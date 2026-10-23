# Stage 4: clean game logic, the Spectrum look kept

Status: built for Hungry Horace in faithful mode (2026-10-23; results at
the end). How to do it: the `zx-clean` skill. Stage 3 (`port.md`) is the
starting point: a port that keeps the asm's memory layout and is identical
to the Z80 at every pass of the main loop.

Decisions:

1. **Faithful first.** Stage 4 reproduces stage 3's behaviour, quirks
   included. Fixing a quirk is a deviation, switched on by a flag and
   recorded in a register, never a silent change.
2. **In slices.** The new code is written one stage 3 module at a time by
   subagents. Planned with teacher forcing; built more simply: stage 3,
   already identical to the Z80, is the oracle. While it replays a record,
   every call of a stage 3 routine is decoded before and after, and the
   stage 4 routine must turn the one into the other (see Tests). Every call
   in the recorded runs is a test case, and no slice needs the others.
3. **The display API lives in `zxpyxel`.** The same calls draw a stage 4 port
   and a new game in the Spectrum style, so this is also the
   drawing layer that `port.md` plans for new games.
4. **The oracle runs live.** The checks run stage 3 next to stage 4 rather
   than reading golden files; the language-neutral golden runs below are
   written when stage 5 needs them.

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

## The oracle and golden runs

The checks compare stage 4 with stage 3, which `make port-test` keeps
identical to the Z80 (and which the oracle checks against the Z80 again as
it runs):

- **State.** A decoder, written once per game (`bridge/decode.py`), reads
  stage 3 memory into the stage 4 state; scratch memory is left out.
- **Input.** The reads stage 3 makes in a step become its Actions, decoded
  the way the stage 3 routine that made them reads them; input is matched
  per step, never per frame or per `IN`.
- **Sound.** The speaker edges in a step, named by the stage 3 routine that
  made them (repeats collapsed when compared).
- **Interrupts.** The interrupts the Z80 took in a step (in the record) are
  an action: a timing effect the logic cannot know.

Step boundaries are the stage 3 checkpoints of the main loop and of the
title loop. The decoder and the oracle are the stage's only
Spectrum-specific test code (`bridge/`); they go when stage 4 records its
own golden runs.

Golden files, for stage 5: one JSON object per step (`actions`, `state`,
`sounds`, the screen's hash and changed cells), written from the same
oracle; build files (`build/golden/`), since they are made from game data.

## Tests

| # | Test | Catches | Built |
| --- | --- | --- | --- |
| 1 | every call of a stage 3 routine: the stage 4 routine on the decoded state before must give the state after, the same Goto, the same sounds (`bridge/oracle.py routine`, all routines in one replay) | a slice's errors, before the slices are put together | yes |
| 2 | the game step by step: state and sounds, every sound synthesised (`make stage4-test`) | any difference in the rules or the flow; a sound the synthesiser cannot take | yes |
| 3 | the screen: `render(state)` through `zxpyxel.display` against stage 3's screen, byte for byte | drawing errors, lost traces of the original's incremental drawing | yes, every 50th step |
| 4 | coverage: every stage 4 routine runs in some record | a slice that passes only because nothing reached it | yes |
| 5 | scenarios: the state of step N loaded, K steps run | rare events in seconds | no: test 1 covers them on every recorded call |
| 6 | free play: random keys through the pacer as a host runs it, invariants after every step (positions on the screen, counters in range, no run of steps without time) | errors outside the recorded runs, a pacer that hangs | yes (`oracle.py play`) |
| 7 | the clock: the Shows' seconds against the Z80's at the last pass | a wrong pacer | yes: demo +0.1%, play -0.5%, bell +0.8% |

Deviation register (`re/deviations.md`): each quirk the faithful mode keeps
and a fixed mode may drop (`OR C` for `OR E` in TickGuardTimers, the delay
underflow at paces 1-3, the guard that picks up another guard's items, the
bell scored at a distance), with the finding it comes from. Faithful mode
must pass the oracle; a fixed mode records its own golden runs, which
become the reference for stage 5. The stack leak of the demo abort has no
equivalent and is not a deviation.

## Order of work

1. **Harness** (lead): the state (from `docs/02-data.md` and
   `variables.asm`), `bridge/decode.py`, `bridge/assets.py`,
   `bridge/oracle.py`, the leaf helpers (`world.py`, checked against the
   stage 3 library routines with test 1).
2. **Slices**, one subagent per stage 3 module, in parallel, against a
   contract: which stage 4 routine stands for which stage 3 routine, the
   signatures, which are generators, which return a flow target. Each
   passes test 1 on every record.
3. **Integration** (lead): the flow (`Game.step`), test 2 on every record:
   the stage's gate. Then the deviations, each behind its flag.
4. **Hosts**: Pyxel (`game/play.py`, `make game-html`); another framework is
   another host over the same display, sounds and controls.

## Hungry Horace

Where the effort went: not into the API but into the model. The game's logic reads the screen:
collisions are attribute colours (walls, flowers, the bell, guards), and each
guard carries the four cells under it, which is how fruit appears and how a
guard can pick up another guard's items. The clean model is a 32×24 grid of
what each cell holds, with Horace and the guards moving over it and saving
what they cover; several quirks come from drawing order (who is drawn last
owns the cell's colour) and are modelled on purpose or registered as
deviations. The rest (score, timers, pace, the demo's autopilot) maps
directly from stage 3.

Built (`examples/hungry-horace/`): `game/horace/` (state, world, movement,
sprites, events, flow, render, sounds, controls; about 900 lines), `game/play.py`
(a pacer over `zxpyxel.pyxel_host.run_display`), `bridge/` (decoder, assets,
oracle). The lead wrote the state, the world helpers, the flow and the
bridge; three subagents (Sonnet) ported movement, sprites and events in
parallel from the `zx-clean` skill and a contract.

| Check | Result |
| --- | --- |
| routines: every call of 17 stage 3 routines on the three records | all match (demo 2,384 passes, play 5,536, bell 15,567) |
| the game, step by step: state and sounds | demo 2,664 steps, play 5,544, bell 15,576: all match |
| the screen, rendered through `zxpyxel.display` | byte for byte equal to stage 3's (every 50th step) |
| coverage | every stage 4 routine runs in some record |
| free play, headless | 300 s of play in 19 s |

Found on the way: the oracle first collapsed repeated sounds across a whole
step, which hid a second chirp in the same step from the routine check (two
subagents diagnosed it independently); it now records every speaker edge and
collapses repeats only when it compares. The contract had left the data of
the sound effects open, so the noise and the chime came out in a shape the
synthesiser did not expect; the free-play run caught it (both are now
checks: every sound is synthesised in the game check, free play is part of
`make stage4-test`). The first free-play check also showed that a step may
take no time: the original goes from the exit arrows into the next maze's
first pass without a frame. Not done yet: deviations (a fixed mode), the
golden files for stage 5.

## Stage 5

The logic, now plain data and functions, goes to C/C++ (SDL2 or a platform
library) or JS. The golden runs are the tests, unchanged; the display,
sound and controls are what each platform reimplements, and the Spectrum
look comes with the display's byte layout.
