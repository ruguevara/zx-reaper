; Draw the water row: its attribute and the reflection of the scenery above it
;
; Called once per pass by the main loop StartGame. The byte at
; DrawWaterReflection is RET until a room script uses op $9D, which
; OpSetupWater turns into NOP (room entry EnterRoom puts the RET back), and
; then writes the operands of the instructions below: this routine is the water
; of room 16 (a lake of blood) and room 19 (the underground river). Every pass
; it (1) writes the attribute to the `width` cells of the water row and (2)
; redraws the bitmap of that row as a reflection: 8 pixel lines, each a copy of
; `width` bytes, the first one the bottom line of the row (a line is picked
; every third pixel line starting at the top of the cell row 3 rows above the
; water, so the 24 lines of the three cell rows above the water come out
; squashed to a third of their height and upside down). The copy is made by the
; chain of 32 LDI instructions at WaterCopyChain: the JR at SmcWaterJump jumps
; into the chain so that only `width` of them run (LADC1 steps the two pointers
; to the next line, see there). The patched operands are labelled; OpSetupWater
; writes them:
;
; SmcWaterAttrAddr attribute address of the first water cell
; (SmcWaterAttrAddr+1), SmcWaterAttr attribute (SmcWaterAttr+1), SmcWaterWidth
; width in cells (SmcWaterWidth+1), SmcWaterSrc bitmap address of the first
; source line (SmcWaterSrc+1), SmcWaterDst bitmap address of the first
; destination line (SmcWaterDst+1), SmcWaterCount bytes to copy, width x 8
; (SmcWaterCount+1) and SmcWaterJump the JR offset, 2 x (32 - width)
; (SmcWaterJump+1).
;
; Hardware: writes the attribute file and the screen bitmap (the water row, 8
; pixel lines).
DrawWaterReflection:
  NOP                     ; RET unless op $9D of the room script switched the
                          ; water on
SmcWaterAttrAddr:
  LD HL,$0000             ; attribute address of the first cell (patched by
                          ; OpSetupWater)
SmcWaterAttr:
  LD A,$00                ; water attribute (patched)
SmcWaterWidth:
  LD B,$00                ; width in cells (patched)
DrawWaterReflection_Attr:
  LD (HL),A               ; paint the attribute of the water cells
  INC L
  DJNZ DrawWaterReflection_Attr
SmcWaterSrc:
  LD HL,$0000             ; source: first pixel line, 3 cell rows above the
                          ; water (patched)
SmcWaterDst:
  LD DE,$0000             ; destination: bottom pixel line of the water row
                          ; (patched)
SmcWaterCount:
  LD BC,$0000             ; width x 8 (patched): reaches 0 after the 8th line
; Loop head, one pixel line per pass (also jumped to from LADC1): remember the
; start of the source and destination lines, then copy the line by jumping into
; the LDI chain.
DrawWaterReflection_Line:
  PUSH HL
  PUSH DE
SmcWaterJump:
  JR SmcWaterJump         ; offset patched to 2 x (32 - width): skips the LDIs
                          ; that are not needed

; Water reflection: first 16 of the 32 LDIs that copy one pixel line
;
; The chain of WaterCopyChain-ADE0 copies up to 32 bytes from (HL) to (DE) and
; counts BC down. The JR at SmcWaterJump of DrawWaterReflection enters it 2 x
; (32 - width) bytes after its start so that exactly `width` (at most 32,
; LDI_CHAIN_LEN) bytes are copied, then execution runs on into LADC1, which
; ends with the second half of the chain. Falls through to LADC1 after the 16th
; LDI.
WaterCopyChain:
  LDI                     ; the chain: 32 LDIs from here to ADE0
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

