"""CountHeldPresent: the number of records held by a holder with the present flag."""
import _objects as W
from labels import *  # noqa: F403
ROUTINE = 'CountHeldPresent'
INPUTS = []
OUTPUTS = W.out(['A', 'BC', 'IX', 'IY'], [])
KINDS = ['typical', 'boundary']
def cases(rnd):
    for _ in range(150):
        yield 'typical', W.case(rnd, A=rnd.choice(W.IDS[:25] + [0xFF]), **W.noise(rnd, 'BC', 'IX', 'IY'))
    for holder in (0, 0xFF, 0x77, W.IDS[-1]):
        yield 'boundary', W.case(rnd, A=holder, **W.noise(rnd, 'BC', 'IX', 'IY'))


def port(regs):
    return W.run('CountHeldPresent', regs, OUTPUTS)
