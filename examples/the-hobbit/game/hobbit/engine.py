"""The engine: carrying out a command (the dispatch through the verb tables,
the test pass and the real pass), the dark, describing locations, the end of
a turn (the victory check, the characters' scripts, the timers), the script
interpreter, a character's death and the start of a new game (stage 3:
engine.py; src/engine.asm, docs/05-characters.md).

The script program is s.program, one list of Commands for all scripts (a
script runs on into the next, as in the original); a character's place in it
is its Npc.script, an index. The behaviour tables are tables.json
'behaviour': name -> [(id, command index)]. The handlers the tables name
(verb tables, timers, script routines) run through world.call_handler; a
flow target one returns (a stage 3 Goto) ends everything at once and is
returned. The other wave B modules (parser, handlers, verbs) are imported
where they are called."""
import functools

from . import assets, pictures, registry, terminal, text, world
from .state import AT_LOCATION, Exit, WaitKey
from .world import END, F_CHARACTER, F_DEAD, F_PRESENT, NO_OBJECT, PLAYER

NO_ACTOR = 0xFF                 # "someone"
PLACE = 1                       # Noun1Kind/Noun2Kind: the noun is a place reached by an exit
LOC_LIT = 0x80                  # location flags bit 7
SWORD = 0x0E                    # OBJ_SHORT_STRONG_SWORD, the light
LIGHT_MASK, LIGHT_ON = 0x1C, 0x14   # its flags bits 4 and 2 set, 3 clear: it shines
WHITE = 7
CMD_GO_THROUGH = 0x1E
SIGHT_DARK, SIGHT_NOISE_HEARD = 1, 2
# The preposition of a location, by its flags bits 1-3 (LocationPrepositions):
# outside, inside, in, on, at. Location 0's flags ($FF) would index past them
# (the asm writes $00 $00 into the message there): it is never described.
PREPOSITIONS = (0x04C2, 0x037B, 0x0378, 0x04AA, 0x0070)
# The script language (src/engine.asm at RunNpcScripts)
MAX_FAILURES = 6
OP_VERB, OP_FIRST_CONTROL, OP_SWITCH, OP_JUMP, OP_RANDOM = 4, 5, 0xC, 0xE, 0xF
BIT_ROUTINE, BIT_ALTERNATIVE, BIT_ERASE, BIT_NO_ORDER = 0x01, 0x10, 0x20, 0x40


@functools.lru_cache(None)
def _tables():
    """tables.json, checked for what the engine reads."""
    t = assets.load_json('tables.json')
    if not all(len(b) == 3 and len(b[1]) == 3 for b in t['blocked_exits']) or not t['random_events']:
        raise ValueError('tables.json: blocked_exits [location, [3 bytes], exit index] and random_events expected')
    return t


def _behaviour(name):
    """The behaviour table `name`: [(id, command index)]."""
    return _tables()['behaviour'][name]


# ---- the dark ---------------------------------------------------------------

def check_dark(s):
    """Can the subject not see? Only the player can be in the dark: inside a
    shut holder, or at a location that is not lit, unless the short strong
    sword is within the actor's reach and shines. The lit test reads the
    actor's location, as the asm does. Callers print 'MsgDark'.
    (stage 3: CheckDark, carry)"""
    if s.vars.subject != PLAYER:
        return False
    if world.closed_holder(s, PLAYER) == AT_LOCATION \
            and s.locations[world.actor_location(s)].flags & LOC_LIT:
        return False
    return not (world.actor_can_reach(s, SWORD)
                and world.thing(s, SWORD).flags & LIGHT_MASK == LIGHT_ON)


@registry.handler('UpdatePlayerSight')         # VerbHandlers runs it after VerbCapture (verb 0)
def update_player_sight(s):
    """Note where the player is and whether the player can see (sight_state 0,
    or SIGHT_DARK). (stage 3: UpdatePlayerSight)"""
    s.vars.player_location = world.single_location(s, PLAYER)
    s.vars.sight_state = SIGHT_DARK if check_dark(s) else 0


# ---- carrying out a command -------------------------------------------------

def abort_unless_perform(s):
    """Go on only when the command is really performed and allowed: False makes
    the calling handler return at once (the asm drops its return address).
    (stage 3: AbortUnlessPerform)"""
    return bool(s.vars.action_perform & s.vars.action_allowed)


