; Leftover assembler source text
;
; 64 bytes of text from the source file of the program (an assembler's line
; buffer left in memory), cut off at $9C3F where the sprite data at SpriteFoot
; begins. Nothing references it. Readable parts: "NZ,ENDPAUSE", "INC E", "JR
; NZ,PAUSE", "INC D", "JR NZ,PAUSE", i.e. the lines of a delay loop with labels
; PAUSE and ENDPAUSE. The lines are split into fields by TAB ($09); each line
; seems to be preceded by a 2-byte prefix ("J" $06 or "J" $0C for the
; instruction part) and followed by a byte that grows by $21 per line ($82,
; $A3, $C4, $E5, $06); the meaning of those bytes is Unknown.
LeftoverSource:
  DEFB $4E,$5A,$2C,$45,$4E,$44,$50,$41,$55,$53,$45,$82,$4A,$06,$09,$49
  DEFB $4E,$43,$09,$45,$A3,$4A,$0C,$09,$4A,$52,$09,$4E,$5A,$2C,$50,$41
  DEFB $55,$53,$45,$C4,$4A,$06,$09,$49,$4E,$43,$09,$44,$E5,$4A,$0C,$09
  DEFB $4A,$52,$09,$4E,$5A,$2C,$50,$41,$55,$53,$45,$06,$4B,$0C,$09,$43

; Sprite: foot
;
; One 16x16 sprite of 32 bytes: 16 pixel rows of 2 bytes (left byte, right
; byte; bit 7 = leftmost pixel), drawn with DrawSprite. A foot (toe pointing
; right). It is frame 2 of sprite page $9C. Drawn at a falling position by the
; game-over sequence ResumeAfterPause (position from ScratchByte, while the
; screen flashes), and used as entity sprite by definition $48 in The Nightmare
; Room (room $1D), where it moves up and down.
SpriteFoot:
  DEFB $10,$80
  DEFB $10,$80
  DEFB $10,$80
  DEFB $10,$80
  DEFB $10,$80
  DEFB $10,$80
  DEFB $10,$80
  DEFB $20,$80
  DEFB $20,$80
  DEFB $48,$42
  DEFB $88,$35
  DEFB $84,$09
  DEFB $80,$01
  DEFB $80,$02
  DEFB $43,$8D
  DEFB $3C,$76

; Sprite: barrel
;
; One 16x16 sprite of 32 bytes: 16 pixel rows of 2 bytes (left byte, right
; byte; bit 7 = leftmost pixel), drawn with DrawSprite. A barrel with a dotted
; face. Frame 3 of sprite page $9C. Drawn by the game-over sequence
; ResumeAfterPause at $48CF (two character rows below Willy, SpriteWillyRight2,
; who stands on it), and used as entity sprite by definition $13 (a vertical
; mover in Ballroom East, room $14, and Top Landing, room $22).
SpriteBarrel:
  DEFB $37,$EC
  DEFB $77,$EE
  DEFB $00,$00
  DEFB $6F,$F6
  DEFB $EF,$F7
  DEFB $EF,$F7
  DEFB $D5,$5B
  DEFB $DB,$BB
  DEFB $D5,$5B
  DEFB $DF,$FB
  DEFB $ED,$77
  DEFB $EE,$F7
  DEFB $6D,$76
  DEFB $00,$00
  DEFB $77,$EE
  DEFB $37,$EC

; Sprite: hatted figure, frame 0
;
; One 16x16 sprite of 32 bytes: 16 pixel rows of 2 bytes (left byte, right
; byte; bit 7 = leftmost pixel), drawn with DrawSprite. Sprite 0 of the four
; figures with a pointed hat and a long dress (frame 4 of sprite page $9C;
; frames 0-1 of that page are the text leftovers at LeftoverSource).
; UpdateBedroom draws them in the Master Bedroom (room $23) at $686E: $9C80 and
; $9CA0 alternate with bit 1 of PassCounter while Willy stands on the floor (Y
; $D0), $9CC0 is used while his Y is $C0-$CF and $9CE0 when it is higher;
; drawing over Willy kills him. Entity definitions $46-$49 use all four in The
; Nightmare Room (room $1D).
SpriteFigure0:
  DEFB $03,$00
  DEFB $03,$C0
  DEFB $01,$E0
  DEFB $01,$40
  DEFB $01,$E0
  DEFB $07,$80
  DEFB $1F,$F8
  DEFB $3F,$FC
  DEFB $37,$6C
  DEFB $14,$98
  DEFB $0F,$F0
  DEFB $0F,$F0
  DEFB $0F,$F0
  DEFB $02,$40
  DEFB $02,$40
  DEFB $06,$60

