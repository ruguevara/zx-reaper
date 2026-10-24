# Data formats and how the game works: our blind run against the references

The Hobbit v1.2, 48K. This note compares what the blind run found (ours) with
the other accounts of the data formats and of the game's design. It compares
meanings, not entry boundaries; those are in `compare-jon.md` and `compare-pob.md`.

## Sources and short names

| Name | What | Version |
| --- | --- | --- |
| **Ours** | `re/notes.md`, `re/ids.md`, `re/findings.md` (F1-F85), `re/questions.md`, `docs/01-08`, `src/*.asm` | 1.2 |
| **J** | jonsole, `notes/hobbit/*.md`, with the skool where a note points to it | 1.2 |
| **B** | basf-c60, `HowItWorks.html`, `Characters.html`, `Objects.html`, `README.md`, and the skool where needed | 1.0 (addresses about $10C-$110 lower) |
| **I** | Icemark data-format page and its linked disassembly (Chris Wild, 1998) | unnamed version; its tables are $5C below 1.2's ($AAF7 vs $AB53, $C063 vs $C007) |
| **W** | Wilderland ("CH", 2012-2019): README, `WL.h`, `dict_v12.txt`, `rooms_v12.txt`. The live page is gone (404); read from Wayback 2021-05-20 | 1.2 dumps |
| **M** | Veronika Megler, "There and Back Again: A Case History of Writing The Hobbit", Refractory 27 (2016), https://refractory-journal.com/vmegler/ | design account |
| **E** | 6elphegor, `README.md` of the C port ("The game's data", "Things found") | 1.2 |

## What I ran to settle differences

Every run is from the project root `examples/the-hobbit`, with
`tools/zxrun.py` (`../../tools/zxrun.py`) on `re/orig.z80`. The input scripts
are in [`inputs/`](inputs/). They press SPACE at frame 50 (title) and at
1453 (picture), then type.

| # | Run | Result |
| --- | --- | --- |
| R1 | `--input adv_a.txt` ("attack thorin") `--take 0x9CD2:rng_a.txt` (the values taken, a record of the game: not kept), then `--input adv_b.txt` ("viciously attack thorin") `--give 0x9CD2:rng_a.txt` (the same random values), `--dump` both | Same text, same outcome. Player +5/+6 = 64/64 and Thorin +5/+6 = 104/120 in both dumps. The adverb changes nothing. |
| R2 | `light.txt`: "light chest", "turn on chest" | "You light. Time passes..." and "You turn. Time passes...". LIGHT and TURN are dictionary verbs with no command record. |
| R3 | `pic.txt` with `--stop 0x7FA7`, then `--stop 0x969A` | The Bag End picture starts at frame 60 and its key wait comes at frame 398: 338 frames, 6.8 s. |
| R4 | `--cls 0x38 --poke 0xB701,0 --poke 0xB6FA,1 --poke 0xB702,1 --poke 0xB6EA,0 --poke 0xB6E8,0x3F --poke 0xB6FC,0x80 --poke 0xB6FD,0x06 --call 0x72DD --reg HL=0xAF20 --text 0x8822` | "you brandish your sword, but Thorin is on guard." Control code 3 prints the weapon word at $B6FC. |
| R5 | `key0.txt`: key 0 as the first key of a line | "> W", " YOU CANNOT GO WEST." |
| R6 | `with.txt`: "with the map attack gandalf"; `with2.txt` "attack gandalf with the map"; `give.txt` three orders of GIVE | "WITH THE MAP ATTACK GANDALF" gives " YOU CANNOT ATTACK THE CURIOUS MAP." (the map taken as the target). "TO THORIN GIVE THE MAP", "GIVE THE MAP TO THORIN" and "GIVE THORIN THE MAP" all give the map to Thorin. |

Static checks (Python over `re/orig.z80` / `re/image.z80`, and `scripts/text.py`):

| # | Check | Result |
| --- | --- | --- |
| S1 | State-word tables `ReasonWords1/2` ($A224/$A234) decoded with `text.py words` | Index n = flag bit n: 0 unlocked/locked, 2 empty/full, 3 -/broken, 4 off/on, 5 closed/open, 6 dead/alive. No caller found that passes 4 or $84. |
| S2 | +4 and +7 of all 61 records | +4: 0, 2 (curtain), 3 (trap door), 4 (rope), $10/$20/$40/$50 (sides), $80 (window only). +7 bit 2: barrel $84, both rivers $86, sword and torch $94. Bit 4: sword and torch only. |
| S3 | Control codes in the 177 messages, scanned item by item from $AD7D | Used: 0,1,2,3,4,6,7,9,11,12,13,14,16,17,19. Unused: 5,8,10,15,18. Code 3 is at $AF0A and $AF24. |
| S4 | Command ids with no handler in `VerbHandlers` ($C730) or any object's verb table | 18 put on, 21 take from, 41 throw, 47 cut, 52 climb. |
| S5 | Endings table $B71F and the words that use it | s, es, ies, BS+ies, d, ing. Slot 4 (d): complete, hear, place. Slot 5 (ing): approach, do, mend, morn, sing, sink, stand, star. Printed in mode 4 at $AE3F "placed", $B054 "doing", $B0EE "singing", $B156 "sinking", $B1FC "heard". |

---

## 1. Dictionary and word classes

**Agree (ours, J, W; I and M in part).**

- $6000 index by first letter, words from $6040, 5-bit letters (A = 1), bit 7
  ends a word except in byte 2 (and byte 3 after a byte 2 with bit 7).
- Class = 4 x (byte 1 bits 5-6) + (byte 2 bits 5-6). Byte 2 bit 7: the word
  takes an ending; byte 3 bits 5-7 pick it. Last byte bit 6: a two-byte
  synonym link follows.
- 562 words: 355 typed ($6040-$67AA), 207 print-only ($67AC-$6BED). W's
  statistics give the same counts, and the same class counts as J: 13 adverbs, 2 in/into,
  19 directions, 59 verbs, 2 go/run, 121 nouns, 96 adjectives, 16
  prepositions, 11 article/aux, 14 special, 1 AND, 1 THEN. Ours gives the
  same verb, noun, adjective and preposition counts.
