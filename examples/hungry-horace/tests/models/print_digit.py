"""PrintDigit divides HL by the power of ten BC, prints the digit at DE (A = "0", carry clear)."""
ROUTINE = 'PrintDigit'
INPUTS = ['A', 'BC', 'DE', 'HL', '^HL', 'GameActive (memory)']
OUTPUTS = {'regs': ['DE', 'HL', '^HL'], 'mem': [('SCREEN', const('SCREEN_SIZE') + const('ATTRS_SIZE'))]}
KINDS = ['typical', 'boundary', 'printing-off', 'third-wrap']
A0 = const('CHAR_0')


def screen(rnd, active):
    return {sym('SCREEN'): bytes(rnd.randrange(256) for _ in range(const('SCREEN_SIZE') + const('ATTRS_SIZE'))),
            sym('GameActive'): active}


def attr_of(de):
    return ((de >> 8 & const('THIRD_BITS')) >> 3) + (sym('ATTRS') >> 8) << 8 | de & 255


def case(rnd, kind, de, hl, bc, active=1):
    return kind, {'A': A0, 'BC': bc, 'DE': de, 'HL': hl, '^HL': attr_of(de), 'mem': screen(rnd, active)}


def cases(rnd):
    scr = sym('SCREEN')
    for _ in range(150):
        bc = rnd.choice((10000, 1000, 100, 10))
        third, row, col = rnd.randrange(3), rnd.randrange(8), rnd.randrange(32)
        yield case(rnd, 'typical', scr + (third << 11) + (row << 5) + col, rnd.randrange(min(10 * bc, 65536)), bc)
    for bc in (10000, 1000, 100, 10):
        for hl in {h for h in (0, bc - 1, bc, 9 * bc, 10 * bc - 1, 65535) if h < min(10 * bc, 65536)}:
            yield case(rnd, 'boundary', scr + 0x40, hl, bc)
    for _ in range(20):
        bc = rnd.choice((10000, 1000, 100, 10))
        yield case(rnd, 'printing-off', scr + 0x40, rnd.randrange(min(10 * bc, 65536)), bc, 0)
        yield case(rnd, 'printing-off', scr + 0x40, rnd.randrange(min(10 * bc, 65536)), bc, 0x80)   # only bit 0 counts
    for third in range(3):
        yield case(rnd, 'third-wrap', scr + (third << 11) + 0xFF, rnd.randrange(50000), 10000)


def port(regs):
    import library
    de, hl, attr = library.PrintDigit(regs['BC'], regs['DE'], regs['HL'], regs['^HL'])
    return {'DE': de, 'HL': hl, '^HL': attr}
