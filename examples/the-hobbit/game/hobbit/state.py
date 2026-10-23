"""The state of The Hobbit as plain values (stage 4).

What the game keeps between two passes of its main loop, and nothing else:
locations, objects and characters, the characters' script positions, the
timers, the orders given with SAY TO, the variables, and the screen. No
addresses: records are referred to by id, messages, handlers, scripts and
behaviour tables by name, words by their offset in the dictionary (an index
into the data, see assets), pictures by location id.

Phrase codes (the names of locations and things, the words of a parsed
phrase) are ints as the original keeps them: bits 0-11 the dictionary offset
of a word, bits 12-15 its flags.
"""
from dataclasses import dataclass, field

from zxpyxel.display import Display

AT_LOCATION = 0xFF          # Thing.holder of a thing that lies at its place(s)


@dataclass
class Exit:
    direction: int          # 1-10: N S E W NE NW SE SW up down; 0 for the blocked exit
    obstacle: int           # a thing id (door, river, web...) or 0
    destination: int        # a location id


@dataclass
class Location:
    id: int
    flags: int              # bit 7 lit, bit 6 visited, bits 1-3 the preposition (in, on, at...)
    capacity: int           # room for things ($FF unlimited)
    names: list             # 3 phrase codes: noun, adjective, adjective
    description: str | None   # message name; None: the name phrase is printed
    exits: list             # Exit, in the record's order


@dataclass
class Thing:
    """An object or a character (ids $3C-$4C) or the player (id 0)."""
    id: int
    holder: int             # the id of what holds it, or AT_LOCATION
    weight: int
    size: int
    state: int              # bits 0-3 the relation message (in, on, behind...), 4-6 a side
    strength: int           # +5: attack
    defence: int            # +6
    flags: int              # bit 7 present, 6 character, 5 active/open/alive, 3 dead,
                            # 1 liquid, 0 locked
    names: list             # 3 phrase codes
    description: str | None   # message name printed by EXAMINE, or None
    places: list            # location ids (1 for a thing that moves; 2+ for doors, rivers)
    verbs: list             # (verb id, handler name or None); verb id 0 chains to the next


@dataclass
class Npc:
    """A character's turn record ($CACB); id 0 is a dormant slot an event fills."""
    id: int
    max_random: int         # the highest random entry of its behaviour table
    script: int | None      # index in the script program of its current command
    table: str | None       # its behaviour table's name
    obedience: int          # 0 obeys no orders


@dataclass
class Timer:
    start: int              # the value a starter copies into the counter
    counter: int
    fire: str | None        # handler name, run when the counter reaches 0
    threshold: int
    tick: str | None        # handler name, run while 0 < counter <= threshold


@dataclass
class Command:
    """One command of the NPC script program (format: docs/05-characters.md).
    The commands of all scripts form one program, run on from one script into
    the next as in the original; positions are indices into it."""
    op: int                 # the command byte: bits 0-3 the operation, 4 an alternative
                            # follows, 5 erase after success, 6 orders do not replace it
    args: list              # its argument bytes as the original keeps them (a verb and
                            # objects, a behaviour id, a random range; for ops 1 and 3
                            # the routine's address bytes, which an erased command runs as
                            # a verb and objects: a quirk kept)
    routine: str | None = None     # ops 1 and 3: the handler run
    target: int | None = None      # op E: the command index jumped to
    alternative: int | None = None # bit 4: the command index taken on failure


@dataclass
class Phrase:
    """A parsed phrase record: 12 words (24 bytes) as the parser leaves them:
    +0 the first command word (its high byte: bit 7 ALL, bit 6 an EXCEPT record),
    +2 the second command word, +4 block A and +$0E block B (prepositions, noun,
    adjectives each)."""
    words: list             # 12 ints


@dataclass
class Order:
    owner: int              # the character it is for; 0 free, $FF being filled
    phrase: Phrase


