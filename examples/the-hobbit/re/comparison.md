# The Hobbit: the blind run compared with the existing work

The run (stages 1 to 4, `docs/the-hobbit-run.md` in ZX-REAPER) was blind: no
disassembly or write-up of the game was read. This report compares it with
those works afterwards (2026-10-24). Nothing in our sources has been changed
by the comparison yet; the corrections it calls for are listed at the end.

The details are in three reports, each with the runs that settled its
differences: [names and meaning](comparison/names.md), [data formats and
how the game works](comparison/formats.md), [bugs, traps and
quirks](comparison/bugs.md). Their input scripts are in
[`comparison/inputs/`](comparison/inputs/).

## The references

| | Work | Version | What |
| --- | --- | --- | --- |
| J | [jonsole/zx-spectrum-disassemblies](https://jonsole.github.io/zx-spectrum-disassemblies/) (2026) | 1.2 | a complete SkoolKit disassembly built from the tape, with notes on how the game works, bugs, traps and pokes; the main reference |
| P | [pobtastic/hobbit](https://github.com/pobtastic/hobbit) (2023) | 1.2 | a partial SkoolKit disassembly (186 entries) |
| B | [basf-c60/thehobbitv1.0](https://github.com/basf-c60/thehobbitv1.0) | 1.0 | a disassembly of the first version, with how it works, bugs and trivia |
| E | [6elphegor/hobbit-1982-native](https://github.com/6elphegor/hobbit-1982-native) (2026) | 1.2 | a C port: a faithful edition and a clean one with the bugs fixed, following P |
| I | [Icemark: The Hobbit data format](https://www.icemark.com/dataformats/hobbit/) | other | format notes |
| W | Wilderland (2012-2019), [veronikamegler.com/WL](http://veronikamegler.com/WL/wl.htm) | 1.2 | the game run with its state shown; dictionary and room dumps |
| M | V. Megler, [There and Back Again: A Case History of Writing The Hobbit](https://refractory-journal.com/vmegler/), Refractory 27 (2016) | | the author's account of the design |

J's skool was built from our tape with its own script; it describes the same
bytes. None of J, P or B carries a licence: their names appear here only to
identify what is compared.

## Structure

`tools/zxcompare.py` on our `build/game.skool` against J's and P's:

| | J | P |
| --- | --- | --- |
| bytes that differ | 4 | 1,589 |
| code vs non-code, bytes in agreement | 99.8% | 99.1% |
| code entries (ours 324) | 369, 307 shared | 128, 110 shared |
| data entries (ours 261) | 418, 251 shared | 58, 29 shared |

- **Bytes.** The 4 at $6D8C are a wrong address on one line of our skool
  (the instruction is at $6D8D; the tape, our asm and J agree). P's 1,589 are
  almost all $F400-$FC2F, the backup copy of the world that P's snapshot
  holds and the tape leaves at zero.
- **Classification.** 70 bytes we call code are six routines nothing reaches,
  which J files as data; 4,343 are our `g` (variables) against J's `b`, a
  convention. Of the text, "> LOOK" is ours right and "WAIT" is J's right.
  Against P, ours is right on 283 bytes of tables P decodes as code and 89
  bytes of workspace.
- **Boundaries.** The 62 code entries only J has are all labelled points
  inside our entries; 46 of them are in two stretches we kept as one entry
  each: the verb handlers at $8CE0-$9404 and the object and character
  handlers at $A244-$AB4F. J splits every location and object record into an
  entry; we keep the world as blocks with a label per record.

| Documentation | Ours | J | P |
| --- | ---: | ---: | ---: |
| entries | 585 | 787 | 186 |
| labels | 1,412 | 1,603 | 434 |
| description words | 29,336 | 29,682 | 664 |
| code instructions with a comment | 34% | 15% | 18% |
| entries with a register section | 182 | 85 | 21 |
| 16-bit / 8-bit literals in the asm | 105 / 585 | 79 / 988 | |

## Meaning

506 addresses have an entry on both sides (ours against J). 273 say the
same, 201 the same thing in other words, 2 differ in emphasis, 6 differ
(J is right in all six), and 24 are ours left generic ("Command handler
(via $C730)"): 2,185 bytes of handlers we did not describe, where J names
about 60.

| Address | Ours | J | Verdict |
| --- | --- | --- | --- |
| $9CE8, $9CED | `SumHeldWeight` (+2), `SumHeldBulk` (+3) | the sizes held, the weights held | J. +3 is the weight: its test prints "too heavy to lift". +2 is the size ("too full", "too small"). Our names are swapped everywhere, the mechanics are right |
| $8315 | `StoreParsedOrders`, "the end of the typed words" | the quote mark's handler | J for the trigger (it runs only on a quote); the mechanism is the same |
| $71F3 | matches a command record | matches a typed name against a record | J: it serves object names too |
| $A20B | five record ids | five action codes | J |
| $AF82 | title "Lands in the boat." | "but slide out again" | J: our title is copied from the message before |
| $9B93 | steps through the object table | steps any three-byte list | J: exits use it too |

194 of our labels are placeholders (`LA244_10`, `L82E2`); J has a real name
at 143 of those addresses, 97 of them in code.

## Data formats and how the game works

The formats agree almost everywhere: the dictionary, the message bytecode,
the parser's records and patterns, locations, exits, object and character
records, scripts, timers, the random numbers, fighting, scoring, pictures,
input, the screen, SAVE and LOAD, the memory map.

- **Ours wrong or stale on eight facts:** the +2/+3 names; +7 bit 5 is
  "open" (a dead troll keeps it), not "alive"; message control code 3 is
  used (two wound messages print the weapon with it); "WITH THE MAP ATTACK
  GANDALF" fails (word order is not free, as B says); exits to location 0;
  the picture drawing time; key 0 as the first key of a line types W (we
  left it out); the idle time in `re/questions.md`.
- **A reference wrong and ours right on six:** J on endings 4 and 5 (they
  are used) and on Thorin's "Get us out of this one" (it cannot be said);
  B on obedience 0 (no orders, not "always obeys"); E on the +4 nibble and
  on the id-0 verb entries; I on code $0C.
- **Our open item answered.** Object flag bits 2 and 4 are "full" and "on"
  (J, W, B, E); the game's own state-word tables are indexed by flag bit
  and hold "empty/full" at 2 and "off/on" at 4.
- **Ours answers four of J's open questions** ($B70F, the class-8 words,
  Gollum's choice of line, the bytes at $99E5).
- **Megler's account against 1.2.** It confirms the three databases, the
  weight-and-size physics (and so the references' names), characters as
  action lists with random entries and jumps, every character acting after
  the player, and randomness as a design goal. Four things she describes
  are not in 1.2: the goblins' dungeon with random exits, random starting
  points in the characters' scripts, an adverb ("viciously") that changes an
  attack (run: no effect), and trolls that kill whatever is alive (they
  talk, eat a player who stays, and turn to stone). LIGHT and TURN are
  verbs with no command: the lamps were cut down to the sword (inferred).

## Bugs, traps and quirks

50 items the references name still hold in 1.2 (J 9 bugs and 7 traps, B 10
of its 14 v1.0 bugs, E 17, others). The blind run found 30, partly 3, and
missed 17.

| Source | Found | Missed |
| --- | --- | --- |
| J's 9 bugs | 7 | FILL never works; five sentence patterns with no handler |
| J's 7 traps | 5, and the closed container in part | a new game keeps the scripts' state (Bard's order, Thorin's spent remark) |
| B's 10 still in 1.2 | 8 | Bard's order loses its second object on SAVE; "You are in in a clearing" after dawn |
| E's 17 | 9, and 1 in part | `SAY "HELLO` then `@` resets the Spectrum; ALL ... EXCEPT with a word out of place writes over the location table; PUT X IN RIVER fails; and four faults that only fuzzing or garbage reach (a resumed search past the index, a token class past $C0, a printed word over 20 letters, a null pointer read at $95DF) |

Ours and in no reference: 14 findings, among them the weapon test that
breaks strong weapons on weak targets (F46), LOOK THROUGH that never says
"It is dark." (F54), the "too small" message that prints a word made of
weights (F53), a typed word of 105 letters that overwrites code (F70),
orders that leak between characters (F72, F73), the riddle's answer that
must be the next command (F76), and the stale IY that turns a timer's
handler into the middle of a routine (F85); and 14 quirks of the code that
stages 3 and 4 reproduce.

Settled by runs where the sources disagree: JUMP ONTO the barrel can be
reached (from the great halls with the sword) and hangs, as B says, not
unreached as J says; the forest can be survived (wait twice, leave on the
third turn), as B says, not "whatever you do" (J, and our 06-tricks); B's
web-strength overflow is not a bug (halved, then doubled back); three of
B's v1.0 bugs are fixed in 1.2; E's "fights end in one blow" overstates a
4% case.

Why the blind run missed what it missed: not reached (sequences of
commands no script typed, the crashes fuzzing finds), read but not
recognised (FILL, the five patterns, the Bard's fourth byte, "in in" on a
screen of our own run that nobody read), and not looked for (which key
opens what, which death makes the game unwinnable).

## The ports

E made the same choice for its faithful port as our stage 3: the Z80's
register interface, because the routines pass values through long chains
of registers.

| | E | Ours |
| --- | --- | --- |
| faithful port | C, 338 routines, ~11,900 lines | Python (stage 3), 400 routines, ~9,300 lines |
| its check | every call of every routine against the Z80: registers, flags, all 64K, the stack | all game memory at every main-loop pass of six recorded runs against the Z80 |
| the random byte from memory | reproduced (the stack bytes and flags too), so the port alone matches the original's transcripts (11 of 12 long fuzzed games) | taken from the record: identical in replay only |
| clean version | C, ~9,700 lines; data in the tape's formats behind record structs; its own random generator; the bugs fixed behind `--original-bugs` | Python (stage 4), ~6,800 lines; plain state, the data as editable files (JSON, picture text, PNG); faithful only |
| its check | transcripts against the faithful port, each clean routine in the faithful port, both versions of a routine from the same state with mutated inputs; 400 fuzzed games | every call of the stage 3 routines and every main-loop pass of six runs against stage 3, the screen included; free play with invariants |
| picture drawing time | not kept | not kept |

## Lessons for the method

1. **Structure and meaning hold up.** Against the most complete reference
   the bytes, the code map and the meaning of what both describe agree; J
   is ahead on the handlers we left as two undescribed stretches, we are
   ahead on registers, constants and instruction comments.
2. **Every target of a handler table is an entry.** The 24 generic entries
   are handler-table targets merged into blocks; `zx-annotate` should split
   them and give each a title.
3. **Name a field from the message its test prints.** The weight/size swap
   ran from the annotation into the article, stage 3 and stage 4, and every
   check passed, because names are not checked. The messages "too heavy to
   lift" and "too full" settle it.
4. **The bug hunt needs sequences.** Fuzz typed commands from the game's
   vocabulary (E found its crashes that way); check every command pattern
   against the handler tables; read every screen of the recorded runs for
   odd text; ask what a new game restores and what it does not.
5. **A port that is identical only in replay.** Our stage 3 needs the record
   for the random byte; E shows the port can reproduce the stack bytes the
   generator reads and then run alone. Our stage 4's free play should be
   recorded on the Z80 and replayed, as E's fuzzing compares with the
   original.

## Corrections to make

Not applied yet:

- The weight and size names: `SumHeldWeight`/`SumHeldBulk`, `re/notes.md`,
  F18, F53, F67, the article (02-data, 05-world), and the fields of stages 3
  and 4 (`Thing.weight`/`size`, the decoder, `world.json`).
- The title of $8315 and F21's "end of word list"; the title at $AF82; $A20B
  as five action codes; the scope of $71F3 and $9B93.
- Flag bits: 5 "open", 2 "full", 4 "on"; the README's open item.
- Control code 3 is used; word order is not free; key 0; exits to location
  0; the stale lines in `re/notes.md`, `re/questions.md` and the comments
  `formats.md` lists.
- 06-tricks: the forest can be survived; F41: the ring divides by 4; the
  Bard's order writes four bytes and SAVE keeps three.
- New findings for the missed bugs that runs confirmed (FILL, the five
  patterns, the Bard's fourth byte, "in in", `SAY "HELLO` then `@`,
  ALL ... EXCEPT, PUT IN RIVER, the closed container, what a new game keeps,
  the unused description at $B5FE), and JUMP ONTO's hang as a finding.
- Names for the handlers we left as placeholders, worked out from the code.
