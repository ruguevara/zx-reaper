; Object type table: 12 pointers to the type records of the room items
;
; Indexed by the type number of a room item record (RoomItems, byte +3), 2
; bytes per type. MakeItemSlot reads the word at ObjectTypeTable + 2 x type and
; takes the 8-byte type record (ObjectTypeRecords) it points to. The types are:
; 0 heart, 1 cross taken while the wheel of faith of room 17 is at rest, 2
; cross taken while the wheel is turned, 3 checkpoint (gravestone cross), 4
; bell, 5 parchment, 6 the red scroll of room 24, 7 the church door trigger (no
; sprite), 8 arch between two rooms, 9 lever, 10 the wheel of faith of room 17,
; 11 the chalice.
;
; The table is not read for the room objects (enemies) of RoomObjects, which
; use the handler table at EntityHandlers.
ObjectTypeTable:
  DEFW ObjectTypeRecords  ; type 0: heart
  DEFW ObjectTypeRecords+$0008 ; type 1: cross (wheel at rest)
  DEFW ObjectTypeRecords+$10 ; type 2: cross (wheel turned)
  DEFW ObjectTypeRecords+$18 ; type 3: checkpoint
  DEFW ObjectTypeRecords+$20 ; type 4: bell
  DEFW ObjectTypeRecords+$28 ; type 5: parchment
  DEFW ObjectTypeRecords+$30 ; type 6: red scroll
  DEFW ObjectTypeRecords+$38 ; type 7: church door trigger
  DEFW ObjectTypeRecords+$40 ; type 8: arch
  DEFW ObjectTypeRecords+$48 ; type 9: lever
  DEFW ObjectTypeRecords+$50 ; type 10: wheel of faith
  DEFW ObjectTypeRecords+$58 ; type 11: chalice

; Object type records: 12 records of 8 bytes, one per type of room item
;
; Found through ObjectTypeTable by the item spawner MakeItemSlot, which copies
; the fields into the object slot (RunObjectSlots has the slot layout). Fields:
;
; +0 byte: frames between two animation steps (slot +8 and +9)
;
; +1 byte: number of animation frames (slot +$0B)
;
; +2 word: the slot's handler, RoomItemHandler (RoomItemHandler), or
; ParchmentHandler for parchments (slot +0)
;
; +4 word: frame list (FramesHeart), 4 bytes per frame (slot +$0C)
;
; +6 byte: sprite width in bytes (slot +$0E)
;
; +7 byte: sprite height in 2-pixel units (slot +$0F)
;
; Only the heart, the crosses and the arch step through their frames by
; themselves (delays of 20, 5 and 3 frames; 2, 6 and 9 frames each). The other
; types have a frame count of 0: their action routine chooses the frame from
; the item's flag (the checkpoint, bell, levers, wheel) or there is only one.
; The church door trigger (type 7) has no frame list: it draws nothing.
ObjectTypeRecords:
  DEFB $14,$02            ; type 0 heart: frame delay, number of frames
  DEFW RoomItemHandler    ; handler
  DEFW FramesHeart        ; frame list
  DEFB $02,$08            ; sprite width (bytes), height (2-pixel units)
  DEFB $05,$06            ; type 1 cross (wheel at rest): frame delay, number
                          ; of frames
  DEFW RoomItemHandler    ; handler
  DEFW FramesCross        ; frame list
  DEFB $02,$08            ; sprite width (bytes), height (2-pixel units)
  DEFB $05,$06            ; type 2 cross (wheel turned): frame delay, number of
                          ; frames
  DEFW RoomItemHandler    ; handler
  DEFW FramesCross        ; frame list
  DEFB $02,$08            ; sprite width (bytes), height (2-pixel units)
  DEFB $00,$00            ; type 3 checkpoint: frame delay, number of frames
  DEFW RoomItemHandler    ; handler
  DEFW FramesCheckpoint   ; frame list
  DEFB $02,$08            ; sprite width (bytes), height (2-pixel units)
  DEFB $00,$00            ; type 4 bell: frame delay, number of frames
  DEFW RoomItemHandler    ; handler
  DEFW FramesBell         ; frame list
  DEFB $02,$08            ; sprite width (bytes), height (2-pixel units)
  DEFB $00,$00            ; type 5 parchment: frame delay, number of frames
  DEFW ParchmentHandler   ; handler
  DEFW FramesScroll       ; frame list
  DEFB $02,$08            ; sprite width (bytes), height (2-pixel units)
  DEFB $00,$00            ; type 6 red scroll: frame delay, number of frames
  DEFW RoomItemHandler    ; handler
  DEFW FramesRedScroll    ; frame list
  DEFB $02,$08            ; sprite width (bytes), height (2-pixel units)
  DEFB $01,$00            ; type 7 church door trigger: frame delay, number of
                          ; frames
  DEFW RoomItemHandler    ; handler
  DEFW $0000              ; frame list
  DEFB $00,$00            ; sprite width (bytes), height (2-pixel units)
  DEFB $03,$09            ; type 8 arch: frame delay, number of frames
  DEFW RoomItemHandler    ; handler
  DEFW FramesArch         ; frame list
  DEFB $02,$0C            ; sprite width (bytes), height (2-pixel units)
  DEFB $00,$00            ; type 9 lever: frame delay, number of frames
  DEFW RoomItemHandler    ; handler
  DEFW FramesLever        ; frame list
  DEFB $02,$08            ; sprite width (bytes), height (2-pixel units)
  DEFB $00,$00            ; type 10 wheel of faith: frame delay, number of
                          ; frames
  DEFW RoomItemHandler    ; handler
  DEFW FramesWheel        ; frame list
  DEFB $02,$08            ; sprite width (bytes), height (2-pixel units)
  DEFB $00,$00            ; type 11 chalice: frame delay, number of frames
  DEFW RoomItemHandler    ; handler
  DEFW FramesChalice      ; frame list
  DEFB $02,$08            ; sprite width (bytes), height (2-pixel units)

