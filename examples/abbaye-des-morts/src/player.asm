; Player variables: state, animation, speed, tile probes, hit flag and position
; of Jean
;
; The state of the monk, rewritten every frame by ProbePlayer (probes) and
; UpdatePlayer (state machine). Positions are 8.8 fixed point words: the low
; byte is a fraction, the high byte counts 2-pixel units, so X runs 0-$7F
; across the 256-pixel room and Y 0-$57 down the 176-pixel room area; X/4 is
; the byte column of the sprite and X mod 4 the sub-byte shift phase (0, 2, 4
; or 6 pixels). The top left corner of the 16x24 pixel sprite is at (X, Y).
; Positions outside the room are held modulo 256: just left of the room X is
; $FC-$FF, just above it Y is $FA-$FF (CheckRoomExit).
;
; +0 byte PlayerState: 0 no player (the intro and the ending: nothing runs), 1
; dying, 2 jumping (rising), 3 crouching, 4 standing or walking, 5 falling, $FF
; debug room warp (DebugWarpRoom, entered by EnterRoomWarp with the cheat on)
; +1 byte PlayerAnimTimer: frames left to the next animation frame (reloaded
; with 8 when walking, 4 when dying) +2 byte PlayerFrame: animation frame, 0-1
; walking (also crouching), 2 in the air, 0-8 when dying (7 is not drawn, 8
; ends the death) +3 byte PlayerFacing: 0 right, 1 left +4 word PlayerSpeedY:
; vertical speed, 8.8 units per frame, positive up while jumping and down while
; falling ($01FE at the start of a jump, at most $021C in a fall) +6 word
; PlayerSpare: unused (no instruction refers to it, and it was not written in
; tests/inputs/play.txt or a 3000-frame fuzz run) +8 byte PlayerTileHead: OR of
; the tile flags (TileFlags) at the head +9 byte PlayerTileRight: the same at
; the right side +A byte PlayerTileFeet: the same just below the feet +B byte
; PlayerTileLeft: the same at the left side +C byte PlayerHit: 0, 4 when a
; harmful tile (class 4) touches the body, $FF when an enemy box overlaps
; (HitTestDone, UpdatePlant_Spit), 2 set by the pyre monk of the ending
; (UpdatePyreMonk, with PlayerState 2 so that UpdatePlayerActive runs); any
; value but 0 kills the monk in UpdatePlayerActive +D word
; PlayerX: horizontal position, 8.8 (high byte 0-$7F) +F word PlayerY: vertical
; position, 8.8 (high byte 0-$57)
PlayerState:
  DEFB $04                ; State: 0 no player, 1 dying, 2 jumping, 3
                          ; crouching, 4 standing/walking, 5 falling, $FF
                          ; debug warp
PlayerAnimTimer:
  DEFB $00                ; Animation timer
PlayerFrame:
  DEFB $00                ; Animation frame
PlayerFacing:
  DEFB $00                ; Facing: 0 right, 1 left
PlayerSpeedY:
  DEFW $0000              ; Vertical speed (8.8)
PlayerSpare:
  DEFB $00,$00            ; Unused
PlayerTileHead:
  DEFB $00                ; Tile flags at the head
PlayerTileRight:
  DEFB $00                ; Tile flags at the right side
PlayerTileFeet:
  DEFB $00                ; Tile flags just below the feet
PlayerTileLeft:
  DEFB $00                ; Tile flags at the left side
PlayerHit:
  DEFB $00                ; Hit flag (4 harmful tile, $FF enemy, 2 ending)
PlayerX:
  DEFW $2400              ; X (8.8, high byte in 2-pixel units, 0-$7F)
PlayerY:
  DEFW $4400              ; Y (8.8, high byte in 2-pixel units, 0-$57)

; Probe the tiles around Jean and build his hit box
;
; Run first in every game frame (GameFrame). Does nothing when the player state
; is 0. Otherwise it turns the position (X, Y: the high bytes of PlayerX and
; PlayerY, 2-pixel units) into the hit box PlayerBoxXMax and samples the tile
; flag map at points around the body with the probe routines below, one result
; per side: PlayerTileHead head, PlayerTileRight right, PlayerTileFeet feet
; (the row just under the sprite), PlayerTileLeft left, and the hit flag
; PlayerHit (4 when a harmful tile, flag bit 2, touches the body; the enemy
; tests HitTestDone and UpdatePlant_Spit may set it to $FF later in the frame).
; The player routine UpdatePlayerActive reads these bytes.
;
; Standing (any state but crouching): hit box x X+2..X+6, y Y+2..Y+12; head at
; (X+2 and X+5, Y+1), left at X+1 and right at X+6 (y Y+3, Y+7, Y+11), feet at
; (X+2 and X+5, Y+12), harmful tiles at the eight points of ProbeRing (X+2 and
; X+5; Y+2, Y+5, Y+8, Y+11). Crouching: hit box x X+1..X+8, y Y+7..Y+13; head
; at (X+2 and X+5, Y+6), left (X, Y+11), right (X+8, Y+11), feet at (X+1, X+4
; and X+7, Y+12), harmful tiles at the six points of ProbeBlock3x2 (X+1, X+4,
; X+7; Y+7, Y+11). Every point and both boxes observed: the routine run with
; one marked cell of the flag map at a time, for each X mod 4 and Y mod 4 in
; both postures.
;
; Hardware: none; reads the tile flag map.
ProbePlayer:
  LD HL,(PlayerY)         ; H = Y
  LD A,H
  LD HL,(PlayerX)         ; HL = (X, Y) in 2-pixel units
  LD L,A
  LD A,(PlayerState)      ; player state
  OR A
  RET Z                   ; none: nothing to do
  CP PLAYER_CROUCHING
  JR NZ,ProbePlayer_Stand ; not crouching
