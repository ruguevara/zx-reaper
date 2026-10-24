"""The verbs slice's assets (called by bridge/assets.py):

  verbs.json   wound_messages: the message of a wound by damage 0-16
                 (WoundMessages; damage 16 reads the word after the table, code
                 bytes that point into the ROM at $2ADD: F56);
               extra_messages: messages the code reaches that messages.json
                 does not hold (the ROM's bytes at $2ADD read as one), as the
                 items game/hobbit/text.py compiles markup into: ["word",
                 offset, print mode], ["text", characters], ["end", bits];
               extra_words: [offset, letters, ending] of the "words" such a
                 message prints from the middle of a dictionary entry (the
                 letters and the ending PrintWord reads from there);
               fire_retargets: timer k -> {location id: routine}: the stage 3
                 routine timer k's fire handler becomes when ActorArrives writes
                 a location id into its low byte with IY at timer k - 2 (F85),
                 for every location that lands on a routine's first byte.
"""
import json
import os

import paths  # noqa: F401
import labels as L
from decode import names, word
from assets import OUT, writing
import assets_text as AT

WOUND_COUNT = 17                # damage 0-16
ENDS = {2: 0x20, 3: 0x30, 6: 0x60}  # token modes that end a message: the end bits (text.ENDS)


def wild_word(mem, t, off):
    """[offset, letters, ending] of a word printed from offset `off` of the
    dictionary: PrintWord's letters, and its ending when byte 1 has bit 7."""
    p = AT.T.DICT + off
    ending = AT.ENDINGS[mem[p + 2] >> 5] if mem[p + 1] & 0x80 else None
    return [off, t.word(off), ending]


def wild_message(mem, t, a, words):
    """The items of the bytes at `a` read as a message (tokens and characters);
    words from the middle of a dictionary entry are added to `words`."""
    items = []
    while True:
        kind, v, q = t.step(a)
        if kind == 'tok':
            mode, off = v
            if t.word_at(off) is None:
                words.append(wild_word(mem, t, off))
            items.append(['word', off, 0 if mode in ENDS else mode])
            if mode in ENDS:
                items.append(['end', ENDS[mode]])
                return items
        elif kind == 'ch':
            items.append(['text', v])
        else:
            raise ValueError('$%04X: %s %r is not reproduced in a wild message' % (a, kind, v))
        a = q


def verbs(mem):
    t = AT.T.Text(bytes(mem))
    message = AT.message_names(mem, t)
    wounds, extra, words = [], {}, []
    for k in range(WOUND_COUNT):
        a = word(mem, L.WoundMessages + 2 * k)
        if a not in message:
            n = 'L%04X' % a
            extra[n] = wild_message(mem, t, a, words)
            wounds.append(n)
        else:
            wounds.append(message[a])
    retargets = {}
    for k in range(2, 10):
        page = word(mem, L.Timers + 7 * k + 2) & 0xFF00
        if page:
            hits = {loc: names()[page | loc] for loc in range(80) if page | loc in names()}
            retargets[k] = hits
    return {'wound_messages': wounds, 'extra_messages': extra, 'extra_words': words,
            'fire_retargets': retargets}


def write(mem, force):
    if writing('verbs.json', force):
        data = verbs(mem)
        with open(os.path.join(OUT, 'verbs.json'), 'w') as f:
            json.dump(data, f, indent=1)


if __name__ == '__main__':
    from assets import image
    print(json.dumps(verbs(image()), indent=1))
