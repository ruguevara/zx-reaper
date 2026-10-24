#!/usr/bin/env python3
"""The location pictures as SVG (docs/09-vector.md): docs/img/vector-NN.svg.

The commands are drawn by game/hobbit/pictures.py, as in the game, and each
one is also turned into a shape:
- the lines that go on from each other are one path through the centres
  of their pixels, simplified (Douglas-Peucker);
- a fill has no shape in the data, only a seed: the pixels it lit, grown by
  half a pixel into the lit pixels around them, so that the edge runs along
  the centres of the pixels that bound it, where the lines are drawn, are
  traced into closed outlines and simplified the same way; a fill seeded on
  a lit pixel only re-inks its cells, and is the lit pixels of those cells;
- the paper is the cells' rectangles, as they are at the end.
The SVG has the paper, then the fills, then the lines, each in its own
colour: no attribute clash. Needs game/assets/pictures/ (make
game/assets/state.json).
Usage: python3 scripts/vector.py [OUTDIR]       (default docs/img)
"""
import itertools
import math
import os
import sys

sys.path.insert(0, 'game')
from hobbit import pictures as P  # noqa: E402
from zxpyxel.display import Display  # noqa: E402
from zxpyxel.screen import rgb  # noqa: E402

W, H = 256, 128
COLOURS = ['#%06X' % c for c in rgb()[:8]]
EPS = 1.0       # px a line or an outline may move when simplified: a 1-pixel staircase becomes straight
NEAR = [(dx, dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1)]


class Canvas(Display):
    """A Display that lists the pixels plotted on it (x, row from the top)."""
    def __init__(self):
        super().__init__()
        self.plots = []

    def plot(self, x, y):
        self.plots.append((x, y))
        super().plot(x, y)


def paper(d, x, row):
    return d.attr(x >> 3, row >> 3) >> 3 & 7


def ink(d, colour, x, row):
    """PlotPixel: an ink equal to the paper becomes 7 - ink."""
    return colour ^ 7 if colour == paper(d, x, row) else colour


def grown(new, lit):
    """The pixels `new` on a grid of half pixels, grown by one half pixel into
    the pixels of `lit` around them and past the edges of the area (the SVG
    cuts it there)."""
    def bound(x, y):
        return (x, y) in lit or not (0 <= x < W and 0 <= y < H)
    half = {(2 * x + i, 2 * y + j) for x, y in new for i in (0, 1) for j in (0, 1)}
    return half | {(hx + dx, hy + dy) for hx, hy in half for dx, dy in NEAR
                   if bound((hx + dx) >> 1, (hy + dy) >> 1)}


def outlines(pixels):
    """The closed loops of corner points between `pixels` and the rest, each
    pixel a unit square, clockwise on screen: holes come out the other way
    round, so they stay holes with the nonzero fill rule."""
    nxt = {}
    for x, y in pixels:
        for (ax, ay), (bx, by), n in (((x, y), (x + 1, y), (x, y - 1)),
                                      ((x + 1, y), (x + 1, y + 1), (x + 1, y)),
                                      ((x + 1, y + 1), (x, y + 1), (x, y + 1)),
                                      ((x, y + 1), (x, y), (x - 1, y))):
            if n not in pixels:
                nxt.setdefault((ax, ay), []).append((bx, by))
    loops = []
    while nxt:
        start = p = next(iter(nxt))
        loop = []
        while True:     # every corner has as many edges in as out, so the walk ends at start
            loop.append(p)
            q = nxt[p].pop()
            if not nxt[p]:
                del nxt[p]
            p = q
            if p == start:
                break
        loops.append(loop)
    return loops


def simplify(pts, eps):
    """Douglas-Peucker on an open run of points, both ends kept."""
    keep = {0, len(pts) - 1}
    todo = [(0, len(pts) - 1)]
    while todo:
        i, j = todo.pop()
        (ax, ay), (bx, by) = pts[i], pts[j]
        n = math.hypot(bx - ax, by - ay)
        best, k = 0, 0
        for m in range(i + 1, j):
            px, py = pts[m]
            dist = (abs((bx - ax) * (py - ay) - (by - ay) * (px - ax)) / n if n
                    else math.hypot(px - ax, py - ay))      # a closed run: from its ends
            if dist > best:
                best, k = dist, m
        if best > eps:
            keep.add(k)
            todo += [(i, k), (k, j)]
    return [pts[m] for m in sorted(keep)]


def simplify_loop(loop, eps):
    """A closed loop cut at its first point and the point farthest from it;
    one that would collapse to a line is kept as it is."""
    x0, y0 = loop[0]
    far = max(range(len(loop)), key=lambda m: (loop[m][0] - x0) ** 2 + (loop[m][1] - y0) ** 2)
    out = simplify(loop[:far + 1], eps)[:-1] + simplify(loop[far:] + loop[:1], eps)[:-1]
    return out if len(out) >= 3 else loop


def num(v):
    return '%g' % v


