# 5.8 Screen drawing

The room area (the top two thirds of the screen) is never drawn on the
screen directly. Each pass starts from a clean copy of the empty room in
two work buffers laid out like the screen, draws Willy, the entities and
the items into them, and copies them to the screen with `LDIR`. The work
buffers are also the collision map: attribute colours say what a cell is,
lit pixels say what a sprite would hit. The bottom third (status area) and
the other screens are drawn directly.

## Buffers

| Buffer | Size | Layout | Filled by | Read by |
| --- | --- | --- | --- | --- |
| $5E00 empty-room attributes | 512 | 16 rows x 32 | [ExpandRoomLayout](../src/roombuild.asm#L85) at room entry | the frame loop copy, nothing else |
| $7000 empty-room bitmap | 4096 | two screen thirds | [BuildRoomBuffers](../src/roombuild.asm#L31); [AnimateConveyor](../src/exits.asm#L119) changes it every pass | the frame loop copy |
| $5C00 work attributes | 512 | 16 rows x 32 | copy of $5E00, then Willy, guardians, arrows, items, figure, toilet | all collision tests, then copied to $5800 |
| $6000 work bitmap | 4096 | two screen thirds | copy of $7000, then the sprites | collision tests, then copied to $4000 |

The bitmap buffers use the Spectrum screen layout ($6000 is $4000 moved up
by $2000), so the same address arithmetic works for both, and one block copy
moves a buffer to the screen. [FrameLoop_Present](../src/mainloop.asm#L126) copies the bitmap first
and the attributes later in the pass. Moving everything into a buffer first
means a sprite is never seen half drawn, but the copies cost about 193,000
T states per pass, three quarters of the time (F93).

## The row table

[RowAddressTable](../src/buffers.asm#L138) ($8200) holds the work-bitmap address of each of the
128 pixel rows: $6000 + 256 * (r mod 8) + 32 * ((r div 8) mod 8) + $800 *
(r div 64) (verified for all rows, F38). A Y index is twice the pixel row,
so a Y index is a direct offset into this table of words: `LD L,Y` with
`H = $82` gives the entry. Guardians, Willy, the toilet, the arrows, the
ropes and the game-over foot all find their rows through it.

## Sprites

[DrawSprite](../src/sprite.asm#L33) ($9456) draws a 16x16 sprite (32 bytes, 2 per row) at HL in a
bitmap with the screen layout, stepping down a row with `INC H` and fixing
up the character-row and third boundaries:

```asm
  INC H                   ; next pixel row
  INC DE
  LD A,H
  AND CELL_HEIGHT-$01
  JR NZ,DrawSprite_2      ; still inside the character row
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
```

Bit 0 of C selects the mode (F37):

- 0: replace the bitmap bytes (code-screen keys, lives, game over);
- 1: collision test. Each sprite byte is ANDed with the byte under it; a
  non-zero result returns NZ at once (the rows drawn before stay drawn);
  otherwise the byte is ORed in. Guardians and the Master Bedroom figure use
  this mode on the work bitmap, and NZ kills Willy.

[DrawWilly](../src/output.asm#L23) and its second entry [DrawSpriteRows](../src/output.asm#L57) OR a sprite into the
work bitmap through the row table (IX walks the table, one entry per row),
without a test. Willy and the toilet use it. Because Willy is drawn first
and without a test, he never collides with anything himself; the entities
drawn after him find his pixels.

## Text

[PrintText](../src/output.asm#L89) prints C characters from IX at screen address DE with
[PrintChar](../src/output.asm#L114), which finds the glyph at $3C00 + 8 * code in the ROM
(bit 7 of the code ignored) and copies its 8 rows with [DrawGlyph8](../src/output.asm#L128). The
same 8-row copy draws the title edge pieces and the item pictures. Texts
are written straight to the screen (status line, title, code screen, game
over); the clock and the items count are reprinted every pass.

## Colour as collision map

| Test | Reads | Meaning |
| --- | --- | --- |
| ground under Willy | the two cells under his feet in $5C00 | not background and not nasty = ground |
| walls | cells beside him and above his head | wall attribute = blocked |
| nasty | his six cells | nasty attribute = death |
| ramp | one cell by direction | ramp attribute = step up or down |
| conveyor | the two cells under his feet | conveyor attribute = pushed |
| item collected | the item cell | ink 7 = touched |
| arrow hit | the arrow's cell | ink 7 = Willy may be there |

The tile attributes come from the room record, so each room has its own
colour code. Willy's ink 7 only goes into background cells ([MarkWillyCell](../src/specialrooms.asm#L224)),
so it never hides a floor, wall or nasty from the tests that follow.

## Pixels as collision map

Guardians, the figure, the arrows and the ropes test pixels in the work
bitmap. At the time they are drawn it holds the room tiles, Willy, and the
entities drawn before them in the list. A guardian therefore also "hits" a
lit tile pixel or an earlier guardian (F83), and a rope is grabbed by any lit
pixel under one of its points (F87). The room designs avoid this; with the
guardian table damaged by the Attic arrow it happens
([Tricks](06-tricks.md#the-attic-arrow)).

## Colour effects

[CycleColours](../src/mainloop.asm#L250) adds 3 to the ink and the paper of every attribute cell on
the screen, clears bright, and sets the border to the old ink of the first
cell. It is the title scroll effect and the pause effect. A cell with bright
set whose paper wraps past 7 gets flash toggled by the carry of the paper
addition (observed with $78 → $93).
