"""PrintInputWindowChar: a character at the input window's cursor: capitals, CR, back-space, a full line."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import _regs
import _text
import screen

ROUTINE = 'PrintInputWindowChar'
INPUTS = ['A', 'HL', 'F', 'InputCursor', 'InputColumn', 'InputCursorGlyph']
OUTPUTS = {'regs': ['A', 'HL'] + _text.FLAGS,
           'mem': _text.SCREEN_MEM + [('InputColumn', 1), ('InputCursor', 2)]}
KINDS = ['typical', 'boundary']


def cases(rnd):
    def case(kind, code, cur, columns):
        return kind, {'A': code, 'HL': rnd.randrange(65536), 'F': rnd.randrange(256),
                      'mem': {**_text.random_screen(rnd), 'InputCursor': [cur & 255, cur >> 8],
                              'InputColumn': columns, 'InputCursorGlyph': 0x2B}}
    for code in (13, 8, 0x61, 0x7A, 0x41, 0x20):
        yield case('boundary', code, 0x50E0, 32)         # start of the bottom row
        yield case('boundary', code, 0x50FF, 1)          # last column: wraps
        yield case('boundary', code, 0x5060, 32)         # start of the top input row
        yield case('boundary', code, 0x50E5, 31)
    for _ in range(150):
        yield case('typical', rnd.choice([13, 8, rnd.randrange(0x20, 0x80)]),
                   _text.cell(rnd, range(19, 24)), rnd.randrange(1, 33))


def port(regs):
    return _regs.run(screen.PrintInputWindowChar, regs, OUTPUTS['regs'])
