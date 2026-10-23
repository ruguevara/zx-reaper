"""UpdateFruitDrops gives each released guard (timer zero) a turn at MaybeDropFruit."""
from _events import screen
ROUTINE = 'UpdateFruitDrops'
INPUTS = ['GuardTimers', 'GuardRecords', 'FruitTimer', 'RandomPtr (memory)']
OUTPUTS = {'regs': [], 'mem': [('GuardTimers', 14), ('GuardRecordPtr', 2), ('GuardRecord', 2 + 1 + 1 + 2 + 1 + 36),
                               ('GuardRecords', 4 * 43), ('FruitTimer', 2), ('RandomPtr', 2)]}
KINDS = ['released', 'waiting', 'timer-fires', 'guard-wait', 'red-cell']


def case(rnd, kind, timers, fruit, wait=0, red=False):
    m = {sym('GuardTimers'): b''.join(t.to_bytes(2, 'little') for t in timers),
         sym('GuardRecords'): bytes(rnd.randrange(256) for _ in range(4 * 43)),
         sym('FruitTimer'): fruit.to_bytes(2, 'little'), sym('RandomPtr'): rnd.randrange(0x4000).to_bytes(2, 'little')}
    for i in range(4):
        rec = sym('GuardRecords') + 43 * i
        m[rec + 6] = wait                       # GuardWait inside the record
        m[rec + 7] = bytes(rnd.choice([0x3E, 0x3F, 0x38]) for _ in range(1))
    if red:
        for i in range(4):
            m[sym('GuardRecords') + 43 * i + 7] = 0x3A
    return kind, {'mem': m}


def cases(rnd):
    for _ in range(40):
        t = [0] + [rnd.choice([0, 0, 0x100, 0x200]) for _ in range(3)]
        yield case(rnd, 'released', t, rnd.randrange(2, 3000))
    for _ in range(10):
        yield case(rnd, 'waiting', [0x100, 0x200, 0x300, 0x400], rnd.randrange(2, 3000))
    for _ in range(40):
        yield case(rnd, 'timer-fires', [rnd.choice([0, 0x100]) for _ in range(4)], 1)
    for _ in range(10):
        yield case(rnd, 'guard-wait', [0, 0, 0, 0], 1, wait=rnd.randrange(1, 90))
    for _ in range(10):
        yield case(rnd, 'red-cell', [0, 0, 0, 0], 1, red=True)


def port(regs):
    import events
    events.UpdateFruitDrops()
    return {}
