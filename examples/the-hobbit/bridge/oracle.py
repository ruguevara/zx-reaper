"""Stage 3 as the oracle of stage 4 (The Hobbit).

Stage 3 replays a zxrun.py record (and is checked against the Z80 as it goes,
as in make port-test). The oracle notes the inputs stage 3 took (the key codes
WaitKey returned, the R register, the random routine's mixed values) and
decodes its memory into the stage 4 state (bridge/decode.py). Two checks:

  python bridge/oracle.py game RECORD...
      the stage 4 game, one generator from the start, driven in lockstep with
      stage 3: at every pass of the main loop (a Step event) the state, the
      screen included, must be equal; then the stage 4 routines no record ran
  python bridge/oracle.py routine NAME[,NAME...]|all [--max=N] RECORD...
      the stage 4 routines registered for stage 3 routines (bridge/routines_*.py)
      on every call (the first N): run on the decoded state before the call with
      the inputs stage 3 took in it, they must give the decoded state after and
      the same result
"""
import copy
import inspect
import os
import sys

import paths
from decode import decode
from routines import ANY, ROUTINES, Regs
import labels
import main as port_main
from hobbit.state import Mixed, ReadKey, ReadR, Step, TapeLoad
from zxpyxel import Goto, T_FRAME, headless, zx

PORT = [m for m in list(sys.modules.values())
        if os.path.dirname(getattr(m, '__file__', '') or '') == os.path.join(paths.ROOT, 'port')]


class Mismatch(AssertionError):
    pass


class Inputs:
    """The inputs of a stretch of the run, answered in order per kind."""

    def __init__(self, items):
        self.queues = {'key': [], 'r': [], 'mixed': []}
        for kind, v in items:
            self.queues[kind].append(v)

    def answer(self, event):
        kind = {ReadKey: 'key', ReadR: 'r', Mixed: 'mixed'}.get(type(event))
        if kind:
            if not self.queues[kind]:
                raise Mismatch('stage 4 asks for %s, but stage 3 took no more' % type(event).__name__)
            return self.queues[kind].pop(0)
        if isinstance(event, TapeLoad):
            return None                     # the records play no tape
        return None

    def left(self):
        return {k: q for k, q in self.queues.items() if q}


def drive(gen, inputs, stop=None):
    """Run a stage 4 generator (or take a plain value), answering its requests
    from `inputs`, until it returns or yields an event of type `stop`. Returns
    (value, events) or, when stopped, (the stop event, events)."""
    if not inspect.isgenerator(gen):
        return gen, []
    events, reply = [], None
    while True:
        try:
            e = gen.send(reply)
        except StopIteration as done:
            return done.value, events
        if stop and isinstance(e, stop):
            return e, events
        events.append(e)
        reply = inputs.answer(e)


class Oracle:
    def __init__(self, record):
        self.record = record

    def run(self, on_step=None):
        """Replay the record through stage 3; on_step() at every pass of the
        main loop, with zx.mem holding the state and self.inputs the inputs
        taken since the previous pass."""
        rep = self.replay = headless.Replay(self.record, labels)
        self.inputs = []
        import keys as port_keys
        wait_key = port_keys.WaitKey

        async def WaitKey():
            await wait_key()
            from regs import r
            self.inputs.append(('key', r.a))

        def checkpoint(label):
            rep.checkpoint(label)           # compared with the Z80 here
            if label == 'MainLoop' and on_step:
                on_step()
                self.inputs = []

        zx.reset(open(os.path.join(paths.ROOT, 'port/image.bin'), 'rb').read())
        zx.inp, zx.on_checkpoint, zx.interrupt = rep.inp, checkpoint, lambda: None
        zx.r = lambda: self.note('r', rep.r())
        zx.take = lambda addr, a: self.note('mixed', rep.given(addr, a))
        zx.tape = None
        port_keys.WaitKey = WaitKey
        try:
            headless.run(port_main.GameStart, frames=2 * rep.z80_frames + 1000)
            if rep.next < len(rep.events):
                raise Mismatch('stage 3 did not use the whole record')
            return rep.passes
        except headless._End:
            return rep.passes
        finally:
            port_keys.WaitKey = wait_key
            for name in ('inp', 'r', 'take', 'interrupt'):
                zx.__dict__.pop(name, None)
            zx.on_checkpoint, zx.tape = None, []

    def note(self, kind, v):
        self.inputs.append((kind, v))
        return v


