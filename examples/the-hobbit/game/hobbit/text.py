"""The messages and the words they print (stage 3: printer.py and
PrintCommandSentence of keys.py; src/printer.asm, docs/05-text-and-screen.md).

A message (game/assets/messages.json, by its stage 3 name) is a list of
items: dictionary words, literal text, the names and words the game fills in,
calls and jumps into other messages, and an ending. One message serves every
actor: "You are dead." and "Thorin is dead." are the same message, the verbs
taking their endings when the subject is not the player. The names and words
a caller supplies are `args`, a list: the code that needs one pops it from
the end (where the original pushes them on the stack before the call)."""
import re

from . import assets, terminal, words, world
from .terminal import CR, new_line, put_char

NO_ACTOR = 0xFF
NO_OBJECT = 0xFF
PLAYER = 0
WORD_YOU = 0x07A8           # the player's name ("you", with bit 15: a proper name)
WORD_IS, WORD_ARE = 0x039B, 0x0065
WORD_HIS, WORD_YOUR = 0x0990, 0x0BEA
WORD_SOMEONE = 0x0AE3
WORD_CANNOT = 0x00EE
WORD_SOMEWHERE = 0x0AEA
CMD_FIRST_OTHER = 0x0B      # command ids 1-10 are the moves
CMDF_NOUN2, CMDF_NOUN1, CMDF_SILENT, CMDF_PREP1_BEFORE = 2, 3, 4, 5     # StateB71D bits
CMDG_PREP2_BEFORE = 7       # StateB71E bit

# The article of a noun by bits 12-14 of its phrase code (ArticleTable), and in
# the input window and the echo of a command (ArticleTableInput: "the" or
# "some"); codes 4-7 there read on into the common words: a, and, are, at (quirk).
ARTICLES = (0x069F, 0x0040, 0x0058, 0x0603, 0x069F, 0x069F, 0x069F, 0x0603)
ARTICLES_INPUT = (0x069F, 0x069F, 0x069F, 0x0603, 0x0040, 0x005B, 0x0065, 0x0070)

CODES = {'thing': 0, 'word': 1, 'weapon': 3, 'the_word': 4, 'nop': 5, 'subj': 6, 'obj1': 7,
         'bs': 8, 'obj2': 9, 'his_subj': 12, 'nl': 13, 'his_obj1': 14, 'subj_is': 16,
         'obj1_is': 17, 'arg_is': 19}
ENDS = {'end': 0x20, 'end nl': 0x60, 'end .': 0x30}      # the original's mode bits: 6 nl, 4 full stop
CONDITIONS = {None: 0, 'obj1': 1, 'always': 4}            # print modes of a word with an ending
_ITEM = re.compile(r'`([^`]*)`|\{([^}]*)\}|([A-Za-z]+)(?:\(([^)]*)\))?(?::(\w+))?|(\S+)')


# ---- the dictionary words as messages name them ---------------------------

def _first():
    letters, exact = {}, {}
    for w in words.WORDS.values():
        letters.setdefault(w.word, w.offset)
        exact.setdefault((w.word, w.ending), w.offset)
    return letters, exact


BY_LETTERS, BY_TEXT = _first()


def canonical(offset, mode):
    """A message word (offset, print mode) as markup gives it back: the first
    word with the same letters (and the same ending where one is printed),
    mode 5 (never an ending) where the mode does not matter."""
    w = words.WORDS[offset]
    if mode == 7:
        return BY_TEXT[(w.word, w.ending)], 7
    if w.ending is None or mode == 5:
        return BY_LETTERS[w.word], 5
    return BY_TEXT[(w.word, w.ending)], mode


