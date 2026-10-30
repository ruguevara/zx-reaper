"""The 22 location pictures as command lists, read from src/pictures.asm, and
their renders by stage 4's interpreter (game/hobbit/pictures.py), which draws
them as the game does.

A command is a tuple, as in game/hobbit/pictures.py:
  ('move', x, y)                     the pen to (x, y)
  ('line', M, m, n, k)               n pixels from the pen, a step in direction M
                                     after each, one in m after every k of them
  ('fill', ink, x, y)                flood fill from the seed (x, y)
  ('paint', paper, cell, runs)       runs: [(d, count)], d in 'urdl'
  ('then', loc)                      go on with picture loc's commands
A picture is a Stream: its own commands, which may end in 'then'."""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, 'game'))
from hobbit import pictures as P  # noqa: E402
from zxpyxel import png, screen  # noqa: E402
from zxpyxel.display import Display  # noqa: E402

W, H = 256, 128
RGB = [(c >> 16, c >> 8 & 0xFF, c & 0xFF) for c in screen.rgb()]


class Stream:
    def __init__(self, loc, border, attr, commands):
        self.loc, self.border, self.attr, self.commands = loc, border, attr, commands


def memory():
    """{address: byte} of src/pictures.asm from PictureTable ($CC00) on, and its labels."""
    mem, labels, words = {}, {}, []
    a = 0xCC00
    with open(os.path.join(ROOT, 'src', 'pictures.asm')) as f:
        for line in f:
            line = line.split(';')[0].rstrip()
            m = re.match(r'(\w+):$', line)
            if m:
                labels[m.group(1)] = a
                continue
            op, _, args = line.strip().partition(' ')
            if op == 'DEFB':
                for v in args.split(','):
                    mem[a] = int(v.strip()[1:], 16)
                    a += 1
            elif op == 'DEFW':
                words.append((a, args.strip()))
                a += 2
            elif op == 'DEFS':
                a += int(args.strip()[1:], 16)
            elif op:
                raise ValueError('pictures.asm: %s' % line)
    for at, label in words:
        mem[at], mem[at + 1] = labels[label] & 0xFF, labels[label] >> 8
    return mem, labels


def table(mem, labels):
    """[(location id, address)] of PictureTable, in its (address) order."""
    out, a = [], labels['PictureTable']
    while mem[a] != 0xFF:
        out.append((mem[a], mem[a + 1] | mem[a + 2] << 8))
        a += 3
    return out


def decode(mem, a, starts):
    """The commands of the original picture at `a` and its length in bytes up
    to the next picture's header when it runs on into it ('then')."""
    out, p = [], a + 2
    while True:
        if p in starts and p != a + 2:
            out.append(('then', starts[p]))
            break
        c = mem[p]
        p += 1
        if c == 0:
            break
        if c == 0x08:
            out.append(('move', mem[p], mem[p + 1]))
            p += 2
        elif c & 0x80:
            b2 = mem[p]
            p += 1
            h, v = 'l' if c & 4 else 'r', 'd' if c & 2 else 'u'
            major, minor = (v, h) if c & 1 else (h, v)
            out.append(('line', major, minor, (b2 & 0x3F) + 1, ((c >> 1 & 0x3C) | b2 >> 6) + 1))
        elif c & 0x40:
            out.append(('fill', c & 7, mem[p], mem[p + 1]))
            p += 2
        elif c & 0x20:
            cell = (mem[p] << 8 | mem[p + 1]) - 0x5800
            p += 2
            runs = []
            while mem[p] != 0xFF:
                runs.append(('urdl'[mem[p] & 3], (mem[p] >> 2) + 1))
                p += 1
            p += 1
            out.append(('paint', c & 7, cell, runs))
        else:
            raise ValueError('command $%02X at $%04X' % (c, p - 1))
    return out, p - a


def load():
    """The pictures as Streams, in address order (a 'then' goes to the next one)."""
    mem, labels = memory()
    tab = table(mem, labels)
    starts = {a + 2: loc for loc, a in tab}
    return [Stream(loc, mem[a], mem[a + 1], decode(mem, a, starts)[0]) for loc, a in tab]


def original_bytes():
    """The picture data as stored: $CC43 to the end of the last picture."""
    mem, labels = memory()
    return bytes(mem[a] for a in range(table(mem, labels)[0][1], labels['LF35A'] + 1))


def flat(streams, loc):
    """The commands that draw picture `loc`, its 'then' followed."""
    by = {s.loc: s for s in streams}
    out = []
    for c in by[loc].commands:
        out += flat(streams, c[1]) if c[0] == 'then' else [c]
    return out


