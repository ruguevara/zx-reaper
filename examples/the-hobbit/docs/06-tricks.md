# 6. Tricks, quirks and bugs

The program is 40K of tightly packed data and code from 1982. This file
collects the techniques that are not obvious from a single routine, the code
that never runs, and the bugs, with their evidence. Finding numbers refer to
[`re/findings.md`](../re/findings.md).

## Design tricks

### A command is run twice; printing means "no"

Every command, the player's and the characters', goes through
[DispatchCommand](../src/engine.asm#L87) twice: a test pass with [ActionPerform](../src/world.asm#L33) = 0 and a real
pass with 1. A handler is written once, as if it always acted:

```
VerbTake:  CALL CheckObject1Held     ; already held?
           LD HL,MsgAlreadyCarrying
           JP C,PrintMessage         ; refusal: just say it
           CALL CheckCanCarry        ; may print "too heavy" and drop out
           ...
           CALL CommitOrAbort        ; test pass: stop here, "allowed"
           LD (IX+$01),A             ; real pass: the object is taken
```

In the test pass the printer is silenced ([OutputEnabled](../src/screen.asm#L11)) and any message
it is asked to print clears [ActionAllowed](../src/world.asm#L35) ([PrintMessage](../src/printer.asm#L112)). Reaching
[CommitOrAbort](../src/objects.asm#L569) means the handler found nothing to object to; it sets
ActionAllowed and drops its caller's return address, so nothing is changed.
The same handler is thus the check, the refusal message and the action. The
noun matcher uses the test pass to choose among objects ("UNLOCK DOOR" picks
the lockable door), and the characters' scripts use it to decide whether a
command fails (F16).

### One path for the player and everyone else

A character's command is the same 3 bytes as a parsed one ([CommandId](../src/messages.asm#L1064),
[FirstObject](../src/messages.asm#L1067), [SecondObject](../src/messages.asm#L1070)) with another [Subject](../src/messages.asm#L1072). The handlers do
not care who acts; [PrintCommandSentence](../src/keys.asm#L570) turns the command back into
English ("Thorin takes the rope."), and the message printer adds the verb
endings and picks "you are" or "Gandalf is" from the subject. "Someone" is
the subject printed when only the object of a command is in view.

### Return-address tricks

Several helpers decide for their caller by removing its return address:
[CommitOrAbort](../src/objects.asm#L569), [AbortUnlessPerform](../src/engine.asm#L663), [RequireHeld](../src/verbs.asm#L59),
[CheckCanCarry](../src/verbs.asm#L128), [CheckAttackAllowed](../src/verbs.asm#L905) end the calling handler at once.
[MatchCommand](../src/parser.asm#L1560) drops two return addresses to jump from deep inside the
noun matcher straight to the end of the turn (`SING`). The message printer
takes its arguments (names, words) from the stack *under* its own return
address, and [PushWordsBefore](../src/parser.asm#L2248) / [PushWordsAfter](../src/parser.asm#L2226) build such argument
lists with `EX (SP),HL` (F15). The flood fill keeps its seeds on the machine
stack ([FloodFill](../src/drawing.asm#L237)).

### Self-modifying code and data

| Where | What is written | By |
| --- | --- | --- |
| [MsgSubjIsIn](../src/messages.asm#L357) second item | the preposition of the location ("You are **on** ...") or an empty word | [DescribeLocation](../src/engine.asm#L282), [VerbLook](../src/verbs.asm#L15) |
| operand at [SmcBlockedExit](../src/handlers.asm#L887) (`$A7D1`) | the record of the exit removed this game | [InitNewGame](../src/engine.asm#L608) |
| opcode at [SmcSetOrRes](../src/verbs.asm#L1412)+3 | `SET 0` or `RES 0`: lock or unlock | [L9404_6](../src/verbs.asm#L1405) |
| JR opcodes at `$7E92`, `$7EA1` | `JR Z` or `JR NZ`: which command words go before the noun | [PushWordsBefore](../src/parser.asm#L2248) (F15) |
| displacement at `$9F42` | which exit field is compared (obstacle or destination) | [FindExitByField](../src/objects.asm#L1026) (F30) |
| the Bard's script command at `$C9E2` | the command he was ordered to do | [LA814_8](../src/handlers.asm#L990) |
| a script command byte | 0 after use, for commands with the erase bit (Thorin's line) | [RunScriptCommand](../src/engine.asm#L947) |
| picture 5 header, location 5 description | day colours and "a clearing with two stone trolls" | [LA94E_0](../src/handlers.asm#L1115) (F77) |

The last two are why the save copies three script bytes ([CopyScriptBytes](../src/system.asm#L535))
and why the restart zeroes two bytes of picture data: they are state kept
outside the state blocks. The blocked-exit operand is state too, and it is
not saved (F84, below).

### Sharing bytes

- The dictionary serves the parser (typed words) and the printer (message
  words, names of everything) at once; only class 0 words of group 2 are
  print-only.
- Messages end by jumping into other messages (control code 2) or call them
  (code 11), so common tails ("... Time passes...") are stored once.
- Two pictures are prefixes of the next one in memory and run on into it
  ([05-pictures](05-pictures.md)).
- The table of blocked exits starts one record early, inside the table of
  random events ([BlockedExitsBase](../src/world.asm#L2288)), so that the selection loop can add
  first and test later; that record is never used.
- [PicVar2](../src/drawing.asm#L743) and [PicVar3](../src/drawing.asm#L745), two bytes at the end of the picture code, are
  used only by the order parser ([BeginOrderPass](../src/system.asm#L173)) to keep a word class and
  a count across its second pass.

### The random generator reads everything

[RandomSigned](../src/objects.asm#L424) mixes its seed with two bytes read through a pointer that
moves one page per call over the whole 64K: ROM, screen, code, stack. The
numbers therefore depend on the screen contents and on the code addresses;
the relocated build of the shift test produced other numbers until it was
fed the original's (F63).

### Small touches

- After drinking the wine the story window prints every "s" as "sh" for five
  turns ([PrintChar](../src/screen.asm#L48), [LispFlag](../src/world.asm#L43), timer 7).
- The "@" key repeats the last line without retyping or reparsing it
  ([L6E7A](../src/keys.asm#L65), F37).
- An idle player gets an automatic WAIT after about 23 s (F36).
- A verb without a command record still works: "You sing. Time passes..."
  (F38).

## Code that never ran

85% of the code instructions ran in the six input scripts (5862 of 6922;
`tools/zxq.py unexec re/maps/*.map` lists the rest). The rest is mostly
handlers of situations the scripts did not reach (the boat, the riddle until
it was run by hand for this article, the side door, the magic door, locking).
Code that cannot run at all:

| Code | Why | Status |
| --- | --- | --- |
| the "Get us out of this one, thief !" branch of [ThorinTalks](../src/handlers.asm#L690) | `JP Z` after a `CP 3` that has already sent every value of 3 and up away | inferred, F42 |
| [L738D](../src/printer.asm#L301), message control code 3 | no message uses code 3 | inferred |
| [LA1AE](../src/objects.asm#L1569) | no reference | inferred |
| the not-a-special-word exit of [DispatchSpecialWord](../src/system.asm#L13) | every class 9 word is in its table | inferred |
| message `$ADDA` | a lone `$14`, no reference | inferred |
| `$CB43-$CBFF`, `$F35B-$F3FF` | zero bytes, never referenced | verified (no reference) |

## Bugs

| Bug | Effect | Status |
| --- | --- | --- |
| [RollStrength](../src/verbs.asm#L1038) underflow | a negative spread (3% of rolls) makes an attack or defence 0; a strength of 0 can wrap to 247-255 | observed, F9 |
| [VerbAttack](../src/verbs.asm#L949) damage 16 | indexes past [WoundMessages](../src/verbs.asm#L1057): prints "Cut seclosed." from ROM bytes | observed, F56 |
| [VerbAttack](../src/verbs.asm#L949) strength loss | `RRCA` instead of a shift: odd damage takes 129+ off a strong victim, nothing off a weak one | observed, F65 |
| wound message 15 | "Your violent attack almost kills you." | inferred intent, F66 |
| [StrikeObject](../src/verbs.asm#L1211) weapon test | the weapon breaks on weak targets: striking the barrel breaks the sword, and with it the only light | observed, F46 |
| [VerbMove](../src/verbs.asm#L294) too small | the message names a word taken from the obstacle's weight bytes | observed, F53 |
| [VerbLookThrough](../src/verbs.asm#L521) | the dark test reads location 1: "It is dark." never shows | observed, F54 |
| [VerbRun](../src/verbs.asm#L639) | hangs on the steep paths, whose only exit is down | observed, F55 |
| no-exit location `$2F` | LOOK lists phantom doors, RUN hangs (unreachable in play) | observed by poke, F82 |
| [WalkToExit](../src/verbs.asm#L582) | the passage check uses the previous move's weight and destination | inferred, F34 |
| second-noun question | "WHICH TING ?" and a wrong saved phrase | observed by call, F61 |
| [CheckCanCarry](../src/verbs.asm#L128) sign test | an actor with a capacity of 132+ cannot take small things | observed by poke, F67 |
| [SumHeldRecords](../src/objects.asm#L511) overflow | some sums wrap past 255 | inferred, F68 |
| word longer than 104 letters | overwrites the code of [ClearBytes](../src/keys.asm#L464): every later line is "WHAT ?", even after QUIT | observed, F70 |
| more than 32 tokens in a line | 128 full stops overwrite code: garbage or a crash into BASIC | observed, F71 |
| ninth order | dropped after writing `$FF` past the slots | observed, F72 |
| orders of a refused SAY TO | carried out by the next character spoken to | observed, F73 |
| blocked exit after LOAD | the removed exit is not saved: Elrond restores the wrong one, the real one stays closed | observed (emulated LOAD), F84 |
| picture 5 after LOAD | day or night is not saved | inferred, F77 |
| "Another goblin enters." | compares the player's location with a stale register | inferred, F39 |

Quirks that look intended or harmless: the victory prints no score (F78);
key 7 types `[` in the middle of a line (F79); the deep bog and the forest
kill without a way out (F80, F83); a troll that eats the player dies of
gluttony (F81); the score cannot pass 75.0% (F64).

## Open questions

- The meaning of flag bits 2 and 4 of the object records (set on the sword,
  which needs them to give light, and on a few other objects; bit 2 is
  "full" for the barrel).
- The meaning of some flag bits of the command table nibbles (F13).
- Whether the ring's strength change can overflow in play: wearing the ring
  divides the strength by 4 and taking it off multiplies it by 4 with two
  shifts, so food eaten while invisible could push it past 255 (inferred
  from [LA377_0](../src/handlers.asm#L271) and [LA377_1](../src/handlers.asm#L286), not tried).
- What the 15% of code that never ran does in detail; it is annotated from
  reading only.
