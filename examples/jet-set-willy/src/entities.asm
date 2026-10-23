; Move the entities of the room by one step
;
; Walks the entity buffer (EntityBuffer: 8 bytes per entity, an entry whose
; byte +0 is $FF ends the list) and moves every entity one step. FrameLoop
; calls it once per pass of the frame loop, before Willy is moved; a pass takes
; about 4 frames (F82). The entity type is in bits 0-2 of byte +0 and only bits
; 0-1 are tested here. Field use (see also EntityDefs and DrawEntities):
;
; Type 0 (empty entry) and type 4 (arrow, which DrawEntities moves itself):
; nothing here (type 4 reads as 0). Types 5-7 are moved like 1-3 and drawn like
; 1-2 (no room uses them).
;
; Type 1, horizontal guardian (MoveEntities_Horizontal): byte +0 bit 7 =
; direction (1 = right), bits 5-6 = animation phase. Every pass the phase
; counts down (going left) or up (going right) modulo 4; when it wraps the
; guardian steps one column (byte +2 bits 0-4, minus or plus 1), so it walks
; one column every 4 passes. At the end of its beat (column = byte +6 going
; left, = byte +7 going right) it turns instead of stepping: byte +0 becomes
; $81 (right, phase 0) or $61 (left, phase 3). Byte +2 bits 5-7 are not
; touched.
;
; Type 2, vertical guardian (MoveEntities_Vertical): byte +0 bit 3 flips every
; pass and the animation phase (bits 5-7) goes up by one when bit 3 or bit 4 is
; set after the flip, that is every pass when bit 4 is set and every second
; pass when it is clear. The Y index (byte +3, twice the pixel row) goes up by
; the signed step in byte +4 every pass (wrapping modulo 256). When Y reaches
; or passes the bottom limit (byte +7, unsigned compare) the step is negated;
; when it reaches or passes the top limit (byte +6) Y is set to that limit and
; the step is negated.
;
; Type 3, rope (MoveEntities_Rope): moves the swing position, byte +1. Bits 0-6
; = distance from hanging straight (index into RopeStepTable), bit 7 = side (0
; = leaning right, 1 = leaning left). Byte +0 bit 7 = swing direction (0: from
; the right side towards the left, 1: the other way). The distance changes by 2
; per pass near the ends and by 4 near the middle; when it equals byte +7 (the
; swing limit, $36) byte +0 bit 7 flips. About 45 passes from one end to the
; other.
;
; Checked against a Python model on 3000 random entity buffers (F81).
;
; Hardware: none.
MoveEntities:
  LD IX,EntityBuffer
MoveEntities_Loop:
  LD A,(IX+$00)
  CP ENTITY_END           ; end of the list
  RET Z
  AND ENTITY_MOVE_MASK    ; type bits 0-1: 0 = empty or arrow
  JP Z,MoveEntities_Next  ; nothing to move
  CP ENTITY_HORIZONTAL
  JP Z,MoveEntities_Horizontal
  CP ENTITY_VERTICAL
  JP Z,MoveEntities_Vertical
MoveEntities_Rope:
  BIT ENTITY_DIR_BIT,(IX+$00) ; type 3: swing direction
  JR Z,MoveEntities_1
  LD A,(IX+ENT_SWING)     ; swing position: bit 7 = side, bits 0-6 = distance
  BIT 7,A
  JR Z,MoveEntities_0
  SUB ROPE_STEP           ; direction 1, left side: distance down by 2 (by 4
                          ; once it is below $14)
  CP ROPE_SIDE_LEFT+ROPE_FAST_DOWN
  JR NC,MoveEntities_3
  SUB ROPE_STEP
  CP ROPE_SIDE_LEFT
  JR NZ,MoveEntities_3
  XOR A                   ; middle reached: stored as 0 (right side, distance
                          ; 0)
  JR MoveEntities_3
