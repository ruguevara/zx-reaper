# Second review R5: src/entities.asm

Evidence scripts and pictures: /tmp/abbaye-R5/ (drv.py is a small driver:
snapshot build/docs/play400.z80, room poked into $8509 with $850C=$81, hits
off $A87A=$18, Jean out of play $A894=0, hooks at PCs in the Python
simulator, fast-forward and repeated stops in the C simulator). t_sp.py
records SP - slot and the registers at every entry point in rooms 2, 3, 9,
10, 11, 12, 14, 16, 17, 18, 19, 20, 22, 24; t_rooms.py dumps the slots of
every room; the kind byte of every RoomObjects record was read from memory.

157 labels checked; 43 entries changed (descriptions, register lines,
instruction comments; no byte changed, `zxq.py check` IDENTICAL).

## Wrong claims corrected

- ThrowDeathScythe: the two `LD E,D` were commented "no effect (E is not used
  again)" / "no effect either". Wrong: E is the frame number SelectFrame uses
  next; E := D (frame count 2) selects frame 2, the third word of Death's
  frame tables: the throwing pose (arm out, scythe gone from its hands),
  shown for the last 20 frames of every 50-frame cycle, from the frame of the
  throw on. Title now "throw a scythe every 50 frames, show the throwing
  frame, then queue the sprite"; register lines D, E, SP added. Evidence:
  hook at SelectFrame for Death's slot, E = 2 for timer 20..1 (frames 44-60),
  screenshots death60.png (pose) / death75.png (scythe in hand). F143 (new).
- UpdateShooter_Common: register lines swapped. Old `HL x (H) and y (L)` /
  `HL' template`; new `HL template` / `HL' x, y` (both callers load the
  template after an EXX; the routine's own EXX swaps them). Evidence: on
  entry H,L = $BC,$A2 (ArrowRightTemplate) in room 17 and $BC,$B2
  (WallShotTemplate) in room 20. IY line added. UpdateStoneHead's "template
  in the alternate HL" reworded the same way.
- Projectile_Remove: `SP Slot address + 2` -> `SP Slot address + 6`
  (observed in rooms 14, 17); "the pushes overwrite the position" -> they
  overwrite the two speed words (+4, +2).
- UpdateScytheFalling: "from the code, no scythe was seen to take this exit"
  (harmful cell) -> it is the commonest end: 54 of 96 scythes removed in 5000
  frames of room 18 fell onto the harmful bottom row (y $4D, x $28-$58), the
  other 42 slid off the edges; no sliding scythe met a harmful cell. F144
  (new; F50 names only the edges).
- UpdateIntroRunner: "the monk (BehaviourJean, the standing frames of Jean
  from MonkFramesLeft)" -> it runs right and is drawn from MonkFramesRight,
  frames 0 and 1 (the walk).
- EntityHandlers description: green zombies -> knights, white ghosts ->
  ceiling ghosts, magenta winged flyers -> birds, red devils -> demons, red
  whirling fireballs -> fire wheels, cyan ghost face -> chasing ghost; kinds
  4/5 split by the records: kind 4 = green spiders and fire wheels, kind 5 =
  yellow spiders (missing before) and flies; kind 3 only one rat, one bat, one
  demon. Each DEFW comment now says what the kind is (they repeated the
  label).
- UpdateWalkLeft: crusaders (rooms 15, 20) -> knights; magenta flyers ->
  birds. UpdateWalkRight: "rats, bats, skeletons, crusaders ... room record
  kind 3" -> kind-3 records are one rat (2), one bat (8), one demon (21).
  UpdateWalkDown: red fireballs -> fire wheels; which records start down/up.
  UpdateWalkUp: kind 4 are green spiders and fire wheels.
- PathCommands: "hop in place over a pit" -> hop over a pit (x speed $0150,
  about 8 units forward).
- UpdateArcher: "The archer is one cell wide" -> its x is a multiple of 4
  (records $08, $70, $3C, $60), the sprite is 2 bytes wide.
- UpdateSatan: "flag of the cross item in room 24" -> the chalice of room 24;
  CrossRingDone noted as never read (variables.asm says the same).
