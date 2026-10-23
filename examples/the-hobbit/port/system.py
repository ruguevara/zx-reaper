"""Ported from src/system.asm: special words (ALL, EXCEPT, PRINT, QUIT, HELP, SCORE, PAUSE), SAVE and LOAD.
Values pass in the registers `r` (port/regs.py); conventions: port/CONTRACT.md."""
from labels import *  # noqa: F403  (first: port functions shadow routine labels)
import calls
import main
import objects
import parser
import printer
import screen
from regs import r
from variables import v
from zxpyxel import Goto, mem, mem16, rom, zx

# The Z80 stack words of the two-pass SAY TO parse: BeginOrderPass pushes IY,
# BC, DE and StoreParsedOrders (the second pass ending, many calls later)
# pops them; SaveGame pushes IX, DE for SaveGame_End.
_order_pass = []
_save_pushed = []


async def _key_down():
    """One pass of the keyboard polls (XOR A, IN A,($FE), AND KEY_BITS, CP
    KEY_BITS, JR: 41 T-states): True while any key is down. Leaves A and the
    flags as the CP does."""
    zx.spend(41)
    await zx.sync()
    r.a = zx.inp(PORT_ULA) & KEY_BITS
    r.cp(KEY_BITS)
    return not r.zf


async def DispatchSpecialWord():
    """Run the handler of a class 9 word: look its dictionary offset (C low,
    B high) up in the 13 pairs of ActionWordTable and jump to the word of
    ActionHandlerTable at the same index. A word not in the table goes on at
    StartPhraseRecord (the asm leaves a pushed DE on the stack then). DE is
    kept for the handler."""
    hl, d = ActionWordTable, 13
    while True:
        r.a = mem[hl]
        hl += 1
        if r.a == r.c and mem[hl] == r.b:
            r.a = mem[hl]
            break
        hl += 1
        d -= 1
        if not d:
            r.hl, r.d = hl & 0xFFFF, 0
            return await parser.StartPhraseRecord()
    r.hl = mem16[hl + 0x19 & 0xFFFF]
    return await calls.call_at(r.hl)


async def WordPrint():
    """PRINT: PrinterFlag = 1 when a printer answers on port $FB (bit 6
    clear; an open bus reads $FF), then the next word. The port's high byte
    is A as the dispatcher left it."""
    r.a = zx.inp(r.a << 8 | PORT_PRINTER)
    if r.a & 0x40:
        return await ResumeDispatch()
    r.a = 1
    return await L82AF_0()


async def L82AF():
    """NOPRINT: PrinterFlag = 0, then the next word."""
    r.a = 0
    return await L82AF_0()


async def L82AF_0():
    """Store A in PrinterFlag, then the next word."""
    v.PrinterFlag = r.a
    return await ResumeDispatch()


async def ResumeDispatch():
    """Back to the parser's next-word step with D = the class nibble of the
    last word read (WordFlags)."""
    r.a = v.WordFlags
    r.d = r.a
    return await parser.ParseNextWord()


async def WordExcept():
    """EXCEPT: allowed only after ALL (AllStage = ALL_STATE_ALL): AllStage
    becomes ALL_STATE_EXCEPT, the phrase record at IY gets RECF_ALL in byte
    +1, next word. Otherwise the line is refused with "What ?". I: IY."""
    r.a = v.AllStage
    r.cp(ALL_STATE_ALL)
    if not r.zf:
        return await parser.RejectLine()
    v.AllStage = r.a = ALL_STATE_EXCEPT
    r.a = mem[r.iy + 1 & 0xFFFF] | 1 << RECF_ALL
    mem[r.iy + 1 & 0xFFFF] = r.a
    return await parser.ParseNextWord()


async def WordAll():
    """ALL (and EVERYTHING): AllStage = ALL_STATE_ALL unless EXCEPT was seen
    already; next word."""
    r.a = v.AllStage
    r.cp(ALL_STATE_EXCEPT)
    if not r.zf:
        v.AllStage = r.a = ALL_STATE_ALL
    return await parser.ParseNextWord()


async def L82E2():
    """Command handler: copy the 6 bytes of PhraseBuffer to ActionSlots+4,
    store the phrase block (StorePhraseBlock_0, or StoreFirstPhraseBlock when
    bit 7 of E is set), next word. DE is kept."""
    de = r.de
    main.ldir(PhraseBuffer, ActionSlots + 4, 6)
    r.de = de
    r.zf = r.pf = not r.e & 0x80                   # BIT 7,E
    if r.zf:
        await parser.StorePhraseBlock_0()
    else:
        await parser.StoreFirstPhraseBlock()
    return await parser.ParseNextWord()


