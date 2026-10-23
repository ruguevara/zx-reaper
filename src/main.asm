; Unused zero bytes below the game code
;
; 75 bytes of zeroes ($5FB5-$5FFF) between the top of the BASIC area (the
; loader's CLEAR 24500 puts RAMTOP just below them) and the code at Start.
; Nothing in the game reads or writes them.
L5FB5:
  DEFS $4B

; Start the program: title screen, demo mode and the main game loop
;
; Entry point of the game (the BASIC loader calls USR 24576) and its whole
; control flow. It never returns; all the other routines are called from here,
; and the places that leave the maze jump back into it.
;
; Phases: (1) Start seeds the random pointer and switches the sound on. (2) The
; title screen at ShowTitle clears the screen, draws the block-pixel words
; HUNGRY and HORACE and the copyright and prompt texts, then loops at
; TitleLoop: each pass cycles the ink colour of the two words and plays a
; rising tone (which paces the loop, about 0.08 s), and ends after TITLE_PASSES
; passes. A key press starts a game (GameActive = 1); running out of passes
; starts the demo (GameActive = 0), in which Horace is steered by the autopilot
; and nothing is printed except the DEMO MODE banner. (3) StartGame starts a
; game or demo: first maze, score 0, three passes, slowest guard interval. (4)
; NextMaze is the next-maze entry, also reached from ExitMaze when Horace
; leaves through the exit arrows and from HoraceDies in the demo after a death:
; it picks the next of the four mazes (every fourth maze the guard interval
; gets one step faster, down to 1), draws it, prints the status line (game) or
; the banner (demo), and sets up the bell and the fruit timer. (5) RestartMaze
; places the four guards and Horace at their starting positions, shows the
; score, and clears the bell timer; HoraceDies also jumps here after a lost
; pass in a game. (6) The main loop at MainLoop.
;
; One pass of the main loop, in call order: ReadControls ReadControls (keys or
; demo autopilot, sets the requested direction); PlanMoves PlanMoves (every
; GuardInterval passes Horace and the guards choose their next positions);
; EraseSprites EraseSprites (restore the background under the sprites that are
; about to move); EatObject EatObject (score what Horace steps on); DrawGuards
; DrawGuards; CheckGuardContact (guard contact test: a lost pass via
; HoraceDies, or a guard eaten while the bell timer runs); DrawHorace
; DrawHorace; UpdateBell UpdateBell (animate the bell or let Horace take it);
; UpdateFruitDrops UpdateFruitDrops; TickGuardTimers TickGuardTimers (release
; the waiting guards); CheckSoundKey CheckSoundKey (T toggles the sound);
; PaceAndChime PaceAndChime (delay loop that sets the game speed, or the bell
; chime). The loop is left only by jumps that drop the return address: ExitMaze
; (exit arrows), HoraceDies (guard contact) and the demo abort in ReadControls.
;
; Hardware: disables interrupts (the ROM BEEPER routine used by the chime
; re-enables them); reads the ROM as a random number source; the title screen
; clears and draws the screen bitmap and attributes directly, reads every
; keyboard half-row at once on port $FE, and uses the beeper for the tone and
; the pacing.
Start:
  DI                      ; interrupts off
; Seed the random pointer: the low byte of FRAMES (with its low five bits as
; the high byte) addresses a ROM byte, and that byte, treated the same way,
; becomes RandomPtr, the pointer GetRandom walks through the ROM.
  LD A,(FRAMES)
  LD L,A
  AND ROM_HIGH_MASK
  LD H,A
  LD A,(HL)
  LD L,A
  AND ROM_HIGH_MASK
  LD H,A
  LD (RandomPtr),HL
; Sound on (mask $1F) and the T key counted as up.
  LD HL,SoundKeyState
  LD (HL),KEY_T_BIT
  LD HL,SoundMask
  LD (HL),ULA_OUT_MASK
; Title screen, also the restart point after a game or demo has ended (jumped
; to from HoraceDies). Clear the screen: attributes white on white while the
; bitmap is wiped, then white paper with black ink.
ShowTitle:
  LD HL,ATTRS
  LD DE,ATTRS+$0001
  LD BC,ATTRS_SIZE-$0001
  LD (HL),WHITE*PAPER+WHITE
  LDIR
  LD HL,SCREEN
  LD DE,SCREEN+$0001
  LD BC,SCREEN_SIZE-$0001
  LD (HL),$00
  LDIR
  LD HL,ATTRS
  LD DE,ATTRS+$0001
  LD BC,ATTRS_SIZE-$0001
  LD (HL),WHITE*PAPER+BLACK
  LDIR
; GameActive = 0 (title mode) and arm the title countdown.
  LD A,$00
  LD (GameActive),A       ; GameActive = 0 (title)
  LD HL,TITLE_PASSES
  LD (TitleCountdown),HL
; Draw the title: HUNGRY at character rows 5-9 and HORACE at rows 12-16, from
; the block-pixel pictures.
DrawTitle:
  LD DE,SCREEN+$0005*SCREEN_COLS
  LD HL,TitleHungry
  LD BC,$0005*SCREEN_COLS
  CALL DrawBlocks         ; draw HUNGRY
  LD DE,SCREEN+THIRD_SIZE+$0004*SCREEN_COLS
  LD HL,TitleHorace
  LD BC,$0005*SCREEN_COLS
  CALL DrawBlocks         ; draw HORACE
; Print the copyright line and the prompt on rows 22-23. PrintChar draws only
; while GameActive is 1, so the flag is raised for the printing and the old
; value restored.
PrintTitleText:
  LD A,(GameActive)
  PUSH AF
  LD A,$01
  LD (GameActive),A
  LD HL,SCREEN+$0002*THIRD_SIZE+$0006*SCREEN_COLS
  CALL SetAttrPointer     ; point HL' at the attribute cell
  EX DE,HL                ; DE = screen address, HL = text
  LD HL,TitleText
PrintTitleText_Loop:
  LD A,(HL)
  CP TEXT_END             ; $FF ends a text
  JR Z,Start_0
  INC HL
  CALL PrintChar          ; print one character
  JR PrintTitleText_Loop
Start_0:
  POP AF                  ; restore GameActive (0)
  LD (GameActive),A
; Title loop, one pass per rising tone: advance the ink colour (0-7, on white
; paper) of the attribute cells of both title words, HUNGRY then HORACE.
TitleLoop:
  LD HL,ATTRS+$0005*SCREEN_COLS
  LD DE,ATTRS+$0005*SCREEN_COLS+$0001
  LD BC,$0005*SCREEN_COLS-$0001
  LD A,(HL)
  INC A
  AND WHITE*PAPER+WHITE
  OR WHITE*PAPER
  LD (HL),A
  LDIR
  LD HL,ATTRS+$000C*SCREEN_COLS
  LD DE,ATTRS+$000C*SCREEN_COLS+$0001
  LD BC,$0005*SCREEN_COLS-$0001
  LD A,(HL)
  INC A
  AND WHITE*PAPER+WHITE
  OR WHITE*PAPER
  LD (HL),A
  LDIR
  CALL PlayRisingTone     ; rising tone, also the pacing
; Count down; when it reaches zero start the demo with GameActive still 0.
; Otherwise read all keyboard half-rows at once: no key pressed means loop, any
; key starts a game with GameActive = 1.
  LD HL,(TitleCountdown)
  DEC HL
  LD (TitleCountdown),HL
  LD A,H
  OR L
  JR Z,StartGame          ; countdown over: demo
  LD A,KB_ALL_ROWS
  IN A,(ULA_PORT)
  AND KEY_BITS
  CP KEY_BITS
  JR Z,TitleLoop
  LD A,$01
  LD (GameActive),A       ; key pressed: game
  JR StartGame            ; no-op jump to the next instruction
; Start a game, or the demo: no maze yet (the next one is number 0), slowest
; pace, three passes, score 0, no guards released.
StartGame:
  LD A,MAZE_NONE
  LD (MazeNumber),A
  LD A,START_GUARD_INTERVAL
  LD (GuardInterval),A
  LD A,START_PASSES
  LD (Passes),A
  LD HL,$0000
  LD (Score),HL
  LD A,$00
  LD (GuardsReleased),A
  LD (ExtraPassMark),A
  CALL ResetGuardTimers
; Next maze. Entered from ExitMaze (Horace left through the exit arrows) and
; from HoraceDies (demo, after a death). When the maze number has just passed 3
; (that is, after the fourth maze) the guard interval drops by one, to a
; minimum of 1: the game gets faster every four mazes.
NextMaze:
  LD A,(MazeNumber)
  INC A
  AND $FF-MAZE_MASK
  JR Z,AdvanceMaze        ; maze number was 0-2 or none: no speed-up
  LD A,(GuardInterval)
  DEC A
  JR NZ,Start_1
  LD A,MIN_GUARD_INTERVAL ; the interval would reach 0: stay at 1
Start_1:
  LD (GuardInterval),A
; Advance to the next maze number (0-3, wrapping).
AdvanceMaze:
  LD A,(MazeNumber)
  INC A
  AND MAZE_MASK
  LD (MazeNumber),A
; Load the maze descriptor and pick the map. Maze 0 uses the map at $72F7, maze
; 1 $6FF7, maze 2 $75F7 and maze 3 $78F7.
SelectMaze:
  LD A,(MazeNumber)
  CP $00
  JR NZ,Start_2
  LD HL,MazeDescriptor+MAZE_DESC_SIZE
  CALL LoadMazeDescriptor
  LD HL,Maze1Map
  JR DrawMazeScreen
Start_2:
  CP $01
  JR NZ,Start_3
  LD HL,MazeDescriptor+$0002*MAZE_DESC_SIZE
  CALL LoadMazeDescriptor
  LD HL,Maze2Map
  JR DrawMazeScreen
Start_3:
  CP $02
  JR NZ,Start_4
  LD HL,MazeDescriptor+$0003*MAZE_DESC_SIZE
  CALL LoadMazeDescriptor
  LD HL,Maze3Map
  JR DrawMazeScreen
Start_4:
  LD HL,MazeDescriptor+$0004*MAZE_DESC_SIZE
  CALL LoadMazeDescriptor
  LD HL,Maze4Map
  JR DrawMazeScreen
; Draw the whole maze: 24 rows of 32 cells, from the map in HL.
DrawMazeScreen:
  LD DE,SCREEN
  LD BC,SCREEN_COLS*SCREEN_ROWS
  CALL DrawMaze           ; draw the maze
; Top row: in a game print the status line PASSES / SCORE / BEST, in demo mode
; the DEMO MODE banner.
ShowTopRow:
  LD A,(GameActive)
  AND A
  JR Z,ShowDemoBanner     ; demo mode: the banner
  LD HL,SCREEN
  CALL SetAttrPointer
  EX DE,HL
  LD HL,StatusText
ShowTopRow_Loop:
  LD A,(HL)
  CP TEXT_END
  JR Z,InitMaze           ; end of the status line text
  INC HL
  CALL PrintChar
  JR ShowTopRow_Loop
; Demo: print the banner with printing enabled, then restore GameActive = 0.
ShowDemoBanner:
  LD A,$01
  LD (GameActive),A
  LD HL,SCREEN
  CALL SetAttrPointer
  EX DE,HL
  LD HL,DemoText
ShowDemoBanner_Loop:
  LD A,(HL)
  CP TEXT_END
  JR Z,Start_5            ; end of the banner text
  INC HL
  CALL PrintChar
  JR ShowDemoBanner_Loop
; Make the words DEMO MODE flash.
Start_5:
  LD A,$00
  LD (GameActive),A
  LD HL,ATTRS
  LD B,DEMO_BANNER_LEN
FlashBanner_Loop:
  LD A,(HL)
  ADD A,FLASH
  LD (HL),A
  INC HL
  DJNZ FlashBanner_Loop
; Per-maze set-up: the bell starts at the position in the maze descriptor, the
; number of passes is printed after PASSES and the fruit timer is armed.
InitMaze:
  LD HL,(MazeBellStart)
  LD (BellPos),HL
  LD HL,SCREEN+STATUS_PASSES_COL
  CALL SetAttrPointer
  LD A,(Passes)
  ADD A,CHAR_0
  EX DE,HL
  CALL PrintChar          ; print the digit of the passes (game only)
  LD HL,FRUIT_FIRST_DELAY
  LD (FruitTimer),HL
; Also entered from HoraceDies after Horace has lost a pass in a game: the maze
; stays on the screen. If the bell is still in the maze, put it back at its
; start position.
RestartMaze:
  LD HL,(BellPos)
  LD A,H
  OR L
  JR Z,PlaceGuards
  LD HL,(MazeBellStart)
  LD (BellPos),HL
; Reset the four guards (B = 4 for the first record down to 1): the position is
; the start position of released guards (descriptor +4) when the release timer
; is zero, else the start position of Horace (descriptor +6), where the waiting
; guards stand until their timers run out (checked in the simulator); the saved
; background is set to four blank cells.
PlaceGuards:
  LD B,GUARD_COUNT
PlaceGuards_Loop:
  PUSH BC
  CALL LoadGuardRecord
  POP BC
  PUSH BC
  SLA B
  LD C,B
  LD B,$00                ; BC = 2 * B
  XOR A
  LD HL,BellTimer         ; end of the four guard release timers
  SBC HL,BC               ; HL = timer of this guard (B = 4: the first)
  LD A,(HL)
  INC HL
  OR (HL)
  JR NZ,Start_6           ; timer still running: wait at Horace's start
  LD HL,(MazeGuardStart)
  JR Start_7
Start_6:
  LD HL,(MazeHoraceStart)
Start_7:
  LD (GuardRecord),HL     ; guard position and new position
  LD (GuardNewPos),HL
  LD HL,SavedBackground
  LD C,SPRITE_CELLS
Start_8:
  LD (HL),ATTR_BLANK
  INC HL
  LD B,CELL_BYTES
Start_9:
  LD (HL),$00
  INC HL
  DJNZ Start_9
  DEC C
  JR NZ,Start_8
  CALL SaveGuardRecord    ; store the record
  POP BC
  DJNZ PlaceGuards_Loop
; Horace starts at the position in descriptor +6, facing right; the step
; countdown is restarted from the guard interval.
PlaceHorace:
  LD HL,(MazeHoraceStart)
  LD (HoracePos),HL
  LD (HoraceNextPos),HL
  LD A,DIR_RIGHT
  LD (HoraceDir),A
  LD A,(GuardInterval)
  LD (StepCountdown),A
; Show the score (this also redraws the passes digit and may award the free
; pass) and the best score.
  LD HL,(Score)
  CALL ShowScore          ; HL is ignored by ShowScore
  LD HL,(BestScore)
  LD DE,SCREEN
  EX DE,HL
  LD BC,STATUS_BEST_COL
  ADD HL,BC
  EX DE,HL
  CALL PrintNumber        ; print BestScore (game only)
; No bell timer (the guards are not scared) and Horace in his normal colour.
  LD HL,$0000
  LD (BellTimer),HL
  LD A,ATTR_HORACE
  LD (HoraceAttr),A
; Main loop, see the description above.
MainLoop:
  CALL ReadControls
  CALL PlanMoves
  CALL EraseSprites
  CALL EatObject
  CALL DrawGuards
  CALL CheckGuardContact
  CALL DrawHorace
  CALL UpdateBell
  CALL UpdateFruitDrops
  CALL TickGuardTimers
  CALL CheckSoundKey
  CALL PaceAndChime
  JR MainLoop
