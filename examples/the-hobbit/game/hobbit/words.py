"""The dictionary, typed words and the command table (stage 3: keys.py;
src/keys.asm, src/dictionary.asm, docs/05-parser.md), and the helpers of the
line editor.

A word is its offset in the dictionary (game/assets/dictionary.json); a word
token is its class in bits 12-15 and the offset in bits 0-11, as the parser
stores it. The typed line is the editor's buffer (128 bytes and the carriage
return after them, a bytearray) and positions in it."""
from dataclasses import dataclass

from . import assets, terminal
from .state import ReadKey

CR, BACKSPACE = 0x0D, 0x08
TOKEN_END, TOKEN_UNKNOWN = 0xC000, 0xD000
PUNCTUATION = {ord('.'): 0xB000, ord(','): 0xA000, ord('"'): 0x9000}   # then, and, quote
CURSOR_LETTERS = {0x09: 'E', 0x08: 'W', 0x0A: 'S', 0x5B: 'N'}         # right, left, down, up
WAIT = b'WAIT'


@dataclass(frozen=True)
class Word:
    offset: int
    word: str               # the letters, a-z
    cls: int                # the parser's class (the token's high nibble)
    ending: str | None      # what a verb adds ("\b" a back-space), None for none
    synonym: int | None     # the offset of the word it stands for when typed
    typed: bool             # the parser looks it up


def _dictionary():
    """dictionary.json, checked: offsets in order, letters a-z, synonyms to
    words, endings of at most 4 characters (the original's record)."""
    out, last = {}, -1
    for x in assets.load_json('dictionary.json')['words']:
        w = Word(x['offset'], x['word'], x['class'], x['ending'], x['synonym'], x['typed'])
        if w.offset <= last or not w.word.isalpha() or not w.word.islower() or not w.word.isascii():
            raise ValueError('dictionary.json: word %r at %d (offsets rise, letters a-z)' % (w.word, w.offset))
        if w.ending is not None and len(w.ending) > 4:
            raise ValueError('dictionary.json: %r: an ending has at most 4 characters' % w.word)
        out[w.offset], last = w, w.offset
    for w in out.values():
        if w.synonym is not None and w.synonym not in out:
            raise ValueError('dictionary.json: %r stands for %d, not a word' % (w.word, w.synonym))
    return out


WORDS = _dictionary()


def _blocks():
    """The parser's words by first letter: the typed words from the first that
    starts with the letter, while they start with it (the original's index)."""
    order, blocks = list(WORDS.values()), {}
    for i, w in enumerate(order):
        letter = ord(w.word[0]) - 96
        if w.typed and letter not in blocks:
            block = []
            for x in order[i:]:
                if not x.typed or x.word[0] != w.word[0]:
                    break
                block.append(x)
            blocks[letter] = block
    return blocks


BLOCKS = _blocks()
FIRST = {letter: b[0].offset for letter, b in BLOCKS.items()}


def _commands():
    """commands.json: record id -> its 4 word codes (offset | flags << 12)."""
    first = {}
    for w in WORDS.values():
        first.setdefault(w.word, w.offset)
    out = {}
    for c in assets.load_json('commands.json')['commands']:
        if len(c['words']) != 4 or len(c['flags']) != 4 or not all(0 <= f < 16 for f in c['flags']):
            raise ValueError('commands.json: command %d needs 4 words and 4 flags 0-15' % c['id'])
        try:
            out[c['id']] = [(first[w] if w else 0) | f << 12 for w, f in zip(c['words'], c['flags'])]
        except KeyError as e:
            raise ValueError('commands.json: command %d: %s is not in the dictionary' % (c['id'], e)) from None
    if sorted(out) != list(range(1, len(out) + 1)):
        raise ValueError('commands.json: the ids must run from 1')
    return out


COMMANDS = _commands()


def command(id):
    """The command record `id` (1-59): its verb, two prepositions and the word
    the echo prints first, as word codes with their flag nibbles.
    (stage 3: CommandRecordAddr)"""
    return COMMANDS[id]


def compare_words(s, typed, entry):
    """True when the typed letters and a dictionary word agree as far as the
    shorter goes (one is a prefix of the other). (stage 3: CompareWords)"""
    n = min(len(typed), len(entry))
    return typed[:n] == entry[:n]


