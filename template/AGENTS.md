# AGENTS.md — reverse engineering and porting a ZX Spectrum game

Goal: sources (asm, BASIC, data, tape manifest) that build a tape **byte-identical**
to `original/`, readable enough for a human to change the game (stages 1 and 2);
then, if the project goes on, the game in Python with the original's memory
layout (stage 3, `port/`) and as clean game logic (stage 4, `game/`), each
checked against the stage before.

## The one rule

`make` must print `IDENTICAL` after every change you keep. Run it after each edit
batch; if it fails, fix or revert before doing anything else. Commit only green
states (`git commit -m "re: <what>"`). Never edit `original/`.

## Layout

| Path | What |
| --- | --- |
| `original/` | the untouched tape (reference) |
| `re/skool/XXXX.skool` | master source while annotating: one SkoolKit entry per file, named by hex address |
| `re/image.z80` | load-time memory image the skool files describe |
| `re/orig.z80` | machine state at handover to the game (after the loader) |
| `re/maps/*.map` | code execution maps (coverage) |
| `re/notes.md` | memory map, loader notes |
| `re/questions.md` | what the work must answer, with status (`tools/zxq.py question`) |
| `re/findings.md` | claims with status observed / inferred / unknown / refuted and evidence (`tools/zxq.py finding`) |
| `re/pokes.md`, `re/pokes.pok` | POKEs and cheats with how each was checked; the .pok in the World of Spectrum format (skill `zx-poke`) |
| `tests/models/*.py` | executable models of routines, checked against the Z80 code (`make diff`) |
| `src/build.asm` | assembles the game, `SAVEBIN`s each tape block |
| `src/*.bas` | BASIC loaders, lossless text (`tools/zxbasic.py`) |
| `src/game.asm`, `src/*.asm` | master source after `make export` |
| `data/` | blocks kept as binary (loading screen, unknown blocks) |
| `tape/tape.txt` | tape manifest: block order, headers, timings, payload files |
| `tests/inputs/*.txt` | input scripts; `tests/expected/*.hash` their recorded frame hashes |
| `scripts/rules.mk` | extra build steps (encryption, compression), optional |
| `port/` | stage 3: the game in Python on `port/zxpyxel/`, checked by `make port-test` (skill `zx-port`) |
| `game/` | stage 4: the game as clean logic, its data as editable files in `game/assets/`, checked by `make game-test` (skill `zx-clean`) |
| `bridge/` | stage 4's link to stage 3: the decoder, the asset extraction, the oracle |

## Tools (run from the project root)

```
make / make test / make status / make labels / make shift-test / make export / make help
make doctor / make diff / make audit
make port-test / make game-test / make port-html / make game-html
tools/zxq.py next 20                 what to annotate next (dependencies first)
tools/zxq.py show $8000              one entry + its callers and callees
tools/zxq.py refs $5C00              who reads, writes, calls an address
tools/zxq.py peek $9000 64 | strings 5 [START END]
tools/zxq.py gfx $A000 256 2 /tmp/s.png [cells]   look at bytes as a bitmap, then view the PNG
tools/zxq.py unexec re/maps/*.map    code never executed (data candidates)
tools/zxq.py reclassify frag.ctl     re-disassemble a range from a control-file fragment
tools/zxq.py cut $8C4A "Title"       split an annotated entry at an address, keeping its annotation
tools/zxq.py check                   byte check in a private build dir (use this, not make, in parallel agents)
tools/zxq.py const [NAME VALUE TEXT] numeric constants (src/constants.asm), used via @isub
tools/zxq.py equs [--uses]           address names (@equ) and every operand they replace
tools/zxrun.py re/orig.z80 --input tests/inputs/x.txt --shot 200:/tmp/a.png --map re/maps/x.map
tools/zxrun.py re/orig.z80 --frames 300 --watch $5C00-$5C0F --watch-from 250   # who writes here
tools/zxpoke.py profile|search|writers|check|keys ...   POKEs and cheats (skill zx-poke)
```

## Token discipline

