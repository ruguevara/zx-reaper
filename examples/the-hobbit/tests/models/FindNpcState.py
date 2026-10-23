"""FindNpcState: zxdiff test of the NPC record search."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import _npc
import _regs
import engine

ROUTINE = 'FindNpcState'
INPUTS = ['A', 'BC', 'DE']
OUTPUTS = {'regs': ['A', 'BC', 'DE', 'HL', 'IY', 'ZF', 'CF', 'SF']}
KINDS = ['typical', 'boundary']


def cases(rnd):
    recs = _npc.records()
    for a in recs[:-1]:                                    # every id in the table
        yield 'typical', {'A': _npc.byte(a), 'BC': rnd.randrange(65536), 'DE': rnd.randrange(65536)}
    for a in (0x00, 0x01, 0x7F, 0xFF):                     # dormant (several), absent, the end mark
        yield 'boundary', {'A': a, 'BC': rnd.randrange(65536), 'DE': rnd.randrange(65536)}


def port(regs):
    return _regs.run(engine.FindNpcState, regs, OUTPUTS['regs'])
