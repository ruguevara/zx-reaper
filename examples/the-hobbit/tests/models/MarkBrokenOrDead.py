"""MarkBrokenOrDead: the second name phrase becomes "broken" or "dead", the third is cleared."""
import _objects as W
from labels import *  # noqa: F403
ROUTINE = 'MarkBrokenOrDead'
INPUTS = []
OUTPUTS = W.out(['A', 'IX', 'DE'], [W.OBJECTS_REGION])
KINDS = ['typical', 'boundary']
def cases(rnd):
    for _ in range(100):
        yield 'typical', W.case(rnd, A=rnd.choice(W.IDS), **W.noise(rnd, 'IX', 'DE'))
    for oid, rec in W.ENTRIES[:12]:
        yield 'boundary', W.case(rnd, False, A=oid, mem={rec + 7: 0x40}, **W.noise(rnd, 'IX'))
        yield 'boundary', W.case(rnd, False, A=oid, mem={rec + 7: 0x00}, **W.noise(rnd, 'IX'))


def port(regs):
    return W.run('MarkBrokenOrDead', regs, OUTPUTS)
