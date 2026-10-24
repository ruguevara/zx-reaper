; Item sprites: the doorway arch (16x24) and 14 sprites of 16x16 pixels
;
; Plain (unpacked) sprite graphics, 16 pixels wide: 2 bytes per pixel row, no
; mask (the outline comes from the table built at $FF00 by StartUp). They are
; not copied to the sprite sheet: the frame lists at FramesHeart point here and
; the sprite drawer reads them directly (popping 2 bytes per row, see
; DrawBlockJob). A frame is selected by the item handlers from RoomItemHandler
; on; frames are listed with the item they belong to.
;
; +$0000 SpriteArch: doorway arch, 24 rows (48 bytes), the passage between
; rooms 10 and 19 +$0030 SpriteCheckpoint0: checkpoint (cross in a ring), not
; yet touched +$0050 SpriteCheckpoint1: checkpoint, active +$0070 SpriteBell0:
; bell at rest (Tower of the Bell) +$0090 SpriteBell1: bell swinging +$00B0
; SpriteLever0: lever, not pulled +$00D0 SpriteLever1: lever, pulled +$00F0
; SpriteWheel0: the wheel of faith at rest +$0110 SpriteWheel1: the wheel of
; faith turned (ornate frame) +$0130 SpriteChalice: the chalice in Satan's room
; +$0150 SpriteHeart0, +$0170 SpriteHeart1: heart (extra life), two frames
; (beating) +$0190 SpriteCross: cross, drawn in six colours by the frame lists
; +$01B0 SpritePlus: plus-shaped cross, the other look of the crosses: the
; frame lists FramesHeart repeat the cross in six colours as SpriteCross and as
; SpritePlus, and ActionCrossWheelTurned/ActionCrossWheelRest pick one
; depending on the wheel of faith (WheelState) +$01D0 SpriteScroll: parchment;
; drawn red for the scroll that ends the game
SpriteArch:
  DEFB $07,$E0
  DEFB $1D,$50
  DEFB $28,$2C
  DEFB $40,$04
  DEFB $60,$02
  DEFB $40,$06
  DEFB $A0,$03
  DEFB $C0,$01
  DEFB $80,$03
  DEFB $C0,$01
  DEFB $80,$03
  DEFB $C0,$01
  DEFB $80,$03
  DEFB $C0,$01
  DEFB $80,$03
  DEFB $C0,$01
  DEFB $80,$03
  DEFB $C0,$01
  DEFB $80,$03
  DEFB $C0,$01
  DEFB $80,$03
  DEFB $C0,$01
  DEFB $80,$03
  DEFB $C0,$01
SpriteCheckpoint0:
  DEFB $07,$E0
  DEFB $0C,$30
  DEFB $1B,$D8
  DEFB $31,$8C
  DEFB $29,$94
  DEFB $2F,$F4
  DEFB $2F,$F4
  DEFB $29,$94
  DEFB $31,$8C
  DEFB $1B,$D8
  DEFB $0C,$30
  DEFB $0F,$F0
  DEFB $0F,$F0
  DEFB $0F,$F0
  DEFB $1C,$B8
  DEFB $1F,$F8
SpriteCheckpoint1:
  DEFB $07,$E0
  DEFB $0C,$30
  DEFB $1A,$58
  DEFB $36,$6C
  DEFB $2F,$F4
  DEFB $23,$C4
  DEFB $23,$C4
  DEFB $2F,$F4
  DEFB $36,$6C
  DEFB $1A,$58
  DEFB $0C,$30
  DEFB $0F,$F0
  DEFB $0F,$F0
  DEFB $0F,$F0
  DEFB $1C,$B8
  DEFB $1F,$F8
SpriteBell0:
  DEFB $01,$80
  DEFB $00,$00
  DEFB $07,$E0
  DEFB $0F,$D0
  DEFB $1F,$E8
  DEFB $1F,$E8
  DEFB $3F,$F4
  DEFB $3F,$F4
  DEFB $3F,$FC
  DEFB $3F,$F4
  DEFB $3F,$FC
  DEFB $7F,$FE
  DEFB $C0,$03
  DEFB $7F,$66
  DEFB $00,$70
  DEFB $00,$30
SpriteBell1:
  DEFB $01,$80
  DEFB $00,$00
  DEFB $07,$E0
  DEFB $0F,$D0
  DEFB $1F,$E8
  DEFB $1F,$E8
  DEFB $3F,$F4
  DEFB $3F,$F4
  DEFB $3F,$FC
  DEFB $3F,$F4
  DEFB $3F,$FC
  DEFB $7F,$FE
  DEFB $C0,$03
  DEFB $76,$FE
  DEFB $0E,$00
  DEFB $0C,$00
SpriteLever0:
  DEFB $00,$00
  DEFB $00,$00
  DEFB $18,$00
  DEFB $18,$00
  DEFB $0C,$00
  DEFB $0C,$00
  DEFB $06,$00
  DEFB $06,$00
  DEFB $03,$00
  DEFB $03,$00
  DEFB $01,$80
  DEFB $01,$80
  DEFB $00,$00
  DEFB $1F,$F8
  DEFB $3F,$FC
  DEFB $7F,$FE
SpriteLever1:
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$18
  DEFB $00,$18
  DEFB $00,$30
  DEFB $00,$30
  DEFB $00,$60
  DEFB $00,$60
  DEFB $00,$C0
  DEFB $00,$C0
  DEFB $01,$80
  DEFB $01,$80
  DEFB $00,$00
  DEFB $1F,$F8
  DEFB $3F,$FC
  DEFB $7F,$FE
