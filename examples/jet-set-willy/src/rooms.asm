; Room 0 ($00): The Off Licence
;
; This entry carries the format description of all rooms; the other rooms refer
; to it. Rooms 0-46 and 48-60 are normal rooms, room 47 is an empty room titled
; "[", rooms 61-63 hold stray bytes that are not a room. The game starts in
; room 33 (The Bathroom, NewGame stores $21 in $8420 at $87EC).
;
; Format of a room (256 bytes at $C000+256*N, N = 0-63). EnterRoom copies the
; room to $8000 when it is entered and all game code reads that copy (the room
; number is kept in $8420; the page address is $C0 OR N, so only the low 6 bits
; of N matter). Offsets below are from the start of the room.
;
; +$00-$7F layout: 16 rows of 32 cells (the 16 character rows of the playing
; area), 8 bytes per row, 2 bits per cell, leftmost cell in bits 7-6 of the
; first byte of the row. The cell value (0-3) selects tile 0-3 of the room
; (ExpandRoomLayout, StoreCellAttr). In the row comments of every room below
; the cells are drawn as . background, - floor, # wall, * nasty; conveyor and
; ramp are not part of the layout bytes.
;
; +$80-$9F name: 32 characters, printed by PrintText on the bottom third of the
; screen (at $5000) when the room is entered.
;
; +$A0-$D5 six tiles of 9 bytes: an attribute byte followed by 8 pixel rows.
; Tile 0 background (also the empty space Willy falls through), 1 floor (Willy
; stands on it; its attribute is never compared by the code), 2 wall (blocks
; sideways and upward movement: MoveWilly), 3 nasty (kills on touch:
; MarkWillyCell), 4 ramp, 5 conveyor. The game finds tiles by attribute byte,
; not by number: BuildRoomBuffers and the movement code compare the attribute
; bytes in the cell buffer with the first byte of tile 0, 2, 3, 4, 5 ($80A0,
; $80B2, $80BB, $80C4, $80CD). BuildRoomBuffers looks each attribute up with
; CPIR over the first 54 bytes of the tile area and draws the 8 bytes that
; follow the first match, so a tile whose attribute byte also occurs earlier in
; the tile area (as a pixel byte of an earlier tile) is drawn with the wrong
; pixels. Observed in rooms 24, 29 and 36 (see their descriptions). Tiles used
; in one room need different attribute bytes (no room checked has two used
; tiles with the same attribute).
;
; +$D6 conveyor direction (0 = moves Willy left, 1 = right), +$D7 word: address
; of the leftmost conveyor cell in the attribute buffer ($5E00 + 32*row +
; column), +$D9 length in cells (0 = no conveyor; the direction and address
; bytes are then leftovers). The cells are filled with tile 5 after the layout
; (ExpandRoomLayout); AnimateConveyor animates the pixel rows 0 and 2 of the
; cells.
;
; +$DA ramp direction (bit 0 only: 0 = rises to the left, 1 = rises to the
; right), +$DB word: attribute buffer address of the lowest cell of the ramp,
; +$DD length in cells (0 = no ramp). Each further cell is one row up and one
; column left (bit 0 = 0, step -33) or right (bit 0 = 1, step -31). Filled with
; tile 4 (ExpandRoomLayout).
;
; +$DE border colour (the whole byte is written to port $FE, bits 3-4 are
; toggled by the sound code; values 1-6 are used). +$DF-$E0: not read by any
; code. Rooms 0-4 hold $00,$40,$80,$C0,$C0 followed by $A0 (as a word $A000,
; $A040, $A080, $A0C0, $A0C0: looks like leftover pointers into the entity
; definitions), all other rooms hold zeros.
;
; +$E1-$E8 item graphic: 8 pixel rows, one picture for every item in the room
; (UpdateItems). Where the items are is not stored here: see the item table at
; ItemRoomTable.
;
; +$E9-$EC exits: room numbers left, right, up, down (observed: holding left in
; room 33 enters the room in byte +$E9 = 34). ExitRoomLeft, ExitRoomRight,
; ExitRoomUp and ExitRoomDown load the new room number into $8420 and re-enter
; EnterRoom. Nothing treats 0 as 'no exit': an exit byte 0 leads to room 0, and
; the bytes of edges Willy cannot reach are mostly 0. Bits 6-7 of the byte are
; ignored (page = $C0 OR byte).
;
; +$ED-$EF: not read by any code; zero in every room that has the room format.
;
; +$F0-$FF eight entity slots of 2 bytes: definition index, start byte.
; EnterRoom copies, for each slot, 8 bytes from the entity definition at
; $A000+8*(index AND $7F) to the entity buffer at $8100+8*slot, with the start
; byte replacing byte 2 (it is also stored in the definition table: inferred
; from $893A-$893D). The start byte low 5 bits are then the entity's column
; (inferred from DrawEntities); the high 3 bits are mixed into its animation
; frame (inferred, not confirmed). A slot with index 0 is an empty entity
; (definition 0 is all zeros: it is skipped by MoveEntities and DrawEntities).
; A slot with index $FF ends the list ($A3F8 begins with $FF); when all 8 slots
; are used the byte $FF at $8140 ends it. Slots after an $FF are copied but
; never used.
;
; Border: cyan (5). Conveyor: moves Willy left, 12 cells from row 9 column 19.
; Ramp: 4 cells from row 14 column 23 up to row 11 column 26, rising to the
; right.
;
; Items (from the item table at ItemRoomTable): 12, at row 4 columns 19-30.
;
; Exits: left Room 1 (The Bridge, RoomBridge); right Room 0 (The Off Licence,
; RoomOffLicence); up Room 0 (The Off Licence, RoomOffLicence); down Room 0
; (The Off Licence, RoomOffLicence). Odd: the right, up and down exits lead
; back to this room.
;
; Entities: slot 0: definition $0A (at $A050) start $8A; slot 1: definition $0C
; (at $A060) start $1D; slot 2: definition $2C (at $A160) start $27. List ends
; at slot 3 ($FF).
;
; Bytes $DF-$E0 hold $00,$A0 (see RoomOffLicence).
RoomOffLicence:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 0:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 1:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 2:
                                       ; ................................
  DEFB $00,$00,$00,$AA,$AA,$AA,$AA,$AA ; row 3:
                                       ; ............####################
  DEFB $00,$00,$00,$80,$00,$00,$00,$02 ; row 4:
                                       ; ............#..................#
  DEFB $00,$00,$00,$80,$00,$00,$00,$02 ; row 5:
                                       ; ............#..................#
  DEFB $00,$00,$00,$8C,$00,$00,$00,$02 ; row 6:
                                       ; ............#.*................#
  DEFB $00,$00,$00,$80,$00,$00,$00,$02 ; row 7:
                                       ; ............#..................#
  DEFB $00,$00,$00,$80,$00,$00,$00,$02 ; row 8:
                                       ; ............#..................#
  DEFB $00,$00,$00,$80,$00,$00,$00,$02 ; row 9:
                                       ; ............#..................#
  DEFB $00,$00,$00,$80,$00,$00,$00,$02 ; row 10:
                                       ; ............#..................#
  DEFB $00,$00,$00,$AA,$00,$00,$02,$AA ; row 11:
                                       ; ............####...........#####
  DEFB $00,$00,$00,$00,$00,$00,$00,$02 ; row 12:
                                       ; ...............................#
  DEFB $00,$00,$00,$00,$00,$00,$00,$02 ; row 13:
                                       ; ...............................#
  DEFB $00,$00,$00,$00,$00,$00,$00,$02 ; row 14:
                                       ; ...............................#
  DEFB $55,$55,$55,$55,$55,$55,$55,$55 ; row 15:
                                       ; --------------------------------
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "         The Off Licence        "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on
                                           ; black
  DEFB $44,$FF,$DE,$6C,$88,$12,$40,$04,$00 ; tile 1 (floor): bright green on
                                           ; black
  DEFB $16,$22,$FF,$88,$FF,$22,$FF,$88,$FF ; tile 2 (wall): yellow on red
  DEFB $05,$F8,$88,$9E,$BD,$BD,$9E,$88,$F8 ; tile 3 (nasty): cyan on black
  DEFB $07,$03,$00,$0C,$00,$30,$00,$C0,$00 ; tile 4 (ramp): white on black
  DEFB $43,$33,$FF,$33,$00,$FF,$00,$AA,$00 ; tile 5 (conveyor): bright magenta
                                           ; on black
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $00,$33,$5F,$0C    ; direction 0 (left), address $5F33 = row 9 column
                          ; 19, 12 cells
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $01,$D7,$5F,$04    ; direction 1 (rises to the right), lowest cell $5FD7
                          ; = row 14 column 23, 4 cells
; Border colour; then $DF-$E0, not read by any code.
  DEFB $05,$00,$A0        ; border cyan (5); $DF-$E0 = $00,$A0
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $18,$18,$3C,$7E,$62,$62,$62,$7E ; item graphic
; Exits: room numbers left, right, up, down.
  DEFB $01,$00,$00,$00    ; left 1, right 0, up 0, down 0
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $0A,$8A            ; definition $0A, start $8A (column 10)
  DEFB $0C,$1D            ; definition $0C, start $1D (column 29)
  DEFB $2C,$27            ; definition $2C, start $27 (column 7)
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 1 ($01): The Bridge
;
; Format: see RoomOffLicence.
;
; Border: green (4). Conveyor: moves Willy right, 5 cells from row 15 column
; 12. Ramp: 3 cells from row 14 column 7 up to row 12 column 9, rising to the
; right.
;
; Items: none in the item table.
;
; Exits: left Room 2 (Under the MegaTree, RoomUnderMegaTree); right Room 0 (The
; Off Licence, RoomOffLicence); up Room 0 (The Off Licence, RoomOffLicence);
; down Room 0 (The Off Licence, RoomOffLicence).
;
; Entities: slot 0: definition $14 (at $A0A0) start $08; slot 1: definition $15
; (at $A0A8) start $14; slot 2: definition $0E (at $A070) start $8C. List ends
; at slot 3 ($FF).
;
; Bytes $DF-$E0 hold $40,$A0 (see RoomOffLicence).
RoomBridge:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 0:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 1:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 2:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 3:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 4:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 5:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 6:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 7:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 8:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 9:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 10:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 11:
                                       ; ................................
  DEFB $00,$00,$0A,$00,$2A,$00,$00,$00 ; row 12:
                                       ; ..........##.....###............
  DEFB $00,$00,$2A,$00,$2A,$80,$00,$00 ; row 13:
                                       ; .........###.....####...........
  DEFB $00,$00,$AA,$FF,$EA,$A0,$00,$00 ; row 14:
                                       ; ........####*****#####..........
  DEFB $55,$55,$AA,$FF,$EA,$A5,$55,$55 ; row 15:
                                       ; --------####*****#####----------
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "         The Bridge             "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on
                                           ; black
  DEFB $44,$FF,$FF,$FD,$BB,$D6,$72,$60,$40 ; tile 1 (floor): bright green on
                                           ; black
  DEFB $46,$22,$77,$22,$88,$22,$77,$22,$88 ; tile 2 (wall): bright yellow on
                                           ; black
  DEFB $2F,$03,$84,$48,$30,$03,$84,$48,$30 ; tile 3 (nasty): white on cyan
  DEFB $07,$03,$03,$0C,$0D,$32,$37,$C2,$C8 ; tile 4 (ramp): white on black
  DEFB $2C,$01,$40,$04,$46,$4F,$79,$F0,$F9 ; tile 5 (conveyor): green on cyan
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $01,$EC,$5F,$05    ; direction 1 (right), address $5FEC = row 15 column
                          ; 12, 5 cells
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $01,$C7,$5F,$03    ; direction 1 (rises to the right), lowest cell $5FC7
                          ; = row 14 column 7, 3 cells
; Border colour; then $DF-$E0, not read by any code.
  DEFB $04,$40,$A0        ; border green (4); $DF-$E0 = $40,$A0
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; item graphic (all zeros: blank)
; Exits: room numbers left, right, up, down.
  DEFB $02,$00,$00,$00    ; left 2, right 0, up 0, down 0
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $14,$08            ; definition $14, start $08 (column 8)
  DEFB $15,$14            ; definition $15, start $14 (column 20)
  DEFB $0E,$8C            ; definition $0E, start $8C (column 12)
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 2 ($02): Under the MegaTree
;
; Format: see RoomOffLicence.
;
; Border: yellow (6). Conveyor: none. Ramp: none.
;
; Items (from the item table at ItemRoomTable): 1, at row 0 column 22.
;
; Exits: left Room 3 (At the Foot of the MegaTree, RoomFootOfMegaTree); right
; Room 1 (The Bridge, RoomBridge); up Room 0 (The Off Licence, RoomOffLicence);
; down Room 0 (The Off Licence, RoomOffLicence).
;
; Entities: slot 0: definition $20 (at $A100) start $10; slot 1: definition $2A
; (at $A150) start $0E; slot 2: definition $1A (at $A0D0) start $1B. List ends
; at slot 3 ($FF).
;
; Bytes $DF-$E0 hold $80,$A0 (see RoomOffLicence).
RoomUnderMegaTree:
  DEFB $00,$03,$FF,$CF,$FC,$00,$00,$00 ; row 0:
                                       ; .......******.*****.............
  DEFB $AA,$AA,$AF,$FF,$3F,$00,$00,$00 ; row 1:
                                       ; ##########******.***............
  DEFB $00,$00,$3F,$D0,$5C,$00,$00,$00 ; row 2:
                                       ; .........****-..--*.............
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 3:
                                       ; ................................
  DEFB $AA,$80,$00,$00,$00,$00,$00,$00 ; row 4:
                                       ; #####...........................
  DEFB $00,$01,$40,$04,$00,$04,$00,$00 ; row 5:
                                       ; .......--.....-.......-.........
  DEFB $00,$00,$01,$00,$04,$00,$00,$00 ; row 6:
                                       ; ...........-......-.............
  DEFB $AA,$A8,$00,$00,$00,$01,$00,$00 ; row 7:
                                       ; #######................-........
  DEFB $00,$00,$14,$10,$10,$00,$00,$00 ; row 8:
                                       ; .........--..-...-..............
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 9:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 10:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 11:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 12:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 13:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 14:
                                       ; ................................
  DEFB $55,$55,$55,$55,$55,$55,$55,$55 ; row 15:
                                       ; --------------------------------
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "       Under the MegaTree       "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on
                                           ; black
  DEFB $44,$D7,$B3,$75,$6D,$5C,$18,$08,$04 ; tile 1 (floor): bright green on
                                           ; black
  DEFB $42,$BD,$AA,$5D,$A2,$F3,$0A,$06,$01 ; tile 2 (wall): bright red on black
  DEFB $46,$49,$6A,$3B,$3A,$FC,$1E,$6B,$E8 ; tile 3 (nasty): bright yellow on
                                           ; black
  DEFB $FF,$00,$00,$00,$FF,$00,$00,$00,$00 ; tile 4 (ramp): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 5 (conveyor): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $00,$00,$00,$00    ; no conveyor (length 0)
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $00,$00,$00,$00    ; no ramp (length 0)
; Border colour; then $DF-$E0, not read by any code.
  DEFB $06,$80,$A0        ; border yellow (6); $DF-$E0 = $80,$A0
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $81,$42,$24,$18,$3C,$18,$3C,$C3 ; item graphic
; Exits: room numbers left, right, up, down.
  DEFB $03,$01,$00,$00    ; left 3, right 1, up 0, down 0
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $20,$10            ; definition $20, start $10 (column 16)
  DEFB $2A,$0E            ; definition $2A, start $0E (column 14)
  DEFB $1A,$1B            ; definition $1A, start $1B (column 27)
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 3 ($03): At the Foot of the MegaTree
;
; Format: see RoomOffLicence.
;
; Border: red (2). Conveyor: none. Ramp: 3 cells from row 12 column 15 up to
; row 10 column 13, rising to the left.
;
; Items (from the item table at ItemRoomTable): 3, at row 10 column 4; row 11
; columns 1, 7.
;
; Exits: left Room 4 (The Drive, RoomDrive); right Room 2 (Under the MegaTree,
; RoomUnderMegaTree); up Room 8 (Inside the MegaTrunk, RoomInsideMegaTrunk);
; down Room 0 (The Off Licence, RoomOffLicence).
;
; Entities: slot 0: definition $06 (at $A030) start $02; slot 1: definition $07
; (at $A038) start $05; slot 2: definition $08 (at $A040) start $08; slot 3:
; definition $35 (at $A1A8) start $09. List ends at slot 4 ($FF).
;
; Bytes $DF-$E0 hold $C0,$A0 (see RoomOffLicence).
RoomFootOfMegaTree:
  DEFB $30,$C3,$08,$00,$08,$00,$00,$00 ; row 0:
                                       ; .*..*..*..#.......#.............
  DEFB $30,$C3,$08,$00,$0A,$AA,$AA,$AA ; row 1:
                                       ; .*..*..*..#.......##############
  DEFB $30,$C3,$08,$00,$08,$00,$00,$00 ; row 2:
                                       ; .*..*..*..#.......#.............
  DEFB $30,$C3,$08,$01,$58,$00,$00,$00 ; row 3:
                                       ; .*..*..*..#....---#.............
  DEFB $30,$C3,$09,$00,$0A,$AA,$AA,$AA ; row 4:
                                       ; .*..*..*..#-......##############
  DEFB $30,$C3,$08,$14,$00,$00,$00,$00 ; row 5:
                                       ; .*..*..*..#..--.................
  DEFB $30,$C3,$08,$00,$00,$00,$00,$00 ; row 6:
                                       ; .*..*..*..#.....................
  DEFB $30,$C3,$09,$00,$1A,$AA,$AA,$AA ; row 7:
                                       ; .*..*..*..#-.....-##############
  DEFB $30,$C3,$08,$00,$08,$00,$00,$00 ; row 8:
                                       ; .*..*..*..#.......#.............
  DEFB $30,$C3,$08,$00,$58,$00,$00,$00 ; row 9:
                                       ; .*..*..*..#.....--#.............
  DEFB $30,$03,$09,$40,$08,$00,$00,$00 ; row 10:
                                       ; .*.....*..#--.....#.............
  DEFB $00,$00,$08,$00,$08,$00,$00,$00 ; row 11:
                                       ; ..........#.......#.............
  DEFB $00,$00,$08,$00,$08,$00,$00,$00 ; row 12:
                                       ; ..........#.......#.............
  DEFB $00,$00,$00,$00,$50,$00,$00,$00 ; row 13:
                                       ; ................--..............
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 14:
                                       ; ................................
  DEFB $55,$55,$55,$55,$55,$55,$55,$55 ; row 15:
                                       ; --------------------------------
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "  At the Foot of the MegaTree   "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on
                                           ; black
  DEFB $04,$F0,$F9,$BF,$1F,$0C,$10,$28,$44 ; tile 1 (floor): green on black
  DEFB $16,$AB,$AB,$AD,$AA,$AA,$AE,$55,$55 ; tile 2 (wall): yellow on red
  DEFB $06,$6E,$74,$38,$1E,$6E,$74,$38,$1E ; tile 3 (nasty): yellow on black
  DEFB $07,$C0,$00,$30,$00,$0C,$00,$03,$00 ; tile 4 (ramp): white on black
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 5 (conveyor): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $00,$00,$00,$00    ; no conveyor (length 0)
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $00,$8F,$5F,$03    ; direction 0 (rises to the left), lowest cell $5F8F
                          ; = row 12 column 15, 3 cells
; Border colour; then $DF-$E0, not read by any code.
  DEFB $02,$C0,$A0        ; border red (2); $DF-$E0 = $C0,$A0
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $40,$A0,$5C,$22,$21,$22,$14,$08 ; item graphic
; Exits: room numbers left, right, up, down.
  DEFB $04,$02,$08,$00    ; left 4, right 2, up 8, down 0
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $06,$02            ; definition $06, start $02 (column 2)
  DEFB $07,$05            ; definition $07, start $05 (column 5)
  DEFB $08,$08            ; definition $08, start $08 (column 8)
  DEFB $35,$09            ; definition $35, start $09 (column 9)
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 4 ($04): The Drive
;
; Format: see RoomOffLicence.
;
; Border: magenta (3). Conveyor: moves Willy right, 2 cells from row 13 column
; 0. Ramp: 7 cells from row 14 column 9 up to row 8 column 3, rising to the
; left.
;
; Items: none in the item table.
;
; Exits: left Room 5 (The Security Guard, RoomSecurityGuard); right Room 3 (At
; the Foot of the MegaTree, RoomFootOfMegaTree); up Room 6 (Entrance to Hades,
; RoomEntranceToHades); down Room 45 (Under the Drive, RoomUnderTheDrive). Odd:
; the down exit of Room 6 is Room 0, not this room.
;
; Entities: slot 0: definition $15 (at $A0A8) start $12; slot 1: definition $16
; (at $A0B0) start $15; slot 2: definition $17 (at $A0B8) start $08; slot 3:
; definition $18 (at $A0C0) start $14; slot 4: definition $24 (at $A120) start
; $8F. List ends at slot 5 ($FF).
;
; Bytes $DF-$E0 hold $C0,$A0 (see RoomOffLicence).
RoomDrive:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 0:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 1:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 2:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 3:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 4:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 5:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 6:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 7:
                                       ; ................................
  DEFB $54,$00,$00,$00,$00,$00,$00,$00 ; row 8:
                                       ; ---.............................
  DEFB $AA,$00,$00,$00,$00,$00,$00,$00 ; row 9:
                                       ; ####............................
  DEFB $AA,$80,$00,$00,$00,$00,$00,$00 ; row 10:
                                       ; #####...........................
  DEFB $00,$A0,$00,$00,$00,$00,$00,$00 ; row 11:
                                       ; ....##..........................
  DEFB $00,$A8,$00,$00,$00,$00,$00,$00 ; row 12:
                                       ; ....###.........................
  DEFB $00,$AA,$00,$00,$00,$00,$00,$00 ; row 13:
                                       ; ....####........................
  DEFB $A0,$AA,$80,$00,$00,$00,$00,$00 ; row 14:
                                       ; ##..#####.......................
  DEFB $A0,$AA,$A5,$55,$55,$5A,$55,$55 ; row 15:
                                       ; ##..######------------##--------
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "            The Drive           "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on
                                           ; black
  DEFB $06,$AA,$55,$AA,$FF,$FF,$55,$AA,$55 ; tile 1 (floor): yellow on black
  DEFB $0D,$70,$07,$77,$77,$00,$3B,$0B,$7D ; tile 2 (wall): cyan on blue
  DEFB $44,$14,$2A,$14,$09,$6A,$9C,$08,$08 ; tile 3 (nasty): bright green on
                                           ; black [not used in this room]
  DEFB $05,$C0,$40,$70,$70,$0C,$74,$77,$05 ; tile 4 (ramp): cyan on black
  DEFB $42,$7B,$00,$ED,$00,$AA,$55,$AA,$55 ; tile 5 (conveyor): bright red on
                                           ; black
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $01,$A0,$5F,$02    ; direction 1 (right), address $5FA0 = row 13 column
                          ; 0, 2 cells
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $00,$C9,$5F,$07    ; direction 0 (rises to the left), lowest cell $5FC9
                          ; = row 14 column 9, 7 cells
; Border colour; then $DF-$E0, not read by any code.
  DEFB $03,$C0,$A0        ; border magenta (3); $DF-$E0 = $C0,$A0
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; item graphic (all zeros: blank)
; Exits: room numbers left, right, up, down.
  DEFB $05,$03,$06,$2D    ; left 5, right 3, up 6, down 45
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $15,$12            ; definition $15, start $12 (column 18)
  DEFB $16,$15            ; definition $16, start $15 (column 21)
  DEFB $17,$08            ; definition $17, start $08 (column 8)
  DEFB $18,$14            ; definition $18, start $14 (column 20)
  DEFB $24,$8F            ; definition $24, start $8F (column 15)
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 5 ($05): The Security Guard
;
; Format: see RoomOffLicence.
;
; Border: blue (1). Conveyor: moves Willy right, 3 cells from row 13 column 29.
; Ramp: 8 cells from row 7 column 8 up to row 0 column 1, rising to the left.
;
; Items: none in the item table.
;
; Exits: left Room 19 (The Forgotten Abbey, RoomForgottenAbbey); right Room 4
; (The Drive, RoomDrive); up Room 10 (The Front Door, RoomFrontDoor); down Room
; 6 (Entrance to Hades, RoomEntranceToHades). Odd: the up exit of Room 6 is
; Room 0, not this room.
;
; Entities: slot 0: definition $02 (at $A010) start $8E; slot 1: definition $03
; (at $A018) start $8B; slot 2: definition $03 (at $A018) start $97; slot 3:
; definition $04 (at $A020) start $91. List ends at slot 4 ($FF).
RoomSecurityGuard:
  DEFB $80,$00,$00,$00,$00,$00,$00,$00 ; row 0:
                                       ; #...............................
  DEFB $A0,$00,$00,$00,$00,$00,$00,$00 ; row 1:
                                       ; ##..............................
  DEFB $A8,$00,$00,$00,$00,$00,$00,$00 ; row 2:
                                       ; ###.............................
  DEFB $AA,$00,$00,$00,$00,$00,$00,$00 ; row 3:
                                       ; ####............................
  DEFB $AA,$80,$00,$00,$00,$00,$00,$00 ; row 4:
                                       ; #####...........................
  DEFB $AA,$A0,$00,$00,$00,$00,$00,$00 ; row 5:
                                       ; ######..........................
  DEFB $A8,$00,$00,$00,$00,$00,$00,$00 ; row 6:
                                       ; ###.............................
  DEFB $A8,$00,$00,$00,$00,$00,$00,$00 ; row 7:
                                       ; ###.............................
  DEFB $A8,$15,$54,$10,$41,$54,$15,$55 ; row 8:
                                       ; ###..------..-..-..----..-------
  DEFB $A8,$2A,$A8,$20,$82,$A8,$2A,$AA ; row 9:
                                       ; ###..######..#..#..####..#######
  DEFB $00,$00,$A8,$20,$82,$A8,$2A,$AA ; row 10:
                                       ; ........###..#..#..####..#######
  DEFB $00,$00,$A8,$20,$82,$A8,$28,$00 ; row 11:
                                       ; ........###..#..#..####..##.....
  DEFB $00,$00,$A8,$20,$82,$A8,$28,$00 ; row 12:
                                       ; ........###..#..#..####..##.....
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 13:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$2A ; row 14:
                                       ; .............................###
  DEFB $A0,$0A,$AA,$AA,$AA,$AA,$AA,$AA ; row 15:
                                       ; ##....##########################
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "       The Security Guard       "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on
                                           ; black
  DEFB $04,$FF,$FF,$AA,$55,$AA,$55,$AA,$55 ; tile 1 (floor): green on black
  DEFB $0D,$0E,$C6,$95,$B0,$36,$86,$C0,$ED ; tile 2 (wall): cyan on blue
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 3 (nasty): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
  DEFB $07,$E0,$40,$20,$10,$0E,$04,$02,$01 ; tile 4 (ramp): white on black
  DEFB $42,$6F,$00,$B7,$00,$AA,$55,$AA,$55 ; tile 5 (conveyor): bright red on
                                           ; black
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $01,$BD,$5F,$03    ; direction 1 (right), address $5FBD = row 13 column
                          ; 29, 3 cells
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $00,$E8,$5E,$08    ; direction 0 (rises to the left), lowest cell $5EE8
                          ; = row 7 column 8, 8 cells
; Border colour; then $DF-$E0, not read by any code.
  DEFB $01,$00,$00        ; border blue (1); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; item graphic (all zeros: blank)
; Exits: room numbers left, right, up, down.
  DEFB $13,$04,$0A,$06    ; left 19, right 4, up 10, down 6
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $02,$8E            ; definition $02, start $8E (column 14)
  DEFB $03,$8B            ; definition $03, start $8B (column 11)
  DEFB $03,$97            ; definition $03, start $97 (column 23)
  DEFB $04,$91            ; definition $04, start $91 (column 17)
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 6 ($06): Entrance to Hades
;
; Format: see RoomOffLicence.
;
; Border: red (2). Conveyor: none. Ramp: none.
;
; Items: none in the item table.
;
; Exits: left Room 14 (Rescue Esmerelda, RoomRescueEsmerelda); right Room 5
; (The Security Guard, RoomSecurityGuard); up Room 0 (The Off Licence,
; RoomOffLicence); down Room 0 (The Off Licence, RoomOffLicence). Odd: the
; right exit of Room 14 is Room 44, not this room; the left exit of Room 5 is
; Room 19, not this room; the left edge of the layout is walled in (no free
; cell next to it), so the left exit (byte 14) cannot be used by walking
; (inferred from the layout).
;
; Entities: slot 0: definition $10 (at $A080) start $82; slot 1: definition $11
; (at $A088) start $A4; slot 2: definition $12 (at $A090) start $C3. List ends
; at slot 3 ($FF).
RoomEntranceToHades:
  DEFB $A0,$00,$00,$00,$00,$00,$00,$00 ; row 0:
                                       ; ##..............................
  DEFB $A0,$00,$00,$00,$00,$00,$00,$00 ; row 1:
                                       ; ##..............................
  DEFB $A0,$00,$00,$15,$04,$55,$00,$00 ; row 2:
                                       ; ##...........---..-.----........
  DEFB $A0,$00,$00,$10,$44,$43,$00,$00 ; row 3:
                                       ; ##...........-..-.-.-..*........
  DEFB $A0,$00,$00,$10,$44,$54,$00,$00 ; row 4:
                                       ; ##...........-..-.-.---.........
  DEFB $A0,$00,$00,$10,$44,$40,$00,$00 ; row 5:
                                       ; ##...........-..-.-.-...........
  DEFB $A0,$00,$00,$15,$04,$55,$00,$00 ; row 6:
                                       ; ##...........---..-.----........
  DEFB $A0,$00,$00,$0C,$0C,$30,$00,$00 ; row 7:
                                       ; ##............*...*..*..........
  DEFB $A0,$00,$00,$00,$00,$00,$00,$00 ; row 8:
                                       ; ##..............................
  DEFB $A0,$01,$01,$04,$14,$15,$04,$10 ; row 9:
                                       ; ##.....-...-..-..--..---..-..-..
  DEFB $A0,$01,$45,$11,$11,$04,$11,$10 ; row 10:
                                       ; ##.....--.--.-.-.-.-..-..-.-.-..
  DEFB $A0,$01,$11,$11,$14,$04,$11,$10 ; row 11:
                                       ; ##.....-.-.-.-.-.--...-..-.-.-..
  DEFB $A0,$01,$31,$11,$11,$04,$15,$10 ; row 12:
                                       ; ##.....-.*.-.-.-.-.-..-..---.-..
  DEFB $A0,$01,$01,$04,$11,$04,$11,$15 ; row 13:
                                       ; ##.....-...-..-..-.-..-..-.-.---
  DEFB $A0,$03,$03,$0C,$33,$0C,$33,$0C ; row 14:
                                       ; ##.....*...*..*..*.*..*..*.*..*.
  DEFB $A0,$00,$00,$00,$00,$00,$00,$00 ; row 15:
                                       ; ##..............................
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "        Entrance to Hades       "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $34,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): green on
                                           ; yellow
  DEFB $A3,$A0,$14,$82,$50,$0A,$41,$28,$05 ; tile 1 (floor): magenta on green,
                                           ; flashing
  DEFB $63,$BB,$BB,$38,$BB,$BB,$BB,$83,$BB ; tile 2 (wall): bright magenta on
                                           ; green
  DEFB $32,$BF,$5C,$58,$30,$28,$58,$48,$30 ; tile 3 (nasty): red on yellow
  DEFB $07,$40,$40,$10,$10,$04,$04,$01,$01 ; tile 4 (ramp): white on black [not
                                           ; used in this room]
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 5 (conveyor): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $00,$00,$00,$00    ; no conveyor (length 0)
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $00,$C7,$5F,$00    ; no ramp (length 0); direction and address are
                          ; leftovers
