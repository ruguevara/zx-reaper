# Second review R1: variables, objects, text, room scripts, cutscene lists, start-up, font, IM2 table

Runs from build/docs/play400.z80 (warp: $8509 = room, $850C = $81, hits off
$A87A = $18), re/orig.z80 with tests/inputs/play.txt, the ending ($850C = $83
with build/docs/ending-keys.txt). Scripts in /tmp/abbaye-R1/ (items.py touches
every room item). `tools/zxq.py check`: IDENTICAL after all edits.

## Checks that confirmed the source (no change)

- All 45 room item records touched (Jean poked onto row*4-2 / column*4 of
  each record in its room; crosses with WheelState 0 and 6, the chalice with 12
  crosses, the red scroll with ChaliceTaken = $FF): every flag comment of
  variables.asm and every record comment of RoomItems is right (room, row,
  column, type). Values: hearts/crosses/parchments/red scroll/chalice $FF,
  checkpoints 2 (the eight others cleared), church trigger $8543 = 1 and
  $851A = $FF, bell and levers 9/10 = 1 (sound 3), lever 20 = 1 (sound 5),
  wheel 0 -> $86 -> $06, arches: the OTHER arch's flag $80 and RespawnXHi/YHi
  $54/$3C (room 10's arch) or $5C/$44 (room 19's), room state 2. Type 1
  crosses taken only with the wheel at 0, type 2 only at 6.
- Doors: flag maps read with the flags 0 and set: room 19 col 0 rows 16-19
  (LeverRoom9), room 8 and room 20 col 31 rows 14-17 (LeverRoom10,
  LeverRoom20), room 6 col 31 and room 7 col 0 rows 14-17 (ChurchDoorShut):
  door tiles with class 3 / blank class 0 exactly as the descriptions say.
- Writers of $8501-$855E in play.txt and the ending (watch): InterruptRoutine
  $8719/$A43D/$85E2, MachineType 1 (StartUp), PagingState $10 (PageInBank),
  RoomNameString (OpSetRoomName), PressedKeyMask/Row (MenuFrame, ENTER = 1/6),
  player box (ProbePlayer), RedrawListPtr, CutsceneDone (UpdateCrusaderSignal
  at frame 406 of the ending, set again every frame), MusicTrack 3, 7, 5, 7.
- Every subscript's "Called by rooms ..." list (grep of the DEFW operands).
- Rooms rendered 0-24 (and 24 with 12 crosses, the chalice taken): items at
  their record positions, ScriptSky moon at row 2 col 20, room 4 with no
  status bar, water strips of rooms 16 and 19, blood of 21-23.
- ScriptEraseCrosses: with the ring shown and the chalice taken the twelve
  crosses are erased, smoke and red scroll appear (screenshot).
- Font: the documented index/glyph format decodes 'W' (13 px) and 'a'
  (10 px, two bytes per row, right byte first) to proper glyphs; the last
  glyph ends at $66DC. FlagRowTable built as $5E00 + 32n (24 words);
  OutlineMasks starts FF FC F8 F8 F1.
- BankMusicTrack: data/music128.bin (at $C000) reads and writes $8550
  ($C03F, $C049, $C056); it also writes MusicTrack ($C059, $C061, $EEE6) and
  reads/writes SoundRequest and SoundPlaying.

## Claims changed (old -> new, evidence)

variables.asm
- UnusedByte: "No code reads or writes $8508, nor $8520" -> no instruction
  refers to them; $8520 is zeroed by StartGame's clear of $8512-$854D (watch:
  write at $861A). Same in the BellRung block ("+5 $8520: unused").
- RoomNumber: title (0-24) -> (0-24, 25 in the ending); writers "RunIntro/
  RunEnding (title, ending)" -> RunIntro (room 0, the intro, not the title),
  RunEnding (25 and 4), EnterRoomAtArch, DebugMoveRoom tails + DebugWarpRoom.
- RoomTableEnd: "RoomItems and RoomObjects are sorted by room number" -> they
  are not sorted (RoomItems is in flag order, RoomObjects mixes rooms); they end
  with a record of room $1A and are scanned to the end.
- ExitDirection: "cleared by ShowParchment ... so that the room is redrawn from
  the right" -> cleared by ShowTextWindow (parchments and the ending windows),
  so the room comes back by columns from LEFT to right (direction 0, F41).
