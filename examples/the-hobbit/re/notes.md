# RE notes

Facts that are not yet in the skool/asm comments: memory map, loader stages,
open questions. Keep it short; move each fact into the source once its
routine or data block is annotated.

## Tape

| Block | What |
| --- | --- |
| 02-03 | BASIC `hobbit` (autostart 5): `CLEAR 24575`, black screen, `LOAD "p" CODE 16384`, `LOAD "h" CODE`, `PRINT USR 27648` |
| 04-05 | `p`: the loading screen, 6912 bytes at $4000 (`data/screen05.scr`) |
| 06-07 | `h`: the game, 40000 bytes at $6000-$FC3F; entry $6C00 |

A standard ROM loader, no protection.

## Memory map

| Range | What | Status |
| --- | --- | --- |
| $4000-$5AFF | screen: picture rows 0-15, story window, input window rows 19-23 | O |
| $5C00-$5CB5 | system variables: only BORDCR ($5C48, set to $38) and those the ROM tape routines use | I |
| $5E00-$5EFF | stack (SP $5EFF from $6C28) | I |
| $5F00-$5FDB | copy of the state blocks $B6EB (29) and $CA84 (191), made at $6C00 | O |
| $6000-$6BFF | dictionary: letter index, 562 words in 5-bit letters (see Text) | O |
| $6C00-$AB52 | code, with variables, tables (control codes $7295, actions $75D2, $8271/$828B), the font $8822 and key tables $8BFB/$8C23 among it (see Code region) | O/I |
| $AB53-$AD7C | command table (59 verb phrases), article and common-word tables | O/I |
| $AD7D-$B6D9 | 177 messages (bytecode, see Text) | O |
| $B6DA-$B6EA | parser variables | I |
| $B6EB-$CBFF | world: variables, locations, objects and characters, handler tables, NPC scripts, timers (see World) | O/I |
| $CC00-$F35A | picture table and 22 pictures (see Pictures) | O |
| $F35B-$F3FF | zeros, unused | I |
| $F400-$FFED | copy of the state blocks $C11B (1557) and $BA8A (1497), made at $6C00; QUIT copies them back; $F400-$FC3F is loaded as zeros | O |

The game state is four blocks, the ones SAVE writes and the start copies:
$B6EB/29, $C11B/1557, $CA84/191, $BA8A/1497 (3274 bytes).

## Hardware

- Interrupts are off: DI at $6C00 and $6C27, no EI in the game. The ROM's
  tape routines return with EI; the game waits for keys with interrupts on
  and DIs at $8488/$8553 after SAVE/LOAD.
- ROM calls: SA-BYTES ($04C2) for SAVE, LD-BYTES ($0556) for LOAD and verify.
  Nothing else from the ROM (its own keyboard scanner, font and print code).
- `LD A,R` at $6CA7 once per game start, after the title key: the random seed ($B70E).
- Keyboard: its own scanner at $8B93 (edge-triggered, ASCII from tables
  $8BFB/$8C23); waits for any key at $969A (after a picture), $84B9, $6C6D.
- ZX printer: port $FB at $8B31-$8B72 (PRINT/NOPRINT). With no printer the runner reads $FF.
- Fonts: the game's own 96-character font at $8822 (42 columns in the story
  window); the input window uses the ROM's at $3D00 (32 columns).
- SPACE held into the ROM's tape routines is BREAK: SA/LD-RET raises a BASIC
  error that crashes the game (seen pressing SPACE at the verify prompt).

## Open questions

## Init (zxinit.py)

- original: `original/game.tzx`
- code region: $6000-$FC3F
- handover PC: $6C00

## Text: dictionary, messages, command table


Decoder: `scripts/text.py` (words, msg ADDR, all, verbs, --selftest).

### Dictionary $6000-$6BED (observed)
- $6000: 27 words, entry n = offset (from $6000) of the first word starting with letter n
  (A=1 ... Z=26; entry 0, X and Z are 0). $6036-$603F and $6BEE-$6BFF are zero fill.
- Words from $6040 (offset $040) to $67AA, grouped by first letter, then $67AB = 0 (pad), then a
  second group $67AC-$6BED (offset $7AC-$BED, 562 words in all) used only by messages.
- A word is 3 or more bytes. Bits 0-4 of each byte = letter (1=A..26=Z; 0 ends the printed
  word); bit 7 = last byte, except in byte 2, and in byte 3 when byte 2 has bit 7.
