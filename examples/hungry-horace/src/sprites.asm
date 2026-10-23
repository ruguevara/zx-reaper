; Erase Horace and the moved guards from their old positions
;
; First part of the per-frame sprite update (see Start, which calls DrawGuards
; and DrawHorace afterwards to draw the guards and Horace at their new places).
; If Horace's next position (HoraceNextPos) differs from his current one
; (HoracePos) he is erased from the current position by drawing the blank
; sprite there. Then every guard that is in the maze (release timer in
; GuardTimers is zero) is loaded into the working buffer (LoadGuardRecord),
; erased with EraseGuard if it has moved and written back (SaveGuardRecord).
; The guards are visited in the order 4, 3, 2, 1: B counts 1 to 4 while the
; timer pointer walks down from the last timer. Hardware: writes the screen
; bitmap and attributes.
EraseSprites:
  LD HL,(HoraceNextPos)   ; Horace's next position
  LD DE,(HoracePos)       ; Horace's current position
  XOR A
  SBC HL,DE
  LD A,H
  OR L
  JR Z,EraseSprites_0     ; did not move: nothing to erase
  LD HL,(HoracePos)
  LD DE,BlankSprite       ; blank sprite
  CALL SetAttrPointer
  LD C,ATTR_BLANK
  CALL DrawSprite
EraseSprites_0:
  LD HL,GuardTimers+(GUARD_COUNT-$0001)*$0002 ; timer of the last guard
  LD B,$01
EraseSprites_Loop:
  PUSH BC
  LD A,(HL)
  INC HL
  OR (HL)
  DEC HL
  DEC HL
  DEC HL
  PUSH HL                 ; points at the timer of the next guard
  JR NZ,EraseSprites_1    ; timer still running: this guard is not in the maze
                          ; yet
  CALL LoadGuardRecord
  CALL EraseGuard
  CALL SaveGuardRecord
EraseSprites_1:
  POP HL
  POP BC
  INC B
  LD A,B
  CP GUARD_COUNT+$01
  JR NZ,EraseSprites_Loop
  RET

; Erase a guard that has moved and save the background at its new place
;
; Works on the guard record in the working buffer (GuardRecord), which holds
; the guard's old screen offset (+0) and the offset it is about to move to
; (+4). If both are equal the guard has not moved and the routine returns at
; once. Otherwise the four character cells saved from under the guard
; (SavedBackground) are drawn back at the old position, which removes the old
; image, and the cells under the new position are saved with SaveBackground so
; that the next call can remove the guard from there. The guard itself is drawn
; afterwards by DrawGuard, which also copies the new position into the old one.
; Hardware: writes the screen bitmap and attributes (four cells);
; SaveBackground reads them.
;
; O:Z Set if the guard had not moved (the entry at EraseGuard only)
EraseGuard:
  LD HL,(GuardNewPos)     ; new position
  LD DE,(GuardRecord)     ; old position
  XOR A
  SBC HL,DE
  LD A,H
  OR L
  RET Z                   ; did not move: the screen is up to date
; Entry point without the "has it moved" test, for the guards that must be
; wiped from the screen in any case. This entry point is used by the routines
; at CheckGuardContact and HoraceDies.
EraseGuard_Always:
  LD HL,(GuardRecord)     ; old position
  LD BC,SCREEN
  ADD HL,BC
  CALL SetAttrPointer
  LD DE,SavedBackground
  LD A,(DE)               ; top-left cell: attribute, then ...
  INC DE
  LD C,A
  CALL DrawCell           ; ... its 8 bitmap rows
  LD A,(DE)               ; top-right cell
  INC DE
  LD C,A
  CALL DrawCell
; Move to the left cell of the next cell row: HL is two cells along already, so
; add 30, carrying into the next screen third.
  LD A,L
  ADD A,SCREEN_COLS-$02
  LD L,A
  JR NC,EraseGuard_0
  LD A,H
  ADD A,THIRD_STEP
  LD H,A
EraseGuard_0:
  LD A,(DE)               ; bottom-left cell
  INC DE
  LD C,A
  CALL SetAttrPointer     ; the attribute pointer must be recomputed for the
                          ; new cell row
  CALL DrawCell
  LD A,(DE)               ; bottom-right cell
  INC DE
  LD C,A
  CALL DrawCell
  LD HL,(GuardNewPos)     ; save the background under the new position
  CALL SaveBackground
  RET

