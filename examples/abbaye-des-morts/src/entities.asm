; Entity handler table: 18 words, indexed by the kind of a room object
;
; Word k is the handler of room objects of kind k (byte 1 of the 11-byte
; records at RoomObjects). The enemy spawner SpawnRoomObject copies it to the
; first word of a free object slot (ObjectSlots): from then on RunObjectSlots
; enters it once per frame with SP at the slot. The kinds with a record in
; RoomObjects, with the creatures they drive (rooms in brackets; the sprite
; sets are those of UnpackRecords):
;
; 0 the runners of the intro screen: Jean and three crusaders (0); 1 the
; spawner of the crusaders that chase Jean (5, 6 and the ending room 25); 2 and
; 3 patrollers along a horizontal line, 2 starting to the left and 3 to the
; right: rats (2), bats (8), worms (9, 14), skeletons (13, 22), knights (15,
; 20), ceiling ghosts (22, 23), birds (20, 23), demons (21, 22) (kind 3 only
; for one rat, one bat and one demon); 4 and 5 patrollers along a vertical
; line, 4 starting down and 5 up: green spiders (3, 14, 16, 19) and fire wheels
; (22, 23) of kind 4, yellow spiders (3) and flies (12) of kind 5; 6 hanged men
; on their ropes (9); 8 the chasing ghost (11); 9 water drops falling from the
; ceiling (15, 19); 10 skeleton archers (17, 21); 11 stone heads in the wall
; that shoot arrows (20, 22); 12 plants that spit seeds (14); 13 fish jumping
; out of the water (16, 19); 14 the head of the Pestilent Beast (10); 15 its
; fire breath (10); 16 Death (18); 17 Satan (24). Kind 7 has no room object:
; the hanged man's handler for going up is entered from UpdateHangedDown when
; it reaches the bottom (and the other way round). Checked against the kind
; byte of every record of RoomObjects and the slots of each room.
;
; Handlers that change their own slot's first word to another (the patrollers
; between going left and right, the crusaders between walking and jumping) are
; not looked up in this table again.
EntityHandlers:
  DEFW UpdateIntroRunner  ; kind 0: Jean and the crusaders of the intro
  DEFW UpdateCrusaderSpawner ; kind 1: makes a crusader every 40 frames from
                             ; the template at the record's parameter word
                             ; (CrusaderTemplateRoom5, 6, 25)
  DEFW UpdatePatrolLeft     ; kind 2: horizontal patroller, starts left
  DEFW UpdatePatrolRight    ; kind 3: horizontal patroller, starts right
  DEFW UpdatePatrolDown     ; kind 4: vertical patroller, starts down
  DEFW UpdatePatrolUp       ; kind 5: vertical patroller, starts up
  DEFW UpdateHangedDown   ; kind 6: hanged man, starts down
  DEFW UpdateHangedUp     ; kind 7: hanged man going up (no room object has
                          ; this kind)
  DEFW UpdateChaser       ; kind 8: the chasing ghost
  DEFW UpdateDropHanging  ; kind 9: water drop, starts hanging
  DEFW UpdateArcher       ; kind 10: skeleton archer
  DEFW UpdateStoneHead    ; kind 11: stone head
  DEFW UpdatePlant        ; kind 12: plant
  DEFW UpdateFishWaiting  ; kind 13: fish, starts under the water
  DEFW UpdateBeastHead    ; kind 14: head of the Pestilent Beast
  DEFW UpdateBeastFire    ; kind 15: fire breath of the Pestilent Beast
  DEFW UpdateDeathLeft    ; kind 16: Death, starts moving left
  DEFW UpdateSatan        ; kind 17: Satan

; Crusader templates: the initial object slot of a crusader, one per chase room
;
; The spawner UpdateCrusaderSpawner copies one of these 22 bytes into a free
; slot of ObjectSlots every 40 passes of the main loop (the room object record
; of room 5, 6 or 25 holds the address in its parameter bytes 5 and 6 at 8BC2,
; 8BCD and 8BD8). The templates differ only in the path script of word +4. A
; slot is a stack frame (see ObjectSlots): its 11 words are popped by the
; handler UpdateCrusader and the code it jumps to:
;
; +0 word: handler, UpdateCrusader (the path follower; the path commands
; replace it for a while by UpdateCrusaderStepUp, UpdateCrusaderHop,
; UpdateCrusaderFall) +2 word: x speed, 8.8 fixed point in 2-pixel units per
; frame ($0060: 0.375 units, three quarters of a pixel) +4 word: address of the
; next entry of the path script (PathScriptRoom5): pairs (target x, command) +6
; word: x, 8.8 ($F700: -9 units, off the left edge); the high byte is in
; 2-pixel units +8 word: y, 8.8 ($4400: 68 units, standing on the floor of the
; three rooms) +A word: state of a jump along a speed curve: low byte = index
; in the curve (0-5), high byte = steps left (6) +C word: hit box offset (low
; byte y, high byte x, in 2-pixel units): x + 1, y + 0 +E word: hit box far
; corner: x + 6, y + $0C (the box spans x + 1..x + 6 and y + 0..y + $0C) +$10
; word: pointer to the sprite description of the crusader (BehaviourCrusader +
; 5: attribute, shift table ShiftPairs, height, the two frame tables, see
; ReadSpriteLeft) +$12 byte: animation counter, +$13 byte: its reload (8 frames
; per step) +$14 byte: frame number, +$15 byte: number of frames (2)
;
; All three are drawn from the sprite set 1 (the crusaders, PackedSetCrusader), cyan.
; The hit box test (HitTest) makes a crusader kill Jean on touch.
CrusaderTemplateRoom5:
  DEFW UpdateCrusader,$0060,PathScriptRoom5,$F700,$4400,$0600,$0100,$060C,BehaviourCrusader+$0005,$0808,$0200 ; room 5,
                                                                                                              ; script
                                                                                                              ; $B218
CrusaderTemplateRoom6:
  DEFW UpdateCrusader,$0060,PathScriptRoom6,$F700,$4400,$0600,$0100,$060C,BehaviourCrusader+$0005,$0808,$0200 ; room 6,
                                                                                                              ; script
                                                                                                              ; $B220
CrusaderTemplateRoom25:
  DEFW UpdateCrusader,$0060,PathScriptRoom25,$F700,$4400,$0600,$0100,$060C,BehaviourCrusader+$0005,$0808,$0200 ; room 25
                                                                                                               ; (the
                                                                                                               ; ending),
                                                                                                               ; script
                                                                                                               ; $B22C

; Free the slot of an entity that has only just been entered
;
; For handlers that remove their entity before popping anything: SP is at slot
; + 2, so the PUSH writes the zero over the handler word at slot + 0 (the slot
; is free from now on) and the next slot is 22 bytes on. Used by the path
; command 4 of the crusaders (PathCommands), by Satan's fireballs once Satan is
; gone (UpdateFireball), by the arrows, fireballs and seeds that leave the room
; or hit a wall (Projectile_Remove), by the splash (UpdateSplash), Death's
; scythe (Scythe_Destroy), Satan (UpdateSatan) and his smoke
; (UpdateSatanSmoke), each after putting SP back at slot + 2. FreeEntitySlot is
; the same for a handler that has already popped its words.
;
; Hardware: none.
;
; SP Slot address + 2
FreeEntitySlotAtEntry:
  LD HL,$0000             ; handler = 0
  PUSH HL                 ; written over the handler word at slot + 0
  LD HL,SLOT_SIZE         ; the next slot
  ADD HL,SP
  JP RunObjectSlot        ; RunObjectSlot: enter the handler of the slot at HL

; Entity handler: the spawner of the crusaders (kind 1, rooms 5, 6 and 25)
;
; An invisible object that makes a new crusader from a template every 40 passes
; of the main loop (one pass per frame in the chase rooms): the slot counts
; down the animation counter at +$12 (the first count, 90 passes, is the
; parameter byte 1 of the room object record: the first crusader appears 90
; passes after the room is entered; the reload at +$13 is not used afterwards,
; a constant 40 is loaded instead). When the counter reaches 0 it asks
; FindFreeSlot_IY for a free slot and goes on at SpawnCrusader, which copies
; the template into it. The template (CrusaderTemplateRoom5) is pointed to by
; the slot word +4, from the parameter bytes 5 and 6 of the record (8BBB, 8BC6,
; 8BD1); each room has its own path script. The slot never changes: crusaders
; keep coming for as long as Jean stays in the room (observed in room 5: four
; or five on the screen at a time, a new one every 40 passes).
;
; Slot fields used: +4 word template address; +$12 byte counter, +$13 byte
; reload (not used). Its x, y and sprite fields are not used (nothing is
; drawn).
;
; Hardware: none.
;
; SP Slot address + 2
UpdateCrusaderSpawner:
  POP DE                  ; skip +2 (speed, 0)
  POP DE                  ; DE = +4: the template of the crusaders
  LD HL,$000C             ; skip +6..+$11: the position and sprite fields, six
                          ; words
  ADD HL,SP
  LD SP,HL                ; SP = slot + $12
  POP BC                  ; C = counter, B = reload
  DEC C
  JR NZ,UpdateCrusaderSpawner_0
  LD C,CRUSADER_PERIOD    ; every 40 passes from now on
UpdateCrusaderSpawner_0:
  PUSH BC                 ; store the counter (SP back at slot + $12)
  JP NZ,NextSlotAfterAnim ; NextSlotAfterAnim: not yet
  LD IY,SpawnCrusader     ; the free slot search returns to SpawnCrusader
  JP FindFreeSlot_IY      ; find a free slot: IX = slot, carry set when there
                          ; is one

; Make a crusader: copy the template into the free slot
;
; Second half of the spawner UpdateCrusaderSpawner, entered through IY from the
; free slot search FindFreeSlot_IY: when there is no free slot (carry clear)
; nothing is made. Otherwise the 22 bytes of the template go to the slot (DE =
; IX), including the handler word UpdateCrusader, which makes the crusader
; start running at the next slot walk or, if the new slot lies after the
; spawner's, in this same frame.
;
; Hardware: none.
;
; F Carry set when FindFreeSlot_IY found a free slot
; DE Template address (kept from UpdateCrusaderSpawner)
; IX Address of the free slot
; SP Slot address + $12 (of the spawner)
SpawnCrusader:
  JP NC,NextSlotAfterAnim ; no free slot: NextSlotAfterAnim
  EX DE,HL                ; HL = template
  LD D,IXH
  LD E,IXL                ; DE = the new slot
  LDI                     ; 22 LDIs: SLOT_SIZE bytes of the template
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  JP NextSlotAfterAnim    ; NextSlotAfterAnim

; Speed curves of the crusaders' jumps: 3 curves of 6 signed words
;
; Vertical speeds in 8.8 fixed point (2-pixel units per frame, negative = up)
; added to the y word of a crusader in six consecutive frames while it runs a
; jump (path commands 1, 2 and 3, handlers UpdateCrusaderStepUp,
; UpdateCrusaderHop and UpdateCrusaderFall; the index in the curve is the low
; byte of slot word +$A). The sums are exact: curve 0 rises $400 (4 units, 8
; pixels), curve 1 falls $800 (8 units, 16 pixels), curve 2 returns to the
; start. Observed in rooms 5 and 6 (y of a crusader every frame): up by 8
; pixels over the six frames at the steps, down by 16 at the end of the block,
; a hop that comes back to the floor over the pits. The first curve is the step
; up (command 1), the second the drop (command 3) and the third the hop
; (command 2); note that the code of UpdateCrusaderFall (command 3) uses the
; second and UpdateCrusaderHop (command 2) the third.
;
; +0 curve 0, JumpCurveStepUp: -$249, -$125, -$92, -$49, 0, +$49 (step up, sum
; -$400) +$C curve 1, JumpCurveFall: +$20, +$42, +$84, +$108, +$20E, +$404
; (fall, accelerating, sum +$800) +$18 curve 2, JumpCurveHop: -$125, -$92,
; -$49, +$49, +$92, +$125 (hop, sum 0)
JumpCurveStepUp:
  DEFW $FDB7,$FEDB,$FF6E,$FFB7,$0000,$0049 ; curve 0: step up 8 pixels
JumpCurveFall:
  DEFW $0020,$0042,$0084,$0108,$020E,$0404 ; curve 1: fall 16 pixels
JumpCurveHop:
  DEFW $FEDB,$FF6E,$FFB7,$0049,$0092,$0125 ; curve 2: hop

; Entity handler: crusader hopping (path command 2)
;
; The handler that the path command 2 puts in the slot (UpdateCrusader_Command)
; for six frames: the crusader jumps over a pit. x goes up by the fixed speed
; $0150 (faster than the walking speed, CRUSADER_HOP_SPEED; the speed word of
; the slot is skipped, as is the path pointer), y changes by the next value of
; the speed curve JumpCurveHop (the hop: up, then down, net zero) and the hit
; test and drawing go on at UpdateCrusaderJump. The state word +$A counts the
; frames: low byte = index in the curve, high byte = frames left. On the sixth
; frame the handler word of the slot is set back to UpdateCrusader and the
; state to 6 frames left, index 0, ready for the next command. Observed in room
; 6 at x = $24, $3C and $4C: y goes $4400, $42DB, $4249, $4200, $4249, $42DB,
; $4400 over six frames while x gains $0150 each frame.
;
; The same code, with another speed and curve, is UpdateCrusaderFall (command
; 3) and UpdateCrusaderStepUp (command 1).
;
; Slot fields used: +4 path pointer (skipped), +6 word x, +8 word y, +$A word
; jump state. The others are used by UpdateCrusaderJump and the code after it,
; as for UpdateCrusader.
;
; Hardware: none.
;
; SP Slot address + 2
UpdateCrusaderHop:
  POP BC                  ; skip +2: the speed, not used in a jump
  POP DE                  ; skip +4: the path pointer
  POP HL                  ; x (8.8)
  LD BC,CRUSADER_HOP_SPEED ; fixed x speed of the hop
  ADD HL,BC
  PUSH HL                 ; store x (SP at slot + 6)
  LD A,H                  ; A = x in 2-pixel units
  POP HL                  ; SP back at slot + 8
  POP DE                  ; DE = y (8.8)
  POP BC                  ; BC = state: B frames left, C index in the curve
  LD L,C
  LD H,$00                ; HL = index
  INC C
  DJNZ UpdateCrusaderHop_0 ; not the last frame: keep the state with the next
                           ; index
  LD BC,CRUSADER_JUMP_FRAMES*$0100 ; the last frame: the state is reset for the
                                   ; next jump
  EXX
  LD (SmcHopRestoreSP+$0001),SP ; SP (slot + $C) for the LD SP below
  LD HL,$FFF6             ; -10: SP to slot + 2
  ADD HL,SP
  LD SP,HL
  LD HL,UpdateCrusader
  PUSH HL                 ; written over the handler word at slot + 0: back to
                          ; walking
  EXX
SmcHopRestoreSP:
  LD SP,SmcHopRestoreSP   ; the operand is stored by B122 just above: SP = slot
                          ; + $C again
UpdateCrusaderHop_0:
  PUSH BC                 ; store the state at slot + $A
  LD BC,JumpCurveHop      ; the curve of the hop
  JR UpdateCrusaderJump   ; apply it

; Entity handler: crusader falling (path command 3)
;
; The handler that the path command 3 puts in the slot (UpdateCrusader_Command)
; for six frames: the crusader drops from a block to the floor, 16 pixels
; lower. It is UpdateCrusaderHop with two differences: x goes up by the slot's
; own speed word (the walking speed, $0060) and y follows the curve
; JumpCurveFall (falling faster each frame, sum +$800). Observed in room 5 at x
; = $64: y goes from $3C00 to $4400 in six frames. After the sixth frame the
; handler goes back to UpdateCrusader.
;
; Hardware: none.
;
; SP Slot address + 2
UpdateCrusaderFall:
  POP BC                  ; BC = +2: the x speed
  POP DE                  ; skip +4: the path pointer
  POP HL                  ; x (8.8)
  ADD HL,BC
  PUSH HL                 ; store x
  LD A,H                  ; A = x in 2-pixel units
  POP HL
  POP DE                  ; DE = y (8.8)
  POP BC                  ; BC = state: B frames left, C index in the curve
  LD L,C
  LD H,$00                ; HL = index
  INC C
  DJNZ UpdateCrusaderFall_0 ; not the last frame
  LD BC,CRUSADER_JUMP_FRAMES*$0100 ; the last frame: reset the state
  EXX
  LD (SmcFallRestoreSP+$0001),SP ; SP (slot + $C) for the LD SP below
  LD HL,$FFF6             ; -10: SP to slot + 2
  ADD HL,SP
  LD SP,HL
  LD HL,UpdateCrusader
  PUSH HL                 ; back to walking
  EXX
SmcFallRestoreSP:
  LD SP,SmcFallRestoreSP  ; the operand is stored by B14C
UpdateCrusaderFall_0:
  PUSH BC                 ; store the state
  LD BC,JumpCurveFall     ; the curve of the fall
  JR UpdateCrusaderJump

; Entity handler: crusader stepping up (path command 1)
;
; The handler that the path command 1 puts in the slot (UpdateCrusader_Command)
; for six frames: the crusader climbs a block 8 pixels high. It is
; UpdateCrusaderHop with the fixed x speed $00A0 (CRUSADER_STEP_SPEED) and the
; curve JumpCurveStepUp (up with decreasing speed, sum -$400). Observed in room
; 5 at x = $48 and $50: y goes from $4400 to $4000 and from $4000 to $3C00.
; After the sixth frame the handler goes back to UpdateCrusader. The three jump
; handlers go on at UpdateCrusaderJump with HL = index in the curve, BC = the
; curve, DE = y and A = x.
;
; Hardware: none.
;
; SP Slot address + 2
UpdateCrusaderStepUp:
  POP BC                  ; skip +2: the speed
  POP DE                  ; skip +4: the path pointer
  POP HL                  ; x (8.8)
  LD BC,CRUSADER_STEP_SPEED ; fixed x speed of the step
  ADD HL,BC
  PUSH HL                 ; store x
  LD A,H                  ; A = x in 2-pixel units
  POP HL
  POP DE                  ; DE = y (8.8)
  POP BC                  ; BC = state: B frames left, C index in the curve
  LD L,C
  LD H,$00                ; HL = index
  INC C
  DJNZ UpdateCrusaderStepUp_0 ; not the last frame
  LD BC,CRUSADER_JUMP_FRAMES*$0100 ; the last frame: reset the state
  EXX
  LD (SmcStepRestoreSP+$0001),SP ; SP (slot + $C) for the LD SP below
  LD HL,$FFF6             ; -10: SP to slot + 2
  ADD HL,SP
  LD SP,HL
  LD HL,UpdateCrusader
  PUSH HL                 ; back to walking
  EXX
SmcStepRestoreSP:
  LD SP,SmcStepRestoreSP  ; the operand is stored by B179
UpdateCrusaderStepUp_0:
  PUSH BC                 ; store the state
  LD BC,JumpCurveStepUp   ; the curve of the step

; Crusader jump: common tail (next value of the speed curve, move, hit test)
;
; Common tail of the three jumps: BC = curve, HL = index, DE = y (8.8), A = x
; in 2-pixel units, SP = slot + $A. Adds the curve value to y and stores it,
; puts (y, x/4) in the draw command, tests the hit box and goes on at
; ReadSpriteCrusaderJump.
;
; Hardware: none.
;
; A x in 2-pixel units
; BC Speed curve (JumpCurveStepUp, JumpCurveHop or JumpCurveFall)
; DE y (8.8)
; HL Index in the curve (0-5)
; SP Slot address + $A (the jump state has just been stored)
UpdateCrusaderJump:
  ADD HL,HL               ; 2 bytes per curve value
  ADD HL,BC
  LD C,(HL)
  INC HL
  LD B,(HL)               ; BC = vertical speed
  EX DE,HL                ; HL = y
  ADD HL,BC               ; y moves
  POP BC                  ; SP slot + $C
  PUSH BC                 ; SP slot + $A again
  PUSH HL                 ; store y at slot + 8
  POP HL                  ; SP slot + $A
  POP BC                  ; SP slot + $C: the hit box words come next
  LD E,H                  ; E = y in 2-pixel units
  LD L,H                  ; L = y
  LD H,A                  ; H = x
  LD D,A                  ; D = x
  EX AF,AF'               ; A' = x: its low two bits select the shifted copy
  SRA H
  SRA H                   ; x / 4: byte column
  LD (SpriteCmdPos),HL    ; draw command position: (y, x/4)
  LD HL,ReadSpriteCrusaderJump ; where the hit test goes on
  JP HitTest              ; HitTest

; Crusader jump: read the sprite description after the hit test and draw frame
; 0
;
; Where the hit test HitTest goes on after UpdateCrusaderJump (SP at slot +
; $10, the hit box words popped). The same as ReadSpriteRight (the sprite
; description read for creatures facing right) up to the end: it puts the
; attribute, the width and the height of the sprite in the draw command and
; finds the column offset of the shift phase of x, but it does not step the
; animation counters (a crusader in the air keeps its first frame) and goes to
; the frame picker with E = 0, frame 0, instead of through StepAnimation.
;
; Hardware: none.
;
; A' x in 2-pixel units (its low two bits are the shift phase)
; SP Slot address + $10
ReadSpriteCrusaderJump:
  POP HL                  ; address of the sprite description (slot + $10)
  LD A,(HL)               ; attribute
  INC HL
  LD (SpriteCmdAttr),A    ; into the draw command
  LD C,(HL)
  INC HL
  LD B,(HL)               ; BC = shift table
  INC HL
  EX DE,HL                ; DE = description, at its height byte
  EX AF,AF'               ; A = x
  AND SPRITE_PHASE_MASK                 ; shift phase
  ADD A,A
  LD L,A
  LD H,$00
  ADD HL,BC               ; entry of the shift table
  LD A,(HL)               ; byte offset of this phase
  EX AF,AF'               ; kept in A' for the frame picker
  INC HL
  LD C,(HL)               ; width
  EX DE,HL
  LD B,(HL)               ; height
  INC HL
  LD (SpriteCmdSize),BC   ; draw command: width, height
  LD E,$00                ; frame 0
  JP SelectFrameRight     ; SelectFrameRight: the crusaders face right

