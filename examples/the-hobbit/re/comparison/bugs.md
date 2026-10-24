# Bugs, traps and quirks: the references against the blind run

Version: The Hobbit 1.2 unless said. "Ours" means `examples/the-hobbit`: `re/findings.md`
(F1-F85), `docs/06-tricks.md`, `docs/05-*.md`, `re/notes.md` and the comments in
`port/*.py` (stage 3) and `game/hobbit/*.py` (stage 4). Labels are written jonsole / ours.

Sources:

- **J**: jonsole, `notes/hobbit/bugs.md` (9 bugs, 7 traps), `leftovers.md`, the other notes,
  `scripts/hobbit.ref` [Bug:...] and `scripts/hobbit_reference.py` (Bug:jostle, the Facts).
- **B**: basf-c60, v1.0. 14 bugs (`source/hobbit.ref` 3, `source/hobbit-extra.ref` 11) and
  the trivia (Facts) in the same files. Characters.html and Objects.html name no bugs
  beyond these.
- **E**: 6elphegor, `docs/CLEAN.md` (17 rows "The bugs it fixes", plus "Not changed")
  and `README.md` ("The bugs...", "Things found on the way").
- **W**: the web. Megler, "There and Back Again" (the 2014 text on readkong.com; the
  Refractory and veronikamegler.com pages gave 404/403). Icemark's format notes. The
  Wilderland page `veronikamegler.com/WL/wl.htm` gave 404. TASVideos #9695, cited by E.
- pobtastic: no bug, trap or quirk anywhere in its .skool, .ctl or .ref.

## What I ran

All from the project root, `tools/zxrun.py`, on a Bag End snapshot made the way
`scripts/docs-images.sh` makes it (`re/orig.z80 --input tests/inputs/endgame.txt --frames
1800 --dump`). Each test types its lines (`TYPE`, 700-1500 frames apart) and reads the
screen with `--text 0x8822`. Pokes put the player or things in place: player location
$C12B, player holder $C11C, sword holder/location $C306/$C315, barrel $C3EF/$C3FE/$C3F5.

