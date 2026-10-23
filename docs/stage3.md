# Stage 3: a Python port on a Spectrum stand-in library

Status: built. The library's core and its Pyxel host exist (`zxpyxel/`), and
Hungry Horace is ported whole and passes the stage's check
(`examples/hungry-horace/port/`; results under "Hungry Horace"). How to
port: the `zx-port` skill; this note keeps the reasons.

Stage 3 turns the annotated asm into Python that runs the same game: the same
screens, the same behaviour under the same input, and code that follows the
asm routine by routine. It runs on `zxpyxel`, the library that stands in
for the 48K hardware the game touches, with Pyxel underneath for the window,
keys and sound. It is the first stage that runs off the Spectrum, and the
oracle of stage 4 ([stage4.md](stage4.md)).

## Decisions

### Pyxel

| | Pyxel 2.9 | pygame-ce | PySDL2 |
| --- | --- | --- | --- |
| Web | `pyxel app2html`: one HTML file, Pyodide/WASM | pygbag; the main loop must be asyncio | no |
| Ship | `.pyxapp` or HTML, one command each | PyInstaller, pygbag | PyInstaller |
| Frame loop | `pyxel.run(update, draw)`; `flip()` is not available on the web | own loop | own loop |
| Screen | 16-colour palette, indexed image, `data_ptr()` for a raw copy | surfaces, `surfarray` | textures |
| Sound | 4-channel synth; PCM only from a WAV/OGG file (`Sound.pcm`) | raw PCM buffers, queued | `SDL_QueueAudio` |
| Prototype | an earlier `zxpyxel` | none | none |

Pyxel. The Spectrum's 16 colours (15 distinct) are its palette, the screen
fits its 256×256 image bank, 50 fps is a setting, and a desktop build or a
single HTML page is one command each: that is what "fork, play, ship"
needs. Its weak point is sound: there is no raw-buffer API, so beeper audio
goes through a WAV file per chunk (see Sound). If that is not good enough,
pygame-ce replaces only the host module (the host contract below); the game
code and the core do not change.

### Principles

1. **The asm's shape survives.** Memory is a 64K `bytearray` at the original
   addresses. Code, data and the screen stay where the asm puts them; data
   tables come from the built image, not retyped into Python. Routine names
   are the asm labels; labels and constants come from the build (`labels.py`,
   generated from `build/game.sym`, which holds the constants too).
2. **The core is standard-library Python.** Rendering a frame from screen
   memory with a (attribute, byte) lookup table takes 0.5 ms in CPython
   (measured: 192 rows × 32 lookups, Apple Silicon), so the core needs no
   numpy, runs unchanged in Pyodide, and reads line by line as C or JS. Only
   the host module imports Pyxel.
3. **Time is a T-state clock the port charges itself.** No CPU is emulated,
   so the port says what costs time: `zx.spend(t)`. Frames (69,888 T-states)
   follow from the clock. Frame-locked games (HALT) and free-running ones
   (Hungry Horace: interrupts off, speed = instruction time plus a delay loop)
   work the same way.
4. **Waiting is `await`.** A routine that halts, waits or plays a blocking
   sound is `async def`, and its callers `await` it. The host drives the game
   coroutine by hand, one frame per `send(None)`, without asyncio. The same
   code runs under `pyxel.run` callbacks, on the web, headless at full speed
   in tests, and maps to JS `async`/`await` later. A forgotten `await` is a
   `RuntimeWarning` ("never awaited") that tests turn into an error; an
   `await` in a plain function is a syntax error.
5. **Loose hardware.** One border colour per frame, no contention, no
   floating bus, no raster timing. A game that relies on more (border
   stripes, multicolour) gets the effect redrawn on the host, not emulated.

### From the prototype

`zxpyxel` began as a prototype written for a new game in the Spectrum style;
its master copy is now here (`zxpyxel/`). What changed on the way:

- The prototype kept the screen in numpy arrays (a bool bitmap and an
  attribute grid). Now there is one screen, the display file in the
  Spectrum's layout, and drawing writes its bytes; numpy and Pillow leave
  the library, which must run in Pyodide and be copied into a project as it
  is. PNG goes through the library's own standard-library codec.
- Update/draw callbacks become `run(main)` with an `async` main for ports,
  and `run_display(update, display)` for games that are not ports.
