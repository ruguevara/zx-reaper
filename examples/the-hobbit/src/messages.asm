; Message: But fall and hit your head.
;
; Messages, from here to $B6D9: a bytecode printed by $72DD (HL = start).
; $20-$5F a letter or sign (capitals print as lower case); $60-$7F a common
; word from $AD3D; $80-$FF + next byte a dictionary word: bits 4-6 of the first
; byte are its print mode (0 plain, 1 verb suffix if object 1 is not you, 4
; suffix always, 5 never, 7 capital first, 2 3 6 end the message after the
; word: nothing, full stop + new line, new line), bits 0-3 and the second byte
; its offset; $00-$16 control codes (jump table $7295); $14 end + new line, $15
; end with full stop + new line, $16 end. Words get a space in front; a suffix
; comes from $B71F. text.py decodes them.
;
; Codes that take a byte: 2 jumps and 11 calls the message at (address of the
; byte) + signed byte. 13 line break (no capital after it), 8 back-space.
; State-dependent: 0 a thing named by a pointer on the stack, 1 and 4 a word
; token on the stack (4 with article), 3 the word at $B6FC, 6 the name of $B6EA
; (the subject), 7 and 9 the name of $B6E8 and $B6E9 with article, 12 and 14
; "his" / "your" for $B6EA and $B6E8, 16 17 19 the same name plus "is"/"are"
; ("You are").
MsgButFallHitHead:
  DEFB $66,$6C,$61,$83,$47,$8B,$EA ; but fall and hit your
  DEFM " HEAD"
  DEFB $15                ; <end,.nl>

; Message: But fall and smash your skull.
MsgButFallSmashSkull:
  DEFB $66,$6C,$61,$85,$E6,$8B,$EA ; but fall and smash your
  DEFB $B5,$BE            ; skull:3

; Message: I do not know the word "
MsgIDoNotKnow:
  DEFB $6F,$69,$73,$89,$C5,$78,$8B,$DE ; i do not know the word
  DEFB $20,$22,$20,$16    ; " " " <end>

; Message: What ?
MsgWhat:
  DEFB $7D,$20,$3F,$14    ; what " ?" <end,nl>

; Message: You <word>. / Time passes...
;
; You <word>. / Time passes...
MsgTimePasses:
  DEFB $0D,$F7,$A8,$01,$2E,$0D ; <nl> you:7 <word> "." <nl>
MsgTimePasses2:
  DEFB $FB,$87,$8A,$74,$2E,$2E,$15 ; time:7 passes ".." <end,.nl>

; Message: I do not know the verb " <word> <word> <word> "
MsgIDoNotKnowVerb:
  DEFB $6F,$69,$73,$89,$C5,$78,$8B,$A9 ; i do not know the verb
  DEFB $20,$22,$01,$01,$01,$20,$22,$14 ; " "" <word> <word> <word> " ""
                                       ; <end,nl>

; Message: <word> <word> <word> <thing> <word> <word> <word>...
;
; <word> <word> <word> <thing> <word> <word> <word> what ?
MsgWhat2:
  DEFB $01,$01,$01,$00    ; <word> <word> <word> <thing>
MsgWhat3:
  DEFB $01,$01,$01,$7D,$20,$3F,$20,$16 ; <word> <word> <word> what " ? " <end>

; Message: Which <word> ?
MsgWhich:
  DEFB $8B,$D1,$01,$20,$3F,$20,$16 ; which <word> " ? " <end>

; Message: I do not see <thing> here
MsgIDoNotSeeHere:
  DEFB $6F,$69,$73,$76,$00,$6E,$14 ; i do not see <thing> here <end,nl>

; Message:
LADDA:
  DEFB $14                ; <end,nl>

; Message: I see nothing to
LADDB:
  DEFB $6F,$76,$8A,$5D,$A6,$D1 ; i see nothing to:2

; Message: I see nothing to <word> <word> <word>
MsgISeeNothing:
  DEFB $0B,$F9,$01,$01,$01,$14 ; <call $ADDB> <word> <word> <word> <end,nl>

; Message: I see nothing to <word> <word> <word> <thing> <wor...
;
; I see nothing to <word> <word> <word> <thing> <word> <word> <word>
MsgISeeNothing2:
  DEFB $0B,$F3,$01,$01,$01,$00,$01,$01 ; <call $ADDB> <word> <word> <word>
                                       ; <thing> <word> <word>
  DEFB $01,$14            ; <word> <end,nl>

; Message: <subj_is> not carrying it.
MsgNotCarrying:
  DEFB $10,$73,$68,$72,$15 ; <subj_is> not carrying it <end,.nl>

; Message: <subj_is> carrying.
MsgCarrying:
  DEFB $10,$68,$15        ; <subj_is> carrying <end,.nl>

; Message: <arg_is> carrying
MsgCarrying2:
  DEFB $13,$68,$14        ; <arg_is> carrying <end,nl>

; Message: And it gets swept away.
MsgGetsSweptAway:
  DEFB $61,$72,$C2,$CE,$8B,$46,$B8,$1A ; and it get:4 swept away:3

; Message: <obj1> is too heavy to lift.
MsgTooHeavyLift:
  DEFB $07,$71,$7C,$83,$27,$7B,$B3,$D4 ; <obj1> is too heavy to lift:3

; Message: <subj_is> carrying too much.
MsgCarryingTooMuch:
  DEFB $10,$68,$7C,$BA,$4B ; <subj_is> carrying too much:3

; Message: <subj_is> already carrying <obj1>.
MsgAlreadyCarrying:
  DEFB $10,$80,$51,$68,$07,$15 ; <subj_is> already carrying <obj1> <end,.nl>

; Message: To the
MsgToThe:
  DEFB $7B,$78,$16        ; to the <end>

; Message: <obj2> is too full.
MsgTooFull:
  DEFB $09,$71,$7C,$B2,$B9 ; <obj2> is too full:3

; Message: It is dark.
MsgDark:
  DEFB $72,$71,$B1,$8E    ; it is dark:3

; Message: <the_arg> is too small for <subj> to enter.
MsgTooSmallForEnter:
  DEFB $04,$71,$7C,$85,$E1,$82,$8F,$06 ; <the_arg> is too small for <subj>
  DEFB $7B,$B2,$2D        ; to enter:3

; Message: <the_arg> is too full for <subj> to enter.
MsgTooFullForEnter:
  DEFB $04,$71,$7C,$82,$B9,$82,$8F,$06 ; <the_arg> is too full for <subj>
  DEFB $7B,$D2,$2D,$15    ; to enter <end,.nl>

