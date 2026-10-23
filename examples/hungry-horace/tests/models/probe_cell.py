"""ProbeCell adds the cell at HL' to the running total E': wall = $FF (sticky), pad +1, arrow +4."""
ROUTINE = 'ProbeCell'
INPUTS = ['E', 'HL']
OUTPUTS = {'regs': ['E']}
KINDS = ['wall', 'pad', 'arrow', 'other', 'blocked']
ADDR = 0xE000


def cases(rnd):
    for e in (0, 1, 2, 3, 4, 5, 8, 9, 12, 16, 0xFF):
        for a, kind in ((const('ATTR_WALL'), 'wall'), (const('ATTR_PAD'), 'pad'),
                        (const('ATTR_ARROW'), 'arrow'), (const('ATTR_BLANK'), 'other'),
                        (const('ATTR_GUARD'), 'other'), (rnd.randrange(256), 'other')):
            yield 'blocked' if e == 0xFF else kind, {'E': e, 'HL': ADDR, 'mem': {ADDR: a}}


def port(regs):
    import library
    return {'E': library.ProbeCell(regs['E'], regs['HL'])}
