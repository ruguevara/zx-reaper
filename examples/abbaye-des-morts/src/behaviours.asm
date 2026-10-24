; Behaviour block: Jean walking across the intro screen (kind 0, room 0)
;
; Used by the first walker of room 0 (RoomObjects): the monk of the intro,
; drawn with the same frames and shift table as the player (ShiftPairs,
; MonkFramesLeft).
;
; Behaviour blocks (BehaviourJean to the end of SpriteBlockSmoke, $95FE) say
; how a room object kind (RoomObjects) looks and where it can be hit. A room
; object record points to
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
; +4 byte: number of animation frames, copied to slot +$15, the frame count
; of StepAnimation (the values are 1 and 2)
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
; SpriteSheetLower (rows 24-39). Columns $63 and up hold what the room unpacked
; (the sprite sets PackedSet0-PackedSet19; each block below names its set, as
; seen by drawing the sheet columns in a room that unpacks it); columns below
; $63 are the fixed part of the sheet (the monk, the spiders, drops, stone
; heads, plants, fish and the projectiles).
BehaviourJean:
  DEFB $00,$00,$00,$00,$02 ; hit box top, left, bottom, right; slot +$15
                           ; (frame count)
  DEFB $46                ; attribute
  DEFW ShiftPairs         ; table of (first column, width) for x AND 3
  DEFB $0C                ; sprite height (2-pixel units)
  DEFW MonkFramesLeft     ; frames of Jean facing left (MonkFramesLeft has 3;
                          ; with a frame count of 2 only 0 and 1 are shown)
  DEFW MonkFramesRight    ; frames of Jean facing right (MonkFramesRight)

; Behaviour block: a crusader (kinds 0 and 1, rooms 0, 5, 6 and 25)
;
; Used by the three crusaders that follow Jean across the intro screen (kind 0,
; room 0) and by the crusader spawners of rooms 5, 6 and 25 (kind 1): the
; entity templates at CrusaderTemplateRoom5 hold the address of byte 5 of this
; block ($93E5). Crusaders are cyan (attribute $45), 24 pixels tall. Sprites:
; PackedSet1 at $D763, two frames facing left, then their mirrored copies
; facing right (the same set gives the crusaders of the pyre, room 4).
;
; Layout: see BehaviourJean.
BehaviourCrusader:
  DEFB $00,$01,$0C,$06,$02 ; hit box top, left, bottom, right; slot +$15
                           ; (frame count)
  DEFB $45                ; attribute
  DEFW ShiftPairs         ; table of (first column, width) for x AND 3
  DEFB $0C                ; sprite height (2-pixel units)
  DEFW BehaviourCrusader+$D ; sprites, first direction (left or up)
  DEFW BehaviourCrusader+$11 ; sprites, second direction (right or down)
  DEFW $D763              ; first direction, frame 0
  DEFW $D76E              ; first direction, frame 1
  DEFW $D779              ; second direction, frame 0
  DEFW $D784              ; second direction, frame 1

; Behaviour block: a skeleton (kind 2, rooms 13 and 22)
;
; Used by the white skeletons with a sword that patrol left and right, two in
; room 13 and one in room 22 (attribute $47, 24 pixels tall). Sprites:
; PackedSet17, unpacked at $D763 in both rooms, the same place as the crusader
; set, so the sprite addresses are the crusader's.
;
; Layout: see BehaviourJean.
BehaviourSkeleton:
  DEFB $02,$01,$0C,$06,$02 ; hit box top, left, bottom, right; slot +$15
                           ; (frame count)
  DEFB $47                ; attribute
  DEFW ShiftPairs         ; table of (first column, width) for x AND 3
  DEFB $0C                ; sprite height (2-pixel units)
  DEFW BehaviourSkeleton+$D ; sprites, first direction (left or up)
  DEFW BehaviourSkeleton+$11 ; sprites, second direction (right or down)
  DEFW $D763              ; first direction, frame 0
  DEFW $D76E              ; first direction, frame 1
  DEFW $D779              ; second direction, frame 0
  DEFW $D784              ; second direction, frame 1

