; Unused area
;
; 232 zero bytes. Nothing references them (no operand or word in the image
; points here, and the code never executes here).
L9718:
  DEFS $E8

; Title screen attributes: rows 0-15, 32 bytes per row
;
; Attributes of the upper two thirds of the title screen (16 rows of 32 bytes,
; row 0 first). NewGame copies $300 bytes from here to $5800, so the attributes
; of the third part of the title screen come from StatusBarAttributes (the
; status bar colours). It then reads the copy on the screen to decide what to
; draw in each cell:
;
; $00 black, nothing drawn. $D3 (flash, bright red paper, magenta ink): the big
; letters "JET SET WILLY", cells without pixels, the red paper is the letter.
; $09, $24, $2D: solid blue, green and cyan blocks of the picture, also without
; pixels. The drawing loop skips exactly these five values. $08, $29, $05 and
; $2C (the last stored back as $25) are drawn with the edge pieces +0/+8 of
; TitleEdgePieces; any other attribute ($28, $25, $04 occur in this data) with
; the pieces +$10/+$18. Taken from the code of NewGame; the result is the
; triangle of the title screenshot (blue, green and cyan faces).
TitleAttributes:
  DEFS $52
  DEFB $28,$28,$05,$05,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$D3,$D3,$D3,$00,$D3,$D3,$D3,$00,$D3,$D3,$D3,$00,$28,$D3
  DEFB $D3,$D3,$25,$D3,$D3,$D3,$00,$D3,$D3,$D3,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$D3,$00,$00,$D3,$00,$00,$00,$00,$D3,$28,$28,$2D,$D3
  DEFB $25,$25,$24,$D3,$00,$00,$00,$00,$D3,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$D3,$00,$00,$D3,$D3,$D3,$00,$28,$D3,$2D,$2D,$25,$D3
  DEFB $D3,$D3,$24,$D3,$D3,$D3,$00,$00,$D3,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$D3,$00,$00,$D3,$00,$28,$28,$2D,$D3,$25,$25,$24,$24
  DEFB $04,$D3,$24,$D3,$00,$00,$00,$00,$D3,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$D3,$D3,$00,$00,$D3,$D3,$D3,$2D,$25,$D3,$24,$24,$04,$D3
  DEFB $D3,$D3,$24,$D3,$D3,$D3,$00,$00,$D3,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$29,$29,$2D,$2D,$2C,$2C,$04,$04,$00,$00
  DEFB $09,$09,$24,$24
  DEFS $12
  DEFB $09,$09,$29,$29,$2D,$2D,$05,$05
  DEFB $00,$00,$09,$09,$24,$24
  DEFS $10
  DEFB $D3,$00,$08,$08,$D3,$09,$D3,$29,$D3,$2D,$05,$05,$D3,$09,$24,$D3
  DEFB $00,$00,$00,$D3,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $D3,$00,$00,$00,$D3,$08,$D3,$09,$D3,$29,$2D,$2D,$D3,$09,$24,$D3
  DEFB $00,$00,$00,$D3,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $D3,$00,$D3,$00,$D3,$00,$D3,$08,$D3,$09,$29,$29,$D3,$09,$24,$D3
  DEFB $D3,$D3,$D3,$D3,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $D3,$00,$D3,$00,$D3,$00,$D3,$00,$D3,$08,$09,$09,$D3,$09,$24,$24
  DEFB $00,$D3,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $D3,$D3,$D3,$D3,$D3,$00,$D3,$00,$D3,$D3,$D3,$08,$D3,$D3,$D3,$24
  DEFB $00,$D3
  DEFS $1A
  DEFB $08,$08,$04,$04,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00

; Status bar attributes: rows 16-23, 32 bytes per row
;
; Attributes of the bottom third of the screen (rows 16-23), copied to $5A00 by
; ScrollTitleMessage when a game starts and by ResumeAfterPause. As part of the
; $300-byte copy of TitleAttributes they are also the bottom third of the title
; screen, before NewGame sets row 19. The game loop copies only the top two
; thirds from the attribute buffer to the screen, so these stay as they are.
;
; Row 16 ($9A00): bright yellow ink on black, the room name. Rows 17-18: black.
; Row 19 ($9A60): the status line, black paper, ink 1 to 6 on the first six
; cells, white (7) on 20 cells and ink 6 to 1 on the last six (the screenshot
; shows the letters of "Items" in different colours). Row 20: black. Rows 21-22
; ($9AA0, $9AC0): the lives, seven pairs of cells, one pair per Willy figure
; drawn by DrawLives, with the attributes $45 (bright cyan ink), $06 (yellow),
; $04 (green), $41 (bright blue), $05 (cyan), $43 (bright magenta), $44 (bright
; green), all on black. Row 23: black.
StatusBarAttributes:
  DEFS $20,$46            ; row 16: room name, bright yellow ink
  DEFS $40                ; rows 17-18: black
  DEFB $01,$02,$03,$04,$05,$06 ; row 19: status line, ink 1-6
  DEFS $14,$07            ; 20 cells with white ink
  DEFB $06,$05,$04,$03,$02,$01 ; ink 6-1
  DEFS $20                ; row 20: black
  DEFB $45,$45,$06,$06,$04,$04,$41,$41 ; row 21: colours of the lives (2 cells
                                       ; per figure), 7 figures
  DEFB $05,$05,$43,$43,$44,$44
  DEFS $12
  DEFB $45,$45,$06,$06,$04,$04,$41,$41 ; row 22: the same
  DEFB $05,$05,$43,$43,$44,$44
  DEFS $32                ; rest of row 22 and row 23: black

