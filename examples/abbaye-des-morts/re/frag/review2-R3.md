# Review 2, R3: redraw, sprites, script, effects, unpack, tiles, sprite sheet, buffers

Files: src/redraw.asm, src/sprites.asm, src/script.asm, src/effects.asm,
src/unpack.asm, src/tiles.asm, src/spritesheet.asm, src/buffers.asm.
274 labels checked (routines, entry points, tables, fields, locals). Only
comments, titles, descriptions and register lines changed; `tools/zxq.py
check` prints IDENTICAL. Runs from build/docs/play400.z80 (rooms entered by
poking $8509 and $850C = $81, Jean out of play with $A894 = 0, hits off with
$A87A = $18); the scripts are in /tmp/abbaye-R3/ (h.py helper, ops*.py script
codes, spr.py sprites, dec.py static script decoder).

Findings: F45, F47, F65 set to observed; new F149-F153.

## Register lines the lead asked about

- AddQueueJob ($98B1): `HL Address of the 16-byte job` is right; no output
  is used (QueueSprite falls in, QueueBlockSprite jumps in, both end in its
  RET). No change.
- CopyTileBitmap ($9BCA): `HL` bitmap, `DE` screen address are right; B, HL,
  D after the call are used by no caller (DrawTileCells and DrawFrameCell push
  and pop HL/DE, RedrawCell falls in). Description: "Also entered from
  DrawTileCells and DrawFrameCell" -> RedrawCell falls into it, the two others
  call it.
- FillTilesRect ($9DD7): A tile, E row, D column, C width, B height are right
  (EX DE,HL gives L = row, H = column for PlaceTile). Added `O:HL Unchanged`:
  DrawTileVLine returns to the interpreter through it and OpFillTilesList goes
  on with the script pointer. Description "Entry point: fill a rectangle of
  tiles; HL is kept" -> full description (B ends 0, C kept, D and E changed).

## Claims changed

script.asm
- RunScript: the table of the 32 codes had been reflowed into one unreadable
  paragraph ("Code Operands Effect $00-$7F - print the character $80 - end of
  script (OpEnd) $81 ...") -> one line per code; $94 now says index byte /
  mask byte as OpDrawTileMask does (was mask byte / data byte). Added that
  every code was run on hand-made scripts and does what its line says (F149).
- OpFillPixels: "The room scripts use it to clear the status bar rows and the
  text windows to 0" -> all uses from a static decode, all with b = 0: the
  whole screen (room 0, ScriptParchment, ScriptEnding1-3), the two bottom rows
  (room 4), the name panel (ScriptRoomPanel), the controls screen lines.
- OpFillTiles: "Also entered at FillTilesRect by OpFillTilesList and
  DrawTileVLine" -> falls into FillTilesRect, which OpFillTilesList calls and
  DrawTileVLine jumps to.
- OpSetRoomName: "the banner script at $82F0" -> ScriptRoomPanel ($82F0),
  run by every room script except rooms 0 and 4 (decode: $83 $82F0 in rooms
  1-3 and 5-24).
- OpTileStripes: "A run is not wrapped" -> the code does not wrap a run, but
  TileMapAddress carries a column above 31 into the next row (from rows 7 and
  15 back to rows 0 and 8 of the same page); room 4's stripes at $742C have a
  run reaching column 37; used twice ($742C, $74D4). Run and decode: F150.
- PlaceTile: removed `O:A Flag byte` and `O:D $CD` (no caller uses them);
  description now says HL, E and BC are preserved (the fill loops rely on HL
  and E) and names ShowCrossRing as a caller too.
- DrawGlyph: removed `O:A Destroyed` (not an output; the description says A
  is not preserved).
- OpSetTextCursor: "No room script uses it" (true for $726A-$83A7 only) ->
  used by the controls screen scripts ScriptControlsScreen,
  ScriptKempstonLine, ScriptKeyboardLine and ScriptPressKey (src/controls.asm
  `DEFB $8E,...`); no room or window script uses it.
- FillAttrRect: "also called by ShowParchment" -> ShowTextWindow (ShowParchment
  falls into it; the CALL is in ShowTextWindow).
- OpMarkRedraw: "1 (... room 4 and the scripts at $82D0-$83A7)" -> 1 in
  ScriptRoomPanel ($8308, run by every room but 0 and 4), room 4 ($7440),
  ScriptParchment ($8342), ScriptEnding1 ($8360), ScriptEnding2 ($837E); 0 only
  in room 0 ($729D), so that the intro text is not drawn over (decode; run in
  F152).
- OpDrawTileMask: added: a skip of 8 cells that passes column 31 goes to column
  0 of the next row, dropping the rest, so the groups stay aligned only from a
  start column that is a multiple of 8 (the one use, room 9, starts at 0);
  mask bytes wrap cell by cell (F150).
- GetBlockTile: removed `O:D 0` (the only caller, OpFillWithBlock, calls
  PlaceTile next, which sets D); D is changed.
- SetTileFlag: removed `O:HL Address of the flag` (SetFlagRect pushes and pops
  HL around the call; no other caller).
- OpSetupWater: "the source is the cell row 3 rows above, the destination the
  bottom pixel line ... so the copy comes out upside down" -> the copy takes
  every third line from the top of the row 3 above and writes upward from the
  bottom line of the water row: the three rows above, squashed and flipped
  (F115); added the operand values written for room 16's operands (run: $5AA6,
  $13, 16, $5046, $57A6, $0080, JR offset $20).
