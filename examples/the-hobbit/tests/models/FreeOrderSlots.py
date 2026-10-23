"""FreeOrderSlots: set the owner of every order slot of actor A to 0."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _regs

import parser

ROUTINE = 'FreeOrderSlots'
INPUTS = ['A', 'BC', 'DE', 'HL']
OUTPUTS = {'regs': ['BC', 'DE', 'HL', 'ZF'], 'mem': [('OrderSlots', 200)]}
KINDS = ['typical', 'boundary']


def case(rnd, owners, actor):
    mem = {sym('OrderSlots') + 25 * k: o for k, o in enumerate(owners)}
    return {'A': actor, 'BC': rnd.randrange(65536), 'DE': rnd.randrange(65536), 'HL': rnd.randrange(65536), 'mem': mem}


def cases(rnd):
    for _ in range(30):
        owners = [rnd.choice([0, 0xFF, 3, 5, rnd.randrange(1, 0x30)]) for _ in range(8)]
        yield 'typical', case(rnd, owners, rnd.choice(owners + [3, 5]))
    yield 'boundary', case(rnd, [4] * 8, 4)                  # all
    yield 'boundary', case(rnd, [4] * 8, 5)                  # none
    yield 'boundary', case(rnd, [0] * 8, 0)                  # free slots stay free
    yield 'boundary', case(rnd, [1, 1, 1, 1, 1, 1, 1, 9], 9) # the last slot


def port(regs):
    return _regs.run(parser.FreeOrderSlots, regs, OUTPUTS['regs'])
