"""ShowScore prints HL as the score, grants an extra pass when Score passes a multiple of 10000, and plays the chirp."""
from _sprites import screen, word
ROUTINE = 'ShowScore'
INPUTS = ['HL', 'Score, ExtraPassMark, Passes, GameActive, SoundMask, screen (memory)']
OUTPUTS = {'regs': [], 'mem': [('SCREEN', const('SCREEN_SIZE') + const('ATTRS_SIZE')),
                               ('Score', 7)]}
KINDS = ['same-tenk', 'extra-pass', 'ten-passes', 'printing-off', 'hl-differs', 'game-start']


def case(rnd, score, mark, passes, hl=None, active=1):
    m = screen(rnd, sym, const, objects=False)
    m.update({sym('Score'): word(score), sym('ExtraPassMark'): mark, sym('Passes'): passes,
              sym('GameActive'): active, sym('SoundMask'): rnd.choice((0, 0x1F))})
    return {'HL': score if hl is None else hl, 'mem': m}


def cases(rnd):
    for _ in range(60):
        score = rnd.randrange(65536)
        yield 'same-tenk', case(rnd, score, score // 10000 + 2, rnd.randrange(10))
    for _ in range(60):
        score = rnd.randrange(65536)
        yield 'extra-pass', case(rnd, score, rnd.choice([m for m in range(9) if m != score // 10000 + 2]),
                                 rnd.randrange(9))
    for score in (0, 9999, 10000, 19999, 20000, 59999, 60000, 65535):
        yield 'same-tenk', case(rnd, score, score // 10000 + 2, 3)
        yield 'extra-pass', case(rnd, score, score // 10000 + 1, 3)
    for _ in range(5):
        yield 'ten-passes', case(rnd, 10500, 2, 9)      # prints ':'
    for active in (0, 2, 0xFE):
        yield 'printing-off', case(rnd, 12345, 2, 3, active=active)
    for _ in range(10):      # every caller passes Score; the asm uses Score for the pass test anyway
        yield 'hl-differs', case(rnd, rnd.randrange(65536), 2, 3, hl=rnd.randrange(65536))
    for score in (0, 50, 150):
        yield 'game-start', case(rnd, score, 0, 3)


def port(regs):
    import sprites
    sprites.ShowScore(regs['HL'])
    return {}