def compile_markup(name, markup):
    """A message's markup as items: ('text', s), ('word', offset, mode),
    ('code', n), ('preposition',), ('call'|'goto', name), ('end', bits)."""
    items = []
    for m in _ITEM.finditer(markup):
        lit, code, letters, ending, cond, junk = m.groups()
        if junk is not None:
            raise ValueError('messages.json: %s: %r is not an item' % (name, junk))
        if lit is not None:
            if items and items[-1][0] == 'text':
                items[-1] = ('text', items[-1][1] + lit)
            else:
                items.append(('text', lit))
        elif code is not None:
            code = ' '.join(code.split())
            if code in CODES:
                items.append(('code', CODES[code]))
            elif code in ENDS:
                items.append(('end', ENDS[code]))
            elif code == 'preposition':
                items.append(('preposition',))
            elif code.split(' ')[0] in ('goto', 'call') and len(code.split(' ')) == 2:
                items.append(tuple(code.split(' ')))
            else:
                raise ValueError('messages.json: %s: {%s} is not a code' % (name, code))
        else:
            key = (letters.lower(), ending)
            try:
                if letters[0].isupper():
                    w = (BY_TEXT[key], 7)
                elif ending is None:
                    w = (BY_LETTERS[key[0]], 5)
                else:
                    w = (BY_TEXT[key], CONDITIONS[cond])
            except KeyError:
                raise ValueError('messages.json: %s: %s is not a dictionary word (with that ending), or '
                                 ':%s not obj1/always' % (name, m.group(0), cond)) from None
            if cond is not None and (ending is None or letters[0].isupper()):
                raise ValueError('messages.json: %s: %s: a condition needs a lower-case word with '
                                 'its ending' % (name, m.group(0)))
            items.append(('word',) + w)
    return items


def _messages():
    """messages.json, compiled and checked: every message ends (an end or a
    goto, last), calls and gotos name messages."""
    out = {name: compile_markup(name, m) for name, m in assets.load_json('messages.json')['messages'].items()}
    for name, items in out.items():
        for i, it in enumerate(items):
            last = it[0] in ('end', 'goto')
            if last != (i == len(items) - 1):
                raise ValueError('messages.json: %s: the message must end with {end...} or {goto ...}, '
                                 'once' % name)
            if it[0] in ('call', 'goto') and it[1] not in out:
                raise ValueError('messages.json: %s: no message %s' % (name, it[1]))
    return out


MESSAGES = _messages()


# ---- the interpreter -----------------------------------------------------

def print_message(s, name, args=None):
    """Print the message `name` in the story window (in the input window while
    s.vars.raw_output). During a command's test pass (action_perform 0) a
    message refuses the command: action_allowed becomes 0; it is printed (or
    not) as any text then. (stage 3: PrintMessage)"""
    if not s.vars.action_perform:
        s.vars.action_allowed = 0
    yield from _run(s, name, [] if args is None else args)


def print_parser_message(s, name, args=None):
    """The parser's print_message: while an order is parsed (input_from_order)
    the message refuses the command it would perform. (stage 3: PrintParserMessage)"""
    if s.vars.input_from_order:
        s.vars.action_perform = 0
    yield from print_message(s, name, args)


def print_cannot_do_that(s):
    """"I cannot do that." (stage 3: PrintCannotDoThat)"""
    yield from print_message(s, 'MsgICannotDoThat')


def _run(s, name, args):
    """The items of message `name`, on through its gotos, to its ending.
    (stage 3: PrintMessageAt)"""
    items, i = MESSAGES[name], 0
    while True:
        it = items[i]
        kind = it[0]
        if kind == 'text':
            for c in it[1]:
                yield from print_message_char(s, ord(c))
        elif kind == 'word':
            yield from print_word(s, it[1], it[2])
        elif kind == 'code':
            yield from CONTROL[it[1]](s, args)
        elif kind == 'preposition':
            # the word DescribeLocation (the location's in, on, at...) or VerbLook
            # (none) wrote into this message last (self-modifying data)
            yield from print_word(s, s.vars.subj_is_in, 0)
        elif kind == 'call':
            yield from _run(s, it[1], args)
        elif kind == 'goto':
            items, i = MESSAGES[it[1]], 0
            continue
        else:
            yield from _end(s, it[1])
            return
        i += 1


def _end(s, bits):
    """A message's ending: a new line (bit 6), or a full stop and a new line
    (bit 4), or nothing. (stage 3: EndMessage)"""
    if bits & 0x40:
        yield from new_line(s)
    elif bits & 0x10:
        yield from put_char(s, ord('.'))
        yield from new_line(s)


def print_message_char(s, ch):
    """A character of a message; a new line (code 13) leaves no capital
    after it. (stage 3: PrintMessageChar)"""
    yield from put_char(s, ch)
    if ch == CR:
        s.vars.capital_next = 0


