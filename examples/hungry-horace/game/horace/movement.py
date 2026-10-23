"""Horace's controls (keyboard or demo autopilot), the planning of Horace's and
the guards' next moves, and the guard AI."""
from .constants import (AI_BASE_SCORE, AI_CHASE_BIAS, AI_RANDOM_MASK, AI_REVERSE_PENALTY,
                        AI_STRAIGHT_BONUS, DIR_COUNT, DIR_DOWN, DIR_LEFT, DIR_MASK, DIR_NONE,
                        DIR_OPPOSITE, DIR_RIGHT, DIR_UP, MOVE_BLOCKED, MOVE_EXIT, MOVE_FREE,
                        MOVE_WRAP, SWEEP_STEPS, WRAP_PAUSE, WRAP_TONE_CYCLES)
from .state import Show, Sound
from .world import ai_random, get_random, probe_move, step_cell, wrap_jump


def read_controls(s, a):
    """Set Horace's direction from the keys (game) or the autopilot (demo);
    nothing while he is frozen after a wrap pad. Any key in the demo ends it.
    (stage 3: ReadControls)"""
    h = s.horace
    if h.wrap_pause:
        return None
    h.requested = DIR_NONE
    if s.playing:
        read_keys(s, a)
    elif a.any_key:
        return 'GameOver'
    else:
        autopilot(s)
    return None


def pick_best(scores, c):
    """The direction 3..0 with the strictly highest score; c is the original's
    leftover when none beats 0: the score of direction 0 (stage 3: pick_best)."""
    best = 0
    for d in range(DIR_COUNT - 1, -1, -1):
        if scores[d] > best:
            best, c = scores[d], d
    return c


def turn_score(c, facing, d):
    """Bonus for going straight on, penalty (wrapping in a byte) for turning back."""
    if facing == d:
        return c + AI_STRAIGHT_BONUS
    if (facing + DIR_OPPOSITE) & DIR_MASK == d:
        return c - AI_REVERSE_PENALTY & 0xFF
    return c


def autopilot(s):
    """Demo: weigh the four directions (0 where the way is a wall or an exit),
    randomly, favouring straight on, and walk the heaviest. (stage 3: Autopilot)"""
    h = s.horace
    scores = [0] * DIR_COUNT
    for d in range(DIR_COUNT - 1, -1, -1):
        scores[d] = 0
        if probe_move(s, h.pos, d) < MOVE_EXIT:
            scores[d] = turn_score((get_random(s) & AI_RANDOM_MASK) + AI_BASE_SCORE, h.dir, d)
    h.dir = pick_best(scores, scores[0])


def read_keys(s, a):
    """Game: the first direction key held is the request, dropped when a wall
    is there; a surviving request is Horace's direction. (stage 3: ReadKeys)"""
    h = s.horace
    if a.direction != DIR_NONE:
        h.requested = a.direction
        if probe_move(s, h.pos, a.direction) == MOVE_BLOCKED:
            h.requested = DIR_NONE
    if h.requested != DIR_NONE:
        h.dir = h.requested


def plan_moves(s):
    """Once per `pace` passes: plan Horace's next position (a wrap pad plays
    the wrap tone and freezes him; an exit arrow going right leaves the maze:
    'NextMaze') and every released guard's. (stage 3: PlanMoves)"""
    s.step_countdown = s.step_countdown - 1 & 0xFF
    if s.step_countdown:
        return None
    s.step_countdown = s.pace
    h = s.horace
    if not h.wrap_pause:
        r = probe_move(s, h.pos, h.dir)
        if r == MOVE_FREE:
            h.next_pos = step_cell(h.pos, h.dir)
        elif r == MOVE_WRAP:
            h.wrap_pause = WRAP_PAUSE
            new = wrap_jump(s, h.pos, h.dir)
            if s.sound_on:
                yield Sound('wrap')
            # the tone's length: SWEEP_STEPS sweeps of WRAP_TONE_CYCLES cycles, 13 T per count
            yield Show(sum(2 * WRAP_TONE_CYCLES * 13 * (c << 3 & 0xFF) for c in range(SWEEP_STEPS, 0, -1))
                       / 3.5e6)
            h.next_pos = new
        else:
            if r == MOVE_EXIT and h.dir == DIR_RIGHT:
                return 'NextMaze'
            h.next_pos = h.pos
    for g in s.guards:
        if not g.timer:
            choose_guard_move(s, g)
    return None


def choose_guard_move(s, g):
    """The guard AI: score the four directions (blocked 0, base, bonus straight
    on, penalty back, random sideways, a chase bonus of 10 + distance towards
    Horace, subtracted while the bell rings: unsigned wrap, probably a bug of
    the original), take the best and plan one step on (wrap pads jump). Nothing
    while the guard waits. (stage 3: ChooseGuardMove)"""
    if g.wait:
        return
    gcol, grow = g.pos
    hcol, hrow = s.horace.pos
    scores = [0] * DIR_COUNT
    for d in range(DIR_COUNT - 1, -1, -1):
        c = 0
        if probe_move(s, g.pos, d) < MOVE_EXIT:
            c = AI_BASE_SCORE
            if g.dir != d and (g.dir + DIR_OPPOSITE) & DIR_MASK != d:
                c = (ai_random(s) & AI_RANDOM_MASK) + c & 0xFF      # sideways
            else:
                c = turn_score(c, g.dir, d)
            # distance towards Horace along the axis, no bonus when he is behind
            dist = {DIR_UP: grow - hrow, DIR_RIGHT: hcol - gcol, DIR_DOWN: hrow - grow,
                    DIR_LEFT: gcol - hcol}[d]
            if dist >= 0:
                bonus = dist + AI_CHASE_BIAS
                if s.bell_timer:
                    bonus = -bonus & 0xFF
                c = c + bonus & 0xFF
        scores[d] = c
    g.dir = pick_best(scores, c)
    r = probe_move(s, g.pos, g.dir)
    if r == MOVE_FREE:
        g.new_pos = step_cell(g.pos, g.dir)
    elif r == MOVE_WRAP:
        g.new_pos = wrap_jump(s, g.pos, g.dir)
    else:
        g.new_pos = g.pos
