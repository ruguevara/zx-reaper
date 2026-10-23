"""Ported from src/keys.asm: typed words to tokens, the command table helpers, WaitKey and the WAIT time-out.
Values pass in the registers `r` (port/regs.py); conventions: port/CONTRACT.md."""
from labels import *  # noqa: F403  (first: port functions shadow routine labels)
import calls  # noqa: F401
import devices
import engine
import main
import objects
import printer
import screen
from regs import r
from variables import v
from zxpyxel import Goto, mem, mem16, zx  # noqa: F401


async def CursorKeyToWord():
    """First key of a line: a cursor key becomes the one-letter direction
    command (up N, down S, right E, left W), echoed in the input window, with
    a CR stored after it. I: A key, HL buffer pointer, B free bytes. O: A CR
    when converted (else the key), HL two further on, B two fewer, NZ."""
    letters = {KEY_RIGHT: 'E', KEY_LEFT: 'W', KEY_DOWN: 'S', KEY_UP: 'N'}
    if r.a not in letters:
        r.cp(KEY_UP)                               # the last compare of the chain: NZ
        return
    hl, b = r.hl, r.b
    mem[hl] = r.a = ord(letters[r.a])
    r.hl = hl + 1 & 0xFFFF
    await screen.PrintChar()
    hl += 1
    mem[hl & 0xFFFF] = r.a = CHAR_CR               # end of line, not echoed here
    r.hl, r.b = hl + 1 & 0xFFFF, b - 2 & 0xFF
    r.zf = r.cf = r.sf = r.pf = False              # OR 1 on $0D


async def L6E7A():
    """The "@" key on an empty line: unless an answer is awaited, rub out the
    prompt "> " and leave Z with A = 0 so the caller parses the old word list
    again; while an answer is awaited the key is ignored and ReadLine_Key goes
    on reading."""
    if v.AwaitingAnswer:
        return await main.ReadLine_Key()
    r.a = CHAR_BACKSPACE
    await screen.PrintChar()
    await screen.PrintChar()
    r.a = 0
    r.zf, r.cf = True, False


async def EraseInputLine():
    """Back up over everything typed: a back-space for each character. I: HL
    after the last character, B free bytes ($80 empty). O: B = $80, HL back
    at the start of the buffer, NZ."""
    hl, b = r.hl, r.b
    while not b & 0x80:
        r.a = CHAR_BACKSPACE
        await screen.PrintChar()
        b += 1
        hl -= 1
    r.hl, r.b = hl & 0xFFFF, b & 0xFF
    r.zf = False                                   # BIT 7,B on a set bit


def ReadTypedWord():
    """Skip spaces and make one token of the next typed word: CR gives
    TOKEN_END, . , " their punctuation tokens, anything else is looked up in
    the dictionary (TOKEN_UNKNOWN when it matches nothing). InputLinePtr is
    set to the start of the word. I: HL typed line. O: A = D class nibble, B
    class + offset bits 8-11, C offset bits 0-7, HL after the word (also when
    unknown), E kept."""
    e = r.e
    hl = r.hl
    while mem[hl] == CHAR_SPACE:
        hl = hl + 1 & 0xFFFF
    v.InputLinePtr = hl
    r.hl, r.a = hl, mem[hl]
    token = None
    if r.a == CHAR_CR:
        token = TOKEN_END
    else:
        ScanPunctuation()
        if r.zf:
            token = r.a                            # BC = 0 already
        else:
            L6F47()
            if not r.zf:
                token = TOKEN_UNKNOWN              # no entry for the first letter
    if token is not None:
        r.bc = 0
        return _TokenDone(token, e)
    after_word = r.hl
    while True:
        CompareWords()
        if r.zf:                                   # same as far as the shorter goes
            if v.MatchLength >= v.WordLength:
                return _Accept(after_word, e)      # the entry is not shorter
            if v.MatchLength >= 4:              # typed word longer: a better entry?
                ix = r.ix
                TestWordEntry_Compare()
                if r.zf:
                    CompareWords()
                if not r.zf:
                    r.ix = ix
                    return _Accept(after_word, e)
                r.ix = ix                          # it matches too: it becomes the candidate
        TestWordEntry()
        if not r.zf:
            r.hl = after_word                      # none left: unknown word
            r.bc = 0
            return _TokenDone(TOKEN_UNKNOWN, e)


