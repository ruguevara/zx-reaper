# Names, meaning and boundaries: ours vs jonsole (pobtastic in brief)

Sources: the per-entry pairs and the structural reports written by `tools/zxcompare.py` (our `build/game.skool` against jonsole's and pobtastic's skool files; see [../comparison.md](../comparison.md)), our `build/game.sym`, jonsole's `hobbit.skool`.

## 1. Meaning

506 entry addresses have an entry on both sides (292 code/code, 211 data/data, 3 code/data).

| Verdict | Count |
| --- | ---: |
| Same (title and description share most words; includes about 125 message strings and 40 pictures) | 273 |
| Same thing, different words | 201 |
| Differs (checked, below) | 6 |
| Differs in scope or emphasis only | 2 |
| One side unknown (ours) | 24 |
| One side unknown (jonsole) | 0 |

How the split was made: "same" versus "different words" is a word-overlap threshold (0.5 on title, label and first description) over the whole pairs file, so those two numbers are approximate (plus or minus 20). I read every code title pair and every data title pair by eye. The "differs" and "unknown" rows are individual judgements, not a threshold. I found no case where jonsole is clearly wrong and we are right on meaning. Where we are ahead is detail, not meaning (flags, registers, instruction comments: 34% of instructions commented against 15%).

"One side unknown (ours)": 23 entries are titled only "Command handler (via $C730)" or "Handlers (via ...)", plus `$977C`, "Wound/score helper". Together the 23 generic entries are 2185 bytes, 837 instructions, 14 with a comment. They are the verb handlers `$8CE0-$9404` and the whole handler region `$A244-$AB4F` (jonsole names about 60 handlers there). Examples: `$A9E5` is one entry that holds 19 handlers (Elrond's lunch, the side door, the magic door, the wine, the spider eyes). We did not work out what they do.

### Differs: who is right

| Addr | Ours | Jonsole | Verdict |
| --- | --- | --- | --- |
| `$8315` | `StoreParsedOrders`: "handle the end of the typed words" | `SPECIAL_QUOTE`: special word slot 0, a quote mark | Differs; jonsole right. Mechanism (stores the orders of a SAY TO line) is the same in both, but the trigger is the quote mark, not the end of the line. Run: `zxrun.py re/orig.z80` with `tests/inputs/verbs.txt` lines 1-31 then `say to thorin "give map to me"`, `--map`: `$82FD` and `$8315` execute. Without the quotes (`say to thorin give map to me`) neither executes. |
| `$9CE8` | `SumHeldWeight`: sums weight (+2) directly held | `SIZE_HELD`: sums sizes of what is held directly | Differs; jonsole right. Record field +3 is the carry limit (player $40; doors $FF so they cannot be lifted); field +2 is the container capacity (player record `01 FF 10 40`). Our own `CheckCanCarry` ($8CF1) tests field +3 and prints "is too heavy to lift", yet we call +3 "bulk". Our F18 and F53 repeat the swap. |
| `$9CED` | `SumHeldBulk` (+3, "size"), recursive | `WEIGHT_HELD`, recursive | Same swap as above; jonsole right. The recursion and the B=0/1 split are described the same by both. |
| `$71F3` | `MatchCommandRecord`: match a command table record (verb + two prepositions) | `NAME_MATCHES`: does a typed name fit an object's name | Differs in scope; jonsole more complete. The routine is called from `$7B9E`, `$9DD9` and `$9EA0`, so it matches object names (noun + two adjectives) as well as action patterns. We only describe the first use. Its callee `$722E` is described the same by both. |
| `$A20B` | `IdList`: "five record ids", defined as 3 bytes, with `$14,$2C` put into the next table | `SECOND_FIRST`: five action codes (DROP IN, PUT IN, PUT ON, TAKE OUT OF, THROW THROUGH) | Differs; jonsole right. They are action codes, not record ids, and the list is 5 bytes (`$A20B-$A20F`). Our reader `$A1D0` (`IsPlacingCommand`) already treats them as commands. |
| `$AF82` | `MsgLandsBoatButSlidesOut`, title "Lands in the boat." | `MSG_BUT_SLIDE_OUT_AGAIN`, "{sub-message} but slide out again" | Differs; ours is a copy of the `$AF8B` title. Label is right, title wrong. |
| `$711A` | `StartPerform`: sets the perform flag, clears the blocked flag, narrates | `NARRATE_REFUSAL` | Same code, same bytes; we describe the mechanism, jonsole the caller's purpose (`$7DBC`). Emphasis only. |
| `$9B93` | `NextObject`: step through the object table | `NEXT_EXIT`: step a three-byte list; shared with exit lists | Jonsole more complete: `$9C41`, `$9EA0`, `$9F08`, `$9F2D` call it for exits, where bytes 1-2 are not an address. |

### Representative pairs

| Addr | Ours | Jonsole | Verdict |
| --- | --- | --- | --- |
| `$6C00` | `GameStart` | `START` | same |
| `$6DD6` | `ReadLine` | `READ_LINE` | same |
| `$6F47` | (no label) "look up the typed word in the dictionary" | `MATCH_WORD` | same meaning; we have no label |
| `$7858` | `PreviousRecord` "go back to the previous phrase record" | `NEW_SENTENCE_FRAME` "move on to a new frame" | same thing, different words (older/newer is the direction of the parser's frame stack) |
| `$7960` | `RunSentences` | `OBEY` | same |
| `$90D2` | `EndGame` | `PLAYER_DIES` | same; both name the `$90DF` entry (wait for a key) |
| `$9BDD` / `$9C17` | `MoveCarried` / `MoveContents` | `MOVE_CONTENTS` / `MOVE_HELD` | same meaning; the two names are swapped between the sides |
| `$A0BA` | `GetIdWord` (id to dictionary word, includes state words via `$A0BD`) | `DIRECTION_WORD` + `WORD_FROM_TABLE` | same code; jonsole names the direction use, we give the wider one |
| `$C7FC` | `RandomEvents` (we describe the Gollum use in the text) | `RIDDLES` | same data; jonsole's name is the specific one |
| `$7574` | `SavedHL` ("workspace of the action dispatcher") | `AND_TOKENS` ("PARSE_AND's checkpoint") | same bytes; "action dispatcher" is our name for the parser, jonsole's is the right scope |
| `$8271` | `ActionWordTable` | `SPECIAL_WORDS` (ALL, EXCEPT, IT, PRINT, QUIT, HELP, the quote) | same table; "action" is a misnomer in ours (same for `$75D2` `ActionTable` and `PARSER_CLASSES`) |
| `$C80E` | `BlockedExits` | `HIDDEN_ROADS` | same; jonsole adds the place names |
| `$792F` | `PrintWhat`: message only, "sentence not finished" | `QUOTE_LEFT_OPEN` | same code; jonsole has the cause (a quote left open) |
| `$A9E5` | "Handlers (via $C9A1) ... to the end of the code region" | `ELROND_GIVES_LUNCH` and 18 more | one side unknown |
| `$977C` | "Wound/score helper" | `KILL_TARGET` | one side unknown |

Names and meaning differ much less than the statistics suggest. Message strings (about 125), pictures (about 40) and tables agree. Our data labels are the CamelCase of the same text as jonsole's.

## 2. Entries one side has and the other lacks

Code entries only in jonsole: 62. Every one of them lies inside one of our entries and every address has a label of ours.

| What | Count |
| --- | ---: |
| Our label with a real name (`ParseThen`, `ParseAdverb`, `ParseVerb`, `ParsePreposition`, `ParseAdjective`, `ParseNoun`, `StoreFirstPhraseBlock`, `StoreRecordWord`, `PrintWhat`, `EmptyHolder`, `PrintEndingWord_1`, `MessageJump_1`) | 12 |
| Our label is a placeholder (`LA244_0`, `L9404_5`, ...) | 50 |
| Inside the merged handler entries `$8CE0-$9500` and `$A244-$AB4F` | 46 |
| Not found at all (merged or missed) | 0 |

So these are our labelled entry points inside larger entries, not routines we merged or missed. The effect is that the handlers have an entry point but no entry, title or description each: jonsole gives each its own entry.

Code entries only in ours: 17. Jonsole labels 15 of these addresses as entry points inside its entries (`$6C27 NEW_GAME`, `$6D13 MAIN_LOOP`, `$6DA2 UNKNOWN_WORD`, `$73FC HIS_OR_YOUR`, `$7428 NAME_WITH_ARTICLE_IS`, `$785F CLEAR_ALL_EXCEPT`, `$7D90 SAY_NOW`, `$7DF5 SAY_WHY_NOT`, `$7DFE TROUBLE_AS_PLACE`, `$82B3 SPECIAL_WORD_DONE`, `$8DAB MOVE_ACTOR`, `$8E12 MOVE_THERE`, `$8F3E GO_BY_EXIT`; `$7E30` has none; `$78FB`, `$A1AE`, `$A536` are its UNREACHED_* data entries). A boundary convention, not a disagreement.

Data entries: ours 261, jonsole 418, 251 in both. About 163 jonsole entries we lack: about 80 location records (`ROOM1` ... `ROOM79`) and about 65 object and character records (`GOLDEN_KEY`, `GANDALF` ...) which we keep as one `g`/`b` block each with record labels; 13 NPC script blocks (we have `GoblinABehaviours` as one); about 10 variable blocks (`DRUNK`, `ACTOR`, `COMMAND_FRAME`, `PHRASE`, `TYPED_WORD`) and the tables `CONTROL_CODES` ($7295), `DIRECTION_WORDS` ($A210), `STATE_WORDS` ($A224). Ours only: 10 (three unused zero fills `$6036`, `$6BEE`, `$CB43`; `$AD35 ArticleTableInput`; four state-variable splits `$B6EB`, `$B708`, `$B737`, `$707A`; `$F35A`). Two one-byte boundary differences: `$67AB` (jonsole starts its second word list one byte earlier, with the `$00` as part of ABLE; the `$00` is the list marker, so ours looks right) and `$7079` (jonsole's `TYPED_WORD` has an unused byte before our `WordLetters` at `$707A`).

## 3. Classification disagreements

Against jonsole (14,757 code bytes in ours; byte-level run with `zxcompare` internals):

| Bytes | Ours / theirs | What | Verdict |
| --- | --- | --- | --- |
| 70 | code / data | six unreached routines: `$78FB-78FE`, `$9030-9033`, `$92E8-92EC`, `$A1AE-A1C7`, `$A536-A540`, `$A70A-A71D` (jonsole: `UNREACHED_COPY_SIX`, `_LET_GO`, `_SAY_BROKEN`, `_WALK_HELD`, `_ELF_OPEN`, `_WIPE_EXIT`) | Convention. The bytes decode as coherent routines and jonsole itself describes them as such, then files them as data because no play reaches them. Both agree they are unreached. |
| 7 | text / data | `$6FF2-6FF8`, "> LOOK" and CR (jonsole `FIRST_COMMAND`, `b`) | Ours right (it is text). |
| 4 | data / text | `$7291-7294`, "WAIT" (jonsole `WAIT_TEXT`, `t`) | Jonsole right; our entry starts with the 4 text bytes then the table at `$7295`, and we classed the whole entry data. |
| 4 (`$6D8C-6D8F`) | bytes differ | Our skool lists `LD (WordListPtr),HL` at `$6D8C`. The tape bytes and `build/game.lst` have it at `$6D8D` (`21 9C 70` at `$6D8A`, then `22 DC B6`). | Our `game.skool` has the wrong address on that one line, one low. Jonsole and pobtastic agree with the tape. The assembled output is right; only the skool text is off. I did not find why the generator wrote `$6D8C`; one instruction with a symbolic operand (`@isub`). |
| 4343 | vars / data | `g` blocks: input line, tokens, parser workspace, variables, state records `$B6DA-$CB42` | Convention. Jonsole never uses `g`; we use it for RAM that changes at run time. 4342 are the large blocks; the rest are small workspace bytes inside code (`$74A6`, `$7574`, `$793D`, `$7F77`, `$806F`, `$824E`, `$85B3`, `$869B`, `$8B81`, `$8D99`, `$980B`, `$9BDC`) where jonsole also says "working bytes" and names each. |

Pobtastic (partial, 186 entries):

- 283 bytes data in ours, code in pobtastic: six data tables that pobtastic decoded as code: `$75D2-75EB` parser class table, `$8271-82A4` special words, `$8BFB-8C4A` key tables, `$9226-9245` wound messages, `$A20B-A243` name/reason words, `$A49C-A4BF`. Ours is right (they are addressed as data).
- 89 bytes vars in ours, code in pobtastic: the same small workspace bytes as above (`$7574-7584`, `$793D-795F`, `$806F`, `$824E`, `$85B3`, `$869B`, `$8B81`, `$980B`, `$9BDC`). Ours right.
- 1589 differing bytes: 1584 are `$F400-$FC2F`. Pobtastic's `CopyOfObjects` holds the snapshot's runtime backup copy of the world (non-zero); on the tape these bytes are zero, so our `StateBackup` is zeros. The other 4 are `$6D8C-$6D8F` (our skool address error above) and, by the tool's count, one more that I did not locate. Not a naming issue.
- Pobtastic adds nothing for names that jonsole lacks.

## 4. Our placeholder labels where jonsole has a name

Our `build/game.sym` has 194 placeholder labels in `$6000-$F3FF` (87 of the form `L82E2`/`LA244`, 107 sub-labels such as `L9404_5`). Jonsole has a real label at the same address for 143 of them. Of these 143, 132 are jonsole entry starts. 97 are in the code region (`$6000-$ACFF`) and 46 are message strings (`LB1EE` ... `LB6CA_0`, jonsole `MSG_...`).

The other 51 have no jonsole label: instruction-level jump targets inside routines.

15 most useful names to adopt:

| Addr | Our label | Jonsole name | Jonsole title |
| --- | --- | --- | --- |
| `$96B3` | `L96B3` | `END_OF_TURN` | Let the other characters act, then count the timers down |
| `$9065` | `L9065` | `DO_DIG` | DIG, carried by the sand |
| `$9076` | `L9065_0` | `DO_SHOOT` | SHOOT |
| `$929C` | `L929C` | `DO_DRINK` | DRINK |
| `$92B5` | `L929C_0` | `DO_EAT` | EAT |
| `$8F69` | `L8F69` | `DO_FILL` | FILL WITH, carried by the barrel |
| `$9404` | `L9404` | `DO_EMPTY` | EMPTY, carried by the barrel |
| `$946D` / `$948D` | `L9404_5` / `L9404_7` | `DO_LOCK` / `DO_UNLOCK` | LOCK WITH / UNLOCK WITH, once the right key is known |
| `$8CE0` | `L8CE0` | `DO_TAKE_OUT` | TAKE OUT OF, carried by the containers |
| `$8FCD` / `$8FF5` | `L8FCD` / `L8FF5` | `DO_ENTER` / `DO_THROW_AT` | ENTER and GO INTO / THROW AT |
| `$A248` / `$A2B4` | `LA244_0` / `LA244_5` | `DO_TIE` / `DO_UNTIE` | TIE TO / UNTIE |
| `$A302` | `LA244_8` | `DO_BURN` | BURN: only the dragon can, and it kills |
| `$977C` | `L977C` | `KILL_TARGET` | Kill the first object |
| `$82E2` | `L82E2` | `WORD_IT` | IT: the last noun phrase again |
| `$6F47` | `L6F47` | `MATCH_WORD` | Look a typed word up in the dictionary |

More worth taking: `$83EF DO_SCORE`, `$82AF WORD_NOPRINT`, `$6E7A REPEAT_LAST`, `$8F3B GO_THROUGH`, `$9F4A SWAPPED_OBJECTS`, `$A1C8 IS_ALIVE`, `$A390 WEAR_RING`, `$A3BC TAKE_OFF_RING`, the control-code handlers `$738D MC_INSTRUMENT_NOUN`, `$73BD MC_BACKSPACE`, `$73F9 MC_ACTOR_HIS`, `$7425 MC_TARGET_IS`, and the 40 handler names in `$A244-$AB4F` (`DRINK_WATER`, `SWIM_RIVER`, `SIDE_DOOR_KEY`, `BARREL_THROWN`, `DRAGON_HUNTS`, `TROLLS_EAT`, `ELROND_GIVES_LUNCH`, `EYES_STING` ...). Each of those is code we have as an unlabelled stretch with no description.
