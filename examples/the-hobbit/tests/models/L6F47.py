"""L6F47: zxdiff test of the dictionary lookup start (letters, index, first entry test)."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _regs
import _keys

import keys

ROUTINE = 'L6F47'
INPUTS = ['HL']
OUTPUTS = {'regs': ['A', 'B', 'C', 'HL', 'IX', 'ZF'],
           'mem': [('WordLetters', 16), ('WordLength', 1), ('MatchLetters', 16), ('MatchLength', 1),
                   ('SourceTextPtr', 2)]}
KINDS = ['typical', 'boundary']

WORDS = ['NORTH', 'N', 'GET', 'TAKE', 'SWORD', 'GANDALF', 'THE', 'ALL', 'GIVE', 'XYZZY', 'Z', 'LOOKING']


def cases(rnd):
    for w in WORDS:
        yield ('typical' if w[0] != 'Z' else 'boundary'), {
            'HL': 0x6FF9, 'BC': rnd.randrange(65536), 'mem': {0x6FF9: (w + ' X').encode() + b'\r'}}
    yield 'boundary', {'HL': 0x6FF9, 'mem': {0x6FF9: b'5\r'}}
    yield 'boundary', {'HL': 0x6FF9, 'mem': {0x6FF9: b'ZZZZZZZZZZZZZZZZZZZZ\r'}}


def port(regs):
    return _regs.run(keys.L6F47, regs, OUTPUTS['regs'])
