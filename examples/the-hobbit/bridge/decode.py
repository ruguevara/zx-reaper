"""Stage 3 memory -> the stage 4 state (game/hobbit/state.py).

Records become dataclasses by id; addresses become names (the stage 3 label
at the address: messages, handlers, behaviour tables) or indices (the NPC
script program, the random events, the blocked exits); screen addresses
become columns. Scratch memory (the parser's work areas and phrase stack, the
printer's saved registers, the key scanner, the drawing variables) is left
out, as are the random walker and the idle counter."""
import functools
import re

import paths  # noqa: F401
import labels as L
from hobbit.state import (Command, Exit, GameState, Location, Npc, Order, Phrase, Terminal,
                          Thing, Timer, Vars)
from zxpyxel.display import Display

SCRIPTS = (0xC82D, 0xCA84)      # the NPC behaviour tables and scripts
ARGS = {0: 3, 1: 3, 2: 3, 3: 3, 4: 1, 0xC: 1, 0xE: 2, 0xF: 1}    # argument bytes by op


@functools.lru_cache(None)
def names():
    """Address -> the label naming it (a routine's own name before an L-label)."""
    out = {}
    for k, v in vars(L).items():
        auto = re.match(r'^L[0-9A-F]{4}(_\d+)?$', k) is not None
        if isinstance(v, int) and 0x6000 <= v < 0x10000 and (auto or not k.isupper()):
            if v not in out or out[v][0] and not auto:
                out[v] = (auto, k)
    return {a: n for a, (auto, n) in out.items()}


def name(a):
    """The name at address `a`, or None for 0."""
    if a == 0:
        return None
    try:
        return names()[a]
    except KeyError:
        raise KeyError('no label at $%04X' % a) from None


def word(mem, a):
    return mem[a] | mem[a + 1] << 8


@functools.lru_cache(None)
def layout(blob):
    """The script area: its commands' addresses (the program's order) and the
    behaviour tables (name, address), from the labels; the byte layout is
    checked to cover the area."""
    mem = blob
    starts = sorted((a, n) for a, n in names().items() if SCRIPTS[0] <= a < SCRIPTS[1])
    commands, tables, a = [], [], SCRIPTS[0]
    bounds = [v for v, k in starts]
    while a < SCRIPTS[1]:
        lab = names().get(a, '')
        if lab.endswith('Behaviours'):
            tables.append((lab, a))
            while mem[a - SCRIPTS[0]] != 0xFF:
                a += 3
            a += 1
            continue
        op = mem[a - SCRIPTS[0]]
        n = 1 + ARGS.get(op & 0x0F, 0) + (2 if op & 0x10 else 0)
        commands.append(a)
        a += n
    if a != SCRIPTS[1] or any(b not in set(commands) | {t for _, t in tables} for b in bounds
                              if not names().get(b, '').startswith('BardCommand')):
        raise AssertionError('the script area does not parse into commands at its labels')
    return tuple(commands), tuple(tables)


def program(mem):
    """The NPC script program and the behaviour tables (name -> [(id, index)])."""
    commands, tables = layout(bytes(mem[SCRIPTS[0]:SCRIPTS[1]]))
    index = {a: i for i, a in enumerate(commands)}
    out = []
    for a in commands:
        op = mem[a]
        n = ARGS.get(op & 0x0F, 0)
        args = list(mem[a + 1:a + 1 + n])
        c = Command(op=op, args=args)
        if op & 0x0F in (1, 3):
            c.routine = name(word(mem, a + 1))
        elif op & 0x0F == 0xE:
            c.target, c.args = index[word(mem, a + 1)], []
        if op & 0x10:
            c.alternative = index[word(mem, a + 1 + n)]
        out.append(c)
    behaviour = {}
    for lab, a in tables:
        entries = []
        while mem[a] != 0xFF:
            entries.append((mem[a], index[word(mem, a + 1)]))
            a += 3
        behaviour[lab] = entries
    return out, behaviour, index


_STARTS = {}


def record_starts(mem=None):
    """Record address -> ('location'|'thing', id), from the original's tables
    (they never change; read once)."""
    if _STARTS or mem is None:
        return _STARTS
    out = _STARTS
    for i in range(80):
        out[word(mem, L.LocationTable + 2 * i)] = ('location', i)
    a = L.ObjectTable
    while mem[a] != 0xFF:
        out[word(mem, a + 1)] = ('thing', mem[a])
        a += 3
    return out


def which(ptr, offsets=(0,)):
    """('location'|'thing', id) of a record pointer (or a pointer `offset` into one)."""
    if ptr == 0:
        return None
    for o in offsets:
        if ptr - o in record_starts():
            return record_starts()[ptr - o]
    raise KeyError('$%04X is not a record' % ptr)


def location(mem, i):
    a = word(mem, L.LocationTable + 2 * i)
    exits, e = [], a + 10
    end = min([b for b in record_starts() if b > a and record_starts()[b][0] == 'location'] or [0x10000])
    while mem[e] != 0xFF and e < end:       # location 0 has no end mark: its one exit, then location 1

        exits.append(Exit(mem[e], mem[e + 1], mem[e + 2]))
        e += 3
    return Location(id=i, flags=mem[a], capacity=mem[a + 1],
                    names=[word(mem, a + 2), word(mem, a + 4), word(mem, a + 6)],
                    description=name(word(mem, a + 8)), exits=exits)


