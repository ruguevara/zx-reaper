; Bytecode interpreter: runs the script at HL until its end code $80
;
; Room scripts, the parchment and ending windows, the menus and the title
; screens are all scripts in one bytecode: a stream of bytes, each either a
; character to print or a command with operands. EnterRoom runs the script of
; room N, the word at $7236 + 2*N, when a room is entered; room 25, entered by
; the ending (RunEnding), just calls room 24's script. A script ends with $80;
; a subscript is run by the commands $83, $95 and $9C (and by RunEventScript)
; and ends with its own $80.
;
; How it runs: the interpreter handles one code per pass and pushes its own
; address as the return address of what it calls, so every handler ends with
; RET and falls back here. Code < $80 is a character: DrawGlyph draws it at the
; text cursor ($9F26/$9F27) and advances the cursor. Code >= $80 is a command:
; its handler is the word at ScriptOpTable + 2*(code - $80); it is entered with
; HL at the first operand byte and returns HL after the last one. DE and BC are
; scratch for the handlers and not preserved. The code $80 pops the loop
; address and returns to the caller (HL = $9D5F then, not the script address).
; Codes from $A0 up index past the table and are not used.
;
; Notation of the operands (all single bytes unless stated): y = row, x =
; column (tile and attribute commands: tile row 0-21 of the room, cell row 0-23
; of the screen; $81 and the text: pixel row 0-191), w and h = width and height
; in cells (bytes for $81), t = tile number, a = attribute byte, b = bitmap
; byte, n and k = counts, word = little-endian address, (y x)*k = k pairs. A
; position is always row first, then column. Tile commands write the tile map
; and the tile flag map (PlaceTile); the screen is redrawn from them later.
;
; The codes (code, operands: effect, handler):
;
; $00-$7F, none: print the character.
; $80, none: end of script (OpEnd).
; $81, y x w h b: fill w bytes x h pixel rows of the bitmap with b
; (OpFillPixels).
; $82, mode y: alignment of numbered strings (1 left at x=0, 2 centred, else
; right-aligned to x=256) and text row y (OpSetTextAlign).
; $83, word: run the subscript at the address (OpCallScript).
; $84, word: print the string whose number is in the byte at the address:
; $850D room name, $850E, $850F parchment lines (OpPrintStringVar).
; $85, n: print string number n of the table at $9048 (OpPrintString).
; $86, y x w h t: fill a w x h rectangle of tiles with t (OpFillTiles).
; $87, n: set the room name: string number n into $850D (OpSetRoomName).
; $88, w h then w*h tile numbers: define the block pattern, row by row
; (OpDefineBlock).
; $89, y x w h: fill the rectangle with the block pattern, repeated
; (OpFillWithBlock).
; $8A, mask: set flag bit 1 on border cells of the tile flag map: bit 0 left
; column, bit 1 right column, bit 2 top row (OpFlagEdges).
; $8B, n t1..tn k (y x)*k: draw the row of n tiles at each of k positions
; (OpStampRun).
; $8C, y x t: place one tile (OpPlaceTile).
; $8D, y x t c then c counts: stripes of t from (y,x): the counts alternate
; draw n tiles, skip n cells (a skip wraps to the next row at column 32)
; (OpTileStripes).
; $8E, y x: set the text cursor, pixel row y and pixel column x
; (OpSetTextCursor).
; $8F, y x w h a: fill a w x h rectangle of attribute cells with a
; (OpFillAttrs).
; $90, f: f=1 mark every cell of the room for redraw (flag bit 7), f=0 clear
; the marks (OpMarkRedraw).
; $91, t w h k (y x)*k: draw the w x h block of tiles t, t+1, ... (row by row)
; at each of k positions (OpStampTileBlock).
; $92, t k (y x)*k: place the tile t at each of k positions (OpStampOne).
; $93, y x n t1..tn: a row of n tiles (OpTileRow).
; $94, y x t c then c bytes: tile t where a two-level bitmap has bits set: an
; index byte holds 8 bits for 8 groups of 8 cells (high bit first), each group
; with its bit set is followed by one mask byte of 8 cells; c counts all index
; and mask bytes (OpDrawTileMask).
; $95, word1 word2: run the subscript word1 if the byte at word2 is 0
; (OpRunIfZero).
; $96, y x w h f: fill a rectangle of the tile flag map with f
; (OpSetFlagRect).
; $97, n: unpack sprite set n for the room (OpUnpackSprites).
; $98, t k (y x w h)*k: fill k rectangles with t (OpFillTilesList).
; $99, k (y x w h)*k: fill k rectangles with the block pattern
; (OpFillBlockList).
; $9A, t y x n: vertical line of n tiles t, not used by the scripts
; (OpTileVLine).
; $9B, t k (y x n)*k: k vertical lines of tile t (OpTileVLines).
; $9C, word1 word2: run the subscript word1 if the byte at word2 is not 0
; (OpRunIfNonZero).
; $9D, y x a n: water strip of n cells at (y,x) with attribute a: starts the
; per-frame reflection effect DrawWaterReflection and gives the cells the
; harmful flag value 4 (OpSetupWater).
; $9E, none: start the bubbling blood of the bottom row, tiles $3B/$3C
; (OpAnimateBlood).
; $9F, none: start the ring of twelve crosses (OpTwelveCrosses).
;
; Every code above was run on hand-made scripts from a game snapshot and the
; tile map, flag map, screen and variables read back: each does what its line
; says (F149).
;
; Hardware: the character and bitmap commands write the screen bitmap and the
; attribute commands the attribute file directly; the tile commands only write
; the buffers.
;
;   HL Address of the script
; O:HL $9D5F after the end code (the script address is lost)
RunScript:
  PUSH HL
  LD HL,RunScript         ; the loop address becomes the return address of
                          ; every handler
  EX (SP),HL
  LD A,(HL)
  ADD A,A                 ; bit 7 to carry: a command
  JR C,RunScript_0
  LD A,(HL)
  INC HL
  CALL DrawGlyph          ; character: draw it at the text cursor
  RET                     ; back into the loop
RunScript_0:
  INC HL                  ; skip the code
  PUSH HL                 ; script pointer for the handler
  PUSH DE
  LD L,A
  LD H,$00
  LD DE,ScriptOpTable
  ADD HL,DE               ; HL = table entry: code*2 (bit 7 gone) + table
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  POP DE
  EX (SP),HL              ; RET enters the handler; HL = script pointer
  RET

; Script opcode $80: end of script
;
; Pops the loop address pushed by RunScript so that the RET returns to the
; caller of the interpreter (or of the subscript).
OpEnd:
  POP HL                  ; drop the loop address (HL = $9D5F)
  RET

; Script opcode $81: fill a block of the screen bitmap with one byte
;
; Operands: y x w h b (5 bytes): the block starts at pixel row y (0-191) and
; byte column x (0-31), is w bytes wide and h pixel rows high and is filled
; with b. The scripts use it with b = 0: the whole screen (room 0, the
; windows ScriptParchment and ScriptEnding1-3), the two bottom rows (room 4),
; the room name panel (ScriptRoomPanel) and the lines of the controls screen
; (ScriptControlsScreen and the line scripts after it). The fill is done by
; FillBitmapRect.
;
; Hardware: writes the screen bitmap.
;
;   HL Operand bytes
; O:HL Address after the operands
OpFillPixels:
  CALL GetFourOperands    ; E = y, D = x, C = w, B = h
  LD A,(HL)               ; b
  INC HL
  PUSH HL
  EX DE,HL                ; HL = y (L), x (H)
  CALL FillBitmapRect
  POP HL
  RET

