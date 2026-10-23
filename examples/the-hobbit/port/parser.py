"""Ported from src/parser.asm: sentences: word classes, phrase records, nouns, questions, orders (SAY TO).
Values pass in the registers `r` (port/regs.py); conventions: port/CONTRACT.md.

The parser is a chain of tail jumps (ParseNextWord, DispatchWord, a word-class
handler, ParseNextWord ...): each is `return await Next()`, so the Python
stack mirrors the Z80 stack. Three routines drop return addresses; they are
handled here:
- RejectPhrase (typed line): "What ?" and back to the caller of the parser
  with NZ: raises _LineRefused, caught in ParseLineFrom.
- MatchCommand (a verb with no command record): drops MatchSentence's and
  RunSentences_Record's return addresses and goes on at EndOfTurn: raises
  _EndOfTurnJump, caught by RunSentences_Record.
- ExplainNounFailure (ALL): drops MatchSentence's return address and goes on
  at NextRecord: raises _NextRecordJump, caught by RunSentences_Record.
ExplainNounFailure's other exits (PerformRefusal -> RunSentences_More) go on
with RunSentences inside the frame of MatchSentence, as the asm does; when the
records are used up the final RET returns to the address after
`CALL MatchSentence`, which then clears ParserFlag: the rest of a line with THEN
is dropped after such a refusal. That is the asm's behaviour and the call
chain here keeps it."""
from labels import *  # noqa: F403  (first: port functions shadow routine labels)
import calls
import engine
import keys
import objects
import printer
from regs import r
from variables import v
from zxpyxel import Goto, mem, mem16, zx  # noqa: F401

JR_NZ, JR_Z = 0x20, 0x28            # the opcodes PushWords_SetTests writes into SmcKeepWord4/2


class _LineRefused(Exception):
    """RejectPhrase on a typed line: the parser returns NZ to its caller."""


class _EndOfTurnJump(Exception):
    """MatchCommand dropped two return addresses: go on at EndOfTurn."""


class _NextRecordJump(Exception):
    """ExplainNounFailure dropped a return address: go on at NextRecord."""


def _iy(d):
    return r.iy + d & 0xFFFF


def _ix(d):
    return r.ix + d & 0xFFFF


def _xor_a():
    r.a = 0
    r.zf, r.cf, r.sf = True, False, False


def _and_a():
    r.set_zs(r.a)
    r.cf = False


def _or_a(x):
    r.a = r.set_zs(r.a | x)
    r.cf = False


def _dec_a():
    r.a = r.set_zs(r.a - 1 & 0xFF)


def _ldir(src, dst, n):
    """LDIR of n bytes (n not 0): HL, DE after the copy, BC = 0."""
    for k in range(n):
        mem[dst + k & 0xFFFF] = mem[src + k & 0xFFFF]
    r.hl, r.de, r.bc = src + n & 0xFFFF, dst + n & 0xFFFF, 0
    r.pf = False
    zx.spend(21 * n - 5)


# ---------------------------------------------------------------------------
# The word loop

async def ParseLine():
    """Parse the typed word list into phrase records, starting at the top of
    the phrase stack for the player's line. O: Z when the records are ready,
    NZ when the line was refused (a message was printed) or is empty."""
    r.iy = PhraseRecord0
    r.a = 0
    return await ParseLineFrom()


async def ParseLineFrom():
    """Start a parse with A = InputFromOrder (0 typed line, 1 the text of an
    order, from BeginOrderPass) and IY the first phrase record. When a
    question is waiting for its answer the answer goes on as if AND had been
    read. A refused phrase (RejectPhrase) ends the whole parse here with NZ."""
    try:
        v.InputFromOrder = r.a
        ClearAllStage()
        v.ParserWordCount = r.a
        r.e = 0xFF
        r.a = v.AwaitingAnswer
        _and_a()
        r.d = TOKEN_AND
        if r.a:
            return await CloseRecord()
        r.d = TOKEN_END
        return await StartPhraseRecord()
    except _LineRefused:
        return


async def StartPhraseRecord():
    """Start a new phrase record: both phrase blocks free and a command word
    needed (not after EXCEPT), the record cleared. E = parser flags."""
    v.ActionFlag = 0
    r.e |= 0xC7
    r.a = v.AllStage
    r.cp(ALL_STATE_EXCEPT)
    if r.zf:
        r.e &= ~0x02 & 0xFF                      # after EXCEPT no command word is needed
    ClearRecord()
    return await ParseNextWord()


async def ParseNextWord():
    """Clear the phrase slots, allow an article, read the next word and send
    it to its class handler."""
    r.hl, r.b = ActionSlots, 0x0A
    keys.ClearBytes()
    r.e |= 0x10
    return await DispatchWord()


async def DispatchWord():
    """Read the next word and jump to the handler of its class in ActionTable
    (ParseAdverb, ParseIn, ParseDirection, ParseVerb, ParseGoVerb, ParseNoun,
    ParseAdjective, ParsePreposition, ParseArticle, DispatchSpecialWord,
    ParseAnd, ParseThen, ParseEnd). The handler gets BC the word, D its class,
    E the parser flags, IY the record."""
    ReadWord()
    r.a = r.a >> 3                               # RRCA x3: the class nibble * 2
    r.cf = False
    r.hl = mem16[ActionTable + r.a]
    return await calls.call_at(r.hl)


def TestOrderText():
    """Z while the text of an order (SAY TO) is parsed. O: A = InputFromOrder - 1."""
    r.a = v.InputFromOrder
    _dec_a()


def TestTypedLine():
    """Z for the player's own line (errors are reported). O: A = InputFromOrder."""
    r.a = v.InputFromOrder
    _and_a()


# ---------------------------------------------------------------------------
# End of a phrase, THEN, AND, the end of the line

async def ParseEnd():
    """Handler of class 12 (the end of the line): ParserFlag 0, then as THEN."""
    v.ParserFlag = 0
    return await ParseThen()


async def ParseThen():
    """Handler of class 11 (THEN, a full stop) and the tail of AND and of the
    end of the line. A phrase with no command word is refused with "What ?"
    (typed line), unless it is the empty line itself (then NZ, no message);
    otherwise the record is closed."""
    if not r.e & 0x02:                           # a command word is there
        return await CloseRecord()
    r.a = v.ParserWordCount
    _and_a()
    if r.a:
        return await CloseRecord()               # an older record can lend its command word
    r.a = v.WordFlags
    r.cp(TOKEN_END)
    if r.zf:
        r.cp(r.d)
        if r.zf:                                 # the line ended at once: an empty line
            return TestOrderText()
    TestTypedLine()
    if r.zf:
        return await PrintWhat()                 # a typed line without a command
    return await CloseRecord()


async def CloseRecord():
    """Close the record being built: flag it RECF_ALL after ALL, count it
    (not an AND inside the EXCEPT nouns), move on to the next record. After AND
    start the next phrase. At THEN or the end: take what an answer lacks from
    the question's phrase, let records without a command word inherit the
    older one's, and give older records a trailing second block. O: Z when the
    records are ready (end of line, or THEN in a typed line)."""
    a = v.AllStage - 1 & 0xFF
    if a == 0:
        mem[_iy(1)] |= 1 << RECF_ALL             # ALL typed: flag the record
    a = a - 1 & 0xFF
    r.a = r.d
    if a or r.d != TOKEN_AND:
        v.ParserWordCount += 1                   # one more record
    StepNewer()
    r.cp(TOKEN_AND)
    if r.zf:
        return await StartPhraseRecord()
    r.a = v.AwaitingAnswer
    _and_a()
    if r.a:
        _complete_answer()
    return await InheritWords()