MoveEntities_0:
  ADD A,ROPE_STEP         ; direction 1, right side: distance up by 2 (by 4
                          ; while below $12)
  CP ROPE_FAST_UP
  JR NC,MoveEntities_3
  ADD A,ROPE_STEP
  JR MoveEntities_3
MoveEntities_1:
  LD A,(IX+ENT_SWING)     ; direction 0
  BIT 7,A
  JR NZ,MoveEntities_2
  SUB ROPE_STEP           ; right side: distance down by 2 (by 4 once it is
                          ; below $14)
  CP ROPE_FAST_DOWN
  JR NC,MoveEntities_3
  SUB ROPE_STEP
  OR A
  JR NZ,MoveEntities_3
  LD A,ROPE_SIDE_LEFT     ; middle reached: stored as $80 (left side, distance
                          ; 0)
  JR MoveEntities_3
MoveEntities_2:
  ADD A,ROPE_STEP         ; left side: distance up by 2 (by 4 while below $12)
  CP ROPE_SIDE_LEFT+ROPE_FAST_UP
  JR NC,MoveEntities_3
  ADD A,ROPE_STEP
MoveEntities_3:
  LD (IX+ENT_SWING),A     ; store the new swing position
  AND ROPE_DIST_MASK      ; distance only
  CP (IX+ENT_LIMIT_HIGH)  ; swing limit reached?
  JP NZ,MoveEntities_Next
  LD A,(IX+$00)           ; yes: flip the swing direction
  XOR $01<<ENTITY_DIR_BIT
  LD (IX+$00),A
  JP MoveEntities_Next
MoveEntities_Horizontal:
  BIT ENTITY_DIR_BIT,(IX+$00) ; type 1: direction
  JR NZ,MoveEntities_5
  LD A,(IX+$00)
  SUB ENTITY_PHASE_STEP   ; going left: phase down by one
  AND ($01<<ENTITY_DIR_BIT)-$01 ; direction bit stays clear
  LD (IX+$00),A
  CP ENTITY_LAST_PHASE*ENTITY_PHASE_STEP ; phase 3 means it wrapped from 0:
                                         ; step
  JR C,MoveEntities_Next
  LD A,(IX+ENT_COLUMN)    ; column
  AND COLUMN_MASK
  CP (IX+ENT_LIMIT_LOW)   ; left end of the beat?
  JR Z,MoveEntities_4
  DEC (IX+ENT_COLUMN)     ; no: one column left
  JR MoveEntities_Next
MoveEntities_4:
  LD (IX+$00),ENTITY_GO_RIGHT ; yes: turn right, phase 0
  JR MoveEntities_Next
MoveEntities_5:
  LD A,(IX+$00)           ; going right: phase up by one
  ADD A,ENTITY_PHASE_STEP
  OR $01<<ENTITY_DIR_BIT
  LD (IX+$00),A
  CP ENTITY_PHASE_STEP+($01<<ENTITY_DIR_BIT) ; phase 0 means it wrapped from 3:
                                             ; step (phase 1-3 give $A1 or
                                             ; more)
  JR NC,MoveEntities_Next
  LD A,(IX+ENT_COLUMN)    ; column
  AND COLUMN_MASK
  CP (IX+ENT_LIMIT_HIGH)  ; right end of the beat?
  JR Z,MoveEntities_6
  INC (IX+ENT_COLUMN)     ; no: one column right
  JR MoveEntities_Next
MoveEntities_6:
  LD (IX+$00),ENTITY_GO_LEFT ; yes: turn left, phase 3
  JR MoveEntities_Next
MoveEntities_Vertical:
  LD A,(IX+$00)           ; type 2
  XOR ENTITY_V_FLIP       ; bit 3 flips every pass
  LD (IX+$00),A
  AND ENTITY_V_ANIM_MASK  ; bits 3-4 set: phase up by one
  JR Z,MoveEntities_7
  LD A,(IX+$00)
  ADD A,ENTITY_PHASE_STEP
  LD (IX+$00),A
