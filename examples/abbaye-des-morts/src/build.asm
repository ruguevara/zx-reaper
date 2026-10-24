; Assembles the game ($6000-$FEFF, as the loader unpacks it) and saves it;
; scripts/rules.mk packs it with the loading screens into tape block 3.
  DEVICE ZXSPECTRUM48
  IFNDEF SHIFT
SHIFT = 0
  ENDIF
  INCLUDE "constants.asm"
  INCLUDE "game.asm"
  IF SHIFT == 0
  SAVEBIN "build/game.bin",$6000,$9F00
  ELSE
  SAVEBIN "build/shifted.bin",$6000,$9F00   ; the whole region: only $85BC-$BFFF moves
  ENDIF
