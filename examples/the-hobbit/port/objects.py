"""Ported from src/objects.asm: object and location records: lookups, holders, weights, reach, exits, lists, random numbers.
Values pass in the registers `r` (port/regs.py); conventions: port/CONTRACT.md.

Records: ObjectTable is a list of (id, record address) entries of ID_ENTRY_SIZE
bytes ending with END_MARK; a record has +0 the number of locations, +1 the
holder (AT_LOCATION when it lies at a location), +2 weight, +3 size, +4 state,
+7 flags, +8 name phrase, +$10 the locations. A location record has the
capacity at +1, its name phrase at +2 and its exits (direction, obstacle,
destination) from +10.

PUSH/POP pairs of the asm that save registers are Python locals; the registers
a routine promises to keep are put back before it returns."""
from labels import *  # noqa: F403  (first: port functions shadow routine labels)
import calls
import engine
import keys
import printer
import screen
import verbs
from regs import r
from variables import v  # noqa: F401
from zxpyxel import mem, mem16, zx


def _af():
    """PUSH AF: the accumulator and the flags, for _set_af (POP AF)."""
    return r.a, r.zf, r.cf, r.sf, r.pf


def _set_af(saved):
    r.a, r.zf, r.cf, r.sf, r.pf = saved


def _and_a(a):
    """The flags of AND A / OR n (Z and S from the result, carry clear); returns a."""
    r.set_zs(a)
    r.cf = False
    return a


async def NpcHeld():
    """NPC turn when the NPC's record (IX) has a holder: FirstObject becomes the
    holder and SecondObject none. A dead or disabled holder, or a character, and
    the NPC acts as usual; a shut holder and it does nothing this turn; an open
    one (a barrel, a boat) and it climbs out. Ends in the NPC loop."""
    v.SecondObject = NO_OBJECT
    r.a = mem[r.ix + 1 & 0xFFFF]
    v.FirstObject = r.a
    FindObject()                                   # IX = the holder's record
    flags = mem[r.ix + 7 & 0xFFFF]
    if flags >> FLAG_DEAD & 1:
        return await engine.RunNpcScripts_Start()
    if flags >> FLAG_CHARACTER & 1:
        return await engine.RunNpcScripts_Start()
    if not flags >> FLAG_ACTIVE & 1:
        return await engine.RunNpcScripts_Next()
    r.a = CMD_CLIMB_OUT_OF
    v.CommandId = r.a
    await engine.RunActorCommand()
    return await engine.RunNpcScripts_Next()


def CheckNounsDistinct():
    """Reject a command that uses the same object twice. NZ and A = 1 when
    there is no first object; otherwise, unless Noun1Kind is set, Z when the
    subject or the second object is the first object; then, unless Noun2Kind is
    set, Z when the second object is the subject. Leaves HL at FirstObject or
    Subject and A/flags of the last compare."""
    r.a = v.FirstObject + 1 & 0xFF
    r.set_zs(r.a)
    if r.a == 0:
        r.a = 1
        r.set_zs(1)                                # INC A: NZ
        return
    r.a = _and_a(v.Noun1Kind)
    if r.a == 0:
        r.hl = FirstObject
        r.a = v.Subject
        r.cp(v.FirstObject)
        if r.zf:
            return
        r.a = v.SecondObject
        r.cp(v.FirstObject)
        if r.zf:
            return
    r.a = _and_a(v.Noun2Kind)
    if r.a:
        return
    r.a = v.SecondObject
    r.hl = Subject
    r.cp(v.Subject)


async def CallHandler():
    """Call the handler at HL unless it is 0. Keeps BC, DE, HL, IX and IY, so
    the handler cannot hand values back in registers; AF is the handler's (A = 0
    and Z when there is none)."""
    saved = r.ix, r.iy, r.de, r.bc, r.hl
    r.a = _and_a(r.l | r.h)
    if r.a:
        await JumpHL()
    r.ix, r.iy, r.de, r.bc, r.hl = saved


async def JumpHL():
    """JP (HL), entered by CALL from CallHandler: run the routine at HL."""
    await calls.call_at(r.hl)


def FindVerbEntry():
    """Find a verb entry in the verb table that follows the record at IX
    (RECORD_HEADER_SIZE plus one byte per location). A = verb id. Out: IX = the
    entry, or the $FF that ends the table; A = the id found or END_MARK; Z when
    not found. DE kept."""
    de = r.de
    d = r.a
    r.a = mem[r.ix] + RECORD_HEADER_SIZE & 0xFF
    r.ix = r.ix + r.a & 0xFFFF
    r.a = d
    FindIdRecord()
    r.de = de


def NextObject():
    """Step IX to the next entry of the object table (start a walk with IX =
    ObjectTable - ID_ENTRY_SIZE). Out: IX = the entry, IY = its record, A = its
    id, Z at the END_MARK that ends the table. BC, DE, HL kept (the alternate
    set is used)."""
    r.exx()
    r.de = ID_ENTRY_SIZE
    r.ix = r.ix + ID_ENTRY_SIZE & 0xFFFF
    r.d = mem[r.ix + 2 & 0xFFFF]
    r.e = mem[r.ix + 1 & 0xFFFF]
    r.iy = r.de
    r.a = mem[r.ix]
    r.cp(END_MARK)
    r.exx()


