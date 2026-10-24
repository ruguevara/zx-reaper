# Review 2, R4: src/player.asm, src/constants.asm

Checked: 90 labels of player.asm, 159 constants (every use grepped in src/*.asm).
Runs: /tmp/abbaye-R4/rig.py (frame stepping over zxrun's simulator),
probes.py; snapshots build/docs/play400.z80 (room 5) and room00-24.z80.
Only comments, descriptions and register lines changed; `zxq.py check`
IDENTICAL. Renames and splits: re/frag/renames-R4.md.

## Claims changed in player.asm

- PlayerVars: state 0 "none" -> "no player (the intro and the ending)" (RunIntro,
  RunEnding store 0). PlayerFrame "0-7 when dying" -> "0-8 (7 not drawn, 8 ends
  the death)" (run: frame 8 read at the end). PlayerSpare "unused" kept, now
  with the evidence: no instruction refers to $A89A/$A89B (no label use, no
  pointer walk over the player block), no write in play.txt or a 3000-frame
  fuzz run. PlayerHit $FF writers: HitTestDone -> HitTestDone and
  UpdatePlant_Spit (entities.asm, SBC A,A / LD (PlayerHit),A); pyre value 2
  "with PlayerState 2" -> "so that UpdatePlayerActive runs".
- ProbePlayer: ring "anywhere on the ring from (X+2, Y+2)" -> the eight points
  (X+2, X+5; Y+2, Y+5, Y+8, Y+11); crouching block -> (X+1, X+4, X+7; Y+7,
  Y+11). All points and both boxes now observed (F79 updated): the routine run
  with one marked flag cell at a time, X mod 4 and Y mod 4 = 0-3, both
  postures, 0 mismatches. The side names are right: walking right into the
  room 5 step stops at X $4A00 with PlayerTileRight $83; the left edge of room
  5 stops him at X $0280 with PlayerTileLeft $82; a poked ceiling shows in
  PlayerTileHead ($83) and holds Y at $3E60; the floor shows in PlayerTileFeet.
- ProbeRing: "corners and edge points of a 4 x 9 unit area ... B and C are left
  unchanged" -> all eight points of the 2 x 4 grid; C is left +3 (code: three
  INC C x3, two DEC C x3 before the fall into ProbeCell).
- Probe routines (ProbePair2, ProbeRowOf3, ProbePoint, ProbeBlock3x2,
  ProbePair, ProbeColumnOf3, ProbeRing): the `O:B` / `O:C` lines removed: every
  caller (ProbePlayer, LandPlayer) reloads BC before the next call and reads
  only E.
- QueueDrawCmd: "the player (AC49, AA96)" -> DrawPlayerSprite (living and dying
  monk).
- KillPlayer: "7 frames of the animation each 4 frames long ... then 4 frames
  ... restart of the room" -> frame 0 drawn 3 frames (the timer is first counted
  down in the frame of the hit), frames 1-6 4 frames each (27 frames, 27
  pixels: Y $4400 -> $3680), frame 7 draws nothing for 4 frames, the 32nd frame
  sets room state $84; the restart is at the active checkpoint, not in the room
  of the death (run: killed in room 6 with no checkpoint touched -> room 5, X
  $2400). F73 updated.
- UpdateDying_End: "ask the main loop (StartGame) to restart the room" -> MainLoop,
  restart at the active checkpoint (room state 4, SelectCheckpoint).
- UpdatePlayer: register lines `O:C` and `O:B` removed: GameFrame uses no
  register after the call; C is handed to UpdatePlayerActive by the JR, and B
  (ControlsPressed) is only tested for bit 5 here.
- UpdatePlayerActive: "entered ... with B = the newly pressed controls" -> B is
  written (direction bits) before it is read. Part 3: "A fall ends ...: tile
  class 3 at once, class 1 only when the fall carries Jean across the top of a
  cell row" -> bit 1 (classes 2 and 3) at once; otherwise LandPlayer snaps when
  the feet come into a floor cell (how a platform is landed on from above);
  with the feet already inside a platform row he lands only at Y mod 4 = 0 or
  when the fall enters the next row and that is a floor, so a jump that leaves
  the feet inside the platform falls back through it (F141, observed: platform
  5 rows above the floor fallen through, 3 or 4 rows above landed on). Added
  the class 2 quirk (F140).
- PlayerFalling comment "free or solid below: check for landing" -> free below
  (solid has gone to PlayerLanded before).
- DrawPlayerSprite: the comment on `JR Z` said "facing left: use the left table";
  Z is facing 0 = right, and DE (the right table) is kept -> fixed; EX DE,HL is
  the left case. Observed: facing 1 draws the hood opening to the left (the
  table names MonkFramesLeft/Right and CrouchFramesLeft/Right are right,
  screenshots /tmp/abbaye-R4/face_*.png, crouch_*.png).
- DrawPlayerCrouch: added the one-frame read past the crouching tables (F120,
  reproduced: facing right graphics $9839 = SpriteCmd's word $9836 + 3, facing
  left $EF21 = CrouchFramesRight[0] + 9, a right-facing frame).
- Sprite draw commands: "the second is used ... by the two-part sprites (Satan)"
  -> the falling water drop, the Pestilent Beast's fire, Satan and his smoke
  (writers of SpriteCmd2* in entities.asm: AnimateDrop, UpdateBeastFire,
  UpdateSatan, SetSatanSprite, UpdateSatanSmoke).
- CheckRoomExit: "(none, dying)" -> (no player, dying); "the main loop
  (StartGame)" -> MainLoop.
- DebugMoveRoom A line: "higher bits are shifted out" -> DebugWarpRoom masks
  them off (AND $0F).
- ShiftPairs data: "X mod 0, 1, 2, 3" -> X mod 4 = 0-3.

Confirmed as written (runs): walking $0080 per frame both ways (left
too, F70 updated: the carry of RR B is cleared by AND TILE_BLOCKS before the
SBC), jump $01FE - $1E per frame, ceiling stop (F75), fall cap $021C, left edge
of room 5 solid, room exits (F76), debug warp (F119).

## Claims changed in constants.asm (comments only)

- OP_RET: "stored over a NOP to switch a one-shot routine off" -> also the tile
  animations at room entry, the frame-list gate, QueueDrawCmd while the list
  runs, the Kempston read (uses in mainloop, templates, startup, controls).
- FLAG_HARMFUL: "tile flag value ... (observed: the lake of room 16)" -> bit 2
  (class 4): kills the monk (PlayerHit 4, run) and removes the scythes; tiles
  $05, $3B, $3C, $4E-$74 (TileFlags $84; the table holds only $80, $81, $83,
  $84) and the water strips.
- STATE_RESPAWN: "respawn at the checkpoint position" -> put Jean at
  RespawnX/RespawnY and enter the room; set by the arches (EnterRoomAtArch);
  state 4 goes on here.
- STATE_DEATH: "restart the room after a death" -> state 4 with STATE_RUNNING:
  restart at the active checkpoint (run above). Split proposed.
- SFX_PICKUP: "item taken, lever pulled, key accepted" -> heart, cross, chalice,
  final scroll (FreeSlotWithSound), wheel, gate lever of room 20, parchment, a
  cross added to the ring (ShowCrossRing), key accepted.
- TILE_BLOCKS: + "and a fall stops on it" (PlayerFalling CP TILE_BLOCKS).
- TILE_STANDABLE: + a jump that leaves the feet inside a class 1 row falls back
  through it (F141).
- DYING_LAST_FRAME: "frame ... after which the monk is gone (the frame itself is
  not drawn)" -> first frame not drawn; frame 7 lasts 4 frames, 8 ends.
- CROSS_FLASH_PERIOD, BLOOD_ANIM_PERIOD: "frames" -> passes of the main loop
  (drawn frames, not interrupts; F116, F117: 8-9 interrupt frames per step in
  room 24).
- EXIT_RIGHT: marked unused (LeaveRight stores 0 with XOR A). Keep it as the
  name of direction 0 or delete it; no other constant is unused.

Constants checked with no change: all others. One name for two meanings /
two names for one: SUBROW_MASK (also X mod 4), PAGE_REDRAW_PIXELS (also the
mirror table page), CHAR_SPACE (also the key code of SPACE), SCREEN_COLS-1
(= COLUMN_MASK), STATE_DEATH (only state constant with bit 7): see
renames-R4.md. PLAYER_JUMPING in CheckRoomExit is used as "lowest live state"
(CP / RET C); the comment there says so, left as is.

## Other modules (not edited)

- gameframe.asm RoomItemHandler (description and the comment at `LD
  (ItemCmdPos),HL`): the item command position is "(y, x/4)"; it is the cell
  row and column (L = row 0-21, H = column), as QueueBlockSprite reads it.
- gameframe.asm EnterRoomAtArch: "the main loop (StartGame)" -> MainLoop.
- cutscenelists.asm DebugWarpRoom: wraps RoomNumber modulo 25 again after
  DebugMoveRoom, whose tails already end in WrapRoomNumber: the second loop
  never changes anything (code; harmless).
- entities.asm: six raw `AND $03 ; shift phase` (426, 877, 1159, 2255, 3008,
  3196) and `AND $1F ; x / 4: cell column` (2179, 2313) are SHIFT_PHASE_MASK /
  COLUMN_MASK if the lead wants them named.
- docs/05-player.md, Dying: "every 4 frames the picture advances" -> picture 0
  lasts 3 frames (27 drawn frames, 4 empty, room state in the 32nd); "$84,
  restart after a death" -> restart at the active checkpoint. "PlayerHit is set
  in two places" -> also UpdatePlant_Spit ($FF). Crouching: "Facing left the
  read lands on a real frame" -> a real frame facing right. Falling: the
  "inside a platform" case is now observed and has a consequence: Jean falls
  back through a platform his jump did not clear (F141).
- re/findings.md F73: its claim says "restart the room"; evidence appended
  (restart at the active checkpoint).

## New findings

- F140 (observed): class 2 floor holds Jean in state 5, no jump or crouch;
  latent (no class 2 tile; room 5's edge column has no top).
- F141 (observed): one-way platforms are passed only if the jump clears them.
- Evidence appended: F70, F73, F79, F120.

## Bugs of the original

- Confirmed: F120 (one frame drawn from code bytes when a crouch ends in a
  fall).
- New, latent: F140 (class 2 floor); not reachable with the shipped flags.
- Refuted (my own suspicion while reading): left walking does not lose an
  extra 1/256 to the carry of RR B (AND clears it; run: steps of $0080).
