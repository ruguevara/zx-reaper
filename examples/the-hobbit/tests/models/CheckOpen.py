"""CheckOpen: A = REASON_CLOSED, Z set when the object in IX is closed (flag bit 5 clear)."""
import _regs
ROUTINE = 'CheckOpen'
INPUTS = ['IX', 'flags of the object']
OUTPUTS = {'regs': ['A', 'ZF', 'PF', 'SF'], 'mem': []}
KINDS = ['typical', 'boundary']


def cases(rnd):
    for name in ['Obj02SmallCuriousKey', 'Obj13Barrel', 'Obj26Lunch', 'Obj10ValuableGoldenRing']:
        rec = sym(name)
        for flags in [rnd.randrange(256) for _ in range(10)] + [0x00, 0x20, 0xDF, 0xFF]:
            kind = 'boundary' if flags in (0x00, 0x20, 0xDF, 0xFF) else 'typical'
            yield kind, {'IX': rec, 'mem': {rec + 7: flags}}


def port(regs):
    import handlers
    return _regs.run(handlers.CheckOpen, regs, OUTPUTS['regs'])
