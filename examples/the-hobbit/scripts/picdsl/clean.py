"""Rewrites of the command lists that leave every final picture the same,
pixel for pixel and attribute for attribute (each one checked by drawing
every picture that runs through the stream):
- a move that no line uses (another move comes first) is dropped, and so is
  a move to where the pen already is;
- two lines in a row become one when a single line plots the same pixels
  and leaves the pen in the same place;
- a line that plots only pixels already lit, or a fill that lights nothing
  new, is dropped when the pictures stay the same without it.
"""
import copy

import pics
from pics import P


def same(streams, locs, want):
    """Do the pictures `locs` draw as `want` (their Displays)?"""
    got = pics.renders(streams, locs)
    return all(got[name] == want[name] for name in got)


def dead_moves(flat):
    """Indices of moves in a flat list that no line uses: a move to where the
    pen is, a move followed by another before any line."""
    out, pending, pen = set(), None, P.PEN_START
    for i, c in enumerate(flat):
        if c[0] == 'move':
            if (c[1], c[2]) == pen:
                out.add(i)
                continue
            if pending is not None:
                out.add(pending)
            pending, pen = i, (c[1], c[2])
        elif c[0] == 'line':
            pending = None
            pen = pics.trace(*pen, *c[1:])[1]
    if pending is not None:
        out.add(pending)
    return out


def drop_moves(streams):
    for s in streams:
        dead = None
        for user, flat, off in pics.placements(streams, s.loc):
            d = {i - off for i in dead_moves(flat) if off <= i < off + len(s.commands)}
            dead = d if dead is None else dead & d
        s.commands = [c for i, c in enumerate(s.commands) if i not in dead]


def merged(pen, a, b):
    """A single line that plots what lines a then b plot from `pen` and ends
    where they end, or None."""
    pa, end = pics.trace(*pen, *a[1:])
    pb, end = pics.trace(*end, *b[1:])
    want = set(pa) | set(pb)
    n = len(pa) + len(pb)
    if n > 64:
        return None
    for major in 'rlud':
        for minor in ('ud' if major in 'rl' else 'rl'):
            for k in range(1, 65):
                c = ('line', major, minor, n, k)
                px, e = pics.trace(*pen, *c[1:])
                if e == end and set(px) == want:
                    return c
    return None


def merge_lines(streams):
    """Two lines in a row into one where that is exact (the pen from the
    stream's first move on; a stream entered by 'then' starts with a move)."""
    n = 0
    for s in streams:
        out, pen, start = [], P.PEN_START, None       # start: the pen before out[-1]
        for c in s.commands:
            if c[0] == 'line' and out and out[-1][0] == 'line':
                m = merged(start, out[-1], c)
                if m:
                    out[-1] = m
                    n += 1
                    pen = pics.trace(*start, *m[1:])[1]
                    continue
            if c[0] == 'line':
                start = pen
                pen = pics.trace(*pen, *c[1:])[1]
            elif c[0] == 'move':
                pen = (c[1], c[2])
            out.append(c)
        s.commands = out
    return n


def idle(streams, loc):
    """Indices of stream loc's lines that plot only lit pixels and fills that
    light nothing, in every picture that draws it."""
    by = {s.loc: s for s in streams}
    out = None
    for user, flat, off in pics.placements(streams, loc):
        found = {i - off for i, c, plotted, lit in pics.steps(flat, by[user].border, by[user].attr)
                 if c[0] in ('line', 'fill') and plotted <= lit and off <= i < off + len(by[loc].commands)}
        out = found if out is None else out & found
    return out


def drop_idle(streams, want):
    n = 0
    for s in streams:
        users = pics.users(streams, s.loc)
        for i in sorted(idle(streams, s.loc), reverse=True):
            keep = s.commands
            s.commands = keep[:i] + keep[i + 1:]
            if same(streams, users, want):
                n += 1
            else:
                s.commands = keep
    return n


def clean(streams):
    """A copy of the streams with the rewrites above, and what they did."""
    streams = copy.deepcopy(streams)
    want = pics.renders(streams)
    before = sum(len(s.commands) for s in streams)
    drop_moves(streams)
    moves = before - sum(len(s.commands) for s in streams)
    lines = merge_lines(streams)
    idle_n = drop_idle(streams, want)
    drop_moves(streams)
    if pics.renders(streams) != want:
        raise AssertionError('clean: a picture changed')
    return streams, {'moves dropped': moves, 'lines merged': lines, 'idle dropped': idle_n}