def check_verb_applies(s):
    """Does the command make sense for the first object? 0 when the nouns
    clash; 1 when VerbHandlers has the verb, the command places the first
    object, or the object's verb table has the verb; 0 otherwise. Also stored
    in action_allowed. (stage 3: CheckVerbApplies)"""
    from . import handlers
    v = s.vars
    applies = not world.same_object_twice(s) and (
        any(verb == v.command for verb, _ in _tables()['verb_handlers'])
        or handlers.is_placing_command(s)
        or world.verb_entry(s, v.first_object, v.command) is not None)
    v.action_allowed = int(applies)
    return v.action_allowed


def dispatch_command(s):
    """Generator: carry out the command (command, first_object, second_object
    by the subject) on the test pass (action_perform 0: the handlers only check,
    a refusal clears action_allowed) or the real pass. A thing named twice is
    refused ("I cannot do that."); in the dark "I see nothing here." unless the
    command needs no light and both objects are held. The handlers: a thing
    another character carries stops it (check_held_by_other); then the verb's
    entry in the first object's verb table (the second object's for a placing
    command), else in VerbHandlers (always with no first object or a place),
    else "I cannot do that."; the entry is run, then each entry after it with
    verb 0. On the real pass: "It is dark." if the player now is, and the
    characters named are told (their scripts for the verb). Returns a flow
    target or None. (stage 3: DispatchCommand)"""
    from . import handlers
    v = s.vars
    if world.same_object_twice(s):
        yield from text.print_cannot_do_that(s)
        return None                         # (no notification)
    if check_dark(s) and (v.needs_light or not world.first_object_held(s)
                          or not world.held_by_subject(s, v.second_object)):
        yield from text.print_message(s, 'MsgISeeNothingHere')
        return (yield from _dispatch_done(s))
    table, i = None, None
    if v.noun1_kind != PLACE and v.first_object != NO_OBJECT:
        v.noun1 = ('thing', v.first_object)
        if (yield from check_held_by_other(s, v.first_object)):
            return (yield from _dispatch_done(s))
        owner = v.first_object
        if v.second_object != NO_OBJECT:
            owner = None                    # a place: VerbHandlers
            if v.noun2_kind != PLACE:
                v.noun2 = ('thing', v.second_object)
                if (yield from check_held_by_other(s, v.second_object)):
                    return (yield from _dispatch_done(s))
                owner = v.second_object if handlers.is_placing_command(s) else v.first_object
        if owner is not None:
            i = world.verb_entry(s, owner, v.command)
            table = world.thing(s, owner).verbs
    if i is None:
        table = _tables()['verb_handlers']
        i = next((k for k, (verb, _) in enumerate(table) if verb == v.command), None)
        if i is None:
            yield from text.print_cannot_do_that(s)
            return None                     # (no notification)
    while True:
        target = yield from world.call_handler(s, table[i][1])
        if isinstance(target, str):
            return target
        i += 1
        if i == len(table) or table[i][0] != 0:
            break
    return (yield from _dispatch_done(s))


def _dispatch_done(s):
    """The end of a real pass: "It is dark." when the player now is in the
    dark, then both objects' records are told of the verb. The records are
    noun1 and noun2 as they are, set by this or an earlier pass (stale with no
    object or a place: quirk kept), the ids the objects. (stage 3:
    DispatchCommand_Done)"""
    v = s.vars
    if v.action_perform != 1:
        return None
    if v.subject == PLAYER and check_dark(s):
        yield from text.print_message(s, 'MsgDark')
    _notify(s, v.noun1, v.first_object, v.command)
    _notify(s, v.noun2, v.second_object, v.command)
    return None


def check_held_by_other(s, id):
    """Generator: does a character other than the player carry thing `id`
    (NO_OBJECT: no)? Only the player is told: when the thing does not lie at a
    location, is not held by the subject, the top of its holder chain is a
    character and the player is present, "<the carrier> is carrying <the
    thing>." and True. (stage 3: CheckHeldByOther, NZ)"""
    v = s.vars
    if id == NO_OBJECT or v.subject != PLAYER:
        return False
    t = world.thing(s, id)
    if t.holder == AT_LOCATION or world.held_by_subject(s, id):
        return False
    top = t
    while top.holder != AT_LOCATION:
        top = world.thing(s, top.holder)
    if not top.flags & F_CHARACTER or not world.thing(s, PLAYER).flags & F_PRESENT:
        return False
    yield from text.print_message(s, 'MsgCarrying3', [t.names[0], top.names[0]])
    return True


