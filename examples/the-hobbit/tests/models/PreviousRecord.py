"""PreviousRecord: IY = the nearest older non-EXCEPT record, AllStage cleared."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _regs
import _parser

import parser

import _parser_walk

ROUTINE = 'PreviousRecord'
INPUTS = ['IY', 'DE']
OUTPUTS = {'regs': ['A', 'DE', 'IX', 'IY'], 'mem': [('AllStage', 1)]}
KINDS = ['typical', 'boundary']


def cases(rnd):
    for kind, c in _parser_walk.walk_cases(rnd, 1):
        c['mem'][sym('AllStage')] = rnd.randrange(3)
        yield kind, c


def port(regs):
    return _regs.run(parser.PreviousRecord, regs, OUTPUTS['regs'])
