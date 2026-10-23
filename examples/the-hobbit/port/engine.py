"""Ported from src/engine.asm: command dispatch, describing locations, the end of a turn, timers, NPC scripts.
Values pass in the registers `r` (port/regs.py); conventions: port/CONTRACT.md."""
from labels import *  # noqa: F403  (first: port functions shadow routine labels)
import calls  # noqa: F401
from regs import r  # noqa: F401
from variables import v  # noqa: F401
from zxpyxel import Goto, mem, mem16, zx  # noqa: F401
import drawing
import handlers
import keys
import objects
import parser
import printer
import screen
import verbs


def _bit(n, value):
    """BIT n,value: Z set when the bit is clear; returns the bit."""
    r.zf = not value >> n & 1
    return not r.zf


def CheckVerbApplies():
    """Set ActionAllowed to 1 when CommandId makes sense for FirstObject, else 0:
    not when the nouns clash; yes when VerbHandlers has the verb, the command
    places the first object, or the object's own verb table has the verb.
    IX and HL are kept; A = the answer."""
    ix, hl = r.ix, r.hl
    objects.CheckNounsDistinct()
    answer = 0
    if not r.zf:
        r.a, r.ix = v.CommandId, VerbHandlers
        objects.FindIdRecord()
        r.cp(END_MARK)
        if not r.zf:
            answer = 1
        else:
            handlers.IsPlacingCommand()
            if r.zf:
                answer = 1
            else:
                r.a = v.FirstObject
                objects.FindObject()
                r.a = v.CommandId
                objects.FindVerbEntry()
                if r.cf:
                    answer = 1
                else:
                    r.a, r.zf, r.cf = 0, True, False        # SUB A
    r.a = v.ActionAllowed = answer
    r.ix, r.hl = ix, hl


async def DispatchCommand():
    """Carry out the command in the parser variables (CommandId, FirstObject,
    SecondObject, Subject) on the test pass (ActionPerform 0) or the real pass:
    refuse a noun used twice, refuse in the dark, find the handler (the
    object's verb table, the second object's for a placing command, else
    VerbHandlers), call it and the verb-0 entries that follow; on the real
    pass tell the characters involved. HL, IX and BC are kept."""
    hl, ix, bc = r.hl, r.ix, r.bc
    await _dispatch()
    r.hl, r.ix, r.bc = hl, ix, bc


async def _dispatch():
    """The body of DispatchCommand (its labels DispatchCommand_0 to _6)."""
    objects.CheckNounsDistinct()
    if r.zf:
        return await printer.PrintCannotDoThat()
    CheckDark()
    if r.cf:
        r.a = v.NeedsLight
        r.set_zs(r.a)
        held = False
        if r.a == 0:
            objects.CheckObject1Held()
            if r.cf:
                r.a = v.SecondObject
                objects.CheckHeldBySubject()
                held = r.cf
        if not held:
            r.hl = MsgISeeNothingHere
            await printer.PrintMessage()
            return await _dispatch_done()
    r.a = v.Noun1Kind
    r.cp(1)
    if r.zf:
        return await _dispatch_default()
    r.a = v.FirstObject
    r.cp(NO_OBJECT)
    if r.zf:
        return await _dispatch_default()
    objects.FindObject()
    v.Noun1Record = r.ix
    r.a = v.FirstObject
    await CheckHeldByOther()
    if not r.zf:
        return await _dispatch_done()
    r.a = v.SecondObject
    r.cp(NO_OBJECT)
    placing = False
    if not r.zf:
        r.a = v.Noun2Kind
        r.cp(1)
        if r.zf:
            return await _dispatch_default()
        r.a = v.SecondObject
        objects.FindObject()
        v.Noun2Record = r.ix
        await CheckHeldByOther()
        if not r.zf:
            return await _dispatch_done()
        handlers.IsPlacingCommand()
        placing = r.zf
    if not placing:
        r.ix = v.Noun1Record
    r.a = v.CommandId
    objects.FindVerbEntry()
    if not r.cf:
        return await _dispatch_default()
    return await _dispatch_call()


