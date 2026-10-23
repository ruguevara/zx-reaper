; Colour-code table: grid cell index to code byte minus index
;
; 256 bytes, read by AskColourCode as CodeTable[L] for the grid cell index L;
; the expected code byte is CodeTable[L]+L (mod 256), see AskColourCode and
; ReadCodeSlot. The byte holds four colours, two bits each, key number minus 1,
; slot 1 in the top bits. Example: L=$37 (cell B3) holds $A2, $A2+$37=$D9 = 11
; 01 10 01 = keys 4-2-3-2.
;
; Used part: indexes $00-$B2 (179 cells, the grid is 18 columns A-R by 10 rows
; 0-9 = 180 cells). Index $B3 (the last cell) is never produced and index $FF
; is read in one case only (the quirk of AskColourCode, when FRAMES is $8E:
; location ">D").
;
; The table does not look designed: the 180 bytes have only 83 distinct values
; and the whole 256-byte block, including the 76 bytes after the used part
; ($9EB4-$9EFF), disassembles as plausible Z80 code of some other program that
; keeps variables at $40xx and calls routines below $2C00. It is not a piece of
; the 48K Spectrum ROM (no run of 6 or more bytes matches the ROM). So the
; table is probably a block of foreign program bytes used as a source of
; arbitrary numbers; where it came from is Unknown. Nothing reads $9EB4-$9EFE.
CodeTable:
  DEFB $2B,$4B,$0D,$78,$CA,$60,$1D,$CD,$5B,$1E,$FE,$2C,$C0,$18,$F3,$11
  DEFB $F2,$40,$1A,$B7,$CA,$A0,$19,$3C,$32,$9A,$40,$12,$7E,$FE,$87,$28
  DEFB $0C,$CD,$5A,$1E,$C0,$7A,$B3,$C2,$C5,$1E,$3C,$18,$02,$D7,$C0,$2A
  DEFB $EE,$40,$EB,$2A,$EA,$40,$22,$A2,$40,$EB,$C0,$7E,$B7,$20,$04,$23
  DEFB $23,$23,$23,$23,$7A,$A3,$3C,$C2,$05,$1F,$3A,$DD,$40,$3D,$CA,$BE
  DEFB $1D,$C3,$05,$1F,$CD,$1C,$2B,$C0,$B7,$CA,$4A,$1E,$3D,$87,$5F,$FE
  DEFB $2D,$38,$02,$1E,$26,$C3,$A2,$19,$11,$0A,$00,$D5,$28,$17,$CD,$4F
  DEFB $1E,$EB,$E3,$28,$11,$EB,$CF,$2C,$EB,$2A,$E4,$40,$EB,$28,$06,$CD
  DEFB $5A,$1E,$C2,$97,$19,$EB,$7C,$B5,$CA,$4A,$1E,$22,$E4,$40,$32,$E1
  DEFB $40,$E1,$22,$E2,$40,$C1,$C3,$33,$1A,$CD,$37,$23,$7E,$FE,$2C,$CC
  DEFB $78,$1D,$FE,$CA,$CC,$78,$1D,$2B,$E5,$CD,$94,$09,$E1,$28,$07,$D7
  DEFB $DA,$C2,$1E,$C3,$5F,$1D,$16,$01,$CD,$05,$1F,$B7,$C8,$D7,$FE,$95
  DEFB $20,$F6,$15,$20,$F3,$18,$E8,$3E,$01,$32,$9C,$40,$C3,$7C,$20,$CD
  DEFB $CA,$41,$FE,$23,$20,$06,$CD,$84,$02,$32,$9C,$40,$2B,$D7,$CC,$FE
  DEFB $20,$CA,$69,$21,$F6,$20,$FE,$60,$20,$1B,$CD,$01,$2B,$FE,$04,$D2
  DEFB $4A,$1E,$E5,$21,$00,$3C,$19,$22,$20,$40,$7B,$E6,$3F,$32,$A6,$40

; Unused area
;
; 256 zero bytes. Nothing references them (no operand or word in the image
; points here). The byte at $9EFF just before it is the one case where
; CodeTable is read beyond its used part.
L9F00:
  DEFS $0100
