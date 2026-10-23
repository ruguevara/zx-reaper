# 3. The start of a game

There is no menu and no demo: the loading screen stays up as the title until a
key is pressed, the key that starts the game also decides whether pictures
are shown, and the game then plays the command `LOOK` by itself. This file
follows the code from `PRINT USR 27648` to the first prompt.

## Start-up: back up the story ([GameStart](../src/main.asm#L60))

The four state blocks (variables, objects and characters, timers and NPC
records, locations) hold the story as it was loaded. The first thing the game
does, with interrupts off for good, is copy them to backups: the two large
blocks to `$F400-$FFED` ([StateBackup](../src/pictures.asm#L4585), memory that was loaded as zeros),
the two small ones to `$5F00`. Everything that later restarts the game copies
the backups back, so a new game never needs the tape.

## Restart and the title wait ([RestartGame](../src/main.asm#L81))

[RestartGame](../src/main.asm#L81) is the entry point used by QUIT ([WordQuit](../src/system.asm#L288)), death and
victory ([EndGame](../src/verbs.asm#L808)) and a failed LOAD ([LoadBlock](../src/system.asm#L509)). It:

1. resets the stack to `$5EFF`;
2. zeroes the border and attribute bytes of picture 5, undoing the change the
   trolls' dawn makes to that picture ([06-tricks](06-tricks.md));
3. copies the four backups over the state blocks;
4. sets the border black and BORDCR to black on white;
5. waits until any key is down ([WaitTitleKey](../src/main.asm#L112): `IN` from port `$FE` with
   all half-rows selected).

The screen at this moment is whatever was there: the loading screen after
`LOAD`, the last game's text after a restart.

| Key moment | Effect |
| --- | --- |
| the key goes down | `IN` from half-row `$7FFE`; bit 3 is the N key. N held: [PicturesEnabled](../src/world.asm#L57) = 0, no picture for the whole game (inferred from the port bit; the input scripts always start with another key) |
| same moment | `LD A,R`: the refresh register, which depends on how long the player waited, becomes the random seed [RandomSeed](../src/world.asm#L76) |

So the game differs from one start to the next only through this seed: the
blocked exit, Gollum's riddle and every random choice of the characters
follow from it.

## Setting up the screen

Still in [RestartGame](../src/main.asm#L81):

- the input window cursor goes to the bottom row (`$50E0`) with the glyph `+`,
  the story window cursor to the start of row 17, both column counters to a
  full line (32 and 42);
- the 8 order slots are cleared (no character has been told anything);
- the list indent, the lisp ([LispFlag](../src/world.asm#L43)), the printer and the pending question are off;
  messages are visible, the score is 0;
- [ClearScreen](../src/keys.asm#L381) sets a white border and black ink on white paper everywhere;
- a decorative rule is drawn across character row 18, between the two
  windows: [BorderTile](../src/main.asm#L299), five pixel lines of a 16-pixel pattern repeated 16
  times;
- [NoPauseLines](../src/world.asm#L88) = 17: the opening text scrolls without the pause that
  normally follows each line.

## The opening LOOK ([AutoLook](../src/main.asm#L181))

[ParserWordCount](../src/world.asm#L55) is `$FF` in the saved state (it is set by the parser only
after a line, and the backups hold the value from the tape), so after every
start and restart the game takes this path (F47):

1. [InitNewGame](../src/engine.asm#L608): the player is the subject and the acting actor; one of the
   five [BlockedExits](../src/world.asm#L2299) is chosen at random and its exit triple is zeroed in
   the location record; one of the four [RandomEvents](../src/world.asm#L2281) (Gollum's riddle) is
   chosen.
2. `"> LOOK"` ([StartCommand](../src/keys.asm#L404)) is echoed in the input window and `LOOK` plus a
   carriage return is copied into [InputLine](../src/keys.asm#L414).
3. The main loop is entered at [BuildWordList](../src/main.asm#L206), as if the player had typed
   the line: the player sees the description and picture of Bag End (the
   "tunnel like hall"), the key wait after the picture, then the exits and the
   objects, and Gandalf and Thorin start acting.

The five exits that can be removed (one per game; the map shown to Elrond puts
it back, [05-world](05-world.md)):

| Location | Exit removed |
| --- | --- |
| Beorn's house (`$16`) | north to the great river (`$31`) |
| forest gate (`$18`) | east to the bewitched gloomy place (`$19`) |
| treeless opening (`$15`) | west to outside the goblins' gate (`$14`) |
| long lake (`$22`) | east to Lake-town (`$23`) |
| misty mountain (`$0A`) | east to the narrow place (`$0B`) |

## Screens

![The start screen: Bag End after the opening LOOK](img/screenshot.png)

More screens are in [07-graphics](07-graphics.md).
