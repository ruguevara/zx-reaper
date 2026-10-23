; Leave the room through the left exit
;
; Makes the left neighbour (byte $E9 of the room, $80E9) the current room and
; puts Willy on column 30 of the same row: his attribute address
; (WillyAttrAddr) gets column bits 11110. Willy's other state is kept. Pops the
; caller's return address and jumps to EnterRoom, which loads the new room and
; restarts the game loop, so it never returns.
;
; Reached when Willy walks off column 0 (jump from MoveWilly). Observed in the
; simulator (finding F21).
ExitRoomLeft:
  LD A,(RoomExitLeft)
  LD (CurrentRoom),A      ; new current room
  LD A,(WillyAttrAddr)
  OR COLUMN_MASK
  AND ~1                  ; column = 30 (low 5 bits 11110), row bits unchanged
  LD (WillyAttrAddr),A
  POP HL                  ; drop the return address
  JP EnterRoom            ; load the new room

; Leave the room through the right exit
;
; Makes the right neighbour (byte $EA of the room, $80EA) the current room and
; puts Willy on column 0 of the same row (column bits of his attribute address
; WillyAttrAddr cleared). Pops the caller's return address and jumps to
; EnterRoom, which loads the new room and restarts the game loop, so it never
; returns.
;
; Reached when Willy walks past column 31 (jump from MoveWilly).
ExitRoomRight:
  LD A,(RoomExitRight)
  LD (CurrentRoom),A      ; new current room
  LD A,(WillyAttrAddr)
  AND ~COLUMN_MASK        ; column = 0, row bits unchanged
  LD (WillyAttrAddr),A
  POP HL                  ; drop the return address
  JP EnterRoom            ; load the new room

; Leave the room through the top: enter the room above at its bottom
;
; Makes the room above (byte $EB of the room, $80EB) the current room and puts
; Willy at the bottom: Willy's attribute address (WillyAttrAddr/85D4) gets row
; 5 of the lower half (row 13 of the room, attribute page $5D), the column is
; kept, Willy's Y (WillyY) becomes $D0 (twice the pixel row, 104) and the
; jump/fall state WillyAirState is cleared. Pops the caller's return address
; and jumps to EnterRoom, so it never returns.
;
; Reached when Willy's Y wraps past the top (from MoveWilly when Y >= $F0 after
; moving up, and from FrameLoop when Y >= $E1).
ExitRoomUp:
  LD A,(RoomExitUp)
  LD (CurrentRoom),A      ; new current room
  LD A,(WillyAttrAddr)
  AND COLUMN_MASK         ; keep the column, clear the row bits
  ADD A,SCREEN_COLS*(Y_LOW_FLOOR/Y_ROW_STEP-CELL_HEIGHT) ; row bits 101 = row 5
  LD (WillyAttrAddr),A
  LD A,$01+(SCREEN_ATTRS_BUF>>8) ; attribute page of the lower half
  LD (WillyAttrAddr+$0001),A
  LD A,Y_LOW_FLOOR        ; Y = 104 pixel rows * 2
  LD (WillyY),A
  XOR A
  LD (WillyAirState),A    ; jump/fall state 0 (TODO: confirm meaning of
                          ; WillyAirState)
  POP HL                  ; drop the return address
  JP EnterRoom            ; load the new room

; Leave the room through the bottom: enter the room below at its top
;
; Makes the room below (byte $EC of the room, $80EC) the current room and puts
; Willy at the top: Y (WillyY) is set to 0, the row bits of his attribute
; address (WillyAttrAddr) are cleared with the column kept, and the attribute
; page (85D4) is $5C (upper half). If the jump/fall state WillyAirState is
; below $0B it is set to 2 (TODO: confirm that this starts a fall); larger
; values are kept. Pops the caller's return address and jumps to EnterRoom, so
; it never returns.
;
; Reached from MoveWilly when Willy's attribute address moves past the bottom
; of the lower half (bit 1 of H set after adding $40).
ExitRoomDown:
  LD A,(RoomExitDown)
  LD (CurrentRoom),A      ; new current room
  XOR A
  LD (WillyY),A           ; Y = 0
  LD A,(WillyAirState)
  CP AIR_FATAL_FALL-$01
  JR NC,ExitRoomDown_Column
  LD A,AIR_FALL_START
  LD (WillyAirState),A
ExitRoomDown_Column:
  LD A,(WillyAttrAddr)
  AND COLUMN_MASK         ; row 0, same column
  LD (WillyAttrAddr),A
  LD A,SCREEN_ATTRS_BUF>>8 ; attribute page of the upper half
  LD (WillyAttrAddr+$0001),A
  POP HL                  ; drop the return address
  JP EnterRoom            ; load the new room

; Animate the conveyor belt of the room
;
; Uses the conveyor fields of the current room: direction (byte $D6, $80D6),
; address (word at $D7, $80D7) and length in cells (byte $D9, $80D9). The
; address is an attribute address in the empty-room buffer ($5E00-$5FFF): bit 0
; of its high byte selects the upper or lower half of the room and the low byte
; is row-in-half * 32 + column, so the routine turns it into the address of the
; first cell in the empty-room screen buffer (page $70 or $78). Nothing happens
; when the length is 0.
;
; The routine reads pixel row 0 and pixel row 2 of the FIRST cell only and
; rotates them by two bits in opposite directions (direction 0: row 0 left, row
; 2 right; direction non-zero: row 0 right, row 2 left). The two results are
; then stored into row 0 and row 2 of every cell of the belt, so all cells end
; up identical (the belt tile is assumed to be the same in every cell). The
; other pixel rows are not changed. The change is made in the master copy, so
; it accumulates from pass to pass; FrameLoop copies the master into the screen
; buffer every pass. Observed: in the Bathroom (4 cells) row 0 of all four
; cells goes $A5, $96, $5A, $69, $A5... (rotation left by two bits per pass).
;
; Hardware: none (memory only).
AnimateConveyor:
  LD HL,(RoomConveyorAddr)
  LD A,H
  AND $01                 ; bit 0: lower half
  RLCA
  RLCA
  RLCA
  ADD A,ROOM_PIXEL_BUF>>8 ; $70 or $78: empty-room screen buffer page
  LD H,A
  LD E,L
  LD D,H                  ; DE = HL = pixel row 0 of the first cell
  LD A,(RoomConveyorLen)
  OR A
  RET Z
  LD B,A                  ; B = number of cells
  LD A,(RoomConveyorDir)
  OR A
  JR NZ,AnimateConveyor_0
  LD A,(HL)
  RLC A
  RLC A
  INC H
  INC H
  LD C,(HL)
  RRC C
  RRC C
AnimateConveyor_Cell:
  LD (DE),A               ; store pixel row 0 (same value in every cell)
  LD (HL),C               ; store pixel row 2
  INC L
  INC E
  DJNZ AnimateConveyor_Cell
  RET
AnimateConveyor_0:
  LD A,(HL)
  RRC A
  RRC A
  INC H
  INC H
  LD C,(HL)
  RLC C
  RLC C
  JR AnimateConveyor_Cell
