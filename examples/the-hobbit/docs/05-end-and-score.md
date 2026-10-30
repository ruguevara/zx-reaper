# 5h. The end of the game and the score

A game ends in one of three ways: the valuable treasure is put in the wooden
chest in Bag End (victory), the player dies, or the player types QUIT. All
three wait for a key and start a new game from the backups; there is no
"another game?" question. The score is a percentage kept in tenths and earned
only by visiting places.

## Victory ([CheckVictory](../src/handlers.asm#L1180))

At the start of every world turn ([L96B3](../src/engine.asm#L433)) [CheckVictory](../src/handlers.asm#L1180) tests one byte:
the holder of the valuable treasure (`$23`). When it is the wooden chest
(`$25`), the game prints

> a cheering crowd of dwarves, hobbits and elves appears. Led by gandalf they
> carry you off into the sunset, proclaiming you hero of heroes and master
> adventurer !!!.

and jumps into the end of [EndGame](../src/verbs.asm#L808) after its score line: no score is shown
for a victory (observed, F78; the screen is `win.png` in
[07-graphics](07-graphics.md)). Nothing else is required: the score at the
win of the `endgame.txt` run is 50.0%.

The test runs after the player's command and before the characters act, so
the command that puts the treasure in the chest is the last one. Anyone can
put it there: an order (`SAY TO THORIN "PUT TREASURE IN CHEST"`) would win
as well (inferred).

## Death ([EndGame](../src/verbs.asm#L808), [KillCharacter](../src/engine.asm#L567))

[KillCharacter](../src/engine.asm#L567) with id 0, and the scripted deaths, end in [EndGame](../src/verbs.asm#L808):
"You are dead.", the score, a key, [RestartGame](../src/main.asm#L81).

| Cause | Message | Code |
| --- | --- | --- |
| a fight lost, an arrow | "With one well placed blow ... cleave your skull." | [VerbAttack](../src/verbs.asm#L949), [L9065_0](../src/verbs.asm#L762) |
| walking into a wall in the dark until the strength is 0 | "But fall and smash your skull." | [MoveActor](../src/verbs.asm#L306) |
| staying with the trolls | "The hideous troll eats you." | [LA94E](../src/handlers.asm#L1100) |
| eating until the strength reaches 128 | "Your foul gluttony has killed you." | [L929C](../src/verbs.asm#L1148) (F81) |
| not answering Gollum | "Someone strangles you from behind." | [LA8F6](../src/handlers.asm#L1044) (F76) |
| the forest off the road | "Some thing drops from above and stings." | [LA9E5_18](../src/handlers.asm#L1354) (F83) |
| the deep bog | "You are slowly sinking into the bog." | [LA761_3](../src/handlers.asm#L852) (F80) |
| staying at the spider threads place 5 turns | "The spider web is slowly smothering you" | [LA9E5_13](../src/handlers.asm#L1317) |
| swimming in the black river | "As soon as you touch the river you fall asleep and gently float away." | [LA244_9](../src/handlers.asm#L187) |
| entering the forest river without the barrel | "You are swept forcefully against the portcullis." | [ArriveForestRiver](../src/world.asm#L2268) |
| put into the river | "And it gets swept away." | [L9404_1](../src/verbs.asm#L1369) |
| the dragon, after the treasure has left the hall | "The dragon descends and in a terrific spout of flames burns you to a crisp." | [LA67E_5](../src/handlers.asm#L755) |

There are no lives and no continue: the player's only insurance is SAVE.

## QUIT ([WordQuit](../src/system.asm#L288))

The score, a key, a new game.

## The score ([Score](../src/world.asm#L29), [FirstVisitScores](../src/verbs.asm#L212), [PrintScore](../src/system.asm#L379))

[Score](../src/world.asm#L29) is a 16-bit count of tenths of a percent. It is set to 0 by the
restart and changed in exactly one place: [ActorArrives](../src/verbs.asm#L356), the first time
the player is described a location (location flag bit 6, "visited", is set
at the same moment). The value comes from [FirstVisitScores](../src/verbs.asm#L212), 14 records
keyed by location id (F57, F64):

| Location | Points | | Location | Points |
| --- | --- | --- | --- | --- |
| `$04` the Lone-lands | 2.5% | | `$1B` smothering forest | 2.5% |
| `$07` trolls' cave | 5.0% | | `$1C` elvish clearing | 2.5% |
| `$0B` narrow place | 2.5% | | `$1F` dark dungeon | 5.0% |
| `$16` Beorn's house | 2.5% | | `$22` long lake | 10.0% |
| `$0D` goblins' dungeon | 7.5% | | `$26` Dale | 2.5% |
| `$41` a dark stuffy passage | 5.0% | | `$2A` side door | 2.5% |
| `$2B` smooth straight passage | 5.0% | | `$29` lower halls | 20.0% |

The total is 750, so **the best possible score is 75.0%**: nothing else
writes the score, and no treasure, kill or victory adds to it (observed,
F64). Some of the places are dark and must be entered with the sword's light
to count, because the dark arrival is not described and so not marked
visited.

[PrintScore](../src/system.asm#L379) prints "You have mastered ", the hundreds digit (left out
when 0), the tens digit, a full stop, the units digit and "% Of this
adventure." through [DecimalDigit](../src/system.asm#L420), which divides by repeated subtraction.
It cannot print 100.0% or more: the hundreds quotient 10 would be the
character after "9" (1000 would print ":0.0%"). Since the score cannot pass
750, this never shows (latent, observed by poking the score, F64).

The SCORE word prints the same line at any time without taking a turn; the
score also appears after a death and after QUIT, but not after a victory.
