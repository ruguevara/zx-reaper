"""The world: things and locations, the queries over them (what holds what,
weights and sizes, room, reach, exits), moving contents, the random numbers,
and the lists the game prints about them (stage 3: objects.py; src/objects.asm,
docs/05-world.md).

Things are walked in s.things order, the original's table order: the order is
behaviour (lists, sums, the first match). The routines that print are
generators (through the text slice's text and terminal); the rest are plain
functions. The wave B modules (engine, verbs) are imported where they are
called."""
import functools
import inspect

from . import assets, registry, terminal, text, words
from .state import AT_LOCATION, Mixed

PLAYER = 0
NO_OBJECT = 0xFF                # an empty object variable (FirstObject...)
END = 0xFF                      # END_MARK: a walk found nothing
LOCATION_COUNT = 80
LIST_INDENT = 4                 # the indent of a top-level list
ALL_MODE_ANY = 2                # AllMode: any thing (0 things, 1 living characters)
DIR_UP = 9                      # directions 1-8 are the compass, 9 up, 10 down
CMD_CLIMB_OUT_OF = 0x37
F_PRESENT, F_CHARACTER, F_ACTIVE, F_DEAD, F_LIQUID = 0x80, 0x40, 0x20, 0x08, 0x02
PHRASE_BROKEN, PHRASE_DEAD = 0x00CD, 0x0192     # adjectives of MarkBrokenOrDead
WORD_IS, WORD_ARE = 0x039B, 0x0065
WORD_ABOVE, WORD_BELOW = 0x07B5, 0x082B


@functools.lru_cache(None)
def _tables():
    """game/assets/world.json: the direction words (by direction id), the state
    words (by state id & $7F; [0] bit 7 clear, [1] bit 7 set) and the relation
    messages (by state & 15)."""
    t = assets.load_json('world.json')
    if len(t['direction_words']) != 11 or [len(w) for w in t['state_words']] != [8, 8] \
            or not t['relations']:
        raise ValueError('world.json: 11 direction words, 2 x 8 state words and the relations expected')
    t['id_words'] = t['direction_words'] + t['state_words'][0] + t['state_words'][1]
    return t


# The lookups

def thing(s, id):
    """The Thing with that id; None when there is none (stage 3: FindObject,
    which leaves garbage in IX then)."""
    for t in s.things:
        if t.id == id:
            return t
    return None


def location(s, id):
    """The Location with that id; None for an id of 80 or more (stage 3:
    FindLocation, which leaves IX as it was then)."""
    return s.locations[id] if id < LOCATION_COUNT else None


def living(s, id):
    """Is thing `id` a character that is not dead? (stage 3: LA1AE_2)"""
    return thing(s, id).flags & (F_CHARACTER | F_DEAD) == F_CHARACTER


def verb_entry(s, id, verb):
    """The index in thing `id`'s verb table of the first entry for `verb`, or
    None (stage 3: FindVerbEntry)."""
    for i, (v, _) in enumerate(thing(s, id).verbs):
        if v == verb:
            return i
    return None


def next_named_thing(s, phrase, cursor):
    """The next thing after table index `cursor` (-1 from the first; 0 skips the
    player) that a typed noun phrase can mean: of the kind s.vars.all_mode asks
    (0 not a living character, 1 a living character, ALL_MODE_ANY any; another
    value finds nothing), its names matching, and within the actor's reach
    unless s.vars.all_active (the names match as words.match_command_record
    says: the noun, then the adjectives in order or swapped). Returns (id, its
    index), or (END, len(s.things)) when none is left (stage 3:
    FindNextNamedObject, the cursor its IX)."""
    mode = s.vars.all_mode
    for i in range(cursor + 1, len(s.things)):
        t = s.things[i]
        if mode != ALL_MODE_ANY and (t.flags & (F_CHARACTER | F_DEAD) == F_CHARACTER) != mode:
            continue
        if words.match_command_record(s, t.names, phrase)[0] and (s.vars.all_active or actor_can_reach(s, t.id)):
            return t.id, i
    return END, len(s.things)


# Holders, weights, room

def held_by(s, id, holder):
    """Is `holder` up the chain of holders of thing `id` (its holder, the
    holder's holder...)? NO_OBJECT counts as held (stage 3: CheckObject1Held_0,
    WalkHolderChain)."""
    if id == NO_OBJECT:
        return True
    while True:
        id = thing(s, id).holder
        if id == AT_LOCATION:
            return False
        if id == holder:
            return True


