"""The verbs: look, take, drop, move and arrive, run, follow, look through,
inventory, open and close, lock and unlock, attack, shoot, throw, put, give,
strike, examine, talk, eat, empty, the river, and the end of a game (stage 3:
verbs.py; src/verbs.asm, docs/05-characters.md).

The handlers the tables name (verb tables, VerbHandlers, NPC script routines)
register under their stage 3 names and take (s): their inputs are s.vars
(command, first_object, second_object, noun1, noun2, subject, actor). They are
generators and return a flow target ('RestartGame') when the game ends, None
otherwise. The stage 3 routines that drop their caller's return address
(RequireHeld, CheckCanCarry, CheckCanCarry_Single, CheckAttackAllowed) return
False here: the caller returns at once.

The other wave B modules (engine, handlers, parser, system) are imported where
they are called (they import this one)."""
import functools

from . import assets, registry, terminal, text, words, world
from .state import AT_LOCATION, WaitKey
from .world import (F_ACTIVE, F_CHARACTER, F_DEAD, F_LIQUID, NO_OBJECT, PLAYER, refuse_command,
                    thing)

F_LOCKED, F_FULL = 0x01, 0x04           # thing flag bits 0 (locked) and 2 (full: food, wine)
LOC_LIT, LOC_VISITED = 0x80, 0x40
STATE_PLAYER_BLOCKED, STATE_UNFRIENDLY, STATE_SIDE_BITS = 0x80, 0x10, 0x70   # Thing.state
DIR_NORTH, DIR_DOWN = 1, 10
PASS_OK, PASS_BLOCKED, PASS_TOO_SMALL, PASS_TOO_FULL = 0, 1, 2, 3
ROLL_SPREAD, STRIKE_SPREAD, KILL_MARGIN = 10, 0x15, 16
GLUTTONY = 0x80                         # a strength this high after a meal kills
PHRASE_FIST = 0x026B                    # the weapon's name in a bare-handed fight
CMD_STRIKE, CMD_ATTACK, CMD_PUT_ON, CMD_THROW = 0x0B, 0x0F, 0x12, 0x2A
REASON_UNLOCKED, REASON_EMPTY, REASON_CLOSED, REASON_DEAD = 0x00, 0x02, 0x05, 0x06
REASON_FULL, REASON_BROKEN = 0x82, 0x83
OBJ_ROPE, OBJ_SWORD = 0x12, 0x0E
OBJ_WATER, OBJ_BLACK_WATER, WORD_WATER, WORD_BLACK_WATER = 0x15, 0x16, 0x17, 0x18
OBJ_BOW, OBJ_STRONG_ARROW, CHR_DRAGON, CHR_BARD = 0x19, 0x1A, 0x3C, 0x46
LOC_BAG_END = 1                         # the tunnel-like hall


@functools.lru_cache(None)
def _tables():
    """verbs.json (the wound messages by damage 0-16, the handlers a stale write
    makes of a timer's fire handler) and tables.json's first-visit scores and
    arrival handlers (by location id). The wound message for damage 16 lies
    past the original's table (F56): the ROM's bytes read as a message, which
    prints a "word" from the middle of a dictionary entry; verbs.json holds
    both, and they are added to the messages and the words here."""
    t = assets.load_json('verbs.json')
    if len(t['wound_messages']) != KILL_MARGIN + 1:
        raise ValueError('verbs.json: %d wound messages, damage 0-16 needs 17' % len(t['wound_messages']))
    for offset, letters, ending in t['extra_words']:
        if offset in words.WORDS or not letters.isalpha():
            raise ValueError('verbs.json: extra word %r at %d' % (letters, offset))
        words.WORDS[offset] = words.Word(offset, letters, 0, ending, None, False)
    for name, items in t['extra_messages'].items():
        items = [tuple(it) for it in items]
        if name in text.MESSAGES or [it[0] for it in items if it[0] not in ('word', 'text')] != ['end'] \
                or items[-1][0] != 'end' or any(it[1] not in words.WORDS for it in items if it[0] == 'word'):
            raise ValueError('verbs.json: extra message %s: words and text, then an end' % name)
        text.MESSAGES[name] = items
    for name in t['wound_messages']:
        if name not in text.MESSAGES:
            raise ValueError('verbs.json: wound message %s is not a message' % name)
    t['retargets'] = {int(k): {int(loc): n for loc, n in v.items()} for k, v in t['fire_retargets'].items()}
    tables = assets.load_json('tables.json')
    t['first_visit'] = dict(tables['first_visit_scores'])
    t['arrivals'] = dict(tables['arrival_handlers'])
    return t


def _noun(s, noun):
    """The Thing of a noun record (Noun1Record, Noun2Record): ('thing', id)."""
    if not noun or noun[0] != 'thing':
        raise ValueError('the noun record %r is not a thing' % (noun,))
    return thing(s, noun[1])


def _ror(a):
    """RRCA."""
    return (a >> 1 | (a & 1) << 7) & 0xFF


def _sra(a):
    """SRA: halve keeping the sign bit."""
    return a >> 1 | a & 0x80


# ---- look, drop, take -----------------------------------------------------

