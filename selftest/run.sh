#!/bin/sh
# End-to-end check of zx-reaper on the fixture game (selftest/demo.asm):
# init -> identical build -> behaviour test -> reclassify -> relocate ->
# shift test -> export to asm modules -> identical build again.
# Usage: selftest/run.sh [WORKDIR]   (default: selftest/out/proj)
set -e
here=$(cd "$(dirname "$0")" && pwd)
kit=$(dirname "$here")
work=${1:-$here/out/proj}
"$here/make-fixture.sh" > /dev/null
rm -rf "$work"
python3 "$kit/tools/zxinit.py" "$here/out/demo.tap" "$work" --frames 3000
cd "$work"
cp "$here/wander.txt" tests/inputs/
make -s expected
make -s test
echo "== shift test before relocation work (must fail)"
if make -s shift-test > shift.log 2>&1; then echo "unexpected pass"; exit 1; fi
tail -2 shift.log
echo "== reclassify the data area and the jump table"
sleep 1   # make 3.81 (macOS) compares whole seconds: edits must come after the last build
python3 tools/zxq.py reclassify "$here/data-area.ctl"
python3 tools/zxq.py reclassify "$here/jump-table.ctl"
echo "== label the self-modified operand, as an agent would"
python3 - <<'PY'
def above(path, line, directive):
    s = open(path).read()
    assert line in s, line
    open(path, 'w').write(s.replace(line, directive + '\n' + line, 1))
above('re/skool/80A6.skool', ' $80B1 LD A,$00', '@label=SMC_SCORE')
above('re/skool/80A6.skool', ' $80B4 LD ($80B2),A', '@isub=LD (SMC_SCORE+1),A')
above('re/skool/812E.skool', ' $8138 LD A,($80B2)', '@isub=LD A,(SMC_SCORE+1)')
PY
make -s
make -s shift-test
make -s shift-test SHIFT=0x1234
echo "== export"
printf '0x8000 main\n0x8144 data\n' > re/modules.txt
make -s export
make -s test
make -s shift-test SHIFT=0x300
echo "== differential test, findings register, doctor"
mkdir -p tests/models
cp "$here/cell_attr_model.py" tests/models/
make -s diff
python3 tools/zxq.py finding add observed "cellad returns ATTRS + 32*PY + PX" "zxdiff: tests/models/cell_attr_model.py" > /dev/null
python3 tools/zxq.py question set Q6 answered "F1" > /dev/null
python3 tools/zxq.py audit | head -2
python3 tools/zxdoctor.py > /dev/null
echo "== typed input and screen text"
python3 - "$kit" <<'PY'
import sys
sys.path.insert(0, sys.argv[1] + '/tools')
import zxrun
ev, end = zxrun.type_events(10, 'a,')
assert ev == [(10, ['A']), (12, []), (14, ['SS']), (15, ['SS', 'N']), (17, []),
              (19, ['ENTER']), (21, [])] and end == 23, ev
mem = bytearray(0x10000)
mem[0x3D00:0x4000] = open(sys.argv[1] + '/zxpyxel/48.rom', 'rb').read()[0x3D00:]
def put(x, y, ch, width):          # a glyph's left `width` columns at pixel x, cell row y
    g = mem[0x3D00 + 8 * (ord(ch) - 32):][:8]
    for r in range(8):
        a = 0x4000 | (y & 0x18) << 8 | r << 8 | (y & 7) << 5
        row = int.from_bytes(mem[a:a + 32], 'big') | (g[r] >> (8 - width)) << (256 - x - width)
        mem[a:a + 32] = row.to_bytes(32, 'big')
for i, ch in enumerate('HI'):
    put(8 * i, 0, ch, 8)
for i, ch in enumerate('ok go'):
    put(6 * i + 1, 2, ch, 6)
assert zxrun.screen_text(mem).split('\n')[:3] == ['HI', '', 'ok go'], zxrun.screen_text(mem)
PY
echo "SELFTEST PASSED"
