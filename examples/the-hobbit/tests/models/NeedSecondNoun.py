"""NeedSecondNoun: must the second noun phrase be matched next? Z no, NZ yes."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _regs
import _parser

import parser

ROUTINE = 'NeedSecondNoun'
INPUTS = ['StateB71D', 'RecWork1']
OUTPUTS = {'regs': ['A', 'HL', 'ZF']}
KINDS = ['typical', 'boundary']


def cases(rnd):
    for _ in range(30):
        yield 'typical', {'mem': {sym('StateB71D'): rnd.randrange(256), sym('RecWork1'): rnd.randrange(4)}}
    for d in (0, 3, 4, 6, 0xFF):                    # no second noun / bit 2 only / bit 2+1 / ...
        for w in (0, 1):
            yield 'boundary', {'mem': {sym('StateB71D'): d, sym('RecWork1'): w}}


def port(regs):
    return _regs.run(parser.NeedSecondNoun, regs, OUTPUTS['regs'])
