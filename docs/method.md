# A method for reverse engineering ZX Spectrum games with an agent

Russian version: [method.ru.md](method.ru.md).

The task: take the original tape (TAP/TZX) and produce a folder of sources (asm, BASIC, data, a tape manifest, a Makefile, scripts) that builds into a tape **byte-identical** to the original and that a person can read. Spend as little human time, time in general and tokens as possible.

This document is the method. The agent harness (the tools, the project template with `AGENTS.md`, the skills, the self-test and the reference run on Hungry Horace) lives in this same repository, [**ZX-REAPER**](../README.md) (Retro Engineer Anything, Port Everywhere Rightnow). Tool paths below (`tools/…`, `template/…`, `selftest/…`) are relative to its root.

## Key decisions

1. **A green build first, understanding later.** SkoolKit's automatic disassembly builds back into the same bytes straight away. So from the first minute the project gives `make` → `IDENTICAL`, and all further work is refactoring under test: renames, comments, code/data classification. A classification mistake does not break the byte match; it only hurts readability. The next `make` catches a typo in a directive.
2. **Scripts do the mechanics, the model does the meaning.** Splitting the tape, loading, coverage, classification from the execution map, building and comparing are deterministic programs. The model spends tokens only on names, descriptions, decisions about data formats, and protected loaders.
3. **The simulator instead of reasoning.** Questions such as "who writes to $5C00", "what is on the screen at frame 200" or "when is this routine called" are cheaper to put to the simulator than to work out from the code. The answer is a couple of lines or a PNG.
4. **One SkoolKit entry, one file.** An agent reads and edits exactly one routine. Subagents work in parallel without conflicts. A rename is one `@label=` line: operands in the skool stay numbers and become labels at build time, so references need no updating.

## Levels of the result

| Level | What it means | How it is checked |
| --- | --- | --- |
| L0 | the memory image matches | `make` (SAVEBIN of the blocks = the tape payload) |
| L1 | the tape matches byte for byte, BASIC, headers and TZX blocks included | `make` → `IDENTICAL` |
| L2 | code and data are separated, everything is named and described | `make status`: 100% annotated |
| L3 | the source is relocatable: insert a byte and the game still works | `make shift-test` (code at address +SHIFT, screen and sound compared frame by frame) |
| L4 | exported to asm modules, no "magic numbers", data formats described | `make export`, `make test`, `make labels` is empty |
| L5 | an article on how the game works, with a graphics gallery and level maps | `docs/`, links to the sources resolve |

L1 comes automatically for standard tapes. L2–L4 are the agent's work.

## Tools and why these

**SkoolKit** (Richard Dymond) is the base. `tap2sna.py` simulates a real load, turbo loaders included (Speedlock, Alkatraz, Bleepload and ~50 other fast loaders). `sna2ctl.py` marks code from an execution map, `sna2skool.py` writes the disassembly, `skool2asm.py` writes assembler with labels, and `skool2html.py` writes browsable documentation. The skool format keeps the address on every line, and directives (`@label`, `@isub`), so edits stay local. SkoolKit 9–10 has a fast Z80 simulator in C with port hooks and a per-frame callback; the runner is built on it. Ghidra and IDA know nothing of Spectrum loaders and give no source that builds; z80dasm does no classification and no labels.

**The assembler is sjasmplus.** `DEVICE ZXSPECTRUM48` with `SAVEBIN` cuts the tape blocks straight out of memory, and it has `DISP`, `ALIGN`, macros, and `-D` for the shift test. pasmo also builds the output of skool2asm byte for byte (tested), but it has no device and no SAVEBIN.

**Emulators:**

| Where | What | Why |
| --- | --- | --- |
| the agent's inner loop | the SkoolKit simulator through `zxrun.py` | headless, deterministic, 30–40 times faster than real time (measured: 60 s of a game with the CPU fully loaded in 1.6 s, with the map and hashes), scripted input, execution map, watchpoints |
| a person plays | Fuse | recording RZX to cover the late levels |
| timing checks | ZEsarUX (the ZRCP protocol over TCP) or MAME (Lua) | multicolour, border effects, 128K: where a simulator without memory contention is not accurate |

The RZX Archive often has finished playthroughs; then the person does not need to play at all. `rzxplay.py --map` turns an RZX into a coverage map.

