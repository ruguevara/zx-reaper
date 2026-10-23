; Guard release timers: guard 1 (word); the table continues at 6DA8, 6DAA and
; 6DAC
;
; GuardTimers is an array of four words, one per guard, in the order of the
; guard records (guard 1 = GuardRecords up to guard 4 = Guard4Record): $6DA6
; guard 1, Guard2Timer guard 2, Guard3Timer guard 3, Guard4Timer guard 4. The timer counts
; main-loop passes until the guard is released; a guard whose timer is 0 is in
; the maze (moved by PlanMoves, erased and drawn by EraseSprites and
; DrawGuards, tested by CheckGuardContact and UpdateFruitDrops).
; ResetGuardTimers sets the timers at the start of a game and after Horace
; loses a life (not when a maze is left through the exit arrows: the timers
; then run on) to 0, n*256, 2*n*256 and 4*n*256 where n is the game pace
; GuardInterval (0, 2048, 4096, 8192 passes at the start). TickGuardTimers
; decrements every non-zero timer once per pass.
;
; The code walks the table with a pointer that moves two bytes per guard, with
; B = 4 down to 1 ($6DA6 up) or B = 1 up to 4 ($6DAC down); B is the number
; LoadGuardRecord expects (4 = first record, 1 = last), so the timer and the
; record of a guard always go together.
GuardTimers:
  DEFW $0000

; Guard release timer: guard 2 (word, part of GuardTimers)
;
; The second word of the four-word array GuardTimers that starts at GuardTimers
; (see there for the meaning and for who sets and counts it). It belongs to the
; guard whose record is at Guard2Record. Initial value after ResetGuardTimers:
; n*256 passes (n = game pace GuardInterval, 8 at the start of a game).
Guard2Timer:
  DEFW $0000

; Guard release timer: guard 3 (word, part of GuardTimers)
;
; The third word of the four-word array GuardTimers that starts at GuardTimers
; (see there for the meaning and for who sets and counts it). It belongs to the
; guard whose record is at Guard3Record. Initial value after ResetGuardTimers:
; 2*n*256 passes (n = game pace GuardInterval, 8 at the start of a game).
Guard3Timer:
  DEFW $0000

; Guard release timer: guard 4 (word, part of GuardTimers)
;
; The fourth word of the four-word array GuardTimers that starts at GuardTimers
; (see there for the meaning and for who sets and counts it). It belongs to the
; guard whose record is at Guard4Record. Initial value after ResetGuardTimers:
; 4*n*256 passes (n = game pace GuardInterval, 8 at the start of a game).
Guard4Timer:
  DEFW $0000

; Bell timer: guards can be eaten while non-zero (word)
;
; Set by UpdateBell (TakeBell) when Horace takes the bell to 128 times the game
; pace GuardInterval (128 to 1024). While it is non-zero the guards are
; "scared": DrawGuard draws the edible-guard sprites and decrements the timer
; once per drawn guard (so it runs out faster the more guards are out),
; ChooseGuardMove subtracts its chase bonus instead of adding it, and
; CheckGuardContact treats Horace touching a guard as eating it (+100 points)
; instead of losing a life. CheckGuardContact clears it when a guard is eaten,
; and Start clears it at the start of each maze and after a new life. 0 =
; guards are dangerous.
BellTimer:
  DEFW $0000

; Guard's cell during the AI: L = column, H = row (word)
;
; Scratch word of ChooseGuardMove (ChooseGuardMove): the working guard's
; position converted from a screen offset to a character cell: the low byte
; (+0, L) is the column 0-31 and the high byte (+1, H) the row 0-23. Compared
; with Horace's cell HoraceCell to find which directions approach him.
; Rewritten for every guard on every planned step; meaningless between calls.
GuardCell:
  DEFW $0000

; Direction scores of the AI (4 bytes)
;
; Scratch table filled by ChooseGuardMove (guard AI) with the score of each
; direction, indexed by direction code: +0 up, +1 right, +2 down, +3 left (0 =
; blocked or never chosen). The best-scoring direction becomes the guard's new
; direction. The Horace autopilot of the demo (ReadControls) uses the same
; table for its weights. Both scan the table backwards from GuardRecordPtr,
; which therefore marks the end; the scores are not kept between calls.
GuardDirScores:
  DEFB $00,$00,$00,$00

