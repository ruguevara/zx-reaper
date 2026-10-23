"""DrawPictureLine: zxdiff test of a picture line segment (all directions, edges)."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import _regs
import _drawing
import drawing

ROUTINE = 'DrawPictureLine'
INPUTS = ['BC', 'D', 'E', 'HL', 'PicVar1']
OUTPUTS = {'regs': ['BC', 'D', 'E', 'HL', 'ZF'], 'mem': _drawing.SCREEN_MEM}
KINDS = ['typical', 'boundary']


def cases(rnd):
    for c in range(8):
        for x, y in [(127, 63), (3, 4), (250, 120), (2, 2)]:
            kind = 'typical' if (x, y) == (127, 63) else 'boundary'
            yield kind, {'B': rnd.randrange(1, 10), 'C': c, 'D': x, 'E': y,
                         'H': rnd.randrange(256), 'L': rnd.randrange(1, 65), 'PicVar1': rnd.randrange(8)}
    for _ in range(12):
        yield 'typical', {'B': rnd.randrange(1, 65), 'C': rnd.randrange(8), 'D': rnd.randrange(256),
                          'E': rnd.randrange(128), 'H': rnd.randrange(256), 'L': rnd.randrange(1, 65),
                          'PicVar1': rnd.randrange(8)}


def port(regs):
    return _regs.run(drawing.DrawPictureLine, regs, OUTPUTS['regs'])