def _complete_answer():
    """The line answers a question: the words the answer's noun phrase (first
    record after the saved one) lacks are taken from the saved record's phrase
    the question was about (offset AwaitingAnswer). Locals only: DE and IY
    are restored."""
    de0, iy0 = r.de, r.iy
    asked = PhraseRecord0 + v.AwaitingAnswer & 0xFFFF
    answer = PhraseRecord1
    phrase = PhraseRecord1Slot1
    if mem[answer + 8] | mem[answer + 9]:        # it has a noun
        same = mem[answer + 8] == mem[asked] and mem[answer + 9] == mem[asked + 1 & 0xFFFF]
        complete = same                          # the same noun as in the question: complete it
        if not same:
            phrase = PhraseRecord1Slot2          # else its second phrase, if it is empty
            complete = not (mem[answer + 0x12] | mem[answer + 0x13])
    else:
        complete = True                          # no noun: complete that phrase
    if complete:
        hl, de = phrase, asked
        for _ in range(3):                       # three words
            absent = not (mem[hl] | mem[hl + 1])
            if absent:
                mem[hl] = mem[de]                # missing: take it from the question's phrase
            hl, de = hl + 1, de + 1
            if absent:
                mem[hl] = mem[de]
            hl, de = hl + 1, de + 1
    r.de, r.iy = de0, iy0


async def InheritWords():
    """(Tail of CloseRecord) Oldest to newest, a record with no command word
    inherits the older one's (InheritRecord); newest to oldest, a second phrase
    block is copied into older records with the same command word and no second
    noun phrase of their own. Then Z at the end of the line or for THEN in a
    typed line; an order goes on with a new record."""
    iy_end = r.iy
    r.iy = LocationTable                         # one record above the oldest
    r.a = v.ParserWordCount
    r.b = r.a
    count = r.bc
    StepNewerCount()
    while r.b:                                   # oldest to newest
        StepNewerCount()
        r.a = mem[_iy(1)] & 0x7F | mem[_iy(0)]   # no command word (RECF_ALL aside)?
        if r.a == 0:
            InheritRecord()
    r.bc = count
    r.iy = iy_end
    StepOlderCount()
    while r.b:                                   # newest to oldest
        StepOlderCount()                         # IX = the newer, IY = the older record
        if mem[_iy(0x12)] | mem[_iy(0x13)]:      # the older one has a second noun phrase
            continue
        if mem[_iy(0)] != mem[_ix(0)] or mem[_iy(1)] != mem[_ix(1)]:
            continue                             # not the same command word
        if not mem[_ix(0x0E)] | mem[_ix(0x0F)]:
            continue                             # the newer one has no second block
        r.exx()
        r.de = REC_BLOCK_B
        CopyBlockFromIX()
    r.iy = iy_end
    r.a = v.ParserFlag
    _and_a()
    if r.zf:
        return                                   # end of the line: Z, the records are ready
    TestTypedLine()
    if r.zf:
        return                                   # THEN in a typed line: stop here
    return await StartPhraseRecord()             # an order: go on with a new record


# ---------------------------------------------------------------------------
# Word class handlers

async def ParseDirection():
    """Handler of class 2 (north, up, ne ...): the command by itself while a
    command word is needed, else the record's second word (once). D = 0."""
    if r.e & 1 << PF_NEED_COMMAND:
        return await ParseVerbAsCommand()
    r.d = 0
    return await ParseAdverb()


async def ParseAdverb():
    """Handler of class 0 (adverbs) and the tail of ParseDirection: the word
    is the record's second command word, if that is still free
    (PF_DIRECTION_OK); else "What ?" (RejectLine)."""
    if not r.e & 1 << PF_DIRECTION_OK:
        return await RejectLine()
    r.a = v.AllStage
    r.cp(ALL_STATE_EXCEPT)
    if r.zf:
        PreviousRecord()                         # after the nouns of EXCEPT: the main record
    r.e &= ~(1 << PF_DIRECTION_OK) & 0xFF
    r.l = REC_WORD2
    StoreRecordWord()
    return await ParseNextWord()


async def ParseAnd():
    """Handler of class 10 (and, the comma): skip further AND words, put the
    first word after them back and save the parser state (SavedHL, SavedA1 =
    E, SavedIY, SavedA2 = word count); then as THEN. BC leaves as the word
    after the ANDs."""
    r.e &= ~(1 << PF_NO_SAVED_POS) & 0xFF
    de = r.de
    while True:
        ReadWord()
        if r.a != TOKEN_AND:                     # skip "and and"
            break
    r.hl = r.hl - 2 & 0xFFFF                     # back to the start of that token
    v.SavedHL = r.hl
    v.WordListPtr = r.hl
    r.de = de
    r.a = r.e
    v.SavedA1 = r.a
    v.SavedIY = r.iy
    r.a = v.ParserWordCount
    v.SavedA2 = r.a
    return await ParseThen()


async def ParseGoVerb():
    """Handler of class 4 (go, run): a verb that looks ahead for a direction."""
    r.e &= ~(1 << PF_PLAIN_VERB) & 0xFF
    return await ParseVerbAsCommand()


async def ParseVerbAsCommand():
    """(Entry point inside ParseGoVerb) The word becomes a verb (D =
    TOKEN_VERB); ParseDirection and ParseIn join here."""
    r.d = TOKEN_VERB
    return await ParseVerb()


async def ParseVerb():
    """Handler of class 3 (the other verbs). After an AND that saved a
    position, in a typed line, the verb starts a new command: the saved
    position, flags and record are restored and the phrase before AND is
    closed as if THEN had been read (the verb is read again later). Otherwise
    it is stored as the command word."""
    if r.e & 1 << PF_NO_SAVED_POS:
        return await StoreVerb()
    TestTypedLine()
    if not r.zf:
        return await StoreVerb()                 # an order: no restart
    r.hl = v.SavedHL
    v.WordListPtr = r.hl
    r.d = TOKEN_THEN
    r.a = v.SavedA1
    r.e = r.a
    r.a = v.SavedA2
    v.ParserWordCount = r.a
    r.iy = v.SavedIY
    return await ParseThen()


async def StoreVerb():
    """Store the verb as the record's first word; a second command word is
    refused with "What ?". Go and run look ahead for a direction."""
    ClearAllStage()
    if not r.e & 1 << PF_NEED_COMMAND:
        return await RejectLine()                # a command word already
    if not r.e & 1 << PF_PLAIN_VERB:
        return await ParseGoDirection()          # go or run
    return await StoreCommandWord()


async def StoreCommandWord():
    """Store BC as the record's first command word and read on."""
    StoreFirstWord()
    return await ParseNextWord()


async def ParseGoDirection():
    """Look ahead past adverbs: when a direction follows, the direction (BC)
    becomes the command word (+0) and go or run the second word (+2), the form
    of the move commands in the command table; else the verb is stored as it is
    and the word is read again later. In the direction case E and D are left
    as they are (PF_PLAIN_VERB set, D the direction's class)."""
    de, bc, ptr = r.de, r.bc, v.WordListPtr
    while True:
        ReadWord()
        if r.a != 0:                             # skip adverbs (class 0)
            break
    r.e |= 1 << PF_PLAIN_VERB
    r.cp(TOKEN_DIRECTION)
    if not r.zf:
        r.hl = ptr                               # not a direction: read it again later
        v.WordListPtr = ptr
        r.bc, r.de = bc, de
        return await StoreCommandWord()
    StoreFirstWord()                             # the direction is the command word
    r.bc = bc                                    # BC = go or run
    r.hl = de
    r.l = REC_WORD2
    StoreRecordWord()
    return await ParseNextWord()


async def ParseArticle():
    """Handler of class 8 (a, an, the, is, can ...): ignored; the article
    allowed at the start of a phrase is used up (E bit 4)."""
    r.e &= ~(1 << PF_ARTICLE_OK) & 0xFF
    return await DispatchWord()


async def ParseIn():
    """Handler of class 1 (in, into): a command by itself after AND while a
    command word is needed, else a preposition (D = TOKEN_PREPOSITION)."""
    if r.e & 1 << PF_NEED_COMMAND:
        r.a = v.WordFlags
        r.cp(TOKEN_AND)
        if r.zf:
            return await ParseVerbAsCommand()
    r.d = TOKEN_PREPOSITION
    return await ParsePreposition()


async def ParsePreposition():
    """Handler of class 7 (on, with, to ...): store the preposition, then read
    the rest of the noun phrase."""
    await StorePreposition()
    return await ParsePhraseWord()


