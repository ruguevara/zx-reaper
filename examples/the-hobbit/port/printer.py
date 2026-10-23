"""Ported from src/printer.asm: the message interpreter: control codes, names, articles, dictionary words.
Values pass in the registers `r` (port/regs.py); conventions: port/CONTRACT.md."""
from labels import *  # noqa: F403  (first: port functions shadow routine labels)
import calls
import keys
import objects
import screen
from regs import r
from variables import v
from zxpyxel import Goto, mem, mem16, zx  # noqa: F401

# The message argument stack (CONTRACT.md): what a caller pushed below the
# return addresses for the control codes 0, 1, 4 and 19. A PUSH AF (code 19)
# is the A value, an int. ponytail: a code inside a sub-message (code 11) would
# find the caller's HL there in the asm; the game never does that.
msg_args = []


def _word_end():
    r.a = 0
    r.zf, r.cf = True, False


async def PrintMessageChar():
    """Print the character in A; a carriage return also clears CapitalNext
    (the next word starts a fresh line). Leaves Z for a carriage return."""
    await screen.PrintChar()
    r.cp(CHAR_CR)
    if not r.zf:
        return
    v.CapitalNext = 0
    _word_end()


async def PrintCannotDoThat():
    """Print "I cannot do that."; as PrintMessage."""
    r.hl = MsgICannotDoThat
    return await PrintMessage()


async def PrintParserMessage():
    """The parser's PrintMessage: while an order is being parsed, the message
    first marks the command as refused (ActionPerform = 0). Note A is lost:
    the asm loads InputFromOrder into A, so SavedA (and A on return) is 0."""
    r.a = r.set_zs(v.InputFromOrder)
    if r.zf:
        return await PrintMessage()
    r.a = 0
    v.ActionPerform = 0
    return await PrintMessage()


async def PrintMessage():
    """Print the message at HL in the story window (input window when
    RawOutputFlag is set). A, DE and IX are saved in SavedA/DE/IX and given
    back by the ending; HL is not kept. During a test pass of a command
    (ActionPerform = 0) any message sets ActionAllowed to 0 first."""
    v.SavedDE = r.de
    v.SavedIX = r.ix
    v.SavedA = r.a
    r.a = r.set_zs(v.ActionPerform)
    if r.zf:
        v.ActionAllowed = 0
    return await PrintMessageAt()


async def PrintMessageAt():
    """Print the message at HL (without saving the registers) up to its ending."""
    r.ix = r.hl
    return await _print_items()


def _load_common_word():
    """Word token of the common word item in A ($60-$7F): DE = CommonWordTable
    entry with print mode WORD_PLAIN (no ending)."""
    r.a = r.a - ITEM_COMMON_WORD & 0xFF
    entry = CommonWordTable + 2 * r.a & 0xFFFF
    r.e = mem[entry]
    r.a = mem[entry + 1] + WORD_PLAIN & 0xFF
    r.d = r.a


async def _print_items():
    """The item loop of the interpreter (PrintMessage_Item, PrintMessage_Next):
    word items, literal characters, common words and control codes, until an
    ending item returns to the caller of the message printer."""
    while True:
        a = r.a = mem[r.ix]
        if a & 0x80:                                    # a two-byte word item
            r.d = a & 0x7F
            r.e = mem[r.ix + 1 & 0xFFFF]
            r.ix = r.ix + 1 & 0xFFFF
            r.a = r.d & 0xF0
            if r.a in (WORD_END_STOP, WORD_END_PLAIN, WORD_END_NEWLINE):
                return await PrintEndingWord()
        elif a < CHAR_SPACE:                            # a control code
            handler = r.hl = mem16[ControlCodeTable + 2 * a]
            if a >= CODE_FIRST_END:
                return await calls.call_at(handler)     # an ending: jumped to
            await calls.call_at(handler)
            if r.zf:                                    # it printed what it wanted
                r.ix = r.ix + 1 & 0xFFFF
                continue
        elif a >= ITEM_COMMON_WORD:
            _load_common_word()
        else:                                           # a literal character
            await PrintMessageChar()
            r.ix = r.ix + 1 & 0xFFFF
            continue
        await PrintWord()
        r.ix = r.ix + 1 & 0xFFFF