- Synonyms: the same list in ours, J and W (READ = EXAMINE, SAY = TALK,
  CAPTURE/KILL/HIT/SLASH/SLICE = ATTACK, BREAK/SMASH = STRIKE, GET/LIFT/STEAL
  = TAKE, PICK = CARRY, EVERYTHING = ALL, BUT = EXCEPT, ME = YOU, I, L, LO,
  the direction abbreviations).
- Matching: a typed word may be any prefix of an entry; a longer typed word
  only matches an entry of 4+ letters. J measured it (INV, EXAM; MAPS fails).
- Endings in table order: s, es, ies, backspace + ies (CARRIES), d, ing.
  Ours, the J skool bytes and W's tally (S 79, ES 10, ING 8, D 3, IES 1, @IES 1)
  agree.
- I has the index, the letters and the synonym bit only ("I can't quite get my
  head around the format").
- M confirms the design: "only 5 bits are used to represent the English
  alphabet... the other 3 bits were used by Phil to encode ... speech parts ...
  valid word usages, what pattern to use when pluralizing".

**Differ.**

| Point | Ours | Reference | Settled |
| --- | --- | --- | --- |
| Endings 4 (d) and 5 (ing) | used (mode 4: "placed") | J (`leftovers.md`, `ENDINGS`): "no word asks for them, nor for 4 or 5" | **Ours.** S5: 11 print-only words use them. "You're doing fine." (HELP) and "Thorin sits down and starts singing about gold" are on screen in our runs (F21, R1). J counted the typed list only. |
| Index size | "27 words, entry 0 unused" | J "26 offsets" | Same thing, different words. |
| Last byte of the second list | $6BED | J $6BEE | One byte; $6BEE is 0. Same thing. |

**Only ours.** The 11 class-8 words by name (a, an, the, is, are, can,
cannot, that, already, another, direction). This answers J's open question
"what the eleven entries of class $8 ... are for"; W lists the same words.
Class $D, the token of an unknown word. Key 7 in mid-line types "[", which the
lookup takes as letter 27 (F79). A word of 105+ letters overwrites code (F70).

**Only theirs.** J: words within a letter are not sorted (BLOW before BLOOD),
so a lookup is a linear scan of the letter; 29 synonyms. W: the full dump,
longest word 14 letters, words in both lists (HURRY, PLACE, SING, SIT), DO and
STAR twice in list 2. E: "a word of more than 20 letters overflows the output
buffer at $74A6". Not checked here; our runs with typed words of 20, 40, 100
and 104 letters (F70) showed no damage.

## 2. Messages and their control codes

**Agree (ours, J, B; I in part).** 177 messages, $AD7D-$B6D9, 2397 bytes.
$20-$5F literal; $60-$7F one of 32 common words at $AD3D (I lists the same 32);
bit 7: a two-byte word reference with a 3-bit print mode; $00-$13 control
codes through the 23-word table $7295 (I: "only 23 entries"); $14/$15/$16 end
with new line, with full stop and new line, or silently. Codes 2 and 11 jump
and call by a signed byte, so messages share tails. Print modes: 2, 3, 6 end the
message; 4 always adds the ending; 5 never; 7 capital first letter; 1 agrees
with the object, the rest with the subject. The letters are lower case and
capitals come from the printer (J: "the messages' own capitals mean nothing").
The control-code meanings in ours and J are the same, code by code.
Both have the wine's S-to-SH lisp for five turns (timer 7).

**Differ.**

| Point | Ours | Reference | Settled |
| --- | --- | --- | --- |
| Control code 3 | `docs/06-tricks.md` lists `L738D` under "code that cannot run": "no message uses code 3" | J: `MC_INSTRUMENT_NOUN`, the instrument; I: "[weapon] ??" | **Theirs.** S3: code 3 is in the wound messages for damage 4 ($AF09, "... {3} sweeps past close to ... ear") and 2 ($AF20, "brandish ... {3}"). R4 prints "you brandish your sword". Our own `05-text-and-screen.md` table and `text.py` ({WORD2}) are right; only 06-tricks is wrong. |
| I's codes | | I: $0C "[the]"; mode 2 "end", 3 "full stop and end", but its own C code does the reverse; modes 5 and 6 "unknown" | Ours and J ran the codes with poked actors: $0C prints "his"/"your" for the subject. Mode 2 ends plainly, 3 with a full stop and new line, 5 never inflects, 6 ends with a new line. I's version may differ; its text contradicts itself on 2/3. |
| Characters of text | "about 6800 characters in 2397 bytes" | J: 611 word references (3560 characters), 413 common-word bytes (1559), 526 literals, 227 control codes: about 5600 | J's count is defined and itemised. Ours cannot be reproduced: our decoder gives 5916 characters when it follows the jumps (shared tails counted twice). |
| Entries inside messages | 5 tails ($ADA9, $ADC4, $AFB5, $B018, $B143) | J: 6, the sixth on the second byte of a word reference, read as a control code | Only J has the sixth. |

**Only ours.** 108 of 111 state-free messages print exactly the decoder's
text (F2); the self-changing message `MsgSubjIsIn` ("You are *on* ..."); the
dawn swaps location 5's description pointer. S3: codes 5, 8, 10, 15 and 18 are
never used in 1.2 (8, the backspace, has a handler but no message).

**Only theirs.** J's compression figures and `NARRATE_ACTION` described as a
sentence template. I's notes on where its version uses codes 5, 8 and $13.

## 3. The parser and sentence patterns

**Agree (ours, J; B in outline; I only the table).**

- Tokens: class nibble + 12-bit offset; $C0 ends; "." is THEN, "," is AND,
  a quote is its own token.
- A state machine dispatching on the class through $75D2 (13 handlers, the
  same table in ours and J).
- The 24-byte phrase record ("frame" in J), stack down from $B9C8: +0 verb
  (bit 7 of +1 ALL, bit 6 an EXCEPT record), +2 adverb or direction or GO,
  +4 and +$0E noun phrases of two prepositions, noun, two adjectives, laid out
  like an object's name. Ours dumped it after typed lines (F25), J watched it.
- THEN and "." end a command; AND repeats the verb; a verb after AND rewinds
  and acts as THEN. Ours (F62) and J both ran it.
- ALL/EXCEPT, IT ($B6E0), ONE ignored; 13 special words handled while
  parsing, costing no turn.
- Orders in quotes into 8 slots of 25 bytes; a line ending inside quotes
  gets "what ?" (F49, J); questions ("which door ?") keep the frame.
- The command table at $AB53: 59 x 8 bytes, id = index + 1, ids 1-10 the
  directions with GO in the fourth word. The flag nibbles: whether there is a
  first and second noun; the kind of object each may be (things and dead
  characters, living characters, any; our `AllMode`, J's `FIND_MODE`); whether
  the action is narrated (not LOOK, INVENTORY); whether it needs light;
  whether a noun is a place reached by an exit (ENTER, GO INTO); which word is
  echoed before the noun. Ours F13 and F59 decode about the same set of bits as J.
- A verb with no pattern prints "You sing. Time passes..." and costs a turn
  (F38, J). A refused command costs no turn; a refusal about a named object
  drops the rest of the line (J measured it; our turn diagram says the same).
- I: the same 59-entry table in its version, "bits 7 and 6 used to mean
  something": not decoded.

**Differ.**

| Point | Ours | Reference | Settled |
| --- | --- | --- | --- |
| Word order of the two phrases | `05-parser.md`: patterns are found "whatever the order of the phrases", example WITH THE SWORD ATTACK THE TROLL, said to be "one of the lines of tests/inputs/verbs.txt" | J (`actions.md`): "the phrase carrying the preposition the pattern wants is its instrument, wherever it came". B (v1.0): "the parser does not accept 'with the sword hit thorin' as a reordering" | **B, for this case.** R6: "WITH THE MAP ATTACK GANDALF" matches ATTACK WITH but takes the map as the target: " YOU CANNOT ATTACK THE CURIOUS MAP." "TO THORIN GIVE THE MAP" works. So the order is free for GIVE ... TO and not for ATTACK ... WITH. Ours and J overstate it. The line is not in verbs.txt. |
| What `$B70F` does | ours `AllActive`: when set, `FindNextNamedObject` skips the reach test | J `PATTERN_OPTION`: open question ("exactly how is not worked out"), though J's own `FIND_NAMED_OBJECT` text says the same as ours | **Ours.** The bit is nibble value 9 of the verb word: TAKE OFF, FOLLOW, JUMP ONTO. |

**Only ours.** The second-noun "Which ... ?" question is broken ("WHICH
TING ?", F61, run by call; E has it too). Pending orders of a refused SAY
TO leak to the next character spoken to (F73), and a ninth order writes $FF at
$B800 (F72). More than 32 tokens overwrite code (F71). E and the TASVideos
"game end glitch" are the same bug.

**Only theirs.** J: five patterns have no handler anywhere: PUT ON, TAKE
FROM, THROW, CUT, CLIMB ("i cannot do that.", measured). S4 confirms it on
1.2: ids 18, 21, 41, 47, 52. E: SAY "HELLO then @ resets the machine; a
long enough sentence builds records over the location table. Neither was
checked here.

## 4. Locations and exits

**Agree (ours, J, W; I in part; B).**

- Pointers at $B9E0 (80 words), records $BA8A-$C062, location 0 a 13-byte
  dummy.
- +0 flags: bit 7 lit, bit 6 visited, bits 1-3 the preposition from $BA80
  (outside, inside, in, on, at). W's dump labels them: $84 "light, IN", $86
  ON, $88 AT, $80 OUTSIDE, $04 "dark, IN", $08 dark AT, $02 dark INSIDE. The
  counts (48 in, 20 on, 9 at, 1 inside, 1 outside) are the same in J and W.
- +1 capacity, $FF unlimited; three limited: Bag End 160, smooth straight
  passage 176, location $2F 254 (W: A0, B0, FE).
- +2/+4/+6 name (noun, adjective, adjective), +8 description message.
- +10 exits: direction (1-10 = N S E W NE NW SE SW up down), obstacle object
  or 0, destination; $FF. W gets the obstacle meaning from its map labels.
- 26 dark locations (ours, J).
- Passage: the obstacle must be open (bit 5) or broken (bit 3); the player
  is stopped by the window's +4 bit 7; the traveller's size and load against
  the obstacle's +2; the destination must have room.
- I: bits 1-3 "prep", byte 1 "if not 0xff" (unfinished), three words and a
  message; exits not described.

**Differ.**

| Point | Ours | Reference | Settled |
| --- | --- | --- | --- |
| Exits with destination 0 | `02-data`: "Destination 0 means 'no way' (the blocked exit is zeroed)" | J: three such exits on the tape (south from the bewitched gloomy place through the black river; up through the trap door and south through the fast river from the forest river) exist so that the door or river is named as being that way. A hidden road is zeroed whole, direction too. | **J.** `InitNewGame` zeroes all three bytes of the triple (the loop at $97DB), so a blocked exit has no direction at all. Our `ids.md` lists the three, but the docs do not explain them. |
| Why $2F cannot be entered | F82: "its capacity 254 refuses the player" | J: the stone in it is size 254, so the room left is 0 (measured from both ways in) | Same thing; J's reason is the complete one (capacity minus the stone). M, quoting Wilderland: "the location is left over from testing". |
| Preposition table | $BA80: outside, inside, in, on, at | I (its version): "OUTSIDE, IN, IN, ON, AT" | Ours, J and W agree for 1.2. I's version may differ; not checked. |

**Only ours.** The "too small" message prints a word made of the obstacle's
+2/+3 bytes (F53, run). LOOK THROUGH's dark test reads location 1 (F54,
run). RUN hangs on the steep paths and in $2F (F55, F82, run). LOOK in $2F
lists phantom obstacles (F82). `WalkToExit` uses the previous move's weight
(F34, read only).

**Only theirs.** J: 205 exits, 42 one-way, every room reachable when doors are
ignored; ENTER finds a place by name among this room's exits
(`ROOM_BY_NAME`). W: rooms are not stored in number order; room 13 sends 9 of
10 exits to room 10.

## 5. Object and character records

The layout (ours F5, J, W, B; I in part) is the same everywhere: a 16-byte
head, N place bytes, a verb table. The field meanings:

| Off | Ours | J | W | B (v1.0) | E | I | Settled |
| --- | --- | --- | --- | --- | --- | --- | --- |
| +0 | N, places listed at +$10 | how many places | "#" | (places) | number of locations | blank | same |
| +1 | holder, $FF none | what holds it | MO, mother object | held by | container | id of the object it is inside | same |
| +2 | "weight"; a container's capacity; what an obstacle lets through | **size**; a container's room | **Vo, volume** | **Size** | **size** | blank | **References.** The +2 tests print "is too full" (`PutObjectIn`), "is too small for you to enter" and "is too full for you to enter" (`CheckPassage`). They sum +2 of the direct contents only. |
| +3 | "size (bulk)"; a character's carrying capacity | **weight**; what a character can carry | **Ma, mass** | **carrying capacity / weight** | **weight** | blank | **References.** `CheckCanCarry` sums +3 at every depth (`SumHeldBulk`) and prints "is too heavy to lift" or "carrying too much". |
| +4 | low nibble: "In/On/Behind/Under/Tied to the"; bits 4-6 sides; bit 7 the player cannot pass | same | "currently unknown" | same | "bits 4-7 the contains message" | blank | **Ours, J, B.** `PrintHolderRelation` does `RLCA, RLCA, AND $3C`: the low nibble x 4. S2: values 0-4, $10-$50, $80 (window). E is wrong. |
| +5 | strength | strength | St | strength | strength | blank | same |
| +6 | defence; the force needed to break it | defence | "currently unknown" | defence | defence | blank | ours, J, B |
| +7 | flags | flags | attributes | flags | attributes | "various flags" | below |
| +8-13 | name: noun, adjective, adjective | same | same | (words) | name | description words 1-3 | same |
| +14 | EXAMINE description, 0 none | its own description | not described | | | "message" | same |
| +$10 | N location ids | the places | 1L (first only) | places | | "current location" | same |
| then | verb table (id, handler); an id-0 entry runs after the entry before it; $FF | same | | own handlers | "action 0 runs every turn" | "if 0xff then object finished" | **Ours and J.** `DispatchCommand` calls the matched entry, then each id-0 entry after it (wine's DRINK then `WINE_DRUNK`). Not every turn. |

The mechanics agree everywhere. Lifting compares the thing's +3 plus
everything inside it (at any depth) with the actor's +3, then with what is
left after its load. Putting in compares +2 with the container's +2 less the
+2 of what it holds directly; an exact fit is refused. Passing compares the
actor's +2 plus its direct load with the obstacle's +2. Only our names are
swapped: our labels `SumHeldWeight` (+2) and `SumHeldBulk` (+3), the 02-data
table, 05-world, F53 and F67. F18's claim sentence ("take compares weight with
the actor's capacity (+2)") even contradicts its own evidence column. M
supports the references' reading: "a door of limited size (so you could not
pass through it while carrying too many items)".

**The flags, +7.**

| Bit | Ours | J | W | B | E | 1.2 code | Settled |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 7 | present, visible | can be seen and reached | v visible | (visible) | visible | reach; the ring clears it on the player | same |
| 6 | a character | a character | A animal | | a character | | same |
| 5 | open / active / alive | open, or can be seen into | o open | open | open | `FindClosedHolder` and `CheckPassage` test $28 (5 or 3) | **References' name.** A dead troll keeps bit 5: $68 after the dawn (our own F77). It is not "alive". |
| 4 | not explained | gives light (the name taken from W) | * gives light | on (the sword glows, the torches burn) | light | read only by `CheckDark`, on the sword | **Answered:** "on", a lit light |
| 3 | dead or broken | dead or broken | b broken (dead) | broken | broken/dead | | same |
| 2 | not explained ("full" for the barrel) | full; part of the glow | f full | full | full | FILL refuses a container that has it ("<it> is full", state $82); DRINK and EMPTY clear it; the barrel's ride sets it again; `CheckDark` requires it on the sword | **Answered:** "full" |
| 1 | liquid (`FLAG_CONSUMABLE` in constants.asm) | a liquid | F fluid | pours | liquid | | same |
| 0 | locked | locked | l locked | locked | locked | | same |

**Our README's open item, "object +7 bits 2 and 4", is answered by every
reference except I, and the 1.2 code agrees.** S1 is the strongest piece of
evidence, and it is in the program itself. The two state-word tables that
print "the door is locked" are indexed by the flag bit, and they hold "empty/full" at index 2 and
"off/on" at index 4. S2: bit 2 is set on the barrel, both rivers
(containers full of water) and the sword and torch. Bit 4 is set on the sword
and torch only. `CheckDark` ($95ED) wants bits 4 and 2 set and bit 3 clear on
object $0E, so a light must be on, full and not broken. Only the sword is
tested. The torch has the same flags but lies in two places, so it cannot be
taken, and no code reads it (ours, J). The remaining "state bits" of the
README: every +4 value in use (S2) is explained in our own 02-data; W alone
calls +4 unknown.

**Only ours.** The sign bug in `CheckCanCarry`: a capacity of 132+ refuses
small things (F67, run with pokes; E has it too). The overflow test of the sums
(F68).

**Only theirs.** Per-character tables of strength, defence, carrying limit,
side and orders (J, B). B (v1.0): +3 doubles as a character's own weight
when it is carried, so Gandalf (96) and Thorin (80) can lift Bilbo (64) and
Elrond (48) cannot. J: "two pairs share a name" (two waters, two black
waters); nothing on the tape is placed "on" anything. Our `OBJ_24` "(name not
decoded)" and the label `Obj24Wa` are the **wall** (J, W, B). Our own
`text.py words` decodes $075A as "wall"; the label generator stopped at the
ending bit.

## 6. NPC scripts and behaviour

**Agree (ours, J; B and W in outline).**

- 17 records of 7 bytes at $CACB, ending at $FF: id (0 = dormant), highest
  random entry, current step, behaviour table, obedience.
- Table key 0 means ordinary scripts; other keys are action ids of events: 15
  attacked, 29 given, 48 captured (Gandalf only).
- Step byte: low nibble the op. Bit 4: a fallback address follows. Bit 5: the
  step's own byte is zeroed after a success (Thorin's remark only). Bit 6:
  orders do not replace it.
