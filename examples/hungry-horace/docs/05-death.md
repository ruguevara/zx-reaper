# 5d. Guard contact, death and game over

Contact between Horace and a guard is detected by colour: if a magenta cell
lies in the block Horace is about to occupy, the guard either kills him or,
while the bell timer runs, is eaten. A death plays a one-second colour and
noise animation, then restarts the maze, moves the demo on, or ends the game
with a flashing screen.

## Contact test

[CheckGuardContact](../src/events.asm#L27) runs after [DrawGuards](../src/sprites.asm#L235) has drawn every released
guard at its new position, and before [DrawHorace](../src/events.asm#L342). It calls
[GetBlockObject](../src/library.asm#L359) on [HoraceNextPos](../src/variables.asm#L126); if the result is not the guard
attribute $3B, it returns. Any overlap of the 2x2 blocks counts, including a
single cell.

- [BellTimer](../src/state.asm#L61) non-zero: the guard is eaten
  ([Guards](05-guards.md#eaten-guards)): +100, bell timer cleared, falling
  buzz, all released guards back to the start cell with a 90-pass wait.
- [BellTimer](../src/state.asm#L61) zero: `JP HoraceDies`. The return address of the
  `CALL CheckGuardContact` in [MainLoop](../src/main.asm#L375) is still on the stack.

## Death: [HoraceDies](../src/events.asm#L175)

1. [Passes](../src/variables.asm#L204) goes down by one and its digit is reprinted (not in the demo);
   [WrapPause](../src/variables.asm#L215) is cleared.
2. 45 colour steps (`DEATH_FLASHES`). Each step increments the ink of
   [HoraceAttr](../src/variables.asm#L155) (white paper, ink 0-7), redraws Horace with it through
   [DrawHorace_Sprite](../src/events.asm#L352) (which also advances his walking frame), paints the
   first nine attribute cells of the status line (`PASSES` and the digit) in
   the same colour, and plays 20 cycles of noise: speaker on for a random
   64-255 loop passes, off for another random 64-255 ([GetRandom](../src/library.asm#L28) ORed with
   $40). About one second in all.
3. The status-line colour is restored to $38 for the first eight cells, and
   [HoraceAttr](../src/variables.asm#L155) to $39.
4. Every released guard is wiped with [EraseGuard_Always](../src/sprites.asm#L77) (its saved
   background is drawn back) and Horace is wiped with [BlankSprite](../src/sprite_gfx.asm#L162).
5. With no passes left: [GameOver](../src/events.asm#L299). Otherwise the return address is
   dropped (`POP HL`), [ResetGuardTimers](../src/guards.asm#L15) restarts the release timers
   (only the first guard is out again), and:
   - in a game, `JP RestartMaze`: the same maze, with the flowers eaten so
     far, the bell where it was (or gone if taken), Horace and the guards at
     their start cells;
   - in the demo, `JP NextMaze`: the next maze is drawn.

Step 1 also stores 0 into [GuardWait](../src/state.asm#L130) of the working
buffer, which is reloaded before it is used again, so that store has no
effect (noted as "BUG?" in the source).

## Game over: [GameOver](../src/events.asm#L299)

Reached from [HoraceDies](../src/events.asm#L175) when the last pass is lost, and from
[ReadControls](../src/movement.asm#L52) when a key is pressed during the demo.

1. 20 times (`GAME_OVER_FLASHES`): play [PlayRisingTone](../src/guards.asm#L94) and flood all 768
   attributes with ink `B AND 7` on white paper, where B counts 20 down to 1.
   The bitmap is unchanged, so the whole picture changes colour 20 times.
2. `POP HL` drops one word from the stack: on the death path this is the
   return address of the call of [CheckGuardContact](../src/events.asm#L27); on the demo path it
   is a word that belongs to no call (see
   [Tricks and bugs](06-tricks.md#the-demo-abort-leaks-stack)).
3. In a real game, if [Score](../src/variables.asm#L174) ≥ [BestScore](../src/variables.asm#L183), [BestScore](../src/variables.asm#L183) = [Score](../src/variables.asm#L174).
4. `JP ShowTitle`.

The score is not cleared here but by [StartGame](../src/main.asm#L169), so it is still in memory
while the title is shown; the title screen does not display it.