async def PrintMessage_Word():
    """Print the word token in DE, then go on with the message at the next item."""
    await PrintWord()
    r.ix = r.ix + 1 & 0xFFFF
    return await _print_items()


async def EndNewLine():
    """Control code $14: end the message with a new line."""
    r.d = 0x60
    return await EndMessage()


async def EndFullStop():
    """Control code $15: end the message with a full stop and a new line."""
    r.d = 0x30
    return await EndMessage()


async def PrintEndingWord():
    """End a message with a closing word (DE, print modes 2, 3 and 6):
    print it, then the ending its mode asks for, and restore A, DE and IX."""
    await PrintWord()
    return await EndMessage()


async def EndMessage():
    """(Entry point inside PrintEndingWord) End the message as D says: bit 6 a
    new line only, bit 4 a full stop and a new line; restore A, DE and IX."""
    r.a = ord('.')
    if r.d & 0x40:
        await screen.PrintNewLine()
    else:
        if r.d & 0x10:
            await screen.PrintChar()
        if r.d & 0x10:
            await screen.PrintNewLine()
    return PrintEndingWord_1()


def PrintEndingWord_1():
    """Control code $16: end the message; restore A, DE and IX of the caller."""
    r.de = v.SavedDE
    r.ix = v.SavedIX
    r.a = v.SavedA


async def PrintStackedName():
    """Control code 0: print the name phrase whose address the caller pushed
    (0 for none), without an article. Leaves A = 0, Z."""
    v.PhraseMode = 0
    r.hl = msg_args.pop()
    if r.hl:
        await PrintPhraseAtHL()
    _word_end()


def PrintStackedWord():
    """Control code 1: DE = the word token the caller pushed; NZ."""
    r.de = msg_args.pop()
    r.a |= 1
    r.zf = False


def MessageJump():
    """Control code 2: IX += the signed displacement byte after the code;
    the loop's next step passes the displacement byte. Z."""
    e = mem[r.ix + 1 & 0xFFFF]
    r.e, r.d = e, 0xFF if e & 0x80 else 0
    r.ix = r.ix + r.de & 0xFFFF
    return MessageJump_1()


def MessageJump_1():
    """Control codes 5, 10, 15, 18: nothing to print. A = 0, Z."""
    _word_end()


def L738D():
    """Control code 3 (never run): DE = TargetNamePtr; NZ."""
    r.de = v.TargetNamePtr
    r.a |= 1
    r.zf = False


async def PrintStackedWordArticle():
    """Control code 4: print the word token the caller pushed, with an article."""
    r.de = msg_args.pop()
    r.a = v.PhraseMode = 1
    await PrintNounWord()
    _word_end()


async def PrintSubjectName():
    """Control code 6: print the name of the subject (Subject) without an article."""
    r.a = v.PhraseMode = 0
    return await PrintSubjectNameAsIs()


async def PrintSubjectNameAsIs():
    """(Entry point inside PrintSubjectName) The same, PhraseMode as it is."""
    r.a = v.Subject
    await PrintActorName()
    _word_end()


async def PrintFirstObjectName():
    """Control code 7: print the name of the first object with an article."""
    r.a = v.PhraseMode = 1
    return await PrintFirstObjectNameAsIs()


async def PrintFirstObjectNameAsIs():
    """(Entry point inside PrintFirstObjectName) The same, PhraseMode as it is.
    Noun1Kind not 0: FirstObject is a location id."""
    r.a = r.set_zs(v.Noun1Kind)
    r.cf = False
    r.a = v.FirstObject
    return await PrintSecondObjectName_0()


async def L73BD():
    """Control code 8 (never run): print the character in A; Z."""
    await screen.PrintChar()
    _word_end()


async def PrintSecondObjectName():
    """Control code 9: print the name of the second object with an article."""
    r.a = v.PhraseMode = 1
    return await PrintSecondObjectNameAsIs()