SpriteWheel0:
  DEFB $01,$80
  DEFB $01,$80
  DEFB $07,$E0
  DEFB $0F,$F0
  DEFB $1C,$38
  DEFB $3E,$7C
  DEFB $36,$6C
  DEFB $F0,$0F
  DEFB $F0,$0F
  DEFB $36,$6C
  DEFB $3E,$7C
  DEFB $1C,$38
  DEFB $0F,$F0
  DEFB $07,$E0
  DEFB $01,$80
  DEFB $01,$80
SpriteWheel1:
  DEFB $00,$00
  DEFB $60,$06
  DEFB $77,$EE
  DEFB $3F,$FC
  DEFB $1E,$78
  DEFB $3E,$7C
  DEFB $3E,$7C
  DEFB $3E,$7C
  DEFB $38,$1C
  DEFB $38,$1C
  DEFB $3E,$7C
  DEFB $1E,$78
  DEFB $3F,$FC
  DEFB $77,$EE
  DEFB $60,$06
  DEFB $00,$00
SpriteChalice:
  DEFB $00,$00
  DEFB $00,$00
  DEFB $1F,$F8
  DEFB $1F,$F8
  DEFB $0D,$B0
  DEFB $1F,$F8
  DEFB $0F,$F0
  DEFB $07,$E0
  DEFB $01,$80
  DEFB $01,$80
  DEFB $01,$80
  DEFB $01,$80
  DEFB $03,$C0
  DEFB $07,$E0
  DEFB $1F,$F8
  DEFB $00,$00
SpriteHeart0:
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $06,$C0
  DEFB $0F,$E0
  DEFB $0F,$E0
  DEFB $0F,$A0
  DEFB $0F,$A0
  DEFB $07,$40
  DEFB $03,$80
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
SpriteHeart1:
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $06,$C0
  DEFB $0F,$E0
  DEFB $0F,$A0
  DEFB $07,$40
  DEFB $03,$80
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
SpriteCross:
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $03,$C0
  DEFB $01,$80
  DEFB $09,$90
  DEFB $0F,$F0
  DEFB $0F,$F0
  DEFB $09,$90
  DEFB $01,$80
  DEFB $03,$C0
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
SpritePlus:
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $01,$80
  DEFB $01,$80
  DEFB $01,$80
  DEFB $01,$80
  DEFB $07,$E0
  DEFB $07,$E0
  DEFB $01,$80
  DEFB $01,$80
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
SpriteScroll:
  DEFB $0F,$FC
  DEFB $1F,$FA
  DEFB $1F,$F2
  DEFB $1F,$F4
  DEFB $10,$B0
  DEFB $1F,$F0
  DEFB $12,$30
  DEFB $1F,$F0
  DEFB $10,$F0
  DEFB $1F,$F0
  DEFB $10,$34
  DEFB $1F,$F2
  DEFB $1F,$FA
  DEFB $0F,$FC
  DEFB $00,$00
  DEFB $00,$00

; Packed sprite set 0 (op $97 $00): 4 columns of 3 character rows
;
; Sprite sets are the animated sprites of the enemies and of Satan, stored
; packed and unpacked into the sprite sheet (SpriteSheet) when a room is
; entered: the room script op $97 N (OpUnpackSprites) calls UnpackSpriteSet,
; which reads record N of UnpackRecords (destination, this address, flags,
; frame width) and fills the sheet columns. Format of a set: byte 0 = total
; columns (frames x frame width), byte 1 = height in character rows (8 pixel
; rows each); then for each column and for each 8 pixel rows one flag byte
; (most significant bit first: a set bit means that a literal byte follows, a
; clear bit repeats the previous pixel byte of the column: 0 only at the top of
; a column, the byte carries over from one character row to the next; observed,
; F113). Unpacking also builds the copies selected by the record's flags: bit 7
; adds three copies shifted by 2, 4 and 6 pixels (for the 2-pixel x positions
; of the entities), bit 6 adds mirrored frames (for the other direction).
;
; Unpacked by room script op $97 $00 into the sprite sheet at $D7F8 (page =
; first pixel row, low byte = first column) with record 0 of UnpackRecords:
; frame width 2 columns, mirrored copies (bit 6). 4 columns x 3 character rows
; (24 pixel rows), 74 bytes packed. Used by rooms: 17, 21.
PackedSet0:
  DEFB $04,$03
  DEFB $00,$DB,$0D,$14,$25,$24,$34,$2E,$FD,$25,$24,$14,$15,$0D,$01,$07
  DEFB $01,$F0,$DF,$F8,$98,$78,$F0,$10,$E6,$16,$FF,$AA,$14,$28,$98,$70
  DEFB $26,$5A,$62,$00,$FF,$11,$28,$24,$43,$41,$40,$FF,$40,$FD,$41,$42
  DEFB $24,$29,$11,$01,$07,$01,$F0,$DF,$F8,$98,$78,$F0,$90,$FA,$C0,$FF
  DEFB $28,$14,$28,$98,$70,$26,$5A,$62

