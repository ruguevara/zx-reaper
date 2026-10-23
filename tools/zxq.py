#!/usr/bin/env python3
"""Query and maintain a skool disassembly split into one file per entry.

The agent should read the disassembly through this tool, never whole.

  zxq.py split GAME.skool DIR       one file per entry: DIR/head.skool, DIR/XXXX.skool
  zxq.py join DIR                   print the whole skool file
  zxq.py show ADDR                  the entry containing ADDR, with callers/callees
  zxq.py refs ADDR                  instructions that refer to ADDR
  zxq.py next [N]                   N un-annotated entries, dependencies first
  zxq.py status [MAP...]            progress counters (MAPs: code execution maps)
  zxq.py unexec MAP...              code never executed in the MAPs (data candidates)
  zxq.py reclassify FRAG.ctl [-f]   regenerate the entries a control-file fragment
                                    covers (ends with `i $END`); -f also replaces
                                    annotated entries
  zxq.py peek ADDR [LEN]            hex + text dump of the image
  zxq.py strings [MIN [START END]]  text runs (plain or bit-7 terminated), default
                                    $5B00-$FFFF
  zxq.py gfx ADDR LEN W OUT.png [cells] [SCALE]
                                    render bytes as a bitmap W bytes wide (linear
                                    rows, or `cells`: 8x8 characters, 8 bytes each)
  zxq.py cmp A.bin B.bin ORG        differing addresses and their entries
  zxq.py export ASM MODULES OUTDIR  split skool2asm output into modules

DIR defaults to $ZXQ_SKOOL or re/skool; the snapshot to $ZXQ_IMAGE or re/image.z80. Addresses: $8000, 0x8000 or 32768.
An entry counts as annotated once its title is not the sna2skool default.
"""
import os
import re
import sys

SKOOL_DIR = os.environ.get('ZXQ_SKOOL', 're/skool')
IMAGE = os.environ.get('ZXQ_IMAGE', 're/image.z80')
DEFAULT_TITLE = re.compile(r'(Routine|Data block|Message|Game status buffer entry) at '
                           r'\$?[0-9A-Fa-f]+$|Unused$|Ignored$')
INSTR = re.compile(r'^([cbtuswgi* !])\$([0-9A-Fa-f]{4}) ?(.*)$')
OPERAND_ADDR = re.compile(r'\$([0-9A-Fa-f]{4})\b')
FLOW = re.compile(r'^(CALL|JP|JR|DJNZ|RST)\b')


def parse_addr(s):
    s = s.strip()
    if s.startswith('$'):
        return int(s[1:], 16)
    return int(s, 0)


class Entry:
    def __init__(self, text, fname=None):
        self.text = text
        self.fname = fname
        self.lines = text.rstrip('\n').split('\n')
        self.instr = []          # (addr, instruction, comment)
        self.labels = {}
        self.title = ''
        self.ctype = None
        pending_label = None
        for line in self.lines:
            if line.startswith('@label='):
                pending_label = line[7:].strip()
                continue
            m = INSTR.match(line)
            if m:
                addr = int(m.group(2), 16)
                if self.ctype is None:
                    self.ctype = m.group(1)
                instr, _, comment = m.group(3).partition(';')
                self.instr.append((addr, instr.strip(), comment.strip()))
                if pending_label:
                    self.labels[addr] = pending_label
                    pending_label = None
            elif line.startswith('; ') and not self.title and not self.instr:
                self.title = line[2:].strip()
        self.addr = self.instr[0][0] if self.instr else None
        self.end = self.instr[-1][0] if self.instr else None

    @property
    def annotated(self):
        return bool(self.title) and not DEFAULT_TITLE.match(self.title)

    @property
    def name(self):
        return self.labels.get(self.addr) or '$%04X' % self.addr

    def refs(self):
        """Addresses this entry refers to: (from, to, is_flow)."""
        out = []
        if self.ctype in 'gui':
            return out
        for a, ins, _ in self.instr:
            if ins.startswith(('DEFB', 'DEFM', 'DEFS')):
                continue
            for m in OPERAND_ADDR.finditer(ins):
                out.append((a, int(m.group(1), 16), bool(FLOW.match(ins))))
        return out