- RoomState: "ShowParchment and the cutscene loop clear and restore it" ->
  ShowTextWindow saves/restores it; RunCutscene sets $80 and clears it at the
  end. Added: UpdateDying_End sets $84 during the pyre scene of the ending
  (watch: $AAA0 writes $84 every frame from frame 753), ignored by the loop.
- BloodAnimTimer: "counts down once per frame ... bubbles every other frame"
  -> once per main-loop pass, a swap every second pass (room 22: about 2
  frames per pass, a swap every 4-5 frames; watch $8510).
- CrossFlashTimer, CrossRingCount, CrossColours: "every 5 frames" -> every
  fifth main-loop pass (room 24: a step every 8-9 interrupt frames, count 1-12
  at frames 32-128, CrossRingDone 12 at frame 128). Added that the ring
  crosses are solid platforms (F125) and that a later visit stamps all 12 at
  once (count poked to 12: all 12 drawn at frame 60).
- PlayerBoxXMax...: "smaller while crouching" -> lower and wider (X+1..X+8 vs
  X+2..X+6); observed $50 $4C $50 $46 standing, $52 $4B $51 $4B crouching at
  X $4A Y $44.
- ChurchDoorShut: "closes the door ... and plays the door sound" -> closes it;
  the first rattle with sound 8 comes on the next frame (watch: $851A FF at
  frame 18, $854F 8 at frame 19). "makes checkpoint 0 active" -> sets
  checkpoint flag 0 to 1.
- BellRung: "erases a 2x2 block of wall at row 20, column 26" -> erases the 2x2
  block of FLOOR there, which opens the way down from room 8 to room 13
  (Catacombs). New finding F142 (observed).
- LeverRoom20: added ActionGateLever, sound 5, the pull erases the door at once
  (EraseDoorRight); the three doors are class 3 and close the way to rooms 18,
  9 and 21.
- SatanSmoked: "Other entity routines (for instance UpdateFireball) test it"
  -> UpdateFireball is the only other reader (zxq refs $8522); "runs the
  script" -> arms the event script; observed in a run.
- Item flags: wheel crosses "only after it has been turned" -> only while it
  is turned; added the touch evidence.
- Crosses: incremented by TakeCross (shared tail of both cross actions).
- SoundRequest: list corrected to every store: 2 PlayerStanding (not
  UpdatePlayerActive), 4 EnterRoomAtArch (both arches, not only
  ActionArchToRiver), 5 also parchment, lever of room 20, each ring cross,
  the red scroll; 7 also UpdateFishJumping; 8 is each rattle of the door.
- MusicTrack: "5 and 2 during the two parts of the ending" -> 5 for the first
  cutscene, 2 for the last text (EnterRoom sets 7 for rooms 25 and 4 in
  between; watch); the music bank also writes it.
- SpawnQueueCount: "add one" -> one, two (plants, Beast fire) or three
  (Satan) per volley.
- ProbeRight..ProbeHead: "around an entity (a 16x24 pixel sprite, 2 x 3
  cells)" -> around the chasing ghost (only user), which is 16x16
  (BehaviourChaser height 8); the probes cover a 2 x 3 cell box from
  (x/4, y/4); ProbeHead is the box's own top row.
- InterruptStack: the pushes include IY (IX, HL, AF, BC, DE, IY + alternate
  HL, AF, BC, DE = 20 bytes); deepest write in play.txt $8565 (32 bytes).

objects.asm
- ObjectTypeTable: added that the type 1 and 2 records are identical; the
  cross set is decided by the action word.
- ObjectTypeRecords: type 7's +0 = 1 is the first rattle countdown (slot +8),
  not an animation delay.
- Frame lists: the arch sprite is 16x24 (48 bytes), not 16x16; bell frame 1
  is "rung, not bright" (not "ringing"), lever frames "before/after the pull"
  (handle tilted the other way, not bright), wheel frames at rest/turned.
  Screenshots with the flags poked.
- RoomObjects: "+6 byte: initial animation state (slot +$0A/+$0B)" -> a timer
  (slot +$0A, reload +$0B): drop start delay, plant spit reload ($78), Beast
  jet delay ($48), Death's first throw ($28), Satan's first volley ($96); the
  animation frame +$14 is cleared by SpawnRoomObject. "+7/+8: the countdown of
  the timer kinds (13-15)" -> fish (13) and Beast fire (15) only; added drops
  (tip y / end y), Death (x limits), Satan (y limits), chaser start delay
  (+8). "The records of one room are not sorted" -> the table is not sorted by
  room.
