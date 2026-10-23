"""LA1AE: walk the object table from its base for the id in A (the asm compares with (IY+1) of the walk itself)."""
import _objects as W
from labels import *  # noqa: F403
ROUTINE = 'LA1AE'
INPUTS = []
OUTPUTS = W.out(['A', 'IX', 'IY'], [])
KINDS = ['typical', 'boundary']
def cases(rnd):
    for _ in range(100):
        yield 'typical', W.case(rnd, A=rnd.choice(W.IDS + [0xFF, 0xFE]), **W.noise(rnd, 'IX', 'IY'))
    for a in (0, 0xFF, W.IDS[-1]):
        yield 'boundary', W.case(rnd, A=a, **W.noise(rnd, 'IX', 'IY'))


def port(regs):
    return W.run('LA1AE', regs, OUTPUTS)
