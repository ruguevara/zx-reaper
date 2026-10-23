"""PrintNumber prints HL as five decimal digits at DE (bitmap and attributes) when GameActive bit 0 is set."""
ROUTINE = 'PrintNumber'
INPUTS = ['DE', 'HL', 'GameActive (memory)']
OUTPUTS = {'regs': [], 'mem': [('SCREEN', const('SCREEN_SIZE') + const('ATTRS_SIZE'))]}
KINDS = ['typical', 'boundary', 'printing-off', 'third-wrap']


def screen(rnd, active):
    return {sym('SCREEN'): bytes(rnd.randrange(256) for _ in range(const('SCREEN_SIZE') + const('ATTRS_SIZE'))),
            sym('GameActive'): active}


def cases(rnd):
    scr = sym('SCREEN')
    for _ in range(150):
        third, row, col = rnd.randrange(3), rnd.randrange(8), rnd.randrange(27)
        yield 'typical', {'DE': scr + (third << 11) + (row << 5) + col, 'HL': rnd.randrange(65536),
                          'mem': screen(rnd, 1)}
    for hl in (0, 9, 10, 99, 100, 999, 1000, 9999, 10000, 59999, 65535):
        yield 'boundary', {'DE': scr + 0x40, 'HL': hl, 'mem': screen(rnd, 1)}
    for hl in (0, 12345, 65535):
        yield 'printing-off', {'DE': scr + 0x40, 'HL': hl, 'mem': screen(rnd, 0)}
        yield 'printing-off', {'DE': scr + 0x40, 'HL': hl, 'mem': screen(rnd, 0xFE)}
    for third in range(3):    # the five cells cross L = $FF -> $00 into the next third
        yield 'third-wrap', {'DE': scr + (third << 11) + 0xFD, 'HL': rnd.randrange(65536),
                             'mem': screen(rnd, 1)}


def port(regs):
    import library
    library.PrintNumber(regs['DE'], regs['HL'])
    return {}
