"""The game's data, from game/assets.json (made from the original by
bridge/assets.py; game data, never committed): graphics as bytes, the mazes,
the texts, the ROM bytes the game uses as random numbers. load() fills the
names below once; the rules read them as constants."""
import json
import os
from dataclasses import dataclass

from .state import Cell, from_json

ROM = b''          # the first 8K of the ROM: the random numbers
FONT = []          # 96 glyphs of 8 bytes, characters 32-127 (127: the copyright sign)
TILES = []         # 10 glyphs, by map code
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


def load(path=os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                           'assets.json')):
    global ROM, FONT, TILES, HORACE, GUARD, SCARED, BELL, FRUIT, TITLE_WORDS, TEXTS, MAZES, INITIAL
    d = json.load(open(path))
    hexes = lambda xs: [bytes.fromhex(x) for x in xs]       # noqa: E731
    ROM = bytes.fromhex(d['rom'])
    FONT, TILES = hexes(d['font']), hexes(d['tiles'])
    HORACE, GUARD = [hexes(f) for f in d['horace']], [hexes(f) for f in d['guard']]
    SCARED, BELL = hexes(d['scared']), hexes(d['bell'])
    FRUIT = [[Cell(bytes.fromhex(g), a) for a, g in fruit] for fruit in d['fruit']]
    TITLE_WORDS, TEXTS = d['title_words'], d['texts']
    MAZES = [Maze(m['map'], m['wrap'], tuple(m['bell']), tuple(m['guard_start']),
                  tuple(m['horace_start'])) for m in d['mazes']]
    INITIAL = from_json(d['initial'])
