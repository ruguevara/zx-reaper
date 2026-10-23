#!/usr/bin/env python3
"""Gallery images that need game knowledge: item counts, animations.

  docs-anim.py items OUT.png          item graphic of every room, captioned
                                      with the room number and its item count
  docs-anim.py guardians OUT.gif      every guardian of rooms 0-60 cycling
                                      through its animation frames
  docs-anim.py sprites OUTDIR         willy-walk.gif, figure.gif, figure.png,
                                      toilet.gif
  docs-anim.py room INGAME N OUT.gif  room N in play (entities moving, Willy
                                      hidden), one GIF frame per pass

Run from the project root; reads re/image.z80. Formats (see src/*.asm):
items at ItemRoomTable $A400 (bits 0-5 room) from FirstItemIndex $A3FF;
room pages at $C000 + 256*N with the item graphic at +$E1 and the entity
slots at +$F0; entity definitions at $A000 + 8*index. A guardian's frame is
((byte 0 AND byte 1) OR slot byte) >> 5 at page(byte 5)*256 + 32*frame; byte
0 bits 5-6 are the phase of a horizontal mover (up 0-3 going right with bit
7 set, down 3-0 going left), bits 5-7 the phase 0-7 of a vertical mover
(F51, F52, F54 in re/findings.md).
"""
import os
import subprocess
import sys
import tempfile

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'tools'))
from zxgfx import BRIGHT, PALETTE, compose, graphic_pixels, memory, write_gif, write_png  # noqa: E402
from skoolkit.snapshot import Snapshot  # noqa: E402

ROOMS = 61
ROOM_PAGE = 0xC000
ITEM_FIRST = 0xA3FF
ITEM_ROOMS = 0xA400
ENTITY_DEFS = 0xA000
WILLY = 0x9D00          # right-facing frames 0-3, left-facing at +$80
FIGURE = 0x9C80         # frames 0-3 of the Master Bedroom figure
TOILET = 0xA600         # frames 0-1 normal, 2-3 in ending stage 3
DELAY = 8               # 1/100 s per GIF frame: a pass of the frame loop is
                        # about 4 frames (75 ms) on the real machine
SCALE = 3


def item_counts(mem):
    counts = [0] * 64
    for i in range(mem[ITEM_FIRST], 256):
        counts[mem[ITEM_ROOMS + i] & 0x3F] += 1
    return counts


def items(out):
    mem = memory('re/image.z80')
    counts = item_counts(mem)
    graphics, labels = [], []
    for r in range(ROOMS):
        graphics.append(graphic_pixels(mem, ROOM_PAGE + 256 * r + 0xE1, 1, 1, 'cells', 0x46))
        n = counts[r]
        labels.append('%d/%s' % (r, '%d item%s' % (n, 's' if n > 1 else '') if n else '-'))
    write_png(out, compose(graphics, 16, 4, labels))
    print('wrote %s' % out)


def sprite(mem, page, frame, attr):
    return graphic_pixels(mem, page * 256 + 32 * frame, 2, 2, 'linear', attr)


def guardians(out):
    mem = memory('re/image.z80')
    found = {}
    for r in range(ROOMS):
        slots = ROOM_PAGE + 256 * r + 0xF0
        for s in range(8):
            index, start = mem[slots + 2 * s], mem[slots + 2 * s + 1]
            if index == 0xFF:
                break
            d = ENTITY_DEFS + 8 * (index & 0x7F)
            b0, b1, page = mem[d], mem[d + 1], mem[d + 5]
            kind = b0 & 7
            if kind == 1:       # right: phase 0-3 with bit 7 set; left: 3-0
                phases = [0x80 | p << 5 for p in range(4)] + [p << 5 for p in (3, 2, 1, 0)]
            elif kind == 2:
                phases = [p << 5 for p in range(8)]
            else:
                continue
            seq = tuple((((b0 & 0x1F | ph) & b1) | start) >> 5 & 7 for ph in phases)
            attr = (0x40 if b1 & 8 else 0) | b1 & 7
            key = (page, attr, seq)
            found.setdefault(key, (index & 0x7F, []))[1].append(r)
    keys = sorted(found, key=lambda k: found[k][0])
    labels = []
    for k in keys:
        index, rooms = found[k]
        rooms = sorted(set(rooms))
        labels.append('$%02X/%s' % (index, ' '.join(map(str, rooms[:3])) + ('+' if len(rooms) > 3 else '')))
    frames = [compose([sprite(mem, k[0], k[2][f], k[1]) for k in keys], 10, SCALE, labels)
              for f in range(8)]
    write_gif(out, frames, DELAY * 2)
    print('wrote %s: %d guardians' % (out, len(keys)))


