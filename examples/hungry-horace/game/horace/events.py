"""What happens to Horace, the bell, the fruit and the guards' timers in a
pass, the sound key and the pacing (stage 3: events.py, guards.py)."""
from . import assets as A
from . import sprites
from .constants import (ATTR_BELL, ATTR_BLANK, ATTR_GUARD, ATTR_HORACE, ATTR_TEXT, BELL_FRAME_BITS,
                        BELL_HALF_PHASE, BELL_MIRROR_LIMIT, BELL_PHASE_MASK, CHAR_0,
                        CHIME_HIGH_LEN, CHIME_HIGH_PITCH, CHIME_LOW_LEN, CHIME_LOW_PITCH, COLS,
                        DEATH_FLASHES, DEATH_NOISE_CYCLES, DIR_RIGHT, EATEN_TONE_CYCLES,
                        EATEN_TONE_STEPS, FRUIT_DELAY_MASK, FRUIT_MIN_DELAY, GAME_OVER_FLASHES,
                        GUARD_COUNT, GUARD_WAIT, HORACE_FRAME_BIT, INK_MASK, NOISE_MIN_DELAY, PAPER,
                        PASS_T, PASSES_LABEL_CELLS, ROWS, SCORE_BELL_BONUS, SCORE_BELL_PICKUP,
                        SCORE_GUARD, SPEED_DELAY_BASE, SPEED_DELAY_STEP, STATUS_PASSES_COL,
                        SWEEP_CYCLES, SWEEP_STEPS, WHITE)
from .state import Cell, Show, Sound
from .world import block_object, draw_sprite, get_random, print_text, save_background, to_offset

HZ = 3.5e6


def _djnz(r):
    """T-states of a DJNZ loop counting r down (0 = 256); for Show seconds only."""
    return 13 * ((r or 256) - 1) + 8


def check_guard_contact(s):
    """Has Horace met a guard? No: None. Bell not running: he dies. Else he
    eats it: score, falling buzz, every released guard sent home to wait.
    Quirk F19 kept: the timers are walked one byte per guard, not one word, so
    a waiting guard can be sent home too. (stage 3: CheckGuardContact)"""
    if block_object(s, s.horace.next_pos) != ATTR_GUARD:
        return None
    if s.bell_timer == 0:
        return (yield from horace_dies(s))
    s.score = s.score + SCORE_GUARD & 0xFFFF
    yield from sprites.show_score(s, s.score)
    s.bell_timer = 0
    if s.sound_on:
        yield Sound('buzz')
    for c in range(EATEN_TONE_STEPS, 0, -1):
        e = (c ^ EATEN_TONE_STEPS) << 3 & 0xFF
        yield Show(EATEN_TONE_CYCLES * 2 * (51 * (e or 256) + 28) / HZ)
    timer_bytes = [b for g in s.guards for b in (g.timer & 0xFF, g.timer >> 8)]
    for k, g in enumerate(s.guards):
        if timer_bytes[k] | timer_bytes[k + 1]:
            continue
        send_home(s, g)


def send_home(s, g):
    """An eaten guard goes to Horace's start cell and waits there. (stage 3: the loop of CheckGuardContact)"""
    sprites.erase_guard_always(s, g)
    g.pos = g.new_pos = start = A.MAZES[s.maze].horace_start
    g.saved = save_background(s, start)
    g.dir = DIR_RIGHT
    g.wait = GUARD_WAIT


def horace_dies(s):
    """Horace loses a pass: 45 colour steps of the death animation with noise,
    then the guards and Horace are wiped. No passes left: game over. Else
    'RestartMaze' (a game) or 'NextMaze' (the demo). (stage 3: HoraceDies)"""
    h = s.horace
    s.passes = s.passes - 1 & 0xFF
    h.wrap_pause = 0
    print_text(s, (STATUS_PASSES_COL, 0), [s.passes + CHAR_0 & 0xFF])
    for _ in range(DEATH_FLASHES):
        h.attr = (h.attr + 1 & INK_MASK) | WHITE * PAPER
        draw_horace_sprite(s)
        for cell in s.cells[:PASSES_LABEL_CELLS]:
            cell.attr = h.attr
        delays = []
        for _ in range(2 * DEATH_NOISE_CYCLES):
            delays.append(get_random(s) | NOISE_MIN_DELAY)
        if s.sound_on:
            yield Sound('noise', tuple(delays))
        t = 144 + 257 + PASSES_LABEL_CELLS * 26 + DEATH_NOISE_CYCLES * 2 * 100 + sum(map(_djnz, delays))
        yield Show(t / HZ)
    for cell in s.cells[:PASSES_LABEL_CELLS - 1]:       # one fewer than was painted: the last stays
        cell.attr = ATTR_TEXT
    h.attr = ATTR_HORACE
    for g in reversed(s.guards):
        if g.timer == 0:
            sprites.erase_guard_always(s, g)
    draw_sprite(s, h.pos, A.BLANK, ATTR_BLANK)
    if s.passes == 0:
        return (yield from game_over(s))
    reset_guard_timers(s)
    return 'RestartMaze' if s.playing else 'NextMaze'


def game_over(s):
    """Flood the screen's colours GAME_OVER_FLASHES times with a rising tone,
    keep the best score (game only), back to the title. (stage 3: GameOver)"""
    sweep = sum(SWEEP_CYCLES * 2 * (_djnz(c << 3 & 0xFF) + 33) for c in range(SWEEP_STEPS, 0, -1))
    for b in range(GAME_OVER_FLASHES, 0, -1):
        if s.sound_on:
            yield Sound('rising')
        for cell in s.cells:
            cell.attr = (b & INK_MASK) + WHITE * PAPER
        yield Show((sweep + 21 * (COLS * ROWS - 1) + 55) / HZ)
    if s.playing and s.score >= s.best:
        s.best = s.score
    return 'ShowTitle'


