"""CommandRecordAddr: zxdiff test of the command table record address."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _regs
import _keys

import keys

ROUTINE = 'CommandRecordAddr'
INPUTS = ['A']
OUTPUTS = {'regs': ['DE', 'HL', 'CF']}
KINDS = ['typical', 'boundary']


def cases(rnd):
    for a in [1, 2, 11, 30, 58, 59]:
        yield 'typical', {'A': a, 'HL': rnd.randrange(65536)}
    for a in [0, 60, 127, 128, 255]:
        yield 'boundary', {'A': a, 'HL': rnd.randrange(65536)}


def port(regs):
    return _regs.run(keys.CommandRecordAddr, regs, OUTPUTS['regs'])
