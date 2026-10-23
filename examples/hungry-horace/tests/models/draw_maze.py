"""DrawMaze draws BC tile codes from HL at screen address DE: attributes from the code, then the 8-byte tile bitmaps."""
ROUTINE = 'DrawMaze'
INPUTS = ['HL', 'DE', 'BC']
OUTPUTS = {'regs': [], 'mem': [('SCREEN', const('SCREEN_SIZE') + const('ATTRS_SIZE'))]}
KINDS = ['maze', 'typical', 'third-wrap']
DATA = 0xE000
TILES = [const('TILE_EMPTY'), const('TILE_FLOWER'), const('TILE_ARROW'), const('TILE_BLANK_WHITE'), 1, 2, 3, 4, 5, 6, 7, 8]


def case(rnd, kind, hl, de, n, data=None):
    mem = {sym('SCREEN'): bytes(rnd.randrange(256) for _ in range(const('SCREEN_SIZE') + const('ATTRS_SIZE')))}
    if data is not None:
        mem[DATA] = data
    return kind, {'HL': hl, 'DE': de, 'BC': n, 'mem': mem}


def cases(rnd):
    scr = sym('SCREEN')
    for m in ('Maze1Map', 'Maze2Map', 'Maze3Map', 'Maze4Map'):
        yield case(rnd, 'maze', sym(m), scr, 768)
    for _ in range(30):
        n = rnd.randrange(1, 60)
        yield case(rnd, 'typical', DATA, scr + (rnd.randrange(3) << 11) + (rnd.randrange(8) << 5),
                   n, bytes(rnd.choice(TILES) for _ in range(n)))
    for third in range(3):
        yield case(rnd, 'third-wrap', DATA, scr + (third << 11) + 0xF0, 40,
                   bytes(rnd.choice(TILES) for _ in range(40)))


def port(regs):
    import library
    library.DrawMaze(regs['HL'], regs['DE'], regs['BC'])
    return {}
