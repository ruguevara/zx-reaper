"""Stage 3 parser.py and system.py -> stage 4 hobbit/parser.py and
hobbit/system.py, for bridge/oracle.py routine.

The parser's work areas are stage 3 memory, not state: the phrase stack,
RecWork to RecPtr3, the word list position, PhraseBuffer (IT), SavedCommandId.
The stage 3 routines checked here are wrapped (transparently) so that their
memory before the call is noted, and the stage 4 routine gets s.scratch built
from it (a clean function here takes it first). The results compared include
the work values the routine leaves (records, the scan), read from stage 3
memory after the call. The special words continue the parse to its end; they
are run from the parser's registers at the call (D, E, BC, IY, the slots...)."""
import functools
import inspect

import paths  # noqa: F401
import labels as L
import parser as port_parser
import system as port_system
from routines import ANY, none, nothing
from routines_world import exit_cursor
from hobbit import parser as P
from hobbit.state import Phrase
from zxpyxel import zx

RECORDS = (L.PhraseRecord0 - L.PhraseStack) // L.PARSED_RECORD_SIZE + 1
_before = {}            # routine name -> (memory, stage 3 _order_pass) before its last call
_last = {}              # values the clean run leaves for convert_out


def w(m, a):
    return m[a] | m[a + 1] << 8


def ws(m, a, n):
    return [w(m, a + 2 * j) for j in range(n)]


def record_index(iy):
    return (L.PhraseRecord0 - iy) // L.PARSED_RECORD_SIZE


def cursor(ptr):
    """RecPtr1/2 as a cursor: an index into the things (the object table) or
    into the exits of a location."""
    if ptr >= L.ObjectTable - 3:
        return (ptr - L.ObjectTable) // 3
    if ptr >= L.Loc00None:
        return exit_cursor(ptr)
    return -1


def scan(m):
    return P.Scan(words=ws(m, L.RecWord1, 3), command=(w(m, L.RecPtr3) - L.CommandTable) // 8 + 1,
                  all_word=m[L.RecWork4], take_first=m[L.RecWork5], offsets=[m[L.RecWork6], m[L.RecWork6 + 1]],
                  has1=m[L.RecWork], has2=m[L.RecWork1], seen1=m[L.RecWork2],
                  kept=[m[L.RecWork3], m[L.RecWork3 + 1]], phrase1=ws(m, L.RecBuf1, 3),
                  phrase2=ws(m, L.RecBuf2, 3), last=[m[L.RecWork7], m[L.RecWork8]],
                  cursor1=cursor(w(m, L.RecPtr1)), cursor2=cursor(w(m, L.RecPtr2)))


def scratch(m):
    return {'phrases': P.Stack({k: ws(m, L.PhraseRecord0 - L.PARSED_RECORD_SIZE * k, 12) for k in range(RECORDS)}),
            'scan': scan(m), 'it': ws(m, L.PhraseBuffer, 3), 'saved_command': m[L.SavedCommandId],
            'word_pos': w(m, L.WordListPtr) - L.ParsedWords}


def before(name):
    return _before[name][0]


def with_scratch(name, f):
    """f(s, *args) with s.scratch from stage 3 memory before the call."""
    def clean(s, *args):
        s.scratch.update(scratch(before(name)))
        return f(s, *args)
    return clean


# ---- the parse

def parse_line(s):
    s.scratch.update(scratch(before('ParseLine')))
    result = yield from P.parse_line(s)
    stack = s.scratch['phrases']
    keys = _last['keys'] = sorted(k for k in stack if k >= 0)
    if isinstance(result, str):
        return result
    return result, s.scratch['word_pos'], [stack[k] if k != keys[-1] else stack[k][:1] for k in keys]


def parse_line_out(regs):
    m, keys = zx.mem, _last['keys']
    recs = [ws(m, L.PhraseRecord0 - L.PARSED_RECORD_SIZE * k, 12) for k in keys]
    return regs.zf, w(m, L.WordListPtr) - L.ParsedWords, [r if k != keys[-1] else r[:1] for k, r in zip(keys, recs)]