; Border colour; then $DF-$E0, not read by any code.
  DEFB $02,$00,$00        ; border red (2); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; item graphic (all zeros: blank)
; Exits: room numbers left, right, up, down.
  DEFB $0E,$05,$00,$00    ; left 14, right 5, up 0, down 0
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $10,$82            ; definition $10, start $82 (column 2)
  DEFB $11,$A4            ; definition $11, start $A4 (column 4)
  DEFB $12,$C3            ; definition $12, start $C3 (column 3)
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 7 ($07): Cuckoo's Nest
;
; Format: see RoomOffLicence.
;
; Border: blue (1). Conveyor: none. Ramp: 2 cells from row 12 column 13 up to
; row 11 column 14, rising to the right.
;
; Items (from the item table at ItemRoomTable): 1, at row 7 column 15.
;
; Exits: left Room 8 (Inside the MegaTrunk, RoomInsideMegaTrunk); right Room 0
; (The Off Licence, RoomOffLicence); up Room 0 (The Off Licence,
; RoomOffLicence); down Room 2 (Under the MegaTree, RoomUnderMegaTree). Odd:
; the up exit of Room 2 is Room 0, not this room.
;
; Entities: slot 0: definition $27 (at $A138) start $90; slot 1: definition $6F
; (at $A378) start $05; slot 2: definition $3C (at $A1E0) start $A4. List ends
; at slot 3 ($FF).
RoomCuckoosNest:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 0:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 1:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 2:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 3:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 4:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 5:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 6:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 7:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 8:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 9:
                                       ; ................................
  DEFB $00,$00,$00,$00,$F0,$00,$00,$00 ; row 10:
                                       ; ................**..............
  DEFB $00,$00,$00,$01,$54,$00,$00,$00 ; row 11:
                                       ; ...............----.............
  DEFB $00,$00,$00,$05,$54,$00,$00,$00 ; row 12:
                                       ; ..............-----.............
  DEFB $AA,$AA,$AA,$A9,$54,$00,$00,$00 ; row 13:
                                       ; ###############----.............
  DEFB $00,$00,$00,$05,$50,$00,$00,$00 ; row 14:
                                       ; ..............----..............
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 15:
                                       ; ................................
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "         Cuckoo's Nest          "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on
                                           ; black
  DEFB $04,$04,$03,$C9,$D8,$30,$36,$23,$01 ; tile 1 (floor): green on black
  DEFB $16,$FF,$60,$0E,$F0,$03,$3C,$C7,$38 ; tile 2 (wall): yellow on red
  DEFB $06,$C2,$34,$0B,$44,$88,$0B,$30,$08 ; tile 3 (nasty): yellow on black
  DEFB $07,$03,$00,$0C,$00,$30,$00,$C0,$00 ; tile 4 (ramp): white on black
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 5 (conveyor): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $00,$00,$00,$00    ; no conveyor (length 0)
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $01,$8D,$5F,$02    ; direction 1 (rises to the right), lowest cell $5F8D
                          ; = row 12 column 13, 2 cells
; Border colour; then $DF-$E0, not read by any code.
  DEFB $01,$00,$00        ; border blue (1); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $20,$18,$A9,$DB,$7E,$7E,$3C,$5A ; item graphic
; Exits: room numbers left, right, up, down.
  DEFB $08,$00,$00,$02    ; left 8, right 0, up 0, down 2
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $27,$90            ; definition $27, start $90 (column 16)
  DEFB $6F,$05            ; definition $6F, start $05 (column 5)
  DEFB $3C,$A4            ; definition $3C, start $A4 (column 4)
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 8 ($08): Inside the MegaTrunk
;
; Format: see RoomOffLicence.
;
; Border: green (4). Conveyor: none. Ramp: 3 cells from row 7 column 27 up to
; row 5 column 25, rising to the left.
;
; Items: none in the item table.
;
; Exits: left Room 9 (On a Branch Over the Drive, RoomBranchOverDrive); right
; Room 7 (Cuckoo's Nest, RoomCuckoosNest); up Room 12 (Tree Top, RoomTreeTop);
; down Room 3 (At the Foot of the MegaTree, RoomFootOfMegaTree).
;
; Entities: slot 0: definition $09 (at $A048) start $02; slot 1: definition $09
; (at $A048) start $05; slot 2: definition $09 (at $A048) start $08; slot 3:
; definition $18 (at $A0C0) start $06; slot 4: definition $2C (at $A160) start
; $2C; slot 5: definition $16 (at $A0B0) start $1B; slot 6: definition $2F (at
; $A178) start $93. List ends at slot 7 ($FF).
RoomInsideMegaTrunk:
  DEFB $00,$00,$08,$00,$08,$00,$00,$00 ; row 0:
                                       ; ..........#.......#.............
  DEFB $00,$00,$08,$00,$08,$00,$00,$00 ; row 1:
                                       ; ..........#.......#.............
  DEFB $00,$00,$08,$00,$08,$00,$00,$00 ; row 2:
                                       ; ..........#.......#.............
  DEFB $00,$00,$08,$01,$40,$00,$00,$00 ; row 3:
                                       ; ..........#....--...............
  DEFB $00,$00,$09,$00,$00,$00,$00,$00 ; row 4:
                                       ; ..........#-....................
  DEFB $00,$00,$00,$00,$1A,$AA,$80,$00 ; row 5:
                                       ; .................-#######.......
  DEFB $00,$00,$00,$05,$08,$00,$00,$00 ; row 6:
                                       ; ..............--..#.............
  DEFB $AA,$AA,$A8,$00,$08,$00,$00,$00 ; row 7:
                                       ; ###########.......#.............
  DEFB $30,$C3,$09,$00,$08,$00,$00,$00 ; row 8:
                                       ; .*..*..*..#-......#.............
  DEFB $30,$C3,$08,$00,$58,$00,$00,$00 ; row 9:
                                       ; .*..*..*..#.....--#.............
  DEFB $30,$C3,$08,$00,$08,$00,$00,$00 ; row 10:
                                       ; .*..*..*..#.......#.............
  DEFB $30,$C3,$08,$05,$00,$00,$00,$00 ; row 11:
                                       ; .*..*..*..#...--................
  DEFB $30,$C3,$08,$00,$00,$00,$00,$00 ; row 12:
                                       ; .*..*..*..#.....................
  DEFB $30,$C3,$09,$00,$0A,$AA,$AA,$AA ; row 13:
                                       ; .*..*..*..#-......##############
  DEFB $30,$C3,$08,$00,$08,$00,$00,$00 ; row 14:
                                       ; .*..*..*..#.......#.............
  DEFB $30,$C3,$08,$00,$58,$00,$00,$00 ; row 15:
                                       ; .*..*..*..#.....--#.............
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "      Inside the MegaTrunk      "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on
                                           ; black
  DEFB $04,$F5,$FA,$BF,$1F,$26,$14,$22,$10 ; tile 1 (floor): green on black
  DEFB $16,$AB,$AB,$AD,$AA,$AA,$AE,$55,$55 ; tile 2 (wall): yellow on red
  DEFB $06,$6E,$74,$38,$1E,$6E,$74,$38,$1E ; tile 3 (nasty): yellow on black
  DEFB $07,$40,$00,$10,$00,$04,$00,$01,$00 ; tile 4 (ramp): white on black
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 5 (conveyor): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $00,$00,$00,$00    ; no conveyor (length 0)
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $00,$FB,$5E,$03    ; direction 0 (rises to the left), lowest cell $5EFB
                          ; = row 7 column 27, 3 cells
; Border colour; then $DF-$E0, not read by any code.
  DEFB $04,$00,$00        ; border green (4); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; item graphic (all zeros: blank)
; Exits: room numbers left, right, up, down.
  DEFB $09,$07,$0C,$03    ; left 9, right 7, up 12, down 3
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $09,$02            ; definition $09, start $02 (column 2)
  DEFB $09,$05            ; definition $09, start $05 (column 5)
  DEFB $09,$08            ; definition $09, start $08 (column 8)
  DEFB $18,$06            ; definition $18, start $06 (column 6)
  DEFB $2C,$2C            ; definition $2C, start $2C (column 12)
  DEFB $16,$1B            ; definition $16, start $1B (column 27)
  DEFB $2F,$93            ; definition $2F, start $93 (column 19)
  DEFB $FF,$00            ; end of list

; Room 9 ($09): On a Branch Over the Drive
;
; Format: see RoomOffLicence.
;
; Border: red (2). Conveyor: none. Ramp: 4 cells from row 10 column 14 up to
; row 7 column 17, rising to the right.
;
; Items (from the item table at ItemRoomTable): 1, at row 11 column 5.
;
; Exits: left Room 10 (The Front Door, RoomFrontDoor); right Room 8 (Inside the
; MegaTrunk, RoomInsideMegaTrunk); up Room 13 (Out on a limb, RoomOutOnALimb);
; down Room 4 (The Drive, RoomDrive). Odd: the up exit of Room 4 is Room 6, not
; this room.
;
; Entities: slot 0: definition $09 (at $A048) start $1E; slot 1: definition $1B
; (at $A0D8) start $87; slot 2: definition $3D (at $A1E8) start $13; slot 3:
; definition $3E (at $A1F0) start $0E; slot 4: definition $3C (at $A1E0) start
; $44. List ends at slot 5 ($FF).
RoomBranchOverDrive:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 0:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 1:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 2:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 3:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 4:
                                       ; ................................
  DEFB $00,$00,$3C,$00,$00,$00,$00,$00 ; row 5:
                                       ; .........**.....................
  DEFB $00,$00,$FD,$50,$00,$00,$00,$00 ; row 6:
                                       ; ........***---..................
  DEFB $00,$00,$3F,$C0,$05,$55,$55,$55 ; row 7:
                                       ; .........****.....--------------
  DEFB $00,$00,$00,$00,$0F,$BF,$3B,$C0 ; row 8:
                                       ; ..................**#***.*#**...
  DEFB $00,$00,$00,$00,$03,$F0,$3B,$00 ; row 9:
                                       ; ...................***...*#*....
  DEFB $00,$00,$00,$00,$00,$00,$0F,$00 ; row 10:
                                       ; ..........................**....
  DEFB $00,$00,$00,$50,$00,$00,$00,$00 ; row 11:
                                       ; ............--..................
  DEFB $00,$50,$00,$00,$00,$00,$00,$00 ; row 12:
                                       ; ....--..........................
  DEFB $00,$00,$05,$00,$00,$00,$00,$00 ; row 13:
                                       ; ..........--....................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 14:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 15:
                                       ; ................................
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "   On a Branch Over the Drive   "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $08,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on blue
  DEFB $0A,$1F,$F3,$E1,$60,$30,$2C,$40,$80 ; tile 1 (floor): red on blue
  DEFB $4A,$09,$12,$0A,$1F,$E4,$08,$08,$08 ; tile 2 (wall): bright red on blue
  DEFB $0C,$42,$29,$54,$26,$87,$23,$2A,$04 ; tile 3 (nasty): green on blue
  DEFB $0F,$05,$02,$04,$08,$50,$20,$40,$80 ; tile 4 (ramp): white on blue
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 5 (conveyor): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $00,$00,$00,$00    ; no conveyor (length 0)
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $01,$4E,$5F,$04    ; direction 1 (rises to the right), lowest cell $5F4E
                          ; = row 10 column 14, 4 cells
; Border colour; then $DF-$E0, not read by any code.
  DEFB $02,$00,$00        ; border red (2); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $30,$3C,$4F,$43,$82,$86,$E4,$FC ; item graphic
; Exits: room numbers left, right, up, down.
  DEFB $0A,$08,$0D,$04    ; left 10, right 8, up 13, down 4
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $09,$1E            ; definition $09, start $1E (column 30)
  DEFB $1B,$87            ; definition $1B, start $87 (column 7)
  DEFB $3D,$13            ; definition $3D, start $13 (column 19)
  DEFB $3E,$0E            ; definition $3E, start $0E (column 14)
  DEFB $3C,$44            ; definition $3C, start $44 (column 4)
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 10 ($0A): The Front Door
;
; Format: see RoomOffLicence.
;
; Border: red (2). Conveyor: none. Ramp: 2 cells from row 15 column 2 up to row
; 14 column 1, rising to the left.
;
; Items (from the item table at ItemRoomTable): 1, at row 4 column 11.
;
; Exits: left Room 11 (The Hall, RoomHall); right Room 9 (On a Branch Over the
; Drive, RoomBranchOverDrive); up Room 0 (The Off Licence, RoomOffLicence);
; down Room 5 (The Security Guard, RoomSecurityGuard).
;
; Entities: none. List ends at slot 0 ($FF).
RoomFrontDoor:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 0:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 1:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 2:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 3:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 4:
                                       ; ................................
  DEFB $AA,$AA,$AA,$00,$00,$00,$00,$00 ; row 5:
                                       ; ############....................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 6:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 7:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 8:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 9:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 10:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 11:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 12:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 13:
                                       ; ................................
  DEFB $40,$00,$00,$00,$00,$00,$00,$00 ; row 14:
                                       ; -...............................
  DEFB $A0,$00,$00,$00,$00,$00,$00,$00 ; row 15:
                                       ; ##..............................
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "         The Front Door         "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $28,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on cyan
  DEFB $47,$FF,$AA,$77,$AA,$77,$AA,$55,$AA ; tile 1 (floor): bright white on
                                           ; black
  DEFB $3A,$20,$10,$0E,$C1,$30,$09,$C6,$20 ; tile 2 (wall): red on white
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 3 (nasty): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
  DEFB $2F,$C0,$40,$B0,$50,$AC,$54,$AB,$55 ; tile 4 (ramp): white on cyan
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 5 (conveyor): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $00,$00,$00,$00    ; no conveyor (length 0)
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $00,$E2,$5F,$02    ; direction 0 (rises to the left), lowest cell $5FE2
                          ; = row 15 column 2, 2 cells
; Border colour; then $DF-$E0, not read by any code.
  DEFB $02,$00,$00        ; border red (2); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $0C,$1C,$1C,$1E,$1B,$3F,$78,$FF ; item graphic
; Exits: room numbers left, right, up, down.
  DEFB $0B,$09,$00,$05    ; left 11, right 9, up 0, down 5
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 11 ($0B): The Hall
;
; Format: see RoomOffLicence.
;
; Border: green (4). Conveyor: none. Ramp: 6 cells from row 13 column 5 up to
; row 8 column 0, rising to the left.
;
; Items: none in the item table.
;
; Exits: left Room 20 (Ballroom East, RoomBallroomEast); right Room 10 (The
; Front Door, RoomFrontDoor); up Room 0 (The Off Licence, RoomOffLicence); down
; Room 0 (The Off Licence, RoomOffLicence).
;
; Entities: slot 0: definition $59 (at $A2C8) start $CA; slot 1: definition $1A
; (at $A0D0) start $13; slot 2: definition $5F (at $A2F8) start $13; slot 3:
; definition $45 (at $A228) start $44; slot 4: definition $3C (at $A1E0) start
; $16. List ends at slot 5 ($FF). Ignored bytes after the end: slot 6 =
; $59,$00.
RoomHall:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 0:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 1:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 2:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 3:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 4:
                                       ; ................................
  DEFB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA ; row 5:
                                       ; ################################
  DEFB $00,$00,$00,$00,$00,$28,$00,$00 ; row 6:
                                       ; .....................##.........
  DEFB $00,$00,$00,$00,$00,$28,$00,$00 ; row 7:
                                       ; .....................##.........
  DEFB $00,$00,$00,$00,$00,$28,$00,$00 ; row 8:
                                       ; .....................##.........
  DEFB $00,$00,$00,$00,$00,$28,$00,$00 ; row 9:
                                       ; .....................##.........
  DEFB $00,$00,$00,$00,$00,$28,$00,$00 ; row 10:
                                       ; .....................##.........
  DEFB $00,$00,$00,$00,$00,$28,$00,$00 ; row 11:
                                       ; .....................##.........
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 12:
                                       ; ................................
  DEFB $00,$00,$C0,$C0,$30,$00,$00,$00 ; row 13:
                                       ; ........*...*....*..............
  DEFB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA ; row 14:
                                       ; ################################
  DEFB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA ; row 15:
                                       ; ################################
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "            The Hall            "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on
                                           ; black
  DEFB $47,$FF,$AA,$77,$AA,$77,$AA,$55,$AA ; tile 1 (floor): bright white on
                                           ; black [not used in this room]
  DEFB $3A,$20,$10,$0E,$C1,$30,$09,$C6,$20 ; tile 2 (wall): red on white
  DEFB $44,$88,$A9,$A9,$BB,$BF,$BF,$BF,$5E ; tile 3 (nasty): bright green on
                                           ; black
  DEFB $07,$C0,$C0,$30,$30,$0C,$0C,$03,$03 ; tile 4 (ramp): white on black
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 5 (conveyor): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $00,$00,$00,$00    ; no conveyor (length 0)
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $00,$A5,$5F,$06    ; direction 0 (rises to the left), lowest cell $5FA5
                          ; = row 13 column 5, 6 cells
; Border colour; then $DF-$E0, not read by any code.
  DEFB $04,$00,$00        ; border green (4); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; item graphic (all zeros: blank)
; Exits: room numbers left, right, up, down.
  DEFB $14,$0A,$00,$00    ; left 20, right 10, up 0, down 0
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $59,$CA            ; definition $59, start $CA (column 10)
  DEFB $1A,$13            ; definition $1A, start $13 (column 19)
  DEFB $5F,$13            ; definition $5F, start $13 (column 19)
  DEFB $45,$44            ; definition $45, start $44 (column 4)
  DEFB $3C,$16            ; definition $3C, start $16 (column 22)
  DEFB $FF,$00            ; end of list
  DEFB $59,$00            ; ignored (after the end of the list)
  DEFB $00,$00            ; empty

; Room 12 ($0C): Tree Top
;
; Format: see RoomOffLicence.
;
; Border: yellow (6). Conveyor: none. Ramp: 2 cells from row 14 column 15 up to
; row 13 column 14, rising to the left.
;
; Items (from the item table at ItemRoomTable): 3, at row 3 column 16; row 4
; column 22; row 13 column 19.
;
; Exits: left Room 13 (Out on a limb, RoomOutOnALimb); right Room 0 (The Off
; Licence, RoomOffLicence); up Room 0 (The Off Licence, RoomOffLicence); down
; Room 8 (Inside the MegaTrunk, RoomInsideMegaTrunk).
;
; Entities: slot 0: definition $18 (at $A0C0) start $07; slot 1: definition $2E
; (at $A170) start $88; slot 2: definition $1A (at $A0D0) start $18; slot 3:
; definition $45 (at $A228) start $84. List ends at slot 4 ($FF).
RoomTreeTop:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 0:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 1:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 2:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 3:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 4:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 5:
                                       ; ................................
  DEFB $00,$00,$00,$00,$40,$00,$00,$00 ; row 6:
                                       ; ................-...............
  DEFB $00,$00,$54,$00,$00,$00,$00,$00 ; row 7:
                                       ; ........---.....................
  DEFB $00,$00,$00,$14,$00,$04,$00,$00 ; row 8:
                                       ; .............--.......-.........
  DEFB $01,$50,$00,$00,$14,$00,$00,$00 ; row 9:
                                       ; ...---...........--.............
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 10:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$14,$00,$00 ; row 11:
                                       ; .....................--.........
  DEFB $55,$55,$54,$00,$08,$00,$00,$00 ; row 12:
                                       ; -----------.......#.............
  DEFB $0C,$F3,$C8,$10,$08,$00,$50,$00 ; row 13:
                                       ; ..*.**.**.#..-....#.....--......
  DEFB $CF,$3F,$08,$00,$08,$50,$00,$00 ; row 14:
                                       ; *.**.***..#.......#.--..........
  DEFB $30,$30,$08,$00,$58,$00,$00,$00 ; row 15:
                                       ; .*...*....#.....--#.............
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "            Tree Top            "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on
                                           ; black
  DEFB $04,$AA,$55,$AA,$58,$30,$10,$10,$08 ; tile 1 (floor): green on black
  DEFB $16,$A5,$28,$52,$55,$55,$49,$A2,$B5 ; tile 2 (wall): yellow on red
  DEFB $42,$89,$4A,$12,$34,$18,$34,$52,$91 ; tile 3 (nasty): bright red on
                                           ; black
  DEFB $07,$40,$00,$10,$00,$04,$00,$01,$00 ; tile 4 (ramp): white on black
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 5 (conveyor): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $00,$00,$00,$00    ; no conveyor (length 0)
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $00,$CF,$5F,$02    ; direction 0 (rises to the left), lowest cell $5FCF
                          ; = row 14 column 15, 2 cells
; Border colour; then $DF-$E0, not read by any code.
  DEFB $06,$00,$00        ; border yellow (6); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $1E,$2D,$37,$7B,$6D,$5E,$B8,$C0 ; item graphic
; Exits: room numbers left, right, up, down.
  DEFB $0D,$00,$00,$08    ; left 13, right 0, up 0, down 8
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $18,$07            ; definition $18, start $07 (column 7)
  DEFB $2E,$88            ; definition $2E, start $88 (column 8)
  DEFB $1A,$18            ; definition $1A, start $18 (column 24)
  DEFB $45,$84            ; definition $45, start $84 (column 4)
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 13 ($0D): Out on a limb
;
; Format: see RoomOffLicence.
;
; Border: cyan (5). Conveyor: none. Ramp: none.
;
; Items (from the item table at ItemRoomTable): 2, at row 1 column 5; row 6
; column 2.
;
; Exits: left Room 10 (The Front Door, RoomFrontDoor); right Room 12 (Tree Top,
; RoomTreeTop); up Room 0 (The Off Licence, RoomOffLicence); down Room 9 (On a
; Branch Over the Drive, RoomBranchOverDrive). Odd: the right exit of Room 10
; is Room 9, not this room.
;
; Entities: slot 0: definition $2D (at $A168) start $4C; slot 1: definition $19
; (at $A0C8) start $13; slot 2: definition $58 (at $A2C0) start $14. List ends
; at slot 3 ($FF).
RoomOutOnALimb:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 0:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 1:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 2:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 3:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 4:
                                       ; ................................
  DEFB $00,$00,$00,$04,$00,$00,$00,$00 ; row 5:
                                       ; ..............-.................
  DEFB $00,$10,$00,$00,$04,$01,$00,$00 ; row 6:
                                       ; .....-............-....-........
  DEFB $00,$00,$04,$00,$00,$00,$00,$00 ; row 7:
                                       ; ..........-.....................
  DEFB $00,$00,$00,$00,$00,$00,$10,$00 ; row 8:
                                       ; .........................-......
  DEFB $00,$00,$00,$01,$00,$40,$00,$00 ; row 9:
                                       ; ...............-....-...........
  DEFB $04,$00,$00,$04,$40,$00,$00,$00 ; row 10:
                                       ; ..-...........-.-...............
  DEFB $00,$04,$00,$01,$10,$00,$00,$00 ; row 11:
                                       ; ......-........-.-..............
  DEFB $00,$00,$01,$00,$4A,$AA,$AA,$AA ; row 12:
                                       ; ...........-....-.##############
  DEFB $01,$00,$00,$00,$00,$7F,$FF,$00 ; row 13:
                                       ; ...-................-*******....
  DEFB $00,$00,$40,$00,$40,$1F,$FC,$00 ; row 14:
                                       ; ........-.......-....-*****.....
  DEFB $00,$00,$00,$40,$00,$01,$50,$00 ; row 15:
                                       ; ............-..........---......
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "        Out on a limb           "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on
                                           ; black
  DEFB $04,$01,$1E,$06,$7A,$1A,$E8,$68,$A0 ; tile 1 (floor): green on black
  DEFB $42,$07,$FF,$FC,$38,$18,$10,$20,$00 ; tile 2 (wall): bright red on black
  DEFB $02,$01,$81,$06,$58,$20,$40,$88,$82 ; tile 3 (nasty): red on black
  DEFB $04,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 4 (ramp): green on black [not
                                           ; used in this room]
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 5 (conveyor): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $00,$00,$00,$00    ; no conveyor (length 0)
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $01,$00,$00,$00    ; no ramp (length 0); direction and address are
                          ; leftovers
; Border colour; then $DF-$E0, not read by any code.
  DEFB $05,$00,$00        ; border cyan (5); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $60,$B8,$BE,$5D,$5A,$35,$2A,$15 ; item graphic
; Exits: room numbers left, right, up, down.
  DEFB $0A,$0C,$00,$09    ; left 10, right 12, up 0, down 9
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $2D,$4C            ; definition $2D, start $4C (column 12)
  DEFB $19,$13            ; definition $19, start $13 (column 19)
  DEFB $58,$14            ; definition $58, start $14 (column 20)
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 14 ($0E): Rescue Esmerelda
;
; Format: see RoomOffLicence.
;
; Border: blue (1). Conveyor: moves Willy right, 4 cells from row 4 column 24.
; Ramp: none.
;
; Items (from the item table at ItemRoomTable): 2, at row 2 column 26; row 3
; column 26.
;
; Exits: left Room 15 (I'm sure I've seen this before.., RoomSeenThisBefore);
; right Room 44 (On top of the house, RoomTopOfTheHouse); up Room 20 (Ballroom
; East, RoomBallroomEast); down Room 39 (Emergency Generator,
; RoomEmergencyGenerator). Odd: the down exit of Room 20 is Room 0, not this
; room.
;
; Entities: slot 0: definition $04 (at $A020) start $C4; slot 1: definition $02
; (at $A010) start $CC; slot 2: definition $0D (at $A068) start $05; slot 3:
; definition $0F (at $A078) start $98. List ends at slot 4 ($FF).
RoomRescueEsmerelda:
  DEFB $00,$00,$00,$00,$00,$00,$08,$02 ; row 0:
                                       ; ..........................#....#
  DEFB $00,$00,$00,$00,$00,$00,$08,$02 ; row 1:
                                       ; ..........................#....#
  DEFB $00,$00,$00,$00,$00,$00,$00,$02 ; row 2:
                                       ; ...............................#
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 3:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$AA,$00 ; row 4:
                                       ; ........................####....
  DEFB $00,$00,$00,$00,$00,$00,$08,$06 ; row 5:
                                       ; ..........................#...-#
  DEFB $00,$00,$00,$00,$00,$00,$00,$12 ; row 6:
                                       ; .............................-.#
  DEFB $00,$00,$00,$00,$00,$00,$00,$42 ; row 7:
                                       ; ............................-..#
  DEFB $00,$00,$00,$00,$00,$00,$01,$02 ; row 8:
                                       ; ...........................-...#
  DEFB $AA,$06,$AA,$06,$AA,$0A,$AA,$06 ; row 9:
                                       ; ####..-#####..-#####..######..-#
  DEFB $AA,$0E,$AA,$0E,$AA,$00,$00,$06 ; row 10:
                                       ; ####..*#####..*#####..........-#
  DEFB $AA,$0E,$AA,$0E,$AA,$00,$00,$06 ; row 11:
                                       ; ####..*#####..*#####..........-#
  DEFB $AA,$0E,$AA,$0E,$AA,$80,$00,$12 ; row 12:
                                       ; ####..*#####..*######........-.#
  DEFB $AA,$0E,$AA,$0E,$AA,$A0,$00,$40 ; row 13:
                                       ; ####..*#####..*#######......-...
  DEFB $AA,$0E,$AA,$0E,$AA,$A8,$01,$00 ; row 14:
                                       ; ####..*#####..*########....-....
  DEFB $AA,$AA,$AA,$AA,$AA,$AA,$04,$0A ; row 15:
                                       ; ########################..-...##
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "        Rescue Esmerelda        "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $10,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on red
  DEFB $17,$03,$03,$0C,$0C,$31,$32,$C4,$C8 ; tile 1 (floor): white on red
  DEFB $04,$EE,$00,$BB,$00,$EE,$00,$BB,$00 ; tile 2 (wall): green on black
  DEFB $55,$D1,$E2,$C4,$C8,$D1,$E2,$C4,$C8 ; tile 3 (nasty): bright cyan on red
  DEFB $17,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 4 (ramp): white on red [not
                                           ; used in this room]
  DEFB $16,$F1,$AA,$F8,$AA,$00,$EE,$00,$BB ; tile 5 (conveyor): yellow on red
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $01,$98,$5E,$04    ; direction 1 (right), address $5E98 = row 4 column
                          ; 24, 4 cells
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $01,$00,$00,$00    ; no ramp (length 0); direction and address are
                          ; leftovers
; Border colour; then $DF-$E0, not read by any code.
  DEFB $01,$00,$00        ; border blue (1); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $FF,$49,$49,$49,$49,$49,$49,$FF ; item graphic
; Exits: room numbers left, right, up, down.
  DEFB $0F,$2C,$14,$27    ; left 15, right 44, up 20, down 39
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $04,$C4            ; definition $04, start $C4 (column 4)
  DEFB $02,$CC            ; definition $02, start $CC (column 12)
  DEFB $0D,$05            ; definition $0D, start $05 (column 5)
  DEFB $0F,$98            ; definition $0F, start $98 (column 24)
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 15 ($0F): I'm sure I've seen this before..
;
; Format: see RoomOffLicence.
;
; Border: magenta (3). Conveyor: none. Ramp: none.
;
; Items (from the item table at ItemRoomTable): 1, at row 4 column 31.
;
; Exits: left Room 16 (We must perform a Quirkafleeg, RoomQuirkafleeg); right
; Room 14 (Rescue Esmerelda, RoomRescueEsmerelda); up Room 0 (The Off Licence,
; RoomOffLicence); down Room 0 (The Off Licence, RoomOffLicence).
;
; Entities: slot 0: definition $04 (at $A020) start $85; slot 1: definition $03
; (at $A018) start $8B; slot 2: definition $05 (at $A028) start $93; slot 3:
; definition $02 (at $A010) start $99; slot 4: definition $0D (at $A068) start
; $06; slot 5: definition $45 (at $A228) start $64; slot 6: definition $3C (at
; $A1E0) start $54. List ends at slot 7 ($FF).
RoomSeenThisBefore:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 0:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 1:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 2:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 3:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 4:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 5:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 6:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 7:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 8:
                                       ; ................................
  DEFB $AA,$42,$A4,$2A,$A4,$2A,$42,$AA ; row 9:
                                       ; ####-..###-..#####-..###-..#####
  DEFB $AA,$C2,$AC,$2A,$AC,$2A,$C2,$AA ; row 10:
                                       ; ####*..###*..#####*..###*..#####
  DEFB $AA,$C2,$AC,$2A,$AC,$2A,$C2,$AA ; row 11:
                                       ; ####*..###*..#####*..###*..#####
  DEFB $AA,$C2,$AC,$2A,$AC,$2A,$C2,$AA ; row 12:
                                       ; ####*..###*..#####*..###*..#####
  DEFB $AA,$C2,$AC,$2A,$AC,$2A,$C2,$AA ; row 13:
                                       ; ####*..###*..#####*..###*..#####
  DEFB $AA,$C2,$AC,$2A,$AC,$2A,$C2,$AA ; row 14:
                                       ; ####*..###*..#####*..###*..#####
  DEFB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA ; row 15:
                                       ; ################################
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "I'm sure I've seen this before.."
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $08,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on blue
  DEFB $0C,$80,$40,$20,$50,$48,$54,$52,$55 ; tile 1 (floor): green on blue
  DEFB $53,$66,$66,$66,$00,$66,$66,$66,$66 ; tile 2 (wall): bright magenta on
                                           ; red
  DEFB $4C,$51,$55,$54,$55,$15,$55,$45,$55 ; tile 3 (nasty): bright green on
                                           ; blue
  DEFB $0C,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 4 (ramp): green on blue [not
                                           ; used in this room]
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 5 (conveyor): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $00,$00,$00,$00    ; no conveyor (length 0)
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $00,$00,$00,$00    ; no ramp (length 0)
; Border colour; then $DF-$E0, not read by any code.
  DEFB $03,$00,$00        ; border magenta (3); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $18,$24,$18,$2C,$5E,$5E,$E7,$66 ; item graphic
; Exits: room numbers left, right, up, down.
  DEFB $10,$0E,$00,$00    ; left 16, right 14, up 0, down 0
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $04,$85            ; definition $04, start $85 (column 5)
  DEFB $03,$8B            ; definition $03, start $8B (column 11)
  DEFB $05,$93            ; definition $05, start $93 (column 19)
  DEFB $02,$99            ; definition $02, start $99 (column 25)
  DEFB $0D,$06            ; definition $0D, start $06 (column 6)
  DEFB $45,$64            ; definition $45, start $64 (column 4)
  DEFB $3C,$54            ; definition $3C, start $54 (column 20)
  DEFB $FF,$00            ; end of list

; Room 16 ($10): We must perform a Quirkafleeg
;
; Format: see RoomOffLicence.
;
; Border: red (2). Conveyor: none. Ramp: 1 cells from row 9 column 4 up to row
; 9 column 4, rising to the left.
;
; Items (from the item table at ItemRoomTable): 1, at row 4 column 31.
;
; Exits: left Room 17 (Up on the Battlements, RoomBattlements); right Room 15
; (I'm sure I've seen this before.., RoomSeenThisBefore); up Room 50 (Watch
; Tower, RoomWatchTower); down Room 0 (The Off Licence, RoomOffLicence).
;
; Entities: slot 0: definition $0D (at $A068) start $08; slot 1: definition $01
; (at $A008) start $10; slot 2: definition $3C (at $A1E0) start $84. List ends
; at slot 3 ($FF).
RoomQuirkafleeg:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 0:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 1:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 2:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 3:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 4:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 5:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 6:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 7:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 8:
                                       ; ................................
  DEFB $AA,$00,$00,$00,$00,$00,$02,$AA ; row 9:
                                       ; ####.......................#####
  DEFB $AA,$40,$00,$00,$00,$00,$02,$AA ; row 10:
                                       ; ####-......................#####
  DEFB $AA,$40,$00,$00,$00,$00,$02,$AA ; row 11:
                                       ; ####-......................#####
  DEFB $AA,$40,$00,$00,$00,$00,$02,$AA ; row 12:
                                       ; ####-......................#####
  DEFB $AA,$40,$00,$00,$00,$00,$02,$AA ; row 13:
                                       ; ####-......................#####
  DEFB $AA,$40,$00,$00,$00,$00,$02,$AA ; row 14:
                                       ; ####-......................#####
  DEFB $AA,$7F,$FF,$FF,$FF,$FF,$FE,$AA ; row 15:
                                       ; ####-**********************#####
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "  We must perform a Quirkafleeg "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $06,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): yellow on
                                           ; black
  DEFB $38,$33,$BB,$DD,$CC,$55,$99,$DD,$EE ; tile 1 (floor): black on white
  DEFB $0D,$27,$F6,$00,$DC,$D1,$04,$77,$80 ; tile 2 (wall): cyan on blue
  DEFB $45,$40,$E4,$4E,$44,$44,$44,$EE,$FF ; tile 3 (nasty): bright cyan on
                                           ; black
  DEFB $07,$80,$40,$20,$30,$A8,$64,$22,$11 ; tile 4 (ramp): white on black
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 5 (conveyor): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $00,$00,$00,$00    ; no conveyor (length 0)
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $00,$24,$5F,$01    ; direction 0 (rises to the left), lowest cell $5F24
                          ; = row 9 column 4, 1 cells
