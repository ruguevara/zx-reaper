"""The handlers of particular things, places and characters (stage 3:
handlers.py and world.py; src/handlers.asm, src/world.asm, docs/05-characters.md).

The game's tables name them: the things' verb tables, VerbHandlers, the
timers, the arrivals and the NPC script routines. Each is registered under
its stage 3 name (`registry.HANDLERS`) and takes the state only: its inputs
are in s.vars (command, first_object, second_object, subject, noun1, actor).
A handler that runs during a command's test pass (action_perform 0) returns
at once where world.commit_or_abort (or engine.abort_unless_perform) says so.
A flow target ('RestartGame' after the end of the game) is returned and
passed up by every caller. The other slices' modules (engine, verbs, parser)
are imported where they are called.

world.move_carried's last argument is the thing whose place ActorArrives sets
when the player is among the contents (the asm's IY, F85). Where a handler
leaves IY as the command dispatcher set it (PhraseRecord0 for the player's
commands, the NPC's turn record for a character's: not reproduced), the
carrier stands in: its place is the destination already, so the write
changes nothing."""
import functools

from . import assets, registry, text, world
from .state import AT_LOCATION

handler = registry.handler

# ids of things and characters (src/constants.asm)
PLAYER = 0
NO_OBJECT = 0xFF
OBJ_SMALL_CURIOUS_KEY, OBJ_DOOR_HOLE, OBJ_MAGIC_DOOR = 0x02, 0x0B, 0x0D
OBJ_SPIDER_WEB, OBJ_GOLDEN_RING, OBJ_GOBLINS_DOOR = 0x07, 0x10, 0x11
OBJ_ROPE, OBJ_BARREL, OBJ_WINE = 0x12, 0x13, 0x14
OBJ_TREASURE, OBJ_WOODEN_CHEST, OBJ_LUNCH, OBJ_BOAT = 0x23, 0x25, 0x26, 0x29
CHR_RED_GOLDEN_DRAGON, CHR_THORIN, CHR_WOOD_ELF, CHR_ELROND = 0x3C, 0x3F, 0x40, 0x41
CHR_BUTLER, CHR_VICIOUS_WARG, CHR_GOLLUM, CHR_BARD = 0x42, 0x43, 0x44, 0x46
CHR_HIDEOUS_TROLL, CHR_VICIOUS_TROLL = 0x47, 0x48
KEYS = (0x02, 0x04, 0x0F)               # the three keys the locks know
# the NPC turn slots the arrivals wake (index in s.npcs: NpcButler, NpcBard, NpcDragon)
NPC_BUTLER, NPC_BARD, NPC_DRAGON = 4, 7, 8

# locations
LOC_FOREST_ROAD, LOC_FOREST = 0x02, 0x03
LOC_TROLLS_CLEARING = 0x05
LOC_GOBLINS_DUNGEON, LOC_DARK_STUFFY_PASSA_0F, LOC_GOBLINS_DOOR = 0x0D, 0x0F, 0x10
LOC_SPIDER_PLACE, LOC_MAGIC_DOOR_B, LOC_BOG, LOC_MAGIC_DOOR_A = 0x1A, 0x1C, 0x1D, 0x1E
LOC_DARK_DUNGEON, LOC_CELLAR, LOC_FOREST_RIVER, LOC_RIVER_BANK = 0x1F, 0x20, 0x21, 0x22
LOC_LAIR_A, LOC_LAIR_B, LOC_LAIR_C, LOC_HOLE = 0x27, 0x29, 0x2C, 0x2A
LOC_TREASURE_HOME = 0x29
LOC_BANK_A, LOC_BANK_B = 0x42, 0x43

DIR_DOWN = 0x0A

# commands (record ids)
CMD_STRIKE, CMD_CLOSE, CMD_OPEN, CMD_LOOK_THROUGH = 0x0B, 0x0C, 0x10, 0x18
CMD_KILL_PLAYER, CMD_GIVE, CMD_GO_THROUGH, CMD_LOCK = 0x1B, 0x1D, 0x1E, 0x25
PLACING_COMMANDS = (0x0E, 0x11, 0x12, 0x14, 0x2C)   # IdList: drop in, put in, put on,
                                                    # take out of, throw through

# flags of a thing (+7) and a location
F_PRESENT, F_CHARACTER, F_ACTIVE, F_DEAD, F_EMPTIED, F_LIQUID, F_LOCKED = \
    0x80, 0x40, 0x20, 0x08, 0x04, 0x02, 0x01
LOC_LIT, LOC_VISITED = 0x80, 0x40
STATE_SIDE_BITS = 0x70
REASON_CLOSED, REASON_LOCKED, REASON_OPEN = 0x05, 0x80, 0x85

WORD_ANOTHER, WORD_GOBLIN = 0x005E, 0x02E2
WEB_CUT_NAME = 0x0623                   # the web's first adjective once it is cut
PICTURE5_DAWN = (0x05, 0x28)            # picture 5's border and attribute bytes at dawn
RIDDLE_ORDER_BYTES = 24                 # the bytes of a stored order LA8F6 searches


@functools.lru_cache(None)
def _data():
    """handlers.json (the respawn table, the Bard's command) and tables.json."""
    d = assets.load_json('handlers.json')
    if len(d['respawn']) != 6 or any(len(r) != 4 for r in d['respawn']):
        raise ValueError('handlers.json: respawn: 6 entries of [id, npc slot, home, name] expected')
    return d, assets.load_json('tables.json')


def _noun1(s):
    """The thing of the first noun record (Noun1Record)."""
    return world.thing(s, s.vars.noun1[1])


def _actor(s):
    return world.thing(s, s.vars.actor)


def _player(s):
    return world.thing(s, PLAYER)


def _start_timer(s, k):
    s.timers[k].counter = s.timers[k].start


def _target(x):
    """A flow target (a Goto of stage 3) among the values a call returns."""
    return x if isinstance(x, str) else None


# ---- tests other modules call ---------------------------------------------

def is_placing_command(s):
    """Does the command put an object somewhere (drop in, put in, put on, take
    out of, throw through)? (stage 3: IsPlacingCommand)"""
    return s.vars.command in PLACING_COMMANDS


def check_open(s, thing_id):
    """Is thing `thing_id` open (flag bit 5)? (stage 3: CheckOpen; the asm's A,
    REASON_CLOSED, is what its callers print when not)"""
    return bool(world.thing(s, thing_id).flags & F_ACTIVE)


def check_openable(s):
    """Can the first noun's thing be opened? Returns (refused, reason): locked
    (True, REASON_LOCKED), open already (True, REASON_OPEN), closed (False,
    REASON_OPEN) (stage 3: CheckOpenable)."""
    t = _noun1(s)
    if t.flags & F_LOCKED:
        return True, REASON_LOCKED
    return check_openable_thing(s, t.id)