; Message: With one well placed blow <subj> cleave <his_obj1>...
;
; With one well placed blow <subj> cleave <his_obj1> skull.
MsgWithOneWellPlacedBlow:
  DEFB $7E,$84,$AD,$8B,$C4,$CA,$7E ; with one well place:4
  DEFB $80,$AF,$06,$88,$66,$0E,$B5,$BE ; blow <subj> cleave <his_obj1> skull:3

; Message: <his_subj> violent attack almost kills <subj>.
MsgViolentAttackAlmost:
  DEFB $0C                ; <his_subj>
  DEFM " VIOLENT"
  DEFB $80,$73,$87,$D9,$C3,$A8,$06,$15 ; attack almost kill:4 <subj> <end,.nl>

; Message: <subj> give <obj1> a vicious cut in the ribs- <his...
;
; <subj> give <obj1> a vicious cut in the ribs- <his_obj1> strength is failing
; fast.
MsgGiveViciousCutRibs:
  DEFB $06,$82,$D4,$07,$60,$87,$41 ; <subj> give <obj1> a vicious
  DEFB $D1,$78,$70,$78,$85,$39,$2D,$0E ; cut in the ribs "-" <his_obj1>
  DEFB $8B,$2E,$71,$89,$02,$B2,$53 ; strength is failing fast:3

; Message: A nasty slice misses <his_obj1> heart.
MsgNastySliceMissesHeart:
  DEFB $60,$84,$6A,$85,$CF,$CA,$25,$0E ; a nasty slice miss:4 <his_obj1>
  DEFB $B3,$22            ; heart:3

; Message: <subj> slice <his_obj1>- hand blood drips slowly t...
;
; <subj> slice <his_obj1>- hand blood drips slowly to the ground.
MsgSliceHandBloodDrips:
  DEFB $06,$85,$CF,$0E,$2D,$83,$12 ; <subj> slice <his_obj1> "-" hand
  DEFB $80,$B3,$88,$CA,$85,$DB,$7B,$78 ; blood drips slowly to the
  DEFB $B9,$65            ; ground:3

; Message: <subj> give <obj1> a nasty slash in the leg.
MsgGiveNastySlashLeg:
  DEFB $06,$82,$D4,$07,$60,$84,$6A ; <subj> give <obj1> a nasty
  DEFB $D5,$C3,$70,$78,$B3,$C9 ; slash in the leg:3

; Message: <subj> hit <obj1> hard on the shoulder- <obj1> sta...
;
; <subj> hit <obj1> hard on the shoulder- <obj1> stagger and almost fall.
MsgHitHardOnShoulder:
  DEFB $06,$83,$47,$07,$83,$16,$75,$78 ; <subj> hit <obj1> hard on the
  DEFB $85,$9E,$2D,$07,$9B,$03,$61 ; shoulder "-" <obj1> stagger:1 and
  DEFB $87,$D9,$92,$4F,$15 ; almost fall:1 <end,.nl>

; Message: A fast blow knocks the wind out of <obj1>.
MsgFastBlowKnocksWindOut:
  DEFB $60,$82,$53,$65,$89,$BF,$78 ; a fast blow knocks the
  DEFB $8B,$DA,$84,$BF,$74,$07,$15 ; wind out of <obj1> <end,.nl>

; Message: A fast stroke sweeps <obj1> off <his_obj1> feet, b...
;
; A fast stroke sweeps <obj1> off <his_obj1> feet, but <obj1_is> on guard in a
; moment.
MsgFastStrokeSweepsOff:
  DEFB $60,$82,$53,$86,$5E,$8B,$40,$07 ; a fast stroke sweeps <obj1>
  DEFB $84,$9F,$0E,$82,$5D,$2C,$66,$11 ; off <his_obj1> feet "," but <obj1_is>
  DEFB $75,$89,$6F,$70,$60,$BA,$29 ; on guard in a moment:3

; Message: <subj> hit <obj1> with a glancing blow and leave <...
;
; <subj> hit <obj1> with a glancing blow and leave <obj1> momentarily stunned.
MsgHitWithGlancingBlow:
  DEFB $06,$83,$47,$07,$7E,$60,$89,$4C ; <subj> hit <obj1> with a glancing
  DEFB $65,$61,$83,$C4,$07,$8A,$2F ; blow and leave <obj1> momentarily
  DEFB $B6,$70            ; stunned:3

; Message: <subj> thrust <obj1> back- <obj1> lose <his_obj1>...
;
; <subj> thrust <obj1> back- <obj1> lose <his_obj1> footing but recover
; quickly.
MsgThrustBackLoseFooting:
  DEFB $06,$8B,$81,$07,$80,$7C,$2D,$07 ; <subj> thrust <obj1> back "-" <obj1>
  DEFB $99,$E8,$0E,$89,$35,$66,$9A,$A4 ; lose:1 <his_obj1> footing but
                                       ; recover:1
  DEFB $B5,$0C            ; quickly:3

; Message: <subj> swing broadside at <his_obj1> body but at t...
;
; <subj> swing broadside at <his_obj1> body but at the last moment <obj1> jump
; aside.
MsgSwingBroadsideAtBody:
  DEFB $06,$8B,$4B,$88,$4B,$63,$0E ; <subj> swing broadside at <his_obj1>
  DEFB $80,$BF,$66,$63,$78,$89,$C9 ; body but at the last
  DEFB $8A,$29,$07,$93,$A1,$B8,$08 ; moment <obj1> jump:1 aside:3

; Message: <his_subj> <word2> sweeps past close to <his_obj1>...
;
; <his_subj> <word2> sweeps past close to <his_obj1> ear.
MsgSweepsPastCloseEar:
  DEFB $0C,$03,$8B,$40,$8A,$7A,$81,$34 ; <his_subj> <word2> sweeps past close
  DEFB $7B,$0E,$B1,$FB    ; to <his_obj1> ear:3

; Message: <subj> slash at <obj1> but the blow is ineffective.
MsgSlashAtButBlow:
  DEFB $06,$85,$C3,$63,$07,$66,$78,$65 ; <subj> slash at <obj1> but the blow
  DEFB $71,$B9,$A0        ; is ineffective:3

; Message: <subj> brandish <his_subj> <word2>, but <obj1_is>...
;
; <subj> brandish <his_subj> <word2>, but <obj1_is> on guard.
MsgBrandishButOnGuard:
  DEFB $06,$88,$3E,$0C,$03,$2C,$66,$11 ; <subj> brandish <his_subj> <word2> ","
                                       ; but <obj1_is>
  DEFB $75,$B9,$6F        ; on guard:3

