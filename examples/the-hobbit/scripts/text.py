#!/usr/bin/env python3
"""Decoder for the dictionary and the messages of The Hobbit (Melbourne House, v1.2, 48K).

Standard library only, except that a .z80 snapshot is read with SkoolKit.

  text.py [-i IMAGE] words            the vocabulary: offset, class, word, suffix, synonym
  text.py [-i IMAGE] msg ADDR...      one message (hex address); follows jumps and calls
  text.py [-i IMAGE] all              every message in $AD7D-$B6D9 with its address range
  text.py [-i IMAGE] verbs            the command table at $AB53
  text.py --selftest                  a few known messages and words

Formats (all found by reading $72DD/$74C1/$6F47 and checked against the running game):

Dictionary, $6000-$6BED
  $6000: 27 words, index by first letter (1 = A ... 26 = Z; entry 0 unused): the offset
  (from $6000) of the first word that starts with that letter.  The words follow from
  $6040, grouped by first letter (the parsed vocabulary), then, from $07AC, a second
  group of words that only messages use (no index, class 0).  A word is a run of bytes:
    bits 0-4  letter (1 = A ... 26 = Z, 0 = padding, ends the printed word)
    bit 7     last byte of the word, but ignored in byte 2, and in byte 3 when byte 2 has it
              (byte 2 bit 7 = "this word takes a suffix", byte 3 bits 5-7 = which one)
    bit 6 of the last byte: two more bytes follow, a synonym: offset of the entry it means
    bits 5-6 of byte 1 and of byte 2 together: the class 0-15 (f0*4+f1)
  A word is addressed by its offset ($000-$BFF), that is how messages name it.

Messages, from $AD7D
  $20-$5F  a letter or sign, printed as it is (capitals show as lower case; the first
           letter of a sentence is capital)
  $60-$7F  a common word: 16-bit entry (index byte-$60) in the table at $AD3D, high
           nibble implied 5
  $80-$FF  two bytes: bit 7 marks a word; bits 4-6 of the first byte are the print mode
           (0 plain, 1 suffix if the object is not you, 4 suffix always, 5 never,
           7 capital letter, 2/3/6 last word of the message: 2 nothing, 3 full stop + new
           line, 6 new line); bits 0-3 and the second byte are the word's offset
  $00-$16  control codes through the table at $7295 (see CODES); 2 and 11 take a byte
  $14 new line, $15 full stop + new line, $16 nothing: end the message
A word is printed after a space (not at the start of a line); a suffix (table $B71F,
four bytes each: s es ies "<back>ies" d ing) is appended when the word has one.
"""
import sys

DICT = 0x6000
DICT_END = 0x6BEE
WORD_TABLE = 0xAD3D       # 32 common words, bytes $60-$7F
MSG_START = 0xAD7D
MSG_END = 0xB6DA          # first address after the last message
VERBS = 0xAB53            # 8-byte command records, ends with a zero word
SUFFIXES = ['s', 'es', 'ies', '\bies', 'd', 'ing', '', '']   # $B71F, 4 bytes each

CLASSES = {0: 'other', 1: 'direction?', 2: 'direction', 3: 'verb', 4: 'verb(go/run)',
           5: 'noun', 6: 'adjective', 7: 'preposition', 8: 'article/aux',
           9: 'command/pronoun', 10: 'and', 11: 'then'}

# control codes: name used in the text when the value depends on the game state
CODES = {0: '{THING}', 1: '{WORD}', 3: '{WORD2}', 4: '{THE_ARG}', 6: '{SUBJ}',
         7: '{OBJ1}', 9: '{OBJ2}', 12: '{HIS_SUBJ}', 14: '{HIS_OBJ1}',
         16: '{SUBJ_IS}', 17: '{OBJ1_IS}', 19: '{ARG_IS}'}
NOOP = {5, 10, 15, 18}
END_CODES = {0x14: '\n', 0x15: '.\n', 0x16: ''}
END_MODES = {2: '', 3: '.\n', 6: '\n'}


def load(src='re/image.z80'):
    """64K memory as bytes from a .z80 file (through SkoolKit) or a bytes object."""
    if isinstance(src, (bytes, bytearray)):
        return bytes(src) if len(src) == 65536 else bytes(65536 - len(src)) + bytes(src)
    from skoolkit.snapshot import Snapshot
    return bytes(16384) + bytes(Snapshot.get(src).ram())


