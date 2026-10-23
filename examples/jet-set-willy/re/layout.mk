# Written by zxinit.py
REGION_START := 0x8000
REGION_END := 0x10000
ENTRY_PC := 0x8400
ENTRY_IN_REGION := 1
IMAGE_PATCHES := --patch 32768,re/tape/03.bin
# Shift only $8000-$9EFF (into the unused page $9F00); $A000-$FFFF stays fixed:
# entity definitions are found by index*8 from H=$14, rooms by OR $C0, sprites
# by page bytes in the definitions, and memory is full up to $FFFF.
SHIFT_END := 0x9F00
SHIFT_LOAD := 0x8000