async def ParsePhraseWord():
    """Read the next word of a noun phrase: more prepositions, one article
    (a second is refused, RejectPhrase), then adjectives and the noun."""
    while True:
        ReadWord()
        if r.a == TOKEN_PREPOSITION:
            return await ParsePreposition()      # another preposition
        if r.a != TOKEN_ARTICLE:
            return await ParseIn_1()
        if not r.e & 1 << PF_ARTICLE_OK:         # an article is allowed once
            await RejectPhrase()
        r.e &= ~(1 << PF_ARTICLE_OK) & 0xFF


async def ParseIn_1():
    """A = class of the word just read: an adjective or the noun continues the
    phrase; any other word is put back (WordListPtr = InputLinePtr) and ends it."""
    if r.a == TOKEN_ADJECTIVE:
        return await ParseAdjective()
    if r.a == TOKEN_NOUN:
        return await ParseNoun()
    r.hl = v.InputLinePtr
    v.WordListPtr = r.hl
    return await EndNounPhrase()


async def ParseAdjective():
    """Handler of class 6: keep the adjective (two are kept), read on."""
    await StoreAdjective()
    ReadWord()
    return await ParseIn_1()


async def ParseNoun():
    """Handler of class 5: the noun goes to the noun slot of ActionSlots."""
    mem[ActionSlots + 4] = r.c
    mem[ActionSlots + 5] = r.b
    r.hl = ActionSlots + 5
    return await EndNounPhrase()


async def EndNounPhrase():
    """The noun phrase is complete (D = TOKEN_NOUN). After EXCEPT the nouns
    each get a record of their own (block A, RECF_EXCEPT) below the main
    record, unless a preposition makes the phrase the main record's; else the
    slots go into a block of the record (StorePhraseBlock)."""
    r.d = TOKEN_NOUN
    r.a = v.AllStage
    r.cp(ALL_STATE_EXCEPT)
    if r.zf:
        r.hl = mem16[ActionSlots]                # the first preposition
        r.a = r.h | r.l
        _and_a()
        if r.zf:                                 # no preposition: an EXCEPT noun
            if not mem[_iy(PARSED_RECORD_SIZE + 1)] & 1 << RECF_EXCEPT:
                r.bc = -PARSED_RECORD_SIZE & 0xFFFF   # the first noun: the free record below
                r.iy = r.iy + r.bc & 0xFFFF
                ClearRecord()
            await StoreFirstPhraseBlock()        # else IY is already a free record
            mem[_iy(1)] = 1 << RECF_EXCEPT
            return await ParseNextWord()
        PreviousRecord()
    await StorePhraseBlock()
    if r.zf:
        return await ParseNextWord()


async def StoreAdjective():
    """Store the word BC in the first free adjective slot (two); both full:
    RejectPhrase."""
    r.hl = ActionSlots + 6
    return await StoreWordInPair()


async def StoreWordInPair():
    """Store the word BC in the first of two consecutive slots at HL that is
    empty; both full: RejectPhrase."""
    r.a = mem[r.hl]
    r.hl = r.hl + 1 & 0xFFFF
    _or_a(mem[r.hl])
    if r.a:                                      # the first slot is taken
        r.hl = r.hl + 1 & 0xFFFF
        r.a = mem[r.hl]
        r.hl = r.hl + 1 & 0xFFFF
        _or_a(mem[r.hl])
        if r.a:
            return await RejectPhrase()
    mem[r.hl] = r.b
    r.hl = r.hl - 1 & 0xFFFF
    mem[r.hl] = r.c


async def StorePreposition():
    """Store a preposition (BC) in the phrase slots: ActionFlag counts them and
    the third is refused (RejectPhrase)."""
    v.ActionFlag += 1
    r.a = v.ActionFlag
    r.cp(MAX_PREPOSITIONS)
    if not r.cf:
        return await RejectPhrase()              # a third one
    r.hl = ActionSlots
    return await StoreWordInPair()


async def StorePhraseBlock():
    """Copy the collected phrase slots into the first free block of the record
    (E bit 6: first, bit 7: second); neither free: RejectPhrase. O: A = 0, Z
    after a store (and after an ignored rejection)."""
    if r.e & 0x40:
        return await StoreFirstPhraseBlock()
    if r.e & 0x80:
        return await StorePhraseBlock_0()
    await RejectPhrase()
    _xor_a()


async def StorePhraseBlock_0():
    """(Entry point inside StorePhraseBlock) Store the slots as the second
    block (offset REC_BLOCK_B) and mark it used (E bit 7)."""
    r.e &= ~0x80 & 0xFF
    bc, de = r.bc, r.de
    _ldir(ActionSlots, _iy(REC_BLOCK_B), PHRASE_BLOCK_SIZE)
    r.bc, r.de = bc, de
    _xor_a()


async def StoreFirstPhraseBlock():
    """(Entry point inside StorePhraseBlock) Store the slots as the first
    block (offset REC_BLOCK_A) and mark it used (E bit 6)."""
    r.e &= ~0x40 & 0xFF
    bc, de = r.bc, r.de
    _ldir(ActionSlots, _iy(REC_BLOCK_A), PHRASE_BLOCK_SIZE)
    r.bc, r.de = bc, de
    _xor_a()


# ---------------------------------------------------------------------------
# Phrase records

def PreviousRecord():
    """Go back to the nearest older record that is not an EXCEPT record, then
    clear the ALL/EXCEPT stage. O: IY = IX = that record, A = 0."""
    FindOlderRecord()
    r.iy = r.ix
    return ClearAllStage()


def ClearAllStage():
    """AllStage = 0 (normal command). O: A = 0."""
    v.AllStage = r.a = 0


def ClearRecord():
    """Zero the 24 bytes of the record at IY and the first word of the record
    below it, so the last record in use is followed by an empty one. O: B = 0."""
    r.hl, r.b = r.iy, PARSED_RECORD_SIZE
    keys.ClearBytes()
    mem[_iy(-PARSED_RECORD_SIZE)] = r.b
    mem[_iy(-PARSED_RECORD_SIZE + 1)] = r.b


def ReadWord():
    """Take the next token of the parsed word list (class nibble, 12-bit
    dictionary offset). D = class of the previous word (stored in WordFlags).
    O: A = D = class (high nibble), BC = the word, HL after the token;
    InputLinePtr = this token's address, for putting it back."""
    r.hl = v.WordListPtr
    v.InputLinePtr = r.hl
    r.a = r.d
    v.WordFlags = r.a
    r.a = mem[r.hl]
    r.b = r.a & 0x0F
    r.a = mem[r.hl] & 0xF0
    r.d = r.a
    r.hl = r.hl + 1 & 0xFFFF
    r.c = mem[r.hl]
    r.hl = r.hl + 1 & 0xFFFF
    v.WordListPtr = r.hl


def StepOlderCount():
    """B -= 1; IY = the next older non-EXCEPT record, IX = the old IY."""
    r.b = r.b - 1 & 0xFF
    FindOlderRecord()
    return SwapRecordPtrs()


def StepNewerCount():
    """B -= 1, then StepNewer."""
    r.b = r.b - 1 & 0xFF
    return StepNewer()


def StepNewer():
    """(Entry point inside StepNewerCount) IY = the next newer (lower)
    non-EXCEPT record, IX = the old IY."""
    FindNewerRecord()
    return SwapRecordPtrs()


def SwapRecordPtrs():
    """(Entry point inside StepNewerCount) Exchange IX and IY."""
    r.ix, r.iy = r.iy, r.ix


def FindNewerRecord():
    """IX = the nearest record below IY (newer) without RECF_EXCEPT. DE kept."""
    de = r.de
    r.de = -PARSED_RECORD_SIZE & 0xFFFF
    FindRecordStep()
    r.de = de


def FindOlderRecord():
    """IX = the nearest record above IY (older) without RECF_EXCEPT. DE kept."""
    de = r.de
    r.de = PARSED_RECORD_SIZE
    FindRecordStep()
    r.de = de


