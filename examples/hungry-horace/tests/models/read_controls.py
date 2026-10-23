"""ReadControls: frozen after a wrap, or no key in a game (ReadKeys) or in the demo (Autopilot). Key paths are left to the whole-game check."""
import _ai
ROUTINE = 'ReadControls'
INPUTS = ['WrapPause', 'GameActive', 'HoracePos', 'HoraceDir', 'RequestedDir', 'RandomPtr', 'attributes']
OUTPUTS = {'regs': [], 'mem': [('RequestedDir', 1), ('HoraceDir', 1), ('GuardDirScores', 4), ('RandomPtr', 2)]}
KINDS = ['frozen', 'game-no-key', 'demo']


def cases(rnd):
    blank, wall = const('ATTR_BLANK'), const('ATTR_WALL')
    for kind, wrap, active in (('frozen', 1, 0), ('frozen', 90, 1), ('game-no-key', 0, 1), ('demo', 0, 0)):
        for _ in range(60):
            p = _ai.rand_pos(rnd)
            mem = _ai.around(rnd, sym('ATTRS'), p, [blank, blank, wall])
            mem.update({'WrapPause': wrap, 'GameActive': active, 'HoracePos': _ai.w(p),
                        'HoraceDir': rnd.randrange(4), 'RequestedDir': rnd.randrange(256),
                        'RandomPtr': _ai.w(rnd.randrange(0x2000))})
            yield kind, {'mem': mem}


def port(regs):
    import movement
    movement.ReadControls()
    return {}
