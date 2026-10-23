# 2. Data structures

The game is data-driven: words, messages, places, things, characters, their
scripts and the timers are all tables, and the code is a small set of
interpreters over them. This file gives the layouts; the chapters 05 explain
how each table is used.

All words and addresses are little-endian. "Phrase code" and "word token"
below are the same 16-bit shape: a dictionary offset in the low 12 bits and a
4-bit tag in the top nibble.

## Words

### Dictionary ([Vocabulary](../src/dictionary.asm#L12), `$6000`) (verified, F1)

| Part | Layout |
| --- | --- |
| `$6000` | 27 words: entry *n* is the offset (from `$6000`) of the first word that starts with letter *n* (A = 1 ... Z = 26; entry 0, X and Z are 0) |
| `$6040-$67AA` | group 1, the words the player can type, sorted by first letter |
| `$67AC-$6BED` | group 2, words used only by messages (class 0) |

A word is 3 or more bytes. Bits 0-4 of each byte are a letter (1 = A ... 26 =
Z; 0 prints nothing). Bit 7 marks the last byte, except that byte 2 is never
the last and byte 3 is not the last when byte 2 has bit 7.

| Bits | Meaning |
| --- | --- |
| byte 1 bits 5-6, byte 2 bits 5-6 | word class = 4 x (byte 1) + (byte 2), see below |
| byte 2 bit 7 | the word takes an ending; byte 3 bits 5-7 index [WordEndings](../src/world.asm#L109): `s`, `es`, `ies`, back-space + `ies`, `d`, `ing` |
| last byte bit 6 | synonym: two more bytes hold the offset of the word it stands for (`get` -> `take`, `n` -> `north`) |

| Class | Words (typed group) |
| --- | --- |
| 0 | adverbs: carefully, quickly, please...; also `i`, `l`, `lo`, `u` (synonyms of inventory, look, up) and all of group 2 |
| 1 | in, into |
| 2 | the ten directions and their abbreviations |
| 3 | 59 verbs (attack, take, give, say...) |
| 4 | go, run |
| 5 | 121 nouns |
| 6 | 96 adjectives |
| 7 | 16 prepositions: across, at, from, of, off, on, out, through, to, with... |
| 8 | a, an, the, is, are, can, cannot, that, already, another, direction |
| 9 | all, everything, except, but, it, one, help, load, save, quit, score, pause, print, noprint |
| 10 | and (also the comma) |
| 11 | then (also the full stop) |
| 12 | end of the typed line (token only) |

The parser's **word token** is that class in the top nibble and the offset in
the other 12 bits ([ReadTypedWord](../src/keys.asm#L127)). A typed line becomes up to 32 tokens in
[ParsedWords](../src/keys.asm#L437) (`$709C`), see [05-parser](05-parser.md).

### Messages ([`messages.asm`](../src/messages.asm), `$AD7D-$B6D9`) (verified, F2)

177 messages back to back, a bytecode read by [PrintMessage](../src/printer.asm#L112):

| Byte | Meaning |
| --- | --- |
| `$00-$13` | control code, called through [ControlCodeTable](../src/printer.asm#L8): names of the subject and objects, "his/your", "is/are", jumps and calls to other messages |
| `$14`, `$15`, `$16` | end with a new line / with a full stop and a new line / silently |
| `$20-$5F` | a literal character |
| `$60-$7F` | one of 32 common words ([CommonWordTable](../src/commands.asm#L103): a, and, are, at, the, you...) |
| `$80-$FF` + 1 byte | a dictionary word: bits 0-11 offset, bits 12-14 print mode (ending rules, capital) |

The full format is in [05-text-and-screen](05-text-and-screen.md).

### Name phrases

Locations, objects and characters are named by up to three phrase codes:
noun, adjective, adjective (printed adjectives first). The top nibble of a
phrase code is a style: bit 7 marks a proper name (no article, capital
letter: "Gandalf"); `$87A8` is "you", the player's name.

## The command table ([CommandTable](../src/commands.asm#L21), `$AB53`) (inferred, F3, F13, F59)

59 records of 8 bytes; the command id is the index + 1 (1-59); a zero word
ends the table. Ids 1-10 are the ten moves and are also the direction numbers
used in exits (1 N, 2 S, 3 E, 4 W, 5 NE, 6 NW, 7 SE, 8 SW, 9 up, 10 down).

| Offset | Size | Meaning |
| --- | --- | --- |
| +0 | 2 | verb word (for 1-10 the direction word); top nibble: flags |
| +2 | 2 | first preposition (0 none); top nibble: flags |
| +4 | 2 | second preposition (0 none); top nibble: flags |
| +6 | 2 | word printed before the verb (`go` for 1-10, else 0); top nibble: flags |

The four flag nibbles are packed into two bytes, StateB71D and StateB71E
([PackCommandFlags](../src/keys.asm#L502)); known bits: the command takes a first / second noun,
a noun is a place reached by an exit (`enter`, `follow`) rather than an
object, the command needs light, it prints no sentence (look, inventory),
which preposition goes before the noun when the command is echoed ("take
**off** the cloak"). The list of all 59 records is printed by
`python3 scripts/text.py verbs`.

## Phrase record (24 bytes, the phrase stack at `$B9C8` downwards) (verified, F25)

What [ParseLine](../src/parser.asm#L30) builds from one clause, and what an order slot stores.

| Offset | Size | Meaning |
| --- | --- | --- |
| +0 | 2 | first command word (the verb; for `go north` the direction); +1 bit 7 ALL typed, bit 6 a record holding the nouns after EXCEPT |
| +2 | 2 | second command word (`go` in `go north`, or an adverb) |
| +4 | 10 | phrase block A: preposition, preposition, noun, adjective, adjective |
| +$0E | 10 | phrase block B: the same, for the second noun phrase |

## Location record ([Loc00None](../src/world.asm#L286), `$BA8A`; address table [LocationTable](../src/world.asm#L179)) (verified, F4)

80 records of variable length, id = index in [LocationTable](../src/world.asm#L179).

| Offset | Size | Meaning |
| --- | --- | --- |
| +0 | 1 | flags: bit 7 lit (outdoors; clear in caves), bit 6 visited, bits 1-3 the preposition of "You are *in*/*on*/*at*..." ([LocationPrepositions](../src/world.asm#L265)) |
| +1 | 1 | capacity: total weight of objects that can lie here, `$FF` unlimited |
| +2 | 6 | name: noun, adjective, adjective (phrase codes) |
| +8 | 2 | description message, 0 = print the name |
| +10 | 3n+1 | exits: direction (1-10), obstacle object id (0 none), destination; `$FF` ends |

Location 0 is a dummy. Destination 0 means "no way" (the blocked exit is
zeroed, [05-world](05-world.md)).

## Object and character record (`$C11B`; id table [ObjectTable](../src/world.asm#L1061)) (verified, F5)

61 records: the player (id 0), objects `$01-$2B`, characters `$3C-$4C`.
The full id lists are in [`re/ids.md`](../re/ids.md).

| Offset | Size | Meaning |
| --- | --- | --- |
| +0 | 1 | N, the number of places listed at +`$10` (1 for anything portable; 2-8 for doors, rivers, webs seen from several places) |
| +1 | 1 | holder: the id of the object or character it is in or held by; `$FF` = lies at its location |
| +2 | 1 | weight; for a container the weight it can hold; for an obstacle the weight that can pass |
| +3 | 1 | size (bulk); for a character the size it can carry |
| +4 | 1 | state: low nibble picks "In the / On the / Under the / Behind the / Tied to the" for its contents; bits 4-6 "sides" (characters that share a bit do not fight); bit 7 an obstacle the player cannot pass |
| +5 | 1 | strength (attack) |
| +6 | 1 | defence (and, for breakable things, the force needed to break them) |
| +7 | 1 | flags: bit 7 present/visible (cleared for the player while the ring is worn), 6 character, 5 open/active/alive, 3 dead/broken, 1 liquid (vanishes when poured out), 0 locked; bits 2 and 4 are set on the light source and a few others (meaning partly unknown) |
| +8 | 6 | name: three phrase codes |
| +14 | 2 | description message for EXAMINE, 0 = none |
| +`$10` | N | location ids |
| +`$10`+N | 3k+1 | verb table: (command id, handler) records, `$FF` ends; a record with id 0 is called after the one before it, for every verb |

The player starts with weight 16, carrying capacity 64, strength 64 and
defence 64 ([Chr00Player](../src/world.asm#L1202)); the dragon has strength and defence 192.

## Character (NPC) record ([NpcStates](../src/world.asm#L2840), `$CACB`) (inferred, F6, F44, F51)

17 records of 7 bytes, `$FF` ends. A record with id 0 is a dormant slot,
filled in by an event (the butler, the Bard, the dragon).

| Offset | Size | Meaning |
| --- | --- | --- |
| +0 | 1 | character id (0 = dormant, the script is not run) |
| +1 | 1 | highest entry of the behaviour table that a random choice may pick |
| +2 | 2 | current script address |
| +4 | 2 | behaviour table: (id, script) records, `$FF` ends; id 0 = default scripts, other ids = command ids of events (15 attack, 29 give, 48 capture) |
| +6 | 1 | obedience: how many SAY TO orders the character may accept (0-6) |

The script bytecode is in [05-characters](05-characters.md).

## Timer record ([Timers](../src/world.asm#L2762), `$CA84`) (verified, F7, F50)

10 records of 7 bytes, `$FF` ends.

| Offset | Size | Meaning |
| --- | --- | --- |
| +0 | 1 | start value; a handler that starts the timer copies it to +1 |
| +1 | 1 | counter, counted down once per turn; 0 = stopped |
| +2 | 2 | handler called when the counter reaches 0 |
| +4 | 1 | tick threshold, 0 = none |
| +5 | 2 | handler called on every turn that leaves the counter between 1 and the threshold |

## Order slot ([OrderSlots](../src/world.asm#L129), `$B738`) (inferred, F14)

8 slots of 25 bytes: the owner (a character id; 0 free, `$FF` being filled)
and a 24-byte phrase record, the parsed text of one order given with SAY TO.

## Other tables

| Table | Records | Meaning |
| --- | --- | --- |
| [VerbHandlers](../src/world.asm#L2132) `$C730` | (command id, handler) | default handler of a verb when the object has none of its own |
| [ArrivalHandlers](../src/world.asm#L2201) `$C78E` | (location id, routine) | run when the player arrives: starts timers, wakes characters |
| [RandomEvents](../src/world.asm#L2281) `$C7FC` | 4 x (answer word, message) | the riddle Gollum asks, chosen at the start (two riddles, each twice) |
| [BlockedExits](../src/world.asm#L2299) `$C80E` | 5 x (location, exit address, saved exit) | one of these exits is removed at the start until Elrond reads the map |
| [FirstVisitScores](../src/verbs.asm#L212) `$8D6E` | 14 x (location, word) | points for the first visit, in tenths of a percent |
| [HintTable](../src/system.asm#L335) `$83CD` | 11 x (location, message) | the answers to HELP |
| [WoundMessages](../src/verbs.asm#L1057) `$9226` | 16 message addresses | the fight messages by damage |
| [RecordTable](../src/handlers.asm#L419) `$A49C` | 6 x 6 bytes | home location and name of each goblin, for its return after death |
| [PictureTable](../src/pictures.asm#L16) `$CC00` | 22 x (location id, address) | the location pictures |
| [ActionTable](../src/parser.asm#L87) `$75D2` | 13 handlers | parser action per word class |
| [ActionWordTable](../src/system.asm#L47) `$8271` | 13 words + 13 handlers | the class 9 words (ALL, SAVE, QUIT...) |
| [ControlCodeTable](../src/printer.asm#L8) `$7295` | 23 handlers | message control codes |
| [ArticleTable](../src/commands.asm#L88) `$AD2D` | 2 x 4 words | "the a an some", and "the the the some" for echoed commands |
| [KeyTable](../src/devices.asm#L202), [ShiftKeyTable](../src/devices.asm#L217) | 40 bytes each | ASCII by key position |
| [Font](../src/screen.asm#L660) `$8822` | 96 x 8 bytes | the story window font |

## Main variables

| Name | Address | Meaning |
| --- | --- | --- |
| [CommandId](../src/messages.asm#L1064) | `$B6E7` | the command being run (1-59) |
| [FirstObject](../src/messages.asm#L1067), [SecondObject](../src/messages.asm#L1070) | `$B6E8`, `$B6E9` | its two nouns, `$FF` = none |
| [Subject](../src/messages.asm#L1072) | `$B6EA` | who does it: 0 the player, else a character id |
| [ActionPerform](../src/world.asm#L33) | `$B6FA` | 0 = test pass (only check), 1 = real pass |
| [ActionAllowed](../src/world.asm#L35) | `$B6FB` | result of the test pass, 0 = refused |
| [MessagesVisible](../src/world.asm#L47) | `$B702` | 0 while a character acts out of the player's sight |
| [RawOutputFlag](../src/world.asm#L45) | `$B701` | 1 = print in the input window |
| [Score](../src/world.asm#L29) | `$B6F7` | word, tenths of a percent |
| [PlayerLocation](../src/world.asm#L25) | `$B6F5` | copy of the player's location, set each turn |
| [ParserFlag](../src/world.asm#L53) | `$B705` | the typed line has sentences left |
| [ParserWordCount](../src/world.asm#L55) | `$B706` | phrase records parsed; `$FF` before the first line |
| [AwaitingAnswer](../src/world.asm#L94) | `$B71A` | a question ("Which key ?") waits for its answer |
| [InputFromOrder](../src/world.asm#L96) | `$B71B` | 1 while the text of an order is parsed |
| [PicturesEnabled](../src/world.asm#L57) | `$B707` | 0 when N was held at the title |
| [RandomSeed](../src/world.asm#L76) | `$B70E` | the random number state |
| [ActorRecord](../src/world.asm#L74) | `$B70C` | record of the character acting now |
| [Noun1Record](../src/world.asm#L70), [Noun2Record](../src/world.asm#L72) | `$B708`, `$B70A` | records of the two nouns |
