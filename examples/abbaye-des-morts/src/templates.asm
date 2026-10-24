; Entity templates: the initial state of objects that are created while the
; game runs
;
; Each line is the template of one kind of object, a stack frame in the format
; of the object slots (ObjectSlots). SpawnQueuedObjects copies a template to a
; free slot when an entry of the object list (ObjectListPtr: template address,
; y, x) is consumed: bytes 0-5 (three words) as they are, then slot +6 = 0 and
; slot +7 = x + template byte 6, slot +8 = 0 and slot +9 = y + template byte 7
; (the two offsets are signed, in 2-pixel units, and make the start position
; relative to the object that threw the thing), then the 10 bytes from template
; byte 8 to slot +$A..+$13 as they are. The words of a template are therefore:
; +0 the handler, +2 and +4 the first two state words of the handler, +6 the x
; offset (low byte) and the y offset (high byte); from +8 on (slot +$A on) the
; layout depends on the handler:
;
; - projectiles (UpdateArrow, UpdateSeed, UpdateFireball): +2 x speed and +4 y
; speed (signed 8.8, 2-pixel units per frame), +8 hit box offset and +$A hit
; box far corner (y in the low byte, x in the high byte, from the position),
; +$C sprite width and height (2, 2), +$E the 3-byte sprite block
; (SpriteBlockArrowLeft and the others after BehaviourDrop: attribute, column,
; page);
;
; - the splash (UpdateSplash): +8 animation counter and reload, +$A frame and
; number of frames (3), +$C width and height, +$E SpriteBlockSplash (no hit
; box);
;
; - the sliding sprites (UpdateMovingSprite, UpdateScytheFalling,
; UpdatePyreMonk): +8 hit box offset, +$A far corner, +$C pointer to a sprite
; block with a shift table (attribute, pair table, height, frames; see
; BehaviourJean), +$E animation counter and reload, +$10 frame and number of
; frames.
;
; A template of 8 words is followed in memory by the next template: the 10-byte
; copy takes two bytes too many from it and they land in slot +$12/+$13, which
; the projectile handlers do not use. Slot +$14/+$15 are left as they were.
; Observed for every template but SmokeTemplate (slot bytes read after
; SpawnQueuedObjects in rooms 10, 14, 17, 18, 19, 20, 24 and the ending): the
; slot is the template with x and y added, +$12/+$13 hold the first word of the
; next template, +$14/+$15 what the slot held before.
;
; The last template of the group (SmokeTemplate) is not spawned this way:
; UpdateSatan writes the two positions into its words +4 and +6 and copies its
; 22 bytes over its own slot. The templates from ActorMonkTemplate on belong to
; the actors of the ending (the lists at CutsceneList1).
;
; arrow of a skeleton archer flying left (x speed $FE00 = -2.0 per frame),
; thrown when the monk is to its left (UpdateArcher); starts 6 units below the
; archer
ArrowLeftTemplate:
  DEFW UpdateArrow,$FE00,$0000,$0600,$0000,$0400,$0202,SpriteBlockArrowLeft
; the same arrow flying right ($0200), thrown when the monk is to the right;
; starts 3 units right of and 6 below the archer
ArrowRightTemplate:
  DEFW UpdateArrow,$0200,$0000,$0603,$0000,$0400,$0202,SpriteBlockArrowRight
; arrow flying left ($FE00) from the stone head in the wall of rooms 20 and 22
; (UpdateStoneHead); starts 2 units left of and 5 below the head
WallShotTemplate:
  DEFW UpdateArrow,$FE00,$0000,$05FE,$0000,$0401,$0202,SpriteBlockStoneArrow
; seed spat up and left by a plant of room 14 (UpdatePlant_Spit), handler
; UpdateSeed: x speed $FF91 = -0.43, y speed $FE90 = -1.44, made larger each
; frame by SEED_GRAVITY
SeedLeftTemplate:
  DEFW UpdateSeed,$FF91,$FE90,$0402,$0000,$0101,$0202,SpriteBlockSeed
; seed spat up and right (x speed $006F = +0.43)
SeedRightTemplate:
  DEFW UpdateSeed,$006F,$FE90,$0404,$0000,$0101,$0202,SpriteBlockSeed
; fireball of Satan, up and left (x speed $FF09 = -0.96, y speed $FFBF =
; -0.25), handler UpdateFireball; the three fireballs start 1 unit left of and
; 9 below Satan's position (UpdateSatan)
FireballUpTemplate:
  DEFW UpdateFireball,$FF09,$FFBF,$09FF,$0000,$0101,$0202,SpriteBlockFireball
