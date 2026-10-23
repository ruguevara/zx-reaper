"""FindNextNamedObject: the next object a typed noun phrase can mean (kind by AllMode, name match, reach)."""
import _objects as W
from labels import *  # noqa: F403
ROUTINE = 'FindNextNamedObject'
INPUTS = []
OUTPUTS = W.out(['A', 'IX', 'BC', 'DE', 'IY', 'ZF', 'CF', 'SF'], [('PhraseMatched', 1)])
KINDS = ['typical', 'boundary']


def make(rnd, start=None, **mem):
    oid, rec = W.rec_pick(rnd)
    actor = W.rec_pick(rnd)
    m = {ActorRecord: W.lo_hi(actor[1]), AllMode: rnd.choice([0, 1, ALL_MODE_ANY]),
         AllActive: rnd.choice([0, 0, 1])}
    m.update(mem)
    ix = ObjectTable - 3 if start is None else start
    return W.case(rnd, HL=rec + REC_PHRASE_A, IX=ix, mem=m, **W.noise(rnd, 'BC', 'DE', 'IY'))


def cases(rnd):
    for _ in range(300):
        yield 'typical', make(rnd, start=ObjectTable - 3 + 3 * rnd.randrange(len(W.ENTRIES)))
    for _ in range(100):                           # the table from the start, every mode
        yield 'boundary', make(rnd)
    for mode in (0, 1, ALL_MODE_ANY):
        yield 'boundary', make(rnd, AllMode=mode, start=W.END_ENTRY - 3)
        yield 'boundary', make(rnd, AllMode=mode, AllActive=1, start=W.END_ENTRY)


def port(regs):
    return W.run('FindNextNamedObject', regs, OUTPUTS)