def two_tone(mem, addr, top, bottom):
    """A 16x16 sprite whose upper two cells and lower two cells differ in colour."""
    upper = graphic_pixels(mem, addr, 2, 2, 'linear', top)
    lower = graphic_pixels(mem, addr, 2, 2, 'linear', bottom)
    return upper[:8] + lower[8:]


def sprites(outdir):
    mem = memory('re/image.z80')
    walk = [sprite(mem, WILLY >> 8, f, 0x47) for f in (0, 1, 2, 3) * 2] + \
           [graphic_pixels(mem, WILLY + 0x80 + 32 * f, 2, 2, 'linear', 0x47) for f in (3, 2, 1, 0) * 2]
    write_gif(os.path.join(outdir, 'willy-walk.gif'), [compose([g], 1, 4) for g in walk], DELAY * 2)
    figure = [two_tone(mem, FIGURE + 32 * f, 0x45, 0x07) for f in (0, 1)]
    write_gif(os.path.join(outdir, 'figure.gif'), [compose([g], 1, 4) for g in figure], DELAY * 2)
    frames = [two_tone(mem, FIGURE + 32 * f, 0x45, 0x07) for f in range(4)]
    write_png(os.path.join(outdir, 'figure.png'), compose(frames, 4, 4))
    toilet = [sprite(mem, TOILET >> 8, f, 0x07) for f in (0, 1) * 3 + (2, 3) * 3]
    write_gif(os.path.join(outdir, 'toilet.gif'), [compose([g], 1, 4) for g in toilet], DELAY * 2)
    print('wrote willy-walk.gif, figure.gif, figure.png, toilet.gif in %s' % outdir)


def screen_pixels(mem):
    """256 x 128 colour pixels of the playing area (top two thirds of the screen)."""
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


def room(ingame, n, out, passes=60, first=20, step=4):
    """Room N from EnterRoom with Willy hidden (ending stage 3), sampled every
    STEP frames (one pass is about 4 frames)."""
    frames = []
    with tempfile.TemporaryDirectory() as tmp:
        for k in range(passes):
            snap = os.path.join(tmp, 's.z80')
            subprocess.run([sys.executable, 'tools/zxrun.py', ingame, '--poke', '0x8420,%d' % n,
                            '--poke', '0x85DF,3', '--pc', '0x8912', '--frames', str(first + step * k),
                            '--dump', snap], check=True, capture_output=True)
            mem = [0] * 0x4000 + list(Snapshot.get(snap).ram(-1))
            px = screen_pixels(mem)
            frames.append([[p for p in row for _ in range(2)] for row in px for _ in range(2)])
    write_gif(out, frames, DELAY)
    print('wrote %s: %d frames' % (out, len(frames)))


def main():
    a = sys.argv[1:]
    if len(a) == 2 and a[0] == 'items':
        items(a[1])
    elif len(a) == 2 and a[0] == 'guardians':
        guardians(a[1])
    elif len(a) == 2 and a[0] == 'sprites':
        sprites(a[1])
    elif len(a) == 4 and a[0] == 'room':
        room(a[1], int(a[2]), a[3])
    else:
        sys.exit(__doc__)


if __name__ == '__main__':
    main()
