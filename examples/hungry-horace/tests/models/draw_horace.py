"""DrawHorace counts the wrap pause down, or draws Horace at his next position."""
from _events import rand_pos, screen
ROUTINE = 'DrawHorace'
INPUTS = ['WrapPause', 'HoraceNextPos', 'HoraceDir', 'HoraceAttr', 'HoraceAnim (memory)']
OUTPUTS = {'regs': [], 'mem': [('SCREEN', 6912), ('WrapPause', 1), ('HoracePos', 2), ('HoraceAnim', 1)]}
KINDS = ['draw', 'wrap-pause', 'anim-wrap']


def case(rnd, kind, wrap, anim):
    m = screen(rnd, sym)
    m.update({sym('WrapPause'): wrap, sym('HoraceNextPos'): rand_pos(rnd).to_bytes(2, 'little'),
              sym('HoracePos'): rnd.randrange(65536).to_bytes(2, 'little'),
              sym('HoraceDir'): rnd.randrange(4), sym('HoraceAttr'): rnd.randrange(0x38, 0x40),
              sym('HoraceAnim'): anim})
    return kind, {'mem': m}


def cases(rnd):
    for _ in range(150):
        yield case(rnd, 'draw', 0, rnd.randrange(256))
    for _ in range(30):
        yield case(rnd, 'wrap-pause', rnd.randrange(1, 4), rnd.randrange(256))
    for anim in (0x0F, 0x1F, 0xFF):
        yield case(rnd, 'anim-wrap', 0, anim)


def port(regs):
    import events
    events.DrawHorace()
    return {}
