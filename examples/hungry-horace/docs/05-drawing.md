# 5e. Drawing and screen layout

All graphics are drawn straight into the Spectrum display file, cell by cell,
with the attribute of each cell written together with its pixels. There is
no back buffer: sprites are erased and redrawn in place on every pass. The
attributes double as the game's collision map, so the drawing routines also
maintain the data the movement code reads.

## Screen layout

| Rows | Contents |
| --- | --- |
| 0 | status line `PASSES n   SCORE nnnnn   BEST nnnnn` (game) or `DEMO MODE  PRESS ANY KEY TO PLAY` (demo) |
| 1-23 | the maze: 32 x 23 cells drawn from the map (row 0 of every map is empty and is overwritten by the status line) |

The border is white during play: every sound routine writes 7 (white) to the
border bits of port $FE with the speaker off.

## Addresses and the alternate register set

The Spectrum bitmap is split into three thirds of eight character rows; the
eight pixel rows of a cell are 256 bytes apart. The game keeps positions as
offsets in that layout (see [Data structures](02-data.md#positions-and-directions))
and walks the bitmap with these rules:

- next pixel row: `INC H`;
- next cell to the right: `INC L`; if L wraps to 0 the cell was the last one
  of a third, and H (already 8 higher after drawing eight rows) points into
  the next third, so no correction is needed; otherwise H is moved back by 8.
  [DrawCell](../src/library.asm#L292), [DrawMaze](../src/library.asm#L155), [DrawBlocks](../src/library.asm#L706) and [SaveBackgroundCell](../src/library.asm#L492) all
  use this test;
- next cell row of a 2x2 sprite: L + 30 (from two cells to the right), with
  H + 8 on carry ([DrawSprite](../src/library.asm#L247), [EraseGuard_Always](../src/sprites.asm#L77), [SaveBackground](../src/library.asm#L444)).

The attribute address of a cell has the same low byte as its bitmap address;
the high byte is `$58 + third`. [SetAttrPointer](../src/library.asm#L329) computes it from H and
leaves it in the **alternate** HL (HL'). [DrawCell](../src/library.asm#L292) and [PrintChar](../src/library.asm#L105) then
write the attribute through HL' with `EXX` and advance it, so a row of cells
can be drawn with one attribute pointer set up per row. The collision probes
([GetBlockObject](../src/library.asm#L359), [ProbeMove](../src/library.asm#L556)) also run their loops in the alternate
set. A port must treat HL' as live state across these calls.

## Building blocks

| Routine | Draws | Inputs |
| --- | --- | --- |
| [DrawCell](../src/library.asm#L292) | one 8x8 cell and its attribute | HL bitmap address, HL' attribute address, DE 8 bytes, C attribute |
| [DrawSprite](../src/library.asm#L247) | a 16x16 sprite, one attribute for all four cells | HL screen offset, DE 32 bytes, C attribute; HL' set by the caller |
| [DrawMaze](../src/library.asm#L155) | a map of tile codes | HL map, DE screen address, BC cell count |
| [DrawBlocks](../src/library.asm#L706) | block-pixel pictures (the title words) | HL data, DE screen address, BC cell count |
| [PrintChar](../src/library.asm#L105) | one ROM-font character, black on white ($38) | A code, DE cell address, HL' attribute; only if bit 0 of [GameActive](../src/texts.asm#L72) is set |
| [PrintNumber](../src/library.asm#L54) / [PrintDigit](../src/library.asm#L87) | a 5-digit decimal number with leading zeros | HL number, DE first cell |

[DrawMaze](../src/library.asm#L155) makes two passes over the map: first it sets every attribute
from the tile code (one `CP` chain, [Data structures](02-data.md#maze-map)),
then it copies each tile's 8 bitmap bytes from [TileGraphics](../src/tiles.asm#L10) through IX.
IX is left pointing into the tile graphics afterwards, which
[CheckGuardContact](../src/events.asm#L27) relies on for a delay loop (see
[Tricks and bugs](06-tricks.md#ix-as-a-harmless-delay)).

[PrintChar](../src/library.asm#L105) computes the font address as `A * 8 + ($3D00 - $100)`, the ROM
character set, where character $7F is the © sign used in the title.
[PrintDigit](../src/library.asm#L87) finds each digit by repeated subtraction of 10000, 1000, 100
and 10 and falls through into [PrintChar](../src/library.asm#L105).

## Sprites and backgrounds

Horace and the bell are erased by drawing [BlankSprite](../src/sprite_gfx.asm#L162) (32 zero bytes)
with the floor attribute $3E. That is enough for them, because Horace eats
whatever he walks over and the bell does not move.

Guards move over flowers, fruit and the bell without eating them, so each
guard record keeps a copy of the four cells under the guard
([SavedBackground](../src/state.asm#L132), 9 bytes per cell: attribute and 8 rows):

1. [EraseGuard](../src/sprites.asm#L66): if the guard has moved, draw the saved cells back at the
   old position, then [SaveBackground](../src/library.asm#L444) at the new position.
2. [DrawGuard](../src/sprites.asm#L273): draw the guard at the new position.

[SaveBackgroundCell](../src/library.asm#L492) stores a guard-coloured cell as blank floor, so when
two guards overlap, neither remembers the other as background. A cell with
Horace's colour is saved as it is (read from the code).

Per pass the screen changes in this order: [EraseSprites](../src/sprites.asm#L13) (Horace, then
guards 4 to 1), [DrawGuards](../src/sprites.asm#L235) (guards 1 to 4), [DrawHorace](../src/events.asm#L342), [UpdateBell](../src/events.asm#L419)
(the bell, on top of everything). Between the erase and the draw a figure is
missing from the screen; there is no synchronisation with the display, so
this can be visible as flicker (inferred).

## The attribute map as collision map

After [DrawMaze](../src/library.asm#L155), the game never reads a maze map again. Every question
about the maze is answered from the attribute area:

| Question | Routine | Attributes used |
| --- | --- | --- |
| can a figure move one cell? | [ProbeMove](../src/library.asm#L556) / [ProbeCell](../src/library.asm#L606) | $3D wall, $3F pad, $38 arrow |
| what does Horace step on? | [EatObject](../src/sprites.asm#L133) via [GetBlockObject](../src/library.asm#L359) | $3C flower, $3A bell or fruit (guard $3B has priority) |
| does Horace touch a guard? | [CheckGuardContact](../src/events.asm#L27) via [GetBlockObject](../src/library.asm#L359) | $3B |
| is a fruit or the bell already under a guard? | [MaybeDropFruit](../src/events.asm#L558) | $3A in the saved background |
| what must not be saved under a guard? | [SaveBackgroundCell](../src/library.asm#L492) | $3B |

This keeps the code small (no separate collision array, no object lists for
flowers), at the price that every sprite must be drawn with the right
attribute and in the right order. The consequences are discussed in
[Tricks and bugs](06-tricks.md#attributes-as-the-collision-map).

## Title and status texts

[PrintChar](../src/library.asm#L105) returns without drawing when bit 0 of [GameActive](../src/texts.asm#L72) is clear.
That one test switches off the status line, the score, the passes digit and
the best score in the demo. The title screen and the demo banner, which must
be printed while [GameActive](../src/texts.asm#L72) is 0, set it to 1 for the duration of the
print loop and restore it afterwards ([PrintTitleText](../src/main.asm#L109), [ShowDemoBanner](../src/main.asm#L255)).
