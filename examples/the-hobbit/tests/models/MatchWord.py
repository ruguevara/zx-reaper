"""MatchWord: zxdiff test of the parsed word against record word compare."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _regs
import _keys

import keys

ROUTINE = 'MatchWord'
INPUTS = ['HL', 'IY']
OUTPUTS = {'regs': ['A', 'HL', 'IY', 'ZF', 'CF']}
KINDS = ['typical', 'boundary']


def cases(rnd):
    for k, rec in enumerate(_keys.command_table()):
        for w in range(4):
            tok = rec[2 * w:2 * w + 2]
            kind = 'typical'
            if rnd.random() < 0.3:
                tok = bytes([tok[0], tok[1] & 0x0F | rnd.randrange(16) << 4])   # class nibble ignored
            elif rnd.random() < 0.3:
                tok = bytes([rnd.randrange(256), rnd.randrange(256)])
            yield kind, {'HL': 0x7000, 'IY': _keys.COMMAND_TABLE + 8 * k + 2 * w,
                         'mem': {0x7000: tok}}
    for tok in [b'\x00\x00', b'\x00\x10', b'\x01\x00', b'\xff\xff']:
        yield 'boundary', {'HL': 0x7000, 'IY': _keys.COMMAND_TABLE, 'mem': {0x7000: tok}}


def port(regs):
    return _regs.run(keys.MatchWord, regs, OUTPUTS['regs'])
