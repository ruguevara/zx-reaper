"""The parser (stage 3: parser.py; src/parser.asm, docs/05-parser.md): the
word list of a typed line into phrase records, the records run as commands
(the command table, the objects the noun phrases mean, the questions "Which
...?" and "... what ?"), and the orders given with SAY TO.

A phrase record is 12 words: [0] the command word (bit 15 ALL typed, bit 14
an EXCEPT record), [1] the second command word (an adverb, go or run), [2-6]
block A (two prepositions, the noun, two adjectives) and [7-11] block B; the
noun phrases are [4-6] and [9-11]. The records of a line are a working list,
the phrase stack (`Stack`), kept in s.scratch['phrases'] from parse_line to
run_sentences: record 0 is the top (the record a question waits on,
s.question), newer records follow. The parse is a chain of word-class
handlers (`_Parser`: each step returns the next one, or the result). The work
area of the match (stage 3 RecWork to RecPtr3) is a `Scan` in
s.scratch['scan'], kept between calls as the original keeps it: an ALL scan
goes on from where it stopped, even after a character's order used it.

Two values the original keeps between lines are not in the state yet:
s.scratch['it'], the last first noun phrase (PhraseBuffer, what IT means),
and s.scratch['saved_command'], the command the last match found
(SavedCommandId, read by the Bard's order timer)."""
import inspect
from dataclasses import dataclass, field

from . import text, words, world
from .constants import TOKEN_AND, TOKEN_END, TOKEN_THEN
from .state import Phrase

TOKEN_DIRECTION, TOKEN_VERB, TOKEN_NOUN = 0x20, 0x30, 0x50
TOKEN_ADJECTIVE, TOKEN_PREPOSITION, TOKEN_ARTICLE = 0x60, 0x70, 0x80
# the parser flags (stage 3 register E)
PF_PLAIN_VERB = 0x01        # clear for go and run, which look ahead for a direction
PF_NEED_COMMAND = 0x02      # the record has no command word yet
PF_DIRECTION_OK = 0x04      # the second command word is free
PF_NO_SAVED_POS = 0x08      # clear once AND has saved a position
PF_ARTICLE_OK = 0x10        # an article may start the phrase
PF_BLOCK_A_FREE, PF_BLOCK_B_FREE = 0x40, 0x80
RECF_ALL, RECF_EXCEPT = 0x8000, 0x4000      # bits of a record's command word
BLOCK_A, BLOCK_B = 2, 7                     # word indices of the blocks
REC_PHRASE_A, REC_PHRASE_B = 0x08, 0x12     # byte offsets of the noun phrases (as AwaitingAnswer keeps them)
ALL_STATE_ALL, ALL_STATE_EXCEPT = 1, 2
MAX_PREPOSITIONS = 3
ORDER_PENDING = 0xFF        # the owner of an order slot not yet given to a character
CMDF_TAKES_NOUNS = 0x0C     # StateB71D bits 2-3
NO_OBJECT, END = world.NO_OBJECT, world.END
STRAY_WORD = 0x7948         # the "word" ExplainNoun2Failure asks about: the address RecBuf2 (quirk)
ACTIONS = ('parse_adverb', 'parse_in', 'parse_direction', 'parse_verb', 'parse_go_verb', 'parse_noun',
           'parse_adjective', 'parse_preposition', 'parse_article', 'special', 'parse_and',
           'parse_then', 'parse_end')     # ActionTable, by word class


class Stack(dict):
    """The phrase stack: record k is k records below the top. Record -1 is
    what lies above the top in the original, its location table: it reads as
    a record that is not an EXCEPT record (its words are taken as 0 here; the
    original would lend them to a record 0 with no command word, which no
    parse leaves). Records not written yet read as zeros (stale in the
    original; the parser clears a record, and the command word of the one
    after it, before using it)."""

    def __missing__(self, k):
        rec = self[k] = [0] * 12
        return rec


@dataclass
class Scan:
    """The work area of matching one record (stage 3 RecWork..RecPtr3)."""
    words: list = field(default_factory=lambda: [0, 0, 0])   # RecWord1-3: the verb, two prepositions
    command: int = 0            # RecPtr3: the command id matched
    all_word: int = 0           # RecWork4: $80 when the record says ALL
    take_first: int = 0         # RecWork5: 1: the first accepted candidate will do
    offsets: list = field(default_factory=lambda: [0, 0])     # RecWork6: phrases 1, 2 in the record
    has1: int = 0               # RecWork: bit 0 phrase 1 has words, bit 1 a candidate was found
    has2: int = 0               # RecWork1: the same for phrase 2
    seen1: int = 0              # RecWork2: candidates for noun 1 the verb applies to
    kept: list = field(default_factory=lambda: [0, 0])        # RecWork3: candidates accepted
    phrase1: list = field(default_factory=lambda: [0, 0, 0])  # RecBuf1: noun, adjective, adjective
    phrase2: list = field(default_factory=lambda: [0, 0, 0])  # RecBuf2
    last: list = field(default_factory=lambda: [0, 0])        # RecWork7, RecWork8: the last accepted
    cursor1: int = -1           # RecPtr1: where the search for noun 1 stands (a things or exits index)
    cursor2: int = -1           # RecPtr2


def scan(s):
    return s.scratch.setdefault('scan', Scan())


# ---------------------------------------------------------------------------
# The parse

