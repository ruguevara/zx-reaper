# Hungry Horace (ZX Spectrum, 1982): how it works

![Hungry Horace in play](img/game.png)

Hungry Horace was published by Psion with Melbourne House in 1982 and
written by Beam Software. It is an 8 KB maze game: Horace eats flowers,
guards chase him, a bell makes the guards edible for a while, and the exit
arrows lead through a cycle of four mazes that gets faster every round. This
article explains the program top-down from a full disassembly whose sources
in [`src/`](../src) rebuild the original tape byte for byte.

The whole game is one loop of twelve calls with interrupts disabled and a
busy-wait delay for pacing. Positions are kept as display-file offsets, the
screen's attribute bytes double as the collision map (walls, flowers, guards
and the bell are recognised by colour), the random numbers are bytes read
from the ROM, and each guard carries a copy of the screen under it, which is
also how bonus fruit appears. The article covers the loader, all data
formats, every routine of the main loop, the original bugs (including a stack
leak in the demo and a delay underflow that stalls the game at high speed),
a gallery of all graphics and mazes rendered by the game's own code, and
notes for porting to C or Python.

## Contents

1. [Overview](01-overview.md): the game, the hardware it uses, memory map,
   the two-stage BASIC loader
2. [Data structures](02-data.md): positions, attributes as object types,
   variables, guard record, maze descriptor, maze map, sprites, title blocks,
   texts
3. [Title screen and demo](03-title-and-menu.md): block-letter title, colour
   loop, start of a game, demo mode and its autopilot
4. [The main loop](04-game-loop.md): outer control flow, the twelve calls of
   one pass, timing and speed
5. Subsystems
   - [Horace: controls and movement](05-horace.md): keys, the move probe,
     wrap pads, the exit, drawing
   - [Guards: records, release timers and AI](05-guards.md): the record
     buffer, release timers, direction scoring, scared guards, eaten guards
   - [Bell, fruit, scoring and extra passes](05-bell-fruit-score.md)
   - [Guard contact, death and game over](05-death.md)
   - [Drawing and screen layout](05-drawing.md): display-file arithmetic,
     sprites and saved backgrounds, the attribute collision map
   - [Sound](05-sound.md): beeper effects, the sound mask, the ROM chime
6. [Tricks, dead code and bugs](06-tricks.md)
7. [Graphics gallery](07-graphics.md): loading screen, title, sprites,
   fruit, tiles, the four mazes, screens in play
8. [Porting notes](08-porting.md): hardware touch points, timing, ROM
   routines and data, memory dependencies, entry points

## Sources

| File | Contents |
| --- | --- |
| [`src/game.asm`](../src/game.asm) | top file, includes the 13 modules in address order |
| [`src/main.asm`](../src/main.asm) | entry point, title, demo start, maze set-up, main loop |
| [`src/movement.asm`](../src/movement.asm) | controls, autopilot, move planning, guard AI |
| [`src/sprites.asm`](../src/sprites.asm) | erasing and drawing guards, eating, score display |
| [`src/events.asm`](../src/events.asm) | guard contact, death, game over, Horace, bell, fruit, timers, sound key, pacing |
| [`src/guards.asm`](../src/guards.asm) | guard timers and records, rising tone, maze descriptor |
| [`src/texts.asm`](../src/texts.asm) | title and demo texts, title variables |
| [`src/library.asm`](../src/library.asm) | delay, random numbers, printing, drawing, collision probes |
| [`src/state.asm`](../src/state.asm) | guard timers, AI scratch, guard records |
| [`src/title_gfx.asm`](../src/title_gfx.asm) | title block bitmaps |
| [`src/mazes.asm`](../src/mazes.asm) | maze descriptors and maps |
| [`src/tiles.asm`](../src/tiles.asm) | maze tiles |
| [`src/variables.asm`](../src/variables.asm) | status text, game variables, fruit graphics |
| [`src/sprite_gfx.asm`](../src/sprite_gfx.asm) | sprites |
| [`src/constants.asm`](../src/constants.asm) | named constants |
| [`src/loader03.bas`](../src/loader03.bas), [`src/loader05.bas`](../src/loader05.bas) | the two BASIC loaders |
| [`re/notes.md`](../re/notes.md) | working notes of the disassembly |

Links in this article point at labels in these files (`../src/file.asm#Lnn`).
Statements are taken from the annotated sources or checked by running the
game in the project's simulator (`tools/zxrun.py`); where something is
inferred rather than observed, the text says so.
