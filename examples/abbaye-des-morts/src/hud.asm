; Redraw the crosses counter in the status bar
;
; One-shot redraw gate: the first byte is NOP while a redraw is wanted and RET
; otherwise. The main loop (StartGame) calls this address on every pass; the
; routine puts RET over its own first byte at once, so it draws only once per
; request. A request is a NOP written at the start of a game (StartGame), when
; a cross is picked up (TakeCross, from both cross actions
; ActionCrossWheelTurned and ActionCrossWheelRest) and when a parchment or text
; window is closed (ShowTextWindow).
;
; Draws twelve cross icons (tile $7C) in the last cell row of the screen (cells
; 0-11 of row 23), then colours them: as many as crosses collected ($854D)
; bright white, the rest blue.
;
; Hardware: writes the bitmap of cell row 23 (cells 0-11) and its attribute
; cells.
DrawCrossesHud:
  NOP
  LD HL,DrawCrossesHud    ; disarm: the next call returns at once
  LD (HL),OP_RET
  LD DE,HUD_CROSSES_SCREEN
  LD HL,TileGfx+TILE_CROSS*CELL_SIZE ; bitmap of the cross tile
  LD C,STATUS_CELLS
  CALL DrawTileCells      ; bitmaps of the 12 empty cross slots
  LD HL,HUD_CROSSES_ATTR
  LD A,(Crosses)          ; crosses collected
  INC A
  LD C,STATUS_CELLS
  LD B,A                  ; B-1 cells get the collected colour
  LD A,BRIGHT+WHITE
  JP FillHudAttrs

; Draw one 8x8 tile bitmap into C consecutive screen cells
;
; Copies the same 8 bytes to the C cells that follow DE on one screen row (INC
; E per cell; the cells must not cross a 32-cell boundary). Used for the status
; bar (DrawLivesBar, DrawCrossesHud).
;
; Hardware: writes the screen bitmap.
;
;   C Number of cells
;   DE Screen address of pixel row 0 of the first cell
;   HL Address of the 8 bitmap bytes (not advanced)
; O:C 0
DrawTileCells:
  PUSH HL
  PUSH DE
  CALL CopyTileBitmap     ; copy 8 bytes HL -> DE, DE steps down the 8 pixel
                          ; rows
  POP DE
  POP HL
  INC E                   ; next cell on the row
  DEC C
  JR NZ,DrawTileCells
  RET

; Colour a status bar row: A for the first B-1 cells, blue for the rest
;
; Stores C attribute bytes along one attribute row. The first B-1 cells get A
; (hearts or crosses owned), every following cell gets blue ink on black paper
; (the empty slots). Used by DrawLivesBar and DrawCrossesHud.
;
; Hardware: writes the attribute file.
;
; A Attribute of the first B-1 cells
; B Number of cells to colour with A, plus one
; C Number of cells in the row
; HL Attribute address of the first cell
FillHudAttrs:
  DJNZ FillHudAttrs_0     ; DJNZ falls through when B reaches 0: switch colour
  LD A,BLUE
FillHudAttrs_0:
  LD (HL),A               ; B wraps to $FF afterwards: DJNZ never falls through
                          ; again
  INC L
  DEC C
  JR NZ,FillHudAttrs
  RET

; Parchment gate: RET until a parchment is picked up, then falls into
; ShowParchment
;
; Single byte that is RET normally. Touching a parchment (ActionParchment)
; stores its two message numbers in $850E/$850F and writes NOP here; the main
; loop (StartGame) calls this address on every pass, so the call then falls
; through into ShowParchment, which shows the parchment and writes RET back.
; EnterRoom also writes RET here when a room is entered.
ParchmentGate:
  RET

