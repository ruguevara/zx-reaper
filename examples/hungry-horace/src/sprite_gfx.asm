; Horace sprites, walking frame A (4 directions)
;
; Horace, the blue creature, 16x16 pixels, one sprite per direction in the
; order of the direction codes 0 up, 1 right, 2 down, 3 left (HoraceDir,
; HoraceDir): the sprite for direction d is at HoraceSprites + SPRITE_BYTES *
; d. Each sprite is 32 bytes: four 8x8 cells in the order top-left, top-right,
; bottom-left, bottom-right, each cell being 8 bytes of pixel rows from the top
; (bit 7 leftmost); DrawSprite (DrawSprite) draws it with an attribute colour
; of the caller's choice.
;
; This is the first of two walking frames. DrawHorace (DrawHorace) uses it when
; bit 4 of the animation counter HoraceAnim is set and the second frame
; HoraceSprites2 when it is clear, so the legs change every 16 draws. It draws
; Horace with attribute $39 (blue ink on white).
HoraceSprites:
  DEFB $0F,$1F,$7F,$7F,$FF,$9F,$E7,$78 ; up (no face): top-left cell
  DEFB $E0,$F8,$FE,$FE,$FF,$F1,$8F,$7E ; top-right
  DEFB $7F,$3B,$18,$18,$38,$3C,$44,$7C ; bottom-left
  DEFB $D8,$D8,$1C,$24,$7C,$00,$00,$00 ; bottom-right
  DEFB $0F,$3F,$7F,$FC,$F8,$B8,$98,$9D ; right: top-left cell
  DEFB $F8,$FC,$FE,$73,$73,$63,$E6,$EE ; top-right
  DEFB $0F,$23,$3F,$33,$1E,$02,$00,$00 ; bottom-left
  DEFB $FC,$BC,$9E,$8E,$0C,$1C,$12,$3F ; bottom-right
  DEFB $07,$1F,$7F,$61,$C0,$E0,$F3,$7F ; down (facing the player): top-left
                                       ; cell
  DEFB $F0,$F8,$FE,$C6,$C3,$C3,$E3,$FE ; top-right
  DEFB $1B,$1B,$38,$24,$3E,$00,$00,$00 ; bottom-left
  DEFB $FE,$DC,$18,$18,$1C,$34,$22,$3E ; bottom-right
  DEFB $1F,$3F,$7F,$CC,$CE,$46,$77,$3F ; left: top-left cell
  DEFB $E0,$F8,$FE,$3E,$1F,$1F,$1F,$B9 ; top-right
  DEFB $1F,$0E,$0C,$1D,$15,$3C,$01,$03 ; bottom-left
  DEFB $F9,$F0,$E0,$C0,$C0,$E0,$30,$E0 ; bottom-right

; Horace sprites, walking frame B (4 directions)
;
; The second walking frame of Horace, 4 sprites of 32 bytes in the order up,
; right, down, left, in the same layout as HoraceSprites. DrawHorace
; (DrawHorace) uses it when bit 4 of the animation counter HoraceAnim is clear.
; It differs from frame A in the legs.
HoraceSprites2:
  DEFB $07,$1F,$7F,$7F,$FF,$8F,$F1,$7E ; up (no face): top-left cell
  DEFB $F0,$F8,$FE,$FE,$FF,$F9,$E7,$1E ; top-right
  DEFB $1B,$1B,$38,$24,$3E,$00,$00,$00 ; bottom-left
  DEFB $FE,$DC,$18,$18,$1C,$3C,$22,$3E ; bottom-right
  DEFB $07,$1F,$7F,$7C,$F8,$F8,$F8,$9D ; right: top-left cell
  DEFB $F8,$FC,$FE,$33,$73,$62,$EE,$FC ; top-right
  DEFB $9F,$0F,$07,$03,$03,$07,$0C,$07 ; bottom-left
  DEFB $F8,$70,$30,$B8,$A8,$3C,$80,$C0 ; bottom-right
  DEFB $0F,$1F,$7F,$63,$C3,$C3,$C7,$7F ; down (facing the player): top-left
                                       ; cell
  DEFB $E0,$F8,$FE,$86,$03,$07,$CF,$FE ; top-right
  DEFB $7F,$3B,$18,$18,$38,$2C,$44,$7C ; bottom-left
  DEFB $D8,$D8,$1C,$24,$7C,$00,$00,$00 ; bottom-right
  DEFB $1F,$3F,$7F,$CE,$CE,$C6,$67,$77 ; left: top-left cell
  DEFB $F0,$FC,$FE,$3F,$1F,$1D,$19,$B9 ; top-right
  DEFB $3F,$3D,$79,$71,$30,$38,$48,$FC ; bottom-left
  DEFB $F0,$C4,$FC,$CC,$78,$40,$00,$00 ; bottom-right