**Our own utilities** (in the kit, all tested):
- `zxtape.py`: TAP/TZX ↔ a text manifest + payload files. It rebuilds byte for byte, including turbo blocks, pauses, non-standard checksums and TZX text blocks.
- `zxbasic.py`: lossless BASIC ↔ text: hidden numbers (`CLEAR 0\#=24999`), colour codes, machine code in REM, wrong line lengths, the variables area. Every line is checked by tokenising it back; 3000 random programs made the round trip without a difference.
- `zxrun.py`: runs a snapshot. Keyboard and Kempston from a script or at random, an execution map, per-frame hashes of the screen, sound and RAM, screenshots, a snapshot dump, a write watchpoint (with the address of the instruction), loading a binary at another address for the shift test. The C and Python simulators give the same hashes.
- `zxq.py`: the agent's interface to the disassembly: `show`, `refs`, `next` (the "dependencies first" queue), `status`, `unexec`, `peek`, `strings`, `gfx` (bytes → PNG), `reclassify` (reclassify a range with a ctl fragment), `export` (asm modules).
- `zxinit.py`: from a tape to a green project in one command.

## Pipeline

| Phase | Who | What happens | Done when |
| --- | --- | --- | --- |
| 0. Init | script | `zxinit.py game.tap game-re/`: the tape split, a simulated load → `re/orig.z80`, the image at the moment of loading → `re/image.z80`, BASIC → `src/loader.bas`, the screen → `data/`, 6000 frames of random input → map, `sna2ctl` + `sna2skool` → `re/skool/`, `src/build.asm`, `tape/tape.txt` | `make` → `IDENTICAL` |
| 0a. Loader | lead agent (+ a person if the tape is protected) | non-standard tapes only: the point where control passes to the game, the addresses of headerless blocks, the decrypter → `scripts/encrypt.py` | `make` → `IDENTICAL`, every block in `re/notes.md` |
| 1. Coverage | lead agent, a person if they like | input scripts made from screenshots, fuzz with the game's real keys, RZX | two new scripts in a row add < 1% |
| 2. Classification | lead agent | `unexec`, `strings`, `gfx`, `refs`, watchpoints → ctl fragments → `reclassify`; a memory map | no data disassembled as code |
| 3. Annotation | subagents on a cheap model | batches of 5–15 entries from `zxq.py next`, leaves of the call graph first; the lead collects them, `make`, commit | `status`: 100% |
| 4. Relocation | lead agent | `make labels`, `@label`/`@isub`, address tables as `W`, self-modifying code through a label on the instruction | `shift-test` passes at a shift of 0x100 and at an odd one |
| 5. Export | lead agent | `re/modules.txt` → `make export` → `src/*.asm`, README | `make`, `make test`, `make shift-test` green |
| 6. Documentation | lead agent + subagents per section | an article in `docs/`, top down: overview, data structures, menu, game loop, subsystems, non-obvious parts and hacks, porting to another platform; a PNG gallery: sprites, tiles, title screens, maps of all levels | all sections present, every routine of the main loop mentioned with a link, links resolve |

The annotation order is "dependencies first": a routine is described once its callees are named, and data once the routines that read it are named. Then `zxq.py show` prints the neighbours' names next to the code, and the agent does not need to read them again.

## No "magic numbers"

The goal is a source that can be ported to C or Python with a library that emulates the Spectrum hardware. So no bare numbers may remain in the asm:

- **Addresses outside the game** (ROM, system variables, the screen): `@equ` in `head.skool`. SkoolKit puts this name in place of every 16-bit operand with the same value, counters included (`LD BC,$4000`), so `zxq.py equs --uses` shows every substitution and `@keep` undoes the false ones.
- **Numbers** (sizes, colours, keyboard masks, tile codes, directions): `src/constants.asm` through `zxq.py const` (it locks the file, so it is safe for parallel agents) and `@isub=LD (HL),CYAN*PAPER+BLACK`.
- **Addresses inside the game**: only `@label`, not `@equ`. A label moves with the code; `@equ` nails the address down. `zxq.py equs --consolidate` turns such `@equ`s from subagents into labels by itself.
- **Self-modifying code**: a label on the instruction that changes, and the write as `Label+1`.
- The description of every routine has a `Hardware:` sentence on the hardware it touches: screen, attributes, ports, ROM, timings. This is the list of what the platform library will replace.

## Documentation (phase 6)

The work ends not only in a source but also in an article in `docs/`, at the level of a good post on Habr: a `README.md` with a table of contents and a separate file per section, relative links to the code (`../src/screen.asm#L120`), tables of structure layouts, Mermaid diagrams of the loop, and an honest "verified / inferred" mark.

