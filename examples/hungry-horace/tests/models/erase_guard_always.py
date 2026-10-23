"""EraseGuard_Always draws the four saved background cells at the guard's old position and saves the background under the new one."""
from _sprites import pos, record, screen
ROUTINE = 'EraseGuard_Always'
INPUTS = ['GuardRecord (memory)', 'screen (memory)']
OUTPUTS = {'regs': [], 'mem': [('SCREEN', const('SCREEN_SIZE') + const('ATTRS_SIZE')),
                               ('GuardRecord', const('GUARD_RECORD_SIZE'))]}
KINDS = ['typical', 'last-row', 'last-col', 'same-pos']


def case(rnd, old, new):
    m = screen(rnd, sym, const)
    m[sym('GuardRecord')] = record(rnd, old, new)
    return m


def cases(rnd):
    for _ in range(150):
        yield 'typical', {'mem': case(rnd, pos(rnd), pos(rnd))}
    for third in range(3):
        for col in (0, 15, 30):    # the bottom cells are in the next third
            row = 7 if third < 2 else 6
            yield 'last-row', {'mem': case(rnd, (third << 11) + (row << 5) + col, pos(rnd))}
        yield 'last-col', {'mem': case(rnd, (third << 11) + (3 << 5) + 30, (third << 11) + (4 << 5) + 30)}
    for _ in range(10):
        p = pos(rnd)
        yield 'same-pos', {'mem': case(rnd, p, p)}


def port(regs):
    import sprites
    sprites.EraseGuard_Always()
    return {}
