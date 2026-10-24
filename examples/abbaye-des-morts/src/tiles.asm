; Tile flags: one byte per tile number, copied to the flag map with the tile
;
; When the room script puts a tile into the tile map at $5B00 (PlaceTile) the
; byte of this table is stored in the flag map three pages above ($5E00, one
; byte per cell, 22 rows of 32); the script can change the flags of a cell
; afterwards (observed: in room 16 row 21, columns 6-21 hold class 4 under the
; blank tile $80, the pit with the bones). Bit 7 is the redraw mark: set when
; the cell must be drawn this frame (every tile starts with it, so a new room
; is drawn in full). Bit 6 is set by the sprite queue (QueueSprite) on the
; cells a sprite covers and CollectRedrawRun turns it into bit 7 on the next
; pass, which erases the sprite. Bits 0-2 are the class that the player and
; enemies test:
;
; class 0 ($80): background, nothing there (tiles $25, $75-$76, $7B-$7C,
; $7E-$86, $88-$B7, $C0-$FF)
;
; class 1 ($81, bit 0 TILE_STANDABLE alone): tiles $10, $26 and $87, a one-way
; platform: Jean jumps up through it and walks through it from the sides, and
; lands on it only when falling across its top edge (observed, F74); the scythe
; of UpdateScytheFalling lands on it like on class 3
;
; class 3 ($83, bits 0 and 1): the walls and floors, solid from every side (bit
; 1, TILE_BLOCKS, stops walking and the head) (tiles $00-$04, $06-$0F, $11-$24,
; $27-$3A, $3D-$4D, $77-$7A, $7D, $B8-$BF); a falling scythe lands on it
; (observed on the ledges of room 18)
;
; class 4 ($84, FLAG_HARMFUL): harmful (tiles $05, $3B-$3C, $4E-$74); the
; player's code sets the hit flag $A8A0 from bit 2 (ProbePlayer), and
; UpdateScytheFalling and UpdateScytheSliding remove a scythe that meets bit 2
; (from the code, not observed)
;
; Class 2 (bit 1 alone: blocks walking and the head, cannot be stood on) is not
; used by any tile of the table; the border cells set by script op $8A
; (OpFlagEdges) get bit 1.
TileFlags:
  DEFB $83,$83,$83,$83,$83,$84,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83
  DEFB $81,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83
  DEFB $83,$83,$83,$83,$83,$80,$81,$83,$83,$83,$83,$83,$83,$83,$83,$83
  DEFB $83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$84,$84,$83,$83,$83
  DEFB $83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$83,$84,$84
  DEFB $84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84
  DEFB $84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84
  DEFB $84,$84,$84,$84,$84,$80,$80,$83,$83,$83,$83,$80,$80,$83,$80,$80
  DEFB $80,$80,$80,$80,$80,$80,$80,$81,$80,$80,$80,$80,$80,$80,$80,$80
  DEFB $80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80
  DEFB $80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80
  DEFB $80,$80,$80,$80,$80,$80,$80,$80,$83,$83,$83,$83,$83,$83,$83,$83
  DEFB $80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80
  DEFB $80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80
  DEFB $80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80
  DEFB $80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80

; Tile attributes: one byte per tile number
;
; The attribute (flash, bright, paper, ink) of each tile, in the layout of the
; attribute file. CopyRunCells stores it in the redraw buffer RedrawAttrs with
; the tile's bitmap, and DrawRedrawList writes it to the screen. Nearly all are
; an ink colour on black paper ($01-$07); bit 6 (bright) is set on a few
; ($42-$47). Tile $00 and tile $80 are both blank (attribute $00).
TileAttrs:
  DEFB $00,$06,$06,$44,$44,$47,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07
  DEFB $02,$02,$02,$02,$07,$07,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02
  DEFB $05,$05,$05,$05,$05,$05,$07,$06,$06,$06,$06,$06,$02,$45,$07,$07
  DEFB $07,$07,$07,$07,$07,$07,$07,$07,$07,$02,$02,$42,$42,$07,$07,$07
  DEFB $07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$46,$00,$06,$06
  DEFB $06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06
  DEFB $06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06
  DEFB $06,$06,$06,$06,$06,$47,$47,$02,$02,$02,$02,$47,$47,$42,$07,$07
  DEFB $00,$04,$02,$02,$02,$02,$02,$02,$02,$04,$44,$02,$02,$47,$47,$47
  DEFB $47,$07,$07,$07,$07,$07,$07,$07,$07,$02,$02,$02,$02,$02,$02,$01
  DEFB $01,$01,$01,$01,$02,$02,$04,$02,$07,$07,$07,$07,$07,$07,$07,$07
  DEFB $07,$01,$02,$02,$02,$07,$00,$02,$02,$02,$02,$02,$02,$02,$02,$02
  DEFB $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
  DEFB $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
  DEFB $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02
  DEFB $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02