def held_by_subject(s, id):
    """Is thing `id` held by the subject, at any depth? (stage 3: CheckHeldBySubject)"""
    return held_by(s, id, s.vars.subject)


def first_object_held(s):
    """Is the first object held by the subject? (stage 3: CheckObject1Held)"""
    return held_by(s, s.vars.first_object, s.vars.subject)


def closed_holder(s, id):
    """The first holder up the chain of thing `id` that is shut: neither open
    or alive (flag bit 5) nor dead or broken (bit 3); AT_LOCATION when the
    chain reaches a location first (stage 3: FindClosedHolder)."""
    t = thing(s, id)
    while t.holder != AT_LOCATION:
        h = thing(s, t.holder)
        if not h.flags & (F_ACTIVE | F_DEAD):
            return h.id
        t = h
    return AT_LOCATION


def can_reach(s, observer, id):
    """Can thing `observer` reach thing `id`? It must be present; then yes when
    the observer's closed holder is the thing itself or the thing's closed
    holder too, and, both in the open, when the observer's first place is one
    of the thing's places (stage 3: CanReach; with no places the asm would
    compare 256 bytes past the record: no thing has none)."""
    t = thing(s, id)
    if not t.flags & F_PRESENT:
        return False
    mine = closed_holder(s, observer)
    if mine == id:
        return True
    if closed_holder(s, id) != mine:
        return False
    return mine != AT_LOCATION or thing(s, observer).places[0] in t.places


def actor_can_reach(s, id):
    """Can the actor reach thing `id`? (stage 3: ActorCanReach; CanReachSwapped
    is can_reach with its records exchanged)"""
    return can_reach(s, s.vars.actor, id)


def sum_held(s, holder, weights, total=0):
    """Add to `total` the weights of what `holder` holds directly (`weights`),
    or the sizes of everything inside it. The add is a signed byte add: past
    127 the total becomes $FF and that level's walk ends (an outer level goes
    on from $FF). Quirk: the walk starts after the table's first entry, so the
    player is never counted (stage 3: SumHeldRecords)."""
    for t in s.things[1:]:
        if t.holder != holder:
            continue
        add = t.weight if weights else t.size
        new = total + add & 0xFF
        if (total ^ new) & (add ^ new) & 0x80:
            return 0xFF
        total = new
        if not weights:
            total = sum_held(s, t.id, weights, total)
    return total


def held_weight(s, holder):
    """The weight of what `holder` holds directly, $FF past 127 (stage 3: SumHeldWeight)."""
    return sum_held(s, holder, True)


def held_bulk(s, holder):
    """The size of everything inside `holder`, $FF past 127 (stage 3: SumHeldBulk)."""
    return sum_held(s, holder, False)


def spare_capacity(s, loc):
    """Room left at location `loc`: its capacity less the weight of every thing
    with exactly one place, that one (carried things too); 0 when they weigh
    more (stage 3: LocationSpareCapacity)."""
    left = s.locations[loc].capacity
    for t in s.things:
        if t.places == [loc]:
            if t.weight > left:
                return 0
            left -= t.weight
    return left


def count_held_present(s, holder):
    """How many present things `holder` holds directly (stage 3: CountHeldPresent)."""
    return sum(1 for t in s.things if t.holder == holder and t.flags & F_PRESENT)


def single_location(s, id):
    """The one place of thing `id`; NO_OBJECT for NO_OBJECT or a thing with
    several places (stage 3: GetSingleLocation)."""
    if id == NO_OBJECT:
        return NO_OBJECT
    t = thing(s, id)
    return t.places[0] if len(t.places) == 1 else NO_OBJECT


def actor_location(s):
    """The location of the actor: its first place (stage 3: GetActorLocationRec)."""
    return thing(s, s.vars.actor).places[0]


# Exits of the actor's location (stage 3: SeekActorExits and the walks after it)

def _exits(s):
    return s.locations[actor_location(s)].exits


def exit_by_direction(s, direction):
    """The first exit of the actor's location in `direction` that leads
    somewhere (destination not 0), or None (stage 3: FindExitByDirection)."""
    return next((e for e in _exits(s) if e.destination and e.direction == direction), None)


def exit_by_obstacle(s, id):
    """The first exit of the actor's location with thing `id` as its obstacle,
    or None (stage 3: FindExitByObstacle_0; FindExitByObstacle for the first
    object)."""
    return next((e for e in _exits(s) if e.obstacle == id), None)


