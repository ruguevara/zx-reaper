"""PrintInputChar: draw a character of the ROM font in the input window and move one cell right."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import _regs
import _text
import screen

ROUTINE = 'PrintInputChar'
INPUTS = ['A', 'HL', 'BC', 'DE', 'F']
OUTPUTS = {'regs': ['A', 'BC', 'DE', 'HL'] + _text.FLAGS, 'mem': _text.SCREEN_MEM}
KINDS = ['typical', 'boundary']


def cases(rnd):
    def case(kind, code, hl):
        return kind, {'A': code, 'HL': hl, 'BC': rnd.randrange(65536), 'DE': rnd.randrange(65536),
                      'F': rnd.randrange(256), 'mem': _text.random_screen(rnd)}
    for code in (0x20, 0x7F, 0x41):
        for hl in (0x50E0, 0x50FF, 0x5060):             # the row's end: L wraps, flags of INC L
            yield case('boundary', code, hl)
    for _ in range(100):
        yield case('typical', rnd.randrange(0x20, 0x80), _text.cell(rnd, range(19, 24)))


def port(regs):
    return _regs.run(screen.PrintInputChar, regs, OUTPUTS['regs'])
