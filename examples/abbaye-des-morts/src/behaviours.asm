; Behaviour block: Jean walking across the intro screen (kind 0, room 0)
;
; Used by the first walker of room 0 (RoomObjects): the monk of the intro,
; drawn with the same frames and shift table as the player (ShiftPairs,
; MonkFramesLeft).
;
; Behaviour blocks (BehaviourJean to 95FE) say how a room object kind
; (RoomObjects) looks and where it can be hit. A room object record points to
; one (record +9). SpawnRoomObject copies bytes 0-3 into the slot (+$0C to
; +$0F), byte 4 into slot +$15 and keeps the address of byte 5 in slot
; +$10/+$11: the handler of the kind reads the rest through that pointer. The
; blocks of the walking and flying kinds (0, 2-6 and 8) have this layout (read
; from ReadSpriteLeft, SelectFrameRight and HitTest):
;
; +0 byte: top edge of the hit box, +1 left edge, +2 bottom edge, +3 right
; edge: all relative to the object's position, in 2-pixel units (the handler
; adds them to x and y and HitTest compares the box with Jean's). Read from
; HitTest: the documentation of some handlers calls the second pair a size,
; which is the same only while the first pair is 0.
;
; +4 byte: Unknown, copied to slot +$15 (the values are 1 and 2)
;
; +5 byte: attribute of the sprite
;
; +6 word: table of (first column, width in bytes) pairs, one for each x AND 3
; (the sprite sheet holds four copies of every sprite shifted by 2 pixels;
; ShiftPairs is the table of the monk and the crusader, 11 columns per frame,
; ShiftPairsAligned is the table of the sprites that sit on a byte boundary)
;
; +8 byte: sprite height in 2-pixel units
;
; +9 word: the sprites for the first direction (moving left or up): a list of
; sprite sheet addresses indexed by the animation frame
;
; +$0B word: the same for the second direction (moving right or down)
;
; The sprites are in the sprite sheet at SpriteSheet (rows 0-23) and
; SpriteSheetLower (rows 24-39); which creature they show depends on the sprite
; set the room unpacked.
BehaviourJean:
  DEFB $00,$00,$00,$00,$02 ; hit box top, left, bottom, right; slot +$15
                           ; (Unknown)
  DEFB $46                ; attribute
  DEFW ShiftPairs         ; table of (first column, width) for x AND 3
  DEFB $0C                ; sprite height (2-pixel units)
  DEFW MonkFramesLeft     ; Jean standing, facing left (3 frames,
                          ; MonkFramesLeft)
  DEFW MonkFramesRight    ; Jean standing, facing right (3 frames,
                          ; MonkFramesRight)

; Behaviour block: a crusader (kinds 0 and 1, rooms 0, 5, 6 and 25)
;
; Used by the three crusaders that follow Jean across the intro screen (kind 0,
; room 0) and by the crusader spawners of rooms 5, 6 and 25 (kind 1): the
; entity templates at CrusaderTemplateRoom5 hold the address of byte 5 of this
; block ($93E5). Crusaders are cyan (attribute $45), 24 pixels tall.
;
; Layout: see BehaviourJean.
BehaviourCrusader:
  DEFB $00,$01,$0C,$06,$02 ; hit box top, left, bottom, right; slot +$15
                           ; (Unknown)
  DEFB $45                ; attribute
  DEFW ShiftPairs         ; table of (first column, width) for x AND 3
  DEFB $0C                ; sprite height (2-pixel units)
  DEFW BehaviourCrusader+$D ; sprites, first direction (left or up)
  DEFW BehaviourCrusader+$11 ; sprites, second direction (right or down)
  DEFW $D763              ; first direction, frame 0
  DEFW $D76E              ; first direction, frame 1
  DEFW $D779              ; second direction, frame 0
  DEFW $D784              ; second direction, frame 1

; Behaviour block: a white walker (kind 2, rooms 13 and 22)
;
; Used by the patrollers of room 13 (skeletons, seen) and one in room 22
; (white, attribute $47). The sprite addresses are the same as the crusader's.
;
; Layout: see BehaviourJean.
BehaviourSkeleton:
  DEFB $02,$01,$0C,$06,$02 ; hit box top, left, bottom, right; slot +$15
                           ; (Unknown)
  DEFB $47                ; attribute
  DEFW ShiftPairs         ; table of (first column, width) for x AND 3
  DEFB $0C                ; sprite height (2-pixel units)
  DEFW BehaviourSkeleton+$D ; sprites, first direction (left or up)
  DEFW BehaviourSkeleton+$11 ; sprites, second direction (right or down)
  DEFW $D763              ; first direction, frame 0
  DEFW $D76E              ; first direction, frame 1
  DEFW $D779              ; second direction, frame 0
  DEFW $D784              ; second direction, frame 1

