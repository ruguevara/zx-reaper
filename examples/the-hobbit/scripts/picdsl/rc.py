"""The tokens of model.py through an adaptive binary range coder (LZMA's:
11-bit probabilities, 32-bit range), each field bit coded with a probability
that learns from the bits coded before it in the same context:
- the type: a bit tree chosen by the type before (none after a move);
- line: in a run of lines, whether the octant is the one before, else the
  octant in a bit tree chosen by the octant before; n - 1 in adaptive
  exp-Golomb, kk too with its probabilities chosen by the size of n;
- move, fill offsets, copy and call numbers: adaptive exp-Golomb (the
  unary length and each following bit with its own probability);
- amove, paint and the rest: bit trees.
Per picture (each picture alone, the probabilities start at 1/2) or one
stream (picture after picture, as stored: drawing one decodes all the
pictures before it). The two header bytes stay outside the coded stream.
"""
import gamma

BITS, MOVE = 11, 3          # probability bits; adaptation shift (fast: the pictures are short)
TOP = 1 << 24


class Encoder:
    def __init__(self):
        self.low, self.range, self.cache, self.size = 0, 0xFFFFFFFF, 0, 1
        self.out = bytearray()
        self.p = {}

    def bit(self, ctx, b):
        p = self.p.get(ctx, 1 << (BITS - 1))
        bound = (self.range >> BITS) * p
        if b:
            self.low += bound
            self.range -= bound
            p -= p >> MOVE
        else:
            self.range = bound
            p += ((1 << BITS) - p) >> MOVE
        self.p[ctx] = p
        while self.range < TOP:
            self.range = (self.range << 8) & 0xFFFFFFFF
            self.shift()
        return b

    def shift(self):
        if self.low < 0xFF000000 or self.low >= 1 << 32:
            carry = self.low >> 32
            temp = self.cache
            while True:
                self.out.append((temp + carry) & 0xFF)
                temp = 0xFF
                self.size -= 1
                if not self.size:
                    break
            self.cache = (self.low >> 24) & 0xFF
        self.size += 1
        self.low = (self.low & 0x00FFFFFF) << 8

    def finish(self):
        for _ in range(5):
            self.shift()
        return bytes(self.out[1:])         # the first byte is always 0


class Decoder:
    def __init__(self, data):
        self.data, self.at = data, 0
        self.range, self.code = 0xFFFFFFFF, 0
        for _ in range(4):
            self.code = self.code << 8 | self.byte()
        self.p = {}

    def byte(self):
        b = self.data[self.at] if self.at < len(self.data) else 0      # zeros past the end
        self.at += 1
        return b

    def bit(self, ctx, _=None):
        p = self.p.get(ctx, 1 << (BITS - 1))
        bound = (self.range >> BITS) * p
        if self.code < bound:
            self.range = bound
            p += ((1 << BITS) - p) >> MOVE
            b = 0
        else:
            self.code -= bound
            self.range -= bound
            p -= p >> MOVE
            b = 1
        self.p[ctx] = p
        while self.range < TOP:
            self.range = (self.range << 8) & 0xFFFFFFFF
            self.code = (self.code << 8 | self.byte()) & 0xFFFFFFFF
        return b


def size_class(n):
    return 0 if n < 3 else 1 if n < 5 else 2 if n < 9 else 3 if n < 17 else 4


