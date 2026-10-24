# Review 2, R2: interrupt, mainloop, sequences, gameframe, hud, controls, helpers

Checked: 235 labels (every routine, entry point, table, field and script of
the seven files), the callers of every routine with register lines (grep of
CALL/JP/JR), the 45 room item records touched one by one.
Runs: /tmp/abbaye-R2/drv.py (frame stepping over zxrun's simulator),
items.py (Jean held on every room item, flags, lives, crosses, room, state
and SoundRequest read after each frame), levers.py, church.py, parch.py,
timing.py, timing2.py, sndsample.py; `zxrun.py --watch` of $854F in rooms 10,
14, 16-18, 20-22, 24, of $8501, $8550-$8551 and $A894 in the ending, of
$A28F in the controls menu. Snapshot build/docs/play400.z80 (warps: $8509,
$850C=$81, hits off $A87A=$18, Jean out of play $A894=0), re/orig.z80 for
the menus. Only comments, descriptions and register lines changed;
`tools/zxq.py check` IDENTICAL. Renames: re/frag/renames-R2.md (one).
Findings: F145-F148 added, F107 extended.

All the item actions do what their names say (run): hearts +1 life and flag
$FF, crosses +1 and $FF (type 1 only with the wheel at 0, type 2 only at 6),
checkpoints flag 2 and sound 9, the church trigger flag 1 and $851A=$FF,
bell and levers of rooms 9/10 flag 1 and sound 3, the room 20 lever flag 1
and sound 5, the wheel $00 -> $86 and sound 5, the chalice $FF (with 12
crosses), the final parchment $FF, room 25, the arches room 10 <-> 19 with
sound 4, the parchments open the window. No item name is wrong.

## The lead's register lines (checked first)

- EnterRoomAtArch ($A6F2): `A New room` was the only line, but the routine
  ends in AnimateItem, so it also needs SP: added `SP Slot address + 8 (the
  flag pointer is popped)`. Description: "Entry point used by
  ActionArchToBeast ... as after a death at a checkpoint" -> the common tail
  of both arch actions (ActionArchToRiver falls in, ActionArchToBeast jumps),
  sets the room state 2, player state 4, sound 4, draws the arch; the main
  loop path is the one a death takes after SelectCheckpoint (code, F32).
- FreeSlotWithSound ($A71F), FreeSlot ($A724): `SP Slot address + 8` right
  for every caller (each pops the flag pointer first; ActionParchment pops
  the message word and the flag). Entry lists completed: ActionHeart falls
  into FreeSlotWithSound, TakeCross/ActionChalice/ActionFinalScroll jump to
  it; FreeSlotWithSound falls into FreeSlot, ActionChalice (fewer than 12
  crosses) and ActionParchment jump to it.
- DrawItemFrame ($A7DB): `A Frame number`, `SP Slot address + 8` right for
  all entries (checked each path). Entry list: ActionCheckpoint added
  (through DrawFlagFrame). Instruction comment wrong: "DE = sprite address (D
  = pixel row page, E = column)" -> the address of the 16-pixel-wide sprite
  (16x16, the arch 16x24): QueueBlockSprite takes linear graphics, not a
  sprite sheet column.
- OverlapTest ($A85F): the inputs D, E, B, C, IX are right. The description
  listed Jean's box as "(min x, max x, min y, max y)": the bytes are
  PlayerBoxXMax, PlayerBoxXMin, PlayerBoxYMax, PlayerBoxYMin ($8516-$8519).
  Added `O:F Carry set when the boxes overlap` and the edge rule (box max >=
  Jean's min, box min < Jean's max: touching Jean's max edge does not count;
  agrees with F100's audit).
- ShowTextWindow ($9C58): HL, B, C right (B blank cells, C frame tiles; EXX
  makes them B'/C' for DrawFrameCell). The description was one sentence;
  now lists what it does. The comment "(the room name is drawn again by the
  room)" was wrong: the window scripts clear only the bitmap of rows 0-21
  and black out all attributes; the room name's pixels stay and come back
  when FillAttrRect makes rows 22-23, columns 12-31 white; no room script
  runs (run: parchment of room 8 closed, "The Altar" back; F148).

## Other claims changed

gameframe.asm
- GameFrame: "spawns the cutscene actors if $8552 is nonzero" -> the
  objects waiting in the object list: shots, seeds, flames, splashes or the
  cutscene actors (writers of SpawnQueueCount: UpdateShooter, UpdatePlant,
  the fish, UpdateBeastFire, Death, Satan, LoadCutsceneList). Same for the
  instruction comment "cutscene actors pending?".