- An embedded 768-byte font becomes the ROM's font at $3D00.
- Kept: the palettes, the FLASH phase, the Pyxel recipe (palette override,
  blit through `images[0].data_ptr()`, border through `cls`), headless tests.

## The library

```
zxpyxel/
  machine.py     the Spectrum: the ROM (48.rom), clock, ports, interrupts, frame sync, checkpoints, Goto
  memory.py      mem, mem16 and typed variables over the same 64K, wrapping like the Z80
  screen.py      screen bytes → 256×192 palette indices; palettes; FLASH
  display.py     the screen without addresses (stage 4, new games): cells, sprites, ROM-font text, border
  png.py         PNG in and out (standard library); Spectrum graphics as checked 8x8 cells
  sound.py       speaker edges → PCM (WAV bytes)
  rom.py         ROM routines games call (BEEPER, …) by ROM label
  keys.py        key matrix: ZX key names ↔ half-row and bit
  pyxel_host.py  window, palette, blit, keys, audio; run(main) for ports, run_display(update, display)
  headless.py    no window: scripted keys, or a Z80 record replayed and checked at checkpoints
```

A port uses the machine and writes screen memory the way the original does.
A game that is not a port (stage 4, a new game in the Spectrum style) draws
on `zxpyxel.display`, which writes the same display-file bytes and
attributes without addresses, and runs under `run_display`. Not built yet:
drawing primitives over the display (lines, rectangles, polygons, clipping)
for new games.

### Machine

```python
from zxpyxel import zx, mem, mem16   # one machine, like the hardware it stands for
from variables import v              # the game's data labels, generated from the asm

mem[a]; mem16[a]                 # a byte, a little-endian word; the 48K ROM at $0000-$3FFF
v.Score; v.GuardTimers[i]        # a DEFB/DEFW/table at its address, with its width
zx.out(port, v)                  # $FE: border bits 0-2, speaker bit 4 (MIC ignored)
zx.inp(port)                     # $xxFE: half-rows selected by the high byte, bits 0-4, 0 = pressed
                                 # $1F: Kempston
zx.spend(t)                      # charge T-states
zx.r()                           # LD A,R: from the clock; in a replay the value the Z80 read
zx.take(addr, a)                 # a value the port cannot be sure of: a; in a replay the Z80's A at addr
await zx.sync()                  # hand the host every frame the clock has passed
await zx.halt()                  # clock to the next frame boundary, then sync
zx.di(); zx.ei(); zx.im2(fn)     # interrupts; the IM1 default only counts FRAMES
zx.checkpoint('MainLoop')        # test hook: compared with the Z80 in a replay; nothing when playing
raise Goto(NextMaze)             # a jump that drops return addresses; dispatch(entry) goes on there
```

All three views of memory are the same 64K and wrap like the Z80 on a
store, so a byte is never written as a word by mistake and the port needs no
`& 0xFF` on memory. `zx.r()` stands for `LD A,R`: a port has no instruction
fetches to count, so it takes the clock, and a replay gives the value the Z80
read (The Hobbit seeds its random numbers this way).

`sync` gives the host one frame for each frame boundary the clock has
crossed: fifty for a one-second blocking sound, none when a main-loop pass is
shorter than a frame. After each frame it runs the interrupt handler if
interrupts are on (the frame is shown first, then the handler runs, as the
interrupt starts the next frame on the hardware). Call it at every HALT
(`halt` does), at the end of every delay loop and blocking sound, and once
per main-loop pass. The host shows only the states at sync points, so the
screens it shows are as coarse as the sync points are.

