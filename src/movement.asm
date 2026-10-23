; Read the controls, or run the demo autopilot, and set Horace's direction
;
; Called once per pass of the main loop at Start. It decides in which direction
; Horace walks; the walking itself is done by PlanMoves, which moves him one
; cell per game tick in the direction left in $7C70 (the current direction).
; Nothing happens while Horace is frozen after going through a wrap pad ($7C79,
; WRAP_PAUSE passes, see PlanMoves). Otherwise the requested direction at $7C6F
; is first cleared to DIR_NONE and then the flag at GameActive selects the
; source of the input: zero (title screen countdown ended without a key, so
; this is the demo) runs the autopilot at Autopilot, non-zero (a real game)
; reads the keyboard at ReadKeys.
;
; Demo mode ends on any key. All eight half-rows are read at once (port high
;      byte $00); if any key bit is low the
; routine drops its return address and jumps to GameOver, which flashes the
;         screen with a rising tone and restarts
; the title screen at ShowTitle. (Measured: this path leaves SP two bytes
;     higher after every demo abort, because the
; return address popped here is followed by the POP HL at $6803 in HoraceDies,
;        which expects the caller's return address
; of the death path from CheckGuardContact instead.)
;
; Keyboard (real game): Q or 4 is up, Z or 3 is down, P or 2 is right, I or 1
; is left (DIR_*). The keys are tested in that order and the first one found
; wins; there is no joystick support. The wanted direction is probed with
; ProbeMove: if a wall is in the way the request is discarded (so Horace keeps
; going the way he is going), otherwise it becomes the current direction at
; once. A direction is therefore only changed when the new way is open; "exit"
; and "wrap" results count as open. Autopilot rule (demo): every pass, each of
; the four directions gets a weight. A direction whose probe result is
; MOVE_EXIT or MOVE_BLOCKED (including the $82 "pads and arrows mixed" result)
; weighs 0, so the demo never leaves through the arrows, and never walks into a
; wall. Every open direction (MOVE_FREE or MOVE_WRAP) weighs AI_BASE_SCORE + a
; random 0-31 (AI_RANDOM_MASK; new random byte per direction from GetRandom),
; then + AI_STRAIGHT_BONUS if it is the current direction ($7C70), -
; AI_REVERSE_PENALTY if it is the opposite of the current direction. So going
; on straight (weight 65-96) always beats a turn (25-56) or a reversal (15-46)
; while the way ahead is open, and when it is blocked the demo picks at random
; among the open turns, a reversal having a slightly lower chance. The
; direction with the highest weight becomes the current direction directly
; ($7C70; $7C6F stays DIR_NONE in demo). On equal weights the higher direction
; code wins (left, down, right, up) because the search runs from 3 down to 0
; and only a strictly greater weight replaces the best one; if all four weigh 0
; the result is DIR_UP. The pick is renewed on every pass, but once a turn is
; chosen it is the new "straight on" and keeps winning. Flowers, guards and the
; bell are ignored. The same constants and weights are used by the guards'
; direction choice. The four weights are kept in the direction score table at
; $6DB2-$6DB5, which the guard code also uses; $6DB6 serves as its end.
; Hardware: reads the keyboard through port $FE (half-rows Q-T, 1-5, CAPS
; SHIFT-V and P-Y; or all rows at once in demo mode). O:A Autopilot: the new
; direction; keyboard: the requested direction or DIR_NONE
ReadControls:
  LD A,(WrapPause)        ; frozen after a wrap: no input
  AND A
  RET NZ
  LD A,DIR_NONE
  LD (RequestedDir),A     ; no direction requested yet
  LD A,(GameActive)       ; 0 = demo, 1 = real game
  AND A
  JR NZ,ReadKeys          ; real game: keyboard
  LD A,KB_ALL_ROWS        ; demo: any key ends it
  IN A,(ULA_PORT)
  AND KEY_BITS
  CP KEY_BITS             ; all five key bits high = nothing pressed
  JR Z,Autopilot
  POP HL                  ; key pressed: forget the call to ReadControls...
  JP GameOver             ; ...and leave the demo
