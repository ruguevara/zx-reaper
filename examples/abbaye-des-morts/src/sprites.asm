; Queue a masked sprite: clip it, flag its cells, add a job to the draw queue
;
; A routine of the frame call list. The frame code appends draw commands (a
; routine address and 8 bytes of parameters, see SpriteCmd) to the call list at
; $BE5A, and the routine at $BDDB runs the list by RET with SP at its start. So
; this routine is entered by a RET and finds its parameters on the stack: it
; pops all eight bytes and ends with a RET into the next entry of the list (the
; early RETs taken when nothing is visible do the same).
;
; The sprite is clipped to the room area. x is a byte column (0-31), y a row of
; 2 pixels (0-87, 4 per character row), the height is in 2-pixel units and the
; width in bytes. An x of $20 or more, or a y of $58 or more, is a negative
; position (the sprite starts left of or above the room): the hidden columns or
; rows are skipped in the graphics and the size is cut; a sprite wholly outside
; the room is dropped. Then each character cell the sprite covers gets bit 6
; set and bit 7 clear in the tile flag map at $5E00 (one byte per cell, 32 per
; row, 3 pages above the tile map). BuildRedrawList takes cells with either bit
; into the redraw run list of the frame and CollectRedrawRun then turns bit 6
; into bit 7, so that the next frame redraws the cell from the tile map and so
; erases the sprite from its old place (observed on the monk's cell: $80 -> $C0
; -> $40 here, $40 -> $00 -> $80 in CollectRedrawRun). The clipped values go
; into the job template SpriteJob, which AddQueueJob appends to the draw queue
; at $C000; DrawSpriteJob draws the sprite into the redraw cell buffers when
; BuildRedrawList runs the queue.
;
; The graphics are in the sprite sheet (SpriteSheet): a 256-byte page per pixel
; row and one byte per column, so the graphics address has the pixel row in D
; and the first column in E.
;
; The parameters are not in registers: the routine pops them from the call list,
; in this order: the position (low byte y in 2-pixel units, high byte x byte
; column), the address of the graphics in the sprite sheet (high byte pixel row,
; low byte column), the size (low byte width in bytes 1-5, high byte height in
; 2-pixel units) and the attribute of the sprite's cells (high byte; the low
; byte is popped into F and not used). SP stays in the call list while it runs,
; so its CALL FlagMapAddress and PUSH BC write over the bytes of its own
; command, which are already popped (observed: writes from $9898 and $989C into
; $BE62-$BE8B during play; F151). An interrupt in the middle writes there too
; and the PUSH BC of InterruptHandler leaves BC in those two bytes, which is
; harmless here for the same reason.
;
; Observed: 903 sprites queued by hand on a room 5 snapshot (widths 1-5,
; heights 1-12, y offsets 0-3 in the cell row, clipped at all four edges) and
; drawn by BuildRedrawList and DrawRedrawList put exactly (OutlineMasks[g] AND
; background) OR g on the screen at pixel row 2y and byte column x, nothing
; for a sprite wholly outside.
;
; Hardware: none; it only changes the tile flag map in RAM. The screen is
; written later, by DrawRedrawList.
QueueSprite:
  POP HL
  POP DE
  POP BC
  POP AF
  LD (SpriteJobAttr),A    ; attribute
; Clip horizontally. H >= $20 means the sprite starts left of the room: if some
; of it shows, shorten the width, skip the hidden columns of the graphics (E =
; E - H) and start at column 0.
  LD A,H
  CP SCREEN_COLS
  JR C,QueueSprite_0
  ADD A,C
  RET Z
  RET NC
  LD C,A
  LD A,E
  SUB H
  LD E,A
  LD H,$00
  JR QueueSprite_ClipY
; H < $20: if the sprite runs past column 31, shorten the width.
QueueSprite_0:
  ADD A,C
  SUB SCREEN_COLS
  JR C,QueueSprite_ClipY
  NEG
  ADD A,C
  LD C,A
; Clip vertically the same way: L >= $58 means the sprite starts above the room
; (D skips 2 pixel rows of graphics per unit); otherwise cut the height at the
; bottom.
QueueSprite_ClipY:
  LD A,L
  CP ROOM_HEIGHT_2PX
  JR C,QueueSprite_1
  ADD A,B
  RET Z
  RET NC
  LD B,A
  LD A,D
  SUB L
  SUB L
  LD D,A
  LD L,$00
  JR QueueSprite_Fill
QueueSprite_1:
  ADD A,B
  SUB ROOM_HEIGHT_2PX
  JR C,QueueSprite_Fill
  NEG
  ADD A,B
  LD B,A
; Fill the job template: graphics address, height, offset inside the cell row
; (y mod 4), cell rows covered (rounded up), cell row (y / 4) and column,
; width.
QueueSprite_Fill:
  LD (SpriteJobGfx),DE    ; graphics address
  LD A,B
  LD (SpriteJobHeight),A  ; height
  LD A,L
  AND SUBROW_MASK
  LD (SpriteJobSubRow),A  ; offset of the first row inside its cell
  ADD A,B
  LD B,A
  SRL B
  SRL B
  AND SUBROW_MASK
  JR Z,QueueSprite_2
  INC B
QueueSprite_2:
  SRL L
  SRL L
  LD (SpriteJobCell),HL
  LD A,B
  LD (SpriteJobRows),A    ; cell rows covered
  LD A,C
  LD (SpriteJobWidth),A   ; width
; Flag the covered cells: HL = address of the top-left cell in the tile flag
; map.
  CALL FlagMapAddress
  LD A,L
QueueSprite_MarkRow:
  PUSH BC
  LD B,C
QueueSprite_MarkCell:
  SET 6,(HL)              ; bit 6 = a sprite is on this cell, bit 7 = already
                          ; in this frame's redraw
  RES 7,(HL)
  INC L
  DJNZ QueueSprite_MarkCell
  POP BC
  ADD A,SCREEN_COLS
  LD L,A
  JR NC,QueueSprite_3
  INC H
