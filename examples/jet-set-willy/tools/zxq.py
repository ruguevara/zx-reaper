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
  zxq.py cut ADDR TITLE             split the entry containing ADDR there; the new
                                    entry keeps the annotations of its instructions
  zxq.py peek ADDR [LEN]            hex + text dump of the image
  zxq.py strings [MIN [START END]]  text runs (plain or bit-7 terminated), default
                                    $5B00-$FFFF
  zxq.py gfx ADDR LEN W OUT.png [cells] [SCALE] [block=N]
                                    render bytes as a bitmap W bytes wide (linear
                                    rows, or `cells`: 8x8 characters, 8 bytes each);
                                    block=N draws each N-byte block as a separate
                                    tile (sprite banks); tiles are laid out in a
                                    square-ish grid with 1-byte gaps
  zxq.py check                      `make verify` in a private copy (safe for
                                    parallel agents: uses its own build dir)
  zxq.py equs [--uses|--consolidate]
                                    list @equ address names; --uses: every 16-bit
                                    operand each one replaces (add @keep before
                                    wrong ones); --consolidate: move @equ lines
                                    from entry files into head.skool
  zxq.py const [NAME VALUE [COMMENT]]
                                    list or add a numeric constant (src/constants.asm,
                                    used through @isub); safe for parallel agents
  zxq.py finding add STATUS CLAIM EVIDENCE [REFS]
  zxq.py finding set ID STATUS EVIDENCE   re/findings.md: claims with status observed /
                                    inferred / unknown / refuted and their evidence
  zxq.py findings [STATUS...]       list findings
  zxq.py question add QUESTION      re/questions.md: what the work must answer
  zxq.py question set ID STATUS ANSWER   STATUS: open / partial / answered
  zxq.py audit                      open questions and unverified findings
  zxq.py cmp A.bin B.bin ORG        differing addresses and their entries
  zxq.py asm GAME.skool             skool2asm output for sjasmplus: ORG +SHIFT (for
                                    the shift test), IXl/IXh/IYl/IYh in upper case
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
        if not entries and not head:
            # global directives (@start, @equ...) open the first paragraph; they
            # belong in head.skool (skool2asm ignores directives before @start).
            # @org stays: it sets the ORG of the entry it is attached to.
            lines = para.split('\n')
            n = 0
            while n < len(lines) and re.match(r'@(start|equ|set-|assemble|writer)', lines[n]):
                n += 1
            if n:
                head.append('\n'.join(lines[:n]))
                para = '\n'.join(lines[n:])
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
    import glob
    mem = image()
    executed = read_map(glob.glob('re/maps/*.map'))
    a = start
    while a < end:
        b = a
        while b < end and 32 <= mem[b] < 127:
            b += 1
        term = b < end and 32 <= (mem[b] & 0x7F) < 127 and mem[b] & 0x80
        text = ''.join(chr(c) for c in mem[a:b]) + (chr(mem[b] & 0x7F) if term else '')
        if len(text) >= minlen and len(set(text)) > 2 and not executed.intersection(range(a, b + 1)):
            short = text if len(text) <= 64 else text[:64] + '...'
            print('$%04X %3d %s%s' % (a, len(text), short, '  [bit 7 end]' if term else ''))
        a = b + 1


def gfx_rows(data, width, cells):
    """Bitmap rows (lists of bytes, `width` bytes each) for `data`."""
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
    return rows


