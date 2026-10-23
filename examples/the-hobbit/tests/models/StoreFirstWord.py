"""StoreFirstWord: no command word is needed any more (E bit 1), BC is the record's first word."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _regs
import _parser

import parser

ROUTINE = 'StoreFirstWord'
INPUTS = ['BC', 'E', 'IY']
OUTPUTS = {'regs': ['E', 'HL'], 'mem': [(_parser.PHRASE_STACK_TOP - 48, 24)]}
KINDS = ['typical', 'boundary']


def cases(rnd):
    for _ in range(20):
        yield 'typical', {'BC': rnd.randrange(65536), 'E': rnd.randrange(256), 'HL': rnd.randrange(65536), 'IY': _parser.PHRASE_STACK_TOP - 48}
    yield 'boundary', {'BC': 0x0130, 'E': 0xFF, 'HL': 0, 'IY': _parser.PHRASE_STACK_TOP}
    yield 'boundary', {'BC': 0x0130, 'E': 0, 'HL': 0xFFFF, 'IY': _parser.PHRASE_STACK_TOP}


def port(regs):
    return _regs.run(parser.StoreFirstWord, regs, OUTPUTS['regs'])