; Path command 5 of the crusaders: signal the end of the cutscene, then run on
;
; Command 5 of the path scripts (PathCommands) puts this address in the slot:
; it sets the cutscene-finished flag (CutsceneDone, which the ending's frame
; loop polls) and then runs UpdateCrusader. As the handler word stays
; UpdateCrusaderEndScene, the flag is set again in every later frame. The room 25
; script ends with this command (the crusaders have reached the top of the
; stairs).
;
; Hardware: none.
;
; SP Slot address + 2 (the handler word has been popped)
UpdateCrusaderEndScene:
  LD A,$01
  LD (CutsceneDone),A     ; CutsceneDone: tell the cutscene it is over

; Entity handler: crusader running along its path script (kind 1 templates,
; path command 0)
;
; The handler of the crusaders made by the spawner UpdateCrusaderSpawner (the
; slot is a copy of a template of CrusaderTemplateRoom5; the slot words are
; described there). Every frame it moves the crusader right by its speed and
; compares the high byte of x with the target coordinate at the path pointer
; (slot word +4): the path script is a list of pairs (target x in 2-pixel
; units, command), see PathScriptRoom5. Until x equals the target the crusader
; just runs: the hit box test (HitTest) and the drawing with the next animation
; step go on at ReadSpriteRight, facing right. When x equals the target (the
; compare is for equality; the speed is below one unit a frame, so it cannot be
; skipped), the path pointer moves to the next pair and the command number is
; turned into a handler address through the table at PathCommands, which is
; written over the handler word of the slot: from the next frame the crusader
; runs a jump (commands 1, 2, 3: UpdateCrusaderStepUp, UpdateCrusaderHop,
; UpdateCrusaderFall), is removed (command 4: FreeEntitySlotAtEntry) or does
; what command 5 does, and the frame goes on as if there had been no command.
; Command 0 is this handler itself, a command that changes nothing; command 5
; is UpdateCrusaderEndScene.
;
; Slot fields used: +2 word x speed (8.8), +4 word path pointer, +6 word x
; (8.8, high byte in 2-pixel units), +8 word y; the state word +$A is skipped
; here (it belongs to the jumps); the rest is read by HitTest, ReadSpriteRight
; and StepAnimation. The path scripts have no terminator: the first two end
; with command 4 (the crusader is removed), the third with command 5, after
; which the path pointer runs into the code at UpdateHangedUp and the next
; target x would be the byte $C1 (not reached: the cutscene is over by then;
; read from the code, not run).
;
; Hardware: none.
;
; SP Slot address + 2 (the handler word has been popped)
UpdateCrusader:
  POP BC                  ; x speed
  POP DE                  ; path pointer
  POP HL                  ; x (8.8)
  ADD HL,BC
  LD A,(DE)               ; target x of the next path pair
  CP H
  JP Z,UpdateCrusader_Command ; reached: take the command
  PUSH HL                 ; PUSH then POP: stores x at slot + 6 and leaves SP
                          ; at slot + 8
  POP DE                  ; DE = x
UpdateCrusader_Draw:
  POP HL                  ; y (8.8)
  POP BC                  ; skip +$A, the jump state
  LD E,H                  ; E = y in 2-pixel units
  LD L,H                  ; L = y
  LD H,D                  ; H = x
  LD A,H
  EX AF,AF'               ; A' = x: its low two bits select the shifted copy
  SRA H
  SRA H                   ; x / 4: byte column
  LD (SpriteCmdPos),HL    ; draw command position: (y, x/4)
  LD HL,ReadSpriteRight   ; the hit test goes on with the sprite description
                          ; (facing right)
  JP HitTest              ; HitTest

; Crusader: take the next command of the path script
;
; Reached from UpdateCrusader when the high byte of x equals the target of the
; pair at the path pointer. Moves the path pointer to the next pair, writes the
; handler of the command (table PathCommands) over the handler word of the slot
; and stores x, the path pointer and the speed back, then goes on with the
; drawing of this frame at UpdateCrusader_Draw.
;
; DE Path pointer (at the target byte of the pair)
; HL x (8.8)
; BC x speed
; SP Slot address + 8
UpdateCrusader_Command:
  INC DE                  ; the command byte of the pair
  LD A,(DE)
  INC DE                  ; DE = next pair
  PUSH HL                 ; store x at slot + 6 (SP was at slot + 8) ...
  PUSH DE                 ; ... the path pointer at slot + 4 ...
  PUSH BC                 ; ... and the speed at slot + 2
  LD L,A
  LD H,$00
  ADD HL,HL
  LD DE,PathCommands      ; PathCommands
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)               ; DE = handler of the command
  PUSH DE                 ; ... and it over the handler word at slot + 0
  POP AF                  ; pop the handler word again (SP at slot + 2); AF is
                          ; not used
  POP BC                  ; BC = speed
  POP DE                  ; the path pointer
  POP DE                  ; DE = x
  JP UpdateCrusader_Draw  ; go on with this frame as if nothing had happened

; Path commands of the crusaders: 6 handler addresses
;
; Indexed by the command byte of a path script pair (PathScriptRoom5):
; UpdateCrusader_Command reads word n and writes it over the handler word of
; the slot, so the crusader runs that handler from the next frame on.
;
; 0 UpdateCrusader keep running (the handler itself: nothing changes) 1
; UpdateCrusaderStepUp step up 8 pixels (x speed $00A0, curve JumpCurveStepUp)
; 2 UpdateCrusaderHop hop over a pit (x speed $0150, curve JumpCurveHop: about
; 8 units forward, back to the same y) 3 UpdateCrusaderFall fall 16 pixels (x
; speed unchanged, curve JumpCurveFall) 4 FreeEntitySlotAtEntry remove the
; crusader (free the slot) 5 UpdateCrusaderEndScene signal the end of the
; cutscene, then keep running
PathCommands:
  DEFW UpdateCrusader     ; 0: UpdateCrusader, keep running
  DEFW UpdateCrusaderStepUp ; 1: UpdateCrusaderStepUp
  DEFW UpdateCrusaderHop  ; 2: UpdateCrusaderHop
  DEFW UpdateCrusaderFall ; 3: UpdateCrusaderFall
  DEFW FreeEntitySlotAtEntry ; 4: FreeEntitySlotAtEntry
  DEFW UpdateCrusaderEndScene ; 5: UpdateCrusaderEndScene

; Path scripts of the crusaders: pairs (target x, command)
;
; Three scripts, one per chase room, run by UpdateCrusader through the slot
; word +4 (set by the templates of CrusaderTemplateRoom5). A pair is two bytes:
; the x (high byte of the 8.8 position, 2-pixel units: x $24 is pixel column
; 72) at which the crusader carries out the command, and the command, an index
; into PathCommands. Observed in the simulator (y of a crusader every frame,
; rooms 5 and 6, room 25 by its picture): the crusaders climb the steps and hop
; the pits of the screens.
;
; Room 5 (PathScriptRoom5, from the forest to the stone block): at $48 and $50
; step up 8 pixels each (the two steps of the block), at $64 fall 16 pixels
; (off the block), at $7F (the right edge) remove the crusader. Room 6
; (PathScriptRoom6): hops at $24, $3C and $4C (the pits), steps up at $68 and
; $6C, removal at $7F. Room 25 (PathScriptRoom25, the stairs below the
; pentagram in the ending): steps up at $48, $4C, $50 and $54, then at $64
; command 5: the end of the cutscene.
PathScriptRoom5:
  DEFB $48,$01            ; step up
  DEFB $50,$01            ; step up
  DEFB $64,$03            ; fall
  DEFB $7F,$04            ; remove
PathScriptRoom6:
  DEFB $24,$02            ; hop
  DEFB $3C,$02            ; hop
  DEFB $4C,$02            ; hop
  DEFB $68,$01            ; step up
  DEFB $6C,$01            ; step up
  DEFB $7F,$04            ; remove
PathScriptRoom25:
  DEFB $48,$01            ; step up
  DEFB $4C,$01            ; step up
  DEFB $50,$01            ; step up
  DEFB $54,$01            ; step up
  DEFB $64,$05            ; end of the cutscene

; Entity handler: hanged man going up on his rope (room 9)
;
; The second half of the patrol of a hanged man of room 9 (Hangman tree). The
; first half, going down, is UpdateHangedDown (kind 6 of the room object
; table); no room record has kind 7, a slot only gets this handler through the
; turn-round in UpdateHangedDown. Entity handlers are entered with SP at slot+2
; (the RET of RunObjectSlots popped the handler word); they pop the words they
; need, push back the ones they change and end by jumping to RunObjectSlot with
; HL at the next slot.
;
; The y coordinate goes up by the speed each frame. When its high byte falls
; below the upper turning point the handler word of the slot is rewritten with
; UpdateHangedDown, so the body goes down again from the next frame. The sprite
; is placed at (x, y), then the rope is redrawn in the tile map: the cell in
; the second column of the sprite, on the row of its top edge, gets TILE_ROPE
; (a dotted red line) and the cell below it TILE_BLANK, so the rope shortens as
; the body rises. Observed in room 9: the writes at $B279/$B27F change the map
; when the body rises and UpdateHangedDown's at $B33A/$B340 when it falls. The
; tail TestEntityHitLeft tests the hit box against Jean and draws the sprite.
;
; Slot fields used: +2 word speed (8.8, 2-pixel units per frame), +4 byte upper
; turning point of y, +5 byte lower turning point, +6 word x (only the high
; byte matters; it is a multiple of 4, so the sprite never needs a shift
; phase), +8 word y (8.8). The other fields are described at ReadSpriteLeft.
;
; Hardware: none. Writes the tile map at $5B00, which the draw queue shows.
;
; SP Slot address + 2
UpdateHangedUp:
  POP BC                  ; speed
  POP DE                  ; D lower turning point, E upper
  POP HL                  ; x (8.8); only its high byte is used
  LD A,H                  ; A = x in 2-pixel units
  EX AF,AF'               ; kept in A'
  POP HL                  ; y (8.8)
  OR A
  SBC HL,BC               ; y goes up
  PUSH HL                 ; store y
  POP HL                  ; SP is back at slot+$A
  LD A,H                  ; y in 2-pixel units
  CP E                    ; above the upper turning point?
  JR NC,UpdateHangedUp_0  ; no: go on
  LD HL,$FFF8             ; -8: back to slot+2
  ADD HL,SP
  LD SP,HL
  LD HL,UpdateHangedDown  ; from the next frame the body goes down
  PUSH HL                 ; written over the handler word at slot+0
  POP HL                  ; pop the handler again
  POP BC                  ; pop speed, limits, x and y again
  POP DE
  POP HL
  POP HL
UpdateHangedUp_0:
  EX AF,AF'               ; A = x
  LD D,A                  ; D = x
  POP BC                  ; skip the unused word at +$A
  LD E,H                  ; E = y
  LD L,H                  ; L = y
  LD H,D                  ; H = x
  LD A,H
  EX AF,AF'               ; A' = x: its low two bits are the shift phase
  SRA H                   ; x / 4: byte column
  SRA H
  LD (SpriteCmdPos),HL    ; draw command position: (y, x/4)
  SRA L                   ; y / 4: row of cells
  SRA L
  LD A,L                  ; low byte of the map offset: (row mod 8) * 32 +
                          ; column
  RRCA
  RRCA
  RRCA
  LD L,A
  AND $E0
  ADD A,H
  LD H,A
  LD A,L
  AND $03                 ; high byte: row / 8
  LD L,H
  LD H,A
  INC L                   ; second column of the sprite
  LD BC,TILE_MAP
  ADD HL,BC
  LD (HL),TILE_ROPE       ; rope on the row of the top edge
  LD BC,SCREEN_COLS
  ADD HL,BC               ; the cell below
  LD (HL),TILE_BLANK      ; no rope below the end
  JR TestEntityHitLeft    ; hit box test and draw

; Entity handler: patroller moving up (kind 5)
;
; The counterpart of UpdatePatrolDown for a creature that starts its vertical
; patrol moving up (the flies of room 12, the yellow spiders of room 3; also
; every kind 4 creature, green spiders and fire wheels, after its first turn).
; The y coordinate goes up by the speed each frame; when its high byte falls
; below the upper turning point (+4) the handler word of the slot is rewritten
; with UpdatePatrolDown. The sprite is placed at (x, y) through PlaceEntityLeft,
; which tests the hit box and draws the first frame table (facing up). Stack
; scheme and slot fields as in UpdatePatrolLeft and ReadSpriteLeft.
;
; Hardware: none.
;
; SP Slot address + 2
UpdatePatrolUp:
  POP BC                  ; speed
  POP DE                  ; D lower turning point, E upper
  POP HL                  ; x (8.8); only its high byte is used
  LD A,H                  ; A = x in 2-pixel units
  EX AF,AF'               ; kept in A'
  POP HL                  ; y (8.8)
  OR A
  SBC HL,BC               ; y goes up
  PUSH HL                 ; store y
  POP HL                  ; SP is back at slot+$A
  LD A,H                  ; y in 2-pixel units
  CP E                    ; above the upper turning point?
  JR NC,UpdatePatrolUp_0    ; no: go on
  LD HL,$FFF8             ; -8: back to slot+2
  ADD HL,SP
  LD SP,HL
  LD HL,UpdatePatrolDown    ; from the next frame the creature goes down
  PUSH HL                 ; written over the handler word at slot+0
  POP HL                  ; pop the handler again
  POP BC                  ; pop speed, limits, x and y again
  POP DE
  POP HL
  POP HL
UpdatePatrolUp_0:
  EX AF,AF'               ; A = x
  LD D,A                  ; D = x
  POP BC                  ; skip the unused word at +$A
  LD E,H                  ; E = y
  JR PlaceEntityLeft      ; place the sprite, test the hit box, draw (facing
                          ; up)

; Entity handler: patroller moving left (kind 2) and the tail shared by the
; movers that go left or up
;
; The handler of every enemy that walks or flies along a horizontal line: rats
; (room 2), bats (room 8), worms (rooms 9, 14), skeletons (rooms 13, 22),
; knights (rooms 15, 20), demons (rooms 21, 22), birds (rooms 20, 23) and the
; ceiling ghosts of rooms 22 and 23. Which creature it is depends on the sprite
; description of its room record, not on the handler. A record of kind 2
; starts moving left (this handler), a record of kind 3 starts moving right
; (UpdatePatrolRight); the two handlers turn the slot into each other at the ends
; of the patrol. The first frame table faces left (observed: the rat of room 2
; moving left has its snout on the left, the one moving right on the right).
;
; Handlers of the object slots are entered with SP at slot+2 (the RET of
; RunObjectSlots popped the handler word); they pop the words they need, push
; back the ones they change and end by jumping to RunObjectSlot with HL at the
; next slot.
;
; The x coordinate goes down by the speed each frame. When its high byte equals
; the left turning point the handler word of the slot is rewritten with
; UpdatePatrolRight, so from the next frame the same speed is added. The test is
; for equality, so a creature that starts outside its patrol (or a speed that
; skips a value) runs until x has wrapped round. The sprite is placed at (x,
; y); the hit box test and the drawing go on at ReadSpriteLeft (the first frame
; table of the sprite description, the one for creatures facing left).
;
; Slot fields used: +2 word speed (8.8, 2-pixel units per frame), +4 byte left
; turning point of x, +5 byte right turning point, +6 word x (8.8; the high
; byte is in 2-pixel units, its low two bits are the shift phase of the
; sprite), +8 word y (8.8). The other fields are described at ReadSpriteLeft.
;
; Hardware: none.
;
; SP Slot address + 2
UpdatePatrolLeft:
  POP BC                  ; speed
  POP DE                  ; D right turning point, E left turning point
  POP HL                  ; x (8.8)
  OR A
  SBC HL,BC               ; x goes left
  PUSH HL                 ; store x
  POP HL                  ; SP is back at slot+8
  LD A,H                  ; x in 2-pixel units
  CP E                    ; at the left turning point?
  JR NZ,UpdatePatrolLeft_0  ; no: go on
  LD HL,$FFFA             ; -6: back to slot+2
  ADD HL,SP
  LD SP,HL
  LD HL,UpdatePatrolRight   ; from the next frame the creature goes right
  PUSH HL                 ; written over the handler word at slot+0
  POP HL                  ; pop the handler again
  POP BC                  ; pop speed, limits and x again
  POP DE
  POP HL
UpdatePatrolLeft_0:
  LD D,H                  ; D = x
  POP HL                  ; y (8.8)
  POP BC                  ; skip the unused word at +$A
  LD E,H                  ; E = y

; Place an entity sprite (facing left or up) and test its hit box
;
; Reached by falling through from UpdatePatrolLeft and by jumps from UpdatePatrolUp
; and the chaser (UpdateChaser_Draw, when Jean is on its left): movers whose
; sprite faces left or up. Puts the position into the draw command, keeps x in
; A' for the shift phase and goes on to the hit box test with the first frame
; table. E is not read here: HitTest takes the position from DE. Observed at
; every entry in rooms 2, 9, 12 and 22: SP = slot + $C, D and E the high bytes
; of the slot's x and y, H = E.
;
; Hardware: none.
;
; D x (2-pixel units)
; E y (2-pixel units, for HitTest)
; H y (2-pixel units)
; SP Slot address + $C (the hit box words come next)
PlaceEntityLeft:
  LD L,H                  ; L = y
  LD H,D                  ; H = x
  LD A,H                  ; A = x in 2-pixel units
  EX AF,AF'               ; kept in A': its low two bits are the shift phase
  SRA H                   ; x / 4: byte column
  SRA H
  LD (SpriteCmdPos),HL    ; draw command position: (y, x/4)
; Entry point used by UpdateHangedUp: the position is already in the draw
; command. D = x, E = y, A' = x, SP at slot+$C (the next words are the hit
; box). Tests the hit box against Jean and continues at ReadSpriteLeft.
TestEntityHitLeft:
  LD HL,ReadSpriteLeft
  JP HitTest              ; HitTest tests the hit box, then jumps to the
                          ; address in HL

; Entity continuation: read the sprite description and animate (frame table for
; the decreasing direction)
;
; Reached through HitTest from TestEntityHitLeft, that is from the movers that
; go left or up (UpdatePatrolLeft, UpdatePatrolUp, UpdateHangedUp) and from the
; chasing ghost (UpdateChaser) when Jean is on its left. ReadSpriteRight does
; the same for the increasing direction (right or down). SP is at slot+$10,
; after the hit box words (+$C..+$F) that HitTest popped. The routine copies
; the attribute, the width and the height of the sprite into the main draw
; command at SpriteCmd (the position is already there), picks the column offset
; for the shift phase of x, then hands over to the animation counter step
; StepAnimation with IX = SelectFrameLeft, which selects the frame, completes
; the draw command and queues it.
;
; Slot layout of the walkers (kinds 2 to 8; SpawnRoomObject builds it from the
; room record at RoomObjects: byte 2 times 4 is +2, byte 3 is +$12 and +$13,
; byte 4 is x, byte 5 is y, byte 6 is +$A and +$B, bytes 7 and 8 are +4 and +5,
; the pointer at +9 is the sprite description block): +0 word handler, +2 word
; speed (8.8 in 2-pixel units per frame), +4 byte and +5 byte turning points
; (the lower and the higher coordinate; the chasing ghost uses +5 as a start
; delay),
; +6 word x (8.8), +8 word y (8.8), +$A word not used by the walkers, +$C byte
; hit box y offset, +$D byte x offset, +$E byte y far corner, +$F byte x far
; corner (2-pixel units, both pairs relative to the position), +$10 word
; address of the sprite description (the block from its byte 5 on), +$12 byte
; animation countdown, +$13 byte countdown reload, +$14 byte frame number, +$15
; byte number of frames.
;
; Sprite description (at the end of the behaviour block of the room record, for
; example BehaviourCrusader): +0 byte attribute, +1 word address of the shift
; table (ShiftPairs: byte offset and width for each x mod 4), +3 byte height
; (2-pixel units), +4 word frame table used for creatures that face left or
; move up, +6 word frame table for right or down. A frame table holds one word
; per frame: the address in the sprite sheet SpriteSheet of the first column of
; the frame (the high byte is the page, that is the pixel row; the byte offset
; of the shift phase is added to the low byte).
;
; Hardware: none.
;
; SP Slot address + $10
; A' x in 2-pixel units (the low two bits are the shift phase)
ReadSpriteLeft:
  POP HL                  ; address of the sprite description
  LD A,(HL)               ; attribute
  INC HL
  LD (SpriteCmdAttr),A    ; into the main draw command
  LD C,(HL)               ; BC = shift table
  INC HL
  LD B,(HL)
  INC HL
  EX DE,HL                ; DE = description at its height byte
  EX AF,AF'               ; A = x
  AND SPRITE_PHASE_MASK                 ; shift phase 0-3
  ADD A,A                 ; 2 bytes per phase
  LD L,A
  LD H,$00
  ADD HL,BC               ; entry of the shift table
  LD A,(HL)               ; byte offset of this phase
  EX AF,AF'               ; kept in A' for SelectFrame
  INC HL
  LD C,(HL)               ; width
  EX DE,HL                ; HL = height byte
  LD B,(HL)               ; height; HL = the frame table pointer
  INC HL
  LD (SpriteCmdSize),BC   ; draw command: width, height
  LD IX,SelectFrameLeft   ; StepAnimation steps the animation, then jumps to IX
  JP StepAnimation

