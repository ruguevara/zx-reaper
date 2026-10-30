"""The tokens of model.py as a bit stream with fixed codes: a decoder needs a
bit reader, exp-Golomb codes and a few small tables, no model.

Each picture: its two header bytes (the game pokes those of $05 at dawn),
then the tokens from the next bit:
- the token type in a prefix code chosen by the type before it (TYPES; the
  code lengths are the tables, counted in TABLE_BITS per length);
- line: whether the octant is the one of the line before (in a run of
  lines), else 3 bits; n - 1 and kk in exp-Golomb codes;
- move: dx, dy signed exp-Golomb; amove: x in 8 bits, y in 7;
- fill: ink in 3 bits, dx, dy signed exp-Golomb;
- paint: paper 3 bits, cell 9 bits, the number of runs and each run's
  direction (2 bits) and count - 1 (6 bits);
- copy: back and count - 2; call: the picture (5 bits), start, count - 2;
- then and end: nothing more; the picture ends at the next byte.
The exp-Golomb parameters K are fitted to the pictures (they are constants
of the decoder).
"""
import heapq

TYPES = ['line', 'move', 'amove', 'fill', 'paint', 'end', 'then', 'copy', 'call']
CONTEXTS = {None: 0, 'line': 1, 'move': 2, 'amove': 2}       # the type before -> its code
K = {'n': 3, 'kk': 1, 'move': 2, 'fill': 2, 'back': 3, 'count': 1, 'start': 4}
TABLE_BITS = 4      # bits to store one code length


class Writer:
    def __init__(self):
        self.bits = []

    def put(self, v, n):
        self.bits += [v >> i & 1 for i in range(n - 1, -1, -1)]

    def eg(self, v, k):
        v += 1 << k
        e = v.bit_length() - 1 - k
        self.bits += [0] * e
        self.put(v, e + k + 1)

    def seg(self, v, k):
        self.eg(2 * v if v >= 0 else -2 * v - 1, k)

    def code(self, c):
        self.bits += c

    def bytes(self):
        b = self.bits + [0] * (-len(self.bits) % 8)
        return bytes(int(''.join(map(str, b[i:i + 8])), 2) for i in range(0, len(b), 8))


class Reader:
    def __init__(self, data):
        self.bits = [b >> i & 1 for b in data for i in range(7, -1, -1)]
        self.at = 0

    def get(self, n):
        v = 0
        for _ in range(n):
            v = v << 1 | self.bits[self.at]
            self.at += 1
        return v

    def eg(self, k):
        e = 0
        while not self.bits[self.at]:
            e += 1
            self.at += 1
        return self.get(e + k + 1) - (1 << k)

    def seg(self, k):
        z = self.eg(k)
        return z // 2 if z % 2 == 0 else -(z + 1) // 2

    def code(self, codes):
        c = []
        if len(codes) == 1:
            return next(iter(codes))
        while True:
            c.append(self.get(1))
            for t, cc in codes.items():
                if cc == c:
                    return t


def huffman(counts):
    """Canonical prefix codes {symbol: [bits]} for counts {symbol: n}."""
    syms = [s for s in counts if counts[s]]
    if len(syms) == 1:
        return {syms[0]: [0]}
    heap = [(counts[s], i, [s]) for i, s in enumerate(syms)]
    heapq.heapify(heap)
    length = {s: 0 for s in syms}
    i = len(syms)
    while len(heap) > 1:
        a, _, sa = heapq.heappop(heap)
        b, _, sb = heapq.heappop(heap)
        for s in sa + sb:
            length[s] += 1
        heapq.heappush(heap, (a + b, i, sa + sb))
        i += 1
    codes, code, prev = {}, 0, None
    for s in sorted(syms, key=lambda s: (length[s], TYPES.index(s))):
        if prev is not None:
            code = (code + 1) << (length[s] - prev)
        codes[s] = [code >> j & 1 for j in range(length[s] - 1, -1, -1)]
        prev = length[s]
    return codes


def type_codes(all_tokens):
    """{context: {type: code}} from the type counts in every context, every
    type counted once more so that any order stays possible; but a move is
    always followed by a line (a move starts a path), which takes no bits."""
    counts = {c: {t: 1 for t in TYPES} for c in (0, 1, 3)}
    for toks in all_tokens:
        prev = None
        for t in toks:
            ctx = CONTEXTS.get(prev, 3)
            if ctx == 2:
                if t[0] != 'line':
                    raise ValueError('a move not followed by a line')
            else:
                counts[ctx][t[0]] += 1
            prev = t[0]
    codes = {c: huffman(n) for c, n in counts.items()}
    codes[2] = {'line': []}
    return codes


