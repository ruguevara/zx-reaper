# Stage 4: clean game logic, the Spectrum look kept

Status: design (2026-10-23), nothing built. Stage 3 (`port.md`) is the
starting point: a port that keeps the asm's memory layout and is identical
to the Z80 at every pass of the main loop.

Decisions:

1. **Faithful first.** Stage 4 reproduces stage 3's behaviour, quirks
   included. Fixing a quirk is a deviation, switched on by a flag and
   recorded in a register, never a silent change.
2. **In slices, with teacher forcing.** The new code is written one slice of
   behaviour at a time by subagents, each checked against the golden runs,
   with the slices not yet written fed from the golden run on every pass.
3. **The display API lives in `zxpyxel`.** The same calls draw a stage 4 port
   and a new game in the Spectrum style (hyperdream), so this is also the
   drawing layer that `port.md` plans for new games.

## What changes, what stays

Stays: the look (256×192 pixels, 32×24 attribute cells of ink and paper,
BRIGHT, FLASH, colour clash, the ROM font, the border), the game's rules, its
quirks (in faithful mode), its random sequence, the pace of the main loop.

Goes: memory addresses, display-file offsets, registers, T-states, beeper
loops, port reads, the working-buffer pattern (a record copied in, changed,
copied back), dead stores and scratch tables kept only for stage 3's check
(they carry `# check:` comments in stage 3).

## Layers

Three layers; only the lowest knows the Spectrum.

| Layer | What | Knows |
| --- | --- | --- |
| logic | `Game.step(actions) -> events`, one pass of the main loop | the rules, `GameState` |
| presentation | `render(state, display)`, sound effects as data, the pacer | `zxpyxel.display`, `zxpyxel.sound` |
| host | window, keys, audio, frames | Pyxel (or another host module) |

### Logic

```python
@dataclass
class GameState:                 # plain values, no addresses
    maze: Maze                   # 32x24 grid of what is in each cell
    horace: Horace               # cell, direction, animation, wrap pause
    guards: list[Guard]          # cell, direction, release timer, wait, saved cells
    score: int; best: int; passes: int
    bell: Bell; fruit: Fruit; pace: int; demo: bool; sound_on: bool
    wait: int                    # passes the logic is frozen (a blocking sound)

class Game:
    def __init__(self, rng: RomRandom, faithful=True): ...
    def step(self, actions: Actions) -> list[Event]: ...
```

- One `step` is one pass of the original main loop. The order inside a pass
  may change; the state after it may not.
- No I/O. What the original did with the hardware becomes an event:
  `Sound('chirp')`, `Wait(passes)` for a blocking sound or an animation that
  held the game, `Screen('title')` for a change of mode.
- Random numbers: `RomRandom` walks the ROM bytes as `GetRandom` and the
  guards' AI do (two pointers: RandomPtr and the FRAMES word). Replacing it by
  a real generator is a deviation.

### Display (`zxpyxel.display`)

```python
display.cls(Attr(ink=BLACK, paper=WHITE))
display.cell(col, row, glyph, attr)         # 8 bytes, one bit a pixel, and its colour
display.sprite(col, row, image, attr)       # a 16x16 image on 2x2 cells, cell-aligned
display.text(col, row, 'SCORE', attr)       # the ROM font
display.blocks(col, row, data, cols)        # the title's 2x2-block letters
display.border(WHITE)
display.attr(col, row) -> Attr              # read back, for the renderer only
```

The display writes display-file bytes and attributes, which `zxpyxel.screen`
already turns into palette indices for the host. So the look is exactly the
Spectrum's, and a stage 4 screen can be compared byte for byte with the
Z80's. A renderer redraws from the state each pass (768 cells are cheap);
where the original's incremental drawing leaves a trace a redraw would not,
the comparison shows it and it is modelled or registered as a deviation.

### Sound

Effects are data: the pitch steps and cycles of each beeper loop of the
original (`chirp`, `wrap`, `buzz`, `death`, `game_over`, `chime_low`,
`chime_high`), synthesised to PCM by `zxpyxel.sound`, played by the host
without blocking. The logic emits `Sound(name)`; the blocking the original
had is a `Wait(passes)`.

### Input

`controls.poll() -> Actions`: a direction, any key, the sound toggle (as an
edge). The keys are the original's (Q/Z/I/P and the number row, T) with the
original priority when several are held; the host maps its keys and gamepad
to them.

### Time

