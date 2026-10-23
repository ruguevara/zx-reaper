"""EatObject scores the flower (SCORE_FLOWER) or any other object (SCORE_ITEM) in Horace's next 2x2 block, then ShowScore."""
from _sprites import pos, screen, word
ROUTINE = 'EatObject'
INPUTS = ['WrapPause, HoraceNextPos, Score, ExtraPassMark, Passes, GameActive, SoundMask, screen (memory)']
OUTPUTS = {'regs': [], 'mem': [('SCREEN', const('SCREEN_SIZE') + const('ATTRS_SIZE')),
                               ('Score', 7), ('WrapPause', 1)]}
KINDS = ['wrap-pause', 'nothing', 'flower', 'item', 'extra-pass', 'printing-off']
BLANK, FLOWER, BELL = 0x3E, 0x3C, 0x3A


def case(rnd, wrap, attrs, score, mark, passes, active=1):
    p = pos(rnd)
    m = screen(rnd, sym, const)
    a = sym('ATTRS') + (p >> 11 << 8) + (p & 0x7FF)
    for cell, val in zip((a, a + 1, a + 32, a + 33), attrs):
        m[cell] = val
    m.update({sym('WrapPause'): wrap, sym('HoraceNextPos'): word(p), sym('Score'): word(score),
              sym('ExtraPassMark'): mark, sym('Passes'): passes, sym('GameActive'): active,
              sym('SoundMask'): rnd.choice((0, 0x1F))})
    return {'mem': m}


def cases(rnd):
    for _ in range(20):
        yield 'wrap-pause', case(rnd, rnd.randrange(1, 4), [FLOWER] * 4, 100, 2, 3)
    for _ in range(30):
        yield 'nothing', case(rnd, 0, [rnd.choice((BLANK, 0x38, 0x39, 0x3D)) for _ in range(4)], 100, 2, 3)
    for _ in range(60):
        score = rnd.randrange(0, 60000)
        yield 'flower', case(rnd, 0, [rnd.choice((FLOWER, BLANK)) for _ in range(3)] + [FLOWER],
                             score, score // 10000 + 2, rnd.randrange(10))
    for _ in range(60):
        score = rnd.randrange(0, 60000)
        yield 'item', case(rnd, 0, [BELL, rnd.choice((FLOWER, BLANK)), BLANK, rnd.choice((BLANK, 0x3B))],
                           score, score // 10000 + 2, rnd.randrange(10))
    for score in (9990, 9995, 9999, 19990, 29995, 59990, 65530):   # the score crosses a multiple of 10000
        for attrs in ([FLOWER] * 4, [BELL] * 4):
            yield 'extra-pass', case(rnd, 0, attrs, score, score // 10000 + 2, rnd.randrange(10))
    yield 'extra-pass', case(rnd, 0, [FLOWER] * 4, 5, 0, 9)         # a game's first call: mark 0
    for active in (0, 2, 0xFE):
        yield 'printing-off', case(rnd, 0, [FLOWER] * 4, 12345, 3, 3, active)


def port(regs):
    import sprites
    sprites.EatObject()
    return {}
