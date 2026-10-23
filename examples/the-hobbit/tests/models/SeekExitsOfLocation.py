"""SeekExitsOfLocation: IX = location record + EXITS_BIAS, BC = EXIT_SIZE."""
import _objects as W
from labels import *  # noqa: F403
ROUTINE = 'SeekExitsOfLocation'
INPUTS = []
OUTPUTS = W.out(['A', 'IX', 'BC'], [])
KINDS = ['typical', 'boundary']
def cases(rnd):
    for _ in range(100):
        yield 'typical', W.case(rnd, False, A=rnd.randrange(LOCATION_COUNT), **W.noise(rnd, 'IX', 'BC'))
    for a in (0, LOCATION_COUNT - 1, LOCATION_COUNT, 0xFF):
        yield 'boundary', W.case(rnd, False, A=a, **W.noise(rnd, 'IX', 'BC'))


def port(regs):
    return W.run('SeekExitsOfLocation', regs, OUTPUTS)
