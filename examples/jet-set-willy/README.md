# Jet Set Willy — reverse-engineered sources

Jet Set Willy (Matthew Smith, Software Projects, 1984) for the 48K ZX Spectrum,
taken through every stage of [ZX-REAPER](../../README.md) as a test of the
harness on a game with a published reference disassembly (SkoolKit, skoolkit.ca).
The sources build a tape byte-identical to the original `JETSET.TAP`
(World of Spectrum, "JetSetWilly(original).tap").

The tape is not in git. Put it into `original/game.tap`, then:

```sh
make restore     # re/tape/, re/orig.z80, re/image.z80 from the tape
make             # must print IDENTICAL
make test        # replays tests/inputs/*.txt against recorded frame hashes
make shift-test  # code assembled at +$100 plays the same, frame by frame
```

Tools: sjasmplus, Python 3 with SkoolKit 10.1 (`pip install -r ../../requirements.txt`), make.

## What is where

| Path | What |
| --- | --- |
| `src/game.asm` | includes the modules below in address order |
| `src/constants.asm` | named numbers (colours, ports, keys, sizes, game values) |
| `src/loader.bas` | the BASIC loader, lossless text |
| `re/notes.md` | memory map, room format, loader and protection, coverage, relocation limits |
| `re/questions.md`, `re/findings.md` | what the work had to answer; 118 claims with evidence |
| `re/skool/` | the annotated SkoolKit disassembly before export (history) |
| `tests/inputs/` | input scripts: code, title, start, pause, play (40,000 frames of seeded random play) |

| Module | Range | Contents |
| --- | --- | --- |
| buffers | $8000 | room buffer, entity buffer, pixel-row address table, rope table |
| start | $8400 | program entry and the fake decryption loop |
| variables | $8420 | current room, movement table, texts, game variables, cheat keys, tunes |
| protection | $869F | colour-code check |
| title | $87CA | new game, title screen, scroller, start game, enter room |
| mainloop | $898B | lives, frame loop, colour cycling, pause, tune, cheat, death, game over |
| roombuild | $8D33 | room attribute and pixel buffers from the layout |
| willy | $8DD3 | Willy: jump, fall, keys, walking, ramps, conveyors; kill |
| entities | $90C0 | guardians, arrows, ropes: movement, drawing, collisions |
| items | $93D1 | drawing and collecting items |
| sprite | $9456 | sprite drawing with collision test |
| exits | $948A | moving between rooms, conveyor animation |
| specialrooms | $9534 | Master Bedroom, the toilet, Willy's cells |
| output | $9637 | Willy drawing, text, tunes, sounds, leftover test code |
| screens | $9718 | title and status attributes, code-screen graphics |
| charsprites | $9C00 | leftover source text, game-over and figure sprites, Willy |
| codetable | $9E00 | colour-code table |
| entitydefs | $A000 | 128 entity definitions |
| itemtable | $A3FF | 83 items |
| sprites | $A600 | entity sprite pages |
| rooms | $C000 | 61 rooms and 3 stray pages |

## Changing common things

- Lives: `START_LIVES` in `src/constants.asm`; start room: `START_ROOM`.
- Game speed: there is no frame sync (no interrupts); the speed is the run time
  of one pass of `FrameLoop` (src/mainloop.asm), about 13 passes a second.
- Rooms: one 256-byte page each in `src/rooms.asm`, format in `re/notes.md`
  and the header of `RoomOffLicence`. Entities: `src/entitydefs.asm`.
- Relocation: `$8000-$9EFF` can move by $100 (see re/notes.md, Relocation);
  `$A000-$FFFF` is found by page arithmetic and must stay where it is.

## Not explained

- Where the bytes of the colour-code table come from (F9), the leftover
  fragments at $93BB and $9C00, and why the start routine has a decryption loop
  that changes nothing.
- Room bytes $DF-$E0 and $ED-$EF are never read.
