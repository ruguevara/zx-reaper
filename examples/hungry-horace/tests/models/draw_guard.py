"""DrawGuard draws the working-buffer guard at its new position (frame by bell timer, animation counter, direction); a just-eaten guard waits first."""
from _sprites import pos, record, screen, word
ROUTINE = 'DrawGuard'
INPUTS = ['GuardRecord (memory)', 'BellTimer', 'screen (memory)']
OUTPUTS = {'regs': [], 'mem': [('SCREEN', const('SCREEN_SIZE') + const('ATTRS_SIZE')),
                               ('BellTimer', 2), ('GuardRecord', const('GUARD_RECORD_SIZE'))]}
KINDS = ['walking', 'scared', 'waiting', 'wait-ends', 'anim-wrap']


def case(rnd, wait=0, bell=0, anim=None, direction=None):
    m = screen(rnd, sym, const)
    rec = bytearray(record(rnd, pos(rnd), pos(rnd), wait, direction))
    if anim is not None:
        rec[3] = anim
    m[sym('GuardRecord')] = bytes(rec)
    m[sym('BellTimer')] = word(bell)
    return {'mem': m}


def cases(rnd):
    for _ in range(80):
        yield 'walking', case(rnd)
    for _ in range(80):
        yield 'scared', case(rnd, bell=rnd.choice((1, 2, 300, 0x100)))
    for _ in range(20):
        yield 'waiting', case(rnd, wait=rnd.randrange(2, 20), bell=rnd.choice((0, 5)))
    for _ in range(20):
        yield 'wait-ends', case(rnd, wait=1, bell=rnd.choice((0, 5)))
    for anim in (0x1F, 0x20, 0x3F, 0x7, 0xFF, 0xDF):    # the counter crosses bits 3 and 5, wraps
        for d in range(4):
            yield 'anim-wrap', case(rnd, anim=anim, direction=d, bell=rnd.choice((0, 7)))


def port(regs):
    import sprites
    sprites.DrawGuard()
    return {}
