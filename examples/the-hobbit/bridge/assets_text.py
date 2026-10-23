"""The text slice's assets (called by bridge/assets.py):

  dictionary.json   the 562 words in the original's order, by offset: letters,
                    class, ending, synonym, and whether the parser looks it up
  commands.json     the 59 command records (CommandTable): four words and their
                    flag nibbles each
  messages.json     every message, named by its stage 3 label, as markup
                    (game/hobbit/text.py reads it; the format is in the file)
  font.png          the story window's font: 96 glyphs, 16 x 6 cells

Each file is checked against the original as it is written: the dictionary's
letter index, the commands' offsets, every message's items (the markup loaded
back must print exactly what the bytecode prints) and the font's bytes.

  python3 bridge/assets_text.py      the checks alone, on the files as they are
"""
import importlib.util
import json
import os

import paths
import labels as L
from decode import names, word
from assets import OUT, writing
from zxpyxel import png

_spec = importlib.util.spec_from_file_location('text_tool', os.path.join(paths.ROOT, 'scripts/text.py'))
T = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(T)

ENDINGS = ['s', 'es', 'ies', '\bies', 'd', 'ing', '', '']        # WordEndings, 4 bytes each
MODES = {0: '', 1: ':obj1', 4: ':always'}                        # print modes that may add an ending
CODES = {0: 'thing', 1: 'word', 3: 'weapon', 4: 'the_word', 5: 'nop', 6: 'subj', 7: 'obj1',
         8: 'bs', 9: 'obj2', 10: 'nop', 12: 'his_subj', 13: 'nl', 14: 'his_obj1', 15: 'nop',
         16: 'subj_is', 17: 'obj1_is', 18: 'nop', 19: 'arg_is'}
ENDS = {0x14: '{end nl}', 0x15: '{end .}', 0x16: '{end}', 2: '{end}', 3: '{end .}', 6: '{end nl}'}
FONT_COLS, FONT_ROWS = 16, 6

DICTIONARY_ABOUT = [
    'The dictionary of The Hobbit: the words the parser knows and the words the messages print.',
    'A word is named by its offset (state.json, commands.json and messages name words so); the',
    'order is the original\'s. word: its letters; class: the parser\'s word class (0 other, 1-2',
    'directions, 3 verb, 4 go/run, 5 noun, 6 adjective, 7 preposition, 8 article, 9 command',
    'word, 10 and, 11 then); ending: what a verb adds ("\\b" is a back-space: carr-ies), null for',
    'none; synonym: the offset of the word it stands for when typed; typed: the parser looks',
    'typed words up among these, by first letter, in this order: a typed word matches the first',
    'word it is a prefix of; a typed word longer than a word of 4 or more letters that starts',
    'with it matches it too, unless the next word matches as well (then that one is tried).']

COMMANDS_ABOUT = [
    'The command table: record n (id n, 1-59) is what the parser matches a typed phrase against:',
    'words: the verb, two prepositions, and a word the echo prints first (the first ten: the',
    'moves, "go"); "" for none. A word is the first dictionary entry with these letters.',
    'flags: the high nibble of each word (the parser packs them: StateB71D = flags[1] << 4 |',
    'flags[0], StateB71E = flags[3] << 4 | flags[2]; bit 2 a second noun, 3 a first noun, 4',
    'silent, 5 the first preposition before the first noun; StateB71E bit 7 the second one).']

MESSAGES_ABOUT = [
    'The messages, by name (the stage 3 label; L and the hex address for an entry other',
    'messages or the code use without a label). A message is a list of items separated by spaces:',
    '  word            a dictionary word, printed after a space (none at the start of a line),',
    '                  wrapped to the next line when it does not fit',
    '  word(e)         a word with its ending e (as in dictionary.json), added when the subject',
    '                  is not the player ("you take", "Thorin takes"); word(e):obj1 when the',
    '                  first object is not the player; word(e):always always',
    '  Word, Word(e)   the same with a capital letter first',
    '  `TEXT`          characters as they are (no space added; letters print in lower case in',
    '                  the story window unless a capital is due, in capitals in the input one)',
    '  {subj} {obj1} {obj2}         the name of the subject or an object ("you", "the rope")',
    '  {subj_is} {obj1_is} {arg_is} a name and "is" or "are"',
    '  {his_subj} {his_obj1}        "his" or "your"',
    '  {thing} {word} {the_word}    a name, a word, a word with its article, and in {arg_is} a',
    '                  name: what the code passes (args, popped from the end)',
    '  {weapon}        the weapon of a fight; {preposition} the word the game sets (in, on, at...)',
    '  {nl}            a new line without a capital after it; {bs} a back-space; {nop} nothing',
    '  {call NAME}     print the message NAME here, then go on',
    '  {goto NAME}     go on with the message NAME (the last item)',
    '  {end} {end nl} {end .}       the end: nothing more, a new line, a full stop and a new line']


