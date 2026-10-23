"""Ported from src/main.asm: the start, the restart, the main loop and the
line editor. GameStart backs up the state and falls into RestartGame, which
waits for the title key, sets up and runs the opening LOOK, then MainLoop runs
forever. QUIT, death and tape errors jump back to RestartGame with the stack
dropped: they raise Goto(RestartGame) and GameStart's dispatch goes on there.
Values pass in the registers `r` (port/regs.py), as in the asm."""
from labels import *  # noqa: F403  (first: port functions shadow routine labels)
import engine
import keys
import objects
import parser
import printer
import screen
from regs import r
from variables import v
from zxpyxel import dispatch, mem, zx


def ldir(src, dst, n):
    """LDIR: copy n bytes from src to dst, a byte at a time, as the Z80 does;
    leaves HL, DE after the copy and BC = 0."""
    for k in range(n):
        mem[dst + k & 0xFFFF] = mem[src + k & 0xFFFF]
    r.hl, r.de, r.bc = src + n & 0xFFFF, dst + n & 0xFFFF, 0
    zx.spend(21 * n - 5)


async def GameStart():
    """Back up the objects and characters, the locations, the saved variables
    and the timers (QUIT and death restore them), then run the game."""
    zx.di()
    ldir(Chr00Player, StateBackup, STATE_OBJECTS_SIZE)
    ldir(Loc00None, r.de, STATE_LOCATIONS_SIZE)
    ldir(SavedScriptBytes, STATE_COPY, STATE_VARS_SIZE)
    ldir(Timers, r.de, STATE_TIMERS_SIZE)
    await dispatch(RestartGame)


async def RestartGame():
    """Restore the state, wait for the title key (N held: no pictures), seed
    the random numbers from R, set up the windows and the opening LOOK; then
    the main loop. Never returns."""
    zx.di()
    r.ix, r.a = PictureTable, 5
    objects.FindIdRecord()
    r.hl = mem[r.ix + 1] | mem[r.ix + 2] << 8      # picture 5's first two bytes
    mem[r.hl] = 0                                  # (zero already; reason unknown)
    r.hl = r.hl + 1 & 0xFFFF
    mem[r.hl] = 0
    ldir(StateBackup, Chr00Player, STATE_OBJECTS_SIZE)
    ldir(r.hl, Loc00None, STATE_LOCATIONS_SIZE)
    ldir(STATE_COPY, SavedScriptBytes, STATE_VARS_SIZE)
    ldir(r.hl, Timers, STATE_TIMERS_SIZE)
    r.a = 0
    zx.out(PORT_ULA, 0)                            # black border
    mem[BORDCR] = WHITE * PAPER + BLACK
    while True:                                    # WaitTitleKey
        zx.spend(41)
        await zx.sync()
        if zx.inp(PORT_ULA) & KEY_BITS != KEY_BITS:
            break
    v.PicturesEnabled = zx.inp(KB_ROW_SPACE_B << 8 | PORT_ULA) & KEY_N
    v.InputCursor = SCREEN_ROW_23
    v.InputCursorGlyph = CURSOR_GLYPH
    v.StoryCursor = STORY_LAST_ROW
    v.StoryCursorPixel = 1
    v.InputColumn = INPUT_COLUMNS
    v.StoryColumn = STORY_COLUMNS
    r.b, r.hl = ORDER_SLOT_SIZE * ORDER_SLOTS & 0xFF, OrderSlots
    keys.ClearBytes()                              # no character has an order
    v.RandomSeed = zx.r()                          # LD A,R: how long the title waited
    v.ListIndent = v.StoryLastChar = v.AwaitingAnswer = v.LispFlag = v.PrinterFlag = 0
    v.MessagesVisible = v.ActionPerform = v.CapitalNext = 1
    v.Score = 0
    keys.ClearScreen()
    hl, de = BORDER_RULE, BorderTile               # the rule between the windows:
    for _ in range(5):                             # 5 pixel lines of 16 two-byte tiles
        for x in range(16):
            mem[hl + 2 * x] = mem[de]
            mem[hl + 2 * x + 1] = mem[de + 1]
        de += 2
        hl += 0x100
    v.NoPauseLines = OPENING_LINES                 # the opening text does not pause
    if v.ParserWordCount + 1 & 0xFF:               # not $FF: no automatic LOOK
        return await MainLoop()                    # (not seen to happen)
    engine.InitNewGame()                           # AutoLook
    r.hl = StartCommand                            # echo "> LOOK" in the input window
    while True:
        r.a = mem[r.hl]
        screen.PrintInputWindowChar()
        r.hl = r.hl + 1 & 0xFFFF
        if r.a == CHAR_CR:
            break
    ldir(LookCommand, InputLine, 5)                # "LOOK", CR is the typed line
    await BuildWordList()
    return await MainLoop()