async def _dispatch_default():
    """DispatchCommand_Default: the verb in VerbHandlers, else "I cannot do that."."""
    r.a, r.ix = v.CommandId, VerbHandlers
    objects.FindIdRecord()
    r.cp(END_MARK)
    if r.zf:
        return await printer.PrintCannotDoThat()    # DispatchCommand_6: no notification
    return await _dispatch_call()


async def _dispatch_call():
    """DispatchCommand_Call: call the entry at IX, then each entry after it with verb 0."""
    while True:
        r.hl = mem16[r.ix + 1]
        await objects.CallHandler()
        r.ix = r.ix + 3 & 0xFFFF
        r.a = 0
        r.cp(mem[r.ix])
        if not r.zf:
            break
    return await _dispatch_done()


async def _dispatch_done():
    """DispatchCommand_Done: on the real pass, "It is dark." if the player is
    now in the dark, then NotifyCharacter for both objects."""
    r.a = v.ActionPerform
    r.cp(1)
    if not r.zf:
        return
    r.a = v.Subject
    r.cp(PLAYER)
    if r.zf:
        CheckDark()
        if r.cf:
            await printer.PrintMessage()                # HL = MsgDark
    r.a = v.CommandId
    r.b = r.a
    r.a = v.FirstObject
    r.ix = v.Noun1Record
    NotifyCharacter()
    r.a = v.SecondObject
    r.ix = v.Noun2Record
    NotifyCharacter()


def NotifyCharacter():
    """A living character (flag bit 6 set, bit 3 clear) in the record at IX is
    switched to its script for the verb B. A = its id; others are ignored."""
    if not _bit(FLAG_CHARACTER, mem[r.ix + 7]):
        return
    if _bit(FLAG_DEAD, mem[r.ix + 7]):
        return
    SwitchNpcScript()


def CheckDark():
    """Carry set (and HL = MsgDark) when the subject cannot see. Only the player
    can be in the dark: inside a closed holder, or in a location that is not
    lit, unless the sword (object $0E) is within reach with its flags bits 4
    and 2 set and bit 3 clear. IX, IY and BC are kept. Carry clear when lit."""
    r.a = v.Subject
    r.set_zs(r.a)
    r.cf = False
    if r.a:
        return
    ix, bc = r.ix, r.bc
    r.ix = Chr00Player
    objects.FindClosedHolder()
    r.a = r.set_zs(r.a + 1 & 0xFF)
    if r.a == 0:                                    # no closed holder
        objects.GetActorLocationRec()
        if _bit(LOC_LIT, mem[r.ix]):
            r.cf = False                            # (carry came from FindClosedHolder: clear)
            r.ix, r.bc = ix, bc
            return
    iy = r.iy
    r.a, r.iy = OBJ_SHORT_STRONG_SWORD, Obj0EShortStrongSword
    objects.ActorCanReach()
    r.iy = iy
    if r.zf:
        r.hl, r.cf = MsgDark, True
    else:
        r.a = r.set_zs((mem[Obj0ESwordFlags] ^ LIGHT_FLAGS_XOR) & LIGHT_FLAGS_MASK)
        if r.zf:
            r.cf = False                            # AND A: light
        else:
            r.hl, r.cf = MsgDark, True
    r.ix, r.bc = ix, bc


async def DescribeSeen():
    """Describe location A with MsgSee ("<subject> see"), as DescribeLocation does."""
    r.hl = MsgSee
    return await DescribeLocation_Intro()


async def DescribeLocation():
    """A = location id. Patch the preposition of the location (outside, inside,
    in, on, at) into the message MsgSubjIsIn (self-modifying data), then show
    the location with it. O: IX = the location's record (IX, IY, BC are kept
    by DescribeLocation_Intro)."""
    a = r.a
    objects.FindLocation()
    r.a = mem[r.ix] & LOC_PREP_MASK
    r.e, r.d = r.a, 0
    r.hl = LocationPrepositions + r.de & 0xFFFF
    r.e = mem[r.hl]
    r.hl = r.hl + 1 & 0xFFFF
    r.d = mem[r.hl]
    r.hl = MsgSubjIsIn + 1
    mem[r.hl] = r.d                                 # the phrase code, high byte first
    r.hl = r.hl + 1 & 0xFFFF
    mem[r.hl] = r.e
    r.a = a
    r.hl = MsgSubjIsIn
    return await DescribeLocation_Intro()


