; Draw Willy into the $6000 screen buffer
;
; Picks Willy's 16x16 sprite from the 8-frame sprite page $9D00 (32 bytes per
; frame) and ORs it into the buffer through the row address table
; RowAddressTable. Inputs are game variables, not registers:
;
; $85CF Willy's vertical position: index into the row address table (2 per
; pixel row; $D0 = pixel row 104) $85D0 bit 0: facing; selects the sprite half
; (frames 0-3 or 4-7) $85D2 bits 0-1: animation frame within that half $85D3
; low 5 bits: screen column of the left byte (the word is also the address of
; Willy's top-left cell in the attribute buffer)
;
; In room $1D (compared with $8420) the sprite page is $B600 instead, with the
; facing half swapped: Willy is drawn as something else there (a different
; creature in the pictures at $B600; not further identified).
;
; Unlike DrawSprite there is no collision test; the bits are ORed in.
;
; Hardware: writes the $6000 bitmap buffer.
;
; B Extra vertical offset, in table index units (2 per pixel row); 0 unless
; Willy is standing on a ramp (see PlaceWilly)
DrawWilly:
  LD A,(WillyY)
  ADD A,B
  LD IXH,RowAddressTable>>8
  LD IXL,A
  LD A,(WillyMoveState)
  AND $01
  RRCA                    ; facing -> bit 7
  LD E,A
  LD A,(WillyFrame)
  AND ANIM_FRAME_MASK
  RRCA
  RRCA
  RRCA                    ; frame * 32
  OR E
  LD E,A
  LD D,WILLY_SPRITE_PAGE
  LD A,(CurrentRoom)
  CP ROOM_NIGHTMARE
  JR NZ,DrawWilly_0
  LD D,SpritesFlapper>>8
  LD A,E
  XOR WILLY_FACING_HALF
  LD E,A
DrawWilly_0:
  LD B,SPRITE_HEIGHT
  LD A,(WillyAttrAddr)
  AND COLUMN_MASK
  LD C,A
; Alternative entry: OR a 16x16 sprite into the $6000 buffer through a row
; address table. IX Address of the table entry of the first pixel row
; (RowAddressTable + index) DE Sprite graphic address C Screen column of the
; left byte (0-31) B Number of pixel rows (16) This entry point is used by the
; routine at DrawToilet.
DrawSpriteRows:
  LD A,(IX+$00)
  LD H,(IX+$01)
  OR C
  LD L,A
  LD A,(DE)
  OR (HL)
  LD (HL),A
  INC HL
  INC DE
  LD A,(DE)
  OR (HL)
  LD (HL),A
  INC IX
  INC IX
  INC DE
  DJNZ DrawSpriteRows
  RET

; Print a text string with the ROM font
;
; Prints C characters from the message at IX, one character cell per character,
; left to right, using PrintChar for each. Character codes are ASCII (bit 7
; ignored). Used for titles, the scrolling message and the status line.
;
; Hardware: writes the screen bitmap.
;
;   IX Address of the message
;   DE Screen address of the first character cell (pixel row 0 of the cell)
;   C Number of characters
; O:IX Address after the message
; O:DE Screen address after the last character cell
PrintText:
  LD A,(IX+$00)
  CALL PrintChar
  INC IX
  INC E                   ; next column
  LD A,D
  SUB CELL_HEIGHT         ; undo the 8 INC D of PrintChar
  LD D,A
  DEC C
  JR NZ,PrintText
  RET

; Draw one character from the ROM font
;
; Looks up the 8-byte glyph of character A in the ROM character set and copies
; it to the screen with DrawGlyph8. The glyph address is $3C00+8*A, so
; printable ASCII (32-127) finds its ROM glyph at $3D00 upwards; bit 7 of A is
; ignored.
;
; Hardware: reads the ROM character set, writes the screen bitmap.
;
;   A Character code (ASCII)
;   DE Screen address of pixel row 0 of the character cell
; O:DE Screen address of pixel row 0 of the cell 8 pixel rows lower (D advanced
;      by 8)
PrintChar:
  LD H,ROM_FONT_CODE0/CELL_HEIGHT>>8
  LD L,A
  SET 7,L                 ; HL = $0780+A (A < 128)
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD B,CELL_HEIGHT
; Alternative entry: copy 8 bytes from HL to the 8 pixel rows of one character
; cell at DE (D advances by 1 per byte, so D ends 8 higher). B must be 8. Used
; for the title graphic pieces and the item graphic as well as glyphs. This
; entry point is used by the routines at NewGame and UpdateItems. HL Address of
; 8 bytes of pixel data DE Screen address of pixel row 0 of the cell B Number
; of pixel rows (8)
DrawGlyph8:
  LD A,(HL)
  LD (DE),A
  INC HL
  INC D
  DJNZ DrawGlyph8
  RET

; Play a tune on the beeper until its end marker or a key press
;
; The tune is a list of one-byte notes ended by $FF. Each note byte is a
; half-period count: a square wave with the speaker/MIC bits toggled every E
; passes of the inner loop, for 100 passes of 256 inner iterations (fixed note
; length, so a tune has no rests and no length codes). Halfway through the note
; (when the outer count is $32) E is doubled, so the second half of each note
; is an octave lower (inferred from the code; not listened to).
;
; After each note ReadStartInput is called; the tune stops if it reports a
; press.
;
; Hardware: writes port $FE (speaker and MIC bits, border black); timing loops.
;
;   HL Address of the tune
; O:HL Address of the $FF terminator, or of the note after which the tune was
;      stopped
; O:F Z if the tune ended, NZ if stopped by ReadStartInput
PlayTune:
  LD A,(HL)
  CP TUNE_END
  RET Z
  LD BC,TUNE_PASSES
  XOR A
  LD E,(HL)
  LD D,E
PlayTune_Pass:
  OUT (ULA_PORT),A
  DEC D
  JR NZ,PlayTune_0
  LD D,E
  XOR BEEPER_BITS         ; toggle speaker and MIC
PlayTune_0:
  DJNZ PlayTune_Pass
  EX AF,AF'
  LD A,C
  CP TUNE_PASSES/$02
  JR NZ,PlayTune_1
  RL E                    ; halfway through the note: double the half-period
PlayTune_1:
  EX AF,AF'
  DEC C
  JR NZ,PlayTune_Pass
  CALL ReadStartInput
  RET NZ
  INC HL
  JR PlayTune

; Test for the start action: joystick fire, key 0 or ENTER
;
; If the Kempston joystick was detected (flag at $85CE, set by NewGame), reads
; the joystick port and returns NZ when fire is pressed. Otherwise, or when
; fire is not pressed, reads keyboard port $AFFE, which selects the half-rows
; 0-6 and H-ENTER together: bit 0 is key 0 or ENTER. Used to stop the title
; tune (PlayTune); ScrollTitleMessage tests the same keys itself.
;
; Hardware: reads port $1F (Kempston joystick) and port $AFFE (keyboard).
;
; O:F NZ if fire, key 0 or ENTER is pressed; Z if not
; O:A Corrupted
ReadStartInput:
  LD A,(JoystickFlag)
  OR A
  JR Z,ReadStartInput_Keys
  IN A,(KEMPSTON_PORT)
  BIT KEMPSTON_FIRE_BIT,A
  RET NZ
ReadStartInput_Keys:
  LD BC,KEYROW_START
  IN A,(C)
  AND $01
  CP $01
  RET

; Play a sweeping pulse sound
;
; Makes E = A passes. In each pass, N (A counting down from its start value to
; 1) selects one of E port writes (the one where B = N): that write has the
; speaker and MIC bits set, all the others have them clear. The single pulse
; therefore moves one step along the pass each time, which makes a sweeping
; chirp. The other bits written are those of N, so the border colour (bits 0-2)
; also changes from pass to pass.
;
; ScrollTitleMessage calls this after each step of the message that scrolls
; along the bottom of the title screen, with A = (message offset AND $1F) +
; $32, so the sound depends on the position in the message. Observed: with no
; key pressed after the code entry, the title tune ends at about frame 1583 and
; the first call follows with A = $32. Not executed in the coverage maps in
; re/maps.
;
; Hardware: writes port $FE (border, speaker, MIC); timing loops.
;
;   A Start value of N (about 50 to 81 as called)
; O:A 0
PlaySweepSound:
  LD E,A
  LD C,ULA_PORT
PlaySweepSound_Pass:
  LD D,A
  RES 4,D
  RES 3,D
  LD B,E
PlaySweepSound_Step:
  CP B
  JR NZ,PlaySweepSound_0
  LD D,BEEPER_BITS
PlaySweepSound_0:
  OUT (C),D
  DJNZ PlaySweepSound_Step
  DEC A
  JR NZ,PlaySweepSound_Pass
  RET

; Unused test code: show the room's attribute map, X resets
;
; Never executed and unreachable: it follows the RET of PlaySweepSound, nothing
; jumps or calls to $96F4 and no word in the image holds that address. Not part
; of the game; it looks like a debugging aid. What it would do (run in the
; simulator from the in-game snapshot): copies the empty-room attribute master
; copy ($5E00-$5FFF, 512 bytes) over the top two thirds of the attributes,
; fills the bitmap of the top two thirds ($4000-$4FFF) with $18 (a thin
; vertical bar in every cell), so the room's colour layout is shown without
; sprites or graphics. It then polls the keyboard half row CS-V (port $FEFE)
; forever; the X key (bit 2) jumps to $0000, which resets the machine.
; Observed: with X pressed the run reaches PC=$0000 after a frame or two,
; without X it stays in the polling loop.
;
; Hardware: writes screen bitmap and attributes; reads keyboard port $FEFE.
ShowAttrMap:
  LD HL,ROOM_ATTR_BUF
  LD DE,ATTRS
  LD BC,ROOM_ATTRS_SIZE
  LDIR
  LD HL,SCREEN
  LD DE,SCREEN+$0001
  LD BC,ROOM_BITMAP_SIZE-$0001
  LD (HL),$18
  LDIR
  LD BC,KEYROW_CS_V
ShowAttrMap_0:
  IN A,(C)
  BIT 2,A
  JP Z,$0000
  JR ShowAttrMap_0
