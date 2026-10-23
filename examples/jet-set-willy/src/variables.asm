; Current room number
;
; Number of the room Willy is in. The room data is at $C000 + 256 * number
; (EnterRoom uses the low 6 bits). Set to $21, the Bathroom, by NewGame;
; changed by the room exit routines (ExitRoomLeft, ExitRoomRight, ExitRoomUp,
; ExitRoomDown) from the exit bytes of the room, and by the cheat teleport of
; ResumeAfterPause (with key 9 held, keys 1-5 and 6 give the number in binary:
; observed, 2+3 gave room 6). Also read by the code that depends on the room
; (UpdateItems, DrawWilly and others).
CurrentRoom:
  DEFB $00

; Willy's walking state transition table (16 bytes)
;
; Read by MoveWilly (at $8F65) after the keyboard/joystick has been scanned.
; Index = key bits + old state, where the old state is the byte WillyMoveState
; (0-3) and the key bits are 0 (no direction pressed), 4 (a left key or
; joystick left pressed), 8 (a right key pressed) or 12 (both). The byte read
; becomes the new WillyMoveState. Bits of the state:
;
; bit 0: facing/direction, 1 = left, 0 = right (DrawWilly picks the sprite half
; from it and MoveWilly moves left when it is set). bit 1: Willy walks this
; frame (set at the start of a jump too).
;
; Rows of four, by old state 0, 1, 2, 3:
;
; +$00 no key: $00,$01,$00,$01 (keep the direction, stop walking) +$04 left:
; $01,$03,$01,$03 (face left; walk only if already facing left, so a change of
; direction takes one frame without a step) +$08 right:  $02,$00,$02,$00 (face
; right; walk only if already facing right) +$0C both:   $00,$01,$02,$03 (state
; unchanged)
;
; Observed in the simulator with tests/inputs/start.txt: pressing P in the
; Bathroom: state 0 -> 2; kept at 2 while P is held; released: 2 -> 0; pressing
; O: 0 -> 1 (turn) -> 3 (walk) -> 3.
MoveStateTable:
  DEFB $00,$01,$00,$01,$01,$03,$01,$03
  DEFB $02,$00,$02,$00,$00,$01,$02,$03

; Title graphic edge pieces: four 8x8 cells
;
; Pixel data (8 bytes each) of the slanted edges of the picture on the title
; screen, drawn by NewGame with DrawGlyph8 into cells of the attribute map
; TitleAttributes that are not solid colours. A 16-pixel-wide edge takes two
; cells side by side: the piece is +0 or +$10, chosen by the cell attribute
; (see NewGame), plus 8 when the cell column is odd (the right cell).
;
; +$00 left cell of an edge that runs down and to the right at 2 pixels per
; row: the edge in rows 0-3 ($C0,$F0,$FC,$FF), solid below it, the filled part
; is the left side. +$08 right cell of the same edge: empty in rows 0-3, the
; edge in rows 4-7. +$10 left cell of an edge that runs down and to the left:
; solid in rows 0-3, then $FC,$F0,$C0,$00. +$18 right cell of that edge:
; $FC,$F0,$C0,$00 in rows 0-3, empty below.
TitleEdgePieces:
  DEFB $C0,$F0,$FC,$FF,$FF,$FF,$FF,$FF
  DEFB $00,$00,$00,$00,$C0,$F0,$FC,$FF
  DEFB $FF,$FF,$FF,$FF,$FC,$F0,$C0,$00
  DEFB $FC,$F0,$C0,$00,$00,$00,$00,$00

; Unused text "AIR"
;
; Three characters just before the title text at TitleMessage. Nothing
; references them: no operand or word in the image points to $8451-$8453, and
; overwriting them changed no frame in two simulator runs (the start script for
; 800 frames and an in-game fuzz run for 1500 frames). Purpose Unknown;
; probably a leftover label.
UnusedAirText:
  DEFM "AIR"

