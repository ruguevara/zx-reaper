"""Ported from src/verbs.asm: look, take, drop, move, run, follow, inventory, open, attack, put, give, examine.
Values pass in the registers `r` (port/regs.py); conventions: port/CONTRACT.md.

Inside this module a routine's own name is the function, not its address: an
address of one of these routines (a handler passed to L9F4A) is `labels.Name`.

Routines that the asm leaves by dropping their return address (RequireHeld,
CheckCanCarry, CheckCanCarry_Single, CheckAttackAllowed) return False then (the
caller returns at once) and True to go on."""
from labels import *  # noqa: F403  (first: port functions shadow routine labels)
import calls  # noqa: F401
import engine
import handlers
import labels
import main
import objects
import parser
import printer
import screen
import system
from regs import r
from variables import v
from zxpyxel import Goto, mem, mem16, zx  # noqa: F401


def add8(a, b):
    """ADD A,b: the sum mod 256; sets Z, S and carry."""
    t = a + b
    r.cf = t > 0xFF
    t &= 0xFF
    r.zf, r.sf = t == 0, t > 0x7F
    return t


def sub8(a, b):
    """SUB b / A-b: the difference mod 256; sets Z, S and carry (borrow)."""
    r.cf = b > a
    t = a - b & 0xFF
    r.zf, r.sf = t == 0, t > 0x7F
    return t


def bit_set(n, addr):
    """BIT n,(addr): sets Z when the bit is clear; returns whether it is set."""
    s = bool(mem[addr & 0xFFFF] >> n & 1)
    r.zf = not s
    return s


def flags_byte():
    """The F register as PUSH AF / POP BC would carry it (Z, C, S; no PV)."""
    return r.cf | r.zf << 6 | r.sf << 7


async def VerbLook():
    """Look: when the actor lies at a location, describe it with its picture;
    when it is inside a holder (barrel, boat) print "<subj> are in the barrel."
    and list what the holder holds. Tail-jumps into the describing/listing
    routine."""
    if not objects.CommitOrAbort():
        return
    r.ix = v.ActorRecord
    r.a = mem[r.ix + 1]
    r.cp(AT_LOCATION)
    if r.zf:                                       # VerbLook_AtLocation
        r.a = mem[r.ix + 0x10]
        return await engine.DescribeLocation()
    r.hl = 0x0080                                  # an empty word item blanks the
    mem16[MsgSubjIsIn + 1] = r.hl                  # message's preposition slot
    r.hl = MsgSubjIsIn
    await printer.PrintMessage()
    actor = r.ix
    r.a = mem[r.ix + 1]
    objects.FindObject()
    await objects.PrintHolderRelation()
    r.e = mem[r.ix + 8]                            # the holder's name phrase
    r.a = mem[r.ix + 9] & 0x0F                     # without the print mode nibble
    r.d = r.a
    await printer.PrintWord()
    r.a = CHAR_FULLSTOP
    await screen.PrintChar()
    await screen.PrintNewLine()
    r.hl = MsgSee2
    await printer.PrintMessage()
    r.ix = actor
    r.a = mem[r.ix + 1]
    r.b = mem[r.ix + 0x10]
    return await objects.ListObjects()


async def RequireHeld():
    """Check that the subject holds the first object. True when it does
    (carry set); otherwise prints "<subject> not carrying it." and returns
    False: the caller must return at once (the asm drops its return address)."""
    objects.CheckObject1Held()
    if r.cf:
        return True
    r.hl = MsgNotCarrying
    await printer.PrintMessage()
    return False


async def VerbDrop():
    """Drop the first object: its holder becomes the actor's holder (an object
    tied to the rope drops the rope). A consumable thing vanishes with
    "<thing> evaporates." Leaves IX at the dropped record (+8 when it
    evaporated)."""
    if not await RequireHeld():
        return
    if not objects.CommitOrAbort():
        return
    r.ix = v.Noun1Record
    r.a = mem[r.ix + 1]
    r.cp(OBJ_ROPE)
    if r.zf:
        r.ix = Obj12Rope                           # tied to the rope: the rope drops
    dropped = r.ix
    r.ix = v.ActorRecord
    r.a = mem[r.ix + 1]
    r.ix = dropped
    mem[r.ix + 1] = r.a                            # held by the actor's holder
    if not bit_set(FLAG_CONSUMABLE, r.ix + 7):
        return
    mem[r.ix + 0x10] = 0                           # nowhere any more
    r.hl = MsgEvaporates
    r.de = 0x0008
    r.ix = r.ix + 8 & 0xFFFF
    printer.msg_args.append(r.ix)                  # the thing's name phrase
    await printer.PrintMessage()


async def L8CE0():
    """Command handler (via $C730): when the first object is held by the second
    (CheckObject1Held_0 with HL = SecondObject) go on as take, else print
    MsgNot."""
    r.a = v.FirstObject
    r.hl = SecondObject
    objects.CheckObject1Held_0()
    r.hl = MsgNot
    if not r.zf:
        return await printer.PrintMessage()
    return await VerbTake_0()


async def CheckCanCarry():
    """Check that the subject can lift and carry the first object: its bulk
    (with what is inside) against the actor's capacity (+3), what is left of it
    after the subject's load (the sign bit of the byte decides, not the
    borrow), then CheckCanCarry_Single. True to go on (IX = the first object's
    record); False after the message or refusal: the caller returns at once."""
    r.ix = v.Noun1Record
    r.a = v.FirstObject
    objects.SumHeldBulk()
    r.a = add8(r.a, mem[r.ix + 3])
    if r.cf:
        r.a = 0xFF                                 # cap at 255
    r.b = r.a
    r.iy = v.ActorRecord
    r.a = sub8(mem[r.iy + 3], r.b)
    r.hl = MsgTooHeavyLift
    if not r.cf:
        left = r.a
        r.a = v.Subject
        objects.SumHeldBulk()
        r.b = r.a
        r.a = sub8(left, r.b)
        if not r.sf:                               # JP P
            return await CheckCanCarry_Single()
        r.hl = MsgCarryingTooMuch
    await printer.PrintMessage()
    return False