def NextObjectKeepA():
    """NextObject, but A and BC come back as they went in. Out: IX, IY, Z at
    the end of the table."""
    bc = r.bc
    r.b = r.a
    NextObject()
    r.a = r.b
    r.bc = bc


def FindLocation():
    """Look up a location record. A = location id. Out: IX = its record; A the
    id; with an id of LOCATION_COUNT or more, A = 0 and IX unchanged. DE, HL kept."""
    r.cp(LOCATION_COUNT)
    if not r.cf:
        r.a = 0                                    # XOR A
        r.set_zs(0)
        r.cf = False
        return
    r.ix = mem16[LocationTable + 2 * r.a]
    r.cf = False                                   # ADD HL,DE: no carry


def FindObject():
    """Find the record of an object or character. A = id. Out: IX = its record
    (garbage when the id is not in the table); A = the id, or END_MARK when it
    is not in the table (Z). HL kept."""
    r.ix = ObjectTable
    FindIdRecord()
    r.ix = mem[r.ix + 1 & 0xFFFF] | mem[r.ix + 2 & 0xFFFF] << 8


async def MoveCarried():
    """A carrier (A = id) has been put at location B: move what it holds there
    (MoveContents). If the walk met the player (MoveFlag cleared: the player is
    inside or carried), the player arrives too, as the subject, and
    UpdatePlayerSight runs; MoveFlag ends 0 then. Leaves HL = MoveFlag, A = 0
    and Z in that case; NZ at once when the player was not among the contents."""
    r.hl = MoveFlag
    v.MoveFlag = 1
    MoveContents()
    r.a = _and_a(v.MoveFlag)
    if r.a:
        return                                     # the player was not among them
    if mem[Chr00PlayerLocation]:
        subject, actor = v.Subject, v.ActorRecord  # the actor is restored afterwards
        v.ActorRecord = Chr00Player
        v.Subject = 0
        v.TakeId = r.b                             # the new location
        await verbs.ActorArrives()
        engine.UpdatePlayerSight()
        v.ActorRecord = actor
        v.Subject = subject
        r.hl, r.a = actor, subject
    r.hl = MoveFlag
    r.a = 0
    r.set_zs(0)                                    # XOR A
    r.cf = False
    v.MoveFlag = 0


def MoveContents():
    """Set the first location (+$10) of every object held by A to B, and of
    what those hold (recursively). Meeting table id 0 (the player) clears
    MoveFlag. IX, IY, A kept."""
    ix, iy = r.ix, r.iy
    holder = r.a
    r.ix = ObjectTable - ID_ENTRY_SIZE
    while True:
        NextObjectKeepA()
        if r.zf:
            break
        r.cp(mem[r.iy + 1 & 0xFFFF])
        if not r.zf:
            continue
        mem[r.iy + 0x10 & 0xFFFF] = r.b
        r.a = mem[r.ix]
        if _and_a(r.a) == 0:
            v.MoveFlag = 0
        MoveContents()                             # its contents too (A = its id)
        r.a = holder
    r.ix, r.iy = ix, iy


def LocationSpareCapacity():
    """Capacity left at location A: its capacity (+1) minus the weight (+2) of
    every record that has exactly one location, this one; 0 when the weights add
    up to more. Out: A. BC, IX, IY kept."""
    ix, iy, bc = r.ix, r.iy, r.bc
    r.b = r.a
    FindLocation()
    r.a = mem[r.ix + 1 & 0xFFFF]
    r.c = r.a
    r.ix = ObjectTable - ID_ENTRY_SIZE
    while True:
        NextObject()
        if r.zf:
            break
        r.a = mem[r.iy]
        r.cp(1)
        if not r.zf:
            continue                               # only records with one location
        r.a = r.b
        r.cp(mem[r.iy + 0x10 & 0xFFFF])
        if not r.zf:
            continue                               # and that one is the location
        r.a = r.c
        left = r.a - mem[r.iy + 2 & 0xFFFF]
        if left < 0:                               # over capacity
            r.c = 0
            break
        r.a = r.c = left
    r.a = r.c
    r.ix, r.iy, r.bc = ix, iy, bc


def CheckObject1Held():
    """Is the first object (FirstObject) held by the subject? See
    CheckObject1Held_0."""
    r.a = v.FirstObject
    return CheckHeldBySubject()


def CheckHeldBySubject():
    """Is the object in A held by the subject (HL := Subject)? See
    CheckObject1Held_0."""
    r.hl = Subject
    return CheckObject1Held_0()


def CheckObject1Held_0():
    """Is the object A in the holder chain of the id at (HL)? NO_OBJECT counts
    as held. Out: carry set when held, clear when not (it ends at a location).
    IX kept."""
    r.cp(NO_OBJECT)
    r.cf = True                                    # SCF
    if r.zf:
        return
    ix = r.ix
    WalkHolderChain()
    r.ix = ix


def WalkHolderChain():
    """Follow the holders of object A until one is the id at (HL) (carry set)
    or the chain ends at a location (carry clear). Trashes IX: the asm's POP IX
    throws the saved AF into it (its high byte is the id looked at)."""
    while True:
        FindObject()
        saved = _af()
        r.a = mem[r.ix + 1 & 0xFFFF]
        r.cp(AT_LOCATION)
        if r.zf:
            _set_af(saved)
            _and_a(r.a)
            return
        r.ix = saved[0] << 8                       # POP IX: AF, unused (low byte = flags)
        r.cp(mem[r.hl])
        if r.zf:
            r.cf = True                            # SCF
            return


