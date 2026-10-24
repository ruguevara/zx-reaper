; Room script table: the address of the script of each room 0-25
;
; Word n is the address of the script of room n (RunScript runs it when
; EnterRoom enters the room): index = room number RoomNumber times 2, 26
; entries. The scripts follow from $726A in the same order, each followed by
; the subscripts that belong to the rooms around it. Room 25 is the ending room
; (RunEnding).
RoomScriptTable:
  DEFW RoomScript00,RoomScript01,RoomScript02,RoomScript03
  DEFW RoomScript04,RoomScript05,RoomScript06,RoomScript07
  DEFW RoomScript08,RoomScript09,RoomScript10,RoomScript11
  DEFW RoomScript12,RoomScript13,RoomScript14,RoomScript15
  DEFW RoomScript16,RoomScript17,RoomScript18,RoomScript19
  DEFW RoomScript20,RoomScript21,RoomScript22,RoomScript23
  DEFW RoomScript24,RoomScript25

; Room script 0: intro text screen
;
; Room scripts are bytecode programs run by the script interpreter RunScript:
; EnterRoom looks up the script of room N in the table RoomScriptTable and runs
; it when the room is entered, RunScript loops over its codes until an END
; ($80). A script paints the room: it writes tile numbers into the tile map
; (and their flags into the tile flag map, through PlaceTile), unpacks the
; sprite sets, prints the room name, and occasionally prints text or fills
; screen memory directly (the parchment, ending and title screens). Everything
; else about a room (enemies, items) comes from the object tables RoomObjects
; and RoomItems, not from the script.
;
; Format. A byte below $80 is a character: it is printed in the proportional
; font at the text cursor (DrawGlyph). A byte of $80 or more is an opcode,
; which indexes the jump table ScriptOpTable with (opcode-$80)*2; the operand
; bytes follow it. y is a row and x a column in tile (character cell) units
; unless marked as a pixel position; a "position (y,x)" is two bytes in that
; order; w and h are a width and height in cells; (...)*n is a list repeated n
; times. Tiles are numbers into the tile tables at TileFlags (flags), TileAttrs
; (attributes) and TileGfx (bitmaps).
;
; $80 END: end of the script (of a subscript too: it returns to the caller) $81
; y,x,w,h,b: FILLPIX, fill screen bitmap bytes with b: y is a pixel row
; (0-191), x a byte column, w bytes by h pixel rows (OpFillPixels) $82 mode,y:
; ALIGN, set how the next string is aligned (1 left, 2 centred, 0 right) and
; its pixel row (OpSetTextAlign) $83 addr: CALL the subscript at addr (a word),
; then go on (OpCallScript) $84 addr: PRINTVAR, print the string whose number
; is in the byte at addr (a word, OpPrintStringVar) $85 n: PRINT string number
; n (OpPrintString) $86 y,x,w,h,t: FILLTILE, fill a rectangle of the tile map
; with tile t (OpFillTiles) $87 n: ROOMNAME, store n as the room name string
; number RoomNameString (OpSetRoomName) $88 w,h,t...: BLOCK, define the current
; block, a pattern of w x h tiles that follows (OpDefineBlock) $89 y,x,w,h:
; TILEBLOCK, fill a rectangle with the current block repeated, its top-left
; tile at the rectangle's corner (OpFillWithBlock) $8A m: EDGES, make room
; edges solid by setting flag bit 1 on the border cells: bit 0 left column, 1
; right column, 2 top row, 3 the row of 32 cells at $60E0 under the room
; (OpFlagEdges) $8B c,t1..tc,n,(y,x)*n: STAMPS, draw a row of the c tiles at n
; positions (OpStampRun) $8C y,x,t: TILE1, one tile at a position (OpPlaceTile)
; $8D y,x,t,n,r1..rn: RUNS, from (y,x) draw tile t along the row (continuing on
; the next row after column 31): runs r1, r3, ... are drawn, r2, r4, ... are
; skipped (OpTileStripes) $8E y,x: CURSOR, set the text cursor to a pixel row
; and a pixel column (OpSetTextCursor) $8F y,x,w,h,a: FILLATTR, fill attribute
; bytes with a: y is a character row (OpFillAttrs) $90 b: REDRAWMARK, with 1
; mark every cell of the flag map for redraw, with 0 clear all marks
; (OpMarkRedraw) $91 t,w,h,n,(y,x)*n: PICTURES, draw a picture of w x h tiles
; numbered t, t+1, ... (row by row) at n positions (OpStampTileBlock) $92
; t,n,(y,x)*n: STAMP1, draw tile t at n positions (OpStampOne) $93
; y,x,n,t1..tn: ROW, draw a row of n listed tiles (OpTileRow) $94
; y,x,t,c,bytes: BITMAP, draw tile t where a compressed bit map has set bits: c
; bytes follow, flag bits say whether 8 cells are skipped or described by the
; next byte (OpDrawTileMask) $95 sub,var: IFZERO, run the subscript at sub (a
; word) if the byte at address var (a word) is 0 (OpRunIfZero) $96 y,x,w,h,f:
; FLAGS, set the flag map bytes of a rectangle to f, leaving the tiles alone
; (OpSetFlagRect) $97 n: SPRITESET, unpack packed sprite set n into the sprite
; sheet (OpUnpackSprites, UnpackSpriteSet) $98 t,n,(y,x,w,h)*n: RECTS, fill n
; rectangles with tile t (OpFillTilesList) $99 n,(y,x,w,h)*n: TILEBLOCKS, as
; $89 for n rectangles (OpFillBlockList) $9A t,y,x,len: RUN1, a vertical run of
; tile t; never used (OpTileVLine) $9B t,n,(y,x,len)*n: RUNS_V, n vertical runs
; of tile t (OpTileVLines) $9C sub,var: IFNZ, run the subscript if the byte at
; var is not 0 (OpRunIfNonZero) $9D y,x,a,w: WATER, start the water strip
; (DrawWaterReflection, a reflection of the scenery above it): w cells at row y
; from column x painted with attribute a and given the harmful flag value 4
; (OpSetupWater) $9E: enable the animation of the blood tiles in the bottom
; row: the RET at the start of AnimateBloodTiles is replaced by a NOP
; (OpAnimateBlood) $9F: enable the ring of twelve crosses: the RET at the start
; of ShowCrossRing is replaced by a NOP (OpTwelveCrosses)
;
; The room scripts of the 26 rooms follow in the order of RoomScriptTable,
; interleaved with the small subscripts they call (blocks, doors, the room
; panel).
;
; Not a room of the abbey: the intro text screen shown before the game starts
; (RunIntro enters it as room 0). It clears the tile map, the attributes and
; the whole screen bitmap, prints the five lines of the story (strings 38-42,
; centred at pixel rows 12, 32, 52, 147 and 167), sets the attributes to white
; on black and clears the redraw marks (op $90 with 0) so that nothing is
; redrawn over the text.
;
; Hardware: writes the screen bitmap and the attribute file directly (ops $81
; and $8F), not through the tile map.
RoomScript00:
  DEFB $97,$01            ; SPRITESET 1
  DEFB $86,$00,$00,$20,$16,$00 ; FILLTILE row 0, col 0, 32x22, tile $00
  DEFB $8F,$00,$00,$20,$18,$00 ; FILLATTR row 0, col 0, 32x24, attribute $00
  DEFB $81,$00,$00,$20,$C0,$00 ; FILLPIX pixel row 0, byte col 0, 32 bytes x
                               ; 192 rows, byte $00
  DEFB $82,$02,$0C        ; ALIGN mode 2, pixel row 12
  DEFB $85,$26            ; PRINT string 38 "13th Century. The Cathars were"
  DEFB $82,$02,$20        ; ALIGN mode 2, pixel row 32
  DEFB $85,$27            ; PRINT string 39 "being expelled by the Catholic"
  DEFB $82,$02,$34        ; ALIGN mode 2, pixel row 52
  DEFB $85,$28            ; PRINT string 40 "Church out of the Lanquedoc"
  DEFB $82,$02,$93        ; ALIGN mode 2, pixel row 147
  DEFB $85,$29            ; PRINT string 41 "The Cathar Jean Raymond"
  DEFB $82,$02,$A7        ; ALIGN mode 2, pixel row 167
  DEFB $85,$2A            ; PRINT string 42 "runs to escape the crusaders..."
  DEFB $8F,$00,$00,$20,$18,$07 ; FILLATTR row 0, col 0, 32x24, attribute $07
  DEFB $90,$00            ; REDRAWMARK clear all marks
  DEFB $80                ; END

; Room script 1: A prayer of Hope
;
; Room 1: column 1, row 0 of the 5x5 map (left is room 0, right 2, up 21, down
; 6, counted modulo 25). Subscripts: ScriptRoomPanel, ScriptSky. No items.
RoomScript01:
  DEFB $87,$01            ; ROOMNAME 1 "A prayer of Hope"
  DEFB $83                ; CALL ScriptRoomPanel
  DEFW ScriptRoomPanel
  DEFB $83                ; CALL ScriptSky
  DEFW ScriptSky
  DEFB $88,$02,$02,$06,$07,$0B,$0A ; BLOCK 2x2: $06 $07 $0B $0A
  DEFB $89,$00,$1E,$02,$16 ; TILEBLOCK row 0, col 30, 2x22
  DEFB $88,$02,$01,$7D,$80 ; BLOCK 2x1: $7D $80
  DEFB $89,$04,$1E,$02,$04 ; TILEBLOCK row 4, col 30, 2x4
  DEFB $98,$8A,$02,$13,$00,$09,$03,$12 ; RECTS tile $8A, 2 rectangles
  DEFB $00,$07,$01
  DEFB $98,$89,$02,$10,$00,$04,$02,$10 ; RECTS tile $89, 2 rectangles
  DEFB $1D,$01,$06
  DEFB $92,$89,$09,$11,$04,$11,$05,$12,$02,$12,$1C,$13,$08,$13,$1C,$14 ; STAMP1
                                                                       ; tile $89
                                                                       ; at 9
                                                                       ; positions
  DEFB $09,$14,$1C,$15,$09
  DEFB $92,$0C,$02,$00,$1F,$12,$1F ; STAMP1 tile $0C at 2 positions
  DEFB $80                ; END

; Room script 2: Tower of the Bell
;
; Room 2: column 2, row 0 of the 5x5 map (left is room 1, right 3, up 22, down
; 7, counted modulo 25). Unpacks sprite set PackedSet13. Subscripts:
; ScriptRoomPanel, ScriptSky, BlockStoneB, BlockStoneA. Items (RoomItems) at
; row,column: bell 1,5, heart 7,12.
RoomScript02:
  DEFB $97,$0D            ; SPRITESET 13
  DEFB $87,$02            ; ROOMNAME 2 "Tower of the Bell"
  DEFB $83                ; CALL ScriptRoomPanel
  DEFW ScriptRoomPanel
  DEFB $83                ; CALL ScriptSky
  DEFW ScriptSky
  DEFB $86,$00,$00,$10,$0A,$80 ; FILLTILE row 0, col 0, 16x10, tile $80
  DEFB $83                ; CALL BlockStoneB
  DEFW BlockStoneB
  DEFB $99,$03,$00,$00,$02,$04,$08,$00 ; TILEBLOCKS 3 rectangles
  DEFB $02,$0E,$00,$0E,$02,$0A
  DEFB $86,$06,$10,$10,$04,$11 ; FILLTILE row 6, col 16, 16x4, tile $11
  DEFB $98,$13,$02,$00,$02,$0C,$01,$05 ; RECTS tile $13, 2 rectangles
  DEFB $10,$10,$01
  DEFB $83                ; CALL BlockStoneA
  DEFW BlockStoneA
  DEFB $99,$02,$14,$06,$1A,$02,$0A,$0E ; TILEBLOCKS 2 rectangles
  DEFB $12,$01
  DEFB $8B,$02,$0E,$0F,$04,$09,$02,$09 ; STAMPS 2 tiles $0E $0F at 4 positions
  DEFB $04,$09,$06,$09,$0C
  DEFB $92,$10,$05,$0B,$08,$0D,$09,$0F ; STAMP1 tile $10 at 5 positions
  DEFB $0A,$11,$0B,$15,$02
  DEFB $92,$12,$05,$06,$19,$06,$1C,$06 ; STAMP1 tile $12 at 5 positions
  DEFB $1E,$07,$13,$08,$17
  DEFB $80                ; END

; Block pattern: grey stone wall (2x2 tiles $07,$08,$0A,$09)
;
; Defines the current block (op $88) as a 2x2 pattern of grey cobbled stone, to
; be repeated over rectangles by ops $89/$99. A variant of BlockStoneB that
; differs in the last tile. Called as a subscript by rooms 2, 3, 7.
BlockStoneA:
  DEFB $88,$02,$02,$07,$08,$0A,$09 ; BLOCK 2x2: $07 $08 $0A $09
  DEFB $80                ; END

