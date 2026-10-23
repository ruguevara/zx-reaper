"""The flow of the game (stage 3: main.py): start, the title, a game or the
demo, the mazes and the main loop.

Game.step(actions) is one step: a pass of the title loop or of the main
loop, and whatever follows it up to the next one (a new maze, a lost pass,
the game over and the title). It is a generator of events (Sound, Show);
the routines return where the original jumps next ('NextMaze',
'RestartMaze', 'GameOver', 'ShowTitle', 'StartGame'), and the step goes on
there.
"""
import copy
import inspect

from . import assets as A
from . import events, movement, sprites, world
from .constants import (ATTR_ARROW, ATTR_HORACE, ATTR_PAD, ATTR_TEXT, ATTR_WALL, CHAR_0, COLS,
                        DEMO_BANNER_LEN, DIR_RIGHT, FLASH, FRUIT_FIRST_DELAY, GREEN, MAZE_MASK,
                        MAZE_NONE, MIN_GUARD_INTERVAL, PAPER, ROM_HIGH_MASK, START_GUARD_INTERVAL,
                        START_PASSES, STATUS_BEST_COL, STATUS_PASSES_COL, TILE_ARROW,
                        TILE_BLANK_WHITE, TILE_EMPTY, TILE_FLOWER, TITLE_PASSES, WHITE, YELLOW)
from .state import BLANK, Cell, Show, Sound

TILE_ATTRS = {TILE_EMPTY: WHITE * PAPER + YELLOW, TILE_FLOWER: WHITE * PAPER + GREEN,
              TILE_ARROW: ATTR_ARROW, TILE_BLANK_WHITE: ATTR_PAD}       # any other tile: a wall
HALVES = [0x00, 0xF0, 0x0F, 0xFF]       # two block bits -> a pixel row of the title letters
TITLE_PASS_SECONDS = 0.08               # the rising tone that paces the title loop


class Game:
    def __init__(self):
        if not A.ROM:
            A.load()
        self.state = copy.deepcopy(A.INITIAL)
        start(self.state)

    def step(self, a):
        s = self.state
        target = yield from (title_pass(s, a) if s.mode == 'title' else main_pass(s, a))
        while target:
            r = FLOW[target](s)
            target = (yield from r) if inspect.isgenerator(r) else r
        s.frames = s.frames + a.interrupts & 0xFFFFFF   # the ROM's interrupt counts FRAMES


def start(s):
    """Seed the random pointer from FRAMES through the ROM, sound on, the
    title (stage 3: Start)."""
    f = s.frames & 0xFF
    r = A.ROM[(f & ROM_HIGH_MASK) << 8 | f]
    s.random = (r & ROM_HIGH_MASK) << 8 | r
    s.t_held = False
    s.sound_on = True
    show_title(s)


def show_title(s):
    """Clear the screen, the title words and texts, the countdown (stage 3: ShowTitle)."""
    s.cells = [Cell(BLANK, ATTR_TEXT) for _ in s.cells]
    s.playing = False
    s.title_countdown = TITLE_PASSES
    for word, row in zip(A.TITLE_WORDS, (5, 12)):
        for k, b in enumerate(word):            # DrawBlocks: bitmap only
            top, bottom = HALVES[b >> 4 & 3], HALVES[b & 3]
            s.cells[row * COLS + k].glyph = bytes([top] * 4 + [bottom] * 4)
    world.print_text(s, (0, 22), A.TEXTS['title'], always=True)
    s.mode = 'title'


def title_pass(s, a):
    """One pass of the title loop: the words change ink, the rising tone, the
    countdown; when it runs out the demo, on a key a game (stage 3: TitleLoop)."""
    for row in (5, 12):
        ink = (s.cells[row * COLS].attr + 1) & 0x3F | WHITE * PAPER
        for c in s.cells[row * COLS:(row + 5) * COLS]:
            c.attr = ink
    if s.sound_on:
        yield Sound('rising')
    yield Show(TITLE_PASS_SECONDS)
    s.title_countdown = s.title_countdown - 1 & 0xFFFF
    if s.title_countdown == 0:
        return 'StartGame'          # the demo
    if a.any_key:
        s.playing = True
        return 'StartGame'
    return None


def start_game(s):
    """No maze yet, the slowest pace, three passes, score 0 (stage 3: StartGame)."""
    s.maze = MAZE_NONE
    s.pace = START_GUARD_INTERVAL
    s.passes = START_PASSES
    s.score = 0
    s.guards_released = 0
    s.extra_pass_mark = 0
    events.reset_guard_timers(s)
    return 'NextMaze'


def next_maze(s):
    """Faster after every fourth maze; the next maze drawn with the status
    line or the demo banner, set up and restarted (stage 3: NextMaze, InitMaze)."""
    if s.maze + 1 & 0xFF & ~MAZE_MASK:
        s.pace = s.pace - 1 & 0xFF or MIN_GUARD_INTERVAL
    s.maze = s.maze + 1 & MAZE_MASK
    for i, code in enumerate(A.MAZES[s.maze].map):
        s.cells[i] = Cell(A.TILES[code], TILE_ATTRS.get(code, ATTR_WALL))
    show_top_row(s)
    s.bell = A.MAZES[s.maze].bell                                     # InitMaze
    world.print_text(s, (STATUS_PASSES_COL, 0), [s.passes + CHAR_0 & 0xFF])
    s.fruit_timer = FRUIT_FIRST_DELAY
    return 'RestartMaze'


def show_top_row(s):
    """The status line in a game; in the demo the banner, its first cells flashing."""
    if s.playing:
        world.print_text(s, (0, 0), A.TEXTS['status'])
        return
    world.print_text(s, (0, 0), A.TEXTS['demo'], always=True)
    for c in s.cells[:DEMO_BANNER_LEN]:
        c.attr = c.attr + FLASH & 0xFF


def restart_maze(s):
    """The bell back at its start if it is still there, the guards and Horace
    at theirs, the score and the best score shown; then the main loop
    (stage 3: RestartMaze, PlaceGuards, PlaceHorace)."""
    maze = A.MAZES[s.maze]
    if s.bell:
        s.bell = maze.bell
    for g in s.guards:                  # waiting guards stand at Horace's start
        g.pos = g.new_pos = maze.horace_start if g.timer else maze.guard_start
        g.saved = [Cell() for _ in range(4)]
    h = s.horace
    h.pos = h.next_pos = maze.horace_start
    h.dir = DIR_RIGHT
    s.step_countdown = s.pace
    yield from sprites.show_score(s, s.score)
    world.print_number(s, STATUS_BEST_COL, s.best)
    s.bell_timer = 0
    h.attr = ATTR_HORACE
    s.mode = 'play'
    return None


def main_pass(s, a):
    """One pass of the main loop (stage 3: MainLoop)."""
    target = movement.read_controls(s, a)
    if target:
        return target
    target = yield from movement.plan_moves(s)
    if target:
        return target
    sprites.erase_sprites(s)
    yield from sprites.eat_object(s)
    sprites.draw_guards(s)
    target = yield from events.check_guard_contact(s)
    if target:
        return target
    events.draw_horace(s)
    yield from events.update_bell(s)
    events.update_fruit_drops(s)
    events.tick_guard_timers(s)
    events.check_sound_key(s, a)
    yield from events.pace_and_chime(s)
    return None


FLOW = {'StartGame': start_game, 'NextMaze': next_maze, 'RestartMaze': restart_maze,
        'GameOver': lambda s: events.game_over(s), 'ShowTitle': show_title}