async def DescribeLocation_Intro():
    """Show location A starting with the message at HL (IX, IY, BC are kept)."""
    ix, iy, bc = r.ix, r.iy, r.bc
    await ShowLocation()
    r.ix, r.iy, r.bc = ix, iy, bc


async def ShowLocation():
    """A = location, HL = intro message. Print the intro and the location's
    text (or name), draw its picture and wait for a key if one was drawn, then
    list the obstacles, exits and objects. B = the location."""
    r.b = r.a
    objects.FindLocation()
    await printer.PrintMessage()
    r.l = mem[r.ix + 8]
    r.h = mem[r.ix + 9]
    r.a = r.h | r.l
    r.set_zs(r.a)
    r.cf = False
    await PrintLocationText()
    r.a = r.b
    drawing.DrawLocationPicture()
    r.a = r.set_zs(v.PictureFound + 1 & 0xFF)       # $FF: no picture drawn
    if not r.zf:
        await WaitKeyAfterPicture()
    await screen.PrintNewLine()
    r.a = r.b
    await objects.ListExitObstacles()
    return await ShowLocation_Lists()


async def ShowLocation_Lists():
    """B = location: the visible exits, then "You see :" and the objects here."""
    r.a = r.b
    await objects.ListVisibleExits()
    return await objects.ListObjectsHere()


async def PrintLocationText():
    """NZ: print the message at HL; Z: print the location's name (IX = its record)."""
    if not r.zf:
        return await printer.PrintMessage()
    return await PrintLocationName()


async def PrintLocationName():
    """Print the name phrase (adjectives and noun) of the location at IX."""
    r.de = LOC_NAME_OFFSET
    iy = r.iy
    r.iy = r.ix + r.de & 0xFFFF
    await objects.PrintNamePhrase()
    r.iy = iy


async def WaitKeyAfterPicture():
    """Wait until any key is down (all half-rows), then make the border white."""
    while True:
        zx.spend(41)                                # XOR A, IN, AND, CP, JR Z
        await zx.sync()
        r.a = zx.inp(PORT_ULA) & KEY_BITS           # A = 0 selects every half-row
        r.cp(KEY_BITS)
        if not r.zf:
            break
    r.a = BORDER_WHITE
    zx.out(BORDER_WHITE << 8 | PORT_ULA, r.a)


async def DescribeLocationShort():
    """A visited location: A = id (B must already hold it, as ShowLocation_Lists
    reads B). Print its name and a new line, then the exits and objects."""
    objects.FindLocation()
    await PrintLocationName()
    await screen.PrintNewLine()
    return await ShowLocation_Lists()


async def EndTurn_Timer():
    """End of a turn (the asm label is L96B3): the victory test, every NPC's
    script, then the timers. A timer counts down; at 0 it fires its handler,
    but one timer per turn (a second is put off to the next turn with its
    counter at 1); a timer not fired whose counter is at most its threshold
    calls its tick handler. Handlers run with ActionPerform and ActionAllowed
    1; MessagesVisible is 1 at the end. All registers are kept."""
    hl, ix, iy, bc, de = r.hl, r.ix, r.iy, r.bc, r.de
    await handlers.CheckVictory()
    await RunNpcScripts()
    v.TimersFired = 0
    v.ActionAllowed = v.ActionPerform = 1
    r.iy = Timers
    while mem[r.iy] != END_MARK:
        counter = mem[r.iy + 1]
        if counter != 0:
            counter -= 1
            mem[r.iy + 1] = counter
            tick = True
            if counter == 0:
                fired = v.TimersFired
                mem[r.iy + 1] = fired               # 0 if it fires, 1 if put off
                if fired != 1:
                    v.TimersFired = 1
                    r.hl = mem16[r.iy + 2]
                    await objects.CallHandler()
                    tick = False
            if tick:
                threshold = mem[r.iy + 4]
                if threshold != 0 and threshold >= mem[r.iy + 1]:
                    r.hl = mem16[r.iy + 5]
                    await objects.CallHandler()
        r.iy = r.iy + TIMER_RECORD_SIZE & 0xFFFF
    v.MessagesVisible = 1
    r.hl, r.ix, r.iy, r.bc, r.de = hl, ix, iy, bc, de


