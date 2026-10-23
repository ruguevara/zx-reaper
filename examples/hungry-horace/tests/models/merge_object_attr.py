"""MergeObjectAttr merges the attribute at HL' into E' (guard beats bell beats flower; others change nothing)."""
ROUTINE = 'MergeObjectAttr'
INPUTS = ['E', 'HL']
OUTPUTS = {'regs': ['E']}
KINDS = ['guard', 'bell', 'flower', 'other']
ADDR = 0xE000


def cases(rnd):
    objs = [const('ATTR_GUARD'), const('ATTR_BELL'), const('ATTR_FLOWER')]
    for e in [0] + objs:
        for a in objs:
            yield {const('ATTR_GUARD'): 'guard', const('ATTR_BELL'): 'bell',
                   const('ATTR_FLOWER'): 'flower'}[a], {'E': e, 'HL': ADDR, 'mem': {ADDR: a}}
    for e in [0] + objs:
        for a in [0, 0x38, 0x39, 0x3D, 0x3E, 0x3F, 0x47] + [rnd.randrange(256) for _ in range(10)]:
            if a not in objs:
                yield 'other', {'E': e, 'HL': ADDR, 'mem': {ADDR: a}}


def port(regs):
    import library
    return {'E': library.MergeObjectAttr(regs['E'], regs['HL'])}