; Demo autopilot: weigh the four directions, B = 3, 2, 1, 0.
Autopilot:
  LD B,DIR_COUNT
Autopilot_Loop:
  DEC B                   ; B = direction being weighed
  LD HL,(HoracePos)       ; Horace's position
  LD C,$00                ; C = weight, 0 unless the way is open
  PUSH BC
  LD A,B
  CALL ProbeMove          ; what is one step in direction B?
  POP BC
  CP MOVE_EXIT            ; exit arrows or wall (or $82): weight stays 0
  JP NC,ReadControls_1
  CALL GetRandom
  AND AI_RANDOM_MASK
  ADD A,AI_BASE_SCORE
  LD C,A                  ; C = 25 + random 0-31
  LD A,(HoraceDir)        ; current direction
  CP B
  JR NZ,ReadControls_0
  LD A,AI_STRAIGHT_BONUS  ; same as the current direction: bonus
  ADD A,C
  LD C,A
  JR ReadControls_1
ReadControls_0:
  ADD A,DIR_OPPOSITE      ; current direction + 2 (mod 4) is the opposite one
  AND DIR_MASK
  CP B
  JR NZ,ReadControls_1
  LD A,$100-AI_REVERSE_PENALTY ; turning back: minus 10
  ADD A,C
  LD C,A
; Store the weight of direction B in the table at $6DB2.
ReadControls_1:
  PUSH BC
  LD HL,GuardDirScores
  LD C,B
  LD B,$00
  ADD HL,BC
  POP BC
  LD A,C
  LD (HL),A
  INC B
  DEC B
  JR NZ,Autopilot_Loop    ; next direction down to 0
; Pick the heaviest: scan from direction 3 down to 0, keep the first strictly
; greater weight.
  XOR A
  LD HL,GuardRecordPtr    ; one past the table
  LD B,DIR_COUNT
Autopilot_Pick:
  DEC B
  DEC HL
  CP (HL)
  JR NC,ReadControls_2
  LD A,(HL)
  LD C,B                  ; C = best direction so far (left over from the loop
                          ; above if all weights are 0: direction 0)
ReadControls_2:
  INC B
  DEC B
  JR NZ,Autopilot_Pick
  LD A,C
  LD (HoraceDir),A        ; new current direction
  RET
; Keyboard: Q/4 up, Z/3 down, P/2 right, I/1 left; the first pair found wins.
; The direction code is left in A for the probe at ReadKeys_Probe.
ReadKeys:
  LD A,KB_Q_T
  IN A,(ULA_PORT)
  AND KEY_Q               ; Q
  JR Z,ReadControls_3
  LD A,KB_1_5
  IN A,(ULA_PORT)
  AND KEY_4               ; 4
  JR NZ,ReadControls_4
ReadControls_3:
  LD A,DIR_UP
  LD (RequestedDir),A
  JR ReadKeys_Probe
ReadControls_4:
  LD A,KB_CS_V
  IN A,(ULA_PORT)
  AND KEY_Z               ; Z
  JR Z,ReadControls_5
  LD A,KB_1_5
  IN A,(ULA_PORT)
  AND KEY_3               ; 3
  JR NZ,ReadControls_6
ReadControls_5:
  LD A,DIR_DOWN
  LD (RequestedDir),A
  JR ReadKeys_Probe
ReadControls_6:
  LD A,KB_P_Y
  IN A,(ULA_PORT)
  BIT KEYBIT_P,A          ; P
  JR Z,ReadControls_7
  LD A,KB_1_5
  IN A,(ULA_PORT)
  AND KEY_2               ; 2
  JR NZ,ReadControls_8
ReadControls_7:
  LD A,DIR_RIGHT
  LD (RequestedDir),A
  JR ReadKeys_Probe
ReadControls_8:
  LD A,KB_P_Y
  IN A,(ULA_PORT)
  BIT KEYBIT_I,A          ; I
  JR Z,ReadControls_9
  LD A,KB_1_5
  IN A,(ULA_PORT)
  AND KEY_1               ; 1
  JR NZ,ReadControls_10   ; no direction key at all
ReadControls_9:
  LD A,DIR_LEFT
  LD (RequestedDir),A