- Ops: 0/2 action with two objects; 1/3 routine run as test then for real;
  4 bare action ($FF pause); $C switch; $E jump; $F random entry; others end.
- At most six refusals a turn; the first success ends the turn.
- The butler, Bard and the dragon are dormant until an arrival hook writes
  their id.
- Bard's rewritten step at $C9E2 is saved through $B6EB.
- The per-character behaviour is the same in ours and J (Gandalf gives the map
  and opens the door, then wanders; Thorin follows; the trolls talk, eat, then
  dawn; Gollum's riddle; the warg's attack/follow/howl loop; goblins return
  after death).
- Ours had bit 5 right from the start ("erase"). J corrected its own
  annotation from "the character leaves the story" to "the step is spent"
  (measured).
- Sides: the attack test (`CheckAttackAllowed`) and the capture test
  (`VerbCapture`) both AND the side bits. Ours and J describe the attack, B
  the capture; both uses are in the code.

**Differ.**

| Point | Ours | Reference | Settled |
| --- | --- | --- | --- |
| Obedience 0 | accepts no orders, silently | B (v1.0): "0 means the character always obeys - so the goblins, the warg and even the dragon will do what they are told" | **Ours and J.** B's own listing at $8F9E: `LD A,(IY+$06)` = 0, `JR Z,$8FC2` hands over A = 0 orders. 1.2's `TalkToCharacter` is the same. |
| Thorin's "Get us out of this one, thief !" | unreachable (F42) | J's `THORIN_CHATTER`: one of his lines | **Ours.** $A662 `CP 3`, $A667 `JP NC` takes 3 and up, so at $A66D `JP Z` never jumps. |
| NPC record | id, max, step, table, obedience | E: "id, entries, current entry, script table" | E leaves out +6. |

