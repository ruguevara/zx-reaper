"""DrawBlocks draws BC block-pixel bytes from HL as 8x8 bitmap cells from screen address DE."""
ROUTINE = 'DrawBlocks'
INPUTS = ['HL', 'DE', 'BC']
OUTPUTS = {'regs': [], 'mem': [('SCREEN', const('SCREEN_SIZE'))]}
KINDS = ['typical', 'title', 'third-wrap']
DATA = 0xE000


def case(rnd, kind, de, n):
    return kind, {'HL': DATA, 'DE': de, 'BC': n,
                  'mem': {sym('SCREEN'): bytes(rnd.randrange(256) for _ in range(const('SCREEN_SIZE'))),
                          DATA: bytes(rnd.randrange(256) for _ in range(n))}}


def cases(rnd):
    scr = sym('SCREEN')
    for _ in range(40):
        yield case(rnd, 'typical', scr + (rnd.randrange(3) << 11) + (rnd.randrange(8) << 5), rnd.randrange(1, 40))
    yield case(rnd, 'title', scr + 5 * 32, 160)
    yield case(rnd, 'title', scr + 0x800 + 4 * 32, 160)
    for third in range(3):
        yield case(rnd, 'third-wrap', scr + (third << 11) + 0xF0, 40)


def port(regs):
    import library
    library.DrawBlocks(regs['HL'], regs['DE'], regs['BC'])
    return {}
