"""UpdateBell redraws the bell, or lets Horace take it (offsets 0, +-1, -32, +33)."""
from _events import pos, screen
ROUTINE = 'UpdateBell'
INPUTS = ['HoracePos', 'BellPos', 'BellTick', 'Score', 'GuardInterval', 'MazeBellStart (memory)']
OUTPUTS = {'regs': [], 'mem': [('SCREEN', 6912), ('BellPos', 3), ('Score', 2), ('BellTimer', 2),
                               ('GuardDir', 1), ('HoracePos', 2), ('WrapPause', 1), ('HoraceAnim', 1),
                               ('ExtraPassMark', 1), ('Passes', 1)]}
KINDS = ['no-bell', 'far', 'take-0', 'take-left', 'take-right', 'take-above', 'take-below-right',
         'near-not-tested', 'all-frames']
DELTAS = {'take-0': 0, 'take-left': -1, 'take-right': 1, 'take-above': -32, 'take-below-right': 33,
          'near-not-tested': None}


def case(rnd, kind, bell, horace, tick):
    m = screen(rnd, sym)
    m.update({sym('BellPos'): bell.to_bytes(2, 'little'), sym('HoracePos'): horace.to_bytes(2, 'little'),
              sym('HoraceNextPos'): horace.to_bytes(2, 'little'), sym('BellTick'): tick,
              sym('MazeBellStart'): (bell or pos(1, 3, 14)).to_bytes(2, 'little'),
              sym('Score'): rnd.randrange(0, 9000).to_bytes(2, 'little'),
              sym('GuardInterval'): rnd.randrange(1, 9), sym('GuardDir'): rnd.randrange(4),
              sym('WrapPause'): 0, sym('HoraceAnim'): rnd.randrange(256), sym('HoraceDir'): rnd.randrange(4),
              sym('HoraceAttr'): 0x39, sym('ExtraPassMark'): 2, sym('Passes'): 3})
    return kind, {'mem': m}


def cases(rnd):
    for _ in range(20):
        yield case(rnd, 'no-bell', 0, pos(1, rnd.randrange(1, 6), rnd.randrange(1, 30)), rnd.randrange(256))
    for tick in range(64):
        yield case(rnd, 'all-frames', pos(1, 2, 20), pos(1, 5, 5), tick)
    for _ in range(40):
        yield case(rnd, 'far', pos(1, 2, 20), pos(1, rnd.randrange(3, 7), rnd.randrange(1, 15)), rnd.randrange(256))
    for kind, d in DELTAS.items():
        for _ in range(8):
            bell = pos(1, rnd.randrange(2, 6), rnd.randrange(3, 28))
            if d is None:       # +-31, +32, -33: overlapping but not tested
                d = rnd.choice([31, 32, -31, -33])
            yield case(rnd, kind, bell, bell + d, rnd.randrange(256))
            if kind == 'near-not-tested':
                d = None


def port(regs):
    import events
    events.UpdateBell()
    return {}