; Block pattern: grey stone wall, variant (tiles $07,$08,$0A,$0D)
;
; Defines the current block (op $88) as a 2x2 pattern of grey cobbled stone:
; the same as BlockStoneA but for the bottom-right tile. Called by rooms 2, 7.
BlockStoneB:
  DEFB $88,$02,$02,$07,$08,$0A,$0D ; BLOCK 2x2: $07 $08 $0A $0D
  DEFB $80                ; END

; Room script 3: Wine supplies
;
; Room 3: column 3, row 0 of the 5x5 map (left is room 2, right 4, up 23, down
; 8, counted modulo 25). Subscripts: ScriptRoomPanel, ScriptSky, BlockStoneA.
; Items (RoomItems) at row,column: parchment 16,18, cross 18,28.
RoomScript03:
  DEFB $87,$03            ; ROOMNAME 3 "Wine supplies"
  DEFB $83                ; CALL ScriptRoomPanel
  DEFW ScriptRoomPanel
  DEFB $83                ; CALL ScriptSky
  DEFW ScriptSky
  DEFB $83                ; CALL BlockStoneA
  DEFW BlockStoneA
  DEFB $99,$03,$14,$00,$20,$02,$0A,$1E ; TILEBLOCKS 3 rectangles
  DEFB $02,$0A,$0A,$00,$20,$01
  DEFB $86,$06,$00,$20,$04,$11 ; FILLTILE row 6, col 0, 32x4, tile $11
  DEFB $86,$05,$00,$20,$01,$13 ; FILLTILE row 5, col 0, 32x1, tile $13
  DEFB $8B,$02,$A1,$A2,$02,$0D,$1A,$0E ; STAMPS 2 tiles $A1 $A2 at 2 positions
  DEFB $1A
  DEFB $8B,$02,$17,$18,$04,$10,$14,$12 ; STAMPS 2 tiles $17 $18 at 4 positions
  DEFB $0E,$12,$12,$12,$14
  DEFB $8B,$02,$19,$1A,$04,$11,$14,$13 ; STAMPS 2 tiles $19 $1A at 4 positions
  DEFB $0E,$13,$12,$13,$14
  DEFB $92,$12,$05,$06,$00,$06,$1C,$07 ; STAMP1 tile $12 at 5 positions
  DEFB $15,$08,$04,$08,$1E
  DEFB $80                ; END

; Room script 4: Room 4 (no name)
;
; Has no room name, so the name panel is not drawn. Besides being the room of
; the grid it is the setting of the second part of the ending (RunEnding): the
; script clears the two bottom character rows with op $81 and, with op $90,
; forces a full redraw. Quirk (F67): in play nothing redraws the status bar
; that op $81 has erased, so the hearts and crosses stay blank, also in the
; next rooms, until a life or a cross is gained or lost.
;
; Room 4: column 4, row 0 of the 5x5 map (left is room 3, right 5, up 24, down
; 9, counted modulo 25). Unpacks sprite set PackedSet1. Subscripts: ScriptSky,
; BlockTreeBark, BlockGrassEarth. No items.
;
; Hardware: writes the screen bitmap and the attribute file directly (ops $81
; and $8F), not through the tile map.
RoomScript04:
  DEFB $97,$01            ; SPRITESET 1
  DEFB $86,$00,$00,$20,$16,$80 ; FILLTILE row 0, col 0, 32x22, tile $80
  DEFB $81,$B0,$00,$20,$10,$00 ; FILLPIX pixel row 176, byte col 0, 32 bytes x
                               ; 16 rows, byte $00
  DEFB $83                ; CALL ScriptSky
  DEFW ScriptSky
  DEFB $83                ; CALL BlockTreeBark
  DEFW BlockTreeBark
  DEFB $99,$03,$06,$01,$02,$0E,$04,$1C ; TILEBLOCKS 3 rectangles
  DEFB $02,$10,$0B,$10,$01,$07
  DEFB $83                ; CALL BlockGrassEarth
  DEFW BlockGrassEarth
  DEFB $89,$14,$00,$20,$02 ; TILEBLOCK row 20, col 0, 32x2
  DEFB $86,$12,$0D,$07,$02,$1B ; FILLTILE row 18, col 13, 7x2, tile $1B
  DEFB $98,$8A,$02,$00,$00,$08,$03,$00 ; RECTS tile $8A, 2 rectangles
  DEFB $17,$09,$03
  DEFB $8B,$04,$8A,$8A,$89,$8A,$04,$00 ; STAMPS 4 tiles $8A $8A $89 $8A at 4
                                       ; positions
  DEFB $05,$00,$16,$03,$01,$03,$18
  DEFB $8B,$02,$8C,$86,$03,$08,$1B,$0B ; STAMPS 2 tiles $8C $86 at 3 positions
  DEFB $00,$0D,$1B
  DEFB $8B,$02,$87,$88,$02,$08,$02,$0B ; STAMPS 2 tiles $87 $88 at 2 positions
  DEFB $1D
  DEFB $92,$99,$02,$0E,$02,$0F,$1D ; STAMP1 tile $99 at 2 positions
  DEFB $92,$81,$03,$13,$00,$13,$03,$13 ; STAMP1 tile $81 at 3 positions
  DEFB $1F
  DEFB $8D,$02,$07,$89,$0F,$01,$15,$01,$02,$01,$04,$02,$15,$0A,$13,$0B ; RUNS from
                                                                       ; row 2, col
                                                                       ; 7, tile
                                                                       ; $89, 15
                                                                       ; runs
  DEFB $16,$02,$02,$01
  DEFB $90,$01            ; REDRAWMARK mark all cells
  DEFB $80                ; END

; Block pattern: grass over earth (tiles $03,$04,$01,$02)
;
; Defines the current block as 2x2 tiles of grass on top of yellow earth, the
; ground of the forest rooms. Called by rooms 4, 5, 6, 9.
BlockGrassEarth:
  DEFB $88,$02,$02,$03,$04,$01,$02 ; BLOCK 2x2: $03 $04 $01 $02
  DEFB $80                ; END

; Block pattern: tree bark (tiles $84,$85,$82,$83)
;
; Defines the current block as 2x2 tiles of red tree bark (the tree trunks of
; the forest rooms). Called by rooms 4, 5, 6.
BlockTreeBark:
  DEFB $88,$02,$02,$84,$85,$82,$83 ; BLOCK 2x2: $84 $85 $82 $83
  DEFB $80                ; END

; Room script 5: Escape !!!
;
; Op $8A with 1 makes the left edge solid: the player cannot leave this room to
; the left (observed: holding left stays at the edge), so the crusaders' chase
; of rooms 4-6 only goes one way.
;
; Room 5: column 0, row 1 of the 5x5 map (left is room 4, right 6, up 0, down
; 10, counted modulo 25). Unpacks sprite set PackedSet1. Subscripts:
; ScriptRoomPanel, BlockGrassEarth, BlockTreeBark. No items.
RoomScript05:
  DEFB $97,$01            ; SPRITESET 1
  DEFB $87,$05            ; ROOMNAME 5 "Escape !!!"
  DEFB $83                ; CALL ScriptRoomPanel
  DEFW ScriptRoomPanel
  DEFB $83                ; CALL BlockGrassEarth
  DEFW BlockGrassEarth
  DEFB $99,$03,$14,$00,$20,$02,$13,$14 ; TILEBLOCKS 3 rectangles
  DEFB $06,$02,$12,$16,$04,$02
  DEFB $83                ; CALL BlockTreeBark
  DEFW BlockTreeBark
  DEFB $99,$07,$06,$01,$02,$0E,$04,$07,$02,$10,$08,$0C,$02,$0C,$0C,$0F ; TILEBLOCKS
                                                                       ; 7
                                                                       ; rectangles
  DEFB $02,$08,$05,$0F,$02,$08,$07,$1B,$02,$01,$08,$1B,$02,$0C
  DEFB $8B,$02,$8C,$86,$07,$06,$06,$08,$06,$09,$0E,$09,$1A,$0B,$00,$0D ; STAMPS 2
                                                                       ; tiles $8C
                                                                       ; $86 at 7
                                                                       ; positions
  DEFB $0B,$0D,$1A
  DEFB $8B,$02,$87,$88,$06,$07,$10,$08,$02,$0A,$08,$0B,$0D,$0B,$1C,$0D ; STAMPS 2
                                                                       ; tiles $87
                                                                       ; $88 at 6
                                                                       ; positions
  DEFB $10
  DEFB $92,$99,$05,$06,$08,$0E,$02,$0E ; STAMP1 tile $99 at 5 positions
  DEFB $0D,$0E,$10,$0F,$1C
  DEFB $92,$81,$07,$11,$17,$13,$00,$13,$03,$13,$0A,$13,$12,$13,$1E,$13 ; STAMP1
                                                                       ; tile $81
                                                                       ; at 7
                                                                       ; positions
  DEFB $1F
  DEFB $86,$00,$00,$20,$04,$8A ; FILLTILE row 0, col 0, 32x4, tile $8A
  DEFB $8D,$02,$07,$89,$35,$04,$04,$03,$0B,$01,$08,$10,$06,$04,$01,$06 ; RUNS from
                                                                       ; row 2, col
                                                                       ; 7, tile
                                                                       ; $89, 53
                                                                       ; runs
  DEFB $02,$08,$01,$06,$01,$06,$01,$06,$05,$04,$02,$01,$01,$04,$01,$06
  DEFB $0C,$04,$04,$0D,$0C,$04,$05,$07,$1A,$02,$08,$01,$15,$01,$21,$02
  DEFB $0B,$01,$0E,$01,$04,$03,$0A,$01,$18,$01
  DEFB $8C,$0C,$07,$8B    ; TILE1 row 12, col 7, tile $8B
  DEFB $8C,$04,$00,$8A    ; TILE1 row 4, col 0, tile $8A
  DEFB $8A,$01            ; EDGES left
  DEFB $80                ; END

; Room script 6: Death is close
;
; The door of the Abandoned church: while ChurchDoorShut is nonzero (the player
; has entered room 7) the script draws the door DoorRight at the right edge so
; that the way into room 7 stays shut.
;
; Room 6: column 1, row 1 of the 5x5 map (left is room 5, right 7, up 1, down
; 11, counted modulo 25). Unpacks sprite set PackedSet1. Subscripts:
; ScriptRoomPanel, ScriptSky, BlockTreeBark, BlockGrassEarth. No items.
RoomScript06:
  DEFB $97,$01            ; SPRITESET 1
  DEFB $87,$06            ; ROOMNAME 6 "Death is close"
  DEFB $83                ; CALL ScriptRoomPanel
  DEFW ScriptRoomPanel
  DEFB $83                ; CALL ScriptSky
  DEFW ScriptSky
  DEFB $83                ; CALL BlockTreeBark
  DEFW BlockTreeBark
  DEFB $89,$08,$02,$02,$0C ; TILEBLOCK row 8, col 2, 2x12
  DEFB $83                ; CALL BlockGrassEarth
  DEFW BlockGrassEarth
  DEFB $89,$14,$00,$20,$02 ; TILEBLOCK row 20, col 0, 32x2
  DEFB $88,$01,$02,$80,$05 ; BLOCK 1x2: $80 $05
  DEFB $99,$03,$14,$0A,$02,$02,$14,$10 ; TILEBLOCKS 3 rectangles
  DEFB $02,$02,$14,$14,$02,$02
  DEFB $91,$91,$02,$02,$05,$10,$0B,$10 ; PICTURES tiles from $91, 2x2, at 5
                                       ; positions
  DEFB $15,$11,$09,$11,$10,$11,$17
  DEFB $88,$03,$02,$06,$07,$08,$0B,$0A ; BLOCK 3x2: $06 $07 $08 $0B $0A $09
  DEFB $09
  DEFB $89,$00,$1D,$03,$0E ; TILEBLOCK row 0, col 29, 3x14
  DEFB $98,$8A,$02,$00,$00,$0A,$04,$04 ; RECTS tile $8A, 2 rectangles
  DEFB $00,$08,$02
  DEFB $98,$89,$02,$05,$00,$04,$02,$06 ; RECTS tile $89, 2 rectangles
  DEFB $02,$04,$02
  DEFB $8B,$02,$89,$89,$03,$05,$06,$06 ; STAMPS 2 tiles $89 $89 at 3 positions
  DEFB $05,$0C,$00
  DEFB $8B,$03,$06,$07,$08,$02,$12,$1D ; STAMPS 3 tiles $06 $07 $08 at 2
                                       ; positions
  DEFB $13,$1C
  DEFB $8B,$02,$95,$96,$04,$0F,$0F,$0F ; STAMPS 2 tiles $95 $96 at 4 positions
  DEFB $15,$10,$0D,$11,$12
  DEFB $8B,$02,$97,$98,$02,$11,$0D,$12 ; STAMPS 2 tiles $97 $98 at 2 positions
  DEFB $12
  DEFB $8B,$02,$8C,$86,$01,$0A,$01 ; STAMPS 2 tiles $8C $86 at 1 positions
  DEFB $8B,$02,$87,$88,$01,$0C,$03 ; STAMPS 2 tiles $87 $88 at 1 positions
  DEFB $92,$81,$03,$13,$00,$13,$05,$13 ; STAMP1 tile $81 at 3 positions
  DEFB $19
  DEFB $92,$0C,$02,$02,$1E,$0A,$1E ; STAMP1 tile $0C at 2 positions
  DEFB $92,$89,$07,$02,$09,$03,$09,$04,$02,$04,$08,$08,$00,$0B,$00,$0F ; STAMP1
                                                                       ; tile $89
                                                                       ; at 7
                                                                       ; positions
  DEFB $01
  DEFB $8C,$0E,$02,$8B    ; TILE1 row 14, col 2, tile $8B
  DEFB $8C,$13,$1F,$07    ; TILE1 row 19, col 31, tile $07
  DEFB $9C                ; IFNZ run DoorRight if ChurchDoorShut is not 0
  DEFW DoorRight
  DEFW ChurchDoorShut
  DEFB $80                ; END

