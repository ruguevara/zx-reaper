; Copy the redraw list to the screen: attributes and eight pixel rows of every
; run of cells
;
; The last step of the drawing of a frame (main loop StartGame, title RunIntro
; and cutscenes RunCutscene call it after BuildRedrawList). It walks the redraw
; run list at RedrawRuns and copies each run of cells from the redraw cell
; buffers to the screen. The list holds one record per character row that has
; cells to draw: the row number, the number of runs and for each run the first
; column and the index of its first cell in the buffers; $FF ends the list
; (RedrawListPtr, BuildRedrawList and CollectRedrawRun build it). For a run of
; n cells (n = 1-32, from RedrawLengths + index) it copies the n attribute
; bytes from RedrawAttrs + index to the attribute file, then the 8 pixel rows
; from the pages RedrawPixels to CC00 (page + pixel row) to the bitmap of the
; cells.
;
; The copy is done with unrolled chains of LDI (and LDD) instructions that are
; entered at the right place by a JR whose offset byte is patched for every run
; to 2 x (32 - n): SmcAttrJump (attributes, chain from CopyAttrChain),
; SmcBitmapBackJump (bitmap going back, chain from CopyBitmapBack) and
; SmcBitmapForwardJump (bitmap going forward, chain from CopyBitmapForward).
; Each chain has 31 two-byte LDIs; the last byte of a run is copied by a plain
; LD A,(HL) / LD (DE),A after the chain. To save a seek at the end of every
; pixel row, the rows alternate in direction: row 0 is copied from the last
; cell of the run back to the first (LDD), row 1 from the first to the last
; (LDI), and so on for four pairs of rows (B).
;
; Hardware: writes the attribute file (5800) and the screen bitmap (4000, the 8
; pixel rows of a cell are 256 bytes apart) directly; no port is used. SP is
; not touched.
;
; All registers are changed.
DrawRedrawList:
  LD HL,RedrawRuns
; Next row record of the redraw list Reads the row number ($FF ends the list:
; the routine returns), looks up the attribute file address of the row's first
; cell in AttrRowAddrs and goes through the runs of the row. Also entered from
; CopyBitmapForward_Tail, with HL at the next row record (row number, run
; count, runs...), after the last run of a row.
DrawRedrawList_Row:
  LD A,(HL)               ; row number, $FF = end of the list
  INC A
  RET Z
  DEC A
  ADD A,A                 ; x2: index into the row address table
  EXX
  LD L,A
  LD H,$00
  LD DE,AttrRowAddrs
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)               ; DE' = attribute file address of column 0 of the row
  EXX
  INC L
  LD B,(HL)               ; B = number of runs of the row