def check_openable_thing(s, thing_id):
    """The open test of check_openable: (open already, REASON_OPEN) (stage 3:
    CheckOpenable_0)."""
    return bool(world.thing(s, thing_id).flags & F_ACTIVE), REASON_OPEN


def check_victory(s):
    """Generator: once a turn, the game is won when the treasure is in the
    wooden chest: the cheering crowd, then the end (the score, a key, the
    restart). Returns the flow target or None (stage 3: CheckVictory)."""
    from . import verbs
    if world.thing(s, OBJ_TREASURE).holder != OBJ_WOODEN_CHEST:
        return None
    yield from text.print_message(s, 'MsgCheeringCrowdDwarves')
    return (yield from verbs.end_game_wait(s))


def print_speech(s, message, args=None):
    """Generator: <subject> say(s) "<message>". with a capital at the start of
    the words (stage 3: PrintSpeech; `args` as text.print_message takes them)."""
    yield from text.print_message(s, 'MsgSay')
    s.vars.capital_next = 1
    yield from text.print_message(s, message, args)
    yield from text.print_message(s, 'MsgB00F')


def _end_game(s, message):
    """Print `message`, then the game ends."""
    from . import verbs
    yield from text.print_message(s, message)
    return (yield from verbs.end_game(s))


# ---- the rope, the locks, deaths -------------------------------------------

@handler('LA244')
def la244(s):
    """Nothing but the test pass (stage 3: LA244)."""
    world.commit_or_abort(s)


@handler('LA244_0')
def la244_0(s):
    """Generator: tie something to the rope. With the rope first the handler
    runs again with the objects swapped. Refused unless the rope is the second
    object, the thing is not a liquid, nothing is tied to the rope yet ("already
    tied") and it is no living character. Done: the thing hangs on the rope;
    when the subject does not hold it, a take is tried first (stage 3: LA244_0).
    Quirk: the take test (VerbTake's CheckCanCarry) leaves the asm's IY at the
    actor, so the holder written after it is the actor's, not the rope's: the
    actor is held by the subject (itself), or by nothing when the take was
    refused."""
    v = s.vars
    if v.first_object == OBJ_ROPE:
        return (yield from world.call_swapped(s, 'LA244_0'))
    if v.second_object != OBJ_ROPE:
        return (yield from world.refuse_command(s))
    t = _noun1(s)
    if t.flags & F_LIQUID:
        return (yield from world.refuse_command(s))
    if world.count_held_present(s, OBJ_ROPE):
        return (yield from text.print_message(s, 'MsgAlreadyTied'))
    if not t.flags & F_DEAD and t.flags & F_CHARACTER:
        return (yield from world.refuse_command(s))
    if not world.commit_or_abort(s):
        return None
    held = world.first_object_held(s)
    t.holder = v.second_object
    rope = world.thing(s, v.noun2[1])
    if not held:
        v.action_perform = 0
        target = _target((yield from registry.call('VerbTake', s)))
        if target:
            return target
        allowed = v.action_allowed
        v.action_perform = v.action_allowed = 1
        rope = _actor(s)                    # (the quirk: IY is the actor now)
        if not allowed:
            rope.holder = NO_OBJECT
            return None
    rope.holder = v.subject
    return None


@handler('LA244_5')
def la244_5(s):
    """Generator: untie: the first noun's thing must hang on the rope ("not
    tied"); it then has the rope's holder (stage 3: LA244_5)."""
    t = _noun1(s)
    if t.holder != OBJ_ROPE:
        return (yield from text.print_message(s, 'MsgNotTied'))
    if not world.commit_or_abort(s):
        return None
    t.holder = world.thing(s, OBJ_ROPE).holder
    return None


@handler('LA244_6')
def la244_6(s):
    """Generator: go through the exit that has the first object as its
    obstacle: an exit with no destination only commits; else the actor moves
    in its direction (the obstacle open meanwhile: flag bit 5, cleared after;
    the command and first object are put back) (stage 3: LA244_6). Not
    reproduced: without such an exit the asm reads the byte after the
    location's exits (taken as no destination here)."""
    from . import verbs
    v = s.vars
    e = world.exit_by_obstacle(s, v.first_object)
    if e is None or not e.destination:
        world.commit_or_abort(s)
        return None
    saved = v.command, v.first_object
    v.command = e.direction
    t = _noun1(s)
    t.flags |= F_ACTIVE
    v.first_object = NO_OBJECT
    target = _target((yield from verbs.move_actor(s)))
    if target:
        return target
    t.flags &= ~F_ACTIVE & 0xFF
    v.command, v.first_object = saved
    return None


@handler('LA244_8')
def la244_8(s):
    """Generator: only the dragon can do it (else refused): the first object
    dies (stage 3: LA244_8)."""
    from . import engine
    if s.vars.subject != CHR_RED_GOLDEN_DRAGON:
        return (yield from world.refuse_command(s))
    if not world.commit_or_abort(s):
        return None
    return (yield from engine.kill_first_object(s))


@handler('LA244_9')
def la244_9(s):
    """Generator: touching the river kills (stage 3: LA244_9)."""
    if not world.commit_or_abort(s):
        return None
    return (yield from la244_10(s, 'MsgAsSoonAsTouchRiver'))


@handler('LA244_11')
def la244_11(s):
    """Generator: falling asleep kills (stage 3: LA244_11)."""
    if not world.commit_or_abort(s):
        return None
    return (yield from la244_10(s, 'MsgFallAsleep'))


def la244_10(s, message):
    """Generator: print `message`, "time passes" for the player, and the
    subject dies (stage 3: LA244_10)."""
    from . import engine
    yield from text.print_message(s, message)
    subject = s.vars.subject
    if subject == PLAYER:
        yield from text.print_message(s, 'MsgTimePasses2')
    return (yield from engine.kill_character(s, subject))


@handler('LA244_12')
def la244_12(s):
    """Generator: the lock key 2 opens (stage 3: LA244_12)."""
    return (yield from lock_with_key(s, 0x02))


@handler('LA244_13')
def la244_13(s):
    """Generator: the lock key $0F opens (stage 3: LA244_13)."""
    return (yield from lock_with_key(s, 0x0F))


@handler('LA244_14')
def la244_14(s):
    """Generator: the lock key 4 opens (stage 3: LA244_14)."""
    return (yield from lock_with_key(s, 0x04))


def lock_with_key(s, key):
    """Generator: lock (LOCK) or unlock with the second object: the right key
    `key` does it (L9404_5, L9404_7), another of the three keys "does not fit",
    anything else "I cannot do that" (stage 3: LA244_15)."""
    v = s.vars
    if v.second_object == key:
        return (yield from registry.call('L9404_5' if v.command == CMD_LOCK else 'L9404_7', s))
    if v.second_object in KEYS:
        return (yield from print_no_fit(s))
    return (yield from text.print_cannot_do_that(s))


