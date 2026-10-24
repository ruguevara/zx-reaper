# A method for reverse engineering and porting ZX Spectrum games with agents

Russian version: [method.ru.md](method.ru.md).

The task: take the original tape (TAP/TZX) and produce, first, a folder of
sources (asm, BASIC, data, a tape manifest, a Makefile, scripts) that builds
into a tape **byte-identical** to the original and that a person can read;
then the same game off the Spectrum ("Port everywhere"): in Python with the
original's memory layout, as clean game logic, later in C or JS. Every stage
is checked against the one before it, and every stage is a place to stop,
fork and ship. Spend as little human time, time in general and tokens as
possible.

This document is the method and its reasons. The agent harness (the tools,
the project template with `AGENTS.md`, the skills, the `zxpyxel` library,
the self-test and the reference run on Hungry Horace) lives in this same
repository, [**ZX-REAPER**](../README.md) (Retro Engineer Anything, Port
Everywhere Rightnow). Tool paths below (`tools/…`, `template/…`,
`selftest/…`) are relative to its root.

## Key decisions

1. **A green build first, understanding later.** SkoolKit's automatic disassembly builds back into the same bytes straight away. So from the first minute the project gives `make` → `IDENTICAL`, and all further work is refactoring under test: renames, comments, code/data classification. A classification mistake does not break the byte match; it only hurts readability. The next `make` catches a typo in a directive.
2. **Every stage is checked against the one before it, which is its oracle.** The rebuilt tape against the original; the Python port against the Z80, replaying a recorded run; the clean logic against the port, on the same runs. The chain reaches back to the original game, and a stage without its check is not done.
3. **Faithful first, clean later.** The first port keeps the original's memory layout, routine names and quirks, because only a faithful port can be compared byte for byte; it then becomes the oracle for the clean version. Cleaning up and fixing the original's bugs come after, each fix a recorded deviation.
4. **Scripts do the mechanics, the model does the meaning.** Splitting the tape, loading, coverage, classification from the execution map, building, comparing, recording and replaying runs are deterministic programs. The model spends tokens only on names, descriptions, decisions about data formats, protected loaders and the judgement in a port.
5. **The simulator instead of reasoning.** Questions such as "who writes to $5C00", "what is on the screen at frame 200" or "when is this routine called" are cheaper to put to the simulator than to work out from the code. The answer is a couple of lines or a PNG. In a port, the same holds for "what state does this routine leave": the previous stage answers it.
6. **Input by order, not by time.** A port does not run at the Z80's speed. It gets the values the original read, in the order it read them, and the comparison is made at fixed points of the game's loop, so timing never breaks the check; the clock's drift is a figure of its own.
7. **One unit of work, one file.** One SkoolKit entry per file while annotating; one port module per subagent. An agent reads and edits exactly its unit, so subagents work in parallel without conflicts. A rename is one `@label=` line: operands in the skool stay numbers and become labels at build time, so references need no updating.
8. **A contract first, then slices in parallel.** For annotation, for each port and for the documentation, the lead fixes what the parts share (names, signatures, formats, events); subagents then work on one part each, and each part passes its check before the parts are put together.

## Stages and levels of the result

| Stage | Level | What it means | How it is checked |
| --- | --- | --- | --- |
| 1 | L0 | the memory image matches | `make` (SAVEBIN of the blocks = the tape payload) |
| 1 | L1 | the tape matches byte for byte, BASIC, headers and TZX blocks included | `make` → `IDENTICAL` |
| 2 | L2 | code and data are separated, everything is named and described | `make status`: 100% annotated |
| 2 | L3 | the source is relocatable: insert a byte and the game still works | `make shift-test` (code at address +SHIFT, screen and sound compared frame by frame) |
| 2 | L4 | exported to asm modules, no "magic numbers", data formats described | `make export`, `make test`, `make labels` is empty |
| 2 | L5 | an article on how the game works, with a graphics gallery and level maps | `docs/`, links to the sources resolve |
| 3 | L6 | the game in Python with the original's memory layout | `make diff` (routines against the Z80), `make port-test` (recorded runs against the Z80) |
| 4 | L7 | the game as clean logic over plain state, the Spectrum look kept, its data editable | `make game-test` (every routine call and every step against stage 3) |
| 5 | L8 | the clean logic in C or JS | the stage 4 golden runs (planned) |

