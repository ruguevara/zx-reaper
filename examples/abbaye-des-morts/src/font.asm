; Font index: one word per character $20-$7F, giving the glyph offset and width
;
; Word n belongs to the character with code $20+n (the word of character c is
; at $6130+2*(c-$20)). Read by the character printer DrawGlyph and by
; MeasureString, which measures a string in the proportional font.
;
; Word layout (stored low byte first): bits 0-11: offset from the address of
; the word's high byte (its own address + 1) to the glyph in FontGlyphs; bits
; 12-15: glyph width in pixels minus 2 (GLYPH_WIDTH_BIAS), so the glyphs are
; 2-17 pixels wide. The width is also the advance to the next character.
FontIndex:
  DEFW $30BF,$10BF,$30C3,$70C5
  DEFW $40D1,$80DD,$A0F3,$0109
  DEFW $310B,$3115,$511F,$6125
  DEFW $1129,$612D,$112F,$5131
  DEFW $513D,$3141,$6147,$6152
  DEFW $715D,$5171,$517A,$6182
  DEFW $5189,$518F,$1197,$119B
  DEFW $41A1,$51A9,$41AD,$51B5
  DEFW $31BE,$C1BE,$81D6,$61E6
  DEFW $91EE,$91FE,$8214,$9226
  DEFW $B23A,$7250,$425E,$B264
  DEFW $827A,$D286,$A29A,$72B0
  DEFW $82BE,$72CC,$B2DE,$62F2
  DEFW $82FD,$A307,$8317,$B329
  DEFW $C33D,$8351,$8365,$337B
  DEFW $537F,$338B,$438F,$8393
  DEFW $2397,$839B,$63A7,$53AF
  DEFW $93B6,$63C6,$53CE,$63D4
  DEFW $83DD,$53F1,$33FB,$8405
  DEFW $4419,$E41F,$942F,$643F
  DEFW $7444,$7452,$5462,$5468
  DEFW $5470,$9478,$7486,$C496
  DEFW $94A6,$74B6,$74CA,$34DA
  DEFW $04E0,$34E2,$54E8,$34EB