**Only ours.** Answers to three of J's open questions:

- Gollum's choice of line (`GollumTalks`): the carry left by `RandomUpTo`,
  and whether he holds the ring.
- The 77 bytes at $99E5 that J marks "not yet worked out" (`RunActorCommand`):
  when a character's action is announced, "appears", "Someone ...".
- "Whatever fits" takes the first object in index order. Both of us infer
  this; neither ran it.

Also: the order-slot bugs (F72, F73); a held NPC's rules (F58; J's `CAPTIVE`
says the same).

**Only theirs.**

- J, measured: a new game restores neither Bard's last order nor Thorin's
  spent remark ($C8FB still 0 after QUIT).
- J: fifty WAIT turns from the start, in which a goblin captures Gandalf, the
  warg attacks the wood elf and the elf captures the warg.
- J names Gandalf's "what's this ?" step. Ours has the step as the unnamed
  `LA4F5`, which prints `MsgWhatSThis`.
- E: `NotifyCharacter` ($95DF) reads ROM $0007 as flags when there is no second
  object. This is plausible from the code: `DispatchCommand` passes
  `Noun2Record` even when `SecondObject` is $FF. It is harmless and was not run.

## 7. Timers

**Agree (ours, J; E in outline).** Ten records of 7 bytes at $CA84: length
(copied into the count when a timer starts), count (0 stopped), routine at 0,
warning span, warning routine. Only one timer fires a turn; a second is put
back to 1. Ours ran this (F50); J read it. The arrival hooks at $C78E are the
same. The ten timers have the same lengths, spans and handlers in ours and J.
The forest is a trap (both ran it four ways; F83). The bog kills at the end
of the arrival turn (both ran it; F80). The barrel goes back to the cellar
closed and full of wine.

