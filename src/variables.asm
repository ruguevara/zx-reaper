; Status line text
;
; The fixed words of the status line in the top character row (screen address
; $4000): "PASSES   SCORE       BEST" (25 characters). Printed by Start with
; PrintChar when a maze is drawn during a real game; the number of passes
; (lives), the score and the best score are then drawn into the gaps by Start
; and ShowScore with PrintNumber.
;
; Format: plain ASCII characters, terminated by $FF.
StatusText:
  DEFM "PASSES   SCORE       BEST"
  DEFB $FF

; Step countdown: passes until the next move (byte)
;
; Counts main-loop passes. PlanMoves decrements it every pass and plans the
; movement of Horace and the guards only on the pass where it reaches 0, then
; reloads it from the game pace GuardInterval, so figures advance one character
; cell every game- pace passes (8 at the start, 1 at the fastest). Start loads
; it with the game pace at the start of a maze. The loaded 9 is overwritten.
StepCountdown:
  DEFB $09

; Game pace, also the level (byte)
;
; Initial 8 (set by Start at game start), lowered by 1 each time all four mazes
; have been played (MazeNumber wraps from 3 to 0) down to a minimum of 1. Lower
; means faster and harder. It is the reload value of the step countdown
; StepCountdown (the figures move every n-th pass), the base of the guard
; release timers (ResetGuardTimers: n*256 passes), the multiplier of the bell
; timer (UpdateBell: 128*n), the length of the main-loop delay in PaceAndChime
; ($015E + $1E*n loop passes), and a dead reload in ChooseGuardMove
; (UnusedAiCounter).
GuardInterval:
  DEFB $08

; Maze number 0-3 (byte)
;
; Which of the four mazes is being played. Starts as $FF (set by Start at game
; start) so that the first increment gives 0; Start increments it modulo 4 each
; time a new maze starts (game start, exit through the right-hand arrows, or a
; death in the demo). 0 selects descriptor Maze1Desc with map Maze1Map, 1
; selects Maze2Desc with Maze2Map, 2 selects Maze3Desc with Maze3Map and 3
; selects Maze4Desc with Maze4Map (the maps are not in memory order). When it
; wraps from 3 to 0 the game pace GuardInterval is lowered.
MazeNumber:
  DEFB $FF

; Dead counter of the guard AI (byte)
;
; Dead state, verified: ChooseGuardMove reads it at $645E, decrements it when
; scoring direction 3 (left) and stores it back, and reloads it with the game
; pace GuardInterval when scoring direction 0 (up), but nothing ever uses the
; value (the register it is read into is overwritten at once and no flag from
; it is tested; no other code touches $7C64). The watch in the simulator shows
; it counting down from 8 to 1 and reloading, without effect. The loaded value
; 1 is arbitrary. Probably a leftover of an earlier version of the AI.
UnusedAiCounter:
  DEFB $01

; Bonus fruit timer (word)
;
; Countdown to the next bonus fruit. Start sets it to 2000 ($07D0) when a maze
; starts; MaybeDropFruit decrements it once per call, that is once per pass for
; each released guard that is not waiting and has no red cell in its saved
; background (so it runs faster with more guards out). When it reaches 0 it is
; re-armed with 800 plus a random 0-1023 and a fruit is planted under the
; guard.
FruitTimer:
  DEFW $0000

; Random pointer into the ROM (word)
;
; The address, kept within $0000-$1FFF, of the next ROM byte that GetRandom
; (GetRandom) returns; the pointer is advanced by one and wrapped at every
; call. Start seeds it at start-up from FRAMES ($5C78): the ROM byte at address
; (F AND $1F)*256 + F, F = low byte of FRAMES, gives A; the pointer becomes (A
; AND $1F)*256 + A. The loaded 0 is overwritten.
RandomPtr:
  DEFW $0000

; Sound mask (byte)
;
; $1F = sound on, $07 = sound off. Every routine that makes a noise ANDs the
; value it writes to port $FE with this mask: $07 leaves only the border colour
; (white) and drops the speaker bit 4. Initial $1F (set by Start); flipped by
; CheckSoundKey when the T key is pressed (XOR $18). Used by PlanMoves,
; ShowScore, CheckGuardContact, HoraceDies, PaceAndChime and PlayRisingTone.
SoundMask:
  DEFB $1F

; Previous state of the T key
;
; Bit 4 of the last Q-T half-row read: $10 = up, 0 = down. CheckSoundKey
; toggles the sound (SoundMask) on a key-down edge. Set to $10 by Start at
; start-up; read and written only by CheckSoundKey.
SoundKeyState:
  DEFB $10

