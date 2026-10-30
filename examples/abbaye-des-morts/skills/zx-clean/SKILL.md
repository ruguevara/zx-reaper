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
| `game/<pkg>/assets.py` | loads and checks `game/assets/`: graphics as bytes, maps, texts |
| `game/<pkg>/world.py` | the leaf helpers (what stage 3's library did, on positions) |
| `game/<pkg>/flow.py` | `Game`: start, `step(actions)` (or `run()`, see Routines), the flow between title, play and game over |
| `game/assets/` | the game's data as editable files, from the original's image (`python bridge/assets.py`); never committed |
| `bridge/` | the only code that sees both stages: `decode.py` (stage 3 memory -> state), `assets.py`, `oracle.py` (the checks), `routines_<module>.py` (which stage 4 routine stands for which stage 3 routine) |

`game/` never imports `port/` or anything with an address. The bridge is
test and build code. Setup: `cp -R port/zxpyxel game/` (the library, as in
`port/`), then `make game/assets/state.json`; `make game-test` is the gate,
`python game/play.py` plays it, `make game-html` builds the web page.

## The state

- Plain values: positions are (col, row) of a figure's top-left cell,
  directions and counters are ints, flags are bools, figures are dataclasses.
  No addresses, no screen offsets, no registers.
- What the game keeps between steps, and nothing else: drop scratch memory (a
  working buffer a record is copied into, an AI's score table), dead
  variables and values only stage 3's check needed (`# check:` in stage 3).
  A value the original keeps from one step to the next is state however
  deep it sits (what IT refers to, the last command matched, the typed
  line's buffer): a field and a line in the decoder, not an attribute of
  `Game`. A dict of scratch values that is not compared
  holds only what lives within one step.
- If the game's rules read the screen (collision by colour, figures that save
  what they cover), the screen is part of the state: a grid of cells, each an
  8x8 glyph and an attribute. That is the game's real world model; render
  draws it.
- Random numbers keep the original's source (the ROM bytes the game reads),
  as a pointer in the state.

## Assets

Always as files a person can edit with ordinary tools, wherever the data
has such a form; bytes only where it has none:

- Graphics: PNG, through `zxpyxel.png` (standard library). One sheet per kind
  (tiles, each figure's frames, fonts), drawn in the game's colours on its
  paper. The loader turns them into 8-byte cells and checks them as they
  load: the size, Spectrum colours only, one ink per 8x8 cell on the paper,
  as on the hardware; an error names the file, the cell or pixel, and what
  was expected. Where a cell's colour is data (fruit drawn in red and
  green), it comes from the ink.
- Maps: text, one character a tile, a legend at the top, a header line per
  map for its positions.
- Texts, positions, tables: JSON. The state as loaded (the variables before
  the game starts): JSON.
- Bytes (`.bin`) only for data with no better form. What zxpyxel ships (the
  ROM's font and bytes) is not copied.

`bridge/assets.py` writes the files once and keeps them after that (edits
are not overwritten; `--force` writes them again). `make game-test` is the
round-trip check: the game loads the files and must still match stage 3.

## Routines

- One stage 4 routine per stage 3 routine the oracle can check, snake_case,
  docstring first line in game terms, then `(stage 3: Name)`.
- Arguments are meaningful values (`show_score(s, value)`), never registers;
  `s` is the state, `a` the Actions where the routine reads input.
- Keep every quirk of the original (findings, stage 3 comments): stage 4 is
  faithful first. A quirk a slice finds that is not a finding yet goes into
  `re/findings.md` (the lead adds it from the slice's report). A fix comes later as a deviation behind a flag, with its own
  golden runs (docs/stage4.md).
- Sound and time are events. A routine that makes a sound or holds the game
  is a generator: `yield Sound('chirp')` where the original starts the effect
  (only when it is audible: the original's mute masks the beeper), `yield
  Show(seconds)` where stage 3 awaited `zx.sync()` (the state as it is now is
  shown that long). Callers `yield from` it. Seconds: the effect's length
  from `sounds.py`, or a closed form of stage 3's loop; not tested, judged
  by eye. Time the original spends building a screen (a picture drawn line
  by line) is Shows too, measured on the Z80 (`zxrun.py --stop` at the
  start and the end), or a deviation the stage note names. Each effect's name and `data` (an order, random lengths) are part
  of the contract: `sounds.py` turns them into speaker edges.
- Loops over figures run in stage 3's order (LoadGuardRecord(b) visits b = 4
  down to 1, or up): figures draw over each other and save what they cover,
  so the order is behaviour. `bridge/decode.py` says which stage 3 record is
  which entry of the state.
- A stage 3 `raise Goto(Target)` is a return value: the routine returns
  `'Target'` (a generator returns it, `x = yield from f(s)`); the step in
  `flow.py` goes on there. A routine that can return a target returns the
  target or None, never True/False as well: a caller's `if not ok` lets a
  target through as success.
- A game that waits inside a pass (a line editor, "press any key", a scroll
  pause) is one generator, `Game().run()`, instead of `step(actions)`: it
  yields requests the driver answers by `send` (a key, R, a byte a random
  routine read, a saved state, whether a printer answers), waits, output,
  and `Step()` at the top of the main loop, where the checks compare. Every
  input the original reads is such a request, never a constant in the
  code: the oracle answers from the record, the pacer from the host.

## Checks

The bridge runs stage 3 on the Z80 records of `make port-test`
(`build/record/*.rec`), so stage 3 is checked against the Z80 at the same
time, and compares:

1. **Routines** (while porting): `bridge/routines_<module>.py` maps the stage
   3 routine name to `(clean, convert)`: the oracle calls `clean(state,
   actions, *convert(*stage3_args))` on a copy of the decoded state before
   every call of the stage 3 routine, and compares the decoded state after,
   the return value (a Goto: the target's name) and the sounds.
   `python bridge/oracle.py routine Name[,Name...] [--max=N] build/record/*.rec`;
   `routine all` checks every registered routine in one replay. A routine
   that works on stage 3 scratch memory (a working buffer) is checked through
   its caller. With stage 3's register interface the map is `(clean,
   convert_in, convert_out)`: `convert_in(regs)` reads the stage 3 registers
   at the call (an IY that points at a phrase, an HL that is a message),
   `convert_out(regs)` the result. A handler no record reaches is checked
   with hand-built cases: stage 3 on the loaded image against stage 4.
2. **The game** (the stage's gate, `make game-test`): `python
   bridge/oracle.py game build/record/*.rec` runs `Game` in lockstep with
   stage 3: at every step boundary (a pass of the title loop or of the main
   loop) the same Actions go in, and the state and the sounds must be equal;
   every sound is synthesised; the rendered screen is compared byte for byte
   every 50 steps; the clock of the Shows is compared with the Z80's (keep it
   within a few per cent: fit the pass time); the routines no record ran are
   listed. Then `python bridge/oracle.py play`: random keys through the pacer
   as a host runs it (a text game types commands from its vocabulary, SAVE
   and LOAD among them), with invariants (positions on the screen, counters
   in range, no run of steps without time). The records do not test the
   pacer: it must answer every request, and each of its time constants (an
   idle time-out, a pause) is measured on the Z80 (`zxrun.py --watch` the
   counter, `--stop` where it runs out) and counted in T-states, not in
   whole loop passes per frame.

A mismatch names the fields (cells by col and row) with both values. Read
the stage 3 routine and its asm header, not just the failing field. The
oracle runs stage 3 and decodes the state around every call, about a minute
per routine for three records: use `--max=N` while iterating and run one
routine per command (several in parallel). The game check also compares the
rendered screen byte for byte with stage 3's every 50 steps, and lists the
stage 4 routines no record ran.

## Orchestration

The lead writes `state.py`, `world.py` (checked against the stage 3 library
routines first), `assets.py`, `sounds.py`, `flow.py`, the bridge, and the
contract; subagents port one stage 3 module each into
`game/<pkg>/<module>.py` with their `bridge/routines_<module>.py`, the
routine check passing on every record. The lead integrates and runs the
game check. The lead writes the pacer and `oracle.py play` with the flow,
before the slices, and runs free play at every integration: what the pacer
answers is not in any record, so its faults show only there. Handlers that
tables name register under their stage 3 names
(`registry.handler('VerbTake')`), so slices run each other's handlers by
name. With many slices, go in waves: the leaf slices (text, world) first,
then the rest in parallel against their written interfaces. The contract,
one line per routine other modules or the flow call:

| Stage 3 | Stage 4 | Arguments | Generator | Returns | Events |
| --- | --- | --- | --- | --- | --- |
| ShowScore(hl) | sprites.show_score | (s, value) | yes | - | Sound('chirp') |
| CheckGuardContact | events.check_guard_contact | (s) | yes | None or a flow target | Sound('buzz'), Show |
| PaceAndChime | events.pace_and_chime | (s) | yes | - | Sound('chime', low_first), Show(the pass) |

Every Sound's name and `data` come from `sounds.py`, written before the
slices: a shape left open comes back in a form the synthesiser does not take
(the game check now synthesises every sound, so it fails there).
