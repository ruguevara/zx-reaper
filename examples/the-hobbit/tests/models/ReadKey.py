"""ReadKey with no key down (the harness has none): KeyFound cleared, KeyPrevious refreshed, A = 0, Z."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import _regs
import _text
import devices

ROUTINE = 'ReadKey'
INPUTS = ['BC', 'HL', 'IX', 'F', 'KeyPrevious']
OUTPUTS = {'regs': ['A', 'BC', 'HL', 'IX'] + _text.FLAGS, 'mem': [('KeyFound', 2), ('KeyPrevious', 8)]}
KINDS = ['typical', 'boundary']


def cases(rnd):
    for prev in (bytes(8), bytes([255] * 8), bytes([0x1F] * 8)):
        yield 'boundary', {'BC': 1, 'HL': 2, 'IX': 3, 'F': 0, 'mem': {'KeyPrevious': prev, 'KeyFound': [9, 9]}}
    for _ in range(20):
        yield 'typical', {'BC': rnd.randrange(65536), 'HL': rnd.randrange(65536), 'IX': rnd.randrange(65536),
                          'F': rnd.randrange(256),
                          'mem': {'KeyPrevious': bytes(rnd.randrange(32) for _ in range(8)),
                                  'KeyFound': [rnd.randrange(256), rnd.randrange(256)]}}


def port(regs):
    return _regs.run(devices.ReadKey, regs, OUTPUTS['regs'])