; Crouching.
  LD A,H                  ; hit box x: X+1 .. X+8
  ADD A,$01
  LD D,A
  ADD A,$07
  LD E,A
  LD (PlayerBoxXMax),DE   ; (PlayerBoxXMax, PlayerBoxXMin)
  LD A,L                  ; hit box y: Y+7 .. Y+13
  ADD A,$07
  LD D,A
  ADD A,$06
  LD E,A
  LD (PlayerBoxYMax),DE   ; (PlayerBoxYMax, PlayerBoxYMin)
  LD D,COLUMN_MASK
  LD BC,$0206             ; probe (X+2, Y+6) and (X+5, Y+6)
  CALL ProbePair2
  LD A,E
  LD (PlayerTileHead),A   ; head
  LD BC,$000B             ; (X, Y+11)
  CALL ProbePoint
  LD A,E
  LD (PlayerTileLeft),A   ; left
  LD BC,$080B             ; (X+8, Y+11)
  CALL ProbePoint
  LD A,E
  LD (PlayerTileRight),A  ; right
  LD BC,$010C             ; (X+1, X+4, X+7; Y+12)
  CALL ProbeRowOf3
  LD A,E
  LD (PlayerTileFeet),A   ; feet
  LD BC,$0107             ; 3x2 block from (X+1, Y+7)
  CALL ProbeBlock3x2
  LD A,E
  AND TILE_HARMFUL        ; harmful tile class
  LD (PlayerHit),A        ; hit flag
  RET
; Standing, walking, jumping or falling.
ProbePlayer_Stand:
  LD A,H                  ; hit box x: X+2 .. X+6
  ADD A,$02
  LD D,A
  ADD A,$04
  LD E,A
  LD (PlayerBoxXMax),DE   ; (PlayerBoxXMax, PlayerBoxXMin)
  LD A,L                  ; hit box y: Y+2 .. Y+12
  ADD A,$02
  LD D,A
  ADD A,$0A
  LD E,A
  LD (PlayerBoxYMax),DE   ; (PlayerBoxYMax, PlayerBoxYMin)
  LD D,COLUMN_MASK
  LD BC,$0201             ; (X+2 and X+5, Y+1)
  CALL ProbePair
  LD A,E
  LD (PlayerTileHead),A   ; head
  LD BC,$0103             ; (X+1; Y+3, Y+7, Y+11)
  CALL ProbeColumnOf3
  LD A,E
  LD (PlayerTileLeft),A   ; left
  LD BC,$0603             ; (X+6; Y+3, Y+7, Y+11)
  CALL ProbeColumnOf3
  LD A,E
  LD (PlayerTileRight),A  ; right
  LD BC,$020C             ; (X+2 and X+5, Y+12)
  CALL ProbePair
  LD A,E
  LD (PlayerTileFeet),A   ; feet
  LD BC,$0202             ; ring from (X+2, Y+2)
  CALL ProbeRing
  LD A,E
  AND TILE_HARMFUL        ; harmful tile class
  LD (PlayerHit),A        ; hit flag
  RET

; Land: snap Jean to the cell row when his feet are in a floor
;
; Called by the falling code (UpdatePlayerActive) after Y has changed. Probes
; the two points under the feet (X+2 and X+5, Y+12). If one of the cells has
; flag bit 0 or 1 (standable or blocking) Y is set to the top of the cell row:
; the fraction is cleared and the high byte loses its low two bits (a cell row
; is 4 units high), so Jean stands exactly on the tile. The state is not
; changed here: the next frame the feet flags tell the fall code that he has
; landed.
;
; Hardware: none.
LandPlayer:
  LD HL,(PlayerY)         ; H = Y
  LD A,H
  LD HL,(PlayerX)         ; HL = (X, Y)
  LD L,A
  LD D,COLUMN_MASK
  LD BC,$020C             ; (X+2 and X+5, Y+12)
  CALL ProbePair
  LD A,E
  AND TILE_BLOCKS|TILE_STANDABLE
  RET Z                   ; no floor
  LD HL,PlayerY           ; Y fraction
  LD (HL),$00
  INC HL                  ; Y high byte
  LD A,(HL)
  AND $FF-SUBROW_MASK     ; round down to a cell row
  LD (HL),A
  RET

; Probe two cells side by side (copy of ProbePair)
;
; The same code as ProbePair, used by the crouching branch of ProbePlayer for
; the head: the flags of the cells at (x+B, y+C) and (x+B+3, y+C) are ORed into
; E (E starts at 0). Three units are less than the 4 units of a cell, so the
; two points are in the same or in neighbouring cell columns. B is left
; increased by 3.
;
; Hardware: none; reads the tile flag map.
;
;   HL Position: H = x, L = y (2-pixel units)
;   B Offset of the first point in x
;   C Offset of the first point in y
;   D Column mask (always $1F)
; O:E OR of the tile flags at the points
ProbePair2:
  LD E,$00
  CALL ProbeCell
  INC B
  INC B
  INC B
  JP ProbeCell

; Probe three cells in a row
;
; ORs the tile flags of the cells at (x+B, y+C), (x+B+3, y+C) and (x+B+6, y+C)
; into E (E starts at 0); the crouching branch of ProbePlayer uses it for the
; feet. B is left increased by 6.
;
; Hardware: none; reads the tile flag map.
;
;   HL Position: H = x, L = y (2-pixel units)
;   B Offset of the first point in x
;   C Offset of the first point in y
;   D Column mask (always $1F)
; O:E OR of the tile flags at the points
ProbeRowOf3:
  LD E,$00
  CALL ProbeCell
  INC B
  INC B
  INC B
  CALL ProbeCell
  INC B
  INC B
  INC B
  JP ProbeCell

; Probe one cell
;
; ORs the tile flags of the cell at (x+B, y+C) into E (E starts at 0). Used for
; the left and right sides of the crouching monk (ProbePlayer).
;
; Hardware: none; reads the tile flag map.
;
;   HL Position: H = x, L = y (2-pixel units)
;   B Offset of the point in x
;   C Offset of the point in y
;   D Column mask (always $1F)
; O:E Tile flags of the cell
ProbePoint:
  LD E,$00
  JP ProbeCell

; Probe a block of 3 x 2 points
;
; ORs the tile flags of six cells into E (E starts at 0): (x+B, y+C), (x+B+3,
; y+C), (x+B+6, y+C), then the same three one cell row lower (y+C+4), the last
; three right to left. The crouching branch of ProbePlayer uses it to find
; harmful tiles. B is unchanged, C is left increased by 4.
;
; Hardware: none; reads the tile flag map.
;
;   HL Position: H = x, L = y (2-pixel units)
;   B Offset of the first point in x
;   C Offset of the first point in y
;   D Column mask (always $1F)
; O:E OR of the tile flags at the points
ProbeBlock3x2:
  LD E,$00
  CALL ProbeCell
  INC B
  INC B
  INC B
  CALL ProbeCell
  INC B
  INC B
  INC B
  CALL ProbeCell
  INC C
  INC C
  INC C
  INC C
  CALL ProbeCell
  DEC B
  DEC B
  DEC B
  CALL ProbeCell
  DEC B
  DEC B
  DEC B
  JP ProbeCell