; Packed sprite set 1 (op $97 $01): 4 columns of 3 character rows
;
; Unpacked by room script op $97 $01 into the sprite sheet at $D763 (page =
; first pixel row, low byte = first column) with record 1 of UnpackRecords:
; frame width 2 columns, pre-shifted copies (bit 7) and mirrored copies (bit
; 6). 4 columns x 3 character rows (24 pixel rows), 99 bytes packed. Used by
; rooms: 0, 4, 5, 6, 24. Probably the crusaders (rooms 4-6 are the chase, room
; 24 and 25 the ending).
PackedSet1:
  DEFB $04,$03
  DEFB $FF,$01,$03,$04,$0B,$17,$11,$15,$14,$FF,$12,$09,$84,$C2,$E4,$62
  DEFB $74,$32,$EF,$48,$30,$06,$03,$05,$0E,$0F,$FE,$E0,$F0,$38,$DC,$EE
  DEFB $2E,$EE,$FD,$6C,$D8,$34,$00,$FE,$E6,$80,$5F,$E6,$64,$38,$00,$1C
  DEFB $38,$7F,$01,$03,$04,$0B,$17,$11,$15,$FF,$14,$92,$C9,$C4,$C2,$E5
  DEFB $62,$65,$FF,$93,$68,$10,$03,$01,$00,$02,$01,$7F,$E0,$F0,$38,$DC
  DEFB $EE,$2E,$EE,$7E,$6C,$D8,$34,$00,$7F,$73,$AF,$40,$73,$B2,$1C,$C0
  DEFB $E0

; Packed sprite set 2 (op $97 $02): 12 columns of 4 character rows
;
; Unpacked by room script op $97 $02 into the sprite sheet at $D763 (page =
; first pixel row, low byte = first column) with record 2 of UnpackRecords:
; frame width 4 columns, pre-shifted copies (bit 7) and mirrored copies (bit
; 6). 12 columns x 4 character rows (32 pixel rows), 302 bytes packed. Used by
; rooms: 18.
PackedSet2:
  DEFB $0C,$04
  DEFB $7F,$1F,$3F,$7F,$F0,$E0,$C1,$83,$FF,$82,$84,$44,$04,$06,$03,$01
  DEFB $04,$98,$05,$04,$08,$40,$00,$5F,$80,$9F,$3F,$FE,$BF,$1F,$EF,$67
  DEFB $F9,$92,$EE,$7C,$54,$83,$FF,$7C,$80,$E0,$F0,$71,$7E,$3C,$1F,$C0
  DEFB $07,$00,$1F,$80,$D8,$F0,$60,$80,$FF,$C0,$E8,$F5,$73,$31,$22,$C0
  DEFB $01,$EF,$06,$08,$00,$80,$00,$18,$FE,$F0,$80,$60,$1F,$00,$00,$7F
  DEFB $80,$E0,$C0,$7E,$64,$C8,$87,$FF,$0E,$1C,$30,$7E,$1C,$30,$08,$04
  DEFB $F0,$18,$F0,$80,$00,$7F,$1F,$3F,$7F,$F0,$E0,$C1,$83,$FF,$82,$84
  DEFB $44,$04,$06,$03,$01,$04,$A8,$05,$04,$08,$40,$00,$5F,$80,$9F,$3F
  DEFB $FE,$BF,$1F,$EF,$67,$F9,$92,$EE,$7C,$54,$83,$FF,$7C,$80,$E0,$F0
  DEFB $78,$3F,$1C,$0E,$E0,$03,$01,$00,$1F,$80,$D8,$F0,$60,$80,$FF,$C8
  DEFB $E5,$F3,$71,$32,$20,$C1,$02,$CD,$04,$00,$C0,$00,$18,$F8,$FE,$80
  DEFB $60,$1F,$00,$00,$FF,$80,$E0,$C0,$7E,$64,$C8,$87,$0E,$FF,$1C,$30
  DEFB $78,$1F,$0E,$18,$30,$08,$F8,$04,$18,$F0,$80,$00,$1E,$01,$03,$02
  DEFB $04,$78,$06,$03,$01,$00,$00,$00,$FF,$1F,$3F,$FE,$BF,$1F,$67,$F9
  DEFB $FE,$BF,$92,$6C,$54,$83,$7C,$80,$A0,$FF,$B8,$BC,$9F,$4E,$67,$63
  DEFB $60,$F0,$F0,$A8,$A4,$10,$00,$FF,$80,$D8,$F0,$60,$80,$C0,$E8,$F5
  DEFB $FF,$73,$31,$22,$C0,$01,$06,$08,$00,$EF,$40,$80,$00,$F0,$98,$C4
  DEFB $21,$E0,$12,$0C,$00,$03,$80,$E0,$FF,$C0,$7E,$64,$C8,$87,$0E,$1C
  DEFB $30,$FF,$7E,$1C,$30,$08,$04,$18,$30,$C0,$80,$00

; Packed sprite set 3 (op $97 $03): 4 columns of 3 character rows
;
; Unpacked by room script op $97 $03 into the sprite sheet at $D7BB (page =
; first pixel row, low byte = first column) with record 3 of UnpackRecords:
; frame width 2 columns, pre-shifted copies (bit 7) and mirrored copies (bit
; 6). 4 columns x 3 character rows (24 pixel rows), 91 bytes packed. Used by
; rooms: 21, 22.
PackedSet3:
  DEFB $04,$03
  DEFB $1F,$09,$1F,$3F,$1C,$08,$FF,$29,$37,$3F,$23,$1F,$00,$09,$1F,$FD
  DEFB $1E,$1D,$0E,$04,$00,$08,$30,$1F,$C0,$88,$84,$DC,$CE,$5F,$CF,$97
  DEFB $13,$23,$CB,$4B,$FF,$8B,$0B,$8B,$12,$92,$44,$24,$60,$3F,$09,$1F
  DEFB $3F,$1C,$08,$29,$FF,$37,$3F,$23,$1F,$00,$09,$1F,$1E,$F9,$1D,$0E
  DEFB $04,$01,$05,$0B,$3E,$C0,$88,$84,$DC,$CE,$BF,$CF,$97,$13,$23,$CB
  DEFB $4B,$8B,$EE,$0B,$8B,$12,$24,$04,$00

