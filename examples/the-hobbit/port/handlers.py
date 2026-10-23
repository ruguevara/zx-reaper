"""Ported from src/handlers.asm: handlers of particular objects and characters, the victory check.
Values pass in the registers `r` (port/regs.py); conventions: port/CONTRACT.md.

Most routines here are verb handlers (reached through the object verb tables),
NPC script routines (op 3) and timer routines, all called with
`calls.call_at`. Every entry of a label chain (LA244, LA244_0, ...) that a
table or another routine uses is a function; a label that only the chain
itself branches to is inline. `objects.CommitOrAbort()` and
`engine.AbortUnlessPerform()` return False where the asm pops the caller's
return address: the handler then returns at once."""
from labels import *  # noqa: F403  (first: port functions shadow routine labels)
import calls  # noqa: F401
import engine
import labels
import objects
import parser
import printer
import verbs
from regs import r
from variables import v
from zxpyxel import Goto, mem, mem16, zx  # noqa: F401


def _bit(n, value):
    """BIT n,value: Z set when the bit is clear (carry untouched)."""
    r.zf = not value >> n & 1
    r.pf = r.zf
    r.sf = n == 7 and bool(value & 0x80)


def _logic(a):
    """Flags of AND/OR/XOR leaving a: Z, S, P (even parity), carry clear."""
    r.zf, r.sf, r.cf = a == 0, a > 0x7F, False
    r.pf = bin(a).count('1') % 2 == 0


def _res(addr, n):
    mem[addr] = mem[addr] & ~(1 << n) & 0xFF


def _set(addr, n):
    mem[addr] = mem[addr] | 1 << n


def IsPlacingCommand():
    """Test whether the command puts an object somewhere (drop in, put in, put
    on, take out of, throw through). O: Z set when it does; A = CommandId; HL
    and BC kept; carry and S from the last compare."""
    r.a = v.CommandId
    for k in range(5):
        r.cp(mem[IdList + k])
        if r.zf:
            break


async def PrintSpeech():
    """Print `<subject> say "<HL message>".` I: HL the words spoken. Leaves A = 1
    and what PrintMessage leaves."""
    words = r.hl
    r.hl = MsgSay
    await printer.PrintMessage()
    r.hl = words
    r.a = 1
    v.CapitalNext = 1                               # the speech starts with a capital
    await printer.PrintMessage()
    r.hl = MsgB00F
    return await printer.PrintMessage()


def CheckOpenable():
    """Say why the first object cannot be opened, or that it can. O: A state id
    (REASON_LOCKED, else REASON_OPEN), NZ refused (locked or already open), Z
    may be opened; IX = Noun1Record."""
    r.ix = v.Noun1Record
    _bit(FLAG_LOCKED, mem[r.ix + 7])
    r.a = REASON_LOCKED
    if not r.zf:
        return
    return CheckOpenable_0()


def CheckOpenable_0():
    """The open test of CheckOpenable on the record in IX. O: A REASON_OPEN; NZ
    when open already, Z when closed."""
    _bit(FLAG_ACTIVE, mem[r.ix + 7])
    r.a = REASON_OPEN


async def LA244():
    """Handler: only the test pass (CommitOrAbort), nothing else."""
    objects.CommitOrAbort()


async def LA244_0():
    """Tie the rope ($12) to an object. Refused unless the rope is the second
    object, the first is not fixed, and nothing is tied to the rope yet. When
    the rope is the first object the handler runs again with the two objects
    swapped (L9F4A). The subject takes the rope first when not holding it."""
    r.a = v.FirstObject
    r.cp(0x12)
    if r.zf:
        r.hl = labels.LA244_0
        return await objects.L9F4A()
    r.a = v.SecondObject
    r.cp(0x12)
    if not r.zf:
        return await objects.RefuseCommand()
    r.ix = v.Noun1Record
    _bit(1, mem[r.ix + 7])
    if not r.zf:
        return await objects.RefuseCommand()
    objects.CountHeldPresent()                      # A: what is tied to the rope already
    r.cp(0)
    r.hl = MsgAlreadyTied
    if not r.zf:
        return await printer.PrintMessage()
    _bit(3, mem[r.ix + 7])
    if r.zf:
        _bit(6, mem[r.ix + 7])
        if not r.zf:
            return await objects.RefuseCommand()
    if not objects.CommitOrAbort():
        return
    r.iy = v.Noun2Record
    objects.CheckObject1Held()                      # carry: held by the subject
    r.a = v.SecondObject
    mem[r.ix + 1] = r.a                             # the object's holder: the rope
    if not r.cf:
        r.a = 0
        v.ActionPerform = 0
        await verbs.VerbTake()                      # take the rope first
        r.a = v.ActionAllowed
        r.cp(0)
        r.a = 1
        v.ActionPerform = 1
        v.ActionAllowed = 1
        if r.zf:                                    # the take was refused
            mem[r.iy + 1] = 0xFF
            return
    r.a = v.Subject
    mem[r.iy + 1] = r.a                             # the rope's holder: the subject


async def LA244_5():
    """Untie: the first object must be tied to the rope; its holder becomes the
    rope's holder."""
    r.ix = v.Noun1Record
    r.a = mem[r.ix + 1]
    r.cp(0x12)
    r.hl = MsgNotTied
    if not r.zf:
        return await printer.PrintMessage()
    if not objects.CommitOrAbort():
        return
    r.a = mem[Obj12RopeHolder]
    mem[r.ix + 1] = r.a


async def LA244_6():
    """Walk through the exit that has the first object as its obstacle: with no
    destination in the exit only the test pass; else MoveActor along the exit
    (its direction as the command, the object's bit 5 set meanwhile)."""
    objects.FindExitByObstacle()
    r.a = mem[r.ix + 2]
    r.cp(0)
    if r.zf:
        objects.CommitOrAbort()
        return
    r.a = mem[r.ix]
    command = mem16[CommandId]
    v.CommandId = r.a
    r.ix = v.Noun1Record
    _set(r.ix + 7, 5)
    ix = r.ix
    r.a = 0xFF
    v.FirstObject = r.a
    await verbs.MoveActor()
    r.ix = ix
    _res(r.ix + 7, 5)
    r.hl = command
    mem16[CommandId] = r.hl                         # both bytes: CommandId and the next one


async def LA244_8():
    """Handler for the subject $3C only (else refused): test pass, then L977C."""
    r.a = v.Subject
    r.cp(0x3C)
    if not r.zf:
        return await objects.RefuseCommand()
    if not objects.CommitOrAbort():
        return
    return await engine.L977C()


