; Start a new game: reset the state, show the title screen, play its tune
; Entered when the colour code is accepted (RunCodeCheck), when the game ends
; because the clock reaches the end (FrameLoop, $8A88), when CAPS SHIFT and
; SPACE are held together in the game loop (FrameLoop, $8AB8; observed) and
; when the game-over scene ends (ResumeAfterPause, $8D30). Not a subroutine: it
; never returns and ends by falling through into ScrollTitleMessage. . Part 1
; ($87CA-$8812) resets the game variables: no joystick, Willy alive, standing
; at the start position in room $21 (the Bathroom) with 7 lives, the item
; counter at the first item index, "000" items collected, and every item in the
; item table (from FirstItemIndex to $A4FF) marked present. The tune on/off
; flag keeps its value (only its bit 0, the "key held" flag, is set); the cheat
; key progress at CheatProgress is not reset either. . Part 2 ($8813, entered
; again by ScrollTitleMessage after each scroll of the message) draws the title
; screen: clears the bitmap, copies the $300 attribute bytes from
; TitleAttributes (the title attributes, with the status bar attributes of
; StatusBarAttributes as the bottom third) to the screen, sets the text line
; (row 19) to bright yellow ink and prints the first 32 characters of the
; message at TitleMessage there. It then walks the attribute cells of the upper
; two thirds and draws the diagonal edge pieces of the title graphic
; (TitleEdgePieces) into cells whose attribute is not one of the solid-colour
; codes; the big letters and the solid parts of the picture are attribute cells
; with an empty bitmap. . Part 3 ($8895) detects a Kempston joystick: port $1F
; is read 256 times and the flag at JoystickFlag is set when bit 5 never came
; up (a real interface returns 0 there; a floating bus, as on a bare 48K,
; usually returns set bits). With interrupts off it then plays the title tune
; TitleTune with PlayTune; ScrollTitleMessage gets the Z flag from it: Z when
; the tune ended, NZ when it was stopped by fire, key 0 or ENTER. . Hardware:
; writes the screen bitmap and attributes, reads port $1F (Kempston) and,
; through the tune, writes port $FE (beeper). Interrupts stay disabled.
NewGame:
  XOR A                   ; clear the variables:
  LD (JoystickFlag),A     ; no Kempston joystick detected (yet)
  LD (TuneStep),A         ; frame counter used for the tune position and Willy
                          ; animation in the lives display
  LD (FlashTimer),A       ; counter read by FrameLoop (screen paper colour
                          ; effect; nothing else sets it)
  LD (WillyAirState),A    ; Willy is not killed (WillyAirState = $FF would kill
                          ; him)
  LD (PassCounter),A      ; frame counter (the game clock advances when it
                          ; wraps)
  LD (IdleCounter),A      ; counter incremented every frame by FrameLoop
  LD (EndingStage),A      ; game state (EndingStage)
  LD A,START_LIVES        ; lives
  LD (LivesLeft),A        ; lives (LivesLeft)
  LD A,WILLY_START_Y
  LD (WillyY),A           ; Willy start Y
  LD A,START_ROOM
  LD (CurrentRoom),A      ; start in the Bathroom
  LD HL,WILLY_START_ATTR
  LD (WillyAttrAddr),HL   ; Willy start position in the attribute buffer
                          ; (WillyAttrAddr)
  LD HL,ItemsCollectedText ; items collected: three ASCII digits "000"
  LD (HL),ASCII_ZERO
  INC HL
  LD (HL),ASCII_ZERO
  INC HL
  LD (HL),ASCII_ZERO
  LD H,ItemRoomTable>>8   ; HL = item table $A400 + first item index
  LD A,(FirstItemIndex)   ; first item index ($AD)
  LD L,A
  LD (ItemCounter),A      ; item counter starts at the first index; counts up
                          ; to 0 when all are collected
NewGame_Item:
  SET ITEM_PRESENT_BIT,(HL) ; mark the item present, for items from the first
                            ; index up to $FF
  INC L
  JR NZ,NewGame_Item      ; until L wraps to 0
  LD HL,TuneFlags         ; tune flag byte TuneFlags: set bit 0 (a key is held:
                          ; ENTER, which started the game, is on the half row
                          ; that toggles the tune, so this keeps it from
                          ; toggling); bit 1 (tune off) is kept
  SET 0,(HL)