; Border colour; then $DF-$E0, not read by any code.
  DEFB $02,$00,$00        ; border red (2); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $18,$24,$18,$2C,$5E,$5E,$E7,$66 ; item graphic
; Exits: room numbers left, right, up, down.
  DEFB $11,$0F,$32,$00    ; left 17, right 15, up 50, down 0
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $0D,$08            ; definition $0D, start $08 (column 8)
  DEFB $01,$10            ; definition $01, start $10 (column 16)
  DEFB $3C,$84            ; definition $3C, start $84 (column 4)
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 17 ($11): Up on the Battlements
;
; Format: see RoomOffLicence.
;
; Border: blue (1). Conveyor: moves Willy left, 5 cells from row 9 column 13.
; Ramp: none.
;
; Items (from the item table at ItemRoomTable): 1, at row 4 column 31.
;
; Exits: left Room 18 (On the Roof, RoomOnTheRoof); right Room 16 (We must
; perform a Quirkafleeg, RoomQuirkafleeg); up Room 0 (The Off Licence,
; RoomOffLicence); down Room 0 (The Off Licence, RoomOffLicence).
;
; Entities: slot 0: definition $02 (at $A010) start $85; slot 1: definition $03
; (at $A018) start $8B; slot 2: definition $04 (at $A020) start $93; slot 3:
; definition $05 (at $A028) start $99; slot 4: definition $45 (at $A228) start
; $84. List ends at slot 5 ($FF).
RoomBattlements:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 0:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 1:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 2:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 3:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 4:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 5:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 6:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 7:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 8:
                                       ; ................................
  DEFB $AA,$42,$A4,$2A,$A4,$2A,$42,$AA ; row 9:
                                       ; ####-..###-..#####-..###-..#####
  DEFB $AA,$C2,$AC,$2A,$AC,$2A,$C2,$AA ; row 10:
                                       ; ####*..###*..#####*..###*..#####
  DEFB $AA,$C2,$AC,$2A,$AC,$2A,$C2,$AA ; row 11:
                                       ; ####*..###*..#####*..###*..#####
  DEFB $AA,$C2,$AC,$2A,$AC,$2A,$C2,$AA ; row 12:
                                       ; ####*..###*..#####*..###*..#####
  DEFB $AA,$C2,$AC,$2A,$AC,$2A,$C2,$AA ; row 13:
                                       ; ####*..###*..#####*..###*..#####
  DEFB $AA,$C2,$AC,$2A,$AC,$2A,$C2,$AA ; row 14:
                                       ; ####*..###*..#####*..###*..#####
  DEFB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA ; row 15:
                                       ; ################################
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "      Up on the Battlements     "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on
                                           ; black
  DEFB $04,$80,$C0,$E0,$B0,$90,$94,$D6,$77 ; tile 1 (floor): green on black
  DEFB $0E,$00,$7F,$7F,$63,$6B,$63,$7F,$7F ; tile 2 (wall): yellow on blue
  DEFB $20,$4A,$2A,$1A,$48,$6C,$6A,$29,$88 ; tile 3 (nasty): black on green
  DEFB $04,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 4 (ramp): green on black [not
                                           ; used in this room]
  DEFB $42,$28,$AA,$0A,$00,$55,$55,$55,$FF ; tile 5 (conveyor): bright red on
                                           ; black
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $00,$2D,$5F,$05    ; direction 0 (left), address $5F2D = row 9 column
                          ; 13, 5 cells
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $00,$00,$00,$00    ; no ramp (length 0)
; Border colour; then $DF-$E0, not read by any code.
  DEFB $01,$00,$00        ; border blue (1); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $18,$24,$18,$2C,$5E,$5E,$E7,$66 ; item graphic
; Exits: room numbers left, right, up, down.
  DEFB $12,$10,$00,$00    ; left 18, right 16, up 0, down 0
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $02,$85            ; definition $02, start $85 (column 5)
  DEFB $03,$8B            ; definition $03, start $8B (column 11)
  DEFB $04,$93            ; definition $04, start $93 (column 19)
  DEFB $05,$99            ; definition $05, start $99 (column 25)
  DEFB $45,$84            ; definition $45, start $84 (column 4)
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 18 ($12): On the Roof
;
; Format: see RoomOffLicence.
;
; Border: red (2). Conveyor: moves Willy right, 8 cells from row 15 column 14.
; Ramp: none.
;
; Items (from the item table at ItemRoomTable): 1, at row 12 column 25.
;
; Exits: left Room 48 (Nomen Luni, RoomNomenLuni); right Room 17 (Up on the
; Battlements, RoomBattlements); up Room 18 (On the Roof, RoomOnTheRoof); down
; Room 0 (The Off Licence, RoomOffLicence). Odd: the up exit leads back to this
; room.
;
; Entities: slot 0: definition $22 (at $A110) start $16; slot 1: definition $01
; (at $A008) start $10. List ends at slot 2 ($FF).
RoomOnTheRoof:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 0:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 1:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 2:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 3:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 4:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 5:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 6:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$0A,$40 ; row 7:
                                       ; ..........................##-...
  DEFB $00,$00,$00,$00,$00,$00,$0A,$D0 ; row 8:
                                       ; ..........................##*-..
  DEFB $AA,$40,$00,$00,$00,$00,$0A,$AA ; row 9:
                                       ; ####-.....................######
  DEFB $AA,$C0,$00,$00,$00,$00,$0A,$AA ; row 10:
                                       ; ####*.....................######
  DEFB $AA,$C0,$00,$00,$00,$00,$0A,$AA ; row 11:
                                       ; ####*.....................######
  DEFB $AA,$90,$00,$00,$00,$00,$0A,$AA ; row 12:
                                       ; #####-....................######
  DEFB $AA,$B0,$00,$00,$00,$00,$0A,$AA ; row 13:
                                       ; #####*....................######
  DEFB $AA,$B0,$0A,$40,$00,$00,$0A,$AA ; row 14:
                                       ; #####*....##-.............######
  DEFB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA ; row 15:
                                       ; ################################
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "          On the Roof           "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $44,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): bright green
                                           ; on black
  DEFB $07,$80,$C0,$E0,$D0,$58,$9C,$DE,$CD ; tile 1 (floor): white on black
  DEFB $26,$11,$F8,$07,$08,$F0,$0F,$D0,$3F ; tile 2 (wall): yellow on green
  DEFB $46,$55,$99,$DD,$CC,$55,$99,$DD,$CC ; tile 3 (nasty): bright yellow on
                                           ; black
  DEFB $07,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 4 (ramp): white on black [not
                                           ; used in this room]
  DEFB $0A,$F0,$F0,$F0,$FF,$FF,$00,$00,$FF ; tile 5 (conveyor): red on blue
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $01,$EE,$5F,$08    ; direction 1 (right), address $5FEE = row 15 column
                          ; 14, 8 cells
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $00,$00,$00,$00    ; no ramp (length 0)
; Border colour; then $DF-$E0, not read by any code.
  DEFB $02,$00,$00        ; border red (2); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $01,$02,$05,$0A,$54,$28,$30,$48 ; item graphic
; Exits: room numbers left, right, up, down.
  DEFB $30,$11,$12,$00    ; left 48, right 17, up 18, down 0
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $22,$16            ; definition $22, start $16 (column 22)
  DEFB $01,$10            ; definition $01, start $10 (column 16)
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 19 ($13): The Forgotten Abbey
;
; Format: see RoomOffLicence.
;
; Border: blue (1). Conveyor: moves Willy left, 26 cells from row 7 column 4.
; Ramp: 2 cells from row 14 column 4 up to row 13 column 3, rising to the left.
;
; Items (from the item table at ItemRoomTable): 1, at row 3 column 2.
;
; Exits: left Room 49 (The Wine Cellar, RoomWineCellar); right Room 5 (The
; Security Guard, RoomSecurityGuard); up Room 0 (The Off Licence,
; RoomOffLicence); down Room 0 (The Off Licence, RoomOffLicence).
;
; Entities: slot 0: definition $4A (at $A250) start $08; slot 1: definition $4B
; (at $A258) start $10; slot 2: definition $4C (at $A260) start $0B; slot 3:
; definition $4D (at $A268) start $18; slot 4: definition $4E (at $A270) start
; $07; slot 5: definition $4F (at $A278) start $0C; slot 6: definition $50 (at
; $A280) start $12; slot 7: definition $51 (at $A288) start $18. All 8 slots
; are used, so the list ends at $8140.
RoomForgottenAbbey:
  DEFB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA ; row 0:
                                       ; ################################
  DEFB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA ; row 1:
                                       ; ################################
  DEFB $A0,$00,$30,$00,$C0,$00,$C0,$0A ; row 2:
                                       ; ##.......*......*.......*.....##
  DEFB $A0,$00,$00,$00,$00,$00,$00,$0A ; row 3:
                                       ; ##............................##
  DEFB $A0,$00,$00,$00,$00,$00,$00,$0A ; row 4:
                                       ; ##............................##
  DEFB $A8,$00,$00,$00,$00,$00,$00,$0A ; row 5:
                                       ; ###...........................##
  DEFB $A0,$00,$00,$00,$00,$00,$00,$0A ; row 6:
                                       ; ##............................##
  DEFB $A0,$00,$00,$00,$00,$00,$00,$0A ; row 7:
                                       ; ##............................##
  DEFB $A0,$00,$00,$00,$30,$00,$00,$0A ; row 8:
                                       ; ##...............*............##
  DEFB $A0,$00,$00,$00,$00,$00,$00,$1A ; row 9:
                                       ; ##...........................-##
  DEFB $A5,$00,$00,$00,$00,$00,$00,$0A ; row 10:
                                       ; ##--..........................##
  DEFB $50,$05,$55,$55,$55,$55,$55,$5A ; row 11:
                                       ; --....------------------------##
  DEFB $50,$00,$00,$00,$00,$00,$00,$0A ; row 12:
                                       ; --............................##
  DEFB $A8,$00,$00,$00,$00,$00,$00,$00 ; row 13:
                                       ; ###.............................
  DEFB $AA,$00,$00,$00,$00,$00,$00,$00 ; row 14:
                                       ; ####............................
  DEFB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA ; row 15:
                                       ; ################################
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "      The Forgotten Abbey       "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on
                                           ; black
  DEFB $04,$FF,$FF,$F2,$24,$40,$02,$00,$88 ; tile 1 (floor): green on black
  DEFB $1D,$44,$AA,$11,$44,$11,$AA,$44,$11 ; tile 2 (wall): cyan on magenta
  DEFB $42,$18,$3C,$7E,$99,$99,$7E,$42,$3C ; tile 3 (nasty): bright red on
                                           ; black
  DEFB $07,$80,$40,$E0,$30,$A8,$D4,$22,$89 ; tile 4 (ramp): white on black
  DEFB $0F,$70,$55,$00,$BB,$AA,$AA,$AA,$AA ; tile 5 (conveyor): white on blue
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $00,$E4,$5E,$1A    ; direction 0 (left), address $5EE4 = row 7 column 4,
                          ; 26 cells
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $00,$C4,$5F,$02    ; direction 0 (rises to the left), lowest cell $5FC4
                          ; = row 14 column 4, 2 cells
; Border colour; then $DF-$E0, not read by any code.
  DEFB $01,$00,$00        ; border blue (1); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $18,$24,$DB,$DB,$24,$18,$18,$18 ; item graphic
; Exits: room numbers left, right, up, down.
  DEFB $31,$05,$00,$00    ; left 49, right 5, up 0, down 0
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $4A,$08            ; definition $4A, start $08 (column 8)
  DEFB $4B,$10            ; definition $4B, start $10 (column 16)
  DEFB $4C,$0B            ; definition $4C, start $0B (column 11)
  DEFB $4D,$18            ; definition $4D, start $18 (column 24)
  DEFB $4E,$07            ; definition $4E, start $07 (column 7)
  DEFB $4F,$0C            ; definition $4F, start $0C (column 12)
  DEFB $50,$12            ; definition $50, start $12 (column 18)
  DEFB $51,$18            ; definition $51, start $18 (column 24)

; Room 20 ($14): Ballroom East
;
; Format: see RoomOffLicence.
;
; Border: red (2). Conveyor: none. Ramp: none.
;
; Items: none in the item table. The room nevertheless has an item graphic
; (leftover: never drawn).
;
; Exits: left Room 21 (Ballroom West, RoomBallroomWest); right Room 11 (The
; Hall, RoomHall); up Room 26 (East Wall Base, RoomEastWallBase); down Room 0
; (The Off Licence, RoomOffLicence).
;
; Entities: slot 0: definition $13 (at $A098) start $6C; slot 1: definition $2A
; (at $A150) start $05; slot 2: definition $28 (at $A140) start $07; slot 3:
; definition $29 (at $A148) start $2B; slot 4: definition $15 (at $A0A8) start
; $18. List ends at slot 5 ($FF).
RoomBallroomEast:
  DEFB $A0,$40,$0A,$00,$00,$00,$00,$00 ; row 0:
                                       ; ##..-.....##....................
  DEFB $A0,$40,$0A,$00,$00,$00,$00,$00 ; row 1:
                                       ; ##..-.....##....................
  DEFB $A0,$40,$0A,$00,$00,$00,$00,$00 ; row 2:
                                       ; ##..-.....##....................
  DEFB $00,$40,$00,$00,$00,$00,$00,$00 ; row 3:
                                       ; ....-...........................
  DEFB $00,$40,$00,$00,$00,$00,$00,$00 ; row 4:
                                       ; ....-...........................
  DEFB $55,$55,$5A,$0A,$AA,$AA,$AA,$AA ; row 5:
                                       ; ----------##..##################
  DEFB $00,$00,$10,$00,$00,$00,$00,$00 ; row 6:
                                       ; .........-......................
  DEFB $00,$00,$10,$00,$00,$00,$00,$00 ; row 7:
                                       ; .........-......................
  DEFB $00,$00,$15,$55,$55,$55,$55,$55 ; row 8:
                                       ; .........-----------------------
  DEFB $00,$00,$10,$00,$00,$00,$00,$00 ; row 9:
                                       ; .........-......................
  DEFB $00,$00,$10,$00,$00,$00,$00,$00 ; row 10:
                                       ; .........-......................
  DEFB $00,$00,$10,$00,$00,$00,$00,$00 ; row 11:
                                       ; .........-......................
  DEFB $00,$00,$10,$00,$00,$00,$00,$00 ; row 12:
                                       ; .........-......................
  DEFB $00,$00,$10,$00,$00,$00,$00,$00 ; row 13:
                                       ; .........-......................
  DEFB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA ; row 14:
                                       ; ################################
  DEFB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA ; row 15:
                                       ; ################################
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "         Ballroom East          "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on
                                           ; black
  DEFB $06,$AA,$55,$22,$44,$22,$44,$22,$44 ; tile 1 (floor): yellow on black
  DEFB $0F,$44,$44,$FF,$11,$11,$FF,$55,$AA ; tile 2 (wall): white on blue
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 3 (nasty): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 4 (ramp): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 5 (conveyor): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $00,$00,$00,$00    ; no conveyor (length 0)
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $00,$00,$00,$00    ; no ramp (length 0)
; Border colour; then $DF-$E0, not read by any code.
  DEFB $02,$00,$00        ; border red (2); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $81,$81,$42,$24,$18,$18,$18,$E7 ; item graphic
; Exits: room numbers left, right, up, down.
  DEFB $15,$0B,$1A,$00    ; left 21, right 11, up 26, down 0
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $13,$6C            ; definition $13, start $6C (column 12)
  DEFB $2A,$05            ; definition $2A, start $05 (column 5)
  DEFB $28,$07            ; definition $28, start $07 (column 7)
  DEFB $29,$2B            ; definition $29, start $2B (column 11)
  DEFB $15,$18            ; definition $15, start $18 (column 24)
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 21 ($15): Ballroom West
;
; Format: see RoomOffLicence.
;
; Border: blue (1). Conveyor: moves Willy right, 12 cells from row 13 column
; 16. Ramp: 4 cells from row 13 column 3 up to row 10 column 0, rising to the
; left.
;
; Items (from the item table at ItemRoomTable): 7, at row 12 columns 17, 18,
; 20, 22, 23, 25, 27.
;
; Exits: left Room 22 (To the Kitchens    Main Stairway, RoomMainStairway);
; right Room 20 (Ballroom East, RoomBallroomEast); up Room 27 (The Chapel,
; RoomChapel); down Room 0 (The Off Licence, RoomOffLicence).
;
; Entities: slot 0: definition $21 (at $A108) start $18; slot 1: definition $28
; (at $A140) start $0E; slot 2: definition $2A (at $A150) start $06. List ends
; at slot 3 ($FF).
RoomBallroomWest:
  DEFB $00,$00,$00,$00,$00,$00,$00,$0A ; row 0:
                                       ; ..............................##
  DEFB $00,$00,$00,$00,$00,$00,$00,$0A ; row 1:
                                       ; ..............................##
  DEFB $00,$00,$00,$00,$00,$00,$00,$0A ; row 2:
                                       ; ..............................##
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 3:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 4:
                                       ; ................................
  DEFB $55,$55,$55,$55,$55,$55,$55,$55 ; row 5:
                                       ; --------------------------------
  DEFB $00,$00,$A0,$00,$00,$00,$00,$00 ; row 6:
                                       ; ........##......................
  DEFB $00,$00,$A0,$00,$00,$00,$00,$00 ; row 7:
                                       ; ........##......................
  DEFB $00,$00,$A0,$00,$00,$00,$55,$55 ; row 8:
                                       ; ........##..............--------
  DEFB $00,$00,$A0,$00,$00,$00,$00,$00 ; row 9:
                                       ; ........##......................
  DEFB $00,$00,$A0,$00,$00,$00,$00,$00 ; row 10:
                                       ; ........##......................
  DEFB $00,$00,$A0,$00,$00,$00,$00,$00 ; row 11:
                                       ; ........##......................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 12:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 13:
                                       ; ................................
  DEFB $55,$55,$55,$55,$55,$55,$55,$55 ; row 14:
                                       ; --------------------------------
  DEFB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA ; row 15:
                                       ; ################################
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "         Ballroom West          "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on
                                           ; black
  DEFB $32,$AA,$A8,$AD,$AF,$20,$AA,$55,$55 ; tile 1 (floor): red on yellow
  DEFB $23,$11,$22,$88,$11,$44,$88,$22,$44 ; tile 2 (wall): magenta on green
  DEFB $42,$28,$54,$AA,$54,$A8,$54,$14,$2E ; tile 3 (nasty): bright red on
                                           ; black [not used in this room]
  DEFB $07,$C0,$C0,$30,$B0,$0C,$0C,$03,$0B ; tile 4 (ramp): white on black
  DEFB $46,$FF,$FF,$FF,$AA,$55,$18,$18,$18 ; tile 5 (conveyor): bright yellow
                                           ; on black
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $01,$B0,$5F,$0C    ; direction 1 (right), address $5FB0 = row 13 column
                          ; 16, 12 cells
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $00,$A3,$5F,$04    ; direction 0 (rises to the left), lowest cell $5FA3
                          ; = row 13 column 3, 4 cells
; Border colour; then $DF-$E0, not read by any code.
  DEFB $01,$00,$00        ; border blue (1); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $04,$04,$AE,$AE,$A2,$42,$42,$EE ; item graphic
; Exits: room numbers left, right, up, down.
  DEFB $16,$14,$1B,$00    ; left 22, right 20, up 27, down 0
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $21,$18            ; definition $21, start $18 (column 24)
  DEFB $28,$0E            ; definition $28, start $0E (column 14)
  DEFB $2A,$06            ; definition $2A, start $06 (column 6)
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 22 ($16): To the Kitchens    Main Stairway
;
; Format: see RoomOffLicence.
;
; Border: green (4). Conveyor: moves Willy left, 2 cells from row 8 column 14.
; Ramp: 12 cells from row 11 column 31 up to row 0 column 20, rising to the
; left.
;
; Items (from the item table at ItemRoomTable): 2, at row 6 column 9; row 9
; column 2.
;
; Exits: left Room 23 (The Kitchen, RoomKitchen); right Room 21 (Ballroom West,
; RoomBallroomWest); up Room 28 (First Landing, RoomFirstLanding); down Room 0
; (The Off Licence, RoomOffLicence).
;
; Entities: slot 0: definition $5A (at $A2D0) start $04; slot 1: definition $5B
; (at $A2D8) start $10; slot 2: definition $5C (at $A2E0) start $96; slot 3:
; definition $5D (at $A2E8) start $04; slot 4: definition $5E (at $A2F0) start
; $96; slot 5: definition $5F (at $A2F8) start $0B. List ends at slot 6 ($FF).
RoomMainStairway:
  DEFB $00,$00,$80,$00,$00,$00,$00,$00 ; row 0:
                                       ; ........#.......................
  DEFB $00,$00,$80,$00,$00,$00,$00,$00 ; row 1:
                                       ; ........#.......................
  DEFB $00,$00,$80,$00,$00,$00,$00,$00 ; row 2:
                                       ; ........#.......................
  DEFB $00,$00,$00,$00,$00,$00,$03,$00 ; row 3:
                                       ; ...........................*....
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 4:
                                       ; ................................
  DEFB $00,$01,$95,$55,$55,$50,$00,$55 ; row 5:
                                       ; .......-#-------------......----
  DEFB $00,$00,$80,$00,$00,$00,$00,$00 ; row 6:
                                       ; ........#.......................
  DEFB $00,$00,$80,$00,$00,$00,$00,$00 ; row 7:
                                       ; ........#.......................
  DEFB $A5,$55,$85,$00,$00,$00,$00,$00 ; row 8:
                                       ; ##------#.--....................
  DEFB $A0,$00,$80,$00,$00,$00,$55,$40 ; row 9:
                                       ; ##......#...............-----...
  DEFB $A0,$00,$80,$00,$01,$40,$00,$00 ; row 10:
                                       ; ##......#..........--...........
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 11:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 12:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 13:
                                       ; ................................
  DEFB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA ; row 14:
                                       ; ################################
  DEFB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA ; row 15:
                                       ; ################################
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "To the Kitchens    Main Stairway"
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $08,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on blue
  DEFB $0D,$FF,$FF,$00,$FF,$00,$00,$00,$00 ; tile 1 (floor): cyan on blue
  DEFB $3A,$00,$15,$BF,$15,$00,$51,$FB,$51 ; tile 2 (wall): red on white
  DEFB $4D,$18,$5A,$BD,$19,$7E,$99,$24,$24 ; tile 3 (nasty): bright cyan on
                                           ; blue
  DEFB $0F,$C0,$80,$30,$20,$0C,$08,$03,$02 ; tile 4 (ramp): white on blue
  DEFB $6B,$F0,$AA,$78,$FF,$AA,$55,$AA,$55 ; tile 5 (conveyor): bright magenta
                                           ; on cyan
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $00,$0E,$5F,$02    ; direction 0 (left), address $5F0E = row 8 column
                          ; 14, 2 cells
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $00,$7F,$5F,$0C    ; direction 0 (rises to the left), lowest cell $5F7F
                          ; = row 11 column 31, 12 cells
; Border colour; then $DF-$E0, not read by any code.
  DEFB $04,$00,$00        ; border green (4); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $40,$A0,$F0,$F8,$FC,$7A,$25,$02 ; item graphic
; Exits: room numbers left, right, up, down.
  DEFB $17,$15,$1C,$00    ; left 23, right 21, up 28, down 0
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $5A,$04            ; definition $5A, start $04 (column 4)
  DEFB $5B,$10            ; definition $5B, start $10 (column 16)
  DEFB $5C,$96            ; definition $5C, start $96 (column 22)
  DEFB $5D,$04            ; definition $5D, start $04 (column 4)
  DEFB $5E,$96            ; definition $5E, start $96 (column 22)
  DEFB $5F,$0B            ; definition $5F, start $0B (column 11)
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty

