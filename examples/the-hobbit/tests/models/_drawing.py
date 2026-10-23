"""Helpers for the drawing tests: pen positions, screen addresses, flag inputs."""
FLAGS = ['ZF', 'CF', 'SF', 'PF']
SCREEN_MEM = [(0x4000, 0x1000), (0x5800, 0x200)]


def edge_pens(rnd):
    """Pen positions at the edges and a few random ones: (kind, x, y)."""
    for x, y in [(0, 0), (255, 127), (0, 127), (255, 0), (127, 63), (7, 1), (8, 126)]:
        yield 'boundary', x, y
    for _ in range(12):
        yield 'typical', rnd.randrange(256), rnd.randrange(128)


def screen_addr(x, y):
    row = 0x7F - y
    return 0x4000 | (row & 7) << 8 | (row & 0xC0) << 5 | (row & 0x38) << 2 | x >> 3


def attr_addr(x, y):
    return 0x5800 | (screen_addr(x, y) >> 8 & 0x18) << 5 | screen_addr(x, y) & 0xFF
