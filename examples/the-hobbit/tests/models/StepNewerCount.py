"""StepNewerCount: walk to the next newer phrase record that is not an EXCEPT record."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _regs
import _parser

import parser

import _parser_walk

ROUTINE = 'StepNewerCount'
INPUTS = ['B', 'DE', 'IY']
OUTPUTS = {'regs': ['B', 'DE', 'IX', 'IY']}
KINDS = ['typical', 'boundary']


def cases(rnd):
    yield from _parser_walk.walk_cases(rnd, -1)


def port(regs):
    return _regs.run(parser.StepNewerCount, regs, OUTPUTS['regs'])