async def MainLoop():
    """Read a line ("@" repeats the previous one), turn it into word tokens,
    then parse and run its sentences until it is used up. Never returns."""
    while True:
        zx.checkpoint('MainLoop')
        v.ParserFlag = 1                           # the line has sentences to run
        v.NoPauseLines = TURN_NO_PAUSE_LINES
        await ReadLine()
        if r.zf:                                   # "@": the old word list again
            await RunWordList()
        else:
            await BuildWordList()


async def BuildWordList():
    """Turn the typed line into tokens in ParsedWords, a double quote toggling
    InputFromOrder, then run them; an unknown word or a line that ends inside
    quotes is reported instead. Returns to the main loop."""
    r.hl, r.b = ParsedWords, PARSED_WORDS_SIZE
    keys.ClearBytes()
    r.hl, r.iy = InputLine, ParsedWords
    while True:                                    # ReadWords
        keys.ReadTypedWord()
        if r.a == TOKEN_UNKNOWN:
            return await UnknownWord()
        if r.a == TOKEN_QUOTE and not (r.b & 0x0F | r.c):
            if not v.InputFromOrder:
                v.InputFromOrder = 1               # an opening quote
            else:
                v.InputFromOrder = 0               # a closing quote: end the order
                cls = mem[r.iy - 2 & 0xFFFF] & 0xF0    # with a THEN unless one is there
                if cls not in (TOKEN_THEN, TOKEN_AND):
                    mem[r.iy] = TOKEN_THEN
                    mem[r.iy + 1] = 0
                    r.iy = r.iy + 2 & 0xFFFF
                r.a = 0
        mem[r.iy] = r.b                            # StoreToken
        mem[r.iy + 1] = r.c
        r.iy = r.iy + 2 & 0xFFFF
        if r.d == TOKEN_END:
            break
    if v.InputFromOrder:                           # the line ended inside quotes
        v.InputFromOrder = 0
        await parser.PrintWhat()
        return
    await RunWordList()


async def RunWordList():
    """Parse the next sentence of the line and run it, until the line is used
    up (ParserFlag 0) or a sentence is refused."""
    v.WordListPtr = ParsedWords
    while True:                                    # ParseSentence
        await parser.ParseLine()
        if not r.zf:                               # refused: drop the line
            return
        await parser.RunSentences()
        if not v.ParserFlag:
            return


async def UnknownWord():
    """`I do not know the word "..."` in the input window."""
    r.hl = MsgIDoNotKnow
    v.RawOutputFlag = 1
    await printer.PrintMessage()
    r.hl = v.InputLinePtr
    while True:
        r.a = mem[r.hl]
        if r.a in (CHAR_CR, CHAR_QUOTE):
            break
        await screen.PrintChar()
        r.hl = r.hl + 1 & 0xFFFF
        if r.a == CHAR_SPACE:
            break
    r.a = CHAR_QUOTE
    await screen.PrintChar()
    await screen.PrintNewLine()


async def ReadLine():
    """Read a typed line into InputLine, echoed in the input window after the
    prompt: letters, digits, space, CR, quote, full stop, comma; DELETE starts
    again, back-space removes; "@" on an empty line repeats the previous line
    (Z). O: NZ for a new line (A = CR)."""
    v.IdleCounter = IDLE_SCANS_MAX
    v.RawOutputFlag = v.ActionPerform = 1
    r.a = CHAR_PROMPT
    await screen.PrintChar()
    r.a = CHAR_SPACE
    await screen.PrintChar()
    r.hl, r.b = InputLine, INPUT_LINE_SIZE         # B: free bytes, bit 7 set while empty
    r.c = 0                                        # ReadLine_Start
    return await ReadLine_Key()


async def ReadLine_Key():
    """The key loop of ReadLine (keys.L6E7A comes back here)."""
    while True:
        await keys.WaitKey()
        if r.b & 0x80 and r.a == CHAR_AT:          # "@" on an empty line
            return await keys.L6E7A()
        if not r.c & 1:
            await keys.CursorKeyToWord()           # the first key may be an arrow
        r.c = 1
        if r.a == KEY_DELETE:
            await keys.EraseInputLine()
            r.c = 0                                # ReadLine_Start
            continue
        if r.a == CHAR_BACKSPACE:
            if r.b & 0x80:
                continue                           # empty line: nothing to remove
            r.a = CHAR_BACKSPACE
            await screen.PrintChar()
            r.b = r.b + 1 & 0xFF
            r.hl = r.hl - 1 & 0xFFFF
            continue
        if not (r.a >= CHAR_AT or r.a in (CHAR_QUOTE, CHAR_SPACE, CHAR_CR, CHAR_FULLSTOP, CHAR_COMMA)):
            continue                               # anything else: ignored
        v.CapitalNext = r.a                        # ReadLine_Accept
        if r.b:                                    # room left: echo and store
            await screen.PrintChar()
            mem[r.hl] = r.a
            r.hl = r.hl + 1 & 0xFFFF
            r.b = r.b - 1 & 0xFF
        if r.a == CHAR_CR:
            r.zf = False                           # OR 1: NZ, a line was typed
            return