; One run of cells Entered for each run of the row (the loop is closed by
; CopyBitmapForward_Tail) with HL at the run entry in the list (first column,
; then the index of the first cell in the buffers, which also gives the address
; of the run's length cell in RedrawLengths) and B the runs left in the row.
DrawRedrawList_Run:
  PUSH BC                 ; save the runs left and the loop counter
  INC L
  LD A,(HL)               ; A = first column of the run
  INC L
  PUSH HL                 ; save the list pointer
  LD L,(HL)               ; L = index of the first cell in the buffers
  LD H,PAGE_REDRAW_LENGTHS ; HL = length cell of the run
  EXX
  LD L,A
  LD H,$00
  ADD HL,DE               ; + column: attribute file address of the first cell
  PUSH HL
  EXX
  POP DE                  ; DE = attribute file address
  LD A,SCREEN_COLS        ; offset of the three chain entry jumps = 2 x (32 -
                          ; length)
  SUB (HL)
  ADD A,A
  LD (SmcBitmapForwardJump+$0001),A
  LD (SmcBitmapBackJump+$0001),A
  LD (SmcAttrJump+$0001),A
  LD H,PAGE_REDRAW_ATTRS  ; HL = attribute of the first cell, in the buffer
; Self-modified: the offset of this JR is written above (9629 and the two
; stores after it) as 2 x (32 - run length), so that it jumps into the chain of
; LDI instructions that follows at the place where as many LDIs remain as the
; run has cells but one.
SmcAttrJump:
  JR SmcAttrJump          ; enter the LDI chain; the offset byte (+1) is
                          ; patched

; Attribute copy chain (first 21 of 31 LDI)
;
; Part of DrawRedrawList: the unrolled copy of the attribute bytes of a run of
; cells, entered in the middle by the JR at SmcAttrJump whose offset is 2 x (32
; - run length). Every LDI copies one attribute from the redraw attribute
; buffer (RedrawAttrs + index) to the attribute file. The chain goes on at
; CopyAttrChain_Tail, whose last instructions finish the run.
;
; Hardware: writes the attribute file.
;
;   HL Redraw attribute buffer address of the cell
;   DE Attribute file address of the cell
;   BC Decremented by every LDI (the value is not used)
; O:HL Advanced by the number of LDIs executed
; O:DE Advanced by the number of LDIs executed
CopyAttrChain:
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
  LDI
  LDI
  LDI
  LDI
  LDI

; Attribute copy chain (last 10 LDI), then the bitmap copy of the run begins
;
; The end of the chain of CopyAttrChain, then the plain copy of the last
; attribute byte, then the set-up of the bitmap copy: the high byte of the
; attribute address is turned into the high byte of the screen address of the
; same cell row (the three thirds of the screen are $0800 apart), DE now
; addresses pixel row 0 of the last cell of the run, and HL the matching byte
; of the first pixel-row page of the redraw buffers (RedrawPixels + index of
; the last cell). B = 4 pairs of pixel rows. C = $FF only keeps the LDD and LDI
; counting in BC from borrowing into B. It then falls into the JR at
; SmcBitmapBackJump, which enters the LDD chain of CopyBitmapBack; the loop of
; CopyBitmapForward_Tail comes back to the same JR for the next pair of pixel
; rows.
;
; Hardware: writes the last attribute byte of the run and prepares screen
; addresses; the bitmap is written by the chains that follow.
;
;   HL Redraw attribute buffer address of the last cell
;   DE Attribute file address of the last cell
; O:HL Page $C5 address of the last cell
; O:DE Screen bitmap address of pixel row 0 of the last cell
; O:BC $04FF
CopyAttrChain_Tail:
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
  LD A,(HL)               ; the last cell has no LDI
  LD (DE),A
  LD A,D
  ADD A,A
  ADD A,A
  ADD A,A
  AND THIRD_MASK
  ADD A,SCREEN_HIGH
  LD D,A                  ; D = high byte of the screen address
  INC H                   ; next page of the redraw buffer: pixel row 0
  LD BC,PIXEL_ROW_PAIRS*$0100+$FF ; B = pairs of pixel rows, C = $FF so that
                                  ; LDD/LDI never borrow from B
; Self-modified: the offset byte of this JR is written by DrawRedrawList_Run (2
; x (32 - run length)). It enters the chain of LDD instructions at
; CopyBitmapBack to copy one pixel row of the run from its last cell to its
; first; CopyBitmapForward_Tail jumps back here to do the next pair of pixel
; rows.
SmcBitmapBackJump:
  JR SmcBitmapBackJump    ; enter the LDD chain; the offset byte (+1) is
                          ; patched

; Bitmap copy chain going back (first 21 of 31 LDD)
;
; Part of DrawRedrawList: copies one pixel row of a run of cells from the
; redraw buffers to the screen, from the last cell down to the first, entered
; by the JR at SmcBitmapBackJump. The chain goes on at CopyBitmapBack_Tail.
;
; Hardware: writes the screen bitmap (one byte of the pixel row for each cell).
;
;   HL Address of the cell's byte in the pixel-row page of the redraw buffers
;   DE Screen bitmap address of the cell's byte
;   BC Decremented by every LDD (the value is not used)
; O:HL Decreased by the number of LDDs executed
; O:DE Decreased by the number of LDDs executed
CopyBitmapBack:
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD

; Bitmap copy chain going back (last 10 LDD), then the next pixel row
;
; The end of the chain of CopyBitmapBack, the plain copy of the first cell's
; byte, then HL and DE go to the next pixel row (the next page of the redraw
; buffers, 256 bytes further in the screen). It falls into the JR at
; SmcBitmapForwardJump, which enters the chain of LDI instructions at
; CopyBitmapForward to copy the next pixel row from the first cell to the last.
;
; Hardware: writes the screen bitmap.
;
;   HL Redraw buffer address of the first cell
;   DE Screen bitmap address of the first cell
; O:HL Page + 1 of the first cell
; O:DE Screen address + $0100: pixel row + 1 of the first cell
CopyBitmapBack_Tail:
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LD A,(HL)
  LD (DE),A
  INC H
  INC D
; Self-modified: the offset byte of this JR is written by DrawRedrawList_Run (2
; x (32 - run length)). It enters the chain of LDI instructions at
; CopyBitmapForward to copy one pixel row of the run from its first cell to its
; last.
SmcBitmapForwardJump:
  JR SmcBitmapForwardJump ; enter the LDI chain; the offset byte (+1) is
                          ; patched

; Bitmap copy chain going forward (first 21 of 31 LDI)
;
; Part of DrawRedrawList: copies one pixel row of a run of cells from the
; redraw buffers to the screen, from the first cell up to the last, entered by
; the JR at SmcBitmapForwardJump. The chain goes on at CopyBitmapForward_Tail.
;
; Hardware: writes the screen bitmap (one byte of the pixel row for each cell).
;
;   HL Address of the cell's byte in the pixel-row page of the redraw buffers
;   DE Screen bitmap address of the cell's byte
;   BC Decremented by every LDI (the value is not used)
; O:HL Advanced by the number of LDIs executed
; O:DE Advanced by the number of LDIs executed
CopyBitmapForward:
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
  LDI
  LDI
  LDI
  LDI
  LDI

; Bitmap copy chain going forward (last 10 LDI), then the loops over pixel
; rows, runs and rows
;
; The end of the chain of CopyBitmapForward and the plain copy of the last
; cell's byte, then the loop control of DrawRedrawList: after each pair of
; pixel rows (one backward, one forward copy) B counts down and the code
; returns to the LDD entry at SmcBitmapBackJump until the 8 pixel rows are
; done; then the saved list pointer and run counter are restored and the next
; run of the row is started at DrawRedrawList_Run; after the last run it goes
; on at DrawRedrawList_Row with the next row record of the list.
;
; Hardware: writes the screen bitmap.
;
; HL Redraw buffer address of the last cell
; DE Screen bitmap address of the last cell
; B Pairs of pixel rows left (the run counter is in the stack)
CopyBitmapForward_Tail:
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
  LD A,(HL)
  LD (DE),A
  INC H
  INC D
  DEC B                   ; one more pair of pixel rows done
  JP NZ,SmcBitmapBackJump ; next pair: back to the LDD chain
  POP HL                  ; list pointer saved at 9619: the index byte of the
                          ; run just drawn
  POP BC                  ; runs left, saved at DrawRedrawList_Run
  DEC B
  JP NZ,DrawRedrawList_Run ; next run of the row
  INC L                   ; HL = the row number byte of the next row record
  JP DrawRedrawList_Row

; Take a run of flagged cells of a row into the redraw list and the cell
; buffers
;
; Called by BuildRedrawList when its scan of the tile flag map (5E00) meets a
; cell with bit 7 (redraw) or bit 6 (a sprite covers the cell) set. It walks
; along the row for as long as the cells are flagged and counts them (D): a
; cell with bit 7 loses it, a cell with only bit 6 has bit 6 cleared and bit 7
; set, so that the cell is drawn once more in the next frame from the tile map
; and the sprite is erased from where it was (QueueSprite sets bit 6 and clears
; bit 7). The run is then added to the redraw run list at (RedrawListPtr): if
; this is the first run of the row a row record (row number, 0 runs) is
; started; the run count is incremented and the run entry (first column, index
; of its first cell in the cell buffers) is stored. CopyRunCells fills the
; buffers (run length RedrawLengths, attributes RedrawAttrs, bitmaps
; RedrawPixels and up) with the tile data of the cells. The index of the next
; free buffer cell then moves on by the run length. Neither the number of cells
; nor the size of the list is checked: the index is one byte.
;
; The routine runs with the alternate register set that BuildRedrawList selects
; (HL, B and C below are the alternate ones). It returns with HL at the last
; cell of the run and B one higher, so that the INC L / DJNZ of the caller's
; loop go on with the first unflagged cell.
;
; Hardware: none.
;
;   HL Address in the tile flag map of the first flagged cell of the run
;   B Cells left in the row, including this one
;   C Rows left, including this one (22 - row number)
; O:HL Address in the flag map of the last cell of the run
; O:B Cells left in the row after the run, plus one
CollectRedrawRun:
  PUSH HL
  LD D,$00
CollectRedrawRun_0:
  LD A,(HL)
  AND FLAG_REDRAW+FLAG_SPRITE ; bit 7 redraw, bit 6 sprite
  JR Z,CollectRedrawRun_3 ; unflagged: the run ends
  JP P,CollectRedrawRun_1 ; bit 7 clear: only bit 6
  RES 7,(HL)              ; bit 7 set: drawn now, nothing left
  JR CollectRedrawRun_2
CollectRedrawRun_1:
  RES 6,(HL)              ; bit 6 only: erase the sprite from the tile map next
                          ; frame
  SET 7,(HL)
CollectRedrawRun_2:
  INC D                   ; D = cells in the run
  INC L
  DJNZ CollectRedrawRun_0
CollectRedrawRun_3:
  EX (SP),HL              ; HL = start of the run, the end address is saved
  PUSH BC
  PUSH HL
  LD HL,(RedrawListPtr)   ; the end of the redraw list
  INC (HL)                ; the slot holds $FF at the start of a row: INC makes
                          ; it 0 (a new row)
  JR NZ,CollectRedrawRun_4
  LD A,MAP_ROWS           ; a new row record: row number = 22 - rows left
  SUB C
  LD (HL),A
  INC L
  LD (HL),$00             ; 0 runs so far
  LD (SmcRunCount+$0001),HL ; the address of the run count: operand of the LD
                            ; HL at SmcRunCount
  INC L
  LD (RedrawListPtr),HL   ; the list pointer is at the first run entry
CollectRedrawRun_4:
  POP HL
  CALL CopyRunCells       ; fill the cell buffers with the tile data of the run
SmcRedrawIndex:
  LD A,$00                ; operand = index of the next free cell of the
                          ; buffers: 0 from BuildRedrawList, advanced below
  LD C,A                  ; C = index of the first cell of the run
  ADD A,D                 ; + cells of the run: the next free index
  LD (SmcRedrawIndex+$0001),A
  LD B,D                  ; (B is not used again)
  EX DE,HL                ; DE = flag map address of the run (HL is replaced
                          ; next)
  LD HL,(RedrawListPtr)   ; the list pointer
  LD A,E
  AND SCREEN_COLS-$01     ; column of the run
  LD (HL),A               ; run entry: first column
  INC L
  LD (HL),C               ; run entry: index of the first cell
  INC L
  LD (HL),H               ; filler (not $FF) in the next slot: the INC at 9736
                          ; then starts no new row
  LD (RedrawListPtr),HL
SmcRunCount:
  LD HL,SmcRunCount       ; operand = address of the run count byte of the row
                          ; (set at 9740)
  INC (HL)                ; one more run in the row
  POP BC                  ; B and C as on entry
  POP HL                  ; HL = first cell after the run
  INC B                   ; the caller's DJNZ comes after its INC L
  DEC L                   ; so that INC L finds the first cell after the run
  RET

; Copy the tile data of a run of cells into the redraw cell buffers
;
; Called by CollectRedrawRun for each run of flagged cells. For each of the D
; cells starting at flag map address HL it looks up the cell's tile number in
; the tile map (3 pages below the flag map), then stores the tile's attribute
; (TileAttrs + tile) at RedrawAttrs + index and the tile's 8 bitmap bytes
; (TileGfx + 8 x tile) at RedrawPixels + index, C600 + index ... CC00 + index
; (one page for each pixel row). The first cell of the run also gets the run
; length D at RedrawLengths + index. The index starts at the value of
; SmcRedrawIndex (the operand of the LD A,0 there) and goes up by one for each
; cell. Together this is the picture of the cells without sprites;
; DrawSpriteJob and DrawBlockJob then draw the queued sprites over it and
; DrawRedrawList copies the result to the screen.
;
; The 8 bitmap bytes are fetched with POP: SP is pointed at byte 2 of the tile
; bitmap and saved in the operand of the LD SP at SmcRestoreSP (SmcRestoreSP),
; which puts it back. For about 130 T-states per cell SP is inside the tile
; bitmaps; an interrupt that comes then has its return address written over
; the two bitmap bytes below SP, which are the pair just loaded into BC, and
; the PUSH BC at the start of InterruptHandler writes them back. This happens:
; 32 times over the 3000 frames of tests/inputs/play.txt, every time repaired
; (F139).
;
; Hardware: none.
;
;   HL Address in the tile flag map of the first cell of the run
;   D Number of cells of the run (1-32)
; O:HL Unchanged
; O:DE Unchanged
;   BC is changed
CopyRunCells:
  PUSH HL
  PUSH DE
  LD BC,-FLAGS_PAGE_OFFSET*$0100 ; HL - $0300: the tile map address of the
                                 ; first cell
  ADD HL,BC
  LD B,D                  ; B = number of cells
  LD DE,(SmcRedrawIndex+$0001) ; E = index of the first cell (the operand of
                               ; SmcRedrawIndex)
  LD D,PAGE_REDRAW_LENGTHS
  LD A,B
  LD (DE),A               ; the run length at the first cell's index
CopyRunCells_Cell:
  PUSH HL
  PUSH BC
  LD L,(HL)               ; L = tile number
  LD D,PAGE_REDRAW_ATTRS
  LD H,TileAttrs>>8
  LD A,(HL)               ; the tile's attribute...
  LD (DE),A               ; ... into the attribute buffer
  LD D,PAGE_REDRAW_PIXELS
  LD H,$00                ; HL = tile x 8 ...
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD A,TileGfx>>8         ; ... + $CF00: the tile's bitmap
  ADD A,H
  LD H,A
  LD C,(HL)               ; bitmap rows 0 and 1
  INC HL
  LD B,(HL)
  INC HL
  LD (SmcRestoreSP+$0001),SP ; save SP; it points into the tile bitmap for the
                             ; next 6 POPs
  LD SP,HL                ; SP = bitmap row 2
  EX DE,HL                ; HL = the cell's byte in the page of pixel row 0
  LD (HL),C               ; pixel rows 0 to 7, one page each (INC H)
  INC H
  LD (HL),B
  INC H
  POP BC                  ; rows 2 and 3
  LD (HL),C
  INC H
  LD (HL),B
  INC H
  POP BC                  ; rows 4 and 5
  LD (HL),C
  INC H
  LD (HL),B
  INC H
  POP BC                  ; rows 6 and 7
  LD (HL),C
  INC H
  LD (HL),B
SmcRestoreSP:
  LD SP,SmcRestoreSP      ; operand = SP saved at 9792
  LD E,L                  ; E = index of this cell (L has not changed)
  POP BC                  ; loop counter
  POP HL                  ; tile map pointer
  INC L                   ; next cell of the tile map
  INC E                   ; next index in the buffers
  DJNZ CopyRunCells_Cell
  POP DE
  POP HL
  RET

; Build the redraw list of the frame, then run the draw queue
;
; The first of the two drawing steps of a frame (the main loop StartGame, the
; title RunIntro and the cutscene loop RunCutscene call it after the frame call
; list has queued the sprites, and DrawRedrawList after it). Two parts:
;
; 1. The redraw list. It scans the tile flag map (5E00, 22 rows of 32 cells)
; and takes every row's runs of cells that have bit 7 (redraw) or bit 6 (a
; sprite is on the cell) set to CollectRedrawRun. That routine clears the
; flags, appends the run to the redraw run list at RedrawRuns (RedrawListPtr is
; the write pointer) and has CopyRunCells copy the tile attributes and bitmaps
; of the cells into the redraw cell buffers (RedrawLengths-CCFF). The end mark
; $FF follows the list after every row. The index of the next free buffer cell
; (the operand of the LD A,0 at SmcRedrawIndex) is reset to 0 first.
;
; 2. The draw queue (from RunDrawQueue, DrawQueue holds 16 jobs of 16 bytes):
; for each job whose first word is not 0 that word is cleared and the routine
; it names is called with DE = job address + 1 (the parameters follow in the
; job). The handlers are DrawSpriteJob (masked sprites, queued by QueueSprite)
; and DrawBlockJob (16-pixel blocks, queued by QueueBlockSprite); they draw
; into the redraw cell buffers on top of the tiles. The tail of the queue (the
; operand of the first instruction of AddQueueJob) is set back to the start of
; the queue.
;
; The scan uses the alternate register set (one EXX that is not undone here).
; DrawRedrawList later puts the cells on the screen.
;
; Hardware: none.
;
; O:All All registers are changed
BuildRedrawList:
  LD HL,RedrawRuns        ; the redraw run list starts here...
  LD (RedrawListPtr),HL   ; ... and RedrawListPtr is its write pointer
  LD (HL),$FF             ; end mark
  XOR A                   ; index of the next free redraw cell: 0
  LD (SmcRedrawIndex+$0001),A
  EXX                     ; alternate set: HL = flag map pointer, C = rows
                          ; left, B = cells left
  LD HL,FLAG_MAP
  LD C,MAP_ROWS
