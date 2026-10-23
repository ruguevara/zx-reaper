"""RandomUpTo: the absolute value of RandomSigned."""
import _objects as W
from labels import *  # noqa: F403
ROUTINE = 'RandomUpTo'
INPUTS = []
OUTPUTS = W.out(['A', 'BC', 'IX', 'HL', 'ZF', 'SF'], [('RandomSeed', 1), ('RandomRomPtr', 2)])
KINDS = ['typical', 'boundary']
def cases(rnd):
    for _ in range(200):
        yield 'typical', W.case(rnd, False, A=rnd.randrange(1, 100), DE=rnd.randrange(0x4000),
                                mem={RandomSeed: rnd.randrange(256), RandomRomPtr + 1: rnd.randrange(0x7F)},
                                **W.noise(rnd, 'BC', 'IX', 'HL'))
    for a in (0, 1, 0x7F, 0x80, 0xFF):
        yield 'boundary', W.case(rnd, False, A=a, DE=0, mem={RandomSeed: 7, RandomRomPtr + 1: 0xFF, RandomRomPtr: 0x10})


def port(regs):
    return W.run('RandomUpTo', regs, OUTPUTS)
