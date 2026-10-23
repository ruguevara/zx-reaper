"""Ported from src/library.asm: the routines the title and the maze screen use."""
from labels import *  # noqa: F403
from variables import v
from zxpyxel import mem, zx

MAZE_ATTRS = {TILE_EMPTY: WHITE * PAPER + YELLOW, TILE_FLOWER: WHITE * PAPER + GREEN,
              TILE_ARROW: WHITE * PAPER + BLACK, TILE_BLANK_WHITE: WHITE * PAPER + WHITE}
HALVES = [0, LEFT_HALF, RIGHT_HALF, BOTH_HALVES]   # 2 bits of a block byte → pixel byte


def next_cell(hl):
    """The asm's step after 8 pixel rows (H already +8): INC L, and back up H
    unless L wrapped, where H+8 is the next screen third."""
    h, l = hl >> 8, (hl + 1) & 0xFF
    return (h if l == 0 else h - THIRD_STEP) << 8 | l


def next_row(hl):
    """From the cell two to the right of a sprite's top-left cell to its
    bottom-left cell: L += 30, and H moves to the next third on a carry."""
    low = (hl & 0xFF) + SCREEN_COLS - 2
    return ((hl >> 8) + (THIRD_STEP if low > 0xFF else 0) & 0xFF) << 8 | low & 0xFF


def SetAttrPointer(hl):
    """Attribute address of the cell at screen address HL (HL' in the asm)."""
    zx.spend(75)
    return ((hl >> 8 & THIRD_BITS) >> 3) + ATTRS_HIGH << 8 | hl & 0xFF


def DrawCell(c, de, hl, attr):
    """Copy 8 bytes from DE to the cell at HL, attribute C at attr.
    Returns the next DE, HL and attr."""
    zx.spend(350)
    mem[attr] = c
    for r in range(CELL_BYTES):
        mem[hl + (r << 8)] = mem[de + r]
    return de + CELL_BYTES, next_cell(hl + (CELL_BYTES << 8)), attr + 1


def PrintChar(a, de, attr):
    """Draw character A of the ROM font at DE, black on white, while bit 0 of
    GameActive is set. Returns the next DE and attr (unchanged when off)."""
    if not v.GameActive & 1:
        zx.spend(68)
        return de, attr
    zx.spend(240)       # plus DrawCell
    _, de, attr = DrawCell(WHITE * PAPER + BLACK, ROM_CHARSET + (a - CHAR_SPACE) * CELL_BYTES,
                           de, attr)
    return de, attr