; Pointer to the guard record in the working buffer (word)
;
; Set by LoadGuardRecord (LoadGuardRecord) to the address of the guard record
; (GuardRecords, Guard2Record, Guard3Record or Guard4Record) that was copied
; into the working buffer GuardRecord, and used by SaveGuardRecord
; (SaveGuardRecord) as the destination when the buffer is written back. The
; loaded value is guard 1's record. It follows the four direction scores of
; GuardDirScores, and the backwards scans of ChooseGuardMove and ReadControls
; use its address as the end of that table (its contents are not read).
GuardRecordPtr:
  DEFW GuardRecords

; Working copy of one guard's state record (43 bytes)
;
; The buffer that all guard code works on: LoadGuardRecord (LoadGuardRecord)
; copies one of the four 43-byte records (GuardRecords, Guard2Record,
; Guard3Record, Guard4Record; GUARD_RECORD_SIZE) here, the routines for
; planning (ChooseGuardMove), erasing (EraseGuard), drawing (DrawGuard), bonus
; fruit (MaybeDropFruit) and eating (CheckGuardContact) change it, and
; SaveGuardRecord (SaveGuardRecord) writes it back (the source is remembered in
; GuardRecordPtr). Anything left in the buffer when the next record is loaded
; is lost. The loaded contents are a placeholder.
;
; Fields (offsets from $6DB8): +0 word: position (GuardRecord), screen offset
; (address minus $4000) of the top-left cell of the guard's 2x2-cell sprite +2
; byte: direction (GuardDir) 0 up, 1 right, 2 down, 3 left (DIR_*) +3 byte:
; animation counter (GuardAnim), incremented each time the guard is drawn; bit
; 5 picks the walking sprite set, bit 3 the frame while the guard is scared +4
; word: new position (GuardNewPos), planned by ChooseGuardMove and made the
; position by DrawGuard +6 byte: wait counter (GuardWait), 90 after the guard
; has been eaten; while it is not zero the guard is neither planned nor drawn
; +7 36 bytes: saved background (SavedBackground) of the four cells under the
; sprite, in the order top-left, top-right, bottom-left, bottom-right, nine
; bytes each (SAVED_CELL_SIZE): the attribute ($3E blank floor at the start)
; and the eight pixel rows. The cells start at $6DBF, $6DC8, $6DD1 and $6DDA.
; EraseGuard puts them back when the guard moves on and MaybeDropFruit
; overwrites them to leave a bonus fruit behind.
GuardRecord:
  DEFW $0210
GuardDir:
  DEFB $00
GuardAnim:
  DEFB $00
GuardNewPos:
  DEFW $0210
GuardWait:
  DEFB $00
SavedBackground:
  DEFB $3E,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $3E,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $3E,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $3E,$00,$00,$00,$00,$00,$00,$00,$00

; Guard 1 state record (43 bytes)
;
; State of guard 1: position, direction, animation counter, wait counter and
; the screen contents hidden under its sprite. The four guard records follow
; one another from here (GuardRecords, Guard2Record, Guard3Record,
; Guard4Record), 43 bytes (GUARD_RECORD_SIZE) each; this is the first. The
; label GuardRecords marks the start of the table and so is this record's
; label.
;
; Fields (offsets from the start of the record): +0 word: position, the screen
; offset (address minus $4000) of the top-left cell of the guard's 2x2-cell
; sprite +2 byte: direction, 0 up, 1 right, 2 down, 3 left (DIR_*) +3 byte:
; animation counter, incremented each time the guard is drawn (bit 5 picks the
; walking frame set, bit 3 the frame while the guard is scared) +4 word: new
; position, where the guard is drawn next; planned by ChooseGuardMove and made
; the position by DrawGuard +6 byte: wait counter, 90 after the guard has been
; eaten; while it is not zero the guard is neither moved nor drawn +7 36 bytes:
; saved background, the four cells under the sprite in the order top-left,
; top-right, bottom-left, bottom-right, nine bytes each: the attribute and then
; the eight pixel rows (SAVED_CELL_SIZE); EraseGuard puts it back when the
; guard moves on, and MaybeDropFruit overwrites it to leave a bonus fruit
; behind
;
; The release timer of guard 1 is the word at GuardTimers (0 at the start of a
; maze: free at once). When a maze starts, or Horace loses a life, Start puts
; the guard at the first guard position of the maze descriptor
; (MazeDescriptor+4) if its timer is zero, otherwise at the second one
; (MazeDescriptor+6, where Horace enters). LoadGuardRecord copies the record
; into the working buffer GuardRecord and SaveGuardRecord writes it back. The
; initial contents below are only a placeholder (position $0210, blank
; background): Start overwrites both positions and clears the background
; whenever it places the guards.
GuardRecords:
  DEFW $0210              ; position
  DEFB DIR_UP             ; direction
  DEFB $00                ; animation counter
  DEFW $0210              ; new position
  DEFB $00                ; wait counter
  DEFB ATTR_BLANK,$00,$00,$00,$00,$00,$00,$00,$00 ; saved cell top-left:
                                                  ; attribute, then 8 pixel
                                                  ; rows
  DEFB ATTR_BLANK,$00,$00,$00,$00,$00,$00,$00,$00 ; saved cell top-right
  DEFB ATTR_BLANK,$00,$00,$00,$00,$00,$00,$00,$00 ; saved cell bottom-left
  DEFB ATTR_BLANK,$00,$00,$00,$00,$00,$00,$00,$00 ; saved cell bottom-right