async def CheckCanCarry_Single():
    """The last test of CheckCanCarry (also PutObjectIn): the first object must
    have a single place and a clear bit 1 of its flags, else the command is
    refused. True to go on; False: the caller returns at once. Leaves IX at the
    first object's record."""
    CheckSinglePlace()
    if r.zf and not bit_set(1, r.ix + 7):
        return True
    await objects.RefuseCommand()
    return False


async def VerbTake():
    """Take or carry (verbs $13, $3B): "<subj> already carrying <obj1>." when
    held, else as VerbTake_0."""
    objects.CheckObject1Held()
    r.hl = MsgAlreadyCarrying
    if r.cf:
        return await printer.PrintMessage()
    return await VerbTake_0()


async def VerbTake_0():
    """The subject takes the first object: weight and kind checked, refused
    when it is something the subject is itself in or on; when performed its
    holder becomes the subject (the rope's holder when it was tied to the
    rope)."""
    if not await CheckCanCarry():
        return
    r.a = v.Subject
    while True:                                    # VerbTake_Up: up the subject's holders
        objects.FindObject()
        r.a = v.FirstObject
        r.cp(mem[r.ix + 1])
        if r.zf:
            return await objects.RefuseCommand()
        r.a = mem[r.ix + 1]
        r.cp(AT_LOCATION)
        if r.zf:
            break
    r.ix = v.Noun1Record
    if not objects.CommitOrAbort():
        return
    r.a = mem[r.ix + 1]
    r.cp(OBJ_ROPE)
    r.a = v.Subject
    if r.zf:
        mem[Obj12Rope + 1] = r.a                   # the rope comes with the subject
    else:
        mem[r.ix + 1] = r.a


async def VerbMove():
    """Move the actor in direction CommandId (the ten direction verbs); in the
    dark the direction is random, 1-10. Falls into MoveActor."""
    engine.CheckDark()
    if r.cf:
        r.a = DIR_DOWN - 1
        objects.RandomUpTo()
        r.a = r.a + 1 & 0xFF
        v.CommandId = r.a
    return await MoveActor()


async def MoveActor():
    """Move the actor through the exit of direction CommandId: a holder that is
    not a character stops it, TakeWeight is its weight and load, no exit (or
    destination 0) is a refusal (MoveActor_NoWay), the obstacle and the room at
    the destination are tested by CheckPassage. Falls into ActorArrives with
    IY = the actor's record and B = the destination."""
    r.iy = v.ActorRecord
    r.a = mem[r.iy + 1]
    r.cp(AT_LOCATION)
    if not r.zf:
        objects.FindObject()
        if not bit_set(FLAG_CHARACTER, r.ix + 7):
            return await MoveActor_NoWay()         # in a barrel or a boat: cannot walk
        mem[r.iy + 1] = AT_LOCATION                # set free of the character
    r.a = v.Subject
    objects.SumHeldWeight()
    r.a = add8(r.a, mem[r.iy + 2])
    v.TakeWeight = r.a
    r.a = v.CommandId
    objects.FindExitByDirection()
    r.cp(END_MARK)
    if r.zf:
        return await MoveActor_NoWay()
    r.a = mem[r.ix + EXIT_DEST]
    r.set_zs(r.a)
    r.cf = False
    if r.a == 0:
        return await MoveActor_NoWay()
    v.TakeId = r.a
    r.a = mem[r.ix + EXIT_OBSTACLE]
    CheckPassage()
    r.a = r.set_zs(r.a - 1 & 0xFF)                 # PASS_BLOCKED
    if r.zf:
        return await MoveActor_NoWay()
    r.a = r.set_zs(r.a - 1 & 0xFF)                 # PASS_TOO_SMALL
    if r.zf:
        return await ActorArrives_2()
    r.a = r.set_zs(r.a - 1 & 0xFF)                 # PASS_TOO_FULL
    if r.zf:
        return await ActorArrives_3()
    return await ActorArrives()


async def MoveActor_NoWay():
    """No way: "<subj> cannot go <dir>."; but in the dark the player blunders
    into a wall: strength (+5 of the player) halved, "But fall and hit your
    head.", and at 0 "But fall and smash your skull." and the game ends."""
    engine.CheckDark()
    if not r.cf:
        return await objects.RefuseCommand()
    if not objects.CommitOrAbort():
        return
    r.ix = Chr00Player
    r.set_zs(r.a)                                  # AND A: carry clear
    r.cf = False
    r.hl = MsgButFallHitHead
    old = mem[r.ix + 5]
    new = old >> 1                                 # RR (IX+5) with carry clear
    mem[r.ix + 5] = new
    r.cf, r.zf, r.sf = bool(old & 1), new == 0, False
    if not r.zf:
        return await printer.PrintMessage()
    r.hl = MsgButFallSmashSkull
    await printer.PrintMessage()
    return await EndGame()


async def ActorArrives():
    """The actor (IY) arrives at location B when really performing: its
    location slot is set, what it carries comes along (MoveCarried). For the
    player the destination's arrival handler runs, then the place is described
    (ActorArrives_0)."""
    if not objects.CommitOrAbort():
        return
    mem[r.iy + 0x10] = r.b
    r.a = v.Subject
    await objects.MoveCarried()
    r.a = v.Subject
    r.cp(PLAYER)
    if not r.zf:
        return                                     # an NPC is done here
    r.ix = ArrivalHandlers
    r.a = v.TakeId
    objects.FindIdRecord()
    if not r.zf:
        r.l = mem[r.ix + 1]
        r.h = mem[r.ix + 2]
        await objects.CallHandler()
    return await ActorArrives_0()