@handler('PrintNoFit')
def print_no_fit(s):
    """Generator: "That key does not fit this lock." (stage 3: PrintNoFit)"""
    yield from text.print_message(s, 'MsgDoesNotFitThisLock')


# ---- doors and openings ------------------------------------------------------

@handler('LA35E')
def la35e(s):
    """Generator: open the first noun's thing, really performing only (stage 3:
    LA35E)."""
    from . import engine, verbs
    if not engine.abort_unless_perform(s):
        return None
    return (yield from verbs.open_thing(s, s.vars.noun1[1]))


@handler('OpenCrack')
def open_crack(s):
    """Generator: the small insignificant crack opens only from the dark stuffy
    passage; elsewhere refused (stage 3: OpenCrack)."""
    if world.actor_location(s) != LOC_DARK_STUFFY_PASSA_0F:
        return (yield from world.refuse_command(s))
    return (yield from registry.call('OpenObject', s))


@handler('LA4C0')
def la4c0(s):
    """Generator: open the goblins' door, only at its place; really performed,
    timer 3 starts (it shuts the door again) (stage 3: LA4C0)."""
    from . import engine
    if world.actor_location(s) != LOC_GOBLINS_DOOR:
        return (yield from world.refuse_command(s))
    target = _target((yield from registry.call('OpenObject', s)))
    if target:
        return target
    if not engine.abort_unless_perform(s):
        return None
    _start_timer(s, 3)
    return None


@handler('LA4C0_0')
def la4c0_0(s):
    """Timer 3: the goblins' door shuts (stage 3: LA4C0_0)."""
    world.thing(s, OBJ_GOBLINS_DOOR).flags &= ~F_ACTIVE & 0xFF


@handler('LA536')
def la536(s):
    """Generator: only the wood elf opens it (else refused) (stage 3: LA536)."""
    if s.vars.subject != CHR_WOOD_ELF:
        return (yield from world.refuse_command(s))
    return (yield from registry.call('OpenObject', s))


@handler('LA67E')
def la67e(s):
    """Generator: open or close (CLOSE) a door of the dragon's lair: only from
    the cellar, else "cannot reach" (stage 3: LA67E)."""
    if world.actor_location(s) != LOC_CELLAR:
        return (yield from text.print_message(s, 'MsgCannotReach'))
    return (yield from registry.call('CloseObject' if s.vars.command == CMD_CLOSE else 'OpenObject', s))


@handler('LA67E_6')
def la67e_6(s):
    """Generator: the magic door: a visible actor (flag bit 7) sees nothing
    special; an invisible one sets timer 5 going and "the magic door warns the
    elves" (stage 3: LA67E_6)."""
    if not world.commit_or_abort(s):
        return None
    if _actor(s).flags & F_PRESENT:
        return (yield from text.print_message(s, 'MsgSeeNothingSpecialHere'))
    _start_timer(s, 5)
    yield from text.print_message(s, 'MsgMagicDoorWarnsElves')
    return None


@handler('LA761')
def la761(s):
    """Generator: open or close the window-like thing: never the player ("cannot
    reach" when free, refused when inside something); others close (CLOSE) or
    open (OPEN) (stage 3: LA761)."""
    v = s.vars
    if v.subject == PLAYER:
        if _player(s).holder == AT_LOCATION:
            return (yield from text.print_message(s, 'MsgCannotReach'))
        return (yield from world.refuse_command(s))
    if v.command == CMD_CLOSE:
        return (yield from registry.call('CloseObject', s))
    if v.command == CMD_OPEN:
        return (yield from registry.call('OpenObject', s))
    return None


@handler('LA761_1')
def la761_1(s):
    """Generator: go through, strike or look through it; the player only from
    inside something ("cannot reach" when free) (stage 3: LA761_1)."""
    v = s.vars
    if v.subject == PLAYER and _player(s).holder == AT_LOCATION:
        return (yield from text.print_message(s, 'MsgCannotReach'))
    name = {CMD_GO_THROUGH: 'L8F3B', CMD_STRIKE: 'StrikeObject',
            CMD_LOOK_THROUGH: 'VerbLookThrough'}.get(v.command)
    if name:
        return (yield from registry.call(name, s))
    return None


@handler('LA761_3')
def la761_3(s):
    """Generator: timer 4 (its fire and tick): sinking into the bog; in the bog
    itself the counter stops first; "slowly sinking into the bog", and with the
    counter at 0 the end (stage 3: LA761_3)."""
    if _player(s).places[0] == LOC_BOG:
        s.timers[4].counter = 0
    yield from text.print_message(s, 'MsgSlowlySinkingIntoBog')
    if s.timers[4].counter:
        return None
    return (yield from verbs_end_game(s))


@handler('LA9E5_3')
def la9e5_3(s):
    """Timer 9: unless the door in the hole is open, timer 9 starts again, the
    door is not present, and at its place "the hole vanishes" (stage 3: LA9E5_3)."""
    door = world.thing(s, OBJ_DOOR_HOLE)
    if door.flags & F_ACTIVE:
        return None
    _start_timer(s, 9)
    door.flags &= ~F_PRESENT & 0xFF
    if _player(s).places[0] != LOC_HOLE:
        return None
    return (yield from la9e5_4(s))


@handler('LA9E5_4')
def la9e5_4(s):
    """Generator: "The hole vanishes." (stage 3: LA9E5_4)"""
    yield from text.print_message(s, 'MsgHoleVanishes')


@handler('LA9E5_5')
def la9e5_5(s):
    """Timer 9 ticking: the door in the hole is present; at its place "there is
    a loud crack and a hole..." (stage 3: LA9E5_5)."""
    world.thing(s, OBJ_DOOR_HOLE).flags |= F_PRESENT
    if _player(s).places[0] != LOC_HOLE:
        return None
    yield from text.print_message(s, 'MsgThereLoudCrackHole')
    return None


@handler('LA9E5_6')
def la9e5_6(s):
    """Generator: really performed, timer 9 counts 6, the door in the hole is
    locked and gone, and "the hole vanishes" (stage 3: LA9E5_6)."""
    from . import engine
    if not engine.abort_unless_perform(s):
        return None
    s.timers[9].counter = 6
    door = world.thing(s, OBJ_DOOR_HOLE)
    door.flags = (door.flags | F_LOCKED) & ~F_PRESENT & 0xFF
    return (yield from la9e5_4(s))


