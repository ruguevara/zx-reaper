; Draw the lives still in reserve as small walking Willys
;
; Draws one 16x16 Willy sprite for each life left in LivesLeft (none when it is
; 0), from the left end of the bottom status row (screen row 21, column 0), two
; columns apart. All figures show the same walking frame of the right-facing
; Willy sprites (SpriteWillyRight0): frame = bits 2-3 of the tune step counter
; TuneStep, so the row of figures walks on the spot, changing frame every 4
; steps of the counter. The counter only advances while the tune is on, so with
; the tune off the figures stand still (observed). The figures are drawn
; straight onto the screen, not into the screen buffer, once per pass of the
; frame loop; their colours are the status bar attributes
; (StatusBarAttributes), which are never rewritten by the loop.
;
; The game starts with 7 figures. A death (ResumeAfterPause) removes one after
; the death flash; when none is left, the next death is the game over.
;
; Hardware: writes the screen bitmap.
DrawLives:
  LD A,(LivesLeft)        ; lives in reserve
  LD HL,LIVES_SCREEN
  OR A
  RET Z                   ; none: nothing to draw
  LD B,A                  ; B = figures left to draw
DrawLives_Loop:
  LD C,$00                ; DrawSprite mode 0: replace
  PUSH HL
  PUSH BC
  LD A,(TuneStep)
  RLCA
  RLCA
  RLCA
  AND LIFE_FRAME_MASK     ; frame offset 0, $20, $40 or $60 from bits 2-3
  LD E,A
  LD D,WILLY_SPRITE_PAGE  ; DE = Willy facing right, frame 0-3
  CALL DrawSprite
  POP BC
  POP HL
  INC HL                  ; next figure two columns to the right
  INC HL
  DJNZ DrawLives_Loop
  RET

; The frame loop: one pass of the game
;
; Entered by JP with an empty stack (SP=$5BFE) from the room entry (EnterRoom),
; from the death handler (ResumeAfterPause) and from the checks at the end of
; the pass, and never returns. One pass takes about 262,000 T states with the
; tune on (230,000 with it off), i.e. 13.4 passes per second on a 3.5 MHz
; Spectrum, nearly all of it in the four block copies. Nothing waits for the
; screen: interrupts have been off since the loader (StartProgram), so the game
; speed is just the speed of the loop (see the details in the finding
; register).
;
; One pass, in order:
;
; 1. Draw the lives in reserve (DrawLives) straight onto the screen.
;
; 2. Copy the empty room (attributes 5E00, bitmap 7000) over the work buffers
; 5C00 and 6000.
;
; 3. Move the entities (MoveEntities); move Willy (MoveWilly) unless the ending
; stage (EndingStage) is 3; leave through the top if his Y reached $E1 or more
; (ExitRoomUp); mark his cells, test for nasties and draw him (PlaceWilly, also
; not in stage 3); in stage 2 test for the toilet (CheckToiletReached); room
; events of the Master Bedroom and Bathroom (UpdateBedroom); draw the entities
; and test them against Willy (DrawEntities); animate the conveyor
; (AnimateConveyor); draw and collect the items (UpdateItems). Any of these can
; end the pass early by killing Willy (KillWillyNested jumps to $89F5 with
; WillyAirState = $FF).
;
; 4. Copy the work bitmap $6000 (top two thirds) to the screen. Stages 2 and 3
; set bit 0 of Willy's animation frame WillyFrame. If the screen flash timer
; FlashTimer is not 0, fill the work attributes with a paper colour. Copy the
; work attributes to the screen.
;
; 5. Print the items count (ItemsCollectedText, at $5070) and the clock
; (ClockText, at $5079).
;
; 6. Count the pass (PassCounter). When it wraps, advance the clock by a
; minute; 12:59pm going to 1:00 ends the game by a jump to NewGame.
;
; 7. Keys: CAPS SHIFT and SPACE together jump to the title screen (NewGame).
; The idle counter IdleCounter is incremented; when it wraps to 0, or when a
; key of the A S D F G row is down, the loop waits (pause) until any key of the
; other rows is pressed, cycling the screen colours about once a second
; (CycleColours) unless the cheat is on. It then goes on to ResumeAfterPause
; (after a pause, to restore the status bar and border) or CheckDeath (death
; check, tune, cheat keys), which ends by jumping back here.
;
; The clock text is " 7:00a" (hours tens digit or blank, hours units, colon,
; minutes tens, minutes units, letter a or p). The minutes carry into the
; hours, the hours go 9, 10, 11, 12 and then 1: at 12 followed by 1 the letter
; changes from a to p, and 12 followed by 1 with p ends the game.
;
; Hardware: writes the screen bitmap and attributes (the blocks are copied with
; LDIR), reads the keyboard ports $FEFE, $7FFE, $FDFE and the half rows
; selected by high byte $02, writes the border while paused.
FrameLoop:
  CALL DrawLives          ; lives in reserve
  LD HL,ROOM_ATTR_BUF     ; empty-room attributes ...
  LD DE,SCREEN_ATTRS_BUF  ; ... to the work attributes
  LD BC,ROOM_ATTRS_SIZE
  LDIR
  LD HL,ROOM_PIXEL_BUF    ; empty-room bitmap ...
  LD DE,SCREEN_PIXEL_BUF  ; ... to the work bitmap
  LD BC,ROOM_BITMAP_SIZE
  LDIR
  CALL MoveEntities       ; move the entities
  LD A,(EndingStage)
  CP STAGE_AT_TOILET      ; stage 3: Willy is not moved
  CALL NZ,MoveWilly       ; move Willy (keys, jump, fall)
  LD A,(WillyY)
  CP WILLY_Y_ABOVE_TOP    ; Y index wrapped past the top of the room?
  CALL NC,ExitRoomUp      ; leave through the top
  LD A,(EndingStage)
  CP STAGE_AT_TOILET
  CALL NZ,PlaceWilly      ; mark Willy's cells, test nasties, draw him
  LD A,(EndingStage)
  CP STAGE_RUN_TO_TOILET
  CALL Z,CheckToiletReached ; stage 2: has he reached the toilet?
  CALL UpdateBedroom      ; Master Bedroom and Bathroom events
  CALL DrawEntities       ; draw the entities, test them against Willy
  CALL AnimateConveyor    ; animate the conveyor
  CALL UpdateItems        ; draw and collect the items