- Canonical names: "white flyer" -> ceiling ghost, "soldier(s)" -> knight(s),
  "grinning ghost"/"chaser (ghost)" -> chasing ghost; record comments of the
  drops, fish, plants, archers, Beast, Death and Satan now name their
  parameters instead of "params ...".

roomscripts.asm
- Room 5: "the crusaders' chase of rooms 4-6" -> rooms 5 and 6 (spawners only
  in 5, 6, 25).
- Room 8 and EraseWallBlock: "erases a 2x2 block of wall" -> a block of the
  floor that opens the way down to room 13 (F142); title changed to "Open the
  floor of The Altar after the bell has rung".
- Room 9: "Draws the tree with a compressed bitmap and sets up the second
  sprite set" -> only the leaves (tile $89) are the $94 bitmap (F3); the
  sprite-set phrase was empty and is gone.
- Room 10: op $96 = row 5, columns 28-31: a hidden one-cell tunnel through the
  rock of the right edge into room 11 (F133). Room 11: row 5 cols 0-1 (its
  end) and rows 20-21 cols 2-3: harmless spikes over non-solid rock, the hidden
  hole into room 16 (F134; the other spikes of the row are class 4). Room 16:
  rows 0-3 cols 2-3, the shaft under that hole. All from flag maps read in
  runs (tiles kept, flags 0).
- Room 16: "makes the bottom row a water strip" -> part of it (cols 6-21).
- Room 24: "sprite set 14 (Satan) is unpacked by the room objects" -> wrong:
  only op $97 unpacks (OpUnpackSprites is the only caller of
  UnpackSpriteSet); the script unpacks 14 (Satan, no other room) and 1 (the
  crusaders, for room 25).

text.asm
- "Room 0 is the title and intro screen" -> the intro screen (the title is
  ScriptTitle).

startup.asm
- FlagRowTable: "Only the first 22 words are used; the last two are spare" ->
  ProbeCell (player) stops at row 21, but UpdateArrow accepts y up to $5F and
  can read words 22-23 ($60C0, $60E0: the main stack) (inferred, not run).
  Added that the player's probes use the table too.

## Claims of other modules found wrong

- entities.asm UpdateSatan, comment on `LD A,(ChaliceTaken)`: "flag of the
  cross item in room 24" -> the chalice (ChaliceTaken, item type 11).
- gameframe.asm ActionChurchDoor description and the comment on
  `LD (HL),$01`: "checkpoint 1" -> it writes 1 to checkpoint flag 0 ($8543,
  CheckpointFlag0, the first of the nine). Also its "countdown in slot +8 of
  32-63 frames": the first countdown is 1 (type record +0), so the first
  rattle and sound 8 come on the frame after the door shuts (watch).
- behaviours.asm BehaviourChaser title "grinning ghost" (canonical: chasing
  ghost); BehaviourWhiteFlyer and BehaviourSoldier are still the label names
  in src (names.md: ceiling ghost, knight).
- docs/05-items-ending.md:133 and docs/05-rooms.md:200: the bell "erases a
  wall block" of room 8 -> it opens the floor down to room 13 (F142).
- docs/05-items-ending.md:95: the ring colours step "every 5 frames" ->
  every fifth main-loop pass (8-9 frames in room 24).
- docs/07-graphics.md:138: "grinning ghost" -> chasing ghost.

## Bugs / quirks

- Confirmed (code, not run): projectiles read flag-map row words 22-23 of
  FlagRowTable (main stack bytes as flags) when y is $58-$5F; at worst a
  projectile below the room is removed one frame early. Not seen in play.
- No new bug of the original found in these files.

## Findings

- Added F142 (observed): the bell opens the floor of room 8 to room 13.
  (Its refs list $7782 by mistake; EraseWallBlock is $7783.)

## Not settled

- The 128K paths (MachineType/PagingState on a 128K, AY in Patch128KHooks)
  stay inferred: the simulator is 48K.
- Whether string 0/4 (":)", ":$") can ever be printed: by code no (no $87 in
  rooms 0 and 4), not run beyond F129.
