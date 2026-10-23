; Check whether Horace has met a guard
;
; Called once per pass of the main loop at Start, after the guards have been
; drawn (DrawGuards) and before Horace is drawn at his new place (DrawHorace).
; The 2x2 block where Horace is about to be (HoraceNextPos) is searched with
; GetBlockObject for the guard's attribute (ATTR_GUARD); nothing found: return.
; The test is on the attribute cells of the screen, so any overlap of Horace's
; block and a guard's block counts.
;
; Bell timer (BellTimer) zero: the guard wins. Control passes to HoraceDies
; (Horace dies), which drops this routine's return address and never comes
; back.
;
; Bell timer running: Horace eats the guard. SCORE_GUARD points are added and
; shown (ShowScore), the bell timer is cleared (so the guards are dangerous
; again at once), a falling buzz is played, and then every guard that is out in
; the maze is sent back to the cell where the guards wait at the start of a
; maze (word at $6FD5, which is also Horace's start cell), where it waits
; GUARD_WAIT passes before it is drawn again. The guard that was touched is not
; singled out: all released guards go home. The loop that does this ends in
; L672F, which is code, not a table.
;
; Hardware: reads the attribute area; writes the screen through ShowScore,
; EraseGuard_Always and SaveBackground; plays the buzz by writing port $FE
; (speaker bit and white border) with busy-wait loops, about 0.25 s, silent
; when the sound mask (SoundMask) has been toggled off.
CheckGuardContact:
  LD HL,(HoraceNextPos)   ; where Horace is about to be
  CALL GetBlockObject
  CP ATTR_GUARD
  RET NZ                  ; no guard there
  LD HL,(BellTimer)       ; bell timer
  LD A,H
  OR L
  JP Z,HoraceDies         ; not running: Horace dies
  LD HL,(Score)
  LD BC,SCORE_GUARD       ; guard eaten
  ADD HL,BC
  LD (Score),HL
  CALL ShowScore
  LD HL,$0000             ; end of the bell effect
  LD (BellTimer),HL
  LD HL,SoundMask         ; sound mask
  LD C,EATEN_TONE_STEPS   ; step number, 15 down to 1
; The falling buzz: 15 steps of 8 square-wave cycles. Half period = 8 * (15 -
; C) loop passes, so the first step is 0, which DJNZ turns into 256 passes (an
; accident: a long first note), and the others grow from 8 to 112, so the pitch
; falls. A pass is not a plain DJNZ but a read and write of (IX+0), 51 T-states
; long.
CheckGuardContact_Tone:
  PUSH BC
  LD A,C
  XOR EATEN_TONE_STEPS    ; B = 15 - C
  LD B,A
  SLA B                   ; x 8
  SLA B
  SLA B
  LD E,B                  ; E = half period
  LD D,EATEN_TONE_CYCLES  ; cycles in this step
CheckGuardContact_Cycle:
  LD B,E                  ; speaker half
  LD A,ULA_OUT_MASK
  AND (HL)                ; speaker on unless muted
  OUT (ULA_PORT),A
CheckGuardContact_0:
  LD A,(IX+$00)           ; delay: IX is left in the tile graphics by DrawMaze;
                          ; the byte is written back unchanged
  LD (IX+$00),A
  DJNZ CheckGuardContact_0
  LD A,WHITE              ; speaker off, white border
  OUT (ULA_PORT),A
  LD B,E
CheckGuardContact_1:
  LD A,(IX+$00)
  LD (IX+$00),A
  DJNZ CheckGuardContact_1
  DEC D
  JR NZ,CheckGuardContact_Cycle
  POP BC
  DEC C
  JR NZ,CheckGuardContact_Tone
; Send every released guard home. Guard B (4 = first record, see
; LoadGuardRecord) is released when its timer is zero.
  LD HL,GuardTimers       ; guard release timers (words)
  LD B,GUARD_COUNT
; BUG: HL advances by one byte per guard, not by one timer word: the two bytes
; tested for guard k (0-3) are at GuardTimers+k and +k+1, not at +2k. Every
; released guard is still found (its timer is zero, and so are the timers of
; the guards before it), but a guard that is still waiting can be sent home
; too, e.g. the second one while the low byte of its timer is zero (its test
; reads the high byte of the first timer and the low byte of the second; seen
; in the simulator). No visible harm: the record only gets its start cell and
; the GUARD_WAIT.
CheckGuardContact_Reset:
  PUSH BC
  LD A,(HL)               ; timer word of this guard, low byte
  INC HL
  OR (HL)                 ; Z: timer is zero, the guard is out in the maze
  PUSH HL                 ; HL is one byte further on, see above
  JR NZ,CheckGuardContact_Next ; still waiting: leave it alone
  CALL LoadGuardRecord    ; B = 4...1 selects the record
  CALL EraseGuard_Always  ; wipe the guard from the screen
; The next three instructions have no effect: the block at Horace's next
; position is searched for the guard attribute but the flags are never tested
; (the JR at $672D is unconditional).
  LD HL,(HoraceNextPos)
  CALL GetBlockObject
  CP ATTR_GUARD
  LD HL,(MazeHoraceStart) ; cell where the guards wait at the start of a maze
  LD (GuardRecord),HL     ; position
  LD (GuardNewPos),HL     ; and next position
  CALL SaveBackground     ; save the background under the guard at its new
                          ; place
  LD A,DIR_RIGHT          ; facing right
  LD (GuardDir),A
  LD A,GUARD_WAIT
  LD (GuardWait),A        ; wait before it is drawn again
  JR CheckGuardContact_Store ; skips the dead CALL at $672F

; Tail of the guard loop of the routine at 66A4
;
; These 11 bytes are code, although they look like a small table: the end of
; the loop in CheckGuardContact that sends the released guards home when Horace
; eats one. The loop enters at $6732 by the JR at $672D, and the first
; instruction (CALL DrawGuard, DrawGuard) is skipped by it, so it can never run
; (dead code, perhaps left over from an earlier version of the loop that redrew
; the guard at once).
;
; $6732 stores the working guard record (SaveGuardRecord). $6735 restores the
; registers pushed at $6702 and $6706 (the guard counter and the pointer to the
; timers, which has advanced one byte, see CheckGuardContact), and loops for
; the next of the four guards. After the last one RET returns to the main loop
; at Start.
;
; B Guards left, 4 down to 1
L672F:
  CALL DrawGuard          ; dead: the JR at $672D jumps over it
CheckGuardContact_Store:
  CALL SaveGuardRecord    ; write the record back
CheckGuardContact_Next:
  POP HL                  ; pointer into the timers
  POP BC                  ; guard counter
  DJNZ CheckGuardContact_Reset ; next guard
  RET                     ; to the main loop

; Horace dies: death animation, one pass less, then retry, next demo maze or
; game over
;
; Entered by JP from CheckGuardContact when Horace touches a guard while the
; bell timer is zero; the return address of that call (into the main loop at
; Start) is still on the stack. The passes counter (Passes) goes down by one
; and its digit on the status line is redrawn (nothing is printed in the demo,
; see PrintChar), and the wrap pause (WrapPause) is cleared. Then 45 colour
; steps (DEATH_FLASHES): each draws Horace again with the next ink colour on
; white paper (HoraceAttr, through DrawHorace_Sprite, which also steps his
; walking animation), paints the label cells "PASSES" on the status line in the
; same colour, and plays 20 cycles of noise whose high and low halves have
; random lengths (random bytes from GetRandom), about one second in all.
; Afterwards the label colour is restored, the guards that are out in the maze
; are wiped from the screen (EraseGuard_Always) and Horace is wiped with the
; blank sprite. The records of the unreleased guards are left alone: they were
; never drawn.
;
; With no passes left the game is over (GameOver). Otherwise the return address
; is dropped, the guard release timers are started again (ResetGuardTimers) and
; the next try starts: in a real game (GameActive non-zero) at RestartMaze, the
; same maze with the flowers eaten so far, the guards and Horace back at their
; start cells; in the demo at NextMaze, the next maze (the maze number and the
; pace advance).
;
; Hardware: writes the screen bitmap and attributes (the status line, Horace's
; sprite) and the speaker and border through port $FE with busy-wait loops
; (silent when the sound mask SoundMask is toggled off); the noise is paced by
; random ROM bytes.
HoraceDies:
  LD A,(Passes)           ; one pass less
  DEC A
  LD (Passes),A
  XOR A                   ; Horace is no longer in the wrap pause
  LD (WrapPause),A
; BUG? The working guard record is reloaded before it is used again, so this
; store has no effect.
  LD (GuardWait),A        ; GuardWait
  LD HL,SCREEN+STATUS_PASSES_COL ; digit of the passes counter
  CALL SetAttrPointer
  LD A,(Passes)
  ADD A,CHAR_0
  EX DE,HL                ; DE = its cell
  CALL PrintChar
  LD B,DEATH_FLASHES
HoraceDies_Flash:
  PUSH BC
  LD A,(HoraceAttr)       ; Horace's attribute: next ink, white paper
  INC A
  AND INK_MASK
  OR WHITE*PAPER
  LD (HoraceAttr),A
  PUSH AF
  CALL DrawHorace_Sprite  ; draw Horace in the new colour
  LD HL,ATTRS             ; the cells of "PASSES" and its digit get it too
  LD B,PASSES_LABEL_CELLS
  POP AF
HoraceDies_Fill:
  LD (HL),A
  INC HL
  DJNZ HoraceDies_Fill
  LD C,DEATH_NOISE_CYCLES
HoraceDies_Noise:
  LD A,ULA_OUT_MASK       ; speaker on (unless muted) ...
  LD HL,SoundMask
  AND (HL)
  OUT (ULA_PORT),A
  CALL GetRandom          ; ... for a random time of at least 64 loop passes
  OR NOISE_MIN_DELAY
  LD B,A
HoraceDies_0:
  DJNZ HoraceDies_0
  LD A,WHITE              ; speaker off, white border, for another random time
  OUT (ULA_PORT),A
  CALL GetRandom
  OR NOISE_MIN_DELAY
  LD B,A
HoraceDies_1:
  DJNZ HoraceDies_1
  DEC C
  JR NZ,HoraceDies_Noise
  POP BC
  DJNZ HoraceDies_Flash
  LD A,WHITE*PAPER+BLACK  ; restore the label colour: one cell fewer than was
                          ; painted (the last one is a blank)
  LD HL,ATTRS
  LD B,PASSES_LABEL_CELLS-$01
HoraceDies_2:
  LD (HL),A
  INC HL
  DJNZ HoraceDies_2
  LD A,ATTR_HORACE        ; Horace's normal attribute
  LD (HoraceAttr),A
; Wipe the guards that are out in the maze (timer zero) from the screen. B
; counts 1, 2, 3, 4 (record 4 down to 1 for LoadGuardRecord) and HL steps back
; one timer word at a time, from the last one.
  LD HL,GuardTimers+$0006 ; last guard's timer
  LD B,$01                ; B = 1
HoraceDies_Erase:
  PUSH BC
  LD A,(HL)
  INC HL
  OR (HL)                 ; Z: timer is zero
  DEC HL
  DEC HL
  DEC HL
  PUSH HL
  JR NZ,HoraceDies_Next   ; waiting guards were never drawn
  CALL LoadGuardRecord    ; record B into the working buffer
  CALL EraseGuard_Always  ; wipe it
  CALL SaveGuardRecord    ; save the buffer back
HoraceDies_Next:
  POP HL
  POP BC
  INC B
  LD A,B
  CP GUARD_COUNT+$01
  JR NZ,HoraceDies_Erase
  LD HL,(HoracePos)       ; Horace's position
  LD DE,BlankSprite       ; blank sprite
  CALL SetAttrPointer
  LD C,ATTR_BLANK
  CALL DrawSprite         ; wipe Horace from the screen
  LD A,(Passes)           ; passes left
  AND A
  JR Z,GameOver           ; none: game over
  POP HL                  ; drop the return address into the main loop (see the
                          ; start of this routine)
  CALL ResetGuardTimers   ; the guards start waiting again
  LD A,(GameActive)       ; 1 = real game, 0 = demo
  AND A
  JP NZ,RestartMaze       ; real game: try again in the same maze
  JP NextMaze             ; demo: go on in the next maze
; Game over, and restart of the title screen. Reached from HoraceDies when the
; last pass is lost (the return address of the call of CheckGuardContact is
; still on the stack), and by the demo abort in ReadControls (any key during
; the demo). The whole attribute area is flooded GAME_OVER_FLASHES times with a
; new ink colour on white paper (ink = loop counter mod 8), each time with a
; rising tone (PlayRisingTone), which also paces the loop. The POP HL then
; drops the return address of the death path; a real game (GameActive non-zero)
; keeps the best score if the score is at least as high (BestScore), and the
; title screen is restarted at ShowTitle. The score is reset by the start of
; the next game. Hardware: writes the attribute area and the speaker and border
; (through PlayRisingTone).
;
; Stack quirk: ReadControls has already popped its own return address when it
; jumps here for the demo abort, so there the POP HL at $6803 removes a word
; that belongs to no call and the stack pointer rises by two on every abort
; (measured in the simulator: $5F9D at the main loop, $5F9F after the first
; abort, ...). From the 63rd abort without a reset the stack pushes overwrite
; the title code from $601A and the 70th abort crashes. The death path is
; balanced. A fix: skip the POP HL for the demo, or make ReadControls jump here
; without dropping its return address.
GameOver:
  LD B,GAME_OVER_FLASHES  ; screen colour steps
GameOver_Flash:
  PUSH BC
  CALL PlayRisingTone     ; the tone; it preserves B
  LD HL,ATTRS
  LD DE,ATTRS+$0001
  LD A,B                  ; ink = B mod 8, white paper
  AND INK_MASK
  ADD A,WHITE*PAPER
  LD (HL),A
  LD BC,ATTRS_SIZE-$0001  ; flood the attribute area
  LDIR
  POP BC
  DJNZ GameOver_Flash
  POP HL                  ; see the quirk above
  LD A,(GameActive)       ; demo: no best score
  AND A
  JP Z,ShowTitle          ; title screen
  LD HL,(Score)           ; Score, BestScore: new best if Score >= BestScore
  LD BC,(BestScore)
  XOR A
  SBC HL,BC
  JP C,ShowTitle          ; lower: keep the old best
  LD HL,(Score)
  LD (BestScore),HL
  JP ShowTitle            ; title screen

; Draw Horace
;
; Last part of the per-frame sprite update (after EraseSprites and DrawGuards).
; While the countdown in WrapPause is non-zero (Horace is crossing the vertical
; wrap, see PlanMoves) the countdown is decremented, Horace's current position
; (HoracePos) is set to the next one (HoraceNextPos) and nothing is drawn.
; Otherwise Horace is drawn at the next position (which becomes the current
; one). The entry at DrawHorace_Sprite skips the countdown test (the death
; sequence of HoraceDies uses it). The animation counter HoraceAnim is
; incremented on each draw; its bit 4 selects the set of four sprites at
; HoraceSprites (set) or HoraceSprites2 (clear), the direction in HoraceDir
; (0-3) selects the sprite in the set (32 bytes each) and HoraceAttr is the
; attribute (normally $39; the death sequence of HoraceDies cycles it).
; Hardware: writes the screen bitmap and four attribute cells (through
; DrawSprite).
DrawHorace:
  LD A,(WrapPause)        ; wrap countdown
  AND A
  JR Z,DrawHorace_Sprite
  DEC A
  LD (WrapPause),A
  LD HL,(HoraceNextPos)
  LD (HoracePos),HL
  RET
; This entry point is used by the routine at HoraceDies.
DrawHorace_Sprite:
  LD A,(HoraceAnim)
  INC A
  LD (HoraceAnim),A
  AND HORACE_FRAME_BIT
  CP $00
  JR NZ,DrawHorace_0
  LD HL,HoraceSprites2    ; second set, direction 0
  JR DrawHorace_1
DrawHorace_0:
  LD HL,HoraceSprites     ; first set, direction 0
; Direction * 32 (RLC five times) is the offset of the direction's sprite.
DrawHorace_1:
  LD A,(HoraceDir)
  RLC A
  RLC A
  RLC A
  RLC A
  RLC A
  LD B,$00
  LD C,A
  ADD HL,BC
  EX DE,HL                ; DE = sprite
  LD HL,(HoraceNextPos)
  LD (HoracePos),HL       ; next position becomes current
  CALL SetAttrPointer
  LD A,(HoraceAttr)       ; attribute
  LD C,A
  CALL DrawSprite
  RET

; Animate the bell, or let Horace pick it up
;
; Called once per pass of the main loop at Start, after Horace has been drawn
; at his new position (so $7C6B, his position, is already the position he has
; just moved to). Does nothing when there is no bell in the maze (the bell
; position BellPos is 0: before the bell is taken it holds the bell position
; from the maze descriptor, afterwards 0 until the next maze).
;
; Pick-up test: d = Horace's position minus the bell's position (both screen
;         offsets of the top-left cell of a 2x2
; block). Horace takes the bell when d is 0 (same place), -1 or +1 (a cell left
;         or right), -32 (a cell above) or +33
; a cell below and a cell to the right . The other overlapping offsets (+32,
;                                      +31, -31, -33) are not tested.
; While the bell is not taken it is redrawn every pass as a 16x16 sprite in the
;       colour ATTR_BELL, using one of the
; four frames at $7F07 (32 bytes each). The animation counter BellTick is
;      incremented on every pass; its bits 3-5
; count 0-7 every 8 passes, mirrored into the frame sequence 0, 1, 2, 3, 3, 2,
;       1, 0.
;
; Taking the bell (TakeBell, never reached in the coverage maps, read from the
; code and confirmed in the simulator): the bell position is cleared and the
; bell erased with the blank sprite at $7F87, Horace is redrawn on top of it by
; DrawHorace, and the score is raised by SCORE_BELL_PICKUP and then
; SCORE_BELL_BONUS, each time through ShowScore (which also chirps). Together
; with SCORE_ITEM already given by EatObject for the bell attribute that is 260
; points. The bell timer at $6DAE is set to 128 * the game pace ($7C62), so
; that the guards stay edible for that long (the timer is counted down
; elsewhere; a non-zero value makes CheckGuardContact treat touching a guard as
; eating it). The routine also tries to turn round one guard (adds 2 to the
; direction of the record in the working buffer GuardRecord), but the buffer is
; not saved and the next LoadGuardRecord overwrites it: in the simulator $6DBA
; went 3, 1 and back to 3 on the next pass. This turn-round has no effect.
; Hardware: writes the screen bitmap and attributes (the bell sprite); the
; score update chirps through port $FE.
UpdateBell:
  LD HL,(HoracePos)       ; Horace
  LD BC,(BellPos)         ; bell
  LD A,B
  OR C
  RET Z                   ; no bell
  AND A
  SBC HL,BC               ; d = Horace - bell
  LD A,H
  OR L
  JR Z,TakeBell           ; d = 0
  INC HL
  LD A,H
  OR L
  JR Z,TakeBell           ; d = -1
  DEC HL
  DEC HL
  LD A,H
  OR L
  JR Z,TakeBell           ; d = +1
  LD BC,SCREEN_COLS+$0001
  ADD HL,BC
  LD A,H
  OR L
  JR Z,TakeBell           ; d = -32
  XOR A
  LD BC,$0002*SCREEN_COLS+$0001
  SBC HL,BC
  LD A,H
  OR L
  JR Z,TakeBell           ; d = +33
; Not taken: advance the animation and redraw the bell.
  LD HL,(BellPos)
  LD A,(BellTick)
  INC A
  LD (BellTick),A
  AND BELL_FRAME_BITS     ; step 0-7 (times 8)
  CP BELL_MIRROR_LIMIT
  JR C,UpdateBell_0
  XOR BELL_FRAME_BITS     ; second half: 4-7 become 3-0
UpdateBell_0:
  RLCA                    ; frame * 8 * 4 = frame * SPRITE_BYTES
  RLCA
  LD C,A
  LD B,$00
  LD DE,BellSprites       ; first bell frame
  EX DE,HL
  ADD HL,BC
  EX DE,HL                ; DE = frame graphic, HL = bell position
  CALL SetAttrPointer
  LD C,ATTR_BELL
  CALL DrawSprite
  RET
; Horace takes the bell.
TakeBell:
  LD HL,$0000
  LD (BellPos),HL         ; bell gone
  LD DE,BlankSprite       ; blank sprite
  LD HL,(MazeBellStart)   ; the bell's place in the maze descriptor (what
                          ; BellPos held)
  CALL SetAttrPointer
  LD C,ATTR_BLANK
  CALL DrawSprite         ; erase the bell
  CALL DrawHorace         ; draw Horace again over the spot
  LD HL,(Score)
  LD BC,SCORE_BELL_PICKUP
  ADD HL,BC
  LD (Score),HL
  CALL ShowScore
  LD A,(GuardInterval)    ; game pace (8 at the start, 1 at the fastest)
  LD L,$00
  LD H,A
  SRA H
  RR L                    ; HL = pace * 128
  LD (BellTimer),HL       ; start the bell timer: guards can be eaten
  LD A,(GuardDir)         ; direction of the guard record in the working buffer
  ADD A,DIR_OPPOSITE
  AND DIR_MASK
  LD (GuardDir),A         ; turn it round (lost, see the description)
  LD HL,(Score)
  LD BC,SCORE_BELL_BONUS
  ADD HL,BC
  LD (Score),HL
  CALL ShowScore
  RET

