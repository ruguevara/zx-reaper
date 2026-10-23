"""Ported from src/movement.asm: Horace's controls (keyboard or demo autopilot),
the planning of Horace's and the guards' next moves, and the guard AI."""
from labels import *  # noqa: F403  (first: port functions shadow routine labels)
from guards import LoadGuardRecord, SaveGuardRecord
from library import GetRandom, ProbeMove, StepCell
from variables import v
from zxpyxel import Goto, djnz_t, mem, mem16, zx

# direction -> keys that request it: (half-row, key mask), the second is the digit key
KEYS = [(DIR_UP, [(KB_Q_T, KEY_Q), (KB_1_5, KEY_4)]),
        (DIR_DOWN, [(KB_CS_V, KEY_Z), (KB_1_5, KEY_3)]),
        (DIR_RIGHT, [(KB_P_Y, 1 << KEYBIT_P), (KB_1_5, KEY_2)]),
        (DIR_LEFT, [(KB_P_Y, 1 << KEYBIT_I), (KB_1_5, KEY_1)])]


def ReadControls():
    """Set Horace's direction from the keyboard (game) or the autopilot (demo);
    nothing while WrapPause runs. Any key in the demo: Goto GameOver (the asm
    drops its return address). Returns nothing."""
    if v.WrapPause:
        zx.spend(18)
        return
    zx.spend(71)
    v.RequestedDir = DIR_NONE
    if v.GameActive:
        ReadKeys()
        return
    zx.spend(44)                # the demo's key test
    if zx.inp(KB_ALL_ROWS << 8 | ULA_PORT) & KEY_BITS != KEY_BITS:
        from events import GameOver     # not at import: events.py is ported in parallel
        raise Goto(GameOver)
    Autopilot()


def pick_best(c):
    """The scan shared by Autopilot and ChooseGuardMove: the direction 3..0 with
    the strictly highest GuardDirScores entry (unsigned); C is the asm's
    leftover when no score beats 0, the weight of direction 0. Returns the direction."""
    zx.spend(4 * 62 + 28)
    best = 0
    for b in range(DIR_COUNT - 1, -1, -1):
        if mem[GuardDirScores + b] > best:
            best = mem[GuardDirScores + b]
            c = b
    return c


def Autopilot():
    """Demo: weigh the four directions (0 where ProbeMove says exit or wall),
    store them in GuardDirScores, and make the heaviest HoraceDir. Returns nothing."""
    zx.spend(110)
    c = 0
    for b in range(DIR_COUNT - 1, -1, -1):
        c = 0
        zx.spend(120)
        if ProbeMove(b, v.HoracePos) < MOVE_EXIT:
            zx.spend(141)
            c = (GetRandom() & AI_RANDOM_MASK) + AI_BASE_SCORE
            d = v.HoraceDir
            if d == b:
                c += AI_STRAIGHT_BONUS
            elif (d + DIR_OPPOSITE) & DIR_MASK == b:
                c = c - AI_REVERSE_PENALTY & 0xFF
        mem[GuardDirScores + b] = c
    v.HoraceDir = pick_best(c)


def ReadKeys():
    """Real game: the first direction whose key pair (Q/4 up, Z/3 down, P/2
    right, I/1 left) is pressed becomes RequestedDir, unless ProbeMove says a
    wall; a surviving request becomes HoraceDir. Returns nothing."""
    zx.spend(299)
    for d, keys in KEYS:
        if any(zx.inp(row << 8 | ULA_PORT) & mask == 0 for row, mask in keys):
            v.RequestedDir = d
            if ProbeMove(d, v.HoracePos) == MOVE_BLOCKED:
                v.RequestedDir = DIR_NONE
            break
    if v.RequestedDir != DIR_NONE:
        v.HoraceDir = v.RequestedDir


def wrap_jump(pos, d):
    """The vertical wrap: up adds the first word of MazeDescriptor, anything else subtracts it."""
    return pos + v.MazeDescriptor & 0xFFFF if d == DIR_UP else pos - v.MazeDescriptor & 0xFFFF


