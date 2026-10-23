"""TickGuardTimers counts the guard timers down; GuardsReleased counts when a timer's high byte and C are 0."""
ROUTINE = 'TickGuardTimers'
INPUTS = ['C (0 when BellPos is 0, else $3A: left over from UpdateBell)', 'GuardTimers', 'GuardsReleased', 'BellPos']
OUTPUTS = {'regs': [], 'mem': [('GuardTimers', 8), ('GuardsReleased', 1)]}
KINDS = ['bell-in-maze', 'bell-gone', 'low-timers', 'zero']


def case(rnd, kind, timers, bell):
    return kind, {'C': 0x3A if bell else 0, 'mem': {
        sym('GuardTimers'): b''.join(t.to_bytes(2, 'little') for t in timers),
        sym('GuardsReleased'): rnd.randrange(256), sym('BellPos'): bell.to_bytes(2, 'little')}}


def cases(rnd):
    for _ in range(50):
        yield case(rnd, 'bell-in-maze', [rnd.choice([0, 0x100, 0x1FF, 0x0050]) for _ in range(4)], 0x240)
    for _ in range(50):
        yield case(rnd, 'bell-gone', [rnd.choice([0, 0x100, 0x1FF, 0x0050, 0x2800]) for _ in range(4)], 0)
    for _ in range(30):
        yield case(rnd, 'low-timers', [rnd.randrange(1, 0x101) for _ in range(4)], 0)
    yield case(rnd, 'zero', [0, 0, 0, 0], 0)


def port(regs):
    import events
    events.TickGuardTimers()
    return {}
