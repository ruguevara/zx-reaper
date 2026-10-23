; Busy-wait delay
;
; Spins BC times in a four-instruction loop (26 T-states per pass). Used by the
; main loop of PaceAndChime to set the game speed: the larger BC, the slower
; the game. BC=0 gives 65536 passes. Hardware: timing loop, no screen or port
; access (the CPU speed sets the delay).
;
;   BC Number of loop passes
; O:BC 0
Delay:
  DEC BC
  LD A,B
  OR C
  JR NZ,Delay
  RET

; Get a pseudo-random byte
;
; Reads the byte at the pointer kept at RandomPtr and advances the pointer by
; one, wrapping it inside $0000-$1FFF. That range is the Spectrum ROM, so the
; ROM contents serve as the random sequence; the pointer is seeded from FRAMES
; in the routine at Start. Used for random choices such as the direction
; weights in ReadControls and the delay and kind of the next bonus item in
; MaybeDropFruit. Hardware: reads the ROM.
;
; O:A Random byte
; O:HL Pointer to the next ROM byte (already stored back)
GetRandom:
  LD HL,(RandomPtr)
  LD A,(HL)
  PUSH AF
  INC HL
  LD A,H
  AND ROM_HIGH_MASK
  LD H,A
  LD (RandomPtr),HL
  POP AF
  RET

; Print a 5-digit decimal number
;
; Prints HL as exactly five decimal digits (leading zeros are printed) in the
; character cells starting at DE, using PrintDigit and PrintChar. Used for the
; score and the best score on the status line. Nothing is drawn while bit 0 of
; the flag at GameActive is clear (demo mode). Hardware: writes the screen
; bitmap and attributes (via SetAttrPointer and PrintChar).
;
;   DE Screen address of the first digit (first pixel row of the cell)
;   HL Number to print (0-65535)
; O:DE Screen address of the cell after the last digit
; O:HL Units digit (0-9)
; O:A ASCII "0" when printing is enabled
; O:BC 10
PrintNumber:
  EX DE,HL
  CALL SetAttrPointer
  EX DE,HL
  LD A,CHAR_0
  AND A
  LD BC,$2710
  CALL PrintDigit
  LD BC,$03E8
  CALL PrintDigit
  LD BC,$0064
  CALL PrintDigit
  LD BC,$000A
  CALL PrintDigit
; The remainder is the units digit
  LD A,L
  ADD A,CHAR_0
  CALL PrintChar
  RET

; Print one digit of a number, then the character
;
; Digit part: finds how many times the power of ten BC fits into HL by repeated
; subtraction, leaving the remainder in HL, and turns the count into the ASCII
; digit by adding it to A. Then falls through to PrintChar to print it.
;
;   A ASCII code of "0" (the digit count is added to it), carry flag clear
;   BC Power of ten to divide by (10000, 1000, 100 or 10)
;   DE Screen address of the character cell to print at
;   HL Number to print
; O:A ASCII code of "0" again (see PrintChar)
; O:DE Screen address of the next character cell
; O:HL Remainder of the number
PrintDigit:
  INC A
  SBC HL,BC
  JR NC,PrintDigit
  ADD HL,BC
  DEC A
; Print a character Draws the character A from the ROM font in the cell at DE,
; in black ink on white paper, and sets the cell's attribute through HL' (see
; SetAttrPointer), when printing is enabled. Printing is enabled while bit 0 of
; the flag at GameActive is set; when it is clear (the demo), the routine
; returns at once and the screen is left alone. The routine at SetAttrPointer
; must have been called for DE's cell before the first character of a string;
; HL' then advances with DE. Hardware: reads the character set of the ROM at
; $3D00 and writes the screen bitmap and attributes. A Character code ($20-$7F;
; $7F gives the ROM copyright glyph) DE Screen address of the cell (first pixel
; row) O:A ASCII code of "0", zero flag clear, carry flag clear (when printed);
; A is unchanged when printing is disabled O:DE Screen address of the next cell
; (unchanged when disabled) HL, BC Preserved
PrintChar:
  PUSH BC
  PUSH AF
  LD A,(GameActive)
  LD B,A
  POP AF
  BIT 0,B
  POP BC
  RET Z