def RandomUpTo():
    """Random number 0 to A (small values likelier): the absolute value of
    RandomSigned. DE is noise for RandomSigned. Out: A."""
    RandomSigned()
    r.zf, r.sf = not r.a & 0x80, bool(r.a & 0x80)  # BIT 7,A
    if r.zf:
        return
    r.cf = r.a != 0                                # NEG
    r.a = -r.a & 0xFF
    r.set_zs(r.a)


def RandomSigned():
    """The game's random number from -A to A (two's complement, not evenly
    spread). Steps the page pointer RandomRomPtr, mixes RandomSeed with the byte
    at the pointer (ADC, the carry being bit 7 of A on entry) and the byte at
    the pointer + DE + 1 (XOR), retries while the result equals the old seed,
    stores it as the seed and halves it until it is at most 2*A. BC, IX, HL
    kept; flags of the final SUB."""
    ix, bc = r.ix, r.bc
    r.c = r.a
    carry = r.a >> 7
    r.b = 0xFF if carry else r.a << 1 & 0xFF
    while True:                                    # RandomSigned_Retry
        mem[RandomRomPtr + 1] = mem[RandomRomPtr + 1] + 1 & 0xFF
        if mem[RandomRomPtr + 1] == 0:
            mem[RandomRomPtr] = mem[RandomRomPtr] + 1 & 0xFF
        r.ix = mem16[RandomRomPtr]
        a = v.RandomSeed + mem[r.ix] + carry & 0xFF
        r.ix = r.ix + r.de & 0xFFFF
        a ^= mem[r.ix + 1 & 0xFFFF]
        r.a = zx.take(RandomSigned_Mixed, a)       # the Z80's value in a replay
        r.cp(v.RandomSeed)
        carry = 0                                  # Z: CP left carry clear
        if not r.zf:
            break
    v.RandomSeed = r.a
    while r.a > r.b:                               # halve until not above 2*A
        r.a >>= 1
    r.cp(r.c)                                      # SUB C: the flags of A - C
    r.a = r.a - r.c & 0xFF
    r.bc, r.ix = bc, ix


def SumHeldWeight():
    """Total weight (+2) of the records held directly by holder A, $FF on
    (signed) overflow. Out: A. BC, IX, IY kept."""
    bc = r.bc
    r.b = 1
    SumHeld()
    r.bc = bc


def SumHeldBulk():
    """Total size (+3) of everything inside holder A, recursively, $FF on
    (signed) overflow. Out: A. BC, IX, IY kept."""
    bc = r.bc
    r.b = 0
    SumHeld()
    r.bc = bc


def SumHeld():
    """SumHeldRecords from 0 for holder A, B = 0 (sizes, recursive) or not 0
    (weights). Out: A = the total. IX, IY kept; BC is the caller's to restore
    (SumHeldWeight, SumHeldBulk)."""
    ix, iy = r.ix, r.iy
    r.c = 0
    SumHeldRecords()
    r.a = r.c
    r.ix, r.iy = ix, iy


def SumHeldRecords():
    """Add a field of every record held by A to C: B = 0 the size (+3), then
    the same for what each holds; B not 0 the weight (+2) only. The add is a
    signed one: a sum past 127 sets C to $FF and ends the walk (the caller of a
    recursion goes on). IX kept; IY is left at the table's end."""
    ix = r.ix
    r.ix = ObjectTable
    while True:
        NextObjectKeepA()
        if r.zf:
            break
        r.cp(mem[r.iy + 1 & 0xFFFF])
        if not r.zf:
            continue
        holder = r.a
        add = mem[r.iy + (2 if r.b else 3) & 0xFFFF]
        total = r.c + add & 0xFF
        if (r.c ^ total) & (add ^ total) & 0x80:   # JP PE: signed overflow
            r.c = 0xFF
            r.a = holder
            break
        r.c = total
        if not r.b:
            r.a = mem[r.ix]
            SumHeldRecords()                       # the held record may hold more
        r.a = holder
    r.ix = ix


def GetActorLocationRec():
    """IX := the location record of the current actor (its first location,
    +$10, through FindLocation: IX is the actor's record when that is not a
    location). AF kept."""
    saved = _af()
    r.ix = v.ActorRecord
    r.a = mem[r.ix + 0x10 & 0xFFFF]
    FindLocation()
    _set_af(saved)


def CommitOrAbort():
    """Continue only if the command is really being performed. Returns True
    when ActionPerform is 1 (A = 1, Z). Otherwise the command is only being
    tried: ActionAllowed := ActionPerform + 1, and the asm's POP BC drops the
    caller's return address, so this returns False and the caller returns at
    once (BC is then the caller's return address in the asm; nobody uses it)."""
    r.a = v.ActionPerform
    r.cp(1)
    if r.zf:
        return True
    r.a = r.a + 1 & 0xFF
    r.set_zs(r.a)
    v.ActionAllowed = r.a
    return False


async def EmptyFirstObject():
    """Empty the first object (FirstObject): see EmptyHolder."""
    r.a = v.FirstObject
    await EmptyHolder()