; Packed sprite set 4 (op $97 $04): 6 columns of 2 character rows
;
; Unpacked by room script op $97 $04 into the sprite sheet at $EF63 (page =
; first pixel row, low byte = first column) with record 4 of UnpackRecords:
; frame width 3 columns, pre-shifted copies (bit 7) and mirrored copies (bit
; 6). 6 columns x 2 character rows (16 pixel rows), 68 bytes packed. Used by
; rooms: 20, 23.
PackedSet4:
  DEFB $06,$02
  DEFB $0F,$10,$30,$7A,$DF,$FE,$BF,$E3,$C1,$4F,$07,$01,$00,$03,$AA,$FF
  DEFB $7B,$FC,$F8,$FC,$FF,$7F,$00,$01,$E6,$EF,$FF,$18,$00,$FC,$F8,$E0
  DEFB $00,$1F,$01,$03,$12,$30,$7A,$FC,$DF,$BF,$E3,$C0,$40,$00,$27,$FF
  DEFB $7E,$70,$FA,$B8,$FF,$FC,$F0,$00,$3D,$E0,$F8,$FC,$00,$30,$E0,$FF
  DEFB $CC,$00

; Packed sprite set 5 (op $97 $05): 10 columns of 3 character rows
;
; Unpacked by room script op $97 $05 into the sprite sheet at $D768 (page =
; first pixel row, low byte = first column) with record 5 of UnpackRecords:
; frame width 2 columns, no extra copies. 10 columns x 3 character rows (24
; pixel rows), 148 bytes packed. Used by rooms: 10.
PackedSet5:
  DEFB $0A,$03
  DEFB $09,$07,$0F,$49,$1F,$3F,$7F,$29,$3F,$3E,$3F,$09,$80,$00,$A3,$80
  DEFB $C0,$E0,$20,$D5,$00,$80,$C0,$40,$00,$0B,$01,$02,$01,$77,$03,$07
  DEFB $03,$07,$06,$0D,$98,$00,$01,$00,$90,$7F,$FF,$2B,$EF,$DF,$9F,$3F
  DEFB $1E,$17,$05,$44,$00,$5F,$80,$C0,$80,$90,$82,$C0,$F4,$E4,$C0,$E0
  DEFB $F0,$E0,$EB,$B0,$98,$80,$C0,$60,$00,$09,$01,$00,$A3,$01,$03,$07
  DEFB $04,$D5,$00,$01,$03,$02,$00,$09,$E0,$F0,$49,$F8,$FC,$FE,$29,$FC
  DEFB $7C,$FC,$5F,$01,$03,$01,$09,$41,$03,$F4,$27,$03,$07,$0F,$07,$EB
  DEFB $0D,$19,$01,$03,$06,$00,$90,$FE,$FF,$2B,$F7,$FB,$F9,$FC,$1E,$E8
  DEFB $A0,$22,$00,$0B,$80,$40,$80,$77,$C0,$E0,$C0,$E0,$60,$B0,$98,$00
  DEFB $80,$00

; Packed sprite set 6 (op $97 $06): 4 columns of 5 character rows
;
; Unpacked by room script op $97 $06 into the sprite sheet at $D763 (page =
; first pixel row, low byte = first column) with record 6 of UnpackRecords:
; frame width 5 columns, no extra copies. 4 columns x 5 character rows (40
; pixel rows), 117 bytes packed. Used by rooms: 10.
PackedSet6:
  DEFB $04,$05
  DEFB $00,$12,$01,$03,$3F,$07,$06,$0E,$0F,$0E,$0F,$1E,$07,$03,$01,$00
  DEFB $00,$1D,$10,$30,$60,$E0,$3F,$F1,$FF,$FC,$F0,$C0,$80,$FF,$F0,$F8
  DEFB $3C,$1C,$1E,$2F,$96,$47,$ED,$87,$F6,$FF,$FE,$FF,$67,$FF,$59,$27
  DEFB $23,$13,$2F,$1F,$07,$00,$1D,$08,$0C,$06,$27,$FF,$67,$E7,$CF,$FF
  DEFB $9F,$07,$83,$01,$FF,$87,$0F,$1E,$BC,$3C,$7A,$B4,$F1,$FF,$70,$B7
  DEFB $FF,$7F,$BF,$FF,$7F,$F3,$FF,$CD,$F2,$E2,$E4,$FA,$FC,$F0,$00,$00
  DEFB $24,$80,$C0,$BF,$E0,$70,$30,$38,$78,$B8,$78,$9F,$F8,$F0,$E0,$C0
  DEFB $80,$00,$00

; Packed sprite set 7 (op $97 $07): 2 columns of 4 character rows
;
; Unpacked by room script op $97 $07 into the sprite sheet at $D7E7 (page =
; first pixel row, low byte = first column) with record 7 of UnpackRecords:
; frame width 2 columns, no extra copies. 2 columns x 4 character rows (32
; pixel rows), 44 bytes packed. Used by rooms: 22, 23.
PackedSet7:
  DEFB $02,$04
  DEFB $0F,$07,$02,$06,$0D,$F8,$09,$0E,$0B,$01,$00,$0F,$03,$06,$0D,$0B
  DEFB $78,$0D,$06,$03,$00,$0F,$80,$D0,$70,$90,$F8,$B0,$60,$40,$E0,$00
  DEFB $0F,$C0,$60,$B0,$D0,$78,$B0,$60,$C0,$00

