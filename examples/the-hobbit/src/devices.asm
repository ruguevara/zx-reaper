; Print a story line on the ZX printer
;
; Called by the story window routine OutputStoryChar when it ends a line
; (carriage return). When PrinterFlag is non-zero, sends the bottom text row of
; the story window (character row 17, 8 pixel lines of 32 bytes, from
; STORY_LAST_ROW) to the ZX printer, one dot line at a time, then stops the
; motor. Does nothing when PrinterFlag is zero. Stops at once when no printer
; answers (the port reads with bit 7 set). The dot loop is the ROM's COPY
; routine, including the stylus-speed bit for the first dot lines.
;
; Hardware: ZX printer port $FB (waits for the printer status bits, sends the
; dots); reads the screen bitmap. Registers HL, DE and BC are preserved.
;
; Reads PrinterFlag.
PrintStoryLine:
  LD A,(PrinterFlag)
  AND A
  RET Z                   ; printer off: nothing to do
  PUSH HL
  PUSH DE
  PUSH BC
  LD D,$01
  LD HL,STORY_LAST_ROW    ; HL: first byte of the story row, E: dot line 0-7
  XOR A
  LD E,A
PrintStoryLine_Dots:
  OUT (PORT_PRINTER),A
PrintStoryLine_0:
  IN A,(PORT_PRINTER)
  ADD A,A
  JP M,PrintStoryLine_5   ; bit 7: no printer, give up
  JR NC,PrintStoryLine_0  ; bit 6 clear: wait for the motor
  PUSH HL
  PUSH DE
  LD A,D
  CP $02
  SBC A,A
  AND E
  RLCA
  AND E
  LD D,A
PrintStoryLine_1:
  LD C,(HL)
  PUSH HL
  LD B,$08
PrintStoryLine_2:
  LD A,D
  RLC C
  RRA
  LD H,A
PrintStoryLine_3:
  IN A,(PORT_PRINTER)
  RRA
  JR NC,PrintStoryLine_3  ; wait until the stylus can take a dot
  LD A,H
  OUT (PORT_PRINTER),A
  DJNZ PrintStoryLine_2
  POP HL
  INC HL
  LD A,L
  AND $1F
  JR NZ,PrintStoryLine_1
PrintStoryLine_4:
  IN A,(PORT_PRINTER)
  RRA
  JR NC,PrintStoryLine_4
  LD A,D
  RRCA
  OUT (PORT_PRINTER),A
  POP DE
  POP HL
  INC H                   ; next pixel line of the row
  INC E
  BIT 3,E
  JR Z,PrintStoryLine_Dots ; 8 dot lines done?
  LD A,PRINTER_STOP_MOTOR
  OUT (PORT_PRINTER),A
PrintStoryLine_5:
  POP BC
  POP DE
  POP HL
  RET

; Short delay loop
;
; Counts BC down from 1000 to 0. The keyboard scanner calls it before each scan
; and uses the zero it leaves in BC to clear KeyFound.
;
; Hardware: timing loop, about 1000 iterations of 4 instructions.
;
; O:BC 0
DelayShort:
  LD BC,$03E8
DelayShort_0:
  DEC BC
  LD A,B
  OR C
  JR NZ,DelayShort_0
  RET

; Keyboard scanner ($8B93) tables and state
;
; $8B81: eight masks ORed to the eight half-rows read ($FEFE, $FDFE, ...,
; $7FFE; keys masked out: caps shift, 1 3 4, 9, symbol shift... mask bit =
; ignored key); constant. $8B89: key found (word BC at $8B89, byte A at $8B89).
; $8B8B: the eight half-rows of the previous scan (edge detection).
KeyMasks:
  DEFB $01,$00,$00,$0D,$02,$00,$00,$02
KeyFound:
  DEFB $00,$00
KeyPrevious:
  DEFS $08