async def EmptyHolder():
    """Empty holder A (destroyed or killed): what it holds passes to its own
    holder (AT_LOCATION when it lies at a location); what is consumable
    evaporates (location 0, AT_LOCATION, not present, its name and
    "Evaporates."). HL, IX, IY kept."""
    iy, ix, hl = r.iy, r.ix, r.hl
    FindObject()                                   # IX = the holder's record
    r.b = mem[r.ix + 1 & 0xFFFF]                   # B = what holds the holder
    r.ix = ObjectTable - ID_ENTRY_SIZE
    while True:
        NextObjectKeepA()
        if r.zf:
            break
        r.cp(mem[r.iy + 1 & 0xFFFF])
        if not r.zf:
            continue
        if mem[r.iy + 7 & 0xFFFF] >> FLAG_CONSUMABLE & 1:
            saved = _af()
            mem[r.iy + 0x10 & 0xFFFF] = 0
            mem[r.iy + 1 & 0xFFFF] = AT_LOCATION
            mem[r.iy + 7 & 0xFFFF] &= ~(1 << FLAG_PRESENT) & 0xFF
            await PrintObjectName()
            r.hl = MsgEvaporates2
            await printer.PrintMessage()
            _set_af(saved)
        else:
            mem[r.iy + 1 & 0xFFFF] = r.b           # passes to the holder's holder
    r.hl, r.ix, r.iy = hl, ix, iy


def CountHeldPresent():
    """Count the records held by holder A whose present flag is set (not what
    they hold). Out: A. BC, IX, IY kept."""
    ix, iy, bc = r.ix, r.iy, r.bc
    r.b = 0
    r.ix = ObjectTableBase
    while True:
        NextObjectKeepA()
        if r.zf:
            break
        r.cp(mem[r.iy + 1 & 0xFFFF])
        if not r.zf:
            continue
        if mem[r.iy + 7 & 0xFFFF] >> FLAG_PRESENT & 1:
            r.b += 1
    r.a = r.b
    r.ix, r.iy, r.bc = ix, iy, bc


def FindIdRecord():
    """Find the record whose first byte is A in a table of 3-byte records from
    IX, ending with END_MARK. Out: IX = the record, or the end mark; Z when not
    found. BC, DE, HL kept (the alternate set is used); A = the byte there."""
    r.exx()
    hl = r.ix
    r.b = r.a
    r.de = ID_ENTRY_SIZE
    while True:
        a = mem[hl]
        if a == r.b or a == END_MARK:
            break
        hl = hl + ID_ENTRY_SIZE & 0xFFFF
    r.a = a
    r.hl = hl
    r.ix = hl
    r.cp(END_MARK)
    r.exx()


def FindNextNamedObject():
    """Find the next object a typed noun phrase (HL, three word tokens) can
    mean, walking from the table entry in IX (ObjectTable - ID_ENTRY_SIZE to
    start). A record qualifies when its kind fits AllMode (0 things, 1 living
    characters, ALL_MODE_ANY anything), its name phrase matches (MatchCommandRecord)
    and, unless AllActive, the actor can reach it. Out: A = its id, $FF at the
    end; IX = its entry. BC, DE, IY kept."""
    bc, de, iy = r.bc, r.de, r.iy
    r.iy = v.ActorRecord
    r.d = mem[r.iy + 0x10 & 0xFFFF]                # (not used again)
    r.a = v.AllMode
    r.e = r.a
    while True:
        NextObject()
        if r.zf:
            break
        r.a = ALL_MODE_ANY
        r.cp(r.e)
        if not r.zf:                               # not "any": test the kind
            r.a = _and_a(mem[r.iy + 7 & 0xFFFF] & 0x48)    # character and not dead?
            r.cp(0x40)
            r.a = 0 if not r.zf else 1             # 1 = living character
            r.cp(r.e)
            if not r.zf:
                continue                           # the wrong kind
        r.bc = REC_PHRASE_A
        object_iy = r.iy
        r.iy = r.iy + REC_PHRASE_A & 0xFFFF        # its name phrase
        keys.MatchCommandRecord()
        r.iy = object_iy
        if not r.zf:
            continue                               # the phrase does not match
        r.a = _and_a(v.AllActive)
        if r.a:
            break                                  # no reach test then
        r.a = mem[r.ix]
        ActorCanReach()
        if r.zf:
            continue                               # out of reach
        break
    r.a = mem[r.ix]
    r.bc, r.de, r.iy = bc, de, iy


def CanReachSwapped():
    """CanReach with the two records exchanged: IX = the object, IY = the
    observer; both put back. A = the object id. Out: NZ within reach."""
    SwapIXIY()
    CanReach()                                     # IX = observer, IY = object
    return SwapIXIY()


def SwapIXIY():
    """EX IX,IY (falls through from CanReachSwapped)."""
    r.ix, r.iy = r.iy, r.ix


def ActorCanReach():
    """CanReach with the observer the current actor (ActorRecord). A = object
    id, IY = its record. Out: NZ within reach. IX kept."""
    ix = r.ix
    r.ix = v.ActorRecord
    CanReach()
    r.ix = ix


