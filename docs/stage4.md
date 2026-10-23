# Stage 4: clean game logic, the Spectrum look kept

Status: built for Hungry Horace in faithful mode (`examples/hungry-horace/
game/`; results under "Hungry Horace"). How to do it: the `zx-clean` skill;
this note keeps the reasons.

Stage 4 rewrites the stage 3 port ([stage3.md](stage3.md)) as plain Python: a
state of plain values, routines that read as the rules, events for sound
and time. The look stays the Spectrum's. Stage 3, identical to the Z80 at
every pass of the main loop, is its oracle.

## Decisions

1. **Faithful first.** Stage 4 reproduces stage 3's behaviour, quirks
   included. Fixing a quirk is a deviation, switched on by a flag and
   recorded in a register, never a silent change.
2. **Stage 3 is the oracle, run live.** While stage 3 replays a recorded
   run, every call of a stage 3 routine is decoded before and after, and the
   stage 4 routine must turn the one into the other. Every call in the
   recorded runs is a test case, and no slice needs the others. (Planned as
   teacher forcing over golden files; built more simply.) The
   language-neutral golden files are written when stage 5 needs them.
3. **In slices.** The new code is written one stage 3 module at a time by
   subagents, against a contract the lead writes first.
4. **The display API lives in `zxpyxel`.** The same calls draw a stage 4
   game and a new game in the Spectrum style.
5. **The data is editable.** Graphics as PNG, maps as text, texts and the
   start state as JSON, checked as they load: a fork changes the game by
   editing them.

What stays: the look (256×192 pixels, 32×24 attribute cells of ink and
paper, BRIGHT, FLASH, colour clash, the ROM font, the border), the game's
rules, its quirks (in faithful mode), its random sequence, the pace of the
main loop. What goes: memory addresses, display-file offsets, registers,
T-states, beeper loops, port reads, the working-buffer pattern (a record
copied in, changed, copied back), dead stores and scratch tables kept only
for stage 3's check (they carry `# check:` comments in stage 3).

## Design

Three layers; only the lowest knows the Spectrum, and only the bridge knows
stage 3.

| Layer | What | Knows |
| --- | --- | --- |
| logic | `Game.step(actions)`, a generator of events | the rules, the state |
| presentation | `render(state, display)`, sound effects as data, controls, the pacer | `zxpyxel.display`, `zxpyxel.sound` |
| host | window, keys, audio, frames | Pyxel (`zxpyxel.pyxel_host.run_display`) or another host module |
| bridge (tests and build only) | stage 3 memory → state, the game's data → editable files, the oracle | stage 3, addresses |

### Logic

```python
@dataclass
class GameState:                 # plain values, no addresses (game/<pkg>/state.py)
    mode: str                    # 'title' or 'play'
    horace: Horace               # pos (col, row), next_pos, dir, attr, anim, wrap_pause
    guards: list                 # Guard: pos, new_pos, dir, anim, wait, timer, saved (the 4 cells under it)
    cells: list                  # the 32x24 grid: Cell(glyph, attr), an 8-byte glyph and an attribute
    score: int; best: int; passes: int; pace: int; bell: tuple | None  # ...
    random: int; frames: int     # the original's random pointers into the ROM

class Game:
    def step(self, actions):     # yields Sound(name, data) and Show(seconds)
```

- One step is one pass of the title loop or of the main loop, and whatever
  follows it up to the next one (a new maze, a lost pass, the game over and
  the title). The order inside a pass may change; the state after it may
  not.
- No I/O. Sound is `Sound(name, data)`; the time the original held the game
  (a frame, an animation, a blocking sound, the rest of a pass) is
  `Show(seconds)`: the state as it is then is shown that long.
