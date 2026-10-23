; Title bitmap: the word "HUNGRY" in 2x2-block letters
;
; The big title word HUNGRY. A picture of 32 x 5 character cells (160 bytes,
; one byte per cell), cells left to right and then down. Each byte describes
; the four 4x4-pixel blocks of its 8x8 cell: bit 4 = top-left block, bit 5 =
; top- right, bit 0 = bottom-left, bit 1 = bottom-right (1 = block set, bits 2,
; 3, 6 and 7 unused). So $33 is a solid cell, $11 its left half, $22 its right
; half and $00 an empty cell. Seen as 64 x 10 blocks the letters are about 9
; blocks wide and 10 tall, separated by one or two empty block columns.
;
; Drawn by Start with DrawBlocks (DrawBlocks) at screen address $40A0
; (character rows 5-9); the title loop then cycles the attributes of these rows
; to colour the letters. The other word is TitleHorace.
TitleHungry:
  DEFB $33,$11,$00,$33,$11,$22,$33,$00,$22,$33,$00,$33,$11,$00,$33,$11
  DEFB $00,$23,$31,$33,$01,$00,$33,$31,$32,$13,$00,$22,$33,$00,$22,$33
  DEFB $33,$11,$00,$33,$11,$22,$33,$00,$22,$33,$00,$33,$33,$01,$33,$11
  DEFB $22,$33,$00,$20,$30,$00,$33,$11,$00,$33,$11,$22,$33,$00,$22,$33
  DEFB $33,$13,$03,$33,$11,$22,$33,$00,$22,$33,$00,$33,$31,$33,$33,$11
  DEFB $22,$33,$02,$03,$03,$00,$33,$13,$23,$31,$00,$00,$32,$13,$33,$10
  DEFB $33,$11,$00,$33,$11,$22,$33,$00,$22,$33,$00,$33,$11,$20,$33,$11
  DEFB $22,$33,$00,$22,$33,$00,$33,$31,$33,$01,$00,$00,$00,$33,$11,$00
  DEFB $33,$11,$00,$33,$11,$00,$32,$13,$33,$10,$00,$33,$11,$00,$33,$11
  DEFB $00,$32,$13,$33,$10,$00,$33,$11,$20,$33,$01,$00,$00,$33,$11,$00

; Title bitmap: the word "HORACE" in 2x2-block letters
;
; The big title word HORACE. A picture of 32 x 5 character cells (160 bytes,
; one byte per cell), cells left to right and then down. Each byte describes
; the four 4x4-pixel blocks of its 8x8 cell: bit 4 = top-left block, bit 5 =
; top- right, bit 0 = bottom-left, bit 1 = bottom-right (1 = block set, bits 2,
; 3, 6 and 7 unused). So $33 is a solid cell, $11 its left half, $22 its right
; half and $00 an empty cell. Seen as 64 x 10 blocks the letters are about 9
; blocks wide and 10 tall, separated by one or two empty block columns.
;
; Drawn by Start with DrawBlocks (DrawBlocks) at screen address $4880
; (character rows 12-16); the title loop then cycles the attributes of these
; rows to colour the letters. The other word is TitleHungry.
TitleHorace:
  DEFB $33,$11,$00,$33,$11,$00,$23,$31,$33,$01,$00,$33,$31,$32,$13,$00
  DEFB $00,$23,$31,$33,$01,$00,$02,$33,$32,$13,$00,$22,$33,$30,$30,$10
  DEFB $33,$11,$00,$33,$11,$22,$33,$00,$22,$33,$00,$33,$11,$00,$33,$11
  DEFB $22,$33,$00,$22,$33,$00,$33,$11,$00,$30,$10,$22,$33,$00,$00,$00
  DEFB $33,$13,$03,$33,$11,$22,$33,$00,$22,$33,$00,$33,$13,$23,$31,$00
  DEFB $22,$33,$03,$23,$33,$00,$33,$11,$00,$00,$00,$22,$33,$03,$01,$00
  DEFB $33,$11,$00,$33,$11,$22,$33,$00,$22,$33,$00,$33,$31,$33,$01,$00
  DEFB $22,$33,$00,$22,$33,$00,$33,$11,$00,$03,$01,$22,$33,$00,$00,$00
  DEFB $33,$11,$00,$33,$11,$00,$32,$13,$33,$10,$00,$33,$11,$20,$33,$01
  DEFB $22,$33,$00,$22,$33,$00,$20,$33,$23,$31,$00,$22,$33,$03,$03,$01