L1 comes automatically for standard tapes. L2–L7 are the agents' work.

## Tools and why these

**SkoolKit** (Richard Dymond) is the base. `tap2sna.py` simulates a real load, turbo loaders included (Speedlock, Alkatraz, Bleepload and ~50 other fast loaders). `sna2ctl.py` marks code from an execution map, `sna2skool.py` writes the disassembly, `skool2asm.py` writes assembler with labels, and `skool2html.py` writes browsable documentation. The skool format keeps the address on every line, and directives (`@label`, `@isub`), so edits stay local. SkoolKit 9–10 has a fast Z80 simulator in C with port hooks and a per-frame callback; the runner, the routine tests and the recorded runs are built on it. Ghidra and IDA know nothing of Spectrum loaders and give no source that builds; z80dasm does no classification and no labels.

**The assembler is sjasmplus.** `DEVICE ZXSPECTRUM48` with `SAVEBIN` cuts the tape blocks straight out of memory, and it has `DISP`, `ALIGN`, macros, and `-D` for the shift test. pasmo also builds the output of skool2asm byte for byte (tested), but it has no device and no SAVEBIN.

**Pyxel** runs the ports. The Spectrum's 16 colours are its palette, the screen fits its image bank, 50 fps is a setting, and a desktop build or a single HTML page is one command each: what "fork, play, ship" needs. Its weak point is sound (no raw-buffer API: the beeper goes through WAV chunks); another framework replaces only the host module.

**zxpyxel**, our library for stages 3 and 4, is standard-library Python except its Pyxel host, so it runs unchanged in the browser (Pyodide) and headless in tests, and reads line by line as C or JS. It stands in for the 48K machine (memory, a T-state clock, port $FE, interrupts, a replay of a recorded run), and gives games that are not ports a display that keeps the Spectrum's look without addresses, and PNG in and out.

**Emulators:**

| Where | What | Why |
| --- | --- | --- |
| the agent's inner loop | the SkoolKit simulator through `zxrun.py` | headless, deterministic, 30–40 times faster than real time (measured: 60 s of a game with the CPU fully loaded in 1.6 s, with the map and hashes), scripted input, execution map, watchpoints, recorded runs |
| a person plays | Fuse | recording RZX to cover the late levels; the original next to a port, by eye and ear |
| timing checks | ZEsarUX (the ZRCP protocol over TCP) or MAME (Lua) | multicolour, border effects, 128K: where a simulator without memory contention is not accurate |

The RZX Archive often has finished playthroughs; then the person does not need to play at all. `rzxplay.py --map` turns an RZX into a coverage map.

**Our own utilities** (in the kit, all tested):

- `zxinit.py`: from a tape to a green project in one command.
- `zxtape.py`: TAP/TZX ↔ a text manifest + payload files. It rebuilds byte for byte, including turbo blocks, pauses, non-standard checksums and TZX text blocks.
- `zxbasic.py`: lossless BASIC ↔ text: hidden numbers (`CLEAR 0\#=24999`), colour codes, machine code in REM, wrong line lengths, the variables area. Every line is checked by tokenising it back; 3000 random programs made the round trip without a difference.
- `zxrun.py`: runs a snapshot. Keyboard and Kempston from a script or at random, an execution map, per-frame hashes of the screen, sound and RAM, screenshots, a snapshot dump, a write watchpoint (with the address of the instruction), loading a binary at another address for the shift test, the record of a run that a port replays (`--record`), and a random run saved as an input script (`--save-input`). The C and Python simulators give the same hashes.
- `zxq.py`: the agent's interface to the disassembly: `show`, `refs`, `next` (the "dependencies first" queue), `status`, `unexec`, `peek`, `strings`, `gfx` (bytes → PNG), `reclassify` (reclassify a range with a ctl fragment), `cut` (split an annotated entry), `export` (asm modules); the question and findings registers.
- `zxgfx.py`: sprite and tile sheets, captions and animated GIFs from the game's bytes, for the article.
- `zxdiff.py`: a Z80 routine against a Python model or a port function, on generated cases (see Checks).
- `zxport.py`: the inputs of a stage 3 port (labels, typed variables and the RAM image from the build) and the check that replays recorded runs.
- `zxcompare.py`: a disassembly against a reference one: bytes, classification, boundaries, documentation, magic numbers.
- In each project at stage 4, `bridge/` (written per game, the only code that sees both stages): a decoder from stage 3 memory to the stage 4 state, the extraction of the game's data into editable files, and the oracle that runs stage 3 next to stage 4.

