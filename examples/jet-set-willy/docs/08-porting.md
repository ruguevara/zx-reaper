# 8. Porting notes

A port to C or Python on a Spectrum-like platform library (a 256x192
bitmap with 32x24 attribute cells, a beeper, a keyboard matrix) can keep
the game's data as it is and translate the routines one by one. This
section lists what touches hardware, what depends on timing, which data
formats and memory layouts the code relies on, and where the program's
control flow does not map onto ordinary functions.

## Hardware touch points

| Hardware | Routines | Replace with |
| --- | --- | --- |
| screen bitmap $4000 (direct) | [RunCodeCheck](../src/protection.asm#L15), [AskColourCode](../src/protection.asm#L63), [ShowTitleScreen](../src/title.asm#L86), [ScrollTitleMessage](../src/title.asm#L217), [EnterRoom](../src/title.asm#L285) (bottom third), [DrawLives](../src/mainloop.asm#L18), [PrintText](../src/output.asm#L89), [ShowGameOver](../src/mainloop.asm#L506), [ShowAttrMap](../src/output.asm#L264) | drawing into the platform bitmap |
| screen bitmap via buffer | [FrameLoop_Present](../src/mainloop.asm#L126) copies $6000 → $4000 (4096 bytes) | present the work bitmap |
| attributes $5800 (direct) | [RunCodeCheck](../src/protection.asm#L15), [AskColourCode](../src/protection.asm#L63), [ReadCodeSlot](../src/protection.asm#L153), [ShowTitleScreen](../src/title.asm#L86), [ScrollTitleMessage](../src/title.asm#L217), [StartGame](../src/title.asm#L259), [CycleColours](../src/mainloop.asm#L250), [ResumeAfterPause](../src/mainloop.asm#L326), [PlayDeath](../src/mainloop.asm#L456), [ShowGameOver](../src/mainloop.asm#L506) | platform attributes |
| attributes via buffer | [FrameLoop_Attrs](../src/mainloop.asm#L151) copies $5C00 → $5800 (512 bytes) | present the work attributes |
| border (port $FE bits 0-2) | [EnterRoom](../src/title.asm#L285), [CycleColours](../src/mainloop.asm#L250), [ResumeAfterPause](../src/mainloop.asm#L326); every sound routine rewrites it with the room's border colour (black for the tunes and the death) | a border colour call |
| beeper (port $FE bits 3-4) | [PlayTune](../src/output.asm#L154), [PlayGameTune](../src/mainloop.asm#L352), [PlaySweepSound](../src/output.asm#L230), [MoveWilly](../src/willy.asm#L78) (jump and fall clicks), [UpdateItems](../src/items.asm#L33), [DrawEntities](../src/entities.asm#L245) (arrow chirp), [PlayDeath](../src/mainloop.asm#L456), [ShowGameOver](../src/mainloop.asm#L506) | square waves of the given half-periods (see below) |
| keyboard (port $FE in) | [ReadCodeSlot](../src/protection.asm#L153) (&#36;F7FE, $BFFE), [ReadStartInput](../src/output.asm#L196) and [ScrollTitleMessage](../src/title.asm#L217) (&#36;AFFE), [ReadWillyInput](../src/willy.asm#L255) (&#36;DFFE, $FBFE, $E7FE, $EFFE, $7EFE), [FrameLoop_Keys](../src/mainloop.asm#L200) (&#36;FEFE, $7FFE, $FDFE, high byte $02), [CheckDeath](../src/mainloop.asm#L334) (&#36;BFFE), [CheckTeleport](../src/mainloop.asm#L388) (&#36;EFFE, $F7FE), [CheckCheatKeys](../src/mainloop.asm#L407) (&#36;FBFE, $DFFE), [ShowAttrMap](../src/output.asm#L264) (&#36;FEFE) | a key-matrix read returning active-low bits |
| Kempston (port $1F) | [ShowTitleScreen](../src/title.asm#L86) (detection), [ReadStartInput](../src/output.asm#L196), [ReadWillyInput](../src/willy.asm#L255) | joystick state; detection can be replaced by a setting |
| ROM font $3D00 | [PrintChar](../src/output.asm#L114) | a copy of the 96 ROM glyphs (768 bytes) |
| FRAMES $5C78 | [AskColourCode](../src/protection.asm#L63) reads and writes it | any seed; the code needs only a cell number |
| reset (`JP $0000`) | [RunCodeCheck](../src/protection.asm#L15), [ShowAttrMap](../src/output.asm#L264) | quit the program |
| interrupts | [StartProgram](../src/start.asm#L16): `DI`, never enabled | nothing |

Some reads combine half rows: $AFFE reads 6-0 and H-ENTER together (bit 0
= 0 or ENTER), $E7FE reads 1-5 and 6-0 (bit 4 = 5 or 6), $7EFE the two
bottom rows, high byte $02 every row but A-G. A port must OR the key states
of the selected rows as the ULA does.

## Timing

The game has no timer. One pass of [FrameLoop](../src/mainloop.asm#L98) takes about 261,800 T
states with the tune on, 230,800 with it off (13.4 or 15.2 passes per
second, F93), and every game speed follows from it: walking 1 cell per 4
passes, a game minute 256 passes. A port should run passes at a fixed rate
(13-15 per second) instead of as fast as possible; how fast the original
runs depends on the room (more entities, an arrow chirp, a jump click all
add time).

The sounds are busy-wait loops that stop the game while they play. Their
lengths are part of the timing: the tune blip about 31,000 T every pass,
the arrow chirp about 111,500 T, the death scene about 415,600 T, the
game-over scene about 184 frames. A port that plays sound asynchronously
should add the same pauses where the original blocks (the death scene, the
game over, the title tune). The pitch formulas:

| Sound | Half-period |
| --- | --- |
| tune notes | note byte E: about 40 * E + 6 T (first half; doubled for the second half of title notes) |
| in-game tune | (note + 28 - 4 * lives) loop passes of about 40 T; 768 port writes per blip |
| arrow chirp | 1697 T falling to 72 T in 13 T steps, 128 toggles |
| death round n (n = 0..7) | 124 + 104 n T, 232 - 32 n toggles |

## Data formats used as they are

All formats are in [Data structures](02-data.md). A port can load the
32 KB block $8000-&#36;FFFF and use these offsets:

| Data | Address | Record |
| --- | --- | --- |
| rooms | $C000 + 256 * N | 256 bytes, layout + tiles + fields + slots |
| entity definitions | $A000 + 8 * I | 8 bytes |
| items | $A400 + i, $A500 + i, i = $AD-&#36;FF | 2 bytes |
| sprites | page * 256 + 32 * frame | 32 bytes, 16 rows of 2 |
| Willy | $9D00 + $80 * facing + $20 * frame | |
| row table | $8200 | can be computed |
| rope table | $8300 | 256 bytes, needed as data |
| move table | $8421 | 16 bytes |
| tunes | $85FB, $865F | |
| title and status attributes | $9800, $9A00 | |
| code screen | $9B00, $9B80, $9E00 | |
| texts | $8454-$85CA | ASCII, fixed length |

## Behaviour that depends on memory layout

These are bugs or quirks of the original that come from where things are in
memory. A port that wants the same behaviour must keep them; a port with
separate arrays will lose them silently.

- The work bitmap is in screen layout and the row table maps Y index to an
  address. The Attic arrow's odd Y index reads the table half a word off and
  writes into $9Fxx and the entity definitions (F92, F121). Reproducing it
  needs the row table as bytes and a flat 64 KB memory.
- Entity definition byte +2 is overwritten at every room entry (F25), and
  the definitions persist across games.
- The rope writes into the next entity entry (F90).
- The damaged guardian of F121 is "drawn" at $006F in ROM, and the
  collision test reads ROM bytes there. A port without ROM contents gets a
  different result.
- [BuildRoomBuffers](../src/roombuild.asm#L31) finds tile pixels by searching the tile bytes for the
  attribute; rooms 24, 29, 36, 49, 51 depend on the search (F40).
- Teleporting to rooms 61-63 uses code bytes as room data (F41).
- [ScratchByte](../src/variables.asm#L501) is shared by the code check, the title scroll and the
  game over (F13).

## Control flow

- [FrameLoop](../src/mainloop.asm#L98) is entered by `JP` with an empty stack and never returns.
  Model it as a loop whose body can end early with one of four results:
  room change, death, quit, game over.
- [KillWilly](../src/willy.asm#L577) and the exits pop return addresses and jump. In a port they
  become a flag or an exception that ends the current pass: after a kill the
  pass continues at the screen copy ([FrameLoop_Present](../src/mainloop.asm#L126)), after an exit at
  [EnterRoom](../src/title.asm#L285).
- [ReadCodeSlot](../src/protection.asm#L153) returns two levels up (it pops its return address).
- [NewGame](../src/title.asm#L30), [ShowTitleScreen](../src/title.asm#L86), [ScrollTitleMessage](../src/title.asm#L217), [StartGame](../src/title.asm#L259)
  and [EnterRoom](../src/title.asm#L285) fall through into each other; [ResumeAfterPause](../src/mainloop.asm#L326),
  [CheckDeath](../src/mainloop.asm#L334), [PlayGameTune](../src/mainloop.asm#L352), [CheckTeleport](../src/mainloop.asm#L388), [CheckCheatKeys](../src/mainloop.asm#L407),
  [PlayDeath](../src/mainloop.asm#L456), [RestartAfterDeath](../src/mainloop.asm#L493) and [ShowGameOver](../src/mainloop.asm#L506) likewise.
- [MoveWilly](../src/willy.asm#L78) is one routine with many entry points reached by `JP`
  ([MoveWilly_Ground](../src/willy.asm#L134), [MoveWilly_Air](../src/willy.asm#L158), [ReadWillyInput](../src/willy.asm#L255),
  [WalkWilly](../src/willy.asm#L397)); its flowchart is in [Willy](05-willy.md#order-of-work-in-a-pass).
- [SmcPixelBufPage](../src/roombuild.asm#L50) is self-modified; a port passes the base as a
  parameter.

## Entry points

| Address | Name | Entered from |
| --- | --- | --- |
| $8400 | [StartProgram](../src/start.asm#L16) | the BASIC loader (`RANDOMIZE USR 33792`) |
| $869F | [RunCodeCheck](../src/protection.asm#L15) | the planted return address |
| $87CA | [NewGame](../src/title.asm#L30) | code accepted, clock end, quit, end of game over |
| $8813 | [ShowTitleScreen](../src/title.asm#L86) | end of the title scroll |
| $88FC | [StartGame](../src/title.asm#L259) | a start key on the title screen |
| $8912 | [EnterRoom](../src/title.asm#L285) | exits, teleport, restart after a death, start of a game |
| $89AD | [FrameLoop](../src/mainloop.asm#L98) | [EnterRoom](../src/title.asm#L285) and the end of each pass |

A useful order for a port is the same as for checking it: room building
(compare $5E00-$7FFF with the original for all 61 rooms), then
[MoveEntities](../src/entities.asm#L42) (pure memory, checked by a model on 3000 random buffers,
F81), then Willy's movement against the harness logs of F109-F118, then
drawing and the frame loop, then sound. The input scripts in
[`tests/inputs/`](../tests/inputs) with their recorded frame hashes in
`tests/expected/` give whole-game regression runs.