- Class = 4*(bits 5-6 of byte 1) + (bits 5-6 of byte 2): 0 adverb/other (also all of group 2),
  1 in/into, 2 directions, 3 verbs, 4 go/run, 5 nouns, 6 adjectives, 7 prepositions,
  8 article/aux (a an the is are can that), 9 all/except/it/load/save/quit/print..., 10 and, 11 then.
  Returned by the parser in the high nibble of the word token ($6F1A-$6F2D).
- Byte 2 bit 7: the word is a verb that takes a suffix; byte 3 bits 5-7 = index into the four-byte
  entries at $B71F: 0 "s", 1 "es", 2 "ies", 3 BS+"ies", 4 "d", 5 "ing" (read by $7512-$752E).
- Last byte bit 6: two more bytes = offset of the word it is a synonym of (kill, hit, capture =
  attack; get, steal, lift = take; n, ne... = north...). Read at $6F09-$6F19.
- Parsing ($6F47, $6F76, $6FBA, $6EC0): index by first typed letter, compare letter by letter; a
  typed word matches a longer entry as its prefix when the entry is 4+ letters (inferred).
- Printing ($74C1, $74D8): offset in DE (high nibble = print mode) -> letters, optional suffix.
  Offset 0 prints nothing.

### Messages $AD7D-$B6D9 (observed): 177 messages, back to back
Read by $72DD (HL = start, caller CALL $72DD); the loop $72F4. Item at IX:
- $20-$5F literal char (prints lower case; first letter after a full stop / a mode-7 word is capital)
- $60-$7F common word: 16-bit entry (b-$60)*2 in $AD3D; D = high byte + $50 (mode 5) ($7493)
- bit 7: 2 bytes. D = first & $7F: bits 4-6 print mode, bits 0-3 + second byte = word offset.
  Mode 0 plain; 1 + suffix when $B6E8 (object 1) <> 0; 4 suffix always; 5 never; 7 capital first
  letter; others (0,2,3,6,7) suffix when $B6EA (subject) <> 0 (e.g. "gives" for others, "give" for
  you). Modes 2/3/6 also END the message (nothing / "." + new line / new line) ($7303-$735B).
  A space is printed before each word unless at line start ($7543); letters wrap at 42 columns.
- $00-$16 control codes via $7295 (23 words; codes <$14 return Z = nothing to print, NZ = DE is a
  word token; $14-$16 end): 2 jump and 11 call the message at (address of its byte)+signed byte
  ($737E, $73E0) -- many messages end by jumping into the middle of another;
  13 line break ($72C3, clears the capital flag), 8 back-space; $14 new line + end, $15 "." +
  new line + end ($7344), $16 end.
  State dependent (inferred from the code, checked by running with $B6EA/$B6E8 poked):
  0 thing from the stack ($7367), 1 word token from the stack ($7376), 4 same, with article ($7394),
  3 word at $B6FC ($738D), 6 name of $B6EA ($73A3), 7 name of $B6E8 with article ($73AF),
  9 same for $B6E9 ($73C2), 12/14 "his" or "your" for $B6EA / $B6E8 ($73F9/$7407),
  16 "<subject> are/is" ($740C), 17 same for $B6E8 ($7425), 19 same, from the stack ($742D);
  5, 10, 15, 18 do nothing.
- Referenced starts are all message starts (or the tail of one: $ADA9, $ADC4, $AFB5, $B018, $B143).
  Not messages: $B6DA-$B6EA (variables, below).
- Verified: 108 of 111 messages without state-dependent codes print exactly the decoder's text
  (`zxrun --poke 0xB701,0 --call 0x72DD --reg HL=addr`, screen cleared, `--text 0x8822`; the other
  3 differ by word wrap in the middle of a literal word). With $B6EA=$20, $B6E8=$1D the suffixes
  of $AE5A, $AE8B, $AE70, $AF2B, $AE0C ("gives", "misses", "slices") match too.

### Tables
- $AB53 command table (inferred): 59 records of 8 bytes, id = index+1, end = zero word at $AD2B.
  +0 verb word (bits 0-11 offset, bits 12-15 flags 8/C/E/9/0), +2 and +4 prepositions (flags 2, A,
  1, 4, 8 above the offset), +6 flags ($4000/$8000/$6000/0; $02DE = GO for ids 1-10, whose +0 is
  the direction). Matched against the parsed phrase in $71F3/$722E from $7BDB (IX=$AB53, step 8);
  $79C5-$79D9 turns a record address into the id stored in $B6E7. Flag meanings not decoded.