@registry.handler('VerbLook')
def verb_look(s):
    """Look: at a location, describe it with its picture; inside a holder (a
    barrel, the boat), "You are in the barrel." and what the holder holds there
    (stage 3: VerbLook)."""
    if not world.commit_or_abort(s):
        return None
    actor = thing(s, s.vars.actor)
    if actor.holder == AT_LOCATION:
        from . import engine
        return (yield from engine.describe_location(s, actor.places[0]))
    s.vars.subj_is_in = 0               # the message's preposition slot blanked ($80,$00)
    yield from text.print_message(s, 'MsgSubjIsIn')
    holder = thing(s, actor.holder)
    yield from world.print_holder_relation(s, holder.id)
    yield from text.print_word(s, holder.names[0] & 0x0FFF, 0)
    yield from terminal.put_char(s, ord('.'))
    yield from terminal.new_line(s)
    yield from text.print_message(s, 'MsgSee2')
    yield from world.list_objects(s, actor.holder, actor.places[0])
    return None


def require_held(s):
    """Generator: is the first object held by the subject? Otherwise "You are
    not carrying it." and False: the caller returns at once (stage 3:
    RequireHeld)."""
    if world.first_object_held(s):
        return True
    yield from text.print_message(s, 'MsgNotCarrying')
    return False


@registry.handler('VerbDrop')
def verb_drop(s):
    """Drop the first object (a thing tied to the rope drops the rope): it goes
    to the actor's holder; a liquid evaporates (stage 3: VerbDrop)."""
    if not (yield from require_held(s)) or not world.commit_or_abort(s):
        return None
    t = _noun(s, s.vars.noun1)
    if t.holder == OBJ_ROPE:
        t = thing(s, OBJ_ROPE)
    t.holder = thing(s, s.vars.actor).holder
    if t.flags & F_LIQUID:
        t.places[0] = 0
        yield from text.print_message(s, 'MsgEvaporates', [t.names])
    return None


def _held_z(s, id, holder):
    """CheckObject1Held_0's Z flag (not its carry, the answer): set when thing
    `id` is NO_OBJECT or `holder` is up its chain of holders, and also when the
    chain ends at a location with the player (the AND of the last id looked at:
    a quirk)."""
    if id == NO_OBJECT:
        return True
    while True:
        t = thing(s, id)
        if t.holder == AT_LOCATION:
            return t.id == PLAYER
        if t.holder == holder:
            return True
        id = t.holder


@registry.handler('L8CE0')
def take_out_of(s):
    """Take the first object out of the second: "<it> is not in <that>." unless
    it is there, else as take. Quirk: the test is the Z flag of the holder walk,
    also set when the chain ends with the player (stage 3: L8CE0)."""
    if not _held_z(s, s.vars.first_object, s.vars.second_object):
        yield from text.print_message(s, 'MsgNot')
        return None
    return (yield from verb_take_0(s))


def check_can_carry(s):
    """Generator: can the subject lift and carry the first object? Its bulk
    with what is inside (at most 255) against the actor's size, then what is
    left after the subject's load (the sign of the byte decides, not the
    borrow), then check_can_carry_single. False after the message: the caller
    returns at once (stage 3: CheckCanCarry)."""
    v = s.vars
    t = _noun(s, v.noun1)
    bulk = min(world.held_bulk(s, v.first_object) + t.size, 0xFF)
    room = thing(s, v.actor).size
    message = 'MsgTooHeavyLift'
    if bulk <= room:
        if not (room - bulk - world.held_bulk(s, v.subject)) & 0x80:     # JP P
            return (yield from check_can_carry_single(s))
        message = 'MsgCarryingTooMuch'
    yield from text.print_message(s, message)
    return False


def check_can_carry_single(s):
    """Generator: the first object must have one place and not be a liquid,
    else the command is refused and False: the caller returns at once (stage 3:
    CheckCanCarry_Single)."""
    t = _noun(s, s.vars.noun1)
    if len(t.places) == 1 and not t.flags & F_LIQUID:
        return True
    yield from refuse_command(s)
    return False


@registry.handler('VerbTake')
def verb_take(s):
    """Take or carry: "You are already carrying it." when held, else take it
    (stage 3: VerbTake)."""
    if world.first_object_held(s):
        yield from text.print_message(s, 'MsgAlreadyCarrying')
        return None
    return (yield from verb_take_0(s))


def verb_take_0(s):
    """Generator: the subject takes the first object if it can carry it;
    refused when the subject is in or on it; it (or the rope it is tied to)
    becomes the subject's (stage 3: VerbTake_0)."""
    v = s.vars
    if not (yield from check_can_carry(s)):
        return None
    id = v.subject
    while True:                         # up the subject's holders
        t = thing(s, id)
        if t.holder == v.first_object:
            return (yield from refuse_command(s))
        if t.holder == AT_LOCATION:
            break
        id = t.holder
    if not world.commit_or_abort(s):
        return None
    t = _noun(s, v.noun1)
    (thing(s, OBJ_ROPE) if t.holder == OBJ_ROPE else t).holder = v.subject
    return None


# ---- moving ---------------------------------------------------------------

@registry.handler('VerbMove')
def verb_move(s):
    """Go in direction s.vars.command; in the dark the direction is random,
    1-10 (stage 3: VerbMove)."""
    from . import engine
    if engine.check_dark(s):
        s.vars.command = (yield from world.random_up_to(s, DIR_DOWN - 1)) + 1
    return (yield from move_actor(s))