; Swap so that HL is the screen address and DE the saved HL; then HL becomes
; the font address of the character: A*8 + (font base - 8 * space).
  EX DE,HL
  PUSH BC
  PUSH DE
  EX DE,HL
  LD H,$00
  LD L,A
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,ROM_CHARSET-CHAR_SPACE*CELL_BYTES
  ADD HL,BC
  EX DE,HL
  LD C,WHITE*PAPER+BLACK
  CALL DrawCell
  POP DE
  POP BC
  EX DE,HL
  LD A,CHAR_0
  AND A
  RET

; Draw a maze map
;
; Draws a map of tile codes (one byte per character cell) on the screen. First
; every cell's attribute byte is set from its tile code (empty yellow ink,
; flowers green, arrows black, tile 9 white on white, every other tile - walls
; and corners - cyan; all on white paper), then the 8-byte bitmap of each tile
; is copied from the tile graphics table (tile code * 8). Cells go left to
; right, then down. The game draws a whole maze with BC=$0300 (32x24 cells).
; Hardware: writes the attribute area and the screen bitmap; the attribute
; address is derived from the screen address with SetAttrPointer, and the cell
; loop uses the alternate register set for it.
;
;   HL Address of the map (tile codes)
;   DE Screen address of the first cell (its top pixel row)
;   BC Number of cells
; O:HL Address after the map
; O:DE Screen address after the last cell
; O:BC 0
DrawMaze:
  PUSH BC
  PUSH HL
  EX DE,HL
  CALL SetAttrPointer     ; HL' = attribute address of the first cell
  EX DE,HL
  EXX                     ; now HL=attributes, DE=map, BC=count
  POP DE
  POP BC
DrawMaze_0:
  LD A,(DE)               ; pass 1: attributes
  INC DE
  CP TILE_EMPTY
  JR Z,DrawMaze_3
  CP TILE_FLOWER
  JR Z,DrawMaze_4
  CP TILE_ARROW
  JR Z,DrawMaze_1
  CP TILE_BLANK_WHITE
  JR Z,DrawMaze_2
  LD A,WHITE*PAPER+CYAN   ; walls and corners
  JR DrawMaze_5
DrawMaze_1:
  LD A,WHITE*PAPER+BLACK  ; arrow
  JR DrawMaze_5
DrawMaze_2:
  LD A,WHITE*PAPER+WHITE  ; invisible tile
  JR DrawMaze_5
DrawMaze_3:
  LD A,WHITE*PAPER+YELLOW ; empty
  JR DrawMaze_5
DrawMaze_4:
  LD A,WHITE*PAPER+GREEN  ; flower
DrawMaze_5:
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JR NZ,DrawMaze_0
  EXX                     ; back to HL=map, DE=screen, BC=count
DrawMaze_6:
  PUSH HL                 ; pass 2: bitmaps, one cell per pass
  LD A,(HL)
  LD H,$00
  LD L,A
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL               ; tile code * 8
  LD IX,TileGraphics
  EX DE,HL
  ADD IX,DE               ; IX = graphics of this tile
  EX DE,HL
  LD L,CELL_BYTES
DrawMaze_7:
  LD A,(IX+$00)
  LD (DE),A
  INC D
  INC IX
  DEC L
  JR NZ,DrawMaze_7
  INC E                   ; next cell
  JR Z,DrawMaze_8         ; end of a screen third: D already points into the
                          ; next one
  LD A,D
  SUB CELL_BYTES          ; back up the eight pixel rows just drawn
  LD D,A
DrawMaze_8:
  POP HL
  INC HL
  DEC BC
  LD A,B
  OR C
  JR NZ,DrawMaze_6
  RET

; Draw a 16x16 sprite
;
; Draws a sprite of 2x2 character cells (graphic order top-left, top-right,
; bottom-left, bottom-right, 8 bytes each) with one attribute for all four
; cells. The caller must already have called SetAttrPointer for HL so that HL'
; points at the attribute of the top-left cell. Used for Horace, the guards and
; the items, and to erase them with the blank sprite at BlankSprite. Hardware:
; writes the screen bitmap and four attribute cells.
;
;   C Attribute byte for all four cells
;   DE Address of the 32 sprite graphic bytes
;   HL Offset from the start of the screen of the top-left cell ($0000-$17FF)
; O:DE Address after the sprite graphic
; O:HL Screen address of the cell after the bottom-right one
; O:HL' Attribute address after the bottom-right cell
; O:AF' Corrupted
DrawSprite:
  EX AF,AF'
  LD A,C
  EX AF,AF'
  LD BC,SCREEN
  ADD HL,BC
