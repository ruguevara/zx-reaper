# 5.3 Rooms and exits

A room is a 256-byte record: a 2-bit layout of 512 cells, six tiles, a
conveyor, a ramp, an item picture, four exits and eight entity slots
([format](02-data.md#room-record)). Entering a room expands the record into
an attribute buffer and a bitmap buffer that hold the room without anything
that moves; every pass copies these into the work buffers. Exits are room
numbers at the edges, and they do not form a flat map everywhere.

## Building the buffers

[EnterRoom](../src/title.asm#L285) calls [BuildRoomBuffers](../src/roombuild.asm#L31) ($8D33), which first calls
[ExpandRoomLayout](../src/roombuild.asm#L85) ($8D6B):

1. Each of the 128 layout bytes holds four cells, first cell in bits 7-6.
   [StoreCellAttr](../src/roombuild.asm#L152) turns a cell value 0-3 into the attribute byte of that
   tile (offset $A0 + 9 * value) and stores it in the attribute buffer at
   $5E00.
2. If the conveyor length is not 0, that many cells from the conveyor
   address get the conveyor tile's attribute.
3. If the ramp length is not 0, that many cells from the ramp address get
   the ramp tile's attribute, each one row up and one column left (direction
   0, step -33) or right (direction 1, step -31).

Then [BuildRoomBuffers](../src/roombuild.asm#L31) fills the bitmap at $7000 cell by cell. It does not
know the tile numbers any more; it searches the 54 bytes of the tile area
with `CPIR` for the cell's attribute byte and copies the 8 bytes after the
first match, row k of cell n to `base + n + 256 * k` (the screen layout of
one third). The two halves of the room use bases $70 and $78, which the
routine writes into the operand of `LD D,n` at [SmcPixelBufPage](../src/roombuild.asm#L50) before
each half (self-modifying code).

```asm
BuildRoomBuffers_Cell:
  LD E,C                  ; E = cell index in this half
  LD A,(IX+$00)           ; the cell's attribute
  LD HL,RoomTiles
  LD BC,TILE_COUNT*TILE_SIZE
  CPIR                    ; HL = one past the first byte equal to A
  LD C,E
  LD B,CELL_HEIGHT
SmcPixelBufPage:
  LD D,$00                ; $70 or $78, written by this routine
```

Matching by value finds the right tile only if no earlier byte of the tile
area (an attribute or a pixel row of an earlier tile) equals the attribute.
In rooms 24, 29, 36, 49 and 51 a used tile fails this and is drawn with
other bytes; this was reproduced in the simulator for rooms 24, 29 and 49
(F30, F40; [Tricks](06-tricks.md#tiles-found-by-colour)). A Python model of
the whole build gives the same $5E00-$7FFF as the game (F39).

## Conveyor animation

[AnimateConveyor](../src/exits.asm#L119) runs every pass. It turns the conveyor address into the
address of the first belt cell in the master bitmap ($70xx or $78xx), takes
pixel row 0 and pixel row 2 of that first cell, rotates them two bits in
opposite directions (direction 0: row 0 left, row 2 right) and writes the
results into rows 0 and 2 of every belt cell. The change accumulates in the
master copy, so the pattern moves by two pixels per pass. All belt cells are
made equal to the first one; the other six rows are not touched (F22).

## Exits

| Routine | Trigger | New position |
| --- | --- | --- |
| [ExitRoomLeft](../src/exits.asm#L11) | a step left from column 0 | column 30, same row and Y |
| [ExitRoomRight](../src/exits.asm#L30) | a step right from column 30 | column 0, same row and Y |
| [ExitRoomUp](../src/exits.asm#L50) | Y wrapped to $F0 or more in a jump, or $E1 or more at the check in [FrameLoop](../src/mainloop.asm#L98), or climbing past the top of a rope | row 13, Y $D0, air state 0, same column |
| [ExitRoomDown](../src/exits.asm#L79) | the cells under his feet are below row 15 | row 0, Y 0, same column; air state 2 unless it was $0B or more |

Each sets [CurrentRoom](../src/variables.asm#L10) from the exit byte, adjusts [WillyAttrAddr](../src/variables.asm#L328) and
[WillyY](../src/variables.asm#L243), pops its caller's return address and jumps to [EnterRoom](../src/title.asm#L285)
(observed for all four, F21, F27). Willy keeps his move state, frame and
jump step, so a walk or a jump continues across the edge. Because
[EnterRoom](../src/title.asm#L285) saves this state, a death in the new room returns him to the
point where he came in, in the same motion; for a fall that is already
deadly this repeats until the game is over (observed, F120,
[Tricks](06-tricks.md#a-deadly-fall-repeats)).

Exit bytes are used whole as room numbers; the page is `$C0 OR number`, so
only the low 6 bits count (F36). An exit of 0 leads to room 0. Edges with
no way out usually hold 0 or the room's own number.

## The room map

![All 61 rooms placed by their exits](img/room-map.png)

The map places each room next to the neighbours whose exit bytes point back
at it ([`scripts/docs-roommap.py`](../scripts/docs-roommap.py); each room is
the game's own picture, shrunk to half size). A walk over these two-way
links from the Bathroom places 56 rooms on a grid; the links below do not
fit a flat plan, and five rooms (6, 16, 17, 47, 50) were placed by hand:

- **The roof row.** "On top of the house" (44), "Rescue Esmerelda" (14),
  "I'm sure I've seen this before.." (15), "We must perform a Quirkafleeg"
  (16), "Up on the Battlements" (17), "On the Roof" (18) and "Nomen Luni"
  (48) form one row of seven rooms joined left-right, but 14 sits above 39
  (14 down = 39, 39 up = 14) while 48 sits above 42 (48 down = 42, 42 up =
  48): the six rooms from 48 to 14 stand on the four rooms from 42 to 39.
  On the map the row is aligned at 14, and the
  48-42 link is not drawn as adjacent. "Watch Tower" (50) is above 16.
- **The bottom row.** "The Forgotten Abbey" (19) and "The Wine Cellar" (49)
  point at each other (19 left = 49, 49 right = 19) but lie at the two ends
  of the row of rooms under the house.
- **One-way exits.** 4 up, 5 down and 45 left lead to "Entrance to Hades"
  (6), whose own left and right exits lead to 14 and 5; 33 up = 39, 34 up =
  40, 35 up = 41, 40 up = 16, 38 up = 60, 44 down = 38, 14 up = 20, 25 up =
  31, 7 down = 2, 9 down = 4, 13 left = 10, 35 down = 29, 41 down = 34, 46
  up = 3. On the map 6 is drawn below 5.
- **Room 47.** Its name is "[", it is empty, and its exits are 29, 205 (=
  room 13 after the masking), 28 and 43. It is entered only through the
  right edge of "Tree Root" (46), which is walled (F35).
- **Rooms 61-63.** The last three pages of the room table are not rooms:
  their bytes are Z80 code, no exit leads to them, and their exit fields are
  not room numbers (F41). Only the teleport cheat reaches them (F106).

## Room list

Exit numbers in bold point back at the room itself. Items: the number of
items in the room (F15).

| # | Name | Left | Right | Up | Down | Items |
| --- | --- | --- | --- | --- | --- | --- |
| 0 | [The Off Licence](../src/rooms.asm#L98) | 1 | **0** | **0** | **0** | 12 |
| 1 | [The Bridge](../src/rooms.asm#L190) | 2 | 0 | 0 | 0 |  |
| 2 | [Under the MegaTree](../src/rooms.asm#L280) | 3 | 1 | 0 | 0 | 1 |
| 3 | [At the Foot of the MegaTree](../src/rooms.asm#L374) | 4 | 2 | 8 | 0 | 3 |
| 4 | [The Drive](../src/rooms.asm#L467) | 5 | 3 | 6 | 45 |  |
| 5 | [The Security Guard](../src/rooms.asm#L557) | 19 | 4 | 10 | 6 |  |
| 6 | [Entrance to Hades](../src/rooms.asm#L650) | 14 | 5 | 0 | 0 |  |
| 7 | [Cuckoo's Nest](../src/rooms.asm#L742) | 8 | 0 | 0 | 2 | 1 |
| 8 | [Inside the MegaTrunk](../src/rooms.asm#L832) | 9 | 7 | 12 | 3 |  |
| 9 | [On a Branch Over the Drive](../src/rooms.asm#L922) | 10 | 8 | 13 | 4 | 1 |
| 10 | [The Front Door](../src/rooms.asm#L1007) | 11 | 9 | 0 | 5 | 1 |
| 11 | [The Hall](../src/rooms.asm#L1099) | 20 | 10 | 0 | 0 |  |
| 12 | [Tree Top](../src/rooms.asm#L1190) | 13 | 0 | 0 | 8 | 3 |
| 13 | [Out on a limb](../src/rooms.asm#L1280) | 10 | 12 | 0 | 9 | 2 |
| 14 | [Rescue Esmerelda](../src/rooms.asm#L1372) | 15 | 44 | 20 | 39 | 2 |
| 15 | [I'm sure I've seen this before..](../src/rooms.asm#L1460) | 16 | 14 | 0 | 0 | 1 |
| 16 | [We must perform a Quirkafleeg](../src/rooms.asm#L1549) | 17 | 15 | 50 | 0 | 1 |
| 17 | [Up on the Battlements](../src/rooms.asm#L1639) | 18 | 16 | 0 | 0 | 1 |
| 18 | [On the Roof](../src/rooms.asm#L1727) | 48 | 17 | **18** | 0 | 1 |
| 19 | [The Forgotten Abbey](../src/rooms.asm#L1818) | 49 | 5 | 0 | 0 | 1 |
| 20 | [Ballroom East](../src/rooms.asm#L1907) | 21 | 11 | 26 | 0 |  |
| 21 | [Ballroom West](../src/rooms.asm#L2000) | 22 | 20 | 27 | 0 | 7 |
| 22 | [To the Kitchens Main Stairway](../src/rooms.asm#L2092) | 23 | 21 | 28 | 0 | 2 |
| 23 | [The Kitchen](../src/rooms.asm#L2181) | 24 | 22 | 0 | 0 |  |
| 24 | [West of Kitchen](../src/rooms.asm#L2276) | 25 | 23 | 30 | 0 |  |
| 25 | [Cold Store](../src/rooms.asm#L2369) | 52 | 24 | 31 | 0 | 4 |
| 26 | [East Wall Base](../src/rooms.asm#L2459) | 27 | 0 | 32 | 20 |  |
| 27 | [The Chapel](../src/rooms.asm#L2553) | 28 | 26 | 33 | 21 | 1 |
| 28 | [First Landing](../src/rooms.asm#L2642) | 29 | 27 | 34 | 22 | 1 |
| 29 | [The Nightmare Room](../src/rooms.asm#L2737) | 30 | 28 | 0 | 0 | 1 |
| 30 | [The Banyan Tree](../src/rooms.asm#L2827) | 31 | 29 | 36 | 24 | 1 |
| 31 | [Swimming Pool](../src/rooms.asm#L2916) | 54 | 30 | 37 | 0 | 1 |
| 32 | [Halfway up the East Wall](../src/rooms.asm#L3007) | 33 | 0 | 38 | 26 |  |
| 33 | [The Bathroom](../src/rooms.asm#L3100) | 34 | 32 | 39 | 27 | 1 |
| 34 | [Top Landing](../src/rooms.asm#L3190) | 35 | 33 | 40 | 28 | 1 |
| 35 | [Master Bedroom](../src/rooms.asm#L3282) | 36 | 34 | 41 | 29 |  |
| 36 | [A bit of tree](../src/rooms.asm#L3374) | 37 | 35 | 42 | 30 |  |
| 37 | [Orangery](../src/rooms.asm#L3465) | 56 | 36 | 43 | 31 | 3 |
| 38 | [Priests' Hole](../src/rooms.asm#L3553) | 39 | 0 | 60 | 32 | 1 |
| 39 | [Emergency Generator](../src/rooms.asm#L3644) | 40 | 38 | 14 | 0 |  |
| 40 | [Dr Jones will never believe this](../src/rooms.asm#L3731) | 41 | 39 | 16 | 0 | 1 |
| 41 | [The Attic](../src/rooms.asm#L3824) | 42 | 40 | 0 | 34 |  |
| 42 | [Under the Roof](../src/rooms.asm#L3915) | 43 | 41 | 48 | 36 |  |
| 43 | [Conservatory Roof](../src/rooms.asm#L4003) | 0 | 42 | 0 | 37 | 4 |
| 44 | [On top of the house](../src/rooms.asm#L4092) | 14 | 0 | 0 | 38 | 1 |
| 45 | [Under the Drive](../src/rooms.asm#L4187) | 6 | 46 | 4 | 0 |  |
| 46 | [Tree Root](../src/rooms.asm#L4279) | 45 | 47 | 3 | 0 | 2 |
| 47 | [\[](../src/rooms.asm#L4369) | 29 | 205 | 28 | 43 |  |
| 48 | [Nomen Luni](../src/rooms.asm#L4444) | 0 | 18 | 0 | 42 |  |
| 49 | [The Wine Cellar](../src/rooms.asm#L4540) | 51 | 19 | 52 | 0 | 6 |
| 50 | [Watch Tower](../src/rooms.asm#L4629) | 0 | 0 | 0 | 16 | 4 |
| 51 | [Tool Shed](../src/rooms.asm#L4719) | 58 | 49 | 53 | 0 | 1 |
| 52 | [Back Stairway](../src/rooms.asm#L4807) | 53 | 25 | 54 | 49 |  |
| 53 | [Back Door](../src/rooms.asm#L4898) | 0 | 52 | 55 | 51 |  |
| 54 | [West Wing](../src/rooms.asm#L4987) | 55 | 31 | 56 | 52 |  |
| 55 | [West Bedroom](../src/rooms.asm#L5077) | 0 | 54 | 57 | 53 |  |
| 56 | [West Wing Roof](../src/rooms.asm#L5169) | 57 | 37 | 0 | 54 | 4 |
| 57 | [Above the West Bedroom](../src/rooms.asm#L5257) | 0 | 56 | 0 | 55 | 1 |
| 58 | [The Beach](../src/rooms.asm#L5345) | 59 | 51 | **58** | 0 | 2 |
| 59 | [The Yacht](../src/rooms.asm#L5431) | 60 | 58 | 0 | 0 | 1 |
| 60 | [The Bow](../src/rooms.asm#L5519) | 0 | 59 | 0 | 0 | 1 |

The figures in each room's header comment in
[`src/rooms.asm`](../src/rooms.asm) (border, conveyor, ramp, items, exits,
entities) were produced from the same bytes.
