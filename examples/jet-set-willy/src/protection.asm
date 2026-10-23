; Colour-code protection: two attempts, then reset
;
; Reached by the RET at the end of StartProgram, never called. Clears the
; bitmap and the attributes to zero (black on black), then calls AskColourCode
; with the prompt "Enter Code at grid location" (EnterCodeText). If the code
; was right (Z set) the game goes on at NewGame. Otherwise AskColourCode is
; called again with "Sorry, try code at location" (TryAgainText); it shows a
; different grid cell, because AskColourCode adds to FRAMES every time. A
; second wrong code jumps to $0000, which restarts the machine through the ROM.
; Checked in the simulator with wrong codes: the second prompt appears and the
; second miss reaches PC=$0000.
;
; Hardware: writes the whole screen (bitmap and attributes); JP 0 resets the
; machine.
RunCodeCheck:
  LD HL,SCREEN
  LD DE,SCREEN+$0001
  LD BC,SCREEN_AND_ATTRS_SIZE-$0001
  LD (HL),$00
  LDIR
  LD IX,EnterCodeText     ; first attempt message
  CALL AskColourCode
  JP Z,NewGame            ; code correct: continue with the game
  LD IX,TryAgainText      ; second attempt message
  CALL AskColourCode
  JP Z,NewGame
  JP $0000                ; wrong twice: reset

; Show the colour-code screen and read the player's answer
;
; Draws the message line (32 characters at IX, ROM font) on screen row 8, the
; four coloured key graphics 1-4 (CodeKeyGraphics, 16x16 each) at columns 2, 5,
; 8 and 11 of rows 10-11, and copies the attributes CodeScreenAttrs to rows
; 8-11 ($5900-$597F). That leaves four empty 2x2-cell colour slots at columns
; 16, 19, 22 and 25 of rows 10-11 (attribute addresses $5950, $5953, $5956,
; $5959).
;
; Grid cell: FRAMES ($5C78) is increased by $25 and stored back. If the result
; is below $B3 it is the cell index L, otherwise L = result-$B4 (see the quirk
; below). The expected code byte is CodeTable[L]+L, stored in ScratchByte. The
; cell is shown as a letter 'A'+(L mod 18) at column 29 and a digit '0'+(L div
; 18) at column 30 of row 8, i.e. a grid of 18 columns (A-R) by 10 rows (0-9).
; With the simulator's FRAMES=$12 the first cell is L=$37, "B3". Checked in the
; simulator for all 256 start values of FRAMES: the stored code byte and the
; new FRAMES always matched this rule.
;
; Quirk: a result of exactly $B3 (FRAMES was $8E) is not below $B3, so SUB $B4
; runs and gives L=$FF. The code is then taken from $9EFF, outside the 180
; cells, and the location shown is ">D" (row digit '0'+14). Index $B3 itself,
; the last cell (row 9, column R), is never produced, so one cell is unused.
;
; Then it loops forever over the four slots calling ReadCodeSlot for each one,
; and starts again at slot 1 after slot 4. The loop is left only inside
; ReadCodeSlot: when ENTER is pressed with slot 4 filled, ReadCodeSlot discards
; its return address and returns from this routine instead, with Z set if the
; code is right.
;
; Hardware: writes the screen bitmap and attributes; FRAMES is read as a source
; of a pseudo-random number. Interrupts are off, so FRAMES does not change
; during the screen except through this routine.
;
; IX Message text (32 characters) O:F Z set if the entered code matches
AskColourCode:
  LD DE,SCREEN+THIRD_SIZE ; screen row 8
  LD C,SCREEN_COLS
  CALL PrintText          ; print the message
  LD HL,SCREEN+THIRD_SIZE+$0002*SCREEN_COLS+$0002 ; row 10, column 2
  LD DE,CodeKeyGraphics
  LD C,$00                ; overwrite mode
  CALL DrawSprite         ; key 1 graphic (DE advances by 32 bytes per call)
  LD HL,SCREEN+THIRD_SIZE+$0002*SCREEN_COLS+$0005
  CALL DrawSprite         ; key 2
  LD HL,SCREEN+THIRD_SIZE+$0002*SCREEN_COLS+$0008
  CALL DrawSprite         ; key 3
  LD HL,SCREEN+THIRD_SIZE+$0002*SCREEN_COLS+$000B
  CALL DrawSprite         ; key 4
  LD HL,CodeScreenAttrs
  LD DE,ATTRS+THIRD_ATTRS_SIZE
  LD BC,$0004*SCREEN_COLS ; four rows of attributes
  LDIR
  LD A,(FRAMES)
  ADD A,CODE_GRID_STEP
  LD (FRAMES),A
  CP CODE_GRID_CELLS-$01
  JR C,AskColourCode_Cell
  SUB CODE_GRID_CELLS
AskColourCode_Cell:
  LD L,A                  ; L = grid cell index
  LD H,CodeTable>>8
  LD A,(HL)
  ADD A,L                 ; expected code = table byte + cell index
  LD (ScratchByte),A
  LD C,L
  LD E,'0'-$01            ; E counts the rows: becomes '0' on the first pass
AskColourCode_Row:
  INC E
  LD A,C
  CP CODE_GRID_COLS
  JR C,AskColourCode_0
  SUB CODE_GRID_COLS
  LD C,A                  ; C ends as the column 0-17
  JR AskColourCode_Row
AskColourCode_0:
  LD A,E                  ; the row digit
  LD DE,SCREEN+THIRD_SIZE+$001E ; row 8, column 30
  CALL PrintChar
  LD A,C
  ADD A,'A'               ; the column letter
  LD DE,SCREEN+THIRD_SIZE+$001D ; row 8, column 29
  CALL PrintChar