; Room 23 ($17): The Kitchen
;
; Format: see RoomOffLicence.
;
; Border: green (4). Conveyor: none. Ramp: 7 cells from row 14 column 22 up to
; row 8 column 28, rising to the right.
;
; Items: none in the item table. The room nevertheless has an item graphic
; (leftover: never drawn).
;
; Exits: left Room 24 (West of Kitchen, RoomWestOfKitchen); right Room 22 (To
; the Kitchens    Main Stairway, RoomMainStairway); up Room 0 (The Off Licence,
; RoomOffLicence); down Room 0 (The Off Licence, RoomOffLicence).
;
; Entities: slot 0: definition $30 (at $A180) start $03; slot 1: definition $31
; (at $A188) start $09; slot 2: definition $32 (at $A190) start $0F; slot 3:
; definition $30 (at $A180) start $14. List ends at slot 4 ($FF).
RoomKitchen:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 0:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 1:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 2:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 3:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 4:
                                       ; ................................
  DEFB $54,$15,$41,$50,$00,$00,$00,$00 ; row 5:
                                       ; ---..----..---..................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 6:
                                       ; ................................
  DEFB $00,$00,$00,$00,$04,$00,$00,$00 ; row 7:
                                       ; ..................-.............
  DEFB $54,$15,$40,$00,$00,$00,$00,$2A ; row 8:
                                       ; ---..----....................###
  DEFB $00,$00,$01,$50,$00,$00,$00,$AA ; row 9:
                                       ; ...........---..............####
  DEFB $00,$00,$00,$00,$00,$00,$02,$AA ; row 10:
                                       ; ...........................#####
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 11:
                                       ; ................................
  DEFB $54,$15,$41,$50,$00,$00,$00,$00 ; row 12:
                                       ; ---..----..---..................
  DEFB $00,$00,$00,$00,$15,$00,$00,$00 ; row 13:
                                       ; .................---............
  DEFB $00,$00,$00,$00,$00,$02,$AA,$AA ; row 14:
                                       ; .......................#########
  DEFB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA ; row 15:
                                       ; ################################
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "          The Kitchen           "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on
                                           ; black
  DEFB $04,$FE,$01,$7D,$85,$81,$81,$81,$01 ; tile 1 (floor): green on black
  DEFB $4D,$42,$A5,$5A,$24,$24,$5A,$A5,$42 ; tile 2 (wall): bright cyan on blue
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 3 (nasty): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
  DEFB $47,$03,$00,$0C,$00,$30,$00,$C0,$00 ; tile 4 (ramp): bright white on
                                           ; black
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 5 (conveyor): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $00,$00,$00,$00    ; no conveyor (length 0)
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $01,$D6,$5F,$07    ; direction 1 (rises to the right), lowest cell $5FD6
                          ; = row 14 column 22, 7 cells
; Border colour; then $DF-$E0, not read by any code.
  DEFB $04,$00,$00        ; border green (4); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $20,$40,$A0,$18,$16,$09,$08,$04 ; item graphic
; Exits: room numbers left, right, up, down.
  DEFB $18,$16,$00,$00    ; left 24, right 22, up 0, down 0
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $30,$03            ; definition $30, start $03 (column 3)
  DEFB $31,$09            ; definition $31, start $09 (column 9)
  DEFB $32,$0F            ; definition $32, start $0F (column 15)
  DEFB $30,$14            ; definition $30, start $14 (column 20)
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 24 ($18): West of Kitchen
;
; Format: see RoomOffLicence.
;
; Border: blue (1). Conveyor: moves Willy left, 5 cells from row 12 column 22.
; Ramp: 7 cells from row 14 column 8 up to row 8 column 2, rising to the left.
;
; Items: none in the item table.
;
; Exits: left Room 25 (Cold Store, RoomColdStore); right Room 23 (The Kitchen,
; RoomKitchen); up Room 30 (The Banyan Tree, RoomBanyanTree); down Room 0 (The
; Off Licence, RoomOffLicence).
;
; Entities: slot 0: definition $31 (at $A188) start $09; slot 1: definition $32
; (at $A190) start $0E; slot 2: definition $31 (at $A188) start $14; slot 3:
; definition $30 (at $A180) start $1B. List ends at slot 4 ($FF).
;
; Odd: tile 5 (conveyor) has attribute $42, which first occurs at tile-area
; offset 15 (inside tile 1), so BuildRoomBuffers draws it with the 8 bytes
; after that offset instead of its own pixels (observed in the $7000 buffer).
RoomWestOfKitchen:
  DEFB $00,$00,$01,$00,$00,$00,$00,$00 ; row 0:
                                       ; ...........-....................
  DEFB $00,$00,$01,$00,$00,$00,$00,$00 ; row 1:
                                       ; ...........-....................
  DEFB $00,$00,$01,$00,$00,$00,$00,$00 ; row 2:
                                       ; ...........-....................
  DEFB $00,$00,$01,$00,$00,$00,$00,$00 ; row 3:
                                       ; ...........-....................
  DEFB $00,$00,$01,$00,$00,$00,$00,$00 ; row 4:
                                       ; ...........-....................
  DEFB $00,$00,$01,$00,$10,$05,$54,$15 ; row 5:
                                       ; ...........-.....-....-----..---
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 6:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 7:
                                       ; ................................
  DEFB $A0,$00,$00,$00,$00,$04,$00,$15 ; row 8:
                                       ; ##....................-......---
  DEFB $A8,$00,$00,$00,$15,$00,$50,$00 ; row 9:
                                       ; ###..............---....--......
  DEFB $AA,$00,$00,$50,$00,$00,$00,$00 ; row 10:
                                       ; ####........--..................
  DEFB $AA,$80,$00,$00,$00,$00,$00,$00 ; row 11:
                                       ; #####...........................
  DEFB $AA,$A0,$00,$00,$15,$05,$54,$15 ; row 12:
                                       ; ######...........---..-----..---
  DEFB $AA,$A8,$00,$00,$00,$00,$00,$00 ; row 13:
                                       ; #######.........................
  DEFB $AA,$AA,$00,$00,$00,$00,$00,$00 ; row 14:
                                       ; ########........................
  DEFB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA ; row 15:
                                       ; ################################
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "    West of Kitchen             "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on
                                           ; black
  DEFB $05,$FF,$BD,$A5,$A5,$A5,$42,$00,$00 ; tile 1 (floor): cyan on black
  DEFB $22,$09,$42,$90,$24,$09,$42,$90,$24 ; tile 2 (wall): red on green
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 3 (nasty): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
  DEFB $47,$C0,$40,$B0,$50,$AC,$54,$AB,$55 ; tile 4 (ramp): bright white on
                                           ; black
  DEFB $42,$F0,$55,$AA,$55,$55,$AA,$2A,$08 ; tile 5 (conveyor): bright red on
                                           ; black
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $00,$96,$5F,$05    ; direction 0 (left), address $5F96 = row 12 column
                          ; 22, 5 cells
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $00,$C8,$5F,$07    ; direction 0 (rises to the left), lowest cell $5FC8
                          ; = row 14 column 8, 7 cells
; Border colour; then $DF-$E0, not read by any code.
  DEFB $01,$00,$00        ; border blue (1); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; item graphic (all zeros: blank)
; Exits: room numbers left, right, up, down.
  DEFB $19,$17,$1E,$00    ; left 25, right 23, up 30, down 0
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $31,$09            ; definition $31, start $09 (column 9)
  DEFB $32,$0E            ; definition $32, start $0E (column 14)
  DEFB $31,$14            ; definition $31, start $14 (column 20)
  DEFB $30,$1B            ; definition $30, start $1B (column 27)
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 25 ($19): Cold Store
;
; Format: see RoomOffLicence.
;
; Border: blue (1). Conveyor: none. Ramp: none.
;
; Items (from the item table at ItemRoomTable): 4, at row 2 column 3; row 5
; column 8; row 8 column 6; row 11 column 6.
;
; Exits: left Room 52 (Back Stairway, RoomBackStairway); right Room 24 (West of
; Kitchen, RoomWestOfKitchen); up Room 31 (Swimming Pool, RoomSwimmingPool);
; down Room 0 (The Off Licence, RoomOffLicence). Odd: the down exit of Room 31
; is Room 0, not this room.
;
; Entities: slot 0: definition $36 (at $A1B0) start $10; slot 1: definition $37
; (at $A1B8) start $04; slot 2: definition $38 (at $A1C0) start $03; slot 3:
; definition $39 (at $A1C8) start $08; slot 4: definition $01 (at $A008) start
; $10. List ends at slot 5 ($FF).
RoomColdStore:
  DEFB $00,$03,$00,$00,$00,$00,$00,$00 ; row 0:
                                       ; .......*........................
  DEFB $00,$00,$00,$30,$00,$00,$C0,$00 ; row 1:
                                       ; .............*..........*.......
  DEFB $54,$00,$00,$00,$00,$00,$00,$00 ; row 2:
                                       ; ---.............................
  DEFB $00,$00,$00,$00,$00,$C0,$03,$00 ; row 3:
                                       ; ....................*......*....
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 4:
                                       ; ................................
  DEFB $55,$55,$00,$00,$00,$00,$00,$00 ; row 5:
                                       ; --------........................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 6:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 7:
                                       ; ................................
  DEFB $55,$50,$00,$00,$00,$00,$0A,$AA ; row 8:
                                       ; ------....................######
  DEFB $00,$00,$00,$00,$00,$00,$0A,$AA ; row 9:
                                       ; ..........................######
  DEFB $00,$00,$00,$00,$00,$00,$0A,$AA ; row 10:
                                       ; ..........................######
  DEFB $55,$50,$00,$00,$00,$00,$0A,$AA ; row 11:
                                       ; ------....................######
  DEFB $00,$00,$30,$00,$00,$14,$0A,$AA ; row 12:
                                       ; .........*...........--...######
  DEFB $00,$00,$00,$00,$00,$00,$0A,$AA ; row 13:
                                       ; ..........................######
  DEFB $00,$00,$00,$00,$00,$00,$0A,$AA ; row 14:
                                       ; ..........................######
  DEFB $55,$55,$55,$55,$55,$55,$5A,$AA ; row 15:
                                       ; --------------------------######
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "           Cold Store           "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $0E,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): yellow on
                                           ; blue
  DEFB $0D,$FF,$FF,$55,$AA,$55,$AA,$00,$00 ; tile 1 (floor): cyan on blue
  DEFB $22,$92,$52,$4A,$49,$29,$25,$A4,$92 ; tile 2 (wall): red on green
  DEFB $4F,$20,$22,$14,$D8,$1B,$28,$44,$04 ; tile 3 (nasty): bright white on
                                           ; blue
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 4 (ramp): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 5 (conveyor): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $00,$00,$00,$00    ; no conveyor (length 0)
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $00,$00,$00,$00    ; no ramp (length 0)
; Border colour; then $DF-$E0, not read by any code.
  DEFB $01,$00,$00        ; border blue (1); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $70,$8C,$72,$FA,$EF,$AD,$25,$21 ; item graphic
; Exits: room numbers left, right, up, down.
  DEFB $34,$18,$1F,$00    ; left 52, right 24, up 31, down 0
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $36,$10            ; definition $36, start $10 (column 16)
  DEFB $37,$04            ; definition $37, start $04 (column 4)
  DEFB $38,$03            ; definition $38, start $03 (column 3)
  DEFB $39,$08            ; definition $39, start $08 (column 8)
  DEFB $01,$10            ; definition $01, start $10 (column 16)
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 26 ($1A): East Wall Base
;
; Format: see RoomOffLicence.
;
; Border: cyan (5). Conveyor: none. Ramp: none.
;
; Items: none in the item table.
;
; Exits: left Room 27 (The Chapel, RoomChapel); right Room 0 (The Off Licence,
; RoomOffLicence); up Room 32 (Halfway up the East Wall, RoomHalfwayEastWall);
; down Room 20 (Ballroom East, RoomBallroomEast). Odd: the left edge of the
; layout is walled in (no free cell next to it), so the left exit (byte 27)
; cannot be used by walking (inferred from the layout).
;
; Entities: slot 0: definition $60 (at $A300) start $03; slot 1: definition $2D
; (at $A168) start $27. List ends at slot 2 ($FF).
RoomEastWallBase:
  DEFB $A0,$00,$0A,$00,$00,$00,$00,$00 ; row 0:
                                       ; ##........##....................
  DEFB $A0,$00,$0A,$00,$00,$00,$00,$00 ; row 1:
                                       ; ##........##....................
  DEFB $A0,$00,$0A,$00,$00,$00,$00,$00 ; row 2:
                                       ; ##........##....................
  DEFB $A0,$00,$0A,$00,$00,$00,$00,$00 ; row 3:
                                       ; ##........##....................
  DEFB $A0,$00,$1A,$00,$00,$00,$00,$00 ; row 4:
                                       ; ##.......-##....................
  DEFB $A0,$04,$0A,$00,$00,$00,$00,$00 ; row 5:
                                       ; ##....-...##....................
  DEFB $A0,$00,$0A,$00,$00,$00,$00,$00 ; row 6:
                                       ; ##........##....................
  DEFB $A4,$00,$0A,$00,$00,$00,$00,$00 ; row 7:
                                       ; ##-.......##....................
  DEFB $A0,$04,$00,$00,$00,$00,$00,$00 ; row 8:
                                       ; ##....-.........................
  DEFB $A0,$00,$00,$00,$00,$00,$00,$00 ; row 9:
                                       ; ##..............................
  DEFB $A0,$00,$1A,$00,$00,$00,$00,$00 ; row 10:
                                       ; ##.......-##....................
  DEFB $A0,$10,$0A,$00,$00,$00,$00,$00 ; row 11:
                                       ; ##...-....##....................
  DEFB $A0,$00,$0A,$00,$00,$00,$00,$00 ; row 12:
                                       ; ##........##....................
  DEFB $A0,$04,$0A,$00,$00,$00,$00,$00 ; row 13:
                                       ; ##....-...##....................
  DEFB $A0,$00,$1A,$00,$00,$00,$00,$00 ; row 14:
                                       ; ##.......-##....................
  DEFB $A0,$40,$0A,$00,$00,$00,$00,$00 ; row 15:
                                       ; ##..-.....##....................
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "         East Wall Base         "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on
                                           ; black
  DEFB $05,$5B,$A4,$A4,$55,$0A,$00,$00,$00 ; tile 1 (floor): cyan on black
  DEFB $26,$59,$25,$26,$D9,$29,$D6,$54,$96 ; tile 2 (wall): yellow on green
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 3 (nasty): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 4 (ramp): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 5 (conveyor): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $00,$00,$00,$00    ; no conveyor (length 0)
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $00,$00,$00,$00    ; no ramp (length 0)
; Border colour; then $DF-$E0, not read by any code.
  DEFB $05,$00,$00        ; border cyan (5); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; item graphic (all zeros: blank)
; Exits: room numbers left, right, up, down.
  DEFB $1B,$00,$20,$14    ; left 27, right 0, up 32, down 20
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $60,$03            ; definition $60, start $03 (column 3)
  DEFB $2D,$27            ; definition $2D, start $27 (column 7)
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 27 ($1B): The Chapel
;
; Format: see RoomOffLicence.
;
; Border: red (2). Conveyor: none. Ramp: 7 cells from row 13 column 17 up to
; row 7 column 23, rising to the right.
;
; Items (from the item table at ItemRoomTable): 1, at row 6 column 29.
;
; Exits: left Room 28 (First Landing, RoomFirstLanding); right Room 26 (East
; Wall Base, RoomEastWallBase); up Room 33 (The Bathroom, RoomBathroom); down
; Room 21 (Ballroom West, RoomBallroomWest). Odd: the right edge of the layout
; is walled in (no free cell next to it), so the right exit (byte 26) cannot be
; used by walking (inferred from the layout).
;
; Entities: slot 0: definition $10 (at $A080) start $99; slot 1: definition $11
; (at $A088) start $BB; slot 2: definition $12 (at $A090) start $DA; slot 3:
; definition $67 (at $A338) start $0C; slot 4: definition $64 (at $A320) start
; $06; slot 5: definition $66 (at $A330) start $91. List ends at slot 6 ($FF).
RoomChapel:
  DEFB $00,$00,$00,$00,$00,$00,$00,$0A ; row 0:
                                       ; ..............................##
  DEFB $00,$00,$00,$00,$00,$00,$00,$0A ; row 1:
                                       ; ..............................##
  DEFB $00,$00,$00,$00,$00,$00,$00,$0A ; row 2:
                                       ; ..............................##
  DEFB $00,$00,$00,$00,$00,$00,$00,$0A ; row 3:
                                       ; ..............................##
  DEFB $00,$00,$00,$00,$00,$00,$00,$0A ; row 4:
                                       ; ..............................##
  DEFB $00,$00,$00,$00,$00,$00,$00,$0A ; row 5:
                                       ; ..............................##
  DEFB $00,$00,$00,$00,$00,$00,$00,$0A ; row 6:
                                       ; ..............................##
  DEFB $00,$00,$00,$00,$00,$00,$80,$1A ; row 7:
                                       ; ........................#....-##
  DEFB $00,$00,$00,$00,$00,$02,$80,$1A ; row 8:
                                       ; .......................##....-##
  DEFB $00,$00,$00,$00,$00,$0A,$80,$1A ; row 9:
                                       ; ......................###....-##
  DEFB $00,$00,$00,$00,$00,$2A,$80,$1A ; row 10:
                                       ; .....................####....-##
  DEFB $00,$00,$00,$00,$00,$AA,$80,$1A ; row 11:
                                       ; ....................#####....-##
  DEFB $00,$00,$00,$00,$00,$00,$00,$1A ; row 12:
                                       ; .............................-##
  DEFB $00,$00,$00,$00,$00,$00,$00,$1A ; row 13:
                                       ; .............................-##
  DEFB $AA,$AA,$AA,$AA,$AA,$AA,$A0,$AA ; row 14:
                                       ; ##########################..####
  DEFB $AA,$AA,$AA,$AA,$AA,$AA,$A0,$AA ; row 15:
                                       ; ##########################..####
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "           The Chapel           "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on
                                           ; black
  DEFB $0D,$49,$49,$49,$49,$49,$49,$49,$49 ; tile 1 (floor): cyan on blue
  DEFB $16,$A8,$25,$00,$25,$A8,$40,$DD,$40 ; tile 2 (wall): yellow on red
  DEFB $42,$28,$54,$AA,$55,$AA,$28,$28,$28 ; tile 3 (nasty): bright red on
                                           ; black [not used in this room]
  DEFB $07,$03,$00,$0C,$00,$30,$00,$C0,$00 ; tile 4 (ramp): white on black
  DEFB $07,$00,$0A,$BD,$FF,$00,$AA,$55,$AA ; tile 5 (conveyor): white on black
                                           ; [not used in this room]
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $00,$00,$00,$00    ; no conveyor (length 0)
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $01,$B1,$5F,$07    ; direction 1 (rises to the right), lowest cell $5FB1
                          ; = row 13 column 17, 7 cells
; Border colour; then $DF-$E0, not read by any code.
  DEFB $02,$00,$00        ; border red (2); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $10,$30,$38,$6C,$C6,$C6,$6C,$10 ; item graphic
; Exits: room numbers left, right, up, down.
  DEFB $1C,$1A,$21,$15    ; left 28, right 26, up 33, down 21
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $10,$99            ; definition $10, start $99 (column 25)
  DEFB $11,$BB            ; definition $11, start $BB (column 27)
  DEFB $12,$DA            ; definition $12, start $DA (column 26)
  DEFB $67,$0C            ; definition $67, start $0C (column 12)
  DEFB $64,$06            ; definition $64, start $06 (column 6)
  DEFB $66,$91            ; definition $66, start $91 (column 17)
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty

; Room 28 ($1C): First Landing
;
; Format: see RoomOffLicence.
;
; Border: magenta (3). Conveyor: none. Ramp: 15 cells from row 14 column 9 up
; to row 0 column 23, rising to the right.
;
; Items (from the item table at ItemRoomTable): 1, at row 3 column 26. The item
; graphic of this room is all zeros, so the item cells show nothing but their
; colour (inferred from UpdateItems, not run).
;
; Exits: left Room 29 (The Nightmare Room, RoomNightmareRoom); right Room 27
; (The Chapel, RoomChapel); up Room 34 (Top Landing, RoomTopLanding); down Room
; 22 (To the Kitchens    Main Stairway, RoomMainStairway).
;
; Entities: slot 0: definition $43 (at $A218) start $19. List ends at slot 1
; ($FF).
RoomFirstLanding:
  DEFB $A0,$00,$00,$00,$00,$00,$A0,$00 ; row 0:
                                       ; ##......................##......
  DEFB $A0,$00,$00,$00,$00,$00,$A0,$00 ; row 1:
                                       ; ##......................##......
  DEFB $A0,$00,$00,$00,$00,$00,$A0,$00 ; row 2:
                                       ; ##......................##......
  DEFB $A0,$00,$00,$00,$00,$00,$A0,$30 ; row 3:
                                       ; ##......................##...*..
  DEFB $A0,$00,$00,$00,$00,$00,$A0,$FC ; row 4:
                                       ; ##......................##..***.
  DEFB $A0,$00,$00,$00,$00,$00,$A0,$30 ; row 5:
                                       ; ##......................##...*..
  DEFB $A0,$00,$00,$00,$00,$00,$A0,$30 ; row 6:
                                       ; ##......................##...*..
  DEFB $A0,$00,$00,$00,$00,$00,$A0,$30 ; row 7:
                                       ; ##......................##...*..
  DEFB $A0,$00,$00,$00,$00,$00,$A0,$00 ; row 8:
                                       ; ##......................##......
  DEFB $A0,$00,$00,$00,$00,$00,$A0,$00 ; row 9:
                                       ; ##......................##......
  DEFB $A0,$00,$00,$00,$00,$00,$A0,$00 ; row 10:
                                       ; ##......................##......
  DEFB $A0,$00,$00,$00,$00,$00,$A0,$00 ; row 11:
                                       ; ##......................##......
  DEFB $A0,$00,$00,$00,$00,$00,$00,$00 ; row 12:
                                       ; ##..............................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 13:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$99,$99 ; row 14:
                                       ; ........................#-#-#-#-
  DEFB $55,$55,$55,$55,$55,$50,$AA,$AA ; row 15:
                                       ; ----------------------..########
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "        First Landing           "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on
                                           ; black
  DEFB $04,$FF,$AA,$55,$80,$5D,$94,$5D,$80 ; tile 1 (floor): green on black
  DEFB $0E,$22,$55,$00,$55,$88,$55,$00,$22 ; tile 2 (wall): yellow on blue
  DEFB $D6,$7E,$81,$A5,$99,$99,$A5,$81,$7E ; tile 3 (nasty): bright yellow on
                                           ; red, flashing
  DEFB $07,$03,$03,$0C,$0C,$30,$30,$C0,$C0 ; tile 4 (ramp): white on black
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 5 (conveyor): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $00,$00,$00,$00    ; no conveyor (length 0)
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $01,$C9,$5F,$0F    ; direction 1 (rises to the right), lowest cell $5FC9
                          ; = row 14 column 9, 15 cells
; Border colour; then $DF-$E0, not read by any code.
  DEFB $03,$00,$00        ; border magenta (3); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; item graphic (all zeros: blank)
; Exits: room numbers left, right, up, down.
  DEFB $1D,$1B,$22,$16    ; left 29, right 27, up 34, down 22
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $43,$19            ; definition $43, start $19 (column 25)
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 29 ($1D): The Nightmare Room
;
; Format: see RoomOffLicence.
;
; Border: red (2). Conveyor: moves Willy left, 1 cells from row 7 column 27.
; Ramp: 3 cells from row 14 column 9 up to row 12 column 7, rising to the left.
;
; Items (from the item table at ItemRoomTable): 1, at row 9 column 26.
;
; Exits: left Room 30 (The Banyan Tree, RoomBanyanTree); right Room 28 (First
; Landing, RoomFirstLanding); up Room 0 (The Off Licence, RoomOffLicence); down
; Room 0 (The Off Licence, RoomOffLicence).
;
; Entities: slot 0: definition $46 (at $A230) start $88; slot 1: definition $47
; (at $A238) start $CB; slot 2: definition $48 (at $A240) start $4E; slot 3:
; definition $49 (at $A248) start $D1; slot 4: definition $46 (at $A230) start
; $94; slot 5: definition $47 (at $A238) start $97; slot 6: definition $48 (at
; $A240) start $9C. List ends at slot 7 ($FF).
;
; Odd: tile 5 (conveyor) has attribute $A5, which first occurs at tile-area
; offset 11 (inside tile 1), so BuildRoomBuffers draws it with the 8 bytes
; after that offset instead of its own pixels (observed in the $7000 buffer).
RoomNightmareRoom:
  DEFB $00,$00,$00,$00,$00,$00,$00,$0A ; row 0:
                                       ; ..............................##
  DEFB $00,$00,$00,$00,$00,$00,$00,$0A ; row 1:
                                       ; ..............................##
  DEFB $00,$00,$00,$00,$00,$00,$00,$0A ; row 2:
                                       ; ..............................##
  DEFB $00,$00,$00,$00,$00,$00,$00,$0A ; row 3:
                                       ; ..............................##
  DEFB $00,$00,$00,$00,$00,$00,$00,$0A ; row 4:
                                       ; ..............................##
  DEFB $00,$00,$04,$00,$40,$04,$00,$0A ; row 5:
                                       ; ..........-.....-.....-.......##
  DEFB $00,$00,$00,$10,$00,$00,$00,$0A ; row 6:
                                       ; .............-................##
  DEFB $00,$01,$00,$00,$01,$00,$00,$0A ; row 7:
                                       ; .......-...........-..........##
  DEFB $00,$00,$04,$00,$00,$04,$00,$0A ; row 8:
                                       ; ..........-...........-.......##
  DEFB $00,$00,$00,$10,$00,$00,$00,$0A ; row 9:
                                       ; .............-................##
  DEFB $00,$00,$00,$00,$01,$00,$04,$0A ; row 10:
                                       ; ...................-......-...##
  DEFB $00,$00,$04,$00,$00,$04,$00,$0A ; row 11:
                                       ; ..........-...........-.......##
  DEFB $AA,$A8,$00,$10,$00,$00,$00,$0A ; row 12:
                                       ; #######......-................##
  DEFB $AA,$AA,$00,$00,$00,$00,$00,$00 ; row 13:
                                       ; ########........................
  DEFB $AA,$AA,$80,$00,$00,$00,$00,$00 ; row 14:
                                       ; #########.......................
  DEFB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA ; row 15:
                                       ; ################################
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "       The Nightmare Room       "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on
                                           ; black
  DEFB $44,$FF,$A5,$52,$24,$42,$22,$40,$04 ; tile 1 (floor): bright green on
                                           ; black
  DEFB $33,$00,$2A,$54,$00,$00,$A2,$45,$00 ; tile 2 (wall): magenta on yellow
  DEFB $45,$42,$99,$66,$A1,$9F,$81,$66,$5A ; tile 3 (nasty): bright cyan on
                                           ; black [not used in this room]
  DEFB $07,$80,$C0,$A0,$F0,$F8,$5C,$BA,$02 ; tile 4 (ramp): white on black
  DEFB $A5,$FF,$5A,$FF,$FF,$AA,$55,$AA,$55 ; tile 5 (conveyor): cyan on green,
                                           ; flashing
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $00,$FB,$5E,$01    ; direction 0 (left), address $5EFB = row 7 column
                          ; 27, 1 cells
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $00,$C9,$5F,$03    ; direction 0 (rises to the left), lowest cell $5FC9
                          ; = row 14 column 9, 3 cells
; Border colour; then $DF-$E0, not read by any code.
  DEFB $02,$00,$00        ; border red (2); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $AC,$AE,$01,$AD,$AD,$02,$AC,$58 ; item graphic
; Exits: room numbers left, right, up, down.
  DEFB $1E,$1C,$00,$00    ; left 30, right 28, up 0, down 0
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $46,$88            ; definition $46, start $88 (column 8)
  DEFB $47,$CB            ; definition $47, start $CB (column 11)
  DEFB $48,$4E            ; definition $48, start $4E (column 14)
  DEFB $49,$D1            ; definition $49, start $D1 (column 17)
  DEFB $46,$94            ; definition $46, start $94 (column 20)
  DEFB $47,$97            ; definition $47, start $97 (column 23)
  DEFB $48,$9C            ; definition $48, start $9C (column 28)
  DEFB $FF,$00            ; end of list

