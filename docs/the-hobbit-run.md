# The Hobbit: a blind run

Russian version: [the-hobbit-run.ru.md](the-hobbit-run.ru.md).

A run of the [method](method.md) on The Hobbit (Philip Mitchell and Veronika Megler, Beam Software, Melbourne House, 1982), version 1.2, from the tape to stage 4. The game was chosen to be unlike Hungry Horace: a text adventure with a parser, characters that act on their own, timers, and pictures drawn from command streams. The run was blind: no disassembly or write-up of the game was read, and the subagents were forbidden to search for them. The author set the task, answered the stage 4 interview, and said "retry" once when the agents stalled. The comparison with the existing work came after the run (below).

## Stages 1 and 2: reverse engineering

- Sources: 17 asm modules plus `game.asm`, `constants.asm` and `build.asm` (22,584 lines), the BASIC loader, a tape manifest; `make` builds a tape byte-identical to the original.
- 585 entries, 100% annotated, 1,608 labels; every routine has a title, a description, registers and a `Hardware:` line.
- Coverage 85% of the code, from six input scripts typed into the game (`TYPE` in `zxrun.py`): the parser's verbs, a death, SAVE, LOAD, a 230,000-frame journey and the whole game played to the end (the Bard shoots the dragon, the treasure goes into the chest).
- Relocatable: code assembled at +$10 and +$7 plays the same frame by frame on every script but SAVE (the saved blocks hold absolute addresses). The random routine reads its own code, so the shift test gives it the original's values (`SHIFT_GIVE`).
- 85 findings (51 observed, 34 inferred), among them the original's bugs: the fight (F9, F56, F65), a RUN that can hang (F55), long words and long lines writing over code (F70, F71), a "Which ... ?" question that prints a stray word (F61), the blocked exit SAVE forgets (F84), a stale IY that turns a timer's handler into the middle of a routine (F85).
- The article, [`examples/the-hobbit/docs/`](../examples/the-hobbit/docs/README.md): 16 files, ~24,600 words, 724 links into the sources, 37 images (every picture, the font, the title, screens).

| Phase | Who | Time | Subagent tokens |
| --- | --- | --- | --- |
| init, coverage scripts | lead, 2 subagents | ~25 min | 0.25 M |
| classification: code, text, world, pictures | lead, 4 subagents | ~30 min | 0.75 M |
| annotation in three waves (6, 6, 5 batches) | lead, 17 subagents | ~50 min | 2.65 M |
| relocation, export | lead | ~35 min | |
| bug hunt, gallery, article (in parallel with stage 3) | 3 subagents | ~45 min | 0.96 M |

The subagents ran on Sonnet, the article's author on Opus.

## Stage 3: the port to Python

The whole game on `zxpyxel` (`examples/the-hobbit/port/`, 13 modules, ~9,300 lines), with the register interface ([stage3.md](stage3.md), The Hobbit): the registers and flags are shared as on the Z80, because the game's routines pass values through long chains of callers. The lead wrote `main.py`, the registers, the indirect calls and a contract of all 400 routines (240 async); eight subagents (Sonnet, 1.5 million tokens, 6-27 minutes each) ported the modules in parallel. From the export to `make port-test` passing: under an hour.

`make port-test` matches the Z80 in all game memory at every main-loop pass of the six records (536 passes); the port's clock runs 4.5-7.4% fast. Two inputs are not keys: R seeds the random numbers (`zx.r()`), and the random routine mixes in a byte from anywhere in memory, the stack included, which the record gives (`zx.take`, `PORT_TAKE`).

## Stage 4: clean logic

The interview: pictures as editable command text, with PNG previews made from it; the Spectrum's screen kept byte for byte; input as the original (the line editor, the idle WAIT); silent, as the original. The lead's defaults: SAVE and LOAD use a file, PRINT a transcript.

The same game as plain Python (`examples/the-hobbit/game/`, the `hobbit` package, ~6,800 lines): records by id, messages, handlers and scripts by name, the whole game one generator whose requests (a key, R, a saved state, a printer) the oracle answers from the record and the pacer from the host ([stage4.md](stage4.md), The Hobbit).

| Step | Who | Time | Subagent tokens |
| --- | --- | --- | --- |
| state, decoder, oracle, registry, assets loader | lead | ~25 min | |
| wave A: text, world | 2 subagents (Opus) | ~50 min | 0.65 M |
| flow, pacer, host | lead | ~15 min | |
| wave B: engine, verbs, parser and special words, handlers | 4 subagents (Opus) | 40-60 min of work each | 1.25 M |
| integration, free play, docs | lead | ~1 h | |

The five agents still running overnight stalled (a watchdog stopped them between tool calls); they were resumed and finished.

