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