def move_actor(s):
    """Generator: move the actor through the exit of direction s.vars.command:
    held by a thing that is not a character it cannot walk (a character lets
    it go); take_weight is its weight and load; no exit is a refusal; the
    obstacle and the room at the destination are tested (check_passage).
    Returns a flow target when the game ends (stage 3: MoveActor)."""
    v = s.vars
    actor = thing(s, v.actor)
    if actor.holder != AT_LOCATION:
        if not thing(s, actor.holder).flags & F_CHARACTER:
            return (yield from move_actor_no_way(s))
        actor.holder = AT_LOCATION
    v.take_weight = world.held_weight(s, v.subject) + actor.weight & 0xFF
    e = world.exit_by_direction(s, v.command)
    if e is None or not e.destination:
        return (yield from move_actor_no_way(s))
    v.take_id = e.destination
    passage = check_passage(s, e.obstacle)
    if passage == PASS_BLOCKED:
        return (yield from move_actor_no_way(s))
    if passage == PASS_TOO_SMALL:
        # BUG kept: the word is the obstacle's weight and size bytes, not a name
        o = thing(s, e.obstacle)
        yield from text.print_message(s, 'MsgTooSmallForEnter', [o.weight | o.size << 8])
        return None
    if passage == PASS_TOO_FULL:
        names = s.locations[v.take_destination].names
        yield from text.print_message(s, 'MsgTooFullForEnter', [names[0]])
        return None
    return (yield from actor_arrives(s, v.actor, v.take_id))


def move_actor_no_way(s):
    """Generator: no way: "You cannot go north."; but in the dark the player
    blunders into a wall: its strength is halved, "But fall and hit your
    head.", and at 0 "But fall and smash your skull." and the game ends
    (stage 3: MoveActor_NoWay)."""
    from . import engine
    if not engine.check_dark(s):
        return (yield from refuse_command(s))
    if not world.commit_or_abort(s):
        return None
    player = thing(s, PLAYER)
    player.strength >>= 1
    if player.strength:
        yield from text.print_message(s, 'MsgButFallHitHead')
        return None
    yield from text.print_message(s, 'MsgButFallSmashSkull')
    return (yield from end_game(s))


def _set_place(s, actor, loc):
    """ActorArrives' LD (IY+$10),B: the first place of thing `actor` becomes
    `loc`. F85 kept: IY is whatever its caller left, so `actor` may be another
    thing than the one moving (the recipient of GIVE, the door of L9404_8), or
    ('timer', k) when a timer's handler moved the player: then the byte written
    is the low byte of timer k + 2's fire handler, which becomes the stage 3
    routine at that address (timer 0's barrel at $22: timer 2's fire handler
    becomes SpiderEyesFromHL)."""
    if isinstance(actor, int):
        thing(s, actor).places[0] = loc
        return
    if actor is not None and actor[0] == 'timer' and actor[1] + 2 in _tables()['retargets']:
        k = actor[1] + 2
        name = _tables()['retargets'][k].get(loc)
        if name is None:
            raise ValueError('F85: no routine starts where timer %d\'s fire handler goes with '
                             'location %d' % (k, loc))
        s.timers[k].fire = name
        return
    raise ValueError('F85: ActorArrives with IY %r is not reproduced' % (actor,))


def actor_arrives(s, actor, loc):
    """Generator: the actor arrives at `loc` when really performing: its place
    is set (`actor`: the thing the asm's IY points at, see _set_place), what
    the subject carries comes along; for the player the arrival handler of
    s.vars.take_id runs, then the place is described. Returns a flow target
    when the game ends (stage 3: ActorArrives)."""
    v = s.vars
    if not world.commit_or_abort(s):
        return None
    _set_place(s, actor, loc)
    target = yield from world.move_carried(s, v.subject, loc, actor)
    if target or v.subject != PLAYER:
        return target
    handler = _tables()['arrivals'].get(v.take_id)
    if handler:
        target = yield from world.call_handler(s, handler)
        if target:
            return target
    return (yield from actor_arrives_describe(s))


def actor_arrives_describe(s):
    """Generator: describe the destination s.vars.take_id unless it is dark:
    the first time with its picture (the location take_destination is marked
    visited and its first-visit score is added), after that the short way.
    Quirk: the visited mark is read and set on take_destination, which
    check_passage set: after a carried move it is the last walk's destination
    (stage 3: ActorArrives_0)."""
    from . import engine
    v = s.vars
    if engine.check_dark(s):
        return None
    if v.subject:                       # never: here the subject is the player
        return (yield from engine.describe_location(s, v.take_id))
    # TakeObject 0 (no walk yet) reads the ROM's first byte, $F3: bit 6 set
    if v.take_destination is None or s.locations[v.take_destination].flags & LOC_VISITED:
        return (yield from engine.describe_location_short(s, v.take_id))
    s.locations[v.take_destination].flags |= LOC_VISITED
    v.score = v.score + _tables()['first_visit'].get(v.take_id, 0) & 0xFFFF
    return (yield from engine.describe_location(s, v.take_id))


