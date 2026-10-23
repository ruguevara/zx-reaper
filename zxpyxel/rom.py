"""ROM routines that ported games call, named by their ROM labels. Add one when
a game needs it; each says what it approximates."""
from .machine import zx

BORDCR = 0x5C48


def BEEPER(de, hl):
    """$03B5: DE cycles of a square wave of 437500 / (HL + 30.125) Hz in the
    border colour of BORDCR; leaves interrupts enabled, as the ROM does."""
    border = zx.mem[BORDCR] >> 3 & 7 | 0x08
    zx.tone(4 * hl + 120, de, border | 0x10, border)
    zx.ei()