; Room script 7: Abandoned church
;
; Entered through its left door, behind which the door closes: while
; ChurchDoorShut is nonzero it draws the left door DoorLeftShut.
;
; Room 7: column 2, row 1 of the 5x5 map (left is room 6, right 8, up 2, down
; 12, counted modulo 25). Subscripts: ScriptRoomPanel, BlockStoneB,
; BlockStoneA, BlockStoneHalfA. Items (RoomItems) at row,column: church door
; trigger 15,2.
RoomScript07:
  DEFB $87,$07            ; ROOMNAME 7 "Abandoned church"
  DEFB $83                ; CALL ScriptRoomPanel
  DEFW ScriptRoomPanel
  DEFB $83                ; CALL BlockStoneB
  DEFW BlockStoneB
  DEFB $99,$03,$00,$00,$02,$0E,$12,$00 ; TILEBLOCKS 3 rectangles
  DEFB $02,$02,$00,$06,$1A,$01
  DEFB $8C,$00,$13,$08    ; TILE1 row 0, col 19, tile $08
  DEFB $83                ; CALL BlockStoneA
  DEFW BlockStoneA
  DEFB $89,$14,$00,$20,$02 ; TILEBLOCK row 20, col 0, 32x2
  DEFB $88,$02,$01,$A1,$A2 ; BLOCK 2x1: $A1 $A2
  DEFB $99,$06,$05,$08,$02,$0A,$05,$0C,$02,$0A,$05,$10,$02,$0A,$05,$14 ; TILEBLOCKS
                                                                       ; 6
                                                                       ; rectangles
  DEFB $02,$0A,$05,$18,$02,$0A,$05,$1C,$02,$0A
  DEFB $83                ; CALL BlockStoneHalfA
  DEFW BlockStoneHalfA
  DEFB $99,$02,$08,$02,$11,$02,$08,$17 ; TILEBLOCKS 2 rectangles
  DEFB $09,$02
  DEFB $8B,$02,$9A,$9B,$02,$13,$06,$13 ; STAMPS 2 tiles $9A $9B at 2 positions
  DEFB $16
  DEFB $8B,$02,$9D,$9E,$04,$13,$0A,$13 ; STAMPS 2 tiles $9D $9E at 4 positions
  DEFB $0E,$13,$12,$13,$1A
  DEFB $8B,$02,$9F,$A0,$06,$04,$08,$04,$0C,$04,$10,$04,$14,$04,$18,$04 ; STAMPS 2
                                                                       ; tiles $9F
                                                                       ; $A0 at 6
                                                                       ; positions
  DEFB $1C
  DEFB $8B,$02,$0A,$0D,$03,$06,$03,$07 ; STAMPS 2 tiles $0A $0D at 3 positions
  DEFB $02,$07,$04
  DEFB $92,$A3,$0C,$06,$09,$06,$1D,$07,$08,$07,$11,$0A,$11,$0A,$19,$0B ; STAMP1
                                                                       ; tile $A3
                                                                       ; at 12
                                                                       ; positions
  DEFB $0C,$0C,$0D,$0C,$1D,$0D,$15,$0D,$1D,$0E,$1C
  DEFB $92,$9C,$04,$12,$0A,$12,$0E,$12 ; STAMP1 tile $9C at 4 positions
  DEFB $12,$12,$1A
  DEFB $92,$0C,$02,$06,$00,$15,$07 ; STAMP1 tile $0C at 2 positions
  DEFB $8C,$06,$02,$07    ; TILE1 row 6, col 2, tile $07
  DEFB $8C,$07,$03,$09    ; TILE1 row 7, col 3, tile $09
  DEFB $8C,$02,$02,$10    ; TILE1 row 2, col 2, tile $10
  DEFB $9C                ; IFNZ run DoorLeftShut if ChurchDoorShut is not 0
  DEFW DoorLeftShut
  DEFW ChurchDoorShut
  DEFB $80                ; END

; Picture: the shut door at the left edge, rows 14-17 (tiles $BC-$BF)
;
; Draws a 1x4 picture of the red studded door (tiles $BC,$BD,$BE,$BF) at row
; 14, column 0. Run by room 7 while the church door flag ChurchDoorShut is set,
; and by the church trigger ActionChurchDoor (script address stored in $9CEE)
; when the door shuts. Alternates with DoorLeftRattle.
DoorLeftShut:
  DEFB $91,$BC,$01,$04,$01,$0E,$00 ; PICTURES tiles from $BC, 1x4, at 1
                                   ; positions
  DEFB $80                ; END

; Picture: the left door of the church in its second look (tiles $77-$7A)
;
; Draws a 1x4 picture of the door (tiles $77,$78,$79,$7A) at row 14, column 0,
; over the picture of DoorLeftShut: the church trigger ActionChurchDoor
; alternates the two scripts at random intervals while sound 8 plays, so the
; shut door seems to rattle.
DoorLeftRattle:
  DEFB $91,$77,$01,$04,$01,$0E,$00 ; PICTURES tiles from $77, 1x4, at 1
                                   ; positions
  DEFB $80                ; END

; Block pattern: stone with a clear lower half (tiles $0E,$0F,$80,$80)
;
; Defines the current block as stone tiles over two blank tiles (a ledge or
; arch). Called by rooms 7, 8.
BlockStoneHalfA:
  DEFB $88,$02,$02,$0E,$0F,$80,$80 ; BLOCK 2x2: $0E $0F $80 $80
  DEFB $80                ; END

; Room script 8: The Altar
;
; Two conditional parts: the door DoorRight at the right edge while the lever
; of room 10 (LeverRoom10) is still 0, and EraseWallBlock which erases a 2x2
; block of wall once the bell of room 2 (BellRung) has rung.
;
; Room 8: column 3, row 1 of the 5x5 map (left is room 7, right 9, up 3, down
; 13, counted modulo 25). Unpacks sprite set PackedSet15. Subscripts:
; ScriptRoomPanel, BlockStoneHalfA. Items (RoomItems) at row,column: parchment
; 18,27, checkpoint 17,7.
RoomScript08:
  DEFB $97,$0F            ; SPRITESET 15
  DEFB $87,$08            ; ROOMNAME 8 "The Altar"
  DEFB $83                ; CALL ScriptRoomPanel
  DEFW ScriptRoomPanel
  DEFB $8B,$02,$95,$96,$01,$0F,$13 ; STAMPS 2 tiles $95 $96 at 1 positions
  DEFB $88,$01,$02,$1B,$16 ; BLOCK 1x2: $1B $16
  DEFB $89,$10,$11,$06,$02 ; TILEBLOCK row 16, col 17, 6x2
  DEFB $8B,$02,$9F,$A0,$02,$04,$00,$04 ; STAMPS 2 tiles $9F $A0 at 2 positions
  DEFB $04
  DEFB $88,$02,$01,$A1,$A2 ; BLOCK 2x1: $A1 $A2
  DEFB $99,$02,$05,$00,$02,$0A,$05,$04 ; TILEBLOCKS 2 rectangles
  DEFB $02,$0A
  DEFB $92,$A3,$07,$06,$01,$07,$05,$0A,$00,$0A,$04,$0A,$05,$0B,$05,$0D ; STAMP1
                                                                       ; tile $A3
                                                                       ; at 7
                                                                       ; positions
  DEFB $04
  DEFB $83                ; CALL BlockStoneHalfA
  DEFW BlockStoneHalfA
  DEFB $99,$03,$08,$00,$08,$02,$0B,$08 ; TILEBLOCKS 3 rectangles
  DEFB $02,$02,$0E,$0A,$04,$02
  DEFB $88,$02,$02,$07,$08,$09,$0A ; BLOCK 2x2: $07 $08 $09 $0A
  DEFB $99,$02,$00,$00,$1E,$01,$14,$00 ; TILEBLOCKS 2 rectangles
  DEFB $20,$02
  DEFB $88,$02,$02,$07,$08,$0D,$09 ; BLOCK 2x2: $07 $08 $0D $09
  DEFB $99,$02,$00,$1E,$02,$0E,$12,$1E ; TILEBLOCKS 2 rectangles
  DEFB $02,$02
  DEFB $92,$0B,$02,$12,$10,$13,$0F ; STAMP1 tile $0B at 2 positions
  DEFB $92,$0C,$04,$03,$1F,$08,$1E,$12 ; STAMP1 tile $0C at 4 positions
  DEFB $12,$14,$04
  DEFB $8C,$12,$17,$15    ; TILE1 row 18, col 23, tile $15
  DEFB $8C,$13,$18,$14    ; TILE1 row 19, col 24, tile $14
  DEFB $93,$12,$11,$06,$08,$0C,$08,$07 ; ROW row 18, col 17, 6 tiles
  DEFB $08,$07
  DEFB $93,$13,$10,$08,$0A,$0A,$0A,$09 ; ROW row 19, col 16, 8 tiles
  DEFB $0A,$09,$0A,$09
  DEFB $91,$C0,$04,$01,$01,$04,$12 ; PICTURES tiles from $C0, 4x1, at 1
                                   ; positions
  DEFB $91,$C4,$06,$04,$01,$05,$11 ; PICTURES tiles from $C4, 6x4, at 1
                                   ; positions
  DEFB $91,$DC,$04,$01,$01,$09,$12 ; PICTURES tiles from $DC, 4x1, at 1
                                   ; positions
  DEFB $95                ; IFZERO run DoorRight if LeverRoom10 is 0
  DEFW DoorRight
  DEFW LeverRoom10
  DEFB $91,$7E,$02,$01,$01,$13,$07 ; PICTURES tiles from $7E, 2x1, at 1
                                   ; positions
  DEFB $9C                ; IFNZ run EraseWallBlock if BellRung is not 0
  DEFW EraseWallBlock
  DEFW BellRung
  DEFB $80                ; END

; Erase the 2x2 wall block of The Altar after the bell has rung
;
; Fills the 2x2 cells at row 20, column 26 with the blank tile $80. Run by room
; 8 (op $9C) when BellRung, the bell of the Tower of the Bell, is nonzero.
EraseWallBlock:
  DEFB $86,$14,$1A,$02,$02,$80 ; FILLTILE row 20, col 26, 2x2, tile $80
  DEFB $80                ; END

; Picture: the door at the right edge, rows 14-17 (tiles $B8-$BB)
;
; Draws a 1x4 picture of the red studded door (tiles $B8,$B9,$BA,$BB) at row
; 14, column 31, closing the passage to the right. Run by room 6 while
; ChurchDoorShut is set, by room 8 while the lever LeverRoom10 is 0 and by room
; 20 while the lever LeverRoom20 is 0.
DoorRight:
  DEFB $91,$B8,$01,$04,$01,$0E,$1F ; PICTURES tiles from $B8, 1x4, at 1
                                   ; positions
  DEFB $80                ; END

