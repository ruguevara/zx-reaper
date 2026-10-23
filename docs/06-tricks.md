# 6. Tricks, dead code and bugs

This section collects what is not obvious from the routine list: where the
random numbers come from, how the screen attributes replace a collision map,
a few space-saving shortcuts, the code that never runs, and every bug found.
Each bug is marked **verified** (seen in the simulator, sometimes with poked
state) or **inferred** (read from the code, not reproduced).

The program contains no self-modifying code: no instruction operand is
written at run time.

## Random numbers from the ROM

There is no pseudo-random generator. The game uses the bytes of the 16K ROM
as its random sequence, through two independent pointers.

**[GetRandom](../src/library.asm#L28)** walks [RandomPtr](../src/variables.asm#L79) through $0000-$1FFF, one byte per call:

```asm
GetRandom:
  LD HL,(RandomPtr)
  LD A,(HL)               ; the random byte
  PUSH AF
  INC HL
  LD A,H
  AND ROM_HIGH_MASK       ; $1F: stay inside the first 8K
  LD H,A
  LD (RandomPtr),HL
  POP AF
  RET
```

[Start](../src/main.asm#L52) seeds the pointer once: F = low byte of FRAMES, A = ROM byte at
`(F AND $1F) * 256 + F`, pointer = `(A AND $1F) * 256 + A`. FRAMES counts
interrupts since power-on, so the seed depends on how long the tape took to
load. Users: the demo [Autopilot](../src/movement.asm#L69), the death noise in [HoraceDies](../src/events.asm#L175) and
the fruit timer and shape in [MaybeDropFruit](../src/events.asm#L558).

**The guard AI** ([ChooseGuardMove_3](../src/movement.asm#L463)) does not call [GetRandom](../src/library.asm#L28). It uses
the low word of the system variable FRAMES as a second pointer, incrementing
it before every read and masking the high byte to $0F ($0000-$0FFF). With
interrupts off nothing else changes FRAMES, so the variable has become a
private counter of the AI.

ROM code is far from uniform (many repeated opcodes and zero bytes), so these
numbers are biased; the game only uses them for weights and delays.

## Attributes as the collision map

After a maze is drawn, its map in memory is never read again. Walls, pads,
arrows, flowers, the bell, fruit, Horace and the guards are all identified by
the attribute byte of the cells they occupy (table in
[Data structures](02-data.md#attributes-colours-that-are-also-object-types)).
Eating a flower is just drawing Horace over it; a flower needs no list or
counter (and there is none, so clearing a maze of flowers has no effect).

The cost is that drawing order and colours become game logic:

- the status line and the title use $38, the arrow colour. Row 0 is never
  probed, so this has no effect;
- the fruit is made of a flower-coloured stalk and bell-coloured body, so it
  scores as "bell" (50) in [EatObject](../src/sprites.asm#L133);
- the bell is redrawn after Horace on every pass, which keeps its attribute
  alive in cells that overlap Horace (next item under [Bugs](#bugs));
- during the death animation Horace is drawn in every ink colour, including
  the guard's and the wall's, but nothing reads the attributes then.

## IX as a harmless delay

The falling buzz in [CheckGuardContact](../src/events.asm#L27) uses a slow inner loop:

```asm
CheckGuardContact_0:
  LD A,(IX+$00)           ; IX is left in the tile graphics by DrawMaze
  LD (IX+$00),A           ; the byte is written back unchanged
  DJNZ CheckGuardContact_0
```

The read and write of (IX+0) only waste time (51 T-states per pass instead of
13 for a bare `DJNZ`). IX is not set here; it still points where
[DrawMaze](../src/library.asm#L155) left it: one past the bitmap of the last tile drawn (the
bottom-right cell, tile 0 or 8 in the four maps), which is inside
[TileGraphics](../src/tiles.asm#L10) in RAM, so the write changes nothing (read from the code and
the maps).

## Other shortcuts

- **Leaving the loop by dropping a return address.** [ExitMaze](../src/events.asm#L765),
  [HoraceDies](../src/events.asm#L175) and the demo abort leave the main loop with `POP HL` and a
  `JP`, instead of returning a status to the loop.
- **One flag for "demo" and "no text".** [PrintChar](../src/library.asm#L105) tests bit 0 of
  [GameActive](../src/texts.asm#L72); the title and banner printing set the flag temporarily
  ([Drawing](05-drawing.md#title-and-status-texts)).
- **Fruit by background substitution.** [MaybeDropFruit](../src/events.asm#L558) never draws a
  fruit; it overwrites the background saved under a guard, and
  [EraseGuard](../src/sprites.asm#L66) draws it when the guard moves on.
- **A table end marker that is another variable.** The AI and the autopilot
  scan [GuardDirScores](../src/state.asm#L82) backwards from the address of [GuardRecordPtr](../src/state.asm#L94),
  the next variable, instead of using an explicit end.
- **The title tone as the loop delay.** [TitleLoop](../src/main.asm#L130) and [GameOver](../src/events.asm#L299) are
  paced only by [PlayRisingTone](../src/guards.asm#L94).

## Dead code and unused bytes

| Address | What | Status |
| --- | --- | --- |
| $5FB5-$5FFF | 75 zero bytes before the entry point ([L5FB5](../src/main.asm#L6)) | never read or written |
| $672F | `CALL DrawGuard` at the head of the guard-reset loop tail ([L672F](../src/events.asm#L136)); the `JR` before it jumps over it | never executed |
| $6A17-$6A1D | `LD A,(IX+0); LD A,(IX+0); RET` ([L6A17](../src/events.asm#L761)) | never executed |
| $670F-$6716 | `LD HL,(HoraceNextPos); CALL GetBlockObject; CP ATTR_GUARD` in [CheckGuardContact](../src/events.asm#L27): the flags are never tested | executed, no effect |
| [UnusedAiCounter](../src/variables.asm#L58) ($7C64) | decremented when the AI scores direction 3, reloaded with the pace for direction 0; nothing reads it (verified by a watch in the simulator) | dead state |
| [StepCell](../src/library.asm#L643), left | `DEC L` does not change the carry, which is clear after the preceding `CP`s, so the `JR NC` is always taken and the three instructions that would move to the previous screen third never run. Nothing moves left out of column 0, so it does not matter | never executed |
| $7FA7-$7FFF | 89 zero bytes after the sprites ([L7FA7](../src/sprite_gfx.asm#L172)) | never read or written |

## Bugs

| Bug | Effect | Status |
| --- | --- | --- |
| [Demo abort leaks stack](#the-demo-abort-leaks-stack) | SP rises 2 bytes per demo abort; crash after about 70 | verified |
| [TickGuardTimers counts the wrong thing](#tickguardtimers-counts-the-wrong-thing) | game speeds up, or at pace 1-3 stalls for half a second per pass, during the last 256 passes of a guard's timer after the bell is taken | verified (with pokes) |
| [The bell pays 50 points per pass](#the-bell-pays-50-points-per-pass) | +50 on every pass while Horace overlaps the bell at an untested offset | verified (with pokes); reachability inferred |
| [Scared guards turn towards Horace](#scared-guards-turn-towards-horace) | the flee score wraps below 0 | verified (source) |
| [Guards sent home by byte steps](#guards-sent-home-by-byte-steps) | a guard still waiting can be "sent home" | verified (source) |
| [The bell's turn-round is lost](#lost-writes-to-the-working-guard-buffer) | [TakeBell](../src/events.asm#L473) turns a guard in a buffer that is never saved | verified (source) |
| [HoraceDies clears GuardWait in the buffer](#lost-writes-to-the-working-guard-buffer) | no effect | inferred |
| [Free extra pass at the start](#free-extra-pass-at-the-start) | every game starts with 4 passes, not 3 | verified |
| [First note of the eaten buzz](#smaller-oddities) | 256 loop passes instead of 0 | inferred |
| [EatObject scores a guard](#smaller-oddities) | a guard cell in Horace's next block scores 50 | inferred, not observed |
| [SaveBackground returns HL and DE swapped](#smaller-oddities) | no caller uses them | inferred |
| [Passes above 9](#smaller-oddities) | printed as `:` `;` ... | inferred |

"Verified (source)" means the routine header in the source says it was
reproduced in the simulator during annotation.

### The demo abort leaks stack

During the demo, [ReadControls](../src/movement.asm#L52) leaves on a key press like this:

```asm
  POP HL                  ; forget the call to ReadControls...
  JP GameOver             ; ...and leave the demo
```

[GameOver](../src/events.asm#L299) is also the end of the death path, where the stack still holds
the return address of `CALL CheckGuardContact`, and it removes that with its
own `POP HL`. On the demo path that word has already been removed, so the
second `POP HL` takes a word that belongs to no call and SP ends two bytes
higher than it should. Measured in the simulator: SP is $5F9D in the main
loop, $5F9F after the first abort, and so on. From the 63rd abort without a
reset, stack pushes overwrite the title code from $601A, and the 70th abort
crashes. Fix: let [ReadControls](../src/movement.asm#L52) jump to [GameOver](../src/events.asm#L299) without its own
`POP HL`.

### TickGuardTimers counts the wrong thing

[GuardsReleased](../src/texts.asm#L55) is meant to count the released guards, and
[PaceAndChime](../src/events.asm#L693) shortens the delay by `2 * (count rotated left 6 times)`
loop passes. [TickGuardTimers](../src/events.asm#L621) increments it like this:

```asm
  DEC DE                  ; DE = this guard's timer, just decremented
  ...
  LD A,D
  OR C                    ; C is whatever the caller left in it
  JR NZ,TickGuardTimers_0
  LD A,(GuardsReleased)
  INC A
  LD (GuardsReleased),A
```

C is not set in this routine. It is left over from [UpdateFruitDrops](../src/events.asm#L512) and
ultimately from [UpdateBell](../src/events.asm#L419), which returns C = $3A while the bell is in
the maze and C = 0 after it has been taken. So the count stays 0 while the
bell is present (verified: no change in 6000 frames of demo); after the bell
is taken it increments on every pass for every timer whose high byte is 0,
that is during the last 256 passes of each waiting guard's timer, and wraps
back to 0 (verified: 256 increments). The test was probably meant to be
`OR E` ("timer reached zero").

The delay is `$015E + $1E·n - 2·A` passes, where A is the count rotated left
six times through carry (`RLA`), up to 223. The subtraction has no floor. At
pace n = 1, 2 or 3 the base (380, 410, 440) is smaller than the largest
possible 2·A (446), and `Delay` with a "negative" count loops almost 65,536
times, about 1.7 million T-states. Verified with pokes in the simulator
(snapshot of the play script, [GuardInterval](../src/variables.asm#L34) set to 1, [BellPos](../src/variables.asm#L283) set to
0 as if the bell had been taken, guard 3's timer set to $0140): once the
timer's high byte reached 0, the game stalled for about 25 frames on every
fourth pass, with normal passes in between. At pace 4-8 the same window only
makes the game faster. In a real game this needs a guard still waiting when
the bell is taken, which happens after a lost pass, when the timers restart.

The [PaceAndChime](../src/events.asm#L693) header says the term is "in practice zero"; that holds
only while the bell is in the maze.

### The bell pays 50 points per pass

[UpdateBell](../src/events.asm#L419) takes the bell only when `HoracePos - BellPos` is 0, -1, +1,
-32 or +33; the overlapping offsets +32, +31, -31 and -33 are not tested.
[EatObject](../src/sprites.asm#L133) meanwhile scores 50 whenever a cell of Horace's next block has
the bell attribute $3A. Because [UpdateBell](../src/events.asm#L419) redraws the bell after
[DrawHorace](../src/events.asm#L342) on every pass, the overlapping cells get the bell attribute
back each time, and [EatObject](../src/sprites.asm#L133) scores them again on the next pass, even
while Horace stands still between steps.

Verified with a poke: placing the bell one row above Horace (d = +32) in the
play-script snapshot adds 50 points on every pass ($7C73 rose by $32 per
pass in a memory watch). Where it happens in play (inferred from the maps):
in mazes 3 and 4 the bell lies at the top of a vertical corridor, so Horace
walking up to it passes through d = +64 and then d = +32, where he collects
50 points per pass for one step (8 passes, 400 points, at pace 8) before
reaching d = 0. In mazes 1 and 2 the bell can only be approached from the
side.

### Scared guards turn towards Horace

While [BellTimer](../src/state.asm#L61) runs, [ChooseGuardMove](../src/movement.asm#L389) subtracts the chase bonus
`10 + distance` from the score of each direction that leads towards Horace:

```asm
  ADD A,AI_CHASE_BIAS     ; distance + 10
  ...
  NEG                     ; scared: subtract instead of add
  ...
  ADD A,C                 ; C = base score of the direction
  LD C,A
```

The sum is an 8-bit value compared unsigned, so when the bonus is larger than
the base score the result wraps to a value above 200 and becomes the best score. The
reverse direction has base 15, so a scared guard walking away from Horace
turns round towards him whenever he is 6 or more cells behind it along that
axis. The source header records this as reproduced in the simulator.

### Guards sent home by byte steps

When Horace eats a guard, [CheckGuardContact](../src/events.asm#L27) sends every released guard
home. Its loop ([CheckGuardContact_Reset](../src/events.asm#L94)) advances the timer pointer by one
byte per guard instead of two, so for guard k it tests the bytes at
`GuardTimers + k` and `+ k + 1`. Released guards are still all found (their
timers and those before them are 0), but a waiting guard can be treated as
released, for example the second guard when the low byte of its timer is 0.
The only consequence is that its record gets the start cell and a 90-pass
wait it would have had anyway; the source notes this was seen in the
simulator with no visible harm.

### Lost writes to the working guard buffer

Two routines change [GuardRecord](../src/state.asm#L122) outside a load/save pair; the next
[LoadGuardRecord](../src/guards.asm#L41) overwrites the change:

- [TakeBell](../src/events.asm#L473) adds 2 to [GuardDir](../src/state.asm#L124), apparently to turn a guard round when
  the bell is taken. In the simulator $6DBA went 3, 1 and back to 3 on the
  next pass (verified, per the source).
- [HoraceDies](../src/events.asm#L175) stores 0 into [GuardWait](../src/state.asm#L130) (inferred: the buffer is
  reloaded before any use).

### Free extra pass at the start

[StartGame](../src/main.asm#L169) sets [Passes](../src/variables.asm#L204) to 3 and [ExtraPassMark](../src/variables.asm#L194) to 0. [ShowScore](../src/sprites.asm#L169)
compares the mark with `score / 10000 + 2` (its counting loop starts at 1
and adds one more), finds 2 on the first call, and awards a pass. Every game
starts with `PASSES 4` (verified on screen). Whether this was intended
cannot be told from the code.

### Smaller oddities

- **First note of the eaten buzz.** The half period is `8 * (15 - C)` with C
  starting at 15, so the first value is 0, which `DJNZ` runs as 256 passes:
  a long low note before the falling sweep.
- **EatObject and guards.** [MergeObjectAttr](../src/library.asm#L396) gives the guard colour the
  highest priority, and [EatObject](../src/sprites.asm#L133) scores 50 for anything that is not a
  flower, so a guard cell in Horace's next block would score 50 before
  [CheckGuardContact](../src/events.asm#L27) runs. Guards that have just moved are erased by then,
  but one that stayed put is still on the screen. Not observed.
- **SaveBackground.** It pushes BC, DE, HL and pops DE, HL, BC, so it returns
  with HL and DE swapped. No caller uses them.
- **Passes above 9.** [Passes](../src/variables.asm#L204) has no limit, but its digit is printed as
  the character `"0" + passes`, so 10 passes would show as `:`.
- **Score wrap.** [Score](../src/variables.asm#L174) wraps at 65,536; [ShowScore](../src/sprites.asm#L169) would then see a
  different ten-thousands value and award another pass (inferred).
