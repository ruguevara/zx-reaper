#!/usr/bin/env python3
"""Split TAP/TZX files into a text manifest + payload files, rebuild them
byte-for-byte, and compare tapes block by block.

  zxtape.py split TAPE OUTDIR      writes OUTDIR/tape.txt and OUTDIR/NN.bin
  zxtape.py build MANIFEST OUT     rebuilds a tape (paths relative to cwd)
  zxtape.py diff A B               per-block comparison, exit 1 on mismatch
  zxtape.py list TAPE              one line per block

Manifest lines (one per block; lines starting with '#' are comments):
  format tap|tzx [VERSION]
  [pause=MS] header TYPE "NAME" len=N p1=N p2=N [cs=N]    standard header
  [pause=MS] data FLAG FILE [cs=N]                         flag + FILE + checksum
  [pause=MS] raw FILE                                      exact block bytes
  turbo HEX18 data|raw ...        TZX 0x11 (HEX18 = timing fields, length omitted)
  pure HEX7 data|raw ...          TZX 0x14 (HEX7 = timing fields, length omitted)
  tzx ID HEX|@FILE                any other TZX block, body as hex or file
cs= is written only when the original checksum is not the XOR checksum.
"""
import os
import re
import shlex
import sys

TYPES = ['program', 'numbers', 'chars', 'code']
TZX_MAGIC = b'ZXTape!\x1a'


def xor(data):
    c = 0
    for b in data:
        c ^= b
    return c


def qname(name):
    out = ''
    for b in name:
        if 32 <= b < 127 and chr(b) not in '"\\':
            out += chr(b)
        else:
            out += '\\x%02x' % b
    return '"' + out + '"'


def uqname(s):
    return bytes(int(m.group(1), 16) if m.group(1) else ord(m.group(2))
                 for m in re.finditer(r'\\x([0-9a-fA-F]{2})|(.)', s))


def tzx_body_len(bid, d, i):
    """Length of the body of TZX block `bid` starting at d[i] (after the ID)."""
    w = lambda o: d[i + o] | d[i + o + 1] << 8
    t = lambda o: w(o) | d[i + o + 2] << 16
    q = lambda o: t(o) | d[i + o + 3] << 24
    fixed = {0x12: 4, 0x20: 2, 0x22: 0, 0x23: 2, 0x24: 2, 0x25: 0, 0x27: 0,
             0x5A: 9}
    if bid in fixed:
        return fixed[bid]
    if bid == 0x10:
        return 4 + w(2)
    if bid == 0x11:
        return 18 + t(15)
    if bid == 0x13:
        return 1 + 2 * d[i]
    if bid == 0x14:
        return 10 + t(7)
    if bid == 0x15:
        return 8 + t(5)
    if bid in (0x18, 0x19, 0x2A, 0x2B):
        return 4 + q(0)
    if bid in (0x21, 0x30):
        return 1 + d[i]
    if bid == 0x26:
        return 2 + 2 * w(0)
    if bid in (0x28, 0x32):
        return 2 + w(0)
    if bid == 0x31:
        return 2 + d[i + 1]
    if bid == 0x33:
        return 1 + 3 * d[i]
    if bid == 0x35:
        return 20 + q(16)
    raise ValueError('unsupported TZX block ID 0x%02X at offset %d' % (bid, i - 1))


def read_blocks(path):
    """Yield dicts: kind ('tap', 0x10, 0x11, 0x14 or other id), data, extra."""
    d = open(path, 'rb').read()
    if d.startswith(TZX_MAGIC):
        yield {'kind': 'magic', 'version': '%d.%02d' % (d[8], d[9])}
        i = 10
        while i < len(d):
            bid = d[i]
            n = tzx_body_len(bid, d, i + 1)
            body = d[i + 1:i + 1 + n]
            if bid == 0x10:
                yield {'kind': 0x10, 'pause': body[0] | body[1] << 8, 'data': body[4:]}
            elif bid == 0x11:
                yield {'kind': 0x11, 'timing': body[:15], 'data': body[18:]}
            elif bid == 0x14:
                yield {'kind': 0x14, 'timing': body[:7], 'data': body[10:]}
            else:
                yield {'kind': bid, 'body': body}
            i += 1 + n
    else:
        i = 0
        while i < len(d):
            n = d[i] | d[i + 1] << 8
            yield {'kind': 'tap', 'data': d[i + 2:i + 2 + n]}
            i += 2 + n


def describe(data, fname):
    """Manifest text for a flag+payload+checksum block, writing payload if needed."""
    if len(data) >= 2:
        cs = '' if xor(data[:-1]) == data[-1] else ' cs=%d' % data[-1]
        if data[0] == 0 and len(data) == 19 and data[1] < 4:
            h = data[1:18]
            return 'header %s %s len=%d p1=%d p2=%d%s' % (
                TYPES[h[0]], qname(h[1:11]), h[11] | h[12] << 8,
                h[13] | h[14] << 8, h[15] | h[16] << 8, cs), None
        return 'data 0x%02x %s%s' % (data[0], fname, cs), data[1:-1]
    return 'raw %s' % fname, data