; This entry point is used by the routine at KillWillyNested.
FrameLoop_Present:
  LD HL,SCREEN_PIXEL_BUF  ; work bitmap ...
  LD DE,SCREEN            ; ... to the screen
  LD BC,ROOM_BITMAP_SIZE
  LDIR
  LD A,(EndingStage)
  AND $01<<ENDING_AUTORUN_BIT
  RRCA                    ; 1 in stages 2 and 3, else 0
  LD HL,WillyFrame
  OR (HL)
  LD (HL),A               ; set bit 0 of Willy's animation frame
  LD A,(FlashTimer)       ; screen flash timer (never set by the game)
  OR A
  JR Z,FrameLoop_Attrs
  DEC A
  LD (FlashTimer),A
  RLCA
  RLCA
  RLCA
  AND PAPER_MASK          ; paper colour = timer * 8, black ink
  LD HL,SCREEN_ATTRS_BUF
  LD DE,SCREEN_ATTRS_BUF+$0001
  LD BC,ROOM_ATTRS_SIZE-$0001
  LD (HL),A
  LDIR                    ; flood the work attributes
FrameLoop_Attrs:
  LD HL,SCREEN_ATTRS_BUF  ; work attributes ...
  LD DE,ATTRS             ; ... to the screen
  LD BC,ROOM_ATTRS_SIZE
  LDIR
  LD IX,ClockText         ; clock text
  LD DE,CLOCK_SCREEN
  LD C,CLOCK_LENGTH
  CALL PrintText          ; print it
  LD IX,ItemsCollectedText ; items collected digits
  LD DE,ITEMS_SCREEN
  LD C,ITEM_DIGITS
  CALL PrintText          ; print them
  LD A,(PassCounter)
  INC A
  LD (PassCounter),A      ; count the pass
  JR NZ,FrameLoop_Keys    ; the clock advances only when the counter wraps
  LD IX,ClockText
  INC (IX+CLOCK_MINUTES_UNITS) ; minutes units
  LD A,(IX+CLOCK_MINUTES_UNITS)
  CP ASCII_AFTER_NINE
  JR NZ,FrameLoop_Keys
  LD (IX+CLOCK_MINUTES_UNITS),ASCII_ZERO ; carry: units 0
  INC (IX+CLOCK_MINUTES_TENS) ; minutes tens
  LD A,(IX+CLOCK_MINUTES_TENS)
  CP ASCII_SIX
  JR NZ,FrameLoop_Keys
  LD (IX+CLOCK_MINUTES_TENS),ASCII_ZERO ; carry: tens 0, next hour
  LD A,(IX+CLOCK_HOURS_TENS) ; hours tens: blank or 1
  CP ASCII_ONE
  JR NZ,FrameLoop_HourBlank ; blank: hours 1-9
  INC (IX+CLOCK_HOURS_UNITS) ; hours 10, 11, 12
  LD A,(IX+CLOCK_HOURS_UNITS)
  CP ASCII_THREE          ; 13 o'clock?
  JR NZ,FrameLoop_Keys
  LD A,(IX+CLOCK_AM_PM)
  CP ASCII_P
  JP Z,NewGame            ; 12:59p -> end of the game: back to the title
  LD (IX+CLOCK_HOURS_TENS),ASCII_SPACE ; hour 12 with letter a becomes " 1" ...
  LD (IX+CLOCK_HOURS_UNITS),ASCII_ONE
  LD (IX+CLOCK_AM_PM),ASCII_P ; ... and the letter changes from a to p
  JR FrameLoop_Keys
