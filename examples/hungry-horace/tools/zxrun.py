#!/usr/bin/env python3
"""Headless, deterministic ZX Spectrum 48K runner for RE work (SkoolKit simulator).

  zxrun.py SNAPSHOT [options]

Runs SNAPSHOT (z80/szx/sna) for --frames frames with scripted input and
records what an agent needs: a code execution map, per-frame hashes,
screenshots, a final snapshot, and writes to watched addresses.

Input script (--input), one line per change, keys held until the next line:
  # comment
  0    -            frame 0: nothing pressed
  50   ENTER
  +2   -            2 frames after the previous line
  100  O SPACE      several keys at once
  140  KF KL        Kempston fire + left (KL KR KU KD KF)
  600  END          stop here (instead of --frames)
Key names: A-Z 0-9 ENTER SPACE CS (caps shift) SS (symbol shift).

Examples:
  zxrun.py orig.z80 --frames 3000 --input play.txt --map cov.map
  zxrun.py orig.z80 --frames 500 --shot 100:title.png --shot 499:game.png
  zxrun.py orig.z80 --frames 9000 --fuzz 7:4:Q,A,O,P,M,SPACE --map cov.map
  zxrun.py orig.z80 --frames 2000 --input play.txt --hashes orig.hash
  zxrun.py new.z80 --frames 2000 --input play.txt --expect orig.hash
  zxrun.py orig.z80 --frames 300 --watch 0x8000-0x80FF --watch-from 250
  zxrun.py orig.z80 --load build/code.bin@0x8100 --pc 0x8100 ...   (shift test)

Record for a stage 3 port (zxpyxel/headless.py replays it):
  zxrun.py orig.z80 --input play.txt --record play.rec --checkpoint 0x6229 \
      --state 0x4000-0x5B00 --state 0x5FB5-0x8000
  writes every value an IN by the game reads (not by the ROM), in order, each
  interrupt the ROM's IM1 handler takes, and at every pass through
  --checkpoint the clock (T-states since the start) and the --state ranges:
  the first pass in full, then the bytes changed since.

Calling a routine (render data with the game's own code, for docs):
  zxrun.py orig.z80 --cls 0x38 --call 0x6B75 --reg HL=0x6FF7 --reg DE=0x4000 \
      --reg BC=0x300 --png maze1.png [--crop X,Y,W,H]
  pushes a return address, runs ADDR with interrupts off until it returns,
  then writes the screen (cells X,Y,W,H) as PNG.
"""
import argparse
import hashlib
import os
import random
import sys

from skoolkit import CSimulator, SkoolKitError
from skoolkit.graphics import Frame, scr_udgs
from skoolkit.components import get_image_writer
from skoolkit.simulator import Simulator
from skoolkit.simutils import SP, from_snapshot, get_state
from skoolkit.snapshot import Snapshot, write_snapshot

PC, T, IFF = 24, 25, 26
KEY_SCAN_IN = 0x0296      # the first IN of the ROM's KEY_SCAN (port $FEFE)

# key name -> (half-row index for A8..A15, bit)
ROWS = ['CS Z X C V', 'A S D F G', 'Q W E R T', '1 2 3 4 5',
        '0 9 8 7 6', 'P O I U Y', 'ENTER L K J H', 'SPACE SS M N B']
KEYS = {k: (r, b) for r, row in enumerate(ROWS) for b, k in enumerate(row.split())}
KEMPSTON = {'KR': 1, 'KL': 2, 'KD': 4, 'KU': 8, 'KF': 16}


def parse_int(s):
    return int(s, 0)


def parse_input(path):
    events = []
    frame = 0
    for lineno, line in enumerate(open(path), 1):
        line = line.split('#')[0].split()
        if not line:
            continue
        f = line[0]
        frame = frame + int(f[1:]) if f.startswith('+') else int(f)
        keys = [k.upper() for k in line[1:] if k != '-']
        if keys == ['END']:
            events.append((frame, None))
            continue
        bad = [k for k in keys if k not in KEYS and k not in KEMPSTON]
        if bad:
            sys.exit('%s:%d: unknown key(s) %s' % (path, lineno, ' '.join(bad)))
        events.append((frame, keys))
    return events


