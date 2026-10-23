"""Ported from src/drawing.asm: location pictures: the command interpreter, lines, flood fill, attributes.
Values pass in the registers `r` (port/regs.py); conventions: port/CONTRACT.md."""
from labels import *  # noqa: F403  (first: port functions shadow routine labels)
import calls  # noqa: F401
from regs import r  # noqa: F401
from variables import v  # noqa: F401
from zxpyxel import Goto, mem, mem16, zx  # noqa: F401
import engine
import objects


def _xor_a():
    """XOR A: A = 0 and its flags."""
    r.a = 0
    r.zf, r.sf, r.pf, r.cf = True, False, True, False


def _inc8(x):
    """INC x on an 8-bit value: sets Z, S, PF (carry is kept); returns the result."""
    x = x + 1 & 0xFF
    r.zf, r.sf, r.pf = x == 0, x > 0x7F, x == 0x80
    return x


def _dec8(x):
    """DEC x on an 8-bit value: sets Z, S, PF (carry is kept); returns the result."""
    x = x - 1 & 0xFF
    r.zf, r.sf, r.pf = x == 0, x > 0x7F, x == 0x7F
    return x


def DrawLocationPicture():
    """Draw the picture of location A, if pictures are on and the location has one.
    PictureFound = the id, or $FF (none, or pictures off). All registers preserved."""
    if v.PicturesEnabled == 0:
        v.PictureFound = 0xFF
        return
    saved = (r.a, r.zf, r.cf, r.sf, r.pf, r.hl, r.bc, r.de, r.ix)
    r.ix = PictureTable
    objects.FindIdRecord()
    v.PictureFound = r.a
    r.l = mem[r.ix + 1 & 0xFFFF]
    r.h = mem[r.ix + 2 & 0xFFFF]
    if not r.zf:
        RunPictureCommands()
    r.a, r.zf, r.cf, r.sf, r.pf, r.hl, r.bc, r.de, r.ix = saved


def RunPictureCommands():
    """Interpret the picture data at HL: StartPicture, then move / line / fill / paint
    commands until a $00 byte. HL, DE, BC, IY are preserved; A and the flags are not."""
    saved = (r.iy, r.hl, r.de, r.bc)
    r.iy = r.hl
    if not StartPicture():          # too dark: the picture is abandoned
        RunPictureCommands_End(saved)
        return
    r.d, r.e = PIC_START_X, PIC_START_Y
    r.b = r.c = r.l = 1
    while True:
        a = r.a = mem[r.iy]
        if a == 0:
            break
        r.iy = r.iy + 1 & 0xFFFF
        if a == PIC_CMD_MOVE:
            r.d, r.e = mem[r.iy], mem[r.iy + 1 & 0xFFFF]
            r.iy = r.iy + 2 & 0xFFFF
        elif a & 0x80:
            b2 = mem[r.iy]
            r.iy = r.iy + 1 & 0xFFFF
            r.c = a & 0x07
            r.l = (b2 & 0x3F) + 1 & 0xFF
            r.b = ((a >> 1 | a << 7) & 0x3C | b2 >> 6) + 1 & 0xFF
            DrawPictureLine()
        elif a & 0x40:
            r.a = a & 0x07
            seed = r.de             # the pen is kept
            r.d, r.e = mem[r.iy], mem[r.iy + 1 & 0xFFFF]
            r.iy = r.iy + 2 & 0xFFFF
            FloodFill()
            r.de = seed
        elif a & 0x20:
            _paint(a)
        # other values below $20 are skipped
    RunPictureCommands_End(saved)


def _paint(a):
    """The paint command ($20-$27): the runs of attribute cells get paper (a & 7) * 8."""
    saved = (r.hl, r.de, r.bc)
    paper = (a & 0x07) << 3
    r.h, r.l = mem[r.iy], mem[r.iy + 1 & 0xFFFF]
    r.iy = r.iy + 2 & 0xFFFF
    while True:
        run = mem[r.iy]
        r.iy = r.iy + 1 & 0xFFFF
        if run == PIC_ATTR_END:
            break
        direction = run & 0x03
        for _ in range((run >> 2 & 0x3F) + 1):
            ink = (mem[r.hl] & 0x07) << 3
            if ink == paper:
                ink ^= PIC_PAPER_MASK   # keep the ink visible
            mem[r.hl] = ink >> 3 | paper
            (AttrUp, AttrRight, AttrDown, AttrLeft)[direction]()
        zx.spend(150 * ((run >> 2 & 0x3F) + 1))
    r.hl, r.de, r.bc = saved


def RunPictureCommands_End(saved):
    """Exit of the drawer (the asm pops these from the stack): restore IY, HL, DE, BC."""
    r.iy, r.hl, r.de, r.bc = saved