def _record_flags(s, record):
    """Byte +7 of a record: a thing's flags; of a location record the high byte
    of its third name word; with no record (0) the ROM's byte 7, $11."""
    if record is None:
        return 0x11
    kind, id = record
    return world.thing(s, id).flags if kind == 'thing' else s.locations[id].names[2] >> 8


def _notify(s, record, id, verb):
    """When `record` is a living character, switch character `id` to its
    script for `verb` (the record and the id can differ: see _dispatch_done).
    (stage 3: NotifyCharacter)"""
    if _record_flags(s, record) & (F_CHARACTER | F_DEAD) == F_CHARACTER:
        switch_npc_script(s, id, verb)


def notify_character(s, id, verb):
    """Generator (it prints nothing): a living character `id` switches to its
    script for `verb`; other things are ignored. (stage 3: NotifyCharacter)"""
    _notify(s, ('thing', id), id, verb)
    return None
    yield


# ---- describing a location --------------------------------------------------

def describe_location(s, loc):
    """Generator: "<subject> are in/on/at/inside/outside" (the preposition by
    the location's flags, written into the message MsgSubjIsIn, which keeps
    it: s.vars.subj_is_in), then the location as describe_location_intro
    shows it. (stage 3: DescribeLocation)"""
    s.vars.subj_is_in = PREPOSITIONS[s.locations[loc].flags >> 1 & 7]
    yield from describe_location_intro(s, loc, 'MsgSubjIsIn')


def describe_seen(s, loc):
    """Generator: "<subject> see" and location `loc`. (stage 3: DescribeSeen)"""
    yield from describe_location_intro(s, loc, 'MsgSee')


def describe_location_intro(s, loc, message):
    """Generator: the message `message`, the location's description (or its
    name), its picture (pictures on: the game waits for a key, then the border
    is white), a new line, the obstacles on its exits, its visible exits and
    what lies there. (stage 3: DescribeLocation_Intro, ShowLocation)"""
    where = s.locations[loc]
    yield from text.print_message(s, message)
    if where.description:
        yield from text.print_message(s, where.description)
    else:
        yield from print_location_name(s, loc)
    if pictures.draw_location_picture(s, loc):
        yield WaitKey()                     # WaitKeyAfterPicture
        s.screen.border = WHITE
    yield from terminal.new_line(s)
    yield from world.list_exit_obstacles(s, loc)
    yield from show_location_lists(s, loc)


def show_location_lists(s, loc):
    """Generator: the visible exits of `loc`, then "<subject> see :" and what
    lies where the actor is. (stage 3: ShowLocation_Lists)"""
    yield from world.list_visible_exits(s, loc)
    yield from world.list_objects_here(s)


def print_location_name(s, loc):
    """Generator: the location's name (adjectives and noun). (stage 3: PrintLocationName)"""
    yield from text.print_name_phrase(s, s.locations[loc].names)


def describe_location_short(s, loc):
    """Generator: a visited location: its name, a new line, its exits and what
    lies there. (stage 3: DescribeLocationShort)"""
    yield from print_location_name(s, loc)
    yield from terminal.new_line(s)
    yield from show_location_lists(s, loc)


def print_message_dot(s, message):
    """Generator: the message, a full stop and a new line. (stage 3: PrintMessageDot)"""
    yield from text.print_message(s, message)
    yield from terminal.put_char(s, ord('.'))
    yield from terminal.new_line(s)


# ---- the end of a turn ------------------------------------------------------

def end_turn(s):
    """Generator: the end of the player's turn: the victory check, every
    character's script, then the timers, with action_perform and
    action_allowed 1. A running timer counts down; at 0 it fires its handler,
    but one timer a turn: another that reaches 0 is put off (its counter 1).
    A timer that did not fire calls its tick handler while its counter is at
    most its threshold (not 0). Returns a flow target or None. (stage 3:
    EndTurn_Timer, the asm's L96B3)"""
    from . import handlers
    v = s.vars
    target = yield from handlers.check_victory(s)
    if isinstance(target, str):
        return target
    target = yield from run_npc_scripts(s)
    if isinstance(target, str):
        return target
    v.timers_fired = 0
    v.action_allowed = v.action_perform = 1
    for t in s.timers:
        if t.start == END:
            break                           # (byte 0 is also the table's end mark)
        if not t.counter:
            continue
        t.counter -= 1
        if not t.counter:
            t.counter = v.timers_fired      # 0: it fires; 1: put off a turn
            if v.timers_fired != 1:
                v.timers_fired = 1
                target = yield from world.call_handler(s, t.fire)
                if isinstance(target, str):
                    return target
                continue
        if t.threshold and t.counter <= t.threshold:
            target = yield from world.call_handler(s, t.tick)
            if isinstance(target, str):
                return target
    v.messages_visible = 1
    return None