QueueSprite_3:
  DJNZ QueueSprite_MarkRow
; Append the job template to the draw queue.
  LD HL,SpriteJob

; Append a job to the draw queue
;
; Append the 16 bytes at HL to the draw queue; also entered from
; QueueBlockSprite with its own template. A template of less than 16 bytes
; brings along the code bytes after it, which nobody uses. The queue tail is
; the operand of the first instruction (BuildRedrawList resets it to $C000
; every frame). There is no check for a full queue (16 jobs): the 17th would be
; copied over the object slots at $C100. The most seen in fuzzed runs of all
; 25 rooms was 14 jobs (F44).
;
; HL Address of the 16-byte job (template)
AddQueueJob:
  LD DE,DrawQueue
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LD (AddQueueJob+$0001),DE ; queue tail moves on
  RET

; Draw-queue job template for a masked sprite
;
; The 16-byte record that QueueSprite fills in and AddQueueJob copies to the
; end of the draw queue at $C000 (the copy also takes the 5 bytes of code after
; the template, which are not used). BuildRedrawList runs the queue: it calls
; the handler in the first word with DE = job address + 1 and clears the word.
; The handler DrawSpriteJob consumes the fields as it draws. Fields:
;
; +0 word: handler address (DrawSpriteJob) +2 word: address of the graphics in
; the sprite sheet, clipped (D = pixel row, E = column) +4 byte: character rows
; covered +5 byte: first character row (0-21) +6 byte: character column (0-31)
; +7 byte: offset of the first pixel row inside its character row, in 2-pixel
; units (0-3); cleared once used +8 byte: height still to draw, in 2-pixel
; units +9 byte: width in bytes (1-5) +10 byte: attribute of the cells
SpriteJob:
  DEFW DrawSpriteJob      ; +0: handler
SpriteJobGfx:
  DEFW $0000              ; +2: graphics address
SpriteJobRows:
  DEFB $00                ; +4: character rows covered
SpriteJobCell:
  DEFW $0000              ; +5: row (low byte), +6: column (high byte)
SpriteJobSubRow:
  DEFB $00                ; +7: first row offset
SpriteJobHeight:
  DEFB $00                ; +8: height
SpriteJobWidth:
  DEFB $00                ; +9: width
SpriteJobAttr:
  DEFB $00                ; +10: attribute

; Find a character row in the redraw run list
;
; The redraw run list at $C200 (built by BuildRedrawList and CollectRedrawRun)
; holds one record per character row that has cells to redraw: the row number,
; the number of runs, and for each run the first column and the index in the
; redraw cell buffers of its first cell (2 bytes per run); the list ends with
; $FF. This searches it from the start for the row whose number is at (DE). The
; row must be in the list: the draw handlers only ask for rows whose cells
; QueueSprite or QueueBlockSprite flagged, and a search for an absent row would
; run on past the end.
;
; Hardware: none.
;
;   DE Address of a byte holding the character row number (the job's row field)
; O:HL Address of the row's first run entry (first column, buffer index of its
;      first cell)
; O:A Number of runs of the row
FindRedrawRow:
  LD HL,RedrawRuns
FindRedrawRow_Next:
  LD A,(DE)
  CP (HL)
  JR Z,FindRedrawRow_0    ; found
  INC L
  LD A,(HL)
  INC L
  ADD A,A                 ; skip the runs: 2 bytes each
  ADD A,L
  LD L,A
  JR FindRedrawRow_Next
FindRedrawRow_0:
  INC L
  LD A,(HL)
  INC L
  RET

; Draw-queue handler: 16-pixel-wide block, unmasked, into the redraw cells
;
; Handler of the jobs that QueueBlockSprite queues (template BlockJob; the
; 16-pixel-wide graphics of the command at ItemCmd). BuildRedrawList calls it
; through JP (HL) with DE = job address + 1, after it has put the background of
; the flagged cells into the redraw cell buffers. For each character row of the
; job it finds the row's run in the redraw run list (FindRedrawRow for the
; first row, then the next record of the list, so the rows must be consecutive
; records) and the index of the job's column among the cells of the run. It
; stores the graphics over the two cells there, 8 pixel rows of 2 bytes in the
; pixel-row pages of the redraw cell buffer ($C500 + 256 x pixel row + index),
; and the attribute at $C400 + index for both cells. No outline mask: the
; background of the cells is replaced. The graphics are read by POP with SP set
; to them (16 bytes per character row, 2 bytes per pixel row); the stores
; alternate between the left and the right cell so that BC needs no swapping.
; SP and the graphics pointer are saved in self-modified operands.
;
; Job fields used (template BlockJob): +2 word graphics address, +4 byte
; character rows, +5 byte first row, +6 byte column, +7 byte attribute.
;
; Hardware: none; the screen is written later by DrawRedrawList. SP points into
; the graphics while it runs.
;
; DE Job address + 1 (the handler word has been read by the caller)
DrawBlockJob:
  EX DE,HL
  INC L                   ; job + 2: the graphics address goes to the operand
                          ; at SmcBlockGfx, job + 4: character rows
  LD C,(HL)
  INC L
  LD B,(HL)
  INC L
  LD (SmcBlockGfx+$0001),BC
  LD B,(HL)
  INC L
  EX DE,HL
; Find the record of the row at DE (job + 5); the INC E then makes DE point at
; the column field (job + 6).
  CALL FindRedrawRow
  INC E
; One character row. Choose the run that holds the column: the last run that
; starts at or before it.
DrawBlockJob_Row:
  PUSH DE
  PUSH BC
DrawBlockJob_0:
  LD C,(HL)
  INC L
  LD B,(HL)
  INC L
  DEC A
  JR Z,DrawBlockJob_2
  EX AF,AF'
  LD A,(DE)
  CP (HL)
  JR C,DrawBlockJob_1
  EX AF,AF'
  JR DrawBlockJob_0