; Behaviour block: a white walker near the ceiling (kind 2, rooms 22 and 23)
;
; Used by the patrollers at the top of rooms 22 and 23 (attribute $47, 20
; pixels tall; seen hanging near the ceiling in room 22).
;
; Layout: see BehaviourJean.
BehaviourWhiteFlyer:
  DEFB $00,$01,$0A,$06,$02 ; hit box top, left, bottom, right; slot +$15
                           ; (Unknown)
  DEFB $47                ; attribute
  DEFW ShiftPairs         ; table of (first column, width) for x AND 3
  DEFB $0C                ; sprite height (2-pixel units)
  DEFW BehaviourWhiteFlyer+$D ; sprites, first direction (left or up)
  DEFW BehaviourWhiteFlyer+$11 ; sprites, second direction (right or down)
  DEFW $D78F              ; first direction, frame 0
  DEFW $D79A              ; first direction, frame 1
  DEFW $D7A5              ; second direction, frame 0
  DEFW $D7B0              ; second direction, frame 1

; Behaviour block: a bat (kinds 2 and 3, room 8)
;
; Used by the two bats of The Altar (red, attribute $42, 16 pixels tall, flying
; left and right).
;
; Layout: see BehaviourJean.
BehaviourBat:
  DEFB $01,$01,$06,$06,$02 ; hit box top, left, bottom, right; slot +$15
                           ; (Unknown)
  DEFB $42                ; attribute
  DEFW ShiftPairs         ; table of (first column, width) for x AND 3
  DEFB $08                ; sprite height (2-pixel units)
  DEFW BehaviourBat+$D    ; sprites, first direction (left or up)
  DEFW BehaviourBat+$D    ; sprites, second direction (right or down)
  DEFW $D763              ; both directions, frame 0
  DEFW $D76E              ; both directions, frame 1

; Behaviour block: a rat (kinds 2 and 3, room 2)
;
; Used by the two rats of Tower of the Bell (cyan, attribute $45, run along the
; floor).
;
; Layout: see BehaviourJean.
BehaviourRat:
  DEFB $03,$01,$06,$06,$02 ; hit box top, left, bottom, right; slot +$15
                           ; (Unknown)
  DEFB $45                ; attribute
  DEFW ShiftPairs         ; table of (first column, width) for x AND 3
  DEFB $08                ; sprite height (2-pixel units)
  DEFW BehaviourRat+$D    ; sprites, first direction (left or up)
  DEFW BehaviourRat+$11   ; sprites, second direction (right or down)
  DEFW $D763              ; first direction, frame 0
  DEFW $D76E              ; first direction, frame 1
  DEFW $D779              ; second direction, frame 0
  DEFW $D784              ; second direction, frame 1

; Behaviour block: a spider on its thread (kind 4, rooms 3, 14, 16 and 19)
;
; Used by the green spiders that move up and down (attribute $44). The two
; frames are at $F338 and $F33A (rows 24-39 of the sprite sheet, 2 bytes wide);
; the shift table is ShiftPairsAligned.
;
; Layout: see BehaviourJean.
BehaviourSpider:
  DEFB $00,$01,$05,$06,$02 ; hit box top, left, bottom, right; slot +$15
                           ; (Unknown)
  DEFB $44                ; attribute
  DEFW ShiftPairsAligned  ; table of (first column, width) for x AND 3
  DEFB $05                ; sprite height (2-pixel units)
  DEFW BehaviourSpiderYellow+$D ; sprites, first direction (left or up)
  DEFW BehaviourSpiderYellow+$D ; sprites, second direction (right or down)

