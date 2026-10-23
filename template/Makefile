# Reverse-engineered sources of one ZX Spectrum game.
#   make            build the tape and check it is byte-identical to the original
#   make help       all targets
# Sources: re/skool/ (while annotating) or src/game.asm (after `make export`).

PY      ?= python3
T       := $(PY) tools
ORIG    := $(firstword $(wildcard original/*.tap original/*.tzx))
EXT     := $(suffix $(ORIG))
SKOOL   := $(sort $(wildcard re/skool/*.skool))
SRC     := $(wildcard src/*.asm) $(wildcard data/*)
BAS_BIN := $(patsubst src/%.bas,build/%.bin,$(wildcard src/*.bas))
INPUTS  := $(wildcard tests/inputs/*.txt)
MAPS    := $(wildcard re/maps/*.map)
SHIFT   ?= 0x100

include re/layout.mk
-include scripts/rules.mk

ifneq ($(wildcard src/game.asm),)
  MASTER := asm
else
  MASTER := skool
  GAME_ASM := build/game.asm
endif

.PHONY: all verify test expected coverage status labels html shift-test export clean help
all: verify

help:
	@echo "make            build + byte-identity check against $(ORIG)"
	@echo "make test       replay tests/inputs/*.txt, compare per-frame hashes with tests/expected"
	@echo "make expected   record tests/expected/*.hash from the original"
	@echo "make coverage   add code execution maps from tests/inputs and re/rzx/*.rzx"
	@echo "make status     annotation and coverage counters"
	@echo "make labels     operands that still use numeric addresses (relocation TODO)"
	@echo "make shift-test build the code at +SHIFT ($(SHIFT)) and replay tests (relocatability)"
	@echo "make html       browsable skool2html disassembly in build/html"
	@echo "make export     freeze re/skool into src/*.asm modules (src becomes the master)"
	@echo "sources: $(MASTER)"

build:
	mkdir -p build

build/game.skool: $(SKOOL) | build
	$(T)/zxq.py join re/skool > $@

# ORG lines get +SHIFT so the shift test can move the code;
# skool2asm writes IXl/IXh/IYl/IYh; sjasmplus takes ixl/IXL/xl/lx... but not
# mixed case (unless --syntax=i), so normalise to IXL/IXH/IYL/IYH
build/game.asm: build/game.skool
	skool2asm.py -q -w -H -c $< | sed -E \
	  -e 's/^( +ORG +)(\$$[0-9A-Fa-f]+)\s*$$/\1\2+SHIFT/' \
	  -e 's/\b(I[XY])([hl])\b/\1\U\2/g' > $@

build/blocks.stamp: src/build.asm $(GAME_ASM) $(SRC) | build
	sjasmplus --nologo --msg=war -Ibuild --sym=build/game.sym --lst=build/game.lst src/build.asm
	touch $@

build/%.bin: src/%.bas | build
	$(T)/zxbasic.py build $< $@

build/game$(EXT): tape/tape.txt build/blocks.stamp $(BAS_BIN) $(SCRIPT_OUTPUTS)
	$(T)/zxtape.py build $< $@

verify: build/game$(EXT)
	@if cmp -s $< $(ORIG); then echo "IDENTICAL: $< == $(ORIG)"; \
	else $(T)/zxtape.py diff $(ORIG) $<; exit 1; fi

build/game.z80: build/game$(EXT)
	tap2sna.py $< $@ > build/tap2sna.log

expected:
	@for i in $(INPUTS); do n=$$(basename $$i .txt); \
	  $(T)/zxrun.py re/orig.z80 --input $$i --hash-ram --hashes tests/expected/$$n.hash || exit 1; done

test: build/game.z80
	@for i in $(INPUTS); do n=$$(basename $$i .txt); echo "== $$n"; \
	  $(T)/zxrun.py build/game.z80 --input $$i --hash-ram --expect tests/expected/$$n.hash || exit 1; done

coverage:
	@for i in $(INPUTS); do $(T)/zxrun.py re/orig.z80 --input $$i --map re/maps/inputs.map || exit 1; done
	@for r in $(wildcard re/rzx/*.rzx); do rzxplay.py --no-screen --quiet --map re/maps/rzx.map $$r; done
	@$(T)/zxq.py status re/maps/*.map

status:
	@$(T)/zxq.py status $(MAPS)

labels: build/game.skool
	@skool2asm.py -H -c $< 2>&1 >/dev/null | grep -A1 WARNING | grep -v '^--' ; true

html: build/game.skool
	skool2html.py -H -d build/html $<

ENTRY := $(if $(filter 1,$(ENTRY_IN_REGION)),$(shell printf '0x%X' $$(($(ENTRY_PC)+$(SHIFT)))),$(ENTRY_PC))
shift-test: $(GAME_ASM) $(SRC) | build
	sjasmplus --nologo --msg=war -Ibuild -DSHIFT=$(SHIFT) src/build.asm
	@for i in $(INPUTS); do n=$$(basename $$i .txt); echo "== $$n (shift $(SHIFT))"; \
	  $(T)/zxrun.py re/orig.z80 --clear $(REGION_START)-$(REGION_END) \
	    --load build/shifted.bin@$$(printf '0x%X' $$(($(REGION_START)+$(SHIFT)))) --pc $(ENTRY) \
	    --input $$i --expect tests/expected/$$n.hash || exit 1; done

export: build/game.asm
	@test ! -e src/game.asm || { echo "src/game.asm exists: already exported"; exit 1; }
	@test -f re/modules.txt || printf '%s main\n' $(REGION_START) > re/modules.txt
	$(T)/zxq.py export build/game.asm re/modules.txt src
	rm -f build/game.asm build/blocks.stamp
	$(MAKE) verify

clean:
	rm -rf build