; Water reflection: last 16 LDIs of the chain, then step to the next pixel line
;
; Continues the chain of WaterCopyChain with its second half; after the 32nd
; LDI the code at ADE1 finishes one pixel line of DrawWaterReflection: it
; restores the start of the source and destination lines, returns when BC is 0
; (all 8 lines of the water row are done) and otherwise moves the destination
; one pixel line up (DEC D, the reflection is upside down) and the source three
; pixel lines down. The source step is three INC H; whenever one of them
; reaches the next character row (the address wraps from pixel line 7 to line 0
; of the next row) L gets 32 added and H is reduced by 8, except when the
; addition carries, which moves to the next third of the screen and needs no
; correction. Then it loops to DrawWaterReflection_Line.
;
; Hardware: none, the pointers are screen bitmap addresses (the copying was
;           done by the LDIs).
;          HL Source line address, advanced by the LDIs (the entry state is the
;             one saved by DrawWaterReflection_Line)
;          DE Destination line address, advanced by the LDIs
;          BC Bytes left to copy
LADC1:
  LDI                     ; second half of the chain (16 LDIs)
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
  POP DE                  ; start of the destination line
  POP HL                  ; start of the source line
  RET PO                  ; BC = 0 (P/V clear after the last LDI): 8 lines done
  DEC D                   ; destination: one pixel line up
  LD A,H
  OR $07
  INC A                   ; A = H of the start of the next character row of the
                          ; source
  INC H                   ; source line + 1
  CP H
  JR NZ,LADC1_1           ; still inside the row
  LD A,L                  ; reached the next row after one step: 32 to L, wrap
                          ; the third
  ADD A,$20
  LD L,A
  JR C,LADC1_0            ; carry: next third of the screen, H is already right
  LD A,H
  SUB $08
  LD H,A
LADC1_0:
  INC H                   ; the other two of the three steps
  INC H
  JP DrawWaterReflection_Line ; next line
LADC1_1:
  INC H                   ; source line + 2
  CP H
  JR NZ,LADC1_3
  LD A,L                  ; reached the next row after two steps
  ADD A,$20
  LD L,A
  JR C,LADC1_2
  LD A,H
  SUB $08
  LD H,A
LADC1_2:
  INC H                   ; the third step
  JP DrawWaterReflection_Line ; next line
LADC1_3:
  INC H                   ; source line + 3
  CP H
  JP NZ,DrawWaterReflection_Line ; same row: next line
  LD A,L                  ; reached the next row after three steps
  ADD A,$20
  LD L,A
  JR C,LADC1_4
  LD A,H
  SUB $08
  LD H,A
LADC1_4:
  JP DrawWaterReflection_Line ; next line

; Animate the bubbling blood tiles of the bottom row
;
; Called once per pass by the main loop StartGame. The byte at
; AnimateBloodTiles is RET until the room script uses op $9E (OpAnimateBlood,
; rooms 21, 22 and 23: the red blood at the foot of the room), which makes it
; NOP; room entry (EnterRoom) puts the RET back. Every second pass
; (BloodAnimTimer) it goes along the bottom row of the tile map (row 21) and
; swaps tile $3B for $3C and $3C for $3B, and sets the redraw bit in the tile
; flag map for each cell it changed, so that the blood flickers. The cells keep
; their flag class, the swap only changes what is drawn.
;
; Hardware: none directly (the redraw step of the main loop, BuildRedrawList
;           and DrawRedrawList, paints the marked cells).
AnimateBloodTiles:
  NOP                     ; RET unless op $9E of the room script switched the
                          ; animation on
  LD HL,BloodAnimTimer    ; pass counter
  DEC (HL)
  RET NZ
  LD (HL),BLOOD_ANIM_PERIOD ; every second pass
  LD BC,SCREEN_COLS*$0100+$0001 ; B = 32 cells of the row (C is not used)
  LD DE,TILE_MAP+(MAP_ROWS-$0001)*SCREEN_COLS ; tile map, row 21
  LD HL,FLAG_MAP+(MAP_ROWS-$0001)*SCREEN_COLS ; tile flag map, row 21 (same low
                                              ; byte as DE)
AnimateBloodTiles_Cell:
  LD A,(DE)
  CP TILE_BLOOD_A
  JR Z,AnimateBloodTiles_0
  CP TILE_BLOOD_B
  JR Z,AnimateBloodTiles_1
  INC E                   ; some other tile: next cell
  DJNZ AnimateBloodTiles_Cell
  RET