; Probe two cells side by side
;
; ORs the tile flags of the cells at (x+B, y+C) and (x+B+3, y+C) into E (E
; starts at 0). Used for the head and the feet of the standing monk
; (ProbePlayer). B is left increased by 3.
;
; Hardware: none; reads the tile flag map.
;
;   HL Position: H = x, L = y (2-pixel units)
;   B Offset of the first point in x
;   C Offset of the first point in y
;   D Column mask (always $1F)
; O:E OR of the tile flags at the points
ProbePair:
  LD E,$00
  CALL ProbeCell
  INC B
  INC B
  INC B
  JP ProbeCell

; Probe three cells in a column
;
; ORs the tile flags of the cells at (x+B, y+C), (x+B, y+C+4) and (x+B, y+C+8)
; into E (E starts at 0): one point in each of the three cell rows of the
; standing monk's side (ProbePlayer). C is left increased by 8.
;
; Hardware: none; reads the tile flag map.
;
;   HL Position: H = x, L = y (2-pixel units)
;   B Offset of the first point in x
;   C Offset of the first point in y
;   D Column mask (always $1F)
; O:E OR of the tile flags at the points
ProbeColumnOf3:
  LD E,$00
  CALL ProbeCell
  INC C
  INC C
  INC C
  INC C
  CALL ProbeCell
  INC C
  INC C
  INC C
  INC C
  JP ProbeCell

; Probe the ring of 8 points around the body
;
; ORs the tile flags of eight cells into E (E starts at 0): the points x+B and
; x+B+3 by y+C, y+C+3, y+C+6 and y+C+9 (all eight of that 2 x 4 grid), taken as
; a ring: (x+B, y+C), (x+B+3, y+C), down the right side (y+C+3, +6, +9) and
; back up the left side (x+B, y+C+9, +6, +3). The standing monk (ProbePlayer)
; tests it for harmful tiles. B is left unchanged, C increased by 3.
;
; Hardware: none; reads the tile flag map.
;
;   HL Position: H = x, L = y (2-pixel units)
;   B Offset of the first point in x
;   C Offset of the first point in y
;   D Column mask (always $1F)
; O:E OR of the tile flags at the points
ProbeRing:
  LD E,$00
  CALL ProbeCell
  INC B
  INC B
  INC B
  CALL ProbeCell
  INC C
  INC C
  INC C
  CALL ProbeCell
  INC C
  INC C
  INC C
  CALL ProbeCell
  INC C
  INC C
  INC C
  CALL ProbeCell
  DEC B
  DEC B
  DEC B
  CALL ProbeCell
  DEC C
  DEC C
  DEC C
  CALL ProbeCell
  DEC C
  DEC C
  DEC C
; Entry point used by the probe routines above: the flags of one cell. The
; point (H+B, L+C) is outside the room (x of $80 or more, y of $58 or more;
; negative coordinates count as large) and then adds nothing. Otherwise the
; flag map address is found through the row address table (FlagRowTable):
; column = (x+B)/4, row = (y+C)/4. HL is preserved.
ProbeCell:
  PUSH HL                 ; save the position
  LD A,H
  ADD A,B
  CP ROOM_WIDTH_2PX
  JR NC,ProbeCell_Skip    ; outside the room
  RRA                     ; /4: column
  RRA
  AND D                   ; AND D (column mask)
  LD H,A                  ; H = column
  LD A,L
  ADD A,C
  CP ROOM_HEIGHT_2PX
  JR NC,ProbeCell_Skip    ; outside the room
  RRA                     ; /2
  AND $3E                 ; (y/4) * 2: offset in the row address table
  LD L,A
  LD A,H
  LD H,FlagRowTable/$100
  ADD A,(HL)              ; row address low + column
  INC L
  LD H,(HL)               ; row address high
  LD L,A
  LD A,(HL)               ; tile flags of the cell
  OR E                    ; accumulate
  LD E,A
ProbeCell_Skip:
  POP HL
  RET

; Queue a draw command on the frame call list
;
; Appends the 10 bytes of the draw command at HL to the frame call list at
; (FrameListPtr) and advances the pointer by 10: the player (DrawPlayerSprite,
; for the living and the dying monk) uses it for the monk's sprite command
; SpriteCmd. The first byte is self-modifying
; and doubles as a flag: it is a NOP in the game frame and $C9 (RET) while the
; call list is being run by RunFrameList, which writes it at the start of the
; drawing phase and clears it at the end (LeaveFrameList), so that nothing is
; queued while the list is being run. The game frame (GameFrame) and the other
; queueing routines read it as that flag (they skip their own copy when it is
; not zero).
;
; Hardware: none.
;
; HL Address of the 10-byte draw command (see SpriteCmd)
QueueDrawCmd:
  NOP                     ; NOP, or RET while the call list runs (written by
                          ; RunFrameList, LeaveFrameList)
  LD DE,(FrameListPtr)    ; write pointer of the frame call list
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
  LD (FrameListPtr),DE    ; new write pointer
  RET

; Kill Jean: lose a life and play the dying animation
;
; Reached from the player routine (UpdatePlayerActive) when the hit flag
; PlayerHit is not zero: takes one life (Lives), requests sound effect 6,
; starts the dying animation (animation timer 4, frame 0), clears the hit flag
; and sets the player state to 1 (dying). Falls into UpdateDying, which also
; runs on every later frame of the animation. The dying monk rises one pixel
; per frame while frames 0-6 of MonkDyingFrames are drawn in bright red: frame
; 0 for 3 frames (the timer is first counted down in the frame of the hit),
; frames 1-6 for 4 frames each, 27 frames and 27 pixels in all; then frame 7
; draws nothing for 4 frames, and in the 32nd frame (the frame of the hit
; counted) UpdateDying_End asks for the restart at the active checkpoint
; (observed: room 5, Y $4400 to $3680, the room state $84 in the 32nd frame;
; Jean dying in room 6 with no checkpoint touched restarts in room 5).
;
; Hardware: none; sound effect request only.
KillPlayer:
  LD HL,Lives             ; one life less
  DEC (HL)
  LD A,SFX_DEATH
  LD (SoundRequest),A
  LD A,DYING_ANIM_PERIOD
  LD (PlayerAnimTimer),A
  XOR A                   ; frame 0
  LD (PlayerFrame),A
  LD (PlayerHit),A        ; clear the hit flag
  INC A                   ; A = 1: dying
  LD (PlayerState),A