L96B3 = EndTurn_Timer       # the asm's name for $96B3 (parser's RunSentences calls it)


async def CheckHeldByOther():
    """A = object id ($FF none). When the subject is the player and the object
    is carried (not by the player) by a character, and the player's present
    flag is set, print "<carrier> is carrying <object>." and return NZ; else
    Z. IX, IY and BC are kept."""
    r.cp(0xFF)
    if r.zf:
        return
    ix, iy, bc = r.ix, r.iy, r.bc
    r.b = r.a
    if v.Subject != 0:                              # only the player is told
        r.a = 0
        r.zf = True
    else:
        r.a = r.b
        objects.FindObject()
        r.a = mem[r.ix + 1]
        r.cp(AT_LOCATION)
        if not r.zf:
            r.a = r.b
            r.iy = r.ix
            objects.CheckHeldBySubject()
            if not r.cf:
                objects.FindObject()                # the top of the holder chain
                if _bit(FLAG_CHARACTER, mem[r.ix + 7]):
                    r.a = mem[Chr00PlayerFlags]
                    if _bit(FLAG_PRESENT, r.a):
                        printer.msg_args.append(mem16[r.iy + 8])    # the object's name
                        printer.msg_args.append(mem16[r.ix + 8])    # the carrier's name
                        r.hl = MsgCarrying3
                        await printer.PrintMessage()
                        r.a |= 1
                        r.zf = False
    r.ix, r.iy, r.bc = ix, iy, bc


async def L977C():
    """Kill the character in FirstObject (falls into KillCharacter)."""
    r.a = v.FirstObject
    return await KillCharacter()


async def KillCharacter():
    """A = id of the character who dies (0 the player: EndGame). Mark it dead,
    put down what it carries, make its NPC record dormant (id 0), rename it
    "dead ...", free its order slots. BC, IX and IY are kept."""
    r.set_zs(r.a)
    r.cf = False
    if r.zf:
        return await verbs.EndGame()
    bc, iy, ix = r.bc, r.iy, r.ix
    r.c = r.a
    objects.FindObject()
    mem[r.ix + 7] |= 1 << FLAG_DEAD
    await objects.EmptyHolder()
    r.a = r.c
    FindNpcState()
    r.cp(END_MARK)
    r.a = r.c
    if not r.zf:
        mem[r.iy] = 0                               # dormant: the NPC loop skips it
    objects.MarkBrokenOrDead()
    r.a = r.c
    parser.FreeOrderSlots()
    r.ix, r.iy, r.bc = ix, iy, bc


def InitNewGame():
    """Start a new game: the player acts, then choose which of the 5
    BlockedExits records is active (patch its address into the LD IY,nn of
    ExamineMap, SmcBlockedExit+2, and zero its exit triple in the location
    record) and which of the 4 RandomEvents records is current."""
    v.Subject = 0
    v.ExitRestoreMode = 0
    v.ReplyGiven = 0
    v.ActorRecord = Chr00Player
    r.a = BLOCKED_EXIT_MAX
    objects.RandomUpTo()
    r.b = r.a = r.a + 1 & 0xFF
    r.de = BLOCKED_EXIT_SIZE
    r.iy = BlockedExits - BLOCKED_EXIT_SIZE + r.b * BLOCKED_EXIT_SIZE & 0xFFFF
    mem16[SmcBlockedExit + 2] = r.iy
    r.hl = mem16[r.iy + 1]                          # the exit triple in the location record
    for _ in range(EXIT_SIZE):
        mem[r.hl] = 0
        r.hl = r.hl + 1 & 0xFFFF
    r.b = 0
    r.a = RANDOM_EVENT_MAX
    objects.RandomUpTo()
    r.e, r.d = r.a << 2 & 0xFF, 0                   # the size of a random event record is 4
    r.hl = RandomEvents + r.de & 0xFFFF
    v.RandomEventPtr = r.hl


