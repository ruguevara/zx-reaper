#!/bin/bash
# Make the images of docs/07-graphics.md from the game's bytes.
# Run from the project root with the venv active; needs re/orig.z80 (make restore).
set -e
IMG=docs/img
TMP=${TMPDIR:-/tmp}/hobbit-docs
RUN="python3 tools/zxrun.py"
mkdir -p $IMG $TMP

# Loading screen (also the title screen: the game waits on it for a key)
sna2img.py -s 2 data/screen05.scr $IMG/loading.png

# The game font at $8822: 96 characters, 8x8 bytes, drawn 6 pixels wide
python3 tools/zxgfx.py sheet 0x8822 96 1 1 $IMG/font.png --snapshot re/image.z80 --cols 16 --attr 0x38 --scale 3

# Bag End after the opening LOOK: the snapshot the pictures are drawn from
$RUN re/orig.z80 --input tests/inputs/endgame.txt --frames 1800 --dump $TMP/bagend.z80 \
  --shot 1400:$IMG/screenshot.png --shot 1799:$IMG/play-start.png

# The 22 location pictures, drawn by DrawLocationPicture ($7F78). The player is
# in Bag End (lit), so CheckDark lets every picture draw, dark places included.
for id in 01 04 05 06 07 08 0B 0D 10 18 19 1A 1C 1F 20 23 25 26 27 29 2B 31; do
  $RUN $TMP/bagend.z80 --cls 0x38 --poke 0xB707,8 --call 0x7F78 --reg A=0x$id \
    --png $IMG/picture-$id.png --crop 0,0,32,16 > /dev/null
done
# Picture 5 after dawn: the trolls' handler writes border 5 and attribute $28
# into the header of picture 5 (data at $E142); RestartGame zeroes them again
$RUN $TMP/bagend.z80 --cls 0x38 --poke 0xB707,8 --poke 0xE142,5 --poke 0xE143,0x28 \
  --call 0x7F78 --reg A=0x05 --png $IMG/picture-05-day.png --crop 0,0,32,16 > /dev/null

# Screens in play
$RUN re/orig.z80 --input tests/inputs/endgame.txt --shot 26120:$IMG/play-rivendell.png \
  --shot 37500:$IMG/play-gollum.png --shot 64630:$IMG/play-which.png \
  --shot 86360:$IMG/play-warg.png --shot 106040:$IMG/play-laketown.png \
  --shot 115060:$IMG/play-dragon.png --shot 136830:$IMG/win.png
$RUN re/orig.z80 --input tests/inputs/journey.txt --frames 171241 --shot 171240:$IMG/play-dark.png
$RUN re/orig.z80 --input tests/inputs/die.txt --shot 7400:$IMG/play-death.png

# Edge case: the player poked into location $2F, which has no exits: LOOK lists
# obstacles read from the bytes after the record (the game itself never lets
# the player in: THE PLACE IS TOO FULL FOR YOU TO ENTER)
printf '0 -\n10 TYPE look\n+700 END\n' > $TMP/look.txt
$RUN $TMP/bagend.z80 --poke 0xC12B,0x2F --input $TMP/look.txt --frames 600 --shot 599:$IMG/edge-2f-look.png

# The location map of docs/07-graphics.md (Mermaid, printed to stdout)
python3 scripts/locmap.py > $TMP/map.md
