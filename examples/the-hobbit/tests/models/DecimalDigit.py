"""DecimalDigit: zxdiff test of the digit by repeated subtraction (score printing)."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _regs
import _keys

import system

ROUTINE = 'DecimalDigit'
INPUTS = ['HL', 'DE']
OUTPUTS = {'regs': ['A', 'HL', 'ZF', 'CF']}
KINDS = ['typical', 'boundary']


def cases(rnd):
    for _ in range(10):
        score = rnd.randrange(1000)
        yield 'typical', {'HL': score, 'DE': 100}
        yield 'typical', {'HL': score % 100, 'DE': 10}
    for hl, de in [(0, 100), (99, 100), (100, 100), (999, 100), (0, 10), (9, 10), (10, 10), (1099, 100), (65535, 10000)]:
        yield 'boundary', {'HL': hl, 'DE': de}


def port(regs):
    return _regs.run(system.DecimalDigit, regs, OUTPUTS['regs'])
