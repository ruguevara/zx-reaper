"""CheckOpenable: the reason the first object cannot be opened (locked, already open) or that it can."""
import _regs
ROUTINE = 'CheckOpenable'
INPUTS = ['Noun1Record', 'flags of the object']
OUTPUTS = {'regs': ['A', 'IX', 'ZF', 'PF'], 'mem': []}
KINDS = ['typical', 'boundary']
OBJECTS = ['Obj02SmallCuriousKey', 'Obj0BDoorFlags', 'Obj0DDoorFlags', 'Obj11DoorFlags', 'Obj13Barrel', 'Obj26Lunch']


def cases(rnd):
    for name in OBJECTS:
        rec = sym(name) - (7 if 'Flags' in name else 0)    # the *DoorFlags labels name the flag byte
        for flags in [rnd.randrange(256) for _ in range(12)] + [0x00, 0x01, 0x20, 0x21, 0xFF]:
            kind = 'boundary' if flags in (0x00, 0x01, 0x20, 0x21, 0xFF) else 'typical'
            yield kind, {'mem': {'Noun1Record': [rec & 255, rec >> 8], rec + 7: flags}}


def port(regs):
    import handlers
    return _regs.run(handlers.CheckOpenable, regs, OUTPUTS['regs'])
