g $BE56 Pointer to the current entry of the object list at $5DC0
W $BE56,2
g $BE58 Pointer to the next free word of the frame call list at $BE5A
W $BE58,2
g $BE5A Frame call list: routine addresses run by RET with SP=$BE5A, ended by $BDEB
S $BE5A,162
u $BEFC Unused, $FF fill
S $BEFC,260,260:$FF
g $C000 Sprite draw queue: 16 records of 16 bytes, word 0 the routine
S $C000,256,256:$FF
g $C100 Object slots: 11 records of 22 bytes, word 0 the handler (0 free), end mark $A5FC at $C1F2
S $C100,244,244:$FF
u $C1F4 Unused, $FF fill
S $C1F4,12,12:$FF
g $C200 Redraw run list built by $97B7: runs of dirty cells, $FF after each screen row
S $C200,256,256:$FF
g $C300 Redraw cells: run length of each queued cell
S $C300,256,256:$FF
g $C400 Redraw cells: attribute of each queued cell
S $C400,256,256:$FF
g $C500 Redraw cells: 8 pixel rows of each queued cell, one page per row; also the bit-mirror table and a screen copy
S $C500,2048,2048:$FF
b $CD00 Tile flags, one per tile: bit 7 redraw, bits 0-2 the tile class
@ $CD00 label=TileFlags
B $CD00,256,16
b $CE00 Tile attributes, one per tile
@ $CE00 label=TileAttrs
B $CE00,256,16
b $CF00 Tile bitmaps, 256 tiles of 8 bytes
@ $CF00 label=TileGfx
B $CF00,2048,8
b $D700 Sprite sheet, rows 0-23: 256-byte pages, one per pixel row; columns $00-$62 the monk, 9 frames of 11 columns (4 copies shifted 2 pixels apart, 2+3+3+3 bytes; frames 6-8 flames), $63-$FF room sprites built at run time
@ $D700 label=SpriteSheet
B $D700,99,11
S $D763,157
B $D800,99,11
S $D863,157
B $D900,99,11
S $D963,157
B $DA00,99,11
S $DA63,157
B $DB00,99,11
S $DB63,157
B $DC00,99,11
S $DC63,157
B $DD00,99,11
S $DD63,157
B $DE00,99,11
S $DE63,157
B $DF00,99,11
S $DF63,157
B $E000,99,11
S $E063,157
B $E100,99,11
S $E163,157
B $E200,99,11
S $E263,157
B $E300,99,11
S $E363,157
B $E400,99,11
S $E463,157
B $E500,99,11
S $E563,157
B $E600,99,11
S $E663,157
B $E700,99,11
S $E763,157
B $E800,99,11
S $E863,157
B $E900,99,11
S $E963,157
B $EA00,99,11
S $EA63,157
B $EB00,99,11
S $EB63,157
B $EC00,99,11
S $EC63,157
B $ED00,99,11
S $ED63,157
B $EE00,99,11
S $EE63,157
b $EF00 Sprite sheet, rows 24-39: columns $00-$2F the crouching monk, 4 frames of 12 columns (4 shifts of 3), $30-$62 small object sprites, $63-$FF room sprites built at run time
B $EF00,48,12
B $EF30,51,17
S $EF63,157
B $F000,48,12
B $F030,51,17
S $F063,157
B $F100,48,12
B $F130,51,17
S $F163,157
B $F200,48,12
B $F230,51,17
S $F263,157
B $F300,48,12
B $F330,51,17
S $F363,157
B $F400,48,12
B $F430,51,17
S $F463,157
B $F500,48,12
B $F530,51,17
S $F563,157
B $F600,48,12
B $F630,51,17
S $F663,157
B $F700,48,12
B $F730,51,17
S $F763,157
B $F800,48,12
B $F830,51,17
S $F863,157
B $F900,48,12
B $F930,51,17
S $F963,157
B $FA00,48,12
B $FA30,51,17
S $FA63,157
B $FB00,48,12
B $FB30,51,17
S $FB63,157
B $FC00,48,12
B $FC30,51,17
S $FC63,157
B $FD00,48,12
B $FD30,51,17
S $FD63,157
B $FE00,48,12
B $FE30,51,17
S $FE63,157
i $FF00