def FindRecordStep():
    """(Entry point inside FindOlderRecord) Search from IY in steps of DE for
    a record without RECF_EXCEPT. O: IX. DE is the step and is not restored
    here (the two callers keep it)."""
    r.ix = r.iy
    while True:
        r.ix = r.ix + r.de & 0xFFFF
        if not mem[_ix(1)] & 1 << RECF_EXCEPT:
            break
    r.zf = True


def InheritRecord():
    """The record at IY takes the command word (+0) and the flags (but not
    ALL) of the older record at IX. If the older record's first block has a
    preposition and the second block is free (E bit 7), the record's own noun
    phrase moves to the second block and the older first block is copied over
    it ("look in chest and map"). BC, DE, HL are kept (EXX)."""
    r.exx()
    r.a = mem[_ix(1)] & 0x7F | mem[_iy(1)]
    mem[_iy(1)] = r.a
    r.a = mem[_ix(0)]
    mem[_iy(0)] = r.a
    r.exx()
    r.a = mem[_iy(PARSED_RECORD_SIZE + REC_BLOCK_A)] | mem[_iy(PARSED_RECORD_SIZE + REC_BLOCK_A + 1)]
    r.zf = r.a == 0
    if r.zf:
        return
    r.zf = not r.e & 0x80
    if r.zf:
        return
    r.exx()
    hl = _iy(REC_PHRASE_B)
    _ldir(hl - PHRASE_BLOCK_SIZE & 0xFFFF, hl, PHRASE_WORDS_SIZE)   # phrase A -> phrase B
    r.de = REC_BLOCK_A
    return CopyBlockFromIX()


def CopyBlockFromIX():
    """Copy the 10-byte block at IX + DE to IY + DE (DE = REC_BLOCK_A or
    REC_BLOCK_B), then the second command word when IY's record has none.
    Ends with EXX: the caller's BC, DE, HL come back."""
    L78FB_0()
    r.a = mem[_iy(2)] | mem[_iy(3)]
    r.zf = r.a == 0
    r.de = REC_WORD2
    if r.zf:
        L78FB_1()
    r.exx()


def L78FB():
    """Copy 6 bytes of record field IX+DE to IY+DE (C = 6)."""
    r.c = 0x06
    return L78FB_2()


def L78FB_0():
    """As L78FB for 10 bytes (a phrase block)."""
    r.c = 0x0A
    return L78FB_2()


def L78FB_1():
    """As L78FB for 2 bytes (a word)."""
    r.c = 0x02
    return L78FB_2()


def L78FB_2():
    """Copy C bytes from IX + DE to IY + DE. O: HL, DE after the copy, BC = 0."""
    r.b = 0
    _ldir(_ix(r.de), _iy(r.de), r.c)


def StoreFirstWord():
    """Clear E bit 1 (no command word is needed any more) and store BC as the
    record's first word."""
    r.e &= ~0x02 & 0xFF
    r.l = REC_WORD1
    return StoreRecordWord()


def StoreRecordWord():
    """Store BC (low byte first) at IY + L. O: HL = the address of the high byte."""
    r.h = 0
    r.hl = _iy(r.l)
    mem[r.hl] = r.c
    r.hl = r.hl + 1 & 0xFFFF
    mem[r.hl] = r.b


# ---------------------------------------------------------------------------
# Refusing a line

async def RejectPhrase():
    """The words do not fit the grammar. In an order (SAY TO) the error is
    ignored (NZ, back to the caller). In the player's line this drops the
    caller's return address: "What ?" and the parse ends at once with NZ (_LineRefused)."""
    TestTypedLine()
    if not r.zf:
        return
    await PrintWhat()
    raise _LineRefused


async def RejectLine():
    """Refuse the line with "What ?" and NZ; in an order the error is ignored
    and the parser goes on with the next word."""
    TestTypedLine()
    if not r.zf:
        return await ParseNextWord()
    return await PrintWhat()


async def PrintWhat():
    """Print "What ?" in the input window. O: NZ."""
    r.hl = MsgWhat
    r.a = v.RawOutputFlag = 1
    await printer.PrintMessage()
    _or_a(1)


# ---------------------------------------------------------------------------
# Running the sentences

async def RunSentences():
    """Run the parsed phrase records one after another (see the asm header).
    A question waiting for its answer (AwaitingAnswer) is cleared and its
    record skipped. O: Z; the caller tests ParserFlag."""
    v.VerbAllFlag = 0
    r.iy = PhraseRecord0
    r.hl = AwaitingAnswer
    r.a = 0
    r.cp(mem[r.hl])
    mem[r.hl] = r.a
    if not r.zf:
        return await NextRecord()
    return await RunSentences_Record()


async def RunSentences_Record():
    """Match the record at IY (MatchSentence); not understood: ParserFlag = 0,
    the rest of the line is given up. Else check the command with
    ActionPerform 0: refused -> PerformRefusal; allowed -> print it as a
    sentence, carry it out, end of turn."""
    jump = None
    try:
        await MatchSentence()
    except _EndOfTurnJump:                       # MatchCommand dropped two return addresses
        jump = EndOfTurn
    except _NextRecordJump:                      # ExplainNounFailure dropped one
        jump = NextRecord
    if jump:
        return await jump()
    if r.zf:
        _xor_a()
        v.ParserFlag = 0
        return
    await RunCheck()
    if r.zf:
        return await PerformRefusal()
    r.a = v.ActionPerform = 1
    await keys.PrintCommandSentence()
    await engine.DispatchCommand()
    return await EndOfTurn()


async def EndOfTurn():
    """The world's turn (timers, then the other characters), then the next
    object of ALL or the next record."""
    await engine.EndTurn_Timer()
    return await RunSentences_More()


async def RunSentences_More():
    """With ALL typed (VerbAllFlag) match the same record again for the next
    object, else go to the next record."""
    r.a = v.VerbAllFlag
    _and_a()
    if r.a:
        return await RunSentences_Record()
    return await NextRecord()


async def NextRecord():
    """The next record down the phrase stack, stepping over EXCEPT records;
    RET Z when the count of records runs out."""
    r.a = v.ParserWordCount
    _dec_a()
    v.ParserWordCount = r.a
    if r.zf:
        return
    r.bc = -PARSED_RECORD_SIZE & 0xFFFF
    while True:
        r.iy = r.iy + r.bc & 0xFFFF
        if not mem[_iy(1)] & 1 << RECF_EXCEPT:   # skip the EXCEPT-only records
            break
    return await RunSentences_Record()


def ResetRecWork():
    """RawOutputFlag = 0 (story window) and zero RecWork .. RecBuf2 (17 bytes).
    RecPtr1 and the later fields are kept. O: A = 0."""
    r.a = 0
    v.RawOutputFlag = 0
    r.hl, r.b = RecWork, RecPtr1 - RecWork
    keys.ClearBytes()


async def MatchSentence():
    """Match the phrase record at IY to a command and find its objects:
    FirstObject and SecondObject start as NO_OBJECT, MatchCommand finds the
    command record (CommandId, RecPtr3), UnpackFlags and StartNounScan1 set up
    the scan, ResolveNouns finds the objects (one per call with ALL, skipping
    those EXCEPT names). Failure to find one object each goes on in
    ExplainNounFailure. O: NZ matched; Z not (a message was printed). IX = the
    command record."""
    r.a = 0xFF
    v.SecondObject = v.FirstObject = r.a
    ResetRecWork()
    await MatchCommand()
    if r.zf:
        return
    r.hl = r.ix - CommandTable & 0xFFFF
    r.de = COMMAND_RECORD_SIZE if r.hl else CommandTable
    r.a = r.hl // COMMAND_RECORD_SIZE + 1        # the record's index from 1
    r.hl = 0
    v.CommandId = v.SavedCommandId = r.a
    v.RecPtr3 = r.ix
    UnpackFlags()
    StartNounScan1()
    r.a = v.ActionPerform = 0
    r.a = v.StateB71D & 0x0C                     # does the command take nouns?
    if r.a:
        r.a = v.RecWork4                         # the ALL flag of the first word
        v.VerbAllFlag = r.a
        v.RecWork5 = r.a >> 7                    # RLCA, AND 1: 1 when ALL
        while True:
            await ResolveNouns()
            if not r.zf:
                return await ExplainNounFailure()
            r.a = v.VerbAllFlag
            _and_a()
            if r.zf:
                break                            # not ALL: done
            IsExcluded()
            if r.zf:                             # EXCEPT does not name this object
                break
    _or_a(1)


