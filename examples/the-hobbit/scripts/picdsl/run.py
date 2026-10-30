#!/usr/bin/env python3
"""Smaller pictures (docs/10-smaller-pictures.md): every approach applied to
the 22 pictures of src/pictures.asm, decoded back, drawn by stage 4's
interpreter and compared with the original drawing (23 drawings: $05 also
after dawn). Prints the sizes, writes OUTDIR/results.md and, per picture,
OUTDIR/compare-NN.png: original | 1 pixel | its difference | 2 pixels | its
difference (the differing pixels in red).

Usage: python3 scripts/picdsl/run.py [OUTDIR] [--docs]     (default build/picdsl)
--docs also writes docs/img/smaller-NN.png for the pictures in DOCS.
Takes a few minutes: the parsers and the refits are plain Python.
"""
import os
import sys

import clean
import gamma
import lossy
import lz
import model
import orig
import pics
import rc
import reuse

DOCS = [0x01, 0x06, 0x26, 0x1A]
TOLERANCES = (1, 2)


def say(*a):
    print(*a, file=sys.stderr, flush=True)


def coded(streams, toks):
    """Sizes of the tokens: fixed codes (with their tables), with reuse, and
    the range coder per picture and as one stream; each decoded and checked."""
    blobs, codes = gamma.encode(streams, toks)
    if gamma.decode(blobs, codes) != toks:
        raise AssertionError('gamma: decoded tokens differ')
    plain = sum(map(len, blobs)) + gamma.tables_size(codes)
    reused = reuse.parse(toks, *reuse.gamma_costs(toks))
    reused = reuse.parse(toks, *reuse.gamma_costs(reused, codes=gamma.type_codes(reused)))
    if any(model.expand(reused, i) != toks[i] for i in range(len(toks))):
        raise AssertionError('reuse: copies do not give the tokens back')
    blobs, codes = gamma.encode(streams, reused)
    if gamma.decode(blobs, codes) != reused:
        raise AssertionError('gamma: decoded tokens differ')
    with_reuse = sum(map(len, blobs)) + gamma.tables_size(codes)
    sizes = {'fixed': plain, 'reuse': with_reuse}
    for shared in (False, True):
        b = rc.encode(reused, shared)
        if rc.decode(b, shared) != reused:
            raise AssertionError('rc: decoded tokens differ')
        sizes['rc one' if shared else 'rc each'] = sum(map(len, b)) + 2 * len(streams)
    sizes['copies'] = sum(t[0] == 'copy' for ts in reused for t in ts)
    sizes['loops'] = sum(t[0] == 'copy' and t[1] < t[2] for ts in reused for t in ts)
    sizes['calls'] = sum(t[0] == 'call' for ts in reused for t in ts)
    sizes['each'] = {s.loc: len(b) + 2 for s, b in zip(streams, rc.encode(reused))}
    return sizes


def drawn(streams, toks, want):
    """{name: pixels that differ from `want`} of the pictures the tokens draw."""
    got = pics.renders(model.commands(streams, toks))
    return {k: pics.differ(want[k], got[k]) for k in want}, got


def main(outdir='build/picdsl', docs=False):
    os.makedirs(outdir, exist_ok=True)
    original = pics.load()
    want = pics.renders(original)
    data = pics.original_bytes()
    if b''.join(orig.encode(s) for s in original) != data:
        raise AssertionError('orig: the pictures do not encode to their bytes')
    rows = [('Original format', len(data), 0, 'the tape')]

    say('ZX0 ...')
    rows.append(('ZX0, all pictures in one block', lz.size(data), 0,
                 'needs a 10K buffer: no use in 48K'))
    rows.append(('ZX0, each picture', sum(lz.size(orig.encode(s)) for s in original), 0,
                 'unpacked into a 778-byte buffer'))

    say('clean ...')
    cleaned, info = clean.clean(original)
    rows.append(('Cleaned, original format', sum(len(orig.encode(s)) for s in cleaned), 0,
                 '%(moves dropped)d dead moves, %(lines merged)d line pairs merged, '
                 '%(idle dropped)d idle commands' % info))
    rows.append(('Cleaned, ZX0 each picture', sum(lz.size(orig.encode(s)) for s in cleaned), 0, ''))

    say('tokens ...')
    toks = model.tokens(cleaned)
    diff, _ = drawn(cleaned, toks, want)
    if any(diff.values()):
        raise AssertionError('tokens: a picture changed: %s' % diff)
    sizes = coded(cleaned, toks)
    rows += [('Tokens, fixed codes', sizes['fixed'], 0, 'relative moves and fill seeds, canonical lines'),
             ('Tokens + reuse, fixed codes', sizes['reuse'], 0,
              '%(copies)d copies (%(loops)d loops), %(calls)d calls' % sizes),
             ('Tokens + reuse, range coder, each picture', sizes['rc each'], 0, ''),
             ('Tokens + reuse, range coder, one stream', sizes['rc one'], 0,
              'drawing a picture decodes all before it')]
    each = {'original': {s.loc: len(orig.encode(s)) for s in original}, 'lossless': sizes['each']}

    images = {}
    for tol in TOLERANCES:
        say('lossy, %d pixel ...' % tol)
        simple, report = lossy.simplify(cleaned, tol)
        toks = model.tokens(simple)
        diff, got = drawn(simple, toks, want)
        images[tol] = got
        sizes = coded(simple, toks)
        lines = sum(r[2] for r in report), sum(r[1] for r in report)
        worst = max(diff, key=diff.get)
        name = worst if isinstance(worst, str) else '%02X' % worst
        note = '%d of %d lines; worst %s: %d pixels' % (lines[0], lines[1], name, diff[worst])
        total = sum(diff.values())
        rows += [('Refit %d px, fixed codes + reuse' % tol, sizes['reuse'], total, note),
                 ('Refit %d px, range coder, each picture' % tol, sizes['rc each'], total, ''),
                 ('Refit %d px, range coder, one stream' % tol, sizes['rc one'], total, '')]
        each['%d px' % tol] = sizes['each']

    area = 256 * 128 * len(want)
    out = ['| Approach | Bytes | Saved | Pixels changed | Notes |', '| --- | ---: | ---: | ---: | --- |']
    for name, size, px, note in rows:
        changed = '%d (%.2f%%)' % (px, 100 * px / area) if px else '0'
        out.append('| %s | %d | %.1f%% | %s | %s |' % (name, size, 100 * (1 - size / len(data)), changed, note))
    out += ['', '| Picture | Original | Lossless (rc) | 1 px (rc) | 2 px (rc) |', '| --- | ---: | ---: | ---: | ---: |']
    for s in original:
        sizes = [str(each[k][s.loc]) for k in ('original', 'lossless', '1 px', '2 px')]
        out.append('| %02X | %s |' % (s.loc, ' | '.join(sizes)))
    text = '\n'.join(out) + '\n'
    with open(os.path.join(outdir, 'results.md'), 'w') as f:
        f.write(text)
    print(text)

    for s in original:
        panels = [pics.colours(want[s.loc])]
        for tol in TOLERANCES:
            panels += [pics.colours(images[tol][s.loc]), pics.diff_image(want[s.loc], images[tol][s.loc])]
        pics.sheet(os.path.join(outdir, 'compare-%02X.png' % s.loc), panels, scale=1)
        if docs and s.loc in DOCS:
            pics.sheet(os.path.join(pics.ROOT, 'docs', 'img', 'smaller-%02X.png' % s.loc), panels, scale=1)


if __name__ == '__main__':
    args = [a for a in sys.argv[1:] if a != '--docs']
    main(*args, docs='--docs' in sys.argv[1:])
