"""PushWordsBefore: the command record's words around the noun, pushed for the message (SMC JR NZ). The port puts them on printer.msg_args; here they are read back as the two words under the return address."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _regs
import _parser

import parser

import printer
from zxpyxel import mem as zxmem

ROUTINE = 'PushWordsBefore'
INPUTS = ['RecPtr3']
OUTPUTS = {'regs': ['A', 'IX', 'ZF'], 'mem': [('SmcKeepWord4', 1), ('SmcKeepWord2', 1), (0xFEFC, 4)]}
KINDS = ['typical', 'boundary']
FN = 'PushWordsBefore'


def cases(rnd):
    for k in list(range(1, 60, 3)) + [1, 59]:
        yield ('typical' if 1 < k < 59 else 'boundary'), {'mem': {sym('RecPtr3'): [(sym('CommandTable') + 8 * (k - 1)) & 255, (sym('CommandTable') + 8 * (k - 1)) >> 8]}}


def port(regs):
    printer.msg_args.clear()
    out = _regs.run(getattr(parser, FN), regs, OUTPUTS['regs'])
    word4, word2 = printer.msg_args                      # pushed first / on top
    for a, w in ((0xFEFC, word2), (0xFEFE, word4)):      # the Z80's stack at SP
        zxmem[a], zxmem[a + 1] = w & 255, w >> 8
    return out
