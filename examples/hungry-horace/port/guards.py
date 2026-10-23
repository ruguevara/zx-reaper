"""Ported from src/guards.asm: the routines the title and the maze set-up use."""
from labels import *  # noqa: F403
from variables import v
from zxpyxel import djnz_t, mem, zx


def ResetGuardTimers():
    """No guard released; release waits 0, 1, 2 and 4 guard intervals (x256). Returns nothing."""
    zx.spend(127)
    v.GuardsReleased = 0
    h = v.GuardInterval
    v.GuardTimers = 0                   # the first guard's timer
    v.Guard2Timer = h << 8
    v.Guard3Timer = (h << 1 & 0xFF) << 8
    v.Guard4Timer = (h << 2 & 0xFF) << 8


def PlayRisingTone():
    """SWEEP_STEPS pitch steps of SWEEP_CYCLES square-wave cycles, half period
    8*C DJNZ passes for C counting down (the pitch rises); white border."""
    for c in range(SWEEP_STEPS, 0, -1):
        d = c << 3 & 0xFF
        # 33: the other instructions of a half period, averaged over both halves
        zx.tone(djnz_t(d) + 33, SWEEP_CYCLES, ULA_OUT_MASK & v.SoundMask, WHITE)


def LoadMazeDescriptor(hl):
    """Copy the 8-byte descriptor at HL to MazeDescriptor. Returns nothing."""
    zx.spend(183)
    mem[MazeDescriptor:MazeDescriptor + MAZE_DESC_SIZE] = mem[hl:hl + MAZE_DESC_SIZE]


def LoadGuardRecord(b):
    """Copy guard record B (4 = first ... 1 = last; other values pick the last)
    to the working buffer GuardRecord, remembering it in GuardRecordPtr."""
    zx.spend({4: 974, 3: 993, 2: 1012}.get(b, 1005))     # LDIR of 43 bytes; the first record is found fastest
    src = GuardRecords + GUARD_RECORD_SIZE * (4 - b if b in (4, 3, 2) else 3)
    v.GuardRecordPtr = src
    mem[GuardRecord:GuardRecord + GUARD_RECORD_SIZE] = mem[src:src + GUARD_RECORD_SIZE]


def SaveGuardRecord():
    """Copy the working buffer GuardRecord back to the record at GuardRecordPtr."""
    zx.spend(938)
    dst = v.GuardRecordPtr
    mem[dst:dst + GUARD_RECORD_SIZE] = mem[GuardRecord:GuardRecord + GUARD_RECORD_SIZE]
