# Lead: cross-file fixes after the annotation waves

- Cut $98B1 "Append a job to the draw queue" (HL = template) and $9BCA
  "Copy a tile bitmap to a screen cell" (HL = 8 bytes, DE = screen address).
- $97E4 (in $97B7) stores the queue tail: `@isub=LD (AddQueueJob+1),HL`.
- Stores into $AD88/$AE20/$AE4B once labelled: $A171 -> $AD8D (LD A,n at
  $AD8C), $A176 -> $AD8F (LD B,n at $AD8E), $A186 -> $AD9B (BC count), $A18E
  -> $ADA0 (JR offset at $AD9F), $A195 -> $AD8A, $A1AA -> $AD95, $A1AE ->
  $AD98; $A169 patches $AD88, $A1BA $AE20, $A1BF $AE4B (RET <-> NOP).
- $850B = direction of the last exit (0 right, 1 left, 2 down, 3 up),
  stored at $AD5C.
- $982E template: +0 handler $98F7, +2 graphics, +4 character rows, +5 row,
  +6 column, +7 attribute.
- Item flags: $851C, $851D, $851F gate the $95 scripts in rooms 19, 8, 20;
  $851A, $851B gate the $9C scripts in rooms 6, 7, 8 ($851A has no item).
- Bugs reported (check, then docs/06): draw queue has no bounds check; $90
  skips the cell at $6000; $8A bit 3 would write row 23 over the stack
  (unused); $A1DE wrong for rows not multiple of 8 (never used so); $A0DF
  loops forever with block size 0 (initial state).
- Splits proposed by W12: $BA32 (common body of the two Death halves),
  $BADF (scythe free), $BB02 (scythe draw), $BBA0 (Satan alive), $BC20 (Satan
  sprite and hit test).
- Move @equ SPAWN_TEMPLATE=$5DFC (BA79) and SPAWN_POSITION=$5DFE (BA15) to
  head.skool.
- W12 code writes the draw-command fields $ACD3, $ACD5, $ACD7, $ACDA, $ACDD,
  $ACDF, $ACE1, $ACE4 as plain addresses: @isub once $ACD1 is labelled.
- Checkpoint rule: $BDF3 stops at the first NONZERO flag of $8543..
  ($A688 zeroes the others and sets its own to 2); no flag: room 5. The
  classification note (first zero) is wrong.
- $83A8 records are (word, y, x), not (word, x, y).
- $850C=4: set by the death code at $AA9D ($84, INC to $85 when lives run out).
- Hit flag $A8A0: $FF from $A87A on overlap, 4 for class-4 cells.
- $8521: flag of the room-24 item made by $A734 (read by $A668, $AE4B);
  $8522 read by $B6E6.
- Constants to dedupe: ATTACK_PERIOD, SFX_ENEMY_SHOT, OBJECT_ENTRY_SIZE,
  TILE_CLASS_MASK, MUSIC_TRACK_7, PLAYER_DYING, PLAYER_STANDING (W12).
- Bugs: $BB50 sliding scythe on a solid cell draws at y = x (inferred);
  Death's turning test is an equality; LD E,D at $BA80/$BA83 do nothing;
  the frame list has no overflow check.
- Tool notes: zxq check prints only a block offset, not the entry at fault;
  label duplicates show only at assembly.
- W5 splits: $9C58 "Show a full-screen text window" (entered by the ending
  $887B), $9DD7 "Fill a rectangle of the tile map" (CALL from $9DC2, JP from
  $A15C); $9DFE optional.
- Writers of the LD HL,nn operand at $9CEE ($A615, $A75A, $BB57):
  `@isub=LD (SmcEventScript+1),HL`.
- Gates armed: $9C51 by $A836; $9C1B by $A782 and $85FC; $9BF3 by $A70B.
- Drop constant OP_FIRST (unused); F21 overlaps F11.
- Script operand lengths (W5, observed F13): $8D 5+c, $92 3+2k, $94 5+c,
  $9D 5 bytes.
