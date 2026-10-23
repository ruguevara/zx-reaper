"""FindExitByName: the next exit of the actor location whose destination a typed noun phrase names."""
import _objects as W
from labels import *  # noqa: F403
ROUTINE = 'FindExitByName'
INPUTS = []
OUTPUTS = W.out(['A', 'IX', 'IY', 'DE', 'HL', 'ZF', 'CF', 'SF'], [('PhraseMatched', 1)])
KINDS = ['typical', 'boundary']


def make(rnd, loc=None, named=None):
    oid, rec = W.rec_pick(rnd)
    loc = rnd.randrange(LOCATION_COUNT) if loc is None else loc
    ex = W.exits(loc)
    if named is None:
        named = rnd.choice([e[3] for e in ex] + [rnd.randrange(LOCATION_COUNT)]) if ex else 3
    phrase = W.w(LocationTable + 2 * named % (2 * LOCATION_COUNT)) + 2
    first = W.w(LocationTable + 2 * loc) + EXITS_BIAS
    return W.case(rnd, False, HL=phrase, IX=first, mem={ActorRecord: W.lo_hi(rec), rec + 0x10: loc},
                  **W.noise(rnd, 'DE', 'IY'))


def cases(rnd):
    for _ in range(200):
        yield 'typical', make(rnd)
    for loc in (0, 1, 5, LOCATION_COUNT - 1):
        yield 'boundary', make(rnd, loc=loc, named=0x40)
        yield 'boundary', make(rnd, loc=loc, named=0)


def port(regs):
    return W.run('FindExitByName', regs, OUTPUTS)
