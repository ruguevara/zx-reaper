---
name: zx-clean
description: Stage 4 of Port everywhere - rewrite a game's stage 3 Python port as clean game logic over plain state (no addresses, registers or T-states), the Spectrum look kept through zxpyxel.display, checked against stage 3 routine by routine and step by step. Use after make port-test passes, to start or continue stage 4, or as a subagent porting one module of it.
---

# zx-clean

Stage 3 (`port/`, skill `zx-port`) is the game in Python with the original's
memory layout, identical to the Z80 at every pass of the main loop. Stage 4
(`game/`) is the same game as plain Python: a state of plain values, routines
that read like the rules, events for sound and time. It looks the same (the
32x24 cells, attributes, colour clash, the ROM font) through
`zxpyxel.display`. Design and reasons: zx-reaper's `docs/stage4.md`.

## Layout

| Path | What |
| --- | --- |
| `game/<pkg>/` | the stage 4 game, a package (its module names must not clash with `port/`) |
| `game/<pkg>/constants.py` | the rules' numbers, hand-picked from `src/constants.asm`, names kept; no addresses |
| `game/<pkg>/state.py` | the state: dataclasses of plain values; `Actions`, `Sound`, `Show` |
| `game/<pkg>/assets.py` | loads `game/assets.json`: graphics as bytes, maps, texts |
| `game/<pkg>/world.py` | the leaf helpers (what stage 3's library did, on positions) |
| `game/<pkg>/flow.py` | `Game`: start, `step(actions)`, the flow between title, play and game over |
| `game/assets.json` | game data from the original's image (`python bridge/assets.py`); never committed |
| `bridge/` | the only code that sees both stages: `decode.py` (stage 3 memory -> state), `assets.py`, `oracle.py` (the checks), `routines_<module>.py` (which stage 4 routine stands for which stage 3 routine) |

`game/` never imports `port/` or anything with an address. The bridge is
test and build code. Setup: `cp -R port/zxpyxel game/` (the library, as in
`port/`), then `make game/assets.json`; `make stage4-test` is the gate,
`python game/play.py` plays it, `make game-html` builds the web page.

## The state

- Plain values: positions are (col, row) of a figure's top-left cell,
  directions and counters are ints, flags are bools, figures are dataclasses.
  No addresses, no screen offsets, no registers.
- What the game keeps between steps, and nothing else: drop scratch memory (a
  working buffer a record is copied into, an AI's score table), dead
  variables and values only stage 3's check needed (`# check:` in stage 3).
- If the game's rules read the screen (collision by colour, figures that save
  what they cover), the screen is part of the state: a grid of cells, each an
  8x8 glyph and an attribute. That is the game's real world model; render
  draws it.
- Random numbers keep the original's source (the ROM bytes the game reads),
  as a pointer in the state.

## Routines

- One stage 4 routine per stage 3 routine the oracle can check, snake_case,
  docstring first line in game terms, then `(stage 3: Name)`.
- Arguments are meaningful values (`show_score(s, value)`), never registers;
  `s` is the state, `a` the Actions where the routine reads input.
- Keep every quirk of the original (findings, stage 3 comments): stage 4 is
  faithful first. A fix comes later as a deviation behind a flag, with its own
  golden runs (docs/stage4.md).
- Sound and time are events. A routine that makes a sound or holds the game
  is a generator: `yield Sound('chirp')` where the original starts the effect
  (only when it is audible: the original's mute masks the beeper), `yield
  Show(seconds)` where stage 3 awaited `zx.sync()` (the state as it is now is
  shown that long). Callers `yield from` it. Seconds: the effect's length
  from `sounds.py`, or a closed form of stage 3's loop; not tested, judged
  by eye. Each effect's name and `data` (an order, random lengths) are part
  of the contract: `sounds.py` turns them into speaker edges.
- Loops over figures run in stage 3's order (LoadGuardRecord(b) visits b = 4
  down to 1, or up): figures draw over each other and save what they cover,
  so the order is behaviour. `bridge/decode.py` says which stage 3 record is
  which entry of the state.
- A stage 3 `raise Goto(Target)` is a return value: the routine returns
  `'Target'` (a generator returns it, `x = yield from f(s)`); the step in
  `flow.py` goes on there.

## Checks

The bridge runs stage 3 on the Z80 records of `make port-test`
(`build/record/*.rec`), so stage 3 is checked against the Z80 at the same
time, and compares:

1. **Routines** (while porting): `bridge/routines_<module>.py` maps the stage
   3 routine name to `(clean, convert)`: the oracle calls `clean(state,
   actions, *convert(*stage3_args))` on a copy of the decoded state before
   every call of the stage 3 routine, and compares the decoded state after,
   the return value (a Goto: the target's name) and the sounds.
   `python bridge/oracle.py routine Name [--max=N] build/record/*.rec`. A
   routine that works on stage 3 scratch memory (a working buffer) is checked
   through its caller.
2. **The game** (the stage's gate): `python bridge/oracle.py game
   build/record/*.rec` (`make stage4-test`) runs `Game` in lockstep with stage
   3: at every step boundary (a pass of the title loop or of the main loop) the
   same Actions go in, and the state and the sounds must be equal.

A mismatch names the fields (cells by col and row) with both values. Read
the stage 3 routine and its asm header, not just the failing field. The
oracle runs stage 3 and decodes the state around every call, about a minute
per routine for three records: use `--max=N` while iterating and run one
routine per command (several in parallel). The game check also compares the
rendered screen byte for byte with stage 3's every 50 steps, and lists the
stage 4 routines no record ran.

## Orchestration

The lead writes `state.py`, `world.py`, `assets.py`, `flow.py`, the bridge,
and the contract (which stage 4 routine stands for which stage 3 routine,
signatures, which are generators, which return a flow target). Subagents
port one stage 3 module each into `game/<pkg>/<module>.py`, with their
registry file and the routine check passing on every record. The lead
integrates and runs the game check.