; BC was clobbered above, so C is restored from A'.
  EX AF,AF'
  LD C,A
  EX AF,AF'
  CALL DrawCell
  CALL DrawCell
; Move down to the left cell of the next cell row: HL is now two cells to the
; right, so add one screen row of cells less two.
  LD A,L
  ADD A,SCREEN_COLS-$02
  LD L,A
  JR NC,DrawSprite_Row2
  LD A,H
  ADD A,THIRD_STEP
  LD H,A
; The attribute pointer must be recomputed for the new cell row.
DrawSprite_Row2:
  CALL SetAttrPointer
  CALL DrawCell
  CALL DrawCell
  RET

; Draw one 8x8 character cell
;
; Copies 8 bytes to the eight pixel rows of the cell at HL, stores an attribute
; byte at the attribute address held in HL' (set up with SetAttrPointer) and
; moves both pointers to the next cell on the right. At the end of a screen row
; HL moves to the first row of the next screen third instead of wrapping.
; Hardware: writes the screen bitmap and one attribute cell.
;
;   C Attribute byte (flash, bright, paper, ink)
;   DE Address of the 8 graphic bytes
;   HL Screen bitmap address of the cell (first pixel row)
;   HL' Attribute address of the cell
; O:DE Address after the 8 graphic bytes
; O:HL Screen address of the next cell
; O:HL' Attribute address of the next cell
; O:A Corrupted
; O:B 0
DrawCell:
  LD A,C
  EXX
  LD (HL),A
  INC HL
  EXX
  LD B,CELL_BYTES
DrawCell_Row:
  LD A,(DE)
  LD (HL),A
  INC H
  INC DE
  DJNZ DrawCell_Row
; H is now 8 rows down. If L wraps to 0 the cell was the last one in the screen
; row of a third, and the extra 8 in H already is the next third.
  INC L
  RET Z
  LD B,THIRD_STEP
  LD A,H
  SUB B
  LD H,A
  RET

; Point HL' at the attribute cell of a screen address
;
; Converts the screen bitmap address in HL into the attribute address of the
; same character cell and leaves it in the alternate register HL'. The low byte
; is the same in both, so only the high byte changes: bits 3-4 of H select the
; screen third (0-2), which becomes the offset from the attribute high byte.
; The drawing routines DrawCell and PrintChar then write an attribute through
; HL' (and increment it) for every cell they draw. The main register set is
; selected again on return. Hardware: computes an address in the attribute area
; ($5800-$5AFF); writes nothing.
;
;   HL Screen bitmap address (in the first pixel row of a cell)
; O:HL' Attribute address matching HL
; O:A Corrupted
SetAttrPointer:
  PUSH HL
  EXX
  POP HL
  LD A,H
  AND THIRD_BITS
  SRA A
  SRA A
  SRA A
  ADD A,ATTRS_HIGH
  LD H,A
  EXX
  RET

; Find the object in a 2x2-cell block of the screen
;
; Reads the four attribute cells of a 16x16 sprite area and reports which
; object colour is in it. Used for collisions: the guard colour has priority,
; then the bell, then a flower (see MergeObjectAttr). The four cells are read
; in the order top-left, top-right, bottom-left, bottom-right. Hardware: reads
; the attribute area; nothing is written.
;
;   HL Screen offset of the top-left cell (a screen address without the $4000
; base)
; O:A Attribute of the object found ($3B guard, $3A bell, $3C flower), 0 if
; none
; O:F Z set when nothing was found
; O:BC' Corrupted
; O:DE' Corrupted
; O:HL' Corrupted
GetBlockObject:
  PUSH BC
  PUSH DE
  PUSH HL
  LD BC,SCREEN
  ADD HL,BC
  CALL SetAttrPointer
  EXX
  LD E,$00
  CALL MergeObjectAttr
  INC HL
  CALL MergeObjectAttr
  LD BC,SCREEN_COLS-$0001
  ADD HL,BC
  CALL MergeObjectAttr
  INC HL
  CALL MergeObjectAttr
  LD A,E
  EXX
  POP HL
  POP DE
  POP BC
  AND A
  RET

