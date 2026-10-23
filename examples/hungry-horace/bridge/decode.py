"""Stage 3 memory -> the stage 4 state (game/horace/state.py). A screen offset
becomes (col, row); the guard records, timers and variables become fields;
the screen becomes the grid of cells. Scratch memory (the guard working
buffer, the AI's score table and cells, UnusedAiCounter) is left out."""
import paths  # noqa: F401
import labels as L
from horace.state import Cell, GameState, Guard, Horace
from variables import Data

FRAMES = 0x5C78
RECORD = 43


def pos(offset):
    """(col, row) of the top-left cell at a screen offset."""
    return offset & 31, (offset >> 8 & 0x18) | (offset >> 5 & 7)


def cell(mem, col, row):
    a = 0x4000 | (row & 0x18) << 8 | (row & 7) << 5 | col
    return Cell(bytes(mem[a + 256 * line] for line in range(8)), mem[0x5800 + row * 32 + col])


def saved(mem, a):
    return [Cell(bytes(mem[a + 9 * i + 1:a + 9 * i + 9]), mem[a + 9 * i]) for i in range(4)]


def decode(mem, mode):
    v = Data(mem)
    w = v.mem16
    guards = [Guard(pos=pos(w[r]), new_pos=pos(w[r + 4]), dir=mem[r + 2], anim=mem[r + 3],
                    wait=mem[r + 6], timer=w[L.GuardTimers + 2 * k], saved=saved(mem, r + 7))
              for k, r in enumerate(range(L.GuardRecords, L.GuardRecords + 4 * RECORD, RECORD))]
    horace = Horace(pos=pos(v.HoracePos), next_pos=pos(v.HoraceNextPos), dir=v.HoraceDir,
                    requested=v.RequestedDir, attr=v.HoraceAttr, anim=v.HoraceAnim,
                    wrap_pause=v.WrapPause)
    return GameState(
        mode=mode, playing=bool(v.GameActive), title_countdown=v.TitleCountdown,
        maze=v.MazeNumber, pace=v.GuardInterval, step_countdown=v.StepCountdown,
        score=v.Score, best=v.BestScore, passes=v.Passes, extra_pass_mark=v.ExtraPassMark,
        guards_released=v.GuardsReleased, bell=pos(v.BellPos) if v.BellPos else None,
        bell_tick=v.BellTick, bell_timer=v.BellTimer, fruit_timer=v.FruitTimer,
        random=v.RandomPtr, frames=w[FRAMES] | mem[FRAMES + 2] << 16,
        sound_on=v.SoundMask == L.ULA_OUT_MASK, t_held=v.SoundKeyState == 0,
        horace=horace, guards=guards,
        cells=[cell(mem, c, r) for r in range(24) for c in range(32)])