; Message: <subj> swing feebly at <obj1> but miss by a wide m...
;
; <subj> swing feebly at <obj1> but miss by a wide margin.
MsgSwingFeeblyAtButMiss:
  DEFB $06,$8B,$4B,$82,$57,$63,$07,$66 ; <subj> swing feebly at <obj1> but
  DEFB $8A,$25,$88,$5B,$60,$87,$7D ; miss by a wide
  DEFB $B9,$FD            ; margin:3

; Message: <subj> seem tired- <subj> stagger but valiantly at...
;
; <subj> seem tired- <subj> stagger but valiantly attempt another blow.
MsgSeemTiredStaggerBut:
  DEFB $06,$8A,$B2,$8B,$8B,$2D,$06 ; <subj> seem tired "-" <subj>
  DEFB $8B,$03,$66,$87,$28,$4C,$59 ; stagger but valiant "LY"
  DEFB $88,$13,$80,$5E,$B0,$AF ; attempt another blow:3

; Message: But the effort is wasted. <his_obj1> defense is to...
;
; But the effort is wasted. <his_obj1> defense is too strong.
MsgButEffortWasted:
  DEFB $66,$78,$88,$CF,$71,$8B,$BB,$2E ; but the effort is wasted "."
  DEFB $0E,$88,$A2,$71,$7C,$B6,$64 ; <his_obj1> defense is too strong:3

; Message: You cannot kill with <obj2>.
MsgCannotKillWith:
  DEFB $7F,$67,$83,$A8,$7E,$09,$15 ; you cannot kill with <obj2> <end,.nl>

; Message: It sails across and
MsgSailsAcross:
  DEFB $72,$CA,$AB,$80,$43,$A0,$5B ; it sail:4 across and:2

; Message: Lands on the other side.
MsgLandsOnOtherSide:
  DEFB $83,$BB,$53,$75,$78,$8A,$6B ; land "S" on the other
  DEFB $B5,$A6            ; side:3

; Message: Falls just short of the other side.
MsgFallsJustShortOther:
  DEFB $C2,$4F,$89,$B1,$85,$99,$74,$78 ; fall:4 just short of the
  DEFB $8A,$6B,$B5,$A6    ; other side:3

; Message: Lands in the boat. / But slides out again.
MsgLandsBoatButSlidesOut:
  DEFB $0B,$08,$66,$CA,$D4,$84,$BF ; <call $AF8B> but slide:4 out
  DEFB $B7,$C3            ; again:3

; Message: Lands in the boat.
MsgLandsBoat:
  DEFB $83,$BB,$53,$70,$78,$B0,$B8 ; land "S" in the boat:3

; Message: The boat glides across the river and lands on this...
;
; The boat glides across the river and lands on this side.
MsgBoatGlidesAcrossRiver:
  DEFB $78,$80,$B8,$89,$54,$80,$43,$78 ; the boat glides across the
  DEFB $85,$4A,$61,$83,$BB,$53,$75,$7A ; river and land "S" on this
  DEFB $B5,$A6            ; side:3

; Message: With a lurch the boat glides across the river and...
;
; With a lurch the boat glides across the river and lands on the other side.
MsgWithLurchBoatGlides:
  DEFB $7E,$60,$89,$B5,$78,$80,$B8 ; with a lurch the boat
  DEFB $89,$54,$80,$43,$78,$85,$4A,$61 ; glides across the river and
  DEFB $02,$B9            ; <jump to $AF6D>
MsgNot:
  DEFB $07,$71,$73,$70,$09,$15 ; <obj1> is not in <obj2> <end,.nl>

; Message: <the_arg> is <word>.
MsgTheArgIsWord:
  DEFB $04,$71,$01,$15    ; <the_arg> is <word> <end,.nl>

; Message: I cannot do that.
MsgICannotDoThat:
  DEFB $6F,$67,$69,$B6,$9B ; i cannot do that:3

; Message: I see nothing here.
MsgISeeNothingHere:
  DEFB $6F,$76,$8A,$5D,$B9,$89 ; i see nothing here:3

; Message: In the
MsgInThe:
  DEFB $83,$78,$02,$11,$84,$AA,$02,$0D ; in <jump to $AFDE> on <jump to $AFDE>
  DEFB $88,$25,$02,$09,$8B,$9B,$02,$05 ; behind <jump to $AFDE> under <jump to
                                       ; $AFDE>
  DEFB $86,$CD,$44,$7B,$78,$16 ; tie "D" to the <end>

; Message: <word> there <word>
MsgThere:
  DEFB $01,$79,$01,$14    ; <word> there <word> <end,nl>

; Message: <the_arg> is carrying <the_arg>.
MsgCarrying3:
  DEFB $04,$71,$68,$04,$15 ; <the_arg> is carrying <the_arg> <end,.nl>

; Message: I cannot follow <obj1> from here.
MsgICannotFollowFromHere:
  DEFB $6F,$67,$82,$85,$07,$6D,$6E,$15 ; i cannot follow <obj1> from here
                                       ; <end,.nl>

; Message: <subj_is> dead.
MsgDead:
  DEFB $10,$B1,$92        ; <subj_is> dead:3

; Message: <subj> see nothing special here.
MsgSeeNothingSpecialHere:
  DEFB $06,$76,$8A,$5D,$8A,$F7,$B9,$89 ; <subj> see nothing special here:3

; Message: <subj_is> in
MsgSubjIsIn:
  DEFB $10,$83,$78,$16    ; <subj_is> in <end>

; Message: <subj> see
MsgSee:
  DEFB $06,$76,$16        ; <subj> see <end>

; Message: <subj> see :
MsgSee2:
  DEFB $06,$8A,$AF,$20,$3A,$14 ; <subj> see " :" <end,nl>

; Message: <subj> say "
MsgSay:
  DEFB $06,$85,$84,$20,$22,$16 ; <subj> say " "" <end>

; Message: ".
MsgB00F:
  DEFB $20,$22,$2E,$14    ; " "." <end,nl>

; Message: There is <thing>
MsgThere2:
  DEFB $79,$71,$00,$14    ; there is <thing> <end,nl>

; Message: <thing> enters.
MsgEnters:
  DEFB $00                ; <thing>
MsgEnters2:
  DEFB $C2,$2D,$2E,$14    ; enter:4 "." <end,nl>

; Message: <thing> appears.
MsgAppears:
  DEFB $00,$C7,$EA,$15    ; <thing> appear:4 <end,.nl>

; Message: Visible exits are:
MsgVisibleExits:
  DEFB $8B,$AD,$88,$F1,$62,$3A,$16 ; visible exits are ":" <end>