AskColourCode_Slots:
  LD IX,CODE_SLOT_1_ATTR
AskColourCode_1:
  CALL ReadCodeSlot       ; read one slot
  INC IX
  INC IX
  INC IX                  ; next slot, 3 attribute cells to the right
  LD A,IXL
  CP CODE_SLOT_END
  JR NZ,AskColourCode_1
  JR AskColourCode_Slots  ; after slot 4 start again with slot 1

; Read one colour key into a slot, or check the code on ENTER
;
; Called by AskColourCode once per slot. Waits until keys 1-4 are all up, then
; loops: - ENTER (and slot 4 already filled): checks the code and returns to
; the caller of AskColourCode (see below). - key 1, 2, 3 or 4 alone: paints the
; 2x2 cells of the slot with that colour (paper blue, red, magenta, green),
; waits about 23 ms and returns, so AskColourCode moves on to the next slot. -
; anything else (several keys, key 5, nothing): the slot is set flashing (bit 7
; of its four attributes) as a cursor and the loop goes on.
;
; Slots are cycled forever, so a filled slot flashes in its colour when its
; turn comes round again and can be overwritten by a later pass. ENTER is
; ignored while the attribute of slot 4 is still the empty value $07 (flash bit
; ignored).
;
; The code byte is built from the paper colours of the slots 1-4 (index 0-3 =
; key number minus 1): slot 1 in bits 7-6, slot 2 in bits 5-4, slot 3 in bits
; 3-2, slot 4 in bits 1-0. It is compared with ScratchByte. The routine then
; does POP HL, throwing away its return address to AskColourCode, so the RET
; after the compare returns to the caller of AskColourCode (RunCodeCheck) with
; the flags of the comparison: Z set if the code is right. Checked in the
; simulator: 4-2-3-2 for grid cell B3 is accepted (code $D9); 1,2,3,2 then a
; new key 4 over slot 1 and ENTER is accepted too; ENTER after three slots does
; nothing.
;
; Hardware: reads keyboard half rows 1-5 (port $F7FE) and H-ENTER (port $BFFE);
; writes screen attributes; a timing loop of 24*256 DJNZ passes as debounce.
;
; IX Attribute address of the slot's top-left cell O:F Z set if ENTER ended the
; input and the code is right (see above)
ReadCodeSlot:
  LD BC,KEYROW_1_5
  IN A,(C)
  AND KEYS_1_4_MASK
  CP KEYS_1_4_MASK        ; wait until keys 1-4 are released
  JR NZ,ReadCodeSlot
ReadCodeSlot_Poll:
  LD B,KEYROW_H_ENTER_HI
  IN A,(C)
  BIT 0,A                 ; ENTER (bit set = not pressed)
  JR NZ,ReadCodeSlot_Key
  LD A,(CODE_SLOT_4_ATTR)
  AND $FF-FLASH
  CP CODE_SLOT_EMPTY      ; slot 4 not filled yet: ignore ENTER
  JR Z,ReadCodeSlot_Key
  SUB BLUE*PAPER          ; slot 4: paper colour minus blue, as 0-3 in bits 4-3
  AND CODE_PAPER_MASK
  RRCA
  RRCA
  RRCA                    ; to bits 1-0
  LD C,A
  LD A,(CODE_SLOT_2_ATTR) ; slot 2
  SUB BLUE*PAPER
  AND CODE_PAPER_MASK
  RLCA                    ; to bits 5-4
  OR C
  LD C,A
  LD A,(CODE_SLOT_3_ATTR) ; slot 3
  SUB BLUE*PAPER
  AND CODE_PAPER_MASK
  RRCA                    ; to bits 3-2
  OR C
  LD C,A
  LD A,(CODE_SLOT_1_ATTR) ; slot 1
  SUB BLUE*PAPER
  AND CODE_PAPER_MASK
  RLCA
  RLCA
  RLCA                    ; to bits 7-6
  POP HL                  ; discard the return address into AskColourCode
  OR C                    ; A = the entered code
  LD HL,ScratchByte
  CP (HL)                 ; Z if equal
  RET                     ; returns to the caller of AskColourCode
ReadCodeSlot_Key:
  SET 7,(IX+$00)          ; flash the slot as a cursor
  SET 7,(IX+$01)
  SET 7,(IX+SCREEN_COLS)
  SET 7,(IX+SCREEN_COLS+$01)
  LD BC,KEYROW_1_5
  IN A,(C)
  AND KEYS_1_4_MASK
  LD E,BLUE*PAPER
  CP KEY_1_ONLY
  JR Z,ReadCodeSlot_Paint
  LD E,RED*PAPER
  CP KEY_2_ONLY
  JR Z,ReadCodeSlot_Paint
  LD E,MAGENTA*PAPER
  CP KEY_3_ONLY
  JR Z,ReadCodeSlot_Paint
  LD E,GREEN*PAPER
  CP KEY_4_ONLY
  JP NZ,ReadCodeSlot_Poll ; no single colour key: poll again
ReadCodeSlot_Paint:
  LD (IX+$00),E           ; fill the slot with the colour (clears the flash
                          ; bit)
  LD (IX+$01),E
  LD (IX+SCREEN_COLS),E
  LD (IX+SCREEN_COLS+$01),E
  LD BC,DEBOUNCE_LOOPS    ; debounce delay, about 23 ms
ReadCodeSlot_0:
  DJNZ ReadCodeSlot_0
  DEC C
  JR NZ,ReadCodeSlot_0
  RET
