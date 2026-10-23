"""NextListedExit: step IX by BC to the next exit with no obstacle and a direction."""
import _objects as W
from labels import *  # noqa: F403
ROUTINE = 'NextListedExit'
INPUTS = []
OUTPUTS = W.out(['A', 'IX', 'BC', 'ZF', 'CF'], [])
KINDS = ['typical', 'boundary']
def cases(rnd):
    for _ in range(200):
        loc = rnd.randrange(LOCATION_COUNT)
        rec = W.w(LocationTable + 2 * loc)
        start = rec + EXITS_BIAS
        ex = W.exits(loc)
        if ex:
            start = rnd.choice(ex)[0] - 3
        m = {}
        for e in ex:                               # erase some exits, put obstacles on others
            if rnd.random() < 0.3:
                m[e[0]] = 0
            if rnd.random() < 0.3:
                m[e[0] + 1] = rnd.choice(W.IDS)
        yield 'typical', W.case(rnd, False, IX=start, BC=EXIT_SIZE, mem=m, **W.noise(rnd, 'A'))
    for loc in (0, 1, 5):
        ex = W.exits(loc)
        yield 'boundary', W.case(rnd, False, IX=ex[-1][0] if ex else W.w(LocationTable + 2 * loc) + EXITS_BIAS, BC=EXIT_SIZE)


def port(regs):
    return W.run('NextListedExit', regs, OUTPUTS)
