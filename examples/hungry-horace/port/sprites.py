"""Ported from src/sprites.asm: erasing and drawing the guards, scoring what Horace eats."""
from labels import *  # noqa: F403  (first: port functions shadow routine labels)
from guards import LoadGuardRecord, SaveGuardRecord
from library import (DrawCell, DrawSprite, GetBlockObject, PrintChar, PrintNumber, SaveBackground,
                     SetAttrPointer, next_row)
from variables import v
from zxpyxel import djnz_t, mem, mem16, zx


def EraseSprites():
    """Erase Horace (if he moves) and every moved guard that is in the maze,
    visiting the guards in the order 4, 3, 2, 1. Returns nothing."""
    if v.HoraceNextPos != v.HoracePos:
        zx.spend(157)
        DrawSprite(ATTR_BLANK, BlankSprite, v.HoracePos, SetAttrPointer(v.HoracePos))
    else:
        zx.spend(75)
    zx.spend(17 - 5)
    for b in range(1, GUARD_COUNT + 1):
        if mem16[GuardTimers + (GUARD_COUNT - b) * 2]:
            zx.spend(119)
            continue
        zx.spend(195)
        LoadGuardRecord(b)
        EraseGuard()
        SaveGuardRecord()


def EraseGuard():
    """Erase the guard of the working buffer from its old position if it moved.
    Returns nothing (the asm's Z = not moved is used by no caller)."""
    if v.GuardNewPos == v.GuardRecord:
        zx.spend(64)
        return
    zx.spend(68)
    EraseGuard_Always()


def EraseGuard_Always():
    """Draw the four saved background cells back at the guard's old position,
    then save the background under the new position. Returns nothing."""
    zx.spend(350)
    hl = v.GuardRecord + SCREEN & 0xFFFF
    attr = SetAttrPointer(hl)
    de = SavedBackground
    for _ in range(2):
        de, hl, attr = DrawCell(mem[de], de + 1, hl, attr)
    hl = next_row(hl)
    attr = SetAttrPointer(hl)
    for _ in range(2):
        de, hl, attr = DrawCell(mem[de], de + 1, hl, attr)
    SaveBackground(v.GuardNewPos)


def EatObject():
    """Score the object (flower SCORE_FLOWER, anything else SCORE_ITEM) in the
    2x2 block at Horace's next position, unless he is frozen after a wrap pad.
    Falls into ShowScore. Returns nothing."""
    if v.WrapPause:
        zx.spend(18)
        return
    a = GetBlockObject(v.HoraceNextPos)
    if not a:
        zx.spend(66)
        return
    zx.spend(149 if a == ATTR_FLOWER else 142)
    v.Score = v.Score + (SCORE_FLOWER if a == ATTR_FLOWER else SCORE_ITEM) & 0xFFFF
    ShowScore(v.Score)


def ShowScore(hl):
    """Print HL as the score on the status line; when Score passes another
    multiple of 10000 (ExtraPassMark) add a pass and reprint its digit; play the
    chirp. Quirk (F15, F16): the extra-pass test uses Score, not HL. Quirks F13
    and F14: ExtraPassMark counts score/10000 + 2, and 10 passes print as ':'.
    Returns nothing."""
    zx.spend(128)
    PrintNumber(SCREEN + STATUS_SCORE_COL, hl)
    n = v.Score // EXTRA_PASS_SCORE + 2     # the asm's subtraction loop counts +1, +1 more
    zx.spend(31 * (n - 1))
    if v.ExtraPassMark != n:
        zx.spend(131)
        v.ExtraPassMark = n
        v.Passes = v.Passes + 1 & 0xFF
        attr = SetAttrPointer(SCREEN + STATUS_PASSES_COL)
        PrintChar(v.Passes + CHAR_0 & 0xFF, SCREEN + STATUS_PASSES_COL, attr)
    chirp()


def chirp():
    """The rising chirp of ShowScore: one square-wave cycle per step, half
    period 8*C DJNZ passes for C = EAT_TONE_STEPS down to 1; white border."""
    zx.spend(17)
    for c in range(EAT_TONE_STEPS, 0, -1):
        d = c << 3 & 0xFF
        zx.out(ULA_PORT, ULA_OUT_MASK & v.SoundMask)
        zx.spend(11 + djnz_t(d) + 7)
        zx.out(ULA_PORT, WHITE)
        zx.spend(11 + 10 + djnz_t(d) + 10 + 4 + 12 + 11 + 4 + 24 + 11 + 7 + 7)
    zx.spend(-5)


def DrawGuards():
    """Draw every guard that is in the maze (release timer zero), in the order
    of the records, and write the records back. Returns nothing."""
    zx.spend(17 - 5)
    for b in range(GUARD_COUNT, 0, -1):
        if mem16[GuardTimers + (GUARD_COUNT - b) * 2]:
            zx.spend(93)
            continue
        zx.spend(169)
        LoadGuardRecord(b)
        DrawGuard()
        SaveGuardRecord()


def DrawGuard():
    """Draw the working-buffer guard at its new position, which becomes its
    current one; a just-eaten guard waits (GuardWait) first. Bell timer running:
    a scared frame (bit 3 of the animation counter) and the timer counts down
    once per guard; else the walking sprite by bit 5 of the counter and the
    direction. Returns nothing."""
    if v.GuardWait:
        v.GuardWait -= 1
        if v.GuardWait:
            zx.spend(42)
            return
        zx.spend(46)
    else:
        zx.spend(29)
    v.GuardRecord = pos = v.GuardNewPos
    v.GuardAnim = anim = v.GuardAnim + 1 & 0xFF
    if v.BellTimer:
        zx.spend(249)
        v.BellTimer -= 1
        sprite = ScaredGuardSprites + (SPRITE_BYTES if anim & GUARD_SCARED_FRAME_BIT else 0)
    else:
        zx.spend(285)
        d = v.GuardDir
        sprite = (GuardSprites if anim & GUARD_WALK_FRAME_BIT else GuardSprites2) \
            + ((d << 5 | d >> 3) & 0xFF)       # RLC five times
    DrawSprite(ATTR_GUARD, sprite, pos, SetAttrPointer(pos))