async def PrintSecondObjectNameAsIs():
    """(Entry point inside PrintSecondObjectName) The same, PhraseMode as it is.
    Noun2Kind not 0: SecondObject is a location id."""
    r.set_zs(v.Noun2Kind)
    r.cf = False
    r.a = v.SecondObject
    return await PrintSecondObjectName_0()


async def PrintSecondObjectName_0():
    """(Entry point inside PrintSecondObjectName) Print the name of the object
    or, with Z clear, the location with id A. HL kept; A = 0, Z."""
    if r.zf:
        return await PrintNameOfObject()
    hl = r.hl
    keys.LocationNamePtr()
    await PrintPhraseAtHL()
    r.hl = hl
    _word_end()


async def PrintNameOfObject():
    """(Entry point inside PrintSecondObjectName) Print the name phrase of the
    object or character A. HL kept; A = 0, Z."""
    hl = r.hl
    keys.ObjectNamePtr()
    await PrintPhraseAtHL()
    r.hl = hl
    _word_end()


async def MessageCall():
    """Control code 11: print the message at the signed displacement after the
    code, then go on after the displacement byte. Z."""
    r.ix = r.ix + 1 & 0xFFFF
    at = r.hl = r.ix
    e = mem[at]
    r.e, r.d = e, 0xFF if e & 0x80 else 0
    r.hl = at + r.de & 0xFFFF
    await PrintMessageAt()
    r.ix = at
    _word_end()


def L73F9():
    """Control code 12 (never run): "his" or "your" for the subject."""
    r.a = v.Subject
    return HisOrYour()


def HisOrYour():
    """DE = the word token for "his" (actor A not the player, NZ) or "your"."""
    r.de = 0x0990
    r.set_zs(r.a)
    if r.zf:
        r.de = 0x0BEA
        r.a |= 1
        r.zf = False


def HisYourFirstObject():
    """Control code 14: "his" or "your" for the actor FirstObject."""
    r.a = v.FirstObject
    return HisOrYour()


async def PrintSubjectIs():
    """Control code 16: print the subject's name, then DE = "are" for the
    player, "is" for anyone else; NZ."""
    r.a = v.Subject
    r.ex_af()
    r.a = 0
    return await PrintActorIs()


async def PrintActorIs():
    """(Entry point inside PrintSubjectIs) A = PhraseMode, A' = actor id."""
    v.PhraseMode = r.a
    r.ex_af()
    actor = r.a
    await PrintActorName()
    r.a = actor
    r.set_zs(actor)
    r.de = 0x039B                                       # "is"
    if r.zf:
        r.de = 0x0065                                   # "are"
        r.a |= 1
        r.zf = False


async def L7425():
    """Control code 17 (never run): as PrintNameIs for FirstObject."""
    r.a = v.FirstObject
    return await PrintNameIs()


async def PrintNameIs():
    """Print the name of actor A with its article, then DE = "are" (the
    player) or "is"; NZ."""
    r.ex_af()
    r.a = 1
    return await PrintActorIs()


async def PrintNameIsFromStack():
    """Control code 19: as PrintNameIs for the id the caller pushed."""
    r.a = msg_args.pop()
    return await PrintNameIs()


async def PrintPhraseAtHL():
    """Print the name phrase at HL (via IY, which is kept)."""
    iy = r.iy
    r.iy = r.hl
    await objects.PrintNamePhrase()
    r.iy = iy


async def PrintArticle():
    """Print the article of the noun code DE ("the", "a", "an", "some"; the
    input window and the command echo use "the"). A proper name has none: it
    sets CapitalNext, and "you" does nothing. E is left as RawOutputFlag on
    the common path."""
    if r.d & 0x80:
        r.a, r.hl = r.e, WORD_YOU
        r.cp(WORD_YOU & 0xFF)
        if r.zf:
            r.a = r.d & 0x0F
            r.cp(WORD_YOU >> 8)
            if r.zf:
                return
        r.a = 1
        v.CapitalNext = 1
        return
    r.hl = ArticleTable
    r.e = v.RawOutputFlag
    if v.EchoingCommand | r.e:
        r.hl = ArticleTableInput
    r.a = r.d >> 3 & 0x1E
    de = r.de
    r.hl = r.hl + r.a & 0xFFFF
    r.e = mem[r.hl]
    r.hl = r.hl + 1 & 0xFFFF
    r.d = mem[r.hl]
    await PrintWord()
    r.de = de


