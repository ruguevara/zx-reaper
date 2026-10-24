# Written by hand (zxinit.py stops at a custom loader): the game is unpacked
# by the loader to $6000-$FEFF and entered at $6000.
REGION_START := 0x6000
REGION_END := 0xFF00
ENTRY_PC := 0x6000
ENTRY_IN_REGION := 1
IMAGE_PATCHES :=
# The loader's second stage returns to $6000 after unpacking the game; the
# first pass through $6000 (the loader itself) comes before the tape ends.
TAP2SNA_OPTS := -c finish-tape=1 --start 24576