async def PrintMessageDot():
    """Print the message at HL, then a full stop and a new line."""
    await printer.PrintMessage()
    r.a = CHAR_FULLSTOP
    await screen.PrintChar()
    return await screen.PrintNewLine()


def AbortUnlessPerform():
    """Returns True to go on, False when ActionPerform AND ActionAllowed is 0:
    the asm then drops its return address, so the handler that called it
    returns at once (every call site is `if not AbortUnlessPerform(): return`).
    BC is kept (in the asm's abort case BC ends up as the dropped return
    address, a dead value). A = the AND, flags from it."""
    bc = r.bc
    r.a = mem[ActionPerform] & mem[ActionAllowed]   # LD BC,(ActionPerform): C and B
    r.set_zs(r.a)
    r.cf = False
    r.bc = bc
    return r.a != 0


# The NPC script interpreter. In the asm its parts jump into each other
# (RunNpcScripts_Next, _Script, _Command, RunScriptCommand ...); here one loop
# runs them as states so that a long script does not nest calls, and each
# entry point runs the loop from its state to the end of the NPC list.
# RunScriptCommand, RunScriptVerb and ScriptCommandFailed return the state
# that the asm jumps to ('next', 'script' or 'command').

async def RunNpcScripts():
    """Run every NPC's script for one turn (see the script language in
    src/engine.asm). Ends with Subject the player, MessagesVisible 1 and
    ActorRecord the player's record."""
    UpdatePlayerSight()
    r.iy = NpcStates
    return await _interpret('npc')


async def RunNpcScripts_Start():
    """The NPC at IY acts normally (entered from NpcHeld): run the rest of the list."""
    return await _interpret('start')


async def RunNpcScripts_Script():
    """Go on with the NPC's current script (IY+2), then the rest of the list."""
    return await _interpret('script')


async def RunNpcScripts_Command():
    """Go on with the script command at HL, then the rest of the list."""
    return await _interpret('command')


async def RunNpcScripts_Next():
    """Skip to the NPC after the one at IY (entered from NpcHeld), then the rest of the list."""
    return await _interpret('next')


async def _interpret(state):
    while True:
        if state == 'next':
            r.de = NPC_RECORD_SIZE
            r.iy = r.iy + NPC_RECORD_SIZE & 0xFFFF
            state = 'npc'
        elif state == 'npc':
            v.NpcFailures = 0
            r.a = mem[r.iy]
            r.cp(END_MARK)
            if r.zf:
                break
            if r.a == 0:                            # a dormant slot
                state = 'next'
                continue
            v.Subject = r.a
            objects.GetSingleLocation()
            v.ActorRecord = r.ix
            v.ActorLocation = r.a
            v.MessagesVisible = 0
            r.a = mem[r.iy]
            iy = r.iy
            r.iy = Chr00Player
            objects.CanReachSwapped()               # can the player reach the NPC?
            r.iy = iy
            if not r.zf and v.SightState != SIGHT_NOISE_HEARD:
                v.MessagesVisible = 1               # the player sees what the NPC does
                if v.SightState == SIGHT_DARK:
                    v.SightState = SIGHT_NOISE_HEARD
                    r.hl = MsgHearNoise
                    await printer.PrintMessage()
                    v.MessagesVisible = 0
            r.a = 0xFF
            r.cp(mem[r.ix + 1])
            if not r.zf:                            # held: NpcHeld finishes the list
                return await objects.NpcHeld()
            state = 'start'
        elif state == 'start':
            r.ix = v.ActorRecord
            parser.FindOrderSlotKeep()              # Z: the NPC owns a stored order
            v.ActorHasOrder = r.a = 1 if r.zf else 0
            state = 'script'
        elif state == 'script':
            r.hl = mem16[r.iy + 2]
            state = 'command'
        else:                                       # 'command': the command at HL
            state = await _script_command()
    v.Subject = 0
    r.a = v.MessagesVisible = 1
    r.hl = v.ActorRecord = Chr00Player