def tables_size(codes):
    """Bytes to store the code lengths: one per type and context (the
    context after a move has none)."""
    return ((len(codes) - 1) * len(TYPES) * TABLE_BITS + 7) // 8


def encode_stream(w, toks, codes, k=K):
    prev, octant = None, None
    for t in toks:
        w.code(codes[CONTEXTS.get(prev, 3)][t[0]])
        kind = t[0]
        if kind == 'line':
            _, o, n, kk = t
            if prev == 'line':
                w.put(o == octant, 1)
                if o != octant:
                    w.put(o, 3)
            else:
                w.put(o, 3)
            w.eg(n - 1, k['n'])
            w.eg(kk, k['kk'])
            octant = o
        elif kind == 'move':
            w.seg(t[1], k['move'])
            w.seg(t[2], k['move'])
        elif kind == 'amove':
            w.put(t[1], 8)
            w.put(t[2], 7)
        elif kind == 'fill':
            w.put(t[1], 3)
            w.seg(t[2], k['fill'])
            w.seg(t[3], k['fill'])
        elif kind == 'paint':
            w.put(t[1], 3)
            w.put(t[2], 9)
            w.eg(len(t[3]) - 1, 0)
            for d, count in t[3]:
                w.put('urdl'.index(d), 2)
                w.put(count - 1, 6)
        elif kind == 'copy':
            w.eg(t[1] - 1, k['back'])
            w.eg(t[2] - 2, k['count'])
        elif kind == 'call':
            w.put(t[1], 5)
            w.eg(t[2], k['start'])
            w.eg(t[3] - 2, k['count'])
        prev = kind


def decode_stream(r, codes, k=K):
    out, prev, octant = [], None, None
    while True:
        kind = r.code(codes[CONTEXTS.get(prev, 3)])
        if kind == 'line':
            if prev == 'line' and r.get(1):
                o = octant
            else:
                o = r.get(3)
            n = r.eg(k['n']) + 1
            t = (kind, o, n, r.eg(k['kk']))
            octant = o
        elif kind == 'move':
            t = (kind, r.seg(k['move']), r.seg(k['move']))
        elif kind == 'amove':
            t = (kind, r.get(8), r.get(7))
        elif kind == 'fill':
            t = (kind, r.get(3), r.seg(k['fill']), r.seg(k['fill']))
        elif kind == 'paint':
            paper, cell, n = r.get(3), r.get(9), r.eg(0) + 1
            t = (kind, paper, cell, tuple(('urdl'[r.get(2)], r.get(6) + 1) for _ in range(n)))
        elif kind == 'copy':
            t = (kind, r.eg(k['back']) + 1, r.eg(k['count']) + 2)
        elif kind == 'call':
            t = (kind, r.get(5), r.eg(k['start']), r.eg(k['count']) + 2)
        else:
            t = (kind,)
        out.append(t)
        if kind in ('end', 'then'):
            return out
        prev = kind


def encode(streams, all_tokens, k=K):
    """[bytes] of each picture and the type codes."""
    codes = type_codes(all_tokens)
    out = []
    for s, toks in zip(streams, all_tokens):
        w = Writer()
        w.put(s.border, 8)
        w.put(s.attr, 8)
        encode_stream(w, toks, codes, k)
        out.append(w.bytes())
    return out, codes


def decode(blobs, codes, k=K):
    out = []
    for b in blobs:
        r = Reader(b)
        r.get(16)
        out.append(decode_stream(r, codes, k))
    return out


def token_bits(t, k=K):
    """Bits of a token's fields (its type code not counted), for the parsers."""
    kind = t[0]
    if kind == 'line':
        return 2 + egbits(t[2] - 1, k['n']) + egbits(t[3], k['kk'])
    if kind == 'move':
        return sbits(t[1], k['move']) + sbits(t[2], k['move'])
    if kind == 'amove':
        return 15
    if kind == 'fill':
        return 3 + sbits(t[2], k['fill']) + sbits(t[3], k['fill'])
    if kind == 'paint':
        return 12 + egbits(len(t[3]) - 1, 0) + 8 * len(t[3])
    if kind == 'copy':
        return egbits(t[1] - 1, k['back']) + egbits(t[2] - 2, k['count'])
    if kind == 'call':
        return 5 + egbits(t[2], k['start']) + egbits(t[3] - 2, k['count'])
    return 0


def egbits(v, k):
    return 2 * ((v + (1 << k)).bit_length() - 1 - k) + 1 + k


def sbits(v, k):
    return egbits(2 * v if v >= 0 else -2 * v - 1, k)
