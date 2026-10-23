#!/usr/bin/env python3
"""Inputs of a stage 3 port on zxpyxel (docs/port.md in zx-reaper).

  zxport.py labels [SYMFILE] > port/labels.py   labels and constants as Python names
                                                 (default build/game.sym; run make first)
  zxport.py image SNAPSHOT OUT.bin              the 48K RAM of a snapshot ($4000-$FFFF)
"""
import sys


def labels(path):
    print('"""Labels and constants from %s (tools/zxport.py labels)."""' % path)
    for line in open(path):
        name, sep, value = line.partition(': EQU ')
        if sep and name.strip().isidentifier():
            print('%s = 0x%04X' % (name.strip(), int(value, 0)))


def image(snapshot, out):
    from skoolkit.snapshot import Snapshot
    snap = Snapshot.get(snapshot)
    if snap is None or len(snap.ram(-1)) != 0xC000:
        sys.exit('%s: not a 48K snapshot' % snapshot)
    with open(out, 'wb') as f:
        f.write(bytes(snap.ram(-1)))


if __name__ == '__main__':
    a = sys.argv[1:]
    if a[:1] == ['labels'] and len(a) <= 2:
        labels(a[1] if len(a) == 2 else 'build/game.sym')
    elif a[:1] == ['image'] and len(a) == 3:
        image(a[1], a[2])
    else:
        sys.exit(__doc__)