FrameLoop_HourBlank:
  INC (IX+$01)            ; hours 1-9
  LD A,(IX+$01)
  CP ASCII_AFTER_NINE
  JR NZ,FrameLoop_Keys
  LD (IX+CLOCK_HOURS_UNITS),ASCII_ZERO ; 9 -> 10
  LD (IX+CLOCK_HOURS_TENS),ASCII_ONE
FrameLoop_Keys:
  LD BC,KEYROW_CS_V       ; CAPS SHIFT row
  IN A,(C)
  LD E,A
  LD B,KEYROW_SPACE_B>>8  ; SPACE row
  IN A,(C)
  OR E
  AND $01                 ; bit 0 clear only if CAPS SHIFT and SPACE are both
                          ; down
  JP Z,NewGame            ; quit to the title
  LD A,(IdleCounter)
  INC A
  LD (IdleCounter),A      ; idle counter
  JR Z,FrameLoop_Wait     ; wrapped: wait for a key by itself
  LD B,KEYROW_A_G_HI      ; A S D F G row: the pause keys
  IN A,(C)
  AND KEYS_MASK
  CP NO_KEYS
  JR Z,CheckDeath         ; none down: on to the death check and tune
  LD DE,$0000             ; wait counter
FrameLoop_Wait:
  LD B,KEYROW_NOT_A_G_HI  ; every row except A-G
  IN A,(C)
  AND KEYS_MASK
  CP NO_KEYS
  JR NZ,ResumeAfterPause  ; a key: resume
  INC E
  JR NZ,FrameLoop_Wait
  INC D
  JR NZ,FrameLoop_Wait    ; 65536 polls (about a second) per colour step
  LD A,(CheatProgress)
  CP CHEAT_ACTIVE         ; cheat on: no colour cycling
  CALL NZ,CycleColours
  JR FrameLoop_Wait

; Cycle the colours of the whole screen one step
;
; Rewrites every one of the 768 attribute cells ($5800-$5AFF): ink and paper
; both go up by 3 (modulo 8) and the bright bit is cleared, and the border is
; set to the ink the first cell had before the step. Calling it repeatedly
; makes the picture and border change colour. Used as the pause effect of the
; game (FrameLoop, while it waits for a key; not called when the cheat is
; active) and once per step of the title message scroll (ScrollTitleMessage).
;
; Flash is kept, except that a cell with bright on and a paper that wraps past
; 7 gets flash toggled by the carry of the paper addition. Observed with a call
; of the routine on the cells $78, $F8 and $40, which became $93, $13 and $1B.
;
; Hardware: reads and writes the screen attributes, writes the border (port
; $FE).
CycleColours:
  LD HL,ATTRS             ; first attribute cell
  LD A,(HL)
  AND INK_MASK
  OUT (ULA_PORT),A        ; border = ink of the first cell (before the step)
