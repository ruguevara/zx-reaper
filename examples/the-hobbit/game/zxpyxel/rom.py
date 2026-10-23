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


T_BIT = 2 * 1710        # T-states of a tape bit, the mean of a 0 (2 x 855) and a 1 (2 x 1710) taken as 1710
T_LEADER = 3223 * 2168  # the leader of a data block (flag >= $80), about 2 s


async def tape_time(nbytes):
    """Spend the time a ROM save or load of `nbytes` takes, a frame at a time."""
    t = T_LEADER + nbytes * 8 * T_BIT
    while t > 0:
        zx.spend(min(t, 69888))
        t -= 69888
        await zx.sync()


async def SA_BYTES(ix, de, a):
    """$04C2: save DE bytes from IX as a block with flag byte A. The block is
    added to zx.tape (a list of bytes, flag first; a host may keep it in a
    file); it takes the ROM's time. Leaves interrupts enabled, as the ROM does.
    With no tape (zx.tape is None, a replay) the block goes nowhere."""
    await tape_time(de + 1)
    if zx.tape is not None:
        zx.tape.append(bytes([a]) + bytes(zx.mem[ix:ix + de]))
    zx.ei()


async def LD_BYTES(ix, de, a, load):
    """$0556: load (`load` true, carry set) or verify DE bytes at IX from the
    next block of zx.tape with flag A and that length, from the tape position,
    rewinding at the end. Returns the carry: True when the block was found and,
    for a verify, matched. With no tape (None, or no such block) it waits for
    one forever, as the ROM does with no tape playing. Leaves interrupts
    enabled."""
    blocks = zx.tape or []
    for k in range(len(blocks)):
        i = (zx.tape_pos + k) % len(blocks)
        b = blocks[i]
        if b[0] == a and len(b) == de + 1:
            await tape_time(de + 1)
            zx.tape_pos = i + 1
            ok = True
            if load:
                zx.mem[ix:ix + de] = b[1:]
            else:
                ok = bytes(zx.mem[ix:ix + de]) == b[1:]
            zx.ei()
            return ok
    while True:
        zx.spend(69888)
        await zx.sync()
