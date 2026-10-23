"""Erasing and drawing the guards, scoring what Horace eats (stage 3: sprites.py)."""
from . import assets as A
from .constants import (ATTR_BLANK, ATTR_FLOWER, ATTR_GUARD, CHAR_0, EXTRA_PASS_SCORE,
                        GUARD_SCARED_FRAME_BIT, GUARD_WALK_FRAME_BIT, SCORE_FLOWER, SCORE_ITEM,
                        STATUS_PASSES_COL, STATUS_SCORE_COL)
from .state import Sound
from .world import block_object, draw_sprite, print_number, print_text, restore, save_background


def erase_sprites(s):
    """Erase Horace (if he moved) and every moved guard in the maze, guards in
    the order 4, 3, 2, 1. (stage 3: EraseSprites)"""
    h = s.horace
    if h.next_pos != h.pos:
        draw_sprite(s, h.pos, A.BLANK, ATTR_BLANK)
    for g in reversed(s.guards):
        if not g.timer:
            erase_guard(s, g)


def erase_guard(s, g):
    """Erase a guard from its old position if it moved. (stage 3: EraseGuard)"""
    if g.new_pos != g.pos:
        erase_guard_always(s, g)


def erase_guard_always(s, g):
    """Put the cells under a guard back at its old position, then save the cells
    under its new one. (stage 3: EraseGuard_Always)"""
    restore(s, g.pos, g.saved)
    g.saved = save_background(s, g.new_pos)


def eat_object(s):
    """Score the object under Horace (flower SCORE_FLOWER, anything else
    SCORE_ITEM) unless he is frozen after a wrap pad. (stage 3: EatObject)"""
    if s.horace.wrap_pause:
        return
    a = block_object(s, s.horace.next_pos)
    if not a:
        return
    s.score = s.score + (SCORE_FLOWER if a == ATTR_FLOWER else SCORE_ITEM) & 0xFFFF
    yield from show_score(s, s.score)


def show_score(s, value):
    """Print value as the score; when the score passes another multiple of
    10000 add a pass and reprint its digit; chirp. Quirks F13-F16: the test uses
    s.score not value, the mark counts score/10000 + 2, 10 passes print as ':'.
    (stage 3: ShowScore)"""
    print_number(s, STATUS_SCORE_COL, value)
    n = s.score // EXTRA_PASS_SCORE + 2
    if s.extra_pass_mark != n:
        s.extra_pass_mark = n
        s.passes = s.passes + 1 & 0xFF
        print_text(s, (STATUS_PASSES_COL, 0), [s.passes + CHAR_0 & 0xFF])
    if s.sound_on:
        yield Sound('chirp')


def draw_guards(s):
    """Draw every guard in the maze, in the order of the records.
    (stage 3: DrawGuards)"""
    for g in s.guards:
        if not g.timer:
            draw_guard(s, g)


def draw_guard(s, g):
    """Draw a guard at its new position, which becomes its current one; a
    just-eaten guard waits first. Bell running: a scared frame and the timer
    counts down once per guard; else the walking sprite. (stage 3: DrawGuard)"""
    if g.wait:
        g.wait -= 1
        if g.wait:
            return
    g.pos = g.new_pos
    g.anim = anim = g.anim + 1 & 0xFF
    if s.bell_timer:
        s.bell_timer -= 1
        sprite = A.SCARED[1 if anim & GUARD_SCARED_FRAME_BIT else 0]
    else:
        sprite = A.GUARD[0 if anim & GUARD_WALK_FRAME_BIT else 1][g.dir]
    draw_sprite(s, g.pos, sprite, ATTR_GUARD)