; Font glyphs: 16 pixel rows each, only the rows that differ are stored
;
; The glyphs of the proportional font (a gothic hand with 16 pixel rows),
; addressed through FontIndex. A glyph is a 16-bit mask word (low byte first)
; followed by one pattern per set mask bit. Mask bit 15 is pixel row 0 and bit
; 0 is row 15; a set bit means that a new row pattern follows, a clear bit
; repeats the pattern of the row above (the first row is blank when its bit is
; clear). A mask of 0 is an empty glyph (the space).
;
; A pattern is one byte (the pixels from the left edge) when the glyph is up to
; 8 pixels wide, and two bytes when it is 9 or more (WIDE_GLYPH): the right
; byte first, then the left one. The glyphs follow each other without gaps up
; to $66DB.
FontGlyphs:
  DEFB $00,$00
  DEFB $68,$20,$C0,$00,$C0,$00
  DEFB $00,$24,$90,$00
  DEFB $A0,$2D,$00,$12,$00,$7F,$00,$24
  DEFB $00,$FE,$00,$48,$00,$00
  DEFB $FC,$3F,$20,$70,$A8,$A0,$E0,$70
  DEFB $38,$28,$A8,$70,$20,$00
  DEFB $F8,$3F,$80,$6F,$80,$91,$00,$93,$00,$96,$00,$6C,$00,$1F,$80,$34
  DEFB $80,$64,$80,$C4,$00,$83,$00,$00
  DEFB $F8,$3F,$00,$38,$00,$44,$00,$4C,$00,$38,$C0,$31,$20,$6B,$20,$C6
  DEFB $40,$86,$00,$8D,$C0,$78,$00,$00
  DEFB $00,$24,$80,$00
  DEFB $7C,$7C,$10,$20,$60,$40,$C0,$40
  DEFB $60,$20,$10,$00
  DEFB $7C,$7C,$80,$40,$60,$20,$30,$20
  DEFB $60,$40,$80,$00
  DEFB $00,$7E,$48,$30,$FC,$30,$48,$00
  DEFB $20,$13,$10,$FE,$10,$00
  DEFB $2E,$00,$C0,$40,$80,$00
  DEFB $00,$03,$FE,$00
  DEFB $28,$00,$C0,$00
  DEFB $FC,$3F,$04,$0C,$08,$18,$10,$30
  DEFB $20,$60,$40,$C0,$80,$00
  DEFB $18,$30,$78,$CC,$78,$00
  DEFB $18,$3C,$20,$60,$E0,$60,$F0,$00
  DEFB $F8,$3F,$3C,$46,$86,$06,$0C,$18
  DEFB $30,$60,$C2,$FC,$00
  DEFB $F8,$3F,$7E,$8C,$18,$30,$7C,$06
  DEFB $46,$86,$8C,$78,$00
  DEFB $D8,$3F,$00,$04,$00,$0C,$00,$1C,$00,$2C,$00,$4C,$00,$8D,$00,$FE
  DEFB $00,$0C,$00,$1E,$00,$00
  DEFB $38,$3F,$F8,$C4,$C0,$F0,$18,$0C
  DEFB $98,$70,$00
  DEFB $18,$3F,$38,$44,$C0,$D8,$EC,$CC
  DEFB $78,$00
  DEFB $48,$3D,$7E,$86,$06,$0C,$18,$30
  DEFB $00
  DEFB $18,$33,$78,$CC,$78,$CC,$78,$00
  DEFB $F8,$31,$78,$CC,$DC,$6C,$0C,$88
  DEFB $70,$00
  DEFB $28,$05,$C0,$00,$C0,$00
  DEFB $2E,$05,$C0,$00,$C0,$40,$80,$00
  DEFB $F0,$0F,$18,$30,$60,$C0,$60,$30
  DEFB $18,$00
  DEFB $C0,$03,$FC,$00,$FC,$00
  DEFB $F0,$0F,$C0,$60,$30,$18,$30,$60
  DEFB $C0,$00
  DEFB $E8,$3B,$78,$8C,$0C,$18,$30,$20
  DEFB $00,$20,$00
  DEFB $00,$00
  DEFB $F8,$7F,$C0,$01,$60,$02,$60,$00,$E0,$00,$E0,$01,$20,$03,$20,$06
  DEFB $E0,$7F,$60,$98,$60,$30,$38,$E0,$00,$00
  DEFB $18,$77,$00,$10,$00,$7E,$00,$B3,$00,$33,$00,$3E,$80,$31,$00,$FF
  DEFB $00,$00
  DEFB $78,$36,$7C,$C2,$C4,$C0,$C2,$C4
  DEFB $78,$00
  DEFB $38,$7C,$00,$10,$00,$7F,$80,$B1,$C0,$B0,$C0,$30,$80,$30,$00,$FF
  DEFB $00,$00
  DEFB $78,$7F,$00,$10,$80,$7F,$80,$B0,$00,$B0,$00,$30,$00,$3E,$00,$30
  DEFB $40,$30,$80,$30,$00,$FF,$00,$00
  DEFB $18,$7F,$00,$10,$80,$7F,$80,$B0,$00,$B0,$00,$30,$00,$3E,$00,$30
  DEFB $00,$E0,$00,$00
  DEFB $78,$3F,$00,$3F,$00,$61,$00,$C2,$00,$C0,$00,$CF,$00,$C3,$40,$C7
  DEFB $80,$CB,$00,$73,$00,$00
  DEFB $F8,$77,$E0,$00,$80,$71,$80,$B1,$80,$31,$80,$7F,$80,$B1,$80,$31
  DEFB $90,$31,$A0,$31,$C0,$E1,$00,$00
  DEFB $78,$34,$00,$78,$00,$98,$00,$18
  DEFB $00,$19,$00,$1A,$00,$1C,$00,$00
  DEFB $07,$34,$78,$98,$18,$10,$20,$C0
  DEFB $F8,$3F,$C0,$70,$80,$B1,$00,$B3,$00,$36,$00,$3C,$00,$38,$00,$3C
  DEFB $10,$36,$20,$33,$C0,$E1,$00,$00
  DEFB $78,$30,$00,$38,$00,$60,$80,$60
  DEFB $00,$61,$00,$FE,$00,$00
  DEFB $78,$3F,$70,$70,$E0,$B8,$60,$BD,$60,$2E,$60,$24,$60,$20,$64,$20
  DEFB $68,$20,$70,$C0,$00,$00
  DEFB $F8,$3F,$60,$70,$40,$B8,$40,$BC,$40,$2E,$40,$27,$C0,$23,$C0,$21
  DEFB $C0,$20,$40,$20,$40,$C0,$00,$00
  DEFB $78,$38,$00,$3C,$00,$46,$00,$C3
  DEFB $00,$C2,$00,$44,$00,$38,$00,$00
  DEFB $98,$35,$00,$7F,$80,$B1,$80,$31
  DEFB $00,$3F,$00,$30,$00,$E0,$00,$00
  DEFB $7E,$38,$00,$3C,$00,$46,$00,$C3,$00,$D3,$00,$4A,$00,$3C,$00,$04
  DEFB $00,$02,$00,$00
  DEFB $F8,$75,$00,$10,$00,$7F,$80,$B1,$80,$31,$00,$3F,$00,$36,$00,$33
  DEFB $90,$31,$E0,$E0,$00,$00
  DEFB $F8,$3F,$7C,$C2,$E4,$70,$38,$1C
  DEFB $4E,$86,$C6,$7C,$00
  DEFB $18,$34,$80,$7F,$00,$8C,$00,$0C
  DEFB $00,$38,$00,$00
  DEFB $F8,$38,$80,$61,$80,$E1,$80,$61,$80,$63,$A0,$65,$C0,$69,$80,$31
  DEFB $00,$00
  DEFB $F8,$39,$00,$61,$80,$E3,$80,$61,$00,$63,$00,$66,$00,$6C,$00,$78
  DEFB $00,$70,$00,$00
  DEFB $F8,$3B,$20,$60,$70,$E0,$30,$60,$30,$62,$30,$66,$60,$6E,$C0,$76
  DEFB $80,$67,$00,$47,$00,$00
  DEFB $F8,$3E,$30,$60,$60,$B0,$C0,$98,$80,$0D,$00,$07,$80,$0D,$C8,$18
  DEFB $68,$30,$30,$60,$00,$00
  DEFB $7F,$38,$80,$61,$80,$E1,$80,$61,$80,$63,$80,$65,$80,$39,$80,$01
  DEFB $00,$01,$00,$02,$00,$1C
  DEFB $F8,$3F,$00,$7F,$00,$83,$00,$86,$00,$0C,$00,$18,$00,$30,$00,$60
  DEFB $80,$C0,$00,$C1,$00,$FE,$00,$00
  DEFB $0C,$60,$F0,$C0,$F0,$00
  DEFB $FC,$3F,$80,$C0,$40,$60,$20,$30
  DEFB $10,$18,$08,$0C,$04,$00
  DEFB $0C,$60,$F0,$30,$F0,$00
  DEFB $00,$1E,$20,$50,$88,$00
  DEFB $18,$00,$80,$FF,$00,$00
  DEFB $00,$78,$80,$40,$20,$00
  DEFB $78,$06,$00,$7E,$00,$C6,$80,$CE
  DEFB $00,$D7,$00,$66,$00,$00
  DEFB $38,$67,$70,$C0,$DC,$E6,$C6,$CC
  DEFB $F8,$00
  DEFB $78,$07,$7C,$C4,$C0,$C4,$C8,$70
  DEFB $00
  DEFB $78,$66,$00,$03,$00,$06,$00,$7E,$00,$C6,$40,$CE,$80,$D6,$00,$67
  DEFB $00,$00
  DEFB $F8,$07,$7C,$C4,$C8,$D0,$E2,$C4
  DEFB $78,$00
  DEFB $03,$66,$1C,$30,$78,$30,$20,$C0
  DEFB $7F,$06,$7E,$C6,$CE,$D6,$66,$06
  DEFB $04,$08,$30
  DEFB $F8,$67,$00,$70,$00,$C0,$00,$CE,$00,$D6,$00,$E6,$00,$C6,$80,$C6
  DEFB $00,$C7,$00,$C6,$00,$00
  DEFB $78,$3F,$20,$40,$00,$60,$E0,$60
  DEFB $64,$68,$70,$00
  DEFB $87,$3F,$10,$20,$00,$30,$70,$B0
  DEFB $30,$20,$40,$80
  DEFB $F8,$67,$00,$70,$00,$C0,$00,$D8,$00,$E4,$00,$C4,$00,$F8,$80,$D8
  DEFB $00,$CD,$00,$C6,$00,$00
  DEFB $78,$60,$70,$C0,$C8,$D0,$E0,$00
  DEFB $F8,$07,$38,$67,$58,$EB,$98,$73,$18,$63,$1A,$63,$1C,$63,$18,$63
  DEFB $00,$00
  DEFB $F8,$07,$00,$67,$00,$EB,$00,$73,$00,$63,$40,$63,$80,$63,$00,$63
  DEFB $00,$00
  DEFB $38,$06,$7C,$C6,$CC,$78,$00
  DEFB $39,$07,$00,$6E,$00,$F3,$00,$63
  DEFB $00,$66,$00,$7C,$00,$60,$00,$C0
  DEFB $7B,$06,$00,$7E,$00,$C6,$00,$CE,$00,$D6,$00,$66,$00,$06,$00,$07
  DEFB $00,$06
  DEFB $38,$07,$6C,$F0,$60,$70,$60,$00
  DEFB $F8,$07,$78,$C4,$C0,$78,$0C,$8C
  DEFB $78,$00
  DEFB $78,$1E,$20,$60,$F8,$60,$64,$68
  DEFB $70,$00
  DEFB $78,$07,$00,$63,$00,$E3,$00,$63
  DEFB $40,$67,$80,$6B,$00,$33,$00,$00
  DEFB $F8,$07,$00,$42,$00,$E7,$00,$63,$00,$62,$00,$64,$00,$68,$00,$70
  DEFB $00,$00
  DEFB $F8,$07,$10,$42,$38,$E7,$18,$63,$10,$67,$20,$6B,$40,$73,$80,$63
  DEFB $00,$00
  DEFB $F8,$07,$00,$61,$00,$B2,$00,$1C,$00,$0C,$00,$16,$40,$23,$80,$41
  DEFB $00,$00
  DEFB $7F,$07,$00,$63,$00,$E3,$00,$63,$00,$67,$00,$6B,$00,$33,$00,$03
  DEFB $00,$02,$00,$04,$00,$38
  DEFB $F8,$07,$00,$7E,$00,$86,$00,$0C,$00,$18,$00,$30,$00,$61,$00,$FE
  DEFB $00,$00
  DEFB $86,$31,$30,$60,$C0,$60,$30,$00
  DEFB $02,$20,$80,$00
  DEFB $86,$31,$C0,$60,$30,$60,$C0,$00
  DEFB $00,$E0,$64,$98,$00
  DEFB $00,$00
