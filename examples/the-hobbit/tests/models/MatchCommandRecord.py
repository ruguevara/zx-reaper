"""MatchCommandRecord: zxdiff test of the command record against typed phrase match."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _regs
import _keys

import keys

ROUTINE = 'MatchCommandRecord'
INPUTS = ['HL', 'IY', 'DE']
OUTPUTS = {'regs': ['A', 'DE', 'HL', 'IY', 'ZF'], 'mem': [('PhraseMatched', 1)]}
KINDS = ['typical', 'boundary']


def cases(rnd):
    table = _keys.command_table()
    for k, rec in enumerate(table):
        verb, p1, p2 = rec[0:2], rec[2:4], rec[4:6]
        for phrase in [verb + p1 + p2,           # in order
                       verb + p2 + p1,           # swapped
                       verb + b'\x00\x00' + b'\x00\x00',
                       verb + p1 + bytes([rnd.randrange(256), rnd.randrange(256)]),
                       bytes([rnd.randrange(256), rnd.randrange(256)]) + p1 + p2]:
            yield 'typical', {'HL': 0x7000, 'IY': _keys.COMMAND_TABLE + 8 * k, 'DE': rnd.randrange(65536),
                              'mem': {0x7000: phrase, 0xB6DF: 0}}
    yield 'boundary', {'HL': 0x7000, 'IY': _keys.COMMAND_TABLE, 'mem': {0x7000: b'\x00' * 6, 0xB6DF: 1}}
    yield 'boundary', {'HL': 0x7000, 'IY': _keys.COMMAND_TABLE, 'mem': {0x7000: b'\xff' * 6, 0xB6DF: 1}}


def port(regs):
    return _regs.run(keys.MatchCommandRecord, regs, OUTPUTS['regs'])
