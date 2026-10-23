"""GetBlockObject returns the object attribute (guard > bell > flower, else 0) among the 2x2 cells at offset HL."""
ROUTINE = 'GetBlockObject'
INPUTS = ['HL']
OUTPUTS = {'regs': ['A', 'HL']}
KINDS = ['typical', 'combos', 'edge']
OBJ = [const('ATTR_GUARD'), const('ATTR_BELL'), const('ATTR_FLOWER'), const('ATTR_BLANK'),
       const('ATTR_WALL'), const('ATTR_PAD'), const('ATTR_ARROW'), const('ATTR_HORACE')]


def attrs(rnd):
    return {sym('ATTRS'): bytes(rnd.choice(OBJ) for _ in range(const('ATTRS_SIZE')))}


def cells(hl):
    return [hl, hl + 1, hl + 32, hl + 33]


def pos(third, row, col):
    return (third << 11) + (row << 5) + col


def cases(rnd):
    for _ in range(200):
        yield 'typical', {'HL': pos(rnd.randrange(3), rnd.randrange(8), rnd.randrange(31)), 'mem': attrs(rnd)}
    # every mix of guard/bell/flower/blank in the four cells (a block in the second third)
    hl = pos(1, 3, 10)
    for combo in range(256):
        a = sym('ATTRS') + 0x100 + (3 << 5) + 10     # attribute cells of that block
        vals = [OBJ[combo >> (2 * i) & 3] for i in range(4)]
        mem = {a: vals[0], a + 1: vals[1], a + 32: vals[2], a + 33: vals[3]}
        yield 'combos', {'HL': hl, 'mem': mem}
    for third in range(3):
        for row, col in ((0, 0), (7, 0), (7, 30), (0, 30), (7, 31), (3, 31)):
            yield 'edge', {'HL': pos(third, row, col), 'mem': attrs(rnd)}


def port(regs):
    import library
    return {'A': library.GetBlockObject(regs['HL']), 'HL': regs['HL']}
