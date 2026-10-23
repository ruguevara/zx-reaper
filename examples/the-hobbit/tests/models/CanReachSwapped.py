"""CanReachSwapped: CanReach with the object in IX and the observer in IY."""
import _objects as W
from labels import *  # noqa: F403
ROUTINE = 'CanReachSwapped'
INPUTS = []
OUTPUTS = W.out(['A', 'ZF', 'IX', 'IY', 'BC'], [])
KINDS = ['typical', 'boundary']
def cases(rnd):
    for _ in range(300):
        o, ob = W.rec_pick(rnd), W.rec_pick(rnd)
        yield 'typical', W.case(rnd, A=o[0], IX=o[1], IY=ob[1], **W.noise(rnd, 'BC'))
    for _ in range(60):                            # same closed holder, or both out in the open
        o, ob = W.rec_pick(rnd), W.rec_pick(rnd)
        m = {o[1] + 1: 0xFF, ob[1] + 1: 0xFF, o[1] + 0x10: 7, ob[1] + 0x10: rnd.choice([7, 8]), o[1] + 7: 0x80, ob[1] + 7: 0x80}
        yield 'boundary', W.case(rnd, A=o[0], IX=o[1], IY=ob[1], **W.noise(rnd, 'BC'), mem=m)
    oid, rec = W.ENTRIES[3]
    o, ob = W.rec_pick(rnd), W.rec_pick(rnd)
    yield 'boundary', W.case(rnd, A=o[0], IX=o[1], IY=ob[1], **W.noise(rnd, 'BC'), mem={o[1] + 7: 0x00})      # not present
    yield 'boundary', W.case(rnd, A=o[0], IX=o[1], IY=ob[1], **W.noise(rnd, 'BC'), mem={o[1] + 1: 0xFF, ob[1] + 1: 0xFF, o[1] + 0x10: 7, ob[1] + 0x10: 8, o[1]: 0})   # no locations: 256 passes


def port(regs):
    return W.run('CanReachSwapped', regs, OUTPUTS)