def DrawMaze(hl, de, bc):
    """Draw BC cells of the tile map at HL from screen address DE: all the
    attributes first, then the bitmaps. Returns nothing."""
    zx.spend(718 * bc)      # per cell, averaged over the four game mazes
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
    2x2 grid of 4x4 blocks (bits 4, 5 top; 0, 1 bottom). Bitmap only. Returns nothing."""
    zx.spend(410 * bc)      # per cell, as measured on the title words
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


def Delay(bc):
    """Spin BC passes (0 = 65536) of 26 T-states. Returns nothing (BC = 0)."""
    zx.spend(26 * (bc or 0x10000))


def GetRandom():
    """Return the ROM byte at RandomPtr (A); the pointer advances, wrapping
    inside the ROM. HL (the next pointer) is not returned: no caller uses it."""
    zx.spend(81)
    p = v.RandomPtr
    v.RandomPtr = p + 1 & (ROM_HIGH_MASK << 8 | 0xFF)
    return mem[p]


def StepCell(a, hl):
    """Move screen address/offset HL one cell in direction A (low 2 bits: 0 up,
    1 right, 2 down, 3 left). Returns the new HL. Quirk: left (DEC L) never
    changes the third, because DEC leaves carry clear."""
    zx.spend(66)
    h, low, d = hl >> 8, hl & 0xFF, a & DIR_MASK
    if d == DIR_UP:
        low -= SCREEN_COLS
        if low < 0:
            low, h = low + 256, h - THIRD_STEP
    elif d == DIR_RIGHT:
        low += 1
        if low > 0xFF:
            low, h = 0, h + THIRD_STEP
    elif d == DIR_DOWN:
        low += SCREEN_COLS
        if low > 0xFF:
            low, h = low - 256, h + THIRD_STEP
    else:
        low = low - 1 & 0xFF
    return (h & 0xFF) << 8 | low


def PrintDigit(bc, de, hl, attr):
    """Digit part of PrintNumber (A = CHAR_0, carry clear on entry): divide HL by
    the power of ten BC, print the quotient digit at DE (see PrintChar).
    Returns the next DE, the remainder HL and the next attr."""
    zx.spend(31 * (hl // bc + 1) + 10)      # the subtraction loop
    de, attr = PrintChar(CHAR_0 + hl // bc, de, attr)
    return de, hl % bc, attr


def PrintNumber(de, hl):
    """Print HL as five decimal digits at DE (the status line's score) while
    GameActive bit 0 is set. Returns nothing. With printing off the Z80's carry
    leaks into the next digit's subtraction, which changes only registers."""
    zx.spend(237)
    attr = SetAttrPointer(de)
    for power in (10000, 1000, 100, 10):
        de, hl, attr = PrintDigit(power, de, hl, attr)
    PrintChar(CHAR_0 + hl, de, attr)


def DrawSprite(c, de, hl, attr):
    """Draw the 2x2-cell sprite graphic at DE (32 bytes, cell order TL, TR, BL,
    BR) with attribute C at screen offset HL; attr is HL' (SetAttrPointer of HL
    before the call). Returns nothing."""
    zx.spend(211)
    hl = hl + SCREEN & 0xFFFF
    for _ in range(2):
        de, hl, attr = DrawCell(c, de, hl, attr)
    hl = next_row(hl)
    attr = SetAttrPointer(hl)
    for _ in range(2):
        de, hl, attr = DrawCell(c, de, hl, attr)


def MergeObjectAttr(e, attr):
    """Merge the object colour at attribute address attr into the running answer
    E' (0 none): guard wins, then bell, then flower. Returns the new E'.
    (The asm takes E and HL; GetBlockObject calls it after EXX.)"""
    a = mem[attr]
    if a == ATTR_GUARD:
        zx.spend(42)
        return a
    if a == ATTR_BELL:
        zx.spend(75)
        return e if e == ATTR_GUARD else a
    if a == ATTR_FLOWER:
        zx.spend(78)
        return e or a
    zx.spend(61)
    return e


def GetBlockObject(hl):
    """The object attribute in the 2x2 cells at screen offset HL: $3B guard,
    $3A bell, $3C flower, 0 none (A; callers branch on A or on Z = none)."""
    zx.spend(275)
    attr = SetAttrPointer(hl + SCREEN & 0xFFFF)
    e = 0
    for cell in (0, 1, SCREEN_COLS, SCREEN_COLS + 1):
        e = MergeObjectAttr(e, attr + cell)
    return e


def SaveBackgroundCell(de, hl, attr):
    """Copy one cell (attribute at attr, 8 bitmap rows at HL) to the 9-byte slot
    at DE; a guard-coloured cell is stored as blank floor. Returns the next DE,
    HL (cell to the right) and attr."""
    a = mem[attr]
    if a == ATTR_GUARD:
        zx.spend(282)
        mem[de:de + 1 + CELL_BYTES] = bytes([ATTR_BLANK]) + bytes(CELL_BYTES)
        # blank cell: H was not advanced, so a wrap of L adds the third itself
        hl = ((hl >> 8) + (THIRD_STEP if hl & 0xFF == 0xFF else 0) & 0xFF) << 8 | hl + 1 & 0xFF
    else:
        zx.spend(371)
        mem[de] = a
        for r in range(CELL_BYTES):
            mem[de + 1 + r] = mem[hl + (r << 8)]
        hl = next_cell(hl + (CELL_BYTES << 8))
    return de + 1 + CELL_BYTES, hl, attr + 1


def SaveBackground(hl):
    """Save the 2x2 cells at screen offset HL (four 9-byte cells: attribute, 8
    rows; guard cells as blank) into SavedBackground. Returns nothing. Quirk:
    the asm pops DE and HL swapped, so DE/HL return each other's value; no
    caller uses them."""
    zx.spend(290)
    hl = hl + SCREEN & 0xFFFF
    attr = SetAttrPointer(hl)
    de = SavedBackground
    for _ in range(2):
        de, hl, attr = SaveBackgroundCell(de, hl, attr)
    attr += SCREEN_COLS - 2
    hl = next_row(hl)
    for _ in range(2):
        de, hl, attr = SaveBackgroundCell(de, hl, attr)


def ProbeCell(e, attr):
    """Classify the cell at attribute address attr for ProbeMove and update the
    running total E': wall = $FF (sticky), pad +1, arrow +4. Returns E'.
    (The asm takes E and HL; ProbeMove calls it after EXX.)"""
    if e == PROBE_BLOCKED:
        zx.spend(12)
        return e
    a = mem[attr]
    if a == ATTR_WALL:
        zx.spend(44)
        return PROBE_BLOCKED
    if a == ATTR_PAD:
        zx.spend(71)
        return e + 1 & 0xFF
    if a == ATTR_ARROW:
        zx.spend(88)
        return e + PROBE_ARROW_WEIGHT & 0xFF
    zx.spend(69)
    return e


def ProbeMove(a, hl):
    """What is one step from the 2x2 block at screen offset HL in direction A?
    Returns MOVE_FREE 0, MOVE_WRAP 1 (2+ pads), MOVE_EXIT 2 (2+ arrows),
    MOVE_BLOCKED 3 (a wall), or $82 for pads and arrows mixed (callers treat it
    as blocked)."""
    zx.spend(337)
    attr = SetAttrPointer(StepCell(a, hl + SCREEN & 0xFFFF))
    e = 0
    for cell in (0, 1, SCREEN_COLS, SCREEN_COLS + 1):
        e = ProbeCell(e, attr + cell)
    if e == PROBE_BLOCKED:
        return MOVE_BLOCKED
    e = e & PROBE_MANY_BITS
    e = e >> 1 | (e & 1) << 7       # RRC A
    if e == MOVE_WRAP:
        return e
    return e >> 1 | (e & 1) << 7