- $AD2D, $AD35: 4 word offsets each, "the a an some" / "the the the some", picked by the noun's
  class bits in $743F-$7476 (second table when typing, $B701).
- $AD3D: 32 common-word offsets (bytes $60-$7F): a and are at be blow but cannot carrying do door
  dragon fall from here i in is it not of on see some the there this to too what with you.
- $B71F (outside the range, in the state block): the suffix table.

### Variables $B6DA-$B6EA (inferred, names are guesses)
$B6DA W typed-line pointer ($6E9F, $7876), $B6DC W word-list pointer ($7873), $B6DE flags nibble,
$B6DF "partial match" flag ($71FE), $B6E0 6 bytes (copied from $7942), $B6E6/$B6E7 command id
(looked up at $C730), $B6E8/$B6E9 first and second object, $B6EA subject (0 = player, $FF none).

### Other
- $AB27 is code, the tail of the routine from $A9E5: the instruction at $AB25 (LD A,($C12B)) is cut
  by the entry boundary at $AB27 (and the CALL $72DD at $AB22 by the one at $AB24).
  $AB27-$AB38, $AB4A-$AB50 ran (journey.map); $AB3A-$AB49 not, but they are code.
- Open: meaning of the flag nibbles in the command table; $ADDA is a bare $14 (an empty message,
  no reference found); exact role of the capital flag $B704.

## World: state, locations, objects, scripts


Status: O = observed (simulator/byte check), I = inferred from code. Actor 0 = player.

| Range | What | Status |
| --- | --- | --- |
| $B6EB-$B707 | saved variables (29): $B6EB/3 copy of script bytes $C9E2, $B6EE W random event, $B6F0 timers fired, $B6F2 printer, $B6F5 player location (O), $B6F6 location of the NPC last run, $B6F7 W score (O), $B6FA perform/$B6FB blocked, $B6FC W name ptr, $B702 messages visible, $B707 pictures (N held at start = 0) | O/I |
| $B708-$B71E | not saved: $B708/A/C records of noun1, noun2, actor (O: $B70C=$C11B), $B70E seed (O), $B712 ROM walker, $B717 W, $B71B 1 = parsing a stored order | I |
| $B71F-$B736 | 6 x 4 bytes word endings s, es, ies, BS+ies, d, ing; index = top 3 bits of 3rd dictionary byte (x4), $74BA | I |
| $B737 | count byte for the order slots ($7EBA) | I |
| $B738-$B7FF | 8 order slots x 25: owner id + 24 bytes of a stored parsed command (an NPC order); `say to X ...` filled B739.. (O) | O/I |
| $B800-$B9DF | parser phrase stack, 24-byte records growing down from $B9C8 (O: writes at $B9B0-$B9DF) | I |
| $B9E0-$BA7F | 80 words: location id -> record address | O |
| $BA80-$BA89 | 5 phrase codes (bit 7): outside, inside, in, on, at; index = (loc flags&$0E)/2 | I |
| $BA8A-$C062 | 80 location records (1497 saved) | O |
| $C060/$C063 | $C063: (id, record address) x 61 + $FF; $C060 = base-3 used by $9BA9 | O |
| $C11B-$C72F | 61 object/character records (1557 saved) | O |
| $C730-$C78D | default verb handlers (verb id, routine): 1-10 moves -> $8D9D, 0 = chain | O |
| $C78E-$C7A3 | arrival handlers (destination id, routine) | I |
| $C7A4-$C7FB | 6 small routines (code), 2 executed (journey.map) | O |
| $C7FC-$C80D | 4 random events (phrase code W-less 2 bytes, message W) | I |
| $C80E-$C82C | 5 blocked-exit records (loc, W exit-triple addr, saved triple) | I |
| $C82D-$CA83 | NPC behaviour tables and scripts | I |
| $CA84-$CACA | 10 timers x 7 (saved); $CACB-$CB42 17 NPC records x 7 (saved) | I |
| $CB43-$CBFF | 189 zero bytes, never referenced | O |

