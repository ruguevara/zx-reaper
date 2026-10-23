"""Case builders shared by the tests of src/sprites.asm."""
# Attributes a cell holds in the game (the guard's are special to SaveBackground / GetBlockObject).
OBJ_ATTRS = [0x3B, 0x3A, 0x3C, 0x3E, 0x38, 0x39, 0x3D, 0x30, 0x07, 0x35]


def pos(rnd):
    """Screen offset of a 2x2 sprite in the maze (cell rows 1..22, columns 0..30)."""
    row, col = rnd.randrange(1, 23), rnd.randrange(31)
    return (row // 8 << 11) + (row % 8 << 5) + col


def word(n):
    return [n & 255, n >> 8]


def screen(rnd, sym, const, objects=True):
    """Random bitmap; attributes drawn from the game's objects."""
    bitmap = bytes(rnd.randrange(256) for _ in range(const('SCREEN_SIZE')))
    pool = OBJ_ATTRS if objects else list(range(256))
    attrs = bytes(rnd.choice(pool) for _ in range(const('ATTRS_SIZE')))
    return {sym('SCREEN'): bitmap + attrs}


def record(rnd, old, new, wait=0, direction=None):
    """A 43-byte guard record: old pos, dir, anim, new pos, wait, saved background."""
    d = rnd.randrange(4) if direction is None else direction
    return bytes(word(old) + [d, rnd.randrange(256)] + word(new) + [wait]
                 + [rnd.choice(OBJ_ATTRS) if i % 9 == 0 else rnd.randrange(256) for i in range(36)])


def records(rnd, moved=0.7, waits=(0,)):
    out = b''
    for _ in range(4):
        old = pos(rnd)
        out += record(rnd, old, pos(rnd) if rnd.random() < moved else old, rnd.choice(waits))
    return out