## Pipeline

| Phase | Stage | Who | What happens | Done when |
| --- | --- | --- | --- | --- |
| 0. Init | 1 | script | `zxinit.py game.tap game-re/`: the tape split, a simulated load → `re/orig.z80`, the image at the moment of loading → `re/image.z80`, BASIC → `src/loader.bas`, the screen → `data/`, 6000 frames of random input → map, `sna2ctl` + `sna2skool` → `re/skool/`, `src/build.asm`, `tape/tape.txt` | `make` → `IDENTICAL` |
| 0a. Loader | 1 | lead agent (+ a person if the tape is protected) | non-standard tapes only: the point where control passes to the game, the addresses of headerless blocks, the decrypter → `scripts/encrypt.py` | `make` → `IDENTICAL`, every block in `re/notes.md` |
| 1. Coverage | 1 | lead agent, a person if they like | input scripts made from screenshots, fuzz with the game's real keys, RZX | two new scripts in a row add < 1% |
| 2. Classification | 1 | lead agent | `unexec`, `strings`, `gfx`, `refs`, watchpoints → ctl fragments → `reclassify`; a memory map | no data disassembled as code |
| 3. Annotation | 2 | subagents on a cheap model | batches of 5–15 entries from `zxq.py next`, leaves of the call graph first; the lead collects them, `make`, commit | `status`: 100% |
| 3a. Review | 2 | subagents, a group of modules each | every name, claim and register line checked by a run; renames as `Old -> New` lines, applied by the lead with `zxq.py rename`; creature names decided once by the lead | every module reviewed, `make` → `IDENTICAL` |
| 4. Relocation | 2 | lead agent | `make labels`, `@label`/`@isub`, address tables as `W`, self-modifying code through a label on the instruction | `shift-test` passes at a shift of 0x100 and at an odd one |
| 5. Export | 2 | lead agent | `re/modules.txt` → `make export` → `src/*.asm`, README | `make`, `make test`, `make shift-test` green |
| 6. Documentation | 2 | lead agent + subagents per section | an article in `docs/`, top down: overview, data structures, menu, game loop, subsystems, non-obvious parts and hacks, porting to another platform; a PNG gallery: sprites, tiles, title screens, maps of all levels | all sections present, every routine of the main loop mentioned with a link, links resolve |
| 7. Port | 3 | lead (control flow, contract, tools), subagents per module | `port/` from `src/`: leaf modules first, then the rest in parallel; recorded runs that reach every routine | `make diff` and `make port-test` green |
| 8. Clean logic | 4 | lead (state, leaf helpers, flow, bridge, contract), subagents per module | `game/` from `port/`, the data as editable files | `make game-test` green |
| 9. Ship | 3, 4 | lead | a desktop build or a web page from `port/` or `game/` | `make port-html` / `make game-html`; played and heard |

The annotation order is "dependencies first": a routine is described once its callees are named, and data once the routines that read it are named. Then `zxq.py show` prints the neighbours' names next to the code, and the agent does not need to read them again. The ports keep the same order: leaf modules first, so their signatures are fixed before their callers are written.

