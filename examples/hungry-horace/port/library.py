"""Ported from src/library.asm: the routines the title and the maze screen use."""
from labels import *  # noqa: F403
from zxpyxel import mem

MAZE_ATTRS = {TILE_EMPTY: WHITE * PAPER + YELLOW, TILE_FLOWER: WHITE * PAPER + GREEN,
              TILE_ARROW: WHITE * PAPER + BLACK, TILE_BLANK_WHITE: WHITE * PAPER + WHITE}
HALVES = [0, LEFT_HALF, RIGHT_HALF, BOTH_HALVES]   # 2 bits of a block byte → pixel byte


def next_cell(hl):
    """The asm's step after 8 pixel rows (H already +8): INC L, and back up H
    unless L wrapped, where H+8 is the next screen third."""
    h, l = hl >> 8, (hl + 1) & 0xFF
    return (h if l == 0 else h - THIRD_STEP) << 8 | l


def SetAttrPointer(hl):
    """Attribute address of the cell at screen address HL (HL' in the asm)."""
    return ((hl >> 8 & THIRD_BITS) >> 3) + ATTRS_HIGH << 8 | hl & 0xFF


def DrawCell(c, de, hl, attr):
    """Copy 8 bytes from DE to the cell at HL, attribute C at attr.
    Returns the next DE, HL and attr."""
    mem[attr] = c
    for r in range(CELL_BYTES):
        mem[hl + (r << 8)] = mem[de + r]
    return de + CELL_BYTES, next_cell(hl + (CELL_BYTES << 8)), attr + 1


def PrintChar(a, de, attr):
    """Draw character A of the ROM font at DE, black on white, while bit 0 of
    GameActive is set. Returns the next DE and attr (unchanged when off)."""
    if not mem[GameActive] & 1:
        return de, attr
    _, de, attr = DrawCell(WHITE * PAPER + BLACK, ROM_CHARSET + (a - CHAR_SPACE) * CELL_BYTES,
                           de, attr)
    return de, attr


def DrawMaze(hl, de, bc):
    """Draw BC cells of the tile map at HL from screen address DE: all the
    attributes first, then the bitmaps."""
    attr = SetAttrPointer(de)
    for i in range(bc):
        mem[attr + i] = MAZE_ATTRS.get(mem[hl + i], WHITE * PAPER + CYAN)
    for i in range(bc):
        g = TileGraphics + mem[hl + i] * CELL_BYTES
        for r in range(CELL_BYTES):
            mem[de + (r << 8)] = mem[g + r]
        de = next_cell(de + (CELL_BYTES << 8))


def DrawBlocks(hl, de, bc):
    """Draw BC block-pixel bytes from HL at screen address DE: each byte is a
    2x2 grid of 4x4 blocks (bits 4, 5 top; 0, 1 bottom). Bitmap only."""
    for i in range(bc):
        b = mem[hl + i]
        top, bottom = HALVES[b >> 4 & 3], HALVES[b & 3]
        for r in range(BLOCK_PIXEL_ROWS):
            mem[de + (r << 8)] = top
            mem[de + (r + BLOCK_PIXEL_ROWS << 8)] = bottom
        de = next_cell(de + (CELL_BYTES << 8))


def print_text(hl, de):
    """The asm's inline print loop: SetAttrPointer for DE, then PrintChar for
    each byte from HL up to TEXT_END."""
    attr = SetAttrPointer(de)
    while mem[hl] != TEXT_END:
        de, attr = PrintChar(mem[hl], de, attr)
        hl += 1
