# Classification $BE56-$FEFF (subagent D)

| Range | What | Status |
| --- | --- | --- |
| $BE56-$BE57 | pointer to the current entry of the object list at $5DC0 | vars |
| $BE58-$BE59 | pointer to the next free word of the frame call list | vars |
| $BE5A-$BEFB | frame call list: routine addresses run by RET with SP=$BE5A, ended by $BDEB | buffer |
| $BEFC-$BFFF | $FF fill | unused |
| $C000-$C0FF | sprite draw queue, 16 x 16 bytes | buffer |
| $C100-$C1F3 | object slots, 11 x 22 bytes, end mark $A5FC at $C1F2 | buffer |
| $C1F4-$C1FF | $FF fill | unused |
| $C200-$C2FF | redraw run list (built by $97B7) | buffer |
| $C300-$C3FF | redraw cells: run length | buffer |
| $C400-$C4FF | redraw cells: attribute | buffer |
| $C500-$CCFF | redraw cells: 8 pixel rows, a page per row; also the bit-mirror table and a screen copy | buffer |
| $CD00-$CDFF | tile flags | table |
| $CE00-$CEFF | tile attributes | table |
| $CF00-$D6FF | tile bitmaps, 256 x 8 | gfx |
| $D700-$EEFF | sprite sheet rows 0-23: columns $00-$62 fixed, $63-$FF filled per room | gfx + buffer |
| $EF00-$FEFF | sprite sheet rows 24-39, same split | gfx + buffer |
| $FF00-$FFFF | outline mask table built by $6034 (outside the image) | buffer |

- Rooms are bytecode scripts at $726A+, word table at $7236 (index room*2),
  run by the interpreter $9D5F; tiles placed by $9E6A; glyphs from $6130 via $9E79.
- Tile T: $9E6A puts T in the tile map ($5Bxx) and $CD00+T in the flag map
  three pages up ($5Exx); $976B redraws from $CE00+T (attribute) and
  $CF00+8T (bitmap). Status bar: tile $7B heart ($D2D8), $7C cross ($D2E0).
- Tile flags: bit 7 redraw mark ($97CB AND $C0, reset at $9719); bits 0-2
  class: $83 walls/floors; $84 tiles 05, 3B-3C, 4E-74; $81 tiles 10, 26, 87;
  $80 the rest (all from $88). $BAB1: AND 7 = 0 free, bit 2 -> $B08E.
- Sprite sheet: a 256-byte page per pixel row, a sprite is a run of columns
  read down with INC D (drawers $99F2-$9B3E, 1-5 bytes wide). Rows 0-23:
  24-pixel sprites; rows 24-39: 16-pixel. No masks stored: $FF00 holds
  NOT(b OR b<<1 OR b>>1), an outline of one pixel. Monk frames ($ACA7):
  11 columns each = 4 copies shifted by 2 pixels (2+3+3+3 bytes); frames 6-8
  ($42-$62) flames in three sizes; crouching monk rows 24-39, 4 frames of 12
  columns ($ACC9). Columns $30-$62 of rows 24-39: small object and enemy
  sprites (object table $93D3 points to $EF30-$EF55, $F357, $F759).
- Room sprites: $AF15 reads the 6-byte records at $AE9D; $AF58 unpacks
  (a bit-flag byte per 8 bytes, 0 bits give zeros), $AF7B shifted copies
  (flag bit 7), $AFC9/$B006 mirrored copies (flag bit 6) through the
  bit-reverse table $BE48 builds at $C500.
- $86D0 clears $C000-$C0FF; $86D7 zeroes the slots at $C100 and writes
  $A5FC at $C1F2; $97E1 calls each record's handler at $C000 and zeroes it;
  $98B1 appends a record copied from $98D9; $A450 copies $4800-$4FFF to
  $C500 (patched NOP: restore); $BDDB sets SP=$BE5A and RETs into the call
  list, $A5DB adds $BDEB as the last entry; $8908 and $A5BE set the pointers.
- The interrupt handler writes into $BE5A+ and the tile bitmaps while SP
  points there and puts the bytes back (EX (SP),HL / PUSH BC).
- Open: tile classes 1 and 4; flame frames 6-8 (death?); which object each
  small sprite is; sizes of the call list and redraw buffers; the $FF fills.
