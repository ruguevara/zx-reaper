"""The game's data, from the original's RAM image (port/image.bin) and the
build's labels, as editable files in game/assets/ (game data, never
committed):

  tiles.png    10 tiles of 8x8, in their game colours on white
  horace.png   4 directions x 2 walking frames, 16x16 each (the first row: frame 0)
  guard.png    the same for a guard
  scared.png   the 2 frames of a scared guard
  bell.png     the 4 frames of the swinging bell
  fruit.png    the 2 fruits; each cell's ink is its colour in the game
  title.png    HUNGRY and HORACE, one pixel a 4x4 block (64x10 each)
  mazes.txt    the 4 mazes as text, a header line with their positions
  texts.json   the title, demo and status texts
  state.json   the variables as loaded, before the game starts

  python bridge/assets.py [--force]   (make game/assets/state.json; existing
                                       files are kept unless --force)"""
import json
import os
import sys

import paths
import labels as L
from decode import decode, pos
from horace.assets import TILE_CHARS
from horace.state import to_json
from zxpyxel import png
from zxpyxel.machine import ROM

MAPS = [L.Maze1Map, L.Maze2Map, L.Maze3Map, L.Maze4Map]       # play order
TILE_INKS = {0: 0, 1: 5, 2: 4, 3: 0, 4: 5, 5: 5, 6: 5, 7: 5, 8: 5, 9: 0}   # black where the game's ink is white


def sprites(mem, rows, cols):
    """Rows of sprite addresses -> cells for png.write_cells, 2x2 cells a sprite."""
    out = [None] * (len(rows) * 2 * cols * 2)
    for sy, (row, ink) in enumerate(rows):
        for sx, a in enumerate(row):
            for k in range(4):
                cx, cy = 2 * sx + (k & 1), 2 * sy + (k >> 1)
                out[cy * cols * 2 + cx] = (bytes(mem[a + 8 * k:a + 8 * k + 8]), ink, False)
    return out


def main():
    d = os.path.join(paths.ROOT, 'game/assets')
    if os.path.exists(os.path.join(d, 'state.json')) and '--force' not in sys.argv:
        sys.exit('%s exists (edited assets are kept); --force writes it again' % d)
    os.makedirs(d, exist_ok=True)
    mem = bytearray(ROM) + open(os.path.join(paths.ROOT, 'port/image.bin'), 'rb').read()

    def word(a):
        return mem[a] | mem[a + 1] << 8

    def path(name):
        return os.path.join(d, name)

    png.write_cells(path('tiles.png'), 10, 1, [(bytes(mem[L.TileGraphics + 8 * i:][:8]),
                                                 TILE_INKS[i], False) for i in range(10)])
    four = lambda base: [base + 32 * i for i in range(4)]      # noqa: E731
    png.write_cells(path('horace.png'), 8, 4, sprites(mem, [(four(L.HoraceSprites), 1),
                                                            (four(L.HoraceSprites2), 1)], 4))
    png.write_cells(path('guard.png'), 8, 4, sprites(mem, [(four(L.GuardSprites), 3),
                                                           (four(L.GuardSprites2), 3)], 4))
    png.write_cells(path('scared.png'), 4, 2,
                    sprites(mem, [([L.ScaredGuardSprites, L.ScaredGuardSprites + 32], 3)], 2))
    png.write_cells(path('bell.png'), 8, 2, sprites(mem, [(four(L.BellSprites), 2)], 4))
    fruit = [None] * 8
    for f, a in enumerate((L.FruitCellsA, L.FruitCellsB)):
        for k in range(4):
            cx, cy = 2 * f + (k & 1), k >> 1
            fruit[cy * 4 + cx] = (bytes(mem[a + 9 * k + 1:a + 9 * k + 9]), mem[a + 9 * k] & 7, False)
    png.write_cells(path('fruit.png'), 4, 2, fruit)
    white, black = (205, 205, 205), (0, 0, 0)
    rows = []
    for a in (L.TitleHungry, L.TitleHorace):
        for y in range(10):
            rows.append([black if mem[a + (y // 2) * 32 + x // 2] >> (4 if y % 2 == 0 else 0)
                         >> (x % 2) & 1 else white for x in range(64)])
    png.write(path('title.png'), 64, 20, rows)
    with open(path('mazes.txt'), 'w') as f:
        f.write('# The four mazes in play order, 24 rows of 32 cells. Tiles: %s.\n'
                '# wrap: the vertical wrap, as the original\'s screen-offset delta (hex);\n'
                '# bell, guards, horace: start cells (col,row) of the bell, the guards, Horace.\n'
                % ', '.join("%s %s" % (c, n) for c, n in zip(TILE_CHARS, (
                    'empty', 'wall', 'flower', 'exit arrow', 'wall', 'corner', 'corner', 'corner',
                    'corner', 'wrap pad'))))
        for n, m in enumerate(MAPS):
            dsc = L.MazeDescriptor + (n + 1) * L.MAZE_DESC_SIZE
            f.write('\nmaze %d wrap=%04X bell=%d,%d guards=%d,%d horace=%d,%d\n' % (
                (n + 1, word(dsc)) + pos(word(dsc + 2)) + pos(word(dsc + 4)) + pos(word(dsc + 6))))
            for r in range(24):
                f.write(''.join(TILE_CHARS[mem[m + 32 * r + c]] for c in range(32)) + '\n')

    def text(a):
        return ''.join('©' if b == 127 else chr(b) for b in mem[a:mem.index(L.TEXT_END, a)])
    json.dump({'title': text(L.TitleText), 'demo': text(L.DemoText), 'status': text(L.StatusText)},
              open(path('texts.json'), 'w'), ensure_ascii=False, indent=1)
    json.dump(to_json(decode(mem, 'title')), open(path('state.json'), 'w'))


if __name__ == '__main__':
    main()