; Behaviour block: a yellow spider (kind 5, room 3)
;
; Used by the yellow spiders of Wine supplies (attribute $06); the sprites and
; the table ShiftPairsAligned at the end of this block are shared with
; BehaviourSpider.
;
; Layout: see BehaviourJean.
BehaviourSpiderYellow:
  DEFB $00,$01,$05,$06,$02 ; hit box top, left, bottom, right; slot +$15
                           ; (Unknown)
  DEFB $06                ; attribute
  DEFW ShiftPairsAligned  ; table of (first column, width) for x AND 3
  DEFB $05                ; sprite height (2-pixel units)
  DEFW BehaviourSpiderYellow+$D ; sprites, first direction (left or up)
  DEFW BehaviourSpiderYellow+$D ; sprites, second direction (right or down)
  DEFW $F338              ; both directions, frame 0
  DEFW $F33A              ; both directions, frame 1
ShiftPairsAligned:
  DEFB $00,$02            ; table for x AND 3 = 0 only: first column 0, width 2
                          ; (shared by the vertical walkers)

; Behaviour block: a hanged man (kind 6, room 9)
;
; Used by the four hanged men of Hangman tree (yellow, attribute $46) that bob
; up and down on their ropes.
;
; Layout: see BehaviourJean.
BehaviourHangedMan:
  DEFB $00,$01,$07,$06,$01 ; hit box top, left, bottom, right; slot +$15
                           ; (Unknown)
  DEFB $46                ; attribute
  DEFW ShiftPairsAligned  ; table of (first column, width) for x AND 3
  DEFB $0C                ; sprite height (2-pixel units)
  DEFW BehaviourHangedMan+$D ; sprites, first direction (left or up)
  DEFW BehaviourHangedMan+$F ; sprites, second direction (right or down)
  DEFW $D763              ; first direction, frame 0
  DEFW $D765              ; second direction, frame 0

; Behaviour block: a worm (kind 2, rooms 9 and 14)
;
; Used by the cyan worms that crawl along a branch in room 9 and on the ground
; in room 14 (attribute $45, 2 units tall).
;
; Layout: see BehaviourJean.
BehaviourWorm:
  DEFB $00,$01,$01,$06,$02 ; hit box top, left, bottom, right; slot +$15
                           ; (Unknown)
  DEFB $45                ; attribute
  DEFW ShiftPairs         ; table of (first column, width) for x AND 3
  DEFB $02                ; sprite height (2-pixel units)
  DEFW BehaviourWorm+$D   ; sprites, first direction (left or up)
  DEFW BehaviourWorm+$D   ; sprites, second direction (right or down)
  DEFW $DBF5              ; both directions, frame 0
  DEFW $E3F5              ; both directions, frame 1

; Behaviour block: a fly (kind 5, room 12)
;
; Used by two of the green flies of Plagued ruins (attribute $44); they move up
; and down.
;
; Layout: see BehaviourJean.
BehaviourFlyA:
  DEFB $01,$01,$06,$06,$02 ; hit box top, left, bottom, right; slot +$15
                           ; (Unknown)
  DEFB $44                ; attribute
  DEFW ShiftPairsAligned  ; table of (first column, width) for x AND 3
  DEFB $08                ; sprite height (2-pixel units)
  DEFW BehaviourFlyA+$D   ; sprites, first direction (left or up)
  DEFW BehaviourFlyA+$11  ; sprites, second direction (right or down)
  DEFW $D76B              ; first direction, frame 0
  DEFW $D76D              ; first direction, frame 1
  DEFW $D76F              ; second direction, frame 0
  DEFW $D771              ; second direction, frame 1

; Behaviour block: a fly, darker colour (kind 5, room 12)
;
; Used by three of the flies of Plagued ruins (attribute $04, not bright).
;
; Layout: see BehaviourJean.
BehaviourFlyB:
  DEFB $01,$01,$06,$06,$02 ; hit box top, left, bottom, right; slot +$15
                           ; (Unknown)
  DEFB $04                ; attribute
  DEFW ShiftPairsAligned  ; table of (first column, width) for x AND 3
  DEFB $08                ; sprite height (2-pixel units)
  DEFW BehaviourFlyB+$D   ; sprites, first direction (left or up)
  DEFW BehaviourFlyB+$11  ; sprites, second direction (right or down)
  DEFW $D763              ; first direction, frame 0
  DEFW $D765              ; first direction, frame 1
  DEFW $D767              ; second direction, frame 0
  DEFW $D769              ; second direction, frame 1

