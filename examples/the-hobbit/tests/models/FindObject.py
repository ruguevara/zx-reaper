"""FindObject: the record address of an object id (garbage IX when the id is not in the table)."""
import _objects as W
from labels import *  # noqa: F403
ROUTINE = 'FindObject'
INPUTS = []
OUTPUTS = W.out(['A', 'IX', 'HL', 'ZF', 'CF', 'SF'], [])
KINDS = ['typical', 'boundary']
def cases(rnd):
    for _ in range(150):
        yield 'typical', W.case(rnd, False, A=rnd.choice(W.IDS), **W.noise(rnd, 'IX', 'HL', 'BC', 'DE'))
    for a in (0, W.IDS[-1], 0x77, 0xFE, 0xFF, 0x80):
        yield 'boundary', W.case(rnd, False, A=a, **W.noise(rnd, 'IX', 'HL'))


def port(regs):
    return W.run('FindObject', regs, OUTPUTS)
