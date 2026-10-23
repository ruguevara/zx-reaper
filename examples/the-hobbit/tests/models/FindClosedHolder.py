"""FindClosedHolder: climb the holders of the record in IX to the first one that is neither open nor alive."""
import _objects as W
from labels import *  # noqa: F403
ROUTINE = 'FindClosedHolder'
INPUTS = []
OUTPUTS = W.out(['A', 'IX'], [])
KINDS = ['typical', 'boundary']
def cases(rnd):
    for _ in range(250):
        oid, rec = W.rec_pick(rnd)
        yield 'typical', W.case(rnd, IX=rec, **W.noise(rnd, 'A'))
    for oid, rec in W.ENTRIES[:12]:
        yield 'boundary', W.case(rnd, IX=rec, mem={rec + 1: 0xFF})


def port(regs):
    return W.run('FindClosedHolder', regs, OUTPUTS)
