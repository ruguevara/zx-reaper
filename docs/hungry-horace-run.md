# Hungry Horace: a run of the method and a comparison with SkoolKit

Russian version: [hungry-horace-run.ru.md](hungry-horace-run.ru.md).

A full run of the [method](method.md) on Hungry Horace (Psion/Melbourne House, 1982), with the result compared against Richard Dymond's reference disassembly (skoolkit.ca, version 2026-04-10). The reference was downloaded into a separate folder and not opened until annotation was finished; subagents were forbidden to search for other people's disassemblies.

## Result

- Sources: 13 asm modules (4,454 lines), 2 BASIC programs, `src/constants.asm`, a tape manifest. `make` builds a TZX tape byte-identical to the original, including both BASIC programs and the tape pauses.
- 106 entries, 100% annotated, 166 labels; every routine has a title, a description, registers and a `Hardware:` line.
- "Magic numbers" in the asm: 4 16-bit and 34 8-bit literals (the raw disassembly had 679 and 266). The 8-bit ones left are mostly row numbers and indexes in expressions (`ATTRS+5*SCREEN_COLS`).
- Relocatability is proven: code assembled at shifts of +$7, +$101 and +$1234 matches the original frame by frame on two scenarios (the demo, 3,000 frames; a game, 4,000 frames).
- Graphics: 15 PNGs from the game's bytes; the maze maps and the title were drawn by the game's own routines through `zxrun.py --call`.
- The article, in the [ZX-REAPER](../README.md) repository, [`examples/hungry-horace/docs/`](../examples/hungry-horace/docs/README.md): 14 files, ~17.6 thousand words, 849 relative links to the sources (all checked), diagrams of the main loop, tables of the structures, an analysis of the guards' AI with a worked example, a gallery of 17 pictures, notes for porting to C/Python.
- The sources are there too, in `examples/hungry-horace/`, without the tape; put the tape into `original/game.tzx`, then run `make restore` and `make`.

## Time and tokens

| Stage | Who | Time |
| --- | --- | --- |
| init, coverage 92%, data classification | script + lead | ~15 min |
| wave 1: 26 leaf routines | 4 subagents in parallel | ~13 min |
| wave 2: 10 mid-level routines | 3 subagents | ~11 min |
| wave 3: main loop, death, variables, data | 4 subagents | ~12 min |
| integration, constants, shift test, export | lead | ~5 min |
| article with gallery (stage 6) | 1 subagent (Opus) | ~24 min |

Annotation subagents (Sonnet): ~1.58 million tokens over 11 runs, 100–180 thousand per group; the article's author, another ~0.32 million. Human: no actions beyond setting the task.

## Comparison with the reference

Tool: `tools/zxcompare.py ours.skool hh.skool --pairs pairs.tsv` (in ZX-REAPER).

**Bytes.** The code is identical. 63 bytes differ in $6DB6–$6E8E, because the reference zeroes the variable buffers with a `@defs` directive, while ours hold the values loaded from the tape. It is the same version of the game.

**Classification by byte:**

| ours \ reference | code | text | data | variables | unused |
| --- | ---: | ---: | ---: | ---: | ---: |
| code | 3386 | 0 | 0 | 0 | 0 |
| text | 0 | 123 | 0 | 0 | 0 |
| data | 0 | 0 | 4305 | 172 | 7 |
| variables | 0 | 0 | 0 | 103 | 0 |

Code vs non-code: a 100% match. The differences: the four guard records (172 bytes) are "data" in ours and "variables" in the reference; 7 bytes of dead code are "data" in ours and "unused" in the reference.

**Routine boundaries:** 40 of 41 are shared. The reference makes the main loop at $6229 an entry of its own (ours has it as the label `MainLoop` inside `Start`); we split off the dead tail of a loop, $672F.

**Meaning.** The names of all 40 shared routines and of all the variables describe the same things; they differ only in wording: `UpdateFruitDrops` / "guard drops his lunch", `BellTimer` / "guard panic timer", `HoraceDir` / "animation frame (0-3)" (the direction selects the frame). Examples:

| Address | Ours | Reference |
| --- | --- | --- |
| $63DA | `ChooseGuardMove` | MVGUARD: Move a guard |
| $6C20 | `GetBlockObject` | CHKATTRS: Check the attribute bytes at a sprite's location |
| $6C68 | `SaveBackground` | CPMAZEBG: Copy maze background tiles into a guard's buffer |
| $6D4E | `DrawBlocks` | BIGWORD: Print 'HUNGRY' or 'HORACE' on the title screen |
| $7C64 | `UnusedAiCounter` | TEMPVAR: Redundant temporary variable |

**Bugs of the original game:**

| Reference bug | Found? |
| --- | --- |
| Broken guard counter (`OR C` instead of `OR E` at $697F) | yes, including the fix: the reference's POKE 27007,179 is `OR E` |
| Free extra life | the symptom found (an extra life at the start), the cause explained differently |
| Game slowdown on the 29th maze | not during annotation; found and checked at the article stage (the delay goes negative at speeds 1–3) |
| How many lives? (10 lives print as ":") | not during annotation; in the article as a guess; confirmed by calling `ShowScore` directly (F14) |
| Who ate my lunch? (a guard picks up another guard's items) | no |

Found beyond the reference (checked in the simulator): a 2-byte stack leak on every exit from the demo (on the 63rd exit the stack overwrites code, on the 70th the game crashes); a "fleeing" guard can turn towards Horace because an unsigned score byte overflows; eaten guards come back in Horace's start cell; a step of 1 byte instead of 2 when `CheckGuardContact` walks the timers; dead code ($6A17, $672F, a guard's turn when the bell rings). The article's author found two more, also checked: at speeds 1–3 the `PaceAndChime` delay goes negative, and the game freezes for about 25 frames every fourth pass; a bell that overlaps Horace from above or diagonally scores 50 points on every pass.

