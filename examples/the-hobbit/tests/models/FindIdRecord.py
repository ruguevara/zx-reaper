"""FindIdRecord: walk 3-byte records from IX for the id in A, up to the END_MARK."""
import _objects as W
from labels import *  # noqa: F403
ROUTINE = 'FindIdRecord'
INPUTS = []
OUTPUTS = W.out(['A', 'IX', 'BC', 'DE', 'HL', 'ZF', 'CF', 'SF'], [])
KINDS = ['typical', 'boundary']
def cases(rnd):
    for _ in range(150):
        k = rnd.randrange(len(W.ENTRIES))
        yield 'typical', W.case(rnd, False, A=rnd.choice(W.IDS), IX=ObjectTable + 3 * (k // 2), **W.noise(rnd, 'BC', 'DE', 'HL'))
    for a, ix in ((0, ObjectTable), (W.IDS[-1], ObjectTable), (0xFF, ObjectTable), (0x77, ObjectTable),
                  (W.IDS[-1], W.END_ENTRY - 3), (3, W.END_ENTRY), (0xFF, W.END_ENTRY)):
        yield 'boundary', W.case(rnd, False, A=a, IX=ix, **W.noise(rnd, 'BC', 'DE', 'HL'))


def port(regs):
    return W.run('FindIdRecord', regs, OUTPUTS)