def special(name, handler):
    """A special word's handler run from the parser's registers at the call,
    to the end of the parse."""
    def clean(s):
        m, order_pass = _before[name]
        s.scratch.update(scratch(m))
        p = P._Parser(s, s.scratch['phrases'])
        regs = _last['regs']
        vars(p).update(
            k=record_index(regs.iy), e=regs.e, d=regs.d, word=regs.bc, slots=ws(m, L.ActionSlots, 5),
            preps=m[L.ActionFlag], word_flags=m[L.WordFlags], token=w(m, L.InputLinePtr) - L.ParsedWords,
            saved=(w(m, L.SavedHL) - L.ParsedWords, m[L.SavedA1], record_index(w(m, L.SavedIY)), m[L.SavedA2]),
            order_pass=[(record_index(iy), bc, de & 0xFF, m[L.PicVar2], m[L.PicVar3]) for iy, bc, de in order_pass])
        return p.run(lambda: handler(p))
    return clean


def keep_regs(regs):
    _last['regs'] = regs
    return ()


# ---- matching

def match_command(s, rec):
    s.scratch.update(scratch(before('MatchCommand')))
    cmd = yield from P.match_command(s, rec)
    m = s.scratch['scan']
    return cmd, m.words, m.phrase1, m.phrase2, m.offsets, m.has1, m.has2, s.scratch['it']


def match_command_out(regs):
    m = zx.mem
    return (0 if regs.zf else (regs.ix - L.CommandTable) // 8 + 1, ws(m, L.RecWord1, 3), ws(m, L.RecBuf1, 3),
            ws(m, L.RecBuf2, 3), [m[L.RecWork6], m[L.RecWork6 + 1]], m[L.RecWork], m[L.RecWork1],
            ws(m, L.PhraseBuffer, 3))


def resolve_nouns(s):
    s.scratch.update(scratch(before('ResolveNouns')))
    found = yield from P.resolve_nouns(s)
    m = s.scratch['scan']
    return found, m.kept, m.last, m.seen1, m.has1, m.has2, m.cursor1, m.cursor2


def resolve_nouns_out(regs):
    m = zx.mem
    return (regs.zf, [m[L.RecWork3], m[L.RecWork3 + 1]], [m[L.RecWork7], m[L.RecWork8]], m[L.RecWork2],
            m[L.RecWork], m[L.RecWork1], cursor(w(m, L.RecPtr1)), cursor(w(m, L.RecPtr2)))


def run_stored_order(s, run):
    s.scratch.update(scratch(before('RunStoredOrder')))
    m = before('RunStoredOrder')
    _last['slot'] = next((k for k in range(L.ORDER_SLOTS)
                          if m[L.OrderSlots + L.ORDER_SLOT_SIZE * k] == m[L.Subject]), None)
    return (yield from P.run_stored_order(s, run))


def run_stored_order_out(regs):
    k = _last['slot']
    phrase = None if k is None else Phrase(ws(zx.mem, L.OrderSlots + L.ORDER_SLOT_SIZE * k + 1, 12))
    return not regs.zf, phrase


ROUTINES = {
    'ParseLine': (parse_line, none, parse_line_out),
    'PrintWhat': (P.print_what, none, lambda regs: ANY),
    'RunSentences': (with_scratch('RunSentences', P.run_sentences), none, nothing),
    'MatchCommand': (match_command, lambda regs: (ws(before('MatchCommand'), regs.iy, 12),), match_command_out),
    'ResolveNouns': (resolve_nouns, none, resolve_nouns_out),
    'TestActorCommand': (with_scratch('TestActorCommand', P.test_actor_command), none, lambda regs: not regs.zf),
    'RunStoredOrder': (run_stored_order, lambda regs: (regs.a != 0,), run_stored_order_out),
    'ClaimOrderSlots': (P.claim_order_slots, lambda regs: (regs.a,), nothing),
    'FindOrderSlot': (P.find_order_slot, none,
                      lambda regs: (regs.hl - L.OrderSlots) // L.ORDER_SLOT_SIZE if regs.zf else None),
    'FindOrderSlotKeep': (lambda s: P.find_order_slot(s) is not None, none, lambda regs: regs.zf),
    'FreeOrderSlots': (P.free_order_slots, lambda regs: (regs.a,), nothing),
}


# ---- the memory before each call of these routines

def _note(name, f):
    if inspect.iscoroutinefunction(f):
        @functools.wraps(f)
        async def wrapper(*args):
            m = bytes(zx.mem), list(port_system._order_pass)
            try:
                return await f(*args)
            finally:
                _before[name] = m       # the call the oracle compares next is the last one ended
        return wrapper
    return f


def note(module, names):
    """Wrap the routines `names` of a stage 3 module so that their memory is noted."""
    for name in names:
        f = getattr(module, name)
        if f.__module__ == module.__name__:
            setattr(module, name, _note(name, f))


note(port_parser, ROUTINES)
