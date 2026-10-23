# zx-re-kit

Kit for agent-driven reverse engineering of ZX Spectrum games into sources
that rebuild the original tape byte for byte. Method and reasoning:
[[Метод реверса игр ZX Spectrum с агентом]] (vault note next to this folder).

## Requirements

- Python 3.9+, `pip install skoolkit` (tested with 10.1)
- [sjasmplus](https://github.com/z00m128/sjasmplus) (tested with 1.24.0)
- make
- optional: Fuse (playing, RZX recording), zmakebas (self-test fixture only)

## Start a project

```sh
python3 zx-re-kit/tools/zxinit.py game.tzx game-re/ [--rzx play.rzx]
cd game-re && make            # must print IDENTICAL
git init && git add -A && git commit -m "re: init"
claude                        # AGENTS.md + skills/ drive the rest
```

`zxinit.py` copies `template/` (Makefile, AGENTS.md, skills) and `tools/` into
the project, so each project is self-contained.

## Tools

| Tool | Purpose |
| --- | --- |
| `tools/zxinit.py` | tape → project: split, simulated load, image, coverage, ctl, skool, build glue |
| `tools/zxrun.py` | headless runner on SkoolKit's C simulator: scripted keys/Kempston, fuzz, execution map, per-frame hashes, screenshots, write watchpoints, shift test loading, `--call` a game routine and save the screen (renders levels for docs) |
| `tools/zxq.py` | skool split into one file per entry; show/refs/next/status/unexec/peek/strings/gfx/reclassify/check/const/equs/cmp/export |
| `tools/zxtape.py` | TAP/TZX ↔ text manifest + payloads, byte-exact rebuild, per-block diff |
| `tools/zxbasic.py` | lossless BASIC ↔ text (hidden numbers, REM code, odd lines) |
| `tools/zxgfx.py` | colour sprite/tile sheets from memory, for the docs gallery |
| `tools/zxcompare.py` | compare our skool with a reference disassembly: bytes, classification, boundaries, documentation, magic numbers |
| `tools/zxdiff.py` | differential tests: a Z80 routine against a Python model or port on generated cases by kind; `--dump` writes golden cases for a C port |
| `tools/zxdoctor.py` | readiness check: tools, versions, and what a project is missing, with the fixing command |

Working registers in every project: `re/questions.md` (what the work must
answer, with status) and `re/findings.md` (claims with status observed /
inferred / unknown / refuted and their evidence), edited through
`zxq.py question|finding` and summarised by `make audit`. The evidence
discipline, the question list and the per-routine differential tests follow
ideas from [REA](https://github.com/morluto/rea) and the reconstruction
projects built with it.

## Self-test

```sh
selftest/run.sh
```

Builds a small fixture game (`selftest/demo.asm`, BASIC loader with hidden
numbers), runs init, behaviour test, reclassification, relocation, shift test
and export, a differential test, the registers and the doctor, and checks
byte identity at each step. Ends with `SELFTEST PASSED`.

## Limits

- `zxrun.py` is 48K only and has no memory contention: frame hashes check
  logic, not cycle-exact effects (multicolour, border tricks). Check those in
  Fuse or ZEsarUX by eye.
- `zxinit.py` automates standard headed blocks. Custom loaders, headerless and
  encrypted blocks are handled by the `zx-init` skill with the agent.
- `zxbasic.py` knows 48K keywords only (128K `SPECTRUM`/`PLAY` come out as `\A3`/`\A4`).
