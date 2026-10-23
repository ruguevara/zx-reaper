# 5g. SAVE, LOAD, the printer and the other system words

The system words (SAVE, LOAD, PRINT, NOPRINT, PAUSE, QUIT, HELP, SCORE) are
class 9 words of the dictionary, handled by the parser as it meets them
([DispatchSpecialWord](../src/system.asm#L13), [ActionWordTable](../src/system.asm#L47)), so they take no turn and can
stand anywhere in a line. SAVE and LOAD use the ROM's tape routines on the four
state blocks; PRINT copies the story to the ZX Printer line by line.

## SAVE ([SaveGame](../src/system.asm#L574))

1. The three bytes of the Bard's script command at `$C9E2`, which orders
   rewrite ([05-characters](05-characters.md)), are copied into the variables
   block ([CopyScriptBytes](../src/system.asm#L535) into [SavedScriptBytes](../src/world.asm#L11)).
2. "Start tape then press any key." in the input window, then a key.
3. Four headerless blocks, flag byte `$FF`, through the ROM's SA-BYTES
   (`$04C2`):

| Block | Address | Length |
| --- | --- | --- |
| variables (score, flags, the random event, the player's location cache) | `$B6EB` | 29 |
| objects and characters | `$C11B` | 1557 |
| timers and NPC records | `$CA84` | 191 |
| locations (exits, visited flags, descriptions) | `$BA8A` | 1497 |

4. "Rewind and prepare tape for verification -- then hit any key.", a key,
   and the same four blocks are verified with LD-BYTES (`$0556`, carry clear)
   ([VerifyBlock](../src/system.asm#L649)). A difference prints "Tape error - hit any key to
   continue." and ends the command.

The ROM routines enable interrupts on their way out, so the game executes `DI`
after them. SPACE held while a ROM tape routine runs is BREAK, and the ROM's
error exit then leaves the game (observed by the input scripts, which avoid
SPACE there).

## LOAD ([LoadGame](../src/system.asm#L463))

The same four blocks are read with LD-BYTES straight over the running game
([LoadBlock](../src/system.asm#L509)), then the Bard's bytes are copied back to `$C9E2`. Since the
first blocks have already replaced the live state, a tape error cannot return
to the old game: "Tape error - hit any key to restart program." and
[RestartGame](../src/main.asm#L81).

### What a save does not hold

The four blocks are the whole state, with three exceptions that live in code
or data bytes:

| State | Where | Effect after LOAD into a new session |
| --- | --- | --- |
| which exit was removed at the start | the operand of the instruction at [SmcBlockedExit](../src/handlers.asm#L887) | Elrond restores and names this session's exit, not the loaded game's, which stays removed for good (bug, observed with an emulated LOAD, F84) |
| day or night at the trolls' clearing | header bytes of picture 5 | the picture shows this session's state (inferred, F77) |
| pending SAY TO orders | [OrderSlots](../src/world.asm#L129) | the orders of the current session survive the LOAD (inferred) |

## PRINT and NOPRINT ([WordPrint](../src/system.asm#L83), [L82AF](../src/system.asm#L91), [PrintStoryLine](../src/devices.asm#L15))

`PRINT` sets [PrinterFlag](../src/world.asm#L19) when a printer answers on port `$FB` (bit 6 of
the status clear); with no printer the port reads `$FF` and nothing happens.
From then on, each time the story window finishes a line, [PrintStoryLine](../src/devices.asm#L15)
sends the 8 pixel rows of the bottom text row (row 17) to the printer, dot
line by dot line, with a copy of the loop of the ROM's COPY routine. The
printout is therefore an image of the 42-column text in the game's font, not
characters. `NOPRINT` clears the flag.

## PAUSE ([WordPause](../src/system.asm#L439))

The border turns green until a key is pressed and released, then white
again. Nothing else stops: the game is waiting for input anyway, except for
the idle counter of the line editor, which PAUSE does not touch (the counter
only runs inside [WaitKey](../src/keys.asm#L802)).

## QUIT ([WordQuit](../src/system.asm#L288))

Prints the score, waits for a key and jumps to [RestartGame](../src/main.asm#L81): a new game
with a new random seed, with no confirmation.

## HELP ([WordHelp](../src/system.asm#L308), [HintTable](../src/system.asm#L335))

One hint for each of 11 locations, else "You're doing fine.". Printed in the
input window. A HELP inside an order (`SAY TO THORIN "HELP"`) is skipped.

| Location | Hint |
| --- | --- |
| trolls' path | A trolls door needs a trolls key. |
| Rivendell | Elves are good at reading symbols. |
| goblins' dungeon | A window should be no obstacle to a thief with friends. |
| west bank | Boats can help. Look carefully. |
| dark dungeon | Wait around and time your exit carefully. |
| elvenking's cellar | Timing is critical, remember barrels float. |
| side door | Wait a while. |
| forest road | Take care to leave at the right time. |
| lower halls | A living dragon is deadly, look to bard. |
| spider threads place | Don't stay here too long. |
| trolls' clearing | Wait for the new day dawning. |

## SCORE ([L83EF](../src/system.asm#L361), [PrintScore](../src/system.asm#L379))

"You have mastered 25.0% Of this adventure." See
[05-end-and-score](05-end-and-score.md).
