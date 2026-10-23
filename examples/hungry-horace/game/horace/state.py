"""The state of Hungry Horace as plain values (docs/stage4.md in zx-reaper).

The game's world is its screen: walls, flowers, the bell, fruit, Horace and
the guards are told apart by the colour of the cells they cover, and each
guard keeps the cells under it. So the state holds the 32x24 grid of cells
(an 8x8 glyph and an attribute each) next to the figures and counters.
Positions are (col, row) of a figure's top-left cell; a figure covers 2x2
cells. Nothing here is a Spectrum address.
"""
from dataclasses import asdict, dataclass, field

from .constants import ATTR_BLANK, ATTR_HORACE, COLS, DIR_NONE, DIR_RIGHT, ROWS

BLANK = bytes(8)


@dataclass
class Cell:
    glyph: bytes = BLANK        # 8 bytes, top row first, bit 7 the leftmost pixel
    attr: int = ATTR_BLANK      # flash << 7 | bright << 6 | paper << 3 | ink


@dataclass
class Horace:
    pos: tuple = (0, 0)
    next_pos: tuple = (0, 0)    # where he is drawn in this pass
    dir: int = DIR_RIGHT
    requested: int = DIR_NONE   # the direction the keys asked for
    attr: int = ATTR_HORACE     # cycled by the death animation
    anim: int = 0               # +1 per draw; bit 4 picks the walking frame
    wrap_pause: int = 0         # passes left frozen and invisible after a wrap pad


@dataclass
class Guard:
    pos: tuple = (0, 0)
    new_pos: tuple = (0, 0)     # planned by the AI, made current when drawn
    dir: int = 0
    anim: int = 0               # +1 per draw; bit 5 walking frame, bit 3 scared frame
    wait: int = 0               # passes an eaten guard waits before it moves again
    timer: int = 0              # passes until it is released; 0 = in the maze
    saved: list = field(default_factory=lambda: [Cell() for _ in range(4)])
    #                             the cells under it: top-left, top-right, bottom-left, bottom-right


@dataclass
class GameState:
    mode: str = 'title'         # 'title' or 'play' (a game or the demo)
    playing: bool = False       # a real game (the status line is printed); False: title or demo
    title_countdown: int = 0    # title passes left before the demo starts
    maze: int = 0               # 0-3, MAZE_NONE before the first
    pace: int = 0               # passes per movement step, 8 ... 1 (GuardInterval)
    step_countdown: int = 0     # passes until the next movement step
    score: int = 0
    best: int = 0
    passes: int = 0             # lives
    extra_pass_mark: int = 0    # score // 10000 + 2 when the score was last shown
    guards_released: int = 0    # counts the wrong thing (findings F10): it slows the delay
    bell: tuple = None          # the bell's position, None when there is none
    bell_tick: int = 0          # bell animation, also times the chime
    bell_timer: int = 0         # the guards are scared while it runs
    fruit_timer: int = 0
    random: int = 0             # GetRandom's pointer into the ROM (0-$1FFF)
    frames: int = 0             # FRAMES: the guards' random pointer, also an interrupt counter
    sound_on: bool = True
    t_held: bool = False        # the T key at the last pass (sound toggles on a press)
    horace: Horace = field(default_factory=Horace)
    guards: list = field(default_factory=lambda: [Guard() for _ in range(4)])
    cells: list = field(default_factory=lambda: [Cell() for _ in range(COLS * ROWS)])

    def cell(self, col, row):
        return self.cells[row * COLS + col]


@dataclass
class Actions:
    """What the player did in one step, as the original read it."""
    any_key: bool = False       # title and demo: any key at all
    direction: int = DIR_NONE   # game: the first direction key held (up, down, right, left)
    t: bool = False             # T held when the pass ends (the sound toggle)
    interrupts: int = 0         # interrupts the Spectrum took in the step (rare: after the chime)


@dataclass
class Sound:
    """A sound effect started in a step; `data` for the synthesiser (pitches,
    the noise's random lengths)."""
    name: str
    data: tuple = ()


@dataclass
class Show:
    """Present the state as it is now for `seconds` (an animation frame, a
    blocking sound, the rest of a pass)."""
    seconds: float


def to_json(s):
    """The state as JSON values: glyphs as hex, positions as lists."""
    def plain(x):
        if isinstance(x, bytes):
            return x.hex()
        if isinstance(x, dict):
            return {k: plain(v) for k, v in x.items()}
        if isinstance(x, (list, tuple)):
            return [plain(v) for v in x]
        return x
    return plain(asdict(s))


def from_json(d):
    def cell(c):
        return Cell(bytes.fromhex(c['glyph']), c['attr'])

    def pos(p):
        return None if p is None else tuple(p)
    h = dict(d['horace'], pos=pos(d['horace']['pos']), next_pos=pos(d['horace']['next_pos']))
    guards = [Guard(**dict(g, pos=pos(g['pos']), new_pos=pos(g['new_pos']),
                           saved=[cell(c) for c in g['saved']])) for g in d['guards']]
    return GameState(**dict(d, bell=pos(d['bell']), horace=Horace(**h), guards=guards,
                            cells=[cell(c) for c in d['cells']]))
