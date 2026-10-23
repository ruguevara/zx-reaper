"""ReadTypedWord: zxdiff test of the typed word to token routine (dictionary
lookup, punctuation, end of line, synonyms, longer-than-entry words)."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _regs
import keys

ROUTINE = 'ReadTypedWord'
INPUTS = ['HL', 'DE']
OUTPUTS = {'regs': ['A', 'B', 'C', 'D', 'E', 'HL', 'IX'],
           'mem': [('InputLinePtr', 2), ('WordLetters', 16), ('WordLength', 1),
                   ('MatchLetters', 16), ('MatchLength', 1), ('SourceTextPtr', 2)]}
KINDS = ['typical', 'boundary']

INPUT_LINE = 0x6FF9
TYPICAL = ['NORTH', 'N', 'S', 'E', 'W', 'GET', 'TAKE', 'DROP', 'SWORD', 'GANDALF', 'BILBO',
           'THORIN', 'DRAGON', 'THE', 'TO', 'ALL', 'EXCEPT', 'HELLO', 'GIVE', 'MAP', 'LOOK',
           'INVENTORY', 'QUIT', 'SAVE', 'UP', 'DOWN', 'IN', 'OUT', 'KILL', 'SAY']
# unknown words, words longer than their entry, one-letter and odd inputs
BOUNDARY = ['XYZZY', 'Z', 'QQQQQQQ', 'TAKEN', 'NORTHWARDS', 'GANDALFFF', 'INVENTORYS', 'SWORDS',
            'A', 'ZZZZZZZZZZZZZZZZZZZZ', '5', '12', 'BILBOBAGGINS', 'LOOKING', 'THEE']


def line(text):
    return bytes(text.encode() + b'\r')


def cases(rnd):
    for w in TYPICAL:
        text = ' ' * rnd.randrange(3) + w + rnd.choice(['', ' ', ' SWORD', '.', ',', ' "X']) 
        yield 'typical', {'HL': INPUT_LINE, 'DE': rnd.randrange(65536), 'mem': {INPUT_LINE: line(text)}}
    for w in BOUNDARY:
        yield 'boundary', {'HL': INPUT_LINE + rnd.randrange(2), 'DE': rnd.randrange(65536),
                           'mem': {INPUT_LINE: line(' ' + w + ' X')}}
    for text in ['', '   ', '.', ',', '"', ' . x', '..', '"HELLO"', ',N']:
        yield 'boundary', {'HL': INPUT_LINE, 'DE': 0x1234, 'mem': {INPUT_LINE: line(text)}}


def port(regs):
    return _regs.run(keys.ReadTypedWord, regs, OUTPUTS['regs'])
