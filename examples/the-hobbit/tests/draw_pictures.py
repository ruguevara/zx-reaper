#!/usr/bin/env python3
"""Draw every location picture on the Z80 (tools/zxrun.py --call DrawLocationPicture) and
through port/drawing.py, from the same snapshot, and compare the picture area
($4000-$4FFF, $5800-$59FF), PictureFound and the border. Needs port/engine.py's
CheckDark (stubbed here as 'not dark').

  python3 tests/draw_pictures.py [SNAPSHOT]     (default /tmp/hobbit/bagend.z80)
"""
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path[:0] = [os.path.join(ROOT, 'port'), os.path.join(ROOT, '..', '..', 'tools')]
from skoolkit.snapshot import Snapshot  # noqa: E402

import drawing  # noqa: E402
import engine  # noqa: E402
import objects  # noqa: E402
from labels import PictureTable  # noqa: E402
from regs import r  # noqa: E402
from zxpyxel import mem, zx  # noqa: E402

snap = sys.argv[1] if len(sys.argv) > 1 else '/tmp/hobbit/bagend.z80'
ram = bytes(Snapshot.get(snap).ram())
pictures = []
a = PictureTable
while ram[a - 0x4000] != 0xFF:
    pictures.append(ram[a - 0x4000])
    a += 3


def z80_draw(pic_id, out):
    subprocess.run([sys.executable, os.path.join(ROOT, '..', '..', 'tools', 'zxrun.py'), snap, '--cls', '0x38',
                    '--poke', '0xB707,8', '--call', '0x7F78', '--reg', 'A=%d' % pic_id, '--dump', out],
                   check=True, capture_output=True)
    return bytes(Snapshot.get(out).ram())




def find_id_record():           # objects.FindIdRecord, until objects.py is ported
    while mem[r.ix] not in (r.a, 0xFF):
        r.ix += 3
    r.zf = mem[r.ix] != r.a     # Z = not found
    r.a = mem[r.ix]


engine.CheckDark = lambda: setattr(r, 'cf', False)     # lit; the real one needs objects.py
if not callable(objects.FindIdRecord):
    objects.FindIdRecord = find_id_record
bad = 0
for pic_id in pictures:
    with tempfile.TemporaryDirectory() as d:
        want = z80_draw(pic_id, os.path.join(d, 'x.z80'))
    mem[0x4000:] = ram
    mem[0x4000:0x5800] = bytes(0x1800)
    mem[0x5800:0x5B00] = bytes([0x38]) * 0x300
    mem[0xB707] = 8
    r.reset()
    r.a = pic_id
    drawing.DrawLocationPicture()
    got = bytes(mem[0x4000:0x10000])
    ok = (got[:0x1000] == want[:0x1000] and got[0x1800:0x1A00] == want[0x1800:0x1A00]
          and got[0x7F77 - 0x4000] == want[0x7F77 - 0x4000])
    diffs = sum(x != y for x, y in zip(got[:0x1B00], want[:0x1B00]))
    print('picture $%02X: %s%s' % (pic_id, 'same' if ok else 'DIFFERENT', '' if ok else ' (%d bytes)' % diffs))
    bad += not ok
print('PICTURES PASSED' if not bad else '%d pictures differ' % bad)
sys.exit(bool(bad))