def check_passage(s, obstacle):
    """Can the subject pass `obstacle` (a thing id, 0 none) and enter location
    s.vars.take_id with its weight s.vars.take_weight? An obstacle neither open
    nor broken blocks (PASS_BLOCKED), as does state bit 7 for the player; a
    weight not below its weight is PASS_TOO_SMALL. Then take_destination
    becomes take_id, and unless its capacity is $FF the weight must be below
    the room left (PASS_TOO_FULL). PASS_OK (0) when it can pass (stage 3:
    CheckPassage)."""
    v = s.vars
    if obstacle:
        o = thing(s, obstacle)
        if not o.flags & (F_ACTIVE | F_DEAD):
            return PASS_BLOCKED
        if v.subject == PLAYER and o.state & STATE_PLAYER_BLOCKED:
            return PASS_BLOCKED
        if v.take_weight >= o.weight:
            return PASS_TOO_SMALL
    v.take_destination = v.take_id
    if s.locations[v.take_id].capacity != 0xFF and \
            v.take_weight >= world.spare_capacity(s, v.take_id):
        return PASS_TOO_FULL
    return PASS_OK


def check_enclosed(s, id):
    """Is thing `id` shut in: a holder up its chain that is not open (flag bit
    5)? (stage 3: CheckEnclosed, NZ)"""
    t = thing(s, id)
    while t.holder != AT_LOCATION:
        t = thing(s, t.holder)
        if not t.flags & F_ACTIVE:
            return True
    return False


@registry.handler('VerbLookThrough')
def verb_look_through(s):
    """Look through the first object (a door, a window): "<it> is closed." when
    it is not open, else the place beyond (stage 3: VerbLookThrough)."""
    from . import handlers
    if not handlers.check_open(s, s.vars.first_object):
        return (yield from world.print_state(s, s.vars.first_object, REASON_CLOSED))
    return (yield from verb_look_through_0(s))


@registry.handler('VerbLookThrough_0')
def verb_look_through_0(s):
    """Describe the place beyond the exit whose obstacle is the first object
    ("You see ..."), the actor put there for the while. Nothing when the
    subject is shut in. BUG kept: the dark test reads location 1 (Bag End,
    the perform flag left in A), not the place beyond, so it never fails
    (stage 3: VerbLookThrough_0)."""
    from . import engine
    v = s.vars
    if check_enclosed(s, v.subject):
        return None
    e = world.exit_by_obstacle(s, v.first_object)
    if e is None or not e.destination:
        return (yield from refuse_command(s))
    if not world.commit_or_abort(s):
        return None
    if not s.locations[LOC_BAG_END].flags & LOC_LIT:
        yield from text.print_message(s, 'MsgDark')
        return None
    actor = thing(s, v.actor)
    real = actor.places[0]
    actor.places[0] = e.destination
    yield from engine.describe_seen(s, e.destination)
    actor.places[0] = real
    return None


@registry.handler('L8F3B')
def go_through(s):
    """Go through the first object: the exit it blocks (stage 3: L8F3B)."""
    return (yield from walk_to_exit(s, world.exit_by_obstacle(s, s.vars.first_object)))


def walk_to_exit(s, e):
    """Generator: walk through exit `e` (None: none): refused without an exit, a
    destination or a passage (check_passage, which reads take_id and
    take_weight as the last move left them: kept); else the exit's direction
    becomes the command, the first object none, and the actor moves (stage 3:
    WalkToExit)."""
    v = s.vars
    if e is None or not e.destination or check_passage(s, e.obstacle) != PASS_OK:
        return (yield from refuse_command(s))
    if not world.commit_or_abort(s):
        return None
    v.command = e.direction
    v.first_object = NO_OBJECT
    return (yield from move_actor(s))


def _water(s, id):
    """The water (or black water) becomes the second object, held by nobody."""
    s.vars.second_object = id
    s.vars.noun2 = ('thing', id)
    thing(s, id).holder = AT_LOCATION


@registry.handler('L8F69')
def put_into(s):
    """Put the first object into the second: the water words make the second
    object the water or the black water; the container must hold liquids (flag
    bit 1); a full first object is "full"; then put_object_in with the nouns
    swapped (stage 3: L8F69)."""
    v = s.vars
    t = _noun(s, v.noun1)
    if v.second_object == WORD_WATER:
        _water(s, OBJ_WATER)
    elif v.second_object == WORD_BLACK_WATER:
        _water(s, OBJ_BLACK_WATER)
    if not _noun(s, v.noun2).flags & F_LIQUID:
        return (yield from refuse_command(s))
    if t.flags & F_FULL:
        return (yield from world.print_state(s, t.id, REASON_FULL))
    return (yield from world.call_swapped(s, 'PutObjectIn'))


@registry.handler('VerbRun')
def verb_run(s):
    """Run: a random start direction 1-10, then that one and the next (after
    up back to north) until one has an exit; then go that way. A place with no
    exit 1-9 loops for ever unless 10 is rolled, as in the original (stage 3:
    VerbRun)."""
    while True:
        d = yield from world.random_up_to(s, DIR_DOWN)
        if d:
            break
    while world.exit_by_direction(s, d) is None:
        d += 1
        if d >= DIR_DOWN:
            d = DIR_NORTH
    s.vars.command = d
    return (yield from verb_move(s))


