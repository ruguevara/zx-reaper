"""IsExcluded: does an EXCEPT record below the main record name FirstObject? NZ yes."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _regs
import _parser

import parser

ROUTINE = 'IsExcluded'
INPUTS = ['IY', 'FirstObject', 'AllActive', 'AllMode']
OUTPUTS = {'regs': ['A', 'DE', 'HL', 'IY', 'ZF']}
KINDS = ['typical', 'boundary']
TOP = _parser.PHRASE_STACK_TOP
NAMES = _parser.object_names()


def case(rnd, first, named, n_except=1, plain_after=True):
    """named: the object ids whose names the EXCEPT records hold."""
    mem = {TOP + 1: 0x80, sym('FirstObject'): first, sym('AllActive'): 1, sym('AllMode'): 2}
    for k in range(1, n_except + 1):
        rec = [0] * 24
        rec[1] = _parser.EXCEPT
        rec[8:14] = NAMES[named[k - 1]]
        mem[TOP - 24 * k] = rec
    if plain_after:
        mem[TOP - 24 * (n_except + 1) + 1] = 0
    return {'IY': TOP, 'DE': rnd.randrange(65536), 'HL': rnd.randrange(65536), 'mem': mem}


def cases(rnd):
    ids = sorted(NAMES)
    for _ in range(40):
        n = rnd.randrange(1, 4)
        named = [rnd.choice(ids) for _ in range(n)]
        first = rnd.choice(named + [rnd.choice(ids)])
        yield 'typical', case(rnd, first, named, n)
    yield 'boundary', case(rnd, ids[0], [ids[0]])                     # the first object of the table
    yield 'boundary', case(rnd, ids[-1], [ids[-1]])                   # the last one
    yield 'boundary', {'IY': TOP, 'DE': 1, 'HL': 2, 'mem': {TOP - 23: 0, sym('FirstObject'): ids[0]}}   # no EXCEPT record


def port(regs):
    return _regs.run(parser.IsExcluded, regs, OUTPUTS['regs'])
