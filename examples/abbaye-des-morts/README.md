# l'Abbaye des Morts — reverse-engineered sources

[l'Abbaye des Morts](https://zxart.ee/prod/189705) for the 48K ZX Spectrum
(DaRkHoRaCe and Jerri, 2014, freeware; after Locomalito's 2010 game), taken
through stages 1 and 2 of [ZX-REAPER](../../README.md) with no disassembly or
write-up of the game read during the work. The sources build a tape
byte-identical to the original (the release file on
[zxart.ee](https://zxart.ee/prod/189705), `AbbayeDesMorts.tzx.zip`,
`ABBAYE.TZX`): the loader, its packer and both packed tape blocks included.

The tape is not in git. Put it into `original/game.tzx`, then:

```sh
make restore             # re/tape/, re/orig.z80, re/image.z80 from the tape
make                     # must print IDENTICAL (the first build packs the game: ~3 minutes)
make expected            # frame hashes of the input scripts from the original
make test                # replays tests/inputs/*.txt against them
make shift-test          # $85BC-$BFFF assembled at +$100 plays the same, frame by frame
make shift-test SHIFT=0x101
scripts/shift-rooms.sh   # the same in every room, the ending and game over
```

The article on how the game works is in [`docs/`](docs/README.md).

Tools: sjasmplus, Python 3 with SkoolKit 10.1 (`pip install -r ../../requirements.txt`), make.

## What is where

| Path | What |
| --- | --- |
| `src/game.asm` | includes the game's modules below in address order |
| `src/constants.asm` | named numbers: colours, tiles, keys, states, sizes, speeds, sounds |
| `src/loader.bas` | BASIC line 10: `PRINT USR (VARS+3)` |
| `src/stage1.asm` | the BASIC variables: the string l$ holding the first loader stage and the packed second stage |
| `src/stage2.asm` | the second loader stage: machine check, the picture revealed cell by cell, the tape loader with the hourglass, the game unpacked |
| `src/megalz.asm` | the MegaLZ depacker (a macro, used twice) |
| `scripts/megalz.py` | MegaLZ decoder and an optimal packer that makes the tape's streams byte for byte |
| `scripts/block3.py`, `scripts/rules.mk` | tape blocks 2 and 3 from the sources and `data/` |
| `data/` | the three screens (loader picture, title, info) and the 128K music bank (not disassembled) |
| `scripts/coverage.sh` | coverage runs that need pokes: every room, the endings, Kempston |
| `scripts/docs-images.py` | the images of the article, from the game's bytes and runs |
| `re/notes.md` | the tape and the loader, the memory map, the structure of the game |
| `re/questions.md`, `re/findings.md` | what the work had to answer; the claims with evidence |
| `re/frag/` | the classification reports and the lead's list of cross-file fixes (history) |
| `re/skool/` | the annotated SkoolKit disassembly before export (history) |
| `tests/inputs/` | input scripts: title and menu, the RAGE cheat, the info screen, play, 8000 frames of random keys |

| Module | Range | Contents |
| --- | --- | --- |
| startup | $6000 | start-up (later the flag map), the main stack, the flag row table |
| font | $6130 | the proportional font: index and glyphs |
| graphics | $66DC | item sprites, the 20 packed sprite sets, the parchment frame |
| roomscripts | $7236 | the bytecode scripts that build the 26 rooms |
| cutscenelists | $83A8 | ending actors, the debug room warp, music per room |
| im2table | $8400 | the IM 2 vector table |
| variables | $8501 | game variables, the interrupt stack |
| interrupt | $8585 | the interrupt handler, 128K paging and music hooks |
| mainloop | $85FC | new game, the main loop, entering a room, beeper sound effects |
| sequences | $8832 | the intro, the ending, cutscenes, spawning objects and items |
| objects | $8A8F | object types, frame lists, room objects, room items |
| text | $9048 | the 53 strings: room names, parchments, intro, ending |
| behaviours | $93D3 | how each kind of creature looks and how large its hit box is |
| redraw | $95FF | the redraw list: changed cells to the screen |
| sprites | $9836 | sprite drawing with masks, the lives bar, room sweeps |
| hud | $9C1B | the crosses counter, parchments and text windows |
| script | $9D5F | the room script interpreter and its 32 opcodes, text |
| helpers | $A1C3 | waiting for keys, address arithmetic, the keyboard scan |
| controls | $A271 | keys and Kempston, the title and controls menus, the cheat |
| gameframe | $A596 | the game frame, the object slots, item actions, hit tests |
| player | $A894 | Jean: tile probes, walking, jumping, falling, crouching, dying, exits |
| effects | $AD88 | the water reflection, the bubbling blood, the ring of crosses |
| unpack | $AE9D | unpacking the sprite sets of a room into the sprite sheet |
| entities | $B028 | the creatures: crusaders, patrollers, hanged men, the chasing ghost, drops, archers, stone heads, plants, fish, the Beast, Death, Satan |
| templates | $BC92 | initial states of objects created during play |
| buffers | $BE56 | frame call list, sprite queue, object slots, redraw buffers |
| tiles | $CD00 | tile flags, attributes and bitmaps |
| spritesheet | $D700 | the sprite sheet: a page per pixel row |

## Changing common things

- Lives: `MAX_LIVES` in `src/constants.asm` (also the most hearts the status
  bar can show). Crosses needed for the chalice: `CROSSES_NEEDED`.
- Movement: `WALK_SPEED`, `JUMP_SPEED`, `GRAVITY` (8.8 fixed point, 2-pixel
  units per frame).
- Rooms: one bytecode script each in `src/roomscripts.asm` (the opcodes are
  listed in the header of `RunScript`, `src/script.asm`); the creatures of a
  room are records in `RoomObjects`, the items in `RoomItems`
  (`src/objects.asm`); the start of a game is the last record of
  `Checkpoints` (`src/templates.asm`).
- Texts: `src/text.asm`, a length byte and the characters of each string.
- Graphics: tiles in `src/tiles.asm`, item sprites and the packed sprite sets
  in `src/graphics.asm` (format in `re/notes.md`), the screens in `data/`.
- Relocation: `$85BC-$BFFF` moves (by up to $104 bytes); the rest stays where
  it is (see `re/layout.mk`). On a 48K only: the 128K music bank, kept as
  data, calls BuildMirrorTable and reads KeyRows at their fixed addresses.

## Not explained

- The 128K music bank (`data/music128.bin`, a Vortex Tracker II player and
  modules) is kept as data; the 128K paths of the code are read, not run.
