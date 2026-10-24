# ZX-REAPER

**R**etro **E**ngineer **A**nything, **P**ort **E**verywhere **R**ightnow.

An agent harness for ZX Spectrum games, in two halves. Reverse engineering
turns a tape into sources that rebuild it byte for byte, are relocatable and
free of magic numbers, and come with an article and a graphics gallery.
Porting then takes the game off the Spectrum in stages, each checked against
the one before it: Python with the original's memory layout, then clean game
logic, then C or JS. A lead agent and subagents do the work from skills;
scripts do the mechanics.

## Port everywhere

| # | From → to | Check | Status |
| --- | --- | --- | --- |
| 1 | tape → automatic disassembly (SkoolKit) → tape | tape and snapshot byte-identical | built |
| 2 | automatic disassembly → annotated, relocatable asm without magic numbers → tape | the same, plus `make shift-test` and routine models (`make diff`) | built |
| 3 | asm → Python on `zxpyxel`, a stand-in for the 48K hardware on [Pyxel](https://github.com/kitao/pyxel): the original memory layout, the same screens and behaviour, code that follows the asm routine by routine | routines against the Z80 code (`zxdiff.py`); the whole game by replaying a Z80 run's input and comparing game memory at every pass of the main loop (`make port-test`) | built ([docs/stage3.md](docs/stage3.md)) |
| 4 | Python on `zxpyxel` → clean game logic over plain state (no addresses, registers or T-states), the Spectrum look kept, on any framework | stage 3 as the oracle: every routine call and every step of the recorded runs, state, sound and screen (`make game-test`) | built in faithful mode ([docs/stage4.md](docs/stage4.md)) |
| 5 | game logic → C/C++ with SDL2 or platform libraries, or JS for the web | the stage 4 golden runs | design |

Each check uses the stage before as its oracle, so the chain runs back to
the original: stage 3 replays the input a Z80 run read and must hold the
same memory at every pass of the main loop; stage 4 runs next to stage 3 on
the same recorded runs and must reach the same state and sounds at every
step, and every call of a stage 3 routine is a test case for its stage 4
version. What a run finds hard becomes a rule in a skill or a check in the
tools.

Any stage is a place to stop, fork and ship. Change the stage 3 or stage 4
Python, play it, ship it (Pyxel makes a desktop app or a single HTML page:
`make port-html`, `make game-html`), or go back to the Spectrum: stage 3
keeps the original memory layout and the routine names, so a change ports
back to asm routine by routine, with the same differential tests run the
other way.

## Examples

Three games so far, in the order they were done. Every run ended with a
comparison against the existing work, and what the run got wrong became a
rule in a skill or a check in the tools before the next game: the harness
learns from its own runs and their mistakes. Each example is the record of
its run.

1. **Hungry Horace** (Psion/Melbourne House, 1982),
   [`examples/hungry-horace/`](examples/hungry-horace/): the reference run.
   Stages 1 and 2 compared with the SkoolKit reference disassembly; stage 3
   identical to the Z80 at every main-loop pass of three recorded runs;
   stage 4 identical to stage 3 at every step, in faithful mode (the
   original's quirks kept); the sound judged by ear.
   [Run report](docs/hungry-horace-run.md).
2. **Jet Set Willy** (Software Projects, 1984),
   [`examples/jet-set-willy/`](examples/jet-set-willy/): stages 1 and 2,
   compared with the SkoolKit reference disassembly
   ([comparison](examples/jet-set-willy/re/comparison.md)).
3. **The Hobbit** (Melbourne House, 1982),
   [`examples/the-hobbit/`](examples/the-hobbit/): the most recent, a text
   adventure with a parser, characters that act on their own and vector
   pictures, done blind through stages 1 to 4 with no help from the author
   beyond the stage 4 interview on graphics, input and sound. The stage 3
   port is identical to the Z80 at every main-loop pass of six recorded runs
   (one plays the game to the end), the stage 4 game identical to stage 3 at
   every pass, the screen included; both play on the desktop and in the
   browser. Compared afterwards with the existing disassemblies, a C port and
   the author's account: the bytes, the code map and the meaning agree with
   the most complete reference wherever both describe something; the run
   named two record fields the wrong way round, missed 17 of 50 known bugs
   and found 14 that no reference has
   ([comparison](examples/the-hobbit/re/comparison.md)). The errors are
   listed, not corrected in the example; the
   [run report](docs/the-hobbit-run.md) shows what each one changed in the
   harness.

Scope: the 48K Spectrum. AY music and effects (128K) come later, through
[pyayay](https://github.com/ruguevara/pyayay) (Ayumi). Out of scope: stage 5
for now, 128K and AY, protected and turbo loaders (such games start from a
snapshot instead of the tape), games that need contention-exact timing.

## Documents

| Document | What |
| --- | --- |
| [docs/method.md](docs/method.md) | the method and its reasons: decisions, phases, evidence, the stages, what has been tested |
| [docs/hungry-horace-run.md](docs/hungry-horace-run.md) | the reference run: Hungry Horace through every stage, time and tokens, the comparison with SkoolKit |
| [docs/the-hobbit-run.md](docs/the-hobbit-run.md) | the blind run: The Hobbit through stages 1 to 4, time and tokens, the comparison with the existing work |
| [docs/stage3.md](docs/stage3.md) | stage 3: the library, the port's shape, the replay check, results |
| [docs/stage4.md](docs/stage4.md) | stage 4: the clean state, the bridge to stage 3, the checks, results |
| [examples/hungry-horace/docs/](examples/hungry-horace/docs/README.md) | the article on how Hungry Horace works, with its gallery |
| [examples/the-hobbit/docs/](examples/the-hobbit/docs/README.md) | the article on how The Hobbit works, with its gallery |

The method and the run report are also in Russian (`docs/*.ru.md`).

## Setup

```sh
python3 -m venv .venv && . .venv/bin/activate
pip install -r requirements.txt   # SkoolKit (its scripts go on PATH) and Pyxel
tools/zxdoctor.py                 # checks Python, SkoolKit, sjasmplus, make
selftest/run.sh                   # must end with SELFTEST PASSED
```

Also needed: [sjasmplus](https://github.com/z00m128/sjasmplus) (tested with
1.20.1 and 1.24.0) and make. Optional: Fuse for playing and recording RZX.
Keep the venv active when working in a game project: its tools import SkoolKit.

## Start a project

```sh
python3 <zx-reaper>/tools/zxinit.py game.tzx game-re/ [--rzx play.rzx]
cd game-re && make            # must print IDENTICAL
git init && git add -A && git commit -m "re: init"
claude                        # AGENTS.md + skills/ drive the rest
```

`zxinit.py` copies `template/` and `tools/` into the project, and `zxpyxel/`
into `port/`, so each project is self-contained and keeps working when
zx-reaper changes. The original tape stays out of git: put it into
`original/` and run `make restore`.

## Skills

Each skill is one procedure with a done criterion, copied into every project
(`skills/`, linked as `.claude/skills`) and loaded only when needed.

| Skill | Stage | What it does | Done when |
| --- | --- | --- | --- |
| `zx-init` | 1 | the project from a TAP/TZX; custom loaders, turbo, headerless and encrypted blocks | `make` prints `IDENTICAL` |
| `zx-coverage` | 1 | input scripts, random play and RZX until the code map stops growing | new inputs add under 1% executed code |
| `zx-classify` | 1 | code, data, text, graphics and variables apart; the memory map | no data disassembled as code |
| `zx-annotate` | 2 | names and descriptions, named constants, self-modifying code labelled; subagents in batches | every entry named and described, findings recorded |
| `zx-relocate` | 2 | every address operand symbolic | `make shift-test` passes at an even and an odd shift |
| `zx-export` | 2 | the skool frozen into asm modules, `src/` the master | `src/*.asm`, still `IDENTICAL` |
| `zx-document` | 2 | the article in `docs/`, top down, with a gallery rendered from the game's bytes | written, audited, links resolve |
| `zx-port` | 2, 3 | models that prove annotations; the port to Python routine by routine against the Z80 | routines pass `make diff`; the port passes `make port-test` |
| `zx-clean` | 4 | the port rewritten as clean logic over plain state, assets as editable files | `make game-test` passes against stage 3 |

## Tools

| Tool | Purpose |
| --- | --- |
| `tools/zxinit.py` | tape → project: split, simulated load, image, coverage, ctl, skool, build glue |
| `tools/zxrun.py` | headless runner on SkoolKit's C simulator: scripted keys/Kempston and typed text (`TYPE`), fuzz, execution map, per-frame hashes, screenshots, the screen as text (`--text`, 32 or 42 columns), pokes, write watchpoints, shift test loading, `--call` a game routine and save the screen (renders levels for docs), `--record` the reads, interrupts and checkpoint states a port replays, `--save-input` a fuzz run as an input script |
| `tools/zxq.py` | skool split into one file per entry; show/refs/next/status/unexec/peek/strings/gfx/reclassify/cut/check/const/equs/addrs/export; question and finding registers, audit |
| `tools/zxtape.py` | TAP/TZX ↔ text manifest + payloads, byte-exact rebuild, per-block diff |
| `tools/zxbasic.py` | lossless BASIC ↔ text (hidden numbers, REM code, odd lines) |
| `tools/zxgfx.py` | colour sprite/tile sheets, captions and animated GIFs from memory, for the docs gallery |
| `tools/zxdiff.py` | differential tests: a Z80 routine against a Python model or a stage 3 port function on generated cases by kind, with its T-states (`--tstates` per kind); `--dump` writes golden cases for a C port |
| `tools/zxcompare.py` | compare a skool disassembly with a reference: bytes, classification, boundaries, documentation, magic numbers |
| `tools/zxport.py` | stage 3: `labels.py` and `variables.py` (typed data labels) from the build, the 48K RAM image of a snapshot, and the whole-game check that replays `zxrun.py --record` runs |
| `tools/zxdoctor.py` | readiness check: tools, versions, and what a project is missing, with the fixing command |

Working registers in every project: `re/questions.md` (what the work must
answer, with status) and `re/findings.md` (claims with status observed /
inferred / unknown / refuted and their evidence), edited through
`zxq.py question|finding` and summarised by `make audit`. The evidence
discipline, the question list and the per-routine differential tests follow
ideas from [REA](https://github.com/morluto/rea) and the reconstruction
projects built with it.

## Layout

| Path | What |
| --- | --- |
| `tools/` | command-line tools (Python, SkoolKit, sjasmplus) |
| `template/` | what every game project starts with: `Makefile`, `AGENTS.md`, `skills/`, `re/questions.md`, `re/findings.md` |
| `zxpyxel/` | the library of stages 3 and 4, standard-library Python except its Pyxel host: a stand-in for the 48K machine (memory, clock, ports, interrupts, a replay of Z80 runs), a display that keeps the Spectrum's look without addresses, PNG in and out |
| `selftest/` | fixture game and an end-to-end test of the whole pipeline |
| `docs/` | the documents above |
| `examples/hungry-horace/` | the reference run: stages 1 to 4 (`src/`, `port/`, `game/` with `bridge/`), compared with the SkoolKit reference disassembly |
| `examples/jet-set-willy/` | the second run, stages 1 and 2, compared with the SkoolKit reference (`re/comparison.md`) |

## Limits

- `zxrun.py` is 48K only and has no memory contention: frame hashes check
  logic, not cycle-exact effects (multicolour, border tricks). Check those in
  Fuse or ZEsarUX by eye.
- The stage 3 replay sees the ROM's IM1 interrupts only; a game with its own
  IM2 handler needs its checkpoint at a HALT.
- `zxinit.py` automates standard headed blocks. Custom loaders, headerless and
  encrypted blocks are handled by the `zx-init` skill with the agent.
- `zxbasic.py` knows 48K keywords only (128K `SPECTRUM`/`PLAY` come out as `\A3`/`\A4`).
- Game tapes are copyrighted: keep game projects in private repositories, and
  the tapes and everything made from them out of git.