; A key was pressed: A = its direction. Cancel the request when a wall is in
; the way.
ReadKeys_Probe:
  LD HL,(HoracePos)
  CALL ProbeMove
  CP MOVE_BLOCKED
  JR NZ,ReadControls_10
  LD A,DIR_NONE
  LD (RequestedDir),A
ReadControls_10:
  LD A,(RequestedDir)
  CP DIR_NONE
  RET Z                   ; nothing (valid) requested: keep the current
                          ; direction
  LD (HoraceDir),A        ; turn at once
  RET

; Plan Horace's next move and every active guard's next move
;
; Called once per pass of the main loop (Start). A countdown at StepCountdown
; is reloaded from the game pace (GuardInterval: 8 at the start, lower and
; faster in later mazes) and everything below happens only on the pass where it
; reaches zero, so Horace and the guards advance one character cell per "step"
; of 1-8 passes. The routine only decides where each figure wants to go and
; draws nothing: the new position of Horace is left in HoraceNextPos (the
; current one is HoracePos), the new position of each guard in the +4 field of
; its record.
;
; Horace is planned unless he is frozen after a wrap (WrapPause non-zero). The
; cell block one step ahead in his current direction (HoraceDir, set from the
; keys by ReadControls) is probed with ProbeMove: - Free: the new position is
; one cell on (StepCell). - Wall, or the left-hand arrows: he stays where he
; is. - Wrap pad (invisible pads at the top and bottom of the maze): he leaves
; at one edge and re-enters at the other. The new position is the current one
; plus (moving up) or minus (moving down) the vertical wrap delta, the first
; word of MazeDescriptor. A short rising tone is played and WrapPause is set to
; 90, which freezes Horace for 90 passes: no key reading (ReadControls), no
; pickups (EatObject), and DrawHorace only copies the new position over the
; current one. - Edge arrows: only the right-hand ones are an exit, so only
; when moving right. The routine then jumps to ExitMaze, which drops this
; routine's return address and starts the next maze at NextMaze; the guards are
; not planned.
;
; The guards come next: the four release timers (GuardTimers) are scanned and
; every guard whose timer is zero is loaded into the working record
; (LoadGuardRecord), planned by ChooseGuardMove and saved back
; (SaveGuardRecord). Guards still waiting are skipped. Hardware: the wrap tone
; writes port $FE (speaker and border) with busy-wait loops, so the game stops
; for about 0.07 s; it is muted through the sound mask SoundMask.
;
; O:A Corrupted
PlanMoves:
  LD A,(StepCountdown)    ; game step countdown
  DEC A
  LD (StepCountdown),A
  RET NZ                  ; not this pass
  LD A,(GuardInterval)    ; reload from the game pace
  LD (StepCountdown),A
; Frozen after a wrap: skip Horace, plan only the guards.
  LD A,(WrapPause)        ; wrap freeze counter
  AND A
  JR NZ,PlanMoves_Guards
; Ask what lies one step ahead of Horace in his current direction.
  LD A,(HoraceDir)        ; Horace direction
  LD HL,(HoracePos)
  CALL ProbeMove
  CP MOVE_FREE
  JR Z,PlanMoves_6
  CP MOVE_WRAP
  JR Z,PlanMoves_Wrap
  CP MOVE_EXIT
  JR NZ,PlanMoves_8
  LD A,(HoraceDir)        ; moving right?
  CP DIR_RIGHT
  JP Z,ExitMaze
  JR PlanMoves_8
PlanMoves_Wrap:
  LD A,WRAP_PAUSE
  LD (WrapPause),A
  LD BC,(MazeDescriptor)
  LD HL,(HoracePos)
  LD A,(HoraceDir)
; Up: add the wrap delta (jump to the bottom), otherwise (down) subtract it.
  AND A                   ; direction 0 is up
  JR Z,PlanMoves_0
  SBC HL,BC
  JR PlanMoves_1
PlanMoves_0:
  ADD HL,BC
PlanMoves_1:
  PUSH HL
  LD HL,SoundMask
; The tone is the one of PlayRisingTone with 8 instead of 10 cycles per pitch
; step; the new position waits on the stack.
  LD C,SWEEP_STEPS