def _TokenDone(token, e):
    """ReadTypedWord_Done: D = class, B = class + offset bits 8-11."""
    r.d, r.e = token, e
    r.b = token + r.b & 0xFF
    r.a = token


def _Accept(after_word, e):
    """ReadTypedWord_Accept: the entry of SourceTextPtr (or the word its
    synonym bytes point to) gives the token."""
    ix = r.ix = v.SourceTextPtr
    entry = ix
    n = 0
    while True:                                    # find the last byte of the entry
        ix += 1
        n += 1
        if not mem[ix - 1 & 0xFFFF] & 0x80:
            continue
        if n == 2:                                 # byte 2 never ends an entry
            continue
        if n == 3 and mem[ix - 2 & 0xFFFF] & 0x80:  # byte 3 does not, after a verb flag in byte 2
            continue
        break
    r.ix = ix & 0xFFFF
    if mem[ix - 1 & 0xFFFF] & 0x40:                # synonym: use the entry it stands for
        entry = Vocabulary + mem16[ix & 0xFFFF] & 0xFFFF
    cls = (mem[entry] << 1 & 0xC0) + (mem[entry + 1 & 0xFFFF] >> 1 & 0x30)
    r.bc = entry - Vocabulary & 0xFFFF
    r.a = cls
    r.hl = after_word
    return _TokenDone(cls, e)


def ScanPunctuation():
    """A full stop is TOKEN_THEN, a comma TOKEN_AND, a double quote
    TOKEN_QUOTE. I: A character, HL its address. O: Z and A the token, HL
    after it, BC = 0 for punctuation; NZ with A unchanged otherwise."""
    tokens = {ord('.'): TOKEN_THEN, ord(','): TOKEN_AND, ord('"'): TOKEN_QUOTE}
    if r.a not in tokens:
        r.b = TOKEN_AND                            # B as the asm leaves it
        r.cp(ord('"'))
        return
    r.hl = r.hl + 1 & 0xFFFF
    r.a = tokens[r.a]
    r.bc = 0
    r.zf, r.cf = True, False                       # from the CP that matched


def L6F47():
    """Copy the letters (5 bits each) of the typed word at HL into
    WordLetters, count them in WordLength, take the first dictionary entry
    for its first letter from the index at Vocabulary, then test it
    (TestWordEntry). O: HL after the word, IX the entry, NZ when the first
    letter has no entry."""
    hl, de, b = r.hl, WordLetters, 0
    while mem[hl] >= 0x40:                         # no limit on the length (asm)
        mem[de & 0xFFFF] = mem[hl] & 0x1F
        de += 1
        hl += 1
        b += 1
    v.WordLength = b
    first = mem[WordLetters]
    r.ix = Vocabulary + mem16[Vocabulary + 2 * first & 0xFFFF] & 0xFFFF
    r.hl = hl & 0xFFFF
    return TestWordEntry()


def TestWordEntry():
    """Remember the entry at IX in SourceTextPtr and test it (as
    TestWordEntry_Compare)."""
    v.SourceTextPtr = r.ix
    return TestWordEntry_Compare()


