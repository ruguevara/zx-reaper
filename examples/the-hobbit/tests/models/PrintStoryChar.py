"""PrintStoryChar: draw a 6-pixel glyph of the game font at a pixel offset, spilling into the next cell."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import _regs
import _text
import screen

ROUTINE = 'PrintStoryChar'
INPUTS = ['A', 'C', 'HL', 'B', 'DE', 'F']
OUTPUTS = {'regs': ['A', 'B', 'C', 'DE', 'HL'] + _text.FLAGS, 'mem': _text.SCREEN_MEM}
KINDS = ['typical', 'boundary']


def cases(rnd):
    def case(kind, code, hl, c):
        return kind, {'A': code, 'C': c, 'HL': hl, 'B': rnd.randrange(256), 'DE': rnd.randrange(65536),
                      'F': rnd.randrange(256), 'mem': _text.random_screen(rnd)}
    for code in (0x20, 0x7F, 0x41):                      # first and last glyph
        for c in (0, 1, 2, 7):                           # offset 2 is the first with no spill past 8
            yield case('boundary', code, 0x4000 + 31, c)             # last cell of the row
            yield case('boundary', code, 0x5020 + 31 - 1, c)         # the story's bottom row
    for c in range(8):
        yield case('boundary', 0x20 + c, 0x4000, c)
    for _ in range(150):
        yield case('typical', rnd.randrange(0x20, 0x80), _text.cell(rnd, range(18)), rnd.randrange(8))


def port(regs):
    return _regs.run(screen.PrintStoryChar, regs, OUTPUTS['regs'])