; Guard sprites, frame A (4 directions)
;
; The guard's head, 16x16 pixels, one sprite per direction in the order 0 up
; (no face), 1 right, 2 down (face), 3 left: the sprite for direction d is at
; GuardSprites + SPRITE_BYTES * d. Each sprite is 32 bytes: four 8x8 cells in
; the order top-left, top-right, bottom-left, bottom-right, each cell being 8
; bytes of pixel rows from the top (bit 7 leftmost); DrawSprite (DrawSprite)
; draws it with an attribute colour of the caller's choice.
;
; Used by DrawGuard (DrawGuard) when bit 5 of the guard's animation counter is
; set, otherwise GuardSprites2, so the face changes (eyes and mouth) every 32
; draws. Not used while the bell timer BellTimer runs: ScaredGuardSprites is
; used then. Drawn with attribute $3B (magenta ink on white).
GuardSprites:
  DEFB $1F,$3F,$3F,$3F,$4F,$71,$7E,$7F ; up (no face): top-left cell
  DEFB $F8,$FC,$FC,$FC,$FA,$C6,$3E,$FE ; top-right
  DEFB $5F,$5F,$3F,$3F,$1F,$0F,$07,$03 ; bottom-left
  DEFB $FA,$FA,$FC,$FC,$F8,$F0,$E0,$C0 ; bottom-right
  DEFB $1F,$3F,$3F,$3F,$3F,$3C,$7C,$4C ; right: top-left cell
  DEFB $E0,$F0,$F0,$F8,$FF,$44,$44,$EE ; top-right
  DEFB $5C,$5E,$6F,$3F,$3F,$1F,$1F,$07 ; bottom-left
  DEFB $EE,$22,$FC,$F8,$B8,$80,$F8,$C0 ; bottom-right
  DEFB $1F,$3F,$3F,$3F,$7F,$63,$41,$66 ; down (facing the player): top-left
                                       ; cell
  DEFB $F8,$FC,$FC,$FC,$FE,$8E,$86,$9A ; top-right
  DEFB $76,$79,$3F,$3F,$1F,$0C,$07,$03 ; bottom-left
  DEFB $DA,$E6,$FC,$FC,$F8,$30,$E0,$C0 ; bottom-right
  DEFB $07,$0F,$0F,$1F,$FF,$22,$22,$5D ; left: top-left cell
  DEFB $F8,$FC,$FC,$FC,$FC,$3C,$3E,$F2 ; top-right
  DEFB $5D,$44,$3F,$1F,$1F,$11,$1F,$03 ; bottom-left
  DEFB $FA,$7A,$F6,$FC,$FC,$F8,$F8,$E0 ; bottom-right

; Guard sprites, frame B (4 directions)
;
; The second animation frame of the guard's head: 4 sprites of 32 bytes in the
; order up, right, down, left, in the same layout as GuardSprites. Used by
; DrawGuard (DrawGuard) when bit 5 of the guard's animation counter is clear.
GuardSprites2:
  DEFB $1F,$3F,$3F,$3F,$5F,$63,$7C,$7F ; up (no face): top-left cell
  DEFB $F8,$FC,$FC,$FC,$F2,$8E,$7E,$FE ; top-right
  DEFB $5F,$5F,$3F,$3F,$1F,$0F,$07,$03 ; bottom-left
  DEFB $FA,$FA,$FC,$FC,$F8,$F0,$E0,$C0 ; bottom-right
  DEFB $1F,$3F,$3F,$3F,$3F,$3C,$7C,$4F ; right: top-left cell
  DEFB $E0,$F0,$F0,$F8,$FF,$44,$44,$BA ; top-right
  DEFB $5F,$5E,$6F,$3F,$3F,$1F,$1F,$07 ; bottom-left
  DEFB $BA,$22,$FC,$F8,$F8,$88,$F8,$C0 ; bottom-right
  DEFB $1F,$3F,$3F,$3F,$7F,$71,$61,$59 ; down (facing the player): top-left
                                       ; cell
  DEFB $F8,$FC,$FC,$FC,$FE,$C6,$82,$66 ; top-right
  DEFB $5B,$67,$3F,$3F,$18,$0C,$06,$03 ; bottom-left
  DEFB $6E,$9E,$FC,$FC,$18,$30,$60,$C0 ; bottom-right
  DEFB $07,$0F,$0F,$1F,$FF,$22,$22,$77 ; left: top-left cell
  DEFB $F8,$FC,$FC,$FC,$FC,$3C,$3E,$32 ; top-right
  DEFB $77,$44,$3F,$1F,$1D,$01,$1F,$03 ; bottom-left
  DEFB $3A,$7A,$F6,$FC,$FC,$F8,$F8,$E0 ; bottom-right