; Behaviour block: the grinning ghost that chases Jean (kind 8, room 11)
;
; Used by the smiling cyan ghost of Cave of illusions (attribute $45), which
; floats toward Jean through free space (UpdateChaser).
;
; Layout: see BehaviourJean.
BehaviourChaser:
  DEFB $01,$01,$06,$06,$02 ; hit box top, left, bottom, right; slot +$15
                           ; (Unknown)
  DEFB $45                ; attribute
  DEFW ShiftPairs         ; table of (first column, width) for x AND 3
  DEFB $08                ; sprite height (2-pixel units)
  DEFW BehaviourChaser+$D ; sprites, first direction (left or up)
  DEFW BehaviourChaser+$11 ; sprites, second direction (right or down)
  DEFW $D763              ; first direction, frame 0
  DEFW $D76E              ; first direction, frame 1
  DEFW $D779              ; second direction, frame 0
  DEFW $D784              ; second direction, frame 1

; Behaviour block: a flying creature (kind 2, rooms 20 and 23)
;
; Used by the magenta flying creatures of Unexpected gate and Ashes to ashes
; (attribute $43). Its own shift table follows the frames (four (first column,
; width) pairs: 3+4+4+4 = 15 columns per frame).
;
; Layout: see BehaviourJean.
BehaviourBird:
  DEFB $03,$00,$04,$0B,$02 ; hit box top, left, bottom, right; slot +$15
                           ; (Unknown)
  DEFB $43                ; attribute
  DEFW ShiftPairsBird     ; table of (first column, width) for x AND 3
  DEFB $08                ; sprite height (2-pixel units)
  DEFW BehaviourBird+$D   ; sprites, first direction (left or up)
  DEFW BehaviourBird+$11  ; sprites, second direction (right or down)
  DEFW $EF63              ; first direction, frame 0
  DEFW $EF72              ; first direction, frame 1
  DEFW $EF81              ; second direction, frame 0
  DEFW $EF90              ; second direction, frame 1
ShiftPairsBird:
  DEFB $00,$03,$03,$04,$07,$04,$0B,$04 ; shift table: (first column, width) for
                                       ; x AND 3

; Behaviour block: a water drop, and the sprite blocks of the projectiles (kind
; 9, rooms 15 and 19)
;
; Used by the drops that fall from the roof of Gloomy tunels and Underground
; river (cyan, attribute $45). This kind does not have the layout of
; BehaviourJean: after the 5 header bytes (hit box and slot +$15, as there)
; comes the sprite description read by AnimateDrop: +5 attribute, +6 height of
; the falling drop (2-pixel units; the width of the sprites is 2 bytes), +7
; word graphics of the hanging drop frame 0, +9 word frame 1, +$0B word the
; falling drop.
;
; The rest of the entry holds the sprite blocks (attribute, then the graphics)
; of the projectiles of the other kinds: the entity templates at
; ArrowLeftTemplate point at them. SpriteBlockFireball the fireballs of Satan,
; SpriteBlockSeed the seeds of the plants, SpriteBlockStoneArrow the arrows of
; the stone heads, SpriteBlockArrowLeft and SpriteBlockArrowRight the arrows of
; the archers (flying left and right), SpriteBlockSplash the splash of a fish
; (3 sprites).
BehaviourDrop:
  DEFB $00,$03,$03,$05,$02 ; hit box top, left, bottom, right (2-pixel units);
                           ; slot +$15 (Unknown)
  DEFB $45,$04            ; attribute, height of the falling drop
  DEFW $EF53              ; hanging drop, frame 0
  DEFW $EF55              ; hanging drop, frame 1
  DEFW $F357              ; falling drop
SpriteBlockFireball:
  DEFB $44                ; fireball of Satan: attribute
  DEFW $EF30              ; sprite
SpriteBlockSeed:
  DEFB $43                ; seed of a plant: attribute
  DEFW $EF30              ; sprite
SpriteBlockStoneArrow:
  DEFB $44                ; arrow of a stone head: attribute
  DEFW $EF32              ; sprite
SpriteBlockArrowLeft:
  DEFB $47                ; arrow of an archer, flying left: attribute
  DEFW $EF34              ; sprite
SpriteBlockArrowRight:
  DEFB $47                ; arrow of an archer, flying right: attribute
  DEFW $EF36              ; sprite
SpriteBlockSplash:
  DEFB $45                ; splash: attribute
  DEFW $F759              ; sprite, frame 0
  DEFW $F75B              ; sprite, frame 1
  DEFW $F75D              ; sprite, frame 2

