# ZX-REAPER

**R**etro **E**ngineer **A**nything, **P**ort **E**verywhere **R**ightnow.

An agent harness for reverse engineering ZX Spectrum games into sources that
rebuild the original tape byte for byte, are relocatable and free of magic
numbers, are documented by an article with a graphics gallery, and are ready
to be ported routine by routine against the original code.

The method and its reasoning, in Russian: [docs/method.md](docs/method.md);
the full Hungry Horace run and its comparison with the SkoolKit reference:
[docs/hungry-horace-run.md](docs/hungry-horace-run.md). Both are copies of
notes in the author's Obsidian vault, refreshed with `scripts/sync-method.py`.

## Layout

| Path | What |
| --- | --- |
| `tools/` | command-line tools (Python, SkoolKit, sjasmplus) |
| `template/` | what every game project starts with: `Makefile`, `AGENTS.md`, `skills/`, `re/questions.md`, `re/findings.md` |
| `selftest/` | fixture game and an end-to-end test of the whole pipeline |
| `docs/` | the method and the reference run report (copies of the vault notes) |
| `scripts/` | repository maintenance (`sync-method.py`) |
| `examples/hungry-horace/` | the reference run: Hungry Horace (1982) taken through every stage, compared with the SkoolKit reference disassembly |

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
| models, port | `zx-port` | routines pass `make diff` against the Z80 code |

## Tools

| Tool | Purpose |
| --- | --- |
| `tools/zxinit.py` | tape → project: split, simulated load, image, coverage, ctl, skool, build glue |
| `tools/zxrun.py` | headless runner on SkoolKit's C simulator: scripted keys/Kempston, fuzz, execution map, per-frame hashes, screenshots, pokes, write watchpoints, shift test loading, `--call` a game routine and save the screen (renders levels for docs) |
| `tools/zxq.py` | skool split into one file per entry; show/refs/next/status/unexec/peek/strings/gfx/reclassify/check/const/equs/export; question and finding registers, audit |
| `tools/zxtape.py` | TAP/TZX ↔ text manifest + payloads, byte-exact rebuild, per-block diff |
| `tools/zxbasic.py` | lossless BASIC ↔ text (hidden numbers, REM code, odd lines) |
| `tools/zxgfx.py` | colour sprite/tile sheets from memory, for the docs gallery |
| `tools/zxdiff.py` | differential tests: a Z80 routine against a Python model or port on generated cases by kind; `--dump` writes golden cases for a C port |
| `tools/zxcompare.py` | compare a skool disassembly with a reference: bytes, classification, boundaries, documentation, magic numbers |
| `tools/zxdoctor.py` | readiness check: tools, versions, and what a project is missing, with the fixing command |

Working registers in every project: `re/questions.md` (what the work must
answer, with status) and `re/findings.md` (claims with status observed /
inferred / unknown / refuted and their evidence), edited through
`zxq.py question|finding` and summarised by `make audit`. The evidence
discipline, the question list and the per-routine differential tests follow
ideas from [REA](https://github.com/morluto/rea) and the reconstruction
projects built with it.

## Limits

- `zxrun.py` is 48K only and has no memory contention: frame hashes check
  logic, not cycle-exact effects (multicolour, border tricks). Check those in
  Fuse or ZEsarUX by eye.
- `zxinit.py` automates standard headed blocks. Custom loaders, headerless and
  encrypted blocks are handled by the `zx-init` skill with the agent.
- `zxbasic.py` knows 48K keywords only (128K `SPECTRUM`/`PLAY` come out as `\A3`/`\A4`).
- Game tapes are copyrighted: keep game projects in private repositories and
  the tapes out of git.