### Location record ($BA8A..; 10-byte header, then exits)
+0 flags (bit 7 clear in caves/dungeons; bits 1-3 -> preposition) | +1 capacity for objects ($FF unlimited,
$9C41 sums weights) | +2,+4,+6 phrase codes noun, adj, adj (words in the dictionary at $6000, see below) |
+8 W description text (0: print the phrase, $9689) | +10.. exits: direction, obstacle, destination; $FF.
Direction = verb id: 1 N 2 S 3 E 4 W 5 NE 6 NW 7 SE 8 SW 9 up 10 down (O). Obstacle = object id (door, river,
web, portcullis; flags bit 5/3 set = passable, $8E85) or 0. Location 0 is a 13-byte dummy. Exit search: $9F08.
Phrase code (2 bytes): low 12 bits = offset into the dictionary at $6000 (letters AND $1F + $60, bit 7 ends),
top nibble = style (bit 7 proper name; $87A8 = "you"); printed adjectives first, noun last ($9ED6).

### Object / character record (in $C11B, ids in $C063: $00 player, $01-$2B objects, $3C-$4C characters)
+0 N | +1 holder id ($FF: lies at the location) (O) | +2 weight, as container/actor the capacity ($9CE8 sums) |
+3 bulk/capacity ($9CED) | +4 state byte: the low nibble picks the relation message at $AFCA+4n ("In the", "On the"...), bits 4-6 a "side" tested by the attack check $914A | +5,+6 strengths
(combat $9171, $92BA) | +7 flags: bit 7 present, 6 character, 5 active/open/alive, 3 dead/disabled, 1 consumable
(O: door $C14C 80->A0 when opened) | +8,+10,+12 name phrase codes (up to 3) | +14,+15 spare |
+$10..+$10+N-1 location ids (O: NPC ids change as they walk; doors/rivers/webs list their 2+ places) |
then the verb table: (verb id, W handler) x k, id 0 = chain to the next entry, $FF ends ($9B81 + $9DBD).
Handlers called by the verb dispatcher $950F; if the object has none, $C730 is used ($94D6, $95CC).

### Scripts ($C82D..)
NPC record at $CACB+7k: +0 id (0 = dormant slot: $C7AA writes $42 butler, $C7D9 $46 Bard, $C7CE $3C dragon), +1 highest
random index, +2 W current script, +4 W behaviour table (id, W script; $FF; 0 default, $F idle, others by events/$0C),
+6 spare. Run by $980E for every NPC each turn. Command byte: low nibble op, bit 4 = extra W (alternative target),
bit 5 erase after use, bit 6 not interruptible by orders. Op 0/2: verb,noun1,noun2 executed as typed; 1/3: W routine +
pad; 4: verb only; $C: switch behaviour (arg id); $E: jump W; $F: random entry 0..arg ($9A59); 5-9,B,D: restart.
(O: script words change at $9921/$98D2/$99BD.) The command at $C9E2-$C9E4 is rewritten by code ($A8C1-$A8CE) and
saved in $B6EB-$B6ED.

### Timers ($CA84) and events
Timer = start, counter, W fire handler, threshold, W tick handler (called while 0 < counter <= threshold). $96B3
steps them each turn, at most one fires per turn ($B6F0). Arrival at a location (destination id, $8E24) may start
a timer (O: arriving at 3 sets timer 8 counter to 3). Random event table $C7FC: 4 x (phrase code, message W), the
choice is in $B6EE. Blocked exits $C80E: one of 5 chosen at start by $97AD, its exit triple zeroed, restored by $A7C4.

## Pictures


Table $CC00: 22 records of 3 bytes (id, address as word), FF at $CC42. Ids are
location numbers (index into the location table $B9E0 via $9BB1). Records are
in address order, ids are not. Data $CC43-$F35A (the last picture's $00 end
byte is $F35A), packed, no gaps. Observed: every picture parses to exactly the
next picture's start.

Ids and what they show (rendered by $7F78):
01 Bilbo's hall; 31 river valley, boat, village; 06 green hill, red spots;
0B moonlit pale cliffs; 25 bare hills, dead trees, bones; 2B green spiral;
26 ruined town at night; 07 cave: axe, pot, skeleton; 18 wall with gatehouse;
23 hill town on lake shore; 0D/1F round-domed stone building (yellow/red);
05/1C forest clearing (black/green); 04 the Lone-lands (the snapshot
lonelands.z80 has location 4: observed); 20 cellar with barrels, trapdoor;
10 spiral with five torches; 19 gnarled trees on blue; 08 river and waterfall;
29 arches and treasure hoard; 1A giant spider on a web; 27 lone mountain.
Location names are inferred from the images only (not from the game text).

