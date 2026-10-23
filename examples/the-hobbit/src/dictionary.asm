; Vocabulary index by first letter
;
; The dictionary: words the parser knows and words the messages print, packed 5
; bits per letter. Words are named by their offset from $6000 (0-$BEA);
; messages, the command table and the tables below store offsets, not
; addresses.
;
; This index: 27 words, entry n (A=1 ... Z=26; entry 0 and the unused X and Z
; are 0) is the offset of the first word that starts with letter n. $74CE
; (print) and $6F47 (parse) read it; the words of one letter are contiguous and
; end where the next letter's begin.
Vocabulary:
  DEFW $0000
  DEFW $0040
  DEFW $007C
  DEFW $00E2
  DEFW $017C
  DEFW $01F6
  DEFW $024F
  DEFW $02BD
  DEFW $0309
  DEFW $0373
  DEFW $03A1
  DEFW $03A5
  DEFW $03B2
  DEFW $0424
  DEFW $045F
  DEFW $049C
  DEFW $04CD
  DEFW $050C
  DEFW $0521
  DEFW $0577
  DEFW $068C
  DEFW $070D
  DEFW $0728
  DEFW $0751
  DEFW $0000
  DEFW $07A8
  DEFW $0000

; Unused zero fill after the vocabulary index
;
; Ten zero bytes between the index ($6000-$6035) and the first word ($6040).
L6036:
  DEFS $0A

