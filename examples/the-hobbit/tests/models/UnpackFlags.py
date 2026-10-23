"""UnpackFlags: StateB71D/E into NeedsLight, AllActive, Noun1Kind and Noun2Kind."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _regs
import _parser

import parser

ROUTINE = 'UnpackFlags'
INPUTS = ['StateB71D', 'StateB71E']
OUTPUTS = {'regs': ['A', 'B'], 'mem': [('NeedsLight', 1), ('AllActive', 1), ('Noun1Kind', 2)]}
KINDS = ['typical', 'boundary']


def cases(rnd):
    for _ in range(30):
        yield 'typical', {'mem': {sym('StateB71D'): rnd.randrange(256), sym('StateB71E'): rnd.randrange(256)}}
    for d, e in ((0, 0), (0xFF, 0xFF), (0x80, 0x40), (0x40, 0), (1, 0x3F)):
        yield 'boundary', {'mem': {sym('StateB71D'): d, sym('StateB71E'): e}}


def port(regs):
    return _regs.run(parser.UnpackFlags, regs, OUTPUTS['regs'])
