"""TestPixel: zxdiff test of the lit/clear pixel test."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import _regs
import _drawing
import drawing

ROUTINE = 'TestPixel'
INPUTS = ['D', 'E', 'HL']
OUTPUTS = {'regs': ['A', 'BC', 'HL'] + _drawing.FLAGS}
KINDS = ['typical', 'boundary']


def cases(rnd):
    for kind, x, y in _drawing.edge_pens(rnd):
        byte = rnd.choice([0, 0xFF, rnd.randrange(256)])
        yield kind, {'D': x, 'E': y, 'BC': rnd.randrange(65536), 'HL': rnd.randrange(65536),
                     'mem': {_drawing.screen_addr(x, y): byte}}


def port(regs):
    return _regs.run(drawing.TestPixel, regs, OUTPUTS['regs'])
