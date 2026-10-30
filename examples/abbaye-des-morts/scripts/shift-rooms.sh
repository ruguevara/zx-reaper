#!/bin/sh
# The shift test on the room warps of scripts/coverage.sh: every room, the
# ending, game over; the moved build (make shift-test SHIFT=...) must give the
# same screen and sound as the original frame by frame.
#   scripts/shift-rooms.sh [SHIFT]      (after make, from the project root)
set -e
SHIFT=${1:-0x100}
T=build/shift-rooms
mkdir -p $T
sjasmplus --nologo --msg=war -Ibuild -DSHIFT=$SHIFT src/build.asm > /dev/null
python3 tools/zxrun.py re/orig.z80 --input tests/inputs/play.txt --frames 400 --dump $T/orig400.z80 > /dev/null
python3 tools/zxrun.py re/orig.z80 --clear 0x6000-0xFF00 --load build/shifted.bin@0x6000 --pc 0x6000 \
  --input tests/inputs/play.txt --frames 400 --dump $T/moved400.z80 > /dev/null
FAIL=0
run() {  # name zxrun-options...
  name=$1; shift
  python3 tools/zxrun.py $T/orig400.z80 "$@" --hashes $T/$name.hash > /dev/null
  if python3 tools/zxrun.py $T/moved400.z80 "$@" --expect $T/$name.hash > $T/$name.log; then
    echo "$name: $(tail -1 $T/$name.log)"
  else
    echo "$name: $(grep DIVERGED $T/$name.log)"; FAIL=1
  fi
}
for n in $(seq 0 24); do
  # room 22 with seed 22 hits finding F120 at frame 25: one frame of the monk
  # drawn from code bytes (QueueSprite's), which differ in the moved build
  seed=$n; [ $n = 22 ] && seed=122
  run room$n --poke 0x8509,$n --poke 0x850C,0x81 --frames 1500 --fuzz $seed:4:Q,A,O,P,SPACE,M
done
run ending --poke 0x850C,0x83 --frames 1500 --fuzz 8:20:SPACE,ENTER
run gameover --poke 0x850C,0x85 --frames 1500 --fuzz 7:20:SPACE,ENTER,P
rm -f diverged-*.png
exit $FAIL