; Show the title screen, play the title tune and scroll the message
;
; Clears the bitmap, copies the title attributes from TitleAttributes, draws
; the title graphic from TitleEdgePieces, detects a Kempston joystick
; (JoystickFlag) and plays the title tune TitleTune, then goes on to
; ScrollTitleMessage, which scrolls the message.
;
; Entered from NewGame (new game) and again from ScrollTitleMessage after each
; full scroll of the message.
;
; Hardware: writes the screen bitmap and attributes, reads the Kempston port
; and the keyboard, drives the beeper.
ShowTitleScreen:
  LD HL,SCREEN            ; clear the bitmap: first byte, then fill the rest
  LD DE,SCREEN+$0001
  LD BC,BITMAP_SIZE-$0001
  LD (HL),$00
  LDIR
  LD HL,TitleAttributes   ; title attributes (TitleAttributes) to the screen: 3
                          ; thirds, the last third is the status bar colours
  LD BC,ATTRS_SIZE
  LDIR
  LD HL,TEXT_LINE_ATTR    ; row 19: bright yellow ink on black
  LD DE,TEXT_LINE_ATTR+$0001
  LD BC,SCREEN_COLS-$0001
  LD (HL),BRIGHT+YELLOW
  LDIR
  LD IX,TitleMessage      ; first 32 characters of the message "+++++ Press
                          ; ENTER to Start +++++"
  LD DE,TEXT_LINE_SCREEN  ; row 19
  LD C,SCREEN_COLS
  CALL PrintText
  LD DE,ATTRS             ; walk the attribute cells of the upper two thirds
ShowTitleScreen_Cell:
  LD A,(DE)               ; A = attribute of the cell
  OR A
  JR Z,ShowTitleScreen_3  ; attributes $00, $D3, $09, $2D, $24: solid colour
                          ; cells, no pixels to draw
  CP FLASH+BRIGHT+RED*PAPER+MAGENTA
  JR Z,ShowTitleScreen_3
  CP BLUE*PAPER+BLUE
  JR Z,ShowTitleScreen_3
  CP CYAN*PAPER+CYAN
  JR Z,ShowTitleScreen_3
  CP GREEN*PAPER+GREEN
  JR Z,ShowTitleScreen_3
  LD C,$00                ; C selects the piece: 0 or $10 by attribute ...
  CP BLUE*PAPER           ; $08, $29, $05 (and $2C, replaced by $25 below): C =
                          ; 0
  JR Z,ShowTitleScreen_1
  CP CYAN*PAPER+BLUE
  JR Z,ShowTitleScreen_1
  CP CYAN*PAPER+GREEN
  JR Z,ShowTitleScreen_0
  CP CYAN
  JR Z,ShowTitleScreen_1
  LD C,$02*CELL_HEIGHT    ; any other attribute: C = $10
  JR ShowTitleScreen_1
ShowTitleScreen_0:
  LD A,GREEN*PAPER+CYAN   ; attribute $2C is stored back as $25 and drawn with
                          ; C = 0
  LD (DE),A
ShowTitleScreen_1:
  LD A,E                  ; piece index = C + 8 for odd columns: pieces at
                          ; TitleEdgePieces (4 pieces of 8 bytes)
  AND $01
  RLCA
  RLCA
  RLCA
  OR C
  LD C,A
  LD B,$00
  LD HL,TitleEdgePieces   ; HL = piece address
  ADD HL,BC
  PUSH DE
  BIT 0,D                 ; cell in the first third ($58xx) or the second
                          ; ($59xx) of the screen: bitmap page $40 or $48
  LD D,SCREEN>>8
  JR Z,ShowTitleScreen_2
  LD D,(SCREEN+THIRD_SIZE)>>8
ShowTitleScreen_2:
  LD B,CELL_HEIGHT
  CALL DrawGlyph8         ; draw the 8 rows with DrawGlyph8; DE = $40/$48 +
                          ; attribute address low byte
  POP DE
ShowTitleScreen_3:
  INC DE
  LD A,D
  CP BOTTOM_THIRD_ATTRS>>8 ; stop at $5A00: only the upper two thirds hold the
                           ; picture
  JP NZ,ShowTitleScreen_Cell
ShowTitleScreen_Joystick:
  LD BC,KEMPSTON_PORT     ; B = 0: 256 reads of port $1F
  DI                      ; interrupts stay off from here to the start of the
                          ; game
  XOR A