def TestWordEntry_Compare():
    """Test the dictionary entry at IX against the typed word: NZ when its
    first letter differs (no more candidates). Otherwise decode its letters
    into MatchLetters (count in MatchLength), move IX past the entry (and past
    the two bytes of a synonym, then A = 0) and return Z. HL is kept."""
    ix = r.ix
    r.b = mem[ix] & 0x1F
    r.a = mem[WordLetters]
    r.cp(r.b)
    if not r.zf:
        return
    hl, b, c = MatchLetters, 0, 0
    while True:
        a = mem[ix & 0xFFFF] & 0x1F
        if a:
            mem[hl] = a
            hl += 1
            b += 1
        ix += 1
        c += 1
        if not mem[ix - 1 & 0xFFFF] & 0x80:
            continue
        if c == 2:                                 # byte 2 is never the last
            continue
        if c == 3 and mem[ix - 2 & 0xFFFF] & 0x80:  # byte 3 goes on after a verb flag in byte 2
            continue
        break
    r.b, r.c, r.a = b, c, b
    v.MatchLength = b
    r.zf = not mem[ix - 1 & 0xFFFF] & 0x40         # BIT 6: Z unless a synonym
    if not r.zf:
        ix += 2
        r.a = 0
        r.zf = True                                # XOR A
    r.ix = ix & 0xFFFF


def CompareWords():
    """Compare WordLetters with MatchLetters over the shorter length; Z when
    one is a prefix of the other. O: A last letter compared, B remaining
    count (0 when Z), HL and DE after the letters compared."""
    r.b = min(v.WordLength, v.MatchLength)
    r.hl, r.de = WordLetters, MatchLetters
    while True:                                    # B = 0 would compare 256 letters (asm)
        r.a = mem[r.de]
        r.cp(mem[r.hl])
        if not r.zf:
            return
        r.de, r.hl = r.de + 1 & 0xFFFF, r.hl + 1 & 0xFFFF
        r.b = r.b - 1 & 0xFF
        if not r.b:
            return


def ClearScreen():
    """White border, bitmap zeroed, attributes black on white; the attribute
    fill runs one byte past the attributes (sets $5B00 too). BC, DE, HL kept."""
    zx.out(PORT_ULA, BORDER_WHITE)
    mem[SCREEN:SCREEN + SCREEN_BITMAP_SIZE + 1] = bytes(SCREEN_BITMAP_SIZE + 1)
    mem[SCREEN + SCREEN_BITMAP_SIZE:SCREEN + SCREEN_BITMAP_SIZE + ATTRS_SIZE + 1] = \
        bytes([WHITE * PAPER + BLACK]) * (ATTRS_SIZE + 1)
    zx.spend(21 * (SCREEN_BITMAP_SIZE + ATTRS_SIZE))


def ClearBytes():
    """Zero B bytes from HL (B = 0 means 256). O: HL after the block, A = B =
    0, Z."""
    n = r.b or 256
    for k in range(n):
        mem[r.hl + k & 0xFFFF] = 0
    r.hl, r.a, r.b = r.hl + n & 0xFFFF, 0, 0
    r.zf, r.cf = True, False


def CommandRecordAddr():
    """HL = address of the 8-byte command table record of command id A (ids
    start at 1). DE is destroyed."""
    r.de = CommandTable - COMMAND_RECORD_SIZE & 0xFFFF
    total = (r.a << 3) + r.de
    r.cf = total > 0xFFFF
    r.hl = total & 0xFFFF


def PackCommandFlags():
    """Pack the top nibbles of the record's high bytes: StateB71E = (+7 hi <<
    4) + (+5 hi), StateB71D = (+3 hi << 4) + (+1 hi). I: IX record. O: A =
    StateB71D, C the nibble of +1."""
    ix = r.ix
    c = mem[ix + 5 & 0xFFFF] >> 4
    v.StateB71E = (mem[ix + 7 & 0xFFFF] & 0xF0) + c
    c = mem[ix + 1 & 0xFFFF] >> 4
    r.c = c
    r.a = v.StateB71D = (mem[ix + 3 & 0xFFFF] & 0xF0) + c


async def StartPerform():
    """Perform the command: ActionAllowed 0, ActionPerform 1, and print the
    command as a sentence unless it comes from a stored order. O: A = 0, Z."""
    v.ActionAllowed = 0
    v.ActionPerform = 1
    if not v.InputFromOrder:
        await PrintCommandSentence()
    r.a = 0
    r.zf, r.cf = True, False


