; Current room buffer
;
; A copy of the current room's 256-byte definition (from $C000+256*room, copied
; by ScrollTitleMessage at room entry). The routines that draw and move things
; read the room from here. Format (offsets from $8000):
;
; $00-$7F: layout, 512 cells (16 rows of 32), 2 bits per cell, 4 cells per byte
; with the first cell in bits 7-6. A cell value 0-3 selects tile 0-3 below
; (ExpandRoomLayout expands this into attributes).
;
; $80-$9F: room name (32 ASCII characters, shown in the status line).
;
; $A0-$D5: six tiles of 9 bytes: attribute, then 8 pixel rows. The tiles are
; (in this order) background, floor, wall, nasty, ramp, conveyor; only the
; first four can appear in the layout, ramp and conveyor are added from their
; fields. The routines compare attributes read from the attribute buffer with
; these tile attributes to find out what is where, so the attributes of the six
; tiles of one room should differ.
;
; $D6: conveyor direction; $D7: conveyor address (word, in the $5E00 attribute
; buffer); $D9: conveyor length in cells.
;
; $DA: ramp direction (bit 0); $DB: ramp address (word, in the $5E00 attribute
; buffer); $DD: ramp length in cells.
;
; $DE: border colour. $DF-$E0: Unknown.
;
; $E1-$E8: item graphic (8 bytes, one character cell).
;
; $E9-$EC: room numbers to the left, right, up and down.
;
; $ED-$EF: Unknown.
;
; $F0-$FF: eight entity slots, 2 bytes each: definition index (bit 7 Unknown,
; cleared before use), and one byte stored into the entity buffer
; (EntityBuffer). Entity definitions are at $A000, 8 bytes each.
RoomBuffer:
  DEFS $0080
RoomName:
  DEFS $0020
RoomTiles:
  DEFS $09
TileFloor:
  DEFS $09
TileWall:
  DEFS $09
TileNasty:
  DEFS $09
TileRamp:
  DEFS $09
TileConveyor:
  DEFS $09
RoomConveyorDir:
  DEFS $01
RoomConveyorAddr:
  DEFS $02
RoomConveyorLen:
  DEFS $01
RoomRampDir:
  DEFS $01
RoomRampAddr:
  DEFS $02
RoomRampLen:
  DEFS $01
RoomBorder:
  DEFS $01
  DEFS $02
RoomItemGfx:
  DEFS $08
RoomExitLeft:
  DEFS $01
RoomExitRight:
  DEFS $01
RoomExitUp:
  DEFS $01
RoomExitDown:
  DEFS $01
  DEFS $03
RoomEntitySlots:
  DEFS $10

; Entity buffer: 8 entities of 8 bytes, ended by $FF
;
; Filled at room entry by ScrollTitleMessage: for each of the 8 entity slots of
; the room (RoomEntitySlots) the 8-byte definition at $A000+8*index is copied
; here; its byte +2 is first replaced by the slot's second byte (observed: the
; definition table itself is modified too, e.g. $A1DA changes from $00 to $10
; in the Bathroom). The entities are then updated and drawn each frame by
; MoveEntities and DrawEntities, which stop at an entry whose first byte is
; $FF. Slot index $7F points to the definition at $A3F8, which starts with $FF,
; so a room that uses fewer than 8 slots ends the list early (observed in the
; Bathroom: entry 1 is $FF); the byte at $8140 ends the list when all 8 slots
; are used.
;
; Entry fields (from the code; most are Unknown until MoveEntities and
; DrawEntities are annotated):
;
; +0 byte: bits 0-1 select the kind of movement handled by MoveEntities (0 =
; none, 1, 2 and 3 take different paths); other bits Unknown (bit 7 is toggled
; by the update code, bits 5-6 change in steps of $20); $FF ends the list
;
; +1 byte: Unknown (animation/phase counter)
;
; +2 byte: low 5 bits: screen column; high 3 bits: used with +0 and +1 to
; choose the animation frame (multiple of $20 in the sprite page)
;
; +3 byte: vertical position, an index into the row address table
; RowAddressTable (2 per pixel row)
;
; +4 byte: vertical step (kind 2 adds it to +3 and reverses it at the limits)
;
; +5 byte: high byte of the sprite page address
;
; +6, +7 bytes: limits (positions where the entity turns), Unknown which fields
; they bound for each kind
EntityBuffer:
  DEFS $40
  DEFB $FF

; Unused area after the entity buffer
;
; Zeros in the tape image; nothing in the code refers to this range as far as
; the entries checked show (see RoomBuffer for the buffers before it).
L8141:
  DEFS $BF

