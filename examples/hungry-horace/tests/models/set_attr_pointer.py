"""SetAttrPointer puts the attribute address of screen address HL in HL' and keeps HL."""
ROUTINE = 'SetAttrPointer'
INPUTS = ['HL']
OUTPUTS = {'regs': ['^HL', 'HL']}
KINDS = ['typical', 'boundary']


def cases(rnd):
    for _ in range(300):
        third, row, col = rnd.randrange(3), rnd.randrange(8), rnd.randrange(32)
        yield 'typical', {'HL': sym('SCREEN') + (third << 11) + (row << 5) + col}
    for third in range(3):
        for low in (0x00, 0x1F, 0xE0, 0xFF):
            yield 'boundary', {'HL': sym('SCREEN') + (third << 11) + low}


def model(regs, mem):
    h, low = regs['HL'] >> 8, regs['HL'] & 255
    third = (h & const('THIRD_BITS')) >> 3
    return {'^HL': (sym('ATTRS') >> 8) + third << 8 | low, 'HL': regs['HL']}


def port(regs):
    import library
    return {'^HL': library.SetAttrPointer(regs['HL']), 'HL': regs['HL']}