; Room 30 ($1E): The Banyan Tree
;
; Format: see RoomOffLicence.
;
; Border: red (2). Conveyor: none. Ramp: 8 cells from row 11 column 4 up to row
; 4 column 11, rising to the right.
;
; Items (from the item table at ItemRoomTable): 1, at row 14 column 8.
;
; Exits: left Room 31 (Swimming Pool, RoomSwimmingPool); right Room 29 (The
; Nightmare Room, RoomNightmareRoom); up Room 36 (A bit of tree,
; RoomBitOfTree); down Room 24 (West of Kitchen, RoomWestOfKitchen).
;
; Entities: slot 0: definition $64 (at $A320) start $8A; slot 1: definition $65
; (at $A328) start $8D; slot 2: definition $66 (at $A330) start $10; slot 3:
; definition $58 (at $A2C0) start $16. List ends at slot 4 ($FF).
RoomBanyanTree:
  DEFB $00,$00,$00,$A0,$00,$00,$00,$00 ; row 0:
                                       ; ............##..................
  DEFB $00,$00,$00,$A0,$00,$00,$00,$00 ; row 1:
                                       ; ............##..................
  DEFB $00,$00,$00,$90,$00,$00,$00,$00 ; row 2:
                                       ; ............#-..................
  DEFB $00,$00,$00,$94,$00,$00,$00,$00 ; row 3:
                                       ; ............#--.................
  DEFB $00,$00,$00,$95,$50,$00,$00,$00 ; row 4:
                                       ; ............#-----..............
  DEFB $00,$00,$00,$81,$08,$00,$00,$00 ; row 5:
                                       ; ............#..-..#.............
  DEFB $00,$00,$00,$01,$04,$00,$00,$00 ; row 6:
                                       ; ...............-..-.............
  DEFB $00,$00,$00,$00,$04,$00,$00,$00 ; row 7:
                                       ; ..................-.............
  DEFB $00,$00,$00,$80,$00,$00,$00,$00 ; row 8:
                                       ; ............#...................
  DEFB $00,$00,$00,$82,$00,$00,$00,$00 ; row 9:
                                       ; ............#..#................
  DEFB $00,$08,$20,$82,$08,$00,$00,$00 ; row 10:
                                       ; ......#..#..#..#..#.............
  DEFB $00,$08,$20,$82,$08,$00,$00,$00 ; row 11:
                                       ; ......#..#..#..#..#.............
  DEFB $AA,$AA,$AA,$AA,$AA,$AA,$5A,$AA ; row 12:
                                       ; ########################--######
  DEFB $AA,$AA,$00,$00,$00,$00,$5A,$AA ; row 13:
                                       ; ########................--######
  DEFB $AA,$AA,$00,$00,$00,$00,$5A,$AA ; row 14:
                                       ; ########................--######
  DEFB $AA,$AA,$55,$55,$55,$55,$5A,$AA ; row 15:
                                       ; ########------------------######
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "       The Banyan Tree          "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on
                                           ; black
  DEFB $48,$00,$A2,$00,$00,$00,$46,$00,$93 ; tile 1 (floor): bright black on
                                           ; blue
  DEFB $16,$4A,$29,$25,$49,$92,$A4,$25,$94 ; tile 2 (wall): yellow on red
  DEFB $0E,$A5,$5A,$A5,$5A,$A5,$5A,$A5,$5A ; tile 3 (nasty): yellow on blue
                                           ; [not used in this room]
  DEFB $07,$03,$00,$0C,$00,$30,$00,$C0,$00 ; tile 4 (ramp): white on black
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 5 (conveyor): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $00,$00,$00,$00    ; no conveyor (length 0)
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $01,$64,$5F,$08    ; direction 1 (rises to the right), lowest cell $5F64
                          ; = row 11 column 4, 8 cells
; Border colour; then $DF-$E0, not read by any code.
  DEFB $02,$00,$00        ; border red (2); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $05,$38,$45,$82,$82,$82,$44,$38 ; item graphic
; Exits: room numbers left, right, up, down.
  DEFB $1F,$1D,$24,$18    ; left 31, right 29, up 36, down 24
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $64,$8A            ; definition $64, start $8A (column 10)
  DEFB $65,$8D            ; definition $65, start $8D (column 13)
  DEFB $66,$10            ; definition $66, start $10 (column 16)
  DEFB $58,$16            ; definition $58, start $16 (column 22)
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 31 ($1F): Swimming Pool
;
; Format: see RoomOffLicence.
;
; Border: red (2). Conveyor: none. Ramp: 3 cells from row 14 column 25 up to
; row 12 column 27, rising to the right.
;
; Items (from the item table at ItemRoomTable): 1, at row 11 column 4.
;
; Exits: left Room 54 (West  Wing, RoomWestWing); right Room 30 (The Banyan
; Tree, RoomBanyanTree); up Room 37 (Orangery, RoomOrangery); down Room 0 (The
; Off Licence, RoomOffLicence).
;
; Entities: slot 0: definition $4E (at $A270) start $0C; slot 1: definition $01
; (at $A008) start $10. List ends at slot 2 ($FF).
RoomSwimmingPool:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 0:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 1:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 2:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 3:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 4:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 5:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 6:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 7:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 8:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 9:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 10:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 11:
                                       ; ................................
  DEFB $AA,$55,$55,$55,$55,$55,$54,$AA ; row 12:
                                       ; ####-----------------------.####
  DEFB $AA,$55,$55,$55,$55,$55,$52,$AA ; row 13:
                                       ; ####----------------------.#####
  DEFB $AA,$55,$55,$55,$55,$55,$4A,$AA ; row 14:
                                       ; ####---------------------.######
  DEFB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA ; row 15:
                                       ; ################################
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "          Swimming Pool         "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $07,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): white on
                                           ; black
  DEFB $29,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 1 (floor): blue on cyan
  DEFB $3A,$44,$44,$BB,$44,$44,$44,$BB,$44 ; tile 2 (wall): red on white
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 3 (nasty): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
  DEFB $2F,$03,$03,$0F,$0F,$3F,$3F,$FF,$FF ; tile 4 (ramp): white on cyan
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 5 (conveyor): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $00,$00,$00,$00    ; no conveyor (length 0)
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $01,$D9,$5F,$03    ; direction 1 (rises to the right), lowest cell $5FD9
                          ; = row 14 column 25, 3 cells
; Border colour; then $DF-$E0, not read by any code.
  DEFB $02,$00,$00        ; border red (2); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $70,$20,$20,$50,$50,$88,$88,$88 ; item graphic
