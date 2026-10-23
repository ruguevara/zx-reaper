"""CopyNamePhrase: copy the name phrase of object B (or place B) to DE; B = $FF means none."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _regs
import _parser

import parser


ROUTINE = 'CopyNamePhrase'
INPUTS = ['A', 'B', 'DE']
OUTPUTS = {'regs': ['A', 'BC', 'DE', 'HL', 'ZF'], 'mem': [('RecBuf1', 12)]}
KINDS = ['typical', 'boundary']


def cases(rnd):
    for _ in range(30):
        yield 'typical', {'A': 0, 'B': rnd.randrange(0, 0x40), 'DE': sym('RecBuf1') + rnd.choice([0, 6])}
    for _ in range(15):
        yield 'typical', {'A': 1, 'B': rnd.randrange(1, 0x25), 'DE': sym('RecBuf1') + rnd.choice([0, 6])}
    yield 'boundary', {'A': 0, 'B': 0xFF, 'DE': sym('RecBuf1')}      # none
    yield 'boundary', {'A': 1, 'B': 0xFF, 'DE': sym('RecBuf1')}
    yield 'boundary', {'A': 0, 'B': 0, 'DE': sym('RecBuf2')}         # the player


def port(regs):
    return _regs.run(parser.CopyNamePhrase, regs, OUTPUTS['regs'])