def CanReach():
    """Is the object (A = id, IY = record) within reach of the observer (IX)?
    It must be present (flag bit 7: Z and nothing else if not). Reachable when
    the observer's closed holder is the object itself, or both have the same
    closed holder; with none ($FF: both in the open) the observer's first
    location must be one of the object's locations (the asm's DJNZ runs 256
    times for an object with 0 locations). Out: A = 0 and Z, or A non-zero and
    NZ. BC, IX, IY kept."""
    if not mem[r.iy + 7 & 0xFFFF] >> FLAG_PRESENT & 1:
        r.zf = True
        return
    iy, ix, bc = r.iy, r.ix, r.bc
    r.b = r.a                                      # B = object id
    r.c = mem[r.ix + 0x10 & 0xFFFF]                # C = location of the observer
    FindClosedHolder()                             # closed holder of the observer
    r.cp(r.b)                                      # the object itself? then reachable
    r.b = r.a
    r.ix = iy
    reach = r.zf
    if not reach:
        FindClosedHolder()                         # closed holder of the object
        r.cp(r.b)                                  # must be the observer's
        if r.zf:
            r.a = r.a + 1 & 0xFF                   # $FF + 1 = 0: both in the open
            r.set_zs(r.a)
            reach = r.a != 0
            if not reach:
                r.b = mem[r.iy]                    # B = number of locations of the object
                r.a = r.c
                while True:                        # CanReach_Location
                    r.cp(mem[r.iy + 0x10 & 0xFFFF])
                    if r.zf:
                        reach = True
                        break
                    r.iy = r.iy + 1 & 0xFFFF
                    r.b = r.b - 1 & 0xFF
                    if r.b == 0:
                        break
    if reach:
        r.a = _and_a(r.a | 1)
    else:
        r.a = _and_a(0)
    r.iy, r.ix, r.bc = iy, ix, bc


def FindClosedHolder():
    """Climb the holders of the record in IX while a holder has flag bit 5 or
    3 set (open or alive, dead or disabled). Out: A = the first holder with
    neither (a shut container), $FF when the chain reaches a location. IX
    kept; AF' is used."""
    ix = r.ix
    while True:
        r.a = mem[r.ix + 1 & 0xFFFF]
        r.cp(AT_LOCATION)
        if r.zf:
            break
        r.ex_af()                                  # keep the holder id
        r.a = mem[r.ix + 1 & 0xFFFF]
        FindObject()
        r.a = _and_a(mem[r.ix + 7 & 0xFFFF] & 0x28)
        if r.a:
            continue
        r.ex_af()
        break
    r.ix = ix


def SeekActorExits():
    """IX := the location record of the current actor + EXITS_BIAS, the
    position before its first exit for the walkers that step before reading.
    DE kept."""
    de = r.de
    GetActorLocationRec()
    r.de = EXITS_BIAS
    r.ix = r.ix + EXITS_BIAS & 0xFFFF
    r.de = de


def FindExitByName():
    """Find the next exit of the actor's location whose destination's name
    phrase (location record +2) matches the typed noun phrase (HL). IX = the
    exit before the first to examine (SeekActorExits). Out: A = the destination
    id, $FF when no more exits match; IX = the exit. IY, DE kept."""
    iy, de = r.iy, r.de
    r.de = 2                                       # offset of the location's name phrase
    while True:
        NextObject()                               # next exit (as 3-byte entries)
        if r.zf:
            break
        r.a = mem[r.ix + EXIT_DEST & 0xFFFF]
        exit_ix = r.ix
        FindLocation()                             # IX = the destination's record
        r.iy = r.ix + r.de & 0xFFFF                # its name phrase
        r.ix = exit_ix
        keys.MatchCommandRecord()
        if not r.zf:
            continue
        r.a = mem[r.ix + EXIT_DEST & 0xFFFF]
        break
    r.de, r.iy = de, iy


async def PrintObjectName():
    """Print the name phrase (+8) of the record in IY. DE, IY kept."""
    iy, de = r.iy, r.de
    r.de = 8
    r.iy = r.iy + 8 & 0xFFFF
    await PrintNamePhrase()
    r.de, r.iy = de, iy


async def PrintNamePhrase():
    """Print the name phrase at IY (noun at +0, adjectives at +2 and +4). With
    PhraseMode 0: the noun's article and the two adjectives, then the noun
    (without an article); any other PhraseMode: the noun with its article only.
    A word code of 0 prints nothing. AF and DE kept."""
    saved, de = _af(), r.de
    if v.PhraseMode == 0:
        r.de = mem16[r.iy]
        await printer.PrintArticle()
        r.de = mem16[r.iy + 2 & 0xFFFF]
        await printer.PrintWord()                  # first adjective
        r.de = mem16[r.iy + 4 & 0xFFFF]
        await printer.PrintWord()                  # second adjective
    r.de = mem16[r.iy]
    r.a = _and_a(r.d | r.e)
    if r.a:
        await printer.PrintNounWord()              # the noun
    _set_af(saved)
    r.de = de


def FindExitByDirection():
    """Find the exit of the actor's location in direction A whose destination
    is not 0. Out: A = the direction, $FF when none; IX = the exit record
    (direction, obstacle, destination). BC, IY kept."""
    bc, iy = r.bc, r.iy
    r.b = r.a
    SeekActorExits()
    while True:
        NextObject()
        if r.zf:
            break
        r.a = _and_a(mem[r.ix + EXIT_DEST & 0xFFFF])
        if r.a == 0:
            continue                               # destination 0: not an exit
        r.a = mem[r.ix]
        r.cp(r.b)
        if r.zf:
            break
    r.bc, r.iy = bc, iy


