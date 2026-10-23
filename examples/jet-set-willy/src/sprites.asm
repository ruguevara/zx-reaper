; Sprites: toilet (4 frames) and unused filler
;
; Eight 16x16 sprites of 32 bytes, 16 pixel rows of 2 bytes each (left byte,
; right byte; bit 7 = leftmost pixel). Sprite F of the page is at $A600+32*F.
; Entity definitions (EntityDefs) name the page in byte +5 and pick F from the
; animation phase, the direction and the slot data. The sprites are drawn with
; DrawSprite (DrawEntities) and have no colour of their own: ink and bright
; come from the entity definition. Frames 0-1 are the toilet drawn in The
; Bathroom (room $21) by DrawToilet, alternating with bit 0 of the frame
; counter PassCounter; frames 2-3 (the same two, plus $40) are used instead
; once game state EndingStage is 3 (set by CheckToiletReached when Willy
; reaches position $BC in the Bathroom; Willy himself is then no longer drawn
; by PlaceWilly). Frames 4-7 hold bytes that are mostly $80 and are not drawn
; by any code seen (leftover filler; no entity definition uses page $A6). The
; look of frames 2-3 is the toilet with something added (a pipe and a swirl).
SpritesToilet:
  DEFB $00,$0F            ; frame 0: toilet, idle frame 0 (lid line slanted)
  DEFB $00,$3F
  DEFB $00,$0F
  DEFB $30,$0F
  DEFB $0C,$0F
  DEFB $03,$0F
  DEFB $00,$CF
  DEFB $00,$2F
  DEFB $00,$08
  DEFB $3F,$F8
  DEFB $3F,$F0
  DEFB $3F,$EE
  DEFB $1F,$DF
  DEFB $1F,$DB
  DEFB $0F,$FB
  DEFB $0F,$FB
  DEFB $00,$0F            ; frame 1: toilet, idle frame 1 (lid line flat)
  DEFB $00,$3F
  DEFB $00,$0F
  DEFB $00,$0F
  DEFB $00,$0F
  DEFB $00,$0F
  DEFB $00,$0F
  DEFB $3F,$EF
  DEFB $00,$08
  DEFB $3F,$F8
  DEFB $3F,$F0
  DEFB $3F,$EE
  DEFB $1F,$DF
  DEFB $1F,$DB
  DEFB $0F,$FB
  DEFB $0F,$FB
  DEFB $03,$AF            ; frame 2: toilet, state 3 frame 0
  DEFB $01,$BF
  DEFB $01,$8F
  DEFB $01,$8F
  DEFB $7F,$8F
  DEFB $7F,$8F
  DEFB $47,$CF
  DEFB $0F,$CF
  DEFB $00,$08
  DEFB $3F,$F8
  DEFB $3F,$F0
  DEFB $3F,$EE
  DEFB $1F,$DF
  DEFB $1F,$DB
  DEFB $0F,$FB
  DEFB $0F,$FB
  DEFB $00,$0F            ; frame 3: toilet, state 3 frame 1
  DEFB $04,$3F
  DEFB $1E,$2F
  DEFB $3B,$2F
  DEFB $5D,$8F
  DEFB $0E,$8F
  DEFB $07,$CF
  DEFB $0F,$CF
  DEFB $00,$08
  DEFB $3F,$F8
  DEFB $3F,$F0
  DEFB $3F,$EE
  DEFB $1F,$DF
  DEFB $1F,$DB
  DEFB $0F,$FB
  DEFB $0F,$FB
  DEFB $80,$80            ; frame 4: filler bytes, never drawn
  DEFB $80,$80
  DEFB $8C,$8F
  DEFB $8F,$8F
  DEFB $8F,$8F
  DEFB $80,$80
  DEFB $BF,$8F
  DEFB $8F,$8F
  DEFB $85,$80
  DEFB $80,$80
  DEFB $80,$80
  DEFB $80,$80
  DEFB $80,$80
  DEFB $80,$80
  DEFB $80,$80
  DEFB $80,$80
  DEFB $80,$80            ; frame 5: filler bytes, never drawn
  DEFB $80,$80
  DEFB $80,$80
  DEFB $80,$80
  DEFB $80,$80
  DEFB $80,$80
  DEFB $80,$80
  DEFB $80,$80
  DEFB $80,$80
  DEFB $80,$80
  DEFB $80,$80
  DEFB $80,$80
  DEFB $80,$80
  DEFB $80,$80
  DEFB $80,$80
  DEFB $80,$80
  DEFB $80,$80            ; frame 6: filler bytes, never drawn
  DEFB $BF,$BF
  DEFB $BF,$BF
  DEFB $BF,$BF
  DEFB $BF,$BF
  DEFB $BF,$8F
  DEFB $B3,$B0
  DEFB $B0,$80
  DEFB $85,$80
  DEFB $80,$80
  DEFB $80,$80
  DEFB $80,$80
  DEFB $80,$80
  DEFB $80,$80
  DEFB $80,$80
  DEFB $80,$80
  DEFB $80,$80            ; frame 7: filler bytes, never drawn
  DEFB $80,$80
  DEFB $80,$80
  DEFB $80,$80
  DEFB $80,$80
  DEFB $80,$80
  DEFB $80,$80
  DEFB $80,$80
  DEFB $80,$80
  DEFB $80,$80
  DEFB $80,$80
  DEFB $80,$80
  DEFB $80,$80
  DEFB $80,$80
  DEFB $80,$80
  DEFB $80,$80

; Sprites: unused page, all zero
;
; Eight 16x16 sprites of 32 bytes, 16 pixel rows of 2 bytes each (left byte,
; right byte; bit 7 = leftmost pixel). Sprite F of the page is at $A700+32*F.
; Entity definitions (EntityDefs) name the page in byte +5 and pick F from the
; animation phase, the direction and the slot data. The sprites are drawn with
; DrawSprite (DrawEntities) and have no colour of their own: ink and bright
; come from the entity definition. This page holds only zero bytes and no
; entity definition uses it.
UnusedSpritesA7:
  DEFB $00,$00            ; frame 0: blank
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00            ; frame 1: blank
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00            ; frame 2: blank
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00            ; frame 3: blank
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00            ; frame 4: blank
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00            ; frame 5: blank
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00            ; frame 6: blank
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00            ; frame 7: blank
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00

; Sprites: unused page, all zero
;
; Eight 16x16 sprites of 32 bytes, 16 pixel rows of 2 bytes each (left byte,
; right byte; bit 7 = leftmost pixel). Sprite F of the page is at $A800+32*F.
; Entity definitions (EntityDefs) name the page in byte +5 and pick F from the
; animation phase, the direction and the slot data. The sprites are drawn with
; DrawSprite (DrawEntities) and have no colour of their own: ink and bright
; come from the entity definition. This page holds only zero bytes and no
; entity definition uses it.
UnusedSpritesA8:
  DEFB $00,$00            ; frame 0: blank
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00            ; frame 1: blank
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00            ; frame 2: blank
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00            ; frame 3: blank
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00            ; frame 4: blank
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00            ; frame 5: blank
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00            ; frame 6: blank
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00            ; frame 7: blank
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00

; Sprites: unused page, all zero
;
; Eight 16x16 sprites of 32 bytes, 16 pixel rows of 2 bytes each (left byte,
; right byte; bit 7 = leftmost pixel). Sprite F of the page is at $A900+32*F.
; Entity definitions (EntityDefs) name the page in byte +5 and pick F from the
; animation phase, the direction and the slot data. The sprites are drawn with
; DrawSprite (DrawEntities) and have no colour of their own: ink and bright
; come from the entity definition. This page holds only zero bytes and no
; entity definition uses it.
UnusedSpritesA9:
  DEFB $00,$00            ; frame 0: blank
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00            ; frame 1: blank
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00            ; frame 2: blank
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00            ; frame 3: blank
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00            ; frame 4: blank
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00            ; frame 5: blank
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00            ; frame 6: blank
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00            ; frame 7: blank
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00

; Sprites: unused page, all zero
;
; Eight 16x16 sprites of 32 bytes, 16 pixel rows of 2 bytes each (left byte,
; right byte; bit 7 = leftmost pixel). Sprite F of the page is at $AA00+32*F.
; Entity definitions (EntityDefs) name the page in byte +5 and pick F from the
; animation phase, the direction and the slot data. The sprites are drawn with
; DrawSprite (DrawEntities) and have no colour of their own: ink and bright
; come from the entity definition. This page holds only zero bytes and no
; entity definition uses it.
UnusedSpritesAA:
  DEFB $00,$00            ; frame 0: blank
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00            ; frame 1: blank
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00            ; frame 2: blank
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00            ; frame 3: blank
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00            ; frame 4: blank
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00            ; frame 5: blank
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00            ; frame 6: blank
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00            ; frame 7: blank
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00

; Sprites: spinning slab (4 frames), crawler (4 frames)
;
; Eight 16x16 sprites of 32 bytes, 16 pixel rows of 2 bytes each (left byte,
; right byte; bit 7 = leftmost pixel). Sprite F of the page is at $AB00+32*F.
; Entity definitions (EntityDefs) name the page in byte +5 and pick F from the
; animation phase, the direction and the slot data. The sprites are drawn with
; DrawSprite (DrawEntities) and have no colour of their own: ink and bright
; come from the entity definition. Frames 0-3 look like a flat box with a label
; window turning (front, oblique, edge-on, oblique); frames 4-7 look like a bug
; with antennae and legs scuttling. Used by entity definitions $65 $66 in rooms
; $1B $1E $24.
SpritesSlabCrawler:
  DEFB $00,$00            ; frame 0: slab, front view (box with window, dotted
                          ; base)
  DEFB $00,$00
  DEFB $2A,$AA
  DEFB $7F,$FF
  DEFB $7F,$FF
  DEFB $7C,$3F
  DEFB $7C,$3F
  DEFB $7F,$FF
  DEFB $7F,$FF
  DEFB $7F,$FF
  DEFB $00,$00
  DEFB $2A,$AA
  DEFB $00,$00
  DEFB $2A,$AA
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$48            ; frame 1: slab, oblique
  DEFB $01,$2C
  DEFB $04,$BC
  DEFB $12,$FE
  DEFB $4B,$FE
  DEFB $2E,$7F
  DEFB $BC,$3F
  DEFB $FE,$7C
  DEFB $FF,$F2
  DEFB $7F,$C9
  DEFB $7F,$25
  DEFB $3C,$94
  DEFB $32,$50
  DEFB $09,$40
  DEFB $05,$00
  DEFB $04,$00
  DEFB $00,$00            ; frame 2: slab, edge-on
  DEFB $07,$E0
  DEFB $0F,$F0
  DEFB $17,$E8
  DEFB $0F,$F0
  DEFB $16,$68
  DEFB $0E,$70
  DEFB $16,$68
  DEFB $0F,$F0
  DEFB $17,$E8
  DEFB $0F,$F0
  DEFB $17,$E8
  DEFB $08,$10
  DEFB $17,$E8
  DEFB $10,$08
  DEFB $00,$00
  DEFB $12,$00            ; frame 3: slab, oblique (other side)
  DEFB $34,$80
  DEFB $3D,$20
  DEFB $7F,$48
  DEFB $7F,$D2
  DEFB $FE,$74
  DEFB $FC,$3D
  DEFB $3E,$7F
  DEFB $4F,$FF
  DEFB $93,$FE
  DEFB $A4,$FE
  DEFB $29,$3C
  DEFB $0A,$4C
  DEFB $02,$90
  DEFB $00,$A0
  DEFB $00,$20
  DEFB $00,$00            ; frame 4: crawler, frame 0
  DEFB $00,$00
  DEFB $00,$00
  DEFB $02,$02
  DEFB $22,$02
  DEFB $A9,$54
  DEFB $A8,$D8
  DEFB $71,$74
  DEFB $22,$DA
  DEFB $3B,$AE
  DEFB $2E,$AB
  DEFB $24,$F9
  DEFB $20,$DB
  DEFB $20,$D8
  DEFB $01,$54
  DEFB $02,$8A
  DEFB $00,$00            ; frame 5: crawler, frame 1
  DEFB $02,$02
  DEFB $02,$02
  DEFB $01,$74
  DEFB $00,$D8
  DEFB $51,$54
  DEFB $52,$FA
  DEFB $23,$DE
  DEFB $E7,$AB
  DEFB $1E,$F9
  DEFB $18,$D9
  DEFB $08,$D9
  DEFB $09,$54
  DEFB $06,$8A
  DEFB $04,$00
  DEFB $00,$00
  DEFB $02,$02            ; frame 6: crawler, frame 2
  DEFB $03,$8E
  DEFB $00,$F8
  DEFB $01,$54
  DEFB $02,$DA
  DEFB $03,$FE
  DEFB $11,$8B
  DEFB $4B,$A9
  DEFB $2B,$FB
  DEFB $96,$F8
  DEFB $6C,$D8
  DEFB $05,$54
  DEFB $02,$8A
  DEFB $01,$00
  DEFB $00,$80
  DEFB $00,$40
  DEFB $00,$00            ; frame 7: crawler, frame 3
  DEFB $02,$02
  DEFB $02,$02
  DEFB $01,$74
  DEFB $00,$D8
  DEFB $51,$54
  DEFB $52,$FA
  DEFB $23,$DE
  DEFB $E7,$AB
  DEFB $1E,$F9
  DEFB $18,$D9
  DEFB $08,$D9
  DEFB $09,$54
  DEFB $06,$8A
  DEFB $04,$00
  DEFB $00,$00