; Behaviour block: a soldier (kind 2, rooms 15 and 20)
;
; Used by the green soldiers with a sword of Gloomy tunels and Unexpected gate
; (attribute $44).
;
; Layout: see BehaviourJean.
BehaviourSoldier:
  DEFB $00,$01,$0C,$06,$02 ; hit box top, left, bottom, right; slot +$15
                           ; (Unknown)
  DEFB $44                ; attribute
  DEFW ShiftPairs         ; table of (first column, width) for x AND 3
  DEFB $0C                ; sprite height (2-pixel units)
  DEFW BehaviourSoldier+$D ; sprites, first direction (left or up)
  DEFW BehaviourSoldier+$11 ; sprites, second direction (right or down)
  DEFW $D763              ; first direction, frame 0
  DEFW $D76E              ; first direction, frame 1
  DEFW $D779              ; second direction, frame 0
  DEFW $D784              ; second direction, frame 1

; Behaviour block: a skeleton archer (kind 10, rooms 17 and 21)
;
; Used by the white skeleton archers of The wheel of faith and Evil church
; (attribute $47, 24 pixels tall), which shoot arrows left or right. Layout
; after the 5 header bytes (hit box as in BehaviourJean): attribute, sprite
; height, sprite width in bytes, then the sprite lists of the two directions
; (two frames each).
BehaviourArcher:
  DEFB $03,$01,$0B,$06,$02 ; hit box top, left, bottom, right (2-pixel units);
                           ; slot +$15 (Unknown)
  DEFB $47,$0C,$02        ; attribute, sprite height (2-pixel units), width
                          ; (bytes)
  DEFW BehaviourArcher+$C ; sprites, first direction (left)
  DEFW BehaviourArcher+$10 ; sprites, second direction (right)
  DEFW $D7F8              ; first direction, frame 0
  DEFW $D7FA              ; first direction, frame 1
  DEFW $D7FC              ; second direction, frame 0
  DEFW $D7FE              ; second direction, frame 1

