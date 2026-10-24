"""The special words (stage 3: system.py; src/system.asm): ALL, EXCEPT, IT,
ONE, the quotes around an order (SAY TO), PRINT, NOPRINT, QUIT, HELP, SCORE,
PAUSE, SAVE and LOAD, and the score. The words are word-class handlers of
the parse: each takes the parse (parser._Parser) and returns its next step
(or the parse's result: 'RestartGame' after QUIT)."""
import functools

from . import assets, parser as P, terminal, text, world
from .state import Show, TapeLoad, TapeSave, WaitKey

# The ZX printer answers PRINT (bit 6 of port $FB clear); the records were made
# with none (an open bus reads $FF: PRINT does nothing). True sends the story
# to the transcript (Printed events).
PRINTER_ATTACHED = False
BORDER_GREEN, BORDER_WHITE = 4, 7
BARD_ORDER_TIMER = 'LA814_8'    # the script command after the one running it is the Bard's order


@functools.lru_cache(None)
def _hints():
    """tables.json 'hints': location id -> the hint's message."""
    return {loc: message for loc, message in assets.load_json('tables.json')['hints']}


def dispatch_special_word(p):
    """Run the handler of a class 9 word; a word with none starts a new
    record (never seen). (stage 3: DispatchSpecialWord)"""
    handler = SPECIAL.get(p.word)
    if handler is None:
        p.d = 0                         # (the asm's table counter, run out)
        return p.start_phrase_record
    return handler(p)


def resume_dispatch(p):
    """Read on, with the class of the word before the special word.
    (stage 3: ResumeDispatch)"""
    p.d = p.word_flags
    return p.parse_next_word


def word_all(p):
    """ALL, EVERYTHING: the ALL stage, unless EXCEPT was seen. (stage 3: WordAll)"""
    if p.v.all_stage != P.ALL_STATE_EXCEPT:
        p.v.all_stage = P.ALL_STATE_ALL
    return p.parse_next_word


def word_except(p):
    """EXCEPT, BUT: only after ALL ("What ?" otherwise); the record is
    flagged ALL. (stage 3: WordExcept)"""
    if p.v.all_stage != P.ALL_STATE_ALL:
        return p.reject_line
    p.v.all_stage = P.ALL_STATE_EXCEPT
    p.rec[0] |= P.RECF_ALL
    return p.parse_next_word


def l82e2(p):
    """IT: the last first noun phrase (s.scratch['it']) as a noun phrase. It
    goes into block A while block B is free, else over block B (quirk: "put
    the map in it" loses its "in"). (stage 3: L82E2)"""
    p.slots[2:5] = p.s.scratch.get('it', [0, 0, 0])
    p.store_block(P.BLOCK_A if p.e & P.PF_BLOCK_B_FREE else P.BLOCK_B)
    return p.parse_next_word


def word_print(p):
    """PRINT: the story is copied to the printer, if one answers. (stage 3: WordPrint)"""
    if PRINTER_ATTACHED:
        p.v.printer_on = 1
    return resume_dispatch(p)


def l82af(p):
    """NOPRINT. (stage 3: L82AF)"""
    p.v.printer_on = 0
    return resume_dispatch(p)


def begin_order_pass(p):
    """An opening quote: parse the order's text as records after the one being
    built (the outer parse's place kept). (stage 3: BeginOrderPass)"""
    p.order_pass.append((p.k, p.word, p.e, p.d, p.v.parser_word_count))
    p.k += 1
    return p.parse_line_from(True)


def store_parsed_orders(p):
    """A quote: an opening one starts the order's pass (begin_order_pass); a
    closing one ends it: the order's records go into free order slots as
    pending (an EXCEPT record takes a slot, is freed again and still counted),
    while there are free slots; s.order_count is how many were taken. Then
    the outer parse goes on. (stage 3: StoreParsedOrders)"""
    s, v = p.s, p.v
    if not v.input_from_order:
        return begin_order_pass(p)
    v.input_from_order = 0
    k, word, e, d, count = p.order_pass.pop()
    n, taken, j = v.parser_word_count - count & 0xFF, 0, k + 1
    while n:
        slot = next((o for o in s.orders if not o.owner), None)
        if slot is None:
            break                       # (the asm marks the byte after the table)
        rec = p.stack[j]
        if not rec[0] & P.RECF_EXCEPT:
            slot.owner = P.ORDER_PENDING
            slot.phrase.words[:] = rec
        j, taken, n = j + 1, taken + 1, n - 1
    v.all_stage = 0
    s.order_count = taken
    p.k, p.word, p.e, p.d, v.parser_word_count = k, word, e, d, count
    return p.parse_next_word


def word_quit(p):
    """QUIT: the score, a key, the game again. (stage 3: WordQuit)"""
    yield from print_score(p.s)
    yield WaitKey()
    return 'RestartGame'


