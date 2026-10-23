"""PrintArticle: the article of a noun code (the, a, an, some; none for "you"; a capital flag for a proper name)."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import _text
import printer

ROUTINE = 'PrintArticle'
INPUTS = ['DE', 'RawOutputFlag', 'EchoingCommand', 'story window state']
OUTPUTS = {'regs': ['A', 'DE', 'HL'], 'mem': _text.STORY_MEM}
KINDS = ['typical', 'boundary']


def cases(rnd):
    def case(kind, de, raw=0, echo=0, **state):
        mem = _text.story_state(rnd, **state)
        mem.update({'RawOutputFlag': raw, 'EchoingCommand': echo, 'InputColumn': 32,
                    'InputCursor': [0xE0, 0x50], 'InputCursorGlyph': 0x2B})
        return kind, {'DE': de, 'mem': mem}
    yield case('boundary', 0x07A8)                       # "you" (bit 15 stripped is the WORD_YOU test)
    yield case('boundary', 0x87A8)                       # "you" as a proper name
    yield case('boundary', 0x8100)                       # a proper name: only the capital flag
    yield case('boundary', 0x87A9)
    yield case('boundary', 0x1100, raw=0)
    for style in range(8):                               # bits 12-14 pick the article
        for raw, echo in ((0, 0), (1, 0), (0, 1)):
            yield case('typical', style << 12 | 0x0100 + style, raw, echo, last=0x41)


def port(regs):
    return _text.run_async(printer.PrintArticle, regs, OUTPUTS['regs'])