; Give every released guard a chance to drop a fruit
;
; Called once per pass of the main loop at Start. Walks the four guard timers
; (GuardTimers) with B = 4, 3, 2, 1; for each guard whose timer is zero
; (released) it loads the guard's record into the working buffer, runs the
; fruit logic of MaybeDropFruit on it and writes the record back. The sibling
; routine DrawGuards does the same walk to move the guards. Hardware: none.
UpdateFruitDrops:
  LD HL,GuardTimers
  LD B,GUARD_COUNT
UpdateFruitDrops_0:
  PUSH BC                 ; B = guard number (4 = first record)
  LD A,(HL)
  INC HL
  OR (HL)
  INC HL
  PUSH HL                 ; HL = next timer
  JR NZ,UpdateFruitDrops_1 ; timer still running: guard not released yet
  CALL LoadGuardRecord
  CALL MaybeDropFruit
  CALL SaveGuardRecord
UpdateFruitDrops_1:
  POP HL
  POP BC
  DJNZ UpdateFruitDrops_0
  RET

; Plant a bonus fruit under a guard when the fruit timer runs out
;
; Works on the guard record in the working buffer (GuardRecord), which
; UpdateFruitDrops has loaded for a released guard. A fruit is a 16x16 sprite
; of four cells (attribute + 8 pixel rows each, 9 bytes per cell, like the
; saved background): a green stalk above a red body, cherry-like; the two
; shapes are in FruitCellsA and FruitCellsB. Instead of drawing it, the routine
; overwrites the guard's saved background (SavedBackground, the four cells
; under the guard) with the fruit. When the guard walks on, EraseGuard restores
; that background, so the fruit is left lying on the floor where the guard
; stood. Horace scores 50 points for it (EatObject: a red cell is any object
; but a flower, worth 10).
;
;          Nothing happens while the guard is waiting (GuardWait is not zero:
;                  CheckGuardContact sets it to 90 when Horace, after
;          picking up the bell, touches a guard and the guards are sent back to
;                  their start position; DrawGuard counts it
;          down) or while the saved background already holds a red cell (the
;                bell, or a fruit). Otherwise the word at
;          #R$7C65 is counted down once per call; at zero it is re-armed with
;                  800 plus a random 0-1023 and one of the two
;          fruit shapes (chosen at random) is planted. The timer is first set
;                to 2000 by Start when a maze starts.
; Hardware: none.
;
; O:HL Corrupted
MaybeDropFruit:
  LD A,(GuardWait)
  AND A
  RET NZ                  ; guard is paused
  LD E,SPRITE_CELLS       ; look at the four saved cells
  LD HL,SavedBackground