BuildRedrawList_Row:
  LD B,SCREEN_COLS
BuildRedrawList_Cell:
  LD A,(HL)
  AND FLAG_REDRAW+FLAG_SPRITE ; bit 7 or bit 6 set?
  CALL NZ,CollectRedrawRun ; a run of flagged cells starts here
  INC L
  DJNZ BuildRedrawList_Cell
  JR NZ,BuildRedrawList_0 ; Z only when L wrapped at the end of a page: then
                          ; carry into H
  INC H
BuildRedrawList_0:
  EX DE,HL
  LD HL,(RedrawListPtr)   ; $FF after the last run of the row: the end of the
                          ; list so far
  LD (HL),$FF
  EX DE,HL
  DEC C
  JR NZ,BuildRedrawList_Row
; The draw queue runner. The queue tail is set back to the start of the queue
; (the operand of the LD DE at AddQueueJob), then the 16 jobs of 16 bytes at
; DrawQueue are visited.
RunDrawQueue:
  LD HL,DrawQueue
  LD (AddQueueJob+$0001),HL ; queue tail = start of the queue (the operand of
                            ; the LD DE at AddQueueJob)
RunDrawQueue_Job:
  PUSH HL
  LD E,(HL)               ; DE = the job's handler address...
  LD (HL),$00             ; ... which is cleared: the job is done
  INC L
  LD D,(HL)
  LD (HL),$00
  EX DE,HL                ; HL = handler, DE = job address + 1
  LD A,H
  OR L                    ; 0 = a free job
  CALL NZ,JumpToHL        ; call the handler through JP (HL) at JumpToHL
  POP HL
  LD A,L
  ADD A,JOB_SIZE          ; next job; L wraps to 0 after the 16th
  LD L,A
  JR NZ,RunDrawQueue_Job
  RET

