# Classification $A596-$BE55 (subagent C)

| Range | What | Status |
| --- | --- | --- |
| $A894-$A8A4 | player variables | vars |
| $AAC0-$AAC5 | enter debug room-warp mode (unreachable: JR $AAC6 at $AABE skips it) | code, unused |
| $AC9F-$ACD0 | player frame tables | data |
| $ACD1-$ACEE | three 10-byte sprite draw commands | vars |
| $AD71-$AD87 | debug room-warp routines | code, unused |
| $ADA1-$ADC0 | 16 LDIs of a block copier entered at $AD9F (JR offset $ADA0 set by $A18E) | code |
| $AE9D-$AF14 | graphics unpack commands, 20 x 6 bytes | data |
| $B028-$B04B | entity handler table, 18 words | words |
| $B04C-$B08D | 3 entity templates of 22 bytes (handler $B1D4) | data |
| $B0E8-$B10B | 3 speed curves, 6 signed 8.8 words each | words |
| $B20C-$B217 | 6 path command handlers | words |
| $B218-$B235 | 3 path scripts: (target coordinate, command) | data |
| $B74B, $B924, $BB07, $BC69 | handlers never executed (falling projectile, continuation, second state of $BAB1, template $BD6A) | code |
| $BC92-$BDD9 | entity templates (16, 18, 22 bytes) | data |
| $BE2A-$BE47 | 10 checkpoints x 3 bytes: room, row, column | data |

- Player state $A894: 0 none, 1 dying, 2 jumping, 3 crouching, 4 standing or
  walking, 5 falling, $FF debug warp. $A895 animation timer, $A896 frame,
  $A897 facing (0 right, 1 left), $A898 vertical speed word ($01FE at a
  jump), $A89A-$A89B unused, $A89C-$A89F tile flags head/right/feet/left,
  $A8A0 hit flag, $A8A1/$A8A3 X/Y in 8.8, high byte in 2-pixel units (X
  0-$7F, Y 0-$57); X/4 = byte column, 4 shift phases.
- Sprite draw command (10 bytes): routine word ($9836 or $97FD), y, x/4,
  graphics word, width, height, unused (popped as F), attribute; copied to
  the list at ($BE58) by $AA1F.
- Unpack record (6 bytes, $AE9D): destination, source, flags, width; flag
  bit 7 pre-shifted copies ($AF7B), bit 6 mirrored ($AFC9); read at $AF15.
- Entity templates: stack frames popped as words; slots of 22 bytes at
  $C100; word 0 the handler; a word near the end points into $93E5-$95F6.
  $B04C's templates (handler $B1D4: +2 speed, +4 path, +6 coordinate) are
  pointed to from $8BC2/$8BCD/$8BD8; $BD80-$BDC8 from a table at $83A9-$83CA.
- Checkpoints $BE2A: the first zero among the nine flags at $8543 picks the
  record, else the 10th ($BDF3). [Corrected later: the first NONZERO flag
  picks the record, F33/F48.]
- Debug warp (observed): poke $A894=$FF; $AAAF jumps to $83CE (code inside
  the $811B data block), reads $A2D1, calls $AD71 to move rooms; bit 5 jumps
  to $AD82 (back to state 4). P moved room 5->6->7, A 7->12.
- Self-modified operands: JP $A880 target ($A881, by $A851), $A5FD, $AA1F
  (NOP/RET), $AD88/$AE20/$AE4B (NOP/RET), operands in $AD89-$AD9C, $AE5B,
  $B131, $B15B, $B188, $B5A0, $BDDA, $BDEC.
- Open: $83CD-$83E5 should be code ($83CE); records $83A8-$83CC (?, ?,
  template pointer); template middle words; upper index of the $ACB3 dying
  table and the speed curves.
