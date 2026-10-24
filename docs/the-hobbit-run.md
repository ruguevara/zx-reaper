# The Hobbit: a blind run

Russian version: [the-hobbit-run.ru.md](the-hobbit-run.ru.md).

A run of the [method](method.md) on The Hobbit (Philip Mitchell and Veronika Megler, Beam Software, Melbourne House, 1982), version 1.2, from the tape to stage 4. The game was chosen to be unlike Hungry Horace: a text adventure with a parser, characters that act on their own, timers, and pictures drawn from command streams. The run was blind: no disassembly or write-up of the game was read, and the subagents were forbidden to search for them. The author set the task, answered the stage 4 interview, and said "retry" once when the agents stalled. The comparison with the existing work comes after the run and is not done yet.

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

## Lessons for the method

1. The genre changes the shape, not the method: the same phases, checks and orchestration carried a text adventure through, with two new shapes (the register interface, the game as one generator).
2. A recorded run checks the game, not the host. What the pacer answers (keys, files, a printer, time) needs its own checks: free play, and each time constant measured on the Z80 rather than counted from the loops.
3. Opus slices for stage 4 took about 0.3 million tokens each, 1.7 times Sonnet's stage 3 modules; their reports found real gaps (a stage 3 bug in a handler no record reaches, the state fields the parser needed, F85's endless message).
4. Holes in the kit found and fixed along the way: typed text and the screen as text in `zxrun.py`; R and taken values in records; runs of repeated reads compressed; a random routine that reads code in the shift test (`SHIFT_GIVE`) and in the port (`PORT_TAKE`); `zxdiff.py` flag outputs; `zxpyxel.display` byte and pixel access.