- Open: why $9C58 sets $850C to 0 while the window is up; flag class 2.
- W7 splits: $A339 "Title: wait for ENTER, SPACE or C" (called from $85FC),
  $A354 "Controls screen: draw and menu loop", $A37A "Redefine the four
  keys", $A45E "Copy the menu area", $A71F "Free the object slot with sound
  5", $A724 "Free the object slot" (used by $A849), $A78B "Take a cross",
  $A799 "Draw a cross of the lever-off set", $A6F2 "Enter a room at an arch".
- $AABE: SMC byte JR ($18) / JR Z ($28) when the cheat is on: label it.
- $8502/$8503: mask and row of the first key found by $A29C (set by $A43D,
  read by $A3B9): label.
- Flags: $851A church door shut; $851B bell; $851C, $851D levers; $851E
  lever of room 17; $851F gate lever; $8521 chalice taken; $8523, $8524 arch
  latches (bit 7); $8534 final scroll. $8512/$8514 arrival position (set by
  $A6BC, $A6D8). Checkpoint flag $8543 set to 1 by the church door $A615,
  $8544-$854B set to 2 by $A688 (clears all nine first).
- Title script $A526 drawn only when $85FC runs from the top (after game
  over or the ending); the first start enters at $8606 and the loader
  picture is the title.
- Bugs (W7): cheat check XORs 8 bytes (any keys with the same XOR, e.g.
  Z X C 5); chalice at $A734 takeable with < 12 crosses by position poke;
  $A29C/$A304 scan orders differ (two keys in a row); attribute fill at $A450
  overwritten; $A31E loses the key code; Kempston up ignored; SP as data
  pointer in $A5E9.
- Copied the RAGE cheat run to tests/inputs/cheat.txt (make expected!).
- Labels needed (W1): $8719 (RET at the end of $86B9), $8606, $860C, $88D5,
  $871A (patched by $605F), $85BE, $AD71, $AD82.
- `@isub=LD H,FlagRowTable/256` at the LD H,$61 in $A9D2 ($AA14), $B44B,
  $B6E6, $B74B, $BAB1, $BB07.
- Item types ($8EDF): 0 heart, 1/2 cross, 3 checkpoint, 4 bell, 5 parchment,
  6 red scroll (ends the game), 7 church trigger (sets CheckpointFlag0), 8
  doorway arch, 9 lever, 10 wheel, 11 chalice; the wheel swaps which
  crosses are real.
- Quirk F67: room 4's script clears the HUD rows and nothing redraws them.
- W8: $B43C, $B4B7, $B5F6 read ($A8A2): `@isub=LD A,(PlayerX+1)`.
- $A70B and $A7B1 say "SP slot+4" for the flag pointer: it is slot+6.
- $8B07 header: read by $A7DB (DrawItemFrame), not $A7CB.
- $CD00: class 1 = one-way platform (F74). $83CE/$AAC0: reachable with the
  cheat (T key, F78). $AD71/$83CE comments: point to LeaveRight/Left/Up/Down.
- W8 splits (labelled already): $A7DB, $A85F, $A903, $AA56, $AA99, $AB25,
  $AB31, $AB79, $ABA8, $ABFC, $AC1C, $AC4C, $AC80, $AD14, $AD2A, $AD5C.
- Bugs (W8): room number underflow (left from room 0 -> 5, up from 2 -> 3,
  F77); exit test depends on facing; $A96F duplicates $A9B4; $A9FE column
  mask always $1F; one side blocked skips the other direction; dying frame 7
  not drawn (monk invisible 4 frames).
- W11 splits: $B6ED "Entity handler: projectile in a straight line
  (arrows)", $B716 "Remove a projectile", $B71B "Draw a projectile", $B6D9
  "Queue the sprite of a frame table", $B7D6 "Fish jumps out of the water",
  $B9BE "Moving sprite: position and hit test", $B611 (optional).
- $B5D6 is the stone head of rooms 20 and 22 (kind 11): shoots
  WallShotTemplate every 70 frames; its jump target $B611 is
  UpdateShooter_Common.