- Never print a whole skool, asm, lst or map file. Read entries with `zxq.py show`,
  find things with `zxq.py refs`, `grep -l` over `re/skool/`, `zxq.py strings`.
- Look at graphics as PNG (`zxq.py gfx`, `zxrun.py --shot`), not as DEFB lists.
- Ask the simulator instead of reasoning through code by hand: watch a write,
  take a screenshot at a frame, run until an address (`--stop`).
- Edit with small, exact replacements in the one entry file you are working on.

## Work loop

Phases (details in the skills in `skills/`):
1. `zx-init` — project from the tape; loader analysis when blocks are not standard.
2. `zx-coverage` — input scripts / RZX until the code map stops growing.
3. `zx-classify` — code vs data vs text vs graphics; memory map in `re/notes.md`.
4. `zx-annotate` — names, titles, descriptions; the bulk of the work.
5. `zx-relocate` — symbolic operands until `make shift-test` passes.
6. `zx-export` — modules in `src/`, final pass, README.
7. `zx-document` — the article in `docs/`: how the game works, top-down, with
   a PNG gallery of sprites, tiles and level maps and links into `src/`.
8. `zx-port` — executable models of routines (annotation proof, any time after
   annotation) and stage 3: the port to Python routine by routine against the
   Z80 code, `make port-test`.
9. `zx-clean` — stage 4: the port as clean game logic in `game/`, checked
   against stage 3, `make game-test`.
- `zx-poke` — POKEs (lives, time, start room, invulnerability) and the
  developers' cheats, each checked in the simulator: `re/pokes.md`,
  `re/pokes.pok`, `make pokes`. Any time after the main variables are named.

Orchestration: the lead agent plans, classifies, relocates and reviews. Bulk
annotation goes to subagents (cheaper model) in batches of 5–15 related entries
from `zxq.py next`; each subagent edits only the files it was given and returns
the new labels and one-line titles, and proposes splits where a second routine
starts inside an entry. The lead applies splits with `zxq.py cut`, runs `make`,
commits, and repeats. In a port the lead writes the control flow and a contract
(signatures, events, what other modules call); subagents port one module each
and pass its check before the lead puts them together. Size a subagent's task
to finish well within an hour (split a module of over ~1,500 lines). A
subagent that goes quiet: read its last step and resume it with a message;
do not wait for the human, and do not start a duplicate.

## Conventions

- Addresses and numbers in hex (`$8000`). Never change an instruction's bytes.
- Labels: routines `VerbNoun` (`DrawSprite`, `ReadKeys`), data and variables
  `NounPhrase` (`SpriteTable`, `PlayerX`), constants `UPPER_CASE`. Unique, ≤ 24 chars.
- A label is set once, with `@label=` on the instruction; operands stay numeric in
  skool files and skool2asm turns them into labels.
- No magic numbers in the final asm: addresses outside the code get `@equ` names
  (ROM, system variables, screen), numbers get constants from `src/constants.asm`
  through `@isub`, self-modified operands are `Label+1`. Details: `zx-annotate`.
- Descriptions say which hardware a routine touches (`Hardware:` sentence) and
  data descriptions give field layouts: the sources must be portable to C or
  Python on a Spectrum-like platform library.
- Entry title: one line saying what it is. Description: what, inputs (`R` lines),
  outputs, side effects. Instruction comments only where the intent is not obvious
  from the code; no `INC A ; increment A`.
- Unknown is fine: write `Unknown` / `TODO:` in a comment instead of guessing.
  A wrong name costs more than a missing one.
- Keep observation, inference and unknowns apart: a claim others build on goes
  into `re/findings.md` with its status and evidence; only a run (simulator,
  test, model) makes it `observed`. "Not executed" from coverage is bounded by
  the inputs used, not proof of dead code.
- Facts that span many entries (memory map, data formats) go to `re/notes.md`.

## Ask the human when

- coverage stops growing and the missing parts need real play (record an RZX in
  Fuse and drop it in `re/rzx/`, or take one from the RZX Archive);
- the loader is protected and you need a decision on how far to reproduce it;
- a build difference persists after two attempts to explain it.