; Title screen message: 256 characters, scrolled along row 19
;
; Eight lines of 32 characters, ASCII (character $7F is the copyright sign of
; the ROM font). NewGame prints the first 32 characters on the title screen;
; ScrollTitleMessage then shows a 32-character window that moves one character
; per step over the whole text (offsets 0 to $DF). The last 32 characters equal
; the first 32, so the scroll ends where it started. Text: "+++++ Press ENTER
; to Start +++++", the title and credit lines, and the story: guide Willy to
; collect all the items around the house before midnight so that Maria will let
; him get to his bed.
TitleMessage:
  DEFM "+++++ Press ENTER to Start +++++"
  DEFM "  JET-SET WILLY by Matthew Smith"
  DEFM "  ",$7F," 1984 SOFTWARE PROJECTS Ltd ."
  DEFM " . . . .Guide Willy to collect a"
  DEFM "ll the items around the house be"
  DEFM "fore Midnight so Maria will let "
  DEFM "you get to your bed. . . . . . ."
  DEFM "+++++ Press ENTER to Start +++++"

; Status line text: 32 characters
;
; Printed on row 19 of the screen by ScrollTitleMessage when a room is entered.
; Columns 0-15 "Items collected ", 16-18 the item count digits (printed over
; each frame from ItemsCollectedText by FrameLoop at $5070), column 19 a blank,
; 20-23 "Time", 24 a blank, 25-30 the clock (printed over each frame from
; ClockText at $5079) and column 31 "m", which completes "am" or "pm" after the
; clock letter. The "00:00" and the three zeros here are placeholders that are
; never seen.
StatusLineText:
  DEFM "Items collected 000 Time 00:00 m"

; Game over message, first word
;
; "Game" (4 characters), printed at screen row 6, column 10 by the game over
; scene (ResumeAfterPause, $8CCB) with PrintText; "Over" follows at column 18
; (OverText), leaving the middle for the falling foot.
GameText:
  DEFM "Game"

; Game over message, second word
;
; "Over" (4 characters), printed at screen row 6, column 18 by the game over
; scene (ResumeAfterPause, $8CD7); see GameText.
OverText:
  DEFM "Over"

; Items collected, as three ASCII digits
;
; Shown on the status line ("Items collected 000"; printed by FrameLoop at
; screen address $5070). NewGame sets it to "000" at the start of a game and
; UpdateItems adds 1 for every item collected, with decimal carry from the last
; digit to the first.
;
; Observed: "000" becomes "001" at the first pick-up; "099" becomes "100".
ItemsCollectedText:
  DEFM "000"

; Game clock text: 6 characters
;
; The time of day as ASCII, printed at column 25 of row 19 each frame
; (FrameLoop): hours (blank or "1", then a digit), ":", minutes (two digits),
; and the letter "a" or "p". Starts as " 7:00a" (copied from ClockStartText by
; ScrollTitleMessage). The minutes advance each time the frame counter
; PassCounter wraps to 0 (every 256 passes of the game loop; observed). The
; hour goes 12 to 1 and switches "a" to "p" there; the game ends and restarts
; (NewGame) when the clock reaches 13:00 with the letter "p" (observed with
; "12:59p"). Poked values: " 9:59a" gives "10:00a", "12:59a" gives " 1:00p".
ClockText:
  DEFM " 7:00a"

; Initial game clock text
;
; The 6 characters " 7:00a" that ScrollTitleMessage copies to ClockText when
; the game starts (and not when a new life starts: the clock keeps running
; through deaths).
ClockStartText:
  DEFM " 7:00a"

; Colour-code prompt, first attempt
;
; 32 characters shown on screen row 8 by AskColourCode (via PrintText). The
; last four characters are blanks that the grid cell letter and digit overwrite
; at columns 29 and 30.
EnterCodeText:
  DEFM "Enter Code at grid location     "

; Colour-code prompt, second attempt
;
; Same layout as EnterCodeText; used by RunCodeCheck after a wrong code.
TryAgainText:
  DEFM "Sorry, try code at location     "

