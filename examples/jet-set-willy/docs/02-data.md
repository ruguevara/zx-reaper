# 2. Data structures

The game keeps its state in a block of single-byte variables at $85CB-$85E4,
the current room in a 256-byte buffer at $8000, and the moving things of the
room in an 8 x 8-byte entity buffer at $8100. Everything static is in fixed
tables: 64 room pages at $C000, 128 entity definitions at $A000, the item
table at $A400 and 26 sprite pages at $A600. This section gives the layout of
each.

## Positions

Three kinds of coordinates are used throughout.

| Name | Meaning | Range |
| --- | --- | --- |
| Y index | twice the pixel row inside the playing area: an index into [RowAddressTable](../src/buffers.asm#L138), which holds 2 bytes per row. Y / 2 = pixel row, Y / 16 = character row | 0-&#36;FE (rows 0-127) |
| attribute address | address of a cell in the work attribute buffer, $5C00 + 32 * row + column. Low 5 bits = column, the rest = row; high byte $5C for rows 0-7, $5D for rows 8-15 | $5C00-$5DFF |
| column | 0-31, the byte column of the bitmap | |

Willy's position is a Y index ([WillyY](../src/variables.asm#L243)) plus an attribute address
([WillyAttrAddr](../src/variables.asm#L328)) whose row is always Y / 16 (F118). Guardians use a Y
index and a column; items use the attribute address directly.

## Game variables

All at $8420 and $85CB-$85E4 ([`src/variables.asm`](../src/variables.asm)).

| Address | Name | Meaning |
| --- | --- | --- |
| $8420 | [CurrentRoom](../src/variables.asm#L10) | room number 0-63; 33 at a new game |
| $85CB | [PassCounter](../src/variables.asm#L177) | passes of the frame loop modulo 256; the clock advances when it wraps; low bits drive item colours, the figure and the toilet |
| $85CC | [LivesLeft](../src/variables.asm#L190) | lives in reserve, 7 at a new game |
| $85CD | [FlashTimer](../src/variables.asm#L205) | screen flash counter; never set by the game (F105) |
| $85CE | [JoystickFlag](../src/variables.asm#L219) | 1 = Kempston joystick detected |
| $85CF | [WillyY](../src/variables.asm#L243) | Willy's Y index (top of his sprite); $D0 = standing on the floor of row 15 |
| $85D0 | [WillyMoveState](../src/variables.asm#L265) | bit 0 facing left, bit 1 walking |
| $85D1 | [WillyAirState](../src/variables.asm#L293) | 0 ground, 1 jump, 2-$0F fall, $FF killed |
| $85D2 | [WillyFrame](../src/variables.asm#L308) | walk frame 0-3 (also the step timer) |
| $85D3 | [WillyAttrAddr](../src/variables.asm#L328) | word: attribute address of Willy's top-left cell |
| $85D5 | [WillyJumpStep](../src/variables.asm#L344) | jump step 0-18 |
| $85D6 | [WillyRope](../src/variables.asm#L360) | 0 no rope, 1-$20 segment held, $F0-&#36;FF just let go |
| $85D7-$85DD | [WillySavedState](../src/variables.asm#L386) | copy of $85CF-$85D5 made at room entry, restored after a death |
| $85DE | [ItemCounter](../src/variables.asm#L401) | starts at $AD (first item index), wraps to 0 when all 83 are collected |
| $85DF | [EndingStage](../src/variables.asm#L432) | 0 play, 1 all items, 2 running to the toilet, 3 at the toilet |
| $85E0 | [IdleCounter](../src/variables.asm#L447) | passes without a movement key or tune pass; wraps into a pause |
| $85E1 | [TuneStep](../src/variables.asm#L458) | in-game tune position; also the walking frame of the lives display |
| $85E2 | [TuneFlags](../src/variables.asm#L474) | bit 0 tune key held last pass, bit 1 tune off |
| $85E3 | [CheatProgress](../src/variables.asm#L489) | letters of WRITETYPER typed, 10 = cheat on |
| $85E4 | [ScratchByte](../src/variables.asm#L501) | expected colour code, then a loop counter of the title scroll and the game over (F13) |

Texts that change while playing are kept as ASCII and printed every pass:
[ItemsCollectedText](../src/variables.asm#L125) ($857C, three digits) and [ClockText](../src/variables.asm#L138) ($857F, six
characters such as " 7:00a"). There is no binary score or time.

## Room record

One page of 256 bytes per room at $C000 + 256 * N, copied to [RoomBuffer](../src/buffers.asm#L37)
($8000) when the room is entered; all code reads the copy. The page is
`$C0 OR N`, so only the low 6 bits of a room number matter (F36). The format
description is in the header of [RoomOffLicence](../src/rooms.asm#L98); F26-F33, F39 verify it.

| Offset | Size | Label in the buffer | Meaning |
| --- | --- | --- | --- |
| $00 | 128 | [RoomBuffer](../src/buffers.asm#L37) | layout: 16 rows x 32 cells, 2 bits per cell, first cell in bits 7-6; cell value = tile 0-3 |
| $80 | 32 | [RoomName](../src/buffers.asm#L39) | name, ASCII, printed on screen row 16 |
| $A0 | 9 | [RoomTiles](../src/buffers.asm#L41) | tile 0 background: attribute + 8 pixel rows |
| $A9 | 9 | [TileFloor](../src/buffers.asm#L43) | tile 1 floor |
| $B2 | 9 | [TileWall](../src/buffers.asm#L45) | tile 2 wall |
| $BB | 9 | [TileNasty](../src/buffers.asm#L47) | tile 3 nasty |
| $C4 | 9 | [TileRamp](../src/buffers.asm#L49) | tile 4 ramp (not in the layout, drawn from the ramp fields) |
| $CD | 9 | [TileConveyor](../src/buffers.asm#L51) | tile 5 conveyor (drawn from the conveyor fields) |
| $D6 | 1 | [RoomConveyorDir](../src/buffers.asm#L53) | 0 moves Willy left, 1 right (F28) |
| $D7 | 2 | [RoomConveyorAddr](../src/buffers.asm#L55) | attribute address ($5E00 buffer) of the leftmost belt cell |
| $D9 | 1 | [RoomConveyorLen](../src/buffers.asm#L57) | belt length in cells, 0 = none |
| $DA | 1 | [RoomRampDir](../src/buffers.asm#L59) | bit 0: 0 rises to the left, 1 to the right |
| $DB | 2 | [RoomRampAddr](../src/buffers.asm#L61) | attribute address of the lowest ramp cell |
| $DD | 1 | [RoomRampLen](../src/buffers.asm#L63) | ramp length in cells, 0 = none |
| $DE | 1 | [RoomBorder](../src/buffers.asm#L65) | border colour (written whole to port $FE) |
| $DF | 2 | | not read by any code; rooms 0-4 hold words $A000-&#36;A0C0 (F32) |
| $E1 | 8 | [RoomItemGfx](../src/buffers.asm#L68) | the item picture of the room |
| $E9 | 1 | [RoomExitLeft](../src/buffers.asm#L70) | room to the left |
| $EA | 1 | [RoomExitRight](../src/buffers.asm#L72) | room to the right |
| $EB | 1 | [RoomExitUp](../src/buffers.asm#L74) | room above |
| $EC | 1 | [RoomExitDown](../src/buffers.asm#L76) | room below |
| $ED | 3 | | not read by any code; zero |
| $F0 | 16 | [RoomEntitySlots](../src/buffers.asm#L79) | eight entity slots: definition index, start byte |

The tiles are found by attribute byte, not by number: the code compares the
attribute of a cell with the attribute bytes at $80A0, $80B2, $80BB, $80C4
and $80CD. Tile 1 (floor) is never compared; any attribute that is not
background, nasty or wall holds Willy up (F31, F112). The six attributes of a
room must therefore differ, and the bitmap of a cell is found by searching
the tile area for its attribute, which gives wrong pixels in five rooms
(F30, F40; see [Tricks](06-tricks.md#tiles-found-by-colour)).

An exit byte of 0 is not "no exit"; it is room 0. Edges Willy cannot reach
mostly hold 0, and some rooms name themselves (F27).

## Entity definitions and the entity buffer

[EntityDefs](../src/entitydefs.asm#L88) at $A000 holds 128 definitions of 8 bytes (index I at $A000 +
8 * I). When a room is entered, [EnterRoom](../src/title.asm#L285) copies the definition of each
of its eight slots into [EntityBuffer](../src/buffers.asm#L116) at $8100, with byte +2 replaced by
the slot's start byte, which is also written back into the definition (F25,
F48, F50). Bit 7 of the slot index is dropped. Slot index $FF selects
definition $7F ([EntityTerminatorDef](../src/entitydefs.asm#L449)), whose first byte $FF ends the
list; a byte $FF at $8140 ends a full list.

The type is bits 0-2 of byte +0 (F80): 0 empty, 1 horizontal guardian, 2
vertical guardian, 3 rope, 4 arrow. Types 5-7 do not occur.

| Byte | Horizontal guardian (1) | Vertical guardian (2) | Rope (3) | Arrow (4) |
| --- | --- | --- | --- | --- |
| +0 | bits 0-2 type, bit 7 direction (1 right), bits 5-6 animation phase | type, bit 3 flips every pass, bit 4 fast animation, bits 5-7 phase | type, bit 7 swing direction | type, bit 7 direction (1 right) |
| +1 | bits 0-2 ink, bit 3 bright, bits 5-7 frame mask | same | swing position: bits 0-6 distance from hanging straight, bit 7 side (1 left) | not read |
| +2 (slot) | bits 0-4 column, bits 5-7 frame offset | same | column of the top | Y index of the centre row |
| +3 | Y index | Y index (moves) | scratch: current column | not read |
| +4 | not read | Y step, signed | length in segments ($20) | X column, moves 1 per pass |
| +5 | sprite page | sprite page | scratch: pixel mask | scratch: collision mask |
| +6 | left limit (column) | top limit (Y) | not read | fin pixel pattern |
| +7 | right limit (column) | bottom limit (Y) | swing limit ($36) | not read |

The sprite of a guardian is page(+5) * 256 + 32 * F with
F = ((+0 AND +1) OR +2) >> 5 (F54): the mask in +1 decides which animation
bits of +0 select the frame, the high bits of the slot byte are added. The
rope also uses bytes +1 (segment counter) and +3 bit 0 (held flag) of the
entry after it, so rooms always put an arrow or the end marker after a rope
(F55, F90).

Indexes $01-$6F except $2B are used by rooms 0-60; $00, $2B, $3F and
$70-$7E are unused (F56). The comment on each line of
[`src/entitydefs.asm`](../src/entitydefs.asm) gives the type, limits, sprite
page and the rooms that use it.

## Item table

| Address | Contents |
| --- | --- |
| $A3FF [FirstItemIndex](../src/itemtable.asm#L10) | $AD: the first item index; items are indexes $AD-&#36;FF (83) |
| $A400 + i [ItemRoomTable](../src/itemtable.asm#L46) | bits 0-5 room, bit 6 item still present, bit 7 bottom half of the room |
| $A500 + i [ItemPositionTable](../src/itemtable.asm#L63) | bits 0-4 column, bits 5-7 row inside the half |

The second byte is also the low byte of the item's attribute address (page
$5C or $5D, chosen by bit 7) and of its bitmap address (page $60 or $68).
Bit 6 is clear on the tape; [NewGame](../src/title.asm#L30) sets it for all 83 items (F15).
Items per room are listed in the header of [ItemRoomTable](../src/itemtable.asm#L46); the most are
12 in "The Off Licence". Two items of "The Beach" share a cell (F18).

## Sprites

All sprites are 16 x 16 pixels, 32 bytes: 16 rows of 2 bytes (left byte,
right byte), top row first, bit 7 = leftmost pixel. They have no colour of
their own. A sprite page is 256 bytes holding 8 frames; frame F is at
page * 256 + 32 * F.

| Range | Contents |
| --- | --- |
| $9C40 [SpriteFoot](../src/charsprites.asm#L25), $9C60 [SpriteBarrel](../src/charsprites.asm#L51) | game-over foot and barrel; the foot is also guardian definition $48 in "The Nightmare Room" |
| $9C80-$9CFF [SpriteFigure0](../src/charsprites.asm#L80) | the figure of the Master Bedroom, 4 frames |
| $9D00-$9D7F [SpriteWillyRight0](../src/charsprites.asm#L193) | Willy facing right, 4 frames |
| $9D80-$9DFF [SpriteWillyLeft0](../src/charsprites.asm#L298) | Willy facing left, 4 frames |
| $A600-&#36;BFFF | 26 pages of guardian sprites; $A6 also holds the toilet; $A7-&#36;AA and $B3 are zero, $B1 is not used (F59) |

The page list with their pictures is in the [gallery](07-graphics.md#sprite-pages).

## Tables

| Address | Name | Format |
| --- | --- | --- |
| $8200 | [RowAddressTable](../src/buffers.asm#L138) | 128 words: work-bitmap address of pixel row r = $6000 + 256 * (r mod 8) + 32 * ((r div 8) mod 8) + $800 * (r div 64), indexed by 2r (F38) |
| $8300 | [RopeStepTable](../src/buffers.asm#L184) | two halves of 128 bytes indexed by segment + swing distance: $8300 + I pixels sideways, $8380 + I rows down in row-table bytes (2 per pixel row); defined for I up to $55 (F23) |
| $8421 | [MoveStateTable](../src/variables.asm#L36) | 16 bytes: new move state = table[old state + 4 * left + 8 * right] (F24) |
| $8431 | [TitleEdgePieces](../src/variables.asm#L54) | four 8x8 pieces of the slanted edges of the title picture |
| $85E5 | [CheatKeyTable](../src/variables.asm#L525) | 11 pairs of key masks (half rows Q-T and P-Y) for W R I T E T Y P E R |
| $9E00 | [CodeTable](../src/codetable.asm#L21) | 256 bytes: code byte for grid cell L is table[L] + L |

[MoveStateTable](../src/variables.asm#L36), rows by key and columns by old state:

| Keys | old 0 | old 1 | old 2 | old 3 |
| --- | --- | --- | --- | --- |
| none | 0 | 1 | 0 | 1 |
| left | 1 | 3 | 1 | 3 |
| right | 2 | 0 | 2 | 0 |
| both | 0 | 1 | 2 | 3 |

A key in the facing direction walks at once; a key in the other direction
first only turns (one pass without a step). Both keys together keep the old
state, which is also what happens when a key is held against a conveyor.

## Tunes

| Address | Name | Format |
| --- | --- | --- |
| $85FB | [TitleTune](../src/variables.asm#L557) | 99 one-byte notes, $FF ends. A note byte is a half-period count; each note has the same length and drops an octave halfway (F44, F73) |
| $865F | [GameTune](../src/variables.asm#L610) | 64 notes, no end marker, one note per two passes; pitch = note + 28 - 4 * lives (F74) |

The music is described in [Sound](05-sound.md).

## Texts

All texts are ASCII printed with the ROM font, fixed length, no terminator.

| Address | Name | Text |
| --- | --- | --- |
| $8451 | [UnusedAirText](../src/variables.asm#L67) | "AIR", not referenced (F12) |
| $8454 | [TitleMessage](../src/variables.asm#L80) | 256 characters scrolled on the title screen |
| $8554 | [StatusLineText](../src/variables.asm#L99) | "Items collected 000 Time 00:00 m" (the digits and the time are printed over it) |
| $8574 | [GameText](../src/variables.asm#L107), [OverText](../src/variables.asm#L114) | "Game", "Over" |
| $857C | [ItemsCollectedText](../src/variables.asm#L125) | "000" |
| $857F | [ClockText](../src/variables.asm#L138) | " 7:00a" |
| $8585 | [ClockStartText](../src/variables.asm#L146) | " 7:00a", copied to the clock at the start of a game |
| $858B | [EnterCodeText](../src/variables.asm#L154) | "Enter Code at grid location     " |
| $85AB | [TryAgainText](../src/variables.asm#L160) | "Sorry, try code at location     " |

## Screen attribute maps

| Address | Name | Use |
| --- | --- | --- |
| $9800 | [TitleAttributes](../src/screens.asm#L24) | 512 bytes for screen rows 0-15 of the title; the picture is made of attribute cells plus edge pieces |
| $9A00 | [StatusBarAttributes](../src/screens.asm#L73) | 256 bytes for rows 16-23: room name yellow, status line in rainbow inks, the lives in seven colours |
| $9B00 | [CodeKeyGraphics](../src/screens.asm#L95) | four 16x16 key pictures "1"-"4" of the code screen |
| $9B80 | [CodeScreenAttrs](../src/screens.asm#L172) | 128 bytes for rows 8-11 of the code screen |