# ---- the characters' scripts ------------------------------------------------

def run_npc_scripts(s):
    """Generator: every character's turn, in s.npcs order (dormant slots, id
    0, skipped). The player sees what a character does (messages_visible 1)
    when it is within the player's reach; in the dark the first one within
    reach gives "You hear a noise." and nothing more is seen this turn. A
    character something holds goes to world.npc_held. Then its script runs
    until a command succeeds or it has failed MAX_FAILURES times (see
    _script_command). At the end the subject and the actor are the player
    and messages are visible. Returns a flow target or None. (stage 3:
    RunNpcScripts)"""
    update_player_sight(s)
    return (yield from _npc_turns(s, 0, False))


def run_npc_scripts_start(s, k):
    """Generator: character k acts as usual (from world.npc_held), then the
    rest of the list. (stage 3: RunNpcScripts_Start)"""
    return (yield from _npc_turns(s, k, True))


def run_npc_scripts_next(s, k):
    """Generator: the characters after slot k. (stage 3: RunNpcScripts_Next)"""
    return (yield from _npc_turns(s, k + 1, False))


def _npc_turns(s, k, start):
    """The NPC loop from slot k; `start`: at the order test of slot k."""
    from . import parser
    v = s.vars
    while True:
        if not start:
            v.npc_failures = 0
            if k == len(s.npcs) or s.npcs[k].id == END:
                break
            id = s.npcs[k].id
            if id == 0:
                k += 1
                continue
            v.subject = v.actor = id
            v.actor_location = world.single_location(s, id)
            v.messages_visible = 0
            if world.can_reach(s, PLAYER, id) and v.sight_state != SIGHT_NOISE_HEARD:
                v.messages_visible = 1
                if v.sight_state == SIGHT_DARK:
                    v.sight_state = SIGHT_NOISE_HEARD
                    yield from text.print_message(s, 'MsgHearNoise')
                    v.messages_visible = 0
            if world.thing(s, id).holder != AT_LOCATION:
                return (yield from world.npc_held(s, k))      # it ends the list
        start = False
        v.actor_has_order = int(parser.find_order_slot(s) is not None)
        step = 'script'
        while step in ('script', 'command'):
            step = yield from _script_command(s, k)
        if step != 'next':
            return step                     # a flow target
        k += 1
    v.subject = PLAYER
    v.messages_visible = 1
    v.actor = PLAYER
    return None


def _script_command(s, k):
    """Generator: character k tries the command at its script position.
    Commands (ops 0-4) take a stored order first, once a turn, unless the
    command has BIT_NO_ORDER: a usable order is done instead and the turn is
    over, the script not moved. Op E jumps, op C switches to a behaviour, op F
    to a random one, and the character goes on at once; the other ops end the
    script: entry 0 of the behaviour table, the turn over. Returns the next
    step: 'next' (the turn is over), 'script' or 'command' (go on at the
    script position: the asm's RunNpcScripts_Script and _Command), or a flow
    target. (stage 3: RunNpcScripts_Command)"""
    v, npc = s.vars, s.npcs[k]
    if v.npc_failures == MAX_FAILURES:
        return 'next'
    i = npc.script
    c = s.program[i]
    op = c.op & 0x0F
    if op < OP_FIRST_CONTROL:
        if v.actor_has_order == 1 and not c.op & BIT_NO_ORDER:
            from . import parser
            v.actor_has_order = 0
            got = yield from parser.run_stored_order(s, True)
            if isinstance(got, str):
                return got
            if got[0]:
                v.action_perform = v.action_allowed = 1
                target = yield from run_actor_command_run(s)
                return target if isinstance(target, str) else 'next'
        if op == OP_VERB:
            return (yield from run_script_verb(s, k, i))
        return (yield from run_script_command(s, k, i))
    if op == OP_JUMP:
        npc.script = c.target
    elif op == OP_SWITCH:
        switch_npc_script(s, npc.id, c.args[0])
    elif op == OP_RANDOM:
        yield from choose_random_script(s, k, i)
    else:
        # 5-9, B, D (A too): the end of the script (the asm's test for op 0
        # after them can never be true)
        select_script(s, k, 0)
        return 'next'
    return 'script'