async def LA244_9():
    """Touching the river: "As soon as ... touch the river", then the subject dies."""
    if not objects.CommitOrAbort():
        return
    r.hl = MsgAsSoonAsTouchRiver
    return await LA244_10()


async def LA244_11():
    """Falling asleep: the subject dies."""
    if not objects.CommitOrAbort():
        return
    r.hl = MsgFallAsleep
    return await LA244_10()


async def LA244_10():
    """Print HL, then "time passes" when the subject is the player, and kill the
    subject (KillCharacter, A = Subject)."""
    await printer.PrintMessage()
    subject = v.Subject
    r.a = subject
    _logic(subject)
    r.hl = MsgTimePasses2
    if r.zf:
        await printer.PrintMessage()
    r.a = subject                                   # POP AF
    _logic(subject)
    return await engine.KillCharacter()


async def LA244_12():
    """Lock/key handler with B = 2."""
    r.b = 2
    return await LA244_15()


async def LA244_13():
    """Lock/key handler with B = $0F."""
    r.b = 0x0F
    return await LA244_15()


async def LA244_14():
    """Lock/key handler with B = 4."""
    r.b = 4
    return await LA244_15()


async def LA244_15():
    """Lock B opened or locked by the second object: with the right key (the
    second object = B) lock (command $25) or unlock; with another of the three
    keys "does not fit"; with anything else "I cannot do that"."""
    r.a = v.SecondObject
    r.cp(r.b)
    if r.zf:
        r.a = v.CommandId
        r.cp(0x25)
        if r.zf:
            return await verbs.L9404_5()
        return await verbs.L9404_7()
    r.cp(2)
    if r.zf:
        return await PrintNoFit()
    r.cp(4)
    if r.zf:
        return await PrintNoFit()
    r.cp(0x0F)
    if not r.zf:
        return await printer.PrintCannotDoThat()
    return await PrintNoFit()


async def PrintNoFit():
    """Print that the key does not fit this lock."""
    r.hl = MsgDoesNotFitThisLock
    return await printer.PrintMessage()


async def LA35E():
    """Open: test pass (AbortUnlessPerform), then OpenObject_0 on Noun1Record."""
    if not engine.AbortUnlessPerform():
        return
    r.ix = v.Noun1Record
    return await verbs.OpenObject_0()


async def OpenCrack():
    """Open the small insignificant crack: only an actor in the dark stuffy
    passage LOC_DARK_STUFFY_PASSA_0F can; else refused. Then OpenObject."""
    r.ix = v.ActorRecord
    r.a = mem[r.ix + 0x10]
    r.cp(LOC_DARK_STUFFY_PASSA_0F)
    if not r.zf:
        return await objects.RefuseCommand()
    return await verbs.OpenObject()


async def LA377():
    """Handler (spiders): if the first object has bit 3 set, set its bit 5, start
    timer 1 and print "Some spiders start"; else nothing (Z from BIT)."""
    r.ix = v.Noun1Record
    _bit(3, mem[r.ix + 7])
    if r.zf:
        return
    _set(r.ix + 7, 5)
    r.a = v.Timer1Start
    mem[Timer1Counter] = r.a
    r.hl = MsgSomeSpidersStart
    return await printer.PrintMessage()


async def LA377_0():
    """Put on the golden ring: the actor turns invisible (bit 7 of its flags
    cleared, its +5 halved twice), the ring is held by the subject, and timer 6
    starts at 2 + RandomUpTo(8)."""
    if not objects.CommitOrAbort():
        return
    r.iy = v.ActorRecord
    r.ix = Obj10ValuableGoldenRing
    _res(r.iy + 7, 7)
    mem[r.iy + 5] >>= 1
    mem[r.iy + 5] >>= 1
    _res(r.ix + 7, 7)
    r.a = v.Subject
    mem[r.ix + 1] = r.a
    r.a = 8
    objects.RandomUpTo()
    r.cf = r.a + 2 > 0xFF
    r.a = r.a + 2 & 0xFF
    r.set_zs(r.a)
    mem[Timer6Counter] = r.a


async def LA377_1():
    """Take off the golden ring: "not wearing" if it is not worn (bit 7 of the
    ring set means visible); else the actor turns visible again (+5 doubled
    twice) and timer 6 stops."""
    r.ix = v.ActorRecord
    r.iy = Obj10ValuableGoldenRing
    _bit(7, mem[r.iy + 7])
    r.hl = MsgNotWearing
    if not r.zf:
        return await printer.PrintMessage()
    if not objects.CommitOrAbort():
        return
    _set(r.iy + 7, 7)
    _set(r.ix + 7, 7)
    mem[r.ix + 5] = mem[r.ix + 5] << 1 & 0xFF
    mem[r.ix + 5] = mem[r.ix + 5] << 1 & 0xFF
    r.a = 0
    mem[Timer6Counter] = 0


async def VerbCapture():
    """Capture: send the first object (a character) to a prison, the elvenking's
    dark dungeon for the wood elf and the butler, else the goblins' dungeon.
    Refused when the two share a side bit, the object is no character, or the
    capturer is in the prison already. When the captive is the player the
    prison is described unless dark. B = the prison."""
    r.ix = v.Noun1Record
    r.a = mem[r.ix + 4] & STATE_SIDE_BITS
    captive = r.ix
    r.ix = v.ActorRecord
    r.a &= mem[r.ix + 4]
    _logic(r.a)
    r.ix = captive
    if not r.zf:
        return await objects.RefuseCommand()
    _bit(FLAG_CHARACTER, mem[r.ix + 7])
    if r.zf:
        return await objects.RefuseCommand()
    r.a = v.Subject
    r.b = LOC_DARK_DUNGEON
    if r.a not in (CHR_WOOD_ELF, CHR_BUTLER):
        r.b = LOC_GOBLINS_DUNGEON
    r.a = v.ActorLocation
    r.cp(r.b)
    if r.zf:
        return await objects.RefuseCommand()
    if not objects.CommitOrAbort():
        return
    r.ix = v.Noun1Record
    mem[r.ix + 0x10] = r.b
    mem[r.ix + 1] = AT_LOCATION
    r.a = v.FirstObject
    await objects.MoveCarried()                     # what the captive carries goes along
    r.a = v.FirstObject
    r.cp(PLAYER)
    if not r.zf:
        return
    v.Subject = r.a                                 # the player is the subject (A = 0)
    r.hl = Chr00Player
    v.ActorRecord = r.hl
    engine.CheckDark()
    if r.cf:
        return
    r.a = r.b
    r.hl = MsgSubjIsIn
    return await engine.DescribeLocation_Intro()