; Room script 9: Hangman tree
;
; Draws the tree with a compressed bitmap (op $94) and sets up the second
; sprite set.
;
; Room 9: column 4, row 1 of the 5x5 map (left is room 8, right 10, up 4, down
; 14, counted modulo 25). Unpacks sprite sets PackedSet10, PackedSet19.
; Subscripts: ScriptRoomPanel, BlockGrassEarth. Items (RoomItems) at
; row,column: lever 18,27, cross 4,6.
RoomScript09:
  DEFB $97,$0A            ; SPRITESET 10
  DEFB $97,$13            ; SPRITESET 19
  DEFB $87,$09            ; ROOMNAME 9 "Hangman tree"
  DEFB $83                ; CALL ScriptRoomPanel
  DEFW ScriptRoomPanel
  DEFB $88,$05,$02,$82,$A4,$A5,$80,$85 ; BLOCK 5x2: $82 $A4 $A5 $80 $85 $84 $A4
                                       ; $A5 $80 $83
  DEFB $84,$A4,$A5,$80,$83
  DEFB $89,$04,$0D,$05,$10 ; TILEBLOCK row 4, col 13, 5x16
  DEFB $88,$03,$02,$07,$08,$14,$0A,$09 ; BLOCK 3x2: $07 $08 $14 $0A $09 $15
  DEFB $15
  DEFB $99,$02,$00,$00,$03,$0E,$12,$00 ; TILEBLOCKS 2 rectangles
  DEFB $03,$02
  DEFB $83                ; CALL BlockGrassEarth
  DEFW BlockGrassEarth
  DEFB $99,$02,$0C,$1A,$04,$02,$14,$00 ; TILEBLOCKS 2 rectangles
  DEFB $20,$02
  DEFB $88,$02,$01,$01,$02 ; BLOCK 2x1: $01 $02
  DEFB $89,$00,$1E,$02,$16 ; TILEBLOCK row 0, col 30, 2x22
  DEFB $98,$1C,$02,$06,$07,$06,$01,$08 ; RECTS tile $1C, 2 rectangles
  DEFB $0A,$03,$01
  DEFB $98,$1E,$02,$07,$12,$05,$01,$0A ; RECTS tile $1E, 2 rectangles
  DEFB $12,$02,$01
  DEFB $86,$00,$03,$19,$04,$8A ; FILLTILE row 0, col 3, 25x4, tile $8A
  DEFB $86,$04,$0F,$03,$01,$80 ; FILLTILE row 4, col 15, 3x1, tile $80
  DEFB $93,$13,$02,$02,$0A,$14 ; ROW row 19, col 2, 2 tiles
  DEFB $92,$10,$03,$09,$1A,$0F,$18,$11 ; STAMP1 tile $10 at 3 positions
  DEFB $19
  DEFB $92,$1D,$02,$06,$06,$08,$09 ; STAMP1 tile $1D at 2 positions
  DEFB $92,$1F,$02,$07,$17,$0A,$14 ; STAMP1 tile $1F at 2 positions
  DEFB $92,$81,$05,$0B,$1C,$13,$05,$13 ; STAMP1 tile $81 at 5 positions
  DEFB $09,$13,$14,$13,$15
  DEFB $92,$86,$02,$06,$0D,$08,$0D ; STAMP1 tile $86 at 2 positions
  DEFB $92,$87,$02,$07,$11,$0A,$11 ; STAMP1 tile $87 at 2 positions
  DEFB $92,$A7,$02,$0C,$0E,$0C,$10 ; STAMP1 tile $A7 at 2 positions
  DEFB $9B,$A6,$02,$0E,$1B,$04,$0E,$1C ; RUNS_V tile $A6, 2 vertical runs
  DEFB $02
  DEFB $8C,$0E,$0E,$A5    ; TILE1 row 14, col 14, tile $A5
  DEFB $8C,$0A,$0D,$8B    ; TILE1 row 10, col 13, tile $8B
  DEFB $8C,$0E,$0F,$80    ; TILE1 row 14, col 15, tile $80
  DEFB $8C,$10,$11,$99    ; TILE1 row 16, col 17, tile $99
  DEFB $94,$00,$00,$89,$14,$11,$0C,$1C,$FF,$10,$1C,$08,$FC,$1D,$3E,$3F ; BITMAP row
                                                                       ; 0, col 0,
                                                                       ; tile $89,
                                                                       ; 20 bytes
  DEFB $FC,$FB,$1C,$F0,$1F,$3C,$18,$0E,$0C
  DEFB $80                ; END

; Room script 10: Pestilent Beast
;
; Op $96 turns some cells into free space (flag $80), so that parts of the cave
; that look solid can be walked through.
;
; Room 10: column 0, row 2 of the 5x5 map (left is room 9, right 11, up 5, down
; 15, counted modulo 25). Unpacks sprite sets PackedSet5, PackedSet6.
; Subscripts: ScriptRoomPanel, BlockCaveRock, BlockCaveGrass. Items (RoomItems)
; at row,column: lever 4,7, doorway arch 17,23, heart 18,10, cross 4,26.
RoomScript10:
  DEFB $97,$05            ; SPRITESET 5
  DEFB $97,$06            ; SPRITESET 6
  DEFB $87,$0A            ; ROOMNAME 10 "Pestilent Beast"
  DEFB $83                ; CALL ScriptRoomPanel
  DEFW ScriptRoomPanel
  DEFB $83                ; CALL BlockCaveRock
  DEFW BlockCaveRock
  DEFB $99,$0A,$00,$00,$20,$01,$01,$00,$02,$15,$06,$02,$02,$04,$06,$06 ; TILEBLOCKS
                                                                       ; 10
                                                                       ; rectangles
  DEFB $0A,$01,$06,$12,$0A,$01,$00,$0A,$04,$06,$00,$1C,$04,$08,$0E,$06
  DEFB $1A,$02,$10,$0C,$04,$06,$10,$1A,$06,$06
  DEFB $83                ; CALL BlockCaveGrass
  DEFW BlockCaveGrass
  DEFB $99,$04,$0C,$06,$1A,$02,$14,$02,$04,$02,$14,$0A,$02,$02,$14,$14 ; TILEBLOCKS
                                                                       ; 4
                                                                       ; rectangles
  DEFB $06,$02
  DEFB $86,$14,$14,$06,$01,$03 ; FILLTILE row 20, col 20, 6x1, tile $03
  DEFB $9B,$A6,$06,$01,$05,$02,$01,$06,$03,$08,$1D,$02,$08,$1E,$04,$10 ; RUNS_V
                                                                       ; tile $A6,
                                                                       ; 6 vertical
                                                                       ; runs
  DEFB $10,$01,$10,$11,$03
  DEFB $92,$81,$06,$0B,$08,$0B,$0D,$0B ; STAMP1 tile $81 at 6 positions
  DEFB $18,$0B,$1A,$0B,$1B,$13,$02
  DEFB $92,$24,$08,$00,$1D,$03,$0D,$04,$1F,$05,$0A,$08,$00,$0D,$0B,$0E ; STAMP1
                                                                       ; tile $24
                                                                       ; at 8
                                                                       ; positions
  DEFB $1D,$0F,$1E
  DEFB $92,$25,$10,$01,$02,$01,$09,$01,$0E,$01,$1B,$07,$09,$07,$0A,$07 ; STAMP1
                                                                       ; tile $25
                                                                       ; at 16
                                                                       ; positions
  DEFB $0C,$07,$16,$07,$18,$07,$19,$07,$1B,$0A,$02,$10,$07,$10,$0A,$10
  DEFB $0B,$10,$13
  DEFB $92,$26,$05,$08,$04,$0E,$05,$10 ; STAMP1 tile $26 at 5 positions
  DEFB $02,$15,$06,$15,$10
  DEFB $91,$4D,$05,$01,$01,$01,$12 ; PICTURES tiles from $4D, 5x1, at 1
                                   ; positions
  DEFB $8C,$01,$18,$52    ; TILE1 row 1, col 24, tile $52
  DEFB $8C,$01,$19,$53    ; TILE1 row 1, col 25, tile $53
  DEFB $91,$54,$08,$02,$01,$02,$12 ; PICTURES tiles from $54, 8x2, at 1
                                   ; positions
  DEFB $91,$64,$07,$01,$01,$04,$13 ; PICTURES tiles from $64, 7x1, at 1
                                   ; positions
  DEFB $91,$6B,$02,$01,$01,$05,$0E ; PICTURES tiles from $6B, 2x1, at 1
                                   ; positions
  DEFB $91,$6D,$08,$01,$01,$05,$12 ; PICTURES tiles from $6D, 8x1, at 1
                                   ; positions
  DEFB $96,$05,$1C,$04,$01,$80 ; FLAGS row 5, col 28, 4x1, flags $80
  DEFB $80                ; END

; Block pattern: cave rock (tiles $20-$23)
;
; Defines the current block as 2x2 tiles of cyan rock, the walls of the cave
; rooms. Called by rooms 10, 11, 14, 15, 16, 19, 20.
BlockCaveRock:
  DEFB $88,$02,$02,$20,$21,$22,$23 ; BLOCK 2x2: $20 $21 $22 $23
  DEFB $80                ; END

; Room script 11: Cave of illusions
;
; Two op $96 areas are turned into free space (flag $80): false walls, as the
; room name says (Cave of illusions).
;
; Room 11: column 1, row 2 of the 5x5 map (left is room 10, right 12, up 6,
; down 16, counted modulo 25). Unpacks sprite set PackedSet12. Subscripts:
; ScriptRoomPanel, BlockCaveRock, BlockCaveGrass. Items (RoomItems) at
; row,column: heart 4,2, checkpoint 17,14.
RoomScript11:
  DEFB $97,$0C            ; SPRITESET 12
  DEFB $87,$0B            ; ROOMNAME 11 "Cave of illusions"
  DEFB $83                ; CALL ScriptRoomPanel
  DEFW ScriptRoomPanel
  DEFB $83                ; CALL BlockCaveRock
  DEFW BlockCaveRock
  DEFB $89,$00,$00,$20,$16 ; TILEBLOCK row 0, col 0, 32x22
  DEFB $98,$80,$05,$01,$02,$1E,$03,$01,$02,$1C,$11,$01,$02,$10,$13,$08 ; RECTS tile
                                                                       ; $80, 5
                                                                       ; rectangles
  DEFB $00,$02,$04,$01,$18,$04,$15
  DEFB $8B,$02,$20,$21,$0A,$06,$02,$06,$08,$06,$0C,$06,$0E,$06,$1A,$06 ; STAMPS 2
                                                                       ; tiles $20
                                                                       ; $21 at 10
                                                                       ; positions
  DEFB $1C,$08,$14,$08,$16,$0A,$0A,$0F,$0C
  DEFB $8B,$02,$22,$23,$02,$0C,$10,$0C ; STAMPS 2 tiles $22 $23 at 2 positions
  DEFB $18
  DEFB $83                ; CALL BlockCaveGrass
  DEFW BlockCaveGrass
  DEFB $99,$05,$0C,$00,$04,$02,$10,$12,$06,$02,$10,$1C,$02,$02,$12,$08 ; TILEBLOCKS
                                                                       ; 5
                                                                       ; rectangles
  DEFB $04,$02,$14,$0C,$06,$02
  DEFB $92,$24,$07,$02,$00,$0A,$1F,$11,$00,$12,$1F,$13,$1E,$14,$0A,$15 ; STAMP1
                                                                       ; tile $24
                                                                       ; at 7
                                                                       ; positions
  DEFB $15
  DEFB $92,$25,$0A,$01,$02,$01,$06,$01,$0A,$01,$0B,$01,$12,$01,$18,$01 ; STAMP1
                                                                       ; tile $25
                                                                       ; at 10
                                                                       ; positions
  DEFB $1A,$07,$0E,$07,$1D,$09,$16
  DEFB $92,$26,$02,$12,$1B,$15,$18 ; STAMP1 tile $26 at 2 positions
  DEFB $92,$81,$06,$0B,$01,$0F,$15,$0F ; STAMP1 tile $81 at 6 positions
  DEFB $1D,$11,$09,$13,$0D,$13,$10
  DEFB $9B,$A6,$06,$01,$04,$03,$01,$05,$02,$01,$0E,$02,$01,$14,$03,$01 ; RUNS_V
                                                                       ; tile $A6,
                                                                       ; 6 vertical
                                                                       ; runs
  DEFB $15,$05,$01,$1C,$02
  DEFB $86,$14,$02,$06,$01,$05 ; FILLTILE row 20, col 2, 6x1, tile $05
  DEFB $96,$05,$00,$02,$01,$80 ; FLAGS row 5, col 0, 2x1, flags $80
  DEFB $96,$14,$02,$02,$02,$80 ; FLAGS row 20, col 2, 2x2, flags $80
  DEFB $91,$7E,$02,$01,$01,$13,$0E ; PICTURES tiles from $7E, 2x1, at 1
                                   ; positions
  DEFB $80                ; END

; Block pattern: grass on cave rock (tiles $03,$04,$22,$23)
;
; Defines the current block as grass tiles over cyan rock. Called by rooms 10,
; 11, 14, 16.
BlockCaveGrass:
  DEFB $88,$02,$02,$03,$04,$22,$23 ; BLOCK 2x2: $03 $04 $22 $23
  DEFB $80                ; END

