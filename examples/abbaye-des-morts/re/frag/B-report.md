# Classification $8A8F-$A595 (subagent B)

| Range | What | Status |
| --- | --- | --- |
| $8A8F-$8AA6 | object type table, 12 pointers (index = type*2, read by $897E) | words |
| $8AA7-$8B06 | object type records, 12 x 8 bytes | records |
| $8B07-$8B8E | frame lists, 34 x 4 bytes (sprite address, attribute, 0), read by $A7CB | records |
| $8B8F-$8EDE | room objects, 77 x 11 bytes, ended by $1A | records |
| $8EDF-$9047 | room items, 45 x 8 bytes, ended by $1A | records |
| $9048-$93D2 | text table: 53 strings, a length byte then the characters | text |
| $93D3-$95FE | behaviour data for object kinds, 26 blocks | records |
| $9636-$965F, $9685-$96AE, $96C9-$96F2 | unrolled LDI/LDD chains, entered by a JR at $9634/$9683/$96C7 whose offset is patched to 2*(32-width) | code |
| $982E-$9835, $98D9-$98E3 | draw-queue job templates | vars |
| $99E8-$99F1 | jump table of 5 sprite drawers ($99C9) | words |
| $9BD3-$9BF2 | 4 x 8-byte screen-scroll setups, indexed by $850B | records |
| $9CF3-$9D1E | 22 attribute row addresses $5800+32n ($95FF) | words |
| $9D1F-$9D5E | jump table for script codes $80-$9F ($9D5F) | words |
| $9F26-$9F27, $9F93 | text cursor (y, x); string alignment mode | vars |
| $A097-$A0B3 | unused script handler | code |
| $A116-$A119 | block descriptor set by script code $88 | vars |
| $A15A-$A15B | handler for script code $9A | code |
| $A22F-$A23F | unused copy of $A21E | code |
| $A2B7-$A2BE | cheat-check pairs ($A422) | data |
| $A2BF-$A2DA | keys and controls ($A2BF keys, $A2CF-$A2D2 controls, $A2D3 row buffer) | vars |
| $A2DB-$A303 | key codes in keyboard-scan order, 40 + 0 ($A304) | text |
| $A31E-$A32C | wait for SPACE release, 128K only ($605F turns the RET into CALL $85EE) | code |
| $A3A9-$A3B8 | redefine-key prompts, 4 x (script, key-pair address) | words |
| $A41A-$A421 | "en","sp","cs","ss" ($A3F6) | text |
| $A493-$A595 | screen scripts (controls, Kempston/keyboard, prompts, title, game over); $A4F2-$A4F9 key-name buffer | script |

- Type record (8): +0 -> IX+8/9, +1 -> IX+$0B, +2 handler ($A600/$A822)
  -> IX+0/1, +4 frame-list pointer, +6/+7 -> IX+$0E/$0F ($897E).
- Room object (11): room, kind (index into $B028), 7 parameters, pointer to
  a behaviour block. $89D9 scans with LD BC,($8509), stops at room
  ($850A)=$1A; $89ED reads 5 header bytes, stores block+5 in IX+$10/$11.
- Room item (8): room, pointer to a flag ($851B...), type, 4 bytes; made
  only if the flag is not $FF ($8957/$896B/$897E).
- Behaviour blocks: 5-byte header, then for most kinds attribute, pointer
  to a pair table ($AC9F, $9463, $94DB, $95D2), a byte, two frame-list
  pointers, sprite addresses ($D7xx/$EFxx).
- Text: length-prefixed; $9F43 finds string N from $9F48; $9F52 measures it
  in the proportional font at $6130 (offset word, width in the high
  nibble). 0-24 room names, 25-36 parchments, 37 Game Over, 38-42 intro,
  43-52 Satan/heresy/ending.
- Scripts ($9D5F): <$80 prints a character; >=$80 indexes $9D1F. $80 end;
  $81 fill 4+1; $8F attribute 4+1; $8E at y,x 2; $82 alignment, y 2; $85
  string number 1.
- Open: strings 0 and 4 (names of rooms 0, 4) are ":)" and ":$"; $9A4C
  reads stray bytes at $xx3C-$xx3E; the 16-byte copy at $98B1 takes code
  bytes after the templates; never-read frame lists from $8B6F, 2nd/4th
  scroll setups; $A2C9-$A2CE (three fixed keys) and the cheat flag $AABE;
  room object $8BD1 is for room 25, type 7 has a null frame-list pointer.
