"""SaveBackgroundCell copies a cell (attribute at HL', 8 bitmap rows at HL) to the 9-byte slot at DE; a guard cell is stored blank."""
ROUTINE = 'SaveBackgroundCell'
INPUTS = ['DE', 'HL', '^HL']
OUTPUTS = {'regs': ['DE', 'HL', '^HL'], 'mem': [('SavedBackground', 9)]}
KINDS = ['typical', 'guard', 'row-end', 'third-end', 'guard-third-end']
SLOT = 'SavedBackground'


def attr_of(hl):
    return ((hl >> 8 & const('THIRD_BITS')) >> 3) + (sym('ATTRS') >> 8) << 8 | hl & 255


def case(rnd, kind, hl, guard):
    scr = bytes(rnd.randrange(256) for _ in range(const('SCREEN_SIZE') + const('ATTRS_SIZE')))
    mem = {sym('SCREEN'): scr, sym(SLOT): bytes(rnd.randrange(256) for _ in range(9))}
    if guard:
        mem[attr_of(hl)] = const('ATTR_GUARD')
    return kind, {'DE': sym(SLOT), 'HL': hl, '^HL': attr_of(hl), 'mem': mem}


def cases(rnd):
    scr = sym('SCREEN')
    for _ in range(150):
        hl = scr + (rnd.randrange(3) << 11) + (rnd.randrange(8) << 5) + rnd.randrange(32)
        yield case(rnd, 'typical', hl, False)
        yield case(rnd, 'guard', hl, True)
    for third in range(3):
        yield case(rnd, 'row-end', scr + (third << 11) + 31, False)
        yield case(rnd, 'third-end', scr + (third << 11) + 0xFF, False)
        yield case(rnd, 'guard-third-end', scr + (third << 11) + 0xFF, True)


def port(regs):
    import library
    de, hl, attr = library.SaveBackgroundCell(regs['DE'], regs['HL'], regs['^HL'])
    return {'DE': de, 'HL': hl, '^HL': attr}