def word_help(p):
    """HELP: for the player (others read on) the hint for the player's
    location, or "You're doing fine.", in the input window. (stage 3: WordHelp)"""
    s, v = p.s, p.v
    if v.subject:
        return p.parse_next_word
    v.raw_output = 1
    yield from text.print_message(s, _hints().get(world.thing(s, world.PLAYER).places[0], 'MsgReDoingFine'))
    return resume_dispatch(p)


def l83ef(p):
    """SCORE. (stage 3: L83EF)"""
    yield from print_score(p.s)
    return resume_dispatch(p)


def word_pause(p):
    """PAUSE: a green border until a key (the original then waits for the keys
    to be let go: no event), white again. (stage 3: WordPause)"""
    p.s.screen.border = BORDER_GREEN
    yield WaitKey()
    p.s.screen.border = BORDER_WHITE
    return resume_dispatch(p)


def _saved(s):
    """What SAVE writes and LOAD reads: the things, the locations, the timers
    and characters, the saved variables (the four tape blocks)."""
    from .flow import SAVED_VARS
    return s.things, s.locations, s.timers, s.npcs, [getattr(s.vars, k) for k in SAVED_VARS]


def _bard_order(s):
    """The index of the Bard's order command in the script program (its first
    three bytes are saved with the variables)."""
    return next(i for i, c in enumerate(s.program) if c.routine == BARD_ORDER_TIMER) + 1


def _wait_for_tape():
    """No tape: the original waits for one forever."""
    while True:
        yield Show(1.0)


def save_game(p):
    """SAVE: "Start tape then press any key", the state saved, "Rewind and
    prepare tape for verification", then the verify: read back and compared,
    "Tape error - hit any key to continue" when it differs. (stage 3: SaveGame,
    VerifyBlock, SaveGame_End)"""
    s, v = p.s, p.v
    v.raw_output = 1
    yield from text.print_message(s, 'MsgStartTapeThenPressAny')
    yield WaitKey()
    yield TapeSave()
    yield from text.print_message(s, 'MsgRewindPrepareTapeFor')
    yield WaitKey()
    result = yield TapeLoad()
    if result is None:
        yield from _wait_for_tape()
    if _saved(result) != _saved(s):
        v.raw_output = 1
        yield from text.print_message(s, 'MsgTapeErrorHitAnyKey2')
        yield WaitKey()
    return resume_dispatch(p)


def load_game(p):
    """LOAD: the saved blocks replace the game's (things, locations, timers
    and characters, the saved variables) and the Bard's order its first three
    bytes (op, verb, first object); the rest (the scripts, the orders, the
    screen) stays. (stage 3: LoadGame, LoadBlock)"""
    s = p.s
    result = yield TapeLoad()
    if result is None:
        yield from _wait_for_tape()
    from .flow import SAVED_VARS
    s.things, s.locations, s.timers, s.npcs = result.things, result.locations, result.timers, result.npcs
    for k in SAVED_VARS:
        setattr(s.vars, k, getattr(result.vars, k))
    i = _bard_order(s)
    mine, saved = s.program[i], result.program[i]
    mine.op, mine.args[:2] = saved.op, saved.args[:2]
    return resume_dispatch(p)


def print_score(s):
    """"You have mastered nn.n% of this adventure." in the story window: the
    score in tenths of a per cent, the hundreds digit left out when 0.
    (stage 3: PrintScore)"""
    v = s.vars
    v.raw_output = 0
    yield from text.print_message(s, 'MsgHaveMastered')
    hundreds, rest = decimal_digit(v.score, 100)
    if hundreds != ord('0'):
        yield from terminal.put_char(s, hundreds)
    tens, rest = decimal_digit(rest, 10)
    for ch in (tens, ord('.'), rest + ord('0') & 0xFF):
        yield from terminal.put_char(s, ch)
    v.capital_next = 0
    yield from text.print_message(s, 'MsgThisAdventure')


def decimal_digit(value, divisor):
    """value // divisor as a digit's character code (past 9 the characters
    after "9", a score of 100% and more), and the remainder. (stage 3: DecimalDigit)"""
    q, rest = divmod(value, divisor)
    return ord('0') + q & 0xFF, rest


# ActionWordTable -> ActionHandlerTable: the class 9 words by dictionary offset
SPECIAL = {
    0x000: store_parsed_orders,         # the quote token
    0x04E: word_all,
    0x245: word_except,
    0x39E: l82e2,                       # it
    0x4AD: lambda p: p.parse_next_word,     # one: ignored
    0x4FB: word_print,
    0x479: l82af,                       # noprint
    0x3EE: load_game,
    0x580: save_game,
    0x518: word_quit,
    0x31E: word_help,
    0x58A: l83ef,                       # score
    0x4D8: word_pause,
}
