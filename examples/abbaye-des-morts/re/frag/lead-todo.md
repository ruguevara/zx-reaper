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
