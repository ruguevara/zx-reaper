# 2. Data structures

The game keeps its state in about forty bytes of variables, four 43-byte guard
records with one working copy, and an 8-byte descriptor of the current maze.
Static data are four maze maps of tile codes, ten tiles, sprites, two fruit
pictures in a "saved background" format and two block-pixel title words. This
file gives every layout; the routines that use them are described in the
later sections.

## Positions and directions

Every position in the game (Horace, guards, bell, maze start points) is a
**screen offset**: the address of the top-left character cell of a 16x16
(2x2-cell) object minus $4000, on the first pixel row of the cell.

```
offset = %000TT000 RRRCCCCC
         TT    screen third 0-2
         RRR   character row inside the third 0-7
         CCCCC column 0-31
row    = 8*TT + RRR   (0-23)
```

So one cell right is +1, one cell down is +$20 inside a third, and crossing
from row 7 to row 8 adds $0800-$E0 = $0720 (the step from the last row of one
third to the first row of the next). [StepCell](../src/library.asm#L643) does this arithmetic; the
drawing routines add $4000 and use the offset directly as a bitmap address.
Only the guard AI converts positions to row and column, into [HoraceCell](../src/variables.asm#L225)
and [GuardCell](../src/state.asm#L71) (H = row, L = column).

Direction codes (constants `DIR_*` in [`src/constants.asm`](../src/constants.asm)):

| Code | Direction | Note |
| --- | --- | --- |
| 0 | up | also the default when no direction scores |
| 1 | right | Horace's direction at the start of a maze |
| 2 | down | |
| 3 | left | |
| $FF | none | [RequestedDir](../src/variables.asm#L137) only |

The opposite direction is `(d + 2) AND 3`.

## Attributes: colours that are also object types

Every cell is white paper; the ink colour says what the cell is. The game
never reads the maze map after drawing it: walls, pads, arrows, flowers,
Horace, the guards and the bell are recognised by these attribute values on
the screen ([ProbeCell](../src/library.asm#L606), [MergeObjectAttr](../src/library.asm#L396), [SaveBackgroundCell](../src/library.asm#L492)).

| Attribute | Ink | Constant | Meaning |
| --- | --- | --- | --- |
| $38 | black | `ATTR_ARROW` | edge arrows; also the status line text and the title text |
| $39 | blue | `ATTR_HORACE` | Horace |
| $3A | red | `ATTR_BELL` | bell; also the lower half of a fruit |
| $3B | magenta | `ATTR_GUARD` | guard (normal or scared) |
| $3C | green | `ATTR_FLOWER` | flower; also the upper half (stalk) of a fruit |
| $3D | cyan | `ATTR_WALL` | wall or wall corner |
| $3E | yellow | `ATTR_BLANK` | empty floor (blank bitmap) |
| $3F | white | `ATTR_PAD` | wrap pad: white on white, invisible |

## Variables

All variables are in RAM between the code. "Word" is little-endian.

| Address | Name | Size | Meaning |
| --- | --- | --- | --- |
| $6B08 | [TitleCountdown](../src/texts.asm#L39) | word | title-loop passes left before the demo starts (140 at the start) |
| $6B0A | [GuardsReleased](../src/texts.asm#L55) | byte | meant to count released guards; see [Tricks and bugs](06-tricks.md#tickguardtimers-counts-the-wrong-thing) |
| $6B0B | [GameActive](../src/texts.asm#L72) | byte | 0 = title or demo, 1 = real game; bit 0 also enables [PrintChar](../src/library.asm#L105) |
| $6DA6 | [GuardTimers](../src/state.asm#L20) | 4 words | release timer per guard, in passes; 0 = guard is in the maze |
| $6DAE | [BellTimer](../src/state.asm#L61) | word | guards are scared and edible while non-zero |
| $6DB0 | [GuardCell](../src/state.asm#L71) | word | AI scratch: guard's row (H) and column (L) |
| $6DB2 | [GuardDirScores](../src/state.asm#L82) | 4 bytes | AI scratch: score per direction 0-3 (also the demo autopilot's weights) |
| $6DB6 | [GuardRecordPtr](../src/state.asm#L94) | word | address of the record held in the working buffer; its address also ends the score table |
| $6DB8 | [GuardRecord](../src/state.asm#L122) | 43 bytes | working copy of one guard record (layout below) |
| $6DE3 | [GuardRecords](../src/state.asm#L170) | 4 x 43 | guard records 1-4 ($6DE3, $6E0E, $6E39, $6E64) |
| $6FCF | [MazeDescriptor](../src/mazes.asm#L20) | 8 bytes | descriptor of the current maze (layout below) |
| $7C61 | [StepCountdown](../src/variables.asm#L21) | byte | passes until the next movement step |
| $7C62 | [GuardInterval](../src/variables.asm#L34) | byte | game pace 8 (slow) ... 1 (fast); the "level" |
| $7C63 | [MazeNumber](../src/variables.asm#L46) | byte | 0-3; $FF before the first maze |
| $7C64 | [UnusedAiCounter](../src/variables.asm#L58) | byte | written by the AI, never used |
| $7C65 | [FruitTimer](../src/variables.asm#L69) | word | countdown to the next fruit |
| $7C67 | [RandomPtr](../src/variables.asm#L79) | word | ROM address of the next random byte ($0000-$1FFF) |
| $7C69 | [SoundMask](../src/variables.asm#L89) | byte | $1F sound on, $07 sound off; ANDed into every OUT to port $FE |
| $7C6A | [SoundKeyState](../src/variables.asm#L97) | byte | last state of the T key (bit 4) |
| $7C6B | [HoracePos](../src/variables.asm#L113) | word | Horace's position (screen offset) |
| $7C6D | [HoraceNextPos](../src/variables.asm#L126) | word | where Horace will be drawn on this pass |
| $7C6F | [RequestedDir](../src/variables.asm#L137) | byte | direction asked for by the keys, $FF none |
| $7C70 | [HoraceDir](../src/variables.asm#L146) | byte | Horace's current direction |
| $7C71 | [HoraceAttr](../src/variables.asm#L155) | byte | Horace's attribute, $39; cycled during the death animation |
| $7C72 | [HoraceAnim](../src/variables.asm#L164) | byte | Horace's animation counter, bit 4 = walking frame |
| $7C73 | [Score](../src/variables.asm#L174) | word | score, binary |
| $7C75 | [BestScore](../src/variables.asm#L183) | word | best score since loading |
| $7C77 | [ExtraPassMark](../src/variables.asm#L194) | byte | score / 10000 + 2 at the last score display |
| $7C78 | [Passes](../src/variables.asm#L204) | byte | lives |
| $7C79 | [WrapPause](../src/variables.asm#L215) | byte | passes Horace stays invisible and frozen after a wrap pad |
| $7C7A | [HoraceCell](../src/variables.asm#L225) | word | AI scratch: Horace's row (H) and column (L) |
| $7CC4 | [BellPos](../src/variables.asm#L283) | word | bell position, 0 = no bell |
| $7CC6 | [BellTick](../src/variables.asm#L292) | byte | bell animation counter; also times the chime |

Most values these locations hold in the tape image are placeholders that are
overwritten before use. The exceptions are [BestScore](../src/variables.asm#L183) (0 after loading,
never cleared), and the animation counters [HoraceAnim](../src/variables.asm#L164), [BellTick](../src/variables.asm#L292) and
the guards' +3 bytes, which are only ever incremented.

## Guard record

Four records of 43 ($2B) bytes, one per guard, from [GuardRecords](../src/state.asm#L170). Every
routine that deals with one guard first copies its record into the working
buffer [GuardRecord](../src/state.asm#L122) with [LoadGuardRecord](../src/guards.asm#L41), works on the buffer, and
copies it back with [SaveGuardRecord](../src/guards.asm#L74). The loops pass the guard as B = 4
(first record) down to B = 1 (last record).

| Offset | Size | Label in the buffer | Meaning |
| --- | --- | --- | --- |
| +0 | word | [GuardRecord](../src/state.asm#L122) | position (screen offset of the top-left cell) |
| +2 | byte | [GuardDir](../src/state.asm#L124) | direction 0-3 |
| +3 | byte | [GuardAnim](../src/state.asm#L126) | animation counter, +1 per draw; bit 5 = walking frame set, bit 3 = scared frame |
| +4 | word | [GuardNewPos](../src/state.asm#L128) | position planned by the AI, made current by [DrawGuard](../src/sprites.asm#L273) |
| +6 | byte | [GuardWait](../src/state.asm#L130) | wait counter: 90 after the guard was eaten; the guard is not planned, drawn or allowed to drop fruit while it is non-zero |
| +7 | 36 | [SavedBackground](../src/state.asm#L132) | the four cells under the sprite, 9 bytes each (format below) |

The release timer of a guard is not in its record but in the parallel array
[GuardTimers](../src/state.asm#L20) (guard 1 = first word).

### Saved cell format (background and fruit)

A 16x16 area is stored as four cells in the order top-left, top-right,
bottom-left, bottom-right, 9 bytes each:

| Offset in cell | Size | Meaning |
| --- | --- | --- |
| +0 | byte | attribute |
| +1 | 8 bytes | pixel rows, top first, bit 7 = leftmost pixel |

[SaveBackground](../src/library.asm#L444) fills this from the screen, storing any guard-coloured cell
as a blank floor cell; [EraseGuard](../src/sprites.asm#L66) draws it back. The two fruit pictures
[FruitCellsA](../src/variables.asm#L241) ($7C7C) and [FruitCellsB](../src/variables.asm#L264) ($7CA0) are stored in exactly
this format, because [MaybeDropFruit](../src/events.asm#L558) drops a fruit by copying it over a
guard's saved background.

## Maze descriptor

Four descriptors of 8 bytes from [Maze1Desc](../src/mazes.asm#L50) ($6FD7); [LoadMazeDescriptor](../src/guards.asm#L133)
copies the one for the current maze to [MazeDescriptor](../src/mazes.asm#L20) ($6FCF).

| Offset | Size | Label | Meaning |
| --- | --- | --- | --- |
| +0 | word | [MazeDescriptor](../src/mazes.asm#L20) | vertical wrap delta: added to a position that goes up through a wrap pad, subtracted going down; 0 if the maze has no pads |
| +2 | word | [MazeBellStart](../src/mazes.asm#L22) | bell position at the start of the maze |
| +4 | word | [MazeGuardStart](../src/mazes.asm#L24) | start position of every guard whose release timer is 0 |
| +6 | word | [MazeHoraceStart](../src/mazes.asm#L26) | Horace's start, next to the entrance arrows; also where waiting guards stand and where eaten guards are sent |

The four mazes, in play order (values decoded from the descriptors and maps;
rows and columns of the top-left cell):

| Maze | Descriptor | Map | Wrap delta | Bell | Guard start | Horace start | Exit arrows | Wrap pads | Flowers |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | [Maze1Desc](../src/mazes.asm#L50) $6FD7 | [Maze1Map](../src/mazes.asm#L216) $72F7 | $F800 (-8 rows) | 19, 10 | 12, 21 | 13, 1 | column 30, rows 19-20 | row 14, columns 16-17 | 44 |
| 2 | [Maze2Desc](../src/mazes.asm#L77) $6FDF | [Maze2Map](../src/mazes.asm#L164) $6FF7 | $1060 (+19 rows) | 7, 28 | 16, 16 | 10, 1 | column 30, rows 10-11 | rows 1 and 23, columns 13-14 | 55 |
| 3 | [Maze3Desc](../src/mazes.asm#L104) $6FE7 | [Maze3Map](../src/mazes.asm#L267) $75F7 | 0 | 5, 29 | 9, 12 | 21, 1 | column 31, rows 2-3 | none | 44 |
| 4 | [Maze4Desc](../src/mazes.asm#L132) $6FEF | [Maze4Map](../src/mazes.asm#L319) $78F7 | $0FE0 (+15 rows) | 3, 29 | 11, 15 | 3, 1 | column 31, rows 20-21 | rows 3 and 21, columns 4-5 and 26-27 | 24 |

The maps are not stored in play order: the map of maze 2 comes first in
memory. [NextMaze](../src/main.asm#L186) picks descriptor and map with a chain of compares on
[MazeNumber](../src/variables.asm#L46) ([SelectMaze](../src/main.asm#L205)).

## Maze map

768 bytes per maze, one tile code per character cell, 32 columns by 24 rows,
row by row. Row 0 is empty in every map (the status line goes there).
[DrawMaze](../src/library.asm#L155) turns each code into an attribute and copies the tile's bitmap
from [TileGraphics](../src/tiles.asm#L10) (8 bytes per tile, at `$7BF7 + 8 * code`).

| Code | Tile | Attribute set by DrawMaze |
| --- | --- | --- |
| 0 | empty floor (blank) | $3E yellow ink |
| 1 | horizontal wall (two lines) | $3D cyan |
| 2 | flower | $3C green |
| 3 | arrow pointing right | $38 black |
| 4 | vertical wall (two lines) | $3D cyan |
| 5 | wall corner, top-left | $3D cyan |
| 6 | wall corner, top-right | $3D cyan |
| 7 | wall corner, bottom-left | $3D cyan |
| 8 | wall corner, bottom-right | $3D cyan |
| 9 | wrap pad (blank) | $3F white on white |

Corridors are two cells wide, the size of a sprite. The maps are shown in the
[gallery](07-graphics.md#mazes).

## Sprites

All moving figures are 16x16 pixels: 32 bytes, four 8x8 cells in the order
top-left, top-right, bottom-left, bottom-right, 8 bytes per cell, top row
first, bit 7 leftmost. [DrawSprite](../src/library.asm#L247) draws one with a single attribute for
all four cells, given by the caller.

| Address | Label | Count | Selection |
| --- | --- | --- | --- |
| $7CC7 | [HoraceSprites](../src/sprite_gfx.asm#L15) | 4 | Horace, walking frame A, one per direction 0-3; used when bit 4 of [HoraceAnim](../src/variables.asm#L164) is set |
| $7D47 | [HoraceSprites2](../src/sprite_gfx.asm#L40) | 4 | Horace, frame B; bit 4 clear |
| $7DC7 | [GuardSprites](../src/sprite_gfx.asm#L72) | 4 | guard, frame A, per direction; bit 5 of the guard's animation counter set |
| $7E47 | [GuardSprites2](../src/sprite_gfx.asm#L96) | 4 | guard, frame B; bit 5 clear |
| $7EC7 | [ScaredGuardSprites](../src/sprite_gfx.asm#L122) | 2 | scared guard, any direction; bit 3 of the counter picks the frame |
| $7F07 | [BellSprites](../src/sprite_gfx.asm#L139) | 4 | bell swinging; frames 0,1,2,3,3,2,1,0 from bits 3-5 of [BellTick](../src/variables.asm#L292) |
| $7F87 | [BlankSprite](../src/sprite_gfx.asm#L162) | 1 | 32 zero bytes, drawn with $3E to erase |

The sprite for direction d is at `base + 32 * d`; the code multiplies by 32
with five `RLC A` ([DrawHorace_Sprite](../src/events.asm#L352), [DrawGuard](../src/sprites.asm#L273)).

## Title block bitmaps

The words HUNGRY ([TitleHungry](../src/title_gfx.asm#L14), $6E8F) and HORACE ([TitleHorace](../src/title_gfx.asm#L39), $6F2F)
are 160 bytes each: 32 x 5 character cells, one byte per cell, row by row.
Each byte encodes the cell as a 2x2 grid of 4x4-pixel blocks:

| Bit | Block |
| --- | --- |
| 4 | top-left |
| 5 | top-right |
| 0 | bottom-left |
| 1 | bottom-right |
| 2, 3, 6, 7 | unused |

So $33 is a full cell, $11 the left half, $22 the right half. Seen as blocks,
each word is a 64 x 10 grid. [DrawBlocks](../src/library.asm#L706) converts the top two bits into a
pixel byte ($F0, $0F or $FF) repeated over four pixel rows, then the bottom
two bits over the next four.

## Texts

Plain ASCII, terminated by $FF, printed with the ROM font by [PrintChar](../src/library.asm#L105):

| Address | Label | Text |
| --- | --- | --- |
| $6AA7 | [TitleText](../src/texts.asm#L11) | ` Copyright © 1982 Beam Software   PRESS ANY KEY TO START PLAY  ` (63 characters over rows 22-23; © is character $7F) |
| $6AE7 | [DemoText](../src/texts.asm#L26) | `DEMO MODE  PRESS ANY KEY TO PLAY` (row 0) |
| $7C47 | [StatusText](../src/variables.asm#L10) | `PASSES   SCORE       BEST` (row 0) |

On the status line the passes digit goes to column 7, the five score digits
to columns 15-19 and the five best-score digits to columns 26-30.
