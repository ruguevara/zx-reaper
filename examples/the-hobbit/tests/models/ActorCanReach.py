"""ActorCanReach: CanReach with the observer the current actor."""
import _objects as W
from labels import *  # noqa: F403
ROUTINE = 'ActorCanReach'
INPUTS = []
OUTPUTS = W.out(['A', 'ZF', 'IX', 'IY', 'BC'], [])
KINDS = ['typical', 'boundary']


def make(rnd, extra=None):
    o, ob = W.rec_pick(rnd), W.rec_pick(rnd)
    mem = {ActorRecord: W.lo_hi(ob[1])}
    mem.update(extra(o, ob) if extra else {})
    return W.case(rnd, A=o[0], IY=o[1], IX=0x1234, mem=mem, **W.noise(rnd, 'BC'))


def cases(rnd):
    for _ in range(300):
        yield 'typical', make(rnd)
    for _ in range(60):                            # same closed holder, or both out in the open
        yield 'boundary', make(rnd, lambda o, ob: {o[1] + 1: 0xFF, ob[1] + 1: 0xFF, o[1] + 0x10: 7,
                                                    ob[1] + 0x10: rnd.choice([7, 8]), o[1] + 7: 0x80, ob[1] + 7: 0x80})
    yield 'boundary', make(rnd, lambda o, ob: {o[1] + 7: 0x00})            # not present
    yield 'boundary', make(rnd, lambda o, ob: {o[1] + 1: 0xFF, ob[1] + 1: 0xFF, o[1] + 0x10: 7,
                                                ob[1] + 0x10: 8, o[1]: 0, o[1] + 7: 0x80})   # no locations: 256 passes


def port(regs):
    return W.run('ActorCanReach', regs, OUTPUTS)
