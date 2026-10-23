# 5.6 Death and game over

Willy dies in one of five ways, all ending in [KillWilly](../src/willy.asm#L577), which marks
him killed and cuts the drawing short. At the end of the pass
[CheckDeath](../src/mainloop.asm#L334) sees the mark and plays a short flash; then either a life is
taken and the room starts again from the point where Willy entered it, or,
with no life left, the game-over scene plays and the title screen follows.
There is no high score.

## Causes

| Cause | Detected in | Path |
| --- | --- | --- |
| nasty tile in any of his cells | [MarkWillyCell](../src/specialrooms.asm#L224) (from [PlaceWilly](../src/specialrooms.asm#L161)) | [KillWillyNested](../src/willy.asm#L573) |
| landing from a fall of state $0C or more | [ReadWillyInput](../src/willy.asm#L255) ($8EE3) | [KillWilly](../src/willy.asm#L577) |
| guardian sprite overlaps lit pixels | [DrawEntities](../src/entities.asm#L245) ($9231) | [KillWilly](../src/willy.asm#L577) |
| arrow centre row over lit pixels in a white cell | [DrawEntities](../src/entities.asm#L245) ($9297) | [KillWilly](../src/willy.asm#L577) |
| the figure in the Master Bedroom overlaps lit pixels | [UpdateBedroom](../src/specialrooms.asm#L22) ($9566) | [KillWilly](../src/willy.asm#L577) |

[KillWilly](../src/willy.asm#L577) drops the return address of the routine that [FrameLoop](../src/mainloop.asm#L98)
called, [KillWillyNested](../src/willy.asm#L573) one more, sets [WillyAirState](../src/variables.asm#L293) to $FF and
jumps into [FrameLoop](../src/mainloop.asm#L98) at [FrameLoop_Present](../src/mainloop.asm#L126), so the screen is updated
with whatever was drawn so far (F42). The rest of the pass runs normally up
to [CheckDeath](../src/mainloop.asm#L334).

## The death scene

[PlayDeath](../src/mainloop.asm#L456) ($8C01) runs eight rounds with the colour A = $47 down to $40
(bright, black paper, ink 7 down to 0):

1. fill the 512 attributes of the room area on the screen with A;
2. buzz: C = A rotated right three times toggles of the speaker with a delay
   D = (7 - ink) * 8 + 7 loop passes: 232 toggles with a short delay in the
   first round down to 8 toggles with a long one in the last, a note falling
   from about 14 kHz to 2 kHz. The border is black meanwhile.

The scene takes about 6 frames (F103).

![The death flash (the poke that starts it ends the pass before Willy is drawn)](img/death.png)

## Restart

[RestartAfterDeath](../src/mainloop.asm#L493) ($8C33): if [LivesLeft](../src/variables.asm#L190) is not 0, decrement it, copy
the seven bytes of [WillySavedState](../src/variables.asm#L386) back to [WillyY](../src/variables.asm#L243)-[WillyJumpStep](../src/variables.asm#L344)
and jump to [EnterRoom](../src/title.asm#L285) (F77, F117). The saved state is the one Willy had
when he entered the room: position, facing, walk frame, air state and jump
step. The room is rebuilt and its entities start again from their
definitions. Items already collected stay collected, the clock keeps its
time, and [WillyRope](../src/variables.asm#L360) is cleared.

Restoring the air state has a consequence at room edges: a fall that was
already fatal when Willy dropped out of the bottom of a room is restored
with the room below, so he falls and dies again, and again, until the lives
are gone (observed, F120). A room entered through a damaged guardian has the
same effect ([Tricks](06-tricks.md#the-attic-arrow)).

## Game over

When a death happens with [LivesLeft](../src/variables.asm#L190) = 0, [ShowGameOver](../src/mainloop.asm#L506) ($8C4A) plays
the closing scene (F104):

1. Clear the top two thirds of the bitmap. Draw Willy ([SpriteWillyRight2](../src/charsprites.asm#L246))
   at row 12, column 15, standing on the barrel ([SpriteBarrel](../src/charsprites.asm#L51)) at row 14.
2. 49 steps with [ScratchByte](../src/variables.asm#L501) = 0, 4, ... $C0: draw the foot
   ([SpriteFoot](../src/charsprites.asm#L25)) at column 15 and pixel row counter / 2 (the address
   comes from [RowAddressTable](../src/buffers.asm#L138), converted from the $6000 buffer to the
   screen by subtracting $20 from the high byte), so the foot comes down
   two pixel rows per step and leaves its leg behind; play 64 speaker
   toggles with a delay of $FF - counter (a rising whistle); flood the
   attributes with bright white ink on paper 0-3 from the counter, and
   colour the barrel's four cells red. The last step puts the foot on
   Willy.
3. Print "Game" at row 6, column 10 and "Over" at column 18.
4. For about 80 frames cycle the inks of the eight letters (each letter one
   ink ahead of the previous; at ink 0 a letter disappears).
5. `JP NewGame`.

The scene lasts about 184 frames, 3.7 seconds.

![The foot coming down](img/gameover-fall.png)

![The end of the scene: "Game Over" with the letters changing colour](img/gameover-end.png)

The foot is also a guardian: definition $48 in "The Nightmare Room" uses
page $9C and frame 2, which is [SpriteFoot](../src/charsprites.asm#L25).