async def ActorArrives_0():
    """Describe the destination TakeId unless it is dark: the full description
    with picture the first time (marks LOC_VISITED and adds the location's
    FirstVisitScores value to the score), the short one afterwards."""
    engine.CheckDark()
    if r.cf:
        return
    r.a = v.Subject
    r.set_zs(r.a)
    r.cf = False
    subject = r.a
    r.a = v.TakeId
    if subject:                                    # ActorArrives_Describe
        return await engine.DescribeLocation()
    r.hl = v.TakeObject                            # the destination's location record
    if bit_set(LOC_VISITED, r.hl):
        return await engine.DescribeLocationShort()
    mem[r.hl] |= 1 << LOC_VISITED
    dest = r.a
    r.ix = FirstVisitScores
    objects.FindIdRecord()
    if not r.zf:
        de = r.de
        r.e = mem[r.ix + 1]
        r.d = mem[r.ix + 2]
        r.hl = v.Score
        r.hl = r.hl + r.de & 0xFFFF
        v.Score = r.hl
        r.de = de
    r.a = dest
    return await engine.DescribeLocation()


async def ActorArrives_2():
    """Too small: "<the_arg> is too small for <subj> to enter." """
    r.hl = MsgTooSmallForEnter
    return await ActorArrives_4()


async def ActorArrives_3():
    """Too full: "<the_arg> is too full for <subj> to enter." (IX = the
    destination's record)."""
    r.ix = v.TakeObject
    r.hl = MsgTooFullForEnter
    return await ActorArrives_4()


async def ActorArrives_4():
    """Print the message in HL with the word at record IX+2, +3 as its
    argument. BUG kept: for too small, IX is the obstacle and +2, +3 is its
    weight, not a name phrase (so a wrong word is printed)."""
    msg = r.hl
    r.l = mem[r.ix + 2]
    r.h = mem[r.ix + 3]
    printer.msg_args.append(r.hl)
    r.hl = msg
    await printer.PrintMessage()


def CheckPassage():
    """Can the subject pass the obstacle A (0: none) and enter TakeId? Obstacle:
    not active/dead -> blocked; blocked also by state bit 7 for the player;
    TakeWeight not below its +2 -> too small. Destination (record in TakeObject,
    B = TakeId): unless capacity (+1) is $FF, TakeWeight must be below the room
    left. O: A 0 / PASS_BLOCKED / PASS_TOO_SMALL / PASS_TOO_FULL, Z set when it
    can pass, IX the obstacle (or destination) record."""
    def result(a):
        r.a = a
        r.set_zs(a)                                # LD A,n / XOR A, then AND A
        r.cf = False

    r.set_zs(r.a)
    if r.a:
        objects.FindObject()
        r.a = mem[r.ix + 7] & 0x28                 # active or dead/disabled
        if r.a == 0:
            return result(PASS_BLOCKED)
        r.a = v.Subject
        if r.a == 0 and bit_set(7, r.ix + 4):      # the player is stopped by state bit 7
            return result(PASS_BLOCKED)
        r.a = v.TakeWeight
        r.b = mem[r.ix + 2]
        r.a = sub8(r.a, r.b)
        if not r.cf:
            return result(PASS_TOO_SMALL)
    r.a = v.TakeId
    r.b = r.a
    objects.FindLocation()
    v.TakeObject = r.ix
    r.a = END_MARK
    r.cp(mem[r.ix + 1])                            # unlimited capacity?
    if not r.zf:
        r.a = r.b
        objects.LocationSpareCapacity()
        r.c = r.a
        r.a = sub8(v.TakeWeight, r.c)
        if not r.cf:
            return result(PASS_TOO_FULL)
    r.a = 0                                        # XOR A
    r.zf, r.cf, r.sf = True, False, False


def CheckEnclosed():
    """Is object A shut in by a closed holder? Up the holders while their bit 5
    (open/alive) is set. O: Z and A = AT_LOCATION when the chain ends at a
    location; NZ and A = the id of the closed holder OR 1. IX preserved."""
    saved = r.ix
    objects.FindObject()
    while True:
        r.a = mem[r.ix + 1]
        r.cp(AT_LOCATION)
        if r.zf:
            break
        objects.FindObject()
        if not bit_set(FLAG_ACTIVE, r.ix + 7):
            r.a = r.set_zs(r.a | 1)
            r.cf = False
            break
    r.ix = saved


async def VerbLookThrough():
    """Look through the first object (a door, a window): "<it> is closed." when
    it is not open, else as VerbLookThrough_0."""
    r.a = v.FirstObject
    objects.FindObject()
    handlers.CheckOpen()
    if r.zf:
        return await objects.PrintStateIX()
    return await VerbLookThrough_0()


async def VerbLookThrough_0():
    """Describe the place beyond the exit whose obstacle is the first object,
    by putting it into the actor's location slot for a moment (DescribeSeen).
    BUG kept: FindLocation is called with A = the perform flag (1) left by
    CommitOrAbort, not the destination, so the dark test looks at Bag End and
    never fails."""
    r.a = v.Subject
    CheckEnclosed()
    if not r.zf:
        return                                     # shut in: nothing
    objects.FindExitByObstacle()
    r.cp(END_MARK)
    if r.zf:
        return await objects.RefuseCommand()
    r.a = mem[r.ix + 2]
    r.cp(0)
    if r.zf:
        return await objects.RefuseCommand()
    if not objects.CommitOrAbort():
        return
    exit_ = r.ix
    objects.FindLocation()                         # A = 1 here: the bug
    lit = bit_set(LOC_LIT, r.ix + 0)
    r.ix = exit_
    if not lit:
        r.hl = MsgDark
        return await printer.PrintMessage()
    r.iy = v.ActorRecord
    r.a = mem[r.iy + 0x10]
    real = r.a
    r.a = mem[r.ix + 2]
    mem[r.iy + 0x10] = r.a
    await engine.DescribeSeen()
    r.a = real
    mem[r.iy + 0x10] = r.a


async def L8F3B():
    """Command handler (via $C730): find the exit that has the first object as
    its obstacle, then walk through it."""
    objects.FindExitByObstacle()
    return await WalkToExit()