@handler('LA9E5_7')
def la9e5_7(s):
    """Timer 5 ticking: the magic door opens, "an elf sweeps past" (both heard
    at the door's two places), then the ring comes off a wearer (stage 3:
    LA9E5_7)."""
    world.thing(s, OBJ_MAGIC_DOOR).flags |= F_ACTIVE
    yield from la9e5_8(s, 'MsgMagicDoorOpens')
    yield from la9e5_8(s, 'MsgElfSweepsPast')
    return (yield from la9e5_10(s))


def la9e5_8(s, message):
    """Generator: print `message` when the player is at either side of the
    magic door (stage 3: LA9E5_8)."""
    if _player(s).places[0] in (LOC_MAGIC_DOOR_A, LOC_MAGIC_DOOR_B):
        yield from text.print_message(s, message)


@handler('LA9E5_9')
def la9e5_9(s):
    """Timer 5: the magic door closes (stage 3: LA9E5_9)."""
    world.thing(s, OBJ_MAGIC_DOOR).flags &= ~F_ACTIVE & 0xFF
    yield from la9e5_8(s, 'MsgMagicDoorCloses')


# ---- the ring, the spiders, the web ------------------------------------------

@handler('LA377')
def la377(s):
    """Generator: the web (when cut: flag bit 3): its bit 5 set, timer 1
    starts, "some spiders start..." (stage 3: LA377)."""
    t = _noun1(s)
    if not t.flags & F_DEAD:
        return None
    t.flags |= F_ACTIVE
    _start_timer(s, 1)
    yield from text.print_message(s, 'MsgSomeSpidersStart')
    return None


@handler('LA377_0')
def la377_0(s):
    """Generator: put on the golden ring: the actor is invisible (flag bit 7
    cleared, strength quartered), the ring too, held by the subject; timer 6
    runs 2 + a random 0-8 turns (stage 3: LA377_0)."""
    if not world.commit_or_abort(s):
        return None
    actor, ring = _actor(s), world.thing(s, OBJ_GOLDEN_RING)
    actor.flags &= ~F_PRESENT & 0xFF
    actor.strength >>= 2
    ring.flags &= ~F_PRESENT & 0xFF
    ring.holder = s.vars.subject
    n = yield from world.random_up_to(s, 8)
    s.timers[6].counter = n + 2 & 0xFF
    return None


@handler('LA377_1')
def la377_1(s):
    """Generator: take off the golden ring: "not wearing" when the ring is
    visible; else the actor and the ring are visible again (strength times
    four, as a byte) and timer 6 stops (stage 3: LA377_1)."""
    actor, ring = _actor(s), world.thing(s, OBJ_GOLDEN_RING)
    if ring.flags & F_PRESENT:
        return (yield from text.print_message(s, 'MsgNotWearing'))
    if not world.commit_or_abort(s):
        return None
    ring.flags |= F_PRESENT
    actor.flags |= F_PRESENT
    actor.strength = actor.strength << 2 & 0xFF
    s.timers[6].counter = 0
    return None


@handler('LA9E5_10')
def la9e5_10(s):
    """Generator: timer 6: whoever holds the golden ring becomes the actor (it
    stays so), and when invisible the ring comes off (stage 3: LA9E5_10)."""
    holder = world.thing(s, OBJ_GOLDEN_RING).holder
    if holder == AT_LOCATION:
        return None
    s.vars.actor = holder
    if not world.thing(s, holder).flags & F_PRESENT:
        return (yield from la377_1(s))
    return None


@handler('LA9E5_2')
def la9e5_2(s):
    """Timer 1: the spider web is whole again: flag bits 3 and 5 cleared, its
    strength doubled (a byte), its first adjective back (stage 3: LA9E5_2)."""
    web = world.thing(s, OBJ_SPIDER_WEB)
    web.flags &= ~(F_DEAD | F_ACTIVE) & 0xFF
    web.strength = web.strength << 1 & 0xFF
    web.names[1] = WEB_CUT_NAME


@handler('LA9E5_11')
def la9e5_11(s):
    """The player lisps (timer 7 ends it) (stage 3: LA9E5_11)."""
    if s.vars.subject != PLAYER:
        return
    s.vars.lisp = 1
    _start_timer(s, 7)


@handler('LA9E5_12')
def la9e5_12(s):
    """Timer 7: the lisp ends (stage 3: LA9E5_12)."""
    s.vars.lisp = 0


@handler('LA9E5_13')
def la9e5_13(s):
    """Generator: timer 2: at the spider place the web holds the player: the
    end (stage 3: LA9E5_13)."""
    if _player(s).places[0] != LOC_SPIDER_PLACE:
        return None
    return (yield from _end_game(s, 'MsgSpiderWebSlowly'))


@handler('LA9E5_14')
def la9e5_14(s):
    """Generator: timer 8 ticking: "pale bulbous eyes", and the spiders drop
    unless the player is at the forest place he came from or the other one
    (stage 3: LA9E5_14)."""
    return (yield from spider_eyes(s, 'MsgSeeSomePaleBulbous'))


@handler('SpiderEyesFromHL')
def spider_eyes(s, message='SpiderEyesFromHL'):
    """Generator: print `message`; the game ends unless the player is where he
    arrived in the forest (arrival_location) or at the other forest place (3
    after 2, else 2) (stage 3: SpiderEyesFromHL). Run from a timer table (timer
    2's handler after F85) the asm prints its own code bytes as a message: the
    message 'SpiderEyesFromHL' (kept)."""
    yield from text.print_message(s, message)
    here, came = _player(s).places[0], s.vars.arrival_location
    if here == came:
        return None
    if here == (LOC_FOREST if came == LOC_FOREST_ROAD else LOC_FOREST_ROAD):
        return None
    return (yield from la9e5_18(s))


@handler('LA9E5_16')
def la9e5_16(s):
    """Generator: timer 8: in the forest the spiders come: the end (stage 3:
    LA9E5_16)."""
    if _player(s).places[0] not in (LOC_FOREST_ROAD, LOC_FOREST):
        return None
    yield from text.print_message(s, 'MsgSeeSomePaleBulbous')
    return (yield from la9e5_18(s))


@handler('LA9E5_18')
def la9e5_18(s):
    """Generator: "some drops from above": the end (stage 3: LA9E5_18)."""
    return (yield from _end_game(s, 'MsgSomeDropsFromAbove'))


# ---- capture, climbing, letting go -------------------------------------------

