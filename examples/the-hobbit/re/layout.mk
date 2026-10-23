# Written by zxinit.py
REGION_START := 0x6000
REGION_END := 0xFC40
ENTRY_PC := 0x6C00
ENTRY_IN_REGION := 1
IMAGE_PATCHES := --patch 24576,re/tape/07.bin
# The state backup at StateBackup runs to $FFED: a shift above $12 would carry
# it past $FFFF, so the shift tests use $10 and an odd $7.
SHIFT := 0x10
# RandomSigned mixes its seed with bytes read anywhere in memory, code included:
# a moved build gets the original's mixed value (A at $9CD2, where it is compared with the seed, so retries match too).
SHIFT_GIVE := 0x9CD2
# SAVE writes the state blocks to tape, and they hold pointers: a moved build
# saves different bytes, so the tape signal of save.txt differs by design.
SHIFT_INPUTS := $(filter-out tests/inputs/save.txt,$(wildcard tests/inputs/*.txt))
# Stage 3 (port/): the main loop is the checkpoint; the stack page is not state.
# RandomSigned reads memory the port does not have (the Z80's stack), so the
# record holds its mixed value and the port takes it (zx.take).
PORT_ENTRY := main.GameStart
PORT_CHECKPOINT := MainLoop
PORT_STATE := --state 0x4000-0x5B00 --state 0x5F00-0x5FDC --state 0x6000-0x10000
PORT_TAKE := RandomSigned_Mixed
