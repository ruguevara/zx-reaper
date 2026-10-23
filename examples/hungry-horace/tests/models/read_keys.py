"""ReadKeys with no key pressed leaves HoraceDir and RequestedDir (DIR_NONE after ReadControls) alone. Key paths are left to the whole-game check."""
import _ai
ROUTINE = 'ReadKeys'
INPUTS = ['RequestedDir', 'HoraceDir']
OUTPUTS = {'regs': [], 'mem': [('RequestedDir', 1), ('HoraceDir', 1)]}
KINDS = ['no-key']


def cases(rnd):
    for _ in range(40):
        yield 'no-key', {'mem': {'RequestedDir': const('DIR_NONE'), 'HoraceDir': rnd.randrange(4),
                                 'HoracePos': _ai.w(_ai.rand_pos(rnd))}}


def port(regs):
    import movement
    movement.ReadKeys()
    return {}