async def RespawnKilledGoblin():
    """Chained after VerbAttack in the verb table of each of the six goblins.
    When the attacked goblin is dead, it comes back: dead flag cleared, its
    NPC state slot gets its id, its home location and second name phrase are
    restored from RecordTable; prints "falls down a hole and vanishes" and, if
    the player's location equals B, "Another goblin enters." Quirk: B is not
    set here (a leftover of the dispatcher), so the last line is unreliable."""
    r.ix = v.Noun1Record
    _bit(FLAG_DEAD, mem[r.ix + 7])
    if r.zf:
        return
    _res(r.ix + 7, FLAG_DEAD)
    r.de = RESPAWN_RECORD_SIZE
    r.iy = RecordTable
    r.a = v.FirstObject
    while True:                                     # RespawnKilledGoblin_Find
        r.cp(mem[r.iy])
        if r.zf:
            break
        r.iy = r.iy + r.de & 0xFFFF
    r.hl = r.iy + 1 & 0xFFFF
    r.e = mem[r.hl]
    r.hl = r.hl + 1 & 0xFFFF
    r.d = mem[r.hl]
    mem[r.de] = r.a                                 # the NPC state's id slot
    r.hl = r.hl + 1 & 0xFFFF
    r.a = mem[r.hl]
    mem[r.ix + 0x10] = r.a                          # home location
    r.hl = r.hl + 1 & 0xFFFF
    r.a = mem[r.hl]
    mem[r.ix + 0x0A] = r.a                          # second name phrase, replacing "dead"
    r.hl = r.hl + 1 & 0xFFFF
    r.a = mem[r.hl]
    mem[r.ix + 0x0B] = r.a
    r.hl = MsgFallsDownHoleVanishes
    await printer.PrintMessage()
    r.a = mem[Chr00PlayerLocation]
    r.cp(r.b)
    if not r.zf:
        return
    r.de = WORD_ANOTHER
    await printer.PrintWord()
    r.de = WORD_GOBLIN
    await printer.PrintWord()
    r.hl = MsgEnters2
    return await printer.PrintMessage()


async def LA4C0():
    """Open (the goblins' door): only an actor at location $10; OpenObject, then
    the test pass; start timer 3."""
    r.ix = v.ActorRecord
    r.a = mem[r.ix + 0x10]
    r.cp(0x10)
    if not r.zf:
        return await objects.RefuseCommand()
    await verbs.OpenObject()
    if not engine.AbortUnlessPerform():
        return
    r.a = v.Timer3Start
    mem[Timer3Counter] = r.a


async def LA4C0_0():
    """Timer routine: clear bit 5 (open) of the door Obj11DoorFlags."""
    r.hl = Obj11DoorFlags
    _res(r.hl, 5)


async def NpcAnswersGift():
    """Script routine of behaviour $1D (give): the character says "Thank you",
    or with RandomUpTo(10) >= 8 "What do you expect me to do with this ?"."""
    if not objects.CommitOrAbort():
        return
    r.a = 0x0A
    objects.RandomUpTo()
    r.hl = MsgWhatDoExpectMeDo
    r.cp(8)
    if not r.cf:
        return await PrintSpeech()
    r.hl = MsgThank
    return await PrintSpeech()


async def LA4F5():
    """Handler: the character says "What's this ?"."""
    if not objects.CommitOrAbort():
        return
    r.hl = MsgWhatSThis
    return await PrintSpeech()


async def GandalfCheers():
    """Script routine: Gandalf says one of "You are doing a great job", "Hurry
    up", "Hello" (RandomUpTo(2))."""
    if not objects.CommitOrAbort():
        return
    r.a = 2
    objects.RandomUpTo()
    r.hl = MsgDoingGreatJob
    r.cp(0)
    if r.zf:
        return await PrintSpeech()
    r.hl = MsgHurryUp
    r.cp(1)
    if r.zf:
        return await PrintSpeech()
    r.hl = MsgHello
    return await PrintSpeech()


async def LA51C():
    """Handler: the character says "This was Thrain's key"."""
    if not objects.CommitOrAbort():
        return
    r.hl = MsgThisWasThrainsKey
    return await PrintSpeech()


async def ElrondGreets():
    """Script routine: Elrond says "Hello" when he is where the player is; else
    returns NZ before the test pass (the script takes its alternative step)."""
    r.a = v.ActorLocation
    r.hl = PlayerLocation
    r.cp(mem[r.hl])
    if not r.zf:
        return
    if not objects.CommitOrAbort():
        return
    r.hl = MsgHello
    return await PrintSpeech()


async def LA536():
    """Handler for the subject $40 only (else refused): OpenObject."""
    r.a = v.Subject
    r.cp(0x40)
    if not r.zf:
        return await objects.RefuseCommand()
    return await verbs.OpenObject()


async def LA536_0():
    """Let go: the first object must be the actor's holder ((IY+1) = the object)
    and open ("<it> is closed" otherwise); the actor then has no holder ($FF)."""
    r.iy = v.ActorRecord
    r.a = v.FirstObject
    r.cp(mem[r.iy + 1])
    if not r.zf:
        return await objects.RefuseCommand()
    objects.FindObject()
    CheckOpen()
    if r.zf:
        return await objects.PrintStateIX()
    if not objects.CommitOrAbort():
        return
    mem[r.iy + 1] = 0xFF


async def LA536_1():
    """Climb into the first object (a holder the actor can reach but is not in):
    follow the holder chain from the object up; if it passes the subject, the
    object is taken out of it. The object must be open, and the actor with
    what it carries must fit (MsgTooBig). Then the actor's holder is the
    object."""
    r.iy = v.ActorRecord
    r.a = v.FirstObject
    r.cp(mem[r.iy + 1])
    if r.zf:
        return await objects.RefuseCommand()
    r.iy = v.Noun1Record
    objects.ActorCanReach()
    if r.zf:
        return await objects.RefuseCommand()
    r.a = v.FirstObject
    while True:                                     # LA536_2: up the holder chain
        objects.FindObject()
        r.a = mem[r.ix + 1]
        r.cp(0xFF)
        if r.zf:
            break
        r.a = v.Subject
        r.cp(mem[r.ix + 1])
        r.a = mem[r.ix + 1]
        if r.zf:                                    # the chain reaches the subject:
            r.ix = v.Noun1Record                    # the object leaves its holder
            mem[r.ix + 1] = 0xFF
            break
    r.iy = v.ActorRecord                            # LA536_3
    r.a = v.Subject
    objects.SumHeldWeight()
    total = r.a + mem[r.iy + 2]
    r.cf = total > 0xFF
    r.a = total & 0xFF
    if not r.cf:                                    # (sic) no carry: B = $FF
        r.a = 0xFF
    r.b = r.a
    r.ix = v.Noun1Record
    CheckOpen()
    if r.zf:
        return await objects.PrintStateIX()
    r.a = mem[r.ix + 2]
    r.cp(0xFF)
    if not r.zf:
        r.cp(r.b)                                   # SUB B
        r.a = r.a - r.b & 0xFF
        r.hl = MsgTooBig
        if not r.cf:
            return await printer.PrintMessage()
    if not objects.CommitOrAbort():
        return
    r.a = v.FirstObject
    mem[r.iy + 1] = r.a