MaybeDropFruit_0:
  LD A,(HL)               ; attribute of the cell
  CP ATTR_BELL            ; red: the bell or a fruit is already there
  RET Z
  LD BC,SAVED_CELL_SIZE
  ADD HL,BC
  DEC E
  JR NZ,MaybeDropFruit_0
  LD HL,(FruitTimer)
  DEC HL
  LD (FruitTimer),HL
  LD A,H
  OR L
  RET NZ                  ; timer still running
  CALL GetRandom          ; L = random byte
  LD L,A
  PUSH HL
  CALL GetRandom
  POP HL
  AND FRUIT_DELAY_MASK    ; H = random 0-3, so HL = random 0-1023
  LD H,A
  LD BC,FRUIT_MIN_DELAY
  ADD HL,BC
  LD (FruitTimer),HL      ; next fruit in 800-1823 calls
  CALL GetRandom
  AND $01                 ; pick one of the two shapes
  JR NZ,MaybeDropFruit_1
  LD HL,FruitCellsA
  JR MaybeDropFruit_2
MaybeDropFruit_1:
  LD HL,FruitCellsB
MaybeDropFruit_2:
  LD DE,SavedBackground
  LD BC,SPRITE_CELLS*SAVED_CELL_SIZE ; 4 cells of 9 bytes
  LDIR
  RET

