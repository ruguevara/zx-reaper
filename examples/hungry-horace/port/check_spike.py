"""Spike check: memory when InitMaze is reached, the Z80 code against the port
(demo, no keys). From port/: python check_spike.py Z80RAM.bin

Z80RAM.bin: tools/zxrun.py re/orig.z80 --frames 2000 --stop <InitMaze> --dump x.z80,
then tools/zxport.py image x.z80 Z80RAM.bin."""
import sys

import labels
from main import Start
from zxpyxel import headless, mem, zx


class Reached(Exception):
    pass


def stop(label):
    if label == 'InitMaze':
        raise Reached


zx.reset(open('image.bin', 'rb').read())
zx.on_checkpoint = stop
try:
    frames = headless.run(Start)
    sys.exit('the port ended without reaching InitMaze')
except Reached:
    pass
z80 = open(sys.argv[1], 'rb').read()
port = bytes(mem[0x4000:])
names = sorted((v, k) for k, v in vars(labels).items() if isinstance(v, int) and v >= 0x4000)


def label(a):
    best = max((v, k) for v, k in names if v <= a) if a >= names[0][0] else (a, '?')
    return '%s+%d' % (best[1], a - best[0]) if a != best[0] else best[1]


diff = [a for a in range(0xC000) if z80[a] != port[a]]
screen = [a for a in diff if a < 0x1B00]
print('port reached InitMaze at frame %d (clock %d T)' % (zx.t // 69888, zx.t))
print('screen and attributes: %s' % ('IDENTICAL' if not screen else '%d bytes differ' % len(screen)))
rest = [a + 0x4000 for a in diff if a >= 0x1B00]
runs = []
for a in rest:
    if runs and a == runs[-1][1] + 1:
        runs[-1][1] = a
    else:
        runs.append([a, a])
for lo, hi in runs:
    print('  $%04X-$%04X %-24s z80 %s port %s' % (lo, hi, label(lo), z80[lo - 0x4000:hi - 0x3FFF].hex(),
                                               port[lo - 0x4000:hi - 0x3FFF].hex()))