; Words the parser knows
;
; Word format, one entry per word: bits 0-4 of each byte are a letter (1=A ...
; 26=Z; 0 = padding, ends the printed word). Bit 7 marks the last byte, but it
; is ignored in byte 2 and, when byte 2 has bit 7 set, in byte 3 too (so a word
; has at least 3 bytes).
;
; Bits 5-6 of bytes 1 and 2 give the class, class = 4*bits(byte1) +
; bits(byte2): 0 adverb/other, 1 and 2 direction words (in, into, down...), 3
; verb, 4 go/run, 5 noun, 6 adjective, 7 preposition, 8 article/auxiliary (a,
; the, is, can), 9 other command words (all, it, save, quit, help), 10 and, 11
; then.
;
; Byte 2 bit 7 set: the word takes a verb suffix and byte 3 bits 5-7 pick it: 0
; s, 1 es, 2 ies, 3 back-space + ies, 4 d, 5 ing (table $B71F). Bit 6 of the
; last byte set: two more bytes follow, a synonym: the offset of the word this
; one means (kill = attack, get = take, n = north).
;
; The parser ($6F47) compares what was typed with the words of its first
; letter; a typed word may be a prefix of a longer word ($6F76). Words from
; $67AC are only used by messages.
L6040:
  DEFB $41,$00,$80        ; a (article/aux)
  DEFB $21,$63,$12,$0F,$13,$93 ; across (preposition)
  DEFB $21,$66,$14,$05,$92 ; after (preposition)
  DEFB $41,$2C,$8C        ; all (command/pronoun)
  DEFB $41,$0C,$12,$05,$01,$04,$99 ; already (article/aux)
  DEFB $41,$0E,$80        ; an (article/aux)
  DEFB $41,$4E,$84        ; and (and)
  DEFB $41,$0E,$0F,$14,$08,$05,$92 ; another (article/aux)
  DEFB $41,$12,$85        ; are (article/aux)
  DEFB $21,$32,$8D        ; arm (noun)
  DEFB $21,$32,$12,$0F,$97 ; arrow (noun)
  DEFB $21,$74,$80        ; at (preposition)
  DEFB $01,$F4,$14,$01,$03,$8B ; attack (verb, +s)
  DEFB $21,$38,$85        ; axe (noun)
  DEFB $22,$41,$03,$8B    ; back (adjective)
  DEFB $22,$21,$12,$84    ; bard (noun)
  DEFB $22,$21,$12,$12,$05,$8C ; barrel (noun)
  DEFB $22,$41,$12,$12,$05,$8E ; barren (adjective)
  DEFB $22,$21,$99        ; bay (noun)
  DEFB $22,$45,$0F,$12,$0E,$93 ; beorns (adjective)
  DEFB $22,$45,$17,$09,$14,$03,$08,$05,$84 ; bewitched (adjective)
  DEFB $22,$49,$87        ; big (adjective)
  DEFB $22,$4C,$01,$03,$8B ; black (adjective)
  DEFB $22,$4C,$05,$01,$8B ; bleak (adjective)
  DEFB $22,$2C,$0F,$97    ; blow (noun)
  DEFB $22,$2C,$0F,$0F,$84 ; blood (noun)
  DEFB $22,$2F,$01,$94    ; boat (noun)
  DEFB $22,$2F,$87        ; bog (noun)
  DEFB $22,$2F,$04,$99    ; body (noun)
  DEFB $22,$2F,$97        ; bow (noun)
  DEFB $02,$F2,$05,$01,$CB ; break (verb, +s, = strike)
  DEFB $58,$06
  DEFB $22,$52,$0F,$0B,$05,$8E ; broken (adjective)
  DEFB $02,$F5,$12,$8E    ; burn (verb, +s)
  DEFB $42,$35,$D4        ; but (command/pronoun, = except)
  DEFB $45,$02
  DEFB $22,$35,$14,$0C,$05,$92 ; butler (noun)
  DEFB $23,$21,$03,$08,$85 ; cache (noun)
  DEFB $23,$21,$0D,$90    ; camp (noun)
  DEFB $43,$01,$8E        ; can (article/aux)
  DEFB $43,$01,$0E,$0E,$0F,$94 ; cannot (article/aux)
  DEFB $03,$E1,$10,$14,$15,$12,$C5 ; capture (verb, +s, = attack)
  DEFB $73,$00
  DEFB $03,$01,$12,$05,$06,$15,$0C,$0C,$99 ; carefully
  DEFB $23,$21,$12,$12,$0F,$03,$8B ; carrock (noun)
  DEFB $03,$E1,$72,$12,$99 ; carry (verb, +<-ies)
  DEFB $23,$21,$16,$85    ; cave (noun)
  DEFB $23,$21,$16,$05,$12,$8E ; cavern (noun)
  DEFB $23,$25,$0C,$0C,$01,$92 ; cellar (noun)
  DEFB $23,$28,$05,$13,$94 ; chest (noun)
  DEFB $23,$2C,$05,$01,$12,$09,$0E,$87 ; clearing (noun)
  DEFB $03,$EC,$09,$0D,$82 ; climb (verb, +s)
  DEFB $03,$EC,$0F,$13,$85 ; close (verb, +s)
  DEFB $23,$4C,$0F,$13,$05,$84 ; closed (adjective)
  DEFB $23,$4F,$0D,$06,$0F,$12,$14,$01,$02,$0C,$85 ; comfortable (adjective)
  DEFB $23,$2F,$15,$0E,$14,$12,$99 ; country (noun)
  DEFB $23,$32,$01,$03,$8B ; crack (noun)
  DEFB $03,$F2,$2F,$13,$93 ; cross (verb, +es)
  DEFB $23,$35,$10,$02,$0F,$01,$12,$84 ; cupboard (noun)
  DEFB $23,$55,$12,$09,$0F,$15,$93 ; curious (adjective)
  DEFB $23,$35,$12,$14,$01,$09,$8E ; curtain (noun)
  DEFB $23,$55,$0E,$0E,$09,$0E,$87 ; cunning (adjective)
  DEFB $03,$F5,$14,$80    ; cut (verb, +s)
  DEFB $04,$40,$C0        ; d (direction, = down)
  DEFB $C4,$01
  DEFB $24,$21,$0C,$85    ; dale (noun)
  DEFB $24,$41,$0E,$07,$05,$12,$0F,$15,$93 ; dangerous (adjective)
  DEFB $24,$41,$12,$8B    ; dark (adjective)
  DEFB $24,$45,$01,$84    ; dead (adjective)
  DEFB $24,$45,$05,$90    ; deep (adjective)
  DEFB $24,$45,$0E,$13,$85 ; dense (adjective)
  DEFB $24,$25,$13,$0F,$0C,$01,$14,$09,$0F,$8E ; desolation (noun)
  DEFB $04,$E9,$07,$80    ; dig (verb, +s)
  DEFB $44,$09,$12,$05,$03,$14,$09,$0F,$8E ; direction (article/aux)
  DEFB $24,$49,$13,$07,$15,$13,$14,$09,$0E,$87 ; disgusting (adjective)
  DEFB $24,$2F,$0F,$92    ; door (noun)
  DEFB $04,$4F,$17,$8E    ; down (direction)
  DEFB $24,$32,$01,$07,$0F,$8E ; dragon (noun)
  DEFB $24,$52,$01,$07,$0F,$0E,$93 ; dragons (adjective)
  DEFB $24,$52,$05,$01,$04,$06,$15,$8C ; dreadful (adjective)
  DEFB $24,$52,$05,$01,$12,$99 ; dreary (adjective)
  DEFB $04,$F2,$09,$0E,$8B ; drink (verb, +s)
  DEFB $04,$F2,$0F,$90    ; drop (verb, +s)
  DEFB $24,$52,$99        ; dry (adjective)
  DEFB $24,$35,$0E,$07,$05,$0F,$8E ; dungeon (noun)
  DEFB $05,$40,$C0        ; e (direction, = east)
  DEFB $FE,$01
  DEFB $25,$21,$92        ; ear (noun)
  DEFB $05,$41,$13,$94    ; east (direction)
  DEFB $05,$E1,$14,$80    ; eat (verb, +s)
  DEFB $25,$44,$07,$85    ; edge (adjective)
  DEFB $25,$2C,$86        ; elf (noun)
  DEFB $25,$2C,$12,$0F,$0E,$84 ; elrond (noun)
  DEFB $25,$4C,$16,$05,$0E,$0B,$09,$0E,$07,$93 ; elvenkings (adjective)
  DEFB $25,$2C,$16,$05,$93 ; elves (noun)
  DEFB $25,$4C,$16,$09,$13,$88 ; elvish (adjective)
  DEFB $05,$ED,$50,$14,$99 ; empty (verb, +ies)
  DEFB $05,$EE,$14,$05,$92 ; enter (verb, +s)
  DEFB $45,$36,$05,$12,$19,$14,$08,$09,$0E,$C7 ; everything (command/pronoun, =
                                               ; all)
  DEFB $4E,$00
  DEFB $05,$F8,$01,$0D,$09,$0E,$85 ; examine (verb, +s)
  DEFB $45,$38,$03,$05,$10,$94 ; except (command/pronoun)
  DEFB $25,$39,$05,$93    ; eyes (noun)
  DEFB $06,$E1,$0C,$8C    ; fall (verb, +s)
  DEFB $26,$41,$13,$94    ; fast (adjective)
  DEFB $06,$05,$05,$02,$0C,$99 ; feebly
  DEFB $26,$25,$05,$94    ; feet (noun)
  DEFB $06,$E9,$0C,$8C    ; fill (verb, +s)
  DEFB $26,$29,$0E,$07,$05,$92 ; finger (noun)
  DEFB $26,$29,$13,$94    ; fist (noun)
  DEFB $26,$2C,$01,$0D,$05,$93 ; flames (noun)
  DEFB $26,$4C,$01,$94    ; flat (adjective)
  DEFB $26,$2C,$0F,$0F,$92 ; floor (noun)
  DEFB $26,$4C,$0F,$17,$09,$0E,$87 ; flowing (adjective)
  DEFB $06,$EF,$0C,$0C,$0F,$97 ; follow (verb, +s)
  DEFB $26,$2F,$0F,$84    ; food (noun)
  DEFB $26,$6F,$92        ; for (preposition)
  DEFB $06,$0F,$12,$03,$05,$06,$15,$0C,$0C,$99 ; forcefully
  DEFB $26,$2F,$12,$84    ; ford (noun)
  DEFB $26,$2F,$12,$05,$13,$94 ; forest (noun)
  DEFB $26,$2F,$12,$05,$13,$14,$12,$09,$16,$05,$92 ; forestriver (noun)
  DEFB $26,$4F,$15,$8C    ; foul (adjective)
  DEFB $26,$72,$0F,$8D    ; from (preposition)
  DEFB $26,$55,$0C,$8C    ; full (adjective)
  DEFB $27,$21,$0E,$04,$01,$0C,$86 ; gandalf (noun)
  DEFB $27,$21,$14,$85    ; gate (noun)
  DEFB $27,$45,$0E,$14,$0C,$99 ; gently (adjective)
  DEFB $07,$E5,$14,$C0    ; get (verb, +s, = take)
  DEFB $8C,$06
  DEFB $07,$E9,$16,$85    ; give (verb, +s)
  DEFB $27,$4C,$0F,$0F,$0D,$99 ; gloomy (adjective)
  DEFB $27,$8F,$20,$80    ; go (verb(go/run), +es)
  DEFB $27,$2F,$02,$0C,$09,$8E ; goblin (noun)
  DEFB $27,$4F,$02,$0C,$09,$0E,$93 ; goblins (adjective)
  DEFB $27,$2F,$0C,$84    ; gold (noun)
  DEFB $27,$4F,$0C,$04,$05,$8E ; golden (adjective)
  DEFB $27,$2F,$0C,$0C,$15,$8D ; gollum (noun)
  DEFB $27,$52,$05,$01,$94 ; great (adjective)
  DEFB $27,$52,$05,$05,$8E ; green (adjective)
  DEFB $28,$21,$0C,$8C    ; hall (noun)
  DEFB $28,$21,$0C,$0C,$93 ; halls (noun)
  DEFB $28,$21,$0E,$84    ; hand (noun)
  DEFB $28,$41,$12,$84    ; hard (adjective)
  DEFB $28,$25,$01,$84    ; head (noun)
  DEFB $48,$25,$0C,$90    ; help (command/pronoun)
  DEFB $28,$25,$01,$12,$94 ; heart (noun)
  DEFB $28,$45,$01,$16,$99 ; heavy (adjective)
  DEFB $08,$65,$0C,$0C,$8F ; hello (verb)
  DEFB $28,$49,$04,$04,$05,$8E ; hidden (adjective)
  DEFB $28,$49,$04,$05,$0F,$15,$93 ; hideous (adjective)
  DEFB $28,$29,$0C,$8C    ; hill (noun)
  DEFB $28,$29,$0C,$0C,$93 ; hills (noun)
  DEFB $08,$E9,$14,$C0    ; hit (verb, +s, = attack)
  DEFB $73,$00
  DEFB $28,$4F,$02,$02,$09,$94 ; hobbit (adjective)
  DEFB $28,$2F,$02,$02,$09,$14,$0C,$01,$0E,$84 ; hobbitland (noun)
  DEFB $28,$2F,$0C,$85    ; hole (noun)
  DEFB $28,$4F,$12,$12,$09,$02,$0C,$85 ; horrible (adjective)
  DEFB $28,$4F,$15,$13,$85 ; house (adjective)
  DEFB $08,$75,$12,$12,$99 ; hurry (verb)
  DEFB $09,$00,$C0        ; i (other, = inventory)
  DEFB $92,$03
  DEFB $09,$2E,$80        ; in (direction?)
  DEFB $29,$6E,$13,$09,$04,$85 ; inside (preposition)
  DEFB $29,$4E,$13,$09,$07,$0E,$09,$06,$09,$03,$01,$0E,$94 ; insignificant
                                                           ; (adjective)
  DEFB $09,$2E,$14,$8F    ; into (direction?)
  DEFB $09,$6E,$16,$05,$0E,$14,$0F,$12,$99 ; inventory (verb)
  DEFB $49,$13,$80        ; is (article/aux)
  DEFB $49,$34,$80        ; it (command/pronoun)
  DEFB $0A,$F5,$0D,$90    ; jump (verb, +s)
  DEFB $2B,$25,$99        ; key (noun)
  DEFB $0B,$E9,$0C,$CC    ; kill (verb, +s, = attack)
  DEFB $73,$00
  DEFB $2B,$29,$0E,$87    ; king (noun)
  DEFB $0C,$00,$C0        ; l (other, = look)
  DEFB $13,$04
  DEFB $2C,$21,$0B,$85    ; lake (noun)
  DEFB $2C,$21,$0E,$84    ; land (noun)
  DEFB $2C,$41,$12,$07,$85 ; large (adjective)
  DEFB $0C,$E5,$01,$16,$85 ; leave (verb, +s)
  DEFB $2C,$25,$87        ; leg (noun)
  DEFB $2C,$45,$16,$05,$0C,$0C,$05,$84 ; levelled (adjective)
  DEFB $0C,$E9,$06,$D4    ; lift (verb, +s, = take)
  DEFB $8C,$06
  DEFB $2C,$49,$0B,$85    ; like (adjective)
  DEFB $0C,$E9,$07,$08,$94 ; light (verb, +s)
  DEFB $2C,$49,$14,$14,$0C,$85 ; little (adjective)
  DEFB $0C,$0F,$C0        ; lo (other, = look)
  DEFB $13,$04
  DEFB $4C,$2F,$01,$84    ; load (command/pronoun)
  DEFB $0C,$EF,$03,$8B    ; lock (verb, +s)
  DEFB $2C,$4F,$03,$0B,$05,$84 ; locked (adjective)
  DEFB $2C,$2F,$07,$93    ; logs (noun)
  DEFB $2C,$2F,$0E,$05,$0C,$01,$0E,$04,$93 ; lonelands (noun)
  DEFB $2C,$4F,$0E,$05,$0C,$99 ; lonely (adjective)
  DEFB $2C,$4F,$0E,$87    ; long (adjective)
  DEFB $0C,$EF,$0F,$8B    ; look (verb, +s)
  DEFB $2C,$4F,$97        ; low (adjective)
  DEFB $2C,$4F,$17,$05,$92 ; lower (adjective)
  DEFB $2C,$35,$0E,$03,$88 ; lunch (noun)
  DEFB $2D,$41,$07,$09,$83 ; magic (adjective)
  DEFB $2D,$21,$8E        ; man (noun)
  DEFB $2D,$21,$90        ; map (noun)
  DEFB $2D,$25,$C0        ; me (noun, = you)
  DEFB $A8,$07
  DEFB $2D,$45,$01,$8E    ; mean (adjective)
  DEFB $2D,$29,$12,$0B,$17,$0F,$0F,$84 ; mirkwood (noun)
  DEFB $2D,$49,$13,$14,$99 ; misty (adjective)
  DEFB $2D,$4F,$0E,$13,$14,$12,$0F,$15,$93 ; monstrous (adjective)
  DEFB $2D,$2F,$15,$0E,$14,$01,$09,$8E ; mountain (noun)
  DEFB $2D,$2F,$15,$0E,$14,$01,$09,$0E,$93 ; mountains (noun)
  DEFB $0E,$40,$C0        ; n (direction, = north)
  DEFB $80,$04
  DEFB $2E,$41,$12,$12,$0F,$97 ; narrow (adjective)
  DEFB $2E,$41,$13,$14,$99 ; nasty (adjective)
  DEFB $0E,$45,$C0        ; ne (direction, = northeast)
  DEFB $85,$04
  DEFB $2E,$29,$07,$08,$94 ; night (noun)
  DEFB $4E,$2F,$10,$12,$09,$0E,$94 ; noprint (command/pronoun)
  DEFB $0E,$4F,$12,$14,$88 ; north (direction)
  DEFB $0E,$4F,$12,$14,$08,$05,$01,$13,$94 ; northeast (direction)
  DEFB $0E,$4F,$12,$14,$08,$17,$05,$13,$94 ; northwest (direction)
  DEFB $0E,$57,$C0        ; nw (direction, = northwest)
  DEFB $8E,$04
  DEFB $2F,$66,$80        ; of (preposition)
  DEFB $2F,$66,$86        ; off (preposition)
  DEFB $0F,$E6,$06,$05,$92 ; offer (verb, +s)
  DEFB $2F,$4C,$84        ; old (adjective)
  DEFB $2F,$6E,$80        ; on (preposition)
  DEFB $4F,$2E,$85        ; one (command/pronoun)
  DEFB $2F,$6E,$14,$8F    ; onto (preposition)
  DEFB $0F,$F0,$05,$8E    ; open (verb, +s)
  DEFB $2F,$30,$05,$0E,$09,$0E,$87 ; opening (noun)
  DEFB $2F,$75,$94        ; out (preposition)
  DEFB $2F,$55,$14,$13,$09,$04,$85 ; outside (adjective)
  DEFB $2F,$76,$05,$92    ; over (preposition)
  DEFB $30,$21,$13,$13,$01,$07,$85 ; passage (noun)
  DEFB $30,$21,$14,$88    ; path (noun)
  DEFB $50,$21,$15,$13,$85 ; pause (command/pronoun)
  DEFB $10,$E9,$03,$CB    ; pick (verb, +s, = carry)
  DEFB $0D,$01
  DEFB $30,$29,$94        ; pit (noun)
  DEFB $30,$2C,$01,$03,$85 ; place (noun)
  DEFB $10,$0C,$05,$01,$13,$85 ; please
  DEFB $30,$2F,$12,$14,$03,$15,$0C,$0C,$09,$93 ; portcullis (noun)
  DEFB $50,$32,$09,$0E,$94 ; print (command/pronoun)
  DEFB $10,$F5,$0C,$8C    ; pull (verb, +s)
  DEFB $10,$F5,$33,$88    ; push (verb, +es)
  DEFB $10,$F5,$14,$80    ; put (verb, +s)
  DEFB $11,$15,$09,$03,$0B,$0C,$99 ; quickly
  DEFB $11,$15,$09,$05,$94 ; quiet
  DEFB $51,$35,$09,$94    ; quit (command/pronoun)
  DEFB $31,$55,$09,$14,$85 ; quite (adjective)
  DEFB $32,$21,$16,$05,$0E,$08,$09,$0C,$8C ; ravenhill (noun)
  DEFB $32,$21,$16,$09,$0E,$85 ; ravine (noun)
  DEFB $12,$65,$01,$C4    ; read (verb, = examine)
  DEFB $3E,$02
  DEFB $32,$45,$84        ; red (adjective)
  DEFB $32,$29,$02,$93    ; ribs (noun)
  DEFB $32,$29,$0E,$87    ; ring (noun)
  DEFB $32,$29,$16,$05,$0E,$04,$05,$0C,$8C ; rivendell (noun)
  DEFB $32,$29,$16,$05,$92 ; river (noun)
  DEFB $32,$2F,$01,$84    ; road (noun)
  DEFB $32,$4F,$03,$8B    ; rock (adjective)
  DEFB $32,$2F,$0F,$8D    ; room (noun)
  DEFB $32,$2F,$10,$85    ; rope (noun)
  DEFB $32,$4F,$15,$0E,$84 ; round (adjective)
  DEFB $32,$35,$87        ; rug (noun)
  DEFB $32,$35,$09,$0E,$93 ; ruins (noun)
  DEFB $32,$95,$0E,$80    ; run (verb(go/run), +s)
  DEFB $32,$35,$0E,$0E,$09,$0E,$87 ; running (noun)
  DEFB $13,$40,$C0        ; s (direction, = south)
  DEFB $07,$06
  DEFB $33,$21,$0E,$84    ; sand (noun)
  DEFB $53,$21,$16,$85    ; save (command/pronoun)
  DEFB $13,$E1,$19,$C0    ; say (verb, +s, = talk)
  DEFB $90,$06
  DEFB $53,$23,$0F,$12,$85 ; score (command/pronoun)
  DEFB $13,$45,$C0        ; se (direction, = southeast)
  DEFB $0C,$06
  DEFB $13,$E8,$0F,$0F,$94 ; shoot (verb, +s)
  DEFB $33,$48,$0F,$12,$94 ; short (adjective)
  DEFB $33,$28,$0F,$15,$0C,$04,$05,$92 ; shoulder (noun)
  DEFB $33,$49,$04,$85    ; side (adjective)
  DEFB $33,$29,$04,$05,$04,$0F,$0F,$92 ; sidedoor (noun)
  DEFB $33,$29,$07,$8E    ; sign (noun)
  DEFB $13,$69,$0E,$87    ; sing (verb)
  DEFB $13,$E9,$14,$80    ; sit (verb, +s)
  DEFB $33,$2B,$15,$0C,$8C ; skull (noun)
  DEFB $13,$EC,$21,$13,$C8 ; slash (verb, +es, = attack)
  DEFB $73,$00
  DEFB $13,$EC,$05,$05,$90 ; sleep (verb, +s)
  DEFB $13,$EC,$09,$03,$C5 ; slice (verb, +s, = attack)
  DEFB $73,$00
  DEFB $33,$4C,$09,$0D,$99 ; slimy (adjective)
  DEFB $13,$0C,$0F,$17,$0C,$99 ; slowly
  DEFB $33,$4D,$01,$0C,$8C ; small (adjective)
  DEFB $13,$ED,$21,$13,$C8 ; smash (verb, +es, = strike)
  DEFB $58,$06
  DEFB $33,$4D,$0F,$0F,$14,$88 ; smooth (adjective)
  DEFB $33,$4D,$0F,$14,$08,$05,$12,$09,$0E,$87 ; smothering (adjective)
  DEFB $13,$0F,$06,$14,$0C,$99 ; softly
  DEFB $33,$4F,$0D,$85    ; some (adjective)
  DEFB $13,$4F,$15,$14,$88 ; south (direction)
  DEFB $13,$4F,$15,$14,$08,$05,$01,$13,$94 ; southeast (direction)
  DEFB $13,$4F,$15,$14,$08,$17,$05,$13,$94 ; southwest (direction)
  DEFB $33,$30,$01,$03,$85 ; space (noun)
  DEFB $33,$50,$09,$04,$05,$92 ; spider (adjective)
  DEFB $33,$34,$01,$09,$12,$93 ; stairs (noun)
  DEFB $33,$34,$01,$14,$15,$85 ; statue (noun)
  DEFB $13,$F4,$05,$01,$CC ; steal (verb, +s, = take)
  DEFB $8C,$06
  DEFB $33,$54,$05,$05,$90 ; steep (adjective)
  DEFB $33,$34,$0F,$0E,$85 ; stone (noun)
  DEFB $33,$54,$12,$01,$09,$07,$08,$94 ; straight (adjective)
  DEFB $33,$54,$12,$05,$14,$03,$08,$09,$0E,$87 ; stretching (adjective)
  DEFB $13,$F4,$12,$09,$0B,$85 ; strike (verb, +s)
  DEFB $33,$34,$12,$0F,$0B,$85 ; stroke (noun)
  DEFB $33,$34,$12,$0F,$0E,$87 ; strong (noun)
  DEFB $33,$54,$15,$06,$06,$99 ; stuffy (adjective)
  DEFB $33,$54,$15,$0E,$0E,$05,$84 ; stunned (adjective)
  DEFB $13,$57,$C0        ; sw (direction, = southwest)
  DEFB $15,$06
  DEFB $13,$F7,$09,$8D    ; swim (verb, +s)
  DEFB $33,$37,$0F,$12,$84 ; sword (noun)
  DEFB $33,$39,$0D,$02,$0F,$0C,$93 ; symbols (noun)
  DEFB $14,$E1,$0B,$85    ; take (verb, +s)
  DEFB $14,$61,$0C,$8B    ; talk (verb)
  DEFB $34,$41,$0E,$07,$0C,$05,$84 ; tangled (adjective)
  DEFB $54,$08,$01,$94    ; that (article/aux)
  DEFB $54,$08,$85        ; the (article/aux)
  DEFB $54,$68,$05,$8E    ; then (then)
  DEFB $34,$48,$09,$03,$8B ; thick (adjective)
  DEFB $34,$28,$09,$05,$86 ; thief (noun)
  DEFB $34,$48,$09,$8E    ; thin (adjective)
  DEFB $34,$28,$0F,$12,$09,$8E ; thorin (noun)
  DEFB $34,$48,$12,$05,$01,$04,$93 ; threads (adjective)
  DEFB $34,$68,$12,$0F,$15,$07,$88 ; through (preposition)
  DEFB $14,$E8,$12,$0F,$97 ; throw (verb, +s)
  DEFB $14,$E9,$05,$80    ; tie (verb, +s)
  DEFB $34,$6F,$80        ; to (preposition)
  DEFB $34,$6F,$8F        ; too (preposition)
  DEFB $34,$AF,$32,$03,$88 ; torch (noun, +es)
  DEFB $34,$2F,$17,$8E    ; town (noun)
  DEFB $34,$52,$01,$90    ; trap (adjective)
  DEFB $34,$32,$05,$01,$13,$15,$12,$85 ; treasure (noun)
  DEFB $34,$B2,$05,$85    ; tree (noun, +s)
  DEFB $34,$52,$05,$05,$0C,$05,$13,$93 ; treeless (adjective)
  DEFB $34,$32,$0F,$0C,$8C ; troll (noun)
  DEFB $34,$52,$0F,$0C,$0C,$93 ; trolls (adjective)
  DEFB $34,$55,$0E,$0E,$05,$8C ; tunnel (adjective)
  DEFB $14,$F5,$12,$8E    ; turn (verb, +s)
  DEFB $15,$00,$C0        ; u (other, = up)
  DEFB $25,$07
  DEFB $15,$EE,$0C,$0F,$03,$8B ; unlock (verb, +s)
  DEFB $35,$4E,$0C,$0F,$03,$0B,$05,$84 ; unlocked (adjective)
  DEFB $15,$EE,$14,$09,$85 ; untie (verb, +s)
  DEFB $15,$50,$80        ; up (direction)
  DEFB $36,$41,$0C,$09,$01,$0E,$94 ; valiant (adjective)
  DEFB $36,$21,$0C,$0C,$05,$99 ; valley (noun)
  DEFB $36,$41,$0C,$15,$01,$02,$0C,$85 ; valuable (adjective)
  DEFB $36,$45,$12,$99    ; very (adjective)
  DEFB $36,$49,$03,$09,$0F,$15,$93 ; vicious (adjective)
  DEFB $16,$09,$03,$09,$0F,$15,$13,$0C,$99 ; viciously
  DEFB $17,$40,$C0        ; w (direction, = west)
  DEFB $79,$07
  DEFB $17,$E1,$09,$94    ; wait (verb, +s)
  DEFB $37,$A1,$0C,$8C    ; wall (noun, +s)
  DEFB $37,$21,$14,$05,$92 ; water (noun)
  DEFB $37,$21,$14,$05,$12,$06,$01,$0C,$8C ; waterfall (noun)
  DEFB $37,$25,$01,$10,$0F,$8E ; weapon (noun)
  DEFB $17,$E5,$01,$92    ; wear (verb, +s)
  DEFB $37,$25,$82        ; web (noun)
  DEFB $17,$45,$13,$94    ; west (direction)
  DEFB $37,$49,$04,$85    ; wide (adjective)
  DEFB $37,$49,$0C,$84    ; wild (adjective)
  DEFB $37,$49,$0E,$04,$09,$0E,$87 ; winding (adjective)
  DEFB $37,$29,$0E,$04,$0F,$97 ; window (noun)
  DEFB $37,$29,$0E,$85    ; wine (noun)
  DEFB $37,$69,$14,$88    ; with (preposition)
  DEFB $37,$21,$12,$87    ; warg (noun)
  DEFB $37,$4F,$0F,$84    ; wood (adjective)
  DEFB $37,$4F,$0F,$04,$05,$8E ; wooden (adjective)
  DEFB $39,$2F,$95        ; you (noun)
  DEFB $00

