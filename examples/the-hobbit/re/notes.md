# RE notes

Facts that are not yet in the skool/asm comments: memory map, loader stages,
open questions. Keep it short; move each fact into the source once its
routine or data block is annotated.

## Tape

| Block | What |
| --- | --- |
| 02-03 | BASIC `hobbit` (autostart 5): `CLEAR 24575`, black screen, `LOAD "p" CODE 16384`, `LOAD "h" CODE`, `PRINT USR 27648` |
| 04-05 | `p`: the loading screen, 6912 bytes at $4000 (`data/screen05.scr`) |
| 06-07 | `h`: the game, 40000 bytes at $6000-$FC3F; entry $6C00 |

A standard ROM loader, no protection.

## Memory map

| Range | What | Status |
| --- | --- | --- |
| $4000-$5AFF | screen | |
| $5C00-$5CB5 | system variables: only BORDCR ($5C48, set to $38) and those the ROM tape routines use | inferred |
| $5E00-$5EFF | stack (SP $5EFF from $6C28) | inferred |
| $5F00-$5FDB | copy of the state blocks $B6EB (29) and $CA84 (191), made at $6C00 | observed |
| $6000-$6BFF | data, not yet classified | |
| $6C00-$A9E4 | code, with data between | |
| $AB27-$F359 | data: texts, dictionary, pictures, objects (not yet classified) | |
| $F400-$FFED | copy of the state blocks $C11B (1557) and $BA8A (1497), made at $6C00; QUIT copies them back | observed |

The game state is four blocks, the ones SAVE writes and the start copies:
$B6EB/29, $C11B/1557, $CA84/191, $BA8A/1497 (3274 bytes).

## Hardware

- Interrupts are off: DI at $6C00 and $6C27, no EI in the game. The ROM's
  tape routines return with EI; the game waits for keys with interrupts on
  and DIs at $8488/$8553 after SAVE/LOAD.
- ROM calls: SA-BYTES ($04C2) for SAVE, LD-BYTES ($0556) for LOAD and verify.
  Nothing else from the ROM (its own keyboard scanner, font and print code).
- `LD A,R` at $6CA7 once per game start, after the title key: the random seed ($B70E).
- Keyboard: its own scanner at $8B93 (edge-triggered, ASCII from tables
  $8BFB/$8C23); waits for any key at $969A (after a picture), $84B9, $6C6D.
- ZX printer: port $FB at $8B31-$8B72 (PRINT/NOPRINT). With no printer the runner reads $FF.
- Fonts: the game's own 96-character font at $8822 (42 columns in the story
  window); the input window uses the ROM's at $3D00 (32 columns).
- SPACE held into the ROM's tape routines is BREAK: SA/LD-RET raises a BASIC
  error that crashes the game (seen pressing SPACE at the verify prompt).

## Open questions

## Init (zxinit.py)

- original: `original/game.tzx`
- code region: $6000-$FC3F
- handover PC: $6C00
