#!/bin/sh
# End-to-end check of the kit on the fixture game (selftest/demo.asm):
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
python3 tools/zxq.py reclassify "$here/data-area.ctl"
python3 tools/zxq.py reclassify "$here/jump-table.ctl"
echo "== label the self-modified operand, as an agent would"
sed -i 's/^ \$80B1 LD A,\$00/@label=SMC_SCORE\n&/; s/^ \$80B4 LD (\$80B2),A/@isub=LD (SMC_SCORE+1),A\n&/' re/skool/80A6.skool
sed -i 's/^ \$8138 LD A,(\$80B2)/@isub=LD A,(SMC_SCORE+1)\n&/' re/skool/812E.skool
make -s
make -s shift-test
make -s shift-test SHIFT=0x1234
echo "== export"
printf '0x8000 main\n0x8144 data\n' > re/modules.txt
make -s export
make -s test
make -s shift-test SHIFT=0x300
echo "SELFTEST PASSED"