def dump_lines(about, key, items, fmt):
    """JSON with one item per line (easy to edit)."""
    body = ',\n'.join('  ' + fmt(x) for x in items)
    return '{\n "about": %s,\n "%s": [\n%s\n ]\n}\n' % (json.dumps(about, indent=2).replace('\n', '\n '), key, body)


def dictionary(t):
    out = []
    for w in t.words():
        out.append({'offset': w['offset'], 'word': w['text'], 'class': w['cls'],
                    'ending': None if w['suffix'] is None else ENDINGS[w['suffix']],
                    'synonym': w['synonym'], 'typed': w['group'] == 1})
    return out


def commands(t):
    def text(x):
        return t.word(x & 0xFFF) if x & 0xFFF else ''
    return [{'id': i, 'words': [text(x) for x in w], 'flags': [x >> 12 for x in w]}
            for i, (_, w) in enumerate(t.verbs(), 1)]


def message_names(mem, t):
    """Address -> name of every entry into the message area: the labels, the
    targets of jumps and calls, and the relation messages at MsgInThe + 4k."""
    n = {a: v for a, v in names().items() if T.MSG_START <= a < T.MSG_END}
    for a in t.starts():
        for p, q, kind, v in t.parse(a)[0]:
            if kind == 'code' and v[0] in (2, 11):
                n.setdefault(p + 1 + v[1], 'L%04X' % (p + 1 + v[1]))
    for a in range(L.MsgInThe, L.MsgThere - 2, 4):
        n.setdefault(a, 'L%04X' % a)
    return n


def word_markup(t, off, mode):
    """A word item as markup, normalised: only what changes the print is kept."""
    w = t.word_at(off)
    text = w['text']
    if mode in (2, 3, 6):
        mode = 0                        # the endings are separate items
    ending = None if w['suffix'] is None else ENDINGS[w['suffix']]
    if mode == 7:
        return text.capitalize() + ('(%s)' % ending if ending is not None else '')
    if ending is None or mode == 5:
        return text
    return '%s(%s)%s' % (text, ending, MODES[mode])


def messages(mem, t):
    """name -> markup, in address order. A message runs to its end or to the next
    name (then it ends with a goto to it)."""
    n = message_names(mem, t)
    out, p, name, items = {}, T.MSG_START, None, []
    while p < T.MSG_END:
        if p in n:
            if name is not None:
                items.append('{goto %s}' % n[p])
                out[name] = ' '.join(items)
            name, items = n[p], []
        kind, v, q = t.step(p)
        if kind == 'ch':
            if items and items[-1].startswith('`') and items[-1].endswith('`') and p not in n:
                items[-1] = items[-1][:-1] + v + '`'
            else:
                items.append('`%s`' % v)
        elif kind == 'cw':
            items.append(word_markup(t, v[1], 5))
        elif kind == 'tok':
            if v[1]:                    # (a word 0 prints nothing; its ending stays)
                items.append(word_markup(t, v[1], v[0]))
            if v[0] in (2, 3, 6):
                items.append(ENDS[v[0]])
        elif v[0] in (0x14, 0x15, 0x16):
            items.append(ENDS[v[0]])
        elif v[0] in (2, 11):
            items.append('{%s %s}' % ('goto' if v[0] == 2 else 'call', n[p + 1 + v[1]]))
        else:
            items.append('{%s}' % CODES[v[0]])
        if name == 'MsgSubjIsIn' and p == L.MsgSubjIsIn + 1:
            items[-1] = '{preposition}'       # DescribeLocation and VerbLook rewrite it
        p = q
        if items[-1].startswith('{end') or items[-1].startswith('{goto'):
            out[name], name = ' '.join(items), None
    return out


def expected(mem, t, n, a):
    """The items of the message at `a` as the original prints them, normalised as
    text.py compiles markup: ('text', s) runs, ('word', offset, mode) with the mode
    only where it matters, ('code', n), ('call'|'goto', name), ('end', d)."""
    from hobbit import text
    out, p = [], a
    while True:
        if p != a and p in n:
            out.append(('goto', n[p]))
            return out
        kind, v, q = t.step(p)
        if kind == 'ch':
            if out and out[-1][0] == 'text':
                out[-1] = ('text', out[-1][1] + v)
            else:
                out.append(('text', v))
        elif kind in ('cw', 'tok'):
            mode = 5 if kind == 'cw' else v[0]
            if p == L.MsgSubjIsIn + 1:
                out.append(('preposition',))
            elif v[1]:
                out.append(('word',) + text.canonical(v[1], 0 if mode in (2, 3, 6) else mode))
            if kind == 'tok' and mode in (2, 3, 6):
                out.append(('end', mode << 4))
                return out
        elif v[0] in (0x14, 0x15, 0x16):
            out.append(('end', {0x14: 0x60, 0x15: 0x30, 0x16: 0x20}[v[0]]))
            return out
        elif v[0] in (2, 11):
            out.append(('goto' if v[0] == 2 else 'call', n[p + 1 + v[1]]))
            if v[0] == 2:
                return out
        else:
            out.append(('code', {10: 5, 15: 5, 18: 5}.get(v[0], v[0])))
        p = q


