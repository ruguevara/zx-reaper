"""ReadWord: the next token of the parsed word list (class nibble, 12-bit offset)."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _regs
import _parser

import parser

ROUTINE = 'ReadWord'
INPUTS = ['D', 'WordListPtr']
OUTPUTS = {'regs': ['A', 'B', 'C', 'D', 'HL'], 'mem': [('InputLinePtr', 2), ('WordFlags', 1), ('WordListPtr', 2)]}
KINDS = ['typical', 'boundary']


def case(rnd, at, d=None):
    toks = [rnd.randrange(256) for _ in range(8)]
    return {'D': rnd.randrange(256) & 0xF0 if d is None else d,
            'mem': {sym('ParsedWords'): toks, sym('WordListPtr'): [(sym('ParsedWords') + at) & 255, (sym('ParsedWords') + at) >> 8]}}


def cases(rnd):
    for _ in range(30):
        yield 'typical', case(rnd, rnd.choice([0, 2, 4, 6]))
    yield 'boundary', case(rnd, 0, 0)
    yield 'boundary', case(rnd, 6, 0xC0)


def port(regs):
    return _regs.run(parser.ReadWord, regs, OUTPUTS['regs'])
