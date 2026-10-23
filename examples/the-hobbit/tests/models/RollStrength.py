"""RollStrength: A plus RandomSigned(ROLL_SPREAD); a carry gives 0 (negative spread) or $FF; BC kept (finding F9)."""
import _regs
from labels import RandomSeed

ROUTINE = 'RollStrength'
INPUTS = ['A', 'B', 'C', 'DE', 'mem']
OUTPUTS = {'regs': ['A', 'B', 'C', 'ZF', 'CF'], 'mem': [('RandomSeed', 1), ('RandomRomPtr', 2)]}
KINDS = ['typical', 'boundary']


def cases(rnd):
    for a in (1, 5, 10, 20, 40, 80, 120, 160):
        for _ in range(8):
            yield 'typical', {'A': a, 'B': rnd.randrange(256), 'C': rnd.randrange(256), 'DE': rnd.randrange(65536),
                              'mem': {RandomSeed: rnd.randrange(256)}}
    for a in (0, 1, 2, 250, 254, 255):                  # wraps under 0 and over 255
        for _ in range(20):
            yield 'boundary', {'A': a, 'B': 7, 'C': 9, 'DE': rnd.randrange(65536),
                               'mem': {RandomSeed: rnd.randrange(256)}}


def port(regs):
    import verbs
    return _regs.run(verbs.RollStrength, regs, OUTPUTS['regs'])