; Show a parchment: clear the screen, print its two lines, frame, wait for a
; key
;
; Runs the parchment text script ScriptParchment, which blacks out the whole
; screen and prints the two messages (string numbers in $850E and $850F)
; centred at pixel rows 65 and 85. Then it draws the parchment frame in black
; on yellow (DrawParchmentFrame), waits for a key (release, press, release),
; redraws the room and the status bar and returns to the game. Entered through
; ParchmentGate.
;
; Hardware: clears and draws the screen, reads the keyboard through
; WaitKeyRelease and WaitKeyPress (HALT until the interrupt).
ShowParchment:
  LD HL,ScriptParchment
  LD BC,(YELLOW*PAPER+BLACK)*$0100+YELLOW ; B: frame interior black on yellow,
                                          ; C: frame tiles yellow on black

; Show a full-screen text window
;
; Entry point of the full-screen text window, also used by the ending
; (RunEnding). Afterwards the screen shows the room again.
;
; HL Script that draws the text (it also clears the screen)
; B Attribute of the blank (interior) cells
; C Attribute of the frame tiles
ShowTextWindow:
  LD A,(RoomState)        ; save the room state; it is restored at the end
  PUSH AF
  PUSH BC
  PUSH HL
  XOR A                   ; room state 0 while the window is up
  LD (RoomState),A
  LD HL,ParchmentGate     ; disarm the parchment gate (ParchmentGate)
  LD (HL),OP_RET
  POP HL
  CALL RunScript          ; print the window text; the script clobbers BC
  POP BC
  EXX                     ; BC -> BC': DrawFrameCell reads the frame attributes
                          ; there
  CALL DrawParchmentFrame ; draw the frame
  CALL WaitKeyRelease     ; wait until no key is pressed
  CALL WaitKeyPress       ; wait for a key
  CALL WaitKeyRelease     ; wait for the release
  XOR A                   ; arm the status bar redraws (hearts DrawLivesBar,
                          ; crosses DrawCrossesHud)
  LD (DrawLivesBar),A
  LD (DrawCrossesHud),A
  LD (ExitDirection),A    ; scroll setup 0
  CALL RedrawRoom         ; redraw the room from the tile map
  LD HL,$0C16             ; row 22, column 12: the 20x2 message area
  LD BC,$0214             ; 20 cells wide, 2 rows
  LD A,WHITE              ; attribute: white ink on black
  CALL FillAttrRect       ; fill the message area attributes (the room name is
                          ; drawn again by the room)
  POP AF
  LD (RoomState),A
  RET

