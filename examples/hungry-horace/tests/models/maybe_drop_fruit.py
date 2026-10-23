"""MaybeDropFruit, on the record in the buffer, plants a fruit in SavedBackground when FruitTimer runs out."""
ROUTINE = 'MaybeDropFruit'
INPUTS = ['GuardWait', 'SavedBackground', 'FruitTimer', 'RandomPtr (memory)']
OUTPUTS = {'regs': [], 'mem': [('SavedBackground', 36), ('FruitTimer', 2), ('RandomPtr', 2)]}
KINDS = ['counting', 'fires', 'guard-wait', 'red-cell']


def case(rnd, kind, fruit, wait=0, red_at=None):
    bg = bytearray(rnd.choice([0x3E, 0x3F, 0x38, 0x39]) for _ in range(36))
    for i in range(0, 36, 9):
        bg[i] = rnd.choice([0x3E, 0x3F, 0x38])
    if red_at is not None:
        bg[red_at * 9] = 0x3A
    return kind, {'mem': {sym('GuardWait'): wait, sym('SavedBackground'): bytes(bg),
                          sym('FruitTimer'): fruit.to_bytes(2, 'little'),
                          sym('RandomPtr'): rnd.randrange(0x4000).to_bytes(2, 'little')}}


def cases(rnd):
    for _ in range(20):
        yield case(rnd, 'counting', rnd.randrange(2, 3000))
    for _ in range(60):
        yield case(rnd, 'fires', 1)
    for _ in range(10):
        yield case(rnd, 'guard-wait', 1, wait=rnd.randrange(1, 90))
    for i in range(4):
        yield case(rnd, 'red-cell', 1, red_at=i)


def port(regs):
    import events
    events.MaybeDropFruit()
    return {}