def split(tape, outdir):
    os.makedirs(outdir, exist_ok=True)
    lines = []
    fmt = 'tap'
    for n, b in enumerate(read_blocks(tape)):
        fname = os.path.join(outdir, '%02d.bin' % n)
        kind = b['kind']
        if kind == 'magic':
            fmt = 'tzx'
            lines.append('format tzx %s' % b['version'])
            continue
        payload = None
        if kind in ('tap', 0x10, 0x11, 0x14):
            text, payload = describe(b['data'], fname)
            if kind == 0x10:
                text = 'pause=%d %s' % (b['pause'], text)
            elif kind == 0x11:
                text = 'turbo %s %s' % (b['timing'].hex(), text)
            elif kind == 0x14:
                text = 'pure %s %s' % (b['timing'].hex(), text)
        else:
            body = b['body']
            if len(body) > 64:
                payload = body
                text = 'tzx 0x%02x @%s' % (kind, fname)
            else:
                text = 'tzx 0x%02x %s' % (kind, body.hex() or '-')
        if payload is not None:
            open(fname, 'wb').write(payload)
        lines.append(text)
    if fmt == 'tap':
        lines.insert(0, 'format tap')
    with open(os.path.join(outdir, 'tape.txt'), 'w') as f:
        f.write('\n'.join(lines) + '\n')


def parse_kv(tokens):
    kv = {}
    rest = []
    for t in tokens:
        k, sep, v = t.partition('=')
        if sep and re.fullmatch(r'[a-z0-9]+', k):
            kv[k] = int(v, 0)
        else:
            rest.append(t)
    return kv, rest


def block_bytes(tokens):
    """Bytes of a flag+payload+checksum (or raw) block from manifest tokens."""
    kv, rest = parse_kv(tokens)
    kind = rest[0]
    if kind == 'header':
        h = bytes([TYPES.index(rest[1])]) + uqname(rest[2][1:-1]).ljust(10, b' ')
        for k in ('len', 'p1', 'p2'):
            h += kv[k].to_bytes(2, 'little')
        data = b'\x00' + h
    elif kind == 'data':
        data = bytes([int(rest[1], 0)]) + open(rest[2], 'rb').read()
    elif kind == 'raw':
        return open(rest[1], 'rb').read()
    else:
        raise ValueError('bad block kind %r' % kind)
    return data + bytes([kv.get('cs', xor(data))])


def build(manifest, out):
    res = bytearray()
    fmt = 'tap'
    for lineno, line in enumerate(open(manifest), 1):
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        tok = shlex.split(line, posix=False)
        try:
            if tok[0] == 'format':
                fmt = tok[1]
                if fmt == 'tzx':
                    major, minor = (tok[2] if len(tok) > 2 else '1.20').split('.')
                    res += TZX_MAGIC + bytes([int(major), int(minor)])
                continue
            if fmt == 'tap':
                data = block_bytes(tok)
                res += len(data).to_bytes(2, 'little') + data
                continue
            if tok[0] == 'tzx':
                bid = int(tok[1], 0)
                body = open(tok[2][1:], 'rb').read() if tok[2].startswith('@') else \
                    bytes.fromhex('' if tok[2] == '-' else tok[2])
                res += bytes([bid]) + body
            elif tok[0] == 'turbo':
                data = block_bytes(tok[2:])
                res += b'\x11' + bytes.fromhex(tok[1]) + len(data).to_bytes(3, 'little') + data
            elif tok[0] == 'pure':
                data = block_bytes(tok[2:])
                res += b'\x14' + bytes.fromhex(tok[1]) + len(data).to_bytes(3, 'little') + data
            else:
                kv, rest = parse_kv(tok[:1])
                pause = kv.get('pause', 1000)
                data = block_bytes(tok[1:] if kv else tok)
                res += b'\x10' + pause.to_bytes(2, 'little') + len(data).to_bytes(2, 'little') + data
        except (ValueError, IndexError, KeyError, OSError) as e:
            sys.exit('%s:%d: %s' % (manifest, lineno, e))
    open(out, 'wb').write(res)


def summary(b):
    k = b['kind']
    if k == 'magic':
        return 'TZX %s' % b['version']
    if 'data' in b:
        d = b['data']
        text = describe(d, '…')[0]
        return '%s %d bytes: %s' % (k if k == 'tap' else 'ID%02X' % k, len(d), text)
    return 'ID%02X %d bytes' % (k, len(b['body']))


def diff(a, b):
    ba, bb = list(read_blocks(a)), list(read_blocks(b))
    bad = 0
    for n in range(max(len(ba), len(bb))):
        x = ba[n] if n < len(ba) else None
        y = bb[n] if n < len(bb) else None
        if x == y:
            print('%02d  ok    %s' % (n, summary(x)))
            continue
        bad += 1
        print('%02d  DIFF  %s\n          %s' % (n, x and summary(x), y and summary(y)))
        if x and y and 'data' in x and 'data' in y:
            dx, dy = x['data'], y['data']
            first = next((i for i in range(min(len(dx), len(dy))) if dx[i] != dy[i]),
                         min(len(dx), len(dy)))
            print('          first difference at block offset %d (payload offset %d)'
                  % (first, first - 1))
    print('identical' if not bad else '%d block(s) differ' % bad)
    return 1 if bad else 0


def main():
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    cmd = sys.argv[1]
    if cmd == 'split' and len(sys.argv) == 4:
        split(sys.argv[2], sys.argv[3])
    elif cmd == 'build' and len(sys.argv) == 4:
        build(sys.argv[2], sys.argv[3])
    elif cmd == 'diff' and len(sys.argv) == 4:
        sys.exit(diff(sys.argv[2], sys.argv[3]))
    elif cmd == 'list':
        for n, b in enumerate(read_blocks(sys.argv[2])):
            print('%02d  %s' % (n, summary(b)))
    else:
        sys.exit(__doc__)


if __name__ == '__main__':
    main()
