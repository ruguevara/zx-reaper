"""The Z80 registers as the port's routines share them.

The Hobbit has about 400 entry points, many of them entered in the middle or
left by a tail jump into another routine, so the port passes values between
routines in these registers, as the Z80 does, instead of per-routine
signatures (the zx-port skill's first step: the register interface; stage 4
gives the logic real arguments). 8-bit registers are ints 0-255 (mask on
assignment where the asm can overflow), the pairs are properties over them,
IX and IY are 16-bit ints. The flags are the bools a caller tests: zf (Z set),
cf (carry set), and sf, pf where some caller tests them. exx() and ex_af()
swap with the alternate set.
"""


class Registers:
    def __init__(self):
        self.reset()

    def reset(self):
        self.a = self.b = self.c = self.d = self.e = self.h = self.l = 0
        self.ix = self.iy = 0
        self.zf = self.cf = self.sf = self.pf = False
        self.alt = [0] * 6                  # B' C' D' E' H' L'
        self.alt_af = [0, False, False, False, False]   # A' and its flags

    @property
    def bc(self):
        return self.b << 8 | self.c

    @bc.setter
    def bc(self, v):
        self.b, self.c = v >> 8 & 0xFF, v & 0xFF

    @property
    def de(self):
        return self.d << 8 | self.e

    @de.setter
    def de(self, v):
        self.d, self.e = v >> 8 & 0xFF, v & 0xFF

    @property
    def hl(self):
        return self.h << 8 | self.l

    @hl.setter
    def hl(self, v):
        self.h, self.l = v >> 8 & 0xFF, v & 0xFF

    def exx(self):
        main = [self.b, self.c, self.d, self.e, self.h, self.l]
        self.b, self.c, self.d, self.e, self.h, self.l = self.alt
        self.alt = main

    def ex_af(self):
        main = [self.a, self.zf, self.cf, self.sf, self.pf]
        self.a, self.zf, self.cf, self.sf, self.pf = self.alt_af
        self.alt_af = main

    def ex_de_hl(self):
        self.d, self.e, self.h, self.l = self.h, self.l, self.d, self.e

    def set_zs(self, v):
        """Z and S from an 8-bit result (AND, OR, XOR, INC, DEC and the like)."""
        self.zf = v == 0
        self.sf = v > 0x7F
        return v

    def cp(self, n):
        """CP n: the flags of A - n (n an int 0-255)."""
        d = self.a - n
        self.cf = d < 0
        self.zf = d == 0
        self.sf = d & 0x80 != 0


r = Registers()