; Entity handler: hanged man going down on his rope (room 9)
;
; The hanged men of room 9 (Hangman tree, four yellow bodies on dotted red
; ropes) are entities of kind 6: this is the handler of the half of the patrol
; in which the body goes down; the other half is UpdateHangedUp (kind 7), which
; has the same body written the other way round. The y coordinate goes down by
; the speed each frame; when its high byte reaches the lower turning point the
; handler word of the slot is rewritten with UpdateHangedUp (see there for the
; stack scheme). The sprite is placed at (x, y), then the rope is redrawn in
; the tile map: the cell in the second column of the sprite on the row of its
; top edge gets TILE_ROPE and the cell below TILE_BLANK, so the rope grows
; behind the falling body. The hit box test and the drawing go on in
; ReadSpriteRight (the second frame table of the sprite description, the one
; for the increasing direction).
;
; Slot fields used: +2 word speed (8.8, 2-pixel units per frame), +4 byte upper
; turning point of y, +5 byte lower turning point, +6 word x (high byte only),
; +8 word y (8.8). The other fields are described at ReadSpriteLeft, which also
; says how SpawnRoomObject fills them from the room record.
;
; Hardware: none. Writes the tile map at $5B00, which the draw queue shows.
;
; SP Slot address + 2
UpdateHangedDown:
  POP BC                  ; speed
  POP DE                  ; D lower turning point, E upper
  POP HL                  ; x (8.8); only its high byte is used
  LD A,H                  ; A = x in 2-pixel units
  EX AF,AF'               ; kept in A'
  POP HL                  ; y (8.8)
  ADD HL,BC               ; y goes down
  PUSH HL
  POP HL                  ; store y
  LD A,H                  ; y in 2-pixel units
  CP D                    ; reached the lower turning point?
  JR C,UpdateHangedDown_0 ; no: go on
  LD HL,$FFF8             ; -8: back to slot+2
  ADD HL,SP
  LD SP,HL
  LD HL,UpdateHangedUp    ; from the next frame the body goes up
  PUSH HL                 ; written over the handler word at slot+0
  POP HL                  ; pop the handler again
  POP BC                  ; pop speed, limits, x and y again
  POP DE
  POP HL
  POP HL
UpdateHangedDown_0:
  EX AF,AF'               ; A = x
  LD D,A                  ; D = x
  POP BC                  ; skip the unused word at +$A
  LD E,H                  ; E = y
  LD L,H                  ; L = y
  LD H,D                  ; H = x
  LD A,H
  EX AF,AF'               ; A' = x: its low two bits are the shift phase
  SRA H                   ; x / 4: byte column
  SRA H
  LD (SpriteCmdPos),HL    ; draw command position: (y, x/4)
  SRA L                   ; y / 4: row of cells
  SRA L
  LD A,L                  ; low byte of the map offset: (row mod 8) * 32 +
                          ; column
  RRCA
  RRCA
  RRCA
  LD L,A
  AND $E0
  ADD A,H
  LD H,A
  LD A,L
  AND $03                 ; high byte: row / 8
  LD L,H
  LD H,A
  INC L                   ; second column of the sprite
  LD BC,TILE_MAP
  ADD HL,BC
  LD (HL),TILE_ROPE       ; rope on the row of the top edge
  LD BC,SCREEN_COLS
  ADD HL,BC               ; the cell below
  LD (HL),TILE_BLANK      ; no rope below the end
  JR TestEntityHitRight   ; hit box test and draw, second frame table

; Entity handler: patroller moving down (kind 4)
;
; The handler of the enemies that move along a vertical line: green and yellow
; spiders (rooms 3, 14, 16, 19), the flies of room 12 and the fire wheels of
; rooms 22 and 23. Which one it is depends on the sprite description of its
; room record. A record of kind 4 (the green spiders and the fire wheels)
; starts moving down (this handler), a record of kind 5 (the yellow spiders and
; the flies) starts moving up (UpdatePatrolUp); the two handlers turn the slot
; into each other at the ends of the patrol (stack scheme and slot fields as in
; UpdatePatrolLeft, ReadSpriteLeft).
;
; The y coordinate goes down by the speed each frame; when its high byte
; reaches the lower turning point (+5) the handler word of the slot is
; rewritten with UpdatePatrolUp. The sprite is placed at (x, y) through
; PlaceEntityRight (x is a multiple of 4, so the shift phase is 0), which tests
; the hit box and draws the second frame table.
;
; Slot fields used: +2 word speed (8.8, 2-pixel units per frame), +4 byte upper
; turning point of y, +5 byte lower turning point, +6 word x (high byte only),
; +8 word y (8.8).
;
; Hardware: none.
;
; SP Slot address + 2
UpdatePatrolDown:
  POP BC                  ; speed
  POP DE                  ; D lower turning point, E upper
  POP HL                  ; x (8.8); only its high byte is used
  LD A,H                  ; A = x in 2-pixel units
  EX AF,AF'               ; kept in A'
  POP HL                  ; y (8.8)
  ADD HL,BC               ; y goes down
  PUSH HL
  POP HL                  ; SP is back at slot+$A
  LD A,H                  ; y in 2-pixel units
  CP D                    ; reached the lower turning point?
  JR C,UpdatePatrolDown_0   ; no: go on
  LD HL,$FFF8             ; -8: back to slot+2
  ADD HL,SP
  LD SP,HL
  LD HL,UpdatePatrolUp      ; from the next frame the creature goes up
  PUSH HL                 ; written over the handler word at slot+0
  POP HL                  ; pop the handler again
  POP BC                  ; pop speed, limits, x and y again
  POP DE
  POP HL
  POP HL
UpdatePatrolDown_0:
  EX AF,AF'               ; A = x
  LD D,A                  ; D = x
  POP BC                  ; skip the unused word at +$A
  LD E,H                  ; E = y
  JR PlaceEntityRight     ; place the sprite, test the hit box, draw (facing
                          ; down)

; Entity handler: patroller moving right (kind 3) and the tail shared by the
; movers that go right or down
;
; The counterpart of UpdatePatrolLeft for a creature that starts its patrol
; moving right (room record kind 3: one rat of room 2, one bat of room 8 and
; one demon of room 21; every horizontal patroller listed there after its first
; turn). The x coordinate goes up by the
; speed each frame; when its high byte equals the right turning point the
; handler word of the slot is rewritten with UpdatePatrolLeft, so from the next
; frame the speed is subtracted. The position goes into the draw command, then
; ReadSpriteRight tests the hit box and draws the second frame table of the
; sprite description (creatures facing right). The slot fields are those of
; UpdatePatrolLeft and ReadSpriteLeft.
;
; Hardware: none.
;
; SP Slot address + 2
UpdatePatrolRight:
  POP BC                  ; speed
  POP DE                  ; D right turning point, E left turning point
  POP HL                  ; x (8.8)
  ADD HL,BC               ; x goes right
  PUSH HL                 ; store x
  POP HL                  ; SP is back at slot+8
  LD A,H                  ; x in 2-pixel units
  CP D                    ; at the right turning point?
  JR NZ,UpdatePatrolRight_0 ; no: go on
  LD HL,$FFFA             ; -6: back to slot+2
  ADD HL,SP
  LD SP,HL
  LD HL,UpdatePatrolLeft    ; from the next frame the creature goes left
  PUSH HL                 ; written over the handler word at slot+0
  POP HL                  ; pop the handler again
  POP BC                  ; pop speed, limits and x again
  POP DE
  POP HL
UpdatePatrolRight_0:
  LD D,H                  ; D = x
  POP HL                  ; y (8.8)
  POP BC                  ; skip the unused word at +$A
  LD E,H                  ; E = y

; Place an entity sprite (facing right or down) and test its hit box
;
; Reached by falling through from UpdatePatrolRight and by jumps from
; UpdatePatrolDown and the chaser (UpdateChaser_Draw, when Jean is level with it
; or on its right): movers whose sprite faces right or down. Puts the position
; into the draw command, keeps x in A' and goes on to the hit box test with the
; second frame table. E is not read here: HitTest takes the position from DE.
; Observed at every entry in rooms 2, 9, 11, 12 and 22: SP = slot + $C, D and E
; the high bytes of the slot's x and y, H = E.
;
; Hardware: none.
;
; D x (2-pixel units)
; E y (2-pixel units, for HitTest)
; H y (2-pixel units)
; SP Slot address + $C (the hit box words come next)
PlaceEntityRight:
  LD L,H                  ; L = y
  LD H,D                  ; H = x
  LD A,H                  ; A = x in 2-pixel units
  EX AF,AF'               ; kept in A': its low two bits are the shift phase
  SRA H                   ; x / 4: byte column
  SRA H
  LD (SpriteCmdPos),HL    ; draw command position: (y, x/4)
; Entry point used by UpdateHangedDown: the position is already in the draw
; command. D = x, E = y, A' = x, SP at slot+$C (the next words are the hit
; box). Tests the hit box against Jean and continues at ReadSpriteRight.
TestEntityHitRight:
  LD HL,ReadSpriteRight
  JP HitTest              ; HitTest tests the hit box, then jumps to the
                          ; address in HL

; Entity handler: runner of the intro screen (kind 0), and the sprite
; continuation for the increasing direction
;
; Room 0 (the intro text, "The Cathar Jean Raymond runs to escape the
; crusaders...") has four entities of this kind: the monk (sprite description
; BehaviourJean; as it runs right it is drawn from the second table,
; MonkFramesRight, frames 0 and 1: Jean's walk) and three cyan crusaders
; (BehaviourCrusader) running after him. The slot is entered
; with SP at slot+2 (see UpdatePatrolLeft for the stack scheme). The x coordinate
; goes up by the speed each frame; when its high byte equals the end coordinate
; (+5, $80, off the right of the screen) the slot is freed through
; FreeEntitySlot. x starts at a value below 0 ($CB-$F7: the runner enters from
; the left), and the compare is for equality. There is no hit box: the three
; words +$A..+$F are skipped. The sprite goes on at ReadSpriteRight.
;
; Slot fields used: +2 word speed (8.8, 2-pixel units per frame), +5 byte end
; x, +6 word x (8.8), +8 word y (8.8); the sprite fields are described at
; ReadSpriteLeft.
;
; Hardware: none.
;
; SP Slot address + 2
UpdateIntroRunner:
  POP BC                  ; speed
  POP DE                  ; D end x, E not used
  POP HL                  ; x (8.8)
  ADD HL,BC               ; x goes right
  PUSH HL                 ; store x
  POP HL                  ; SP is back at slot+8
  LD A,H                  ; x in 2-pixel units
  CP D                    ; at the end?
  JP Z,FreeEntitySlot     ; yes: free the slot
  LD D,H                  ; D = x
  POP HL                  ; y (8.8)
  LD E,H                  ; E = y
  LD L,E                  ; L = y
  LD H,D                  ; H = x
  LD A,H                  ; A = x in 2-pixel units
  EX AF,AF'               ; kept in A': its low two bits are the shift phase
  SRA H                   ; x / 4: byte column
  SRA H
  LD (SpriteCmdPos),HL    ; draw command position: (y, x/4)
  POP BC                  ; skip the words at +$A, +$C and +$E: no hit box
  POP BC
  POP BC

; Read the sprite description and animate (facing right or down)
;
; Entry point used through HitTest by UpdatePatrolRight, UpdateHangedDown,
; UpdatePatrolDown, the chasing ghost (UpdateChaser, Jean level with it or on its
; right) and the walking crusaders (UpdateCrusader_Draw), and by
; UpdateIntroRunner, which falls into it without a hit test. Like
; ReadSpriteLeft, but picks the second frame table. Observed in rooms 2, 9 and
; 11: SP = slot + $10 and A' = the high byte of the slot's x at every entry.
;
; Hardware: none.
;
; A' x in 2-pixel units (the low two bits are the shift phase)
; SP Slot address + $10
ReadSpriteRight:
  POP HL                  ; address of the sprite description
  LD A,(HL)               ; attribute
  INC HL
  LD (SpriteCmdAttr),A    ; into the main draw command
  LD C,(HL)               ; BC = shift table
  INC HL
  LD B,(HL)
  INC HL
  EX DE,HL                ; DE = description at its height byte
  EX AF,AF'               ; A = x
  AND SPRITE_PHASE_MASK                 ; shift phase 0-3
  ADD A,A                 ; 2 bytes per phase
  LD L,A
  LD H,$00
  ADD HL,BC               ; entry of the shift table
  LD A,(HL)               ; byte offset of this phase
  EX AF,AF'               ; kept in A' for SelectFrame
  INC HL
  LD C,(HL)               ; width
  EX DE,HL                ; HL = height byte
  LD B,(HL)               ; height; HL = the frame table pointer
  INC HL
  LD (SpriteCmdSize),BC   ; draw command: width, height
  LD IX,SelectFrameRight  ; the second frame table: SelectFrameRight skips the
                          ; first
  JP StepAnimation        ; StepAnimation steps the animation, then jumps to IX

; Entity sprite: pick the frame from a frame table and queue the draw command
;
; The end of the sprite part of most entity handlers. StepAnimation has just
; stepped the animation counters and jumped here (IX) with HL at the frame
; table pointer words of the sprite description (see ReadSpriteLeft):
; SelectFrameRight skips the first one and takes the second (creatures facing
; right or down), SelectFrameLeft takes the first. Both continue at
; SelectFrame, which adds the frame number to the table address, reads the
; frame's sprite sheet address, adds the byte offset of the shift phase to its
; low byte and stores the result in the main draw command (SpriteCmd, graphics
; word at SpriteCmdGfx). Then, unless the frame list is being run (QueueDrawCmd
; holds RET), the ten bytes of the draw command are copied to the frame call
; list at the write pointer FrameListPtr (through QueueOneCommand) and the
; handler goes on with the next slot (NextSlotAfterAnim).
;
; Hardware: none.
;
; HL Address of the first of the two frame table pointer words of the sprite
;    description
; E Frame number
; A' Byte offset of the shift phase, from the shift table
; SP Slot address + $12 (the animation counters have been pushed back)
SelectFrameRight:
  INC HL                  ; skip the pointer of the first frame table
  INC HL
; Entry point of the first frame table (creatures facing left or up), reached
; through IX from ReadSpriteLeft and through IY from UpdateStoneHead,
; UpdateArcher (Jean on its left) and UpdateDeathLeft. SelectFrameRight is
; reached through IX from ReadSpriteRight, by a jump from
; ReadSpriteCrusaderJump and through IY from UpdateArcher and UpdateDeathRight.
SelectFrameLeft:
  LD A,(HL)               ; HL = frame table (word array)
  INC HL
  LD H,(HL)
  LD L,A

; Select an entity's frame
;
; Entry point used by QueueFrameSprite (the plants and the fish),
; UpdateBeastHead and QueueMovingSprite, which have their own frame table in
; HL: HL = frame table, E = frame number, A' = shift byte offset. It goes on
; through QueueEntitySprite to NextSlotAfterAnim, so SP must be at slot + $12
; (observed at every entry in rooms 10, 14, 16, 17, 18, 19 and 20).
;
; Hardware: none.
;
; HL Frame table
; E Frame number
; A' Shift byte offset
; SP Slot address + $12
SelectFrame:
  LD D,$00                ; DE = frame number
  ADD HL,DE               ; HL = address of the frame word
  ADD HL,DE
  EX AF,AF'               ; A = shift byte offset
  ADD A,(HL)              ; add the low byte of the frame address
  INC HL
  LD H,(HL)               ; H = sprite sheet page of the frame
  LD L,A
  LD (SpriteCmdGfx),HL    ; draw command: graphics address

; Queue an entity's sprite
;
; Entry point used by SetProjectileSprite and UpdateSplash, which have set the
; graphics address themselves: queue the main draw command. SP is at slot +
; $12, as for SelectFrame.
QueueEntitySprite:
  LD A,(QueueDrawCmd)     ; the frame list is being run?
  OR A
  JR NZ,NextSlotAfterAnim ; yes: do not queue, go on with the next slot
  LD HL,SpriteCmd         ; draw command to copy
  LD DE,(FrameListPtr)    ; write pointer of the frame call list
  JR QueueOneCommand      ; copy the 10 bytes of the main command

; Queue one or two draw commands of an entity and go on with the next slot
;
; Copies draw commands (10 bytes each: routine word, y, x/4, graphics word,
; width, height, unused, attribute; see SpriteCmd) from HL to the end of the
; frame call list at DE and stores the new end in FrameListPtr.
; QueueTwoCommands copies two commands in a row (20 bytes: the commands at
; SpriteCmd and SpriteCmd2, used by the entities that draw two sprites: the
; falling drop, through IY from UpdateDropFalling and AnimateDrop, and by jumps
; from the Beast's fire jet (UpdateBeastFire_Draw) and from Satan and his smoke
; (QueueTwoPartSprite)), QueueOneCommand copies one. Both fall through to
; NextSlotAfterAnim, which ends every entity handler that has pushed back its
; animation counters: it sets HL to the slot after the current one and jumps
; to RunObjectSlot.
;
; Hardware: none.
;
; HL Address of the first draw command (SpriteCmd)
; DE Write pointer of the frame call list (the value of FrameListPtr)
; SP Slot address + $12
QueueTwoCommands:
  LDI                     ; the main command ...
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI                     ; ... 10 bytes
  LDI                     ; and then the second command (10 bytes)

; Queue one draw command
;
; Entry point used by QueueEntitySprite (the end of SelectFrame) and, through
; IY, by the hanging water drop (UpdateDropHanging, AnimateDrop): copy one
; command, 10 bytes.
QueueOneCommand:
  LDI                     ; 10 bytes
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LD (FrameListPtr),DE    ; new end of the frame call list

; Go to the next slot after the animation step
;
; Entry point used by every entity handler that has pushed back its animation
; counters, by the frame queueing code when the frame list is being run
; (QueueEntitySprite, AnimateDrop, UpdateBeastFire_Draw, QueueTwoPartSprite)
; and by the crusader spawner, which draws nothing (UpdateCrusaderSpawner,
; SpawnCrusader): go on with the next slot. SP is at slot+$12 (observed at
; every entry in rooms 10, 14, 16, 17, 18, 19, 20 and 24).
;
; Hardware: none.
;
; SP Slot address + $12
NextSlotAfterAnim:
  LD HL,SLOT_SIZE-$12     ; slot+$12 + 4 = the next slot
  ADD HL,SP
  JP RunObjectSlot        ; RunObjectSlot enters the handler of the slot at HL

; Free the slot of an entity
;
; The same code as FreeSlot, kept for the entity handlers: SP goes back to
; slot+2, the handler word at slot+0 is zeroed (the slot is free; RunObjectSlot
; skips such a slot from now on) and the walker goes on with the slot after
; this one. Used by the intro runner UpdateIntroRunner when it has run off the
; screen and by the flame UpdateMovingSprite.
;
; Hardware: none.
;
; SP Slot address + 8
FreeEntitySlot:
  LD HL,$FFFA             ; -6: back to slot+2
  ADD HL,SP
  LD SP,HL
  LD HL,$0000             ; handler = 0
  PUSH HL                 ; written over the handler word at slot+0
  LD HL,SLOT_SIZE         ; the next slot
  ADD HL,SP
  JP RunObjectSlot        ; RunObjectSlot enters the handler of the slot at HL

; Chasing ghost: face Jean, then hit box test and draw
;
; The second half of UpdateChaser, entered at UpdateChaser_Draw after the
; chaser has moved (or at UpdateChaser_Wait while its start delay still runs).
; It takes x and y from the slot, chooses the sprite that looks toward Jean
; (Jean's x, A8A2, below the chaser's x: the first frame table, through
; PlaceEntityLeft; otherwise the second one through PlaceEntityRight; a Jean x
; with bit 7 set counts as 0) and goes on with the common tail that puts the
; position into the draw command, tests the hit box and draws. See
; ReadSpriteLeft for the slot fields.
;
; Hardware: none.
;
; BC Slot bytes +4 and +5 with the start delay in B already decremented (only
;    at UpdateChaser_Wait: written back first)
; SP Slot address + 6
UpdateChaser_Wait:
  PUSH BC                 ; store the countdown
  POP BC                  ; SP is back at slot+6
; Entry point used by UpdateChaser after it has moved the chaser: x and y are
; already stored. SP is at slot+6.
UpdateChaser_Draw:
  POP DE                  ; D = x
  POP HL                  ; H = y
  LD E,H                  ; E = y
  POP AF                  ; skip the word at +$A
  LD A,(PlayerX+$0001)    ; Jean's x
  BIT 7,A                 ; x of $80 or more is negative: counts as 0
  JR Z,UpdateChaser_Wait_0
  XOR A
UpdateChaser_Wait_0:
  CP D                    ; Jean on the left of the chaser?
  JP C,PlaceEntityLeft    ; yes: face left
  JP PlaceEntityRight     ; no: face right

; Entity handler: the chasing ghost (kind 8, room 11)
;
; The chasing ghost, a cyan grinning head that floats through the Cave of
; illusions (room 11; the only room record of kind 8). After a start delay it
; moves toward Jean along both axes, through free space only, then faces Jean
; and is drawn (the tail UpdateChaser_Wait/UpdateChaser_Draw). Entered with SP
; at slot+2, see UpdatePatrolLeft for the stack scheme.
;
; The start delay is the byte at slot+5 (30 frames in the room record): each
; frame it is decremented and, until it reaches 0, the handler only draws the
; sprite (UpdateChaser_Wait). After that the byte is reset to 1, so that it
; drops to 0 on every following frame. The movement then works in four steps.
; First, the tile flag map is sampled around the sprite, which is 2 cells wide
; and 3 high at (x/4, y/4): the flags of the two cells of its own top row
; (ProbeHead; not the row above it, unlike the other three sides), of the two
; cells right of rows 1 and 2 (ProbeRight), of the two cells under the bottom
; row (ProbeBelow) and of the two cells left of rows 1 and 2 (ProbeLeft) are
; ORed in pairs (ProbeRight-ProbeHead) and a side counts as free when its class
; (flag AND 7) is 0. Second, Jean's x and y (A8A2, A8A4; bit 7 set counts as 0)
; are compared with the chaser's; each compare gives 0 (equal), 1 (Jean is
; smaller: left or above) or 2 (greater: right or below), and the two codes are
; shifted into A' (whatever A' held before only reaches the bits above the low
; nibble) and make a 4-bit move mask (x code in bits 3-2, y code in bits 1-0).
; Third, the mask is ANDed with the free sides (bit 3 right, bit 2 left, bit 1
; below, bit 0 above). Last, the speed is subtracted from or added to y for
; bits 0 and 1 and to x for bits 2 and 3, so each axis is blocked separately
; (the ghost slides along a wall: it does not move toward a side whose probed
; cells are not class 0), and it does not move on an axis on which it is level
; with Jean. Observed in room 11 with Jean at x = $70, y = $40: after the delay
; the face moved diagonally from (x $40, y $24), 0.25 unit per frame on each
; axis.
;
; Slot fields used: +2 word speed (8.8, $0040 = 0.25 unit of 2 pixels per
; frame), +5 byte start delay, +6 word x (8.8), +8 word y (8.8); the sprite
; fields are described at ReadSpriteLeft. Hit box and drawing as for the
; walkers.
;
; Hardware: reads the tile flag map (through FlagRowTable) and writes the four
; probe bytes ProbeRight-ProbeHead.
;
; SP Slot address + 2
UpdateChaser:
  POP DE                  ; skip the speed (read again at B4B3)
  POP BC                  ; B = start delay
  DJNZ UpdateChaser_Wait  ; delay still running: only draw
  INC B                   ; the delay stays at 1 from now on
  PUSH BC                 ; store it
  POP AF                  ; SP is back at slot+6
  POP DE                  ; x (8.8)
  POP HL                  ; y (8.8)
  SRA H                   ; y / 2
  RES 0,H                 ; 2 * row of cells (row = y / 4)
  LD L,H                  ; L = offset into the row address table
  LD H,FlagRowTable/$100
  LD A,D                  ; x / 4: column of cells
  RRA
  RRA
  AND $1F
  ADD A,(HL)              ; row address (low) + column
  INC L
  LD H,(HL)               ; row address (high)
  LD L,A                  ; HL = flag map cell of the top left corner
  LD A,(HL)               ; top row, left cell
  INC HL
  OR (HL)                 ; OR the right cell
  LD (ProbeHead),A        ; ProbeHead
  LD BC,SCREEN_COLS+$0001 ; row 1, two columns right of the corner
  ADD HL,BC
  LD A,(HL)
  DEC BC
  ADD HL,BC               ; row 2
  OR (HL)
  LD (ProbeRight),A       ; ProbeRight
  DEC BC                  ; row 3, one column right of the corner
  ADD HL,BC
  LD A,(HL)
  DEC HL
  OR (HL)
  LD (ProbeBelow),A       ; ProbeBelow
  INC BC                  ; row 2, one column left of the corner
  INC BC
  SBC HL,BC
  LD A,(HL)
  DEC BC
  SBC HL,BC               ; row 1
  OR (HL)
  LD (ProbeLeft),A        ; ProbeLeft
  LD BC,TILE_CLASS_MASK*$0100 ; B = class mask, C collects the free bits
  LD HL,ProbeRight        ; the four probes: right, left, below, head
  LD A,(HL)               ; tile class of the side
  AND B
  CP $01                  ; carry when the class is 0 (free)
  RL C                    ; shift the free bit into C
  INC HL
  LD A,(HL)
  AND B
  CP $01
  RL C
  INC HL
  LD A,(HL)
  AND B
  CP $01
  RL C
  INC HL
  LD A,(HL)
  AND B
  CP $01
  RL C
  LD A,C                  ; C = free sides: bit 3 right, 2 left, 1 below, 0
                          ; above
  EXX                     ; keep them in C'
  LD C,A
  EXX
  LD HL,$FFF8             ; -8: back to slot+2
  ADD HL,SP
  LD SP,HL
  POP BC                  ; speed
  POP HL                  ; skip the countdown word
  POP HL                  ; x (8.8)
  POP DE                  ; y (8.8)
  LD A,(PlayerX+$0001)    ; Jean's x
  BIT 7,A
  JR Z,UpdateChaser_0
  XOR A                   ; negative counts as 0