async def PrintCommandSentence():
    """Write the chosen command as a sentence ("You take the short strong
    sword.", "Gandalf cannot take the chest."): subject, "cannot" when refused,
    the word at record +6, the verb, the first noun with the prepositions the
    record's flags place before it, the other prepositions and the second
    noun, a full stop and a new line. Silent commands print nothing. An
    allowed command goes to the story window, a refused one to the input
    window (RawOutputFlag is left so). IY, BC, IX, HL, DE are kept. O: A = 0, Z."""
    saved = r.iy, r.bc, r.ix, r.hl, r.de
    v.EchoingCommand = 1                           # the article printer uses its command table
    v.PhraseMode = 0
    allowed = v.ActionAllowed
    v.RawOutputFlag = 0 if allowed else 1
    r.a = v.CommandId
    CommandRecordAddr()
    rec = hl = r.ix = r.hl
    if allowed and v.Subject == 0:
        await screen.PrintNewLine()                # the player acts: start on a new line
    PackCommandFlags()
    c = r.c = r.a
    if not c >> CMDF_SILENT & 1:
        await printer.PrintSubjectNameAsIs()
        if not allowed:
            r.de = WORD_CANNOT
            await printer.PrintWord()
        r.hl = rec + 6 & 0xFFFF                    # the word at +6, usually empty
        await printer.PrintWordAtHL()
        r.ix = rec                                 # CheckDark keeps IX, IY, BC
        engine.CheckDark()
        hl = rec
        if r.cf and v.CommandId < CMD_FIRST_OTHER:
            r.de = WORD_SOMEWHERE                  # "go somewhere" in the dark
            hl = rec + 2 & 0xFFFF
            await printer.PrintWord()
        else:
            r.hl = hl
            await printer.PrintWordAtHL()          # the verb word
            hl = hl + 2 & 0xFFFF
        if c >> CMDF_NOUN1 & 1:
            if c >> CMDF_PREP1_BEFORE & 1:
                r.hl = hl
                await printer.PrintWordAtHL()      # "off", "out"
                hl = hl + 2 & 0xFFFF
            if v.StateB71E >> CMDG_PREP2_BEFORE & 1:
                r.hl = hl
                await printer.PrintWordAtHL()      # "of"
                hl = hl + 2 & 0xFFFF
            r.hl = hl
            await printer.PrintFirstObjectNameAsIs()
        if v.SecondObject != NO_OBJECT and c >> CMDF_NOUN2 & 1:
            if not c >> CMDF_PREP1_BEFORE & 1:
                r.hl = hl
                await printer.PrintWordAtHL()      # "to", "in"
                hl = hl + 2 & 0xFFFF
            if not v.StateB71E >> CMDG_PREP2_BEFORE & 1:
                r.hl = hl
                await printer.PrintWordAtHL()
                hl = hl + 2 & 0xFFFF
            r.hl = hl
            await printer.PrintSecondObjectNameAsIs()
        r.a = CHAR_FULLSTOP
        await screen.PrintChar()
        await screen.PrintNewLine()
    v.EchoingCommand = 0
    r.iy, r.bc, r.ix, r.hl, r.de = saved
    r.a = 0
    r.zf, r.cf = True, False


def LocationNamePtr():
    """HL = address of the name phrase codes of location A (record +2). IX kept."""
    ix = r.ix
    objects.FindLocation()
    r.hl = r.ix + 2 & 0xFFFF
    r.ix = ix


def ObjectNamePtr():
    """HL = address of the name phrase codes of object or character A (record
    +8). DE and IX kept."""
    de, ix = r.de, r.ix
    objects.FindObject()
    total = r.ix + 8
    r.hl = total & 0xFFFF
    r.cf = total > 0xFFFF
    r.de, r.ix = de, ix