def run_script_command(s, k, i):
    """Generator: character k does command i of the program (ops 0-3), its
    script moved past it first. Ops 0 and 2: the verb and objects of its
    arguments through run_actor_command. Ops 1 and 3: its routine, a test
    pass that must set action_allowed to 1, then the real pass. A success
    ends the turn ('next'), erasing the command when it has BIT_ERASE: its
    byte becomes 0, so the routine's address bytes would run as a verb and
    objects if it is reached again (quirk kept; only Thorin's routine LA51C
    has the bit). A failure: script_command_failed. (stage 3: RunScriptCommand)"""
    v, c = s.vars, s.program[i]
    s.npcs[k].script = i + 1                # AdvanceScript (its alternative skipped too)
    if c.op & BIT_ROUTINE:
        v.action_perform = v.action_allowed = 0
        target = yield from world.call_handler(s, c.routine)
        if isinstance(target, str):
            return target
        if v.action_allowed != 1:
            return script_command_failed(s, k, i)
        v.action_perform = 1
        target = yield from world.call_handler(s, c.routine)
        if isinstance(target, str):
            return target
    else:
        v.command, v.first_object, v.second_object = c.args
        done = yield from run_actor_command(s)
        if isinstance(done, str):
            return done
        if not done:
            return script_command_failed(s, k, i)
    if c.op & BIT_ERASE:
        c.op, c.routine = 0, None
    return 'next'


def run_script_verb(s, k, i):
    """Generator: character k does command i (op 4), a verb alone, its script
    moved past it first. Verb $FF does nothing: the script goes to the
    alternative if there is one, and the turn is over. Another verb runs with
    no objects through run_actor_command: done, the turn is over; refused,
    script_command_failed. (stage 3: RunScriptVerb)"""
    v, c, npc = s.vars, s.program[i], s.npcs[k]
    npc.script = i + 1                      # AdvanceScript
    verb = c.args[0]
    if verb == NO_OBJECT:
        if c.op & BIT_ALTERNATIVE:
            npc.script = c.alternative
        return 'next'
    v.command, v.first_object, v.second_object = verb, NO_OBJECT, NO_OBJECT
    done = yield from run_actor_command(s)
    if isinstance(done, str):
        return done
    return 'next' if done else script_command_failed(s, k, i)


def script_command_failed(s, k, i):
    """Command i of character k failed: count it, and go on at its alternative
    ('command') if it has one, else at the script position ('script').
    (stage 3: ScriptCommandFailed)"""
    s.vars.npc_failures = s.vars.npc_failures + 1 & 0xFF
    c = s.program[i]
    if not c.op & BIT_ALTERNATIVE:
        return 'script'
    s.npcs[k].script = c.alternative
    return 'command'


def choose_random_script(s, k, i):
    """Generator: op F (command i): character k takes the script of a random
    behaviour entry from 0 to the smaller of the command's argument and its
    max_random. (stage 3: ChooseRandomScript)"""
    npc = s.npcs[k]
    entry = yield from world.random_up_to(s, min(s.program[i].args[0], npc.max_random))
    select_script(s, k, entry)


def select_script(s, k, entry):
    """Character k takes the script of behaviour entry `entry` (at most its
    max_random). (stage 3: SelectScript)"""
    npc = s.npcs[k]
    npc.script = _behaviour(npc.table)[min(entry, npc.max_random)][1]


def find_npc(s, id):
    """The slot in s.npcs of character `id`, or None. Id 0 finds the first
    dormant slot (quirk kept: the player told of a command switches it).
    (stage 3: FindNpcState)"""
    for k, npc in enumerate(s.npcs):
        if npc.id == id:
            return k
        if npc.id == END:
            break
    return None


def switch_npc_script(s, id, behaviour):
    """Character `id` takes the script of its behaviour table's entry for
    `behaviour` (a verb, or 0, $0F...); nothing without a slot or an entry.
    (stage 3: SwitchNpcScript)"""
    k = find_npc(s, id)
    if k is None:
        return
    for b, script in _behaviour(s.npcs[k].table):
        if b == behaviour:
            s.npcs[k].script = script
            return


