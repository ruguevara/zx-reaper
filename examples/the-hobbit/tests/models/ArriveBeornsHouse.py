"""ArriveBeornsHouse wakes the butler (NpcButler := $42, flag bit 7) unless he is dead (flag bit 3)."""
import _regs
ROUTINE = 'ArriveBeornsHouse'
INPUTS = ['Chr42ButlerFlags', 'NpcButler']
OUTPUTS = {'regs': ['A', 'HL', 'ZF'], 'mem': [('Chr42ButlerFlags', 1), ('NpcButler', 1)]}
KINDS = ['typical', 'boundary']


def cases(rnd):
    for flags in [rnd.randrange(256) for _ in range(20)] + [0x00, 0x08, 0x80, 0x88, 0xF7, 0xFF]:
        kind = 'boundary' if flags in (0x00, 0x08, 0x80, 0x88, 0xF7, 0xFF) else 'typical'
        yield kind, {'A': rnd.randrange(256), 'mem': {'Chr42ButlerFlags': flags, 'NpcButler': rnd.randrange(256)}}


def port(regs):
    import world
    return _regs.run(world.ArriveBeornsHouse, regs, OUTPUTS['regs'])