class Model:
    """The fields of the tokens as bits in contexts, for an Encoder (values
    given) or a Decoder (values read)."""
    def __init__(self, coder):
        self.c = coder

    def tree(self, ctx, nbits, v=None):
        node = 1
        for i in range(nbits - 1, -1, -1):
            b = self.c.bit((ctx, node), None if v is None else v >> i & 1)
            node = node * 2 + b
        return node - (1 << nbits)

    def eg(self, ctx, v=None):
        """v >= 0: the length of v + 1 in unary, then its bits below the top."""
        e = 0
        if v is not None:
            v += 1
            top = v.bit_length() - 1
            for i in range(top):
                self.c.bit((ctx, 'u', i), 1)
            self.c.bit((ctx, 'u', top), 0)
            for i in range(top - 1, -1, -1):
                self.c.bit((ctx, 'm', top, i), v >> i & 1)
            return v - 1
        while self.c.bit((ctx, 'u', e)):
            e += 1
        v = 1
        for i in range(e - 1, -1, -1):
            v = v << 1 | self.c.bit((ctx, 'm', e, i))
        return v - 1

    def seg(self, ctx, v=None):
        z = self.eg(ctx, None if v is None else (2 * v if v >= 0 else -2 * v - 1))
        return z // 2 if z % 2 == 0 else -(z + 1) // 2

    def stream(self, toks=None):
        """Code the tokens (or read them when toks is None)."""
        out, prev, octant = [], None, None
        it = iter(toks or ())
        while True:
            t = next(it) if toks is not None else None
            if prev in ('move', 'amove'):
                kind = 'line'
            else:
                kind = gamma.TYPES[self.tree(('type', prev), 4, None if t is None else gamma.TYPES.index(t[0]))]
            v = (lambda i: None if t is None else t[i])
            if kind == 'line':
                if prev == 'line' and self.c.bit('same', None if t is None else int(t[1] == octant)):
                    o = octant
                else:
                    o = self.tree(('octant', octant if prev == 'line' else None), 3, v(1))
                n = self.eg('n', None if t is None else t[2] - 1) + 1
                r = (kind, o, n, self.eg(('kk', size_class(n)), v(3)))
                octant = o
            elif kind == 'move':
                r = (kind, self.seg('mx', v(1)), self.seg('my', v(2)))
            elif kind == 'amove':
                r = (kind, self.tree('ax', 8, v(1)), self.tree('ay', 7, v(2)))
            elif kind == 'fill':
                r = (kind, self.tree('ink', 3, v(1)), self.seg('fx', v(2)), self.seg('fy', v(3)))
            elif kind == 'paint':
                paper, cell = self.tree('paper', 3, v(1)), self.tree('cell', 9, v(2))
                n = self.eg('runs', None if t is None else len(t[3]) - 1) + 1
                runs = []
                for j in range(n):
                    d = self.tree('rd', 2, None if t is None else 'urdl'.index(t[3][j][0]))
                    runs.append(('urdl'[d], self.tree('rc', 6, None if t is None else t[3][j][1] - 1) + 1))
                r = (kind, paper, cell, tuple(runs))
            elif kind == 'copy':
                r = (kind, self.eg('back', None if t is None else t[1] - 1) + 1,
                     self.eg('count', None if t is None else t[2] - 2) + 2)
            elif kind == 'call':
                r = (kind, self.tree('stream', 5, v(1)), self.eg('start', v(2)),
                     self.eg('count', None if t is None else t[3] - 2) + 2)
            else:
                r = (kind,)
            out.append(r)
            if kind in ('end', 'then'):
                return out
            prev = kind


def encode(all_tokens, shared=False):
    """[bytes] of each picture's coded tokens (shared: one stream, its
    bytes as the first item and empty ones after)."""
    out, e = [], Encoder()
    for toks in all_tokens:
        Model(e).stream(toks)
        if not shared:
            out.append(trim(e.finish(), [toks], False))
            e = Encoder()
    if shared:
        out = [trim(e.finish(), all_tokens, True)] + [b''] * (len(all_tokens) - 1)
    return out


def trim(data, all_tokens, shared):
    """The bytes without the zeros at the end the decoder reads anyway, and
    then without the last bytes as long as everything still decodes."""
    while len(data) > 1 and decode_all(data[:-1], len(all_tokens)) == all_tokens:
        data = data[:-1]
    return data


def decode_all(data, count):
    d = Decoder(data)
    try:
        return [Model(d).stream() for _ in range(count)]
    except (IndexError, ValueError):
        return None


def decode(blobs, shared=False):
    if shared:
        return decode_all(blobs[0], len(blobs))
    return [decode_all(b, 1)[0] for b in blobs]