; fireball of Satan, straight left (x speed $FF00 = -1.0)
FireballLeftTemplate:
  DEFW UpdateFireball,$FF00,$0000,$09FF,$0000,$0101,$0202,SpriteBlockFireball
; fireball of Satan, down and left (x speed -0.96, y speed $0041 = +0.25)
FireballDownTemplate:
  DEFW UpdateFireball,$FF09,$0041,$09FF,$0000,$0101,$0202,SpriteBlockFireball
; water splash of rooms 16 and 19 (made by UpdateFishWaiting and
; UpdateFishJumping at the fish's x and WATER_Y), handler UpdateSplash:
; animation counter and reload 2, three frames, 2 x 4 sprite, no hit box
; (observed, F83)
SplashTemplate:
  DEFW UpdateSplash,$0000,$0000,$0000,$0202,$0300,$0402,SpriteBlockSplash
; flame of the Pestilent Beast running left along the ledge of room 10 (x speed
; $FFC0 = -0.25) until x = $18, handler UpdateMovingSprite, spawned by
; UpdateBeastFire 20 units below the fire's position; hit box far corner x 7, y
; 3; red, 2 frames (observed, F84)
FlameLeftTemplate:
  DEFW UpdateMovingSprite,$FFC0,$0018,$1400,$0000,$0703,SpriteBlockFlame,$0202,$0200
; the same flame running right ($0040 = +0.25) until x = $70
FlameRightTemplate:
  DEFW UpdateMovingSprite,$0040,$0070,$1400,$0000,$0703,SpriteBlockFlame,$0202,$0200
; scythe of Death that falls (y speed $00C0 = +0.75, UpdateScytheFalling) and
; slides left on a floor (x speed $FF80 = -0.5, UpdateScytheSliding); starts 8
; units right of and 12 below Death (ThrowDeathScythe); four frames
ScytheLeftTemplate:
  DEFW UpdateScytheFalling,$FF80,$00C0,$0C08,$0000,$0707,SpriteBlockScythe,$0202,$0400
; the same scythe sliding right (x speed $0080 = +0.5)
ScytheRightTemplate:
  DEFW UpdateScytheFalling,$0080,$00C0,$0C08,$0000,$0707,SpriteBlockScythe,$0202,$0400
; the cloud of smoke that replaces Satan, a whole slot copied by UpdateSatan
; (see UpdateSatanSmoke): +2 lifetime 150 frames (high byte), +4 and +6 the
; positions of the upper and lower half (written by UpdateSatan), +8 size 4 x
; 12 of both halves, three unused words, +$10 SpriteBlockSmoke, +$12 animation
; counter and reload 5, +$14 frame 0 of 2
SmokeTemplate:
  DEFW UpdateSatanSmoke,$9600,$0000,$0000,$0C04,$0000,$0000,$0000,SpriteBlockSmoke,$0505,$0200
; the monk in the first scene of the ending (list CutsceneList1, room 25),
; handler UpdateMovingSprite with speed and limit 0: he only turns round, after
; 80 frames and then every 60 ($3C50; observed)
ActorMonkTemplate:
  DEFW UpdateMovingSprite,$0000,$0000,$0000,$0000,$0000,SpriteBlockEndingMonk,$3C50,$0200
; the monk on the pyre in the second scene (list CutsceneList2), handler
; UpdatePyreMonk: +2 280 frames until he burns ($0118), +4 175 more until the
; scene ends ($00AF); turns round every 25 frames ($1923; observed)
ActorPyreMonkTemplate:
  DEFW UpdatePyreMonk,$0118,$00AF,$0000,$0000,$0000,SpriteBlockPyreMonk,$1923,$0200
; a flame of the pyre (three of them), handler UpdateMovingSprite with speed 0,
; 2 frames, red
ActorFlameTemplate:
  DEFW UpdateMovingSprite,$0000,$0000,$0000,$0000,$0000,SpriteBlockFlame,$0202,$0200
; a crusader right of the pyre (two of them), facing left, cyan, 1 frame
ActorCrusaderRTemplate:
  DEFW UpdateMovingSprite,$0000,$0000,$0000,$0000,$0000,SpriteBlockPyreCrusaderR,$0202,$0100
; a crusader left of the pyre (two of them), facing right, cyan, 1 frame
ActorCrusaderLTemplate:
  DEFW UpdateMovingSprite,$0000,$0000,$0000,$0000,$0000,SpriteBlockPyreCrusaderL,$0202,$0100

; Frame call list gate: RET while the list is not complete, NOP when it is
;
; The first byte of the frame call list runner (RunFrameList), which it falls
; into when it is a NOP. It is a flag and an entry point at once. Observed over
; a frame: EndFrameList (the end of the game frame, when the frame list is
; complete) stores 0 here, so a CALL to this address runs the list;
; RunFrameList stores $C9 (RET) as the first thing it does, so a second call
; does nothing until the next list is complete. EnterRoom also stores $C9 when
; a room is entered. The main loop (MainLoop_Play) and the intro and cutscene
; loops (RunIntro, RunCutscene, through WaitFrameList) wait until the byte is
; zero and then CALL it.
;
; The byte is not data to read as a number only: the same address is read with
; LD A,(nn) by those loops.
FrameListGate:
  RET                     ; RET until the list is complete; 0 (NOP) when it is

; Run the frame call list
;
; Runs the draw commands the game frame queued in the frame call list
; (FrameList) and returns to the caller of FrameListGate. The list is a chain
; of calls without CALL: each command is a routine address followed by the
; parameters that routine pops (see QueueSprite for the usual one), and the RET
; that ends each routine pops the address of the next command. So the routine
; saves SP in the operand of the LD SP,nn at LeaveFrameList (self-modified
; here), sets SP to the start of the list and RETs into the first command; the
; last entry of the list is LeaveFrameList, which restores SP and returns. The
; routine first stores $C9 (RET) at FrameListGate, so the list is taken once,
; and at QueueDrawCmd, so that while the list runs no frame code adds commands
; to it (the game frame runs from the interrupt; while this flag is set it does
; not queue, so a frame that starts while the list runs leaves the list as it
; is and GameFrame skips EndFrameList).
;
; Hardware: none directly. SP points into the list while the commands run.
RunFrameList:
  LD A,OP_RET             ; RET
  LD (QueueDrawCmd),A     ; QueueDrawCmd, which queues a command, now returns
                          ; at once
  LD (FrameListGate),A    ; the list is taken: callers of FrameListGate return
                          ; until the next one
  LD (LeaveFrameList+$0001),SP ; saved SP: operand of the LD SP,nn at
                               ; LeaveFrameList
  LD SP,FrameList         ; start of the frame call list
  RET                     ; run the first command

; End of the frame call list: restore SP and leave the runner
;
; The word EndFrameList appends as the last entry of every frame call list, so
; the RET of the last command lands here. The operand of the LD SP,nn is
; self-modified: RunFrameList stores there the SP it had on entry, so this
; instruction puts the stack back. The routine then zeroes QueueDrawCmd, which
; lets the frame code queue commands again, and returns to the caller of
; RunFrameList.
LeaveFrameList:
  LD SP,LeaveFrameList    ; the operand is stored by RunFrameList
  XOR A
  LD (QueueDrawCmd),A     ; frame code may queue commands again
  RET                     ; return to the caller of FrameListGate

; Choose where the monk restarts after dying
;
; Reached at MainLoop_AfterDeath: once when a game starts (StartGame falls into
; it after the intro; observed at frame 301 of tests/inputs/play.txt, with no
; flag set: room 5) and for room state 4, after the monk has died. It clears the
; room state (MainLoop_Respawn then enters the room) and the hit flag
; PlayerHit, turns a dying monk into a standing one, and loads the room and
; position of the active checkpoint. The nine flags at CheckpointFlag0 are all
; zero, or all zero but one: the first is set to 1 by the church door of room 7
; (ActionChurchDoor), the other eight belong to the checkpoint items, and the
; checkpoint item the monk touched last (ActionCheckpoint) zeroes all nine and
; stores 2 in its own flag. The routine skips the zero flags together with the
; records of Checkpoints, so DE ends at the record of the flagged checkpoint, or
; at the tenth record (room 5, the start) when no flag is set. The record gives
; the room (to RoomNumber), and the row and column, which are multiplied by 4
; to give y and x in 2-pixel units (the high bytes of RespawnY and RespawnX,
; which MainLoop_Respawn copies to PlayerY and PlayerX).
;
; The loop stops at the first nonzero flag, not at the first zero one (observed
; with a run of the routine: with $8545 set to 2 the monk restarts in room 11
; at column 14, row 17; with all flags zero in room 5 at column 9, row 17).
SelectCheckpoint:
  XOR A                   ; room state 0
  LD (RoomState),A        ; it was 4: restart at the checkpoint
  LD (PlayerHit),A        ; clear the player hit flag
  LD HL,PlayerState       ; player state
  LD A,(HL)
  CP PLAYER_DYING         ; dying?
  JR NZ,SelectCheckpoint_0
  LD (HL),PLAYER_STANDING ; a dying monk stands up
SelectCheckpoint_0:
  LD HL,CheckpointFlag0   ; checkpoint flags
  LD DE,Checkpoints       ; checkpoint records
  LD B,CHECKPOINT_FLAGS   ; nine flags, ten records
  XOR A                   ; A = 0
SelectCheckpoint_Loop:
  CP (HL)                 ; flag zero (not the active checkpoint)?
  JR NZ,SelectCheckpoint_Found ; no: this is the active one
  INC HL                  ; next flag
  INC DE                  ; next record, three bytes
  INC DE
  INC DE
  DJNZ SelectCheckpoint_Loop ; if all nine are zero DE is at the tenth record
SelectCheckpoint_Found:
  LD A,(DE)               ; room of the checkpoint
  INC DE
  LD (RoomNumber),A       ; room number
  LD A,(DE)               ; row of the checkpoint
  INC DE
  ADD A,A                 ; times 4: y in 2-pixel units
  ADD A,A
  LD (RespawnYHi),A       ; start y (high byte of $8514)
  LD A,(DE)               ; column
  INC DE
  ADD A,A                 ; times 4: x in 2-pixel units
  ADD A,A
  LD (RespawnXHi),A       ; start x (high byte of $8512)
  RET

; Checkpoints: room, row and column of the 10 places the monk restarts at
;
; Ten records of 3 bytes read by SelectCheckpoint: +0 byte room number, +1 byte
; row (character rows, 0-21), +2 byte column (0-31). The monk restarts there
; with y = row * 4 and x = column * 4 in 2-pixel units, in character cells.
; Records 1 to 9 belong to the nine checkpoint flags at CheckpointFlag0 in the
; same order (the church door trigger of room 7, ActionChurchDoor, then the
; checkpoint items of rooms 8, 11, 12, 14, 15, 19, 21 and 23, ActionCheckpoint;
; room item records in RoomItems); the tenth is used while no flag is set: the
; start of the game in room 5. Room names: 7 Abandoned church, 8 The Altar,
; 11 Cave of illusions, 12 Plagued ruins, 14 Hidden garden, 15 Gloomy tunels,
; 19 Underground river, 21 Evil church, 23 Ashes to ashes, 5 Escape !!!.
Checkpoints:
  DEFB $07,$10,$02        ; CheckpointFlag0: Abandoned church
  DEFB $08,$11,$07        ; CheckpointFlag1: The Altar
  DEFB $0B,$11,$0E        ; CheckpointFlag2: Cave of illusions
  DEFB $0C,$07,$08        ; CheckpointFlag3: Plagued ruins
  DEFB $0E,$11,$08        ; CheckpointFlag4: Hidden garden
  DEFB $0F,$07,$15        ; CheckpointFlag5: Gloomy tunels
  DEFB $13,$0B,$08        ; CheckpointFlag6: Underground river
  DEFB $15,$05,$13        ; CheckpointFlag7: Evil church
  DEFB $17,$11,$11        ; CheckpointFlag8: Ashes to ashes
  DEFB $05,$11,$09        ; none touched: Escape !!!, the start

; Build a table of the 256 bit-reversed bytes
;
; Fills the page that HL points to (from L up to $FF) with the bit-reversed
; value of the low byte of each address: the byte at page + n is n with bits 7
; to 0 swapped. Room entry (EnterRoom) builds the table at $C500, where
; MirrorFrame and MirrorPixelLine use it to make the mirrored copies of sprites
; when a room's sprite sets are unpacked. It shares the memory of the first
; pixel-row page of the redraw buffer (RedrawPixels), which the table
; overwrites on every room entry and which the redraw code overwrites again.
; The 128K music bank calls it too (BankEndingDoor, see the interrupt module).
; Observed with a run of the routine (HL = $C500): every byte of the page is
; the bit-reversed index; on return B = 0, C = $FF, HL = $C500.
;
;   HL Start of the page; L is 0 for a whole table
; O:B 0 (EnterRoom clears the draw queue with it)
BuildMirrorTable:
  LD BC,$0800             ; B counts 8 bits, C collects the reversed byte
  LD A,L                  ; A = n
BuildMirrorTable_0:
  RLA                     ; bit 7 of A goes to the carry ...
  RR C                    ; ... and enters C at the top: after 8 turns the bits
                          ; are reversed
  DJNZ BuildMirrorTable_0
  LD (HL),C               ; store at page + n
  INC L
  JR NZ,BuildMirrorTable  ; until L wraps to 0
  RET