; One step of the dying animation; entered every frame in state 1 from
; UpdatePlayer. The timer counts down from 4; at zero the frame number goes up
; by one.
UpdateDying:
  LD HL,PlayerAnimTimer   ; timer
  DEC (HL)
  JR NZ,UpdateDying_Frame
  LD (HL),DYING_ANIM_PERIOD
  LD HL,PlayerFrame
  INC (HL)
UpdateDying_Frame:
  LD A,(PlayerFrame)      ; frame
  CP DYING_LAST_FRAME     ; frame 7 is not drawn, then it is over
  RET Z                   ; frame 7: draw nothing, wait
  JR NC,UpdateDying_End   ; frame 8: finished
  LD HL,(PlayerY)
  LD DE,DYING_RISE        ; the monk rises one pixel per frame
  OR A
  SBC HL,DE
  LD (PlayerY),HL         ; Y = Y - $0080
  LD HL,(PlayerY)
  LD A,H
  LD HL,(PlayerX)         ; H = X, L = Y
  LD L,A
  SRA H                   ; H = X / 4: byte column
  SRA H
  LD (SpriteCmdPos),HL    ; position of the draw command (y, byte column)
  LD BC,ShiftPairs        ; shift pairs
  LD HL,MonkDyingFrames   ; dying frames, for either facing
  LD DE,MonkDyingFrames
  LD A,MONK_HEIGHT        ; height, kept on the stack for DrawPlayerSprite
  PUSH AF
  LD A,BRIGHT+RED         ; attribute: bright red
  LD (SpriteCmdAttr),A    ; attribute of the draw command
  JP DrawPlayerSprite     ; draw frame PlayerFrame of the table, as walking
; The animation is over: ask the main loop (MainLoop) to restart at the active
; checkpoint (room state 4: SelectCheckpoint chooses the room and position),
; or to show Game Over when no life is left, and have the hearts of the status
; bar redrawn (DrawLivesBar).
UpdateDying_End:
  LD A,(Lives)            ; lives left?
  OR A
  LD HL,RoomState         ; room state
  LD (HL),STATE_RUNNING+STATE_RESTART ; $84: restart at the checkpoint
  JR NZ,UpdateDying_Bar      ; lives left
  INC (HL)                ; room state $85: Game Over
UpdateDying_Bar:
  LD DE,DrawLivesBar      ; hearts bar redraw gate: NOP re-arms it
  XOR A
  LD (DE),A
  RET

; Player state machine: dispatch on the state
;
; Called once per game frame (GameFrame) after the object slots. Player state
; PlayerState: $FF runs the debug room warp DebugWarpRoom (JP, it returns to
; the frame code), 0 does nothing, 1 (dying) goes on with the dying animation
; UpdateDying. For states 2 to 5 (jumping, crouching, standing, falling) it
; goes on at UpdatePlayerActive with C = state - 1, after testing bit 5 (T) of
; the control bits newly pressed this frame (ControlsPressed, loaded into B).
; The JR at SmcWarpCheat is changed by the RAGE cheat (CheckCheatKeys) into JR
; Z: then the T key falls through to EnterRoomWarp, which enters the debug room
; warp; without the cheat it always goes to UpdatePlayerActive. GameFrame uses
; no register after the call.
;
; Hardware: none.
UpdatePlayer:
  LD A,(PlayerState)      ; state
  INC A                   ; $FF becomes 0
  JP Z,DebugWarpRoom      ; state $FF: debug room warp
  DEC A                   ; restore the state
  RET Z                   ; 0: nothing
  DEC A
  JR Z,UpdateDying        ; 1: dying animation
  LD C,A                  ; C = state - 1
  LD A,(ControlsPressed)  ; keys pressed this frame
  LD B,A
  BIT 5,B                 ; T (the debug warp key)
; Self-modified opcode: JR ($18) normally, JR Z ($28) when the cheat is on
; (flipped by CheckCheatKeys).
SmcWarpCheat:
  JR UpdatePlayerActive   ; skip the warp entry (with the cheat: unless T was
                          ; pressed)

; Enter the debug room-warp mode (player state $FF)
;
; Reached only with the RAGE cheat on (CheckCheatKeys has changed the JR at
; SmcWarpCheat into JR Z) and the T key pressed: the player state becomes $FF,
; in which UpdatePlayer runs the room warp DebugWarpRoom instead of the player
; (observed with tests/inputs/cheat.txt: after T the direction keys step
; through the rooms 5, 6, 7, 12). Leaves the mode through DebugLeaveWarp.
;
; Hardware: none.
EnterRoomWarp:
  LD A,PLAYER_WARP        ; debug room warp
  LD (PlayerState),A
  RET

