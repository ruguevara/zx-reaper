# Regenerates every image of the article from the game's bytes.
# Run from the project root: make -f docs/img/Makefile -j8
# Needs re/orig.z80 and re/image.z80 (make restore).
#
# Addresses used (see src/*.asm): EnterRoom $8912, FrameLoop $89AD; $8A31 is
# the instruction after the attribute copy of FrameLoop (the screen of the
# pass is complete there). Variables: CurrentRoom $8420, LivesLeft $85CC,
# WillyAirState $85D1, EndingStage $85DF.

PY    ?= python3
RUN   := $(PY) tools/zxrun.py
GFX   := $(PY) tools/zxgfx.py sheet
IMG   := docs/img
TMP   := build/docs
INGAME := $(TMP)/ingame.z80

ROOMS := $(shell seq -f '%02g' 0 60)
ROOM_PNGS := $(foreach r,$(ROOMS),$(IMG)/rooms/room-$(r).png)

all: $(IMG)/loader.png $(IMG)/code-screen.png $(IMG)/title-screen.png \
     $(IMG)/title-scroll.png $(IMG)/game.png $(IMG)/status-bar.png \
     $(IMG)/willy.png $(IMG)/figure.png $(IMG)/foot-barrel.png \
     $(IMG)/sprite-pages.png $(IMG)/code-keys.png $(IMG)/title-pieces.png \
     $(IMG)/item-graphics.png $(IMG)/tiles-24.png $(IMG)/tiles-29.png \
     $(IMG)/death.png $(IMG)/gameover-fall.png $(IMG)/gameover-end.png \
     $(IMG)/ending.png $(IMG)/nightmare.png $(IMG)/pause.png \
     $(IMG)/attic-after-16.png \
     $(ROOM_PNGS) $(IMG)/room-map.png

$(TMP):
	mkdir -p $(TMP) $(IMG)/rooms

# the state after tests/inputs/start.txt (same bytes as re/ingame.z80):
# in the Bathroom, inside FrameLoop
$(INGAME): | $(TMP)
	$(RUN) re/orig.z80 --input tests/inputs/start.txt --dump $@

# --- screens -----------------------------------------------------------

# the BASIC loader's message, still on the screen when the code starts
$(IMG)/loader.png:
	$(RUN) re/orig.z80 --frames 1 --png $@
# colour-code screen with the four slots filled (4-2-3-2), before ENTER
$(IMG)/code-screen.png:
	$(RUN) re/orig.z80 --input tests/inputs/code.txt --frames 115 --png $@
$(IMG)/title-screen.png:
	$(RUN) re/orig.z80 --input tests/inputs/code.txt --frames 400 --png $@
# the message scroll after the tune, colours cycled
$(IMG)/title-scroll.png:
	$(RUN) re/orig.z80 --input tests/inputs/title.txt --frames 1650 --png $@
$(IMG)/game.png: $(INGAME)
	$(RUN) $(INGAME) --frames 1 --png $@
$(IMG)/status-bar.png: $(INGAME)
	$(RUN) $(INGAME) --frames 1 --png $@ --crop 0,16,32,8
# death: Willy marked killed (MoveWilly then ends the pass before he is
# drawn); the flash a few frames later
$(IMG)/death.png: $(INGAME)
	$(RUN) $(INGAME) --poke 0x85D1,0xFF --frames 4 --png $@ --crop 0,0,32,17
# game over: no lives left, then killed
$(IMG)/gameover-fall.png: $(INGAME)
	$(RUN) $(INGAME) --poke 0x85CC,0 --poke 0x85D1,0xFF --frames 60 --png $@ --crop 0,0,32,16
$(IMG)/gameover-end.png: $(INGAME)
	$(RUN) $(INGAME) --poke 0x85CC,0 --poke 0x85D1,0xFF --frames 130 --png $@ --crop 0,0,32,16
# ending stage 3 in the Bathroom: Willy gone, toilet frames 2-3
$(IMG)/ending.png: $(INGAME)
	$(RUN) $(INGAME) --poke 0x85DF,3 --frames 20 --png $@ --crop 0,0,32,17
