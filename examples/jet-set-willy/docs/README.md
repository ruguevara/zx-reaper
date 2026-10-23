# Jet Set Willy (ZX Spectrum, 1984): how it works

![Jet Set Willy in play: The Bathroom, where every game starts](img/game.png)

Jet Set Willy was written by Matthew Smith and published by Software Projects
in 1984 for the 48K ZX Spectrum. Willy walks and jumps through 61 rooms of a
house and its grounds, collecting 83 flashing items before the clock runs
out; the title message asks the player to collect them "before Midnight so
Maria will let you get to your bed". This article explains the program
top-down from a full disassembly whose sources in [`src/`](../src) rebuild the
original tape byte for byte.

The program is one frame loop with interrupts disabled. Every pass copies an
empty picture of the room from two buffers into two work buffers, draws
Willy, the guardians, the ropes, the arrows and the items into the work
buffers, and copies them to the screen. Collisions are found in the buffers:
attribute colours tell walls, floors, nasties, ramps and conveyors apart and
tell an item that Willy touches it, and a guardian kills Willy when its
pixels land on any lit pixel. Rooms are 256-byte records with a 2-bit layout,
six tiles and eight entity slots; entities are 8-byte records copied from a
table of 128 definitions. The article covers the loader and the colour-code
protection, every data format, every routine of the frame loop, the ending,
the WRITETYPER cheat, the bugs (including a stray arrow that overwrites the
guardian table and makes three rooms deadly for the rest of the session), a
gallery of every room, sprite and screen rendered by the game's own code,
and notes for porting.

## Contents

1. [Overview](01-overview.md): the game, the hardware it uses, the memory
   map, how it loads
2. [Data structures](02-data.md): variables, the room record, entity
   definitions and the entity buffer, the item table, sprites, tables, tunes
   and texts
3. [Title screen and start of a game](03-title-and-menu.md): the colour-code
   screen hand-over, the title picture, tune and scroller, new game, room
   entry
4. [The frame loop](04-game-loop.md): one pass step by step, the second half
   of the pass, timing and speed, the clock
5. Subsystems
   - [Willy](05-willy.md): input, move state, walking, jumping, falling,
     ramps, conveyors, walls, ropes, drawing
   - [Entities](05-entities.md): guardians, arrows and ropes: movement,
     drawing, collisions
   - [Rooms and exits](05-rooms.md): the room record, building the buffers,
     conveyor animation, exits, the room map
   - [Items and the ending](05-items-ending.md): the item table, collecting,
     the figure in the Master Bedroom, the run to the toilet
   - [Clock, lives, pause and tune toggle](05-clock-lives.md)
   - [Death and game over](05-death.md)
   - [Sound](05-sound.md): tunes, clicks, chirps and sweeps on the beeper
   - [Screen drawing](05-drawing.md): the buffers, the row table, sprites,
     text, collision by pixels and by colour
   - [Colour-code protection and the WRITETYPER cheat](05-protection-cheat.md)
6. [Tricks, dead code and bugs](06-tricks.md)
7. [Graphics gallery](07-graphics.md): screens, sprites, item graphics,
   tiles, all 61 rooms and the room map
8. [Porting notes](08-porting.md): hardware touch points, timing, data
   formats, entry points

## Sources

| File | Contents |
| --- | --- |
| [`src/game.asm`](../src/game.asm) | top file: screen and system addresses, includes the 21 modules in address order |
| [`src/constants.asm`](../src/constants.asm) | named numbers (colours, ports, keys, sizes, game values) |
| [`src/buffers.asm`](../src/buffers.asm) | $8000: room buffer, entity buffer, pixel-row address table, rope table |
| [`src/start.asm`](../src/start.asm) | $8400: program entry and the loop that changes nothing |
| [`src/variables.asm`](../src/variables.asm) | $8420: current room, move table, texts, game variables, cheat keys, tunes |
| [`src/protection.asm`](../src/protection.asm) | $869F: colour-code check |
| [`src/title.asm`](../src/title.asm) | $87CA: new game, title screen, scroller, start of a game, room entry |
| [`src/mainloop.asm`](../src/mainloop.asm) | $898B: lives, frame loop, colour cycling, pause, tune, cheat, death, game over |
| [`src/roombuild.asm`](../src/roombuild.asm) | $8D33: room attribute and pixel buffers from the layout |
| [`src/willy.asm`](../src/willy.asm) | $8DD3: Willy's movement; the kill routine |
| [`src/entities.asm`](../src/entities.asm) | $90C0: guardians, arrows, ropes |
| [`src/items.asm`](../src/items.asm) | $93D1: drawing and collecting items |
| [`src/sprite.asm`](../src/sprite.asm) | $9456: sprite drawing with collision test |
| [`src/exits.asm`](../src/exits.asm) | $948A: room exits, conveyor animation |
| [`src/specialrooms.asm`](../src/specialrooms.asm) | $9534: Master Bedroom, toilet, placing and marking Willy |
| [`src/output.asm`](../src/output.asm) | $9637: drawing Willy, text, tunes, sounds, leftover test code |
| [`src/screens.asm`](../src/screens.asm) | $9718: title and status attributes, code-screen graphics |
| [`src/charsprites.asm`](../src/charsprites.asm) | $9C00: leftover source text, foot, barrel, figure and Willy sprites |
| [`src/codetable.asm`](../src/codetable.asm) | $9E00: colour-code table |
| [`src/entitydefs.asm`](../src/entitydefs.asm) | $A000: 128 entity definitions |
| [`src/itemtable.asm`](../src/itemtable.asm) | $A3FF: 83 items |
| [`src/sprites.asm`](../src/sprites.asm) | $A600: 26 sprite pages |
| [`src/rooms.asm`](../src/rooms.asm) | $C000: 61 rooms and 3 stray pages |
| [`src/loader.bas`](../src/loader.bas) | the BASIC loader |
| [`re/findings.md`](../re/findings.md) | 121 claims with status and evidence (F1-F121, cited in this article) |
| [`re/notes.md`](../re/notes.md) | memory map, room format, coverage, relocation |

Links in this article point at labels in these files (`../src/file.asm#Lnn`).
Statements come from the annotated sources, from the finding register or
from runs of the game in the project's simulator (`tools/zxrun.py`). A
statement marked **observed** was seen in such a run; **inferred** means read
from the code and not run. Finding numbers (F1-F121) point into
[`re/findings.md`](../re/findings.md). Names are those of the sources; names
the game prints itself (room names, texts) are quoted as printed. Where the
sources say Unknown, so does the article.

Images in [`img/`](img) are made from the game's bytes by
[`img/Makefile`](img/Makefile) (`make -f docs/img/Makefile` from the project
root).
