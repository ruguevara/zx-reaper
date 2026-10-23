; Draw the items of the current room and collect the one Willy touches
;
; Walks the whole item table (ItemRoomTable and ItemPositionTable) from the
; entry at FirstItemIndex to the end (L wraps to 0) and handles every item
; whose room number is the current room (CurrentRoom) and whose "present" flag
; (bit 6 of the first byte) is still set. For each such item:
;
; The item cell is looked up in the attribute buffer at $5C00 (bit 7 of the
; first byte selects the page $5C00 or $5D00, the second byte is the low byte
; of the address). If its ink is 7 (white) the item is collected. Willy is the
; sprite that is drawn with ink 7 (MarkWillyCell writes his attribute before
; this routine runs), so this is the pick-up test: any other attribute with ink
; 7 on that cell would collect the item too. Not checked: guardian attributes
; with ink 7 (TODO). Two items on the same cell are collected in the same pass,
; because the attribute does not change when the first is collected (observed,
; F18).
;
; Collecting: the three ASCII digits at ItemsCollectedText are incremented with
; decimal carry, a falling beep is played (border colour of the room, speaker
; and MIC toggled), ItemCounter is incremented (when it wraps to 0 all items
; are collected and EndingStage is set to 1) and the present flag (bit 6) is
; cleared.
;
; Drawing (item not touched): the ink of the cell is set to 3 + ((PassCounter +
; table index) AND 3), so the items flash through magenta, green, cyan and
; yellow, keeping the paper, bright and flash bits; the 8 bytes of the room's
; item graphic ($80E1) are copied into the screen buffer at $6000 (or $6800 for
; items in the bottom half of the room), one byte per pixel row, at the column
; and character row taken from the second byte.
;
; Hardware: writes the speaker/MIC/border bits of port $FE (busy-wait beep) on
; a pick-up; the pixels go to the screen buffer, not to the screen.
UpdateItems:
  LD H,ItemRoomTable>>8
  LD A,(FirstItemIndex)
  LD L,A
UpdateItems_Loop:
  LD C,(HL)               ; C = room number with bits 6 and 7 as flags; bit 7
                          ; dropped
  RES 7,C
  LD A,(CurrentRoom)
  OR ITEM_PRESENT         ; compare with (current room | present flag)
  CP C
  JR NZ,UpdateItems_Next  ; another room, or already collected
  LD A,(HL)               ; bit 7 (bottom half) becomes bit 0 of the attribute
                          ; page
  RLCA
  AND $01
  ADD A,SCREEN_ATTRS_BUF>>8
  LD D,A                  ; D = $5C or $5D
  INC H
  LD E,(HL)               ; E = low byte of the cell address (second table)
  DEC H
  LD A,(DE)
  AND INK_MASK
  CP WHITE                ; ink 7 = Willy is on the cell
  JR NZ,UpdateItems_Draw  ; not touched: draw the item
  LD IX,ItemsCollectedText ; collected: add 1 to the three-digit counter
UpdateItems_Carry:
  INC (IX+ITEM_DIGITS-$01)
  LD A,(IX+ITEM_DIGITS-$01)
  CP ASCII_AFTER_NINE
  JR NZ,UpdateItems_Sound
  LD (IX+ITEM_DIGITS-$01),ASCII_ZERO ; digit overflow: back to 0, carry to the
                                     ; next digit
  DEC IX
  JR UpdateItems_Carry
UpdateItems_Sound:
  LD A,(RoomBorder)       ; beep: border colour, then alternating with the
                          ; beeper bits
  LD C,ITEM_BEEP_START    ; C = $80, $7E, ... 2: 64 half-periods; delay B = $90
                          ; - C grows,
UpdateItems_Beep:
  OUT (ULA_PORT),A        ; so the pitch falls
  XOR BEEPER_BITS
  LD E,A
  LD A,ITEM_BEEP_DELAY
  SUB C
  LD B,A
  LD A,E
UpdateItems_0:
  DJNZ UpdateItems_0
  DEC C
  DEC C
  JR NZ,UpdateItems_Beep
  LD A,(ItemCounter)
  INC A
  LD (ItemCounter),A
  JR NZ,UpdateItems_Remove
  LD A,$01                ; counter wrapped to 0: every item collected, state 1
  LD (EndingStage),A
UpdateItems_Remove:
  RES 6,(HL)              ; clear the present flag
  JR UpdateItems_Next
UpdateItems_Draw:
  LD A,(PassCounter)      ; ink = 3 + ((pass counter + table index) AND 3)
  ADD A,L
  AND ITEM_COLOURS-$01
  ADD A,MAGENTA
  LD C,A
  LD A,(DE)
  AND ~INK_MASK
  OR C
  LD (DE),A
  LD A,(HL)               ; bit 7 (bottom half) becomes bit 3: D = $60 or $68
  RLCA
  RLCA
  RLCA
  RLCA
  AND THIRD_PAGES
  ADD A,SCREEN_PIXEL_BUF>>8
  LD D,A
  PUSH HL
  LD HL,RoomItemGfx
  LD B,CELL_HEIGHT
  CALL DrawGlyph8
  POP HL
UpdateItems_Next:
  INC L
  JR NZ,UpdateItems_Loop
  RET
