"""RandomSigned: a random number from -A to A from the seed and memory bytes; retries a repeated seed."""
import _objects as W
from labels import *  # noqa: F403
ROUTINE = 'RandomSigned'
INPUTS = []
OUTPUTS = W.out(['A', 'BC', 'IX', 'HL', 'DE', 'ZF', 'CF', 'SF'], [('RandomSeed', 1), ('RandomRomPtr', 2)])
KINDS = ['typical', 'boundary']
def cases(rnd):
    for _ in range(300):
        yield 'typical', W.case(rnd, False, A=rnd.randrange(1, 100), DE=rnd.randrange(0x4000),
                                mem={RandomSeed: rnd.randrange(256), RandomRomPtr + 1: rnd.randrange(0x7F),
                                     RandomRomPtr: rnd.randrange(256)},
                                **W.noise(rnd, 'BC', 'IX', 'HL'))
    for a in (0, 1, 0x7F, 0x80, 0xFF):             # the doubling overflows from 0x80
        for page in (0x10, 0xFF):
            yield 'boundary', W.case(rnd, False, A=a, DE=0x20, mem={RandomSeed: 0x55, RandomRomPtr + 1: page, RandomRomPtr: 0x30})
    for _ in range(30):                            # retry: the mix gives the seed again
        page = rnd.randrange(0x90, 0xB0)
        yield 'boundary', W.case(rnd, False, A=rnd.randrange(1, 100), DE=0,
                                 mem={RandomSeed: rnd.randrange(256), RandomRomPtr + 1: page - 1, RandomRomPtr: 0,
                                      page << 8: 0, (page << 8) + 1: 0, ((page + 1) << 8): 0x10, ((page + 1) << 8) + 1: 0x20})


def port(regs):
    return W.run('RandomSigned', regs, OUTPUTS)