async def PrintNounWord():
    """Print the noun code DE (article first when PhraseMode is not 0), with
    its style bits cleared. D leaves with the style bits cleared."""
    de = r.de
    r.a = r.set_zs(v.PhraseMode)
    if not r.zf:
        await PrintArticle()
    r.de = de
    r.a = r.d & 0x0F
    r.d = r.a
    return await PrintWord()


async def PrintActorName():
    """Print the name of actor A (NO_ACTOR: "someone", the player: "you")."""
    r.cp(NO_ACTOR)
    if not r.zf:
        return await PrintNameOfObject()
    r.de = WORD_SOMEONE
    return await PrintWord()


async def PrintCommonWord():
    """Print the common word item A ($60-$7F) of a message, then go on."""
    _load_common_word()
    return await PrintMessage_Word()


async def PrintWordAtHL():
    """Print the word code at HL (offset low byte, high byte without the print
    mode); HL leaves after the code."""
    r.e = mem[r.hl]
    r.a = mem[r.hl + 1 & 0xFFFF]
    r.hl = r.hl + 2 & 0xFFFF
    r.d = r.a & 0x0F
    return await PrintWord()


async def PrintWord():
    """Print the dictionary word of code DE (bits 0-11 offset, 0 prints
    nothing; bits 12-15 print mode: ending, capital). The letters go to
    WordBuffer, a verb's ending is added, then a space (not at the start of a
    story line), a new line if the word does not fit, and the letters through
    PrintChar. HL, BC, DE are kept; A = the last character."""
    de = r.de
    r.a = (de >> 8 & 0x0F) | (de & 0xFF)
    r.zf = r.a == 0
    if r.zf:
        return
    hl_in, bc_in = r.hl, r.bc
    mode_byte = de >> 8
    hl = Vocabulary + (de & 0x0FFF)
    start, buf, n = hl, WordBuffer, 0
    while True:                                         # PrintWord_Letter
        x = mem[hl]
        if x & 0x1F == 0:
            break
        n += 1
        mem[buf] = (x & 0x1F) + LETTER_BASE & 0xFF
        buf += 1
        hl += 1
        if not x & 0x80:
            continue
        if n == 2:                                      # bit 7 on byte 2: more bytes follow
            continue
        if n != 3:
            break
        if mem[hl - 2] & 0x80:                          # a verb flag on byte 2
            continue
        break
    mode = mode_byte & 0xF0
    if mode == WORD_PLAIN:
        ending = False
    elif mode == WORD_SUFFIX:
        ending = True
    else:
        ending = bool(v.FirstObject if mode == WORD_SUFFIX_OBJ1 else v.Subject)
    if ending and mem[start + 1] & 0x80:                # the word takes an ending
        e = WordEndings + ((mem[start + 2] & 0xE0) >> 3)
        for k in range(WORD_ENDING_SIZE):
            if mem[e + k] == 0:
                break
            mem[buf] = mem[e + k]
            buf += 1
    length = buf - WordBuffer & 0xFF
    raw = v.RawOutputFlag
    if raw or v.StoryLastChar:
        r.a = CHAR_SPACE
        await screen.PrintChar()
    columns = v.InputColumn if raw else v.StoryColumn
    if columns < length:                                # it does not fit: a new line,
        capital = v.CapitalNext                         # the capital flag kept over it
        await screen.PrintNewLine()
        v.CapitalNext = capital
    if mode_byte & 0xF0 == WORD_CAPITAL:
        v.CapitalNext = 1
    for k in range(length or 256):                      # (a 0-length word would print 256)
        r.a = mem[WordBuffer + k & 0xFFFF]
        await screen.PrintChar()
    r.hl, r.bc, r.de = hl_in, bc_in, de
    zx.spend(60 * n + 300)