@handler('VerbCapture')
def verb_capture(s):
    """Generator: capture a character: to the elvenking's dark dungeon (by the
    wood elf or the butler) or the goblins' dungeon, with what it carries.
    Refused when the two are on a side together, the thing is no character, or
    the capturer is in the prison. A captured player is the subject and actor
    then and sees the prison unless it is dark (stage 3: VerbCapture)."""
    from . import engine
    v = s.vars
    captive = _noun1(s)
    if captive.state & STATE_SIDE_BITS & _actor(s).state:
        return (yield from world.refuse_command(s))
    if not captive.flags & F_CHARACTER:
        return (yield from world.refuse_command(s))
    prison = LOC_DARK_DUNGEON if v.subject in (CHR_WOOD_ELF, CHR_BUTLER) else LOC_GOBLINS_DUNGEON
    if v.actor_location == prison:
        return (yield from world.refuse_command(s))
    if not world.commit_or_abort(s):
        return None
    captive.places[0], captive.holder = prison, AT_LOCATION
    target = _target((yield from world.move_carried(s, v.first_object, prison, captive.id)))
    if target:
        return target
    if v.first_object != PLAYER:
        return None
    v.subject = v.actor = PLAYER
    if engine.check_dark(s):
        return None
    return (yield from engine.describe_location_intro(s, prison, 'MsgSubjIsIn'))


@handler('LA536_0')
def la536_0(s):
    """Generator: let go of (get out of) the first object: it must be the
    actor's holder and open ("<it> is closed"); the actor is then free (stage
    3: LA536_0)."""
    actor = _actor(s)
    if s.vars.first_object != actor.holder:
        return (yield from world.refuse_command(s))
    t = world.thing(s, s.vars.first_object)
    if not check_open(s, t.id):
        return (yield from world.print_state(s, t.id, REASON_CLOSED))
    if not world.commit_or_abort(s):
        return None
    actor.holder = AT_LOCATION
    return None


@handler('LA536_1')
def la536_1(s):
    """Generator: climb into the first object (the barrel, the chest, the boat):
    not the actor's holder already, within reach; when the subject holds it
    (at any depth) it is put down first. It must be open ("is closed"); the
    room test compares its weight with the actor's load (stage 3: LA536_1).
    Quirk: without a carry the load is taken as $FF, so only a load past 255
    can be "too big"; a container of weight $FF takes anything."""
    v = s.vars
    actor = _actor(s)
    if v.first_object == actor.holder:
        return (yield from world.refuse_command(s))
    t = _noun1(s)
    if not world.actor_can_reach(s, t.id):
        return (yield from world.refuse_command(s))
    up = v.first_object
    while True:                         # up the holders of the first object
        h = world.thing(s, up).holder
        if h == AT_LOCATION:
            break
        if h == v.subject:
            t.holder = AT_LOCATION      # held by the subject: put down first
            break
        up = h
    load = world.held_weight(s, v.subject) + actor.weight
    room = load & 0xFF if load > 0xFF else 0xFF          # (sic)
    if not check_open(s, t.id):
        return (yield from world.print_state(s, t.id, REASON_CLOSED))
    if t.weight != 0xFF and t.weight >= room:
        return (yield from text.print_message(s, 'MsgTooBig'))
    if not world.commit_or_abort(s):
        return None
    actor.holder = v.first_object
    return None


@handler('LA9E5_1')
def la9e5_1(s):
    """Generator: jump onto the first object: an exit of the actor's place must
    lead to its place ("cannot jump onto" when none); downwards only. Then the
    actor is on it and moves there with it; the player sees the place (stage 3:
    LA9E5_1). Quirk: for an exit in another direction the asm jumps into the
    message's bytes (JP NZ,MsgCannotJumpOntoFrom) and runs them as code; that
    code always runs on into the next message (its ADC always carries), which
    stage 3 does not port either: NotImplementedError, the same limit."""
    from . import engine
    v = s.vars
    t = _noun1(s)
    place = t.places[0]
    e = world.exit_by_destination(s, place)
    if e is None:
        return (yield from text.print_message(s, 'MsgCannotJumpOntoFrom'))
    if e.direction != DIR_DOWN:
        raise NotImplementedError('JP NZ,MsgCannotJumpOntoFrom: the Z80 runs on into message data')
    if not world.commit_or_abort(s):
        return None
    _actor(s).holder = v.first_object
    target = _target((yield from world.move_carried(s, v.first_object, place, t.id)))
    if target:
        return target
    if v.subject != PLAYER:
        return None
    return (yield from engine.describe_location(s, place))


# ---- the goblins -------------------------------------------------------------

@handler('RespawnKilledGoblin')
def respawn_killed_goblin(s, b=None):
    """Generator: after an attack on a goblin: a killed goblin comes back at
    its home (alive, its turn slot filled again, its first adjective in place of
    "dead"); "<it> falls down a hole and vanishes", and "Another goblin enters."
    when the player is at location `b` (stage 3: RespawnKilledGoblin). It runs
    on the test pass too. Quirk: `b` is the asm's B, left by the command
    dispatcher (0 or $0E in the records); None (the game's default) never
    matches."""
    t = _noun1(s)
    if not t.flags & F_DEAD:
        return None
    t.flags &= ~F_DEAD & 0xFF
    gid = s.vars.first_object
    _, slot, home, name = next(r for r in _data()[0]['respawn'] if r[0] == gid)
    s.npcs[slot].id = gid
    t.places[0] = home
    t.names[1] = name
    yield from text.print_message(s, 'MsgFallsDownHoleVanishes')
    if _player(s).places[0] != b:
        return None
    yield from text.print_word(s, WORD_ANOTHER, 0)
    yield from text.print_word(s, WORD_GOBLIN, 0)
    yield from text.print_message(s, 'MsgEnters2')
    return None


# ---- the barrel, the boat ----------------------------------------------------

@handler('LA5E2')
def la5e2(s):
    """A barrel thrown in at the forest river floats off: timer 0 counts 2,
    really performing (stage 3: LA5E2)."""
    from . import engine
    if s.vars.first_object != OBJ_BARREL:
        return None
    if not engine.abort_unless_perform(s):
        return None
    if world.thing(s, OBJ_BARREL).places[0] != LOC_FOREST_RIVER:
        return None
    s.timers[0].counter = 2
    return None


@handler('LA5E2_0')
def la5e2_0(s):
    """Generator: timer 0: the barrel floats to the bank (a player in it is
    thrown out there, "...thrown onto the bank"), then lies in the cellar,
    emptied quietly, with the wine in it (stage 3: LA5E2_0). Quirk (F85): the
    asm's IY is timer 0's record when MoveCarried runs, so a player arriving
    in the barrel sets timer 2's handler to 'SpiderEyesFromHL' (passed as
    ('timer', 0), the record ActorArrives writes the place into)."""
    v = s.vars
    v.timers_fired = 0
    if _player(s).holder == OBJ_BARREL:
        yield from text.print_message(s, 'MsgThrownOntoBankLong')
    barrel = world.thing(s, OBJ_BARREL)
    barrel.places[0] = LOC_RIVER_BANK
    target = _target((yield from world.move_carried(s, OBJ_BARREL, LOC_RIVER_BANK, ('timer', 0))))
    if target:
        return target
    barrel.places[0] = LOC_CELLAR
    barrel.flags = (barrel.flags & ~F_ACTIVE | F_EMPTIED) & 0xFF
    v.messages_visible = 0
    yield from world.empty_holder(s, OBJ_BARREL)
    v.messages_visible = 1
    wine = world.thing(s, OBJ_WINE)
    wine.places[0], wine.holder = LOC_CELLAR, OBJ_BARREL
    return None


