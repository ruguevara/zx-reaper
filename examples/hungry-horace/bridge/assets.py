"""The game data stage 4 needs, from the original's RAM image (port/image.bin)
and the build's labels, as game/assets.json: game data, never committed.

  python bridge/assets.py   (from the project root; make game/assets.json)"""
import json
import os

import paths
import labels as L
from decode import decode, pos
from horace.state import to_json
from zxpyxel.machine import ROM

MAPS = [L.Maze1Map, L.Maze2Map, L.Maze3Map, L.Maze4Map]       # play order


def main():
    mem = bytearray(ROM) + open(os.path.join(paths.ROOT, 'port/image.bin'), 'rb').read()

    def hexes(a, n, size):
        return [mem[a + size * i:a + size * (i + 1)].hex() for i in range(n)]

    def word(a):
        return mem[a] | mem[a + 1] << 8

    def text(a):
        return list(mem[a:mem.index(L.TEXT_END, a)])

    mazes = []
    for n, m in enumerate(MAPS):
        d = L.MazeDescriptor + (n + 1) * L.MAZE_DESC_SIZE
        mazes.append({'map': list(mem[m:m + 768]), 'wrap': word(d), 'bell': pos(word(d + 2)),
                      'guard_start': pos(word(d + 4)), 'horace_start': pos(word(d + 6))})
    assets = {
        'rom': ROM[:0x2000].hex(),          # GetRandom and the guards' AI read these as random numbers
        'font': hexes(0x3D00, 96, 8),
        'tiles': hexes(L.TileGraphics, 10, 8),
        'horace': [hexes(L.HoraceSprites, 4, 32), hexes(L.HoraceSprites2, 4, 32)],
        'guard': [hexes(L.GuardSprites, 4, 32), hexes(L.GuardSprites2, 4, 32)],
        'scared': hexes(L.ScaredGuardSprites, 2, 32),
        'bell': hexes(L.BellSprites, 4, 32),
        'fruit': [[[mem[a + 9 * i], mem[a + 9 * i + 1:a + 9 * i + 9].hex()] for i in range(4)]
                  for a in (L.FruitCellsA, L.FruitCellsB)],
        'title_words': [list(mem[L.TitleHungry:L.TitleHungry + 160]),
                        list(mem[L.TitleHorace:L.TitleHorace + 160])],
        'texts': {'title': text(L.TitleText), 'demo': text(L.DemoText),
                  'status': text(L.StatusText)},
        'mazes': mazes,
        'initial': to_json(decode(mem, 'title')),     # the variables as loaded, before Start
    }
    with open(os.path.join(paths.ROOT, 'game/assets.json'), 'w') as f:
        json.dump(assets, f)


if __name__ == '__main__':
    main()