; Player: die on a hit, walk, then run the action of the state and draw the
; monk
;
; The main player routine, entered from UpdatePlayer with C = state - 1 (B, the
; newly pressed controls, is written before it is read). It uses the tile flag
; bytes PlayerTileHead-PlayerTileLeft that ProbePlayer filled in this frame.
;
; 1. A hit flag PlayerHit other than 0 (a harmful tile or an enemy) goes to
; KillPlayer: Jean dies.
;
; 2. Walking. The held control bits (ControlsHeld) right (bit 0) and left (bit
; 1) change X by $0080 (half a unit, one pixel) per frame, by $0020 (a quarter
; of a pixel) when crouching, in any state: Jean can steer in the air. A side
; whose tile flags have bit 1 set (PlayerTileRight right, PlayerTileLeft left)
; blocks him; a blocked move, no move at all or both blocked leave X as it was.
; The facing PlayerFacing follows the last direction tested (left wins when
; both keys are down). While walking the animation frame PlayerFrame toggles
; between 0 and 1 every 8 frames; not walking it is held at frame 0 with the
; timer at 8.
;
; 3. The action of the state: jumping PlayerJumping, crouching PlayerCrouching,
; standing PlayerStanding, falling PlayerFalling (see below). Jumping and
; falling move Y by the vertical speed PlayerSpeedY (8.8, units of 2 pixels): a
; jump starts at $01FE and loses $1E per frame, so it rises for 17 frames by
; 17.9 units (35.9 pixels) and then falls; a fall gains $1E per frame up to
; $021C (4.2 pixels per frame). Standing starts a jump (control bits 3 or 4
; pressed: sound effect 2) or crouching (bit 2 held); if there is no floor
; under the feet (bit 0 of PlayerTileFeet) Jean falls. A fall ends at once
; when the feet flags have bit 1 (classes 2 and 3); otherwise Y moves by the
; speed and LandPlayer snaps Y to the cell row if the feet have come into a
; floor cell, which is how Jean lands on a platform (class 1) from above. When
; the feet are already inside a platform's cell row (the top of a jump up
; through it) he lands only if he is exactly on its top (Y mod 4 = 0) or when
; the fall takes him into the next cell row and that is a floor, so a jump that
; does not lift the feet above the platform falls back through it (observed: a
; platform 5 rows above the floor is passed and fallen through, 3 or 4 rows
; above it is landed on, F141). A fall has no damage and no height limit.
; Crouching stands up when the crouch key is released and nothing blocks the
; head.
; Quirk: on a class 2 cell (bit 1 without bit 0) Jean lands and is set falling
; again in every frame, so he stays put in state 5 with the in-air frame and
; cannot jump or crouch (observed with flags poked; no room has a class 2
; floor, F140).
;
; 4. The monk's sprite: frame, shift phase (X mod 4 selects the copy of the
; frame shifted by 0, 2, 4 or 6 pixels and its width, ShiftPairs) and attribute
; go to the draw command SpriteCmd, which QueueDrawCmd appends to the frame
; call list.
;
; Hardware: none; reads the control bits and the tile flags, writes the player
; variables and queues a draw command.
;
; C Player state minus 1 (1 jumping, 2 crouching, 3 standing, 4 falling)
UpdatePlayerActive:
  LD A,(PlayerHit)        ; hit flag: die
  OR A
  JP NZ,KillPlayer        ; die
  LD A,(ControlsHeld)     ; held controls
  AND CTRL_RIGHT+CTRL_LEFT ; right / left
  JR Z,UpdatePlayer_Still ; no direction: stand still
  LD B,A                  ; B = direction bits
  LD A,C                  ; state - 1
  LD DE,WALK_SPEED        ; step: one pixel
  CP PLAYER_CROUCHING-$01 ; crouching (state 3)?
  JR NZ,UpdatePlayerActive_0
  LD DE,CROUCH_SPEED      ; crouching steps are a quarter of a pixel
UpdatePlayerActive_0:
  LD HL,(PlayerX)         ; HL = X
  RR B                    ; right?
  JR NC,UpdatePlayerActive_1
  LD A,(PlayerTileRight)  ; right side blocked?
  AND TILE_BLOCKS
  JR NZ,UpdatePlayer_Still ; blocked: no walking
  ADD HL,DE               ; X + step
  LD A,$00                ; facing right
  LD (PlayerFacing),A
UpdatePlayerActive_1:
  RR B                    ; left?
  JR NC,UpdatePlayerActive_2
  LD A,(PlayerTileLeft)   ; left side blocked?
  AND TILE_BLOCKS
  JR NZ,UpdatePlayer_Still ; blocked: no walking
  SBC HL,DE               ; X - step
  LD A,$01                ; facing left
  LD (PlayerFacing),A
UpdatePlayerActive_2:
  LD (PlayerX),HL         ; store X
  LD HL,PlayerAnimTimer   ; walk animation: timer
  DEC (HL)
  JR NZ,UpdatePlayer_State
  LD (HL),WALK_ANIM_PERIOD
  LD HL,PlayerFrame
  LD A,(HL)
  INC A
  AND $01                 ; toggle frame 0 / 1
  LD (HL),A
  JR UpdatePlayer_State
; Not walking (or blocked): animation frame 0, timer reloaded.
UpdatePlayer_Still:
  LD HL,PlayerAnimTimer
  LD (HL),WALK_ANIM_PERIOD
  LD HL,PlayerFrame
  LD (HL),$00
; Run the action of the state; C = state - 1.
UpdatePlayer_State:
  DEC C                   ; C = 1: jumping
  JP Z,PlayerJumping
  DEC C                   ; C = 2: crouching
  JP Z,PlayerCrouching
  DEC C                   ; C = 3: standing
  JP Z,PlayerStanding
; Falling (C = 4). A fall changes Y by the vertical speed PlayerSpeedY and
; stops when the feet flags show a floor.
PlayerFalling:
  XOR A                   ; A' = 0
  EX AF,AF'
  LD HL,(PlayerY)         ; HL = Y
  LD DE,(PlayerSpeedY)    ; DE = vertical speed
  LD A,(PlayerTileFeet)   ; feet flags
  AND TILE_BLOCKS|TILE_STANDABLE ; free below: keep falling
  JR Z,PlayerFalling_Move
  CP TILE_BLOCKS          ; class 2 or 3: landed
  JP NC,PlayerLanded      ; landed
  LD A,H                  ; class 1 (platform): Y mod 4
  AND SUBROW_MASK
  JP Z,PlayerLanded       ; exactly at the top of a cell row: landed
  ADD A,D                 ; Y mod 4 + speed high byte
  EX AF,AF'               ; A' = that
PlayerFalling_Move:
  ADD HL,DE               ; Y + speed
  LD (PlayerY),HL
  LD A,(PlayerTileFeet)   ; feet flags (old)
  AND TILE_BLOCKS|TILE_STANDABLE
  CP TILE_STANDABLE
  JR NZ,PlayerFalling_Land ; free below (solid went to PlayerLanded): check
                          ; for landing
  EX AF,AF'               ; platform: only when the fall crossed a cell row
  AND SUBROWS_PER_CELL    ; carry into bit 2 = crossed
PlayerFalling_Land:
  CALL NZ,LandPlayer      ; snap Y to the floor if the feet are in it
  LD HL,PlayerFrame       ; frame 2: in the air
  LD (HL),$02
  LD HL,(PlayerSpeedY)    ; vertical speed
  LD A,H
  CP FALL_SPEED_CAP_HI    ; at most $021C
  JP NC,DrawPlayerStand
  LD DE,GRAVITY
  ADD HL,DE
  LD (PlayerSpeedY),HL
  JP DrawPlayerStand      ; draw
; Jumping (C = 1): Y goes up by the vertical speed, which falls by $1E per
; frame; at zero the fall starts. A blocked head (bit 1 of PlayerTileHead)
; stops the rise but not the countdown of the speed.
PlayerJumping:
  LD HL,PlayerFrame       ; frame 2: in the air
  LD (HL),$02
  LD DE,(PlayerSpeedY)    ; vertical speed
  LD A,(PlayerTileHead)   ; head flags
  AND TILE_BLOCKS
  JR NZ,PlayerJumping_Slow ; head blocked: do not rise
  LD HL,(PlayerY)         ; Y - speed
  SBC HL,DE
  LD (PlayerY),HL