def fuzz_input(spec, frames):
    seed, hold, keys = spec.split(':')
    rnd = random.Random(int(seed))
    keys = keys.upper().split(',')
    events = []
    for f in range(0, frames, int(hold)):
        events.append((f, rnd.sample(keys, rnd.choice((0, 1, 1, 2)))))
    return events


class Tracer:
    """Port I/O for the simulator: keyboard, Kempston, border/beeper/AY log."""

    def __init__(self):
        self.keyboard = [0] * 8
        self.kempston = 0
        self.border = [(0, 7)]
        self.outfe = 0
        self.out7ffd = self.outfffd = 0
        self.ay = [0] * 16
        self.io_log = []
        self.record = None        # --record: lines of the reads and checkpoints

    def set_keys(self, keys):
        self.keyboard[:] = [0] * 8
        self.kempston = 0
        for k in keys:
            if k in KEMPSTON:
                self.kempston |= KEMPSTON[k]
            else:
                r, b = KEYS[k]
                self.keyboard[r] |= 1 << b

    def read_port(self, registers, port):
        v = self.port_value(port)
        if self.record is not None:
            pc = registers[PC]                       # the IN instruction
            if pc >= 0x4000:
                self.record.append('in %04X %02X' % (port, v))
            elif pc == KEY_SCAN_IN and port == 0xFEFE:
                # ponytail: the ROM's IM1 handler scans the keyboard once per
                # interrupt; a game that calls KEY_SCAN itself would add false
                # ones, and an IM2 handler is not seen
                self.record.append('int')
        return v

    def port_value(self, port):
        if port & 0xFF == 0x1F:
            return self.kempston
        if port & 1 == 0:
            h = (port >> 8) ^ 0xFF
            v = 0
            for i in range(8):
                if h & (1 << i):
                    v |= self.keyboard[i]
            return (v | 0x40) ^ 0xFF
        return 0xFF

    def write_port(self, registers, port, value, offset=0):
        if port & 1 == 0:
            self.outfe = value
            self.border[-1:] = [(0, value & 7)]
            self.io_log.append((registers[T] + offset, 0xFE, value))
        elif port & 0xC002 == 0xC000:
            self.outfffd = value
        elif port & 0xC002 == 0x8000:
            self.ay[self.outfffd & 15] = value
            self.io_log.append((registers[T] + offset, self.outfffd & 15, value))


def png(scr, path, crop=(0, 0, 32, 24), scale=2):
    x, y, w, h = crop
    frame = Frame(scr_udgs(scr, x, y, w, h, 0, 6144), scale)
    with open(path, 'wb') as f:
        get_image_writer().write_image([frame], f)


