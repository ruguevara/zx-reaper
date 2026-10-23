"""Ported from src/guards.asm: the routines the title and the maze set-up use."""
from labels import *  # noqa: F403
from zxpyxel import djnz_t, mem, zx


def ResetGuardTimers():
    """No guard released; release waits 0, 1, 2 and 4 guard intervals (x256)."""
    mem[GuardsReleased] = 0
    h = mem[GuardInterval]
    zx.poke16(GuardTimers, 0)
    zx.poke16(GuardTimers + 2, h << 8)
    zx.poke16(GuardTimers + 4, (h << 1 & 0xFF) << 8)
    zx.poke16(GuardTimers + 6, (h << 2 & 0xFF) << 8)


def PlayRisingTone():
    """SWEEP_STEPS pitch steps of SWEEP_CYCLES square-wave cycles, half period
    8*C DJNZ passes for C counting down (the pitch rises); white border."""
    for c in range(SWEEP_STEPS, 0, -1):
        d = c << 3 & 0xFF
        # 33: the other instructions of a half period, averaged over both halves
        zx.tone(djnz_t(d) + 33, SWEEP_CYCLES, ULA_OUT_MASK & mem[SoundMask], WHITE)


def LoadMazeDescriptor(hl):
    """Copy the 8-byte descriptor at HL to MazeDescriptor."""
    mem[MazeDescriptor:MazeDescriptor + MAZE_DESC_SIZE] = mem[hl:hl + MAZE_DESC_SIZE]
