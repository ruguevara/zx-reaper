"""Stage 3 keys.py -> stage 4 hobbit/words.py, for bridge/oracle.py routine.

The typed line is the buffer at InputLine (128 bytes and its carriage return),
positions are offsets in it. WaitKey is not checked here: the oracle notes its
key after the call returns (it is checked through the line editor)."""
import paths  # noqa: F401
import labels as L
from routines import ANY, none
from zxpyxel import mem
from hobbit import words as W

LINE = 129


def line():
    return bytearray(mem[L.InputLine:L.InputLine + LINE])


def word16(a):
    return mem[a] | mem[a + 1] << 8


def letters(a, n):
    return ''.join(chr(0x60 | mem[a + k] & 0x1F) for k in range(n))


class Implied:
    """Equal to a bool b unless b is True and PhraseMatched is 0 after the call
    (the routine only ever sets it)."""
    def __init__(self, after):
        self.after = after

    def __eq__(self, b):
        return not b or bool(self.after)

    def __repr__(self):
        return 'True if PhraseMatched (%d) else False' % self.after


def match_out(regs):
    return regs.zf, regs.zf and regs.a == 1, Implied(mem[L.PhraseMatched])


ROUTINES = {
    'ReadTypedWord': (W.read_typed_word, lambda regs: (line(), regs.hl - L.InputLine),
                      lambda regs: (regs.bc, regs.hl - L.InputLine, word16(L.InputLinePtr) - L.InputLine)),
    'CompareWords': (W.compare_words,
                     lambda regs: (letters(L.WordLetters, mem[L.WordLength]),
                                   letters(L.MatchLetters, mem[L.MatchLength])),
                     lambda regs: regs.zf),
    'MatchWord': (W.match_word, lambda regs: (word16(regs.hl), word16(regs.iy)), lambda regs: regs.zf),
    'MatchCommandRecord': (W.match_command_record,
                           lambda regs: ([word16(regs.iy + 2 * k) for k in range(3)],
                                         [word16(regs.hl + 2 * k) for k in range(3)]),
                           match_out),
    'PackCommandFlags': (W.pack_command_flags, lambda regs: ([word16(regs.ix + 2 * k) for k in range(4)],),
                         lambda regs: regs.a),
    'CommandRecordAddr': (lambda s, id: W.command(id), lambda regs: (regs.a,),
                          lambda regs: [word16(regs.hl + 2 * k) for k in range(4)]),
    'CursorKeyToWord': (W.cursor_key_to_word, lambda regs: (regs.a, line(), regs.hl - L.InputLine),
                        lambda regs: (regs.a, regs.hl - L.InputLine)),
    'L6E7A': (W.l6e7a, none, lambda regs: regs.zf and regs.a == 0),
    'EraseInputLine': (W.erase_input_line, lambda regs: (0x80 - regs.b,), lambda regs: 0),
    'ClearScreen': (W.clear_screen, none, lambda regs: ANY),
}