def cmd_gfx(addr, n, width, out, cells=False, scale=4, block=0):
    import struct
    import zlib
    data = image()[addr:addr + n]
    if block:
        tiles = [gfx_rows(data[i:i + block], width, cells) for i in range(0, len(data), block)]
    else:   # one tall bitmap, cut into side-by-side columns
        rows = gfx_rows(data, width, cells)
        h = max(8, int((len(rows) * width * 8) ** 0.5) // 8 * 8)
        tiles = [rows[i:i + h] for i in range(0, len(rows), h)]
    # lay tiles out in a roughly square grid (image APIs reject long strips)
    th = max(len(t) for t in tiles) + 1
    per_row = max(1, min(len(tiles), round((len(tiles) * th / ((width + 1) * 8)) ** 0.5)))
    rows = []
    for r in range(0, len(tiles), per_row):
        band = tiles[r:r + per_row]
        band += [[]] * (per_row - len(band))
        for y in range(th):
            rows.append([b for t in band for b in ((t[y] if y < len(t) else [0] * width) + [0])])
    width = len(rows[0])
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


def cmd_check():
    import shutil
    import subprocess
    import tempfile
    tmp = tempfile.mkdtemp(prefix='zxcheck-')
    try:
        for name in os.listdir('.'):
            if name not in ('build', '.git'):
                os.symlink(os.path.abspath(name), os.path.join(tmp, name))
        r = subprocess.run(['make', '-s', 'verify'], cwd=tmp, capture_output=True, text=True)
        out = (r.stdout + r.stderr).strip().splitlines()
        print('\n'.join(out[-15:]))
        return r.returncode
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


EQU = re.compile(r'^@equ=([A-Za-z_][A-Za-z0-9_]*)=(.+?)\s*$')


def cmd_const(args):
    import fcntl
    path = 'src/constants.asm'
    with open(path, 'a+') as f:
        fcntl.flock(f, fcntl.LOCK_EX)
        f.seek(0)
        have = {}
        for line in f:
            m = re.match(r'^([A-Za-z_][A-Za-z0-9_]*)\s+EQU\s+([^;]+?)\s*(;.*)?$', line)
            if m:
                have[m.group(1)] = m.group(2)
        if not args:
            f.seek(0)
            sys.stdout.write(f.read())
            return 0
        name, value = args[0], args[1]
        comment = ' '.join(args[2:])
        if name in have:
            if have[name].replace(' ', '') == value.replace(' ', ''):
                print('%s already defined' % name)
                return 0
            print('CONFLICT: %s is already %s' % (name, have[name]))
            return 1
        same = [n for n, v in have.items() if v.replace(' ', '') == value.replace(' ', '')]
        if same:
            print('note: same value as %s; reuse it if the meaning is the same' % ' '.join(same))
        f.seek(0, 2)
        f.write('%-24s EQU %s%s\n' % (name, value, ' ; ' + comment if comment else ''))
        print('added %s' % name)
    return 0


def cmd_equ_uses():
    names = {}
    for e in [None] + load():
        path = os.path.join(SKOOL_DIR, 'head.skool') if e is None else e.fname
        if os.path.exists(path):
            for line in open(path):
                m = EQU.match(line)
                if m:
                    names[parse_addr(m.group(2))] = m.group(1)
    for e in load():
        keep = False
        for line in e.lines:
            if line.startswith('@keep'):
                keep = True
                continue
            m = INSTR.match(line)
            if not m:
                continue
            ins = m.group(3).partition(';')[0].strip()
            if not ins.startswith('DEF'):
                for v in OPERAND_ADDR.findall(ins):
                    if int(v, 16) in names:
                        print('%-16s $%s  %-22s %s%s' % (names[int(v, 16)], m.group(2), ins,
                                                         e.name, '  (@keep)' if keep else ''))
            keep = False


def cmd_equs(consolidate):
    head_path = os.path.join(SKOOL_DIR, 'head.skool')
    head = open(head_path).read() if os.path.exists(head_path) else ''
    found = {}   # name -> {value: [files]}
    for path in [head_path] + [e.fname for e in load()]:
        if not os.path.exists(path):
            continue
        for line in open(path):
            m = EQU.match(line)
            if m:
                found.setdefault(m.group(1), {}).setdefault(parse_addr(m.group(2)), []).append(path)
    by_value = {}
    for name, vals in found.items():
        for v in vals:
            by_value.setdefault(v, []).append(name)
    labels = {lab for e in load() for lab in e.labels.values()}
    bad = 0
    for name, vals in sorted(found.items()):
        if len(vals) > 1:
            bad += 1
            print('CONFLICT %s: %s' % (name, ', '.join('$%04X in %s' % (v, ' '.join(f))
                                                        for v, f in vals.items())))
        if name in labels:
            bad += 1
            print('CONFLICT %s is also a @label' % name)
    for v, names in sorted(by_value.items()):
        if len(set(names)) > 1:
            print('note: $%04X has several names: %s (the last one wins in operands)'
                  % (v, ' '.join(sorted(set(names)))))
    if not consolidate:
        for name, vals in sorted(found.items(), key=lambda kv: min(kv[1])):
            for v in vals:
                print('%-24s $%04X' % (name, v))
        return 1 if bad else 0
    if bad:
        print('fix the conflicts first')
        return 1
    # names for addresses inside the disassembly become @label directives:
    # a label moves with the code, an EQU pins it
    entries = load()
    inside = {}
    for name, vals in found.items():
        v = next(iter(vals))
        for e in entries:
            if any(a == v for a, i, c in e.instr):
                inside[name] = (v, e)
                break
    for name, (v, e) in sorted(inside.items()):
        text = open(e.fname).read()
        if v in e.labels:
            if e.labels[v] != name:
                print('kept @label=%s at $%04X; @equ %s dropped (rename by hand if better)'
                      % (e.labels[v], v, name))
            continue
        lines = text.split('\n')
        for k, line in enumerate(lines):
            m = INSTR.match(line)
            if m and int(m.group(2), 16) == v:
                lines.insert(k, '@label=' + name)
                break
        open(e.fname, 'w').write('\n'.join(lines))
        e.labels[v] = name
        print('@label=%s at $%04X (%s)' % (name, v, e.fname))
    have = {m.group(1) for m in map(EQU.match, head.splitlines()) if m}
    new = ['@equ=%s=$%04X' % (n, next(iter(v))) for n, v in sorted(found.items(), key=lambda kv: min(kv[1]))
           if n not in have and n not in inside]
    if new:
        lines = head.rstrip('\n').split('\n') if head.strip() else []
        open(head_path, 'w').write('\n'.join(lines + new) + '\n')
    moved = 0
    for e in load():
        text = open(e.fname).read()
        kept = [line for line in text.split('\n') if not EQU.match(line)]
        if len(kept) != len(text.split('\n')):
            moved += 1
            open(e.fname, 'w').write('\n'.join(kept))
    print('head.skool: %d new constants; cleaned %d entry files' % (len(new), moved))
    return 0


FINDING_STATUS = ('observed', 'inferred', 'unknown', 'refuted')
QUESTION_STATUS = ('open', 'partial', 'answered')
REGISTERS = {
    'finding': ('re/findings.md', 'F', ['ID', 'Status', 'Claim', 'Evidence', 'Refs'],
                '# Findings\n\nEvery claim about the game with its status and evidence. '
                '`observed`: seen in the simulator, a byte check or a test; `inferred`: '
                'read from code, not run; `unknown`: open; `refuted`: shown wrong (keep it). '
                'Only observed evidence can make a claim observed. Edit through '
                '`tools/zxq.py finding`.\n\n'),
    'question': ('re/questions.md', 'Q', ['ID', 'Status', 'Question', 'Answer'],
                 '# Questions\n\nWhat this reverse engineering must answer; revisit before '
                 'finishing. Edit through `tools/zxq.py question`.\n\n'),
}


def table_cell(text):
    return ' '.join(str(text).replace('|', '/').split())


def registry(kind, op, args):
    """Add to or update a markdown-table register under a file lock."""
    import fcntl
    path, prefix, cols, intro = REGISTERS[kind]
    statuses = FINDING_STATUS if kind == 'finding' else QUESTION_STATUS
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'a+') as f:
        fcntl.flock(f, fcntl.LOCK_EX)
        f.seek(0)
        text = f.read()
        if '| ID |' not in text:
            text = (text or intro) + '| ' + ' | '.join(cols) + ' |\n' + '| --- ' * len(cols) + '|\n'
        lines = text.rstrip('\n').split('\n')
        rows = [i for i, line in enumerate(lines) if re.match(r'^\| %s\d+ \|' % prefix, line)]
        if op == 'add':
            if kind == 'finding':
                status, claim, evidence = args[0], args[1], args[2]
                refs = args[3] if len(args) > 3 else ''
                cells = [status, claim, evidence, refs]
            else:
                status, cells = 'open', ['open', args[0], '']
            if status not in statuses:
                print('status must be one of: ' + ', '.join(statuses))
                return 1
            n = 1 + max([int(re.match(r'^\| %s(\d+)' % prefix, lines[i]).group(1)) for i in rows] or [0])
            rid = '%s%d' % (prefix, n)
            lines.append('| %s | %s |' % (rid, ' | '.join(table_cell(c) for c in cells)))
            print('added ' + rid)
        else:
            rid, status, note = args[0], args[1], args[2]
            if status not in statuses:
                print('status must be one of: ' + ', '.join(statuses))
                return 1
            hit = [i for i in rows if lines[i].startswith('| %s |' % rid)]
            if not hit:
                print('no %s %s' % (kind, rid))
                return 1
            cells = [c.strip() for c in lines[hit[0]].strip('|').split('|')]
            cells[1] = status
            col = 3 if kind == 'finding' else 3
            cells[col] = table_cell((cells[col] + '; ' if cells[col] else '') + note)
            lines[hit[0]] = '| ' + ' | '.join(cells) + ' |'
            print('updated %s: %s' % (rid, status))
        f.seek(0)
        f.truncate()
        f.write('\n'.join(lines) + '\n')
    return 0


