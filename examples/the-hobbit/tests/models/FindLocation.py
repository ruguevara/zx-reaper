"""FindLocation: the record address of a location id; out of range gives A = 0."""
import _objects as W
from labels import *  # noqa: F403
ROUTINE = 'FindLocation'
INPUTS = []
OUTPUTS = W.out(['A', 'IX', 'DE', 'HL', 'ZF', 'CF', 'SF'], [])
KINDS = ['typical', 'boundary']
def cases(rnd):
    for _ in range(150):
        yield 'typical', W.case(rnd, False, A=rnd.randrange(LOCATION_COUNT), **W.noise(rnd, 'IX', 'DE', 'HL'))
    for a in (0, 1, LOCATION_COUNT - 1, LOCATION_COUNT, LOCATION_COUNT + 1, 0x7F, 0x80, 0xFF):
        yield 'boundary', W.case(rnd, False, A=a, **W.noise(rnd, 'IX', 'DE', 'HL'))


def port(regs):
    return W.run('FindLocation', regs, OUTPUTS)
