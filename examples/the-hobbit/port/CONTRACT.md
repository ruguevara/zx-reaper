# Stage 3 port contract

The port is one Python module per asm module (`src/<m>.asm` → `port/<m>.py`),
one function per routine and per entry point other code jumps or calls into,
named as the label (the table below lists every one: module, address, async,
what it does). `main.py` (the lead) is written; `regs.py` holds the registers,
`calls.py` the indirect calls. Design and reasons: `docs/stage3.md` in
zx-reaper; the procedure: `skills/zx-port/SKILL.md`.

## Conventions

**Imports.** First `from labels import *` (labels and constants; a port
function shadows its own label), then
`from regs import r`, `from variables import v`, `from zxpyxel import Goto, mem, mem16, zx`,
and `import <module>` for the other port modules (call them as
`printer.PrintMessage()`: modules import each other, so never
`from <module> import <function>`). Inside a module, its own functions are
called by name (each `def` rebinds the label's name); a bare name of another
module's routine is only its address (an int).

**Registers.** Values pass between routines in `r`, as in the asm: a routine
reads the registers its instructions read and leaves in `r` every register a
caller uses after the call (check the callers; when in doubt, leave the asm's
final value). 8-bit registers are ints 0-255: mask on assignment where the asm
can overflow (`r.a = r.a + 1 & 0xFF`); `r.bc`, `r.de`, `r.hl` are properties;
`r.ix`, `r.iy` are 16-bit ints (`r.ix = r.ix + d & 0xFFFF`; `(IX+d)` with a
negative d is `mem[r.ix + d & 0xFFFF]`). `r.exx()`, `r.ex_af()`, `r.ex_de_hl()`.
Inside a routine, Python locals are fine where nothing outside reads the
register.

**Flags.** `r.zf` (Z set), `r.cf` (carry set), `r.sf`, `r.pf`: set them where
a caller, or a later instruction of the routine, tests them, as the asm leaves
them. `r.cp(n)` sets them as `CP n`; `r.set_zs(x)` returns x and sets Z and S
for an 8-bit result (AND, OR, XOR, INC, DEC). `AND`/`OR`/`XOR` clear carry.

**Control flow.** Loops become Python loops; a label used only inside its
routine needs no function. Fall-through into the next routine and a tail jump
(`JP Other`, `JR Other_Inner`) are `return Other()` (`return await Other()`
when async). A routine entered in the middle (rows "entry point inside") is
its own function from that address; the outer function runs its own part and
then calls it.

**async.** Rows marked async are `async def` and are always awaited
(`await printer.PrintMessage()`); the others are plain `def` and never
awaited. The list is the closure of the routines that wait for keys, the
scroll pause, the tape or the printer: keep it as given.

**Indirect calls.** `JP (HL)`, `JP (IX)`, `JP (IY)`, `CALL` through a table
(verb handlers, arrivals, timers, NPC script routines, message control codes,
parser word classes, special words): `await calls.call_at(addr)` (works for
plain and async routines). `import calls`.

**The message argument stack.** Values pushed before a message is printed and
not popped by the same routine (the message's control codes 0, 1, 4, 19 and
the like consume them from below the return addresses) go on
`printer.msg_args`: `printer.msg_args.append(x)` where the asm pushes; the
codes `.pop()` them. A `PUSH`/`POP` pair that saves a register in a routine is
a Python local. Return addresses never go on the list.

**Dropped return addresses.**
- `JP RestartGame` (QUIT, death, tape errors): `raise Goto(main.RestartGame)`
  (`from zxpyxel import Goto`; main's dispatch goes on there).
- `CommitOrAbort` (objects, $9D44) and `AbortUnlessPerform` (engine, $97FF)
  pop their caller's return address when the command is only being tested:
  they return False then, and every call site is
  `if not objects.CommitOrAbort(): return` (the caller returns at once, with
  the registers as they are). They return True to go on.
- Other `POP`-then-jump tricks inside one module: handle them in the module
  (a local exception class caught where the asm lands, or a returned flag),
  with a comment.

**Self-modifying code.** Write the modified bytes with `mem[Label + k]` where
the asm writes them, and read them where the asm executes them (for example
`mem[SmcSetOrRes + 3]` decides between SET and RES).

**Hardware.** `zx.inp(port)` with the full 16-bit port (`IN A,($FE)` with A =
$7F is `zx.inp(0x7FFE)`, `IN A,(C)` is `zx.inp(r.bc)`): one call per IN the
asm executes, in the same order (the replay feeds the Z80's reads in order).
`zx.out(port, value)`. `LD A,R` is `zx.r()`. In RandomSigned, A at
`RandomSigned_Mixed` is `r.a = zx.take(RandomSigned_Mixed, r.a)` (it mixes
bytes the port does not have, such as the Z80's stack). The ROM tape:
`await rom.SA_BYTES(ix, de, a)`, `carry = await rom.LD_BYTES(ix, de, a, load)`
(`from zxpyxel import rom`).

**Time.** No CPU is emulated. A loop that polls the keyboard or the printer,
and a delay loop, charges its T-states per pass (`zx.spend(t)`, counted from
the asm) and calls `await zx.sync()` each pass. Elsewhere `zx.spend` is
optional (long loops such as the flood fill or a big copy: 21 per LDIR byte).

**Memory.** `v.Name` for a data label (width from the asm), `mem[a]` and
`mem16[a]` for computed addresses, all wrapping like the Z80. Write exactly
the bytes the asm writes, scratch variables and dead stores included (the
check compares all memory from $6000 up and the screen at every pass of the
main loop); mark a write that is there only for the check with `# check:`.
Keep the asm's quirks and bugs (findings in re/findings.md), with a comment.

**Docstrings.** One per function: what it does in game terms, inputs and
outputs in `r` (from the asm header's register lines), and which flags it
leaves.

## Checks

- Per plain routine, while porting: a test file `tests/models/<Routine>.py`
  with `cases` and `port(regs)`, run with
  `python3 tools/zxdiff.py tests/models/<Routine>.py`. The port side is
  `_regs.run(module.Routine, regs, OUTPUTS['regs'])` from
  `tests/models/_regs.py`; flags are compared as `ZF`, `CF`, `SF`, `PF`.
  Put the routine's input memory (records, variables) into the case's `mem`.
  Async routines are left to the whole-game check.
- The whole game: `make port-test` (the lead runs it after integration).

## Routines

### main.py

| Address | Routine | async | What |
| --- | --- | --- | --- |
| $6C00 | `GameStart` | async | Start of the game, restart point and main loop |
| $6C27 | `RestartGame` | async | Restart the game: restore the saved state and begin a new game |
| $6D13 | `MainLoop` | async | Main loop: read a line, turn it into words, run its sentences |
| $6D22 | `BuildWordList` | async | (entry point inside MainLoop) Called from: RestartGame |
| $6DA2 | `UnknownWord` | async | Report an unknown word and read the next line |
| $6DD6 | `ReadLine` | async | Read a typed line from the keyboard |
| $6DF5 | `ReadLine_Key` | async | (entry point inside ReadLine) Called from: L6E7A |

### keys.py

| Address | Routine | async | What |
| --- | --- | --- | --- |
| $6E4F | `CursorKeyToWord` | async | Turn a cursor key at the start of a line into a compass word |
| $6E7A | `L6E7A` | async | Repeat the previous command (the @ key) |
| $6E8B | `EraseInputLine` | async | Erase the typed line from the input window |
| $6E97 | `ReadTypedWord` |  | Turn the next typed word into a word token |
| $6F30 | `ScanPunctuation` |  | Turn punctuation in the typed line into a word token |
| $6F47 | `TestWordEntry` |  | Look up the typed word in the dictionary |
| $6F72 | `TestWordEntry` |  | (entry point inside TestWordEntry) Called from: ReadTypedWord |
| $6F76 | `TestWordEntry_Compare` |  | (entry point inside TestWordEntry) Called from: ReadTypedWord |
| $6FBA | `CompareWords` |  | Compare the typed word with the dictionary word |
| $6FD3 | `ClearScreen` |  | Clear the screen to black ink on white paper |
| $70E2 | `ClearBytes` |  | Zero a block of bytes |
| $70E8 | `CommandRecordAddr` |  | Address of a command table record |
| $70F3 | `PackCommandFlags` |  | Pack the flag nibbles of a command record |
| $711A | `StartPerform` | async | Start performing a command |
| $712B | `PrintCommandSentence` | async | Print a command as a sentence |
| $71D5 | `LocationNamePtr` |  | Address of a location's name phrase |
| $71E2 | `ObjectNamePtr` |  | Address of an object's name phrases |
| $71F3 | `MatchCommandRecord` |  | Match a command table record against the typed phrase |
| $722E | `MatchWord` |  | Compare a parsed word with a command record word |
| $7249 | `WaitKey` | async | Wait for a key of the line editor, typing WAIT when the player is idle |
| $728B | `CompareHLDE` |  | Compare HL with DE |

### printer.py

| Address | Routine | async | What |
| --- | --- | --- | --- |
| $72C3 | `PrintMessageChar` | async | Print a message character |
| $72CE | `PrintCannotDoThat` | async | Print "I cannot do that." |
| $72D3 | `PrintParserMessage` | async | Print a message |
| $72DD | `PrintMessage` | async | (entry point inside PrintParserMessage) Called from: ActorArrives, AnnounceArrival, ArriveForestRiver, CheckCanCarry, CheckHeldByOther, CheckVictory, DispatchCommand, EmptyFirstObject, EndGame, ExamineObject, GiveObject, L8CE0, L9065, L929C, LA244, LA377, LA536, LA5E2, LA67E, LA761, LA814, LA8F6, LA94E, LA9E5, ListExitObstacles, ListObjects, ListObjectsHere, ListVisibleExits, LoadBlock, MoveActor, PrintCannotDoThat, PrintContentsHeader, PrintHolderRelation, PrintLocationText, PrintMessageDot, PrintNoFit, PrintScore, PrintSpeech, PrintStateIX, PutObjectIn, RejectLine, RequireHeld, RespawnKilledGoblin, RunNpcScripts, SaveGame, ShowLocation, SmcSetOrRes, TalkToCharacter, ThorinDeathBreaksKey, UnknownWord, VerbAttack, VerbDrop, VerbFollow, VerbInventory, VerbLook, VerbLookThrough, VerbTake, VerifyBlock, WordHelp |
| $72F1 | `PrintMessageAt` | async | (entry point inside PrintParserMessage) Called from: MessageCall |
| $7311 | `PrintMessage_Word` | async | (entry point inside PrintParserMessage) Called from: PrintCommonWord |
| $7340 | `EndNewLine` | async | Control code $14: end the message with a new line |
| $7344 | `EndFullStop` | async | Control code $15: end the message with a full stop and a new line |
| $7348 | `PrintEndingWord` | async | End a message with a closing word (print modes 2, 3 and 6) |
| $734B | `EndMessage` | async | (entry point inside PrintEndingWord) Called from: EndFullStop, EndNewLine |
| $7367 | `PrintStackedName` | async | Control code 0: print a name phrase passed on the stack |
| $7376 | `PrintStackedWord` |  | Control code 1: print a word token passed on the stack |
| $737E | `MessageJump` |  | Control code 2: jump inside the message data |
| $738D | `L738D` |  | Control code 3 handler: DE=($B6FC), return NZ (jump table $7295, never run) |
| $7394 | `PrintStackedWordArticle` | async | Control code 4: print a word token from the stack with an article |
| $73A3 | `PrintSubjectName` | async | Control code 6: print the name of the subject |
| $73A7 | `PrintSubjectNameAsIs` | async | (entry point inside PrintSubjectName) Called from: PrintCommandSentence |
| $73AF | `PrintFirstObjectName` | async | Control code 7: print the name of the first object with an article |
| $73B4 | `PrintFirstObjectNameAsIs` | async | (entry point inside PrintFirstObjectName) Called from: PrintCommandSentence |
| $73BD | `L73BD` | async | Control code 8 handler: print character A, return Z (jump table $7295, never |
| $73C2 | `PrintSecondObjectName` | async | Control code 9: print the name of the second object with an article |
| $73C7 | `PrintSecondObjectNameAsIs` | async | (entry point inside PrintSecondObjectName) Called from: PrintCommandSentence |
| $73CE | `PrintSecondObjectName_0` | async | (entry point inside PrintSecondObjectName) Called from: PrintFirstObjectName |
| $73D6 | `PrintNameOfObject` | async | (entry point inside PrintSecondObjectName) Called from: PrintActorName |
| $73E0 | `MessageCall` | async | Control code 11: print another message, then go on |
| $73F9 | `L73F9` |  | Control code 12 handler: word reference by ($B6EA), return DE (jump table |
| $73FC | `HisOrYour` |  | Choose "his" or "your" for an actor |
| $7407 | `HisYourFirstObject` |  | Control code 14: "his" or "your" for the first object |
| $740C | `PrintSubjectIs` | async | Control code 16: print the subject's name and "is" or "are" |
| $7411 | `PrintActorIs` | async | (entry point inside PrintSubjectIs) Called from: PrintNameIs |
| $7425 | `L7425` | async | Control code 17 handler: select by ($B6E8), then as $7428 (jump table $7295, |
| $7428 | `PrintNameIs` | async | Print a name with its article, then "is" or "are" |
| $742D | `PrintNameIsFromStack` | async | Print a name with its article and "is"/"are", the id from the stack |
| $7434 | `PrintPhraseAtHL` | async | Print the name phrase at HL |
| $743F | `PrintArticle` | async | Print the article of a name phrase |
| $7478 | `PrintNounWord` | async | Print the noun of a name phrase with its article |
| $7488 | `PrintActorName` | async | Print the name of an actor |
| $7493 | `PrintCommonWord` | async | Print a common word of a message |
| $74BA | `PrintWordAtHL` | async | Print a word of the dictionary |
| $74C1 | `PrintWord` | async | (entry point inside PrintWordAtHL) Called from: ListExitObstacles, ListVisibleExits, PrintActorName, PrintArticle, PrintCommandSentence, PrintEndingWord, PrintNamePhrase, PrintNounWord, PrintParserMessage, RespawnKilledGoblin, VerbLook |

### parser.py

| Address | Routine | async | What |
| --- | --- | --- | --- |
| $7585 | `ParseLine` | async | Parse the typed word list into phrase records |
| $758A | `ParseLineFrom` | async | (entry point inside ParseLine) Called from: BeginOrderPass |
| $75A0 | `StartPhraseRecord` | async | (entry point inside ParseLine) Called from: DispatchSpecialWord, ParseEnd |
| $75B4 | `ParseNextWord` | async | (entry point inside ParseLine) Called from: DispatchSpecialWord, L82E2, ParseDirection, ParseGoVerb, ParseIn, RejectLine, ResumeDispatch, StoreParsedOrders, WordAll, WordExcept, WordHelp |
| $75BE | `DispatchWord` | async | (entry point inside ParseLine) Called from: ParseArticle |
| $75EC | `TestOrderText` |  | Test for an order being parsed (Z set) |
| $75F1 | `TestTypedLine` |  | Test for the player's own line being parsed (Z set) |
| $75F6 | `ParseEnd` | async | Parse the end of the line or THEN: close the phrase records |
| $75FA | `ParseThen` | async | (entry point inside ParseEnd) Called from: ParseAnd, ParseGoVerb |
| $7614 | `CloseRecord` | async | (entry point inside ParseEnd) Called from: ParseLine |
| $76EC | `ParseDirection` | async | Parse a direction or an adverb (word classes 2 and 0) |
| $770B | `ParseAnd` | async | Parse AND: save the parser position, then treat it as a separator |
| $772F | `ParseGoVerb` | async | Parse a verb (word classes 4 and 3) |
| $7731 | `ParseVerbAsCommand` | async | (entry point inside ParseGoVerb) Called from: ParseDirection, ParseIn |
| $7790 | `ParseArticle` | async | Parse an article or auxiliary word (class 8) |
| $7795 | `ParseIn` | async | Parse "in" and the words of a noun phrase (word classes 1, 7, 6, 5) |
| $7809 | `StoreAdjective` | async | Store a word in the first free slot of a pair |
| $780C | `StoreWordInPair` | async | (entry point inside StoreAdjective) Called from: StorePreposition |
| $781C | `StorePreposition` | async | Store a preposition in the phrase slots |
| $782B | `StorePhraseBlock` | async | Copy the collected phrase slots into the record |
| $7838 | `StorePhraseBlock_0` | async | (entry point inside StorePhraseBlock) Called from: L82E2 |
| $7850 | `StoreFirstPhraseBlock` | async | (entry point inside StorePhraseBlock) Called from: L82E2, ParseIn |
| $7858 | `PreviousRecord` |  | Go back to the previous phrase record |
| $785F | `ClearAllStage` |  | Clear the ALL/EXCEPT stage |
| $7864 | `ClearRecord` |  | Clear a phrase record and the head of the next one |
| $7873 | `ReadWord` |  | Read the next word of the parsed line |
| $788C | `StepOlderCount` |  | Step IY to the next older phrase record, counting down B |
| $7892 | `StepNewerCount` |  | Step IY to the next newer phrase record |
| $7893 | `StepNewer` |  | (entry point inside StepNewerCount) Called from: ParseEnd |
| $7896 | `SwapRecordPtrs` |  | (entry point inside StepNewerCount) Called from: StepOlderCount |
| $789F | `FindNewerRecord` |  | Find the next newer phrase record |
| $78A5 | `FindOlderRecord` |  | Find the previous (older) phrase record |
| $78A9 | `FindRecordStep` |  | (entry point inside FindOlderRecord) Called from: FindNewerRecord |
| $78B7 | `InheritRecord` |  | Let a phrase record inherit from the one before it |
| $78EA | `CopyBlockFromIX` |  | (entry point inside InheritRecord) Called from: ParseEnd |
| $78FB | `L78FB` |  | Copy 6 bytes of record field IX+DE to IY+DE (entry for C=6; $78FF copies 10, |
| $78FF | `L78FB_0` |  | (entry point inside L78FB) Called from: InheritRecord |
| $7903 | `L78FB_1` |  | (entry point inside L78FB) Called from: InheritRecord |
| $7914 | `StoreFirstWord` |  | Store a word as the first word of the record |
| $7918 | `StoreRecordWord` |  | (entry point inside StoreFirstWord) Called from: ParseDirection, ParseGoVerb |
| $7924 | `RejectPhrase` | async | Reject the phrase |
| $7929 | `RejectLine` | async | Refuse the line with "What ?" |
| $792F | `PrintWhat` | async | (entry point inside RejectLine) Called from: MainLoop, ParseEnd |
| $7960 | `RunSentences` | async | Run the parsed sentences, one turn each |
| $798B | `EndOfTurn` | async | (entry point inside RunSentences) Called from: MatchCommand |
| $798E | `RunSentences_More` | async | (entry point inside RunSentences) Called from: PerformRefusal |
| $7994 | `NextRecord` | async | (entry point inside RunSentences) Called from: ExplainNounFailure |
| $79A9 | `ResetRecWork` |  | Clear the record workspace |
| $79B6 | `MatchSentence` | async | Match a phrase record to a command and find its objects |
| $7A14 | `ResolveNouns` | async | Find the objects the noun phrases of a sentence mean |
| $7A73 | `IsExcluded` |  | Test whether EXCEPT removes the current object |
| $7AA1 | `StartNounScan1` |  | Start the candidate scan for the first noun |
| $7AA6 | `StartNounScan1_Always` |  | (entry point inside StartNounScan1) Called from: TestActorCommand |
| $7ABA | `StartNounScan2` |  | Start the candidate scan for the second noun |
| $7ACC | `PickScanStart` |  | Choose where an object scan starts |
| $7AD8 | `NeedSecondNoun` |  | Decide whether the second noun phrase must be matched next |
| $7AED | `RunCheck` | async | Run the command check and fetch its result |
| $7AF5 | `TestActorCommand` | async | Test whether a character can do a command |
| $7B63 | `CopyNamePhrase` |  | Copy the name phrase of an object or place into a record buffer |
| $7B78 | `UnpackFlags` |  | Unpack the command flags into the matcher's variables |
| $7B9E | `MatchCommand` | async | Find the command table record that matches a parsed phrase |
| $7C23 | `SplitNounPhrases` |  | Split a matched phrase into its two noun phrases |
| $7C91 | `CopyPhrase` |  | Copy a noun phrase out of the parsed record |
| $7CAC | `CollectWord` |  | Collect one word of the parsed record |
| $7CC9 | `CallIY` | async | Jump to the routine in IY |
| $7CCB | `NextNoun1` | async | Next candidate for the first noun phrase |
| $7CFC | `NextNoun1Match` | async | Find the next object that fits noun phrase 1 and passes the check |
| $7D17 | `NextNoun2` | async | Next candidate for the second noun phrase |
| $7D54 | `NextNoun2Match` | async | Find the next object that fits noun phrase 2 and passes the check |
| $7D6B | `SetPerformMode` |  | Switch to performing and printing mode |
| $7D74 | `SaveParsedRecord` |  | Save the parsed record for the player's reply |
| $7D83 | `AskWhichNoun1` | async | Ask "Which ...?" about noun phrase 1 |
| $7D89 | `AskWhich` | async | (entry point inside AskWhichNoun1) Called from: ExplainNoun2Failure |
| $7D90 | `PrintReplyFail` | async | Print a parser reply and return failure |
| $7D98 | `ExplainNoun2Failure` | async | Explain why the second noun phrase gave no single object |
| $7DBC | `ExplainNounFailure` | async | Explain why the noun phrases did not give one object each |
| $7DF5 | `PerformRefusal` | async | Run the verb handler again to print its refusal |
| $7DFE | `FindNounElsewhere` | async | Find a named object out of reach and say where it is |
| $7E30 | `ReportNoNoun1` | async | Report that the first noun phrase names nothing here |
| $7E4D | `ReportNoSecondNoun` | async | Report or ask about a missing second noun phrase |
| $7E78 | `PushWordsAfter` |  | Push the command's words that follow the noun |
| $7E7C | `PushWordsBefore` |  | Push the command's words that precede the noun |
| $7E7E | `PushWords_SetTests` |  | (entry point inside PushWordsBefore) Called from: PushWordsAfter |
| $7EA8 | `ReportUnknownVerb` | async | Report a verb that matched only in part |
| $7EBA | `ClaimOrderSlots` |  | Give pending order slots to an actor and free the rest |
| $7EFF | `FindOrderSlot` |  | Find the order slot of the acting character |
| $7F10 | `FindOrderSlotKeep` |  | Find the acting character's order slot, keeping registers |
| $7F1A | `RunStoredOrder` | async | Take the acting character's stored order and test it |
| $7F60 | `FreeOrderSlots` |  | Free the order slots of an actor |

### drawing.py

| Address | Routine | async | What |
| --- | --- | --- | --- |
| $7F78 | `DrawLocationPicture` |  | Draw the picture of a location |
| $7FA7 | `RunPictureCommands` |  | Run the picture commands of a location picture |
| $8069 | `RunPictureCommands_End` |  | (entry point inside RunPictureCommands) Called from: StartPicture |
| $8071 | `FloodFill` |  | Flood fill a region of the picture |
| $80EE | `TestPixel` |  | Test a picture pixel |
| $80F5 | `AttrUp` |  | Step an attribute address up one row |
| $8106 | `AttrDown` |  | Step an attribute address down one row |
| $8117 | `AttrLeft` |  | Step an attribute address left one cell |
| $8121 | `AttrRight` |  | Step an attribute address right one cell |
| $812B | `MovePenUp` |  | Move the picture pen up one pixel |
| $8135 | `MovePen_Moved` |  | (entry point inside MovePenUp) Called from: MovePenDown |
| $813A | `MovePenDown` |  | Move the picture pen down one pixel |
| $8141 | `MovePenRight` |  | Move the picture pen right one pixel |
| $8148 | `MovePenLeft` |  | Move the picture pen left one pixel |
| $8151 | `DrawPictureLine` |  | Draw a straight picture line segment |
| $81B5 | `PlotPixel` |  | Plot a picture pixel and colour its cell |
| $81DE | `PenToScreen` |  | Convert a picture pen position to a screen byte address and bit mask |
| $820B | `StartPicture` |  | Start a picture: border, attribute fill and clear |

### system.py

| Address | Routine | async | What |
| --- | --- | --- | --- |
| $8251 | `DispatchSpecialWord` | async | Run the handler of a special typed word (all, except, it, load, save...) |
| $82A5 | `WordPrint` | async | Handler of the word "print": switch the ZX printer on |
| $82AF | `L82AF` | async | Command handler: clear ($B6F2) (table $828B) |
| $82B0 | `L82AF_0` | async | (entry point inside L82AF) Called from: WordPrint |
| $82B3 | `ResumeDispatch` | async | Return from a word handler to the dispatcher |
| $82BA | `WordExcept` | async | Handler of the word EXCEPT |
| $82D2 | `WordAll` | async | Handler of the word "all" (also "everything") |
| $82E2 | `L82E2` | async | Command handler: copy 6 bytes $B6E0 to $757F, then dispatch (table $828B) |
| $82FD | `BeginOrderPass` | async | Start the second pass over a stored order |
| $8315 | `StoreParsedOrders` | async | Handle the end of the typed words: store the orders of a SAY TO line |
| $8391 | `WordQuit` | async | Handler of the word QUIT |
| $83A0 | `WordHelp` | async | Handler of the word HELP |
| $83EF | `L83EF` | async | Command handler (via $828B): call $83F5, then $82B3 |
| $83F5 | `PrintScore` | async | Print the score as a percentage of the adventure |
| $842E | `DecimalDigit` |  | Next decimal digit by repeated subtraction |
| $843A | `WordPause` | async | PAUSE: wait for a key with a green border |
| $8451 | `LoadGame` | async | Load a saved game from tape |
| $8498 | `LoadBlock` | async | Load one block from tape, restart the game on an error |
| $84B3 | `CopyScriptBytes` |  | Copy the three script bytes |
| $84B9 | `WaitForKey` | async | Wait for a key press |
| $84CC | `SaveGame` | async | Save the game to tape and verify it |
| $8553 | `SaveGame_End` | async | (entry point inside SaveGame) Called from: VerifyBlock |
| $855A | `VerifyBlock` | async | Verify one tape block of SAVE |

### screen.py

| Address | Routine | async | What |
| --- | --- | --- | --- |
| $8576 | `OutputEnabled` |  | Test whether text output is enabled |
| $8583 | `PrintNewLine` | async | Print a new line |
| $858B | `PrintChar` | async | Print a character in the current output window |
| $85B7 | `PrintToInput` |  | Print a character in the input window |
| $85B8 | `PrintInputWindowChar` |  | (entry point inside PrintToInput) Called from: RestartGame |
| $860D | `ScrollInputUp` |  | Scroll the input window up one line |
| $864A | `ScrollInputDown` |  | Scroll the input window down one line |
| $867A | `PrintInputChar` |  | Print a character in the input window |
| $86A1 | `OutputStoryChar` | async | Print a character in the story window |
| $8761 | `StepCursorBack` |  | Move the story-window cursor back one character |
| $876B | `ScrollStoryUp` |  | Scroll the story window up one line |
| $87C9 | `PrintStoryChar` |  | Print a character in the story window |

### devices.py

| Address | Routine | async | What |
| --- | --- | --- | --- |
| $8B22 | `PrintStoryLine` | async | Print a story line on the ZX printer |
| $8B78 | `DelayShort` |  | Short delay loop |
| $8B93 | `ReadKey` |  | Scan the keyboard and return a newly pressed key |

### verbs.py

| Address | Routine | async | What |
| --- | --- | --- | --- |
| $8C4B | `VerbLook` | async | Look: say where the actor is and what is around |
| $8C9B | `RequireHeld` | async | Require the first object to be held by the subject |
| $8CA6 | `VerbDrop` | async | Drop the first object |
| $8CE0 | `L8CE0` | async | Command handler (via $C730) |
| $8CF1 | `CheckCanCarry` | async | Check that the subject can lift and carry the first object |
| $8D25 | `CheckCanCarry_Single` | async | (entry point inside CheckCanCarry) Called from: PutObjectIn, SmcSetOrRes |
| $8D33 | `VerbTake` | async | Take or carry an object (default handler of the verbs take and carry) |
| $8D3C | `VerbTake_0` | async | (entry point inside VerbTake) Called from: L8CE0 |
| $8D9D | `VerbMove` | async | Move the actor in a direction |
| $8DAB | `MoveActor` | async | Move the actor through the exit in CommandId |
| $8E12 | `ActorArrives` | async | The actor arrives at the destination |
| $8E39 | `ActorArrives_0` | async | (entry point inside ActorArrives) Called from: ArriveForestRiver |
| $8E6D | `ActorArrives_2` | async | (entry point inside ActorArrives) Called from: MoveActor |
| $8E72 | `ActorArrives_3` | async | (entry point inside ActorArrives) Called from: MoveActor |
| $8E85 | `CheckPassage` |  | Check whether the subject can pass an obstacle and enter the destination |
| $8ED2 | `CheckEnclosed` |  | Test whether an object is shut in by a closed holder |
| $8EEC | `VerbLookThrough` | async | Look through the first object into the place beyond |
| $8F3B | `L8F3B` | async | Command handler (via $C730): call $9F25 |
| $8F3E | `WalkToExit` | async | Walk through a given exit (follow, enter, go into) |
| $8F69 | `L8F69` | async | Command handler (via $C730) |
| $8FAD | `VerbRun` | async | Run: move in a random direction that has an exit |
| $8FCD | `L8FCD` | async | Command handler (via $C730): call $9F2D with ($B6E8), jump to $8F3E |
| $8FD6 | `VerbFollow` | async | Follow: walk to where the first object is |
| $8FF5 | `L8FF5` | async | Command handler (via $C730) |
| $9034 | `TalkToCharacter` | async | Handler for "talk to": the character takes some of the orders |
| $9065 | `L9065` | async | Command handler (via $C730) |
| $90D2 | `EndGame` | async | End of the game: dead, or the ending text printed |
| $90DF | `EndGame_Wait` | async | (entry point inside EndGame) Called from: CheckVictory |
| $90EB | `VerbInventory` | async | Inventory: list what the subject carries |
| $910E | `OpenObject` | async | Open the first object and show what is inside |
| $9117 | `OpenObject_0` | async | (entry point inside OpenObject) Called from: L9065, LA35E |
| $9138 | `CloseObject` | async | Close the first object |
| $9145 | `CloseObject_Clear` | async | (entry point inside CloseObject) Called from: L9065 |
| $914A | `CheckAttackAllowed` |  | Refuse an attack between actors that share a side bit |
| $9171 | `VerbAttack` | async | Attack the first object, with the second as the weapon |
| $9213 | `RollStrength` |  | Roll a strength with a random spread |
| $9246 | `CheckSinglePlace` |  | Test whether the first object has a single place |
| $924F | `PutObjectIn` | async | Put the first object into (or onto) the second |
| $929C | `L929C` | async | Command handler (via $C730) |
| $92B5 | `L929C_0` | async | (entry point inside L929C) Called from: LA94E |
| $92ED | `StrikeObject` | async | Strike an object, perhaps with a weapon |
| $939E | `GiveObject` | async | Give the first object to the second |
| $93DA | `ExamineObject` | async | Examine the first object |
| $9404 | `SmcSetOrRes` | async | Command handler (via $C730), with entry points $946D, $948D, $94A4 |
| $946D | `L9404_5` | async | (entry point inside SmcSetOrRes) Called from: LA244 |
| $948D | `L9404_7` | async | (entry point inside SmcSetOrRes) Called from: LA244 |

### engine.py

| Address | Routine | async | What |
| --- | --- | --- | --- |
| $94D6 | `CheckVerbApplies` |  | Test whether the command can be applied to the first object |
| $950F | `DispatchCommand` | async | Carry out the command in the parser variables (test pass or real pass) |
| $95DF | `NotifyCharacter` |  | Let a living character react to a command |
| $95ED | `CheckDark` |  | Test whether the subject is in the dark |
| $962B | `DescribeSeen` | async | Describe a location with the "see" message |
| $9630 | `DescribeLocation` | async | Describe a location as "<subject> are in ..." with its picture |
| $964D | `DescribeLocation_Intro` | async | (entry point inside DescribeLocation) Called from: DescribeSeen, VerbCapture |
| $965B | `ShowLocation` | async | Show a location: its text, picture, obstacles, exits and objects |
| $967F | `ShowLocation_Lists` | async | (entry point inside ShowLocation) Called from: DescribeLocationShort |
| $9686 | `PrintLocationText` | async | Print a location's description text or its name |
| $9689 | `PrintLocationName` | async | (entry point inside PrintLocationText) Called from: DescribeLocationShort |
| $969A | `WaitKeyAfterPicture` | async | Wait for a key after a picture |
| $96A8 | `DescribeLocationShort` | async | Show a visited location: its name and the lists, without the picture |
| $96B3 | `EndTurn_Timer` | async | End of a turn: win test, NPC scripts, timers |
| $9728 | `CheckHeldByOther` | async | Report an object that another character is carrying |
| $977C | `L977C` | async | Wound/score helper: A=($B6E8), continues at $977F (called from $A30D) |
| $977F | `KillCharacter` | async | Kill a character |
| $97AD | `InitNewGame` |  | Set up a new game: the blocked exit, the random event, the actor |
| $97F4 | `PrintMessageDot` | async | Print a message, then a full stop and a new line |
| $97FF | `AbortUnlessPerform` |  | Return from the caller unless the action is to be performed |
| $980E | `RunNpcScripts` | async | Run the script of every NPC for one turn (the script interpreter) |
| $9870 | `RunNpcScripts_Start` | async | (entry point inside RunNpcScripts) Called from: NpcHeld |
| $987F | `RunNpcScripts_Script` | async | (entry point inside RunNpcScripts) Called from: RunScriptVerb |
| $9885 | `RunNpcScripts_Command` | async | (entry point inside RunNpcScripts) Called from: RunScriptVerb |
| $9901 | `RunNpcScripts_Next` | async | (entry point inside RunNpcScripts) Called from: NpcHeld, RunScriptCommand, RunScriptVerb |
| $9918 | `AdvanceScript` |  | Step the NPC script pointer past the command just read |
| $9928 | `RunScriptCommand` | async | Run an NPC script command of op 0-3 (a command with objects, or a routine) |
| $9974 | `RunScriptVerb` | async | Run an NPC script command of type 4 (a verb alone) |
| $99AA | `ScriptCommandFailed` | async | (entry point inside RunScriptVerb) Called from: RunScriptCommand |
| $99C6 | `RunActorCommand` | async | Make a character carry out the command in the parser variables |
| $99CE | `RunActorCommand_Run` | async | (entry point inside RunActorCommand) Called from: RunNpcScripts |
| $9A59 | `ChooseRandomScript` |  | Choose a random script from the NPC's behaviour table |
| $9A68 | `SelectScript` |  | (entry point inside ChooseRandomScript) Called from: RunNpcScripts |
| $9A85 | `FindNpcState` |  | Find an NPC record by id |
| $9AA0 | `SwitchNpcScript` |  | Switch an NPC to the script for an event |
| $9ACD | `AnnounceArrival` | async | Announce that a character or object has arrived where the player is |
| $9B02 | `UpdatePlayerSight` |  | Update where the player is and whether the player can see |

### objects.py

| Address | Routine | async | What |
| --- | --- | --- | --- |
| $9B16 | `NpcHeld` | async | NPC turn: the NPC is held by something |
| $9B44 | `CheckNounsDistinct` |  | Check that a command does not use the same object twice |
| $9B6C | `CallHandler` | async | Call a handler address if it is not zero |
| $9B80 | `JumpHL` | async | Jump to the address in HL |
| $9B81 | `FindVerbEntry` |  | Find a verb entry in an object's verb table |
| $9B93 | `NextObject` |  | Step to the next entry of the object table |
| $9BA9 | `NextObjectKeepA` |  | Step to the next object, keeping A |
| $9BB1 | `FindLocation` |  | Find a location record |
| $9BCA | `FindObject` |  | Find an object or character record |
| $9BDD | `MoveCarried` | async | Move what a carrier holds to a new location, bringing the player along |
| $9C17 | `MoveContents` |  | Move an object's contents to a location |
| $9C41 | `LocationSpareCapacity` |  | Capacity left at a location |
| $9C78 | `CheckObject1Held` |  | Test whether an object is held by the subject |
| $9C7B | `CheckHeldBySubject` |  | (entry point inside CheckObject1Held) Called from: CheckHeldByOther, DispatchCommand, L9065 |
| $9C7E | `CheckObject1Held_0` |  | (entry point inside CheckObject1Held) Called from: L8CE0 |
| $9C8A | `WalkHolderChain` |  | Walk up the holder chain of an object |
| $9C9F | `RandomUpTo` |  | Random number from 0 to A |
| $9CA8 | `RandomSigned` |  | Random number from -A to A |
| $9CE8 | `SumHeldWeight` |  | Sum the weights of what a holder directly holds |
| $9CED | `SumHeldBulk` |  | Sum the sizes of everything inside a holder |
| $9CF0 | `SumHeld` |  | (entry point inside SumHeldBulk) Called from: SumHeldWeight |
| $9D00 | `SumHeldRecords` |  | Add a field of all records held by a holder |
| $9D37 | `GetActorLocationRec` |  | Find the record of the location of the current actor |
| $9D44 | `CommitOrAbort` |  | Continue only if the command is really being performed |
| $9D50 | `EmptyFirstObject` | async | Empty the first object: consumables vanish, the rest passes up |
| $9D53 | `EmptyHolder` | async | (entry point inside EmptyFirstObject) Called from: KillCharacter, LA5E2, LA94E |
| $9D97 | `CountHeldPresent` |  | Count the present records held by a holder |
| $9DBD | `FindIdRecord` |  | Find a record by id in a table of records that start with an id |
| $9DD9 | `FindNextNamedObject` |  | Find the next object that a typed noun phrase can mean |
| $9E25 | `CanReachSwapped` |  | Test reach with the two records exchanged |
| $9E34 | `ActorCanReach` |  | Test whether the current actor can reach an object |
| $9E40 | `CanReach` |  | Test whether an object is within an observer's reach |
| $9E7A | `FindClosedHolder` |  | Find the closed holder of an object |
| $9E95 | `SeekActorExits` |  | Point IX at the exits of the actor's location |
| $9EA0 | `FindExitByName` |  | Find the next exit whose destination a typed noun phrase names |
| $9EC7 | `PrintObjectName` | async | Print the name of an object |
| $9ED6 | `PrintNamePhrase` | async | Print a name phrase |
| $9F08 | `FindExitByDirection` |  | Find the exit of the actor's location in a given direction |
| $9F25 | `FindExitByObstacle` |  | Find the exit that has the first object as its obstacle |
| $9F28 | `FindExitByObstacle_0` |  | (entry point inside FindExitByObstacle) Called from: LA814, SmcSetOrRes |
| $9F2D | `FindExitByDestination` |  | Find the exit of the actor's location that leads to a given place |
| $9F30 | `FindExitByField` |  | (entry point inside FindExitByDestination) Called from: FindExitByObstacle |
| $9F4A | `L9F4A` | async | Swap the actor and target records ($B708/$B70A, $B6E8/$B6E9), run $9B6C, swap |
| $9F76 | `RefuseCommand` | async | Refuse the command |
| $9F82 | `GetSingleLocation` |  | Get the one location of a record |
| $9F94 | `ListObjectsHere` | async | Print "You see :" and the objects lying where the actor is |
| $9FAF | `ListObjects` | async | List what a holder holds at a location, or print "Nothing" |
| $9FC7 | `ListHolderContents` | async | List the objects of a holder, one per line, with their contents |
| $A050 | `PrintContentsHeader` | async | Print the line that introduces what an object holds |
| $A09D | `PrintHolderRelation` | async | Print the relation word of a holder |
| $A0AE | `SeekExitsOfLocation` |  | Point IX at the exits of a location |
| $A0BA | `GetIdWord` |  | Get the dictionary word for an id |
| $A0BD | `GetTableWord` |  | (entry point inside GetIdWord) Called from: PrintStateIX |
| $A0C8 | `ListExitObstacles` | async | List the doors and other obstacles on the exits of a location |
| $A124 | `NextListedExit` |  | Step to the next listable exit |
| $A138 | `ListVisibleExits` | async | List the visible exits of a location |
| $A164 | `PrintStateIY` | async | Print "<object> is <state>" for the object in IY |
| $A16C | `PrintStateIX` | async | Print "<object> is <state>" for the object in IX |
| $A172 | `PrintStateHL` | async | (entry point inside PrintStateIX) Called from: PrintStateIY |
| $A18C | `MarkBrokenOrDead` |  | Mark an object or actor as broken or dead |
| $A1AE | `LA1AE` |  | Find the record in table $C060 whose id matches IY+1 (unreferenced), then |
| $A1C8 | `LA1AE_2` |  | (entry point inside LA1AE) Called from: L9065 |

### handlers.py

| Address | Routine | async | What |
| --- | --- | --- | --- |
| $A1D0 | `IsPlacingCommand` |  | Test whether the command puts an object somewhere |
| $A1E3 | `PrintSpeech` | async | Print a spoken line |
| $A1F9 | `CheckOpenable` |  | Say why the first object cannot be opened, or that it can |
| $A204 | `CheckOpenable_0` |  | (entry point inside CheckOpenable) Called from: SmcSetOrRes |
| $A244 | `LA244` | async | Handlers (via $A1D5): $A244, $A248, $A2B4, $A2CD, $A302, $A310, $A328, $A330 |
| $A358 | `PrintNoFit` | async | Print that the key does not fit |
| $A35E | `LA35E` | async | Command handler (via $C730): call $97FF, jump to $9117 |
| $A368 | `OpenCrack` | async | Open handler of the small insignificant crack |
| $A377 | `LA377` | async | Command handler (via $C730) with entry points $A390 and $A3BC |
| $A3BC | `LA377_1` | async | (entry point inside LA377) Called from: LA9E5 |
| $A3E6 | `VerbCapture` | async | Capture: send the first object to a prison |
| $A448 | `RespawnKilledGoblin` | async | Bring a killed goblin back at its home |
| $A4C0 | `LA4C0` | async | Handler: test (IX+$10)=$10, call $910E and $97FF |
| $A4DF | `NpcAnswersGift` | async | NPC answer to being given something |
| $A4F5 | `LA4F5` | async | Command handler (via $C8C9 table) |
| $A4FE | `GandalfCheers` | async | Gandalf cheers the player on |
| $A51C | `LA51C` | async | Command handler (via $C8FC table) |
| $A525 | `ElrondGreets` | async | Elrond greets the player |
| $A536 | `LA536` | async | Command handlers ($A536, $A541, $A55F) |
| $A5CA | `CheckOpen` |  | Test whether the object is open |
| $A5D1 | `WargHowls` | async | The warg runs around the player and howls |
| $A5E2 | `LA5E2` | async | Handlers: $A5E2 (via $C302), $A5FB |
| $A640 | `ThorinMissesThief` | async | Thorin asks where the thief is |
| $A657 | `ThorinTalks` | async | Thorin's remarks |
| $A67E | `LA67E` | async | Handlers (via $C2F0, $C2F3) |
| $A73B | `ThorinDeathBreaksKey` | async | Killing Thorin breaks the small curious key |
| $A761 | `LA761` | async | Handlers (via $C518, $C51B) |
| $A7C4 | `ExamineMap` | async | Examine the curious map |
| $A814 | `LA814` | async | Handlers (via $C378): $A814, $A876, $A89E, $A8AB |
| $A8D2 | `GollumAsksRiddle` | async | Gollum asks his riddle |
| $A8F6 | `LA8F6` | async | Handler (via $C9FE) |
| $A926 | `GollumTalks` | async | Gollum mutters about his pockets |
| $A94E | `LA94E` | async | Handlers (via $CA42-$CA54): $A94E, $A971 |
| $A9BD | `TrollsTalk` | async | The trolls talk about cooking the player |
| $A9D6 | `CheckVictory` | async | Victory check, once per turn |
| $A9E5 | `LA9E5` | async | Handlers (via $C9A1): $A9E5 and following to the end of the code region |

### world.py

| Address | Routine | async | What |
| --- | --- | --- | --- |
| $C7A4 | `ArriveBeornsHouse` |  | Beorn house: wake the butler (location $16) |
| $C7B2 | `ArriveSpiderPlace` |  | Mirkwood spider place: start timer 3 (location $1A) |
| $C7B9 | `ArriveBog` |  | Deep bog: start timer 4 (location $1D) |
| $C7C0 | `ArriveCellar` |  | Elvenking cellar: start timer 9, wake the dragon slot and the Bard (location |
| $C7DD | `ArriveForest` |  | Forest road and forest: remember the arrival, start timer 8 (locations 2 and |
| $C7EA | `ArriveForestRiver` | async | Forest river: without the barrel the player is swept away (location $21) |
