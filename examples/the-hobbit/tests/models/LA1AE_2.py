"""LA1AE_2: Z when the record in IX is a living character."""
import _objects as W
from labels import *  # noqa: F403
ROUTINE = 'LA1AE_2'
INPUTS = []
OUTPUTS = W.out(['A', 'ZF', 'CF', 'SF'], [])
KINDS = ['typical', 'boundary']
def cases(rnd):
    for oid, rec in W.ENTRIES:
        yield 'typical', W.case(rnd, False, IX=rec)
    for f in (0x00, 0x08, 0x40, 0x48, 0xFF, 0xC0):
        yield 'boundary', W.case(rnd, False, IX=W.REC[W.IDS[1]], mem={W.REC[W.IDS[1]] + 7: f})


def port(regs):
    return W.run('LA1AE_2', regs, OUTPUTS)