; Sprite: hatted figure, frame 1
;
; One 16x16 sprite of 32 bytes: 16 pixel rows of 2 bytes (left byte, right
; byte; bit 7 = leftmost pixel), drawn with DrawSprite. Sprite 1 of the four
; figures with a pointed hat and a long dress (frame 5 of sprite page $9C;
; frames 0-1 of that page are the text leftovers at LeftoverSource).
; UpdateBedroom draws them in the Master Bedroom (room $23) at $686E: $9C80 and
; $9CA0 alternate with bit 1 of PassCounter while Willy stands on the floor (Y
; $D0), $9CC0 is used while his Y is $C0-$CF and $9CE0 when it is higher;
; drawing over Willy kills him. Entity definitions $46-$49 use all four in The
; Nightmare Room (room $1D).
SpriteFigure1:
  DEFB $03,$00
  DEFB $03,$C0
  DEFB $01,$E0
  DEFB $01,$40
  DEFB $01,$E0
  DEFB $07,$80
  DEFB $1F,$F8
  DEFB $3F,$FC
  DEFB $37,$6C
  DEFB $14,$98
  DEFB $0F,$F0
  DEFB $0F,$F0
  DEFB $0F,$F0
  DEFB $02,$40
  DEFB $06,$40
  DEFB $02,$60

; Sprite: hatted figure, frame 2
;
; One 16x16 sprite of 32 bytes: 16 pixel rows of 2 bytes (left byte, right
; byte; bit 7 = leftmost pixel), drawn with DrawSprite. Sprite 2 of the four
; figures with a pointed hat and a long dress (frame 6 of sprite page $9C;
; frames 0-1 of that page are the text leftovers at LeftoverSource).
; UpdateBedroom draws them in the Master Bedroom (room $23) at $686E: $9C80 and
; $9CA0 alternate with bit 1 of PassCounter while Willy stands on the floor (Y
; $D0), $9CC0 is used while his Y is $C0-$CF and $9CE0 when it is higher;
; drawing over Willy kills him. Entity definitions $46-$49 use all four in The
; Nightmare Room (room $1D).
SpriteFigure2:
  DEFB $03,$00
  DEFB $03,$C0
  DEFB $01,$E0
  DEFB $01,$40
  DEFB $01,$E0
  DEFB $07,$80
  DEFB $1F,$FC
  DEFB $3F,$FE
  DEFB $37,$66
  DEFB $14,$92
  DEFB $0F,$F0
  DEFB $0F,$F0
  DEFB $0F,$F0
  DEFB $02,$40
  DEFB $02,$40
  DEFB $06,$60

; Sprite: hatted figure, frame 3
;
; One 16x16 sprite of 32 bytes: 16 pixel rows of 2 bytes (left byte, right
; byte; bit 7 = leftmost pixel), drawn with DrawSprite. Sprite 3 of the four
; figures with a pointed hat and a long dress (frame 7 of sprite page $9C;
; frames 0-1 of that page are the text leftovers at LeftoverSource).
; UpdateBedroom draws them in the Master Bedroom (room $23) at $686E: $9C80 and
; $9CA0 alternate with bit 1 of PassCounter while Willy stands on the floor (Y
; $D0), $9CC0 is used while his Y is $C0-$CF and $9CE0 when it is higher;
; drawing over Willy kills him. Entity definitions $46-$49 use all four in The
; Nightmare Room (room $1D).
SpriteFigure3:
  DEFB $03,$00
  DEFB $03,$C0
  DEFB $01,$E0
  DEFB $01,$40
  DEFB $01,$E0
  DEFB $07,$80
  DEFB $1F,$FF
  DEFB $3F,$FE
  DEFB $37,$60
  DEFB $14,$90
  DEFB $0F,$F0
  DEFB $0F,$F0
  DEFB $0F,$F0
  DEFB $02,$40
  DEFB $02,$40
  DEFB $06,$60