async def PlanMoves():
    """Once per StepCountdown passes: plan Horace (HoraceNextPos; a wrap pad
    plays the wrap tone and freezes him, an exit arrow while moving right is
    ExitMaze) and every released guard (load record, ChooseGuardMove, save).
    Returns nothing."""
    zx.spend(35)
    v.StepCountdown -= 1
    if v.StepCountdown:
        return
    zx.spend(20)
    v.StepCountdown = v.GuardInterval
    if not v.WrapPause:
        zx.spend(60)
        d = v.HoraceDir
        r = ProbeMove(d, v.HoracePos)
        if r == MOVE_FREE:
            v.HoraceNextPos = StepCell(d, v.HoracePos)
        elif r == MOVE_WRAP:
            v.WrapPause = WRAP_PAUSE
            new = wrap_jump(v.HoracePos, d)
            # PlayRisingTone with WRAP_TONE_CYCLES cycles; 76: the outer step, 33: as there
            for c in range(SWEEP_STEPS, 0, -1):
                e = c << 3 & 0xFF
                zx.spend(76)
                zx.tone(djnz_t(e) + 33, WRAP_TONE_CYCLES, ULA_OUT_MASK & v.SoundMask, WHITE)
            await zx.sync()
            v.HoraceNextPos = new
        else:
            if r == MOVE_EXIT and d == DIR_RIGHT:
                from events import ExitMaze     # never returns (Goto)
                ExitMaze()
            v.HoraceNextPos = v.HoracePos       # blocked: stay
    for i in range(GUARD_COUNT):
        zx.spend(88)
        if not mem16[GuardTimers + 2 * i]:
            zx.spend(81)
            LoadGuardRecord(GUARD_COUNT - i)
            ChooseGuardMove()
            SaveGuardRecord()


def cell_of(pos):
    """The asm's conversion of a screen offset to row (H) and column (L): the
    RR H x3 and RR H/RR L x5 chain with the carry clear on entry; the row is the
    low 5 bits of the shifted L, the column the low 5 bits of the offset."""
    h, l, c = pos >> 8, pos & 0xFF, 0
    for _ in range(3):
        c, h = h & 1, c << 7 | h >> 1
    for _ in range(CELL_COL_BITS):
        c, h = h & 1, c << 7 | h >> 1
        c, l = l & 1, c << 7 | l >> 1
    return (l & SCREEN_COLS - 1) << 8 | pos & SCREEN_COLS - 1


def ChooseGuardMove():
    """The guard AI for the working record: score the four directions (blocked
    0, base 25, +40 straight, -10 back, random 0-31 sideways from the ROM at the
    FRAMES word, chase bonus 10 + distance, subtracted unsigned while the bell
    rings), pick the best into GuardDir and set GuardNewPos one step on (wrap
    pads jump). Nothing while GuardWait. Returns nothing."""
    zx.spend(18)
    if v.GuardWait:
        return
    zx.spend(643)
    v.HoraceCell = hc = cell_of(v.HoracePos)
    v.GuardCell = gc = cell_of(v.GuardRecord)
    c = 0
    for b in range(DIR_COUNT - 1, -1, -1):
        c = 0
        zx.spend(110)
        if ProbeMove(b, v.GuardRecord) < MOVE_EXIT:
            zx.spend(350)
            c = AI_BASE_SCORE
            d = v.GuardDir
            if d == b:
                c += AI_STRAIGHT_BONUS
            elif (d + DIR_OPPOSITE) & DIR_MASK == b:
                c = c - AI_REVERSE_PENALTY & 0xFF
            else:                       # sideways: next ROM byte at the FRAMES word
                p = mem16[FRAMES] + 1 & 0xFFFF
                mem16[FRAMES] = p
                c = (mem[(p >> 8 & RANDOM_ROM_HIGH_MASK) << 8 | p & 0xFF] & AI_RANDOM_MASK) + c & 0xFF
            if b == DIR_LEFT:           # dead counter, never read
                v.UnusedAiCounter -= 1
            if b == DIR_UP:
                v.UnusedAiCounter = v.GuardInterval
            gr, gcol, hr, hcol = gc >> 8, gc & 0xFF, hc >> 8, hc & 0xFF
            # distance towards Horace along the axis, no bonus when he is behind
            dist = {DIR_UP: gr - hr, DIR_RIGHT: hcol - gcol, DIR_DOWN: hr - gr,
                    DIR_LEFT: gcol - hcol}[b]
            if dist >= 0:
                bonus = dist + AI_CHASE_BIAS
                if mem16[BellTimer]:    # scared: unsigned wrap, probably a bug
                    bonus = -bonus & 0xFF
                c = c + bonus & 0xFF
        mem[GuardDirScores + b] = c
    v.GuardDir = pick_best(c)
    zx.spend(100)
    r = ProbeMove(v.GuardDir, v.GuardRecord)
    if r == MOVE_FREE:
        v.GuardNewPos = StepCell(v.GuardDir, v.GuardRecord)
    elif r == MOVE_WRAP:
        v.GuardNewPos = wrap_jump(v.GuardRecord, v.GuardDir)
    else:
        v.GuardNewPos = v.GuardRecord