class Text:
    def __init__(self, mem):
        self.m = mem if isinstance(mem, (bytes, bytearray)) else load(mem)
        self._words = None

    # ---- dictionary -------------------------------------------------
    def word(self, off):
        """The printed letters of the word at offset OFF, in lower case."""
        m, p, n, out = self.m, DICT + off, 0, ''
        while True:
            x = m[p]
            if not x & 31:
                return out
            n += 1
            out += chr(96 + (x & 31))
            p += 1
            if not x & 0x80 or n == 2 or (n == 3 and m[p - 2] & 0x80):
                continue
            return out

    def words(self):
        """All words as dicts: offset, text, cls, suffix (index or None), synonym (offset
        or None), group (1 = indexed by first letter, 2 = only used by messages)."""
        if self._words is None:
            m, off, res = self.m, 0x40, []
            while off < DICT_END - DICT:
                p = DICT + off
                if m[p] == 0:               # padding between the two groups
                    off += 1
                    continue
                b, n = [], 0
                while True:
                    x = m[p + len(b)]
                    b.append(x)
                    n += 1
                    if x & 0x80 and not (n == 2 or (n == 3 and b[1] & 0x80)):
                        break
                syn = None
                if b[-1] & 0x40:
                    q = p + len(b)
                    syn = m[q] | m[q + 1] << 8
                res.append(dict(offset=off, text=self.word(off), raw=bytes(b),
                                cls=((b[0] >> 5) & 3) * 4 + ((b[1] >> 5) & 3),
                                suffix=(b[2] >> 5) if b[1] & 0x80 and len(b) > 2 else None,
                                synonym=syn, group=1 if off < 0x7A8 + 3 else 2))
                off += len(b) + (2 if syn is not None else 0)
            self._words = res
        return self._words

    def word_at(self, off):
        for w in self.words():
            if w['offset'] == off:
                return w
        return None

    # ---- messages ---------------------------------------------------
    def _token(self, p):
        """(mode, offset) of the two-byte word at P."""
        d, e = self.m[p] & 0x7F, self.m[p + 1]
        return d >> 4, (d & 15) << 8 | e

    def common(self, b):
        i = WORD_TABLE + (b - 0x60) * 2
        return (self.m[i + 1] & 15) << 8 | self.m[i]

    def step(self, p):
        """The item at P: (kind, value, next address).  kinds: ch (literal), cw (common
        word), tok (word with print mode), code (control code, with its byte if any)."""
        m, b = self.m, self.m[p]
        if b & 0x80:
            return 'tok', self._token(p), p + 2
        if b >= 0x60:
            return 'cw', (5, self.common(b)), p + 1
        if b >= 0x20:
            return 'ch', chr(b), p + 1
        if b in (2, 11):
            return 'code', (b, (m[p + 1] ^ 128) - 128), p + 2
        return 'code', (b, None), p + 1

    def parse(self, p):
        """Split the message at P into items (start, end, kind, value) up to its end."""
        items = []
        while True:
            kind, v, q = self.step(p)
            items.append((p, q, kind, v))
            if (kind == 'tok' and v[0] in END_MODES) or (kind == 'code' and v[0] in END_CODES):
                return items, q
            p = q

    def starts(self):
        """Start addresses of the messages from $AD7D, each ended by its terminator."""
        res, p = [], MSG_START
        while p < MSG_END:
            res.append(p)
            p = self.parse(p)[1]
        return res

    def render(self, addr, subj=0, obj1=0, names=None):
        """The text of the message at ADDR as the game prints it (one line, '\\n' where the
        game starts a new line, no word wrap).  SUBJ and OBJ1 are $B6EA and $B6E8: when
        non-zero the verbs get their suffix.  Codes that print game state come out as
        {SUBJ} and so on (CODES), or as NAMES[code] if given."""
        out = []
        st = dict(cap=True, line=False)

        def put(s):
            for c in s:
                if c == '\n':
                    out.append(c)
                    st.update(cap=True, line=False)
                elif c == '\b':
                    if out and out[-1] != '\n':
                        out.pop()
                else:
                    if c.isalpha() and st['cap']:
                        c, st['cap'] = c.upper(), False
                    elif c.isalpha():
                        c = c.lower()
                    out.append(c)
                    st['line'] = True
                    if c == '.':
                        st['cap'] = True

        def say(off, mode):
            if not off:                           # offset 0 is no word (74C1 returns)
                return
            w = self.word_at(off)
            text = self.word(off)
            if mode == 7:
                st['cap'] = True
            if st['line'] and out and out[-1] != '\n':
                put(' ')
            put(text)
            if w and w['suffix'] is not None:
                if mode == 4 or (mode == 1 and obj1) or (mode in (0, 2, 3, 6, 7) and subj):
                    put(SUFFIXES[w['suffix']])

        def run(p, depth):
            while True:
                kind, v, q = self.step(p)
                if kind == 'ch':
                    put(v)
                elif kind in ('tok', 'cw'):
                    say(v[1], v[0])
                    if kind == 'tok' and v[0] in END_MODES:
                        put(END_MODES[v[0]])
                        return
                else:
                    c, d = v
                    if c in END_CODES:
                        put(END_CODES[c])
                        return
                    if c == 2:                      # jump: relative to the parameter byte
                        q = p + 1 + d
                    elif c == 11 and depth < 20:    # call a message
                        run(p + 1 + d, depth + 1)
                    elif c == 13:                   # a line break that is not a sentence end
                        put('\n')
                        st['cap'] = False
                    elif c == 8:
                        put('\b')
                    elif c not in NOOP and c != 11:
                        if st['line']:
                            put(' ')
                        out.append((names or {}).get(c, CODES[c]))
                        st.update(line=True, cap=False)
                p = q

        run(addr, 0)
        return ''.join(out)

    # ---- command table ----------------------------------------------
    def verbs(self):
        """The 8-byte records at $AB53 (id = index + 1): four words.  Word 0 = the
        verb (dictionary offset in bits 0-11, flags in bits 12-15), 1 = the first
        preposition, 2 = the second one, 3 = flags (for the first ten: the verb GO)."""
        res, p = [], VERBS
        while self.m[p] | self.m[p + 1]:
            w = [self.m[p + 2 * k] | self.m[p + 2 * k + 1] << 8 for k in range(4)]
            res.append((p, w))
            p += 8
        return res