async def ResolveNouns():
    """Find the objects the noun phrases mean: candidates for the first noun
    (NextNoun1) are counted in RecWork3, the last one kept in RecWork7; with a
    second noun each is kept only if NextNoun2 finds a partner. Exactly one
    must be kept: it becomes FirstObject; the second noun is then settled the
    same way (RecWork3+1, RecWork8, SecondObject). With ALL (RecWork5 = 1) the
    first kept candidate is returned at once. O: Z when found, NZ when not."""
    while True:
        await NextNoun1()
        if r.zf:                                 # none left: how many were accepted?
            r.a = v.RecWork3[0]
            r.cp(1)
            if not r.zf:
                return                           # not exactly one: failure
            r.a = v.RecWork7
            v.FirstObject = r.a
            StartNounScan2()
            NeedSecondNoun()
            if r.zf:
                return                           # no second noun: done (Z)
            return await ResolveNouns_Second()
        v.RecWork2 += 1                          # candidates seen for the first noun
        NeedSecondNoun()
        if r.zf:
            await RunCheck()                     # no second noun: test with this candidate
        else:
            StartNounScan2()
            await NextNoun2()                    # a candidate for the second noun?
        if r.zf:
            continue                             # none (or refused): the next first candidate
        r.a = v.RecWork5
        _dec_a()
        if r.zf:
            return                               # ALL: this one, now (Z)
        r.a = v.FirstObject                      # count this candidate
        v.RecWork7 = r.a
        v.RecWork3[0] += 1


async def ResolveNouns_Second():
    """(Tail of ResolveNouns) Settle the second noun: exactly one accepted
    candidate becomes SecondObject (Z), else NZ."""
    while True:
        await NextNoun2()
        if r.zf:
            r.a = v.RecWork3[1]
            r.cp(1)
            if not r.zf:
                return
            r.a = v.RecWork8
            v.SecondObject = r.a
            return
        r.a = v.SecondObject                     # count this candidate
        v.RecWork8 = r.a
        v.RecWork3[1] += 1


def IsExcluded():
    """Test whether EXCEPT removes FirstObject: walk the EXCEPT records below
    the record at IY and list the objects each can mean. IY, DE, HL kept.
    O: NZ excluded, Z not. IX destroyed."""
    iy, de, hl = r.iy, r.de, r.hl
    excluded = False
    while not excluded:
        r.de = -PARSED_RECORD_SIZE & 0xFFFF
        r.iy = r.iy + r.de & 0xFFFF
        if not mem[_iy(1)] & 1 << RECF_EXCEPT:   # not an EXCEPT record: not excluded
            r.zf = True
            break
        r.ix = ObjectTable - 3
        while True:
            r.hl = _iy(REC_PHRASE_A)
            r.de = REC_PHRASE_A
            objects.FindNextNamedObject()
            r.cp(END_MARK)
            if r.zf:
                break                            # no more: next record
            r.cp(v.FirstObject)
            if r.zf:
                _or_a(1)
                excluded = True
                break
    r.iy, r.de, r.hl = iy, de, hl


def StartNounScan1():
    """Start the scan for the first noun unless ALL is being worked through
    (VerbAllFlag not 0)."""
    r.a = v.VerbAllFlag
    _and_a()
    if r.a:
        return
    return StartNounScan1_Always()


def StartNounScan1_Always():
    """Set RecPtr1 (and IX): the start of the object table for the class in
    StateB71E bits 2-3, or the exits of the actor's location when Noun1Kind
    is a place."""
    r.a = v.StateB71E
    r.a = (r.a >> 2 | r.a << 6) & 0xFF           # RRCA x2
    PickScanStart()
    r.a = v.Noun1Kind
    _and_a()
    if r.a:
        objects.SeekActorExits()
    v.RecPtr1 = r.ix


def StartNounScan2():
    """The same for the second noun: class StateB71E bits 0-1, Noun2Kind, RecPtr2."""
    r.a = v.StateB71E
    PickScanStart()
    r.a = v.Noun2Kind
    _and_a()
    if r.a:
        objects.SeekActorExits()
    v.RecPtr2 = r.ix


def PickScanStart():
    """IX = ObjectTable for a noun class (A bits 0-1) of 0 (the player's own
    entry is skipped), else ObjectTable - 3 (NextObject steps on by 3 first)."""
    r.ix = ObjectTable
    r.a &= 0x03
    r.set_zs(r.a)
    r.cf = False
    if r.zf:
        return
    r.ix = ObjectTable - 3


def NeedSecondNoun():
    """Must the second noun phrase be matched next? Z (no) when StateB71D bit
    2 is clear; NZ (yes) when the player typed words for it (RecWork1 bit 0);
    else bit 1 of StateB71D: set gives Z, clear NZ. O: A destroyed."""
    r.a = v.StateB71D
    r.zf = not r.a & 0x04
    if r.zf:
        return
    r.hl = RecWork1
    r.zf = not mem[r.hl] & 0x01
    if not r.zf:
        return
    if r.a & 0x02:
        _xor_a()
        return
    _or_a(1)


async def RunCheck():
    """DispatchCommand (a test pass when ActionPerform is 0), then
    A = ActionAllowed. O: Z when it is 0, the command is refused."""
    await engine.DispatchCommand()
    r.a = v.ActionAllowed
    _and_a()


async def TestActorCommand():
    """Test whether a character can do the command CommandId with FirstObject
    and SecondObject (Noun1Kind/Noun2Kind: object or place) without a typed
    sentence: the command record's flags are packed and unpacked, the nouns'
    name phrases go to RecBuf1/2, and the check runs (ResolveNouns with
    RecWork5 = 1 for a command with nouns). ActionPerform is left 1. All
    registers except A and the flags, and RecPtr1, are kept. O: NZ the
    command can be done, Z refused. A = 1."""
    saved = r.hl, r.iy, r.ix, r.de, r.bc
    ptr1 = v.RecPtr1
    r.a = v.CommandId
    keys.CommandRecordAddr()
    r.ix = r.hl
    ResetRecWork()
    keys.PackCommandFlags()
    UnpackFlags()
    r.b = v.FirstObject
    r.a = v.Noun1Kind
    r.de = RecBuf1
    CopyNamePhrase()
    r.b = v.SecondObject
    r.a = v.Noun2Kind
    r.de = RecBuf2
    CopyNamePhrase()
    StartNounScan1_Always()                      # ignores VerbAllFlag
    r.a = v.ActionPerform = 0
    r.a = v.StateB71D & 0x0C                     # does the command take nouns?
    if r.a:
        r.a = v.RecWork5 = 1                     # take the first match
        await ResolveNouns()
        if r.zf:
            _or_a(1)                             # matched: NZ
        else:
            _xor_a()                             # no match: Z
    else:
        await engine.DispatchCommand()           # check it directly
        r.a = v.ActionAllowed
        _and_a()
    r.a = v.ActionPerform = 1                    # the caller carries it out
    v.RecPtr1 = ptr1
    r.hl, r.iy, r.ix, r.de, r.bc = saved


def CopyNamePhrase():
    """Copy the 6-byte name phrase of object B (or of place B when A, the
    kind, is not 0) to DE; B = $FF means none and nothing is copied (B is
    then left 0). O: BC = 0, DE and HL after the copy."""
    r.b = r.b + 1 & 0xFF
    if r.b == 0:
        r.zf = True
        return
    r.b = r.b - 1 & 0xFF
    _and_a()
    zero = r.zf
    r.a = r.b
    if zero:
        keys.ObjectNamePtr()
    else:
        keys.LocationNamePtr()
    _ldir(r.hl, r.de, PHRASE_WORDS_SIZE)


