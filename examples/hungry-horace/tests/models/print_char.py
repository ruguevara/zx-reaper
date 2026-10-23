"""PrintChar draws ROM-font character A at DE (black on white) when GameActive bit 0 is set."""
ROUTINE = 'PrintChar'
INPUTS = ['A', 'DE', '^HL', 'GameActive (memory)']
OUTPUTS = {'regs': ['DE', '^HL'], 'mem': [('SCREEN', const('SCREEN_SIZE') + const('ATTRS_SIZE'))]}
KINDS = ['typical', 'third-end', 'printing-off']


def attr_of(de):
    return ((de >> 8 & const('THIRD_BITS')) >> 3) + (sym('ATTRS') >> 8) << 8 | de & 255


def case(rnd, kind, de, active, a=None):
    scr = bytes(rnd.randrange(256) for _ in range(const('SCREEN_SIZE') + const('ATTRS_SIZE')))
    return kind, {'A': rnd.randrange(0x20, 0x80) if a is None else a, 'DE': de, '^HL': attr_of(de),
                  'mem': {sym('SCREEN'): scr, sym('GameActive'): active}}


def cases(rnd):
    scr = sym('SCREEN')
    for _ in range(150):
        yield case(rnd, 'typical', scr + (rnd.randrange(3) << 11) + (rnd.randrange(8) << 5) + rnd.randrange(32), 1)
    for third in range(3):
        yield case(rnd, 'third-end', scr + (third << 11) + 0xFF, 1)
    for active in (0, 2, 0xFE):
        for _ in range(8):
            yield case(rnd, 'printing-off', scr + (rnd.randrange(3) << 11) + rnd.randrange(256), active)
    yield case(rnd, 'typical', scr + 0x100, 1, 0x20)
    yield case(rnd, 'typical', scr + 0x100, 1, 0x7F)


def port(regs):
    import library
    de, attr = library.PrintChar(regs['A'], regs['DE'], regs['^HL'])
    return {'DE': de, '^HL': attr}