def below_half(s):
    """Generator: a random 0-100 below 50? (stage 3: LA814_3)"""
    return (yield from world.random_up_to(s, 100)) < 50


@handler('LA814')
def la814(s, b=None):
    """Generator: sail the boat across the river (the exit with the second
    object as its obstacle; refused without one): "sails across", then by luck:
    with the boat at the far side it lands there (held by the rope) or falls
    short, or lands and slides out; else it falls short or the first object
    lands on the other side (stage 3: LA814). Quirk: what the first object
    carries goes to location `b`, the asm's B left by the dispatcher; None
    (the game's default) is taken as the far side."""
    v = s.vars
    e = world.exit_by_obstacle(s, v.second_object)
    if e is None:
        return (yield from world.refuse_command(s))
    if not world.commit_or_abort(s):
        return None
    yield from text.print_message(s, 'MsgSailsAcross')
    boat = world.thing(s, OBJ_BOAT)
    if boat.places[0] == e.destination:
        if (yield from below_half(s)):
            boat.holder = OBJ_ROPE
            message = 'MsgLandsBoat'
        else:
            message = 'MsgFallsJustShortOther'
            if not (yield from below_half(s)):
                message = 'MsgLandsBoatButSlidesOut'
    else:
        message = 'MsgFallsJustShortOther'
        if not (yield from below_half(s)):
            t = _noun1(s)
            t.places[0], t.holder = e.destination, AT_LOCATION
            target = _target((yield from world.move_carried(
                s, v.first_object, e.destination if b is None else b, t.id)))
            if target:
                return target
            message = 'MsgLandsOnOtherSide'
    yield from text.print_message(s, message)
    return None


@handler('LA814_4')
def la814_4(s):
    """Generator: when the boat is tied to the rope, "the boat glides across the
    river" to the other bank (stage 3: LA814_4)."""
    if not world.commit_or_abort(s):
        return None
    if world.thing(s, OBJ_BOAT).holder != OBJ_ROPE:
        return None
    return (yield from la814_5(s, 'MsgBoatGlidesAcrossRiver'))


def la814_5(s, message):
    """Generator: print `message`; the boat crosses to the other bank ($43 from
    $42, else $42), free, with what it carries (stage 3: LA814_5; stage 3 has
    the two banks the other way round, against the asm's JR NZ: the asm is
    followed here)."""
    yield from text.print_message(s, message)
    boat = world.thing(s, OBJ_BOAT)
    boat.places[0] = LOC_BANK_B if boat.places[0] == LOC_BANK_A else LOC_BANK_A
    boat.holder = AT_LOCATION
    return (yield from world.move_carried(s, OBJ_BOAT, boat.places[0], OBJ_BOAT))


@handler('LA814_7')
def la814_7(s):
    """Generator: the player pushes the boat off: "with a lurch the boat
    glides", and it crosses (stage 3: LA814_7)."""
    from . import engine
    if not engine.abort_unless_perform(s):
        return None
    if s.vars.subject != PLAYER:
        return None
    return (yield from la814_5(s, 'MsgWithLurchBoatGlides'))


@handler('LA814_8')
def la814_8(s):
    """Generator: the Bard's script: an order for him (actor_has_order 1) is
    taken (parser.run_stored_order); when usable the action is refused here
    and his script command becomes it (a verb and two objects, the op $42)
    (stage 3: LA814_8). The asm reads the verb from SavedCommandId, the command
    record the order matched: s.vars.command here (equal unless the order's
    test pass changed the command)."""
    from . import parser
    v = s.vars
    if v.actor_has_order != 1:
        return None
    v.actor_has_order = 0
    done, _ = yield from parser.run_stored_order(s, True)
    if not done:
        return None
    v.action_allowed = 0
    c = s.program[_data()[0]['bard_command']]
    c.op, c.args = 0x42, [v.command, v.first_object, v.second_object]
    return None


# ---- the dragon, the trolls, the treasure --------------------------------------

@handler('LA67E_0')
def la67e_0(s):
    """Generator: the dragon comes to the player in its lair (three places):
    "<the dragon> enters" (stage 3: LA67E_0)."""
    here = _player(s).places[0]
    if here not in (LOC_LAIR_A, LOC_LAIR_C, LOC_LAIR_B):
        return None
    if not world.commit_or_abort(s):
        return None
    dragon = world.thing(s, CHR_RED_GOLDEN_DRAGON)
    if here == dragon.places[0]:
        return None
    dragon.places[0] = here
    s.vars.messages_visible = 1
    yield from text.print_message(s, 'MsgEnters', [dragon.names])
    return None


@handler('LA67E_3')
def la67e_3(s):
    """Generator: the dragon with the player: to a visible player "Well,
    thief...", to an invisible one "I may not..." (stage 3: LA67E_3)."""
    if _player(s).places[0] != s.vars.actor_location:
        return None
    if not world.commit_or_abort(s):
        return None
    visible = _player(s).flags & F_PRESENT
    yield from text.print_message(s, 'MsgDragonSaysWellThief' if visible else 'MsgDragonSaysIMayNot')
    return None


@handler('LA67E_5')
def la67e_5(s):
    """Generator: while the treasure is away from the dragon's hall and the
    player is in the open (a lit place): "in the distance you see a shape", or
    by a random 0-100 of $50 and more "the dragon descends": the end (stage 3:
    LA67E_5). Not reproduced: a player location of 80 or more (the asm reads
    the record it found before)."""
    if world.thing(s, OBJ_TREASURE).places[0] == LOC_TREASURE_HOME:
        return None
    if not s.locations[_player(s).places[0]].flags & LOC_LIT:
        return None
    if not world.commit_or_abort(s):
        return None
    s.vars.messages_visible = 1
    if (yield from world.random_up_to(s, 100)) < 0x50:
        yield from text.print_message(s, 'MsgDistanceSeeShape')
        return None
    return (yield from _end_game(s, 'MsgDragonDescends'))