CycleColours_Cell:
  LD A,(HL)
  ADD A,COLOUR_CYCLE_STEP
  AND INK_MASK            ; new ink
  LD D,A
  LD A,(HL)
  ADD A,COLOUR_CYCLE_STEP*PAPER ; paper + 3
  AND $FF-INK_MASK-BRIGHT ; keep flash and paper, clear bright and ink
  OR D
  LD (HL),A
  INC HL
  LD A,H
  CP (ATTRS+ATTRS_SIZE)>>8 ; until the address reaches $5B00
  JR NZ,CycleColours_Cell
  RET

; Rest of the frame loop: resume, death check, tune, cheat, death, game over
;
; The second half of the pass started by FrameLoop, with five independent
; parts. All of them end by jumping back to FrameLoop (EnterRoom after a
; teleport or a death, NewGame after the game over), so none of them returns.
; Proposed split points are the entry labels below.
;
; 1. $8B07 (ResumeAfterPause): entered when the pause wait of FrameLoop sees a
; key. Restores the status bar attributes (the pause cycled every colour on the
; screen) and the room's border colour, then goes on at $8B17.
;
; 2. $8B17 (CheckDeath): if Willy was killed in this pass (WillyAirState = $FF)
; jump to the death scene at $8C01. Then the tune: any key of the H J K L ENTER
; half row toggles it (TuneFlags). With the tune on, the idle counter
; IdleCounter is cleared, TuneStep is incremented and one note is played as a
; short beep of 768 loop passes (about 9 ms, so the tune is a series of blips,
; one per pass): the note is GameTune[(TuneStep AND $7E) / 2] plus 28 - 4 *
; lives (LivesLeft), a count of loop passes per half period, so the pitch drops
; as lives are lost. The border keeps the room colour during the beep.
;
; 3. $8B70 (CheckTeleport) and $8B97 (CheckCheatKeys): the WRITETYPER cheat.
; Teleport, only with CheatProgress = 10: key 9 held together with keys 1-5 (1,
; 2, 4, 8, 16) and 6 (32) sets the room number to that sum (0-63) and enters it
; at once (EnterRoom), keeping Willy's position. Typing the sequence: in room
; $1C (First Landing) with Willy's Y index $D0, CheatProgress counts the
; letters W R I T E T Y P E R (CheatKeyTable) typed one at a time; see
; CheatProgress.
;
; 4. $8C01 (PlayDeath): the death scene, about 6 frames: eight rounds, each
; filling the whole room area (top 16 rows) of the screen attributes with one
; bright colour with black paper, from ink 7 (white) down to ink 0 (black), and
; a buzz whose half-period grows round by round (a falling note, from about 14
; kHz to 2 kHz, 232 toggles in the first round and 8 in the last; the border
; turns black). Then, at $8C33 (RestartAfterDeath), if LivesLeft is not 0 it is
; decremented, Willy's seven saved state bytes (WillySavedState, copied when
; the room was entered) are copied back to WillyY and the room is entered again
; (EnterRoom) at its entry position.
;
; 5. $8C4A (ShowGameOver): when LivesLeft is 0 the death is the game over. The
; top two thirds of the bitmap are cleared; Willy (SpriteWillyRight2) is drawn
; standing on a barrel (SpriteBarrel) in the middle, and a foot (SpriteFoot) is
; drawn 49 times at column 15 on its way down from the top of the screen in
; steps of 2 pixel rows, landing on Willy, each time with a rising whistle (64
; toggles, the half-period shrinks from 3,350 to 850 T states: 520 Hz up to 2
; kHz) and a flood of the room attributes with bright white ink on a paper
; colour that runs 0-3 (the barrel stays red). GameText and OverText ("Game"
; and "Over") are printed on screen row 6 to the left and right of the foot's
; path. For about 80 frames the eight letters then cycle through the colours
; (ink (counter + n) mod 8, bright; at ink 0 a letter is black on black and
; blinks out), after which the game restarts at the title screen (NewGame). The
; scene lasts about 184 frames (3.7 seconds). The counter is ScratchByte.
;
; Hardware: reads keyboard ports $BFFE (tune key), $EFFE, $F7FE (teleport),
; $FBFE, $DFFE (cheat), writes the beeper and border (port $FE), writes the
; screen bitmap and attributes.
ResumeAfterPause:
  LD HL,StatusBarAttributes ; status bar attributes ...
  LD DE,BOTTOM_THIRD_ATTRS ; ... back to the screen
  LD BC,THIRD_ATTRS_SIZE
  LDIR
  LD A,(RoomBorder)       ; room border colour
  OUT (ULA_PORT),A        ; restore the border