def UnpackFlags():
    """Unpack StateB71D/E into NeedsLight (StateB71E & $40), AllActive
    (StateB71D & 1), Noun1Kind (bit 7 -> 1) and Noun2Kind (bit 6 -> 1).
    O: A = Noun2Kind, B = StateB71D."""
    v.NeedsLight = v.StateB71E & 0x40
    r.b = v.StateB71D
    v.AllActive = r.b & 0x01
    r.a = v.Noun1Kind = 1 if r.b & 0x80 else 0
    r.a = v.Noun2Kind = 1 if r.b & 0x40 else 0


async def MatchCommand():
    """Find the command table record that matches the phrase record at IY:
    the ALL flag goes to RecWork4, the verb to RecWord1 and up to two
    prepositions (first block, second block) to RecWord2/3 (CollectWord);
    MatchCommandRecord tries the table. Found: SplitNounPhrases, NZ, IX =
    the record. The verb known but not with these words: ReportUnknownVerb.
    No such verb: "You {WORD}. Time passes" and, for a typed line, the end of
    the turn at once (drops two return addresses: _EndOfTurnJump); for an
    order Z."""
    iy = r.iy
    r.l = mem[_iy(0)]
    r.h = mem[_iy(1)]
    r.a = r.h & 0x80
    v.RecWork4 = r.a
    r.h &= 0x7F
    v.RecWord1 = r.hl
    r.hl = RecWord2
    hl = r.hl
    r.b = 0x04
    keys.ClearBytes()                            # RecWord2 and RecWord3 empty
    r.hl = hl
    r.b = 0x02                                   # room for two words
    for offset in (REC_BLOCK_A, REC_BLOCK_B, REC_BLOCK_A + 2, REC_BLOCK_B + 2):
        r.e = offset
        CollectWord()
    v.PhraseMatched = 0
    r.hl = RecWord1
    r.de = COMMAND_RECORD_SIZE
    r.ix = CommandTable
    while True:
        r.iy = r.ix
        keys.MatchCommandRecord()
        if r.zf:
            r.iy = iy
            SplitNounPhrases()
            return _or_a(1)
        r.ix = r.ix + r.de & 0xFFFF
        r.a = mem[_ix(1)]
        _or_a(mem[_ix(0)])
        if not r.a:
            break                                # the zero word ends the table
    r.iy = iy
    r.a = v.PhraseMatched
    _and_a()
    if r.a:
        return await ReportUnknownVerb()
    r.hl = v.RecWord1                            # the verb word, for {WORD}
    printer.msg_args.append(r.hl)
    r.hl = MsgTimePasses
    r.a = v.RawOutputFlag = v.VerbAllFlag = 0
    r.a = v.ActionPerform = 1
    await printer.PrintParserMessage()
    r.a = v.InputFromOrder
    _dec_a()
    if r.zf:
        return                                   # an order: Z, no match
    raise _EndOfTurnJump                         # the typed line: end the turn here


def SplitNounPhrases():
    """A matched phrase into its two noun phrases. A not 0: the command
    matched with its two words swapped (swap RecWord2/3). PackCommandFlags
    builds StateB71D/E; bit 5 of StateB71D decides which of the record's
    phrases (+$12, +$08) is noun phrase 1, flipped when the first collected
    word is the word at +$0E or +$10 of the record (with no collected word
    bit 5 of StateB71E is taken and flipped: the asm's quirk). Phrase 1 goes to
    RecBuf1 (RecWork bit 0 if it has words) and PhraseBuffer, phrase 2 to
    RecBuf2 (RecWork1). RecWork6/7 hold the two offsets."""
    _and_a()
    if r.a:
        r.hl, r.de = v.RecWord2, v.RecWord3
        v.RecWord2, v.RecWord3 = r.de, r.hl
    keys.PackCommandFlags()
    r.hl = RecWord2
    r.a = mem[r.hl]
    r.hl = r.hl + 1 & 0xFFFF
    _or_a(mem[r.hl])
    if r.a == 0:                                 # no word collected: use StateB71E
        r.a = v.StateB71E ^ 0x20
    else:
        r.hl = r.hl - 1 & 0xFFFF
        r.a = mem[r.hl]
        r.cp(mem[_iy(0x0E)])
        matched = False
        if r.zf:
            r.hl = r.hl + 1 & 0xFFFF
            r.a = mem[r.hl]
            r.cp(mem[_iy(0x0F)])
            matched = r.zf
            if not matched:
                r.hl = r.hl - 1 & 0xFFFF
        if not matched:
            r.a = mem[r.hl]
            r.cp(mem[_iy(0x10)])
            if r.zf:
                r.hl = r.hl + 1 & 0xFFFF
                r.a = mem[r.hl]
                r.cp(mem[_iy(0x11)])
        r.a = v.StateB71D
        if r.zf:
            r.a ^= 0x20                          # flip bit 5
    if r.a & 0x20:
        r.b, r.c = REC_PHRASE_A, REC_PHRASE_B
    else:
        r.b, r.c = REC_PHRASE_B, REC_PHRASE_A
    v.RecWork6[0] = r.b                          # offset of phrase 1
    v.RecWork6[1] = r.c                          # offset of phrase 2
    r.a = r.b
    r.de = RecBuf1
    r.hl = RecWork
    CopyPhrase()                                 # phrase 1 to RecBuf1
    r.a = r.c
    _ldir(RecBuf1, PhraseBuffer, PHRASE_WORDS_SIZE)
    r.de = RecBuf2                               # phrase 2 to RecBuf2
    r.hl = RecWork1
    return CopyPhrase()


def CopyPhrase():
    """Copy the 6-byte noun phrase at IY + A to DE; set bit 0 of the byte at HL
    when it has any word. BC and HL are kept. O: A = the OR of the six bytes,
    Z when none; DE after the copy."""
    bc, flag = r.bc, r.hl
    _ldir(_iy(r.a), r.de, PHRASE_WORDS_SIZE)
    r.a = 0
    for k in range(PHRASE_WORDS_SIZE):
        r.a |= mem[r.hl - 1 - k & 0xFFFF]
    r.set_zs(r.a)
    r.b = 0
    r.hl, r.bc = flag, bc
    if r.zf:
        return                                   # no words: leave the flag clear
    mem[r.hl] |= 0x01


def CollectWord():
    """Copy the word at offset E of the parsed record (IY) to the list at HL;
    a non-zero word uses a slot (B -= 1, HL on to the next). Nothing when B
    is 0. O: Z when the word was zero or B was 0."""
    r.a = 0
    r.cp(r.b)
    if r.zf:
        return
    r.d = 0
    p = _iy(r.de)
    r.a = mem[p]
    mem[r.hl] = r.a
    r.hl = r.hl + 1 & 0xFFFF
    r.a = mem[p + 1 & 0xFFFF]
    mem[r.hl] = r.a
    r.hl = r.hl - 1 & 0xFFFF
    _or_a(mem[p])
    if r.zf:
        return
    r.b = r.set_zs(r.b - 1 & 0xFF)
    r.hl = r.hl + 2 & 0xFFFF


async def CallIY():
    """JP (IY): the noun lookup (FindNextNamedObject or FindExitByName) runs
    with HL = the phrase words and returns to the caller of this routine."""
    return await calls.call_at(r.iy)


async def NextNoun1():
    """One step of the search for the first noun phrase (RecBuf1) from the
    cursor RecPtr1: among the exits when Noun1Kind is a place, else among
    the objects of the kind in StateB71E bits 2-3 (AllMode). O: Z when no
    candidate is left (A = $FF), else NZ with FirstObject the accepted one
    (A is ActionAllowed, not the id). IY kept."""
    iy = r.iy
    r.ix = v.RecPtr1
    r.a = v.Noun1Kind
    _dec_a()
    if r.zf:
        r.iy = FindExitByName
    else:
        r.iy = FindNextNamedObject
        r.a = v.StateB71E
        r.a = (r.a >> 2 | r.a << 6) & 0xFF       # RRCA x2
        r.a &= 0x03
        v.AllMode = r.a
    await NextNoun1Match()
    r.cp(0xFF)
    v.RecPtr1 = r.ix
    r.iy = iy


