"""FindExitByObstacle_0: FindExitByObstacle for the object in A."""
import _objects as W
from labels import *  # noqa: F403
ROUTINE = 'FindExitByObstacle_0'
INPUTS = []
OUTPUTS = W.out(['A', 'IX', 'BC', 'IY', 'ZF'], [('SmcExitField', 4)])
KINDS = ['typical', 'boundary']
def cases(rnd):
    for _ in range(100):
        oid, rec = W.rec_pick(rnd)
        loc = rnd.randrange(LOCATION_COUNT)
        ex = [e for e in W.exits(loc) if e[2]]
        obstacle = rnd.choice([e[2] for e in ex] + [rnd.choice(W.IDS)]) if ex else rnd.choice(W.IDS)
        yield 'typical', W.case(rnd, False, A=obstacle, mem={ActorRecord: W.lo_hi(rec), rec + 0x10: loc}, **W.noise(rnd, 'BC', 'IY'))
    for obstacle in (0, 0xFF):
        oid, rec = W.rec_pick(rnd)
        yield 'boundary', W.case(rnd, False, A=obstacle, mem={ActorRecord: W.lo_hi(rec), rec + 0x10: 1}, **W.noise(rnd, 'BC', 'IY'))


def port(regs):
    return W.run('FindExitByObstacle_0', regs, OUTPUTS)
