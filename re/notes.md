# RE notes

Facts that are not yet in the skool/asm comments: memory map, loader stages,
open questions. Keep it short; move each fact into the source once its
routine or data block is annotated.

## Memory map

| Range | What | Status |
| --- | --- | --- |

## Open questions

## Init (zxinit.py)

- original: `original/game.tzx`
- code region: $5FB5-$7FFF
- handover PC: $6000

## Game (from screenshots)

Hungry Horace (Beam Software/Psion, 1982). Maze game: Horace eats flowers in
a maze, a guard chases him; a bell item scares the guard; arrows on the left
and right edges are maze entrances/exits. Status line: PASSES (lives), SCORE,
BEST. Title screen ("HUNGRY HORACE" in big 2x2-block letters), then DEMO MODE
if no key is pressed. Controls: Q/4 up, Z/3 down, I/1 left, P/2 right
(read at $624F). Demo mode flag is probably $6B0B.

## Memory map (lead, classification phase)

| Range | What | Status |
| --- | --- | --- |
| $5FB5-$5FFF | 75 zero bytes below the code (CLEAR 24500 leaves SP at $5F9D) | unused |
| $6000-$6AA6 | code; $6000 is the entry point (PRINT USR 24576) | code |
| $672F, $6A17 | 11-byte tables inside code | data |
| $6AA7-$6B07 | title-screen texts, $FF-terminated ($7F = copyright sign) | text |
| $6B08-$6B0B | variables | vars |
| $6B0C-$6DA5 | code (utility routines: screen, sprites, random, print) | code |
| $6DA6-$6DB7 | variables (words) | vars |
| $6DB8-$6DE2 | current maze record (43 bytes), copied from one of four records by $6A3F; $6DB6 points to the source record | vars |
| $6DE3, $6E0E, $6E39, $6E64 | maze records 1-4, 43 bytes: word, byte, byte, word, byte, then the 36-byte saved background (see below) | data |
| $6E8F, $6F2F | title bitmaps "HUNGRY", "HORACE": 160 bytes each, each byte = 2x2 blocks of 4x4 pixels (drawn by $6D4E) | data |
| $6FCF | current maze descriptor (8 bytes, 4 words), copied by $6A9E | vars |
| $6FD7, $6FDF, $6FE7, $6FEF | maze descriptors 1-4 (8 bytes) | data |
| $6FF7, $72F7, $75F7, $78F7 | maze maps 1-4: 24 rows x 32 columns of tile codes | data |
| $7BF7 | maze tile graphics: 10 tiles x 8 bytes, index = tile code | data |
| $7C47-$7C60 | status line text "PASSES SCORE BEST", $FF-terminated | text |
| $7C61-$7C7B | variables | vars |
| $7C7C, $7CA0 | two 36-byte tables used by $6922 | data |
| $7CC4-$7CC6 | variables | vars |
| $7CC7-$7F86 | 16x16 sprites, 32 bytes each, 2x2 character cells in order top-left, top-right, bottom-left, bottom-right: $7CC7 Horace, the blue creature (8 = 4 directions x 2 frames), $7DC7 guard, the magenta head (8), $7EC7 2 sprites, $7F07 4 bell animation frames | data |
| $7F87 | blank sprite (32 zero bytes), used to erase | data |
| $7FA7-$7FFF | unused zeros up to the end of the code block | unused |

Maze tile codes (map bytes): 0 empty, 1 horizontal wall, 2 flower, 3 arrow,
4 vertical wall, 5-8 corners, 9 (in the entrance column). Check against $7BF7.

Coverage: 92% of code instructions executed (demo + random play). Never run:
most of $66A4 (probably maze cleared / next maze), $686A tail, parts of
$663D and $6337. Annotate those from the code.

## Lead summary after wave 1 (verified across reports; use these names)

- Sprites: $7CC7 Horace (blue, attribute $39), $7DC7 guard (magenta head, $3B).
  The earlier note that swapped them was wrong.
- Attributes are white paper + ink and double as object identity on screen:
  $38 arrows (black), $39 Horace, $3A bell (red), $3B guard, $3C flower,
  $3D wall (cyan), $3E empty floor (yellow ink, blank), $3F wrap pad (invisible).
  Constants ATTR_* exist; reuse them.
- $7C6B Horace position, $7C6D his next position (screen offsets without $4000);
  $7C6F requested direction ($FF none); $7C70 current direction.
  Directions: 0 up, 1 right, 2 down, 3 left (DIR_*).
- Guard records: $6DE3/$6E0E/$6E39/$6E64 = guards 1-4 (43 bytes), working copy
  $6DB8 (LoadGuardRecord $6A3F / SaveGuardRecord $6A6A), $6DB6 = pointer to the
  source record. Fields: +0 position, +2 direction, +3 ?, +4 new position,
  +6 non-zero = inactive, +7..+42 saved background under the sprite
  (4 cells x 9 bytes: attribute + 8 bitmap rows), not "objects".
- $6DA6-$6DAD guard release timers (4 words); $6B0A number of released guards;
  $6DAE bell timer (guards edible while non-zero; inferred); $6DB2-$6DB5
  direction scores of the guard AI, $6DB6 doubles as their end marker.