; Scared guard sprites (2 frames)
;
; The guard's head while it can be eaten (the bell timer BellTimer is running):
; a frightened face with hair standing up, 2 frames of 32 bytes in the same
; cell order as GuardSprites (top-left, top-right, bottom-left, bottom-right).
; The two frames alternate according to bit 3 of the guard's animation counter,
; and there is one pair for all directions. Used by DrawGuard (DrawGuard).
ScaredGuardSprites:
  DEFB $88,$C8,$4C,$66,$37,$A4,$A0,$E6 ; frame 0: top-left cell
  DEFB $40,$60,$60,$C6,$CC,$3C,$09,$C7 ; top-right
  DEFB $46,$60,$21,$23,$16,$0C,$06,$03 ; bottom-left
  DEFB $C2,$06,$84,$CC,$68,$30,$60,$C0 ; bottom-right
  DEFB $C4,$44,$66,$26,$37,$B8,$A0,$E3 ; frame 1: top-left cell
  DEFB $10,$30,$60,$E7,$CE,$3C,$08,$67 ; top-right
  DEFB $43,$60,$21,$23,$16,$0C,$06,$03 ; bottom-left
  DEFB $62,$06,$84,$CC,$68,$30,$60,$C0 ; bottom-right

; Bell sprites (4 animation frames)
;
; The bonus bell, 16x16 pixels, 4 frames of 32 bytes in the same cell order as
; GuardSprites. The bell swings: frame 0 and frame 3 are the two extreme
; positions and frames 1 and 2 lie between them. UpdateBell (UpdateBell) draws
; them in the attribute ATTR_BELL (red), stepping every 8 passes through frames
; 0, 1, 2, 3, 3, 2, 1, 0 from the animation counter BellTick.
BellSprites:
  DEFB $00,$00,$00,$02,$01,$01,$01,$01 ; frame 0: top-left cell
  DEFB $00,$00,$00,$00,$E0,$F9,$FE,$FC ; top-right
  DEFB $00,$00,$00,$01,$01,$00,$00,$00 ; bottom-left
  DEFB $F0,$E0,$E0,$A0,$00,$00,$00,$00 ; bottom-right
  DEFB $00,$00,$00,$01,$01,$01,$03,$03 ; frame 1: top-left cell
  DEFB $00,$00,$00,$00,$00,$C0,$E0,$E0 ; top-right
  DEFB $03,$07,$07,$1D,$01,$00,$00,$00 ; bottom-left
  DEFB $F0,$FC,$E0,$00,$00,$00,$00,$00 ; bottom-right
  DEFB $00,$00,$00,$00,$00,$03,$07,$07 ; frame 2: top-left cell
  DEFB $00,$00,$00,$80,$80,$80,$C0,$C0 ; top-right
  DEFB $0F,$3F,$07,$00,$00,$00,$00,$00 ; bottom-left
  DEFB $C0,$E0,$E0,$B8,$80,$00,$00,$00 ; bottom-right
  DEFB $00,$00,$00,$00,$07,$9F,$7F,$3F ; frame 3: top-left cell
  DEFB $00,$00,$00,$40,$80,$80,$80,$80 ; top-right
  DEFB $0F,$07,$07,$05,$00,$00,$00,$00 ; bottom-left
  DEFB $00,$00,$00,$80,$80,$00,$00,$00 ; bottom-right

; Blank sprite (32 zero bytes)
;
; An empty 16x16 sprite (four cells of 8 zero bytes). It is drawn with
; DrawSprite over a sprite to erase it: by EraseSprites (EraseSprites), by
; UpdateBell when Horace takes the bell and by HoraceDies.
BlankSprite:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

; Unused zero bytes at the end of the code block
;
; 89 bytes of zeroes ($7FA7-$7FFF) filling the last part of the code block.
; Nothing in the game reads or writes them.
L7FA7:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00