def short_hash(data):
    return hashlib.blake2b(bytes(data), digest_size=6).hexdigest()


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0],
                                 epilog=__doc__.split('\n', 2)[2],
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('snapshot')
    ap.add_argument('--frames', type=int, help='frames to run (default: END in the input, or 500)')
    ap.add_argument('--input', help='input script')
    ap.add_argument('--fuzz', metavar='SEED:HOLD:KEYS', help='random input, HOLD frames per change')
    ap.add_argument('--map', help='add executed addresses to this map file')
    ap.add_argument('--hashes', help='write per-frame hashes')
    ap.add_argument('--hash-ram', action='store_true', help='hash all RAM, not just the screen')
    ap.add_argument('--expect', help='compare per-frame hashes with this file, stop at divergence')
    ap.add_argument('--shot', action='append', default=[], metavar='FRAME:FILE.png')
    ap.add_argument('--shots-every', metavar='N:DIR', help='screenshot every N frames into DIR')
    ap.add_argument('--dump', help='write a snapshot (.z80/.szx) when finished')
    ap.add_argument('--stop', type=parse_int, help='stop when PC reaches this address')
    ap.add_argument('--load', action='append', default=[], metavar='FILE@ADDR',
                    help='load a binary into memory before running')
    ap.add_argument('--pc', type=parse_int, help='set PC before running')
    ap.add_argument('--clear', metavar='A-B', help='zero memory A..B-1 before --load')
    ap.add_argument('--poke', action='append', default=[], metavar='ADDR,VALUE',
                    help='set a byte before running (after --load); repeatable')
    ap.add_argument('--cls', type=parse_int, metavar='ATTR', help='clear the screen to ATTR first')
    ap.add_argument('--call', type=parse_int, metavar='ADDR', help='call a routine and stop on return')
    ap.add_argument('--reg', action='append', default=[], metavar='R=V', help='register for --call')
    ap.add_argument('--png', help='write the final screen as PNG')
    ap.add_argument('--crop', default='0,0,32,24', help='cells X,Y,W,H for --png (default whole screen)')
    ap.add_argument('--scale', type=int, default=2, help='--png scale (default 2)')
    ap.add_argument('--watch', metavar='A[-B]', help='log writes to A..B (pure Python simulator)')
    ap.add_argument('--watch-from', type=int, default=0, metavar='FRAME',
                    help='run fast until FRAME, then start watching')
    ap.add_argument('--record', help='write the game\'s IN reads and the checkpoint states')
    ap.add_argument('--checkpoint', type=parse_int, metavar='ADDR',
                    help='with --record: save the state at every pass through ADDR')
    ap.add_argument('--state', action='append', default=[], metavar='A-B',
                    help='with --record: memory A..B-1 that is game state (repeatable; '
                         'default the screen, 0x4000-0x5B00)')
    args = ap.parse_args()
    if args.record and (args.checkpoint is None or args.watch or args.stop is not None):
        sys.exit('--record needs --checkpoint and excludes --watch and --stop')

    snap = Snapshot.get(args.snapshot)
    if snap is None:
        sys.exit('cannot read snapshot %s' % args.snapshot)
    regs = {'PC': args.pc} if args.pc is not None else {}
    for spec in args.reg:
        r, _, v = spec.partition('=')
        regs[r.upper()] = parse_int(v)
    sim = from_snapshot(CSimulator or Simulator, snap, regs, None,
                        {'fast_djnz': False, 'fast_ldir': False})
    if len(sim.memory) != 0x10000:
        sys.exit('48K snapshots only (extend Tracer/paging for 128K)')
    if args.clear:
        lo, hi = (parse_int(x) for x in args.clear.split('-'))
        sim.memory[lo:hi] = [0] * (hi - lo)
    for spec in args.load:
        fname, addr = spec.rsplit('@', 1)
        data = open(fname, 'rb').read()
        a = parse_int(addr)
        sim.memory[a:a + len(data)] = list(data)

    for spec in args.poke:
        addr, value = (parse_int(x) for x in spec.split(','))
        sim.memory[addr] = value & 0xFF
    if args.cls is not None:
        sim.memory[0x4000:0x5800] = [0] * 0x1800
        sim.memory[0x5800:0x5B00] = [args.cls] * 0x300

    tracer = Tracer()
    tracer.border = [(0, snap.border)]
    tracer.outfe = snap.outfe
    sim.set_tracer(tracer)

    events = []
    if args.input:
        events = parse_input(args.input)
    elif args.fuzz:
        events = fuzz_input(args.fuzz, args.frames or 500)
    events = sorted(events, key=lambda e: e[0])
    ends = [f for f, keys in events if keys is None]
    events = [e for e in events if e[1] is not None]
    if args.frames is None:
        args.frames = ends[0] if ends else 500
    shots = {}
    for s in args.shot:
        f, path = s.split(':', 1)
        shots[int(f)] = path
    every = None
    if args.shots_every:
        n, d = args.shots_every.split(':', 1)
        every = (int(n), d)
        os.makedirs(d, exist_ok=True)
    expected = None
    if args.expect:
        expected = [line.split() for line in open(args.expect)]
    hashes = []
    exec_map = set() if args.map else None
    fd = sim.frame_duration
    f0 = sim.registers[T] // fd
    state = {'ev': 0, 'diverged': None, 'io_start': 0}
    cur = {'sim': sim}
    if events and events[0][0] <= 0:
        tracer.set_keys(events[0][1])

    def on_frame(scr, frame):
        """Called at each frame interrupt; returns False to stop."""
        n = frame - f0 - 1        # frame n has just finished
        mem = cur['sim'].memory
        io = tracer.io_log[state['io_start']:]
        state['io_start'] = len(tracer.io_log)
        h = [str(n), short_hash(scr),
             short_hash(b''.join((t % fd).to_bytes(3, 'little') + bytes([p, v]) for t, p, v in io))]
        if args.hash_ram:
            h.append(short_hash(mem[16384:65536]))
        hashes.append(h)
        if expected is not None and state['diverged'] is None:
            if n >= len(expected) or expected[n][:len(h)] != h:
                state['diverged'] = n
                print('DIVERGED at frame %d: expected %s, got %s'
                      % (n, ' '.join(expected[n]) if n < len(expected) else 'end', ' '.join(h)))
                png(scr, 'diverged-%d.png' % n)
                print('wrote diverged-%d.png' % n)
                return False
        if n in shots:
            png(scr, shots[n])
        if every and n % every[0] == 0:
            png(scr, os.path.join(every[1], '%06d.png' % n))
        while state['ev'] < len(events) and events[state['ev']][0] <= n + 1:
            tracer.set_keys(events[state['ev']][1])
            state['ev'] += 1
        return n + 1 < args.frames

    stop = -1 if args.stop is None else args.stop
    crop = tuple(int(v) for v in args.crop.split(','))
    if args.call is not None:
        ret = 0x0001          # never executed by a routine under test
        sp = (sim.registers[SP] - 2) & 0xFFFF
        sim.memory[sp], sim.memory[sp + 1] = ret & 255, ret >> 8
        sim.registers[SP] = sp
        cond, ops = sim.trace(args.call, ret, 50000000, 0, 0, None, None, tracer.keyboard,
                              None, None)
        print('returned from $%04X after %d instructions' % (args.call, ops)
              if sim.registers[PC] == ret else 'did not return (PC=$%04X)' % sim.registers[PC])
        if args.png:
            png(sim.memory[0x4000:0x5B00], args.png, crop, args.scale)
            print('wrote %s' % args.png)
        if args.dump:
            ram, registers, st, machine = get_state(sim)
            write_snapshot(args.dump, ram, registers, st, machine)
        return
    watch_log = []
    if args.watch:
        lo, _, hi = args.watch.partition('-')
        lo = parse_int(lo)
        hi = parse_int(hi) if hi else lo
        if args.watch_from:
            frames, args.frames = args.frames, args.watch_from
            sim.trace(sim.registers[PC], stop, 0, 0, 1,
                      lambda scr, frame, border, kb: on_frame(scr, frame),
                      exec_map, tracer.keyboard, None, None)
            args.frames = frames
        sim = cur['sim'] = python_sim(sim, tracer, lo, hi, watch_log)
        run_python(sim, on_frame, exec_map, stop)
    elif args.record:
        ranges = [tuple(parse_int(x) for x in r.split('-')) for r in args.state or ['0x4000-0x5B00']]
        tracer.record = ['# zxrun.py %s' % ' '.join(sys.argv[1:]),
                         'checkpoint %04X' % args.checkpoint,
                         'state ' + ' '.join('%04X-%04X' % r for r in ranges)]
        seen = bytearray(0x10000)
        first, t0 = True, sim.registers[T]
        while True:
            cond, _ = sim.trace(sim.registers[PC], args.checkpoint, 0, 0, 1,
                                lambda scr, frame, border, kb: on_frame(scr, frame),
                                exec_map, tracer.keyboard, None, None)
            if cond != 3:
                break
            tracer.record.append(' '.join(['cp %d' % (sim.registers[T] - t0)] +
                                          changes(seen, sim.memory, ranges, first)))
            first = False
        with open(args.record, 'w') as f:
            f.write('\n'.join(tracer.record + ['end %d' % len(hashes)]) + '\n')
        print('record %s: %d reads, %d checkpoints' % (
            args.record, sum(r[:2] == 'in' for r in tracer.record),
            sum(r[:2] == 'cp' for r in tracer.record)))
    else:
        sim.trace(sim.registers[PC], stop, 0, 0, 1,
                  lambda scr, frame, border, kb: on_frame(scr, frame),
                  exec_map, tracer.keyboard, None, None)

    print('stopped at frame %d, PC=$%04X' % (len(hashes), sim.registers[PC]))
    if args.map:
        old = set()
        if os.path.exists(args.map):
            old = {int(line.strip().lstrip('$'), 16) for line in open(args.map) if line.strip()}
        new = exec_map - old
        with open(args.map, 'w') as f:
            for a in sorted(old | exec_map):
                f.write('$%04X\n' % a)
        print('map %s: %d addresses (+%d new)' % (args.map, len(old | exec_map), len(new)))
    if args.hashes:
        with open(args.hashes, 'w') as f:
            f.write(''.join(' '.join(h) + '\n' for h in hashes))
    if watch_log:
        for frame, pc, addr, old, new in watch_log:
            who = 'interrupt' if pc < 0 else 'PC=$%04X' % pc
            print('frame %d  %s  ($%04X) %02X -> %02X' % (frame - f0, who, addr, old, new))
    if args.dump:
        ram, registers, st, machine = get_state(sim)
        write_snapshot(args.dump, ram, registers, st, machine)
        print('wrote %s' % args.dump)
    if args.png:
        png(sim.memory[0x4000:0x5B00], args.png, crop, args.scale)
        print('wrote %s' % args.png)
    if expected is not None:
        if state['diverged'] is not None:
            sys.exit(1)
        if len(hashes) < len(expected):
            print('run ended at frame %d before the expected %d' % (len(hashes), len(expected)))
            sys.exit(1)
        print('matched %d frames' % len(hashes))