; Script opcode $8F: fill a rectangle of attribute cells with one attribute
;
; Operands: y x w h a (5 bytes): the rectangle starts at cell row y (0-23) and
; column x, is w cells wide and h rows high and gets the attribute byte a.
; Fills through FillAttrRect.
;
; Hardware: writes the attribute file.
;
;   HL Operand bytes
; O:HL Address after the operands
OpFillAttrs:
  CALL GetFourOperands    ; E = y, D = x, C = w, B = h
  LD A,(HL)               ; a
  INC HL
  PUSH HL
  EX DE,HL                ; HL = y (L), x (H)
  CALL FillAttrRect
  POP HL
  RET

; Script opcode $82: set the alignment of numbered strings and the text row
;
; Operands: mode y (2 bytes). mode goes to $9F93 and y to the text cursor row
; $9F26. The alignment is applied by AlignText when a string is printed with
; $84 or $85: mode 1 starts at x=0, mode 2 centres the string on x=128, any
; other value (the scripts use 0) right-aligns it to x=256.
;
;   HL Operand bytes
; O:HL Address after the operands
OpSetTextAlign:
  LD DE,TextAlignMode     ; mode into $9F93
  LDI
  LD DE,TextCursorY       ; y into the text cursor row $9F26
  LDI
  RET

; Script opcode $83: run a subscript
;
; Operand: word (the address of a script). Runs it with RunScript and continues
; after the operand. HL is saved because the end code of the subscript leaves
; HL = $9D5F.
;
;   HL Operand bytes
; O:HL Address after the operand
OpCallScript:
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  PUSH HL
  EX DE,HL
  CALL RunScript          ; run the subscript
  POP HL
  RET

; Script opcode $85: print a numbered string
;
; Operand: n (1 byte), a string number of the table at $9048 (0-52: room names,
; parchment texts, ...). Printed by PrintString at the text row ($9F26) and the
; alignment set by $82.
;
; Hardware: draws on the screen bitmap (through DrawGlyph).
;
;   HL Operand byte
; O:HL Address after the operand
OpPrintString:
  LD A,(HL)
  INC HL
  PUSH HL
  CALL PrintString
  POP HL
  RET

; Script opcode $84: print the string whose number is stored in a variable
;
; Operand: word, the address of a byte holding the string number. The scripts
; use $850D (the room name, set by $87) and $850E/$850F (the two lines of a
; parchment). Printed by PrintString.
;
; Hardware: draws on the screen bitmap (through DrawGlyph).
;
;   HL Operand bytes
; O:HL Address after the operand
OpPrintStringVar:
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD A,(DE)               ; string number from the variable
  PUSH HL
  CALL PrintString
  POP HL
  RET

; Script opcode $98: fill several rectangles of the tile map with one tile
;
; Operands: t k, then k rectangles of y x w h (4 bytes each). Each rectangle is
; filled with the tile t through FillTilesRect.
;
;   HL Operand bytes
; O:HL Address after the last rectangle
OpFillTilesList:
  LD C,(HL)               ; C = tile
  INC HL
  LD B,(HL)               ; B = number of rectangles
  INC HL
OpFillTilesList_0:
  PUSH BC                 ; loop over the rectangles
  LD A,C                  ; A = tile
  CALL GetFourOperands    ; E = y, D = x, C = w, B = h
  CALL FillTilesRect      ; fill it
  POP BC
  DJNZ OpFillTilesList_0
  RET

; Script opcode $86: fill a rectangle of the tile map with one tile
;
; Operands: y x w h t (5 bytes): rows y to y+h-1 and columns x to x+w-1 get the
; tile t, one cell at a time through PlaceTile. Falls into FillTilesRect, which
; OpFillTilesList calls and DrawTileVLine jumps to with the rectangle already in
; registers.
;
;   HL Operand bytes
; O:HL Address after the operands
OpFillTiles:
  CALL GetFourOperands    ; E = y, D = x, C = w, B = h
  LD A,(HL)
  INC HL

; Fill a rectangle of the tile map
;
; Fill the rectangle (E row, D column, C wide, B high) with tile A through
; PlaceTile. HL is kept (it is the script pointer of the callers, and
; DrawTileVLine returns to the interpreter through here); B ends 0, C is kept,
; D and E are changed.
;
;   A Tile number
;   E Row
;   D Column
;   C Width
;   B Height
; O:HL Unchanged
FillTilesRect:
  PUSH HL                 ; keep the script pointer
  EX DE,HL                ; HL = position: L row, H column
  LD E,A                  ; E = tile
FillTilesRect_0:
  PUSH HL                 ; one row
  PUSH BC
  LD B,C                  ; B = width
FillTilesRect_1:
  CALL PlaceTile          ; put the tile in the map
  INC H                   ; next column
  DJNZ FillTilesRect_1
  POP BC
  POP HL
  INC L                   ; next row
  DJNZ FillTilesRect_0
  POP HL
  RET

; Script opcode $87: set the room name
;
; Operand: n (1 byte): the number of the room name string, stored in $850D. It
; is printed later with $84 by the room name panel script ScriptRoomPanel
; ($82F0, bottom right of the screen), which every room script but those of
; rooms 0 and 4 runs.
;
;   HL Operand byte
; O:HL Address after the operand
OpSetRoomName:
  LD A,(HL)
  INC HL
  LD (RoomNameString),A
  RET

; Script opcode $92: place one tile at several positions
;
; Operands: t k, then k positions (y x). The single tile is handled as a list
; of one tile by the code it shares with $8B (StampTiles).
;
;   HL Operand bytes
; O:HL Address after the last position
OpStampOne:
  LD D,H                  ; DE = address of the tile list (the operand t)
  LD E,L
  LD C,$01                ; list length 1
  INC HL                  ; skip t
  JR StampTiles

; Script opcode $8B: draw a row of tiles at several positions
;
; Operands: n, t1..tn, k, then k positions (y x). The row of n tiles is drawn
; left to right at each position, one cell at a time through PlaceTile. The
; shared part at StampTiles also serves OpStampOne ($92).
;
;   HL Operand bytes
; O:HL Address after the last position
OpStampRun:
  LD C,(HL)               ; C = n
  INC HL
  LD B,$00
  LD D,H                  ; DE = address of the tile list
  LD E,L
  ADD HL,BC               ; skip the list
; Entry point from OpStampOne: DE tile list, C its length, HL the count byte k.
StampTiles:
  LD B,(HL)               ; B = k, the number of positions
  INC HL
StampTiles_Pos:
  PUSH BC                 ; next position
  LD B,C                  ; B = list length
  PUSH DE                 ; keep the list address
  LD E,(HL)               ; DE = position (y, x)
  INC HL
  LD D,(HL)
  INC HL
  EX (SP),HL              ; HL = list, stack = script pointer
  EX DE,HL                ; HL = position, DE = list
  PUSH DE
StampTiles_Tile:
  PUSH DE                 ; next tile of the list
  LD A,(DE)
  LD E,A
  CALL PlaceTile          ; put the tile in the map
  POP DE
  INC DE
  INC H                   ; next column
  DJNZ StampTiles_Tile
  POP DE
  POP HL
  POP BC
  DJNZ StampTiles_Pos
  RET

