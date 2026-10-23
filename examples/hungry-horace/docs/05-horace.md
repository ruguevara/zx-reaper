# 5a. Horace: controls and movement

Horace moves one character cell per step in his current direction and keeps
going until a wall stops him. A key only changes that direction, and only
when the way in the new direction is open. Movement is decided by looking at
the attributes of the screen cells ahead, through one probe routine shared
with the guards. Two special cases are the invisible wrap pads, which move
him to the other edge of the maze, and the right-hand arrows, which end the
maze.

## Controls

[ReadControls](../src/movement.asm#L52) runs on every pass of the main loop. It does nothing while
[WrapPause](../src/variables.asm#L215) is non-zero. Otherwise it clears [RequestedDir](../src/variables.asm#L137) to $FF and,
in a real game, jumps to [ReadKeys](../src/movement.asm#L135); in the demo it runs the
[Autopilot](../src/movement.asm#L69) ([Title and demo](03-title-and-menu.md#the-autopilot)).

[ReadKeys](../src/movement.asm#L135) reads four half-rows of port $FE and tests the keys in a fixed
order; the first key found wins:

| Direction | Keys | Half-row (port high byte), bit |
| --- | --- | --- |
| up (0) | Q, 4 | $FB bit 0; $F7 bit 3 |
| down (2) | Z, 3 | $FE bit 1; $F7 bit 2 |
| right (1) | P, 2 | $DF bit 0; $F7 bit 1 |
| left (3) | I, 1 | $DF bit 2; $F7 bit 0 |

The key's direction is then probed from Horace's current position with
[ProbeMove](../src/library.asm#L556) ([ReadKeys_Probe](../src/movement.asm#L188)). A wall cancels the request, so Horace
carries on in his old direction; any other result (free, wrap pad, arrows)
makes the request the new [HoraceDir](../src/variables.asm#L146) immediately. Holding a key before a
junction therefore turns Horace at the first cell where the turn is open.
There is no input buffering beyond that: a key released before the junction
is forgotten.

## Probing the way ahead

[ProbeMove](../src/library.asm#L556) answers "what would a 16x16 figure at HL run into if it took
one step in direction A?". It moves the address one cell with [StepCell](../src/library.asm#L643)
and classifies the four attribute cells of the block there with
[ProbeCell](../src/library.asm#L606):

| Cell attribute | Effect on the running total E |
| --- | --- |
| $3D wall | E = $FF, the remaining cells are skipped |
| $3F wrap pad | E + 1 |
| $38 arrow | E + 4 |
| anything else (floor, flower, Horace, guard, bell) | none |

The result:

| A | Constant | Condition |
| --- | --- | --- |
| 3 | `MOVE_BLOCKED` | a wall cell |
| 1 | `MOVE_WRAP` | two or more pad cells (bit 1 of E) |
| 2 | `MOVE_EXIT` | two or more arrow cells (bit 3 of E) |
| 0 | `MOVE_FREE` | otherwise |
| $82 | | both two pads and two arrows; every caller treats it as blocked |

Guards, flowers and the bell never block: the probe only knows walls, pads
and arrows. [StepCell](../src/library.asm#L643) has no bounds check; the maze borders are walls or
arrows, so the probe never needs one.

## Movement

The movement step is in the first half of [PlanMoves](../src/movement.asm#L237). It runs only on the
pass where [StepCountdown](../src/variables.asm#L21) reaches 0 (then reloaded from
[GuardInterval](../src/variables.asm#L34)), and skips Horace while [WrapPause](../src/variables.asm#L215) is non-zero. The
probe in [HoraceDir](../src/variables.asm#L146) decides:

| Probe | New [HoraceNextPos](../src/variables.asm#L126) |
| --- | --- |
| free | one cell on ([StepCell](../src/library.asm#L643)) |
| wall | unchanged |
| arrows, moving right | none: jumps to [ExitMaze](../src/events.asm#L765), the next maze starts |
| arrows, any other direction | unchanged (the entrance arrows on the left are a wall for Horace) |
| wrap pad | position + wrap delta (moving up) or - wrap delta (moving down) |

Whatever the result, the guards are planned afterwards (except on the exit).
[PlanMoves](../src/movement.asm#L237) only plans; the screen is changed later in the pass by
[EraseSprites](../src/sprites.asm#L13) and [DrawHorace](../src/events.asm#L342).

### The exit

[ExitMaze](../src/events.asm#L765) is two instructions:

```asm
ExitMaze:
  POP HL          ; drop PlanMoves' return address into the main loop
  JP NextMaze
```

The main loop calls [PlanMoves](../src/movement.asm#L237), so dropping that one return address leaves
the stack as it was before the loop, and [NextMaze](../src/main.asm#L186) draws the next maze.
Only the right-hand arrows act as an exit, and only for Horace: the guard AI
and the demo autopilot score arrows as 0.

### Wrap pads

A wrap pad is a pair of invisible cells (tile 9, attribute $3F) at the end of
a vertical corridor. When the probe finds two pad cells, the new position is
the current one plus the first word of [MazeDescriptor](../src/mazes.asm#L20) when moving up, or
minus it when moving down ([PlanMoves_Wrap](../src/movement.asm#L262)). Horace does not walk onto the
pad: he jumps from the cell next to it to the far end. Per maze (rows of
the top-left cell, derived from the maps and descriptors):

| Maze | Pads | Delta | Effect |
| --- | --- | --- | --- |
| 1 | row 14, columns 16-17 | -8 rows | going up from row 15 lands at row 7; the cells above the pad are wall, so it can only be entered from below and works in one direction only |
| 2 | rows 1 and 23, columns 13-14 | +19 rows | row 2 going up lands at row 21; row 21 going down lands at row 2 |
| 3 | none | 0 | |
| 4 | rows 3 and 21, columns 4-5 and 26-27 | +15 rows | row 4 going up lands at row 19 and back |

A wrap also:

- plays a short rising tone (16 steps of 8 cycles, about 0.07 s) inside
  [PlanMoves](../src/movement.asm#L237) itself;
- sets [WrapPause](../src/variables.asm#L215) to 90 (`WRAP_PAUSE`). For the next 90 passes
  [ReadControls](../src/movement.asm#L52) reads no keys, [PlanMoves](../src/movement.asm#L237) does not move Horace,
  [EatObject](../src/sprites.asm#L133) scores nothing, and [DrawHorace](../src/events.asm#L342) only counts down and copies
  [HoraceNextPos](../src/variables.asm#L126) to [HoracePos](../src/variables.asm#L113) without drawing. Horace is invisible at
  his new place for those 90 passes (about 1.4 s, with the 1.3 passes per frame
  measured at pace 8).

[CheckGuardContact](../src/events.asm#L27) has no wrap-pause test, so a guard can still catch the
invisible Horace at his landing cell (read from the code; not tested).

The guards use the same pads with the same delta ([ChooseGuardMove](../src/movement.asm#L389)), but
without the pause or the tone.

## Drawing Horace

[EraseSprites](../src/sprites.asm#L13) (third in the pass) draws [BlankSprite](../src/sprite_gfx.asm#L162) with attribute $3E
at [HoracePos](../src/variables.asm#L113) when [HoraceNextPos](../src/variables.asm#L126) differs from it. That also removes a
flower he has just eaten: the flower was under the cells he walked onto, he
was drawn over it, and the cells become floor when he leaves.

[DrawHorace](../src/events.asm#L342) (seventh) draws the sprite at [HoraceNextPos](../src/variables.asm#L126) and copies it
to [HoracePos](../src/variables.asm#L113). It increments [HoraceAnim](../src/variables.asm#L164) on every draw, that is on
every pass, not on every step; bit 4 selects [HoraceSprites](../src/sprite_gfx.asm#L15) or
[HoraceSprites2](../src/sprite_gfx.asm#L40), so the legs change every 16 passes whether he walks or
stands. [HoraceDir](../src/variables.asm#L146) selects one of the four sprites of the set, and
[HoraceAttr](../src/variables.asm#L155) (normally $39) is the colour. [DrawHorace_Sprite](../src/events.asm#L352) is a
second entry without the wrap-pause test, used by the death animation.

Horace is drawn on every pass with [DrawSprite](../src/library.asm#L247), which writes the four
attribute cells too. This is how a flower under him disappears from the
collision map: the green attribute is replaced by his blue one at once.