@handler('ThorinDeathBreaksKey')
def thorin_death_breaks_key(s):
    """Generator: after an attack on Thorin: when he is dead, really performing,
    the small curious key breaks; "The small curious key shatters." when the
    player can reach it (stage 3: ThorinDeathBreaksKey)."""
    from . import engine
    if not world.thing(s, CHR_THORIN).flags & F_DEAD:
        return None
    if not engine.abort_unless_perform(s):
        return None
    world.thing(s, OBJ_SMALL_CURIOUS_KEY).flags |= F_DEAD
    world.mark_broken_or_dead(s, OBJ_SMALL_CURIOUS_KEY)
    if not world.can_reach(s, PLAYER, OBJ_SMALL_CURIOUS_KEY):
        return None
    yield from text.print_message(s, 'MsgSmallCuriousKey')
    return None


@handler('LA94E_0')
def la94e_0(s):
    """Generator: dawn: both trolls die and turn to stone (not present, what
    they hold falls), the clearing's text tells of two stone trolls and it is
    not visited, "Day dawns", and picture 5 turns to day (stage 3: LA94E_0)."""
    from . import engine
    if not world.commit_or_abort(s):
        return None
    for troll in (CHR_HIDEOUS_TROLL, CHR_VICIOUS_TROLL):
        target = _target((yield from engine.kill_character(s, troll)))
        if target:
            return target
    for troll in (CHR_HIDEOUS_TROLL, CHR_VICIOUS_TROLL):
        world.thing(s, troll).flags &= ~F_PRESENT & 0xFF
    clearing = s.locations[LOC_TROLLS_CLEARING]
    clearing.description = 'MsgClearingWithTwoStone'
    clearing.flags &= ~LOC_VISITED & 0xFF
    for troll in (CHR_HIDEOUS_TROLL, CHR_VICIOUS_TROLL):
        yield from world.empty_holder(s, troll)
    s.vars.messages_visible = 1
    yield from text.print_message(s, 'MsgDayDawns')
    s.picture5 = PICTURE5_DAWN
    return None


@handler('LA94E')
def la94e(s):
    """Generator: a character with the player kills him: the command becomes
    "kill the player", refused, then L929C_0, and the game ends (stage 3: LA94E)."""
    from . import verbs
    v = s.vars
    if v.actor_location != v.player_location:
        return None
    if not world.commit_or_abort(s):
        return None
    v.command, v.first_object, v.second_object = CMD_KILL_PLAYER, PLAYER, NO_OBJECT
    yield from world.refuse_command(s)
    target = _target((yield from registry.call('L929C_0', s)))
    if target:
        return target
    return (yield from verbs.end_game(s))


@handler('LA9E5')
def la9e5(s):
    """Generator: Elrond's (the actor's) lunch: with the player, when the lunch
    is nowhere (place 0) or Elrond holds it, it is put in his hands and he gives
    it to the player (stage 3: LA9E5)."""
    v = s.vars
    if v.actor_location != v.player_location:
        return None
    lunch = world.thing(s, OBJ_LUNCH)
    if lunch.places[0] != 0 and lunch.holder != CHR_ELROND:
        return None
    if not world.commit_or_abort(s):
        return None
    lunch.places[0], lunch.holder = v.actor_location, CHR_ELROND
    v.first_object, v.second_object, v.command = OBJ_LUNCH, PLAYER, CMD_GIVE
    v.noun1, v.noun2 = ('thing', OBJ_LUNCH), ('thing', PLAYER)
    yield from world.refuse_command(s)
    return (yield from registry.call('GiveObject', s))


# ---- what the characters say ------------------------------------------------

@handler('NpcAnswersGift')
def npc_answers_gift(s):
    """Generator: given something, the character says "Thank you", or with a
    random 0-10 of 8 and more "What do you expect me to do with this ?" (stage
    3: NpcAnswersGift)."""
    if not world.commit_or_abort(s):
        return None
    n = yield from world.random_up_to(s, 10)
    yield from print_speech(s, 'MsgWhatDoExpectMeDo' if n >= 8 else 'MsgThank')
    return None


@handler('LA4F5')
def la4f5(s):
    """Generator: the character says "What's this ?" (stage 3: LA4F5)."""
    if not world.commit_or_abort(s):
        return None
    yield from print_speech(s, 'MsgWhatSThis')
    return None


@handler('LA51C')
def la51c(s):
    """Generator: the character says "This was Thrain's key" (stage 3: LA51C)."""
    if not world.commit_or_abort(s):
        return None
    yield from print_speech(s, 'MsgThisWasThrainsKey')
    return None


@handler('GandalfCheers')
def gandalf_cheers(s):
    """Generator: Gandalf says "You are doing a great job", "Hurry up" or
    "Hello" (a random 0-2) (stage 3: GandalfCheers)."""
    if not world.commit_or_abort(s):
        return None
    n = yield from world.random_up_to(s, 2)
    yield from print_speech(s, ('MsgDoingGreatJob', 'MsgHurryUp')[n] if n < 2 else 'MsgHello')
    return None


@handler('ElrondGreets')
def elrond_greets(s):
    """Generator: Elrond says "Hello" where the player is; elsewhere the script
    goes on to its alternative (stage 3: ElrondGreets)."""
    if s.vars.actor_location != s.vars.player_location:
        return None
    if not world.commit_or_abort(s):
        return None
    yield from print_speech(s, 'MsgHello')
    return None


@handler('WargHowls')
def warg_howls(s):
    """Generator: with the player, "The vicious warg run around you and howls."
    (stage 3: WargHowls)."""
    from . import engine
    if not world.commit_or_abort(s):
        return None
    if world.thing(s, CHR_VICIOUS_WARG).places[0] != _player(s).places[0]:
        return None
    yield from engine.print_message_dot(s, 'MsgViciousWargRunAround')
    return None


@handler('ThorinMissesThief')
def thorin_misses_thief(s):
    """Generator: Thorin with an invisible player says "Where's the thief ?"
    (stage 3: ThorinMissesThief)."""
    v = s.vars
    if v.actor_location != v.player_location or _player(s).flags & F_PRESENT:
        return None
    if not world.commit_or_abort(s):
        return None
    yield from print_speech(s, 'MsgWhereSThief')
    return None


@handler('ThorinTalks')
def thorin_talks(s):
    """Generator: by a random 0-8: 0 Thorin sits down and sings about gold, 1-2
    "Hurry up", 3-4 "Thorin waits", more nothing (stage 3: ThorinTalks). Quirk:
    "Get us out of this one, thief !" can never be said (its test follows one
    that took 3 and more away)."""
    from . import engine
    if not world.commit_or_abort(s):
        return None
    n = yield from world.random_up_to(s, 8)
    if n >= 5:
        return None
    if n >= 3:
        yield from engine.print_message_dot(s, 'MsgThorinWait')
    elif n == 0:
        yield from engine.print_message_dot(s, 'MsgThorinSitsDownStarts')
    else:
        yield from print_speech(s, 'MsgHurryUp')
    return None