; Horace's current position (word)
;
; Where Horace is drawn now. Positions are screen offsets: the screen address
; minus $4000 of the top-left cell of the 2x2-cell sprite, with the pixel row
; bits 0, i.e. %000TT000 RRRCCCCC with TT the screen third, RRR the character
; row in the third and CCCCC the column (row 8*TT+RRR, column CCCCC, 24 rows by
; 32 columns). Set to Horace's start position (MazeHoraceStart) when a maze
; starts or after a life is lost (Start); DrawHorace makes it equal to the next
; position HoraceNextPos whenever it draws him (or, while he is frozen after a
; wrap pad, without drawing). Read by the control code (ReadControls), the
; planner (PlanMoves), the guard AI (ChooseGuardMove: chase), the eraser
; (EraseSprites), the bell (UpdateBell) and the death sequence (HoraceDies).
; The loaded value is a placeholder.
HoracePos:
  DEFW $014C

; Horace's next position (word)
;
; Where Horace is going to be drawn on this pass. Same encoding as the current
; position HoracePos. PlanMoves (PlanMoves) sets it one cell on from the
; current position in the current direction, or leaves it equal to the current
; position if the way is blocked or the step is not due yet, or sets it across
; the vertical wrap for a wrap pad. EraseSprites erases Horace when it differs
; from HoracePos, EatObject scores what is at this position, CheckGuardContact
; checks it for a guard and DrawHorace draws him there. The loaded value is a
; placeholder.
HoraceNextPos:
  DEFW $014C

; Requested direction: key pressed, $FF if none (byte)
;
; Direction code the player asks for: 0 up, 1 right, 2 down, 3 left (DIR_*),
; $FF (DIR_NONE) for none. ReadControls sets it to $FF on every pass, then to
; the code of the key found (Q/4 up, Z/3 down, P/2 right, I/1 left), and back
; to $FF if ProbeMove reports a wall in that direction; a valid request is
; copied to the current direction HoraceDir at once. The demo autopilot never
; sets it. Only ReadControls uses it.
RequestedDir:
  DEFB $FF

; Horace's current direction (byte)
;
; Direction code 0 up, 1 right, 2 down, 3 left (DIR_*) in which Horace walks.
; Start sets it to 1 (right) when a maze starts or a life is lost; ReadControls
; changes it (keys or demo autopilot); PlanMoves moves him one cell in that
; direction on every step; DrawHorace uses it to select his sprite.
HoraceDir:
  DEFB $01

; Horace's attribute (byte)
;
; The attribute byte (white paper, ink 1 = blue: $39, ATTR_*) with which Horace
; is drawn by DrawHorace; it is also the colour that identifies him on the
; screen. Start and HoraceDies set it to $39; during the death animation
; HoraceDies cycles it through $38-$3F.
HoraceAttr:
  DEFB $39

; Horace's animation counter (byte)
;
; Incremented by DrawHorace (entry DrawHorace_Sprite) each time Horace is
; drawn, including the death sequence. Bit 4 chooses between the two walking
; frames (HoraceSprites when set, HoraceSprites2 when clear), so the frame
; changes every 16 draws. Never reset; starts at 0.
HoraceAnim:
  DEFB $00

; Score (word)
;
; The score as a 16-bit binary number (not BCD), shown as five digits on the
; status line by ShowScore and PrintNumber. Cleared by Start at the start of a
; game; raised by EatObject (flower +10, bell or fruit +50), CheckGuardContact
; (guard +100) and UpdateBell (bell +60 and +150). There is no cap: it wraps at
; 65536. At game over it replaces the best score BestScore if it is not lower.
Score:
  DEFW $0000

; Best score (word)
;
; The highest score of a real game since the program was loaded, binary like
; Score. Printed on the status line when a maze starts (Start); replaced in
; HoraceDies at game over if the score is not lower, but only in a real game
; (GameActive non-zero). Starts at 0 and is not cleared when a new game begins.
BestScore:
  DEFW $0000

; Score of the last extra pass (byte)
;
; Score divided by 10000, plus 2 (the counting loop in ShowScore starts at 1
; and adds one more), as it was the last time the score was shown. ShowScore
; compares it with the new value: when they differ the number of passes Passes
; goes up by one (an extra pass for every 10000 points) and the digit on the
; status line is reprinted. Cleared by Start at the start of a game, so the
; first call finds 2 and gives a free pass.
ExtraPassMark:
  DEFB $00

; Passes left, Horace's lives (byte)
;
; The "PASSES" counter of the status line: number of lives, as a binary number
; printed as one digit. Set to 3 by Start at the start of a game; the first
; score update then adds a free pass (see ExtraPassMark), so a game starts with
; 4. HoraceDies decrements it when Horace is caught; at 0 the game is over.
; ShowScore increments it for every 10000 points (no upper limit).
Passes:
  DEFB $00

