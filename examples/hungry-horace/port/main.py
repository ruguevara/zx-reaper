"""Ported from src/main.asm: the title, the start of a game or demo, the maze
set-up and the main loop. The asm's fall-through from label to label is a
chain of calls (ShowTitle → StartGame → NextMaze → RestartMaze → MainLoop);
the jumps back into it that drop return addresses (ExitMaze, HoraceDies,
GameOver) raise Goto, and Start's dispatch goes on at the target."""
from labels import *  # noqa: F403  (first: port functions shadow routine labels)
from events import (CheckGuardContact, DrawHorace, PaceAndChime, TickGuardTimers,
                    UpdateBell, UpdateFruitDrops, CheckSoundKey)
from guards import (LoadGuardRecord, LoadMazeDescriptor, PlayRisingTone, ResetGuardTimers,
                    SaveGuardRecord)
from library import DrawBlocks, DrawMaze, PrintChar, PrintNumber, SetAttrPointer, print_text
from movement import PlanMoves, ReadControls
from sprites import DrawGuards, EatObject, EraseSprites, ShowScore
from variables import v
from zxpyxel import dispatch, mem, mem16, zx

MAZE_MAPS = [Maze1Map, Maze2Map, Maze3Map, Maze4Map]


async def Start():
    """Seed the random pointer from FRAMES through the ROM, sound on, then the
    title screen and everything after it."""
    zx.di()
    a = mem[FRAMES]
    a = mem[(a & ROM_HIGH_MASK) << 8 | a]
    v.RandomPtr = (a & ROM_HIGH_MASK) << 8 | a
    v.SoundKeyState = KEY_T_BIT
    v.SoundMask = ULA_OUT_MASK
    await dispatch(ShowTitle)


async def ShowTitle():
    """Clear the screen, draw the title and cycle its colours, one rising tone
    per pass, until a key (GameActive = 1) or the countdown (demo)."""
    mem[ATTRS:ATTRS + ATTRS_SIZE] = bytes([WHITE * PAPER + WHITE]) * ATTRS_SIZE
    mem[SCREEN:SCREEN + SCREEN_SIZE] = bytes(SCREEN_SIZE)
    mem[ATTRS:ATTRS + ATTRS_SIZE] = bytes([WHITE * PAPER + BLACK]) * ATTRS_SIZE
    v.GameActive = 0
    v.TitleCountdown = TITLE_PASSES
    DrawBlocks(TitleHungry, SCREEN + 5 * SCREEN_COLS, 5 * SCREEN_COLS)
    DrawBlocks(TitleHorace, SCREEN + THIRD_SIZE + 4 * SCREEN_COLS, 5 * SCREEN_COLS)
    saved, v.GameActive = v.GameActive, 1           # PrintChar draws only when 1
    print_text(TitleText, SCREEN + 2 * THIRD_SIZE + 6 * SCREEN_COLS)
    v.GameActive = saved
    while True:                 # TitleLoop
        for row in (5, 12):
            a = ATTRS + row * SCREEN_COLS
            ink = (mem[a] + 1) & WHITE * PAPER + WHITE | WHITE * PAPER
            mem[a:a + 5 * SCREEN_COLS] = bytes([ink]) * (5 * SCREEN_COLS)
        PlayRisingTone()
        await zx.sync()
        v.TitleCountdown -= 1
        if v.TitleCountdown == 0:
            break               # demo
        if zx.inp(KB_ALL_ROWS << 8 | ULA_PORT) & KEY_BITS != KEY_BITS:
            v.GameActive = 1
            break
    await StartGame()


async def StartGame():
    """No maze yet, slowest pace, three passes, score 0, no guards released."""
    v.MazeNumber = MAZE_NONE
    v.GuardInterval = START_GUARD_INTERVAL
    v.Passes = START_PASSES
    v.Score = 0
    v.GuardsReleased = 0
    v.ExtraPassMark = 0
    ResetGuardTimers()
    await NextMaze()


async def NextMaze():
    """Speed up after every fourth maze, load the next maze's descriptor, draw
    it with the status line or the demo banner, and set it up."""
    if v.MazeNumber + 1 & 0xFF - MAZE_MASK:
        v.GuardInterval = v.GuardInterval - 1 & 0xFF or MIN_GUARD_INTERVAL
    n = v.MazeNumber + 1 & MAZE_MASK                          # AdvanceMaze
    v.MazeNumber = n
    LoadMazeDescriptor(MazeDescriptor + (n + 1) * MAZE_DESC_SIZE)   # SelectMaze
    DrawMaze(MAZE_MAPS[n], SCREEN, SCREEN_COLS * SCREEN_ROWS)
    ShowTopRow()
    InitMaze()
    await RestartMaze()


def ShowTopRow():
    """The status line in a game; in the demo the banner, its first
    DEMO_BANNER_LEN cells flashing."""
    if v.GameActive:
        print_text(StatusText, SCREEN)
        return
    v.GameActive = 1
    print_text(DemoText, SCREEN)
    v.GameActive = 0
    for a in range(ATTRS, ATTRS + DEMO_BANNER_LEN):
        mem[a] += FLASH


def InitMaze():
    """The bell at its start, the passes digit printed, the fruit timer armed."""
    v.BellPos = v.MazeBellStart
    PrintChar(v.Passes + CHAR_0, SCREEN + STATUS_PASSES_COL,
              SetAttrPointer(SCREEN + STATUS_PASSES_COL))
    v.FruitTimer = FRUIT_FIRST_DELAY


async def RestartMaze():
    """Bell back at its start if still in the maze, guards and Horace at their
    starting places, score and best score shown, bell timer off; then the
    main loop. Also the entry after a lost pass in a game."""
    if v.BellPos:
        v.BellPos = v.MazeBellStart
    PlaceGuards()
    v.HoracePos = v.HoraceNextPos = v.MazeHoraceStart          # PlaceHorace
    v.HoraceDir = DIR_RIGHT
    v.StepCountdown = v.GuardInterval
    ShowScore(v.Score)
    PrintNumber(SCREEN + STATUS_BEST_COL, v.BestScore)
    v.BellTimer = 0
    v.HoraceAttr = ATTR_HORACE
    await MainLoop()


def PlaceGuards():
    """Each guard (B = 4 for the first record down to 1) at the guards' start
    when its release timer is zero, else at Horace's start, where it waits;
    its saved background four blank cells."""
    for b in range(GUARD_COUNT, 0, -1):
        LoadGuardRecord(b)
        waiting = mem16[BellTimer - 2 * b]          # the timer of this guard
        v.GuardRecord = v.GuardNewPos = v.MazeHoraceStart if waiting else v.MazeGuardStart
        for c in range(0, len(v.SavedBackground), CELL_BYTES + 1):
            v.SavedBackground[c] = ATTR_BLANK
            for r in range(1, CELL_BYTES + 1):
                v.SavedBackground[c + r] = 0
        SaveGuardRecord()


async def MainLoop():
    """One pass per iteration; left only by Goto (ExitMaze, HoraceDies, the
    demo abort in ReadControls)."""
    while True:
        zx.checkpoint('MainLoop')
        ReadControls()
        await PlanMoves()
        EraseSprites()
        EatObject()
        DrawGuards()
        await CheckGuardContact()
        DrawHorace()
        UpdateBell()
        UpdateFruitDrops()
        TickGuardTimers()
        CheckSoundKey()
        await PaceAndChime()