**Differ.** E calls +0 a "flag"; ours and J read it as the length that
starting copies into the count (timer 6 has 0 there and its count is set
directly, 2-10).

**Only ours.** `ActorArrives` writes through a stale IY. From `MoveCarried`
it changed timer 2's fire handler to $AB22 in the endgame run (F85, watched).
A timer put off by another gets counter 1 every turn (F75).

**Only theirs.** J: `BARREL_REACHES_LAKE` clears `TIMER_FIRED`, so the
barrel's arrival does not use up the turn's one firing.

## 8. Random numbers

**Agree (ours, J, E, B).**

- One generator, $9CA8. The seed is R at the title key, mixed with bytes read
  through a pointer whose high byte steps once a call. So it sweeps all 64K,
  ROM, screen and code included (F19, F63; J corrected its own "by one"; E;
  B: "reads bytes of the program itself").
- The value is halved until it is no more than 2A, then A is taken off.
  `RandomUpTo` folds it: 0 and A come half as often (F74, J measured).
- Not saved and not restored.
- The list of uses is the same in ours and J.
- B's "skews them towards the high end" is true of the signed value. Bytes
  above 2A are halved into the upper half, so `RandomSigned(10)` is
  negative only for bytes 0-9: about 1 in 25 (J), 10 of 256 rolls (F9).
  `RandomUpTo(100)` leans low instead (mean 38.9, F74). Same facts, two
  views.

**Differ.**

| Point | Ours | Reference | Settled |
| --- | --- | --- | --- |
| The rope landing in the boat | `RandomUpTo(100) < 50`, "about two times in three" (F74, measured) | J `HALF_THE_TIME`: "half and half" | Same code ($A86E); J gives the threshold, ours the frequency. With a uniform byte the chance is 154/256 = 60%. The dragon's "80 or more" is likewise 42/256 = 16%, not 20%. |

**Only ours.** Moving the code changes the numbers (shift test, F63).

**Only theirs.** J: A = 9 short at the top. M: "Phil wrote a 'true' random
number generator, experimenting with many sources of seed values". 1.2 uses a
register (R) plus a walk over memory.

## 9. Fighting

**Agree (ours, J).**

- Blow = attacker +5 + weapon +5 (capped at 255), jostled. The guard is the
  target's +6, jostled. Guard >= blow wastes the blow; blow > guard + 16 kills;
  otherwise the margin 1-16 picks a wound.
- The jostle bug: a negative spread gives 0 (ours F9, called; J measured 2000
  jostles and watched one live).
- The wear-down uses `RRCA` (F65; J measured on Thorin).
- `WOUNDS` is read one entry late: entry 0 is never used, and a margin of 16
  reads $2ADD in the ROM.
- The side bits; a friend attacked by the player leaves the player's side.
  R1 shows Thorin's +4 going from $10 to 0.
- Shooting: Bard never misses; anyone else always misses the dragon and
  misses anything else about one time in three. A hit kills.
- KILL: dead flag, "dead ..." name, drops what it holds, loses its orders and
  its slot. Goblins come back. Thorin's death breaks the key.
- A troll that eats the player dies of gluttony (F81; J measured).

**Differ.** Nothing of substance.

**Only ours.** The margin of 16 reached in normal play: "Cut seclosed.", 9
of 100 seeds bare-handed on the wood elf (F56; J only ran the message). The
weapon test of STRIKE is reversed, so striking the barrel breaks the sword and
with it the only light (F46, run). Wound 15 says "Your violent attack almost
kills you." (F66).