; Frame lists of the room items: 34 frames of 4 bytes
;
; Each frame: +0 word: graphics address of a 16 x 16 pixel sprite (32 bytes, in
; the sprite block at SpriteArch), +2 byte: attribute, +3 byte: 0 (unused: it
; is popped as the flags of the sprite command). The type records
; (ObjectTypeRecords) point into this table; the item's current frame number
; (slot +$0A) is an index in its list, read by DrawItemFrame (DrawItemFrame).
; The lists:
;
; FramesHeart (2 frames), FramesCross (12: 6 bright crosses in the colours of
; CrossColours, then 6 thin ones, the plus sign sprite), FramesCheckpoint (2:
; not active, active), FramesArch (9, all the arch with changing ink),
; FramesScroll (1: the parchment), FramesRedScroll (1: the same sprite in red,
; attribute $42), FramesBell (2: at rest, ringing), FramesLever (2: up,
; pulled), FramesWheel (2) and FramesChalice (1).
FramesHeart:
  DEFW SpriteHeart0
  DEFB $02,$00
  DEFW SpriteHeart1
  DEFB $02,$00
FramesCross:
  DEFW SpriteCross
  DEFB $46,$00
  DEFW SpriteCross
  DEFB $42,$00
  DEFW SpriteCross
  DEFB $43,$00
  DEFW SpriteCross
  DEFB $41,$00
  DEFW SpriteCross
  DEFB $45,$00
  DEFW SpriteCross
  DEFB $44,$00
  DEFW SpritePlus
  DEFB $06,$00
  DEFW SpritePlus
  DEFB $02,$00
  DEFW SpritePlus
  DEFB $03,$00
  DEFW SpritePlus
  DEFB $01,$00
  DEFW SpritePlus
  DEFB $05,$00
  DEFW SpritePlus
  DEFB $04,$00
FramesCheckpoint:
  DEFW SpriteCheckpoint0
  DEFB $07,$00
  DEFW SpriteCheckpoint1
  DEFB $07,$00
FramesArch:
  DEFW SpriteArch
  DEFB $01,$00
  DEFW SpriteArch
  DEFB $01,$00
  DEFW SpriteArch
  DEFB $02,$00
  DEFW SpriteArch
  DEFB $03,$00
  DEFW SpriteArch
  DEFB $02,$00
  DEFW SpriteArch
  DEFB $03,$00
  DEFW SpriteArch
  DEFB $02,$00
  DEFW SpriteArch
  DEFB $01,$00
  DEFW SpriteArch
  DEFB $01,$00
FramesScroll:
  DEFW SpriteScroll
  DEFB $46,$00
FramesRedScroll:
  DEFW SpriteScroll
  DEFB $42,$00
FramesBell:
  DEFW SpriteBell0
  DEFB $46,$00
  DEFW SpriteBell1
  DEFB $06,$00
FramesLever:
  DEFW SpriteLever0
  DEFB $46,$00
  DEFW SpriteLever1
  DEFB $06,$00
FramesWheel:
  DEFW SpriteWheel0
  DEFB $47,$00
  DEFW SpriteWheel1
  DEFB $07,$00
FramesChalice:
  DEFW SpriteChalice
  DEFB $46,$00