; Script opcode $8C: place one tile
;
; Operands: y x t (3 bytes). Puts the tile t at row y, column x through
; PlaceTile.
;
;   HL Operand bytes
; O:HL Address after the operands
OpPlaceTile:
  LD E,(HL)               ; E = y, D = x
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)               ; t
  INC HL
  PUSH HL
  EX DE,HL                ; HL = position
  LD E,A
  CALL PlaceTile
  POP HL
  RET

; Script opcode $93: a row of tiles given inline
;
; Operands: y x n, then n tile numbers. The tiles are placed left to right from
; row y, column x through PlaceTile.
;
;   HL Operand bytes
; O:HL Address after the tile numbers
OpTileRow:
  LD E,(HL)               ; E = y, D = x
  INC HL
  LD D,(HL)
  INC HL
  LD B,(HL)               ; B = n
  INC HL
  PUSH HL
  EX DE,HL                ; HL = position
OpTileRow_0:
  EX (SP),HL              ; E = next tile number from the script (pointer on
                          ; the stack)
  LD E,(HL)
  INC HL
  EX (SP),HL
  CALL PlaceTile          ; put the tile in the map
  INC H
  DJNZ OpTileRow_0
  POP HL
  RET

; Script opcode $8D: draw a tile in stripes (runs and gaps along the rows)
;
; Operands: y x t c, then c count bytes. From the cell (y, x) the counts
; alternate: draw that many cells with the tile t, skip that many cells (a skip
; that passes column 31 continues on the next row), draw, skip... c counts both
; kinds, so it is odd when the last count is a run. The code does not wrap a
; run, but the address arithmetic of TileMapAddress carries a column above 31
; into the next row (except from rows 7 and 15, which go back to rows 0 and 8):
; room 4's stripes at $742C have a run that reaches column 37. Used twice, rooms
; 4 and 5 ($742C, $74D4); cells are placed through PlaceTile (F150).
;
;   HL Operand bytes
; O:HL Address after the counts
OpTileStripes:
  LD E,(HL)               ; E = y, D = x
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)               ; tile
  INC HL
  LD C,(HL)               ; C = number of counts
  INC HL
  PUSH HL
  EX DE,HL
  LD E,A
OpTileStripes_0:
  EX (SP),HL              ; HL = script, stack = position: B = next count
  LD A,(HL)
  INC HL
  EX (SP),HL
  LD B,A
OpTileStripes_1:
  CALL PlaceTile          ; draw a run of B cells
  INC H                   ; next column
  DJNZ OpTileStripes_1
  DEC C                   ; all counts used?
  JR Z,OpTileStripes_4
  EX (SP),HL
  LD A,(HL)
  INC HL
  EX (SP),HL
  LD B,A
OpTileStripes_2:
  INC H                   ; skip B cells
  LD A,H
  SUB $20                 ; past column 31: next row
  JR C,OpTileStripes_3
  LD H,A
  INC L
OpTileStripes_3:
  DJNZ OpTileStripes_2
  DEC C
  JR NZ,OpTileStripes_0
OpTileStripes_4:
  POP HL
  RET

; Put a tile in the room: tile map and tile flag map
;
; Writes the tile number E in the tile map at row L, column H (address $5B00 +
; 32*row + column, via TileMapAddress) and the flag byte of that tile
; (TileFlags, $CD00 + tile; bit 7 set marks the cell for redraw, bits 0-2 are
; the tile class) in the same cell of the tile flag map, three pages higher
; ($5E00 + 32*row + column). Nothing is drawn: the redraw routines (RedrawRoom,
; BuildRedrawList) paint the marked cells later. All the tile commands of the
; room scripts end up here, and ShowCrossRing. HL, E and BC are preserved (the
; fill loops rely on HL and E); D and A are not.
;
;   E Tile number
;   H Column (0-31)
;   L Row (0-21)
PlaceTile:
  PUSH HL
  CALL TileMapAddress     ; HL = tile map address
  LD D,TileFlags/$100     ; DE = TileFlags + tile
  LD (HL),E               ; tile map
  LD A,H
  ADD A,FLAGS_PAGE_OFFSET ; the flag map is 3 pages higher
  LD H,A
  LD A,(DE)               ; flags of the tile
  LD (HL),A               ; tile flag map
  POP HL
  RET

; Draw one character of the proportional font at the text cursor
;
; Draws the glyph of character A (codes $20-$7F) with its top-left pixel at the
; text cursor, pixel row ($9F26) and pixel column ($9F27), then moves the
; cursor right by the glyph width. The glyph pixels are XORed into the screen,
; so drawing the same text again erases it. The attributes are not touched. HL,
; DE and BC are preserved, A and the alternate AF are not.
;
; Font format (FontIndex): the index has one word per character at $6130 +
; 2*(code-$20): bits 0-11 are the distance from the address of the word's high
; byte to the glyph, bits 12-15 the width minus 2 (the cursor advance is width,
; 2 to 17 pixels). A glyph is 16 pixel rows: a mask word (bit 15 for row 0, bit
; 0 for row 15; set = a new row pattern follows in the data, clear = the
; previous pattern is repeated; before the first pattern a row is blank)
; followed by the pattern bytes of the rows that start a new pattern: one byte
; when the width is up to 8, two when it is 9 or more (the right byte first,
; then the left one). A mask of 0 is an empty glyph (the space), only the
; cursor moves.
;
; Each row is positioned at the cursor: the pattern is shifted right by (x mod
; 8) bits inside a 24-bit window (A, H, L) by jumping into the shift chain at
; ShiftGlyphRow (the JR at SmcGlyphShift has its offset set to 2*(x mod 8)) and
; XORed into the three screen bytes of the row. The rows are stepped with
; NextPixelRow; ShiftGlyphRow holds the rest of the loop.
;
; Hardware: writes the screen bitmap.
;
;   A Character code ($20-$7F)
DrawGlyph:
  PUSH HL
  PUSH DE
  PUSH BC
  SUB CHAR_SPACE
  ADD A,A                 ; index word offset
  LD L,A
  LD H,$00
  LD DE,FontIndex
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD A,(HL)
  AND $0F
  LD D,A
  LD A,(HL)
  ADD HL,DE
  RRA
  RRA
  RRA
  RRA
  AND $0F
  INC A
  INC A
  EX AF,AF'               ; A' = width of the glyph, in pixels
  LD E,(HL)               ; DE = mask word
  INC HL
  LD D,(HL)
  INC HL
  LD A,D                  ; empty glyph: only advance the cursor (AdvanceTextX)
  OR E
  JR Z,AdvanceTextX
  LD BC,$0000             ; BC = row pattern, none yet
  PUSH HL                 ; keep the glyph data pointer
  LD HL,(TextCursorY)     ; L = y, H = x
  LD A,H                  ; x mod 8
  AND $07
  ADD A,A
  LD (SmcGlyphShift+$0001),A ; SMC: set the offset of the JR at SmcGlyphShift
                             ; to skip x mod 8 shifts
  LD A,L                  ; low byte of the screen address: ((y/8) mod 8) * 32
                          ; + x/8
  ADD A,A
  ADD A,A
  AND $E0
  SRL H
  SRL H
  SRL H
  OR H
  LD H,L
  LD L,A
  LD A,H                  ; high byte of the screen address from y
  AND $C0
  RRCA
  RRCA
  RRCA
  XOR H
  AND $F8
  XOR H
  ADD A,$40
  LD H,A
  EX (SP),HL              ; stack = screen address, HL = glyph data
  LD A,GLYPH_ROWS         ; rows left