def split_entries(text):
    head, entries = [], []
    for para in re.split(r'\n[ \t]*\n', text.strip('\n')):
        para = para.strip('\n')
        if not para:
            continue
        e = Entry(para + '\n')
        if e.addr is None:
            head.append(para)
        else:
            entries.append(e)
    return '\n\n'.join(head) + '\n' if head else '', entries


def load(dirname=None):
    d = dirname or SKOOL_DIR
    if not os.path.isdir(d):
        sys.exit('no skool directory %s (run zxq.py split first)' % d)
    entries = []
    for f in sorted(os.listdir(d)):
        if re.fullmatch(r'[0-9A-F]{4}\.skool', f):
            p = os.path.join(d, f)
            entries.append(Entry(open(p).read(), p))
    return entries


class Index:
    def __init__(self, entries):
        self.entries = entries
        self.starts = [e.addr for e in entries]
        self.by_addr = {e.addr: e for e in entries}
        self.callees = {e.addr: set() for e in entries}
        self.callers = {e.addr: set() for e in entries}
        self.ref_lines = {}
        for e in entries:
            for frm, to, flow in e.refs():
                t = self.find(to)
                self.ref_lines.setdefault(to, []).append((frm, e))
                if t and t is not e:
                    self.callees[e.addr].add(t.addr)
                    self.callers[t.addr].add(e.addr)

    def find(self, addr):
        import bisect
        i = bisect.bisect_right(self.starts, addr) - 1
        if i < 0:
            return None
        e = self.entries[i]
        nxt = self.starts[i + 1] if i + 1 < len(self.starts) else 0x10000
        return e if addr < nxt else None

    def brief(self, addr):
        e = self.by_addr[addr]
        mark = '' if e.annotated else ' (TODO)'
        return '%s %s %s — %s%s' % (e.ctype, '$%04X' % e.addr, e.labels.get(e.addr, ''),
                                    e.title, mark)


def cmd_show(addr):
    idx = Index(load())
    e = idx.find(addr)
    if not e:
        sys.exit('no entry contains $%04X' % addr)
    print('# file: %s' % e.fname)
    sys.stdout.write(e.text)
    for title, addrs in (('callers/readers', idx.callers[e.addr]),
                         ('refers to', idx.callees[e.addr])):
        if addrs:
            print('# %s:' % title)
            for a in sorted(addrs):
                print('#   ' + idx.brief(a))


def cmd_refs(addr):
    idx = Index(load())
    hits = idx.ref_lines.get(addr, [])
    for frm, e in sorted(hits, key=lambda h: h[0]):
        ins = next(i for a, i, c in e.instr if a == frm)
        print('$%04X  %-22s in %s' % (frm, ins, idx.brief(e.addr)))
    if not hits:
        print('no references to $%04X' % addr)


def next_entries(idx, n):
    """Un-annotated entries, those with fewest un-annotated dependencies first.

    Code depends on the code it calls (leaves first); data depends on the code
    that reads it (understand the reader, then the data)."""
    todo = [e for e in idx.entries if not e.annotated]

    def deps(e):
        if e.ctype == 'c':
            rel = idx.callees[e.addr]
            rel = [a for a in rel if idx.by_addr[a].ctype == 'c']
        else:
            rel = idx.callers[e.addr]
        return sum(1 for a in rel if not idx.by_addr[a].annotated)

    todo.sort(key=lambda e: (deps(e), e.ctype != 'c', -len(idx.callers[e.addr]), e.addr))
    return todo[:n]


