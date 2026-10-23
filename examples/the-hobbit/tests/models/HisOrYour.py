"""HisOrYour: DE = the word token for "his" (actor not the player) or "your"."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import _regs
import printer

ROUTINE = 'HisOrYour'
INPUTS = ['A']
OUTPUTS = {'regs': ['A', 'DE', 'ZF'], 'mem': []}
KINDS = ['typical', 'boundary']


def cases(rnd):
    for a in (0, 1, 0xFF):
        yield 'boundary', {'A': a}
    for _ in range(20):
        yield 'typical', {'A': rnd.randrange(256)}


def port(regs):
    return _regs.run(printer.HisOrYour, regs, OUTPUTS['regs'])