async def WalkToExit():
    """Walk through the exit IX found by FindExitByDestination (A = $FF if none):
    refused without an exit, a destination, or when CheckPassage stops the
    subject; else the exit's direction becomes the verb, FirstObject is cleared
    and the walk goes on in MoveActor. CheckPassage reads TakeId/TakeWeight as
    left by the last move (kept)."""
    r.cp(END_MARK)
    if r.zf:
        return await objects.RefuseCommand()
    r.a = mem[r.ix + EXIT_DEST]
    r.cp(0)
    if r.zf:
        return await objects.RefuseCommand()
    r.a = mem[r.ix + EXIT_OBSTACLE]
    exit_ = r.ix
    CheckPassage()
    r.ix = exit_
    if not r.zf:
        return await objects.RefuseCommand()
    if not objects.CommitOrAbort():
        return
    r.a = mem[r.ix + 0]
    v.CommandId = r.a
    r.a = AT_LOCATION
    v.FirstObject = r.a
    return await MoveActor()


async def L8F69():
    """Command handler (via $C730), put into: the water words ($17, $18) make
    the second object the water ($15) or black water ($16), held by nobody; the
    container must have bit 1; then PutObjectIn with the nouns swapped
    (L9F4A)."""
    r.ix = v.Noun1Record
    r.a = v.SecondObject
    r.cp(0x17)
    if r.zf:
        r.a = 0x15
        r.iy = Obj15Water
        _water(r.a, r.iy)
    else:
        r.cp(0x18)
        if r.zf:
            r.a = 0x16
            r.iy = Obj16BlackWater
            _water(r.a, r.iy)
    r.iy = v.Noun2Record
    if not bit_set(1, r.iy + 7):
        return await objects.RefuseCommand()
    set_ = bit_set(2, r.ix + 7)
    r.a = 0x82
    if set_:
        return await objects.PrintStateIX()
    r.hl = labels.PutObjectIn
    return await objects.L9F4A()


def _water(obj, rec):
    """L8F69_3: the water becomes the second object, held by nobody."""
    v.SecondObject = obj
    v.Noun2Record = rec
    mem[rec + 1] = 0xFF


async def VerbRun():
    """Run: roll a start direction 1-10 (RandomUpTo(DIR_DOWN), 0 again), try it
    and each next one (after DIR_UP wrapping to DIR_NORTH) until
    FindExitByDirection finds an exit; that is CommandId and the walk goes on in
    VerbMove. A location with no exit in 1-9 loops for ever unless 10 is rolled
    (as in the original)."""
    while True:
        r.a = DIR_DOWN
        objects.RandomUpTo()
        r.cp(0)
        if not r.zf:
            break
    while True:                                    # VerbRun_Try
        r.b = r.a
        objects.FindExitByDirection()
        r.cp(r.b)
        if r.zf:
            break
        r.a = r.set_zs(r.b + 1 & 0xFF)
        r.cp(DIR_DOWN)
        if not r.cf:
            r.a = DIR_NORTH
    v.CommandId = r.a
    return await VerbMove()


async def L8FCD():
    """Command handler (via $C730), enter / go into: walk to the exit leading to
    the first object."""
    r.a = v.FirstObject
    objects.FindExitByDestination()
    return await WalkToExit()


async def VerbFollow():
    """Follow: walk through the exit of the actor's location that leads to where
    the first object is; "I cannot follow <obj1> from here." when it is in the
    same place or there is no such exit."""
    r.ix = v.ActorRecord
    r.b = mem[r.ix + 0x10]
    r.ix = v.Noun1Record
    r.a = mem[r.ix + 0x10]
    r.cp(r.b)
    if not r.zf:
        objects.FindExitByDestination()
        r.cp(END_MARK)
        if not r.zf:
            return await WalkToExit()
    r.hl = MsgICannotFollowFromHere
    return await printer.PrintMessage()


async def L8FF5():
    """Command handler (via $C730), throw/shoot at: the subject must be able to
    carry the object; the target (second object) is attacked (VerbAttack) if it
    is a character (bit 6), else struck (StrikeObject), by running that handler
    with the nouns swapped (L9F4A) under CommandId $0F / $0B. When performed the
    object ends up held by nobody and its owner is notified. (The `LD
    (IX+$01),$FF` after the final jump is never executed.)"""
    if not await CheckCanCarry():
        return
    r.hl = labels.VerbAttack
    r.a = 0x0F
    r.ix = v.Noun2Record
    if not bit_set(6, r.ix + 7):
        r.hl = labels.StrikeObject
        r.a = 0x0B
    v.CommandId = r.a
    await objects.L9F4A()
    r.a = 0x2A
    v.CommandId = r.a
    r.a = v.ActionPerform
    r.cp(0x01)
    if not r.zf:
        return
    r.ix = v.Noun1Record
    mem[r.ix + 1] = 0xFF
    r.a = 0x0F
    v.CommandId = r.a
    r.a = v.FirstObject
    return engine.NotifyCharacter()


async def TalkToCharacter():
    """Talk to (command 53): how many of the stored orders the character
    (FirstObject) obeys: none without an NPC record, one after it has spoken
    (ReplyGiven), else a random number 0 to its obedience (NPC record +6);
    0 -> "<obj1> says "No"". Then ClaimOrderSlots with that number."""
    if not objects.CommitOrAbort():
        return
    r.a = v.FirstObject
    engine.FindNpcState()
    r.cp(END_MARK)
    r.a = 0
    if not r.zf:
        r.a = v.ReplyGiven
        r.cp(0)
        if r.zf:
            r.a = mem[r.iy + 6]
            r.cp(0)
            if not r.zf:
                objects.RandomUpTo()
                r.cp(0)
                if r.zf:
                    r.hl = MsgSaysNo
                    await printer.PrintMessage()
                    r.a = 0                        # SUB A
                    r.zf, r.cf, r.sf = True, False, False
    parser.ClaimOrderSlots()