; Loop head, also jumped to by ShiftGlyphRow: next pixel row of the glyph. A =
; rows left, DE = remaining mask bits, HL = glyph data, stack = screen address
; of the row.
DrawGlyph_Row:
  EX DE,HL                ; next mask bit into carry
  ADD HL,HL
  EX DE,HL
  JR NC,DrawGlyph_1
  EX AF,AF'               ; A = width
  CP WIDE_GLYPH           ; 9 or more: two bytes per pattern
  JR C,DrawGlyph_0
  LD C,(HL)               ; right byte (stays 0 for narrow glyphs)
  INC HL
DrawGlyph_0:
  LD B,(HL)               ; left byte
  INC HL
  EX AF,AF'
DrawGlyph_1:
  EX (SP),HL              ; HL = screen address, stack = glyph data
  PUSH AF
  PUSH DE
  PUSH HL
  LD D,B                  ; HL = B:C pattern
  LD E,C
  XOR A                   ; A = the 24-bit window's top byte
  EX DE,HL
; SMC: the offset byte at $9EE3 is written by DrawGlyph (2*(x mod 8)); the jump
; lands in the ADD HL,HL / ADC A,A chain at ShiftGlyphRow, which leaves 8 - x
; mod 8 shifts to do.
SmcGlyphShift:
  JR SmcGlyphShift        ; shift chain entry

; Shift a glyph row into place, XOR it onto the screen and finish the character
;
; Second half of the character printer DrawGlyph, which lies in the middle of
; that routine's address range. DrawGlyph builds the 16-bit pattern of one
; glyph row in HL and then runs the self-modified `JR $9EE2`; it sets the
; offset byte at $9EE3 to 2*(x mod 8) for each character, so the jump lands in
; this chain of eight `ADD HL,HL` / `ADC A,A` pairs and shifts the pattern left
; by 8-(x mod 8) bits into the 24-bit value A:H:L, aligned with the pixel
; column where the glyph starts.
;
; The three bytes are XORed onto the bitmap at the row's address, the address
; is moved down one pixel row with NextPixelRow and control goes back to the
; row loop of DrawGlyph at $9ECB until its 16 rows are done. The common exit of
; the printer is AdvanceTextX: it adds the glyph width to the cursor x and
; restores the registers; DrawGlyph jumps straight to it for an empty glyph (a
; space).
;
; Hardware: XORs three bytes per glyph row into the screen bitmap; the
; attributes are not touched.
;
; HL Glyph row pattern: H the leftmost 8 pixels (bit 7 leftmost), L the next 8
; DE Screen address of the first byte of this row of the glyph
; A 0 (the top byte of the 24-bit shift)
ShiftGlyphRow:
  ADD HL,HL               ; start of the chain: shift A:HL left (entered 0-7
                          ; pairs later for x mod 8 > 0)
  ADC A,A
  ADD HL,HL
  ADC A,A
  ADD HL,HL
  ADC A,A
  ADD HL,HL
  ADC A,A
  ADD HL,HL
  ADC A,A
  ADD HL,HL
  ADC A,A
  ADD HL,HL
  ADC A,A
  ADD HL,HL
  ADC A,A
  EX DE,HL                ; HL = screen address, DE = shifted pattern (D middle
                          ; byte, E right byte)
  XOR (HL)                ; left byte: XOR onto the screen
  LD (HL),A
  INC L
  LD A,D
  XOR (HL)
  LD (HL),A
  INC L
  LD A,E
  XOR (HL)
  LD (HL),A
  POP HL                  ; screen address saved by DrawGlyph at $9EDD
  CALL NextPixelRow       ; next pixel row
  POP DE                  ; glyph mask word
  POP AF                  ; rows left
  EX (SP),HL              ; HL = glyph data pointer, the new row address goes
                          ; on the stack
  DEC A
  JR NZ,DrawGlyph_Row     ; next glyph row
  POP HL                  ; drop the screen address
