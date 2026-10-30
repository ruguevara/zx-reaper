"""The size of bytes compressed in the ZX0 format (v2), the usual Spectrum
LZ, by an optimal parse of our own (zx0's own parser may do a little better).

ZX0's blocks: a literal run (0, Elias gamma length, the bytes), a copy from
the last offset (0, gamma length; only after a literal) and a copy from a new
offset (1, gamma of the offset's high part + 1, 7 low bits, gamma length - 1);
a literal never follows a literal, the first block is a literal without its
bit, and the end is a new offset of 256 (18 bits). The 68-byte standard
decompressor unpacks it; a picture would be unpacked into a buffer of the
size of the largest picture (778 bytes) and drawn from there.
"""
import collections

KEEP = 12           # states (last offset, ended with a literal) kept at each position
LIT_FROM = 3        # of them, the ones a literal run may start from
LIT_MAX = 512       # the longest literal run tried


def gamma(n):
    return 2 * (n.bit_length() - 1) + 1


def new_offset(off, length):
    return 1 + gamma(((off - 1) >> 7) + 1) + 7 + gamma(length - 1)


def parse(data):
    """(bits, blocks) of the cheapest parse found; a block is (kind, length,
    offset), kind 'lit', 'rep' or 'new'."""
    n = len(data)
    states = [dict() for _ in range(n + 1)]
    states[0][(0, False)] = (0, None)
    heads = collections.defaultdict(list)       # 2-byte prefix -> earlier positions

    def put(j, key, cost, how):
        s = states[j]
        if key not in s or cost < s[key][0]:
            s[key] = (cost, how)

    for i in range(n):
        best = sorted(states[i].items(), key=lambda kv: kv[1][0])[:KEEP]
        states[i] = dict(best)
        cands = []
        if i + 1 < n:
            for j in heads[data[i:i + 2]]:
                length = 2
                while i + length < n and data[j + length] == data[i + length]:
                    length += 1
                cands.append((i - j, length))
            heads[data[i:i + 2]].append(i)
        lits = 0
        for key, (cost, _) in best:
            last, lit = key
            back = (key, i)
            if not lit:
                if lits < LIT_FROM:
                    lits += 1
                    for length in range(1, min(LIT_MAX, n - i) + 1):
                        put(i + length, (last, True), cost + (1 if i else 0) + gamma(length) + 8 * length,
                            ('lit', length, last, back))
            elif last:
                length = 0
                while i + length < n and data[i - last + length] == data[i + length]:
                    length += 1
                for m in range(1, length + 1):
                    put(i + m, (last, False), cost + 1 + gamma(m), ('rep', m, last, back))
            for off, length in cands:
                for m in range(2, length + 1):
                    put(i + m, (off, False), cost + new_offset(off, m), ('new', m, off, back))
    key, (cost, _) = min(states[n].items(), key=lambda kv: kv[1][0])
    blocks, at = [], (key, n)
    while at[1]:
        how = states[at[1]][at[0]][1]
        blocks.append(how[:3])
        at = how[3]
    blocks.reverse()
    if unpack(blocks, data) != data:
        raise AssertionError('lz: the parse does not unpack to the data')
    return cost + 18, blocks


def unpack(blocks, data):
    """The bytes the blocks make (the literals taken from `data`)."""
    out = bytearray()
    for kind, length, off in blocks:
        if kind == 'lit':
            out += data[len(out):len(out) + length]
        else:
            for _ in range(length):
                out.append(out[-off])
    return bytes(out)


def size(data):
    """Bytes of `data` in the ZX0 format."""
    return (parse(bytes(data))[0] + 7) // 8
