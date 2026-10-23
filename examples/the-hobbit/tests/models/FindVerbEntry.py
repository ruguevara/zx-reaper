"""FindVerbEntry: a verb id in the verb table that follows an object record."""
import _objects as W
from labels import *  # noqa: F403
ROUTINE = 'FindVerbEntry'
INPUTS = []
OUTPUTS = W.out(['A', 'IX', 'DE', 'ZF', 'CF', 'SF'], [])
KINDS = ['typical', 'boundary']
def verbs(rec):
    a = rec + 0x10 + W.b(rec)
    out = []
    while W.b(a) != 0xFF:
        out.append(W.b(a))
        a += 3
    return out


def cases(rnd):
    for _ in range(150):
        oid, rec = rnd.choice(W.ENTRIES)
        known = verbs(rec)
        a = rnd.choice(known) if known and rnd.random() < 0.7 else rnd.randrange(0x40)
        yield 'typical', W.case(rnd, False, A=a, IX=rec, **W.noise(rnd, 'DE'))
    for oid, rec in W.ENTRIES[:20]:
        yield 'boundary', W.case(rnd, False, A=0xFF, IX=rec, **W.noise(rnd, 'DE'))
        yield 'boundary', W.case(rnd, False, A=0, IX=rec, **W.noise(rnd, 'DE'))


def port(regs):
    return W.run('FindVerbEntry', regs, OUTPUTS)