; Merge one cell's object colour into the block result
;
; Part of GetBlockObject. Looks at one attribute byte and updates the running
; answer in E: a guard colour always wins, then the bell, then a flower; any
; other attribute (floor, wall, pads, arrows) changes nothing. Hardware: reads
; an attribute cell (through the shadow register set).
;
;   E' Best object attribute so far (0 = none)
;   HL' Attribute address of the cell
; O:E' Updated best object attribute
; O:D' Corrupted
; O:A Corrupted
MergeObjectAttr:
  LD A,(HL)
  CP ATTR_GUARD
  JR Z,MergeObjectAttr_0
  CP ATTR_BELL
  JR Z,MergeObjectAttr_1
  CP ATTR_FLOWER
  JR Z,MergeObjectAttr_2
  JR MergeObjectAttr_3
; Guard: always replaces the previous answer.
MergeObjectAttr_0:
  LD E,A
  JR MergeObjectAttr_3
; Bell: replaces everything except a guard.
MergeObjectAttr_1:
  LD D,A
  LD A,E
  CP ATTR_GUARD
  JR Z,MergeObjectAttr_3
  LD E,D
  JR MergeObjectAttr_3
; Flower: only taken when nothing else was found.
MergeObjectAttr_2:
  LD D,A
  LD A,E
  AND A
  JR NZ,MergeObjectAttr_3
  LD E,D
MergeObjectAttr_3:
  RET

; Save the background under a guard sprite
;
; Remembers what is on the screen in the 2x2-cell area (16x16 pixels) whose
; top-left cell is HL, so that it can be put back when the guard moves on (see
; EraseGuard). The four cells are stored in the order top-left, top-right,
; bottom-left, bottom-right, 9 bytes each (attribute, then 8 bitmap rows), in
; the 36 bytes at $6DBF inside the current guard record (see GuardRecord).
; Guard coloured cells are stored as blank floor (see SaveBackgroundCell).
; Hardware: reads the screen bitmap and the attribute area.
;
;   HL Screen offset of the top-left cell (a screen address without the $4000
; base)
; O:HL Corrupted: holds the original DE (the pops are in the wrong order; no
; caller uses it)
; O:DE Corrupted: holds the original HL
; O:BC' Corrupted
; O:HL' Corrupted
SaveBackground:
  PUSH BC
  PUSH DE
  PUSH HL
  LD BC,SCREEN
  ADD HL,BC
  CALL SetAttrPointer
  LD DE,SavedBackground
  CALL SaveBackgroundCell
  CALL SaveBackgroundCell
; Move both pointers to the left cell of the next row: HL' is two cells along
; already, so add 30; the same for HL, carrying into the next screen third.
  EXX
  LD BC,SCREEN_COLS-$0002
  ADD HL,BC
  EXX
  LD A,L
  ADD A,SCREEN_COLS-$02
  LD L,A
  JR NC,SaveBackground_0
  LD A,H
  ADD A,THIRD_STEP
  LD H,A
SaveBackground_0:
  CALL SaveBackgroundCell
  CALL SaveBackgroundCell
  POP DE
  POP HL
  POP BC
  RET

