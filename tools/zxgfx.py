#!/usr/bin/env python3
"""Render graphics data from a snapshot as colour PNG sheets (for docs).

  zxgfx.py sheet ADDR COUNT W H OUT.png [options]

ADDR: first graphic; COUNT graphics of W x H character cells each.
Options:
  --layout cells|linear|attrcells
                         cells: each 8x8 cell is 8 consecutive bytes, cells in
                         row order (TL, TR, BL, BR for 2x2; default);
                         linear: pixel rows of W bytes, top to bottom;
                         attrcells: each cell is its attribute byte + 8 bytes
  --stride N             bytes from one graphic to the next (default W*H*8)
  --attr A               attribute for every graphic (default $38: black on white)
  --attrs A,B,...        one attribute per graphic (overrides --attr)
  --cols N               graphics per row of the sheet (default 8)
  --scale N              pixel scale (default 3)
  --snapshot FILE        default re/image.z80
Examples:
  zxgfx.py sheet $7CC7 8 2 2 docs/img/horace.png --attr $39 --cols 8
  zxgfx.py sheet $7BF7 10 1 1 docs/img/tiles.png --attrs $3E,$3D,$3C,$38,$3D,$3D,$3D,$3D,$3D,$3F
"""
import argparse
import struct
import sys
import zlib

from skoolkit.snapshot import Snapshot

PALETTE = [(0, 0, 0), (0, 0, 0xD7), (0xD7, 0, 0), (0xD7, 0, 0xD7),
           (0, 0xD7, 0), (0, 0xD7, 0xD7), (0xD7, 0xD7, 0), (0xD7, 0xD7, 0xD7)]
BRIGHT = [(0, 0, 0), (0, 0, 0xFF), (0xFF, 0, 0), (0xFF, 0, 0xFF),
          (0, 0xFF, 0), (0, 0xFF, 0xFF), (0xFF, 0xFF, 0), (0xFF, 0xFF, 0xFF)]
GRID = (0x60, 0x60, 0x60)


def num(s):
    s = s.strip()
    return int(s[1:], 16) if s.startswith('$') else int(s, 0)


def colours(attr):
    pal = BRIGHT if attr & 0x40 else PALETTE
    return pal[attr & 7], pal[(attr >> 3) & 7]


def graphic_pixels(mem, addr, w, h, layout, attr):
    """Rows of (ink, paper) colour pixels for one W x H cell graphic."""
    rows = []
    for y in range(h * 8):
        row = []
        for cx in range(w):
            cell = (y // 8) * w + cx
            a = attr
            if layout == 'cells':
                b = mem[addr + cell * 8 + y % 8]
            elif layout == 'attrcells':
                a = mem[addr + cell * 9]
                b = mem[addr + cell * 9 + 1 + y % 8]
            else:
                b = mem[addr + y * w + cx]
            ink, paper = colours(a)
            row += [ink if (b >> (7 - k)) & 1 else paper for k in range(8)]
        rows.append(row)
    return rows


def write_png(path, rows):
    h, w = len(rows), len(rows[0])
    raw = b''.join(b'\0' + bytes(c for px in row for c in px) for row in rows)

    def chunk(t, d):
        return struct.pack('>I', len(d)) + t + d + struct.pack('>I', zlib.crc32(t + d))
    with open(path, 'wb') as f:
        f.write(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0))
                + chunk(b'IDAT', zlib.compress(raw, 9)) + chunk(b'IEND', b''))


def sheet(a):
    snap = Snapshot.get(a.snapshot)
    mem = [0] * 16384 + list(snap.ram(-1))[:49152]
    stride = a.stride or a.w * a.h * (9 if a.layout == 'attrcells' else 8)
    attrs = [num(x) for x in a.attrs.split(',')] if a.attrs else [a.attr] * a.count
    cols = min(a.cols, a.count)
    nrows = (a.count + cols - 1) // cols
    gw, gh = a.w * 8, a.h * 8
    width = cols * (gw + 1) + 1
    height = nrows * (gh + 1) + 1
    canvas = [[GRID] * width for _ in range(height)]
    for n in range(a.count):
        px = graphic_pixels(mem, a.addr + n * stride, a.w, a.h, a.layout, attrs[n % len(attrs)])
        ox, oy = 1 + (n % cols) * (gw + 1), 1 + (n // cols) * (gh + 1)
        for y in range(gh):
            canvas[oy + y][ox:ox + gw] = px[y]
    rows = [[p for p in row for _ in range(a.scale)] for row in canvas for _ in range(a.scale)]
    write_png(a.out, rows)
    print('wrote %s: %d graphics, %dx%d px' % (a.out, a.count, width * a.scale, height * a.scale))


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0],
                                 formatter_class=argparse.RawDescriptionHelpFormatter,
                                 epilog='\n'.join(__doc__.split('\n')[2:]))
    ap.add_argument('cmd', choices=['sheet'])
    ap.add_argument('addr', type=num)
    ap.add_argument('count', type=num)
    ap.add_argument('w', type=num)
    ap.add_argument('h', type=num)
    ap.add_argument('out')
    ap.add_argument('--layout', choices=['cells', 'linear', 'attrcells'], default='cells')
    ap.add_argument('--stride', type=num, default=0)
    ap.add_argument('--attr', type=num, default=0x38)
    ap.add_argument('--attrs')
    ap.add_argument('--cols', type=int, default=8)
    ap.add_argument('--scale', type=int, default=3)
    ap.add_argument('--snapshot', default='re/image.z80')
    sheet(ap.parse_args())


if __name__ == '__main__':
    import signal
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)
    try:
        main()
    except (OSError, ValueError) as e:
        sys.exit(str(e))