- C-report and $BC92 template comments outdated: $B74B and $B924 run; the
  flames $BD22/$BD34 and the splash $BD12 are known ($BD22 says "never seen").
- In the ending $B9A3 sets $A894 and $A8A0 to 2: the player's sprite runs
  the dying animation.
- Bugs (W11): pyre monk countdown wraps to $FFFF (harmless); plant reload
  read from +$B not +$13 (same value); seeds test one flag cell, arrows two.
- Tool: `zxq.py check FILE...` now builds HEAD + the given files.
- W10 splits: $B2C3 "Place an entity sprite (facing left or up) and test
  the hit box", $B380 (right or down), $B3AD "Read the sprite description
  and animate (right or down)", $B3D8, $B3E4, $B407, $B41F.
- Kinds ($B028): 0 $B391 intro runner, 1 $B099 crusaders (rooms 5, 6, 25),
  2/3 horizontal patrol, 4/5 vertical patrol, 6/7 hanged men (room 9), 8
  $B44B chaser (room 11), 9 $B512 drops, 10 archer, 11 $B5D6 stone head, 12
  plants (14), 13 fish (16, 19). Creature = sprite block, not handler: rats
  (2), bats (8), worms (9, 14), skeletons (13, 22), crusaders (15, 20),
  demons (21, 22), flyers (20, 23), ceiling ghosts (22, 23); spiders (3, 14,
  16, 19), flies (12), fireballs (22, 23).
- $B426 duplicates $A724 (FreeSlot).
- Bugs (W10): patrol limit tests are equalities (latent); chaser flag
  probes wrap rows at columns 0, 30, 31; rope INC L wraps at column 31.
- W2 splits: $8664 main loop proper, $869F ending and game over branches,
  $85EE and $85F3 128K music stubs, $8754 noise step, $876E tone step.
- $854E description wrong: a request replaces a playing effect at once.
- $83A8 and $8552 descriptions: records are (template, y, x).
- Bugs (W2): $87D7 stores A over the low byte of the noise pointer (noise is
  R XOR 1; effect 1 never requested); spawners skip the carry test after
  $8A6E (harmless, <= 10 records vs 11 slots); PUSH BC at $858E useless; a
  second interrupt between EI at $85B5 and JP at $85B9 would hang
  (theoretical); 128K title not redrawn after game over (inferred); R+Y
  ignored in the intro; $861E redundant.
- Timing (F103): logic once per interrupt; the foreground draws; a busy
  frame overruns and its sprites are not queued (586 draws / 800 frames).
- W3: $A851 block bytes +E/+F are the far corner relative to the position,
  not a size: handler docs saying "hit box size" are wrong when the offset
  is not 0. $B04C `DEFW $93E5` -> BehaviourCrusader+5; $BC92 templates can
  use SpriteBlock* labels ($94F9, $9595, $95DA). Text typos in the game:
  "Lanquedoc", "Gloomy tunels". Bugs: redraw index and $C200 list size
  unchecked; $97B7 EXX never undone (harmless); $976B SP in tile bitmaps.
- W9 splits: $B1D4 "Entity handler: crusader following its path script",
  $B1F3 "Take the next path command", $B18E "Common tail of the crusader
  jumps".
- W9: PackedSet descriptions wrong: a clear flag bit repeats the previous
  byte of the column (0 only at the top) (F113). Stores into the effects:
  $A168 -> `@isub=LD (SmcWaterAttr+1),A` etc.; `LD ($AD88),A` -> `LD
  (DrawWaterReflection),A`; $A1B9 -> AnimateBloodTiles; $A1BE -> ShowCrossRing.
- W9 bugs: path scripts have no terminator (room 25 runs into $B236 after
  command 5, inferred); spawner reload byte used only once (then 40); the
  spawner reloads even without a free slot; set 6 width 5 with 4 columns;
  $AF7B/$AFC9 advance E without carry. Main loop runs a pass per frame in
  room 5, one per 1.7-2.5 frames in rooms 22, 24.