def draw_horace(s):
    """While the wrap pad's pause runs count it down and make the next
    position current; otherwise draw him. (stage 3: DrawHorace)"""
    h = s.horace
    if h.wrap_pause == 0:
        draw_horace_sprite(s)
    else:
        h.wrap_pause -= 1
        h.pos = h.next_pos


def draw_horace_sprite(s):
    """Draw Horace at his next position (it becomes current) in his colour,
    the frame bit 4 of his counter picks; the counter steps on.
    (stage 3: DrawHorace_Sprite)"""
    h = s.horace
    h.anim = h.anim + 1 & 0xFF
    h.pos = h.next_pos
    draw_sprite(s, h.pos, A.HORACE[0 if h.anim & HORACE_FRAME_BIT else 1][h.dir], h.attr)


def update_bell(s):
    """Nothing without a bell. Horace within one cell of it: he takes it.
    Otherwise animate and redraw it. Quirk F17 kept: a bell at +32, +31, -31
    or -33 is neither taken nor out of reach of EatObject. (stage 3: UpdateBell)"""
    if s.bell is None:
        return
    d = to_offset(s.horace.pos) - to_offset(s.bell) & 0xFFFF
    if d in (0, 1, 0xFFFF, 0x10000 - COLS, COLS + 1):
        yield from take_bell(s)
        return
    s.bell_tick = tick = s.bell_tick + 1 & 0xFF
    a = tick & BELL_FRAME_BITS
    if a >= BELL_MIRROR_LIMIT:
        a ^= BELL_FRAME_BITS
    draw_sprite(s, s.bell, A.BELL[a >> 3], ATTR_BELL)


def take_bell(s):
    """Erase the bell, redraw Horace, score the pickup and the bonus, start the
    bell timer (pace * 128). (stage 3: TakeBell)"""
    s.bell = None
    draw_sprite(s, A.MAZES[s.maze].bell, A.BLANK, ATTR_BLANK)
    draw_horace(s)
    s.score = s.score + SCORE_BELL_PICKUP & 0xFFFF
    yield from sprites.show_score(s, s.score)
    a = s.pace
    s.bell_timer = (a >> 1 | a & 0x80) << 8 | (a & 1) << 7
    s.score = s.score + SCORE_BELL_BONUS & 0xFFFF
    yield from sprites.show_score(s, s.score)


def update_fruit_drops(s):
    """Every guard out in the maze may drop fruit. (stage 3: UpdateFruitDrops)"""
    for g in s.guards:
        if g.timer == 0:
            maybe_drop_fruit(s, g)


def maybe_drop_fruit(s, g):
    """Not while the guard waits or has a bell or fruit cell under it; else
    count the fruit timer down, and at zero re-arm it (800 + random 0-1023)
    and put one of two fruits under the guard. (stage 3: MaybeDropFruit)"""
    if g.wait or any(c.attr == ATTR_BELL for c in g.saved):
        return
    s.fruit_timer = s.fruit_timer - 1 & 0xFFFF
    if s.fruit_timer:
        return
    low = get_random(s)
    high = get_random(s) & FRUIT_DELAY_MASK
    s.fruit_timer = (high << 8 | low) + FRUIT_MIN_DELAY
    fruit = A.FRUIT[1 if get_random(s) & 1 else 0]
    g.saved = [Cell(c.glyph, c.attr) for c in fruit]


def tick_guard_timers(s):
    """Count every running guard timer down. Quirk F10 kept: guards_released
    goes up on a tick below $0100 only while there is no bell (the original
    tests a leftover register). (stage 3: TickGuardTimers)"""
    for g in s.guards:
        if g.timer:
            g.timer -= 1
            if g.timer >> 8 == 0 and s.bell is None:
                s.guards_released = s.guards_released + 1 & 0xFF


def check_sound_key(s, a):
    """A fresh press of T toggles the sound. (stage 3: CheckSoundKey)"""
    if a.t == s.t_held:
        return
    s.t_held = a.t
    if a.t:
        s.sound_on = not s.sound_on


def pace_and_chime(s):
    """With the bell in the maze and sound on, ring it at phase 0 and $20 of
    its tick; otherwise wait a delay that grows with the pace and shortens as
    guards are released (quirk F11: it underflows at paces 1-3). Ends the pass.
    (stage 3: PaceAndChime)"""
    low, high = (CHIME_LOW_LEN, CHIME_LOW_PITCH), (CHIME_HIGH_LEN, CHIME_HIGH_PITCH)
    phase = s.bell_tick & BELL_PHASE_MASK
    if s.bell is not None and s.sound_on and phase in (0, BELL_HALF_PHASE):
        yield Sound('chime', phase == 0)     # data: low tone first
        t = sum(n * 8 * (pitch + 30) for n, pitch in (low, high))
    else:
        level = s.pace or 256
        hl = SPEED_DELAY_BASE + SPEED_DELAY_STEP * level & 0xFFFF
        x = (s.guards_released << 6 | s.guards_released >> 3) & 0x1FF     # RLA x6 through the carry
        bc, carry = x & 0xFF, x >> 8
        for _ in range(2):
            diff = hl - bc - carry
            hl, carry = diff & 0xFFFF, int(diff < 0)
        t = (hl or 0x10000) * 26
    yield Show((PASS_T + t) / HZ)


def reset_guard_timers(s):
    """No guard released; release waits 0, 1, 2 and 4 paces (x256).
    (stage 3: ResetGuardTimers)"""
    s.guards_released = 0
    p = s.pace
    for g, n in zip(s.guards, (0, p, p << 1 & 0xFF, p << 2 & 0xFF)):
        g.timer = n << 8