- OpAnimateBlood: "Observed: $AE20 holds 0 in room 22 and $C9 in the other
  rooms tried (5, 16, 19, 25)" -> 40 frames after the warp $AE20 = 0 in rooms
  21, 22, 23 and $C9 in rooms 5, 16, 19, 24.
- OpTwelveCrosses: "draws tile $4C at each cell of the coordinate list at $82D7
  (room 25's script holds the list)" -> wrong: room 25's script is only `$83
  $826C $80` (it calls room 24's); the list CrossRingPositions ($82D7) is the
  position list of ScriptEraseCrosses ($82D4, `$92 $80 12 ...`), the script
  UpdateSatan runs to blank the ring when the chalice is taken; ShowCrossRing
  adds the crosses one by one. "Observed: $AE4B holds 0 in room 25 and $C9 in
  the other rooms tried" -> 0 in room 24 (and 25, F10), $C9 in rooms 5, 16,
  19, 21, 22, 23 (run).

effects.asm
- DrawWaterReflection, AnimateBloodTiles, ShowCrossRing: "Called once per pass
  by the main loop StartGame" -> the main loop (MainLoop_Play). StartGame is
  the start of a game; the calls are in MainLoop_Play.
- DrawWaterReflection: added the room 16 observation of F115 (the 8 water
  lines equal source lines 21, 18, ..., 0 from the top of screen row 18).
- WaterCopyChain: "The chain of WaterCopyChain-ADE0" (raw address) reworded;
  added that both strips are 16 cells wide, so the JR lands on WaterChainTail
  and these 16 LDIs never run (F130).
- WaterChainTail: "the code at ADE1" -> "the code that follows".
- ShowCrossRing, Hardware: "the crosses are drawn by the redraw routine
  RedrawRoom" -> PlaceTile marks the cells and the main loop's
  BuildRedrawList/DrawRedrawList paint them (RedrawRoom runs only at room entry
  and after a text window).
- Three lines over 80 characters rewrapped.

redraw.asm
- DrawRedrawList, BuildRedrawList: "main loop StartGame, title RunIntro" -> the
  main loop MainLoop_Play, the intro RunIntro (RunIntro runs room 0, the
  intro; the title is ScriptTitle).
- Raw addresses in comments (5800, 4000, CC00, CCFF, 5E00 and the code
  addresses 9619, 9629, 9736, 9740, 9792) -> $-prefixed or the label.
- DrawRedrawList_Row / _Run headers: missing full stop after the heading.
- BuildRedrawList: `O:All All registers are changed` (not a register) -> plain
  sentence as in DrawRedrawList.
- CopyRunCells: duplicated "(SmcRestoreSP)" removed.
- QueueBlockSprite: the register lines `HL/DE/BC/AF Popped ...` (popped from
  the call list, not register inputs; the BC line was also broken across
  lines) -> a parameter paragraph. Width "not used: it is always 2" and height
  8 / 12 confirmed: room 10, all 64 calls in 60 frames have C = 2, B = 8 for
  the items and $0C for the arch at $66DC; graphics in $66DC-$68CB. "the sprite
  command at ItemCmd, made by AnimateItem" -> DrawItemFrame (it fills ItemCmd;
  AnimateItem leads into it). Added: it uses the call list as stack (F151);
  drawn unmasked (three blocks queued by hand at rows 3, 10, 19: every screen
  byte equals the graphics byte, both attributes set).
- BlockJob: "the first code bytes of QueueSprite" -> "... which follows in
  memory" (no change of claim).

sprites.asm
- QueueSprite: register lines `HL/DE/BC/AF Popped ...` -> a parameter
  paragraph (popped from the call list). Added: SP stays in the call list, so
  its CALL FlagMapAddress and PUSH BC overwrite its own, already popped command
  (watch: writes from $9898/$989C into $BE62-$BE8B), and an interrupt there is
  harmless (F151). Added the 903-sprite test (F47 now observed).
- DispatchDrawer: "so entering later draws only the last C pairs of pixel
  rows" -> the four calls are alike, entering later only draws fewer pairs;
  where they land is set by H' (= $C5 + 2 x offset, from DrawSpriteJob): the
  first character row of a sprite offset by n draws 4 - n pairs from pixel row
  2n, the last row the pairs left from row 0 (observed, F47).
- DrawSpriteJob: added that the outline is inside the byte only (OutlineMasks
  works on one byte: no outline across a byte edge, above or below; F37).
- DrawSpriteW1-DrawSpriteW5: removed the `AF Popped from the stack` register
  lines (a popped value, not a register input; the description already says
  POP AF takes the attribute).
- RedrawRoom: "Called after a room has been built (every cell is flagged by
  then), at the title and after ShowParchment has printed a screen of text" ->
  callers MainLoop (room entry), RunIntro (the intro, not the title) and
  ShowTextWindow; the marks come from the $90 1 of ScriptRoomPanel or of room
  4's script; exceptions: the water cells of rooms 16 and 19 (flag 4 set by
  OpSetupWater after the panel, painted by DrawWaterReflection) and room 0,
  where only the cell at $6000 is marked (F152, run on rooms 0-24).