UpdateChaser_0:
  CP H                    ; compare with the chaser's x
  JR C,UpdateChaser_1     ; Jean is on the left: code 1
  JR Z,UpdateChaser_2     ; level: code 0
  EX AF,AF'               ; Jean is on the right: code 2
  ADD A,A
  INC A
  ADD A,A
  EX AF,AF'
  JR UpdateChaser_3
UpdateChaser_1:
  EX AF,AF'               ; code 1: shift the code in
  ADD A,A
  ADD A,A
  INC A
  EX AF,AF'
  JR UpdateChaser_3
UpdateChaser_2:
  EX AF,AF'               ; code 0
  ADD A,A
  ADD A,A
  EX AF,AF'
UpdateChaser_3:
  EX DE,HL                ; HL = y, DE = x
  LD A,(PlayerY+$0001)    ; Jean's y
  BIT 7,A
  JR Z,UpdateChaser_4
  XOR A
UpdateChaser_4:
  CP H                    ; compare with the chaser's y
  JR C,UpdateChaser_5     ; Jean is above: code 1
  JR Z,UpdateChaser_6     ; level: code 0
  EX AF,AF'               ; Jean is below: code 2
  ADD A,A
  INC A
  ADD A,A
  JR UpdateChaser_7
UpdateChaser_5:
  EX AF,AF'               ; code 1
  ADD A,A
  ADD A,A
  INC A
  JR UpdateChaser_7
UpdateChaser_6:
  EX AF,AF'               ; code 0
  ADD A,A
  ADD A,A
UpdateChaser_7:
  EXX                     ; move mask AND free sides
  LD B,A
  AND C
  EXX
  RRA                     ; bit 0: above
  JR NC,UpdateChaser_8
  OR A                    ; y goes up
  SBC HL,BC
UpdateChaser_8:
  RRA                     ; bit 1: below
  JR NC,UpdateChaser_9
  ADD HL,BC               ; y goes down
UpdateChaser_9:
  EX DE,HL                ; HL = x, DE = y
  RRA                     ; bit 2: left
  JR NC,UpdateChaser_10
  OR A                    ; x goes left
  SBC HL,BC
UpdateChaser_10:
  RRA                     ; bit 3: right
  JR NC,UpdateChaser_11
  ADD HL,BC               ; x goes right
UpdateChaser_11:
  EX DE,HL                ; HL = y, DE = x
  PUSH HL                 ; store y
  PUSH DE                 ; store x
  JP UpdateChaser_Draw    ; face Jean and draw

; Entity handler: water drop hanging from a stalactite (kind 9, rooms 15 and
; 19)
;
; The cyan drops that form at the tip of the stalactites of Gloomy tunnels
; (room 15) and Underground river (room 19), swell and fall. A drop cycles
; through two handlers: this one while it hangs and UpdateDropFalling while it
; falls. Entered with SP at slot+2, see UpdatePatrolLeft for the stack scheme.
; Slot fields used: +4 byte y of the stalactite tip, +7 byte x, +$B byte start
; delay; the whole layout is at AnimateDrop.
;
; The start delay (byte +$B, the fifth parameter of the room record: $0B-$3D
; frames, so that the drops of a room do not fall together) is decremented each
; frame and written back while it is nonzero; the drop is neither drawn nor
; tested until it reaches 0. From then on it stays 1 (the decrement leaves 0
; and the zero is not stored) and each frame the drop is placed at the tip
; (x/4, y of the tip) and drawn with a single draw command (IY =
; QueueOneCommand, the hanging drop of the sprite description), without a hit
; box test (the two hit box words +$C..+$F are skipped), and AnimateDrop counts
; the animation down.
;
; Hardware: none.
;
; SP Slot address + 2
UpdateDropHanging:
  POP BC                  ; skip the speed
  POP DE                  ; E = y of the tip, D = y where the fall ends
  POP HL                  ; H = x
  LD D,H                  ; D = x
  POP HL                  ; skip y
  POP AF                  ; A = start delay
  DEC A
  JR Z,UpdateDropHanging_0 ; over: draw the drop
  PUSH AF                 ; store the decremented delay
  LD HL,SLOT_SIZE-$A      ; SP is slot+$A: not drawn, next slot
  ADD HL,SP
  JP RunObjectSlot        ; RunObjectSlot enters the handler of the slot at HL
UpdateDropHanging_0:
  LD H,D                  ; H = x
  LD L,E                  ; L = y of the tip
  SRA H                   ; x / 4: byte column
  SRA H
  LD (SpriteCmdPos),HL    ; draw command position: (y, x/4)
  POP HL                  ; skip the hit box
  POP HL
  LD IY,QueueOneCommand   ; queue one draw command
  JR AnimateDrop          ; animate and queue

; Entity handler: water drop falling (kind 9, rooms 15 and 19)
;
; The falling half of the water drop cycle (the hanging half is
; UpdateDropHanging; AnimateDrop starts the fall after 70 frames). The y
; coordinate goes down by the speed (1 unit of 2 pixels per frame); when its
; high byte reaches the end of the fall (slot +5) the handler word of the slot
; is rewritten with UpdateDropHanging and the drop hangs again. Two sprites are
; drawn: the drop at the stalactite tip (main draw command at y = slot+4, as in
; UpdateDropHanging) and the falling drop (second draw command at SpriteCmd2,
; position (y, x/4) with the current y), so IY = QueueTwoCommands queues two
; commands. The falling drop is tested against Jean's hit box through HitTest
; (DE = x, y), which continues at AnimateDrop. Observed in room 15: y goes from
; $2C to $3C in 16 frames, one unit per frame; the cycle of 70 frames is
; counted by AnimateDrop.
;
; Hardware: none.
;
; SP Slot address + 2
UpdateDropFalling:
  POP BC                  ; speed
  POP DE                  ; D = y where the fall ends, E = y of the tip
  POP HL                  ; x (8.8)
  LD A,H                  ; A = x
  EX AF,AF'               ; kept in A'
  POP HL                  ; y (8.8)
  ADD HL,BC               ; the drop falls
  PUSH HL
  POP HL                  ; SP is back at slot+$A
  LD A,H                  ; y in 2-pixel units
  CP D                    ; the end of the fall?
  JR C,UpdateDropFalling_0 ; not yet
  LD HL,$FFF8             ; -8: back to slot+2
  ADD HL,SP
  LD SP,HL
  LD HL,UpdateDropHanging ; from the next frame the drop hangs again
  PUSH HL                 ; written over the handler word at slot+0
  POP HL                  ; pop the handler again
  POP BC                  ; pop speed, limits, x and y again
  POP DE
  POP HL
  POP HL
UpdateDropFalling_0:
  EX AF,AF'               ; A = x
  LD D,A                  ; D = x
  POP BC                  ; skip the word at +$A
  LD C,E                  ; C = y of the tip
  LD E,H                  ; E = y
  LD L,H                  ; L = y
  LD H,D                  ; H = x
  LD A,H
  EX AF,AF'               ; A' = x
  SRA H                   ; x / 4: byte column
  SRA H
  LD (SpriteCmd2Pos),HL   ; second draw command: position (y, x/4) of the
                          ; falling drop
  LD L,C                  ; L = y of the tip
  LD (SpriteCmdPos),HL    ; main draw command: position (y of the tip, x/4)
  LD IY,QueueTwoCommands  ; queue both commands
  LD HL,AnimateDrop       ; after the hit box test: AnimateDrop
  JP HitTest              ; HitTest tests the hit box of the falling drop, then
                          ; jumps to HL

; Water drop: sprite description, animation countdown, start of the fall, then
; queue the sprites
;
; The continuation of UpdateDropHanging (jumped to, IY = QueueOneCommand) and
; of UpdateDropFalling (through HitTest, IY = QueueTwoCommands) for the water
; drops (kind 9). SP is at slot+$10, so the next words of the slot are the
; sprite description pointer and the animation words. It fills the draw
; commands from the sprite description, counts the cycle of the drop down and
; queues the commands through IY.
;
; Slot layout of the drops (made by SpawnRoomObject from the room record; byte
; 3 of the record is the cycle length): +0 word handler (UpdateDropHanging or
; UpdateDropFalling), +2 word speed of the fall (8.8, $0100 = 1 unit of 2
; pixels per frame), +4 byte y of the stalactite tip (copy of the record's y),
; +5 byte y where the fall ends, +6 word x (8.8; high byte a multiple of 4), +8
; word y (8.8), +$A byte not used, +$B byte start delay (UpdateDropHanging),
; +$C..+$F hit box (y offset, x offset, y far corner, x far corner, relative to
; the position), +$10 word sprite description, +$12 byte cycle countdown (70
; frames, DROP_PERIOD), +$13 byte its reload, +$14 byte frame number (0, or 1
; for the last 30 frames of the cycle), +$15 byte number of frames.
;
; Sprite description of the drops (94E8, after the 5-byte hit box and frame
; count header of the block BehaviourDrop): +0 byte attribute (used for both
; sprites), +1 byte height of the falling drop (2-pixel units; the width of
; both sprites is 2 cells and the height of the hanging drop is 2), +2 word
; graphics of the hanging drop for frame 0, +4 word for frame 1, +6 word
; graphics of the falling drop.
;
; The cycle countdown goes down by one per frame (also during the fall,
; AnimateDrop is run by both handlers). At $1E (30 frames before the end) the
; hanging drop switches to frame 1 (it swells). At 0 the fall begins: SP is
; saved in the operand of the LD SP at SmcDropSP and moved back to slot+2, the
; handler word becomes UpdateDropFalling, y is reset to the tip, SP is
; restored, the frame number goes back to 0 and the countdown is reloaded with
; 70. Observed in room 15: the countdown goes from $46 to 1 in 70 frames and
; the fall begins at the next one.
;
; Hardware: none.
;
; IY Address that queues the draw commands: QueueOneCommand (one) or
;    QueueTwoCommands (two)
; SP Slot address + $10
AnimateDrop:
  POP HL                  ; address of the sprite description
  LD A,(HL)               ; attribute
  INC HL
  LD (SpriteCmdAttr),A    ; main draw command
  LD (SpriteCmd2Attr),A   ; second draw command
  LD B,(HL)               ; height of the falling drop
  INC HL
  LD C,$02                ; width: 2 cells
  LD (SpriteCmd2Size),BC  ; second draw command: width, height
  LD B,C                  ; main draw command height 2 ...
  LD (SpriteCmdSize),BC   ; ... width 2
  POP BC                  ; C = cycle countdown, B = reload
  POP DE                  ; E = frame number, D = number of frames
  DEC C                   ; cycle over?
  JR NZ,AnimateDrop_0     ; no
  LD B,DROP_PERIOD        ; reload value
  EXX                     ; alternate registers as scratch
  LD (SmcDropSP+$0001),SP ; save SP in the operand of the LD SP at SmcDropSP
  LD HL,$FFEC             ; -$14: back to slot+2
  ADD HL,SP
  LD SP,HL
  LD HL,UpdateDropFalling ; the drop falls from the next frame on
  PUSH HL                 ; written over the handler word at slot+0
  POP HL                  ; pop the handler again
  POP BC                  ; speed
  POP DE                  ; E = y of the tip, D = end of the fall
  POP HL                  ; x
  POP HL                  ; y
  LD H,E                  ; y := y of the tip
  PUSH HL                 ; store y
SmcDropSP:
  LD SP,$B59F             ; the operand is written by B58B: SP back at slot+$16
  EXX                     ; main registers again: B = reload
  LD E,C                  ; E = 0: frame 0
  LD C,B                  ; C = reload: the countdown starts again
  JR AnimateDrop_1
AnimateDrop_0:
  LD A,C                  ; countdown value
  CP DROP_SWELL
  JR NZ,AnimateDrop_1
  INC E                   ; frame 1 for the last 30 frames
AnimateDrop_1:
  PUSH DE                 ; store the frame number and the countdown
  PUSH BC
  LD D,$00                ; DE = frame number
  EX DE,HL                ; HL = frame number, DE = address of the graphics
                          ; words
  ADD HL,HL
  ADD HL,DE               ; HL = DE + 2 * frame
  LD C,(HL)               ; graphics of the hanging drop
  INC HL
  LD B,(HL)
  LD (SpriteCmdGfx),BC    ; main draw command: graphics
  LD HL,$0004
  ADD HL,DE               ; the third word: graphics of the falling drop
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  LD (SpriteCmd2Gfx),HL   ; second draw command: graphics
  LD A,(QueueDrawCmd)     ; frame list being run: do not queue
  OR A
  JP NZ,NextSlotAfterAnim ; go on with the next slot
  LD HL,SpriteCmd         ; first draw command
  LD DE,(FrameListPtr)    ; write pointer of the frame call list
  JP (IY)                 ; QueueOneCommand or QueueTwoCommands copies the
                          ; commands

; Entity handler: stone head in the wall that shoots arrows (kind 11, rooms 20
; and 22)
;
; The stone head set into the right-hand wall of Unexpected gate (room 20, at x
; = $6C, y = $0C) and Tortured souls (room 22, at x = $70, y = $34). It does
; not move: the handler takes its position, makes it the position of the shot
; to be created (SPAWN_POSITION, $5DFE: the (y, x) half of the 4-byte record
; built at $5DFC) and prepares the arguments of the shared tail
; UpdateShooter_Common of the archer UpdateArcher: after an EXX (the position
; stays in the other HL) the template of the shot in HL (WallShotTemplate, the
; arrow flying left, UpdateArrow) and IY = SelectFrameLeft, the first frame
; table. The tail puts the position into
; the draw command and tests the hit box; the continuation UpdateShooter_Tail
; counts the shot cycle down (70 frames: the head fires when the countdown
; reaches 0) and queues the arrow, animates and draws the head. Observed in
; room 20: a slot with handler UpdateArrow, x speed $FE00, appears at x = $6A
; next to the head every 70 frames and flies left.
;
; Slot fields used: +6 word x (high byte), +8 word y (high byte); the speed and
; the turning points are not used. The sprite description is of another kind
; than the walkers' (see UpdateShooter_Tail).
;
; Hardware: none.
;
; SP Slot address + 2
UpdateStoneHead:
  POP BC                  ; skip the speed
  POP BC                  ; skip the words at +4
  POP HL                  ; x (8.8)
  LD D,H                  ; D = x
  POP HL                  ; y (8.8)
  LD E,H                  ; E = y
  LD H,D                  ; H = x
  LD L,E                  ; L = y
  LD (SPAWN_POSITION),HL  ; position of the shot
  EXX                     ; alternate registers: template of the shot ...
  LD IY,SelectFrameLeft   ; first frame table (the head faces left)
  LD HL,WallShotTemplate  ; ... the arrow flying left
  JR UpdateShooter_Common ; tail of the archer UpdateArcher

; Entity handler: skeleton archer (rooms 17 and 21)
;
; The skeleton archers of "The wheel of faith" (room 17, three of them) and
; "Evil church" (room 21, one): handler of room object kind 10 (EntityHandlers,
; behaviour block BehaviourArcher). They stand still, face the monk, aim and
; throw an arrow every 80 frames; an arrow that touches the monk kills him
; (observed in room 17), and the archer's own hit box is tested the same way.
; Entity handlers are not called: the slot walker RunObjectSlots sets SP to a
; slot of ObjectSlots and RETs, so the handler is entered with SP at slot+2 and
; finds its state on the stack.
;
; Slot (the layout of the room enemies made by SpawnRoomObject): +2 and +4
; words not used, +6 word x and +8 word y (8.8, high bytes in 2-pixel units),
; +$A word not used (popped and dropped), +$C word hit box offset (y, x), +$E
; word hit box far corner (y, x), +$10 pointer to the sprite block (attribute,
; height, width, then a pointer to the frame table for facing left and one for
; facing right, 2 frames each), +$12 byte shot countdown and +$13 its reload
; ($50), +$14 byte frame number and +$15 number of frames (2). The archer's x
; is a multiple of 4 (a whole cell; $08, $70, $3C in room 17, $60 in room 21),
; so no shifted copies of its 2-byte wide sprite are needed: A' is 0 for the
; frame lookup.
;
; This routine reads the position, stores it as the start position of the arrow
; (SPAWN_POSITION), decides which way to face by comparing the monk's x
; (PlayerX, high byte; a negative value counts as 0) with its own, and chooses
; the arrow template (ArrowLeftTemplate when the monk is to the left,
; ArrowRightTemplate otherwise) and the frame table (IY = SelectFrameLeft, the
; left one, or SelectFrameRight, which skips it to take the right one). It goes
; on at UpdateShooter_Common, which the stone head UpdateStoneHead shares.
;
; SP Slot address + 2 (the handler word was popped by the RET that entered the
;    routine)
UpdateArcher:
  POP BC                  ; +2, not used
  POP BC                  ; +4, not used
  POP HL                  ; x word
  LD D,H                  ; D = x
  POP HL                  ; y word
  LD E,H                  ; E = y
  LD H,D
  LD L,E                  ; HL = x (H) and y (L), 2-pixel units
  LD (SPAWN_POSITION),HL  ; start position of an arrow: SPAWN_POSITION
  LD A,(PlayerX+$0001)    ; x of the monk (high byte)
  BIT 7,A                 ; negative: treat as 0
  JR Z,UpdateArcher_0
  XOR A
UpdateArcher_0:
  CP H                    ; monk left of the archer: carry
  EXX                     ; alternate set: HL' and DE' the two templates
  LD IY,SelectFrameLeft   ; facing left: the first frame table
  LD HL,ArrowLeftTemplate ; ArrowLeftTemplate
  LD DE,ArrowRightTemplate ; ArrowRightTemplate
  JR C,UpdateShooter_Common ; monk on the left: keep left
  EX DE,HL                ; facing right: HL' = ArrowRightTemplate
  LD IY,SelectFrameRight  ; the second frame table

; Shooter: position and hit test
;
; Common part of the archer and the stone head of rooms 20 and 22
; (UpdateStoneHead jumps here). Both callers load the template after an EXX,
; so on entry HL = address of the arrow template and HL' = x (H) and y (L);
; the EXX here swaps them, so the template waits in HL' for
; UpdateShooter_Tail. IY = SelectFrameLeft or SelectFrameRight (see above),
; SPAWN_POSITION already set, SP at slot+$A with the hit box words next. Makes
; the position of the sprite draw command (SpriteCmd: y, x/4), then tests the
; shooter's hit box against the monk (HitTest), which continues at
; UpdateShooter_Tail. Observed in rooms 17 and 20: on entry H, L = $BC, $A2
; (ArrowRightTemplate) or $BC, $B2 (WallShotTemplate), SP = slot + $A.
;
; Hardware: none.
;
; HL Address of the arrow template
; HL' x (H) and y (L), 2-pixel units
; IY SelectFrameLeft or SelectFrameRight (used by UpdateShooter_Tail)
; SP Slot address + $A
UpdateShooter_Common:
  EXX                     ; back to the main set: HL = x, y
  SRA H                   ; x / 4 = byte column
  SRA H
  LD (SpriteCmdPos),HL    ; position of the draw command: y, byte column
  POP HL                  ; +$A, dropped
  LD HL,UpdateShooter_Tail ; continue after the hit test
  JP HitTest              ; hit test: sets the hit flag when the monk touches
                          ; the box

; Archer and stone head: draw attributes, shot countdown, throw an arrow, queue
; the sprite
;
; Continuation of UpdateShooter_Common after the hit test HitTest (reached by
; the JP at SmcHitContinue; SP is at slot+$10, the hit test has popped the two
; hit box words). It pops the pointer to the sprite block (slot +$10:
; attribute, height, width, frame tables) and puts the attribute, width and
; height in the draw command at SpriteCmd (A' = 0: no shifted copy), then steps
; the shot countdown (slot +$12 counter, +$13 reload: $50 for the archers, $46
; for the stone head):
;
; - when the counter equals ARCHER_AIM_TIME (30) the frame number is increased:
; the aiming frame is shown for the last 30 frames; - when it reaches 0 the
; arrow is thrown: sound effect SFX_ENEMY_SHOT is requested, a 4-byte record
; (the template in HL' and the position stored at SPAWN_POSITION by
; UpdateArcher or UpdateStoneHead) is appended to the object list at
; ObjectListPtr and the spawn count SpawnQueueCount is increased, so that
; SpawnQueuedObjects turns it into an arrow slot (UpdateArrow) in the same
; frame; the counter is reloaded and the frame number is increased again, which
; wraps to 0 (frame 0 is the resting frame).
;
; The frame number goes back to the slot and the code jumps to IY
; (SelectFrameLeft or SelectFrameRight: the frame table for the way the shooter
; faces, see UpdateArcher), which queues the sprite draw command and goes on to
; the next slot.
;
; Observed (room 17, the archers throw together every 80 frames; room 20 the
; stone head every 70): arrows appear in the slots as UpdateArrow with the
; templates ArrowLeftTemplate, ArrowRightTemplate and WallShotTemplate.
;
; HL' Address of the arrow template (ArrowLeftTemplate, ArrowRightTemplate or
;     WallShotTemplate)
; IY Address SelectFrameLeft or SelectFrameRight that queues the sprite
; SP Slot address + $10
UpdateShooter_Tail:
  POP HL                  ; sprite block
  LD A,(HL)               ; attribute
  INC HL
  LD (SpriteCmdAttr),A    ; attribute of the draw command
  XOR A
  EX AF,AF'               ; A' = 0: column offset of the sprite copy
  LD B,(HL)               ; height
  INC HL
  LD C,(HL)               ; width
  INC HL                  ; HL = the frame tables
  LD (SpriteCmdSize),BC   ; width, height of the draw command
  POP BC                  ; C countdown, B reload
  POP DE                  ; E frame, D number of frames
  LD A,C
  CP ARCHER_AIM_TIME      ; 30 frames before the shot: aiming frame
  JR NZ,UpdateShooter_Tail_0
  INC E
UpdateShooter_Tail_0:
  DEC C                   ; count down
  JR NZ,UpdateShooter_Tail_1
  EXX                     ; throw an arrow: HL' = template
  LD A,SFX_ENEMY_SHOT
  LD (SoundRequest),A     ; sound effect request
  LD (SPAWN_TEMPLATE),HL  ; SPAWN_TEMPLATE: the first word of the 4-byte record
  LD HL,SpawnQueueCount   ; one more record waiting
  INC (HL)
  LD HL,SPAWN_TEMPLATE    ; SPAWN_TEMPLATE, SPAWN_POSITION
  LD DE,(ObjectListPtr)   ; end of the object list
  LD BC,OBJECT_ENTRY_SIZE
  LDIR                    ; append the record
  LD (ObjectListPtr),DE
  EXX
  LD C,B                  ; reload the countdown
  INC E                   ; next frame: wraps to 0
  LD A,E
  CP D
  JR NZ,UpdateShooter_Tail_1
  SUB D
  LD E,A
UpdateShooter_Tail_1:
  PUSH DE                 ; store frame
  PUSH BC                 ; store countdown
  JP (IY)                 ; queue the sprite, next slot

; Entity handler: spitting plant of room 14, position and hit test
;
; The three magenta plants of "Hidden garden" (room 14): handler of room object
; kind 12 (EntityHandlers, behaviour block BehaviourSeedPlant). A plant stays
; where it is, opens its head and spits two seeds, one flying up and left and
; one up and right (UpdateSeed), every 120 frames; touching a plant kills the
; monk. Entity handlers are not called: the slot walker RunObjectSlots sets SP
; to a slot of ObjectSlots and RETs, so the handler is entered with SP at
; slot+2 and finds its state on the stack.
;
; Slot (the layout of the room enemies made by SpawnRoomObject): +2 and +4
; words not used, +6 word x and +8 word y (8.8, high bytes in 2-pixel units; x
; is a multiple of 4), +$A byte not used and +$B byte the reload of the spit
; countdown (both $78), +$C word hit box offset (y, x), +$E word hit box far
; corner (y, x), +$10 pointer to the sprite block (attribute, height, width,
; two frames), +$12 byte spit countdown (the other byte of the word is not used
; here), +$14 byte frame and +$15 number of frames (2).
;
; This routine stores the position as the start position of the seeds
; (SPAWN_POSITION), makes the position of the draw command (SpriteCmd: y, x/4),
; keeps +$B in A', and tests the hit box against the monk with OverlapTest,
; with UpdatePlant_Spit as the continuation (carry set when the boxes overlap).
;
; SP Slot address + 2 (the handler word was popped by the RET that entered the
;    routine)
UpdatePlant:
  POP BC                  ; +2, not used
  POP BC                  ; +4, not used
  POP HL                  ; x word
  LD D,H                  ; D = x
  POP HL                  ; y word
  LD E,H                  ; E = y
  LD H,D
  LD L,E                  ; HL = x (H) and y (L), 2-pixel units
  LD (SPAWN_POSITION),HL  ; start position of the seeds: SPAWN_POSITION
  SRA H                   ; x / 4 = byte column
  SRA H
  LD (SpriteCmdPos),HL    ; position of the draw command: y, byte column
  POP AF                  ; +$A and +$B: A = the reload of the spit countdown
  EX AF,AF'               ; keep it
  POP HL                  ; hit box offset
  ADD HL,DE               ; plus the position
  EX DE,HL
  POP BC                  ; hit box far corner
  ADD HL,BC
  LD B,H                  ; BC = far corner of the box
  LD C,L
  LD IX,UpdatePlant_Spit  ; continue after the test
  JP OverlapTest          ; compare the box with the monk's (HitTest without
                          ; its first half)

