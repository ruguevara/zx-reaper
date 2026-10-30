# Review 2, R6: behaviours, templates, graphics, loader

Files: src/behaviours.asm, src/templates.asm, src/graphics.asm,
src/stage1.asm, src/stage2.asm, src/megalz.asm. Comments only;
`tools/zxq.py check` IDENTICAL. Scripts of the runs: /tmp/abbaye-R6/
(sets.py renders every packed set from build/docs/roomNN.z80; spawns.py logs
every template spawn at $894E; slotwatch.py, actorframes.py, hourglass.py).
Renames: re/frag/renames-R6.md (27). Findings added: F154-F158; F65 set to
observed.

## Claims changed in my files

### behaviours.asm
- BehaviourSkeleton title "a white walker" -> "a skeleton"; set PackedSet17
  named (why its addresses equal the crusader's: same destination $D763).
- BehaviourWhiteFlyer title "a white walker near the ceiling", "20 pixels
  tall" -> ceiling ghost, sprite 24 pixels tall (height $0C), hit box 20;
  patrol observed in room 22 (y $04, x $08-$38).
- BehaviourFlyA "two of the green flies" -> three (RoomObjects has 3 records
  with $9487); BehaviourFlyB "three" -> two (2 records with $949C). Swapped.
- BehaviourChaser "smiling cyan ghost" -> chasing ghost, grinning cyan head.
- BehaviourBird "flying creature" -> bird.
- BehaviourSoldier "soldier" -> knight (closed helmet, sword).
- BehaviourFireWheel title "a falling red flame" -> fire wheel (it moves up
  and down, kind 4); the garbled sentence about one sprite "for each row of
  the sheet" -> both frames are stacked in the 32-row strip of PackedSet7
  (rows 4 and 20).
- BehaviourBeastHead "Hit box 38 x 30 pixels" -> the hit box bytes are
  copied but UpdateBeastHead drops them without a hit test (from the code):
  the head does not kill, only the jet.
- BehaviourBeastFire: the lower jet sprite is one byte wider (3); the list
  order (upper f0, upper f1, lower f0, lower f1) and the set 5 column layout.
- BehaviourDeath: frame count 2, but frame 2 (the throwing pose) is drawn by
  ThrowDeathScythe for the frame of a throw and the 19 after it (observed,
  F155). SpriteBlockScythe: four frames, two 16-row halves of PackedSet16.
- BehaviourSatan / SpriteBlockSmoke: "four sprite addresses of the body" ->
  upper half f0, f1, lower half f0, f1 (QueueTwoPartSprite reads table[frame]
  and table[frame+2]); lower half one byte narrower, one column right, 12
  units lower.
- BehaviourJean "Jean standing, facing left (3 frames ...)" -> frames of Jean
  facing left/right; only frames 0 and 1 shown (frame count 2).
- Projectile sprite blocks after BehaviourDrop: "(attribute, then the
  graphics)" -> attribute, column, page of the first of four copies, 4 pages
  apart per x AND 3 (SetProjectileSprite); fireball and seed share one sprite.
- BehaviourArcher frames: frame 0 resting, frame 1 aiming (seen in the sheet
  of room 17: the left-facing list really faces left). BehaviourStoneHead
  "sprite $EF3E / $EF3C" -> frame 0 resting, frame 1 the last 30 frames
  before a shot.
- SpriteBlockEndingMonk "standing" frames kept, and observed: the monk turns
  round after 80 frames, then every 60. SpriteBlockPyreMonk: frame 2 of each
  monk table, turns every 25 frames (observed). PyreCrusaderR/L: crusader
  frame 1 facing left / its mirrored copy.
- Each block now names its sprite set (or the fixed part of the sheet).

### templates.asm
- Header: the template word layout "+8 hit box offset, +$A far corner, then
  the pointer to the behaviour block (attribute, pair table, height,
  frames)" was right only for UpdateMovingSprite. Now per handler:
  projectiles +$C size word, +$E 3-byte sprite block; splash +8 animation,
  +$A frame/count, +$C size, +$E block; sliding sprites +$C block with shift
  table, +$E/+$10 animation. Observed for all 18 spawned templates (rooms
  10, 14, 17, 18, 19, 20, 24, ending): slot = template with x/y added,
  +$12/+$13 = first word of the next template, +$14/+$15 untouched (F55
  confirmed).
- Per-template comments rewritten above each template; offsets added
  (arrows x 0/+3, y +6; wall shot x -2, y +5; fireballs x -1, y +9; flames y
  +20; scythes x +8, y +12). ScytheLeft/Right "flying left/right" -> falls,
  then slides left/right on a floor. SmokeTemplate "behaviour block $95F6"
  -> SpriteBlockSmoke; UpdateSatan writes words +4/+6 before the copy.
  ActorMonkTemplate / ActorPyreMonkTemplate: timers explained (observed).
- FrameListGate "The main loop (StartGame) and the cutscene loops ($8832,
  $88DE, WaitFrameList)" -> MainLoop_Play, RunIntro, RunCutscene.
- SelectCheckpoint "Called by the main loop (StartGame) for room state 4"
  -> reached at MainLoop_AfterDeath, also once at every game start (observed
  at frame 301 of play.txt); flag 0 is set to 1 by the church door of room 7
  (ActionChurchDoor), not by a checkpoint item; addresses -> labels.