; Sprites: barbed bars (4 frames), spiral disc (4 frames)
;
; Eight 16x16 sprites of 32 bytes, 16 pixel rows of 2 bytes each (left byte,
; right byte; bit 7 = leftmost pixel). Sprite F of the page is at $AC00+32*F.
; Entity definitions (EntityDefs) name the page in byte +5 and pick F from the
; animation phase, the direction and the slot data. The sprites are drawn with
; DrawSprite (DrawEntities) and have no colour of their own: ink and bright
; come from the entity definition. Frames 0-3 look like a double horizontal bar
; with spikes (barbed wire) changing shape; frames 4-7 look like a round disc
; with a spiral, turning. Used by entity definitions $60 $61 $64 in rooms $1A
; $1B $1E $25 $36.
SpritesBarbedSpiral:
  DEFB $20,$04            ; frame 0: barbed bars, frame 0
  DEFB $AE,$EC
  DEFB $BB,$7D
  DEFB $E0,$07
  DEFB $BD,$B5
  DEFB $A0,$04
  DEFB $3B,$7C
  DEFB $00,$00
  DEFB $1D,$B0
  DEFB $20,$04
  DEFB $3B,$7C
  DEFB $A2,$44
  DEFB $FD,$B7
  DEFB $A0,$04
  DEFB $3B,$DC
  DEFB $20,$04
  DEFB $20,$04            ; frame 1: barbed bars, frame 1
  DEFB $37,$B4
  DEFB $A0,$04
  DEFB $FB,$7F
  DEFB $A0,$04
  DEFB $3D,$B4
  DEFB $20,$04
  DEFB $1B,$78
  DEFB $00,$00
  DEFB $3D,$B4
  DEFB $A2,$44
  DEFB $BB,$7D
  DEFB $E0,$07
  DEFB $BD,$B5
  DEFB $B7,$EC
  DEFB $20,$04
  DEFB $20,$04            ; frame 2: barbed bars, frame 2
  DEFB $3A,$DC
  DEFB $3D,$BD
  DEFB $E0,$07
  DEFB $3B,$75
  DEFB $20,$04
  DEFB $3D,$BC
  DEFB $00,$00
  DEFB $1B,$70
  DEFB $20,$04
  DEFB $3D,$BD
  DEFB $A2,$45
  DEFB $FB,$77
  DEFB $A0,$05
  DEFB $3D,$ED
  DEFB $20,$04
  DEFB $20,$04            ; frame 3: barbed bars, frame 3
  DEFB $3B,$75
  DEFB $A0,$05
  DEFB $FD,$BF
  DEFB $A0,$05
  DEFB $3B,$75
  DEFB $20,$04
  DEFB $1D,$B8
  DEFB $00,$00
  DEFB $3B,$74
  DEFB $24,$84
  DEFB $3D,$BD
  DEFB $E0,$07
  DEFB $3B,$75
  DEFB $2E,$EC
  DEFB $20,$04
  DEFB $0F,$F0            ; frame 4: spiral disc, frame 0
  DEFB $17,$E8
  DEFB $18,$18
  DEFB $37,$CC
  DEFB $28,$24
  DEFB $53,$92
  DEFB $64,$4A
  DEFB $A9,$2B
  DEFB $AA,$2B
  DEFB $6A,$4A
  DEFB $69,$92
  DEFB $24,$24
  DEFB $33,$CC
  DEFB $18,$18
  DEFB $17,$E8
  DEFB $0F,$F0
  DEFB $00,$E0            ; frame 5: spiral disc, frame 1
  DEFB $07,$F0
  DEFB $38,$18
  DEFB $73,$CC
  DEFB $64,$26
  DEFB $49,$93
  DEFB $52,$4B
  DEFB $D4,$2B
  DEFB $D5,$2A
  DEFB $D4,$CA
  DEFB $D2,$12
  DEFB $49,$E4
  DEFB $24,$0C
  DEFB $13,$F4
  DEFB $08,$78
  DEFB $07,$80
  DEFB $01,$80            ; frame 6: spiral disc, frame 2
  DEFB $07,$E0
  DEFB $18,$18
  DEFB $73,$CE
  DEFB $A4,$25
  DEFB $C9,$95
  DEFB $D2,$55
  DEFB $D4,$55
  DEFB $D4,$95
  DEFB $D2,$25
  DEFB $C9,$C9
  DEFB $E4,$13
  DEFB $73,$E6
  DEFB $18,$18
  DEFB $07,$E0
  DEFB $01,$80
  DEFB $07,$00            ; frame 7: spiral disc, frame 3
  DEFB $08,$E0
  DEFB $1F,$DC
  DEFB $30,$26
  DEFB $67,$92
  DEFB $C8,$4A
  DEFB $D3,$2A
  DEFB $D4,$AB
  DEFB $54,$2B
  DEFB $52,$4B
  DEFB $49,$93
  DEFB $24,$26
  DEFB $33,$CC
  DEFB $28,$18
  DEFB $1F,$F0
  DEFB $01,$E0

; Sprites: pincers (4 frames), razor blade (4 frames)
;
; Eight 16x16 sprites of 32 bytes, 16 pixel rows of 2 bytes each (left byte,
; right byte; bit 7 = leftmost pixel). Sprite F of the page is at $AD00+32*F.
; Entity definitions (EntityDefs) name the page in byte +5 and pick F from the
; animation phase, the direction and the slot data. The sprites are drawn with
; DrawSprite (DrawEntities) and have no colour of their own: ink and bright
; come from the entity definition. Frames 0-3 look like pincers or pliers (legs
; apart, crossing); frames 4-7 look like a razor blade turning (flat, diagonal,
; upright, diagonal). Used by entity definitions $1E $3A $3D $63 in rooms $09
; $22 $2B $2E $33 $37.
SpritesPincersRazor:
  DEFB $0C,$00            ; frame 0: pincers, legs apart
  DEFB $0C,$00
  DEFB $0C,$00
  DEFB $0C,$00
  DEFB $0C,$00
  DEFB $1E,$00
  DEFB $12,$00
  DEFB $33,$00
  DEFB $3F,$00
  DEFB $73,$80
  DEFB $61,$80
  DEFB $61,$80
  DEFB $C0,$C0
  DEFB $C0,$C0
  DEFB $80,$40
  DEFB $80,$40
  DEFB $08,$40            ; frame 1: pincers, crossing
  DEFB $08,$40
  DEFB $0C,$C0
  DEFB $04,$80
  DEFB $07,$80
  DEFB $07,$80
  DEFB $0C,$C0
  DEFB $1C,$E0
  DEFB $3B,$70
  DEFB $30,$30
  DEFB $60,$18
  DEFB $60,$18
  DEFB $40,$08
  DEFB $C0,$0C
  DEFB $80,$04
  DEFB $80,$04
  DEFB $02,$10            ; frame 2: pincers, crossing wide
  DEFB $02,$10
  DEFB $03,$30
  DEFB $01,$20
  DEFB $01,$E0
  DEFB $01,$E0
  DEFB $03,$30
  DEFB $07,$38
  DEFB $0E,$DC
  DEFB $0C,$0C
  DEFB $18,$06
  DEFB $18,$06
  DEFB $10,$02
  DEFB $30,$03
  DEFB $20,$01
  DEFB $20,$01
  DEFB $00,$30            ; frame 3: pincers, legs apart (narrow)
  DEFB $00,$30
  DEFB $00,$30
  DEFB $00,$30
  DEFB $00,$30
  DEFB $00,$78
  DEFB $00,$48
  DEFB $00,$CC
  DEFB $00,$FC
  DEFB $01,$CE
  DEFB $01,$86
  DEFB $01,$86
  DEFB $03,$03
  DEFB $03,$03
  DEFB $02,$01
  DEFB $02,$01
  DEFB $00,$00            ; frame 4: razor blade, flat
  DEFB $00,$00
  DEFB $00,$00
  DEFB $7F,$FE
  DEFB $40,$02
  DEFB $FF,$FF
  DEFB $DE,$7B
  DEFB $C0,$03
  DEFB $C0,$03
  DEFB $DE,$7B
  DEFB $FF,$FF
  DEFB $40,$02
  DEFB $7F,$FE
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $0A,$00            ; frame 5: razor blade, diagonal
  DEFB $1D,$00
  DEFB $36,$80
  DEFB $67,$40
  DEFB $C3,$A0
  DEFB $71,$D0
  DEFB $B8,$68
  DEFB $5C,$34
  DEFB $2C,$3A
  DEFB $16,$1D
  DEFB $0B,$8E
  DEFB $05,$C3
  DEFB $02,$E6
  DEFB $01,$6C
  DEFB $00,$B8
  DEFB $00,$50
  DEFB $07,$E0            ; frame 6: razor blade, upright
  DEFB $1F,$F8
  DEFB $14,$28
  DEFB $16,$68
  DEFB $16,$68
  DEFB $16,$68
  DEFB $16,$68
  DEFB $14,$28
  DEFB $14,$28
  DEFB $16,$68
  DEFB $16,$68
  DEFB $16,$68
  DEFB $16,$68
  DEFB $14,$28
  DEFB $1F,$F8
  DEFB $07,$E0
  DEFB $00,$50            ; frame 7: razor blade, diagonal (other way)
  DEFB $00,$B8
  DEFB $01,$6C
  DEFB $02,$E6
  DEFB $05,$C3
  DEFB $0B,$8E
  DEFB $16,$1D
  DEFB $2C,$3A
  DEFB $5C,$34
  DEFB $B8,$68
  DEFB $71,$D0
  DEFB $C3,$A0
  DEFB $67,$40
  DEFB $36,$80
  DEFB $1D,$00
  DEFB $0A,$00

; Sprites: two-legged walker (4 frames), arms-up figure on a drum (4 frames)
;
; Eight 16x16 sprites of 32 bytes, 16 pixel rows of 2 bytes each (left byte,
; right byte; bit 7 = leftmost pixel). Sprite F of the page is at $AE00+32*F.
; Entity definitions (EntityDefs) name the page in byte +5 and pick F from the
; animation phase, the direction and the slot data. The sprites are drawn with
; DrawSprite (DrawEntities) and have no colour of their own: ink and bright
; come from the entity definition. Frames 0-3 look like a flat-headed creature
; with two long legs stepping; frames 4-7 look like a figure with raised arms
; above a drum-like base, the arms waving. Used by entity definitions $26 $44
; $5A $6A $6E in rooms $16 $20 $2B $2D $3C.
SpritesWalkerDrum:
  DEFB $7E,$00            ; frame 0: walker, frame 0
  DEFB $99,$00
  DEFB $FF,$00
  DEFB $81,$00
  DEFB $7E,$00
  DEFB $18,$00
  DEFB $24,$00
  DEFB $24,$00
  DEFB $42,$00
  DEFB $42,$00
  DEFB $81,$00
  DEFB $E7,$00
  DEFB $A5,$00
  DEFB $C3,$00
  DEFB $A5,$00
  DEFB $E7,$00
  DEFB $00,$00            ; frame 1: walker, frame 1
  DEFB $1F,$80
  DEFB $26,$40
  DEFB $39,$C0
  DEFB $30,$C0
  DEFB $1F,$80
  DEFB $09,$00
  DEFB $10,$80
  DEFB $20,$40
  DEFB $40,$20
  DEFB $80,$10
  DEFB $E0,$70
  DEFB $A0,$50
  DEFB $C0,$30
  DEFB $A0,$50
  DEFB $E0,$70
  DEFB $00,$00            ; frame 2: walker, frame 2
  DEFB $00,$00
  DEFB $00,$00
  DEFB $07,$E0
  DEFB $09,$90
  DEFB $0E,$70
  DEFB $0E,$70
  DEFB $06,$60
  DEFB $1B,$D8
  DEFB $60,$06
  DEFB $80,$01
  DEFB $E0,$07
  DEFB $A0,$05
  DEFB $C0,$03
  DEFB $A0,$05
  DEFB $E0,$07
  DEFB $00,$00            ; frame 3: walker, frame 3
  DEFB $01,$F8
  DEFB $02,$64
  DEFB $03,$9C
  DEFB $03,$0C
  DEFB $01,$F8
  DEFB $00,$90
  DEFB $01,$08
  DEFB $02,$04
  DEFB $04,$02
  DEFB $08,$01
  DEFB $0E,$07
  DEFB $0A,$05
  DEFB $0C,$03
  DEFB $0A,$05
  DEFB $0E,$07
  DEFB $0C,$00            ; frame 4: figure on drum, frame 0
  DEFB $12,$00
  DEFB $21,$10
  DEFB $12,$20
  DEFB $8C,$40
  DEFB $52,$80
  DEFB $2F,$00
  DEFB $2F,$00
  DEFB $5F,$80
  DEFB $5F,$80
  DEFB $5F,$80
  DEFB $00,$00
  DEFB $FF,$C0
  DEFB $5D,$80
  DEFB $5D,$80
  DEFB $FF,$C0
  DEFB $00,$01            ; frame 5: figure on drum, frame 1
  DEFB $00,$02
  DEFB $83,$04
  DEFB $4C,$C8
  DEFB $23,$10
  DEFB $14,$A0
  DEFB $0B,$C0
  DEFB $0B,$C0
  DEFB $17,$E0
  DEFB $17,$E0
  DEFB $17,$E0
  DEFB $00,$00
  DEFB $3F,$F0
  DEFB $1B,$B0
  DEFB $1B,$B0
  DEFB $3F,$F0
  DEFB $80,$00            ; frame 6: figure on drum, frame 2
  DEFB $40,$00
  DEFB $20,$01
  DEFB $11,$E2
  DEFB $08,$C4
  DEFB $05,$28
  DEFB $02,$F0
  DEFB $02,$F0
  DEFB $05,$F8
  DEFB $05,$F8
  DEFB $05,$F8
  DEFB $00,$00
  DEFB $0F,$FC
  DEFB $0B,$74
  DEFB $0B,$74
  DEFB $0F,$FC
  DEFB $00,$00            ; frame 7: figure on drum, frame 3
  DEFB $00,$00
  DEFB $08,$30
  DEFB $04,$CC
  DEFB $02,$31
  DEFB $01,$4A
  DEFB $00,$BC
  DEFB $00,$BC
  DEFB $01,$7E
  DEFB $01,$7E
  DEFB $01,$7E
  DEFB $00,$00
  DEFB $03,$FF
  DEFB $02,$ED
  DEFB $02,$ED
  DEFB $03,$FF