; Behaviour block: a ceiling ghost (kind 2, rooms 22 and 23)
;
; Used by the ceiling ghosts of Tortured souls and Ashes to ashes, one in each:
; a white hooded figure hanging upside down from the ceiling (attribute $47,
; sprite 24 pixels tall, hit box 20) that patrols left and right (observed in
; room 22: y $04, x from $08 to $38 and back). Sprites: PackedSet18 at $D78F.
;
; Layout: see BehaviourJean.
BehaviourWhiteFlyer:
  DEFB $00,$01,$0A,$06,$02 ; hit box top, left, bottom, right; slot +$15
                           ; (frame count)
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
; left and right). Sprites: PackedSet15 at $D763, two frames with shifted
; copies and no mirrored ones, so both directions use the same list.
;
; Layout: see BehaviourJean.
BehaviourBat:
  DEFB $01,$01,$06,$06,$02 ; hit box top, left, bottom, right; slot +$15
                           ; (frame count)
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
; floor). Sprites: PackedSet13 at $D763.
;
; Layout: see BehaviourJean.
BehaviourRat:
  DEFB $03,$01,$06,$06,$02 ; hit box top, left, bottom, right; slot +$15
                           ; (frame count)
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
; frames are at $F338 and $F33A (pixel rows 28-37, in the fixed part of the
; sprite sheet: no room unpacks them; 2 bytes wide); the shift table is
; ShiftPairsAligned.
;
; Layout: see BehaviourJean.
BehaviourSpider:
  DEFB $00,$01,$05,$06,$02 ; hit box top, left, bottom, right; slot +$15
                           ; (frame count)
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
                           ; (frame count)
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
; up and down on their ropes. Sprites: PackedSet10 at $D763, one frame and its
; mirrored copy at $D765 (drawn while going down).
;
; Layout: see BehaviourJean.
BehaviourHangedMan:
  DEFB $00,$01,$07,$06,$01 ; hit box top, left, bottom, right; slot +$15
                           ; (frame count)
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
; in room 14 (attribute $45, 2 units tall). Sprites: PackedSet19 at $D7F5, a
; strip of 16 pixel rows holding both frames, one under the other: frame 0 at
; pixel row 4 ($DBF5), frame 1 at row 12 ($E3F5).
;
; Layout: see BehaviourJean.
BehaviourWorm:
  DEFB $00,$01,$01,$06,$02 ; hit box top, left, bottom, right; slot +$15
                           ; (frame count)
  DEFB $45                ; attribute
  DEFW ShiftPairs         ; table of (first column, width) for x AND 3
  DEFB $02                ; sprite height (2-pixel units)
  DEFW BehaviourWorm+$D   ; sprites, first direction (left or up)
  DEFW BehaviourWorm+$D   ; sprites, second direction (right or down)
  DEFW $DBF5              ; both directions, frame 0
  DEFW $E3F5              ; both directions, frame 1

; Behaviour block: a fly (kind 5, room 12)
;
; Used by three of the five green flies of Plagued ruins (bright, attribute
; $44); they move up and down. Sprites: PackedSet9 at $D76B.
;
; Layout: see BehaviourJean.
BehaviourFlyA:
  DEFB $01,$01,$06,$06,$02 ; hit box top, left, bottom, right; slot +$15
                           ; (frame count)
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
; Used by the other two flies of Plagued ruins (attribute $04, not bright).
; Sprites: PackedSet8 at $D763.
;
; Layout: see BehaviourJean.
BehaviourFlyB:
  DEFB $01,$01,$06,$06,$02 ; hit box top, left, bottom, right; slot +$15
                           ; (frame count)
  DEFB $04                ; attribute
  DEFW ShiftPairsAligned  ; table of (first column, width) for x AND 3
  DEFB $08                ; sprite height (2-pixel units)
  DEFW BehaviourFlyB+$D   ; sprites, first direction (left or up)
  DEFW BehaviourFlyB+$11  ; sprites, second direction (right or down)
  DEFW $D763              ; first direction, frame 0
  DEFW $D765              ; first direction, frame 1
  DEFW $D767              ; second direction, frame 0
  DEFW $D769              ; second direction, frame 1