- $7C62 game pace (1-8, lower = faster); $7C63 maze number; $7C65 countdown
  to the next bell; $7C67 random pointer into the ROM; $7C69 sound mask
  ($1F on, $07 off); $7CC4 bell position, $7CC6 bell animation counter.
- $6B0B: 0 = title, 1 = playing/demo text enabled (PrintChar draws only if
  bit 0 set). $6B08 title-loop countdown.
- $6FCF current maze descriptor: +0 vertical wrap delta, +2 initial bell
  position, +4 guard 1 start, +6 other guards' and Horace's start.
- Tiles: 0 empty, 1 h-wall, 2 flower, 3 arrow, 4 v-wall, 5-8 corners,
  9 wrap pad (blank, white ink). Right-hand arrows = maze exit ($6A1E -> $60E9).
- Utility routines named so far: Delay, GetRandom, PrintNumber, PrintDigit,
  PrintChar, DrawSprite, DrawCell, SetAttrPointer, GetBlockObject,
  MergeObjectAttr, SaveBackground, SaveBackgroundCell, ProbeMove, ProbeCell,
  StepCell, DrawBlocks, DrawMaze, LoadGuardRecord, SaveGuardRecord,
  PlayRisingTone, LoadMazeDescriptor, ResetGuardTimers.
- Wave 1 group D: $6907 UpdateFruitDrops, $6922 MaybeDropFruit, $696C
  TickGuardTimers, $698E CheckSoundKey (T toggles sound), $69A4 PaceAndChime.
  $7C7C/$7CA0 = two bonus-fruit (cherry) graphics in the saved-background
  format (4 cells x (attribute + 8 rows)); a guard drops a fruit by
  overwriting its saved background, so the fruit appears where it stood.
  $7C65 FruitTimer (word, re-armed to 800 + random 0-1023). $6DBE GuardWait
  (pause countdown, 90 after being eaten). Eating: flower +10, anything else
  (fruit, bell) +50; guard +100 while the bell timer $6DAE runs.
  Bell: $7CC4 BellPos (0 = none), $7CC6 BellTick (bits 3-5 = frame at $7F07).
  Possible bug: `OR C` at $697F (C is always $3A) makes the GuardsReleased
  increment unreachable; verify before claiming it.
- Names now exist for all of these as @label; use them in comments as #R$XXXX.
- Wave 2 group E: $651E EraseSprites, $655B EraseGuard (+$6568 EraseGuard_Always),
  $6622 DrawGuards, $663D DrawGuard, $6821 DrawHorace (+$6832 DrawHorace_Sprite).
  Lead added labels: HoraceSprites $7CC7 / HoraceSprites2 $7D47 (two walk
  frames per direction, chosen by HoraceAnim bit 4), GuardSprites $7DC7 /
  GuardSprites2 $7E47, ScaredGuardSprites $7EC7 (2 frames, while BellTimer
  $6DAE runs), BellSprites $7F07, BlankSprite $7F87; HoracePos $7C6B,
  HoraceNextPos $7C6D, RequestedDir $7C6F, HoraceDir $7C70, HoraceAttr $7C71
  (cycled during death), HoraceAnim $7C72, WrapPause $7C79 (Horace invisible
  for 90 calls while crossing a wrap pad), guard record fields GuardDir
  $6DBA, GuardAnim $6DBB, GuardNewPos $6DBC, GuardWait $6DBE; BellTimer $6DAE
  (decremented once per drawn guard: runs faster with more guards),
  GameActive $6B0B, TitleCountdown $6B08, RandomPtr $7C67, GuardDirScores $6DB2.
- Wave 2 group F: $6337 PlanMoves (Horace + guards plan one step every
  GuardInterval passes; StepCountdown $7C61), $63DA ChooseGuardMove (AI:
  per open direction 25 + 40 if straight on, -10 if reversing, +rand 0-31
  sideways; chase bonus distance+10 towards Horace, negated while BellTimer
  runs; highest score wins). Random numbers here come from FRAMES ($5C78)
  incremented by the AI itself, masked to ROM bytes. Bugs: negated bonus
  wraps below 0 as an unsigned byte, so a "fleeing" guard can turn towards
  Horace (verified in the simulator); $7C64 is written/read only by the AI
  and is dead state. $6A1E ExitMaze (POP HL; JP $60E9); $6A17-$6A1D are 7
  never-executed code bytes. HoraceCell $7C7A / GuardCell $6DB0: H=row, L=col.
- Wave 2 group G: $624F ReadControls (+Autopilot $626D, ReadKeys $62C4),
  $65A1 EatObject (+ShowScore $65C7), $686A UpdateBell (+TakeBell $68BE).
  Score $7C73, BestScore $7C75, ExtraPassMark $7C77 (score/10000+2 at the
  last award; starts at 0, so the first ShowScore gives a free pass: 3 -> 4),
  Passes $7C78, MazeNumber $7C63. Demo abort: ReadControls drops its return
  address and jumps to $67E9 (title restart). Bugs found: stack creeps by 2
  bytes per demo abort; bell turn-round at $68EF-$68F6 is overwritten by the
  next LoadGuardRecord (dead); bell pickup tests only offsets 0, -1, +1, -32,
  +33; guard attribute could score 50 in EatObject (not seen).
