"""AdvanceScript: zxdiff test of the NPC script pointer step."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import _npc
import _regs
import engine
from labels import NpcStates, NPC_RECORD_SIZE

ROUTINE = 'AdvanceScript'
INPUTS = ['HL', 'DE', 'IX', 'IY']
OUTPUTS = {'regs': ['HL', 'DE', 'IX', 'IY'],
           'mem': [(NpcStates, 17 * NPC_RECORD_SIZE)]}
KINDS = ['typical', 'boundary']


def cases(rnd):
    recs = _npc.records()[:-1]
    cmds = {k: [a for a in range(0xC82D, 0xCA84) if _npc.byte(a) >> 4 & 1 == k] for k in (0, 1)}
    for k in (0, 1):                                       # bit 4 clear / set: boundary of the extra word
        for de in (2, 4):
            for _ in range(4):
                a = rnd.choice(cmds[k])
                yield 'boundary', {'HL': a, 'IX': a, 'DE': de, 'IY': rnd.choice(recs)}
    for _ in range(12):
        a = rnd.randrange(0xC82D, 0xCA84)
        yield 'typical', {'HL': a, 'IX': a, 'DE': rnd.choice((2, 4)), 'IY': rnd.choice(recs)}


def port(regs):
    return _regs.run(engine.AdvanceScript, regs, OUTPUTS['regs'])
