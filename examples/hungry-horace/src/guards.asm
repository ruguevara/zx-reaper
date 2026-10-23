; Reset the guard release timers
;
; Called at the start of a game (Start) and after a lost pass (HoraceDies), not
; when Horace leaves a maze through the exit, so the timers carry over into the
; next maze. It frees the first guard at once and holds the other three back:
; GuardTimers is an array of four words, one per guard record (in the order of
; GuardRecords), counted down once per main loop pass by TickGuardTimers; a
; guard is moved only while its timer is zero. The timers become 0, n*256,
; 2n*256 and 4n*256, where n is the guard interval (GuardInterval: 8 at the
; start of the game, lower from level to level). Also clears the count at
; GuardsReleased, which TickGuardTimers raises while the timers run out and
; PaceAndChime uses to shorten the game's delay.
;
; O:HL Timer of the last guard
ResetGuardTimers:
  LD A,$00
  LD (GuardsReleased),A
  LD HL,$0000
  LD (GuardTimers),HL     ; first guard: no wait
  LD A,(GuardInterval)
  LD H,A                  ; HL = interval * 256 (L is still 0)
  LD (GuardTimers+$0002),HL
  SLA H
  LD (GuardTimers+$0004),HL ; twice that
  SLA H
  LD (GuardTimers+$0006),HL ; four times
  RET

; Load a guard record into the working buffer
;
; The four guards have a 43-byte state record each, stored one after another
; from GuardRecords. To work on one of them the game copies it into the working
; buffer at GuardRecord, remembers where it came from in GuardRecordPtr, and
; writes the buffer back with SaveGuardRecord when done. B counts down 4, 3, 2,
; 1 in the callers' loops, so B=4 selects the first record (at GuardRecords)
; and B=1 the last (at Guard4Record); any value other than 4, 3 or 2 selects
; the last.
;
;   B Guard number 4 (first record) down to 1 (last record)
; O:HL Address after the working buffer's source record
LoadGuardRecord:
  LD A,B
  CP $04
  JR NZ,LoadGuardRecord_0
  LD HL,GuardRecords
  JR LoadGuardRecord_3
LoadGuardRecord_0:
  CP $03
  JR NZ,LoadGuardRecord_1
  LD HL,GuardRecords+GUARD_RECORD_SIZE
  JR LoadGuardRecord_3
LoadGuardRecord_1:
  CP $02
  JR NZ,LoadGuardRecord_2
  LD HL,GuardRecords+GUARD_RECORD_SIZE*$0002
  JR LoadGuardRecord_3
LoadGuardRecord_2:
  LD HL,GuardRecords+GUARD_RECORD_SIZE*$0003
LoadGuardRecord_3:
  LD (GuardRecordPtr),HL  ; remember the source record for SaveGuardRecord
  LD DE,GuardRecord
  LD BC,GUARD_RECORD_SIZE
  LDIR
  RET

; Save the working guard record
;
; Copies the 43-byte working buffer at GuardRecord back to the guard record it
; was loaded from by LoadGuardRecord (the source address is kept in
; GuardRecordPtr). Call it after changing the buffer.
;
; O:HL Address after the working buffer
; O:DE Address after the saved record
SaveGuardRecord:
  LD HL,(GuardRecordPtr)
  LD DE,GuardRecord
  EX DE,HL                ; HL = buffer, DE = record
  LD BC,GUARD_RECORD_SIZE
  LDIR
  RET

; Play a rising tone
;
; A square-wave sweep of 16 pitch steps, from low to high, of 10 cycles each
; (about 0.08 s in all). The title screen calls it once per pass of its
; colour-cycling loop, so it also acts as that loop's pacing delay; the game
; calls it again at HoraceDies. Muted when SoundMask (the sound mask) has been
; toggled off: the beeper bit is then masked out of every OUT and only the
; white border is written. Hardware: writes port $FE, with busy-wait loops
; setting the pitch; the border is set to white and the speaker is switched on
; and off.
;
; O:HL Address of the sound mask
PlayRisingTone:
  LD HL,SoundMask
  LD C,SWEEP_STEPS        ; C = step number, counting down: half period = 8*C
                          ; loop passes
PlayRisingTone_Step:
  PUSH BC
  LD B,C
  SLA B
  SLA B
  SLA B
  LD D,B                  ; D = half period
  LD E,SWEEP_CYCLES
PlayRisingTone_0:
  LD B,D
  LD A,ULA_OUT_MASK
  AND (HL)                ; speaker on unless muted
  OUT (ULA_PORT),A
PlayRisingTone_1:
  DJNZ PlayRisingTone_1
  LD A,WHITE              ; speaker off, white border
  OUT (ULA_PORT),A
  LD B,D
PlayRisingTone_2:
  DJNZ PlayRisingTone_2
  DEC E
  JR NZ,PlayRisingTone_0
  POP BC
  DEC C
  JR NZ,PlayRisingTone_Step
  RET

; Load a maze descriptor
;
; Copies an 8-byte maze descriptor (four words, one of the four descriptors
; from Maze1Desc) to the current maze descriptor at MazeDescriptor.
;
;   HL Address of the maze descriptor to use
; O:HL Address after the source descriptor
; O:DE Address after the current maze descriptor
LoadMazeDescriptor:
  LD DE,MazeDescriptor
  LD BC,MAZE_DESC_SIZE
  LDIR
  RET
