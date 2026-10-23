"""The grid and the figures on it: what stage 3's library did with screen
addresses, on (col, row) positions and the cells of the state.

A figure covers four cells: block(pos) is the original's attribute pointer
walk (+0, +1, +32, +33), so at column 31 it runs into the next row, as on
the Spectrum. Colours are what the rules read: a cell is a wall, a pad, an
arrow, a flower, the bell, a guard by its attribute.
"""
from . import assets as A
from .constants import (ATTR_ARROW, ATTR_BELL, ATTR_BLANK, ATTR_FLOWER, ATTR_GUARD, ATTR_PAD,
                        ATTR_TEXT, ATTR_WALL, CHAR_0, COLS, DIR_DOWN, DIR_MASK, DIR_RIGHT,
                        DIR_UP, MOVE_BLOCKED, MOVE_WRAP, PROBE_ARROW_WEIGHT, PROBE_MANY_BITS,
                        RANDOM_ROM_HIGH_MASK, ROM_HIGH_MASK, ROWS)
from .state import BLANK, Cell


def index(pos):
    return pos[1] * COLS + pos[0]


def at(i):
    return i % COLS, i // COLS


def block(pos):
    """The four cells of a figure at pos: top-left, top-right, bottom-left, bottom-right."""
    i = index(pos)
    return i, i + 1, i + COLS, i + COLS + 1


def attr(s, i):
    """The attribute of cell i; past the last row 0 (the printer buffer on the
    Spectrum, read when a probe looks below row 23)."""
    return s.cells[i].attr if 0 <= i < COLS * ROWS else 0


def step_cell(pos, d):
    """One cell on in direction d (low two bits). Quirk kept: left from column
    0 stays in the same screen third (DEC L carries nothing), to column 31 of
    the row above, or of row 7 of the third from its first row."""
    col, row = pos
    d &= DIR_MASK
    if d == DIR_UP:
        return at(index(pos) - COLS)
    if d == DIR_RIGHT:
        return at(index(pos) + 1)
    if d == DIR_DOWN:
        return at(index(pos) + COLS)
    return (col - 1, row) if col else (COLS - 1, row - 1 if row % 8 else row + 7)


def rrc(x):
    return (x >> 1 | x << 7) & 0xFF


def probe_move(s, pos, d):
    """What is one step from the figure at pos in direction d: MOVE_FREE,
    MOVE_WRAP (2 or more pad cells), MOVE_EXIT (2 or more arrow cells),
    MOVE_BLOCKED (any wall). Quirk kept: pads and arrows both 2 or more give
    $82, which callers treat as blocked."""
    e = 0
    for i in block(step_cell(pos, d)):
        a = attr(s, i)
        if a == ATTR_WALL:
            return MOVE_BLOCKED
        if a == ATTR_PAD:
            e += 1
        elif a == ATTR_ARROW:
            e += PROBE_ARROW_WEIGHT
    e = rrc(e & PROBE_MANY_BITS)        # bit 1 (2-3 pads) -> MOVE_WRAP, bit 3 (2-3 arrows) -> bit 2
    return e if e == MOVE_WRAP else rrc(e)


def block_object(s, pos):
    """The object under a figure at pos, by colour: a guard before the bell
    before a flower; 0 for none. Fruit has the bell's and the flower's
    colours, so it counts as the bell."""
    found = 0
    for i in block(pos):
        a = attr(s, i)
        if a == ATTR_GUARD or a == ATTR_BELL and found != ATTR_GUARD or a == ATTR_FLOWER and not found:
            found = a
    return found


def draw_sprite(s, pos, graphic, a):
    """A 32-byte figure (four 8-byte cells) at pos, all four cells in colour a."""
    for k, i in enumerate(block(pos)):
        s.cells[i] = Cell(graphic[8 * k:8 * k + 8], a)


def save_background(s, pos):
    """The four cells under a figure at pos, for a guard to put back when it
    leaves; a guard-coloured cell is saved as blank floor."""
    return [Cell(BLANK, ATTR_BLANK) if s.cells[i].attr == ATTR_GUARD else Cell(s.cells[i].glyph,
                                                                                  s.cells[i].attr)
            for i in block(pos)]


def restore(s, pos, saved):
    """Put four saved cells back at pos."""
    for i, c in zip(block(pos), saved):
        s.cells[i] = Cell(c.glyph, c.attr)


def print_text(s, pos, codes, always=False):
    """Characters of the ROM font from pos on, black on white, running on into
    the next row. Only in a real game (the original prints while GameActive is
    1), unless `always`."""
    if not (always or s.playing):
        return
    i = index(pos)
    for k, code in enumerate(codes):
        s.cells[i + k] = Cell(A.FONT[code - 32], ATTR_TEXT)


def print_number(s, col, n):
    """Five decimal digits on the status line (row 0) from col. Ten passes
    print as ':' (CHAR_0 + 10) through print_text, as in the original."""
    print_text(s, (col, 0), [CHAR_0 + n // p % 10 for p in (10000, 1000, 100, 10)] + [CHAR_0 + n % 10])


def get_random(s):
    """The next random byte: the ROM byte at s.random, which walks the first 8K."""
    p = s.random
    s.random = p + 1 & (ROM_HIGH_MASK << 8 | 0xFF)
    return A.ROM[p]


def ai_random(s):
    """The guards' random byte: FRAMES (its low word) steps on, and the ROM
    byte it points at in the first 4K."""
    p = (s.frames & 0xFFFF) + 1 & 0xFFFF
    s.frames = s.frames & 0xFF0000 | p
    return A.ROM[(p >> 8 & RANDOM_ROM_HIGH_MASK) << 8 | p & 0xFF]


def to_offset(pos):
    """The original's screen offset of a cell: %000TT000 RRRCCCCC."""
    col, row = pos
    return (row & 0x18) << 8 | (row & 7) << 5 | col


def from_offset(o):
    return o & 31, (o >> 8 & 0x18) | (o >> 5 & 7)


def wrap_jump(s, pos, d):
    """Through a wrap pad: the maze's wrap delta added going up, subtracted
    otherwise, in the original's screen-offset arithmetic (the deltas are
    whole screen thirds plus rows, which that arithmetic makes uneven)."""
    w = A.MAZES[s.maze].wrap
    return from_offset(to_offset(pos) + (w if d == DIR_UP else -w) & 0xFFFF)
