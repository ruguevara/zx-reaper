"""StoreRecordWord: store BC at IY + L (L = 0 or 2)."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _regs
import _parser

import parser

ROUTINE = 'StoreRecordWord'
INPUTS = ['BC', 'L', 'H', 'IY']
OUTPUTS = {'regs': ['HL'], 'mem': [(_parser.PHRASE_STACK_TOP - 48, 24)]}
KINDS = ['typical', 'boundary']


def cases(rnd):
    for _ in range(20):
        yield 'typical', {'BC': rnd.randrange(65536), 'HL': rnd.choice([0, 2]) | rnd.randrange(256) << 8, 'IY': _parser.PHRASE_STACK_TOP - 48}
    yield 'boundary', {'BC': 0, 'HL': 0xFF02, 'IY': _parser.PHRASE_STACK_TOP}
    yield 'boundary', {'BC': 0xFFFF, 'HL': 0, 'IY': 0xFFFE}        # wraps at the end of memory


def port(regs):
    return _regs.run(parser.StoreRecordWord, regs, OUTPUTS['regs'])