def cmd_next(n):
    idx = Index(load())
    for e in next_entries(idx, n):
        print('%s  %s  (%d instr, %d callers, %d refs)' % (
            '$%04X' % e.addr, e.fname, len(e.instr), len(idx.callers[e.addr]),
            len(idx.callees[e.addr])))


def read_map(paths):
    addrs = set()
    for path in paths:
        addrs |= {int(line.strip().lstrip('$'), 16) for line in open(path) if line.strip()}
    return addrs


def cmd_status(map_path):
    entries = load()
    total = len(entries)
    done = sum(e.annotated for e in entries)
    by_type = {}
    for e in entries:
        by_type[e.ctype] = by_type.get(e.ctype, 0) + 1
    labels = sum(len(e.labels) for e in entries)
    comments = sum(1 for e in entries for a, i, c in e.instr if c)
    instrs = sum(len(e.instr) for e in entries)
    print('entries: %d (%s)' % (total, ', '.join('%s=%d' % kv for kv in sorted(by_type.items()))))
    print('annotated: %d/%d (%.0f%%)' % (done, total, 100.0 * done / max(total, 1)))
    print('labels: %d   commented instructions: %d/%d' % (labels, comments, instrs))
    if map_path:
        ex = read_map(map_path)
        code = [a for e in entries if e.ctype == 'c' for a, i, c in e.instr
                if not i.startswith('DEF')]
        hit = sum(1 for a in code if a in ex)
        print('code coverage: %d/%d instructions executed (%.0f%%)'
              % (hit, len(code), 100.0 * hit / max(len(code), 1)))
        outside = sorted(a for a in ex if a >= 0x4000 and not any(
            e.ctype == 'c' and e.addr <= a <= e.end for e in entries))
        if outside:
            print('executed addresses outside code entries: %d (first: %s)'
                  % (len(outside), ' '.join('$%04X' % a for a in outside[:8])))


def cmd_unexec(map_path):
    ex = read_map(map_path)
    for e in load():
        if e.ctype != 'c':
            continue
        run = []
        for a, ins, _ in e.instr + [(None, '', '')]:
            if a is not None and a not in ex:
                run.append(a)
                continue
            if run:
                print('$%04X-$%04X  %d instr never executed  in %s %s' % (
                    run[0], run[-1], len(run), e.name, e.title))
                run = []


def cmd_cmp(a, b, org):
    da, db = open(a, 'rb').read(), open(b, 'rb').read()
    idx = Index(load()) if os.path.isdir(SKOOL_DIR) else None
    diffs = [i for i in range(min(len(da), len(db))) if da[i] != db[i]]
    if len(da) != len(db):
        print('sizes differ: %d vs %d' % (len(da), len(db)))
    for i in diffs[:40]:
        where = ''
        if idx:
            e = idx.find(org + i)
            where = e and idx.brief(e.addr) or ''
        print('$%04X  %02X %02X  %s' % (org + i, da[i], db[i], where))
    if len(diffs) > 40:
        print('... %d differences in total' % len(diffs))
    sys.exit(1 if diffs or len(da) != len(db) else 0)


def image():
    from skoolkit.snapshot import Snapshot
    snap = Snapshot.get(IMAGE)
    return [0] * 16384 + list(snap.ram(-1))[:49152]


def cmd_peek(addr, n):
    mem = image()
    for a in range(addr, min(addr + n, 0x10000), 16):
        row = mem[a:min(a + 16, addr + n)]
        text = ''.join(chr(b & 0x7F) if 32 <= (b & 0x7F) < 127 else '.' for b in row)
        print('$%04X  %-48s %s' % (a, ' '.join('%02X' % b for b in row), text))


