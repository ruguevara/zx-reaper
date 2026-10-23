"""MessageJump: control code 2, IX moves by the signed byte after the code; Z, A = 0."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import _regs
import printer

ROUTINE = 'MessageJump'
INPUTS = ['IX', 'displacement byte']
OUTPUTS = {'regs': ['A', 'DE', 'IX', 'ZF'], 'mem': []}
KINDS = ['typical', 'boundary']


def cases(rnd):
    for d in (0, 1, 0x7F, 0x80, 0xFF, 0xFE):             # forward, backward, either end
        yield 'boundary', {'IX': 0xB000, 'A': 2, 'mem': {0xB001: d}}
    for _ in range(40):
        yield 'typical', {'IX': rnd.randrange(0xAD7D, 0xB6D0), 'A': 2, 'mem': {}}


def port(regs):
    return _regs.run(printer.MessageJump, regs, OUTPUTS['regs'])
