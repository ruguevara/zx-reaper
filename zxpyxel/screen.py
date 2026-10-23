"""Screen memory → palette indices, one byte per pixel (256x192): colours 0-7,
BRIGHT as 8-15, FLASH swapping ink and paper in phase 1."""
LINE = [(y & 0xC0) << 5 | (y & 7) << 8 | (y & 0x38) << 2 for y in range(192)]   # from $4000
ATTR = [0x1800 + (y >> 3) * 32 for y in range(192)]
_BITS = [bytes(b >> (7 - i) & 1 for i in range(8)) for b in range(256)]

# RGB levels (normal, bright) of the palettes from the zxpyxel prototype
PALETTES = {
    'pulsar': ((205, 205, 205), (255, 255, 255)),
    'alone': ((160, 160, 160), (255, 255, 255)),
    'orthodox': ((167, 183, 205), (208, 228, 255)),
}


def _table(phase):
    """(attribute << 8 | bitmap byte) → the 8 palette indices of those pixels."""
    t = []
    for a in range(256):
        ink, paper = (a & 7) | (a >> 3 & 8), (a >> 3 & 7) | (a >> 3 & 8)
        if a & 0x80 and phase:
            ink, paper = paper, ink
        tr = bytes.maketrans(b'\0\1', bytes((paper, ink)))
        t += [bits.translate(tr) for bits in _BITS]
    return t


_TABLES = [_table(0), _table(1)]


def render(mem, flash=0, base=0x4000):
    """The screen at `base` in `mem` (a 64K memory, or a 6912-byte display
    with base 0)."""
    t = _TABLES[flash]
    out = []
    for y in range(192):
        o, a = base + LINE[y], base + ATTR[y]
        out += [t[mem[a + x] << 8 | mem[o + x]] for x in range(32)]
    return b''.join(out)


def rgb(palette='pulsar'):
    """The 16 colours as 0xRRGGBB: index = bright * 8 + G R B bits."""
    out = []
    for r, g, b in PALETTES[palette]:
        out += [(c >> 1 & 1) * r << 16 | (c >> 2 & 1) * g << 8 | (c & 1) * b for c in range(8)]
    return out