; Sprite: Willy facing right, walk frame 0
;
; One 16x16 sprite of 32 bytes: 16 pixel rows of 2 bytes (left byte, right
; byte; bit 7 = leftmost pixel), drawn with DrawSprite. Willy walking to the
; right (observed: key P gives $85D0 = 2, bit 0 clear), walk frame 0. DrawWilly
; draws Willy from $9D00 + 128*(bit 0 of WillyMoveState) + 32*(WillyFrame AND
; 3); the lives indicator DrawLives shows frames 0-3 in turn (frame counter
; TuneStep).
SpriteWillyRight0:
  DEFB $3C,$00
  DEFB $3C,$00
  DEFB $7E,$00
  DEFB $34,$00
  DEFB $3E,$00
  DEFB $3C,$00
  DEFB $18,$00
  DEFB $3C,$00
  DEFB $7E,$00
  DEFB $7E,$00
  DEFB $F7,$00
  DEFB $FB,$00
  DEFB $3C,$00
  DEFB $76,$00
  DEFB $6E,$00
  DEFB $77,$00

; Sprite: Willy facing right, walk frame 1
;
; One 16x16 sprite of 32 bytes: 16 pixel rows of 2 bytes (left byte, right
; byte; bit 7 = leftmost pixel), drawn with DrawSprite. Willy walking to the
; right (observed: key P gives $85D0 = 2, bit 0 clear), walk frame 1. DrawWilly
; draws Willy from $9D00 + 128*(bit 0 of WillyMoveState) + 32*(WillyFrame AND
; 3); the lives indicator DrawLives shows frames 0-3 in turn (frame counter
; TuneStep).
SpriteWillyRight1:
  DEFB $0F,$00
  DEFB $0F,$00
  DEFB $1F,$80
  DEFB $0D,$00
  DEFB $0F,$80
  DEFB $0F,$00
  DEFB $06,$00
  DEFB $0F,$00
  DEFB $1B,$80
  DEFB $1B,$80
  DEFB $1B,$80
  DEFB $1D,$80
  DEFB $0F,$00
  DEFB $06,$00
  DEFB $06,$00
  DEFB $07,$00

; Sprite: Willy facing right, walk frame 2
;
; One 16x16 sprite of 32 bytes: 16 pixel rows of 2 bytes (left byte, right
; byte; bit 7 = leftmost pixel), drawn with DrawSprite. Willy walking to the
; right (observed: key P gives $85D0 = 2, bit 0 clear), walk frame 2. DrawWilly
; draws Willy from $9D00 + 128*(bit 0 of WillyMoveState) + 32*(WillyFrame AND
; 3); the lives indicator DrawLives shows frames 0-3 in turn (frame counter
; TuneStep); the game-over sequence ResumeAfterPause draws this frame at $488F
; as the figure that the foot falls on.
SpriteWillyRight2:
  DEFB $03,$C0
  DEFB $03,$C0
  DEFB $07,$E0
  DEFB $03,$40
  DEFB $03,$E0
  DEFB $03,$C0
  DEFB $01,$80
  DEFB $03,$C0
  DEFB $07,$E0
  DEFB $07,$E0
  DEFB $0F,$70
  DEFB $0F,$B0
  DEFB $03,$C0
  DEFB $07,$60
  DEFB $06,$E0
  DEFB $07,$70

; Sprite: Willy facing right, walk frame 3
;
; One 16x16 sprite of 32 bytes: 16 pixel rows of 2 bytes (left byte, right
; byte; bit 7 = leftmost pixel), drawn with DrawSprite. Willy walking to the
; right (observed: key P gives $85D0 = 2, bit 0 clear), walk frame 3. DrawWilly
; draws Willy from $9D00 + 128*(bit 0 of WillyMoveState) + 32*(WillyFrame AND
; 3); the lives indicator DrawLives shows frames 0-3 in turn (frame counter
; TuneStep).
SpriteWillyRight3:
  DEFB $00,$F0
  DEFB $00,$F0
  DEFB $01,$F8
  DEFB $00,$D0
  DEFB $00,$F8
  DEFB $00,$F0
  DEFB $00,$60
  DEFB $00,$F0
  DEFB $01,$F8
  DEFB $03,$FC
  DEFB $07,$FE
  DEFB $06,$F6
  DEFB $00,$F8
  DEFB $01,$DA
  DEFB $03,$0E
  DEFB $03,$8C