- CopyTileBitmap: see above.

buffers.asm
- ObjectListPtr: raw addresses "the routines at $B620, $B687, $B7C6, $B818
  and $B8C5" -> UpdateShooter_Tail (archers and stone heads), UpdatePlant_Spit,
  UpdateFishWaiting and UpdateFishJumping (splashes), UpdateBeastFire; added
  that the list has room for 15 entries ($5DFC-$5DFF is the build area).
- FrameListPtr: appenders "QueueDrawCmd, AnimateItem, SelectFrameRight,
  QueueTwoCommands, UpdateBeastFire_Draw" -> QueueDrawCmd, DrawItemFrame,
  QueueEntitySprite, QueueTwoPartSprite, UpdateBeastFire_Draw (the routines
  that load and store FrameListPtr; grep).
- FrameList: "closed by $BDEB" -> closed by LeaveFrameList (the word is its
  address). "The interrupt handler writes into this area while SP points here
  and puts the bytes back" -> wrong: the handler's PUSH BC (F139) leaves BC
  below SP, which here is not the popped pair (watch: frame 79, the word $98AC
  at $BE6C became $0203); harmless because the bytes below SP are already used
  (F151).
- DrawQueue: "$9972 for a masked sprite, $98F7 for an object sprite" ->
  DrawSpriteJob, DrawBlockJob.
- RedrawPixels: "RestoreMenuArea and its partner" -> SaveMenuArea and
  RestoreMenuArea (through CopyMenuArea).

unpack.asm (UnpackRecords comments, canonical names of re/frag/names.md)
- set 1 "crusaders (rooms 0, 4, 5, 6, 24, 25)": kept, noted that 25 is through
  room 24's script; observed: room 5 draws cyan 24-row sprites from $D763 on
  (F65 now observed).
- set 3 "red winged devils" -> demons; set 4 "magenta winged flyers" -> birds;
  set 7 "red whirling fireballs" -> fire wheels; set 11 "green zombies" ->
  knights; set 12 "grinning cyan ghost" -> the chasing ghost; set 18 "white
  ghosts" -> ceiling ghosts; sets 8/9 "green flies (second kind)" -> flies,
  BehaviourFlyB / BehaviourFlyA (their blocks point at $D763 and $D76B); set 19
  "cyan worms" -> worms.
- set 5 "unidentified, room 10 (Pestilent Beast)" -> the fire jet of the
  Pestilent Beast (BehaviourBeastFire draws it red from $D768/$D76A/$D76D/
  $D76F; logged in room 10) (F153).
