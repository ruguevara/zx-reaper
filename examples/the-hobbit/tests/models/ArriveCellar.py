"""ArriveCellar starts timer 9 at 3 and wakes the dragon slot and the Bard unless their flag bit 3 (dead) is set."""
import _regs
ROUTINE = 'ArriveCellar'
INPUTS = ['Chr3CDragonFlags', 'Chr46BardFlags', 'NpcDragon', 'NpcBard', 'Timer9Counter']
OUTPUTS = {'regs': ['A', 'HL', 'ZF'], 'mem': [('Timer9Counter', 1), ('NpcDragon', 1), ('NpcBard', 1)]}
KINDS = ['typical', 'boundary']


def cases(rnd):
    for d, b in [(rnd.randrange(256), rnd.randrange(256)) for _ in range(20)] + \
            [(0, 0), (8, 0), (0, 8), (8, 8), (0xF7, 0xF7), (0xFF, 0xFF)]:
        kind = 'boundary' if d in (0, 8, 0xF7, 0xFF) and b in (0, 8, 0xF7, 0xFF) else 'typical'
        yield kind, {'mem': {'Chr3CDragonFlags': d, 'Chr46BardFlags': b, 'NpcDragon': rnd.randrange(256),
                             'NpcBard': rnd.randrange(256), 'Timer9Counter': rnd.randrange(256)}}


def port(regs):
    import world
    return _regs.run(world.ArriveCellar, regs, OUTPUTS['regs'])
