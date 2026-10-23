"""DrawCell copies 8 bytes from DE to the cell at HL, stores C at the attribute address HL', and moves on."""
ROUTINE = 'DrawCell'
INPUTS = ['C', 'DE', 'HL', '^HL']
OUTPUTS = {'regs': ['DE', 'HL', '^HL'], 'mem': [('SCREEN', const('SCREEN_SIZE') + const('ATTRS_SIZE'))]}
KINDS = ['typical', 'row-end', 'third-end']
GFX = 0xE000


def attr_of(hl):
    return ((hl >> 8 & const('THIRD_BITS')) >> 3) + (sym('ATTRS') >> 8) << 8 | hl & 255


def case(rnd, kind, hl):
    scr = bytes(rnd.randrange(256) for _ in range(const('SCREEN_SIZE') + const('ATTRS_SIZE')))
    return kind, {'C': rnd.randrange(256), 'DE': GFX, 'HL': hl, '^HL': attr_of(hl),
                  'mem': {sym('SCREEN'): scr, GFX: bytes(rnd.randrange(256) for _ in range(8))}}


def cases(rnd):
    scr = sym('SCREEN')
    for _ in range(200):
        yield case(rnd, 'typical', scr + (rnd.randrange(3) << 11) + (rnd.randrange(8) << 5) + rnd.randrange(32))
    for third in range(3):
        for row in range(8):
            yield case(rnd, 'row-end', scr + (third << 11) + (row << 5) + 31)
        yield case(rnd, 'third-end', scr + (third << 11) + 0xFF)


def port(regs):
    import library
    de, hl, attr = library.DrawCell(regs['C'], regs['DE'], regs['HL'], regs['^HL'])
    return {'DE': de, 'HL': hl, '^HL': attr}