@dataclass
class Terminal:
    """The two text windows' cursors and the printing flags."""
    story_column: int       # characters left on the story line
    story_cursor: int       # cell column of the story cursor on the story line
    story_pixel: int        # pixel offset of the cursor within its cell
    list_indent: int        # spaces printed at the start of an empty line
    story_last_char: int    # the last character printed on the line, 0 = empty line
    input_column: int
    input_cursor: int       # cell column of the input cursor on the bottom row
    input_glyph: int        # the cursor's character
    no_pause_lines: int     # story lines that scroll without the pause


@dataclass
class Vars:
    """The variables (the saved block at $B6EB and the run-time ones after it)."""
    random_event: int       # the random event chosen at the start (index into the table)
    timers_fired: int
    exit_restore_mode: int
    printer_on: int
    arrival_location: int
    actor_has_order: int
    player_location: int
    actor_location: int
    score: int              # in tenths of a per cent
    reply_given: int
    action_perform: int     # 0: a test pass, 1: do it
    action_allowed: int
    weapon_name: int        # the phrase code of the weapon in a fight (or "fist") for its messages
    noun1_kind: int
    noun2_kind: int
    lisp: int
    raw_output: int         # 1: text goes to the input window
    messages_visible: int
    phrase_mode: int
    capital_next: int
    parser_flag: int
    parser_word_count: int
    pictures_enabled: int
    noun1: tuple | None     # ('thing'|'location', id)
    noun2: tuple | None
    actor: int              # the thing id whose turn it is
    random_seed: int
    all_active: int
    all_mode: int
    needs_light: int
    all_stage: int
    awaiting_answer: int
    input_from_order: int
    verb_all_flag: int
    command_flags: tuple    # (StateB71D, StateB71E)
    take_destination: int | None   # the location id the last move went to (TakeObject)
    take_id: int
    take_weight: int
    npc_failures: int
    sight_state: int
    first_object_place: int
    move_flag: int
    blocked_exit: int       # which of the 5 blocked-exit records the game removed
    command: int            # CommandId: the matched command record (1-59)
    first_object: int
    second_object: int
    subject: int


@dataclass
class GameState:
    vars: Vars
    locations: list         # Location, by id (0-79)
    things: list            # Thing, in the original's table order
    npcs: list              # Npc, 17
    timers: list            # Timer, 10
    program: list           # Command: the NPC scripts (they change: commands are erased, rewritten)
    orders: list            # Order, 8
    order_count: int
    question: Phrase | None     # the phrase a "Which ...?" question waits to complete
    parsed_words: list      # the last line's 32 token pairs (tag, word), for "@"
    picture5: tuple         # the border and attribute bytes of picture 5 (dawn rewrites them)
    terminal: Terminal
    screen: Display = field(default_factory=Display)


# Events: a routine that needs something from outside, or that holds the game,
# is a generator; it yields these and its callers `yield from` it. The driver
# (the pacer in play, the oracle in the checks) answers the requests by
# send(): ReadKey, ReadR and Mixed get an int, TapeLoad a saved state or None;
# the others get None.

@dataclass
class ReadKey:
    """The line editor wants the next key code (a character, CR, a cursor or
    delete code; the idle time-out types W, A, I, T, CR as keys)."""


@dataclass
class ReadR:
    """The refresh register at a (re)start: the random seed."""


@dataclass
class Mixed:
    """The random routine's mixed value: the original mixes its seed with bytes
    read anywhere in memory (code and the Z80's stack included), which the clean
    game does not have; in play a stand-in generator answers."""


@dataclass
class WaitKey:
    """The game waits for any key (after a picture, PAUSE, the end of a game)."""


@dataclass
class ScrollPause:
    """A story line scrolled: the original pauses about 0.6 s here unless a key
    is pressed, and holds while a key is held."""


@dataclass
class Show:
    """Hold the screen as it is for `seconds` (time the original spends)."""
    seconds: float


@dataclass
class Printed:
    """A line of the story window copied to the printer (PRINT): the presentation
    appends it to the transcript file."""
    text: str


@dataclass
class TapeSave:
    """SAVE: the presentation writes the state to a file."""


@dataclass
class TapeLoad:
    """LOAD: answered with a saved state, or None when there is none (the
    original then waits for a tape forever)."""


@dataclass
class Step:
    """The top of the main loop: a pass is over (the checks compare here)."""