def cmd_strings(minlen, start=0x5B00, end=0x10000):
    mem = image()
    a = start
    while a < end:
        b = a
        while b < end and 32 <= mem[b] < 127:
            b += 1
        term = b < end and 32 <= (mem[b] & 0x7F) < 127 and mem[b] & 0x80
        text = ''.join(chr(c) for c in mem[a:b]) + (chr(mem[b] & 0x7F) if term else '')
        if len(text) >= minlen and len(set(text)) > 2:
            short = text if len(text) <= 64 else text[:64] + '...'
            print('$%04X %3d %s%s' % (a, len(text), short, '  [bit 7 end]' if term else ''))
        a = b + 1


def cmd_gfx(addr, n, width, out, cells=False, scale=4):
    import struct
    import zlib
    mem = image()
    data = mem[addr:addr + n]
    if cells:   # 8x8 characters, `width` characters per row
        chars = [data[i:i + 8] for i in range(0, len(data), 8)]
        rows = []
        for r in range(0, len(chars), width):
            line = chars[r:r + width]
            line += [[0] * 8] * (width - len(line))
            for y in range(8):
                rows.append([c[y] if y < len(c) else 0 for c in line])
    else:
        rows = [data[i:i + width] for i in range(0, len(data), width)]
        rows[-1] = rows[-1] + [0] * (width - len(rows[-1]))
    raw = b''
    for row in rows:
        bits = [(b >> (7 - k)) & 1 for b in row for k in range(8)]
        line = bytes(0 if bit else 255 for bit in bits for _ in range(scale))
        raw += (b'\0' + line) * scale
    w, h = width * 8 * scale, len(rows) * scale

    def chunk(t, d):
        return struct.pack('>I', len(d)) + t + d + struct.pack('>I', zlib.crc32(t + d))
    with open(out, 'wb') as f:
        f.write(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 0, 0, 0, 0))
                + chunk(b'IDAT', zlib.compress(raw)) + chunk(b'IEND', b''))
    print('wrote %s (%dx%d px, %d rows of %d bytes)' % (out, w, h, len(rows), width))


def cmd_reclassify(frag, force):
    import subprocess
    addrs = []
    end = None
    for line in open(frag):
        m = re.match(r'^([a-zA-Z@ ]) *\$?([0-9A-Fa-f]+)', line) if line.strip() else None
        if not m:
            continue
        a = int(m.group(2), 16) if '$' in line.split()[1] else int(m.group(2), 0)
        addrs.append(a)
        if m.group(1) == 'i':
            end = a
    if end is None:
        sys.exit('the fragment must end with an `i $END` line (END = first address not covered)')
    start = min(addrs)
    entries = load()
    hit = [e for e in entries if e.addr < end and e.end >= start]
    if hit and (hit[0].addr < start or max(e.end for e in hit) >= end):
        sys.exit('fragment $%04X-$%04X must start and end on entry boundaries; overlapping '
                 'entries: %s' % (start, end - 1, ' '.join('$%04X-$%04X' % (e.addr, e.end)
                                                           for e in hit)))
    done = [e for e in hit if e.annotated]
    if done and not force:
        sys.exit('annotated entries would be replaced (use -f): %s'
                 % ' '.join(e.name for e in done))
    r = subprocess.run(['sna2skool.py', '-H', '-c', frag, '-s', str(start), '-e', str(end), IMAGE],
                       capture_output=True, text=True)
    if r.returncode:
        sys.exit(r.stderr)
    head, new = split_entries(r.stdout)
    new = [e for e in new if e.ctype != 'i']
    for e in hit:
        os.remove(e.fname)
    for e in new:
        open(os.path.join(SKOOL_DIR, '%04X.skool' % e.addr), 'w').write(e.text)
    print('replaced %d entries with %d: %s' % (len(hit), len(new),
                                              ' '.join('$%04X' % e.addr for e in new)))