def changes(state, mem, ranges, full):
    """'ADDR:HEX' runs of the bytes in `ranges` that differ from `state` (all of
    them when `full`), merged across gaps under 4 bytes; updates `state`."""
    runs = []
    for lo, hi in ranges:
        new, old = bytes(mem[lo:hi]), bytes(state[lo:hi])
        state[lo:hi] = new
        if full:
            runs.append('%04X:%s' % (lo, new.hex()))
            continue
        diff = [i for k in range(0, hi - lo, 64) if new[k:k + 64] != old[k:k + 64]
                for i in range(k, min(k + 64, hi - lo)) if new[i] != old[i]]
        start = prev = None
        for i in diff + [None]:
            if i is not None and prev is not None and i - prev < 4:
                prev = i
                continue
            if start is not None:
                runs.append('%04X:%s' % (lo + start, new[start:prev + 1].hex()))
            start = prev = i
    return runs


def python_sim(csim, tracer, lo, hi, log):
    """Copy csim's state into the pure Python simulator, logging writes to lo..hi."""
    class WatchMem(list):
        def __setitem__(self, i, v):
            if isinstance(i, int) and lo <= i <= hi:
                log.append((regs[T] // sim.frame_duration, sim.cur_pc, i,
                            list.__getitem__(self, i), v))
            list.__setitem__(self, i, v)

    sim = Simulator(WatchMem(csim.memory), config={'frame_duration': csim.frame_duration})
    regs = sim.registers
    for i in range(len(regs)):
        regs[i] = csim.registers[i]
    sim.set_tracer(tracer)
    return sim


def run_python(sim, on_frame, exec_map, stop):
    """The interrupt/frame loop of trace.py, for the pure Python simulator."""
    mem, regs, opcodes = sim.memory, sim.registers, sim.opcodes
    fd, ia = sim.frame_duration, sim.int_active
    prev_frame = regs[T] // fd
    next_int = ((regs[T] + fd - ia) // fd) * fd
    while True:
        pc = sim.cur_pc = regs[PC]
        opcodes[mem[pc]]()
        if exec_map is not None:
            exec_map.add(pc)
        t = regs[T]
        if t >= next_int:
            if t < next_int + ia:
                if regs[IFF]:
                    sim.cur_pc = -1
                    sim.accept_interrupt(regs, mem, pc)
                frame = regs[T] // fd
                if frame > prev_frame:
                    prev_frame = frame
                    if not on_frame(mem[16384:23296], frame):
                        break
            else:
                next_int += fd
        if regs[PC] == stop:
            break


if __name__ == '__main__':
    import signal
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)   # quiet exit under `| head`
    try:
        main()
    except SkoolKitError as e:
        sys.exit('ERROR: %s' % e)
