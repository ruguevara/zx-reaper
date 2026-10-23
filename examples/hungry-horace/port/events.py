"""Ported from src/events.asm: what happens to Horace, the bell, the fruit and
the guards' timers in a pass of the main loop, the sound key and the pacing.
The jumps that drop return addresses (HoraceDies, GameOver, ExitMaze) raise
Goto; the targets in main are imported where they are used (main imports this
module)."""
from labels import *  # noqa: F403  (first: port functions shadow routine labels)
from guards import LoadGuardRecord, PlayRisingTone, ResetGuardTimers, SaveGuardRecord
from library import (Delay, DrawSprite, GetBlockObject, GetRandom, PrintChar, SaveBackground,
                      SetAttrPointer)
from sprites import EraseGuard_Always, ShowScore   # L672F (with its dead CALL DrawGuard) is not ported
from variables import v
from zxpyxel import Goto, djnz_t, mem, mem16, rom, zx


def rlc(a, n):
    """RLC A, n times, on a byte."""
    n %= 8
    return (a << n | a >> 8 - n) & 0xFF


async def CheckGuardContact():
    """Has Horace met a guard? None in the 2x2 block at HoraceNextPos: return.
    Bell timer zero: HoraceDies (never returns). Otherwise he eats it: score,
    falling buzz, every released guard sent home to wait GUARD_WAIT passes."""
    zx.spend(61)
    if GetBlockObject(v.HoraceNextPos) != ATTR_GUARD:
        return
    if v.BellTimer == 0:
        await HoraceDies()
    zx.spend(180)
    v.Score += SCORE_GUARD
    ShowScore(v.Score)
    v.BellTimer = 0
    for c in range(EATEN_TONE_STEPS, 0, -1):
        e = (c ^ EATEN_TONE_STEPS) << 3 & 0xFF         # SLA B x3
        # a pass is LD A,(IX+0); LD (IX+0),A; DJNZ = 51 T, the last 5 less;
        # 33: the other instructions of a half period, averaged over both halves
        zx.tone(51 * (e or 256) - 5 + 33, EATEN_TONE_CYCLES, ULA_OUT_MASK & v.SoundMask, WHITE)
        await zx.sync()
    # Send every released guard home. BUG (kept): HL advances one byte per
    # guard, not one word, so guard k tests the bytes at GuardTimers+k and +k+1.
    for k, b in enumerate(range(GUARD_COUNT, 0, -1)):
        zx.spend(87)
        if mem[GuardTimers + k] | mem[GuardTimers + k + 1]:
            continue                        # still waiting
        zx.spend(5 * 27 + 80)               # five calls, the loads and stores
        LoadGuardRecord(b)
        EraseGuard_Always()
        GetBlockObject(v.HoraceNextPos)     # no effect: the flags are never tested
        v.GuardRecord = v.GuardNewPos = v.MazeHoraceStart
        SaveBackground(v.MazeHoraceStart)
        v.GuardDir = DIR_RIGHT
        v.GuardWait = GUARD_WAIT
        SaveGuardRecord()                   # (L672F, with its dead CALL DrawGuard, is skipped)


async def HoraceDies():
    """Horace dies: one pass less, 45 colour steps of the death animation with
    noise, the guards and Horace wiped. No passes left: GameOver. Otherwise
    Goto RestartMaze (game) or NextMaze (demo). Never returns."""
    zx.spend(200)
    v.Passes = v.Passes - 1 & 0xFF
    v.WrapPause = 0
    v.GuardWait = 0         # no effect: LoadGuardRecord reloads the buffer before it is used
    cell = SCREEN + STATUS_PASSES_COL
    PrintChar(v.Passes + CHAR_0 & 0xFF, cell, SetAttrPointer(cell))
    for _ in range(DEATH_FLASHES):
        zx.spend(144)
        a = (v.HoraceAttr + 1 & INK_MASK) | WHITE * PAPER
        v.HoraceAttr = a
        DrawHorace_Sprite()
        mem[ATTRS:ATTRS + PASSES_LABEL_CELLS] = bytes([a]) * PASSES_LABEL_CELLS
        zx.spend(PASSES_LABEL_CELLS * 26 - 5)
        for _ in range(DEATH_NOISE_CYCLES):
            zx.spend(24)
            zx.out(ULA_PORT, ULA_OUT_MASK & v.SoundMask)
            r = GetRandom() | NOISE_MIN_DELAY
            zx.spend(11 + 27 + 7 + 4 + djnz_t(r) + 7)
            zx.out(ULA_PORT, WHITE)
            r = GetRandom() | NOISE_MIN_DELAY
            zx.spend(11 + 27 + 7 + 4 + djnz_t(r) + 16)
        await zx.sync()
    n = PASSES_LABEL_CELLS - 1          # one cell fewer than was painted: the last is a blank
    mem[ATTRS:ATTRS + n] = bytes([WHITE * PAPER + BLACK]) * n
    zx.spend(n * 26 - 5)
    v.HoraceAttr = ATTR_HORACE
    for b in range(1, GUARD_COUNT + 1):     # the guards out in the maze (timer zero)
        zx.spend(80)
        if mem16[GuardTimers + 6 - 2 * (b - 1)] == 0:
            zx.spend(3 * 27)
            LoadGuardRecord(b)
            EraseGuard_Always()
            SaveGuardRecord()
    pos = v.HoracePos
    DrawSprite(ATTR_BLANK, BlankSprite, pos, SetAttrPointer(pos))
    if v.Passes == 0:
        await GameOver()
    ResetGuardTimers()      # the asm drops the return address here (POP HL)
    from main import NextMaze, RestartMaze
    raise Goto(RestartMaze if v.GameActive else NextMaze)


