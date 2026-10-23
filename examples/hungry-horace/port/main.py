"""Ported from src/main.asm, as far as the spike goes: the title, the start of
a game or demo and the maze screen. The main loop is not ported yet."""
from labels import *  # noqa: F403  (first: port functions shadow routine labels)
from guards import LoadMazeDescriptor, PlayRisingTone, ResetGuardTimers
from library import DrawBlocks, DrawMaze, print_text
from zxpyxel import mem, zx

MAZE_MAPS = [Maze1Map, Maze2Map, Maze3Map, Maze4Map]


async def Start():
    """Seed the random pointer from FRAMES through the ROM, sound on, then the
    title, a game or the demo, and the maze screen."""
    zx.di()
    a = mem[FRAMES]
    a = mem[(a & ROM_HIGH_MASK) << 8 | a]
    zx.poke16(RandomPtr, (a & ROM_HIGH_MASK) << 8 | a)
    mem[SoundKeyState] = KEY_T_BIT
    mem[SoundMask] = ULA_OUT_MASK
    await ShowTitle()
    StartGame()
    NextMaze()
    zx.checkpoint('InitMaze')
    while True:                 # spike: MainLoop not ported
        await zx.halt()


async def ShowTitle():
    """Clear the screen, draw the title and cycle its colours, one rising tone
    per pass, until a key (GameActive = 1) or the countdown (demo)."""
    mem[ATTRS:ATTRS + ATTRS_SIZE] = bytes([WHITE * PAPER + WHITE]) * ATTRS_SIZE
    mem[SCREEN:SCREEN + SCREEN_SIZE] = bytes(SCREEN_SIZE)
    mem[ATTRS:ATTRS + ATTRS_SIZE] = bytes([WHITE * PAPER + BLACK]) * ATTRS_SIZE
    mem[GameActive] = 0
    zx.poke16(TitleCountdown, TITLE_PASSES)
    DrawBlocks(TitleHungry, SCREEN + 5 * SCREEN_COLS, 5 * SCREEN_COLS)
    DrawBlocks(TitleHorace, SCREEN + THIRD_SIZE + 4 * SCREEN_COLS, 5 * SCREEN_COLS)
    saved, mem[GameActive] = mem[GameActive], 1     # PrintChar draws only when 1
    print_text(TitleText, SCREEN + 2 * THIRD_SIZE + 6 * SCREEN_COLS)
    mem[GameActive] = saved
    while True:                 # TitleLoop
        for row in (5, 12):
            a = ATTRS + row * SCREEN_COLS
            ink = (mem[a] + 1) & WHITE * PAPER + WHITE | WHITE * PAPER
            mem[a:a + 5 * SCREEN_COLS] = bytes([ink]) * (5 * SCREEN_COLS)
        PlayRisingTone()
        await zx.sync()
        n = zx.peek16(TitleCountdown) - 1 & 0xFFFF
        zx.poke16(TitleCountdown, n)
        if n == 0:
            return              # demo
        if zx.inp(KB_ALL_ROWS << 8 | ULA_PORT) & KEY_BITS != KEY_BITS:
            mem[GameActive] = 1
            return


def StartGame():
    """No maze yet, slowest pace, three passes, score 0, no guards released."""
    mem[MazeNumber] = MAZE_NONE
    mem[GuardInterval] = START_GUARD_INTERVAL
    mem[Passes] = START_PASSES
    zx.poke16(Score, 0)
    mem[GuardsReleased] = 0
    mem[ExtraPassMark] = 0
    ResetGuardTimers()


def NextMaze():
    """Speed up after every fourth maze, load the next maze's descriptor and
    draw it with the status line or the demo banner."""
    if mem[MazeNumber] + 1 & 0xFF - MAZE_MASK:
        mem[GuardInterval] = mem[GuardInterval] - 1 & 0xFF or MIN_GUARD_INTERVAL
    n = mem[MazeNumber] + 1 & MAZE_MASK                       # AdvanceMaze
    mem[MazeNumber] = n
    LoadMazeDescriptor(MazeDescriptor + (n + 1) * MAZE_DESC_SIZE)   # SelectMaze
    DrawMaze(MAZE_MAPS[n], SCREEN, SCREEN_COLS * SCREEN_ROWS)
    ShowTopRow()


def ShowTopRow():
    """The status line in a game; in the demo the banner, its first
    DEMO_BANNER_LEN cells flashing."""
    if mem[GameActive]:
        print_text(StatusText, SCREEN)
        return
    mem[GameActive] = 1
    print_text(DemoText, SCREEN)
    mem[GameActive] = 0
    for a in range(ATTRS, ATTRS + DEMO_BANNER_LEN):
        mem[a] = mem[a] + FLASH & 0xFF