; Packed sprite set 8 (op $97 $08): 4 columns of 2 character rows
;
; Unpacked by room script op $97 $08 into the sprite sheet at $D763 (page =
; first pixel row, low byte = first column) with record 8 of UnpackRecords:
; frame width 2 columns, mirrored copies (bit 6). 4 columns x 2 character rows
; (16 pixel rows), 59 bytes packed. Used by rooms: 12.
PackedSet8:
  DEFB $04,$02
  DEFB $0F,$1C,$01,$3C,$7E,$BC,$52,$2D,$02,$3C,$00,$1F,$1C,$7E,$FC,$F8
  DEFB $C4,$FE,$16,$D4,$E8,$A8,$28,$20,$00,$7F,$60,$F0,$F9,$7B,$01,$3C
  DEFB $7E,$BE,$52,$2D,$02,$0A,$1D,$00,$FF,$3C,$7E,$FE,$FC,$F8,$F0,$C8
  DEFB $04,$FE,$16,$D4,$E8,$A8,$30,$40,$00

; Packed sprite set 9 (op $97 $09): 4 columns of 2 character rows
;
; Unpacked by room script op $97 $09 into the sprite sheet at $D76B (page =
; first pixel row, low byte = first column) with record 9 of UnpackRecords:
; frame width 2 columns, mirrored copies (bit 6). 4 columns x 2 character rows
; (16 pixel rows), 59 bytes packed. Used by rooms: 12.
PackedSet9:
  DEFB $04,$02
  DEFB $EF,$02,$07,$06,$04,$01,$3C,$7E,$FE,$12,$5E,$1F,$06,$24,$19,$00
  DEFB $FF,$1C,$3E,$7E,$FC,$F8,$F0,$C8,$04,$FE,$56,$D4,$F8,$A8,$A4,$40
  DEFB $00,$07,$01,$3C,$7E,$FC,$12,$5E,$1F,$06,$3C,$00,$1F,$1C,$7E,$FC
  DEFB $F8,$C4,$F6,$16,$D4,$F8,$A8,$A0,$00

; Packed sprite set 10 (op $97 $0A): 2 columns of 3 character rows
;
; Unpacked by room script op $97 $0A into the sprite sheet at $D763 (page =
; first pixel row, low byte = first column) with record 10 of UnpackRecords:
; frame width 2 columns, mirrored copies (bit 6). 2 columns x 3 character rows
; (24 pixel rows), 44 bytes packed. Used by rooms: 9.
PackedSet10:
  DEFB $02,$03
  DEFB $FF,$07,$0C,$1A,$16,$15,$16,$12,$1B,$FE,$0C,$07,$00,$05,$08,$0D
  DEFB $0F,$07,$0C,$0F,$07,$FD,$F0,$38,$1C,$4E,$EE,$6E,$CE,$F8,$1A,$F4
  DEFB $00,$98,$B8,$7D,$88,$98,$D0,$60,$E0,$C0

; Packed sprite set 11 (op $97 $0B): 4 columns of 3 character rows
;
; Unpacked by room script op $97 $0B into the sprite sheet at $D763 (page =
; first pixel row, low byte = first column) with record 11 of UnpackRecords:
; frame width 2 columns, pre-shifted copies (bit 7) and mirrored copies (bit
; 6). 4 columns x 3 character rows (24 pixel rows), 99 bytes packed. Used by
; rooms: 15, 20.
PackedSet11:
  DEFB $04,$03
  DEFB $7D,$01,$03,$07,$0F,$02,$0F,$FF,$0A,$8F,$C5,$C3,$C0,$E5,$62,$65
  DEFB $FF,$93,$68,$10,$03,$01,$00,$02,$01,$7F,$EE,$F7,$FB,$FD,$1D,$1C
  DEFB $FC,$FE,$BC,$FC,$78,$F4,$00,$7F,$73,$5F,$40,$73,$B2,$1C,$C0,$E0
  DEFB $FB,$01,$03,$07,$0F,$02,$0F,$0A,$FF,$0F,$05,$83,$C0,$E4,$62,$74
  DEFB $32,$EF,$48,$30,$06,$03,$05,$0E,$0F,$FF,$EE,$F7,$FB,$FD,$1D,$1C
  DEFB $FC,$BC,$FC,$FC,$78,$F4,$00,$FE,$E6,$BF,$80,$E6,$64,$38,$00,$1C
  DEFB $38

; Packed sprite set 12 (op $97 $0C): 4 columns of 2 character rows
;
; Unpacked by room script op $97 $0C into the sprite sheet at $D763 (page =
; first pixel row, low byte = first column) with record 12 of UnpackRecords:
; frame width 2 columns, pre-shifted copies (bit 7) and mirrored copies (bit
; 6). 4 columns x 2 character rows (16 pixel rows), 70 bytes packed. Used by
; rooms: 11.
PackedSet12:
  DEFB $04,$02
  DEFB $FB,$02,$17,$1F,$3F,$7F,$CF,$E6,$FF,$BF,$DF,$4A,$60,$35,$1F,$07
  DEFB $00,$FB,$A0,$B0,$F4,$FC,$FE,$3F,$7B,$FF,$F7,$E6,$CE,$1C,$38,$F0
  DEFB $C0,$00,$F7,$05,$1F,$3F,$7F,$CF,$E6,$BF,$FF,$9F,$CA,$C0,$40,$60
  DEFB $35,$1F,$07,$FF,$40,$68,$F8,$FC,$FE,$3E,$7F,$F3,$EF,$E7,$C7,$0E
  DEFB $1C,$38,$F0,$C0

