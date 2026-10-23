"""PenToScreen: zxdiff test of the pen position to screen address and mask."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import _regs
import _drawing
import drawing

ROUTINE = 'PenToScreen'
INPUTS = ['A', 'BC', 'D', 'E', 'HL']
OUTPUTS = {'regs': ['A', 'BC', 'HL'] + _drawing.FLAGS}
KINDS = ['typical', 'boundary']


def cases(rnd):
    for kind, x, y in _drawing.edge_pens(rnd):
        yield kind, {'A': rnd.randrange(256), 'BC': rnd.randrange(65536), 'D': x, 'E': y, 'HL': rnd.randrange(65536)}
    for x in range(8):
        yield 'typical', {'A': 0, 'BC': 0x1234, 'D': 16 + x, 'E': 40, 'HL': 0}


def port(regs):
    return _regs.run(drawing.PenToScreen, regs, OUTPUTS['regs'])