; Save one cell of the background under a sprite
;
; Copies a character cell (attribute byte, then the 8 bitmap rows) from the
; screen into the 9-byte save slot at DE, and moves on to the cell on the
; right. A cell whose attribute is the guard colour is not saved as it is: a
; blank floor cell (attribute $3E, empty bitmap) is stored instead, so a guard
; is never remembered as part of the background. Hardware: reads the screen
; bitmap and one attribute cell (through HL').
;
;   DE Address of the 9-byte save slot
;   HL Screen bitmap address of the cell (first pixel row)
;   HL' Attribute address of the cell
; O:DE Address after the slot
; O:HL Screen address of the next cell on the right
; O:HL' Attribute address of the next cell
; O:A Corrupted
; O:B 0
SaveBackgroundCell:
  EXX
  LD A,(HL)
  INC HL
  EXX
  CP ATTR_GUARD
  JR Z,SaveBackgroundCell_Blank
  LD (DE),A
  INC DE
  LD B,CELL_BYTES
SaveBackgroundCell_Row:
  LD A,(HL)
  LD (DE),A
  INC DE
  INC H
  DJNZ SaveBackgroundCell_Row
; H is now 8 pixel rows too far: undo that, unless L wraps, in which case the
; next cell is in the next screen third and H is already right.
  INC L
  JR Z,SaveBackgroundCell_0
  LD A,H
  SUB THIRD_STEP
  LD H,A
SaveBackgroundCell_0:
  RET
; Guard colour found: store a blank cell.
SaveBackgroundCell_Blank:
  LD A,ATTR_BLANK
  LD (DE),A
  INC DE
  LD B,CELL_BYTES
  LD A,$00
SaveBackgroundCell_1:
  LD (DE),A
  INC DE
  DJNZ SaveBackgroundCell_1
  INC L
  RET NZ
  LD A,H
  ADD A,THIRD_STEP
  LD H,A
  RET

; Probe what is in the way of a one-cell move
;
; Used by the Horace and guard movement code to ask "what would I run into if
; the 16x16 sprite at HL took one step in direction A?". The 2x2-cell block one
; cell away is examined through its attributes (top-left, top-right,
; bottom-left, bottom-right, see ProbeCell): any wall cell blocks the move;
; otherwise at least two pad cells give MOVE_WRAP and at least two arrow cells
; give MOVE_EXIT. The sprite is not moved; HL is preserved. Hardware: reads the
; attribute area; nothing is written.
;
;   A Direction (0 up, 1 right, 2 down, 3 left); only the low two bits are used
;   HL Screen offset of the sprite's top-left cell (a screen address without
; the $4000 base)
; O:A 0 nothing in the way (move allowed), 1 vertical wrap pad ahead
;   Horace is carried to the opposite edge, see PlanMoves , 2 edge arrows ahead
; the right-hand ones leave the maze , 3 wall ahead (blocked). Mixed
; pads and arrows give $82, which callers treat as blocked.
; O:F Corrupted
; O:BC' Corrupted
; O:DE' Corrupted
; O:HL' Corrupted
ProbeMove:
  PUSH BC
  PUSH DE
  PUSH HL
  LD BC,SCREEN
  ADD HL,BC
  CALL StepCell
  CALL SetAttrPointer
  EXX
  LD E,$00
  CALL ProbeCell
  INC HL
  CALL ProbeCell
  LD BC,SCREEN_COLS-$0001
  ADD HL,BC
  CALL ProbeCell
  INC HL
  CALL ProbeCell
  LD A,E
  EXX
  POP HL
  POP DE
  POP BC
  CP PROBE_BLOCKED
  JR NZ,ProbeMove_0
  LD A,MOVE_BLOCKED
  RET
; E = pads + 4*arrows. Bit 1 (2 or 3 pads) -> 1, bit 3 (2 or 3 arrows) -> 2.
ProbeMove_0:
  AND PROBE_MANY_BITS
  RRC A
  CP MOVE_WRAP
  RET Z
  RRC A
  RET

; Classify one cell for a move probe
;
; Part of ProbeMove. Looks at the attribute of one cell ahead of a moving
; sprite and updates a running total in E: a wall sets E to $FF (blocked, and
; the later cells are skipped), a pad cell adds 1, an arrow cell adds 4. Any
; other attribute leaves E alone. Two or more pad cells (E bit 1) or two or
; more arrow cells (E bit 3) in the 2x2 block are what ProbeMove later
; recognises. Hardware: reads an attribute cell (through the shadow register
; set).
;
;   E' Running total ($FF = wall seen)
;   HL' Attribute address of the cell
; O:E' Updated total
; O:A Corrupted
ProbeCell:
  LD A,E
  CP PROBE_BLOCKED
  RET Z
  LD A,(HL)
  CP ATTR_WALL
  JR NZ,ProbeCell_0
  LD E,PROBE_BLOCKED
  RET
ProbeCell_0:
  CP ATTR_PAD
  JR NZ,ProbeCell_1
  LD A,$01
  ADD A,E
  LD E,A
  RET
ProbeCell_1:
  CP ATTR_ARROW
  RET NZ
  LD A,PROBE_ARROW_WEIGHT
  ADD A,E
  LD E,A
  RET

