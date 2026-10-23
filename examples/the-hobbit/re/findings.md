# Findings

Every claim about the game with its status and evidence. `observed`: seen in the simulator, a byte check or a test; `inferred`: read from code, not run; `unknown`: open; `refuted`: shown wrong (keep it). Only observed evidence can make a claim observed. Edit through `tools/zxq.py finding`.

| ID | Status | Claim | Evidence | Refs |
| --- | --- | --- | --- | --- |
| F1 | observed | Dictionary at $6000: 27-word index by first letter then 5-bit-letter words (562 words, class in bits 5-6 of bytes 1,2; synonym pointer if bit 6 of last byte); messages name words by 12-bit offset from $6000 | /tmp/hobbit/ctl/text.py decodes all; 108 messages printed by $72DD in the simulator equal the decoder output | $6000 $72DD $74C1 |
| F2 | observed | Messages $AD7D-&#36;B6D9 are a bytecode: $20-$5F literal, $60-$7F common word (table $AD3D), bit 7 = 2-byte word token (mode in bits 4-6), $14/$15/$16 end; code 2 jumps / 11 calls relative to its byte; 177 messages end exactly at $B6DA | text.py render() vs zxrun --call 0x72DD: 108 of 111 state-independent messages identical, the other 3 differ only by 42-column word wrap | $72DD $AD7D |
| F3 | inferred | $AB53 is the command table: 59 8-byte records (verb word, 2 prepositions, flags), id=index+1 stored in $B6E7 by $79C5; terminated by a zero word at $AD2B; $AD2D/&#36;AD35 article tables; $AD3D common words | read from $79C5-$79D9, $7BDB-$7BF0, $743F-$7476, $7493; flag meanings not decoded | $AB53 $79C5 $7BB0 |
