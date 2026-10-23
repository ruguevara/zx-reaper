"""GetSingleLocation: the one location of an object, $FF when it has several."""
import _objects as W
from labels import *  # noqa: F403
ROUTINE = 'GetSingleLocation'
INPUTS = []
OUTPUTS = W.out(['A', 'IX', 'ZF'], [])
KINDS = ['typical', 'boundary']
def cases(rnd):
    for _ in range(150):
        yield 'typical', W.case(rnd, A=rnd.choice(W.IDS), **W.noise(rnd, 'IX'))
    for a in (0xFF, 0, W.IDS[-1]):
        yield 'boundary', W.case(rnd, A=a, **W.noise(rnd, 'IX'))
    for oid, rec in W.ENTRIES[:10]:
        yield 'boundary', W.case(rnd, A=oid, mem={rec: rnd.choice([0, 1, 3])}, **W.noise(rnd, 'IX'))


def port(regs):
    return W.run('GetSingleLocation', regs, OUTPUTS)