DrawBlockJob_1:
  EX AF,AF'
  ADD A,A
  ADD A,L
  LD L,A
; Cell index = column - first column of the run + index of the run's first
; cell; BC = page $C5, index = the cell's first pixel row in the redraw buffer.
; A = the attribute (job + 7).
DrawBlockJob_2:
  EX DE,HL
  LD A,(HL)
  SUB C
  ADD A,B
  LD C,A
  INC L
  LD B,PAGE_REDRAW_PIXELS
  PUSH BC
  LD A,(HL)
; Alternate set: DE = cell address in the buffer.
  EXX
  POP DE
  LD (SmcBlockSP+$0001),SP ; save SP
; The operand is the address of the next 16 bytes of graphics: set at 98FD,
; moved on at 995C after each row.
SmcBlockGfx:
  LD HL,SmcBlockGfx
; First pixel row: take 2 bytes from the graphics, then POP the 7 other pairs,
; storing left/right or right/left.
  LD C,(HL)
  INC HL
  LD B,(HL)
  INC HL
  LD SP,HL                ; SP = graphics
  EX DE,HL
  LD (HL),C
  INC L
  LD (HL),B
  INC H
  POP BC
  LD (HL),B
  DEC L
  LD (HL),C
  INC H
  POP BC
  LD (HL),C
  INC L
  LD (HL),B
  INC H
  POP BC
  LD (HL),B
  DEC L
  LD (HL),C
  INC H
  POP BC
  LD (HL),C
  INC L
  LD (HL),B
  INC H
  POP BC
  LD (HL),B
  DEC L
  LD (HL),C
  INC H
  POP BC
  LD (HL),C
  INC L
  LD (HL),B
  INC H
  POP BC
  LD (HL),B
  DEC L
  LD (HL),C
  LD (SmcBlockGfx+$0001),SP ; graphics pointer for the next row
; The operand is the stack pointer saved at 9929.
SmcBlockSP:
  LD SP,SmcBlockSP        ; restore SP
; Attribute of both cells.
  LD H,PAGE_REDRAW_ATTRS
  LD (HL),A
  INC L
  LD (HL),A
  EXX
; Next character row: HL = the record after this row's runs; skip its row
; number and read its run count.
  EX DE,HL
  POP BC
  POP DE
  INC L
  LD A,(HL)
  INC L
  DJNZ DrawBlockJob_Row
  RET

; Draw-queue handler: masked sprite into the redraw cells
;
; Handler of the jobs that QueueSprite queues (template SpriteJob).
; BuildRedrawList calls it through JP (HL) with DE = job address + 1, after it
; has put the background of the flagged cells into the redraw cell buffers. For
; each character row of the job it finds the row's run in the redraw run list
; (FindRedrawRow for the first row, then the next record of the list, so the
; rows must be consecutive records) and the index of the job's column among the
; cells of the run. It works out how many pairs of pixel rows of the sprite fit
; in the character row (4 minus the offset of the first row, at most the height
; left; the job's offset and height are updated for the next row) and calls
; DispatchDrawer, which runs the drawer for the sprite's width: for every
; graphics byte g it stores (OutlineMasks[g] AND background) OR g, the sprite
; over the background with the pixels next to the sprite's own pixels (one to
; the left and one to the right, inside the same byte: the table works on one
; byte, so there is no outline across a byte edge, nor above or below) cleared
; first (F37). The drawer also stores the
; attribute of the covered cells at $C400 + index.
;
; The drawers work in the alternate register set: HL' = destination in the
; redraw cell buffer (H = $C5 + 2 x offset selects the pixel row, L = cell
; index), DE' = graphics (D = pixel row, E = column; D carries on down the
; sprite sheet from one character row to the next), B' = $FF so that BC'
; addresses the outline mask table OutlineMasks ($FF00) by the graphics byte in
; C'.
;
; Hardware: none; the screen is written later by DrawRedrawList.
;
; DE Job address + 1 (the handler word has been read by the caller)
DrawSpriteJob:
  EX DE,HL
  INC L
  LD C,(HL)
  INC L
  LD B,(HL)
  INC L
  PUSH BC
  EXX                     ; alternate set: B' = $FF, DE' = graphics address
  LD B,OutlineMasks>>8
  POP DE
  EXX
  LD B,(HL)               ; B = number of character rows
  INC L
  EX DE,HL
; Find the record of the row at DE (job + 5); the INC E then makes DE point at
; the column field (job + 6).
  CALL FindRedrawRow
  INC E
; One character row. Choose the run that holds the column: the last run that
; starts at or before it.
DrawSpriteJob_Row:
  PUSH DE
  PUSH BC
DrawSpriteJob_0:
  LD C,(HL)
  INC L
  LD B,(HL)
  INC L
  DEC A
  JR Z,DrawSpriteJob_2
  EX AF,AF'
  LD A,(DE)
  CP (HL)
  JR C,DrawSpriteJob_1
  EX AF,AF'
  JR DrawSpriteJob_0
DrawSpriteJob_1:
  EX AF,AF'
  ADD A,A
  ADD A,L
  LD L,A
; Cell index = column - first column of the run + index of the run's first
; cell; HL' = $C5 + 2 x (offset of the first row) in the high byte, the index
; in the low byte.
DrawSpriteJob_2:
  EX DE,HL
  LD A,(HL)
  SUB C
  ADD A,B
  LD C,A
  INC L
  LD A,(HL)
  ADD A,A
  ADD A,PAGE_REDRAW_PIXELS
  LD B,A
  PUSH BC
  EXX
  POP HL
  EXX
; C = pairs of pixel rows to draw in this character row = 4 - offset, but at
; most the height left. The offset is cleared and the height reduced in the
; job.
  LD B,(HL)
  LD A,SUBROWS_PER_CELL
  SUB B
  LD C,A
  LD (HL),$00
  INC L
  LD A,(HL)
  CP C
  JR NC,DrawSpriteJob_3
  LD C,A