MoveEntities_7:
  LD A,(IX+ENT_Y)         ; Y index plus step
  ADD A,(IX+ENT_STEP)
  LD (IX+ENT_Y),A
  CP (IX+ENT_LIMIT_HIGH)  ; bottom limit reached or passed: reverse
  JR NC,MoveEntities_9
  CP (IX+ENT_LIMIT_LOW)   ; top limit
  JR Z,MoveEntities_8     ; at the top limit: clamp and reverse
  JR NC,MoveEntities_Next ; between the limits: nothing to do
MoveEntities_8:
  LD A,(IX+ENT_LIMIT_LOW) ; Y := top limit
  LD (IX+ENT_Y),A
MoveEntities_9:
  LD A,(IX+ENT_STEP)      ; step := -step
  NEG
  LD (IX+ENT_STEP),A
MoveEntities_Next:
  LD DE,ENTITY_SIZE
  ADD IX,DE
  JP MoveEntities_Loop

; Draw the entities of the room and test them against Willy
;
; Walks the entity buffer (EntityBuffer, 8 bytes per entity, an entry whose
; byte +0 is $FF ends the list) and draws every entity into the pixel buffer at
; $6000 and the attribute buffer at $5C00, on top of the room and of Willy, who
; PlaceWilly has already drawn. The entity type is bits 0-2 of byte +0: 0 is
; skipped, 3 is the rope (DrawEntities_Rope), 4 the arrow (DrawEntities_Arrow),
; anything else (1 and 2; 5-7 would be treated the same) a sprite guardian
; (DrawEntities_Guardian). A collision jumps to KillWilly (KillWilly), which
; abandons the frame update, so the entities after the one that hit Willy are
; not drawn in that pass. Moving the entities is MoveEntities, except for the
; arrow, which moves here.
;
; Guardian (types 1 and 2): +0 type and animation bits, +1 bits 0-2 ink, bit 3
; bright, bits 5-7 frame mask, +2 bits 0-4 column of the left cell, bits 5-7
; frame offset, +3 Y index (twice the pixel row, as in RowAddressTable), +5
; sprite page. The sprite address is page * 256 + F with F = ((+0 AND +1) OR
; +2) AND $E0, so the frame number is bits 5-7 (the mask in +1 decides how much
; of the animation bits of +0 selects the frame, the bits of +2 are or-ed in).
; First the attributes: the 2 x 2 cells under the sprite (2 x 3 when the Y
; index is not a multiple of 16) get the ink and bright bits of +1, keeping the
; paper of the background and clearing flash. Then DrawSprite draws the sprite
; into the $6000 buffer with the collision test (C = 1): any lit pixel already
; there (Willy, but also the room tiles) kills Willy (F83).
;
; Arrow (type 4, DrawEntities_Arrow): +0 bit 7 direction, +2 Y index of its
; centre row (bit 7 = lower half of the room), +4 X column (moves one column
; per pass), +5 scratch (collision mask), +6 pixel pattern of the fins. See
; F84, F85, F86: it is drawn only while X is 0-31, as one cell wide: the fin
; pattern above and below a solid centre row, in white ink; when X reaches $2C
; (left) or $F4 (right) the pass makes a rising chirp instead (128 speaker
; toggles, about 32 ms). It kills Willy when its attribute cell has ink 7 and
; the centre row byte is not empty. Quirk (F92): the arrow of The Attic has the
; odd Y index $D5, so the row table is read half a word off and its pixels go
; to $9F6A+X and $A06A+X (inside EntityDefs), its attributes to $5D6A+X.
;
; Rope (type 3, DrawEntities_Rope): +1 swing position (moved by MoveEntities),
; +2 column of the top, +3 scratch (current column), +4 length in segments ($20
; gives 33 points), +5 scratch (pixel mask, starts at $80). The rope also uses
; the entry after it: its byte +1 is the segment counter (the rope's byte +9)
; and bit 0 of its byte +3 the held flag (the rope's byte +11), so a rope is
; followed by an arrow or by the $FF end marker (F90). The rope is a chain of
; one-pixel points starting at pixel row 0 of the room; the next point is found
; from RopeStepTable with the index segment + swing distance: the second half
; gives the rows down (row table bytes, 2 per pixel row), the first half the
; pixels sideways (left when bit 7 of +1 is set, else right). Points are ORed
; into the buffer, in the ink of the background.
;
; Willy and the rope use WillyRope: 0 = Willy holds no rope; 1-$20 = number of
; the rope segment he holds; $F0-$FF = he has just let go (counts up by 1 per
; rope pass, so for 16 passes he cannot grab again). While it is 0, any lit
; pixel of the buffer under a rope point grabs the rope there (Willy, drawn
; earlier, is the normal case; a room tile or another entity would do it too,
; F87). While held, every pass puts Willy on the rope: his Y index (WillyY) is
; the Y index of the point minus $10 (the rope passes through the middle of the
; sprite), his column and frame (WillyAttrAddr, WillyFrame) are taken from the
; pixel mask of the point (mask $80 or $40: frame 2, $20 or $10: frame 3, both
; with the column one to the left; $08 or $04: frame 0, $02 or $01: frame 1, in
; the point's own column), and SetWillyCell recomputes his attribute address.
; At the end of the rope (F88, F89): during the release countdown $85D6 is
; counted up and the held flag cleared; otherwise, if the rope is held and
; Willy walks (bit 1 of WillyMoveState), $85D6 goes down one segment (higher
; up) or up one segment (lower down): +1 when his facing (bit 0 of
; WillyMoveState, 1 = left) differs from the swing direction bit (bit 7 of +0),
; else -1. In a room whose up exit (RoomExitUp) is the room itself he cannot go
; above segment $0C. Past the last segment he is let go: WillyRope := $F0, his
; Y index is rounded down to a multiple of 8 and the jump/fall state
; WillyAirState is cleared. Quirk (F91): a lit pixel under point 0 sets the
; held flag and moves Willy to the top of the rope without setting $85D6.
;
; Hardware: writes the $6000 pixel buffer and the $5C00 attribute buffer; the
; arrow chirp toggles the speaker and border bits of port $FE in a busy-wait
; loop.
DrawEntities:
  LD IX,EntityBuffer
DrawEntities_Loop:
  LD A,(IX+$00)
  CP ENTITY_END
  RET Z
  AND ENTITY_TYPE_MASK
  JP Z,DrawEntities_Next  ; empty
  CP ENTITY_ROPE
  JP Z,DrawEntities_Rope
  CP ENTITY_ARROW
  JR Z,DrawEntities_Arrow
DrawEntities_Guardian:
  LD E,(IX+ENT_Y)         ; guardian: E = Y index
  LD D,RowAddressTable>>8
  LD A,(DE)               ; low byte of the row address in the buffer
  LD L,A
  LD A,(IX+ENT_COLUMN)    ; plus the column
  AND COLUMN_MASK
  ADD A,L
  LD L,A
  LD A,E                  ; Y index bit 7: upper or lower half of the room
  RLCA
  AND $01
  OR SCREEN_ATTRS_BUF>>8
  LD H,A                  ; HL = attribute buffer address of the top-left cell
  LD DE,SCREEN_COLS-$0001 ; to the next row of cells, one column left
  LD A,(IX+$01)
  AND ENTITY_ATTR_MASK    ; ink and bright
  ADD A,WHITE*PAPER       ; bright becomes bit 6, the paper bits are cleared by
                          ; the next AND
  AND BRIGHT+INK_MASK
  LD C,A                  ; C = attribute without paper
  LD A,(HL)
  AND PAPER_MASK          ; keep the paper of the background
  XOR C
  LD C,A
  LD (HL),C
  INC HL
  LD (HL),C
  ADD HL,DE
  LD (HL),C
  INC HL
  LD (HL),C
  LD A,(IX+ENT_Y)         ; Y index in the lower bits
  AND Y_BETWEEN_MASK      ; 0 when the sprite starts on a character row
  JR Z,DrawEntities_Sprite ; two rows of cells only
  ADD HL,DE               ; third row of cells
  LD (HL),C
  INC HL
  LD (HL),C
DrawEntities_Sprite:
  LD C,DRAW_COLLIDE       ; draw with collision test
  LD A,(IX+$01)
  AND (IX+$00)
  OR (IX+ENT_COLUMN)
  AND ENTITY_FRAME_MASK   ; frame number * 32
  LD E,A
  LD D,(IX+ENT_PAGE)      ; sprite page
  LD H,RowAddressTable>>8
  LD L,(IX+ENT_Y)         ; Y index
  LD A,(IX+ENT_COLUMN)
  AND COLUMN_MASK
  OR (HL)                 ; row address low byte plus column
  INC HL
  LD H,(HL)               ; row address high byte
  LD L,A
  CALL DrawSprite         ; DrawSprite: NZ at the first overlap
  JP NZ,KillWilly         ; overlap: Willy is killed
  JP DrawEntities_Next    ; no collision
DrawEntities_Arrow:
  BIT ENTITY_DIR_BIT,(IX+$00) ; arrow: direction
  JR NZ,DrawEntities_0
  DEC (IX+ENT_ARROW_X)    ; left: X down by one
  LD C,ARROW_BEEP_LEFT    ; X value that makes the beep
  JR DrawEntities_1
DrawEntities_0:
  INC (IX+ENT_ARROW_X)    ; right: X up by one
  LD C,ARROW_BEEP_RIGHT
DrawEntities_1:
  LD A,(IX+ENT_ARROW_X)
  CP C                    ; beep value reached?
  JR NZ,DrawEntities_ArrowDraw
  LD BC,$0002*HI_BYTE+ARROW_BEEP_COUNT ; B = 2: first delay; C = 128 toggles
  LD A,(RoomBorder)       ; border colour of the room
DrawEntities_ArrowBeep:
  OUT (ULA_PORT),A
  XOR BEEPER_BITS
DrawEntities_2:
  DJNZ DrawEntities_2
  LD B,C                  ; next delay = counter, falling: the pitch rises
  DEC C
  JR NZ,DrawEntities_ArrowBeep
  JP DrawEntities_Next    ; the arrow is not drawn in this pass
DrawEntities_ArrowDraw:
  AND ~COLUMN_MASK        ; X outside 0-31: off screen
  JP NZ,DrawEntities_Next
  LD E,(IX+ENT_ARROW_Y)   ; Y index of the centre row
  LD D,RowAddressTable>>8
  LD A,(DE)
  ADD A,(IX+ENT_ARROW_X)  ; plus X
  LD L,A
  LD A,E                  ; Y index bit 7: upper or lower half of the room
  AND Y_LOWER_HALF
  RLCA
  OR SCREEN_ATTRS_BUF>>8
  LD H,A                  ; HL = attribute buffer address of the arrow cell
  LD (IX+ENT_ARROW_MASK),$00 ; collision mask: none
  LD A,(HL)
  AND INK_MASK
  CP WHITE                ; white ink: Willy is in this cell
  JR NZ,DrawEntities_3
  DEC (IX+ENT_ARROW_MASK) ; mask $FF
DrawEntities_3:
  LD A,(HL)
  OR WHITE                ; the arrow is white
  LD (HL),A
  INC DE                  ; high byte of the row address
  LD A,(DE)
  LD H,A
  DEC H                   ; the pixel row above the centre row
  LD A,(IX+ENT_ARROW_FINS)
  LD (HL),A               ; fins
  INC H
  LD A,(HL)               ; centre row: anything lit there?
  AND (IX+ENT_ARROW_MASK) ; only counts in a white-ink cell
  JP NZ,KillWilly         ; Willy is killed
  LD (HL),$FF             ; solid centre row
  INC H
  LD A,(IX+ENT_ARROW_FINS)
  LD (HL),A               ; fins below
  JP DrawEntities_Next
DrawEntities_Rope:
  LD IY,RowAddressTable   ; rope: IY = row table, starts at pixel row 0
  LD (IX+ROPE_SEGMENT),$00 ; segment 0 (byte +1 of the next entry)
  LD A,(IX+ENT_COLUMN)
  LD (IX+ENT_ROPE_COLUMN),A ; current column := column of the top
  LD (IX+ENT_ROPE_MASK),PIXEL_LEFT ; pixel mask: leftmost pixel
DrawEntities_Segment:
  LD A,(IY+$00)
  ADD A,(IX+ENT_ROPE_COLUMN)
  LD L,A                  ; row address low byte plus column
  LD H,(IY+$01)           ; HL = pixel buffer address of this point
  LD A,(WillyRope)        ; rope variable: 0 = no rope held
  OR A
  JR NZ,DrawEntities_Held
  LD A,(IX+ENT_ROPE_MASK) ; no rope held: is the pixel under this point lit?
  AND (HL)
  JR Z,DrawEntities_Plot
  LD A,(IX+ROPE_SEGMENT)  ; grab: remember the segment
  LD (WillyRope),A
  SET 0,(IX+ROPE_HELD)    ; held flag
DrawEntities_Held:
  CP (IX+ROPE_SEGMENT)    ; is this the segment Willy holds?
  JR NZ,DrawEntities_Plot
  BIT 0,(IX+ROPE_HELD)    ; and does this rope hold him?
  JR Z,DrawEntities_Plot
  LD B,(IX+ENT_ROPE_COLUMN) ; column
  LD A,(IX+ENT_ROPE_MASK)
  LD C,$01                ; from the pixel mask: C = Willy frame, B = column of
                          ; his left cell
  CP $04
  JR C,DrawEntities_4
  LD C,$00
  CP $10
  JR C,DrawEntities_4
  DEC B
  LD C,$03
  CP $40
  JR C,DrawEntities_4
  LD C,$02
DrawEntities_4:
  LD (WillyFrame),BC      ; Willy frame ($85D2) and column ($85D3)
  LD A,IYL                ; Y index of this point
  SUB Y_ROW_STEP          ; minus 8 pixel rows
  LD (WillyY),A           ; Willy Y index
  PUSH HL
  CALL SetWillyCell       ; Willy attribute address from his Y index and column
  POP HL
  JR DrawEntities_Plot    ; (jumps to the next instruction)
DrawEntities_Plot:
  LD A,(IX+ENT_ROPE_MASK) ; plot the point
  OR (HL)
  LD (HL),A
  LD A,(IX+ROPE_SEGMENT)  ; segment
  ADD A,(IX+$01)          ; plus swing position
  LD L,A
  SET 7,L                 ; second half of the rope table
  LD H,RopeStepTable>>8
  LD E,(HL)               ; rows down (row table bytes)
  LD D,$00
  ADD IY,DE               ; IY to the next point
  RES 7,L
  LD A,(HL)               ; first half: pixels sideways
  OR A
  JR Z,DrawEntities_NextSegment
  LD B,A
  BIT 7,(IX+$01)          ; side: bit 7 set = left
  JR Z,DrawEntities_ShiftRight
DrawEntities_ShiftLeft:
  RLC (IX+ENT_ROPE_MASK)  ; mask one pixel left
  BIT 0,(IX+ENT_ROPE_MASK) ; moved into the next byte?
  JR Z,DrawEntities_5
  DEC (IX+ENT_ROPE_COLUMN) ; column left
DrawEntities_5:
  DJNZ DrawEntities_ShiftLeft
  JR DrawEntities_NextSegment
DrawEntities_ShiftRight:
  RRC (IX+ENT_ROPE_MASK)  ; mask one pixel right
  BIT 7,(IX+ENT_ROPE_MASK) ; moved into the next byte?
  JR Z,DrawEntities_6
  INC (IX+ENT_ROPE_COLUMN) ; column right
DrawEntities_6:
  DJNZ DrawEntities_ShiftRight
DrawEntities_NextSegment:
  LD A,(IX+ROPE_SEGMENT)  ; last point?
  CP (IX+ENT_ROPE_LENGTH)
  JR Z,DrawEntities_RopeEnd
  INC (IX+ROPE_SEGMENT)
  JP DrawEntities_Segment
DrawEntities_RopeEnd:
  LD A,(WillyRope)        ; rope variable
  BIT 7,A                 ; $F0-$FF: release countdown
  JR Z,DrawEntities_Climb
  INC A                   ; count up
  LD (WillyRope),A
  RES 0,(IX+ROPE_HELD)    ; clear the held flag
  JR DrawEntities_Next
DrawEntities_Climb:
  BIT 0,(IX+ROPE_HELD)    ; rope held?
  JR Z,DrawEntities_Next
  LD A,(WillyMoveState)   ; Willy walking state
  BIT 1,A                 ; walking?
  JR Z,DrawEntities_Next
  RRCA                    ; bit 1 of the result: facing left XOR swing
                          ; direction
  XOR (IX+$00)
  RLCA
  RLCA
  AND $02
  DEC A                   ; +1 or -1
  LD HL,WillyRope
  ADD A,(HL)
  LD (HL),A               ; one segment down or up
  LD A,(RoomExitUp)       ; up exit of the room
  LD C,A
  LD A,(CurrentRoom)      ; current room
  CP C                    ; no room above: the up exit is the room itself
  JR NZ,DrawEntities_Limit
  LD A,(HL)
  CP ROPE_MIN_SEGMENT
  JR NC,DrawEntities_Limit
  LD (HL),ROPE_MIN_SEGMENT ; not higher than this segment
DrawEntities_Limit:
  LD A,(HL)               ; past the last segment?
  CP (IX+ENT_ROPE_LENGTH)
  JR C,DrawEntities_Next
  JR Z,DrawEntities_Next
  LD (HL),ROPE_LET_GO     ; let go at the bottom
  LD A,(WillyY)
  AND Y_SNAP_MASK         ; Y index down to a multiple of 8
  LD (WillyY),A
  XOR A
  LD (WillyAirState),A    ; clear the jump/fall state
  JR DrawEntities_Next    ; (jumps to the next instruction)
DrawEntities_Next:
  LD DE,ENTITY_SIZE
  ADD IX,DE
  JP DrawEntities_Loop

; Unused code fragment: fill a 2x3 block of attribute cells
;
; Never executed and unreachable: it follows the unconditional JP $91C2 at the
; end of DrawEntities, and no jump, call or word in the image points to
; $93BB-$93D0. It starts with LD (HL),A, so it looks like the tail of a routine
; whose first part is not in the image; what it was called from is Unknown.
;
; What it would do (checked by calling it in the simulator with HL=$58A5, A=2
; and $80A0=$38): the ink A is merged with the paper, bright and flash bits of
; the room's first tile attribute ($80A0, the background tile) and stored in
; the 2x3 block of attribute cells (2 wide, 3 high) whose top-left cell is HL:
; (HL), (HL+1), (HL+$20), (HL+$21), (HL+$40), (HL+$41). Result there: $3A in
; all six cells.
;
; Hardware: writes screen attributes.
;
; A Ink colour (bits 0-2) HL Attribute address of the top-left cell
FillAttrBlock:
  LD (HL),A
  LD A,(RoomTiles)        ; attribute of the room background tile
  AND ATTR_INK_CLEAR      ; keep paper, bright, flash
  OR (HL)
  LD (HL),A
  LD DE,SCREEN_COLS-$0001 ; with INC HL: next row, same column
  INC HL
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  INC HL
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  INC HL
  LD (HL),A
  RET
