"""SeekActorExits: IX = the location record of the actor + EXITS_BIAS."""
import _objects as W
from labels import *  # noqa: F403
ROUTINE = 'SeekActorExits'
INPUTS = []
OUTPUTS = W.out(['IX', 'DE', 'A'], [])
KINDS = ['typical', 'boundary']
def cases(rnd):
    for _ in range(100):
        oid, rec = W.rec_pick(rnd)
        yield 'typical', W.case(rnd, False, mem={ActorRecord: W.lo_hi(rec), rec + 0x10: rnd.randrange(LOCATION_COUNT)}, **W.noise(rnd, 'DE', 'A', 'IX'))
    for loc in (0, LOCATION_COUNT - 1, LOCATION_COUNT, 0xFF):
        oid, rec = W.rec_pick(rnd)
        yield 'boundary', W.case(rnd, False, mem={ActorRecord: W.lo_hi(rec), rec + 0x10: loc}, **W.noise(rnd, 'DE', 'A', 'IX'))


def port(regs):
    return W.run('SeekActorExits', regs, OUTPUTS)
