# Stage 3: a Python port on a Spectrum stand-in library

Status: the library's core and its Pyxel host exist (`zxpyxel/`), and a spike
ported Hungry Horace's title and first maze (`examples/hungry-horace/port/`;
results under "Spike"). The rest is design; the next steps are at the end.

Stage 3 turns the annotated asm into Python that runs the same game: the same
screens, the same behaviour under the same input, and code that follows the
asm routine by routine. It runs on `zxpyxel`, the library that stands in
for the 48K hardware the game touches, with Pyxel underneath for the window,
keys and sound. It is the first stage that runs off the Spectrum and the base
for stages 4 and 5 (README, "Port everywhere"). The same library serves new
games in the Spectrum style (hyperdream): their drawing calls write the same
screen memory that a port writes.

## Framework: Pyxel

| | Pyxel 2.9 | pygame-ce | PySDL2 |
| --- | --- | --- | --- |
| Web | `pyxel app2html`: one HTML file, Pyodide/WASM | pygbag; the main loop must be asyncio | no |
| Ship | `.pyxapp` or HTML, one command each | PyInstaller, pygbag | PyInstaller |
| Frame loop | `pyxel.run(update, draw)`; `flip()` is not available on the web | own loop | own loop |
| Screen | 16-colour palette, indexed image, `data_ptr()` for a raw copy | surfaces, `surfarray` | textures |
| Sound | 4-channel synth; PCM only from a WAV/OGG file (`Sound.pcm`) | raw PCM buffers, queued | `SDL_QueueAudio` |
| Prototype | `zxpyxel` in hyperdream | none | none |

Pyxel. The Spectrum's 16 colours (15 distinct) are its palette, the screen
fits its 256×256 image bank, 50 fps is a setting, and a desktop build or a
single HTML page is one command each: that is what "clone, tweak, play, ship"
needs. Its weak point is sound: there is no raw-buffer API, so beeper audio
goes through a WAV file per chunk (see Sound). If that is not good enough,
pygame-ce replaces only the host module (the host contract below); the game
code and the core do not change.

## Principles

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

## The library

```
zxpyxel/
  machine.py     the Spectrum: memory, the ROM (48.rom), clock, ports, interrupts, frame sync, checkpoints
  screen.py      screen memory → 256×192 palette indices; palettes; FLASH
  draw.py        pset, lines, rectangles, polygons, blit, attribute writes, clipping
  text.py        text in the ROM font or a loaded codepage
  sprite.py      sprites from bytes (UDG); a PNG becomes bytes at build time
  sound.py       speaker edges → PCM (WAV bytes)
  rom.py         ROM routines games call (BEEPER, …) by ROM label
  keys.py        key matrix: ZX key names ↔ half-row and bit; host key maps
  pyxel_host.py  window, palette, blit, keys, audio; run(main)
  headless.py    no window: scripted or replayed input, frame dumps, checkpoint log
```

A port uses the machine and writes screen memory the way the original does.
A new game uses the same machine and draws with `draw`, `text` and `sprite`,
which write the same display-file bytes and attributes; it is an `async`
main that awaits `zx.halt()` once per frame. Everything below the host module
is shared, so a new game can mix in routines ported from an old one.

### Machine

```python
from zxpyxel import zx, mem      # one machine, like the hardware it stands for

mem[0x5C78]                      # memory is a bytearray; the 48K ROM at $0000-$3FFF
zx.peek16(a); zx.poke16(a, v)
zx.out(port, v)                  # $FE: border bits 0-2, speaker bit 4 (MIC ignored)
zx.inp(port)                     # $xxFE: half-rows selected by the high byte, bits 0-4, 0 = pressed
                                 # $1F: Kempston
zx.r()                           # LD A,R: from the clock when playing, recorded values in a replay
zx.spend(t)                      # charge T-states
await zx.sync()                  # hand the host every frame the clock has passed
await zx.halt()                  # clock to the next frame boundary, then sync
zx.di(); zx.ei(); zx.im2(fn)     # interrupts; the IM1 default only counts FRAMES
zx.checkpoint('MainLoop')        # test hook: hash game-state memory; nothing when playing
```

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
per-routine or per-pass figures measured in the simulator. A HALT-locked game
needs hardly any: they only matter for frames where its work overruns.

The ROM area holds the 48K ROM, for games that read the font or use ROM bytes
as random numbers; it is also the font of `text`. The library ships it (taken
from SkoolKit's `resources/48.rom`; Amstrad allows distributing it with
emulators). A write there is a bug in the port: the headless host checks at
every frame that the ROM is intact.

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

A host is one module that:

1. sets `zx.keys`, then calls `game.send(None)`, 50 times a second;
2. shows `screen.render(mem, flash)` inside the border colour;
3. plays the PCM from `zx.take_audio()`;
4. stops when the game coroutine returns.

## Port code

One Python module per asm module (`src/movement.asm` → `port/movement.py`),
one function per routine, named as the label.

- Registers become arguments and return values; a flag the caller branches on
  becomes a returned bool; alternate registers become extra arguments.
- Variables stay in memory: `mem[Lives]`, `zx.peek16(PlayerPos)`. A
  self-modified operand is memory at `Label+1`, written where the asm writes
  it.
- A jump that drops a return address (`POP HL` then `JP NextMaze`) becomes an
  exception caught at the entry point it jumps to.
- The `Hardware:` sentence of a routine says which `zx` calls its port needs.
- A loop the asm repeats inline (a print loop, the step to the next cell)
  becomes one lower-case helper, so it does not read as a routine of the
  original.
- `from labels import *` comes first in a module: port functions have the
  labels' names and must shadow the numbers.

