# The Hobbit — reverse-engineered sources

The Hobbit (Philip Mitchell and Veronika Megler, Beam Software, Melbourne
House, 1982), version 1.2, for the 48K ZX Spectrum, taken through
[ZX-REAPER](../../README.md) blind: no disassembly or write-up of the game was
read during the work. The sources build a tape byte-identical to the original
(Spectrum Computing, "HobbitTheV1.2.tzx").

The tape is not in git. Put it into `original/game.tzx`, then:

```sh
make restore     # re/tape/, re/orig.z80, re/image.z80 from the tape
make             # must print IDENTICAL
make expected    # frame hashes of the scripts from the original (not in git: 19 MB)
make test        # replays tests/inputs/*.txt against them
make shift-test  # code assembled at +$10 plays the same, frame by frame
make port-test   # stage 3: the Python port against the Z80 runs
make game-test   # stage 4: the clean game against stage 3, then free play
python3 port/play.py; python3 game/play.py   # play either (Pyxel)
make port-html; make game-html               # either as one web page
```

The article on how the game works is in [`docs/`](docs/README.md).

Tools: sjasmplus, Python 3 with SkoolKit 10.1 (`pip install -r ../../requirements.txt`), make.

## What is where

| Path | What |
| --- | --- |
| `src/game.asm` | includes the modules below in address order |
| `src/constants.asm` | named numbers: location, object and character ids, directions, record fields, flags, keys, ports |
| `src/loader03.bas` | the BASIC loader, lossless text |
| `scripts/text.py` | decodes the dictionary, the messages and the command table (`words`, `msg ADDR`, `all`, `verbs`) |
| `scripts/picdsl/` | the pictures in smaller encodings, each decoded and drawn again and compared with the original ([docs/10-smaller-pictures.md](docs/10-smaller-pictures.md)) |
| `re/notes.md` | memory map and every data format: dictionary, messages, locations, objects, NPC scripts, timers, pictures; relocation |
| `re/ids.md` | location, object and character ids, NPC records, timers |
| `re/questions.md`, `re/findings.md` | what the work had to answer; the claims with evidence |
| `re/skool/` | the annotated SkoolKit disassembly before export (history) |
| `port/` | stage 3: the game in Python with the original's memory layout ([porting notes](docs/08-porting.md)) |
| `game/`, `bridge/` | stage 4: the game as clean Python, its data in `game/assets/` (made by `bridge/assets.py`, not in git); the bridge checks it against stage 3 |
| `tests/inputs/` | input scripts: verbs (the parser), die, save, load, journey (230,000 frames of play), endgame (the game played to the end) |

| Module | Range | Contents |
| --- | --- | --- |
| dictionary | $6000 | the vocabulary: letter index and 562 words in 5-bit letters |
| main | $6C00 | start, restart, the main loop, the line editor |
| keys | $6E4F | typed words to tokens, command table helpers, the wait for a key and the WAIT time-out |
| printer | $7291 | the message interpreter: control codes, names, articles, dictionary words |
| parser | $7585 | sentences: word classes, phrase records, nouns, questions, orders (SAY TO) |
| drawing | $7F77 | location pictures: the command interpreter, lines, flood fill, attributes |
| system | $8251 | special words (ALL, EXCEPT, PRINT, QUIT, HELP, SCORE, PAUSE), SAVE and LOAD |
| screen | $8576 | the story and input windows: characters, scrolling, the 42-column font |
| devices | $8B22 | the ZX printer and the keyboard scanner |
| verbs | $8C4B | look, take, drop, move, run, follow, inventory, open, attack, put, give, examine |
| engine | $94D6 | command dispatch, describing locations, the end of a turn, timers, NPC scripts |
| objects | $9B16 | object and location records: lookups, holders, weights, reach, exits, lists, random numbers |
| handlers | $A1D0 | handlers of particular objects and characters, the victory check |
| commands | $AB53 | the command table, articles, common words |
| messages | $AD7D | the 177 messages |
| world | $B6EB | variables, locations, objects, characters, handler tables, NPC scripts, timers |
| pictures | $CC00 | the picture table and the 22 pictures; the state backup area |

## Changing common things

- Texts: `src/messages.asm`, a bytecode of letters, dictionary words and
  control codes (format in `re/notes.md`, Text); `python3 scripts/text.py msg
  ADDR` shows what a message prints. Words: `src/dictionary.asm`.
- The world: locations (exits, descriptions), objects and characters (where
  they are, weight, strength, verb handlers) and the NPC scripts are in
  `src/world.asm`; record layouts in `re/notes.md`, World.
- Pictures: `src/pictures.asm`, one command stream per location id.
- Score: `FirstVisitScores` (src/verbs.asm), points for reaching locations.
- Timing: the scroll pause per line is `SCROLL_DELAY` key polls; the automatic
  WAIT comes after `IDLE_SCANS_MAX` polls without a key.
- Relocation: the whole region moves, but only by up to $12 bytes upwards:
  the state backup ends at $FFED (see `re/notes.md`, Relocation).

## Not explained

- Some record flag bits (object +7 bits 2 and 4) and state bits.
- Code no script reached (85% of the code ran): it is listed by
  `tools/zxq.py unexec re/maps/*.map`.