; This entry point is used by the routine at FrameLoop.
CheckDeath:
  LD A,(WillyAirState)    ; Willy killed in this pass?
  CP WILLY_KILLED
  JP Z,PlayDeath          ; yes: death scene
  LD B,KEYROW_H_ENTER_HI  ; H J K L ENTER row (C is still $FE)
  LD HL,TuneFlags         ; tune flags
  IN A,(C)
  AND KEYS_MASK
  CP NO_KEYS
  JR Z,ResumeAfterPause_0 ; no key down
  BIT 0,(HL)              ; key down: was it down last pass too?
  JR NZ,PlayGameTune      ; yes: do not toggle again
  LD A,(HL)
  XOR $03                 ; flip bit 1 (tune off) and set bit 0
  LD (HL),A
  JR PlayGameTune
ResumeAfterPause_0:
  RES 0,(HL)              ; no key: clear the key-held flag
PlayGameTune:
  BIT 1,(HL)              ; bit 1 set: tune is off
  JR NZ,CheckTeleport
  XOR A
  LD (IdleCounter),A      ; idle counter cleared while the tune plays
  LD A,(TuneStep)
  INC A
  LD (TuneStep),A         ; step counter
  AND TUNE_LENGTH_MASK
  RRCA                    ; note index 0-63
  LD E,A
  LD D,$00
  LD HL,GameTune          ; game tune
  ADD HL,DE
  LD A,(LivesLeft)        ; lives
  RLCA
  RLCA
  SUB LIVES_FULL_PITCH
  NEG                     ; A = 28 - 4 * lives
  ADD A,(HL)              ; plus the note: D = half-period count
  LD D,A
  LD A,(RoomBorder)       ; room border colour (bits 3 and 4 are 0)
  LD E,D                  ; E counts down to the next speaker toggle
  LD BC,TUNE_BEEP_LOOPS   ; B = 0: 256 passes of the inner loop, C = 3 times
PlayGameTune_Loop:
  OUT (ULA_PORT),A        ; speaker/MIC state with the border
  DEC E
  JR NZ,ResumeAfterPause_1
  LD E,D
  XOR BEEPER_BITS         ; toggle the speaker and MIC
ResumeAfterPause_1:
  DJNZ PlayGameTune_Loop
  DEC C
  JR NZ,PlayGameTune_Loop

; Teleport cheat and WRITETYPER key check
CheckTeleport:
  LD BC,KEYROW_0_9        ; 0 9 8 7 6 row
  IN A,(C)
  BIT KEY_9_BIT,A         ; key 9 down?
  JP NZ,CheckCheatKeys    ; no: skip the teleport
  AND $01<<KEY_6_BIT      ; key 6
  XOR $01<<KEY_6_BIT
  RLCA                    ; $20 if key 6 is down, else 0 (room bit 5)
  LD D,A
  LD A,(CheatProgress)    ; cheat progress
  CP CHEAT_ACTIVE         ; cheat not typed yet: no teleport
  JP NZ,CheckCheatKeys
  LD BC,KEYROW_1_5        ; keys 1-5
  IN A,(C)
  CPL                     ; 1 = down: room bits 0-4
  AND KEYS_MASK
  OR D
  LD (CurrentRoom),A      ; new room number
  JP EnterRoom            ; enter it