; Sprites: penknife (4 frames), teardrop with spot (4 frames)
;
; Eight 16x16 sprites of 32 bytes, 16 pixel rows of 2 bytes each (left byte,
; right byte; bit 7 = leftmost pixel). Sprite F of the page is at $AF00+32*F.
; Entity definitions (EntityDefs) name the page in byte +5 and pick F from the
; animation phase, the direction and the slot data. The sprites are drawn with
; DrawSprite (DrawEntities) and have no colour of their own: ink and bright
; come from the entity definition. Frames 0-3 look like a penknife with a blade
; swinging open; frames 4-7 look like a teardrop or leaf shape with a dotted
; spot, turning. Used by entity definitions $24 $27 $5E $62 in rooms $04 $07
; $16 $22 $2A $33 $34.
SpritesKnifeTeardrop:
  DEFB $38,$00            ; frame 0: penknife, frame 0
  DEFB $7C,$00
  DEFB $7E,$00
  DEFB $6D,$80
  DEFB $44,$40
  DEFB $6C,$40
  DEFB $7C,$20
  DEFB $7C,$00
  DEFB $7C,$0C
  DEFB $7C,$32
  DEFB $FC,$CC
  DEFB $FF,$30
  DEFB $FC,$C0
  DEFB $7F,$00
  DEFB $6C,$00
  DEFB $38,$00
  DEFB $0E,$60            ; frame 1: penknife, frame 1
  DEFB $1F,$94
  DEFB $1F,$08
  DEFB $1B,$20
  DEFB $11,$50
  DEFB $1B,$50
  DEFB $1F,$A0
  DEFB $1F,$A0
  DEFB $7F,$40
  DEFB $DF,$40
  DEFB $DF,$80
  DEFB $9F,$80
  DEFB $7F,$00
  DEFB $1F,$00
  DEFB $1B,$00
  DEFB $0E,$00
  DEFB $03,$80            ; frame 2: penknife, frame 2
  DEFB $07,$C0
  DEFB $07,$E0
  DEFB $06,$D8
  DEFB $04,$44
  DEFB $0E,$C4
  DEFB $7F,$C2
  DEFB $EF,$C0
  DEFB $EF,$C0
  DEFB $8F,$C0
  DEFB $77,$C0
  DEFB $07,$C0
  DEFB $07,$C0
  DEFB $07,$C0
  DEFB $06,$C0
  DEFB $03,$80
  DEFB $00,$E0            ; frame 3: penknife, frame 3
  DEFB $01,$F0
  DEFB $01,$F0
  DEFB $01,$B2
  DEFB $01,$15
  DEFB $01,$B5
  DEFB $01,$FA
  DEFB $01,$FA
  DEFB $07,$F4
  DEFB $0D,$F4
  DEFB $0D,$F8
  DEFB $09,$F8
  DEFB $07,$F0
  DEFB $01,$F0
  DEFB $01,$B0
  DEFB $00,$E0
  DEFB $0C,$00            ; frame 4: teardrop, frame 0
  DEFB $16,$00
  DEFB $2F,$00
  DEFB $2F,$00
  DEFB $4F,$80
  DEFB $5F,$80
  DEFB $5F,$80
  DEFB $9F,$C0
  DEFB $BF,$C0
  DEFB $BD,$C0
  DEFB $BA,$C0
  DEFB $BD,$40
  DEFB $5A,$80
  DEFB $5D,$80
  DEFB $3F,$00
  DEFB $0C,$00
  DEFB $00,$00            ; frame 5: teardrop, frame 1
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$70
  DEFB $03,$98
  DEFB $0C,$78
  DEFB $33,$F8
  DEFB $47,$F0
  DEFB $5F,$F0
  DEFB $BF,$F0
  DEFB $BE,$A0
  DEFB $BD,$60
  DEFB $5A,$C0
  DEFB $5D,$40
  DEFB $3F,$80
  DEFB $0E,$00
  DEFB $00,$00            ; frame 6: teardrop, frame 2
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $03,$C0
  DEFB $1C,$78
  DEFB $21,$FC
  DEFB $4F,$FE
  DEFB $5F,$FE
  DEFB $9F,$FF
  DEFB $BF,$EF
  DEFB $5F,$56
  DEFB $5F,$AE
  DEFB $23,$54
  DEFB $1F,$F8
  DEFB $03,$C0
  DEFB $00,$00            ; frame 7: teardrop, frame 3
  DEFB $00,$00
  DEFB $00,$00
  DEFB $0E,$00
  DEFB $17,$C0
  DEFB $17,$F0
  DEFB $13,$FC
  DEFB $0B,$FE
  DEFB $0B,$FE
  DEFB $0B,$D7
  DEFB $05,$EB
  DEFB $05,$D7
  DEFB $02,$EA
  DEFB $02,$7E
  DEFB $01,$8C
  DEFB $00,$70

; Sprites: ring on a stalk, chomping head, dressed figure, barred ornament
;
; Eight 16x16 sprites of 32 bytes, 16 pixel rows of 2 bytes each (left byte,
; right byte; bit 7 = leftmost pixel). Sprite F of the page is at $B000+32*F.
; Entity definitions (EntityDefs) name the page in byte +5 and pick F from the
; animation phase, the direction and the slot data. The sprites are drawn with
; DrawSprite (DrawEntities) and have no colour of their own: ink and bright
; come from the entity definition. Four unrelated pairs. Frames 0-1: a ring on
; a stalk (entities $52-$56 in The Attic, room $29). Frames 2-3: a round head
; with a wedge-shaped mouth (entity $57, The Attic). Frames 4-5: a small figure
; with hair and a dress (entity $0F, in the room named "Rescue Esmerelda", room
; $0E). Frames 6-7: an ornament with a vertical bar and arcs (entity $59, rooms
; $0B and $36).
SpritesRingChomper:
  DEFB $07,$C0            ; frame 0: ring on a stalk, frame 0
  DEFB $18,$30
  DEFB $23,$88
  DEFB $44,$44
  DEFB $88,$22
  DEFB $90,$13
  DEFB $90,$13
  DEFB $88,$22
  DEFB $44,$44
  DEFB $23,$88
  DEFB $18,$30
  DEFB $07,$C0
  DEFB $03,$00
  DEFB $03,$00
  DEFB $03,$00
  DEFB $03,$80
  DEFB $07,$C0            ; frame 1: ring on a stalk, frame 1
  DEFB $18,$30
  DEFB $20,$08
  DEFB $43,$84
  DEFB $84,$42
  DEFB $88,$23
  DEFB $88,$23
  DEFB $84,$42
  DEFB $43,$84
  DEFB $20,$08
  DEFB $18,$30
  DEFB $07,$C0
  DEFB $0F,$80
  DEFB $1D,$D0
  DEFB $08,$E0
  DEFB $04,$40
  DEFB $07,$C0            ; frame 2: chomping head, frame 0
  DEFB $1F,$F0
  DEFB $3E,$78
  DEFB $7C,$3C
  DEFB $7E,$7C
  DEFB $FF,$FE
  DEFB $FF,$FE
  DEFB $F0,$00
  DEFB $FF,$80
  DEFB $7F,$F0
  DEFB $7F,$FC
  DEFB $3F,$F8
  DEFB $1F,$F0
  DEFB $07,$C0
  DEFB $00,$00
  DEFB $00,$00
  DEFB $07,$C0            ; frame 3: chomping head, frame 1
  DEFB $1F,$F0
  DEFB $3C,$F8
  DEFB $78,$7C
  DEFB $7C,$FC
  DEFB $FF,$80
  DEFB $FC,$00
  DEFB $F0,$00
  DEFB $F8,$00
  DEFB $7E,$00
  DEFB $7F,$80
  DEFB $3F,$E0
  DEFB $1F,$F0
  DEFB $07,$C0
  DEFB $00,$00
  DEFB $00,$00
  DEFB $07,$C0            ; frame 4: dressed figure, frame 0
  DEFB $08,$20
  DEFB $0A,$A0
  DEFB $08,$20
  DEFB $0B,$A0
  DEFB $10,$10
  DEFB $25,$48
  DEFB $0A,$A0
  DEFB $3D,$78
  DEFB $46,$C4
  DEFB $07,$C0
  DEFB $02,$80
  DEFB $05,$40
  DEFB $0F,$E0
  DEFB $14,$80
  DEFB $08,$C0
  DEFB $07,$C0            ; frame 5: dressed figure, frame 1
  DEFB $08,$20
  DEFB $0A,$A0
  DEFB $08,$20
  DEFB $39,$38
  DEFB $00,$00
  DEFB $05,$40
  DEFB $0A,$A0
  DEFB $1D,$70
  DEFB $16,$D0
  DEFB $17,$D0
  DEFB $0A,$A0
  DEFB $05,$40
  DEFB $0F,$E0
  DEFB $02,$50
  DEFB $06,$20
  DEFB $01,$80            ; frame 6: barred ornament, frame 0
  DEFB $00,$00
  DEFB $01,$80
  DEFB $45,$91
  DEFB $01,$80
  DEFB $89,$A2
  DEFB $45,$91
  DEFB $01,$80
  DEFB $CD,$B3
  DEFB $CD,$B3
  DEFB $CD,$B3
  DEFB $CD,$B3
  DEFB $23,$C4
  DEFB $12,$48
  DEFB $0D,$B0
  DEFB $00,$00
  DEFB $01,$80            ; frame 7: barred ornament, frame 1
  DEFB $00,$00
  DEFB $01,$80
  DEFB $89,$A2
  DEFB $01,$80
  DEFB $45,$91
  DEFB $89,$A2
  DEFB $01,$80
  DEFB $CD,$B3
  DEFB $CD,$B3
  DEFB $CD,$B3
  DEFB $CD,$B3
  DEFB $23,$C4
  DEFB $12,$48
  DEFB $0D,$B0
  DEFB $00,$00