; Message: You hear a noise.
MsgHearNoise:
  DEFB $7F,$D9,$85,$60,$BA,$55 ; you hear a noise:3

; Message: <obj2> does not fit this lock.
MsgDoesNotFitThisLock:
  DEFB $09,$69,$45,$53,$73,$89,$19,$7A ; <obj2> do "ES" not fit this
  DEFB $B3,$F2            ; lock:3

; Message: The magic door opens.
MsgMagicDoorOpens:
  DEFB $78,$84,$24,$6A,$C4,$B4,$2E,$14 ; the magic door open:4 "." <end,nl>

; Message: The magic door closes.
MsgMagicDoorCloses:
  DEFB $78,$84,$24,$6A,$C1,$34,$2E,$14 ; the magic door close:4 "." <end,nl>

; Message: Thank you
MsgThank:
  DEFB $8B,$58,$A7,$A8    ; thank you:2

; Message: What's this ?
MsgWhatSThis:
  DEFB $7D,$27,$53,$7A,$20,$3F,$16 ; what "'S" this " ?" <end>

; Message: You are doing a great job
MsgDoingGreatJob:
  DEFB $7F,$62,$C8,$C6,$60,$82,$FF ; you are do:4 a great
  DEFB $A9,$AE            ; job:2

; Message: Hurry up
MsgHurryUp:
  DEFB $89,$9B,$A7,$25    ; hurry up:2

; Message: Hello
MsgHello:
  DEFB $A3,$2C            ; hello:2

; Message: This was Thrains key
MsgThisWasThrainsKey:
  DEFB $7A,$8B,$B8,$FB,$6F,$A3,$A5 ; this was thrains:7 key:2

; Message: <obj1> falls down a hole and vanishes.
MsgFallsDownHoleVanishes:
  DEFB $07,$C2,$4F,$81,$C4,$60,$83,$5D ; <obj1> fall:4 down a hole
  DEFB $61,$CB,$A3,$15    ; and vanish:4 <end,.nl>

; Message: <subj_is> not wearing <obj1>.
MsgNotWearing:
  DEFB $10,$73,$87,$72,$49,$4E,$47,$07 ; <subj_is> not wear "ING" <obj1>
  DEFB $15                ; <end,.nl>

; Message: <obj2> is already tied.
MsgAlreadyTied:
  DEFB $09,$71,$80,$51,$86,$CD,$44,$15 ; <obj2> is already tie "D" <end,.nl>

; Message: The vicious warg run around you and howls
MsgViciousWargRunAround:
  DEFB $78,$87,$41,$87,$9A,$85,$6C ; the vicious warg run
  DEFB $87,$F8,$7F,$61,$A9,$96 ; around you and howls:2

; Message: <obj1> is not tied.
MsgNotTied:
  DEFB $07,$71,$73,$86,$CD,$44,$15 ; <obj1> is not tie "D" <end,.nl>

; Message: Some spiders start mending the broken web.
MsgSomeSpidersStart:
  DEFB $77,$86,$23,$53,$8B,$17,$CA,$15 ; some spider "S" start mend:4
  DEFB $78,$80,$CD,$B7,$76 ; the broken web:3

; Message: What do you expect me to do with this ?
MsgWhatDoExpectMeDo:
  DEFB $7D,$69,$7F,$88,$F6,$84,$2F,$7B ; what do you expect me to
  DEFB $69,$7E,$7A,$20,$3F,$16 ; do with this " ?" <end>

; Message: As soon as <subj> touch the river <subj> fall asle...
;
; As soon as <subj> touch the river <subj> fall asleep and gently float away.
MsgAsSoonAsTouchRiver:
  DEFB $88,$05,$8A,$F3,$88,$05,$06 ; as soon as <subj>
  DEFB $8B,$93,$78,$85,$4A,$06,$6C ; touch the river <subj> fall
  DEFB $88,$0D,$61,$82,$C8,$89,$26 ; asleep and gently float
  DEFB $B8,$1A            ; away:3

; Message: Where's the thief ?
MsgWhereSThief:
  DEFB $8B,$CC,$27,$53,$78,$86,$AB,$20 ; where "'S" the thief " "
  DEFB $3F,$16            ; "?" <end>

; Message: Get us out of this one, thief !
MsgGetUsOutThisOne:
  DEFB $82,$CE,$8B,$A0,$84,$BF,$74,$7A ; get us out of this
  DEFB $84,$AD,$2C,$86,$AB,$20,$21,$16 ; one "," thief " !" <end>

; Message: Thorin sits down and starts singing about gold
MsgThorinSitsDownStarts:
  DEFB $86,$B4,$CA,$D0,$81,$C4,$61 ; thorin sit:4 down and
  DEFB $CB,$17,$CA,$C8,$87,$B0,$A2,$EF ; start:4 sing:4 about gold:2

; Message: Thorin wait
MsgThorinWait:
  DEFB $86,$B4,$A7,$56    ; thorin wait:2

; Message: <subj> fall asleep.
MsgFallAsleep:
  DEFB $06,$6C,$88,$0D,$15 ; <subj> fall asleep <end,.nl>

; Message: The spider web is slowly smothering you
MsgSpiderWebSlowly:
  DEFB $78,$86,$23,$87,$76,$71,$85,$DB ; the spider web is slowly
  DEFB $85,$F3,$A7,$A8    ; smothering you:2

; Message: The small curious key shatters.
MsgSmallCuriousKey:
  DEFB $78,$85,$E1,$81,$63,$83,$A5 ; the small curious key
  DEFB $CA,$C1,$15        ; shatter:4 <end,.nl>

; Message: An elf sweeps past.
MsgElfSweepsPast:
  DEFB $80,$58,$82,$0A,$8B,$40,$BA,$7A ; an elf sweeps past:3

; Message: You cannot reach <obj1>.
MsgCannotReach:
  DEFB $7F,$67,$8A,$9F,$07,$15 ; you cannot reach <obj1> <end,.nl>

; Message: <subj_is> not carrying the bow.
MsgNotCarryingBow:
  DEFB $10,$73,$68,$78,$B0,$C3 ; <subj_is> not carrying the bow:3

; Message: The arrow misses <obj2> by a wide margin.
MsgArrowMissesByWide:
  DEFB $78,$80,$6B,$8A,$25,$45,$53,$09 ; the arrow miss "ES" <obj2>
  DEFB $88,$5B,$60,$87,$7D,$B9,$FD ; by a wide margin:3

; Message: The arrow hits <obj1>.
MsgArrowHits:
  DEFB $78,$80,$6B,$D3,$47,$53,$07,$15 ; the arrow hit "S" <obj1> <end,.nl>

