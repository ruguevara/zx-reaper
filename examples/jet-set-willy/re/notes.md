# RE notes

Facts that are not yet in the skool/asm comments: memory map, loader stages,
open questions. Keep it short; move each fact into the source once its
routine or data block is annotated.

## Memory map

| Range | What | Status |
| --- | --- | --- |
| $5B00-$5BFF | stack (SP=$5BFE set at $8400) | stack |
| $5C00-$5DFF | attribute buffer: room with sprites (copied to $5800) | buffer |
| $5E00-$5FFF | attribute buffer: empty room (master copy) | buffer |
| $6000-$6FFF | screen buffer: room with sprites (copied to $4000) | buffer |
| $7000-$7FFF | screen buffer: empty room (master copy) | buffer |
| $8000-$80FF | current room, copied from $C000+256*room | buffer (room format below) |
| $8100-$8140 | entity buffer: 8 entities x 8 bytes, $FF terminator | buffer |
| $8141-$81FF | unused (zeros) | unused |
| $8200-$82FF | 128 words: screen-buffer address of each pixel row ($6000-based) | data:words |
| $8300-$83FF | rope table (two 128-byte halves, read with L and L+128) | data (inferred) |
| $8400-$841F | start: SP, return to $869F; fake decryption loop (bytes rewritten unchanged) | code |
| $8420 | current room number | vars |
| $8421-$8430 | 16-byte table read by $8F65 | data (TODO) |
| $8431-$8450 | title graphic pieces (read by $887B) | data |
| $8451-$869E | texts, variables $85CB-$85E4, key table $85E5-$85FA, tunes $85FB/$865F | text, vars, data |
| $869F-$9716 | code (with unused fragments $93BB-$93D0 and $96F4-$9717) | code |
| $9718-$97FF | unused (zeros) | unused |
| $9800-$99FF | title screen attributes (copied to $5800, 512 bytes) | data |
| $9A00-$9AFF | status bar attributes (copied to $5A00) | data |
| $9B00-$9B7F | code-entry key graphics (4 x 32 bytes) | data |
| $9B80-$9BFF | code-entry screen attributes (copied to $5900) | data |
| $9C00-$9C3F | leftover assembler source text | unused |
| $9C40-$9C7F | game over: foot, barrel | data:sprites |
| $9C80-$9CFF | Maria (4 frames) | data:sprites |
| $9D00-$9DFF | Willy (8 frames, 32 bytes each) | data:sprites |
| $9E00-$9EB3 | code table: grid location L -> code byte - L | data |
| $9EB4-$9EFF | leftover bytes | unknown |
| $9F00-$9FFF | unused (zeros) | unused |
| $A000-&#36;A3FE | entity definitions, 8 bytes each (index*8+&#36;A000) | data |
| $A3FF | index of the first item in the item table | data/var |
| $A400-&#36;A5FF | item table: two 256-byte halves | data |
| $A600-&#36;BFFF | sprites, 32 bytes each (toilet at $A600) | data:sprites |
| $C000-&#36;FFFF | 64 rooms, 256 bytes each | data:rooms |

Room format (256 bytes, copied to $8000): $00-$7F layout, 2 bits per cell
(512 cells); $80-$9F name; $A0-&#36;D5 six tiles of 9 bytes (attribute + 8 pixel
rows: background, floor, wall, nasty, ramp, conveyor); $D6 conveyor direction,
$D7 conveyor address (word), $D9 conveyor length; $DA ramp direction, $DB ramp
address (word), $DD ramp length; $DE border colour; $DF-&#36;E0 unknown; $E1-&#36;E8
item graphic; $E9-&#36;EC exits (left, right, up, down); $ED-&#36;EF unknown; $F0-&#36;FF
eight entity slots (2 bytes each: definition index, start data).

## Open questions

## Init (zxinit.py)

- original: `original/game.tap`
- code region: $8000-&#36;FFFF
- handover PC: $8400

## Loader and protection

- Tape: BASIC "Jetset1" (autostart line 10) loads code "Jetset2" 32768 bytes at
  $8000 and jumps to $8400. Standard ROM blocks; no turbo, no encryption.
- $8400 looks like a decryptor: it XORs each byte of $8500-&#36;FFFF with L and H
  but stores the original byte back, so nothing changes. It then RETs to $869F
  through a stack word it planted at $5BFE.
- Colour-code protection: $86C3 shows a grid location (from FRAMES at $5C78) and
  waits for four colours (keys 1-4, ENTER). Code byte = $9E00[L] + L, two bits
  per position. Two tries, then JP 0. Input script `tests/inputs/code.txt`
  enters the code for the simulator's fixed start (B3: 4-2-3-2).

## Coverage

97% of code instructions executed (`make coverage`): scripts `code`, `title`
(tune, scroll, colour cycling), `start`, `pause` (pause, tune toggle, idle
pause, CAPS SHIFT+SPACE quit), fuzz runs (re/maps/fuzz*.map), the RZX
walkthrough "Perfect JSW" (same version; only runtime state differs), and
`ending.map` (simulator runs with pokes that reach the ending stages, F61-F65).
Not executed by these inputs, with the reason:
- $86FF: the FRAMES value $8E case of the code screen (F-entry of #R$86C3).
- $8A11-$8A24: flash timer $85CD is never set by any code (F105).
- $8A8B-$8A97, $8AA3-$8AA7: the clock reaching 1:00pm and 13:00 (observed with
  pokes, F75/F95; a full run takes 18 game hours).
- $8B7A-$8B94, $8BE5-$8BF4: teleport and WRITETYPER completion (observed with
  pokes and snapshots, F72/F106).
- $9283, $9399: rare arrow and rope branches.
- $93BB-$93D0 and $96F4-$9717: unreachable leftovers (F10, F11).
The RZX speed run "jsw7.56am" is a different build (25 KB differ) and was not used.

## Relocation

`make shift-test` (SHIFT=0x100) passes on all input scripts (code, title,
start, pause, play: 58,000 frames with room changes, deaths and game over).
Only $8000-$9EFF moves (`SHIFT_END` in re/layout.mk); $A000-&#36;FFFF stays at its
address, and +$100 is the largest shift that fits:
- memory is used up to $FFFF and $5C00-$7FFF holds the work buffers, so the
  region cannot grow upwards or move down; the only free page is $9F00
  (unused zeros, which the Attic arrow bug writes into, F92);
- entity definitions are found as $1400+index, times 8 (= $A000+8*index), so
  the table must stay at $A000; rooms are found as page $C0 OR room, so the
  room table must stay at $C000; items use H=&#36;A4/&#36;A5 and sprites are named by
  page bytes in the definitions (pages $AB-&#36;BF stay; page $9C moves and is
  written as SpriteFoot>>8 in the five definitions that use it);
- the moved tables are page aligned (RowAddressTable, RopeStepTable, CodeTable,
  the sprite pages $9C/$9D and the room buffer are read with H or D set to the
  page and L or E as the index), so a shift must be a multiple of $100: an odd
  shift cannot work without changing instructions.