def exit_by_destination(s, loc):
    """The first exit of the actor's location that leads to `loc`, or None
    (stage 3: FindExitByDestination)."""
    return next((e for e in _exits(s) if e.destination == loc), None)


def next_named_exit(s, phrase, cursor):
    """The next exit of the actor's location after index `cursor` (-1 from the
    first) whose destination's names a typed noun phrase matches: (the
    destination, the exit's index), or (END, the number of exits) (stage 3:
    FindExitByName, the cursor its IX)."""
    exits = _exits(s)
    for i in range(cursor + 1, len(exits)):
        if words.match_command_record(s, s.locations[exits[i].destination].names, phrase)[0]:
            return exits[i].destination, i
    return END, len(exits)


# Changing things

def move_contents(s, holder, loc):
    """Put everything `holder` holds, and what those hold, at location `loc`
    (their first place); meeting the player clears s.vars.move_flag (stage 3:
    MoveContents)."""
    for t in s.things:
        if t.holder == holder:
            t.places[0] = loc
            if t.id == PLAYER:
                s.vars.move_flag = 0
            move_contents(s, t.id, loc)


def move_carried(s, carrier, loc, arriving):
    """Generator: carrier `carrier` has been put at `loc`; what it holds comes
    along. When the player was among it (and `loc` is not 0) the player
    arrives too, as the subject and actor for the while: verbs.actor_arrives
    (wave B) with `arriving` (the asm's IY, left by the caller: the thing whose
    place ActorArrives sets) and `loc`, then engine.update_player_sight (wave
    B). move_flag ends 0 then (stage 3: MoveCarried). Returns a flow target
    when the arrival ends the game."""
    v = s.vars
    v.move_flag = 1
    move_contents(s, carrier, loc)
    if v.move_flag:
        return None                     # the player was not among them
    if thing(s, PLAYER).places[0]:
        from . import engine, verbs
        subject, actor = v.subject, v.actor
        v.actor, v.subject, v.take_id = PLAYER, 0, loc
        target = yield from verbs.actor_arrives(s, arriving, loc)
        if isinstance(target, str):
            return target               # a Goto: the rest is skipped, as the exception does
        engine.update_player_sight(s)
        v.actor, v.subject = actor, subject
    v.move_flag = 0
    return None


def mark_broken_or_dead(s, id):
    """Thing `id` becomes "broken" (a thing) or "dead" (a character): its first
    adjective is replaced, the second cleared (stage 3: MarkBrokenOrDead)."""
    t = thing(s, id)
    t.names[1] = PHRASE_DEAD if t.flags & F_CHARACTER else PHRASE_BROKEN
    t.names[2] = 0


def empty_holder(s, holder):
    """Generator: holder `holder` is destroyed or killed: what it holds passes to
    its own holder, but a liquid evaporates (to location 0, lying there, not
    present; "<name> evaporates.") (stage 3: EmptyHolder; EmptyFirstObject is
    this for the first object)."""
    up = thing(s, holder).holder
    for t in s.things:
        if t.holder != holder:
            continue
        if t.flags & F_LIQUID:
            t.places[0], t.holder = 0, AT_LOCATION
            t.flags &= ~F_PRESENT & 0xFF
            yield from print_object_name(s, t.id)
            yield from text.print_message(s, 'MsgEvaporates2')
        else:
            t.holder = up


def commit_or_abort(s):
    """Go on only when the command is really being performed: True when
    s.vars.action_perform is 1; else (a test pass) action_allowed becomes
    action_perform + 1 and False: the caller returns at once (the asm pops its
    caller's return address) (stage 3: CommitOrAbort)."""
    if s.vars.action_perform == 1:
        return True
    s.vars.action_allowed = s.vars.action_perform + 1 & 0xFF
    return False


# The random numbers

def random_signed(s, n):
    """Generator: a random number from -n to n as a byte (two's complement; not
    evenly spread, small values likelier). It yields Mixed for the mixed value
    (the original mixes the seed with bytes of memory a walker steps through:
    not state) and asks again while that equals the seed; the value becomes
    the seed, is halved until it is at most 2n (any value for n of 128 or
    more), then n is taken off (stage 3: RandomSigned)."""
    limit = 0xFF if n & 0x80 else n << 1
    while True:
        a = yield Mixed()
        if a != s.vars.random_seed:
            break
    s.vars.random_seed = a
    while a > limit:
        a >>= 1
    return a - n & 0xFF