@registry.handler('L8FCD')
def enter(s):
    """Enter, go into: walk to the exit that leads to the first object (stage
    3: L8FCD)."""
    return (yield from walk_to_exit(s, world.exit_by_destination(s, s.vars.first_object)))


@registry.handler('VerbFollow')
def verb_follow(s):
    """Follow the first object: through the exit to where it is; "I cannot
    follow it from here." when it is here or no exit leads there (stage 3:
    VerbFollow)."""
    there = _noun(s, s.vars.noun1).places[0]
    if there != thing(s, s.vars.actor).places[0]:
        e = world.exit_by_destination(s, there)
        if e is not None:
            return (yield from walk_to_exit(s, e))
    yield from text.print_message(s, 'MsgICannotFollowFromHere')
    return None


# ---- throw, talk, open and close -------------------------------------------

@registry.handler('L8FF5')
def throw_at(s):
    """Throw the first object at the second: the subject must be able to carry
    it; a character is attacked (VerbAttack), anything else struck
    (StrikeObject), with the nouns swapped. When performed the object ends held
    by nobody and its character is told, with the target's id as the behaviour
    (B left by L9F4A: kept) (stage 3: L8FF5)."""
    v = s.vars
    if not (yield from check_can_carry(s)):
        return None
    if _noun(s, v.noun2).flags & F_CHARACTER:
        name, v.command = 'VerbAttack', CMD_ATTACK
    else:
        name, v.command = 'StrikeObject', CMD_STRIKE
    target = yield from world.call_swapped(s, name)
    if target:
        return target
    v.command = CMD_THROW
    if v.action_perform != 1:
        return None
    _noun(s, v.noun1).holder = AT_LOCATION
    v.command = CMD_ATTACK
    from . import engine
    yield from engine.notify_character(s, v.first_object, v.second_object)
    return None


@registry.handler('TalkToCharacter')
def talk_to_character(s):
    """Talk to the first object: how many stored orders it takes (none without
    an NPC record; its reply after it has spoken; else 0 to its obedience at
    random, 0 being "<it> says "No""), then they are handed over (stage 3:
    TalkToCharacter)."""
    from . import engine, parser
    v = s.vars
    if not world.commit_or_abort(s):
        return None
    k = engine.find_npc(s, v.first_object)
    n = 0
    if k is not None:
        n = v.reply_given
        if not n and s.npcs[k].obedience:
            n = yield from world.random_up_to(s, s.npcs[k].obedience)
            if not n:
                yield from text.print_message(s, 'MsgSaysNo')
    parser.claim_order_slots(s, n)
    return None


@registry.handler('L9065')
def open_or_close(s):
    """Open the first object when it is closed, else close it (stage 3: L9065)."""
    if not world.commit_or_abort(s):
        return None
    t = _noun(s, s.vars.noun1)
    if not t.flags & F_ACTIVE:
        return (yield from open_thing(s, t.id))
    close_thing(s, t.id)
    return None


@registry.handler('OpenObject')
def open_object(s):
    """Open the first object: why it cannot be ("<it> is locked/open.") or open
    it (stage 3: OpenObject)."""
    from . import handlers
    refused, reason = handlers.check_openable(s)
    t = _noun(s, s.vars.noun1)
    if refused:
        return (yield from world.print_state(s, t.id, reason))
    if not world.commit_or_abort(s):
        return None
    return (yield from open_thing(s, t.id))


def open_thing(s, id):
    """Generator: thing `id` is opened; one with a single place that holds
    something shows it: the header and the list of what the first object holds
    (stage 3: OpenObject_0)."""
    v = s.vars
    t = thing(s, id)
    t.flags |= F_ACTIVE
    if len(t.places) != 1 or not world.count_held_present(s, v.first_object):
        return None
    if (yield from world.print_contents_header(s, v.first_object)):
        yield from world.list_objects(s, v.first_object, t.places[0])
    return None


@registry.handler('CloseObject')
def close_object(s):
    """Close the first object: "<it> is closed." when it is not open (stage 3:
    CloseObject)."""
    from . import handlers
    t = _noun(s, s.vars.noun1)
    if not handlers.check_open(s, t.id):
        return (yield from world.print_state(s, t.id, REASON_CLOSED))
    if not world.commit_or_abort(s):
        return None
    close_thing(s, t.id)
    return None


def close_thing(s, id):
    """Thing `id` is closed: its open flag cleared (stage 3: CloseObject_Clear)."""
    thing(s, id).flags &= ~F_ACTIVE & 0xFF


# ---- fights -----------------------------------------------------------------

def check_attack_allowed(s):
    """May the actor attack the first object? Not when they share a side
    (state bits 4-6); the player first clears the victim's bit 4. When refused
    action_allowed is 0 and False: the caller returns at once (stage 3:
    CheckAttackAllowed)."""
    v = s.vars
    victim = _noun(s, v.noun1)
    if v.subject == PLAYER:
        victim.state &= ~STATE_UNFRIENDLY & 0xFF
    if not victim.state & STATE_SIDE_BITS & thing(s, v.actor).state:
        return True
    v.action_allowed = 0
    return False


