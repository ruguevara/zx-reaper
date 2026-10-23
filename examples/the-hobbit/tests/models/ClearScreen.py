"""ClearScreen: zxdiff test of the screen clear (bitmap, attributes, the extra byte at $5B00)."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _regs
import keys

ROUTINE = 'ClearScreen'
INPUTS = ['BC', 'DE', 'HL']
OUTPUTS = {'regs': ['BC', 'DE', 'HL'], 'mem': [(0x4000, 0x1B01)]}
KINDS = ['typical', 'boundary']


def cases(rnd):
    for _ in range(2):
        yield 'typical', {'BC': rnd.randrange(65536), 'DE': rnd.randrange(65536), 'HL': rnd.randrange(65536),
                          'mem': {0x4000: bytes(rnd.randrange(256) for _ in range(0x1B01))}}
    yield 'boundary', {'mem': {0x4000: b'\xff' * 0x1B01}}


def port(regs):
    return _regs.run(keys.ClearScreen, regs, OUTPUTS['regs'])
