"""The stage 4 routine that stands for each stage 3 routine, for
`python bridge/oracle.py routine NAME RECORD...`.

ROUTINES[name] = (clean, convert): the oracle calls clean(state, actions,
*convert(*stage3_args)) on a copy of the state before each call of the stage 3
routine and compares the state after, the return value (a Goto becomes the
target's name) and the sounds. A stage 4 routine that yields events is a
generator; its return value is what is compared."""
import inspect

import paths  # noqa: F401
from decode import pos


def drive(x, events):
    """Run a generator to the end, collecting what it yields; return its value."""
    if not inspect.isgenerator(x):
        return x
    while True:
        try:
            events.append(next(x))
        except StopIteration as stop:
            return stop.value


def none():
    return ()


def offset(o):
    return (pos(o),)


ROUTINES = {}       # filled below and by bridge/routines_*.py (one file per stage 4 module)


from horace import world  # noqa: E402
from zxpyxel import zx  # noqa: E402

ROUTINES.update({
    'GetBlockObject': (lambda s, a, p: world.block_object(s, p), offset),
    'ProbeMove': (lambda s, a, d, p: world.probe_move(s, p, d), lambda d, hl: (d, pos(hl))),
    'GetRandom': (lambda s, a: world.get_random(s), none),
    'DrawSprite': (lambda s, a, c, g, p: world.draw_sprite(s, p, g, c),
                   lambda c, de, hl, attr: (c, bytes(zx.mem[de:de + 32]), pos(hl))),
})


import glob as _glob  # noqa: E402
import importlib as _importlib  # noqa: E402
import os as _os  # noqa: E402

for _f in sorted(_glob.glob(_os.path.join(_os.path.dirname(_os.path.abspath(__file__)), 'routines_*.py'))):
    ROUTINES.update(_importlib.import_module(_os.path.basename(_f)[:-3]).ROUTINES)
