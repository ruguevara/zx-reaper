"""ClaimOrderSlots: the first A pending slots (at most OrderSlotCount) go to FirstObject, the other pending ones are freed."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _regs

import parser

ROUTINE = 'ClaimOrderSlots'
INPUTS = ['A', 'BC', 'DE', 'IX']
OUTPUTS = {'regs': ['A', 'BC', 'DE', 'IX', 'ZF'], 'mem': [('OrderSlots', 200)]}
KINDS = ['typical', 'boundary']


def case(rnd, pending, a, other=0x20):
    """pending: slot numbers marked $FF (their number is OrderSlotCount)."""
    mem = {}
    for k in range(8):
        mem[sym('OrderSlots') + 25 * k] = 0xFF if k in pending else (other if k % 3 == 0 else 0)
    mem[sym('OrderSlotCount')] = len(pending)
    mem[sym('FirstObject')] = rnd.randrange(1, 0x30)
    return {'A': a, 'BC': rnd.randrange(65536), 'DE': rnd.randrange(65536), 'IX': rnd.randrange(65536), 'mem': mem}


def cases(rnd):
    for _ in range(40):
        pending = rnd.sample(range(8), rnd.randrange(1, 6))
        yield 'typical', case(rnd, pending, rnd.randrange(0, len(pending) + 2))
    yield 'boundary', case(rnd, [], 0)                       # nothing pending
    yield 'boundary', case(rnd, [2, 5], 0)                   # all freed
    yield 'boundary', case(rnd, [2, 5], 2)                   # all claimed
    yield 'boundary', case(rnd, [0, 1, 2, 3, 4, 5, 6, 7], 8) # every slot
    yield 'boundary', case(rnd, [7], 1)                      # the last slot


def port(regs):
    return _regs.run(parser.ClaimOrderSlots, regs, OUTPUTS['regs'])