; Behaviour block: the stone head in the wall that shoots arrows (kind 11,
; rooms 20 and 22)
;
; Used by the stone heads (shaped like a dragon's head) in the right wall of
; Unexpected gate and Tortured souls (attribute $07, handler UpdateStoneHead).
; After the 5 header bytes: attribute, sprite height, width in bytes, then a
; pointer to the list of its two sprites.
BehaviourStoneHead:
  DEFB $00,$00,$07,$07,$02 ; hit box top, left, bottom, right (2-pixel units);
                           ; slot +$15 (Unknown)
  DEFB $07,$08,$02        ; attribute, sprite height, width (bytes)
  DEFW BehaviourStoneHead+$A ; sprites
  DEFW $EF3E              ; sprite $EF3E
  DEFW $EF3C              ; sprite $EF3C

; Behaviour block: a seed-spitting plant (kind 12, room 14)
;
; Used by the three magenta plants of Hidden garden that spit seeds (attribute
; $43). After the 5 header bytes: attribute, sprite height, width in bytes,
; then the addresses of its two sprites.
BehaviourSeedPlant:
  DEFB $03,$01,$07,$06,$02 ; hit box top, left, bottom, right (2-pixel units);
                           ; slot +$15 (Unknown)
  DEFB $43,$08,$02        ; attribute, sprite height, width (bytes)
  DEFW $EF4B              ; sprite, frame 0
  DEFW $EF4D              ; sprite, frame 1

; Behaviour block: a fish that jumps out of the water (kind 13, rooms 16 and
; 19)
;
; Used by the magenta fish (attribute $03) that wait under the water of Lake of
; despair and Underground river and jump out of it (UpdateFishWaiting; the lake
; is red). After the 5 header bytes: attribute, sprite height, width in bytes,
; then the addresses of its two sprites.
BehaviourFish:
  DEFB $00,$00,$07,$07,$02 ; hit box top, left, bottom, right (2-pixel units);
                           ; slot +$15 (Unknown)
  DEFB $03,$08,$02        ; attribute, sprite height, width (bytes)
  DEFW $EF4F              ; sprite, frame 0
  DEFW $EF51              ; sprite, frame 1

; Behaviour block: a demon (kinds 2 and 3, rooms 21 and 22)
;
; Used by the red demons of Evil church (and one in Tortured souls); attribute
; $42, 24 pixels tall.
;
; Layout: see BehaviourJean.
BehaviourDemon:
  DEFB $02,$01,$0C,$06,$02 ; hit box top, left, bottom, right; slot +$15
                           ; (Unknown)
  DEFB $42                ; attribute
  DEFW ShiftPairs         ; table of (first column, width) for x AND 3
  DEFB $0C                ; sprite height (2-pixel units)
  DEFW BehaviourDemon+$D  ; sprites, first direction (left or up)
  DEFW BehaviourDemon+$11 ; sprites, second direction (right or down)
  DEFW $D7BB              ; first direction, frame 0
  DEFW $D7C6              ; first direction, frame 1
  DEFW $D7D1              ; second direction, frame 0
  DEFW $D7DC              ; second direction, frame 1

; Behaviour block: a falling red flame (kind 4, rooms 22 and 23)
;
; Used by the small red spinning flames that move up and down in Tortured souls
; and Ashes to ashes (attribute $42). The same sprite address is used for both
; directions: the sprite sheet has one for each row of the sheet ($DBE7 and
; $EBE7: frames 0 and 1).
;
; Layout: see BehaviourJean.
BehaviourFireWheel:
  DEFB $00,$02,$03,$05,$02 ; hit box top, left, bottom, right; slot +$15
                           ; (Unknown)
  DEFB $42                ; attribute
  DEFW ShiftPairsAligned  ; table of (first column, width) for x AND 3
  DEFB $04                ; sprite height (2-pixel units)
  DEFW BehaviourFireWheel+$D ; sprites, first direction (left or up)
  DEFW BehaviourFireWheel+$D ; sprites, second direction (right or down)
  DEFW $DBE7              ; both directions, frame 0
  DEFW $EBE7              ; both directions, frame 1

; Behaviour block: the Pestilent Beast (kind 14, room 10)
;
; Used by the head of the Pestilent Beast of room 10 (attribute $06,
; UpdateBeastHead): a 32 x 40 pixel sprite at the top of the room that lowers
; while the fire breath of kind 15 (BehaviourBeastFire) is drawn. Hit box 38 x
; 30 pixels. After the 5 header bytes (hit box as in BehaviourJean): attribute,
; sprite height, width in bytes, then the address of one sprite.
BehaviourBeastHead:
  DEFB $00,$00,$13,$0F,$01 ; hit box top, left, bottom, right (2-pixel units);
                           ; slot +$15 (Unknown)
  DEFB $06,$14,$04        ; attribute, sprite height, width (bytes)
  DEFW $D763              ; sprite

; Behaviour block: the fire breath of the Pestilent Beast, and the sprite
; blocks of the flames and the ending (kind 15)
;
; Used by the fire breath of the Beast of room 10 (attribute $42,
; UpdateBeastFire): a red jet of two sprites, one under the other, that comes
; down from the mouth for the last 38 frames of a 110-frame cycle and kills
; Jean on contact (hit box 46 x 14 pixels). After the 5 header bytes:
; attribute, width in bytes, height in 2-pixel units and the four sprite
; addresses of the jet (two frames of each of the two sprites).
;
; The rest of the entry holds sprite blocks (attribute, shift table ShiftPairs,
; height, sprite addresses) that the templates at ArrowLeftTemplate point at:
; SpriteBlockFlame the flames (two frames: the flames of the Beast
; FlameLeftTemplate and FlameRightTemplate and the flames of the pyre),
; SpriteBlockEndingMonk the monk of the first scene of the ending,
; SpriteBlockPyreMonk the monk on the pyre, SpriteBlockPyreCrusaderR and
; SpriteBlockPyreCrusaderL the crusaders at the pyre (right and left).
BehaviourBeastFire:
  DEFB $00,$00,$17,$07,$02 ; hit box top, left, bottom, right (2-pixel units);
                           ; slot +$15 (Unknown)
  DEFB $42,$02,$0C        ; attribute, width (bytes), height (2-pixel units)
  DEFW $D768              ; jet, upper sprite, frame 0
  DEFW $D76D              ; jet, upper sprite, frame 1
  DEFW $D76A              ; jet, lower sprite, frame 0
  DEFW $D76F              ; jet, lower sprite, frame 1
SpriteBlockFlame:
  DEFB $42                ; flame: attribute
  DEFW ShiftPairs         ; shift table
  DEFB $04                ; height
  DEFW $EF40              ; flame frame 0
  DEFW $F740              ; flame frame 1
SpriteBlockEndingMonk:
  DEFB $46                ; monk of the first ending scene: attribute
  DEFW ShiftPairs         ; shift table
  DEFB $0C                ; height
  DEFW SpriteSheet        ; sprite (standing, facing left)
  DEFW $D721              ; sprite (standing, facing right)
SpriteBlockPyreMonk:
  DEFB $46                ; monk on the pyre: attribute
  DEFW ShiftPairs         ; shift table
  DEFB $0C                ; height
  DEFW $D716              ; sprite
  DEFW $D737              ; sprite
SpriteBlockPyreCrusaderR:
  DEFB $45                ; crusader right of the pyre: attribute
  DEFW ShiftPairs         ; shift table
  DEFB $0C                ; height
  DEFW $D76E              ; sprite
SpriteBlockPyreCrusaderL:
  DEFB $45                ; crusader left of the pyre: attribute
  DEFW ShiftPairs         ; shift table
  DEFB $0C                ; height
  DEFW $D784              ; sprite

; Behaviour block: Death, and the sprite block of his scythe (kind 16, room 18)
;
; Used by Death of Banquet of Death (attribute $47, 28 pixels tall) who flies
; left and right and throws scythes. After the 5 header bytes (hit box as in
; BehaviourJean): attribute, the pointer to Death's shift table (it follows the
; sprite lists), sprite height, the lists of the two directions (3 frames each,
; 19 columns per frame). The shift table has four (first column, width) pairs:
; 4+5+5+5 columns. The sprite block of the thrown scythe follows
; (SpriteBlockScythe, used by the templates ScytheLeftTemplate and
; ScytheRightTemplate): attribute, the shift table ShiftPairs, height and four
; sprite addresses.
BehaviourDeath:
  DEFB $02,$02,$0C,$0D,$02 ; hit box top, left, bottom, right (2-pixel units);
                           ; slot +$15 (Unknown)
  DEFB $47                ; attribute
  DEFW ShiftTableDeath    ; shift table (ShiftTableDeath)
  DEFB $0E                ; sprite height
  DEFW BehaviourDeath+$D  ; sprites, first direction (left)
  DEFW BehaviourDeath+$13 ; sprites, second direction (right)
  DEFW $D763              ; first direction, frame 0
  DEFW $D776              ; first direction, frame 1
  DEFW $D789              ; first direction, frame 2
  DEFW $D79C              ; second direction, frame 0
  DEFW $D7AF              ; second direction, frame 1
  DEFW $D7C2              ; second direction, frame 2