Callers: $9630 (A = location) -> $965B (B = A; prints the description,
calls $7F78, then $9671: if $7F77 != $FF waits for a key at $969A (border
white after), so a picture is shown until a key is pressed).
$7F78 (A = id): returns at once with $7F77=$FF if $B707 = 0; else looks the id
up (IX=$CC00, $9DBD), stores id or $FF in $7F77, draws via $7FA7 (HL = data).
$B707 is set at $6C7C from port $7FFE bit 3: zero when N is held at start-up
(pictures off; inferred from the port/bit, not tried).

Drawing $7FA7 (IY = data; observed by running all 22 pictures, formats read
from the code):
- $820B: calls $95ED; carry set = too dark to see: border and attribute are
  taken as 0, screen cleared and the picture is abandoned (black); else
  header byte 0 = border (OUT $FE), byte 1 = attribute that fills $5800-$59FF;
  pixels $4000-$4FFF cleared. The picture area is the top 16 cell rows
  (256x128 pixels).
- Pen D,E starts at x=$7F, y=$3F; pixel row = $7F - y (y grows upward), $81DE
  gives the byte address and bit mask, $81B5 plots (sets the pixel and sets the
  attribute of the cell to ink = fill colour $824E, paper kept).
- $00 end. $08 x y: move pen. Other values 1-$1F are ignored (none present).
- $80-$FF line, 2 bytes (code $7FD5): byte1 = 1 rrrr L U V, byte2 = rr nnnnnn.
  V=1 vertical-major ($8185) else horizontal-major ($8151); U=1: y-1 (up)
  else y+1 (bit1 of C); L=1: x-1 else x+1 (bit2 of C); n+1 steps on the major
  axis; every r+1 major steps one minor step (r = rrrr<<2 | rr, B=r+1).
- $40-$7F fill, 3 bytes: ink = A&7, x, y; flood fill by scan lines ($8071,
  stack of spans, boundary = lit pixels) in ink colour A&7 ($824E).
- $20-$27 paint, 3 bytes + runs: paper = (A&7)<<3, then H,L = attribute
  address (high byte first), then run bytes: dd = byte&3 (0 up -$20, 1 right
  +1, 2 down +$20, 3 left -1), count = (byte>>2)+1; $FF ends. Each cell: paper
  := colour, ink inverted if it equalled the new paper ($8012-$8066).
- 0D and 05 are short prefixes that end with $08 whose x,y bytes are the header
  of picture 1F / 1C, so after the prefix the other picture's strokes run: 0D
  and 05 are variants of 1F and 1C (other colours, extra details first).
  Observed from the byte stream and renders (0D yellow, 1F red; 05 black, 1C green).
- $6C2B-$6C3D (in $6C00, the QUIT/restart routine) zeroes the border and
  attribute bytes of picture 5 each time it runs. On this tape they are 0
  already (re/tape/07.bin), so it changes nothing here; reason unknown (maybe a
  leftover; inferred). Picture 5 is black anyway, with white lines.

$F35A-$FC3F: $F35A = end byte of picture 27; $F35B-$F3FF zeros, unused;
$F400-$FC3F is part of the backup of the state blocks written by $6C00
($C11B/1557 -> $F400.., $BA8A/1497 -> $FA15..$FFED, restored at $6C3F);
observed in bagend.z80 (the backup equals $C11B at start-up). Zero on tape.
Player location: $B6F5 changes with it (1 in Bag End, 4 in the Lone-lands) and
objects at $C12B, $C1E1, $C3B0, $C3C2 (observed in the two snapshots; poking
them did not move the player: not understood).

## Code region: tables, variables, self-modifying code

# Code-region data ($6C00-$AB26): formats found

Most
"data" entries were handlers never run in our inputs: they are reached through
tables ($7295 control codes, $75D2 actions, $828B words, $C730 command ids, and
$C2xx-$CAxx handler words) and are now type c.