# The Nightmare Room (29) with Willy, drawn from sprite page $B6
$(IMG)/nightmare.png: $(INGAME)
	$(RUN) $(INGAME) --poke 0x8420,29 --pc 0x8912 --stop 0x8A31 --frames 50 --png $@ --crop 0,0,32,17
# pause (A held, then released): colours cycled about once a second
$(IMG)/pause.png: $(INGAME)
	printf '0 A\n10 -\n180 END\n' > $(TMP)/pause.txt
	$(RUN) $(INGAME) --input $(TMP)/pause.txt --png $@

# The Attic (41) for 200 frames (its arrow overwrites entity definitions
# $0D-$10), then room 16 entered: the damaged guardian is drawn against ROM
# bytes and the rope and arrow are no longer in the list (F92, F121)
$(TMP)/attic.z80: $(INGAME)
	$(RUN) $(INGAME) --poke 0x8420,41 --poke 0x85DF,3 --pc 0x8912 --frames 200 --dump $@
$(IMG)/attic-after-16.png: $(TMP)/attic.z80
	$(RUN) $(TMP)/attic.z80 --poke 0x8420,16 --pc 0x8912 --stop 0x8A31 --frames 50 --png $@ --crop 0,0,32,17

# --- graphics data -----------------------------------------------------

# 16x16 sprites: 16 rows of 2 bytes, so --layout linear
$(IMG)/willy.png:
	$(GFX) 0x9D00 8 2 2 $@ --layout linear --attr 0x47 --scale 4
$(IMG)/figure.png:
	$(GFX) 0x9C80 4 2 2 $@ --layout linear --attr 0x45 --scale 4
$(IMG)/foot-barrel.png:
	$(GFX) 0x9C40 2 2 2 $@ --layout linear --attr 0x47 --scale 4
# all 26 sprite pages $A600-$BFFF, one page per row
$(IMG)/sprite-pages.png:
	$(GFX) 0xA600 208 2 2 $@ --layout linear --attr 0x47 --cols 8 --scale 2
# code-screen keys in the inks of CodeScreenAttrs
$(IMG)/code-keys.png:
	$(GFX) 0x9B00 4 2 2 $@ --layout linear --attrs 0x41,0x42,0x03,0x04 --scale 4
$(IMG)/title-pieces.png:
	$(GFX) 0x8431 4 1 1 $@ --attr 0x05 --scale 6
# item graphic of every room (room byte $E1, one page per room)
$(IMG)/item-graphics.png:
	$(GFX) 0xC0E1 61 1 1 $@ --stride 256 --attr 0x46 --cols 16 --scale 4
# the six tiles of rooms 24 and 29 as defined (attribute + 8 rows)
$(IMG)/tiles-24.png:
	$(GFX) 0xD8A0 6 1 1 $@ --layout attrcells --scale 6
$(IMG)/tiles-29.png:
	$(GFX) 0xDDA0 6 1 1 $@ --layout attrcells --scale 6

# --- rooms -------------------------------------------------------------

# Room N: EnterRoom with CurrentRoom = N, then one pass of FrameLoop, with
# Willy hidden (ending stage 3 skips MoveWilly and PlaceWilly). The Bathroom
# (33) and the Master Bedroom (35) are drawn in stage 0, with Willy and the
# figure.
STAGE = $(if $(filter 33 35,$(1)),0,3)
$(IMG)/rooms/room-%.png: $(INGAME)
	$(RUN) $(INGAME) --poke 0x8420,$(patsubst 0%,%,$*) --poke 0x85DF,$(call STAGE,$*) \
	  --pc 0x8912 --stop 0x8A31 --frames 50 --dump $(TMP)/room-$*.z80 \
	  --png $@ --crop 0,0,32,17

$(IMG)/room-map.png: $(ROOM_PNGS) scripts/docs-roommap.py
	$(PY) scripts/docs-roommap.py $(TMP) $@

.PHONY: all