async def GameOver():
    """Flood the attribute area GAME_OVER_FLASHES times with a rising tone, keep
    the best score (game only), then Goto ShowTitle. Never returns. The asm's
    POP HL drops a return address (F12: in the demo abort it drops a word that
    belongs to no call and the stack creeps up): the Z80 stack only, no
    Python equivalent."""
    for b in range(GAME_OVER_FLASHES, 0, -1):
        PlayRisingTone()
        zx.spend(21 * (ATTRS_SIZE - 1) - 5 + 60)        # LDIR
        mem[ATTRS:ATTRS + ATTRS_SIZE] = bytes([(b & INK_MASK) + WHITE * PAPER]) * ATTRS_SIZE
        await zx.sync()
    zx.spend(80)
    if v.GameActive and v.Score >= v.BestScore:
        v.BestScore = v.Score
    from main import ShowTitle
    raise Goto(ShowTitle)


def DrawHorace():
    """During the wrap countdown (WrapPause) count it down and make the next
    position current; otherwise draw him (DrawHorace_Sprite)."""
    a = v.WrapPause
    if a == 0:
        zx.spend(24)
        DrawHorace_Sprite()
        return
    zx.spend(73)
    v.WrapPause = a - 1
    v.HoracePos = v.HoraceNextPos


def DrawHorace_Sprite():
    """Draw Horace at HoraceNextPos (it becomes HoracePos) in HoraceAttr, the
    sprite from the set HoraceAnim bit 4 picks and the direction HoraceDir;
    HoraceAnim steps on. Also the entry of the death animation."""
    zx.spend(257)
    anim = v.HoraceAnim = v.HoraceAnim + 1 & 0xFF
    de = (HoraceSprites if anim & HORACE_FRAME_BIT else HoraceSprites2) + rlc(v.HoraceDir, 5)
    pos = v.HoracePos = v.HoraceNextPos
    DrawSprite(v.HoraceAttr, de, pos, SetAttrPointer(pos))


def UpdateBell():
    """Nothing when there is no bell (BellPos 0). Horace within one cell of it
    (offsets 0, +-1, -32, +33): TakeBell. Otherwise animate and redraw it.
    The asm leaves C = 0 when it returns without drawing or after TakeBell and
    C = ATTR_BELL after a redraw; TickGuardTimers reads that as BellPos == 0."""
    bell = v.BellPos
    if bell == 0:
        zx.spend(45)
        return
    d = v.HoracePos - bell & 0xFFFF
    if d in (0, 0xFFFF, 1, 0x10000 - SCREEN_COLS, SCREEN_COLS + 1):
        zx.spend(100)
        TakeBell()
        return
    zx.spend(393)
    tick = v.BellTick = v.BellTick + 1 & 0xFF
    a = tick & BELL_FRAME_BITS
    if a >= BELL_MIRROR_LIMIT:
        a ^= BELL_FRAME_BITS
    de = BellSprites + (a << 2)         # RLCA x2: frame * SPRITE_BYTES
    DrawSprite(ATTR_BELL, de, bell, SetAttrPointer(bell))


def TakeBell():
    """Erase the bell, redraw Horace, score SCORE_BELL_PICKUP and
    SCORE_BELL_BONUS, start the bell timer (GuardInterval * 128)."""
    zx.spend(360)
    v.BellPos = 0
    cell = v.MazeBellStart
    DrawSprite(ATTR_BLANK, BlankSprite, cell, SetAttrPointer(cell))
    DrawHorace()
    v.Score += SCORE_BELL_PICKUP
    ShowScore(v.Score)
    a = v.GuardInterval
    v.BellTimer = (a >> 1 | a & 0x80) << 8 | (a & 1) << 7        # SRA H; RR L
    # no effect: the record in the buffer is not saved, the next LoadGuardRecord replaces it
    v.GuardDir = v.GuardDir + DIR_OPPOSITE & DIR_MASK
    v.Score += SCORE_BELL_BONUS
    ShowScore(v.Score)


