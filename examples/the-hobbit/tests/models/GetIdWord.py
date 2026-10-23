"""GetIdWord: the dictionary word for an id (bit 7 ignored) from NameWordTable."""
import _objects as W
from labels import *  # noqa: F403
ROUTINE = 'GetIdWord'
INPUTS = []
OUTPUTS = W.out(['A', 'DE', 'HL'], [])
KINDS = ['typical', 'boundary']
def cases(rnd):
    for _ in range(100):
        yield 'typical', W.case(rnd, False, A=rnd.randrange(1, 22), **W.noise(rnd, 'DE', 'HL'))
    for a in (0, 1, 0x7F, 0x80, 0x81, 0xFF):
        yield 'boundary', W.case(rnd, False, A=a, **W.noise(rnd, 'DE', 'HL'))


def port(regs):
    return W.run('GetIdWord', regs, OUTPUTS)
