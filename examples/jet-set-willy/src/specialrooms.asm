; Room events of the Master Bedroom and the Bathroom
;
; Called once per frame by FrameLoop after Willy has been moved and drawn. In
; any room except the Master Bedroom (room $23) it jumps to DrawToilet, which
; handles the Bathroom and returns.
;
; Master Bedroom, ending stage 0 (EndingStage): draws one of the four figure
; sprites SpriteFigure0-9CFF at $686E of the $6000 buffer (column 14, pixel row
; 88) with the collision test of DrawSprite, after Willy and the room are
; already in the buffer. Touching the figure kills Willy (KillWilly). The frame
; follows Willy's Y index (WillyY): Y = $D0 (the low floor) alternates frames 0
; and 1 with bit 1 of the frame counter PassCounter; Y from $C0 up (a ramp or a
; low jump) gives frame 2; a smaller Y (the upper platform, where the figure
; stands) gives frame 3. The two cells in the first character row of the figure
; get attribute $45 (bright cyan), the two below get $07 (white).
;
; Master Bedroom, ending stage not 0: no figure. If Willy's column is below 6
; (the bed end) the stage becomes 2 and he starts running to the toilet (see
; EndingStage).
;
; Hardware: none (writes the $6000 and $5C00 buffers).
UpdateBedroom:
  LD A,(CurrentRoom)      ; current room
  CP ROOM_MASTER_BEDROOM
  JR NZ,DrawToilet        ; other rooms: Bathroom handler
  LD A,(EndingStage)
  OR A
  JR NZ,UpdateBedroom_1   ; every item collected: no figure
  LD A,(PassCounter)
  AND $02                 ; bit 1 of the frame counter
  RRCA
  RRCA
  RRCA
  RRCA                    ; -> $20 or 0
  OR SpriteFigure0&$FF    ; frame 0 ($9C80) or 1 ($9CA0)
  LD E,A
  LD A,(WillyY)
  CP BEDROOM_FLOOR_Y      ; Willy on the low floor: keep the walking frame
  JR Z,UpdateBedroom_0
  LD E,SpriteFigure2&$FF  ; frame 2
  CP BEDROOM_MID_Y
  JR NC,UpdateBedroom_0
  LD E,SpriteFigure3&$FF  ; Willy higher up: frame 3
UpdateBedroom_0:
  LD D,SpriteFigure0>>8   ; DE = sprite
  LD HL,SCREEN_PIXEL_BUF+THIRD_SIZE+(FIGURE_ROW-CELL_HEIGHT)*SCREEN_COLS+FIGURE_COLUMN ; buffer
                                                                                       ; address of
                                                                                       ; the figure
  LD C,$01                ; collision test
  CALL DrawSprite
  JP NZ,KillWilly         ; overlaps Willy (or anything drawn): Willy dies
  LD HL,(BRIGHT+CYAN)*HI_BYTE+BRIGHT+CYAN
  LD (SCREEN_ATTRS_BUF+FIGURE_ROW*SCREEN_COLS+FIGURE_COLUMN),HL ; row 11,
                                                                ; columns 14-15
  LD HL,WHITE*HI_BYTE+WHITE
  LD (SCREEN_ATTRS_BUF+(FIGURE_ROW+$0001)*SCREEN_COLS+FIGURE_COLUMN),HL ; row 12,
                                                                        ; columns
                                                                        ; 14-15
  RET
; Ending stage not 0: watch for Willy reaching the bed end of the room.
UpdateBedroom_1:
  LD A,(WillyAttrAddr)    ; low byte of Willy's attribute address
  AND COLUMN_MASK         ; column
  CP BED_END_COLUMN
  RET NC
  LD A,STAGE_RUN_TO_TOILET
  LD (EndingStage),A      ; the run to the toilet starts
  RET