def print_word(s, word, mode):
    """Print dictionary word `word` (0: nothing) in print mode `mode`: its
    ending when the mode asks (0, 2, 3, 6, 7: the subject is not the player;
    1: the first object is not the player; 4: always; 5: never), after a space
    unless the story line is empty, on a new line when it does not fit; mode 7
    with a capital. (stage 3: PrintWord)"""
    if word == 0:
        return
    w = words.WORDS[word]
    if mode == 5:
        ending = False
    elif mode == 4:
        ending = True
    elif mode == 1:
        ending = s.vars.first_object != PLAYER
    else:
        ending = s.vars.subject != PLAYER
    text = w.word + (w.ending if ending and w.ending is not None else '')
    t, raw = s.terminal, s.vars.raw_output
    if raw or t.story_last_char:
        yield from put_char(s, 0x20)
    if (t.input_column if raw else t.story_column) < len(text):     # (a back-space counts)
        capital = s.vars.capital_next
        yield from new_line(s)
        s.vars.capital_next = capital
    if mode == 7:
        s.vars.capital_next = 1
    for c in text:
        yield from put_char(s, ord(c))


def print_code(s, code):
    """Print a word code (offset and the print mode in bits 12-15)."""
    yield from print_word(s, code & 0xFFF, code >> 12)


# ---- names and articles --------------------------------------------------

def print_article(s, code, echo=False):
    """The article of the noun `code`: "the", "a", "an" or "some" by its bits
    12-14 ("the" or "some" in the input window and in the echo of a command);
    a proper name (bit 15) has none but a capital, and "you" not even that.
    (stage 3: PrintArticle)"""
    if code & 0x8000:
        if code & 0x0FFF == WORD_YOU:
            return
        s.vars.capital_next = 1
        return
    table = ARTICLES_INPUT if echo or s.vars.raw_output else ARTICLES
    yield from print_code(s, table[code >> 12 & 7])


def print_noun_word(s, code, echo=False):
    """The noun `code` without its flags, its article first unless
    s.vars.phrase_mode is 0. (stage 3: PrintNounWord)"""
    if s.vars.phrase_mode:
        yield from print_article(s, code, echo)
    yield from print_word(s, code & 0xFFF, 0)


def print_name_phrase(s, names, echo=False):
    """A name (noun, adjective, adjective): with phrase_mode 0 the article, the
    adjectives and the noun ("a short strong sword"); otherwise the article and
    the noun ("the sword"). (stage 3: PrintNamePhrase)"""
    if s.vars.phrase_mode == 0:
        yield from print_article(s, names[0], echo)
        yield from print_code(s, names[1])
        yield from print_code(s, names[2])
    if names[0]:
        yield from print_noun_word(s, names[0], echo)


def print_actor_name(s, id, echo=False):
    """The name of thing `id` ("you" for the player, "someone" for NO_ACTOR).
    (stage 3: PrintActorName)"""
    if id == NO_ACTOR:
        yield from print_word(s, WORD_SOMEONE, 0)
    else:
        yield from print_name_phrase(s, world.thing(s, id).names, echo)


def _object_name(s, id, location, echo):
    """Thing `id`, or location `id` when `location`. (stage 3: PrintSecondObjectName_0)"""
    yield from print_name_phrase(s, s.locations[id].names if location else world.thing(s, id).names, echo)


def print_first_object_name(s, echo=False):
    """The first object's name as phrase_mode says. (stage 3: PrintFirstObjectNameAsIs)"""
    yield from _object_name(s, s.vars.first_object, s.vars.noun1_kind, echo)


def print_second_object_name(s, echo=False):
    """The second object's name as phrase_mode says. (stage 3: PrintSecondObjectNameAsIs)"""
    yield from _object_name(s, s.vars.second_object, s.vars.noun2_kind, echo)


def print_subject_name(s):
    """Code 6: the subject's name ("you", "Thorin"). (stage 3: PrintSubjectName)"""
    s.vars.phrase_mode = 0
    yield from print_actor_name(s, s.vars.subject)


def _name_is(s, id, mode):
    """A name and "is", or "are" after the player's ("you are").
    (stage 3: PrintActorIs)"""
    s.vars.phrase_mode = mode
    yield from print_actor_name(s, id)
    yield from print_word(s, WORD_ARE if id == PLAYER else WORD_IS, 0)


def _his(s, id):
    """"his", or "your" for the player. (stage 3: HisOrYour)"""
    yield from print_word(s, WORD_YOUR if id == PLAYER else WORD_HIS, 0)


def _stacked_name(s, args):
    """Code 0: a name the caller passed (a names list; 0 or None: nothing),
    without an article. (stage 3: PrintStackedName)"""
    s.vars.phrase_mode = 0
    names = args.pop()
    if names:
        yield from print_name_phrase(s, names)