def FindExitByObstacle():
    """Find the exit of the actor's location that has the first object as its
    obstacle. Out: A = the obstacle id, $FF when none; IX = the exit."""
    r.a = v.FirstObject
    return FindExitByObstacle_0()


def FindExitByObstacle_0():
    """FindExitByObstacle for the object id in A."""
    return FindExitByField(r.a, 1)                 # field +1: the obstacle


def FindExitByDestination():
    """Find the exit of the actor's location that leads to place A. Out: A = the
    id, $FF when none; IX = the exit. BC, IY kept."""
    return FindExitByField(r.a, EXIT_DEST)         # compare byte +2


def FindExitByField(value, field):
    """Walk the exits of the actor's location for one whose byte at `field`
    equals `value` (the asm takes the value from the stack and the field in A).
    The field is written into the displacement of the LD A,(IX+d) at
    SmcExitField and stays as last set. Out: A = the byte found, $FF when none;
    IX = the exit. BC, IY kept."""
    mem[SmcExitField + 2] = field
    bc, iy = r.bc, r.iy
    r.b = value
    SeekActorExits()
    while True:
        NextObject()
        if r.zf:
            break
        r.a = mem[r.ix + mem[SmcExitField + 2] & 0xFFFF]   # the self-modified displacement
        r.cp(r.b)
        if r.zf:
            break
    r.bc, r.iy = bc, iy


async def L9F4A():
    """Exchange the first and second noun records and objects, run the handler
    at HL (CallHandler), and exchange them back. DE, IY, BC come back as they
    were."""
    r.de = v.Noun1Record
    r.iy = v.Noun2Record
    v.Noun1Record = r.iy
    v.Noun2Record = r.de
    r.bc = mem16[FirstObject]                      # C = first object, B = second
    r.a = r.b
    v.FirstObject = r.a
    r.a = r.c
    v.SecondObject = r.a
    await CallHandler()
    mem16[FirstObject] = r.bc
    v.Noun1Record = r.de
    v.Noun2Record = r.iy


async def RefuseCommand():
    """End of a command that cannot be done. Really performed (ActionPerform 1):
    print "<subject> cannot <the command>."; only tried: ActionAllowed := 0."""
    r.a = v.ActionPerform - 1 & 0xFF
    r.set_zs(r.a)
    if r.zf:
        return await keys.PrintCommandSentence()
    r.a = 0
    r.set_zs(0)
    r.cf = False
    v.ActionAllowed = 0


def GetSingleLocation():
    """The one location of object A ($FF for none). Out: A = its location (+$10),
    or $FF when A was $FF or the record has not exactly one location (NZ);
    IX = the record (when A was not $FF)."""
    r.cp(NO_OBJECT)
    if r.zf:
        return
    FindObject()
    r.a = 1
    r.cp(mem[r.ix])
    r.a = 0xFF
    if not r.zf:
        return
    r.a = mem[r.ix + 0x10 & 0xFFFF]


async def ListObjectsHere():
    """Print "<subject> see :" and the objects lying where the actor is (the
    first location of ActorRecord), or "Nothing". IY, AF, BC kept; HL destroyed."""
    iy, saved, bc = r.iy, _af(), r.bc
    r.hl = MsgSee2
    await printer.PrintMessage()
    r.a = AT_LOCATION                              # holder: lying at the location
    r.iy = v.ActorRecord
    r.b = mem[r.iy + 0x10 & 0xFFFF]
    await ListObjects()
    r.bc = bc
    _set_af(saved)
    r.iy = iy


async def ListObjects():
    """List what holder A (AT_LOCATION: lying at the location) holds at
    location B and the actor can reach, indented by LIST_INDENT; "Nothing" when
    none was listed. IY, DE, BC kept; HL destroyed."""
    iy, de, bc = r.iy, r.de, r.bc
    r.c = 0                                        # C counts what is listed
    r.d = LIST_INDENT
    await ListHolderContents()
    r.a = 0
    r.cp(r.c)
    r.hl = MsgNothing
    if r.zf:
        await printer.PrintMessage()               # nothing listed
    r.bc, r.de, r.iy = bc, de, iy