; Check whether Willy has reached the toilet
;
; Called by FrameLoop every frame while the ending stage EndingStage is 2
; (Willy is running to the toilet). In the Bathroom (room $21) with Willy's
; attribute address at $5DBC (low byte $BC: row 13, column 28, where the toilet
; is drawn by DrawToilet) it zeroes the frame counter PassCounter (so the
; toilet animation starts from frame 0) and sets the stage to 3, which freezes
; Willy there.
;
; Observed: Willy runs right from the Master Bedroom through the Top Landing to
; the Bathroom and the stage changes from 2 to 3 at $9596 (frame 1063 of the
; run in finding F65).
CheckToiletReached:
  LD A,(CurrentRoom)      ; current room
  CP ROOM_BATHROOM
  RET NZ
  LD A,(WillyAttrAddr)    ; low byte of Willy's attribute address
  CP TOILET_ATTR_LOW      ; only the low byte is compared
  RET NZ
  XOR A
  LD (PassCounter),A
  LD A,STAGE_AT_TOILET
  LD (EndingStage),A      ; Willy stops
  RET

; Draw the toilet in the Bathroom
;
; Reached by the jump at $9539 of UpdateBedroom for every room except the
; Master Bedroom; does nothing outside the Bathroom (room $21). Otherwise ORs
; one of the toilet frames of SpritesToilet into the $6000 buffer at column 28
; and pixel row 104 (the floor, where Willy stands) with DrawSpriteRows, after
; Willy has been drawn, so he walks through it. The frame is bit 0 of the frame
; counter PassCounter times 32, plus 64 when the ending stage EndingStage is 3.
; The four attribute cells (rows 13-14, columns 28-29) are set to $07, white
; ink.
;
; Hardware: none (writes the $6000 and $5C00 buffers).
DrawToilet:
  LD A,(CurrentRoom)      ; current room
  CP ROOM_BATHROOM
  RET NZ
  LD A,(PassCounter)
  AND $01                 ; bit 0 of the frame counter
  RRCA
  RRCA
  RRCA                    ; -> 0 or $20
  LD E,A                  ; frame 0 or 1
  LD A,(EndingStage)
  CP STAGE_AT_TOILET
  JR NZ,DrawToilet_0
  SET 6,E                 ; at the toilet: frame 2 or 3
DrawToilet_0:
  LD D,SpritesToilet>>8   ; DE = sprite
  LD IX,RowAddressTable+BEDROOM_FLOOR_Y ; row table entry of pixel row 104
  LD BC,SPRITE_HEIGHT*HI_BYTE+TOILET_COLUMN ; 16 rows, column 28
  CALL DrawSpriteRows
  LD HL,WHITE*HI_BYTE+WHITE
  LD (SCREEN_ATTRS_BUF+TOILET_ROW*SCREEN_COLS+TOILET_COLUMN),HL ; row 13,
                                                                ; columns 28-29
  LD (SCREEN_ATTRS_BUF+(TOILET_ROW+$0001)*SCREEN_COLS+TOILET_COLUMN),HL ; row 14
  RET

