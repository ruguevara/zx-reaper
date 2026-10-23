"""CompareWords: zxdiff test of the typed word against dictionary word compare."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _regs
import _keys

import keys

ROUTINE = 'CompareWords'
INPUTS = ['WordLength', 'MatchLength', 'WordLetters', 'MatchLetters']
OUTPUTS = {'regs': ['A', 'B', 'DE', 'HL', 'ZF', 'CF']}
KINDS = ['typical', 'boundary']


def mk(rnd, n, same, m):
    word = [rnd.randrange(1, 27) for _ in range(n)]
    match = list(word[:m]) if same else [rnd.randrange(1, 27) for _ in range(m)]
    match += [rnd.randrange(1, 27) for _ in range(m - len(match))]
    return word, match


def case(rnd, n, m, same, differ_at=None):
    word, match = mk(rnd, n, same, m)
    if differ_at is not None and differ_at < min(n, m):
        match[differ_at] = word[differ_at] % 26 + 1
    return {'mem': {0x707A: bytes(word + [0] * (16 - n)), 0x708A: n,
                    0x708B: bytes(match + [0] * (16 - m)), 0x709B: m}}


def cases(rnd):
    for n, m in [(5, 5), (3, 6), (6, 3), (1, 1), (4, 9), (7, 2)]:
        yield 'typical', case(rnd, n, m, True)
        yield 'typical', case(rnd, n, m, False)
        yield 'typical', case(rnd, n, m, True, differ_at=min(n, m) - 1)
    for n, m in [(16, 16), (1, 16), (16, 1), (0, 5), (5, 0), (0, 0)]:
        yield 'boundary', case(rnd, n, m, True)
        yield 'boundary', case(rnd, n, m, False)


def port(regs):
    return _regs.run(keys.CompareWords, regs, OUTPUTS['regs'])
