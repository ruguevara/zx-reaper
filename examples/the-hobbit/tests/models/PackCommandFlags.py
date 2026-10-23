"""PackCommandFlags: zxdiff test of the command record flag nibble packing."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _regs
import _keys

import keys

ROUTINE = 'PackCommandFlags'
INPUTS = ['IX']
OUTPUTS = {'regs': ['A', 'C'], 'mem': [('StateB71D', 2)]}
KINDS = ['typical', 'boundary']


def cases(rnd):
    for k, rec in enumerate(_keys.command_table()):
        yield 'typical', {'IX': _keys.COMMAND_TABLE + 8 * k, 'C': rnd.randrange(256)}
    for rec in [b'\x00' * 8, b'\xff' * 8, bytes([0, 0xF0, 0, 0x0F, 0, 0xA5, 0, 0x5A])]:
        yield 'boundary', {'IX': 0x7000, 'mem': {0x7000: rec}}


def port(regs):
    return _regs.run(keys.PackCommandFlags, regs, OUTPUTS['regs'])