def diff(a, b, path=''):
    """Paths and values where two states differ."""
    if hasattr(a, 'data') and hasattr(b, 'data') and type(a) is type(b):      # a Display
        if a.border != b.border:
            return [(path + '.border', a.border, b.border)]
        cells = [i for i in range(6912) if a.data[i] != b.data[i]]
        return [(path + '.data[%s]' % screen_cell(i), a.data[i], b.data[i]) for i in cells[:6]]
    if type(a) is not type(b) or not hasattr(a, '__dataclass_fields__'):
        if isinstance(a, (list, tuple)) and isinstance(b, (list, tuple)) and len(a) == len(b) \
                and type(a) is type(b):
            return [d for i, (x, y) in enumerate(zip(a, b)) for d in diff(x, y, '%s[%d]' % (path, i))]
        if isinstance(a, dict) and isinstance(b, dict) and a.keys() == b.keys():
            return [d for k in a for d in diff(a[k], b[k], '%s[%r]' % (path, k))]
        return [] if a == b else [(path, a, b)]
    return [d for f in a.__dataclass_fields__ for d in diff(getattr(a, f), getattr(b, f),
                                                            (path + '.' if path else '') + f)]


def screen_cell(i):
    if i >= 6144:
        return 'attr col %d row %d' % ((i - 6144) % 32, (i - 6144) // 32)
    y = (i >> 8 & 7) | (i >> 2 & 0x38) | (i >> 5 & 0xC0)
    return 'pixels col %d y %d' % (i & 31, y)


def report(got, want, limit=12):
    return '\n'.join('  %-40s stage 4 %r, stage 3 %r' % d for d in diff(got, want)[:limit])


def check_game(record):
    """The stage 4 game against stage 3, pass by pass. Returns the passes checked."""
    from hobbit.flow import Game
    game, gen, passes = Game(), None, [0]
    oracle = Oracle(record)

    def on_step():
        nonlocal gen
        want = decode(zx.mem, zx.border)
        inputs = Inputs(oracle.inputs)
        if gen is None:
            gen = game.run()
        stop, events = drive(gen, inputs, Step)
        if not isinstance(stop, Step):
            raise Mismatch('pass %d: the stage 4 game ended' % passes[0])
        if inputs.left():
            raise Mismatch('pass %d: stage 4 left inputs unused: %s' % (passes[0], inputs.left()))
        if game.state != want:
            raise Mismatch('pass %d (port frame %d):\n%s' % (passes[0], zx.t // T_FRAME,
                                                               report(game.state, want)))
        passes[0] += 1

    oracle.run(on_step)
    return passes[0]


def check_routines(record, names, limit=None):
    """The stage 4 routines registered for `names` on every call of their stage 3
    routines (the first `limit` calls of each), in one replay. Returns the calls
    checked, by name."""
    from regs import r
    oracle, calls, patched = Oracle(record), {}, []

    def wrap(name):
        clean, convert_in, convert_out = ROUTINES[name]
        holder = next(m for m in PORT if inspect.isfunction(getattr(m, name, None))
                      and getattr(m, name).__module__ == m.__name__)
        orig = getattr(holder, name)
        calls[name] = 0

        def start():
            if limit is not None and calls[name] >= limit:
                return None
            return decode(zx.mem, zx.border), Regs(r), len(oracle.inputs)

        def finish(call, ret):
            if call is None:
                return
            before, regs, n_inputs = call
            want = decode(zx.mem, zx.border)
            s = copy.deepcopy(before)
            inputs = Inputs(oracle.inputs[n_inputs:])
            got, _ = drive(clean(s, *convert_in(regs)), inputs)
            expect = ret if ret is not None else convert_out(Regs(r))
            if s != want or (expect is not ANY and got != expect) or inputs.left():
                raise Mismatch('%s, call %d (port frame %d): returns %r (stage 3 %r), inputs left %s\n%s'
                               % (name, calls[name], zx.t // T_FRAME, got, expect, inputs.left(),
                                  report(s, want)))
            calls[name] += 1

        if inspect.iscoroutinefunction(orig):
            async def wrapper(*args):
                call = start()
                try:
                    await orig(*args)
                except Goto as g:
                    finish(call, g.target.__name__)
                    raise
                finish(call, None)
        else:
            def wrapper(*args):
                call = start()
                try:
                    v = orig(*args)
                except Goto as g:
                    finish(call, g.target.__name__)
                    raise
                finish(call, v)
                return v
        setattr(holder, name, wrapper)
        patched.append((holder, name, orig))

    import calls as port_calls
    for name in names:
        wrap(name)
    port_calls._at = None               # indirect calls must find the wrappers
    try:
        oracle.run()
    finally:
        for m, name, orig in patched:
            setattr(m, name, orig)
        port_calls._at = None
    return calls


def functions():
    """The stage 4 game's functions, by module."""
    return [f for m in list(sys.modules.values())
            if m.__name__.startswith('hobbit.') and m.__name__ != 'hobbit.state'
            for f in vars(m).values() if inspect.isfunction(f) and f.__module__ == m.__name__]


def main():
    a = sys.argv[1:]
    if a[:1] == ['game'] and len(a) > 1:
        ran = set()
        for rec in a[1:]:
            sys.setprofile(lambda frame, event, arg: event == 'call' and ran.add(frame.f_code))
            try:
                n = check_game(rec)
                print('%s: %d passes match' % (rec, n))
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
    else:
        sys.exit(__doc__)


if __name__ == '__main__':
    main()
