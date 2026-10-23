# 1. Overview: the game, the machine, the memory

The Hobbit is a text adventure with location pictures: the player types
English sentences, the game answers in a scrolling story window, and a dozen
characters (Gandalf, Thorin, the trolls, Gollum, the goblins...) act on their
own every turn. This file covers what the program uses of the 48K Spectrum,
how it loads and where everything lives in memory.

## The game

- *The Hobbit*, Philip Mitchell and Veronika Megler, Beam Software, published
  by Melbourne House in 1982. This is version 1.2 for the 48K ZX Spectrum.
- The player is Bilbo. The goal is to bring the valuable treasure from the
  dragon's lair back to the wooden chest in Bag End
  ([CheckVictory](../src/handlers.asm#L1180)). The story is told in 177 messages and a 562-word
  dictionary; 80 locations, 43 objects and 17 characters make the world.
- The parser accepts sentences such as `TAKE THE ROPE AND THE SWORD THEN GO
  EAST`, `PUT ALL EXCEPT THE MAP IN THE CHEST`, `SAY TO THORIN "CARRY ME"`
  (INGLISH for the parser and ANIMACTION for the characters are the names the
  game was sold with; neither appears in the program).
- 22 of the 80 locations have a picture, drawn with lines and flood fills when
  the player arrives ([05-pictures](05-pictures.md)).

## Hardware it uses

| What | How | Where |
| --- | --- | --- |
| CPU | Z80, interrupts off for the whole game (`DI` at start and restart; no `EI`, no `HALT`, no `IM`) | [GameStart](../src/main.asm#L60), [RestartGame](../src/main.asm#L81) |
| Screen | 256x192 bitmap and attributes, written directly: pictures in the top 16 character rows, the story window (rows 0-17, 42 columns with the game's own 6-pixel font), a rule at row 18, the input window (rows 19-23, 32 columns, ROM font) | [05-text-and-screen](05-text-and-screen.md) |
| Border | port `$FE`: black at the title, white in play, the picture's colour while a picture waits for a key, green during PAUSE | [StartPicture](../src/drawing.asm#L697), [WordPause](../src/system.asm#L439) |
| Keyboard | port `$FE`, the game's own edge-triggered scanner and key tables; the ROM's keyboard routine is never called | [ReadKey](../src/devices.asm#L132) |
| Sound | none: no `OUT` sets the speaker bit (the border bytes of all 22 pictures are 0-7) | |
| Tape | the ROM's `SA-BYTES` (`$04C2`) and `LD-BYTES` (`$0556`) for SAVE and LOAD | [SaveGame](../src/system.asm#L574), [LoadGame](../src/system.asm#L463) |
| ZX Printer | port `$FB`, a copy of the ROM's COPY loop that prints each finished story line (PRINT / NOPRINT) | [PrintStoryLine](../src/devices.asm#L15) |
| ROM font | `$3D00`, read by the input window | [PrintInputChar](../src/screen.asm#L270) |
| R register | read once, when the title key is pressed: the random seed | [RestartGame](../src/main.asm#L81) |

Nothing in the game is tied to the 50 Hz frame. Time is counted in typed
commands ("turns"); the only real-time element, the automatic `WAIT` of an
idle player, counts keyboard scans ([04-game-loop](04-game-loop.md)).

## How it loads

The tape is standard ROM blocks with no protection (verified: the sources
rebuild a byte-identical tape).

| Block | Content |
| --- | --- |
| `hobbit` (BASIC, autostart line 5) | [`src/loader03.bas`](../src/loader03.bas): `CLEAR 24575`, black ink, paper and border, `POKE 23659,0` (DF SZ: no lower screen lines), `LOAD "p" CODE 16384`, `LOAD "h" CODE`, `PRINT USR 27648` |
| `p`, 6912 bytes at `$4000` | the loading screen ([`data/screen05.scr`](../data/screen05.scr), shown in [07-graphics](07-graphics.md)) |
| `h`, 40000 bytes at `$6000-$FC3F` | the whole game: code, dictionary, messages, world, pictures |

`PRINT USR 27648` enters [GameStart](../src/main.asm#L60) at `$6C00`. The loading screen stays on
the display as the title screen until a key is pressed
([03-title-and-menu](03-title-and-menu.md)).

## Memory map

| Range | Size | What | Source |
| --- | --- | --- | --- |
| `$4000-$5AFF` | 6912 | screen: picture rows 0-15, story window rows 0-17, rule row 18, input window rows 19-23 | |
| `$5C00-$5CB5` | | system variables; only BORDCR (`$5C48`) is written by the game, the rest serve the ROM tape routines | |
| `$5E00-$5EFF` | 256 | stack (SP = `$5EFF`, set by the restart) | [RestartGame](../src/main.asm#L81) |
| `$5F00-$5FDB` | 220 | backup of the two small state blocks | [GameStart](../src/main.asm#L60) |
| `$6000-$6BFF` | 3072 | dictionary: letter index and 562 words in 5-bit letters | [`dictionary.asm`](../src/dictionary.asm) |
| `$6C00-$6E4E` | | start, restart, main loop, line editor | [`main.asm`](../src/main.asm) |
| `$6E4F-$7290` | | typed words to tokens, command table helpers, idle WAIT | [`keys.asm`](../src/keys.asm) |
| `$7291-$7584` | | the message interpreter | [`printer.asm`](../src/printer.asm) |
| `$7585-$7F76` | | the sentence parser, noun matching, order slots | [`parser.asm`](../src/parser.asm) |
| `$7F77-$8250` | | picture interpreter, lines, flood fill | [`drawing.asm`](../src/drawing.asm) |
| `$8251-$8575` | | special words (ALL, EXCEPT, PRINT, SAVE, LOAD, QUIT, HELP, SCORE, PAUSE) | [`system.asm`](../src/system.asm) |
| `$8576-$8B21` | | the two text windows, the 768-byte font at `$8822` | [`screen.asm`](../src/screen.asm) |
| `$8B22-$8C4A` | | ZX printer, keyboard scanner and key tables | [`devices.asm`](../src/devices.asm) |
| `$8C4B-$94D5` | | verb handlers: look, take, drop, move, run, follow, attack, put, give, examine | [`verbs.asm`](../src/verbs.asm) |
| `$94D6-$9B15` | | command dispatch, location descriptions, end of turn, timers, NPC script interpreter | [`engine.asm`](../src/engine.asm) |
| `$9B16-$A1CF` | | record lookups, holders, weights, reach, exits, object lists, random numbers | [`objects.asm`](../src/objects.asm) |
| `$A1D0-$AB52` | | handlers of particular objects and characters, the victory test | [`handlers.asm`](../src/handlers.asm) |
| `$AB53-$AD7C` | 554 | command table (59 records), article and common-word tables | [`commands.asm`](../src/commands.asm) |
| `$AD7D-$B6D9` | 2397 | 177 messages (bytecode) | [`messages.asm`](../src/messages.asm) |
| `$B6DA-$B736` | | parser and game variables, the word-ending table | [`world.asm`](../src/world.asm) |
| `$B737-$B7FF` | 201 | 8 order slots for SAY TO | [OrderSlots](../src/world.asm#L129) |
| `$B800-$B9DF` | 480 | parser phrase stack (24-byte records growing down from `$B9C8`) | [PhraseStack](../src/world.asm#L144) |
| `$B9E0-$BA89` | | location address table, location prepositions | [LocationTable](../src/world.asm#L179) |
| `$BA8A-$C062` | 1497 | 80 location records (saved) | [Loc00None](../src/world.asm#L286) |
| `$C063-$C11A` | | object id -> record table | [ObjectTable](../src/world.asm#L1061) |
| `$C11B-$C72F` | 1557 | 61 object and character records (saved) | [Chr00Player](../src/world.asm#L1202) |
| `$C730-$C82C` | | default verb handlers, arrival handlers, random events, blocked exits | [VerbHandlers](../src/world.asm#L2132) |
| `$C82D-$CA83` | 599 | NPC behaviour tables and scripts | [GoblinABehaviours](../src/world.asm#L2332) |
| `$CA84-$CB42` | 191 | 10 timers and 17 NPC records (saved) | [Timers](../src/world.asm#L2762) |
| `$CB43-$CBFF` | 189 | zeros, never referenced | [LCB43](../src/world.asm#L2930) |
| `$CC00-$F35A` | 10075 | picture table and 22 pictures | [`pictures.asm`](../src/pictures.asm) |
| `$F35B-$F3FF` | 165 | zeros, unused | |
| `$F400-$FFED` | 3054 | backup of the two large state blocks (zeros on tape) | [GameStart](../src/main.asm#L60) |

Free memory: `$CB43-$CBFF` and `$F35B-$F3FF` (354 bytes) are the only unused
bytes inside the loaded block; the backup area above `$F400` is loaded as
zeros and filled at run time.

### The saved state

Everything that changes during a game lives in four blocks. They are what
SAVE writes, what the start-up code copies to the backups and what a restart
copies back:

| Block | Size | Content | Backup |
| --- | --- | --- | --- |
| `$B6EB` | 29 | variables: score, player location cache, flags, random event | `$5F00` |
| `$C11B` | 1557 | object and character records | `$F400` |
| `$CA84` | 191 | timers and NPC records | `$5F1D` |
| `$BA8A` | 1497 | location records (exits, visited flags, descriptions) | `$FA15` |

Two things outside these blocks also change: three bytes of the Bard's
script (`$C9E2`, rewritten by orders; copied into the variables block for
SAVE, [05-characters](05-characters.md)) and the two header bytes of picture 5
([06-tricks](06-tricks.md)).

## Sources and checks

The sources in [`src/`](../src/) assemble with sjasmplus into a tape identical
to the original. `make test` replays six input scripts frame by frame against
hashes recorded from the original; `make shift-test` moves the code by `$10`
bytes and checks that it still plays the same, which proves that every address
in the sources is symbolic. Claims in this article are marked *verified*
(seen in the simulator or a byte check) or *inferred* (read from the code);
the `F` numbers refer to [`re/findings.md`](../re/findings.md).