async def L9065():
    """Command handler (via $C730), open/close toggle: when performing, open the
    first object if its bit 5 is clear, else close it."""
    if not objects.CommitOrAbort():
        return
    r.ix = v.Noun1Record
    if not bit_set(5, r.ix + 7):
        return await OpenObject_0()
    return await CloseObject_Clear()


async def L9065_0():
    """Command handler (via the world tables), shoot the bow: needs the bow
    (object $19) held; the arrow misses by a wide margin at the target $3C
    (or, when the subject is not $46, at random: RandomUpTo(8) < 3); otherwise
    "arrow hits": the strong arrow ($1A) is held by nobody unless it is the
    target; a character is killed (KillCharacter) and "dead" printed, anything
    else is struck (StrikeObject)."""
    r.a = 0x19
    objects.CheckHeldBySubject()
    r.hl = MsgNotCarryingBow
    if not r.cf:
        return await printer.PrintMessage()
    if not CheckAttackAllowed():
        return
    if not objects.CommitOrAbort():
        return
    r.a = 0x0F
    v.CommandId = r.a
    r.a = v.Subject
    r.cp(0x46)
    if not r.zf:
        r.a = v.FirstObject
        r.cp(0x3C)
        r.hl = MsgArrowMissesByWide
        if r.zf:
            return await printer.PrintMessage()
        r.a = 0x08
        objects.RandomUpTo()
        r.cp(0x03)
        if r.cf:
            return await printer.PrintMessage()
    r.ix = Obj1AStrongArrow                        # L9065_1
    r.a = v.FirstObject
    r.cp(0x1A)
    if not r.zf:
        mem[r.ix + 1] = 0xFF
    r.hl = MsgArrowHits                            # L9065_2
    await printer.PrintMessage()
    r.ix = v.Noun1Record
    objects.LA1AE_2()
    if not r.zf:
        return await StrikeObject()
    r.a = v.FirstObject
    await engine.KillCharacter()
    r.a = 0x06
    return await objects.PrintStateIX()


async def EndGame():
    """End of the game: the subject is the player, "<subject> is dead." and the
    score, then EndGame_Wait."""
    r.a = 0
    v.Subject = r.a
    r.hl = MsgDead
    await printer.PrintMessage()
    await system.PrintScore()
    return await EndGame_Wait()


async def EndGame_Wait():
    """Wait for any key (all half-rows read together), then restart the game
    (RestartGame, the stack dropped). CheckVictory joins here."""
    while True:
        r.a = 0                                    # XOR A: every half-row
        zx.spend(41)
        await zx.sync()
        r.a = zx.inp(r.a << 8 | PORT_ULA)
        r.a &= KEY_BITS
        r.cp(KEY_BITS)
        if not r.zf:
            break
    raise Goto(main.RestartGame)


async def VerbInventory():
    """Inventory: "<subj_is> carrying." and the objects the subject holds, or
    "Nothing"."""
    if not objects.CommitOrAbort():
        return
    r.hl = MsgCarrying
    await printer.PrintMessage()
    r.a = v.Subject
    objects.CountHeldPresent()
    r.set_zs(r.a)
    r.cf = False
    r.hl = MsgNothing
    if r.zf:
        return await printer.PrintMessage()
    r.a = v.Subject
    r.ix = v.ActorRecord
    r.b = mem[r.ix + 0x10]
    return await objects.ListObjects()


async def OpenObject():
    """Open the first object: the reason it cannot be (CheckOpenable) is said
    with PrintStateIX; else, when performing, as OpenObject_0."""
    handlers.CheckOpenable()
    if not r.zf:
        return await objects.PrintStateIX()
    if not objects.CommitOrAbort():
        return
    return await OpenObject_0()


async def OpenObject_0():
    """Set the open flag of IX; an object with one place that holds something
    present shows it (PrintContentsHeader, ListObjects)."""
    mem[r.ix + 7] |= 1 << FLAG_ACTIVE
    r.a = r.set_zs(mem[r.ix + 0] - 1 & 0xFF)       # more than one place (a door): done
    if not r.zf:
        return
    r.a = v.FirstObject
    objects.CountHeldPresent()
    r.set_zs(r.a)
    r.cf = False
    if r.zf:
        return
    r.a = v.FirstObject
    await objects.PrintContentsHeader()
    if r.cf:
        return
    r.b = mem[r.ix + 0x10]
    r.a = v.FirstObject
    return await objects.ListObjects()


async def CloseObject():
    """Close the first object: "<it> is closed" if it is not open, else when
    performing clear its open flag."""
    r.ix = v.Noun1Record
    handlers.CheckOpen()
    if r.zf:
        return await objects.PrintStateIX()
    if not objects.CommitOrAbort():
        return
    return await CloseObject_Clear()


async def CloseObject_Clear():
    """Clear the open flag (bit 5) of the object in IX."""
    mem[r.ix + 7] &= ~(1 << FLAG_ACTIVE) & 0xFF


def CheckAttackAllowed():
    """Refuse an attack between actors that share a side bit (state +4, bits
    4-6). The player clears state bit 4 of the victim first. True when the attack
    may go on (Z set, IX = the attacker); False when refused: ActionAllowed is
    cleared and the caller must return at once. IX = the attacker either way."""
    r.ix = v.Noun1Record
    r.a = v.Subject
    r.set_zs(r.a)
    r.cf = False
    if r.a == 0 and bit_set(4, r.ix + 4):          # only the player clears it
        mem[r.ix + 4] &= ~0x10 & 0xFF
    r.a = mem[r.ix + 4] & STATE_SIDE_BITS
    r.ix = v.ActorRecord
    r.a &= mem[r.ix + 4]
    r.set_zs(r.a)
    r.cf = False
    if r.zf:
        return True
    r.a = 0
    v.ActionAllowed = r.a
    r.zf, r.sf = True, False
    return False


