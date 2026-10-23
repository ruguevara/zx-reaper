"""EraseGuard erases the guard of the working buffer from its old position if its new position differs."""
from _sprites import pos, record, screen
ROUTINE = 'EraseGuard'
INPUTS = ['GuardRecord (memory)', 'screen (memory)']
OUTPUTS = {'regs': [], 'mem': [('SCREEN', const('SCREEN_SIZE') + const('ATTRS_SIZE')),
                               ('GuardRecord', const('GUARD_RECORD_SIZE'))]}
KINDS = ['moved', 'not-moved', 'adjacent']


def case(rnd, old, new):
    m = screen(rnd, sym, const)
    m[sym('GuardRecord')] = record(rnd, old, new)
    return {'mem': m}


def cases(rnd):
    for _ in range(100):
        yield 'moved', case(rnd, pos(rnd), pos(rnd))
    for _ in range(30):
        p = pos(rnd)
        yield 'not-moved', case(rnd, p, p)
    for _ in range(30):     # the new image overlaps the old one
        p = (4 << 5) + rnd.randrange(1, 29)
        yield 'adjacent', case(rnd, p, p + rnd.choice((-33, -32, -31, -1, 1, 31, 32, 33)))


def port(regs):
    import sprites
    sprites.EraseGuard()
    return {}