ShowTitleScreen_4:
  IN E,(C)                ; OR together 256 readings
  OR E
  DJNZ ShowTitleScreen_4
  AND KEMPSTON_UNUSED_MASK
  JR NZ,ShowTitleScreen_Tune
  LD A,$01                ; bit 5 never set: treat as a Kempston interface
                          ; (fire starts the game)
  LD (JoystickFlag),A     ; joystick flag JoystickFlag = 1
ShowTitleScreen_Tune:
  LD HL,TitleTune         ; title tune; returns NZ if stopped by fire, 0 or
                          ; ENTER
  CALL PlayTune           ; falls into ScrollTitleMessage, which tests the flag

; Scroll the title message, start the game, enter a room Three parts that share
; one entry. . Part 1 ($88AE-$88F9) continues the title screen of NewGame: it
; gets the result of the title tune (NZ if a start key stopped it) and, when
; the tune ended on its own, scrolls the message at TitleMessage along text
; line 19, one character per step, for $E0 steps (the message is 256
; characters, the window 32; the last window equals the first, "+++++ Press
; ENTER to Start +++++"). Each step cycles the colours of all attribute cells
; with CycleColours (the border follows the first cell), prints the
; 32-character window in bright white on blue, plays a sound with
; PlaySweepSound and tests key 0 and ENTER (port $AFFE). A press ends the
; scroll and starts the game; when the scroll reaches the end the title screen
; is drawn again (JP ShowTitleScreen) and the tune restarts. Kempston fire is
; tested only while the tune plays (ReadStartInput), not here. Observed: the
; whole scroll takes 843 frames after the tune (frames 1582-2425 in the
; code.txt run). . Part 2 ($88FC) starts the game: resets the clock text at
; ClockText from ClockStartText and copies the status bar attributes from
; StatusBarAttributes to the bottom third of the screen, then falls into room
; entry. . Part 3 ($8912, entered at the start of the game and by every room
; change: ExitRoomLeft, ExitRoomRight, ExitRoomUp, ExitRoomDown, the cheat
; teleport and the restart after a death in ResumeAfterPause) loads room number
; CurrentRoom from the room table: the 256 bytes at $C000 + 256 * room are
; copied to RoomBuffer. It then builds the entity buffer EntityBuffer from the
; eight slots of the room (RoomEntitySlots): for each slot, the 8-byte
; definition at $A000 + 8 * index (bit 7 of the index ignored) is copied, and
; the slot's second byte replaces byte 2 of the copy and of the definition.
; Then it saves Willy's state ($85CF-$85D5, 7 bytes) at $85D7 (the position to
; return to after a death), builds the empty-room buffers with
; BuildRoomBuffers, clears the bottom third of the bitmap, prints the room name
; (32 characters from RoomName) on row 16 and the status line text
; StatusLineText on row 19, sets the border colour of the room, clears
; WillyRope and jumps to the game loop FrameLoop. . Hardware: reads ports $AFFE
; (keyboard) and, through the sound, writes port $FE (border, beeper); writes
; the screen bitmap and attributes.
ScrollTitleMessage:
  JP NZ,StartGame         ; NZ from PlayTune: the tune was stopped by a start
                          ; key
  XOR A                   ; scroll offset (ScratchByte) = 0
  LD (ScratchByte),A
ScrollTitleMessage_Step:
  CALL CycleColours       ; cycle the colours of all attribute cells
                          ; (CycleColours)
  LD HL,TEXT_LINE_ATTR    ; row 19 attributes: bright white on blue
  LD DE,TEXT_LINE_ATTR+$0001
  LD BC,SCREEN_COLS-$0001
  LD (HL),BRIGHT_WHITE_ON_BLUE
  LDIR
  LD A,(ScratchByte)
  LD IX,TitleMessage      ; IX = message + scroll offset
  LD E,A
  LD D,$00
  ADD IX,DE
  LD DE,TEXT_LINE_SCREEN
  LD C,SCREEN_COLS
  CALL PrintText          ; print the 32-character window on row 19
  LD A,(ScratchByte)
  AND SCROLL_PITCH_MASK   ; sound pitch depends on the position in the message
  ADD A,SCROLL_PITCH_BASE ; A = (offset AND $1F) + $32
  CALL PlaySweepSound     ; sweep sound PlaySweepSound
  LD BC,KEYROW_START
  IN A,(C)                ; key 0 or ENTER (bit 0 low when pressed)
  AND $01
  CP $01
  JR NZ,StartGame         ; pressed: start the game
  LD A,(ScratchByte)
  INC A                   ; next step
  CP TITLE_SCROLL_STEPS
  LD (ScratchByte),A
  JR NZ,ScrollTitleMessage_Step ; more steps
  JP ShowTitleScreen      ; end of the message: draw the title screen again and
                          ; replay the tune