; Queue a 16-pixel-wide object sprite: flag its cells and add a job to the draw
; queue
;
; A routine of the frame call list (RunFrameList), like QueueSprite: the call
; list holds the address of the routine and 8 bytes of parameters, which it
; POPs, and it ends with a RET into the next entry. The room items use it (the
; sprite command at ItemCmd, made by AnimateItem): a sprite 2 bytes wide,
; without mask, placed on the character grid. It stores the parameters in the
; job template BlockJob (the height in 2-pixel units divided by 4 gives the
; character rows), marks the 2 cells of each row as for QueueSprite (bit 6 set
; and bit 7 clear in the tile flag map, so that the cells are redrawn now and
; once more in the next frame to erase the sprite) and adds the template to the
; draw queue with AddQueueJob, which is a job for DrawBlockJob. No clipping is
; done: the sprite must be wholly inside the room.
;
; Hardware: none; it only changes the tile flag map in RAM.
;
; HL Popped from the call list: L = character row (0-21), H = column (0-30) of
;    the top-left cell
; DE Popped: address of the 16-pixel-wide graphics (16 bytes for each character
;    row)
; BC Popped: B = height in 2-pixel units (a multiple of 4: 8 for the items, 12
;    for the arch), C = width (not used: it
; is always 2)
; AF Popped: A = attribute of the sprite's cells (F unused)
QueueBlockSprite:
  POP HL
  POP DE
  POP BC
  POP AF
  LD (BlockJobAttr),A     ; job +7: attribute
  LD (BlockJobGfx),DE     ; job +2: graphics address
  SRL B                   ; height / 4 = character rows
  SRL B
  LD A,B
  LD (BlockJobRows),A     ; job +4: character rows
  LD (BlockJobCell),HL    ; job +5: row (L), +6: column (H)
  CALL FlagMapAddress     ; HL = flag map address of the top-left cell
  LD A,L                  ; A = low byte of the address of the first cell of
                          ; the row (+32 for each row)