; Exits: room numbers left, right, up, down.
  DEFB $36,$1E,$25,$00    ; left 54, right 30, up 37, down 0
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $4E,$0C            ; definition $4E, start $0C (column 12)
  DEFB $01,$10            ; definition $01, start $10 (column 16)
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 32 ($20): Halfway up the East Wall
;
; Format: see RoomOffLicence.
;
; Border: red (2). Conveyor: none. Ramp: 6 cells from row 7 column 11 up to row
; 2 column 6, rising to the left.
;
; Items: none in the item table.
;
; Exits: left Room 33 (The Bathroom, RoomBathroom); right Room 0 (The Off
; Licence, RoomOffLicence); up Room 38 (Priests' Hole, RoomPriestsHole); down
; Room 26 (East Wall Base, RoomEastWallBase). Odd: the left edge of the layout
; is walled in (no free cell next to it), so the left exit (byte 33) cannot be
; used by walking (inferred from the layout).
;
; Entities: slot 0: definition $26 (at $A130) start $04. List ends at slot 1
; ($FF).
RoomHalfwayEastWall:
  DEFB $A0,$00,$0A,$00,$00,$00,$00,$00 ; row 0:
                                       ; ##........##....................
  DEFB $A0,$00,$0A,$00,$00,$00,$00,$00 ; row 1:
                                       ; ##........##....................
  DEFB $A0,$00,$0A,$00,$00,$00,$00,$00 ; row 2:
                                       ; ##........##....................
  DEFB $A0,$08,$00,$00,$00,$00,$00,$00 ; row 3:
                                       ; ##....#.........................
  DEFB $80,$0A,$00,$00,$00,$00,$00,$00 ; row 4:
                                       ; #.....##........................
  DEFB $80,$1A,$80,$00,$00,$00,$00,$00 ; row 5:
                                       ; #....-###.......................
  DEFB $A0,$00,$20,$00,$00,$00,$00,$00 ; row 6:
                                       ; ##.......#......................
  DEFB $A0,$00,$28,$00,$00,$00,$00,$00 ; row 7:
                                       ; ##.......##.....................
  DEFB $A0,$4A,$AA,$00,$00,$00,$00,$00 ; row 8:
                                       ; ##..-.######....................
  DEFB $A0,$0A,$AA,$00,$00,$00,$00,$00 ; row 9:
                                       ; ##....######....................
  DEFB $A0,$10,$0A,$00,$00,$00,$00,$00 ; row 10:
                                       ; ##...-....##....................
  DEFB $A4,$00,$0A,$00,$00,$00,$00,$00 ; row 11:
                                       ; ##-.......##....................
  DEFB $A0,$00,$0A,$00,$00,$00,$00,$00 ; row 12:
                                       ; ##........##....................
  DEFB $A0,$04,$0A,$00,$00,$00,$00,$00 ; row 13:
                                       ; ##....-...##....................
  DEFB $A0,$00,$0A,$00,$00,$00,$00,$00 ; row 14:
                                       ; ##........##....................
  DEFB $A0,$00,$1A,$00,$00,$00,$00,$00 ; row 15:
                                       ; ##.......-##....................
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "Halfway up the East Wall        "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on
                                           ; black
  DEFB $05,$FF,$FF,$5A,$99,$BD,$5A,$3C,$5A ; tile 1 (floor): cyan on black
  DEFB $0F,$33,$11,$44,$CC,$33,$11,$44,$CC ; tile 2 (wall): white on blue
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 3 (nasty): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
  DEFB $07,$80,$C0,$E0,$70,$B8,$1C,$4E,$C7 ; tile 4 (ramp): white on black
  DEFB $07,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 5 (conveyor): white on black
                                           ; [not used in this room]
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $01,$00,$00,$00    ; no conveyor (length 0); direction and address are
                          ; leftovers
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $00,$EB,$5E,$06    ; direction 0 (rises to the left), lowest cell $5EEB
                          ; = row 7 column 11, 6 cells
; Border colour; then $DF-$E0, not read by any code.
  DEFB $02,$00,$00        ; border red (2); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; item graphic (all zeros: blank)
; Exits: room numbers left, right, up, down.
  DEFB $21,$00,$26,$1A    ; left 33, right 0, up 38, down 26
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $26,$04            ; definition $26, start $04 (column 4)
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 33 ($21): The Bathroom
;
; Format: see RoomOffLicence.
;
; Border: red (2). Conveyor: moves Willy left, 4 cells from row 14 column 20.
; Ramp: 8 cells from row 12 column 9 up to row 5 column 16, rising to the
; right.
;
; Items (from the item table at ItemRoomTable): 1, at row 13 column 23.
;
; Exits: left Room 34 (Top Landing, RoomTopLanding); right Room 32 (Halfway up
; the East Wall, RoomHalfwayEastWall); up Room 39 (Emergency Generator,
; RoomEmergencyGenerator); down Room 27 (The Chapel, RoomChapel). Odd: the down
; exit of Room 39 is Room 0, not this room; the right edge of the layout is
; walled in (no free cell next to it), so the right exit (byte 32) cannot be
; used by walking (inferred from the layout).
;
; Entities: slot 0: definition $3B (at $A1D8) start $10. List ends at slot 1
; ($FF).
RoomBathroom:
  DEFB $A0,$00,$00,$00,$00,$00,$00,$0A ; row 0:
                                       ; ##............................##
  DEFB $A0,$00,$00,$00,$00,$00,$00,$0A ; row 1:
                                       ; ##............................##
  DEFB $A0,$00,$00,$00,$00,$00,$00,$0A ; row 2:
                                       ; ##............................##
  DEFB $00,$00,$00,$00,$00,$00,$00,$0A ; row 3:
                                       ; ..............................##
  DEFB $00,$00,$00,$00,$00,$00,$00,$0A ; row 4:
                                       ; ..............................##
  DEFB $55,$55,$55,$50,$25,$55,$55,$5A ; row 5:
                                       ; --------------...#------------##
  DEFB $80,$00,$00,$00,$20,$00,$00,$0A ; row 6:
                                       ; #................#............##
  DEFB $80,$00,$00,$00,$20,$00,$00,$0A ; row 7:
                                       ; #................#............##
  DEFB $80,$00,$00,$00,$20,$00,$00,$0A ; row 8:
                                       ; #................#............##
  DEFB $80,$00,$00,$00,$20,$00,$00,$0A ; row 9:
                                       ; #................#............##
  DEFB $80,$00,$00,$00,$20,$00,$00,$0A ; row 10:
                                       ; #................#............##
  DEFB $80,$00,$00,$00,$20,$00,$00,$0A ; row 11:
                                       ; #................#............##
  DEFB $80,$00,$00,$00,$20,$00,$00,$0A ; row 12:
                                       ; #................#............##
  DEFB $00,$05,$40,$00,$00,$00,$00,$0A ; row 13:
                                       ; ......---.....................##
  DEFB $00,$00,$00,$00,$00,$00,$00,$0A ; row 14:
                                       ; ..............................##
  DEFB $55,$55,$55,$55,$55,$55,$55,$5A ; row 15:
                                       ; ------------------------------##
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "          The Bathroom          "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on
                                           ; black
  DEFB $16,$00,$40,$09,$64,$92,$2D,$96,$FF ; tile 1 (floor): yellow on red
  DEFB $0E,$1F,$AA,$00,$55,$F8,$55,$00,$AA ; tile 2 (wall): yellow on blue
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 3 (nasty): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
  DEFB $07,$03,$00,$0C,$00,$30,$00,$C0,$00 ; tile 4 (ramp): white on black
  DEFB $3D,$A5,$00,$00,$00,$00,$00,$00,$FF ; tile 5 (conveyor): cyan on white
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $00,$D4,$5F,$04    ; direction 0 (left), address $5FD4 = row 14 column
                          ; 20, 4 cells
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $01,$89,$5F,$08    ; direction 1 (rises to the right), lowest cell $5F89
                          ; = row 12 column 9, 8 cells
; Border colour; then $DF-$E0, not read by any code.
  DEFB $02,$00,$00        ; border red (2); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $1F,$04,$0A,$77,$87,$B1,$AA,$0A ; item graphic
; Exits: room numbers left, right, up, down.
  DEFB $22,$20,$27,$1B    ; left 34, right 32, up 39, down 27
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $3B,$10            ; definition $3B, start $10 (column 16)
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 34 ($22): Top Landing
;
; Format: see RoomOffLicence.
;
; Border: blue (1). Conveyor: none. Ramp: 7 cells from row 11 column 17 up to
; row 5 column 23, rising to the right.
;
; Items (from the item table at ItemRoomTable): 1, at row 9 column 2.
;
; Exits: left Room 35 (Master Bedroom, RoomMasterBedroom); right Room 33 (The
; Bathroom, RoomBathroom); up Room 40 (Dr Jones will never believe this,
; RoomNeverBelieveThis); down Room 28 (First Landing, RoomFirstLanding). Odd:
; the down exit of Room 40 is Room 0, not this room.
;
; Entities: slot 0: definition $3A (at $A1D0) start $86; slot 1: definition $13
; (at $A098) start $6C; slot 2: definition $24 (at $A120) start $10. List ends
; at slot 3 ($FF).
RoomTopLanding:
  DEFB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA ; row 0:
                                       ; ################################
  DEFB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA ; row 1:
                                       ; ################################
  DEFB $A0,$00,$00,$00,$00,$00,$00,$0A ; row 2:
                                       ; ##............................##
  DEFB $A0,$00,$00,$00,$00,$00,$00,$00 ; row 3:
                                       ; ##..............................
  DEFB $A5,$50,$55,$05,$55,$55,$00,$00 ; row 4:
                                       ; ##----..----..----------........
  DEFB $A0,$00,$00,$00,$00,$00,$AA,$AA ; row 5:
                                       ; ##......................########
  DEFB $A0,$00,$00,$00,$00,$00,$00,$0A ; row 6:
                                       ; ##............................##
  DEFB $A0,$00,$00,$00,$00,$00,$00,$0A ; row 7:
                                       ; ##............................##
  DEFB $A5,$50,$55,$05,$55,$00,$00,$0A ; row 8:
                                       ; ##----..----..------..........##
  DEFB $A0,$00,$00,$00,$00,$00,$00,$0A ; row 9:
                                       ; ##............................##
  DEFB $A0,$00,$00,$00,$00,$00,$00,$0A ; row 10:
                                       ; ##............................##
  DEFB $A0,$00,$00,$00,$00,$00,$00,$0A ; row 11:
                                       ; ##............................##
  DEFB $A5,$50,$55,$05,$40,$00,$00,$0A ; row 12:
                                       ; ##----..----..---.............##
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 13:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 14:
                                       ; ................................
  DEFB $55,$55,$55,$55,$55,$05,$55,$55 ; row 15:
                                       ; --------------------..----------
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "          Top Landing           "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on
                                           ; black
  DEFB $06,$FF,$AA,$55,$FF,$00,$00,$00,$00 ; tile 1 (floor): yellow on black
  DEFB $1A,$69,$90,$90,$69,$96,$69,$69,$96 ; tile 2 (wall): red on magenta
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 3 (nasty): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
  DEFB $07,$07,$02,$3C,$08,$70,$20,$C0,$80 ; tile 4 (ramp): white on black
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 5 (conveyor): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $00,$00,$00,$00    ; no conveyor (length 0)
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $01,$71,$5F,$07    ; direction 1 (rises to the right), lowest cell $5F71
                          ; = row 11 column 17, 7 cells
; Border colour; then $DF-$E0, not read by any code.
  DEFB $01,$00,$00        ; border blue (1); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $18,$24,$A4,$CA,$95,$0A,$15,$0A ; item graphic
; Exits: room numbers left, right, up, down.
  DEFB $23,$21,$28,$1C    ; left 35, right 33, up 40, down 28
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $3A,$86            ; definition $3A, start $86 (column 6)
  DEFB $13,$6C            ; definition $13, start $6C (column 12)
  DEFB $24,$10            ; definition $24, start $10 (column 16)
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 35 ($23): Master Bedroom
;
; Format: see RoomOffLicence.
;
; Border: blue (1). Conveyor: moves Willy right, 4 cells from row 12 column 2.
; Ramp: 2 cells from row 14 column 18 up to row 13 column 17, rising to the
; left.
;
; Items: none in the item table.
;
; Exits: left Room 36 (A bit of tree, RoomBitOfTree); right Room 34 (Top
; Landing, RoomTopLanding); up Room 41 (The Attic, RoomAttic); down Room 29
; (The Nightmare Room, RoomNightmareRoom). Odd: the down exit of Room 41 is
; Room 34, not this room; the up exit of Room 29 is Room 0, not this room; the
; left edge of the layout is walled in (no free cell next to it), so the left
; exit (byte 36) cannot be used by walking (inferred from the layout).
;
; Entities: none. List ends at slot 0 ($FF).
RoomMasterBedroom:
  DEFB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA ; row 0:
                                       ; ################################
  DEFB $A0,$00,$00,$0A,$00,$00,$00,$00 ; row 1:
                                       ; ##............##................
  DEFB $A0,$00,$00,$0A,$00,$00,$00,$00 ; row 2:
                                       ; ##............##................
  DEFB $A0,$00,$00,$0A,$00,$00,$00,$00 ; row 3:
                                       ; ##............##................
  DEFB $A0,$00,$00,$0A,$00,$00,$00,$00 ; row 4:
                                       ; ##............##................
  DEFB $A0,$00,$00,$0A,$00,$00,$00,$00 ; row 5:
                                       ; ##............##................
  DEFB $A0,$00,$00,$0A,$00,$00,$00,$00 ; row 6:
                                       ; ##............##................
  DEFB $A0,$00,$00,$0A,$00,$00,$00,$00 ; row 7:
                                       ; ##............##................
  DEFB $A0,$00,$00,$0A,$00,$00,$00,$00 ; row 8:
                                       ; ##............##................
  DEFB $A0,$00,$00,$0A,$00,$00,$00,$00 ; row 9:
                                       ; ##............##................
  DEFB $A0,$00,$00,$0A,$00,$00,$00,$00 ; row 10:
                                       ; ##............##................
  DEFB $AC,$00,$00,$00,$00,$00,$00,$00 ; row 11:
                                       ; ##*.............................
  DEFB $A0,$00,$00,$00,$00,$00,$00,$00 ; row 12:
                                       ; ##..............................
  DEFB $95,$55,$55,$55,$40,$00,$00,$00 ; row 13:
                                       ; #----------------...............
  DEFB $AA,$AA,$AA,$AA,$A0,$00,$00,$00 ; row 14:
                                       ; ##################..............
  DEFB $AA,$AA,$AA,$AA,$A9,$55,$55,$55 ; row 15:
                                       ; ###################-------------
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "         Master Bedroom         "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on
                                           ; black
  DEFB $06,$FF,$6B,$B5,$00,$AD,$00,$4A,$00 ; tile 1 (floor): yellow on black
  DEFB $33,$00,$51,$FB,$51,$00,$AA,$BF,$AA ; tile 2 (wall): magenta on yellow
  DEFB $47,$00,$00,$00,$00,$7C,$FE,$7F,$3E ; tile 3 (nasty): bright white on
                                           ; black
  DEFB $07,$C0,$40,$B0,$00,$AC,$00,$53,$00 ; tile 4 (ramp): white on black
  DEFB $29,$55,$55,$55,$55,$51,$5F,$40,$AA ; tile 5 (conveyor): blue on cyan
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $01,$82,$5F,$04    ; direction 1 (right), address $5F82 = row 12 column
                          ; 2, 4 cells
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $00,$D2,$5F,$02    ; direction 0 (rises to the left), lowest cell $5FD2
                          ; = row 14 column 18, 2 cells
; Border colour; then $DF-$E0, not read by any code.
  DEFB $01,$00,$00        ; border blue (1); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; item graphic (all zeros: blank)
; Exits: room numbers left, right, up, down.
  DEFB $24,$22,$29,$1D    ; left 36, right 34, up 41, down 29
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 36 ($24): A bit of tree
;
; Format: see RoomOffLicence.
;
; Border: cyan (5). Conveyor: none. Ramp: 2 cells from row 9 column 20 up to
; row 8 column 21, rising to the right.
;
; Items: none in the item table.
;
; Exits: left Room 37 (Orangery, RoomOrangery); right Room 35 (Master Bedroom,
; RoomMasterBedroom); up Room 42 (Under the Roof, RoomUnderTheRoof); down Room
; 30 (The Banyan Tree, RoomBanyanTree).
;
; Entities: slot 0: definition $68 (at $A340) start $02; slot 1: definition $65
; (at $A328) start $07; slot 2: definition $45 (at $A228) start $92. List ends
; at slot 3 ($FF).
;
; Odd: tile 3 (nasty) has attribute $02, which first occurs at tile-area offset
; 15 (inside tile 1), so BuildRoomBuffers draws it with the 8 bytes after that
; offset instead of its own pixels (observed in the $7000 buffer).
RoomBitOfTree:
  DEFB $00,$00,$00,$A0,$00,$00,$00,$03 ; row 0:
                                       ; ............##.................*
  DEFB $00,$00,$00,$A0,$00,$00,$00,$03 ; row 1:
                                       ; ............##.................*
  DEFB $00,$00,$00,$A0,$00,$00,$00,$03 ; row 2:
                                       ; ............##.................*
  DEFB $00,$00,$00,$A0,$00,$00,$00,$03 ; row 3:
                                       ; ............##.................*
  DEFB $00,$00,$10,$A0,$00,$40,$00,$03 ; row 4:
                                       ; .........-..##......-..........*
  DEFB $00,$00,$00,$A0,$00,$00,$00,$03 ; row 5:
                                       ; ............##.................*
  DEFB $00,$14,$00,$A0,$00,$01,$40,$03 ; row 6:
                                       ; .....--.....##.........--......*
  DEFB $00,$00,$10,$A0,$00,$00,$00,$03 ; row 7:
                                       ; .........-..##.................*
  DEFB $00,$00,$00,$A0,$00,$00,$00,$03 ; row 8:
                                       ; ............##.................*
  DEFB $00,$00,$14,$A0,$00,$00,$40,$03 ; row 9:
                                       ; .........--.##..........-......*
  DEFB $55,$50,$00,$A5,$40,$00,$00,$03 ; row 10:
                                       ; ------......##---..............*
  DEFB $00,$00,$00,$A0,$00,$00,$01,$03 ; row 11:
                                       ; ............##.............-...*
  DEFB $00,$00,$00,$A0,$00,$00,$40,$03 ; row 12:
                                       ; ............##..........-......*
  DEFB $00,$00,$00,$A0,$05,$00,$00,$03 ; row 13:
                                       ; ............##....--...........*
  DEFB $00,$00,$00,$A0,$00,$00,$00,$03 ; row 14:
                                       ; ............##.................*
  DEFB $00,$00,$01,$A4,$00,$00,$00,$03 ; row 15:
                                       ; ...........-##-................*
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "    A bit of tree               "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on
                                           ; black
  DEFB $04,$AD,$52,$29,$00,$01,$02,$00,$00 ; tile 1 (floor): green on black
  DEFB $1E,$D6,$6B,$66,$DB,$69,$6B,$D9,$6D ; tile 2 (wall): yellow on magenta
  DEFB $02,$15,$00,$AA,$55,$AA,$00,$15,$0A ; tile 3 (nasty): red on black
  DEFB $44,$03,$08,$24,$10,$40,$20,$80,$80 ; tile 4 (ramp): bright green on
                                           ; black
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 5 (conveyor): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $00,$00,$00,$00    ; no conveyor (length 0)
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $01,$34,$5F,$02    ; direction 1 (rises to the right), lowest cell $5F34
                          ; = row 9 column 20, 2 cells
; Border colour; then $DF-$E0, not read by any code.
  DEFB $05,$00,$00        ; border cyan (5); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; item graphic (all zeros: blank)
; Exits: room numbers left, right, up, down.
  DEFB $25,$23,$2A,$1E    ; left 37, right 35, up 42, down 30
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $68,$02            ; definition $68, start $02 (column 2)
  DEFB $65,$07            ; definition $65, start $07 (column 7)
  DEFB $45,$92            ; definition $45, start $92 (column 18)
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 37 ($25): Orangery
;
; Format: see RoomOffLicence.
;
; Border: yellow (6). Conveyor: moves Willy left, 4 cells from row 10 column
; 28. Ramp: 14 cells from row 13 column 0 up to row 0 column 13, rising to the
; right.
;
; Items (from the item table at ItemRoomTable): 3, at row 1 column 28; row 6
; column 16; row 13 column 6.
;
; Exits: left Room 56 (West Wing Roof, RoomWestWingRoof); right Room 36 (A bit
; of tree, RoomBitOfTree); up Room 43 (Conservatory Roof,
; RoomConservatoryRoof); down Room 31 (Swimming Pool, RoomSwimmingPool).
;
; Entities: slot 0: definition $61 (at $A308) start $94; slot 1: definition $1B
; (at $A0D8) start $89; slot 2: definition $3C (at $A1E0) start $84. List ends
; at slot 3 ($FF).
RoomOrangery:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 0:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 1:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$01,$00,$00 ; row 2:
                                       ; .......................-........
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 3:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 4:
                                       ; ................................
  DEFB $00,$00,$00,$00,$40,$00,$10,$00 ; row 5:
                                       ; ................-........-......
  DEFB $00,$00,$00,$00,$00,$04,$00,$40 ; row 6:
                                       ; ......................-.....-...
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 7:
                                       ; ................................
  DEFB $A0,$00,$00,$04,$00,$00,$00,$00 ; row 8:
                                       ; ##............-.................
  DEFB $00,$00,$00,$00,$01,$00,$00,$00 ; row 9:
                                       ; ...................-............
  DEFB $00,$20,$00,$40,$00,$00,$05,$00 ; row 10:
                                       ; .....#......-.............--....
  DEFB $00,$25,$00,$00,$40,$00,$00,$55 ; row 11:
                                       ; .....#--........-...........----
  DEFB $00,$20,$00,$00,$00,$00,$10,$00 ; row 12:
                                       ; .....#...................-......
  DEFB $00,$20,$01,$00,$00,$00,$00,$00 ; row 13:
                                       ; .....#.....-....................
  DEFB $00,$20,$00,$00,$00,$40,$00,$00 ; row 14:
                                       ; .....#..............-...........
  DEFB $AA,$AA,$00,$01,$40,$00,$00,$00 ; row 15:
                                       ; ########.......--...............
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "            Orangery            "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on
                                           ; black
  DEFB $04,$A5,$4A,$24,$02,$04,$00,$02,$00 ; tile 1 (floor): green on black
  DEFB $16,$15,$55,$55,$24,$25,$55,$49,$22 ; tile 2 (wall): yellow on red
  DEFB $06,$82,$41,$3E,$6A,$B7,$19,$25,$44 ; tile 3 (nasty): yellow on black
                                           ; [not used in this room]
  DEFB $05,$01,$02,$04,$00,$10,$20,$40,$80 ; tile 4 (ramp): cyan on black
  DEFB $26,$C6,$AA,$A8,$2A,$59,$24,$00,$00 ; tile 5 (conveyor): yellow on green
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $00,$5C,$5F,$04    ; direction 0 (left), address $5F5C = row 10 column
                          ; 28, 4 cells
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $01,$A0,$5F,$0E    ; direction 1 (rises to the right), lowest cell $5FA0
                          ; = row 13 column 0, 14 cells
; Border colour; then $DF-$E0, not read by any code.
  DEFB $06,$00,$00        ; border yellow (6); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $02,$14,$2E,$55,$2A,$45,$2A,$14 ; item graphic
; Exits: room numbers left, right, up, down.
  DEFB $38,$24,$2B,$1F    ; left 56, right 36, up 43, down 31
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $61,$94            ; definition $61, start $94 (column 20)
  DEFB $1B,$89            ; definition $1B, start $89 (column 9)
  DEFB $3C,$84            ; definition $3C, start $84 (column 4)
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 38 ($26): Priests' Hole
;
; Format: see RoomOffLicence.
;
; Border: red (2). Conveyor: none. Ramp: none.
;
; Items (from the item table at ItemRoomTable): 1, at row 2 column 9.
;
; Exits: left Room 39 (Emergency Generator, RoomEmergencyGenerator); right Room
; 0 (The Off Licence, RoomOffLicence); up Room 60 (The Bow, RoomBow); down Room
; 32 (Halfway up the East Wall, RoomHalfwayEastWall). Odd: the down exit of
; Room 60 is Room 0, not this room.
;
; Entities: slot 0: definition $10 (at $A080) start $84; slot 1: definition $11
; (at $A088) start $A6; slot 2: definition $12 (at $A090) start $C5; slot 3:
; definition $25 (at $A128) start $16. List ends at slot 4 ($FF).
RoomPriestsHole:
  DEFB $A0,$00,$0A,$00,$00,$00,$00,$00 ; row 0:
                                       ; ##........##....................
  DEFB $A0,$00,$0A,$00,$00,$00,$00,$00 ; row 1:
                                       ; ##........##....................
  DEFB $A0,$00,$0A,$00,$00,$00,$00,$00 ; row 2:
                                       ; ##........##....................
  DEFB $00,$00,$0A,$00,$00,$00,$00,$00 ; row 3:
                                       ; ..........##....................
  DEFB $00,$00,$0A,$00,$00,$00,$00,$00 ; row 4:
                                       ; ..........##....................
  DEFB $A5,$00,$5A,$00,$00,$00,$00,$00 ; row 5:
                                       ; ##--....--##....................
  DEFB $A0,$00,$0A,$00,$00,$00,$00,$00 ; row 6:
                                       ; ##........##....................
  DEFB $A1,$00,$0A,$00,$00,$00,$00,$00 ; row 7:
                                       ; ##.-......##....................
  DEFB $A0,$00,$4A,$00,$00,$00,$00,$00 ; row 8:
                                       ; ##......-.##....................
  DEFB $A0,$00,$0A,$00,$00,$00,$00,$00 ; row 9:
                                       ; ##........##....................
  DEFB $A1,$00,$00,$00,$00,$00,$00,$00 ; row 10:
                                       ; ##.-............................
  DEFB $A0,$00,$00,$00,$00,$00,$00,$00 ; row 11:
                                       ; ##..............................
  DEFB $A0,$00,$5A,$00,$00,$00,$00,$00 ; row 12:
                                       ; ##......--##....................
  DEFB $A0,$00,$0A,$00,$00,$00,$00,$00 ; row 13:
                                       ; ##........##....................
  DEFB $A0,$40,$0A,$00,$00,$00,$00,$00 ; row 14:
                                       ; ##..-.....##....................
  DEFB $A0,$01,$0A,$00,$00,$00,$00,$00 ; row 15:
                                       ; ##.....-..##....................
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "         Priests' Hole          "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on
                                           ; black
  DEFB $06,$55,$55,$5D,$D7,$70,$00,$00,$00 ; tile 1 (floor): yellow on black
  DEFB $2A,$22,$11,$44,$88,$22,$11,$44,$88 ; tile 2 (wall): red on cyan
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 3 (nasty): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 4 (ramp): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 5 (conveyor): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $00,$00,$00,$00    ; no conveyor (length 0)
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $00,$00,$00,$00    ; no ramp (length 0)
; Border colour; then $DF-$E0, not read by any code.
  DEFB $02,$00,$00        ; border red (2); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $BF,$BF,$BB,$B1,$BB,$BB,$BF,$BF ; item graphic
; Exits: room numbers left, right, up, down.
  DEFB $27,$00,$3C,$20    ; left 39, right 0, up 60, down 32
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $10,$84            ; definition $10, start $84 (column 4)
  DEFB $11,$A6            ; definition $11, start $A6 (column 6)
  DEFB $12,$C5            ; definition $12, start $C5 (column 5)
  DEFB $25,$16            ; definition $25, start $16 (column 22)
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 39 ($27): Emergency Generator
;
; Format: see RoomOffLicence.
;
; Border: red (2). Conveyor: moves Willy left, 14 cells from row 11 column 9.
; Ramp: 6 cells from row 10 column 18 up to row 5 column 23, rising to the
; right.
;
; Items: none in the item table.
;
; Exits: left Room 40 (Dr Jones will never believe this, RoomNeverBelieveThis);
; right Room 38 (Priests' Hole, RoomPriestsHole); up Room 14 (Rescue Esmerelda,
; RoomRescueEsmerelda); down Room 0 (The Off Licence, RoomOffLicence).
;
; Entities: slot 0: definition $1A (at $A0D0) start $08. List ends at slot 1
; ($FF).
RoomEmergencyGenerator:
  DEFB $00,$00,$00,$00,$00,$00,$00,$0A ; row 0:
                                       ; ..............................##
  DEFB $00,$00,$00,$00,$00,$00,$00,$0A ; row 1:
                                       ; ..............................##
  DEFB $00,$00,$00,$00,$00,$00,$00,$0A ; row 2:
                                       ; ..............................##
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 3:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 4:
                                       ; ................................
  DEFB $00,$05,$00,$00,$00,$00,$50,$0A ; row 5:
                                       ; ......--................--....##
  DEFB $00,$05,$00,$00,$00,$00,$50,$03 ; row 6:
                                       ; ......--................--.....*
  DEFB $00,$05,$00,$00,$00,$00,$50,$03 ; row 7:
                                       ; ......--................--.....*
  DEFB $00,$05,$00,$00,$00,$00,$50,$03 ; row 8:
                                       ; ......--................--.....*
  DEFB $00,$05,$00,$00,$00,$00,$50,$03 ; row 9:
                                       ; ......--................--.....*
  DEFB $00,$2A,$80,$00,$00,$02,$A8,$03 ; row 10:
                                       ; .....####..............####....*
  DEFB $00,$28,$80,$00,$00,$02,$28,$03 ; row 11:
                                       ; .....##.#..............#.##....*
  DEFB $00,$AA,$AA,$AA,$AA,$AA,$AA,$03 ; row 12:
                                       ; ....########################...*
  DEFB $00,$AA,$2A,$8A,$A2,$A8,$AA,$03 ; row 13:
                                       ; ....####.####.####.####.####...*
  DEFB $00,$AA,$AA,$AA,$AA,$AA,$AA,$03 ; row 14:
                                       ; ....########################...*
  DEFB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA ; row 15:
                                       ; ################################
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "       Emergency Generator      "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $08,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on blue
  DEFB $2F,$66,$66,$66,$66,$66,$66,$66,$66 ; tile 1 (floor): white on cyan
  DEFB $33,$BF,$15,$00,$51,$FB,$51,$00,$15 ; tile 2 (wall): magenta on yellow
  DEFB $0D,$FF,$3F,$03,$1F,$7F,$1F,$03,$3F ; tile 3 (nasty): cyan on blue
  DEFB $0F,$03,$00,$0C,$00,$30,$00,$C0,$00 ; tile 4 (ramp): white on blue
  DEFB $16,$AA,$54,$AA,$54,$28,$10,$28,$10 ; tile 5 (conveyor): yellow on red
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $00,$69,$5F,$0E    ; direction 0 (left), address $5F69 = row 11 column
                          ; 9, 14 cells
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $01,$52,$5F,$06    ; direction 1 (rises to the right), lowest cell $5F52
                          ; = row 10 column 18, 6 cells
; Border colour; then $DF-$E0, not read by any code.
  DEFB $02,$00,$00        ; border red (2); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; item graphic (all zeros: blank)
; Exits: room numbers left, right, up, down.
  DEFB $28,$26,$0E,$00    ; left 40, right 38, up 14, down 0
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $1A,$08            ; definition $1A, start $08 (column 8)
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 40 ($28): Dr Jones will never believe this
;
; Format: see RoomOffLicence.
;
; Border: blue (1). Conveyor: moves Willy left, 32 cells from row 15 column 0.
; Ramp: 5 cells from row 10 column 24 up to row 6 column 20, rising to the
; left.
;
; Items (from the item table at ItemRoomTable): 1, at row 7 column 19.
;
; Exits: left Room 41 (The Attic, RoomAttic); right Room 39 (Emergency
; Generator, RoomEmergencyGenerator); up Room 16 (We must perform a
; Quirkafleeg, RoomQuirkafleeg); down Room 0 (The Off Licence, RoomOffLicence).
; Odd: the down exit of Room 16 is Room 0, not this room.
;
; Entities: slot 0: definition $1B (at $A0D8) start $92; slot 1: definition $0B
; (at $A058) start $0A. List ends at slot 2 ($FF).
RoomNeverBelieveThis:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 0:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 1:
                                       ; ................................
  DEFB $00,$00,$00,$EA,$00,$00,$00,$00 ; row 2:
                                       ; ............*###................
  DEFB $00,$00,$00,$AA,$A0,$00,$00,$00 ; row 3:
                                       ; ............######..............
  DEFB $00,$00,$00,$95,$54,$00,$00,$00 ; row 4:
                                       ; ............#------.............
  DEFB $00,$0E,$A8,$D5,$15,$00,$00,$00 ; row 5:
                                       ; ......*####.*---.---............
  DEFB $00,$0A,$AA,$81,$AA,$00,$00,$00 ; row 6:
                                       ; ......#######..-####............
  DEFB $00,$05,$50,$90,$A8,$20,$00,$00 ; row 7:
                                       ; ......----..#-..###..#..........
  DEFB $50,$05,$50,$81,$A0,$00,$00,$00 ; row 8:
                                       ; --....----..#..-##..............
  DEFB $00,$0A,$50,$90,$A0,$00,$00,$00 ; row 9:
                                       ; ......##--..#-..##..............
  DEFB $04,$0A,$50,$81,$80,$40,$00,$00 ; row 10:
                                       ; ..-...##--..#..-#...-...........
  DEFB $00,$12,$50,$90,$80,$00,$00,$00 ; row 11:
                                       ; .....-.#--..#-..#...............
  DEFB $00,$42,$50,$01,$80,$10,$00,$10 ; row 12:
                                       ; ....-..#--.....-#....-.......-..
  DEFB $00,$02,$00,$01,$80,$00,$40,$00 ; row 13:
                                       ; .......#.......-#.......-.......
  DEFB $00,$02,$94,$01,$90,$00,$00,$00 ; row 14:
                                       ; .......##--....-#-..............
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 15:
                                       ; ................................
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "Dr Jones will never believe this"
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on
                                           ; black
  DEFB $02,$FE,$55,$2A,$AA,$55,$AA,$AA,$FF ; tile 1 (floor): red on black
  DEFB $1F,$11,$44,$22,$88,$11,$44,$22,$88 ; tile 2 (wall): white on magenta
  DEFB $43,$01,$04,$22,$08,$11,$44,$22,$88 ; tile 3 (nasty): bright magenta on
                                           ; black
  DEFB $05,$40,$90,$24,$48,$12,$24,$09,$02 ; tile 4 (ramp): cyan on black
  DEFB $26,$A5,$00,$A5,$00,$AA,$FF,$FF,$55 ; tile 5 (conveyor): yellow on green
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $00,$E0,$5F,$20    ; direction 0 (left), address $5FE0 = row 15 column
                          ; 0, 32 cells
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $00,$58,$5F,$05    ; direction 0 (rises to the left), lowest cell $5F58
                          ; = row 10 column 24, 5 cells
; Border colour; then $DF-$E0, not read by any code.
  DEFB $01,$00,$00        ; border blue (1); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $F0,$F0,$78,$B8,$4C,$32,$0D,$03 ; item graphic
; Exits: room numbers left, right, up, down.
  DEFB $29,$27,$10,$00    ; left 41, right 39, up 16, down 0
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $1B,$92            ; definition $1B, start $92 (column 18)
  DEFB $0B,$0A            ; definition $0B, start $0A (column 10)
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 41 ($29): The Attic
;
; Format: see RoomOffLicence.
;
; Border: blue (1). Conveyor: moves Willy right, 4 cells from row 8 column 24.
; Ramp: none.
;
; Items: none in the item table. The room nevertheless has an item graphic
; (leftover: never drawn).
;
; Exits: left Room 42 (Under the Roof, RoomUnderTheRoof); right Room 40 (Dr
; Jones will never believe this, RoomNeverBelieveThis); up Room 0 (The Off
; Licence, RoomOffLicence); down Room 34 (Top Landing, RoomTopLanding). Odd:
; the up exit of Room 34 is Room 40, not this room.
;
; Entities: slot 0: definition $52 (at $A290) start $04; slot 1: definition $53
; (at $A298) start $06; slot 2: definition $54 (at $A2A0) start $08; slot 3:
; definition $55 (at $A2A8) start $0A; slot 4: definition $56 (at $A2B0) start
; $0C; slot 5: definition $57 (at $A2B8) start $4E; slot 6: definition $45 (at
; $A228) start $D5; slot 7: definition $3C (at $A1E0) start $92. All 8 slots
; are used, so the list ends at $8140.
RoomAttic:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 0:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 1:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 2:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 3:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 4:
                                       ; ................................
  DEFB $00,$C0,$03,$00,$00,$00,$00,$00 ; row 5:
                                       ; ....*......*....................
  DEFB $55,$95,$56,$50,$00,$00,$00,$00 ; row 6:
                                       ; ----#------#--..................
  DEFB $A0,$00,$00,$00,$00,$00,$00,$00 ; row 7:
                                       ; ##..............................
  DEFB $A4,$00,$00,$00,$05,$00,$00,$05 ; row 8:
                                       ; ##-...............--..........--
  DEFB $A0,$00,$00,$00,$00,$00,$00,$00 ; row 9:
                                       ; ##..............................
  DEFB $A4,$00,$00,$00,$00,$50,$00,$00 ; row 10:
                                       ; ##-.................--..........
  DEFB $A0,$00,$00,$00,$00,$00,$00,$00 ; row 11:
                                       ; ##..............................
  DEFB $A4,$00,$00,$00,$00,$04,$00,$00 ; row 12:
                                       ; ##-...................-.........
  DEFB $A0,$00,$00,$00,$00,$00,$00,$00 ; row 13:
                                       ; ##..............................
  DEFB $A4,$03,$00,$C0,$C0,$00,$00,$00 ; row 14:
                                       ; ##-....*....*...*...............
  DEFB $55,$65,$95,$96,$55,$95,$56,$59 ; row 15:
                                       ; -----#--#---#--#----#------#--#-
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "          The Attic             "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on
                                           ; black
  DEFB $16,$CE,$FF,$00,$E7,$00,$7F,$00,$FB ; tile 1 (floor): yellow on red
  DEFB $1E,$EE,$11,$6C,$92,$11,$C9,$22,$9C ; tile 2 (wall): yellow on magenta
  DEFB $44,$24,$12,$44,$AA,$55,$AA,$5B,$FF ; tile 3 (nasty): bright green on
                                           ; black
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 4 (ramp): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
  DEFB $42,$F0,$AA,$3C,$AA,$55,$AA,$55,$AA ; tile 5 (conveyor): bright red on
                                           ; black
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $01,$18,$5F,$04    ; direction 1 (right), address $5F18 = row 8 column
                          ; 24, 4 cells
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $00,$00,$00,$00    ; no ramp (length 0)
; Border colour; then $DF-$E0, not read by any code.
  DEFB $01,$00,$00        ; border blue (1); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $11,$22,$33,$44,$55,$66,$77,$88 ; item graphic
; Exits: room numbers left, right, up, down.
  DEFB $2A,$28,$00,$22    ; left 42, right 40, up 0, down 34
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $52,$04            ; definition $52, start $04 (column 4)
  DEFB $53,$06            ; definition $53, start $06 (column 6)
  DEFB $54,$08            ; definition $54, start $08 (column 8)
  DEFB $55,$0A            ; definition $55, start $0A (column 10)
  DEFB $56,$0C            ; definition $56, start $0C (column 12)
  DEFB $57,$4E            ; definition $57, start $4E (column 14)
  DEFB $45,$D5            ; definition $45, start $D5 (column 21)
  DEFB $3C,$92            ; definition $3C, start $92 (column 18)

; Room 42 ($2A): Under the Roof
;
; Format: see RoomOffLicence.
;
; Border: red (2). Conveyor: moves Willy right, 20 cells from row 6 column 12.
; Ramp: 7 cells from row 6 column 4 up to row 0 column 10, rising to the right.
;
; Items: none in the item table. The room nevertheless has an item graphic
; (leftover: never drawn).
;
; Exits: left Room 43 (Conservatory Roof, RoomConservatoryRoof); right Room 41
; (The Attic, RoomAttic); up Room 48 (Nomen Luni, RoomNomenLuni); down Room 36
; (A bit of tree, RoomBitOfTree).
;
; Entities: slot 0: definition $37 (at $A1B8) start $04; slot 1: definition $27
; (at $A138) start $10; slot 2: definition $3C (at $A1E0) start $C2. List ends
; at slot 3 ($FF).
RoomUnderTheRoof:
  DEFB $00,$00,$00,$FF,$FF,$FF,$FF,$F0 ; row 0:
                                       ; ............******************..
  DEFB $00,$00,$00,$00,$C3,$FC,$30,$00 ; row 1:
                                       ; ................*..****..*......
  DEFB $00,$00,$00,$03,$F3,$FC,$FC,$00 ; row 2:
                                       ; ...............***.****.***.....
  DEFB $00,$00,$00,$00,$00,$F0,$00,$00 ; row 3:
                                       ; ....................**..........
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 4:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 5:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 6:
                                       ; ................................
  DEFB $AA,$55,$00,$00,$00,$00,$00,$00 ; row 7:
                                       ; ####----........................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 8:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 9:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 10:
                                       ; ................................
  DEFB $00,$00,$00,$A0,$00,$01,$40,$00 ; row 11:
                                       ; ............##.........--.......
  DEFB $00,$00,$50,$A0,$01,$00,$00,$00 ; row 12:
                                       ; ........--..##.....-............
  DEFB $55,$50,$00,$A0,$40,$00,$00,$00 ; row 13:
                                       ; ------......##..-...............
  DEFB $54,$00,$01,$A0,$00,$00,$00,$00 ; row 14:
                                       ; ---........-##..................
  DEFB $00,$00,$00,$A0,$00,$40,$00,$00 ; row 15:
                                       ; ............##......-...........
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "         Under the Roof         "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $08,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on blue
  DEFB $0C,$B5,$AA,$55,$4A,$25,$42,$01,$02 ; tile 1 (floor): green on blue
  DEFB $1E,$66,$B6,$6D,$BB,$66,$B9,$6D,$B6 ; tile 2 (wall): yellow on magenta
  DEFB $F5,$66,$AA,$5F,$BC,$63,$AC,$6B,$A4 ; tile 3 (nasty): bright cyan on
                                           ; yellow, flashing
  DEFB $0F,$01,$02,$04,$28,$10,$28,$40,$80 ; tile 4 (ramp): white on blue
  DEFB $0E,$A5,$AA,$BD,$66,$66,$66,$66,$66 ; tile 5 (conveyor): yellow on blue
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $01,$CC,$5E,$14    ; direction 1 (right), address $5ECC = row 6 column
                          ; 12, 20 cells
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $01,$C4,$5E,$07    ; direction 1 (rises to the right), lowest cell $5EC4
                          ; = row 6 column 4, 7 cells
; Border colour; then $DF-$E0, not read by any code.
  DEFB $02,$00,$00        ; border red (2); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; item graphic
; Exits: room numbers left, right, up, down.
  DEFB $2B,$29,$30,$24    ; left 43, right 41, up 48, down 36
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $37,$04            ; definition $37, start $04 (column 4)
  DEFB $27,$10            ; definition $27, start $10 (column 16)
  DEFB $3C,$C2            ; definition $3C, start $C2 (column 2)
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 43 ($2B): Conservatory Roof
;
; Format: see RoomOffLicence.
;
; Border: cyan (5). Conveyor: moves Willy right, 6 cells from row 13 column 26.
; Ramp: 9 cells from row 15 column 12 up to row 7 column 20, rising to the
; right.
;
; Items (from the item table at ItemRoomTable): 4, at row 8 columns 22, 25, 28,
; 31.
;
; Exits: left Room 0 (The Off Licence, RoomOffLicence); right Room 42 (Under
; the Roof, RoomUnderTheRoof); up Room 0 (The Off Licence, RoomOffLicence);
; down Room 37 (Orangery, RoomOrangery).
;
; Entities: slot 0: definition $6A (at $A350) start $14; slot 1: definition $3D
; (at $A1E8) start $18. List ends at slot 2 ($FF).
RoomConservatoryRoof:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 0:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 1:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 2:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 3:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 4:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 5:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 6:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$2A,$AA,$AA ; row 7:
                                       ; .....................###########
  DEFB $00,$00,$00,$00,$00,$30,$C3,$0C ; row 8:
                                       ; .....................*..*..*..*.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 9:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 10:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 11:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 12:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$50,$00 ; row 13:
                                       ; ........................--......
  DEFB $00,$00,$00,$00,$00,$00,$05,$55 ; row 14:
                                       ; ..........................------
  DEFB $00,$00,$00,$00,$00,$04,$00,$00 ; row 15:
                                       ; ......................-.........
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "        Conservatory Roof       "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on
                                           ; black
  DEFB $04,$AC,$53,$2A,$D0,$8A,$24,$22,$04 ; tile 1 (floor): green on black
  DEFB $05,$F7,$EF,$00,$00,$00,$66,$66,$00 ; tile 2 (wall): cyan on black
  DEFB $43,$DA,$D5,$7F,$2E,$11,$1F,$0A,$1B ; tile 3 (nasty): bright magenta on
                                           ; black
  DEFB $07,$01,$02,$04,$10,$08,$20,$40,$80 ; tile 4 (ramp): white on black
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 5 (conveyor): bright white on
                                           ; white, flashing
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $01,$BA,$5F,$06    ; direction 1 (right), address $5FBA = row 13 column
                          ; 26, 6 cells
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $01,$EC,$5F,$09    ; direction 1 (rises to the right), lowest cell $5FEC
                          ; = row 15 column 12, 9 cells
; Border colour; then $DF-$E0, not read by any code.
  DEFB $05,$00,$00        ; border cyan (5); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $18,$18,$F8,$3C,$7E,$60,$60,$7E ; item graphic
; Exits: room numbers left, right, up, down.
  DEFB $00,$2A,$00,$25    ; left 0, right 42, up 0, down 37
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $6A,$14            ; definition $6A, start $14 (column 20)
  DEFB $3D,$18            ; definition $3D, start $18 (column 24)
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 44 ($2C): On top of the house
;
; Format: see RoomOffLicence.
;
; Border: magenta (3). Conveyor: none. Ramp: 6 cells from row 10 column 12 up
; to row 5 column 17, rising to the right.
;
; Items (from the item table at ItemRoomTable): 1, at row 4 column 18.
;
; Exits: left Room 14 (Rescue Esmerelda, RoomRescueEsmerelda); right Room 0
; (The Off Licence, RoomOffLicence); up Room 0 (The Off Licence,
; RoomOffLicence); down Room 38 (Priests' Hole, RoomPriestsHole). Odd: the up
; exit of Room 38 is Room 60, not this room.
;
; Entities: slot 0: definition $1D (at $A0E8) start $14. List ends at slot 1
; ($FF).
RoomTopOfTheHouse:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 0:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 1:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 2:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 3:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 4:
                                       ; ................................
  DEFB $92,$00,$00,$00,$04,$00,$00,$00 ; row 5:
                                       ; #-.#..............-.............
  DEFB $90,$00,$00,$00,$10,$00,$00,$00 ; row 6:
                                       ; #-...............-..............
  DEFB $90,$00,$00,$00,$40,$00,$00,$00 ; row 7:
                                       ; #-..............-...............
  DEFB $92,$00,$00,$01,$00,$00,$00,$00 ; row 8:
                                       ; #-.#...........-................
  DEFB $92,$80,$00,$04,$00,$00,$00,$00 ; row 9:
                                       ; #-.##.........-.................
  DEFB $92,$A0,$82,$10,$00,$00,$00,$00 ; row 10:
                                       ; #-.###..#..#.-..................
  DEFB $92,$AA,$AA,$40,$00,$00,$00,$00 ; row 11:
                                       ; #-.#########-...................
  DEFB $92,$AA,$AA,$00,$00,$00,$00,$00 ; row 12:
                                       ; #-.#########....................
  DEFB $10,$00,$00,$00,$00,$00,$00,$00 ; row 13:
                                       ; .-..............................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 14:
                                       ; ................................
  DEFB $AA,$AA,$AA,$00,$00,$00,$00,$00 ; row 15:
                                       ; ############....................
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "         On top of the house    "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $08,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on blue
  DEFB $0E,$A0,$40,$80,$00,$00,$00,$00,$00 ; tile 1 (floor): yellow on blue
  DEFB $4B,$51,$AA,$00,$AA,$15,$AA,$00,$AA ; tile 2 (wall): bright magenta on
                                           ; blue
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 3 (nasty): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
  DEFB $0F,$01,$03,$06,$0D,$1A,$34,$68,$D0 ; tile 4 (ramp): white on blue
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 5 (conveyor): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $00,$00,$00,$00    ; no conveyor (length 0)
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $01,$4C,$5F,$06    ; direction 1 (rises to the right), lowest cell $5F4C
                          ; = row 10 column 12, 6 cells
; Border colour; then $DF-$E0, not read by any code.
  DEFB $03,$00,$00        ; border magenta (3); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $00,$00,$18,$14,$1A,$35,$6B,$D0 ; item graphic
; Exits: room numbers left, right, up, down.
  DEFB $0E,$00,$00,$26    ; left 14, right 0, up 0, down 38
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $1D,$14            ; definition $1D, start $14 (column 20)
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 45 ($2D): Under the Drive
;
; Format: see RoomOffLicence.
;
; Border: green (4). Conveyor: moves Willy left, 14 cells from row 10 column
; 18. Ramp: 12 cells from row 14 column 13 up to row 3 column 2, rising to the
; left.
;
; Items: none in the item table. The room nevertheless has an item graphic
; (leftover: never drawn).
;
; Exits: left Room 6 (Entrance to Hades, RoomEntranceToHades); right Room 46
; (Tree Root, RoomTreeRoot); up Room 4 (The Drive, RoomDrive); down Room 0 (The
; Off Licence, RoomOffLicence). Odd: the right exit of Room 6 is Room 5, not
; this room; the left edge of the layout is walled in (no free cell next to
; it), so the left exit (byte 6) cannot be used by walking (inferred from the
; layout).
;
; Entities: slot 0: definition $1C (at $A0E0) start $10; slot 1: definition $1D
; (at $A0E8) start $92; slot 2: definition $44 (at $A220) start $96. List ends
; at slot 3 ($FF).
RoomUnderTheDrive:
  DEFB $A0,$00,$00,$00,$00,$00,$AA,$AA ; row 0:
                                       ; ##......................########
  DEFB $A0,$00,$00,$00,$00,$00,$AA,$AA ; row 1:
                                       ; ##......................########
  DEFB $A0,$00,$00,$00,$00,$00,$AA,$AA ; row 2:
                                       ; ##......................########
  DEFB $A0,$00,$00,$00,$00,$05,$AA,$AA ; row 3:
                                       ; ##....................--########
  DEFB $A8,$00,$00,$00,$00,$00,$AA,$AA ; row 4:
                                       ; ###.....................########
  DEFB $AA,$00,$00,$00,$10,$00,$02,$AA ; row 5:
                                       ; ####.............-.........#####
  DEFB $AA,$80,$00,$00,$00,$50,$00,$AA ; row 6:
                                       ; #####...............--......####
  DEFB $AA,$A0,$00,$00,$00,$00,$00,$0A ; row 7:
                                       ; ######........................##
  DEFB $AA,$A8,$00,$00,$50,$00,$00,$00 ; row 8:
                                       ; #######.........--..............
  DEFB $AA,$AA,$00,$00,$00,$C0,$00,$00 ; row 9:
                                       ; ########............*...........
  DEFB $AA,$AA,$80,$00,$00,$00,$00,$00 ; row 10:
                                       ; #########.......................
  DEFB $AA,$AA,$A0,$00,$00,$00,$00,$00 ; row 11:
                                       ; ##########......................
  DEFB $AA,$AA,$A8,$00,$00,$00,$00,$00 ; row 12:
                                       ; ###########.....................
  DEFB $AA,$AA,$AA,$00,$00,$00,$00,$00 ; row 13:
                                       ; ############....................
  DEFB $AA,$AA,$AA,$80,$30,$0C,$0C,$00 ; row 14:
                                       ; #############....*....*...*.....
  DEFB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA ; row 15:
                                       ; ################################
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "          Under the Drive       "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on
                                           ; black
  DEFB $06,$FF,$FF,$A5,$58,$24,$42,$20,$00 ; tile 1 (floor): yellow on black
  DEFB $0C,$10,$2A,$55,$A0,$10,$20,$10,$08 ; tile 2 (wall): green on blue
  DEFB $04,$18,$18,$14,$22,$22,$55,$11,$28 ; tile 3 (nasty): green on black
  DEFB $07,$80,$40,$A0,$50,$A8,$54,$AA,$55 ; tile 4 (ramp): white on black
  DEFB $02,$E0,$AA,$F8,$00,$FF,$FF,$66,$66 ; tile 5 (conveyor): red on black
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $00,$52,$5F,$0E    ; direction 0 (left), address $5F52 = row 10 column
                          ; 18, 14 cells
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $00,$CD,$5F,$0C    ; direction 0 (rises to the left), lowest cell $5FCD
                          ; = row 14 column 13, 12 cells
; Border colour; then $DF-$E0, not read by any code.
  DEFB $04,$00,$00        ; border green (4); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $81,$64,$CD,$0F,$61,$DA,$33,$1A ; item graphic
; Exits: room numbers left, right, up, down.
  DEFB $06,$2E,$04,$00    ; left 6, right 46, up 4, down 0
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $1C,$10            ; definition $1C, start $10 (column 16)
  DEFB $1D,$92            ; definition $1D, start $92 (column 18)
  DEFB $44,$96            ; definition $44, start $96 (column 22)
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 46 ($2E): Tree Root
;
; Format: see RoomOffLicence.
;
; Border: blue (1). Conveyor: moves Willy left, 13 cells from row 10 column 0.
; Ramp: 6 cells from row 14 column 24 up to row 9 column 29, rising to the
; right.
;
; Items (from the item table at ItemRoomTable): 2, at row 3 column 10; row 4
; column 29.
;
; Exits: left Room 45 (Under the Drive, RoomUnderTheDrive); right Room 47 (the
; room titled "[", RoomBracket); up Room 3 (At the Foot of the MegaTree,
; RoomFootOfMegaTree); down Room 0 (The Off Licence, RoomOffLicence). Odd: the
; down exit of Room 3 is Room 0, not this room; the right edge of the layout is
; walled in (no free cell next to it), so the right exit (byte 47) cannot be
; used by walking (inferred from the layout).
;
; Entities: slot 0: definition $1E (at $A0F0) start $84; slot 1: definition $28
; (at $A140) start $0D; slot 2: definition $23 (at $A118) start $13; slot 3:
; definition $1F (at $A0F8) start $59. List ends at slot 4 ($FF).
RoomTreeRoot:
  DEFB $AA,$0A,$AA,$AA,$AA,$AA,$AA,$AA ; row 0:
                                       ; ####..##########################
  DEFB $AA,$0A,$AA,$AA,$AA,$AA,$AA,$AA ; row 1:
                                       ; ####..##########################
  DEFB $AA,$0A,$AA,$AA,$AA,$AA,$AA,$AA ; row 2:
                                       ; ####..##########################
  DEFB $AA,$0A,$A0,$AA,$AA,$AA,$AA,$AA ; row 3:
                                       ; ####..####..####################
  DEFB $AA,$0A,$A0,$AA,$00,$A0,$00,$0A ; row 4:
                                       ; ####..####..####....##........##
  DEFB $AA,$0A,$A0,$AA,$00,$A0,$00,$0A ; row 5:
                                       ; ####..####..####....##........##
  DEFB $AA,$0A,$A0,$00,$00,$A0,$00,$0A ; row 6:
                                       ; ####..####..........##........##
  DEFB $AA,$0A,$A0,$00,$00,$A0,$00,$0A ; row 7:
                                       ; ####..####..........##........##
  DEFB $00,$00,$05,$00,$00,$A0,$00,$0A ; row 8:
                                       ; ..........--........##........##
  DEFB $00,$00,$00,$00,$00,$00,$00,$0A ; row 9:
                                       ; ..............................##
  DEFB $00,$00,$00,$00,$00,$00,$00,$2A ; row 10:
                                       ; .............................###
  DEFB $00,$00,$00,$01,$55,$55,$40,$AA ; row 11:
                                       ; ...............----------...####
  DEFB $00,$00,$00,$00,$00,$00,$02,$AA ; row 12:
                                       ; ...........................#####
  DEFB $00,$00,$00,$00,$00,$00,$0A,$AA ; row 13:
                                       ; ..........................######
  DEFB $00,$0C,$03,$03,$00,$30,$2A,$AA ; row 14:
                                       ; ......*....*...*.....*...#######
  DEFB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA ; row 15:
                                       ; ################################
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "           Tree Root            "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on
                                           ; black
  DEFB $06,$FF,$FF,$00,$00,$00,$00,$00,$00 ; tile 1 (floor): yellow on black
  DEFB $0A,$66,$99,$24,$24,$77,$88,$8D,$72 ; tile 2 (wall): red on blue
  DEFB $02,$1C,$2A,$5F,$7D,$BE,$FE,$D2,$7C ; tile 3 (nasty): red on black
  DEFB $43,$03,$02,$0D,$02,$31,$08,$D5,$22 ; tile 4 (ramp): bright magenta on
                                           ; black
  DEFB $04,$EE,$AA,$38,$FF,$FF,$10,$10,$38 ; tile 5 (conveyor): green on black
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $00,$40,$5F,$0D    ; direction 0 (left), address $5F40 = row 10 column
                          ; 0, 13 cells
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $01,$D8,$5F,$06    ; direction 1 (rises to the right), lowest cell $5FD8
                          ; = row 14 column 24, 6 cells
; Border colour; then $DF-$E0, not read by any code.
  DEFB $01,$00,$00        ; border blue (1); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $02,$1D,$22,$5E,$BE,$7C,$38,$10 ; item graphic
; Exits: room numbers left, right, up, down.
  DEFB $2D,$2F,$03,$00    ; left 45, right 47, up 3, down 0
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $1E,$84            ; definition $1E, start $84 (column 4)
  DEFB $28,$0D            ; definition $28, start $0D (column 13)
  DEFB $23,$13            ; definition $23, start $13 (column 19)
  DEFB $1F,$59            ; definition $1F, start $59 (column 25)
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 47 ($2F): Empty room titled "["
;
; Format: see RoomOffLicence. An empty room: the layout is all background, the
; name is the single character "[" surrounded by spaces, the tile area holds
; zeros followed by bytes that look like Z80 code (not a valid set of tiles),
; the border byte is $7E (low 3 bits: yellow), $DF-$E0 hold $FE,$2C and the
; entity list is empty ($FF in slot 0). The unused tile bytes are harmless as
; long as no cell uses a tile other than 0.
;
; Exits: left Room 29 (The Nightmare Room, RoomNightmareRoom); right byte 205 =
; $CD, page $CD = Room 13 (Out on a limb, RoomOutOnALimb); up Room 28 (First
; Landing, RoomFirstLanding); down Room 43 (Conservatory Roof,
; RoomConservatoryRoof).
;
; Entered only from the right exit of Room 46 (Tree Root, RoomTreeRoot), whose
; right edge is walled in, so no way to enter it by walking was found (inferred
; from the layout). Observed: starting in this room from a snapshot, Willy
; falls out through the bottom into Room 43 within 40 frames.
RoomBracket:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 0:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 1:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 2:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 3:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 4:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 5:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 6:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 7:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 8:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 9:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 10:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 11:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 12:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 13:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 14:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 15:
                                       ; ................................
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "         [                      "
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$04
  DEFB $36,$00,$C2,$E3,$62,$DD,$34,$06,$10
  DEFB $FF,$DD,$71,$0A,$70,$C3,$56,$5E,$01
  DEFB $07,$60,$3A,$8E,$40,$20,$18,$E5,$C5
  DEFB $F5,$11,$E8,$5E,$D5,$C5,$C9,$F1,$C1
  DEFB $3D,$F2,$E0,$00
  DEFB $E1,$C9,$C1,$00
  DEFB $7E,$FE,$2C
  DEFB $C0,$D7,$C5,$7E,$FE,$23,$CC,$78
  DEFB $1D,$CD,$1C,$2B
  DEFB $E3,$E5,$11
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 48 ($30): Nomen Luni
;
; Format: see RoomOffLicence.
;
; Border: red (2). Conveyor: none. Ramp: 5 cells from row 15 column 9 up to row
; 11 column 13, rising to the right.
;
; Items: none in the item table. The room nevertheless has an item graphic
; (leftover: never drawn).
;
; Exits: left Room 0 (The Off Licence, RoomOffLicence); right Room 18 (On the
; Roof, RoomOnTheRoof); up Room 0 (The Off Licence, RoomOffLicence); down Room
; 42 (Under the Roof, RoomUnderTheRoof).
;
; Entities: slot 0: definition $68 (at $A340) start $05; slot 1: definition $6B
; (at $A358) start $14; slot 2: definition $1D (at $A0E8) start $90; slot 3:
; definition $0B (at $A058) start $16. List ends at slot 4 ($FF).
RoomNomenLuni:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 0:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 1:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 2:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 3:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 4:
                                       ; ................................
  DEFB $00,$00,$00,$00,$0A,$AA,$00,$00 ; row 5:
                                       ; ..................######........
  DEFB $00,$00,$00,$01,$0A,$AA,$00,$50 ; row 6:
                                       ; ...............-..######....--..
  DEFB $00,$00,$00,$00,$00,$A0,$00,$00 ; row 7:
                                       ; ....................##..........
  DEFB $00,$00,$01,$50,$00,$A0,$40,$00 ; row 8:
                                       ; ...........---......##..-.......
  DEFB $00,$00,$00,$00,$04,$A0,$00,$0A ; row 9:
                                       ; ..................-.##........##
  DEFB $00,$00,$00,$00,$00,$A0,$00,$2A ; row 10:
                                       ; ....................##.......###
  DEFB $00,$00,$00,$00,$40,$A0,$0A,$A2 ; row 11:
                                       ; ................-...##....####.#
  DEFB $00,$00,$00,$00,$01,$A0,$21,$42 ; row 12:
                                       ; ...................-##...#.--..#
  DEFB $00,$00,$00,$00,$00,$A0,$00,$0A ; row 13:
                                       ; ....................##........##
  DEFB $00,$00,$00,$AA,$AA,$AA,$AA,$A2 ; row 14:
                                       ; ............##################.#
  DEFB $00,$00,$00,$AA,$AA,$AA,$AA,$A2 ; row 15:
                                       ; ............##################.#
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "           Nomen Luni           "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on
                                           ; black
  DEFB $0D,$FF,$22,$44,$88,$55,$22,$00,$00 ; tile 1 (floor): cyan on blue
  DEFB $F3,$AA,$70,$AA,$6C,$B1,$5F,$AA,$55 ; tile 2 (wall): bright magenta on
                                           ; yellow, flashing
  DEFB $06,$55,$A2,$55,$98,$1C,$2A,$45,$8A ; tile 3 (nasty): yellow on black
                                           ; [not used in this room]
  DEFB $07,$03,$00,$0C,$00,$34,$0A,$C4,$00 ; tile 4 (ramp): white on black
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 5 (conveyor): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $00,$00,$00,$00    ; no conveyor (length 0)
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $01,$E9,$5F,$05    ; direction 1 (rises to the right), lowest cell $5FE9
                          ; = row 15 column 9, 5 cells
; Border colour; then $DF-$E0, not read by any code.
  DEFB $02,$00,$00        ; border red (2); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $12,$12,$12,$12,$12,$12,$12,$12 ; item graphic
; Exits: room numbers left, right, up, down.
  DEFB $00,$12,$00,$2A    ; left 0, right 18, up 0, down 42
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $68,$05            ; definition $68, start $05 (column 5)
  DEFB $6B,$14            ; definition $6B, start $14 (column 20)
  DEFB $1D,$90            ; definition $1D, start $90 (column 16)
  DEFB $0B,$16            ; definition $0B, start $16 (column 22)
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 49 ($31): The Wine Cellar
;
; Format: see RoomOffLicence.
;
; Border: green (4). Conveyor: moves Willy right, 5 cells from row 12 column
; 27. Ramp: 3 cells from row 14 column 24 up to row 12 column 26, rising to the
; right.
;
; Items (from the item table at ItemRoomTable): 6, at row 4 column 28; row 7
; columns 4, 28; row 10 columns 2, 28; row 13 column 4.
;
; Exits: left Room 51 (Tool  Shed, RoomToolShed); right Room 19 (The Forgotten
; Abbey, RoomForgottenAbbey); up Room 52 (Back Stairway, RoomBackStairway);
; down Room 0 (The Off Licence, RoomOffLicence).
;
; Entities: slot 0: definition $34 (at $A1A0) start $10; slot 1: definition $40
; (at $A200) start $19; slot 2: definition $41 (at $A208) start $09; slot 3:
; definition $42 (at $A210) start $13. List ends at slot 4 ($FF).
;
; Odd: tile 5 (conveyor) has attribute $0D, which first occurs at tile-area
; offset 39 (inside tile 4), so BuildRoomBuffers draws it with the 8 bytes
; after that offset instead of its own pixels (observed in the $7000 buffer).
RoomWineCellar:
  DEFB $00,$00,$00,$00,$00,$0C,$02,$AA ; row 0:
                                       ; ......................*....#####
  DEFB $00,$00,$00,$00,$00,$00,$02,$AA ; row 1:
                                       ; ...........................#####
  DEFB $55,$40,$00,$00,$00,$00,$02,$AA ; row 2:
                                       ; -----......................#####
  DEFB $00,$00,$00,$00,$00,$00,$00,$2A ; row 3:
                                       ; .............................###
  DEFB $00,$00,$00,$00,$00,$00,$00,$2A ; row 4:
                                       ; .............................###
  DEFB $AA,$A8,$00,$41,$00,$15,$56,$AA ; row 5:
                                       ; #######.....-..-.....------#####
  DEFB $AA,$00,$00,$00,$00,$00,$00,$2A ; row 6:
                                       ; ####.........................###
  DEFB $AA,$00,$00,$00,$00,$00,$00,$2A ; row 7:
                                       ; ####.........................###
  DEFB $AA,$A8,$00,$41,$00,$55,$56,$AA ; row 8:
                                       ; #######.....-..-....-------#####
  DEFB $A0,$00,$00,$00,$00,$00,$00,$2A ; row 9:
                                       ; ##...........................###
  DEFB $A0,$00,$00,$00,$00,$00,$00,$2A ; row 10:
                                       ; ##...........................###
  DEFB $AA,$A8,$00,$41,$01,$55,$55,$55 ; row 11:
                                       ; #######.....-..-...-------------
  DEFB $AA,$00,$00,$C3,$03,$00,$00,$00 ; row 12:
                                       ; ####........*..*...*............
  DEFB $AA,$00,$00,$00,$00,$00,$0A,$AA ; row 13:
                                       ; ####......................######
  DEFB $AA,$A8,$00,$00,$00,$00,$2A,$AA ; row 14:
                                       ; #######..................#######
  DEFB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA ; row 15:
                                       ; ################################
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "        The Wine Cellar         "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on
                                           ; black
  DEFB $42,$FF,$18,$E7,$10,$C7,$38,$00,$00 ; tile 1 (floor): bright red on
                                           ; black
  DEFB $29,$0A,$41,$28,$05,$A0,$14,$82,$50 ; tile 2 (wall): blue on cyan
  DEFB $46,$24,$24,$24,$5A,$DB,$BD,$C3,$7E ; tile 3 (nasty): bright yellow on
                                           ; black
  DEFB $07,$03,$03,$0D,$0E,$35,$3A,$D5,$EA ; tile 4 (ramp): white on black
  DEFB $0D,$AA,$55,$AA,$55,$AA,$55,$AA,$55 ; tile 5 (conveyor): cyan on blue
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $01,$9B,$5F,$05    ; direction 1 (right), address $5F9B = row 12 column
                          ; 27, 5 cells
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $01,$D8,$5F,$03    ; direction 1 (rises to the right), lowest cell $5FD8
                          ; = row 14 column 24, 3 cells
; Border colour; then $DF-$E0, not read by any code.
  DEFB $04,$00,$00        ; border green (4); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $00,$19,$F9,$1F,$00,$19,$FF,$1F ; item graphic
; Exits: room numbers left, right, up, down.
  DEFB $33,$13,$34,$00    ; left 51, right 19, up 52, down 0
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $34,$10            ; definition $34, start $10 (column 16)
  DEFB $40,$19            ; definition $40, start $19 (column 25)
  DEFB $41,$09            ; definition $41, start $09 (column 9)
  DEFB $42,$13            ; definition $42, start $13 (column 19)
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 50 ($32): Watch Tower
;
; Format: see RoomOffLicence.
;
; Border: cyan (5). Conveyor: moves Willy right, 8 cells from row 4 column 12.
; Ramp: 5 cells from row 8 column 7 up to row 4 column 11, rising to the right.
;
; Items (from the item table at ItemRoomTable): 4, at row 8 column 25; row 9
; columns 10, 20, 24.
;
; Exits: left Room 0 (The Off Licence, RoomOffLicence); right Room 0 (The Off
; Licence, RoomOffLicence); up Room 0 (The Off Licence, RoomOffLicence); down
; Room 16 (We must perform a Quirkafleeg, RoomQuirkafleeg).
;
; Entities: slot 0: definition $6C (at $A360) start $91; slot 1: definition $6D
; (at $A368) start $0B. List ends at slot 2 ($FF).
RoomWatchTower:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 0:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 1:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 2:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 3:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 4:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 5:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 6:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 7:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 8:
                                       ; ................................
  DEFB $00,$08,$00,$00,$00,$00,$20,$00 ; row 9:
                                       ; ......#..................#......
  DEFB $00,$08,$0C,$00,$00,$C0,$E0,$00 ; row 10:
                                       ; ......#...*.........*...*#......
  DEFB $00,$0A,$AA,$A0,$1A,$AA,$A0,$00 ; row 11:
                                       ; ......########...-########......
  DEFB $00,$00,$00,$A0,$0A,$00,$00,$00 ; row 12:
                                       ; ............##....##............
  DEFB $00,$00,$00,$A5,$0A,$00,$00,$00 ; row 13:
                                       ; ............##--..##............
  DEFB $00,$00,$00,$A0,$0A,$00,$00,$00 ; row 14:
                                       ; ............##....##............
  DEFB $00,$00,$00,$A0,$5A,$00,$00,$00 ; row 15:
                                       ; ............##..--##............
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "          Watch Tower           "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $08,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on blue
  DEFB $06,$FF,$FF,$AA,$55,$AA,$55,$00,$00 ; tile 1 (floor): yellow on black
  DEFB $1D,$AA,$55,$55,$AA,$55,$AA,$AA,$55 ; tile 2 (wall): cyan on magenta
  DEFB $0C,$46,$89,$89,$36,$48,$83,$84,$68 ; tile 3 (nasty): green on blue
  DEFB $0F,$01,$02,$04,$08,$10,$20,$40,$80 ; tile 4 (ramp): white on blue
  DEFB $0D,$F6,$FF,$E7,$00,$00,$00,$00,$00 ; tile 5 (conveyor): cyan on blue
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $01,$8C,$5E,$08    ; direction 1 (right), address $5E8C = row 4 column
                          ; 12, 8 cells
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $01,$07,$5F,$05    ; direction 1 (rises to the right), lowest cell $5F07
                          ; = row 8 column 7, 5 cells
; Border colour; then $DF-$E0, not read by any code.
  DEFB $05,$00,$00        ; border cyan (5); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $74,$38,$66,$BF,$BF,$9D,$42,$3C ; item graphic
; Exits: room numbers left, right, up, down.
  DEFB $00,$00,$00,$10    ; left 0, right 0, up 0, down 16
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $6C,$91            ; definition $6C, start $91 (column 17)
  DEFB $6D,$0B            ; definition $6D, start $0B (column 11)
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 51 ($33): Tool  Shed
;
; Format: see RoomOffLicence.
;
; Border: cyan (5). Conveyor: moves Willy right, 18 cells from row 15 column 7.
; Ramp: 8 cells from row 7 column 3 up to row 0 column 10, rising to the right.
;
; Items (from the item table at ItemRoomTable): 1, at row 14 column 7.
;
; Exits: left Room 58 (The Beach, RoomBeach); right Room 49 (The Wine Cellar,
; RoomWineCellar); up Room 53 (Back Door, RoomBackDoor); down Room 0 (The Off
; Licence, RoomOffLicence).
;
; Entities: slot 0: definition $34 (at $A1A0) start $10; slot 1: definition $62
; (at $A310) start $09; slot 2: definition $63 (at $A318) start $14. List ends
; at slot 3 ($FF).
;
; Odd: tile 5 (conveyor) has attribute $44, which first occurs at tile-area
; offset 13 (inside tile 1), so BuildRoomBuffers draws it with the 8 bytes
; after that offset instead of its own pixels (observed in the $7000 buffer).
RoomToolShed:
  DEFB $00,$00,$02,$AA,$A0,$00,$00,$00 ; row 0:
                                       ; ...........#######..............
  DEFB $00,$00,$0A,$AA,$A0,$00,$00,$00 ; row 1:
                                       ; ..........########..............
  DEFB $00,$00,$2A,$AA,$AA,$AA,$AA,$AA ; row 2:
                                       ; .........#######################
  DEFB $00,$00,$00,$00,$C0,$00,$00,$00 ; row 3:
                                       ; ................*...............
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 4:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$AA ; row 5:
                                       ; ............................####
  DEFB $00,$00,$00,$00,$00,$00,$00,$AA ; row 6:
                                       ; ............................####
  DEFB $00,$00,$00,$00,$00,$00,$00,$AA ; row 7:
                                       ; ............................####
  DEFB $AA,$A8,$00,$41,$00,$40,$2A,$AA ; row 8:
                                       ; #######.....-..-....-....#######
  DEFB $AA,$A8,$00,$00,$00,$00,$2A,$AA ; row 9:
                                       ; #######..................#######
  DEFB $AA,$A8,$00,$00,$00,$00,$6A,$AA ; row 10:
                                       ; #######.................-#######
  DEFB $AA,$A8,$11,$00,$10,$00,$2A,$AA ; row 11:
                                       ; #######..-.-.....-.......#######
  DEFB $AA,$A8,$00,$00,$00,$40,$2A,$AA ; row 12:
                                       ; #######.............-....#######
  DEFB $AA,$A8,$00,$00,$00,$00,$6A,$AA ; row 13:
                                       ; #######.................-#######
  DEFB $AA,$A8,$00,$00,$00,$00,$2A,$AA ; row 14:
                                       ; #######..................#######
  DEFB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA ; row 15:
                                       ; ################################
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "           Tool  Shed           "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on
                                           ; black
  DEFB $05,$5A,$FF,$22,$44,$22,$40,$00,$00 ; tile 1 (floor): cyan on black
  DEFB $1E,$55,$AA,$44,$22,$55,$AA,$44,$22 ; tile 2 (wall): yellow on magenta
  DEFB $06,$04,$04,$04,$88,$50,$20,$10,$08 ; tile 3 (nasty): yellow on black
  DEFB $07,$03,$03,$0C,$0C,$30,$30,$C0,$C0 ; tile 4 (ramp): white on black
  DEFB $44,$E0,$AA,$00,$66,$66,$66,$66,$66 ; tile 5 (conveyor): bright green on
                                           ; black
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $01,$E7,$5F,$12    ; direction 1 (right), address $5FE7 = row 15 column
                          ; 7, 18 cells
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $01,$E3,$5E,$08    ; direction 1 (rises to the right), lowest cell $5EE3
                          ; = row 7 column 3, 8 cells
; Border colour; then $DF-$E0, not read by any code.
  DEFB $05,$00,$00        ; border cyan (5); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $18,$18,$18,$18,$18,$9B,$7F,$3B ; item graphic
; Exits: room numbers left, right, up, down.
  DEFB $3A,$31,$35,$00    ; left 58, right 49, up 53, down 0
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $34,$10            ; definition $34, start $10 (column 16)
  DEFB $62,$09            ; definition $62, start $09 (column 9)
  DEFB $63,$14            ; definition $63, start $14 (column 20)
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 52 ($34): Back Stairway
;
; Format: see RoomOffLicence.
;
; Border: red (2). Conveyor: none. Ramp: 16 cells from row 15 column 2 up to
; row 0 column 17, rising to the right.
;
; Items: none in the item table.
;
; Exits: left Room 53 (Back Door, RoomBackDoor); right Room 25 (Cold Store,
; RoomColdStore); up Room 54 (West  Wing, RoomWestWing); down Room 49 (The Wine
; Cellar, RoomWineCellar).
;
; Entities: slot 0: definition $24 (at $A120) start $96; slot 1: definition $5C
; (at $A2E0) start $90; slot 2: definition $1D (at $A0E8) start $83. List ends
; at slot 3 ($FF).
RoomBackStairway:
  DEFB $00,$00,$00,$00,$0A,$AA,$AA,$AA ; row 0:
                                       ; ..................##############
  DEFB $00,$00,$00,$00,$2A,$AA,$AA,$AA ; row 1:
                                       ; .................###############
  DEFB $00,$00,$00,$00,$55,$55,$55,$55 ; row 2:
                                       ; ................----------------
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 3:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 4:
                                       ; ................................
  DEFB $00,$00,$00,$15,$55,$55,$55,$55 ; row 5:
                                       ; .............-------------------
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 6:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 7:
                                       ; ................................
  DEFB $00,$00,$05,$55,$55,$55,$55,$55 ; row 8:
                                       ; ..........----------------------
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 9:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 10:
                                       ; ................................
  DEFB $55,$54,$55,$55,$55,$55,$55,$55 ; row 11:
                                       ; -------.------------------------
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 12:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 13:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 14:
                                       ; ................................
  DEFB $55,$55,$55,$55,$55,$55,$55,$55 ; row 15:
                                       ; --------------------------------
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "         Back Stairway          "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on
                                           ; black
  DEFB $43,$FF,$44,$44,$FF,$11,$11,$FF,$00 ; tile 1 (floor): bright magenta on
                                           ; black
  DEFB $1E,$15,$F1,$8F,$A8,$8A,$F8,$1F,$15 ; tile 2 (wall): yellow on magenta
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 3 (nasty): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
  DEFB $47,$03,$01,$0C,$04,$30,$10,$C0,$40 ; tile 4 (ramp): bright white on
                                           ; black
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 5 (conveyor): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $00,$00,$00,$00    ; no conveyor (length 0)
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $01,$E2,$5F,$10    ; direction 1 (rises to the right), lowest cell $5FE2
                          ; = row 15 column 2, 16 cells
; Border colour; then $DF-$E0, not read by any code.
  DEFB $02,$00,$00        ; border red (2); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; item graphic (all zeros: blank)
; Exits: room numbers left, right, up, down.
  DEFB $35,$19,$36,$31    ; left 53, right 25, up 54, down 49
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $24,$96            ; definition $24, start $96 (column 22)
  DEFB $5C,$90            ; definition $5C, start $90 (column 16)
  DEFB $1D,$83            ; definition $1D, start $83 (column 3)
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 53 ($35): Back Door
;
; Format: see RoomOffLicence.
;
; Border: blue (1). Conveyor: moves Willy right, 14 cells from row 15 column
; 18. Ramp: 5 cells from row 15 column 9 up to row 11 column 13, rising to the
; right.
;
; Items: none in the item table.
;
; Exits: left Room 0 (The Off Licence, RoomOffLicence); right Room 52 (Back
; Stairway, RoomBackStairway); up Room 55 (West Bedroom, RoomWestBedroom); down
; Room 51 (Tool  Shed, RoomToolShed).
;
; Entities: none. List ends at slot 0 ($FF).
RoomBackDoor:
  DEFB $00,$00,$00,$00,$A0,$00,$00,$00 ; row 0:
                                       ; ................##..............
  DEFB $00,$00,$00,$00,$A0,$00,$00,$00 ; row 1:
                                       ; ................##..............
  DEFB $00,$00,$00,$00,$A0,$00,$00,$00 ; row 2:
                                       ; ................##..............
  DEFB $00,$00,$00,$00,$A0,$00,$00,$00 ; row 3:
                                       ; ................##..............
  DEFB $00,$00,$00,$00,$A0,$00,$00,$00 ; row 4:
                                       ; ................##..............
  DEFB $00,$00,$00,$00,$A0,$00,$00,$00 ; row 5:
                                       ; ................##..............
  DEFB $00,$00,$00,$00,$A0,$00,$00,$00 ; row 6:
                                       ; ................##..............
  DEFB $00,$00,$00,$00,$A0,$00,$00,$00 ; row 7:
                                       ; ................##..............
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 8:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 9:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 10:
                                       ; ................................
  DEFB $00,$00,$00,$05,$55,$55,$55,$55 ; row 11:
                                       ; ..............------------------
  DEFB $00,$00,$00,$2A,$A0,$00,$00,$00 ; row 12:
                                       ; .............#####..............
  DEFB $00,$00,$00,$AA,$A0,$00,$00,$00 ; row 13:
                                       ; ............######..............
  DEFB $00,$00,$02,$AA,$A0,$00,$00,$00 ; row 14:
                                       ; ...........#######..............
  DEFB $00,$00,$0A,$AA,$A0,$00,$00,$00 ; row 15:
                                       ; ..........########..............
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "            Back Door           "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on
                                           ; black
  DEFB $03,$FF,$FF,$FF,$AA,$55,$AA,$55,$00 ; tile 1 (floor): magenta on black
  DEFB $26,$69,$D2,$A5,$4B,$96,$2D,$5A,$B4 ; tile 2 (wall): yellow on green
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 3 (nasty): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
  DEFB $07,$03,$03,$0D,$0F,$36,$3D,$DA,$F4 ; tile 4 (ramp): white on black
  DEFB $22,$F0,$F0,$F0,$F0,$66,$66,$00,$00 ; tile 5 (conveyor): red on green
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $01,$F2,$5F,$0E    ; direction 1 (right), address $5FF2 = row 15 column
                          ; 18, 14 cells
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $01,$E9,$5F,$05    ; direction 1 (rises to the right), lowest cell $5FE9
                          ; = row 15 column 9, 5 cells
; Border colour; then $DF-$E0, not read by any code.
  DEFB $01,$00,$00        ; border blue (1); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; item graphic (all zeros: blank)
; Exits: room numbers left, right, up, down.
  DEFB $00,$34,$37,$33    ; left 0, right 52, up 55, down 51
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 54 ($36): West  Wing
;
; Format: see RoomOffLicence.
;
; Border: red (2). Conveyor: none. Ramp: 16 cells from row 15 column 16 up to
; row 0 column 31, rising to the right.
;
; Items: none in the item table.
;
; Exits: left Room 55 (West Bedroom, RoomWestBedroom); right Room 31 (Swimming
; Pool, RoomSwimmingPool); up Room 56 (West Wing Roof, RoomWestWingRoof); down
; Room 52 (Back Stairway, RoomBackStairway).
;
; Entities: slot 0: definition $61 (at $A308) start $0E; slot 1: definition $59
; (at $A2C8) start $C4; slot 2: definition $14 (at $A0A0) start $09. List ends
; at slot 3 ($FF).
RoomWestWing:
  DEFB $00,$A0,$00,$00,$00,$00,$00,$00 ; row 0:
                                       ; ....##..........................
  DEFB $00,$A0,$00,$00,$00,$00,$00,$00 ; row 1:
                                       ; ....##..........................
  DEFB $00,$A0,$00,$00,$00,$00,$00,$00 ; row 2:
                                       ; ....##..........................
  DEFB $55,$A0,$00,$00,$00,$00,$00,$00 ; row 3:
                                       ; ----##..........................
  DEFB $00,$A0,$00,$00,$00,$00,$00,$00 ; row 4:
                                       ; ....##..........................
  DEFB $00,$A0,$00,$00,$00,$00,$00,$00 ; row 5:
                                       ; ....##..........................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 6:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 7:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 8:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 9:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 10:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 11:
                                       ; ................................
  DEFB $55,$55,$55,$50,$00,$55,$55,$55 ; row 12:
                                       ; --------------......------------
  DEFB $00,$00,$00,$00,$02,$AA,$AA,$AA ; row 13:
                                       ; ...................#############
  DEFB $00,$00,$00,$00,$0A,$AA,$AA,$AA ; row 14:
                                       ; ..................##############
  DEFB $00,$00,$00,$00,$2A,$AA,$AA,$AA ; row 15:
                                       ; .................###############
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "           West  Wing           "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on
                                           ; black
  DEFB $41,$F9,$FF,$3F,$D5,$AA,$15,$4A,$84 ; tile 1 (floor): bright blue on
                                           ; black
  DEFB $27,$AC,$AE,$01,$AD,$AD,$02,$AC,$E8 ; tile 2 (wall): white on green
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 3 (nasty): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
  DEFB $07,$03,$03,$0C,$0C,$30,$30,$C0,$C0 ; tile 4 (ramp): white on black
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 5 (conveyor): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $00,$00,$00,$00    ; no conveyor (length 0)
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $01,$F0,$5F,$10    ; direction 1 (rises to the right), lowest cell $5FF0
                          ; = row 15 column 16, 16 cells
; Border colour; then $DF-$E0, not read by any code.
  DEFB $02,$00,$00        ; border red (2); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; item graphic (all zeros: blank)
; Exits: room numbers left, right, up, down.
  DEFB $37,$1F,$38,$34    ; left 55, right 31, up 56, down 52
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $61,$0E            ; definition $61, start $0E (column 14)
  DEFB $59,$C4            ; definition $59, start $C4 (column 4)
  DEFB $14,$09            ; definition $14, start $09 (column 9)
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 55 ($37): West Bedroom
;
; Format: see RoomOffLicence.
;
; Border: cyan (5). Conveyor: moves Willy left, 3 cells from row 3 column 26.
; Ramp: none.
;
; Items: none in the item table.
;
; Exits: left Room 0 (The Off Licence, RoomOffLicence); right Room 54 (West
; Wing, RoomWestWing); up Room 57 (Above the West Bedroom,
; RoomAboveWestBedroom); down Room 53 (Back Door, RoomBackDoor).
;
; Entities: slot 0: definition $1E (at $A0F0) start $8B; slot 1: definition $33
; (at $A198) start $4E. List ends at slot 2 ($FF).
RoomWestBedroom:
  DEFB $00,$00,$04,$00,$A0,$40,$00,$00 ; row 0:
                                       ; ..........-.....##..-...........
  DEFB $00,$00,$00,$00,$A0,$40,$00,$00 ; row 1:
                                       ; ................##..-...........
  DEFB $00,$00,$10,$00,$A0,$40,$00,$00 ; row 2:
                                       ; .........-......##..-...........
  DEFB $00,$00,$00,$00,$A0,$40,$00,$15 ; row 3:
                                       ; ................##..-........---
  DEFB $00,$00,$04,$00,$A0,$40,$00,$00 ; row 4:
                                       ; ..........-.....##..-...........
  DEFB $00,$00,$00,$00,$A0,$40,$00,$00 ; row 5:
                                       ; ................##..-...........
  DEFB $00,$00,$00,$10,$A0,$40,$00,$00 ; row 6:
                                       ; .............-..##..-...........
  DEFB $00,$00,$00,$00,$A0,$40,$00,$00 ; row 7:
                                       ; ................##..-...........
  DEFB $00,$00,$04,$00,$00,$40,$00,$00 ; row 8:
                                       ; ..........-.........-...........
  DEFB $00,$00,$00,$00,$00,$40,$00,$00 ; row 9:
                                       ; ....................-...........
  DEFB $00,$00,$10,$00,$00,$40,$00,$00 ; row 10:
                                       ; .........-..........-...........
  DEFB $00,$00,$08,$00,$00,$40,$00,$00 ; row 11:
                                       ; ..........#.........-...........
  DEFB $00,$00,$09,$55,$55,$55,$55,$55 ; row 12:
                                       ; ..........#---------------------
  DEFB $00,$00,$0A,$AA,$A0,$00,$00,$00 ; row 13:
                                       ; ..........########..............
  DEFB $00,$00,$00,$00,$A0,$00,$00,$00 ; row 14:
                                       ; ................##..............
  DEFB $00,$00,$00,$00,$A0,$00,$00,$00 ; row 15:
                                       ; ................##..............
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "    West Bedroom                "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on
                                           ; black
  DEFB $06,$AA,$55,$82,$41,$82,$41,$82,$41 ; tile 1 (floor): yellow on black
  DEFB $0D,$A8,$55,$A8,$56,$CF,$2E,$26,$C1 ; tile 2 (wall): cyan on blue
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 3 (nasty): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 4 (ramp): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
  DEFB $42,$A5,$FF,$BD,$AA,$55,$BA,$45,$83 ; tile 5 (conveyor): bright red on
                                           ; black
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $00,$7A,$5E,$03    ; direction 0 (left), address $5E7A = row 3 column
                          ; 26, 3 cells
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $00,$00,$00,$00    ; no ramp (length 0)
; Border colour; then $DF-$E0, not read by any code.
  DEFB $05,$00,$00        ; border cyan (5); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; item graphic (all zeros: blank)
; Exits: room numbers left, right, up, down.
  DEFB $00,$36,$39,$35    ; left 0, right 54, up 57, down 53
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $1E,$8B            ; definition $1E, start $8B (column 11)
  DEFB $33,$4E            ; definition $33, start $4E (column 14)
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 56 ($38): West Wing Roof
;
; Format: see RoomOffLicence.
;
; Border: blue (1). Conveyor: none. Ramp: 4 cells from row 15 column 28 up to
; row 12 column 31, rising to the right.
;
; Items (from the item table at ItemRoomTable): 4, at row 10 column 6; row 11
; column 27; row 13 column 19; row 14 column 9.
;
; Exits: left Room 57 (Above the West Bedroom, RoomAboveWestBedroom); right
; Room 37 (Orangery, RoomOrangery); up Room 0 (The Off Licence,
; RoomOffLicence); down Room 54 (West  Wing, RoomWestWing).
;
; Entities: slot 0: definition $34 (at $A1A0) start $13; slot 1: definition $1C
; (at $A0E0) start $14; slot 2: definition $3C (at $A1E0) start $54. List ends
; at slot 3 ($FF).
RoomWestWingRoof:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 0:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 1:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 2:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 3:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 4:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 5:
                                       ; ................................
  DEFB $55,$A0,$00,$00,$00,$00,$00,$00 ; row 6:
                                       ; ----##..........................
  DEFB $00,$A0,$30,$30,$0C,$0C,$03,$00 ; row 7:
                                       ; ....##...*...*....*...*....*....
  DEFB $00,$A5,$55,$55,$55,$55,$55,$55 ; row 8:
                                       ; ....##--------------------------
  DEFB $00,$A0,$00,$00,$00,$00,$00,$00 ; row 9:
                                       ; ....##..........................
  DEFB $00,$A0,$00,$00,$00,$00,$00,$00 ; row 10:
                                       ; ....##..........................
  DEFB $50,$A0,$00,$00,$00,$00,$00,$00 ; row 11:
                                       ; --..##..........................
  DEFB $00,$A0,$00,$00,$00,$00,$00,$00 ; row 12:
                                       ; ....##..........................
  DEFB $01,$A0,$00,$00,$00,$00,$00,$00 ; row 13:
                                       ; ...-##..........................
  DEFB $00,$A0,$00,$00,$00,$00,$00,$00 ; row 14:
                                       ; ....##..........................
  DEFB $04,$A5,$55,$55,$55,$55,$55,$05 ; row 15:
                                       ; ..-.##----------------------..--
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "         West Wing Roof         "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on
                                           ; black
  DEFB $03,$FF,$AA,$FF,$A4,$A4,$A7,$E4,$3C ; tile 1 (floor): magenta on black
  DEFB $25,$E1,$84,$1E,$48,$E1,$84,$1E,$48 ; tile 2 (wall): cyan on green
  DEFB $42,$18,$3C,$7E,$FF,$AF,$55,$3A,$10 ; tile 3 (nasty): bright red on
                                           ; black
  DEFB $07,$03,$00,$0C,$00,$30,$00,$C0,$00 ; tile 4 (ramp): white on black
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 5 (conveyor): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $00,$00,$00,$00    ; no conveyor (length 0)
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $01,$FC,$5F,$04    ; direction 1 (rises to the right), lowest cell $5FFC
                          ; = row 15 column 28, 4 cells
; Border colour; then $DF-$E0, not read by any code.
  DEFB $01,$00,$00        ; border blue (1); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $00,$00,$00,$0A,$0D,$3C,$F2,$C0 ; item graphic
; Exits: room numbers left, right, up, down.
  DEFB $39,$25,$00,$36    ; left 57, right 37, up 0, down 54
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $34,$13            ; definition $34, start $13 (column 19)
  DEFB $1C,$14            ; definition $1C, start $14 (column 20)
  DEFB $3C,$54            ; definition $3C, start $54 (column 20)
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 57 ($39): Above the West Bedroom
;
; Format: see RoomOffLicence.
;
; Border: red (2). Conveyor: none. Ramp: 8 cells from row 13 column 17 up to
; row 6 column 24, rising to the right.
;
; Items (from the item table at ItemRoomTable): 1, at row 9 column 23.
;
; Exits: left Room 0 (The Off Licence, RoomOffLicence); right Room 56 (West
; Wing Roof, RoomWestWingRoof); up Room 0 (The Off Licence, RoomOffLicence);
; down Room 55 (West Bedroom, RoomWestBedroom).
;
; Entities: slot 0: definition $07 (at $A038) start $CB; slot 1: definition $33
; (at $A198) start $4E. List ends at slot 2 ($FF).
RoomAboveWestBedroom:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 0:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 1:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 2:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 3:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 4:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 5:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$15,$55 ; row 6:
                                       ; .........................-------
  DEFB $00,$00,$00,$00,$00,$00,$D0,$00 ; row 7:
                                       ; ........................*-......
  DEFB $00,$00,$00,$00,$00,$03,$10,$00 ; row 8:
                                       ; .......................*.-......
  DEFB $00,$00,$00,$00,$00,$0C,$10,$00 ; row 9:
                                       ; ......................*..-......
  DEFB $00,$00,$00,$00,$00,$30,$10,$00 ; row 10:
                                       ; .....................*...-......
  DEFB $00,$00,$00,$00,$01,$55,$55,$55 ; row 11:
                                       ; ...................-------------
  DEFB $00,$00,$00,$00,$03,$00,$00,$00 ; row 12:
                                       ; ...................*............
  DEFB $00,$00,$04,$00,$0C,$00,$00,$00 ; row 13:
                                       ; ..........-.......*.............
  DEFB $00,$00,$00,$00,$A0,$00,$00,$00 ; row 14:
                                       ; ................##..............
  DEFB $00,$00,$10,$00,$A0,$55,$55,$00 ; row 15:
                                       ; .........-......##..--------....
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "   Above the West Bedroom       "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on
                                           ; black
  DEFB $04,$F7,$AA,$55,$EF,$00,$00,$00,$00 ; tile 1 (floor): green on black
  DEFB $23,$AA,$55,$AA,$55,$AA,$55,$AA,$55 ; tile 2 (wall): magenta on green
  DEFB $06,$30,$60,$C0,$80,$00,$00,$00,$00 ; tile 3 (nasty): yellow on black
  DEFB $07,$01,$00,$06,$09,$13,$06,$6C,$98 ; tile 4 (ramp): white on black
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 5 (conveyor): bright white on
                                           ; white, flashing [not used in this
                                           ; room]
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $00,$00,$00,$00    ; no conveyor (length 0)
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $01,$B1,$5F,$08    ; direction 1 (rises to the right), lowest cell $5FB1
                          ; = row 13 column 17, 8 cells
; Border colour; then $DF-$E0, not read by any code.
  DEFB $02,$00,$00        ; border red (2); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $08,$10,$20,$21,$12,$AC,$40,$20 ; item graphic
; Exits: room numbers left, right, up, down.
  DEFB $00,$38,$00,$37    ; left 0, right 56, up 0, down 55
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $07,$CB            ; definition $07, start $CB (column 11)
  DEFB $33,$4E            ; definition $33, start $4E (column 14)
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 58 ($3A): The Beach
;
; Format: see RoomOffLicence.
;
; Border: red (2). Conveyor: moves Willy left, 5 cells from row 15 column 0.
; Ramp: 1 cells from row 14 column 5 up to row 14 column 5, rising to the
; right.
;
; Items (from the item table at ItemRoomTable): 2, at row 13 columns 22, 22.
;
; Exits: left Room 59 (The Yacht, RoomYacht); right Room 51 (Tool  Shed,
; RoomToolShed); up Room 58 (The Beach, RoomBeach); down Room 0 (The Off
; Licence, RoomOffLicence). Odd: the up exit leads back to this room.
;
; Entities: slot 0: definition $01 (at $A008) start $0E; slot 1: definition $3C
; (at $A1E0) start $54. List ends at slot 2 ($FF).
RoomBeach:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 0:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 1:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 2:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 3:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 4:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 5:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 6:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 7:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$AA,$AA ; row 8:
                                       ; ........................########
  DEFB $00,$00,$00,$00,$00,$00,$AA,$AA ; row 9:
                                       ; ........................########
  DEFB $AA,$A0,$00,$00,$00,$00,$AA,$AA ; row 10:
                                       ; ######..................########
  DEFB $00,$00,$00,$00,$00,$00,$AA,$AA ; row 11:
                                       ; ........................########
  DEFB $00,$00,$00,$00,$00,$00,$AA,$AA ; row 12:
                                       ; ........................########
  DEFB $00,$00,$00,$00,$00,$00,$AA,$AA ; row 13:
                                       ; ........................########
  DEFB $00,$05,$D5,$75,$5D,$75,$AA,$AA ; row 14:
                                       ; ......--*----*----*--*--########
  DEFB $00,$15,$55,$55,$55,$55,$AA,$AA ; row 15:
                                       ; .....-------------------########
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "            The Beach           "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $0D,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): cyan on blue
  DEFB $32,$00,$00,$40,$04,$00,$10,$00,$01 ; tile 1 (floor): red on yellow
  DEFB $2A,$44,$00,$92,$24,$80,$28,$82,$50 ; tile 2 (wall): red on cyan
  DEFB $30,$42,$81,$E7,$81,$5A,$7E,$3C,$42 ; tile 3 (nasty): black on yellow
  DEFB $0E,$01,$03,$07,$0F,$1E,$37,$7F,$FB ; tile 4 (ramp): yellow on blue
  DEFB $2C,$4E,$AA,$00,$40,$40,$44,$AA,$FF ; tile 5 (conveyor): green on cyan
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $00,$E0,$5F,$05    ; direction 0 (left), address $5FE0 = row 15 column
                          ; 0, 5 cells
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $01,$C5,$5F,$01    ; direction 1 (rises to the right), lowest cell $5FC5
                          ; = row 14 column 5, 1 cells
; Border colour; then $DF-$E0, not read by any code.
  DEFB $02,$00,$00        ; border red (2); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $04,$05,$0B,$0B,$17,$37,$6F,$EF ; item graphic
; Exits: room numbers left, right, up, down.
  DEFB $3B,$33,$3A,$00    ; left 59, right 51, up 58, down 0
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $01,$0E            ; definition $01, start $0E (column 14)
  DEFB $3C,$54            ; definition $3C, start $54 (column 20)
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 59 ($3B): The Yacht
;
; Format: see RoomOffLicence.
;
; Border: cyan (5). Conveyor: moves Willy left, 11 cells from row 15 column 21.
; Ramp: 5 cells from row 9 column 10 up to row 5 column 6, rising to the left.
;
; Items (from the item table at ItemRoomTable): 1, at row 14 column 13.
;
; Exits: left Room 60 (The Bow, RoomBow); right Room 58 (The Beach, RoomBeach);
; up Room 0 (The Off Licence, RoomOffLicence); down Room 0 (The Off Licence,
; RoomOffLicence).
;
; Entities: slot 0: definition $35 (at $A1A8) start $08; slot 1: definition $1B
; (at $A0D8) start $15. List ends at slot 2 ($FF). The $FF slot also holds
; start byte $11 (unused).
RoomYacht:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 0:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 1:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 2:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 3:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 4:
                                       ; ................................
  DEFB $55,$60,$00,$00,$00,$00,$00,$00 ; row 5:
                                       ; -----#..........................
  DEFB $00,$20,$00,$00,$00,$00,$00,$00 ; row 6:
                                       ; .....#..........................
  DEFB $00,$20,$00,$00,$00,$00,$00,$00 ; row 7:
                                       ; .....#..........................
  DEFB $00,$20,$00,$00,$00,$00,$00,$00 ; row 8:
                                       ; .....#..........................
  DEFB $00,$20,$03,$03,$00,$C0,$00,$00 ; row 9:
                                       ; .....#.....*...*....*...........
  DEFB $55,$6A,$AA,$AA,$AA,$81,$55,$55 ; row 10:
                                       ; -----################..---------
  DEFB $01,$00,$00,$00,$02,$81,$00,$00 ; row 11:
                                       ; ...-...............##..-........
  DEFB $01,$00,$00,$00,$02,$81,$00,$00 ; row 12:
                                       ; ...-...............##..-........
  DEFB $01,$00,$00,$00,$02,$81,$00,$00 ; row 13:
                                       ; ...-...............##..-........
  DEFB $01,$00,$00,$00,$02,$80,$00,$00 ; row 14:
                                       ; ...-...............##...........
  DEFB $AA,$AA,$AA,$AA,$AA,$80,$00,$00 ; row 15:
                                       ; #####################...........
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "           The Yacht            "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on
                                           ; black
  DEFB $06,$BB,$DD,$DD,$EE,$00,$00,$00,$00 ; tile 1 (floor): yellow on black
  DEFB $3D,$BB,$77,$EE,$DD,$BB,$77,$EE,$DD ; tile 2 (wall): cyan on white
  DEFB $42,$7E,$BF,$BF,$6E,$2C,$2C,$AD,$FF ; tile 3 (nasty): bright red on
                                           ; black
  DEFB $07,$80,$40,$20,$10,$08,$04,$02,$01 ; tile 4 (ramp): white on black
  DEFB $0D,$E0,$AA,$38,$01,$83,$C7,$7C,$10 ; tile 5 (conveyor): cyan on blue
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $00,$F5,$5F,$0B    ; direction 0 (left), address $5FF5 = row 15 column
                          ; 21, 11 cells
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $00,$2A,$5F,$05    ; direction 0 (rises to the left), lowest cell $5F2A
                          ; = row 9 column 10, 5 cells
; Border colour; then $DF-$E0, not read by any code.
  DEFB $05,$00,$00        ; border cyan (5); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $CE,$F1,$B9,$D5,$EF,$D7,$BB,$FF ; item graphic
; Exits: room numbers left, right, up, down.
  DEFB $3C,$3A,$00,$00    ; left 60, right 58, up 0, down 0
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $35,$08            ; definition $35, start $08 (column 8)
  DEFB $1B,$15            ; definition $1B, start $15 (column 21)
  DEFB $FF,$11            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 60 ($3C): The Bow
;
; Format: see RoomOffLicence.
;
; Border: cyan (5). Conveyor: moves Willy right, 15 cells from row 15 column
; 17. Ramp: 6 cells from row 14 column 16 up to row 9 column 11, rising to the
; left.
;
; Items (from the item table at ItemRoomTable): 1, at row 8 column 26.
;
; Exits: left Room 0 (The Off Licence, RoomOffLicence); right Room 59 (The
; Yacht, RoomYacht); up Room 0 (The Off Licence, RoomOffLicence); down Room 0
; (The Off Licence, RoomOffLicence).
;
; Entities: slot 0: definition $69 (at $A348) start $17; slot 1: definition $6E
; (at $A370) start $14. List ends at slot 2 ($FF).
RoomBow:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 0:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 1:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 2:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 3:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 4:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$01,$55,$55 ; row 5:
                                       ; .......................---------
  DEFB $00,$00,$00,$00,$00,$00,$80,$00 ; row 6:
                                       ; ........................#.......
  DEFB $00,$00,$00,$00,$04,$00,$80,$00 ; row 7:
                                       ; ..................-.....#.......
  DEFB $00,$00,$00,$00,$00,$00,$90,$00 ; row 8:
                                       ; ........................#-......
  DEFB $00,$00,$00,$00,$00,$00,$80,$00 ; row 9:
                                       ; ........................#.......
  DEFB $00,$00,$00,$15,$55,$55,$55,$55 ; row 10:
                                       ; .............-------------------
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 11:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 12:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 13:
                                       ; ................................
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; row 14:
                                       ; ................................
  DEFB $FF,$FF,$FF,$FF,$C0,$00,$00,$00 ; row 15:
                                       ; *****************...............
; Room name: 32 characters, printed at the bottom of the screen when the room
; is entered.
  DEFM "             The Bow            "
; Six tiles of 9 bytes: attribute, then 8 pixel rows. Tile 0 background, 1
; floor, 2 wall, 3 nasty, 4 ramp, 5 conveyor.
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; tile 0 (background): black on
                                           ; black
  DEFB $44,$FF,$AA,$55,$FF,$00,$00,$00,$00 ; tile 1 (floor): bright green on
                                           ; black
  DEFB $3D,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9 ; tile 2 (wall): cyan on white
  DEFB $4F,$40,$82,$52,$00,$00,$00,$00,$00 ; tile 3 (nasty): bright white on
                                           ; blue
  DEFB $07,$80,$40,$20,$10,$08,$04,$02,$01 ; tile 4 (ramp): white on black
  DEFB $0E,$FF,$AA,$AA,$00,$AA,$FF,$00,$00 ; tile 5 (conveyor): yellow on blue
; Conveyor: direction, address of the leftmost cell in the attribute buffer,
; length in cells.
  DEFB $01,$F1,$5F,$0F    ; direction 1 (right), address $5FF1 = row 15 column
                          ; 17, 15 cells
; Ramp: direction, attribute buffer address of its lowest cell, length in
; cells.
  DEFB $00,$D0,$5F,$06    ; direction 0 (rises to the left), lowest cell $5FD0
                          ; = row 14 column 16, 6 cells
; Border colour; then $DF-$E0, not read by any code.
  DEFB $05,$00,$00        ; border cyan (5); $DF-$E0 = $00,$00
; Item graphic: 8 pixel rows shared by all items of the room.
  DEFB $48,$39,$26,$DA,$5B,$64,$9C,$12 ; item graphic
; Exits: room numbers left, right, up, down.
  DEFB $00,$3B,$00,$00    ; left 0, right 59, up 0, down 0
; Three bytes not read by any code.
  DEFB $00,$00,$00        ; unused
; Entity slots: definition index, start byte (see RoomOffLicence).
  DEFB $69,$17            ; definition $69, start $17 (column 23)
  DEFB $6E,$14            ; definition $6E, start $14 (column 20)
  DEFB $FF,$00            ; end of list
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty
  DEFB $00,$00            ; empty

; Room 61 ($3D): Stray bytes (not a room)
;
; Not a room: stray bytes. Nothing in the game refers to this page; it looks
; like Z80 machine code or data left in memory by the author's tools (no field
; of the room format makes sense: name, tile and exit bytes are arbitrary; room
; 61, the same kind of data, was loaded from a snapshot and shows noise). No
; exit of any room leads here, so the game does not load it by walking
; (inferred). Format: see RoomOffLicence.
RoomStray61:
  DEFB $09,$1A,$FE,$3B,$28,$CA,$FE,$0D
  DEFB $28,$C6,$E5,$21,$00,$78,$06,$02
  DEFB $CD,$9E,$65,$C1,$30,$06,$11,$B3
  DEFB $67,$C3,$59,$64,$CD,$4A,$75,$20
  DEFB $F5,$CD,$B4,$5B,$C4,$ED,$5B,$5E
  DEFB $23,$7E,$32,$2E,$54,$3A,$33,$54
  DEFB $B7,$28,$10,$7B,$FE,$20,$38,$04
  DEFB $FE,$25,$38,$07,$3A,$06,$53,$B7
  DEFB $CA,$E4,$6B,$21,$30,$7A,$16,$00
  DEFB $19,$19,$7E,$23,$66,$6F,$7B,$11
  DEFB $57,$75,$EB,$E3,$EB,$E5,$0C,$0D
  DEFB $C8,$FE,$18,$3E,$01,$2A,$34,$54
  DEFB $D0,$E5,$F5,$2A,$41,$54,$06,$02
  DEFB $CD,$9E,$65,$30,$37,$D5,$C5,$CD
  DEFB $87,$77,$2A,$41,$54,$79,$80,$3C
  DEFB $4F,$AF,$47,$ED,$42,$DF,$30,$11
  DEFM "!",$1C,"h",$E5,":",$12,"S",$B7,"(",$03,$CD,"qw",$E1,$C3,$92,"W\"AT",$C1,$D1,$C5,"q",$EB,$13,$06,$00,$ED,$B0,$EB,"p"
  DEFB $23,$70,$2B,$C1,$D1,$E5,$AF,$47,$03
  DEFB $ED,$42,$3A,$3E,$54,$FE,$02,$20,$07
  DEFB $3A,$C3,$56,$B7,$C4,$20,$6D,$14,$15
  DEFB $20,$19,$7E,$E6,$80,$11,$3D,$68,$CC
  DEFB $5E,$64,$7E,$E6,$40,$11,$05,$68,$C4
  DEFB $5E,$64,$E1,$7E,$23,$66,$6F,$D1,$C9
  DEFB $7E,$B7,$F2,$12
  DEFB $6D,$7A,$E3,$C1
  DEFB $D1,$D5,$E5
  DEFB $F5,$7E,$23,$66,$6F,$DF,$D1,$28
  DEFB $1C,$0A,$E6,$5F
  DEFB $45,$5F,$45
  DEFB $FF,$45
  DEFB $5F,$45
  DEFB $5F,$45
  DEFB $5F,$45
  DEFB $5F,$45
  DEFB $5F,$45
  DEFB $5F,$45
  DEFB $91,$35