def random_up_to(s, n):
    """Generator: a random number from 0 to n, small values likelier: the
    absolute value of random_signed (stage 3: RandomUpTo)."""
    a = yield from random_signed(s, n)
    return -a & 0xFF if a & 0x80 else a


# Handlers

def call_handler(s, name):
    """Generator: run the handler `name` (registry.HANDLERS) unless it is None;
    returns what it returns (a flow target after a Goto) (stage 3: CallHandler,
    JumpHL; the registers it keeps are the caller's locals here)."""
    if name is None:
        return None
    result = registry.HANDLERS[name](s)
    if inspect.isgenerator(result):
        result = yield from result
    return result


def call_swapped(s, name):
    """Generator: run handler `name` with the first and second objects (and
    noun records) exchanged, then put back the values from before the call
    (stage 3: L9F4A)."""
    v = s.vars
    saved = v.noun1, v.noun2, v.first_object, v.second_object
    v.noun1, v.noun2, v.first_object, v.second_object = v.noun2, v.noun1, v.second_object, v.first_object
    result = yield from call_handler(s, name)
    if isinstance(result, str):
        return result                   # a Goto skips the restore
    v.noun1, v.noun2, v.first_object, v.second_object = saved
    return result


def same_object_twice(s):
    """Does the command use one object twice: the subject or the second object
    is the first one (unless the first noun is a place), or the second object
    is the subject (unless the second noun is a place)? Never without a first
    object (stage 3: CheckNounsDistinct, Z)."""
    v = s.vars
    if v.first_object == NO_OBJECT:
        return False
    if not v.noun1_kind and v.first_object in (v.subject, v.second_object):
        return True
    return not v.noun2_kind and v.second_object == v.subject


def npc_held(s, k):
    """Generator: the turn of the character in slot k (the actor) when
    something holds it: the holder becomes the first object (no second). A
    dead or broken holder, or a character, and it acts as usual
    (engine.run_npc_scripts_start, wave B); a shut one and its turn is over
    (engine.run_npc_scripts_next); an open one (a barrel, the boat) and it
    climbs out first. Ends in the NPC loop, whose result it returns (stage 3:
    NpcHeld)."""
    from . import engine
    v = s.vars
    v.second_object = NO_OBJECT
    v.first_object = thing(s, v.actor).holder
    flags = thing(s, v.first_object).flags
    if flags & (F_DEAD | F_CHARACTER):
        return (yield from engine.run_npc_scripts_start(s, k))
    if flags & F_ACTIVE:
        v.command = CMD_CLIMB_OUT_OF
        target = yield from engine.run_actor_command(s)
        if isinstance(target, str):
            return target
    return (yield from engine.run_npc_scripts_next(s, k))


# Printing

def id_word(id):
    """The word for direction `id` (bit 7 ignored; past the directions come the
    state words, as in the original's memory) (stage 3: GetIdWord)."""
    return _tables()['id_words'][id & 0x7F]


def print_object_name(s, id):
    """Generator: print the names of thing `id` as s.vars.phrase_mode says
    (stage 3: PrintObjectName; PrintNamePhrase is text.print_name_phrase)."""
    yield from text.print_name_phrase(s, thing(s, id).names)


def print_holder_relation(s, id):
    """Generator: print "In the", "On the", "Behind the"... for holder `id`, by
    its state & 15 (stage 3: PrintHolderRelation)."""
    yield from text.print_message(s, _tables()['relations'][thing(s, id).state & 15])


def print_state(s, id, state):
    """Generator: print "<the thing> is <state word>." for thing `id` (its noun):
    state ids below $80 are unlocked, empty, off, closed, dead...; $80 and up
    locked, full, broken, on, open, alive... (stage 3: PrintStateIX, PrintStateIY,
    PrintStateHL)."""
    word = _tables()['state_words'][state >> 7][state & 0x7F]
    yield from text.print_message(s, 'MsgTheArgIsWord', [word, thing(s, id).names[0]])