; Behaviour block: the chasing ghost (kind 8, room 11)
;
; Used by the chasing ghost of Cave of illusions, a grinning cyan head
; (attribute $45) that floats toward Jean through free space (UpdateChaser).
; Sprites: PackedSet12 at $D763.
;
; Layout: see BehaviourJean.
BehaviourChaser:
  DEFB $01,$01,$06,$06,$02 ; hit box top, left, bottom, right; slot +$15
                           ; (frame count)
  DEFB $45                ; attribute
  DEFW ShiftPairs         ; table of (first column, width) for x AND 3
  DEFB $08                ; sprite height (2-pixel units)
  DEFW BehaviourChaser+$D ; sprites, first direction (left or up)
  DEFW BehaviourChaser+$11 ; sprites, second direction (right or down)
  DEFW $D763              ; first direction, frame 0
  DEFW $D76E              ; first direction, frame 1
  DEFW $D779              ; second direction, frame 0
  DEFW $D784              ; second direction, frame 1

; Behaviour block: a bird (kind 2, rooms 20 and 23)
;
; Used by the magenta gliding birds of Unexpected gate and Ashes to ashes
; (attribute $43). Sprites: PackedSet4 at $EF63 (24 pixels wide). Its own
; shift table follows the frames (four (first column, width) pairs: 3+4+4+4 =
; 15 columns per frame).
;
; Layout: see BehaviourJean.
BehaviourBird:
  DEFB $03,$00,$04,$0B,$02 ; hit box top, left, bottom, right; slot +$15
                           ; (frame count)
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
; The rest of the entry holds the sprite blocks of the projectiles of the other
; kinds: the entity templates at ArrowLeftTemplate point at them (slot +$10).
; The five projectile blocks are 3 bytes, read by SetProjectileSprite:
; attribute, column and page of the first of four copies of a 2-pixel-unit
; (4 pixel rows) high sprite in the fixed part of the sheet, each copy 2 pixels
; further right and 4 pages lower than the one before (the copy for x AND 3 is
; 4 * (x AND 3) pages down). SpriteBlockFireball the fireballs of Satan and
; SpriteBlockSeed the seeds of the plants (the same round sprite in two
; colours), SpriteBlockStoneArrow the arrows of the stone heads,
; SpriteBlockArrowLeft and SpriteBlockArrowRight the arrows of the archers
; (flying left and right). SpriteBlockSplash, the splash of a fish, is the
; attribute and three frame addresses (UpdateSplash).
BehaviourDrop:
  DEFB $00,$03,$03,$05,$02 ; hit box top, left, bottom, right (2-pixel units);
                           ; slot +$15 (frame count)
  DEFB $45,$04            ; attribute, height of the falling drop
  DEFW $EF53              ; hanging drop, frame 0
  DEFW $EF55              ; hanging drop, frame 1
  DEFW $F357              ; falling drop
SpriteBlockFireball:
  DEFB $44                ; fireball of Satan: attribute
  DEFW $EF30              ; column $30, page $EF: first of the 4 copies
SpriteBlockSeed:
  DEFB $43                ; seed of a plant: attribute
  DEFW $EF30              ; the same sprite as the fireball
SpriteBlockStoneArrow:
  DEFB $44                ; arrow of a stone head: attribute
  DEFW $EF32              ; column $32, page $EF
SpriteBlockArrowLeft:
  DEFB $47                ; arrow of an archer, flying left: attribute
  DEFW $EF34              ; column $34, page $EF
SpriteBlockArrowRight:
  DEFB $47                ; arrow of an archer, flying right: attribute
  DEFW $EF36              ; column $36, page $EF
SpriteBlockSplash:
  DEFB $45                ; splash: attribute
  DEFW $F759              ; sprite, frame 0
  DEFW $F75B              ; sprite, frame 1
  DEFW $F75D              ; sprite, frame 2

; Behaviour block: a knight (kind 2, rooms 15 and 20)
;
; Used by the green knights with a closed helmet and a sword that patrol Gloomy
; tunels (two) and Unexpected gate (one) (attribute $44). Sprites: PackedSet11
; at $D763.
;
; Layout: see BehaviourJean.
BehaviourSoldier:
  DEFB $00,$01,$0C,$06,$02 ; hit box top, left, bottom, right; slot +$15
                           ; (frame count)
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
; (two frames each: frame 0 resting, frame 1 aiming with the bow drawn, shown
; for the last 30 frames before a shot, UpdateShooter_Tail). Sprites:
; PackedSet0 at $D7F8, the two frames facing left and their mirrored copies.
BehaviourArcher:
  DEFB $03,$01,$0B,$06,$02 ; hit box top, left, bottom, right (2-pixel units);
                           ; slot +$15 (frame count)
  DEFB $47,$0C,$02        ; attribute, sprite height (2-pixel units), width
                          ; (bytes)
  DEFW BehaviourArcher+$C ; sprites, first direction (left)
  DEFW BehaviourArcher+$10 ; sprites, second direction (right)
  DEFW $D7F8              ; facing left, frame 0 (resting)
  DEFW $D7FA              ; facing left, frame 1 (aiming)
  DEFW $D7FC              ; facing right, frame 0
  DEFW $D7FE              ; facing right, frame 1