; Room 62 ($3E): Stray bytes (not a room)
;
; Not a room: stray bytes. Nothing in the game refers to this page; it looks
; like Z80 machine code or data left in memory by the author's tools (no field
; of the room format makes sense: name, tile and exit bytes are arbitrary; room
; 61, the same kind of data, was loaded from a snapshot and shows noise). No
; exit of any room leads here, so the game does not load it by walking
; (inferred). Format: see RoomOffLicence.
RoomStray62:
  DEFB $D2,$44,$A1,$42,$79,$44,$54,$00
  DEFB $7A,$44,$BD,$44,$45,$01,$00,$43
  DEFB $F5,$FE,$04,$4F,$00,$43,$89,$47
  DEFB $67,$72,$00,$00,$6F,$49,$26,$4D
  DEFB $00,$4C,$00,$43,$36,$4D,$CC,$4C
  DEFB $99,$4C,$BF,$64,$41,$4C,$01,$53
  DEFB $2B,$53,$78,$1D,$E6,$4B,$2D,$53
  DEFB $1E,$1D,$00,$00,$00,$7A,$44,$BD
  DEFB $44,$45,$01,$00,$43,$F5,$FE,$04
  DEFB $4F,$00,$43,$89,$47,$67,$72,$00
  DEFB $00,$6F,$49,$26,$4D,$00,$4C,$4A
  DEFB $6D,$2B,$60,$E8,$5E,$42,$00,$28
  DEFB $60,$4A,$6D,$0E,$5F,$2C,$00,$47
  DEFB $6D,$8F,$1B,$46,$54,$00,$00,$00
  DEFB $18,$62,$FF,$FF,$06,$54,$52,$53
  DEFB $48,$44,$78,$21,$48,$44,$22,$3E
  DEFM "<>",$10,$D3,$C1,$06,"@",$CD,$60,$00,"!",$80,$80,"\"><>",$0C,$D3,$C1,$E3,$E3,$DB,$CF,$FE,"P ",$DF,$AF,$D3,$CE,">"
  DEFB $10,$D3,$CF,$06,$32,$CD,$60,$00,$DB
  DEFB $CF,$CB,$7F,$20,$FA,$CB,$47,$20,$C9
  DEFB $C9,$00,$00,$54,$52,$53,$48,$44,$78
  DEFB $28,$43,$29,$20,$43,$6F,$70,$79,$72
  DEFB $69,$67,$68,$74,$20,$31,$39,$38,$32
  DEFB $20,$62,$79,$20,$4C,$53,$49,$3E,$07
  DEFB $B8,$28,$44,$CB
  DEFB $58,$20,$02,$AF
  DEFB $C9,$CB,$50
  DEFB $E5,$20,$30,$CB,$48,$28,$03,$21
  DEFB $00,$00,$D5,$CD
  DEFB $92,$FF,$3E
  DEFB $20,$D3
  DEFB $CF,$E3
  DEFB $E3,$DB
  DEFB $CF,$07
  DEFB $38,$FB
  DEFB $01,$C8
  DEFB $00,$ED
  DEFB $B2,$DB

