"""FindExitByObstacle: the exit of the actor location whose obstacle is the first object; sets the SMC field to 1."""
import _objects as W
from labels import *  # noqa: F403
ROUTINE = 'FindExitByObstacle'
INPUTS = []
OUTPUTS = W.out(['A', 'IX', 'BC', 'IY', 'ZF'], [('SmcExitField', 4)])
KINDS = ['typical', 'boundary']
def cases(rnd):
    for _ in range(200):
        oid, rec = W.rec_pick(rnd)
        loc = rnd.randrange(LOCATION_COUNT)
        ex = [e for e in W.exits(loc) if e[2]]
        obstacle = rnd.choice([e[2] for e in ex] + [rnd.choice(W.IDS)]) if ex else rnd.choice(W.IDS)
        yield 'typical', W.case(rnd, False, mem={ActorRecord: W.lo_hi(rec), rec + 0x10: loc, FirstObject: obstacle}, **W.noise(rnd, 'BC', 'IY', 'A'))
    for obstacle in (0, 0xFF, 1):
        oid, rec = W.rec_pick(rnd)
        yield 'boundary', W.case(rnd, False, mem={ActorRecord: W.lo_hi(rec), rec + 0x10: 1, FirstObject: obstacle}, **W.noise(rnd, 'BC', 'IY', 'A'))


def port(regs):
    return W.run('FindExitByObstacle', regs, OUTPUTS)
