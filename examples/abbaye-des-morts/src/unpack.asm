; Sprite set unpack records: 20 records of 6 bytes, one per packed sprite set
;
; Record n tells the unpacker UnpackSpriteSet how to turn the packed set n
; (room script op $97 n, OpUnpackSprites) into the sprite sheet at SpriteSheet.
; The sheet is a page per pixel row (the high byte of an address is the pixel
; row, the low byte the byte column) and a sprite is a run of columns read down
; the pages. The 20 records and what they hold:
;
; +0 word: destination in the sheet: page = first pixel row ($D7 row 0, $EF row
; 24), low byte = first byte column; the columns go up from there (INC E: never
; a carry into the page); the sets one room uses have different destinations,
; sets of different rooms reuse them (several start at $D763) +2 word: address
; of the packed set (PackedSetArcher..PackedSetWorm, label PackedSetN) +4 byte: flags.
; Bit 7: after each frame add three copies shifted right by 2, 4 and 6 pixels
; (the entities are positioned in 2-pixel steps, so a sprite is drawn from the
; copy for x AND 3). Bit 6: after all frames add the mirrored copy of every
; frame (columns reversed and each byte bit-reversed through the table
; RedrawPixels that BuildMirrorTable builds on room entry), used for the other
; walking direction. Other bits unused +5 byte: frame width in columns (the
; packed set holds frames x width columns)
;
; The sheet bytes written by UnpackSpriteSet for all 20 records agree with a
; model of the format described here (see finding F114).
UnpackRecords:
  DEFW $D7F8,PackedSetArcher   ; set 0: skeleton archers (rooms 17, 21)
  DEFB $40,$02
  DEFW $D763,PackedSetCrusader   ; set 1: crusaders (rooms 0, 4, 5, 6, 24 and 25,
                          ; whose script calls room 24's)
  DEFB $C0,$02
  DEFW $D763,PackedSetDeath   ; set 2: Death (room 18)
  DEFB $C0,$04
  DEFW $D7BB,PackedSetDemon   ; set 3: demons (rooms 21, 22)
  DEFB $C0,$02
  DEFW $EF63,PackedSetBird   ; set 4: birds (rooms 20, 23)
  DEFB $C0,$03
  DEFW $D768,PackedSetBeastFire   ; set 5: the fire jet of the Pestilent Beast (room
                          ; 10; BehaviourBeastFire, drawn red from $D768,
                          ; $D76A, $D76D, $D76F; F153)
  DEFB $00,$02
  DEFW $D763,PackedSetBeastHead   ; set 6: head of the Pestilent Beast (room 10); frame
                          ; width 5, but the set has only 4 columns
  DEFB $00,$05
  DEFW $D7E7,PackedSetFireWheel   ; set 7: fire wheels (rooms 22, 23)
  DEFB $00,$02
  DEFW $D763,PackedSetFlyB   ; set 8: flies, BehaviourFlyB (room 12)
  DEFB $40,$02
  DEFW $D76B,PackedSetFlyA   ; set 9: flies, BehaviourFlyA (room 12)
  DEFB $40,$02
  DEFW $D763,PackedSetHangedMan  ; set 10: hanged men (room 9)
  DEFB $40,$02
  DEFW $D763,PackedSetKnight  ; set 11: knights (rooms 15, 20)
  DEFB $C0,$02
  DEFW $D763,PackedSetChaser  ; set 12: the chasing ghost (room 11)
  DEFB $C0,$02
  DEFW $D763,PackedSetRat  ; set 13: rats (room 2)
  DEFB $C0,$02
  DEFW $D78F,PackedSetSatan  ; set 14: Satan's pieces (room 24)
  DEFB $00,$1E
  DEFW $D763,PackedSetBat  ; set 15: red bats (room 8)
  DEFB $80,$02
  DEFW $D7EA,PackedSetScythe  ; set 16: Death's scythe (room 18), two frames of
                          ; 32 rows, each drawn as an upper and a lower
                          ; 16-row picture ($D7EA/$D7F5, $E7EA/$E7F5;
                          ; F153)
  DEFB $80,$02
  DEFW $D763,PackedSetSkeleton  ; set 17: skeletons (rooms 13, 22)
  DEFB $C0,$02
  DEFW $D78F,PackedSetCeilingGhost  ; set 18: ceiling ghosts (rooms 22, 23)
  DEFB $C0,$02
  DEFW $D7F5,PackedSetWorm  ; set 19: worms (rooms 9, 14)
  DEFB $80,$02

; Unpack a packed sprite set into the sprite sheet
;
; Script op $97 (OpUnpackSprites) calls this once per sprite set a room needs.
; It reads record A of UnpackRecords (destination DE in the sheet at
; SpriteSheet, source set address, flags, frame width N) and the 2-byte header
; of the packed set (B = columns, C = character rows of 8 pixel rows). For each
; frame of N columns it unpacks the columns (UnpackColumns) and, if flag bit 7
; is set, adds the three copies shifted by 2, 4 and 6 pixels
; (ShiftFrameCopies), so a frame takes N + 3 x (N + 1) columns. If flag bit 6
; is set it then makes a mirrored copy of every frame (MirrorFrame), again with
; the shifted copies when bit 7 is set, placed after all the unmirrored frames.
; The mirror uses the table RedrawPixels built by BuildMirrorTable on room
; entry. The routine only reads and writes memory and uses the alternate AF,
; which it does not preserve; HL, DE and BC are clobbered.
;
; Hardware: none. The sprite sheet is plain memory; the sprite drawers
; (DrawStripW1-DrawStripW5, through DispatchDrawer) read it later.
;
; A Sprite set number 0-19 (record number)
UnpackSpriteSet:
  LD L,A
  ADD A,A
  ADD A,L
  ADD A,A                 ; A = 6 x set
  LD HL,UnpackRecords     ; record table
  CALL AddAToHL           ; HL = record
  LD E,(HL)               ; DE = destination in the sprite sheet
  INC HL
  LD D,(HL)
  INC HL
  LD C,(HL)
  INC HL
  LD B,(HL)               ; BC = address of the packed set
  INC HL
  LD A,(HL)               ; flags
  INC HL
  EX AF,AF'               ; A' = flags
  LD A,(HL)               ; A = frame width N
  LD H,B
  LD L,C
  LD B,(HL)               ; B = columns in the set
  INC HL
  LD C,(HL)               ; C = character rows
  INC HL                  ; HL = first flag byte
  PUSH BC                 ; keep columns and rows for the mirror pass
  PUSH DE                 ; and the start of the sheet columns
UnpackSpriteSet_Frame:
  PUSH DE                 ; start of this frame
  CALL UnpackColumns      ; unpack N columns
  EX (SP),HL              ; HL = start of the frame, stack = packed stream
  EX AF,AF'               ; A = flags
  CALL ShiftFrameCopies   ; bit 7: three shifted copies after the frame
  EX AF,AF'               ; A = N
  POP HL                  ; HL = packed stream
  DJNZ UnpackSpriteSet_Frame ; next frame
  POP HL                  ; HL = start of the first frame
  POP BC                  ; B = columns, C = rows
  EX AF,AF'               ; A = flags
  BIT 6,A
  RET Z                   ; no mirrored copies
  EX AF,AF'               ; A = N
UnpackSpriteSet_Mirror:
  PUSH DE                 ; start of this mirrored frame
  CALL MirrorFrame        ; mirror one frame from HL to DE
  EX (SP),HL              ; HL = start of the mirrored frame, stack = next
                          ; source frame
  EX AF,AF'               ; A = flags
  CALL ShiftFrameCopies   ; shifted copies of the mirrored frame
  POP HL                  ; HL = next source frame ...
  CALL SkipShiftedCopies  ; ... past its shifted copies, if there are any
  EX AF,AF'               ; A = N
  DJNZ UnpackSpriteSet_Mirror
  RET

; Unpack N columns of a packed sprite set
;
; The packed format, per column: for each character row (8 pixel rows) one flag
; byte, most significant bit first; for each bit a set bit means that a literal
; byte follows in the stream and becomes the next pixel byte, a clear bit
; repeats the previous pixel byte of the column (0 at the top of a column). So
; a run of equal bytes costs one flag bit. Each pixel byte goes to the next
; page (INC D): pixel row 0 at the destination, row 1 in the page above, and so
; on; then the next column is the next byte of the page (INC E). Stops after N
; columns or when the set has no more columns (B is counted down once per
; column, the caller's DJNZ takes the last one of a frame).
;
;   A Frame width N: columns to unpack in this call
;   B Columns of the set left to unpack
;   C Character rows of the set
;   HL Packed stream, at a flag byte
;   DE Destination: D = page of pixel row 0, E = column
; O:A N
; O:B Columns left, less N - 1 (1 when the set ran out first)
; O:HL Packed stream after the columns
; O:DE Destination of the next column (E + N)
UnpackColumns:
  PUSH AF                 ; N
UnpackColumns_Column:
  PUSH BC
  PUSH DE
  PUSH AF
  XOR A                   ; the pixel byte "so far" is 0 at the top of a column
UnpackColumns_Row:
  LD B,(HL)               ; flag byte of a character row
  INC HL
  SCF
  RL B                    ; carry = first flag bit, a marker bit enters at the
                          ; bottom to end the loop after 8 bits
UnpackColumns_0:
  JR NC,UnpackColumns_1   ; clear: repeat the previous byte
  LD A,(HL)               ; set: a literal byte
  INC HL
UnpackColumns_1:
  LD (DE),A
  INC D                   ; next pixel row
  SLA B
  JR NZ,UnpackColumns_0
  DEC C
  JR NZ,UnpackColumns_Row ; next character row
  POP AF
  POP DE
  POP BC
  INC E                   ; next column
  DEC A
  JR Z,UnpackColumns_2    ; N columns done
  DJNZ UnpackColumns_Column ; more columns in the set
  INC B                   ; the set ran out: B = 1 for the caller's DJNZ
UnpackColumns_2:
  POP AF
  RET

; Add the three pre-shifted copies of a frame
;
; Does nothing unless flag bit 7 of the set is set (A). The frame (N columns,
; rows of pixel pages) is at HL; the copies are written after it at DE, one
; pixel line (page) at a time: copy 1 is the frame shifted right by 2 pixels
; and is N + 1 columns wide (a zero byte is appended to take the bits shifted
; out), copy 2 is copy 1 shifted by 2 more pixels and copy 3 copy 2 shifted by
; 2 more, both N + 1 columns wide as well (the bits that leave the last column
; are lost). The 2-pixel shift is two calls of ShiftPixelLine. A frame so takes
; N + 3 x (N + 1) columns, which the entity code relies on when it picks the
; copy for x AND 3 (the shift tables, ShiftPairs). On return DE is the
; destination after the copies and HL the source plus 3 x N + 3.
;
;   A Flags of the set: bit 7 makes the copies
;   A' Frame width N
;   C Character rows of the frame
;   HL Start of the frame, the column in L, the page of pixel row 0 in H
;   DE Destination of the copies: the column after the frame, same page
; O:A Flags
; O:A' N
; O:HL Source column + 3 x N + 3
; O:DE Destination column + 3 x N + 3 (low byte only)
ShiftFrameCopies:
  BIT 7,A
  RET Z
  EX AF,AF'               ; A = N
  PUSH BC
  PUSH AF
  LD A,C                  ; A = character rows
  POP BC                  ; B = N
  PUSH BC
  LD C,B                  ; C = N, the columns per pixel line
  LD B,A
  SLA B
  SLA B
  SLA B                   ; B = pixel lines (pages) = 8 x rows
  PUSH HL
  PUSH DE
ShiftFrameCopies_Line:
  PUSH BC
  PUSH HL
  PUSH DE
  CALL CopyPixelLine      ; copy 1 = the line, N bytes (HL ends N bytes on, at
                          ; the new copy)
  XOR A
  LD (DE),A               ; a zero byte after it
  INC E
  INC C                   ; N + 1 bytes from now on
  CALL ShiftPixelLine     ; shift copy 1 right by 1 pixel ...
  CALL ShiftPixelLine     ; ... and by 1 more: 2 pixels
  CALL CopyPixelLine      ; copy 2 = copy 1 (N + 1 bytes)
  CALL ShiftPixelLine     ; shifted by 2 pixels more
  CALL ShiftPixelLine
  CALL CopyPixelLine      ; copy 3 = copy 2
  CALL ShiftPixelLine     ; shifted by 2 pixels more
  CALL ShiftPixelLine
  POP DE
  POP HL
  POP BC
  INC H                   ; next pixel line, source ...
  INC D                   ; ... and destination
  DJNZ ShiftFrameCopies_Line
  POP DE
  POP HL
  LD A,C                  ; N
  ADD A,A
  ADD A,C
  INC A
  INC A
  INC A                   ; 3 x N + 3
  PUSH AF
  ADD A,E
  LD E,A
  POP AF
  ADD A,L
  LD L,A
  POP AF                  ; A = N
  POP BC
  EX AF,AF'               ; A = flags again, A' = N
  RET

; Make a horizontally mirrored copy of a frame
;
; For every pixel line (page) of the frame at HL it reads the N columns
; backwards (from the last column to the first), reverses the bits of each byte
; through MirrorPixelLine and writes them forwards at DE, which makes the
; picture face the other way. HL and DE are then moved on by N columns and B
; counted down like UnpackColumns does (once per column except the last of the
; frame, which is left to the caller's DJNZ; B = 1 on return when the set ran
; out).
;
;   A Frame width N
;   B Columns of the set left
;   C Character rows
;   HL Start of the frame: column in L, page of pixel row 0 in H
;   DE Destination: column in E, same page numbers as the source
; O:A N
; O:B Columns left, less N - 1
; O:HL Start of the next source frame
; O:DE Destination after the mirrored frame
MirrorFrame:
  PUSH AF
  PUSH HL
  PUSH DE
  PUSH BC
  PUSH AF
  LD B,C
  LD C,A                  ; C = N
  SLA B
  SLA B
  SLA B                   ; B = pixel lines = 8 x rows
  DEC A
  ADD A,L
  LD L,A                  ; HL = last column of the frame
MirrorFrame_Line:
  PUSH HL
  PUSH DE
  PUSH BC
  CALL MirrorPixelLine    ; mirror one pixel line
  POP BC
  POP DE
  POP HL
  INC H                   ; next pixel line
  INC D
  DJNZ MirrorFrame_Line
  POP AF
  POP BC
  POP DE
  POP HL
MirrorFrame_Advance:
  INC L                   ; move on by N columns, as UnpackColumns does for its
                          ; columns
  INC E
  DEC A
  JR Z,MirrorFrame_0
  DJNZ MirrorFrame_Advance
  INC B
MirrorFrame_0:
  POP AF
  RET

; Copy a run of bytes along one pixel line
;
; The source and destination are columns of one page each, so only L and E
; move.
;
;   C Bytes to copy
;   HL Source
;   DE Destination
; O:B 0
; O:HL Source + C (low byte only)
; O:DE Destination + C (low byte only)
CopyPixelLine:
  LD B,C
CopyPixelLine_Byte:
  LD A,(HL)
  LD (DE),A
  INC L
  INC E
  DJNZ CopyPixelLine_Byte
  RET

; Shift a run of bytes along one pixel line right by one pixel
;
; Rotates the C bytes from (HL) right through the carry, left byte first, with
; a clear carry at the start: the whole run moves one bit to the right, a 0
; enters on the left and the bit leaving the last byte is lost. L is restored.
;
;   C Bytes in the run
;   HL Start of the run
; O:A L
; O:B 0
ShiftPixelLine:
  LD A,L
  LD B,C
  OR A
ShiftPixelLine_Byte:
  RR (HL)
  INC L
  DJNZ ShiftPixelLine_Byte
  LD L,A
  RET

; Mirror one pixel line: copy bytes backwards with their bits reversed
;
; Reads C bytes from (HL) downwards (DEC L) and writes them upwards from DE,
; each byte replaced by its bit-reversed value from the table at RedrawPixels
; (built by BuildMirrorTable on room entry): the line is flipped left to right.
; Sets the alternate HL' to $C5 for the table and uses its L' as the index, so
; the alternate set is clobbered.
;
; C Bytes in the line
; HL Address of the last byte of the source line
; DE Destination
MirrorPixelLine:
  EXX
  LD H,MIRROR_TABLE_PAGE  ; H' = page of the bit-reverse table
  EXX
  LD B,C
MirrorPixelLine_Byte:
  LD A,(HL)
  EXX
  LD L,A                  ; L' = the byte
  LD A,(HL)               ; its reverse from the table
  EXX
  LD (DE),A
  DEC L
  INC E
  DJNZ MirrorPixelLine_Byte
  RET

; Step the source pointer past the shifted copies of a frame
;
; Does nothing unless flag bit 7 (A) is set; then adds 3 x N + 3 to L, the
; three copies that ShiftFrameCopies added after the frame (N + 1 columns each,
; N is in A'). Used by the mirror pass of UnpackSpriteSet, which reads the
; plain frames only.
;
;   A Flags of the set: bit 7 = the frames have shifted copies
;   A' Frame width N
;   HL Source column
; O:HL Source column + 3 x N + 3 (low byte only), or unchanged
SkipShiftedCopies:
  BIT 7,A
  RET Z
  EX AF,AF'               ; A = N
  PUSH AF
  PUSH BC
  LD C,A
  ADD A,A
  ADD A,C                 ; 3 x N
  INC A
  INC A
  INC A
  ADD A,L
  LD L,A
  POP BC
  POP AF
  EX AF,AF'               ; back as on entry
  RET