def FloodFill():
    """Flood fill with ink A from the seed pen position D, E (scan-line fill, seeds on
    a stack above the sentinel). PicVar1 ends 0 (the lines after a fill are black).
    DE, HL preserved; A = 0; flags from the last CP of the sentinel (Z)."""
    v.PicVar1 = r.a
    saved = (r.de, r.hl)
    seeds = []
    while True:
        # go left to the first lit pixel (or the edge): the span starts there
        while True:
            TestPixel()
            if not r.zf:
                PlotPixel()
                MovePenRight()
                break
            MovePenLeft()
            if r.zf:
                break
        mem16[DrawVar1] = 0     # DrawVar1 and DrawVar2: no seed pushed above or below
        while True:
            zx.spend(170)       # the column loop's own instructions
            MovePenUp()
            r.a = 0
            if not r.zf:
                TestPixel()
                r.a = 0
                if r.zf:
                    if v.DrawVar1 == 0:
                        seeds.append(r.de)
                        r.a = 1
                    else:
                        r.a = v.DrawVar1
                MovePenDown()
            v.DrawVar1 = r.a
            MovePenDown()
            r.a = 0
            if not r.zf:
                TestPixel()
                r.a = 0
                if r.zf:
                    if v.DrawVar2 == 0:
                        seeds.append(r.de)
                        r.a = 1
                    else:
                        r.a = v.DrawVar2
                MovePenUp()
            v.DrawVar2 = r.a
            PlotPixel()
            MovePenRight()
            if r.zf:
                break
            TestPixel()
            if not r.zf:
                PlotPixel()
                break
        r.de = seeds.pop() if seeds else FILL_SENTINEL
        r.a = r.e
        r.cp(FILL_SENTINEL)
        if r.zf:
            break
    r.a = 0
    v.PicVar1 = 0
    r.de, r.hl = saved


def TestPixel():
    """Is the pixel at the pen D, E lit? A = mask AND screen byte; Z clear, NZ lit.
    HL preserved."""
    hl = r.hl
    PenToScreen()
    r.a &= mem[r.hl]
    r.zf, r.sf, r.pf, r.cf = r.a == 0, r.a > 0x7F, r.a.bit_count() % 2 == 0, False
    r.hl = hl
    zx.spend(55)


def AttrUp():
    """Attribute address HL up one row, unless that leaves $5800-$59FF. AF, DE preserved."""
    new = r.hl - ATTR_ROW & 0xFFFF
    if new >> 8 != 0x57:
        r.hl = new


def AttrDown():
    """Attribute address HL down one row, unless that passes $59FF. AF, DE preserved.
    (The asm's JR NZ lands in the second byte of SBC HL,DE, a no-op.)"""
    new = r.hl + ATTR_ROW & 0xFFFF
    if new >> 8 != 0x5A:
        r.hl = new


def AttrLeft():
    """Attribute address HL left one cell, unless that passes $5800 (it wraps to the
    row above at column 0). AF preserved."""
    new = r.hl - 1 & 0xFFFF
    if new >> 8 != 0x57:
        r.hl = new


def AttrRight():
    """Attribute address HL right one cell, unless that reaches $5A00 (it wraps to the
    next row at column 31). AF preserved."""
    new = r.hl + 1 & 0xFFFF
    if new >> 8 != 0x5A:
        r.hl = new


def MovePenUp():
    """Pen y up one. Z (and no move) at the top edge, y 127; NZ moved. H destroyed."""
    r.e = _inc8(r.e)
    if r.e & 0x80:
        r.e = _dec8(r.e)
        r.h = r.a
        _xor_a()
        r.a = r.h
    else:
        MovePen_Moved()
    zx.spend(30)


def MovePen_Moved():
    """Moved: Z clear (A kept, H = A)."""
    r.h = r.a
    v8 = r.a | 0x01
    r.zf, r.sf, r.pf, r.cf = False, v8 > 0x7F, v8.bit_count() % 2 == 0, False
    r.a = r.h


def MovePenDown():
    """Pen y down one. Z (and no move) at the bottom edge, y 0; NZ moved."""
    r.e = _dec8(r.e)
    if r.e & 0x80:
        r.e = _inc8(r.e)
    else:
        MovePen_Moved()
    zx.spend(30)


def MovePenRight():
    """Pen x right one. Z (and no move) at the right edge, x 255. H destroyed there."""
    r.d = _inc8(r.d)
    if r.zf:
        r.d = _dec8(r.d)
        r.h = r.a
        _xor_a()
        r.a = r.h
    zx.spend(30)