; Count down the guards' release timers
;
; Called once per pass of the main loop at Start. The four 16-bit words at
; GuardTimers are the guards' release timers: a guard whose timer is zero is
; out in the maze and is processed by DrawGuards and UpdateFruitDrops. This
; routine decrements every timer that is not yet zero, so each waiting guard is
; released in turn.
;
;          When a timer's high byte is zero and register C is zero,
;               GuardsReleased is incremented. C is not set here: it is
;          left over from UpdateBell, which returns C=$3A while the bell is in
;               the maze and C=0 after the bell has been
;          taken. So the byte only counts once the bell is gone, and then it
;                 counts every tick of every timer below
;          $0100 (256 increments per guard, wrapping to 0) rather than released
;                guards. The test was probably meant
;          to be OR E ("timer reached zero"). Verified in the simulator: no
;             change before the bell is taken, 256
;          increments afterwards.
; Hardware: none.
TickGuardTimers:
  LD HL,GuardTimers
  LD B,GUARD_COUNT
TickGuardTimers_Loop:
  LD E,(HL)               ; DE = this timer
  INC HL
  LD D,(HL)
  DEC HL
  LD A,D
  OR E
  JR Z,TickGuardTimers_0  ; already zero: guard is out, nothing to do
  DEC DE
  LD (HL),E
  INC HL
  LD (HL),D
  DEC HL
  LD A,D
  OR C                    ; BUG? C is not zero in practice (see above)
  JR NZ,TickGuardTimers_0
  LD A,(GuardsReleased)
  INC A
  LD (GuardsReleased),A