def main(argv):
    img = 're/image.z80'
    if argv[:1] == ['-i']:
        img, argv = argv[1], argv[2:]
    if argv[:1] == ['--selftest']:
        return selftest(img)
    t = Text(load(img))
    cmd, args = (argv or ['all'])[0], argv[1:]
    if cmd == 'words':
        for w in t.words():
            print('%04X %-2d %-13s %-14s %s %s' % (
                w['offset'], w['cls'], CLASSES.get(w['cls'], '?'), w['text'],
                '' if w['suffix'] is None else '+' + SUFFIXES[w['suffix']].replace('\b', '<'),
                '' if w['synonym'] is None else '=' + t.word(w['synonym'] & 0xFFF)))
    elif cmd == 'msg':
        for a in args:
            print('%s: %s' % (a, t.render(int(a, 16))))
    elif cmd == 'all':
        s = t.starts()
        for a, e in zip(s, s[1:] + [MSG_END]):
            print('%04X-%04X %s' % (a, e - 1, t.render(a).replace('\n', '\\n')))
    elif cmd == 'verbs':
        for i, (p, w) in enumerate(t.verbs(), 1):
            f = lambda x: '%X:%s' % (x >> 12, t.word(x & 0xFFF) if x & 0xFFF else '-')
            print('%2d %04X %s | %s %s %s %04X' % (i, p, ' '.join('%04X' % x for x in w),
                                                    f(w[0]), f(w[1]), f(w[2]), w[3]))
    else:
        sys.exit(__doc__)


def selftest(img):
    t = Text(load(img))
    assert t.word(0x40) == 'a' and t.word(0x43) == 'across' and t.word(0x658) == 'strike'
    assert len(t.words()) == 562 and t.words()[-1]['text'] == 'your'
    assert t.render(0xAD7D) == 'But fall and hit your head.\n'
    assert t.render(0xB15D).startswith('The dragon says " Well thief your cunning has failed')
    assert t.render(0xB3A4).startswith('Rewind and prepare tape for')
    assert len(t.starts()) == 177
    print('text.py selftest ok')


if __name__ == '__main__':
    main(sys.argv[1:])