def MovePenLeft():
    """Pen x left one. Z (and no move) at the left edge, x 0. H destroyed."""
    r.d = _dec8(r.d)
    r.h = r.a
    res = r.d - 0xFF & 0xFF         # CP $FF
    r.zf, r.sf, r.cf = r.d == 0xFF, res > 0x7F, r.d < 0xFF
    r.pf = bool((r.d ^ 0xFF) & (r.d ^ res) & 0x80)
    r.a = r.h
    if r.zf:
        r.d = _inc8(r.d)
    zx.spend(30)


def DrawPictureLine():
    """Draw L pixels from the pen D, E, moving the pen after each plot: a major step
    every time (C bit 0: vertical, else horizontal) and a minor step every B major
    steps (C bit 1: down, else up; bit 2: left, else right). Stops at an edge.
    BC, HL preserved; the pen ends one step past the last pixel."""
    saved = (r.hl, r.bc)
    b0 = r.b

    def step_x():
        MovePenLeft() if r.c & 0x04 else MovePenRight()

    def step_y():
        MovePenDown() if r.c & 0x02 else MovePenUp()

    major, minor = (step_y, step_x) if r.c & 0x01 else (step_x, step_y)
    while True:
        PlotPixel()
        zx.spend(80)            # the loop's own instructions
        major()
        if r.zf:
            break
        r.b = _dec8(r.b)
        if r.zf:
            minor()
            if r.zf:
                break
            r.b = b0
        r.l = _dec8(r.l)
        if r.zf:
            break
    r.hl, r.bc = saved


def PlotPixel():
    """Set the pixel at the pen D, E and set the ink of its attribute cell to PicVar1
    (paper kept, BRIGHT and FLASH cleared; ink = paper becomes 7 - ink). A = the
    new screen byte, flags of its OR; HL preserved."""
    hl = r.hl
    PenToScreen()
    mask, addr = r.a, r.hl
    attr = 0x58 + ((addr >> 8 & 0x18) >> 3) << 8 | addr & 0xFF
    paper = mem[attr] & 0x07 * PAPER
    mem[attr] = paper
    ink = v.PicVar1
    ink = (ink << 3 | ink >> 5) & 0xFF
    if ink == paper:
        ink ^= 0x07 * PAPER
    mem[attr] = (ink >> 3 | ink << 5) & 0xFF | paper
    r.a = mask | mem[addr]
    mem[addr] = r.a
    r.zf, r.sf, r.pf, r.cf = False, r.a > 0x7F, r.a.bit_count() % 2 == 0, False
    r.hl = hl
    zx.spend(230)


def PenToScreen():
    """Screen address of the pixel at the pen D, E (row from the top = $7F - E) in HL
    and its bit mask in A. BC preserved."""
    row = 0x7F - r.e & 0xFF
    r.h = 0x40 | row & 0x07 | (row & 0xC0) >> 3
    r.l = (row & 0x38) << 2 & 0xFF | r.d >> 3 & 0x1F
    r.a = 0x80 >> (r.d & 0x07)
    # the flags of the last RRC A of the mask loop
    r.zf, r.sf, r.pf, r.cf = False, r.a == 0x80, False, r.a == 0x80
    zx.spend(181 + 21 * (r.d & 0x07))


def StartPicture():
    """Border, picture bitmap cleared, attributes filled, from the header bytes at IY
    (border, attribute; IY advances past them). Too dark (CheckDark carry): both bytes
    are 0 and the picture is abandoned: returns False (the asm drops its return
    address and leaves the drawer at RunPictureCommands_End), else True."""
    engine.CheckDark()
    r.ex_af()                       # the carry is parked in AF'
    r.a = mem[r.iy]
    r.iy = r.iy + 1 & 0xFFFF
    r.ex_af()
    if r.cf:
        r.ex_af()
        _xor_a()
        r.ex_af()
    r.ex_af()
    zx.out(PORT_ULA, r.a)
    saved = (r.hl, r.de, r.bc)
    mem[SCREEN:SCREEN + PICTURE_BITMAP_SIZE] = bytes(PICTURE_BITMAP_SIZE)
    r.a = mem[r.iy]
    r.iy = r.iy + 1 & 0xFFFF
    r.ex_af()
    if r.cf:
        r.ex_af()
        _xor_a()
        r.ex_af()
    r.ex_af()
    mem[ATTRS:ATTRS + PICTURE_ATTRS_SIZE] = bytes([r.a]) * PICTURE_ATTRS_SIZE
    r.pf = False                    # LDIR leaves PF clear
    zx.spend(21 * (PICTURE_BITMAP_SIZE + PICTURE_ATTRS_SIZE))
    r.hl, r.de, r.bc = saved
    r.ex_af()
    return not r.cf