; Room 63 ($3F): Stray bytes (not a room)
;
; Not a room: stray bytes. Nothing in the game refers to this page; it looks
; like Z80 machine code or data left in memory by the author's tools (no field
; of the room format makes sense: name, tile and exit bytes are arbitrary; room
; 61, the same kind of data, was loaded from a snapshot and shows noise). No
; exit of any room leads here, so the game does not load it by walking
; (inferred). Format: see RoomOffLicence.
RoomStray63:
  DEFB $CF,$0F,$21,$81,$FF,$38,$46,$D1
  DEFB $D5,$7A,$FD,$BE,$09,$3E,$06,$28
  DEFB $43,$AF,$18,$40,$CD,$1D,$FF,$28
  DEFB $1B,$E1,$3E,$0F,$C9,$FD,$7E,$03
  DEFB $E6,$03,$4F,$DB,$C0,$DC,$07,$0D
  DEFB $20,$FC,$FD,$B6,$03,$CB,$7F,$3E
  DEFB $40,$C0,$AF,$C9,$D5,$78,$FE,$0F
  DEFB $28,$1E,$FE,$0C,$3E,$08,$28,$14
  DEFB $CD,$92,$FF,$3E,$30,$CD,$DA,$FF
  DEFB $28,$0A,$21,$89,$FF,$DB,$C9,$07
  DEFB $23,$30,$FC,$7E,$B7,$D1,$E1,$C9
  DEFB $FD,$7E,$07,$47,$E6,$1F,$5F,$A8
  DEFB $07,$07,$07,$3C,$47,$C5,$D5,$CD
  DEFB $92,$FF,$E5,$7E,$D3,$CA,$23,$3E
  DEFB $50,$CD,$DA,$FF,$E1,$D1,$C1,$20
  DEFB $D1,$3E,$20,$83,$5F,$10,$E6,$AF
  DEFM $18,$D2,$07,$04,$01,$05,$7F,$08,$02,$03,$0E,$0C,$09,$0D,$7F,$08,$0A,$0B,$E5,"j&",$00,$FD,$CB,$04,"n(",$01,")",$FD,"~",$07
  DEFB $D5,$57,$E6,$1F,$5F,$1C,$4B,$AA,$07
  DEFB $07,$07,$3C,$CD,$6B,$4B,$3D,$D1,$BB
  DEFB $30,$04,$2F,$83,$5F,$23,$79,$CD,$7A
  DEFB $4B,$57,$FD,$7E,$04,$E6,$0F,$82,$57
  DEFB $FD,$7E,$03,$E6,$03,$07,$07,$07,$B2
  DEFB $D3,$CE,$7B,$D3,$CB,$7D,$D3,$CC,$7C
  DEFB $D3,$CD,$E1,$C9
  DEFB $D3,$CF,$01,$C8
  DEFB $00,$ED,$B3
  DEFB $E3,$E3,$DB,$CF,$07,$38,$FB,$DB
  DEFB $CF,$E6,$01,$C9
  DEFB $00,$00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
