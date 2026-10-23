# ZX-REAPER

**R**etro **E**ngineer **A**nything, **P**ort **E**verywhere **R**ightnow.

An agent harness for reverse engineering ZX Spectrum games into sources that
rebuild the original tape byte for byte, are relocatable and free of magic
numbers, are documented by an article with a graphics gallery, and are ready
to be ported routine by routine against the original code.

## Port everywhere

Reverse engineering is the first half. The second half takes the game off
the Spectrum in stages. Each stage is checked against the one before it, and
any stage is a place to stop, fork and ship.

| # | From → to | Check | Status |
| --- | --- | --- | --- |
| 1 | tape → automatic disassembly (SkoolKit) → tape | tape and snapshot byte-identical | built: `zx-init`, `zx-coverage`, `zx-classify` |
| 2 | automatic disassembly → annotated, relocatable asm without magic numbers → tape | the same, plus `make shift-test` and routine models (`make diff`) | built: `zx-annotate` to `zx-document`, models in `zx-port` |
| 3 | asm → Python on `zxpyxel`, a library that stands in for the 48K hardware on [Pyxel](https://github.com/kitao/pyxel): the original memory layout, the same screens and behaviour, code that follows the asm routine by routine | routines against the Z80 code (`zxdiff.py`); the whole game by replaying the Z80 run's input and comparing game memory at checkpoints (`make port-test`) | built: `zx-port`; Hungry Horace ported whole ([docs/port.md](docs/port.md)) |
| 4 | Python on `zxpyxel` → game logic in plain Python plus graphics, input and sound subsystems with nothing Spectrum-specific in the logic, on the framework the user picks (Pyxel, pygame, SDL2, …) | stage 3 as the oracle: every routine call and every step of the recorded runs, state, screen and sound | built: `zx-clean`; Hungry Horace in faithful mode ([docs/stage4.md](docs/stage4.md)) |
| 5 | game logic → C/C++ with SDL2 or platform libraries, or JS for the web | the stage 4 golden runs | optional |

Stages 4 and 5 are optional and go wherever a project needs. Fork the stage 3
Python, change the game, play it and ship it (Pyxel makes a desktop app or a
single HTML page), or go back to the Spectrum: stage 3 keeps the original
memory layout and the routine names, so a change ports back to asm or C
routine by routine, with the same differential tests run the other way.

Scope for now: the 48K Spectrum. AY music and effects (128K) come later,
through [pyayay](https://github.com/ruguevara/pyayay) (Ayumi).

Done when a game of a different genre and engine, The Hobbit (Melbourne
House, 1982), runs as a stage 3 Python port on the desktop and in the browser
with little help from the author, and goes through stage 4 with the agent
interviewing the author on how to port graphics, input and sound. The run is
blind: the existing annotated disassemblies and write-ups of The Hobbit are
compared with the result afterwards, as the SkoolKit reference was for
Hungry Horace.

Out of scope: stage 5 for now; 128K and AY; protected and turbo loaders
(such games start from a snapshot instead of the tape); games that need
contention-exact timing.

The method and its reasoning, in Russian: [docs/method.md](docs/method.md);
the full Hungry Horace run and its comparison with the SkoolKit reference:
[docs/hungry-horace-run.md](docs/hungry-horace-run.md).

## Layout

| Path | What |
| --- | --- |
| `tools/` | command-line tools (Python, SkoolKit, sjasmplus) |
| `template/` | what every game project starts with: `Makefile`, `AGENTS.md`, `skills/`, `re/questions.md`, `re/findings.md` |
| `selftest/` | fixture game and an end-to-end test of the whole pipeline |
| `zxpyxel/` | the stage 3 library: a stand-in for the 48K Spectrum on Pyxel, for ported and new games ([docs/port.md](docs/port.md)) |
| `docs/` | the method, the reference run report, `port.md` (stage 3), `stage4.md` (the stage 4 design) |
| `examples/hungry-horace/` | the reference run: Hungry Horace (1982) taken through every stage, compared with the SkoolKit reference disassembly |
| `examples/jet-set-willy/` | second run: Jet Set Willy (1984), compared with the SkoolKit reference; report in `re/comparison.md` |

## Setup

```sh
python3 -m venv .venv && . .venv/bin/activate
pip install -r requirements.txt   # SkoolKit; its scripts go on PATH
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

`zxinit.py` copies `template/` and `tools/` into the project, so each project
is self-contained and keeps working when zx-reaper changes. The original tape
stays out of git: put it into `original/` and run `make restore`.

## Pipeline

| Stage | Skill | Done when |
| --- | --- | --- |
| init, loaders | `zx-init` | `make` prints `IDENTICAL` |
| coverage | `zx-coverage` | new inputs add under 1% executed code |
| classification | `zx-classify` | no data disassembled as code, memory map complete |
| annotation | `zx-annotate` | every entry named and described, findings recorded |
| relocation | `zx-relocate` | `make shift-test` passes at an even and an odd shift |
| export | `zx-export` | `src/*.asm` modules are the master, still `IDENTICAL` |
| article | `zx-document` | `docs/` written, audit done, links resolve |
| models, port | `zx-port` | routines pass `make diff` against the Z80 code; a stage 3 port passes `make port-test` |
| clean logic (stage 4) | `zx-clean` | the game in `game/` passes `make stage4-test` against stage 3 |

## Tools

| Tool | Purpose |
| --- | --- |
| `tools/zxinit.py` | tape → project: split, simulated load, image, coverage, ctl, skool, build glue |
| `tools/zxrun.py` | headless runner on SkoolKit's C simulator: scripted keys/Kempston, fuzz, execution map, per-frame hashes, screenshots, pokes, write watchpoints, shift test loading, `--call` a game routine and save the screen (renders levels for docs), `--record` the reads, interrupts and checkpoint states a port replays |
| `tools/zxq.py` | skool split into one file per entry; show/refs/next/status/unexec/peek/strings/gfx/reclassify/check/const/equs/export; question and finding registers, audit |
| `tools/zxtape.py` | TAP/TZX ↔ text manifest + payloads, byte-exact rebuild, per-block diff |
| `tools/zxbasic.py` | lossless BASIC ↔ text (hidden numbers, REM code, odd lines) |
| `tools/zxgfx.py` | colour sprite/tile sheets from memory, for the docs gallery |
| `tools/zxdiff.py` | differential tests: a Z80 routine against a Python model or port on generated cases by kind; `--dump` writes golden cases for a C port |
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

## Limits

- Stages 3 and 4 of "Port everywhere" are built and done on one game, Hungry
  Horace: stage 3 identical to the Z80 at every main-loop pass of three
  recorded runs ([docs/port.md](docs/port.md)), stage 4 identical to stage 3
  at every step, in faithful mode, without deviations yet
  ([docs/stage4.md](docs/stage4.md)); the sound is judged by ear, and stage
  5 is a design. The replay sees the ROM's IM1 interrupts
  only; a game with its own IM2 handler needs its checkpoint at a HALT.
- `zxrun.py` is 48K only and has no memory contention: frame hashes check
  logic, not cycle-exact effects (multicolour, border tricks). Check those in
  Fuse or ZEsarUX by eye.
- `zxinit.py` automates standard headed blocks. Custom loaders, headerless and
  encrypted blocks are handled by the `zx-init` skill with the agent.
- `zxbasic.py` knows 48K keywords only (128K `SPECTRUM`/`PLAY` come out as `\A3`/`\A4`).
- Game tapes are copyrighted: keep game projects in private repositories and
  the tapes out of git.
