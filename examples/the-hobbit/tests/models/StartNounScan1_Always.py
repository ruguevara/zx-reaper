"""StartNounScan1_Always: the start of the candidate scan for noun 1 (StateB71E bits 2-3, Noun1Kind), into RecPtr1."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _regs
import _parser

import parser

ROUTINE = 'StartNounScan1_Always'
INPUTS = ['StateB71E', 'Noun1Kind', 'Subject']
OUTPUTS = {'regs': ['A', 'IX', 'ZF'], 'mem': [('RecPtr1', 2)]}
KINDS = ['typical', 'boundary']


def cases(rnd):
    for _ in range(30):
        yield 'typical', {'IX': rnd.randrange(65536), 'mem': {sym('StateB71E'): rnd.randrange(256), sym('Noun1Kind'): 0, sym('Subject'): 0}}
    for e in (0, 0x0F, 0xF0, 0xFF):
        for kind in (0, 1):
            yield 'boundary', {'IX': 0, 'mem': {sym('StateB71E'): e, sym('Noun1Kind'): kind, sym('Subject'): 0}}


def port(regs):
    return _regs.run(parser.StartNounScan1_Always, regs, OUTPUTS['regs'])