; Row address table of the $6000 bitmap buffer
;
; 128 words: for pixel row r (0-127, index 2*r), the address of its first byte
; in the $6000 buffer, which has the layout of the screen bitmap: address =
; $6000 + 256*(r MOD 8) + 32*((r DIV 8) MOD 8) + $800*(r DIV 64). Rows 0-127
; are the 16 character rows of the playing area (the top two thirds of the
; screen); the buffer is copied to $4000 by FrameLoop. Sprite routines add the
; column (0-31) to the low byte (OR) and step by index in steps of 2. Observed:
; all 128 words match the formula (checked on a snapshot).
;
; Hardware: none (data for the bitmap buffer at $6000).
RowAddressTable:
  DEFW SCREEN_PIXEL_BUF,$6100,$6200,$6300,$6400,$6500,$6600,$6700
  DEFW $6020,$6120,$6220,$6320,$6420,$6520,$6620,$6720
  DEFW $6040,$6140,$6240,$6340,$6440,$6540,$6640,$6740
  DEFW $6060,$6160,$6260,$6360,$6460,$6560,$6660,$6760
  DEFW $6080,$6180,$6280,$6380,$6480,$6580,$6680,$6780
  DEFW $60A0,$61A0,$62A0,$63A0,$64A0,$65A0,$66A0,$67A0
  DEFW $60C0,$61C0,$62C0,$63C0,$64C0,$65C0,$66C0,$67C0
  DEFW $60E0,$61E0,$62E0,$63E0,$64E0,$65E0,$66E0,$67E0
  DEFW $6800,$6900,$6A00,$6B00,$6C00,$6D00,$6E00,$6F00
  DEFW $6820,$6920,$6A20,$6B20,$6C20,$6D20,$6E20,$6F20
  DEFW $6840,$6940,$6A40,$6B40,$6C40,$6D40,$6E40,$6F40
  DEFW $6860,$6960,$6A60,$6B60,$6C60,$6D60,$6E60,$6F60
  DEFW $6880,$6980,$6A80,$6B80,$6C80,$6D80,$6E80,$6F80
  DEFW $68A0,$69A0,$6AA0,$6BA0,$6CA0,$6DA0,$6EA0,$6FA0
  DEFW $68C0,$69C0,$6AC0,$6BC0,$6CC0,$6DC0,$6EC0,$6FC0
  DEFW $68E0,$69E0,$6AE0,$6BE0,$6CE0,$6DE0,$6EE0,$6FE0

; Rope shape tables (per-segment steps, 2 x 128 bytes)
;
; Describes the curve of a swinging rope (entity type 3, the entity routine
; DrawEntities; the swing itself is moved by MoveEntities). The rope is drawn
; as a chain of points, one pixel each. For every segment S (0 to the rope
; length, byte 4 of the entity, $20 for the ropes in this game) the routine
; takes the index I = S + swing phase (low 7 bits of entity byte 1) and, after
; plotting the point, moves to the next one by two steps taken from this table:
;
; +$00-$7F (read with L = I): number of pixels to move sideways (0-3), to the
; left when bit 7 of entity byte 1 is set, to the right when it is clear.
; +$80-$FF (read with L = I OR $80): vertical step, as a number of bytes in the
; pixel-row table RowAddressTable (2 bytes per pixel row, so 6 = 3 pixel rows
; and 4 = 2 pixel rows).
;
; The data is only defined for I = 0 to $55; the rest is zero. The largest
; phase is $36 (entity byte 7 of the rope definition) plus the length $20 gives
; $56, whose value is also zero. For a small index the rope hangs straight down
; (3 rows per segment, no sideways steps); the larger the index, the more the
; segments lean (up to 3 pixels sideways with 2 rows down), so the swing phase
; bends the rope progressively from the top.
;
; Observed with the simulator in "We must perform a Quirkafleeg" (room $10):
; plotting the chain from these tables reproduces the rope pixels on screen (33
; of 33 points at three of five sampled frames, the screen being one update
; behind the phase byte).
;
; Hardware: none.
RopeStepTable:
  DEFS $20
  DEFB $01,$01,$01,$01,$01,$01,$01,$01
  DEFB $01,$01,$01,$01
  DEFS $16,$02
  DEFB $01,$02,$02,$01,$01,$02,$01,$01,$02,$02,$03,$02,$03,$02,$03,$03
  DEFB $03,$03,$03,$03
  DEFS $2A
RopeStepTable_Rows:
  DEFS $30,$06
  DEFB $04,$06,$06,$04,$06,$04,$06,$04
  DEFB $06,$04,$04,$04,$06
  DEFS $19,$04
  DEFS $2A
