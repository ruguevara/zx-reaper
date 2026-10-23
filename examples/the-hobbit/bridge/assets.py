"""Writes the game's data (game/assets/) from the original's image, once:
existing files are kept (edits survive); --force writes them again.

  python3 bridge/assets.py [--force]

The lead's part (state.json, tables.json, title.scr) is here; each slice adds
bridge/assets_<slice>.py with a write(mem, force) function."""
import glob
import importlib
import json
import os
import sys

import paths
from decode import decode, name, program, word
import labels as L
from hobbit import assets

OUT = assets.ROOT


def image():
    """The 64K memory at the handover to the game: the ROM and port/image.bin."""
    from zxpyxel.machine import ROM
    return bytearray(ROM) + bytearray(open(os.path.join(paths.ROOT, 'port/image.bin'), 'rb').read())


def writing(fname, force):
    """True when `fname` (in game/assets/) should be written."""
    p = os.path.join(OUT, fname)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    return force or not os.path.exists(p)


def table3(mem, a, value=None):
    """An (id, word) table ending in $FF: [(id, value(word))]."""
    out = []
    while mem[a] != 0xFF:
        out.append([mem[a], (value or (lambda w: w))(word(mem, a + 1))])
        a += 3
    return out


def tables(mem):
    _, behaviour, _ = program(mem)
    return {
        'verb_handlers': table3(mem, L.VerbHandlers, name),
        'arrival_handlers': table3(mem, L.ArrivalHandlers, name),
        'behaviour': {k: [list(e) for e in v] for k, v in behaviour.items()},
        'random_events': [[word(mem, L.RandomEvents + 4 * k), name(word(mem, L.RandomEvents + 4 * k + 2))]
                          for k in range(4)],
        'blocked_exits': [[mem[a], list(mem[a + 3:a + 6]),
                           (word(mem, a + 1) - word(mem, L.LocationTable + 2 * mem[a]) - 10) // 3]
                          for a in range(L.BlockedExits, L.BlockedExits + 5 * L.BLOCKED_EXIT_SIZE,
                                         L.BLOCKED_EXIT_SIZE)],
        'hints': table3(mem, L.HintTable, name),
        'first_visit_scores': table3(mem, L.FirstVisitScores),
        'key_masks': list(mem[L.KeyMasks:L.KeyMasks + 8]),
        'key_table': list(mem[L.KeyTable:L.KeyTable + 40]),
        'shift_key_table': list(mem[L.ShiftKeyTable:L.ShiftKeyTable + 40]),
        'border_tile': list(mem[L.BorderTile:L.BorderTile + 10]),
        'start_command': list(mem[L.StartCommand:L.StartCommand + 7]),
        'look_command': list(mem[L.LookCommand:L.LookCommand + 5]),
    }


def write(mem, force):
    if writing('state.json', force):
        s = decode(mem)
        with open(os.path.join(OUT, 'state.json'), 'w') as f:
            json.dump(assets.dump_state(s), f, indent=1)
    if writing('tables.json', force):
        with open(os.path.join(OUT, 'tables.json'), 'w') as f:
            json.dump(tables(mem), f, indent=1)
    if writing('title.scr', force):
        with open(os.path.join(OUT, 'title.scr'), 'wb') as f:
            f.write(bytes(mem[0x4000:0x5B00]))


def main():
    force = '--force' in sys.argv[1:]
    mem = image()
    write(mem, force)
    for f in sorted(glob.glob(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'assets_*.py'))):
        importlib.import_module(os.path.basename(f)[:-3]).write(mem, force)
    print('game/assets/: %s' % ', '.join(sorted(os.listdir(OUT))))


if __name__ == '__main__':
    main()