async def BeginOrderPass():
    """Start the second pass over a SAY TO line: keep D (PicVar2), DE, BC, IY
    and ParserWordCount (PicVar3), move IY back one phrase record and parse
    again from ParseLineFrom with A = 1 (InputFromOrder). I: D, IY."""
    v.PicVar2 = r.d
    _order_pass.append((r.iy, r.bc, r.de))
    v.PicVar3 = v.ParserWordCount
    total = r.iy + 0xFFE8
    r.cf = total > 0xFFFF
    r.iy = total & 0xFFFF
    r.de = 0xFFE8
    r.a = 1
    return await parser.ParseLineFrom()


async def StoreParsedOrders():
    """The end of the word list: with InputFromOrder 0 start the second pass
    (BeginOrderPass); with 1 the pass is over: InputFromOrder = 0 and the
    phrase records parsed since (newest first) are copied into free order
    slots (owner FLAG_SLOT_PENDING + 24 bytes; a record with bit 6 of +1 is
    freed again but still counted). Stops when no slot is free (the asm then
    still writes FLAG_SLOT_PENDING one byte past OrderSlots). OrderSlotCount =
    slots counted, AllStage = 0, ParserWordCount back; on to the next word with
    D = PicVar2."""
    if not v.InputFromOrder:
        r.a = 0
        r.zf = True
        return await BeginOrderPass()
    v.InputFromOrder = 0
    n = v.ParserWordCount - v.PicVar3 & 0xFF
    c = 0
    iy_saved, bc_saved, de_saved = _order_pass.pop()
    if n:
        iy = iy_saved - PARSED_RECORD_SIZE & 0xFFFF
        while n:
            ix, left = OrderSlots, ORDER_SLOTS
            while mem[ix]:                         # look for a free slot
                ix += ORDER_SLOT_SIZE
                left -= 1
                if not left:
                    break
            ix &= 0xFFFF
            mem[ix] = FLAG_SLOT_PENDING            # take it (also past the table)
            ix += 1
            if left == 0:
                break                              # no free slot
            if mem[iy + 1 & 0xFFFF] & 0x40:        # not to keep
                mem[ix - 1] = ORDER_SLOT_FREE
            else:
                for k in range(PARSED_RECORD_SIZE):
                    mem[ix + k & 0xFFFF] = mem[iy + k & 0xFFFF]
            iy = iy - PARSED_RECORD_SIZE & 0xFFFF
            c += 1
            n -= 1
        r.ix = ix & 0xFFFF
    v.AllStage = 0
    v.OrderSlotCount = c
    r.iy = iy_saved
    v.ParserWordCount = v.PicVar3
    r.bc, r.de = bc_saved, de_saved
    r.a = r.d = v.PicVar2
    return await parser.ParseNextWord()


async def WordQuit():
    """QUIT: print the score, wait for any key, restart the game."""
    await PrintScore()
    while not await _key_down():
        pass
    raise Goto(main.RestartGame)


async def WordHelp():
    """HELP: for the player only (others skip to the next word) print the hint
    of the player's location from HintTable in the input window, or "You're
    doing fine."; then the next word. HL and IX kept."""
    if v.Subject:
        r.zf = False
        return await parser.ParseNextWord()
    hl, ix = r.hl, r.ix
    r.hl = MsgReDoingFine
    r.a = mem[Chr00PlayerLocation]
    r.ix = HintTable
    objects.FindIdRecord()
    if not r.zf:                                   # (a hit is NZ here, as the asm tests it)
        r.hl = mem16[r.ix + 1 & 0xFFFF]
    v.RawOutputFlag = r.a = 1
    await printer.PrintMessage()
    r.hl, r.ix = hl, ix
    return await ResumeDispatch()


async def L83EF():
    """SCORE: print the score, then the next word."""
    await PrintScore()
    return await ResumeDispatch()


async def PrintScore():
    """Print "You have mastered nn.n% Of this adventure.": Score is in tenths
    of a percent (hundreds digit left out when 0). HL and DE kept."""
    hl, de = r.hl, r.de
    v.RawOutputFlag = 0
    r.hl = MsgHaveMastered
    await printer.PrintMessage()
    r.hl, r.de = v.Score, 100
    DecimalDigit()
    rest = r.hl
    if not r.zf:
        await screen.PrintChar()
    r.hl, r.de = rest, 10
    DecimalDigit()
    rest = r.hl
    await screen.PrintChar()
    r.a = ord('.')
    await screen.PrintChar()
    r.a = (rest & 0xFF) + ord('0') & 0xFF
    await screen.PrintChar()
    v.CapitalNext = r.a = 0
    r.hl = MsgThisAdventure
    await printer.PrintMessage()
    r.hl, r.de = hl, de