; Room objects: 77 records of 11 bytes, the enemies and moving things of each
; room
;
; Read by the spawner SpawnRoomObjects when a room is entered: it scans the
; table from the start, calls SpawnRoomObject for every record whose room (+0)
; is the current room and stops at the room byte $1A (the end mark at 8EDE,
; which is also the value in $850A, so room and end mark are compared as a word
; with $8509). The records of one room are not sorted. Record:
;
; +0 byte: room number
;
; +1 byte: kind, the index of the handler word in the table at EntityHandlers
; (0-17; the kinds are listed below); the handler goes to slot +0 and may
; change itself while it runs (kind 2 and 3, 4 and 5, 6 and 7 are the two
; directions of one patrol)
;
; +2 byte: speed, times 4 it becomes the speed word of the slot (+2, 8.8 fixed
; point, 2-pixel units per frame)
;
; +3 byte: frames between two animation steps or other timer (slot +$12 counts
; down, +$13 reloads); for the crusader spawner (kind 1) it is the delay before
; the first crusader, then a new one comes every $28 frames (observed in room
; 5: the first at about frame 90, then one per 40, F118)
;
; +4 byte: x position in 2-pixel units (high byte of the slot's x word at
; +6/+7)
;
; +5 byte: y position in 2-pixel units (high byte of the slot's y word at
; +8/+9)
;
; +6 byte: initial animation state (slot +$0A and +$0B)
;
; +7 byte: slot +4: lower limit of the patrol (x for kinds 2 and 3, y for kinds
; 4-7); the countdown of the timer kinds (13-15); low byte of the entity
; template address for kind 1
;
; +8 byte: slot +5: upper limit of the patrol; the reload of the countdown
; (kinds 13-15); high byte of the template address for kind 1; the x position
; where a runner of kind 0 ends ($80)
;
; +9 word: behaviour block (BehaviourJean to BehaviourSatan) that tells how the
; kind looks and how large its hit box is
;
; Kinds (what was seen on the screen after warping to the room, and the titles
; of the handlers): 0 the runners of the intro in room 0 (Jean and three
; crusaders crossing the screen); 1 spawns a running crusader every 40 frames
; (rooms 5, 6 and 25, where crusaders chase Jean in from the left edge); 2 and
; 3 patrol horizontally (rats, bats, skeletons, soldiers, worms, birds, demons:
; the behaviour block tells which sprite); 4 and 5 patrol vertically (spiders
; on a thread, flies, fire wheels); 6 and 7 the hanged men of room 9 (bob on
; their ropes; no record starts as kind 7); 8 the grinning ghost of room 11
; that chases Jean; 9 the water drops of rooms 15 and 19; 10 skeleton archers;
; 11 the stone heads in the wall of rooms 20 and 22 that shoot arrows; 12
; the spitting plants of room 14; 13 the fish of rooms 16 and 19 that jump out
; of the water; 14 the head of the Pestilent Beast; 15 the fire breath of the
; Beast (room 10; its timer is 110 frames); 16 Death of room 18; 17 Satan of
; room 24.
;
; Positions are in 2-pixel units (0-127 across, 0-87 down). The lists below
; give per record: room, kind, creature, start x and y, and the patrol limits.
RoomObjects:
  DEFB $00,$00,$20,$08,$F7,$30,$00,$00,$80 ; room 0: Jean walker, x $F7 y $30,
                                           ; ends at x $80
  DEFW BehaviourJean
  DEFB $00,$00,$18,$08,$E3,$30,$00,$00,$80 ; room 0: crusader walker, x $E3 y
                                           ; $30, ends at x $80
  DEFW BehaviourCrusader
  DEFB $00,$00,$18,$08,$D7,$30,$00,$00,$80 ; room 0: crusader walker, x $D7 y
                                           ; $30, ends at x $80
  DEFW BehaviourCrusader
  DEFB $00,$00,$18,$08,$CB,$30,$00,$00,$80 ; room 0: crusader walker, x $CB y
                                           ; $30, ends at x $80
  DEFW BehaviourCrusader
  DEFB $05,$01,$00,$5A,$00,$00,$00,low CrusaderTemplateRoom5,high CrusaderTemplateRoom5 ; room 5:
                                                                                        ; crusader
                                                                                        ; spawner,
                                                                                        ; template
                                                                                        ; $B04C,
                                                                                        ; first
                                                                                        ; after 90
                                                                                        ; frames
  DEFW BehaviourCrusader
  DEFB $06,$01,$00,$5A,$00,$00,$00,low CrusaderTemplateRoom6,high CrusaderTemplateRoom6 ; room 6:
                                                                                        ; crusader
                                                                                        ; spawner,
                                                                                        ; template
                                                                                        ; $B062,
                                                                                        ; first
                                                                                        ; after 90
                                                                                        ; frames
  DEFW BehaviourCrusader
  DEFB $19,$01,$00,$5A,$00,$00,$00,low CrusaderTemplateRoom25,high CrusaderTemplateRoom25 ; room 25:
                                                                                          ; crusader
                                                                                          ; spawner,
                                                                                          ; template
                                                                                          ; $B078,
                                                                                          ; first
                                                                                          ; after 90
                                                                                          ; frames
  DEFW BehaviourCrusader
  DEFB $08,$02,$20,$07,$48,$18,$00,$10,$50 ; room 8: bat (patroller, starts
                                           ; left), x $48 y $18, x limits
                                           ; $10-$50
  DEFW BehaviourBat
  DEFB $08,$03,$10,$07,$2C,$2C,$00,$28,$70 ; room 8: bat (patroller, starts
                                           ; right), x $2C y $2C, x limits
                                           ; $28-$70
  DEFW BehaviourBat
  DEFB $02,$02,$20,$08,$6C,$48,$00,$20,$6C ; room 2: rat (patroller, starts
                                           ; left), x $6C y $48, x limits
                                           ; $20-$6C
  DEFW BehaviourRat
  DEFB $02,$03,$20,$08,$20,$48,$00,$20,$6C ; room 2: rat (patroller, starts
                                           ; right), x $20 y $48, x limits
                                           ; $20-$6C
  DEFW BehaviourRat
  DEFB $03,$04,$20,$04,$10,$3E,$00,$2E,$42 ; room 3: spider (vertical
                                           ; patroller, starts down), x $10 y
                                           ; $3E, y limits $2E-$42
  DEFW BehaviourSpider
  DEFB $03,$05,$28,$04,$20,$46,$00,$36,$4A ; room 3: yellow spider (vertical
                                           ; patroller, starts up), x $20 y
                                           ; $46, y limits $36-$4A
  DEFW BehaviourSpiderYellow
  DEFB $03,$04,$2A,$04,$28,$36,$00,$2E,$3E ; room 3: spider (vertical
                                           ; patroller, starts down), x $28 y
                                           ; $36, y limits $2E-$3E
  DEFW BehaviourSpider
  DEFB $03,$05,$10,$04,$60,$3E,$00,$3E,$4A ; room 3: yellow spider (vertical
                                           ; patroller, starts up), x $60 y
                                           ; $3E, y limits $3E-$4A
  DEFW BehaviourSpiderYellow
  DEFB $0E,$04,$20,$04,$18,$0E,$00,$06,$1E ; room 14: spider (vertical
                                           ; patroller, starts down), x $18 y
                                           ; $0E, y limits $06-$1E
  DEFW BehaviourSpider
  DEFB $10,$04,$18,$04,$48,$0E,$00,$06,$1E ; room 16: spider (vertical
                                           ; patroller, starts down), x $48 y
                                           ; $0E, y limits $06-$1E
  DEFW BehaviourSpider
  DEFB $13,$04,$18,$04,$2C,$1A,$00,$06,$2A ; room 19: spider (vertical
                                           ; patroller, starts down), x $2C y
                                           ; $1A, y limits $06-$2A
  DEFW BehaviourSpider
  DEFB $09,$06,$20,$00,$18,$1C,$00,$24,$3C ; room 9: hanged man (hanged man,
                                           ; starts down), x $18 y $1C, y
                                           ; limits $24-$3C
  DEFW BehaviourHangedMan
  DEFB $09,$06,$20,$00,$24,$24,$00,$2C,$40 ; room 9: hanged man (hanged man,
                                           ; starts down), x $24 y $24, y
                                           ; limits $2C-$40
  DEFW BehaviourHangedMan
  DEFB $09,$06,$20,$00,$4C,$2C,$00,$34,$40 ; room 9: hanged man (hanged man,
                                           ; starts down), x $4C y $2C, y
                                           ; limits $34-$40
  DEFW BehaviourHangedMan
  DEFB $09,$06,$20,$00,$58,$20,$00,$28,$3C ; room 9: hanged man (hanged man,
                                           ; starts down), x $58 y $20, y
                                           ; limits $28-$3C
  DEFW BehaviourHangedMan
  DEFB $09,$02,$10,$05,$4C,$1A,$00,$48,$58 ; room 9: worm (patroller, starts
                                           ; left), x $4C y $1A, x limits
                                           ; $48-$58
  DEFW BehaviourWorm
  DEFB $09,$02,$10,$05,$44,$4E,$00,$28,$48 ; room 9: worm (patroller, starts
                                           ; left), x $44 y $4E, x limits
                                           ; $28-$48
  DEFW BehaviourWorm
  DEFB $0E,$02,$10,$05,$54,$4E,$00,$18,$58 ; room 14: worm (patroller, starts
                                           ; left), x $54 y $4E, x limits
                                           ; $18-$58
  DEFW BehaviourWorm
  DEFB $0C,$05,$40,$03,$10,$38,$00,$15,$48 ; room 12: fly (vertical patroller,
                                           ; starts up), x $10 y $38, y limits
                                           ; $15-$48
  DEFW BehaviourFlyA
  DEFB $0C,$05,$18,$03,$18,$0C,$00,$05,$20 ; room 12: fly (vertical patroller,
                                           ; starts up), x $18 y $0C, y limits
                                           ; $05-$20
  DEFW BehaviourFlyB
  DEFB $0C,$05,$18,$03,$40,$40,$00,$39,$48 ; room 12: fly (vertical patroller,
                                           ; starts up), x $40 y $40, y limits
                                           ; $39-$48
  DEFW BehaviourFlyB
  DEFB $0C,$05,$40,$03,$50,$14,$00,$05,$48 ; room 12: fly (vertical patroller,
                                           ; starts up), x $50 y $14, y limits
                                           ; $05-$48
  DEFW BehaviourFlyA
  DEFB $0C,$05,$30,$03,$58,$40,$00,$05,$48 ; room 12: fly (vertical patroller,
                                           ; starts up), x $58 y $40, y limits
                                           ; $05-$48
  DEFW BehaviourFlyA
  DEFB $0B,$08,$10,$08,$40,$24,$00,$00,$1E ; room 11: chaser (ghost), x $40 y
                                           ; $24, params $00 $00 $1E
  DEFW BehaviourChaser
  DEFB $0D,$02,$20,$08,$2C,$2C,$00,$28,$60 ; room 13: skeleton (patroller,
                                           ; starts left), x $2C y $2C, x
                                           ; limits $28-$60
  DEFW BehaviourSkeleton
  DEFB $0D,$02,$20,$08,$40,$44,$00,$1C,$48 ; room 13: skeleton (patroller,
                                           ; starts left), x $40 y $44, x
                                           ; limits $1C-$48
  DEFW BehaviourSkeleton
  DEFB $16,$02,$20,$08,$48,$20,$00,$3C,$4C ; room 22: skeleton (patroller,
                                           ; starts left), x $48 y $20, x
                                           ; limits $3C-$4C
  DEFW BehaviourSkeleton
  DEFB $16,$02,$20,$08,$20,$04,$00,$08,$38 ; room 22: white flyer (patroller,
                                           ; starts left), x $20 y $04, x
                                           ; limits $08-$38
  DEFW BehaviourWhiteFlyer
  DEFB $17,$02,$20,$08,$50,$04,$00,$08,$70 ; room 23: white flyer (patroller,
                                           ; starts left), x $50 y $04, x
                                           ; limits $08-$70
  DEFW BehaviourWhiteFlyer
  DEFB $14,$02,$20,$04,$12,$2C,$00,$10,$68 ; room 20: bird (patroller, starts
                                           ; left), x $12 y $2C, x limits
                                           ; $10-$68
  DEFW BehaviourBird
  DEFB $17,$02,$30,$04,$34,$10,$00,$08,$6C ; room 23: bird (patroller, starts
                                           ; left), x $34 y $10, x limits
                                           ; $08-$6C
  DEFW BehaviourBird
  DEFB $17,$02,$20,$04,$64,$34,$00,$08,$6C ; room 23: bird (patroller, starts
                                           ; left), x $64 y $34, x limits
                                           ; $08-$6C
  DEFW BehaviourBird
  DEFB $0F,$09,$40,$46,$10,$2C,$3D,$2C,$3C ; room 15: water drop (drop), x $10
                                           ; y $2C, params $3D $2C $3C
  DEFW BehaviourDrop
  DEFB $0F,$09,$40,$46,$2C,$10,$29,$10,$24 ; room 15: water drop (drop), x $2C
                                           ; y $10, params $29 $10 $24
  DEFW BehaviourDrop
  DEFB $0F,$09,$40,$46,$2C,$2C,$15,$2C,$3C ; room 15: water drop (drop), x $2C
                                           ; y $2C, params $15 $2C $3C
  DEFW BehaviourDrop
  DEFB $0F,$09,$40,$46,$60,$10,$33,$10,$34 ; room 15: water drop (drop), x $60
                                           ; y $10, params $33 $10 $34
  DEFW BehaviourDrop
  DEFB $0F,$09,$40,$46,$68,$10,$0B,$10,$44 ; room 15: water drop (drop), x $68
                                           ; y $10, params $0B $10 $44
  DEFW BehaviourDrop
  DEFB $13,$09,$40,$46,$18,$04,$15,$04,$14 ; room 19: water drop (drop), x $18
                                           ; y $04, params $15 $04 $14
  DEFW BehaviourDrop
  DEFB $13,$09,$40,$46,$40,$04,$3D,$04,$1C ; room 19: water drop (drop), x $40
                                           ; y $04, params $3D $04 $1C
  DEFW BehaviourDrop
  DEFB $0F,$02,$10,$08,$28,$1C,$00,$26,$3B ; room 15: soldier (patroller,
                                           ; starts left), x $28 y $1C, x
                                           ; limits $26-$3B
  DEFW BehaviourSoldier
  DEFB $0F,$02,$10,$08,$60,$44,$00,$40,$60 ; room 15: soldier (patroller,
                                           ; starts left), x $60 y $44, x
                                           ; limits $40-$60
  DEFW BehaviourSoldier
  DEFB $14,$02,$10,$08,$44,$44,$00,$28,$48 ; room 20: soldier (patroller,
                                           ; starts left), x $44 y $44, x
                                           ; limits $28-$48
  DEFW BehaviourSoldier
  DEFB $11,$0A,$00,$50,$08,$0C,$00,$00,$00 ; room 17: archer (skeleton archer),
                                           ; x $08 y $0C
  DEFW BehaviourArcher
  DEFB $11,$0A,$00,$50,$70,$24,$00,$00,$00 ; room 17: archer (skeleton archer),
                                           ; x $70 y $24
  DEFW BehaviourArcher
  DEFB $11,$0A,$00,$50,$3C,$34,$00,$00,$00 ; room 17: archer (skeleton archer),
                                           ; x $3C y $34
  DEFW BehaviourArcher
  DEFB $15,$0A,$00,$50,$60,$3C,$00,$00,$00 ; room 21: archer (skeleton archer),
                                           ; x $60 y $3C
  DEFW BehaviourArcher
  DEFB $14,$0B,$00,$46,$6C,$0C,$00,$00,$00 ; room 20: stone head in the wall, x
                                           ; $6C y $0C
  DEFW BehaviourStoneHead
  DEFB $16,$0B,$00,$46,$70,$34,$00,$00,$00 ; room 22: stone head in the wall, x
                                           ; $70 y $34
  DEFW BehaviourStoneHead
  DEFB $0E,$0C,$00,$94,$44,$10,$78,$00,$00 ; room 14: seed-spitting plant, x
                                           ; $44 y $10, timer $94
  DEFW BehaviourSeedPlant
  DEFB $0E,$0C,$00,$B0,$70,$18,$78,$00,$00 ; room 14: seed-spitting plant, x
                                           ; $70 y $18, timer $B0
  DEFW BehaviourSeedPlant
  DEFB $0E,$0C,$00,$78,$38,$38,$78,$00,$00 ; room 14: seed-spitting plant, x
                                           ; $38 y $38, timer $78
  DEFW BehaviourSeedPlant
  DEFB $13,$0D,$00,$04,$48,$4C,$3B,$54,$54 ; room 19: fish (fish), x $48 y $4C
  DEFW BehaviourFish
  DEFB $13,$0D,$00,$04,$60,$4C,$3B,$7C,$54 ; room 19: fish (fish), x $60 y $4C
  DEFW BehaviourFish
  DEFB $10,$0D,$00,$04,$1C,$4C,$3B,$54,$54 ; room 16: fish (fish), x $1C y $4C
  DEFW BehaviourFish
  DEFB $10,$0D,$00,$04,$3C,$4C,$3B,$7C,$54 ; room 16: fish (fish), x $3C y $4C
  DEFW BehaviourFish
  DEFB $10,$0D,$00,$04,$50,$4C,$3B,$68,$54 ; room 16: fish (fish), x $50 y $4C
  DEFW BehaviourFish
  DEFB $15,$02,$20,$08,$2D,$14,$00,$08,$30 ; room 21: demon (patroller, starts
                                           ; left), x $2D y $14, x limits
                                           ; $08-$30
  DEFW BehaviourDemon
  DEFB $15,$02,$20,$08,$09,$44,$00,$08,$40 ; room 21: demon (patroller, starts
                                           ; left), x $09 y $44, x limits
                                           ; $08-$40
  DEFW BehaviourDemon
  DEFB $15,$03,$20,$08,$3F,$44,$00,$08,$40 ; room 21: demon (patroller, starts
                                           ; right), x $3F y $44, x limits
                                           ; $08-$40
  DEFW BehaviourDemon
  DEFB $16,$02,$20,$08,$68,$20,$00,$60,$70 ; room 22: demon (patroller, starts
                                           ; left), x $68 y $20, x limits
                                           ; $60-$70
  DEFW BehaviourDemon
  DEFB $16,$04,$60,$04,$28,$46,$00,$1A,$62 ; room 22: fire wheel (vertical
                                           ; patroller, starts down), x $28 y
                                           ; $46, y limits $1A-$62
  DEFW BehaviourFireWheel
  DEFB $16,$04,$40,$04,$30,$4E,$00,$1A,$62 ; room 22: fire wheel (vertical
                                           ; patroller, starts down), x $30 y
                                           ; $4E, y limits $1A-$62
  DEFW BehaviourFireWheel
  DEFB $16,$04,$40,$04,$4C,$32,$00,$32,$62 ; room 22: fire wheel (vertical
                                           ; patroller, starts down), x $4C y
                                           ; $32, y limits $32-$62
  DEFW BehaviourFireWheel
  DEFB $17,$04,$40,$04,$18,$0A,$00,$06,$62 ; room 23: fire wheel (vertical
                                           ; patroller, starts down), x $18 y
                                           ; $0A, y limits $06-$62
  DEFW BehaviourFireWheel
  DEFB $17,$04,$40,$04,$28,$2A,$00,$06,$62 ; room 23: fire wheel (vertical
                                           ; patroller, starts down), x $28 y
                                           ; $2A, y limits $06-$62
  DEFW BehaviourFireWheel
  DEFB $17,$04,$40,$04,$50,$22,$00,$06,$62 ; room 23: fire wheel (vertical
                                           ; patroller, starts down), x $50 y
                                           ; $22, y limits $06-$62
  DEFW BehaviourFireWheel
  DEFB $0A,$0E,$00,$6E,$3C,$04,$00,$00,$00 ; room 10: beast head (beast head),
                                           ; x $3C y $04
  DEFW BehaviourBeastHead
  DEFB $0A,$0F,$03,$02,$40,$18,$48,$6E,$6E ; room 10: fire breath (fire
                                           ; breath), x $40 y $18
  DEFW BehaviourBeastFire
  DEFB $12,$10,$20,$05,$09,$04,$28,$08,$68 ; room 18: Death (Death), x $09 y
                                           ; $04
  DEFW BehaviourDeath
  DEFB $18,$11,$20,$06,$60,$27,$96,$05,$28 ; room 24: Satan (Satan), x $60 y
                                           ; $27
  DEFW BehaviourSatan
  DEFB $1A

