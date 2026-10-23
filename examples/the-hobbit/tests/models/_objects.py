"""Shared by the tests of port/objects.py: cases built from the real object
table of re/orig.z80 (ids, records, locations), with the holders, flags,
weights and locations of the records shuffled per case (a holder is never changed to make a chain loop)."""
import random  # noqa: F401

import labels as L
import _regs
from skoolkit.snapshot import Snapshot

_ram = Snapshot.get('re/orig.z80').ram(-1)


def b(a):
    return _ram[a - 0x4000]


def w(a):
    return b(a) | b(a + 1) << 8


def lo_hi(x):
    return [x & 0xFF, x >> 8]


ENTRIES = []                                       # (id, record address) of ObjectTable
_a = L.ObjectTable
while b(_a) != 0xFF:
    ENTRIES.append((b(_a), w(_a + 1)))
    _a += 3
IDS = [i for i, _ in ENTRIES]
REC = dict(ENTRIES)
END_ENTRY = _a                                     # the END_MARK entry of the table
OBJECTS_REGION = ('Chr00Player', L.STATE_OBJECTS_SIZE)


def exits(loc):
    """(address, direction, obstacle, destination) of the exits of a location."""
    rec, a, out = w(L.LocationTable + 2 * loc), 0, []
    a = rec + L.EXITS_BIAS + L.EXIT_SIZE
    while b(a) != 0xFF:
        out.append((a, b(a), b(a + 1), b(a + 2)))
        a += 3
    return out


def world(rnd):
    """Memory shuffle: holders, flags, weights, sizes, location counts and
    locations of the records; the actor and the subject."""
    m = {}
    holder = {oid: b(rec + 1) for oid, rec in ENTRIES}
    for k, (oid, rec) in enumerate(ENTRIES):
        if k and rnd.random() < 0.6:
            h = rnd.choice([0xFF] + IDS * 2)                       # any object, or a location
            up = h
            while up != 0xFF and up != oid:                        # no holder chain may loop
                up = holder.get(up, 0xFF)
            if up != oid:
                holder[oid] = m[rec + 1] = h
        if rnd.random() < 0.7:
            m[rec + 7] = rnd.choice([0x80, 0xA0, 0x88, 0xC0, 0x40, 0x48, 0x82, 0xA8, 0x20, 0x00]) | rnd.choice([0, 0, 1])
        m[rec + 2] = rnd.choice([0, 1, 5, 10, 30, 60, 100])
        m[rec + 3] = rnd.choice([0, 1, 5, 10, 30, 60, 100])
        if rnd.random() < 0.5:
            m[rec] = rnd.choice([1, 1, 1, 2])
        m[rec + 0x10] = rnd.randrange(0x20)
        m[rec + 0x11] = rnd.randrange(0x20)
    actor = rnd.choice(ENTRIES)
    m[L.ActorRecord] = lo_hi(actor[1])
    m[L.Subject] = actor[0]
    return m


def case(rnd, shuffle=True, mem=None, **regs):
    c = dict(regs)
    c['mem'] = world(rnd) if shuffle else {}
    c['mem'].update(mem or {})
    return c


def noise(rnd, *names):
    """Random values for registers a routine must keep."""
    return {n: rnd.randrange(0x10000 if len(n) == 2 else 0x100) for n in names}


def out(regs, mem=()):
    return {'regs': regs, 'mem': list(mem)}


def run(name, regs, outputs):
    import objects
    return _regs.run(getattr(objects, name), regs, outputs['regs'])


def rec_pick(rnd):
    return rnd.choice(ENTRIES)