@handler('TrollsTalk')
def trolls_talk(s):
    """Generator: in the trolls' clearing with the player, the hideous troll
    says "Blimey, look at this!! Can yer cook'em?", the other "Yer can try, but
    he wouldn't make above a mouthfull" (stage 3: TrollsTalk)."""
    if s.vars.player_location != LOC_TROLLS_CLEARING:
        return None
    if not world.commit_or_abort(s):
        return None
    yield from print_speech(s, 'MsgBlimeyLookAtThisCan' if s.vars.subject == CHR_HIDEOUS_TROLL
                            else 'MsgYerCanTryButHe')
    return None


@handler('GollumAsksRiddle')
def gollum_asks_riddle(s):
    """Generator: Gollum with a visible player asks the riddle of the game's
    random event and waits for the answer (reply_given 1) (stage 3:
    GollumAsksRiddle)."""
    if world.thing(s, CHR_GOLLUM).places[0] != s.vars.player_location:
        return None
    if not _player(s).flags & F_PRESENT:
        return None
    if not world.commit_or_abort(s):
        return None
    yield from print_speech(s, _data()[1]['random_events'][s.vars.random_event][1])
    s.vars.reply_given = 1
    return None


@handler('GollumTalks')
def gollum_talks(s):
    """Generator: Gollum with the player says "What has it got in its pockets
    ?" (a random -8..8 not below 0, or he holds the ring), else "My birthday
    present..." (stage 3: GollumTalks: the carry of RandomUpTo is the sign of
    RandomSigned)."""
    if world.thing(s, CHR_GOLLUM).places[0] != s.vars.player_location:
        return None
    if not world.commit_or_abort(s):
        return None
    n = yield from world.random_signed(s, 8)
    if not n & 0x80 or world.thing(s, OBJ_GOLDEN_RING).holder == CHR_GOLLUM:
        yield from print_speech(s, 'MsgWhatHasGotPockets')
    else:
        yield from print_speech(s, 'MsgMyBirthdayPresentHow')
    return None


def riddle_answered(words, answer):
    """Do the bytes of a stored order (its 12 words, low byte first) hold the
    riddle's answer (a phrase code, low byte then high byte)? CPIR finds the low
    byte, then the next byte must be the high one. Quirk: after a miss the
    search goes on for the high byte (A is not reloaded). Not reproduced: a
    match at the last byte compares the byte after the order and searches on
    through memory (taken as no answer)."""
    data = [b for w in words for b in (w & 0xFF, w >> 8)][:RIDDLE_ORDER_BYTES]
    a, i = answer & 0xFF, 0
    while a in data[i:]:
        i = data.index(a, i) + 1
        if i >= len(data):
            return False
        a = answer >> 8
        if data[i] == a:
            return True
    return False


@handler('LA8F6')
def la8f6(s):
    """Generator: Gollum takes the answer to his riddle (the subject's stored
    order, parser.run_stored_order without running it): the right one and
    nothing happens; a wrong one or none: "someone strangles you from behind",
    the end (stage 3: LA8F6). Not reproduced: no stored order (the asm reads
    the phrase stack then): no answer."""
    from . import parser, verbs
    v = s.vars
    if not world.commit_or_abort(s):
        return None
    v.reply_given = 0
    done, phrase = yield from parser.run_stored_order(s, False)
    if done and phrase is not None:
        answer = _data()[1]['random_events'][v.random_event][0]
        if riddle_answered(phrase.words, answer):
            return None
    if not world.commit_or_abort(s):
        return None
    v.messages_visible = 1
    yield from text.print_message(s, 'MsgSomeoneStranglesFrom')
    return (yield from verbs.end_game(s))


# ---- the map ---------------------------------------------------------------

@handler('ExamineMap')
def examine_map(s):
    """Generator: examine the curious map: anyone but Elrond as ExamineObject.
    Elrond reads it: the exit the game blocked at the start (s.vars.blocked_exit,
    tables.json blocked_exits) is put back while exit_restore_mode is 0, and he
    says "Go <direction> from <place> to get to <place>" (stage 3: ExamineMap)."""
    v = s.vars
    if v.subject != CHR_ELROND:
        return (yield from registry.call('ExamineObject', s))
    if not world.commit_or_abort(s):
        return None
    loc, (direction, obstacle, destination), index = _data()[1]['blocked_exits'][v.blocked_exit]
    if v.exit_restore_mode == 0:
        e = s.locations[loc].exits[index]
        e.direction, e.obstacle, e.destination = direction, obstacle, destination
    args = [s.locations[destination].names, s.locations[loc].names, world.id_word(direction)]
    yield from print_speech(s, 'MsgGoFromGet', args)
    return None


# ---- the arrivals (stage 3: world.py) ---------------------------------------

@handler('ArriveBeornsHouse')
def arrive_beorns_house(s):
    """Beorn's house: the butler wakes (his turn slot filled, present) unless he
    is dead (stage 3: ArriveBeornsHouse)."""
    butler = world.thing(s, CHR_BUTLER)
    if butler.flags & F_DEAD:
        return
    s.npcs[NPC_BUTLER].id = CHR_BUTLER
    butler.flags |= F_PRESENT


@handler('ArriveSpiderPlace')
def arrive_spider_place(s):
    """The spider place: timer 2 starts (stage 3: ArriveSpiderPlace)."""
    _start_timer(s, 2)


@handler('ArriveBog')
def arrive_bog(s):
    """The deep bog: timer 4 starts (stage 3: ArriveBog)."""
    _start_timer(s, 4)


@handler('ArriveCellar')
def arrive_cellar(s):
    """The elvenking's cellar: timer 9 counts 3; the dragon and the Bard wake
    unless dead (stage 3: ArriveCellar)."""
    s.timers[9].counter = 3
    if not world.thing(s, CHR_RED_GOLDEN_DRAGON).flags & F_DEAD:
        s.npcs[NPC_DRAGON].id = CHR_RED_GOLDEN_DRAGON
    if not world.thing(s, CHR_BARD).flags & F_DEAD:
        s.npcs[NPC_BARD].id = CHR_BARD


@handler('ArriveForest')
def arrive_forest(s):
    """The forest road and the forest: where the player came in is kept
    (arrival_location), timer 8 starts (stage 3: ArriveForest)."""
    s.vars.arrival_location = s.vars.take_id
    _start_timer(s, 8)


@handler('ArriveForestRiver')
def arrive_forest_river(s):
    """Generator: the forest river: unless in the barrel the player is swept
    away: the place is shown, then the end (stage 3: ArriveForestRiver)."""
    from . import verbs
    if _player(s).holder == OBJ_BARREL:
        return None
    target = _target((yield from verbs.actor_arrives_describe(s)))
    if target:
        return target
    return (yield from _end_game(s, 'MsgSweptForcefully'))
