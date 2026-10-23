"""PickScanStart: where an object scan starts (class 0: ObjectTable, else one entry before it)."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _regs
import _parser

import parser

ROUTINE = 'PickScanStart'
INPUTS = ['A']
OUTPUTS = {'regs': ['A', 'IX', 'ZF']}
KINDS = ['typical', 'boundary']


def cases(rnd):
    for a in range(0, 4):
        yield 'typical', {'A': a}
    for a in (4, 0x80, 0xFC, 0xFF, 0x40):
        yield 'boundary', {'A': a}


def port(regs):
    return _regs.run(parser.PickScanStart, regs, OUTPUTS['regs'])