def CheckOpen():
    """Test whether the object IX is open. O: A = REASON_CLOSED; Z set when
    closed (bit FLAG_ACTIVE clear)."""
    _bit(FLAG_ACTIVE, mem[r.ix + 7])
    r.a = REASON_CLOSED


async def WargHowls():
    """Script routine: after the test pass, when the player is in the warg's
    location print "The vicious warg run around you and howls."."""
    if not objects.CommitOrAbort():
        return
    r.hl = Chr43WargLocation
    r.a = mem[Chr00PlayerLocation]
    r.cp(mem[r.hl])
    if not r.zf:
        return
    r.hl = MsgViciousWargRunAround
    return await engine.PrintMessageDot()


async def LA5E2():
    """Handler (barrel moves, via $C302): when the first object is the barrel
    ($13) and really performed, the barrel at location $21 (forest river) sets
    timer 0 to 2."""
    r.a = v.FirstObject
    r.cp(0x13)
    if not r.zf:
        return
    if not engine.AbortUnlessPerform():
        return
    r.ix = Obj13Barrel
    r.a = mem[r.ix + 0x10]
    r.cp(0x21)
    if not r.zf:
        return
    r.a = 2
    mem[Timer0Counter] = r.a


async def LA5E2_0():
    """Timer 0: the barrel floats down to the bank ($22), quietly empties and
    comes to rest at $20 with the wine; the player in it is thrown out."""
    r.a = 0
    v.TimersFired = r.a
    r.a = mem[Chr00PlayerHolder]
    r.cp(0x13)
    r.hl = MsgThrownOntoBankLong
    if r.zf:
        await printer.PrintMessage()
    r.a = 0x22
    mem[Obj13BarrelLocation] = r.a
    r.b = r.a
    r.a = 0x13
    await objects.MoveCarried()
    r.ix = Obj13Barrel
    mem[r.ix + 0x10] = 0x20
    _res(r.ix + 7, 5)
    _set(r.ix + 7, 2)
    r.a = 0
    v.MessagesVisible = 0
    r.a = 0x13
    await objects.EmptyHolder()
    r.a = 1
    v.MessagesVisible = 1
    r.iy = Obj14Wine
    mem[r.iy + 0x10] = 0x20
    mem[r.iy + 1] = 0x13


async def ThorinMissesThief():
    """Script routine: when Thorin is with the player and the player is
    invisible (flag bit FLAG_PRESENT clear) he says "Where's the thief ?"; else
    returns NZ before the test pass."""
    r.a = v.ActorLocation
    r.hl = PlayerLocation
    r.cp(mem[r.hl])
    if not r.zf:
        return
    r.a = mem[Chr00PlayerFlags]
    _bit(FLAG_PRESENT, r.a)
    if not r.zf:
        return
    if not objects.CommitOrAbort():
        return
    r.hl = MsgWhereSThief
    return await PrintSpeech()


async def ThorinTalks():
    """Script routine: after the test pass, by RandomUpTo(8): 0 Thorin sits down
    and sings about gold, 1-2 "Hurry up", 3-4 "Thorin wait", 5+ nothing. Quirk:
    the "Get us out of this one, thief !" branch can never run (Z after a CP 3
    that already sent 3 and more away)."""
    if not objects.CommitOrAbort():
        return
    r.a = 8
    objects.RandomUpTo()
    r.cp(5)
    if not r.cf:
        return
    r.cp(3)
    r.hl = MsgThorinWait
    if not r.cf:
        return await engine.PrintMessageDot()
    r.hl = MsgGetUsOutThisOne
    if r.zf:                                        # never
        return await PrintSpeech()
    r.hl = MsgThorinSitsDownStarts
    r.cp(0)
    if r.zf:
        return await engine.PrintMessageDot()
    r.hl = MsgHurryUp
    return await PrintSpeech()


async def LA67E():
    """Open or close a door of the dragon's lair from outside ($C2F0, $C2F3):
    the actor must be at location $20; CommandId $0C closes, else opens."""
    r.ix = v.ActorRecord
    r.a = mem[r.ix + 0x10]
    r.cp(0x20)
    r.hl = MsgCannotReach
    if not r.zf:
        return await printer.PrintMessage()
    r.a = v.CommandId
    r.cp(0x0C)
    if r.zf:
        return await verbs.CloseObject()
    return await verbs.OpenObject()


async def LA67E_0():
    """Timer: the dragon comes to the player's location, if that is $27, $2C or
    $29, and "<dragon> enters" (the name phrase goes on the message stack)."""
    r.a = mem[Chr00PlayerLocation]
    r.cp(0x27)
    if not r.zf:
        r.cp(0x2C)
        if not r.zf:
            r.cp(0x29)
            if not r.zf:
                return
    if not objects.CommitOrAbort():
        return
    r.a = mem[Chr00PlayerLocation]
    r.hl = Chr3CDragonLocation
    r.cp(mem[r.hl])
    if r.zf:
        return
    mem[r.hl] = r.a
    r.a = 1
    v.MessagesVisible = 1
    r.hl = Chr3CDragonName
    printer.msg_args.append(r.hl)
    r.hl = MsgEnters
    return await printer.PrintMessage()


async def LA67E_3():
    """Script routine: when the dragon is where the player is: after the test
    pass he says "I may not..." to a visible player, "Well, thief" (bit 7 of
    the player's flags clear: invisible) otherwise."""
    r.a = mem[Chr00PlayerLocation]
    r.hl = ActorLocation
    r.cp(mem[r.hl])
    if not r.zf:
        return
    if not objects.CommitOrAbort():
        return
    r.a = mem[Chr00PlayerFlags] & 0x80
    _logic(r.a)
    r.hl = MsgDragonSaysIMayNot
    if not r.zf:
        r.hl = MsgDragonSaysWellThief
    return await printer.PrintMessage()