; Start a game: reset the clock and the status bar
;
; Start the game: reset the clock text and the status bar attributes, then
; enter the first room (falls into EnterRoom).
StartGame:
  LD HL,ClockStartText    ; clock text: " 7:00a" from ClockStartText to
                          ; ClockText
  LD DE,ClockText
  LD BC,CLOCK_LENGTH
  LDIR
  LD HL,StatusBarAttributes ; status bar attributes (StatusBarAttributes) to
                            ; the bottom third of the screen
  LD DE,BOTTOM_THIRD_ATTRS
  LD BC,THIRD_ATTRS_SIZE
  LDIR

; Enter a room: build its entities and buffers and start the frame loop
;
; Copies the room whose number is in CurrentRoom from RoomOffLicence to
; RoomBuffer, builds the entity buffer EntityBuffer from the definitions at
; EntityDefs, saves Willy's state at WillySavedState, builds the room buffers
; (BuildRoomBuffers), prints the room name and the status line and sets the
; border, then jumps to the frame loop FrameLoop.
;
; Used by every room change (ExitRoomLeft, ExitRoomRight, ExitRoomUp,
; ExitRoomDown), the teleport cheat (CheckTeleport), the restart after a death
; (PlayDeath) and the start of a game (StartGame).
;
; Hardware: writes the bottom third of the screen bitmap and attributes and the
; border (port $FE).
EnterRoom:
  LD A,(CurrentRoom)      ; room number
  OR ROOM_TABLE_PAGE      ; high byte of the room address: $C0 OR room
  LD H,A
  LD L,$00                ; HL = $C000 + 256 * room
  LD DE,RoomBuffer
  LD BC,ROOM_SIZE         ; copy the room to the room buffer RoomBuffer
  LDIR
  LD IX,RoomEntitySlots   ; IX = the room's 8 entity slots (2 bytes each)
  LD DE,EntityBuffer      ; DE = entity buffer
  LD A,ROOM_SLOTS
EnterRoom_Slot:
  LD L,(IX+$00)           ; L = definition index of the slot
  RES 7,L                 ; bit 7 is ignored
  LD H,EntityDefs>>11     ; HL = $1400, times 8 below: $A000 + 8 * index
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,$0002             ; copy definition bytes 0-1 to the entity buffer
  LDIR
  LD C,(IX+$01)           ; slot start byte replaces byte 2 of the definition
                          ; (HL points to it) ...
  LD (HL),C
  LD BC,ENTITY_SIZE-$0002 ; ... and the copy continues with bytes 2-7
  LDIR
  INC IX                  ; next slot
  INC IX
  DEC A
  JR NZ,EnterRoom_Slot
  LD HL,WillyY            ; save Willy's state $85CF-$85D5 at $85D7: position
                          ; to restart from after a death (8C3C copies it back)
  LD DE,WillySavedState
  LD BC,WILLY_STATE_SIZE
  LDIR
  CALL BuildRoomBuffers   ; expand the room into the empty-room buffers
  LD HL,BOTTOM_THIRD_SCREEN ; clear the bottom third of the bitmap (room name,
                            ; status line and lives)
  LD DE,BOTTOM_THIRD_SCREEN+$0001
  LD BC,THIRD_SIZE-$0001
  LD (HL),$00
  LDIR
  LD IX,RoomName
  LD C,SCREEN_COLS
  LD DE,BOTTOM_THIRD_SCREEN
  CALL PrintText          ; room name on row 16
  LD IX,StatusLineText
  LD DE,TEXT_LINE_SCREEN  ; status line text on row 19
  LD C,SCREEN_COLS
  CALL PrintText
  LD A,(RoomBorder)       ; border colour of the room
  LD C,ULA_PORT
  OUT (C),A
  XOR A
  LD (WillyRope),A        ; clear WillyRope
  JP FrameLoop            ; start the game loop
