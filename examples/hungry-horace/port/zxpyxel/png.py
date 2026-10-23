"""PNG in and out with the standard library, and Spectrum graphics as PNG:
8x8 cells of one ink on the paper, in the colours of zxpyxel's palettes.

    cells(path, cols, rows)          -> [(glyph, ink, bright)] row by row, checked
    write_cells(path, cols, rows, [(glyph, ink, bright)])

A cell's glyph is 8 bytes, top row first, bit 7 the leftmost pixel; a pixel
of the paper colour is 0, any other is 1 and must be the cell's one ink, as on
the Spectrum. Images are read in any common PNG form (indexed, grey, RGB,
with or without alpha, 8 bits or fewer, not interlaced).
"""
import struct
import zlib

from .screen import PALETTES, rgb

WHITE = 7


def read(path):
    """(width, height, rows of (r, g, b))."""
    data = open(path, 'rb').read()
    if data[:8] != b'\x89PNG\r\n\x1a\n':
        raise ValueError('%s: not a PNG' % path)
    pos, idat, palette = 8, b'', None
    while pos < len(data):
        n, kind = struct.unpack('>I4s', data[pos:pos + 8])
        body = data[pos + 8:pos + 8 + n]
        pos += 12 + n
        if kind == b'IHDR':
            w, h, depth, ctype, _, _, interlace = struct.unpack('>IIBBBBB', body)
        elif kind == b'PLTE':
            palette = [tuple(body[i:i + 3]) for i in range(0, n, 3)]
        elif kind == b'IDAT':
            idat += body
        elif kind == b'IEND':
            break
    if interlace or ctype not in (0, 2, 3, 4, 6) or depth > 8:
        raise ValueError('%s: interlaced or 16-bit PNG, save it plain' % path)
    channels = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}[ctype]
    stride, bpp = (w * channels * depth + 7) // 8, max(1, channels * depth // 8)
    raw, rows, prev = zlib.decompress(idat), [], bytearray(stride)
    for y in range(h):
        i = y * (stride + 1)
        line = _unfilter(raw[i], bytearray(raw[i + 1:i + 1 + stride]), prev, bpp)
        prev = line
        if depth < 8:                   # unpack 1, 2 or 4-bit samples
            per = 8 // depth
            line = [b >> (8 - depth * (k % per + 1)) & (1 << depth) - 1
                    for k, b in ((k, line[k // per]) for k in range(w * channels))]
        if ctype == 3:
            rows.append([palette[v] for v in line[:w]])
        elif ctype in (0, 4):
            scale = 255 // ((1 << depth) - 1)
            rows.append([(line[x * channels] * scale,) * 3 for x in range(w)])
        else:
            rows.append([tuple(line[x * channels:x * channels + 3]) for x in range(w)])
    return w, h, rows


def _unfilter(f, line, prev, bpp):
    for i in range(len(line)):
        a = line[i - bpp] if i >= bpp else 0
        b = prev[i]
        c = prev[i - bpp] if i >= bpp else 0
        if f == 1:
            line[i] = line[i] + a & 0xFF
        elif f == 2:
            line[i] = line[i] + b & 0xFF
        elif f == 3:
            line[i] = line[i] + (a + b) // 2 & 0xFF
        elif f == 4:
            p = a + b - c
            pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
            line[i] = line[i] + (a if pa <= pb and pa <= pc else b if pb <= pc else c) & 0xFF
    return line


def write(path, w, h, rows):
    """An 8-bit RGB PNG from rows of (r, g, b)."""
    def chunk(kind, body):
        return struct.pack('>I', len(body)) + kind + body + struct.pack('>I', zlib.crc32(kind + body))
    raw = b''.join(b'\0' + bytes(v for px in row for v in px) for row in rows)
    with open(path, 'wb') as f:
        f.write(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0))
                + chunk(b'IDAT', zlib.compress(raw, 9)) + chunk(b'IEND', b''))


def _colours():
    """RGB -> (colour 0-7, bright) for every palette of zxpyxel; black is not bright."""
    out = {}
    for name in PALETTES:
        for i, c in enumerate(rgb(name)):
            out.setdefault((c >> 16, c >> 8 & 0xFF, c & 0xFF), (i & 7, bool(i & 8)))
    return out


COLOURS = _colours()


def cells(path, cols, rows, paper=WHITE):
    """The image as cols x rows cells: [(glyph, ink, bright)], row by row,
    checked: the size, Spectrum colours only, one ink per cell on the paper."""
    w, h, px = read(path)
    if (w, h) != (cols * 8, rows * 8):
        raise ValueError('%s: %dx%d pixels expected (%dx%d cells), the image is %dx%d'
                         % (path, cols * 8, rows * 8, cols, rows, w, h))
    out = []
    for cy in range(rows):
        for cx in range(cols):
            inks, glyph = set(), []
            for y in range(cy * 8, cy * 8 + 8):
                bits = 0
                for x in range(cx * 8, cx * 8 + 8):
                    c = COLOURS.get(px[y][x])
                    if c is None:
                        raise ValueError('%s: pixel %d,%d is #%02x%02x%02x, not a Spectrum colour '
                                         '(zxpyxel palettes)' % ((path, x, y) + px[y][x]))
                    if c[0] != paper:
                        inks.add(c)
                        bits |= 0x80 >> x - cx * 8
                glyph.append(bits)
            if len(inks) > 1:
                raise ValueError('%s: cell %d,%d has %d inks; a cell is one ink on the paper'
                                 % (path, cx, cy, len(inks)))
            ink, bright = inks.pop() if inks else (0, False)
            out.append((bytes(glyph), ink, bright))
    return out


def write_cells(path, cols, rows, cells, paper=WHITE, palette='pulsar'):
    colours = rgb(palette)

    def colour(i):
        return colours[i] >> 16, colours[i] >> 8 & 0xFF, colours[i] & 0xFF
    px = [[None] * (cols * 8) for _ in range(rows * 8)]
    for k, (glyph, ink, bright) in enumerate(cells):
        cx, cy = k % cols, k // cols
        on, off = colour(ink | bright << 3), colour(paper)
        for y in range(8):
            for x in range(8):
                px[cy * 8 + y][cx * 8 + x] = on if glyph[y] & 0x80 >> x else off
    write(path, cols * 8, rows * 8, px)
