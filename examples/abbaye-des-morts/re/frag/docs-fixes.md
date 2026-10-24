# Fixes reported by the article writers (lead)

Writer B:
- variables.asm RespawnX: a death after an arch does not return Jean to the
  arch (the forced restart went to room 5).
- sequences.asm SpawnRoomItems: the records are sorted by flag address, not
  by room.
- behaviours.asm: block byte +4 ("Unknown") is the frame count (also A).
- gameframe.asm OverlapTest: register comments swapped: D is x, E is y.
- text.asm SatanText: black on bright red, not white on black; HeresyText:
  the second part of the ending is room 4, not 25 (also A).
- roomscripts.asm RoomScript25: CutsceneList1 is the monk; the crusaders
  come from the room 25 spawner.
- hud.asm RunEventScript: "lever" where it means the church door.
- New observations: room 10 one-cell crawl tunnel into room 11; room 11 hole
  in the floor into room 16; room 20 invisible bridge (tile $00, class 3,
  black on black); Satan turns to smoke in the frame the chalice is taken;
  the pyre in the ending costs a life; holding jump gives one jump.
Writer A:
- Q4: holding SPACE does not show the info screen on 48K (WaitSpaceRelease
  is a RET; the info screen is overwritten by the game unpacking).
- interrupt.asm MusicEntryGame/MusicEntryInfo: on 128K the bank routine at
  $F9D7 clears the attributes and jumps to $C000 (the copy of DepackScreen):
  they draw the title ($C09D) or the info screen ($CA8A); explains F111.
- Relocation holds for 48K only: the 128K bank reads $A2D4/$A2D9 (KeyRows)
  and calls $BE48 (BuildMirrorTable) at fixed addresses.
- $8503 is PressedKeyRow, $8505 the high byte of InterruptRoutine; unused:
  $8508, $8520, $8550 (L8508 comment, Q2).
- RevealPicture: the "border flash" is bit 3 (MIC) with the border colour
  kept: no flash.
- F103's T 54,900 main-loop figure was measured in the intro, which never
  reaches MainLoop.
- scripts/megalz.py cites "src/loader*.asm" (stage1/stage2).
