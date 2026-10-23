"""Stage 3 as the oracle of stage 4.

The stage 3 port replays a zxrun.py record (and is checked against the Z80
as it goes, as in make port-test). At every step boundary of stage 4 (a pass
of the title loop or of the main loop) the oracle knows what the player did
in the step (Actions, decoded from the reads), the sounds it started, the
interrupts the Z80 took, and the state (decoded from memory). Two checks use
it:

  python bridge/oracle.py game RECORD...
      stage 4 in lockstep with stage 3: state and sounds per step (every sound
      synthesised), the rendered screen byte for byte every 50 steps, the clock
      against the Z80's; then the stage 4 routines no record ran
  python bridge/oracle.py routine NAME[,NAME...]|all [--max=N] RECORD...
      stage 4 routines on every call of their stage 3 routines, in one replay:
      the same state after, the same Goto, the same sounds
  python bridge/oracle.py play [FRAMES]
      free play with random keys through the pacer: every step takes time,
      the invariants hold
"""
import copy
import inspect
import os
import sys

import paths
from decode import decode
from horace import assets
from horace.state import Actions
from routines import ROUTINES, drive
import labels
import main as port_main
import movement
from zxpyxel import Goto, T_FRAME, headless, zx

STEPS = {'TitleLoop': 'title', 'MainLoop': 'play'}
SCREEN_EVERY = 50
READERS = ('ShowTitle', 'ReadControls', 'ReadKeys', 'CheckSoundKey')
SOUNDS = {'PlayRisingTone': 'rising', 'chirp': 'chirp', 'PlanMoves': 'wrap',
          'CheckGuardContact': 'buzz', 'HoraceDies': 'noise', 'BEEPER': 'chime'}
PORT = [m for m in list(sys.modules.values())
        if os.path.dirname(getattr(m, '__file__', '') or '') == os.path.join(paths.ROOT, 'port')]


class Mismatch(AssertionError):
    pass


def actions(reads, interrupts=0):
    """The player's input as the stage 3 routines read it: (routine, port, value) each."""
    a = Actions(interrupts=interrupts)
    keys = [(p, v) for r, p, v in reads if r == 'ReadKeys']
    for r, p, v in reads:
        if r in ('ShowTitle', 'ReadControls'):
            a.any_key = v & 0x1F != 0x1F
        elif r == 'CheckSoundKey':
            a.t = not v & labels.KEY_T_BIT
    i = 0
    for d, pairs in movement.KEYS:          # ReadKeys reads in this order up to the first key held
        for row, mask in pairs:
            if i < len(keys) and not keys[i][1] & mask:
                a.direction = d
                return a
            i += 1
    return a


class Oracle:
    def __init__(self, record):
        self.record = record

    def run(self, on_step=None):
        """Replay the record through stage 3; on_step(mode, new_mode, actions,
        sounds) at every step boundary (mode: the step just finished, None at the
        first boundary; new_mode: the step starting), zx.mem holding the state."""
        r = self.replay = headless.Replay(self.record, labels)
        self.reads, self.sounds, self.interrupts = [], [], 0
        self.mode = None

        def inp(port):
            v = r.inp(port)
            self.reads.append((caller(READERS), port, v))
            return v

        def checkpoint(label):
            r.checkpoint(label)             # MainLoop: compared with the Z80 here
            if label in STEPS:
                if on_step:
                    on_step(self.mode, STEPS[label], actions(self.reads, self.interrupts),
                            self.sounds)
                self.mode, self.reads, self.sounds, self.interrupts = STEPS[label], [], [], 0

        def out(port, value, original=zx.out):
            if port & 1 == 0 and value >> 4 & 1 != zx.speaker:      # one name per edge,
                self.sounds.append(SOUNDS.get(caller(SOUNDS), '?'))    # collapsed when compared
            original(port, value)

        def handler(original=zx.handler):
            self.interrupts += 1
            original()

        zx.reset(open(os.path.join(paths.ROOT, 'port/image.bin'), 'rb').read())
        zx.inp, zx.on_checkpoint, zx.out, zx.interrupt = inp, checkpoint, out, lambda: None
        zx.handler = handler
        try:
            headless.run(port_main.Start, frames=2 * r.z80_frames + 1000)
            raise Mismatch('stage 3 did not use the whole record')
        except headless._End:
            return r.passes
        finally:
            for name in ('inp', 'out', 'interrupt'):
                del zx.__dict__[name]
            zx.on_checkpoint = None


def caller(names):
    """The nearest stage 3 routine on the call stack among `names`."""
    f = sys._getframe(2)
    while f and f.f_code.co_name not in names:
        f = f.f_back
    return f.f_code.co_name if f else None


