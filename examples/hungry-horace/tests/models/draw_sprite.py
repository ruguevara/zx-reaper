"""DrawSprite draws a 2x2-cell graphic (32 bytes at DE) with attribute C at screen offset HL (HL' = its attribute address)."""
ROUTINE = 'DrawSprite'
INPUTS = ['C', 'DE', 'HL', '^HL']
OUTPUTS = {'regs': [], 'mem': [('SCREEN', const('SCREEN_SIZE') + const('ATTRS_SIZE'))]}
KINDS = ['typical', 'last-row', 'last-col', 'third-end']
GFX = 0xE000


def attr_of(hl):
    return ((hl >> 8 & const('THIRD_BITS')) >> 3) + (sym('ATTRS') >> 8) << 8 | hl & 255


def case(rnd, kind, third, row, col):
    hl = (third << 11) + (row << 5) + col       # offset from the start of the screen
    scr = bytes(rnd.randrange(256) for _ in range(const('SCREEN_SIZE') + const('ATTRS_SIZE')))
    return kind, {'C': rnd.randrange(256), 'DE': GFX, 'HL': hl, '^HL': attr_of(hl),
                  'mem': {sym('SCREEN'): scr, GFX: bytes(rnd.randrange(256) for _ in range(32))}}


def cases(rnd):
    for _ in range(200):
        yield case(rnd, 'typical', rnd.randrange(3), rnd.randrange(8), rnd.randrange(31))
    for third in range(3):
        for col in (0, 15, 30):
            yield case(rnd, 'last-row', third, 7, col)       # bottom cells in the next third
        yield case(rnd, 'last-col', third, rnd.randrange(8), 31)   # right cells wrap
        yield case(rnd, 'third-end', third, 7, 31)


def port(regs):
    import library
    library.DrawSprite(regs['C'], regs['DE'], regs['HL'], regs['^HL'])
    return {}
