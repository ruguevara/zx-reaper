# 5c. Bell, fruit, scoring and extra passes

Each maze has one bell. Taking it gives 260 points and starts the bell timer,
during which the guards can be eaten. Fruit appears where a guard has stood,
on a timer of its own. All scoring goes through one routine that also prints
the score, awards an extra pass every 10,000 points and makes a short chirp.
Objects are recognised by their attribute colour, which leads to a few odd
cases described below.

## Scoring

| Event | Points | Where |
| --- | --- | --- |
| flower (green cell in Horace's next block) | 10 | [EatObject](../src/sprites.asm#L133) |
| bell or fruit (red cell in Horace's next block) | 50 | [EatObject](../src/sprites.asm#L133) |
| taking the bell | 60 + 150 | [TakeBell](../src/events.asm#L473) |
| eating a guard while the bell timer runs | 100 | [CheckGuardContact](../src/events.asm#L27) |

[EatObject](../src/sprites.asm#L133) runs on every pass (except during a wrap pause) on the block at
[HoraceNextPos](../src/variables.asm#L126). [GetBlockObject](../src/library.asm#L359) reads the four attribute cells and
[MergeObjectAttr](../src/library.asm#L396) keeps the most important colour found: guard ($3B) over
bell ($3A) over flower ($3C). A flower scores 10, anything else found scores
50. A flower is eaten simply by drawing Horace over it: his sprite replaces
the green attribute, so the same flower is not found again, and the cells
become floor when he moves on. A guard colour would also score 50 here; the
routine headers note that this was not observed.

The score is a 16-bit binary number ([Score](../src/variables.asm#L174)) with no upper limit check; it
would wrap at 65,536.

## Score display and extra passes

[ShowScore](../src/sprites.asm#L169) is called after every score change and at the start of every
maze and life. It:

1. prints [Score](../src/variables.asm#L174) as five digits at row 0, column 15 ([PrintNumber](../src/library.asm#L54);
   nothing is drawn in the demo);
2. computes `score / 10000 + 2` by repeated subtraction and compares it with
   [ExtraPassMark](../src/variables.asm#L194). If it differs, the mark is updated, [Passes](../src/variables.asm#L204) goes up
   by one and its digit is reprinted at column 7;
3. plays a rising chirp: 16 single square-wave cycles with the half period
   falling from 128 to 8 loop passes, about 8 ms.

[StartGame](../src/main.asm#L169) sets [ExtraPassMark](../src/variables.asm#L194) to 0 and [Passes](../src/variables.asm#L204) to 3; the first call
of [ShowScore](../src/sprites.asm#L169) (from [RestartMaze](../src/main.asm#L297), before anything has been eaten)
finds 2, so every game really starts with 4 passes. Seen in the simulator:
the status line shows `PASSES 4` at the start of a game. Passes have no
upper limit, but the counter is printed as one character `"0" + passes`
(read from the code; ten or more passes would print `:`, `;` and so on).

[BestScore](../src/variables.asm#L183) is shown at column 26 when a maze or life starts. [GameOver](../src/events.asm#L299)
replaces it with [Score](../src/variables.asm#L174) when the score is at least as high, in a real game
only.

## The bell

![The four bell frames](img/bell.png)

[BellPos](../src/variables.asm#L283) holds the bell's position, or 0 once it has been taken. It is set
from [MazeBellStart](../src/mazes.asm#L22) when a maze starts; after a lost pass it is reset to
that position only if the bell has not been taken.

[UpdateBell](../src/events.asm#L419) runs after [DrawHorace](../src/events.asm#L342), so [HoracePos](../src/variables.asm#L113) is already the
position Horace has just moved to. With `d = HoracePos - BellPos` (screen
offsets of the top-left cells), the bell is taken when d is one of

| d | Horace relative to the bell |
| --- | --- |
| 0 | same cell |
| -1 | one column left |
| +1 | one column right |
| -32 | one row above |
| +33 | one row below, one column right |

The other overlapping offsets, +32 (one row below), +31, -31 and -33, are not
tested.

If the bell is not taken, [BellTick](../src/variables.asm#L292) is incremented and the bell is redrawn
with attribute $3A, using frame `(BellTick >> 3) AND 7` mirrored into the
sequence 0, 1, 2, 3, 3, 2, 1, 0, so the bell swings once every 64 passes.

[TakeBell](../src/events.asm#L473):

1. clears [BellPos](../src/variables.asm#L283) and draws [BlankSprite](../src/sprite_gfx.asm#L162) at [MazeBellStart](../src/mazes.asm#L22);
2. calls [DrawHorace](../src/events.asm#L342) again so Horace is on top;
3. adds 60 points ([ShowScore](../src/sprites.asm#L169));
4. sets [BellTimer](../src/state.asm#L61) to 128 × [GuardInterval](../src/variables.asm#L34) (1024 at pace 8, 128 at
   pace 1). [DrawGuard](../src/sprites.asm#L273) decrements it once per guard drawn per pass;
5. adds 2 to the direction in the working guard buffer, meant to turn a guard
   round; the buffer is not saved, so this has no effect (see
   [Tricks and bugs](06-tricks.md#bugs));
6. adds 150 points ([ShowScore](../src/sprites.asm#L169)).

With the 50 points [EatObject](../src/sprites.asm#L133) has already given for the red bell cells,
taking the bell is worth 260.

While [BellTimer](../src/state.asm#L61) is non-zero, guards are drawn scared, flee (the AI
subtracts its chase bonus) and are eaten on contact
([Guards](05-guards.md#eaten-guards)). Eating one guard clears the timer.

### The chime

While the bell is in the maze, [PaceAndChime](../src/events.asm#L693) looks at the low six bits of
[BellTick](../src/variables.asm#L292): at 0 it plays a lower then a higher tone, at $20 a higher then
a lower tone, each through the ROM BEEPER routine (about 1010 Hz and 1120 Hz,
about 22 ms each). The tones replace the delay of that pass. With the sound
off, the chime is skipped and the normal delay runs.

## Fruit

![The two fruit pictures](img/fruit.png)

A fruit is never drawn directly. [UpdateFruitDrops](../src/events.asm#L512) loads each released
guard and calls [MaybeDropFruit](../src/events.asm#L558), which:

1. returns if the guard is waiting ([GuardWait](../src/state.asm#L130) non-zero);
2. returns if any of the four cells in the guard's saved background has
   attribute $3A, i.e. the guard is standing on the bell or on a fruit;
3. decrements [FruitTimer](../src/variables.asm#L69); returns unless it reached 0;
4. re-arms the timer to 800 + a random 0-1023 (two [GetRandom](../src/library.asm#L28) bytes, the
   second masked to 0-3 as the high byte);
5. picks [FruitCellsA](../src/variables.asm#L241) or [FruitCellsB](../src/variables.asm#L264) with bit 0 of a third random byte
   and copies its 36 bytes over the guard's [SavedBackground](../src/state.asm#L132).

When the guard next moves, [EraseGuard](../src/sprites.asm#L66) "restores" that background, and
the fruit appears on the cells the guard has just left. The fruit pictures
use the saved-cell format for this reason: green stalk cells with the flower
attribute $3C on top, red cells with the bell attribute $3A below. Eating the
red part scores 50 through [EatObject](../src/sprites.asm#L133).

[FruitTimer](../src/variables.asm#L69) is set to 2000 when a maze starts. It is shared by all guards
and counted down once per eligible guard per pass, so it runs faster with
more guards out. Whatever was under the guard when the fruit was planted is
overwritten, including flowers, which then cannot be eaten any more (read
from the code).
