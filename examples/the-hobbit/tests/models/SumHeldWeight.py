"""SumHeldWeight: the weights of what a holder directly holds ($FF on signed overflow)."""
import _objects as W
from labels import *  # noqa: F403
ROUTINE = 'SumHeldWeight'
INPUTS = []
OUTPUTS = W.out(['A', 'BC', 'IX', 'IY'], [])
KINDS = ['typical', 'boundary']
def cases(rnd):
    for _ in range(150):
        yield 'typical', W.case(rnd, A=rnd.choice(W.IDS[:25]), **W.noise(rnd, 'BC', 'IX', 'IY'))
    for holder in (0, 0xFF, 0x77):
        yield 'boundary', W.case(rnd, A=holder, **W.noise(rnd, 'BC', 'IX', 'IY'))
    for _ in range(40):                            # heavy: signed overflow
        m = {rec + 1: 1 for oid, rec in W.ENTRIES[2:]}
        m.update({rec + 2: rnd.choice([30, 60, 100]) for oid, rec in W.ENTRIES[2:]})
        yield 'boundary', W.case(rnd, A=1, mem=m, **W.noise(rnd, 'BC', 'IX', 'IY'))


def port(regs):
    return W.run('SumHeldWeight', regs, OUTPUTS)