Facts from the reference: the T key toggling the sound, the keys 1-2-3-4, the speed-up after every 4th maze: found; the fruit bonus depending on the direction: partly found.

**Documentation style:**

| | ours | reference |
| --- | ---: | ---: |
| words in headers and block comments | 17,424 | 2,784 |
| words in instruction comments | 2,027 | 7,621 |
| code instructions with a comment | 18% | 60% |
| entries with a register section | 30 | 18 |
| literals ≥ 256 in the asm | 4 | 66 |
| literals < 256 (other than 0/1) in the asm | 34 | 254 |
| relocatability | by default | only in `skool2asm -r` mode |

The reference is line-by-line comments and separate pages (bugs, facts, POKEs, sound). Ours is long descriptions of routines and data, named constants instead of numbers, and a source ready to be shifted and ported.

After the article stage and a pass over the register, one of the reference's five bugs is still not found: "Who ate my lunch?". It stands in `re/findings.md` as `unknown` (F22). The findings register: 18 observed, 3 inferred, 2 open, 1 refuted claim.

## Stage 3: the port to Python

The whole game on `zxpyxel` (`examples/hungry-horace/port/`, six modules, ~1,100 lines). The order of work is in the `zx-port` skill, the design in [port.md](port.md).

| Step | Who | Time |
| --- | --- | --- |
| recording a run and replaying it (`zxrun.py --record`, `headless.replay`), `zxdiff` for the port, `make port-test`, `main.py` | lead | ~1 h |
| library, guards: 14 routines, tests | 1 subagent (Sonnet), 137 thousand tokens | ~9 min |
| movement, sprites, events in parallel against a contract | 3 subagents (Sonnet), 293 thousand tokens | ~5 min |
| integration | lead | ~10 min |

The very first run of the integrated port matched for 2,147 passes of the main loop and stopped at FRAMES. The ROM's BEEPER returns with interrupts enabled, and the game's `DI` is the next instruction. Once in a few thousand bell chimes the Z80 has time to take an interrupt there; its handler counts FRAMES, and the guards' AI reads FRAMES as a random number. The record now marks the interrupts of the ROM handler, and the replay calls the port's handler at the same place. After that: the demo, 2,384 passes; play, 5,536; random play with the bell, an eaten guard and an exit, 15,567; all byte-identical. The port's clock runs 1.3–2% fast against the Z80. The port's code was never fixed.

What the subagents found hard, now in the skill or the tools: read a routine's inputs from the instructions, not from the header (an `E'` in the header can be E after the caller's EXX); flags and unused registers in the test cases; how to split T-states between a routine and its callees (`zxdiff.py --tstates`); a screen comparison flooding the output (only the differences are printed now); a word written as a byte (`mem16`, `v`).

## Stage 4: clean logic

The same game as plain Python (`examples/hungry-horace/game/`, the `horace` package, ~900 lines). The order of work is in the `zx-clean` skill, the decisions in [stage4.md](stage4.md).

| Step | Who | Time |
| --- | --- | --- |
| state, `world.py`, the bridge (`bridge/`: decoder, data, oracle), `flow.py`, rendering, sounds, host | lead | ~1.5 h |
| movement, sprites, events in parallel against a contract | 3 subagents (Sonnet), 194 thousand tokens | 5–14 min |
| integration: the game step by step | lead | ~10 min |

Every call of the 17 stage 3 routines on the three records gives the same state, the same transition and the same sounds in the stage 4 version. The game matches step by step at every step (demo 2,664, play 5,544, bell 15,576), and the screen through `zxpyxel.display` is byte-identical. No code was fixed after integration. Two errors were in the bridge and in the contract. The oracle collapsed repeated sounds across a whole step, so a second chirp in the same step dropped out of the routine check (two subagents found this independently). The contract did not specify the data of the sound effects, so the noise and the chime arrived in the wrong shape; the free-play run caught it.

The world model: the game's rules read the screen (collisions go by a cell's colour; a guard keeps the cells under it, which is how fruit appears). So the state holds a 32×24 grid of cells, each with a glyph and an attribute. That grid is the game's real world; rendering only copies it to the screen.

## Lessons for the method

1. A single run is as accurate in meaning as the reference, which a human has been refining since 2014: names and purposes matched wherever both sides named something.
2. The weak spot is bugs that show only at the edges: a long game, two-digit counters, two guards interacting. A separate "bug hunt" pass is needed: for each counter, what happens at its minimum, its maximum and on overflow; a simulator run with substituted values (`--poke` lives = 9, maze number = 28, speed = 1).
3. There are few line comments (18%). If the reference's style is wanted, raise the bar in `zx-annotate` ("a comment on every instruction that means something in terms of the game"). Porting to C does not need it: long descriptions are more useful.
4. Holes in the kit found and fixed along the way: `@equ` before `@start` was silently ignored; subagents named game variables with `@equ` (this breaks relocation), and now `equs --consolidate` turns them into labels; a bare `;` line inside a description breaks skool2asm, so the skill got the rule `; .`; one subagent ran `rm -rf re/skool` and restored it from a copy, so the skill now forbids touching shared files.