def read_register(kind):
    path, prefix, cols, intro = REGISTERS[kind]
    out = []
    if os.path.exists(path):
        for line in open(path):
            if re.match(r'^\| %s\d+ \|' % prefix, line):
                out.append([c.strip() for c in line.strip().strip('|').split('|')])
    return out


def cmd_audit():
    qs, fs = read_register('question'), read_register('finding')
    count = lambda rows, st: sum(1 for r in rows if r[1] == st)
    print('questions: %d answered, %d partial, %d open' % (
        count(qs, 'answered'), count(qs, 'partial'), count(qs, 'open')))
    print('findings: %d observed, %d inferred, %d unknown, %d refuted' % tuple(
        count(fs, st) for st in FINDING_STATUS))
    for r in qs:
        if r[1] != 'answered':
            print('  %s %-8s %s' % (r[0], r[1], r[2]))
    for r in fs:
        if r[1] in ('unknown', 'inferred'):
            print('  %s %-8s %s' % (r[0], r[1], r[2][:100]))
    return 1 if count(qs, 'open') or count(fs, 'unknown') else 0


def cmd_cut(addr, title):
    """Split an entry at ADDR into a new entry titled TITLE, keeping every
    annotation (comments, @label, @isub) with the instruction it belongs to."""
    e = next((e for e in load() if e.addr < addr <= e.end), None)
    if e is None:
        sys.exit('$%04X is not inside an entry (or already starts one)' % addr)
    lines = e.text.rstrip('\n').split('\n')
    i = next((n for n, l in enumerate(lines)
              if (m := INSTR.match(l)) and int(m.group(2), 16) == addr), None)
    if i is None:
        sys.exit('no instruction at $%04X in %s' % (addr, e.fname))
    j = i
    while j > 0 and lines[j - 1].startswith(('@', ';')):
        j -= 1
    pre = lines[j:i]
    first = e.ctype + lines[i][1:]
    new = ['; ' + title]
    comments = [l for l in pre if l.startswith(';')]
    if comments:
        new += [';'] + comments
    new += [l for l in pre if l.startswith('@')] + [first] + lines[i + 1:]
    open(e.fname, 'w').write('\n'.join(lines[:j]) + '\n')
    open(os.path.join(SKOOL_DIR, '%04X.skool' % addr), 'w').write('\n'.join(new) + '\n')
    print('%s -> $%04X-$%04X and $%04X-$%04X' % (e.name, e.addr, addr - 1, addr, e.end))


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
    # keep an @org that opened a replaced entry (the first entry of a block)
    org = {e.addr for e in hit if re.match(r'@org\b', e.text)}
    for e in new:
        if e.addr in org and not re.match(r'@org\b', e.text):
            e.text = '@org\n' + e.text
    for e in hit:
        os.remove(e.fname)
    for e in new:
        open(os.path.join(SKOOL_DIR, '%04X.skool' % e.addr), 'w').write(e.text)
    print('replaced %d entries with %d: %s' % (len(hit), len(new),
                                              ' '.join('$%04X' % e.addr for e in new)))


