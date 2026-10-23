"""OutputStoryChar: a character in the story window: indent, lower case, capital after a full stop, back-space, line end."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import _text
import screen

ROUTINE = 'OutputStoryChar'
INPUTS = ['A', 'BC', 'HL', 'F', 'story window state']
OUTPUTS = {'regs': ['A', 'BC', 'HL'] + _text.FLAGS,
           'mem': _text.SCREEN_MEM + [('StoryColumn', 6), ('CapitalNext', 1), ('StoryLastChar', 1), ('NoPauseLines', 1)]}
KINDS = ['typical', 'boundary']


def cases(rnd):
    def case(kind, code, **state):
        return kind, {'A': code, 'BC': rnd.randrange(65536), 'HL': rnd.randrange(65536),
                      'F': rnd.randrange(256), 'mem': _text.story_state(rnd, **state)}
    for code in (13, 8, ord('.'), ord('A'), ord('z'), 0x20, 0x7F):
        yield case('boundary', code)
        yield case('boundary', code, column=1)           # the line is full: it ends
        yield case('boundary', code, last=0x41, capital=0, indent=3)
        yield case('boundary', code, capital=1, last=0x2E, pixel=0)
        yield case('boundary', code, cursor=0x5020 + 31)  # the bottom row's end
    for _ in range(150):
        yield case('typical', rnd.choice([13, 8, ord('.'), rnd.randrange(0x20, 0x80)]),
                   column=rnd.randrange(1, 43), last=rnd.choice([0, 0, 0x41]), capital=rnd.randrange(2),
                   indent=rnd.choice([0, 0, 2]))


def port(regs):
    return _text.run_async(screen.OutputStoryChar, regs, OUTPUTS['regs'])