TickGuardTimers_0:
  INC HL                  ; next timer
  INC HL
  DJNZ TickGuardTimers_Loop
  RET

; Toggle the sound when T is pressed
;
; Called once per pass of the main loop at Start. Reads the T key and acts on
; the key-down edge only: the previous reading is kept in SoundKeyState (bit 4
; set = T up; initialised to $10), so holding the key down flips the sound just
; once. Each press flips the sound mask at SoundMask between $1F (sound on) and
; $07 (sound off); every routine that makes a noise ANDs its port $FE output
; with that mask. Hardware: reads port $FBFE (keyboard half-row Q-T, bit 4 =
; T).
CheckSoundKey:
  LD A,KB_Q_T             ; high byte of the port address: half-row Q,W,E,R,T
  IN A,(ULA_PORT)
  AND KEY_T_BIT           ; bit 4 = T, 0 when pressed
  LD HL,SoundKeyState
  CP (HL)
  RET Z                   ; no change since last pass
  LD (HL),A
  AND A
  RET NZ                  ; T was released: nothing to do
  LD HL,SoundMask
  LD A,(HL)
  XOR SOUND_TOGGLE        ; $1F <-> $07
  LD (HL),A
  RET

; Pace the game loop, or ring the bell
;
; The last routine of every pass of the main loop at Start, and the only thing
; that sets the game speed. While the bell bonus is lying in the maze (the word
; at BellPos, its screen offset, is not zero; UpdateBell animates it and counts
; BellTick up on every pass), the bell rings twice per 64 passes of that
; counter and the sound replaces the delay: when the counter is 0 (mod 64) a
; lower then a higher tone, when it is $20 a higher then a lower tone, provided
; sound is on (SoundMask = $1F). In every other case it burns a busy-wait delay
; of $015E + $1E * level - 2 * 64 * (guards released) loop passes, where level
; is GuardInterval (8 at the start of a game, then lower, so the game gets
; faster) and the guards-released term (GuardsReleased, see TickGuardTimers) is
; in practice zero. The rotation of that count uses RLA, so it is a multiply by
; 64 only for counts 0-3. Hardware: the delay is a timing loop (Delay), so the
; CPU speed sets the game speed. The chime calls the ROM BEEPER routine, which
; drives the speaker through port $FE and re-enables interrupts when it returns
; (the game runs with interrupts off, hence the DI after each call). BEEPER
; takes DE = frequency * duration (cycles) and HL = pitch value; the tones are
; about 1010 Hz and 1120 Hz for about 22 ms each.
PaceAndChime:
  LD HL,(BellPos)
  LD A,H
  OR L
  JR NZ,PaceAndChime_1    ; bell present: maybe ring it