PlanMoves_2:
  PUSH BC
  LD B,C
  SLA B
  SLA B
  SLA B
  LD E,B
  LD D,WRAP_TONE_CYCLES
PlanMoves_3:
  LD B,E
  LD A,ULA_OUT_MASK
  AND (HL)
  OUT (ULA_PORT),A
PlanMoves_4:
  DJNZ PlanMoves_4
  LD A,WHITE
  OUT (ULA_PORT),A
  LD B,E
PlanMoves_5:
  DJNZ PlanMoves_5
  DEC D
  JR NZ,PlanMoves_3
  POP BC
  DEC C
  JR NZ,PlanMoves_2
  POP HL
  JR PlanMoves_7
; Free: step one cell in the current direction.
PlanMoves_6:
  LD HL,(HoracePos)
  LD A,(HoraceDir)
  CALL StepCell
PlanMoves_7:
  LD (HoraceNextPos),HL
  JR PlanMoves_Guards
; Blocked: the new position is the current one.
PlanMoves_8:
  LD HL,(HoracePos)
  LD (HoraceNextPos),HL
; Plan the guards: HL walks the four release timers, B counts 4 down to 1 (the
; guard number LoadGuardRecord expects).
PlanMoves_Guards:
  LD HL,GuardTimers
  LD B,GUARD_COUNT
PlanMoves_9:
  PUSH BC
  LD A,(HL)               ; timer low byte
  INC HL
  OR (HL)                 ; both bytes zero: the guard is active
  INC HL
  PUSH HL
  JR NZ,PlanMoves_10      ; timer running: skip this guard
  CALL LoadGuardRecord
  CALL ChooseGuardMove
  CALL SaveGuardRecord
PlanMoves_10:
  POP HL
  POP BC
  DJNZ PlanMoves_9
  RET

; Choose the working guard's direction and next position
;
; The guard AI. Called by PlanMoves for each active guard with its record
; loaded into the working buffer at GuardRecord (position +0, direction +2, new
; position +4, wait counter +6). Nothing happens while the wait counter
; (GuardWait, set after the guard has been eaten) is non-zero.
;
; Every one of the four directions gets a score and the highest score wins. The
; guard decides again at every step (one character cell), not only at
; junctions. The scores, one byte per direction, are stored from GuardDirScores
; (up, right, down, left) and GuardRecordPtr serves as the end marker. For each
; direction the block of cells one step ahead is probed with ProbeMove: - Wall,
; edge arrows (the guards never leave through them) or any other result of 2 or
; more: the score is 0, the direction is never chosen while another one has a
; score. - Otherwise the score starts at 25 and gets: +40 when it is the
; guard's current direction (GuardDir), so a guard tends to go straight on; or
; -10 when it is the opposite of the current direction; or, for the two
; sideways directions, a random 0-31 (the low five bits of a ROM byte, see
; below). - Chase: a direction that leads towards Horace along its axis gets a
; bonus of 10 plus the distance in cells along that axis. Up counts when
; Horace's row is not below the guard's, down when it is not above, left and
; right likewise with the columns. A direction that leads away from him gets
; nothing. When Horace is on the guard's row, up and down both get the bonus
; 10; on its column, left and right do. The bonus grows with the distance, so
; far away the guard prefers to close the longer gap first. - While the bell
; timer (BellTimer) is running the bonus is subtracted instead of added, so the
; guard runs from Horace. The subtraction is done on a byte without a floor, so
; a result below 0 wraps to a value near 255 and wins (probably a bug: a scared
; guard far from Horace that is walking away turns back towards him, because
; the opposite direction scores 15 minus up to 33).
;
; The random numbers do not come from GetRandom: the pointer is the low word of
; the system variable FRAMES (the interrupts are off, so the game itself owns
; it), increased by one at every draw and masked to $0000-$0FFF to read a byte
; of the ROM. Only open sideways directions draw a number.
;
; The best direction (the highest score, a tie going to the highest direction
; code, so left before down before right before up; if all scores are 0 it is
; up) is stored in +2. The new position in +4 is the position one cell on
; (StepCell). Probing the chosen direction again can give a wrap pad: the guard
; then jumps by the vertical wrap delta of the maze descriptor
; (MazeDescriptor), plus when going up and minus when going down, as Horace
; does. Any other result leaves the guard where it is. Hardware: reads the ROM
; as a source of random numbers; touches no port or screen.
;
; O:HL New position of the guard, also stored in its record (not set when the
;      wait counter is non-zero)
ChooseGuardMove:
  LD A,(GuardWait)        ; wait counter of the guard
  AND A
  RET NZ                  ; non-zero: the guard is paused
