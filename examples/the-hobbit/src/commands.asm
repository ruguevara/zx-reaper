; Command table
;
; The verb phrases the parser accepts: 59 records of 8 bytes, record number =
; id (1-59), then a zero word. $79C5 finds the record whose phrase matches
; ($71F3, $7B9E) and stores its id in $B6E7; the handler for the id is looked
; up in the table at $C730. Four words:
;
; +0 the verb (for ids 1-10 the direction word): bits 0-11 are the offset of
; the word in the dictionary, bits 12-15 flags (8 an object follows; C two
; objects; E and 9 other forms);
;
; +2 the first preposition (offset in bits 0-11, flags above: 2 and A mark
; "through", "into"...; 1 a bare object slot) and +4 the second preposition
; ("with", "in", "on", "of", "to");
;
; +6 flags $4000 / $8000 / $6000 / 0 (inferred: what the second object can be);
; for ids 1-10 the verb GO ($02DE) instead, so that the ten directions are "go
; north" ... "go down".
;
; Flags and slots are matched in $71F3/$722E; their exact meaning is open.
CommandTable:
  DEFW $0480,$0000,$0000,$02DE ; 1: north - -
  DEFW $0607,$0000,$0000,$02DE ; 2: south - -
  DEFW $01FE,$0000,$0000,$02DE ; 3: east - -
  DEFW $0779,$0000,$0000,$02DE ; 4: west - -
  DEFW $0485,$0000,$0000,$02DE ; 5: northeast - -
  DEFW $048E,$0000,$0000,$02DE ; 6: northwest - -
  DEFW $060C,$0000,$0000,$02DE ; 7: southeast - -
  DEFW $0615,$0000,$0000,$02DE ; 8: southwest - -
  DEFW $0725,$0000,$0000,$02DE ; 9: up - -
  DEFW $01C4,$0000,$0000,$02DE ; 10: down - -
  DEFW $E658,$0000,$0796,$4000 ; 11: strike - with
  DEFW $8134,$0000,$0000,$4000 ; 12: close - -
  DEFW $81E8,$0000,$8000,$0000 ; 13: drop - -
  DEFW $C1E8,$0000,$0378,$4000 ; 14: drop - in
  DEFW $E073,$0000,$4796,$4000 ; 15: attack - with
  DEFW $84B4,$0000,$0000,$4000 ; 16: open - -
  DEFW $C508,$0000,$0378,$4000 ; 17: put - in
  DEFW $C508,$0000,$04AA,$4000 ; 18: put - on
  DEFW $868C,$0000,$0000,$4000 ; 19: take - -
  DEFW $C68C,$04BF,$049C,$4000 ; 20: take out of
  DEFW $C68C,$02B5,$0000,$4000 ; 21: take from -
  DEFW $968C,$249F,$0000,$4000 ; 22: take off -
  DEFW $0413,$1000,$0000,$4000 ; 23: look - -
  DEFW $8413,$26C1,$0000,$0000 ; 24: look through -
  DEFW $8413,$2043,$0000,$0000 ; 25: look across -
  DEFW $0392,$1000,$0000,$4000 ; 26: inventory - -
  DEFW $8202,$0000,$0000,$0000 ; 27: eat - -
  DEFW $823E,$0000,$0000,$4000 ; 28: examine - -
  DEFW $C2D4,$06D1,$1000,$6000 ; 29: give to -
  DEFW $82DE,$26C1,$0000,$0000 ; 30: go through -
  DEFW $822D,$8000,$0000,$0000 ; 31: enter - -
  DEFW $82DE,$A38E,$0000,$0000 ; 32: go into -
  DEFW $81E3,$0000,$0000,$0000 ; 33: drink - -
  DEFW $8228,$0000,$0000,$0000 ; 34: empty - -
  DEFW $C261,$0000,$0796,$4000 ; 35: fill - with
  DEFW $056C,$0000,$0000,$0000 ; 36: run - -
  DEFW $C3F2,$0000,$0796,$4000 ; 37: lock - with
  DEFW $C712,$0000,$0796,$4000 ; 38: unlock - with
  DEFW $9285,$0000,$4000,$0000 ; 39: follow - -
  DEFW $8772,$0000,$0000,$0000 ; 40: wear - -
  DEFW $86C8,$0000,$0000,$0000 ; 41: throw - -
  DEFW $C6C8,$0000,$2070,$0000 ; 42: throw - at
  DEFW $C6C8,$0000,$0043,$4000 ; 43: throw - across
  DEFW $C6C8,$0000,$06C1,$4000 ; 44: throw - through
  DEFW $80D3,$0000,$4000,$0000 ; 45: burn - -
  DEFW $C6CD,$0000,$06D1,$4000 ; 46: tie - to
  DEFW $8178,$0000,$0000,$0000 ; 47: cut - -
  DEFW $80F4,$0000,$4000,$0000 ; 48: capture - -
  DEFW $8500,$0000,$0000,$0000 ; 49: pull - -
  DEFW $867C,$0000,$0000,$4000 ; 50: swim - -
  DEFW $8720,$0000,$8000,$4000 ; 51: untie - -
  DEFW $812F,$0000,$0000,$4000 ; 52: climb - -
  DEFW $8690,$26D1,$4000,$4000 ; 53: talk to -
  DEFW $812F,$238E,$0000,$4000 ; 54: climb into -
  DEFW $812F,$24BF,$049C,$8000 ; 55: climb out of
  DEFW $93A1,$24B0,$0000,$0000 ; 56: jump onto -
  DEFW $81A9,$0000,$0000,$4000 ; 57: dig - -
  DEFW $8594,$0000,$4000,$4000 ; 58: shoot - -
  DEFW $810D,$0000,$8000,$4000 ; 59: carry - -
  DEFW $0000              ; End of the table

; Article table (nouns)
;
; Four word offsets chosen by the class bits of a noun token ($743F): the, a,
; an, some. Used when the noun is printed with an article, for B701=0 ($AD35
; otherwise).
ArticleTable:
  DEFW $069F,$0040,$0058,$0603

; Article table (input line)
;
; The same with "the" for the first three: used when printing into the input
; line.
ArticleTableInput:
  DEFW $069F,$069F,$069F,$0603

; Common words
;
; 32 word offsets for the bytes $60-$7F in a message ($7493): a and are at be
; blow but cannot carrying do door dragon fall from here i in is it not of on
; see some the there this to too what with you. The high nibble of each is 0.
CommonWordTable:
  DEFW $0040,$005B,$0065,$0070
  DEFW $0822,$00AF,$00D7,$00EE
  DEFW $085E,$08C2,$01C0,$01C8
  DEFW $024F,$02B5,$0989,$0373
  DEFW $0378,$039B,$039E,$0A5A
  DEFW $049C,$04AA,$0AAF,$0603
  DEFW $069F,$0B61,$0B6B,$06D1
  DEFW $06D4,$0BC8,$0796,$07A8