async def ListHolderContents():
    """List the objects held by holder A (AT_LOCATION: lying at the location)
    that are at location B, one per line, with their contents, indented by D
    (ListIndent, restored at the end). An object is listed when it is at B
    (a record with one location, or its first or second location, for a holder),
    is not the subject at the top level (D = LIST_INDENT) and the actor can reach
    it. C counts the objects listed; the actor itself gets only a new line; an
    object with something to show (PrintContentsHeader) is followed by its
    contents, two spaces further. Out: A = the holder; HL, IX kept."""
    hl = r.hl
    holder = r.a
    old_indent = v.ListIndent
    v.ListIndent = r.d                             # the new indent
    ix = r.ix
    r.ix = ObjectTable - ID_ENTRY_SIZE
    r.a = holder
    while True:
        NextObjectKeepA()
        if r.zf:
            break
        r.cp(mem[r.iy + 1 & 0xFFFF])               # held by the holder?
        if not r.zf:
            continue
        r.a = r.a + 1 & 0xFF                       # INC A (restored below)
        r.e = mem[r.iy]                            # E = its number of locations
        listed = True
        if r.a == 0:                               # lying at the location: one location
            listed = r.e == 1
        if listed:
            listed = False
            if mem[r.iy + 0x10 & 0xFFFF] == r.b:   # first location is B
                listed = True
            else:
                r.e = r.e - 1 & 0xFF
                listed = r.e != 0 and mem[r.iy + 0x11 & 0xFFFF] == r.b
        if listed:
            if v.Subject == mem[r.ix] and r.d == LIST_INDENT:
                listed = False                     # the actor is not listed at the top level
        if listed:
            r.a = mem[r.ix]
            ActorCanReach()                        # can the actor reach it?
            listed = not r.zf
        if listed:
            r.c = r.c + 1 & 0xFF                   # one more listed
            v.CapitalNext = 0
            v.PhraseMode = 0                       # adjectives too
            await PrintObjectName()
            if v.Subject == mem[r.ix]:
                await screen.PrintNewLine()        # the actor: just end the line
            else:
                r.a = CHAR_FULLSTOP
                await screen.PrintChar()
                r.a = mem[r.ix]
                await PrintContentsHeader()        # header of its contents (or a new line)
                if not r.cf:                       # something to list
                    r.a = mem[r.ix]
                    de = r.de
                    r.d = r.d + 2 & 0xFF           # indent two more
                    await ListHolderContents()
                    r.de = de
        r.a = holder
    r.ix = ix
    v.ListIndent = old_indent                      # the old indent back
    r.a = holder
    r.hl = hl


async def PrintContentsHeader():
    """Print the line that introduces what object A holds. When it can show its
    contents (flag bit 5 or 3: open, alive or dead) and holds a present record
    (CountHeldPresent): "<name> is carrying" for a character (the id goes to the
    message), or the holder's relation word, its noun and "there is/are" (the
    noun and the word go to the message); carry clear then, to list the contents.
    Otherwise a new line, carry set. BC, DE, IX kept."""
    ix, bc, de = r.ix, r.bc, r.de
    r.c = r.a                                      # C = holder id
    FindObject()                                   # IX = its record
    flags = mem[r.ix + 7 & 0xFFFF]
    r.a = _and_a(flags & 0x28)
    shown = r.a != 0
    if shown:
        r.a = r.c
        CountHeldPresent()
        r.cp(0)
        shown = not r.zf
    if shown:
        if flags >> FLAG_CHARACTER & 1:
            r.a = r.c
            printer.msg_args.append(r.a)           # PUSH AF: A = the holder id
            r.hl = MsgCarrying2
        else:
            r.hl = WORD_IS                         # "is" for one thing
            r.a = r.a - 1 & 0xFF
            if r.a != 0:
                r.hl = WORD_ARE                    # "are" for more
            printer.msg_args.append(r.hl)
            r.l = mem[r.ix + 8 & 0xFFFF]           # the holder's noun
            r.a = mem[r.ix + 9 & 0xFFFF] & 0x0F
            r.h = r.a
            printer.msg_args.append(r.hl)
            await PrintHolderRelation()            # "In the" / "On the"...
            r.hl = MsgThere
        await printer.PrintMessage()               # "<noun> there is/are" or "<name> is carrying"
        _and_a(r.a)                                # AND A: carry clear
    else:
        await screen.PrintNewLine()
        r.cf = True
    r.de, r.bc, r.ix = de, bc, ix


async def PrintHolderRelation():
    """Print the relation word of the holder in IX: the 4-byte message at
    MsgInThe + 4 * (state & 15), state being +4 ("In the", "On the", "Behind
    the", "Under the", "Tied to the")."""
    r.hl = MsgInThe
    a = mem[r.ix + 4 & 0xFFFF]
    r.a = (a << 2 | a >> 6) & 0x3C                 # RLCA, RLCA, AND $3C
    r.e = r.a
    r.d = 0
    r.hl = r.hl + r.de & 0xFFFF
    return await printer.PrintMessage()


def SeekExitsOfLocation():
    """IX := the record of location A + EXITS_BIAS (before its first exit),
    BC := EXIT_SIZE, for NextListedExit and ListExitObstacles."""
    FindLocation()
    r.bc = EXITS_BIAS
    r.ix = r.ix + r.bc & 0xFFFF
    r.bc = EXIT_SIZE


def GetIdWord():
    """The dictionary word for id A (bit 7 ignored) from NameWordTable
    (directions, then object states). Out: DE = the word, 0 for none."""
    r.hl = NameWordTable
    return GetTableWord()


def GetTableWord():
    """The word for id A (bit 7 ignored) from the table of words at HL. Out:
    DE = the word; HL at its high byte."""
    r.e = r.a & 0x7F
    r.d = 0
    r.hl = r.hl + r.de + r.de & 0xFFFF
    r.e = mem[r.hl]
    r.hl = r.hl + 1 & 0xFFFF
    r.d = mem[r.hl]


