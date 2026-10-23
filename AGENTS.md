# AGENTS.md — developing ZX-REAPER

This repository is the harness, not a game project. Game projects are created
from it with `tools/zxinit.py`; their instructions are `template/AGENTS.md`
and `template/skills/`, which get copied into each project.

## Rules

- `selftest/run.sh` must end with `SELFTEST PASSED` before every commit. It
  builds the fixture game and runs the whole pipeline.
- Tools use the Python standard library plus SkoolKit only (pinned in
  `requirements.txt`). sjasmplus and make are the only other programs.
- A tool change that projects need goes to `tools/`; a rule for the agents goes
  to `template/AGENTS.md` or the matching skill. Keep each skill about one stage.
- `examples/hungry-horace/` is a finished project with its own copies of the
  tools and skills, frozen at the time of the run. Update it only on purpose
  (copy the changed tools in, then `make`, `make test`, `make diff` there with
  the tape in `original/`).
- Never commit game tapes, snapshots made from them (`re/*.z80`) or split tape
  blocks (`re/tape/`).
- The method note in the Obsidian vault describes why things are done this
  way; keep it in step when a stage changes.