async def VerbAttack():
    """Attack the first object with the second as the weapon (bare "fist" when
    none). Attack = actor's +5 plus the weapon's +5 (saturating), defence = the
    victim's +6, both through RollStrength. Defence holding: "But the effort is
    wasted". Excess d over KILL_MARGIN (16): killing blow (dead flag,
    KillCharacter, "<victim> is dead."); else wound message d and the victim's +5
    reduced by X+1 (if above X), +6 by Y+1, where X = 2d rotated right twice and
    Y = X rotated right once more. Damage 16 reads one word past WoundMessages
    (code at $9246: a wild message address, kept)."""
    if not CheckAttackAllowed():
        return
    r.a = v.SecondObject
    r.hl = PHRASE_FIST
    r.cp(NO_OBJECT)
    if not r.zf:
        r.ix = v.Noun2Record
        r.l = mem[r.ix + 8]
        r.h = mem[r.ix + 9]
    v.TargetNamePtr = r.hl
    r.ix = v.ActorRecord
    r.b = mem[r.ix + 5]
    r.a = r.set_zs(v.SecondObject + 1 & 0xFF)
    if not r.zf:                                   # a weapon
        r.iy = v.Noun2Record
        r.a = r.set_zs(mem[r.iy + 0] - 1 & 0xFF)
        r.hl = MsgCannotKillWith
        if not r.zf:
            return await printer.PrintMessage()
        r.a = add8(mem[r.iy + 5], r.b)
        if r.cf:
            r.a = 0xFF
        r.b = r.a
    r.a = r.b                                      # VerbAttack_Roll
    RollStrength()
    r.b = r.a
    if not objects.CommitOrAbort():
        return
    r.ix = v.Noun1Record
    r.a = mem[r.ix + 6]
    RollStrength()
    r.cp(r.b)
    r.hl = MsgButEffortWasted
    if not r.cf:                                   # defence holds
        return await printer.PrintMessage()
    r.c = r.a
    r.a = add8(r.a, KILL_MARGIN)
    if r.cf:
        r.a = 0xFF
    r.cp(r.b)
    if r.cf:                                       # VerbAttack_Kill
        r.hl = MsgWithOneWellPlacedBlow
        await printer.PrintMessage()
        mem[r.ix + 7] |= 1 << FLAG_DEAD
        r.a = v.FirstObject
        await engine.KillCharacter()
        r.a = REASON_DEAD
        return await objects.PrintStateIX()
    r.a = sub8(r.b, r.c)                           # damage d
    r.a = (r.a << 1 | r.a >> 7) & 0xFF             # RLCA: 2d, the word index
    r.e = r.a
    r.d = 0
    r.iy = WoundMessages + r.de & 0xFFFF
    r.l = mem[r.iy + 0]
    r.h = mem[r.iy + 1]
    r.a = (r.a >> 1 | (r.a & 1) << 7) & 0xFF       # RRCA, RRCA: X
    r.a = (r.a >> 1 | (r.a & 1) << 7) & 0xFF
    r.b = r.a
    r.a = add8(r.a ^ 0xFF, mem[r.ix + 5])          # CPL, then +5 - X - 1 if above X
    if r.cf:
        mem[r.ix + 5] = r.a
    r.a = (r.b >> 1 | (r.b & 1) << 7) & 0xFF       # Y
    r.a = add8(r.a ^ 0xFF, mem[r.ix + 6])
    if r.cf:
        mem[r.ix + 6] = r.a
    return await printer.PrintMessage()


def RollStrength():
    """Roll a strength: A plus a random spread RandomSigned(ROLL_SPREAD). BUG
    kept (finding F9): a carry from the addition gives 0 for a negative spread
    and $FF for a positive one, so a negative spread that does not underflow
    gives 0 and strength 0 plus a negative spread wraps. O: A. BC kept."""
    b, c = r.b, r.c
    r.b = r.a
    r.a = ROLL_SPREAD
    objects.RandomSigned()
    r.c = r.a
    r.a = add8(r.a, r.b)
    if r.cf:
        r.a = 0                                    # XOR A
        r.cf = False
        if r.c & 0x80:                             # BIT 7,C
            r.zf, r.sf = False, True
        else:
            r.a = 0xFF                             # DEC A
            r.zf, r.sf = False, True
    r.b, r.c = b, c


def CheckSinglePlace():
    """Does the first object have a single place? O: Z set when its +0 is 1,
    IX = its record; carry as it was."""
    r.ix = v.Noun1Record
    r.a = r.set_zs(mem[r.ix + 0] - 1 & 0xFF)


async def PutObjectIn():
    """Put the first object into (or onto) the second: refused for several
    places or a liquid (CheckCanCarry_Single), when already in it ("I cannot do
    that."), when the container is closed (not for put on), or too full (the
    weight must be below the room: an exact fit is refused). When performing the
    holder becomes the second object and the location the container's."""
    if not await CheckCanCarry_Single():
        return
    r.a = v.SecondObject
    r.cp(mem[r.ix + 1])
    if r.zf:
        return await printer.PrintCannotDoThat()
    r.iy = v.Noun2Record
    r.a = v.CommandId
    r.cp(CMD_PUT_ON)
    if not r.zf and not bit_set(FLAG_ACTIVE, r.iy + 7):
        r.a = REASON_CLOSED
        return await objects.PrintStateIY()
    r.a = sub8(mem[r.iy + 2], mem[r.ix + 2])       # capacity minus the weight
    if not r.cf:
        left = r.a
        r.a = v.SecondObject
        objects.SumHeldWeight()
        r.b = r.a
        r.a = sub8(left, r.b)
    r.hl = MsgTooFull
    if r.cf or r.zf:
        return await printer.PrintMessage()
    if not objects.CommitOrAbort():
        return
    r.a = mem[r.iy + 0x10]
    mem[r.ix + 0x10] = r.a
    r.a = v.SecondObject
    mem[r.ix + 1] = r.a