PlayerJumping_Slow:
  LD HL,(PlayerSpeedY)    ; speed - $1E
  LD DE,-GRAVITY
  ADD HL,DE
  LD (PlayerSpeedY),HL
  LD A,H                  ; speed reached zero?
  OR L
  JP NZ,DrawPlayerStand   ; not yet
  LD A,PLAYER_FALLING     ; top of the jump: fall
  LD (PlayerState),A
  JP DrawPlayerStand
; Landed: standing, frame 0; then as standing.
PlayerLanded:
  LD A,PLAYER_STANDING
  LD (PlayerState),A
  LD HL,PlayerFrame
  LD (HL),$00
; Standing (C = 3): a newly pressed jump key starts a jump, a held crouch key
; crouches; no floor under the feet starts a fall.
PlayerStanding:
  LD A,(ControlsPressed)  ; jump pressed (bit 3 or 4)?
  AND CTRL_JUMP
  JR Z,PlayerStanding_Crouch
  LD A,SFX_JUMP
  LD (SoundRequest),A
  LD HL,PlayerAnimTimer
  LD (HL),WALK_ANIM_PERIOD
  LD HL,JUMP_SPEED        ; start speed
  LD (PlayerSpeedY),HL
  LD A,PLAYER_JUMPING
  LD (PlayerState),A
  JR PlayerStanding_Floor
PlayerStanding_Crouch:
  LD A,(ControlsHeld)     ; crouch held?
  AND CTRL_CROUCH
  JR Z,PlayerStanding_Floor
  LD A,WALK_ANIM_PERIOD
  LD (PlayerAnimTimer),A
  XOR A
  LD (PlayerFrame),A
  LD A,PLAYER_CROUCHING
  LD (PlayerState),A
PlayerStanding_Floor:
  LD A,(PlayerTileFeet)   ; feet flags
  AND TILE_STANDABLE
  JR NZ,DrawPlayerStand   ; floor below: draw
  LD A,PLAYER_FALLING     ; no floor: fall from rest
  LD (PlayerState),A
  LD A,$02                ; frame 2
  LD (PlayerFrame),A
  LD HL,$0000             ; speed 0
  LD (PlayerSpeedY),HL
; Draw the standing, walking, jumping or falling monk.
DrawPlayerStand:
  LD HL,(PlayerY)         ; H = Y
  LD A,H
  LD HL,(PlayerX)         ; HL = (X, Y)
  LD L,A
  SRA H                   ; X / 4: byte column
  SRA H
  LD (SpriteCmdPos),HL    ; position of the draw command (y, byte column)
  LD BC,ShiftPairs        ; shift pairs
  LD HL,MonkFramesLeft    ; frames facing left
  LD DE,MonkFramesRight   ; frames facing right
  LD A,MONK_HEIGHT        ; height
; Entry point used by the crouching code: A = height, HL and DE = the frame
; tables for facing left and right, BC = shift pairs.
DrawPlayerAttr:
  PUSH AF                 ; height on the stack
  LD A,BRIGHT+YELLOW      ; attribute: bright yellow
  LD (SpriteCmdAttr),A    ; attribute of the draw command
; Entry point of the dying code (UpdateDying): the frame table is chosen by the
; facing (HL for left, DE for right), the frame by PlayerFrame; the copy of the
; frame by X mod 4 gives the address and width of the graphics.
DrawPlayerSprite:
  LD A,(PlayerFacing)     ; facing
  OR A
  JR Z,DrawPlayerSprite_Frame ; facing right (0): keep DE, the right table
  EX DE,HL                ; facing left: DE = the left table
DrawPlayerSprite_Frame:
  LD HL,(PlayerFrame)     ; HL = frame number
  LD H,$00
  ADD HL,HL
  ADD HL,DE               ; table + 2 x frame
  LD E,(HL)               ; DE = frame in the sprite sheet
  INC HL
  LD D,(HL)
  LD HL,(PlayerX)         ; X
  LD A,H
  AND SPRITE_PHASE_MASK    ; X mod 4: shift phase
  ADD A,A                 ; x 2: index in the pairs
  LD L,A
  XOR A
  LD H,A
  ADD HL,BC               ; pairs + 2 x phase
  LD B,(HL)               ; B = offset of the shifted copy
  INC HL
  LD C,(HL)               ; C = width
  LD H,A
  LD L,B
  ADD HL,DE               ; frame + offset
  LD (SpriteCmdGfx),HL    ; graphics address of the draw command
  POP HL                  ; H = height
  LD L,C                  ; L = width
  LD (SpriteCmdSize),HL   ; size of the draw command
  LD HL,SpriteCmd         ; the draw command
  JP QueueDrawCmd         ; queue it
; Crouching (C = 2): the crouch key released and nothing above the head (bit 1
; of PlayerTileHead) stand the monk up; no floor under the feet starts a fall.
PlayerCrouching:
  LD A,(ControlsHeld)     ; crouch still held?
  AND CTRL_CROUCH
  JR NZ,PlayerCrouching_Floor ; yes: stay
  LD A,(PlayerTileHead)   ; head flags
  AND TILE_BLOCKS
  JR NZ,PlayerCrouching_Floor ; no room to stand up: stay
  LD A,PLAYER_STANDING    ; stand up
  LD (PlayerState),A
  LD HL,PlayerAnimTimer
  LD (HL),$08
  LD HL,PlayerFrame
  LD (HL),$00
PlayerCrouching_Floor:
  LD A,(PlayerTileFeet)   ; feet flags
  AND TILE_STANDABLE
  JR NZ,DrawPlayerCrouch  ; floor below
  LD A,PLAYER_FALLING     ; no floor: fall
  LD (PlayerState),A
  LD A,$02                ; frame 2
  LD (PlayerFrame),A
  LD HL,$0000
  LD (PlayerSpeedY),HL