def UpdateFruitDrops():
    """For every released guard (timer zero): load its record, MaybeDropFruit,
    save the record."""
    zx.spend(64)
    for k, b in enumerate(range(GUARD_COUNT, 0, -1)):
        zx.spend(80)
        if mem16[GuardTimers + 2 * k] == 0:
            zx.spend(81)
            LoadGuardRecord(b)
            MaybeDropFruit()
            SaveGuardRecord()


def MaybeDropFruit():
    """On the record in the buffer: not while it waits (GuardWait) or a red cell
    (bell or fruit) is in SavedBackground; else count FruitTimer down, and at
    zero re-arm it (800 + random 0-1023) and plant one of two fruits."""
    if v.GuardWait:
        zx.spend(18)
        return
    for i in range(SPRITE_CELLS):
        if v.SavedBackground[i * SAVED_CELL_SIZE] == ATTR_BELL:
            zx.spend(53 + 56 * i)
            return
    zx.spend(304)
    v.FruitTimer -= 1
    if v.FruitTimer != 0:
        return
    zx.spend(962)
    low = GetRandom()
    high = GetRandom() & FRUIT_DELAY_MASK
    v.FruitTimer = (high << 8 | low) + FRUIT_MIN_DELAY
    src = FruitCellsB if GetRandom() & 1 else FruitCellsA
    n = SPRITE_CELLS * SAVED_CELL_SIZE
    mem[SavedBackground:SavedBackground + n] = mem[src:src + n]


def TickGuardTimers():
    """Count every non-zero guard timer down. BUG (kept): GuardsReleased goes up
    when the timer's high byte is zero and C is zero; C is left over from
    UpdateBell, zero exactly when BellPos is 0 (so it counts only once the bell
    is gone, on every tick below $0100, not on release)."""
    zx.spend(12)
    c_zero = v.BellPos == 0
    for k in range(GUARD_COUNT):
        t = mem16[GuardTimers + 2 * k]
        if t == 0:
            zx.spend(71)
            continue
        t = mem16[GuardTimers + 2 * k] = t - 1 & 0xFFFF
        zx.spend(118)
        if t >> 8 == 0 and c_zero:
            zx.spend(25)
            v.GuardsReleased = v.GuardsReleased + 1 & 0xFF


def CheckSoundKey():
    """T pressed (edge): toggle SoundMask between $1F and $07."""
    zx.spend(43)
    a = zx.inp(KB_Q_T << 8 | ULA_PORT) & KEY_T_BIT
    if a == v.SoundKeyState:
        return
    zx.spend(16)
    v.SoundKeyState = a
    if a:
        return
    zx.spend(30)
    v.SoundMask ^= SOUND_TOGGLE


def chime(first, second):
    """Two ROM BEEPER tones, (length, pitch) each, DI after each."""
    for de, hl in (first, second):
        rom.BEEPER(de, hl)
        zx.di()


async def PaceAndChime():
    """With the bell in the maze ring it at BellTick 0 (low, high) and $20 (high,
    low) mod 64 when sound is on; every other pass a delay of
    SPEED_DELAY_BASE + SPEED_DELAY_STEP * GuardInterval - 2 * (GuardsReleased
    rotated left six times through carry) passes. Ends the pass with zx.sync()."""
    low, high = (CHIME_LOW_LEN, CHIME_LOW_PITCH), (CHIME_HIGH_LEN, CHIME_HIGH_PITCH)
    phase = v.BellTick & BELL_PHASE_MASK
    if v.BellPos and v.SoundMask == ULA_OUT_MASK and phase in (0, BELL_HALF_PHASE):
        zx.spend(120)
        chime(*((low, high) if phase == 0 else (high, low)))
    else:
        level = v.GuardInterval or 256
        zx.spend(135 + 37 * level)
        hl = SPEED_DELAY_BASE + SPEED_DELAY_STEP * level & 0xFFFF
        x = v.GuardsReleased
        x = (x << 6 | x >> 3) & 0x1FF       # RLA x6 through the carry (clear on entry)
        bc, carry = x & 0xFF, x >> 8
        for _ in range(2):                  # SBC HL,BC twice; the carry runs through both
            diff = hl - bc - carry
            hl, carry = diff & 0xFFFF, int(diff < 0)
        Delay(hl)
    await zx.sync()


def ExitMaze():
    """Leave the maze through the exit arrows: Goto NextMaze (the asm drops
    its caller's return address)."""
    from main import NextMaze
    raise Goto(NextMaze)