```python
async def Pause():                       # illustrative: a DJNZ delay loop
    zx.spend(mem[PauseLength] * 256 * 13)
    await zx.sync()
```

Layout in a game project:

```
port/
  zxpyxel/      the library, copied from zx-reaper by zxinit.py, like tools/
  labels.py     tools/zxport.py labels > port/labels.py
  image.bin     tools/zxport.py image re/orig.z80 port/image.bin: the 48K RAM
                at handover (game data, never committed)
  *.py          one per src/*.asm module (main.asm → main.py)
  play.py       loads image.bin, runs Start on the Pyxel host
```

Everything the game needs is in `port/`, so `pyxel package port port/play.py`
and `pyxel app2html` make the desktop and web builds from it as it is.

## Tests: identical behaviour

1. **Routines.** `zxdiff.py` as in the `zx-port` skill: the port function
   runs on a machine whose memory holds the case's memory, and the same
   registers and memory are compared. Needs: zxdiff accepting a port that
   takes the machine.
2. **The whole game, by checkpoint replay.** The Z80 run records every value
   an IN instruction reads, with its port address, in order (and the values
   `LD A,R` reads), and at every pass through a checkpoint address a hash of
   the game-state memory: screen, attributes and the variable ranges, not
   the stack. The port runs headless with those values replayed in the same
   order and hashes the same ranges at `zx.checkpoint`. The two hash
   sequences must be equal; the first difference is reported by label, and a
   read the port does differently is caught at the read. Input is matched by
   read order, not by frame, so the port's timing does not have to match the
   Z80's. Needs: `zxrun.py --record-in FILE` and `--checkpoint ADDR`.
   Limit: an interrupt handler that changes variables in mid-pass runs at a
   different point in the port; in such games, put the checkpoints at HALTs,
   where both are in step.
3. **By eye.** The Pyxel host next to Fuse. Speed and sound are judged here,
   not tested.

## Stages 4 and 5

Stage 4 takes the Spectrum out of the code one subsystem at a time:
variables move from `mem` into Python objects, screen writes become draw
calls on a framebuffer or sprites, beeper loops become sound events, keys
become actions. While the screen and the variables still exist in some form,
the checkpoint test runs through an adapter that writes the old memory
ranges; after that, the stage 4 code records its own golden runs. The game
can then move to whatever framework the user prefers.

Stage 5 ports the plain game logic to C/C++ (SDL2 or a platform library) or
JS. `async` routines become JS `async`/`await`, and in C a state machine or a
game thread that blocks on a frame semaphore. The host contract is what each
platform reimplements.

Going back: stage 3 keeps the memory layout and the labels, so a change made
in Python goes back to asm (or z88dk C) routine by routine, with `zxdiff` run
the other way: the Python routine is the oracle.

## From the prototypes

**zxpyxel** (`hyperdream/src/zxpyxel`) becomes this library. Its master copy
moves to zx-reaper (`zxpyxel/`); hyperdream depends on it and drops its copy.
What changes:

- `Display` kept the screen in numpy arrays (a bool bitmap and an attribute
  grid). Now there is one screen, the display file in memory, and the drawing
  primitives write its bytes (a horizontal span is a few masked bytes, not a
  pixel loop). numpy and Pillow leave the library; `load_sprite` (PNG) moves
  to build time, and hyperdream's game code does not use it.
- `ZxApp` with `update`/`draw` callbacks becomes `run(main)` with an `async`
  main. A callback-style game is `while True: update(); draw(); await zx.halt()`.
- The embedded 768-byte font becomes the ROM's font at $3D00; glyphs 128-255
  for a codepage stay a feature of `text`.
- Kept: the palettes, the FLASH phase, the Pyxel recipe (palette override,
  blit through `images[0].data_ptr()`, border through `cls`), headless tests,
  and the drawing and text API, so hyperdream's code changes little.

**mokit** (`mokit/zx/screen.py`): the display-file line formula and the
attribute bit layout. Not a dependency: it brings numpy, Pillow and a git
install, while the library must run in Pyodide and be copied into a project
as it is.

## Spike: Hungry Horace (2026-10-23)

Ported: `Start` up to `InitMaze` (the title with its colour cycle, rising
tone and any-key check; the start of a game or demo; maze 1 with the status
line or the demo banner), in `examples/hungry-horace/port/`, about 200
lines.

| Check | Result |
| --- | --- |
| memory when `InitMaze` is reached, demo, against the Z80 run (`port/check_spike.py`) | screen and attributes identical; every game variable identical; only $5F93-$5F9C differ, the Z80 stack |
| timing | the port reaches `InitMaze` at frame 584, the Z80 at 614: only the beeper loops are charged so far |
| desktop, Pyxel 2.9.4 | 50.1 fps; 96 beeper chunks in 400 frames through `Sound.pcm` without errors |
| web, `pyxel app2html` (Pyodide 0.29.3, Chrome) | 48.5-48.8 fps; the WAV chunks play without errors; `ctypes.memmove` into `data_ptr()` works; a key on the title starts a game |
| size | the web build is one 43 KB HTML file plus Pyxel's runtime from its CDN |

Not checked: how the beeper sounds (needs ears), the seams between WAV chunks,
and why the web build runs 3% slow (frame pacing under a 60 Hz display is the
likely cause).

## Next steps

1. `zxrun.py --record-in` and `--checkpoint`, the headless replay, and the
   Horace port, main loop included, passing it for `tests/inputs/*.txt`.
2. `zxinit.py` copying the library; a Makefile target for `zxport.py labels`
   and `image`; a stage 3 part in the `zx-port` skill; the selftest fixture
   game ported in `selftest/`.
3. The drawing, text and sprite layer over memory, with the prototype's
   tests; hyperdream switches to it.