def parse_line(s):
    """Parse the typed word list from s.scratch['word_pos'] into phrase records
    (s.scratch['phrases']). Returns True when the records are ready, False
    when the line was refused (a message was printed) or is empty, or a flow
    target ('RestartGame' after QUIT). (stage 3: ParseLine)"""
    stack = s.scratch['phrases'] = Stack()
    if s.vars.awaiting_answer:
        stack[0] = s.question.words         # the answer completes the question's record
    p = _Parser(s, stack)
    return (yield from p.run(lambda: p.parse_line_from(False)))


def print_what(s):
    """"What ?" in the input window. (stage 3: PrintWhat)"""
    s.vars.raw_output = 1
    yield from text.print_message(s, 'MsgWhat')


class _Parser:
    """The parse: its registers (stage 3 IY, E, D, BC and the parser's
    variables) and its steps, the word-class handlers. A step returns the next
    step, or the result of the parse."""

    def __init__(self, s, stack):
        self.s, self.v, self.stack = s, s.vars, stack
        self.k = 0                  # IY: the record being built
        self.e = 0                  # the parser flags (PF_...)
        self.d = 0                  # the class of the word just read
        self.word = 0               # BC: the word just read (its dictionary offset)
        self.slots = [0] * 5        # ActionSlots: two prepositions, the noun, two adjectives
        self.preps = 0              # ActionFlag: prepositions in this record
        self.word_flags = 0         # WordFlags: the class of the word before
        self.token = 0              # InputLinePtr: where the word just read is
        self.saved = None           # ParseAnd: SavedHL, SavedA1, SavedIY, SavedA2
        self.order_pass = []        # BeginOrderPass: the outer parse's registers, PicVar2/3

    def run(self, step):
        while callable(step):
            step = step()
            if inspect.isgenerator(step):
                step = yield from step
        return step

    @property
    def rec(self):
        return self.stack[self.k]

    @property
    def typed(self):
        """The player's own line (errors are reported). (stage 3: TestTypedLine)"""
        return self.v.input_from_order == 0

    # ---- the word loop

    def parse_line_from(self, order):
        """Start a parse: of the typed line, or (order) of the text of an order.
        A question waiting for its answer: the answer goes on as if AND had been
        read. (stage 3: ParseLineFrom)"""
        v = self.v
        v.input_from_order = 1 if order else 0
        v.all_stage = v.parser_word_count = 0
        self.e = 0xFF
        if v.awaiting_answer:
            self.d = TOKEN_AND
            return self.close_record
        self.d = TOKEN_END
        return self.start_phrase_record

    def start_phrase_record(self):
        """A new record: both blocks free, a command word needed (not after
        EXCEPT), the record cleared. (stage 3: StartPhraseRecord)"""
        self.preps = 0
        self.e |= 0xC7
        if self.v.all_stage == ALL_STATE_EXCEPT:
            self.e &= ~PF_NEED_COMMAND & 0xFF
        self.clear_record()
        return self.parse_next_word

    def parse_next_word(self):
        """Clear the phrase slots, allow an article, read on. (stage 3: ParseNextWord)"""
        self.slots = [0] * 5
        self.e |= PF_ARTICLE_OK
        return self.dispatch_word

    def dispatch_word(self):
        """Read the next word and go to the handler of its class. (stage 3: DispatchWord)"""
        cls = self.read_word() >> 4
        if cls >= len(ACTIONS):
            raise ValueError('a word of class %d: the original jumps into the ROM' % cls)
        return getattr(self, ACTIONS[cls])

    def read_word(self):
        """The next token of the word list: self.d its class, self.word the
        word; the class before is kept in self.word_flags. Returns the class.
        (stage 3: ReadWord)"""
        s = self.s
        pos = s.scratch['word_pos']
        self.token, self.word_flags = pos, self.d
        hi, lo = s.parsed_words[pos], s.parsed_words[pos + 1]
        self.d, self.word = hi & 0xF0, (hi & 0x0F) << 8 | lo
        s.scratch['word_pos'] = pos + 2
        return self.d

    def special(self):
        """Class 9: ALL, EXCEPT, IT, the quotes of an order... (stage 3:
        DispatchSpecialWord, in system)"""
        from . import system
        return system.dispatch_special_word(self)

    # ---- the end of a phrase: THEN, AND, the end of the line

    def parse_end(self):
        """Class 12, the end of the line: no more sentences, then as THEN.
        (stage 3: ParseEnd)"""
        self.v.parser_flag = 0
        return self.parse_then

    def parse_then(self):
        """Class 11 (THEN, a full stop): a record with no command word is
        refused with "What ?" in a typed line, unless the line is empty (then
        False, no message) or an older record can lend its command word;
        otherwise the record is closed. (stage 3: ParseThen)"""
        if not self.e & PF_NEED_COMMAND or self.v.parser_word_count:
            return self.close_record
        if self.word_flags == TOKEN_END and self.d == TOKEN_END:
            return self.v.input_from_order == 1         # the line ended at once (TestOrderText)
        if self.typed:
            return self.print_what
        return self.close_record

    def print_what(self):
        yield from print_what(self.s)
        return False

    def close_record(self):
        """Close the record: flag it ALL, count it (not an AND among the EXCEPT
        nouns), go to the next. After AND a new phrase starts; at THEN or the
        end an answer takes what it lacks from the question, then the words are
        inherited. (stage 3: CloseRecord)"""
        v = self.v
        if v.all_stage == ALL_STATE_ALL:
            self.rec[0] |= RECF_ALL
        if v.all_stage != ALL_STATE_EXCEPT or self.d != TOKEN_AND:
            v.parser_word_count = v.parser_word_count + 1 & 0xFF
        self.k = self.find(self.k, 1)
        if self.d == TOKEN_AND:
            return self.start_phrase_record
        if v.awaiting_answer:
            self.complete_answer()
        return self.inherit_words

    def complete_answer(self):
        """The line answers a question: the answer's noun phrase (record 1)
        takes the words it lacks from the phrase of record 0 the question was
        about (offset awaiting_answer): its own phrase when it names the same
        noun or none, else its second phrase if that is empty."""
        offset = self.v.awaiting_answer
        if offset & 1 or offset > REC_PHRASE_B:
            raise ValueError('awaiting_answer %d: the original reads past the record (not reproduced)'
                             % offset)
        asked = self.stack[0][offset // 2:offset // 2 + 3]
        answer = self.stack[1]
        at, complete = 4, True
        if answer[4] and answer[4] != asked[0]:
            at, complete = 9, not answer[9]
        if complete:
            for j in range(3):
                if not answer[at + j]:
                    answer[at + j] = asked[j]

    def inherit_words(self):
        """Oldest to newest (counting from the top of the stack, not from this
        parse's first record: an order's records are not those walked, quirk),
        a record with no command word takes the older one's; newest to oldest,
        an older record with the same command word and no second noun phrase
        takes the newer one's block B. Then True at the end of the line or at
        THEN in a typed line; an order goes on with a new record. (stage 3:
        InheritWords)"""
        stack, end = self.stack, self.k
        count = self.v.parser_word_count
        newer = self.find(-1, 1)
        for _ in range(count - 1 & 0xFF):
            older, newer = newer, self.find(newer, 1)
            if not stack[newer][0] & 0x7FFF:
                self.inherit_record(newer, older)
        older = self.find(end, -1)
        for _ in range(count - 1 & 0xFF):
            newer, older = older, self.find(older, -1)
            o, n = stack[older], stack[newer]
            if not o[9] and o[0] == n[0] and n[BLOCK_B]:
                copy_block(n, o, BLOCK_B)
        self.k = end
        if not self.v.parser_flag or self.typed:
            return True
        return self.start_phrase_record

    def inherit_record(self, k, older):
        """Record k takes the command word and flags (not ALL) of the older
        record. When the record above it has a preposition in block A and this
        parse's last record has block B free (the flags are the parse's, not
        this record's: quirk), its noun phrase moves to phrase B and the older
        block A is copied over ("look in chest and map"). (stage 3: InheritRecord)"""
        r, o = self.stack[k], self.stack[older]
        r[0] = o[0] & 0x7FFF | r[0] & 0xFF00
        if not self.stack[k - 1][BLOCK_A] or not self.e & PF_BLOCK_B_FREE:
            return
        r[9:12] = r[4:7]
        copy_block(o, r, BLOCK_A)

    # ---- the records

    def find(self, k, step):
        """The nearest record from k in steps of `step` (1 newer, -1 older)
        that is not an EXCEPT record. (stage 3: FindNewerRecord, FindOlderRecord)"""
        k += step
        while self.stack[k][0] & RECF_EXCEPT:
            k += step
        return k

    def previous_record(self):
        """Back to the older record; the ALL stage cleared. (stage 3: PreviousRecord)"""
        self.k = self.find(self.k, -1)
        self.v.all_stage = 0

    def clear_record(self):
        """Clear the record and the command word of the one after it. (stage 3: ClearRecord)"""
        self.rec[:] = [0] * 12
        self.stack[self.k + 1][0] = 0

    def store_first_word(self):
        """The word is the record's command word. (stage 3: StoreFirstWord)"""
        self.e &= ~PF_NEED_COMMAND & 0xFF
        self.rec[0] = self.word

    # ---- the word classes

    def parse_direction(self):
        """Class 2 (north, up...): the command by itself while one is needed,
        else the record's second word. (stage 3: ParseDirection)"""
        if self.e & PF_NEED_COMMAND:
            return self.parse_verb_as_command
        self.d = 0
        return self.parse_adverb

    def parse_adverb(self):
        """Class 0: the record's second command word, if still free; else "What ?".
        (stage 3: ParseAdverb)"""
        if not self.e & PF_DIRECTION_OK:
            return self.reject_line
        if self.v.all_stage == ALL_STATE_EXCEPT:
            self.previous_record()          # after the EXCEPT nouns: the main record
        self.e &= ~PF_DIRECTION_OK & 0xFF
        self.rec[1] = self.word
        return self.parse_next_word

    def parse_and(self):
        """Class 10 (and, the comma): skip further ANDs, put the word after them
        back and save the place, then as THEN. (stage 3: ParseAnd)"""
        self.e &= ~PF_NO_SAVED_POS & 0xFF
        d = self.d
        while self.read_word() == TOKEN_AND:
            pass
        self.s.scratch['word_pos'] = self.token
        self.d = d
        self.saved = (self.token, self.e, self.k, self.v.parser_word_count)
        return self.parse_then

    def parse_go_verb(self):
        """Class 4 (go, run): a verb that looks ahead for a direction. (stage 3: ParseGoVerb)"""
        self.e &= ~PF_PLAIN_VERB & 0xFF
        return self.parse_verb_as_command

    def parse_verb_as_command(self):
        """(stage 3: ParseVerbAsCommand)"""
        self.d = TOKEN_VERB
        return self.parse_verb

    def parse_verb(self):
        """Class 3: after an AND that saved its place, in a typed line, a verb
        starts a new command: the place, flags and record come back and the
        phrase before AND closes as at THEN (the verb is read again next parse).
        Else it is the command word. (stage 3: ParseVerb)"""
        if self.e & PF_NO_SAVED_POS or not self.typed:
            return self.store_verb
        pos, self.e, self.k, self.v.parser_word_count = self.saved
        self.s.scratch['word_pos'] = pos
        self.d = TOKEN_THEN
        return self.parse_then

    def store_verb(self):
        """The command word; a second one is refused. (stage 3: StoreVerb)"""
        self.v.all_stage = 0
        if not self.e & PF_NEED_COMMAND:
            return self.reject_line
        if not self.e & PF_PLAIN_VERB:
            return self.parse_go_direction
        return self.store_command_word

    def store_command_word(self):
        """(stage 3: StoreCommandWord)"""
        self.store_first_word()
        return self.parse_next_word

    def parse_go_direction(self):
        """Go or run: when a direction follows (adverbs skipped) it is the
        command word and go or run the second word; else the verb is stored and
        the word read again later. (stage 3: ParseGoDirection)"""
        d, e, word, pos = self.d, self.e, self.word, self.s.scratch['word_pos']
        while self.read_word() == 0:
            pass
        self.e |= PF_PLAIN_VERB
        if self.d != TOKEN_DIRECTION:
            self.s.scratch['word_pos'] = pos
            self.d, self.e, self.word = d, e, word
            return self.store_command_word
        self.store_first_word()
        self.rec[1] = word
        return self.parse_next_word

    def parse_article(self):
        """Class 8 (a, the, is...): ignored. (stage 3: ParseArticle)"""
        self.e &= ~PF_ARTICLE_OK & 0xFF
        return self.dispatch_word

    def parse_in(self):
        """Class 1 (in, into): a command after AND while one is needed, else a
        preposition. (stage 3: ParseIn)"""
        if self.e & PF_NEED_COMMAND and self.word_flags == TOKEN_AND:
            return self.parse_verb_as_command
        self.d = TOKEN_PREPOSITION
        return self.parse_preposition

    def parse_preposition(self):
        """Class 7: store the preposition (a third in the record is refused),
        then the rest of the noun phrase. (stage 3: ParsePreposition, StorePreposition)"""
        self.preps = self.preps + 1 & 0xFF
        if self.preps >= MAX_PREPOSITIONS:
            refused = yield from self.reject_phrase()
        else:
            refused = yield from self.store_word_in_pair(0)
        if refused:
            return False
        return self.parse_phrase_word

    def parse_phrase_word(self):
        """More prepositions, one article (a second is refused), then the
        adjectives and the noun. (stage 3: ParsePhraseWord)"""
        while True:
            cls = self.read_word()
            if cls == TOKEN_PREPOSITION:
                return self.parse_preposition
            if cls != TOKEN_ARTICLE:
                return self.parse_in_1
            if not self.e & PF_ARTICLE_OK and (yield from self.reject_phrase()):
                return False
            self.e &= ~PF_ARTICLE_OK & 0xFF

    def parse_in_1(self):
        """An adjective or the noun goes on with the phrase; another word is put
        back and ends it. (stage 3: ParseIn_1)"""
        if self.d == TOKEN_ADJECTIVE:
            return self.parse_adjective
        if self.d == TOKEN_NOUN:
            return self.parse_noun
        self.s.scratch['word_pos'] = self.token
        return self.end_noun_phrase

    def parse_adjective(self):
        """Class 6: two adjectives are kept, a third is refused. (stage 3: ParseAdjective)"""
        if (yield from self.store_word_in_pair(3)):
            return False
        self.read_word()
        return self.parse_in_1

    def parse_noun(self):
        """Class 5. (stage 3: ParseNoun)"""
        self.slots[2] = self.word
        return self.end_noun_phrase

    def end_noun_phrase(self):
        """The phrase is complete. After EXCEPT a noun without a preposition gets
        a record of its own (an EXCEPT record) after the main record; else the
        phrase goes into a free block of the record. (stage 3: EndNounPhrase)"""
        self.d = TOKEN_NOUN
        if self.v.all_stage == ALL_STATE_EXCEPT:
            if not self.slots[0]:
                if not self.stack[self.k - 1][0] & RECF_EXCEPT:     # the first EXCEPT noun
                    self.k += 1
                    self.clear_record()
                self.store_block(BLOCK_A)
                self.rec[0] = self.rec[0] & 0xFF | RECF_EXCEPT
                return self.parse_next_word
            self.previous_record()
        if (yield from self.store_phrase_block()):
            return False
        return self.parse_next_word

    def store_word_in_pair(self, i):
        """The word into slot i or i + 1, the first empty; both full: refused.
        Returns True when the parse ends. (stage 3: StoreWordInPair)"""
        if self.slots[i] and self.slots[i + 1]:
            return (yield from self.reject_phrase())
        self.slots[i + 1 if self.slots[i] else i] = self.word
        return False

    def store_phrase_block(self):
        """The slots into the first free block; none free: refused. Returns
        True when the parse ends. (stage 3: StorePhraseBlock)"""
        if self.e & PF_BLOCK_A_FREE:
            self.store_block(BLOCK_A)
        elif self.e & PF_BLOCK_B_FREE:
            self.store_block(BLOCK_B)
        else:
            return (yield from self.reject_phrase())
        return False

    def store_block(self, at):
        """(stage 3: StoreFirstPhraseBlock, StorePhraseBlock_0)"""
        self.e &= ~(PF_BLOCK_A_FREE if at == BLOCK_A else PF_BLOCK_B_FREE) & 0xFF
        self.rec[at:at + 5] = self.slots

    # ---- refusing

    def reject_phrase(self):
        """The words do not fit: "What ?" and the parse ends (True), in a typed
        line; an order ignores it (False). (stage 3: RejectPhrase)"""
        if not self.typed:
            return False
        yield from print_what(self.s)
        return True

    def reject_line(self):
        """"What ?" and False; an order reads on. (stage 3: RejectLine)"""
        if not self.typed:
            return self.parse_next_word
        yield from print_what(self.s)
        return False


def copy_block(src, dst, at):
    """Block `at` of record src into dst, and src's second command word when
    dst has none. (stage 3: CopyBlockFromIX)"""
    dst[at:at + 5] = src[at:at + 5]
    if not dst[1]:
        dst[1] = src[1]


# ---------------------------------------------------------------------------
# Running the sentences

def run_sentences(s):
    """Run the records of s.scratch['phrases'] one after another: match each
    (a failure, its message printed, gives the rest of the line up), test it
    (a refusal prints its reason and takes no turn), else echo it, carry it
    out and end the turn; with ALL the record again for the next object. A
    question's record is skipped (its flag cleared). Returns a flow target or
    None; s.vars.parser_flag says whether the line has more sentences.
    (stage 3: RunSentences)"""
    from . import engine
    v = s.vars
    stack = s.scratch['phrases']
    v.verb_all_flag = 0
    k, nested = 0, False
    step = 'NextRecord' if v.awaiting_answer else 'RunSentences_Record'
    v.awaiting_answer, s.question = 0, None
    while True:
        if step == 'RunSentences_Record':
            m = yield from match_sentence(s, stack, k)
            if m is False:
                v.parser_flag = 0
                return None
            if m is True:
                if (yield from run_check(s)):
                    v.action_perform = 1
                    yield from text.print_command_sentence(s)
                    target = yield from engine.dispatch_command(s)
                    if target:
                        return target
                    step = 'EndOfTurn'
                else:
                    step = 'PerformRefusal'
            else:
                # PerformRefusal from inside MatchSentence goes on in its frame:
                # when the records run out, MatchSentence returns Z and its
                # caller clears parser_flag, so the rest of a line after THEN
                # is dropped (quirk kept)
                nested = nested or m == 'PerformRefusal'
                step = m
        elif step == 'PerformRefusal':
            set_perform_mode(s)             # the command prints its own refusal
            target = yield from engine.dispatch_command(s)
            if target:
                return target
            step = 'RunSentences_More'
        elif step == 'EndOfTurn':
            target = yield from engine.end_turn(s)
            if target:
                return target
            step = 'RunSentences_More'
        elif step == 'RunSentences_More':
            step = 'RunSentences_Record' if v.verb_all_flag else 'NextRecord'
        else:                               # NextRecord
            v.parser_word_count = v.parser_word_count - 1 & 0xFF
            if not v.parser_word_count:
                if nested:
                    v.parser_flag = 0
                return None
            k += 1
            while stack[k][0] & RECF_EXCEPT:
                k += 1
            step = 'RunSentences_Record'


def set_perform_mode(s):
    """Perform, and print in the input window. (stage 3: SetPerformMode)"""
    s.vars.action_perform = s.vars.raw_output = 1


def run_check(s):
    """The command's test pass (action_perform 0): True when it is allowed.
    (stage 3: RunCheck)"""
    from . import engine
    target = yield from engine.dispatch_command(s)
    if target:
        raise RuntimeError('a test pass went to %s' % target)
    return s.vars.action_allowed != 0


def reset_rec_work(s):
    """The story window, and the match's flags, counts and phrases cleared
    (the cursors and the rest kept). (stage 3: ResetRecWork)"""
    s.vars.raw_output = 0
    m = scan(s)
    m.has1 = m.has2 = m.seen1 = 0
    m.kept, m.phrase1, m.phrase2 = [0, 0], [0, 0, 0], [0, 0, 0]


def match_sentence(s, stack, k):
    """Match record k of the stack to a command (s.vars.command) and find its
    objects (first_object, second_object: NO_OBJECT unless found); with ALL
    one object a call, those EXCEPT names skipped. Returns True when matched,
    False when not (a message was printed), or where the turn goes on
    instead: 'EndOfTurn' (a verb no command has, typed), 'NextRecord' (ALL
    used up), 'PerformRefusal' (the command will print why it cannot).
    (stage 3: MatchSentence)"""
    v = s.vars
    v.first_object = v.second_object = NO_OBJECT
    reset_rec_work(s)
    rec = stack[k]
    cmd = yield from match_command(s, rec)
    if not isinstance(cmd, int) or not cmd:
        return cmd or False
    m = scan(s)
    v.command = m.command = s.scratch['saved_command'] = cmd
    unpack_flags(s)
    start_noun_scan1(s)
    v.action_perform = 0
    if v.command_flags[0] & CMDF_TAKES_NOUNS:
        v.verb_all_flag = m.all_word
        m.take_first = m.all_word >> 7
        while True:
            if not (yield from resolve_nouns(s)):
                return (yield from explain_noun_failure(s, rec))
            if not v.verb_all_flag or not is_excluded(s, stack, k):
                break
    return True


def match_command(s, rec):
    """Find the command whose verb and prepositions the record has: the verb,
    then the first two prepositions of blocks A and B in the order A1, B1,
    A2, B2 (words.match_command_record: in order or swapped). Found: its
    noun phrases are split out (split_noun_phrases), the id returned. A verb
    known but not with these words: "I do not know the verb ...", 0. No
    such verb: "You {verb}. Time passes", and 'EndOfTurn' for a typed line
    (the asm drops two return addresses), 0 for an order. (stage 3: MatchCommand)"""
    v, m = s.vars, scan(s)
    m.all_word = rec[0] >> 8 & 0x80
    collected = [w for w in (rec[BLOCK_A], rec[BLOCK_B], rec[BLOCK_A + 1], rec[BLOCK_B + 1]) if w][:2]
    m.words = [rec[0] & 0x7FFF] + collected + [0] * (2 - len(collected))
    verb_known = False
    for cmd, record in words.COMMANDS.items():
        ok, swapped, first = words.match_command_record(s, record, m.words)
        verb_known = verb_known or first
        if ok:
            split_noun_phrases(s, rec, record, swapped)
            return cmd
    if verb_known:
        return (yield from report_unknown_verb(s))
    v.raw_output = v.verb_all_flag = 0
    v.action_perform = 1
    yield from text.print_parser_message(s, 'MsgTimePasses', [m.words[0]])
    return 0 if v.input_from_order == 1 else 'EndOfTurn'


def split_noun_phrases(s, rec, record, swapped):
    """The matched record's two noun phrases (s.vars.command_flags packed from
    the command): bit 5 of StateB71D says whether phrase A or B is noun phrase
    1, flipped when the first preposition typed is one of block B's; with no
    preposition typed bit 5 of StateB71E is taken, flipped (the asm's quirk).
    Phrase 1 is also what IT means from now on. (stage 3: SplitNounPhrases)"""
    m = scan(s)
    if swapped:
        m.words[1], m.words[2] = m.words[2], m.words[1]
    flags = words.pack_command_flags(s, record)
    if not m.words[1]:
        bits = s.vars.command_flags[1] ^ 0x20
    else:
        bits = flags ^ 0x20 if m.words[1] in (rec[BLOCK_B], rec[BLOCK_B + 1]) else flags
    m.offsets = [REC_PHRASE_A, REC_PHRASE_B] if bits & 0x20 else [REC_PHRASE_B, REC_PHRASE_A]
    m.phrase1, m.phrase2 = (rec[o // 2:o // 2 + 3] for o in m.offsets)
    m.has1 |= any(m.phrase1)
    m.has2 |= any(m.phrase2)
    s.scratch['it'] = list(m.phrase1)


def unpack_flags(s):
    """The command's flags into needs_light, all_active (the objects need not
    be in reach), noun1_kind and noun2_kind (1: a place). (stage 3: UnpackFlags)"""
    v = s.vars
    d, e = v.command_flags
    v.needs_light = e & 0x40
    v.all_active = d & 0x01
    v.noun1_kind = 1 if d & 0x80 else 0
    v.noun2_kind = 1 if d & 0x40 else 0


def start_noun_scan1(s):
    """Start the search for noun 1, unless ALL is being worked through.
    (stage 3: StartNounScan1)"""
    if not s.vars.verb_all_flag:
        start_noun_scan1_always(s)


def start_noun_scan1_always(s):
    """From the first thing (the player skipped for a noun class 0), or the
    first exit when noun 1 is a place. (stage 3: StartNounScan1_Always)"""
    v = s.vars
    scan(s).cursor1 = -1 if v.noun1_kind or v.command_flags[1] >> 2 & 3 else 0


def start_noun_scan2(s):
    """(stage 3: StartNounScan2)"""
    v = s.vars
    scan(s).cursor2 = -1 if v.noun2_kind or v.command_flags[1] & 3 else 0


def need_second_noun(s):
    """Must noun phrase 2 be matched? Not when the command takes no second
    noun; yes when words were typed for it; else as bit 1 of StateB71D says
    (set: no). (stage 3: NeedSecondNoun)"""
    d = s.vars.command_flags[0]
    if not d & 0x04:
        return False
    return bool(scan(s).has2 & 1) or not d & 0x02


def resolve_nouns(s):
    """Find the objects: the candidates for noun 1 the verb applies to are
    counted (seen1), and kept when the command passes its test (or, with a
    second noun, when a partner is found for it); exactly one kept is
    first_object, then noun 2 likewise. With take_first the first kept will
    do. Returns True when found. (stage 3: ResolveNouns)"""
    m = scan(s)
    while True:
        if not next_noun1(s):
            if m.kept[0] != 1:
                return False
            s.vars.first_object = m.last[0]
            start_noun_scan2(s)
            if not need_second_noun(s):
                return True
            return (yield from resolve_nouns_second(s))
        m.seen1 = m.seen1 + 1 & 0xFF
        if not need_second_noun(s):
            ok = yield from run_check(s)
        else:
            start_noun_scan2(s)
            ok = yield from next_noun2(s)
        if not ok:
            continue
        if m.take_first == 1:
            return True
        m.last[0] = s.vars.first_object
        m.kept[0] = m.kept[0] + 1 & 0xFF


def resolve_nouns_second(s):
    """Exactly one accepted candidate for noun 2 becomes second_object.
    (stage 3: ResolveNouns_Second)"""
    m = scan(s)
    while True:
        if not (yield from next_noun2(s)):
            if m.kept[1] != 1:
                return False
            s.vars.second_object = m.last[1]
            return True
        m.last[1] = s.vars.second_object
        m.kept[1] = m.kept[1] + 1 & 0xFF


def _lookup(s, kind, cls):
    """The search for a noun: the exits for a place, else the things of class `cls`."""
    if kind == 1:
        return world.next_named_exit
    s.vars.all_mode = cls
    return world.next_named_thing


def next_noun1(s):
    """The next candidate for noun 1 the verb applies to (check_verb_applies),
    left in first_object; False when none is left. (stage 3: NextNoun1)"""
    from . import engine
    v, m = s.vars, scan(s)
    lookup = _lookup(s, v.noun1_kind, v.command_flags[1] >> 2 & 3)
    while True:
        id, m.cursor1 = lookup(s, m.phrase1, m.cursor1)
        if id == END:
            return False
        v.first_object = id
        m.has1 |= 2
        engine.check_verb_applies(s)
        if v.action_allowed:
            return v.action_allowed != 0xFF     # (the asm compares A with $FF)


def next_noun2(s):
    """The next candidate for noun 2 with which the whole command passes its
    test, left in second_object; all_active is 0 meanwhile (it must be in
    reach), then bit 0 of StateB71D. (stage 3: NextNoun2)"""
    v, m = s.vars, scan(s)
    v.all_active = 0
    lookup = _lookup(s, v.noun2_kind, v.command_flags[1] & 3)
    found = False
    while True:
        id, m.cursor2 = lookup(s, m.phrase2, m.cursor2)
        if id == END:
            break
        v.second_object = id
        m.has2 |= 2
        if (yield from run_check(s)):
            found = v.action_allowed != 0xFF
            break
    v.all_active = v.command_flags[0] & 0x01
    return found


def is_excluded(s, stack, k):
    """Does an EXCEPT record after record k name first_object? (stage 3: IsExcluded)"""
    while True:
        k += 1
        rec = stack[k]
        if not rec[0] & RECF_EXCEPT:
            return False
        cursor = -1
        while True:
            id, cursor = world.next_named_thing(s, rec[4:7], cursor)
            if id == END:
                break
            if id == s.vars.first_object:
                return True


# ---------------------------------------------------------------------------
# Questions and complaints

def save_parsed_record(s, rec, offset):
    """The record becomes the question waiting for its answer (record 0);
    `offset` is the phrase asked about. (stage 3: SaveParsedRecord)"""
    s.vars.awaiting_answer = offset
    s.question = Phrase(list(rec)) if offset else None
    if s.question and 'phrases' in s.scratch:
        s.scratch['phrases'][0] = s.question.words


def print_reply_fail(s, message, args):
    """A parser reply in the input window. (stage 3: PrintReplyFail)"""
    set_perform_mode(s)
    yield from text.print_parser_message(s, message, args)


def explain_noun_failure(s, rec):
    """The search did not end with one object per noun phrase: an order fails
    silently; ALL is used up ('NextRecord'); else the reason: a second noun
    missing, no words for noun 1 ("take what ?"), words that fit nothing
    here, a refusal the command prints ('PerformRefusal'), several ("Which
    ...?"). Returns False or where the turn goes on. (stage 3: ExplainNounFailure)"""
    v, m = s.vars, scan(s)
    if v.input_from_order == 1:
        return False
    if v.verb_all_flag:
        return 'NextRecord'
    if m.kept[0] == 1:
        return (yield from explain_noun2_failure(s, rec))
    if not m.has1 & 1:
        return (yield from report_no_noun1(s, rec))
    if not m.has1 & 2:
        return (yield from find_noun_elsewhere(s, 1))
    if not m.seen1:
        return 'PerformRefusal'
    if m.seen1 != 1:
        return (yield from ask_which(s, rec, m.offsets[0], m.phrase1[0]))
    if need_second_noun(s):
        return (yield from explain_noun2_failure(s, rec))
    return 'PerformRefusal'


def explain_noun2_failure(s, rec):
    """Noun 1 is settled, noun 2 is not. Several candidates: the asm asks about
    the address RecBuf2 as a word and saves the noun's low byte as the
    offset (quirk; never seen run). (stage 3: ExplainNoun2Failure)"""
    m = scan(s)
    if not m.has2 & 1:
        return (yield from report_no_second_noun(s, rec))
    if not m.has2 & 2:
        return (yield from find_noun_elsewhere(s, 2))
    if not m.kept[1]:
        return 'PerformRefusal'
    return (yield from ask_which(s, rec, m.phrase2[0] & 0xFF, STRAY_WORD))


def ask_which(s, rec, offset, word):
    """"Which {word} ?", the record saved as the question. (stage 3: AskWhichNoun1, AskWhich)"""
    save_parsed_record(s, rec, offset)
    yield from print_reply_fail(s, 'MsgWhich', [word])
    return False


def find_noun_elsewhere(s, n):
    """The words of noun phrase n fit nothing of the kind the command takes:
    an exit of the actor's location (noun n a place), else any thing at all.
    Found: it is noun n and the command is refused ("You cannot ...", through
    text.start_perform). None: "I do not see {phrase} here". Returns False.
    (stage 3: FindNounElsewhere)"""
    v, m = s.vars, scan(s)
    phrase = m.phrase1 if n == 1 else m.phrase2
    kind, obj = ('noun1_kind', 'first_object') if n == 1 else ('noun2_kind', 'second_object')
    setattr(v, kind, 1)
    id, _ = world.next_named_exit(s, phrase, -1)
    if id == END:
        v.all_mode = world.ALL_MODE_ANY
        setattr(v, kind, 0)
        id, _ = world.next_named_thing(s, phrase, -1)
        if id == END:
            yield from print_reply_fail(s, 'MsgIDoNotSeeHere', [list(phrase)])
            return False
    setattr(v, obj, id)
    yield from text.start_perform(s)
    return False


def report_no_noun1(s, rec):
    """A verb with no noun: "I see nothing to {verb}..." when nothing would
    do, else the question "{verb}... what ?". (stage 3: ReportNoNoun1)"""
    m = scan(s)
    args = push_words(s, False) + [m.words[0]]
    if not m.kept[0]:
        yield from print_reply_fail(s, 'MsgISeeNothing', args)
        return False
    save_parsed_record(s, rec, m.offsets[0])
    yield from print_reply_fail(s, 'MsgWhat3', args)
    return False


def report_no_second_noun(s, rec):
    """No second noun typed: "I see nothing to {verb} {thing} {with}" when
    nothing would do, else "{verb} {thing} {with} what ?". (stage 3: ReportNoSecondNoun)"""
    m = scan(s)
    names = world.thing(s, s.vars.first_object).names     # (a thing even when noun 1 is a place)
    args = push_words(s, True) + [0, names] + push_words(s, False) + [m.words[0]]
    if not m.kept[1]:
        yield from print_reply_fail(s, 'MsgISeeNothing2', args)
        return False
    save_parsed_record(s, rec, m.offsets[1])
    yield from print_reply_fail(s, 'MsgWhat2', args)
    return False


def push_words(s, after):
    """The matched command's two prepositions for a message, as the record's
    flags place them before the noun (`after` False) or after it; a word not
    in that place is 0. (stage 3: PushWordsBefore, PushWordsAfter: the flag
    was the JR opcode they wrote into the code)"""
    record = words.command(scan(s).command)
    keep2 = bool(record[3] & 0x8000) != after
    keep1 = bool(record[1] & 0x2000) != after
    return [record[2] if keep2 else 0, record[1] if keep1 else 0]


def report_unknown_verb(s):
    """"I do not know the verb "..."" with the words typed; 0. (stage 3: ReportUnknownVerb)"""
    m = scan(s)
    yield from print_reply_fail(s, 'MsgIDoNotKnowVerb', [m.words[2], m.words[1], m.words[0]])
    return 0


# ---------------------------------------------------------------------------
# A character's command (no typed sentence)

def test_actor_command(s):
    """Can the actor do s.vars.command with first_object and second_object
    (their kinds in noun1_kind, noun2_kind)? Their names are the phrases and
    the check runs as for a typed command (the first match will do).
    action_perform is left 1, the noun 1 cursor as it was. (stage 3: TestActorCommand)"""
    from . import engine
    v, m = s.vars, scan(s)
    cursor = m.cursor1
    reset_rec_work(s)
    words.pack_command_flags(s, words.command(v.command))
    unpack_flags(s)
    m.phrase1 = _names(s, v.first_object, v.noun1_kind) or m.phrase1
    m.phrase2 = _names(s, v.second_object, v.noun2_kind) or m.phrase2
    start_noun_scan1_always(s)
    v.action_perform = 0
    if v.command_flags[0] & CMDF_TAKES_NOUNS:
        m.take_first = 1
        ok = yield from resolve_nouns(s)
    else:
        target = yield from engine.dispatch_command(s)
        if target:
            raise RuntimeError('a test pass went to %s' % target)
        ok = v.action_allowed != 0
    v.action_perform = 1
    m.cursor1 = cursor
    return ok


def _names(s, id, kind):
    """The names of thing `id` (location when `kind`), None for NO_OBJECT.
    (stage 3: CopyNamePhrase)"""
    if id == NO_OBJECT:
        return None
    return list(s.locations[id].names if kind else world.thing(s, id).names)


# ---------------------------------------------------------------------------
# Orders given with SAY TO

def claim_order_slots(s, n):
    """The first n pending orders (at most s.order_count) go to first_object,
    the other pending ones are freed. (Too few pending slots: the asm walks
    on past the table; here it stops.) (stage 3: ClaimOrderSlots)"""
    take = min(n, s.order_count)
    pending = [o for o in s.orders if o.owner == ORDER_PENDING]
    for o in pending[:take]:
        o.owner = s.vars.first_object
    for o in pending[take:s.order_count]:
        o.owner = 0


def find_order_slot(s):
    """The index of the order slot the subject owns, or None (the player, 0,
    owns the free ones). (stage 3: FindOrderSlotKeep, FindOrderSlot)"""
    return next((i for i, o in enumerate(s.orders) if o.owner == s.vars.subject), None)


def free_order_slots(s, owner):
    """Free every order slot of `owner`. (stage 3: FreeOrderSlots)"""
    for o in s.orders:
        if o.owner == owner:
            o.owner = 0


def run_stored_order(s, run):
    """Take the subject's stored order: its slot is freed; without `run` that
    is all, (True, its phrase). Else it is matched as if typed and tested;
    a failure frees all the subject's slots. Returns (usable, phrase); the
    command is then in s.vars.command, first_object, second_object.
    (stage 3: RunStoredOrder)"""
    v = s.vars
    slot = find_order_slot(s)
    if slot is None:
        # the asm takes the bytes after the table (the phrase stack's bottom) as the order
        if run:
            raise NotImplementedError('a stored order with no slot (the original runs stale memory)')
        return True, None
    order = s.orders[slot]
    order.owner = 0
    if not run:
        return True, order.phrase
    v.input_from_order = 1
    all_flag = v.verb_all_flag
    matched = yield from match_sentence(s, Stack({0: order.phrase.words}), 0)
    v.input_from_order = 0
    v.verb_all_flag = all_flag
    ok = matched is True and (yield from run_check(s))
    if not ok:
        free_order_slots(s, v.subject)
    return ok, order.phrase