; Draw the crouching monk, 4 units (8 pixels) lower than the standing sprite.
; When the floor has just gone, frame 2 is read from the two-word crouching
; tables for this one frame: facing left gives CrouchFramesRight[0] (a frame
; facing the other way), facing right the first word of SpriteCmd, so the monk
; is drawn from the code bytes of QueueSprite (observed: graphics $9839 at X
; mod 4 = 1; F120).
DrawPlayerCrouch:
  LD HL,(PlayerY)         ; H = Y
  LD A,H
  LD HL,(PlayerX)
  ADD A,$04               ; Y + 4
  LD L,A
  SRA H                   ; X / 4
  SRA H
  LD (SpriteCmdPos),HL    ; position of the draw command
  LD BC,ShiftPairsCrouch  ; crouching shift pairs
  LD HL,CrouchFramesLeft  ; crouching frames facing left
  LD DE,CrouchFramesRight ; crouching frames facing right
  LD A,CROUCH_HEIGHT      ; height
  JP DrawPlayerAttr       ; draw in bright yellow

; Sprite shift pairs and the frame tables of the monk
;
; The 16-pixel-wide sprites of the monk (and of most enemies) are stored in the
; sprite sheet (SpriteSheet) as four copies of each frame, each shifted two
; pixels further right than the one before, so that a sprite can be placed on
; any 2-pixel column without shifting at run time. X mod 4 (X in 2-pixel units)
; selects the copy; the pair table gives, per copy, the column offset inside
; the frame and the width in bytes (2 for the unshifted copy, 3 for the others:
; 2 + 3 + 3 + 3 = 11 columns per frame). The monk frame tables hold the sprite
; sheet address of each frame (D = pixel row page, E = first column);
; DrawPlayerSprite picks the table by the facing (PlayerFacing) and the entry
; by the animation frame (PlayerFrame).
;
; +$00 ShiftPairs: 4 x (byte offset of the copy, width) for X mod 4 = 0, 1, 2,
; 3, shared with the enemies +$08 MonkFramesLeft: 3 words, facing left
; (PlayerFacing = 1; observed: the hood opens to the left): walking 0, walking
; 1, in the air +$0E MonkFramesRight: 3 words, facing right: walking 0, walking
; 1, in the air +$14 MonkDyingFrames: 7 words, the dying animation (3 pictures,
; repeated, KillPlayer) +$22 ShiftPairsCrouch: 4 x (offset, width) for the
; crouching monk (3 bytes wide in every phase) +$2A CrouchFramesLeft: 2 words,
; crouching facing left (sprite sheet rows 24-39) +$2E CrouchFramesRight: 2
; words, crouching facing right (both read one word too far for frame 2, see
; DrawPlayerCrouch)
ShiftPairs:
  DEFB $00,$02            ; Standing: (byte offset, width) for X mod 4
  DEFB $02,$03            ;
  DEFB $05,$03            ;
  DEFB $08,$03            ;
MonkFramesLeft:
  DEFW SpriteSheet,$D70B,$D716 ; Standing frames, facing left
MonkFramesRight:
  DEFW $D721,$D72C,$D737  ; Standing frames, facing right
MonkDyingFrames:
  DEFW $D742,$D74D,$D742,$D74D,$D758,$D74D,$D758 ; Dying frames
ShiftPairsCrouch:
  DEFB $00,$03            ; Crouching: (byte offset, width) for X mod 4
  DEFB $03,$03            ;
  DEFB $06,$03            ;
  DEFB $09,$03            ;
CrouchFramesLeft:
  DEFW SpriteSheetLower,$EF0C ; Crouching frames, facing left
CrouchFramesRight:
  DEFW $EF18,$EF24        ; Crouching frames, facing right

; Sprite draw commands
;
; Three 10-byte templates in the format of the frame call list (FrameList): the
; game frame fills a command with the sprite's position, graphics and size, and
; QueueDrawCmd (or the copy loops of the entities) appends its 10 bytes to the
; list, which RunFrameList later runs by RET: the first word is the routine,
; the other eight bytes are popped by it as HL, DE, BC and AF. The entities and
; the player share the first template, one after the other in the same frame;
; the second is used with it by the entities that draw two sprites (the falling
; water drop, the fire of the Pestilent Beast, Satan and his smoke), the third
; by the room items.
;
; Sprite command (routine QueueSprite, the masked sprite; SpriteCmd and
; SpriteCmd2): +0 word: routine QueueSprite +2 word: position, low byte y in
; 2-pixel units (0-87), high byte x in bytes (0-31); a value of $20 or more or
; $58 or more is negative (the sprite starts outside the room) +4 word:
; graphics address in the sprite sheet, low byte first column, high byte pixel
; row page +6 byte: width in bytes (1-5) +7 byte: height in 2-pixel units +8
; byte: unused (popped as the flags) +9 byte: attribute of the cells the sprite
; covers
;
; Object command (routine QueueBlockSprite, ItemCmd): the same fields, but the
; position is the cell row and column of the top left corner (low byte row
; 0-21, high byte column 0-31), the height is in 2-pixel units (4 to a cell
; row) and the width byte is not used: the sprite is always 2 cells wide.
SpriteCmd:
  DEFW QueueSprite        ; Main sprite: routine
SpriteCmdPos:
  DEFW $0000              ; Position (y, x/4 = byte column)
SpriteCmdGfx:
  DEFW $0000              ; Graphics
SpriteCmdSize:
  DEFB $00,$00            ; Width, height
  DEFB $00                ; Unused
SpriteCmdAttr:
  DEFB $00                ; Attribute
SpriteCmd2:
  DEFW QueueSprite        ; Second sprite: routine
SpriteCmd2Pos:
  DEFW $0000              ; Position
SpriteCmd2Gfx:
  DEFW $0000              ; Graphics
SpriteCmd2Size:
  DEFB $00,$00            ; Width, height
  DEFB $00                ; Unused
SpriteCmd2Attr:
  DEFB $00                ; Attribute
ItemCmd:
  DEFW QueueBlockSprite   ; Object sprite: routine
ItemCmdPos:
  DEFW $0000              ; Position (row, column)
ItemCmdGfx:
  DEFW $0000              ; Graphics
ItemCmdSize:
  DEFB $00,$00            ; Width, height
  DEFB $00                ; Unused
ItemCmdAttr:
  DEFB $00                ; Attribute