- Checkpoints "(the checkpoint items of rooms 7, 8, ...)" -> church door
  trigger of room 7, then the checkpoint items of rooms 8-23.
- BuildMirrorTable "O:HL The same page" -> "O:B 0" (EnterRoom uses B = 0 to
  clear the draw queue; no caller uses HL); the 128K bank caller added;
  observed by a run of the routine.

### graphics.asm
- Item sprites header: "no mask (the outline comes from the table built at
  $FF00 by StartUp)" -> no mask and no outline: DrawBlockJob replaces the
  background of the two cell columns (sprites.asm says so; from the code).
- SpritePlus "plus-shaped cross" -> inverted cross, the look of a cross that
  cannot be taken (observed in room 9, F156); "the frame lists FramesHeart
  repeat the cross" -> FramesCross; which routine adds 6 to the frame.
- SpriteBell1 "bell swinging" -> the bell once rung (frame = flag, drawn not
  bright); levers: leaning left / right.
- The list of item sprites was run together into one paragraph; split.
- PackedSet0-19 titles now say what each set holds (F154); "Probably the
  crusaders" (set 1) -> observed; set 1 and 14 also used by room 25 (its
  script calls RoomScript24); general text: which creatures come from sets
  and which from the fixed part of the sheet.

### stage2.asm
- `JR NC,.retry ; a tape error: load the block again` -> only safe for an
  error in the first 1764 bytes (bug, observed, F157).
- `POP BC ; B = machine type, C = 1 if there is an AY` -> C is the pushed
  flags; the LD C,A after it makes C the AY flag.
- MachineType "($11-$16)" -> $11, $13, $14 or $16.
- HourglassTop/HourglassBottom and FramesTop/FramesBottom: two phases of the
  falling grains (even / odd bytes left), frame 0 = end of load (observed,
  F158; renames proposed).

### stage1.asm, megalz.asm
- No change. Observed with tap2sna (--start $5CF6): Stage1 entered with BC =
  $5CF6; run on to $6000: memory $6000-$8AFF equals build/stage2.bin, SP back
  at $5CF6. Stage 2 run alone: reveal from the middle outwards (screenshot at
  frame 3), done at frame 9 (RevealExit), hourglass at columns 29-31, rows
  21-23. megalz.asm comments agree with the format in scripts/megalz.py; the
  attribution "fyrex and Mayhem" was not checked (no run can).

## Wrong claims in other modules

- src/entities.asm ThrowDeathScythe: `LD E,D ; no effect (E is not used
  again)` and `LD E,D ; no effect either` are wrong: SelectFrame uses E, so
  they select frame 2 (Death's throwing pose) for the 20 frames from a throw
  (F155). The description should say so.
- src/entities.asm UpdateSatan: `LD A,(ChaliceTaken) ; flag of the cross item
  in room 24` -> the chalice.
- src/entities.asm EntityHandlers description: "green zombies (15, 20)",
  "white ghosts (22, 23)", "magenta winged flyers (20, 23)", "red devils",
  "red whirling fireballs (22, 23)" -> knights, ceiling ghosts, birds,
  demons, fire wheels (names.md).
- src/unpack.asm UnpackRecords comments: set 3 "red winged devils" -> demon;
  4 "magenta winged flyers" -> bird; 5 "unidentified" -> fire breath of the
  Beast; 7 "red whirling fireballs" -> fire wheel; 8/9 "green flies, second
  kind" -> 8 the darker fly (FlyB), 9 the bright fly (FlyA); 11 "green
  zombies" -> knight; 14 "Satan's pieces" -> Satan and his smoke; 16 "scythe
  pieces, probably" -> Death's scythe (4 frames); 18 "white ghosts" ->
  ceiling ghost. Header text "PackedSet0..PackedSet19, label PackedSetN"
  needs rewording after the renames.
- src/objects.asm FramesCross description "6 thin ones, the plus sign
  sprite" -> the inverted cross; RoomObjects comments "white flyer",
  "soldier" (lines ~406-458) and the kinds list "soldiers" (~246) -> ceiling
  ghost, knight.

## Docs to fix (from the above)

- docs/05-drawing.md set table (lines ~309-324): sets 3, 4, 5, 7, 8/9, 11,
  14, 16, 18 as above.
- docs/07-graphics.md:96 "thin plus sign" -> inverted cross; :128-129 titles
  of BehaviourSkeleton / BehaviourWhiteFlyer; :23 link labels after the
  hourglass renames (its text is already right).
- docs/05-creatures.md:183, 185 "white ghost", "green soldier" and the room
  table (:121, 126, 128, 129) -> ceiling ghost, knight; the Death section
  (~285) can add the throwing pose (F155).
- docs/02-data.md:187 "soldiers" -> knights.
- docs/01-overview.md:133, 255 "retried on a tape error" / "a tape error
  loads it again": only for an error in the first 1764 bytes (F157).
- scripts/docs-images.py:201 uses the labels HourglassTop/HourglassBottom
  (rename together).

## Bugs of the original

- Confirmed (new): the loader's retry after a tape error crashes once more
  than 1764 bytes of block 3 have loaded (F157).
- Not a bug but a correction: Death's third frame is shown (F155); the
  "no effect" reading made it look like dead graphics.

## Not settled

- Which way the unmirrored crusader frames face (taken from the code: the
  first list is for moving left).
- The Beast head's lack of a hit test is from the code only (Jean cannot
  reach the head in play to test it).