def thing(mem, i, a):
    n = mem[a]
    places = list(mem[a + 16:a + 16 + n])
    verbs, v = [], a + 16 + n
    while mem[v] != 0xFF:
        verbs.append((mem[v], name(word(mem, v + 1))))
        v += 3
    return Thing(id=i, holder=mem[a + 1], weight=mem[a + 2], size=mem[a + 3], state=mem[a + 4],
                 strength=mem[a + 5], defence=mem[a + 6], flags=mem[a + 7],
                 names=[word(mem, a + 8), word(mem, a + 10), word(mem, a + 12)],
                 description=name(word(mem, a + 14)), places=places, verbs=verbs)


def decode(mem, border=0):
    """The stage 4 state in stage 3's memory (`mem`: 64K, as zx.mem)."""
    record_starts(mem)
    prog, behaviour, index = program(mem)
    things, a = [], L.ObjectTable
    while mem[a] != 0xFF:
        things.append(thing(mem, mem[a], word(mem, a + 1)))
        a += 3
    npcs = []
    for k in range(17):
        r = L.NpcStates + 7 * k
        npcs.append(Npc(id=mem[r], max_random=mem[r + 1],
                        script=index.get(word(mem, r + 2)) if word(mem, r + 2) else None,
                        table=name(word(mem, r + 4)), obedience=mem[r + 6]))
    timers = []
    for k in range(10):
        r = L.Timers + 7 * k
        timers.append(Timer(start=mem[r], counter=mem[r + 1], fire=name(word(mem, r + 2)),
                            threshold=mem[r + 4], tick=name(word(mem, r + 5))))
    orders = []
    for k in range(8):
        r = L.OrderSlots + 25 * k
        orders.append(Order(owner=mem[r], phrase=Phrase([word(mem, r + 1 + 2 * j) for j in range(12)])))
    w = lambda lab: word(mem, getattr(L, lab))          # noqa: E731
    b = lambda lab: mem[getattr(L, lab)]                # noqa: E731
    blocked = (word(mem, L.SmcBlockedExit + 2) - L.BlockedExits) // L.BLOCKED_EXIT_SIZE \
        if word(mem, L.SmcBlockedExit + 2) else None
    v = Vars(
        random_event=(w('RandomEventPtr') - L.RandomEvents) // 4 if w('RandomEventPtr') else None,
        timers_fired=b('TimersFired'), exit_restore_mode=b('ExitRestoreMode'),
        printer_on=b('PrinterFlag'), arrival_location=b('ArrivalLocation'),
        actor_has_order=b('ActorHasOrder'), player_location=b('PlayerLocation'),
        actor_location=b('ActorLocation'), score=w('Score'), reply_given=b('ReplyGiven'),
        action_perform=b('ActionPerform'), action_allowed=b('ActionAllowed'),
        weapon_name=w('TargetNamePtr'), noun1_kind=b('Noun1Kind'),
        noun2_kind=b('Noun2Kind'), lisp=b('LispFlag'), raw_output=b('RawOutputFlag'),
        messages_visible=b('MessagesVisible'), phrase_mode=b('PhraseMode'),
        capital_next=b('CapitalNext'), parser_flag=b('ParserFlag'),
        parser_word_count=b('ParserWordCount'), pictures_enabled=b('PicturesEnabled'),
        noun1=which(w('Noun1Record')), noun2=which(w('Noun2Record')),
        actor=which(w('ActorRecord'))[1], random_seed=b('RandomSeed'),
        all_active=b('AllActive'), all_mode=b('AllMode'), needs_light=b('NeedsLight'),
        all_stage=b('AllStage'), awaiting_answer=b('AwaitingAnswer'),
        input_from_order=b('InputFromOrder'), verb_all_flag=b('VerbAllFlag'),
        command_flags=(b('StateB71D'), b('StateB71E')),
        take_destination=which(w('TakeObject'))[1] if w('TakeObject') else None,
        take_id=b('TakeId'), take_weight=b('TakeWeight'), npc_failures=b('NpcFailures'),
        sight_state=b('SightState'), first_object_place=b('FirstObjectPlace'),
        move_flag=b('MoveFlag'), blocked_exit=blocked, command=b('CommandId'),
        first_object=b('FirstObject'), second_object=b('SecondObject'), subject=b('Subject'),
        subj_is_in=(mem[L.MsgSubjIsIn + 1] & 15) << 8 | mem[L.MsgSubjIsIn + 2],
        it=[word(mem, L.PhraseBuffer + 2 * j) for j in range(3)], saved_command=b('SavedCommandId'))
    t = Terminal(story_column=b('StoryColumn'), story_cursor=w('StoryCursor') & 0x1F,
                 story_pixel=b('StoryCursorPixel'), list_indent=b('ListIndent'),
                 story_last_char=b('StoryLastChar'), input_column=b('InputColumn'),
                 input_cursor=w('InputCursor') & 0x1F, input_glyph=b('InputCursorGlyph'),
                 no_pause_lines=b('NoPauseLines'))
    pic5 = word(mem, L.PictureTable + 3 * [mem[L.PictureTable + 3 * k] for k in range(22)].index(5) + 1)
    screen = Display()
    screen.data[:] = bytes(mem[0x4000:0x5B00])
    screen.border = border
    return GameState(
        vars=v, locations=[location(mem, i) for i in range(80)], things=things, npcs=npcs,
        timers=timers, program=prog, orders=orders, order_count=b('OrderSlotCount'),
        question=Phrase([word(mem, L.PhraseRecord0 + 2 * j) for j in range(12)])
        if b('AwaitingAnswer') else None,
        parsed_words=list(mem[L.ParsedWords:L.ParsedWords + 64]),
        picture5=(mem[pic5], mem[pic5 + 1]), terminal=t, screen=screen)
