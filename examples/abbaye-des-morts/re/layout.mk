# Written by hand (zxinit.py stops at a custom loader): the game is unpacked
# by the loader to $6000-$FEFF and entered at $6000.
REGION_START := 0x6000
REGION_END := 0xFF00
ENTRY_PC := 0x6000
ENTRY_IN_REGION := 0
IMAGE_PATCHES :=
# The loader's second stage returns to $6000 after unpacking the game; the
# first pass through $6000 (the loader itself) comes before the tape ends.
TAP2SNA_OPTS := -c finish-tape=1 --start 24576
# The shift test moves $85BC-$BFFF: all the code after the interrupt handler,
# into the $FF fill at $BEFC-$BFFF. Fixed below: the start-up code (entered at
# $6000, under the flag map), the flag row table at $6100 and the IM 2 table at
# $8400 (both read by page), the handler at $8585 (an IM 2 vector is two equal
# bytes), the font and the room scripts. Fixed above: buffers, tile tables and
# the sprite sheet, a page per pixel row. build.asm saves the whole region.
SHIFT_START := 0x85BC
SHIFT_END := 0xC000
SHIFT_LOAD := 0x6000