; Guard 2 state record (43 bytes)
;
; State of guard 2: position, direction, animation counter, wait counter and
; the screen contents hidden under its sprite. It is the second of the four
; 43-byte records that start at GuardRecords (GUARD_RECORD_SIZE bytes each).
;
; Fields (offsets from the start of the record): +0 word: position, the screen
; offset (address minus $4000) of the top-left cell of the guard's 2x2-cell
; sprite +2 byte: direction, 0 up, 1 right, 2 down, 3 left (DIR_*) +3 byte:
; animation counter, incremented each time the guard is drawn (bit 5 picks the
; walking frame set, bit 3 the frame while the guard is scared) +4 word: new
; position, where the guard is drawn next; planned by ChooseGuardMove and made
; the position by DrawGuard +6 byte: wait counter, 90 after the guard has been
; eaten; while it is not zero the guard is neither moved nor drawn +7 36 bytes:
; saved background, the four cells under the sprite in the order top-left,
; top-right, bottom-left, bottom-right, nine bytes each: the attribute and then
; the eight pixel rows (SAVED_CELL_SIZE); EraseGuard puts it back when the
; guard moves on, and MaybeDropFruit overwrites it to leave a bonus fruit
; behind
;
; The release timer of guard 2 is the word at Guard2Timer. When a maze starts, or
; Horace loses a life, Start puts the guard at the first guard position of the
; maze descriptor (MazeDescriptor+4) if its timer is zero, otherwise at the
; second one (MazeDescriptor+6, where Horace enters). LoadGuardRecord copies
; the record into the working buffer GuardRecord and SaveGuardRecord writes it
; back. The initial contents below are only a placeholder (position $0210,
; blank background): Start overwrites both positions and clears the background
; whenever it places the guards.
Guard2Record:
  DEFW $0210              ; position
  DEFB DIR_UP             ; direction
  DEFB $00                ; animation counter
  DEFW $0210              ; new position
  DEFB $00                ; wait counter
  DEFB ATTR_BLANK,$00,$00,$00,$00,$00,$00,$00,$00 ; saved cell top-left:
                                                  ; attribute, then 8 pixel
                                                  ; rows
  DEFB ATTR_BLANK,$00,$00,$00,$00,$00,$00,$00,$00 ; saved cell top-right
  DEFB ATTR_BLANK,$00,$00,$00,$00,$00,$00,$00,$00 ; saved cell bottom-left
  DEFB ATTR_BLANK,$00,$00,$00,$00,$00,$00,$00,$00 ; saved cell bottom-right

