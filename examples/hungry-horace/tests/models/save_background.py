"""SaveBackground stores the 2x2 cells at offset HL (attribute + 8 rows each; guard cells blank) in SavedBackground."""
ROUTINE = 'SaveBackground'
INPUTS = ['HL']
OUTPUTS = {'regs': [], 'mem': [('SavedBackground', 36)]}
KINDS = ['typical', 'guards', 'last-row', 'last-col', 'third-end']
OBJ = [const('ATTR_GUARD'), const('ATTR_BLANK'), const('ATTR_WALL'), const('ATTR_FLOWER')]


def case(rnd, kind, third, row, col, guards):
    hl = (third << 11) + (row << 5) + col
    scr = bytes(rnd.randrange(256) for _ in range(const('SCREEN_SIZE')))
    attrs = bytes(rnd.choice(OBJ) if guards else rnd.randrange(256) for _ in range(const('ATTRS_SIZE')))
    return kind, {'HL': hl, 'mem': {sym('SCREEN'): scr, sym('ATTRS'): attrs,
                                    sym('SavedBackground'): bytes(rnd.randrange(256) for _ in range(36))}}


def cases(rnd):
    for _ in range(100):
        yield case(rnd, 'typical', rnd.randrange(3), rnd.randrange(8), rnd.randrange(31), False)
        yield case(rnd, 'guards', rnd.randrange(3), rnd.randrange(8), rnd.randrange(31), True)
    for third in range(3):
        for col in (0, 15, 30):
            yield case(rnd, 'last-row', third, 7, col, True)
        yield case(rnd, 'last-col', third, 2, 31, True)
        yield case(rnd, 'third-end', third, 7, 31, True)
        yield case(rnd, 'third-end', third, 7, 31, False)


def port(regs):
    import library
    library.SaveBackground(regs['HL'])
    return {}
