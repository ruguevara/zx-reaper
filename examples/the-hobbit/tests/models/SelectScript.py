"""SelectScript: zxdiff test of the NPC behaviour entry choice."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import _npc
import _regs
import engine
from labels import NpcStates, NPC_RECORD_SIZE

ROUTINE = 'SelectScript'
INPUTS = ['DE', 'IY']
OUTPUTS = {'regs': ['A', 'DE', 'HL', 'IY'],
           'mem': [(NpcStates, 17 * NPC_RECORD_SIZE)]}
KINDS = ['typical', 'boundary']


def cases(rnd):
    for a in _npc.records()[:-1]:
        top = _npc.byte(a + 1)
        yield 'typical', {'IY': a, 'DE': rnd.randrange(top + 1)}      # E within the highest index
        yield 'boundary', {'IY': a, 'DE': top}                        # E = the highest index
        yield 'boundary', {'IY': a, 'DE': top + 1 + rnd.randrange(8)}  # E above it: limited


def port(regs):
    return _regs.run(engine.SelectScript, regs, OUTPUTS['regs'])