; Room script 12: Plagued ruins
;
; Room 12: column 2, row 2 of the 5x5 map (left is room 11, right 13, up 7,
; down 17, counted modulo 25). Unpacks sprite sets PackedSet8, PackedSet9.
; Subscripts: ScriptRoomPanel, BlockYellowBricks. Items (RoomItems) at
; row,column: heart 6,16, parchment 18,10, checkpoint 7,8.
RoomScript12:
  DEFB $97,$08            ; SPRITESET 8
  DEFB $97,$09            ; SPRITESET 9
  DEFB $87,$0C            ; ROOMNAME 12 "Plagued ruins"
  DEFB $83                ; CALL ScriptRoomPanel
  DEFW ScriptRoomPanel
  DEFB $83                ; CALL BlockYellowBricks
  DEFW BlockYellowBricks
  DEFB $99,$09,$04,$00,$02,$12,$04,$00,$06,$01,$04,$08,$06,$01,$08,$10 ; TILEBLOCKS
                                                                       ; 9
                                                                       ; rectangles
  DEFB $02,$01,$10,$00,$04,$04,$0A,$06,$1A,$04,$14,$00,$1A,$02,$00,$1E
  DEFB $02,$06,$0A,$1E,$02,$0C
  DEFB $88,$02,$01,$29,$28 ; BLOCK 2x1: $29 $28
  DEFB $89,$00,$02,$1C,$01 ; TILEBLOCK row 0, col 2, 28x1
  DEFB $98,$80,$03,$0A,$0C,$10,$02,$0C ; RECTS tile $80, 3 rectangles
  DEFB $14,$04,$02,$11,$1E,$02,$03
  DEFB $92,$26,$03,$0C,$03,$0E,$02,$15 ; STAMP1 tile $26 at 3 positions
  DEFB $1D
  DEFB $92,$27,$05,$00,$01,$00,$06,$00 ; STAMP1 tile $27 at 5 positions
  DEFB $12,$00,$14,$00,$18
  DEFB $92,$2B,$0D,$00,$00,$07,$01,$0B,$00,$0B,$1E,$0C,$10,$0C,$1F,$0D ; STAMP1
                                                                       ; tile $2B
                                                                       ; at 13
                                                                       ; positions
  DEFB $0D,$0D,$1A,$13,$02,$14,$06,$14,$16,$15,$13,$15,$14
  DEFB $91,$AA,$02,$03,$01,$11,$00 ; PICTURES tiles from $AA, 2x3, at 1
                                   ; positions
  DEFB $8C,$0B,$08,$49    ; TILE1 row 11, col 8, tile $49
  DEFB $8C,$0B,$09,$4A    ; TILE1 row 11, col 9, tile $4A
  DEFB $91,$7E,$02,$01,$01,$09,$08 ; PICTURES tiles from $7E, 2x1, at 1
                                   ; positions
  DEFB $80                ; END

; Block pattern: yellow bricks (tiles $27-$2A)
;
; Defines the current block as 2x2 tiles of yellow brick, the walls of the
; ruins and catacombs. Called by rooms 12, 13, 17.
BlockYellowBricks:
  DEFB $88,$02,$02,$27,$28,$29,$2A ; BLOCK 2x2: $27 $28 $29 $2A
  DEFB $80                ; END

; Room script 13: Catacombs
;
; Room 13: column 3, row 2 of the 5x5 map (left is room 12, right 14, up 8,
; down 18, counted modulo 25). Unpacks sprite set PackedSet17. Subscripts:
; ScriptRoomPanel, BlockYellowBricks. Items (RoomItems) at row,column: cross
; 18,18.
RoomScript13:
  DEFB $97,$11            ; SPRITESET 17
  DEFB $87,$0D            ; ROOMNAME 13 "Catacombs"
  DEFB $83                ; CALL ScriptRoomPanel
  DEFW ScriptRoomPanel
  DEFB $83                ; CALL BlockYellowBricks
  DEFW BlockYellowBricks
  DEFB $89,$00,$00,$20,$16 ; TILEBLOCK row 0, col 0, 32x22
  DEFB $98,$80,$07,$00,$1A,$02,$06,$06,$00,$1E,$04,$11,$00,$14,$03,$06 ; RECTS tile
                                                                       ; $80, 7
                                                                       ; rectangles
  DEFB $06,$04,$0E,$06,$06,$18,$08,$08,$1E,$02,$04,$0F,$06,$0E,$05
  DEFB $93,$01,$04,$04,$80,$4A,$49,$80 ; ROW row 1, col 4, 4 tiles
  DEFB $93,$01,$0C,$03,$80,$4B,$80 ; ROW row 1, col 12, 3 tiles
  DEFB $93,$03,$0A,$03,$80,$49,$80 ; ROW row 3, col 10, 3 tiles
  DEFB $92,$26,$08,$02,$1A,$05,$1B,$08,$1A,$0B,$1B,$0C,$06,$0E,$07,$10 ; STAMP1
                                                                       ; tile $26
                                                                       ; at 8
                                                                       ; positions
  DEFB $06,$12,$07
  DEFB $92,$2B,$0B,$00,$14,$00,$15,$01,$08,$02,$1E,$03,$0D,$0E,$03,$10 ; STAMP1
                                                                       ; tile $2B
                                                                       ; at 11
                                                                       ; positions
  DEFB $02,$12,$14,$14,$09,$15,$0E,$15,$1B
  DEFB $91,$AA,$02,$03,$04,$10,$16,$10 ; PICTURES tiles from $AA, 2x3, at 4
                                       ; positions
  DEFB $18,$10,$1A,$10,$1C
  DEFB $80                ; END

; Room script 14: Hidden garden
;
; Room 14: column 4, row 2 of the 5x5 map (left is room 13, right 15, up 9,
; down 19, counted modulo 25). Unpacks sprite set PackedSet19. Subscripts:
; ScriptRoomPanel, BlockCaveRock, BlockCaveGrass. Items (RoomItems) at
; row,column: parchment 10,19, cross 4,9, checkpoint 17,8.
RoomScript14:
  DEFB $97,$13            ; SPRITESET 19
  DEFB $87,$0E            ; ROOMNAME 14 "Hidden garden"
  DEFB $83                ; CALL ScriptRoomPanel
  DEFW ScriptRoomPanel
  DEFB $83                ; CALL BlockCaveRock
  DEFW BlockCaveRock
  DEFB $99,$09,$00,$00,$02,$08,$00,$1E,$02,$16,$0E,$00,$06,$08,$06,$08 ; TILEBLOCKS
                                                                       ; 9
                                                                       ; rectangles
  DEFB $04,$01,$06,$0E,$0A,$01,$08,$1B,$03,$01,$0C,$12,$04,$01,$0C,$18
  DEFB $04,$01,$10,$0E,$04,$01
  DEFB $83                ; CALL BlockCaveGrass
  DEFW BlockCaveGrass
  DEFB $99,$03,$0C,$00,$06,$02,$14,$06 ; TILEBLOCKS 3 rectangles
  DEFB $12,$02,$14,$1C,$02,$02
  DEFB $88,$02,$01,$22,$23 ; BLOCK 2x1: $22 $23
  DEFB $89,$00,$02,$1C,$01 ; TILEBLOCK row 0, col 2, 28x1
  DEFB $9B,$A6,$06,$01,$03,$06,$01,$04,$03,$01,$19,$02,$01,$1A,$05,$07 ; RUNS_V
                                                                       ; tile $A6,
                                                                       ; 6 vertical
                                                                       ; runs
  DEFB $0F,$02,$07,$10,$03
  DEFB $92,$24,$06,$0F,$1F,$13,$01,$11 ; STAMP1 tile $24 at 6 positions
  DEFB $05,$0F,$03,$03,$1F,$04,$01
  DEFB $92,$25,$0A,$01,$05,$01,$07,$01,$11,$01,$15,$01,$1B,$01,$1D,$07 ; STAMP1
                                                                       ; tile $25
                                                                       ; at 10
                                                                       ; positions
  DEFB $0A,$07,$14,$0D,$1A,$11,$10
  DEFB $92,$81,$05,$0B,$03,$13,$07,$13 ; STAMP1 tile $81 at 5 positions
  DEFB $0A,$13,$14,$13,$1C
  DEFB $8C,$15,$18,$10    ; TILE1 row 21, col 24, tile $10
  DEFB $91,$7E,$02,$01,$01,$13,$08 ; PICTURES tiles from $7E, 2x1, at 1
                                   ; positions
  DEFB $80                ; END

; Room script 15: Gloomy tunels
;
; Room 15: column 0, row 3 of the 5x5 map (left is room 14, right 16, up 10,
; down 20, counted modulo 25). Unpacks sprite set PackedSet11. Subscripts:
; ScriptRoomPanel, BlockCaveRock. Items (RoomItems) at row,column: heart 14,3,
; cross 8,28, checkpoint 7,21.
RoomScript15:
  DEFB $97,$0B            ; SPRITESET 11
  DEFB $87,$0F            ; ROOMNAME 15 "Gloomy tunels"
  DEFB $83                ; CALL ScriptRoomPanel
  DEFW ScriptRoomPanel
  DEFB $83                ; CALL BlockCaveRock
  DEFW BlockCaveRock
  DEFB $89,$00,$00,$20,$16 ; TILEBLOCK row 0, col 0, 32x22
  DEFB $98,$80,$07,$00,$06,$04,$16,$00,$10,$04,$14,$04,$06,$18,$06,$0B ; RECTS tile
                                                                       ; $80, 7
                                                                       ; rectangles
  DEFB $02,$1C,$05,$0C,$1E,$02,$04,$0B,$0E,$10,$09,$0A,$18,$04,$01
  DEFB $98,$2C,$06,$01,$00,$06,$02,$01,$14,$0C,$02,$07,$00,$06,$02,$12 ; RECTS tile
                                                                       ; $2C, 6
                                                                       ; rectangles
  DEFB $00,$06,$02,$12,$0A,$05,$01,$13,$0A,$06,$01
  DEFB $89,$0E,$18,$02,$01 ; TILEBLOCK row 14, col 24, 2x1
  DEFB $91,$17,$02,$02,$01,$12,$1A ; PICTURES tiles from $17, 2x2, at 1
                                   ; positions
  DEFB $92,$24,$09,$03,$02,$03,$0D,$04,$01,$07,$1E,$0B,$01,$10,$03,$10 ; STAMP1
                                                                       ; tile $24
                                                                       ; at 9
                                                                       ; positions
  DEFB $1F,$14,$17,$15,$13
  DEFB $92,$25,$08,$04,$0D,$04,$0E,$04,$15,$04,$17,$04,$1D,$0B,$02,$0B ; STAMP1
                                                                       ; tile $25
                                                                       ; at 8
                                                                       ; positions
  DEFB $0E,$0B,$16
  DEFB $92,$26,$07,$02,$06,$02,$10,$04,$11,$06,$06,$06,$12,$11,$06,$15 ; STAMP1
                                                                       ; tile $26
                                                                       ; at 7
                                                                       ; positions
  DEFB $06
  DEFB $8C,$15,$12,$49    ; TILE1 row 21, col 18, tile $49
  DEFB $8C,$15,$11,$4A    ; TILE1 row 21, col 17, tile $4A
  DEFB $8C,$05,$1F,$4B    ; TILE1 row 5, col 31, tile $4B
  DEFB $91,$7E,$02,$01,$01,$09,$15 ; PICTURES tiles from $7E, 2x1, at 1
                                   ; positions
  DEFB $80                ; END

; Room script 16: Lake of despair
;
; Op $96 turns an area into free space (flag $80). Op $9D makes the bottom row
; of the room a water strip (DrawWaterReflection, the lake of blood reflecting
; the scenery, harmful): row 21, from column 6, 16 cells wide, attribute $13
; (DrawWaterReflection).
;
; Room 16: column 1, row 3 of the 5x5 map (left is room 15, right 17, up 11,
; down 21, counted modulo 25). Subscripts: ScriptRoomPanel, BlockCaveRock,
; BlockCaveGrass. Items (RoomItems) at row,column: parchment 5,22, cross 6,2.
RoomScript16:
  DEFB $87,$10            ; ROOMNAME 16 "Lake of despair"
  DEFB $83                ; CALL ScriptRoomPanel
  DEFW ScriptRoomPanel
  DEFB $83                ; CALL BlockCaveRock
  DEFW BlockCaveRock
  DEFB $99,$0A,$00,$00,$06,$16,$00,$00,$18,$01,$11,$1E,$02,$02,$00,$1E ; TILEBLOCKS
                                                                       ; 10
                                                                       ; rectangles
  DEFB $02,$12,$00,$1C,$02,$01,$0A,$1C,$02,$01,$03,$1A,$02,$01,$07,$10
  DEFB $02,$01,$07,$14,$06,$01,$0E,$1A,$02,$01
  DEFB $98,$80,$02,$04,$02,$04,$04,$0C ; RECTS tile $80, 2 rectangles
  DEFB $00,$06,$04
  DEFB $83                ; CALL BlockCaveGrass
  DEFW BlockCaveGrass
  DEFB $99,$03,$08,$02,$04,$02,$10,$00 ; TILEBLOCKS 3 rectangles
  DEFB $06,$02,$14,$16,$0A,$02
  DEFB $92,$B1,$14,$11,$0A,$11,$0B,$12,$09,$12,$0B,$12,$0C,$12,$12,$12 ; STAMP1
                                                                       ; tile $B1
                                                                       ; at 20
                                                                       ; positions
  DEFB $13,$13,$08,$13,$09,$13,$11,$13,$12,$13,$13,$14,$07,$14,$09,$14
  DEFB $0A,$14,$0C,$14,$0D,$14,$0E,$14,$14,$14,$15
  DEFB $92,$49,$03,$12,$18,$12,$1A,$13 ; STAMP1 tile $49 at 3 positions
  DEFB $0B
  DEFB $92,$4B,$0A,$12,$19,$13,$0A,$13,$0C,$13,$0D,$13,$17,$13,$18,$13 ; STAMP1
                                                                       ; tile $4B
                                                                       ; at 10
                                                                       ; positions
  DEFB $19,$13,$1B,$14,$11,$14,$12
  DEFB $92,$24,$05,$00,$03,$13,$05,$04 ; STAMP1 tile $24 at 5 positions
  DEFB $1F,$09,$1E,$15,$1C
  DEFB $92,$25,$05,$01,$06,$01,$1D,$08 ; STAMP1 tile $25 at 5 positions
  DEFB $18,$0B,$1D,$0C,$01
  DEFB $9B,$A6,$03,$01,$0B,$07,$01,$0D ; RUNS_V tile $A6, 3 vertical runs
  DEFB $03,$01,$14,$03
  DEFB $8C,$12,$06,$26    ; TILE1 row 18, col 6, tile $26
  DEFB $8C,$13,$1A,$4A    ; TILE1 row 19, col 26, tile $4A
  DEFB $96,$00,$02,$02,$04,$80 ; FLAGS row 0, col 2, 2x4, flags $80
  DEFB $9D,$15,$06,$13,$10 ; WATER strip: row 21, col 6, attribute $13, 16
                           ; cells
  DEFB $80                ; END

