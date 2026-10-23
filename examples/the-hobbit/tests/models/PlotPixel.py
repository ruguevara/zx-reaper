"""PlotPixel: zxdiff test of plotting a picture pixel and colouring its cell."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import _regs
import _drawing
import drawing

ROUTINE = 'PlotPixel'
INPUTS = ['D', 'E', 'HL', 'PicVar1']
OUTPUTS = {'regs': ['A', 'BC', 'HL'] + _drawing.FLAGS, 'mem': _drawing.SCREEN_MEM}
KINDS = ['typical', 'boundary']


def cases(rnd):
    for kind, x, y in _drawing.edge_pens(rnd):
        ink = rnd.choice([0, 7, 0x38, rnd.randrange(8)])
        attr = rnd.randrange(256)
        if rnd.random() < 0.4:
            attr = attr & 0xC0 | (ink & 7) << 3 | rnd.randrange(8)   # ink equals paper
        yield kind, {'D': x, 'E': y, 'HL': rnd.randrange(65536), 'PicVar1': ink,
                     'mem': {_drawing.screen_addr(x, y): rnd.randrange(256),
                             _drawing.attr_addr(x, y): attr}}


def port(regs):
    return _regs.run(drawing.PlotPixel, regs, OUTPUTS['regs'])