def _stacked_word_article(s, args):
    """Code 4: a word code the caller passed, with its article.
    (stage 3: PrintStackedWordArticle)"""
    code = args.pop()
    s.vars.phrase_mode = 1
    yield from print_noun_word(s, code)


def _first_object(s, args):
    s.vars.phrase_mode = 1
    yield from print_first_object_name(s)


def _second_object(s, args):
    s.vars.phrase_mode = 1
    yield from print_second_object_name(s)


def _nothing(s, args):
    return
    yield


# Control codes (ControlCodeTable); 2 and 11 (jump, call) and the endings are items.
CONTROL = {
    0: _stacked_name,
    1: lambda s, args: print_code(s, args.pop()),                       # PrintStackedWord
    3: lambda s, args: print_code(s, s.vars.weapon_name),               # L738D (never run)
    4: _stacked_word_article,
    5: _nothing,                                                        # 10, 15, 18 too
    6: lambda s, args: print_subject_name(s),
    7: _first_object,                                                   # PrintFirstObjectName
    8: lambda s, args: put_char(s, 0x08),                               # L73BD (never run)
    9: _second_object,                                                  # PrintSecondObjectName
    12: lambda s, args: _his(s, s.vars.subject),                        # L73F9
    13: lambda s, args: print_message_char(s, CR),
    14: lambda s, args: _his(s, s.vars.first_object),                   # HisYourFirstObject
    16: lambda s, args: _name_is(s, s.vars.subject, 0),                 # PrintSubjectIs
    17: lambda s, args: _name_is(s, s.vars.first_object, 1),            # L7425 (never run)
    19: lambda s, args: _name_is(s, args.pop(), 1),                     # PrintNameIsFromStack
}


# ---- the echo of a command ----------------------------------------------

def print_command_sentence(s):
    """The command as a sentence: "You take the short strong sword." in the
    story window, or "Gandalf cannot take the chest." in the input window when
    refused (raw_output is left so): the subject, "cannot", the record's first
    word, the verb ("somewhere" for a move in the dark), the first noun with
    the prepositions the flags put before it, the other prepositions and the
    second noun, a full stop. Silent commands print nothing.
    (stage 3: PrintCommandSentence)"""
    from . import engine            # (another slice's module; engine imports this one)
    v = s.vars
    v.phrase_mode = 0
    allowed = v.action_allowed
    v.raw_output = 0 if allowed else 1
    record = words.command(v.command)
    if allowed and v.subject == PLAYER:
        yield from new_line(s)
    flags = words.pack_command_flags(s, record)
    if flags >> CMDF_SILENT & 1:
        return
    yield from print_actor_name(s, v.subject, echo=True)
    if not allowed:
        yield from print_word(s, WORD_CANNOT, 0)
    yield from print_word(s, record[3] & 0xFFF, 0)
    if engine.check_dark(s) and v.command < CMD_FIRST_OTHER:
        yield from print_word(s, WORD_SOMEWHERE, 0)
    else:
        yield from print_word(s, record[0] & 0xFFF, 0)
    rest = iter(record[1:])             # the prepositions, in the order they are printed
    prep2_before = v.command_flags[1] >> CMDG_PREP2_BEFORE & 1
    if flags >> CMDF_NOUN1 & 1:
        if flags >> CMDF_PREP1_BEFORE & 1:
            yield from print_word(s, next(rest) & 0xFFF, 0)     # "off", "out"
        if prep2_before:
            yield from print_word(s, next(rest) & 0xFFF, 0)     # "of"
        yield from print_first_object_name(s, echo=True)
    if v.second_object != NO_OBJECT and flags >> CMDF_NOUN2 & 1:
        if not flags >> CMDF_PREP1_BEFORE & 1:
            yield from print_word(s, next(rest) & 0xFFF, 0)     # "to", "in"
        if not prep2_before:
            yield from print_word(s, next(rest) & 0xFFF, 0)
        yield from print_second_object_name(s, echo=True)
    yield from put_char(s, ord('.'))
    yield from new_line(s)


def start_perform(s):
    """Perform the command now (action_perform 1, action_allowed 0) and echo it,
    unless it is a stored order. (stage 3: StartPerform)"""
    s.vars.action_allowed = 0
    s.vars.action_perform = 1
    if not s.vars.input_from_order:
        yield from print_command_sentence(s)