async def LA67E_5():
    """Timer: while the treasure is not at $29 and the player's location has bit
    7 set (visible from afar): "In the distance you see a shape"; with
    RandomUpTo(100) >= $50 "The dragon descends" and the game ends. (The asm
    has unreachable code after the EndGame jump.)"""
    r.a = mem[Obj23TreasureLocation]
    r.cp(0x29)
    if r.zf:
        return
    r.a = mem[Chr00PlayerLocation]
    objects.FindLocation()
    _bit(7, mem[r.ix])
    if r.zf:
        return
    if not objects.CommitOrAbort():
        return
    r.a = 1
    v.MessagesVisible = 1
    r.hl = MsgDistanceSeeShape
    r.a = 0x64
    objects.RandomUpTo()
    r.cp(0x50)
    if r.cf:
        return await printer.PrintMessage()
    r.hl = MsgDragonDescends
    await printer.PrintMessage()
    return await verbs.EndGame()


async def LA67E_6():
    """Handler (magic door): after the test pass, "see nothing special" when the
    actor's bit 7 is set; else start timer 5 and "the magic door warns the
    elves"."""
    if not objects.CommitOrAbort():
        return
    r.ix = v.ActorRecord
    _bit(7, mem[r.ix + 7])
    r.hl = MsgSeeNothingSpecialHere
    if not r.zf:
        return await printer.PrintMessage()
    r.a = v.Timer5Start
    mem[Timer5Counter] = r.a
    r.hl = MsgMagicDoorWarnsElves
    return await printer.PrintMessage()


async def ThorinDeathBreaksKey():
    """Chained after VerbAttack in Thorin's verb table. When Thorin is dead and
    the command is really performed, the small curious key is marked broken;
    if the player can reach it, "The small curious key shatters."."""
    r.hl = Chr3FThorinFlags
    _bit(FLAG_DEAD, mem[r.hl])
    if r.zf:
        return
    if not engine.AbortUnlessPerform():
        return
    r.ix = Obj02SmallCuriousKey
    _set(r.ix + 7, FLAG_DEAD)
    r.a = OBJ_SMALL_CURIOUS_KEY
    objects.MarkBrokenOrDead()
    r.a = OBJ_SMALL_CURIOUS_KEY
    r.iy = Chr00Player
    objects.CanReachSwapped()                       # IX = key, IY = player
    if r.zf:
        return
    r.hl = MsgSmallCuriousKey
    return await printer.PrintMessage()


async def LA761():
    """Open or close a window-like object ($C518, $C51B). The player must not be
    inside something (holder $FF) or "cannot reach"; others close ($0C) or
    open ($10)."""
    r.a = v.Subject
    r.cp(0)
    if r.zf:
        r.a = mem[Chr00PlayerHolder]
        r.hl = MsgCannotReach
        r.cp(0xFF)
        if r.zf:
            return await printer.PrintMessage()
        return await objects.RefuseCommand()
    r.a = v.CommandId
    r.cp(0x0C)
    if r.zf:
        return await verbs.CloseObject()
    r.cp(0x10)
    if r.zf:
        return await verbs.OpenObject()


async def LA761_1():
    """Handler (via $C518, $C51B): for the player not free ("cannot reach" with
    holder $FF), then by CommandId: $1E L8F3B, $0B StrikeObject, $18
    VerbLookThrough."""
    r.a = v.Subject
    r.cp(0)
    if r.zf:
        r.a = mem[Chr00PlayerHolder]
        r.cp(0xFF)
        r.hl = MsgCannotReach
        if r.zf:
            return await printer.PrintMessage()
    r.a = v.CommandId
    r.cp(0x1E)
    if r.zf:
        return await verbs.L8F3B()
    r.cp(0x0B)
    if r.zf:
        return await verbs.StrikeObject()
    r.cp(0x18)
    if r.zf:
        return await verbs.VerbLookThrough()


async def LA761_3():
    """Timer 4: sinking into the bog. At location $1D the timer stops first;
    prints "slowly sinking into the bog"; the game ends when the counter is 0."""
    r.a = mem[Chr00PlayerLocation]
    r.cp(0x1D)
    if r.zf:
        r.a = 0
        mem[Timer4Counter] = 0
    r.hl = MsgSlowlySinkingIntoBog
    await printer.PrintMessage()
    r.a = mem[Timer4Counter]
    r.cp(0)
    if not r.zf:
        return
    return await verbs.EndGame()


async def ExamineMap():
    """Examine the curious map. Anyone but Elrond: ExamineObject. When Elrond
    reads it, the exit that InitNewGame erased is put back into its location
    record (while ExitRestoreMode is 0) and he says "Go <direction> from
    <place> to get to <place>". The blocked-exit record is the operand of the
    LD IY at SmcBlockedExit, patched by InitNewGame."""
    r.a = v.Subject
    r.cp(CHR_ELROND)
    if not r.zf:
        return await verbs.ExamineObject()
    if not objects.CommitOrAbort():
        return
    r.iy = mem16[SmcBlockedExit + 2]                # LD IY,nn (self-modified operand)
    r.l = mem[r.iy + 1]
    r.h = mem[r.iy + 2]
    r.a = v.ExitRestoreMode
    r.cp(0)
    if r.zf:
        r.b = 3
        while r.b:                                  # ExamineMap_Restore: the saved triple back
            r.a = mem[r.iy + 3]
            mem[r.hl] = r.a
            r.hl = r.hl + 1 & 0xFFFF
            r.iy = r.iy + 1 & 0xFFFF
            r.b -= 1
        r.iy = mem16[SmcBlockedExit + 2]
    r.a = mem[r.iy + 5]                             # ExamineMap_0: destination
    objects.FindLocation()
    r.ix = r.ix + 2 & 0xFFFF                        # its name phrase
    printer.msg_args.append(r.ix)
    r.a = mem[r.iy]                                 # location of the exit
    objects.FindLocation()
    r.ix = r.ix + 2 & 0xFFFF
    printer.msg_args.append(r.ix)
    r.a = mem[r.iy + 3]                             # direction id
    objects.GetIdWord()
    printer.msg_args.append(r.de)
    r.hl = MsgGoFromGet
    return await PrintSpeech()


def LA814_3():
    """A random 0-99 compared with 50. O: carry set when below 50."""
    r.a = 0x64
    objects.RandomUpTo()
    r.cp(0x32)