; Guard 3 state record (43 bytes)
;
; State of guard 3: position, direction, animation counter, wait counter and
; the screen contents hidden under its sprite. It is the third of the four
; 43-byte records that start at GuardRecords (GUARD_RECORD_SIZE bytes each).
;
; Fields (offsets from the start of the record): +0 word: position, the screen
; offset (address minus $4000) of the top-left cell of the guard's 2x2-cell
; sprite +2 byte: direction, 0 up, 1 right, 2 down, 3 left (DIR_*) +3 byte:
; animation counter, incremented each time the guard is drawn (bit 5 picks the
; walking frame set, bit 3 the frame while the guard is scared) +4 word: new
; position, where the guard is drawn next; planned by ChooseGuardMove and made
; the position by DrawGuard +6 byte: wait counter, 90 after the guard has been
; eaten; while it is not zero the guard is neither moved nor drawn +7 36 bytes:
; saved background, the four cells under the sprite in the order top-left,
; top-right, bottom-left, bottom-right, nine bytes each: the attribute and then
; the eight pixel rows (SAVED_CELL_SIZE); EraseGuard puts it back when the
; guard moves on, and MaybeDropFruit overwrites it to leave a bonus fruit
; behind
;
; The release timer of guard 3 is the word at Guard3Timer. When a maze starts, or
; Horace loses a life, Start puts the guard at the first guard position of the
; maze descriptor (MazeDescriptor+4) if its timer is zero, otherwise at the
; second one (MazeDescriptor+6, where Horace enters). LoadGuardRecord copies
; the record into the working buffer GuardRecord and SaveGuardRecord writes it
; back. The initial contents below are only a placeholder (position $0210,
; blank background): Start overwrites both positions and clears the background
; whenever it places the guards.
Guard3Record:
  DEFW $0210              ; position
  DEFB DIR_UP             ; direction
  DEFB $00                ; animation counter
  DEFW $0210              ; new position
  DEFB $00                ; wait counter
  DEFB ATTR_BLANK,$00,$00,$00,$00,$00,$00,$00,$00 ; saved cell top-left:
                                                  ; attribute, then 8 pixel
                                                  ; rows
  DEFB ATTR_BLANK,$00,$00,$00,$00,$00,$00,$00,$00 ; saved cell top-right
  DEFB ATTR_BLANK,$00,$00,$00,$00,$00,$00,$00,$00 ; saved cell bottom-left
  DEFB ATTR_BLANK,$00,$00,$00,$00,$00,$00,$00,$00 ; saved cell bottom-right

; Guard 4 state record (43 bytes)
;
; State of guard 4: position, direction, animation counter, wait counter and
; the screen contents hidden under its sprite. It is the fourth of the four
; 43-byte records that start at GuardRecords (GUARD_RECORD_SIZE bytes each).
;
; Fields (offsets from the start of the record): +0 word: position, the screen
; offset (address minus $4000) of the top-left cell of the guard's 2x2-cell
; sprite +2 byte: direction, 0 up, 1 right, 2 down, 3 left (DIR_*) +3 byte:
; animation counter, incremented each time the guard is drawn (bit 5 picks the
; walking frame set, bit 3 the frame while the guard is scared) +4 word: new
; position, where the guard is drawn next; planned by ChooseGuardMove and made
; the position by DrawGuard +6 byte: wait counter, 90 after the guard has been
; eaten; while it is not zero the guard is neither moved nor drawn +7 36 bytes:
; saved background, the four cells under the sprite in the order top-left,
; top-right, bottom-left, bottom-right, nine bytes each: the attribute and then
; the eight pixel rows (SAVED_CELL_SIZE); EraseGuard puts it back when the
; guard moves on, and MaybeDropFruit overwrites it to leave a bonus fruit
; behind
;
; The release timer of guard 4 is the word at Guard4Timer. When a maze starts, or
; Horace loses a life, Start puts the guard at the first guard position of the
; maze descriptor (MazeDescriptor+4) if its timer is zero, otherwise at the
; second one (MazeDescriptor+6, where Horace enters). LoadGuardRecord copies
; the record into the working buffer GuardRecord and SaveGuardRecord writes it
; back. The initial contents below are only a placeholder (position $0210,
; blank background): Start overwrites both positions and clears the background
; whenever it places the guards.
Guard4Record:
  DEFW $0210              ; position
  DEFB DIR_UP             ; direction
  DEFB $00                ; animation counter
  DEFW $0210              ; new position
  DEFB $00                ; wait counter
  DEFB ATTR_BLANK,$00,$00,$00,$00,$00,$00,$00,$00 ; saved cell top-left:
                                                  ; attribute, then 8 pixel
                                                  ; rows
  DEFB ATTR_BLANK,$00,$00,$00,$00,$00,$00,$00,$00 ; saved cell top-right
  DEFB ATTR_BLANK,$00,$00,$00,$00,$00,$00,$00,$00 ; saved cell bottom-left
  DEFB ATTR_BLANK,$00,$00,$00,$00,$00,$00,$00,$00 ; saved cell bottom-right
