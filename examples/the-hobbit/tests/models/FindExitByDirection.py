"""FindExitByDirection: the exit of the actor location in a direction (destination not 0)."""
import _objects as W
from labels import *  # noqa: F403
ROUTINE = 'FindExitByDirection'
INPUTS = []
OUTPUTS = W.out(['A', 'IX', 'BC', 'IY', 'ZF'], [])
KINDS = ['typical', 'boundary']
def cases(rnd):
    for _ in range(200):
        oid, rec = W.rec_pick(rnd)
        loc = rnd.randrange(LOCATION_COUNT)
        ex = W.exits(loc)
        direction = rnd.choice([e[1] for e in ex] + [rnd.randrange(1, 11)]) if ex else 3; obstacle = 0
        yield 'typical', W.case(rnd, False, A=direction, mem={ActorRecord: W.lo_hi(rec), rec + 0x10: loc, FirstObject: obstacle}, **W.noise(rnd, 'BC', 'IY'))
    for want in (0, 0xFF, 1, 0x50):
        oid, rec = W.rec_pick(rnd)
        obstacle, dest, direction = want, want, want
        yield 'boundary', W.case(rnd, False, A=direction, mem={ActorRecord: W.lo_hi(rec), rec + 0x10: 1, FirstObject: want}, **W.noise(rnd, 'BC', 'IY'))


def port(regs):
    return W.run('FindExitByDirection', regs, OUTPUTS)
