"""The game's data, from the editable files in game/assets/ (made from the
original by bridge/assets.py; game data, never committed), checked as they
load: the PNG sizes and colours (one ink per 8x8 cell on white paper, as on
the Spectrum), the mazes' text. The font and the random numbers are the
ROM's, which zxpyxel ships. load() fills the names below once; the rules read
them as constants."""
import json
import os
from dataclasses import dataclass

from zxpyxel import png
from zxpyxel.machine import ROM as ROM48

from .constants import COLS, PAPER, ROWS, WHITE
from .state import Cell, from_json

TILE_CHARS = '.-*>|F7LJo'   # tile codes 0-9 in mazes.txt: empty, walls, flower, arrow, corners, pad

ROM = b''          # the first 8K of the ROM: the random numbers
FONT = []          # 96 glyphs of 8 bytes, characters 32-127 (127: the copyright sign)
TILES = []         # 10 glyphs, by map code (tiles.png; the game colours them)
HORACE = []        # [frame][direction] 32 bytes: frame 0 when bit 4 of his counter is set
GUARD = []         # [frame][direction]: frame 0 when bit 5 of the guard's counter is set
SCARED = []        # 2 frames, any direction: bit 3 of the counter picks
BELL = []          # 4 frames of the swinging bell
BLANK = bytes(32)
FRUIT = []         # 2 fruits, 4 cells each (top-left, top-right, bottom-left, bottom-right)
TITLE_WORDS = []   # HUNGRY and HORACE, 32x5 cells, one block byte a cell
TEXTS = {}         # 'title', 'demo', 'status': character codes
MAZES = []         # in play order
INITIAL = None     # the state as loaded, before the game starts


@dataclass
class Maze:
    map: list               # 768 tile codes, row by row
    wrap: int               # the vertical wrap, as the original's screen-offset delta (world.wrap_jump)
    bell: tuple
    guard_start: tuple
    horace_start: tuple     # also where waiting and eaten guards stand


def sprites(path, cols, rows):
    """A sheet of 16x16 sprites -> rows of 32-byte sprites (cells TL, TR, BL, BR)."""
    cells = png.cells(path, 2 * cols, 2 * rows)
    return [[b''.join(cells[(2 * sy + k // 2) * 2 * cols + 2 * sx + k % 2][0] for k in range(4))
             for sx in range(cols)] for sy in range(rows)]


def blocks(path):
    """title.png: one pixel a 4x4 block, 64x10 per word -> 160 block bytes per
    word (bits 4, 5: the top blocks, 0, 1: the bottom ones)."""
    w, h, px = png.read(path)
    if (w, h) != (64, 20):
        raise ValueError('%s: 64x20 pixels expected (two words of 64x10 blocks), the image is %dx%d'
                         % (path, w, h))
    on = []
    for y, row in enumerate(px):
        for x, rgb in enumerate(row):
            c = png.COLOURS.get(rgb)
            if c is None:
                raise ValueError('%s: pixel %d,%d is not a Spectrum colour' % (path, x, y))
        on.append([png.COLOURS[rgb][0] != WHITE for rgb in row])
    return [[on[10 * w + 2 * cy][2 * cx] << 4 | on[10 * w + 2 * cy][2 * cx + 1] << 5
             | on[10 * w + 2 * cy + 1][2 * cx] | on[10 * w + 2 * cy + 1][2 * cx + 1] << 1
             for cy in range(5) for cx in range(32)] for w in range(2)]


def mazes(path):
    lines = [l.rstrip('\n') for l in open(path, encoding='utf-8')]
    out, i = [], 0
    while i < len(lines):
        if not lines[i].startswith('maze '):
            i += 1
            continue
        head = dict(f.split('=') for f in lines[i].split()[2:])
        pos = lambda k: tuple(int(v) for v in head[k].split(','))     # noqa: E731
        rows = lines[i + 1:i + 1 + ROWS]
        for r, row in enumerate(rows):
            bad = [c for c in row if c not in TILE_CHARS]
            if len(row) != COLS or bad:
                raise ValueError('%s line %d: %d cells of %s expected, got %r'
                                 % (path, i + 2 + r, COLS, TILE_CHARS, row))
        if len(rows) != ROWS:
            raise ValueError('%s: maze at line %d has %d rows, %d expected' % (path, i + 1, len(rows), ROWS))
        out.append(Maze([TILE_CHARS.index(c) for row in rows for c in row], int(head['wrap'], 16),
                        pos('bell'), pos('guards'), pos('horace')))
        i += 1 + ROWS
    if len(out) != 4:
        raise ValueError('%s: 4 mazes expected, found %d' % (path, len(out)))
    return out


def load(d=os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'assets')):
    global ROM, FONT, TILES, HORACE, GUARD, SCARED, BELL, FRUIT, TITLE_WORDS, TEXTS, MAZES, INITIAL

    def p(name):
        return os.path.join(d, name)
    ROM = ROM48[:0x2000]
    FONT = [ROM48[0x3D00 + 8 * i:0x3D08 + 8 * i] for i in range(96)]
    TILES = [g for g, ink, bright in png.cells(p('tiles.png'), 10, 1)]
    HORACE, GUARD = sprites(p('horace.png'), 4, 2), sprites(p('guard.png'), 4, 2)
    SCARED, BELL = sprites(p('scared.png'), 2, 1)[0], sprites(p('bell.png'), 4, 1)[0]
    cells = png.cells(p('fruit.png'), 4, 2)
    FRUIT = [[Cell(g, WHITE * PAPER + ink + (0x40 if bright else 0))
              for g, ink, bright in (cells[(k // 2) * 4 + 2 * f + k % 2] for k in range(4))]
             for f in range(2)]
    TITLE_WORDS = blocks(p('title.png'))
    TEXTS = {k: [127 if ch == '©' else ord(ch) for ch in v]
             for k, v in json.load(open(p('texts.json'), encoding='utf-8')).items()}
    MAZES = mazes(p('mazes.txt'))
    INITIAL = from_json(json.load(open(p('state.json'))))