; Tile bitmaps: 256 tiles of 8 bytes
;
; The 8x8 bitmap of each tile number, 8 bytes top to bottom, tile n at $CF00 +
; 8 * n. CopyRunCells copies them into the pixel-row pages of the redraw buffer
; (RedrawPixels). Tiles $00 and $80 are blank ($80 is the background most rooms
; are filled with), $7B is the heart and $7C the cross of the status bar,
; $E0-$FF are the pieces of the red pentagram of room 24 (a block of 6 by 6
; cells in its tile map); the rest are the walls, floors and decorations of the
; rooms and are not described tile by tile here (the attributes in TileAttrs
; give their colours: for instance the tiles of rows $C0-$DF are blue and
; $20-$2F cave rock in cyan).
TileGfx:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $72,$F8,$71,$06,$6F,$76,$B8,$DA
  DEFB $1C,$EE,$E0,$CE,$1F,$6E,$F1,$FB
  DEFB $FF,$FF,$FB,$51,$40,$00,$00,$00
  DEFB $7B,$FF,$EF,$44,$00,$00,$00,$00
  DEFB $00,$00,$00,$44,$44,$EE,$EE,$EE
  DEFB $4C,$DE,$DE,$DE,$DE,$DA,$4C,$00
  DEFB $71,$FB,$FB,$FB,$FB,$6B,$31,$00
  DEFB $FC,$FE,$FE,$FA,$FA,$F6,$FC,$00
  DEFB $C3,$E7,$EF,$AF,$AF,$6F,$C7,$00
  DEFB $8F,$DF,$DF,$DF,$DF,$5F,$8F,$00
  DEFB $11,$BB,$BB,$BB,$3B,$AB,$11,$00
  DEFB $03,$07,$07,$17,$47,$27,$73,$00
  DEFB $C6,$EF,$EF,$AF,$AF,$6D,$C6,$00
  DEFB $FF,$77,$00,$7E,$FF,$FD,$7E,$00
  DEFB $EF,$DE,$00,$3C,$7E,$7E,$3C,$00
  DEFB $FF,$FF,$00,$00,$00,$00,$00,$00
  DEFB $11,$BB,$BB,$99,$44,$EE,$EE,$66
  DEFB $01,$83,$A3,$91,$40,$E6,$EE,$66
  DEFB $FE,$00,$CF,$F0,$0F,$F7,$00,$00
  DEFB $72,$FB,$FB,$FB,$FB,$BB,$72,$00
  DEFB $88,$DD,$DD,$DD,$DC,$D5,$88,$00
  DEFB $B6,$B6,$B6,$B6,$12,$B6,$B6,$B6
  DEFB $3F,$00,$5B,$5B,$B7,$37,$B0,$B7
  DEFB $FC,$00,$DA,$DA,$ED,$EC,$0D,$ED
  DEFB $B7,$87,$B7,$B7,$5B,$5B,$00,$3F
  DEFB $ED,$E1,$ED,$ED,$DA,$DA,$00,$FC
  DEFB $C0,$BF,$80,$FF,$00,$80,$C0,$C0
  DEFB $FF,$DF,$E7,$00,$00,$00,$00,$00
  DEFB $FF,$3F,$0F,$18,$30,$00,$00,$00
  DEFB $FF,$00,$0C,$F7,$00,$00,$00,$00
  DEFB $FF,$86,$3C,$C6,$00,$00,$00,$00
  DEFB $73,$F9,$F8,$F9,$EB,$D7,$77,$27
  DEFB $C6,$80,$1C,$3E,$BE,$9A,$8C,$81
  DEFB $86,$C3,$C8,$DC,$DD,$9D,$0D,$61
  DEFB $B3,$3B,$1B,$C1,$E5,$EE,$AE,$4E
  DEFB $B3,$03,$43,$01,$09,$90,$C4,$CE
  DEFB $CF,$8F,$0F,$07,$06,$02,$00,$00
  DEFB $FF,$FF,$00,$00,$00,$00,$00,$00
  DEFB $F3,$FB,$71,$00,$FC,$FE,$FC,$00
  DEFB $FE,$FF,$FE,$00,$07,$77,$B3,$00
  DEFB $0F,$6F,$A7,$00,$F1,$F7,$E6,$00
  DEFB $FC,$FE,$FC,$00,$DF,$DF,$8F,$00
  DEFB $05,$0A,$40,$20,$01,$83,$31,$00
  DEFB $FE,$00,$CF,$F0,$0F,$F7,$00,$00
  DEFB $99,$FF,$78,$00,$E1,$1E,$00,$00
  DEFB $FD,$7F,$80,$EF,$AF,$EF,$EF,$EF
  DEFB $3F,$FF,$00,$FF,$FF,$FB,$FF,$FF
  DEFB $FF,$FE,$00,$BF,$DF,$EF,$EE,$EE
  DEFB $BF,$5E,$01,$FB,$FB,$7B,$FB,$FB
  DEFB $EF,$EE,$EF,$6F,$00,$38,$3C,$3C
  DEFB $7F,$FF,$7F,$7F,$00,$00,$00,$00
  DEFB $F5,$FB,$FD,$FD,$00,$00,$00,$00
  DEFB $FB,$FD,$FB,$FE,$00,$38,$3C,$3C
  DEFB $24,$A9,$75,$19,$B2,$40,$34,$02
  DEFB $FC,$16,$CA,$00,$7C,$FE,$92,$FE
  DEFB $6C,$7C,$54,$00,$7C,$FE,$92,$92
  DEFB $00,$00,$45,$8A,$DF,$5F,$8F,$00
  DEFB $00,$00,$05,$8A,$AF,$6F,$C7,$00
  DEFB $94,$36,$7F,$6B,$C5,$C3,$E7,$7E
  DEFB $00,$10,$01,$AC,$7E,$FF,$E7,$7E
  DEFB $4C,$DE,$DE,$DE,$DE,$DA,$4C,$00
  DEFB $71,$FB,$FB,$FB,$FB,$6B,$31,$00
  DEFB $FC,$FE,$FE,$FA,$FA,$F6,$FC,$00
  DEFB $C3,$E7,$EF,$AF,$AF,$6F,$C7,$00
  DEFB $8F,$DF,$DF,$DF,$DF,$5F,$8F,$00
  DEFB $11,$BB,$BB,$BB,$3B,$AB,$11,$00
  DEFB $03,$07,$07,$17,$47,$27,$73,$00
  DEFB $C6,$EF,$EF,$AF,$AF,$6D,$C6,$00
  DEFB $FF,$77,$00,$7E,$FF,$FD,$7E,$00
  DEFB $EF,$DE,$00,$3C,$7E,$7E,$3C,$00
  DEFB $72,$FB,$FB,$FB,$FB,$BB,$72,$00
  DEFB $88,$DD,$DD,$DD,$DC,$D5,$88,$00
  DEFB $00,$3E,$7F,$4F,$49,$36,$3E,$2A
  DEFB $00,$00,$20,$60,$10,$08,$66,$24
  DEFB $7C,$FE,$92,$92,$6C,$7C,$54,$00
  DEFB $3C,$18,$99,$FF,$FF,$99,$18,$3C
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$07,$00,$1C
  DEFB $00,$00,$00,$00,$1E,$BE,$04,$F0
  DEFB $00,$00,$00,$00,$F8,$7B,$33,$01
  DEFB $00,$00,$00,$00,$00,$C0,$EC,$CE
  DEFB $00,$00,$00,$00,$00,$00,$01,$03
  DEFB $00,$00,$00,$00,$00,$40,$C0,$C0
  DEFB $00,$01,$00,$06,$0E,$00,$01,$03
  DEFB $B9,$B0,$06,$F7,$EF,$00,$DC,$D9
  DEFB $F3,$E7,$43,$18,$3D,$7B,$00,$E7
  DEFB $9C,$BE,$04,$70,$F7,$E7,$4E,$80
  DEFB $18,$07,$F7,$76,$40,$18,$73,$37
  DEFB $60,$32,$14,$40,$E6,$2F,$1E,$1C
  DEFB $07,$7E,$F0,$60,$00,$00,$00,$0E
  DEFB $80,$00,$00,$00,$00,$00,$00,$00
  DEFB $03,$00,$01,$01,$00,$00,$00,$00
  DEFB $83,$30,$77,$76,$20,$0E,$EE,$EC
  DEFB $CF,$07,$3A,$7C,$39,$93,$C7,$06
  DEFB $B9,$33,$77,$0F,$C2,$98,$B9,$7B
  DEFB $A6,$80,$B9,$33,$63,$03,$89,$8C
  DEFB $48,$E0,$F0,$E4,$C3,$88,$93,$27
  DEFB $1C,$19,$03,$87,$A7,$13,$42,$61
  DEFB $C0,$E0,$F0,$C0,$98,$7C,$FC,$FE
  DEFB $50,$07,$3B,$38,$10,$07,$0F,$01
  DEFB $70,$79,$73,$87,$01,$E0,$CE,$9F
  DEFB $03,$E0,$C7,$CF,$9F,$1F,$0F,$0F
  DEFB $0F,$0F,$CF,$CF,$E6,$F4,$F1,$F9
  DEFB $02,$30,$3B,$1B,$01,$8C,$C4,$E1
  DEFB $68,$0C,$64,$71,$23,$0A,$98,$B8
  DEFB $FE,$C2,$3C,$7E,$7E,$7E,$7E,$3E
  DEFB $00,$00,$00,$00,$01,$03,$03,$01
  DEFB $00,$38,$7C,$FE,$B7,$6C,$6C,$B6
  DEFB $00,$00,$01,$03,$06,$0D,$0D,$06
  DEFB $3C,$FF,$FE,$FF,$DF,$B1,$B0,$D9
  DEFB $3F,$8F,$E0,$3F,$9F,$CF,$C7,$80
  DEFB $83,$C1,$E1,$F3,$F6,$ED,$CD,$06
  DEFB $F9,$FC,$FC,$7E,$DF,$B1,$B0,$DB
  DEFB $F0,$F4,$E6,$4F,$1F,$9F,$8F,$03
  DEFB $10,$C0,$01,$05,$7C,$BE,$BF,$9F
  DEFB $1E,$EC,$F4,$F8,$F8,$F0,$60,$00
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $00,$36,$76,$76,$76,$76,$54,$76
  DEFB $76,$76,$54,$76,$76,$76,$54,$76
  DEFB $76,$00,$3F,$2F,$3F,$00,$76,$76
  DEFB $64,$76,$76,$76,$64,$76,$76,$76
  DEFB $00,$36,$7B,$77,$7F,$3E,$18,$00
  DEFB $18,$18,$7E,$7E,$18,$18,$18,$00
  DEFB $C0,$40,$C0,$C0,$40,$C0,$C0,$C0
  DEFB $1C,$1F,$1D,$3F,$3F,$3F,$1F,$6F
  DEFB $38,$F8,$38,$EC,$EC,$F4,$E8,$DC
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$E3,$D5,$6A,$3E,$7F
  DEFB $1E,$1D,$1D,$1C,$1E,$1A,$1A,$1A
  DEFB $08,$08,$08,$88,$88,$08,$08,$08
  DEFB $1A,$1A,$1E,$1D,$1D,$1B,$1A,$1A
  DEFB $88,$88,$80,$08,$00,$88,$88,$08
  DEFB $ED,$FD,$FE,$76,$0B,$33,$07,$1E
  DEFB $0A,$05,$00,$00,$09,$06,$08,$0C
  DEFB $FF,$86,$3C,$C6,$00,$00,$00,$00
  DEFB $80,$80,$40,$04,$04,$02,$10,$08
  DEFB $48,$E0,$E2,$47,$17,$BA,$38,$12
  DEFB $78,$BC,$AE,$A6,$E2,$71,$39,$19
  DEFB $FF,$3F,$0F,$18,$30,$00,$00,$00
  DEFB $00,$00,$00,$10,$00,$00,$00,$00
  DEFB $60,$18,$0C,$0E,$06,$07,$15,$47
  DEFB $00,$80,$80,$41,$70,$3F,$1F,$07
  DEFB $07,$0F,$0F,$1E,$6E,$DC,$F8,$E0
  DEFB $07,$1C,$2F,$5F,$7F,$F4,$B0,$FA
  DEFB $C0,$30,$88,$C4,$E4,$C2,$02,$10
  DEFB $BC,$B0,$A0,$80,$80,$80,$00,$80
  DEFB $22,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$01,$01,$07,$04,$00,$01,$01
  DEFB $00,$00,$00,$60,$00,$00,$00,$00
  DEFB $00,$3F,$00,$10,$10,$13,$00,$10
  DEFB $00,$FC,$00,$00,$10,$F0,$00,$00
  DEFB $08,$08,$8E,$89,$01,$09,$02,$04
  DEFB $00,$05,$05,$02,$02,$00,$FF,$B7
  DEFB $00,$38,$18,$80,$80,$50,$93,$F7
  DEFB $C0,$40,$C0,$C0,$40,$C0,$C0,$C0
  DEFB $C0,$BF,$80,$FF,$00,$80,$C0,$C0
  DEFB $00,$F0,$00,$E0,$00,$20,$60,$60
  DEFB $02,$06,$0A,$1C,$0A,$36,$36,$00
  DEFB $40,$60,$50,$38,$50,$6C,$6C,$00
  DEFB $36,$76,$6A,$1C,$5A,$66,$76,$00
  DEFB $6C,$6E,$56,$38,$5A,$66,$6E,$00
  DEFB $00,$20,$72,$60,$00,$22,$34,$10
  DEFB $D4,$D4,$55,$95,$A6,$E2,$6A,$52
  DEFB $D0,$D0,$41,$81,$88,$88,$08,$12
  DEFB $10,$10,$0A,$0C,$50,$30,$08,$08
  DEFB $C4,$80,$01,$01,$01,$82,$46,$7A
  DEFB $00,$3E,$7F,$4F,$49,$36,$3E,$2A
  DEFB $00,$00,$20,$60,$10,$08,$66,$24
  DEFB $00,$07,$08,$10,$23,$47,$84,$94
  DEFB $00,$E0,$10,$08,$E4,$F2,$91,$95
  DEFB $A7,$93,$AA,$90,$A3,$89,$AB,$89
  DEFB $75,$E1,$A9,$1D,$C9,$09,$C1,$19
  DEFB $82,$A9,$82,$A2,$90,$A2,$92,$86
  DEFB $59,$81,$29,$29,$09,$29,$29,$39
  DEFB $7C,$FE,$92,$92,$6C,$7C,$54,$00
  DEFB $1E,$21,$40,$40,$64,$50,$00,$20
  DEFB $36,$76,$6A,$1C,$5A,$66,$76,$00
  DEFB $00,$20,$72,$60,$00,$22,$34,$10
  DEFB $1E,$21,$40,$40,$64,$50,$00,$20
  DEFB $10,$10,$28,$28,$28,$28,$10,$10
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $80,$00,$80,$00,$80,$00,$80,$00
  DEFB $00,$36,$B7,$B7,$B7,$B7,$95,$B7
  DEFB $B7,$B7,$95,$B7,$B7,$B7,$95,$B7
  DEFB $B7,$00,$FE,$FA,$FE,$00,$B7,$B7
  DEFB $93,$B7,$B7,$B7,$93,$B7,$B7,$B7
  DEFB $00,$6C,$ED,$ED,$ED,$ED,$A9,$ED
  DEFB $ED,$ED,$A9,$ED,$ED,$ED,$A9,$ED
  DEFB $ED,$00,$7F,$5F,$7F,$00,$ED,$ED
  DEFB $C9,$ED,$ED,$ED,$C9,$ED,$ED,$ED
  DEFB $00,$00,$00,$0C,$0E,$26,$70,$67
  DEFB $1C,$CA,$D2,$34,$76,$6A,$14,$38
  DEFB $38,$53,$4B,$2C,$6E,$56,$28,$1C
  DEFB $00,$00,$00,$30,$70,$64,$0E,$E6
  DEFB $00,$03,$07,$02,$18,$1D,$0D,$01
  DEFB $06,$10,$0B,$42,$20,$80,$B0,$20
  DEFB $1A,$80,$00,$1E,$58,$C6,$B2,$74
  DEFB $58,$01,$00,$78,$1A,$63,$4D,$2E
  DEFB $60,$08,$D0,$42,$04,$01,$0D,$04
  DEFB $00,$C0,$E0,$40,$18,$B8,$B0,$80
  DEFB $60,$6C,$1D,$BB,$C5,$9A,$6C,$00
  DEFB $46,$0D,$03,$9B,$98,$15,$96,$00
  DEFB $2E,$10,$80,$46,$8E,$96,$98,$18
  DEFB $74,$08,$01,$62,$71,$69,$19,$18
  DEFB $62,$B0,$C0,$D9,$19,$A8,$69,$00
  DEFB $06,$36,$B8,$DD,$A3,$59,$36,$00
  DEFB $00,$6C,$9A,$C5,$BB,$1D,$6C,$60
  DEFB $00,$96,$15,$98,$9B,$03,$0D,$46
  DEFB $16,$86,$9A,$8C,$46,$80,$10,$2E
  DEFB $68,$61,$59,$31,$62,$01,$08,$74
  DEFB $00,$69,$A8,$19,$D9,$C0,$B0,$62
  DEFB $00,$36,$59,$A3,$DD,$B8,$36,$06
  DEFB $01,$0D,$1D,$18,$02,$07,$03,$00
  DEFB $20,$B0,$80,$20,$42,$0B,$10,$06
  DEFB $74,$B2,$C6,$58,$1E,$00,$80,$1A
  DEFB $2E,$4D,$63,$1A,$78,$00,$01,$58
  DEFB $04,$0D,$01,$04,$42,$D0,$08,$60
  DEFB $80,$B0,$B8,$18,$40,$E0,$C0,$00
  DEFB $67,$70,$26,$0E,$0C,$00,$00,$00
  DEFB $38,$14,$6A,$76,$34,$D2,$CA,$1C
  DEFB $1C,$28,$56,$6E,$2C,$4B,$53,$38
  DEFB $E6,$0E,$64,$70,$30,$00,$00,$00
  DEFB $00,$00,$03,$0C,$30,$43,$8A,$10
  DEFB $0F,$F1,$01,$2D,$45,$01,$0F,$70
  DEFB $F0,$8F,$80,$B4,$A2,$80,$F0,$0E
  DEFB $00,$00,$C0,$30,$0C,$C2,$51,$08
  DEFB $02,$04,$08,$09,$12,$10,$26,$24
  DEFB $81,$46,$28,$18,$2E,$49,$44,$84
  DEFB $80,$00,$00,$00,$00,$00,$C0,$30
  DEFB $01,$00,$00,$00,$00,$00,$03,$0C
  DEFB $81,$62,$14,$18,$74,$92,$22,$21
  DEFB $40,$20,$10,$90,$48,$08,$64,$24
  DEFB $40,$49,$51,$41,$92,$9A,$82,$FE
  DEFB $82,$02,$02,$01,$01,$00,$00,$00
  DEFB $08,$06,$01,$03,$0C,$91,$E1,$81
  DEFB $10,$60,$80,$C0,$30,$89,$87,$81
  DEFB $41,$40,$40,$80,$80,$00,$00,$00
  DEFB $02,$92,$8A,$82,$49,$59,$41,$7F
  DEFB $FE,$82,$9A,$92,$41,$51,$49,$40
  DEFB $03,$0C,$10,$60,$80,$00,$FF,$80
  DEFB $41,$47,$27,$21,$21,$10,$FF,$10
  DEFB $82,$E2,$E4,$84,$84,$08,$FF,$08
  DEFB $C0,$30,$08,$06,$01,$00,$FF,$01
  DEFB $7F,$41,$59,$49,$82,$8A,$92,$02
  DEFB $24,$26,$10,$12,$09,$08,$04,$02
  DEFB $80,$40,$40,$20,$10,$28,$46,$81
  DEFB $08,$08,$04,$04,$04,$02,$02,$81
  DEFB $10,$10,$20,$20,$20,$40,$40,$81
  DEFB $01,$02,$02,$04,$08,$14,$62,$81
  DEFB $24,$64,$08,$48,$90,$10,$20,$40
  DEFB $10,$8A,$43,$30,$0C,$03,$00,$00
  DEFB $71,$0F,$01,$45,$2D,$01,$F1,$0F
  DEFB $8E,$F0,$80,$A2,$B4,$80,$8F,$F0
  DEFB $08,$51,$C2,$0C,$30,$C0,$00,$00