def cmd_asm(skool):
    """skool2asm for sjasmplus: ORG lines below $SHIFT_END get +SHIFT so the
    shift test can move the code; skool2asm writes IXl/IXh/IYl/IYh, which
    sjasmplus rejects in mixed case (unless --syntax=i), so they become
    IXL/IXH/IYL/IYH."""
    import subprocess
    r = subprocess.run(['skool2asm.py', '-q', '-w', '-H', '-c', skool], capture_output=True, text=True)
    if r.returncode:
        sys.exit(r.stderr)
    org = re.compile(r'^( +ORG +)(\$[0-9A-Fa-f]+)\s*$')
    half = re.compile(r'\b(I[XY])([hl])\b')
    shift_end = int(os.environ.get('SHIFT_END') or '0x10000', 0)
    for line in r.stdout.split('\n')[:-1] if r.stdout.endswith('\n') else r.stdout.split('\n'):
        m = org.match(line)
        if m and int(m.group(2)[1:], 16) < shift_end:
            line = org.sub(r'\1\2+SHIFT', line)
        print(half.sub(lambda m: m.group(1) + m.group(2).upper(), line))


def cmd_export(asm_path, modules_path, outdir):
    """Split skool2asm output into modules by address ranges.

    MODULES lines: `START NAME` (hex start address, module file stem); each
    entry goes to the last module starting at or before it. The ASM must have
    been written from the joined skool (same entry order)."""
    entries = [e for e in load() if e.ctype != 'i']
    chunks = re.split(r'\n\n+', open(asm_path).read().strip('\n'))
    # leading chunks of EQU/ORG lines only (from @equ and @org) are the header
    directive = re.compile(r'^\s*(\w+\s+EQU\s|ORG\s)', re.I)
    head = []
    while chunks and all(directive.match(line) for line in chunks[0].split('\n')):
        head.append(chunks.pop(0))
    head = '\n\n'.join(head)
    if len(chunks) != len(entries):
        sys.exit('asm has %d entries, skool has %d: cannot split' % (len(chunks), len(entries)))
    mods = []
    for line in open(modules_path):
        line = line.split('#')[0].split()   # `START NAME  # comment`
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
    elif cmd == 'cut' and len(a) == 3:
        cmd_cut(parse_addr(a[1]), a[2])
    elif cmd == 'reclassify' and len(a) in (2, 3):
        cmd_reclassify(a[1], a[2:] == ['-f'])
    elif cmd == 'peek' and len(a) in (2, 3):
        cmd_peek(parse_addr(a[1]), parse_addr(a[2]) if len(a) == 3 else 64)
    elif cmd == 'strings':
        cmd_strings(int(a[1]) if len(a) > 1 else 5,
                    *(parse_addr(x) for x in a[2:4]))
    elif cmd == 'gfx' and 5 <= len(a) <= 8:
        cmd_gfx(parse_addr(a[1]), parse_addr(a[2]), int(a[3]), a[4], 'cells' in a[5:],
                next((int(x) for x in a[5:] if x.isdigit()), 4),
                next((parse_addr(x[6:]) for x in a[5:] if x.startswith('block=')), 0))
    elif cmd == 'check':
        sys.exit(cmd_check())
    elif cmd == 'equs' and '--uses' in a:
        cmd_equ_uses()
    elif cmd == 'equs':
        sys.exit(cmd_equs('--consolidate' in a))
    elif cmd == 'const' and len(a) in (1, 3) or cmd == 'const' and len(a) > 3:
        sys.exit(cmd_const(a[1:]))
    elif cmd in ('finding', 'question') and len(a) >= 3 and a[1] in ('add', 'set'):
        sys.exit(registry(cmd, a[1], a[2:]))
    elif cmd == 'findings':
        for r in read_register('finding'):
            if len(a) == 1 or r[1] in a[1:]:
                print(' | '.join(r))
    elif cmd == 'audit':
        sys.exit(cmd_audit())
    elif cmd == 'cmp' and len(a) == 4:
        cmd_cmp(a[1], a[2], parse_addr(a[3]))
    elif cmd == 'asm' and len(a) == 2:
        cmd_asm(a[1])
    elif cmd == 'export' and len(a) == 4:
        cmd_export(a[1], a[2], a[3])
    else:
        sys.exit(__doc__)


if __name__ == '__main__':
    import signal
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)   # quiet exit under `| head`
    main()
