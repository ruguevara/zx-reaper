"""CopyPhrase: copy the noun phrase at offset A of the record IY to DE and flag it when it has words."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _regs
import _parser

import parser

ROUTINE = 'CopyPhrase'
INPUTS = ['A', 'BC', 'DE', 'HL', 'IY']
OUTPUTS = {'regs': ['A', 'B', 'C', 'DE', 'HL', 'ZF'], 'mem': [('RecWork', 1), ('RecBuf1', 12)]}
KINDS = ['typical', 'boundary']
REC = _parser.PHRASE_STACK_TOP - 48


def case(rnd, offset, empty=0.3, flag=0):
    return {'A': offset, 'BC': rnd.randrange(65536), 'DE': sym('RecBuf1') + rnd.choice([0, 6]), 'HL': sym('RecWork'), 'IY': REC,
            'mem': {REC: _parser.record(rnd, empty=empty), sym('RecWork'): flag}}


def cases(rnd):
    for _ in range(40):
        yield 'typical', case(rnd, rnd.choice([8, 0x12]), flag=rnd.choice([0, 2]))
    yield 'boundary', case(rnd, 8, empty=1.0)            # no words: the flag stays clear
    yield 'boundary', case(rnd, 0x12, empty=1.0, flag=2)
    yield 'boundary', case(rnd, 0x12, empty=0.0, flag=1)


def port(regs):
    return _regs.run(parser.CopyPhrase, regs, OUTPUTS['regs'])
