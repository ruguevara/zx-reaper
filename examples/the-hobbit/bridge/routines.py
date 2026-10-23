"""The stage 4 routine that stands for each stage 3 routine, for
`python bridge/oracle.py routine NAME RECORD...`.

ROUTINES[name] = (clean, convert_in, convert_out): before each call of the
stage 3 routine `name` the oracle snapshots its registers (a Regs); after it,
it calls clean(state, *convert_in(regs_before)) on a copy of the state before
(answering its requests with the inputs stage 3 took in the call) and compares
the state after and the result: convert_out(regs_after) is what clean must
return (ANY: not compared). A stage 3 Goto is compared with the name
returned. One file per stage 4 module: bridge/routines_<module>.py."""
import glob
import importlib
import os

import paths  # noqa: F401


class Regs:
    """A snapshot of the stage 3 registers (port/regs.py)."""
    NAMES = ('a', 'b', 'c', 'd', 'e', 'h', 'l', 'ix', 'iy', 'zf', 'cf', 'sf', 'pf')

    def __init__(self, r):
        for n in self.NAMES:
            setattr(self, n, getattr(r, n))

    @property
    def bc(self):
        return self.b << 8 | self.c

    @property
    def de(self):
        return self.d << 8 | self.e

    @property
    def hl(self):
        return self.h << 8 | self.l


ANY = object()      # convert_out's answer when a routine's result is not compared


def none(regs):
    return ()


def nothing(regs):
    return None


ROUTINES = {}       # filled by bridge/routines_*.py

for _f in sorted(glob.glob(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'routines_*.py'))):
    ROUTINES.update(importlib.import_module(os.path.basename(_f)[:-3]).ROUTINES)