def check(mem):
    """The files in game/assets/ against the original (raises on a difference)."""
    from hobbit import terminal, text, words
    t = T.Text(bytes(mem))
    by_offset = {w['offset']: w for w in t.words()}
    for letter in range(1, 27):
        first = word(mem, L.Vocabulary + 2 * letter)
        got = words.FIRST.get(letter)
        if (got or 0) != first:
            raise AssertionError('dictionary: the first word of %s is $%03X, the original $%03X'
                                 % (chr(96 + letter), got or 0, first))
    for off, e in words.WORDS.items():
        w = by_offset[off]
        if (e.word, e.cls, e.ending, e.synonym) != (w['text'], w['cls'], None if w['suffix'] is None
                                                    else ENDINGS[w['suffix']], w['synonym']):
            raise AssertionError('dictionary: $%03X %r' % (off, e))
    for i, (_, w) in enumerate(t.verbs(), 1):
        if words.command(i) != w:
            raise AssertionError('commands: %d is %s, the original %s'
                                 % (i, [hex(x) for x in words.command(i)], [hex(x) for x in w]))
    n = message_names(mem, t)
    if set(n.values()) != set(text.MESSAGES):
        raise AssertionError('messages: names differ: %s' % (set(n.values()) ^ set(text.MESSAGES)))
    for a, name in n.items():
        if text.MESSAGES[name] != expected(mem, t, n, a):
            raise AssertionError('messages: %s is %r,\n  the original %r'
                                 % (name, text.MESSAGES[name], expected(mem, t, n, a)))
    font = bytes(mem[L.Font:L.Font + 768])
    if b''.join(terminal.FONT) != font:
        raise AssertionError('font.png: the glyphs differ from the original')
    printed = transcript('MsgDead')
    if printed != ['You are dead.']:
        raise AssertionError('the printer copy of MsgDead is %r' % printed)


def transcript(name):
    """The lines a message sends to the printer, from the start state with the
    windows set up as RestartGame does and PRINT on."""
    from hobbit import assets as game_assets, terminal, text, words
    from hobbit.state import Printed
    s = game_assets.state()
    words.clear_screen(s)
    s.vars.printer_on = s.vars.action_perform = s.vars.messages_visible = s.vars.capital_next = 1
    s.vars.subj_is_in = 0
    t = s.terminal
    t.story_column, t.story_cursor, t.story_pixel = terminal.STORY_COLUMNS, 0, 1
    t.input_column, t.input_glyph = terminal.INPUT_COLUMNS, ord('+')
    return [e.text for e in text.print_message(s, name) if isinstance(e, Printed)]


def write(mem, force):
    t = T.Text(bytes(mem))
    if writing('dictionary.json', force):
        with open(os.path.join(OUT, 'dictionary.json'), 'w') as f:
            f.write(dump_lines(DICTIONARY_ABOUT, 'words', dictionary(t), json.dumps))
    if writing('commands.json', force):
        with open(os.path.join(OUT, 'commands.json'), 'w') as f:
            f.write(dump_lines(COMMANDS_ABOUT, 'commands', commands(t), json.dumps))
    if writing('messages.json', force):
        msgs = messages(mem, t)
        body = ',\n'.join('  %s: %s' % (json.dumps(k), json.dumps(v)) for k, v in msgs.items())
        with open(os.path.join(OUT, 'messages.json'), 'w') as f:
            f.write('{\n "about": %s,\n "messages": {\n%s\n }\n}\n'
                    % (json.dumps(MESSAGES_ABOUT, indent=2).replace('\n', '\n '), body))
    if writing('font.png', force):
        glyphs = [(bytes(mem[L.Font + 8 * k:L.Font + 8 * k + 8]), 0, False) for k in range(96)]
        png.write_cells(os.path.join(OUT, 'font.png'), FONT_COLS, FONT_ROWS, glyphs)
    check(mem)


if __name__ == '__main__':
    from assets import image
    check(image())
    print('text assets match the original')
