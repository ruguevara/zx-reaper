#!/usr/bin/env python3
"""Render graphics data from a snapshot as colour PNG sheets (for docs).

  zxgfx.py sheet ADDR COUNT W H OUT.png [options]
  zxgfx.py gif ADDR COUNT W H OUT.gif [options]   COUNT graphics as animation frames

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
  --labels T,T,...       sheet: caption under each graphic ('/' starts a new line)
  --order N,N,...        gif: frame order by graphic number (default 0..COUNT-1)
  --delay CS             gif: 1/100 s per frame (default 20)
Examples:
  zxgfx.py sheet $7CC7 8 2 2 docs/img/horace.png --attr $39 --cols 8
  zxgfx.py sheet $7BF7 10 1 1 docs/img/tiles.png --attrs $3E,$3D,$3C,$38,$3D,$3D,$3D,$3D,$3D,$3F
  zxgfx.py gif $9D00 4 2 2 docs/img/walk.gif --attr $47 --scale 4 --delay 12
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


def load_font():
    """The 48K ROM (its character set at $3D00 draws the captions)."""
    from skoolkit import ROM48
    with open(ROM48, 'rb') as f:
        return f.read()


def draw_text(canvas, font, text, ox, oy, colour=(0xFF, 0xFF, 0xFF)):
    """Print text with the ROM font (8x8 per character) at pixel ox, oy."""
    for n, ch in enumerate(text):
        code = ord(ch) if 32 <= ord(ch) < 128 else ord('?')
        glyph = font[0x3C00 + 8 * code:0x3C00 + 8 * code + 8]
        for y in range(8):
            for x in range(8):
                if (glyph[y] >> (7 - x)) & 1:
                    canvas[oy + y][ox + 8 * n + x] = colour


def compose(graphics, cols, scale, labels=None):
    """Lay out graphics (rows of colour pixels, all the same size) in a grid,
    scaled, with grid lines as wide as one scaled pixel; labels (one string
    per graphic, lines split by '/') are printed with the ROM font under each
    graphic."""
    gh, gw = len(graphics[0]), len(graphics[0][0])
    cols = min(cols, len(graphics))
    nrows = (len(graphics) + cols - 1) // cols
    lines = [str(t).split('/') for t in labels] if labels else []
    nlines = max((len(x) for x in lines), default=0)
    b = scale
    cw = max([gw * scale] + [8 * len(t) for x in lines for t in x])
    ch = gh * scale + (9 * nlines + 1 if nlines else 0)
    width, height = cols * (cw + b) + b, nrows * (ch + b) + b
    canvas = [[GRID] * width for _ in range(height)]
    font = load_font() if lines else None
    for n, px in enumerate(graphics):
        ox, oy = b + (n % cols) * (cw + b), b + (n // cols) * (ch + b)
        for y in range(oy, oy + ch):
            canvas[y][ox:ox + cw] = [(0, 0, 0)] * cw
        gx = ox + (cw - gw * scale) // 2
        for y in range(gh * scale):
            canvas[oy + y][gx:gx + gw * scale] = [p for p in px[y // scale] for _ in range(scale)]
        for k, t in enumerate(lines[n] if lines else []):
            draw_text(canvas, font, t, ox + (cw - 8 * len(t)) // 2, oy + gh * scale + 1 + 9 * k)
    return canvas


def lzw(indices, min_size):
    """GIF LZW compression of a list of palette indices."""
    clear, end = 1 << min_size, (1 << min_size) + 1
    out, acc, nbits = bytearray(), 0, 0
    size, nxt, table = min_size + 1, end + 1, {}

    def emit(code):
        nonlocal acc, nbits
        acc |= code << nbits
        nbits += size
        while nbits >= 8:
            out.append(acc & 0xFF)
            acc >>= 8
            nbits -= 8
    emit(clear)
    prefix = indices[0]
    for k in indices[1:]:
        if (prefix, k) in table:
            prefix = table[prefix, k]
            continue
        emit(prefix)
        if nxt < 4096:
            table[prefix, k] = nxt
            nxt += 1
            if nxt > 1 << size and size < 12:
                size += 1
        else:
            emit(clear)
            size, nxt, table = min_size + 1, end + 1, {}
        prefix = k
    emit(prefix)
    emit(end)
    if nbits:
        out.append(acc & 0xFF)
    return bytes(out)


def write_gif(path, frames, delay=20):
    """Animated GIF (looping) from frames of colour rows, all the same size;
    delay in 1/100 s per frame."""
    colours = sorted({c for f in frames for row in f for c in row})
    if len(colours) > 256:
        raise ValueError('more than 256 colours')
    bits = max(1, (len(colours) - 1).bit_length())
    index = {c: n for n, c in enumerate(colours)}
    h, w = len(frames[0]), len(frames[0][0])
    pal = b''.join(bytes(c) for c in colours) + bytes(3 * ((1 << bits) - len(colours)))
    data = bytearray(b'GIF89a' + struct.pack('<HHBBB', w, h, 0x80 | 0x70 | (bits - 1), 0, 0) + pal)
    data += b'\x21\xFF\x0BNETSCAPE2.0\x03\x01\x00\x00\x00'
    min_size = max(2, bits)
    for f in frames:
        data += b'\x21\xF9\x04\x00' + struct.pack('<H', delay) + b'\x00\x00'
        data += b'\x2C' + struct.pack('<HHHHB', 0, 0, w, h, 0) + bytes([min_size])
        code = lzw([index[c] for row in f for c in row], min_size)
        for i in range(0, len(code), 255):
            data += bytes([len(code[i:i + 255])]) + code[i:i + 255]
        data += b'\x00'
    data += b'\x3B'
    with open(path, 'wb') as f:
        f.write(data)


def memory(path):
    return [0] * 16384 + list(Snapshot.get(path).ram(-1))[:49152]


def sheet(a):
    mem = memory(a.snapshot)
    stride = a.stride or a.w * a.h * (9 if a.layout == 'attrcells' else 8)
    attrs = [num(x) for x in a.attrs.split(',')] if a.attrs else [a.attr] * a.count
    labels = a.labels.split(',') if a.labels else None
    graphics = [graphic_pixels(mem, a.addr + n * stride, a.w, a.h, a.layout, attrs[n % len(attrs)])
                for n in range(a.count)]
    if a.cmd == 'gif':
        order = [num(x) for x in a.order.split(',')] if a.order else range(a.count)
        frames = [compose([graphics[n]], 1, a.scale) for n in order]
        write_gif(a.out, frames, a.delay)
        print('wrote %s: %d frames, %dx%d px' % (a.out, len(frames), len(frames[0][0]), len(frames[0])))
        return
    rows = compose(graphics, a.cols, a.scale, labels)
    write_png(a.out, rows)
    print('wrote %s: %d graphics, %dx%d px' % (a.out, a.count, len(rows[0]), len(rows)))


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0],
                                 formatter_class=argparse.RawDescriptionHelpFormatter,
                                 epilog='\n'.join(__doc__.split('\n')[2:]))
    ap.add_argument('cmd', choices=['sheet', 'gif'])
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
    ap.add_argument('--labels')
    ap.add_argument('--order')
    ap.add_argument('--delay', type=int, default=20)
    sheet(ap.parse_args())


if __name__ == '__main__':
    import signal
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)
    try:
        main()
    except (OSError, ValueError) as e:
        sys.exit(str(e))
