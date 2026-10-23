"""GetActorLocationRec: IX = the location record of the current actor; AF kept."""
import _objects as W
from labels import *  # noqa: F403
ROUTINE = 'GetActorLocationRec'
INPUTS = []
OUTPUTS = W.out(['A', 'IX', 'ZF', 'CF', 'SF', 'PF'], [])
KINDS = ['typical', 'boundary']
def cases(rnd):
    for _ in range(150):
        oid, rec = W.rec_pick(rnd)
        yield 'typical', W.case(rnd, False, A=rnd.randrange(256), F=rnd.randrange(256), mem={ActorRecord: W.lo_hi(rec), rec + 0x10: rnd.randrange(LOCATION_COUNT)}, **W.noise(rnd, 'IX'))
    for loc in (0, LOCATION_COUNT - 1, LOCATION_COUNT, 0xFF):
        oid, rec = W.rec_pick(rnd)
        yield 'boundary', W.case(rnd, False, A=0x55, F=0xD5, mem={ActorRecord: W.lo_hi(rec), rec + 0x10: loc}, **W.noise(rnd, 'IX'))


def port(regs):
    return W.run('GetActorLocationRec', regs, OUTPUTS)
