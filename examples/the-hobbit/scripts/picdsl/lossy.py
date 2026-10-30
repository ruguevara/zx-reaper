"""Lossy: each run of lines (a path from one move) drawn again with the
lines that take the fewest bits, every pixel of the new lines within `tol`
pixels (Chebyshev) of the old path and every old pixel within `tol` of the
new lines; the corners of the new path are pixels of the old one, its ends
are the old ends. A path is replaced only if the pictures that draw it change
in few pixels more (ALLOW per pixel of the path; a gap that lets a fill out
changes thousands) and no square of pixels changes colour (blob). A fill
whose seed the new lines cover is seeded on the nearest pixel of its old
region that is still clear.
"""
import copy

import gamma
import model
import pics
from pics import P

ALLOW = 2           # pixels a path may change per pixel of its own (3 let a door of $01 change colour)


def path(pen, lines):
    """The pixels the lines plot from `pen`, in order, and the pen after them."""
    out = []
    for c in lines:
        px, pen = pics.trace(*pen, *c[1:])
        out += px
    return out, pen


def line_to(a, b):
    """The lines from pen a that end at pen b: [(major, minor, n, k)]."""
    dx, dy = b[0] - a[0], b[1] - a[1]
    if abs(dx) >= abs(dy):
        major, n, minor, m = ('r' if dx > 0 else 'l'), abs(dx), ('u' if dy > 0 else 'd'), abs(dy)
    else:
        major, n, minor, m = ('u' if dy > 0 else 'd'), abs(dy), ('r' if dx > 0 else 'l'), abs(dx)
    if not 1 <= n <= 64:
        return []
    if m == 0:
        return [(major, 'u' if major in 'rl' else 'r', n, n + 1)]
    return [(major, minor, n, k) for k in range(1, 65) if n // k == m]


def near(pixels, others, tol):
    return all(any((x + dx, y + dy) in others for dx in range(-tol, tol + 1) for dy in range(-tol, tol + 1))
               for x, y in pixels)


def bits(c):
    """Bits of a line in gamma.py's code (its type and octant taken as 3)."""
    _, _, n, k = c
    return 3 + gamma.egbits(n - 1, gamma.K['n']) + gamma.egbits(min(k, n + 1) - 1, gamma.K['kk'])


def refit(pen, lines, tol):
    """Lines that take fewer bits for the path the lines draw from `pen`, or None."""
    pts, end = path(pen, lines)
    if end == pts[-1]:
        return None                                 # stopped at the edge: keep it
    verts = pts + [end]
    L = len(pts)
    best = [None] * (L + 1)
    best[0] = (0, None)
    for j in range(1, L + 1):
        fails = 0
        for i in range(j - 1, -1, -1):
            if best[i] is None:
                continue
            got = None
            seg = set(pts[i:j])
            for c in sorted(line_to(verts[i], verts[j]), key=bits):
                px, e = pics.trace(*verts[i], *c)
                if e == verts[j] and near(px, seg, tol) and near(seg, set(px), tol):
                    got = c
                    break
            if got is None:
                fails += 1
                if fails > 8:
                    break
                continue
            fails = 0
            cost = best[i][0] + bits(got)
            if best[j] is None or cost < best[j][0]:
                best[j] = (cost, (i, got))
    if best[L] is None or best[L][0] >= sum(bits(c[1:]) for c in lines):
        return None
    out, j = [], L
    while j:
        i, c = best[j][1]
        out.append(('line',) + c)
        j = i
    return out[::-1]


def chains(commands):
    """[(start index, end index, pen)] of the runs of lines."""
    out, pen, i = [], P.PEN_START, 0
    while i < len(commands):
        c = commands[i]
        if c[0] == 'line':
            j = i
            while j < len(commands) and commands[j][0] == 'line':
                j += 1
            out.append((i, j, pen))
            pen = path(pen, commands[i:j])[1]
            i = j
            continue
        if c[0] == 'move':
            pen = (c[1], c[2])
        i += 1
    return out


def reseed(streams, loc, regions):
    """Stream loc's fills moved off the pixels the new lines cover, onto the
    nearest pixel of their old region that is still clear."""
    s = {t.loc: t for t in streams}[loc]
    d = pics.Canvas()
    P.draw(d, (), s.border, s.attr)
    pen = P.PEN_START
    out = []
    for i, c in enumerate(s.commands):
        if c[0] == 'fill' and P.lit(d, c[2], c[3]) and regions.get((loc, i)):
            clear = [p for p in regions[(loc, i)] if not P.lit(d, *p)]
            if clear:
                x, y = min(clear, key=lambda p: max(abs(p[0] - c[2]), abs(p[1] - c[3])))
                c = ('fill', c[1], x, y)
        out.append(c)
        if c[0] == 'move':
            pen = (c[1], c[2])
        elif c[0] == 'line':
            pen = P.draw_line(d, *pen, *c[1:], 0)
        elif c[0] == 'fill':
            P.flood_fill(d, *c[1:])
        elif c[0] == 'paint':
            P.paint(d, *c[1:])
    s.commands = out


def blob(changed, r):
    """Is there a square of 2r + 1 pixels that all changed colour? A line
    moved by r pixels changes a strip; a region that closes up, a fill that
    gets out or a cell that changes ink changes a block."""
    return any(all((x + dx, y + dy) in changed for dx in range(-r, r + 1) for dy in range(-r, r + 1))
               for x, y in changed)


def simplify(streams, tol):
    """A copy of the streams with the paths refitted; [(loc, lines before,
    after, pixels changed)]. A refit is kept when the pictures change in few
    pixels more, and in no block of pixels (blob)."""
    streams = copy.deepcopy(streams)
    want = pics.renders(streams)
    regions = model.regions(streams)
    report = []
    for s in streams:
        users = pics.users(streams, s.loc)
        diff = {name: 0 for name in pics.renders(streams, users)}
        before = sum(c[0] == 'line' for c in s.commands)
        index = list(range(len(s.commands)))       # the commands' indices before the refits
        for start, end, pen in reversed(chains(s.commands)):
            new = refit(pen, s.commands[start:end], tol)
            if new is None:
                continue
            keep, keep_index = s.commands, index
            s.commands = keep[:start] + new + keep[end:]
            index = index[:start] + [None] * len(new) + index[end:]
            reseed(streams, s.loc, {(s.loc, i): regions[(s.loc, o)] for i, o in enumerate(index)
                                    if (s.loc, o) in regions})
            pixels = len(path(pen, keep[start:end])[0])
            changed = {name: pics.changed(want[name], d) for name, d in pics.renders(streams, users).items()}
            got = {name: len(c) for name, c in changed.items()}
            if all(got[name] <= diff[name] + ALLOW * pixels and not blob(changed[name], tol) for name in got):
                diff = got
            else:
                s.commands, index = keep, keep_index
        report.append((s.loc, before, sum(c[0] == 'line' for c in s.commands), diff[s.loc]))
    return streams, report
