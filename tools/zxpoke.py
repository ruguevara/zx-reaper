#!/usr/bin/env python3
"""Find POKEs (lives, energy, time, rooms) and developer cheats in a 48K game.

  zxpoke.py search SNAP --input X.txt --at F=SPEC [--at F=SPEC ...]
      addresses that hold SPEC at frame F. SPEC is a number (matched as the
      value, value-1, value+1, an ASCII digit and BCD; --enc narrows it) or
      a change since the previous --at: same, changed, dec, inc, less, more;
      the first may be `any` (every address)
  zxpoke.py profile SNAP --input X.txt [--from F] [--changes LO-HI]
      [--max V] [--step N] [--near F,F...]
      every address that changes after frame --from, with its history;
      filters: number of changes, largest value, every change +-N, a change
      within 2 frames of each --near frame (deaths seen on screen)
  zxpoke.py trace SNAP --input X.txt ADDR...
      every change of each address, frame by frame
  zxpoke.py writers SNAP --input X.txt ADDR [--from F] [--depth N]
      the instructions that write ADDR, the ones executed before each, and
      the POKEs that would stop or change the write (to be checked); when a
      writer is reached in several ways (a kill routine called by each cause
      of death), the last N jumps of each path: the patch goes on the path
  zxpoke.py check SNAP --input X.txt --poke A,V [--poke ...] [--with A,V]
      [--addr ADDR...] [--shot F:PNG]
      the same input with and without the POKEs (--with: in both runs, e.g.
      a start room next to the hazard): each --addr's values, the first
      frame the screen differs, whether the patched game still moves
  zxpoke.py pok FILE.pok [--apply SNAP OUT.z80] [--check]
      list a .pok file (the format of World of Spectrum's POKE database);
      --apply writes a patched snapshot for Fuse; --check compares each
      POKE's original value with SNAP
  zxpoke.py keys
      keyboard reads in the code (IN with the keys of the half-rows it
      reads, the ROM's key routines, LAST_K and the KSTATE system
      variables) by entry, marked NEVER RAN when no re/maps/*.map has
      them: where a typed cheat or a secret key combination is looked for
  zxpoke.py keytab ADDR COUNT --rows HI[,HI...]
      decode a table of key masks (a cheat word stored as the bits IN reads):
      COUNT groups of one byte per half-row, the rows given by the high
      bytes of their ports ($FB = Q-T, $DF = P-Y, ...); prints the keys

Run options for every command that runs the game: --input (zxrun.py input
script), --fuzz SEED:HOLD:KEYS, --frames N, --poke A,V (applied before the
run, e.g. infinite lives while looking for the room variable), --range A-B
(memory searched, default $5B00-$FFFF), --referenced (only addresses the
code names as operands: variables, not bytes inside buffers). Addresses: $8000, 0x8000 or 32768.
SNAP is normally re/orig.z80. With re/skool/ present, addresses are shown
with their entry and label.

A POKE is ADDRESS,VALUE in decimal on the Spectrum (POKE 35899,0); this tool
prints both. Nothing a search prints is a POKE until `check` has run it.
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from skoolkit import CSimulator, SkoolKitError  # noqa: E402
from skoolkit.components import get_component  # noqa: E402
from skoolkit.simulator import Simulator  # noqa: E402
from skoolkit.simutils import from_snapshot, get_state  # noqa: E402
from skoolkit.snapshot import Snapshot, write_snapshot  # noqa: E402
from skoolkit.snaskool import DisassemblerConfig, Instruction  # noqa: E402

import zxrun  # noqa: E402
from zxrun import PC, T, IFF, Tracer, parse_input, fuzz_input, png, short_hash  # noqa: E402

ROM_KEYS = {0x028E: 'KEY_SCAN', 0x02BF: 'KEYBOARD', 0x031E: 'K_TEST', 0x0333: 'K_DECODE',
            0x10A8: 'KEY_INPUT', 0x15D4: 'WAIT_KEY', 0x15E6: 'INPUT_AD', 0x1F54: 'BREAK_KEY'}
SYSVAR_KEYS = {0x5C00: 'KSTATE', 0x5C04: 'KSTATE+4', 0x5C08: 'LAST_K', 0x5C3B: 'FLAGS'}


def addr(s):
    s = s.strip()
    return int(s[1:], 16) if s.startswith('$') else int(s, 0)


def hexdec(a):
    return '$%04X (%d)' % (a, a)


# --- the run -------------------------------------------------------------

def load_events(args):
    events = []
    if args.input:
        events = parse_input(args.input)
    elif args.fuzz:
        events = fuzz_input(args.fuzz, args.frames or 500)
    events = sorted(events, key=lambda e: e[0])
    ends = [f for f, keys in events if keys is None]
    if args.frames is None:
        args.frames = ends[0] if ends else 500
    return [e for e in events if e[1] is not None]


def make_sim(args, pokes=None, python=False):
    snap = Snapshot.get(args.snapshot)
    if snap is None:
        sys.exit('cannot read snapshot %s' % args.snapshot)
    sim = from_snapshot(Simulator if python else (CSimulator or Simulator), snap, {}, None,
                        {'fast_djnz': False, 'fast_ldir': False})
    for a, v in (args.poke if pokes is None else pokes):
        sim.memory[a] = v
    tracer = Tracer()
    tracer.border = [(0, snap.border)]
    tracer.outfe = snap.outfe
    sim.set_tracer(tracer)
    return sim, tracer


def run(args, on_frame, pokes=None):
    """Run the input; on_frame(n, memory) after each frame n (0-based) returns
    False to stop. Returns the simulator."""
    events = load_events(args)
    sim, tracer = make_sim(args, pokes)
    f0 = sim.registers[T] // sim.frame_duration
    state = {'ev': 0}
    if events and events[0][0] <= 0:
        tracer.set_keys(events[0][1])

    def frame(scr, fr, border, kb):
        n = fr - f0 - 1
        go = on_frame(n, sim.memory) is not False
        while state['ev'] < len(events) and events[state['ev']][0] <= n + 1:
            tracer.set_keys(events[state['ev']][1])
            state['ev'] += 1
        return go and n + 1 < args.frames
    sim.trace(sim.registers[PC], -1, 0, 0, 1, frame, None, tracer.keyboard, None, None)
    return sim


def changed(old, new, lo):
    """Offsets (from lo) where two equal-length byte strings differ."""
    out = []
    for k in range(0, len(new), 256):
        if new[k:k + 256] != old[k:k + 256]:
            out += [lo + i for i in range(k, min(k + 256, len(new))) if new[i] != old[i]]
    return out


# --- labels from re/skool --------------------------------------------------

class Where:
    def __init__(self):
        self.idx = None
        if os.path.isdir(os.environ.get('ZXQ_SKOOL', 're/skool')):
            import zxq
            self.idx = zxq.Index(zxq.load())
            self.labels = {}
            for e in self.idx.entries:
                self.labels.update(e.labels)

    def __call__(self, a):
        if not self.idx:
            return ''
        if a in self.labels:
            return self.labels[a]
        e = self.idx.find(a)
        if not e:
            return ''
        base = max((x for x in e.labels if x <= a), default=e.addr)
        name = e.labels.get(base) or '$%04X' % base
        return name if base == a else '%s+%d' % (name, a - base)

    def referenced(self, a):
        """True when code names `a` as an operand (a variable rather than a
        byte inside a buffer); always True without re/skool."""
        return self.idx is None or a in self.idx.ref_lines

    def title(self, a):
        e = self.idx.find(a) if self.idx else None
        return '%s %s' % (e.name, e.title) if e else ''


# --- search ----------------------------------------------------------------

def encodings(v, allowed):
    """(name, byte) a counter showing v could be stored as."""
    out = []
    for name, b in (('value', v), ('value-1', v - 1), ('value+1', v + 1),
                    ('ascii', 0x30 + v if 0 <= v <= 9 else None),
                    ('bcd', int(str(v), 16) if 0 <= v <= 99 else None)):
        if b is not None and 0 <= b <= 255 and name in allowed:
            out.append((name, b))
    return out


RELATIVE = {'same': lambda a, b: a == b, 'changed': lambda a, b: a != b,
            'dec': lambda a, b: b == (a - 1) & 255, 'inc': lambda a, b: b == (a + 1) & 255,
            'less': lambda a, b: b < a, 'more': lambda a, b: b > a}


def cmd_search(args):
    specs = []
    for s in args.at:
        f, _, spec = s.partition('=')
        specs.append((int(f), spec.strip().lower()))
    specs.sort()
    if specs[0][1] in RELATIVE:
        sys.exit('the first --at needs a value or any; later ones may be %s' % ', '.join(RELATIVE))
    lo, hi = args.range
    want = {f for f, _ in specs}
    snaps = {}

    def on_frame(n, mem):
        if n in want:
            snaps[n] = bytes(mem[lo:hi])
        return n < max(want)
    args.frames = max(want) + 1
    run(args, on_frame)
    allowed = args.enc.split(',')
    # candidates: (address, encoding name, offset of the byte from the shown value)
    cands = None
    for f, spec in specs:
        mem = snaps.get(f)
        if mem is None:
            sys.exit('the run ended before frame %d' % f)
        if spec == 'any':
            cands = [(lo + i, 'value') for i in range(len(mem))] if cands is None else cands
        elif spec in RELATIVE:
            prev = snaps[prevf]
            cands = [c for c in cands if RELATIVE[spec](prev[c[0] - lo], mem[c[0] - lo])]
        else:
            v = int(spec, 0)
            enc = dict(encodings(v, allowed))
            if cands is None:
                cands = [(lo + i, name) for i, b in enumerate(mem) for name, e in enc.items() if b == e]
            else:
                cands = [c for c in cands if c[1] in enc and mem[c[0] - lo] == enc[c[1]]]
        prevf = f
        print('frame %d %s: %d candidates' % (f, spec, len(cands)))
    where = Where()
    if args.referenced:
        cands = [c for c in cands if where.referenced(c[0])]
        print('named by the code: %d candidates' % len(cands))
    if args.max is not None:
        cands = [c for c in cands if all(snaps[f][c[0] - lo] <= args.max for f, _ in specs)]
        print('at most %d: %d candidates' % (args.max, len(cands)))
    for a, name in cands[:args.limit]:
        vals = ' '.join('%d' % snaps[f][a - lo] for f, _ in specs)
        print('%s  %-8s %s  %s' % (hexdec(a), name, vals, where(a)))
    if len(cands) > args.limit:
        print('... %d more (narrow with another --at)' % (len(cands) - args.limit))


# --- profile and trace -----------------------------------------------------

def histories(args, addrs=None):
    """{address: [(frame, value), ...]} from frame --from: the value then and
    every change after. `addrs`: only these (else the whole --range)."""
    lo, hi = args.range
    hist, prev = {}, {}

    def on_frame(n, mem):
        if n < args.start:
            return
        cur = bytes(mem[lo:hi])
        if 'mem' not in prev:
            for a in (addrs or range(lo, hi)):
                hist[a] = [(n, cur[a - lo])]
        else:
            for a in changed(prev['mem'], cur, lo):
                if addrs is None or a in hist:
                    h = hist[a]
                    if len(h) <= args.keep:
                        h.append((n, cur[a - lo]))
        prev['mem'] = cur
    run(args, on_frame)
    return hist


def counter_like(h, args):
    vals = [v for _, v in h]
    n = len(h) - 1
    if args.changes and not args.changes[0] <= n <= args.changes[1]:
        return False
    if args.max is not None and max(vals) > args.max:
        return False
    if args.step and any(abs(b - a) != args.step for a, b in zip(vals, vals[1:])):
        return False
    if args.near and not all(any(abs(f - g) <= 2 for f, _ in h[1:]) for g in args.near):
        return False
    return n > 0


def show_history(h, limit=12):
    s = ' '.join('%d@%d' % (v, f) for f, v in h[:limit])
    return s + (' ...(%d more)' % (len(h) - limit) if len(h) > limit else '')


def cmd_profile(args):
    hist = histories(args)
    where = Where()
    hits = [(a, h) for a, h in sorted(hist.items()) if counter_like(h, args)
            and (not args.referenced or where.referenced(a))]
    print('%d addresses changed after frame %d; %d pass the filters'
          % (sum(len(h) > 1 for h in hist.values()), args.start, len(hits)))
    for a, h in hits[:args.limit]:
        print('%s  %-20s %s' % (hexdec(a), where(a), show_history(h)))
    if len(hits) > args.limit:
        print('... %d more (filter with --changes, --max, --step, --near)' % (len(hits) - args.limit))


def cmd_trace(args):
    hist = histories(args, args.addr)
    where = Where()
    for a in args.addr:
        print('%s %s' % (hexdec(a), where(a)))
        for f, v in hist[a]:
            print('  frame %6d  %3d  $%02X' % (f, v, v))


# --- writers ---------------------------------------------------------------

def disassembler(mem):
    return get_component('Disassembler', mem,
                         DisassemblerConfig(True, False, 8, 65, 1, 0, Instruction, '', 0))


def instr(dis, a):
    i = dis.disassemble(a, a + 1, 'h')[0]
    return i.operation, list(i.bytes)


SETS_A = ('LDA,', 'DECA', 'INCA', 'SUB', 'ADDA', 'ADCA', 'SBCA', 'AND', 'OR', 'XOR', 'NEG',
          'CPL', 'RLA', 'RRA', 'RLCA', 'RRCA', 'POPAF', 'EXAF', 'INA,')


def proposals(dis, pc, before):
    """POKEs that would stop or change the write at pc: (address, value,
    what it does). `before`: the PCs executed just before, oldest first."""
    op, b = instr(dis, pc)
    out = []
    o = op.upper().replace(' ', '')
    if o.startswith(('DEC(', 'INC(')):
        out.append((pc, [0] * len(b), '%s -> NOP: the value never changes here' % op))
    elif o.startswith('LD(') and o.endswith('),A') and b[0] == 0x32:
        out.append((pc, [0x3A], '%s -> LD A,(nn): reads instead of writing' % op))
    elif o.startswith('LD(') and o.endswith(('),HL', '),DE', '),BC')) and b[0] in (0x22, 0xED):
        out.append((pc, [0x2A] if b[0] == 0x22 else [0xED, b[1] + 8],
                    '%s -> load: reads instead of writing' % op))
    elif o in ('LD(HL),A',):
        out.append((pc, [0], '%s -> NOP' % op))
    elif o.startswith(('LD(HL),', 'LD(IX', 'LD(IY')) and not o.endswith(
            (',A', ',B', ',C', ',D', ',E', ',H', ',L')):
        out.append((pc + len(b) - 1, [b[-1]], '%s: the value written is this byte' % op))
    a_done = not o.endswith(',A')        # the write stores A: what set A last?
    for p in reversed(before[-4:]):
        pop, pb = instr(dis, p)
        po = pop.upper().replace(' ', '')
        if po.startswith(('JRNZ', 'JRZ', 'JRNC', 'JRC')):
            if (p + 2 + (pb[1] ^ 128) - 128) & 0xFFFF > pc:
                out.insert(0, (p, [0x18], '%s -> JR: always jumps past the write' % pop))
            else:
                out.append((p, [0, 0], '%s -> NOPs: never jumps' % pop))
        elif po.startswith('JP') and len(pb) == 3 and pb[0] & 0xC7 == 0xC2:
            if pb[1] + 256 * pb[2] > pc:
                out.insert(0, (p, [0xC3], '%s -> JP: always jumps past the write' % pop))
        elif not a_done and po.startswith(SETS_A):
            a_done = True
            if po in ('DECA', 'INCA'):
                out.append((p, [0], '%s -> NOP (before the write)' % pop))
            elif po.startswith(('SUB', 'ADDA,', 'SBCA,', 'ADCA,')) and len(pb) == 2:
                out.append((p + 1, [0], '%s -> operand 0 (before the write)' % pop))
            elif po.startswith('LDA,') and len(pb) == 2:
                out.append((p + 1, [pb[1]], '%s: the value written (set it)' % pop))
    return op, out


def never(dis, p):
    """POKEs that make the jump at p never taken, as text, or None."""
    op, b = instr(dis, p)
    if b[0] in (0x20, 0x28, 0x30, 0x38, 0x10):          # JR cc / DJNZ: jump to the next
        return 'POKE %d,0 (%s -> offset 0)' % (p + 1, op)
    if b[0] & 0xC7 in (0xC2, 0xC4):                      # JP cc / CALL cc: 3 NOPs
        return 'POKE %d,0 POKE %d,0 POKE %d,0 (%s -> NOPs)' % (p, p + 1, p + 2, op)
    if b[0] & 0xC7 == 0xC0:                              # RET cc
        return 'POKE %d,0 (%s -> NOP)' % (p, op)
    return None


def transfer(mem, frm):
    """What the instruction at frm did when control left it: 'call' (CALL,
    RST), 'ret' (RET, RETI, RETN) or 'jump'."""
    op = mem[frm]
    if op == 0xCD or op & 0xC7 in (0xC4, 0xC7):
        return 'call'
    if op == 0xC9 or op & 0xC7 == 0xC0 or op == 0xED and mem[(frm + 1) & 0xFFFF] in (0x45, 0x4D):
        return 'ret'
    return 'jump'


def cmd_writers(args):
    target = args.addr[0]
    events = load_events(args)
    sim, tracer = make_sim(args)
    f0 = sim.registers[T] // sim.frame_duration
    if args.start:
        frames, args.frames = args.frames, args.start
        state = {'ev': 0}

        def frame(scr, fr, border, kb):
            n = fr - f0 - 1
            while state['ev'] < len(events) and events[state['ev']][0] <= n + 1:
                tracer.set_keys(events[state['ev']][1])
                state['ev'] += 1
            return n + 1 < args.frames
        if events and events[0][0] <= 0:
            tracer.set_keys(events[0][1])
        sim.trace(sim.registers[PC], -1, 0, 0, 1, frame, None, tracer.keyboard, None, None)
        args.frames = frames
        events = events[state['ev']:]
    found = {}         # pc -> [count, before, (frame, old, new) of the first, last value, paths]
    recent = []        # the PCs executed last
    levels = [[]]      # shadow call stack: the calls and forward jumps that led here
    interrupted = [False]

    class WatchMem(list):
        def __setitem__(self, i, v):
            if i == target:
                old = list.__getitem__(self, i)
                fr = regs[T] // psim.frame_duration - f0
                rec = found.get(psim.cur_pc)
                if rec is None:
                    found[psim.cur_pc] = rec = [0, list(recent), (fr, old, v), 0, {}]
                rec[0] += 1
                rec[3] = v
                path = tuple([j for lv in levels for j in lv][-args.depth:])
                rec[4][path] = rec[4].get(path, 0) + 1
            list.__setitem__(self, i, v)

    psim = Simulator(WatchMem(sim.memory), config={'frame_duration': sim.frame_duration})
    regs = psim.registers
    for i in range(len(regs)):
        regs[i] = sim.registers[i]
    psim.set_tracer(tracer)
    mem, opcodes = psim.memory, psim.opcodes
    fd, ia = psim.frame_duration, psim.int_active
    prev_frame = regs[T] // fd
    next_int = ((regs[T] + fd - ia) // fd) * fd
    ev = 0
    while True:
        pc = psim.cur_pc = regs[PC]
        opcodes[mem[pc]]()
        if recent and not 0 <= pc - recent[-1] <= 4:      # (HALT repeats itself)
            frm = recent[-1]
            kind = 'call' if interrupted[0] else transfer(mem, frm)
            interrupted[0] = False
            if kind == 'call':
                levels[-1].append((frm, pc))
                levels.append([])
            elif kind == 'ret':
                if len(levels) > 1:
                    levels.pop()
                    if levels[-1]:
                        levels[-1].pop()
                else:                            # the run started inside a call
                    levels[0] = []
            elif pc > frm or mem[frm] not in (0x10, 0x18, 0x20, 0x28, 0x30, 0x38):
                levels[-1].append((frm, pc))     # not a loop's JR or DJNZ back
                del levels[-1][:-8]
            if len(levels) > 64:                 # unbalanced stack tricks: start again
                levels[:] = [[]]
        recent.append(pc)
        if len(recent) > 6:
            del recent[0]
        t = regs[T]
        if t >= next_int:
            if t < next_int + ia:
                if regs[IFF]:
                    psim.cur_pc = -1
                    psim.accept_interrupt(regs, mem, pc)
                    interrupted[0] = True
                fr = regs[T] // fd
                if fr > prev_frame:
                    prev_frame = fr
                    n = fr - f0 - 1
                    while ev < len(events) and events[ev][0] <= n + 1:
                        tracer.set_keys(events[ev][1])
                        ev += 1
                    if n + 1 >= args.frames:
                        break
            else:
                next_int += fd
    where = Where()
    dis = disassembler(list(mem))
    if not found:
        print('no writes to %s in frames %d-%d' % (hexdec(target), args.start, args.frames))
    for pc, (count, before, first, last, paths) in sorted(found.items()):
        if pc < 0:
            print('interrupt (a stack push): %d writes' % count)
            continue
        op, props = proposals(dis, pc, [p for p in before if p != pc])
        print('PC=%s %-16s %s  %d writes, first frame %d %d->%d, last value %d'
              % (hexdec(pc), op, where(pc), count, first[0], first[1], first[2], last))
        for p in before[-3:]:
            if p != pc:
                print('    before: $%04X %s' % (p, instr(dis, p)[0]))
        for a, vals, what in props:
            pokes = ' '.join('POKE %d,%d' % (a + k, v) for k, v in enumerate(vals))
            print('    try %s   (%s)' % (pokes, what))
        if len(paths) > 1 or args.paths:
            print('    reached by %d paths (the last %d jumps before the write):'
                  % (len(paths), args.depth))
            for path, n in sorted(paths.items(), key=lambda x: -x[1])[:args.paths or 8]:
                print('      %4dx  %s' % (n, '  '.join(
                    '$%04X %s [%s] ->' % (f, instr(dis, f)[0], where(f) or '?') for f, t in path)
                    or '(no call or jump since the run started)'))
                block = never(dis, path[-1][0]) if path else None
                if block:
                    print('             block this path: %s' % block)


# --- check -----------------------------------------------------------------

def cmd_check(args):
    if not args.poke:
        sys.exit('check needs --poke')
    shots = dict((int(f), p) for f, _, p in (s.partition(':') for s in args.shot))
    runs = []
    for label, pokes in (('original', args.with_), ('patched', args.with_ + args.poke)):
        rec = {'vals': {a: [] for a in args.addr}, 'scr': [], 'pcs': []}

        def on_frame(n, mem, rec=rec, label=label):
            for a in args.addr:
                v = mem[a]
                if not rec['vals'][a] or rec['vals'][a][-1][1] != v:
                    rec['vals'][a].append((n, v))
            rec['scr'].append(short_hash(mem[0x4000:0x5B00]))
            if label == 'patched' and n in shots:
                png(mem[0x4000:0x5B00], shots[n])
        sim = run(args, on_frame, pokes)
        rec['pc'] = sim.registers[PC]
        runs.append((label, rec))
    (_, a), (_, b) = runs
    for adr in args.addr:
        for label, rec in runs:
            vals = [v for _, v in rec['vals'][adr]]
            print('%s %-8s changes %4d  min %3d max %3d  end %3d   %s' % (
                hexdec(adr), label, len(vals) - 1, min(vals), max(vals), vals[-1],
                show_history(rec['vals'][adr], 8)))
    diff = next((n for n, (x, y) in enumerate(zip(a['scr'], b['scr'])) if x != y), None)
    print('screens: %s' % ('identical for all %d frames' % len(a['scr']) if diff is None
                           else 'first differ at frame %d' % diff))
    for label, rec in runs:
        tail = rec['scr'][-200:]
        print('%-8s ran %d frames, end PC=$%04X, %d different screens in the last %d frames'
              % (label, len(rec['scr']), rec['pc'], len(set(tail)), len(tail)))
    for f, p in sorted(shots.items()):
        print('wrote %s (patched, frame %d)' % (p, f))


# --- .pok files ------------------------------------------------------------

def read_pok(path):
    """[(name, [(bank, address, value, original)])] from a .pok file. Value
    256 means 'ask the user'."""
    out = []
    for line in open(path, encoding='latin-1'):
        line = line.rstrip('\r\n')
        if not line or line[0] == 'Y':
            if line[:1] == 'Y':
                break
            continue
        if line[0] == 'N':
            out.append((line[1:].strip(), []))
        elif line[0] in 'MZ':
            bank, a, v, orig = (int(x) for x in line[1:].split()[:4])
            out[-1][1].append((bank, a, v, orig))
    return out


def cmd_pok(args):
    if not os.path.exists(args.file):
        sys.exit('no %s (skill zx-poke writes it)' % args.file)
    trainers = read_pok(args.file)
    mem = None
    if args.apply or args.check:
        args.snapshot, args.poke = args.snapshot_in, []
        sim, _ = make_sim(args, python=True)
        mem = sim.memory
    bad = 0
    for name, pokes in trainers:
        print(name)
        for bank, a, v, orig in pokes:
            note = ''
            if mem is not None and mem[a] != orig:
                note = '   snapshot has %d, not %d' % (mem[a], orig)
                bad += 1
            print('  POKE %d,%s   ($%04X: %02X -> %s)%s' % (
                a, 'ask' if v == 256 else v, a, orig, 'ask' if v == 256 else '%02X' % v, note))
            if args.apply and v < 256:
                mem[a] = v
    if args.apply:
        ram, registers, st, machine = get_state(sim)
        write_snapshot(args.apply, ram, registers, st, machine)
        print('wrote %s' % args.apply)
    if args.check:
        print('%s' % ('every original value matches' if not bad else '%d original values differ' % bad))
        sys.exit(1 if bad else 0)


# --- keys ------------------------------------------------------------------

def half_rows(high):
    """The keys a read of port high*256+$FE sees (a 0 bit selects a row)."""
    rows = [zxrun.ROWS[r] for r in range(8) if not high & (1 << r)]
    return ' | '.join(rows) if rows else 'no row'


def port_of(e, a, ins):
    """The port an IN at a reads, from the instructions before it in entry e."""
    u = ins.upper().replace(' ', '')
    prev = [i for x, i, _ in e.instr if x < a][-8:]
    if u.startswith('INA,($'):
        if u[6:8] == '1F':
            return 0x1F
        for p in reversed(prev):
            m = p.upper().replace(' ', '')
            if m.startswith('LDA,$') and len(m) == 7:
                return int(m[5:7], 16) * 256 + int(u[6:8], 16)
            if m.startswith(SETS_A):
                return None
        return None
    for p in reversed(prev):
        m = p.upper().replace(' ', '')
        if m.startswith('LDBC,$') and len(m) == 10:
            return int(m[6:10], 16)
        if m.startswith('LDB,$') and len(m) == 7:
            return int(m[5:7], 16) * 256 + 0xFE
    return None


def cmd_keys(args):
    import glob
    import zxq
    idx = zxq.Index(zxq.load())
    maps = glob.glob('re/maps/*.map')
    ran = zxq.read_map(maps) if maps else None
    hits = []
    for e in idx.entries:
        if e.ctype not in 'c*':
            continue
        for a, ins, _ in e.instr:
            u = ins.upper()
            note = None
            if u.startswith('IN '):
                port = port_of(e, a, ins)
                if port is None:
                    note = 'port set elsewhere'
                elif port & 0xFF == 0x1F:
                    note = 'Kempston'
                elif port & 1 == 0:
                    note = 'keys %s' % half_rows(port >> 8)
                else:
                    note = 'port $%04X' % port
            elif u.startswith(('CALL', 'JP')) and not u.startswith('JP (') and '$' in u:
                t = int(u.rsplit('$', 1)[1][:4], 16)
                if t in ROM_KEYS:
                    note = 'ROM %s' % ROM_KEYS[t]
            for m in zxq.OPERAND_ADDR.finditer(ins):
                t = int(m.group(1), 16)
                if t in SYSVAR_KEYS and '(' in ins:
                    note = SYSVAR_KEYS[t]
            if note:
                if ran is not None:
                    note += '' if a in ran else '   NEVER RAN'
                hits.append((a, ins, note, e))
    by_entry = {}
    for h in hits:
        by_entry.setdefault(h[3].addr, []).append(h)
    for ea, lst in sorted(by_entry.items()):
        print(idx.brief(ea))
        for a, ins, note, _ in lst:
            print('    $%04X  %-14s %s' % (a, ins, note))
    print('%d keyboard reads in %d entries%s' % (
        len(hits), len(by_entry), '' if ran is None else
        '; %d never ran under re/maps/*.map' % sum('NEVER' in h[2] for h in hits)))


def cmd_keytab(args):
    """Decode a table of keyboard masks: each group holds one byte per half-row
    in --rows; a 0 in bits 0-4 is a key held."""
    import zxq
    mem = zxq.image()
    rows = args.rows
    a = args.addr
    word = ''
    for g in range(args.count):
        keys = []
        for r, high in enumerate(rows):
            v = mem[a + g * len(rows) + r]
            names = [zxrun.ROWS[k] for k in range(8) if not high & (1 << k)][0].split()
            keys += [names[b] for b in range(5) if not v & (1 << b)]
        cells = ' '.join('$%02X' % mem[a + g * len(rows) + r] for r in range(len(rows)))
        print('$%04X  %s  %s' % (a + g * len(rows), cells, '+'.join(keys) or '(none)'))
        word += keys[0] if len(keys) == 1 and len(keys[0]) == 1 else '.'
    print('as letters: %s' % word)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0],
                                 epilog=__doc__.split('\n', 2)[2],
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest='cmd', required=True)

    def runner(name):
        p = sub.add_parser(name)
        p.add_argument('snapshot')
        p.add_argument('--input')
        p.add_argument('--fuzz', metavar='SEED:HOLD:KEYS')
        p.add_argument('--frames', type=int)
        p.add_argument('--poke', action='append', default=[], metavar='A,V',
                       type=lambda s: tuple(addr(x) for x in s.split(',')))
        p.add_argument('--range', default='0x5B00-0x10000', metavar='A-B',
                       type=lambda s: tuple(addr(x) for x in s.split('-')))
        p.add_argument('--limit', type=int, default=40, help='candidates shown')
        p.add_argument('--referenced', action='store_true',
                       help='only addresses the code names as operands (needs re/skool)')
        return p

    p = runner('search')
    p.add_argument('--at', action='append', required=True, metavar='F=SPEC')
    p.add_argument('--enc', default='value,value-1,value+1,ascii,bcd')
    p.add_argument('--max', type=int, help='largest value at every --at (a room number < 64)')
    for name in ('profile', 'trace'):
        p = runner(name)
        p.add_argument('--from', dest='start', type=int, default=0, metavar='F')
        p.add_argument('--keep', type=int, default=64, help='changes kept per address')
        if name == 'trace':
            p.add_argument('addr', nargs='+', type=addr)
            continue
        p.add_argument('--changes', type=lambda s: tuple(int(x) for x in s.split('-')),
                       metavar='LO-HI')
        p.add_argument('--max', type=int)
        p.add_argument('--step', type=int)
        p.add_argument('--near', type=lambda s: [int(x) for x in s.split(',')], metavar='F,F')
    p = runner('writers')
    p.add_argument('addr', nargs=1, type=addr)
    p.add_argument('--depth', type=int, default=2, help='jumps shown per path (default 2)')
    p.add_argument('--paths', type=int, default=0, help='paths shown (default 8, only when '
                   'there are several)')
    p.add_argument('--from', dest='start', type=int, default=0, metavar='F')
    p = runner('check')
    p.add_argument('--with', dest='with_', action='append', default=[], metavar='A,V',
                   type=lambda s: tuple(addr(x) for x in s.split(',')),
                   help='a POKE applied to both runs (a start room that reaches the hazard)')
    p.add_argument('--addr', action='append', default=[], type=addr)
    p.add_argument('--shot', action='append', default=[], metavar='F:PNG')
    p = sub.add_parser('pok')
    p.add_argument('file')
    p.add_argument('--apply', nargs=2, metavar=('SNAP', 'OUT'))
    p.add_argument('--check', metavar='SNAP')
    sub.add_parser('keys')
    p = sub.add_parser('keytab')
    p.add_argument('addr', type=addr)
    p.add_argument('count', type=int)
    p.add_argument('--rows', required=True, metavar='HI,HI',
                   type=lambda s: [addr(x) for x in s.split(',')],
                   help='the high bytes of the ports each group is read with, e.g. $FB,$DF')
    args = ap.parse_args()
    if args.cmd == 'pok':
        args.snapshot_in = args.apply[0] if args.apply else args.check
        if args.apply:
            args.apply = args.apply[1]
    {'search': cmd_search, 'profile': cmd_profile, 'trace': cmd_trace, 'writers': cmd_writers,
     'check': cmd_check, 'pok': cmd_pok, 'keys': cmd_keys, 'keytab': cmd_keytab}[args.cmd](args)


if __name__ == '__main__':
    import signal
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)
    try:
        main()
    except SkoolKitError as e:
        sys.exit('ERROR: %s' % e)
