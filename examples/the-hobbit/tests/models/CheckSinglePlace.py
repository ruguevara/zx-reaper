"""CheckSinglePlace: Z when the first object's record has exactly one place (+0 = 1); IX = the record."""
import _regs
import _verbs
from labels import Noun1Record

ROUTINE = 'CheckSinglePlace'
INPUTS = []
OUTPUTS = {'regs': ['A', 'IX', 'ZF']}
KINDS = ['typical', 'boundary']


def cases(rnd):
    for oid, rec in _verbs.objects():
        yield ('typical' if _verbs.byte(rec) == 1 else 'boundary'), {'mem': {Noun1Record: [rec & 0xFF, rec >> 8]}}
    yield 'boundary', {'mem': {Noun1Record: [0x00, 0xB0]}}      # a record of zeros: N = 0, DEC wraps to $FF


def port(regs):
    import verbs
    from zxpyxel import mem
    return _regs.run(verbs.CheckSinglePlace, {}, OUTPUTS['regs'])