; Plant: set the hit flag, count down, spit two seeds, queue the sprite
;
; Continuation of UpdatePlant after the hit test OverlapTest (SP is at
; slot+$10). Carry set means the boxes overlap: the hit flag PlayerHit is set
; to $FF, which makes the monk die (observed: the death code KillPlayer clears
; the flag in the same frame). It then takes the sprite block (slot +$10),
; stores the attribute in the draw command at SpriteCmd and steps the spit
; countdown (slot +$12; the reload comes from +$B through A'):
;
; - when the countdown equals PLANT_SPIT_TIME (50) the frame number is
; increased (the plant opens its head) and the plant spits: the sound effect
; SFX_ENEMY_SHOT is requested, two 4-byte records (the templates
; SeedLeftTemplate and SeedRightTemplate with the position at SPAWN_POSITION)
; are appended to the object list at ObjectListPtr and the spawn count
; SpawnQueueCount is raised by two, so that SpawnQueuedObjects turns them into
; the seeds of UpdateSeed in the same frame; - when it reaches 0 it is reloaded
; and the frame number increased, which wraps to 0 (head closed).
;
; The countdown goes back to the slot and the code goes on at QueueFrameSprite,
; which queues the sprite.
;
; F Carry set when the plant's hit box overlaps the monk's
; A' Reload of the spit countdown (slot +$B)
; SP Slot address + $10
UpdatePlant_Spit:
  JR NC,UpdatePlant_Spit_0 ; no overlap
  SBC A,A                 ; A = $FF
  LD (PlayerHit),A        ; hit flag
UpdatePlant_Spit_0:
  POP HL                  ; sprite block
  LD A,(HL)               ; attribute
  INC HL
  LD (SpriteCmdAttr),A    ; attribute of the draw command
  EX AF,AF'               ; A = reload
  POP BC                  ; C spit countdown
  LD B,A                  ; B = reload
  POP DE                  ; E frame, D number of frames
  LD A,C
  CP PLANT_SPIT_TIME      ; 50 frames before the end: spit
  JR NZ,UpdatePlant_Spit_1
  INC E                   ; open head
  EXX
  LD A,SFX_ENEMY_SHOT
  LD (SoundRequest),A     ; sound effect request
  LD HL,SpawnQueueCount   ; two records waiting
  INC (HL)
  INC (HL)
  LD HL,SeedLeftTemplate  ; SeedLeftTemplate
  LD (SPAWN_TEMPLATE),HL  ; SPAWN_TEMPLATE
  LD HL,SPAWN_TEMPLATE    ; SPAWN_TEMPLATE, SPAWN_POSITION
  LD DE,(ObjectListPtr)   ; end of the object list
  LD BC,OBJECT_ENTRY_SIZE
  LDIR                    ; append the record
  LD HL,SeedRightTemplate ; SeedRightTemplate
  LD (SPAWN_TEMPLATE),HL
  LD HL,SPAWN_TEMPLATE    ; same position
  LD C,OBJECT_ENTRY_SIZE
  LDIR                    ; append the second record
  LD (ObjectListPtr),DE
  EXX
UpdatePlant_Spit_1:
  DEC C                   ; count down
  JR NZ,UpdatePlant_Spit_2
  LD C,B                  ; reload
  INC E                   ; next frame: wraps to 0
  LD A,E
  CP D
  JR NZ,UpdatePlant_Spit_2
  SUB D
  LD E,A
UpdatePlant_Spit_2:
  PUSH DE                 ; store frame
  PUSH BC                 ; store countdown

; Queue the sprite of a frame table
;
; Queue the sprite of an entity with one frame table. The attribute is already
; in the draw command. HL points to the sprite block + 1 (height, width, then
; the frame table: one word per frame, the address of its graphics) and E is
; the frame number. Used by the plant (UpdatePlant_Spit falls into it) and the
; fish (UpdateFish_Queue); makes the draw command with width and height from
; the block, the graphics from the table (A' = 0: the sprite is at a multiple
; of 4 and needs no shifted copy) and goes on to SelectFrame (which queues it
; and goes to the next slot, so SP must be at slot + $12: observed at every
; entry in rooms 14, 16 and 19).
;
; Hardware: none.
;
; HL Sprite block + 1
; E Frame number
; SP Slot address + $12
QueueFrameSprite:
  XOR A
  EX AF,AF'               ; A' = 0: column offset
  LD B,(HL)               ; height
  INC HL
  LD C,(HL)               ; width
  INC HL                  ; HL = frame table
  LD (SpriteCmdSize),BC   ; width, height of the draw command
  JP SelectFrame          ; graphics = table[E]; queue it

; Entity handler: Satan's fireball (room 24); its body flies the arrows too
;
; The fireballs Satan fires in room 24 (templates FireballUpTemplate,
; FireballLeftTemplate and FireballDownTemplate, spawned in a volley of three
; by UpdateSatan). This 3-instruction entry removes the fireball as soon as
; Satan has been turned into smoke (SatanSmoked nonzero, set by UpdateSatan):
; FreeEntitySlotAtEntry clears the handler word and goes on to the next slot.
; Otherwise it falls through to UpdateArrow, which is the handler of the arrows
; (ArrowLeftTemplate, ArrowRightTemplate and WallShotTemplate are spawned with
; that address) and of the fireballs alike.
;
; SP Slot address + 2 (the handler word was popped by the RET that entered the
;    routine)
UpdateFireball:
  LD A,(SatanSmoked)      ; SatanSmoked
  OR A
  JP NZ,FreeEntitySlotAtEntry ; Satan is gone: remove the fireball

; Entity handler: projectile flying in a straight line
;
; Entity handler: projectile flying in a straight line (arrows, fireballs),
; entered with SP at slot+2. Slot from a template (ArrowLeftTemplate on): +2
; word x speed and +4 word y speed (signed 8.8, 2-pixel units per frame), +6
; word x and +8 word y (8.8, high bytes in 2-pixel units), +$A word hit box
; offset (y, x), +$C word hit box far corner (y, x), +$E word width and height
; of the sprite (draw command units), +$10 pointer to the sprite description
; (attribute, column in the sprite sheet, base page: see SetProjectileSprite).
; The speeds are added to the position every frame and the projectile is
; removed (slot freed by FreeEntitySlotAtEntry) when it leaves the room (y at
; or below PROJECTILE_Y_MAX, or x not in 0-$7F, which takes the negative values
; as well) or when the flags of the two cells at its top-left corner (the cell
; at (x/4, y/4) and the one to the right) have a tile class other than 0 (solid
; or harmful; ORed and masked with TILE_CLASS_MASK). Otherwise the position
; becomes the position of the draw command (y, x/4) and the hit box is tested
; against the monk (HitTest), which continues at SetProjectileSprite with A' =
; x. Cells are looked up as in the other entities: the row address table
; FlagRowTable (H = $61, L = 2 * (y / 4)) gives the address of the row of the
; tile flag map and x / 4 is the column. The handler word of the arrows
; (ArrowLeftTemplate, ArrowRightTemplate, WallShotTemplate); Satan's fireballs
; fall into it from UpdateFireball.
;
; Hardware: none.
;
; SP Slot address + 2 (the handler word was popped by the RET that entered the
;    routine)
UpdateArrow:
  POP HL                  ; x speed
  POP DE                  ; y speed
  POP BC                  ; x
  ADD HL,BC               ; x moves
  EX DE,HL                ; DE = new x, HL = y speed
  POP BC                  ; y
  ADD HL,BC               ; y moves
  PUSH HL                 ; store y
  PUSH DE                 ; store x
  LD A,H                  ; y in 2-pixel units
  CP PROJECTILE_Y_MAX     ; below the room (or negative)
  JR NC,Projectile_Remove
  BIT 7,D                 ; x outside 0-$7F
  JR NZ,Projectile_Remove
  SRA H                   ; y / 2
  RES 0,H                 ; 2 * (y / 4): index of the row in the table of words
  LD L,H
  LD H,FlagRowTable/$100  ; row address table FlagRowTable
  LD A,D                  ; x
  RRA
  RRA
  AND $1F                 ; x / 4: cell column
  ADD A,(HL)              ; address of the cell in the tile flag map
  INC L
  LD H,(HL)
  LD L,A
  LD A,(HL)               ; flags of the cell
  INC L
  OR (HL)                 ; and of the cell to its right
  AND TILE_CLASS_MASK     ; tile class
  JR Z,Projectile_Draw    ; free: draw it

; Remove a projectile
;
; Remove a projectile (arrow, fireball) that has left the room or hit a cell
; that is not free; also used by the seeds (UpdateSeed). Entered with SP at
; slot+6, just after the new x and y have been stored. The two pushes put SP
; back at slot+2 (they write HL over the two speed words at +4 and +2, which
; does not matter) and FreeEntitySlotAtEntry then zeroes the handler word and
; goes on to the next slot. Observed in rooms 14 and 17: SP = slot + 6 at every
; entry.
;
; Hardware: none.
;
; SP Slot address + 6
Projectile_Remove:
  PUSH HL
  PUSH HL
  JP FreeEntitySlotAtEntry ; free the slot

; Draw a projectile
;
; Draw a projectile that stays: also used by the seeds (UpdateSeed). SP is at
; slot+6, the position words (x, then y) are the next ones (observed in rooms
; 14, 17, 20 and 24). Makes HL = x (H) and y (L), keeps x in A' for the shift
; phase of the sprite, makes the draw command position (y, x/4) and tests the
; hit box (HitTest, with D = x and E = y; it continues at SetProjectileSprite).
;
; Hardware: none.
;
; SP Slot address + 6
Projectile_Draw:
  POP HL                  ; x word
  LD D,H                  ; D = x
  POP HL                  ; y word
  LD E,H                  ; E = y
  LD L,H
  LD H,D                  ; HL = x (H) and y (L)
  LD A,H
  EX AF,AF'               ; A' = x: its low 2 bits select the shifted copy
  SRA H                   ; x / 4 = byte column
  SRA H
  LD (SpriteCmdPos),HL    ; position of the draw command: y, byte column
  LD HL,SetProjectileSprite ; continue after the hit test
  JP HitTest              ; hit test: sets the hit flag when the monk touches
                          ; the box

; Projectile: attribute, size and shifted graphics of the sprite, then queue it
;
; Continuation of Projectile_Draw after the hit test HitTest (reached by a JP
; through $A881; SP is at slot+$E, the hit test has popped the two hit box
; words). It pops the sprite size word (slot +$E: width, height) into the draw
; command at SpriteCmd (+6, $ACD7) and the pointer to the sprite description
; (slot +$10) which holds three bytes: attribute, column in the sprite sheet
; and the page of the first shifted copy. The attribute goes to the draw
; command (+9, $ACDA). The graphics address (+4, $ACD5) is the column plus the
; page, increased by 4 pages for every step of the shift phase x AND 3 (A' =
; x): the sprite sheet SpriteSheet holds a page per pixel row, and the four
; copies of such a small sprite (2-pixel units: 4 pixel rows high) follow each
; other, each copy shifted 2 pixels further right than the one before.
; QueueEntitySprite then queues the draw command and goes on to the next slot.
;
; A' x in 2-pixel units; AND 3 is the shift phase
; SP Slot address + $E
SetProjectileSprite:
  POP HL                  ; width, height
  LD (SpriteCmdSize),HL   ; of the draw command
  POP HL                  ; sprite description: attribute, column, page
  LD A,(HL)               ; attribute
  INC HL
  LD (SpriteCmdAttr),A    ; of the draw command
  LD A,(HL)               ; column in the sprite sheet
  INC HL
  EX AF,AF'               ; A = x, A' = column
  AND SPRITE_PHASE_MASK                 ; shift phase
  ADD A,A
  ADD A,A                 ; times 4 pages
  ADD A,(HL)              ; plus the page of the first copy
  LD H,A
  EX AF,AF'
  LD L,A                  ; HL = page and column
  LD (SpriteCmdGfx),HL    ; graphics of the draw command
  JP QueueEntitySprite    ; queue it (unless QueueDrawCmd stops drawing), next
                          ; slot

; Entity handler: seed spat by a plant of room 14, flying in an arc
;
; The seeds the plants of "Hidden garden" (UpdatePlant_Spit) spit, two at a
; time, up and to the left (template SeedLeftTemplate) and up and to the right
; (SeedRightTemplate). Slot from the template (see UpdateFireball for the whole
; layout): +2 word x speed ($FF91 = -0.43 or $006F = +0.43), +4 word y speed
; (starts at $FE90 = -1.44), +6 word x, +8 word y, +$A hit box offset, +$C hit
; box far corner, +$E sprite size, +$10 sprite description. Each frame
; SEED_GRAVITY is added to the y speed (stored back in the slot), so the seed
; rises, turns and falls; both speeds are then added to the position as in
; UpdateArrow. It is removed (Projectile_Remove) when it leaves the room (y
; below PROJECTILE_Y_MAX or x outside 0-$7F) or when the single cell at (x/4,
; y/4) has a tile class other than 0 (unlike the arrows it does not look at the
; cell to its right); otherwise it is drawn and hit-tested at Projectile_Draw
; like the arrows. Observed (room 14, the monk standing still): the seeds fall
; from the plants in arcs to both sides and are freed when they reach the floor
; or leave the room.
;
; SP Slot address + 2 (the handler word was popped by the RET that entered the
;    routine)
UpdateSeed:
  POP DE                  ; x speed
  POP HL                  ; y speed
  LD BC,SEED_GRAVITY      ; gravity
  ADD HL,BC               ; the seed accelerates downwards
  PUSH HL                 ; store the new y speed
  POP HL                  ; SP back at +4
  EX DE,HL                ; HL = x speed, DE = y speed
  POP BC                  ; x
  ADD HL,BC               ; x moves
  EX DE,HL                ; DE = new x, HL = y speed
  POP BC                  ; y
  ADD HL,BC               ; y moves
  PUSH HL                 ; store y
  PUSH DE                 ; store x
  LD A,H                  ; y in 2-pixel units
  CP PROJECTILE_Y_MAX     ; below the room (or negative)
  JP NC,Projectile_Remove
  BIT 7,D                 ; x outside 0-$7F
  JP NZ,Projectile_Remove
  SRA H                   ; y / 2
  RES 0,H                 ; 2 * (y / 4): index of the row in the table of words
  LD L,H
  LD H,FlagRowTable/$100  ; row address table FlagRowTable
  LD A,D                  ; x
  RRA
  RRA
  AND $1F                 ; x / 4: cell column
  ADD A,(HL)              ; address of the cell in the tile flag map
  INC L
  LD H,(HL)
  LD L,A
  LD A,(HL)               ; flags of the cell
  AND TILE_CLASS_MASK     ; tile class
  JP Z,Projectile_Draw    ; free: draw it
  JP Projectile_Remove    ; solid or harmful: remove it

; Entity handler: water splash (rooms 16 and 19)
;
; The splash that appears on the water where a fish jumps out and where it
; falls back in (the object is made from SplashTemplate by UpdateFishWaiting
; and UpdateFishJumping). It plays its three frames (blue-white drops, sprite
; description SpriteBlockSplash) two frames each, so it lasts six game frames,
; and is then removed. It has no hit box. Slot (a template slot, see
; UpdateFireball): +2 word x speed and +4 word y speed (both 0 here, but added
; to the position), +6 word x, +8 word y (8.8, high bytes in 2-pixel units),
; +$A byte animation counter and +$B its reload (2), +$C byte frame and +$D
; number of frames (3), +$E word width and height of the sprite (2, 4), +$10
; pointer to the sprite description (attribute, then one graphics address per
; frame). The position is the start position set by the fish: x of the fish, y
; = WATER_Y.
;
; Entered with SP at slot+2. The frame counter reaching the number of frames
; removes the splash: SP is put back to slot+2 and FreeEntitySlotAtEntry zeroes
; the handler word and goes on to the next slot; otherwise it makes the draw
; command (position y, x/4; size; attribute; graphics = table[frame], no shift
; phase is used) and goes to QueueEntitySprite, which queues it.
;
; SP Slot address + 2 (the handler word was popped by the RET that entered the
;    routine)
UpdateSplash:
  POP HL                  ; x speed
  POP DE                  ; y speed
  POP BC                  ; x
  ADD HL,BC               ; x moves
  EX DE,HL                ; DE = new x, HL = y speed
  POP BC                  ; y
  ADD HL,BC               ; y moves
  PUSH HL                 ; store y
  PUSH DE                 ; store x
  POP HL                  ; and take them back: HL = x word
  LD D,H                  ; D = x
  POP HL                  ; y word
  LD E,H                  ; E = y
  LD L,H
  LD H,D                  ; HL = x (H) and y (L)
  LD A,H
  EX AF,AF'               ; A' = x (not used further)
  SRA H                   ; x / 4 = byte column
  SRA H
  LD (SpriteCmdPos),HL    ; position of the draw command: y, byte column
  POP BC                  ; C animation counter, B reload
  POP DE                  ; E frame, D number of frames
  DEC C
  JR NZ,UpdateSplash_0
  LD C,B                  ; reload
  INC E                   ; next frame
  LD A,E
  CP D
  JR NZ,UpdateSplash_0
  LD HL,$FFF4             ; last frame shown: remove the splash; -12: SP back
                          ; to slot+2
  ADD HL,SP
  LD SP,HL
  JP FreeEntitySlotAtEntry ; free the slot
UpdateSplash_0:
  PUSH DE                 ; store frame
  PUSH BC                 ; store counter
  POP BC                  ; and take them back to move SP on
  POP DE
  POP HL                  ; width, height
  LD (SpriteCmdSize),HL   ; of the draw command
  POP HL                  ; sprite description
  LD A,(HL)               ; attribute
  INC HL
  LD (SpriteCmdAttr),A    ; of the draw command
  LD D,$00
  ADD HL,DE
  ADD HL,DE               ; HL = table + 2 * frame
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A                  ; graphics address of the frame
  LD (SpriteCmdGfx),HL    ; of the draw command
  JP QueueEntitySprite    ; queue it, next slot

; Entity handler: fish waiting under the water (rooms 16 and 19)
;
; The jumping fish of "Lake of despair" (room 16, three of them) and
; "Underground river" (room 19, two): handler of room object kind 13
; (EntityHandlers, behaviour block BehaviourFish). A fish has two states, each
; with its own handler: this one, in which it is hidden under the water, and
; UpdateFishJumping, in which it jumps out of the water in an arc and falls
; back. The slot is the one of the room enemies (SpawnRoomObject): +2 word not
; used while waiting (the jump speed once it jumps), +4 byte countdown and +5
; byte its reload ($54), +6 word x and +8 word y (8.8, high bytes in 2-pixel
; units), +$A and +$B bytes not used, +$C word hit box offset, +$E word hit box
; far corner (7, 7), +$10 pointer to the sprite block (954E: attribute, height,
; width, two frames), +$12 byte animation counter and +$13 its reload, +$14
; byte frame and +$15 number of frames (2).
;
; While waiting nothing is drawn and the hit test is not made. The countdown
; goes down by one per frame; when it equals FISH_JUMP_TIME (30 frames after
; the reload) the fish jumps: a splash (template SplashTemplate) is made at x
; with y = WATER_Y (position at SPAWN_POSITION, record appended to the object
; list ObjectListPtr, spawn count SpawnQueueCount raised, sound effect
; SFX_ENEMY_SHOT), and the slot is rewritten in place: the handler word becomes
; UpdateFishJumping, +2 the jump speed FISH_JUMP_SPEED (upwards), +4 the
; countdown (kept: it now counts the 54 frames of the jump), +8 the start y
; FISH_JUMP_Y, +6 x is kept. The rest of the slot is not touched. The fish of a
; room start with different countdowns (observed in room 19: $54 and $7C), so
; that they do not jump together.
;
; SP Slot address + 2 (the handler word was popped by the RET that entered the
;    routine)
UpdateFishWaiting:
  POP BC                  ; +2, not used
  POP DE                  ; E countdown, D reload
  DEC E
  LD A,E
  CP FISH_JUMP_TIME       ; time to jump?
  JR Z,UpdateFishWaiting_Jump
  PUSH DE                 ; store the countdown
  LD HL,$0012             ; SP is at slot+4: +$12 is the next slot
  ADD HL,SP
  JP RunObjectSlot        ; next slot

; Fish: jump out of the water
;
; Reached from UpdateFishWaiting when its countdown, already decremented,
; equals FISH_JUMP_TIME. Queues a splash at the water surface below the fish
; and rewrites the slot words +0 to +8 for the jump (see UpdateFishWaiting). DE
; is kept across the EXX and stored back at +4: the countdown goes on through
; the jump. Observed in rooms 16 and 19: SP = slot + 6, E = $36, D = $54 at
; every entry.
;
; Hardware: none.
;
; DE E countdown (FISH_JUMP_TIME), D its reload
; SP Slot address + 6
UpdateFishWaiting_Jump:
  POP HL                  ; x word
  LD A,H                  ; A = x
  POP HL                  ; y word
  LD L,A
  LD A,H
  LD H,L                  ; H = x
  LD L,WATER_Y            ; y of the water surface
  LD (SPAWN_POSITION),HL  ; SPAWN_POSITION of the splash
  EXX
  LD HL,SoundRequest      ; sound effect request
  LD (HL),SFX_ENEMY_SHOT
  LD HL,SplashTemplate    ; SplashTemplate
  LD (SPAWN_TEMPLATE),HL  ; SPAWN_TEMPLATE
  LD HL,SpawnQueueCount   ; one more record waiting
  INC (HL)
  LD HL,SPAWN_TEMPLATE    ; SPAWN_TEMPLATE, SPAWN_POSITION
  LD DE,(ObjectListPtr)   ; end of the object list
  LD BC,OBJECT_ENTRY_SIZE
  LDIR                    ; append the record
  LD (ObjectListPtr),DE
  EXX                     ; DE = countdown (E) and reload (D) again
  LD HL,FISH_JUMP_Y       ; start y of the jump
  PUSH HL                 ; slot +8
  DEC SP
  DEC SP                  ; skip +6, x stays
  PUSH DE                 ; slot +4: countdown and reload
  LD BC,FISH_JUMP_SPEED   ; speed upwards
  PUSH BC                 ; slot +2
  LD HL,UpdateFishJumping ; the jumping state
  PUSH HL                 ; handler word at slot +0
  LD HL,SLOT_SIZE
  ADD HL,SP               ; next slot
  JP RunObjectSlot

; Entity handler: fish jumping out of the water (rooms 16 and 19)
;
; The jumping state of the fish of UpdateFishWaiting, which rewrote the slot
; with this handler word. Slot: +2 word vertical speed (8.8; starts at
; FISH_JUMP_SPEED, upwards), +4 byte countdown of the jump (starts at
; FISH_JUMP_TIME, 54 frames) and +5 its reload ($54), +6 word x and +8 word y
; (8.8, high bytes in 2-pixel units, y starts at FISH_JUMP_Y), +$A word not
; used, +$C word hit box offset, +$E word hit box far corner (7, 7), +$10
; pointer to the sprite block (954E), +$12 and +$13 animation counter and
; reload, +$14 frame and +$15 number of frames (2).
;
; Each frame the speed grows by FISH_GRAVITY (stored back), the y moves by the
; old speed, and the countdown goes down. When the countdown has fallen to 1
; the fish is back at the water: a splash (template SplashTemplate) is made at
; the x of the fish with y = WATER_Y, as at the start of the jump (position at
; SPAWN_POSITION, record appended to the object list ObjectListPtr, spawn count
; SpawnQueueCount raised, sound effect SFX_ENEMY_SHOT). When it reaches 0 the
; handler word is set back to UpdateFishWaiting and the countdown reloaded (the
; fish stays under the water for 30 frames, then jumps again: a cycle of 84
; frames). The fish is then drawn: the position (y, x/4) goes to the draw
; command, the hit box is tested against the monk (HitTest; observed: touching
; the fish sets the hit flag), which continues at SetFishSprite.
;
; SP Slot address + 2 (the handler word was popped by the RET that entered the
;    routine)
UpdateFishJumping:
  POP BC                  ; vertical speed
  LD HL,FISH_GRAVITY
  ADD HL,BC               ; faster downwards
  PUSH HL                 ; store the new speed
  POP HL                  ; SP back at +4
  POP DE                  ; E countdown, D reload
  DEC E
  JR NZ,UpdateFishJumping_0
  LD E,D                  ; back in the water: reload,
  PUSH DE                 ; store it
  PUSH HL                 ; store the speed
  LD HL,UpdateFishWaiting ; and wait under the water again:
  PUSH HL                 ; handler word at slot +0
  POP HL                  ; take the three words back
  POP HL
  POP DE
UpdateFishJumping_0:
  PUSH DE                 ; store the countdown
  POP DE
  DEC E                   ; test only: is the stored countdown 1 (the landing)?
  POP DE                  ; x word: D = x
  JR NZ,UpdateFishJumping_1
  LD A,D                  ; A = x
  EXX
  LD H,A                  ; H = x
  LD A,SFX_ENEMY_SHOT
  LD (SoundRequest),A     ; sound effect request
  LD L,WATER_Y            ; y of the water surface
  LD (SPAWN_POSITION),HL  ; SPAWN_POSITION of the splash
  LD HL,SplashTemplate    ; SplashTemplate
  LD (SPAWN_TEMPLATE),HL  ; SPAWN_TEMPLATE
  LD HL,SpawnQueueCount   ; one more record waiting
  INC (HL)
  LD HL,SPAWN_TEMPLATE    ; SPAWN_TEMPLATE, SPAWN_POSITION
  LD DE,(ObjectListPtr)   ; end of the object list
  LD BC,OBJECT_ENTRY_SIZE
  LDIR                    ; append the record
  LD (ObjectListPtr),DE
  EXX
UpdateFishJumping_1:
  POP HL                  ; y word
  ADD HL,BC               ; y moves by the old speed
  PUSH HL                 ; store y
  POP HL
  POP BC                  ; +$A, dropped
  LD E,H                  ; E = y
  LD L,H
  LD H,D                  ; HL = x (H) and y (L)
  SRA H                   ; x / 4 = byte column
  SRA H
  LD (SpriteCmdPos),HL    ; position of the draw command: y, byte column
  LD HL,SetFishSprite     ; continue after the hit test
  JP HitTest              ; hit test: sets the hit flag when the monk touches
                          ; the box

; Fish: attribute, then the animation step
;
; Continuation of UpdateFishJumping after the hit test HitTest (reached by a JP
; through $A881; SP is at slot+$10, the hit test has popped the two hit box
; words). It takes the pointer to the sprite block (slot +$10: attribute,
; height, width, two frames; 954E) and stores the attribute in the draw command
; at SpriteCmd. The animation counter and frame number in slot +$12..+$15 are
; stepped by StepAnimation, which continues at UpdateFish_Queue.
;
; SP Slot address + $10
SetFishSprite:
  POP HL                  ; sprite block
  LD A,(HL)               ; attribute
  INC HL
  LD (SpriteCmdAttr),A    ; of the draw command
  LD IX,UpdateFish_Queue  ; the animation step continues there
  JP StepAnimation        ; step the animation: frame in E

; Fish: queue the sprite after the animation step
;
; Continuation of SetFishSprite after StepAnimation. HL points to the sprite
; block + 1 and E is the frame number: QueueFrameSprite makes the draw command
; from them and queues it.
;
; E Frame number
; HL Sprite block + 1
UpdateFish_Queue:
  JP QueueFrameSprite     ; queue the sprite of the frame

; Entity handler: head of the Pestilent Beast (room 10)
;
; The yellow dragon head of "Pestilent Beast" (room 10, 4 cells wide, 20 units
; high): handler of room object kind 14 (EntityHandlers, behaviour block
; BehaviourBeastHead). The body of the dragon is part of the room's tiles; the
; head is this sprite, which stays where it is and lowers by 2 units (4 pixels)
; for the last 40 frames of every 110 frames, the time in which the Beast
; breathes fire (UpdateBeastFire). It is only drawn: there is no hit box test
; (the three words +$A, +$C and +$E are popped and dropped).
;
; Slot (the layout of the room enemies made by SpawnRoomObject): +2 and +4 not
; used, +6 word x and +8 word y (8.8, high bytes in 2-pixel units), +$A word,
; +$C word hit box offset and +$E word hit box far corner: not used here, +$10
; pointer to the sprite block (9580: attribute, height, width, one frame), +$12
; byte counter (110 down to 1) and +$13 its reload ($6E), +$14 byte the dip (0
; or 1; the slot's frame number, but there is only one frame) and +$15 number
; of frames.
;
; When the counter equals BEAST_HEAD_DIP (40) the dip becomes 1; when it
; reaches 0 it is reloaded and the dip becomes 0. The draw command's y is the
; slot's y plus twice the dip, its graphics the one frame of the block (the
; frame number used for the table lookup is forced to 0). The routine goes on
; to SelectFrame, which queues it.
;
; SP Slot address + 2 (the handler word was popped by the RET that entered the
;    routine)
UpdateBeastHead:
  POP BC                  ; +2, not used
  POP BC                  ; +4, not used
  POP HL                  ; x word
  LD D,H                  ; D = x
  POP HL                  ; y word
  LD E,H                  ; E = y
  LD H,D
  LD L,E                  ; HL = x (H) and y (L)
  LD (SPAWN_POSITION),HL  ; SPAWN_POSITION (not used by the head)
  SRA H                   ; x / 4 = byte column
  SRA H
  LD (SpriteCmdPos),HL    ; position of the draw command: y, byte column
  POP AF                  ; +$A, dropped
  POP AF                  ; +$C, dropped
  POP AF                  ; +$E, dropped
  POP HL                  ; sprite block
  LD A,(HL)               ; attribute
  INC HL
  LD (SpriteCmdAttr),A    ; of the draw command
  POP BC                  ; C counter, B reload
  POP DE                  ; E dip, D number of frames
  LD A,C
  CP BEAST_HEAD_DIP       ; 40 frames before the end: lower the head
  JR NZ,UpdateBeastHead_0
  INC E
UpdateBeastHead_0:
  DEC C                   ; count down
  JR NZ,UpdateBeastHead_1
  LD C,B                  ; reload
  LD E,$00                ; raise the head
UpdateBeastHead_1:
  PUSH DE                 ; store the dip
  PUSH BC                 ; store the counter
  LD A,E
  ADD A,A                 ; 2 units per step
  EXX
  LD HL,(SpriteCmdPos)    ; position of the draw command
  ADD A,L
  LD L,A                  ; y lower by 2 * dip
  LD (SpriteCmdPos),HL
  EXX
  XOR A
  LD E,A                  ; frame 0 for the table lookup
  EX AF,AF'               ; A' = 0: column offset
  LD B,(HL)               ; height
  INC HL
  LD C,(HL)               ; width
  INC HL                  ; HL = frame table
  LD (SpriteCmdSize),BC   ; width, height of the draw command
  JP SelectFrame          ; graphics = table[0]; queue it

; Entity handler: fire breath of the Pestilent Beast (room 10)
;
; The red jet of fire the dragon of "Pestilent Beast" breathes from its mouth
; down to the ledge below it, and the flames that run along that ledge
; afterwards: handler of room object kind 15 (EntityHandlers, behaviour block
; BehaviourBeastFire). The jet kills the monk on contact (observed: the hit
; flag PlayerHit is set on the frame it appears over the monk). Its cycle is
; 110 frames: for the first 72 nothing is drawn and nothing is tested; for the
; last 38 the jet is drawn and tested every frame (UpdateBeastFire_Draw); at
; the end of the cycle it disappears and two flames are made (templates
; FlameLeftTemplate and FlameRightTemplate at the position of the jet, 20 units
; lower, on the ledge, running left and right: UpdateMovingSprite), and the
; next cycle starts. The head of the dragon (UpdateBeastHead) lowers during the
; same last frames.
;
; Slot (the layout of the room enemies made by SpawnRoomObject): +2 word offset
; in y of the second sprite of the jet ($000C: 12 units below the first), +4
; byte cycle countdown (110 down to 1) and +5 its reload ($6E), +6 word x and
; +8 word y (8.8, high bytes in 2-pixel units; the position is the mouth: x =
; $40, y = $18), +$A byte countdown to the appearance of the jet and +$B its
; reload ($48 = 72), +$C word hit box offset, +$E word hit box far corner (x 7,
; y $17 from the position), +$10 pointer to the sprite block (958A: attribute,
; height, width, then the frames of both sprites), +$12 byte animation counter
; and +$13 its reload (2), +$14 byte frame and +$15 number of frames (2).
;
; This routine counts the cycle down (when it reaches 0 the countdown is
; reloaded and the flames are made), takes the position, and either leaves the
; slot (cycle countdown 0, or the appearance countdown still above 0, which is
; stored back one lower) or makes the positions of the two draw commands
; (SpriteCmd: y, x/4; SpriteCmd2: the same x, y plus +2) and tests the hit box
; against the monk with HitTest, which continues at UpdateBeastFire_Draw.
;
; SP Slot address + 2 (the handler word was popped by the RET that entered the
;    routine)
UpdateBeastFire:
  POP BC                  ; B = 0, C = $0C: offset in y of the second sprite
  POP DE                  ; E cycle countdown, D reload
  DEC E
  JR NZ,UpdateBeastFire_0
  LD E,D                  ; end of the cycle: reload (the zero flag stays set)
UpdateBeastFire_0:
  PUSH DE                 ; store the countdown
  POP DE
  POP HL                  ; x word
  LD D,H                  ; D = x
  POP HL                  ; y word
  LD E,H                  ; E = y
  LD H,D
  LD L,E                  ; HL = x (H) and y (L)
  JR NZ,UpdateBeastFire_2 ; not the end of the cycle
  LD (SPAWN_POSITION),HL  ; SPAWN_POSITION of the flames
  EXX
  LD HL,SpawnQueueCount   ; two records waiting
  INC (HL)
  INC (HL)
  LD HL,FlameLeftTemplate ; FlameLeftTemplate
  LD (SPAWN_TEMPLATE),HL  ; SPAWN_TEMPLATE
  LD HL,SPAWN_TEMPLATE    ; SPAWN_TEMPLATE, SPAWN_POSITION
  LD DE,(ObjectListPtr)   ; end of the object list
  LD BC,OBJECT_ENTRY_SIZE
  LDIR                    ; append the record
  LD HL,FlameRightTemplate ; FlameRightTemplate
  LD (SPAWN_TEMPLATE),HL
  LD HL,SPAWN_TEMPLATE    ; same position
  LD C,OBJECT_ENTRY_SIZE
  LDIR                    ; append the second record
  LD (ObjectListPtr),DE
  EXX
  POP BC                  ; C appearance countdown, B reload
  LD C,B                  ; the jet is hidden again for the next 72 frames
UpdateBeastFire_1:
  PUSH BC                 ; store the countdown; nothing is drawn
  LD HL,$000C             ; SP is at slot+$A: +$C is the next slot
  ADD HL,SP
  JP RunObjectSlot        ; next slot
UpdateBeastFire_2:
  SRA H                   ; x / 4 = byte column
  SRA H
  LD (SpriteCmdPos),HL    ; position of the first draw command: y, byte column
  ADD HL,BC               ; the second sprite is 12 units lower
  LD (SpriteCmd2Pos),HL   ; position of the second draw command
  POP BC                  ; C appearance countdown, B reload
  DEC C
  JR NZ,UpdateBeastFire_1 ; still hidden
  INC C                   ; stays at 1: drawn every frame until the end of the
                          ; cycle
  PUSH BC                 ; store it
  POP BC
  LD HL,UpdateBeastFire_Draw ; continue after the hit test
  JP HitTest              ; hit test: sets the hit flag when the monk touches
                          ; the box

; Beast fire: sizes of the two sprites, their frames, queue both draw commands
;
; Continuation of UpdateBeastFire after the hit test HitTest (reached by a JP
; through $A881; SP is at slot+$10, the hit test has popped the two hit box
; words), made only while the jet is visible. It takes the sprite block (slot
; +$10: attribute, width, height, then four graphics addresses: frames 0 and 1
; of the upper sprite, frames 0 and 1 of the lower one; 958A) and puts the
; attribute and the width and height into both draw commands at SpriteCmd and
; SpriteCmd2 (the lower sprite is one cell wider). The animation counter and
; frame number in slot +$12..+$15 are stepped here: when the counter reaches 0
; it is reloaded, the sound effect SFX_ENEMY_SHOT is requested (so the fire
; crackles every two frames) and the frame number is increased, which wraps to
; 0. The graphics of the upper sprite is table[frame], that of the lower sprite
; table[frame + 2]; in frame 0 the lower sprite is also moved one cell to the
; left (its byte column at ACDE is decreased). Both draw commands are copied
; together to the frame call list (QueueTwoCommands), unless the call list is
; being run (QueueDrawCmd is not a NOP), and the routine goes on to the next
; slot.
;
; SP Slot address + $10
UpdateBeastFire_Draw:
  POP HL                  ; sprite block
  LD A,(HL)               ; attribute
  INC HL
  LD C,(HL)               ; width
  INC HL
  LD B,(HL)               ; height
  INC HL                  ; HL = table of the four graphics addresses
  LD (SpriteCmdAttr),A    ; attribute of the first draw command
  LD (SpriteCmd2Attr),A   ; and of the second
  LD (SpriteCmdSize),BC   ; width, height of the first
  INC C                   ; the lower sprite is one cell wider
  LD (SpriteCmd2Size),BC  ; width, height of the second
  POP BC                  ; C animation counter, B reload
  POP DE                  ; E frame, D number of frames
  DEC C
  JR NZ,UpdateBeastFire_Draw_0
  LD C,B                  ; reload
  LD A,SFX_ENEMY_SHOT
  LD (SoundRequest),A     ; sound effect request
  INC E                   ; next frame: wraps to 0
  LD A,E
  CP D
  JR NZ,UpdateBeastFire_Draw_0
  SUB D
  LD E,A
UpdateBeastFire_Draw_0:
  PUSH DE                 ; store frame
  PUSH BC                 ; store counter
  LD D,$00
  ADD HL,DE
  ADD HL,DE               ; HL = table + 2 * frame
  DEC E                   ; frame 0: nonzero
  EXX
  LD HL,SpriteCmd2Pos+$0001 ; byte column of the second draw command
  JR Z,UpdateBeastFire_Draw_1 ; frame 1: keep it
  DEC (HL)                ; frame 0: one cell to the left
UpdateBeastFire_Draw_1:
  EXX
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (SpriteCmdGfx),DE    ; graphics of the upper sprite
  INC HL
  INC HL                  ; skip the other frame of the upper sprite:
                          ; table[frame + 2]
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  LD (SpriteCmd2Gfx),HL   ; graphics of the lower sprite
  LD A,(QueueDrawCmd)     ; the call list is being run?
  OR A
  JP NZ,NextSlotAfterAnim ; yes: draw nothing
  LD HL,SpriteCmd         ; both draw commands (20 bytes)
  LD DE,(FrameListPtr)    ; write pointer of the frame call list
  JP QueueTwoCommands     ; copy them, next slot

; Entity handler: the monk burning on the pyre (ending, second scene)
;
; The monk tied to the stake in the second scene of the ending (room 4;
; template ActorPyreMonkTemplate, record in the list at CutsceneList2; the
; three flames of the pyre and the four crusaders around it are
; UpdateMovingSprite). Slot (template slot, see UpdateFireball): +2 word the
; first countdown ($0118 = 280 frames), +4 word the second countdown ($00AF =
; 175 frames), +6 word x and +8 word y (8.8, high bytes in 2-pixel units: $3E
; and $3A, the place where the game also puts the monk's own position), +$A
; word hit box offset and +$C word hit box far corner (both 0), +$E pointer to
; the sprite block (SpriteBlockPyreMonk, yellow monk, 2 frames), +$10 animation
; counter and reload, +$12 frame and number of frames (2).
;
; The scene has three phases:
;
; - first countdown above 1: it is stored back one lower and the monk is drawn,
; standing still (speed and turning point are zeroed in the registers and the
; code goes on at UpdateMovingSprite_Move, which draws it with the shared
; flame/actor code); - the first countdown reaches 0 (the monk burns away): the
; player variables PlayerHit (hit flag) and PlayerState (state) are set to 2;
; nothing is drawn by this handler any more. Observed: the game's own monk (the
; player, at the same position) then runs its dying animation, the state
; PlayerState becoming 1 and y going from $3A to $2C within about 100 frames; -
; the first countdown is 0: the second countdown is decreased every frame and
; nothing is drawn; when it is 0 the cutscene flag CutsceneDone is set to 1,
; which ends the scene (the slot has already run once more when the loop
; notices: observed, the second countdown wraps to $FFFE).
;
; SP Slot address + 2 (the handler word was popped by the RET that entered the
;    routine)
UpdatePyreMonk:
  POP BC                  ; first countdown
  LD A,B
  OR C
  JR NZ,UpdatePyreMonk_1  ; still counting
  POP DE                  ; second countdown
  LD A,D
  OR E
  JR NZ,UpdatePyreMonk_0
  INC A                   ; A = 1
  LD (CutsceneDone),A     ; CutsceneDone: end the scene
UpdatePyreMonk_0:
  DEC DE                  ; count down
  PUSH DE                 ; store it
  LD HL,$0012             ; SP is at slot+4: +$12 is the next slot
  ADD HL,SP
  JP RunObjectSlot        ; next slot, nothing drawn
UpdatePyreMonk_1:
  DEC BC
  LD A,B
  OR C
  JR Z,UpdatePyreMonk_2   ; just reached 0: the monk burns away
  PUSH BC                 ; store the countdown
  POP BC
  POP DE                  ; second countdown (not changed)
  XOR A
  LD B,A
  LD C,A                  ; speed 0
  LD D,A
  LD E,A                  ; limit 0: never reached
  JR UpdateMovingSprite_Move ; draw it like a flame, at the same place
UpdatePyreMonk_2:
  PUSH BC                 ; store the countdown (0)
  LD A,$02
  LD (PlayerHit),A        ; hit flag
  LD (PlayerState),A      ; player state
  POP BC
  POP DE                  ; second countdown
  JR UpdatePyreMonk_0     ; count it down, nothing drawn

; Entity handler: sprite moving sideways at a constant speed (flames of the
; Pestilent Beast, actors of the ending)
;
; Drives the objects that only slide along x and are drawn from a block with
; the shift pairs (ShiftPairs): the two flames that run along the ledge of room
; 10 after the Beast has breathed (templates FlameLeftTemplate, moving left,
; and FlameRightTemplate, moving right; spawned by UpdateBeastFire; they kill
; the monk on contact, observed: the hit flag is set when the monk stands on
; the ledge), and the actors of the ending (the monk of the first scene,
; ActorMonkTemplate, the three flames of the pyre, ActorFlameTemplate, and the
; four crusaders, ActorCrusaderRTemplate and ActorCrusaderLTemplate: speed 0
; and limit 0, so they only animate). Slot (template slot, see UpdateFireball):
; +2 word x speed (signed 8.8; $FFC0 = -0.25 moving left, $0040 moving right),
; +4 byte x limit (high byte of x at which the object is removed: $18 for the
; left flame, $70 for the right flame, 0 for the actors) and +5 byte not used,
; +6 word x and +8 word y (8.8, high bytes in 2-pixel units), +$A word hit box
; offset (y, x), +$C word hit box far corner (y, x), +$E pointer to the sprite
; block (SpriteBlockFlame, SpriteBlockEndingMonk, SpriteBlockPyreCrusaderR ...:
; attribute, pointer to the shift pairs, height, then one graphics address per
; frame), +$10 byte animation counter and +$11 its reload, +$12 byte frame and
; +$13 number of frames.
;
; Each frame the speed is added to x; when the high byte of x equals the limit
; the slot is freed through FreeEntitySlot (SP back to slot+2, handler word
; cleared). Otherwise the position becomes the draw command's (y, x/4), A' = x
; for the shift phase, the hit box is tested against the monk (HitTest) and the
; code goes on at SetMovingSprite.
;
; SP Slot address + 2 (the handler word was popped by the RET that entered the
;    routine)
UpdateMovingSprite:
  POP BC                  ; x speed
  POP DE                  ; E x limit
; Also entered from the pyre monk (UpdatePyreMonk) with BC = 0 and DE = 0, SP
; at slot+4.
UpdateMovingSprite_Move:
  POP HL                  ; x word
  ADD HL,BC               ; x moves
  PUSH HL                 ; store x
  POP HL
  LD A,H                  ; x in 2-pixel units
  CP E                    ; at the limit?
  JP Z,FreeEntitySlot     ; yes: free the slot
  LD D,H                  ; D = x
  POP HL                  ; y word
  LD E,H                  ; E = y

; Moving sprite: position, hit test and draw
;
; Draw part of UpdateMovingSprite (which falls into it), also entered from
; Death's scythe: from UpdateScytheFalling and UpdateScytheSliding through
; Scythe_Draw, and from UpdateScytheSliding directly on its bug path (F51, E =
; x there). D = x and E = y in 2-pixel units, SP at slot+$A: makes the draw
; command position, keeps x in A' and tests the hit box (HitTest, which goes on
; at SetMovingSprite). Observed in rooms 10 and 18: SP = slot + $A, D and E the
; high bytes of the slot's x and y.
;
; Hardware: none.
;
; D x (2-pixel units)
; E y (2-pixel units)
; SP Slot address + $A
UpdateMovingSprite_Draw:
  LD L,E                  ; L = y
  LD H,D                  ; H = x
  LD A,H
  EX AF,AF'               ; A' = x: its low 2 bits select the shifted copy
  SRA H                   ; x / 4 = byte column
  SRA H
  LD (SpriteCmdPos),HL    ; position of the draw command: y, byte column
  LD HL,SetMovingSprite   ; continue after the hit test
  JP HitTest              ; hit test: sets the hit flag when the monk touches
                          ; the box