; Message: <subj_is> too big.
MsgTooBig:
  DEFB $10,$7C,$B0,$A2    ; <subj_is> too big:3

; Message: <thing> evaporates.
MsgEvaporates:
  DEFB $00                ; <thing>
MsgEvaporates2:
  DEFB $C8,$E1,$15        ; evaporate:4 <end,.nl>

; Message: <his_subj> foul gluttony has killed <subj>.
MsgFoulGluttonyHasKilled:
  DEFB $0C,$82,$B1,$89,$5A,$89,$7B ; <his_subj> foul gluttony has
  DEFB $D3,$A8,$45,$44,$06,$15 ; kill "ED" <subj> <end,.nl>

; Message: <subj_is> slowly sinking into the bog.
MsgSlowlySinkingIntoBog:
  DEFB $10,$85,$DB,$CA,$CC,$83,$8E,$78 ; <subj_is> slowly sink:4 into the
  DEFB $B0,$BC            ; bog:3

; Message: The dragon says " Well thief your cunning has fail...
;
; The dragon says " Well thief your cunning has failed you this time. Prepare
; to die " .
MsgDragonSaysWellThief:
  DEFB $78,$6B,$C5,$84,$20,$22,$FB,$C4 ; the dragon say:4 " "" well:7
  DEFB $86,$AB,$8B,$EA,$81,$71,$89,$7B ; thief your cunning has
  DEFB $88,$FC,$7F,$7A,$8B,$87,$2E ; failed you this time "."
  DEFB $8A,$91,$7B,$88,$B1 ; prepare to die
  DEFM " \" ."
  DEFB $14                ; <end,nl>

; Message: The dragon says " I may not be able to see you thi...
;
; The dragon says " I may not be able to see you thief but I can still burn
; you. Prepare to die " .
MsgDragonSaysIMayNot:
  DEFB $78,$6B,$C5,$84,$20,$22,$F3,$73 ; the dragon say:4 " "" i:7
  DEFB $8A,$0D,$73,$64,$87,$AC,$7B,$76 ; may not be able to see
  DEFB $7F,$86,$AB,$66,$F3,$73,$80,$EB ; you thief but i:7 can
  DEFB $8B,$1C,$80,$D3,$7F,$2E,$8A,$91 ; still burn you "." prepare
  DEFB $7B,$88,$B1        ; to die
  DEFM " \" ."
  DEFB $14                ; <end,nl>

; Message: In the distance you see the shape of a monstrous d...
;
; In the distance you see the shape of a monstrous dragon flying after you.
MsgDistanceSeeShape:
  DEFB $70,$78,$88,$BA,$7F,$76,$78 ; in the distance you see the
  DEFB $8A,$BC,$74,$60,$84,$45,$6B ; shape of a monstrous dragon
  DEFB $89,$2B,$80,$49,$B7,$A8 ; flying after you:3

; Message: The dragon descends and in a terrific spout of fla...
;
; The dragon descends and in a terrific spout of flames burns you to a crisp.
MsgDragonDescends:
  DEFB $78,$6B,$88,$A9,$61,$70,$60 ; the dragon descends and in a
  DEFB $8B,$50,$DA,$FE,$74,$82,$6F ; terrific spout of flames
  DEFB $C0,$D3,$7F,$7B,$60,$88,$96,$15 ; burn:4 you to a crisp <end,.nl>

; Message: Go <word> from <thing> to get to <thing>
MsgGoFromGet:
  DEFB $D2,$DE,$01,$6D,$00,$7B,$D2,$CE ; go <word> from <thing> to get
  DEFB $7B,$00,$16        ; to <thing> <end>

; Message: Someone strangles you from behind.
MsgSomeoneStranglesFrom:
  DEFB $8A,$E3,$CB,$26,$7F,$6D,$B8,$25 ; someone strangle:4 you from behind:3

; Message: <obj1> says " No "
MsgSaysNo:
  DEFB $07,$85,$84,$53,$20,$22,$FA,$52 ; <obj1> say "S "" no:7
  DEFB $20,$22,$14        ; " "" <end,nl>

; Message: It cannot be seen, cannot be felt / Cannot be hear...
;
; It cannot be seen, cannot be felt / Cannot be heard, cannot be smelt. / It
; lies behind stars and under hills, / And empty holes it fills. / It comes
; first and follows after, / ends life, kills laughter.
LB1EE:
  DEFB $72,$67,$64,$76,$4E,$2C,$67,$64 ; it cannot be see "N," cannot be
  DEFB $89,$15,$0D,$F0,$EE,$64,$C9,$85 ; felt <nl> cannot:7 be hear:4
  DEFB $2C,$67,$64,$8A,$DE,$2E,$0D ; "," cannot be smelt "." <nl>
  DEFB $F3,$9E,$C9,$DB,$88,$25,$CB,$0F ; it:7 lie:4 behind star:4
  DEFB $61,$8B,$9B,$83,$42,$2C,$0D ; and under hills "," <nl>
  DEFB $F0,$5B,$D2,$28,$83,$5D,$53,$72 ; and:7 empty hole "S" it
  DEFB $C2,$61,$2E,$0D,$F3,$9E,$C8,$71 ; fill:4 "." <nl> it:7 come:4
  DEFB $89,$1C,$61,$C2,$85,$80,$49,$2C ; first and follow:4 after ","
  DEFB $0D,$C8,$D5,$89,$DF,$2C,$C3,$A8 ; <nl> end:4 life "," kill:4
  DEFB $89,$D3,$2E,$16    ; laughter "." <end>

; Message: Blimey, look at this!! Can yer cook'em?
MsgBlimeyLookAtThisCan:
  DEFB $88,$38,$2C,$84,$13,$63,$7A,$21 ; blimey "," look at this "!"
  DEFB $21,$F0,$EB,$8B,$E7,$88,$8B ; "!" can:7 yer cook
  DEFM "'EM?"
  DEFB $16                ; <end>

; Message: Yer can try, but he wouldn't make above a mouthfull
MsgYerCanTryButHe:
  DEFB $8B,$E7,$80,$EB,$8B,$90,$2C,$66 ; yer can try "," but
  DEFB $89,$82,$8B,$E2,$4E,$27,$54 ; he would "N'T"
  DEFB $89,$F9,$87,$B5,$60,$AA,$3E ; make above a mouthfull:2

; Message: In a clearing with two stone trolls
MsgClearingWithTwoStone:
  DEFB $70,$60,$81,$27,$7E,$8B,$98 ; in a clearing with two
  DEFB $86,$41,$A6,$FD    ; stone trolls:2