; Move a screen address one character cell in a direction
;
; Adds one cell step to a screen address (or to an offset from the screen
; start) in direction A: up/down change the address by 32 bytes, left/right by
; 1, carrying into the next or previous screen third when the low byte wraps.
; Only the two low bits of A matter. There is no check against the maze edges.
; Hardware: none, pure screen-address arithmetic (the screen layout is the ZX
; Spectrum's: the high byte holds the third and the pixel row).
;
;   A Direction (0 up, 1 right, 2 down, 3 left, as stored in $7C70)
;   HL Screen address or offset of the cell
; O:HL Address of the neighbouring cell
; O:A Corrupted
StepCell:
  AND DIR_MASK
  CP DIR_UP
  JR Z,StepCell_0
  CP DIR_RIGHT
  JR Z,StepCell_1
  CP DIR_DOWN
  JR Z,StepCell_2
; Left. DEC does not affect carry, and carry is clear after the CPs above, so
; the JR NC is always taken and the third is never adjusted (the three
; instructions after it are never executed).
  DEC L
  JR NC,StepCell_3
  LD A,H
  SUB THIRD_STEP
  LD H,A
  JR StepCell_3
; Up.
StepCell_0:
  LD A,L
  SUB SCREEN_COLS
  LD L,A
  JR NC,StepCell_3
  LD A,H
  SUB THIRD_STEP
  LD H,A
  JR StepCell_3
; Right.
StepCell_1:
  INC L
  JR NZ,StepCell_3
  LD A,H
  ADD A,THIRD_STEP
  LD H,A
  JR StepCell_3
; Down.
StepCell_2:
  LD A,L
  ADD A,SCREEN_COLS
  LD L,A
  JR NC,StepCell_3
  LD A,H
  ADD A,THIRD_STEP
  LD H,A
StepCell_3:
  RET

; Draw block-pixel graphics
;
; Draws a picture stored as one byte per 8x8 character cell, each byte being a
; 2x2 grid of 4x4-pixel blocks: bit 4 = top-left block, bit 5 = top-right, bit
; 0 = bottom-left, bit 1 = bottom-right (1 = set). Cells go left to right, then
; on to the next character row (and, past the end of a screen third, to the
; next third). The game uses it for the two title words "HUNGRY" and "HORACE"
; (160 bytes each, 32x5 cells). Hardware: writes the screen bitmap only; the
; attributes are not touched.
;
;   HL Address of the block data
;   DE Screen address of the first cell (its top pixel row)
;   BC Number of cells (data bytes) to draw
; O:HL Address after the data
; O:DE Screen address after the last cell
; O:BC 0
DrawBlocks:
  PUSH BC                 ; loop head: one cell per pass
  LD A,(HL)
  AND BLOCK_TOP_BITS      ; top-row bits: 0 none, $10 left, $20 right, $30 both
  CP $00
  JR Z,DrawBlocks_2
  CP BLOCK_TOP_LEFT
  JR Z,DrawBlocks_1
  CP BLOCK_TOP_RIGHT
  JR Z,DrawBlocks_0
  LD C,BOTH_HALVES
  JR DrawBlocks_3
DrawBlocks_0:
  LD C,RIGHT_HALF
  JR DrawBlocks_3
DrawBlocks_1:
  LD C,LEFT_HALF
  JR DrawBlocks_3
DrawBlocks_2:
  LD C,$00
DrawBlocks_3:
  LD B,BLOCK_PIXEL_ROWS   ; four pixel rows of the top blocks
  LD A,C
DrawBlocks_4:
  LD (DE),A
  INC D
  DJNZ DrawBlocks_4
  LD A,(HL)
  AND BLOCK_BOTTOM_BITS   ; bottom-row bits: 0 none, 1 left, 2 right, 3 both
  CP $00
  JR Z,DrawBlocks_7
  CP $01
  JR Z,DrawBlocks_6
  CP BLOCK_BOTTOM_RIGHT
  JR Z,DrawBlocks_5
  LD C,BOTH_HALVES
  JR DrawBlocks_8
DrawBlocks_5:
  LD C,RIGHT_HALF
  JR DrawBlocks_8
DrawBlocks_6:
  LD C,LEFT_HALF
  JR DrawBlocks_8
DrawBlocks_7:
  LD C,$00
DrawBlocks_8:
  LD B,BLOCK_PIXEL_ROWS   ; four pixel rows of the bottom blocks
  LD A,C
DrawBlocks_9:
  LD (DE),A
  INC D
  DJNZ DrawBlocks_9
  INC E                   ; next cell to the right
  JR Z,DrawBlocks_10      ; E wrapped: end of a screen third, D already points
                          ; into the next third
  LD A,D
  SUB CELL_BYTES          ; back up the eight pixel rows just drawn
  LD D,A
DrawBlocks_10:
  INC HL
  POP BC
  DEC BC
  LD A,B
  OR C
  JR NZ,DrawBlocks
  RET