; Packed sprite set 13 (op $97 $0D): 4 columns of 2 character rows
;
; Unpacked by room script op $97 $0D into the sprite sheet at $D763 (page =
; first pixel row, low byte = first column) with record 13 of UnpackRecords:
; frame width 2 columns, pre-shifted copies (bit 7) and mirrored copies (bit
; 6). 4 columns x 2 character rows (16 pixel rows), 47 bytes packed. Used by
; rooms: 2. Rats (the cyan rats of room 2).
PackedSet13:
  DEFB $04,$02
  DEFB $03,$05,$1B,$FF,$3F,$6F,$CF,$FF,$5B,$02,$04,$00,$03,$86,$C1,$FF
  DEFB $F1,$FB,$FF,$DE,$1C,$0F,$03,$06,$00,$FF,$05,$1B,$3F,$6F,$CF,$FF
  DEFB $5B,$01,$01,$02,$FF,$C1,$F1,$F9,$DF,$BE,$38,$18,$70

; Packed sprite set 14 (op $97 $0E): 30 columns of 3 character rows
;
; Unpacked by room script op $97 $0E into the sprite sheet at $D78F (page =
; first pixel row, low byte = first column) with record 14 of UnpackRecords:
; frame width 30 columns, no extra copies. 30 columns x 3 character rows (24
; pixel rows), 589 bytes packed. Used by rooms: 24.
PackedSet14:
  DEFB $1E,$03
  DEFB $3F,$03,$07,$0F,$1F,$37,$2F,$FF,$39,$73,$43,$E2,$FE,$FF,$BF,$FF
  DEFB $FE,$57,$07,$2E,$7C,$38,$10,$00,$FF,$3B,$77,$8F,$CF,$EF,$E6,$F0
  DEFB $F9,$BF,$FF,$7F,$BE,$CC,$70,$BF,$DF,$FF,$C7,$B0,$7C,$3F,$17,$07
  DEFB $0F,$1F,$FE,$81,$C1,$E0,$F0,$F8,$78,$38,$1F,$79,$71,$F3,$E6,$CC
  DEFB $FF,$98,$30,$70,$30,$98,$9F,$CF,$E7,$6C,$80,$C0,$60,$70,$6B,$F0
  DEFB $B0,$30,$18,$0C,$FF,$07,$0E,$1C,$38,$F8,$E8,$88,$08,$B7,$3D,$7C
  DEFB $7E,$5C,$15,$07,$FE,$22,$11,$05,$0A,$1D,$3E,$3F,$FE,$1F,$0F,$01
  DEFB $00,$01,$03,$05,$FF,$F6,$F2,$FB,$7B,$3B,$7B,$77,$76,$EF,$6E,$EE
  DEFB $DF,$9F,$2F,$C7,$03,$FE,$C1,$E0,$F0,$F8,$98,$E9,$E2,$DF,$08,$04
  DEFB $82,$F1,$FF,$02,$0C,$F5,$18,$30,$60,$C0,$C1,$E3,$E7,$FE,$7C,$00
  DEFB $80,$C0,$E0,$0F,$07,$0F,$1F,$37,$FF,$2F,$79,$73,$CB,$E3,$FE,$BE
  DEFB $FF,$CF,$AF,$07,$2E,$7C,$38,$10,$3D,$3B,$77,$CF,$EF,$E6,$EF,$F0
  DEFB $F9,$FF,$7F,$BE,$CC,$70,$FF,$BF,$DF,$C7,$B0,$7C,$37,$07,$0F,$FF
  DEFB $02,$03,$81,$C1,$E0,$F0,$F8,$78,$CF,$38,$39,$3B,$7B,$72,$F6,$FF
  DEFB $E4,$CC,$98,$38,$3C,$1F,$8F,$E7,$2C,$80,$C0,$E0,$13,$60,$30,$18
  DEFB $FF,$0E,$0C,$18,$30,$70,$F0,$D0,$10,$FF,$1F,$3F,$3E,$7E,$7F,$7E
  DEFB $5C,$15,$F9,$C6,$63,$26,$1E,$3F,$1F,$DE,$0F,$07,$03,$06,$0F,$17
  DEFB $FF,$F6,$F2,$FA,$7B,$3B,$9B,$BB,$BA,$EF,$36,$37,$F7,$77,$6F,$87
  DEFB $03,$FE,$01,$80,$C0,$E0,$60,$A0,$81,$DF,$10,$08,$04,$E2,$FE,$04
  DEFB $18,$F7,$30,$60,$C0,$80,$82,$81,$C1,$F7,$E3,$FE,$3C,$00,$C0,$60
  DEFB $70,$04,$01,$FF,$00,$0C,$1E,$1C,$19,$1B,$0B,$01,$F8,$00,$0E,$1F
  DEFB $3E,$3F,$1F,$70,$F9,$FD,$FC,$FB,$DF,$FF,$7F,$BF,$DF,$FF,$EF,$E7
  DEFB $E9,$CF,$1F,$3F,$7F,$BF,$1B,$E0,$F0,$F3,$E7,$FD,$87,$07,$E7,$F3
  DEFB $FB,$FF,$FE,$CF,$FD,$FB,$F9,$FC,$CA,$E0,$03,$E0,$F0,$85,$F8,$F0
  DEFB $F8,$87,$FC,$F8,$70,$00,$FD,$3F,$1F,$0D,$03,$0F,$1F,$1E,$F8,$0E
  DEFB $04,$01,$07,$0F,$E0,$07,$03,$00,$C0,$DF,$FF,$B8,$7F,$BF,$CF,$FF
  DEFB $FC,$DF,$BF,$1F,$0F,$07,$00,$E3,$F9,$FC,$FE,$FC,$FD,$C0,$FB,$FF
  DEFB $FC,$F3,$C0,$E0,$C0,$80,$00,$EB,$80,$B0,$38,$00,$E0,$F0,$05,$E0
  DEFB $C0,$C0,$80,$00,$0F,$07,$0F,$1F,$3F,$1F,$1F,$02,$18,$3C,$7D,$9F
  DEFB $7F,$3F,$07,$3B,$7F,$FF,$E6,$1F,$3F,$7F,$BF,$FF,$1C,$9F,$3F,$FF
  DEFB $01,$BF,$EE,$80,$C0,$E0,$E7,$EF,$FF,$0F,$E7,$F3,$FD,$FE,$49,$FF
  DEFB $FE,$FC,$06,$80,$C0,$68,$B0,$F8,$FC,$FB,$78,$70,$00,$0C,$1E,$4C
  DEFB $C0,$CF,$FF,$FE,$FC,$FE,$7E,$3C,$F7,$01,$03,$27,$77,$73,$79,$3C
  DEFB $E3,$19,$07,$0F,$07,$03,$C5,$7F,$FF,$7F,$3F,$FE,$9F,$C7,$DF,$FF
  DEFB $BF,$7F,$FF,$3B,$FB,$F8,$FD,$F8,$F0,$F8,$F0,$CD,$FE,$FC,$FD,$CF
  DEFB $FE,$FF,$FD,$F9,$F1,$23,$FB,$83,$F3,$FB,$F9,$F8,$F0,$00,$70,$38
  DEFB $7E,$FF,$68,$7E,$FC,$FE,$78,$FC,$F8,$E0,$00

