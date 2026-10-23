# 8. Porting notes

What a port to C, Python or another machine has to replace, and what it can
keep. The game logic is almost free of hardware: input goes through one
routine, output through one character routine and the picture interpreter, and
nothing depends on the frame rate. The hard parts are the random numbers,
which read raw memory, and the save files, which hold absolute addresses.

## Hardware touch points

| Touch point | Routines | A port provides |
| --- | --- | --- |
| keyboard scan, edge-triggered, ASCII from two tables | [ReadKey](../src/devices.asm#L132) (via [WaitKey](../src/keys.asm#L802)) | "the next key pressed", with the same codes: letters, `$0D`, `$08` back-space, `$18` delete, `$09`/`$0A`/`$5B` cursor keys, `"` `.` `,` `@` |
| "any key down" polls | [WaitTitleKey](../src/main.asm#L112), [WaitKeyAfterPicture](../src/engine.asm#L380), [WaitForKey](../src/system.asm#L546), [EndGame_Wait](../src/verbs.asm#L815), [WordQuit](../src/system.asm#L288), [LoadBlock](../src/system.asm#L509), [VerifyBlock](../src/system.asm#L649), [WordPause](../src/system.asm#L439), the scroll pause in [OutputStoryChar](../src/screen.asm#L349) | a key-held test |
| the N key at the title | [RestartGame](../src/main.asm#L81) | a "pictures off" option |
| R register | [RestartGame](../src/main.asm#L81) | a seed |
| border | [StartPicture](../src/drawing.asm#L697), [ClearScreen](../src/keys.asm#L381), [WaitKeyAfterPicture](../src/engine.asm#L380), [WordPause](../src/system.asm#L439), [RestartGame](../src/main.asm#L81) | a colour, or nothing |
| screen bitmap and attributes | the picture drawer ([`drawing.asm`](../src/drawing.asm)), the story window ([PrintStoryChar](../src/screen.asm#L580), [ScrollStoryUp](../src/screen.asm#L495)), the input window ([PrintInputChar](../src/screen.asm#L270), [ScrollInputUp](../src/screen.asm#L164), [ScrollInputDown](../src/screen.asm#L220)), [ClearScreen](../src/keys.asm#L381), the rule in [RestartGame](../src/main.asm#L81) | a 256x192 two-colour-per-cell display, or a text console plus a picture area |
| ROM font `$3D00` | [PrintInputChar](../src/screen.asm#L270) | the Spectrum font for the input window |
| ROM tape SA-BYTES, LD-BYTES | [SaveGame](../src/system.asm#L574), [LoadGame](../src/system.asm#L463) | save and load of the four state blocks |
| ZX Printer port `$FB` | [WordPrint](../src/system.asm#L83), [PrintStoryLine](../src/devices.asm#L15) | optional |

A text-only port can intercept [PrintChar](../src/screen.asm#L48) (with [RawOutputFlag](../src/world.asm#L45) for
the window) and [ReadLine](../src/main.asm#L331), and skip [DrawLocationPicture](../src/drawing.asm#L21) by leaving
[PicturesEnabled](../src/world.asm#L57) at 0: everything else is game logic.

## Timing

There is no frame timing and no interrupt. Three waits depend on the speed of
the Z80 code:

- the idle WAIT after 3000 key scans, about 19 seconds on a 3.5 MHz Spectrum
  (938 frames from Bag End, F36); a port should use a clock of about 19 s
  and refill 3 s per key;
- the scroll pause of `SCROLL_DELAY` key polls per story line, about half a
  second;
- the picture drawing itself, which takes from under a second to a few
  seconds and is part of the game's feel.

## Data

All data can be used as it is; the formats are in [02-data](02-data.md):
the dictionary at `$6000`, the 177 messages, the 59 command records, 80
locations, 61 object records, 17 NPC records with their scripts, 10 timers
and 22 pictures. [`scripts/text.py`](../scripts/text.py) decodes the text.
The handlers referenced from the object verb tables, the arrival table, the
timers and the scripts are code addresses: a port maps each to its own
function (the stage 3 port in [`port/`](../port/) does this with a table of
routines).

## Things that tie the game to its memory layout

- **Random numbers.** [RandomSigned](../src/objects.asm#L424) reads two bytes per call from a pointer
  that walks the whole address space: the ROM, the screen, the code and the
  stack. To play exactly like the original a port must emulate that memory
  (bitmap included) or take the numbers from a recording; a port that is
  free to differ can use any generator with the same ranges (F63, F74).
- **Save files.** The saved blocks contain absolute addresses: the current
  script and behaviour table of each NPC record, location description
  pointers, the timers' handler addresses, the random event pointer. A port
  that wants to read tapes saved by the original must keep these addresses or
  translate them; this is also why the relocated build cannot produce the same
  save tape (the shift test skips `save.txt`).
- **Self-modifying code** ([06-tricks](06-tricks.md)): the blocked-exit
  operand, the lock/unlock opcode, two `JR` opcodes, an index displacement,
  the message [MsgSubjIsIn](../src/messages.asm#L357), the Bard's script bytes and picture 5's header
  are all state. In a port they become variables; the blocked exit should then
  be saved with the game (F84).
- **The machine stack** carries message arguments under return addresses and
  the flood fill's seeds; handlers leave their callers by popping return
  addresses. A structured port needs explicit argument lists, a seed list for
  the fill and an "abort" result (or exceptions) for [CommitOrAbort](../src/objects.asm#L569) and
  its relatives.

## Entry points

| Entry | Address | Role |
| --- | --- | --- |
| [GameStart](../src/main.asm#L60) | `$6C00` | from BASIC: back up the state, then [RestartGame](../src/main.asm#L81) |
| [RestartGame](../src/main.asm#L81) | `$6C27` | restore the state, title key, set up, opening LOOK |
| [MainLoop](../src/main.asm#L197) | | read a line, parse, run |
| [ParseLine](../src/parser.asm#L30) / [RunSentences](../src/parser.asm#L1035) | | one sentence |
| [DispatchCommand](../src/engine.asm#L87) | | one command, test or real pass |
| [L96B3](../src/engine.asm#L433) | | the world's turn: victory test, characters, timers |
| [RunNpcScripts](../src/engine.asm#L765) | | the characters |
| [PrintMessage](../src/printer.asm#L112) | | all text |
| [DrawLocationPicture](../src/drawing.asm#L21) | | a picture by location id |

## Bugs: keep or fix

A faithful port keeps the bugs listed in [06-tricks](06-tricks.md), since some
of them shape play: the fight bugs (F9, F56, F65) change who wins, and the
RUN hang (F55) can end a game. The memory-overwriting ones (long words F70,
too many tokens F71) cannot be kept without emulating the memory and are
better turned into "line too long" errors. The save of the blocked exit (F84)
should be fixed in any port that offers SAVE.