def read_typed_word(s, line, pos):
    """The token of the next word of the typed line from `pos`, spaces
    skipped: TOKEN_END at the carriage return, the tokens of . , and ", the
    dictionary word (a synonym gives the word it stands for), or
    TOKEN_UNKNOWN. Returns (token, the position after it, where it starts).
    (stage 3: ReadTypedWord)"""
    while line[pos] == 0x20:
        pos += 1
    start, c = pos, line[pos]
    if c == CR:
        return TOKEN_END, pos, start
    if c in PUNCTUATION:
        return PUNCTUATION[c], pos + 1, start
    if c < 0x40:
        raise ValueError('typed character %d: the editor lets none in' % c)   # (the asm reads stale letters)
    while line[pos] >= 0x40:            # @ A-Z [ \ ] ^ _ and lower case: 5 bits a letter
        pos += 1
    typed = ''.join(chr(0x60 | b & 0x1F) for b in line[start:pos])
    w = _lookup(s, typed)
    if w is None:
        return TOKEN_UNKNOWN, pos, start
    if w.synonym is not None:
        w = WORDS[w.synonym]
    return w.cls << 12 | w.offset, pos, start


def _lookup(s, typed):
    """The dictionary word a typed word means, or None. The words of its first
    letter in order: the first the typed word is a prefix of; a typed word
    longer than a word of 4 or more letters it starts with means that word,
    unless the next word starts with the typed word too (then the walk goes on
    from it)."""
    block = BLOCKS.get(ord(typed[0]) - 96, [])
    for i, w in enumerate(block):
        if compare_words(s, typed, w.word):
            if len(w.word) >= len(typed):
                return w
            if len(w.word) >= 4 and (i + 1 == len(block) or not compare_words(s, typed, block[i + 1].word)):
                return w
    return None


def pack_command_flags(s, record):
    """The command record's flag nibbles into s.vars.command_flags (StateB71D,
    StateB71E); returns StateB71D. (stage 3: PackCommandFlags)"""
    f = [x >> 12 for x in record]
    s.vars.command_flags = (f[1] << 4 | f[0], f[3] << 4 | f[2])
    return s.vars.command_flags[0]


def match_word(s, token, word):
    """True when a phrase word and a record word are the same word (the class
    nibble ignored); a phrase word 0 matches anything. (stage 3: MatchWord)"""
    return token == 0 or token & 0xFFF == word & 0xFFF


def match_command_record(s, record, phrase):
    """Match three record words (a command: verb and prepositions; a name:
    noun and adjectives) against three phrase words: the first, then the other
    two in order or swapped. Returns (matched, swapped, the first matched).
    (stage 3: MatchCommandRecord)"""
    if not match_word(s, phrase[0], record[0]):
        return False, False, False
    if match_word(s, phrase[1], record[1]) and match_word(s, phrase[2], record[2]):
        return True, False, True
    if match_word(s, phrase[1], record[2]) and match_word(s, phrase[2], record[1]):
        return True, True, True
    return False, False, True


def cursor_key_to_word(s, key, line, pos):
    """The first key of a line: a cursor key becomes its direction letter (up
    N, down S, right E, left W), echoed and stored with a carriage return
    after it, and CR is the key; another key stays. Returns (key, position).
    (stage 3: CursorKeyToWord)"""
    if key not in CURSOR_LETTERS:
        return key, pos
    letter = ord(CURSOR_LETTERS[key])
    line[pos] = letter
    yield from terminal.put_char(s, letter)
    line[pos + 1] = CR                  # not echoed here
    return CR, pos + 2


def l6e7a(s):
    """"@" on an empty line: the previous line again (the prompt rubbed out;
    True), unless a question waits for its answer (the key is ignored; False).
    (stage 3: L6E7A)"""
    if s.vars.awaiting_answer:
        return False
    yield from terminal.put_char(s, BACKSPACE)
    yield from terminal.put_char(s, BACKSPACE)
    return True


def erase_input_line(s, pos):
    """Rub out the `pos` characters typed; returns the new position, 0.
    (stage 3: EraseInputLine)"""
    for _ in range(pos):
        yield from terminal.put_char(s, BACKSPACE)
    return 0


def wait_key(s, line, pos):
    """The next key (ReadKey). When the player has been idle (None), the typed
    line is rubbed out and WAIT typed instead, with CR as the key. Returns
    (key, position). (stage 3: WaitKey)"""
    key = yield ReadKey()
    if key is not None:
        return key, pos
    pos = yield from erase_input_line(s, pos)
    for c in WAIT:
        line[pos] = c
        pos += 1
        yield from terminal.put_char(s, c)
    return CR, pos


def clear_screen(s):
    """White border, the screen cleared to black on white. (stage 3: ClearScreen;
    its fill also sets the byte after the attributes, outside the screen)"""
    s.screen.border = 7
    s.screen.cls(0x38)