; Packed sprite set 15 (op $97 $0F): 4 columns of 2 character rows
;
; Unpacked by room script op $97 $0F into the sprite sheet at $D763 (page =
; first pixel row, low byte = first column) with record 15 of UnpackRecords:
; frame width 2 columns, pre-shifted copies (bit 7). 4 columns x 2 character
; rows (16 pixel rows), 50 bytes packed. Used by rooms: 8.
PackedSet15:
  DEFB $04,$02
  DEFB $3F,$1C,$38,$70,$77,$FF,$B9,$F8,$A9,$8E,$87,$05,$00,$3F,$70,$38
  DEFB $1C,$DC,$FE,$3A,$F8,$2A,$E2,$C2,$40,$00,$1E,$30,$67,$EF,$F9,$F8
  DEFB $AE,$A7,$85,$40,$00,$1E,$18,$CC,$EE,$3E,$F8,$EA,$CA,$42,$04,$00

; Packed sprite set 16 (op $97 $10): 4 columns of 4 character rows
;
; Unpacked by room script op $97 $10 into the sprite sheet at $D7EA (page =
; first pixel row, low byte = first column) with record 16 of UnpackRecords:
; frame width 2 columns, pre-shifted copies (bit 7). 4 columns x 4 character
; rows (32 pixel rows), 67 bytes packed. Used by rooms: 18.
PackedSet16:
  DEFB $04,$04
  DEFB $0A,$FF,$78,$1F,$7C,$7F,$3F,$1F,$00,$3C,$01,$03,$02,$00,$28,$FF
  DEFB $00,$0A,$FF,$00,$1E,$40,$C0,$80,$00,$7C,$F8,$FC,$FE,$3E,$1E,$28
  DEFB $FF,$00,$80,$0C,$11,$0F,$0C,$F6,$00,$1F,$3F,$7F,$78,$70,$E0,$30
  DEFB $18,$00,$03,$18,$0C,$B7,$0E,$1E,$FE,$FC,$F8,$00,$C4,$30,$F0,$30
  DEFB $00

; Packed sprite set 17 (op $97 $11): 4 columns of 3 character rows
;
; Unpacked by room script op $97 $11 into the sprite sheet at $D763 (page =
; first pixel row, low byte = first column) with record 17 of UnpackRecords:
; frame width 2 columns, pre-shifted copies (bit 7) and mirrored copies (bit
; 6). 4 columns x 3 character rows (24 pixel rows), 87 bytes packed. Used by
; rooms: 13, 22.
PackedSet17:
  DEFB $04,$03
  DEFB $1F,$03,$04,$0B,$17,$11,$7F,$16,$13,$0A,$84,$C2,$E5,$62,$F9,$75
  DEFB $32,$49,$30,$01,$02,$1F,$F0,$38,$DC,$EE,$2E,$7F,$EE,$CC,$98,$34
  DEFB $68,$D4,$A4,$F5,$54,$A4,$04,$4C,$40,$C0,$0F,$03,$04,$0B,$17,$BF
  DEFB $11,$16,$93,$CA,$C4,$C2,$E5,$FD,$6A,$65,$92,$61,$00,$02,$0C,$0F
  DEFB $F0,$38,$DC,$EE,$BF,$2E,$EE,$CC,$98,$34,$68,$D4,$FF,$A2,$52,$A2
  DEFB $06,$26,$10,$08,$18