async def _script_command():
    """RunNpcScripts_Command: try the script command at HL; returns the next state."""
    r.a = v.NpcFailures
    r.cp(SCRIPT_MAX_FAILURES)
    if r.zf:
        return 'next'                               # done for this turn
    r.a = mem[r.hl]
    r.de = 4
    r.ix = r.hl
    r.a &= SCRIPT_OP_MASK
    r.cp(SCRIPT_OPS_COMMANDS)
    if r.cf:                                        # op 0-4: a command
        r.a = v.ActorHasOrder
        r.cp(1)
        if r.zf and not _bit(SCRIPT_BIT_NO_ORDER, mem[r.hl]):
            v.ActorHasOrder = r.a = 0               # the order is looked at once per turn
            r.a = 1
            await parser.RunStoredOrder()
            if not r.zf:                            # do the order now, tested already
                v.ActionPerform = v.ActionAllowed = r.a = 1
                await RunActorCommand_Run()
                return 'next'
        r.a = mem[r.hl] & 0x0F
        r.cp(SCRIPT_OP_VERB)
        if r.zf:
            return await RunScriptVerb()
        if r.cf:
            return await RunScriptCommand()
        return 'next'
    if r.a == SCRIPT_OP_JUMP:
        mem[r.iy + 2] = mem[r.ix + 1]
        r.e = mem[r.ix + 2]
        mem[r.iy + 3] = r.e
        return 'script'
    if r.a == SCRIPT_OP_SWITCH:
        r.b = mem[r.ix + 1]
        r.a = mem[r.iy]
        SwitchNpcScript()
        return 'script'
    if r.a == SCRIPT_OP_RANDOM:
        ChooseRandomScript()
        return 'script'
    # 5-9, B, D: end of the script (the asm's test of op 0 here, an ADD HL,DE
    # to the next command, can never be true): entry 0 of the behaviour table
    r.a = r.e = 0
    SelectScript()
    return 'next'


def AdvanceScript():
    """HL = the command (as IX), DE = its length: step the NPC's script (IY+2)
    past it, two bytes more when the command byte has bit 4 (an alternative
    address). O: HL = the next command."""
    r.hl = r.hl + r.de & 0xFFFF
    if _bit(4, mem[r.ix]):
        r.hl = r.hl + 2 & 0xFFFF
    mem16[r.iy + 2] = r.hl


async def RunScriptCommand():
    """Script ops 0-3 at IX (NPC at IY): op 0/2 the verb and two objects through
    RunActorCommand, op 1/3 a routine called in a test pass and, if it set
    ActionAllowed to 1, a real pass. Success: the command byte is zeroed if it
    has bit 5, the NPC is done ('next'); failure: ScriptCommandFailed."""
    AdvanceScript()
    if _bit(SCRIPT_BIT_ROUTINE, mem[r.ix]):
        r.hl = mem16[r.ix + 1]
        r.a = v.ActionPerform = v.ActionAllowed = 0
        await objects.CallHandler()
        r.a = v.ActionAllowed
        r.cp(1)
        if not r.zf:
            return await ScriptCommandFailed()
        v.ActionPerform = 1
        await objects.CallHandler()
    else:
        v.CommandId = mem[r.ix + 1]
        v.FirstObject = mem[r.ix + 2]
        v.SecondObject = mem[r.ix + 3]
        await RunActorCommand()
        if r.zf:
            return await ScriptCommandFailed()
    if _bit(SCRIPT_BIT_ERASE, mem[r.ix]):
        mem[r.ix] = 0                               # a one-shot command
    return 'next'