; Draw the parchment frame from the layout at $71DF
;
; Draws the 24x11 cell frame of the parchment window. The layout
; (ParchmentLayout) starts with a word, row then column of the top-left cell,
; followed by 11 rows of 24 cells, one code per cell or per run; a 0 code ends
; it. Code 1 is followed by a count n: n blank cells (attribute B'); code k >=
; 2 is one frame tile, the 8x8 bitmap number k-2 of the 12 at
; ParchmentFrameTiles (attribute C'). Rows are drawn by DrawFrameRow, cells by
; DrawFrameCell.
;
; The caller does EXX so that B' and C' hold the attributes (ShowParchment sets
; them from its BC).
;
; Hardware: writes the screen bitmap and the attribute file.
;
; B' Attribute of the blank (interior) cells
; C' Attribute of the frame tile cells
DrawParchmentFrame:
  LD HL,ParchmentLayout   ; layout address
  LD E,(HL)               ; DE = position: E row, D column
  INC HL
  LD D,(HL)
  INC HL
DrawParchmentFrame_0:
  CALL DrawFrameRow       ; one row of 24 cells
  LD A,(HL)               ; next code: 0 = end of layout
  OR A
  JR NZ,DrawParchmentFrame_0
  RET

; Draw one row of 24 cells of the parchment frame
;
; Decodes layout codes with DrawFrameCell until 24 cells have been drawn, then
; moves the position down one row.
;
; Hardware: writes the screen bitmap and the attribute file (through
; DrawFrameCell).
;
;   DE Position of the first cell: E row (0-23), D column
;   HL Layout pointer
;   B' Attribute of blank cells
;   C' Attribute of frame tile cells
; O:DE Position of the next row (E + 1)
; O:HL Layout pointer after the row
; O:C 0
DrawFrameRow:
  LD C,PARCHMENT_COLS     ; cells in the row
  PUSH DE                 ; keep the row position
  EX DE,HL
  CALL AttrAddress        ; HL = attribute address of the first cell
  EX DE,HL
DrawFrameRow_0:
  CALL DrawFrameCell      ; draw one code; C counts the cells left
  LD A,C
  OR A
  JR NZ,DrawFrameRow_0
  POP DE
  INC E
  RET

; Decode one parchment layout code and draw its cell or run of blank cells
;
; Reads a layout code (see DrawParchmentFrame). Code 1 is followed by a count n
; and sets n attribute cells to B' (the bitmap is left alone). Any other code k
; draws frame tile k-2: its attribute C' is stored and its 8x8 bitmap, 8 bytes
; at ParchmentFrameTiles + 8*(k-2), is copied over the cell on screen.
;
; Hardware: writes the attribute file and the screen bitmap.
;
;   C Cells left in the row
;   DE Attribute address of the cell
;   HL Layout pointer
;   B' Attribute of blank cells
;   C' Attribute of frame tile cells
; O:C Cells left in the row (minus the cells drawn)
; O:DE Attribute address of the next cell
; O:HL Layout pointer after the code
DrawFrameCell:
  LD A,(HL)
  INC HL
  DEC A                   ; code 1: run of blank cells
  JR Z,DrawFrameCell_0
  DEC A                   ; A = frame tile number
  PUSH HL
  PUSH DE
  ADD A,A                 ; x 8: bytes per tile
  ADD A,A
  ADD A,A
  LD HL,ParchmentFrameTiles ; frame tile bitmaps
  CALL AddAToHL           ; HL = bitmap of the tile
  EXX                     ; EXX
  LD A,C
  EXX
  LD (DE),A               ; attribute of the frame tile
  EX DE,HL                ; HL = attribute address
  CALL AttrToBitmap       ; H = screen high byte of the cell
  EX DE,HL
  CALL CopyTileBitmap     ; copy 8 bitmap bytes to the cell
  POP DE
  POP HL
  INC E
  DEC C
  RET
DrawFrameCell_0:
  LD A,(HL)               ; blank run: A = number of cells
  INC HL
DrawFrameCell_1:
  PUSH AF                 ; attribute of blank cells
  EXX
  LD A,B
  EXX
  LD (DE),A
  POP AF
  INC E
  DEC C
  DEC A
  JR NZ,DrawFrameCell_1
  RET

; Run the pending event script (once)
;
; One-shot gate in the style of ParchmentGate: the first byte is NOP when a
; script is pending and RET otherwise, and the main loop (StartGame) calls this
; address on every pass. When pending, it writes RET over itself and runs the
; script at the address held in its own LD HL instruction (operand at $9CEE,
; SmcEventScript+1) with RunScript. The routines that start an event store the
; script address there and write 0 over the first byte: ActionChurchDoor (the
; church door shutting behind Jean, scripts DoorLeftShut and DoorLeftRattle),
; ActionGateLever (EraseDoorRight) and UpdateSatan (the twelve crosses,
; ScriptEraseCrosses). EnterRoom writes RET here when a room is entered.
RunEventScript:
  NOP
  LD HL,RunEventScript    ; disarm
  LD (HL),OP_RET
; SMC: the operand (script address) is written by ActionChurchDoor,
; ActionGateLever and UpdateSatan
SmcEventScript:
  LD HL,SmcEventScript    ; script address; the placeholder value is never used
  JP RunScript            ; run the script

; Attribute file row addresses: 22 words, $5800 + 32*row
;
; One word per row of the room area (rows 0-21): the address of the first
; attribute cell of the row. Read by the redraw routine DrawRedrawList.
AttrRowAddrs:
  DEFW ATTRS
  DEFW $5820
  DEFW $5840
  DEFW $5860
  DEFW $5880
  DEFW $58A0
  DEFW $58C0
  DEFW $58E0
  DEFW $5900
  DEFW $5920
  DEFW $5940
  DEFW $5960
  DEFW $5980
  DEFW $59A0
  DEFW $59C0
  DEFW $59E0
  DEFW $5A00
  DEFW $5A20
  DEFW $5A40
  DEFW $5A60
  DEFW $5A80
  DEFW $5AA0

; Script opcode jump table: handlers of the codes $80-$9F interpreted by $9D5F
;
; 32 words indexed by opcode - $80 (RunScript adds twice the code, without bit
; 7, to this address). The command set and its operand bytes are described at
; RunScript; each word is commented with its opcode number and what the handler
; does.
ScriptOpTable:
  DEFW OpEnd              ; $80 end of script
  DEFW OpFillPixels       ; $81 fill pixels: y x w h b
  DEFW OpSetTextAlign     ; $82 text alignment mode and text row: mode y
  DEFW OpCallScript       ; $83 run a subscript: word address
  DEFW OpPrintStringVar   ; $84 print the string whose number is in the byte at
                          ; the word address
  DEFW OpPrintString      ; $85 print string number n
  DEFW OpFillTiles        ; $86 fill a tile rectangle with one tile: y x w h t
  DEFW OpSetRoomName      ; $87 set the room name string number: n
  DEFW OpDefineBlock      ; $88 define the block pattern: w h, then w*h tile
                          ; numbers (OpDefineBlock)
  DEFW OpFillWithBlock    ; $89 fill a rectangle with the block pattern: y x w
                          ; h (OpFillWithBlock)
  DEFW OpFlagEdges        ; $8A flag the room border cells: mask (OpFlagEdges)
  DEFW OpStampRun         ; $8B tile run at several positions: n t1..tn k (y
                          ; x)*k
  DEFW OpPlaceTile        ; $8C place one tile: y x t
  DEFW OpTileStripes      ; $8D tile stripes: y x t c, c draw/skip counts
  DEFW OpSetTextCursor    ; $8E set the text cursor: y x (OpSetTextCursor)
  DEFW OpFillAttrs        ; $8F fill attributes: y x w h a
  DEFW OpMarkRedraw       ; $90 mark all cells for redraw (1) or unmark them
                          ; (0): f (OpMarkRedraw)
  DEFW OpStampTileBlock   ; $91 tile block at several positions: t w h k (y
                          ; x)*k (OpStampTileBlock)
  DEFW OpStampOne         ; $92 one tile at several positions: t k (y x)*k
  DEFW OpTileRow          ; $93 row of tiles: y x n t1..tn
  DEFW OpDrawTileMask     ; $94 tiles from a two-level bitmap: y x t c, c bytes
                          ; (OpDrawTileMask)
  DEFW OpRunIfZero        ; $95 run a subscript if a variable is 0: word word
                          ; (OpRunIfZero)
  DEFW OpSetFlagRect      ; $96 fill a rectangle of the tile flag map: y x w h
                          ; f (OpSetFlagRect)
  DEFW OpUnpackSprites    ; $97 unpack sprite set n: n (OpUnpackSprites)
  DEFW OpFillTilesList    ; $98 fill k rectangles with one tile: t k (y x w
                          ; h)*k
  DEFW OpFillBlockList    ; $99 fill k rectangles with the block pattern: k (y
                          ; x w h)*k (OpFillBlockList)
  DEFW OpTileVLine        ; $9A vertical line of a tile: t y x n, never used
                          ; (OpTileVLine)
  DEFW OpTileVLines       ; $9B vertical lines of a tile: t k (y x n)*k
                          ; (OpTileVLines)
  DEFW OpRunIfNonZero     ; $9C run a subscript if a variable is not 0: word
                          ; word (OpRunIfNonZero)
  DEFW OpSetupWater       ; $9D water strip with its reflection: y x a n
                          ; (OpSetupWater)
  DEFW OpAnimateBlood     ; $9E start the bubbling blood of the bottom row,
                          ; tiles $3B/$3C (OpAnimateBlood)
  DEFW OpTwelveCrosses    ; $9F start the twelve-crosses effect
                          ; (OpTwelveCrosses)
