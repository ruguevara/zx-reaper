"""The new drawing DSL: the commands as tokens that depend on the pen, so a
shape drawn twice in different places is the same run of tokens.

  ('line', o, n, kk)        n pixels in octant o (OCTANTS), a minor step after
                            every kk + 1; kk = n is straight (no minor step)
  ('move', dx, dy)          the pen moves by (dx, dy)
  ('amove', x, y)           the pen to (x, y)
  ('fill', ink, dx, dy)     flood fill seeded at the pen + (dx, dy)
  ('paint', paper, cell, runs)
  ('then',)                 go on with the next picture's tokens (its header skipped)
  ('end',)
  ('copy', back, count)     the `count` tokens that start `back` tokens back
                            (they may overlap the copy: a loop)
  ('call', stream, start, count)   tokens start.. of another picture

The tokens are made from the command lists with three choices that keep every
picture the same:
- a line is written in its canonical octant (a straight line in the
  horizontal-major or vertical-major octant with the minor step up or right,
  a diagonal one as horizontal-major), only where it plots the same pixels;
- a fill's seed is any pixel of the region it fills (the scan-line fill
  fills the same runs from any of them): the one nearest the pen, in the
  region it fills in every picture that draws the stream;
- a move is relative when that is shorter in the gamma code (gamma.py).
"""
import gamma
import pics
from pics import P

OCTANTS = [('r', 'u'), ('r', 'd'), ('l', 'u'), ('l', 'd'), ('u', 'r'), ('u', 'l'), ('d', 'r'), ('d', 'l')]
OCTANT = {d: i for i, d in enumerate(OCTANTS)}


def relative_move(dx, dy):
    """Is a relative move shorter than an absolute one (15 bits) in gamma.py?"""
    return gamma.sbits(dx, gamma.K['move']) + gamma.sbits(dy, gamma.K['move']) < 15


def base(token):
    """The command of a line token."""
    _, o, n, kk = token
    major, minor = OCTANTS[o]
    return ('line', major, minor, n, kk + 1)


def canonical(pen, c):
    """The line token of command c drawn from `pen`."""
    _, major, minor, n, k = c
    kk = min(k, n + 1) - 1
    want = pics.trace(*pen, major, minor, n, kk + 1)
    if kk == n:
        alt = [(major, 'u' if major in 'rl' else 'r')]
    elif kk == 0 and major in 'ud':
        alt = [(minor, major)]
    else:
        alt = []
    for a in alt:
        if pics.trace(*pen, *a, n, kk + 1) == want:
            return ('line', OCTANT[a], n, kk)
    return ('line', OCTANT[(major, minor)], n, kk)


def regions(streams):
    """{(stream loc, command index): set of seeds} for every fill: the pixels
    it lights in every picture that draws it (empty when it lights nothing
    new: then only its own seed will do)."""
    by = {s.loc: s for s in streams}
    out = {}
    for s in streams:
        for user, flat, off in pics.placements(streams, s.loc):
            for i, c, plotted, lit in pics.steps(flat, by[user].border, by[user].attr):
                if c[0] == 'fill' and off <= i < off + len(s.commands):
                    key, new = (s.loc, i - off), plotted - lit
                    out[key] = new if key not in out else out[key] & new
    return out


def seed(region, pen, own):
    """The seed nearest the pen (Chebyshev, then the sum)."""
    if not region:
        return own
    px, py = pen
    return min(region, key=lambda p: (max(abs(p[0] - px), abs(p[1] - py)),
                                      abs(p[0] - px) + abs(p[1] - py), p))


def tokens(streams, relocate=True):
    """[[token]] of each stream (the order of `streams`)."""
    reg = regions(streams) if relocate else {}
    out = []
    for s in streams:
        toks, pen = [], P.PEN_START
        for i, c in enumerate(s.commands):
            if c[0] == 'move':
                dx, dy = c[1] - pen[0], c[2] - pen[1]
                toks.append(('move', dx, dy) if relative_move(dx, dy) else ('amove', c[1], c[2]))
                pen = (c[1], c[2])
            elif c[0] == 'line':
                t = canonical(pen, c)
                toks.append(t)
                pen = pics.trace(*pen, *base(t)[1:])[1]
            elif c[0] == 'fill':
                sx, sy = seed(reg.get((s.loc, i)), pen, (c[2], c[3]))
                toks.append(('fill', c[1], sx - pen[0], sy - pen[1]))
            elif c[0] == 'paint':
                toks.append(('paint', c[1], c[2], tuple(c[3])))
            else:
                toks.append(('then',))
        if not toks or toks[-1] != ('then',):
            toks.append(('end',))
        out.append(toks)
    return out


def text(toks, locs):
    """The tokens one per line, in the words of game/assets/pictures/NN.txt
    where they are the same; `locs`: the location id of each stream."""
    out = []
    for t in toks:
        kind = t[0]
        if kind == 'line':
            major, minor = OCTANTS[t[1]]
            out.append('line %s%s %d %s' % (major, minor, t[2], 'straight' if t[3] == t[2] else t[3] + 1))
        elif kind == 'move':
            out.append('move %+d %+d' % t[1:])
        elif kind == 'amove':
            out.append('move to %d %d' % t[1:])
        elif kind == 'fill':
            out.append('fill %d %+d %+d' % t[1:])
        elif kind == 'paint':
            out.append('paint %d %d %d %s' % (t[1], t[2] & 31, t[2] >> 5, ' '.join('%s%d' % r for r in t[3])))
        elif kind == 'copy':
            out.append('copy %d back, %d' % t[1:] + (' (a loop)' if t[1] < t[2] else ''))
        elif kind == 'call':
            out.append('call %02X from %d, %d' % (locs[t[1]], t[2], t[3]))
        else:
            out.append(kind)
    return '\n'.join(out)


def expand(all_tokens, i):
    """Stream i's tokens with copies and calls replaced by what they copy."""
    out = []
    for t in all_tokens[i]:
        if t[0] == 'copy':
            for _ in range(t[2]):
                out.append(out[-t[1]])
        elif t[0] == 'call':
            out += expand(all_tokens, t[1])[t[2]:t[2] + t[3]]
        else:
            out.append(t)
    return out


def commands(streams, all_tokens):
    """New Streams (loc, header of `streams`) whose commands the tokens draw."""
    out = []
    for i, s in enumerate(streams):
        cmds, pen = [], P.PEN_START
        for t in expand(all_tokens, i):
            if t[0] == 'move':
                pen = (pen[0] + t[1], pen[1] + t[2])
                cmds.append(('move',) + pen)
            elif t[0] == 'amove':
                pen = (t[1], t[2])
                cmds.append(('move',) + pen)
            elif t[0] == 'line':
                c = base(t)
                cmds.append(c)
                pen = pics.trace(*pen, *c[1:])[1]
            elif t[0] == 'fill':
                cmds.append(('fill', t[1], pen[0] + t[2], pen[1] + t[3]))
            elif t[0] == 'paint':
                cmds.append(('paint', t[1], t[2], list(t[3])))
            elif t[0] == 'then':
                cmds.append(('then', streams[i + 1].loc))
        out.append(pics.Stream(s.loc, s.border, s.attr, cmds))
    return out