The pictures are made from the game's bytes, not drawn:
- `zxgfx.py sheet`: sprite and tile sheets in the attribute colours the game uses;
- `zxrun.py --call ADDR --reg HL=... --png`: calls the game's own drawing routine in the simulator and saves the screen. This gives level maps and title screens exactly as the game draws them;
- `zxrun.py --input ... --shot`: frames from the game.

The commands that make them are in `docs/img/Makefile`, so the pictures can be rebuilt. The procedure is the `zx-document` skill.

Before the section on bugs comes a separate "bug hunt" pass at the edges: for every counter and timer (lives, level, speed, score digits), what happens at the minimum, at the maximum and on overflow, checked in the simulator with `zxrun.py --poke`. The comparison with the reference on Hungry Horace showed that annotation without this pass misses exactly these bugs: [Hungry Horace: a run of the method and a comparison with SkoolKit](hungry-horace-run.md).

## Evidence, questions, per-routine checks

Three techniques are borrowed from [REA](https://github.com/morluto/rea) (an MCP for reverse engineering modern programs) and the reconstructions made with it (DX-Ball: a C function checked on 3205 cases against the original x86):

- **The question list** (`re/questions.md`): at init, 17 standard questions for any game (loading, memory map, controls, loop, AI, score, lives, levels, formats, random numbers, sound, hardware, counter edges, unexecuted code, bugs), extended for the game. Before the article each one is marked answered / partial / open; `make audit` shows the ones not closed.
- **The findings register** (`re/findings.md`): every claim the work relies on, with its evidence and a status: `observed` (seen in the simulator, in a test, by a byte check), `inferred` (read from the code), `unknown`, or `refuted` (disproved; it stays in the register). Only a run makes a claim observed. Negative claims are limited: "not executed on these inputs", not "dead code".
- **Differential tests of routines** (`zxdiff.py`, the `zx-port` skill): a Z80 routine runs in the simulator on cases generated by kind (`typical`, `boundary`, special inputs), and its registers and memory are compared with a Python model. The model checks the annotation. The same scheme serves a port to Python, and `--dump` writes golden input/output pairs for a port to C. Boundary cases find bugs more often than random ones (on a model of `StepCell` with a planted bug: 3 of 48 boundary cases against 1 of 400 random ones). The per-routine status is in `tests/models/STATUS.md`.

Smaller things from the same source: `zxdoctor.py` (it checks the tools and the state of the project and gives the command that fixes a problem), and the tape and its copies kept out of git, with `make restore`.

On Hungry Horace this paid off at once: a direct call of `ShowScore` checked two things. It confirmed the bug "10 lives print as `:`" and refuted the annotator's claim that `ShowScore` does not use HL (in fact it prints exactly HL). The refuted claim stayed in the register as `refuted`.

## Stage 3: a Python port

The port runs on `zxpyxel`, a library that stands in for the 48K machine the game runs on (memory, T-states, port $FE, interrupts), on top of Pyxel. Its design and the reasons for its decisions are in [port.md](port.md); the way to work is the `zx-port` skill.

- **The asm's shape survives.** Memory is the same 64 KB at the same addresses, a routine is a function named after its label, and registers are arguments and results. A variable is `v.Score`, with the width from its declaration in the asm (DEFB, DEFW, a table; `variables.py` is generated from the sources). A computed address is `mem[a]` (a byte) and `mem16[a]` (a word). All three are the same memory and wrap round as on the Z80. A word cannot be written as a byte by mistake, and at stage 4 `v` moves into a Python object without editing the routines.
- **The CPU is not emulated.** Time is a T-state counter that the port keeps itself (`zx.spend`; `zxdiff.py` gives the figures). Waiting and blocking sound are `await`. A jump that drops the return address is `raise Goto(...)`.
- **Checking a routine**: `zxdiff.py` with a `port(regs)` function, on the same generated cases as for the annotation models.
- **Checking the whole game**: a replay of a Z80 run (`make port-test`). `zxrun.py --record` writes, in order, every value the game's IN read, the interrupts of the ROM handler, and the memory state at every pass of the main loop (the first in full, then the changes). The port gets the same input values and compares memory at the same point. Input is matched by the order of reads, not by frame, so the port's T-states need not match; the clock drift is a separate figure. The first difference is reported as bytes named by label and by screen cell.
- **Roles.** The lead writes the control flow (`main`) and the contract. Subagents on a cheap model port the modules: the leaves first, then the rest in parallel against the contract (signatures, which routines are `async`, where each `Goto` goes).

## Stage 4: clean game logic

Stage 3 is rewritten as plain Python: state made of simple values (positions are a column and a row; no addresses, registers or T-states), routines that read as rules, and sound and time as events. The look stays the Spectrum's: 32×24 cells, attributes, the ROM font through `zxpyxel.display`. The decisions are in [stage4.md](stage4.md); the way to work is the `zx-clean` skill.

- **Stage 3 is the oracle.** It already matches the Z80, so stage 4 is checked against it, not against files. Stage 3 replays a recorded run, every call of one of its routines is decoded into stage 4 state before and after, and the stage 4 routine must turn the one into the other. Every call in the recorded runs is a test case. Slices are checked independently, with nothing substituted from neighbouring slices.
- **The game step by step**: the same player actions at every step (a pass of the title loop or of the main loop), the same state and the same sounds. The screen drawn through `zxpyxel.display` is byte-identical to the stage 3 screen.
- **Where the work was on Hungry Horace**: not in the API but in the model. The rules read the screen (collisions go by the colour of a cell, a guard keeps the cells under it), so the grid of cells with glyph and attribute is part of the state.

## The agent harness

- `AGENTS.md` at the project root (`CLAUDE.md` contains `@AGENTS.md`): one rule (`make` green after every edit, commit only when green), the layout, a command cheat sheet, token discipline, naming conventions, when to call the person. About 100 lines; it is read in every session.
- Skills (`skills/`, symlinked as `.claude/skills`): `zx-init` (loaders, encryption and headerless blocks included), `zx-coverage`, `zx-classify`, `zx-annotate`, `zx-relocate`, `zx-export`, `zx-document`, `zx-port`. Each is a procedure with a done criterion, and each is loaded only when needed.
- Roles: a lead agent on a strong model (plan, loader, classification, relocation, review of names); subagents on a cheap model only for `zx-annotate`, each given a list of files. One file per entry rules out conflicting edits.
- State between sessions lives in git and `re/notes.md`; `make status` and `zxq.py next` tell where the work stopped. Long work can run in a loop (`/loop`): "take the next batch, annotate, `make`, commit".

## Saving tokens

- Never read a whole skool, asm, lst, map or trace. Only `show`/`refs`/`grep -l`/`head`.
- Look at graphics as a picture (`gfx`, `--shot`), not as a list of DEFBs: one PNG instead of hundreds of lines.
- Reclassify with a ctl fragment of 5–10 lines, not by rewriting a hundred lines of skool.
- Put questions about behaviour to the simulator (a watchpoint, `--stop`, a screenshot of a frame).
- Comment only where the intent cannot be seen from the code.
- Check the exit code of `make`, not its output.

An estimate for a 40 KB game (not a measurement): 600–1200 entries; annotating an entry takes 3–8 thousand input tokens, mostly from the cache, and 200–500 output tokens. That is a few million input tokens for the whole game, mostly on the cheap model.

## Human time

1. Provide the tape (and an RZX, if the archive has one): minutes.
2. Sometimes play for 10–20 minutes in Fuse, recording an RZX, when coverage stalls short of the late levels.
3. Decide how far to reproduce the loader's protection.
4. Spot-check the names after annotation, read the README.

In total, about an hour per game without protection.

## What has been tested

On the test game `selftest/demo.asm` (movement on QAOP/Kempston, a jump table, a self-modifying counter, text with bit 7 set, a BASIC loader with hidden numbers), `selftest/run.sh` goes the whole way. Init gives `IDENTICAL` at once (through sjasmplus and pasmo); `make test` matches for 300 frames; the shift test first fails on the jump table written as DEFB and on the operand of a self-modifying instruction, and after two ctl fragments and two `@isub`s it passes at shifts of 0x100, 0x1234 and 0x300; export to modules gives `IDENTICAL` again. Separately: TAP and TZX (standard, turbo, pure data, comment, pause) make the round trip through the manifest byte for byte, and `tap2sna.py` loads the built TZX.

### First run on a real game: Horace Goes to the Tower

[Horace Goes to the Tower](https://spectrumcomputing.co.uk/entry/26600/ZX-Spectrum/Horace_Goes_to_the_Tower) (The Mojon Twins, 2011): 48K, freeware, a standard tape (BASIC, a screen, 31766 bytes of code from address 25000); the authors have published the C sources (z88dk + splib2). The sources are valuable as a reference: the function names in `engine.h` and `horace.c` can be compared with the names the agent comes up with.

`zxinit.py` gave `IDENTICAL` in 7 seconds: 429 entries, 66% of instructions executed in 6000 frames of random input, and the random input reached the game screen. The run found two bugs in the kit; both are fixed:
- `skool2asm` writes the undocumented registers as `IXl`/`IXh`, which sjasmplus does not accept; the Makefile converts them to `IXL`/`IXH`;
- the header of the screen block gave address 32768, but the BASIC loads it with `LOAD "" SCREEN$`, that is, to 16384; now any CODE block of length 6912 is treated as a screen.

Annotation, the shift test and export have not been done on this game yet.

### Full run: Hungry Horace

All phases except the article were done in ~1 hour without a person, and the result was compared with the SkoolKit reference disassembly. Names and purpose match for every routine and variable. The run found the `OR C`/`OR E` bug that the reference documents, and several more that the reference does not have; it missed three bugs that show at the edges. In detail: [Hungry Horace: a run of the method and a comparison with SkoolKit](hungry-horace-run.md).

Stage 3: the whole game is ported to Python (~1100 lines) and matches the Z80 in all of the game's memory at every pass of the main loop on three records: the demo, a game, and 11,000 frames of random play in which the bell is taken, a guard is eaten and Horace leaves through the arrows. 38 routines pass `zxdiff.py` without a difference. The port never needed a fix. The only difference on the first run was an interrupt that the Z80 now and then takes between the `EI` in the ROM's BEEPER and the game's `DI`; recording the interrupts in the run closed it.

Stage 4: the same game as plain Python (~900 lines, the `game/horace/` package) matches stage 3 at every call of 17 routines and at every step of all three records (demo 2664 steps, game 5544, bell 15,576), the screen byte for byte. The lead wrote the state, the world helpers, the flow and the bridge to stage 3; three subagents (Sonnet) ported the modules in parallel from the skill and the contract. Nothing needed fixing after the parts were put together. The only bug was in the oracle (repeated sounds were collapsed across the whole step), and two subagents found it independently. A mode with the original's bugs fixed is not built yet.

### Candidates for further tests

| Game | Why | Rights |
| --- | --- | --- |
| Horace Goes to the Tower | first run, C source available | freeware |
| [Cheril the Goddess](https://spectrumcomputing.co.uk/alt/27991/ZX-Spectrum/Cheril_the_Goddess), [Trabajo Basura](https://spectrumcomputing.co.uk/alt/27128/ZX-Spectrum/Trabajo_Basura) | the same Mojon Twins engine, sources available: tests whether names carry over between games | freeware |
| [BLAM!](https://scattergoodstudios.itch.io/blam) (1992) | a classic in assembler, re-released for free by its author | free, with the author's permission |
| [The Speccies 2](https://spectrumcomputing.co.uk/entry/30028) | a modern game in assembler | freeware; distribute only from the author's site, Spectrum Computing, WoS |
| Manic Miner, Jet Set Willy, Hungry Horace | SkoolKit reference disassemblies exist to compare the classification with | rights unclear: for private testing only, do not publish the tape or the result |

"Freeware" on Spectrum Computing usually means "free, but under copyright": keep the reverse-engineered sources in a private repository, and do not put the tape there.

## Limits

- The runner is 48K only and has no memory contention: the hashes check logic, not cycle-exact effects. 128K (`@bank`, `sna2skool -p`) and timings go through ZEsarUX/MAME.
- Only standard headed blocks are split automatically. Protected loaders are manual work for the agent following `zx-init`; the hardest part is generating a tape with encryption, which needs `scripts/encrypt.py`.
- The shift test does not move code that is copied to a fixed address at start-up: such code is kept in place with `DISP`, or excluded and noted in `re/notes.md`.
- Copyright: do not put `original/` or built tapes into the project repository unless the game is free.

## Links

- SkoolKit: https://skoolkit.ca (documentation on ctl and skool, example disassemblies).
- sjasmplus: https://github.com/z00m128/sjasmplus
- RZX Archive: https://www.rzxarchive.co.uk
- Fuse: https://fuse-emulator.sourceforge.net; ZEsarUX: https://github.com/chernandezba/zesarux
