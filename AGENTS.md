# AGENTS.md — developing ZX-REAPER

This repository is the harness, not a game project. Game projects are created
from it with `tools/zxinit.py`; their instructions are `template/AGENTS.md`
and `template/skills/`, which get copied into each project.

## Rules

- `selftest/run.sh` must end with `SELFTEST PASSED` before every commit. It
  builds the fixture game and runs the whole pipeline.
- Tools use the Python standard library plus SkoolKit only (pinned in
  `requirements.txt`, with Pyxel for the zxpyxel host). sjasmplus and make
  are the only other programs.
- A tool change that projects need goes to `tools/`; a rule for the agents goes
  to `template/AGENTS.md` or the matching skill. Keep each skill about one stage.
- `examples/hungry-horace/` is a finished project with its own copies of the
  tools and skills, frozen at the time of the run. Update it only on purpose
  (copy the changed tools in, then `make`, `make test`, `make diff` there with
  the tape in `original/`).
- Never commit game tapes, snapshots or RAM images made from them (`re/*.z80`,
  `port/image.bin`) or split tape blocks (`re/tape/`).
- `docs/method.md` (the method, in Russian) and `docs/hungry-horace-run.md`
  are the master copies; the author's notes are synced from them. Keep the
  method in step when a stage changes.

## Port everywhere

The harness works toward five stages (README, "Port everywhere"): 1 tape →
automatic disassembly → tape, 2 → annotated asm → tape, 3 → Python on the
`zxpyxel` library over Pyxel with the same screens and behaviour, 4 → plain
Python game logic on any framework, 5 → C/C++ or JS. Stages 1 and 2 are
built; stage 3 is built and done on Hungry Horace (`docs/port.md`, skill
`zx-port`); stage 4 is built and done on Hungry Horace in faithful mode
(`docs/stage4.md`, skill `zx-clean`); 4 and 5 are optional and done per
project.

- Every stage ends with a check against the stage before it: byte-identical
  tape and snapshot (1, 2), the same game memory at every checkpoint under
  replayed input (3), golden runs recorded from the previous stage (4, 5).
  A stage without its check is not done.
- `zxpyxel/` is one library for ports and for new ZX-style games (the master
  copy is here; hyperdream switches to it from its prototype copy). It is standard-library Python
  except its host module, which alone imports Pyxel; another framework is
  another host module, not a change to the core or to games. It is copied
  into projects, like `tools/`.
- 48K only until a 48K game has been through stage 3. AY goes through
  pyayay when it comes.
- `docs/port.md` is the design until the code exists; once a part is built,
  the code and the `zx-port` skill are the reference and the design note
  shrinks to the reasons.