; Message: <subj_is> swept forcefully against the portcullis.
MsgSweptForcefully:
  DEFB $10,$8B,$46,$82,$92,$87,$C8,$78 ; <subj_is> swept forcefully against the
  DEFB $B4,$F1            ; portcullis:3

; Message: There is a loud crack and a hole appears about thr...
;
; There is a loud crack and a hole appears about three feet from the ground. /
; You are standing in front of the side door to the Lonely Mountain.
MsgThereLoudCrackHole:
  DEFB $79,$71,$60,$89,$EC,$81,$51,$61 ; there is a loud crack and
  DEFB $60,$83,$5D,$C7,$EA,$87,$B0 ; a hole appear:4 about
  DEFB $8B,$76,$82,$5D,$6D,$78,$89,$65 ; three feet from the ground
  DEFB $2E,$0D,$F7,$A8,$62,$CB,$0A,$70 ; "." <nl> you:7 are stand:4 in
  DEFB $89,$40,$74,$78,$85,$A6,$6A,$7B ; front of the side door to
  DEFB $78,$F4,$09,$F4,$4E,$15 ; the lonely:7 mountain:7 <end,.nl>

; Message: The hole vanishes.
MsgHoleVanishes:
  DEFB $78,$83,$5D,$CB,$A3,$15 ; the hole vanish:4 <end,.nl>

; Message: The magic door warns of elves approaching.
MsgMagicDoorWarnsElves:
  DEFB $F6,$9F,$84,$24,$6A,$CB,$B4,$74 ; the:7 magic door warn:4 of
  DEFB $82,$1D,$C7,$F0,$15 ; elves approach:4 <end,.nl>

; Message: Which is the animal that has four feet in the morn...
;
; Which is the animal that has four feet in the morning, two at midday and
; three in the evening ?
LB2B7:
  DEFB $8B,$D1,$71,$78,$87,$E4,$86,$9B ; which is the animal that
  DEFB $89,$7B,$89,$3C,$82,$5D,$70,$78 ; has four feet in the
  DEFB $CA,$3A,$2C,$8B,$98,$63,$8A,$1F ; morn:4 "," two at midday
  DEFB $61,$8B,$76,$70,$78,$88,$EA,$20 ; and three in the evening " "
  DEFB $3F,$16            ; "?" <end>

; Message: What has it got in its pockets ?
MsgWhatHasGotPockets:
  DEFB $7D,$89,$7B,$72,$89,$62,$70 ; what has it got in
  DEFB $89,$AB,$CA,$83,$20,$3F,$16 ; its pocket:4 " ?" <end>

