"""ScanPunctuation: zxdiff test of the punctuation to token routine."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _regs
import _keys

import keys

ROUTINE = 'ScanPunctuation'
INPUTS = ['A', 'HL']
OUTPUTS = {'regs': ['A', 'B', 'BC', 'HL', 'ZF', 'CF']}
KINDS = ['typical', 'boundary']


def cases(rnd):
    for ch in b'.,"':
        yield 'typical', {'A': ch, 'HL': 0x6FF9, 'BC': rnd.randrange(65536)}
    for ch in [0x0D, 0x20, 0x41, 0x5A, 0x2B, 0x2D, 0x22 - 1, 0x22 + 1, 0, 0xFF]:
        yield 'boundary', {'A': ch, 'HL': 0xFFFF, 'BC': rnd.randrange(65536)}


def port(regs):
    return _regs.run(keys.ScanPunctuation, regs, OUTPUTS['regs'])
