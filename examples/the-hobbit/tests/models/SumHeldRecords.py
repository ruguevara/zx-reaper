"""SumHeldRecords: add a field of the records held by A to C (B = 0 sizes, recursive; else weights)."""
import _objects as W
from labels import *  # noqa: F403
ROUTINE = 'SumHeldRecords'
INPUTS = []
OUTPUTS = W.out(['A', 'C', 'IX', 'IY'], [])
KINDS = ['typical', 'boundary']
def cases(rnd):
    for _ in range(150):
        yield 'typical', W.case(rnd, A=rnd.choice(W.IDS[:25]), B=rnd.choice([0, 1]), C=rnd.randrange(30), **W.noise(rnd, 'IX', 'IY'))
    for c in (0, 100, 127, 128, 255):
        for b in (0, 1):
            yield 'boundary', W.case(rnd, A=1, B=b, C=c, **W.noise(rnd, 'IX', 'IY'))


def port(regs):
    return W.run('SumHeldRecords', regs, OUTPUTS)
