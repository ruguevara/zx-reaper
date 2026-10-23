"""StepCursorBack: move the story cursor back one 6-pixel glyph, borrowing from the cell on the left."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import _regs
import _text
import screen

ROUTINE = 'StepCursorBack'
INPUTS = ['C', 'HL']
OUTPUTS = {'regs': ['A', 'C', 'HL'] + _text.FLAGS, 'mem': []}
KINDS = ['typical', 'boundary']


def cases(rnd):
    for c in range(8):                                   # 0-5 borrow, 6-7 do not
        for l in (0, 1, 0x80, 0xFF):
            yield 'boundary', {'C': c, 'HL': 0x5000 | l, 'A': rnd.randrange(256), 'F': rnd.randrange(256)}
    for _ in range(50):
        yield 'typical', {'C': rnd.randrange(8), 'HL': rnd.randrange(65536), 'A': rnd.randrange(256),
                          'F': rnd.randrange(256)}


def port(regs):
    return _regs.run(screen.StepCursorBack, regs, OUTPUTS['regs'])
