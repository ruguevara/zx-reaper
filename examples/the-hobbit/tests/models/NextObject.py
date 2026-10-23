"""NextObject steps IX through ObjectTable, loading IY and A; BC, DE, HL kept."""
import _objects as W
from labels import *  # noqa: F403
ROUTINE = 'NextObject'
INPUTS = []
OUTPUTS = W.out(['A', 'IX', 'IY', 'BC', 'DE', 'HL', 'ZF', 'CF', 'SF'], [])
KINDS = ['typical', 'boundary']
def cases(rnd):
    for _ in range(150):
        k = rnd.randrange(-1, len(W.ENTRIES))
        yield 'typical', W.case(rnd, False, IX=ObjectTable + 3 * k, **W.noise(rnd, 'BC', 'DE', 'HL', 'IY'))
    for ix in (ObjectTable - 3, W.END_ENTRY - 3, W.END_ENTRY - 6, W.END_ENTRY):
        yield 'boundary', W.case(rnd, False, IX=ix, **W.noise(rnd, 'BC', 'DE', 'HL'))


def port(regs):
    return W.run('NextObject', regs, OUTPUTS)
