#!/usr/bin/env python3
"""Compose the room map of docs/07-graphics.md from the rendered rooms.

  scripts/docs-roommap.py DUMPDIR OUT.png

DUMPDIR holds room-NN.z80, the snapshots written by docs/img/Makefile after
the game drew room NN (EnterRoom plus one pass of FrameLoop). Each room's
playing area (16 x 32 cells) is taken from the screen of its snapshot, shrunk
to half size (2x2 pixel blocks averaged) and placed on the grid below; the
room number is printed in its corner with the font of the 48K ROM.

The grid follows the exits: a room's left/right/up/down neighbour sits next to
it where the exit bytes of both rooms point at each other. The exits do not
form a flat map everywhere; the links that cannot be drawn as neighbours are
listed in docs/07-graphics.md.
"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'tools'))
from zxgfx import BRIGHT, PALETTE, write_png  # noqa: E402
from skoolkit.snapshot import Snapshot  # noqa: E402

# Rows of the map, top to bottom; None = empty. Built from the exits by a
# breadth-first walk from the Bathroom (33) over pairs of exits that point at
# each other, then rooms 6, 16, 17, 47 and 50 and the top row placed by hand.
GRID = [
    [None] * 7 + [50] + [None] * 10,
    [None] * 4 + [48, 18, 17, 16, 15, 14, 44] + [None] * 7,
    [None] * 5 + [43, 42, 41, 40, 39, 38] + [None] * 7,
    [None] * 3 + [57, 56, 37, 36, 35, 34, 33, 32] + [None] * 7,
    [None] * 3 + [55, 54, 31, 30, 29, 28, 27, 26, None, None, 13, 12, None, None, None],
    [None] * 3 + [53, 52, 25, 24, 23, 22, 21, 20, 11, 10, 9, 8, 7, None, None],
    [60, 59, 58, 51, 49] + [None] * 6 + [19, 5, 4, 3, 2, 1, 0],
    [None] * 12 + [6, 45, 46, 47, None, None],
]

W, H = 128, 64          # room thumbnail in pixels (half of 256 x 128)
GAP = 4
BG = (0x40, 0x40, 0x40)


def screen_pixels(mem):
    """256 x 128 colour pixels of the top two thirds of the screen."""
    rows = []
    for y in range(128):
        addr = 0x4000 + ((y & 0xC0) << 5) + ((y & 7) << 8) + ((y & 0x38) << 2)
        row = []
        for cx in range(32):
            a = mem[0x5800 + (y // 8) * 32 + cx]
            pal = BRIGHT if a & 0x40 else PALETTE
            ink, paper = pal[a & 7], pal[(a >> 3) & 7]
            b = mem[addr + cx]
            row += [ink if (b >> (7 - k)) & 1 else paper for k in range(8)]
        rows.append(row)
    return rows


def half(rows):
    out = []
    for y in range(0, len(rows), 2):
        r0, r1 = rows[y], rows[y + 1]
        out.append([tuple((r0[x][c] + r0[x + 1][c] + r1[x][c] + r1[x + 1][c]) // 4 for c in range(3))
                    for x in range(0, len(r0), 2)])
    return out


def label(img, rom, text, ox, oy):
    """Print text with the ROM font (8x8, white on black) at pixel ox, oy."""
    for n, ch in enumerate(text):
        glyph = rom[0x3C00 + 8 * ord(ch):0x3C00 + 8 * ord(ch) + 8]
        for y in range(8):
            for x in range(8):
                on = (glyph[y] >> (7 - x)) & 1
                img[oy + y][ox + 8 * n + x] = (0xFF, 0xFF, 0xFF) if on else (0, 0, 0)


def main():
    dumpdir, out = sys.argv[1], sys.argv[2]
    font = load_font()
    cols = len(GRID[0])
    width = cols * (W + GAP) + GAP
    height = len(GRID) * (H + GAP) + GAP
    img = [[BG] * width for _ in range(height)]
    for gy, row in enumerate(GRID):
        assert len(row) == cols, gy
        for gx, room in enumerate(row):
            if room is None:
                continue
            snap = Snapshot.get(os.path.join(dumpdir, 'room-%02d.z80' % room))
            mem = [0] * 0x4000 + list(snap.ram(-1))
            pix = half(screen_pixels(mem))
            ox, oy = GAP + gx * (W + GAP), GAP + gy * (H + GAP)
            for y in range(H):
                img[oy + y][ox:ox + W] = pix[y]
            label(img, font, str(room), ox, oy)
    write_png(out, img)
    print('wrote %s: %dx%d px' % (out, width, height))


def load_font():
    from skoolkit import ROM48
    with open(ROM48, 'rb') as f:
        return list(f.read())


if __name__ == '__main__':
    main()