PaceAndChime_Delay:
  LD A,(GuardInterval)
  LD E,A                  ; E = level, at least 1
  LD HL,SPEED_DELAY_BASE
PaceAndChime_0:
  LD BC,SPEED_DELAY_STEP
  ADD HL,BC               ; HL = base + step * level
  DEC E
  JR NZ,PaceAndChime_0
  XOR A                   ; clear carry for the RLA and SBC below
  LD A,(GuardsReleased)
  RLA                     ; A = guards released * 64 (for 0-3), see above
  RLA
  RLA
  RLA
  RLA
  RLA
  LD B,$00
  LD C,A
  SBC HL,BC               ; HL = HL - 2 * A
  SBC HL,BC
  PUSH HL
  POP BC                  ; BC = number of delay passes
  CALL Delay
  RET
; The bell is lying in the maze: ring it on two phases of its animation
; counter.
PaceAndChime_1:
  LD A,(BellTick)
  AND BELL_PHASE_MASK
  CP $00
  JR NZ,PaceAndChime_2
  LD HL,SoundMask         ; phase 0: lower tone, then higher tone
  LD A,(HL)
  CP ULA_OUT_MASK         ; sound mask = $1F: sound on
  JR NZ,PaceAndChime_Delay ; muted: just delay
  LD DE,CHIME_LOW_LEN
  LD HL,CHIME_LOW_PITCH
  CALL ROM_BEEPER
  DI                      ; BEEPER leaves interrupts enabled
  LD DE,CHIME_HIGH_LEN
  LD HL,CHIME_HIGH_PITCH
  CALL ROM_BEEPER
  DI
  RET
PaceAndChime_2:
  CP BELL_HALF_PHASE      ; phase $20: higher tone, then lower tone
  JR NZ,PaceAndChime_Delay ; any other phase: just delay
  LD HL,SoundMask
  LD A,(HL)
  CP ULA_OUT_MASK
  JR NZ,PaceAndChime_Delay
  LD DE,CHIME_HIGH_LEN
  LD HL,CHIME_HIGH_PITCH
  CALL ROM_BEEPER
  DI
  LD DE,CHIME_LOW_LEN
  LD HL,CHIME_LOW_PITCH
  CALL ROM_BEEPER
  DI
  RET

; Unused code bytes (LD A,(IX+0); LD A,(IX+0); RET), never executed
L6A17:
  DEFB $DD,$7E,$00,$DD,$7E,$00,$C9

; Leave the maze through the exit arrows
ExitMaze:
  POP HL
  JP NextMaze