CheckCheatKeys:
  LD A,(CheatProgress)    ; cheat progress
  CP CHEAT_ACTIVE
  JP Z,FrameLoop          ; cheat already on: nothing to type
  LD A,(CurrentRoom)      ; room number
  CP ROOM_FIRST_LANDING
  JP NZ,FrameLoop         ; only in First Landing ...
  LD A,(WillyY)
  CP CHEAT_Y
  JP NZ,FrameLoop         ; ... with Willy at Y = $D0
  LD A,(CheatProgress)
  RLCA                    ; 2 * step
  LD E,A
  LD D,$00
  LD IX,CheatKeyTable+$0002 ; pair of step 0; IX-2 is the previous step pair
  ADD IX,DE
  LD BC,KEYROW_Q_T        ; Q W E R T row
  IN A,(C)
  AND KEYS_MASK
  CP (IX+$00)             ; the letter of this step in this row? ($1F matches
                          ; no key)
  JR Z,CheckCheatKeys_Row2 ; yes: check the P-Y row
  CP NO_KEYS              ; no key: wait
  JP Z,FrameLoop
  CP (IX-$02)             ; previous letter still held: wait
  JP Z,FrameLoop
  XOR A                   ; anything else: back to step 0
  LD (CheatProgress),A
  JP FrameLoop
CheckCheatKeys_Row2:
  LD B,KEYROW_P_Y>>8      ; P O I U Y row
  IN A,(C)
  AND KEYS_MASK
  CP (IX+$01)             ; the letter of this step in this row?
  JR Z,CheckCheatKeys_Next
  CP NO_KEYS
  JP Z,FrameLoop
  CP (IX-$01)
  JP Z,FrameLoop
  XOR A                   ; anything else: back to step 0
  LD (CheatProgress),A
  JP FrameLoop
CheckCheatKeys_Next:
  LD A,(CheatProgress)    ; both rows matched: next step
  INC A
  LD (CheatProgress),A
  JP FrameLoop

; Death scene, then restart the room or end the game
PlayDeath:
  LD A,FLASH_START_ATTR   ; first colour: bright white ink, black paper
PlayDeath_Round:
  LD HL,ATTRS             ; flood the top two thirds of the screen attributes
                          ; ...
  LD DE,ATTRS+$0001
  LD BC,ROOM_ATTRS_SIZE-$0001
  LD (HL),A               ; ... with this colour
  LDIR
  LD E,A                  ; E = colour
  CPL
  AND INK_MASK
  RLCA
  RLCA
  RLCA
  OR $07                  ; D = ((7 - ink) * 8) + 7: delay, grows as the ink
                          ; falls
  LD D,A
  LD C,E                  ; C = colour rotated right 3 times: toggles in this
                          ; round
  RRC C
  RRC C
  RRC C
  OR $10                  ; result unused: A is cleared below
  XOR A                   ; speaker off, border black
PlayDeath_Buzz:
  OUT (ULA_PORT),A
  XOR BEEPER_BITS
  LD B,D
PlayDeath_0:
  DJNZ PlayDeath_0
  DEC C
  JR NZ,PlayDeath_Buzz
  LD A,E                  ; next colour (ink - 1)
  DEC A
  CP FLASH_END_ATTR       ; ink 0 done?
  JR NZ,PlayDeath_Round
RestartAfterDeath:
  LD HL,LivesLeft         ; lives in reserve
  LD A,(HL)
  OR A
  JP Z,ShowGameOver       ; none left: game over
  DEC (HL)                ; one life used
  LD HL,WillySavedState   ; state saved at room entry ...
  LD DE,WillyY            ; ... back to Willy state ($85CF-$85D5)
  LD BC,WILLY_STATE_SIZE
  LDIR
  JP EnterRoom            ; enter the room again

; Game over scene
ShowGameOver:
  LD HL,SCREEN            ; clear the top two thirds of the bitmap
  LD DE,SCREEN+$0001
  LD BC,ROOM_BITMAP_SIZE-$0001
  LD (HL),$00
  LDIR
  XOR A
  LD (ScratchByte),A      ; step counter 0
  LD DE,SpriteWillyRight2 ; Willy, facing right (frame 2)
  LD HL,GAME_OVER_WILLY   ; row 12, column 15
  LD C,$00                ; DrawSprite mode 0: replace
  CALL DrawSprite
  LD DE,SpriteBarrel      ; barrel
  LD HL,GAME_OVER_BARREL  ; row 14, column 15 (below Willy)
  LD C,$00
  CALL DrawSprite
