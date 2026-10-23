# Regenerates every image of the article from the game's bytes.
# Run from the project root: make -f docs/img/Makefile
# Routine addresses: DrawMaze $6B75, DrawBlocks $6D4E (see their skool entries).

PY   ?= python3
RUN  := $(PY) tools/zxrun.py re/orig.z80
GFX  := $(PY) tools/zxgfx.py sheet
IMG  := docs/img
HORACE_ATTR := 0x39
GUARD_ATTR  := 0x3B
BELL_ATTR   := 0x3A

all: $(IMG)/loading.png $(IMG)/title.png $(IMG)/horace.png $(IMG)/guard.png \
     $(IMG)/guard-scared.png $(IMG)/bell.png $(IMG)/fruit.png $(IMG)/tiles.png \
     $(IMG)/maze1.png $(IMG)/maze2.png $(IMG)/maze3.png $(IMG)/maze4.png \
     $(IMG)/title-screen.png $(IMG)/demo.png $(IMG)/game.png $(IMG)/scared.png

$(IMG)/loading.png: data/screen07.scr
	sna2img.py -s 2 $< $@

# the big title letters: DrawBlocks twice, as the title screen does
$(IMG)/title.png:
	$(RUN) --cls 0x3D --call 0x6D4E --reg HL=0x6E8F --reg DE=0x40A0 --reg BC=0xA0 --dump build/hh-title.z80
	$(PY) tools/zxrun.py build/hh-title.z80 --call 0x6D4E --reg HL=0x6F2F --reg DE=0x4880 --reg BC=0xA0 \
	  --png $@ --crop 0,5,32,12

$(IMG)/horace.png:
	$(GFX) 0x7CC7 8 2 2 $@ --attr $(HORACE_ATTR) --cols 4 --scale 4
$(IMG)/guard.png:
	$(GFX) 0x7DC7 8 2 2 $@ --attr $(GUARD_ATTR) --cols 4 --scale 4
$(IMG)/guard-scared.png:
	$(GFX) 0x7EC7 2 2 2 $@ --attr $(GUARD_ATTR) --scale 4
$(IMG)/bell.png:
	$(GFX) 0x7F07 4 2 2 $@ --attr $(BELL_ATTR) --scale 4
$(IMG)/fruit.png:
	$(GFX) 0x7C7C 2 2 2 $@ --layout attrcells --scale 4
# tile colours as DrawMaze sets them: 0 yellow ink, 2 green, 3 black, 9 white, rest cyan
$(IMG)/tiles.png:
	$(GFX) 0x7BF7 10 1 1 $@ --attrs 0x3E,0x3D,0x3C,0x38,0x3D,0x3D,0x3D,0x3D,0x3D,0x3F --cols 10 --scale 6

# play order: Maze1Map $72F7, Maze2Map $6FF7, Maze3Map $75F7, Maze4Map $78F7
MAZE_MAP_1 := 0x72F7
MAZE_MAP_2 := 0x6FF7
MAZE_MAP_3 := 0x75F7
MAZE_MAP_4 := 0x78F7
$(IMG)/maze%.png:
	$(RUN) --cls 0x38 --call 0x6B75 --reg HL=$(MAZE_MAP_$*) --reg DE=0x4000 --reg BC=0x300 --png $@

$(IMG)/title-screen.png:
	$(RUN) --frames 300 --shot 299:$@
$(IMG)/demo.png:
	$(RUN) --input tests/inputs/demo.txt --frames 2000 --shot 1999:$@

# a real game (second game of the play script, maze 1): status line, Horace,
# two guards, the bell and a dropped strawberry
$(IMG)/game.png:
	$(RUN) --input tests/inputs/play.txt --frames 2751 --shot 2750:$@

# scared guards: the same moment with BellTimer ($6DAE) poked to $0400, as if
# Horace had taken the bell, 60 frames later (the poke is not part of the game)
$(IMG)/scared.png:
	$(RUN) --input tests/inputs/play.txt --frames 2750 --dump build/hh-play.z80
	$(PY) tools/zxrun.py build/hh-play.z80 --poke 0x6DAE,0x00 --poke 0x6DAF,0x04 --frames 61 --shot 60:$@

.PHONY: all