async def NextNoun1Match():
    """Ask the lookup in IY for the next candidate (HL = RecBuf1) until
    CheckVerbApplies lets one through (ActionAllowed). It is left in
    FirstObject; RecWork bit 1 says a candidate was found. O: Z, A = $FF when
    none is left."""
    while True:
        r.hl = RecBuf1
        await CallIY()
        r.cp(0xFF)
        if r.zf:
            return
        v.FirstObject = r.a
        v.RecWork |= 0x02
        engine.CheckVerbApplies()
        r.a = v.ActionAllowed
        _and_a()
        if r.zf:
            continue                             # refused: try the next one
        return


async def NextNoun2():
    """The same step for the second noun phrase (RecBuf2, cursor RecPtr2,
    StateB71E bits 0-1); a candidate is accepted when the whole command is
    allowed (RunCheck) and is left in SecondObject. AllActive is 0 during the
    search (the second object must be in reach) and bit 0 of StateB71D after.
    O: as NextNoun1."""
    v.AllActive = r.a = 0
    iy = r.iy
    r.ix = v.RecPtr2
    r.a = v.Noun2Kind
    _dec_a()
    if r.zf:
        r.iy = FindExitByName
    else:
        r.iy = FindNextNamedObject
        r.a = v.StateB71E & 0x03
        v.AllMode = r.a
    await NextNoun2Match()
    r.cp(0xFF)
    v.RecPtr2 = r.ix
    r.iy = iy
    af = r.a, r.zf, r.cf, r.sf, r.pf
    v.AllActive = v.StateB71D & 0x01
    r.a, r.zf, r.cf, r.sf, r.pf = af


async def NextNoun2Match():
    """As NextNoun1Match for the second noun: HL = RecBuf2, SecondObject,
    RecWork1 bit 1, and RunCheck (both objects) as the test."""
    while True:
        r.hl = RecBuf2
        await CallIY()
        r.cp(0xFF)
        if r.zf:
            return
        v.SecondObject = r.a
        v.RecWork1 |= 0x02
        await RunCheck()
        if r.zf:
            continue                             # refused: try the next one
        return


# ---------------------------------------------------------------------------
# Questions and complaints

def SetPerformMode():
    """ActionPerform = 1 and RawOutputFlag = 1 (the input window). O: A = 1."""
    r.a = v.ActionPerform = 1
    v.RawOutputFlag = 1


def SaveParsedRecord():
    """AwaitingAnswer = A (the offset of the noun phrase asked about) and copy
    the 24-byte record at IY to the top of the phrase stack (PhraseRecord0)."""
    v.AwaitingAnswer = r.a
    _ldir(r.iy, PhraseRecord0, PARSED_RECORD_SIZE)


async def AskWhichNoun1():
    """Several objects fit the first noun phrase: save the record and ask
    "Which {first word} ?"."""
    r.a = v.RecWork6[0]
    r.hl = mem16[RecBuf1]
    return await AskWhich()


async def AskWhich():
    """(Entry point inside AskWhichNoun1) A = offset, HL = the word to print."""
    printer.msg_args.append(r.hl)
    SaveParsedRecord()
    r.hl = MsgWhich
    return await PrintReplyFail()


async def PrintReplyFail():
    """Print the parser reply at HL in perform mode and fail. O: A = 0, Z."""
    SetPerformMode()
    await printer.PrintParserMessage()
    _xor_a()


async def ExplainNoun2Failure():
    """The first noun phrase is settled, the second is not: no words typed for
    it (ReportNoSecondNoun); words that fit nothing (FindNounElsewhere);
    candidates but none accepted (PerformRefusal); several (ask "Which"). The
    last case is the asm's odd one: it pushes the address RecBuf2 as the word
    and stores the low byte of RecBuf2 in AwaitingAnswer (not seen run)."""
    r.hl = RecWork1
    if not mem[r.hl] & 0x01:
        return await ReportNoSecondNoun()
    r.zf = not mem[r.hl] & 0x02
    r.hl, r.de, r.bc = RecBuf2, SecondObject, Noun2Kind
    if r.zf:
        return await FindNounElsewhere()
    r.a = v.RecWork3[1]
    _and_a()
    if r.zf:
        return await PerformRefusal()
    r.a = v.RecWork6[1]                          # (this load is overwritten)
    r.a = mem[RecBuf2]
    return await AskWhich()


async def ExplainNounFailure():
    """The search for the objects (ResolveNouns) did not end with one object
    per noun phrase; this takes MatchSentence's place. An order: Z at once,
    silent. ALL: drop MatchSentence's return address and go to the next record
    (_NextRecordJump). Else, in the asm's order: one object for the first phrase
    -> ExplainNoun2Failure; no words typed -> ReportNoNoun1; nothing fits ->
    FindNounElsewhere; none passed the check -> PerformRefusal; several ->
    AskWhichNoun1; one passed and a second noun is needed ->
    ExplainNoun2Failure; else PerformRefusal."""
    r.a = v.InputFromOrder
    _dec_a()
    if r.zf:
        return
    r.a = v.VerbAllFlag
    _and_a()
    if r.a:
        raise _NextRecordJump
    r.a = v.RecWork3[0]
    r.cp(1)
    if r.zf:
        return await ExplainNoun2Failure()
    r.hl = RecWork
    if not mem[r.hl] & 0x01:
        return await ReportNoNoun1()
    r.zf = not mem[r.hl] & 0x02
    r.hl, r.de, r.bc = RecBuf1, FirstObject, Noun1Kind
    if r.zf:
        return await FindNounElsewhere()
    r.a = v.RecWork2
    _and_a()
    if r.zf:
        return await PerformRefusal()
    _dec_a()
    if not r.zf:
        return await AskWhichNoun1()
    NeedSecondNoun()
    if not r.zf:
        return await ExplainNoun2Failure()
    return await PerformRefusal()


async def PerformRefusal():
    """Run the command again in perform mode so that its handler prints the
    refusal, then go on with the turn (RunSentences_More: no turn is taken)."""
    SetPerformMode()
    await engine.DispatchCommand()
    return await RunSentences_More()


async def FindNounElsewhere():
    """The words fitted no object of the kind the command takes. HL = the typed
    phrase, DE = FirstObject or SecondObject, BC = Noun1Kind or Noun2Kind. Look
    among the exits of the actor's location (the kind becomes NOUN_PLACE), then
    among all objects (AllMode ANY). Found: it becomes the noun and the command
    is refused with "You cannot ..." (StartPerform). None: "I do not see
    {THING} here" with the phrase's address as the {THING}. O: A = 0, Z."""
    phrase = r.hl
    objects.SeekActorExits()
    r.a = NOUN_PLACE
    mem[r.bc] = r.a
    objects.FindExitByName()
    r.cp(END_MARK)
    if r.zf:
        r.hl = phrase
        r.a = v.AllMode = ALL_MODE_ANY
        r.ix = ObjectTable - 3
        _xor_a()
        mem[r.bc] = r.a                          # the noun is an object
        printer.msg_args.append(r.hl)            # kept for the message
        objects.FindNextNamedObject()
        r.cp(END_MARK)
        if r.zf:
            SetPerformMode()
            r.hl = MsgIDoNotSeeHere
            await printer.PrintParserMessage()
            _xor_a()
            return
        r.hl = printer.msg_args.pop()
    mem[r.de] = r.a                              # the noun
    return await keys.StartPerform()


async def ReportNoNoun1():
    """The player typed a verb with no noun. Push the command record's words
    around the noun and the verb; nothing accepted: "I see nothing to ...";
    else save the record and ask "{verb} ... what ?". O: A = 0, Z."""
    PushWordsBefore()
    r.hl = v.RecWord1
    printer.msg_args.append(r.hl)
    r.hl = MsgISeeNothing
    r.a = v.RecWork3[0]
    _and_a()
    if r.zf:
        return await PrintReplyFail()
    r.a = v.RecWork6[0]
    SaveParsedRecord()
    r.hl = MsgWhat3
    return await PrintReplyFail()


