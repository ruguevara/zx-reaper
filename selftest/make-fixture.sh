#!/bin/sh
# Build the self-test "original" tape: selftest/out/demo.tap
# BASIC loader with hidden numbers (shows CLEAR 0 / USR 0, stores 32767 / 32768)
# followed by a headed CODE block.
set -e
cd "$(dirname "$0")"
mkdir -p out
sjasmplus --nologo --msg=war --raw=out/demo.bin demo.asm
printf '10 BORDER 0: CLEAR 0\\#=32767: LOAD "" CODE : RANDOMIZE USR 0\\#=32768\n' > out/loader.bas
python3 ../tools/zxbasic.py build out/loader.bas out/loader.bin
python3 - <<'PY'
import os
n_bas, n_code = os.path.getsize('out/loader.bin'), os.path.getsize('out/demo.bin')
open('out/fixture-tape.txt', 'w').write(f'''format tap
header program "demo" len={n_bas} p1=10 p2={n_bas}
data 0xff out/loader.bin
header code "democode" len={n_code} p1=32768 p2=32768
data 0xff out/demo.bin
''')
PY
python3 ../tools/zxtape.py build out/fixture-tape.txt out/demo.tap
python3 ../tools/zxtape.py list out/demo.tap
