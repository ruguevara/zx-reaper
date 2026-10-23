"""Helpers for the parser tests: phrase records, order slots, tokens (the
layouts are in src/parser.asm: records of 24 bytes, REC_BLOCK_A at +4, REC_BLOCK_B at +$0E)."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

PHRASE_STACK_TOP = 0xB9C8       # PhraseRecord0; the records below it are newer
RECORD = 24
EXCEPT, ALL = 0x40, 0x80        # flags in the high byte of word 1


def word(rnd, empty=0.3):
    """A word token as the record holds it: 12-bit dictionary offset (0 = none)."""
    if rnd.random() < empty:
        return [0, 0]
    return [rnd.randrange(1, 256), rnd.randrange(0, 6)]


def record(rnd, flags=0, w1=None, w2=None, empty=0.3):
    """The 24 bytes of a phrase record; flags are or-ed into byte +1."""
    b = []
    for k in range(RECORD // 2):
        b += word(rnd, empty)
    if w1 is not None:
        b[0:2] = w1
    if w2 is not None:
        b[2:4] = w2
    b[1] = (b[1] & 0x0F) | flags
    b[0x13] &= 0x0F
    return b


def records_mem(rnd, n=7, first=-2, flag_choices=(0, 0, EXCEPT, ALL)):
    """Records at PHRASE_STACK_TOP - 24 * k for k in range(first, first + n)
    as a mem dict (one entry per record)."""
    mem = {}
    for k in range(first, first + n):
        mem[PHRASE_STACK_TOP - RECORD * k] = record(rnd, rnd.choice(flag_choices))
    return mem


_snapshot = None


def object_names():
    """{object id: its 6 name phrase bytes (record +8)} from the snapshot's ObjectTable ($C063: id, record address)."""
    global _snapshot
    if _snapshot is None:
        from skoolkit.snapshot import Snapshot
        _snapshot = Snapshot.get(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 're', 'orig.z80')).ram(-1)
    ram, names, a = _snapshot, {}, 0xC063
    while ram[a - 0x4000] != 0xFF:
        rec = ram[a + 1 - 0x4000] | ram[a + 2 - 0x4000] << 8
        names[ram[a - 0x4000]] = list(ram[rec + 8 - 0x4000:rec + 14 - 0x4000])
        a += 3
    return names