def MatchCommandRecord():
    """Match a command table record (IY) against the parsed phrase (HL: three
    word tokens): the verb, then the two prepositions in order (A = 0) or
    swapped (A = 1). Sets PhraseMatched when the verb matches. Z when the
    record matches; DE, HL, IY kept."""
    de, hl, iy = r.de, r.hl, r.iy
    MatchWord()
    if r.zf:
        v.PhraseMatched = r.a = 1                  # the verb matched
        MatchWord()
        if r.zf:
            MatchWord()
            r.a = 0
            if r.zf:
                r.de, r.hl, r.iy = de, hl, iy
                return
        r.iy, r.hl = iy + 4 & 0xFFFF, hl + 2 & 0xFFFF   # try the two words swapped
        r.de = 0x0004
        MatchWord()
        if r.zf:
            r.de = 0xFFFC
            r.iy = r.iy - 4 & 0xFFFF
            MatchWord()
            r.a = 1
    r.de, r.hl, r.iy = de, hl, iy


def MatchWord():
    """Compare the word token at HL with the record word at IY: equal in the
    low 12 bits (the class nibble ignored); a token of 0 matches anything.
    O: Z on a match, HL and IY two on."""
    hl, iy = r.hl, r.iy
    r.a = r.set_zs(mem[hl] | mem[hl + 1 & 0xFFFF])
    r.cf = False
    if not r.zf:
        r.a = r.set_zs((mem[iy + 1 & 0xFFFF] ^ mem[hl + 1 & 0xFFFF]) & 0x0F)
        if r.zf:
            r.a = mem[hl]
            r.cp(mem[iy])
    r.hl, r.iy = hl + 2 & 0xFFFF, iy + 2 & 0xFFFF


async def WaitKey():
    """Scan the keyboard (ReadKey) until a key is newly pressed; the scans
    are counted down from IdleCounter. At 0 with no key the typed line is
    erased, WAIT is typed into the buffer and the input window and CR is
    returned as if ENTER were pressed. A key gives IDLE_SCANS_PER_KEY scans
    back, up to IDLE_SCANS_MAX. I: HL after the last typed character, B free
    bytes. O: A key (CR after the time-out), HL as before (after WAIT on a
    time-out), B $7C on a time-out."""
    saved_hl = r.hl
    counter = v.IdleCounter
    b, c, ix = r.b, r.c, r.ix
    while True:
        devices.ReadKey()
        r.b, r.c, r.ix = b, c, ix                  # ReadKey keeps them
        zx.spend(54)                               # CALL, AND A, JR NZ, DEC HL, LD A,H, OR L, JR NZ (ReadKey spends its own)
        if r.a:
            key, hl = r.a, saved_hl
            break
        counter = counter - 1 & 0xFFFF
        if counter:
            await zx.sync()
            continue
        r.hl = saved_hl                            # time-out
        await EraseInputLine()
        hl = r.hl
        for k in range(4):
            mem[hl] = r.a = mem[WaitText + k]
            hl += 1
            r.hl = hl & 0xFFFF
            await screen.PrintChar()
        key, b, hl = CHAR_CR, INPUT_LINE_SIZE - 4, hl & 0xFFFF
        counter = -IDLE_SCANS_PER_KEY & 0xFFFF     # so that the refill gives the full count
        break
    total = counter + IDLE_SCANS_PER_KEY
    carry, counter, de = total > 0xFFFF, total & 0xFFFF, IDLE_SCANS_MAX
    if carry or counter >= de:                     # wrapped, or not below the maximum
        counter, de = de, counter
    v.IdleCounter = counter
    r.a, r.hl, r.b, r.de = key, hl, b, de
    r.zf = r.cf = False


def CompareHLDE():
    """Compare HL with DE: Z when equal, carry when HL < DE. A destroyed."""
    r.a = r.h - r.d & 0xFF
    r.cf, r.zf = r.h < r.d, r.a == 0
    r.sf = r.a > 0x7F
    if not r.zf:
        return
    r.a = r.l - r.e & 0xFF
    r.cf, r.zf = r.l < r.e, r.a == 0
    r.sf = r.a > 0x7F