def users(streams, loc):
    """The pictures whose drawing runs through stream `loc`."""
    by = {s.loc: s for s in streams}

    def chain(s):
        yield s.loc
        while s.commands and s.commands[-1][0] == 'then':
            s = by[s.commands[-1][1]]
            yield s.loc
    return [s.loc for s in streams if loc in chain(s)]


def placements(streams, loc):
    """[(user, flat commands, offset of stream loc's commands in them)] of
    every picture that draws stream loc."""
    by = {s.loc: s for s in streams}
    out = []
    for user in users(streams, loc):
        offset, s = 0, by[user]
        while s.loc != loc:
            offset += sum(c[0] != 'then' for c in s.commands)
            s = by[s.commands[-1][1]]
        out.append((user, flat(streams, user), offset))
    return out


class Canvas(Display):
    """A Display that lists the pixels plotted on it (x, row from the top)."""
    def __init__(self):
        super().__init__()
        self.plots = []

    def plot(self, x, y):
        self.plots.append((x, y))
        super().plot(x, y)


def steps(commands, border, attr):
    """Draws the commands one by one, yielding (index, command, the pixels it
    plotted as pen coordinates, the pixels lit before it)."""
    d = Canvas()
    P.draw(d, (), border, attr)
    pen, lit = P.PEN_START, set()
    for i, c in enumerate(commands):
        d.plots = []
        if c[0] == 'move':
            pen = (c[1], c[2])
        elif c[0] == 'line':
            pen = P.draw_line(d, *pen, *c[1:], 0)
        elif c[0] == 'fill':
            P.flood_fill(d, *c[1:])
        else:
            P.paint(d, *c[1:])
        plotted = {(x, P.TOP - row) for x, row in d.plots}
        yield i, c, plotted, lit
        lit = lit | plotted


def render(commands, border, attr):
    d = Display()
    P.draw(d, commands, border, attr)
    return d


def headers(stream):
    """[(name, border, attr)] the picture is drawn with: its own header, and
    for the trolls' clearing the one dawn writes (LA94E_0)."""
    out = [(stream.loc, stream.border, stream.attr)]
    if stream.loc == P.TROLLS_CLEARING:
        out.append(('05-day', 5, 0x28))
    return out


def renders(streams, locs=None):
    """{name: Display} of every picture (or of the pictures `locs`) with
    every header it is drawn with."""
    by = {s.loc: s for s in streams}
    return {name: render(flat(streams, loc), border, attr)
            for loc in (locs if locs is not None else by) for name, border, attr in headers(by[loc])}


def colours(d):
    """The colour index (0-15) of each pixel of the picture area, row by row."""
    return screen.render(d.data, base=0)[:W * H]


def changed(a, b):
    """{(x, row)} of the pixels whose colour differs between Displays a and b."""
    if a.data[:4096] == b.data[:4096] and a.data[6144:6656] == b.data[6144:6656]:
        return set()
    return {(i % W, i // W) for i, (x, y) in enumerate(zip(colours(a), colours(b))) if x != y}


def differ(a, b):
    """The number of pixels whose colour differs between Displays a and b."""
    return len(changed(a, b))


def trace(x, y, major, minor, n, k):
    """The pixels a line plots from the pen (x, y) and the pen after it: the
    rule of P.draw_line without a screen."""
    out, left = [], k
    while True:
        out.append((x, y))
        x, y, moved = P.step(x, y, major)
        if not moved:
            break
        left -= 1
        if left == 0:
            x, y, moved = P.step(x, y, minor)
            if not moved:
                break
            left = k
        n -= 1
        if n == 0:
            break
    return out, (x, y)


def sheet(path, images, scale=2, gap=4):
    """A PNG of colour-index images (W x H each, lists of 0-15 or RGB tuples)
    side by side."""
    w = len(images) * (W + gap) - gap
    rows = []
    for y in range(H):
        row = []
        for i, im in enumerate(images):
            if i:
                row += [(255, 255, 255)] * gap
            for x in range(W):
                v = im[y * W + x]
                row.append(RGB[v] if isinstance(v, int) else v)
        rows.append([px for px in row for _ in range(scale)])
    rows = [r for r in rows for _ in range(scale)]
    png.write(path, w * scale, H * scale, rows)


def diff_image(a, b):
    """Picture b greyed, its pixels that differ from a in red."""
    out = []
    for x, y in zip(colours(a), colours(b)):
        if x != y:
            out.append((230, 0, 0))
        else:
            r, g, bl = RGB[y]
            v = (r + g + bl) // 3
            out.append((128 + v // 2,) * 3)
    return out