; Sprite: Willy facing left, walk frame 0
;
; One 16x16 sprite of 32 bytes: 16 pixel rows of 2 bytes (left byte, right
; byte; bit 7 = leftmost pixel), drawn with DrawSprite. Willy walking to the
; left (observed: key O gives $85D0 = 3, bit 0 set), walk frame 0. DrawWilly
; draws Willy from $9D00 + 128*(bit 0 of WillyMoveState) + 32*(WillyFrame AND
; 3). In The Nightmare Room (room $1D) DrawWilly uses page $B6 (SpritesFlapper)
; instead.
SpriteWillyLeft0:
  DEFB $0F,$00
  DEFB $0F,$00
  DEFB $1F,$80
  DEFB $0B,$00
  DEFB $1F,$00
  DEFB $0F,$00
  DEFB $06,$00
  DEFB $0F,$00
  DEFB $1F,$80
  DEFB $3F,$C0
  DEFB $7F,$E0
  DEFB $6F,$60
  DEFB $1F,$00
  DEFB $5B,$80
  DEFB $70,$C0
  DEFB $31,$C0

; Sprite: Willy facing left, walk frame 1
;
; One 16x16 sprite of 32 bytes: 16 pixel rows of 2 bytes (left byte, right
; byte; bit 7 = leftmost pixel), drawn with DrawSprite. Willy walking to the
; left (observed: key O gives $85D0 = 3, bit 0 set), walk frame 1. DrawWilly
; draws Willy from $9D00 + 128*(bit 0 of WillyMoveState) + 32*(WillyFrame AND
; 3). In The Nightmare Room (room $1D) DrawWilly uses page $B6 (SpritesFlapper)
; instead.
SpriteWillyLeft1:
  DEFB $03,$C0
  DEFB $03,$C0
  DEFB $07,$E0
  DEFB $02,$C0
  DEFB $07,$C0
  DEFB $03,$C0
  DEFB $01,$80
  DEFB $03,$C0
  DEFB $07,$E0
  DEFB $07,$E0
  DEFB $0E,$F0
  DEFB $0D,$F0
  DEFB $03,$C0
  DEFB $06,$E0
  DEFB $07,$60
  DEFB $0E,$E0

; Sprite: Willy facing left, walk frame 2
;
; One 16x16 sprite of 32 bytes: 16 pixel rows of 2 bytes (left byte, right
; byte; bit 7 = leftmost pixel), drawn with DrawSprite. Willy walking to the
; left (observed: key O gives $85D0 = 3, bit 0 set), walk frame 2. DrawWilly
; draws Willy from $9D00 + 128*(bit 0 of WillyMoveState) + 32*(WillyFrame AND
; 3). In The Nightmare Room (room $1D) DrawWilly uses page $B6 (SpritesFlapper)
; instead.
SpriteWillyLeft2:
  DEFB $00,$F0
  DEFB $00,$F0
  DEFB $01,$F8
  DEFB $00,$B0
  DEFB $01,$F0
  DEFB $00,$F0
  DEFB $00,$60
  DEFB $00,$F0
  DEFB $01,$D8
  DEFB $01,$D8
  DEFB $01,$D8
  DEFB $01,$B8
  DEFB $00,$F0
  DEFB $00,$60
  DEFB $00,$60
  DEFB $00,$E0

; Sprite: Willy facing left, walk frame 3
;
; One 16x16 sprite of 32 bytes: 16 pixel rows of 2 bytes (left byte, right
; byte; bit 7 = leftmost pixel), drawn with DrawSprite. Willy walking to the
; left (observed: key O gives $85D0 = 3, bit 0 set), walk frame 3. DrawWilly
; draws Willy from $9D00 + 128*(bit 0 of WillyMoveState) + 32*(WillyFrame AND
; 3). In The Nightmare Room (room $1D) DrawWilly uses page $B6 (SpritesFlapper)
; instead.
SpriteWillyLeft3:
  DEFB $00,$3C
  DEFB $00,$3C
  DEFB $00,$7E
  DEFB $00,$2C
  DEFB $00,$7C
  DEFB $00,$3C
  DEFB $00,$18
  DEFB $00,$3C
  DEFB $00,$7E
  DEFB $00,$7E
  DEFB $00,$EF
  DEFB $00,$DF
  DEFB $00,$3C
  DEFB $00,$6E
  DEFB $00,$76
  DEFB $00,$EE
