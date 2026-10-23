"""FindOrderSlot: the order slot owned by Subject (Z, HL), or the end of the table."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _regs

import parser

ROUTINE = 'FindOrderSlot'
INPUTS = ['Subject']
OUTPUTS = {'regs': ['A', 'B', 'DE', 'HL', 'ZF']}
KINDS = ['typical', 'boundary']
SLOTS, SIZE = 8, 25


def slots(rnd, owners):
    mem = {}
    for k, o in enumerate(owners):
        mem[sym('OrderSlots') + k * SIZE] = o
    return mem


def cases(rnd):
    for _ in range(40):
        owners = [rnd.choice([0, 0, 0xFF, rnd.randrange(1, 0x30)]) for _ in range(SLOTS)]
        subject = rnd.choice(owners + [rnd.randrange(0x30)])
        mem = slots(rnd, owners)
        mem[sym('Subject')] = subject
        yield 'typical', {'mem': mem}
    for k in (0, SLOTS - 1):                          # the first and the last slot
        owners = [0x20] * SLOTS
        owners[k] = 7
        mem = slots(rnd, owners)
        mem[sym('Subject')] = 7
        yield 'boundary', {'mem': mem}
    for owners, subject in (([1] * SLOTS, 2),          # none: past the table
                            ([0] * SLOTS, 0)):         # Subject 0 matches a free slot
        mem = slots(rnd, owners)
        mem[sym('Subject')] = subject
        yield 'boundary', {'mem': mem}


def port(regs):
    return _regs.run(parser.FindOrderSlot, regs, OUTPUTS['regs'])