; Packed sprite set 18 (op $97 $12): 4 columns of 3 character rows
;
; Unpacked by room script op $97 $12 into the sprite sheet at $D78F (page =
; first pixel row, low byte = first column) with record 18 of UnpackRecords:
; frame width 2 columns, pre-shifted copies (bit 7) and mirrored copies (bit
; 6). 4 columns x 3 character rows (24 pixel rows), 91 bytes packed. Used by
; rooms: 22, 23.
PackedSet18:
  DEFB $04,$03
  DEFB $CF,$02,$01,$30,$49,$32,$75,$FF,$62,$E5,$C2,$84,$0A,$13,$16,$11
  DEFB $7C,$17,$0B,$04,$03,$00,$D7,$C0,$40,$4C,$04,$A4,$54,$FF,$A4,$D4
  DEFB $68,$34,$98,$CC,$EE,$2E,$7C,$EE,$DC,$38,$F0,$00,$DF,$0C,$02,$00
  DEFB $61,$92,$65,$6A,$FE,$E5,$C2,$C4,$CA,$93,$16,$11,$F8,$17,$0B,$04
  DEFB $03,$00,$FF,$18,$08,$10,$26,$06,$A2,$52,$A2,$FE,$D4,$68,$34,$98
  DEFB $CC,$EE,$2E,$F8,$EE,$DC,$38,$F0,$00

; Packed sprite set 19 (op $97 $13): 2 columns of 2 character rows
;
; Unpacked by room script op $97 $13 into the sprite sheet at $D7F5 (page =
; first pixel row, low byte = first column) with record 19 of UnpackRecords:
; frame width 2 columns, pre-shifted copies (bit 7). 2 columns x 2 character
; rows (16 pixel rows), 22 bytes packed. Used by rooms: 9, 14.
PackedSet19:
  DEFB $02,$02
  DEFB $0F,$30,$39,$1F,$0F,$87,$00,$0F,$3F,$39,$0F,$F0,$F8,$9C,$0C,$87
  DEFB $00,$0C,$FC,$F8

; Parchment frame tiles: 12 bitmaps of 8x8 pixels
;
; The border pieces of the parchment window (a scroll with torn edges), 8 bytes
; each, copied to the screen by DrawFrameCell (frame tile number = layout code
; - 2). The attributes of the frame cells and of the blank interior cells come
; from BC of ShowTextWindow (C = frame, B = interior).
;
; +0 top-left corner, +1 and +2 two variants of the top edge, +3 top-right
; corner, +4 and +6 left edge variants, +5 and +7 right edge variants, +8
; bottom-left corner, +9 and +10 bottom edge variants, +11 bottom-right corner
; (tile n is at $717F+8*n)
ParchmentFrameTiles:
  DEFB $06,$0F,$1F,$3E,$5C,$89,$93,$47
  DEFB $00,$00,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $00,$00,$61,$FF,$FF,$FF,$FF,$FF
  DEFB $60,$F0,$F8,$7C,$3A,$91,$C9,$E2
  DEFB $7F,$3F,$3F,$3F,$3F,$7F,$7F,$3F
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F
  DEFB $FC,$FE,$FE,$FC,$FC,$FC,$FC,$FE
  DEFB $47,$93,$89,$5C,$3E,$1F,$0F,$06
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$00,$00
  DEFB $FF,$FF,$FF,$FF,$FF,$86,$00,$00
  DEFB $E3,$C9,$91,$3A,$7C,$F8,$F0,$60

; Parchment frame layout: start position and 11 rows of 24 codes
;
; Read by DrawParchmentFrame (DrawFrameRow draws a row, DrawFrameCell one
; code). The first word is the position of the frame: low byte = character row
; (5), high byte = column (4). Then 11 rows of 24 cells follow, each cell
; described by a code: code 1 is followed by a count n and means n blank cells
; (only the attribute is set, the bitmap is left as it is); any other code k
; draws frame tile k-2 from ParchmentFrameTiles. The first row is the top
; border, the next 9 rows are a left tile, a run of 22 blank cells (code 1,
; $16) and a right tile, the last row is the bottom border. A 0 where a row
; would start ends the layout.
;
; The window therefore covers 24 x 11 character cells, columns 4-27 and rows
; 5-15; the text of a parchment is printed over its blank cells.
ParchmentLayout:
  DEFW $0405
  DEFB $02,$03,$04,$03,$03,$04,$03,$03,$03,$03,$03,$03,$03,$03,$04,$03
  DEFB $03,$03,$03,$04,$03,$04,$03,$05
  DEFB $06,$01,$16,$09
  DEFB $08,$01,$16,$09
  DEFB $06,$01,$16,$07
  DEFB $08,$01,$16,$07
  DEFB $08,$01,$16,$07
  DEFB $08,$01,$16,$07
  DEFB $08,$01,$16,$09
  DEFB $06,$01,$16,$07
  DEFB $06,$01,$16,$09
  DEFB $0A,$0B,$0B,$0C,$0B,$0B,$0B,$0B,$0B,$0C,$0B,$0C,$0B,$0B,$0B,$0B
  DEFB $0B,$0C,$0B,$0B,$0C,$0B,$0B,$0D
  DEFB $00