; Score what Horace eats on his next step
;
; Called once per pass of the main loop at Start, after Horace's next position
; ($7C6D) has been worked out by PlanMoves and before he is drawn there. Does
; nothing while Horace is frozen after a wrap pad ($7C79 non-zero). Otherwise
; the 2x2 block at the next position is searched with GetBlockObject for an
; object, which is recognised by its attribute (guard, bell, flower, see
; MergeObjectAttr). A flower scores SCORE_FLOWER; any other object found scores
; SCORE_ITEM: in practice the bell (attribute $3A) and the fruit, whose red
; cells have the bell's attribute and are found before the flower-green ones.
; Nothing found: nothing happens. The flower itself disappears when Horace is
; drawn over it. The guard attribute would also take this branch (50 points),
; but no guard was seen to reach it; guard contact is handled in
; CheckGuardContact (which adds 100 points while the bell timer runs). The
; score is the word at $7C73; the code then falls into ShowScore.
;
; Hardware: reads the attribute area; the fall-through writes the screen and
; the speaker (see ShowScore).
EatObject:
  LD A,(WrapPause)        ; frozen after a wrap: nothing to eat
  AND A
  RET NZ
  LD HL,(HoraceNextPos)   ; where Horace is about to be
  CALL GetBlockObject
  RET Z                   ; nothing there
  CP ATTR_FLOWER
  JR NZ,EatObject_Item
  LD HL,(Score)
  LD BC,SCORE_FLOWER
  ADD HL,BC
  LD (Score),HL
  JR ShowScore
EatObject_Item:
  LD HL,(Score)
  LD BC,SCORE_ITEM
  ADD HL,BC
  LD (Score),HL
; Show the score, award an extra pass, and play the sound Redraws the score on
; the status line, grants an extra pass each time the score passes a multiple
; of 10000, and plays a short rising chirp. Called after every score change: by
; EatObject above, by CheckGuardContact after a guard is eaten, by UpdateBell
; (twice) for the bell, and at the start of a maze or a new life by Start (HL
; = the number to print: every caller loads Score into HL first; tested). Printing is skipped in demo mode (see PrintNumber, PrintChar),
; but the sound is not. The ten-thousands counter in $7C77 holds score/10000 +
; 2 as it was at the last call (the +2 comes from the counting loop below).
; When the new value differs, the passes counter $7C78 goes up by one and its
; digit is reprinted at the first status line cell after "PASSES ". At the
; start of a game $7C77 is 0 (set by Start) and the first call finds 2, so a
; game starts with 4 passes although $7C78 was just set to 3 (the screen shows
; PASSES 4). Hardware: writes the screen bitmap and attributes of the status
; line (row 0), and the beeper through port $FE with busy-wait loops: 16 steps
; of one square-wave cycle, half period 8*C loop passes (C = 16 down to 1), so
; the pitch rises; about 8 ms in all. The speaker bit is masked by the sound
; mask at $7C69. O:HL Address of the sound mask O:C 0
ShowScore:
  LD DE,SCREEN
  EX DE,HL
  LD BC,STATUS_SCORE_COL
  ADD HL,BC
  EX DE,HL                ; DE = status line cell of the first score digit
  CALL PrintNumber
  LD HL,(Score)
  XOR A
  LD BC,EXTRA_PASS_SCORE
; A = number of times 10000 can be subtracted, + 1 ...
EatObject_0:
  INC A
  SBC HL,BC
  JR NC,EatObject_0
  INC A                   ; ... + 1 again
  LD B,A
  LD A,(ExtraPassMark)
  CP B
  JR Z,EatObject_1        ; same ten-thousands as before: no extra pass
  LD A,B
  LD (ExtraPassMark),A
  LD A,(Passes)
  INC A                   ; one more pass (no upper limit)
  LD (Passes),A
  LD HL,SCREEN+STATUS_PASSES_COL
  CALL SetAttrPointer
  LD A,(Passes)
  ADD A,CHAR_0
  EX DE,HL
  CALL PrintChar
; The chirp. B = half period = 8*C; one cycle per step, C = 16 ... 1.
EatObject_1:
  LD HL,SoundMask
  LD C,EAT_TONE_STEPS
EatObject_2:
  PUSH BC
  LD B,C
  SLA B
  SLA B
  SLA B
  PUSH BC
  LD A,ULA_OUT_MASK
  AND (HL)                ; speaker on unless muted
  OUT (ULA_PORT),A