**Only theirs.** J: bare-hand and sword ranges against each character. A
guard of 0 makes even the dragon mortal to bare hands, one blow in 25 (read).
The deaths table adds drinking the black water (`LA244_11` in ours, missing
from our table in 05-end-and-score). The dark fall kills on the seventh fall
from 64 (measured).

## 10. Scoring

**Agree (ours, J).** Only first visits score: 14 locations, 750 in all, so the
best is 75.0%. The only increase is at $8E61-$8E65. A dark place scores only
with the sword's light, and its visited bit is not set in the dark (J counts
the five dark places; ours says "some"). Victory prints no score (F78
observed; J). 1000 prints ":0.0%" (both ran it).

**Only theirs.** J: v1.0 has the identical table, found by the score-add
pattern. W's map has "2.5%" at the Lonelands, the score of the first visit.
M does not mention scoring.

## 11. Pictures

**Agree (ours, J, B).**

- $CC00 table of 22 (location, address); streams $CC43-$F35A (about 10 KB).
- Header: border and attribute. Then $00 end, $08 move, lines (2 bytes, bit
  7), fill (3 bytes, bit 6), paint (bit 5, run bytes to $FF).
- y counts up from the bottom; the pen starts at (127, 63). Every plotted
  pixel sets its cell's ink and flips it if it equals the paper.
- 13 runs on into 31, 5 into 28.
- Day and night in the trolls' clearing (F77; J measured both).
- In the dark the picture is black but the key wait still comes.
- N held at the title turns pictures off.
- M confirms the origin: Kent Rees drew them, Phil adapted them "to make
  them easier to draw" and "quickly added a switch to turn them off".

**Differ.**

| Point | Ours | Reference | Settled |
| --- | --- | --- | --- |
| Drawing time | `04-game-loop.md`: "from a fraction of a second to a few seconds" | J measured: Bag End 6.7 s, the trolls' path 11.7 s, the Lonelands 11.5 s, 126.1 s for all 22 | **J.** R3: Bag End takes 338 frames, 6.8 s. |

**Only ours.** The size of each picture (largest $10, 778 bytes; smallest
complete $04, 124 bytes). The bit layout of a line written out
(`1 rrrr L D V`, `rr nnnnnn`).

**Only theirs.** J: the profile (`PIXEL_ADDRESS` 52%); a key pressed while a
picture draws is lost; the 9.4x fast-draw patch.

## 12. Input and the idle WAIT

**Agree (ours, J, E).**

- The game's own edge-triggered scanner: masks for the shifts and for 1, 3,
  4 and 9; key tables $8BFB and $8C23.
- One-key moves on an empty line; @ repeats the last line; shift+0 rubs out
  the line; the line holds 128 characters.
- The idle WAIT: 3000 scans, each key gives 500 back, at most 3000; set
  again at every line. Ours: 1171 frames, 23.4 s (F36, run). J: 23.4 s
  (measured, 7.8 ms a scan; ours 27,280 T-states a scan, the same).
- M: "if the player took too long in taking his next action ... the
  characters would each take another turn".

**Differ.**

| Point | Ours | Reference | Settled |
| --- | --- | --- | --- |
| Idle time | 23.4 s (F36, `04-game-loop`, `06-tricks`) | B (v1.0): "about 20 seconds"; W: "appr. 30 seconds wait cycle" | Ours and J measured it. Our own `re/questions.md` (Q5, Q23) still says "~19 s"; that text is stale. |
| Key 0 as the first key | not mentioned (`04-game-loop` lists 5-8) | J: 0 shares backspace's code with 5, so it types W; E: "0 deletes" | **J.** R5: "> W", "YOU CANNOT GO WEST." |

**Only ours.** Key 7 in mid-line types "[" (F79). Lines past 128 are cut
(F69). The word and token overflows (F70, F71).

**Only theirs.** J: shift+SPACE gives $02, which nothing uses; holding a key
through story output hangs a driver; which waits poll port $FE directly.

## 13. Screen, printer, save and load

**Agree (ours, J).**

- Rows 0-15 picture; story window rows 0-17, 42 columns of 6 pixels, new
  text on row 17; divider on row 18; input window rows 19-23, ROM font, 32
  columns.
- About 0.58 s pause per line after the first 9 (17 at the start) (F35; J
  measured 0.58-0.60 s).
- PRINT tests port $FB bit 6 and sends row 17's pixel rows itself; no ROM
  print routine.
- SAVE and LOAD: four headerless blocks ($B6EB/29, $C11B/1557, $CA84/191,
  $BA8A/1497) through SA-BYTES and LD-BYTES, then a verify; SAVE copies
  Bard's three bytes.
- A LOAD error restarts; holding BREAK at the end of a tape block crashes
  into the ROM (both ran it).
- The blocked road is kept only in the operand at $A7D1 and is not saved.
  Ours observed it with an emulated LOAD (F84); J read it.
- `ExitRestoreMode`/`ROAD_OPEN` ($B6F1) is never set.

**Only ours.** Inferred: picture 5's day or night is not saved (F77), and
pending orders survive a LOAD.