ShowGameOver_Step:
  LD A,(ScratchByte)      ; counter 0, 4, 8 ... $C0
  LD C,A                  ; BC = $8200 + counter: pixel row counter/2 in the
                          ; row table
  LD B,RowAddressTable>>8
  LD A,(BC)               ; low byte of the row address
  OR GAME_OVER_COLUMN     ; column 15
  LD L,A
  INC BC
  LD A,(BC)
  SUB (SCREEN_PIXEL_BUF-SCREEN)>>8 ; buffer address to screen address
  LD H,A
  LD DE,SpriteFoot        ; foot sprite
  LD C,$00
  CALL DrawSprite
  LD A,(ScratchByte)
  CPL                     ; E = $FF - counter: delay, shorter every step
                          ; (rising whistle)
  LD E,A
  XOR A
  LD BC,GAME_OVER_TOGGLES ; 64 toggles
ShowGameOver_Buzz:
  OUT (ULA_PORT),A
  XOR BEEPER_BITS
  LD B,E
ShowGameOver_0:
  DJNZ ShowGameOver_0
  DEC C
  JR NZ,ShowGameOver_Buzz
  LD HL,ATTRS             ; flood the screen attributes ...
  LD DE,ATTRS+$0001
  LD BC,ROOM_ATTRS_SIZE-$0001
  LD A,(ScratchByte)
  AND $0C                 ; ... paper = (counter AND $0C) / 4: 0, 1, 2, 3 ...
  RLCA
  OR BRIGHT+WHITE         ; ... with bright white ink
  LD (HL),A
  LDIR
  AND $FF-BLUE-GREEN      ; barrel: ink red, keep the rest
  OR RED
  LD (BARREL_ATTRS),A
  LD (BARREL_ATTRS+$0001),A
  LD (BARREL_ATTRS+SCREEN_COLS),A
  LD (BARREL_ATTRS+SCREEN_COLS+$0001),A
  LD A,(ScratchByte)
  ADD A,GAME_OVER_STEP    ; next foot position
  LD (ScratchByte),A
  CP GAME_OVER_STEPS      ; after $C0: the foot has landed
  JR NZ,ShowGameOver_Step
  LD IX,GameText          ; "Game" ...
  LD C,GAME_OVER_WORD_LEN
  LD DE,GAME_OVER_TEXT_1
  CALL PrintText
  LD IX,OverText          ; "Over" ...
  LD C,GAME_OVER_WORD_LEN
  LD DE,GAME_OVER_TEXT_2
  CALL PrintText
  LD BC,$0000             ; C counts 256 loops, D = 6 times 256
  LD D,GAME_OVER_FLASH_LOOPS
ShowGameOver_Flash:
  DJNZ ShowGameOver_Flash
  LD A,C                  ; ink = C mod 8 on the first letter, +1 on each next
                          ; letter, bright
  AND INK_MASK
  OR BRIGHT
  LD (GAME_TEXT_ATTRS),A
  INC A
  AND INK_MASK
  OR BRIGHT
  LD (GAME_TEXT_ATTRS+$0001),A
  INC A
  AND INK_MASK
  OR BRIGHT
  LD (GAME_TEXT_ATTRS+$0002),A
  INC A
  AND INK_MASK
  OR BRIGHT
  LD (GAME_TEXT_ATTRS+$0003),A
  INC A
  AND INK_MASK
  OR BRIGHT
  LD (GAME_TEXT_ATTRS+$0008),A
  INC A
  AND INK_MASK
  OR BRIGHT
  LD (GAME_TEXT_ATTRS+$0009),A
  INC A
  AND INK_MASK
  OR BRIGHT
  LD (GAME_TEXT_ATTRS+$000A),A
  INC A
  AND INK_MASK
  OR BRIGHT
  LD (GAME_TEXT_ATTRS+$000B),A
  DEC C
  JR NZ,ShowGameOver_Flash
  DEC D
  JR NZ,ShowGameOver_Flash
  JP NewGame              ; back to the title screen
