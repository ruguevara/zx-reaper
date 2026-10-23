"""Runs a game without a window, for tests: as fast as it goes, keys from a
function, or input replayed from a Z80 run with its state checked."""
from .machine import ROM, T_FRAME, zx


def run(main, frames=None, keys=None):
    """Drive the coroutine function `main` for `frames` frames (None: until it
    returns); `keys(frame)` gives the ZX keys held. Returns the frames run."""
    game, n = main(), 0
    while frames is None or n < frames:
        zx.keys = keys(n) if keys else set()
        try:
            game.send(None)
        except StopIteration:
            break
        if zx.mem[:0x4000] != ROM:
            raise AssertionError('frame %d: the port wrote to the ROM' % n)
        zx.edges.clear()
        n += 1
    return n


class Mismatch(AssertionError):
    pass


class _End(Exception):
    pass


class Replay:
    """A `zxrun.py --record` file: the reads and checkpoints of a Z80 run, in order."""

    def __init__(self, path, labels):
        self.labels = {k: v for k, v in vars(labels).items() if isinstance(v, int)}
        self.events = []
        for line in open(path):
            w = line.split()
            if w[0] == 'state':
                self.ranges = [tuple(int(x, 16) for x in r.split('-')) for r in w[1:]]
            elif w[0] == 'checkpoint':
                self.addr = int(w[1], 16)
            elif w[0] in ('in', 'cp', 'int', 'r', 'a'):
                self.events.append(w)
            elif w[0] == 'end':
                self.z80_frames = int(w[1])
        self.next = 0
        self.left = 0                    # repeats left of the last 'in' line
        self.passes = 0                  # checkpoints matched
        self.z80_t = self.port_t = 0     # the clocks at the last checkpoint
        self.z80 = bytearray(0x10000)    # the Z80's state at the last checkpoint

    def take(self, kind, what):
        if self.left:
            raise Mismatch('%s, where the Z80 reads port %04X %d more times%s' % (
                what, self.left_port, self.left, self.where()))
        while self.next < len(self.events) and self.events[self.next][0] == 'int':
            self.next += 1
            zx.handler()        # an interrupt the Z80 took since the last event
        if self.next == len(self.events):
            raise _End
        e = self.events[self.next]
        if e[0] != kind:
            z80 = ('reads port ' + e[1] if e[0] == 'in' else 'reads R' if e[0] == 'r'
                   else 'gives A at ' + e[1] if e[0] == 'a'
                   else 'is at the checkpoint (frame %d)' % (int(e[1]) // T_FRAME))
            raise Mismatch('%s, where the Z80 %s%s' % (what, z80, self.where()))
        self.next += 1
        return e

    def where(self):
        return ' (after checkpoint %d, record event %d)' % (self.passes, self.next)

    def inp(self, port):
        if self.left:                    # a run of repeated reads: 'in PORT VAL COUNT'
            if port != self.left_port:
                raise Mismatch('the port reads port %04X, the Z80 port %04X%s' % (
                    port, self.left_port, self.where()))
            self.left -= 1
            return self.left_val
        e = self.take('in', 'the port reads port %04X' % port)
        if int(e[1], 16) != port:
            raise Mismatch('the port reads port %04X, the Z80 port %s%s' % (port, e[1], self.where()))
        self.left, self.left_port, self.left_val = (int(e[3]) - 1 if len(e) > 3 else 0), port, int(e[2], 16)
        return self.left_val

    def r(self):
        return int(self.take('r', 'the port reads R')[1], 16)

    def given(self, addr, a):
        e = self.take('a', 'the port takes A at %04X' % addr)
        if int(e[1], 16) != addr:
            raise Mismatch('the port takes A at %04X, the Z80 gave it at %s%s' % (addr, e[1], self.where()))
        return int(e[2], 16)

    def checkpoint(self, label):
        if self.labels.get(label) != self.addr:
            return              # a checkpoint of another record
        e = self.take('cp', 'the port is at %s' % label)
        for run in e[2:]:
            a, data = run.split(':')
            a = int(a, 16)
            self.z80[a:a + len(data) // 2] = bytes.fromhex(data)
        diff = [a for lo, hi in self.ranges for a in range(lo, hi) if zx.mem[a] != self.z80[a]]
        if diff:
            raise Mismatch('%s, checkpoint %d (Z80 frame %d, port frame %d): %d bytes differ\n%s' % (
                label, self.passes + 1, int(e[1]) // T_FRAME, zx.t // T_FRAME, len(diff),
                self.report(diff)))
        self.passes += 1
        self.z80_t, self.port_t = int(e[1]), zx.t

    def name(self, a):
        """Screen and attribute cells by position, other addresses by label."""
        if 0x4000 <= a < 0x5800:
            y = (a >> 8 & 7) | (a >> 2 & 0x38) | (a >> 5 & 0xC0)
            return 'screen x=%d y=%d' % ((a & 31) * 8, y)
        if 0x5800 <= a < 0x5B00:
            return 'attr col %d row %d' % ((a - 0x5800) % 32, (a - 0x5800) // 32)
        best = max(((v, k) for k, v in self.labels.items() if v <= a), default=(0, '?'))
        return best[1] + ('+%d' % (a - best[0]) if a != best[0] else '')

    def report(self, diff, limit=12):
        runs = []
        for a in diff:
            if runs and a == runs[-1][1] + 1 and a not in range(0x4000, 0x5800):
                runs[-1][1] = a
            else:
                runs.append([a, a])
        lines = ['  $%04X %-28s z80 %s port %s' % (lo, self.name(lo), self.z80[lo:hi + 1].hex(),
                                                   zx.mem[lo:hi + 1].hex()) for lo, hi in runs[:limit]]
        return '\n'.join(lines + (['  ... %d more' % (len(runs) - limit)] if len(runs) > limit else []))


def replay(main, path, labels):
    """Run `main` against the record at `path`: each zx.inp, zx.r and zx.take
    gets the value the Z80 read, each zx.checkpoint(label) must come where the Z80 passed its
    checkpoint, with the same state, and the interrupt handler runs where the
    Z80 took an interrupt (at the port's next read or checkpoint) instead of
    by the port's clock. `labels` is the port's labels module.
    Returns (checkpoints matched, Z80 clock, port clock at the last one);
    raises Mismatch at the first difference."""
    r = Replay(path, labels)
    zx.inp, zx.r, zx.take, zx.on_checkpoint = r.inp, r.r, r.given, r.checkpoint
    zx.interrupt = lambda: None     # interrupts come from the record
    zx.tape = None                  # the Z80 run had no tape playing
    try:
        frames = run(main, frames=2 * r.z80_frames + 1000)
    except _End:
        return r.passes, r.z80_t, r.port_t
    finally:
        del zx.inp, zx.r, zx.take, zx.interrupt
        zx.on_checkpoint = None
        zx.tape = []
    if r.next == len(r.events):     # the port waits where the Z80 run ended waiting
        return r.passes, r.z80_t, r.port_t
    raise Mismatch('the port ran %d frames and used %d of %d record events%s' % (
        frames, r.next, len(r.events), r.where()))