; Exit of the character printer, also reached directly for an empty glyph: add
; the glyph width (in A') to the cursor x and restore BC, DE, HL.
AdvanceTextX:
  EX AF,AF'               ; A = glyph width
  LD HL,(TextCursorY)     ; cursor: L = y, H = x
  ADD A,H
  LD H,A
  LD (TextCursorY),HL
  POP BC
  POP DE
  POP HL
  RET

; Move a bitmap address down one pixel row
;
; Steps the address of a screen bitmap byte down by one pixel row, following
; the Spectrum screen layout: INC H inside a character cell; after the eighth
; line it moves to the first line of the next character row (L+32) and, on a
; carry, into the next third of the screen. Used by the character printer
; (ShiftGlyphRow) and the bitmap fill FillBitmapRect.
;
; Hardware: knows the layout of the screen bitmap at $4000-$57FF.
;
;   HL Address of a byte in the screen bitmap
; O:HL Address of the byte one pixel row below
NextPixelRow:
  INC H
  LD A,H
  AND $07
  RET NZ
  LD A,L
  ADD A,SCREEN_COLS       ; next character row
  LD L,A
  RET C
  LD A,H
  SUB THIRD_STEP
  LD H,A
  RET

; Text cursor: y (pixel row) and x (pixel column)
;
; Where DrawGlyph draws the next character; read as a word with L = y and H =
; x. +0 byte: y, pixel row 0-191, set by script codes $82 (y only) and $8E (y
; and x). +1 byte: x, pixel column 0-255; recomputed by AlignText before each
; string from the alignment mode and the string width, and advanced by the
; width of every character drawn (AdvanceTextX).
TextCursorY:
  DEFB $00
TextCursorX:
  DEFB $00

; Script code $8E: set the text cursor
;
; Operands: y (pixel row), x (pixel column), copied to TextCursorY and
; TextCursorX. Used by the controls screen scripts (ScriptControlsScreen,
; ScriptKempstonLine, ScriptKeyboardLine, ScriptPressKey), whose characters
; follow it; no room or window script uses it (a static decode of the scripts
; at $726A-$83A7 finds no $8E): those set only y, with $82 (OpSetTextAlign), and
; let the alignment choose x for the numbered strings.
;
;   HL Script pointer, at the operands
; O:HL Script pointer after the two operands
OpSetTextCursor:
  LD DE,TextCursorY
  LDI
  LDI
  RET

; Print string number A at the text cursor, aligned
;
; Finds string A in the text table (FindString), measures it (MeasureString),
; lets AlignText set the cursor x from the alignment mode (TextAlignMode) and
; the width, then draws the characters one at a time with DrawGlyph, each
; advancing the cursor by its width. The cursor y is not changed; HL ends after
; the string. Reached from script codes $85 (string number in the script,
; OpPrintString) and $84 (string number read from a variable,
; OpPrintStringVar).
;
; Hardware: draws the proportional font into the screen bitmap by XOR (through
; DrawGlyph); the attributes are not touched, so the text takes the colours the
; cells already have.
;
; A String number 0-52 (the text table at $9048)
PrintString:
  CALL FindString
  CALL MeasureString
  CALL AlignText
  LD B,(HL)               ; string length
  INC HL
PrintString_Loop:
  LD A,(HL)
  INC HL
  CALL DrawGlyph
  DJNZ PrintString_Loop
  RET

; Find string number A in the text table
;
; The text table at $9048 is a run of strings, each a length byte followed by
; that many characters. Skips A strings by stepping HL over length+1 bytes
; each; string 0 is at $9048 itself, so A = 0 returns at once. The table holds
; strings 0-52; a larger number would run past it (not checked).
;
;   A String number
; O:HL Address of the string's length byte
FindString:
  LD HL,RoomNames
  OR A
  RET Z
  LD B,A
  LD DE,$0000
FindString_Loop:
  LD E,(HL)
  INC HL
  ADD HL,DE
  DJNZ FindString_Loop
  RET

; Measure a string in the proportional font
;
; Adds up the advance of every character of a length-prefixed string. The
; advance of a character is the high nibble of the second byte of its word in
; the font index at $6130 plus 2, the same field DrawGlyph uses when it moves
; the cursor. The sum is kept in 8 bits.
;
;   HL Address of the string (length byte first)
; O:C Width of the string in pixels
; O:HL Unchanged
MeasureString:
  PUSH HL
  LD B,(HL)
  INC HL
  LD C,$00
MeasureString_Loop:
  LD A,(HL)
  INC HL
  PUSH HL
  SUB CHAR_SPACE
  ADD A,A                 ; index word of the character
  LD L,A
  LD H,$00
  LD DE,FontIndex
  ADD HL,DE
  INC HL                  ; second byte of the word: bits 12-15 of the word
                          ; hold the width minus 2
  LD A,(HL)
  RRA
  RRA
  RRA
  RRA
  AND $0F
  ADD A,GLYPH_WIDTH_BIAS
  ADD A,C
  LD C,A
  POP HL
  DJNZ MeasureString_Loop
  POP HL
  RET

; Set the text cursor x for a string of width C
;
; Applies the alignment mode in TextAlignMode to the string width: 1 puts the
; string at the left edge (x = 0), 2 centres it on the 256-pixel line (x = 128
; - ceil(C/2)), anything else, including the initial 0, makes it end at the
; right edge (x = 256 - C). The cursor y is kept.
;
; C Width of the string in pixels
AlignText:
  LD DE,(TextCursorY)
  LD D,$00
  LD A,(TextAlignMode)    ; alignment mode
  DEC A
  JR Z,AlignText_1        ; mode 1: left, x = 0
  DEC A
  LD A,C
  JR NZ,AlignText_0
  SRL A                   ; mode 2: x = 128 - ceil(C/2)
  ADC A,$00
  SUB $80
AlignText_0:
  NEG                     ; x = -A: 128 - ceil(C/2) in mode 2, 256 - C in the
                          ; other modes
  LD D,A
AlignText_1:
  LD (TextCursorY),DE
  RET

; Alignment mode of numbered strings
;
; One byte read by AlignText and set by script code $82 (its first operand,
; OpSetTextAlign): 1 left-aligned at x = 0, 2 centred, any other value (0 at
; the start) right-aligned, flush with the right edge of the screen.
TextAlignMode:
  DEFB $00

; Fill a rectangle of the screen bitmap with a byte
;
; Worker of script code $81 (OpFillPixels). Fills B pixel rows of C bytes with
; A, starting at the cell given by L (pixel row) and H (byte column);
; BitmapAddress converts the position, which is only right when L is a multiple
; of 8 (all scripts use cell-aligned rows).
;
; Hardware: writes the screen bitmap at $4000-$57FF directly.
;
; A Byte to store
; L Pixel row of the top, a multiple of 8
; H Byte column 0-31
; C Width in bytes
; B Height in pixel rows
FillBitmapRect:
  PUSH AF
  CALL BitmapAddress
  POP DE
FillBitmapRect_Row:
  PUSH HL
  PUSH BC
  LD B,C
FillBitmapRect_0:
  LD (HL),D
  INC L
  DJNZ FillBitmapRect_0
  POP BC
  POP HL
  CALL NextPixelRow       ; next pixel row
  DJNZ FillBitmapRect_Row
  RET

; Fill a rectangle of the attribute file with a byte
;
; Worker of script code $8F (OpFillAttrs); also called by ShowTextWindow. Fills
; B rows of C attribute cells with A, starting at row L, column H.
;
; Hardware: writes the attribute file at $5800-$5AFF directly.
;
; A Attribute byte
; L Cell row 0-23
; H Cell column 0-31
; C Width in cells
; B Height in cells
FillAttrRect:
  PUSH AF
  CALL AttrAddress
  POP DE
FillAttrRect_Row:
  PUSH HL
  PUSH BC
  LD B,C
FillAttrRect_0:
  LD (HL),D
  INC L
  DJNZ FillAttrRect_0
  POP BC
  POP HL
  LD A,SCREEN_COLS        ; next row: +32
  CALL AddAToHL
  DJNZ FillAttrRect_Row
  RET

; Script code $90: mark or unmark every tile for redraw
;
; Operand: one byte v. Rewrites every cell of the tile flag map at $5E00-$60BF:
; the old bit 7 (the redraw mark) is cleared and v rotated right by one bit is
; ORed in, so bit 0 of v becomes the new mark in bit 7 and bits 1-7 of v land
; in bits 0-6 of the flags. The scripts use 0 (clear all marks: room 0, so
; that the intro text is not drawn over) and 1 (mark every cell, so the next
; redraw repaints the whole room from the tile map: the room name panel
; ScriptRoomPanel, which every room but 0 and 4 runs, room 4's own script, and
; the windows ScriptParchment, ScriptEnding1 and ScriptEnding2).
;
; Observed: the cell at $6000 (row 16, column 0) is left alone, because the
; loop ends when L reaches 0 on its first page and so skips offset 0 of that
; page.
;
;   HL Script pointer, at the operands
; O:HL Script pointer after the operands
OpMarkRedraw:
  LD A,(HL)
  INC HL
  RRCA                    ; v rotated right: bit 0 -> bit 7
  LD E,A
  LD D,$FF-FLAG_REDRAW    ; D = mask that clears the mark
  PUSH HL
  LD HL,FLAG_MAP+MAP_ROWS*SCREEN_COLS-$0001 ; last cell of the map; the loop
                                            ; works down through three pages
  LD B,$03
OpMarkRedraw_Loop:
  LD A,(HL)
  AND D
  OR E
  LD (HL),A
  DEC L
  JR NZ,OpMarkRedraw_Loop
  DEC H                   ; next page down
  DJNZ OpMarkRedraw_Loop
  POP HL
  RET

; Script code $91: stamp a block of consecutive tiles at several places
;
; Operands: first tile number, width C, height B, count A, then A positions of
; two bytes each (row, column). At each position the block is drawn into the
; tile map with PlaceTile from its top-left cell, left to right and top to
; bottom; the tile number goes up by one from cell to cell and keeps counting
; from one row to the next (a picture cut into C x B tiles stored one after the
; other in the tile set). Used 29 times.
;
;   HL Script pointer, at the operands
; O:HL Script pointer after the operands
OpStampTileBlock:
  LD E,(HL)
  INC HL
  LD C,(HL)
  INC HL
  LD B,(HL)
  INC HL
  LD A,(HL)
  INC HL
OpStampTileBlock_At:
  PUSH AF                 ; one position of the list
  PUSH DE
  PUSH BC
  PUSH HL
  LD A,(HL)               ; HL = this position: L = row, H = column
  INC HL
  LD H,(HL)
  LD L,A
OpStampTileBlock_0:
  PUSH HL                 ; one row of the block
  PUSH BC
  LD B,C
OpStampTileBlock_1:
  CALL PlaceTile          ; place tile E
  INC H                   ; next column
  INC E                   ; next tile number
  DJNZ OpStampTileBlock_1
  POP BC
  POP HL
  INC L                   ; next row
  DJNZ OpStampTileBlock_0
  POP HL
  INC HL                  ; next position word
  INC HL
  POP BC
  POP DE
  POP AF
  DEC A
  JR NZ,OpStampTileBlock_At
  RET

; Script code $94: draw one tile wherever a bit mask says
;
; Operands: row, column (the first position), tile, then a byte count C and C
; bytes of mask data. The mask covers the tile map in reading order from the
; first position, wrapping from column 31 to column 0 of the next row, and is
; stored in two levels. An index byte is read from its most significant bit
; down and has one bit for each group of 8 cells: 0 skips the 8 cells, 1 takes
; the next byte of the stream as the mask of those 8 cells (most significant
; bit first) and puts the tile on the cells whose bit is 1. A skip that passes
; column 31 goes to column 0 of the next row, dropping the rest (the groups
; stay in step only when the start column is a multiple of 8, as in the one
; use, column 0); a mask byte wraps cell by cell (F150). C counts every byte
; of the stream, index and mask bytes alike; the routine stops when it runs
; out, so a last index byte is read but its bits are not used. Used once (room
; 9, the foliage at $7851).
;
;   HL Script pointer, at the operands
; O:HL Script pointer after the operands
OpDrawTileMask:
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  INC HL
  LD C,(HL)
  INC HL
  PUSH HL
  EX DE,HL
  LD E,A
  EX (SP),HL
  LD A,$80                ; A = marker bit: after 8 shifts the next index byte
                          ; is fetched
OpDrawTileMask_Bit:
  SLA A                   ; next index bit
  JR NZ,OpDrawTileMask_0
  LD A,(HL)               ; new index byte; the SCF/RLA puts the marker bit
                          ; below its bits
  INC HL
  SCF
  RLA
  DEC C
  JR Z,OpDrawTileMask_6   ; stream used up
OpDrawTileMask_0:
  JR C,OpDrawTileMask_2   ; bit 1: a mask byte follows
  EX (SP),HL
  PUSH AF
  LD A,H
  ADD A,$08               ; bit 0: skip 8 cells
  LD H,A
  CP SCREEN_COLS          ; past column 31: first column of the next row
  JR C,OpDrawTileMask_1
  INC L
  LD H,$00
OpDrawTileMask_1:
  POP AF
  EX (SP),HL
  JR OpDrawTileMask_Bit
OpDrawTileMask_2:
  EX AF,AF'
  LD A,(HL)               ; mask byte
  INC HL
  EX (SP),HL
  LD B,$08
OpDrawTileMask_3:
  ADD A,A
  PUSH AF
  JR NC,OpDrawTileMask_4
  CALL PlaceTile          ; place the tile
OpDrawTileMask_4:
  INC H
  LD A,H
  CP SCREEN_COLS
  JR C,OpDrawTileMask_5
  INC L
  LD H,$00
OpDrawTileMask_5:
  POP AF
  DJNZ OpDrawTileMask_3
  EX AF,AF'
  DEC C
  EX (SP),HL
  JR NZ,OpDrawTileMask_Bit
OpDrawTileMask_6:
  POP AF
  RET

; Script code $95: run a subscript when a flag byte is zero
;
; Operands: subscript address (word), flag address (word). If the byte at the
; flag address is 0 the script at the subscript address is run to its $80 end
; by a recursive call of RunScript; in either case the script goes on after the
; operands. Observed with a hand-made script and the flag byte set to 0 and to
; 1. The flags are bytes of the item flag area at $851A-$8521 (see the item
; table at $8EDF); used 3 times (rooms 8, 19 and 20).
;
;   HL Script pointer, at the operands
; O:HL Script pointer after the operands
OpRunIfZero:
  CALL GetFourOperands
  LD A,(BC)               ; flag byte
  OR A
  RET NZ
  PUSH HL
  EX DE,HL
  CALL RunScript          ; run the subscript
  POP HL
  RET

; Script code $9C: run a subscript when a flag byte is not zero
;
; As OpRunIfZero ($95) but the subscript runs when the byte at the flag address
; is not 0. Used 3 times (rooms 6, 7 and 8, flags $851A and $851B).
;
;   HL Script pointer, at the operands
; O:HL Script pointer after the operands
OpRunIfNonZero:
  CALL GetFourOperands
  LD A,(BC)               ; flag byte
  OR A
  RET Z
  PUSH HL
  EX DE,HL
  CALL RunScript          ; run the subscript
  POP HL
  RET

; Script code $8A: set tile flag bit 1 along the room edges
;
; Operand: one byte, a mask of the edges: bit 0 the left column, bit 1 the
; right column, bit 2 the top row, bit 3 the bottom edge. Sets bit 1 of the
; tile flag of every cell along each edge with SetFlagRun. Bit 1 of a cell
; stops the monk walking sideways into it (observed: a flagged column in the
; middle of room 5 stopped him; code: the walking routine tests the flags to
; his left and right with AND 2, UpdatePlayerActive), so this closes an edge
; that has no exit. Used once: room 5, operand 1 (the left edge, $7516).
;
; The bottom edge starts at $60E0, which is row 23 of the flag map and not its
; last row (row 21 is at $60A0): those 32 bytes are the top of the main stack,
; so operand bit 3 would corrupt the stack (observed: a call with operand 8
; does not return). Never used by the scripts.
;
;   HL Script pointer, at the operands
; O:HL Script pointer after the operands
OpFlagEdges:
  LD A,(HL)
  INC HL
  PUSH HL
  LD C,MAP_ROWS           ; a column has 22 cells
  LD DE,SCREEN_COLS       ; step down one row
  LD HL,FLAG_MAP
  RRA                     ; bit 0: left column
  CALL C,SetFlagRun
  LD HL,FLAG_MAP+SCREEN_COLS-$0001 ; bit 1: right column
  RRA
  CALL C,SetFlagRun
  LD C,SCREEN_COLS        ; a row has 32 cells
  LD DE,$0001             ; step along the row
  LD HL,FLAG_MAP
  RRA                     ; bit 2: top row
  CALL C,SetFlagRun
  LD HL,FLAG_MAP+$0017*SCREEN_COLS ; bit 3: "bottom row", but row 23 is outside
                                   ; the map
  RRA
  CALL C,SetFlagRun
  POP HL
  RET

; Set bit 1 of a run of tile flags
;
; Sets bit 1 of C flag bytes starting at HL, DE bytes apart.
;
; HL Address of the first flag in the flag map
; DE Step between cells: 1 along a row, 32 down a column
; C Number of cells
SetFlagRun:
  LD B,C
SetFlagRun_0:
  SET 1,(HL)
  ADD HL,DE
  DJNZ SetFlagRun_0
  RET

; Unused: set a rectangle of tile flags (same operands as $96)
;
; Not in the script jump table and never called (no references). Reads row,
; column, width, height and a value like OpSetFlagRect ($96) and stores the
; value in every cell of that rectangle of the tile flag map at $5E00, using
; UnusedFlagMapAddress for the address; the same job as OpSetFlagRect done
; through a second address routine.
;
;   HL Script pointer, at the operands
; O:HL Script pointer after the operands
UnusedFillFlags:
  CALL GetFourOperands
  LD A,(HL)
  INC HL
  PUSH HL
  EX DE,HL
  LD E,A
  CALL UnusedFlagMapAddress ; flag map address of (row, column)
UnusedFillFlags_Row:
  PUSH BC
  PUSH HL
  LD B,C
UnusedFillFlags_0:
  LD (HL),E
  INC L
  DJNZ UnusedFillFlags_0
  POP HL
  POP BC
  LD A,SCREEN_COLS        ; next row
  CALL AddAToHL
  DJNZ UnusedFillFlags_Row
  POP HL
  RET

; Script code $99: fill several rectangles with the $88 block
;
; Operands: count, then count groups of four bytes (row, column, width,
; height). Each group is handled like script code $89 (OpFillWithBlock) with
; the block defined by the last $88 (OpDefineBlock). Used 37 times.
;
;   HL Script pointer, at the operands
; O:HL Script pointer after the operands
OpFillBlockList:
  LD B,(HL)
  INC HL
OpFillBlockList_Loop:
  PUSH BC
  CALL OpFillWithBlock
  POP BC
  DJNZ OpFillBlockList_Loop
  RET

; Script code $89: fill a rectangle by repeating the $88 block
;
; Operands: row, column, width, height. Fills that rectangle of the tile map:
; the cell at offset (dy, dx) from the top-left gets the tile at (dy mod block
; height, dx mod block width) of the block set by $88 (OpDefineBlock), looked
; up by GetBlockTile and placed with PlaceTile, which also stores the tile's
; default flags. Used 24 times (this entry) and 37 times through $99.
;
;   HL Script pointer, at the operands
; O:HL Script pointer after the operands
OpFillWithBlock:
  CALL GetFourOperands
  PUSH HL
  EX DE,HL
  LD DE,$0000             ; D = row offset, E = column offset in the rectangle
OpFillWithBlock_Row:
  PUSH BC
  PUSH DE
  PUSH HL
  LD B,C
OpFillWithBlock_Cell:
  PUSH DE
  CALL GetBlockTile       ; E = tile of the block
  CALL PlaceTile
  POP DE
  INC H                   ; next column
  INC E
  DJNZ OpFillWithBlock_Cell
  POP HL
  POP DE
  POP BC
  INC L                   ; next row
  INC D
  DJNZ OpFillWithBlock_Row
  POP HL
  RET

; Tile of the repeated block at an offset
;
; Reduces the offsets modulo the block width and height (by repeated
; subtraction: a block of width or height 0, the initial state of BlockWidth,
; would never end) and reads the tile from the block data set by OpDefineBlock.
;
; BC and HL are preserved; D is changed.
;
;   D Row offset in the rectangle
;   E Column offset in the rectangle
; O:E Tile number
GetBlockTile:
  PUSH HL
  PUSH BC
  LD BC,(BlockWidth)      ; C = block width, B = block height
  LD A,E
GetBlockTile_0:
  SUB C
  JR NC,GetBlockTile_0
  ADD A,C
  LD E,A
  LD A,D
GetBlockTile_1:
  SUB B
  JR NC,GetBlockTile_1
  ADD A,B
  LD D,A
  LD HL,(BlockData)       ; HL = block data
  LD A,D
  LD D,$00
  ADD HL,DE
  OR A
  JR Z,GetBlockTile_3
  LD B,A
  LD E,C
GetBlockTile_2:
  ADD HL,DE               ; add the block width once per row
  DJNZ GetBlockTile_2
GetBlockTile_3:
  LD E,(HL)
  POP BC
  POP HL
  RET

; Script code $88: define the tile block used by $89 and $99
;
; Operands: width, height, then width x height tile numbers, row by row. Stores
; the width, height and the address of the tile numbers (which stay in the
; script) in BlockWidth and moves the script pointer past them. Used 31 times,
; each followed by $89 or $99 fills.
;
;   HL Script pointer, at the operands
; O:HL Script pointer after the operands
OpDefineBlock:
  LD C,(HL)
  INC HL
  LD B,(HL)
  INC HL
  LD (BlockWidth),BC      ; block width and height
  LD (BlockData),HL       ; address of the tile numbers
  LD E,C
  LD D,$00
OpDefineBlock_Skip:
  ADD HL,DE               ; skip width x height bytes
  DJNZ OpDefineBlock_Skip
  RET

; Tile block descriptor set by script code $88
;
; +0 byte: block width in tiles. +1 byte: block height in tiles. +2 word:
; address of the width x height tile numbers (row by row), inside the room
; script. Read by GetBlockTile. Both bytes are 0 until the first $88 runs.
BlockWidth:
  DEFB $00
BlockHeight:
  DEFB $00
BlockData:
  DEFW $0000

; Read four script operand bytes
;
; Loads the next four bytes of the script into E, D, C, B, in that order. The
; handlers use them as a position and a size (E row, D column, C width, B
; height: OpFillPixels, OpFillAttrs, OpFillTilesList, OpFillTiles,
; OpFillWithBlock, OpSetFlagRect) or as two words (DE and BC: OpRunIfZero,
; OpRunIfNonZero).
;
;   HL Script pointer
; O:E First byte
; O:D Second byte
; O:C Third byte
; O:B Fourth byte
; O:HL Script pointer after the four bytes
GetFourOperands:
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD C,(HL)
  INC HL
  LD B,(HL)
  INC HL
  RET

; Script code $96: set the tile flags of a rectangle
;
; Operands: row, column, width, height, flag value. Stores the value in the
; tile flag of every cell of the rectangle (SetTileFlag), replacing the whole
; flag byte (class bits and redraw mark). Used 4 times, always with $80: class
; 0 (nothing to touch) and the redraw mark set (rooms 10, 11 and 16, at $794E,
; $7A17, $7A1D, $7D56).
;
; The part from $A12B on is shared with OpSetupWater.
;
;   HL Script pointer, at the operands
; O:HL Script pointer after the operands
OpSetFlagRect:
  CALL GetFourOperands
  LD A,(HL)
  INC HL
  PUSH HL
  LD L,A                  ; L = value; EX DE,HL then gives HL = (row, column),
                          ; E = value
  EX DE,HL
; Entry used by OpSetupWater: HL = (L row, H column), C width, B height, E flag
; value; the script pointer is on the stack and is popped into HL at the end.
SetFlagRect:
  PUSH BC
  PUSH HL
  LD B,C
SetFlagRect_Cell:
  PUSH HL                 ; one cell of the row
  CALL SetTileFlag
  POP HL
  INC H                   ; next column
  DJNZ SetFlagRect_Cell
  POP HL
  POP BC
  INC L                   ; next row
  DJNZ SetFlagRect
  POP HL
  RET

; Store a flag value in the tile flag map
;
; Finds the tile map cell with TileMapAddress and writes E three pages higher,
; in the tile flag map (FlagMapAddress gives the same address). HL is left at
; the flag (SetFlagRect keeps its own copy).
;
;   L Row 0-21
;   H Column 0-31
;   E Flag value
SetTileFlag:
  CALL TileMapAddress
  LD A,FLAGS_PAGE_OFFSET  ; the flag map is 3 pages above the tile map
  ADD A,H
  LD H,A
  LD (HL),E
  RET

; Script code $97: unpack sprite set A into the sprite sheet
;
; Operand: one byte, a record number 0-19. Calls UnpackSpriteSet, which reads
; the 6-byte record at $AE9D + 6 x number (destination, source, flags, width)
; and unpacks that packed graphic into the columns of the sprite sheet that are
; filled per room. Used 32 times: the room scripts start with the sprites the
; room needs.
;
;   HL Script pointer, at the operands
; O:HL Script pointer after the operands
OpUnpackSprites:
  LD A,(HL)
  INC HL
  PUSH HL
  CALL UnpackSpriteSet
  POP HL
  RET

; Script code $9B: draw several vertical lines of one tile
;
; Operands: tile, count, then count groups of three bytes (row, column,
; length). Each group draws a vertical line of that tile, length cells long,
; from (row, column) downwards (DrawTileVLine). Used 9 times.
;
;   HL Script pointer, at the operands
; O:HL Script pointer after the operands
OpTileVLines:
  LD C,(HL)
  INC HL
  LD B,(HL)
  INC HL
OpTileVLines_Loop:
  PUSH BC
  CALL DrawTileVLine
  POP BC
  DJNZ OpTileVLines_Loop
  RET

; Script code $9A: draw one vertical line of a tile (never used)
;
; Operands: tile, row, column, length. Loads the tile number into C and
; continues in DrawTileVLine. No room script uses it (a static decode of the
; scripts at $726A-$83A7 finds no $9A).
;
;   HL Script pointer, at the operands
; O:HL Script pointer after the operands
OpTileVLine:
  LD C,(HL)               ; C = tile
  INC HL

; Draw a vertical line of one tile
;
; Reads row, column and length from the script and hands over to the rectangle
; fill FillTilesRect with a width of 1: the tile goes in each of the length
; cells below the start, through PlaceTile.
;
;   C Tile number
;   HL Script pointer, at (row, column, length)
; O:HL Script pointer after the three bytes
DrawTileVLine:
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD B,(HL)
  INC HL
  LD A,C
  LD C,$01
  JP FillTilesRect        ; rectangle fill with width 1 (C), tile in A, height
                          ; B

; Script code $9D: set up the water row and its reflection
;
; Operands: row, column, attribute, width. Makes a row of width cells the monk
; can drown in and shows the scenery above it mirrored in it. First it writes 0
; (NOP) over the RET at DrawWaterReflection so that routine runs from the main
; loop on every frame, and patches that routine's operands: the attribute and
; the width, the address of the attribute cells, and the two bitmap addresses of
; the copy (the source starts at the top pixel line of the cell row 3 rows
; above, the destination at the bottom pixel line of the water cell row; the
; copy takes every third line going down and writes going up, so the three rows
; above come out squashed and upside down: a reflection); the JR into the LDI
; chain is set to copy `width` bytes per pixel line and the BC count to width x
; 8. Observed with operands 21, 6, $13, 16: the operands written are $5AA6, $13,
; 16, $5046, $57A6, $0080 and the JR offset $20. Finally it stores the flag
; value 4 in the width cells (the entry SetFlagRect of OpSetFlagRect), which
; kills the monk when he enters them (observed in room 16).
;
; Used twice: room 16 (lake, $7D5C: row 21, column 6, attribute $13, width 16)
; and room 19 (river, $7F7A: row 21, column 14, attribute $0D, width 16).
;
; Hardware: only through the patched DrawWaterReflection, which writes the
; attribute file and the screen bitmap.
;
;   HL Script pointer, at the operands
; O:HL Script pointer after the operands
OpSetupWater:
  XOR A
  LD (DrawWaterReflection),A ; NOP over the RET at $AD88: the effect runs every
                             ; frame
  LD E,(HL)               ; E = row, D = column
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  LD (SmcWaterAttr+$0001),A ; attribute: operand of the LD A,n at $AD8C
  INC HL
  LD A,(HL)
  LD (SmcWaterWidth+$0001),A ; width: operand of the LD B,n at $AD8E
  LD C,A
  LD B,$01
  INC HL
  PUSH HL
  PUSH DE
  PUSH BC
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD (SmcWaterCount+$0001),HL ; width x 8: the count in the LD BC,nn at $AD9A
  SUB LDI_CHAIN_LEN
  NEG
  ADD A,A
  LD (SmcWaterJump+$0001),A ; offset of the JR at $AD9F: skips 32 - width LDIs
                            ; of the chain
  EX DE,HL
  CALL AttrAddress        ; attribute address of the first cell
  LD (SmcWaterAttrAddr+$0001),HL ; operand of the LD HL,nn at $AD89
  CALL AttrToBitmap       ; bitmap address of the cell
  LD D,H
  LD A,L
  SUB $03*SCREEN_COLS     ; three cell rows up (the source of the copy)
  LD E,A
  JR NC,OpSetupWater_0
  LD A,H
  SUB $08
  LD D,A
OpSetupWater_0:
  LD A,CELL_SIZE-$01      ; bottom pixel line of the water cell row
  ADD A,H
  LD H,A
  LD (SmcWaterSrc+$0001),DE ; source: operand of the LD HL,nn at $AD94
  LD (SmcWaterDst+$0001),HL ; destination: operand of the LD DE,nn at $AD97
  LD H,A
  POP BC
  POP HL
  LD E,TILE_HARMFUL       ; flag value of the water cells
  JP SetFlagRect          ; set the flags of the width cells (B = 1 row)

; Script code $9E: start the bubbling blood tiles of the bottom row
;
; No operands. Writes 0 (NOP) over the RET at AnimateBloodTiles, so that
; routine runs from the main loop on every frame; it swaps the tiles $3B and
; $3C in the bottom row of the tile map (row 21) every second pass and marks
; those cells for redraw. Observed 40 frames after entering the room: $AE20
; holds 0 in rooms 21, 22 and 23 and $C9 in rooms 5, 16, 19 and 24, so the room
; entry puts the RET back. Used by rooms 21, 22 and 23 ($80FB, $81C1, $8263).
OpAnimateBlood:
  XOR A
  LD (AnimateBloodTiles),A ; NOP over the RET at $AE20
  RET

; Script code $9F: start the twelve-crosses effect
;
; No operands. Writes 0 (NOP) over the RET at ShowCrossRing, so that routine
; runs from the main loop on every frame; once the player holds 12 crosses
; ($854D) it adds the crosses one by one (tile $4C) at the cells of the list
; CrossRingPositions ($82D7, the positions of the script ScriptEraseCrosses,
; which blanks the same cells when the chalice is taken). Observed 40 frames
; after entering the room: $AE4B holds 0 in room 24 (and 25, F10) and $C9 in
; rooms 5, 16, 19, 21, 22 and 23. Used once, at the end of room 24's script
; ($82CE), which room 25 calls.
OpTwelveCrosses:
  XOR A
  LD (ShowCrossRing),A    ; NOP over the RET at $AE4B
  RET