def strokes(chains, colour):
    """(colour, points) paths: the centres of the pixels of each chain of
    lines, in order, cut halfway between two pixels where the colour changes,
    and simplified as the fills are. The pixels, not the slopes stored: a
    line of 57 steps with one step up every 57 is a row of 57 pixels, the
    step up comes after it, and the fills are bounded by those pixels."""
    out = []
    for chain in chains:
        run = prev = None
        for p in itertools.chain(*chain):
            if run and run[0] == colour[p]:
                run[1].append(p)
            else:
                mid = [((prev[0] + p[0]) / 2, (prev[1] + p[1]) / 2)] if run else []
                if run:
                    run[1].extend(mid)
                run = (colour[p], mid + [p])
                out.append(run)
            prev = p
    return [(c, simplify(pts, EPS)) for c, pts in out]


def svg(commands, border, attr):
    d = Canvas()
    P.draw(d, (), border, attr)
    lit, fills, chains = set(), [], []
    colour = {}         # a pixel of a line -> the colour it shows
    x, y = P.PEN_START
    chain = None        # the lines from one pen, while no move comes between
    for c in commands:
        d.plots = []
        if c[0] == 'move':
            x, y = c[1], c[2]
            chain = None
        elif c[0] == 'line':
            x, y = P.draw_line(d, x, y, c[1], c[2], c[3], c[4], 0)
            colour.update((p, ink(d, 0, *p)) for p in d.plots)
            if chain is None:
                chain = []
                chains.append(chain)
            chain.append(d.plots)
        elif c[0] == 'fill':
            fill = ink(d, c[1], c[2], P.TOP - c[3])
            P.flood_fill(d, c[1], c[2], c[3])
            new = set(d.plots) - lit
            if new:
                fills.append((fill, grown(new, lit)))
                # a line that bounds a later fill was drawn for it: the fill's ink
                # colours its cells, so on the Spectrum the line shows in the fill's colour
                for px, py in new:
                    for n in ((px + 1, py), (px - 1, py), (px, py + 1), (px, py - 1)):
                        if n in colour:
                            colour[n] = fill
            else:
                # seeded on a lit pixel: it only gives the cells it plotted in its
                # ink, and everything lit in them shows in it (the spire of $27)
                cells = {(px >> 3, py >> 3) for px, py in d.plots}
                inked = {p for p in lit if (p[0] >> 3, p[1] >> 3) in cells}
                fills.append((fill, grown(inked, lit)))
                colour.update((p, fill) for p in inked & colour.keys())
        else:
            P.paint(d, c[1], c[2], c[3])
        lit.update(d.plots)

    out = ['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" width="%d" height="%d">'
           % (W, H, W * 2, H * 2), '<g shape-rendering="crispEdges">']
    for row in range(16):
        col = 0
        while col < 32:
            end = col
            while end < 32 and paper(d, end * 8, row * 8) == paper(d, col * 8, row * 8):
                end += 1
            out.append('<rect x="%d" y="%d" width="%d" height="8" fill="%s"/>'
                       % (col * 8, row * 8, (end - col) * 8, COLOURS[paper(d, col * 8, row * 8)]))
            col = end
    out.append('</g>')
    for fill, halves in fills:
        loops = [simplify_loop(lp, 2 * EPS) for lp in outlines(halves)]
        out.append('<path fill="%s" d="%s"/>' % (COLOURS[fill], ' '.join(
            'M' + ' '.join(num(hx / 2) + ' ' + num(hy / 2) for hx, hy in lp) + 'Z' for lp in loops)))
    out.append('<g fill="none" stroke-width="1" stroke-linecap="round" stroke-linejoin="round">')
    for stroke, pts in strokes(chains, colour):
        out.append('<path stroke="%s" d="M%s"/>' % (COLOURS[stroke], ' '.join(
            num(px + 0.5) + ' ' + num(py + 0.5) for px, py in pts)))
    out.append('</g></svg>\n')
    return '\n'.join(out)


def check():
    """A ring (a square with a hole) traces to two loops, the hole the other
    way round; a 1-pixel staircase simplifies to its two ends; a closed run
    keeps its corners."""
    ring = {(x, y) for x in range(4) for y in range(4)} - {(1, 1), (2, 1), (1, 2), (2, 2)}
    loops = sorted(outlines(ring), key=len)
    area = [sum(ax * by - bx * ay for (ax, ay), (bx, by) in zip(lp, lp[1:] + lp[:1])) / 2 for lp in loops]
    assert len(loops) == 2 and area == [-4, 16], area
    stairs = [(i // 2 + i % 2, i // 2) for i in range(9)]
    assert simplify(stairs, EPS) == [stairs[0], stairs[-1]]
    square = [(0, 0), (4, 0), (4, 4), (0, 4), (0, 0)]
    assert simplify(square, EPS) == square


def main(outdir='docs/img'):
    check()
    pics = P.pictures()
    jobs = [('%02X' % loc, p.commands, p.border, p.attr) for loc, p in sorted(pics.items())]
    jobs.append(('05-day', pics[P.TROLLS_CLEARING].commands, 5, 0x28))     # after dawn (LA94E_0)
    for name, commands, border, attr in jobs:
        with open(os.path.join(outdir, 'vector-%s.svg' % name), 'w') as f:
            f.write(svg(commands, border, attr))
    print('%d pictures written to %s' % (len(jobs), outdir))


if __name__ == '__main__':
    main(*sys.argv[1:])