; Sprites: poles (unused)
;
; Eight 16x16 sprites of 32 bytes, 16 pixel rows of 2 bytes each (left byte,
; right byte; bit 7 = leftmost pixel). Sprite F of the page is at $B100+32*F.
; Entity definitions (EntityDefs) name the page in byte +5 and pick F from the
; animation phase, the direction and the slot data. The sprites are drawn with
; DrawSprite (DrawEntities) and have no colour of their own: ink and bright
; come from the entity definition. No entity definition has page $B1 as its
; sprite page and no code loads $B1 into a register (checked with the
; definitions and a search of the code), so this page is not displayed with the
; inputs and rooms examined. Frames 0-3 look like a vertical pole above a base
; of dots; frames 4-7 look like a tall pole with different tops (hook, round
; head, flag, diamond).
SpritesPolesUnused:
  DEFB $16,$00            ; frame 0: pole above dotted base, frame 0
  DEFB $16,$00
  DEFB $16,$00
  DEFB $16,$00
  DEFB $16,$00
  DEFB $16,$00
  DEFB $16,$00
  DEFB $16,$00
  DEFB $FF,$C0
  DEFB $00,$00
  DEFB $52,$80
  DEFB $C0,$C0
  DEFB $33,$00
  DEFB $B3,$40
  DEFB $08,$00
  DEFB $2D,$00
  DEFB $05,$80            ; frame 1: pole above dotted base, frame 1
  DEFB $05,$80
  DEFB $05,$80
  DEFB $05,$80
  DEFB $05,$80
  DEFB $05,$80
  DEFB $05,$80
  DEFB $05,$80
  DEFB $3F,$F0
  DEFB $00,$00
  DEFB $0D,$20
  DEFB $24,$00
  DEFB $0C,$D0
  DEFB $0C,$F0
  DEFB $28,$00
  DEFB $0D,$20
  DEFB $01,$60            ; frame 2: pole above dotted base, frame 2
  DEFB $01,$60
  DEFB $01,$60
  DEFB $01,$60
  DEFB $01,$60
  DEFB $01,$60
  DEFB $01,$60
  DEFB $01,$60
  DEFB $0F,$FC
  DEFB $00,$00
  DEFB $02,$D0
  DEFB $00,$40
  DEFB $0B,$34
  DEFB $03,$30
  DEFB $0C,$0C
  DEFB $05,$28
  DEFB $00,$58            ; frame 3: pole above dotted base, frame 3
  DEFB $00,$58
  DEFB $00,$58
  DEFB $00,$58
  DEFB $00,$58
  DEFB $00,$58
  DEFB $00,$58
  DEFB $00,$58
  DEFB $03,$FF
  DEFB $00,$00
  DEFB $01,$2C
  DEFB $00,$05
  DEFB $03,$CC
  DEFB $02,$CC
  DEFB $00,$09
  DEFB $01,$2C
  DEFB $00,$40            ; frame 4: pole with hooked top
  DEFB $01,$80
  DEFB $02,$40
  DEFB $05,$C0
  DEFB $0B,$C0
  DEFB $0B,$C0
  DEFB $17,$C0
  DEFB $17,$C0
  DEFB $16,$40
  DEFB $16,$00
  DEFB $16,$00
  DEFB $16,$00
  DEFB $16,$00
  DEFB $16,$00
  DEFB $16,$00
  DEFB $16,$00
  DEFB $03,$00            ; frame 5: pole with round head
  DEFB $0F,$C0
  DEFB $08,$40
  DEFB $13,$20
  DEFB $13,$20
  DEFB $08,$40
  DEFB $0F,$C0
  DEFB $07,$80
  DEFB $05,$80
  DEFB $05,$80
  DEFB $05,$80
  DEFB $05,$80
  DEFB $05,$80
  DEFB $05,$80
  DEFB $05,$80
  DEFB $05,$80
  DEFB $08,$00            ; frame 6: pole with flag top
  DEFB $0E,$00
  DEFB $0B,$00
  DEFB $0B,$80
  DEFB $0B,$C0
  DEFB $0B,$C0
  DEFB $0B,$E0
  DEFB $0F,$E0
  DEFB $09,$60
  DEFB $01,$60
  DEFB $01,$60
  DEFB $01,$60
  DEFB $01,$60
  DEFB $01,$60
  DEFB $01,$60
  DEFB $01,$60
  DEFB $00,$30            ; frame 7: pole with diamond top
  DEFB $00,$DC
  DEFB $00,$BC
  DEFB $01,$7E
  DEFB $01,$7E
  DEFB $00,$BC
  DEFB $00,$BC
  DEFB $00,$58
  DEFB $00,$58
  DEFB $00,$58
  DEFB $00,$58
  DEFB $00,$58
  DEFB $00,$58
  DEFB $00,$58
  DEFB $00,$58
  DEFB $00,$58

