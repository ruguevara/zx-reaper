"""ProbeMove tells what is one step from the 2x2 block at offset HL in direction A: free, wrap, exit or blocked."""
ROUTINE = 'ProbeMove'
INPUTS = ['A', 'HL']
OUTPUTS = {'regs': ['A', 'HL']}
KINDS = ['typical', 'walls', 'pads', 'arrows', 'mixed', 'edge', 'high-bits']
OBJ = [const('ATTR_WALL'), const('ATTR_PAD'), const('ATTR_ARROW'), const('ATTR_BLANK'),
       const('ATTR_GUARD'), const('ATTR_FLOWER'), const('ATTR_HORACE')]


def pos(third, row, col):
    return (third << 11) + (row << 5) + col


def block(rnd, kind, a, hl, pool):
    """Attributes: blank everywhere except the four cells ahead of the block, drawn from `pool`."""
    from_step = {0: -32, 1: 1, 2: 32, 3: -1}[a & 3]
    base = sym('ATTRS') + ((hl >> 11 & 3) << 8) + (hl & 255)    # no third change in these cases
    cells = [base + from_step + d for d in (0, 1, 32, 33)]
    mem = {c: rnd.choice(pool) for c in cells}
    return kind, {'A': a, 'HL': hl, 'mem': mem}


def cases(rnd):
    blank, wall, pad, arrow = const('ATTR_BLANK'), const('ATTR_WALL'), const('ATTR_PAD'), const('ATTR_ARROW')
    for _ in range(200):
        a = rnd.randrange(4)
        hl = pos(rnd.randrange(3), rnd.randrange(1, 7), rnd.randrange(1, 29))
        yield block(rnd, 'typical', a, hl, OBJ)
    for _ in range(60):
        yield block(rnd, 'walls', rnd.randrange(4), pos(1, rnd.randrange(1, 7), rnd.randrange(1, 29)), [blank, blank, wall])
        yield block(rnd, 'pads', rnd.randrange(4), pos(1, rnd.randrange(1, 7), rnd.randrange(1, 29)), [blank, pad])
        yield block(rnd, 'arrows', rnd.randrange(4), pos(1, rnd.randrange(1, 7), rnd.randrange(1, 29)), [blank, arrow])
        yield block(rnd, 'mixed', rnd.randrange(4), pos(1, rnd.randrange(1, 7), rnd.randrange(1, 29)), [pad, arrow, pad, arrow, blank])
    # block on the screen edges, stepping off them; cells beyond read whatever attribute memory holds
    for third in range(3):
        for row, col in ((0, 0), (7, 0), (0, 30), (7, 30), (0, 15), (7, 15)):
            for a in range(4):
                yield 'edge', {'A': a, 'HL': pos(third, row, col),
                               'mem': {sym('ATTRS') + k: rnd.choice(OBJ) for k in range(0, 0x300, 2)}}
    # only the low two bits of A are a direction
    for _ in range(40):
        a = rnd.randrange(256)
        yield block(rnd, 'high-bits', a, pos(1, rnd.randrange(1, 7), rnd.randrange(1, 29)), OBJ)


def port(regs):
    import library
    return {'A': library.ProbeMove(regs['A'], regs['HL']), 'HL': regs['HL']}