The game check: identical to stage 3 at every pass of the six records, the screen included (536 passes). Free play types random commands through the pacer: 30,000 frames in 1.6 s. Integration found one bug in the game (a routine returned True, False or QUIT's flow target, and its caller took the target for a parsed line) and the rest in what the records do not vary: the pacer's answers (the title key, LOAD without a save, the printer, the idle WAIT 28% slow and not restarted per line, now measured on the Z80) and two values kept between lines outside the compared state. Not built: the time the original takes to draw a picture (about 7 s for Bag End; stage 4 shows it at once) and the fixed mode.

## Comparison with the existing work

After the run, the result was compared with jonsole's complete SkoolKit disassembly of 1.2 (2026), pobtastic's partial one (2023), basf-c60's disassembly of 1.0, 6elphegor's C port (2026), Icemark's format notes, Wilderland and Megler's own account of the design: [`examples/the-hobbit/re/comparison.md`](../examples/the-hobbit/re/comparison.md), with three detailed reports. Three reviewers (two Opus, one Sonnet; 0.94 million tokens, about 35 minutes) settled each disagreement with the code or a run.

- **Structure.** Against jonsole's: 4 bytes differ (a wrong address on one line of our skool), code and non-code agree on 99.8% of the bytes, 307 code entries are shared; the 62 only jonsole has are labelled points inside our entries.
- **Meaning.** Of 506 entries both describe, 474 say the same thing; 6 differ, jonsole right in all. The worst: our weight and size fields are swapped, from the annotation through stage 4, and every check passed, because names are not checked. 24 of our entries, 2,185 bytes of handlers, are left generic where jonsole names about 60 handlers.
- **Formats.** The same almost everywhere. Ours is wrong or stale on eight facts, a reference on six; our one open item (object flag bits 2 and 4) is answered: "full" and "on".
- **Bugs.** Of 50 items the references name that hold in 1.2, the run found 30, partly 3, missed 17: sequences no script typed, the crashes fuzzing finds, and things read but not recognised (FILL never works; "You are in in a clearing" was on a screen of our own run). 14 of our findings are in no reference.
- **Ports.** The C port made the same choice for its faithful edition, the Z80's register interface, and goes further: it reproduces the stack bytes the random generator reads, so it matches the original without a record; ours is identical in replay. Its clean edition fixes the bugs behind a switch; ours is faithful and moves the data into editable files.

## What the run got wrong, and what changed

The example stays as the run left it; the harness learns instead.

| Stage | Slip | Why it got through | Changed |
| --- | --- | --- | --- |
| 1 | coverage stopped at 85% with hand-written scripts | no lines were generated from the game's vocabulary; one key was never pressed | `zx-coverage`: generated command lines over many seeds, every key once |
| 2 | two record fields named the wrong way round (weight, size) | named from how they are summed; no check reads a name | `zx-annotate`: name a field from the message its failed test prints |
| 2 | about 60 handlers left in 24 generic entries | handler-table targets merged into blocks | `zx-annotate`: every handler-table target is an entry |
| 2 | a routine's trigger guessed from a table's layout | no run with and without the input | `zx-annotate`: a trigger claim needs both runs |
| 2 | a wrong address on one skool line | the build ignores skool addresses: IDENTICAL anyway | `zxq.py asm` checks every address against the instruction before it |
| 2 | article claims beyond their evidence (an unused control code, free word order, a trap with no escape) | written from some cases | `zx-document`: "never", "unused", "any" need every case |
| 2 | unknowns left in notes and comments after findings answered them | no closing pass | `zx-document`: change every place that states an answered unknown |
| 2 | 17 of 50 known bugs missed | no command sequences, no check of patterns against handlers, screens of own runs not read | `zx-document`: bug hunt over sequences, patterns, screens, what a new game keeps |
| 3 | a handler's test inverted in the port | 70 routines no record ran, and nothing else checked them | `zx-port`: the never-ran list is part of the gate; cases at the call |
| 3 | the port identical to the original in replay only | the random byte from the stack taken from the record, unstated | `zx-port`: choose, and say which in the contract |
| 3, 4 | bugs kept as quirks in code comments, not findings | slices reported them, the lead did not register them | `zx-port`, `zx-clean`: a kept quirk is a finding |
| 4 | four pacer faults found at the very end | the pacer was written early and first run at integration | `zx-clean`: the pacer and free play before the slices |
| 4 | values kept between lines outside the state | a dict and an attribute of `Game` held them | `zx-clean`: such values are state, buffers included |
| 4 | the picture drawing time left out | no measurement asked for it | `zx-clean`: Shows measured on the Z80, or a named deviation |
| all | five agents stalled overnight until the author said "retry" | the lead waited for notifications | `AGENTS.md`: resume a quiet agent; size tasks under an hour |

## Lessons for the method

1. The genre changes the shape, not the method: the same phases, checks and orchestration carried a text adventure through, with two new shapes (the register interface, the game as one generator).
2. A recorded run checks the game, not the host. What the pacer answers (keys, files, a printer, time) needs its own checks: free play, and each time constant measured on the Z80 rather than counted from the loops.
3. Opus slices for stage 4 took about 0.3 million tokens each, 1.7 times Sonnet's stage 3 modules; their reports found real gaps (a stage 3 bug in a handler no record reaches, the state fields the parser needed, F85's endless message).
4. The comparison: name a field from the message its test prints; every target of a handler table is an entry of its own; the bug hunt needs sequences of commands (fuzzing from the vocabulary), a check of every command pattern against the handlers, and a reading of every screen of the recorded runs.
5. Holes in the kit found and fixed along the way: typed text and the screen as text in `zxrun.py`; R and taken values in records; runs of repeated reads compressed; a random routine that reads code in the shift test (`SHIFT_GIVE`) and in the port (`PORT_TAKE`); `zxdiff.py` flag outputs; `zxpyxel.display` byte and pixel access.