; Moving sprite: attribute, size and shifted copy, then the animation step
;
; Continuation of UpdateMovingSprite_Draw after the hit test HitTest (reached
; by a JP through $A881; SP is at slot+$E, the hit test has popped the two hit
; box words). It pops the pointer to the sprite block (slot +$E): attribute (to
; the draw command at SpriteCmd, +9, $ACDA), pointer to the shift pairs
; ShiftPairs, height, then the frame table. The pair for the shift phase x AND
; 3 (A') gives the column offset of that copy of the sprite, kept in A' for
; SelectFrame, and its width; with the height they go to the draw command (+6,
; $ACD7). The animation counter and frame number in slot +$10..+$13 are stepped
; by StepAnimation, which continues at QueueMovingSprite.
;
;   A' x in 2-pixel units; AND 3 is the shift phase
; O:A' Column offset of the shifted copy
; O:HL Sprite block + 4: the frame table
;   SP Slot address + $E
SetMovingSprite:
  POP HL                  ; sprite block
  LD A,(HL)               ; attribute
  INC HL
  LD (SpriteCmdAttr),A    ; of the draw command
  LD C,(HL)
  INC HL
  LD B,(HL)               ; BC = shift pair table
  INC HL
  EX DE,HL                ; DE = block + 3
  EX AF,AF'               ; A = x
  AND SPRITE_PHASE_MASK                 ; shift phase
  ADD A,A                 ; two bytes per pair
  LD L,A
  LD H,$00
  ADD HL,BC
  LD A,(HL)               ; column offset of that copy
  EX AF,AF'               ; keep it in A'
  INC HL
  LD C,(HL)               ; width of that copy
  EX DE,HL
  LD B,(HL)               ; B = height
  INC HL                  ; HL = frame table
  LD (SpriteCmdSize),BC   ; width, height of the draw command
  LD IX,QueueMovingSprite ; the animation step continues there
  JP StepAnimation        ; step the animation: frame in E

; Moving sprite: queue the sprite after the animation step
;
; Continuation of SetMovingSprite after StepAnimation. The POP BC takes back
; the animation counter that StepAnimation has just pushed, so that SP is at
; slot+$12 as the end of SelectFrame expects (it adds 4 to reach the next
; slot). HL points to the frame table and E is the frame number: SelectFrame
; takes table[E], adds the column offset in A' and queues the draw command.
;
; A' Column offset of the shifted copy
; E Frame number
; HL Frame table
QueueMovingSprite:
  POP BC                  ; SP at slot+$12
  JP SelectFrame          ; graphics = table[E] + offset; queue it, next slot

; Entity handler: Death flying right (room 18)
;
; Death, the flying reaper of room 18 (Banquet of Death), during the half of
; its patrol in which it moves right (the other half is UpdateDeathLeft).
; Entity handlers are not called: the slot walker RunObjectSlots sets SP to a
; slot of ObjectSlots and RETs, so the handler is entered with SP at slot+2
; (the handler word has been popped) and finds its state on the stack. It pops
; the words it needs, pushes back the ones that changed, and ends by jumping to
; RunObjectSlot with HL at the next slot (here through NextSlotAfterAnim).
;
; State used by this half, from the slot (ObjectSlots): +2 word speed (signed
; 8.8, 2-pixel units per frame), +4 byte left turning point, +5 byte right
; turning point, +6 word x (8.8; the high byte is in 2-pixel units). The speed
; is added to x; when the high byte of x equals the right turning point the
; handler word of the slot is rewritten with UpdateDeathLeft, so that from the
; next frame on the same speed is subtracted. Both halves go on at
; UpdateDeath_Common. IY is the address the animation code at ThrowDeathScythe
; jumps to when it has chosen the graphics: SelectFrameRight takes the second
; of the two frame tables of the sprite block (it skips the first), which is
; the table for this direction; UpdateDeathLeft uses SelectFrameLeft, the first
; table. Observed in room 18: with this handler Death moves right and its skull
; faces right, with UpdateDeathLeft it faces left.
;
; SP Slot address + 2 (the handler word was popped by the RET that entered the
;    routine)
UpdateDeathRight:
  LD IY,SelectFrameRight  ; frame table for moving right (the second one)
  POP BC                  ; speed
  POP DE                  ; D right turning point, E left turning point
  POP HL                  ; x (8.8)
  ADD HL,BC               ; x moves right
  PUSH HL                 ; store x
  POP HL                  ; SP is back at +8
  LD A,H                  ; x in 2-pixel units
  CP D                    ; at the right turning point?
  JR NZ,UpdateDeath_Common
  LD HL,$FFFA             ; -6: back to slot+2
  ADD HL,SP
  LD SP,HL
  LD HL,UpdateDeathLeft   ; next frame this slot is handled by the moving-left
                          ; half
  PUSH HL                 ; written over the handler word at slot+0
  POP HL
  POP BC                  ; pop speed, limits and x again
  POP DE
  POP HL
  JR UpdateDeath_Common

; Entity handler: Death flying left (room 18), and the body shared with
; UpdateDeathRight
;
; Death during the half of its patrol in which it moves left (see
; UpdateDeathRight, which has the layout of the slot and the way the two halves
; hand over to each other). The speed is subtracted from x; when the high byte
; of x equals the left turning point (slot +4) the handler word is rewritten
; with UpdateDeathRight. IY = SelectFrameLeft selects the first frame table of
; the sprite block (left). This is the handler of room object kind 16
; (EntityHandlers entry 16), so it is the half that runs first, from x = $09
; down to the turning point $08.
;
; SP Slot address + 2 (the handler word was popped by the RET that entered the
;    routine)
UpdateDeathLeft:
  LD IY,SelectFrameLeft   ; frame table for moving left (the first one)
  POP BC                  ; speed
  POP DE                  ; D right turning point, E left turning point
  POP HL                  ; x (8.8)
  OR A                    ; carry clear
  SBC HL,BC               ; x moves left
  PUSH HL                 ; store x
  POP HL                  ; SP is back at +8
  LD A,H                  ; x in 2-pixel units
  CP E                    ; at the left turning point?
  JR NZ,UpdateDeath_Common
  LD HL,$FFFA             ; -6: back to slot+2
  ADD HL,SP
  LD SP,HL
  LD HL,UpdateDeathRight  ; next frame this slot is handled by the moving-right
                          ; half
  PUSH HL                 ; written over the handler word at slot+0
  POP HL
  POP BC                  ; pop speed, limits and x again
  POP DE
  POP HL

; Death: move, turn and attack
;
; Common body of both halves. On entry H is the high byte of x, SP is at slot+8
; (the y word) and IY is set. It pops the y word and the timer (+$A counter,
; +$B reload): the timer counts down to 1 and reloads with the 50 frames of
; ATTACK_PERIOD (B is loaded with it every frame, so +$B always ends up 50),
; and a copy goes to BC' for ThrowDeathScythe, which throws a scythe when the
; counter equals 20 and shows the throwing frame from then on to the end of the
; cycle. Then it builds the position (H = x, L = y, both in 2-pixel units) in
; HL: A' keeps x (its low two bits select the shifted copy of the sprite), the
; word at SPAWN_POSITION is the position a spawned scythe starts from (y low, x
; high), and x/4 (the byte column) with y becomes the position of the draw
; command (SpriteCmdPos). Last, HitTest tests Death's hit box against the
; player and continues at SetDeathSprite. Observed in room 18: SP = slot + 8, H
; = the high byte of the slot's x at every entry.
;
; Hardware: none.
;
; H x (2-pixel units)
; IY SelectFrameLeft or SelectFrameRight (passed on to ThrowDeathScythe)
; SP Slot address + 8
UpdateDeath_Common:
  LD D,H                  ; D = x
  POP HL                  ; y (8.8)
  POP BC                  ; timer: C counter, B reload
  LD B,ATTACK_PERIOD      ; period of Death's throw
  DEC C                   ; count down
  JR NZ,UpdateDeath_Common_0
  LD C,B                  ; reload
UpdateDeath_Common_0:
  PUSH BC                 ; store the timer back
  EXX                     ; BC' = timer, for ThrowDeathScythe
  POP BC
  EXX
  LD E,H                  ; E = y
  LD L,H                  ; L = y
  LD H,D                  ; H = x
  LD A,H                  ; A' = x, its low 2 bits are the shift phase
  EX AF,AF'
  LD (SPAWN_POSITION),HL  ; start position of a thrown scythe (low y, high x)
  SRA H                   ; x / 4: byte column
  SRA H
  LD (SpriteCmdPos),HL    ; position of the draw command: y, byte column
  LD HL,SetDeathSprite    ; hit test, then continue at SetDeathSprite
  JP HitTest

; Death: attribute, width and height of the sprite for the current shift phase
;
; Continuation of UpdateDeath_Common after the hit test at HitTest (reached by
; the JP at SmcHitContinue; SP is at slot+16, the hit test has popped the two
; hit box words). It pops the pointer in slot +$10, which points five bytes
; into the behaviour block of kind 16 (BehaviourDeath): attribute byte, pointer
; to the pair table of (column offset, width) per shift phase, height in
; 2-pixel units, then the two frame tables. The attribute goes to the draw
; command at $ACD1 (+9, $ACDA); the pair for shift phase x AND 3 gives the
; offset of the shifted copy inside the frame (kept in A') and the width, and
; with the height they go to $ACD7. Then the animation counter and frame number
; in slot +$12..+$15 are stepped by StepAnimation, which continues at
; ThrowDeathScythe.
;
; Each frame is stored in the sprite sheet as four copies, each 2 pixels
; further right than the one before (4, 5, 5 and 5 columns for Death, 19 per
; frame), so x AND 3 picks the copy to draw.
;
;   A' x of Death in 2-pixel units; AND 3 is the shift phase
;   IY Address ThrowDeathScythe passes on control to (SelectFrameRight or
;      SelectFrameLeft)
; O:A' Column offset of the shifted copy, added to the frame's column by
;      SelectFrame
; O:HL Sprite block + 9: the first frame table
SetDeathSprite:
  POP HL                  ; pointer to the sprite block + 5
  LD A,(HL)               ; attribute
  INC HL
  LD (SpriteCmdAttr),A    ; attribute of the draw command
  LD E,(HL)               ; DE = pair table
  INC HL
  LD D,(HL)
  INC HL
  EX DE,HL                ; HL = pair table, DE = block + 8
  EX AF,AF'               ; A = x
  AND SPRITE_PHASE_MASK                 ; shift phase
  ADD A,A                 ; two bytes per pair
  LD C,A
  LD B,$00
  ADD HL,BC
  LD A,(HL)               ; column offset of that copy
  EX AF,AF'               ; keep it in A'
  INC HL
  LD C,(HL)               ; width of that copy
  EX DE,HL
  LD B,(HL)               ; B = height
  INC HL
  LD (SpriteCmdSize),BC   ; width, height of the draw command
  LD IX,ThrowDeathScythe  ; animation step continues at ThrowDeathScythe
  JP StepAnimation

; Death: throw a scythe every 50 frames, show the throwing frame, then queue
; the sprite
;
; Continuation of SetDeathSprite after the animation step StepAnimation (SP is
; at slot+18, E holds the frame number and D the number of frames, 2). BC'
; holds the timer of UpdateDeath_Common (C' is its counter after this frame's
; decrement). While C' is 20 or less E is replaced by D: frame 2, the third
; word of each of Death's frame tables, the throwing pose (arm stretched out,
; the scythe gone from its hands), is shown for the last 20 frames of the
; 50-frame cycle, from the frame of the throw on; frames 0 and 1 (flying with
; the scythe) alternate the rest of the time. Observed in room 18: E = 2 at
; SelectFrame for counters 20 to 1, screenshots of both poses. When C' is
; exactly 20 Death throws: sound effect 7 is requested, one of the two scythe
; templates (ScytheLeftTemplate flying left, ScytheRightTemplate flying right,
; chosen by bit 0 of the Z80's R register) goes into the word at
; SPAWN_TEMPLATE, which together with the start position at $5DFE is appended
; as a four-byte entry to the object list at $5DC0 (the pointer is
; ObjectListPtr) and the pending count in SpawnQueueCount goes up; GameFrame
; spawns the scythe at the end of the frame (SpawnQueuedObjects). In every case
; it jumps to IY, which is SelectFrameRight or SelectFrameLeft: they pick the
; graphics address of the frame from the table at HL and queue the draw
; command.
;
; Hardware: reads the R register as a random number.
;
; C' Timer counter of Death (50 down to 1)
; D Number of frames (2), the frame shown while C' is 20 or less
; E Frame number from StepAnimation (0 or 1)
; HL Sprite block + 9, passed on to IY
; IY Where to continue: SelectFrameRight or SelectFrameLeft
; SP Slot address + $12
ThrowDeathScythe:
  EXX                     ; switch to the alternate registers
  LD A,C                  ; A = timer counter (C')
  EXX
  CP $14                  ; throw when it is exactly 20 (the Z flag is kept to
                          ; ThrowDeathScythe_0)
  JR NC,ThrowDeathScythe_0
  LD E,D                  ; below 20: frame 2, the throwing pose
ThrowDeathScythe_0:
  JR NZ,ThrowDeathScythe_2
  LD E,D                  ; exactly 20: the throwing pose from this frame on
  EXX
  LD A,SFX_ENEMY_SHOT     ; sound effect
  LD (SoundRequest),A
  LD HL,ScytheLeftTemplate ; scythe flying left
  LD DE,ScytheRightTemplate ; scythe flying right
  LD A,R                  ; random bit
  AND $01
  JR NZ,ThrowDeathScythe_1
  EX DE,HL
ThrowDeathScythe_1:
  LD (SPAWN_TEMPLATE),HL  ; template address of the new object
  LD HL,SpawnQueueCount   ; one more spawn pending for SpawnQueuedObjects
  INC (HL)
  LD HL,SPAWN_TEMPLATE
  LD DE,(ObjectListPtr)   ; end of the object list
  LD BC,OBJECT_ENTRY_SIZE ; one entry: template, start position
  LDIR
  LD (ObjectListPtr),DE   ; object list pointer moves on
  EXX
ThrowDeathScythe_2:
  JP (IY)                 ; continue at SelectFrameRight or SelectFrameLeft

; Entity handler: Death's scythe falling
;
; The scythe Death throws (templates ScytheLeftTemplate and
; ScytheRightTemplate, spawned by ThrowDeathScythe). In this state it falls
; straight down: its y moves by the vertical speed and the cells under it are
; looked at. When they are free it is drawn (UpdateMovingSprite_Draw) and keeps
; falling. When a cell is harmful (tile class 4, TILE_HARMFUL) the slot is
; freed by way of FreeEntitySlotAtEntry (the four state words are pushed back
; first so that SP is at the slot again). This is how most scythes end: in 5000
; frames of room 18 (Jean out of play) 54 of the 96 scythes removed fell onto
; the harmful bottom row (y $4D, x $28-$58), the other 42 slid off the room
; edges (UpdateScytheSliding). When a cell is solid (class 1 to 3) the scythe
; lands: y is rounded down to a multiple of 4 (a whole character row), the
; handler word becomes UpdateScytheSliding and the scythe is drawn.
; UpdateScytheSliding then slides it sideways and hands it back to this routine
; when the floor ends, so a scythe that lands on a ledge moves along it
; (observed: it falls, alternates between the two states while it creeps
; sideways, falls off the end of the ledge and goes on) until it leaves the
; room at the side or reaches a harmful tile. Entity handlers are not called:
; the slot walker RunObjectSlots sets SP to a slot of ObjectSlots and RETs, so
; the handler is entered with SP at slot+2 (the handler word has been popped)
; and finds its state on the stack. It pops the words it needs, pushes back the
; ones that changed, and ends by jumping to RunObjectSlot with HL at the next
; slot (here through NextSlotAfterAnim).
;
; Slot layout (from the template, see ScytheLeftTemplate): +2 word x speed
; (signed 8.8, used by UpdateScytheSliding only; $FF80 = left), +4 word y speed
; ($00C0), +6 word x, +8 word y (8.8, high bytes in 2-pixel units), +$A word
; hit box offset (y, x), +$C word hit box far corner (y, x), +$E word pointer
; to the sprite block ($95DA: attribute, pair table $AC9F, height, four
; frames), +$10 animation counter and reload, +$12 frame number and number of
; frames (4), +$14 unused.
;
; The cell test reads the tile flag map: the row address table at $6100 gives
; the address of the row of the scythe's lower edge ((y + 7) / 4), the column
; is x / 4, and the flags of two cells (three when x AND 3 is not 0, the sprite
; straddling three cells) are ORed.
;
; SP Slot address + 2 (the handler word was popped by the RET that entered the
;    routine)
UpdateScytheFalling:
  POP BC                  ; x speed (not used while falling)
  POP BC                  ; y speed
  EXX
  POP DE                  ; DE' = x word (D' = x)
  EXX
  POP HL                  ; y word
  ADD HL,BC               ; y moves down
  PUSH HL                 ; store y
  EXX
  POP AF                  ; A = y high byte
  ADD A,$07               ; cell row of the lower edge = (y + 7) / 4, as a word
                          ; index
  RRA
  AND $3E
  LD L,A
  LD H,FlagRowTable/$100  ; row address table at $6100
  LD A,D                  ; x in 2-pixel units (D')
  LD C,A
  RRA
  RRA
  AND $1F                 ; byte column
  ADD A,(HL)              ; address of the cell in the tile flag map
  INC L
  LD H,(HL)
  LD L,A
  LD A,C
  AND SPRITE_PHASE_MASK                 ; x not a multiple of 4: three cells
  JR Z,UpdateScytheFalling_0
  LD A,(HL)
  INC L
UpdateScytheFalling_0:
  OR (HL)                 ; OR of the flags of the cells
  INC L
  OR (HL)
  AND TILE_CLASS_MASK     ; tile class
  JR Z,UpdateScytheFalling_2 ; free: keep falling
  BIT 2,A                 ; harmful?
  JR Z,UpdateScytheFalling_1 ; no: solid, the scythe lands
; Free the scythe. Also entered from UpdateScytheSliding when the scythe leaves
; the room or meets a harmful cell. The four pushes put SP back at slot+2 (the
; state words are overwritten with HL, which does not matter), and
; FreeEntitySlotAtEntry then zeroes the handler word and goes on to the next
; slot.
Scythe_Destroy:
  PUSH HL                 ; put the four state words back: SP = slot+2
  PUSH HL
  PUSH HL
  PUSH HL
  JP FreeEntitySlotAtEntry ; free the slot
UpdateScytheFalling_1:
  LD HL,$FFF8             ; -8: SP back to slot+2
  ADD HL,SP
  LD SP,HL
  LD HL,UpdateScytheSliding ; new handler: sliding
  PUSH HL                 ; written over the handler word at slot+0
  POP HL
  EXX
  POP BC                  ; pop x speed, y speed, x and y again
  POP BC
  POP DE
  POP HL
  LD A,H
  AND $FC                 ; y rounded down to a multiple of 4 ...
  LD H,A
  LD L,$00                ; ... with a zero fraction
  PUSH HL                 ; store y
  POP HL
  LD A,D                  ; A = x
  JR Scythe_Draw
UpdateScytheFalling_2:
  LD A,D                  ; A = x
  EXX
; Draw the scythe: D = x and E = y in 2-pixel units go to the common drawing
; code UpdateMovingSprite_Draw, which makes the draw command, tests the hit box
; against the player and queues the sprite. Also entered from
; UpdateScytheSliding.
Scythe_Draw:
  LD D,A                  ; D = x
  LD E,H                  ; E = y
  JP UpdateMovingSprite_Draw ; draw it (UpdateMovingSprite_Draw)

; Entity handler: Death's scythe sliding along a floor
;
; Second state of the scythe (see UpdateScytheFalling, which sets it when the
; scythe lands). The signed x speed in slot +2 is added to x ($FF80 moves the
; scythe left, $0080 right). It disappears (Scythe_Destroy) when x is $71 or
; more or less than 8 (2-pixel units, the edges of the room) or when a cell
; under it is harmful. If the cells under its lower edge have no solid flag the
; floor has ended and the handler word goes back to UpdateScytheFalling (it
; falls again); otherwise it is drawn.
;
; Slot layout: see UpdateScytheFalling.
;
; Bug: the drawing path at $BB50 (a solid cell under the scythe: with the
; scythe at its rounded height that only happens when it slides into a ledge
; or wall) loads D and E from the x position, because H holds x here and not
; y, so the scythe is drawn (and hit-tested) at y = x. Observed with the flags
; of its row poked solid (F51); not reached in 5000 frames of room 18 without
; pokes: the usual path (UpdateScytheFalling and this routine alternating, F50)
; draws through Scythe_Draw.
;
; SP Slot address + 2 (the handler word was popped by the RET that entered the
;    routine)
UpdateScytheSliding:
  POP BC                  ; x speed
  POP DE                  ; y speed (not used)
  POP HL                  ; x
  ADD HL,BC               ; x moves
  PUSH HL                 ; store x
  EXX
  POP DE                  ; D' = x word
  EXX
  POP DE                  ; y word
  LD A,D                  ; A = y
  EXX
  ADD A,$07               ; cell row of the lower edge, as a word index
  RRA
  AND $3E
  LD L,A
  LD H,FlagRowTable/$100  ; row address table at $6100
  LD A,D                  ; x in 2-pixel units
  CP $71                  ; right edge of the room
  JR NC,Scythe_Destroy
  CP $08                  ; left edge
  JR C,Scythe_Destroy
  LD C,A                  ; byte column and cell address as in
                          ; UpdateScytheFalling
  RRA
  RRA
  AND $1F
  ADD A,(HL)
  INC L
  LD H,(HL)
  LD L,A
  LD A,C
  AND SPRITE_PHASE_MASK    ; x not a multiple of 4: three cells
  JR Z,UpdateScytheSliding_0
  LD A,(HL)
  INC L
UpdateScytheSliding_0:
  OR (HL)
  INC L
  OR (HL)
  BIT 2,A                 ; harmful?
  JR NZ,Scythe_Destroy
  AND TILE_BLOCKS+TILE_STANDABLE ; solid cell under it: stay in this state
  JR NZ,UpdateScytheSliding_1
  LD HL,$FFF8             ; no floor: back to falling
  ADD HL,SP
  LD SP,HL
  LD HL,UpdateScytheFalling ; new handler: falling
  PUSH HL                 ; written over the handler word at slot+0
  POP HL
  EXX
  POP BC                  ; pop x speed, y speed, x and y again
  POP BC
  POP DE
  POP HL
  LD A,D
  JR Scythe_Draw
UpdateScytheSliding_1:
  LD A,D                  ; see the description: D and E both get x
  EXX
  LD D,H
  LD E,A
  JP UpdateMovingSprite_Draw

; Entity handler: Satan (room 24), patrolling up and down and firing, then
; vanishing in smoke
;
; Satan, the boss of the last room (room object kind 17, 8ED3). A two-part
; sprite: an upper half of 4 bytes and a lower half one byte narrower and one
; byte to the right, 12 units (24 pixels) lower. The routine is entered with SP
; at slot+2 (see UpdateDeathLeft for how handlers run); ObjectSlots describes
; the slots.
;
; Slot layout, in the order it is popped: +2 word y speed (signed 8.8, from the
; object's first parameter: $0080), +4 byte lower limit and +5 byte upper limit
; of y ($05 and $28), +6 word x, +8 word y (8.8, high bytes in 2-pixel units),
; +$A timer counter (starts at $96, reloads with ATTACK_PERIOD) and +$B reload,
; +$C word hit box offset (y, x) = 0, +$E word hit box far corner (y, x) = $17,
; $0F (with the offset 0, a box of 46 by 30 pixels), +$10 pointer into the
; behaviour block of kind 17 (BehaviourSatan + 5: attribute $42, width 4,
; height 12, then the frame tables), +$12 animation counter and reload, +$14
; frame number and number of frames (2).
;
; While the flag at ChaliceTaken is zero Satan is alive (the flag belongs to
; the item of room 24 made by ActionChalice, which exists only when all twelve
; crosses are collected and which sets the flag to $FF when the player takes
; it). Each frame y changes by the speed; when its high byte reaches a limit
; the speed is negated (the new speed acts next frame). The timer is
; decremented; when it reaches zero it reloads and Satan fires: sound effect 7
; and three entries in the object list for the fireballs FireballUpTemplate (up
; and left), FireballLeftTemplate (left) and FireballDownTemplate (down and
; left), all starting one unit left of and 9 units below Satan's position (the
; byte at +6 and +7 of the templates) and handled by UpdateFireball. The first
; volley comes about 150 frames after the room is entered (the timer starts at
; $96), then one every 50 frames (observed). Then the hit box is tested against
; the player (HitTest, which sets the hit flag at $A8A0 on contact) and the
; sprite is set up by SetSatanSprite.
;
; When the flag at ChaliceTaken is not zero Satan is finished: the first time
; this is seen (SatanSmoked is zero, and set to $FF) music track 7 starts, the
; script at $82D4 is started (the main loop runs the script whose address is in
; $9CEE when $9CE7 holds a NOP; it erases the ring of crosses), the done flag
; of the crosses display CrossRingDone is cleared (no code reads it), and
; Satan's own slot is overwritten with the smoke template SmokeTemplate, whose
; handler UpdateSatanSmoke draws a cloud of smoke in the place of Satan for 150
; frames (observed: a white cloud, then nothing). Later, when the room is
; entered again with SatanSmoked set, the slot is freed at once and Satan is
; gone for good.
;
; SP Slot address + 2 (the handler word was popped by the RET that entered the
;    routine)
UpdateSatan:
  LD A,(ChaliceTaken)     ; flag of the chalice of room 24 ($FF once taken)
  OR A
  JR Z,UpdateSatan_Alive  ; not taken: Satan is alive
  LD HL,SatanSmoked       ; smoke already made once?
  LD A,(HL)
  OR A
  JP NZ,FreeEntitySlotAtEntry ; yes: Satan is gone, free the slot
  LD (HL),$FF             ; remember it
  LD HL,MusicTrack
  LD (HL),MUSIC_TRACK_GAME_OVER ; music track 7
  LD HL,ScriptEraseCrosses ; start the script at $82D4
  LD (SmcEventScript+$0001),HL
  XOR A
  LD (RunEventScript),A   ; let the main loop run the script step
  LD (CrossRingDone),A    ; clear the done flag of the twelve crosses display
                          ; (ShowCrossRing sets it; nothing reads it)
  POP AF                  ; drop y speed ...
  POP AF                  ; ... and the limits
  POP HL                  ; x word
  POP DE                  ; y word
  LD L,D                  ; HL = (x, y)
  SRA H                   ; x / 4: byte column
  SRA H
  LD (SmokeTemplate+$0004),HL ; position of the upper half in the smoke
                              ; template (y, byte column)
  LD BC,$000C             ; 12 units = 24 pixels
  ADD HL,BC
  LD (SmokeTemplate+$0006),HL ; position of the lower half
  LD HL,$FFF6             ; SP - 10 is the start of the slot
  ADD HL,SP
  EX DE,HL
  LD HL,SmokeTemplate     ; the smoke template
  LD BC,SLOT_SIZE         ; size of a slot
  LDIR                    ; overwrite the whole slot with the template
  LD HL,$000C             ; 12 + SP is the next slot
  ADD HL,SP
  JP RunObjectSlot        ; on to the next slot
UpdateSatan_Alive:
  POP BC                  ; y speed
  EXX
  POP DE                  ; D' upper limit, E' lower limit
  EXX
  POP DE                  ; x word
  POP HL                  ; y word
  ADD HL,BC               ; y moves
  PUSH HL                 ; store y
  EXX
  POP HL                  ; HL' = y
  LD A,H
  CP D                    ; upper limit
  JR NC,UpdateSatan_Turn  ; reached: turn round
  CP E                    ; lower limit
  JR NC,UpdateSatan_Draw  ; inside the limits
UpdateSatan_Turn:
  LD HL,$FFF8             ; -8: SP back to slot+2
  ADD HL,SP
  LD SP,HL
  POP HL                  ; y speed
  LD A,H                  ; negate it
  CPL
  LD H,A
  LD A,L
  CPL
  LD L,A
  INC HL
  PUSH HL                 ; store it
  POP HL
  POP HL                  ; pop the three other words again
  POP HL
  POP HL
UpdateSatan_Draw:
  EXX                     ; main registers: D = x, H = y
  LD E,H                  ; E = y
  LD L,E                  ; L = y
  LD H,D                  ; H = x
  LD (SPAWN_POSITION),HL  ; start position of the fireballs (low y, high x)
  SRA H                   ; x / 4
  SRA H
  LD (SpriteCmdPos),HL    ; position of the upper half: y, byte column
  LD BC,$010C             ; one column right, 12 units lower
  ADD HL,BC
  LD (SpriteCmd2Pos),HL   ; position of the lower half
  POP BC                  ; timer: C counter, B reload
  LD B,ATTACK_PERIOD
  DEC C                   ; count down
  JR NZ,UpdateSatan_0
  LD C,B                  ; reload
UpdateSatan_0:
  PUSH BC                 ; store the timer back (the flags stay)
  POP BC
  JR NZ,UpdateSatan_Sprite ; not zero: no volley
  EXX
  LD A,SFX_ENEMY_SHOT     ; sound effect
  LD (SoundRequest),A
  LD HL,SpawnQueueCount   ; three spawns pending for SpawnQueuedObjects
  INC (HL)
  INC (HL)
  INC (HL)
  LD HL,FireballUpTemplate ; fireball up and left
  LD (SPAWN_TEMPLATE),HL  ; template address
  LD HL,SPAWN_TEMPLATE
  LD DE,(ObjectListPtr)   ; end of the object list
  LD BC,OBJECT_ENTRY_SIZE ; one entry
  LDIR
  LD HL,FireballLeftTemplate ; fireball straight left
  LD (SPAWN_TEMPLATE),HL
  LD HL,SPAWN_TEMPLATE
  LD C,OBJECT_ENTRY_SIZE
  LDIR
  LD HL,FireballDownTemplate ; fireball down and left
  LD (SPAWN_TEMPLATE),HL
  LD HL,SPAWN_TEMPLATE
  LD C,OBJECT_ENTRY_SIZE
  LDIR
  LD (ObjectListPtr),DE   ; object list pointer moves on
  EXX

; Satan: sprite and hit test
UpdateSatan_Sprite:
  LD HL,SetSatanSprite    ; hit test, then continue at SetSatanSprite
  JP HitTest

; Satan: attribute and sizes of the two halves, then the animation step
;
; Continuation of UpdateSatan after the hit test HitTest (SP is at slot+16). It
; pops the pointer in slot +$10, which points into the behaviour block of kind
; 17 (BehaviourSatan + 5): attribute, width and height of the upper half, then
; the frame tables. The attribute goes to both draw commands at $ACD1 and
; $ACDB, the width and height to the first, and the width less one to the
; second (the lower half is a byte narrower). Then StepAnimation steps the
; animation (slot +$12..+$15) and continues at QueueTwoPartSprite with HL = the
; frame tables.
;
; SP Slot address + 16 (the hit box words have been popped)
SetSatanSprite:
  POP HL                  ; pointer to the behaviour block + 5
  LD A,(HL)               ; attribute
  INC HL
  LD C,(HL)               ; width of the upper half
  INC HL
  LD B,(HL)               ; height of both halves
  INC HL
  LD (SpriteCmdAttr),A    ; attribute of the upper half
  LD (SpriteCmd2Attr),A   ; attribute of the lower half
  LD (SpriteCmdSize),BC   ; width, height of the upper half
  DEC C                   ; lower half one byte narrower
  LD (SpriteCmd2Size),BC  ; width, height of the lower half
StepTwoPartAnim:
  LD IX,QueueTwoPartSprite ; also entered from UpdateSatanSmoke with HL = the
                           ; frame tables
  JP StepAnimation        ; animation step, then QueueTwoPartSprite

; Two-part sprite: graphics of both halves for the current frame, queue both
; draw commands
;
; Continuation of StepAnimation for Satan (UpdateSatan) and for his smoke
; (UpdateSatanSmoke). HL points to the frame tables, E is the frame number. The
; table holds one graphics address per frame for the upper half and then,
; immediately after, one per frame for the lower half, so it is read at 2 * E
; and again 4 bytes later (the code assumes two frames). The addresses go to
; the draw commands at $ACD1 (graphics at $ACD5) and $ACDB ($ACDF). Unless the
; frame list is being run (the flag at $AA1F is not zero) both commands are
; copied, 20 bytes, to the end of the frame call list at ($BE58) by
; QueueTwoCommands, which also continues with the next slot.
;
; E Frame number (0 or 1)
; HL Frame tables: upper half graphics per frame, lower half graphics per frame
QueueTwoPartSprite:
  LD D,$00
  ADD HL,DE
  ADD HL,DE               ; HL = table + 2 * frame
  LD E,(HL)               ; graphics of the upper half
  INC HL
  LD D,(HL)
  INC HL
  LD (SpriteCmdGfx),DE    ; upper half command
  INC HL                  ; skip to the lower half table (2 frames)
  INC HL
  LD A,(HL)               ; graphics of the lower half
  INC HL
  LD H,(HL)
  LD L,A
  LD (SpriteCmd2Gfx),HL   ; lower half command
  LD A,(QueueDrawCmd)     ; frame list being run: do not queue
  OR A
  JP NZ,NextSlotAfterAnim
  LD HL,SpriteCmd         ; both draw commands
  LD DE,(FrameListPtr)    ; end of the frame call list
  JP QueueTwoCommands     ; copy 20 bytes, continue with the next slot

; Entity handler: the cloud of smoke that replaces Satan (150 frames)
;
; The slot is made from the template SmokeTemplate by UpdateSatan when the flag
; at ChaliceTaken shows Satan finished, so the layout is the template's: +2
; word lifetime (B counts down from 150, C unused), +4 word position of the
; upper half (y, byte column), +6 word position of the lower half, +8 word
; width and height of both halves (4 and 12), +$A, +$C and +$E three unused
; words, +$10 pointer to the behaviour block ($95F6: attribute $47, white, then
; the frame tables), +$12 animation counter and reload, +$14 frame number and
; number of frames. It has no hit box: the smoke does not hurt. Each frame the
; lifetime is decremented; at zero the slot is freed by FreeEntitySlotAtEntry.
; Otherwise both halves are drawn (StepTwoPartAnim, QueueTwoPartSprite) and the
; cloud animates through its two frames.
;
; SP Slot address + 2 (the handler word was popped by the RET that entered the
;    routine)
UpdateSatanSmoke:
  POP BC                  ; lifetime in B
  DJNZ UpdateSatanSmoke_0 ; count down
  PUSH BC                 ; expired: store it back ...
  JP FreeEntitySlotAtEntry ; ... and free the slot
UpdateSatanSmoke_0:
  PUSH BC                 ; store the lifetime back
  POP BC
  POP HL                  ; position of the upper half
  LD (SpriteCmdPos),HL    ; draw command 1
  POP HL                  ; position of the lower half
  LD (SpriteCmd2Pos),HL   ; draw command 2
  POP BC                  ; width, height of both halves
  LD (SpriteCmdSize),BC
  LD (SpriteCmd2Size),BC
  POP AF                  ; three words not used
  POP AF
  POP AF
  POP HL                  ; pointer to the behaviour block
  LD A,(HL)               ; attribute
  INC HL
  LD (SpriteCmdAttr),A    ; attribute of the upper half
  LD (SpriteCmd2Attr),A   ; attribute of the lower half
  JP StepTwoPartAnim      ; animation step, then QueueTwoPartSprite