async def RunScriptVerb():
    """Script op 4 at IX (NPC at IY): a verb alone. $FF does nothing (jumps to
    the alternative address if bit 4); else CommandId with no objects through
    RunActorCommand; failure: ScriptCommandFailed. Returns the next state."""
    r.de = 2
    AdvanceScript()
    r.a = mem[r.ix + 1]
    r.cp(NO_OBJECT)
    if not r.zf:
        v.CommandId = r.a
        r.a = v.FirstObject = v.SecondObject = NO_OBJECT
        await RunActorCommand()
        if r.zf:
            return await ScriptCommandFailed()
        return 'next'
    if _bit(4, mem[r.ix]):
        r.hl = mem16[r.ix + 2]
        mem16[r.iy + 2] = r.hl
    return 'next'


async def ScriptCommandFailed():
    """Count a failure; go to the alternative address (bit 4: the word at IX+DE)
    as the next command, else on with the script. Returns 'command' or 'script'."""
    v.NpcFailures = v.NpcFailures + 1 & 0xFF
    if not _bit(4, mem[r.ix]):
        return 'script'
    r.ix = r.ix + r.de & 0xFFFF
    r.h = mem[r.ix + 1]
    r.l = mem[r.ix]
    mem16[r.iy + 2] = r.hl
    return 'command'


async def RunActorCommand():
    """Make the character in Subject do CommandId (FirstObject, SecondObject):
    the test pass (TestActorCommand); refused: Z. Otherwise announce it and
    really do it (RunActorCommand_Run). O: NZ when done. IX is kept."""
    ix = r.ix
    await parser.TestActorCommand()
    if r.zf:
        r.ix = ix
        return
    await _run_command()
    r.ix = ix


async def RunActorCommand_Run():
    """The second half of RunActorCommand without the test pass (an order that
    RunStoredOrder has tested). O: NZ. IX is kept (the asm's caller pushes it)."""
    ix = r.ix
    await _run_command()
    r.ix = ix


async def _run_command():
    """Announce the command as a sentence when the player can see it ("Someone"
    when the actor is away but the first object, with several places, is at the
    player's), run DispatchCommand, then announce the actor and the first
    object arriving."""
    quiet = False
    r.a = v.Noun1Kind
    r.cp(1)
    if r.zf:
        quiet = True                                # a place: run it quietly
    else:
        r.a = v.CommandId
        r.cp(CMD_GO_THROUGH)
        if r.zf:
            r.a = v.ActorLocation
            r.cp(mem[Chr00PlayerLocation])
            quiet = not r.zf                        # the actor is away: quietly
    if not quiet:
        r.a = v.FirstObject
        r.cp(NO_OBJECT)
        someone = False
        if not r.zf:
            objects.GetSingleLocation()
            v.FirstObjectPlace = r.a
            r.cp(NO_OBJECT)
            if r.zf:                                # several places
                r.bc = mem16[PlayerLocation]        # C = PlayerLocation, B = ActorLocation
                r.a = r.c
                r.cp(r.b)
                if not r.zf:
                    r.b = mem[r.ix]                 # the number of places of the object
                    for _ in range(r.b or 256):     # (DJNZ: 0 runs 256 times)
                        r.cp(mem[r.ix + 0x10])
                        if r.zf:
                            someone = True
                            break
                        r.ix = r.ix + 1 & 0xFFFF
        if someone:
            r.b = v.Subject
            v.Subject = NO_ACTOR                    # "Someone"
            v.MessagesVisible = 1
            iy = r.iy
            await keys.PrintCommandSentence()
            r.iy = iy
            v.MessagesVisible = 0
            r.a = r.b
            v.Subject = r.a
        else:
            iy = r.iy
            await keys.PrintCommandSentence()       # (prints only if visible)
            r.iy = iy
    await DispatchCommand()
    r.a = v.Subject
    r.hl = ActorLocation
    r.de = MsgEnters
    await AnnounceArrival()
    if v.Noun1Kind != 1:
        r.a = v.FirstObject
        r.hl = FirstObjectPlace
        r.de = MsgAppears
        await AnnounceArrival()
    else:
        r.a = 1
    r.a |= 1
    r.set_zs(r.a)
    r.cf = False