; Mark Willy's attribute cells, check for nasties and draw him
;
; Called by FrameLoop once per frame after MoveWilly has moved Willy (skipped
; in ending stage 3, EndingStage, so Willy is then not drawn at all). Works in
; the attribute buffer $5C00 on Willy's cells, starting from the address in
; WillyAttrAddr (top-left cell; Willy is 2 cells wide and 2 or 3 cells high).
;
; 1. Ramp offset (B). If the cell under Willy's feet is a ramp cell (its
; attribute equals the ramp tile attribute $80C4: the cell two rows down, in
; the left column when the ramp direction RoomRampDir is 0, in the right column
; when it is 1) and Willy is not jumping or falling (WillyAirState = 0), the
; sprite is drawn lower by 0 to 6 pixel rows (B = 0, 4, 8, 12 in row table
; units, two per pixel row) following his walking frame (WillyFrame bits 0-1):
; B = 4*frame for a ramp that rises to the left, 12-4*frame for one that rises
; to the right, so he stays on the slope between cell steps. Otherwise B = 0.
;
; 2. MarkWillyCell is called for the six cells (the third row only counts as
; Willy's when his Y plus B (WillyY) is not on a character row boundary, C &
; $0F); each cell that holds the background attribute gets ink 7, which is how
; UpdateItems sees him touch an item, and any cell that holds the nasty tile
; attribute kills him.
;
; 3. Jumps to DrawWilly to draw the sprite, with the offset B.
;
; Observed with test calls: Willy at $5D48 on the Bathroom ramp (direction 1, Y
; $A0) is drawn from pixel row 86, 84, 82, 80 for frames 0-3, on the Master
; Bedroom ramp (direction 0, Y $C0) from row 96, 98, 100, 102.
;
; Hardware: none (writes the attribute and bitmap buffers).
PlaceWilly:
  LD HL,(WillyAttrAddr)   ; Willy's top-left attribute cell
  LD B,$00                ; no ramp offset
  LD A,(RoomRampDir)      ; ramp direction
  AND $01
  ADD A,$02*SCREEN_COLS   ; 2 rows down, column 0 or 1
  LD E,A
  LD D,$00
  ADD HL,DE               ; the cell under Willy's feet
  LD A,(TileRamp)         ; ramp tile attribute
  CP (HL)
  JR NZ,PlaceWilly_0      ; not on a ramp
  LD A,(WillyAirState)
  OR A
  JR NZ,PlaceWilly_0      ; jumping or falling: no offset
  LD A,(WillyFrame)       ; animation frame
  AND ANIM_FRAME_MASK
  RLCA
  RLCA                    ; frame * 4
  LD B,A
  LD A,(RoomRampDir)
  AND $01
  DEC A                   ; direction 0: $FF, 1: 0
  XOR RAMP_OFFSET_MASK
  XOR B
  AND RAMP_OFFSET_MASK    ; direction 0: frame*4, direction 1: 12-frame*4
  LD B,A
PlaceWilly_0:
  LD HL,(WillyAttrAddr)
  LD DE,SCREEN_COLS-$0001 ; from the right cell to the left cell of the next
                          ; row
  LD C,Y_CELL_MASK        ; the first two rows always count
  CALL MarkWillyCell      ; row 0, left
  INC HL
  CALL MarkWillyCell      ; row 0, right
  ADD HL,DE
  CALL MarkWillyCell      ; row 1, left
  INC HL
  CALL MarkWillyCell      ; row 1, right
  LD A,(WillyY)           ; Y index
  ADD A,B
  LD C,A                  ; low nibble: 0 on a character row boundary
  ADD HL,DE
  CALL MarkWillyCell      ; row 2, left
  INC HL
  CALL MarkWillyCell      ; row 2, right
  JR DrawWilly            ; draw Willy

; Mark one attribute cell as Willy's and kill him on a nasty
;
; If the cell holds the room's background attribute ($80A0) and C & $0F is not
; 0, the cell gets that attribute with ink 7 (Willy's colour; paper, bright and
; flash are kept). Cells with any other attribute (floor, wall, guardians) are
; left alone. Then, whatever the cell now holds, it is compared with the nasty
; tile attribute ($80BB); a match jumps to KillWillyNested, which drops the
; return addresses of this routine and PlaceWilly and kills Willy. So the nasty
; test covers all six cells even where nothing is written (standing on a nasty
; floor kills him). Observed with test calls: a nasty attribute in the right
; cell of Willy's top row, or in the row below his feet with Y on a row
; boundary, jumps to $90B6; two columns to the right it does not.
;
; HL Attribute buffer address of the cell C Low nibble 0: leave the cell alone
; (third row of cells while Willy is on a row boundary) O:HL Unchanged
MarkWillyCell:
  LD A,(RoomTiles)        ; background attribute
  CP (HL)
  JR NZ,MarkWillyCell_0   ; not empty: leave the cell
  LD A,C
  AND Y_CELL_MASK
  JR Z,MarkWillyCell_0
  LD A,(RoomTiles)
  OR WHITE                ; ink 7
  LD (HL),A
MarkWillyCell_0:
  LD A,(TileNasty)        ; nasty tile attribute
  CP (HL)
  JP Z,KillWillyNested    ; Willy dies
  RET