; Wrap pause counter (byte)
;
; Set to 90 (WRAP_PAUSE) by PlanMoves when Horace walks onto a wrap pad at the
; top or bottom of the maze and is moved to the opposite edge; counted down
; once per pass by DrawHorace. While it is non-zero Horace is invisible and
; frozen: ReadControls reads no keys, PlanMoves does not plan him, EatObject
; scores nothing and DrawHorace only copies the next position to the current
; one. Cleared by HoraceDies when he dies; otherwise 0.
WrapPause:
  DEFB $00

; Horace's cell during the guard AI: L = column, H = row (word)
;
; Scratch word of ChooseGuardMove (ChooseGuardMove), written once per planned
; guard: Horace's position HoracePos converted from a screen offset to
; character-cell coordinates, low byte (+0) the column 0-31, high byte (+1) the
; row 0-23. Compared with the guard's cell GuardCell to decide which directions
; lead towards him. Not used elsewhere.
HoraceCell:
  DEFW $0000

; Bonus fruit A graphic (4 saved-background cells)
;
; One of the two shapes of the bonus fruit, a stalk with a leaf above a single
; round body (a cherry or apple). A 16x16 picture of 2x2 character cells in the
; same format as the saved background of a guard record (6DEA): four cells of 9
; bytes each in the order top-left, top-right, bottom-left, bottom-right, every
; cell being its attribute byte (the top two cells are green, ATTR_FLOWER; the
; bottom two red, ATTR_BELL) followed by its 8 pixel rows.
;
; MaybeDropFruit (MaybeDropFruit) copies it over the saved background of a
; guard record, so that the fruit appears on the floor where the guard stood
; once the guard walks on; it picks FruitCellsA or FruitCellsB at random.
; Horace scores 50 points for eating it.
FruitCellsA:
  DEFB $3C,$00,$00,$01,$01,$02,$02,$02,$01 ; top-left (green): attribute, then
                                           ; 8 pixel rows
  DEFB $3C,$60,$C0,$E0,$60,$20,$00,$00,$00 ; top-right (green): attribute, then
                                           ; 8 pixel rows
  DEFB $3A,$06,$0E,$0F,$0F,$07,$03,$00,$00 ; bottom-left (red): attribute, then
                                           ; 8 pixel rows
  DEFB $3A,$C0,$E0,$E0,$E0,$C0,$80,$00,$00 ; bottom-right (red): attribute,
                                           ; then 8 pixel rows

; Bonus fruit B graphic (4 saved-background cells)
;
; One of the two shapes of the bonus fruit, two round bodies on crossed stalks
; (a pair of cherries). A 16x16 picture of 2x2 character cells in the same
; format as the saved background of a guard record (6DEA): four cells of 9
; bytes each in the order top-left, top-right, bottom-left, bottom-right, every
; cell being its attribute byte (the top two cells are green, ATTR_FLOWER; the
; bottom two red, ATTR_BELL) followed by its 8 pixel rows.
;
; MaybeDropFruit (MaybeDropFruit) copies it over the saved background of a
; guard record, so that the fruit appears on the floor where the guard stood
; once the guard walks on; it picks FruitCellsA or FruitCellsB at random.
; Horace scores 50 points for eating it.
FruitCellsB:
  DEFB $3C,$00,$00,$00,$00,$10,$1C,$0E,$03 ; top-left (green): attribute, then
                                           ; 8 pixel rows
  DEFB $3C,$00,$00,$00,$00,$00,$38,$F0,$C0 ; top-right (green): attribute, then
                                           ; 8 pixel rows
  DEFB $3A,$1E,$17,$1D,$1F,$0D,$07,$03,$00 ; bottom-left (red): attribute, then
                                           ; 8 pixel rows
  DEFB $3A,$78,$E8,$78,$D8,$F0,$60,$C0,$00 ; bottom-right (red): attribute,
                                           ; then 8 pixel rows

; Bell position (word)
;
; Screen offset (address minus $4000) of the top-left cell of the bell's 2x2
; sprite, or 0 when there is no bell. Start loads it from the bell position of
; the maze descriptor (MazeBellStart) when a maze starts; after a life is lost
; it is reloaded only if it is not 0, so a bell that was already taken stays
; gone. UpdateBell animates the bell at this position every pass and sets the
; word to 0 when Horace picks it up; PaceAndChime rings the chime while it is
; non-zero.
BellPos:
  DEFW $00FC

; Bell animation counter (byte)
;
; Incremented on every pass by UpdateBell while the bell is lying in the maze.
; Bits 3-5 select the animation frame at BellSprites (a new step every 8
; passes, running 0-3 and back 3-0); PaceAndChime rings the chime when its low
; six bits are 0 or $20. Never reset; starts at 0.
BellTick:
  DEFB $00
