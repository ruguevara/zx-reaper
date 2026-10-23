"""FindExitByDestination: the exit of the actor location that leads to a place; sets the SMC field to 2."""
import _objects as W
from labels import *  # noqa: F403
ROUTINE = 'FindExitByDestination'
INPUTS = []
OUTPUTS = W.out(['A', 'IX', 'BC', 'IY', 'ZF'], [('SmcExitField', 4)])
KINDS = ['typical', 'boundary']
def cases(rnd):
    for _ in range(200):
        oid, rec = W.rec_pick(rnd)
        loc = rnd.randrange(LOCATION_COUNT)
        ex = W.exits(loc)
        dest = rnd.choice([e[3] for e in ex] + [rnd.randrange(LOCATION_COUNT)]) if ex else 3; obstacle = 0
        yield 'typical', W.case(rnd, False, A=dest, mem={ActorRecord: W.lo_hi(rec), rec + 0x10: loc, FirstObject: obstacle}, **W.noise(rnd, 'BC', 'IY'))
    for want in (0, 0xFF, 1, 0x50):
        oid, rec = W.rec_pick(rnd)
        obstacle, dest, direction = want, want, want
        yield 'boundary', W.case(rnd, False, A=dest, mem={ActorRecord: W.lo_hi(rec), rec + 0x10: 1, FirstObject: want}, **W.noise(rnd, 'BC', 'IY'))


def port(regs):
    return W.run('FindExitByDestination', regs, OUTPUTS)
