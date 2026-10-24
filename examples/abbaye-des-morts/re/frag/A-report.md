# Classification $6000-$8A8E (subagent A)

| Range | What | Status |
| --- | --- | --- |
| $5E00-$60BF | room tile map buffer, 32x22 tile numbers; overwrites the start-up code at $6000-$6072 | buffer |
| $60C0-$60FF | main stack (SP=$6100) | stack |
| $6100-$612F | row address table, 24 words $5E00+32n, built at start-up | buffer |
| $6130-$61EF | font index, 96 packed words | font |
| $61F0-$66DB | proportional font glyphs, 16 rows high | font |
| $66DC-$68CB | sprites 16 wide: door arch 16x24, 14 of 16x16 | gfx |
| $68CC-$717E | 20 packed sprite sets (enemies, Satan, dragon...) | gfx packed |
| $717F-$71DE | 12 parchment frame tiles, 8x8 | gfx |
| $71DF-$7235 | parchment frame layout | layout |
| $7236-$7269 | room script addresses, 26 words | words |
| $726A-$83A7 | room scripts (bytecode for $9D5F), rooms 0-25 and subscripts | script |
| $83A8-$83CD | cutscene actor lists | data |
| $83CE-$83E5 | unused debug routine (room warp) | code |
| $83E6-$83FF | music track per room, 26 bytes | data |
| $8400-$8500 | IM 2 vector table, 257 x $85 | data |
| $8501-$855E | game variables | vars |
| $855F-$8584 | interrupt stack | stack |
| $8585-$87E7 | interrupt handler, 128K paging and music calls, main loop, beeper effects | code |
| $87E8-$87F1 | sound-effect state | vars |
| $87F2-$8831 | sound effects 2-9, 8 bytes each | data |
| $8832-$8A8E | title, ending, cutscene, object and enemy spawning | code |

- Font $6130: word per character at $6130+2*(char-$20): bits 0-11 offset
  from the address of the word's high byte to the glyph, bits 12-15 width-2.
  Glyph: mask word (bit 15 row 0; set = a new row pattern follows), then 1
  byte per new row (2 when width >= 9). Mask 0 = empty. Ends at $66DB.
- Sprites $66DC: table $8B07 points to $66DC, $670C, $672C...$68AC; $98F7
  draws them popping 2 bytes per row.
- Packed sprite sets $68CC: 2-byte header (columns, character rows), then
  a flag byte per 8 pixel rows (set bit: a literal byte follows, clear: 0);
  unpacked by $AF15/$AF58 from the records at $AE9D.
- Parchment layout $71DF ($9C96, $9CB7): position word, then 11 columns of
  24 cells; `1,n` = n blank cells, k>1 = tile k-2 from $717F; 0 at $7235 ends.
- Room scripts: $86B9 runs $7236+2*room through $9D5F; <$80 prints a
  character, >=$80 dispatches via $9D1F; operand lengths of all 32 opcodes
  known (some depend on operands: $88, $8B, $8D, $91, $94). Static decoding
  reproduces all 560 traced opcode starts. Subscripts: op $83, $95 (flag 0),
  $9C (flag nonzero), others via $9CEE. Room names via op $87 and $9048.
  Room 25 ($82D0) calls room 24's script; the twelve-crosses script at $82D4
  holds a coordinate list at $82D7 also read by $AE4B.
- $85C2-$85FB: 128K-only code (paging, call DE in the music bank); $605F
  patches $860C, $88D5, $871A to reach it.
- Variables: $8512-$854D zeroed by $85FC at a new game; $854C lives (9);
  $854D crosses; $854F sound request, $854E effect playing; $850D room-name
  message; $850E/$850F parchment messages; $850A = $1A, end marker of the
  room-keyed tables, read with $8509 as a word; $8551 music track (unread
  on 48K).
- Open: meaning of $850B, $8516-$8519, $8521-$8524, $8543-$854B; which of
  $851B-$8540 belongs to which object; sound-effect fields; opcode meanings;
  $85BD (lone RET) and $85EE have no known caller; $8508, $8550 unused.
- Conflict to settle in annotation: subagent D says the tile map is at
  $5Bxx and the flag map at $5Exx.
