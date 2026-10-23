"""CollectWord: copy the word at offset E of the phrase record IY to the list at HL; a non-zero word uses a slot."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _regs
import _parser

import parser

ROUTINE = 'CollectWord'
INPUTS = ['B', 'E', 'HL', 'IY']
OUTPUTS = {'regs': ['A', 'B', 'D', 'HL', 'IY', 'ZF'], 'mem': [('RecWord2', 4)]}
KINDS = ['typical', 'boundary']
REC = _parser.PHRASE_STACK_TOP


def case(rnd, b, e, w):
    rec = _parser.record(rnd)
    rec[e:e + 2] = w
    return {'B': b, 'E': e, 'HL': sym('RecWord2') + rnd.choice([0, 2]), 'IY': REC, 'mem': {REC: rec}}


def cases(rnd):
    for _ in range(40):
        yield 'typical', case(rnd, rnd.choice([1, 2]), rnd.choice([4, 14, 6, 16]), _parser.word(rnd))
    yield 'boundary', case(rnd, 0, 4, [5, 1])           # no room: nothing happens
    yield 'boundary', case(rnd, 2, 4, [0, 0])           # a zero word is stored but not counted
    yield 'boundary', case(rnd, 1, 16, [0xFF, 0x0F])    # the last slot is used up


def port(regs):
    return _regs.run(parser.CollectWord, regs, OUTPUTS['regs'])
