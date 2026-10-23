; Build the empty-room attribute and bitmap buffers
;
; Called by ScrollTitleMessage at room entry. First expands the layout into the
; attributes at $5E00 with ExpandRoomLayout. Then, for each of the 512 cells,
; it finds the tile whose attribute equals the cell's attribute and copies that
; tile's 8 pixel rows into the $7000 bitmap buffer (screen layout: the first
; 256 cells go to $7000-$77FF, the last 256 to $7800-$7FFF; pixel row k of cell
; n is at base+n+256*k).
;
; The tile is found with CPIR over the 54 bytes of the six tile definitions at
; $80A0, so it is the attribute byte that is looked up, not a tile number: the
; first byte in the table equal to the attribute decides, and the 8 bytes after
; it are copied. That is the tile's own pixel data only if no earlier byte of
; the table (attribute or pixel row) has the same value. In rooms 24, 29, 36,
; 49 and 51 a used tile does not satisfy this (found by scanning the rooms in
; the tape image), and the simulator then copies the 8 bytes after the earlier
; match (observed for rooms 24, 29 and 49).
;
; The copy loop's pixel buffer high byte is a self-modified operand: the code
; at $8D3C and $8D48 stores $70 / $78 into the LD D,n at $8D5C
; (SmcPixelBufPage).
;
; Observed: a Python model of the attribute step and this copy reproduces
; $5E00-$5FFF and $7000-$7FFF of a snapshot taken in the Bathroom exactly, and
; the same for rooms 24, 29 and 49 loaded into $8000 and run here.
;
; Hardware: none (memory only). The buffers are copied to $5C00/$6000 and to
; the screen later by the frame code (FrameLoop).
;
; O:A Corrupted (all other registers too)
BuildRoomBuffers:
  CALL ExpandRoomLayout
  LD IX,ROOM_ATTR_BUF     ; first half: cells 0-255
  LD A,ROOM_PIXEL_BUF>>8
  LD (SmcPixelBufPage+$0001),A
  CALL BuildRoomBuffers_Half
  LD IX,ROOM_ATTR_BUF+THIRD_ATTRS_SIZE ; second half: cells 256-511
  LD A,(ROOM_PIXEL_BUF+THIRD_SIZE)>>8
  LD (SmcPixelBufPage+$0001),A
BuildRoomBuffers_Half:
  LD C,$00
BuildRoomBuffers_Cell:
  LD E,C                  ; E = cell index in this half
  LD A,(IX+$00)
  LD HL,RoomTiles
  LD BC,TILE_COUNT*TILE_SIZE
  CPIR
  LD C,E
  LD B,CELL_HEIGHT
SmcPixelBufPage:
  LD D,$00                ; operand $8D5D: set to $70 or $78 by this routine
BuildRoomBuffers_0:
  LD A,(HL)
  LD (DE),A
  INC HL
  INC D
  DJNZ BuildRoomBuffers_0
  INC IX
  INC C
  JP NZ,BuildRoomBuffers_Cell
  RET

; Expand the room layout into the attribute buffer
;
; Builds the attributes of the empty room (no sprites) at $5E00, 512 bytes for
; the 16 rows of 32 cells of the playing area:
;
; 1. Each of the 128 layout bytes at $8000 holds 4 cells of 2 bits, first cell
; in bits 7-6; every cell is replaced by its tile's attribute through
; StoreCellAttr. 2. If the conveyor length ($80D9) is not 0, that many cells
; starting at the conveyor address ($80D7, an address in the $5E00 buffer) get
; the conveyor tile's attribute (tile 5, $80CD). 3. If the ramp length ($80DD)
; is not 0, that many cells get the ramp tile's attribute (tile 4, $80C4),
; starting at the ramp address ($80DB) and moving up one row per cell, one
; column left when ramp direction bit 0 ($80DA) is 0 (step -33) and one column
; right when it is 1 (step -31).
;
; Observed: a Python model of these three steps reproduces $5E00-$5FFF of a
; snapshot taken in the Bathroom exactly (that room has a conveyor and a ramp
; going right).
;
; Hardware: none (memory only).
;
; O:A Corrupted (HL, IX, B, DE also change)
ExpandRoomLayout:
  LD HL,RoomBuffer
  LD IX,ROOM_ATTR_BUF
ExpandRoomLayout_Byte:
  LD A,(HL)
  RLCA
  RLCA
  CALL StoreCellAttr
  LD A,(HL)
  RRCA
  RRCA
  RRCA
  RRCA
  CALL StoreCellAttr
  LD A,(HL)
  RRCA
  RRCA
  CALL StoreCellAttr
  LD A,(HL)
  CALL StoreCellAttr
  INC HL
  LD A,L                  ; until HL reaches $8080
  AND ROOM_LAYOUT_SIZE
  JR Z,ExpandRoomLayout_Byte
  LD A,(RoomConveyorLen)
  OR A
  JR Z,ExpandRoomLayout_1
  LD HL,(RoomConveyorAddr)
  LD B,A
  LD A,(TileConveyor)
ExpandRoomLayout_0:
  LD (HL),A
  INC HL
  DJNZ ExpandRoomLayout_0
ExpandRoomLayout_1:
  LD A,(RoomRampLen)
  OR A
  RET Z
  LD HL,(RoomRampAddr)
  LD A,(RoomRampDir)
  AND $01
  RLCA
  ADD A,(-SCREEN_COLS-$01)&$FF ; E = $DF or $E1: step -33 or -31 (D = $FF)
  LD E,A
  LD D,$FF
  LD A,(RoomRampLen)
  LD B,A
  LD A,(TileRamp)
ExpandRoomLayout_2:
  LD (HL),A
  ADD HL,DE
  DJNZ ExpandRoomLayout_2
  RET

; Store the attribute of a layout cell
;
; Takes the low two bits of A as a tile number 0-3, reads that tile's attribute
; byte from the room buffer's tile table (RoomBuffer, tiles at $80A0, 9 bytes
; each) and stores it at (IX), then advances IX. Used by ExpandRoomLayout for
; each of the 4 cells of a layout byte.
;
;   A Layout cell value (bits 0-1 used)
;   IX Attribute buffer address of the cell
; O:IX Address of the next cell
; O:A Attribute stored
; O:C Cell value 0-3
; O:DE Address of the tile's attribute byte in the room buffer
StoreCellAttr:
  AND CELLS_PER_BYTE-$01
  LD C,A
  RLCA
  RLCA
  RLCA                    ; 8*tile
  ADD A,C                 ; 9*tile (TILE_SIZE)
  ADD A,RoomTiles-RoomBuffer
  LD E,A
  LD D,RoomBuffer>>8
  LD A,(DE)
  LD (IX+$00),A
  INC IX
  RET
