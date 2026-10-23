"""InheritRecord: the record at IY takes the command word and flags of the older record at IX (and its first block when E bit 7 allows)."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _regs
import _parser

import parser

ROUTINE = 'InheritRecord'
INPUTS = ['BC', 'DE', 'HL', 'IX', 'IY']
OUTPUTS = {'regs': ['A', 'BC', 'DE', 'HL', 'ZF'], 'mem': [(_parser.PHRASE_STACK_TOP - 24 * 3, 24 * 5)]}
KINDS = ['typical', 'boundary']
NEW = _parser.PHRASE_STACK_TOP - 24


def case(rnd, e, prep, word2):
    old = _parser.record(rnd, rnd.choice([0, _parser.ALL]))
    new = _parser.record(rnd, 0, empty=0.5)
    if not prep:
        old[4:6] = [0, 0]                                  # the older first block has no preposition
    else:
        old[4:6] = [9, 1]
    new[2:4] = [0, 0] if not word2 else [7, 2]
    new[0:2] = [0, 0]
    return {'BC': rnd.randrange(65536), 'DE': e | rnd.randrange(256) << 8, 'HL': rnd.randrange(65536), 'IX': NEW + 24, 'IY': NEW,
            'mem': {NEW: new, NEW + 24: old}}


def cases(rnd):
    for _ in range(40):
        yield 'typical', case(rnd, rnd.randrange(256), rnd.random() < 0.7, rnd.random() < 0.5)
    yield 'boundary', case(rnd, 0x80, False, False)        # no preposition: only the word and flags
    yield 'boundary', case(rnd, 0x00, True, False)         # a preposition but the second block is not free
    yield 'boundary', case(rnd, 0x80, True, False)         # the block moves, the second word is copied
    yield 'boundary', case(rnd, 0xFF, True, True)          # the second word is there already


def port(regs):
    return _regs.run(parser.InheritRecord, regs, OUTPUTS['regs'])