async def LA814():
    """Sail the boat across ($C378): the exit with the second object as its
    obstacle; "sails across"; then by luck the boat lands (holder $12) or falls
    short, or the sailor lands on the other side."""
    r.a = v.SecondObject
    objects.FindExitByObstacle_0()
    r.cp(0xFF)
    if r.zf:
        return await objects.RefuseCommand()
    if not objects.CommitOrAbort():
        return
    r.hl = MsgSailsAcross
    await printer.PrintMessage()
    r.a = mem[Obj29BoatLocation]
    r.cp(mem[r.ix + 2])
    if r.zf:                                        # the boat is at the destination
        LA814_3()
        if r.cf:
            r.a = 0x12                              # LA814_0
            mem[Obj29BoatHolder] = r.a
            r.hl = MsgLandsBoat
        else:
            r.hl = MsgFallsJustShortOther
            LA814_3()
            if not r.cf:
                r.hl = MsgLandsBoatButSlidesOut
    else:                                           # LA814_1
        r.hl = MsgFallsJustShortOther
        LA814_3()
        if not r.cf:
            r.a = mem[r.ix + 2]
            r.ix = v.Noun1Record
            mem[r.ix + 0x10] = r.a
            mem[r.ix + 1] = 0xFF
            r.a = v.FirstObject
            await objects.MoveCarried()             # (B is whatever the caller left)
            r.hl = MsgLandsOnOtherSide
    return await printer.PrintMessage()


async def LA814_4():
    """Timer: if the boat's holder is $12, "the boat glides across the river"
    and it moves to the other bank."""
    if not objects.CommitOrAbort():
        return
    r.a = mem[Obj29BoatHolder]
    r.cp(0x12)
    if not r.zf:
        return
    r.hl = MsgBoatGlidesAcrossRiver
    return await LA814_5()


async def LA814_5():
    """Print HL, then move the boat to the other bank ($42 <-> $43), free of
    its holder, with what it carries."""
    await printer.PrintMessage()
    r.a = mem[Obj29BoatLocation]
    r.cp(0x42)
    r.a = 0x42
    if not r.zf:
        r.a = 0x43
    mem[Obj29BoatLocation] = r.a
    r.b = r.a
    r.a = 0xFF
    mem[Obj29BoatHolder] = r.a
    r.a = 0x29
    return await objects.MoveCarried()


async def LA814_7():
    """Handler: the player (Subject 0) pushes the boat: "with a lurch the boat
    glides" and it crosses."""
    if not engine.AbortUnlessPerform():
        return
    r.a = v.Subject
    _logic(r.a)
    if not r.zf:
        return
    r.hl = MsgWithLurchBoatGlides
    return await LA814_5()


async def LA814_8():
    """Timer: the Bard has an order stored (ActorHasOrder = 1): fetch it with
    RunStoredOrder; when usable, refuse the action and make the Bard do the
    command (BardCommandVerb/Args/Op := $42)."""
    r.a = v.ActorHasOrder
    r.cp(1)
    if not r.zf:
        return
    r.a = 0
    v.ActorHasOrder = 0
    r.a = 1
    await parser.RunStoredOrder()
    if r.zf:
        return
    r.a = 0
    v.ActionAllowed = 0
    r.a = v.SavedCommandId
    v.BardCommandVerb = r.a
    r.bc = mem16[FirstObject]
    mem16[BardCommandArgs] = r.bc
    r.a = 0x42
    v.BardCommandOp = r.a


async def GollumAsksRiddle():
    """Script routine: when Gollum is with a visible player (flag FLAG_PRESENT
    set), after the test pass he says the riddle of the chosen random event
    (message word at +2 of its record) and ReplyGiven := 1; else returns before
    the test pass."""
    r.a = mem[Chr44GollumLocation]
    r.hl = PlayerLocation
    r.cp(mem[r.hl])
    if not r.zf:
        return
    r.hl = Chr00PlayerFlags
    _bit(FLAG_PRESENT, mem[r.hl])
    if r.zf:
        return
    if not objects.CommitOrAbort():
        return
    r.hl = v.RandomEventPtr
    r.hl = r.hl + 2 & 0xFFFF                        # skip the phrase code
    r.e = mem[r.hl]
    r.hl = r.hl + 1 & 0xFFFF
    r.d = mem[r.hl]
    r.hl = r.de
    await PrintSpeech()
    r.a = 1
    v.ReplyGiven = 1


def _cpir():
    """CPIR: compare A with (HL) up to BC bytes; stops after a match (Z) or at
    BC = 0. Carry is untouched; PV = BC <> 0."""
    while True:
        x = mem[r.hl]
        r.hl = r.hl + 1 & 0xFFFF
        r.bc = r.bc - 1 & 0xFFFF
        r.zf = r.a == x
        r.sf = (r.a - x) & 0x80 != 0
        r.pf = r.bc != 0
        if r.zf or r.bc == 0:
            return


async def LA8F6():
    """Handler (via $C9FE): the answer to Gollum's riddle. After the test pass
    ReplyGiven := 0; the answer is the stored order of the player; it is
    searched in the 24 bytes of its command record for the riddle's phrase
    (night, man pair); a wrong or no answer: "someone strangles you from
    behind" and the game ends. Quirk: after a first mismatch A is the second
    phrase byte, so the next CPIR looks for that."""
    if not objects.CommitOrAbort():
        return
    r.a = 0
    v.ReplyGiven = 0
    await parser.RunStoredOrder()
    if not r.zf:
        r.bc = 0x18
        r.de = v.RandomEventPtr
        r.a = mem[r.de]
        while True:                                 # LA8F6_0
            _cpir()
            if not r.zf:
                break
            r.de = r.de + 1 & 0xFFFF
            r.a = mem[r.de]
            r.de = r.de - 1 & 0xFFFF
            r.cp(mem[r.hl])
            if r.zf:
                return
    if not objects.CommitOrAbort():                 # LA8F6_1
        return
    r.a = 1
    v.MessagesVisible = 1
    r.hl = MsgSomeoneStranglesFrom
    await printer.PrintMessage()
    return await verbs.EndGame()


async def GollumTalks():
    """Script routine: when Gollum is with the player, after the test pass he
    says "What has it got in its pockets ?" (RandomUpTo(8) left carry clear, or
    he holds the golden ring), else "My birthday present - how did we lose it.
    My precious"; elsewhere returns before the test pass."""
    r.a = mem[Chr44GollumLocation]
    r.hl = PlayerLocation
    r.cp(mem[r.hl])
    if not r.zf:
        return
    if not objects.CommitOrAbort():
        return
    r.hl = MsgWhatHasGotPockets
    r.a = 8
    objects.RandomUpTo()
    if not r.cf:
        return await PrintSpeech()
    r.ix = Obj10ValuableGoldenRing
    r.a = CHR_GOLLUM
    r.cp(mem[r.ix + 1])
    if r.zf:
        return await PrintSpeech()
    r.hl = MsgMyBirthdayPresentHow
    return await PrintSpeech()


