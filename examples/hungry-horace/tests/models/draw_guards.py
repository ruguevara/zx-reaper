"""DrawGuards draws every guard in the maze (timer zero) and saves its record."""
from _sprites import records, screen, word
ROUTINE = 'DrawGuards'
INPUTS = ['GuardTimers, GuardRecords, BellTimer, screen (memory)']
OUTPUTS = {'regs': [], 'mem': [('SCREEN', const('SCREEN_SIZE') + const('ATTRS_SIZE')),
                               ('BellTimer', 2), ('GuardRecordPtr', 2),
                               ('GuardRecord', const('GUARD_RECORD_SIZE')),
                               ('GuardRecords', 4 * const('GUARD_RECORD_SIZE'))]}
KINDS = ['none-in-maze', 'all-in-maze', 'some-in-maze', 'scared', 'waiting']


def cases(rnd):
    for i in range(160):
        in_maze = [rnd.random() < 0.6 for _ in range(4)]
        if i % 16 == 0:
            in_maze = [False] * 4
        if i % 16 == 1:
            in_maze = [True] * 4
        scared = i % 4 == 2
        waiting = i % 4 == 3
        timers = b''.join(bytes(word(0 if m else rnd.choice((1, 0x100, 0x4000, 0x401)))) for m in in_maze)
        mem = screen(rnd, sym, const)
        mem.update({sym('GuardTimers'): timers, sym('BellTimer'): word(rnd.randrange(1, 5) if scared else 0),
                    sym('GuardRecords'): records(rnd, waits=(0, 1, 2, 3) if waiting else (0,))})
        kind = 'scared' if scared else 'waiting' if waiting else (
            'none-in-maze' if not any(in_maze) else 'all-in-maze' if all(in_maze) else 'some-in-maze')
        yield kind, {'mem': mem}


def port(regs):
    import sprites
    sprites.DrawGuards()
    return {}
