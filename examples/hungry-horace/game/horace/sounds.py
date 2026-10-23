"""The sound effects as data: the shapes of the original's beeper loops
(half periods in T-states of the 3.5 MHz clock, cycles), turned into speaker
edges for zxpyxel.sound."""
from .constants import (CHIME_HIGH_LEN, CHIME_HIGH_PITCH, CHIME_LOW_LEN, CHIME_LOW_PITCH,
                        EAT_TONE_STEPS, EATEN_TONE_CYCLES, EATEN_TONE_STEPS, SWEEP_CYCLES,
                        SWEEP_STEPS, WRAP_TONE_CYCLES)


def djnz(b):
    """T-states of a DJNZ loop of b passes (0 makes 256)."""
    return 13 * (b or 256) - 5


def sweep(cycles):
    """The rising tone: 16 steps, the half period shrinking."""
    return [(djnz(c << 3 & 0xFF) + 33, djnz(c << 3 & 0xFF) + 33, cycles)
            for c in range(SWEEP_STEPS, 0, -1)]


def shape(sound):
    """(on T, off T, cycles) segments of an effect."""
    name = sound.name
    if name == 'rising':
        return sweep(SWEEP_CYCLES)
    if name == 'wrap':
        return sweep(WRAP_TONE_CYCLES)
    if name == 'chirp':
        return [(18 + djnz(c << 3), djnz(c << 3) + 112, 1) for c in range(EAT_TONE_STEPS, 0, -1)]
    if name == 'buzz':
        return [(51 * ((c ^ EATEN_TONE_STEPS) << 3 & 0xFF or 256) + 28,) * 2 + (EATEN_TONE_CYCLES,)
                for c in range(EATEN_TONE_STEPS, 0, -1)]
    if name == 'noise':                 # data: the random loop counts, on, off, on, off ...
        d = sound.data
        return [(djnz(d[i]) + 49, djnz(d[i + 1]) + 65, 1) for i in range(0, len(d) - 1, 2)]
    if name == 'chime':                 # data: True for low then high, False for high then low
        low, high = (CHIME_LOW_LEN, CHIME_LOW_PITCH), (CHIME_HIGH_LEN, CHIME_HIGH_PITCH)
        return [(4 * hl + 120, 4 * hl + 120, de) for de, hl in ((low, high) if sound.data else (high, low))]
    return []


def edges(sound):
    """Speaker changes (T, level) from 0, and the effect's length in T-states."""
    out, t = [], 0
    for on, off, cycles in shape(sound):
        for _ in range(cycles):
            out.append((t, 1))
            t += on
            out.append((t, 0))
            t += off
    return out, t