async def LA94E():
    """Handler (via $CA42-$CA54): the actor is with the player; after the test
    pass the command becomes $1B on object 0 (the player) and the refusal and
    L929C_0 run; the game ends."""
    r.a = v.ActorLocation
    r.hl = PlayerLocation
    r.cp(mem[r.hl])
    if not r.zf:
        return
    if not objects.CommitOrAbort():
        return
    r.a = 0x1B
    v.CommandId = r.a
    r.a = 0
    v.FirstObject = r.a
    r.a = 0xFF
    v.SecondObject = r.a
    await objects.RefuseCommand()
    await verbs.L929C_0()
    return await verbs.EndGame()


async def LA94E_0():
    """Dawn turns the trolls to stone: both trolls die, lose their bit 7, empty
    their holdings; the clearing's text becomes "clearing with two stone..."
    (Loc00None_0), its bit 6 clears, "Day dawns" is printed and picture 5's
    first two bytes become $05, $28."""
    if not objects.CommitOrAbort():
        return
    r.a = 0x47
    await engine.KillCharacter()
    r.a = 0x48
    await engine.KillCharacter()
    r.hl = Chr47TrollFlags
    _res(r.hl, 7)
    r.hl = Chr48TrollFlags
    _res(r.hl, 7)
    r.hl = MsgClearingWithTwoStone
    mem16[Loc00None_0] = r.hl
    r.hl = Loc05TrollsClearing
    _res(r.hl, 6)
    r.a = 0x47
    await objects.EmptyHolder()
    r.a = 0x48
    await objects.EmptyHolder()
    r.hl = MsgDayDawns
    r.a = 1
    v.MessagesVisible = 1
    await printer.PrintMessage()
    r.ix = PictureTable
    r.a = 5
    objects.FindIdRecord()
    r.l = mem[r.ix + 1]
    r.h = mem[r.ix + 2]
    mem[r.hl] = 0x05
    r.hl = r.hl + 1 & 0xFFFF
    mem[r.hl] = 0x28


async def TrollsTalk():
    """Script routine of both trolls: with the player at the trolls clearing,
    after the test pass the hideous troll says "Blimey, look at this!! Can
    yer cook'em?", the vicious one "Yer can try, but he wouldn't make above a
    mouthfull"; elsewhere returns before the test pass."""
    r.a = v.PlayerLocation
    r.cp(LOC_TROLLS_CLEARING)
    if not r.zf:
        return
    if not objects.CommitOrAbort():
        return
    r.a = v.Subject
    r.hl = MsgBlimeyLookAtThisCan
    r.cp(CHR_HIDEOUS_TROLL)
    if not r.zf:
        r.hl = MsgYerCanTryButHe
    return await PrintSpeech()


async def CheckVictory():
    """Victory check, once per turn. When the valuable treasure is held by the
    wooden chest: print the ending text and go to EndGame_Wait (the score, a
    key, the restart). Else returns NZ."""
    r.a = mem[Obj23TreasureHolder]
    r.cp(OBJ_WOODEN_CHEST)
    if not r.zf:
        return
    r.hl = MsgCheeringCrowdDwarves
    await printer.PrintMessage()
    return await verbs.EndGame_Wait()


async def LA9E5():
    """Handler (via $C9A1): the actor lunches off the player's pack... When the
    actor is with the player and the lunch is not at any location or is held
    by the actor $41, after the test pass the lunch is put in $41's hands and
    given to the player (command $1D, GiveObject)."""
    r.a = v.ActorLocation
    r.hl = PlayerLocation
    r.cp(mem[r.hl])
    if not r.zf:
        return
    r.ix = Obj26Lunch
    r.a = mem[r.ix + 0x10]
    r.cp(0)
    if not r.zf:
        r.a = 0x41
        r.cp(mem[r.ix + 1])
        if not r.zf:
            return
    if not objects.CommitOrAbort():                 # LA9E5_0
        return
    r.a = v.ActorLocation
    mem[r.ix + 0x10] = r.a
    mem[r.ix + 1] = 0x41
    r.bc = 0x0026
    mem16[FirstObject] = r.bc
    r.a = 0x1D
    v.CommandId = r.a
    v.Noun1Record = r.ix
    r.hl = Chr00Player
    v.Noun2Record = r.hl
    await objects.RefuseCommand()
    return await verbs.GiveObject()


async def LA9E5_1():
    """Jump onto the first object: its location must be reachable by an exit of
    the actor (else "cannot jump onto") with direction $0A; then the actor
    moves there with what it carries, and the player sees the location.
    Quirk: the asm has JP NZ,MsgCannotJumpOntoFrom (the data of the message,
    run as code) where JP NZ,PrintMessage was meant; only its start, up to the
    RET Z, is reproduced (_run_message_as_code)."""
    r.iy = v.Noun1Record
    r.a = mem[r.iy + 0x10]
    r.b = r.a
    objects.FindExitByDestination()
    r.cp(0xFF)
    r.hl = MsgCannotJumpOntoFrom
    if r.zf:
        return await printer.PrintMessage()
    r.a = mem[r.ix]
    r.cp(0x0A)
    if not r.zf:
        return _run_message_as_code()
    if not objects.CommitOrAbort():
        return
    r.a = v.FirstObject
    r.ix = v.ActorRecord
    mem[r.ix + 1] = r.a
    await objects.MoveCarried()
    r.a = v.Subject
    r.cp(0)
    if not r.zf:
        return
    r.a = r.b
    return await engine.DescribeLocation()


def _run_message_as_code():
    """The bytes of MsgCannotJumpOntoFrom executed as Z80 code, from $B301 to the
    RET Z at $B30C: LD B,$67; ADD A,E; AND C; ADD A,H; OR B; RLCA; LD L,L; LD
    L,(HL); DEC D; ADC A,B; SBC A,A; RET Z. The Z80 goes on into the next
    message's bytes when Z is clear, which is not ported."""
    r.b = 0x67
    r.a = r.a + r.e & 0xFF
    r.a &= r.c
    r.a = r.a + r.h & 0xFF
    r.a |= r.b
    r.cf = r.a >> 7 == 1
    r.a = (r.a << 1 | r.cf) & 0xFF
    r.l = mem[r.hl]
    r.d = r.d - 1 & 0xFF
    total = r.a + r.b + r.cf
    r.cf = total > 0xFF
    r.a = 0xFF if r.cf else 0
    r.zf, r.sf, r.pf = r.a == 0, r.a == 0xFF, False
    if not r.zf:
        raise NotImplementedError('JP NZ,MsgCannotJumpOntoFrom: the Z80 runs on into message data')