How much to `spend`: exact counts for delay and sound loops (the asm gives
them: Hungry Horace's `Delay` is 26 T-states per pass); for other code,
per-routine figures measured in the simulator (`zxdiff.py --tstates`). A
HALT-locked game needs hardly any: they only matter for frames where its
work overruns.

The ROM area holds the 48K ROM, for games that read the font or use ROM bytes
as random numbers; it is also the font of `display.text`. The library ships
it (taken from SkoolKit's `resources/48.rom`; Amstrad allows distributing it
with emulators). A write there is a bug in the port: the headless host
checks at every frame that the ROM is intact.

### Screen

Rendered from memory at each host frame: the bitmap at $4000-$57FF in
display-file line order, the attributes at $5800-$5AFF, BRIGHT as colour
indices 8-15, FLASH swapping ink and paper every 16 frames. The output is
49,152 palette indices, one byte per pixel, which the host copies into its
image (Pyxel: `ctypes.memmove` into `images[0].data_ptr()`). The border is the
last colour written to $FE in that frame. Palettes from zxpyxel: PULSAR
(default), ALONE, ORTHODOX. Window 320×256 (32-pixel border), scale 3.

### Sound

`out($FE)` records each change of the speaker bit at the clock time. A beeper
loop in the port keeps its structure: it writes the port and spends the
loop's T-states per half-period, or calls `zx.tone(half_period_t, cycles)`,
which records the same edges in one call. ROM BEEPER is
`rom.BEEPER(de, hl)`: 437500 / (HL + 30.125) Hz for DE cycles.

At each host frame the host takes the edges from the last played time up to
the clock, as PCM. A blocking sound is generated before its first frame is
shown, so it plays as one piece. Pyxel host: the chunk is written as a WAV to
the temporary (on the web, Pyodide's in-memory) file system and played with
`Sound.pcm` on one channel. Ceiling: a tone that keeps sounding across frames
while the game runs (beeper music during play) gets a seam at every frame;
the fix is the pygame-ce host with queued buffers.

AY (128K) is out of scope. When it comes, `out($FFFD/$BFFD)` feeds the
registers to pyayay (Ayumi) on the desktop; the web needs a Pyodide build of
it or a pure-Python Ayumi.

### Keys

`zx.keys` is the set of ZX keys held in this frame, set by the host before
each frame. `inp($xxFE)` combines the selected half-rows as the ULA does.
Host keys: letters, digits, space and Enter as themselves, Shift as CAPS
SHIFT, Ctrl and Alt as SYMBOL SHIFT. Arrows and gamepad map, per game, to the
keys the game reads (a `keymap` for the host in the port's `play.py`) or to
Kempston.

### Host contract

A host is one module that, 50 times a second:

1. gives the game the ZX keys held: for a port it sets `zx.keys` and calls
   `game.send(None)`; for a display game it calls `update(keys)`;
2. shows the screen bytes (`screen.render(mem, flash)` for a port,
   `screen.render(display.data, flash, base=0)` for a display) inside the
   border colour;
3. plays the PCM (`zx.take_audio()`, or what `update` returned);
4. stops when the game ends.

## Port code

One Python module per asm module (`src/movement.asm` → `port/movement.py`),
one function per routine, named as the label.

- Registers become arguments and return values; a flag the caller branches on
  becomes a returned bool; alternate registers become extra arguments.
- Variables stay in memory: `v.Lives`, `v.PlayerPos`, at the addresses
  and widths of the asm. A self-modified operand is `mem[Label + 1]`,
  written where the asm writes it.
- Fall-through into the next label is a call; a jump that drops a return
  address (`POP HL` then `JP NextMaze`) is `raise Goto(NextMaze)`, and
  `dispatch` in the entry routine goes on there, so the Python stack does not
  grow with every maze.
- The `Hardware:` sentence of a routine says which `zx` calls its port needs.
- A loop the asm repeats inline (a print loop, the step to the next cell)
  becomes one lower-case helper, so it does not read as a routine of the
  original.
- `from labels import *` comes first in a module: port functions have the
  labels' names and must shadow the numbers.

```python
async def Pause():                       # illustrative: a DJNZ delay loop
    zx.spend(v.PauseLength * 256 * 13)
    await zx.sync()
```

Layout in a game project:

```
port/
  zxpyxel/      the library, copied from zx-reaper by zxinit.py, like tools/
  labels.py     labels and constants (make port/labels.py)
  variables.py  the data labels as typed fields of `v` (make port/variables.py)
  image.bin     the 48K RAM at handover (make port/image.bin; game data, never committed)
  *.py          one per src/*.asm module (main.asm → main.py)
  play.py       loads image.bin, runs Start on the Pyxel host
```

Everything the game needs is in `port/`, so `make port-html` (Pyxel's
`package` and `app2html`) makes a web page from it as it is.

## Checks

How to run them: the `zx-port` skill. Why they look like this:

1. **Routines.** `zxdiff.py` with a `port(regs)` function: the port runs on
   `zx.mem` loaded with the case's memory, and registers and memory are
   compared with the Z80. It also prints the routine's T-states, which is
   where the port's `zx.spend` figures come from.
2. **The whole game, by checkpoint replay** (`make port-test`). The Z80 run
   (`zxrun.py --record`) writes every value an IN by the game reads, with
   its port address, in order (a run of the same read as one line with a
   count: polling loops read millions of times), every value an `LD A,R`
   read (a second run that stops at each `LD A,R`, merged by the order of
   reads), the interrupts the ROM's handler takes, and
   at every pass through one checkpoint address the clock and the game
   state: the screen, the code region and any system variable the game
   uses, not the stack. The state is stored, not hashed (the first pass in
   full, then the changes), so a mismatch names the bytes, by label or
   screen cell. The port runs headless with the reads replayed and compares
   at `zx.checkpoint`; a read on another port, or a read where the Z80 was
   at the checkpoint, stops it at once. Input is matched by read order, not
   by frame, so the port's timing does not have to match; the drift of its
   clock is reported instead. The check also lists the port's routines no
   record ran. Records are build files (`build/record/`): they hold game
   data. Limit: an interrupt handler that changes variables in mid-pass runs
   at a different point in the port; in such games, put the checkpoint at a
   HALT, where both are in step.
3. **By eye and ear.** The Pyxel host next to Fuse. Speed and sound are
   judged here, not tested.

## Hungry Horace

### The spike (title to the first maze)

Ported first: `Start` up to `InitMaze` (the title with its colour cycle,
rising tone and any-key check; the start of a game or demo; maze 1 with the
status line or the demo banner), about 200 lines, to try the platform.

| Check | Result |
| --- | --- |
| memory when `InitMaze` is reached, demo, against the Z80 run | screen and attributes identical; every game variable identical; only $5F93-$5F9C differ, the Z80 stack |
| desktop, Pyxel 2.9.4 | 50.1 fps; 96 beeper chunks in 400 frames through `Sound.pcm` without errors |
| web, `pyxel app2html` (Pyodide 0.29.3, Chrome) | 48.5-48.8 fps; the WAV chunks play without errors; `ctypes.memmove` into `data_ptr()` works; a key on the title starts a game |
| size | the web build is one HTML file of tens of KB plus Pyxel's runtime from its CDN |

### The whole game

About 1,100 lines of Python (six modules, one per asm module), ported by the
method of the `zx-port` skill: the lead wrote the tools and `main.py`
(control flow), subagents on a cheaper model ported the modules, the leaf
modules first (library, guards), then movement, sprites and events in
parallel against a fixed contract (signatures, which routines are async, the
Goto targets).

| Check | Result |
| --- | --- |
| routines, `make diff` | 38 routines against the Z80, 0 mismatches (the async ones are left to the replay) |
| whole game, `make port-test` | every main-loop pass identical to the Z80 in all game memory: demo 2,384 passes, play 5,536, bell 15,567 (11,000 frames of random play that take the bell, eat a guard and leave by the arrows) |
| clock | the port runs 1.3-2.0% fast against the Z80 |
| speed, headless | about 14,000 frames a second |
| by ear | the beeper through WAV chunks sounds right on the whole game; the seams between chunks do not show |

The first replay of the integrated port matched 2,147 passes and stopped at
FRAMES: the ROM's BEEPER returns with interrupts on, the game's DI comes one
instruction later, and once in a few thousand chimes the Z80 takes an
interrupt in between, whose handler counts FRAMES, which the guards' AI
reads as a random source. The record now logs the interrupts the ROM handler
takes, and the replay runs the port's handler at the same place in the order
of events. No port code was fixed: every other difference would have been a
porting error, and there were none.

What the subagents found hard, now in the skill or the tools: inputs read
from the instructions rather than the header (an `E'` in a header can mean
E after the caller's EXX), flags and unused registers in the test cases,
how to split T-states between a routine and its callees (`zxdiff.py
--tstates`), whole-screen mismatches flooding the output (only the differing
bytes are printed now), and a word written as a byte (`mem16` and `v`).

## Next steps

1. The selftest fixture game ported in `selftest/`, so `selftest/run.sh`
   checks stage 3 end to end.
2. Drawing primitives over `zxpyxel.display` (lines, rectangles, polygons,
   clipping) with the prototype's tests, for new games in the Spectrum style.
3. Why the web build runs 3% slow (frame pacing under a 60 Hz display is the
   likely cause).
