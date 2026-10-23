"""AttrLeft: zxdiff test of the attribute address step."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import _regs
import drawing

ROUTINE = 'AttrLeft'
INPUTS = ['A', 'DE', 'HL', 'F']
OUTPUTS = {'regs': ['A', 'DE', 'HL', 'ZF', 'CF', 'SF', 'PF']}
KINDS = ['typical', 'boundary']


def cases(rnd):
    for hl in [0x5800, 0x581F, 0x5820, 0x59FF, 0x59E0, 0x5A00, 0x5900, 0x5801, 0x59FE]:
        yield 'boundary', {'A': rnd.randrange(256), 'DE': rnd.randrange(65536), 'HL': hl, 'F': rnd.randrange(256)}
    for _ in range(12):
        yield 'typical', {'A': rnd.randrange(256), 'DE': rnd.randrange(65536),
                          'HL': 0x5800 + rnd.randrange(0x200), 'F': rnd.randrange(256)}


def port(regs):
    return _regs.run(drawing.AttrLeft, regs, OUTPUTS['regs'])
