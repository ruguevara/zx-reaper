"""LocationSpareCapacity: a location capacity minus the weights of the single-location records there."""
import _objects as W
from labels import *  # noqa: F403
ROUTINE = 'LocationSpareCapacity'
INPUTS = []
OUTPUTS = W.out(['A', 'BC', 'IX', 'IY'], [])
KINDS = ['typical', 'boundary']
def cases(rnd):
    for _ in range(150):
        loc = rnd.randrange(0x20)
        yield 'typical', W.case(rnd, A=loc, **W.noise(rnd, 'BC', 'IX', 'IY'))
    for loc in (0, 0x1F, 0x4F, 0x20):
        yield 'boundary', W.case(rnd, A=loc, **W.noise(rnd, 'BC', 'IX', 'IY'))
    for _ in range(40):                            # many heavy records at one location: over capacity
        loc = rnd.randrange(1, 0x20)
        m = {}
        for oid, rec in W.ENTRIES[1:]:
            m.update({rec: 1, rec + 0x10: loc, rec + 2: rnd.choice([0, 3, 40])})
        yield 'boundary', W.case(rnd, A=loc, mem=m, **W.noise(rnd, 'BC', 'IX', 'IY'))


def port(regs):
    return W.run('LocationSpareCapacity', regs, OUTPUTS)