; Room script 17: The wheel of faith
;
; Room 17: column 2, row 3 of the 5x5 map (left is room 16, right 18, up 12,
; down 22, counted modulo 25). Unpacks sprite set PackedSet0. Subscripts:
; ScriptRoomPanel, BlockYellowBricks. Items (RoomItems) at row,column: wheel of
; faith 2,15, heart 18,3, cross 18,28, cross 10,3.
RoomScript17:
  DEFB $97,$00            ; SPRITESET 0
  DEFB $87,$11            ; ROOMNAME 17 "The wheel of faith"
  DEFB $83                ; CALL ScriptRoomPanel
  DEFW ScriptRoomPanel
  DEFB $83                ; CALL BlockYellowBricks
  DEFW BlockYellowBricks
  DEFB $99,$11,$00,$00,$02,$13,$00,$1E,$02,$16,$14,$00,$1E,$02,$00,$02 ; TILEBLOCKS
                                                                       ; 17
                                                                       ; rectangles
  DEFB $18,$01,$12,$0D,$06,$02,$13,$0C,$01,$01,$13,$13,$01,$01,$00,$0F
  DEFB $02,$01,$06,$04,$02,$01,$06,$0A,$02,$01,$06,$14,$02,$01,$06,$1A
  DEFB $04,$01,$09,$0E,$02,$01,$0C,$04,$02,$01,$0C,$08,$04,$01,$0C,$14
  DEFB $04,$01,$0C,$1C,$02,$01
  DEFB $91,$2E,$04,$02,$03,$10,$0E,$12 ; PICTURES tiles from $2E, 4x2, at 3
                                       ; positions
  DEFB $06,$12,$16
  DEFB $8B,$02,$29,$2A,$08,$00,$06,$00,$16,$06,$02,$06,$08,$06,$16,$09 ; STAMPS 2
                                                                       ; tiles $29
                                                                       ; $2A at 8
                                                                       ; positions
  DEFB $10,$0C,$02,$0C,$1A
  DEFB $92,$2B,$08,$03,$01,$00,$0E,$0A,$1F,$11,$1E,$12,$00,$14,$1C,$15 ; STAMP1
                                                                       ; tile $2B
                                                                       ; at 8
                                                                       ; positions
  DEFB $03,$15,$17
  DEFB $92,$49,$02,$03,$1F,$14,$12 ; STAMP1 tile $49 at 2 positions
  DEFB $92,$4A,$02,$09,$00,$15,$0C ; STAMP1 tile $4A at 2 positions
  DEFB $8C,$03,$1D,$26    ; TILE1 row 3, col 29, tile $26
  DEFB $80                ; END

; Room script 18: Banquet of Death
;
; Room 18: column 3, row 3 of the 5x5 map (left is room 17, right 19, up 13,
; down 23, counted modulo 25). Unpacks sprite sets PackedSet2, PackedSet16.
; Subscripts: ScriptRoomPanel. Items (RoomItems) at row,column: heart 11,15,
; cross 5,3.
RoomScript18:
  DEFB $97,$02            ; SPRITESET 2
  DEFB $97,$10            ; SPRITESET 16
  DEFB $87,$12            ; ROOMNAME 18 "Banquet of Death"
  DEFB $83                ; CALL ScriptRoomPanel
  DEFW ScriptRoomPanel
  DEFB $86,$15,$0A,$10,$01,$05 ; FILLTILE row 21, col 10, 16x1, tile $05
  DEFB $88,$02,$02,$4B,$37,$36,$38 ; BLOCK 2x2: $4B $37 $36 $38
  DEFB $99,$06,$00,$00,$02,$16,$00,$1E,$02,$10,$14,$00,$0A,$02,$14,$0C ; TILEBLOCKS
                                                                       ; 6
                                                                       ; rectangles
  DEFB $02,$02,$14,$14,$02,$02,$14,$1A,$06,$02
  DEFB $86,$00,$02,$1C,$01,$4B ; FILLTILE row 0, col 2, 28x1, tile $4B
  DEFB $98,$B1,$0A,$11,$13,$02,$01,$12,$05,$03,$01,$12,$12,$02,$01,$12 ; RECTS tile
                                                                       ; $B1, 10
                                                                       ; rectangles
  DEFB $1B,$02,$01,$13,$04,$03,$01,$13,$0F,$02,$01,$13,$12,$04,$01,$13
  DEFB $1C,$03,$01,$14,$0E,$03,$01,$14,$12,$02,$01
  DEFB $92,$B1,$06,$13,$08,$13,$0C,$12 ; STAMP1 tile $B1 at 6 positions
  DEFB $15,$13,$1A,$14,$0B,$14,$16
  DEFB $92,$4A,$09,$02,$1E,$04,$01,$09,$00,$0B,$1E,$0C,$01,$12,$00,$15 ; STAMP1
                                                                       ; tile $4A
                                                                       ; at 9
                                                                       ; positions
  DEFB $00,$15,$06,$15,$1C
  DEFB $8B,$02,$4B,$4B,$06,$07,$04,$0C,$09,$0D,$0F,$0D,$15,$0F,$06,$11 ; STAMPS 2
                                                                       ; tiles $4B
                                                                       ; $4B at 6
                                                                       ; positions
  DEFB $02
  DEFB $92,$4B,$0D,$03,$00,$01,$1F,$06,$09,$07,$02,$07,$0C,$07,$11,$07 ; STAMP1
                                                                       ; tile $4B
                                                                       ; at 13
                                                                       ; positions
  DEFB $16,$0B,$1D,$0C,$0C,$0D,$00,$0E,$1B,$14,$11,$14,$18
  DEFB $92,$36,$08,$00,$03,$00,$06,$00,$0C,$00,$0F,$00,$11,$00,$16,$00 ; STAMP1
                                                                       ; tile $36
                                                                       ; at 8
                                                                       ; positions
  DEFB $1A,$00,$1B
  DEFB $92,$49,$08,$07,$03,$07,$0D,$07,$15,$08,$1B,$0C,$0B,$0D,$14,$0E ; STAMP1
                                                                       ; tile $49
                                                                       ; at 8
                                                                       ; positions
  DEFB $1A,$14,$1F
  DEFB $80                ; END

; Room script 19: Underground river
;
; The door DoorLeftLow is drawn at the left edge, at row 16, while the lever of
; room 9 (LeverRoom9) is 0. Op $9D makes the river a water strip reflecting the
; scenery (harmful): row 21, from column 14, 16 cells wide, attribute $0D (blue
; and cyan, DrawWaterReflection).
;
; Room 19: column 4, row 3 of the 5x5 map (left is room 18, right 20, up 14,
; down 24, counted modulo 25). Subscripts: ScriptRoomPanel, BlockCaveRock.
; Items (RoomItems) at row,column: doorway arch 15,21, heart 8,25, cross 2,3,
; checkpoint 11,8.
RoomScript19:
  DEFB $87,$13            ; ROOMNAME 19 "Underground river"
  DEFB $83                ; CALL ScriptRoomPanel
  DEFW ScriptRoomPanel
  DEFB $83                ; CALL BlockCaveRock
  DEFW BlockCaveRock
  DEFB $99,$13,$00,$00,$02,$10,$14,$00,$0E,$02,$04,$02,$04,$01,$06,$06 ; TILEBLOCKS
                                                                       ; 19
                                                                       ; rectangles
  DEFB $02,$01,$08,$08,$02,$01,$0E,$06,$06,$08,$10,$05,$01,$01,$12,$0C
  DEFB $02,$02,$00,$1C,$02,$01,$06,$1C,$02,$01,$0E,$1C,$02,$01,$00,$1E
  DEFB $02,$16,$02,$1A,$02,$01,$04,$18,$02,$01,$0A,$18,$04,$01,$12,$1A
  DEFB $02,$01,$12,$14,$04,$01,$06,$12,$04,$01,$08,$0E,$04,$01
  DEFB $88,$02,$01,$22,$23 ; BLOCK 2x1: $22 $23
  DEFB $89,$00,$02,$16,$01 ; TILEBLOCK row 0, col 2, 22x1
  DEFB $9B,$A6,$05,$01,$0B,$02,$01,$0C,$04,$01,$0E,$02,$07,$13,$02,$07 ; RUNS_V
                                                                       ; tile $A6,
                                                                       ; 5 vertical
                                                                       ; runs
  DEFB $14,$04
  DEFB $92,$25,$07,$01,$09,$01,$14,$01,$1D,$05,$02,$07,$1D,$09,$10,$13 ; STAMP1
                                                                       ; tile $25
                                                                       ; at 7
                                                                       ; positions
  DEFB $16
  DEFB $92,$24,$06,$02,$01,$0B,$01,$0B ; STAMP1 tile $24 at 6 positions
  DEFB $1F,$0F,$0B,$13,$07,$13,$1F
  DEFB $92,$49,$03,$03,$1F,$11,$06,$15 ; STAMP1 tile $49 at 3 positions
  DEFB $09
  DEFB $8C,$13,$11,$4B    ; TILE1 row 19, col 17, tile $4B
  DEFB $8C,$15,$0A,$4A    ; TILE1 row 21, col 10, tile $4A
  DEFB $95                ; IFZERO run DoorLeftLow if LeverRoom9 is 0
  DEFW DoorLeftLow
  DEFW LeverRoom9
  DEFB $9D,$15,$0E,$0D,$10 ; WATER strip: row 21, col 14, attribute $0D, 16
                           ; cells
  DEFB $91,$7E,$02,$01,$01,$0D,$08 ; PICTURES tiles from $7E, 2x1, at 1
                                   ; positions
  DEFB $80                ; END

; Picture: the door at the left edge of room 19, rows 16-19
;
; Draws a 1x4 picture of the door (tiles $BC-$BF) at row 16, column 0. Run by
; room 19 (op $95) while LeverRoom9, the lever of room 9, is 0.
DoorLeftLow:
  DEFB $91,$BC,$01,$04,$01,$10,$00 ; PICTURES tiles from $BC, 1x4, at 1
                                   ; positions
  DEFB $80                ; END

; Room script 20: Unexpected gate
;
; The door DoorRight is drawn at the right edge while the lever of this room
; (LeverRoom20) is 0; pulling it runs EraseDoorRight, which erases the door.
;
; Room 20: column 0, row 4 of the 5x5 map (left is room 19, right 21, up 15,
; down 0, counted modulo 25). Unpacks sprite sets PackedSet11, PackedSet4.
; Subscripts: ScriptRoomPanel, BlockCaveRock. Items (RoomItems) at row,column:
; lever 6,24.
RoomScript20:
  DEFB $97,$0B            ; SPRITESET 11
  DEFB $97,$04            ; SPRITESET 4
  DEFB $87,$14            ; ROOMNAME 20 "Unexpected gate"
  DEFB $83                ; CALL ScriptRoomPanel
  DEFW ScriptRoomPanel
  DEFB $88,$04,$02,$3D,$3E,$3F,$47,$42 ; BLOCK 4x2: $3D $3E $3F $47 $42 $41 $40
                                       ; $48
  DEFB $41,$40,$48
  DEFB $99,$04,$08,$17,$04,$02,$00,$1D,$03,$0E,$12,$1D,$03,$02,$13,$1C ; TILEBLOCKS
                                                                       ; 4
                                                                       ; rectangles
  DEFB $02,$01
  DEFB $83                ; CALL BlockCaveRock
  DEFW BlockCaveRock
  DEFB $99,$0B,$00,$00,$02,$16,$00,$00,$06,$01,$00,$0A,$16,$01,$14,$02 ; TILEBLOCKS
                                                                       ; 11
                                                                       ; rectangles
  DEFB $10,$02,$14,$1C,$04,$02,$02,$06,$02,$01,$06,$0A,$02,$01,$09,$06
  DEFB $04,$01,$0C,$02,$02,$01,$10,$06,$02,$02,$12,$06,$04,$02
  DEFB $86,$14,$12,$0A,$01,$13 ; FILLTILE row 20, col 18, 10x1, tile $13
  DEFB $86,$08,$0F,$06,$01,$00 ; FILLTILE row 8, col 15, 6x1, tile $00
  DEFB $86,$11,$03,$03,$02,$B1 ; FILLTILE row 17, col 3, 3x2, tile $B1
  DEFB $92,$B1,$03,$10,$03,$12,$0C,$10 ; STAMP1 tile $B1 at 3 positions
  DEFB $18
  DEFB $8B,$02,$B1,$B1,$06,$13,$13,$12,$19,$13,$04,$13,$0B,$13,$19,$11 ; STAMPS 2
                                                                       ; tiles $B1
                                                                       ; $B1 at 6
                                                                       ; positions
  DEFB $17
  DEFB $92,$4B,$02,$12,$06,$12,$16 ; STAMP1 tile $4B at 2 positions
  DEFB $8B,$02,$4B,$4B,$04,$11,$08,$13 ; STAMPS 2 tiles $4B $4B at 4 positions
  DEFB $02,$13,$15,$13,$17
  DEFB $8C,$13,$16,$4A    ; TILE1 row 19, col 22, tile $4A
  DEFB $92,$25,$05,$01,$02,$01,$0C,$01 ; STAMP1 tile $25 at 5 positions
  DEFB $18,$01,$1A,$0A,$08
  DEFB $92,$49,$04,$10,$08,$12,$02,$12 ; STAMP1 tile $49 at 4 positions
  DEFB $17,$13,$14
  DEFB $95                ; IFZERO run DoorRight if LeverRoom20 is 0
  DEFW DoorRight
  DEFW LeverRoom20
  DEFB $80                ; END

