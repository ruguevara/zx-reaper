; Draw a 16x16 sprite, optionally testing for collision
;
; Draws a 16x16 sprite of 16 pixel rows, 2 bytes per row (left byte, right
; byte; 32 bytes, row-interleaved), at a byte-aligned position in a
; Spectrum-layout bitmap. The target is either the screen ($4000) or a buffer
; in the same layout (the $6000 buffer, see RowAddressTable).
;
; Mode 0 (C bit 0 clear): the sprite bytes replace the bitmap bytes.
;
; Mode 1 (C bit 0 set): collision test. Each sprite byte is ANDed with the
; bitmap byte under it; if the result is not zero the routine returns at once
; with NZ (rows drawn before that stay drawn); otherwise the byte is ORed in.
;
; The address steps down a pixel row with INC H and handles the character-row
; and one-third-of-the-bitmap boundaries.
;
; Callers: AskColourCode, DrawLives and ResumeAfterPause use mode 0 directly on
; the screen (C = 0). DrawEntities and UpdateBedroom use mode 1 on the $6000
; buffer, after Willy and the room are already drawn there, and send a
; collision to KillWilly (observed in the Bathroom: C = 1, DE = $B900, HL =
; $607B). Observed with a test call: mode 0 replaces bytes and returns Z with
; HL = $6040 after a sprite drawn at $6000; mode 1 over set pixels returns NZ
; with part of the sprite drawn.
;
; Hardware: writes the screen bitmap or a bitmap buffer in screen layout.
;
;   DE Sprite graphic address
;   HL Bitmap address of the top-left byte
;   C Bit 0: 0 = overwrite, 1 = draw with collision test
; O:A 0 when drawn completely (Z set); in mode 1, the overlapping bits when
;     stopped (NZ)
; O:HL Bitmap address of the pixel row below the sprite (when drawn completely)
DrawSprite:
  LD B,SPRITE_HEIGHT
DrawSprite_Row:
  BIT 0,C
  LD A,(DE)
  JR Z,DrawSprite_0
  AND (HL)
  RET NZ                  ; collision with the left byte
  LD A,(DE)
  OR (HL)
DrawSprite_0:
  LD (HL),A
  INC L
  INC DE
  BIT 0,C
  LD A,(DE)
  JR Z,DrawSprite_1
  AND (HL)
  RET NZ                  ; collision with the right byte
  LD A,(DE)
  OR (HL)
DrawSprite_1:
  LD (HL),A
  DEC L
  INC H                   ; next pixel row
  INC DE
  LD A,H
  AND CELL_HEIGHT-$01
  JR NZ,DrawSprite_2
  LD A,H                  ; crossed into the next character row
  SUB CELL_HEIGHT
  LD H,A
  LD A,L
  ADD A,SCREEN_COLS
  LD L,A
  AND ~COLUMN_MASK
  JR NZ,DrawSprite_2
  LD A,H                  ; crossed into the next third of the bitmap
  ADD A,THIRD_PAGES
  LD H,A
DrawSprite_2:
  DJNZ DrawSprite_Row
  XOR A                   ; Z set: no collision
  RET