def DecimalDigit():
    """Divide HL by DE by repeated subtraction: A the quotient as an ASCII
    digit (it must be below 10), HL the remainder, Z when the digit is "0"."""
    a, hl = ord('0') - 1, r.hl
    while True:
        a = a + 1 & 0xFF
        hl -= r.de
        if hl < 0:
            break
    r.hl = hl + r.de & 0xFFFF
    r.a = a
    r.cp(ord('0'))


async def WordPause():
    """PAUSE: green border, wait for a key and for its release, white
    border, next word."""
    zx.out(PORT_ULA, BORDER_GREEN)
    r.a = BORDER_GREEN
    await WaitForKey()
    while await _key_down():                       # wait until all keys are up
        pass
    zx.out(PORT_ULA, BORDER_WHITE)
    r.a = BORDER_WHITE
    return await ResumeDispatch()


async def LoadGame():
    """LOAD: read the four state blocks from tape straight over the game
    (LoadBlock restarts the game on a tape error), put the Bard's script
    bytes back, next word. IX and DE kept."""
    ix, de = r.ix, r.de
    for addr, size in ((SavedScriptBytes, STATE_VARS_SIZE), (Chr00Player, STATE_OBJECTS_SIZE),
                       (Timers, STATE_TIMERS_SIZE), (Loc00None, STATE_LOCATIONS_SIZE)):
        r.a, r.cf, r.ix, r.de = TAPE_FLAG_DATA, True, addr, size
        await LoadBlock()
    zx.di()                                        # the ROM returned with interrupts on
    r.hl, r.de = SavedScriptBytes, BardCommandOp
    CopyScriptBytes()
    r.de, r.ix = de, ix
    return await ResumeDispatch()


async def LoadBlock():
    """Load one block through the ROM LD-BYTES (A flag, carry set to load, IX
    address, DE length). On a bad block print the tape error, wait for a key
    and restart the game. O: carry set."""
    r.cf = await rom.LD_BYTES(r.ix, r.de, r.a, r.cf)
    if r.cf:
        return
    v.RawOutputFlag = r.a = 1
    r.hl = MsgTapeErrorHitAnyKey
    await printer.PrintMessage()
    while not await _key_down():
        pass
    raise Goto(main.RestartGame)


def CopyScriptBytes():
    """Copy 3 bytes from HL to DE (the Bard's command bytes and SavedScriptBytes)."""
    main.ldir(r.hl, r.de, 3)


async def WaitForKey():
    """Wait until no key is down, then until one is."""
    while await _key_down():
        pass
    while not await _key_down():
        pass


async def SaveGame():
    """SAVE: copy the script bytes to SavedScriptBytes, ask for the tape, write
    the four state blocks through SA_BYTES, ask to rewind and verify each
    block (a mismatch ends the command in VerifyBlock's report). IX and DE
    are kept by SaveGame_End."""
    _save_pushed.append((r.ix, r.de))
    r.de, r.hl = SavedScriptBytes, BardCommandOp
    CopyScriptBytes()
    v.RawOutputFlag = r.a = 1
    r.hl = MsgStartTapeThenPressAny
    await printer.PrintMessage()
    await WaitForKey()
    blocks = ((SavedScriptBytes, STATE_VARS_SIZE), (Chr00Player, STATE_OBJECTS_SIZE),
              (Timers, STATE_TIMERS_SIZE), (Loc00None, STATE_LOCATIONS_SIZE))
    for addr, size in blocks:
        r.a, r.ix, r.de = TAPE_FLAG_DATA, addr, size
        await rom.SA_BYTES(addr, size, TAPE_FLAG_DATA)
    r.hl = MsgRewindPrepareTapeFor
    await printer.PrintMessage()
    await WaitForKey()
    for addr, size in blocks:
        r.a, r.cf, r.ix, r.de = TAPE_FLAG_DATA, False, addr, size
        if not await VerifyBlock():
            break                                  # VerifyBlock dropped the return address
    return await SaveGame_End()


async def SaveGame_End():
    """End of SAVE: interrupts off (the ROM left them on), IX and DE back,
    next word."""
    zx.di()
    r.ix, r.de = _save_pushed.pop()
    return await ResumeDispatch()


async def VerifyBlock():
    """Check one block of SAVE against the tape through LD-BYTES (carry clear
    = verify). Returns True when it matched (carry set, the caller goes on).
    On a mismatch print "Tape error - hit any key to continue.", wait for a
    key and return False: the asm drops its return address (POP DE) and jumps
    to SaveGame_End, so SaveGame must end its command (DE is destroyed)."""
    r.cf = await rom.LD_BYTES(r.ix, r.de, r.a, r.cf)
    if r.cf:
        return True
    v.RawOutputFlag = r.a = 1
    r.hl = MsgTapeErrorHitAnyKey2
    await printer.PrintMessage()
    while not await _key_down():
        pass
    return False