async def ReportNoSecondNoun():
    """No second noun phrase was typed. Push the words after the noun, a
    blank, the name of FirstObject, the words before it and the verb; nothing
    could serve: "I see nothing to ..."; else save the record and ask
    "... what ?". O: A = 0, Z."""
    PushWordsAfter()
    printer.msg_args.append(0)                   # a blank word
    r.a = v.FirstObject
    keys.ObjectNamePtr()
    printer.msg_args.append(r.hl)
    PushWordsBefore()
    r.hl = v.RecWord1
    printer.msg_args.append(r.hl)
    r.hl = MsgISeeNothing2
    r.a = v.RecWork3[1]
    _and_a()
    if r.zf:
        return await PrintReplyFail()
    r.a = v.RecWork6[1]
    SaveParsedRecord()
    r.hl = MsgWhat2
    return await PrintReplyFail()


def PushWordsAfter():
    """Push the words of the command record (RecPtr3) that follow the noun
    (see PushWordsBefore; the tests are set to JR Z)."""
    r.a = JR_Z
    return PushWords_SetTests()


def PushWordsBefore():
    """Push the words of the command record (RecPtr3) that precede the noun:
    the word at +4 is kept when bit 7 of (+7) is set, the word at +2 when bit
    5 of its high byte is set, else 0 is pushed. The test is self-modifying:
    the opcode in SmcKeepWord4/SmcKeepWord2 is JR NZ ($20) here, JR Z ($28)
    for PushWordsAfter. The asm swaps the words in under its return address;
    here they go on printer.msg_args, +4 first, then +2 on top."""
    r.a = JR_NZ
    return PushWords_SetTests()


def PushWords_SetTests():
    """(Entry point inside PushWordsBefore) Write the opcode A into the two JR
    instructions and push the two words. IX = RecPtr3. Z/NZ is the last BIT."""
    mem[SmcKeepWord4] = r.a
    mem[SmcKeepWord2] = r.a
    r.ix = v.RecPtr3
    r.hl = mem16[_ix(4)]
    r.zf = not mem[_ix(7)] & 0x80
    if not _jr_taken(mem[SmcKeepWord4]):
        r.hl = 0                                 # the flag says skip: no word
    printer.msg_args.append(r.hl)
    r.hl = mem16[_ix(2)]
    r.zf = not r.h & 0x20
    if not _jr_taken(mem[SmcKeepWord2]):
        r.hl = 0
    printer.msg_args.append(r.hl)


def _jr_taken(opcode):
    """Does the JR (NZ or Z, the opcode in memory) after BIT jump?"""
    assert opcode in (JR_NZ, JR_Z), opcode
    return r.zf if opcode == JR_Z else not r.zf


async def ReportUnknownVerb():
    """A command record matched the start of the phrase only: push RecWord3,
    RecWord2 and RecWord1 and print "I do not know the verb ..."."""
    for word in (v.RecWord3, v.RecWord2, v.RecWord1):
        r.hl = word
        printer.msg_args.append(r.hl)
    r.hl = MsgIDoNotKnowVerb
    return await PrintReplyFail()


# ---------------------------------------------------------------------------
# Orders given with SAY TO

def ClaimOrderSlots():
    """Give the first A of the pending order slots (at most OrderSlotCount) to
    FirstObject (the character addressed) and free the other pending ones.
    BC, DE, IX are kept."""
    bc, ix, de = r.bc, r.ix, r.de
    r.b = r.a
    r.a = v.OrderSlotCount
    r.c = r.a
    r.cp(r.b)
    if r.cf:
        r.b = r.a                                # B = min(A, count)
    r.a = r.c - r.b & 0xFF
    r.c = r.a                                    # the slots to free
    r.ix = OrderSlots - ORDER_SLOT_SIZE
    r.de = ORDER_SLOT_SIZE
    r.a = 0
    r.cp(r.b)
    if not r.zf:
        while True:
            while True:                          # the next pending slot
                r.ix = r.ix + r.de & 0xFFFF
                r.a = mem[_ix(0)]
                r.cp(FLAG_SLOT_PENDING)
                if r.zf:
                    break
            r.a = v.FirstObject
            mem[_ix(0)] = r.a                    # it belongs to the addressed actor
            r.b = r.b - 1 & 0xFF
            if not r.b:
                break
    r.b = r.c
    r.a = 0
    r.cp(r.b)
    if not r.zf:
        while True:
            while True:
                r.ix = r.ix + r.de & 0xFFFF
                r.a = mem[_ix(0)]
                r.cp(FLAG_SLOT_PENDING)
                if r.zf:
                    break
            mem[_ix(0)] = 0                      # become free
            r.b = r.b - 1 & 0xFF
            if not r.b:
                break
    r.de, r.ix, r.bc = de, ix, bc


def FindOrderSlot():
    """Find the order slot whose owner is Subject. O: Z and HL = the slot if
    found; else NZ and HL = past the table (OrderSlots + 8 * 25); A = Subject;
    B, DE destroyed."""
    r.hl = OrderSlots
    r.de = ORDER_SLOT_SIZE
    r.a = v.Subject
    r.b = ORDER_SLOTS
    while True:
        r.cp(mem[r.hl])
        if r.zf:
            return
        r.hl = r.hl + r.de & 0xFFFF
        r.b = r.b - 1 & 0xFF
        if not r.b:
            return


def FindOrderSlotKeep():
    """FindOrderSlot with HL, DE, BC kept. O: Z if Subject owns an order slot."""
    hl, de, bc = r.hl, r.de, r.bc
    FindOrderSlot()
    r.hl, r.de, r.bc = hl, de, bc


async def RunStoredOrder():
    """Take the stored order of Subject: free its slot; with A = 0 stop there
    (O: A = 1, NZ, HL = the stored record). Otherwise parse the record as if
    typed (InputFromOrder = 1, MatchSentence, VerbAllFlag kept) and run the
    check; a failed parse or a refused check frees all the character's slots
    (FreeOrderSlots). O: NZ usable order (the command is in CommandId,
    FirstObject, SecondObject), Z none (A = 0). All other registers kept. If
    Subject owns no slot HL is past the table and the zero goes to PhraseStack."""
    saved = r.ix, r.iy, r.bc, r.de, r.hl
    r.c = r.a
    FindOrderSlot()
    mem[r.hl] = ORDER_SLOT_FREE                  # the slot is taken
    r.hl = r.hl + 1 & 0xFFFF
    r.a = 0
    r.cp(r.c)
    if r.zf:
        record = r.hl
        _or_a(1)
        r.ix, r.iy, r.bc, r.de, r.hl = saved
        r.hl = record
        return
    r.iy = r.hl
    r.a = v.InputFromOrder = 1
    r.a = v.VerbAllFlag
    pushed = r.a, r.zf, r.cf, r.sf, r.pf         # PUSH AF
    await MatchSentence()
    r.ex_af()                                    # keep MatchSentence's A and flags
    _xor_a()
    v.InputFromOrder = 0
    r.a, r.zf, r.cf, r.sf, r.pf = pushed         # POP AF
    v.VerbAllFlag = r.a
    r.ex_af()
    allowed = False
    if not r.zf:
        await RunCheck()
        allowed = not r.zf
    if not allowed:
        r.a = v.Subject
        FreeOrderSlots()
        _xor_a()
    r.ix, r.iy, r.bc, r.de, r.hl = saved


def FreeOrderSlots():
    """Set the owner of every order slot owned by A to 0 (free). HL, DE, BC kept."""
    hl, de, bc = r.hl, r.de, r.bc
    r.hl = OrderSlots
    r.de = ORDER_SLOT_SIZE
    r.b = ORDER_SLOTS
    while True:
        r.cp(mem[r.hl])
        if r.zf:
            mem[r.hl] = 0
        r.hl = r.hl + r.de & 0xFFFF
        r.b = r.b - 1 & 0xFF
        if not r.b:
            break
    r.hl, r.de, r.bc = hl, de, bc
