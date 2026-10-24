# 5e. Time: turns, timers and chance

Time in the game is counted in turns, one per command carried out; the
clock only moves on its own when the player is idle, by typing WAIT. Ten
timers count turns for the events of the story (doors that open and close,
traps, the dawn), and one random number routine, seeded by how long the player
looked at the title screen, decides everything the characters and fights
leave to chance.

## Turns

A turn is what [EndOfTurn](../src/parser.asm#L1057) does after a command has been carried out
([04-game-loop](04-game-loop.md)):

1. [CheckVictory](../src/handlers.asm#L1180);
2. [RunNpcScripts](../src/engine.asm#L765): the 17 character records in table order;
3. the timers in table order.

What takes a turn and what does not:

| Takes a turn | Takes no turn |
| --- | --- |
| every command that passes its test pass | a refused command ("You cannot ...", "I see nothing here.") |
| a verb with no command record: `SING`, `WAIT` ("Time passes...") | a parser error ("What ?", "I do not know the word") |
| each object of ALL | the system words: SCORE, HELP, SAVE, LOAD, PRINT, PAUSE |
| the automatic WAIT of an idle player | |

Each sentence of a line is its own turn, so `N. N. N` moves three times and
the characters act between the moves.

## The automatic WAIT ([WaitKey](../src/keys.asm#L802))

The line editor counts keyboard scans; after 3000 scans without a key (about
23 seconds, F36) it types `WAIT` and ENTER by itself. The count is refilled at
each new line, and each key gives 500 scans back (up to 3000), so a slow typist
is not interrupted. The effect is that the world goes on without the player:
Gandalf wanders off, the trolls' dawn comes, Gollum's riddle runs out.

## Timers ([Timers](../src/world.asm#L2762), stepped by [L96B3](../src/engine.asm#L433))

Each timer has a counter that is stopped at 0. A handler that starts a timer
copies its start value into the counter; each turn the counter goes down by
one; at 0 the fire handler runs; while the counter is between 1 and the
threshold the tick handler runs every turn. Only one timer may fire per turn:
a second one whose counter reaches 0 in the same turn is set back to 1 and
fires on the next (verified, F50). Nothing wraps: a stopped counter is never
decremented (F75).

| Timer | Start | Started by | Tick (threshold) | Fire | What it is |
| --- | --- | --- | --- | --- | --- |
| 0 | 2 | [LA5E2](../src/handlers.asm#L617): the barrel thrown through the trap door into the forest river | | [LA5E2_0](../src/handlers.asm#L629) | the barrel floats down to the long lake ("You are thrown onto the bank of the long lake." if the player is inside); the barrel goes back to the cellar, closed and full of wine |
| 1 | 2 | [LA377](../src/handlers.asm#L262): the spider web broken ("Some spiders start mending the broken web.") | | [LA9E5_2](../src/handlers.asm#L1236) | the web is whole and closed again, with its strength byte doubled |
| 2 | 5 | [ArriveSpiderPlace](../src/world.asm#L2229) | | [LA9E5_13](../src/handlers.asm#L1317) | a player still at the spider threads place: "The spider web is slowly smothering you", death |
| 3 | 2 | [LA4C0](../src/handlers.asm#L440): the goblins' door opened from the big cavern | | [LA4C0_0](../src/handlers.asm#L450) | the door closes again |
| 4 | 2 | [ArriveBog](../src/world.asm#L2235) | [LA761_3](../src/handlers.asm#L852) (2) | [LA761_3](../src/handlers.asm#L852) | the deep bog: death at the end of the arrival turn (observed, F80) |
| 5 | 4 | [LA67E_6](../src/handlers.asm#L782): the magic door examined by an invisible player ("The magic door warns of elves approaching.") | [LA9E5_7](../src/handlers.asm#L1274) (1) | [LA9E5_9](../src/handlers.asm#L1289) | "The magic door opens." and "An elf sweeps past.", then "The magic door closes." |
| 6 | 2-10 | [LA377_0](../src/handlers.asm#L271): the ring put on | | [LA9E5_10](../src/handlers.asm#L1294) | the ring stops working: the wearer is visible again |
| 7 | 5 | [LA9E5_11](../src/handlers.asm#L1304): the wine drunk | | [LA9E5_12](../src/handlers.asm#L1313) | the lisp ([LispFlag](../src/world.asm#L43)) ends |
| 8 | 4 | [ArriveForest](../src/world.asm#L2260) | [LA9E5_14](../src/handlers.asm#L1324) (3) | [LA9E5_16](../src/handlers.asm#L1341) | the forest off the road: "pale bulbous eyes"; leaving it, or staying three more turns, is death (observed, F83) |
| 9 | 5 (3 the first time) | [ArriveCellar](../src/world.asm#L2242); then itself | [LA9E5_5](../src/handlers.asm#L1258) (1) | [LA9E5_3](../src/handlers.asm#L1244) | the side door of the Lonely Mountain: "There is a loud crack and a hole appears..." on one turn, "The hole vanishes." on the next, every 5 turns while the door is not open |

Other events that run by turns without a timer: the trolls' dawn (their
script counts four turns, [05-characters](05-characters.md)), Gollum's
riddle (one turn to answer), the dragon (a chance every turn).

## Random numbers ([RandomSigned](../src/objects.asm#L424), [RandomUpTo](../src/objects.asm#L402))

There is one generator, [RandomSigned](../src/objects.asm#L424): `RandomSigned(A)` returns a value
from -A to A.

```
seed  = (seed + mem[ptr] + carry) XOR mem[ptr + DE + 1]   ; repeated if equal to the old seed
ptr   = ptr + $0100 (and + 1 when the high byte wraps)    ; RandomRomPtr
r     = seed; while r > 2*A: r = r / 2                    ; 2*A capped at 255
return r - A
```

- The state is the seed [RandomSeed](../src/world.asm#L76) and the pointer [RandomRomPtr](../src/world.asm#L84). The seed starts as the R register read when the title key
  is pressed ([RestartGame](../src/main.asm#L81)); R counts instruction fetches, so it depends on
  how long the player waited.
- The pointer walks the whole 64K, one page per call: ROM, screen, the game's
  code and data, the stack. So the numbers depend on what is on the screen and
  on the stack at the time, and a build of the game moved in memory gets other
  numbers (observed in the shift test, F63).
- `DE` is whatever the caller left in it and adds noise to the second byte.
- [RandomUpTo](../src/objects.asm#L402) folds the signed value: `|RandomSigned(A)|`, 0 to A. Because
  of the fold, 0 and A come half as often as the values between, and the
  halving makes large values rarer: `RandomUpTo(100)` has a mean of about 39
  (observed over 768 calls, F74). No caller asks for more than 100.

Where chance is used:

| Use | Call | Code |
| --- | --- | --- |
| which exit is removed, which riddle | `RandomUpTo(4)`, `RandomUpTo(3)` | [InitNewGame](../src/engine.asm#L608) |
| direction in the dark, RUN | `RandomUpTo(9)`+1, `RandomUpTo(10)` | [VerbMove](../src/verbs.asm#L294), [VerbRun](../src/verbs.asm#L639) |
| fights | `RandomSigned(10)` on attack and defence | [RollStrength](../src/verbs.asm#L1038) |
| breaking things | `RandomSigned(21)` | [StrikeObject](../src/verbs.asm#L1211) |
| orders accepted | `RandomUpTo(obedience)` | [TalkToCharacter](../src/verbs.asm#L730) |
| random scripts | `RandomUpTo(n)` | [ChooseRandomScript](../src/engine.asm#L1141) |
| the ring's duration | `RandomUpTo(8)`+2 | [LA377_0](../src/handlers.asm#L271) |
| speech: Gandalf, Thorin, Gollum, gifts | `RandomUpTo(2..10)` | [GandalfCheers](../src/handlers.asm#L488), [ThorinTalks](../src/handlers.asm#L690), [GollumTalks](../src/handlers.asm#L1081), [NpcAnswersGift](../src/handlers.asm#L465) |
| the arrow, the boat, the dragon | `RandomUpTo(8)`, `RandomUpTo(100)` | [L9065_0](../src/verbs.asm#L762), [LA814](../src/handlers.asm#L922), [LA67E_5](../src/handlers.asm#L755) |