def print_contents_header(s, id):
    """Generator: the line before what thing `id` holds. When it can show its
    contents (open, alive or dead: flag bit 5 or 3) and holds something present:
    "<name> is carrying" for a character, else "<In the> <noun> there is/are";
    returns True (the contents follow). Otherwise a new line and False (stage 3:
    PrintContentsHeader, carry clear for True)."""
    t = thing(s, id)
    n = count_held_present(s, id) if t.flags & (F_ACTIVE | F_DEAD) else 0
    if not n:
        yield from terminal.new_line(s)
        return False
    if t.flags & F_CHARACTER:
        yield from text.print_message(s, 'MsgCarrying2', [id])
    else:
        args = [WORD_IS if n == 1 else WORD_ARE, t.names[0] & 0x0FFF]
        yield from print_holder_relation(s, id)        # (the two values already on the asm's stack)
        yield from text.print_message(s, 'MsgThere', args)
    return True


def list_holder_contents(s, holder, place, indent, count=0):
    """Generator: list what `holder` holds (AT_LOCATION: what lies at a
    location) at location `place`, one per line, indented by `indent`
    (s.terminal.list_indent, put back at the end). A thing is listed when it
    is at `place` (one place for a thing lying there; else its first or second
    place), is not the subject at the top level (indent LIST_INDENT) and the
    actor can reach it: its names, then a new line for the subject, else a
    full stop, the header of its contents and those, two further in. Returns
    `count` plus the things listed (stage 3: ListHolderContents, C)."""
    v, old = s.vars, s.terminal.list_indent
    s.terminal.list_indent = indent
    for t in s.things:
        if t.holder != holder or holder == AT_LOCATION and len(t.places) != 1:
            continue
        if not (t.places[0] == place or len(t.places) > 1 and t.places[1] == place):
            continue
        if v.subject == t.id and indent == LIST_INDENT or not actor_can_reach(s, t.id):
            continue
        count += 1
        v.capital_next = v.phrase_mode = 0
        yield from print_object_name(s, t.id)
        if v.subject == t.id:
            yield from terminal.new_line(s)
        else:
            yield from terminal.put_char(s, ord('.'))
            if (yield from print_contents_header(s, t.id)):
                count = yield from list_holder_contents(s, t.id, place, indent + 2, count)
    s.terminal.list_indent = old
    return count


def list_objects(s, holder, place):
    """Generator: list what `holder` holds at `place`, or "Nothing" (stage 3:
    ListObjects)."""
    if not (yield from list_holder_contents(s, holder, place, LIST_INDENT)):
        yield from text.print_message(s, 'MsgNothing')


def list_objects_here(s):
    """Generator: "<subject> see :" and what lies where the actor is (stage 3:
    ListObjectsHere)."""
    yield from text.print_message(s, 'MsgSee2')
    yield from list_objects(s, AT_LOCATION, thing(s, s.vars.actor).places[0])


def list_exit_obstacles(s, loc):
    """Generator: "To the <direction> there is <thing>." ("above", "below" for
    up and down) for every exit of `loc` whose obstacle (a door, a river, a
    web) is present. Quirk: the asm reads the first exit before testing for
    the end, so for location $2F, which has none, it walks the memory after
    the record; that is not reproduced (nothing is printed) (stage 3:
    ListExitObstacles)."""
    for e in s.locations[loc].exits:
        if not e.obstacle:
            continue
        t = thing(s, e.obstacle)
        if not t.flags & F_PRESENT:
            continue
        args = [t.names]                # one stack for both messages, as in the asm
        if e.direction < DIR_UP:
            yield from text.print_message(s, 'MsgToThe', args)
            word = id_word(e.direction)
        else:
            word = WORD_ABOVE if e.direction == DIR_UP else WORD_BELOW
        yield from text.print_code(s, word)
        yield from text.print_message(s, 'MsgThere2', args)


def list_visible_exits(s, loc):
    """Generator: "Visible exits are:" and the direction of every exit of `loc`
    with no obstacle and a direction (0: an erased exit), then a new line;
    nothing without one (stage 3: ListVisibleExits)."""
    shown = [e for e in s.locations[loc].exits if not e.obstacle and e.direction]
    if not shown:
        return
    yield from text.print_message(s, 'MsgVisibleExits')
    for e in shown:
        yield from text.print_code(s, id_word(e.direction))
    yield from terminal.new_line(s)


def refuse_command(s):
    """Generator: the command cannot be done: really performing, "<subject>
    cannot <the command>." (text.print_command_sentence); a test pass,
    action_allowed 0 (stage 3: RefuseCommand)."""
    if s.vars.action_perform == 1:
        return (yield from text.print_command_sentence(s))
    s.vars.action_allowed = 0
    return None
