"""SplitNounPhrases: the two noun phrases of a matched phrase record into RecBuf1/RecBuf2 (and PhraseBuffer), by the flags of the command record."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _regs
import _parser

import parser

import _keys

ROUTINE = 'SplitNounPhrases'
INPUTS = ['A', 'IX', 'IY']
OUTPUTS = {'regs': ['A', 'BC', 'DE', 'HL', 'ZF'],
           'mem': [('StateB71D', 2), ('RecWork', 2), ('RecBuf1', 12), ('PhraseBuffer', 6), ('RecWork6', 2), ('RecWord2', 4)]}
KINDS = ['typical', 'boundary']
IY = _parser.PHRASE_STACK_TOP


def case(rnd, k, swapped, collect):
    rec = _keys.command_table()[k - 1]
    w2, w3 = list(rec[2:4]), list(rec[4:6])
    phrase = _parser.record(rnd)
    if collect == 'match0E':
        phrase[0x0E:0x10] = [w2[0], w2[1] & 0x0F]          # the first collected word equals the word at +$0E
    elif collect == 'match10':
        phrase[0x10:0x12] = [w2[0], w2[1] & 0x0F]
    words = {'none': ([0, 0], [0, 0]), 'one': (w2, [0, 0])}.get(collect, (w2, w3))
    return {'A': swapped, 'IX': sym('CommandTable') + 8 * (k - 1), 'IY': IY, 'BC': rnd.randrange(65536), 'DE': rnd.randrange(65536),
            'HL': rnd.randrange(65536), 'mem': {IY: phrase, sym('RecWord2'): words[0] + words[1], sym('RecWork'): 0, sym('RecWork1'): 0}}


def cases(rnd):
    for _ in range(50):
        yield 'typical', case(rnd, rnd.randrange(1, 60), rnd.randrange(2), rnd.choice(['one', 'both', 'match0E', 'match10']))
    for k in (1, 59):
        yield 'boundary', case(rnd, k, 0, 'none')
    yield 'boundary', case(rnd, 20, 1, 'both')
    yield 'boundary', case(rnd, 20, 0, 'none')


def port(regs):
    return _regs.run(parser.SplitNounPhrases, regs, OUTPUTS['regs'])
