; Index of the first item in the item table
;
; The item table (ItemRoomTable and ItemPositionTable) holds one entry per
; index; entries before this index are zeros and are never used. This byte
; ($AD) is the index of the first real item, so the table has 256 - $AD = 83
; items. It is read when a game starts (NewGame sets the present flag of every
; item from here to index $FF and copies this value to ItemCounter) and at
; every pass by UpdateItems as the start of its loop. Nothing writes it while
; the game runs.
FirstItemIndex:
  DEFB $AD

; Item table, first half: room, flags and screen half of each item
;
; One byte per item, indexed by L from FirstItemIndex ($AD) to $FF (83 items;
; the first $AD bytes are unused zeros). The matching entry of the second half
; is ItemPositionTable + the same index. Item entry format:
;
; bits 0-5 of the first byte (this table): room number (0-63); bit 6: the item
; is still there. Clear in the file; NewGame sets it for every item when a game
; starts and UpdateItems clears it when Willy collects the item; bit 7: the
; item is in the bottom half of the room (character rows 8-15), clear for the
; top half (rows 0-7); second byte (ItemPositionTable + index): character cell
; inside that half: bits 0-4 = column (0-31, x = column * 8), bits 5-7 = row
; within the half (0-7). The character row of the room (0-15) is therefore
; (second byte >> 5) + 8 * bit 7 of the first byte, and the second byte is also
; the low byte of the cell's address in the attribute buffer page $5C00/$5D00
; (bit 7 chooses the page) and in the screen buffer page $60/$68 (the 8 pixel
; rows are 256 bytes apart).
;
; The graphic and colour of every item are the same in a room: the 8 bytes of
; the room's item graphic (room byte $E1-$E8).
;
; Decoded from re/image.z80 (a short script reading the image): 83 items in 38
; rooms. Items per room: room $00: 12, $02: 1, $03: 3, $07: 1, $09: 1, $0A: 1,
; $0C: 3, $0D: 2, $0E: 2, $0F: 1, $10: 1, $11: 1, $12: 1, $13: 1, $15: 7, $16:
; 2, $19: 4, $1B: 1, $1C: 1, $1D: 1, $1E: 1, $1F: 1, $21: 1, $22: 1, $25: 3,
; $26: 1, $28: 1, $2B: 4, $2C: 1, $2E: 2, $31: 6, $32: 4, $33: 1, $38: 4, $39:
; 1, $3A: 2, $3B: 1, $3C: 1. The two items of room $3A (indexes $C0 and $C6)
; are on the same cell, so only 82 different cells are used; both are collected
; together.
;
; The only code that touches the item tables is NewGame (sets bit 6) and
; UpdateItems (reads, clears bit 6): static search for loads of the pages
; $A4/$A5.
ItemRoomTable:
  DEFS $AD
  DEFB $B2,$B2,$B2,$B2,$B8,$B8,$B8,$B8,$AB,$AB,$AB,$AB,$9F,$92,$0F,$10
  DEFB $11,$BC,$BB,$BA,$25,$25,$A5,$1B,$B9,$BA,$1C,$A2,$19,$19,$99,$99
  DEFB $B3,$16,$96,$28,$8C,$0C,$0C,$89,$07,$2E,$2E,$26,$95,$95,$95,$95
  DEFB $95,$0E,$0A,$95,$95,$0E,$0D,$0D,$2C,$13,$83,$83,$83,$31,$31,$31
  DEFB $B1,$B1,$B1,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02
  DEFB $9D,$9E,$A1

; Item table, second half: cell position of each item
;
; Byte for each item index (see ItemRoomTable, whose entry has the full
; format): bits 0-4 column (0-31), bits 5-7 row inside the half of the room
; chosen by bit 7 of ItemRoomTable + index. Also the low byte of the item's
; address in the attribute buffer (page $5C or $5D) and in the screen buffer
; (page $60 or $68). The first $AD bytes are unused zeros (items start at
; FirstItemIndex). Never written while the game runs.
ItemPositionTable:
  DEFS $AD
  DEFB $19,$2A,$34,$38,$C9,$B3,$7B,$46,$1F,$19,$1C,$16,$64,$99,$9F,$9F
  DEFB $9F,$1A,$CD,$B6,$3C,$D0,$A6,$DD,$37,$B6,$7A,$22,$43,$A8,$06,$66
  DEFB $C7,$C9,$22,$F3,$B3,$70,$96,$65,$EF,$6A,$9D,$49,$91,$92,$94,$96
  DEFB $97,$5A,$8B,$99,$9B,$7A,$C2,$25,$92,$62,$61,$44,$67,$9C,$E4,$FC
  DEFB $42,$5C,$A4,$93,$94,$95,$96,$97,$98,$99,$9A,$9B,$9C,$9D,$9E,$16
  DEFB $3A,$C8,$B7
