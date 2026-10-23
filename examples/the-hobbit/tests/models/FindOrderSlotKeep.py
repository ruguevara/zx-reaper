"""FindOrderSlotKeep: FindOrderSlot with HL, DE, BC kept; only Z comes back."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _regs

import parser

ROUTINE = 'FindOrderSlotKeep'
INPUTS = ['BC', 'DE', 'HL', 'Subject']
OUTPUTS = {'regs': ['A', 'BC', 'DE', 'HL', 'ZF']}
KINDS = ['typical', 'boundary']


def case(rnd, owners, subject):
    mem = {sym('OrderSlots') + 25 * k: o for k, o in enumerate(owners)}
    mem[sym('Subject')] = subject
    return {'BC': rnd.randrange(65536), 'DE': rnd.randrange(65536), 'HL': rnd.randrange(65536), 'mem': mem}


def cases(rnd):
    for _ in range(30):
        owners = [rnd.choice([0, 0xFF, rnd.randrange(1, 0x30)]) for _ in range(8)]
        yield 'typical', case(rnd, owners, rnd.choice(owners))
    yield 'boundary', case(rnd, [5] * 8, 9)
    yield 'boundary', case(rnd, [1, 2, 3, 4, 5, 6, 7, 8], 8)


def port(regs):
    return _regs.run(parser.FindOrderSlotKeep, regs, OUTPUTS['regs'])
