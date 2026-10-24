#!/usr/bin/env python3
"""MegaLZ: the packer format of both tape stages (decoder, optimal encoder).

  megalz.py unpack [--rcs] IN OUT    decode a stream
  megalz.py pack [--rcs] IN OUT      encode a file (cached in the project's build/mlz-cache/)
  megalz.py rcs IN OUT               a screen to RCS order
--rcs: the file is a screen, the stream holds it in RCS order (rcs_address).

Format (as read by the depacker at $5CF6 and $6152, see src/loader*.asm):
bits are read MSB first from bytes taken from the stream when the bit
buffer runs out; the first byte of the output is stored as is.
  1 + byte                 literal
  000 + 3 bits x           1 byte from distance 8-x
  001 + byte n             2 bytes from distance 256-n
  010 + offset             3 bytes
  011 + gamma g            4..255 bytes; eight zero bits and a one = end
gamma: k zero bits, a one, k+1 bits v; length 2 + 2^(k+1) + v.
offset: 0 + byte n (distance 256-n, 1..256) or
        1 + 4 bits d + byte n (distance (17-d)*256 - n, 257..4352).
"""
import os
import sys


class BitReader:
    def __init__(self, data, pos=0):
        self.d = data
        self.p = pos
        self.buf = 0
        self.left = 0

    def byte(self):
        b = self.d[self.p]
        self.p += 1
        return b

    def bit(self):
        if not self.left:
            self.buf = self.byte()
            self.left = 8
        self.left -= 1
        return (self.buf >> self.left) & 1

    def bits(self, n):
        v = 0
        for _ in range(n):
            v = v * 2 + self.bit()
        return v


def tokens(data, pos=0):
    """Yield ('lit', byte) and ('copy', length, distance); the stream end
    position is in the last item, ('end', pos)."""
    r = BitReader(data, pos)
    yield ('lit', r.byte())
    while True:
        if r.bit():
            yield ('lit', r.byte())
            continue
        kind = r.bits(2)
        if kind == 0:
            yield ('copy', 1, 8 - r.bits(3))
            continue
        if kind == 1:
            yield ('copy', 2, 256 - r.byte())
            continue
        if kind == 2:
            length = 3
        else:
            k = 0
            while not r.bit():
                k += 1
                if k == 8:
                    yield ('end', r.p)
                    return
            length = 2 + (2 << k) + r.bits(k + 1)
        if r.bit():
            d = r.bits(4)
            dist = (17 - d) * 256 - r.byte()
        else:
            dist = 256 - r.byte()
        yield ('copy', length, dist)


def unpack(data, pos=0):
    """Return (output, end position in data)."""
    out = bytearray()
    for t in tokens(data, pos):
        if t[0] == 'lit':
            out.append(t[1])
        elif t[0] == 'copy':
            for _ in range(t[1]):
                out.append(out[-t[2]])
        else:
            return bytes(out), t[1]


class BitWriter:
    def __init__(self):
        self.out = bytearray()
        self.at = None      # index of the byte taking bits
        self.left = 0

    def byte(self, b):
        self.out.append(b)

    def bit(self, v):
        if not self.left:
            self.at = len(self.out)
            self.out.append(0)
            self.left = 8
        self.left -= 1
        if v:
            self.out[self.at] |= 1 << self.left

    def bits(self, v, n):
        for i in range(n - 1, -1, -1):
            self.bit((v >> i) & 1)


def gamma_bits(length):
    k = (length - 2).bit_length() - 2
    return 2 * k + 2


def copy_cost(length, dist):
    """Bits for a copy token, or None if it cannot be coded."""
    if length == 1:
        return 6 if dist <= 8 else None
    if length == 2:
        return 11 if dist <= 256 else None
    if dist > 4352:
        return None
    off = 9 if dist <= 256 else 13
    if length == 3:
        return 3 + off
    if length > 255:
        return None
    return 3 + gamma_bits(length) + off


def encode(toks):
    w = BitWriter()
    first = True
    for t in toks:
        if first:
            w.byte(t[1])
            first = False
            continue
        if t[0] == 'lit':
            w.bit(1)
            w.byte(t[1])
            continue
        _, length, dist = t
        w.bit(0)
        if length == 1:
            w.bits(0, 2)
            w.bits(8 - dist, 3)
            continue
        if length == 2:
            w.bits(1, 2)
            w.byte(256 - dist)
            continue
        if length == 3:
            w.bits(2, 2)
        else:
            w.bits(3, 2)
            k = (length - 2).bit_length() - 2
            w.bits(0, k)
            w.bit(1)
            w.bits(length - 2 - (2 << k), k + 1)
        if dist <= 256:
            w.bit(0)
            w.byte(256 - dist)
        else:
            w.bit(1)
            hi, lo = divmod(dist + 255, 256)
            w.bits(17 - hi, 4)
            w.byte(255 - lo)
    w.bit(0)
    w.bits(3, 2)
    w.bits(0, 8)
    w.bit(1)        # never read: the packer ends the gamma code all the same
    return bytes(w.out)


