# 5f. Pictures

The 22 location pictures are not bitmaps but small programs: lines, flood
fills and attribute paints, about 10K of commands for 22 screens of
256x128 pixels. They are drawn live, pixel by pixel, each time the player
enters a pictured location for the first time or looks around there. This
file explains the format and the drawing routines; every picture is shown in
[07-graphics](07-graphics.md).

## When a picture is drawn

[ShowLocation](../src/engine.asm#L327) (the long description: first visit, LOOK, being captured)
prints "You are in ..." and the description, then calls
[DrawLocationPicture](../src/drawing.asm#L21) with the location id:

- nothing happens when pictures are off (N held at the title,
  [PicturesEnabled](../src/world.asm#L57) = 0) or when [PictureTable](../src/pictures.asm#L16) has no record for the
  location (57 of the 79 locations): [PictureFound](../src/drawing.asm#L2) is `$FF`;
- otherwise the picture is drawn into character rows 0-15 and
  [WaitKeyAfterPicture](../src/engine.asm#L380) waits for any key; then the border turns white and
  the text goes on, scrolling the picture away.

A visited location gets the short description and no picture.

The text printed before the picture is at the bottom of the story window
(row 17), below the picture area, so the player sees the first line of the
description under the picture while it is drawn (see the screenshot in
[03-title-and-menu](03-title-and-menu.md)).

## The format ([RunPictureCommands](../src/drawing.asm#L77))

[PictureTable](../src/pictures.asm#L16) at `$CC00`: 22 records of (location id, address), `$FF`
ends. The data of all pictures lies back to back from `$CC43` to `$F35A`.

A picture is two header bytes and a command stream:

| Bytes | Meaning |
| --- | --- |
| header +0 | border colour |
| header +1 | attribute for the whole picture area (paper and ink) |
| `$00` | end of the picture |
| `$08` x y | move the pen to (x, y) |
| `$01-$1F` (others) | ignored (none occur) |
| `$20-$27` hh ll runs... `$FF` | paint: paper colour = low 3 bits; start at attribute address hh:ll; each run byte is direction (bits 0-1: up, right, down, left) and count (bits 2-7, +1); `$FF` ends |
| `$40-$7F` x y | flood fill from (x, y) with ink = low 3 bits |
| `$80-$FF` b2 | a straight line from the pen, 2 bytes (below) |

Coordinates: x 0-255 from the left, y 0-127 from the **bottom** of the
picture area ([PenToScreen](../src/drawing.asm#L641) converts with row = 127 - y). The pen starts at
(`$7F`, `$3F`), the middle.

### Lines ([DrawPictureLine](../src/drawing.asm#L510))

A line is two bytes, `1 rrrr L D V` and `rr nnnnnn`:

| Field | Meaning |
| --- | --- |
| V | 1: vertical-major (one step in y per step), 0: horizontal-major |
| D | the minor (or vertical) step goes down, else up |
| L | the horizontal step goes left, else right |
| nnnnnn | number of major steps - 1 (1-64 steps) |
| rrrr rr | one minor step after every rrrrrr + 1 major steps (1-64) |

So a line is a run of n major steps with a fixed slope of 1/k, k = 1..64:
no division, no error term, and every slope the picture needs is chosen by
the artist when the line is stored. Long curves are chains of short lines.
The pen stays at the end of the line, so most lines continue from the last.
A line stops at the edge of the picture area.

### Flood fill ([FloodFill](../src/drawing.asm#L237))

A scan-line fill: from the seed it goes left to the first lit pixel, then
plots the span to the right; for the rows above and below, it pushes one new
seed for each run of clear pixels. Seeds are pushed on the Z80 stack itself,
above a sentinel (y = `$80`); the fill ends when the sentinel comes back. The
boundary is any lit pixel, so the outlines must be closed; the fill colour
goes into the attributes, not the bitmap.

### Colour ([PlotPixel](../src/drawing.asm#L592), [StartPicture](../src/drawing.asm#L697))

The Spectrum has one ink and one paper per 8x8 cell. The pictures use that
directly:

- [StartPicture](../src/drawing.asm#L697) clears the 4K of bitmap, fills the 512 attribute bytes of
  rows 0-15 with the header attribute and sets the border;
- every pixel plotted (line or fill) sets its cell's ink to the current ink
  [PicVar1](../src/drawing.asm#L741) and keeps its paper; when ink and paper are equal the ink is
  inverted (7 - colour), which is why the lines of the black night picture of
  the trolls' clearing are white;
- a fill sets [PicVar1](../src/drawing.asm#L741) to its colour for its own pixels and back to 0
  (black) at its end, so the lines drawn after it are black;
- the paint command changes paper colours cell by cell along runs, which is
  how skies and grounds of several colours are made (a sky can be blue above a
  yellow hill line without any pixels).

### Darkness

[StartPicture](../src/drawing.asm#L697) asks [CheckDark](../src/engine.asm#L219) first. When the player cannot see, the
border and attribute are taken as 0 and the drawing is abandoned: a black
area. A dark place is normally not described at all, so this path is reached
mainly through LOOK THROUGH a door into a dark place: the player is moved
there for the description, and the picture comes out black (F54).

## Sharing ([07-graphics](07-graphics.md))

Two pictures are prefixes: the goblins' dungeon (`$0D`, 29 bytes) and the
trolls' clearing (`$05`, 93 bytes) draw a few details and end with a bare
`$08` move whose operands are the header bytes of the next picture in memory,
the dark dungeon (`$1F`) and the elvish clearing (`$1C`); the interpreter then
runs on through that picture. Two locations get similar pictures in different
colours for the price of one. This only works because the pictures are stored
in this order; the table is in address order, not id order.

## The picture that changes

The trolls' clearing (`$05`) has border 0 and attribute 0 on tape: a white
forest on black. When the trolls turn to stone at dawn, [LA94E_0](../src/handlers.asm#L1115) writes
border 5 and attribute `$28` into the two header bytes: the same lines on
cyan paper, by day. [RestartGame](../src/main.asm#L81) writes the zeros back at every new game,
because the picture data is not part of the state the restart restores
(observed, F77). The picture is not saved with SAVE either, so a game saved
after dawn and loaded into a fresh game shows the night picture (inferred).

## Size

| | Bytes |
| --- | --- |
| picture table | 67 |
| 22 pictures | 10008 |
| largest (`$10`, the big goblins' cavern) | 778 |
| smallest complete (`$04`, the Lone-lands) | 124 |
| one screen of bitmap and attributes, for comparison | 6912 |

The drawing routines and their variables ([`drawing.asm`](../src/drawing.asm),
`$7F77-$8250`) take 730 bytes.
