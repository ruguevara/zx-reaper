"""ScrollStoryUp: rows 1-17 and their attributes copied up one row, row 17 blanked."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import _regs
import _text
import screen

ROUTINE = 'ScrollStoryUp'
INPUTS = ['A', 'BC', 'DE', 'HL', 'F']
OUTPUTS = {'regs': ['A', 'BC', 'DE', 'HL'] + _text.FLAGS, 'mem': _text.SCREEN_MEM}
KINDS = ['typical', 'boundary']


def cases(rnd):
    for kind in ['boundary'] * 2 + ['typical'] * 8:
        scr = _text.random_screen(rnd)
        yield kind, {'A': rnd.randrange(256), 'F': rnd.randrange(256), 'BC': rnd.randrange(65536), 'DE': rnd.randrange(65536),
                     'HL': rnd.randrange(65536), 'mem': scr}


def port(regs):
    return _regs.run(screen.ScrollStoryUp, regs, OUTPUTS['regs'])
