"""EraseSprites erases Horace if he moves and every moved guard in the maze (timer zero), guards 4, 3, 2, 1."""
from _sprites import pos, records, screen, word
ROUTINE = 'EraseSprites'
INPUTS = ['HoracePos, HoraceNextPos, GuardTimers, GuardRecords, screen (memory)']
OUTPUTS = {'regs': [], 'mem': [('SCREEN', const('SCREEN_SIZE') + const('ATTRS_SIZE')),
                               ('GuardRecordPtr', 2), ('GuardRecord', const('GUARD_RECORD_SIZE')),
                               ('GuardRecords', 4 * const('GUARD_RECORD_SIZE'))]}
KINDS = ['horace-still', 'horace-moved', 'none-in-maze', 'all-in-maze', 'some-in-maze']


def cases(rnd):
    for i in range(200):
        here = pos(rnd)
        moved = i % 2
        there = pos(rnd) if moved else here
        in_maze = [rnd.random() < 0.6 for _ in range(4)]
        if i % 20 == 0:
            in_maze = [False] * 4
        if i % 20 == 1:
            in_maze = [True] * 4
        timers = b''.join(bytes(word(0 if m else rnd.choice((1, 0x100, 0x4000, 0x401)))) for m in in_maze)
        mem = screen(rnd, sym, const)
        mem.update({sym('HoracePos'): word(here), sym('HoraceNextPos'): word(there),
                    sym('GuardTimers'): timers, sym('GuardRecords'): records(rnd)})
        kind = ('none-in-maze' if not any(in_maze) else 'all-in-maze' if all(in_maze) else
                'some-in-maze') if i % 4 < 2 else ('horace-moved' if moved else 'horace-still')
        yield kind, {'mem': mem}


def port(regs):
    import sprites
    sprites.EraseSprites()
    return {}