; Convert a screen offset (third, pixel row, character row, column) into H =
; cell row 0-23 and L = column 0-31: the three RR H drop the pixel row bits,
; the five RR H/RR L pairs then shift the 16-bit value right by 5.
  LD HL,(HoracePos)
  RR H
  RR H
  RR H
  LD B,CELL_COL_BITS
ChooseGuardMove_0:
  RR H
  RR L
  DJNZ ChooseGuardMove_0
  LD A,L
  AND SCREEN_COLS-$01
  LD HL,(HoracePos)
  LD H,A
  LD A,L
  AND SCREEN_COLS-$01
  LD L,A
  LD (HoraceCell),HL      ; HoraceCell = Horace: H row, L column
; Same for the guard: GuardCell = row and column of the guard.
  LD HL,(GuardRecord)
  RR H
  RR H
  RR H
  LD B,CELL_COL_BITS
ChooseGuardMove_1:
  RR H
  RR L
  DJNZ ChooseGuardMove_1
  LD A,L
  AND SCREEN_COLS-$01
  LD HL,(GuardRecord)
  LD H,A
  LD A,L
  AND SCREEN_COLS-$01
  LD L,A
  LD (GuardCell),HL       ; GuardCell = guard: H row, L column
; Score the directions 3 (left), 2, 1 and 0 (up) in this order; B is the
; direction being scored.
  LD B,DIR_COUNT
ChooseGuardMove_Dir:
  DEC B                   ; next direction
  LD HL,(GuardRecord)
  LD C,$00                ; C = score, 0 if blocked
  PUSH BC
  LD A,B
  CALL ProbeMove          ; what is one step ahead?
  POP BC
  CP MOVE_EXIT
  JP NC,ChooseGuardMove_Store ; wall, exit arrows or worse: score stays 0
  LD C,AI_BASE_SCORE
  LD A,(GuardDir)         ; current direction of the guard
  CP B
  JR NZ,ChooseGuardMove_2 ; sideways or opposite?
  LD A,AI_STRAIGHT_BONUS
  ADD A,C
  LD C,A
  JR ChooseGuardMove_4    ; score 25 + 40
ChooseGuardMove_2:
  ADD A,DIR_OPPOSITE
  AND DIR_MASK            ; opposite of the current direction
  CP B
  JR NZ,ChooseGuardMove_3
  LD A,$100-AI_REVERSE_PENALTY
  ADD A,C
  LD C,A
  JR ChooseGuardMove_4    ; score 25 - 10
; Sideways: add the next ROM byte (pointer = FRAMES word, advanced by one at
; every draw) AND 31.
ChooseGuardMove_3:
  LD HL,(FRAMES)
  INC HL
  LD (FRAMES),HL
  LD A,H
  AND RANDOM_ROM_HIGH_MASK
  LD H,A
  LD A,(HL)
  AND AI_RANDOM_MASK
  ADD A,C
  LD C,A                  ; score 25 + random 0-31
; Dead code: UnusedAiCounter is decremented when direction 3 is scored and
; reloaded with the game pace when direction 0 is scored; nothing reads it.
ChooseGuardMove_4:
  LD A,B
  CP DIR_LEFT
  LD A,(UnusedAiCounter)
  JR NZ,ChooseGuardMove_5
  DEC A                   ; dead counter
  LD (UnusedAiCounter),A
ChooseGuardMove_5:
  AND A
  LD A,B
  CP DIR_UP
  JR NZ,ChooseGuardMove_6
  LD A,(GuardInterval)
  LD (UnusedAiCounter),A
ChooseGuardMove_6:
  LD A,B
  CP DIR_UP
  JR NZ,ChooseGuardMove_7