; Colour-code screen key graphics
;
; Four 16x16 pixel graphics, 32 bytes each (16 rows of 2 bytes): the keys 1, 2,
; 3 and 4 shown in rows 10-11 of the code screen. Drawn by AskColourCode with
; DrawSprite at columns 2, 5, 8 and 11. Their colours come from the attributes
; at CodeScreenAttrs: most pixels are set (key colour as ink) and the digit is
; made of unset pixels, which show black on the black paper.
CodeKeyGraphics:
  DEFB $7F,$FE
  DEFB $C3,$03
  DEFB $BF,$FD
  DEFB $BF,$FD
  DEFB $FF,$FD
  DEFB $FF,$FD
  DEFB $FF,$FD
  DEFB $F9,$FD
  DEFB $F1,$FF
  DEFB $F9,$FF
  DEFB $F9,$FF
  DEFB $F9,$FF
  DEFB $F9,$FD
  DEFB $F9,$FD
  DEFB $FF,$FB
  DEFB $7F,$FE
  DEFB $7F,$FE
  DEFB $C7,$03
  DEFB $BF,$FD
  DEFB $BF,$FD
  DEFB $FF,$FD
  DEFB $FF,$FD
  DEFB $FF,$FD
  DEFB $F1,$FF
  DEFB $EC,$FF
  DEFB $FC,$FF
  DEFB $F9,$FF
  DEFB $F3,$FF
  DEFB $E7,$FF
  DEFB $E0,$FD
  DEFB $FF,$F3
  DEFB $7F,$FE
  DEFB $7F,$FE
  DEFB $C6,$03
  DEFB $BF,$FD
  DEFB $BF,$FD
  DEFB $BF,$FD
  DEFB $FF,$FD
  DEFB $FF,$FF
  DEFB $F1,$FF
  DEFB $EC,$FF
  DEFB $FC,$FF
  DEFB $F1,$FF
  DEFB $FC,$FF
  DEFB $EC,$FF
  DEFB $F1,$FD
  DEFB $FF,$E7
  DEFB $7F,$FE
  DEFB $7F,$FE
  DEFB $C6,$03
  DEFB $BF,$FD
  DEFB $BF,$FD
  DEFB $BF,$FD
  DEFB $BF,$FF
  DEFB $FF,$FF
  DEFB $FD,$FF
  DEFB $F9,$FF
  DEFB $F1,$FF
  DEFB $E9,$FF
  DEFB $E0,$FF
  DEFB $F9,$FF
  DEFB $F9,$FD
  DEFB $FF,$9B
  DEFB $7F,$FE

; Colour-code screen attributes
;
; 128 bytes copied by AskColourCode to $5900-$597F (attribute rows 8-11): row
; 8: columns 0-27 $45 (bright cyan ink, for the message), columns 28-31 $47
; (bright white, for the grid cell letter and digit); row 9 and columns 0-1 of
; row 10: 0; rows 10-11, columns 2-12: the four keys, 2x2 cells each at columns
; 2, 5, 8, 11: ink blue ($41, bright), red ($42, bright), magenta ($03), green
; ($04), with the top-right cell of each key paper white ($79, $7A, $3B, $3C)
; for a highlight; rows 10-11, columns 16-17, 19-20, 22-23, 25-26: $07 (white
; ink, black paper) = the four empty colour slots filled by ReadCodeSlot (value
; $07 means empty). All other cells are 0.
CodeScreenAttrs:
  DEFS $1C,$45
  DEFB $47,$47,$47,$47
  DEFS $22
  DEFB $41,$79,$00,$42,$7A,$00,$03,$3B,$00,$04,$3C,$00,$00,$00,$07,$07
  DEFB $00,$07,$07,$00,$07,$07,$00,$07,$07,$00,$00,$00,$00,$00,$00,$00
  DEFB $41,$41,$00,$42,$42,$00,$03,$03,$00,$04,$04,$00,$00,$00,$07,$07
  DEFB $00,$07,$07,$00,$07,$07,$00,$07,$07,$00,$00,$00,$00,$00