### Data structures
| Where | What | Read/written by | Status |
| --- | --- | --- | --- |
| $6DCC (10) | border tile: 5 pixel rows x 2 bytes, repeated across 32 cells at $5140 | $6CD3 | observed |
| $6FF2 | "> LOOK" CR: first command; $6FF4..$6FF8 copied into the input line | $6CFA-$6D0F | observed |
| $6FF9 (128+CR at $7079) | input line buffer, blank filled | line editor $6E44-$6E68, parser $6E97 | observed |
| $707A (16) $708A (1) $708B (16) $709B (1) | word lookup: letters (5 bits each), length, matched dictionary letters, count | $6F47-$6FAC | observed |
| $709C (64) | parsed command: pairs (tag, word); tag high nibble = class; read back by $7873 via ($B6DC) | $6D61-$6D6F, $7873 | observed |
| $70DC, $70DD, $70E0 | message printer's saved A, DE, IX | $72DD writes, $735B restores | observed |
| $7291 | "WAIT" (typed after an idle time-out, $7249) | $725D | observed |
| $7295 (23 words) | message control code table, codes 0-22; <$14 called, rest jumped to | $7326 | observed |
| $74A6 (20) | text buffer of the word being printed ($74C1) | $74E0, $752C, read $756A | observed |
| $7574 (6) $757A $757B (10) | saved HL, A, IY, A; flag; 10 byte slots of the action dispatcher | $770B/$772F, $7585, $7795, $781C | observed |
| $75D2 (13 words) | action dispatch table: index = $7873 result rotated right 3 | $75D1 | inferred |
| $793D (35) | work variables of the record routines $79B6-$7E7C (words at $794E, $7950, $7958, $795A, $795C, $795E) | many | observed (writes), meaning inferred |
| $7F77, $806F/70, $824E-50 | single bytes of picture routines | $7F78, $8071, $82FD, $8315 | observed |
| $8271 (13 pairs) + $828B (13 words) | word pair (C,B) -> handler; $8251 searches, adds $19, jumps | $8251 | inferred |
| $83CD (11 x 3 + FF) | state id ($C12B) -> message address ($B47A..$B53E) | $83B0 via $9DBD, print $72DD | inferred |
| $85B3, $85B4, $85B6 | input window column, cursor address, char under cursor | $85B8 | observed |
| $869B-$86A0 | story window column, cursor address, char, 2 flags | $86A1 | observed |
| $8822 (768) | game font, chars $20-$7F, 8 bytes each | story window | observed |
| $8B81 (8) | key masks ORed into the 8 half-rows | $8BAC | inferred |
| $8B89 (2), $8B8B (8) | key found; previous scan of the half-rows | $8B93 | observed |
| $8BFB, $8C23 (40 each) | ASCII by key index 5*half-row+column; the second when caps or symbol shift is held. $08 = 5 and 0, $09 = 8, $0A = 6, $5B = 7 | $8BDE-$8BF5 | observed |
| $8D6E (14 x 3 + FF) | treasure id -> score value (25, 50, 75, 100, 200) added to ($B6F7) when first taken | $8E51 | inferred |
| $8D99 (2) $8D9B $8D9C | take routine variables | $8D9D | observed |
| $9226 (16 words) | wound message addresses by damage | $91D8 | inferred |
| $980B-$980D, $9BDC | variables of turn routines; $9BDC is a flag (FF, set to 1 by $9BDD) | $980E, $9BDD | observed |
| $A20B (5) | ids tested by $A1D4 | $A1D4 | inferred |
| $A20E.. (words) | dictionary word reference per id (index from 1), read by $A0BA | $A14F | inferred |
| $A224, $A234 (8 words each) | reason words; the second table when bit 7 of A is set | $A172-$A17E | inferred |
| $A49C (6 x 6) | records: id, state address ($CBxx), three bytes into IX+$10, +$0A, +$0B | $A458-$A47E | inferred |

### Self-modifying code (inside code entries, so not touched)
- $7E92 and $7EA1: the opcode of a JR (cc) written by $7E7E/$7E81.
- $9F42: the displacement of `LD A,(IX+d)` at $9F40, written by $9F30 (1 or 2).
- $A7D1-$A7D2: the operand of `LD IY,nn` at $A7CF, written by $97CF (and read back at $A7EB).

### Notes
- The 12 entries between 8B22 and 8C4B that were code/data: only $8B81 and the key tables are data.
- $AB24 (3 bytes) is the last bytes of the CALL at $AB22 and the LD at $AB25, which ends at $AB27 (next slice).
- Dictionary at $6000: word index (2 bytes per first letter) then 5-bit letter strings; seen from $6F5E-$6F72.
- Not decoded: the meaning of the $793D variables, what the $C730/$C2xx handler tables mean.