async def L929C():
    """Command handler (via $C730), eat/drink the first object: when it lies
    inside something, that holder loses bit 2 and the meal is worth 1, else 10;
    L929C_0 on from there."""
    if not objects.CommitOrAbort():
        return
    r.ix = v.Noun1Record
    r.a = mem[r.ix + 1]
    r.cp(0xFF)
    if r.zf:
        return await L929C_0()
    objects.FindObject()
    mem[r.ix + 7] &= ~4 & 0xFF
    r.a = 0x01
    return await L929C_1()


async def L929C_0():
    """Eat a thing that lies about (worth 10): the actor's strength (+5) grows by
    the meal; the thing goes to nobody and all its places to location 0 (a B of
    0 would be 256 passes). At $80 or more: "Foul gluttony has killed" the
    subject."""
    if not objects.CommitOrAbort():
        return
    r.a = 0x0A
    return await L929C_1()


async def L929C_1():
    r.ix = v.ActorRecord
    r.a = add8(r.a, mem[r.ix + 5])
    r.cp(0x80)
    if not r.cf:                                   # L929C_3
        r.hl = MsgFoulGluttonyHasKilled
        await printer.PrintMessage()
        r.a = v.Subject
        return await engine.KillCharacter()        # (the code after it is never run)
    mem[r.ix + 5] = r.a
    r.ix = v.Noun1Record
    mem[r.ix + 1] = 0xFF
    r.b = mem[r.ix + 0]
    while True:
        mem[r.ix + 0x10] = 0
        r.ix = r.ix + 1 & 0xFFFF
        r.b = r.b - 1 & 0xFF
        if r.b == 0:
            break


async def StrikeObject():
    """Strike the first object, perhaps with a weapon (second object). Refused
    for a liquid, defence 0, a weapon of attack 0 or without a "strike" verb
    entry; "<object> is broken" when already broken. When performing: strength =
    random spread (unsigned add, so a negative one saturates at $FF) + the
    weapon's attack + the subject's attack; at least the defence (+6) breaks the
    object (name "broken", attack halved, contents spilled when state < 2); then
    the weapon is tested against the object's defence the same way. EmptyFirstObject
    spills FirstObject also for the weapon (kept)."""
    r.ix = v.Noun1Record
    if bit_set(FLAG_CONSUMABLE, r.ix + 7):
        return await objects.RefuseCommand()
    if bit_set(FLAG_DEAD, r.ix + 7):
        return await StrikeObject_4()
    r.a = 0                                        # SUB A
    r.cp(mem[r.ix + 6])
    if r.zf:
        return await objects.RefuseCommand()       # defence 0: unbreakable
    r.b = r.a                                      # no weapon: attack 0
    r.a = r.set_zs(v.SecondObject + 1 & 0xFF)
    if not r.zf:
        r.iy = v.Noun2Record
        r.a = mem[r.iy + 5]
        r.set_zs(r.a)
        if r.a == 0:
            return await objects.RefuseCommand()   # attack 0: not a weapon
        target = r.ix
        r.ix = v.Noun2Record
        r.a = CMD_STRIKE
        objects.FindVerbEntry()
        r.ix = target
        r.a = r.set_zs(r.a + 1 & 0xFF)
        if r.zf:
            return await objects.RefuseCommand()
        r.b = mem[r.iy + 5]
    if not objects.CommitOrAbort():                # StrikeObject_0
        return
    r.a = STRIKE_SPREAD
    objects.RandomSigned()
    r.a = add8(r.a, r.b)
    r.iy = v.ActorRecord
    r.a = add8(r.a, mem[r.iy + 5])                 # only this carry saturates
    if r.cf:
        r.a = 0xFF
    r.a = sub8(r.a, mem[r.ix + 6])
    if not r.cf:                                   # the object breaks
        mem[r.ix + 7] |= 1 << FLAG_DEAD
        r.a = v.FirstObject
        objects.MarkBrokenOrDead()
        mem[r.ix + 5] = mem[r.ix + 5] >> 1 | mem[r.ix + 5] & 0x80    # SRA
        r.a = mem[r.ix + 4]
        r.cp(0x02)
        if r.cf:
            await objects.EmptyFirstObject()
        r.a = REASON_BROKEN
        await objects.PrintStateIX()
    r.a = v.SecondObject                           # StrikeObject_2
    r.cp(NO_OBJECT)
    if r.zf:
        return
    r.iy = v.Noun2Record
    if bit_set(FLAG_DEAD, r.iy + 7):
        return
    r.b = mem[r.iy + 6]
    r.a = STRIKE_SPREAD
    objects.RandomSigned()
    r.a = add8(r.a, r.b)
    if r.cf:
        r.a = 0xFF
    r.a = sub8(r.a, mem[r.ix + 6])
    if r.cf:
        return                                     # the weapon holds
    mem[r.iy + 7] |= 1 << FLAG_DEAD
    r.a = v.SecondObject
    objects.MarkBrokenOrDead()
    r.a = mem[r.iy + 5]
    r.a = r.a >> 1 | r.a & 0x80                    # SRA A
    mem[r.iy + 5] = r.a
    await objects.EmptyFirstObject()
    r.ix = r.iy                                    # the message names the weapon
    return await StrikeObject_4()


async def StrikeObject_4():
    """"<IX> is broken"."""
    r.a = REASON_BROKEN
    return await objects.PrintStateIX()


async def GiveObject():
    """Give the first object to the second: the subject must hold it, and the
    recipient's capacity (+3) must cover its load plus the object's bulk (the
    sum wraps at 256). When performing the holder becomes the recipient and the
    location the recipient's, MoveCarried finishes."""
    r.iy = v.Noun2Record
    objects.CheckObject1Held()
    r.hl = MsgNotCarrying
    if not r.cf:
        return await printer.PrintMessage()
    r.a = v.SecondObject
    objects.SumHeldBulk()
    r.ix = v.Noun1Record
    r.a = add8(r.a, mem[r.ix + 3])
    r.b = r.a                                      # PUSH AF / POP BC
    r.c = flags_byte()
    r.a = sub8(mem[r.iy + 3], r.b)
    r.hl = MsgCarryingTooMuch
    if r.cf:
        return await printer.PrintMessage()
    if not objects.CommitOrAbort():
        return
    r.a = v.SecondObject
    mem[r.ix + 1] = r.a
    r.a = mem[r.iy + 0x10]
    mem[r.ix + 0x10] = r.a
    r.b = r.a
    r.a = v.FirstObject
    return await objects.MoveCarried()