def roll_strength(s, strength):
    """Generator: a strength rolled: `strength` plus a random spread of -10 to
    10. BUG kept (F9): past 255 it is 0 for a negative spread (any that does
    not wrap below 0) and 255 for a positive one; strength 0 with a negative
    spread wraps to 246-255 (stage 3: RollStrength)."""
    spread = yield from world.random_signed(s, ROLL_SPREAD)
    a = strength + spread
    if a > 0xFF:
        return 0 if spread & 0x80 else 0xFF
    return a


@registry.handler('VerbAttack')
def verb_attack(s):
    """Attack the first object with the second (bare-handed: the "fist"). The
    actor's strength plus the weapon's (at most 255) is rolled against the
    victim's rolled defence: no more, "But the effort is wasted"; more than 16
    over, a killing blow; else wound message d (the difference) and the
    victim's strength and defence reduced. Quirks kept: damage 16 reads past
    the wound messages (F56: the ROM's bytes as a message); an odd damage
    gives a reduction of 128 or more, so the strength almost never drops; the
    attack is rolled before the test pass ends (stage 3: VerbAttack)."""
    from . import engine
    v = s.vars
    if not check_attack_allowed(s):
        return None
    v.weapon_name = PHRASE_FIST if v.second_object == NO_OBJECT else _noun(s, v.noun2).names[0]
    attack = thing(s, v.actor).strength
    if v.second_object != NO_OBJECT:
        weapon = _noun(s, v.noun2)
        if len(weapon.places) != 1:
            yield from text.print_message(s, 'MsgCannotKillWith')
            return None
        attack = min(weapon.strength + attack, 0xFF)
    attack = yield from roll_strength(s, attack)
    if not world.commit_or_abort(s):
        return None
    victim = _noun(s, v.noun1)
    defence = yield from roll_strength(s, victim.defence)
    if defence >= attack:
        yield from text.print_message(s, 'MsgButEffortWasted')
        return None
    if min(defence + KILL_MARGIN, 0xFF) < attack:
        yield from text.print_message(s, 'MsgWithOneWellPlacedBlow')
        victim.flags |= F_DEAD
        target = yield from engine.kill_character(s, v.first_object)
        if target:
            return target
        return (yield from world.print_state(s, victim.id, REASON_DEAD))
    damage = attack - defence
    message = _tables()['wound_messages'][damage]
    x = _ror(_ror(damage << 1))         # 2d rotated right twice
    if victim.strength > x:
        victim.strength -= x + 1
    y = _ror(x)
    if victim.defence > y:
        victim.defence -= y + 1
    yield from text.print_message(s, message)
    return None


@registry.handler('L9065_0')
def shoot(s):
    """Shoot the first object with the bow: it must be held; the arrow misses
    the dragon, and anything 3 times in 9 at random, unless Bard shoots; a hit
    leaves the strong arrow held by nobody (unless it is the target); a living
    character is killed, anything else struck (stage 3: L9065_0)."""
    from . import engine
    v = s.vars
    if not world.held_by_subject(s, OBJ_BOW):
        yield from text.print_message(s, 'MsgNotCarryingBow')
        return None
    if not check_attack_allowed(s) or not world.commit_or_abort(s):
        return None
    v.command = CMD_ATTACK
    if v.subject != CHR_BARD:
        if v.first_object == CHR_DRAGON or (yield from world.random_up_to(s, 8)) < 3:
            yield from text.print_message(s, 'MsgArrowMissesByWide')
            return None
    if v.first_object != OBJ_STRONG_ARROW:
        thing(s, OBJ_STRONG_ARROW).holder = AT_LOCATION
    yield from text.print_message(s, 'MsgArrowHits')
    victim = _noun(s, v.noun1)
    if not world.living(s, victim.id):
        return (yield from strike_object(s))
    target = yield from engine.kill_character(s, v.first_object)
    if target:
        return target
    return (yield from world.print_state(s, victim.id, REASON_DEAD))


@registry.handler('StrikeObject')
def strike_object(s):
    """Strike the first object, perhaps with a weapon (the second). Refused for
    a liquid, a defence of 0, a weapon of strength 0 or one that cannot strike;
    "<it> is broken." when it is. A random spread (its carry lost) plus the
    weapon's and the subject's strength (at most 255) at least its defence
    breaks it ("broken", strength halved, contents spilled when its state is
    below 2); then the weapon's defence is tried against it the same way.
    Quirks kept: the weapon breaking spills the first object again (F46)
    (stage 3: StrikeObject)."""
    v = s.vars
    t = _noun(s, v.noun1)
    if t.flags & F_LIQUID:
        return (yield from refuse_command(s))
    if t.flags & F_DEAD:
        return (yield from world.print_state(s, t.id, REASON_BROKEN))
    if not t.defence:
        return (yield from refuse_command(s))
    attack = 0
    if v.second_object != NO_OBJECT:
        weapon = _noun(s, v.noun2)
        if not weapon.strength or world.verb_entry(s, weapon.id, CMD_STRIKE) is None:
            return (yield from refuse_command(s))
        attack = weapon.strength
    if not world.commit_or_abort(s):
        return None
    a = (yield from world.random_signed(s, STRIKE_SPREAD)) + attack & 0xFF
    a = min(a + thing(s, v.actor).strength, 0xFF)
    if a >= t.defence:                  # the object breaks
        t.flags |= F_DEAD
        world.mark_broken_or_dead(s, v.first_object)
        t.strength = _sra(t.strength)
        if t.state < 2:
            yield from world.empty_holder(s, v.first_object)
        yield from world.print_state(s, t.id, REASON_BROKEN)
    if v.second_object == NO_OBJECT:
        return None
    weapon = _noun(s, v.noun2)
    if weapon.flags & F_DEAD:
        return None
    a = min((yield from world.random_signed(s, STRIKE_SPREAD)) + weapon.defence, 0xFF)
    if a < t.defence:
        return None                     # the weapon holds
    weapon.flags |= F_DEAD
    world.mark_broken_or_dead(s, v.second_object)
    weapon.strength = _sra(weapon.strength)
    yield from world.empty_holder(s, v.first_object)
    return (yield from world.print_state(s, weapon.id, REASON_BROKEN))