; Words only messages use
;
; Same format; no index by letter, class 0, in alphabetical order. A message
; names one by its offset ($67AC = offset $7AC).
L67AC:
  DEFB $01,$02,$0C,$85    ; able
  DEFB $01,$02,$0F,$15,$94 ; about
  DEFB $01,$02,$0F,$16,$85 ; above
  DEFB $01,$04,$16,$05,$0E,$14,$15,$12,$85 ; adventure
  DEFB $01,$07,$01,$09,$8E ; again
  DEFB $01,$07,$01,$09,$0E,$13,$94 ; against
  DEFB $01,$08,$05,$01,$84 ; ahead
  DEFB $01,$0C,$09,$16,$85 ; alive
  DEFB $01,$0C,$0D,$0F,$13,$94 ; almost
  DEFB $01,$0C,$0F,$0E,$87 ; along
  DEFB $01,$0E,$09,$0D,$01,$8C ; animal
  DEFB $01,$90,$10,$05,$01,$92 ; appear (other, +s)
  DEFB $01,$90,$B0,$12,$0F,$01,$03,$88 ; approach (other, +ing)
  DEFB $01,$12,$0F,$15,$0E,$84 ; around
  DEFB $01,$12,$12,$09,$16,$05,$93 ; arrives
  DEFB $01,$13,$80        ; as
  DEFB $01,$13,$09,$04,$85 ; aside
  DEFB $01,$13,$0C,$05,$05,$90 ; asleep
  DEFB $01,$94,$14,$05,$0D,$10,$94 ; attempt (other, +s)
  DEFB $01,$17,$01,$99    ; away
  DEFB $02,$01,$0E,$8B    ; bank
  DEFB $02,$05,$80        ; be
  DEFB $02,$05,$08,$09,$0E,$84 ; behind
  DEFB $02,$05,$0C,$0F,$97 ; below
  DEFB $02,$09,$12,$14,$08,$04,$01,$99 ; birthday
  DEFB $02,$0C,$09,$0D,$05,$99 ; blimey
  DEFB $02,$92,$21,$0E,$04,$09,$13,$88 ; brandish (other, +es)
  DEFB $02,$12,$09,$0E,$8B ; brink
  DEFB $02,$12,$0F,$01,$04,$13,$09,$04,$85 ; broadside
  DEFB $02,$15,$0C,$02,$0F,$15,$93 ; bulbous
  DEFB $02,$19,$80        ; by
  DEFB $03,$01,$12,$12,$19,$09,$0E,$87 ; carrying
  DEFB $03,$8C,$05,$01,$16,$85 ; cleave (other, +s)
  DEFB $03,$0C,$09,$06,$86 ; cliff
  DEFB $03,$8F,$0D,$85    ; come (other, +s)
  DEFB $03,$8F,$8D,$10,$0C,$05,$14,$85 ; complete (other, +d)
  DEFB $03,$8F,$0E,$07,$12,$01,$14,$15,$0C,$01,$14,$09,$0F,$8E ; congratulation
                                                               ; (other, +s)
  DEFB $03,$0F,$0F,$8B    ; cook
  DEFB $03,$15,$12,$12,$05,$0E,$94 ; current
  DEFB $03,$12,$09,$13,$90 ; crisp
  DEFB $04,$81,$17,$8E    ; dawn (other, +s)
  DEFB $04,$01,$99        ; day
  DEFB $04,$05,$06,$05,$0E,$13,$85 ; defense
  DEFB $04,$05,$13,$03,$05,$0E,$04,$93 ; descends
  DEFB $04,$09,$85        ; die
  DEFB $04,$09,$84        ; did
  DEFB $04,$09,$8D        ; dim
  DEFB $04,$09,$13,$14,$01,$0E,$03,$85 ; distance
  DEFB $04,$8F,$20,$80    ; do (other, +es)
  DEFB $04,$8F,$A0,$80    ; do (other, +ing)
  DEFB $04,$12,$09,$10,$93 ; drips
  DEFB $05,$06,$06,$0F,$12,$94 ; effort
  DEFB $05,$8E,$04,$80    ; end (other, +s)
  DEFB $05,$0E,$14,$12,$01,$0E,$03,$85 ; entrance
  DEFB $05,$96,$01,$10,$0F,$12,$01,$14,$85 ; evaporate (other, +s)
  DEFB $05,$16,$05,$0E,$09,$0E,$87 ; evening
  DEFB $05,$18,$09,$14,$93 ; exits
  DEFB $05,$18,$10,$05,$03,$94 ; expect
  DEFB $06,$01,$09,$0C,$05,$84 ; failed
  DEFB $06,$01,$09,$0C,$09,$0E,$87 ; failing
  DEFB $06,$01,$92        ; far
  DEFB $06,$01,$14,$01,$8C ; fatal
  DEFB $06,$05,$05,$84    ; feed
  DEFB $06,$05,$0C,$94    ; felt
  DEFB $06,$09,$94        ; fit
  DEFB $06,$09,$12,$13,$94 ; first
  DEFB $06,$8C,$01,$0D,$85 ; flame (other, +s)
  DEFB $06,$8C,$0F,$01,$94 ; float (other, +s)
  DEFB $06,$0C,$19,$09,$0E,$87 ; flying
  DEFB $06,$0F,$0F,$94    ; foot
  DEFB $06,$0F,$0F,$14,$09,$0E,$87 ; footing
  DEFB $06,$0F,$15,$92    ; four
  DEFB $06,$12,$0F,$0E,$94 ; front
  DEFB $07,$05,$14,$14,$09,$0E,$87 ; getting
  DEFB $07,$0C,$01,$0E,$03,$09,$0E,$87 ; glancing
  DEFB $07,$0C,$09,$04,$05,$93 ; glides
  DEFB $07,$0C,$15,$14,$14,$0F,$0E,$99 ; gluttony
  DEFB $07,$0F,$94        ; got
  DEFB $07,$12,$0F,$15,$0E,$84 ; ground
  DEFB $07,$12,$0F,$97    ; grow
  DEFB $07,$15,$01,$12,$84 ; guard
  DEFB $08,$01,$0E,$07,$09,$0E,$87 ; hanging
  DEFB $08,$01,$93        ; has
  DEFB $08,$01,$16,$85    ; have
  DEFB $08,$05,$80        ; he
  DEFB $08,$85,$81,$92    ; hear (other, +d)
  DEFB $08,$05,$12,$85    ; here
  DEFB $08,$09,$8D        ; him
  DEFB $08,$09,$93        ; his
  DEFB $08,$0F,$97        ; how
  DEFB $08,$0F,$17,$0C,$93 ; howls
  DEFB $08,$15,$12,$12,$99 ; hurry
  DEFB $09,$0E,$05,$06,$06,$05,$03,$14,$09,$16,$85 ; ineffective
  DEFB $09,$14,$93        ; its
  DEFB $0A,$0F,$82        ; job
  DEFB $0A,$15,$13,$94    ; just
  DEFB $0C,$15,$12,$03,$88 ; lurch
  DEFB $0B,$05,$05,$10,$93 ; keeps
  DEFB $0B,$0E,$0F,$03,$0B,$93 ; knocks
  DEFB $0B,$0E,$0F,$97    ; know
  DEFB $0C,$01,$13,$94    ; last
  DEFB $0C,$01,$15,$07,$08,$93 ; laughs
  DEFB $0C,$01,$15,$07,$08,$14,$05,$92 ; laughter
  DEFB $0C,$89,$05,$80    ; lie (other, +s)
  DEFB $0C,$09,$06,$85    ; life
  DEFB $0C,$09,$16,$05,$93 ; lives
  DEFB $0C,$8F,$13,$85    ; lose (other, +s)
  DEFB $0C,$0F,$15,$84    ; loud
  DEFB $0C,$15,$03,$0B,$99 ; lucky
  DEFB $0D,$01,$04,$85    ; made
  DEFB $0D,$01,$0B,$85    ; make
  DEFB $0D,$01,$12,$07,$09,$8E ; margin
  DEFB $0D,$01,$12,$16,$05,$0C,$0C,$0F,$15,$93 ; marvellous
  DEFB $0D,$01,$99        ; may
  DEFB $0D,$01,$19,$02,$85 ; maybe
  DEFB $0D,$85,$AE,$84    ; mend (other, +ing)
  DEFB $0D,$09,$04,$04,$0C,$85 ; middle
  DEFB $0D,$09,$04,$04,$01,$99 ; midday
  DEFB $0D,$89,$33,$93    ; miss (other, +es)
  DEFB $0D,$0F,$0D,$05,$0E,$94 ; moment
  DEFB $0D,$0F,$0D,$05,$0E,$14,$01,$12,$09,$0C,$99 ; momentarily
  DEFB $0D,$8F,$B2,$8E    ; morn (other, +ing)
  DEFB $0D,$0F,$15,$14,$08,$06,$15,$0C,$8C ; mouthfull
  DEFB $0D,$0F,$16,$85    ; move
  DEFB $0D,$15,$03,$88    ; much
  DEFB $0D,$19,$80        ; my
  DEFB $0E,$0F,$80        ; no
  DEFB $0E,$0F,$09,$13,$85 ; noise
  DEFB $0E,$0F,$94        ; not
  DEFB $0E,$0F,$14,$08,$09,$0E,$87 ; nothing
  DEFB $0E,$0F,$97        ; now
  DEFB $0F,$0E,$03,$85    ; once
  DEFB $0F,$14,$08,$05,$92 ; other
  DEFB $10,$01,$0C,$85    ; pale
  DEFB $10,$01,$13,$13,$05,$93 ; passes
  DEFB $10,$01,$13,$94    ; past
  DEFB $10,$8C,$81,$03,$85 ; place (other, +d)
  DEFB $10,$8F,$03,$0B,$05,$94 ; pocket (other, +s)
  DEFB $10,$92,$05,$03,$09,$0F,$15,$93 ; precious (other, +s)
  DEFB $10,$12,$05,$10,$01,$12,$85 ; prepare
  DEFB $10,$12,$05,$13,$05,$0E,$94 ; present
  DEFB $12,$05,$01,$03,$88 ; reach
  DEFB $12,$85,$03,$0F,$16,$05,$92 ; recover (other, +s)
  DEFB $13,$81,$09,$8C    ; sail (other, +s)
  DEFB $13,$05,$85        ; see
  DEFB $13,$85,$05,$8D    ; seem (other, +s)
  DEFB $13,$08,$01,$04,$0F,$97 ; shadow
  DEFB $13,$08,$01,$10,$85 ; shape
  DEFB $13,$88,$01,$14,$14,$05,$92 ; shatter (other, +s)
  DEFB $13,$89,$AE,$87    ; sing (other, +ing)
  DEFB $13,$89,$AE,$8B    ; sink (other, +ing)
  DEFB $13,$89,$14,$80    ; sit (other, +s)
  DEFB $13,$8C,$09,$04,$85 ; slide (other, +s)
  DEFB $13,$0D,$05,$0C,$8C ; smell
  DEFB $13,$0D,$05,$0C,$94 ; smelt
  DEFB $13,$0F,$0D,$05,$0F,$0E,$85 ; someone
  DEFB $13,$0F,$0D,$05,$17,$08,$05,$12,$85 ; somewhere
  DEFB $13,$0F,$0F,$8E    ; soon
  DEFB $13,$10,$05,$03,$09,$01,$8C ; special
  DEFB $13,$90,$0F,$15,$94 ; spout (other, +s)
  DEFB $13,$94,$01,$07,$07,$05,$92 ; stagger (other, +s)
  DEFB $13,$94,$A1,$0E,$84 ; stand (other, +ing)
  DEFB $13,$94,$01,$92    ; star (other, +s)
  DEFB $13,$94,$A1,$92    ; star (other, +ing)
  DEFB $13,$94,$01,$12,$94 ; start (other, +s)
  DEFB $13,$14,$09,$0C,$8C ; still
  DEFB $13,$94,$09,$0E,$87 ; sting (other, +s)
  DEFB $13,$94,$12,$01,$0E,$07,$0C,$85 ; strangle (other, +s)
  DEFB $13,$14,$12,$05,$0E,$07,$14,$88 ; strength
  DEFB $13,$15,$12,$12,$0F,$15,$0E,$04,$05,$84 ; surrounded
  DEFB $13,$17,$05,$05,$10,$93 ; sweeps
  DEFB $13,$17,$05,$10,$94 ; swept
  DEFB $13,$97,$09,$0E,$87 ; swing (other, +s)
  DEFB $14,$05,$12,$12,$09,$06,$09,$83 ; terrific
  DEFB $14,$08,$01,$0E,$8B ; thank
  DEFB $14,$08,$05,$8D    ; them
  DEFB $14,$08,$05,$12,$85 ; there
  DEFB $14,$08,$09,$0E,$87 ; thing
  DEFB $14,$08,$09,$93    ; this
  DEFB $14,$08,$12,$01,$09,$0E,$93 ; thrains
  DEFB $14,$08,$12,$05,$85 ; three
  DEFB $14,$08,$12,$0F,$17,$8E ; thrown
  DEFB $14,$88,$12,$15,$13,$94 ; thrust (other, +s)
  DEFB $14,$09,$0D,$85    ; time
  DEFB $14,$09,$12,$05,$84 ; tired
  DEFB $14,$12,$99        ; try
  DEFB $14,$0F,$15,$03,$88 ; touch
  DEFB $14,$17,$8F        ; two
  DEFB $15,$0E,$04,$05,$92 ; under
  DEFB $15,$13,$80        ; us
  DEFB $16,$81,$2E,$09,$13,$88 ; vanish (other, +es)
  DEFB $16,$05,$12,$82    ; verb
  DEFB $16,$09,$13,$09,$02,$0C,$85 ; visible
  DEFB $17,$81,$12,$8E    ; warn (other, +s)
  DEFB $17,$01,$93        ; was
  DEFB $17,$01,$13,$14,$05,$84 ; wasted
  DEFB $17,$05,$80        ; we
  DEFB $17,$05,$0C,$8C    ; well
  DEFB $17,$08,$01,$94    ; what
  DEFB $17,$08,$05,$12,$85 ; where
  DEFB $17,$08,$09,$03,$88 ; which
  DEFB $17,$09,$0C,$8C    ; will
  DEFB $17,$09,$0E,$84    ; wind
  DEFB $17,$0F,$12,$84    ; word
  DEFB $17,$0F,$15,$0C,$84 ; would
  DEFB $19,$05,$92        ; yer
  DEFB $19,$0F,$15,$92    ; your

; Unused zero fill after the last word
;
; Eighteen zero bytes at the end of the vocabulary block, up to $6BFF.
L6BEE:
  DEFS $12
