"""PrintWord: print a dictionary word (DE) with its ending, a space, a wrap and the capital flag, through PrintChar."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import _text
import printer

ROUTINE = 'PrintWord'
INPUTS = ['DE', 'HL', 'BC', 'Subject', 'FirstObject', 'story window state']
OUTPUTS = {'regs': ['A', 'BC', 'DE', 'HL'], 'mem': _text.STORY_MEM}
KINDS = ['typical', 'boundary']


def words(rnd):
    """Word codes: dictionary offsets from the vocabulary, with print modes."""
    for _ in range(400):
        yield rnd.randrange(1, 0x0C00)


def cases(rnd):
    def case(kind, de, subject, first, **state):
        mem = _text.story_state(rnd, **state)
        mem.update({'Subject': subject, 'FirstObject': first})
        return kind, {'DE': de, 'HL': rnd.randrange(65536), 'BC': rnd.randrange(65536), 'mem': mem}
    yield case('boundary', 0, 0, 0)                      # offset 0 prints nothing
    yield case('boundary', 0x7000, 0, 0)
    for mode in range(8):
        for subject, first in ((0, 0), (5, 0), (0, 5)):
            for column in (42, 3):                       # 3: the word does not fit
                yield case('boundary', mode << 12 | 0x0100, subject, first, column=column)
    it = words(rnd)
    for _ in range(300):
        yield case('typical', next(it) | rnd.randrange(8) << 12, rnd.choice([0, 5]), rnd.choice([0, 5]),
                   column=rnd.randrange(1, 43), last=rnd.choice([0, 0x41]), capital=rnd.randrange(2),
                   pixel=rnd.randrange(8))


def port(regs):
    return _text.run_async(printer.PrintWord, regs, OUTPUTS['regs'])
