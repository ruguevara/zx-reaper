"""CheckEnclosed: follows an object's holders while their open/alive bit is set; Z at a location, else NZ with A = holder OR 1; IX kept."""
import _regs
import _verbs

ROUTINE = 'CheckEnclosed'
INPUTS = ['A', 'IX']
OUTPUTS = {'regs': ['A', 'IX', 'ZF']}
KINDS = ['typical', 'boundary']


def cases(rnd):
    objs = _verbs.objects()
    for oid, rec in objs:
        held = _verbs.byte(rec + 1) != 0xFF
        yield ('boundary' if held else 'typical'), {'A': oid, 'IX': 0x1234}
    # a holder with its open bit cleared: the holder chain stops there
    for oid, rec in objs:
        holder = _verbs.byte(rec + 1)
        if holder != 0xFF:
            hrec = dict(objs)[holder]
            yield 'boundary', {'A': oid, 'IX': 0x4321, 'mem': {hrec + 7: _verbs.byte(hrec + 7) & ~0x20}}


def port(regs):
    import verbs
    return _regs.run(verbs.CheckEnclosed, regs, OUTPUTS['regs'])