AnimateBloodTiles_0:
  INC A                   ; $3B becomes $3C
  LD (DE),A
  JR AnimateBloodTiles_2
AnimateBloodTiles_1:
  DEC A                   ; $3C becomes $3B
  LD (DE),A
AnimateBloodTiles_2:
  LD L,E
  SET 7,(HL)              ; FLAG_REDRAW: mark the cell for redraw
  INC E
  DJNZ AnimateBloodTiles_Cell
  RET

; Show the ring of twelve crosses in Satan's room, flashing in colour
;
; Called once per pass by the main loop StartGame. The byte at ShowCrossRing is
; RET until the room script uses op $9F (OpTwelveCrosses, at the end of room
; 24's script, which room 25 calls too); room entry (EnterRoom) puts the RET
; back. Once the player holds 12 crosses (Crosses) it acts on every fifth pass
; (CrossFlashTimer; observed in room 24: every 8 to 9 interrupt frames, the
; main loop is slower than one pass per frame there): it advances the colour
; cycle (the operand of the LD A,n at SmcCrossColour holds the position 0-5)
; and copies the new attribute from CrossColours to the attribute of the ring
; cross tile (CE4C). Unless the chalice has been taken (ChaliceTaken) it then
; adds one cross to the ring (CrossRingCount, one cross per step until 12, with
; sound effect 5) and stamps that many crosses, tile $4C, at the first cells of
; the list at CrossRingPositions (row, column pairs, also read by the erase
; script ScriptEraseCrosses), which marks them for redraw; with all 12 shown it
; restamps them every time, so they keep flashing.
;
; Hardware: none directly (the crosses are drawn by the redraw routine
; RedrawRoom); requests sound effect 5 through SoundRequest.
ShowCrossRing:
  NOP                     ; RET unless op $9F of the room script switched the
                          ; ring on
  LD B,CROSSES_NEEDED     ; B = 12, also the size of the ring
  LD A,(Crosses)          ; crosses collected
  CP B
  RET C                   ; fewer than 12: nothing to show
  LD HL,CrossFlashTimer   ; colour step timer
  DEC (HL)
  RET NZ
  LD (HL),CROSS_FLASH_PERIOD
SmcCrossColour:
  LD A,$00                ; the colour position; this operand is stored by
                          ; ShowCrossRing_0
  INC A
  CP CROSS_COLOURS
  JR NZ,ShowCrossRing_0
  XOR A                   ; wrap to 0 after the 6th colour
ShowCrossRing_0:
  LD (SmcCrossColour+$0001),A ; keep the position for the next step
  LD HL,CrossColours      ; CrossColours
  CALL AddAToHL           ; HL = colour table + position
  LD A,(HL)
  LD (TileAttrs+TILE_RING_CROSS),A ; attribute of the ring cross tile
  LD A,(ChaliceTaken)
  OR A
  RET NZ                  ; chalice taken: the ring is no longer restamped
  LD HL,CrossRingCount    ; crosses of the ring shown so far
  LD A,(HL)
  CP B
  JR Z,ShowCrossRing_Stamp ; all 12 shown: just restamp them (B = 12)
  INC (HL)                ; one more cross
  LD A,(HL)
  CP B
  JR NZ,ShowCrossRing_1
  LD (CrossRingDone),A    ; the twelfth: CrossRingDone = 12
ShowCrossRing_1:
  LD B,A                  ; B = number of crosses to stamp
  LD A,SFX_PICKUP
  LD (SoundRequest),A     ; sound effect 5
ShowCrossRing_Stamp:
  LD HL,CrossRingPositions ; list of positions
ShowCrossRing_2:
  LD E,(HL)               ; E = row
  INC HL
  LD D,(HL)               ; D = column
  INC HL
  PUSH BC
  PUSH HL
  EX DE,HL                ; H = column, L = row
  LD E,TILE_RING_CROSS
  CALL PlaceTile          ; PlaceTile
  POP HL
  POP BC
  DJNZ ShowCrossRing_2
  RET