- UpdateFireball: SatanSmoked "see UpdateSatanSmoke" -> set by UpdateSatan.
- FreeEntitySlotAtEntry: users list was wrong ("arrows and seeds
  (UpdateFireball, UpdateSplash)", "Death's scythe (UpdateScytheFalling)") ->
  PathCommands 4, UpdateFireball, Projectile_Remove (arrows, fireballs,
  seeds), UpdateSplash, Scythe_Destroy, UpdateSatan, UpdateSatanSmoke.
- SelectFrame: "used by UpdatePlant_Spit" -> by QueueFrameSprite (plants and
  fish); SP line added. QueueOneCommand: "used by SelectFrameRight and
  UpdateDropHanging" -> QueueEntitySprite and, through IY, the hanging drop.
  QueueTwoCommands: "entered through IY (... UpdateDropHanging ...)" (that
  one uses QueueOneCommand) -> the falling drop through IY, plus the Beast's
  fire jet and Satan/smoke, which were missing.
- SetDeathSprite: "continuation of UpdateDeathLeft" -> of UpdateDeath_Common;
  ThrowDeathScythe "timer of UpdateDeathLeft" -> of UpdateDeath_Common.
- UpdateMovingSprite_Draw: "the sliding scythe (UpdateScytheFalling and
  UpdateScytheSliding through Scythe_Draw)" -> Death's scythe, through
  Scythe_Draw from both, and directly from UpdateScytheSliding on the F51 path.

## Register lines checked by runs (lead's list)

- SelectFrame ($B3D8): HL, E, A' right; SP slot+$12 added (observed at every
  entry, rooms 10, 14, 16-20).
- QueueFrameSprite ($B6D9): HL, E right; SP slot+$12 added (rooms 14, 16, 19).
- UpdateMovingSprite_Draw ($B9BE): D x, E y, SP slot+$A right (rooms 10, 18).
- PlaceEntityLeft ($B2C3) / PlaceEntityRight ($B380): D, E, H right (E is
  only passed on to HitTest); SP slot+$C added; callers corrected (fall-through
  from UpdateWalkLeft/Right, chaser tail; not "UpdateChaser_Wait").
- Projectile_Remove ($B716): wrong, see above. Projectile_Draw ($B71B): SP
  slot+6 right (rooms 14, 17, 20, 24).
- UpdateFishWaiting_Jump ($B7D6): DE was missing (E = FISH_JUMP_TIME $36,
  D = reload $54, pushed back to +4 after the EXX); SP slot+6 right.
- ReadSpriteRight ($B3AD): A' line was missing (A' = x observed); callers now
  include UpdateCrusader_Draw and the fall-through from UpdateIntroRunner.
- NextSlotAfterAnim ($B41F): SP slot+$12 right at every entry (rooms 10, 14,
  16-20, 24); callers listed.
- UpdateShooter_Common ($B611): wrong, see above.
- UpdateDeath_Common ($BA32): H x, SP slot+8 right; IY line added.
- UpdateCrusaderJump had no register lines: A, BC, DE, HL, SP added.

## Checked and right (no change)

Direction names: UpdateWalkLeft/Right change x by -/+speed and the first
frame table faces left (rat of room 2 screenshots); UpdateDeathRight moves
right and faces right, UpdateDeathLeft faces left (screenshots); Up/Down
handlers change y by -/+speed. Slot field comments of crusader templates,
walkers, drops, archers, stone heads, plants, fish, Beast head/fire, Death,
Satan, smoke, scythe, splash, pyre monk and moving sprites match the slot
dumps and the templates. Crusader path scripts and CutsceneDone: written by
UpdateCrusaderSignal (PC $B1D1) at frames 406 and 407 of the ending; room 25
shows the stairs below the pentagram. The F51 sliding-scythe bug path:
UpdateScytheSliding_1 not reached in 5000 frames of room 18.

## Findings

- F143 (new, observed): Death's throwing pose, LD E,D.
- F144 (new, observed): most scythes end on the harmful bottom row of room 18.
- F93 set observed (rat and Death screenshots: first frame table = facing
  left / decreasing coordinate).

## For the article (docs/)

- docs/05-creatures.md, Death: add that for the last 20 frames of each
  50-frame cycle Death shows a third frame, the throwing pose (F143); the
  scythe paragraph should say most scythes end on the harmful bottom row
  (F144), not only at the edges.
- docs/05-creatures.md lines 128-129, 183 and docs/05-drawing.md line 317
  still use "white ghost" and "green zombies" (canonical: ceiling ghost,
  knight).
- Any text that repeats the UpdateShooter_Common register lines or "the
  standing frames" of the intro monk follows the corrections above.

## Other modules

None found wrong beyond the names above. HitTest, OverlapTest, StepAnimation,
FindFreeSlot_IY, RunObjectSlot and FreeSlot descriptions agree with how
entities.asm uses them.
