; Move Willy by one pass: jump, fall, keys, walking, ramps, conveyors, walls
;
; Called once per pass of the frame loop FrameLoop (not in ending stage 3),
; after the entities have been moved and before Willy is drawn (PlaceWilly). It
; changes only Willy's variables: Y WillyY, move state WillyMoveState, air
; state WillyAirState, walk frame WillyFrame, attribute address WillyAttrAddr,
; jump step WillyJumpStep and, when he walks off the room, the room itself (the
; ExitRoomLeft routines never return). It is one long routine whose parts are
; reached by JP and fall-through; the entry points are labelled and could be
; split (see the comments at each label). Order of work in a pass:
;
; 1. Rope. If WillyRope says Willy holds a rope (1-$80) the jump and ground
; code is skipped and the pass goes straight to the keys ($8ED4, which then
; skips the ground logic as well).
;
; 2. Jump (air state 1, MoveWilly). The step counter WillyJumpStep counts 0-17.
; In every pass Y changes by (step AND $FE) - 8 index units: -8 -8 -6 -6 -4 -4
; -2 -2 0 0 +2 +2 +4 +4 +6 +6 +8 +8, so he rises 40 units (20 pixel rows, 2.5
; character rows) in 8 passes, hangs for 3 and comes down again; at step 18 he
; is back at his take-off height and the state becomes 6 (a fall). If either of
; the two cells of his top row now holds the wall tile he bumps his head: Y
; becomes the row boundary below Y + 16 and a fall (state 2) starts. Walking
; goes on during the jump but the keys are not read again, so the direction at
; take-off cannot be changed. Each pass clicks the speaker (pitch follows the
; distance from the apex). The ground test is made only after steps 13 and 16,
; which is how Willy can land on a platform that is 2 or 1 character rows above
; his take-off floor; a platform 3 rows up cannot be landed on.
;
; 3. Ground test (MoveWilly_Ground), for every state other than a jump in
; progress (and after jump steps 13 and 16): while Y is between two character
; rows there is no ground; otherwise the two cells below Willy's feet (two rows
; down from WillyAttrAddr) are ground when neither holds the nasty tile and at
; least one is not background (any wall, floor, ramp or conveyor attribute
; counts; a nasty cell under his feet also kills him in MarkWillyCell). Below
; the bottom of the room he leaves through ExitRoomDown.
;
; 4. No ground (MoveWilly_Air). Walking is switched off (bit 1 of
; WillyMoveState cleared). State 0 becomes 2 (a fall starts, nothing moves
; yet); in a fall the state counts up once per pass (2, 3, ... $0F, then back
; to $0C), Willy drops 8 index units (4 pixel rows) per pass and the speaker
; clicks with a falling pitch. Falling has no horizontal movement.
;
; 5. Ground found (ReadWillyInput). A fall state of $0C or more kills Willy
; (KillWilly). From standing at the top of a fall that means a drop of 5
; character rows or more (4 rows is survived); after a jump that ended over a
; gap (state 6) a drop of 3 rows kills. The state becomes 0. Then the input is
; collected as one byte of key bits (bits 0, 2, 4 mean right, bits 1, 3, 5 mean
; left, 0 = pressed): the conveyor under his feet, the keys, the Kempston
; joystick (only if JoystickFlag) and, in ending stages 2 and 3, a forced right
; key. Left keys: Q E T U O 5 6 and joystick left. Right keys: W R Y I P 7 8
; and joystick right. Jump keys: CAPS SHIFT Z X C V B N M SYMBOL SHIFT SPACE, 0
; and joystick fire (ignored in ending stages 2 and 3). The key bits and the
; old move state select the new state in MoveStateTable (both directions
; together, which includes a key held against a conveyor, leave the state
; unchanged). A jump key starts the jump (air state 1, step 0) and the pass
; goes on to the walking code, with the move state just computed.
;
; 6. Walking (WalkWilly). Only if bit 1 of WillyMoveState is set and no rope is
; held. Willy takes one cell (8 pixels) every 4 passes: the frame WillyFrame
; counts 3 down to 0 when facing left and 0 up to 3 when facing right, and the
; step is taken in the pass that finds the frame at the end of its count (the
; frame is then reset). On the ground the step follows a ramp: a ramp cell next
; to his feet (the cell depends on the ramp direction RoomRampDir) moves Willy
; one row up or down together with the sideways step. The cells he steps into
; must not hold the wall tile: the cell beside his lower row (and beside a
; third row while he straddles three rows in a jump), for a step right also the
; cell beside his head row. A step left from column 0 or a step right from
; column 30 leaves the room through ExitRoomLeft or ExitRoomRight.
;
; Quirk (observed): a step to the right also tests the cell at his head level,
; a step to the left does not, so a wall cell that is only at head height
; blocks him when he walks right but not when he walks left.
;
; Hardware: reads the keyboard half rows with IN (ports $DFFE, $FBFE, $E7FE,
; $EFFE, $7EFE), the Kempston port $1F when JoystickFlag is set, and writes
; port $FE (speaker bits and the room's border colour) for the jump and fall
; clicks.
MoveWilly:
  LD A,(WillyRope)        ; rope variable
  DEC A                   ; bit 7 clear only for 1-$80: a rope is held
  BIT 7,A
  JP Z,ReadWillyInput     ; holding a rope: read the keys, no jump or fall
  LD A,(WillyAirState)    ; air state
  CP AIR_JUMPING
  JR NZ,MoveWilly_Ground  ; not in a jump: ground test
  LD A,(WillyJumpStep)    ; jump step
  AND $FE                 ; steps 2n and 2n+1 give the same change
  SUB JUMP_APEX_STEP      ; -8 at the start, 0 at the apex, +8 at the end
  LD HL,WillyY            ; Y index
  ADD A,(HL)
  LD (HL),A               ; Y after the rise or fall of the jump
  CP Y_WRAPPED_MIN
  JP NC,ExitRoomUp        ; Y wrapped below 0: through the top of the room
  CALL SetWillyCell       ; new attribute address; HL = top-left cell
  LD A,(TileWall)         ; wall attribute: is his head in a wall?
  CP (HL)
  JP Z,MoveWilly_HitHead  ; left cell of the top row: head bump
  INC HL
  CP (HL)
  JP Z,MoveWilly_HitHead  ; right cell of the top row: head bump
  LD A,(WillyJumpStep)    ; no bump: next jump step
  INC A
  LD (WillyJumpStep),A
  SUB JUMP_APEX_STEP      ; click delay from the distance to the apex
  JP P,MoveWilly_0
  NEG                     ; absolute value
MoveWilly_0:
  INC A                   ; delay = (distance + 1) * 8
  RLCA
  RLCA
  RLCA
  LD D,A
  LD C,STEP_SOUND_TOGGLES
  LD A,(RoomBorder)       ; border colour of the room
MoveWilly_1:
  OUT (ULA_PORT),A        ; click: speaker bits and border
  XOR BEEPER_BITS
  LD B,D
MoveWilly_2:
  DJNZ MoveWilly_2
  DEC C
  JR NZ,MoveWilly_1
  LD A,(WillyJumpStep)    ; jump step after this pass
  CP JUMP_END_STEP
  JP Z,MoveWilly_EndJump  ; step 18: the jump is over, fall
  CP JUMP_LAND_SECOND
  JR Z,MoveWilly_Ground   ; step 16: test for ground
  CP JUMP_LAND_FIRST
  JP NZ,WalkWilly         ; other steps: skip the ground test and walk
; Ground test: is there something to stand on? (reached from MoveWilly for
; every air state but a jump in progress, and falls through from the jump steps
; 13 and 16). While Y is between two character rows there is no ground. The
; jump code falls into this part.
MoveWilly_Ground:
  LD A,(WillyY)           ; Y index
  AND Y_BETWEEN_MASK      ; Y between two character rows?
  JR NZ,MoveWilly_Air     ; yes: no ground
  LD HL,(WillyAttrAddr)   ; attribute address of the top-left cell
  LD DE,$0002*SCREEN_COLS ; two rows down: the cells under his feet
  ADD HL,DE
  BIT 1,H                 ; $5E00 or more: below the room
  JP NZ,ExitRoomDown      ; falls out of the bottom of the room
  LD A,(TileNasty)        ; nasty attribute: not ground
  CP (HL)
  JR Z,MoveWilly_Air      ; nasty under the left foot: no ground
  INC HL
  LD A,(TileNasty)
  CP (HL)
  JR Z,MoveWilly_Air      ; nasty under the right foot: no ground
  LD A,(RoomTiles)        ; background attribute
  CP (HL)                 ; right cell
  DEC HL
  JP NZ,ReadWillyInput    ; right cell is not background: ground
  CP (HL)                 ; left cell
  JP NZ,ReadWillyInput    ; left cell is not background: ground
; No ground under Willy (or a jump between its ground tests): continue the jump
; walking, or start or continue a fall.
MoveWilly_Air:
  LD A,(WillyAirState)    ; air state
  CP AIR_JUMPING
  JP Z,WalkWilly          ; jumping: walk
  LD HL,WillyMoveState    ; move state
  RES MOVE_WALK_BIT,(HL)  ; no walking in a fall
  LD A,(WillyAirState)
  OR A
  JP Z,MoveWilly_StartFall ; was on the ground: start falling, nothing moves
                           ; yet
  INC A                   ; next fall state
  CP AIR_FALL_WRAP
  JR NZ,MoveWilly_Fall
  LD A,AIR_FATAL_FALL     ; states cycle 12-15 in a long fall
MoveWilly_Fall:
  LD (WillyAirState),A    ; store the fall state
  RLCA
  RLCA
  RLCA
  RLCA                    ; click delay = state * 16: lower pitch the longer he
                          ; falls
  LD D,A
  LD C,STEP_SOUND_TOGGLES
  LD A,(RoomBorder)       ; border colour of the room
MoveWilly_3:
  OUT (ULA_PORT),A
  XOR BEEPER_BITS
  LD B,D
MoveWilly_4:
  DJNZ MoveWilly_4
  DEC C
  JR NZ,MoveWilly_3
  LD A,(WillyY)           ; Y index
  ADD A,Y_FALL_STEP       ; 4 pixel rows down per pass
  LD (WillyY),A           ; and fall into SetWillyCell

; Set Willy's attribute-buffer address from a Y index
;
; Puts Willy's attribute-buffer address in step with his Y: sets
; WillyAttrAddr/85D4 to the cell of his top-left corner, attribute page $5C
; (rows 0-7) or $5D (rows 8-15), row = Y / 16, keeping the column already in
; WillyAttrAddr.
;
; Reached by falling through from the fall code in MoveWilly and called by
; MoveWilly, ReadWillyInput and the rope code in DrawEntities after it moves
; Willy.
SetWillyCell:
  AND Y_ROW_MASK          ; Y / 16 = character row, times 16
  LD L,A                  ; L = row * 16
  XOR A
  RL L                    ; row * 32; carry = row 8-15
  ADC A,SCREEN_ATTRS_BUF>>8 ; attribute page $5C or $5D
  LD H,A
  LD A,(WillyAttrAddr)    ; old address: keep its column
  AND COLUMN_MASK
  OR L
  LD L,A
  LD (WillyAttrAddr),HL   ; new attribute address
  RET

; End of jump, start of fall, head bump: Willy's air-state helpers
;
; The jump has reached step 18: it becomes a fall of state 6 from the take-off
; height.
MoveWilly_EndJump:
  LD A,AIR_FALL_AFTER_JUMP
  LD (WillyAirState),A
  RET
; Willy stands on nothing: start a fall (state 2); he does not move in this
; pass.
MoveWilly_StartFall:
  LD A,AIR_FALL_START
  LD (WillyAirState),A
  RET
; Head bump in a jump: round Y up to the next character row boundary, start a
; fall (state 2) and stop walking.
MoveWilly_HitHead:
  LD A,(WillyY)           ; Y index
  ADD A,Y_ROW_STEP
  AND Y_ROW_MASK          ; row boundary below
  LD (WillyY),A
  CALL SetWillyCell       ; attribute address from the new Y
  LD A,AIR_FALL_START
  LD (WillyAirState),A
  LD HL,WillyMoveState    ; move state
  RES MOVE_WALK_BIT,(HL)  ; stop walking
  RET

; Read Willy's input: landing, conveyor, keys, move state, jump start
;
; Willy stands on ground or holds a rope: land, collect the key bits, update
; the move state and start a jump if asked. Reached by JP from the ground test
; and from the rope test in MoveWilly. The key bits go into E (0 = pressed;
; bits 0, 2, 4 = right, bits 1, 3, 5 = left), starting as $FF.
;
; Hardware: reads the keyboard (ports $FBFE, $DFFE, $EFFE, $F7FE, $7EFE...) and
; the Kempston port when JoystickFlag is set.
ReadWillyInput:
  LD E,KEYBITS_NONE       ; E = key bits, nothing pressed
  LD A,(WillyRope)        ; rope variable
  DEC A
  BIT 7,A
  JR Z,MoveWilly_Keys     ; holding a rope: skip landing and conveyor
  LD A,(WillyAirState)    ; air state
  CP AIR_FATAL_FALL
  JP NC,KillWilly         ; landed from a fall of state $0C or more: killed
  XOR A
  LD (WillyAirState),A    ; state 0: standing
  LD A,(TileConveyor)     ; conveyor attribute
  CP (HL)                 ; left cell under his feet (HL) is conveyor?
  JR Z,MoveWilly_Conveyor
  INC HL
  CP (HL)                 ; right cell under his feet is conveyor?
  JR NZ,MoveWilly_Keys
MoveWilly_Conveyor:
  LD A,(RoomConveyorDir)  ; conveyor direction 0 or 1
  SUB $03                 ; direction 0: $FD (left bit clear), 1: $FE (right
                          ; bit clear)
  LD E,A                  ; conveyor as a pressed key
MoveWilly_Keys:
  LD BC,KEYROW_P_Y        ; P O I U Y: right left right left right
  IN A,(C)
  AND KEYS_MASK
  OR KEYBITS_PAD_P        ; bit 5 is not a key here
  AND E                   ; combine with E
  LD E,A
  LD A,(EndingStage)      ; ending stage
  AND $01<<ENDING_AUTORUN_BIT ; stages 2 and 3: bit 1
  RRCA                    ; to bit 0
  XOR E                   ; flips the P bit: the right key is forced on in the
                          ; ending run
  LD E,A
  LD BC,KEYROW_Q_T        ; Q W E R T: shifted to bits 1-5: left right left
                          ; right left
  IN A,(C)
  AND KEYS_MASK
  RLC A                   ; bit 0 is left free
  OR $01
  AND E
  LD E,A
  LD B,KEYROWS_5_6_HI     ; half rows 1-5 and 6-0 together
  IN A,(C)
  RRCA                    ; keys 5 and 6 (bit 4) to bit 3: left
  OR ~($01<<(KEY_6_BIT-$01)) ; keep only bit 3
  AND E
  LD E,A
  LD B,KEYROW_0_9_HI      ; 0 9 8 7 6
  IN A,(C)                ; key 8 (bit 2): right
  OR ~($01<<KEY_8_BIT)    ; keep only bit 2
  AND E
  LD E,A
  IN A,(C)                ; same row again
  RRCA                    ; key 7 (bit 3) to bit 2: right
  OR ~($01<<KEY_8_BIT)    ; keep only bit 2
  AND E
  LD E,A
  LD A,(JoystickFlag)     ; Kempston joystick present?
  OR A
  JR Z,MoveWilly_State    ; no
  LD BC,KEMPSTON_PORT
  IN A,(C)                ; bit 0 right, bit 1 left, 1 = pressed
  AND KEMPSTON_LR_MASK
  CPL                     ; 0 = pressed, as the keys
  AND E
  LD E,A
MoveWilly_State:
  LD C,$00                ; C = row of the state table: no direction
  LD A,E                  ; left bits
  AND KEYBITS_LEFT
  CP KEYBITS_LEFT
  JR Z,ReadWillyInput_0   ; no left key
  LD C,STATE_ROW_LEFT     ; left row
  XOR A                   ; a direction key resets the idle counter
  LD (IdleCounter),A      ; clear the idle counter
ReadWillyInput_0:
  LD A,E                  ; right bits
  AND KEYBITS_RIGHT
  CP KEYBITS_RIGHT
  JR Z,ReadWillyInput_1   ; no right key
  SET STATE_ROW_RIGHT_BIT,C ; adds 8: right row (12 when both)
  XOR A
  LD (IdleCounter),A      ; clear the idle counter
ReadWillyInput_1:
  LD A,(WillyMoveState)   ; old move state
  ADD A,C                 ; index = old state + key row
  LD C,A
  LD B,$00
  LD HL,MoveStateTable
  ADD HL,BC
  LD A,(HL)               ; new move state
  LD (WillyMoveState),A
MoveWilly_JumpKeys:
  LD BC,KEYROWS_BOTTOM    ; half rows CAPS SHIFT-V and B-SPACE
  IN A,(C)
  AND KEYS_MASK
  CP NO_KEYS
  JR NZ,MoveWilly_Jump    ; any of them: jump
  LD B,KEYROW_0_9_HI      ; key 0
  IN A,(C)
  BIT 0,A                 ; key 0 is bit 0
  JR Z,MoveWilly_Jump     ; pressed: jump
  LD A,(JoystickFlag)     ; Kempston joystick present?
  OR A
  JR Z,WalkWilly          ; no joystick: no jump key
  LD BC,KEMPSTON_PORT
  IN A,(C)
  BIT KEMPSTON_FIRE_BIT,A
  JR Z,WalkWilly          ; fire not pressed: no jump
MoveWilly_Jump:
  LD A,(EndingStage)      ; ending stage
  BIT ENDING_AUTORUN_BIT,A ; stage 2 or 3: jump ignored
  JR NZ,WalkWilly
  XOR A
  LD (WillyJumpStep),A    ; jump step 0
  LD (IdleCounter),A      ; clear the idle counter
  INC A
  LD (WillyAirState),A    ; air state 1: jumping
  LD A,(WillyRope)        ; rope variable
  DEC A
  BIT 7,A
  JR NZ,WalkWilly         ; no rope held: walk in this pass
  LD A,ROPE_LET_GO        ; jumping off a rope: let go, cannot grab for 16
                          ; passes
  LD (WillyRope),A
  LD A,(WillyY)           ; Y index
  AND Y_ROW_MASK          ; to a row boundary
  LD (WillyY),A
  LD HL,WillyMoveState    ; move state
  SET MOVE_WALK_BIT,(HL)  ; he leaves the rope walking in the direction he
                          ; faces
  RET

; Walk Willy one step: ramps and walls
;
; Takes a step when the move state WillyMoveState asks for one, climbing or
; descending ramps and stopping at walls. Reached by JP from ReadWillyInput.
;
; Hardware: none (reads the attribute buffer, port reads are in
; ReadWillyInput).
WalkWilly:
  LD A,(WillyMoveState)   ; move state
  AND MOVE_WALK_MASK
  RET Z                   ; not walking: done
  LD A,(WillyRope)        ; rope variable
  DEC A
  BIT 7,A
  RET Z                   ; holding a rope: no walking
  LD A,(WillyMoveState)   ; move state
  AND MOVE_FACING_LEFT
  JP Z,MoveWilly_Right    ; facing right
  LD A,(WillyFrame)       ; walk frame
  OR A
  JR Z,MoveWilly_LeftStep ; left: the step is taken when the frame is 0
  DEC A
  LD (WillyFrame),A
  RET
; Step left (frame 0 reached). With the air state 0 first look for a ramp cell,
; which sets BC, the change of the attribute address (-32 up, +32 down, 0
; level). The cell to test is the one at offset $1F from his top-left cell
; (direction 0: one row down, one column left, the next ramp cell up the slope)
; or $41 (direction 1: two rows down, one column right, under his right foot,
; the next ramp cell down the slope).
MoveWilly_LeftStep:
  LD A,(WillyAirState)    ; air state
  LD BC,$0000             ; BC = 0: level step
  CP $00
  JR NZ,MoveWilly_LeftCells ; jumping: no ramp
  LD HL,(WillyAttrAddr)   ; attribute address of the top-left cell
  LD BC,$0000
  LD A,(RoomRampDir)      ; ramp direction: 0 rises left, 1 rises right
  DEC A                   ; $FF or 0
  OR $A1                  ; $FF or $A1
  XOR $E0                 ; $1F or $41: the cell to test, see above
  LD E,A
  LD D,$00
  ADD HL,DE               ; cell to test
  LD A,(TileRamp)         ; ramp attribute
  CP (HL)                 ; ramp cell?
  JR NZ,MoveWilly_LeftCells ; no: level step
  LD BC,SCREEN_COLS       ; a row down
  LD A,(RoomRampDir)      ; ramp direction
  OR A
  JR NZ,MoveWilly_LeftCells ; direction 1: ramp rises right, the step goes down
  LD BC,-SCREEN_COLS      ; direction 0: ramp rises left, the step goes up
MoveWilly_LeftCells:
  LD HL,(WillyAttrAddr)   ; attribute address of the top-left cell
  LD A,L                  ; column
  AND COLUMN_MASK
  JP Z,ExitRoomLeft       ; column 0: through the left of the room
  ADD HL,BC               ; row change of the ramp
  DEC HL                  ; one column left
  LD DE,SCREEN_COLS
  ADD HL,DE               ; second row of Willy: the cell left of his lower
                          ; body
  LD A,(TileWall)         ; wall attribute
  CP (HL)                 ; wall: blocked
  RET Z
  LD A,(WillyY)           ; Y index
  SRA C                   ; half the row change in Y units: -16, 0 or +16
  ADD A,C
  LD B,A                  ; B = new Y
  AND Y_CELL_MASK
  JR Z,WalkWilly_0        ; on a row boundary: two rows only
  LD A,(TileWall)         ; third row of a jump
  ADD HL,DE
  CP (HL)                 ; wall: blocked
  RET Z
  OR A
  SBC HL,DE               ; back to row 2
WalkWilly_0:
  OR A                    ; row 1: the cell at his head level is not tested
  SBC HL,DE
  LD (WillyAttrAddr),HL   ; new attribute address
  LD A,B
  LD (WillyY),A           ; new Y
  LD A,WALK_LAST_FRAME
  LD (WillyFrame),A       ; frame restarts at 3 when facing left
  RET
; Facing right: count the frame up 0-3 and step in the pass that finds it at 3.
MoveWilly_Right:
  LD A,(WillyFrame)       ; walk frame
  CP WALK_LAST_FRAME
  JR Z,MoveWilly_RightStep ; frame 3: step
  INC A
  LD (WillyFrame),A
  RET
; Step right (frame 3 reached), with the ramp test as for MoveWilly_LeftStep.
; The cell to test is at offset $40 from his top-left cell (direction 0: two
; rows down, under his left foot, the next ramp cell down the slope) or $22
; (direction 1: one row down, two columns right, the next ramp cell up the
; slope).
MoveWilly_RightStep:
  LD A,(WillyAirState)    ; air state
  LD BC,$0000             ; BC = 0: level step
  OR A
  JR NZ,MoveWilly_RightCells ; jumping: no ramp
  LD HL,(WillyAttrAddr)
  LD A,(RoomRampDir)      ; ramp direction
  DEC A                   ; $FF or 0
  OR $9D                  ; $FF or $9D
  XOR $BF                 ; $40 or $22: the cell to test, see above
  LD E,A
  LD D,$00
  ADD HL,DE               ; cell to test
  LD A,(TileRamp)         ; ramp attribute
  CP (HL)                 ; ramp cell?
  JR NZ,MoveWilly_RightCells ; no: level step
  LD BC,SCREEN_COLS       ; a row down
  LD A,(RoomRampDir)      ; ramp direction
  OR A
  JR Z,MoveWilly_RightCells ; direction 0: ramp rises left, the step goes down
  LD BC,-SCREEN_COLS      ; direction 1: ramp rises right, the step goes up
MoveWilly_RightCells:
  LD HL,(WillyAttrAddr)   ; attribute address
  ADD HL,BC               ; row change of the ramp
  INC HL                  ; two columns right: the column beyond Willy
  INC HL
  LD A,L
  AND COLUMN_MASK
  JP Z,ExitRoomRight      ; column 0: through the right of the room
  LD DE,SCREEN_COLS
  LD A,(TileWall)         ; wall attribute
  ADD HL,DE               ; second row of Willy
  CP (HL)                 ; wall: blocked
  RET Z
  LD A,(WillyY)           ; Y index
  SRA C                   ; half the row change in Y units
  ADD A,C
  LD B,A                  ; B = new Y
  AND Y_CELL_MASK
  JR Z,WalkWilly_1        ; on a row boundary: skip the third row
  LD A,(TileWall)         ; third row of a jump
  ADD HL,DE
  CP (HL)                 ; wall: blocked
  RET Z
  OR A
  SBC HL,DE               ; back to row 2
WalkWilly_1:
  LD A,(TileWall)         ; wall attribute
  OR A
  SBC HL,DE               ; row 1: the cell at head level
  CP (HL)                 ; wall: blocked (unlike the left step)
  RET Z
  DEC HL                  ; one column back: Willy's new left cell
  LD (WillyAttrAddr),HL   ; new attribute address
  XOR A
  LD (WillyFrame),A       ; frame restarts at 0 when facing right
  LD A,B
  LD (WillyY),A           ; new Y
  RET

; Abandon the frame update and mark Willy as killed
;
; Jumped to (never called) from the collision and hazard checks of the frame
; update. Two entry points:
;
; $90B6 drops two return addresses (for a hazard check called two levels below
; FrameLoop) and falls into $90B7, which drops one more (for a routine called
; directly from FrameLoop). The frame loop FrameLoop is entered by JP with an
; empty stack (SP=$5BFE), so both leave the stack empty again. Observed: at
; $90B7 reached from DrawEntities the word on the stack is $89EF, the return
; address inside FrameLoop.
;
; Then Willy's state variable at $85D1 is set to $FF and control jumps to
; $89F5, the part of FrameLoop that copies the $6000 buffer to the screen, so
; the rest of the frame update (remaining sprites and checks) is skipped.
; Inferred from the code: ResumeAfterPause tests $85D1 = $FF at $8B17 and goes
; to $8C01, a colour flash with sound, so $FF means Willy has been killed.
;
; Reached from: the nasty-tile check MarkWillyCell (JP Z,$90B6); $8EE3 in
; MoveWilly (when $85D1 >= $0C); $9231 and $9297 in DrawEntities (collision
; with an entity); $9566 in UpdateBedroom (collision of the sprite drawn at
; $686E with what is already in the buffer, in room $23).
;
; Hardware: none directly (the jump target copies the buffer to the screen).
KillWillyNested:
  POP HL
; This entry point is used by the routines at MoveWilly, DrawEntities and
; UpdateBedroom.
KillWilly:
  POP HL
  LD A,WILLY_KILLED
  LD (WillyAirState),A
  JP FrameLoop_Present