A pacer runs the logic at the original speed: passes per second from the
pace formula (`PaceAndChime`'s delay at each GuardInterval, measured against
the Z80 clock in the records). There are no T-states in the logic.

## Golden runs

The tests compare stage 4 with the Z80, through files that know nothing of
the Spectrum:

- **State.** A decoder, written once per game, reads stage 3 memory (`v`,
  `mem`) into a normalised `GameState`. The Z80 records of stage 3 already
  hold the whole memory at every pass, so the golden state comes from the
  Z80 itself, not from stage 3.
- **Input.** The reads recorded between two checkpoints become the keys
  known held or not during that pass (each read names its half-row), so
  input is matched per pass, never per frame or per `IN`.
- **Screen.** The display file and attributes at the pass, from the record.
- **Sound.** The effects started in each pass, from stage 3 instrumented to
  name its sound routines (stage 3 is identical to the Z80, so it is a valid
  oracle here).

Format: one JSON object per pass (`keys`, `state`, `sounds`, a hash and the
cells of the screen), so stage 5 in C or JS reads the same files. The golden
runs are build files (`build/golden/`): they are made from game data.

The decoder, the input decoding and the screen comparison are the stage's
only Spectrum-specific test code, in one adapter module; it is deleted when
stage 4 records its own golden runs.

## Tests

| # | Test | Catches |
| --- | --- | --- |
| 1 | state per pass against the golden runs | any difference in the rules |
| 2 | screen per pass: `render(state)` against the recorded screen, with a side-by-side PNG and the differing cells on failure | drawing errors, lost traces of the original's incremental drawing |
| 3 | sound effects per pass against stage 3's | missing or misplaced effects; optionally each effect's waveform against stage 3's speaker edges |
| 4 | scenarios: the state of pass N of a golden run loaded, K passes stepped, compared | rare events (the bell, a death, the exit) in seconds, without replaying the run |
| 5 | invariants under random actions: Horace never inside a wall, at most four guards, the score never falls within a game, a pass for every 10,000 points | errors outside the recorded runs |
| 6 | coverage: every logic function runs in some golden run | a slice that passes only because nothing reached it |
| 7 | speed: passes per second at each pace against the record's clock, within a tolerance | a wrong pacer (soft check, judged by eye too) |

Deviation register (`re/deviations.md`): each quirk the faithful mode keeps
and a fixed mode may drop (`OR C` for `OR E` in TickGuardTimers, the delay
underflow at paces 1-3, the guard that picks up another guard's items, the
bell scored at a distance), with the finding it comes from. Faithful mode
must pass the golden runs; a fixed mode records its own golden runs, which
become the reference for stage 5. The stack leak of the demo abort has no
equivalent and is not a deviation.

## Order of work

1. **Harness.** The `GameState` dataclasses (from `docs/02-data.md` and
   `variables.asm`), the decoder, golden runs from the records, the stage 4
   check with teacher forcing, the scenario loader. Proof: stage 3, decoded,
   passes its own golden runs.
2. **Slices**, one subagent each, in parallel where they do not share state:
   maze and Horace's movement; the guards' AI; eating and score; bell and
   fruit; death, game over and the demo; rendering; sound. Before each pass
   of a slice's test, the fields of the slices not yet written are copied
   from the golden run; after it, only the slice's fields are compared.
3. **Integration.** Forcing off, everything compared on every run: the
   stage's gate. Then the deviations, each behind its flag with its own
   golden runs.
4. **Hosts.** Pyxel as in stage 3 (desktop, `make port-html`); another
   framework is another host module over the same display, sound and
   controls.

As in stage 3, the lead writes the contract first: `GameState`, the
signatures of `step` and `render`, the events, which fields belong to which
slice.

## Hungry Horace: where the effort will go

Not into the API but into the model. The game's logic reads the screen:
collisions are attribute colours (walls, flowers, the bell, guards), and each
guard carries the four cells under it, which is how fruit appears and how a
guard can pick up another guard's items. The clean model is a 32×24 grid of
what each cell holds, with Horace and the guards moving over it and saving
what they cover; several quirks come from drawing order (who is drawn last
owns the cell's colour) and are modelled on purpose or registered as
deviations. The rest (score, timers, pace, the demo's autopilot) maps
directly from stage 3.

## Stage 5

The logic, now plain data and functions, goes to C/C++ (SDL2 or a platform
library) or JS. The golden runs are the tests, unchanged; the display,
sound and controls are what each platform reimplements, and the Spectrum
look comes with the display's byte layout.