; Room items: 45 records of 8 bytes, the things Jean can touch (hearts,
; crosses, checkpoints, levers, parchments...)
;
; Read by SpawnRoomItems when a room is entered: for every record of the
; current room SpawnItem makes an object slot through MakeItemSlot, unless the
; item's flag byte is $FF (the item was taken or is finished). The table ends
; with the room byte $1A. Record:
;
; +0 byte: room number
;
; +1 word: address of the item's flag byte in the variables at
; BellRung-CheckpointFlag8 (copied to slot +6/+7); every item has its own flag,
; whose meaning depends on the type (taken, pulled, active checkpoint...) and
; which survives leaving the room
;
; +3 byte: type, the index in ObjectTypeTable (0-11)
;
; +4 byte: row of the top-left cell of the 16 x 16 pixel sprite (0-21)
;
; +5 byte: column of the top-left cell (0-31)
;
; +6 word: the action routine that the handler RoomItemHandler enters when it
; has tested whether Jean touches the item (slot +4). For parchments (type 5,
; handler ParchmentHandler) the word is not an address: the low byte is the
; number of the first text line and the high byte that of the second line
; (strings 25-36 of ParchmentTexts), which ActionParchment copies to
; ParchmentLine1.
;
; Positions are in character cells. The lists give room, what it is, row and
; column, and the flag.
RoomItems:
  DEFB $02                ; room 2: bell, row 1 column 5, flag $851B
  DEFW BellRung
  DEFB $04,$01,$05,low ActionBellOrLever,high ActionBellOrLever
  DEFB $09                ; room 9: lever, row 18 column 27, flag $851C
  DEFW LeverRoom9
  DEFB $09,$12,$1B,low ActionBellOrLever,high ActionBellOrLever
  DEFB $0A                ; room 10: lever, row 4 column 7, flag $851D
  DEFW LeverRoom10
  DEFB $09,$04,$07,low ActionBellOrLever,high ActionBellOrLever
  DEFB $11                ; room 17: wheel of faith, row 2 column 15, flag
                          ; $851E
  DEFW WheelState
  DEFB $0A,$02,$0F,low ActionWheel,high ActionWheel
  DEFB $14                ; room 20: lever, row 6 column 24, flag $851F
  DEFW LeverRoom20
  DEFB $09,$06,$18,low ActionGateLever,high ActionGateLever
  DEFB $18                ; room 24: chalice, row 2 column 16, flag $8521
  DEFW ChaliceTaken
  DEFB $0B,$02,$10,low ActionChalice,high ActionChalice
  DEFB $0A                ; room 10: arch, row 17 column 23, flag $8523
  DEFW DoorwayRoom10
  DEFB $08,$11,$17,low ActionArchToRiver,high ActionArchToRiver
  DEFB $13                ; room 19: arch, row 15 column 21, flag $8524
  DEFW DoorwayRoom19
  DEFB $08,$0F,$15,low ActionArchToBeast,high ActionArchToBeast
  DEFB $02                ; room 2: heart, row 7 column 12, flag $8525
  DEFW HeartRoom2
  DEFB $00,$07,$0C,low ActionHeart,high ActionHeart
  DEFB $0A                ; room 10: heart, row 18 column 10, flag $8526
  DEFW HeartRoom10
  DEFB $00,$12,$0A,low ActionHeart,high ActionHeart
  DEFB $0B                ; room 11: heart, row 4 column 2, flag $8527
  DEFW HeartRoom11
  DEFB $00,$04,$02,low ActionHeart,high ActionHeart
  DEFB $0C                ; room 12: heart, row 6 column 16, flag $8528
  DEFW HeartRoom12
  DEFB $00,$06,$10,low ActionHeart,high ActionHeart
  DEFB $0F                ; room 15: heart, row 14 column 3, flag $8529
  DEFW HeartRoom15
  DEFB $00,$0E,$03,low ActionHeart,high ActionHeart
  DEFB $11                ; room 17: heart, row 18 column 3, flag $852A
  DEFW HeartRoom17
  DEFB $00,$12,$03,low ActionHeart,high ActionHeart
  DEFB $12                ; room 18: heart, row 11 column 15, flag $852B
  DEFW HeartRoom18
  DEFB $00,$0B,$0F,low ActionHeart,high ActionHeart
  DEFB $13                ; room 19: heart, row 8 column 25, flag $852C
  DEFW HeartRoom19
  DEFB $00,$08,$19,low ActionHeart,high ActionHeart
  DEFB $17                ; room 23: heart, row 7 column 23, flag $852D
  DEFW HeartRoom23
  DEFB $00,$07,$17,low ActionHeart,high ActionHeart
  DEFB $03                ; room 3: parchment, row 16 column 18, flag $852E,
                          ; text lines 25 and 26
  DEFW ParchmentRoom3
  DEFB $05,$10,$12,$19,$1A
  DEFB $08                ; room 8: parchment, row 18 column 27, flag $852F,
                          ; text lines 27 and 28
  DEFW ParchmentRoom8
  DEFB $05,$12,$1B,$1B,$1C
  DEFB $0C                ; room 12: parchment, row 18 column 10, flag $8530,
                          ; text lines 29 and 30
  DEFW ParchmentRoom12
  DEFB $05,$12,$0A,$1D,$1E
  DEFB $0E                ; room 14: parchment, row 10 column 19, flag $8531,
                          ; text lines 31 and 32
  DEFW ParchmentRoom14
  DEFB $05,$0A,$13,$1F,$20
  DEFB $10                ; room 16: parchment, row 5 column 22, flag $8532,
                          ; text lines 33 and 34
  DEFW ParchmentRoom16
  DEFB $05,$05,$16,$21,$22
  DEFB $15                ; room 21: parchment, row 6 column 3, flag $8533,
                          ; text lines 35 and 36
  DEFW ParchmentRoom21
  DEFB $05,$06,$03,$23,$24
  DEFB $18                ; room 24: red scroll, row 14 column 28, flag $8534
  DEFW RedScrollTaken
  DEFB $06,$0E,$1C,low ActionFinalScroll,high ActionFinalScroll
  DEFB $03                ; room 3: cross (wheel at rest), row 18 column 28,
                          ; flag $8535
  DEFW CrossRoom3
  DEFB $01,$12,$1C,low ActionCrossWheelRest,high ActionCrossWheelRest
  DEFB $09                ; room 9: cross (wheel turned), row 4 column 6, flag
                          ; $8536
  DEFW WheelCrossRoom9
  DEFB $02,$04,$06,low ActionCrossWheelTurned,high ActionCrossWheelTurned
  DEFB $0A                ; room 10: cross (wheel at rest), row 4 column 26,
                          ; flag $8537
  DEFW CrossRoom10
  DEFB $01,$04,$1A,low ActionCrossWheelRest,high ActionCrossWheelRest
  DEFB $0D                ; room 13: cross (wheel at rest), row 18 column 18,
                          ; flag $8538
  DEFW CrossRoom13
  DEFB $01,$12,$12,low ActionCrossWheelRest,high ActionCrossWheelRest
  DEFB $0E                ; room 14: cross (wheel at rest), row 4 column 9,
                          ; flag $8539
  DEFW CrossRoom14
  DEFB $01,$04,$09,low ActionCrossWheelRest,high ActionCrossWheelRest
  DEFB $0F                ; room 15: cross (wheel turned), row 8 column 28,
                          ; flag $853A
  DEFW WheelCrossRoom15
  DEFB $02,$08,$1C,low ActionCrossWheelTurned,high ActionCrossWheelTurned
  DEFB $10                ; room 16: cross (wheel at rest), row 6 column 2,
                          ; flag $853B
  DEFW CrossRoom16
  DEFB $01,$06,$02,low ActionCrossWheelRest,high ActionCrossWheelRest
  DEFB $11                ; room 17: cross (wheel at rest), row 18 column 28,
                          ; flag $853C
  DEFW CrossRoom17
  DEFB $01,$12,$1C,low ActionCrossWheelRest,high ActionCrossWheelRest
  DEFB $11                ; room 17: cross (wheel turned), row 10 column 3,
                          ; flag $853D
  DEFW WheelCrossRoom17
  DEFB $02,$0A,$03,low ActionCrossWheelTurned,high ActionCrossWheelTurned
  DEFB $12                ; room 18: cross (wheel at rest), row 5 column 3,
                          ; flag $853E
  DEFW CrossRoom18
  DEFB $01,$05,$03,low ActionCrossWheelRest,high ActionCrossWheelRest
  DEFB $13                ; room 19: cross (wheel at rest), row 2 column 3,
                          ; flag $853F
  DEFW CrossRoom19
  DEFB $01,$02,$03,low ActionCrossWheelRest,high ActionCrossWheelRest
  DEFB $16                ; room 22: cross (wheel turned), row 18 column 27,
                          ; flag $8540
  DEFW WheelCrossRoom22
  DEFB $02,$12,$1B,low ActionCrossWheelTurned,high ActionCrossWheelTurned
  DEFB $07                ; room 7: church door trigger, row 15 column 2, flag
                          ; $8543
  DEFW CheckpointFlag0
  DEFB $07,$0F,$02,low ActionChurchDoor,high ActionChurchDoor
  DEFB $08                ; room 8: checkpoint, row 17 column 7, flag $8544
  DEFW CheckpointFlag1
  DEFB $03,$11,$07,low ActionCheckpoint,high ActionCheckpoint
  DEFB $0B                ; room 11: checkpoint, row 17 column 14, flag $8545
  DEFW CheckpointFlag2
  DEFB $03,$11,$0E,low ActionCheckpoint,high ActionCheckpoint
  DEFB $0C                ; room 12: checkpoint, row 7 column 8, flag $8546
  DEFW CheckpointFlag3
  DEFB $03,$07,$08,low ActionCheckpoint,high ActionCheckpoint
  DEFB $0E                ; room 14: checkpoint, row 17 column 8, flag $8547
  DEFW CheckpointFlag4
  DEFB $03,$11,$08,low ActionCheckpoint,high ActionCheckpoint
  DEFB $0F                ; room 15: checkpoint, row 7 column 21, flag $8548
  DEFW CheckpointFlag5
  DEFB $03,$07,$15,low ActionCheckpoint,high ActionCheckpoint
  DEFB $13                ; room 19: checkpoint, row 11 column 8, flag $8549
  DEFW CheckpointFlag6
  DEFB $03,$0B,$08,low ActionCheckpoint,high ActionCheckpoint
  DEFB $15                ; room 21: checkpoint, row 5 column 19, flag $854A
  DEFW CheckpointFlag7
  DEFB $03,$05,$13,low ActionCheckpoint,high ActionCheckpoint
  DEFB $17                ; room 23: checkpoint, row 17 column 17, flag $854B
  DEFW CheckpointFlag8
  DEFB $03,$11,$11,low ActionCheckpoint,high ActionCheckpoint
  DEFB $1A
