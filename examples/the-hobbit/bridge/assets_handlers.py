"""The handlers slice's assets (called by bridge/assets.py):

  handlers.json   respawn: the goblins RespawnKilledGoblin brings back (RecordTable),
                  one [goblin id, NPC slot (index in the state's npcs), home
                  location, name phrase code (the first adjective, put back over
                  "dead")] each, in the table's order;
                  bard_command: the index in the NPC program of the command
                  LA814_8 rewrites with the Bard's order (BardCommandOp)
"""
import json
import os

import paths  # noqa: F401
import labels as L
from decode import SCRIPTS, layout, word
from assets import OUT, writing

GOBLINS = 6


def respawn(mem):
    out = []
    for k in range(GOBLINS):
        a = L.RecordTable + k * L.RESPAWN_RECORD_SIZE
        slot, rest = divmod(word(mem, a + 1) - L.NpcStates, 7)
        if rest or not 0 <= slot < 17:
            raise ValueError('RecordTable entry %d: $%04X is not an NPC state' % (k, word(mem, a + 1)))
        out.append([mem[a], slot, mem[a + 3], word(mem, a + 4)])
    return out


def write(mem, force):
    if not writing('handlers.json', force):
        return
    commands, _ = layout(bytes(mem[SCRIPTS[0]:SCRIPTS[1]]))
    data = {'respawn': respawn(mem), 'bard_command': commands.index(L.BardCommandOp)}
    with open(os.path.join(OUT, 'handlers.json'), 'w') as f:
        json.dump(data, f, indent=1)