; Message: My birthday present " how did we lose it. / my pre...
;
; My birthday present " how did we lose it. / my precious "
MsgMyBirthdayPresentHow:
  DEFB $8A,$4F,$88,$30,$8A,$98,$20,$22 ; my birthday present " ""
  DEFB $89,$93,$88,$B4,$8B,$C1,$89,$E8 ; how did we lose
  DEFB $72,$2E,$0D,$8A,$4F,$8A,$89,$20 ; it "." <nl> my precious " "
  DEFB $22,$16            ; """ <end>

; Message: <subj> cannot jump onto <obj1> from here.
;
; Used by the routine at LA9E5.
MsgCannotJumpOntoFrom:
  DEFB $06,$67,$83,$A1,$84,$B0,$07,$6D ; <subj> cannot jump onto <obj1> from
  DEFB $6E,$15            ; here <end,.nl>

; Message: Day dawns.
MsgDayDawns:
  DEFB $88,$9F,$C8,$9B,$B0,$00 ; day dawn:4 (none):3

; Message: <subj> see some pale bulbous eyes staring at <subj>.
MsgSeeSomePaleBulbous:
  DEFB $06,$76,$77,$8A,$70,$88,$54 ; <subj> see some pale bulbous
  DEFB $82,$4B,$CB,$13,$63,$06,$15 ; eyes star:4 at <subj> <end,.nl>

; Message: Some thing drops from above and stings.
MsgSomeDropsFromAbove:
  DEFB $77,$86,$B0,$47,$C1,$E8,$6D ; some thin "G" drop:4 from
  DEFB $87,$B5,$61,$CB,$21,$15 ; above and sting:4 <end,.nl>

; Message: You are thrown onto the bank of the long lake.
MsgThrownOntoBankLong:
  DEFB $7F,$62,$8B,$7B,$84,$B0,$78 ; you are thrown onto the
  DEFB $88,$1E,$74,$78,$84,$0F,$B3,$B7 ; bank of the long lake:3

; Message: Nothing
MsgNothing:
  DEFM "     "
  DEFB $EA,$5D            ; nothing:6

; Message: Start tape then press any key.
MsgStartTapeThenPressAny:
  DEFB $8B,$17            ; start
  DEFM " TAPE"
  DEFB $86,$A2            ; then
  DEFM " PRESS ANY"
  DEFB $B3,$A5            ; key:3

; Message: Tape error -     hit any key to restart program.
MsgTapeErrorHitAnyKey:
  DEFM "TAPE ERROR -    "
  DEFB $83,$47            ; hit
  DEFM " ANY"
  DEFB $83,$A5,$7B        ; key to
  DEFM " RESTART PROGRAM"
  DEFB $15                ; <end,.nl>

; Message: Tape error -     hit any key to continue.
MsgTapeErrorHitAnyKey2:
  DEFM "TAPE ERROR -    "
  DEFB $83,$47            ; hit
  DEFM " ANY"
  DEFB $83,$A5,$7B        ; key to
  DEFM " CONTINUE"
  DEFB $15                ; <end,.nl>

; Message: Rewind and prepare tape for     verification  -- t...
;
; Rewind and prepare tape for     verification  -- then hit any key.
MsgRewindPrepareTapeFor:
  DEFM "REWIND"
  DEFB $61                ; and
  DEFM " PREPARE TAPE"
  DEFB $82,$8F            ; for
  DEFM "     VERIFICATION  --"
  DEFB $86,$A2,$83,$47    ; then hit
  DEFM " ANY"
  DEFB $B3,$A5            ; key:3

; Message: a cheering crowd of dwarves, hobbits and elves app...
;
; a cheering crowd of dwarves, hobbits and elves appears. Led by gandalf they
; carry you off into the sunset, proclaiming you  hero of heroes and master
; adventurer !!!.
MsgCheeringCrowdDwarves:
  DEFB $0D,$0D,$0D,$60    ; <nl> <nl> <nl> a
  DEFM " CHEERING CROWD"
  DEFB $74                ; of
  DEFM " DWARVES, HOBBITS"
  DEFB $61,$82,$1D,$C7,$EA ; and elves appear:4
  DEFM ". LED"
  DEFB $88,$5B,$82,$BD    ; by gandalf
  DEFM " THEY"
  DEFB $81,$0D,$7F,$84,$9F,$83,$8E,$78 ; carry you off into the
  DEFM " SUNSET, PROCLAIMING"
  DEFB $7F                ; you
  DEFM "  HERO"
  DEFB $74                ; of
  DEFM " HEROES"
  DEFB $61                ; and
  DEFM " MASTER ADVENTURER !!!"
  DEFB $15                ; <end,.nl>

; Message: You have mastered
MsgHaveMastered:
  DEFB $7F,$89,$7E        ; you have
  DEFM " MASTERED "
  DEFB $16                ; <end>

; Message: % Of this adventure.
MsgThisAdventure:
  DEFB $25,$74,$7A,$B7,$BA ; "%" of this adventure:3

; Message: You're doing fine.
MsgReDoingFine:
  DEFM " YOU'RE DOING FINE"
  DEFB $15                ; <end,.nl>

; Message: A trolls door needs a trolls key.
LB47A:
  DEFB $60,$86,$FD,$81,$C0 ; a trolls door
  DEFM " NEEDS"
  DEFB $60,$86,$FD,$B3,$A5 ; a trolls key:3

; Message: Elves are good at reading symbols.
LB48A:
  DEFB $82,$1D,$62        ; elves are
  DEFM " GOOD"
  DEFB $63,$85,$30,$49,$4E,$47,$B6,$85 ; at read "ING" symbols:3

; Message: A window should be no obstacle to a thief with fri...
;
; A window should be no obstacle to a thief with friends.
LB49A:
  DEFB $60,$87,$8C        ; a window
  DEFM " SHOULD"
  DEFB $64,$8A,$52        ; be no
  DEFM " OBSTACLE"
  DEFB $7B,$60,$86,$AB,$7E ; to a thief with
  DEFM " FRIENDS"
  DEFB $15                ; <end,.nl>

; Message: Boats can help. Look carefully.
LB4BE:
  DEFB $80,$B8,$53,$80,$EB,$83,$1E,$2E ; boat "S" can help "."
  DEFB $F4,$13,$B0,$FD    ; look:7 carefully:3

; Message: Wait around and time your exit carefully.
LB4CA:
  DEFB $87,$56,$87,$F8,$61,$8B,$87 ; wait around and time
  DEFB $8B,$EA            ; your
  DEFM " EXIT"
  DEFB $B0,$FD            ; carefully:3

; Message: Timing is critical, remember barrels float.
LB4DA:
  DEFM " TIMING"
  DEFB $71                ; is
  DEFM " CRITICAL, REMEMBER"
  DEFB $80,$84,$53,$B9,$26 ; barrel "S" float:3

; Message: Wait a while.
LB4FA:
  DEFB $87,$56,$60        ; wait a
  DEFM " WHILE"
  DEFB $15                ; <end,.nl>

; Message: Take care to leave at the right time.
LB504:
  DEFB $86,$8C            ; take
  DEFM " CARE"
  DEFB $7B,$83,$C4,$63,$78 ; to leave at the
  DEFM " RIGHT"
  DEFB $BB,$87            ; time:3

; Message: A living dragon is deadly, look to bard.
LB518:
  DEFB $60                ; a
  DEFM " LIVING"
  DEFB $6B,$71            ; dragon is
  DEFM " DEADLY,"
  DEFB $84,$13,$7B,$B0,$80 ; look to bard:3

; Message: Don't stay here too long.
LB52F:
  DEFM " DON'T STAY"
  DEFB $6E,$7C,$B4,$0F    ; here too long:3

; Message: Wait for the new day dawning.
LB53E:
  DEFB $87,$56,$82,$8F,$78 ; wait for the
  DEFM " NEW"
  DEFB $88,$9F            ; day
  DEFM " DAWNING"
  DEFB $15                ; <end,.nl>

; Message: There seem to be some symbols on it but <subj> can...
;
; There seem to be some symbols on it but <subj> cannot read them.
LB552:
  DEFB $79,$DA,$B2,$7B,$64,$77,$86,$85 ; there seem to be some symbols
  DEFB $75,$72,$66,$06,$67,$85,$30 ; on it but <subj> cannot read
  DEFB $BB,$5D            ; them:3

; Message: You see a fast flowing black river not very wide a...
;
; You see a fast flowing black river not very wide across.
LB563:
  DEFB $7F,$76,$60,$82,$53,$82,$7E ; you see a fast flowing
  DEFB $80,$A5,$85,$4A,$73,$87,$3D ; black river not very
  DEFB $87,$7D,$B0,$43    ; wide across:3

; Message: A comfortable tunnel like hall
LB575:
  DEFB $60,$81,$3F,$87,$03,$83,$DA ; a comfortable tunnel like
  DEFB $A3,$09            ; hall:2

; Message: A gloomy empty land with dreary hills ahead
LB57E:
  DEFB $60,$82,$D8,$82,$28,$83,$BB,$7E ; a gloomy empty land with
  DEFB $81,$DD,$83,$42,$A7,$CF ; dreary hills ahead:2

; Message: A hidden path with trolls foot prints
LB58C:
  DEFB $60,$83,$31,$84,$D4,$7E,$86,$FD ; a hidden path with trolls
  DEFB $89,$31,$84,$FB,$53,$16 ; foot print "S" <end>

; Message: The trolls cave
LB59A:
  DEFB $78,$86,$FD,$A1,$12 ; the trolls cave:2

; Message: A hard dangerous path in the misty mountains
LB59F:
  DEFB $60,$83,$16,$81,$85,$84,$D4,$70 ; a hard dangerous path in
  DEFB $78,$84,$40,$A4,$56 ; the misty mountains:2

; Message: A narrow place with a dreadful drop into a dim val...
;
; A narrow place with a dreadful drop into a dim valley
LB5AC:
  DEFB $60,$84,$64,$D4,$E6,$7E,$60 ; a narrow place with a
  DEFB $81,$D5,$81,$E8,$83,$8E,$60 ; dreadful drop into a
  DEFB $88,$B7,$A7,$2F    ; dim valley:2

; Message: A narrow dangerous path
LB5BE:
  DEFB $60,$84,$64,$81,$85,$A4,$D4 ; a narrow dangerous path:2

; Message: A large dry cave which is quite comfortable
MsgLargeDryCaveWhich:
  DEFB $60,$83,$BF,$81,$EC,$81,$12 ; a large dry cave
  DEFB $8B,$D1,$71,$85,$1C,$A1,$3F ; which is quite comfortable:2

; Message: A big cavern with torches along the walls
LB5D3:
  DEFB $60,$80,$A2,$81,$16,$7E,$86,$D7 ; a big cavern with torch
  DEFB $45,$53,$87,$DF,$78,$87,$5A,$53 ; "ES" along the wall "S"
  DEFB $16                ; <end>

; Message: The brink of a deep dark under ground lake
MsgBrinkDeepDarkUnder:
  DEFB $78,$88,$46,$74,$60,$81,$96 ; the brink of a deep
  DEFB $81,$8E,$8B,$9B,$89,$65,$A3,$B7 ; dark under ground lake:2

; Message: The goblins gate
LB5F3:
  DEFB $78,$82,$E8,$A2,$C4 ; the goblins gate:2

; Message: The gate to mirkwood
LB5F8:
  DEFB $78,$82,$C4,$7B,$A4,$38 ; the gate to mirkwood:2

; Message: A bewitched gloomy place surrounded by thick trees
LB5FE:
  DEFB $60,$80,$99,$82,$D8,$84,$E6 ; a bewitched gloomy place
  DEFB $8B,$36,$88,$5B,$86,$A6,$C6,$EC ; surrounded by thick tree:4
  DEFB $A0,$00            ; (none):2

; Message: A place of black spiders
LB60F:
  DEFB $60,$84,$E6,$74,$80,$A5,$86,$23 ; a place of black spider
  DEFB $53,$16            ; "S" <end>

; Message: A forest of tangled smothering trees
LB619:
  DEFB $60,$82,$A0,$74,$86,$94,$85,$F3 ; a forest of tangled smothering
  DEFB $C6,$EC,$16        ; tree:4 <end>

; Message: An elvish clearing with levelled ground and logs
LB624:
  DEFB $60,$4E,$82,$22,$81,$27,$7E ; a "N" elvish clearing with
  DEFB $83,$CC,$89,$65,$61,$A3,$FC ; levelled ground and logs:2

; Message: A dark dungeon in the elvenkings halls
LB632:
  DEFB $60,$81,$8E,$81,$EF,$70,$78 ; a dark dungeon in the
  DEFB $82,$13,$A3,$0D    ; elvenkings halls:2

; Message: The cellar where the king keeps his barrels of wine
LB63D:
  DEFB $78,$81,$1C,$8B,$CC,$78,$83,$AE ; the cellar where the king
  DEFB $89,$BA,$89,$90,$80,$84,$53,$74 ; keeps his barrel "S" of
  DEFB $A7,$92            ; wine:2

; Message: A wooden town in the middle of long lake
LB64F:
  DEFB $60,$87,$A2,$86,$DC,$70,$78 ; a wooden town in the
  DEFB $8A,$19,$74,$84,$0F,$A3,$B7 ; middle of long lake:2

; Message: A strong river: the current is now too strong to m...
;
; A strong river: the current is now too strong to move against
LB65D:
  DEFB $60,$86,$64,$85,$4A,$3A,$78 ; a strong river ":" the
  DEFB $88,$8F,$71,$8A,$64,$7C,$86,$64 ; current is now too strong
  DEFB $7B,$8A,$47,$A7,$C8 ; to move against:2

; Message: A bleak barren land that was once green
LB671:
  DEFB $60,$80,$AA,$80,$8A,$83,$BB ; a bleak barren land
  DEFB $86,$9B,$8B,$B8,$8A,$67,$A3,$04 ; that was once green:2

; Message: The ruins of the town of dale
LB680:
  DEFB $78,$85,$67,$74,$78,$86,$DC,$74 ; the ruins of the town of
  DEFB $A1,$81            ; dale:2

; Message: The front gate of the lonely mountain
LB68A:
  DEFB $78,$89,$40,$82,$C4,$74,$78 ; the front gate of the
  DEFB $84,$09,$A4,$4E    ; lonely mountain:2

; Message: The west side of ravenhill
LB695:
  DEFB $78,$87,$79,$85,$A6,$74,$A5,$21 ; the west side of ravenhill:2

; Message: The halls where the dragon sleeps
LB69D:
  DEFB $78,$83,$0D,$8B,$CC,$78,$6B ; the halls where the dragon
  DEFB $C5,$CA,$16        ; sleep:4 <end>

; Message: A little steep bay, still and quiet, with an over...
;
; A little steep bay, still and quiet, with an over hanging cliff
LB6A7:
  DEFB $60,$83,$E3,$86,$3C,$80,$90,$2C ; a little steep bay ","
  DEFB $8B,$1C,$61,$85,$13,$2C,$7E ; still and quiet "," with
  DEFB $80,$58,$84,$C9,$89,$74,$A8,$6C ; an over hanging cliff:2

; Message: A smooth straight passage
LB6BE:
  DEFB $60,$85,$ED,$86,$46,$A4,$CD ; a smooth straight passage:2

; Message: The lonely mountain
LB6C5:
  DEFB $78,$84,$09,$A4,$4E ; the lonely mountain:2

; Message: The west bank of a black river
LB6CA:
  DEFB $78,$87,$79,$02,$04 ; the west <jump to $B6D2>
LB6CA_0:
  DEFB $78,$81,$FE        ; the east (reused as a tail)
  DEFB $88,$1E,$74,$60,$80,$A5,$A5,$4A ; bank of a black river:2

; Input and parse variables
;
; Words and bytes the parser and the command matcher keep (inferred from $6E9F,
; $7873, $79B6, $7A14).
InputLinePtr:
  DEFW $0000              ; pointer into the typed line, set by $6E9F
WordListPtr:
  DEFW $0000              ; pointer into the parsed word list ($7873 reads it)
WordFlags:
  DEFB $00                ; high nibble of the last word read from the list
PhraseMatched:
  DEFB $00                ; set by $71F3 when a command record matched in part
PhraseBuffer:
  DEFB $00,$00,$00,$00,$00,$00 ; six bytes copied from $7942 by $7C80
SavedCommandId:
  DEFB $00                ; copy of the command id
CommandId:
  DEFB $00                ; id (1-59) of the matched command record, looked up
                          ; in the table at $C730
FirstObject:
  DEFB $00                ; first object of the command (id), used by the
                          ; message codes 7, 14, 17
SecondObject:
  DEFB $00                ; second object, used by the codes 9
Subject:
  DEFB $00                ; who acts: 0 the player, $FF nobody (prints
                          ; "someone"); used by the codes 6, 12, 16 and the
                          ; verb suffix
