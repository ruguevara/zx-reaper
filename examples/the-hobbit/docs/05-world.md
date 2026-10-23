# 5c. The world: places, exits, things, light

The world is 80 locations joined by exits, and 61 records for the player, the
objects and the characters. The rules are few and general: everything has a
holder and a place, weight and size limit what can be carried, entered or put
inside, a door or a river on an exit is an object with flags, and the caves
are dark unless the sword is at hand. This file describes those rules; the
records are laid out in [02-data](02-data.md) and a map of all exits is in
[07-graphics](07-graphics.md).

## Locations and exits

Each location record lists its exits as (direction, obstacle, destination)
triples ([02-data](02-data.md), F4). Directions are the command ids 1-10: N,
S, E, W, NE, NW, SE, SW, up, down. 26 locations are dark (bit 7 of the flags
clear): the trolls' cave, the goblins' caves and the 15 dark stuffy passages
of the goblin labyrinth, the deep dark lake, the elvenking's halls, dungeon and
cellar, the smooth straight passage. Only three locations limit what can be in
them: Bag End (capacity 160), the smooth straight passage (176) and location
`$2F` (254).

Exits are one-way records: the way back is a separate exit of the other
location, and some are missing on purpose (the river, the steep paths that
only go down). A location may also lead to the same place several ways (the
inside of the goblins' gate sends eight directions back to the big cavern).

### Moving ([VerbMove](../src/verbs.asm#L294), [MoveActor](../src/verbs.asm#L306), [ActorArrives](../src/verbs.asm#L356))

The ten moves share one handler, for the player and the characters alike:

1. In the dark the player cannot choose: the direction becomes random 1-10.
2. An actor inside something (a barrel, the boat) cannot walk; one held by a
   character is let go first.
3. [FindExitByDirection](../src/objects.asm#L976) finds the exit. None (or destination 0): "You
   cannot go north."; in the dark the player instead falls: the strength
   (`+5`) is halved, "But fall and hit your head.", and when it reaches 0, "But
   fall and smash your skull." and the game ends.
4. [CheckPassage](../src/verbs.asm#L434) tests the obstacle and the destination. The weight that
   moves is the actor's own weight (`+2`) plus everything it carries
   ([SumHeldWeight](../src/objects.asm#L471)).
5. [ActorArrives](../src/verbs.asm#L356): the actor's location changes, what it carries comes along
   ([MoveCarried](../src/objects.asm#L230): contents of contents too, and a carried player). For the
   player, the destination's arrival handler runs ([ArrivalHandlers](../src/world.asm#L2201)); then,
   unless it is dark, the place is described: the first time with its
   description, picture and score ([FirstVisitScores](../src/verbs.asm#L212)), later only with its
   name ([DescribeLocationShort](../src/engine.asm#L400)).

A character's move is announced only if the player sees it: "Thorin enters."
when it arrives where the player is ([AnnounceArrival](../src/engine.asm#L1248)).

### Obstacles ([CheckPassage](../src/verbs.asm#L434))

An exit's obstacle is an object id: the round green door, the trolls' rock
door, the goblins' doors, the trap doors, the magic door, the portcullis, the
spider web, the black river, the window. The obstacle lets the traveller pass
when

- its flags have bit 5 (open/active) or bit 3 (broken/dead) set: an open door
  or a broken web;
- for the player, bit 7 of its state byte is clear. Only the window of the
  goblins' dungeon has it: a character can climb through, the player cannot
  (the HELP hint there: "A window should be no obstacle to a thief with
  friends.");
- the moving weight is below the obstacle's `+2` (96 for the window, 64 for
  the goblins' back door, 160 for the web, 255 for most doors).

Then the destination must have room: unless its capacity is `$FF`, the
capacity minus the weights of the objects lying there must exceed the moving
weight. The messages are "<the obstacle> is too small for you to enter." and
"<the place> is too full for you to enter."; the first prints a wrong word
because it takes its argument from the obstacle's weight bytes (bug, observed,
F53).

### Other ways to move

| Command | Handler | Rule |
| --- | --- | --- |
| run | [VerbRun](../src/verbs.asm#L639) | a random direction 1-10, then the next direction that has an exit. Direction 10 (down) is never reached by stepping, so on the steep paths `$4B-$4D`, whose only exit is down, RUN loops for ever unless the first roll was 10 (bug, observed: the game hangs, F55) |
| follow X | [VerbFollow](../src/verbs.asm#L672) | walks through the exit that leads to X's location |
| enter, go into, go through | [L8FCD](../src/verbs.asm#L660), [WalkToExit](../src/verbs.asm#L582) | the noun is a place reached by an exit (or the obstacle on it); the exit's direction becomes the command and the walk continues as a move. The passage check here uses the destination and weight left from the previous move (inferred, F34) |
| look through | [VerbLookThrough](../src/verbs.asm#L521) | describes the place beyond an open door or window. Its "It is dark." test reads location 1 instead of the place beyond, so it never fires (bug, observed, F54) |
| climb into / out of, jump onto | handlers of the barrel, the boat... | the actor's holder changes |

### The exit that is removed ([InitNewGame](../src/engine.asm#L608), [ExamineMap](../src/handlers.asm#L882))

At the start one of five exits is zeroed in its location record (the list is
in [03-title-and-menu](03-title-and-menu.md)). The curious map holds the
answer: when Elrond examines it (`SAY TO ELROND "READ MAP"`, F40), the triple
is copied back and he says "Go east from the misty mountain to get to the
narrow place". Anyone else reading it sees "There seem to be some symbols on
it but you cannot read them.". The record of the chosen exit is kept in the
operand of an instruction ([SmcBlockedExit](../src/handlers.asm#L887), patched by [InitNewGame](../src/engine.asm#L608)).

## Objects

### Holders, places and reach

Every record has a holder (`+1`) and a list of places (`+$10`). An object
lying in a location has holder `$FF`; an object in a container or carried by
a character has that record's id as holder, and its place follows the holder
([MoveContents](../src/objects.asm#L272)). So "carried by Thorin", "in the chest" and "in the barrel
carried by the player" are all the same relation, and [WalkHolderChain](../src/objects.asm#L378)
walks it upwards.

Doors, rivers and webs have several places (the field `+0` counts them,
F11): they are seen from both sides and cannot be taken ([CheckSinglePlace](../src/verbs.asm#L1084)).

[CanReach](../src/objects.asm#L800) decides what an actor can see and touch: the object must be
present (flag bit 7) and in the same "room" as the actor, where a closed
container counts as a room of its own ([FindClosedHolder](../src/objects.asm#L847)). A thing in a
closed chest is out of reach; a player in a closed barrel reaches only what is
in the barrel.

The list of what is here ([ListObjectsHere](../src/objects.asm#L1106)) prints the objects one per line
and their contents indented below them with "In the / On the" from the
container's state byte (F33).

### Weight and size (F18, F67)

| Action | Compares | With |
| --- | --- | --- |
| take, carry ([CheckCanCarry](../src/verbs.asm#L128)) | the object's size (`+3`) plus the sizes inside it | the actor's carrying capacity (`+3`), and then what is left after everything the actor already carries |
| give ([GiveObject](../src/verbs.asm#L1300)) | the object's size | the recipient's capacity minus what it carries |
| put in, drop in ([PutObjectIn](../src/verbs.asm#L1112)) | the object's weight (`+2`) | the container's `+2` minus the weights already inside; an exact fit is refused |
| moving ([CheckPassage](../src/verbs.asm#L434)) | the actor's weight plus what it carries | the obstacle's `+2`, the destination's free capacity |

The player can carry a total size of 64. The sums are computed by
[SumHeldRecords](../src/objects.asm#L511), which caps a total at `$FF` when it passes 127. Two
edge bugs hide here, neither reachable by the player: [CheckCanCarry](../src/verbs.asm#L128) treats
128 or more of room left as negative, so an actor with a capacity of 132 or
more is "carrying too much" for a small object (observed with a poked
capacity, F67), and the cap misses some overflows (inferred, F68).

### Open, locked, broken, liquid

The flag byte (`+7`) carries the state:

| Bit | Meaning | Used by |
| --- | --- | --- |
| 7 | present, visible | reach, lists; cleared for the player while wearing the ring |
| 6 | a character | fights, captures, the NPC loop |
| 5 | open (containers, doors), alive | [OpenObject](../src/verbs.asm#L854), [CloseObject](../src/verbs.asm#L884), obstacles, reach into containers |
| 3 | broken or dead | [StrikeObject](../src/verbs.asm#L1211), [KillCharacter](../src/engine.asm#L567), [MarkBrokenOrDead](../src/objects.asm#L1552) renames it "broken ..." or "dead ..." |
| 1 | liquid | water, wine: they evaporate when dropped or when their container is emptied ([VerbDrop](../src/verbs.asm#L77), [EmptyFirstObject](../src/objects.asm#L591)) |
| 0 | locked | lock / unlock with a key ([SmcSetOrRes](../src/verbs.asm#L1412) writes a `SET` or `RES` opcode) |

[PrintStateIX](../src/objects.asm#L1523) prints these states with the words of [IdList](../src/handlers.asm#L67):
unlocked/locked, empty/full, off/on, closed/open, dead/alive, broken (F17).

Breaking: `STRIKE X WITH Y` breaks X when a random spread plus the weapon's
and the actor's strength reach X's defence (`+6`); a broken container spills
its contents. The weapon is then tested the same way but with its own
defence on the wrong side, so a strong weapon breaks on a weak target:
striking the barrel with the sword breaks the sword (bug, observed, F46).

### Light and darkness ([CheckDark](../src/engine.asm#L219))

Only the player can be in the dark (characters always see). The player is in
the dark inside a closed holder, or in a location whose lit bit is clear,
unless the short strong sword (object `$0E`) is within reach with its flags
bits 4 and 2 set and bit 3 clear (verified, F45). There is no other light
source: the torches of the goblins' cavern and the elvenking's hall are fixed
objects. A broken sword (bit 3) gives no light (F46).

In the dark:

- commands that need light are refused with "I see nothing here." unless the
  objects named are held ([DispatchCommand](../src/engine.asm#L87)); "It is dark." follows a
  command that leaves the player in the dark;
- moves go in a random direction, and a wall costs half the strength;
- nothing is described on arrival, so a dark location gives no first-visit
  score until it is entered with the sword;
- the pictures of dark places are not drawn ([StartPicture](../src/drawing.asm#L697));
- what characters do is not printed; the first one within reach gives "You
  hear a noise." once per turn ([RunNpcScripts](../src/engine.asm#L765), F32).

## Special places and objects

Most of the world runs on the general rules; a few objects have handlers of
their own in their verb tables ([`handlers.asm`](../src/handlers.asm)):

| Where | What happens | Code |
| --- | --- | --- |
| Bag End | the round green door: Gandalf opens it at the start | Gandalf's script |
| trolls' clearing | the trolls threaten, eat the player who stays, and turn to stone at dawn | [TrollsTalk](../src/handlers.asm#L1156), [LA94E](../src/handlers.asm#L1100), [LA94E_0](../src/handlers.asm#L1115) |
| goblins' dungeon | the crack can only be opened from the passage behind it, by a goblin | [OpenCrack](../src/handlers.asm#L254) |
| the black river (west and east bank) | throwing the rope across to the boat on the far bank: it lands in the boat when `RandomUpTo(100)` is below 50 (about two times in three, F74), else it falls short or slides out; pulling the rope brings the boat across | [LA814](../src/handlers.asm#L922), [LA814_4](../src/handlers.asm#L963) |
| forest river, long lake | a player not in the barrel is swept away; the barrel floats from the cellar to the long lake | [ArriveForestRiver](../src/world.asm#L2268), [LA5E2_0](../src/handlers.asm#L629) |
| magic door, side door | open and close on timers; the side door of the Lonely Mountain is present (flag bit 7) only one turn in five | [05-time](05-time.md) |
| the spider web | breaking it starts the spiders | [LA377](../src/handlers.asm#L262) |
| the ring | wearing it makes the wearer invisible and weaker for 2-10 turns | [LA377_0](../src/handlers.asm#L271), [LA377_1](../src/handlers.asm#L286) |