def cmd_export(asm_path, modules_path, outdir):
    """Split skool2asm output into modules by address ranges.

    MODULES lines: `START NAME` (hex start address, module file stem); each
    entry goes to the last module starting at or before it. The ASM must have
    been written from the joined skool (same entry order)."""
    entries = [e for e in load() if e.ctype != 'i']
    text = open(asm_path).read()
    head, body = text.split('\n\n', 1) if '\n\n' in text else ('', text)
    chunks = [c for c in re.split(r'\n\n+', body.strip('\n'))]
    if len(chunks) != len(entries):
        sys.exit('asm has %d entries, skool has %d: cannot split' % (len(chunks), len(entries)))
    mods = []
    for line in open(modules_path):
        line = line.split('#')[0].split()
        if line:
            mods.append((parse_addr(line[0]), line[1]))
    mods.sort()
    os.makedirs(outdir, exist_ok=True)
    out = {}
    order = []
    for e, chunk in zip(entries, chunks):
        name = next((m for s, m in reversed(mods) if s <= e.addr), mods[0][1])
        if name not in out:
            out[name] = []
            order.append(name)
        out[name].append(chunk)
    for name in order:
        with open(os.path.join(outdir, name + '.asm'), 'w') as f:
            f.write('\n\n'.join(out[name]) + '\n')
    with open(os.path.join(outdir, 'game.asm'), 'w') as f:
        f.write(head.strip('\n') + '\n\n')
        for name in order:
            f.write('  INCLUDE "%s.asm"\n' % name)
    print('wrote %s/game.asm and %d modules' % (outdir, len(order)))


def main():
    a = sys.argv[1:]
    if not a:
        sys.exit(__doc__)
    cmd = a[0]
    if cmd == 'split' and len(a) == 3:
        head, entries = split_entries(open(a[1]).read())
        os.makedirs(a[2], exist_ok=True)
        for f in os.listdir(a[2]):
            if f.endswith('.skool'):
                os.remove(os.path.join(a[2], f))
        open(os.path.join(a[2], 'head.skool'), 'w').write(head)
        for e in entries:
            open(os.path.join(a[2], '%04X.skool' % e.addr), 'w').write(e.text)
        print('%d entries -> %s' % (len(entries), a[2]))
    elif cmd == 'join':
        d = a[1] if len(a) > 1 else SKOOL_DIR
        parts = []
        if os.path.exists(os.path.join(d, 'head.skool')):
            parts.append(open(os.path.join(d, 'head.skool')).read().strip('\n'))
        parts += [e.text.strip('\n') for e in load(d)]
        sys.stdout.write('\n\n'.join(p for p in parts if p) + '\n')
    elif cmd == 'show' and len(a) == 2:
        cmd_show(parse_addr(a[1]))
    elif cmd == 'refs' and len(a) == 2:
        cmd_refs(parse_addr(a[1]))
    elif cmd == 'next':
        cmd_next(int(a[1]) if len(a) > 1 else 10)
    elif cmd == 'status':
        cmd_status(a[1:])
    elif cmd == 'unexec' and len(a) > 1:
        cmd_unexec(a[1:])
    elif cmd == 'reclassify' and len(a) in (2, 3):
        cmd_reclassify(a[1], a[2:] == ['-f'])
    elif cmd == 'peek' and len(a) in (2, 3):
        cmd_peek(parse_addr(a[1]), parse_addr(a[2]) if len(a) == 3 else 64)
    elif cmd == 'strings':
        cmd_strings(int(a[1]) if len(a) > 1 else 5,
                    *(parse_addr(x) for x in a[2:4]))
    elif cmd == 'gfx' and 5 <= len(a) <= 7:
        cmd_gfx(parse_addr(a[1]), parse_addr(a[2]), int(a[3]), a[4], 'cells' in a[5:],
                next((int(x) for x in a[5:] if x.isdigit()), 4))
    elif cmd == 'cmp' and len(a) == 4:
        cmd_cmp(a[1], a[2], parse_addr(a[3]))
    elif cmd == 'export' and len(a) == 4:
        cmd_export(a[1], a[2], a[3])
    else:
        sys.exit(__doc__)


if __name__ == '__main__':
    import signal
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)   # quiet exit under `| head`
    main()
