"""CompareHLDE: zxdiff test of the 16-bit compare."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _regs
import _keys

import keys

ROUTINE = 'CompareHLDE'
INPUTS = ['HL', 'DE']
OUTPUTS = {'regs': ['A', 'ZF', 'CF', 'SF']}
KINDS = ['typical', 'boundary']


def cases(rnd):
    for _ in range(12):
        yield 'typical', {'HL': rnd.randrange(65536), 'DE': rnd.randrange(65536)}
    for hl, de in [(0, 0), (0xFFFF, 0xFFFF), (0, 1), (1, 0), (0x0100, 0x00FF), (0x00FF, 0x0100),
                   (0x8000, 0x7FFF), (0xBB8, 0xBB8)]:
        yield 'boundary', {'HL': hl, 'DE': de}


def port(regs):
    return _regs.run(keys.CompareHLDE, regs, OUTPUTS['regs'])