def diff(a, b, path=''):
    """Paths and values where two states differ."""
    if type(a) is not type(b) or not hasattr(a, '__dataclass_fields__'):
        if isinstance(a, list) and isinstance(b, list) and len(a) == len(b):
            return [d for i, (x, y) in enumerate(zip(a, b)) for d in diff(x, y, '%s[%d]' % (path, i))]
        return [] if a == b else [(path, a, b)]
    return [d for f in a.__dataclass_fields__ for d in diff(getattr(a, f), getattr(b, f),
                                                            (path + '.' if path else '') + f)]


def report(got, want, limit=12):
    out = []
    for path, g, w in diff(got, want)[:limit]:
        if path.startswith('cells['):
            i = int(path[6:path.index(']')])
            path = 'cells col %d row %d%s' % (i % 32, i // 32, path[path.index(']') + 1:])
        out.append('  %-34s stage 4 %s, stage 3 %s' % (path, fmt(g), fmt(w)))
    return '\n'.join(out)


def fmt(x):
    return x.hex() if isinstance(x, bytes) else repr(x)


def check_game(record):
    """Stage 4 against stage 3, step by step. Returns the steps checked."""
    from horace import sounds as sounds_module
    from horace.flow import Game
    from horace.render import render
    from zxpyxel.display import Display
    game, steps, display = None, [0], Display()
    clock = [0.0, 0.0, 0.0]         # stage 4 seconds; both at the last main-loop step
    oracle = Oracle(record)

    def on_step(mode, new_mode, acts, sounds):
        nonlocal game
        want = decode(zx.mem, new_mode)
        if game is None:                    # the first boundary: the state after Start
            game = Game()
        else:
            events = []
            drive(game.step(acts), events)
            for e in events:
                if hasattr(e, 'name'):
                    sounds_module.edges(e)      # the synthesiser takes every sound the game makes
                else:
                    clock[0] += e.seconds
            if new_mode == 'play':
                clock[1:] = [clock[0], oracle.replay.z80_t / 3500000]
            got_sounds = dedup(e.name for e in events if hasattr(e, 'name'))
            if got_sounds != dedup(sounds):
                raise Mismatch('step %d (%s): sounds %s, stage 3 %s' % (steps[0], mode, got_sounds,
                                                                         dedup(sounds)))
        if game.state != want:
            raise Mismatch('step %d (after a %s step, port frame %d), actions %s:\n%s' % (
                steps[0], mode, zx.t // T_FRAME, acts, report(game.state, want)))
        if steps[0] % SCREEN_EVERY == 0:    # the renderer: the Spectrum's screen, byte for byte
            render(game.state, display)
            if display.data != zx.mem[0x4000:0x5B00]:
                raise Mismatch('step %d: the rendered screen differs from stage 3\'s' % steps[0])
        steps[0] += 1

    oracle.run(on_step)
    return steps[0], clock[1], clock[2]


def dedup(names):
    out = []
    for n in names:
        if not out or out[-1] != n:
            out.append(n)
    return out


def check_routines(record, names, limit=None):
    """The stage 4 routines registered for `names` on every call of their stage 3
    routines (the first `limit` calls of each), in one replay. Returns the calls
    checked, by name."""
    oracle, calls, patched = Oracle(record), {}, []

    def wrap(name):
        clean, convert = ROUTINES[name]
        orig = next(getattr(m, name) for m in PORT if callable(getattr(m, name, None)))  # not the label
        calls[name] = 0

        def start():
            if limit is not None and calls[name] >= limit:
                return None
            return decode(zx.mem, oracle.mode or 'title'), len(oracle.reads), len(oracle.sounds)

        def finish(call, args, ret):
            """Run the stage 4 routine on the state before the call; compare."""
            if call is None:
                return
            before, n_reads, n_sounds = call
            want = decode(zx.mem, oracle.mode or 'title')
            a = actions(oracle.reads[n_reads:])
            s, events = copy.deepcopy(before), []
            got = drive(clean(s, a, *convert(*args)), events)
            got_sounds = dedup(e.name for e in events if hasattr(e, 'name'))
            sounds = dedup(oracle.sounds[n_sounds:])
            if s != want or got != ret or got_sounds != sounds:
                raise Mismatch('%s, call %d (port frame %d), actions %s: returns %r (stage 3 %r), '
                               'sounds %s (stage 3 %s)\n%s' % (name, calls[name], zx.t // T_FRAME, a,
                                                                got, ret, got_sounds, sounds,
                                                                report(s, want)))
            calls[name] += 1

        if inspect.iscoroutinefunction(orig):
            async def wrapper(*args):
                call = start()
                try:
                    ret = await orig(*args)
                except Goto as g:
                    finish(call, args, g.target.__name__)
                    raise
                finish(call, args, ret)
                return ret
        else:
            def wrapper(*args):
                call = start()
                try:
                    ret = orig(*args)
                except Goto as g:
                    finish(call, args, g.target.__name__)
                    raise
                finish(call, args, ret)
                return ret
        for m in PORT:
            if getattr(m, name, None) is orig:
                setattr(m, name, wrapper)
                patched.append((m, name, orig))

    for name in names:
        wrap(name)
    try:
        oracle.run()
    finally:
        for m, name, orig in patched:
            setattr(m, name, orig)
    return calls


def check_play(frames, seed=1):
    """Free play: random keys for `frames` host frames through the pacer and
    the sound synthesiser, as a host would run it; the steps must take time
    (a step may not, as the original's exit to the next maze has no frame, but
    a run of them hangs the pacer) and keep the invariants."""
    import random
    from horace.pacer import Pacer
    from horace.state import Show
    from zxpyxel import sound
    from zxpyxel.display import Display
    p = Pacer(Display(), 22050, lambda edges, t, rate: sound.pcm(edges, 0, 0, t, rate)[0])
    step, steps, idle = p.game.step, [0], [0]

    def checked(a):
        shown = 0
        for e in step(a):
            shown += isinstance(e, Show)
            yield e
        idle[0] = 0 if shown else idle[0] + 1
        if idle[0] > 3:
            raise Mismatch('steps %d-%d took no time: the pacer would hang' % (steps[0] - 3, steps[0]))
        problem = invariant(p.game.state)
        if problem:
            raise Mismatch('step %d: %s' % (steps[0], problem))
        steps[0] += 1

    p.game.step = checked
    rnd, keys, best = random.Random(seed), set(), 0
    for n in range(frames):
        if n % 8 == 0:
            keys = set(rnd.sample(['Q', 'Z', 'I', 'P', 'T', 'SPACE'], rnd.choice((0, 1, 1, 2))))
        p.update(keys)
        best = max(best, p.game.state.best)
    return steps[0], best


def invariant(s):
    """What must hold after any step, whatever the keys."""
    if s.mode not in ('title', 'play') or len(s.cells) != 768:
        return 'mode %r, %d cells' % (s.mode, len(s.cells))
    if any(len(c.glyph) != 8 or not 0 <= c.attr < 256 for c in s.cells):
        return 'a cell is not 8 bytes and an attribute'
    for who, (col, row) in [('Horace', s.horace.pos)] + [('guard', g.pos) for g in s.guards]:
        if not (0 <= col < 31 and 0 <= row < 23):
            return '%s at %r, off the screen' % (who, (col, row))
    if s.mode == 'play' and not 1 <= s.pace <= 8:
        return 'pace %d' % s.pace
    if not (0 <= s.score < 0x10000 and 0 <= s.passes < 0x100):
        return 'score %d, passes %d' % (s.score, s.passes)
    return None


def functions():
    """The stage 4 game's functions, by module."""
    import horace
    return [f for m in list(sys.modules.values())
            if m.__name__.startswith('horace.') and m.__name__ not in ('horace.state', 'horace.assets')
            for f in vars(m).values() if inspect.isfunction(f) and f.__module__ == m.__name__]


def main():
    assets.load()
    a = sys.argv[1:]
    if a[:1] == ['game'] and len(a) > 1:
        ran = set()
        for rec in a[1:]:
            sys.setprofile(lambda frame, event, arg: event == 'call' and ran.add(frame.f_code))
            try:
                n, t4, t3 = check_game(rec)
                print('%s: %d steps match; at the last pass stage 4 %.1f s, Z80 %.1f s (%+.1f%%)'
                      % (rec, n, t4, t3, 100 * (t4 / t3 - 1)))
            except Mismatch as e:
                sys.exit('%s: MISMATCH %s' % (rec, e))
            finally:
                sys.setprofile(None)
        never = sorted('%s.%s' % (f.__module__, f.__name__) for f in functions() if f.__code__ not in ran)
        if never:
            print('never ran in any record (add an input that reaches them): ' + ', '.join(never))
    elif a[:1] == ['routine'] and len(a) > 2:
        limit = None
        if a[2].startswith('--max='):
            limit, a = int(a[2][6:]), a[:2] + a[3:]
        names = sorted(ROUTINES) if a[1] == 'all' else a[1].split(',')
        for rec in a[2:]:
            try:
                calls = check_routines(rec, names, limit)
            except Mismatch as e:
                sys.exit('%s: MISMATCH %s' % (rec, e))
            print('%s: %s' % (rec, ', '.join('%s %d' % kv for kv in calls.items())))
    elif a[:1] == ['play'] and len(a) <= 2:
        frames = int(a[1]) if len(a) == 2 else 15000
        try:
            steps, best = check_play(frames)
        except Mismatch as e:
            sys.exit('free play: MISMATCH %s' % e)
        print('free play: %d frames, %d steps, invariants hold (best score %d)' % (frames, steps, best))
    else:
        sys.exit(__doc__)


if __name__ == '__main__':
    main()
