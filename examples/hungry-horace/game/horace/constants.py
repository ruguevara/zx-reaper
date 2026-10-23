"""The rules' numbers, from src/constants.asm (names kept, so the asm and
the stage 3 port can be read side by side). Nothing here is an address."""

COLS, ROWS = 32, 24             # the screen in character cells

# colours, attributes (ink on white paper, the ink says what a cell is)
BLACK, BLUE, RED, MAGENTA, GREEN, CYAN, YELLOW, WHITE = range(8)
PAPER, FLASH = 8, 0x80
ATTR_ARROW = 0x38               # exit arrows; also the status line and title text
ATTR_HORACE = 0x39
ATTR_BELL = 0x3A                # bell; also the lower half of a fruit
ATTR_GUARD = 0x3B
ATTR_FLOWER = 0x3C              # flower; also the upper half of a fruit
ATTR_WALL = 0x3D
ATTR_BLANK = 0x3E               # empty floor
ATTR_PAD = 0x3F                 # wrap pad, white on white
ATTR_TEXT = WHITE * PAPER + BLACK
INK_MASK = 7

# directions
DIR_UP, DIR_RIGHT, DIR_DOWN, DIR_LEFT = range(4)
DIR_NONE = 0xFF
DIR_COUNT, DIR_MASK, DIR_OPPOSITE = 4, 3, 2

# what is one step ahead (ProbeMove)
MOVE_FREE, MOVE_WRAP, MOVE_EXIT, MOVE_BLOCKED = range(4)
PROBE_BLOCKED, PROBE_ARROW_WEIGHT, PROBE_MANY_BITS = 0xFF, 4, 0x0A

# maze tiles (map codes)
TILE_EMPTY, TILE_FLOWER, TILE_ARROW, TILE_BLANK_WHITE = 0, 2, 3, 9

# game start and pace
START_PASSES = 3
START_GUARD_INTERVAL = 8        # the pace: passes per movement step, 8 slow ... 1 fast
MIN_GUARD_INTERVAL = 1
MAZE_NONE, MAZE_MASK = 0xFF, 3
TITLE_PASSES = 140
GUARD_COUNT = 4
GUARD_WAIT = 0x5A               # passes an eaten guard waits
WRAP_PAUSE = 0x5A               # passes Horace is frozen after a wrap pad
FRUIT_FIRST_DELAY = 2000
FRUIT_MIN_DELAY, FRUIT_DELAY_MASK = 0x0320, 0x03
SPEED_DELAY_BASE, SPEED_DELAY_STEP = 0x015E, 0x1E

# scores
SCORE_FLOWER = 10
SCORE_ITEM = 50                 # anything else eaten: the bell's or a fruit's cells
SCORE_GUARD = 100
SCORE_BELL_PICKUP, SCORE_BELL_BONUS = 60, 150
EXTRA_PASS_SCORE = 10000

# guard AI
AI_BASE_SCORE = 0x19
AI_STRAIGHT_BONUS = 0x28
AI_REVERSE_PENALTY = 10
AI_RANDOM_MASK = 0x1F
AI_CHASE_BIAS = 10
RANDOM_ROM_HIGH_MASK = 0x0F     # the AI's random pointer stays in the first 4K of the ROM
ROM_HIGH_MASK = 0x1F            # GetRandom's pointer stays in the first 8K

# animation
HORACE_FRAME_BIT = 0x10
GUARD_WALK_FRAME_BIT = 0x20
GUARD_SCARED_FRAME_BIT = 8
BELL_FRAME_BITS, BELL_MIRROR_LIMIT = 0x38, 0x1F
BELL_PHASE_MASK, BELL_HALF_PHASE = 0x3F, 0x20
DEATH_FLASHES = 45
DEATH_NOISE_CYCLES = 20
NOISE_MIN_DELAY = 0x40
PASSES_LABEL_CELLS = 9
GAME_OVER_FLASHES = 20
DEMO_BANNER_LEN = 9

# status line columns (row 0)
STATUS_PASSES_COL, STATUS_SCORE_COL, STATUS_BEST_COL = 7, 15, 26
CHAR_0 = 0x30

# sound (the shapes of the original's beeper loops, for zxpyxel.sound)
SWEEP_STEPS, SWEEP_CYCLES = 16, 10      # the rising tone
WRAP_TONE_CYCLES = 8
EAT_TONE_STEPS = 16                     # the chirp
EATEN_TONE_STEPS, EATEN_TONE_CYCLES = 15, 8
CHIME_LOW_LEN, CHIME_LOW_PITCH = 0x16, 0x0193
CHIME_HIGH_LEN, CHIME_HIGH_PITCH = 0x1A, 0x0168

PASS_T = 21000                  # T-states of a main-loop pass besides its delay (stage 3 measure; pacing only)
