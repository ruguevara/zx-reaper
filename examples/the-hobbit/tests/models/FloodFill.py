"""FloodFill: zxdiff test of the scan-line flood fill on drawn boxes, strips and
a region open to the picture edges."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import _regs
import _drawing
import drawing

ROUTINE = 'FloodFill'
INPUTS = ['A', 'D', 'E', 'HL']
OUTPUTS = {'regs': ['A', 'DE', 'HL', 'ZF', 'CF', 'SF'],
           'mem': _drawing.SCREEN_MEM + [('DrawVar1', 2), ('PicVar1', 1)]}
KINDS = ['typical', 'boundary']


def bitmap(lit):
    """The 4K picture bitmap with the pixels `lit` ((x, y) pairs) set."""
    m = bytearray(0x1000)
    for x, y in lit:
        m[_drawing.screen_addr(x, y) - 0x4000] |= 0x80 >> (x & 7)
    return bytes(m)


def box(x0, y0, x1, y1):
    return ([(x, y) for x in range(x0, x1 + 1) for y in (y0, y1)] +
            [(x, y) for y in range(y0, y1 + 1) for x in (x0, x1)])


def case(rnd, lit, x, y):
    return {'A': rnd.randrange(8), 'D': x, 'E': y, 'HL': rnd.randrange(65536),
            'mem': {0x4000: bitmap(lit)}}


def cases(rnd):
    yield 'typical', case(rnd, box(20, 20, 40, 35), 30, 28)
    yield 'typical', case(rnd, box(20, 20, 40, 35) + box(25, 24, 30, 30), 22, 22)       # a hole inside
    yield 'typical', case(rnd, box(9, 9, 14, 30) + [(11, 15), (12, 15)], 10, 10)
    diamond = [(60 + i, 50 + 5 - abs(i - 5)) for i in range(11)] + [(60 + i, 50 - 5 + abs(i - 5)) for i in range(11)]
    yield 'typical', case(rnd, diamond, 65, 50)
    # boundary: strips open to the left and right edges, the top and bottom edges
    yield 'boundary', case(rnd, [(x, 10) for x in range(256)] + [(x, 14) for x in range(256)], 100, 12)
    yield 'boundary', case(rnd, [(x, 5) for x in range(256)], 0, 0)
    yield 'boundary', case(rnd, [(x, 122) for x in range(256)], 255, 127)
    yield 'boundary', case(rnd, box(0, 0, 8, 8), 4, 4)
    yield 'boundary', case(rnd, box(0, 0, 8, 8), 0, 0)                                    # seed on a lit pixel
    yield 'boundary', case(rnd, [(x, 20) for x in range(256)] + [(5, y) for y in range(20)], 3, 3)


def port(regs):
    return _regs.run(drawing.FloodFill, regs, OUTPUTS['regs'])
