"""Autopilot weighs the four directions with ProbeMove and random bytes and sets HoraceDir to the heaviest."""
import _ai
ROUTINE = 'Autopilot'
INPUTS = ['HoracePos', 'HoraceDir', 'RandomPtr', 'attributes around Horace']
OUTPUTS = {'regs': [], 'mem': [('GuardDirScores', 4), ('HoraceDir', 1), ('RandomPtr', 2)]}
KINDS = ['open', 'walls', 'blocked-all', 'pads', 'arrows']


def make(rnd, kind, pool):
    p = _ai.rand_pos(rnd)
    mem = _ai.around(rnd, sym('ATTRS'), p, pool)
    mem.update({'HoracePos': _ai.w(p), 'HoraceDir': rnd.randrange(4),
                'RandomPtr': _ai.w(rnd.randrange(0x2000))})
    return kind, {'mem': mem}


def cases(rnd):
    blank, wall, pad, arrow = (const(n) for n in ('ATTR_BLANK', 'ATTR_WALL', 'ATTR_PAD', 'ATTR_ARROW'))
    for _ in range(100):
        yield make(rnd, 'open', [blank])
        yield make(rnd, 'walls', [blank, blank, blank, wall])
        yield make(rnd, 'pads', [blank, blank, pad])
        yield make(rnd, 'arrows', [blank, blank, arrow])
    for _ in range(20):
        yield make(rnd, 'blocked-all', [wall])


def port(regs):
    import movement
    movement.Autopilot()
    return {}