; Up: bonus only if Horace is level with or above the guard (guard row - Horace
; row >= 0).
  LD HL,(GuardCell)
  LD A,H
  LD HL,(HoraceCell)
  SUB H
  JR C,ChooseGuardMove_Store ; Horace is below: no bonus
  JR ChooseGuardMove_10
ChooseGuardMove_7:
  CP DIR_RIGHT
  JR NZ,ChooseGuardMove_8
; Right: bonus only if Horace is level with or right of the guard (Horace
; column - guard column >= 0).
  LD HL,(HoraceCell)
  LD A,L
  LD HL,(GuardCell)
  SUB L
  JR C,ChooseGuardMove_Store
  JR ChooseGuardMove_10
ChooseGuardMove_8:
  CP DIR_DOWN
  JR NZ,ChooseGuardMove_9
; Down: bonus only if Horace is level with or below the guard (Horace row -
; guard row >= 0).
  LD HL,(HoraceCell)
  LD A,H
  LD HL,(GuardCell)
  SUB H
  JR C,ChooseGuardMove_Store
  JR ChooseGuardMove_10
; Left: bonus only if Horace is level with or left of the guard (guard column -
; Horace column >= 0).
ChooseGuardMove_9:
  LD HL,(GuardCell)
  LD A,L
  LD HL,(HoraceCell)
  SUB L
  JR C,ChooseGuardMove_Store
ChooseGuardMove_10:
  AND A
  ADD A,AI_CHASE_BIAS     ; distance + 10
; The bell timer is a word: non-zero means the guards are scared.
  PUSH AF
  PUSH HL
  LD HL,(BellTimer)
  LD A,H
  OR L
  POP HL
  JR Z,ChooseGuardMove_11
  POP AF
; Scared: subtract the bonus (8-bit wrap-around, see the description).
  NEG
  JR ChooseGuardMove_12   ; unsigned compare later: a negative result looks
                          ; like a high score
ChooseGuardMove_11:
  POP AF
ChooseGuardMove_12:
  ADD A,C
  LD C,A
ChooseGuardMove_Store:
  PUSH BC
  LD HL,GuardDirScores
  LD C,B
  LD B,$00
  ADD HL,BC
  POP BC
  LD A,C
  LD (HL),A               ; store the score at GuardDirScores + direction
  INC B
  DEC B
  JP NZ,ChooseGuardMove_Dir
; Pick the highest score, scanning left, down, right, up. A is the best so far,
; C its direction.
ChooseGuardMove_Pick:
  XOR A
  LD HL,GuardRecordPtr
  LD B,DIR_COUNT
ChooseGuardMove_13:
  DEC B
  DEC HL
  CP (HL)                 ; score of this direction
  JR NC,ChooseGuardMove_14
  LD A,(HL)               ; new best
  LD C,B
ChooseGuardMove_14:
  INC B
  DEC B
  JR NZ,ChooseGuardMove_13
  LD A,C
  LD (GuardDir),A         ; store the chosen direction in the record
; Now find the position one step in the chosen direction.
ChooseGuardMove_Move:
  LD A,(GuardDir)         ; chosen direction
  LD HL,(GuardRecord)     ; guard position
  CALL ProbeMove
  CP MOVE_FREE
  JR Z,ChooseGuardMove_17
  CP MOVE_WRAP
  JR NZ,ChooseGuardMove_19
; Wrap pad: add the wrap delta going up, subtract it going down.
  LD BC,(MazeDescriptor)
  LD A,(GuardDir)
  AND A
  JR Z,ChooseGuardMove_15
  SBC HL,BC
  JR ChooseGuardMove_16
ChooseGuardMove_15:
  ADD HL,BC
ChooseGuardMove_16:
  JR ChooseGuardMove_18
; Free: one cell on.
ChooseGuardMove_17:
  LD HL,(GuardRecord)
  LD A,(GuardDir)
  CALL StepCell
ChooseGuardMove_18:
  LD (GuardNewPos),HL
  RET                     ; new position stored
; Blocked: stay.
ChooseGuardMove_19:
  LD HL,(GuardRecord)
  LD (GuardNewPos),HL
  RET
