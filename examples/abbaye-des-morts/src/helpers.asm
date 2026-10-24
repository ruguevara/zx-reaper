; Wait until a key is pressed
;
; Enables interrupts and halts until the next frame interrupt, then reads all
; eight keyboard half-rows at once (port $FE with a zero high byte) and repeats
; until one of the five key bits shows a pressed key. Called by the main loop
; (StartGame), the ending (RunEnding) and ShowParchment.
;
; Hardware: HALT for the frame interrupt; reads the ULA keyboard port $FE.
WaitKeyPress:
  EI
  HALT
  XOR A                   ; A = 0 selects every half-row
  IN A,(ULA_PORT)
  CPL
  AND KEY_BITS            ; bits set = keys down
  JR Z,WaitKeyPress
  RET

; Wait until all keys are released
;
; Enables interrupts and halts until the next frame interrupt, then reads all
; eight keyboard half-rows at once and repeats until no key is pressed. Called
; together with WaitKeyPress by StartGame and ShowParchment, and jumped to by
; the ending RunEnding.
;
; Hardware: HALT for the frame interrupt; reads the ULA keyboard port $FE.
WaitKeyRelease:
  EI
  HALT
  XOR A                   ; A = 0 selects every half-row
  IN A,(ULA_PORT)
  CPL
  AND KEY_BITS
  JR NZ,WaitKeyRelease
  RET

; Add A to HL
;
; Unsigned 8-bit addition to a 16-bit register, used for row steps and table
; offsets.
;
;   A Value to add
;   HL Base
; O:HL HL + A
; O:A Low byte of the result
AddAToHL:
  ADD A,L
  LD L,A
  RET NC
  INC H
  RET

; Bitmap address of a cell from its pixel row and byte column
;
; Converts a position given as a pixel row L and a byte column H into the
; address of that byte in the screen bitmap. Only correct when L is a multiple
; of 8, the top pixel line of a character cell: the low three bits of L would
; reach the high byte twice (observed: L = 1 gives $6100 instead of $4100).
; Used by FillBitmapRect only, whose operands are cell-aligned.
;
; Hardware: knows the layout of the screen bitmap at $4000-$57FF.
;
;   L Pixel row, a multiple of 8
;   H Byte column 0-31
; O:HL Bitmap address
BitmapAddress:
  LD A,L
  ADD A,A
  ADD A,A
  AND $E0
  ADD A,H
  LD H,A
  LD A,L
  RRCA
  RRCA
  RRCA
  XOR L
  AND $F8
  XOR L
  OR SCREEN_HIGH
  LD L,H
  LD H,A
  RET

; Attribute address of a cell
;
; Converts a cell row and column into the address of the cell's attribute byte:
; $5800 + 32 x row + column. Used by FillAttrRect, OpSetupWater and two
; routines at RedrawCell and DrawFrameRow.
;
; Hardware: knows the address of the attribute file.
;
;   L Cell row 0-23
;   H Cell column 0-31
; O:HL Attribute address
AttrAddress:
  LD A,L
  RRCA
  RRCA
  RRCA
  LD L,A
  AND $E0
  ADD A,H
  LD H,A
  LD A,L
  AND $03
  ADD A,ATTRS_HIGH
  LD L,H
  LD H,A
  RET

; Bitmap address of the first pixel line of an attribute cell
;
; Converts an attribute address into the screen bitmap address of the top pixel
; line of the same cell: only the high byte changes, from $58-$5A to $40, $48
; or $50.
;
; Hardware: knows the layout of the screen bitmap and the attribute file.
;
;   HL Attribute address
; O:HL Bitmap address of the top line of the cell
AttrToBitmap:
  LD A,H
  AND $03
  ADD A,A
  ADD A,A
  ADD A,A
  OR SCREEN_HIGH
  LD H,A
  RET

; Tile map address of a cell
;
; $5B00 + 32 x row + column: the address in the tile map (22 rows of 32 tile
; numbers) of the cell at row L, column H. The flag map is 3 pages above
; (FlagMapAddress). Used by PlaceTile, SetTileFlag and RedrawCell.
;
;   L Row 0-21
;   H Column 0-31
; O:HL Tile map address
TileMapAddress:
  LD A,L
  RRCA
  RRCA
  RRCA
  LD L,A
  AND $E0
  ADD A,H
  LD H,L
  LD L,A
  LD A,H
  AND $03
  ADD A,TILEMAP_HIGH
  LD H,A
  RET

; Tile flag map address of a cell
;
; $5E00 + 32 x row + column: the address in the tile flag map of the cell at
; row L, column H. Used by the sprite drawers QueueBlockSprite and QueueSprite
; to read the flags under a sprite.
;
;   L Row 0-21
;   H Column 0-31
; O:HL Flag map address
FlagMapAddress:
  LD A,L
  RRCA
  RRCA
  RRCA
  LD L,A
  AND $E0
  ADD A,H
  LD H,L
  LD L,A
  LD A,H
  AND $03
  ADD A,FLAGMAP_HIGH
  LD H,A
  RET

; Unused copy of $A21E
;
; Identical to FlagMapAddress; called only by the unused UnusedFillFlags.
;
;   L Row 0-21
;   H Column 0-31
; O:HL Flag map address
UnusedFlagMapAddress:
  LD A,L
  RRCA
  RRCA
  RRCA
  LD L,A
  AND $E0
  ADD A,H
  LD H,L
  LD L,A
  LD A,H
  AND $03
  ADD A,FLAGMAP_HIGH
  LD H,A
  RET

; Read the keyboard into the half-row buffer
;
; Reads the eight keyboard half-rows into the eight bytes at KeyRows: row 0
; from port $FEFE (CAPS SHIFT, Z, X, C, V), then $FDFE (A-G), $FBFE (Q-T),
; $F7FE (1-5), $EFFE (0-6), $DFFE (P-Y), $BFFE (ENTER-H) and $7FFE (SPACE-B);
; bits 0-4 are the keys, a 0 bit is a key down. Each INI reads the port
; addressed by BC (B = the half-row selector, rotated left between reads) and
; stores it at HL. Then it reads every half-row together and stores the five
; key bits, inverted so that 1 is a key down, in ControlsRead; the control
; reader ReadKeyControls overwrites that byte with the control bits. Used by
; GameFrame (every frame) and MenuFrame (the key redefinition).
;
; Hardware: reads the ULA keyboard port $FE.
;
; O:F Carry and not zero when any key is down, zero when none (no caller tests
;     it)
ScanKeyboard:
  LD A,KB_CS_V            ; port high byte of the first half-row
  LD C,A                  ; C = $FE, the ULA port
  LD HL,KeyRows           ; row buffer
  LD B,A
  INI
  RLCA                    ; next half-row: $FD, $FB, $F7, $EF, $DF, $BF, $7F
  LD B,A
  INI
  RLCA
  LD B,A
  INI
  RLCA
  LD B,A
  INI
  RLCA
  LD B,A
  INI
  RLCA
  LD B,A
  INI
  RLCA
  LD B,A
  INI
  RLCA
  LD B,A
  INI
  XOR A                   ; A = 0: every half-row at once
  IN A,(ULA_PORT)
  CPL
  AND KEY_BITS
  LD (ControlsRead),A
  RET Z                   ; no key: carry is clear
  SCF                     ; some key down
  RET