; Erase the door at the right edge of room 20
;
; Fills the 1x4 cells at row 14, column 31 with the blank tile $80. Run through
; 9CEE by the lever of room 20 (ActionGateLever) when it is pulled.
EraseDoorRight:
  DEFB $86,$0E,$1F,$01,$04,$80 ; FILLTILE row 14, col 31, 1x4, tile $80
  DEFB $80                ; END

; Room script 21: Evil church
;
; Op $9E starts the animation of the blood tiles $3B/$3C in the bottom row
; (AnimateBloodTiles).
;
; Room 21: column 1, row 4 of the 5x5 map (left is room 20, right 22, up 16,
; down 1, counted modulo 25). Unpacks sprite sets PackedSet0, PackedSet3.
; Subscripts: ScriptRoomPanel, BlockAbbeyStoneA, BlockAbbeyStoneB,
; BlockAbbeyBlood, BlockBloodPool, BlockStoneHalfB. Items (RoomItems) at
; row,column: parchment 6,3, checkpoint 5,19.
RoomScript21:
  DEFB $97,$00            ; SPRITESET 0
  DEFB $97,$03            ; SPRITESET 3
  DEFB $87,$15            ; ROOMNAME 21 "Evil church"
  DEFB $83                ; CALL ScriptRoomPanel
  DEFW ScriptRoomPanel
  DEFB $83                ; CALL BlockAbbeyStoneA
  DEFW BlockAbbeyStoneA
  DEFB $99,$04,$00,$00,$20,$01,$00,$1E,$02,$10,$13,$16,$01,$01,$12,$17 ; TILEBLOCKS
                                                                       ; 4
                                                                       ; rectangles
  DEFB $04,$02
  DEFB $83                ; CALL BlockAbbeyStoneB
  DEFW BlockAbbeyStoneB
  DEFB $99,$02,$00,$00,$02,$0E,$12,$00 ; TILEBLOCKS 2 rectangles
  DEFB $02,$02
  DEFB $83                ; CALL BlockAbbeyBlood
  DEFW BlockAbbeyBlood
  DEFB $89,$14,$00,$20,$02 ; TILEBLOCK row 20, col 0, 32x2
  DEFB $83                ; CALL BlockBloodPool
  DEFW BlockBloodPool
  DEFB $89,$14,$12,$02,$02 ; TILEBLOCK row 20, col 18, 2x2
  DEFB $98,$B2,$06,$04,$07,$02,$0B,$04,$0F,$02,$0B,$04,$17,$02,$0B,$0B ; RECTS tile
                                                                       ; $B2, 6
                                                                       ; rectangles
  DEFB $05,$06,$02,$0B,$0D,$06,$02,$0B,$15,$06,$02
  DEFB $83                ; CALL BlockStoneHalfB
  DEFW BlockStoneHalfB
  DEFB $99,$05,$08,$02,$0C,$02,$08,$12,$04,$02,$08,$1A,$01,$02,$0B,$1D ; TILEBLOCKS
                                                                       ; 5
                                                                       ; rectangles
  DEFB $01,$02,$0E,$1C,$02,$02
  DEFB $92,$B3,$17,$04,$0F,$04,$18,$05,$18,$07,$08,$07,$10,$07,$17,$08 ; STAMP1
                                                                       ; tile $B3
                                                                       ; at 23
                                                                       ; positions
  DEFB $0F,$08,$10,$09,$0F,$09,$18,$0B,$05,$0B,$07,$0B,$09,$0B,$11,$0B
  DEFB $17,$0C,$0A,$0C,$0F,$0C,$10,$0C,$15,$0C,$1A,$0E,$07,$0E,$10,$0E
  DEFB $17
  DEFB $8C,$12,$16,$3D    ; TILE1 row 18, col 22, tile $3D
  DEFB $8C,$12,$1B,$47    ; TILE1 row 18, col 27, tile $47
  DEFB $8C,$13,$1B,$48    ; TILE1 row 19, col 27, tile $48
  DEFB $9E                ; enable the blood animation
  DEFB $91,$7E,$02,$01,$01,$07,$13 ; PICTURES tiles from $7E, 2x1, at 1
                                   ; positions
  DEFB $80                ; END

; Block pattern: abbey stone (tiles $3E,$3F,$41,$40)
;
; Defines the current block as 2x2 tiles of grey stone, the walls of the last
; rooms. Called by rooms 21, 22, 23, 24.
BlockAbbeyStoneA:
  DEFB $88,$02,$02,$3E,$3F,$41,$40 ; BLOCK 2x2: $3E $3F $41 $40
  DEFB $80                ; END

; Block pattern: abbey stone, variant (tiles $3E,$3F,$41,$44)
;
; Defines the current block as 2x2 tiles of grey stone; a variant of
; BlockAbbeyStoneA. Called by room 21.
BlockAbbeyStoneB:
  DEFB $88,$02,$02,$3E,$3F,$41,$44 ; BLOCK 2x2: $3E $3F $41 $44
  DEFB $80                ; END

; Block pattern: stone with blood (tiles $3E,$3F,$39,$3A)
;
; Defines the current block as grey stone tiles over blood-stained tiles, used
; for the floor. Called by rooms 21, 22, 23, 24.
BlockAbbeyBlood:
  DEFB $88,$02,$02,$3E,$3F,$39,$3A ; BLOCK 2x2: $3E $3F $39 $3A
  DEFB $80                ; END

; Block pattern: blood pool (tiles $80,$80,$3B,$3C)
;
; Defines the current block as two blank tiles over the two blood tiles $3B and
; $3C, which the animation AnimateBloodTiles swaps ($3B and $3C alternate) when
; op $9E is set. Called by rooms 21, 22, 23.
BlockBloodPool:
  DEFB $88,$02,$02,$80,$80,$3B,$3C ; BLOCK 2x2: $80 $80 $3B $3C
  DEFB $80                ; END

; Block pattern: stone with a clear lower half (tiles $45,$46,$80,$80)
;
; Defines the current block as stone tiles over two blank tiles. Called by
; rooms 21, 22.
BlockStoneHalfB:
  DEFB $88,$02,$02,$45,$46,$80,$80 ; BLOCK 2x2: $45 $46 $80 $80
  DEFB $80                ; END

; Room script 22: Tortured souls
;
; Op $9E starts the animation of the blood tiles $3B/$3C in the bottom row
; (AnimateBloodTiles).
;
; Room 22: column 2, row 4 of the 5x5 map (left is room 21, right 23, up 17,
; down 2, counted modulo 25). Unpacks sprite sets PackedSet17, PackedSet3,
; PackedSet18, PackedSet7. Subscripts: ScriptRoomPanel, BlockAbbeyStoneA,
; BlockAbbeyBlood, BlockBloodPool, BlockStoneHalfB. Items (RoomItems) at
; row,column: cross 18,27.
RoomScript22:
  DEFB $97,$11            ; SPRITESET 17
  DEFB $97,$03            ; SPRITESET 3
  DEFB $97,$12            ; SPRITESET 18
  DEFB $97,$07            ; SPRITESET 7
  DEFB $87,$16            ; ROOMNAME 22 "Tortured souls"
  DEFB $83                ; CALL ScriptRoomPanel
  DEFW ScriptRoomPanel
  DEFB $83                ; CALL BlockAbbeyStoneA
  DEFW BlockAbbeyStoneA
  DEFB $99,$05,$00,$00,$20,$06,$00,$00,$02,$10,$0A,$1E,$02,$0A,$10,$06 ; TILEBLOCKS
                                                                       ; 5
                                                                       ; rectangles
  DEFB $02,$02,$12,$05,$04,$02
  DEFB $86,$01,$02,$0E,$05,$80 ; FILLTILE row 1, col 2, 14x5, tile $80
  DEFB $83                ; CALL BlockAbbeyBlood
  DEFW BlockAbbeyBlood
  DEFB $89,$14,$00,$20,$02 ; TILEBLOCK row 20, col 0, 32x2
  DEFB $83                ; CALL BlockBloodPool
  DEFW BlockBloodPool
  DEFB $99,$02,$14,$0A,$04,$02,$14,$12 ; TILEBLOCKS 2 rectangles
  DEFB $04,$02
  DEFB $83                ; CALL BlockStoneHalfB
  DEFW BlockStoneHalfB
  DEFB $99,$05,$05,$06,$08,$02,$09,$04,$02,$02,$0B,$0F,$06,$02,$0B,$18 ; TILEBLOCKS
                                                                       ; 5
                                                                       ; rectangles
  DEFB $06,$02,$0D,$02,$02,$02
  DEFB $91,$AA,$02,$03,$03,$02,$12,$02 ; PICTURES tiles from $AA, 2x3, at 3
                                       ; positions
  DEFB $16,$02,$1A
  DEFB $9B,$B5,$05,$01,$03,$05,$01,$04,$03,$06,$15,$03,$06,$16,$09,$06 ; RUNS_V
                                                                       ; tile $B5,
                                                                       ; 5 vertical
                                                                       ; runs
  DEFB $1B,$02
  DEFB $86,$13,$18,$02,$01,$05 ; FILLTILE row 19, col 24, 2x1, tile $05
  DEFB $98,$4B,$03,$02,$14,$02,$03,$02 ; RECTS tile $4B, 3 rectangles
  DEFB $18,$02,$03,$02,$1C,$02,$03
  DEFB $92,$49,$03,$02,$18,$03,$14,$03 ; STAMP1 tile $49 at 3 positions
  DEFB $1D
  DEFB $9E                ; enable the blood animation
  DEFB $80                ; END

; Room script 23: Ashes to ashes
;
; Op $9E starts the animation of the blood tiles $3B/$3C in the bottom row
; (AnimateBloodTiles).
;
; Room 23: column 3, row 4 of the 5x5 map (left is room 22, right 24, up 18,
; down 3, counted modulo 25). Unpacks sprite sets PackedSet4, PackedSet18,
; PackedSet7. Subscripts: ScriptRoomPanel, BlockAbbeyStoneA, BlockAbbeyBlood,
; BlockBloodPool. Items (RoomItems) at row,column: heart 7,23, checkpoint
; 17,17.
RoomScript23:
  DEFB $97,$04            ; SPRITESET 4
  DEFB $97,$12            ; SPRITESET 18
  DEFB $97,$07            ; SPRITESET 7
  DEFB $87,$17            ; ROOMNAME 23 "Ashes to ashes"
  DEFB $83                ; CALL ScriptRoomPanel
  DEFW ScriptRoomPanel
  DEFB $83                ; CALL BlockAbbeyStoneA
  DEFW BlockAbbeyStoneA
  DEFB $89,$00,$00,$20,$16 ; TILEBLOCK row 0, col 0, 32x22
  DEFB $98,$80,$03,$01,$02,$1C,$15,$06 ; RECTS tile $80, 3 rectangles
  DEFB $00,$02,$04,$10,$1E,$02,$04
  DEFB $83                ; CALL BlockAbbeyBlood
  DEFW BlockAbbeyBlood
  DEFB $99,$02,$14,$00,$20,$02,$0F,$1D ; TILEBLOCKS 2 rectangles
  DEFB $01,$01
  DEFB $83                ; CALL BlockBloodPool
  DEFW BlockBloodPool
  DEFB $99,$03,$14,$02,$06,$02,$14,$0A ; TILEBLOCKS 3 rectangles
  DEFB $06,$02,$14,$14,$06,$02
  DEFB $8B,$02,$4B,$4B,$04,$06,$12,$10 ; STAMPS 2 tiles $4B $4B at 4 positions
  DEFB $0C,$10,$0E,$07,$08
  DEFB $92,$4B,$06,$08,$10,$09,$18,$0A ; STAMP1 tile $4B at 6 positions
  DEFB $0C,$0B,$1B,$0C,$0E,$13,$1B
  DEFB $92,$49,$04,$07,$09,$09,$17,$10 ; STAMP1 tile $49 at 4 positions
  DEFB $0E,$13,$1C
  DEFB $9B,$B5,$04,$01,$04,$06,$01,$05 ; RUNS_V tile $B5, 4 vertical runs
  DEFB $03,$01,$18,$02,$01,$1B,$05
  DEFB $93,$0A,$04,$02,$45,$46 ; ROW row 10, col 4, 2 tiles
  DEFB $8B,$02,$B4,$B4,$0D,$14,$02,$14,$05,$13,$02,$13,$04,$12,$02,$12 ; STAMPS 2
                                                                       ; tiles $B4
                                                                       ; $B4 at 13
                                                                       ; positions
  DEFB $04,$11,$02,$14,$0A,$14,$0C,$13,$0B,$14,$16,$14,$18,$13,$17
  DEFB $92,$B4,$01,$10,$02 ; STAMP1 tile $B4 at 1 positions
  DEFB $9E                ; enable the blood animation
  DEFB $91,$7E,$02,$01,$01,$13,$11 ; PICTURES tiles from $7E, 2x1, at 1
                                   ; positions
  DEFB $80                ; END

