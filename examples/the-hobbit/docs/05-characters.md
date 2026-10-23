# 5d. Characters

The 17 other characters are run by a small script interpreter: each has a
current script, a table of scripts to switch to when something happens to it
(it is attacked, given something, captured), and a willingness to take
orders. They use exactly the same commands as the player, through the same
dispatcher and the same checks, which is why "Thorin takes the rope" needs no
code of its own. The game's own name for this was ANIMACTION.

## Who is who

| Character | Id | Starts at | NPC record | Obedience | What its scripts do |
| --- | --- | --- | --- | --- | --- |
| Gandalf | `$3E` | Bag End | [NpcStates](../src/world.asm#L2840) | 5 | gives the curious map to the player and opens the round green door, then wanders (run), takes, drops and gives things, cheers ("Hurry up", "You are doing a great job") |
| Thorin | `$3F` | Bag End | [NpcThorin](../src/world.asm#L2845) | 6 | follows the player; takes the small curious key and says "This was Thrain's key"; asks "Where's the thief ?" when the player wears the ring; sits down and sings about gold |
| wood elf | `$40` | levelled elvish clearing | [NpcElf](../src/world.asm#L2850) | 1 | captures anyone it can (prison: the dark dungeon), runs about |
| vicious warg | `$43` | treeless opening | [NpcWarg](../src/world.asm#L2855) | 0 | attacks; else follows and howls; else runs |
| butler | `$42` | elvenking's cellar (asleep) | [NpcButler](../src/world.asm#L2860) | 1 | woken when the player reaches Beorn's house; unlocks, opens, closes and locks the red door; drinks the wine, throws barrels through the trap door, captures |
| Elrond | `$41` | Rivendell | [NpcElrond](../src/world.asm#L2865) | 5 | says "Hello"; gives the lunch; reads the map when asked |
| Gollum | `$44` | deep dark lake | [NpcGollum](../src/world.asm#L2870) | 3 | asks his riddle and strangles a player who does not answer; mutters about his pockets; takes and wears the ring |
| Bard | `$46` | Lake-town (asleep) | [NpcBard](../src/world.asm#L2875) | 3 | woken at the cellar; carries out an order by rewriting his own script; shoots |
| dragon | `$3C` | lower halls (asleep) | [NpcDragon](../src/world.asm#L2880) | 0 | woken at the cellar; meets the player at the mountain and burns him; once the treasure is gone, may descend from the sky and kill |
| hideous troll, vicious troll | `$47`, `$48` | trolls' clearing | [NpcTroll1](../src/world.asm#L2885), [NpcTroll2](../src/world.asm#L2890) | 1 | talk about cooking the player, eat a player who stays, turn to stone at dawn four turns later |
| six goblins | `$3D`, `$45`, `$49-$4C` | the goblin caves | [NpcGoblinA](../src/world.asm#L2895)... | 0 | open the crack, wander, attack, capture (prison: the goblins' dungeon); come back after death |

The character records (strength, defence, flags, location) are ordinary
object records ([02-data](02-data.md)); the NPC record adds the script state.
"Asleep" means the NPC record's id is 0: the record is skipped until an
arrival handler writes the id ([ArriveBeornsHouse](../src/world.asm#L2219), [ArriveCellar](../src/world.asm#L2242)).
All the scripts, decoded, are listed at the end of this file; their bytes are
in [`src/world.asm`](../src/world.asm) from [GoblinABehaviours](../src/world.asm#L2332) on.

## The turn of the characters ([RunNpcScripts](../src/engine.asm#L765))

After every command the player carries out, [RunNpcScripts](../src/engine.asm#L765) goes through
the 17 records in order (Gandalf first, the goblins last). For each living
one:

1. [Subject](../src/messages.asm#L1072) becomes the character, [ActorRecord](../src/world.asm#L74) its record.
2. Visibility: [MessagesVisible](../src/world.asm#L47) is 1 only when the player can reach the
   character (same place, not shut in) and can see. In the dark, the first
   character in reach prints "You hear a noise." once for the turn and the
   rest stays silent (F32). Everything a character does goes through the same
   printing routines, so this one flag decides whether the player sees it.
3. A character held by something ([NpcHeld](../src/objects.asm#L13)) acts only when the holder is a
   character or dead; inside an open container it climbs out; in a closed one
   it does nothing (F58).
4. If the character owns an order (below), the order is tried first.
5. Otherwise it runs script commands until one **succeeds** or **six fail**
   ([NpcFailures](../src/engine.asm#L675)). A failed command moves on to its alternative address or
   the next command; the next turn starts where this one stopped.

A command a character runs ([RunActorCommand](../src/engine.asm#L1058)) goes through
[TestActorCommand](../src/parser.asm#L1403) (the noun matcher, with the objects already chosen) and
the test pass of [DispatchCommand](../src/engine.asm#L87); a refusal is a failure, and nothing is
printed for it. A success is echoed like the player's commands ("Thorin takes
the rope.", "Someone opens the door." when only the door is in sight) and then
performed. A character that walks into the player's location is announced:
"Gandalf enters." ([AnnounceArrival](../src/engine.asm#L1248)).

## The script language (verified by the script pointers changing, F6, F52)

A script is a row of commands in `$C82D-$CA83`. The first byte of a command:

| Bits | Meaning |
| --- | --- |
| 0-3 | the op |
| 4 | an alternative address (2 bytes) follows the command: where to go when it fails |
| 5 | erase: the command byte is set to 0 after a success (one-shot; used once, by Thorin) |
| 6 | not interrupted: a stored order does not replace this command |

| Op | Bytes | Meaning | Routine |
| --- | --- | --- | --- |
| 0, 2 | 4 | command id, first object, second object (`$FF` none): a command as if typed | [RunScriptCommand](../src/engine.asm#L947) |
| 1, 3 | 4 | a routine address and a pad byte; the routine is called twice like a verb handler and must agree in the test pass | [RunScriptCommand](../src/engine.asm#L947) |
| 4 | 2 | a command id alone; `$FF` = do nothing this turn | [RunScriptVerb](../src/engine.asm#L995) |
| `$C` | 2 | switch to the behaviour table entry with this id | [SwitchNpcScript](../src/engine.asm#L1209) |
| `$E` | 3 | jump to an address | [RunNpcScripts](../src/engine.asm#L765) |
| `$F` | 2 | jump to a random default entry, 0 to min(argument, record `+1`) | [ChooseRandomScript](../src/engine.asm#L1141) |
| 5-9, `$B`, `$D` | 1 | end: back to entry 0 of the behaviour table, turn over | [SelectScript](../src/engine.asm#L1150) |

Ops C, E and F cost no time; ops 0-4 are attempts. A command of op 4 with a
verb that takes objects (`attack`, `capture`, `take`) has no named object, so
the noun matcher accepts the first object in reach that the command allows:
"attack anyone here", "take anything" (inferred from [TestActorCommand](../src/parser.asm#L1403)).

A small example, the vicious warg ([WargBehaviours](../src/world.asm#L2511)):

```
C928  attack (anyone)       | else C92F       $14 $0F + address
C92C  jump C928
C92F  follow (anyone)       | else C93A
C933  call WargHowls                          "The vicious warg run around you and howls."
C937  jump C928
C93A  run                   | else C941
C93E  jump C928
C941  nothing this turn
C943  jump C928
```

### Behaviour tables and events ([NotifyCharacter](../src/engine.asm#L190), [SwitchNpcScript](../src/engine.asm#L1209))

The behaviour table of a record holds the scripts it can switch to: entries
with id 0 are its default scripts (entry 0 is where an "end" op returns, op
`$F` picks one at random), and entries with a command id are events. When a
command is performed whose first or second object is a living character,
[DispatchCommand](../src/engine.asm#L87) tells that character ([NotifyCharacter](../src/engine.asm#L190)) and, if its
table has an entry for the command id, it switches to that script (F51):

| Event | Who reacts | Script |
| --- | --- | --- |
| 15, attacked | Gandalf, Thorin and the trolls attack back, else follow, else run (`$CA5E`, not interrupted by orders); the Bard shoots; the elf, the butler and the goblins capture; Gollum puts on the ring and runs; the dragon burns; Elrond attacks | |
| 29, given something | Gandalf, Thorin, the elf, the butler, Elrond | [NpcAnswersGift](../src/handlers.asm#L465): "Thank you" or "What do you expect me to do with this ?" |
| 48, captured | Gandalf: tries to go through, then runs | |

## Orders: SAY TO

The parser stores the orders of `SAY TO X "..."` in the 8 order slots and
[TalkToCharacter](../src/verbs.asm#L730) decides how many of them X accepts: a random number from
0 to its obedience, "No" for 0 ([05-parser](05-parser.md), F44). In X's turn
([RunNpcScripts](../src/engine.asm#L765)) an owned order is taken before the script, unless the
script's current command has bit 6:

1. [RunStoredOrder](../src/parser.asm#L2410) frees the slot and parses the stored phrase record as if
   it had been typed ([InputFromOrder](../src/world.asm#L96) = 1), then runs its test pass;
2. if it parses and is allowed, the character performs it instead of its
   script command, and the script does not move; otherwise all of the
   character's slots are freed and the script runs as usual.

So `SAY TO THORIN "GO EAST THEN TAKE THE ROPE"` gives Thorin two orders that he
carries out on his next two turns, if he accepts both (inferred). Two bugs come from the
slot handling, both observed by the bug hunt:

- a ninth order is dropped silently, after writing `$FF` one byte past the
  slots (F72);
- orders whose SAY TO was refused (the character is not here) stay pending,
  and the next character the player talks to carries out the oldest of them:
  after `SAY TO ELROND "OPEN CHEST"` in Bag End, `SAY TO THORIN "WAIT"` makes
  Thorin open the chest (F73).

**The Bard** is told what to do differently. His script command at `$C9E2`
([BardCommandOp](../src/world.asm#L2636)) is an ordinary op 2 command with bit 6. Its handler
[LA814_8](../src/handlers.asm#L990) takes the Bard's stored order and, when it is allowed, writes the
order's command and objects into those three bytes, so the Bard repeats the
order every turn until told otherwise. Because this changes code-area bytes
outside the saved state, SAVE copies them into the variables block and LOAD
copies them back ([SavedScriptBytes](../src/world.asm#L11), [CopyScriptBytes](../src/system.asm#L535)).

## Fights ([VerbAttack](../src/verbs.asm#L949))

`KILL X WITH Y` (also hit, slash, slice, capture... all synonyms of attack) is
command 15:

1. Refused when attacker and victim share a "side" bit (bits 4-6 of the state
   byte): friends do not fight ([CheckAttackAllowed](../src/verbs.asm#L905)). When the player
   attacks, the victim's bit 4 is cleared first.
2. The weapon must be a single-place object; bare hands are named "fist".
3. Attack = the attacker's strength (`+5`) plus the weapon's (`+5`), capped at
   255; defence = the victim's `+6`. Both get a random spread from
   [RollStrength](../src/verbs.asm#L1038) (+0 to +10 mostly; in about 3% of rolls the spread is
   negative and the roll comes out 0, so a defence can collapse to 0; a
   strength of 0 can wrap to 247-255: bug, observed, F9).
4. Defence >= attack: "But the effort is wasted. His defense is too strong."
5. Attack > defence + 16: "With one well placed blow you cleave his skull."
   and the victim dies ([KillCharacter](../src/engine.asm#L567)); if the victim is the player, the
   game ends.
6. Otherwise the damage *d* = attack - defence (1-16) picks one of the 16
   [WoundMessages](../src/verbs.asm#L1057) ("You swing feebly at ... but miss by a wide margin" for
   1 up to "... almost kills ..." for 15), and the victim loses strength.

Three bugs live here (observed by the bug hunt):

- *d* = 16 reads the word after the 16-entry table, `$2ADD`, an address in
  the ROM, and prints its bytes as a message: "Cut seclosed." (seen in 9 of 100
  bare-handed attacks on the elf, F56);
- the strength loss is computed with `RRCA`, which rotates the low bit into
  bit 7: an odd *d* takes 129 or more off a strong victim's attack and
  nothing off a weak one's (F65);
- the message for *d* = 15 says "Your violent attack almost kills you." to
  the attacker (F66, inferred intent).

Shooting ([L9065_0](../src/verbs.asm#L762), `SHOOT X`) needs the bow: the arrow misses the dragon
unless the Bard shoots, and otherwise hits 2 times in 3 (a random number 0-8
of 3 or more); a hit kills a character at once.

### Death and capture

[KillCharacter](../src/engine.asm#L567) marks the victim dead (flag bit 3), drops what it carried
where it stands, makes its NPC record dormant, renames it "dead ..." and frees
its orders. Goblins do not stay dead: the attack entry of each goblin's verb
table is followed by [RespawnKilledGoblin](../src/handlers.asm#L373), which brings the goblin back to
its home location ([RecordTable](../src/handlers.asm#L419)) with "<goblin> falls down a hole and
vanishes." (F39). The "Another goblin enters." that may follow compares the
player's location with a register left over from the dispatcher, so it
appears at random (inferred).

[VerbCapture](../src/handlers.asm#L315) (command 48) moves the captive to a prison: the dark dungeon
for the wood elf and the butler, the goblins' dungeon for everyone else. A
captured player is described the new place ("You are in a goblins dungeon").

## Particular characters

- **Gollum** asks one of two riddles, chosen at the start of the game, when
  he is with the player and the player is visible ([GollumAsksRiddle](../src/handlers.asm#L1021)). The
  answer has to be given as an order in the very next command, `SAY TO GOLLUM
  "NIGHT"` for the riddle of the dark (DARK is refused) or `SAY TO GOLLUM
  "MAN"` for the riddle of the animal: on his next turn [LA8F6](../src/handlers.asm#L1044) looks for
  the answer word anywhere in the stored order. Anything else: "Someone
  strangles you from behind." and the game ends (observed, F76).
- **The trolls** ([TrollBehaviours](../src/world.asm#L2694)): when the player is in their clearing
  they talk ([TrollsTalk](../src/handlers.asm#L1156)). On each of the next four turns [LA94E](../src/handlers.asm#L1100) makes a
  troll eat a player who is still there: the command `eat` with the player as
  object, echoed as "The hideous troll eats you." through [RefuseCommand](../src/objects.asm#L1070),
  then the player's own verb table entry for `eat` ends the game. The troll's
  strength (160) plus the 10 a meal gives passes 127, so the same line adds
  "His foul gluttony has killed the hideous troll." (observed, F81). After the
  four turns, [LA94E_0](../src/handlers.asm#L1115) is the dawn: both trolls turn to stone, the clearing
  gets a new description and a day picture (F77).
- **The dragon** ([DragonBehaviours](../src/world.asm#L2596)): woken when the player first reaches
  the elvenking's cellar. While the treasure lies in the lower halls he comes
  to the player at the front gate, the lonely mountain or the halls
  ([LA67E_0](../src/handlers.asm#L719)), says "Well thief your cunning has failed you this time.
  Prepare to die" (or, to an invisible player, "I may not be able to see you
  thief but I can still burn you", [LA67E_3](../src/handlers.asm#L742)) and then burns. Once the
  treasure has gone, on every turn the player is in a lit place he is "In the
  distance ... the shape of a monstrous dragon flying after you", or, with a
  random number 0-100 of 80 or more (less than one turn in five, F74), "The
  dragon descends and ... burns you to a crisp." ([LA67E_5](../src/handlers.asm#L755)). The Bard's
  arrow is the only thing that kills him.
- **Elrond** reads the map when asked and gives the lunch; the map tells where
  the exit removed at the start lies ([05-world](05-world.md), F40).
- **Gandalf and Thorin** start in Bag End; Thorin follows the player all the
  time, the warg when it cannot attack, the others only when attacked. Killing Thorin breaks the small
  curious key ([ThorinDeathBreaksKey](../src/handlers.asm#L802)). One of his remarks, "Get us out of
  this one, thief !", can never be printed (F42).

## All scripts

Decoded from the bytes of the NPC records and scripts (each shared script is
listed once, under its first owner). `do(x, y)` is a command with objects,
a bare verb is a command without objects (any object in reach that fits),
`call` an op 1/3 routine, `| else` the alternative address taken on failure,
`[N]` bit 6 (orders wait), `[E]` bit 5 (erased after use). "max" is the
record's `+1`, "behaviours" the table: entry id and script.

<details><summary>17 records, 148 commands</summary>

```text
NPC gandalf (NpcStates, Gandalf) max 7 obedience 5 script ScriptC8BA table GandalfBehaviours
  behaviours: 0:ScriptC8C2, 0:ScriptC8D0, 0:ScriptC8D4, 0:ScriptC8DA, 0:ScriptC8DE, 29:ScriptCA7F, 48:ScriptCA73, 15:ScriptCA5E
  C8BA ScriptC8BA   give(curious map, player)
  C8BE              open(round green door, -)
  C8C2 ScriptC8C2   run
  C8C4              take | else ScriptC8D0
  C8C8              call LA4F5
  C8CC              close
  C8CE              give
  C8D0 ScriptC8D0   run
  C8D2              drop
  C8D4 ScriptC8D4   run
  C8D6              call GandalfCheers
  C8DA ScriptC8DA   run
  C8DC              give
  C8DE ScriptC8DE   open
  C8E0              random entry 0..4
  CA7F ScriptCA7F   call NpcAnswersGift
  CA83              end (back to entry 0)
  CA73 ScriptCA73   go | else ScriptCA7A
  CA77              run
  CA79              end (back to entry 0)
  CA5E ScriptCA5E   attack | else ScriptCA6B [N]
  CA62              attack | else ScriptCA72 [N]
  CA66              run [N]
  CA68              jump ScriptCA5E
  CA7A ScriptCA7A   nothing
  CA7C              jump ScriptCA73
  CA6B ScriptCA6B   follow | else ScriptCA72 [N]
  CA6F              jump ScriptCA5E
  CA72 ScriptCA72   end (back to entry 0)
NPC thorin (NpcThorin) max 2 obedience 6 script ScriptC8EC table ThorinBehaviours
  behaviours: 0:ScriptC8EC, 29:ScriptCA7F, 15:ScriptCA5E
  C8EC ScriptC8EC   follow(player, -) | else ScriptC8F5
  C8F2              jump ScriptC8EC
  C8F5 ScriptC8F5   take(small curious key, -) | else ScriptC8FF
  C8FB              call LA51C [E]
  C8FF ScriptC8FF   call ThorinMissesThief | else ScriptC90C
  C905              nothing
  C907              run
  C909              jump ScriptC8EC
  C90C ScriptC90C   call ThorinTalks
  C910              jump ScriptC8EC
NPC wood elf (NpcElf) max 2 obedience 1 script ScriptC91D table ElfBehaviours
  behaviours: 0:ScriptC91D, 15:ScriptC91D, 29:ScriptCA7F
  C91D ScriptC91D   capture
  C91F              run
  C921              jump ScriptC91D
NPC vicious warg (NpcWarg) max 0 obedience 0 script ScriptC928 table WargBehaviours
  behaviours: 0:ScriptC928
  C928 ScriptC928   attack | else ScriptC92F
  C92C              jump ScriptC928
  C92F ScriptC92F   follow | else ScriptC93A
  C933              call WargHowls
  C937              jump ScriptC928
  C93A ScriptC93A   run | else ScriptC941
  C93E              jump ScriptC928
  C941 ScriptC941   nothing
  C943              jump ScriptC928
NPC dormant (NpcButler) max 2 obedience 1 script ScriptC950 table ButlerBehaviours
  behaviours: 0:ScriptC950, 15:ScriptC960, 29:ScriptCA7F
  C950 ScriptC950   unlock(red door, red key)
  C954              open(red door, -)
  C958              close(red door, -)
  C95C              lock(red door, red key)
  C960 ScriptC960   capture | else ScriptC967
  C964              jump ScriptC960
  C967 ScriptC967   open(barrel, -)
  C96B              drink(wine, -)
  C96F              capture
  C971              close(barrel, -)
  C975              open(large trap door, -)
  C979              capture
  C97B              take(barrel, -)
  C97F              throw(barrel, large trap door)
  C983              capture
  C985              close(large trap door, -)
  C989              capture | else ScriptC950
  C98D              jump ScriptC950
NPC elrond (NpcElrond) max 2 obedience 5 script ScriptC99A table ElrondBehaviours
  behaviours: 0:ScriptC9A0, 15:ScriptC9AA, 29:ScriptCA7F
  C99A ScriptC99A   call ElrondGreets | else ScriptC9A4
  C9A0 ScriptC9A0   call LA9E5
  C9A4 ScriptC9A4   nothing
  C9A6              nothing | else ScriptC99A
  C9AA ScriptC9AA   attack | else ScriptC99A
  C9AE              jump ScriptC9AA
NPC gollum (NpcGollum) max 1 obedience 3 script ScriptC9F7 table GollumBehaviours
  behaviours: 0:ScriptC9F7, 15:ScriptCA2B
  C9F7 ScriptC9F7   call GollumAsksRiddle | else ScriptCA10
  C9FD              call LA8F6 [N]
  CA01              drop(valuable golden ring, -)
  CA05              north | else ScriptCA21
  CA09 ScriptCA09   take(valuable golden ring, -)
  CA0D              jump ScriptC9F7
  CA2B ScriptCA2B   wear(valuable golden ring, -)
  CA2F              run
  CA31              jump ScriptC9F7
  CA10 ScriptCA10   north | else ScriptCA26
  CA14 ScriptCA14   call GollumTalks | else ScriptC9F7
  CA1A              take(valuable golden ring, -)
  CA1E              jump ScriptC9F7
  CA21 ScriptCA21   southwest
  CA23              jump ScriptCA09
  CA26 ScriptCA26   southwest
  CA28              jump ScriptCA14
NPC dormant (NpcBard) max 1 obedience 3 script ScriptC9DE table BardBehaviours
  behaviours: 0:ScriptC9DE, 15:ScriptC9E9
  C9DE ScriptC9DE   call LA814_8 [N]
  C9E2 BardCommandOp take(wooden chest, -) [N]
  C9E6              jump ScriptC9DE
  C9E9 ScriptC9E9   shoot | else ScriptCA5E [N]
  C9ED              jump ScriptC9E9
NPC dormant (NpcDragon) max 1 obedience 0 script ScriptC9B8 table DragonBehaviours
  behaviours: 0:ScriptC9B8, 15:ScriptC9CD
  C9B8 ScriptC9B8   call LA67E_5 | else ScriptC9C1
  C9BE              jump ScriptC9B8
  C9CD ScriptC9CD   burn
  C9CF              jump ScriptC9B8
  C9C1 ScriptC9C1   call LA67E_0 | else ScriptC9D2
  C9C7              call LA67E_3 | else ScriptC9D2
  C9D2 ScriptC9D2   run
  C9D4              jump ScriptC9B8
NPC hideous troll (NpcTroll1) max 1 obedience 1 script ScriptCA3B table TrollBehaviours
  behaviours: 0:ScriptCA41, 15:ScriptCA5E
  CA3B ScriptCA3B   call TrollsTalk | else ScriptCA3B
  CA41 ScriptCA41   call LA94E
  CA45              nothing
  CA47              call LA94E
  CA4B              nothing
  CA4D              call LA94E
  CA51              nothing
  CA53              call LA94E
  CA57              call LA94E_0
  CA5B              jump ScriptCA41
NPC vicious troll (NpcTroll2) max 1 obedience 1 script ScriptCA3B table TrollBehaviours
  behaviours: 0:ScriptCA41, 15:ScriptCA5E
NPC nasty goblin (NpcGoblinA) max 1 obedience 0 script ScriptC842 table GoblinABehaviours
  behaviours: 0:ScriptC842, 15:ScriptC89E
  C842 ScriptC842   open(small insignificant crack, -)
  C846 ScriptC846   capture | else ScriptC84D
  C84A              jump ScriptC846
  C89E ScriptC89E   capture
  C8A0              end (back to entry 0)
  C84D ScriptC84D   up
  C84F ScriptC84F   capture | else ScriptC856
  C853              jump ScriptC84F
  C856 ScriptC856   down
  C858 ScriptC858   capture | else ScriptC85F
  C85C              jump ScriptC858
  C85F ScriptC85F   close(small insignificant crack, -)
  C863              south
  C865 ScriptC865   capture | else ScriptC86C
  C869              jump ScriptC865
  C86C ScriptC86C   north
  C86E              jump ScriptC842
NPC hideous goblin (NpcGoblinB) max 1 obedience 0 script ScriptC842 table GoblinABehaviours
  behaviours: 0:ScriptC842, 15:ScriptC89E
NPC vicious goblin (NpcGoblinC) max 1 obedience 0 script ScriptC871 table GoblinBBehaviours
  behaviours: 0:ScriptC871, 15:ScriptC89E
  C871 ScriptC871   northwest
  C873 ScriptC873   capture | else ScriptC87A
  C877              jump ScriptC873
  C87A ScriptC87A   north
  C87C ScriptC87C   capture | else ScriptC883
  C880              jump ScriptC87C
  C883 ScriptC883   southwest
  C885 ScriptC885   capture | else ScriptC88C
  C889              jump ScriptC885
  C88C ScriptC88C   up
  C88E ScriptC88E   capture | else ScriptC871
  C892              jump ScriptC88E
NPC horrible goblin (NpcGoblinD) max 1 obedience 0 script ScriptC895 table GoblinCBehaviours
  behaviours: 0:ScriptC895, 15:ScriptC89E
  C895 ScriptC895   run
  C897              attack
  C899              capture
  C89B              jump ScriptC895
NPC mean goblin (NpcGoblinE) max 1 obedience 0 script ScriptC895 table GoblinCBehaviours
  behaviours: 0:ScriptC895, 15:ScriptC89E
NPC disgusting goblin (NpcGoblinF) max 1 obedience 0 script ScriptC895 table GoblinCBehaviours
  behaviours: 0:ScriptC895, 15:ScriptC89E
```

</details>
