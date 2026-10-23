"""Ported from src/devices.asm: the ZX printer and the keyboard scanner.
Values pass in the registers `r` (port/regs.py); conventions: port/CONTRACT.md."""
from labels import *  # noqa: F403  (first: port functions shadow routine labels)
import calls  # noqa: F401
from regs import r
from variables import v
from zxpyxel import Goto, mem, mem16, zx  # noqa: F401


def _port(a):
    """IN A,(PORT_PRINTER) and OUT (PORT_PRINTER),A put A on the high address lines."""
    return a << 8 | PORT_PRINTER


async def PrintStoryLine():
    """If PrinterFlag is set, send the bottom story row (8 dot lines of 32
    bytes) to the ZX printer through port $FB, as the ROM's COPY does, then stop
    the motor; give up at once when no printer answers. HL, DE, BC are kept;
    A is the last value sent (0 when the printer is off)."""
    if not v.PrinterFlag:
        r.a = 0
        r.zf = True
        return
    hl, e, a = STORY_LAST_ROW, 0, 0                     # D is 1 all the time (restored each line)
    while True:                                         # PrintStoryLine_Dots: one dot line
        zx.out(_port(a), a)
        while True:                                     # wait for the motor
            x = zx.inp(_port(a))
            a = x << 1 & 0xFF                           # ADD A,A
            zx.spend(11 + 4 + 10 + 12)
            await zx.sync()
            if x & 0x40:                                # JP M: no printer
                r.a = a
                return
            if x & 0x80:                                # JR NC: wait while bit 7 is clear
                break
        d = e                                           # D = 1: CP $02; SBC A,A is $FF
        d = ((d << 1 | d >> 7) & 0xFF) & e              # AND E; RLCA; AND E
        p = hl
        while True:                                     # PrintStoryLine_1: one byte
            c = mem[p]
            cf = 0                                      # the carry the RRA below takes in
            for _ in range(8):
                cf = c >> 7                             # RLC C
                c = (c << 1 | cf) & 0xFF
                a = cf << 7 | d >> 1                    # RRA (the carry of the RLC)
                cf = d & 1
                h = a
                while True:                             # wait until the stylus takes a dot
                    a = zx.inp(_port(a))
                    zx.spend(11 + 4 + 12)
                    await zx.sync()
                    carry = a & 1
                    a = cf << 7 | a >> 1                # RRA
                    cf = carry
                    if cf:
                        break
                zx.out(_port(h), h)
                zx.spend(4 + 8 + 4 + 4 + 11 + 13)
            p = p + 1 & 0xFFFF
            if p & 0x1F == 0:
                break
        a = 0                                           # LD A,L; AND $1F
        while True:
            a = zx.inp(_port(a))
            zx.spend(11 + 4 + 12)
            await zx.sync()
            if a & 1:                                   # RRA: bit 0
                break
        a = (d >> 1 | d << 7) & 0xFF                    # LD A,D; RRCA
        zx.out(_port(a), a)
        hl = hl & 0xFF | (hl >> 8) + 1 << 8 & 0xFF00    # INC H (the pixel line)
        e += 1
        if e & 8:
            break
    r.a = PRINTER_STOP_MOTOR
    zx.out(_port(r.a), r.a)


def _and_flags(x):
    """Flags of an AND with result x (carry clear); True when x is 0."""
    r.zf, r.cf, r.sf, r.pf = x == 0, False, x > 0x7F, bin(x).count('1') % 2 == 0
    return r.zf


def DelayShort():
    """Count BC down from 1000 (about 26,000 T-states). Leaves BC = 0, A = 0, Z."""
    zx.spend(1000 * 26 - 5 + 10)
    r.bc = 0
    r.a = 0
    r.zf = True


def ReadKey():
    """Scan the eight keyboard half-rows and return the key that is down now and
    was up in the previous scan (KeyPrevious): the last such half-row wins.
    A = its ASCII code (KeyTable, or ShiftKeyTable while CAPS or SYMBOL SHIFT is
    down) or 0 when there is none. Only A and the flags change; Z is left as
    the last AND/OR set it, so with a shift down it is Z even with a key
    found (quirk): callers test A."""
    bc = r.bc
    DelayShort()
    r.bc = bc
    mem16[KeyFound] = 0
    b = KB_ROW_CAPS_V
    for i in range(8):                                  # ReadKey_HalfRow
        a = zx.inp(b << 8 | PORT_ULA) & KEY_BITS | mem[KeyMasks + i]
        new = ~(~a & mem[KeyPrevious + i]) & 0xFF       # CPL; AND (HL); CPL
        if ~new & 0xFF:                                 # NZ: a newly pressed key
            mem16[KeyFound] = b << 8 | PORT_ULA
            mem[KeyFound] = new                         # 0 bit = the new key
        mem[KeyPrevious + i] = a
        b = (b << 1 | b >> 7) & 0xFF                    # RLC B
    key = mem16[KeyFound]
    if key == 0:
        r.a = 0
        r.zf, r.cf, r.sf, r.pf = True, False, False, True    # OR C of two zeros
        return
    b, c = key >> 8, key & 0xFF
    row = 0x100 - KEYS_PER_ROW                   # 5 * half-row index
    while True:
        row = row + KEYS_PER_ROW & 0xFF
        low, b = b & 1, (b >> 1 | b << 7) & 0xFF        # RRC B
        if not low:
            break
    index = row - 1 & 0xFF
    while True:                                         # plus the column
        index = index + 1 & 0xFF
        low, c = c & 1, (c >> 1 | c << 7) & 0xFF        # RRC C
        if not low:
            break
    table = KeyTable
    r.a = zx.inp(KB_ROW_CAPS_V << 8 | PORT_ULA) & KEY_CAPS_SHIFT
    shifted = _and_flags(r.a)
    if not shifted:
        r.a = zx.inp(KB_ROW_SPACE_B << 8 | PORT_ULA) & KEY_SYMBOL_SHIFT
        shifted = _and_flags(r.a)
    if shifted:
        table = ShiftKeyTable
    r.cf = table + index > 0xFFFF
    r.a = mem[table + index & 0xFFFF]
