# 8. Porting notes

This section lists what a C or Python port has to provide when it runs on a
platform library that imitates the Spectrum (a 256x192 bitmap with 8x8
attribute cells, a keyboard matrix, a beeper). The game touches little
hardware: the display file, port $FE, the ROM and one system variable. The
harder parts are that positions are display-file offsets, that the attribute
area is the collision map, and that the speed comes from instruction timing.

## Hardware touch points

Every routine whose source header has a `Hardware:` sentence, summarised.
"Screen" means the bitmap $4000-$57FF, "attrs" the attribute area
$5800-$5AFF.

| Routine | Hardware touched |
| --- | --- |
| [Start](../src/main.asm#L52) | `DI`; reads ROM bytes (random seed) and FRAMES; title: clears and writes screen and attrs, reads all keyboard rows (port $00FE), beeper via [PlayRisingTone](../src/guards.asm#L94) |
| [ReadControls](../src/movement.asm#L52) | reads port $FE: half-rows $FB (Q-T), $F7 (1-5), $FE (CAPS SHIFT-V), $DF (P-Y); in the demo all rows ($00) |
| [PlanMoves](../src/movement.asm#L237) | wrap tone: writes port $FE (speaker, border white) in busy-wait loops, about 0.07 s |
| [ChooseGuardMove](../src/movement.asm#L389) | reads ROM $0000-$0FFF, reads and writes FRAMES ($5C78); no port, no screen |
| [EraseSprites](../src/sprites.asm#L13) | writes screen and attrs |
| [EraseGuard](../src/sprites.asm#L66) | writes screen and attrs (four cells); reads them through [SaveBackground](../src/library.asm#L444) |
| [EatObject](../src/sprites.asm#L133) | reads attrs; falls into [ShowScore](../src/sprites.asm#L169) |
| [ShowScore](../src/sprites.asm#L169) | writes screen and attrs of row 0; beeper chirp through port $FE, about 8 ms |
| [DrawGuards](../src/sprites.asm#L235), [DrawGuard](../src/sprites.asm#L273) | write screen and attrs (through [DrawSprite](../src/library.asm#L247)) |
| [CheckGuardContact](../src/events.asm#L27) | reads attrs; writes screen; beeper buzz through port $FE, about 0.25 s |
| [HoraceDies](../src/events.asm#L175) | writes screen and attrs; beeper noise through port $FE; random ROM bytes |
| [GameOver](../src/events.asm#L299) | writes attrs; beeper through [PlayRisingTone](../src/guards.asm#L94) |
| [DrawHorace](../src/events.asm#L342) | writes screen and attrs (through [DrawSprite](../src/library.asm#L247)) |
| [UpdateBell](../src/events.asm#L419) | writes screen and attrs; chirp through [ShowScore](../src/sprites.asm#L169) |
| [UpdateFruitDrops](../src/events.asm#L512), [MaybeDropFruit](../src/events.asm#L558), [TickGuardTimers](../src/events.asm#L621) | none |
| [CheckSoundKey](../src/events.asm#L658) | reads port $FBFE (T is bit 4) |
| [PaceAndChime](../src/events.asm#L693) | busy-wait delay ([Delay](../src/library.asm#L10)); calls ROM BEEPER at $03B5, which re-enables interrupts (`DI` follows) |
| [PlayRisingTone](../src/guards.asm#L94) | writes port $FE (speaker on/off, border white) in busy-wait loops, about 0.08 s |
| [Delay](../src/library.asm#L10) | timing loop only, 26 T-states per pass |
| [GetRandom](../src/library.asm#L28) | reads ROM $0000-$1FFF |
| [PrintNumber](../src/library.asm#L54), [PrintChar](../src/library.asm#L105) | read the ROM font at $3D00; write screen and attrs |
| [DrawMaze](../src/library.asm#L155) | writes attrs, then screen; uses the alternate register set for the attribute pointer |
| [DrawSprite](../src/library.asm#L247) | writes screen and four attrs |
| [DrawCell](../src/library.asm#L292) | writes screen and one attr |
| [SetAttrPointer](../src/library.asm#L329) | computes an attribute address into HL'; writes nothing |
| [GetBlockObject](../src/library.asm#L359), [MergeObjectAttr](../src/library.asm#L396) | read attrs |
| [SaveBackground](../src/library.asm#L444), [SaveBackgroundCell](../src/library.asm#L492) | read screen and attrs |
| [ProbeMove](../src/library.asm#L556), [ProbeCell](../src/library.asm#L606) | read attrs |
| [StepCell](../src/library.asm#L643) | none: display-file address arithmetic |
| [DrawBlocks](../src/library.asm#L706) | writes the screen bitmap only |

Routines without a `Hardware:` sentence touch only game memory:
[ResetGuardTimers](../src/guards.asm#L15), [LoadGuardRecord](../src/guards.asm#L41), [SaveGuardRecord](../src/guards.asm#L74),
[LoadMazeDescriptor](../src/guards.asm#L133), [PrintDigit](../src/library.asm#L87) (before it falls into [PrintChar](../src/library.asm#L105))
and [ExitMaze](../src/events.asm#L765).

Port $FE output values used: `$1F AND SoundMask`, which is $1F with the sound
on (border 7, MIC bit 3 and speaker bit 4 set) and $07 with it off, and
`$07` (speaker and MIC off, border 7). The border is
white throughout the game; the loader sets it to blue during loading and
white before the call.

## Timing and pacing

The game has no frame lock. A pass of the main loop takes as long as its
code, plus [Delay](../src/library.asm#L10) at the end, and the movement step happens every
[GuardInterval](../src/variables.asm#L34) passes. To keep the original speed a port must either
count Z80 T-states (3.5 MHz) for the code it emulates, or run the main loop
at a fixed rate close to the original:

- measured at pace 8 in maze 1 with one guard: 1.3 passes per 50 Hz frame
  (263 passes in 200 frames); the pass time grows with each guard on the
  screen. The measurement uses `tools/zxrun.py`, which runs SkoolKit's plain
  simulator, not its contention-aware one, so memory contention is not
  included;
- the delay at the end of a pass: `($015E + $1E·n) × 26` T-states, n = pace
  (15,340 at n = 8, 9,880 at n = 1);
- blocking sounds: chirp 8 ms per score change, wrap tone 0.07 s, eaten buzz
  0.25 s, death about 1 s, game over 20 × 0.08 s, title loop 0.08 s per pass;
- every count in the game (step interval, release timers, bell timer, fruit
  timer, wrap pause, wait after being eaten) is in passes, not in frames or
  seconds.

The title screen waits 140 passes of [PlayRisingTone](../src/guards.asm#L94) (606 frames from the
start to the demo in the simulator).

The [GuardsReleased](../src/texts.asm#L55) term of the delay can go negative at paces 1-3 and
stall the game ([Tricks and bugs](06-tricks.md#tickguardtimers-counts-the-wrong-thing)).
A port that reproduces the delay arithmetic exactly (16-bit wrap) reproduces
the stall; a port with a fixed pass rate does not.

## ROM routines and ROM data

| ROM address | What | Used by | Replacement |
| --- | --- | --- | --- |
| $0000-$1FFF | ROM bytes as random numbers | [GetRandom](../src/library.asm#L28), seed in [Start](../src/main.asm#L52) | a copy of the 48K ROM's first 8K, or any byte source if exact behaviour is not needed |
| $0000-$0FFF | ROM bytes as random numbers | [ChooseGuardMove](../src/movement.asm#L389) | the same ROM bytes |
| $3D00-$3FFF | character set, 96 characters of 8 bytes, $20-$7F ($7F = ©) | [PrintChar](../src/library.asm#L105) | a copy of the ROM font |
| $03B5 BEEPER | tone generator: DE = cycles, HL = pitch value | [PaceAndChime](../src/events.asm#L693) | a square-wave tone of about 1010 Hz (DE = $16, HL = $0193) and 1120 Hz (DE = $1A, HL = $0168), about 22 ms each |
| $5C78 FRAMES | system variable (RAM) | [Start](../src/main.asm#L52) reads its low byte once; [ChooseGuardMove](../src/movement.asm#L389) uses its low word as a counter | a 16-bit variable, initialised from whatever the platform has (exact demo replay needs the original value) |

The demo is deterministic given the ROM contents and the initial FRAMES
value: the autopilot, the guards and the fruit all draw from the ROM.

## Memory layout dependencies

- **Positions are display-file offsets.** [HoracePos](../src/variables.asm#L113), the guard records,
  [BellPos](../src/variables.asm#L283) and the maze descriptors store `address - $4000` of the
  top-left cell; [StepCell](../src/library.asm#L643), [DrawSprite](../src/library.asm#L247), [SaveBackground](../src/library.asm#L444) and the
  wrap deltas rely on the Spectrum layout (third, row, column bits; see
  [Data structures](02-data.md#positions-and-directions)). A port can either
  keep a Spectrum-layout display file and these offsets, or convert the four
  descriptors to (row, column) and the wrap deltas to row counts (-8, +19, 0,
  +15).
- **The attribute area is game state.** Movement, eating, contact and the
  guards' saved backgrounds read the attribute bytes. A port that draws to a
  modern frame buffer must still keep a 32x24 array of attribute values,
  written exactly when the original writes attributes and in the same order
  ([Drawing](05-drawing.md#the-attribute-map-as-collision-map)).
- **Saved backgrounds hold display bytes.** Each guard record stores 4 cells
  of attribute plus 8 bitmap bytes, and the fruit graphics are in that
  format. A port needs the 8x8 bitmap of each cell, not only a tile code,
  because a saved cell can hold part of a flower, the bell, Horace or a
  fruit.
- **Address range.** Code, data and variables occupy $5FB5-$7FFF; the stack
  is below $5FB5 (SP $5F9D in the main loop). Nothing above $7FFF is used, so
  there is no dependency on 48K-only memory or paging. All of the program
  runs from $4000-$7FFF, which is contended RAM on a real Spectrum, so real
  hardware runs it somewhat slower than an uncontended model (inferred).
- **Alternate registers.** [SetAttrPointer](../src/library.asm#L329) leaves the attribute pointer
  in HL'; [DrawCell](../src/library.asm#L292), [PrintChar](../src/library.asm#L105), [GetBlockObject](../src/library.asm#L359) and [ProbeMove](../src/library.asm#L556)
  use BC', DE', HL'. In C or Python these become an explicit attribute
  pointer passed along with the bitmap pointer.
- **Shared tables.** [GuardDirScores](../src/state.asm#L82) is used by both the AI and the demo
  autopilot, and its end is the address of [GuardRecordPtr](../src/state.asm#L94).

## Entry points and structure for a port

| Entry | Address | Role |
| --- | --- | --- |
| [Start](../src/main.asm#L52) | $6000 | program start (`PRINT USR 24576`) |
| [ShowTitle](../src/main.asm#L74) | $601A | title screen, also after game over |
| [StartGame](../src/main.asm#L169) | $60C9 | new game or demo |
| [NextMaze](../src/main.asm#L186) | $60E9 | next maze (also from the exit and from a demo death) |
| [RestartMaze](../src/main.asm#L297) | $61AA | new life in the same maze |
| [MainLoop](../src/main.asm#L375) | $6229 | the twelve-call loop ([The main loop](04-game-loop.md)) |

The non-local exits ([ExitMaze](../src/events.asm#L765), [HoraceDies](../src/events.asm#L175), the demo abort in
[ReadControls](../src/movement.asm#L52)) become return codes or exceptions in a structured port:
`PlanMoves` returns "exit", `CheckGuardContact` returns "dead", and
`ReadControls` returns "abort demo"; the main loop then branches to the
corresponding entry. The demo-abort stack leak disappears in such a port.

Bugs to decide on (keep for fidelity or fix) are listed in
[Tricks and bugs](06-tricks.md#bugs).

## The Python port

[`port/`](../port) is the whole game in Python on zxpyxel, one module per
asm module and one function per routine, with the memory layout of the
original. `python port/play.py` plays it; `make port-test` replays the three
runs of `tests/inputs/` recorded on the Z80 and checks every pass of the
main loop against them, byte for byte. The non-local exits are `Goto`
exceptions that `Start` dispatches, and the quirks above are kept.