; Room script 24: Satan !!!
;
; Satan's room. The last op, $9F, switches on the ring of crosses
; (ShowCrossRing), which shows the twelve crosses one by one when all of them
; have been collected. The sprite set 14 (Satan) is unpacked by the room
; objects, the script itself unpacks sets 14 and 1.
;
; Room 24: column 4, row 4 of the 5x5 map (left is room 23, right 0, up 19,
; down 4, counted modulo 25). Unpacks sprite sets PackedSet14, PackedSet1.
; Subscripts: ScriptRoomPanel, BlockAbbeyStoneA, BlockAbbeyBlood. Items
; (RoomItems) at row,column: chalice 2,16, red scroll 14,28.
RoomScript24:
  DEFB $97,$0E            ; SPRITESET 14
  DEFB $97,$01            ; SPRITESET 1
  DEFB $87,$18            ; ROOMNAME 24 "Satan !!!"
  DEFB $83                ; CALL ScriptRoomPanel
  DEFW ScriptRoomPanel
  DEFB $83                ; CALL BlockAbbeyStoneA
  DEFW BlockAbbeyStoneA
  DEFB $89,$00,$00,$20,$14 ; TILEBLOCK row 0, col 0, 32x20
  DEFB $83                ; CALL BlockAbbeyBlood
  DEFW BlockAbbeyBlood
  DEFB $89,$14,$00,$20,$02 ; TILEBLOCK row 20, col 0, 32x2
  DEFB $98,$80,$03,$10,$00,$15,$04,$01 ; RECTS tile $80, 3 rectangles
  DEFB $02,$1C,$0F,$10,$00,$17,$02
  DEFB $92,$3D,$04,$10,$17,$11,$16,$12 ; STAMP1 tile $3D at 4 positions
  DEFB $15,$13,$14
  DEFB $9B,$B5,$04,$01,$04,$04,$01,$05 ; RUNS_V tile $B5, 4 vertical runs
  DEFB $02,$01,$1A,$02,$01,$1B,$04
  DEFB $91,$E0,$04,$01,$01,$06,$0E ; PICTURES tiles from $E0, 4x1, at 1
                                   ; positions
  DEFB $91,$E4,$06,$04,$01,$07,$0D ; PICTURES tiles from $E4, 6x4, at 1
                                   ; positions
  DEFB $91,$FC,$04,$01,$01,$0B,$0E ; PICTURES tiles from $FC, 4x1, at 1
                                   ; positions
  DEFB $92,$B4,$04,$12,$05,$13,$04,$13 ; STAMP1 tile $B4 at 4 positions
  DEFB $05,$13,$07
  DEFB $9F                ; enable the ring of crosses
  DEFB $80                ; END

; Room script 25: the ending room, runs the script of room 24
;
; Room 25 is only entered by the ending sequence RunEnding (first part): it
; runs the script of room 24 (RoomScript24) and nothing else; the crusaders of
; the actor list CutsceneList1 and the text ScriptEnding1 are added by the
; sequence.
RoomScript25:
  DEFB $83                ; CALL RoomScript24
  DEFW RoomScript24
  DEFB $80                ; END

; Erase the twelve crosses of Satan's room
;
; Run by UpdateSatan (through $9CEE and the hook $9CE7) when Satan has been
; turned into smoke. Op $92 draws the blank tile $80 at 12 positions, covering
; the twelve crosses (tile $4C) that ShowCrossRing stamped there. The 12
; positions (row, column, two bytes each) start at $82D7 and are also read by
; ShowCrossRing, which stamps the crosses at them.
ScriptEraseCrosses:
  DEFB $92,$80,$0C        ; STAMP1 tile $80 at 12 positions
CrossRingPositions:
  DEFB $06,$0B            ; row, column of the 1st cross
  DEFB $06,$0C
  DEFB $09,$05
  DEFB $09,$06
  DEFB $09,$09
  DEFB $0D,$03
  DEFB $0E,$0E
  DEFB $0F,$06
  DEFB $0F,$07
  DEFB $0F,$0A
  DEFB $0F,$0B
  DEFB $11,$10
  DEFB $80                ; END

; Standard start of a room: clear the map and draw the name panel
;
; Called by the script of nearly every room (all but 0 and 4) right after the
; room name is set. It sets the colours of the bottom right panel (rows 22-23,
; columns 12-31: white on black), clears its pixels, clears the whole tile map
; with the blank tile $80, prints the room name from RoomNameString
; right-aligned at pixel row 176 and marks every cell for redraw.
;
; Hardware: writes the screen bitmap and the attribute file directly (ops $81
; and $8F), not through the tile map.
ScriptRoomPanel:
  DEFB $8F,$16,$0C,$14,$02,$07 ; FILLATTR row 22, col 12, 20x2, attribute $07
  DEFB $81,$B0,$0C,$14,$10,$00 ; FILLPIX pixel row 176, byte col 12, 20 bytes x
                               ; 16 rows, byte $00
  DEFB $86,$00,$00,$20,$16,$80 ; FILLTILE row 0, col 0, 32x22, tile $80
  DEFB $82,$00,$B0        ; ALIGN mode 0, pixel row 176
  DEFB $84                ; PRINTVAR string number in RoomNameString
  DEFW RoomNameString
  DEFB $90,$01            ; REDRAWMARK mark all cells
  DEFB $80                ; END

; Night sky: the moon and the stars
;
; Used by the first rooms (1, 2, 3, 4 and 6). Defines a 2x2 block of tiles
; $8D-$90 (the crescent moon), draws it at row 2, column 20, then draws the
; single-pixel star tile $8D at seven positions.
ScriptSky:
  DEFB $88,$02,$02,$8D,$8E,$8F,$90 ; BLOCK 2x2: $8D $8E $8F $90
  DEFB $89,$02,$14,$02,$02 ; TILEBLOCK row 2, col 20, 2x2
  DEFB $8B,$01,$8D,$07,$04,$01,$05,$03,$02,$05,$03,$0B,$02,$0C,$05,$0F ; STAMPS 1
                                                                       ; tiles $8D
                                                                       ; at 7
                                                                       ; positions
  DEFB $03,$1A
  DEFB $80                ; END

; Parchment page: clear the screen and print the two lines of text
;
; Run by ShowParchment when a parchment is read. It sets all the attributes to
; black, clears the screen bitmap above the status bar (176 pixel rows), prints
; the strings numbered ParchmentLine1 and ParchmentLine2 centred at pixel rows
; 65 and 85 with two PRINTVAR ops, and marks every cell for redraw so that the
; room comes back when the parchment is closed. The frame is drawn afterwards
; by DrawParchmentFrame.
;
; Hardware: writes the screen bitmap and the attribute file directly (ops $81
; and $8F), not through the tile map.
ScriptParchment:
  DEFB $8F,$00,$00,$20,$18,$00 ; FILLATTR row 0, col 0, 32x24, attribute $00
  DEFB $81,$00,$00,$20,$B0,$00 ; FILLPIX pixel row 0, byte col 0, 32 bytes x
                               ; 176 rows, byte $00
  DEFB $82,$02,$41        ; ALIGN mode 2, pixel row 65
  DEFB $84                ; PRINTVAR string number in ParchmentLine1
  DEFW ParchmentLine1
  DEFB $82,$02,$55        ; ALIGN mode 2, pixel row 85
  DEFB $84                ; PRINTVAR string number in ParchmentLine2
  DEFW ParchmentLine2
  DEFB $90,$01            ; REDRAWMARK mark all cells
  DEFB $80                ; END

; Ending text 1: "your doom will come / not by my hand / but by human hands"
;
; Run by the ending sequence RunEnding: clears the attributes and the screen,
; prints strings 43-45 centred at pixel rows 55, 75 and 95, and marks all cells
; for redraw.
;
; Hardware: writes the screen bitmap and the attribute file directly (ops $81
; and $8F), not through the tile map.
ScriptEnding1:
  DEFB $8F,$00,$00,$20,$18,$00 ; FILLATTR row 0, col 0, 32x24, attribute $00
  DEFB $81,$00,$00,$20,$B0,$00 ; FILLPIX pixel row 0, byte col 0, 32 bytes x
                               ; 176 rows, byte $00
  DEFB $82,$02,$37        ; ALIGN mode 2, pixel row 55
  DEFB $85,$2B            ; PRINT string 43 "your doom will come"
  DEFB $82,$02,$4B        ; ALIGN mode 2, pixel row 75
  DEFB $85,$2C            ; PRINT string 44 "not by my hand"
  DEFB $82,$02,$5F        ; ALIGN mode 2, pixel row 95
  DEFB $85,$2D            ; PRINT string 45 "but by human hands"
  DEFB $90,$01            ; REDRAWMARK mark all cells
  DEFB $80                ; END

; Ending text 2: "Heresy!!! The Cathar is hidden on the throne of Satan, burn
; him"
;
; Run by the ending sequence RunEnding before its second part: clears the
; attributes and the screen, prints strings 46-48 centred at pixel rows 55, 75
; and 95, and marks all cells for redraw.
;
; Hardware: writes the screen bitmap and the attribute file directly (ops $81
; and $8F), not through the tile map.
ScriptEnding2:
  DEFB $8F,$00,$00,$20,$18,$00 ; FILLATTR row 0, col 0, 32x24, attribute $00
  DEFB $81,$00,$00,$20,$B0,$00 ; FILLPIX pixel row 0, byte col 0, 32 bytes x
                               ; 176 rows, byte $00
  DEFB $82,$02,$37        ; ALIGN mode 2, pixel row 55
  DEFB $85,$2E            ; PRINT string 46 "Heresy!!! The Cathar"
  DEFB $82,$02,$4B        ; ALIGN mode 2, pixel row 75
  DEFB $85,$2F            ; PRINT string 47 "is hidden on the throne"
  DEFB $82,$02,$5F        ; ALIGN mode 2, pixel row 95
  DEFB $85,$30            ; PRINT string 48 "of Satan, burn him"
  DEFB $90,$01            ; REDRAWMARK mark all cells
  DEFB $80                ; END

; Ending text 3: "Your body has burned in the flames, but your soul has found a
; place in Heaven."
;
; Run at the end of the ending sequence RunEnding: clears the attributes and
; the screen (176 + 16 pixel rows), prints strings 49-52 centred at pixel rows
; 28, 48, 128 and 148 and sets the attributes to white on black.
;
; Hardware: writes the screen bitmap and the attribute file directly (ops $81
; and $8F), not through the tile map.
ScriptEnding3:
  DEFB $8F,$00,$00,$20,$18,$00 ; FILLATTR row 0, col 0, 32x24, attribute $00
  DEFB $81,$00,$00,$20,$C0,$00 ; FILLPIX pixel row 0, byte col 0, 32 bytes x
                               ; 192 rows, byte $00
  DEFB $82,$02,$1C        ; ALIGN mode 2, pixel row 28
  DEFB $85,$31            ; PRINT string 49 "Your body has burned"
  DEFB $82,$02,$30        ; ALIGN mode 2, pixel row 48
  DEFB $85,$32            ; PRINT string 50 "in the flames,"
  DEFB $82,$02,$80        ; ALIGN mode 2, pixel row 128
  DEFB $85,$33            ; PRINT string 51 "but your soul has found"
  DEFB $82,$02,$94        ; ALIGN mode 2, pixel row 148
  DEFB $85,$34            ; PRINT string 52 "a place in Heaven."
  DEFB $8F,$00,$00,$20,$18,$07 ; FILLATTR row 0, col 0, 32x24, attribute $07
  DEFB $80                ; END