**Only theirs.** J: a new game does not restore the script bytes (Bard's
order, Thorin's spent step); `PICTURES_ON` is in block 1, so LOAD brings back
the saved game's choice; interrupts stay on through SAVE's rewind prompt with
IY at $B9C8 (harmless, measured). M: SAVE began as a debugging aid.

## 14. Memory map

**Agree (ours, J, W).** The same blocks in the same places: dictionary $6000,
code $6C00-$AB52 with tables among it, patterns $AB53, articles $AD2D, common
words $AD3D, messages $AD7D, variables $B6DA, endings $B71F, orders $B738,
frames down from $B9C8, room pointers $B9E0, prepositions $BA80, rooms $BA8A,
object index $C063, objects $C11B, verb handlers $C730, arrival hooks $C78E,
riddles $C7FC, blocked roads $C80E, scripts $C82D, timers $CA84, NPCs $CACB,
zeros $CB43-$CBFF, pictures $CC00-$F35A, zeros $F35B-$F3FF, the world copy
$F400-$FFED, the small copies at $5F00, the stack below $5EFF. W's `WL.h`
gives the same 1.2 addresses for the dictionary, rooms and objects, and
`$C12B` as "YOU_OBJ_POSITION".

**Only theirs.** J: the deepest stack seen is $5E85; `ERR_SP` still points
into BASIC's stack. I: its version's addresses (tables $5C lower than 1.2's).
B: v1.0's block is 37,888 bytes, with tables about $10C-$110 lower. M,
footnote 4, citing a Wilderland analysis: game engine 36%, text engine,
dictionary, graphics engine and parser 22%, graphics data 25%. The pictures
are 10,075 of the 40,000 bytes, which fits the 25%.

---

## Our open items against the references

| Item | Where | Answered? |
| --- | --- | --- |
| Object +7 bits 2 and 4 | README "Not explained", `06-tricks` open questions, `02-data` | **Yes.** Bit 2 full, bit 4 on/gives light (J, W, B, E). The 1.2 code confirms it: S1 (the program's own state words), S2, FILL, DRINK, EMPTY, the barrel reset, `CheckDark`. |
| "some state bits" | README | The +4 bits in use are all explained in our 02-data, and by J and B. W calls +4 unknown. |
| Command-table flag nibbles | `06-tricks`, `keys.asm` "partly known", `re/notes.md` "not decoded" | J decodes the same set of bits as ours F13/F59; neither explains more. The notes.md line is stale. |
| `Noun1Kind`/`Noun2Kind` "not decoded" | `objects.asm` `CheckNounsDistinct` | Already answered by our own F13, and by J: the noun is a place (ENTER, GO INTO). The self-test is skipped because a location id may equal an object or actor id. The comment is stale. |
| `OBJ_24` "(name not decoded)", `Obj24Wa` | `constants.asm`, `world.asm` | The wall (J, W, B); our `text.py` decodes it too. |
| Picture 5 zeroed, "reason unknown" | `main.asm` line 86, `re/notes.md` | Answered by our own F77 and by J: night colours restored. Stale comments. |
| "$C12B ... poking did not move the player: not understood" | `re/notes.md` (Pictures) | Stale. $C12B is the player's location byte (+$10). W's teleport writes it, and our F80-F83 poke it. |
| $793D variables, "$C730/$C2xx handler tables" | `re/notes.md` | J names $793D/$793E as the target and instrument search flags (bit 0 named, bit 1 found); ours F48 explains the counts. $C730 is `VerbHandlers` (02-data). Stale lines. |
| $B704 "exact role" | `re/notes.md` | The capital-next flag: our F28 and J's `CAPITAL_NEXT`. Stale. |
| $ADDA, a bare $14 | `re/notes.md`, `06-tricks` | J has it as `MSG_CODES_ONLY` with no use either. Still open. |
| Q16: which code is dead | `re/questions.md` (partial) | J lists six stretches nothing reaches: $78FB (a third entry into the copy), $9030 (let go), $92E8 ("the ... is broken"), $A1AE, $A536 (an OPEN for the wood elf alone), $A70A (wipe an exit). `zxq.py refs` finds no reference to $78FB, $9030, $92E8, $A536 or $A70A in ours either, so these are dead, not merely unreached. Ours adds the Thorin branch (F42), the not-a-special-word exit and $ADDA. Ours must drop `L738D` from the list (§2). |
| The ring's strength overflow | `06-tricks` | Not answered (B only states the /4 while worn). |
| Q5 and Q23, "~19 s" | `re/questions.md` | Stale against our own F36 (23.4 s). |

Open questions in J that ours answers: the class-8 words (§1); what `$B70F`
does (§3); Gollum's choice of line and the $99E5 bytes (§6). J's leftover
claim about endings 4 and 5 is wrong (§1).

## Design facts from Megler's paper (and W, B) against the 1.2 code

| M says | 1.2 | Verdict |
| --- | --- | --- |
| Megler wrote the engine, "physics" and data; Phil Mitchell the parser ("Inglish") and the port; assembler on a TRS-80 look-alike, "approximately 40k" | a 40,000-byte block; the names ANIMACTION and INGLISH are in our docs too | consistent |
| Three databases: locations, objects, characters, "just a collection of records with a given structure" | rooms, the 61 object records, the NPC table | confirms |
| A location has "for each direction, a pointer to the location reached. There could also be an override routine" | exits are plain (direction, obstacle, destination) triples; the special cases are the obstacle objects' handlers and the arrival hooks | design kept; the mechanism changed |
| The Goblin's Dungeon: an override "randomly picks a 'next location'" | fixed exits; the only random moves are moving in the dark and RUN | **contradicts** (not in 1.2) |
| Objects have "weight, size"; picked up "by something bigger and stronger", put into a container "if there was enough room left" | +3 weight against the carrier's +3; +2 size against the container's room | confirms, and settles our swapped names (§5) |
| A door "of limited size (so you could not pass through it while carrying too many items)" | `CheckPassage`: the actor's +2 plus its load against the door's +2 | confirms |
| Containers "transparent or opaque" | no separate bit: bit 5 (open) is the see-into test, and it is set from the start on the wall, the cache, the boat, the rope and every character | partly |
| A general "turn on" routine for lamps, overridable for a magic lamp | LIGHT and TURN are verbs with no pattern (R2); the state word "on/off" sits at flag bit 4 and is never printed (S1); the torch has the sword's light flags but is never tested; only the sword lights | the lamp design was cut down to the sword (inferred) |
| NPCs are objects that begin "alive" and can stop being alive | the same record; dead = bit 3; bit 5 is not "alive" (§5) | confirms |
| A character is "a set of actions ... a sequence ... a frequency of repetition"; a step may branch or "jump to a random location in the sequence" | script ops $E (jump), $F (random entry up to +1), fallbacks | confirms |
| Gandalf: "[go]. [Pick up] [Say, "what's this?"]. [Go]. [Put down]." | `ScriptC8C2`: run, take, "What's this?" (`LA4F5`), close, give; `ScriptC8D0`: run, drop | confirms almost word for word; "what's this" is its own step, not an override of TAKE |
| The troll: "if no alive object [go] else [kill]" | the trolls never move: they talk, eat a player who stays, and turn to stone at dawn; they attack only when attacked | **contradicts**: changed toward the book |
| Thorin's "short character-action list"; "Thorin sits down and starts singing about gold" | follow, take the key, ask for the thief, chatter ($B0E5) | confirms |
| The friendly dwarf turns violent "once he'd been attacked (or picked up)" | Thorin's table reacts to 15 (attack) and 29 (give) only. He weighs 80, more than the player can carry (64) | attack: confirms; picked up: not in 1.2 |
| "At the beginning of the game, we would generate, for each NPC, a random starting point in that NPC's action list" | a new game copies the NPC records back from the backup, and `InitNewGame` only picks the road and the riddle; Gandalf always starts by giving the map | **contradicts** (not in 1.2) |
| "viciously kill" would attack harder and use more strength | the adverb is stored at +2 of the frame and no routine reads it; R1 gives identical results | **contradicts** (not in 1.2) |
| A dead dwarf can be a weapon, weaker than a sword | any carried single-place object adds its own +5; there is no special case | consistent, generic |
| NPCs act after the player, "each (remaining) alive character" | `EndOfTurn`: the victory test, the 17 slots in order, then the timers | confirms |
| The player is "merely another character" | record 0; the same `DispatchCommand` and sentence builder for everyone | confirms |
| NPCs "would do to each other almost anything"; battles draw in newcomers | bare attack and capture steps take anyone in reach not on their side; attacked characters switch to "attack, else follow, else run" | confirms; J saw a goblin capture Gandalf and the warg fight the elf in 50 WAIT turns |
| "only actions in the current location were printed" | the `OutputEnabled` gate on `ActionPerform` and `MessagesVisible`; W's log window catches the hidden NPC text at $858B | confirms |
| Randomness "a key feature"; a "true" generator after many seed sources | R at the title key plus a walk over all memory | confirms |
| 5-bit letters plus 3 bits for parts of speech, usage and plural pattern; messages built from the dictionary and sentence templates | §1 and §2 | confirms |
| The dictionary size traded against bug fixes, "synonyms ... would sometimes decrease" | 29 synonyms in 1.2 (J) | consistent; not checkable |
| "This room is too full for you to enter", "left over from testing" | location $2F: capacity 254, the stone 254, no exits | consistent with ours (F82) and J |
| "the game could crash because of something that happened in another location" | F85 (a stale IY rewrites timer 2's handler during an NPC move, watched); E's crashes; F70 and F71 | consistent |
| Pictures added late, then a switch to turn them off | N held at the title (`PicturesEnabled`) | confirms |
| No "notion of variable travel time" | every move is one turn | confirms |

---

## Summary

| Topic | Agree | Differ | Only ours | Only theirs |
| --- | --- | --- | --- | --- |
| Dictionary, word classes | format, 355+207 words, class counts, synonyms, matching, ending order | endings 4 and 5: J says unused, **ours right** (S5) | class-8 words named; unknown-word token; "[" key; long-word overflow | J sort order, synonym count; W full dump and oddities |
| Messages, control codes | bytecode, 23 codes, modes, tails, 177 messages / 2397 bytes | code 3: our 06-tricks says unused, **theirs right** (R4, S3); I's $0C and modes 2/3/5/6 (ours and J right); character count (J's defined, ours not reproducible) | 108/111 checked by run; patched message; codes 5, 8, 10, 15, 18 unused | J compression counts; sixth mid-message entry |
| Parser, patterns | tokens, class dispatch, 24-byte frame, AND/THEN, ALL/EXCEPT, IT, orders, command table and its flags | phrase order: ours and J "any order", **B right** for WITH-first (R6); $B70F: ours explained, J open | "WHICH TING", order-slot leaks, token overflow | five patterns with no handler (J; S4 confirms); E's SAY+@ and long-sentence crashes |
| Locations, exits | record, flags, prepositions, capacity, exits, 26 dark | destination-0 exits (**J right**); $2F reason (J complete) | F53, F54, F55, F82, F34 bugs | J exit counts, one-way exits, `ROOM_BY_NAME`; W dump |
| Object and character records | layout and mechanics of every field | +2/+3 names: **references right** (the game's own messages); +4 nibble (E wrong); id-0 handlers (E wrong); bit 5 "alive" (references' "open" right) | sign and overflow bugs of the sums | **bits 2 (full) and 4 (on/light) explained** by J, W, B, E, confirmed by S1/S2; wall's name; per-character tables |
| NPC scripts | record, ops, bits, events, dormant slots, Bard, per-character behaviour | obedience 0 (B wrong); Thorin's line (J wrong); E's record misses +6 | Gollum's line choice, $99E5, order bugs | scripts not restored by a new game (J measured); 50-turn run; $95DF null read (E) |
| Timers | table, ten timers, one firing a turn, forest, bog, barrel | +0 "flag" (E) | F85 stale IY, F75 edges | barrel ride clears the firing flag (J) |
| Random numbers | generator, seed, page walk, fold, uses | rope odds: threshold (J) vs measured 2/3 (ours) | relocation changes numbers | J A=9 skew; M on seeds |
| Fighting | formula, jostle bug, RRCA wear, wound table off by one, sides, shooting, KILL | none | "Cut seclosed." in play, reversed weapon test, wound 15 | per-character ranges, black-water death, seven falls |
| Scoring | 14 places, 750, ":0.0%", no score on victory | none | | v1.0 same table (J) |
| Pictures | format, sharing, day/night, dark, N key | drawing time: **J right** (R3: 6.8 s) | sizes per picture | profile, fast-draw patch |
| Input, idle WAIT | scanner, keys, @, 3000 scans + 500, 23.4 s | key 0 first types W (**J right**, E wrong, ours silent); B 20 s, W 30 s, our Q5/Q23 19 s stale | "[" key, line cut, overflows | shift+SPACE, driver hang |
| Screen, printer, save/load | layout, pause, PRINT on port $FB, four blocks, BREAK crash, road not saved | none | picture 5 and orders across LOAD | script bytes not restored, pictures flag in block 1, interrupts during SAVE |
| Memory map | all blocks | none | | J stack depth and ERR_SP; I and B other versions' addresses; M size split |

Counts across the 14 topics: we agree on the formats almost everywhere.
Ours is wrong or stale on eight facts: the +2/+3 names, the bit 5 name,
control code 3, the phrase order, destination-0 exits, picture drawing time,
key 0 (left out), and the idle time in questions.md. A reference is wrong
and ours right on six: J's endings 4/5, J's Thorin line, B's obedience 0,
E's +4 nibble, E's id-0 rule and I's code $0C. E's key 0 is wrong too, but
ours says nothing there. Ours answers four of J's open questions ($B70F, the
class-8 words, Gollum's line, $99E5). The README's open item, +7 bits 2 and
4, is answered: full and on.