# ---- put, give, examine, eat, empty --------------------------------------------

@registry.handler('PutObjectIn')
def put_object_in(s):
    """Put the first object into (or onto) the second: refused for several
    places or a liquid; "I cannot do that." when it is there already; the
    container must be open (not for PUT ON) and have room: its weight less the
    object's and its load must stay above 0. Then it is held there (stage 3:
    PutObjectIn)."""
    v = s.vars
    if not (yield from check_can_carry_single(s)):
        return None
    t = _noun(s, v.noun1)
    if v.second_object == t.holder:
        return (yield from text.print_cannot_do_that(s))
    c = _noun(s, v.noun2)
    if v.command != CMD_PUT_ON and not c.flags & F_ACTIVE:
        return (yield from world.print_state(s, c.id, REASON_CLOSED))
    left = c.weight - t.weight
    if left > 0:
        left -= world.held_weight(s, v.second_object)
    if left <= 0:                       # an exact fit is too full
        yield from text.print_message(s, 'MsgTooFull')
        return None
    if not world.commit_or_abort(s):
        return None
    t.places[0] = c.places[0]
    t.holder = v.second_object
    return None


@registry.handler('GiveObject')
def give_object(s):
    """Give the first object to the second: the subject must hold it and the
    recipient's size cover its load and the object's bulk (the sum wraps at
    256); then the recipient holds it where it is (stage 3: GiveObject)."""
    v = s.vars
    if not world.first_object_held(s):
        yield from text.print_message(s, 'MsgNotCarrying')
        return None
    recipient = _noun(s, v.noun2)
    t = _noun(s, v.noun1)
    if recipient.size < world.held_bulk(s, v.second_object) + t.size & 0xFF:
        yield from text.print_message(s, 'MsgCarryingTooMuch')
        return None
    if not world.commit_or_abort(s):
        return None
    t.holder = v.second_object
    t.places[0] = recipient.places[0]
    # IY is the recipient: an arrival of the player writes its place (F85)
    return (yield from world.move_carried(s, v.first_object, recipient.places[0], recipient.id))


@registry.handler('ExamineObject')
def examine_object(s):
    """Examine the first object: its description, else "You see <it>." (stage
    3: ExamineObject)."""
    if not world.commit_or_abort(s):
        return None
    t = thing(s, s.vars.first_object)
    if t.description:
        yield from text.print_message(s, t.description)
        return None
    yield from text.print_message(s, 'MsgSee')
    yield from world.print_object_name(s, t.id)
    yield from terminal.put_char(s, ord('.'))
    yield from terminal.new_line(s)
    return None


@registry.handler('L929C')
def eat(s):
    """Eat or drink the first object: from inside a holder (the holder is no
    longer full) it is worth 1, else 10 (stage 3: L929C)."""
    if not world.commit_or_abort(s):
        return None
    t = _noun(s, s.vars.noun1)
    if t.holder == AT_LOCATION:
        return (yield from eat_lying(s))
    thing(s, t.holder).flags &= ~F_FULL & 0xFF
    return (yield from eat_meal(s, 1))


@registry.handler('L929C_0')
def eat_lying(s):
    """Eat a thing that lies about: worth 10 (stage 3: L929C_0)."""
    if not world.commit_or_abort(s):
        return None
    return (yield from eat_meal(s, 10))


def eat_meal(s, worth):
    """The actor's strength grows by `worth` (a byte: it wraps); at $80 or
    more "Foul gluttony has killed" the subject. Else the meal is held by
    nobody, all its places location 0 (stage 3: L929C_1)."""
    from . import engine
    actor = thing(s, s.vars.actor)
    strength = worth + actor.strength & 0xFF
    if strength >= GLUTTONY:
        yield from text.print_message(s, 'MsgFoulGluttonyHasKilled')
        return (yield from engine.kill_character(s, s.vars.subject))
    actor.strength = strength
    t = _noun(s, s.vars.noun1)
    t.holder = AT_LOCATION
    t.places[:] = [0] * len(t.places)   # (no thing has 0 places: the asm would clear 256)
    return None