; Sprites: banner (4 frames), round face (4 frames)
;
; Eight 16x16 sprites of 32 bytes, 16 pixel rows of 2 bytes each (left byte,
; right byte; bit 7 = leftmost pixel). Sprite F of the page is at $B200+32*F.
; Entity definitions (EntityDefs) name the page in byte +5 and pick F from the
; animation phase, the direction and the slot data. The sprites are drawn with
; DrawSprite (DrawEntities) and have no colour of their own: ink and bright
; come from the entity definition. Frames 0-3 look like a waving banner; frames
; 4-7 look like a round grinning face. Used by entity definitions $1B $1D in
; rooms $09 $25 $28 $2C $2D $30 $34 $3B (the banner in the room named "The
; Yacht", $3B; the face elsewhere).
SpritesBannerFace:
  DEFB $00,$03            ; frame 0: banner, frame 0
  DEFB $00,$0F
  DEFB $00,$1F
  DEFB $80,$3F
  DEFB $C0,$7F
  DEFB $D1,$FF
  DEFB $5F,$FF
  DEFB $9F,$FF
  DEFB $CF,$FF
  DEFB $D3,$FF
  DEFB $DF,$FC
  DEFB $FF,$F0
  DEFB $FF,$E0
  DEFB $7F,$C0
  DEFB $3F,$80
  DEFB $0E,$00
  DEFB $00,$00            ; frame 1: banner, frame 1
  DEFB $00,$00
  DEFB $50,$01
  DEFB $D8,$03
  DEFB $9C,$07
  DEFB $4F,$1F
  DEFB $D7,$FF
  DEFB $DB,$FF
  DEFB $FF,$FF
  DEFB $FF,$FF
  DEFB $FF,$FF
  DEFB $FF,$FF
  DEFB $8F,$FE
  DEFB $07,$FC
  DEFB $03,$F8
  DEFB $00,$E0
  DEFB $00,$00            ; frame 2: banner, frame 2
  DEFB $03,$80
  DEFB $07,$C0
  DEFB $8F,$C0
  DEFB $DF,$E0
  DEFB $DB,$F1
  DEFB $57,$FF
  DEFB $8F,$FF
  DEFB $DF,$FF
  DEFB $DF,$FF
  DEFB $FF,$FF
  DEFB $FC,$7F
  DEFB $F8,$3F
  DEFB $70,$3F
  DEFB $00,$1F
  DEFB $00,$0E
  DEFB $00,$38            ; frame 3: banner, frame 3
  DEFB $00,$FE
  DEFB $01,$FF
  DEFB $83,$FF
  DEFB $C7,$FF
  DEFB $DF,$FF
  DEFB $5F,$FF
  DEFB $9B,$FF
  DEFB $C7,$FF
  DEFB $DF,$FF
  DEFB $DF,$C7
  DEFB $FF,$01
  DEFB $FE,$00
  DEFB $7C,$00
  DEFB $38,$00
  DEFB $00,$00
  DEFB $03,$C0            ; frame 4: round face, frame 0
  DEFB $0E,$F0
  DEFB $1D,$F8
  DEFB $3E,$FC
  DEFB $53,$CE
  DEFB $65,$A6
  DEFB $A4,$27
  DEFB $71,$8F
  DEFB $BF,$F7
  DEFB $55,$EF
  DEFB $6E,$76
  DEFB $53,$CA
  DEFB $38,$1C
  DEFB $16,$78
  DEFB $0B,$F0
  DEFB $02,$C0
  DEFB $03,$C0            ; frame 5: round face, frame 1
  DEFB $0D,$F0
  DEFB $1A,$F8
  DEFB $3F,$FC
  DEFB $51,$8C
  DEFB $64,$26
  DEFB $C5,$A7
  DEFB $B3,$CF
  DEFB $5D,$BB
  DEFB $AA,$77
  DEFB $5F,$FA
  DEFB $72,$4E
  DEFB $38,$1C
  DEFB $1C,$38
  DEFB $0B,$F0
  DEFB $02,$C0
  DEFB $03,$C0            ; frame 6: round face, frame 2
  DEFB $0B,$F0
  DEFB $15,$78
  DEFB $3F,$FC
  DEFB $50,$0C
  DEFB $65,$A6
  DEFB $C7,$E7
  DEFB $F1,$8F
  DEFB $BE,$7F
  DEFB $DD,$F7
  DEFB $2C,$3A
  DEFB $5A,$5E
  DEFB $2C,$3C
  DEFB $16,$78
  DEFB $0B,$F0
  DEFB $03,$C0
  DEFB $03,$C0            ; frame 7: round face, frame 3
  DEFB $0D,$F0
  DEFB $1A,$F8
  DEFB $3F,$FC
  DEFB $51,$8C
  DEFB $64,$26
  DEFB $C5,$A7
  DEFB $B3,$CF
  DEFB $5D,$BB
  DEFB $AA,$77
  DEFB $5F,$FA
  DEFB $72,$4E
  DEFB $38,$1C
  DEFB $1C,$38
  DEFB $0B,$F0
  DEFB $02,$C0

; Sprites: unused page, all zero
;
; Eight 16x16 sprites of 32 bytes, 16 pixel rows of 2 bytes each (left byte,
; right byte; bit 7 = leftmost pixel). Sprite F of the page is at $B300+32*F.
; Entity definitions (EntityDefs) name the page in byte +5 and pick F from the
; animation phase, the direction and the slot data. The sprites are drawn with
; DrawSprite (DrawEntities) and have no colour of their own: ink and bright
; come from the entity definition. This page holds only zero bytes and no
; entity definition uses it.
UnusedSpritesB3:
  DEFB $00,$00            ; frame 0: blank
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00            ; frame 1: blank
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00            ; frame 2: blank
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00            ; frame 3: blank
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00            ; frame 4: blank
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00            ; frame 5: blank
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00            ; frame 6: blank
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00            ; frame 7: blank
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00

; Sprites: hatted walker, left and right (8 frames)
;
; Eight 16x16 sprites of 32 bytes, 16 pixel rows of 2 bytes each (left byte,
; right byte; bit 7 = leftmost pixel). Sprite F of the page is at $B400+32*F.
; Entity definitions (EntityDefs) name the page in byte +5 and pick F from the
; animation phase, the direction and the slot data. The sprites are drawn with
; DrawSprite (DrawEntities) and have no colour of their own: ink and bright
; come from the entity definition. A figure in a hat and robe with an
; outstretched arm, walking. Frames 0-3 are used while moving left, 4-7 while
; moving right (bit 7 of entity byte +0). Used by entity definitions $40 $41
; $42 $43 $4A $4B $4C $4D $4E $4F $50 $51 $67 in rooms $13 $1B $1C $1F $31
; (eight of them in The Forgotten Abbey, room $13).
SpritesHatWalkers:
  DEFB $0E,$00            ; frame 0: walker facing left, frame 0
  DEFB $15,$00
  DEFB $2A,$80
  DEFB $17,$00
  DEFB $FF,$00
  DEFB $16,$00
  DEFB $0C,$00
  DEFB $1F,$80
  DEFB $3F,$80
  DEFB $7F,$00
  DEFB $2A,$00
  DEFB $7F,$00
  DEFB $6F,$00
  DEFB $7F,$00
  DEFB $18,$00
  DEFB $38,$00
  DEFB $03,$80            ; frame 1: walker facing left, frame 1
  DEFB $05,$40
  DEFB $0A,$A0
  DEFB $05,$C0
  DEFB $7F,$C0
  DEFB $05,$80
  DEFB $03,$00
  DEFB $07,$E0
  DEFB $0F,$E0
  DEFB $1F,$C0
  DEFB $0A,$80
  DEFB $1F,$C0
  DEFB $1B,$C0
  DEFB $1F,$C0
  DEFB $18,$80
  DEFB $38,$00
  DEFB $00,$E0            ; frame 2: walker facing left, frame 2
  DEFB $01,$50
  DEFB $02,$A8
  DEFB $01,$70
  DEFB $0F,$F0
  DEFB $01,$60
  DEFB $00,$C0
  DEFB $01,$F8
  DEFB $03,$F8
  DEFB $07,$F0
  DEFB $02,$A0
  DEFB $07,$F0
  DEFB $06,$F0
  DEFB $07,$F0
  DEFB $06,$30
  DEFB $00,$60
  DEFB $00,$38            ; frame 3: walker facing left, frame 3
  DEFB $00,$54
  DEFB $00,$AA
  DEFB $00,$5C
  DEFB $01,$FC
  DEFB $00,$58
  DEFB $00,$30
  DEFB $00,$7E
  DEFB $00,$FE
  DEFB $01,$FC
  DEFB $00,$A8
  DEFB $01,$FC
  DEFB $01,$BC
  DEFB $01,$FC
  DEFB $01,$18
  DEFB $00,$38
  DEFB $1C,$00            ; frame 4: walker facing right, frame 0
  DEFB $2A,$00
  DEFB $55,$00
  DEFB $3A,$00
  DEFB $3F,$80
  DEFB $1A,$00
  DEFB $0C,$00
  DEFB $7E,$00
  DEFB $7F,$00
  DEFB $3F,$80
  DEFB $15,$00
  DEFB $3F,$80
  DEFB $3D,$80
  DEFB $3F,$80
  DEFB $18,$80
  DEFB $1C,$00
  DEFB $07,$00            ; frame 5: walker facing right, frame 1
  DEFB $0A,$80
  DEFB $15,$40
  DEFB $0E,$80
  DEFB $0F,$F0
  DEFB $06,$80
  DEFB $03,$00
  DEFB $1F,$80
  DEFB $1F,$C0
  DEFB $0F,$E0
  DEFB $05,$40
  DEFB $0F,$E0
  DEFB $0F,$60
  DEFB $0F,$E0
  DEFB $0C,$60
  DEFB $06,$00
  DEFB $01,$C0            ; frame 6: walker facing right, frame 2
  DEFB $02,$A0
  DEFB $05,$50
  DEFB $03,$A0
  DEFB $03,$FE
  DEFB $01,$A0
  DEFB $00,$C0
  DEFB $07,$E0
  DEFB $07,$F0
  DEFB $03,$F8
  DEFB $01,$50
  DEFB $03,$F8
  DEFB $03,$D8
  DEFB $03,$F8
  DEFB $01,$18
  DEFB $00,$1C
  DEFB $00,$70            ; frame 7: walker facing right, frame 3
  DEFB $00,$A8
  DEFB $01,$54
  DEFB $00,$E8
  DEFB $00,$FF
  DEFB $00,$68
  DEFB $00,$30
  DEFB $01,$F8
  DEFB $01,$FC
  DEFB $00,$FE
  DEFB $00,$54
  DEFB $00,$FE
  DEFB $00,$F6
  DEFB $00,$FE
  DEFB $00,$18
  DEFB $00,$1C

; Sprites: spiky post, left and right (8 frames)
;
; Eight 16x16 sprites of 32 bytes, 16 pixel rows of 2 bytes each (left byte,
; right byte; bit 7 = leftmost pixel). Sprite F of the page is at $B500+32*F.
; Entity definitions (EntityDefs) name the page in byte +5 and pick F from the
; animation phase, the direction and the slot data. The sprites are drawn with
; DrawSprite (DrawEntities) and have no colour of their own: ink and bright
; come from the entity definition. Narrow upright serrated shapes with a few
; loose pixels; most of the picture is in the left byte column and frames 0 and
; 4 are only a small blob. Frames 0-3 are used while moving left, 4-7 while
; moving right (bit 7 of entity byte +0). Used by entity definitions $34 $35
; $58 $6F in rooms $03 $07 $0D $1E $31 $33 $38 $3B.
SpritesSpikyPosts:
  DEFB $00,$00            ; frame 0: spiky post (left), frame 0, small blob
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $06,$00
  DEFB $3F,$00
  DEFB $1F,$00
  DEFB $0D,$00
  DEFB $00,$00            ; frame 1: spiky post (left), frame 1
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $01,$80
  DEFB $0F,$C0
  DEFB $07,$40
  DEFB $03,$40
  DEFB $4F,$40
  DEFB $07,$40
  DEFB $03,$20
  DEFB $0F,$20
  DEFB $87,$20
  DEFB $00,$60            ; frame 2: spiky post (left), frame 2, tall
  DEFB $03,$F0
  DEFB $01,$D0
  DEFB $00,$D0
  DEFB $03,$D0
  DEFB $01,$D0
  DEFB $00,$C8
  DEFB $03,$C8
  DEFB $01,$C8
  DEFB $00,$C8
  DEFB $0B,$C8
  DEFB $21,$C8
  DEFB $00,$C8
  DEFB $0B,$C4
  DEFB $01,$C4
  DEFB $20,$C4
  DEFB $00,$00            ; frame 3: spiky post (left), frame 3
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$18
  DEFB $00,$FC
  DEFB $00,$74
  DEFB $00,$34
  DEFB $00,$F4
  DEFB $00,$74
  DEFB $01,$36
  DEFB $00,$FA
  DEFB $02,$7A
  DEFB $00,$3A
  DEFB $04,$FA
  DEFB $00,$00            ; frame 4: spiky post (right), frame 0, small blob
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $30,$00
  DEFB $7E,$00
  DEFB $7C,$00
  DEFB $58,$00
  DEFB $00,$00            ; frame 5: spiky post (right), frame 1
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $0C,$00
  DEFB $1F,$80
  DEFB $17,$00
  DEFB $16,$00
  DEFB $17,$80
  DEFB $17,$00
  DEFB $26,$10
  DEFB $27,$80
  DEFB $27,$08
  DEFB $03,$00            ; frame 6: spiky post (right), frame 2, tall
  DEFB $07,$E0
  DEFB $05,$C0
  DEFB $05,$80
  DEFB $05,$E0
  DEFB $05,$C0
  DEFB $09,$80
  DEFB $09,$E0
  DEFB $09,$D0
  DEFB $09,$80
  DEFB $09,$E8
  DEFB $09,$C2
  DEFB $09,$80
  DEFB $11,$E8
  DEFB $11,$C0
  DEFB $11,$82
  DEFB $00,$00            ; frame 7: spiky post (right), frame 3
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$C0
  DEFB $01,$F8
  DEFB $01,$70
  DEFB $01,$60
  DEFB $01,$78
  DEFB $01,$70
  DEFB $02,$60
  DEFB $02,$78
  DEFB $02,$70
  DEFB $02,$61
  DEFB $02,$78

; Sprites: flapper, left and right (8 frames); also Willy in The Nightmare Room
;
; Eight 16x16 sprites of 32 bytes, 16 pixel rows of 2 bytes each (left byte,
; right byte; bit 7 = leftmost pixel). Sprite F of the page is at $B600+32*F.
; Entity definitions (EntityDefs) name the page in byte +5 and pick F from the
; animation phase, the direction and the slot data. The sprites are drawn with
; DrawSprite (DrawEntities) and have no colour of their own: ink and bright
; come from the entity definition. A small creature with a body and a flapping
; wing drawn in a dithered pattern. Frames 0-3 face left, 4-7 face right (the
; order of the entity pages: bit 7 of entity byte +0 selects the right half).
; Used by entity definition $1A in rooms $02 $0B $0C $27. DrawWilly also uses
; this page instead of Willy's own sprites (SpriteWillyRight0) in The Nightmare
; Room (room $1D): it XORs bit 7 of the frame offset, because Willy's sprites
; have the right-facing frames first while this page has the left-facing ones
; first.
SpritesFlapper:
  DEFB $00,$00            ; frame 0: flapper facing left, frame 0
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $13,$40
  DEFB $17,$80
  DEFB $3F,$C0
  DEFB $55,$40
  DEFB $FA,$A0
  DEFB $FD,$40
  DEFB $1F,$A0
  DEFB $08,$80
  DEFB $05,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00            ; frame 1: flapper facing left, frame 1
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $08,$D0
  DEFB $05,$E0
  DEFB $0F,$F0
  DEFB $16,$B0
  DEFB $3D,$50
  DEFB $3E,$A8
  DEFB $07,$50
  DEFB $02,$A8
  DEFB $02,$54
  DEFB $00,$28
  DEFB $00,$14
  DEFB $00,$00            ; frame 2: flapper facing left, frame 2
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $02,$34
  DEFB $01,$78
  DEFB $03,$FC
  DEFB $05,$54
  DEFB $0F,$AA
  DEFB $0F,$D4
  DEFB $01,$FA
  DEFB $00,$88
  DEFB $01,$04
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$03            ; frame 3: flapper facing left, frame 3 (wing up)
  DEFB $00,$0A
  DEFB $00,$15
  DEFB $00,$0A
  DEFB $00,$15
  DEFB $00,$AB
  DEFB $00,$56
  DEFB $00,$EB
  DEFB $01,$55
  DEFB $03,$EB
  DEFB $03,$FF
  DEFB $00,$7E
  DEFB $00,$22
  DEFB $00,$22
  DEFB $00,$00
  DEFB $00,$00
  DEFB $80,$00            ; frame 4: flapper facing right, frame 0 (wing up)
  DEFB $50,$00
  DEFB $A8,$00
  DEFB $50,$00
  DEFB $A8,$00
  DEFB $D5,$00
  DEFB $6A,$00
  DEFB $D7,$00
  DEFB $AA,$80
  DEFB $D7,$C0
  DEFB $FF,$C0
  DEFB $7E,$00
  DEFB $44,$00
  DEFB $44,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00            ; frame 5: flapper facing right, frame 1
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $2C,$40
  DEFB $1E,$80
  DEFB $3F,$C0
  DEFB $2A,$A0
  DEFB $55,$F0
  DEFB $2B,$F0
  DEFB $5F,$80
  DEFB $11,$00
  DEFB $20,$80
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00            ; frame 6: flapper facing right, frame 2
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $0B,$10
  DEFB $07,$A0
  DEFB $0F,$F0
  DEFB $0D,$68
  DEFB $0A,$BC
  DEFB $15,$7C
  DEFB $0A,$E0
  DEFB $15,$40
  DEFB $2A,$40
  DEFB $14,$00
  DEFB $28,$00
  DEFB $00,$00            ; frame 7: flapper facing right, frame 3
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $02,$C8
  DEFB $01,$E8
  DEFB $03,$FC
  DEFB $02,$AA
  DEFB $05,$5F
  DEFB $02,$BF
  DEFB $05,$F8
  DEFB $01,$10
  DEFB $00,$A0
  DEFB $00,$00
  DEFB $00,$00

; Sprites: crowned creature, dome, bars, spotted ball
;
; Eight 16x16 sprites of 32 bytes, 16 pixel rows of 2 bytes each (left byte,
; right byte; bit 7 = leftmost pixel). Sprite F of the page is at $B700+32*F.
; Entity definitions (EntityDefs) name the page in byte +5 and pick F from the
; animation phase, the direction and the slot data. The sprites are drawn with
; DrawSprite (DrawEntities) and have no colour of their own: ink and bright
; come from the entity definition. Frames 0-1 look like a creature with a crown
; and raised prongs (entities $30-$32 in The Kitchen, room $17, and West of
; Kitchen, room $18). Frames 2-3 look like a striped dome (entities $1F, $33).
; Frame 4 is a narrow bar pattern and frames 5-7 a spotted ball turning (entity
; $5C, frames 4-7). Used by entity definitions $1F $30 $31 $32 $33 $5C in rooms
; $16 $17 $18 $2E $34 $37 $39.
SpritesCrownDomeBall:
  DEFB $0A,$A0            ; frame 0: crowned creature, frame 0
  DEFB $15,$50
  DEFB $0A,$A0
  DEFB $05,$42
  DEFB $05,$45
  DEFB $05,$45
  DEFB $07,$C2
  DEFB $0D,$62
  DEFB $0F,$E3
  DEFB $3C,$7F
  DEFB $7B,$BF
  DEFB $EF,$E3
  DEFB $AE,$E2
  DEFB $47,$C2
  DEFB $CE,$C0
  DEFB $C0,$E0
  DEFB $C0,$00            ; frame 1: crowned creature, frame 1
  DEFB $CA,$A0
  DEFB $D5,$50
  DEFB $CA,$A0
  DEFB $45,$40
  DEFB $45,$42
  DEFB $A7,$C5
  DEFB $CD,$65
  DEFB $6F,$E2
  DEFB $7C,$7A
  DEFB $3A,$BF
  DEFB $0F,$EF
  DEFB $0E,$E3
  DEFB $07,$C2
  DEFB $06,$E2
  DEFB $0E,$02
  DEFB $03,$00            ; frame 2: dome, frame 0
  DEFB $04,$80
  DEFB $05,$C0
  DEFB $0B,$A0
  DEFB $15,$40
  DEFB $17,$60
  DEFB $17,$60
  DEFB $1F,$E0
  DEFB $13,$90
  DEFB $2D,$68
  DEFB $2F,$78
  DEFB $2F,$78
  DEFB $2F,$78
  DEFB $2F,$78
  DEFB $AF,$79
  DEFB $7F,$FE
  DEFB $00,$C0            ; frame 3: dome, frame 1
  DEFB $01,$20
  DEFB $01,$70
  DEFB $02,$E8
  DEFB $05,$50
  DEFB $05,$D8
  DEFB $05,$D8
  DEFB $07,$F8
  DEFB $09,$C8
  DEFB $16,$B4
  DEFB $17,$BC
  DEFB $17,$BC
  DEFB $17,$BC
  DEFB $17,$BC
  DEFB $97,$BD
  DEFB $7F,$FE
  DEFB $76,$00            ; frame 4: bars (frame 0 of the entity $5C cycle)
  DEFB $00,$00
  DEFB $6E,$00
  DEFB $76,$00
  DEFB $6E,$00
  DEFB $00,$00
  DEFB $76,$00
  DEFB $6E,$00
  DEFB $00,$00
  DEFB $76,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $6E,$00
  DEFB $76,$00
  DEFB $00,$00
  DEFB $6E,$00
  DEFB $1D,$80            ; frame 5: spotted ball, frame 0
  DEFB $2A,$00
  DEFB $27,$60
  DEFB $51,$B0
  DEFB $4B,$D0
  DEFB $90,$80
  DEFB $AA,$E8
  DEFB $94,$B8
  DEFB $91,$80
  DEFB $AA,$D8
  DEFB $91,$00
  DEFB $55,$00
  DEFB $4B,$B0
  DEFB $2B,$60
  DEFB $24,$00
  DEFB $1D,$80
  DEFB $03,$C0            ; frame 6: spotted ball, frame 1
  DEFB $0C,$30
  DEFB $10,$98
  DEFB $32,$14
  DEFB $68,$82
  DEFB $40,$2A
  DEFB $B5,$11
  DEFB $C8,$45
  DEFB $A4,$91
  DEFB $9A,$05
  DEFB $48,$42
  DEFB $55,$0A
  DEFB $28,$54
  DEFB $12,$88
  DEFB $0D,$70
  DEFB $03,$C0
  DEFB $01,$B8            ; frame 7: spotted ball, frame 2
  DEFB $00,$54
  DEFB $06,$E4
  DEFB $0D,$8A
  DEFB $0B,$D2
  DEFB $01,$09
  DEFB $17,$55
  DEFB $1D,$29
  DEFB $01,$89
  DEFB $1B,$55
  DEFB $00,$89
  DEFB $00,$AA
  DEFB $0D,$D2
  DEFB $06,$D4
  DEFB $00,$24
  DEFB $01,$B8

; Sprites: profile critter (4 frames), hooded figure (4 frames)
;
; Eight 16x16 sprites of 32 bytes, 16 pixel rows of 2 bytes each (left byte,
; right byte; bit 7 = leftmost pixel). Sprite F of the page is at $B800+32*F.
; Entity definitions (EntityDefs) name the page in byte +5 and pick F from the
; animation phase, the direction and the slot data. The sprites are drawn with
; DrawSprite (DrawEntities) and have no colour of their own: ink and bright
; come from the entity definition. Frames 0-3 look like an animal in profile
; with a pointed tip at the top; frames 4-7 look like an upright hooded figure
; whose arms go up and down. Entities that use all eight frames show one while
; moving left and the other while moving right (bit 7 of entity byte +0). Used
; by entity definitions $20 $21 $22 $23 in rooms $02 $12 $15 $2E.
SpritesCritterHooded:
  DEFB $00,$00            ; frame 0: critter in profile, frame 0
  DEFB $06,$00
  DEFB $08,$00
  DEFB $38,$00
  DEFB $50,$00
  DEFB $F0,$00
  DEFB $F8,$00
  DEFB $3C,$00
  DEFB $3E,$00
  DEFB $7E,$00
  DEFB $9F,$00
  DEFB $1F,$00
  DEFB $1F,$C0
  DEFB $0E,$C0
  DEFB $18,$00
  DEFB $60,$00
  DEFB $00,$00            ; frame 1: critter in profile, frame 1
  DEFB $00,$00
  DEFB $0F,$00
  DEFB $14,$80
  DEFB $3C,$00
  DEFB $0E,$00
  DEFB $3F,$00
  DEFB $0F,$80
  DEFB $1F,$80
  DEFB $2F,$C0
  DEFB $0F,$C0
  DEFB $07,$F0
  DEFB $03,$B0
  DEFB $01,$00
  DEFB $02,$00
  DEFB $04,$00
  DEFB $00,$00            ; frame 2: critter in profile, frame 2
  DEFB $00,$60
  DEFB $00,$80
  DEFB $03,$80
  DEFB $0D,$00
  DEFB $07,$00
  DEFB $03,$80
  DEFB $07,$C0
  DEFB $0B,$E0
  DEFB $07,$E0
  DEFB $09,$F0
  DEFB $01,$F0
  DEFB $01,$FC
  DEFB $00,$EC
  DEFB $01,$80
  DEFB $06,$00
  DEFB $00,$00            ; frame 3: critter in profile, frame 3
  DEFB $00,$00
  DEFB $00,$04
  DEFB $00,$08
  DEFB $00,$70
  DEFB $00,$A0
  DEFB $01,$E0
  DEFB $00,$70
  DEFB $01,$F8
  DEFB $00,$78
  DEFB $01,$FC
  DEFB $00,$7C
  DEFB $00,$7C
  DEFB $00,$7F
  DEFB $00,$3B
  DEFB $00,$F0
  DEFB $04,$00            ; frame 4: hooded figure, arms down
  DEFB $04,$00
  DEFB $0C,$00
  DEFB $0C,$00
  DEFB $16,$00
  DEFB $1E,$00
  DEFB $3E,$00
  DEFB $6C,$00
  DEFB $9E,$00
  DEFB $3F,$00
  DEFB $3F,$00
  DEFB $3F,$00
  DEFB $7F,$00
  DEFB $56,$00
  DEFB $1C,$00
  DEFB $06,$00
  DEFB $04,$80            ; frame 5: hooded figure, arms up
  DEFB $08,$40
  DEFB $13,$20
  DEFB $13,$20
  DEFB $17,$A0
  DEFB $13,$20
  DEFB $1F,$E0
  DEFB $1B,$60
  DEFB $27,$90
  DEFB $0F,$C0
  DEFB $0F,$C0
  DEFB $0F,$C0
  DEFB $0F,$C0
  DEFB $1D,$80
  DEFB $03,$80
  DEFB $01,$00
  DEFB $00,$80            ; frame 6: hooded figure, arms down (b)
  DEFB $00,$80
  DEFB $00,$C0
  DEFB $00,$C0
  DEFB $01,$A0
  DEFB $01,$E0
  DEFB $01,$F0
  DEFB $00,$D8
  DEFB $01,$E4
  DEFB $03,$F0
  DEFB $03,$F0
  DEFB $03,$F0
  DEFB $03,$F8
  DEFB $01,$A8
  DEFB $00,$E0
  DEFB $01,$80
  DEFB $00,$48            ; frame 7: hooded figure, arms up (b)
  DEFB $00,$84
  DEFB $01,$32
  DEFB $01,$02
  DEFB $01,$7A
  DEFB $01,$7A
  DEFB $01,$FE
  DEFB $01,$B6
  DEFB $02,$79
  DEFB $00,$FC
  DEFB $00,$FC
  DEFB $00,$FC
  DEFB $00,$FC
  DEFB $00,$6E
  DEFB $00,$70
  DEFB $00,$20

; Sprites: coil (4 frames), fringed dome (4 frames)
;
; Eight 16x16 sprites of 32 bytes, 16 pixel rows of 2 bytes each (left byte,
; right byte; bit 7 = leftmost pixel). Sprite F of the page is at $B900+32*F.
; Entity definitions (EntityDefs) name the page in byte +5 and pick F from the
; animation phase, the direction and the slot data. The sprites are drawn with
; DrawSprite (DrawEntities) and have no colour of their own: ink and bright
; come from the entity definition. Frames 0-3 look like a twisting figure-eight
; or coil; frames 4-7 look like a checkered dome with a fringe underneath. Used
; by entity definitions $0E $3B $3E $5D in rooms $01 $09 $16 $21.
SpritesCoilDome:
  DEFB $3C,$00            ; frame 0: coil, frame 0 (upright)
  DEFB $6E,$00
  DEFB $A7,$00
  DEFB $A5,$00
  DEFB $77,$00
  DEFB $A3,$00
  DEFB $62,$00
  DEFB $2C,$00
  DEFB $34,$00
  DEFB $46,$00
  DEFB $C5,$00
  DEFB $EE,$00
  DEFB $A5,$00
  DEFB $E5,$00
  DEFB $76,$00
  DEFB $3C,$00
  DEFB $00,$00            ; frame 1: coil, frame 1 (diagonal)
  DEFB $00,$00
  DEFB $00,$B0
  DEFB $01,$48
  DEFB $03,$FC
  DEFB $00,$44
  DEFB $02,$0C
  DEFB $02,$7C
  DEFB $35,$D8
  DEFB $46,$F0
  DEFB $C5,$00
  DEFB $EE,$00
  DEFB $A5,$00
  DEFB $E5,$00
  DEFB $76,$00
  DEFB $3C,$00
  DEFB $00,$00            ; frame 2: coil, frame 2 (flat)
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $34,$34
  DEFB $46,$46
  DEFB $C5,$C5
  DEFB $EE,$EE
  DEFB $A5,$A5
  DEFB $E5,$E5
  DEFB $76,$76
  DEFB $3C,$3C
  DEFB $00,$00            ; frame 3: coil, frame 3 (diagonal)
  DEFB $00,$00
  DEFB $0F,$00
  DEFB $1B,$80
  DEFB $3E,$40
  DEFB $30,$40
  DEFB $22,$00
  DEFB $3F,$C0
  DEFB $12,$B4
  DEFB $0D,$46
  DEFB $00,$C5
  DEFB $00,$EE
  DEFB $00,$A5
  DEFB $00,$E5
  DEFB $00,$76
  DEFB $00,$3C
  DEFB $03,$C0            ; frame 4: fringed dome, frame 0
  DEFB $06,$60
  DEFB $0D,$F0
  DEFB $1A,$D8
  DEFB $35,$5C
  DEFB $20,$04
  DEFB $7F,$FE
  DEFB $D7,$75
  DEFB $B2,$27
  DEFB $D7,$75
  DEFB $7F,$FE
  DEFB $15,$78
  DEFB $25,$A4
  DEFB $02,$40
  DEFB $11,$88
  DEFB $00,$00
  DEFB $03,$C0            ; frame 5: fringed dome, frame 1
  DEFB $06,$60
  DEFB $0D,$F0
  DEFB $1A,$B8
  DEFB $35,$5C
  DEFB $20,$04
  DEFB $7F,$FE
  DEFB $AE,$EB
  DEFB $E4,$4D
  DEFB $AE,$EB
  DEFB $7F,$FE
  DEFB $15,$78
  DEFB $0A,$50
  DEFB $01,$80
  DEFB $04,$20
  DEFB $01,$00
  DEFB $03,$C0            ; frame 6: fringed dome, frame 2
  DEFB $06,$60
  DEFB $0D,$F0
  DEFB $1A,$D8
  DEFB $35,$5C
  DEFB $20,$04
  DEFB $7F,$FE
  DEFB $ED,$DB
  DEFB $A8,$93
  DEFB $ED,$DB
  DEFB $7F,$FE
  DEFB $15,$78
  DEFB $25,$A4
  DEFB $02,$40
  DEFB $11,$88
  DEFB $04,$20
  DEFB $03,$C0            ; frame 7: fringed dome, frame 3
  DEFB $06,$60
  DEFB $0D,$F0
  DEFB $1A,$E8
  DEFB $35,$5C
  DEFB $20,$04
  DEFB $7F,$FE
  DEFB $DB,$B7
  DEFB $C9,$15
  DEFB $DB,$B7
  DEFB $7F,$FE
  DEFB $15,$78
  DEFB $0A,$42
  DEFB $41,$90
  DEFB $04,$00
  DEFB $11,$44

; Sprites: skull face (4 frames), checkered blobs, dripping fringe
;
; Eight 16x16 sprites of 32 bytes, 16 pixel rows of 2 bytes each (left byte,
; right byte; bit 7 = leftmost pixel). Sprite F of the page is at $BA00+32*F.
; Entity definitions (EntityDefs) name the page in byte +5 and pick F from the
; animation phase, the direction and the slot data. The sprites are drawn with
; DrawSprite (DrawEntities) and have no colour of their own: ink and bright
; come from the entity definition. Frames 0-3 look like a skull-like face with
; a hat brim and crossed bones; entities show frames 0 and 2 or 1 and 3 so that
; neighbours alternate. Frames 4 and 5 are checkered blobs and 6-7 a dripping
; fringe; entities $10-$12 use them at three places in the rooms with the big
; lettering (Entrance to Hades $06, The Chapel $1B, Priests' Hole $26). Used by
; entity definitions $10 $11 $12 $28 $29 $2A $2B $2C $2D in rooms $00 $02 $06
; $08 $0D $14 $15 $1A $1B $26 $2E.
SpritesSkullBlobDrip:
  DEFB $07,$E0            ; frame 0: skull face, frame 0
  DEFB $0F,$F0
  DEFB $DF,$FB
  DEFB $3F,$FC
  DEFB $1F,$F8
  DEFB $1F,$F8
  DEFB $31,$8C
  DEFB $6A,$56
  DEFB $B1,$8D
  DEFB $9E,$F9
  DEFB $0D,$F0
  DEFB $1D,$B8
  DEFB $36,$6C
  DEFB $59,$9A
  DEFB $8C,$31
  DEFB $07,$E0
  DEFB $07,$E0            ; frame 1: skull face, frame 1
  DEFB $0F,$F0
  DEFB $1F,$F8
  DEFB $FF,$FF
  DEFB $1F,$F8
  DEFB $1F,$F8
  DEFB $31,$8C
  DEFB $2A,$54
  DEFB $71,$8E
  DEFB $9E,$F9
  DEFB $8D,$F1
  DEFB $1D,$B8
  DEFB $32,$4C
  DEFB $58,$1A
  DEFB $4C,$32
  DEFB $07,$E0
  DEFB $07,$E0            ; frame 2: skull face, frame 2
  DEFB $0F,$F0
  DEFB $1F,$F8
  DEFB $DF,$FB
  DEFB $3F,$FC
  DEFB $1F,$F8
  DEFB $31,$8C
  DEFB $2A,$54
  DEFB $30,$8C
  DEFB $5D,$FA
  DEFB $8D,$B1
  DEFB $9A,$59
  DEFB $12,$48
  DEFB $18,$18
  DEFB $2C,$34
  DEFB $C7,$E3
  DEFB $07,$E0            ; frame 3: skull face, frame 3
  DEFB $8F,$F1
  DEFB $5F,$FA
  DEFB $3F,$FC
  DEFB $1F,$F8
  DEFB $11,$88
  DEFB $2E,$74
  DEFB $2A,$54
  DEFB $71,$8E
  DEFB $5E,$FA
  DEFB $8D,$F1
  DEFB $1D,$B8
  DEFB $12,$48
  DEFB $78,$1E
  DEFB $8C,$31
  DEFB $07,$E0
  DEFB $15,$03            ; frame 4: checkered blob, frame 0 (entity $10)
  DEFB $2A,$BE
  DEFB $15,$5E
  DEFB $4A,$A8
  DEFB $35,$5C
  DEFB $8A,$AE
  DEFB $6D,$5C
  DEFB $99,$F9
  DEFB $6E,$BF
  DEFB $DD,$63
  DEFB $2E,$49
  DEFB $59,$81
  DEFB $04,$82
  DEFB $2B,$C6
  DEFB $12,$FC
  DEFB $0C,$FD
  DEFB $40,$A8            ; frame 5: checkered blob, frame 1 (entity $11)
  DEFB $FD,$54
  DEFB $7A,$A8
  DEFB $15,$52
  DEFB $3A,$AC
  DEFB $75,$51
  DEFB $3A,$B6
  DEFB $9F,$99
  DEFB $FD,$76
  DEFB $C6,$BB
  DEFB $92,$74
  DEFB $81,$9A
  DEFB $41,$20
  DEFB $63,$D4
  DEFB $3F,$48
  DEFB $BF,$30
  DEFB $FD,$BF            ; frame 6: dripping fringe, frame 0 (entity $12)
  DEFB $BF,$EF
  DEFB $EA,$D7
  DEFB $AA,$45
  DEFB $68,$D4
  DEFB $48,$84
  DEFB $40,$04
  DEFB $40,$01
  DEFB $50,$00
  DEFB $12,$0A
  DEFB $40,$0C
  DEFB $2A,$22
  DEFB $14,$A8
  DEFB $20,$84
  DEFB $14,$28
  DEFB $05,$20
  DEFB $FD,$BF            ; frame 7: dripping fringe, frame 1 (entity $12)
  DEFB $FF,$FB
  DEFB $AC,$D7
  DEFB $AA,$D1
  DEFB $2A,$54
  DEFB $82,$44
  DEFB $42,$01
  DEFB $08,$04
  DEFB $4A,$10
  DEFB $22,$82
  DEFB $08,$A8
  DEFB $14,$04
  DEFB $0A,$90
  DEFB $01,$40
  DEFB $00,$00
  DEFB $00,$00

; Sprites: cone (4 frames), balloon on legs (4 frames)
;
; Eight 16x16 sprites of 32 bytes, 16 pixel rows of 2 bytes each (left byte,
; right byte; bit 7 = leftmost pixel). Sprite F of the page is at $BB00+32*F.
; Entity definitions (EntityDefs) name the page in byte +5 and pick F from the
; animation phase, the direction and the slot data. The sprites are drawn with
; DrawSprite (DrawEntities) and have no colour of their own: ink and bright
; come from the entity definition. Frames 0-3 look like a dark blob over a
; checkered cone; frames 4-7 look like a checkered balloon with a bar and two
; stick legs. Used by entity definitions $2E $2F $37 $39 $6C in rooms $08 $0C
; $19 $2A $32.
SpritesConeBalloon:
  DEFB $0C,$00            ; frame 0: cone, frame 0
  DEFB $36,$80
  DEFB $7F,$40
  DEFB $7E,$80
  DEFB $FD,$00
  DEFB $FE,$80
  DEFB $FF,$80
  DEFB $FF,$00
  DEFB $55,$00
  DEFB $2A,$00
  DEFB $14,$00
  DEFB $2A,$00
  DEFB $14,$00
  DEFB $08,$00
  DEFB $14,$00
  DEFB $08,$00
  DEFB $03,$00            ; frame 1: cone, frame 1
  DEFB $0D,$A0
  DEFB $1F,$D0
  DEFB $1F,$A0
  DEFB $3F,$40
  DEFB $3F,$A0
  DEFB $3F,$E0
  DEFB $3F,$C0
  DEFB $35,$40
  DEFB $2A,$80
  DEFB $05,$00
  DEFB $0A,$80
  DEFB $05,$00
  DEFB $02,$00
  DEFB $05,$00
  DEFB $02,$00
  DEFB $00,$C0            ; frame 2: cone, frame 2
  DEFB $03,$68
  DEFB $07,$F4
  DEFB $07,$E8
  DEFB $0F,$D0
  DEFB $0F,$E8
  DEFB $0F,$F8
  DEFB $0F,$F0
  DEFB $05,$50
  DEFB $0A,$A0
  DEFB $01,$40
  DEFB $02,$A0
  DEFB $09,$40
  DEFB $00,$80
  DEFB $01,$40
  DEFB $00,$80
  DEFB $00,$30            ; frame 3: cone, frame 3
  DEFB $00,$DA
  DEFB $01,$FD
  DEFB $01,$FA
  DEFB $03,$F4
  DEFB $03,$FA
  DEFB $03,$FE
  DEFB $03,$FC
  DEFB $03,$54
  DEFB $02,$A8
  DEFB $00,$50
  DEFB $00,$A8
  DEFB $00,$50
  DEFB $00,$20
  DEFB $00,$50
  DEFB $00,$20
  DEFB $04,$00            ; frame 4: balloon on legs, frame 0
  DEFB $2A,$80
  DEFB $55,$40
  DEFB $2B,$80
  DEFB $44,$40
  DEFB $AF,$A0
  DEFB $5F,$40
  DEFB $20,$80
  DEFB $55,$40
  DEFB $2A,$80
  DEFB $04,$00
  DEFB $04,$00
  DEFB $08,$00
  DEFB $3E,$00
  DEFB $41,$00
  DEFB $81,$00
  DEFB $02,$00            ; frame 5: balloon on legs, frame 1
  DEFB $15,$40
  DEFB $2A,$A0
  DEFB $15,$C0
  DEFB $22,$20
  DEFB $5F,$50
  DEFB $2A,$A0
  DEFB $10,$40
  DEFB $2A,$A0
  DEFB $15,$40
  DEFB $02,$00
  DEFB $02,$00
  DEFB $0E,$00
  DEFB $11,$80
  DEFB $20,$40
  DEFB $00,$00
  DEFB $00,$40            ; frame 6: balloon on legs, frame 2
  DEFB $02,$A8
  DEFB $05,$54
  DEFB $03,$A8
  DEFB $04,$44
  DEFB $0B,$EA
  DEFB $05,$F4
  DEFB $02,$08
  DEFB $05,$54
  DEFB $02,$A8
  DEFB $00,$40
  DEFB $00,$40
  DEFB $00,$70
  DEFB $01,$88
  DEFB $02,$04
  DEFB $00,$00
  DEFB $00,$20            ; frame 7: balloon on legs, frame 3
  DEFB $01,$54
  DEFB $02,$AA
  DEFB $01,$D4
  DEFB $02,$22
  DEFB $05,$7D
  DEFB $02,$FA
  DEFB $01,$54
  DEFB $02,$AA
  DEFB $01,$54
  DEFB $00,$20
  DEFB $00,$20
  DEFB $00,$10
  DEFB $00,$7C
  DEFB $00,$82
  DEFB $00,$81

; Sprites: small flyer, left and right (8 frames)
;
; Eight 16x16 sprites of 32 bytes, 16 pixel rows of 2 bytes each (left byte,
; right byte; bit 7 = leftmost pixel). Sprite F of the page is at $BC00+32*F.
; Entity definitions (EntityDefs) name the page in byte +5 and pick F from the
; animation phase, the direction and the slot data. The sprites are drawn with
; DrawSprite (DrawEntities) and have no colour of their own: ink and bright
; come from the entity definition. A small creature in side view, mostly 8
; pixels high, that looks like a bird or insect with changing wing positions.
; Frames 0-3 are used while moving left, 4-7 while moving right (bit 7 of
; entity byte +0). Used by entity definitions $0D $14 $15 $16 $17 $18 $19 $1C
; $25 $5F $68 $6D in rooms $01 $04 $08 $0B $0C $0D $0E $0F $10 $14 $16 $24 $26
; $2D $30 $32 $36 $38: the most used page.
SpritesSmallFlyers:
  DEFB $00,$00            ; frame 0: small flyer facing left, frame 0
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $6F,$40
  DEFB $BB,$80
  DEFB $75,$40
  DEFB $1A,$80
  DEFB $05,$00
  DEFB $00,$80
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00            ; frame 1: small flyer facing left, frame 1
  DEFB $00,$00
  DEFB $00,$A0
  DEFB $01,$40
  DEFB $02,$80
  DEFB $01,$50
  DEFB $36,$A0
  DEFB $5D,$70
  DEFB $37,$E0
  DEFB $03,$C0
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00            ; frame 2: small flyer facing left, frame 2
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$F4
  DEFB $19,$B8
  DEFB $2F,$54
  DEFB $19,$A8
  DEFB $00,$50
  DEFB $00,$08
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00            ; frame 3: small flyer facing left, frame 3
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$3D
  DEFB $03,$7E
  DEFB $05,$D7
  DEFB $03,$6A
  DEFB $00,$14
  DEFB $00,$28
  DEFB $00,$14
  DEFB $00,$0A
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00            ; frame 4: small flyer facing right, frame 0
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $BC,$00
  DEFB $7E,$C0
  DEFB $EB,$A0
  DEFB $56,$C0
  DEFB $28,$00
  DEFB $14,$00
  DEFB $28,$00
  DEFB $50,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00            ; frame 5: small flyer facing right, frame 1
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $2F,$00
  DEFB $1D,$98
  DEFB $2A,$F4
  DEFB $15,$98
  DEFB $0A,$00
  DEFB $10,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00            ; frame 6: small flyer facing right, frame 2
  DEFB $00,$00
  DEFB $05,$00
  DEFB $02,$80
  DEFB $01,$40
  DEFB $0A,$80
  DEFB $05,$6C
  DEFB $0E,$BA
  DEFB $07,$EC
  DEFB $03,$C0
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00            ; frame 7: small flyer facing right, frame 3
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $02,$F6
  DEFB $01,$DD
  DEFB $02,$AE
  DEFB $01,$58
  DEFB $00,$A0
  DEFB $01,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00

; Sprites: hatted bird, left and right (8 frames)
;
; Eight 16x16 sprites of 32 bytes, 16 pixel rows of 2 bytes each (left byte,
; right byte; bit 7 = leftmost pixel). Sprite F of the page is at $BD00+32*F.
; Entity definitions (EntityDefs) name the page in byte +5 and pick F from the
; animation phase, the direction and the slot data. The sprites are drawn with
; DrawSprite (DrawEntities) and have no colour of their own: ink and bright
; come from the entity definition. An upright bird-like figure with a hat and a
; beak, walking. Frames 0-3 are used while moving left, 4-7 while moving right
; (bit 7 of entity byte +0). Used by entity definitions $36 $38 in rooms $19
; (The Cold Store).
SpritesHatBirds:
  DEFB $18,$00            ; frame 0: hatted bird facing left, frame 0
  DEFB $3C,$00
  DEFB $D4,$00
  DEFB $2E,$00
  DEFB $3A,$00
  DEFB $3A,$00
  DEFB $5A,$00
  DEFB $5D,$00
  DEFB $4F,$00
  DEFB $43,$00
  DEFB $21,$80
  DEFB $22,$00
  DEFB $1E,$00
  DEFB $14,$00
  DEFB $13,$00
  DEFB $3C,$00
  DEFB $06,$00            ; frame 1: hatted bird facing left, frame 1
  DEFB $0F,$00
  DEFB $3F,$00
  DEFB $0B,$80
  DEFB $0E,$80
  DEFB $0E,$80
  DEFB $1F,$00
  DEFB $17,$80
  DEFB $11,$C0
  DEFB $10,$60
  DEFB $08,$40
  DEFB $08,$80
  DEFB $07,$80
  DEFB $02,$00
  DEFB $02,$00
  DEFB $07,$00
  DEFB $01,$80            ; frame 2: hatted bird facing left, frame 2
  DEFB $0B,$C0
  DEFB $05,$40
  DEFB $0A,$E0
  DEFB $03,$A0
  DEFB $03,$A0
  DEFB $05,$A0
  DEFB $05,$D0
  DEFB $04,$F0
  DEFB $04,$30
  DEFB $02,$18
  DEFB $02,$20
  DEFB $01,$E0
  DEFB $01,$40
  DEFB $06,$30
  DEFB $01,$40
  DEFB $00,$60            ; frame 3: hatted bird facing left, frame 3
  DEFB $00,$B0
  DEFB $03,$50
  DEFB $00,$B8
  DEFB $00,$E8
  DEFB $00,$E8
  DEFB $01,$68
  DEFB $01,$74
  DEFB $01,$3C
  DEFB $01,$0C
  DEFB $00,$86
  DEFB $00,$88
  DEFB $00,$78
  DEFB $00,$25
  DEFB $00,$22
  DEFB $00,$74
  DEFB $06,$00            ; frame 4: hatted bird facing right, frame 0
  DEFB $0D,$00
  DEFB $0A,$C0
  DEFB $1D,$00
  DEFB $17,$00
  DEFB $17,$00
  DEFB $16,$80
  DEFB $2E,$80
  DEFB $3C,$80
  DEFB $30,$80
  DEFB $61,$00
  DEFB $11,$00
  DEFB $1E,$00
  DEFB $A4,$00
  DEFB $44,$00
  DEFB $2E,$00
  DEFB $01,$80            ; frame 5: hatted bird facing right, frame 1
  DEFB $03,$D0
  DEFB $02,$A0
  DEFB $07,$50
  DEFB $05,$C0
  DEFB $05,$C0
  DEFB $05,$A0
  DEFB $0B,$A0
  DEFB $0F,$20
  DEFB $0C,$20
  DEFB $18,$40
  DEFB $04,$40
  DEFB $07,$80
  DEFB $02,$80
  DEFB $0C,$60
  DEFB $02,$80
  DEFB $00,$60            ; frame 6: hatted bird facing right, frame 2
  DEFB $00,$F0
  DEFB $00,$FC
  DEFB $01,$D0
  DEFB $01,$70
  DEFB $01,$70
  DEFB $00,$F8
  DEFB $01,$E8
  DEFB $03,$88
  DEFB $06,$08
  DEFB $02,$10
  DEFB $01,$10
  DEFB $01,$E0
  DEFB $00,$40
  DEFB $00,$40
  DEFB $00,$E0
  DEFB $00,$18            ; frame 7: hatted bird facing right, frame 3
  DEFB $00,$3C
  DEFB $00,$2B
  DEFB $00,$74
  DEFB $00,$5C
  DEFB $00,$5C
  DEFB $00,$5A
  DEFB $00,$BA
  DEFB $00,$F2
  DEFB $00,$C2
  DEFB $01,$84
  DEFB $00,$44
  DEFB $00,$78
  DEFB $00,$50
  DEFB $01,$90
  DEFB $00,$78

; Sprites: head on a stalk (4 frames), dark ball (4 frames)
;
; Eight 16x16 sprites of 32 bytes, 16 pixel rows of 2 bytes each (left byte,
; right byte; bit 7 = leftmost pixel). Sprite F of the page is at $BE00+32*F.
; Entity definitions (EntityDefs) name the page in byte +5 and pick F from the
; animation phase, the direction and the slot data. The sprites are drawn with
; DrawSprite (DrawEntities) and have no colour of their own: ink and bright
; come from the entity definition. Frames 0-3 look like a head or flower
; (round, notched, bow-like) on a stalk above a decorated base; frames 4-7 look
; like a dark round ball with a highlight. Used by entity definitions $0A $0C
; $5B $69 $6B in rooms $00 $16 $30 $3C.
SpritesStalkHeadBall:
  DEFB $0C,$00            ; frame 0: stalk head, round
  DEFB $12,$00
  DEFB $21,$00
  DEFB $2D,$00
  DEFB $21,$00
  DEFB $12,$00
  DEFB $0C,$00
  DEFB $0C,$00
  DEFB $1E,$00
  DEFB $00,$00
  DEFB $37,$00
  DEFB $40,$00
  DEFB $0D,$40
  DEFB $AC,$40
  DEFB $40,$80
  DEFB $2E,$00
  DEFB $0E,$C0            ; frame 1: stalk head, notched
  DEFB $1D,$A0
  DEFB $1F,$00
  DEFB $1F,$E0
  DEFB $1F,$00
  DEFB $1D,$A0
  DEFB $0E,$C0
  DEFB $03,$00
  DEFB $07,$80
  DEFB $00,$00
  DEFB $0E,$C0
  DEFB $00,$20
  DEFB $2B,$00
  DEFB $23,$50
  DEFB $10,$60
  DEFB $07,$00
  DEFB $04,$08            ; frame 2: stalk head, bow-like
  DEFB $06,$18
  DEFB $07,$38
  DEFB $0F,$FC
  DEFB $07,$38
  DEFB $06,$D8
  DEFB $04,$C8
  DEFB $00,$C0
  DEFB $01,$E0
  DEFB $00,$00
  DEFB $01,$D0
  DEFB $04,$08
  DEFB $08,$D4
  DEFB $0A,$C0
  DEFB $00,$08
  DEFB $03,$B0
  DEFB $00,$DC            ; frame 3: stalk head, notched (other side)
  DEFB $01,$6E
  DEFB $00,$3E
  DEFB $01,$FE
  DEFB $00,$3E
  DEFB $01,$6E
  DEFB $00,$DC
  DEFB $00,$30
  DEFB $00,$78
  DEFB $00,$00
  DEFB $00,$B8
  DEFB $01,$02
  DEFB $02,$B1
  DEFB $00,$35
  DEFB $01,$00
  DEFB $00,$DC
  DEFB $00,$00            ; frame 4: dark ball, frame 0
  DEFB $00,$00
  DEFB $07,$E0
  DEFB $1F,$B8
  DEFB $3D,$EC
  DEFB $7F,$FE
  DEFB $7D,$F6
  DEFB $FB,$F7
  DEFB $FB,$F7
  DEFB $7F,$EE
  DEFB $7F,$DE
  DEFB $3F,$FC
  DEFB $1F,$F8
  DEFB $07,$E0
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00            ; frame 5: dark ball, frame 1
  DEFB $01,$80
  DEFB $07,$E0
  DEFB $0D,$70
  DEFB $1F,$F8
  DEFB $3F,$FC
  DEFB $3F,$F4
  DEFB $7D,$FE
  DEFB $7B,$F6
  DEFB $3B,$EC
  DEFB $3F,$DC
  DEFB $1F,$38
  DEFB $0F,$F0
  DEFB $07,$E0
  DEFB $01,$80
  DEFB $00,$00
  DEFB $01,$80            ; frame 6: dark ball, frame 2
  DEFB $07,$E0
  DEFB $0F,$F0
  DEFB $1E,$F8
  DEFB $1F,$78
  DEFB $3F,$7C
  DEFB $3B,$FC
  DEFB $37,$F4
  DEFB $37,$FC
  DEFB $3F,$EC
  DEFB $3F,$EC
  DEFB $1F,$D8
  DEFB $1F,$38
  DEFB $0F,$F0
  DEFB $07,$E0
  DEFB $01,$80
  DEFB $00,$00            ; frame 7: dark ball, frame 3
  DEFB $01,$80
  DEFB $07,$E0
  DEFB $0F,$F0
  DEFB $1E,$B8
  DEFB $3F,$FC
  DEFB $3F,$F4
  DEFB $7B,$FE
  DEFB $77,$F6
  DEFB $37,$EC
  DEFB $3F,$DC
  DEFB $1F,$38
  DEFB $0F,$F0
  DEFB $07,$E0
  DEFB $01,$80
  DEFB $00,$00

; Sprites: stick figure (4 frames), spear guard and plumed guard (2 + 2 frames)
;
; Eight 16x16 sprites of 32 bytes, 16 pixel rows of 2 bytes each (left byte,
; right byte; bit 7 = leftmost pixel). Sprite F of the page is at $BF00+32*F.
; Entity definitions (EntityDefs) name the page in byte +5 and pick F from the
; animation phase, the direction and the slot data. The sprites are drawn with
; DrawSprite (DrawEntities) and have no colour of their own: ink and bright
; come from the entity definition. Frames 0-3 look like a figure with raised
; arms and a diagonal stick (entities $06-$09 and $0B, e.g. At the Foot of the
; MegaTree, room $03). Frames 4-5 look like a guard with a pointed cap and an
; upright spear; frames 6-7 the same with a wider hat (entities $02-$05 in The
; Security Guard, room $05, and rooms $0E, $0F, $11). Used by entity
; definitions $02 $03 $04 $05 $06 $07 $08 $09 $0B in rooms $03 $05 $08 $09 $0E
; $0F $11 $28 $30 $39.
SpritesImpsGuards:
  DEFB $80,$00            ; frame 0: stick figure, frame 0
  DEFB $40,$00
  DEFB $A3,$60
  DEFB $53,$60
  DEFB $29,$C0
  DEFB $16,$A0
  DEFB $0B,$E0
  DEFB $07,$70
  DEFB $02,$A8
  DEFB $05,$D4
  DEFB $02,$2A
  DEFB $03,$E5
  DEFB $03,$E2
  DEFB $03,$61
  DEFB $03,$62
  DEFB $07,$70
  DEFB $00,$00            ; frame 1: stick figure, frame 1
  DEFB $00,$00
  DEFB $06,$30
  DEFB $56,$30
  DEFB $A9,$C0
  DEFB $56,$A0
  DEFB $0B,$E0
  DEFB $06,$30
  DEFB $03,$E8
  DEFB $05,$D4
  DEFB $02,$2A
  DEFB $03,$E4
  DEFB $03,$EA
  DEFB $17,$64
  DEFB $0E,$60
  DEFB $04,$70
  DEFB $00,$00            ; frame 2: stick figure, frame 2
  DEFB $00,$00
  DEFB $03,$60
  DEFB $03,$60
  DEFB $01,$C0
  DEFB $1E,$A0
  DEFB $2B,$E0
  DEFB $56,$B4
  DEFB $A3,$6A
  DEFB $45,$D5
  DEFB $82,$22
  DEFB $03,$E1
  DEFB $03,$E2
  DEFB $03,$60
  DEFB $03,$60
  DEFB $07,$70
  DEFB $00,$00            ; frame 3: stick figure, frame 3
  DEFB $00,$00
  DEFB $06,$30
  DEFB $56,$30
  DEFB $A9,$C0
  DEFB $56,$A0
  DEFB $0B,$E0
  DEFB $07,$F4
  DEFB $02,$2A
  DEFB $05,$D5
  DEFB $02,$22
  DEFB $03,$E1
  DEFB $03,$E0
  DEFB $03,$74
  DEFB $03,$38
  DEFB $07,$10
  DEFB $02,$04            ; frame 4: spear guard, frame 0
  DEFB $05,$0E
  DEFB $0A,$84
  DEFB $15,$C4
  DEFB $17,$44
  DEFB $2B,$E4
  DEFB $2F,$E0
  DEFB $12,$44
  DEFB $08,$82
  DEFB $07,$2C
  DEFB $15,$50
  DEFB $2A,$A4
  DEFB $55,$44
  DEFB $AA,$84
  DEFB $45,$00
  DEFB $1D,$C0
  DEFB $02,$00            ; frame 5: spear guard, frame 1
  DEFB $05,$00
  DEFB $0A,$84
  DEFB $15,$CE
  DEFB $17,$44
  DEFB $2B,$E4
  DEFB $2F,$E4
  DEFB $12,$44
  DEFB $08,$80
  DEFB $07,$04
  DEFB $15,$52
  DEFB $2A,$AC
  DEFB $55,$40
  DEFB $AA,$84
  DEFB $45,$04
  DEFB $1D,$C4
  DEFB $00,$04            ; frame 6: plumed guard, frame 0
  DEFB $07,$06
  DEFB $2F,$A4
  DEFB $5F,$D4
  DEFB $30,$64
  DEFB $42,$14
  DEFB $32,$60
  DEFB $1F,$C4
  DEFB $08,$82
  DEFB $07,$2C
  DEFB $15,$50
  DEFB $2A,$A4
  DEFB $55,$44
  DEFB $AA,$84
  DEFB $45,$00
  DEFB $0C,$C0
  DEFB $00,$00            ; frame 7: plumed guard, frame 1
  DEFB $07,$00
  DEFB $2F,$A4
  DEFB $50,$56
  DEFB $22,$24
  DEFB $52,$54
  DEFB $3F,$E4
  DEFB $17,$44
  DEFB $08,$80
  DEFB $07,$04
  DEFB $15,$52
  DEFB $2A,$AC
  DEFB $55,$40
  DEFB $AA,$84
  DEFB $45,$04
  DEFB $19,$84
