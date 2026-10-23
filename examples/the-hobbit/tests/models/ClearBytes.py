"""ClearBytes: zxdiff test of the block zeroing."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _regs
import _keys

import keys

ROUTINE = 'ClearBytes'
INPUTS = ['HL', 'B']
OUTPUTS = {'regs': ['A', 'B', 'HL', 'ZF'], 'mem': [(0x5E00, 0x120)]}
KINDS = ['typical', 'boundary']


def cases(rnd):
    for n in [1, 5, 16, 64, 100]:
        yield 'typical', {'HL': 0x5E00 + rnd.randrange(16), 'B': n, 'A': rnd.randrange(256),
                          'mem': {0x5E00: bytes(rnd.randrange(1, 256) for _ in range(0x120))}}
    for n in [0, 1, 255]:
        yield 'boundary', {'HL': 0x5E00, 'B': n, 'mem': {0x5E00: b'\xff' * 0x120}}


def port(regs):
    return _regs.run(keys.ClearBytes, regs, OUTPUTS['regs'])
