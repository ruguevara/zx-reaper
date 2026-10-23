# 5a. The parser

The parser turns a typed line into commands: a verb id from 1 to 59 and up
to two objects. It works in three stages: words to tokens (dictionary
lookup), tokens to phrase records (a small state machine driven by the word
class), and records to commands (matching the command table and finding the
objects the nouns mean). The game's own name for it was INGLISH.

## 1. Words to tokens ([ReadTypedWord](../src/keys.asm#L127), [L6F47](../src/keys.asm#L272))

Each word of the line is looked up in the dictionary at `$6000`
([02-data](02-data.md)):

1. the letters (characters from `$40` up, 5 bits each) are copied into
   [WordLetters](../src/keys.asm#L423) and counted;
2. the index entry for the first letter gives the first dictionary word with
   that letter; entries are tried one by one until the first letter changes;
3. a typed word matches an entry when the shorter of the two is a prefix of
   the other ([CompareWords](../src/keys.asm#L353)), with two rules: when the typed word is the
   shorter one it matches the first such entry (`exa` is `examine`); when the
   typed word is longer, the entry must have at least 4 letters, and a later
   entry that also matches is preferred (`looking` is `look`, but `inn` is not
   `in`);
4. a synonym entry is replaced by the word it points to (`get`, `steal`,
   `lift` -> `take`; `kill`, `hit`, `slash` -> `attack`; `n` -> `north`;
   `i` -> `inventory`);
5. the token is the class of the word in the top nibble and its offset;
   punctuation gives THEN (`.`), AND (`,`) or a quote token
   ([ScanPunctuation](../src/keys.asm#L237)).

A word that matches nothing ends the line with `I do not know the word
"xyzzy"`. So any start of a word is accepted as the first word that begins
with it (`EXA` for `examine`), and any longer word that begins with a word of
4 or more letters is taken as that word (`TAKEN`, `LOOKING`).

The letter buffer [WordLetters](../src/keys.asm#L423) holds 16 letters and the copy loop has no
limit; see [06-tricks](06-tricks.md) for what a longer word does.

## 2. Tokens to phrase records ([ParseLine](../src/parser.asm#L30))

[ParseLine](../src/parser.asm#L30) reads the tokens with [ReadWord](../src/parser.asm#L731) and jumps through
[ActionTable](../src/parser.asm#L87) by the word class:

| Class | Handler | What it does |
| --- | --- | --- |
| 0 adverb | [ParseAdverb](../src/parser.asm#L334) | kept as the record's second word (`quickly go north`), at most one |
| 1 in, into | [ParseIn](../src/parser.asm#L503) | a preposition, or the command itself when no verb came yet |
| 2 direction | [ParseDirection](../src/parser.asm#L329) | the command (`north`) when no verb came yet, else the second word (`go north`) |
| 3 verb, 4 go/run | [ParseVerb](../src/parser.asm#L408), [ParseGoVerb](../src/parser.asm#L403) | the command word; after `go`/`run` a following direction becomes the command and `go` the second word, the form of commands 1-10 |
| 5 noun | [ParseNoun](../src/parser.asm#L538) | closes a noun phrase: prepositions and adjectives collected so far plus the noun go into phrase block A, then B |
| 6 adjective | [ParseAdjective](../src/parser.asm#L533) | up to two per noun |
| 7 preposition | [ParsePreposition](../src/parser.asm#L512) | up to two per noun phrase (`out of`) |
| 8 article / aux | [ParseArticle](../src/parser.asm#L466) | skipped (`the`, `a`, `is`, `can`...) |
| 9 special | [DispatchSpecialWord](../src/system.asm#L13) | ALL, EXCEPT, IT, ONE and the system words, below |
| 10 and | [ParseAnd](../src/parser.asm#L362) | ends the record and starts a new one |
| 11 then | [ParseThen](../src/parser.asm#L173) | ends the sentence |
| 12 end | [ParseEnd](../src/parser.asm#L169) | ends the line |

The result is a stack of 24-byte phrase records growing down from `$B9C8`
(layout in [02-data](02-data.md), verified by dumps after typed lines, F25).

### AND, THEN and shared words

- `.` and THEN end a sentence. [ParseLine](../src/parser.asm#L30) returns after each sentence, the
  main loop runs it and calls the parser again for the rest of the line, so
  `TAKE MAP. GO EAST` takes the map before the parser even reads `GO`.
- AND (or a comma) starts a new record. If the record has no verb of its own,
  it inherits the command words of the one before it ([InheritRecord](../src/parser.asm#L844)):
  `TAKE THE ROPE AND THE SWORD` is two `take` commands. If a verb follows
  AND, the parser rewinds to the word after AND and treats it as THEN, so
  `TAKE THE MAP AND GO EAST` is two sentences (verified, F62).
- A trailing second phrase is copied back into earlier records with the same
  verb: `PUT THE KEY AND THE MAP IN THE CHEST` puts both in the chest.
- A line can be answered rather than typed fresh: when the game asked a
  question, the next line completes the saved record (below).

### ALL and EXCEPT ([WordAll](../src/system.asm#L137), [WordExcept](../src/system.asm#L119))

`ALL` (or `EVERYTHING`) sets [AllStage](../src/world.asm#L92) to 1 and marks the record (`+1`
bit 7). `EXCEPT` (or `BUT`) is only accepted after ALL; it sets the stage to 2
and the nouns after it go into separate records marked with bit 6, which the
main walk skips (verified with a watch on [AllStage](../src/world.asm#L92), F20, F26). When the
command runs, [MatchSentence](../src/parser.asm#L1117) takes the objects one at a time and
[IsExcluded](../src/parser.asm#L1248) passes over those an EXCEPT record names: `TAKE ALL EXCEPT THE
CHEST` is one turn per object taken.

### IT and ONE

`IT` copies the first noun phrase of the last command matched (kept in
[PhraseBuffer](../src/messages.asm#L1060)) into the phrase being built ([L82E2](../src/system.asm#L146)): `TAKE MAP OUT OF
CHEST, EXAMINE IT` (inferred from the code). `ONE` is skipped.

### Special words that are not commands

The class 9 words are handled while the line is being parsed, not as
commands, so they take no turn ([ActionWordTable](../src/system.asm#L47), F21):

| Word | Handler | Effect |
| --- | --- | --- |
| PRINT / NOPRINT | [WordPrint](../src/system.asm#L83), [L82AF](../src/system.asm#L91) | ZX printer copy of the story on/off |
| SAVE / LOAD | [SaveGame](../src/system.asm#L574), [LoadGame](../src/system.asm#L463) | tape, [05-save-and-printer](05-save-and-printer.md) |
| QUIT | [WordQuit](../src/system.asm#L288) | the score, a key, a new game |
| HELP | [WordHelp](../src/system.asm#L308) | a hint for 11 locations, else "You're doing fine." |
| SCORE | [L83EF](../src/system.asm#L361) | `You have mastered 0.0% Of this adventure.` ([05-end-and-score](05-end-and-score.md)) |
| PAUSE | [WordPause](../src/system.asm#L439) | green border until a key |

## 3. Records to commands ([RunSentences](../src/parser.asm#L1035), [MatchSentence](../src/parser.asm#L1117))

### The command ([MatchCommand](../src/parser.asm#L1560))

The record's verb and the (up to) two prepositions found in its two phrase
blocks are compared with every record of the [CommandTable](../src/commands.asm#L21)
([MatchCommandRecord](../src/keys.asm#L714)): the verb must match, and the two prepositions must
match the record's in either order (an absent word matches anything). So
`TAKE THE MAP OUT OF THE CHEST` and `WITH THE SWORD ATTACK THE TROLL` find
their records whatever the order of the phrases (inferred from the code; the
second is one of the lines of `tests/inputs/verbs.txt`). The record number is
the command id ([CommandId](../src/messages.asm#L1064)).

- Verb known, prepositions not: `I do not know the verb " ... "`
  ([ReportUnknownVerb](../src/parser.asm#L2283)).
- A verb with no record at all (`sing`, `wait`, `sleep`): `You sing. Time
  passes...` and the turn passes (F38).

### The objects ([ResolveNouns](../src/parser.asm#L1188))

The command record says whether the command takes one or two nouns and
whether a noun is an object or a place reached by an exit (`enter`, `follow`,
`go through`). [SplitNounPhrases](../src/parser.asm#L1647) decides which phrase block is the first
noun (`GIVE THORIN THE MAP` and `GIVE THE MAP TO THORIN` both work). Then
[ResolveNouns](../src/parser.asm#L1188) walks the candidates:

1. [FindNextNamedObject](../src/objects.asm#L708) lists the objects whose name fits the noun phrase
   (noun and adjectives) and that the actor can reach ([ActorCanReach](../src/objects.asm#L779): here,
   carried, or inside an open thing that is here);
2. each candidate is tried with the **test pass** of the command itself
   ([RunCheck](../src/parser.asm#L1372)): `UNLOCK DOOR` in a room with two doors picks the door the
   verb makes sense for;
3. exactly one candidate must remain: it becomes [FirstObject](../src/messages.asm#L1067) (and the
   same for the second noun, [SecondObject](../src/messages.asm#L1070)).

What the player sees when that fails ([ExplainNounFailure](../src/parser.asm#L2070), observed, F60):

| Case | Reply |
| --- | --- |
| verb without a noun, candidates here | `EXAMINE WHAT ?` |
| verb without a noun, nothing here | `I SEE NOTHING TO TAKE` |
| noun not in reach | `I DO NOT SEE THE SWORD HERE` (or where it is, [FindNounElsewhere](../src/parser.asm#L2129)) |
| several candidates | `WHICH DOOR ?` |
| wrong kind (a place, a person for a thing verb) | `YOU CANNOT TAKE THE LONELANDS.` |
| the one candidate refused | the verb handler's own reason, run again in perform mode ([PerformRefusal](../src/parser.asm#L2103)) |

These replies appear in the input window, in capitals, under the typed line.

### Questions and answers

`WHICH DOOR ?` and `GIVE THE CURIOUS MAP TO WHAT ?` are real questions: the
record is saved ([SaveParsedRecord](../src/parser.asm#L1948)) and [AwaitingAnswer](../src/world.asm#L94) remembers which
phrase was asked about. The next line is parsed as a continuation: a bare
`RED` or `THORIN` fills in the missing words of the saved phrase
([ParseEnd](../src/parser.asm#L169)), and [RunSentences](../src/parser.asm#L1035) then runs the completed command. `@`
cannot repeat a line while a question is open.

The question for the **second** noun is broken: it prints a stray dictionary
word ("WHICH TING ?") and saves the wrong phrase offset (observed by calling
it, F61). It needs two equally good candidates for the second noun and was
not reached in play.

## Orders: SAY TO ([StoreParsedOrders](../src/system.asm#L213), [TalkToCharacter](../src/verbs.asm#L730))

`SAY TO THORIN "TAKE THE ROPE AND GO EAST"` is parsed twice. The first pass
sees `say to thorin` and, at the opening quote, the main loop has set
[InputFromOrder](../src/world.asm#L96); at the end of the words [BeginOrderPass](../src/system.asm#L173) re-runs the
parser over the quoted text with errors ignored, and [StoreParsedOrders](../src/system.asm#L213)
copies each resulting phrase record into a free order slot (8 slots, F14,
F23). Then `talk to` (command 53) runs: [TalkToCharacter](../src/verbs.asm#L730) decides how many
of those orders the character accepts:

- a character without an NPC record (or with obedience 0: the goblins, the
  warg, the dragon) accepts none;
- after Gollum has asked his riddle ([ReplyGiven](../src/world.asm#L31)), exactly one: the answer;
- otherwise a random number from 0 to the record's obedience (Gandalf 5,
  Thorin 6, Elrond 5, Gollum and the Bard 3, the elf, the butler and the
  trolls 1); 0 makes the character say `No` (F44).

Accepted slots get the character's id as owner, the others are freed
([ClaimOrderSlots](../src/parser.asm#L2304)). The orders are carried out later, in the character's
own turns ([05-characters](05-characters.md)).

## Echo

When the command is carried out it is echoed as an English sentence in the
story window by [PrintCommandSentence](../src/keys.asm#L570): "You take the rope.", "Thorin opens
the door.", "You go somewhere." in the dark. A command refused in the test
pass is echoed in the input window: "YOU CANNOT TAKE THE CHEST." (F59).