ShiftTableDeath:
  DEFB $00,$04,$04,$05,$09,$05,$0E,$05 ; shift table of Death: (first column,
                                       ; width) for x AND 3
SpriteBlockScythe:
  DEFB $47                ; scythe: attribute
  DEFW ShiftPairs         ; shift table
  DEFB $08                ; height
  DEFW $D7EA              ; sprite
  DEFW $D7F5              ; sprite
  DEFW $E7EA              ; sprite
  DEFW $E7F5              ; sprite

; Behaviour block: Satan, and the sprite block of the smoke (kind 17, room 24)
;
; Used by Satan (attribute $42, UpdateSatan), a two-part sprite: the upper half
; 4 bytes wide and the lower half. After the 5 header bytes (hit box 30 x 46
; pixels): attribute, width in bytes (4), height in 2-pixel units (12), four
; sprite addresses of the body. Then the sprite block of the cloud of smoke
; that replaces Satan (SpriteBlockSmoke, used by the template SmokeTemplate):
; attribute and four sprite addresses.
BehaviourSatan:
  DEFB $00,$00,$17,$0F,$02 ; hit box top, left, bottom, right (2-pixel units);
                           ; slot +$15 (Unknown)
  DEFB $42,$04,$0C        ; attribute, width (bytes), height (2-pixel units)
  DEFW $D78F              ; body sprite
  DEFW $D796              ; body sprite
  DEFW $D793              ; body sprite
  DEFW $D79A              ; body sprite
SpriteBlockSmoke:
  DEFB $47                ; smoke: attribute
  DEFW $D79D              ; sprite
  DEFW $D7A5              ; sprite
  DEFW $D7A1              ; sprite
  DEFW $D7A9              ; sprite