@registry.handler('L9404')
def empty(s):
    """Empty the first object: it must be open and hold something present
    ("<it> is empty."); its contents spill and it is no longer full (stage 3:
    L9404)."""
    from . import handlers
    v = s.vars
    t = _noun(s, v.noun1)
    if not handlers.check_open(s, t.id):
        return (yield from world.print_state(s, t.id, REASON_CLOSED))
    if not world.count_held_present(s, v.first_object):
        return (yield from world.print_state(s, t.id, REASON_EMPTY))
    if not world.commit_or_abort(s):
        return None
    yield from world.empty_holder(s, v.first_object)
    t.flags &= ~F_FULL & 0xFF
    return None


@registry.handler('L9404_1')
def send_down_river(s):
    """Put the first object in the river (the second): among the river's
    places it goes from the actor's to the next (0 after the last), "and it
    gets swept away", and what it carries comes along; the game ends when the
    player went to location 0. Not reproduced: the asm's IY there is whatever
    the dispatcher left, so a player carried along stops the game with an
    error (F85) (stage 3: L9404_1)."""
    v = s.vars
    if not (yield from check_can_carry_single(s)) or not world.commit_or_abort(s):
        return None
    places = _noun(s, v.noun2).places
    if v.actor_location not in places:
        return (yield from text.print_cannot_do_that(s))
    i = places.index(v.actor_location)
    place = places[i + 1] if i + 1 < len(places) else 0
    yield from text.print_message(s, 'MsgGetsSweptAway')
    t = _noun(s, v.noun1)
    t.places[0], t.holder = place, AT_LOCATION
    target = yield from world.move_carried(s, v.first_object, place, None)
    if target:
        return target
    if not thing(s, PLAYER).places[0]:
        return (yield from end_game(s))
    return None


@registry.handler('L9404_5')
def lock(s):
    """Lock the first object with the second: unless it is locked or open
    already (handlers.check_openable) (stage 3: L9404_5)."""
    from . import handlers
    refused, reason = handlers.check_openable(s)
    if refused:
        return (yield from world.print_state(s, _noun(s, s.vars.noun1).id, reason))
    return (yield from lock_with_key(s, True))


@registry.handler('L9404_7')
def unlock(s):
    """Unlock the first object with the second: it must be locked ("<it> is
    unlocked.") and not open (stage 3: L9404_7)."""
    from . import handlers
    t = _noun(s, s.vars.noun1)
    if not t.flags & F_LOCKED:
        return (yield from world.print_state(s, t.id, REASON_UNLOCKED))
    open_already, reason = handlers.check_openable_thing(s, t.id)
    if open_already:
        return (yield from world.print_state(s, t.id, reason))
    return (yield from lock_with_key(s, False))


def lock_with_key(s, locked):
    """Generator: lock (`locked`) or unlock the first object with the key, the
    second: refused when the key is broken; then set_locked. (The asm writes
    the SET or RES into SmcSetOrRes: an argument here.) (stage 3: L9404_6)"""
    key = _noun(s, s.vars.noun2)
    if key.flags & F_DEAD:
        return (yield from world.print_state(s, key.id, REASON_BROKEN))
    if not world.commit_or_abort(s):
        return None
    set_locked(s, _noun(s, s.vars.noun1).id, locked)
    return None


def set_locked(s, id, locked):
    """Thing `id` is locked or unlocked: flag bit 0 (stage 3: SmcSetOrRes)."""
    t = thing(s, id)
    t.flags = t.flags | F_LOCKED if locked else t.flags & ~F_LOCKED & 0xFF


@registry.handler('L9404_8')
def put_through(s):
    """Put the first object through the second (a window, a door): the subject
    must hold it, the second must be an open obstacle of an exit here; the
    object goes to the exit's destination, held by nobody, with what it
    carries (stage 3: L9404_8)."""
    v = s.vars
    if not (yield from require_held(s)):
        return None
    e = world.exit_by_obstacle(s, v.second_object)
    if e is None:
        return (yield from refuse_command(s))
    door = _noun(s, v.noun2)
    if not door.flags & F_ACTIVE:
        return (yield from world.print_state(s, door.id, REASON_CLOSED))
    if not world.commit_or_abort(s):
        return None
    t = _noun(s, v.noun1)
    t.holder, t.places[0] = AT_LOCATION, e.destination
    # IY is the door: an arrival of the player writes its first place (F85)
    return (yield from world.move_carried(s, v.first_object, e.destination, door.id))


# ---- inventory, the end --------------------------------------------------------

@registry.handler('VerbInventory')
def verb_inventory(s):
    """Inventory: "You are carrying." and what the subject holds, or "Nothing"
    (stage 3: VerbInventory)."""
    v = s.vars
    if not world.commit_or_abort(s):
        return None
    yield from text.print_message(s, 'MsgCarrying')
    if not world.count_held_present(s, v.subject):
        yield from text.print_message(s, 'MsgNothing')
        return None
    yield from world.list_objects(s, v.subject, thing(s, v.actor).places[0])
    return None


@registry.handler('EndGame')
def end_game(s):
    """The end of a game: "You are dead.", the score, then a key and the game
    starts again (stage 3: EndGame)."""
    from . import system
    s.vars.subject = PLAYER
    yield from text.print_message(s, 'MsgDead')
    yield from system.print_score(s)
    return (yield from end_game_wait(s))


def end_game_wait(s):
    """Generator: wait for any key, then the game starts again: returns
    'RestartGame' (stage 3: EndGame_Wait)."""
    yield WaitKey()
    return 'RestartGame'
