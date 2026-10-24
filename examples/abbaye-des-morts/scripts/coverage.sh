#!/bin/sh
# Coverage runs that need pokes (they are not input scripts): every room
# entered directly, the endings, the Kempston code. Writes re/maps/warp.map.
# The rooms: from a game started by tests/inputs/play.txt (frame 400), room
# number $8509 := N and the room state $850C := $81 (enter the room, bit 7
# kept so the frame routines go on), then random keys.
set -e
T=build/coverage
mkdir -p $T
python3 tools/zxrun.py re/orig.z80 --input tests/inputs/play.txt --frames 400 --dump $T/play400.z80 > /dev/null
for n in $(seq 0 24); do
  python3 tools/zxrun.py $T/play400.z80 --poke 0x8509,$n --poke 0x850C,0x81 --frames 2500 \
    --fuzz $n:4:Q,A,O,P,SPACE,M --map $T/room$n.map > /dev/null &
  if [ $((n % 4)) = 3 ]; then wait; fi
done
wait
# room state 5 (the ending) and 3 (the end of the game); Kempston read on
python3 tools/zxrun.py $T/play400.z80 --poke 0x850C,0x85 --frames 3000 --fuzz 7:20:SPACE,ENTER,P --map $T/ending.map > /dev/null
python3 tools/zxrun.py $T/play400.z80 --poke 0x850C,0x83 --frames 1500 --fuzz 8:20:SPACE,ENTER --map $T/over.map > /dev/null
python3 tools/zxrun.py $T/play400.z80 --poke 0xA28F,0 --frames 3000 --fuzz 9:5:KL,KR,KU,KD,KF --map $T/kempston.map > /dev/null
cat $T/*.map | sort -u > re/maps/warp.map