def ChooseRandomScript():
    """Op $F: the script of a random behaviour entry from 0 to the smaller of
    the command's argument (IX+1) and the record's highest index (IY+1)."""
    r.a = mem[r.ix + 1]
    r.cp(mem[r.iy + 1])
    if not r.cf:
        r.a = mem[r.iy + 1]
    objects.RandomUpTo()
    r.e = r.a
    return SelectScript()


def SelectScript():
    """E = behaviour entry number (limited to the record's highest index, IY+1):
    make that entry's script the NPC's current script (IY+2)."""
    r.a = mem[r.iy + 1]
    r.cp(r.e)
    if r.cf:
        r.e = r.a
    r.hl = mem16[r.iy + 4]                          # the behaviour table: 3-byte entries
    r.d = 0
    r.hl = r.hl + 3 * r.e + 1 & 0xFFFF              # skip the id
    r.e = mem[r.hl]
    r.hl = r.hl + 1 & 0xFFFF
    r.d = mem[r.hl]
    mem[r.iy + 2] = r.e
    mem[r.iy + 3] = r.d


def FindNpcState():
    """A = character id. O: IY = HL = its NpcStates record (or the $FF end
    mark), A = the id found or $FF; flags of the last CP. BC and DE are kept."""
    wanted = r.a
    hl = NpcStates
    while True:
        a = mem[hl]
        r.a = a
        r.cp(wanted)
        if r.zf:
            break
        r.cp(END_MARK)
        if r.zf:
            break
        hl = hl + NPC_RECORD_SIZE & 0xFFFF
    r.hl = r.iy = hl


def SwitchNpcScript():
    """A = character id, B = behaviour id: make the script of the NPC's
    behaviour entry for B its current script (IY+2); nothing if the NPC or the
    entry is missing. IX and IY are kept."""
    iy, ix = r.iy, r.ix
    FindNpcState()
    r.cp(END_MARK)
    if not r.zf:
        r.hl = mem16[r.iy + 4]
        r.ix = r.hl                                 # the behaviour table
        r.a = r.b
        objects.FindIdRecord()
        r.cp(END_MARK)
        if not r.zf:
            r.hl = mem16[r.ix + 1]
            mem16[r.iy + 2] = r.hl
    r.ix, r.iy = ix, iy


async def AnnounceArrival():
    """A = id of an actor or object ($FF none, 0 the player), HL = the address
    of the byte holding its location before the action, DE = message. Print
    "<name> enters." / "appears." when it is now at the player's location and
    was not there, unless the dark noise was given (SightState 2) or MoveFlag
    is 0 (the player was carried along). The name goes on the message stack as
    the address of the record's name phrase (+8)."""
    r.cp(END_MARK)
    if r.zf:
        return
    r.set_zs(r.a)
    r.cf = False
    if r.zf:
        return                                      # the player never arrives
    r.b = r.a
    r.a = v.SightState
    r.cp(SIGHT_NOISE_HEARD)
    if r.zf:
        return
    r.a = r.b
    objects.GetSingleLocation()
    r.c = r.a
    r.cp(mem[r.hl])
    if r.zf:
        return                                      # not moved
    r.a = v.PlayerLocation
    r.cp(r.c)
    if not r.zf:
        return                                      # not where the player is
    r.a = v.MoveFlag
    r.set_zs(r.a)
    if r.zf:
        return
    r.a = v.MessagesVisible = 1
    r.hl = r.de
    r.a = r.b
    objects.FindObject()
    r.ix = r.ix + 8 & 0xFFFF
    printer.msg_args.append(r.ix)
    await printer.PrintMessage()


def UpdatePlayerSight():
    """Store the player's location in PlayerLocation and SightState: 0 when the
    player can see, 1 when it is dark."""
    r.a = PLAYER
    objects.GetSingleLocation()
    v.PlayerLocation = r.a
    CheckDark()
    r.a = 1 if r.cf else 0
    v.SightState = r.a