QueueBlockSprite_Row:
  SET 6,(HL)              ; two cells of a row: a sprite is on the cell, not
                          ; yet redrawn
  RES 7,(HL)
  INC L
  SET 6,(HL)
  RES 7,(HL)
  ADD A,SCREEN_COLS       ; next character row
  LD L,A
  JR NC,QueueBlockSprite_0
  INC H
QueueBlockSprite_0:
  DJNZ QueueBlockSprite_Row
  LD HL,BlockJob          ; job template
  JP AddQueueJob          ; append it to the draw queue (the RET there enters
                          ; the next call list entry)

; Draw queue job template of the 16-pixel-wide object sprites (filled in by
; QueueBlockSprite)
;
; QueueBlockSprite stores its parameters here and AddQueueJob copies 16 bytes
; from here to the draw queue (DrawQueue); the template is only 8 bytes long,
; so the next 8 bytes (the first code bytes of QueueSprite) are copied along
; and not used. The job is run by BuildRedrawList: the handler DrawBlockJob
; draws the sprite into the redraw cell buffers. Fields:
;
; +0 word: handler, DrawBlockJob
;
; +2 word: address of the graphics (16 bytes for each character row)
;
; +4 byte: character rows covered
;
; +5 byte: row of the top-left cell (0-21)
;
; +6 byte: column of the top-left cell
;
; +7 byte: attribute of the cells
BlockJob:
  DEFW DrawBlockJob       ; +0: handler
BlockJobGfx:
  DEFW $0000              ; +2: graphics address
BlockJobRows:
  DEFB $00                ; +4: character rows
BlockJobCell:
  DEFW $0000              ; +5: row (low byte), +6: column (high byte)
BlockJobAttr:
  DEFB $00                ; +7: attribute