- RoomItemHandler, ParchmentHandler: ItemCmd position "(y, x/4)" -> (row,
  column): ItemCmd's routine is QueueBlockSprite, which takes a character row
  and column (player.asm ItemCmdPos says so too).
- ActionChurchDoor: "flicker ... a countdown of 32-63 frames ends with sound
  8" -> added that the countdown starts at 1 (type 7 record), so the first
  rattle and sound 8 come on the frame after the door shuts, and on the first
  frame when room 7 is entered with the door shut; the shutting path itself
  requests no sound (run: shut at frame 21, rattles at 22, 60, 111; F146).
- ActionBellOrLever: added what the flags do, in other rooms, when entered:
  bell -> hole in the floor of room 8 (rows 20-21, cols 26-27; also F142 by
  R1), lever of room 9 -> red door at the left edge of room 19 (col 0, rows
  16-19), lever of room 10 -> red door at the right edge of room 8 (col 31,
  rows 14-17) (run: flag maps with each flag 0/1; F145).
- ActionGateLever: the gate goes at once (run: flag cells and screenshot
  after the touch; F145).
- ActionCrossWheelTurned: "Room items of types 1 and 2 with this action" ->
  the four crosses of type 2 (rooms 9, 15, 17, 22); ActionCrossWheelRest: the
  eight of type 1 (rooms 3, 10, 13, 14, 16, 17, 18, 19). Table read; takes
  observed (items.py with $851E 0 and 6).
- Register lines: SP lines added to ActionCrossWheelTurned/Rest, TakeCross,
  DrawCrossWheelRest; `F ... (not used here)` removed from
  DrawCrossWheelTurned (it does not read F).
- Garbled comments "frame without the wheel at restset" (x2) -> "frame
  without the wheel offset". AnimateItem_Store "Entry point of AnimateItem,
  ActionCrossWheelRest and DrawCrossWheelTurned" -> DrawCrossWheelRest and
  DrawCrossWheelTurned. AnimateItem's users: the arches added.
  ArchRelease/ArchIdle: used by both arch actions, not only
  ActionArchToBeast.
- HitTest: `SP Slot address + $C` holds only for room object slots; slots
  made from a template (arrows, seeds, flames, scythes, fireballs) have the
  hit box at +$A/+$C (Projectile_Draw pops x and y and jumps with SP at +$A;
  layouts observed in F80). Register line and description changed.

mainloop.asm
- MainLoop/StartGame description: "When the drawing outlasts the next
  interrupt, that frame's game logic still runs but its sprites are not
  queued" -> each game frame starts its list again, the loop draws only the
  latest complete list, and a frame whose interrupt comes while RunFrameList
  runs queues nothing. "A quiet frame is drawn by about T 55,000": kept, now
  measured in play (room 7: T 54,700-54,850 every frame; F147; F103's figure
  was from the intro). Draw counts per room added.
- EnterRoom: `O:IX Changed` removed (no caller uses IX).
- SoundEffects "who plays what": 3 is the bell and the levers of rooms 9/10
  only (the room 20 lever plays 5); 5 also the wheel, parchments, the ring
  of crosses, a key accepted; 7 was "Death throws a scythe or Satan fires"
  -> also the archers and the stone head, the plants, the fish (splash at
  the start and the end of each jump) and the Beast's fire (every second
  frame while the jet burns); 8 when the door shuts and each rattle (runs;
  F107 extended).

interrupt.asm
- InterruptHandler: "The interrupted code needs no stack room: the main loop
  runs the frame list with SP as a data pointer" -> the handler keeps
  nothing on the interrupted stack; the CPU's push of the return address is
  repaired by PUSH BC (F139). Timing "about 5,500 to 7,300 T-states" was the
  intro only -> T 7,550 in a quiet room, median 9,300-15,700 and up to
  24,000 (room 14) in rooms with enemies (F147). `O:All` pseudo register line
  turned into a sentence.
- CallInMusicBank: "registers reach the music routine unchanged, except BC"
  -> except A (paging value) and BC (PageInBank0); `O:BC Changed` removed; HL
  described per entry. PageInBank0: `O:A $10` removed (no caller uses A).

sequences.asm
- `O:A 0` removed from WaitFrameList and SpawnQueued_NoSlot, `O:IX` from
  MakeItemSlot and SpawnRoomObject (no caller uses them).
- SpawnItem "All registers are preserved", SpawnRoomObject "All registers
  but IX and IY" -> AF, BC, DE, HL preserved; IX, IY and the alternate set
  changed (FindFreeSlot works in the alternate set).
