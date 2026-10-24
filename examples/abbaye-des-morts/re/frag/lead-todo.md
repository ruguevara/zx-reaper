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