; Behaviour block: the stone head in the wall that shoots arrows (kind 11,
; rooms 20 and 22)
;
; Used by the stone heads (shaped like a dragon's head) in the right wall of
; Unexpected gate and Tortured souls (attribute $07, handler UpdateStoneHead).
; After the 5 header bytes: attribute, sprite height, width in bytes, then a
; pointer to the list of its two frames (fixed part of the sheet): frame 0
; resting, frame 1 for the last 30 frames before a shot (UpdateShooter_Tail).
BehaviourStoneHead:
  DEFB $00,$00,$07,$07,$02 ; hit box top, left, bottom, right (2-pixel units);
                           ; slot +$15 (frame count)
  DEFB $07,$08,$02        ; attribute, sprite height, width (bytes)
  DEFW BehaviourStoneHead+$A ; frame list (the head faces left only)
  DEFW $EF3E              ; frame 0: resting
  DEFW $EF3C              ; frame 1: about to shoot

; Behaviour block: a seed-spitting plant (kind 12, room 14)
;
; Used by the three magenta plants of Hidden garden that spit seeds (attribute
; $43). After the 5 header bytes: attribute, sprite height, width in bytes,
; then the addresses of its two sprites (fixed part of the sheet).
BehaviourSeedPlant:
  DEFB $03,$01,$07,$06,$02 ; hit box top, left, bottom, right (2-pixel units);
                           ; slot +$15 (frame count)
  DEFB $43,$08,$02        ; attribute, sprite height, width (bytes)
  DEFW $EF4B              ; sprite, frame 0
  DEFW $EF4D              ; sprite, frame 1

; Behaviour block: a fish that jumps out of the water (kind 13, rooms 16 and
; 19)
;
; Used by the magenta fish (attribute $03) that wait under the water of Lake of
; despair and Underground river and jump out of it (UpdateFishWaiting; the lake
; is red). After the 5 header bytes: attribute, sprite height, width in bytes,
; then the addresses of its two sprites (fixed part of the sheet).
BehaviourFish:
  DEFB $00,$00,$07,$07,$02 ; hit box top, left, bottom, right (2-pixel units);
                           ; slot +$15 (frame count)
  DEFB $03,$08,$02        ; attribute, sprite height, width (bytes)
  DEFW $EF4F              ; sprite, frame 0
  DEFW $EF51              ; sprite, frame 1

; Behaviour block: a demon (kinds 2 and 3, rooms 21 and 22)
;
; Used by the red demons of Evil church (and one in Tortured souls); attribute
; $42, 24 pixels tall. Sprites: PackedSet3 at $D7BB.
;
; Layout: see BehaviourJean.
BehaviourDemon:
  DEFB $02,$01,$0C,$06,$02 ; hit box top, left, bottom, right; slot +$15
                           ; (frame count)
  DEFB $42                ; attribute
  DEFW ShiftPairs         ; table of (first column, width) for x AND 3
  DEFB $0C                ; sprite height (2-pixel units)
  DEFW BehaviourDemon+$D  ; sprites, first direction (left or up)
  DEFW BehaviourDemon+$11 ; sprites, second direction (right or down)
  DEFW $D7BB              ; first direction, frame 0
  DEFW $D7C6              ; first direction, frame 1
  DEFW $D7D1              ; second direction, frame 0
  DEFW $D7DC              ; second direction, frame 1

; Behaviour block: a fire wheel (kind 4, rooms 22 and 23)
;
; Used by the fire wheels, small red spinning flames that move up and down in
; Tortured souls and Ashes to ashes (attribute $42, three in each room). Both
; directions share one frame list. Sprites: PackedSet7 at $D7E7, a strip of 32
; pixel rows holding both frames, one under the other: frame 0 at pixel row 4
; ($DBE7), frame 1 at row 20 ($EBE7).
;
; Layout: see BehaviourJean.
BehaviourFireWheel:
  DEFB $00,$02,$03,$05,$02 ; hit box top, left, bottom, right; slot +$15
                           ; (frame count)
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
; while the fire breath of kind 15 (BehaviourBeastFire) is drawn. Sprite:
; PackedSet6 at $D763. The hit box bytes (38 pixels tall, 30 wide) are copied
; to the slot but UpdateBeastHead drops them without a hit test: touching the
; head does not kill (from the code), only the fire does. After the 5 header
; bytes: attribute, sprite height, width in bytes, then the address of one
; sprite.
BehaviourBeastHead:
  DEFB $00,$00,$13,$0F,$01 ; hit box top, left, bottom, right (2-pixel units);
                           ; slot +$15 (frame count)
  DEFB $06,$14,$04        ; attribute, sprite height, width (bytes)
  DEFW $D763              ; sprite

; Behaviour block: the fire breath of the Pestilent Beast, and the sprite
; blocks of the flames and the ending (kind 15)
;
; Used by the fire breath of the Beast of room 10 (attribute $42,
; UpdateBeastFire): a red jet of two sprites, one under the other, that comes
; down from the mouth for the last 38 frames of a 110-frame cycle and kills
; Jean on contact (hit box 14 pixels wide, 46 tall). After the 5 header bytes:
; attribute, width in bytes of the upper sprite (the lower one is a byte
; wider), height in 2-pixel units and the four sprite addresses of the jet:
; upper sprite frames 0 and 1, lower sprite frames 0 and 1
; (UpdateBeastFire_Draw). Sprites: PackedSet5 at $D768, ten columns: upper
; frame 0 (2), lower frame 0 (3), upper frame 1 (2), lower frame 1 (3).
;
; The rest of the entry holds sprite blocks (attribute, shift table ShiftPairs,
; height, sprite addresses) that the templates at ArrowLeftTemplate point at:
; SpriteBlockFlame the flames (two frames: the flames of the Beast
; FlameLeftTemplate and FlameRightTemplate and the flames of the pyre),
; SpriteBlockEndingMonk the monk of the first scene of the ending (Jean facing
; left and facing right, the fixed monk sprites; observed: he turns round after
; 80 frames, then every 60), SpriteBlockPyreMonk the monk on the pyre (frame 2
; of MonkFramesLeft and of MonkFramesRight; he turns every 25 frames),
; SpriteBlockPyreCrusaderR and SpriteBlockPyreCrusaderL the crusaders right and
; left of the pyre (frame 1 of PackedSet1 facing left, and its mirrored copy
; facing right: each pair faces the pyre).
BehaviourBeastFire:
  DEFB $00,$00,$17,$07,$02 ; hit box top, left, bottom, right (2-pixel units);
                           ; slot +$15 (frame count)
  DEFB $42,$02,$0C        ; attribute, width of the upper sprite (bytes),
                          ; height (2-pixel units)
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
  DEFW SpriteSheet        ; frame 0: standing, facing left (MonkFramesLeft 0)
  DEFW $D721              ; frame 1: standing, facing right (MonkFramesRight
                          ; 0)
SpriteBlockPyreMonk:
  DEFB $46                ; monk on the pyre: attribute
  DEFW ShiftPairs         ; shift table
  DEFB $0C                ; height
  DEFW $D716              ; frame 0: facing left (MonkFramesLeft 2)
  DEFW $D737              ; frame 1: facing right (MonkFramesRight 2)
SpriteBlockPyreCrusaderR:
  DEFB $45                ; crusader right of the pyre: attribute
  DEFW ShiftPairs         ; shift table
  DEFB $0C                ; height
  DEFW $D76E              ; crusader frame 1, facing left
SpriteBlockPyreCrusaderL:
  DEFB $45                ; crusader left of the pyre: attribute
  DEFW ShiftPairs         ; shift table
  DEFB $0C                ; height
  DEFW $D784              ; crusader frame 1, facing right (mirrored copy)

; Behaviour block: Death, and the sprite block of his scythe (kind 16, room 18)
;
; Used by Death of Banquet of Death (attribute $47, 28 pixels tall) who flies
; left and right and throws scythes. After the 5 header bytes (hit box as in
; BehaviourJean): attribute, the pointer to Death's shift table (it follows the
; sprite lists), sprite height, the lists of the two directions (3 frames each,
; 19 columns per frame). Sprites: PackedSet2 at $D763, three frames facing left
; and their mirrored copies. The frame count (+4) is 2, so StepAnimation only
; alternates frames 0 and 1; frame 2, the throwing pose, is drawn by
; ThrowDeathScythe, which selects it while Death's 50-frame timer is at 20 or
; below: the frame of a throw and the 19 after it (observed in room 18: scythes
; spawned at frames 20 and 70, frame 2 drawn at frames 20-39 and 70-89, frames
; 0 and 1 between).
; The shift table has four (first column, width) pairs: 4+5+5+5 columns. The
; sprite block of the thrown scythe follows (SpriteBlockScythe, used by the
; templates ScytheLeftTemplate and ScytheRightTemplate): attribute, the shift
; table ShiftPairs, height and the four frames of the spinning scythe
; (PackedSet16 at $D7EA: a strip of 32 pixel rows with two frames, one under
; the other, in each of its two frame columns).
BehaviourDeath:
  DEFB $02,$02,$0C,$0D,$02 ; hit box top, left, bottom, right (2-pixel units);
                           ; slot +$15 (frame count)
  DEFB $47                ; attribute
  DEFW ShiftTableDeath    ; shift table (ShiftTableDeath)
  DEFB $0E                ; sprite height
  DEFW BehaviourDeath+$D  ; sprites, first direction (left)
  DEFW BehaviourDeath+$13 ; sprites, second direction (right)
  DEFW $D763              ; first direction, frame 0
  DEFW $D776              ; first direction, frame 1
  DEFW $D789              ; first direction, frame 2 (throwing)
  DEFW $D79C              ; second direction, frame 0
  DEFW $D7AF              ; second direction, frame 1
  DEFW $D7C2              ; second direction, frame 2 (throwing)