- FindFreeSlot: the three O: lines were run together in one paragraph; now
  one per line. Not mentioned before: UpdateCrusaderSpawner enters at
  FindFreeSlot_IY with IY preset (comment added on that label).
- SpawnQueuedObjects: list writers "(Death, Satan, the archers)" -> Death,
  Satan, UpdateShooter (archers and stone head), plants, fish, Beast's fire.
- RunCutscene: "Jean is not in play (state 0)" -> except in the second
  scene: UpdatePyreMonk sets his state 2 and hit flag and he dies on the pyre
  (run: $A894 0 -> 2 at $B9A9, 2 -> 1 at $AA53, frame 722; F85, F137).
  CutsceneDone writers observed: $B1D1 frame 406, $B988 frame 897. RunEnding
  point 3 says the same.
- SpawnRoomItems: an over-long line reflowed.

hud.asm
- ShowParchment: "blacks out the whole screen ... redraws the room and the
  status bar" -> black attributes, bitmap cleared above the status bar,
  colours of the status bar and room name given back (ScriptParchment code,
  run).
- DrawParchmentFrame: B'/C' come from ShowTextWindow's EXX (not
  ShowParchment). `O:C 0` removed from DrawTileCells and DrawFrameRow.

controls.asm
- ControlsRead, KeyCode: "the title loop RunIntro" -> the intro loop.
- ControlsPressed: "jump (bits 3 and 4) and the debug warp (bit 5)" -> also
  the direction bits 0-3 in the warp mode (DebugWarpRoom reads them).
- MenuFrame: "StartGame installs it before the title is drawn" -> after the
  title script is drawn (StartGame_NoTitle), before the title menu;
  replaced when ENTER starts the game. `O:A` removed.
- TitleMenu: "SPACE calls WaitSpaceRelease (128K music only ...)" -> 128K
  only: the info screen. Observed added: C, 1 writes RET at KempstonSwitch
  ($A333) and shows "Kempston disabled", ENTER restores the title picture.
- CheckCheatKeys: the garbled XOR sentence rewritten (each byte of the four
  pairs XOR the matching CheatKeyPairs byte into one running value; F24).
- Unused output lines removed: ReadKeyControls O:A (kept O:E, read by
  ReadKempston), ReadKempston O:A, FindPressedKey O:HL, GetKeyCode O:A,
  TitleMenu O:A, AddKeyName O:BC, CheckCheatKeys O:A.

helpers.asm
- WaitKeyPress, WaitKeyRelease: caller "ShowParchment" -> ShowTextWindow
  (parchments and ending texts).
- ScanKeyboard: "MenuFrame (the key redefinition)" -> every frame of the
  title and the controls menu; `O:F` (no caller tests it) turned into a
  sentence. AddAToHL `O:A` removed (no caller uses it).

## Claims in other modules found wrong

- src/entities.asm, UpdateSatan: `LD A,(ChaliceTaken) ; flag of the cross
  item in room 24` -> the chalice (item type 11, ActionChalice; F29).
- src/constants.asm, MUSIC_TRACK_ENDING2: "second part of the ending (the
  pyre, room 4)" -> RunEnding sets track 2 after the pyre scene, for the last
  text ScriptEnding3 (run: $8551 7 -> 2 at frame 898, after CutsceneDone at
  897; during the pyre scene the track is 7 from RoomMusicTable for room 4).
  MUSIC_TRACK_ENDING1 (5) is likewise set after the first text window, for
  the room 25 cutscene.
- src/constants.asm, SFX_PICKUP "item taken, lever pulled, key accepted":
  "lever" is only the gate lever of room 20; also the wheel, parchments and
  the ring of crosses. SFX_TRIGGER: also the levers of rooms 9 and 10.
- docs/04-game-loop.md line 99: "from about 5,500 T-states (the intro) to
  about 16,000 (rooms 10 and 15)": room 14 reached 24,012 (median 15,381) in
  300 frames with hits off; quiet play (room 7) is 7,550.
- docs/05-sound.md: effect 8 "the church door flickers" -> it also plays
  when the door shuts (the first rattle comes on the next frame, F146).

## Bugs of the original

None new. Confirmed by the same runs: the cross set rule (F31), the
chalice and final parchment (F29). F112 (the EI/JP
window of the interrupt handler) and F110 (no free slot test in the room
spawners) stay inferred: not reachable in the runs.

## Not settled

- PlayEffectOnAY and the bank entries (128K): not run here (48K simulator);
  the lead's bank runs are the evidence.
- NoiseByte / effect 1 (F106) not re-run.