; Pass counter: frames of the game loop, modulo 256
;
; Incremented once at the end of every pass of the frame loop (FrameLoop,
; $8A49). Each time it wraps from $FF to 0 the clock advances by one minute
; (ClockText), so a game minute is 256 passes (about 19 seconds with the tune
; on and 17 with it off, see FrameLoop). The low bits also drive animations:
; the colour of the flashing items (UpdateItems), the guard figure in the
; Master Bedroom (UpdateBedroom) and the toilet (DrawToilet). Cleared by
; NewGame at a new game and by CheckToiletReached when the ending stage 3
; starts (so the toilet animation starts in step).
;
; Observed: the clock changes from 7:00am to 7:01am 256 passes after the
; counter was 0, and with the counter poked to $FF the minute advances in the
; next pass.
PassCounter:
  DEFB $00

; Lives in reserve
;
; Set to 7 by NewGame at a new game. DrawLives shows one small Willy for each
; one. When Willy is killed the death flash plays (ResumeAfterPause, $8C01) and
; then, if this is not 0, it is decremented and Willy restarts the room; if it
; is 0 the game over scene follows. So a game allows 8 deaths in all: the 8th
; ends it (observed with random keys from the Bathroom snapshot: the byte went
; 7, 6, 5, 4, 3, 2, 1, 0 after each of seven deaths, and the eighth death ran
; the game over scene). Nothing adds a life. Also used by the in-game tune: the
; fewer lives, the lower the notes (GameTune).
LivesLeft:
  DEFB $00

; Screen flash timer: never set to a non-zero value by the game
;
; If not 0, FrameLoop decrements it once per pass and floods the attribute
; buffer of the room area (5C00, 512 bytes) with the paper colour (new value *
; 8 and $38, black ink), hiding the room's colours for that pass. A value of N
; therefore gives N flashes with paper colours N-1, N-2 ... 0 (modulo 8). Only
; NewGame (writes 0) and FrameLoop (decrements) access it: no code sets it, so
; the effect is not used in the original game (inferred from the references;
; checked by poking the byte).
;
; Observed: with the byte poked to 3 the room attributes were $10, $08 and $00
; in the next three passes, then the room was drawn normally.
FlashTimer:
  DEFB $00

; Kempston joystick flag
;
; 0 = no joystick, 1 = a Kempston joystick is used in addition to the keys.
; Cleared and then set by NewGame if port $1F never returned bit 5 in 256
; reads. Read by ReadStartInput (fire starts the game while the title tune
; plays) and by the movement code MoveWilly, which then adds port $1F (right =
; bit 0, left = bit 1, fire = bit 4, used for the jump: inferred from the code)
; to the key input. Observed: in the simulator, which returns 0 for port $1F,
; the flag is 1 after the title screen; in the Bathroom snapshot with the flag
; poked to 1 the Kempston right input moves Willy right, with 0 it does not;
; fire at the tune starts the game.
JoystickFlag:
  DEFB $00