- Where the original jumps away (stage 3's `Goto`), a routine returns the
  target's name, and the step goes on there.
- Random numbers keep the original's source: the ROM bytes, through the two
  pointers the game uses. Replacing them by a real generator is a deviation.

### Display (`zxpyxel.display`)

```python
d = Display()                    # d.data: 6912 bytes in the Spectrum's layout
d.cls(attr(BLACK, WHITE))        # attr(ink, paper, bright, flash) -> the attribute byte
d.cell(col, row, glyph, a)       # 8 bytes, one bit a pixel, and an attribute
d.sprite(col, row, graphic, a)   # 32 bytes on 2x2 cells
d.text(col, row, 'SCORE', a)     # the ROM font
d.border = WHITE
d.glyph(col, row); d.attr(col, row)
```

The display writes display-file bytes and attributes, which `zxpyxel.screen`
turns into palette indices for the host, so the look is exactly the
Spectrum's and a stage 4 screen compares byte for byte with stage 3's. The
renderer redraws every cell each time a Show comes (768 cells are cheap).

### Sound, input, time

- **Sound**: effects are data, the shapes of the original's beeper loops
  (`rising`, `chirp`, `wrap`, `buzz`, `noise` with its random lengths,
  `chime` with its order), turned into speaker edges and PCM by
  `zxpyxel.sound`, played by the host without blocking.
- **Input**: `controls.actions(keys)` turns the ZX keys held into Actions: a
  direction (the original's keys and priority), any key, the sound toggle.
  The host maps its keys and gamepad to ZX keys.
- **Time**: a pacer runs the steps and holds each Show for its seconds. The
  pass time is fitted to the clock of the recorded runs, so the game runs at
  the original's pace.

### Assets

The game's data is a folder of editable files (game data, never committed),
written once from the original's image by the bridge and kept after that:
PNG sheets for tiles and figures, loaded through `zxpyxel.png` and checked
(the size, Spectrum colours only, one ink per 8×8 cell on the paper; where a
cell's colour is data, it comes from the ink), maps as text with one
character a tile, texts and the start state as JSON. The ROM's font and
random bytes come from zxpyxel.

## Checks

The oracle runs stage 3 on the Z80 records of `make port-test` (so stage 3 is
checked against the Z80 at the same time). At every step boundary (the stage
3 checkpoints of the main loop and of the title loop) it knows:

- **the state**: stage 3 memory decoded into the stage 4 state by a decoder
  written once per game; scratch memory is left out;
- **the input**: the reads stage 3 made in the step, decoded into Actions
  the way the stage 3 routine that made them reads them; input is matched
  per step, never per frame or per `IN`;
- **the sounds**: the speaker edges in the step, named by the stage 3
  routine that made them (repeats collapsed when compared);
- **the interrupts** the Z80 took in the step (in the record): a timing
  effect the logic cannot know, given to it as an action.

| # | Check | Catches |
| --- | --- | --- |
| 1 | every call of a stage 3 routine: the stage 4 routine on the decoded state before must give the state after, the same Goto, the same sounds (`bridge/oracle.py routine`, all routines in one replay) | a slice's errors, before the slices are put together |
| 2 | the game step by step: state and sounds, every sound synthesised (`make game-test`) | any difference in the rules or the flow; a sound the synthesiser cannot take |
| 3 | the screen: `render(state)` through `zxpyxel.display` against stage 3's screen, byte for byte, every 50th step | drawing errors, lost traces of the original's incremental drawing |
| 4 | the clock: the Shows' seconds against the Z80's at the last pass | a wrong pacer |
| 5 | coverage: every stage 4 routine runs in some record | a slice that passes only because nothing reached it |
| 6 | free play: random keys through the pacer as a host runs it, invariants after every step (positions on the screen, counters in range, no run of steps without time) | errors outside the recorded runs, a pacer that hangs |

The editable assets are checked by the same runs: the game loads them, and
the checks must still pass (the round trip).

Deviation register (`re/deviations.md`): each quirk the faithful mode keeps
and a fixed mode may drop (`OR C` for `OR E` in TickGuardTimers, the delay
underflow at paces 1-3, the guard that picks up another guard's items, the
bell scored at a distance), with the finding it comes from. Faithful mode
must pass the oracle; a fixed mode records its own golden runs, which
become the reference for stage 5. The stack leak of the demo abort has no
equivalent and is not a deviation.

## How the work is split

1. **Harness** (lead): the state (from the data article and
   `variables.asm`), the decoder, the asset extraction, the oracle, the leaf
   helpers (checked against the stage 3 library routines with check 1),
   the sound effects.
2. **Slices**, one subagent per stage 3 module, in parallel, against a
   contract: which stage 4 routine stands for which stage 3 routine, the
   signatures, which are generators, which return a flow target, the sound
   events and their data. Each passes check 1 on every record.
3. **Integration** (lead): the flow (`Game.step`), checks 2 to 6: the
   stage's gate. Then the deviations, each behind its flag.
4. **Hosts**: Pyxel (`game/play.py`, `make game-html`); another framework is
   another host over the same display, sounds and controls.

## Hungry Horace

Where the effort went: not into the API but into the model. The game's
logic reads the screen: collisions are attribute colours (walls, flowers,
the bell, guards), and each guard carries the four cells under it, which is
how fruit appears and how a guard can pick up another guard's items. So the
state holds the 32×24 grid of what each cell shows, with Horace and the
guards moving over it and saving what they cover; the quirks that come from
drawing order (who is drawn last owns the cell's colour) follow from it. The
rest (score, timers, pace, the demo's autopilot) maps directly from stage 3.

Built (`examples/hungry-horace/`): `game/horace/` (state, world, movement,
sprites, events, flow, render, sounds, controls, pacer; about 900 lines),
`game/play.py`, `game/assets/` (PNG sheets for the tiles, Horace, the
guards, the bell, the fruit and the title letters; `mazes.txt`;
`texts.json`; `state.json`), `bridge/` (decoder, assets, oracle, the
routine registry). The lead wrote the state, the world helpers, the flow,
the presentation and the bridge; three subagents (Sonnet) ported movement,
sprites and events in parallel from the `zx-clean` skill and a contract.

| Check | Result |
| --- | --- |
| routines: every call of 17 stage 3 routines on the three records | all match |
| the game step by step: state and sounds | demo 2,664 steps, play 5,544, bell 15,576: all match |
| the screen through `zxpyxel.display` | byte for byte equal to stage 3's |
| the clock | demo +0.1%, play -0.5%, bell +0.8% |
| coverage | every stage 4 routine runs in some record |
| free play, headless | 15,000 frames, the invariants hold; 300 s of play in 19 s |
| the assets as edited files | the checks pass with the game loading them |

Found on the way, now checks or rules: the oracle first collapsed repeated
sounds across a whole step, which hid a second chirp in the same step from
the routine check (two subagents diagnosed it independently); the contract
had left the data of the sound effects open, so the noise and the chime came
out in a shape the synthesiser did not take (every sound is now synthesised
in the game check, and the sound data is part of the contract); a step may
take no time (the original goes from the exit arrows into the next maze's
first pass without a frame), so free play checks for runs of such steps; the
demo's autopilot made demo passes 6% slower than the flat pass time, now
charged.

## Next steps

1. Deviations: the fixed mode behind flags, with `re/deviations.md` and its
   own golden runs.
2. Stage 5: the golden files written by the oracle (one JSON object per
   step: actions, state, sounds, the screen's hash and changed cells; build
   files, since they hold game data), and the logic in C/C++ (SDL2 or a
   platform library) or JS, with the display, sound and controls
   reimplemented per platform.
3. A second game through stage 4, to see which parts of the bridge are
   generic enough to move into `tools/`.
