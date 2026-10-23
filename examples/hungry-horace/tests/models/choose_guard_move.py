"""ChooseGuardMove scores the four directions for the working guard, picks one and sets GuardNewPos."""
import _ai
ROUTINE = 'ChooseGuardMove'
INPUTS = ['GuardWait', 'GuardRecord', 'GuardDir', 'HoracePos', 'BellTimer', 'FRAMES', 'MazeDescriptor', 'attributes']
OUTPUTS = {'regs': [], 'mem': [('GuardDirScores', 4), ('GuardDir', 1), ('GuardNewPos', 2), ('HoraceCell', 2),
                               ('GuardCell', 2), ('FRAMES', 2), ('UnusedAiCounter', 1)]}
KINDS = ['chase', 'scared', 'waiting', 'walls', 'pads', 'arrows', 'blocked-all']


def make(rnd, kind, pool, scared=False, wait=0):
    g = _ai.rand_pos(rnd)
    h = _ai.rand_pos(rnd)
    mem = _ai.around(rnd, sym('ATTRS'), g, pool)
    mem.update({'GuardWait': wait, 'GuardRecord': _ai.w(g), 'GuardDir': rnd.randrange(4),
                'HoracePos': _ai.w(h), 'BellTimer': _ai.w(rnd.randrange(1, 500) if scared else 0),
                'FRAMES': _ai.w(rnd.randrange(0x10000)), 'GuardInterval': rnd.randrange(1, 9),
                'UnusedAiCounter': rnd.randrange(256), 'GuardNewPos': [0, 0],
                'MazeDescriptor': _ai.w(rnd.choice([0x0300, 0x0400, 0x0500]))})
    return kind, {'mem': mem}


def cases(rnd):
    blank, wall, pad, arrow = (const(n) for n in ('ATTR_BLANK', 'ATTR_WALL', 'ATTR_PAD', 'ATTR_ARROW'))
    for _ in range(150):
        yield make(rnd, 'chase', [blank])
        yield make(rnd, 'scared', [blank, blank, wall], scared=True)
        yield make(rnd, 'walls', [blank, blank, blank, wall])
        yield make(rnd, 'pads', [blank, blank, pad])
        yield make(rnd, 'arrows', [blank, blank, arrow])
    for _ in range(20):
        yield make(rnd, 'waiting', [blank], wait=rnd.randrange(1, 256))
        yield make(rnd, 'blocked-all', [wall])


def port(regs):
    import movement
    movement.ChooseGuardMove()
    return {}