DrawSpriteJob_3:
  SUB C                   ; height left after this character row
  LD (HL),A
  INC L
; A = width in bytes, B = attribute (job + 10).
  LD A,(HL)
  INC L
  LD B,(HL)
; Run the drawer: A width, B attribute, C row pairs.
  CALL DispatchDrawer
; Back from the drawer: main registers again. Step to the next record of the
; run list and the next character row.
  EXX
  EX DE,HL
  POP BC
  POP DE
  INC L
  LD A,(HL)
  INC L
  DJNZ DrawSpriteJob_Row
  RET

; Run the sprite drawer for a width and a number of row pairs
;
; Takes the drawer for the sprite's width from SpriteDrawerTable and skips 4 - C
; of its calls: every drawer is four times CALL strip + INC H, 4 bytes each, and
; the calls are alike, so entering later only draws fewer pairs of pixel rows (C
; = 4: the whole character row). Where the pairs land is set by H', which
; DrawSpriteJob points at pixel row 2 x offset of the cell row: the first
; character row of a sprite offset by n 2-pixel units draws 4 - n pairs from
; pixel row 2n, the last row the pairs of height left from pixel row 0 (observed
; with every offset, see QueueSprite). It switches to the alternate register
; set, which holds the drawer's pointers (see DrawSpriteJob), and jumps into the
; drawer with RET. The drawer ends with POP AF, which takes the BC pushed here
; (A = the attribute), and RET: it returns to the caller of this routine, which
; executes EXX to get its own registers back; HL and DE are as they were on
; entry.
;
; Hardware: none.
;
;   A Width of the sprite in bytes (1-5)
;   B Attribute of the cells, passed to the drawer
;   C Pairs of pixel rows to draw (1-4)
;   HL Passed through (the caller's job pointer)
;   DE Passed through (the caller's run pointer)
; O:HL Unchanged
; O:DE Unchanged
DispatchDrawer:
  PUSH BC
  PUSH HL
  PUSH DE
  DEC A
  ADD A,A
  LD HL,SpriteDrawerTable
  LD E,A
  LD D,$00
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
; HL = 4, the size of CALL + INC H; after the swap HL = the drawer and DE = 4.
  LD HL,$0004
  EX DE,HL
; Skip 4 - C of the strip calls: HL = drawer + 4 x (4 - C).
  LD A,E
  SUB C
  JR Z,DispatchDrawer_0
  LD B,A
DispatchDrawer_Skip:
  ADD HL,DE
  DJNZ DispatchDrawer_Skip
; Stack: drawer address, BC, return address; HL = the caller's job pointer
; again. EXX, then RET into the drawer.
DispatchDrawer_0:
  POP DE
  EX (SP),HL
  EXX
  RET

; Table of the five sprite drawers
;
; Words indexed by the sprite width in bytes minus 1; DispatchDrawer jumps
; through it. Each drawer draws one character row of the sprite (up to 8 pixel
; rows) as four calls of its strip routine.
;
; +0 word: DrawSpriteW1, 1 byte wide +2 word: DrawSpriteW2, 2 bytes wide +4
; word: DrawSpriteW3, 3 bytes wide +6 word: DrawSpriteW4, 4 bytes wide +8 word:
; DrawSpriteW5, 5 bytes wide
SpriteDrawerTable:
  DEFW DrawSpriteW1       ; width 1
  DEFW DrawSpriteW2       ; width 2
  DEFW DrawSpriteW3       ; width 3
  DEFW DrawSpriteW4       ; width 4
  DEFW DrawSpriteW5       ; width 5

; Draw two pixel rows of a 1-byte-wide sprite
;
; Called four times per character row by DrawSpriteW1. For each of the two
; pixel rows: C = the graphics byte from (DE); the destination byte becomes
; (OutlineMasks[C] AND old byte) OR C: the sprite replaces the background under
; its own pixels and under the pixel on either side of each of them, which
; gives it a one-pixel outline. HL moves down one pixel row in between (the
; caller adds the next INC H) and DE down two.
;
; The pointers are in the alternate register set (see DrawSpriteJob): HL =
; destination in the redraw cell buffer (H = pixel-row page, L = cell index),
; DE = graphics in the sprite sheet (D = pixel row, E = column), B = $FF so
; that BC addresses the outline mask table OutlineMasks ($FF00) by the graphics
; byte in C.
;
; Hardware: none (the redraw cell buffer is in RAM).
;
;   BC B = $FF; C is scratch
;   DE Graphics: D = pixel row, E = column of the first byte
;   HL Destination in the redraw cell buffer: H = pixel-row page, L = cell
;      index of the first byte
; O:DE D advanced by 2 pixel rows
; O:HL H advanced by 1 pixel row
DrawStripW1:
  LD A,(DE)
  LD C,A                  ; C = graphics byte
  LD A,(BC)               ; A = outline mask of the byte
  AND (HL)                ; clear the pixels around the sprite's pixels
  OR C                    ; set the sprite's pixels
  LD (HL),A
  INC H
  INC D
  LD A,(DE)
  LD C,A
  LD A,(BC)
  AND (HL)
  OR C
  LD (HL),A
  INC D
  RET

; Draw a 1-byte-wide sprite across one character row
;
; The drawer for width 1 of the table SpriteDrawerTable, run by DispatchDrawer
; through RET in the alternate register set: four calls of DrawStripW1, each
; drawing two pixel rows (8 pixel rows in all); DispatchDrawer may enter at a
; later call to draw fewer. After the last call, POP AF takes the BC that
; DispatchDrawer pushed (A = the attribute) and the attribute is stored at
; $C400 + cell index for each of the 1 cell of the character row; RET returns
; to the caller of DispatchDrawer (DrawSpriteJob).
;
; Hardware: none (the redraw cell buffer is in RAM).
;
; BC B = $FF (alternate set; used by the strip routine)
; DE Graphics: D = pixel row, E = column of the first byte (alternate set)
; HL Destination: H = $C5 + first pixel row, L = cell index of the first byte
;    (alternate set)
DrawSpriteW1:
  CALL DrawStripW1
  INC H
  CALL DrawStripW1
  INC H
  CALL DrawStripW1
  INC H
  CALL DrawStripW1
  POP AF
; Attribute of the covered cells.
  LD H,PAGE_REDRAW_ATTRS
  LD (HL),A
  RET

; Draw two pixel rows of a 2-byte-wide sprite
;
; Called four times per character row by DrawSpriteW2. The first pixel row is
; stored from the left byte to the right, the second from the right byte to the
; left, so that HL and DE are back at the first column at the end and no
; pointer has to be reloaded. Each byte is combined with the background as in
; DrawStripW1: (OutlineMasks[g] AND old byte) OR g. HL ends one pixel row down
; and DE two rows down.
;
; The pointers are in the alternate register set (see DrawSpriteJob): HL =
; destination in the redraw cell buffer (H = pixel-row page, L = cell index),
; DE = graphics in the sprite sheet (D = pixel row, E = column), B = $FF so
; that BC addresses the outline mask table OutlineMasks ($FF00) by the graphics
; byte in C.
;
; Hardware: none (the redraw cell buffer is in RAM).
;
;   BC B = $FF; C is scratch
;   DE Graphics: D = pixel row, E = column of the first byte
;   HL Destination in the redraw cell buffer: H = pixel-row page, L = cell
;      index of the first byte
; O:DE D advanced by 2 pixel rows
; O:HL H advanced by 1 pixel row
DrawStripW2:
  LD A,(DE)
  LD C,A
  LD A,(BC)
  AND (HL)
  OR C
  LD (HL),A
  INC L
  INC E
  LD A,(DE)
  LD C,A
  LD A,(BC)
  AND (HL)
  OR C
  LD (HL),A
  INC H
  INC D
  LD A,(DE)
  LD C,A
  LD A,(BC)
  AND (HL)
  OR C
  LD (HL),A
  DEC L
  DEC E
  LD A,(DE)
  LD C,A
  LD A,(BC)
  AND (HL)
  OR C
  LD (HL),A
  INC D
  RET

; Draw a 2-byte-wide sprite across one character row
;
; The drawer for width 2 of the table SpriteDrawerTable, run by DispatchDrawer
; through RET in the alternate register set: four calls of DrawStripW2, each
; drawing two pixel rows (8 pixel rows in all); DispatchDrawer may enter at a
; later call to draw fewer. After the last call, POP AF takes the BC that
; DispatchDrawer pushed (A = the attribute) and the attribute is stored at
; $C400 + cell index for each of the 2 cells of the character row; RET returns
; to the caller of DispatchDrawer (DrawSpriteJob).
;
; Hardware: none (the redraw cell buffer is in RAM).
;
; BC B = $FF (alternate set; used by the strip routine)
; DE Graphics: D = pixel row, E = column of the first byte (alternate set)
; HL Destination: H = $C5 + first pixel row, L = cell index of the first byte
;    (alternate set)
DrawSpriteW2:
  CALL DrawStripW2
  INC H
  CALL DrawStripW2
  INC H
  CALL DrawStripW2
  INC H
  CALL DrawStripW2
  POP AF
; Attribute of the covered cells.
  LD H,PAGE_REDRAW_ATTRS
  LD (HL),A
  INC L
  LD (HL),A
  RET

; Draw two pixel rows of a 3-byte-wide sprite
;
; Called four times per character row by DrawSpriteW3. The first pixel row is
; stored from the left byte to the right, the second from the right byte to the
; left, so that HL and DE are back at the first column at the end and no
; pointer has to be reloaded. Each byte is combined with the background as in
; DrawStripW1: (OutlineMasks[g] AND old byte) OR g. HL ends one pixel row down
; and DE two rows down.
;
; The pointers are in the alternate register set (see DrawSpriteJob): HL =
; destination in the redraw cell buffer (H = pixel-row page, L = cell index),
; DE = graphics in the sprite sheet (D = pixel row, E = column), B = $FF so
; that BC addresses the outline mask table OutlineMasks ($FF00) by the graphics
; byte in C.
;
; Hardware: none (the redraw cell buffer is in RAM).
;
;   BC B = $FF; C is scratch
;   DE Graphics: D = pixel row, E = column of the first byte
;   HL Destination in the redraw cell buffer: H = pixel-row page, L = cell
;      index of the first byte
; O:DE D advanced by 2 pixel rows
; O:HL H advanced by 1 pixel row
DrawStripW3:
  LD A,(DE)
  LD C,A
  LD A,(BC)
  AND (HL)
  OR C
  LD (HL),A
  INC L
  INC E
  LD A,(DE)
  LD C,A
  LD A,(BC)
  AND (HL)
  OR C
  LD (HL),A
  INC L
  INC E
  LD A,(DE)
  LD C,A
  LD A,(BC)
  AND (HL)
  OR C
  LD (HL),A
  INC H
  INC D
  LD A,(DE)
  LD C,A
  LD A,(BC)
  AND (HL)
  OR C
  LD (HL),A
  DEC L
  DEC E
  LD A,(DE)
  LD C,A
  LD A,(BC)
  AND (HL)
  OR C
  LD (HL),A
  DEC L
  DEC E
  LD A,(DE)
  LD C,A
  LD A,(BC)
  AND (HL)
  OR C
  LD (HL),A
  INC D
  RET

; Draw a 3-byte-wide sprite across one character row
;
; The drawer for width 3 of the table SpriteDrawerTable, run by DispatchDrawer
; through RET in the alternate register set: four calls of DrawStripW3, each
; drawing two pixel rows (8 pixel rows in all); DispatchDrawer may enter at a
; later call to draw fewer. After the last call, POP AF takes the BC that
; DispatchDrawer pushed (A = the attribute) and the attribute is stored at
; $C400 + cell index for each of the 3 cells of the character row; RET returns
; to the caller of DispatchDrawer (DrawSpriteJob).
;
; Hardware: none (the redraw cell buffer is in RAM).
;
; BC B = $FF (alternate set; used by the strip routine)
; DE Graphics: D = pixel row, E = column of the first byte (alternate set)
; HL Destination: H = $C5 + first pixel row, L = cell index of the first byte
;    (alternate set)
DrawSpriteW3:
  CALL DrawStripW3
  INC H
  CALL DrawStripW3
  INC H
  CALL DrawStripW3
  INC H
  CALL DrawStripW3
  POP AF
; Attribute of the covered cells.
  LD H,PAGE_REDRAW_ATTRS
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  RET

; Draw two pixel rows of a 4-byte-wide sprite
;
; Called four times per character row by DrawSpriteW4. The first pixel row is
; stored from the left byte to the right, the second from the right byte to the
; left, so that HL and DE are back at the first column at the end and no
; pointer has to be reloaded. Each byte is combined with the background as in
; DrawStripW1: (OutlineMasks[g] AND old byte) OR g. HL ends one pixel row down
; and DE two rows down.
;
; The pointers are in the alternate register set (see DrawSpriteJob): HL =
; destination in the redraw cell buffer (H = pixel-row page, L = cell index),
; DE = graphics in the sprite sheet (D = pixel row, E = column), B = $FF so
; that BC addresses the outline mask table OutlineMasks ($FF00) by the graphics
; byte in C.
;
; Hardware: none (the redraw cell buffer is in RAM).
;
;   BC B = $FF; C is scratch
;   DE Graphics: D = pixel row, E = column of the first byte
;   HL Destination in the redraw cell buffer: H = pixel-row page, L = cell
;      index of the first byte
; O:DE D advanced by 2 pixel rows
; O:HL H advanced by 1 pixel row
DrawStripW4:
  LD A,(DE)
  LD C,A
  LD A,(BC)
  AND (HL)
  OR C
  LD (HL),A
  INC L
  INC E
  LD A,(DE)
  LD C,A
  LD A,(BC)
  AND (HL)
  OR C
  LD (HL),A
  INC L
  INC E
  LD A,(DE)
  LD C,A
  LD A,(BC)
  AND (HL)
  OR C
  LD (HL),A
  INC L
  INC E
  LD A,(DE)
  LD C,A
  LD A,(BC)
  AND (HL)
  OR C
  LD (HL),A
  INC H
  INC D
  LD A,(DE)
  LD C,A
  LD A,(BC)
  AND (HL)
  OR C
  LD (HL),A
  DEC L
  DEC E
  LD A,(DE)
  LD C,A
  LD A,(BC)
  AND (HL)
  OR C
  LD (HL),A
  DEC L
  DEC E
  LD A,(DE)
  LD C,A
  LD A,(BC)
  AND (HL)
  OR C
  LD (HL),A
  DEC L
  DEC E
  LD A,(DE)
  LD C,A
  LD A,(BC)
  AND (HL)
  OR C
  LD (HL),A
  INC D
  RET

; Draw a 4-byte-wide sprite across one character row
;
; The drawer for width 4 of the table SpriteDrawerTable, run by DispatchDrawer
; through RET in the alternate register set: four calls of DrawStripW4, each
; drawing two pixel rows (8 pixel rows in all); DispatchDrawer may enter at a
; later call to draw fewer. After the last call, POP AF takes the BC that
; DispatchDrawer pushed (A = the attribute) and the attribute is stored at
; $C400 + cell index for each of the 4 cells of the character row; RET returns
; to the caller of DispatchDrawer (DrawSpriteJob).
;
; Hardware: none (the redraw cell buffer is in RAM).
;
; BC B = $FF (alternate set; used by the strip routine)
; DE Graphics: D = pixel row, E = column of the first byte (alternate set)
; HL Destination: H = $C5 + first pixel row, L = cell index of the first byte
;    (alternate set)
DrawSpriteW4:
  CALL DrawStripW4
  INC H
  CALL DrawStripW4
  INC H
  CALL DrawStripW4
  INC H
  CALL DrawStripW4
  POP AF
; Attribute of the covered cells.
  LD H,PAGE_REDRAW_ATTRS
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  RET

; Draw two pixel rows of a 5-byte-wide sprite
;
; Called four times per character row by DrawSpriteW5. The first pixel row is
; stored from the left byte to the right, the second from the right byte to the
; left, so that HL and DE are back at the first column at the end and no
; pointer has to be reloaded. Each byte is combined with the background as in
; DrawStripW1: (OutlineMasks[g] AND old byte) OR g. HL ends one pixel row down
; and DE two rows down.
;
; The pointers are in the alternate register set (see DrawSpriteJob): HL =
; destination in the redraw cell buffer (H = pixel-row page, L = cell index),
; DE = graphics in the sprite sheet (D = pixel row, E = column), B = $FF so
; that BC addresses the outline mask table OutlineMasks ($FF00) by the graphics
; byte in C.
;
; Hardware: none (the redraw cell buffer is in RAM).
;
;   BC B = $FF; C is scratch
;   DE Graphics: D = pixel row, E = column of the first byte
;   HL Destination in the redraw cell buffer: H = pixel-row page, L = cell
;      index of the first byte
; O:DE D advanced by 2 pixel rows
; O:HL H advanced by 1 pixel row
DrawStripW5:
  LD A,(DE)
  LD C,A
  LD A,(BC)
  AND (HL)
  OR C
  LD (HL),A
  INC L
  INC E
  LD A,(DE)
  LD C,A
  LD A,(BC)
  AND (HL)
  OR C
  LD (HL),A
  INC L
  INC E
  LD A,(DE)
  LD C,A
  LD A,(BC)
  AND (HL)
  OR C
  LD (HL),A
  INC L
  INC E
  LD A,(DE)
  LD C,A
  LD A,(BC)
  AND (HL)
  OR C
  LD (HL),A
  INC L
  INC E
  LD A,(DE)
  LD C,A
  LD A,(BC)
  AND (HL)
  OR C
  LD (HL),A
  INC H
  INC D
  LD A,(DE)
  LD C,A
  LD A,(BC)
  AND (HL)
  OR C
  LD (HL),A
  DEC L
  DEC E
  LD A,(DE)
  LD C,A
  LD A,(BC)
  AND (HL)
  OR C
  LD (HL),A
  DEC L
  DEC E
  LD A,(DE)
  LD C,A
  LD A,(BC)
  AND (HL)
  OR C
  LD (HL),A
  DEC L
  DEC E
  LD A,(DE)
  LD C,A
  LD A,(BC)
  AND (HL)
  OR C
  LD (HL),A
  DEC L
  DEC E
  LD A,(DE)
  LD C,A
  LD A,(BC)
  AND (HL)
  OR C
  LD (HL),A
  INC D
  RET

; Draw a 5-byte-wide sprite across one character row
;
; The drawer for width 5 of the table SpriteDrawerTable, run by DispatchDrawer
; through RET in the alternate register set: four calls of DrawStripW5, each
; drawing two pixel rows (8 pixel rows in all); DispatchDrawer may enter at a
; later call to draw fewer. After the last call, POP AF takes the BC that
; DispatchDrawer pushed (A = the attribute) and the attribute is stored at
; $C400 + cell index for each of the 5 cells of the character row; RET returns
; to the caller of DispatchDrawer (DrawSpriteJob).
;
; Hardware: none (the redraw cell buffer is in RAM).
;
; BC B = $FF (alternate set; used by the strip routine)
; DE Graphics: D = pixel row, E = column of the first byte (alternate set)
; HL Destination: H = $C5 + first pixel row, L = cell index of the first byte
;    (alternate set)
DrawSpriteW5:
  CALL DrawStripW5
  INC H
  CALL DrawStripW5
  INC H
  CALL DrawStripW5
  INC H
  CALL DrawStripW5
  POP AF
; Attribute of the covered cells.
  LD H,PAGE_REDRAW_ATTRS
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  RET

; Draw the flagged cells of the room, sweeping in the direction of the last
; exit
;
; Redraws the room area (32 x 22 character cells) from the tile map: every cell
; whose redraw flag (bit 7 in the tile flag map) is set is drawn by RedrawCell,
; the others are skipped. Called after a room has been built (MainLoop: every
; cell is flagged by then, by the $90 1 of the room name panel script
; ScriptRoomPanel or of room 4's script, except the water cells of rooms 16 and
; 19, whose flag OpSetupWater sets to 4 afterwards and which DrawWaterReflection
; paints; observed at the call in rooms 1-24, F152), by the intro RunIntro (room
; 0's script clears every mark with $90 0 so that the intro text stays: only the
; cell at $6000 is drawn, see OpMarkRedraw) and by ShowTextWindow after a
; parchment or an ending window. The cells are visited line by line in an order
; taken from the table SweepSetups, indexed by the exit direction in $850B (0 =
; left to right by columns, after leaving the room through the right edge; 1 =
; right to left; 2 = top to bottom by rows, after leaving through the bottom
; edge; 3 = bottom to top). There is no waiting, but the drawing of 704 cells
; takes about 8 frames (observed: 580,000 to 650,000 T-states), so the new room
; is seen to wipe in.
;
; The four step bytes of the setup are copied into the operands of the LD A,0
; instructions at SmcSweepInnerCol, SmcSweepInnerRow, SmcSweepOuterCol and
; SmcSweepOuterRow, which add them to the column (H) and row (L) after every
; cell and after every line.
;
; Hardware: writes the attribute and bitmap of the flagged cells on screen
; (through RedrawCell); no port or interrupt use.
;
; All registers are changed.
RedrawRoom:
  LD A,(ExitDirection)    ; direction of the last exit
  ADD A,A                 ; x8: offset of the setup
  ADD A,A
  ADD A,A
  LD HL,SweepSetups
  CALL AddAToHL           ; HL = HL + A
; B = number of lines, C = cells per line; DE = start row (E), column (D); DE
; and BC are kept for the loop.
  LD B,(HL)
  INC HL
  LD C,(HL)
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  PUSH DE
  PUSH BC
; Copy the 4 step bytes to the operands below.
  LD DE,SmcSweepInnerCol+$0001
  LDI
  LD DE,SmcSweepInnerRow+$0001
  LDI
  LD DE,SmcSweepOuterCol+$0001
  LDI
  LD DE,SmcSweepOuterRow+$0001
  LDI
; HL = start (H = column, L = row); one line per pass of the outer loop.
  POP BC
  POP HL
RedrawRoom_Line:
  PUSH BC
  PUSH HL
  LD B,C
RedrawRoom_Cell:
  PUSH HL
  PUSH BC
; Draw the cell at (H = column, L = row) if it is flagged.
  CALL RedrawCell
  POP BC
  POP HL
; Operand = step of the column between cells of a line (setup byte 4).
SmcSweepInnerCol:
  LD A,$00
  ADD A,H
  LD H,A
; Operand = step of the row between cells of a line (setup byte 5).
SmcSweepInnerRow:
  LD A,$00
  ADD A,L
  LD L,A
  DJNZ RedrawRoom_Cell
  POP HL
  POP BC
; Operand = step of the column from line to line (setup byte 6).
SmcSweepOuterCol:
  LD A,$00
  ADD A,H
  LD H,A
; Operand = step of the row from line to line (setup byte 7).
SmcSweepOuterRow:
  LD A,$00
  ADD A,L
  LD L,A
  DJNZ RedrawRoom_Line
  RET

; Redraw one cell from the tile map if its redraw flag is set
;
; Looks up the cell's tile in the tile map ($5B00, one byte per cell, 32 per
; row) and its flag in the flag map 3 pages above ($5E00). It always clears bit
; 7 (redraw) of the flag; if the bit was clear nothing else happens. Otherwise
; it copies the tile's attribute (TileAttrs, indexed by the tile) to the
; attribute file and the tile's 8 bitmap bytes (TileGfx, 8 per tile) to the
; cell's pixel rows on the screen.
;
; Hardware: writes one byte of the attribute file ($5800) and 8 bytes of the
; screen bitmap ($4000, a cell's pixel rows are 256 bytes apart).
;
;   H Column of the cell (0-31)
;   L Row of the cell (0-21)
; O:HL Unchanged when the cell was not flagged, otherwise changed (the caller
;      keeps HL and BC itself)
RedrawCell:
  PUSH HL
  CALL TileMapAddress     ; HL = tile map address of the cell
  LD E,(HL)               ; E = tile number
  LD D,TileAttrs>>8       ; D = high byte of the attribute table
; The flag map is 3 pages above the tile map.
  LD A,FLAGS_PAGE_OFFSET
  ADD A,H
  LD H,A
; A = the cell's flag; bit 7 is cleared in the map whatever it was.
  LD A,(HL)
  RES 7,(HL)              ; clear the redraw flag
  POP HL
; Carry = the old bit 7: return when the cell is not flagged.
  RLA
  RET NC
; HL = attribute file address; set the attribute of the tile.
  CALL AttrAddress
  LD A,(DE)
  LD (HL),A
; HL = screen address of the cell's first pixel row (D, E = tile number,
; swapped below).
  CALL AttrToBitmap
; HL = tile number x 8 + $CF00: the tile's bitmap.
  EX DE,HL
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD A,H
  ADD A,TileGfx>>8
  LD H,A

; Copy a tile bitmap to a screen cell
;
; Copy 8 bytes from HL to the screen cell at DE, one byte per pixel row: DE
; moves down a row with INC D. RedrawCell falls into it; DrawTileCells and
; DrawFrameCell (the status bar and the parchment frame) call it. B ends 0, HL
; and D are moved on by 8; no caller uses them.
;
; HL The 8 bytes of the bitmap
; DE Screen address of the cell
CopyTileBitmap:
  LD B,CELL_SIZE
CopyTileBitmap_Row:
  LD A,(HL)
  LD (DE),A
  INC HL
  INC D
  DJNZ CopyTileBitmap_Row
  RET

; Sweep setups for the room redraw, 4 x 8 bytes
;
; Indexed by the exit direction in $850B (0 = right, 1 = left, 2 = down, 3 =
; up; set by CheckRoomExit). RedrawRoom copies the four step bytes into the
; operands of its loop and walks the cells line by line. Fields:
;
; +0 byte: number of lines (outer loop count) +1 byte: cells per line (inner
; loop count) +2 byte: row of the first cell +3 byte: column of the first cell
; +4 byte: column step between the cells of a line +5 byte: row step between
; the cells of a line +6 byte: column step from one line to the next +7 byte:
; row step from one line to the next
;
; Setup 0: 32 columns of 22 cells, left to right; 1: the same, right to left
; (starts at column 31); 2: 22 rows of 32 cells, top to bottom; 3: the same,
; bottom to top (starts at row 21). Steps $FF are -1.
SweepSetups:
  DEFB $20,$16,$00,$00,$00,$01,$01,$00 ; 0: columns, left to right
  DEFB $20,$16,$00,$1F,$00,$01,$FF,$00 ; 1: columns, right to left
  DEFB $16,$20,$00,$00,$01,$00,$00,$01 ; 2: rows, top to bottom
  DEFB $16,$20,$15,$00,$01,$00,$00,$FF ; 3: rows, bottom to top

; Draw the lives bar (hearts) of the status line, when asked to
;
; Row 22 of the screen holds the lives bar, row 23 the crosses
; (DrawCrossesHud). The main loop calls this every frame, but the routine works
; only when its first byte is NOP: it then overwrites that byte with RET and so
; does nothing on the later calls. Writing 0 to $9BF3 asks for a redraw: done
; at the start of a game (StartGame), after a heart is picked up (ActionHeart),
; at the end of the dying animation (UpdateDying_End) and after ShowTextWindow
; has printed text over the screen. It draws 9 heart tiles (tile $7B, MAX_LIVES
; of them) and 3 blank cells in row 22, columns 0-11, and then sets the
; attributes: as many cells as the player has lives ($854C) are bright red, the
; rest (lost hearts and the blank cells) blue. Observed with $854C = 5: five
; red hearts, then four blue ones.
;
; Hardware: writes bitmap bytes of screen row 22 ($50C0...) and its attributes
; ($5AC0...).
;
; All registers are changed.
DrawLivesBar:
  NOP                     ; NOP: draw the bar; RET: already drawn. Callers
                          ; write 0 here to ask for a redraw
  LD HL,DrawLivesBar
  LD (HL),OP_RET          ; switch off until the next request
  LD DE,LIVES_BAR_SCREEN
; The heart tile bitmap.
  LD HL,TileGfx+TILE_HEART*CELL_SIZE
  LD C,MAX_LIVES
  CALL DrawTileCells
; Blank cells for the rest of the 12.
  LD C,STATUS_CELLS-MAX_LIVES
  LD HL,TileGfx
  CALL DrawTileCells
; Attributes: the first `lives` cells (A = lives + 1 as the DJNZ count of
; FillHudAttrs) get ink red, bright; the rest ink blue.
  LD HL,LIVES_BAR_ATTRS
  LD A,(Lives)
  INC A
  LD C,STATUS_CELLS
  LD B,A
  LD A,BRIGHT+RED
  JP FillHudAttrs