async def ListExitObstacles():
    """Print "To the <direction> there is <thing>" (above/below for up and
    down) for every exit of location A whose obstacle (a door, a river, a web)
    is an object present in the game. BC, DE, IX, IY kept."""
    bc, de, iy, ix = r.bc, r.de, r.iy, r.ix
    SeekExitsOfLocation()                          # IX = location record + 7, BC = 3
    r.ix = r.ix + r.bc & 0xFFFF                    # the first exit
    r.iy = r.ix                                    # IY walks the exits
    while True:
        r.a = 0
        r.cp(mem[r.iy + 1 & 0xFFFF])               # obstacle 0: nothing to say
        if not r.zf:
            r.a = mem[r.iy + 1 & 0xFFFF]
            FindObject()                           # IX = the obstacle record
            if mem[r.ix + 7 & 0xFFFF] >> FLAG_PRESENT & 1:    # not present: skip
                r.de = 8
                r.ix = r.ix + 8 & 0xFFFF           # its first name phrase: the <thing>
                printer.msg_args.append(r.ix)
                r.a = mem[r.iy]
                GetIdWord()                        # DE = direction word
                r.cp(DIR_UP)                       # the eight compass directions are below 9
                if r.cf:
                    r.hl = MsgToThe                # "To the"
                    await printer.PrintMessage()
                else:
                    r.de = WORD_ABOVE if r.zf else WORD_BELOW
                await printer.PrintWord()          # the direction word, or above / below
                r.hl = MsgThere2                   # "There is <thing>"
                await printer.PrintMessage()
        r.iy = r.iy + r.bc & 0xFFFF                # next exit
        r.a = END_MARK
        r.cp(mem[r.iy])
        if r.zf:
            break
    r.ix, r.iy, r.de, r.bc = ix, iy, de, bc


def NextListedExit():
    """Step IX by BC to the next exit that is shown: no obstacle and a
    direction other than 0 (an erased exit). Out: Z at the end mark, NZ with
    an exit."""
    while True:
        r.ix = r.ix + r.bc & 0xFFFF
        r.a = END_MARK
        r.cp(mem[r.ix])
        if r.zf:
            return
        r.a = 0                                    # XOR A: obstacle must be 0
        r.set_zs(0)
        r.cf = False
        r.cp(mem[r.ix + 1 & 0xFFFF])
        if not r.zf:
            continue
        r.cp(mem[r.ix])                            # direction must not be 0
        if r.zf:
            continue
        return


async def ListVisibleExits():
    """Print "Visible exits are:" and the direction word of every exit of
    location A that has no obstacle and is not erased, then a new line; nothing
    when there is none. BC, DE, IX, IY kept."""
    ix, iy, de, bc = r.ix, r.iy, r.de, r.bc
    SeekExitsOfLocation()
    NextListedExit()                               # IX = first listable exit
    if not r.zf:
        r.hl = MsgVisibleExits
        await printer.PrintMessage()
        while True:
            r.a = mem[r.ix]                        # direction id of the exit
            GetIdWord()
            await printer.PrintWord()
            NextListedExit()
            if r.zf:
                break
        await screen.PrintNewLine()
    r.bc, r.de, r.iy, r.ix = bc, de, iy, ix


async def PrintStateIY():
    """Print "<object> is <state>" for the object in IY: HL := its name phrase
    (+8), then PrintStateHL. A = state id."""
    r.hl = mem16[r.iy + 8 & 0xFFFF]
    return await PrintStateHL()


async def PrintStateIX():
    """Print "<object> is <state>" for the object in IX: HL := its name phrase
    (+8), then PrintStateHL. A = state id."""
    r.hl = mem16[r.ix + 8 & 0xFFFF]
    return await PrintStateHL()


async def PrintStateHL():
    """Print "<the phrase at HL> is <word>." with MsgTheArgIsWord, the word from
    ReasonWords1 (state id A below 128: unlocked, empty, off, closed, dead) or
    ReasonWords2 (bit 7 set: locked, full, broken, on, open, alive). The word
    and the phrase go to the message. DE kept."""
    de, hl = r.de, r.hl
    table = ReasonWords2 if r.a & 0x80 else ReasonWords1
    r.hl = table
    GetTableWord()                                 # DE = state word
    printer.msg_args.append(r.de)
    printer.msg_args.append(hl)
    r.hl = MsgTheArgIsWord
    await printer.PrintMessage()
    r.de = de


def MarkBrokenOrDead():
    """Replace the second name phrase (+10) of object A with "broken" (an
    object) or "dead" (a character) and clear the third (+12). IX kept; DE is
    the word."""
    ix = r.ix
    FindObject()
    mem[r.ix + 0x0C & 0xFFFF] = 0                  # clear the third name phrase
    mem[r.ix + 0x0D & 0xFFFF] = 0
    r.de = PHRASE_BROKEN
    if mem[r.ix + 7 & 0xFFFF] >> FLAG_CHARACTER & 1:
        r.de = PHRASE_DEAD
    mem[r.ix + 0x0A & 0xFFFF] = r.e
    mem[r.ix + 0x0B & 0xFFFF] = r.d
    r.ix = ix


def LA1AE():
    """Walk the object table from ObjectTableBase for a record whose holder
    equals A (unreferenced; the asm compares with (IY+1) of the walk itself).
    Out: A = the id of the entry reached. IX, IY kept."""
    iy, ix = r.iy, r.ix
    r.ix = ObjectTableBase
    while True:
        NextObjectKeepA()
        if r.zf:
            break
        r.cp(mem[r.iy + 1 & 0xFFFF])
        if r.zf:
            break
    r.a = mem[r.ix]
    r.ix, r.iy = ix, iy


def LA1AE_2():
    """Z when the record in IX is a living character: (+7) & $48 = $40. Out:
    A = the masked flags; flags of CP $40."""
    r.a = _and_a(mem[r.ix + 7 & 0xFFFF] & 0x48)
    r.cp(0x40)