## Checks

One idea at every stage: run the previous stage and the new one on the same inputs, compare at fixed points, and report the first difference by name.

| What | Stage | Tool | Compares |
| --- | --- | --- | --- |
| the tape | 1, 2 | `make` | the built tape with the original, byte for byte |
| behaviour after a refactoring | 1, 2 | `make test` | per-frame hashes of screen, sound and RAM with the recorded ones |
| relocatability | 2 | `make shift-test` | the same hashes with the code moved |
| a routine, the annotation | 2 | `zxdiff.py`, `make diff` | a Z80 routine with a Python model, on generated cases |
| a routine, the port | 3 | `zxdiff.py` | a Z80 routine with its port function, on generated cases, with its T-states |
| the whole port | 3 | `make port-test` | the game's memory at every pass of the main loop, the input replayed from a Z80 run |
| a routine, the clean logic | 4 | `bridge/oracle.py routine` | every call of a stage 3 routine in the recorded runs: the stage 4 routine on the state before must give the state after |
| the whole clean game | 4 | `make game-test` | the state and the sounds at every step; the screen byte for byte; the clock; free play with invariants |

**Differential tests of routines** come from [REA](https://github.com/morluto/rea) (an MCP for reverse engineering modern programs) and the reconstructions made with it (DX-Ball: a C function checked on 3205 cases against the original x86). A Z80 routine runs in the simulator on cases generated by kind (`typical`, `boundary`, special inputs), and its registers and memory are compared with a Python function: a model, which checks the annotation, or the port itself. Boundary cases find bugs more often than random ones (on a model of `StepCell` with a planted bug: 3 of 48 boundary cases against 1 of 400 random ones). `--dump` writes golden input/output pairs for a port to C. The per-routine status is in `tests/models/STATUS.md`. At stage 4 the cases are no longer generated: every call of a routine in the recorded runs is one, decoded from stage 3's memory before and after.

**Recorded runs.** `zxrun.py --record` writes, in order, every value the game's IN read, the interrupts the ROM's handler took, and the game's memory at every pass of a checkpoint (the main loop), with the clock: the first pass in full, then the changes. A stage 3 port replays the reads and must hold the same memory at the same point; stage 4 runs next to stage 3 on the same records. The records hold game data and are build files. A check also lists the routines no record reached; a random run that reaches them is saved as a new input.

**The question list** (`re/questions.md`, also from REA): at init, 17 standard questions for any game (loading, memory map, controls, loop, AI, score, lives, levels, formats, random numbers, sound, hardware, counter edges, unexecuted code, bugs), extended for the game. Before the article each one is marked answered / partial / open; `make audit` shows the ones not closed.

**The findings register** (`re/findings.md`): every claim the work relies on, with its evidence and a status: `observed` (seen in the simulator, in a test, by a byte check), `inferred` (read from the code), `unknown`, or `refuted` (disproved; it stays in the register). Only a run makes a claim observed. Negative claims are limited: "not executed on these inputs", not "dead code". On Hungry Horace this paid off at once: a direct call of `ShowScore` confirmed the bug "10 lives print as `:`" and refuted the annotator's claim that `ShowScore` does not use HL (in fact it prints exactly HL). The refuted claim stayed in the register as `refuted`. The ports keep every finding's quirk, and a fixed mode drops them one by one, by finding.

Smaller things from REA: `zxdoctor.py` (it checks the tools and the state of the project and gives the command that fixes a problem), and the tape and everything made from it kept out of git, with `make restore`.

## No "magic numbers"

The goal is a source that can be ported to C or Python with a library that emulates the Spectrum hardware. So no bare numbers may remain in the asm:

- **Addresses outside the game** (ROM, system variables, the screen): `@equ` in `head.skool`. SkoolKit puts this name in place of every 16-bit operand with the same value, counters included (`LD BC,$4000`), so `zxq.py equs --uses` shows every substitution and `@keep` undoes the false ones.
- **Numbers** (sizes, colours, keyboard masks, tile codes, directions): `src/constants.asm` through `zxq.py const` (it locks the file, so it is safe for parallel agents) and `@isub=LD (HL),CYAN*PAPER+BLACK`.
- **Addresses inside the game**: only `@label`, not `@equ`. A label moves with the code; `@equ` nails the address down. `zxq.py equs --consolidate` turns such `@equ`s from subagents into labels by itself.
- **Self-modifying code**: a label on the instruction that changes, and the write as `Label+1`.
- The description of every routine has a `Hardware:` sentence on the hardware it touches: screen, attributes, ports, ROM, timings. This is the list of what the platform library will replace. Its register lines say what the routine's own instructions read and what its callers use, flags included: the port builds its signatures from them.

The ports inherit all of it: the labels and constants become Python names (`labels.py`), the data labels become typed variables with the widths of their declarations (`variables.py`), and the stage 4 constants keep the asm's names.

## Documentation (phase 6)

The work ends not only in a source but also in an article in `docs/`, at the level of a good post on Habr: a `README.md` with a table of contents and a separate file per section, relative links to the code (`../src/screen.asm#L120`), tables of structure layouts, Mermaid diagrams of the loop, and an honest "verified / inferred" mark.

The pictures are made from the game's bytes, not drawn:

- `zxgfx.py sheet`: sprite and tile sheets in the attribute colours the game uses, with captions and animated GIFs;
- `zxrun.py --call ADDR --reg HL=... --png`: calls the game's own drawing routine in the simulator and saves the screen. This gives level maps and title screens exactly as the game draws them;
- `zxrun.py --input ... --shot`: frames from the game.

The commands that make them are in `docs/img/Makefile`, so the pictures can be rebuilt. The procedure is the `zx-document` skill.

Before the section on bugs comes a separate "bug hunt" pass at the edges: for every counter and timer (lives, level, speed, score digits), what happens at the minimum, at the maximum and on overflow, checked in the simulator with `zxrun.py --poke`. The comparison with the reference on Hungry Horace showed that annotation without this pass misses exactly these bugs: [Hungry Horace: a run of the method and a comparison with SkoolKit](hungry-horace-run.md). On The Hobbit the comparison showed what else it misses: sequences of commands no script typed (a refused line, then the repeat key, resets the machine), command patterns with no handler, odd text on screens of its own runs that nobody read, and what a new game does not restore. The pass now covers these too ([The Hobbit: a blind run](the-hobbit-run.md)).

## The ports

### Stage 3: the original's shape

The design and its reasons are in [stage3.md](stage3.md); the way to work is the `zx-port` skill.

- **The asm's shape survives.** Memory is the same 64 KB at the same addresses, a routine is a function named after its label, and registers are arguments and results. A variable is `v.Score`, with the width from its declaration in the asm (DEFB, DEFW, a table). A computed address is `mem[a]` (a byte) and `mem16[a]` (a word). All three are the same memory and wrap round as on the Z80, so a word cannot be written as a byte by mistake.
- **Or the Z80's interface.** When routines pass values in registers and flags through long chains of callers (The Hobbit: 400 routines), the registers stay shared (`r.a`, `r.hl`, `r.cf`) and each routine reads and leaves what its instructions do: a signature per routine would be a second model of the code, checked by nothing.
- **The CPU is not emulated.** Time is a T-state counter that the port keeps itself (`zx.spend`; `zxdiff.py` gives the figures). Waiting and blocking sound are `await`. A jump that drops the return address is `raise Goto(...)`.
- **What was hard, now in the skill:** a routine's inputs read from its instructions rather than its header, flags in the test cases, how to split T-states between a routine and its callees, and a timing race the code does not show (an interrupt the Z80 takes between the ROM's `EI` and the game's `DI`), which only a recorded run could reproduce.

### Stage 4: clean game logic

The decisions are in [stage4.md](stage4.md); the way to work is the `zx-clean` skill.

- **Plain state, events for the hardware.** Positions are a column and a row; no addresses, registers or T-states. A routine reads as a rule; sound and the time the game holds are events (`Sound`, `Show`) that a pacer and a synthesiser turn into frames and audio. The look stays the Spectrum's: 32×24 cells, attributes, the ROM font through `zxpyxel.display`.
- **Only a bridge sees both stages.** The decoder, the oracle and the extraction of the game's data live in `bridge/`; the stage 4 game never imports the port or an address.
- **The data is editable**: graphics as PNG sheets checked as they load (size, Spectrum colours, one ink per cell), maps as text, texts and the start state as JSON. Editing them is how a fork changes the game.
- **The model is where the work is.** On Hungry Horace the rules read the screen (collisions go by the colour of a cell, a guard keeps the cells under it), so the grid of cells with glyph and attribute is part of the state. On The Hobbit the world is records by id, messages and handlers by name, and the screen (drawn on incrementally, scrolled) is state too.
- **A game that waits inside a pass is one generator.** The Hobbit waits for keys in its line editor, its scroll pause and its prompts, so the whole game is a generator that yields requests (a key, R, a saved state, whether a printer answers), answered by the oracle from the record and by the pacer from the host, and a `Step` at the top of the main loop.

### Stage 5 and going back

Stage 5 takes the clean logic to C/C++ (SDL2 or a platform library) or JS. Its tests are golden runs written by the stage 4 oracle: one language-neutral record per step (actions, state, sounds, the screen). It is a design for now.

Going back to the Spectrum works the same way in reverse: stage 3 keeps the memory layout and the labels, so a change made in Python goes back to asm routine by routine, with `zxdiff.py` run the other way (the Python routine is the oracle).

## The agent harness

- `AGENTS.md` at the project root (`CLAUDE.md` contains `@AGENTS.md`): one rule (`make` green after every edit, commit only when green), the layout, a command cheat sheet, token discipline, naming conventions, when to call the person. About 100 lines; it is read in every session.
- Skills (`skills/`, symlinked as `.claude/skills` for Claude Code and `.agents/skills` for Codex), one per phase or stage: `zx-init` (loaders, encryption and headerless blocks included), `zx-coverage`, `zx-classify`, `zx-annotate`, `zx-relocate`, `zx-export`, `zx-document`, `zx-port` (models and stage 3), `zx-clean` (stage 4). Each is a procedure with a done criterion, and each is loaded only when needed.
- Roles: a lead agent on a strong model (plan, loader, classification, relocation, review of names; in a port the control flow, the leaf helpers, the contract and the integration); subagents on a cheap model for the bulk: annotation batches, article sections, port modules. Each gets its files, the skill and the contract, and edits nothing else.
- What a run finds hard becomes a rule in the skill or a check in a tool: every subagent's report ends with what was unclear, and the lead folds it in.
- State between sessions lives in git and `re/notes.md`; `make status` and `zxq.py next` tell where the work stopped. Long work can run in a loop (`/loop`): "take the next batch, annotate, `make`, commit".

## Saving tokens

- Never read a whole skool, asm, lst, map, trace or record. Only `show`/`refs`/`grep -l`/`head`.
- Look at graphics as a picture (`gfx`, `--shot`), not as a list of DEFBs: one PNG instead of hundreds of lines.
- Reclassify with a ctl fragment of 5–10 lines, not by rewriting a hundred lines of skool.
- Put questions about behaviour to the simulator (a watchpoint, `--stop`, a screenshot of a frame), and in a port to the previous stage.
- A check reports the first difference only, named (a label, a screen cell, a state field), never a dump.
- Comment only where the intent cannot be seen from the code.
- Check the exit code of `make`, not its output.

An estimate for a 40 KB game (not a measurement): 600–1200 entries; annotating an entry takes 3–8 thousand input tokens, mostly from the cache, and 200–500 output tokens. That is a few million input tokens for the whole game, mostly on the cheap model. A port is cheaper: on Hungry Horace each port stage took 200–450 thousand subagent tokens. Measured on The Hobbit (48 KB, 585 entries): about 4.6 million subagent tokens for stages 1 and 2 with the article, 1.5 million for stage 3, 1.9 million for stage 4.

## Human time

1. Provide the tape (and an RZX, if the archive has one): minutes.
2. Sometimes play for 10–20 minutes in Fuse, recording an RZX, when coverage stalls short of the late levels.
3. Decide how far to reproduce the loader's protection.
4. Spot-check the names after annotation, read the README.
5. Play each port and listen to it: speed and sound are judged by eye and ear, not tested.
6. Decide which of the original's bugs a fixed mode drops.

In total, about an hour per game without protection, and minutes per port stage.

## What has been tested

On the test game `selftest/demo.asm` (movement on QAOP/Kempston, a jump table, a self-modifying counter, text with bit 7 set, a BASIC loader with hidden numbers), `selftest/run.sh` goes the whole way through stages 1 and 2. Init gives `IDENTICAL` at once (through sjasmplus and pasmo); `make test` matches for 300 frames; the shift test first fails on the jump table written as DEFB and on the operand of a self-modifying instruction, and after two ctl fragments and two `@isub`s it passes at shifts of 0x100, 0x1234 and 0x300; export to modules gives `IDENTICAL` again. Separately: TAP and TZX (standard, turbo, pure data, comment, pause) make the round trip through the manifest byte for byte, and `tap2sna.py` loads the built TZX.

### First run on a real game: Horace Goes to the Tower

[Horace Goes to the Tower](https://spectrumcomputing.co.uk/entry/26600/ZX-Spectrum/Horace_Goes_to_the_Tower) (The Mojon Twins, 2011): 48K, freeware, a standard tape (BASIC, a screen, 31766 bytes of code from address 25000); the authors have published the C sources (z88dk + splib2). The sources are valuable as a reference: the function names in `engine.h` and `horace.c` can be compared with the names the agent comes up with.

`zxinit.py` gave `IDENTICAL` in 7 seconds: 429 entries, 66% of instructions executed in 6000 frames of random input, and the random input reached the game screen. The run found two bugs in the kit; both are fixed:

- `skool2asm` writes the undocumented registers as `IXl`/`IXh`, which sjasmplus does not accept; the Makefile converts them to `IXL`/`IXH`;
- the header of the screen block gave address 32768, but the BASIC loads it with `LOAD "" SCREEN$`, that is, to 16384; now any CODE block of length 6912 is treated as a screen.

Annotation, the shift test and export have not been done on this game yet.

### Full run: Hungry Horace

Stages 1 and 2: all phases except the article were done in ~1 hour without a person, and the result was compared with the SkoolKit reference disassembly. Names and purpose match for every routine and variable. The run found the `OR C`/`OR E` bug that the reference documents, and several more that the reference does not have; it missed three bugs that show at the edges.

Stage 3: the whole game is ported to Python (~1100 lines) and matches the Z80 in all of the game's memory at every pass of the main loop on three records: the demo, a game, and 11,000 frames of random play in which the bell is taken, a guard is eaten and Horace leaves through the arrows. 38 routines pass `zxdiff.py` without a difference. The port never needed a fix. The only difference on the first run was an interrupt that the Z80 now and then takes between the `EI` in the ROM's BEEPER and the game's `DI`; recording the interrupts in the run closed it.

Stage 4: the same game as plain Python (~900 lines, the `game/horace/` package) matches stage 3 at every call of 17 routines and at every step of all three records (demo 2,664 steps, game 5,544, bell 15,576), the screen byte for byte, the clock within 1%. Three subagents (Sonnet) ported the modules in parallel from the skill and the contract. Nothing needed fixing after the parts were put together. The only bug was in the oracle (repeated sounds were collapsed across the whole step), and two subagents found it independently. A mode with the original's bugs fixed is not built yet.

In detail: [Hungry Horace: a run of the method and a comparison with SkoolKit](hungry-horace-run.md).

### Second run: Jet Set Willy

Jet Set Willy (1984) went through stages 1 and 2 and was compared with the SkoolKit reference disassembly (`examples/jet-set-willy/re/comparison.md`).

### Blind run: The Hobbit

The Hobbit (Melbourne House, 1982), a text adventure of another genre and engine, went through stages 1 to 4 without the existing disassemblies and write-ups, and without help from the author beyond the stage 4 interview. Stages 1 and 2: 585 entries annotated, relocatable, in about 2.3 hours; the article (37 images) in parallel with stage 3; 85 findings by the end. Stage 3: the register interface, ~9,300 lines by eight subagents in under an hour, identical to the Z80 at every main-loop pass of six records (one plays the game to the end). Stage 4: one generator for the whole game, ~6,800 lines by six subagents, identical to stage 3 at every pass with the screen; integration found its bugs in the pacer and in inputs the records do not vary, which free play and a measurement on the Z80 caught. Compared afterwards with a complete SkoolKit disassembly of the same version: 4 bytes differ, code and non-code agree on 99.8% of the bytes, and of 506 entries both describe 474 mean the same; 6 differ, among them two record fields named the wrong way round (weight and size) from the annotation through stage 4, which no check could catch. Of 50 known bugs it found 30 and part of 3; it missed sequences of commands no script typed and things it read but did not recognise. 14 of its findings are in no reference.

In detail: [The Hobbit: a blind run](the-hobbit-run.md).

### Candidates for further tests

| Game | Why | Rights |
| --- | --- | --- |
| Horace Goes to the Tower | first run, C source available | freeware |
| [Cheril the Goddess](https://spectrumcomputing.co.uk/alt/27991/ZX-Spectrum/Cheril_the_Goddess), [Trabajo Basura](https://spectrumcomputing.co.uk/alt/27128/ZX-Spectrum/Trabajo_Basura) | the same Mojon Twins engine, sources available: tests whether names carry over between games | freeware |
| [BLAM!](https://scattergoodstudios.itch.io/blam) (1992) | a classic in assembler, re-released for free by its author | free, with the author's permission |
| [The Speccies 2](https://spectrumcomputing.co.uk/entry/30028) | a modern game in assembler | freeware; distribute only from the author's site, Spectrum Computing, WoS |
| Manic Miner, Jet Set Willy, Hungry Horace | SkoolKit reference disassemblies exist to compare the classification with | already reversed in public: publish the explanation, never the tape or anything made from it as data |

"Freeware" on Spectrum Computing usually means "free, but under copyright": the tape and anything made from it as data stay out of the repository, as for any game.

## Limits

- The runner is 48K only and has no memory contention: the hashes check logic, not cycle-exact effects. 128K (`@bank`, `sna2skool -p`) and timings go through ZEsarUX/MAME.
- Only standard headed blocks are split automatically. Protected loaders are manual work for the agent following `zx-init`; the hardest part is generating a tape with encryption, which needs `scripts/encrypt.py`.
- The shift test does not move code that is copied to a fixed address at start-up: such code is kept in place with `DISP`, or excluded and noted in `re/notes.md`.
- The stage 3 replay sees only the ROM's IM1 interrupts; a game with its own IM2 handler needs its checkpoint at a HALT. Stages 3 and 4 have been done on two games, and the stage 4 bridge is still written per game.
- Copyright: never put `original/`, built tapes or anything made from them as data (RAM images, extracted assets, records, web builds) into the repository unless the game is free. The explanations of games already reversed in public (annotated sources, articles, ports) are published without them, as the examples are.

## Links

- SkoolKit: <https://skoolkit.ca> (documentation on ctl and skool, example disassemblies).
- sjasmplus: <https://github.com/z00m128/sjasmplus>
- Pyxel: <https://github.com/kitao/pyxel>
- RZX Archive: <https://www.rzxarchive.co.uk>
- Fuse: <https://fuse-emulator.sourceforge.net>; ZEsarUX: <https://github.com/chernandezba/zesarux>
