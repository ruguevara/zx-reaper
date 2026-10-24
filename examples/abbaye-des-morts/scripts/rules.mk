# Tape block 2: BASIC line 10 and the variables (src/stage1.asm), which hold
# the depacker and the packed second stage (src/stage2.asm)
SCRIPT_OUTPUTS += build/blk02.bin build/blk03.bin
build/picture.rcs: data/picture.scr scripts/megalz.py | build
	$(PY) scripts/megalz.py rcs $< $@
build/stage2.bin: src/stage2.asm src/megalz.asm build/picture.rcs | build
	sjasmplus --nologo --msg=war -Isrc --lst=build/stage2.lst src/stage2.asm
build/stage2.mlz: build/stage2.bin scripts/megalz.py
	$(PY) scripts/megalz.py pack $< $@
build/stage1.bin: src/stage1.asm src/megalz.asm build/stage2.mlz
	sjasmplus --nologo --msg=war -Isrc --lst=build/stage1.lst src/stage1.asm
build/blk02.bin: build/loader.bin build/stage1.bin
	cat $^ > $@

# Tape block 3: the screens, the 128K music and the game, packed (MegaLZ)
build/blk03.bin: build/blocks.stamp scripts/block3.py scripts/megalz.py data/loading.scr data/info.scr data/music128.bin
	$(PY) scripts/block3.py data/loading.scr data/info.scr data/music128.bin build/game.bin $@