ShiftTableDeath:
  DEFB $00,$04,$04,$05,$09,$05,$0E,$05 ; shift table of Death: (first column,
                                       ; width) for x AND 3
SpriteBlockScythe:
  DEFB $47                ; scythe: attribute
  DEFW ShiftPairs         ; shift table
  DEFB $08                ; height
  DEFW $D7EA              ; frame 0 (pixel rows 0-15)
  DEFW $D7F5              ; frame 1
  DEFW $E7EA              ; frame 2 (pixel rows 16-31)
  DEFW $E7F5              ; frame 3

; Behaviour block: Satan, and the sprite block of the smoke (kind 17, room 24)
;
; Used by Satan (attribute $42, UpdateSatan), a two-part sprite: the upper half
; 4 bytes wide and the lower half one byte narrower, drawn one column right and
; 12 units lower (SetSatanSprite). After the 5 header bytes (hit box 30 pixels
; wide, 46 tall): attribute, width in bytes of the upper half (4), height in
; 2-pixel units (12), then the upper half frames 0 and 1 and the lower half
; frames 0 and 1 (QueueTwoPartSprite takes table[frame] and table[frame + 2]).
; Then the sprite block of the cloud of smoke that replaces Satan
; (SpriteBlockSmoke, used by the template SmokeTemplate): attribute and the
; four addresses in the same order. Sprites: PackedSet14 at $D78F, 30 columns:
; Satan's four pieces, then the smoke's.
BehaviourSatan:
  DEFB $00,$00,$17,$0F,$02 ; hit box top, left, bottom, right (2-pixel units);
                           ; slot +$15 (frame count)
  DEFB $42,$04,$0C        ; attribute, width (bytes), height (2-pixel units)
  DEFW $D78F              ; upper half, frame 0
  DEFW $D796              ; upper half, frame 1
  DEFW $D793              ; lower half, frame 0
  DEFW $D79A              ; lower half, frame 1
SpriteBlockSmoke:
  DEFB $47                ; smoke: attribute
  DEFW $D79D              ; upper half, frame 0
  DEFW $D7A5              ; upper half, frame 1
  DEFW $D7A1              ; lower half, frame 0
  DEFW $D7A9              ; lower half, frame 1