def run_actor_command(s):
    """Generator: the subject (a character) does the command: the test pass
    (parser.test_actor_command); refused, False. Otherwise
    run_actor_command_run. Returns True, False or a flow target. (stage 3:
    RunActorCommand, NZ)"""
    from . import parser
    ok = yield from parser.test_actor_command(s)
    if isinstance(ok, str):
        return ok
    if not ok:
        return False
    return (yield from run_actor_command_run(s))


def run_actor_command_run(s):
    """Generator: the command, tested already: announced as a sentence (seen
    only when messages are visible) unless the first noun is a place, or it is
    going through something away from the player. When the actor is away and
    the first object has several places, one of them the player's, it is
    announced with "Someone" as the subject, seen. Then the real pass, and
    "<actor> enters." and "<first object> appears." when they came to the
    player. Returns True or a flow target. (stage 3: RunActorCommand_Run)"""
    v = s.vars
    quiet = v.noun1_kind == PLACE or v.command == CMD_GO_THROUGH \
        and v.actor_location != world.thing(s, PLAYER).places[0]
    if not quiet:
        someone = False
        if v.first_object != NO_OBJECT:
            v.first_object_place = world.single_location(s, v.first_object)   # (only here: stale otherwise)
            if v.first_object_place == NO_OBJECT and v.player_location != v.actor_location:
                someone = v.player_location in world.thing(s, v.first_object).places
        if someone:
            subject, v.subject, v.messages_visible = v.subject, NO_ACTOR, 1
            yield from text.print_command_sentence(s)
            v.messages_visible, v.subject = 0, subject
        else:
            yield from text.print_command_sentence(s)
    target = yield from dispatch_command(s)
    if isinstance(target, str):
        return target
    yield from announce_arrival(s, v.subject, v.actor_location, 'MsgEnters')
    if v.noun1_kind != PLACE:
        yield from announce_arrival(s, v.first_object, v.first_object_place, 'MsgAppears')
    return True


def announce_arrival(s, id, before, message):
    """Generator: thing `id` (not the player, not NO_OBJECT) was at `before`:
    when it is now where the player is, "<name> enters." or "appears."
    (`message`), unless the noise was heard this turn or move_flag is 0 (the
    player came along). (stage 3: AnnounceArrival)"""
    v = s.vars
    if id in (END, PLAYER) or v.sight_state == SIGHT_NOISE_HEARD:
        return
    now = world.single_location(s, id)
    if now == before or now != v.player_location or not v.move_flag:
        return
    v.messages_visible = 1
    yield from text.print_message(s, message, [world.thing(s, id).names])


# ---- death and a new game ---------------------------------------------------

def kill_character(s, id):
    """Generator: character `id` dies; the player (0): verbs.end_game, which
    returns 'RestartGame'. Another is marked dead, what it holds is put down
    (world.empty_holder), its slot made dormant, its name "dead ...", its
    orders freed. Returns a flow target or None. (stage 3: KillCharacter)"""
    if id == PLAYER:
        from . import verbs
        return (yield from verbs.end_game(s))
    from . import parser
    world.thing(s, id).flags |= F_DEAD
    yield from world.empty_holder(s, id)
    k = find_npc(s, id)
    if k is not None:
        s.npcs[k].id = 0
    world.mark_broken_or_dead(s, id)
    parser.free_order_slots(s, id)
    return None


def kill_first_object(s):
    """Generator: the first object dies. (stage 3: L977C)"""
    return (yield from kill_character(s, s.vars.first_object))


def init_new_game(s):
    """Generator: a new game: the player acts; one of the blocked exits
    (tables.json 'blocked_exits': [location, the exit as saved, its index]) is
    chosen at random and removed (Exit(0, 0, 0) until ExamineMap puts it
    back), and one of the random events. (stage 3: InitNewGame)"""
    v = s.vars
    v.subject = v.exit_restore_mode = v.reply_given = 0
    v.actor = PLAYER
    blocked = _tables()['blocked_exits']
    v.blocked_exit = yield from world.random_up_to(s, len(blocked) - 1)
    loc, _, exit = blocked[v.blocked_exit]
    s.locations[loc].exits[exit] = Exit(0, 0, 0)
    v.random_event = yield from world.random_up_to(s, len(_tables()['random_events']) - 1)