| Run | Result |
| --- | --- |
| player at $1E (great halls), `jump onto barrel` (barrel in the cellar) | without the sword: "I SEE NOTHING HERE. IT IS DARK." With the sword: PC reaches $B301 at frame 75; no prompt comes back in 3400 frames; the code map shows $B301-$B324 run as code |
| same, `climb into barrel`, `go into barrel`, `enter barrel` | "I DO NOT SEE THE BARREL HERE" |
| player at $2E: `e; wait; wait; w; wait; wait` | the eyes after the second wait, then "You go west", and alive two turns later |
| player at $2E: `e; wait; w` and `e; wait; wait; wait; w` | dead, back at Bag End |
| player at 5, description word $BAC4 = $B262 (as the dawn writes it), `look` | "You are in in a clearing with two stone trolls" |
| `tests/inputs/endgame.txt` to frame 16800 | the same "You are in in a clearing with two stone trolls" on screen |
| barrel carried, open, empty, at the long lake ($22): `fill barrel with water` | "YOU CANNOT FILL SOME WATER WITH THE BARREL." |
| player in the closed chest (Bag End) or closed barrel: `open chest`, `climb out of chest`, `open barrel`, `climb out of barrel` | all "I SEE NOTHING HERE. IT IS DARK." |
| player in the closed barrel in the cellar, sword in the closed chest at Bag End: `take sword` | "I DO NOT SEE THE SWORD HERE" (barrel closed and open) |
| `do`, `op do` | "WHAT ?", then the door opens; no runaway |
| `say "hello` then `@` | PC = $0000 at frame 956: the Spectrum restarts |
| `take all except quickly`, `--watch $B9E0-$BA0F` | $B9E2-$B9E3 (location 1's record pointer) written by $791F/$7921; then "I SEE NOTHING HERE. IT IS DARK." in Bag End |
| player at $22 carrying the map: `put map in river` | "You put the curious map in the fast river. I cannot do that." |
| player at $1A with the sword: `strike web with sword` x2 with waits, `--watch $C20A` | web +5: $40 -> $20 at $934F (break), $20 -> $40 at $AA68 (mend), twice. The sword breaks too (seeds 1-6, 6 of 6) |
| player at $06 with the bow: `strike door with bow`, 40 RNG states ($B70E, $B713 poked), `--take $9377` | the bow broke 6 times; each time the spread was negative (-20, -4, -12, -17, -12, -20), never otherwise |
| `--call $9CA8 --reg A=$15`, 1024 RNG states | 84 negative (8.2%) |
| `take map from chest`, `climb chest`, `cut map`, `put map on chest` | "I CANNOT DO THAT." each |
| `take map out of chest` (map carried) | "You take the curious map out of the wooden chest." |

## 1. The reference bugs, traps and quirks

Columns J, B, E, W: "yes" if the source names it. Ours: the finding or file, "partly"
when we have the mechanism but not the effect, "no" when absent. Rows 1-35 bugs, 36-43
traps, 44-55 quirks and leftovers.

| # | Claim (short) | J | B v1.0 | E | W | Ours | Same cause? Details |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | The score stops at 75%: only 14 first visits score, 750 of 1000; `SHOW_SCORE`/PrintScore $83F5 cannot print 100% (1000 gives ":0.0%") | yes | yes (trivia score75) | - | - | F64, F24 | Same. 750, 14 places, ":0.0%" agree in all three. Ours observed (endgame ends at 500; ":0.0%" by call) |
| 2 | Winning shows no score | yes (in Bug:score) | says the opposite | - | - | F78 | Differs. B's Fact:winning and Fact:score75 say the score is printed ("A perfect game ends with 'you have mastered 75.0%'"). B's own listing refutes it: $A8D6 `JP $9049` enters after `CALL $81AD` at $9046. In 1.2 CheckVictory $A9D6 jumps to EndGame_Wait $90DF, after PrintScore. F78 observed on the win screen. J and ours right |
| 3 | Jostle: a negative spread with no underflow returns 0; below 10 it wraps to 246+ | yes (Bug:jostle, bug 9) | yes (negativeRandom) | yes (fight rolls) | - | F9 | Same cause, `JOSTLE`/RollStrength $9213. Rates: ours "about 3%" (our evidence 10 of 256 = 3.9%), J 1 in 25 (71 of 2000), B 4%. E says "rolls mostly come out as 0, fights end in one blow": wrong; F9 and J measured about 4% |
| 4 | `WOUNDS`/WoundMessages $9226 read one entry late: entry 0 never used; margin 16 reads $9246's code bytes DD 2A as $2ADD, a ROM "message" | yes | yes (woundTable) | - | - | F56 | Same. $2ADD in all three (B: table $9190, code $91B0 in v1.0). Ours observed "Cut seclosed." (9 of 100 seeds); J "garbled dictionary words" |
| 5 | Wear-down halves with `RRCA` (DO_ATTACK/VerbAttack $91E4): odd margins take 129+ or nothing | yes | yes (rrca) | - | - | F65 | Same. Numbers agree. Worked from the code for Thorin 104/120: d=8 99/117, d=10 98/120, d=11 nothing, d=13 defence 52 (J's runs); d = 1, 5, 9, 13 leave defence 55, 54, 53, 52 and d = 3, 7, 11, 15 do nothing (B's "about 53"). Ours d=15: 192 -> 56 |
| 6 | FILL can never work: `DO_FILL`/L8F69 calls PutObjectIn $924F, which refuses a liquid first | yes | - | - | - | no | Confirmed by run: "YOU CANNOT FILL SOME WATER WITH THE BARREL." |
| 7 | JUMP ONTO the barrel (`JUMP_ONTO_BARREL`/LA9E5_1 $AA27) does `JP NZ,$B301` into message text | yes | yes (barreljump) | yes ("GO INTO") | - | port/handlers.py, game/hobbit/handlers.py (LA9E5_1) | Same cause. Reachable? J: "not reached" (test from the great halls). B: reachable from rooms 30/31, froze. Run: reachable from the great halls with the sword, and the game hangs. B is right. J's test failed because the halls are dark ("I SEE NOTHING HERE"). E calls action $38 "go into"; typed GO INTO BARREL does not reach it, JUMP ONTO does. We had the jump in the stage 3/4 code, not as a finding |
| 8 | A LOAD loses the hidden road: its record is only the operand at $A7D1 (SmcBlockedExit), not saved | yes | yes (loadroute, $A6C3 in v1.0) | - | - | F84 | Same. J and B read it. Ours observed with an emulated LOAD (Elrond restores the wrong exit). Five records (J, B, ours); E's "one of four exits" is wrong: `InitNewGame` $97BD-$97CD picks record 1-5, the end ones half as often (F74), so the long lake's is 1 in 4 |
| 9 | `ROAD_OPEN`/ExitRestoreMode $B6F1 is cleared and tested, never set. Harmless | yes | - | - | - | ExamineMap $A7C4 description | Same ("it is never set to anything else"). Not marked as a bug by us |
| 10 | PUT ON, TAKE FROM, THROW, CUT, CLIMB have patterns but no handler; PutObjectIn's PUT ON branch is unreachable | yes | - | - | - | no | Run: TAKE FROM, CLIMB, CUT, PUT ON all "I CANNOT DO THAT." Our PutObjectIn description treats the PUT ON branch as live |
| 11 | Unreached code: $A536, $A70A, $A1AE, $78FB, $9030, $92E8 | yes (6) | yes (2: $A0DE, $A600 = 1.2's $A1AE, $A70A) | - | - | partly: $A1AE only (06-tricks) | We call $A536 "Command handlers" and $78FB an entry; $A70A, $9030, $92E8 unmarked |
| 12 | Thorin never says "get us out of this one, thief!": `JP Z` after `JP NC` on the same `CP 3` (THORIN_CHATTER/ThorinTalks $A657) | no (lists the line as possible) | yes (thorinline) | - | - | F42 | Same. J misses it |
| 13 | Bard's order only partly saved | - | yes (bardsave) | - | - | no | Still in 1.2. `BARD_TAKES_ORDER`/LA814_8 $A8AB writes four bytes, $C9E2 op, $C9E3 command, $C9E4-$C9E5 the objects. SAVE ($84CF-$84D5) and LOAD ($8489-$848F) copy three from $C9E2 (CopyScriptBytes $84B3, `LD BC,$0003`), so the second object is lost. J and ours both say "three bytes" and miss it |
| 14 | "Another goblin enters." compares the player's place with a register never loaded (`GOBLIN_RETURNS`/RespawnKilledGoblin $A448, `CP B` at $A488) | no (reads B as the goblin's place) | yes (goblinB) | yes | - | F39, port/handlers.py, game/hobbit/handlers.py | Same cause. What B holds: B "left over from the attack routine"; E "0 on all 3,628 calls traced"; ours "0 or $0E in the records" (game/hobbit/handlers.py). All agree it is unreliable; ours saw a non-zero value too |
| 15 | The mended web's strength doubles with `SLA` and overflows 64 -> 128 -> 0 | - | yes (webstrength) | - | - | (05-time: "doubled") | **Not a bug.** StrikeObject halves +5 with `SRA` when the web breaks ($934F; $92B9 in v1.0), and the mend doubles it back. Run: $40 -> $20 -> $40, twice. B is wrong; not counted |
| 16 | Breaking something can break the tool | - | yes (breakcarry) | - | - | F46 | Overlapping. Two faults in one test (StrikeObject $9372-$937F). B: a negative spread saturates to $FF (or wraps high), so the tool breaks. Run: the bow broke on the rock door 6 of 40 strikes, every time the spread was negative. B right, and in 1.2 too (ours had this as inferred). Ours: the comparison itself is upside down (the weapon breaks when its own defence reaches the target's), so strong weapons break on weak targets. B calls the comparison honest. Run: the sword breaks every time it cuts the spider web (6 of 6 seeds) |
| 17 | "you are in in a clearing with two stone trolls" after dawn | - | yes (inin) | - | - | no | Still in 1.2. Run, and also on screen in our own endgame run (frame ~15500) |
| 18 | Two things shut in different closed containers count as together | - | yes (sameplace) | - | - | - | **Fixed in 1.2.** FindClosedHolder $9E7A keeps the holder's id (`EX AF,AF'`) where v1.0's $9DC8 returned 0. Run: "I DO NOT SEE THE SWORD HERE". Not counted |
| 19 | PRINT without a printer jumps into the middle of an instruction | - | yes (printjump) | - | - | - | **Fixed in 1.2.** WordPrint $82A9 `JR NZ,$82B3` lands on ResumeDispatch. Not counted |
| 20 | Typing DO makes the game run wild | - | yes (doword) | - | - | - | **Fixed in 1.2.** DO is only in the print-only word list (offset $08C2), not a class 9 word. Run: "WHAT ?". The path B describes is the "not a special word" exit of DispatchSpecialWord $8251, which our 06-tricks lists as code that cannot run. Not counted |
| 21 | Unused room description "a bewitched gloomy place surrounded by thick trees" | - | yes (trivia unuseddesc) | - | - | no | Still in 1.2: message $B5FE (LB5FE) has no reference, and location $19's text word (+8) is 0 |
| 22 | The ring divides strength by 4 and drops the remainder (up to 3 points lost each time) | - | yes (trivia ring) | - | - | partly | 1.2 `SRL` x2 at $A39F, `SLA` x2 at $A3D9. Ours: 06-tricks open question asks about the x4 overflow, not the lost remainder; F41 says "halves" (wrong: it is /4) |
| 23 | `SAY "HELLO` refused, then `@`: the Spectrum restarts | - | - | yes | - | no | Run: PC = $0000 at frame 956 |
| 24 | A word out of place after ALL ... EXCEPT puts the phrase records over the location table at $B9E0 | - | - | yes | - | no | Run: `take all except quickly` writes $B9E2-$B9E3; Bag End then "I SEE NOTHING HERE. IT IS DARK." |
| 25 | A finished object or exit search, resumed, runs past the index into the records | - | - | yes | - | no | Not run here. F48 has the resumed scan (RecPtr1), not its overrun |
| 26 | A token class past $C0 runs the parser's jump table into the ROM | - | - | yes (fuzzing) | - | no | Not run here |
| 27 | More than 32 tokens overwrite code from $70E2 | - | - | yes | TASVideos #9695 | F71 | Same. Addresses agree ($709C, $70DC/$70E2). The speedrunners' winning line ("game end glitch") is only E/W; we saw garbage and a crash into BASIC |
| 28 | A printed word over 20 letters (read from garbage) overflows the buffer at $74A6 | - | - | yes | - | no | Not run here. We document the 20-byte WordBuffer $74A6 without the missing bound. (Our F70 is another overflow, the typed word at $707A) |
| 29 | TIE ROPE TO X with X not carried puts the actor inside itself; the next walk loops | - | - | yes ($A2A2) | - | game/hobbit/handlers.py (LA244_0) | Same ("IY is the actor now"). Ours only in the stage 4 comment |
| 30 | RUN where no direction has an exit tries for ever | - | - | yes | - | F55, F82 | Same cause (VerbRun $8FAD). Ours wider and observed: any place with no exit in 1-9 hangs unless 10 is rolled (the steep paths have only "down") |
| 31 | With no object, $95DF reads object flags from ROM $0007 | - | - | yes | - | no | Not run here |
| 32 | PUT X IN RIVER uses the location of the last character that moved | - | - | yes | - | no | Run: "You put the curious map in the fast river. I cannot do that." The handler (L9404_1, $942E) reads ActorLocation $B6F6 |
| 33 | The lift check tests a sign: strong characters "carry too much" | - | - | yes ($8D1A) | - | F67 | Same (CheckCanCarry $8CF1, `JP P`). Ours observed: capacity 132+ |
| 34 | TAKE X OUT OF Y works for anything carried (L8CE0 $8CE0 tests Z, not the answer) | - | - | yes | - | game/hobbit/verbs.py (take_out_of) | Same. Run: a carried map "taken out of the wooden chest" |
| 35 | The second-noun "which ?" asks "which ting ?" and the answer fails | - | - | yes | - | F61 | Same (ExplainNoun2Failure $7D98, the word is the address $7948) |
| 36 | Shut inside a closed container you are in the dark, cannot open it or climb out | yes (barrel trap) | - | yes (chest) | - | partly: F45 | Same. Run: OPEN and CLIMB OUT OF refused "IT IS DARK" for both. F45 has the darkness, not the trap |
| 37 | The forest road and forest ($02, $03): the pale eyes kill | yes ("kills whatever you do") | yes (eyes: wait twice, leave on the third turn) | - | - | F83 | Same mechanism (IN_THE_FOREST/ArriveForest $C7DD, timer 8, EYES_WARNING $AB1F, EYES_STING $AB3A). **Differs on escape.** Run: arrive, wait, wait, leave: alive. B right; J's "whatever you do" and J's Bug:forest title are wrong. F83 is right but our 06-tricks says "the forest kills without a way out": wrong |
| 38 | The deep bog kills at the end of the arrival turn | yes | yes (verified) | - | - | F80 | Same |
| 39 | SPACE held at the end of a tape block is BREAK: the ROM's error exit restarts the machine | yes | - | - | - | re/notes.md, 05-save-and-printer.md | Same. J names the cause (IY not pointing at the system variables, "assumed"); ours does not |
| 40 | Attacking a friend takes it off the player's side for good | yes | yes (allies) | - | - | 05-characters.md (CheckAttackAllowed $914A clears bit 4) | Same. J adds: Thorin then kills a barehanded player at once |
| 41 | Thorin's death shatters the small curious key (side door locked for good) | yes | yes (thrainskey) | - | yes (Megler: a game is "insoluble" if a key character dies) | 05-characters.md (ThorinDeathBreaksKey $A73B) | Same |
| 42 | A new game does not restore the scripts: Bard keeps his order, Thorin's spent remark stays spent | yes | - | - | - | no | Stage 4 reproduces it (flow.py's backup omits `s.program`) without saying so |
| 43 | If Elrond dies first, the game cannot be won | - | - | yes | yes (Megler, in general) | no | Not checked |
| 44 | Location 47 ($2F) cannot be entered: no exits, the stone fills it | yes | - | - | yes (Megler: "left over from testing") | F82 | Same. Ours adds LOOK there lists phantom doors and RUN hangs (poked in) |
| 45 | NEW_GAME's test at $6CF1 never branches | yes | - | - | - | F47 | Same |
| 46 | The fresh water and black water ($15, $16) exist only for FILL, so never appear | yes | - | - | - | no | Follows from row 6 |
| 47 | The torch has the sword's light flags but is never tested | yes | - | - | - | F45 | Same effect (only object $0E is tested). 05-world.md gives another reason ("fixed objects") |
| 48 | After a refused object the rest of the line is dropped | yes (open question) | - | - | - | game/hobbit/parser.py | Same |
| 49 | A troll that eats the player dies of gluttony | yes | - | - | - | F81 | Same |
| 50 | CAPTURE is a synonym of ATTACK: the player cannot capture | yes | yes (capture2) | - | - | 05-characters.md | Same (synonym listed); only B and J draw the consequence |
| 51 | The golden key opens nothing; no key fits Bag End's door | - | yes (trivia) | - | - | no | Not checked in 1.2 |
| 52 | Message control code 3 is used by no message | - | - | - | yes (Icemark: entries 3, $0B, $0F unused) | 06-tricks (L738D) | Same for code 3 |
| 53 | Unused bytes $CB43-$CBFF, $F35B-$F3FF | yes (+ $6BEF-$6BFF) | - | - | - | 06-tricks | Same |
| 54 | Eating at strength 255 wraps to 9 | yes (poke page) | - | - | - | no | Poke-only; F81 covers the 128 limit |
| 55 | v1.0 could not be finished: a road near the long lake never opened (Your Sinclair #5) | yes (versions) | - | yes ("reported unwinnable") | yes (ZXDB) | - | v1.0 only. Not counted |

## 2. Ours, not in any reference

Each was searched for in J's notes, listing and ref; B's .ref files and listing; E's
CLEAN.md, README and `clean/*.c` comments. Status as in our register.

| Finding | What | Status |
| --- | --- | --- |
| F46 (half) | StrikeObject's weapon test is upside down: a strong weapon breaks on a weak target. The sword breaks on the barrel, and (new run) every time it cuts the spider web, and a broken sword gives no light. B has only the negative-spread half and calls the comparison honest | observed |
| F53 | VerbMove's "too small" message prints a word made of the obstacle's weight bytes ($8E6D falls into $8E79 without reloading IX) | observed |
| F54 | VerbLookThrough $8EEC tests the darkness of location 1, not the place looked at: "It is dark." never shows. J describes it as working | observed |
| F34 | WalkToExit $8F3E checks the passage with the previous move's weight and destination; the stage 4 comment adds that the visited mark is read and set on that stale destination | inferred |
| F66 | Wound message 15 says "Your violent attack almost kills you." (J lists the message, not the fault) | text observed, intent inferred |
| F68 | SumHeldRecords $9D00 tests overflow with `JP PE`: sums past 255 can wrap unnoticed (J says "goes to $FF on overflow") | inferred |
| F70 | A typed word of 105-128 letters overwrites the code of ClearBytes $70E2: every later line is "WHAT ?", even after QUIT | observed |
| F72 | A ninth order writes $FF at $B800 and the rest are dropped | observed |
| F73 | Orders of a refused SAY TO stay pending and the next character spoken to carries them out | observed |
| F76 | The riddle's answer must be the very next command; an order given before the riddle is used up and lost | observed |
| F77 | The day picture of the clearing is not saved: a game saved after dawn and loaded after a restart shows night | inferred |
| F79 | Key 7 later in a line types "[" | observed |
| F85 | ActorArrives $8E12 writes through a stale IY: arriving by barrel sets timer 2's handler to $AB22, mid-routine | write observed, effect inferred |
| F75 | A timer put off by another (F50) is put off again every turn while an earlier timer keeps firing | inferred |
| 06-tricks open question | Taking the ring off multiplies strength by 4 with two shifts and can overflow (B has only the lost remainder) | open |
| stage 3/4 comments | Code quirks reproduced in `port/` and `game/`, none named by a reference: climbing into something takes the load as $FF without a carry, so only a load past 255 is "too big" (LA536_1, J reads it as working); the boat's cargo goes to location B left by the dispatcher (LA814); the riddle's CPIR searches for the high byte after a miss (LA8F6); an erased script step runs its routine's address bytes as a verb and objects; FindNpcState $9A85 with id 0 finds the first dormant slot; ScrollInputDown $864A leaves the rule in row 19; the input article table's codes 4-7 read on into the common words; SumHeldRecords never counts the player; IT goes over block B ("put the map in it" loses "in"); SplitNounPhrases flips StateB71E bit 5 with no preposition; InheritWords counts from the stack top and InheritRecord uses the parse's flags; ReadKey $8B93 leaves Z set with a shift down; PicVar1 is $38 in the loaded image (latent); DispatchCommand_Done tells stale noun records | inferred (code, reproduced against stage 3) |

## 3. Counts

Rows 1-54 less the four not counted (15 not a bug; 18, 19, 20 fixed in 1.2) and row 55
(v1.0 only): **50 reference items valid for 1.2.**

| | Found | Partly | Missed |
| --- | --- | --- | --- |
| All 50 | 30 | 3 (11, 22, 36) | 17 (6, 10, 13, 17, 21, 23, 24, 25, 26, 28, 31, 32, 42, 43, 46, 51, 54) |
| J's 9 bugs | 7 | 0 | 2 (FILL, the five shapes) |
| J's 7 traps | 5 | 1 (barrel) | 1 (new game keeps the scripts) |
| B's 14 bugs | 8 of the 10 still in 1.2 | 0 | 2 (bardsave, inin); 3 fixed in 1.2, 1 not a bug |
| E's 17 rows | 9 | 1 (closed chest) | 7 |

Of the 30 found, 5 are only in stage 3/4 code comments or an entry description, not in
the findings or the article (rows 7, 9, 29, 34, 48). For row 7 we did not know the jump
was reachable.

Ours not in any reference: 14 findings (F34, F46's comparison, F53, F54, F66, F68, F70, F72,
F73, F75, F76, F77, F79, F85), 14 code-comment quirks, 1 open question.

Corrections to our own text from this check: 06-tricks "the forest kills without a way
out" (wrong, row 37); F41 "halves the strength" (it is /4, row 22); 05-characters and
06-tricks "those three bytes" for the Bard (four are written, row 13); F46's saturation is
now observed (row 16); F9's "about 3%" is 3.9% by its own evidence.

## 4. Why the blind run missed each

| # | Why |
| --- | --- |
| 6 FILL | Read, not recognised: $8F69 was left as "Command handler (via $C730)", though PutObjectIn's own description says it refuses a liquid and that $8F69 calls it swapped; verbs.txt typed only `fill chest` |
| 10 five shapes | Reached, not recognised: verbs.txt typed `take map from chest` and `climb chest`, and "I cannot do that." read as an ordinary refusal; command records were never checked against the handler tables |
| 13 Bard save | Read, not recognised: we counted the copied bytes, not the bytes LA814_8 writes; no script saves after giving Bard an order |
| 17 "in in" | Reached, not recognised: our endgame run printed it at frame ~15500; nobody read that screen for mistakes |
| 21 unused description | Read, not recognised: no sweep for unreferenced messages ($ADDA was found by chance, $B5FE not) |
| 23 `"` then `@` | Not reached: F49 tried the open quote and F37 the @, never one after the other |
| 24 ALL ... EXCEPT | Not reached: verbs.txt put only nouns after EXCEPT; no word-order fuzzing |
| 25 resumed search | Read, not recognised: F48 found the resume, not what happens at the end of the table |
| 26 token class > $C0 | Not reached: needs junk after the line, which only fuzzing produced |
| 28 printed word > 20 letters | Not reached: needs garbage text; the 20-byte buffer was documented without asking what bounds it |
| 31 $95DF null pointer | Read, not recognised: F51 cites $95DF, the no-object case was not traced |
| 32 PUT IN RIVER | Read, not recognised: ActorLocation is described as the NPC loop's (VerbCapture), not checked in L9404_1; no script put anything in a river |
| 42 scripts kept by a new game | Read, not recognised: both script writes were listed as state outside the saved blocks, but nobody asked whether RestartGame restores them; stage 4 copied the behaviour silently |
| 43 Elrond dies | Not looked for: puzzle dependencies over the whole game were not analysed |
| 46 waters for FILL | Follows from 6 |
| 51 golden key | Not looked for: which key opens which lock was never tabulated |
| 54 eat at 255 | Not reached: needs a poked strength |
| 11 unreached code (5 of 6) | Coverage gave "never ran", but each such routine was not searched for references; $A536 was taken for a handler from its shape |
| 22 ring remainder | Read, half recognised: the x4 overflow was asked, the /4 loss was not, and F41 misread the shifts |
| 36 closed container | Mechanism known (F45); the consequence (OPEN refused in the dark, no way out) was never tried |
| 37 forest escape (wrong summary) | The summary in 06-tricks was written from the "stay" and "leave early" runs; the "leave on the fourth turn" case that F83's own mechanism allows was not run |
