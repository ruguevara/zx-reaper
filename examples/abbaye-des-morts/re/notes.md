# RE notes

Facts that are not yet in the skool/asm comments: memory map, loader stages,
open questions. Keep it short; move each fact into the source once its
routine or data block is annotated.

## Tape and loader

`original/game.tzx` (zxart.ee, AbbayeDesMorts.tzx.zip, `ABBAYE.TZX`, 35533
bytes): three standard-speed blocks.

| Block | What | Source |
| --- | --- | --- |
| 01 | header: program "l'Abbaye", 5689 bytes, LINE 10, program 40 bytes | `tape/tape.txt` |
| 02 | BASIC line 10 (`PRINT USR (VARS+3)`) and the variables: one string, l&#36;, of 5646 bytes holding Stage1 | `src/loader.bas`, `src/stage1.asm` |
| 03 | headerless, flag $FF, 29796 bytes loaded at $625E by the loader's copy of LD-BYTES | `scripts/block3.py` |

- Stage1 (in l&#36;, run at $5CF6): moves the packed stage 2 to the top of
  memory and unpacks it (MegaLZ) to $6000-$8AFF, then returns to $6000.
- Stage 2 (`src/stage2.asm`): machine check (48K / 128K by paging, then the
  fastest bank by timing), the picture at $7000 revealed cell by cell,
  LD-BYTES copied from the ROM to $FE00 and patched to draw an hourglass
  while loading, block 3 loaded at $625E, then (48K) the loading screen
  unpacked to the screen and the game unpacked from the top of memory to
  $6000 by a copy of the depacker at $5B00, which returns to $6000.
- Block 3 holds four MegaLZ streams: the loading screen ($625E, 2541 bytes,
  RCS order), the info screen ($6C4B, 1251 bytes, RCS order), the 128K music
  ($712E, 4811 bytes, 11631 unpacked, a Vortex Tracker II player and module
  that goes to a 128K bank; not disassembled) and the game ($83F9, 21193
  bytes, 40704 unpacked to $6000-&#36;FEFF).
- The packer: `scripts/megalz.py` is an optimal MegaLZ packer whose ties
  fall the way the original packer's did, so all five streams come out byte
  for byte (checked by `make`). The game stream takes about 2.5 minutes to
  pack; results are cached in `build/mlz-cache/` by content.
- Handover: `re/orig.z80` is the machine at the second pass through $6000
  (`TAP2SNA_OPTS` in `re/layout.mk`), the game unpacked, SP=$5FFE with the
  machine type on the stack (A=1 on 48K). `re/image.z80` is the same
  snapshot: the game is not changed between unpacking and its start.

## Memory map

Details and evidence: `re/frag/[ABCD]-report.md` (classification reports).

| Range | What | Status |
| --- | --- | --- |
| $5B00-$5DBF | room tile map, 22 rows x 32 tile numbers (&#36;A20D: row/column -> address) | buffer |
| $5DC0-$5DFF | object list (pointer at $BE56) | buffer |
| $5E00-$60BF | tile flag map, $CD00+tile for each cell (3 pages above the tile map); overwrites the start-up code $6000-$6072 | buffer |
| $6000-$6072 | start-up (run once) | code |
| $60C0-$60FF | main stack (SP=$6100) | stack |
| $6100-$612F | row address table, 24 words $5E00+32n, built at start-up | buffer |
| $6130-$66DB | proportional font: index of 96 words, glyphs 16 rows high | font |
| $66DC-$68CB | sprites 16 wide: door arch 16x24, 14 of 16x16 | gfx |
| $68CC-$717E | 20 packed sprite sets, unpacked per room into the sprite sheet | gfx packed |
| $717F-$7235 | parchment frame tiles and layout | gfx, layout |
| $7236-$83A7 | room scripts: addresses (26 words) and bytecode for the interpreter $9D5F | script |
| $83A8-$83FF | cutscene actor lists, debug room-warp routine (reached with the RAGE cheat), music track per room | data, code |
| $8400-$8500 | IM 2 vector table, 257 x $85 | table |
| $8501-$855E | game variables | vars |
| $855F-$8584 | interrupt stack | stack |
| $8585-$8A8E | interrupt handler, 128K paging and music, main loop, beeper effects, title, ending, spawning | code |
| $8A8F-$9047 | object types, frame lists, room objects (11 bytes), room items (8 bytes) | records |
| $9048-$93D2 | text: 53 length-prefixed strings | text |
| $93D3-$95FE | behaviour data for object kinds | records |
| $95FF-&#36;A595 | redraw, sprite drawing, parchments, script interpreter and opcodes, text, keys, menus | code |
| $A596-&#36;BE55 | game frame: player, items, room exits, sprite unpacking, entities | code |
| $BE56-&#36;BFFF | pointers, frame call list | vars, buffer |
| $C000-&#36;CCFF | sprite draw queue, object slots (11 x 22 bytes at $C100), redraw buffers | buffer |
| $CD00-&#36;D6FF | tile flags, tile attributes, tile bitmaps (256 x 8) | tables, gfx |
| $D700-&#36;FEFF | sprite sheet: a page per pixel row, 40 rows; columns $63-&#36;FF filled per room | gfx, buffer |
| $FF00-&#36;FFFF | outline mask table built at start-up | buffer |

## Game structure

- Entry $6000 (StartUp): pops the machine type (1 = 48K) into MachineType,
  patches the 128K hooks ($605F) on 128K, builds the flag row table and the
  outline mask table, probes the Kempston port, IM 2 with I=$84: the vector
  table $8400-$8500 points to $8585, the interrupt handler, which saves all
  registers and calls the routine in InterruptRoutine ($8504): the menu frame
  (&#36;A43D) or the game frame ($85E2: a sound step, then GameFrame $A596). The
  game logic runs once per interrupt; the foreground (MainLoop $8664) only
  draws (F103).
- Rooms: a 5x5 grid, 25 rooms, number in RoomNumber $8509 (right +1, left
  -1, down +5, up -5, wrapped modulo 25; rooms 0-4 are not reachable from
  below, F124). Room 0 is the intro, room 25 the first ending scene. Room
  state $850C, checked by the main loop: $80 playing, 1 enter the room, 2
  back to the arrival position, 3 the ending ($887B), 4 restart at the active
  checkpoint after a death, 5 game over (script $A57E); bit 7 keeps the
  frame routines running (F25).
- A room is built by its bytecode script (RoomScriptTable $7236, the
  interpreter RunScript $9D5F, 32 opcodes): tiles into the tile map $5B00,
  tile flags into the flag map $5E00; then RoomObjects and RoomItems spawn
  the creatures and items into 11 object slots of 22 bytes at $C100, each
  run by its handler word through RET (F34, F80).
- Keys: ControlKeys $A2BF (redefinable), ControlsRead/Held/Pressed
  $A2CF-&#36;A2D1; the Kempston read at $A290 is cut off by a RET at $A28F when
  no interface answers on port $1F (F35).

## Coverage

tests/inputs (title and menu, the RAGE cheat, the info screen, play, 8000
frames of random keys) and scripts/coverage.sh (each room entered by poking
$8509 and $850C, the ending, game over, the Kempston read) -> re/maps/: 89%
of the instructions executed. The rest: dead code (F130) and paths the
inputs did not take (F131): the 128K paths (the simulator is 48K), some
Kempston branches, the warp keys, rare branches.

## Relocation

The shift test moves $85BC-&#36;BFFF (SHIFT_START/SHIFT_END in re/layout.mk) and
passes at +$100 and +$101, on the input scripts and on every room entered
directly, the ending and game over (scripts/shift-rooms.sh). Fixed: the
start-up code (entered at $6000, under the flag map), FlagRowTable at $6100
and Im2Table at $8400 (read by page), the interrupt handler at $8585 (an IM
2 vector is two equal bytes), the font, the sprites and the room scripts
below; the buffers, the tile tables and the sprite sheet above (a page per
pixel row). The moved part can grow into the $FF fill at $BEFC-&#36;BFFF, $104
bytes. Records that hold an address in two bytes (item actions, crusader
templates in RoomObjects, cutscene actors) use `low`/`high` of the label.
On a 48K only: the 128K music bank (data/music128.bin, data) calls
BuildMirrorTable (&#36;BE48) and reads KeyRows (&#36;A2D4, $A2D9) at fixed addresses,
inside the moved part. F120 (one frame of the monk drawn from code bytes) makes room 22 with fuzz
seed 22 differ in the moved build; scripts/shift-rooms.sh uses seed 122 there.
