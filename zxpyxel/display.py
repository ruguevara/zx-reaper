"""The Spectrum screen without addresses, for games that are not ports: 32x24
cells of 8x8 pixels, each with an attribute (ink, paper, BRIGHT, FLASH), the
ROM font and the border. It keeps the display file and the attributes in the
Spectrum's layout (`data`, 6912 bytes as at $4000), so a screen compares byte
for byte with a Spectrum's and `screen.render(display.data, base=0)` shows it.
"""
from .machine import ROM

COLS, ROWS = 32, 24
FONT = 0x3D00            # the ROM font: 96 characters from space, 8 bytes each


def attr(ink, paper=7, bright=False, flash=False):
    """An attribute byte."""
    return flash << 7 | bright << 6 | paper << 3 | ink


def _row(col, row, line):
    """Offset in the display file of pixel line `line` of a cell."""
    return (row & 0x18) << 8 | line << 8 | (row & 7) << 5 | col


def _line(col, y):
    """Offset in the display file of the 8 pixels of cell column `col` on pixel row `y`."""
    return _row(col, y >> 3, y & 7)


class Display:
    def __init__(self):
        self.data = bytearray(6912)
        self.border = 7

    def __eq__(self, other):
        return isinstance(other, Display) and self.data == other.data and self.border == other.border

    def cls(self, a):
        self.data[:6144] = bytes(6144)
        self.data[6144:] = bytes([a]) * 768

    def cell(self, col, row, glyph, a):
        """8 bytes, top row first, bit 7 the leftmost pixel, and an attribute."""
        for line in range(8):
            self.data[_row(col, row, line)] = glyph[line]
        self.data[6144 + row * COLS + col] = a

    def glyph(self, col, row):
        return bytes(self.data[_row(col, row, line)] for line in range(8))

    def attr(self, col, row):
        return self.data[6144 + row * COLS + col]

    def sprite(self, col, row, graphic, a):
        """32 bytes on 2x2 cells, in the order top-left, top-right, bottom-left,
        bottom-right."""
        for i in range(4):
            self.cell(col + (i & 1), row + (i >> 1), graphic[8 * i:8 * i + 8], a)

    def text(self, col, row, s, a):
        """Characters 32-127 of the ROM font from (col, row) to the right."""
        for i, ch in enumerate(s):
            c = FONT + (ord(ch) - 32) * 8
            self.cell(col + i, row, ROM[c:c + 8], a)

    def byte(self, col, y):
        """The 8 pixels of cell column `col` (0-31) on pixel row `y` (0-191), bit 7 leftmost."""
        return self.data[_line(col, y)]

    def set_byte(self, col, y, v):
        self.data[_line(col, y)] = v

    def set_attr(self, col, row, a):
        self.data[6144 + row * COLS + col] = a

    def pixel(self, x, y):
        """1 when the pixel at (x, y) is set (x 0-255, y 0-191 from the top)."""
        return self.data[_line(x >> 3, y)] >> (7 - (x & 7)) & 1

    def plot(self, x, y):
        self.data[_line(x >> 3, y)] |= 0x80 >> (x & 7)