; Willy's Y index: twice the pixel row of the top of his sprite
;
; Index into the row address table RowAddressTable (2 bytes per pixel row), so
; Y / 2 is the pixel row (0-127) and Y / 16 the character row (0-15) of the top
; of his 16x16 sprite. Standing on the floor of character row 15 gives $D0
; (pixel row 104, character row 13), the value at a new game. The attribute
; address WillyAttrAddr is always the cell of row Y / 16 (kept in step by
; SetWillyCell). Y is unsigned: a rise through the top wraps it to $F0 or more
; and the frame loop leaves the room upwards (ExitRoomUp, which sets $D0 in the
; new room); a fall past the bottom leaves it downwards (ExitRoomDown, which
; sets 0).
;
; Changed by MoveWilly (jump: -8 to +8 per pass; fall: +8 per pass; ramp step:
; 16 up or down), by the rope code DrawEntities (while he holds a rope Y is the
; rope point's Y index minus $10), by the room exits, by NewGame and by the
; death restore from WillySavedState. Read by DrawWilly and PlaceWilly
; (drawing, with the ramp offset added) and by the Master Bedroom guard
; (UpdateBedroom).
;
; Observed in the simulator: jump arc and fall steps, see findings F109-F111,
; F118.
WillyY:
  DEFB $00

; Willy's move state: facing and walking bits
;
; bit 0: 1 = facing left (the sprite half of DrawWilly and the direction of the
; walking step in MoveWilly)
;
; bit 1: 1 = Willy walks in this pass (one cell every 4 passes in the facing
; direction)
;
; Values 0-3. Every pass in which Willy is on the ground or on a rope MoveWilly
; replaces it with MoveStateTable[old state + 4 * left + 8 * right] (see
; there); the walking bit is cleared in a fall and by a head bump, and set when
; he jumps off a rope. During a jump the keys are not read, so the state at
; take-off (and with it the sideways direction) is kept until he lands. Saved
; at room entry in WillySavedState. Also used by the rope code DrawEntities,
; which reads it to climb: walking (bit 1) moves him along the rope, facing
; (bit 0) decides up or down.
;
; Observed: P pressed from standing: 0 -> 2 (walks right at once); O pressed: 0
; -> 1 (turns, no step) -> 3; released: 3 -> 1, 2 -> 0.
WillyMoveState:
  DEFB $00

; Willy's air state: on the ground, jumping, falling or killed
;
; 0: standing or walking on ground, or holding a rope (WillyRope)
;
; 1: in a jump; WillyJumpStep counts the steps 0-17 (the arc is described at
; MoveWilly)
;
; 2-$0F: falling. 2 when he walks off an edge or bumps his head, 6 at the end
; of a jump; it counts up by 1 in every pass of the fall and from $10 returns
; to $0C, so a long fall cycles through $0C-$0F. A landing with a state of $0C
; or more kills him (8EE3). Standing at the take-off point that means a drop of
; 5 character rows (40 pixel rows) or more; after a jump that ended over a gap
; (state 6) a drop of 3 rows or more. Drops of 4 and 2 rows respectively are
; survived.
;
; $FF: killed (set by KillWilly, see WILLY_KILLED); the frame loop then plays
; the death flash (CheckDeath) and either restarts the room from
; WillySavedState or ends the game.
;
; Set to 0 at a new game and by the exit up (ExitRoomUp); exit down
; (ExitRoomDown) makes it 2 when it was below $0B. Saved at room entry in
; WillySavedState.
;
; Observed: falls from each height checked in the Bathroom with Willy poked
; into the air, see findings F109-F111.
WillyAirState:
  DEFB $00

; Willy's walk frame: step counter and sprite frame
;
; Bits 0-1 only (0-3): the frame of the Willy sprite within the half chosen by
; the facing bit of WillyMoveState (DrawWilly adds frame * 32 to the sprite
; address), and the step timer of MoveWilly. While he walks, the frame counts 3
; down to 0 when facing left and 0 up to 3 when facing right, one count per
; pass, and the cell step is taken in the pass that finds it at 0 (left) or 3
; (right): after the step it is reloaded with 3 (left) or 0 (right). So a step
; takes 4 passes and the four frames are shown once per step. It keeps its
; value when he stops, so a new walk resumes in the middle of the cycle. In the
; ending stages 2 and 3 the frame loop sets bit 0 in every pass (FrameLoop,
; $8A00) which speeds the animation up. Saved at room entry in WillySavedState.
WillyFrame:
  DEFB $00

; Willy's attribute address: his top-left cell in the attribute buffer
;
; Word (low byte first): address of the attribute cell at the top-left of
; Willy's 2 x 2 cells in the room attribute buffer 5C00. Low 5 bits of the low
; byte = screen column (0-31) of the left cell; the other bits of the word give
; the row: $5C00 + 32 * row + column, so the high byte is $5C for rows 0-7 and
; $5D for rows 8-15. The row is Y / 16 of WillyY; SetWillyCell recomputes the
; word from Y. Willy covers this cell and the one to the right in the top row
; (and two more in the next row, two more again when Y is between rows); the
; cells below are what he stands on.
;
; A step changes the column by 1 (and the row by 1 on a ramp); the room exits
; wrap the column (ExitRoomLeft, ExitRoomRight) or set the row and the page
; (ExitRoomUp, ExitRoomDown). Set to $5DB4 (row 13, column 20) at a new game.
; Read by DrawWilly (column), PlaceWilly, the room events (UpdateBedroom,
; CheckToiletReached) and the rope code. Saved at room entry in WillySavedState
; (bytes +4 and +5 of the copy).
WillyAttrAddr:
  DEFW $0000

; Willy's jump step: 0-18
;
; The step of the jump arc, meaningful while the air state WillyAirState is 1:
; set to 0 when a jump starts (MoveWilly_Jump), incremented once per pass, and
; at 18 the jump becomes a fall of state 6. The Y change of a pass is (step AND
; $FE) - 8 index units, for steps 0-17: -8 -8 -6 -6 -4 -4 -2 -2 0 0 +2 +2 +4 +4
; +6 +6 +8 +8, a rise of 40 units (20 pixel rows) and a return to the take-off
; height. After steps 13 and 16 the ground test is made. It keeps the value 18
; after the jump until the next one starts. Saved at room entry in
; WillySavedState (byte +6 of the copy).
;
; Observed (finding F109) with a jump from a floor: Y $D0 -> $C8 $C0 $BA $B4
; $B0 $AC $AA $A8 $A8 $A8 $AA $AC $B0 $B4 $BA $C0 $C8 $D0 over 18 passes.
WillyJumpStep:
  DEFB $00

; Rope state: 0 = no rope, 1-$20 = rope segment held, $F0-$FF = let go a moment
; ago
;
; Shared by the rope code DrawEntities (which sets it when Willy touches a rope
; point, moves it while he climbs, and counts the release value up) and
; MoveWilly, which tests it at the start of the pass: with a value of 1-$80
; (that is, ((value - 1) AND $80) = 0) he holds a rope: there is no jump or
; fall logic, no walking and no landing, only the keys are read (the move state
; then drives the climbing in DrawEntities). A jump key on a rope sets it to
; $F0 ($8FA9, ROPE_LET_GO), sets the walking bit of WillyMoveState and starts a
; jump from the row boundary above. It is not saved with Willy's other state:
; it is cleared to 0 whenever a room is entered (EnterRoom, at $8985). See
; findings F87-F89.
WillyRope:
  DEFB $00

; Saved copy of Willy's state: the position he returns to after a death
;
; 7 bytes, a copy of $85CF-$85D5 made at every room entry (EnterRoom, at
; $894A), before the room is built: +0 Y index WillyY
;
; +1 move state WillyMoveState
;
; +2 air state WillyAirState
;
; +3 walk frame WillyFrame
;
; +4 attribute address WillyAttrAddr (word, low byte first)
;
; +6 jump step WillyJumpStep
;
; When Willy is killed and a life is left, ResumeAfterPause (at $8C3C) copies
; the 7 bytes back and enters the room again, so he restarts from the state in
; which he entered it (a room entered by falling in restarts the fall). The
; rope variable WillyRope is not part of the copy.
;
; Observed (finding F117): after entering a room with Willy in the middle of a
; walk (state 3, frame 2, jump step 5) and a fatal fall, all seven variables
; came back with the saved values.
WillySavedState:
  DEFB $00,$00,$00,$00,$00,$00,$00

; Item counter (counts up to 256 when every item is collected)
;
; Set to the index of the first item (FirstItemIndex, $AD) when a game starts
; (NewGame, at $8806) and incremented by UpdateItems for every item collected.
; With N items in the table (256 minus the first index, 83 here) it wraps to 0
; exactly when the last one is collected; UpdateItems then also sets
; EndingStage to 1. The value is not displayed: the display is the three ASCII
; digits at ItemsCollectedText.
;
; Observed: starts at $AD, becomes $AE after the first pick-up in the Bathroom;
; with the first item index poked to $FF the pick-up wraps it to 0 and
; EndingStage becomes 1.
ItemCounter:
  DEFB $00

; Ending stage: what the game does once every item is collected
;
; One byte, 0 at the start of a game (NewGame clears it). The values form a
; one-way sequence; nothing sets it back except a new game.
;
; 0: normal play. In the Master Bedroom (room $23) UpdateBedroom draws a guard
; figure (SpriteFigure0) that kills Willy on contact.
;
; 1: every item is collected (set by UpdateItems when ItemCounter wraps to 0).
; The figure is no longer drawn, so Willy can walk to the bed end of the Master
; Bedroom. Everything else is as in state 0.
;
; 2: set by UpdateBedroom when Willy in the Master Bedroom is in a column below
; 6 (the bed end). MoveWilly now sees the right key as pressed (the P bit of
; port $DFFE is inverted at $8F05) so Willy runs right by himself, twice as
; fast (FrameLoop ORs bit 0 into the animation frame WillyFrame), a jump key is
; ignored ($8F8F) and holding a right key stops him. He leaves through the
; right exit and the rooms on the way to the Bathroom are played as usual.
;
; 3: set by CheckToiletReached when Willy is at $5DBC (Bathroom, column 28, row
; 13: the toilet). FrameLoop then no longer calls MoveWilly (no movement, no
; keys) or PlaceWilly (Willy is neither drawn nor checked for nasties), and
; DrawToilet draws the second pair of toilet frames. Nothing leaves this state:
; the game goes on with the other sprites, the clock and the status line until
; the clock passes 12:59pm or caps shift + space are held, both of which
; restart at the title screen (NewGame).
;
; Observed in the simulator, see findings F61-F66.
EndingStage:
  DEFB $00

; Idle counter: passes since the last key or tune pass
;
; Incremented once per pass by FrameLoop ($8ABB). When it wraps to 0 (after 256
; passes) the frame loop does not go on but waits for a key, as if paused
; (FrameLoop, $8AD1). It is cleared in every pass in which the tune plays
; (ResumeAfterPause, $8B3D) and whenever Willy's movement code sees a left or
; right key or a jump (MoveWilly, $8F4E, $8F5B, $8F9A). The effect: with the
; tune off and no key for 256 passes the game stops by itself. Cleared by
; NewGame.
;
; Observed: with the tune off and no key pressed the loop stopped at the wait
; after exactly 256 passes; with the tune on it never did.
IdleCounter:
  DEFB $00

; Tune step counter: also the animation phase of the lives display
;
; Incremented once per pass by ResumeAfterPause ($8B44) while the tune is on
; (bit 1 of TuneFlags clear); it keeps its value while the tune is off. Bits
; 1-6 select the note of the game tune (GameTune: note = (counter AND $7E) / 2,
; so a note lasts two passes and the 64 notes repeat every 128 passes) and bits
; 2-3 select the Willy frame shown by the lives display (DrawLives). Cleared by
; NewGame.
TuneStep:
  DEFB $00

; Tune flags: bit 0 = tune key was down last pass, bit 1 = tune off
;
; The game tune is toggled by any key of the H J K L ENTER half row
; (ResumeAfterPause, $8B1F-$8B38). Bit 0 remembers that such a key was down in
; the previous pass, so that holding the key toggles only once: the first pass
; with a key down and bit 0 clear flips both bits (XOR 3), and a pass without a
; key clears bit 0. Bit 1 set means the tune is off: the tune and the step
; counter TuneStep are skipped. NewGame sets bit 0 only (an ENTER held from the
; title screen cannot toggle), so the tune is on at the first game and keeps
; its state across new games.
;
; Observed: with H pressed and released the byte went 0, 3, 2 and with a second
; press (ENTER) 2, 1, 0; holding the key for several passes toggled once.
TuneFlags:
  DEFB $00

; Cheat progress: number of letters of the key sequence typed so far
;
; 0 at start. While not 10 and while Willy is at Y = $D0 in room $1C (First
; Landing) the frame loop (ResumeAfterPause, $8B97-$8BFE) reads the half rows
; Q-T and P-Y for the step number held here and advances it when the next
; letter of the sequence W R I T E T Y P E R is down (the table is
; CheatKeyTable). A reading that is neither the next letter, nor no key, nor
; the previous letter still held resets it to 0. The value 10 (all ten letters
; typed) switches the cheat on: the room teleport of ResumeAfterPause ($8B70)
; works and the pause no longer cycles the colours (FrameLoop, $8AE1). It is
; not cleared by NewGame, so the cheat stays on across games until the machine
; is reset.
CheatProgress:
  DEFB $00

; Scratch byte: expected colour code, later a loop counter
;
; Written by AskColourCode with the expected colour-code byte (table byte +
; grid cell index) and compared by ReadCodeSlot. After the code check the
; program reuses the byte as a loop counter in two places: ScrollTitleMessage
; sets it to 0 and counts up to $E0 (it offsets into the scrolling text at
; TitleMessage), and ResumeAfterPause sets it to 0 and adds 4 up to $C4 (it
; selects a position from the table at $8200 and a border/attribute value).
; Exact meaning there is Unknown here.
ScratchByte:
  DEFB $00

; Cheat key sequence: 11 pairs of half-row key masks
;
; The keys that must be pressed one after the other (one key at a time) in the
; game to switch on the cheat: W R I T E T Y P E R. Each pair is (byte 0 = half
; row Q-T read from port $FBFE, byte 1 = half row P-Y read from port $DFFE),
; bits 0-4 as read from the port with 0 meaning pressed, so $1F means no key in
; that half row. In byte 0 bit 1 is W, bit 3 R, bit 2 E, bit 4 T; in byte 1 bit
; 2 is I, bit 4 Y, bit 0 P.
;
; The progress (step number 0-10) is the byte CheatProgress; ResumeAfterPause
; reads the pair for the current step at CheatKeyTable + 2 + 2 * step ($8BB6
; loads $85E7 and adds 2 * step). A matching pair advances the step; no key or
; the previous step's pair (key still held) keeps it; any other reading sets
; the step back to 0. The first pair ($1F,$1F) at $85E5 is the "previous pair"
; of step 0. Step 10 is the completed sequence (no pair beyond the table is
; read). Observed: pressing W, R, I, T, E, T, Y, P, E, R one at a time in the
; Bathroom snapshot with the room poked to $1C (First Landing; the code also
; requires room $1C and Y = $D0, WillyY) makes CheatProgress count 1 to 10; W
; and R together, or a key out of order, set it back to 0. With step 10
; reached, key 9 together with keys 1-6 teleports to the room whose number is
; the keys as bits (observed: 9+2+3 gave room 6).
CheatKeyTable:
  DEFB $1F,$1F            ; before step 0: no key in either half row (also the
                          ; "previous step" pair of step 0)
  DEFB $1D,$1F            ; step 0: key W
  DEFB $17,$1F            ; step 1: key R
  DEFB $1F,$1B            ; step 2: key I
  DEFB $0F,$1F            ; step 3: key T
  DEFB $1B,$1F            ; step 4: key E
  DEFB $0F,$1F            ; step 5: key T
  DEFB $1F,$0F            ; step 6: key Y
  DEFB $1F,$1E            ; step 7: key P
  DEFB $1B,$1F            ; step 8: key E
  DEFB $17,$1F            ; step 9: key R

; Title tune: 99 notes and an end marker
;
; Played once by NewGame (88AB) with PlayTune each time the title screen is
; drawn; it ends with $FF. One byte per note: the half-period count E of the
; square wave (larger = lower). Every note has the same length, about 0.29 s
; (100 x 256 inner loops), so the 99 notes take about 29 s (observed: the tune
; started at frame 137 and PlayTune returned at frame 1583 without a key). The
; first half of each note sounds at about 3.5 MHz / (2 * (40 * E + 6)) Hz, the
; second half an octave lower (E doubled); e.g. $51 = 539 Hz, $3C = 727 Hz, $33
; = 855 Hz (computed, not heard; the pitches are within a quarter tone of
; equal- tempered notes).
;
; The notes come in 33 groups of three (the lines of the listing: a bar of
; three equal notes, 3/4 time). Most groups are a low note followed by two
; higher ones: the first group $51,$3C,$33 is C#5 F#5 A5 by the computed
; pitches, repeated for eight bars, then the chords move (D5 F#5 A5, D5 G5 B5,
; C#5 F5 B5, ...) and the tune ends on F5 F#4 F5. The tune cannot be named from
; these notes alone: Unknown.
TitleTune:
  DEFB $51,$3C,$33
  DEFB $51,$3C,$33
  DEFB $51,$3C,$33
  DEFB $51,$3C,$33
  DEFB $51,$3C,$33
  DEFB $51,$3C,$33
  DEFB $51,$3C,$33
  DEFB $51,$3C,$33
  DEFB $4C,$3C,$33
  DEFB $4C,$3C,$33
  DEFB $4C,$39,$2D
  DEFB $4C,$39,$2D
  DEFB $51,$40,$2D
  DEFB $51,$3C,$33
  DEFB $51,$3C,$36
  DEFB $5B,$40,$36
  DEFB $66,$51,$3C
  DEFB $51,$3C,$33
  DEFB $51,$3C,$33
  DEFB $28,$3C,$28
  DEFB $28,$36,$2D
  DEFB $51,$36,$2D
  DEFB $51,$36,$2D
  DEFB $28,$36,$28
  DEFB $28,$3C,$33
  DEFB $51,$3C,$33
  DEFB $26,$3C,$2D
  DEFB $4C,$3C,$2D
  DEFB $28,$40,$33
  DEFB $51,$40,$33
  DEFB $2D,$40,$36
  DEFB $20,$40,$36
  DEFB $3D,$79,$3D
  DEFB $FF

; In-game tune: 64 notes, one per two game-loop passes
;
; Played by ResumeAfterPause (from $8B4D) while the tune is on (bit 1 of
; TuneFlags clear; the H to ENTER half row toggles it). No end marker: the
; table is used as a loop. On every pass of the game loop the counter TuneStep
; is incremented and the note is byte (TuneStep AND $7E) / 2, so each note
; lasts two passes and the whole tune 128 passes. Only the passes with the tune
; on increment the counter; the same counter also selects Willy's frame in the
; lives display (DrawLives).
;
; Each byte is a half-period count E as in TitleTune (larger = lower), here
; played for 3 x 256 inner loops (about 9 ms, a short blip every pass; the
; pitch is the half-period before doubling, no octave drop). The count actually
; used is E + 28 - 4 * lives (LivesLeft), so the tune sounds lower as lives are
; lost: observed E = $48 with 7 lives, $50 with 5 and $60 with 1 for the note
; at index $16. The melody (by computed pitch, as for the title tune) starts B4
; A#4 B4 A#4 A4 A4 F4 F4 F4 F4 A4 A#4 B4 ...; it is not named: Unknown.
GameTune:
  DEFB $56,$60,$56,$60,$66,$66,$80,$80,$80,$80,$66,$60,$56,$60,$56,$60
  DEFB $66,$60,$56,$4C,$48,$4C,$48,$4C,$56,$56,$56,$56,$56,$56,$56,$56
  DEFB $40,$40,$40,$40,$44,$44,$4C,$4C,$56,$60,$66,$60,$56,$56,$66,$66
  DEFB $51,$56,$60,$56,$51,$51,$60,$60,$40,$40,$40,$40,$40,$40,$40,$40
