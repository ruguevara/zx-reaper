"""MovePen: zxdiff test of the picture pen move (edges and middle)."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import _regs
import _drawing
import drawing

ROUTINE = 'MovePenRight'
INPUTS = ['A', 'D', 'E', 'F']
OUTPUTS = {'regs': ['A', 'D', 'E', 'H'] + _drawing.FLAGS}
KINDS = ['typical', 'boundary']


def cases(rnd):
    for kind, x, y in _drawing.edge_pens(rnd):
        yield kind, {'A': rnd.randrange(256), 'D': x, 'E': y, 'F': rnd.randrange(256)}


def port(regs):
    return _regs.run(drawing.MovePenRight, regs, OUTPUTS['regs'])