; Room exits: change the room when Jean walks off an edge
;
; The last routine of the game frame (GameFrame). Does nothing in the states 0
; and 1 (no player, dying). Otherwise it looks at the position of the monk (X
; and Y, high bytes in 2-pixel units, kept modulo 256, so a position left of or
; above the room is $FC-$FF resp. $FA-$FF). Horizontal exits are tested first
; and only on the side Jean faces (PlayerFacing): facing right he leaves
; through the right edge when $7C <= X < $FC, facing left through the left edge
; when $80 <= X <= $FC. The sprite is 8 units wide, so Jean has half of his
; width outside the room when the room changes. Vertical exits: up when $80 <=
; Y <= $F9 (5 units of the sprite are still in the room), down when $52 <= Y <
; $80 (only 6 of the 12 units are left).
;
; On an exit the room number RoomNumber changes by +1 (right), -1 (left), +5
; (down) or -5 (up), the position wraps by the size of the room (X by $80, Y by
; $58, so that the monk appears at the opposite edge half outside the room),
; the exit direction ExitDirection is set (0 right, 1 left, 2 down, 3 up: the
; new room is drawn from that side by RedrawRoom) and the room state RoomState
; becomes 1, which makes the main loop (MainLoop) enter the room. Last the
; room number is reduced modulo 25 by subtracting 25 until it is below 25. The
; subtraction works on the byte, so a room number below zero (the left of room
; 0, the top row of rooms going up) is $FB-$FF and ends as 6 more than the
; mathematical result (room 0 left gives room 5, room 2 up gives room 3).
; None of these exits can be reached in play: room 0 is only the intro, the
; top edges of rooms 1-4 are out of reach and room 4 cannot be entered
; (F124); only the debug warp (DebugMoveRoom) takes them (F77, observed by
; poking the position).
;
; Hardware: none.
CheckRoomExit:
  LD A,(PlayerState)      ; state
  CP PLAYER_JUMPING
  RET C                   ; none or dying: no exits
  LD HL,(PlayerX)         ; H = X
  LD A,(PlayerFacing)     ; facing
  OR A
  LD A,H                  ; A = X
  JR NZ,CheckExitLeft     ; facing left
  CP $FC                  ; $FC-$FF: just entered from the left
  JR NC,CheckExitY        ; no horizontal exit
  CP $7C                  ; not yet at the right edge
  JR C,CheckExitY
  SUB ROOM_WIDTH_2PX      ; X wraps to $FC-$FF
  LD H,A
  LD (PlayerX),HL
; Leave through the right edge (also entered by the debug room warp,
; DebugMoveRoom): next room.
LeaveRight:
  LD HL,RoomNumber        ; room + 1
  INC (HL)
  XOR A                   ; exit direction 0: right
  JR SetExitDirection     ; store the direction
CheckExitLeft:
  CP $80                  ; A = X, facing left
  JR C,CheckExitY         ; no exit
  CP $FD                  ; $FD-$FF: no exit yet
  JR NC,CheckExitY        ; no exit
  ADD A,ROOM_WIDTH_2PX    ; X wraps to $7C or less
  LD H,A
  LD (PlayerX),HL
; Leave through the left edge (also entered by the debug room warp): previous
; room.
LeaveLeft:
  LD HL,RoomNumber        ; room - 1
  DEC (HL)
  LD A,EXIT_LEFT
  JR SetExitDirection
; Vertical exits.
CheckExitY:
  LD HL,(PlayerY)         ; H = Y
  LD A,H
  CP $80                  ; Y below $80: test the bottom
  JR C,CheckExitDown
  CP $FA                  ; $FA-$FF: no exit yet
  JR NC,CheckExitDown
  ADD A,ROOM_HEIGHT_2PX   ; Y wraps to the bottom
  LD H,A
  LD (PlayerY),HL
; Leave through the top edge (also entered by the debug room warp): room - 5.
LeaveUp:
  LD HL,RoomNumber        ; room
  LD A,(HL)
  SUB $05
  LD (HL),A
  LD A,EXIT_UP
  JR SetExitDirection
CheckExitDown:
  CP $80                  ; A = Y
  RET NC                  ; $80-$FF: no exit
  CP $52                  ; $52: the bottom
  RET C                   ; above: no exit
  SUB ROOM_HEIGHT_2PX     ; Y wraps to the top
  LD H,A
  LD (PlayerY),HL
; Leave through the bottom edge (also entered by the debug room warp): room +
; 5.
LeaveDown:
  LD HL,RoomNumber        ; room
  LD A,(HL)
  ADD A,$05
  LD (HL),A
  LD A,EXIT_DOWN
SetExitDirection:
  LD (ExitDirection),A    ; exit direction
  LD A,STATE_ENTER_ROOM   ; enter the new room
  LD (RoomState),A
; Reduce the room number modulo 25.
WrapRoomNumber:
  LD A,(RoomNumber)       ; room
  CP GRID_ROOMS
  RET C
  SUB GRID_ROOMS
  LD (RoomNumber),A
  JR WrapRoomNumber

; Debug room warp: change room in the direction of a pressed key
;
; Called by the debug room warp DebugWarpRoom with the direction bits of the
; keys pressed this frame. Does not move the monk: it jumps into the
; room-change tails of CheckRoomExit, which add to the room number
; (RoomNumber), store the exit direction (ExitDirection), set the room state to
; 1 (enter the room) and wrap the room number modulo 25, and then return to the
; caller of this routine. Bit 0 (right) goes to LeaveRight (room + 1, direction
; 0), bit 1 (left) to LeaveLeft (room - 1, direction 1), bit 2 (down) to
; LeaveDown (room + 5, direction 2) and bit 3 (up) to LeaveUp (room - 5,
; direction 3); only one direction is taken, the first bit set from bit 0 up.
; Observed with PlayerState poked to $FF: P, A, O and Q moved room 5 to 6, 11,
; 10 and 5. Reached only through the RAGE cheat (EnterRoomWarp).
;
; A Direction bits as in ControlsPressed: bit 0 right, bit 1 left, bit 2 down,
;   bit 3 up (DebugWarpRoom has masked off the higher bits)
DebugMoveRoom:
  RRA                     ; bit 0: right
  JP C,LeaveRight         ; room + 1
  RRA                     ; bit 1: left
  JP C,LeaveLeft          ; room - 1
  RRA                     ; bit 2: down
  JP C,LeaveDown          ; room + 5
  RRA                     ; bit 3: up
  JP C,LeaveUp            ; room - 5
  RET

; Debug room warp: leave the warp mode
;
; Jumped to by the debug room warp DebugWarpRoom when key T (control bit 5) is
; pressed: sets the player state back to 4, standing (it was $FF, the warp
; mode). Reached only through the RAGE cheat (EnterRoomWarp).
DebugLeaveWarp:
  LD A,PLAYER_STANDING    ; player state standing
  LD (PlayerState),A
  RET