async def ExamineObject():
    """Examine the first object: print its description message (+14, +15), else
    "<subject> see <name>." """
    if not objects.CommitOrAbort():
        return
    r.a = v.FirstObject
    objects.FindObject()
    r.l = mem[r.ix + 0x0E]
    r.h = mem[r.ix + 0x0F]
    r.a = r.set_zs(r.h | r.l)
    r.cf = False
    if not r.zf:
        return await printer.PrintMessage()
    r.hl = MsgSee
    await printer.PrintMessage()
    r.iy = r.ix
    await objects.PrintObjectName()
    r.a = CHAR_FULLSTOP
    await screen.PrintChar()
    await screen.PrintNewLine()


async def L9404():
    """Command handler (via $C730), empty a container: it must be open
    ("<it> is closed" otherwise) and hold something present (else state 2,
    "empty"); when performing its contents are emptied (EmptyFirstObject) and
    bit 2 of its flags is cleared."""
    r.ix = v.Noun1Record
    handlers.CheckOpen()
    if r.zf:
        return await objects.PrintStateIX()
    r.a = v.FirstObject
    objects.CountHeldPresent()
    r.cp(0)
    if r.zf:
        r.a = 0x02
        return await objects.PrintStateIX()
    if not objects.CommitOrAbort():
        return
    await objects.EmptyFirstObject()
    mem[r.ix + 7] &= ~4 & 0xFF


async def L9404_1():
    """Command handler (world tables), send the first object down the river:
    among the places of the second object (the river's location list) find the
    actor's location; the object goes to the next one (0 when it was the last),
    "gets swept away", and the player is moved along with it (MoveCarried); the
    game ends if the player's location became 0."""
    if not await CheckCanCarry_Single():
        return
    if not objects.CommitOrAbort():
        return
    r.a = v.ActorLocation
    r.ix = v.Noun2Record
    r.b = mem[r.ix + 0]
    while True:
        r.cp(mem[r.ix + 0x10])
        if r.zf:
            break
        r.ix = r.ix + 1 & 0xFFFF
        r.b = r.b - 1 & 0xFF
        if r.b == 0:                               # DJNZ: B = 0 would scan 256
            return await printer.PrintCannotDoThat()
    r.a = mem[r.ix + 0x11]                         # L9404_3: the next place
    r.b = r.b - 1 & 0xFF
    r.set_zs(r.b)
    if r.zf:
        r.a = 0                                    # XOR A: it was the last one
    place = r.a
    r.hl = MsgGetsSweptAway
    await printer.PrintMessage()
    r.a = place
    r.ix = v.Noun1Record
    mem[r.ix + 0x10] = r.a
    mem[r.ix + 1] = 0xFF
    r.b = r.a
    r.a = v.FirstObject
    await objects.MoveCarried()
    r.a = mem[Chr00PlayerLocation]
    r.set_zs(r.a)
    r.cf = False
    if r.zf:
        return await EndGame()


async def L9404_5():
    """Lock-style handler (entered from LA244): unless CheckOpenable refuses, the
    operation byte is $C6 (SET 0)."""
    handlers.CheckOpenable()
    if not r.zf:
        return await objects.PrintStateIX()
    r.a = 0xC6
    return await L9404_6()


async def L9404_6():
    """Write the operation byte A of SmcSetOrRes ($C6 SET 0 or $86 RES 0), refuse
    when the key (second object) is broken (bit 3: "...broken"), then do it."""
    mem[labels.SmcSetOrRes + 3] = r.a
    r.iy = v.Noun2Record
    if bit_set(3, r.iy + 7):
        r.a = 0x83
        return await objects.PrintStateIY()
    if not objects.CommitOrAbort():
        return
    return await SmcSetOrRes()


async def SmcSetOrRes():
    """SET 0,(IX+7) or RES 0,(IX+7): the instruction's operation byte (at +3) was
    written by L9404_6 ($C6 SET, $86 RES)."""
    if mem[labels.SmcSetOrRes + 3] == 0xC6:
        mem[r.ix + 7] |= 1
    else:
        mem[r.ix + 7] &= ~1 & 0xFF


async def L9404_7():
    """Unlock-style handler (entered from LA244): the first object must have bit 0
    set (else state 0), CheckOpenable_0 must allow it; the operation is $86
    (RES 0)."""
    r.ix = v.Noun1Record
    set_ = bit_set(0, r.ix + 7)
    r.a = 0x00
    if not set_:
        return await objects.PrintStateIX()
    handlers.CheckOpenable_0()
    if not r.zf:
        return await objects.PrintStateIX()
    r.a = 0x86
    return await L9404_6()


async def L9404_8():
    """Command handler (world tables), put the first object through the exit
    whose obstacle is the second object ($9F28 search): the subject must hold
    it, the second object must be open (bit 5, else state 5); the object goes
    to the exit's destination (+2) held by nobody, and MoveCarried finishes."""
    if not await RequireHeld():
        return
    r.a = v.SecondObject
    objects.FindExitByObstacle_0()
    r.cp(0xFF)
    if r.zf:
        return await objects.RefuseCommand()
    r.iy = v.Noun2Record
    if not bit_set(5, r.iy + 7):
        r.a = 0x05
        return await objects.PrintStateIY()
    if not objects.CommitOrAbort():
        return
    r.b = mem[r.ix + 2]
    r.ix = v.Noun1Record
    mem[r.ix + 1] = 0xFF
    mem[r.ix + 0x10] = r.b
    r.a = v.FirstObject
    return await objects.MoveCarried()
