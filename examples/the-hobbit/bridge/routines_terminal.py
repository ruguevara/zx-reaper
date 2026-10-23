"""Stage 3 screen.py and devices.py -> stage 4 hobbit/terminal.py, for
bridge/oracle.py routine.

Stage 3 draws a character through private helpers (_put_story_char,
_put_input_char), not through PrintStoryChar and PrintInputChar; while one of
those two is checked, the helper goes through the routine (its registers
kept), so that every character drawn is a call the oracle checks."""
import sys

import paths  # noqa: F401
import labels as L
import screen as port_screen
from regs import r
from routines import ANY, none
from hobbit import terminal as T


def checking(name):
    """True when the oracle's command line checks routine `name`."""
    return any(a == 'all' or name in a.split(',') for a in sys.argv[1:])


def keep_registers(f):
    """Call f() with every register (the alternate set too) given back after."""
    saved = [getattr(r, n) for n in ('a', 'b', 'c', 'd', 'e', 'h', 'l', 'ix', 'iy', 'zf', 'cf', 'sf', 'pf')]
    alt, alt_af = list(r.alt), list(r.alt_af)
    try:
        return f()
    finally:
        for n, v in zip(('a', 'b', 'c', 'd', 'e', 'h', 'l', 'ix', 'iy', 'zf', 'cf', 'sf', 'pf'), saved):
            setattr(r, n, v)
        r.alt, r.alt_af = alt, alt_af


def through(helper, routine, set_regs, result):
    """Route stage 3's helper `helper` through the routine `routine`."""
    orig, busy = getattr(port_screen, helper), [False]

    def call(*args):
        if busy[0]:
            return orig(*args)

        def run():
            busy[0] = True
            try:
                set_regs(*args)
                getattr(port_screen, routine)()
                return result()
            finally:
                busy[0] = False
        return keep_registers(run)
    setattr(port_screen, helper, call)


def story_col(hl):
    if not L.STORY_LAST_ROW <= hl <= L.STORY_LAST_ROW + 32:
        raise AssertionError('a story character at $%04X, not on the story line' % hl)
    return hl - L.STORY_LAST_ROW


def input_col(hl):
    col = hl - L.SCREEN_ROW_23 & 0xFF
    if hl >> 8 != L.SCREEN_ROW_23 >> 8 or col > 32:
        raise AssertionError('an input character at $%04X, not on the input line' % hl)
    return col


if checking('PrintStoryChar'):
    def _story(code, hl, c):
        r.a, r.hl, r.c = code, hl, c
    through('_put_story_char', 'PrintStoryChar', _story, lambda: (r.hl, r.c))
if checking('PrintInputChar'):
    def _input(code, hl):
        r.a, r.hl = code, hl
    through('_put_input_char', 'PrintInputChar', _input, lambda: r.hl)


ROUTINES = {
    'PrintChar': (T.put_char, lambda regs: (regs.a,), lambda regs: ANY),
    'PrintNewLine': (T.new_line, none, lambda regs: ANY),
    'OutputStoryChar': (T.output_story_char, lambda regs: (regs.a,), lambda regs: ANY),
    'PrintStoryChar': (T.print_story_char, lambda regs: (regs.a, story_col(regs.hl), regs.c),
                       lambda regs: (story_col(regs.hl), regs.c)),
    'ScrollStoryUp': (T.scroll_story_up, none, lambda regs: ANY),
    'PrintStoryLine': (T.print_story_line, none, lambda regs: ANY),
    'PrintInputWindowChar': (T.print_input_window_char, lambda regs: (regs.a,), lambda regs: ANY),
    'PrintInputChar': (T.print_input_char, lambda regs: (regs.a, input_col(regs.hl)),
                       lambda regs: input_col(regs.hl)),
    'ScrollInputUp': (T.scroll_input_up, none, lambda regs: ANY),
    'ScrollInputDown': (T.scroll_input_down, none, lambda regs: ANY),
}