async def LA9E5_2():
    """Timer routine: the spider web is cut: bits 3 and 5 of its flags cleared,
    its +5 doubled, its words at Obj07WebOff0A set to $0623."""
    r.ix = Obj07SpiderWeb
    _res(r.ix + 7, 3)
    _res(r.ix + 7, 5)
    mem[r.ix + 5] = mem[r.ix + 5] << 1 & 0xFF
    r.de = 0x0623
    mem16[Obj07WebOff0A] = r.de


async def LA9E5_3():
    """Timer routine: unless the door Obj0BDoorFlags is open (bit 5), restart
    timer 9, clear the door's bit 7 and, at location $2A, print "the hole
    vanishes"."""
    r.hl = Obj0BDoorFlags
    _bit(5, mem[r.hl])
    if not r.zf:
        return
    r.a = v.Timer9Start
    mem[Timer9Counter] = r.a
    r.hl = Obj0BDoorFlags
    _res(r.hl, 7)
    r.a = mem[Chr00PlayerLocation]
    r.cp(0x2A)
    if not r.zf:
        return
    return await LA9E5_4()


async def LA9E5_4():
    """Print "the hole vanishes"."""
    r.hl = MsgHoleVanishes
    return await printer.PrintMessage()


async def LA9E5_5():
    """Timer routine: the door's bit 7 set; at location $2A "there is a loud
    crack and a hole ..."."""
    r.hl = Obj0BDoorFlags
    _set(r.hl, 7)
    r.a = mem[Chr00PlayerLocation]
    r.cp(0x2A)
    if not r.zf:
        return
    r.hl = MsgThereLoudCrackHole
    return await printer.PrintMessage()


async def LA9E5_6():
    """Handler: after the test pass timer 9 counts 6, the door's bit 0 is set
    and bit 7 cleared; "the hole vanishes"."""
    if not engine.AbortUnlessPerform():
        return
    r.a = 6
    mem[Timer9Counter] = r.a
    r.hl = Obj0BDoorFlags
    _set(r.hl, 0)
    _res(r.hl, 7)
    return await LA9E5_4()


async def LA9E5_7():
    """Timer routine: the magic door opens (Obj0DDoorFlags bit 5), announced at
    locations $1E and $1C, with "an elf sweeps past"; then LA9E5_10."""
    r.hl = Obj0DDoorFlags
    _set(r.hl, 5)
    r.hl = MsgMagicDoorOpens
    await LA9E5_8()
    r.hl = MsgElfSweepsPast
    await LA9E5_8()
    return await LA9E5_10()


async def LA9E5_8():
    """Print HL when the player is at location $1E or $1C."""
    r.a = mem[Chr00PlayerLocation]
    r.cp(0x1E)
    if r.zf:
        return await printer.PrintMessage()
    r.cp(0x1C)
    if r.zf:
        return await printer.PrintMessage()


async def LA9E5_9():
    """Timer routine: the magic door closes (bit 5 cleared) and is announced."""
    r.hl = Obj0DDoorFlags
    _res(r.hl, 5)
    r.hl = MsgMagicDoorCloses
    return await LA9E5_8()


async def LA9E5_10():
    """If the golden ring is held by someone, that one becomes the actor, and
    when his flag bit 7 is clear (he is invisible: wearing it) the ring comes
    off (LA377_1)."""
    r.ix = Obj10ValuableGoldenRing
    r.a = mem[r.ix + 1]
    r.cp(0xFF)
    if r.zf:
        return
    objects.FindObject()
    v.ActorRecord = r.ix
    _bit(7, mem[r.ix + 7])
    if r.zf:
        return await LA377_1()


async def LA9E5_11():
    """Handler: for the player (Subject 0): LispFlag := 1 and timer 7 starts."""
    r.a = v.Subject
    r.cp(0)
    if not r.zf:
        return
    r.a = 1
    v.LispFlag = 1
    r.a = v.Timer7Start
    mem[Timer7Counter] = r.a


async def LA9E5_12():
    """Timer routine: LispFlag := 0."""
    r.a = 0
    v.LispFlag = 0


async def LA9E5_13():
    """Timer routine: at location $1A "the spider web slowly..." and the game
    ends."""
    r.a = mem[Chr00PlayerLocation]
    r.cp(0x1A)
    if not r.zf:
        return
    r.hl = MsgSpiderWebSlowly
    await printer.PrintMessage()
    return await verbs.EndGame()


async def LA9E5_14():
    """Timer routine: "you see some pale bulbous eyes"; unless the player is at
    the location he arrived from (ArrivalLocation) or at the other forest
    location (2 <-> 3), "some drops from above" and the game ends."""
    r.hl = MsgSeeSomePaleBulbous
    return await SpiderEyesFromHL()


async def SpiderEyesFromHL():
    """LA9E5_14 from its CALL PrintMessage: print the message at HL, then the
    same location test. Run directly as timer 2's fire handler after
    ActorArrives wrote a location id into its low byte with a stale IY (F85):
    HL is then this routine's own address, so its code bytes are printed as a
    message (kept)."""
    await printer.PrintMessage()
    r.a = mem[Chr00PlayerLocation]
    r.c = r.a
    r.hl = ArrivalLocation
    r.cp(mem[r.hl])
    if r.zf:
        return
    r.b = mem[r.hl]
    r.a = 2
    r.cp(r.b)
    if r.zf:
        r.a = 3
    r.cp(r.c)
    if r.zf:
        return
    return await LA9E5_18()


async def LA9E5_16():
    """Timer routine: at location 2 or 3 print "pale bulbous eyes", then drops
    from above and the game ends."""
    r.a = mem[Chr00PlayerLocation]
    r.cp(2)
    if not r.zf:
        r.cp(3)
        if not r.zf:
            return
    r.hl = MsgSeeSomePaleBulbous
    await printer.PrintMessage()
    return await LA9E5_18()


async def LA9E5_18():
    """"Some drops from above" and the game ends."""
    r.hl = MsgSomeDropsFromAbove
    await printer.PrintMessage()
    return await verbs.EndGame()