; Scan the keyboard and return a newly pressed key
;
; The game's own keyboard scanner (the ROM's is never used). Reads the 8
; keyboard half-rows and compares each with the previous scan (KeyPrevious),
; after OR-ing the shift bits out through KeyMasks. A key that is down now and
; was up in the previous scan is the key found (the last such key in half-row
; order wins). Its index 5*half-row+column picks the ASCII code from KeyTable,
; or from ShiftKeyTable while CAPS SHIFT or SYMBOL SHIFT is held. Keys held
; down from before give nothing, so each press is returned once.
;
; Used by the idle wait WaitKey, which calls it in a loop.
;
; Hardware: keyboard port $FE (all 8 half-rows, then CAPS SHIFT and SYMBOL
; SHIFT again); starts with a delay loop. Registers other than A and the flags
; are preserved.
;
; O:A ASCII code of the newly pressed key, 0 when there is none O:F Z set when
; there is no key
ReadKey:
  PUSH HL
  PUSH IX
  PUSH BC
  CALL DelayShort         ; clears BC; BC := 0 for KeyFound
  LD (KeyFound),BC
  LD HL,KeyPrevious
  LD IX,KeyMasks
  LD BC,KB_ROW_CAPS_V*$0100+PORT_ULA ; B: half-row select, rotated each pass;
                                     ; C: port $FE
ReadKey_HalfRow:
  IN A,(C)
  AND KEY_BITS
  OR (IX+$00)             ; ignore the shift bits of the row
  PUSH AF                 ; keep this scan for KeyPrevious
  CPL                     ; new key bits = now down AND up before
  AND (HL)
  CPL
  JR Z,ReadKey_0          ; Z: no new key in this row
  LD (KeyFound),BC
  LD (KeyFound),A         ; low byte: key bits, 0 = the new key
ReadKey_0:
  POP AF
  LD (HL),A
  INC HL
  INC IX
  RLC B                   ; next half-row; carry out after the 8th
  JR C,ReadKey_HalfRow
  LD BC,(KeyFound)
  LD A,B
  OR C
  JR Z,ReadKey_5          ; nothing found: A = 0
  LD A,$100-KEYS_PER_ROW
ReadKey_1:
  ADD A,KEYS_PER_ROW      ; A = 5 * half-row index (B has a 0 bit at the row)
  RRC B
  JR C,ReadKey_1
  DEC A
ReadKey_2:
  INC A                   ; A + column index (C has a 0 bit at the key)
  RRC C
  JR C,ReadKey_2
  LD C,A
  LD B,$00
  LD HL,KeyTable          ; HL: KeyTable
  LD A,KB_ROW_CAPS_V
  IN A,(PORT_ULA)
  AND KEY_CAPS_SHIFT
  JR Z,ReadKey_3          ; CAPS SHIFT down: shifted table
  LD A,KB_ROW_SPACE_B
  IN A,(PORT_ULA)
  AND KEY_SYMBOL_SHIFT
  JR NZ,ReadKey_4         ; SYMBOL SHIFT up: plain table
ReadKey_3:
  LD HL,ShiftKeyTable     ; HL: ShiftKeyTable
ReadKey_4:
  ADD HL,BC
  LD A,(HL)               ; ASCII code
ReadKey_5:
  POP BC
  POP IX
  POP HL
  RET

; Key table: 40 keys without shift
;
; Index = 5 x half-row + key position (half-rows $FEFE, $FDFE, $FBFE, $F7FE,
; $EFFE, $DFFE, $BFFE, $7FFE, bit 0 first). Values: ASCII letters, $0D enter,
; $20 space, $08 = key 5 and 0 (left, delete), $09 = 8 (right), $0A = 6 (down),
; $5B = 7 (up), 0 = no character.
KeyTable:
  DEFB $00,$5A,$58,$43,$56
  DEFB $41,$53,$44,$46,$47
  DEFB $51,$57,$45,$52,$54
  DEFB $00,$00,$00,$00,$08
  DEFB $08,$00,$09,$5B,$0A
  DEFB $50,$4F,$49,$55,$59
  DEFB $0D,$4C,$4B,$4A,$48
  DEFB $20,$00,$4D,$4E,$42

; Key table: 40 keys with caps shift or symbol shift
;
; Same layout as $8BFB; selected when caps shift or symbol shift is held
; ($8BDE-$8BF1): punctuation, $40 "@", $22 quote, $2E ".", $2C ",", $18, $02
; for shift + space.
ShiftKeyTable:
  DEFB $00,$5A,$58,$43,$56
  DEFB $41,$53,$44,$46,$47
  DEFB $51,$57,$45,$52,$54
  DEFB $00,$40,$00,$00,$08
  DEFB $18,$00,$09,$5B,$0A
  DEFB $22,$4F,$49,$55,$59
  DEFB $0D,$4C,$4B,$4A,$48
  DEFB $02,$00,$2E,$2C,$42