def rcs_address(i):
    """Screen address of byte i of a screen stored in RCS order (the order
    the loading screen depacker at $61C1 writes): each third of the pixel
    area column by column, cell by cell, eight rows of a cell together; the
    attributes as they are."""
    a = 0x4000 + i
    hi, lo = a >> 8, a & 255
    if hi >= 0x58:
        return a
    b = (lo & 0xF8) | (hi & 7)
    return (hi & 0xF8 | lo & 7) << 8 | ((b << 2) | (b >> 6)) & 255


def to_rcs(screen):
    return bytes(screen[rcs_address(i) - 0x4000] for i in range(len(screen)))


def from_rcs(data):
    screen = bytearray(len(data))
    for i, v in enumerate(data):
        screen[rcs_address(i) - 0x4000] = v
    return bytes(screen)


# The cache lives in the project's build/ even when the build runs elsewhere
# (tools/zxq.py check builds in a temporary directory of links).
CACHE = os.path.join(os.path.dirname(os.path.dirname(os.path.realpath(__file__))),
                     'build', 'mlz-cache')


def pack(data, cache=CACHE):
    """encode(parse(data)), kept in CACHE/<sha1> (the parse is slow)."""
    if cache:
        import hashlib
        path = os.path.join(cache, hashlib.sha1(data).hexdigest())
        if os.path.exists(path):
            return open(path, 'rb').read()
    out = encode(parse(data))
    if cache:
        os.makedirs(cache, exist_ok=True)
        tmp = '%s.%d' % (path, os.getpid())
        open(tmp, 'wb').write(out)
        os.replace(tmp, path)
    return out

def main():
    args = sys.argv[1:]
    rcs = '--rcs' in args
    args = [a for a in args if a != '--rcs']
    cmd, src, dst = args[:3]
    data = open(src, 'rb').read()
    if cmd == 'rcs':
        out = to_rcs(data)
    elif cmd == 'unpack':
        out, _ = unpack(data)
        if rcs:
            out = from_rcs(out)
    else:
        out = pack(to_rcs(data) if rcs else data)
    open(dst, 'wb').write(out)


def matches(data, i, chains):
    """For position i: {length: nearest distance} for the lengths that the
    nearest matches reach, short (distance <= 256) and long."""
    n = len(data)
    short, long_ = {}, {}
    if i + 1 >= n:
        return short, long_
    best = 1
    bestl = 2
    for j in reversed(chains.get(data[i] | data[i + 1] << 8, ())):
        dist = i - j
        if dist > 4352:
            break
        top = best if dist <= 256 else max(best, bestl)
        if i + top < n and top < 255 and data[j + top] != data[i + top]:
            continue
        L = 2
        while i + L < n and L < 255 and data[j + L] == data[i + L]:
            L += 1
        if dist <= 256:
            for length in range(best + 1, L + 1):
                short[length] = dist
            best = max(best, L)
        else:
            for length in range(max(best, bestl) + 1, L + 1):
                if length >= 3:
                    long_[length] = dist
            bestl = max(bestl, L)
    return short, long_


def parse(data):
    """Optimal parse: the fewest bits. Returns the token list. Of equal
    costs the first found is kept, a 1-byte copy takes the farthest of the
    eight distances and a longer copy the nearest: the original packer's
    choices, so the tape's streams come out byte for byte."""
    n = len(data)
    INF = 1 << 60
    cost = [INF] * (n + 1)
    choice = [None] * (n + 1)
    cost[1] = 8
    chains = {}
    for i in range(1, n):
        chains.setdefault(data[i - 1] | data[i] << 8, []).append(i - 1)
        c = cost[i]

        def relax(at, b, t):
            if c + b < cost[at]:
                cost[at] = c + b
                choice[at] = t
        relax(i + 1, 9, ('lit', data[i]))
        for dist in range(min(8, i), 0, -1):
            if data[i - dist] == data[i]:
                relax(i + 1, 6, ('copy', 1, dist))
                break
        short, long_ = matches(data, i, chains)
        for length, dist in short.items():
            relax(i + length, copy_cost(length, dist), ('copy', length, dist))
        for length, dist in long_.items():
            relax(i + length, copy_cost(length, dist), ('copy', length, dist))
    out = []
    i = n
    while i > 1:
        t = choice[i]
        out.append(t)
        i -= 1 if t[0] == 'lit' else t[1]
    out.append(('lit', data[0]))
    return out[::-1]


if __name__ == '__main__':
    main()