EatObject_3:
  DJNZ EatObject_3
  LD A,WHITE              ; speaker off, white border
  OUT (ULA_PORT),A
  POP BC
EatObject_4:
  DJNZ EatObject_4
  POP BC
  DEC C
  JR NZ,EatObject_2
  RET

; Draw all guards that are in the maze
;
; Second part of the per-frame sprite update (after EraseSprites, see Start).
; Visits the four guard release timers (GuardTimers, GuardTimers) in order; for
; each guard whose timer is zero (released) it loads the guard record into the
; working buffer (LoadGuardRecord), draws the guard with DrawGuard and writes
; the record back (SaveGuardRecord). B counts 4 to 1, which selects the records
; from the first to the last. Hardware: writes the screen bitmap and attributes
; (through DrawGuard).
DrawGuards:
  LD HL,GuardTimers
  LD B,GUARD_COUNT
DrawGuards_Loop:
  PUSH BC
  LD A,(HL)
  INC HL
  OR (HL)
  INC HL
  PUSH HL                 ; points at the timer of the next guard
  JR NZ,DrawGuards_0      ; timer still running: this guard is not in the maze
                          ; yet
  CALL LoadGuardRecord
  CALL DrawGuard
  CALL SaveGuardRecord
DrawGuards_0:
  POP HL
  POP BC
  DJNZ DrawGuards_Loop
  RET

; Draw one guard
;
; Draws the guard of the working buffer (GuardRecord) at its new position (+4)
; and makes that its current position (+0). A guard that has just been eaten
; waits first: while the wait counter (GuardWait, GuardWait) is non-zero it is
; counted down and the guard is not drawn; the guard reappears when the count
; reaches zero. The graphic depends on the bell timer (BellTimer): - Timer
; running (guards can be eaten): the timer is counted down by one for every
; guard drawn, and the guard uses one of the two alternating frames at
; ScaredGuardSprites (frame chosen by bit 3 of the animation counter in +3). -
; Otherwise the normal guard graphics: the direction (+2, 0-3) selects one of
; four sprites of 32 bytes in a set of four, which is GuardSprites2 when bit 5
; of the animation counter in +3 is clear and GuardSprites when it is set. The
; animation counter (+3) is incremented on every call that gets this far. The
; guard record must have been loaded into the working buffer with
; LoadGuardRecord and is saved again by the caller. Hardware: writes the screen
; bitmap and four attribute cells (through DrawSprite).
DrawGuard:
  LD A,(GuardWait)        ; wait counter
  AND A
  JR Z,DrawGuard_0
  DEC A
  LD (GuardWait),A
  RET NZ                  ; still waiting
DrawGuard_0:
  LD HL,(GuardNewPos)
  LD (GuardRecord),HL     ; new position becomes current
  LD BC,(BellTimer)       ; bell timer
  LD A,B
  OR C
  JR Z,DrawGuard_2        ; not running: normal guard
  DEC BC
  LD (BellTimer),BC
  LD DE,ScaredGuardSprites ; edible guard frames
  EX DE,HL                ; HL = frames, DE = position
  LD A,(GuardAnim)
  INC A
  LD (GuardAnim),A
  AND GUARD_SCARED_FRAME_BIT
  CP $00
  JR Z,DrawGuard_1
  LD BC,SPRITE_BYTES      ; second frame
  ADD HL,BC
DrawGuard_1:
  EX DE,HL                ; HL = position, DE = sprite
  JR DrawGuard_5
DrawGuard_2:
  EX DE,HL                ; DE = position
  LD A,(GuardAnim)
  INC A
  LD (GuardAnim),A
  AND GUARD_WALK_FRAME_BIT
  CP $00
  JR NZ,DrawGuard_3
  LD HL,GuardSprites2     ; second set, direction 0
  JR DrawGuard_4
DrawGuard_3:
  LD HL,GuardSprites      ; first set, direction 0
; Direction * 32 (RLC five times) is the offset of the direction's sprite.
DrawGuard_4:
  LD A,(GuardDir)
  RLC A
  RLC A
  RLC A
  RLC A
  RLC A
  LD B,$00
  LD C,A
  ADD HL,BC
  EX DE,HL                ; HL = position, DE = sprite
DrawGuard_5:
  CALL SetAttrPointer
  LD C,ATTR_GUARD
  CALL DrawSprite
  RET