- set 16 "scythe pieces, probably (room 18)" -> Death's scythe: two frames of
  32 rows drawn as 16-row halves ($D7EA/$D7F5, $E7EA/$E7F5; logged in room 18,
  sheet rendered) (F153).
- UnpackSpriteSet: "the drawers DispatchDrawer read it later" -> the sprite
  drawers (DrawStripW1-5, through DispatchDrawer).
- UnpackColumns: "BC is counted down once per column" -> B.

tiles.asm
- TileFlags: "in room 16 row 21, columns 6-21 hold class 4 under the blank
  tile $80, the pit with the bones" -> the lake of blood, set by OpSetupWater
  (screenshot of room 16: the red strip with the reflection; the bones are
  above it). "every tile starts with it, so a new room is drawn in full" ->
  every tile of the table has bit 7, so a placed tile is drawn (the full draw of
  a new room comes from the $90 1 of the panel script, F152). Class lists
  checked against the table: all right.
- TileAttrs: added that tile $00 is blank but class 3 (solid), tile $80
  class 0: the black cells Jean walks on in room 20 are tile $00 (run: room 20
  row 8 columns 15-20, tile $00, flags 3; F135).
- TileGfx: "$E0-$FF ... a block of 6 by 6 cells" -> rows 6-11, columns 13-18
  of room 24, 6 by 6 with the four corners blank (32 tiles; tile map read
  back). "$20-$2F cave rock in cyan" -> $20-$25 (only those have attribute 5;
  $26-$2F are white, yellow, red and bright cyan).

spritesheet.asm
- SpriteSheetLower: "the object table BehaviourJean points to $EF30-$EF55,
  $F357 and $F759" (BehaviourJean points at MonkFramesLeft/Right only) -> the
  behaviour and sprite blocks of behaviours.asm, with each address named:
  fireball and seed $EF30, the stone head's arrow $EF32, arrows $EF34/$EF36,
  stone head $EF3C/$EF3E, flames $EF40/$F740, plant $EF4B/$EF4D, fish
  $EF4F/$EF51, drop $EF53/$EF55/$F357, splash $F759-$F75D; birds (set 4) are
  unpacked at $EF63.

## Names

No label in these files is wrong for what it does. Three loop labels sit in
another routine than their prefix says (left by a cut): renames-R3.md
(OpStampRun_0/1 -> StampTiles_Pos/_Tile, OpSetFlagRect_0 -> SetFlagRect_Cell).

## Claims about other modules

- hud.asm:4 and :279 (ParchmentGate, RunEventScript area), sequences.asm:81,
  startup.asm:155, variables.asm:109: "the main loop (StartGame)" / "the main
  loop StartGame": the per-pass loop is MainLoop (MainLoop_Play calls the
  gates); StartGame ($85FC) is the start of a game. Imprecise rather than
  wrong where it means the whole foreground program.
- docs/05-drawing.md table of sprite sets (lines 309-322): rows 3, 4, 5, 7, 8,
  9, 11, 12, 16, 18, 19 carry the old names (devils, flyers, unidentified,
  fireballs, zombies, grinning ghost, scythe pieces, white ghosts); see
  unpack.asm above. docs/05-drawing.md:222 "F47 is still marked inferred" ->
  F47 is observed now. docs/05-drawing.md:336 "The room script marks every
  cell": through the panel subscript ScriptRoomPanel ($90 1), with the water
  and room 0 exceptions of F152.
- controls.asm CopyMenuArea saves the attributes at $5B00, over the tile map
  (fine in the menus, where no room is shown); not a bug, just worth a word in
  the buffers notes if the tile map is described as always holding the room.

## Bugs of the original

- Confirmed (F5, observed again): OpMarkRedraw never touches the flag at
  $6000; one consequence found here: in the intro the $90 0 leaves that one
  cell marked, so RedrawRoom draws row 16, column 0 (blank, harmless).
- Latent quirks confirmed by runs (F150): OpTileStripes runs past column 31
  rely on TileMapAddress's carry (wrong row from rows 7 and 15); OpDrawTileMask
  drops cells when a skip passes column 31 from an unaligned column. Neither
  shows with the shipped scripts.
- F44 (no check for a full draw queue) and the frame call list overflow: not
  reached; nothing new.
- Refuted claim (not a bug): the frame call list is not "put back" by the
  interrupt handler (F151); nothing depends on it.
