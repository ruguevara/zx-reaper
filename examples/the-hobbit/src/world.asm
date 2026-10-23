; Game state: variables saved with the game (29 bytes)
;
; Saved by SAVE with $C11B, $CA84 and $BA8A. Roles inferred from the code that
; reads and writes each byte.
;
; $B6EB-$B6ED: copy of the three bytes of the Bard command at $C9E2 (the script
; area is not saved); copied there at save ($84D2) and back at load ($848C).
;
; Actor 0 is the player; $B6EA (before this block) is the actor now acting,
; $B6E7-$B6E9 verb and the two nouns.
SavedScriptBytes:
  DEFB $00,$00,$00
RandomEventPtr:
  DEFW $0000
TimersFired:
  DEFB $00
ExitRestoreMode:
  DEFB $00
PrinterFlag:
  DEFB $00
ArrivalLocation:
  DEFB $00
ActorHasOrder:
  DEFB $00
PlayerLocation:
  DEFB $00
ActorLocation:
  DEFB $00
Score:
  DEFW $0000
ReplyGiven:
  DEFB $00
ActionPerform:
  DEFB $00
ActionAllowed:
  DEFB $00
TargetNamePtr:
  DEFW $0000
Noun1Kind:
  DEFB $00
Noun2Kind:
  DEFB $00
LispFlag:
  DEFB $00
RawOutputFlag:
  DEFB $00
MessagesVisible:
  DEFB $00
PhraseMode:
  DEFB $00
CapitalNext:
  DEFB $00
ParserFlag:
  DEFB $00
ParserWordCount:
  DEFB $FF
PicturesEnabled:
  DEFB $00

; Run-time pointers and flags (not saved)
;
; $B708/$B70A: records of the two nouns of the command ($B6E8, $B6E9); $B70C:
; record of the acting actor (initially the player, $C11B).
;
; $B70E: random seed (LD A,R at $6CA7); $B712: counter (high byte first)
; stepping through ROM bytes for $9CA8, the random number routine.
;
; $B70F-$B711: ALL/EXCEPT state of the parser (inferred). $B71B: 1 while an
; order stored in an order slot is being parsed instead of keyboard input.
Noun1Record:
  DEFW $0000
Noun2Record:
  DEFW $0000
ActorRecord:
  DEFW Chr00Player
RandomSeed:
  DEFB $00
AllActive:
  DEFB $00
AllMode:
  DEFB $00
NeedsLight:
  DEFB $00
RandomRomPtr:
  DEFB $00,$00
IdleCounter:
  DEFW $0000
NoPauseLines:
  DEFB $00
SourceTextPtr:
  DEFW $0000
AllStage:
  DEFB $00
AwaitingAnswer:
  DEFB $00
InputFromOrder:
  DEFB $00
VerbAllFlag:
  DEFB $00
StateB71D:
  DEFB $00
StateB71E:
  DEFB $00

; Word endings: 6 records of 4 bytes, zero padded
;
; Indexed by the top 3 bits of the third dictionary byte of a word (x4), read
; by $74BA: s, es, ies, BACKSPACE+ies, d, ing.
WordEndings:
  DEFB $73,$00,$00,$00
  DEFB $65,$73,$00,$00
  DEFB $69,$65,$73,$00
  DEFB $08,$69,$65,$73
  DEFB $64,$00,$00,$00
  DEFB $69,$6E,$67,$00

; Count of order slots in use
;
; Used by $7EBA as the number of slots to claim or release.
OrderSlotCount:
  DEFB $00

; Order slots: 8 slots of 25 bytes
;
; Slot: owner actor id (0 = free, $FF = being filled) then 24 bytes, the stored
; parsed command of one phrase record (24 bytes, like the parser stack).
; Cleared at start ($6CA1); found by actor with $7EFF, freed by $7F60, filled
; at $8341 (inferred from the code).
OrderSlots:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; Parser phrase stack: 24-byte records growing downward from $B9C8
;
; Phrase records of the parser ($7585-$78FF): stepped by +-24; the record at
; $B9C8 is the first, $B9B0 the one below it. Fields +8 and +$12 are 10-byte
; noun slots (inferred).
PhraseStack:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
PhraseRecord1:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
PhraseRecord1Slot1:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00
PhraseRecord1Slot2:
  DEFB $00,$00,$00,$00,$00,$00
PhraseRecord0:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

; Location table: address of the record of each location (80 words)
;
; Index = location id (0-$4F). Read by $9BB1 (A < $50 -> IX = record) and
; $7684.
LocationTable:
  DEFW Loc00None
  DEFW Loc01TunnelLikeHall
  DEFW Loc02ForestRoad
  DEFW Loc03Forest
  DEFW Loc04Lonelands
  DEFW Loc05TrollsClearing
  DEFW Loc06TrollsPath
  DEFW Loc07TrollsCave
  DEFW Loc08RunningRiver
  DEFW Loc09Rivendell
  DEFW Loc0AMistyMountain
  DEFW Loc0BNarrowPlace
  DEFW Loc0CDangerousNarrowPath
  DEFW Loc0DGoblinsDungeon
  DEFW Loc0ELargeDryCave
  DEFW Loc0FDarkStuffyPassage
  DEFW Loc10BigGoblinsCavern
  DEFW Loc11DeepDarkLake
  DEFW Loc12DarkWindingPassage
  DEFW Loc13InsideGoblinsGate
  DEFW Loc14OutsideGoblinsGate
  DEFW Loc15TreelessOpening
  DEFW Loc16BeornsHouse
  DEFW Loc17Forestriver
  DEFW Loc18ForestGate
  DEFW Loc19BewitchedGloomyPlac
  DEFW Loc1ASpiderThreadsPlace
  DEFW Loc1BSmotheringForest
  DEFW Loc1CLevelledElvishClear
  DEFW Loc1DDeepBog
  DEFW Loc1EElvenkingsGreatHall
  DEFW Loc1FDarkDungeon
  DEFW Loc20ElvenkingsCellar
  DEFW Loc21Forestriver
  DEFW Loc22LongLake
  DEFW Loc23LakeTown
  DEFW Loc24RunningRiver
  DEFW Loc25DragonsDesolation
  DEFW Loc26DaleValley
  DEFW Loc27FrontGate
  DEFW Loc28Ravenhill
  DEFW Loc29LowerHalls
  DEFW Loc2ASidedoor
  DEFW Loc2BSmoothStraightPassa
  DEFW Loc2CLonelyMountain
  DEFW Loc2DWaterfall
  DEFW Loc2EForestRoad
  DEFW Loc2FEmPlace
  DEFW Loc30Mountains
  DEFW Loc31GreatRiver
  DEFW Loc32GreenForest
  DEFW Loc33EmPlace
  DEFW Loc34DarkStuffyPassage
  DEFW Loc35DarkStuffyPassage
  DEFW Loc36DarkStuffyPassage
  DEFW Loc37DarkStuffyPassage
  DEFW Loc38DarkStuffyPassage
  DEFW Loc39DarkStuffyPassage
  DEFW Loc3ADarkStuffyPassage
  DEFW Loc3BDarkStuffyPassage
  DEFW Loc3CDarkStuffyPassage
  DEFW Loc3DDarkStuffyPassage
  DEFW Loc3EDarkStuffyPassage
  DEFW Loc3FDarkStuffyPassage
  DEFW Loc40DarkStuffyPassage
  DEFW Loc41DarkStuffyPassage
  DEFW Loc42WestBank
  DEFW Loc43EastBank
  DEFW Loc44NarrowPath
  DEFW Loc45NarrowPath
  DEFW Loc46NarrowPath
  DEFW Loc47NarrowPath
  DEFW Loc48NarrowPath
  DEFW Loc49NarrowPath
  DEFW Loc4ANarrowPath
  DEFW Loc4BSteepPath
  DEFW Loc4CSteepPath
  DEFW Loc4DSteepPath
  DEFW Loc4EDeepMistyValley
  DEFW Loc4FDeepMistyValley

; Location prepositions: 5 phrase codes (bit 7 set)
;
; Index = (location flags AND $0E)/2: outside, inside, in, on, at. Read at
; $963C, copied into the message at $AFFC.
LocationPrepositions:
  DEFW $84C2
  DEFW $837B
  DEFW $8378
  DEFW $84AA
  DEFW $8070

; Locations: 80 variable-length records (1497 bytes, saved)
;
; Record, found through $B9E0: +0 flags (bit 7: outdoors?, bits 1-3 x2:
; preposition index into $BA80), +1 capacity for objects (weight, $FF
; unlimited), +2 +4 +6 three phrase codes (noun, adjective, adjective; shown
; adjectives then noun), +8 text address (0: build the name from the phrase
; codes), +10 exits.
;
; Exit: 3 bytes direction (1-10 = the movement verbs), obstacle object id (0
; none; the door or river that blocks it, see $8E85) and destination location
; id; the list ends with $FF. Location 0 is a 13-byte dummy.
;
; At game start $97AD clears one of five exits ($C80E) and keeps the original
; for $A7C4.
Loc00None:
  DEFB $FF,$FF,$00,$00,$00,$00,$00,$00
  DEFB $00,$00
  DEFB $00,$00,$FF
Loc01TunnelLikeHall:
  DEFB $84,$A0
  DEFB $09,$13
  DEFB $03,$07
  DEFB $DA,$03
  DEFW LB575
  DEFB $03,$05,$04
  DEFB $FF
Loc04Lonelands:
  DEFB $84,$FF
  DEFB $00,$04
  DEFB $00,$00
  DEFB $00,$00
  DEFW LB57E
  DEFB $04,$05,$01
  DEFB $03,$00,$05
  DEFB $01,$00,$05
  DEFB $05,$00,$06
  DEFB $FF
Loc05TrollsClearing:
  DEFB $84,$FF
  DEFB $27,$01
  DEFB $FD,$06
  DEFB $00,$00
Loc00None_0:
  DEFW $0000
  DEFB $08,$00,$04
  DEFB $07,$00,$09
  DEFB $01,$00,$06
  DEFB $FF
Loc06TrollsPath:
  DEFB $84,$FF
  DEFB $D4,$04
  DEFB $FD,$06
  DEFB $00,$00
  DEFW LB58C
  DEFB $02,$00,$05
  DEFB $01,$01,$07
  DEFB $FF
Loc07TrollsCave:
  DEFB $04,$FF
  DEFB $12,$01
  DEFB $FD,$06
  DEFB $00,$00
  DEFW LB59A
  DEFB $02,$01,$06
  DEFB $FF
Loc09Rivendell:
  DEFB $84,$FF
  DEFB $41,$85
  DEFB $00,$00
  DEFB $00,$00
  DEFW $0000
  DEFB $03,$00,$0A
  DEFB $04,$00,$05
  DEFB $FF
Loc0AMistyMountain:
  DEFB $86,$FF
  DEFB $4E,$04
  DEFB $40,$04
  DEFB $00,$00
  DEFW LB59F
Loc00None_1:
  DEFB $03,$00,$0B
  DEFB $01,$00,$44
  DEFB $04,$00,$09
  DEFB $02,$00,$49
  DEFB $FF
Loc0BNarrowPlace:
  DEFB $84,$FF
  DEFB $E6,$14
  DEFB $64,$04
  DEFB $00,$00
  DEFW LB5AC
  DEFB $03,$00,$0C
  DEFB $04,$00,$0A
  DEFB $01,$00,$0E
  DEFB $FF
Loc0CDangerousNarrowPath:
  DEFB $86,$FF
  DEFB $D4,$14
  DEFB $85,$01
  DEFB $64,$04
  DEFW LB5BE
  DEFB $03,$00,$16
  DEFB $04,$00,$0B
  DEFB $FF
Loc0ELargeDryCave:
  DEFB $04,$FF
  DEFB $12,$11
  DEFB $BF,$03
  DEFB $EC,$01
  DEFW MsgLargeDryCaveWhich
  DEFB $0A,$06,$0F
  DEFB $02,$00,$0B
  DEFB $FF
Loc0FDarkStuffyPassage:
  DEFB $04,$FF
  DEFB $CD,$04
  DEFB $8E,$01
  DEFB $6A,$06
  DEFW $0000
  DEFB $09,$06,$0E
  DEFB $02,$00,$34
  DEFB $05,$00,$3A
  DEFB $FF
Loc34DarkStuffyPassage:
  DEFB $04,$FF
  DEFB $CD,$04
  DEFB $8E,$01
  DEFB $6A,$06
  DEFW $0000
  DEFB $01,$00,$0F
  DEFB $0A,$00,$35
  DEFB $09,$00,$36
  DEFB $FF
Loc35DarkStuffyPassage:
  DEFB $04,$FF
  DEFB $CD,$04
  DEFB $8E,$01
  DEFB $6A,$06
  DEFW $0000
  DEFB $09,$00,$34
  DEFB $FF
Loc36DarkStuffyPassage:
  DEFB $04,$FF
  DEFB $CD,$04
  DEFB $8E,$01
  DEFB $6A,$06
  DEFW $0000
  DEFB $0A,$00,$34
  DEFB $07,$00,$37
  DEFB $02,$00,$40
  DEFB $08,$00,$11
  DEFB $FF
Loc37DarkStuffyPassage:
  DEFB $04,$FF
  DEFB $CD,$04
  DEFB $8E,$01
  DEFB $6A,$06
  DEFW $0000
  DEFB $02,$00,$11
  DEFB $05,$00,$36
  DEFB $08,$00,$3D
  DEFB $04,$00,$3C
  DEFB $FF
Loc38DarkStuffyPassage:
  DEFB $04,$FF
  DEFB $CD,$04
  DEFB $8E,$01
  DEFB $6A,$06
  DEFW $0000
  DEFB $08,$00,$3C
  DEFB $FF
Loc39DarkStuffyPassage:
  DEFB $04,$FF
  DEFB $CD,$04
  DEFB $8E,$01
  DEFB $6A,$06
  DEFW $0000
  DEFB $09,$00,$10
  DEFB $04,$00,$41
  DEFB $01,$00,$3A
  DEFB $FF
Loc3ADarkStuffyPassage:
  DEFB $04,$FF
  DEFB $CD,$04
  DEFB $8E,$01
  DEFB $6A,$06
  DEFW $0000
  DEFB $07,$00,$3E
  DEFB $03,$00,$0F
  DEFB $02,$00,$39
  DEFB $09,$00,$3B
  DEFB $FF
Loc3BDarkStuffyPassage:
  DEFB $04,$FF
  DEFB $CD,$04
  DEFB $8E,$01
  DEFB $6A,$06
  DEFW $0000
  DEFB $0A,$00,$3A
  DEFB $02,$00,$3C
  DEFB $FF
Loc3CDarkStuffyPassage:
  DEFB $04,$FF
  DEFB $CD,$04
  DEFB $8E,$01
  DEFB $6A,$06
  DEFW $0000
  DEFB $07,$00,$3D
  DEFB $01,$00,$3B
  DEFB $06,$00,$38
  DEFB $FF
Loc3DDarkStuffyPassage:
  DEFB $04,$FF
  DEFB $CD,$04
  DEFB $8E,$01
  DEFB $6A,$06
  DEFW $0000
  DEFB $01,$00,$36
  DEFB $06,$00,$3C
  DEFB $FF
Loc3EDarkStuffyPassage:
  DEFB $04,$FF
  DEFB $CD,$04
  DEFB $8E,$01
  DEFB $6A,$06
  DEFW $0000
  DEFB $03,$00,$3D
  DEFB $FF
Loc3FDarkStuffyPassage:
  DEFB $04,$FF
  DEFB $CD,$04
  DEFB $8E,$01
  DEFB $6A,$06
  DEFW $0000
  DEFB $09,$00,$40
  DEFB $01,$00,$12
  DEFB $03,$00,$3A
  DEFB $FF
Loc40DarkStuffyPassage:
  DEFB $04,$FF
  DEFB $CD,$04
  DEFB $8E,$01
  DEFB $6A,$06
  DEFW $0000
  DEFB $06,$00,$41
  DEFB $04,$00,$36
  DEFB $08,$00,$3F
  DEFB $FF
Loc41DarkStuffyPassage:
  DEFB $04,$FF
  DEFB $CD,$04
  DEFB $8E,$01
  DEFB $6A,$06
  DEFW $0000
  DEFB $01,$00,$40
  DEFB $07,$00,$39
  DEFB $03,$00,$13
  DEFB $FF
Loc10BigGoblinsCavern:
  DEFB $04,$FF
  DEFB $16,$01
  DEFB $A2,$00
  DEFB $E8,$02
  DEFW LB5D3
  DEFB $0A,$00,$39
  DEFB $05,$00,$12
  DEFB $07,$11,$0D
  DEFB $FF
Loc11DeepDarkLake:
  DEFB $08,$FF
  DEFB $B7,$03
  DEFB $96,$01
  DEFB $8E,$01
  DEFW MsgBrinkDeepDarkUnder
  DEFB $01,$00,$37
  DEFB $FF
Loc12DarkWindingPassage:
  DEFB $04,$FF
  DEFB $CD,$04
  DEFB $8E,$01
  DEFB $85,$07
  DEFW $0000
  DEFB $08,$00,$10
  DEFB $07,$00,$3F
  DEFB $01,$1B,$0D
  DEFB $FF
Loc13InsideGoblinsGate:
  DEFB $02,$FF
  DEFB $C4,$82
  DEFB $7B,$03
  DEFB $E8,$02
  DEFW LB5F3
  DEFB $04,$00,$10
  DEFB $01,$00,$10
  DEFB $02,$00,$10
  DEFB $09,$0A,$14
  DEFB $03,$00,$10
  DEFB $07,$00,$10
  DEFB $08,$00,$10
  DEFB $0A,$00,$10
  DEFB $05,$00,$41
  DEFB $06,$00,$10
  DEFB $FF
Loc14OutsideGoblinsGate:
  DEFB $80,$FF
  DEFB $C4,$82
  DEFB $C2,$04
  DEFB $E8,$02
  DEFW LB5F3
  DEFB $0A,$0A,$13
  DEFB $03,$00,$15
  DEFB $FF
Loc0DGoblinsDungeon:
  DEFB $04,$FF
  DEFB $EF,$01
  DEFB $E8,$02
  DEFB $00,$00
  DEFW $0000
  DEFB $01,$11,$10
  DEFB $04,$1B,$12
  DEFB $FF
Loc15TreelessOpening:
  DEFB $84,$FF
  DEFB $B8,$04
  DEFB $F0,$06
  DEFB $00,$00
  DEFW $0000
  DEFB $03,$00,$16
Loc00None_2:
  DEFB $04,$00,$14
  DEFB $FF
Loc16BeornsHouse:
  DEFB $84,$FF
  DEFB $69,$83
  DEFB $93,$00
  DEFB $00,$00
  DEFW $0000
  DEFB $05,$00,$18
  DEFB $06,$00,$14
  DEFB $02,$00,$2E
  DEFB $08,$00,$0C
Loc00None_3:
  DEFB $01,$00,$31
  DEFB $FF
Loc18ForestGate:
  DEFB $88,$FF
  DEFB $C4,$02
  DEFB $A0,$02
  DEFB $00,$00
  DEFW LB5F8
  DEFB $04,$00,$16
  DEFB $02,$00,$2E
Loc00None_4:
  DEFB $03,$00,$19
  DEFB $FF
Loc19BewitchedGloomyPlac:
  DEFB $84,$FF
  DEFB $E6,$04
  DEFB $99,$00
  DEFB $D8,$02
  DEFW $0000
  DEFB $04,$00,$18
  DEFB $03,$00,$42
  DEFB $02,$09,$00
  DEFB $FF
Loc1ASpiderThreadsPlace:
  DEFB $84,$FF
  DEFB $E6,$04
  DEFB $23,$06
  DEFB $BA,$06
  DEFW LB60F
  DEFB $03,$07,$1D
  DEFB $04,$07,$32
  DEFB $01,$07,$1C
  DEFB $02,$07,$1B
  DEFB $FF
Loc1BSmotheringForest:
  DEFB $84,$FF
  DEFB $A0,$02
  DEFB $F3,$05
  DEFB $00,$00
  DEFW LB619
  DEFB $01,$07,$1A
  DEFB $04,$07,$32
  DEFB $FF
Loc1CLevelledElvishClear:
  DEFB $84,$FF
  DEFB $27,$11
  DEFB $CC,$03
  DEFB $22,$02
  DEFW LB624
  DEFB $04,$00,$19
  DEFB $03,$07,$1A
  DEFB $05,$0D,$1E
  DEFB $FF
Loc1DDeepBog:
  DEFB $84,$FF
  DEFB $BC,$00
  DEFB $96,$01
  DEFB $00,$00
  DEFW $0000
  DEFB $04,$07,$1A
  DEFB $FF
Loc1EElvenkingsGreatHall:
  DEFB $04,$FF
  DEFB $0D,$03
  DEFB $13,$02
  DEFB $FF,$02
  DEFW $0000
  DEFB $03,$08,$1F
  DEFB $02,$00,$20
  DEFB $04,$0D,$1C
  DEFB $FF
Loc1FDarkDungeon:
  DEFB $04,$FF
  DEFB $EF,$11
  DEFB $8E,$01
  DEFB $00,$00
  DEFW LB632
  DEFB $08,$08,$20
  DEFB $04,$08,$1E
  DEFB $FF
Loc20ElvenkingsCellar:
  DEFB $04,$FF
  DEFB $1C,$01
  DEFB $13,$02
  DEFB $00,$00
  DEFW LB63D
  DEFB $05,$08,$1F
  DEFB $01,$00,$1E
  DEFB $0A,$0C,$21
  DEFB $FF
Loc21Forestriver:
  DEFB $88,$FF
  DEFB $A6,$82
  DEFB $00,$00
  DEFB $00,$00
  DEFW $0000
  DEFB $03,$27,$22
  DEFB $09,$0C,$00
  DEFB $02,$2A,$00
  DEFB $FF
Loc22LongLake:
  DEFB $88,$FF
  DEFB $B7,$83
  DEFB $0F,$04
  DEFB $00,$00
  DEFW $0000
  DEFB $01,$00,$24
Loc00None_5:
  DEFB $03,$00,$23
  DEFB $06,$27,$21
  DEFB $02,$00,$2D
  DEFB $FF
Loc23LakeTown:
  DEFB $84,$FF
  DEFB $DC,$86
  DEFB $B7,$03
  DEFB $00,$00
  DEFW LB64F
  DEFB $01,$00,$22
  DEFB $02,$00,$22
  DEFB $03,$00,$22
  DEFB $04,$00,$22
  DEFB $FF
Loc24RunningRiver:
  DEFB $86,$FF
  DEFB $4A,$85
  DEFB $70,$05
  DEFB $00,$00
  DEFW LB65D
  DEFB $09,$00,$25
  DEFB $02,$00,$22
  DEFB $FF
Loc25DragonsDesolation:
  DEFB $84,$FF
  DEFB $9F,$01
  DEFB $CE,$01
  DEFB $00,$00
  DEFW LB671
  DEFB $01,$00,$26
  DEFB $0A,$00,$24
  DEFB $FF
Loc26DaleValley:
  DEFB $84,$FF
  DEFB $2F,$87
  DEFB $81,$01
  DEFB $00,$00
  DEFW LB680
  DEFB $01,$00,$27
  DEFB $02,$00,$25
  DEFB $06,$00,$28
  DEFB $FF
Loc27FrontGate:
  DEFB $88,$FF
  DEFB $C4,$02
  DEFB $40,$09
  DEFB $00,$00
  DEFW LB68A
  DEFB $01,$00,$29
  DEFB $02,$00,$26
  DEFB $04,$00,$28
  DEFB $FF
Loc28Ravenhill:
  DEFB $86,$FF
  DEFB $21,$85
  DEFB $00,$00
  DEFB $00,$00
  DEFW LB695
  DEFB $01,$00,$2A
  DEFB $07,$00,$25
  DEFB $03,$00,$27
  DEFB $FF
Loc29LowerHalls:
  DEFB $84,$FF
  DEFB $0D,$83
  DEFB $1A,$04
  DEFB $00,$00
  DEFW LB69D
  DEFB $02,$00,$27
  DEFB $03,$00,$2B
  DEFB $09,$00,$2C
  DEFB $FF
Loc2ASidedoor:
  DEFB $84,$FF
  DEFB $AA,$05
  DEFB $00,$00
  DEFB $00,$00
  DEFW LB6A7
  DEFB $02,$00,$28
  DEFB $03,$0B,$2B
  DEFB $01,$00,$33
  DEFB $FF
Loc2BSmoothStraightPassa:
  DEFB $04,$B0
  DEFB $CD,$14
  DEFB $ED,$05
  DEFB $46,$06
  DEFW LB6BE
  DEFB $04,$0B,$2A
  DEFB $03,$00,$29
  DEFB $FF
Loc2CLonelyMountain:
  DEFB $86,$FF
  DEFB $4E,$84
  DEFB $09,$04
  DEFB $00,$00
  DEFW LB6C5
  DEFB $0A,$00,$29
  DEFB $04,$00,$2A
  DEFB $02,$00,$27
  DEFB $08,$00,$28
  DEFB $FF
Loc2EForestRoad:
  DEFB $86,$FF
  DEFB $4F,$05
  DEFB $A0,$02
  DEFB $00,$00
  DEFW $0000
  DEFB $03,$00,$02
  DEFB $01,$00,$18
  DEFB $FF
Loc2DWaterfall:
  DEFB $88,$FF
  DEFB $63,$07
  DEFB $00,$00
  DEFB $00,$00
  DEFW $0000
  DEFB $02,$00,$08
  DEFB $04,$00,$03
  DEFB $FF
Loc02ForestRoad:
  DEFB $86,$FF
  DEFB $4F,$05
  DEFB $A0,$02
  DEFB $00,$00
  DEFW $0000
  DEFB $03,$00,$03
  DEFB $04,$00,$2E
  DEFB $FF
Loc03Forest:
  DEFB $84,$FF
  DEFB $A0,$02
  DEFB $00,$00
  DEFB $00,$00
  DEFW $0000
  DEFB $04,$00,$02
  DEFB $03,$00,$2D
  DEFB $FF
Loc08RunningRiver:
  DEFB $88,$FF
  DEFB $4A,$05
  DEFB $70,$05
  DEFB $00,$00
  DEFW $0000
  DEFB $01,$00,$2D
  DEFB $04,$00,$03
  DEFB $FF
Loc17Forestriver:
  DEFB $88,$FF
  DEFB $A6,$82
  DEFB $00,$00
  DEFB $00,$00
  DEFW $0000
  DEFB $07,$2A,$21
  DEFB $01,$00,$30
  DEFB $FF
Loc30Mountains:
  DEFB $86,$FF
  DEFB $56,$04
  DEFB $00,$00
  DEFB $00,$00
  DEFW $0000
  DEFB $08,$00,$31
  DEFB $03,$00,$2F
  DEFB $07,$00,$17
  DEFB $FF
Loc31GreatRiver:
  DEFB $88,$FF
  DEFB $4A,$05
  DEFB $FF,$02
  DEFB $00,$00
  DEFW $0000
  DEFB $05,$00,$30
  DEFB $02,$00,$16
  DEFB $03,$00,$18
  DEFB $08,$00,$0A
  DEFB $FF
Loc2FEmPlace:
  DEFB $84,$FE
  DEFB $E6,$04
  DEFB $28,$02
  DEFB $00,$00
  DEFW $0000
  DEFB $FF
Loc32GreenForest:
  DEFB $84,$FF
  DEFB $A0,$02
  DEFB $04,$03
  DEFB $00,$00
  DEFW $0000
  DEFB $05,$07,$1A
  DEFB $04,$00,$43
  DEFB $FF
Loc33EmPlace:
  DEFB $84,$FF
  DEFB $E6,$04
  DEFB $28,$02
  DEFB $00,$00
  DEFW $0000
  DEFB $01,$00,$2F
  DEFB $02,$00,$2A
  DEFB $09,$00,$2C
  DEFB $FF
Loc42WestBank:
  DEFB $86,$FF
  DEFB $1E,$08
  DEFB $79,$07
  DEFB $00,$00
  DEFW LB6CA
  DEFB $04,$00,$19
  DEFB $03,$09,$43
  DEFB $FF
Loc43EastBank:
  DEFB $86,$FF
  DEFB $1E,$08
  DEFB $FE,$01
  DEFB $00,$00
  DEFW LB6CA_0
  DEFB $03,$00,$32
  DEFB $04,$09,$42
  DEFB $FF
Loc44NarrowPath:
  DEFB $86,$FF
  DEFB $D4,$14
  DEFB $64,$04
  DEFB $00,$00
  DEFW $0000
  DEFB $03,$00,$47
  DEFB $05,$00,$45
  DEFB $02,$00,$0A
  DEFB $FF
Loc45NarrowPath:
  DEFB $86,$FF
  DEFB $D4,$14
  DEFB $64,$04
  DEFB $00,$00
  DEFW $0000
  DEFB $01,$00,$46
  DEFB $08,$00,$44
  DEFB $02,$00,$0A
  DEFB $FF
Loc46NarrowPath:
  DEFB $86,$FF
  DEFB $D4,$14
  DEFB $64,$04
  DEFB $00,$00
  DEFW $0000
  DEFB $07,$00,$48
  DEFB $02,$00,$45
  DEFB $FF
Loc47NarrowPath:
  DEFB $86,$FF
  DEFB $D4,$14
  DEFB $64,$04
  DEFB $00,$00
  DEFW $0000
  DEFB $06,$00,$45
  DEFB $02,$00,$4A
  DEFB $04,$00,$44
  DEFB $FF
Loc48NarrowPath:
  DEFB $86,$FF
  DEFB $D4,$14
  DEFB $64,$04
  DEFB $00,$00
  DEFW $0000
  DEFB $06,$00,$46
  DEFB $08,$00,$47
  DEFB $0A,$00,$4B
  DEFB $FF
Loc49NarrowPath:
  DEFB $86,$FF
  DEFB $D4,$14
  DEFB $64,$04
  DEFB $00,$00
  DEFW $0000
  DEFB $03,$00,$4A
  DEFB $01,$00,$0A
  DEFB $FF
Loc4ANarrowPath:
  DEFB $86,$FF
  DEFB $D4,$14
  DEFB $64,$04
  DEFB $00,$00
  DEFW $0000
  DEFB $01,$00,$47
  DEFB $04,$00,$49
  DEFB $FF
Loc4BSteepPath:
  DEFB $86,$FF
  DEFB $D4,$14
  DEFB $3C,$06
  DEFB $00,$00
  DEFW $0000
  DEFB $0A,$00,$4C
  DEFB $FF
Loc4CSteepPath:
  DEFB $86,$FF
  DEFB $D4,$14
  DEFB $3C,$06
  DEFB $00,$00
  DEFW $0000
  DEFB $0A,$00,$4D
  DEFB $FF
Loc4DSteepPath:
  DEFB $86,$FF
  DEFB $D4,$14
  DEFB $3C,$06
  DEFB $00,$00
  DEFW $0000
  DEFB $0A,$00,$4E
  DEFB $FF
Loc4EDeepMistyValley:
  DEFB $84,$FF
  DEFB $2F,$17
  DEFB $96,$01
  DEFB $40,$04
  DEFW $0000
  DEFB $03,$00,$4F
  DEFB $09,$00,$4D
  DEFB $FF
Loc4FDeepMistyValley:
  DEFB $84,$FF
  DEFB $2F,$17
  DEFB $96,$01
  DEFB $40,$04
  DEFW $0000
  DEFB $04,$00,$4E
  DEFB $09
ObjectTableBase:
  DEFB $00,$4A,$FF

; Object table: (id, address of record) for each object and character
;
; 3-byte records, id then the record address in $C11B; ends with $FF. Ids
; $00-$2B objects (0 = the player), $3C-$4C characters. Found by $9BCA; walked
; by $9BA9 / $9B93 starting from $C060 (the routines add 3 first).
ObjectTable:
  DEFB $00
  DEFW Chr00Player
  DEFB $01
  DEFW Obj01HeavyRockDoor
  DEFB $02
  DEFW Obj02SmallCuriousKey
  DEFB $03
  DEFW Obj03CuriousMap
  DEFB $04
  DEFW Obj04LargeKey
  DEFB $05
  DEFW Obj05RoundGreenDoor
  DEFB $06
  DEFW Obj06SmallInsignificantC
  DEFB $07
  DEFW Obj07SpiderWeb
  DEFB $08
  DEFW Obj08RedDoor
  DEFB $09
  DEFW Obj09FastBlackRiver
  DEFB $0A
  DEFW Obj0AGoblinsBackDoor
  DEFB $0B
  DEFW Obj0BMountainsSideDoor
  DEFB $0C
  DEFW Obj0CLargeTrapDoor
  DEFB $0D
  DEFW Obj0DMagicDoor
  DEFB $0E
  DEFW Obj0EShortStrongSword
  DEFB $0F
  DEFW Obj0FRedKey
  DEFB $10
  DEFW Obj10ValuableGoldenRing
  DEFB $11
  DEFW Obj11GoblinsDoor
  DEFB $12
  DEFW Obj12Rope
  DEFB $13
  DEFW Obj13Barrel
  DEFB $14
  DEFW Obj14Wine
  DEFB $15
  DEFW Obj15Water
  DEFB $16
  DEFW Obj16BlackWater
  DEFB $17
  DEFW Obj17Water
  DEFB $18
  DEFW Obj18BlackWater
  DEFB $19
  DEFW Obj19Bow
  DEFB $1A
  DEFW Obj1AStrongArrow
  DEFB $1B
  DEFW Obj1BWindow
  DEFB $1C
  DEFW Obj1CTo
  DEFB $1D
  DEFW Obj1DSand
  DEFB $1E
  DEFW Obj1ETrapDoor
  DEFB $1F
  DEFW Obj1FGoblinsCache
  DEFB $20
  DEFW Obj20HeavyCurtain
  DEFB $21
  DEFW Obj21LargeCupboard
  DEFB $22
  DEFW Obj22Food
  DEFB $23
  DEFW Obj23ValuableTreasure
  DEFB $24
  DEFW Obj24Wa
  DEFB $25
  DEFW Obj25WoodenChest
  DEFB $26
  DEFW Obj26Lunch
  DEFB $27
  DEFW Obj27StrongPortcullis
  DEFB $28
  DEFW Obj28Stone
  DEFB $29
  DEFW Obj29WoodenBoat
  DEFB $2A
  DEFW Obj2AFastRiver
  DEFB $2B
  DEFW Obj2BGoldenKey
  DEFB $3C
  DEFW Chr3CRedGoldenDragon
  DEFB $3D
  DEFW Chr3DNastyGoblin
  DEFB $3E
  DEFW Chr3EGandalf
  DEFB $3F
  DEFW Chr3FThorin
  DEFB $40
  DEFW Chr40WoodElf
  DEFB $41
  DEFW Chr41Elrond
  DEFB $42
  DEFW Chr42Butler
  DEFB $43
  DEFW Chr43ViciousWarg
  DEFB $44
  DEFW Chr44Gollum
  DEFB $45
  DEFW Chr45HideousGoblin
  DEFB $46
  DEFW Chr46Bard
  DEFB $47
  DEFW Chr47HideousTroll
  DEFB $48
  DEFW Chr48ViciousTroll
  DEFB $49
  DEFW Chr49HorribleGoblin
  DEFB $4A
  DEFW Chr4AMeanGoblin
  DEFB $4B
  DEFW Chr4BViciousGoblin
  DEFB $4C
  DEFW Chr4CDisgustingGoblin
  DEFB $FF

; Objects and characters: 61 variable-length records (1557 bytes, saved)
;
; Record, found through $C063: +0 N, number of location bytes at +$10; +1
; holder id ($FF: lying at the location); +2 weight (capacity as a container or
; character); +3 bulk (capacity); +4 state bits; +5 +6 strength values (used by
; combat); +7 flags: bit 7 present, bit 6 character, bit 5 alive/active, bit 3
; dead or disabled, bit 1 consumable; +8 +10 +12 three phrase codes (noun,
; adjectives; high bit set: proper name, $87A8 = you); +14 +15 spare.
;
; +$10..: N location ids where it is (1 for a movable thing and a character; 2
; or more for a door, river or web seen from several places); then a verb
; table: 3-byte records (verb id, handler address), id 0 chains to the next
; record, ends with $FF (searched by $9B81 with $9DBD).
;
; Moves of an object only change +1 and +$10 ($9C17 copies a holder location to
; what it carries).
Chr00Player:
  DEFB $01
Chr00PlayerHolder:
  DEFB $FF
  DEFB $10,$40,$10,$40,$40
Chr00PlayerFlags:
  DEFB $E0
  DEFB $A8,$87
  DEFB $00,$00
  DEFB $00,$00
  DEFW $0000
Chr00PlayerLocation:
  DEFB $01
  DEFB $1B
  DEFW L929C_0
  DEFB $00
  DEFW EndGame
  DEFB $FF
Chr3CRedGoldenDragon:
  DEFB $01,$FF
  DEFB $C0,$60,$00,$C0,$C0
Chr3CDragonFlags:
  DEFB $E0
Chr3CDragonName:
  DEFB $C8,$01
  DEFB $36,$05
  DEFB $F3,$02
  DEFW $0000
Chr3CDragonLocation:
  DEFB $29
  DEFB $FF
Obj05RoundGreenDoor:
  DEFB $02,$FF
  DEFB $FF,$FF,$00,$00,$10
  DEFB $80
  DEFB $C0,$01
  DEFB $5F,$05
  DEFB $04,$03
  DEFW $0000
  DEFB $01,$04
  DEFB $0B
  DEFW StrikeObject
  DEFB $0C
  DEFW CloseObject
  DEFB $10
  DEFW OpenObject
  DEFB $18
  DEFW VerbLookThrough
  DEFB $1E
  DEFW L8F3B
  DEFB $25
  DEFW PrintNoFit
  DEFB $26
  DEFW PrintNoFit
  DEFB $2C
  DEFW L9404_8
  DEFB $FF
Obj01HeavyRockDoor:
  DEFB $02,$FF
  DEFB $FF,$FF,$00,$00,$90
  DEFB $81
  DEFB $C0,$01
  DEFB $27,$03
  DEFB $53,$05
  DEFW $0000
  DEFB $07,$06
  DEFB $0B
  DEFW StrikeObject
  DEFB $0C
  DEFW CloseObject
  DEFB $10
  DEFW OpenObject
  DEFB $18
  DEFW VerbLookThrough
  DEFB $1E
  DEFW L8F3B
  DEFB $25
  DEFW LA244_14
  DEFB $26
  DEFW LA244_14
  DEFB $2C
  DEFW L9404_8
  DEFB $FF
Obj2BGoldenKey:
  DEFB $01,$FF
  DEFB $00,$00,$00,$00,$00
  DEFB $80
  DEFB $A5,$03
  DEFB $F3,$02
  DEFB $00,$00
  DEFW $0000
  DEFB $4F
  DEFB $FF
Obj02SmallCuriousKey:
  DEFB $01,$1F
  DEFB $00,$00,$00,$00,$00
  DEFB $80
  DEFB $A5,$03
  DEFB $E1,$05
  DEFB $63,$01
  DEFW $0000
  DEFB $0D
  DEFB $FF
Obj04LargeKey:
  DEFB $01,$47
  DEFB $01,$01,$00,$00,$00
  DEFB $80
  DEFB $A5,$03
  DEFB $BF,$03
  DEFB $00,$00
  DEFW $0000
  DEFB $05
  DEFB $FF
Obj03CuriousMap:
  DEFB $01,$3E
  DEFB $02,$00,$00,$00,$02
  DEFB $80
  DEFB $2C,$14
  DEFB $63,$01
  DEFB $00,$00
  DEFW LB552
  DEFB $01
  DEFB $1C
  DEFW ExamineMap
  DEFB $FF
Obj06SmallInsignificantC:
  DEFB $02,$FF
  DEFB $FF,$FF,$00,$FF,$00
  DEFB $80
  DEFB $51,$01
  DEFB $E1,$05
  DEFB $81,$03
  DEFW $0000
  DEFB $0E,$0F
  DEFB $10
  DEFW OpenCrack
  DEFB $0C
  DEFW CloseObject
  DEFB $1E
  DEFW L8F3B
  DEFB $18
  DEFW VerbLookThrough
  DEFB $FF
Obj07SpiderWeb:
  DEFB $05,$FF
  DEFB $A0,$50,$00,$40,$40
  DEFB $80
  DEFB $76,$07
Obj07WebOff0A:
  DEFB $23,$06
  DEFB $00,$00
  DEFW $0000
  DEFB $1A,$1C,$1B,$1D,$32
  DEFB $0B
  DEFW StrikeObject
  DEFB $00
  DEFW LA377
  DEFB $1E
  DEFW L8F3B
  DEFB $FF
Obj08RedDoor:
  DEFB $03,$FF
  DEFB $FF,$FF,$00,$00,$00
  DEFB $81
  DEFB $C0,$01
  DEFB $36,$05
  DEFB $00,$00
  DEFW $0000
  DEFB $1F,$1E,$20
  DEFB $10
  DEFW OpenObject
  DEFB $0C
  DEFW CloseObject
  DEFB $18
  DEFW VerbLookThrough
  DEFB $1E
  DEFW L8F3B
  DEFB $25
  DEFW LA244_13
  DEFB $26
  DEFW LA244_13
  DEFB $2C
  DEFW L9404_8
  DEFB $FF
Obj09FastBlackRiver:
  DEFB $03,$FF
  DEFB $FF,$FF,$00,$00,$00
  DEFB $86
  DEFB $4A,$05
  DEFB $53,$02
  DEFB $A5,$00
  DEFW LB563
  DEFB $42,$43,$19
  DEFB $11
  DEFW L9404_1
  DEFB $0E
  DEFW L9404_1
  DEFB $19
  DEFW VerbLookThrough_0
  DEFB $32
  DEFW LA244_9
  DEFB $FF
Obj2AFastRiver:
  DEFB $03,$FF
  DEFB $FF,$FF,$00,$00,$00
  DEFB $86
  DEFB $4A,$05
  DEFB $53,$02
  DEFB $00,$00
  DEFW $0000
  DEFB $17,$21,$22
  DEFB $11
  DEFW L9404_1
  DEFB $0E
  DEFW L9404_1
  DEFB $19
  DEFW VerbLookThrough_0
  DEFB $32
  DEFW LA244_6
  DEFB $FF
Obj0AGoblinsBackDoor:
  DEFB $02,$FF
  DEFB $40,$FF,$00,$50,$50
  DEFB $80
  DEFB $C0,$01
  DEFB $E8,$02
  DEFB $7C,$00
  DEFW $0000
  DEFB $13,$14
  DEFB $10
  DEFW OpenObject
  DEFB $0C
  DEFW CloseObject
  DEFB $0B
  DEFW StrikeObject
  DEFB $18
  DEFW VerbLookThrough
  DEFB $1E
  DEFW L8F3B
  DEFB $2C
  DEFW L9404_8
  DEFB $0B
  DEFW StrikeObject
  DEFB $FF
Obj0BMountainsSideDoor:
  DEFB $02,$FF
  DEFB $FF,$FF,$00,$00,$00
Obj0BDoorFlags:
  DEFB $01
  DEFB $C0,$01
  DEFB $56,$04
  DEFB $A6,$05
  DEFW $0000
  DEFB $2A,$2B
  DEFB $0C
  DEFW CloseObject
  DEFB $00
  DEFW LA9E5_6
  DEFB $26
  DEFW LA244_12
  DEFB $00
  DEFW LA35E
  DEFB $1E
  DEFW L8F3B
  DEFB $18
  DEFW VerbLookThrough
  DEFB $2C
  DEFW L9404_8
  DEFB $FF
Obj0CLargeTrapDoor:
  DEFB $02,$FF
  DEFB $FF,$FF,$00,$00,$30
  DEFB $80
  DEFB $C0,$01
  DEFB $BF,$03
  DEFB $E0,$06
  DEFW $0000
  DEFB $20,$21
  DEFB $10
  DEFW LA67E
  DEFB $0C
  DEFW LA67E
  DEFB $0B
  DEFW StrikeObject
  DEFB $18
  DEFW VerbLookThrough
  DEFB $1E
  DEFW L8F3B
  DEFB $2C
  DEFW L9404_8
  DEFB $00
  DEFW LA5E2
  DEFB $FF
Obj0EShortStrongSword:
  DEFB $01,$FF
  DEFB $03,$04,$00,$40,$80
Obj0ESwordFlags:
  DEFB $94
  DEFB $80,$06
  DEFB $99,$05
  DEFB $64,$06
  DEFW $0000
  DEFB $07
  DEFB $0B
  DEFW StrikeObject
  DEFB $FF
Obj10ValuableGoldenRing:
  DEFB $01,$FF
  DEFB $00,$00,$00,$FF,$00
  DEFB $80
  DEFB $3D,$05
  DEFB $35,$07
  DEFB $F3,$02
  DEFW $0000
  DEFB $3D
  DEFB $28
  DEFW LA377_0
  DEFB $16
  DEFW LA377_1
  DEFB $FF
Obj0FRedKey:
  DEFB $01,$42
  DEFB $02,$02,$00,$02,$02
  DEFB $80
  DEFB $A5,$03
  DEFB $36,$05
  DEFB $00,$00
  DEFW $0000
  DEFB $20
  DEFB $FF
Obj11GoblinsDoor:
  DEFB $02,$FF
  DEFB $FF,$FF,$00,$FF,$FF
Obj11DoorFlags:
  DEFB $80
  DEFB $C0,$01
  DEFB $E8,$02
  DEFB $00,$00
  DEFW $0000
  DEFB $10,$0D
  DEFB $10
  DEFW LA4C0
  DEFB $0C
  DEFW CloseObject
  DEFB $1E
  DEFW L8F3B
  DEFB $18
  DEFW VerbLookThrough
  DEFB $2C
  DEFW L9404_8
  DEFB $FF
Obj12Rope:
  DEFB $01
Obj12RopeHolder:
  DEFB $FF
  DEFB $02,$02,$04,$20,$05
  DEFB $A0
  DEFB $5B,$05
  DEFB $00,$00
  DEFB $00,$00
  DEFW $0000
  DEFB $07
  DEFB $2B
  DEFW LA814
  DEFB $2E
  DEFW LA244_0
  DEFB $31
  DEFW LA814_4
  DEFB $FF
Obj0DMagicDoor:
  DEFB $02,$FF
  DEFB $FF,$FF,$00,$FF,$FF
Obj0DDoorFlags:
  DEFB $80
  DEFB $C0,$01
  DEFB $24,$04
  DEFB $00,$00
  DEFW $0000
  DEFB $1E,$1C
  DEFB $1E
  DEFW L8F3B
  DEFB $18
  DEFW VerbLookThrough
  DEFB $2C
  DEFW L9404_8
  DEFB $1C
  DEFW LA67E_6
  DEFB $FF
Chr3EGandalf:
  DEFB $01,$FF
  DEFB $15,$60,$10,$70,$88
  DEFB $E0
  DEFB $BD,$82
  DEFB $00,$00
  DEFB $00,$00
  DEFW $0000
  DEFB $01
  DEFB $FF
Chr3FThorin:
  DEFB $01,$FF
  DEFB $1D,$50,$10,$68,$78
Chr3FThorinFlags:
  DEFB $E0
  DEFB $B4,$86
  DEFB $00,$00
  DEFB $00,$00
  DEFW $0000
  DEFB $01
  DEFB $0F
  DEFW VerbAttack
  DEFB $00
  DEFW ThorinDeathBreaksKey
  DEFB $FF
Chr40WoodElf:
  DEFB $01,$FF
  DEFB $70,$FF,$40,$40,$30
  DEFB $E0
  DEFB $0A,$02
  DEFB $9E,$07
  DEFB $00,$00
  DEFW $0000
  DEFB $1C
  DEFB $FF
Chr41Elrond:
  DEFB $01,$FF
  DEFB $20,$30,$50,$40,$40
  DEFB $E0
  DEFB $0D,$82
  DEFB $00,$00
  DEFB $00,$00
  DEFW $0000
  DEFB $09
  DEFB $FF
Obj13Barrel:
  DEFB $01,$FF
  DEFB $20,$03,$00,$20,$20
  DEFB $84
  DEFB $84,$10
  DEFB $00,$00
  DEFB $00,$00
  DEFW $0000
Obj13BarrelLocation:
  DEFB $20
  DEFB $10
  DEFW OpenObject
  DEFB $0C
  DEFW CloseObject
  DEFB $11
  DEFW PutObjectIn
  DEFB $23
  DEFW L8F69
  DEFB $22
  DEFW L9404
  DEFB $38
  DEFW LA9E5_1
  DEFB $36
  DEFW LA536_1
  DEFB $0B
  DEFW StrikeObject
  DEFB $FF
Obj14Wine:
  DEFB $01,$13
  DEFB $1F,$05,$00,$00,$00
  DEFB $82
  DEFB $92,$37
  DEFB $00,$00
  DEFB $00,$00
  DEFW $0000
  DEFB $20
  DEFB $21
  DEFW L929C
  DEFB $00
  DEFW LA9E5_11
  DEFB $FF
Chr42Butler:
  DEFB $01,$FF
  DEFB $30,$30,$40,$20,$70
Chr42ButlerFlags:
  DEFB $60
  DEFB $DC,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFW $0000
  DEFB $20
  DEFB $FF
Chr43ViciousWarg:
  DEFB $01,$FF
  DEFB $30,$30,$00,$37,$37
  DEFB $E0
  DEFB $9A,$07
  DEFB $41,$07
  DEFB $00,$00
  DEFW $0000
Chr43WargLocation:
  DEFB $15
  DEFB $FF
Obj15Water:
  DEFB $01,$FF
  DEFB $1F,$05,$00,$00,$00
  DEFB $82
  DEFB $5E,$37
  DEFB $00,$00
  DEFB $00,$00
  DEFW $0000
  DEFB $00
  DEFB $21
  DEFW L929C
  DEFB $FF
Obj16BlackWater:
  DEFB $01,$FF
  DEFB $1F,$05,$00,$00,$00
  DEFB $82
  DEFB $5E,$07
  DEFB $A5,$00
  DEFB $00,$00
  DEFW $0000
  DEFB $00
  DEFB $21
  DEFW LA244_11
  DEFB $FF
Obj17Water:
  DEFB $08,$FF
  DEFB $00,$05,$00,$00,$00
  DEFB $82
  DEFB $5E,$07
  DEFB $00,$00
  DEFB $00,$00
  DEFW $0000
  DEFB $08,$21,$22,$24,$31,$2D,$11,$17
  DEFB $21
  DEFW LA244
  DEFB $FF
Obj18BlackWater:
  DEFB $03,$FF
  DEFB $1F,$05,$00,$00,$00
  DEFB $82
  DEFB $5E,$07
  DEFB $A5,$00
  DEFB $00,$00
  DEFW $0000
  DEFB $19,$42,$43
  DEFB $21
  DEFW LA244_11
  DEFB $FF
Chr44Gollum:
  DEFB $01,$FF
  DEFB $05,$05,$20,$20,$40
  DEFB $E0
  DEFB $F9,$82
  DEFB $00,$00
  DEFB $00,$00
  DEFW $0000
Chr44GollumLocation:
  DEFB $11
  DEFB $FF
Chr46Bard:
  DEFB $01,$FF
  DEFB $30,$10,$10,$60,$60
Chr46BardFlags:
  DEFB $E0
  DEFB $80,$80
  DEFB $00,$00
  DEFB $00,$00
  DEFW $0000
  DEFB $23
  DEFB $FF
Obj19Bow:
  DEFB $01,$46
  DEFB $05,$03,$00,$10,$10
  DEFB $80
  DEFB $C3,$10
  DEFB $00,$00
  DEFB $00,$00
  DEFW $0000
  DEFB $23
  DEFB $0B
  DEFW StrikeObject
  DEFB $FF
Obj1AStrongArrow:
  DEFB $01,$46
  DEFB $02,$01,$00,$10,$10
  DEFB $80
  DEFB $6B,$10
  DEFB $64,$06
  DEFB $00,$00
  DEFW $0000
  DEFB $23
  DEFB $0B
  DEFW StrikeObject
  DEFB $FF
Obj1BWindow:
  DEFB $02,$FF
  DEFB $60,$FF,$80,$70,$70
  DEFB $80
  DEFB $8C,$07
  DEFB $00,$00
  DEFB $00,$00
  DEFW $0000
  DEFB $0D,$12
  DEFB $1E
  DEFW LA761_1
  DEFB $0B
  DEFW LA761_1
  DEFB $10
  DEFW LA761
  DEFB $0C
  DEFW LA761
  DEFB $18
  DEFW LA761_1
  DEFB $FF
Obj1CTo:
  DEFB $02,$FF
  DEFB $05,$05,$00,$80,$80
  DEFB $94
  DEFB $D7,$16
  DEFB $00,$00
  DEFB $00,$00
  DEFW $0000
  DEFB $10,$1E
  DEFB $FF
Obj1DSand:
  DEFB $01,$FF
  DEFB $65,$65,$00,$00,$00
  DEFB $80
  DEFB $7C,$35
  DEFB $00,$00
  DEFB $00,$00
  DEFW $0000
  DEFB $0D
  DEFB $39
  DEFW L9065
  DEFB $11
  DEFW PutObjectIn
  DEFB $FF
Obj1ETrapDoor:
  DEFB $01,$1D
  DEFB $FF,$FF,$03,$80,$80
  DEFB $81
  DEFB $C0,$01
  DEFB $E0,$06
  DEFB $00,$00
  DEFW $0000
  DEFB $0D
  DEFB $0B
  DEFW StrikeObject
  DEFB $26
  DEFW PrintNoFit
  DEFB $10
  DEFW OpenObject
  DEFB $FF
Obj1FGoblinsCache:
  DEFB $01,$1E
  DEFB $FF,$FF,$00,$00,$00
  DEFB $A0
  DEFB $E2,$00
  DEFB $E8,$02
  DEFB $00,$00
  DEFW $0000
  DEFB $0D
  DEFB $11
  DEFW PutObjectIn
  DEFB $14
  DEFW L8CE0
  DEFB $FF
Obj20HeavyCurtain:
  DEFB $01,$FF
  DEFB $FF,$FF,$02,$00,$00
  DEFB $80
  DEFB $6A,$11
  DEFB $27,$03
  DEFB $00,$00
  DEFW $0000
  DEFB $16
  DEFB $10
  DEFW OpenObject
  DEFB $0C
  DEFW CloseObject
  DEFB $FF
Obj21LargeCupboard:
  DEFB $01,$24
  DEFB $FF,$FF,$00,$00,$00
  DEFB $80
  DEFB $5B,$11
  DEFB $BF,$03
  DEFB $00,$00
  DEFW $0000
  DEFB $16
  DEFB $10
  DEFW OpenObject
  DEFB $0C
  DEFW CloseObject
  DEFB $11
  DEFW PutObjectIn
  DEFB $14
  DEFW L8CE0
  DEFB $0B
  DEFW StrikeObject
  DEFB $FF
Obj22Food:
  DEFB $01,$21
  DEFB $05,$05,$00,$01,$00
  DEFB $80
  DEFB $8B,$32
  DEFB $00,$00
  DEFB $00,$00
  DEFW $0000
  DEFB $16
  DEFB $1B
  DEFW L929C_0
  DEFB $FF
Obj23ValuableTreasure:
  DEFB $01
Obj23TreasureHolder:
  DEFB $FF
  DEFB $20,$20,$00,$05,$05
  DEFB $80
  DEFB $E4,$06
  DEFB $35,$07
  DEFB $00,$00
  DEFW $0000
Obj23TreasureLocation:
  DEFB $29
  DEFB $FF
Obj24Wa:
  DEFB $01,$20
  DEFB $FF,$FF,$00,$00,$00
  DEFB $A0
  DEFB $5A,$17
  DEFB $00,$00
  DEFB $00,$00
  DEFW $0000
  DEFB $16
  DEFB $11
  DEFW $0000
  DEFB $FF
Obj25WoodenChest:
  DEFB $01,$FF
  DEFB $40,$FF,$00,$00,$00
  DEFB $80
  DEFB $22,$01
  DEFB $A2,$07
  DEFB $00,$00
  DEFW $0000
  DEFB $01
  DEFB $10
  DEFW OpenObject
  DEFB $0C
  DEFW CloseObject
  DEFB $11
  DEFW PutObjectIn
  DEFB $0E
  DEFW PutObjectIn
  DEFB $14
  DEFW L8CE0
  DEFB $0B
  DEFW StrikeObject
  DEFB $36
  DEFW LA536_1
  DEFB $FF
Obj29WoodenBoat:
  DEFB $01
Obj29BoatHolder:
  DEFB $FF
  DEFB $40,$FF,$00,$00,$00
  DEFB $A0
  DEFB $B8,$00
  DEFB $A2,$07
  DEFB $00,$00
  DEFW $0000
Obj29BoatLocation:
  DEFB $43
  DEFB $11
  DEFW PutObjectIn
  DEFB $0E
  DEFW PutObjectIn
  DEFB $14
  DEFW L8CE0
  DEFB $0B
  DEFW StrikeObject
  DEFB $36
  DEFW LA536_1
  DEFB $00
  DEFW LA814_7
  DEFB $FF
Chr47HideousTroll:
  DEFB $01,$FF
  DEFB $90,$90,$00,$A0,$A0
Chr47TrollFlags:
  DEFB $E0
  DEFB $F8,$06
  DEFB $37,$03
  DEFB $00,$00
  DEFW $0000
  DEFB $05
  DEFB $FF
Chr48ViciousTroll:
  DEFB $01,$FF
  DEFB $90,$90,$00,$A0,$A0
Chr48TrollFlags:
  DEFB $E0
  DEFB $F8,$06
  DEFB $41,$07
  DEFB $00,$00
  DEFW $0000
  DEFB $05
  DEFB $FF
Obj26Lunch:
  DEFB $01,$FF
  DEFB $05,$05,$00,$01,$00
  DEFB $80
  DEFB $1F,$34
  DEFB $00,$00
  DEFB $00,$00
  DEFW $0000
  DEFB $00
  DEFB $1B
  DEFW L929C_0
  DEFB $FF
Obj27StrongPortcullis:
  DEFB $02,$FF
  DEFB $90,$FF,$00,$00,$00
  DEFB $80
  DEFB $F1,$04
  DEFB $64,$06
  DEFB $00,$00
  DEFW $0000
  DEFB $21,$22
  DEFB $1E
  DEFW L8F3B
  DEFB $FF
Obj28Stone:
  DEFB $01,$FF
  DEFB $FE,$FE,$00,$FF,$FF
  DEFB $80
  DEFB $41,$36
  DEFB $00,$00
  DEFB $00,$00
  DEFW $0000
  DEFB $2F
  DEFB $FF
Chr3DNastyGoblin:
  DEFB $01,$FF
  DEFB $40,$30,$20,$48,$60
  DEFB $E0
  DEFB $E2,$02
  DEFB $6A,$04
  DEFB $00,$00
  DEFW $0000
  DEFB $0F
  DEFB $0F
  DEFW VerbAttack
  DEFB $00
  DEFW RespawnKilledGoblin
  DEFB $FF
Chr45HideousGoblin:
  DEFB $01,$FF
  DEFB $40,$30,$20,$48,$60
  DEFB $E0
  DEFB $E2,$02
  DEFB $37,$03
  DEFB $00,$00
  DEFW $0000
  DEFB $3A
  DEFB $0F
  DEFW VerbAttack
  DEFB $00
  DEFW RespawnKilledGoblin
  DEFB $FF
Chr49HorribleGoblin:
  DEFB $01,$FF
  DEFB $40,$30,$20,$48,$60
  DEFB $E0
  DEFB $E2,$02
  DEFB $61,$03
  DEFB $00,$00
  DEFW $0000
  DEFB $12
  DEFB $0F
  DEFW VerbAttack
  DEFB $00
  DEFW RespawnKilledGoblin
  DEFB $FF
Chr4AMeanGoblin:
  DEFB $01,$FF
  DEFB $40,$30,$20,$48,$60
  DEFB $E0
  DEFB $E2,$02
  DEFB $34,$04
  DEFB $00,$00
  DEFW $0000
  DEFB $38
  DEFB $0F
  DEFW VerbAttack
  DEFB $00
  DEFW RespawnKilledGoblin
  DEFB $FF
Chr4BViciousGoblin:
  DEFB $01,$FF
  DEFB $40,$30,$20,$48,$60
  DEFB $E0
  DEFB $E2,$02
  DEFB $41,$07
  DEFB $00,$00
  DEFW $0000
  DEFB $40
  DEFB $0F
  DEFW VerbAttack
  DEFB $00
  DEFW RespawnKilledGoblin
  DEFB $FF
Chr4CDisgustingGoblin:
  DEFB $01,$FF
  DEFB $40,$30,$20,$48,$60
  DEFB $E0
  DEFB $E2,$02
  DEFB $B6,$01
  DEFB $00,$00
  DEFW $0000
  DEFB $10
  DEFB $0F
  DEFW VerbAttack
  DEFB $00
  DEFW RespawnKilledGoblin
  DEFB $FF

; Default verb handlers: (verb id, handler address), ends with $FF
;
; Looked up with the verb id ($B6E7) by $94E3 and $95CF when the object has no
; handler of its own; id 0 chains to the next record. Verbs 1-10 are the
; movement verbs, handled by $8D9D.
VerbHandlers:
  DEFB $01
  DEFW VerbMove
  DEFB $02
  DEFW VerbMove
  DEFB $03
  DEFW VerbMove
  DEFB $04
  DEFW VerbMove
  DEFB $05
  DEFW VerbMove
  DEFB $06
  DEFW VerbMove
  DEFB $07
  DEFW VerbMove
  DEFB $08
  DEFW VerbMove
  DEFB $09
  DEFW VerbMove
  DEFB $0A
  DEFW VerbMove
  DEFB $13
  DEFW VerbTake
  DEFB $0D
  DEFW VerbDrop
  DEFB $0F
  DEFW VerbAttack
  DEFB $17
  DEFW VerbLook
  DEFB $1A
  DEFW VerbInventory
  DEFB $1C
  DEFW ExamineObject
  DEFB $1D
  DEFW GiveObject
  DEFB $1F
  DEFW L8FCD
  DEFB $20
  DEFW L8FCD
  DEFB $24
  DEFW VerbRun
  DEFB $27
  DEFW VerbFollow
  DEFB $2A
  DEFW L8FF5
  DEFB $30
  DEFW VerbCapture
  DEFB $00
  DEFW UpdatePlayerSight
  DEFB $33
  DEFW LA244_5
  DEFB $2E
  DEFW LA244_0
  DEFB $2D
  DEFW LA244_8
  DEFB $35
  DEFW TalkToCharacter
  DEFB $3A
  DEFW L9065_0
  DEFB $3B
  DEFW VerbTake
  DEFB $37
  DEFW LA536_0
  DEFB $FF

; Arrival handlers: (location id, routine address), ends with $FF
;
; After a move to a location, $8E24 looks up its id (destination, $8D9B) here
; and calls the routine ($9B6C).
ArrivalHandlers:
  DEFB $16
  DEFW ArriveBeornsHouse
  DEFB $1A
  DEFW ArriveSpiderPlace
  DEFB $1D
  DEFW ArriveBog
  DEFB $21
  DEFW ArriveForestRiver
  DEFB $02
  DEFW ArriveForest
  DEFB $03
  DEFW ArriveForest
  DEFB $20
  DEFW ArriveCellar
  DEFB $FF

; Beorn house: wake the butler (location $16)
ArriveBeornsHouse:
  LD HL,Chr42ButlerFlags
  BIT 3,(HL)
  RET NZ
  LD A,$42
  LD (NpcButler),A
  SET 7,(HL)
  RET

; Mirkwood spider place: start timer 3 (location $1A)
ArriveSpiderPlace:
  LD A,(Timer2Start)
  LD (Timer2Counter),A
  RET

; Deep bog: start timer 4 (location $1D)
ArriveBog:
  LD A,(Timer4Start)
  LD (Timer4Counter),A
  RET

; Elvenking cellar: start timer 9, wake the dragon slot and the Bard (location
; $20)
ArriveCellar:
  LD A,$03
  LD (Timer9Counter),A
  LD HL,Chr3CDragonFlags
  BIT 3,(HL)
  JR NZ,ArriveCellar_0
  LD A,$3C
  LD (NpcDragon),A
ArriveCellar_0:
  LD HL,Chr46BardFlags
  BIT 3,(HL)
  RET NZ
  LD A,$46
  LD (NpcBard),A
  RET

; Forest road and forest: remember the arrival, start timer 8 (locations 2 and
; 3)
ArriveForest:
  LD A,(TakeId)
  LD (ArrivalLocation),A
  LD A,(Timer8Start)
  LD (Timer8Counter),A
  RET

; Forest river: without the barrel the player is swept away (location $21)
ArriveForestRiver:
  LD A,(Chr00PlayerHolder)
  CP $13
  RET Z
  CALL ActorArrives_0
  LD HL,MsgSweptForcefully
  CALL PrintMessage
  JP EndGame

; Random events: 4 records (dictionary phrase code, message address)
;
; One is picked at game start ($97E0, random 0-3) into $B6EE; $A8F6 looks for
; the phrase (night, man) in a stored order and $A8D2 prints the message.
RandomEvents:
  DEFB $74,$04
  DEFW LB1EE
  DEFB $29,$04
  DEFW LB2B7
  DEFB $74,$04
  DEFW LB1EE
BlockedExitsBase:
  DEFB $29,$04
  DEFW LB2B7
  DEFB $FF,$FF

; Blocked exits: 5 records of 6 bytes
;
; Record: location id, address of an exit triple in $BA8A, the saved triple
; (direction, obstacle, destination). $97AD picks one of them (random 1-4 or 5)
; and zeroes the triple in the location record; $A7C4 puts it back. Record 0 of
; the table is the overlap $C808-$C80D.
BlockedExits:
  DEFB $16
  DEFW Loc00None_3
  DEFB $01,$00,$31
  DEFB $18
  DEFW Loc00None_4
  DEFB $03,$00,$19
  DEFB $15
  DEFW Loc00None_2
  DEFB $04,$00,$14
  DEFB $22
  DEFW Loc00None_5
  DEFB $03,$00,$23
  DEFB $0A
  DEFW Loc00None_1
  DEFB $03,$00,$0B
  DEFB $FF

; NPC behaviour: tables of scripts and the scripts (all characters)
;
; Run by $980E / $9815 for each NPC record of $CACB, whose +2 is the current
; script address and +4 its behaviour table. Table: 3-byte records (behaviour
; id, script address), $FF ends; id 0 is the default, $0F the idle script, $1D
; and $30 are looked up by command $0C and by events; $9A59 (command $0F) picks
; entry 0..N at random.
;
; Script command, first byte = op in the low nibble, bit 4: a second address
; follows (taken on success), bit 5: erase the command after use, bit 6: not
; interrupted by an order. Ops 0 and 2: verb, noun1, noun2 (4 bytes; run as a
; typed command); 1 and 3: address of a routine + 1 pad byte ($9B6C); 4: verb
; only (2 bytes); $C: switch to behaviour id (2 bytes); $E: jump to the address
; (3 bytes); $F: choose entry at random, argument = highest index (2 bytes);
; 5-9, $B, $D: 1 byte, restart the default behaviour (entry 0).
GoblinABehaviours:
  DEFB $00
  DEFW ScriptC842
  DEFB $0F
  DEFW ScriptC89E
  DEFB $FF
GoblinBBehaviours:
  DEFB $00
  DEFW ScriptC871
  DEFB $0F
  DEFW ScriptC89E
  DEFB $FF
GoblinCBehaviours:
  DEFB $00
  DEFW ScriptC895
  DEFB $0F
  DEFW ScriptC89E
  DEFB $FF
ScriptC842:
  DEFB $02,$10,$06,$FF
ScriptC846:
  DEFB $14,$30
  DEFW ScriptC84D
  DEFB $0E
  DEFW ScriptC846
ScriptC84D:
  DEFB $04,$09
ScriptC84F:
  DEFB $14,$30
  DEFW ScriptC856
  DEFB $0E
  DEFW ScriptC84F
ScriptC856:
  DEFB $04,$0A
ScriptC858:
  DEFB $14,$30
  DEFW ScriptC85F
  DEFB $0E
  DEFW ScriptC858
ScriptC85F:
  DEFB $02,$0C,$06,$FF
  DEFB $04,$02
ScriptC865:
  DEFB $14,$30
  DEFW ScriptC86C
  DEFB $0E
  DEFW ScriptC865
ScriptC86C:
  DEFB $04,$01
  DEFB $0E
  DEFW ScriptC842
ScriptC871:
  DEFB $04,$06
ScriptC873:
  DEFB $14,$30
  DEFW ScriptC87A
  DEFB $0E
  DEFW ScriptC873
ScriptC87A:
  DEFB $04,$01
ScriptC87C:
  DEFB $14,$30
  DEFW ScriptC883
  DEFB $0E
  DEFW ScriptC87C
ScriptC883:
  DEFB $04,$08
ScriptC885:
  DEFB $14,$30
  DEFW ScriptC88C
  DEFB $0E
  DEFW ScriptC885
ScriptC88C:
  DEFB $04,$09
ScriptC88E:
  DEFB $14,$30
  DEFW ScriptC871
  DEFB $0E
  DEFW ScriptC88E
ScriptC895:
  DEFB $04,$24
  DEFB $04,$0F
  DEFB $04,$30
  DEFB $0E
  DEFW ScriptC895
ScriptC89E:
  DEFB $04,$30
  DEFB $07
GandalfBehaviours:
  DEFB $00
  DEFW ScriptC8C2
  DEFB $00
  DEFW ScriptC8D0
  DEFB $00
  DEFW ScriptC8D4
  DEFB $00
  DEFW ScriptC8DA
  DEFB $00
  DEFW ScriptC8DE
  DEFB $1D
  DEFW ScriptCA7F
  DEFB $30
  DEFW ScriptCA73
  DEFB $0F
  DEFW ScriptCA5E
  DEFB $FF
ScriptC8BA:
  DEFB $02,$1D,$03,$00
  DEFB $02,$10,$05,$FF
ScriptC8C2:
  DEFB $04,$24
  DEFB $14,$13
  DEFW ScriptC8D0
  DEFB $03
  DEFW LA4F5
  DEFB $00
  DEFB $04,$0C
  DEFB $04,$1D
ScriptC8D0:
  DEFB $04,$24
  DEFB $04,$0D
ScriptC8D4:
  DEFB $04,$24
  DEFB $03
  DEFW GandalfCheers
  DEFB $00
ScriptC8DA:
  DEFB $04,$24
  DEFB $04,$1D
ScriptC8DE:
  DEFB $04,$10
  DEFB $0F,$04
ThorinBehaviours:
  DEFB $00
  DEFW ScriptC8EC
  DEFB $1D
  DEFW ScriptCA7F
  DEFB $0F
  DEFW ScriptCA5E
  DEFB $FF
ScriptC8EC:
  DEFB $12,$27,$00,$FF
  DEFW ScriptC8F5
  DEFB $0E
  DEFW ScriptC8EC
ScriptC8F5:
  DEFB $12,$13,$02,$FF
  DEFW ScriptC8FF
  DEFB $23
  DEFW LA51C
  DEFB $00
ScriptC8FF:
  DEFB $13
  DEFW ThorinMissesThief
  DEFB $00
  DEFW ScriptC90C
  DEFB $04,$FF
  DEFB $04,$24
  DEFB $0E
  DEFW ScriptC8EC
ScriptC90C:
  DEFB $03
  DEFW ThorinTalks
  DEFB $00
  DEFB $0E
  DEFW ScriptC8EC
ElfBehaviours:
  DEFB $00
  DEFW ScriptC91D
  DEFB $0F
  DEFW ScriptC91D
  DEFB $1D
  DEFW ScriptCA7F
  DEFB $FF
ScriptC91D:
  DEFB $04,$30
  DEFB $04,$24
  DEFB $0E
  DEFW ScriptC91D
WargBehaviours:
  DEFB $00
  DEFW ScriptC928
  DEFB $FF
ScriptC928:
  DEFB $14,$0F
  DEFW ScriptC92F
  DEFB $0E
  DEFW ScriptC928
ScriptC92F:
  DEFB $14,$27
  DEFW ScriptC93A
  DEFB $03
  DEFW WargHowls
  DEFB $00
  DEFB $0E
  DEFW ScriptC928
ScriptC93A:
  DEFB $14,$24
  DEFW ScriptC941
  DEFB $0E
  DEFW ScriptC928
ScriptC941:
  DEFB $04,$FF
  DEFB $0E
  DEFW ScriptC928
ButlerBehaviours:
  DEFB $00
  DEFW ScriptC950
  DEFB $0F
  DEFW ScriptC960
  DEFB $1D
  DEFW ScriptCA7F
  DEFB $FF
ScriptC950:
  DEFB $02,$26,$08,$0F
  DEFB $02,$10,$08,$FF
  DEFB $02,$0C,$08,$FF
  DEFB $02,$25,$08,$0F
ScriptC960:
  DEFB $14,$30
  DEFW ScriptC967
  DEFB $0E
  DEFW ScriptC960
ScriptC967:
  DEFB $02,$10,$13,$FF
  DEFB $02,$21,$14,$FF
  DEFB $04,$30
  DEFB $02,$0C,$13,$FF
  DEFB $02,$10,$0C,$FF
  DEFB $04,$30
  DEFB $02,$13,$13,$FF
  DEFB $02,$2C,$13,$0C
  DEFB $04,$30
  DEFB $02,$0C,$0C,$FF
  DEFB $14,$30
  DEFW ScriptC950
  DEFB $0E
  DEFW ScriptC950
ElrondBehaviours:
  DEFB $00
  DEFW ScriptC9A0
  DEFB $0F
  DEFW ScriptC9AA
  DEFB $1D
  DEFW ScriptCA7F
  DEFB $FF
ScriptC99A:
  DEFB $13
  DEFW ElrondGreets
  DEFB $00
  DEFW ScriptC9A4
ScriptC9A0:
  DEFB $03
  DEFW LA9E5
  DEFB $00
ScriptC9A4:
  DEFB $04,$FF
  DEFB $14,$FF
  DEFW ScriptC99A
ScriptC9AA:
  DEFB $14,$0F
  DEFW ScriptC99A
  DEFB $0E
  DEFW ScriptC9AA
DragonBehaviours:
  DEFB $00
  DEFW ScriptC9B8
  DEFB $0F
  DEFW ScriptC9CD
  DEFB $FF
ScriptC9B8:
  DEFB $13
  DEFW LA67E_5
  DEFB $00
  DEFW ScriptC9C1
  DEFB $0E
  DEFW ScriptC9B8
ScriptC9C1:
  DEFB $13
  DEFW LA67E_0
  DEFB $00
  DEFW ScriptC9D2
  DEFB $13
  DEFW LA67E_3
  DEFB $00
  DEFW ScriptC9D2
ScriptC9CD:
  DEFB $04,$2D
  DEFB $0E
  DEFW ScriptC9B8
ScriptC9D2:
  DEFB $04,$24
  DEFB $0E
  DEFW ScriptC9B8
BardBehaviours:
  DEFB $00
  DEFW ScriptC9DE
  DEFB $0F
  DEFW ScriptC9E9
  DEFB $FF
ScriptC9DE:
  DEFB $43
  DEFW LA814_8
  DEFB $00
BardCommandOp:
  DEFB $42
BardCommandVerb:
  DEFB $13
BardCommandArgs:
  DEFB $25,$FF
  DEFB $0E
  DEFW ScriptC9DE
ScriptC9E9:
  DEFB $54,$3A
  DEFW ScriptCA5E
  DEFB $0E
  DEFW ScriptC9E9
GollumBehaviours:
  DEFB $00
  DEFW ScriptC9F7
  DEFB $0F
  DEFW ScriptCA2B
  DEFB $FF
ScriptC9F7:
  DEFB $13
  DEFW GollumAsksRiddle
  DEFB $00
  DEFW ScriptCA10
  DEFB $43
  DEFW LA8F6
  DEFB $00
  DEFB $02,$0D,$10,$FF
  DEFB $14,$01
  DEFW ScriptCA21
ScriptCA09:
  DEFB $02,$13,$10,$FF
  DEFB $0E
  DEFW ScriptC9F7
ScriptCA10:
  DEFB $14,$01
  DEFW ScriptCA26
ScriptCA14:
  DEFB $13
  DEFW GollumTalks
  DEFB $00
  DEFW ScriptC9F7
  DEFB $02,$13,$10,$FF
  DEFB $0E
  DEFW ScriptC9F7
ScriptCA21:
  DEFB $04,$08
  DEFB $0E
  DEFW ScriptCA09
ScriptCA26:
  DEFB $04,$08
  DEFB $0E
  DEFW ScriptCA14
ScriptCA2B:
  DEFB $02,$28,$10,$FF
  DEFB $04,$24
  DEFB $0E
  DEFW ScriptC9F7
TrollBehaviours:
  DEFB $00
  DEFW ScriptCA41
  DEFB $0F
  DEFW ScriptCA5E
  DEFB $FF
ScriptCA3B:
  DEFB $13
  DEFW TrollsTalk
  DEFB $00
  DEFW ScriptCA3B
ScriptCA41:
  DEFB $03
  DEFW LA94E
  DEFB $00
  DEFB $04,$FF
  DEFB $03
  DEFW LA94E
  DEFB $00
  DEFB $04,$FF
  DEFB $03
  DEFW LA94E
  DEFB $00
  DEFB $04,$FF
  DEFB $03
  DEFW LA94E
  DEFB $00
  DEFB $03
  DEFW LA94E_0
  DEFB $00
  DEFB $0E
  DEFW ScriptCA41
ScriptCA5E:
  DEFB $54,$0F
  DEFW ScriptCA6B
  DEFB $54,$0F
  DEFW ScriptCA72
  DEFB $44,$24
  DEFB $0E
  DEFW ScriptCA5E
ScriptCA6B:
  DEFB $54,$27
  DEFW ScriptCA72
  DEFB $0E
  DEFW ScriptCA5E
ScriptCA72:
  DEFB $07
ScriptCA73:
  DEFB $14,$1E
  DEFW ScriptCA7A
  DEFB $04,$24
  DEFB $07
ScriptCA7A:
  DEFB $04,$FF
  DEFB $0E
  DEFW ScriptCA73
ScriptCA7F:
  DEFB $03
  DEFW NpcAnswersGift
  DEFB $00
  DEFB $07

; Timers: 10 records of 7 bytes, $FF ends (saved)
;
; Record: +0 start value (copied to +1 by $C7B2, $AA7D...), +1 counter (0 =
; stopped; stepped by $96B3, which calls the handler at +2 when it reaches 0,
; at most one timer per turn via $B6F0), +4 threshold, +5 address called every
; turn while 0 < counter <= threshold (0: none).
Timers:
  DEFB $02
Timer0Counter:
  DEFB $00
  DEFW LA5E2_0
  DEFB $00
  DEFW $0000
Timer1Start:
  DEFB $02
Timer1Counter:
  DEFB $00
  DEFW LA9E5_2
  DEFB $00
  DEFW $0000
Timer2Start:
  DEFB $05
Timer2Counter:
  DEFB $00
  DEFW LA9E5_13
  DEFB $00
  DEFW $0000
Timer3Start:
  DEFB $02
Timer3Counter:
  DEFB $00
  DEFW LA4C0_0
  DEFB $00
  DEFW $0000
Timer4Start:
  DEFB $02
Timer4Counter:
  DEFB $00
  DEFW LA761_3
  DEFB $02
  DEFW LA761_3
Timer5Start:
  DEFB $04
Timer5Counter:
  DEFB $00
  DEFW LA9E5_9
  DEFB $01
  DEFW LA9E5_7
Timer6:
  DEFB $00
Timer6Counter:
  DEFB $00
  DEFW LA9E5_10
  DEFB $00
  DEFW $0000
Timer7Start:
  DEFB $05
Timer7Counter:
  DEFB $00
  DEFW LA9E5_12
  DEFB $00
  DEFW $0000
Timer8Start:
  DEFB $04
Timer8Counter:
  DEFB $00
  DEFW LA9E5_16
  DEFB $03
  DEFW LA9E5_14
Timer9Start:
  DEFB $05
Timer9Counter:
  DEFB $00
  DEFW LA9E5_3
  DEFB $01
  DEFW LA9E5_5
  DEFB $FF

; NPC states: 17 records of 7 bytes, $FF ends (saved)
;
; Record: +0 character id (0: dormant slot, an event stores the id: $C7AA
; butler $42, $C7D9 Bard $46, $C7CE dragon $3C), +1 highest index for a random
; choice, +2 address of the current script, +4 address of the behaviour table,
; +6 spare. Run by $980E; the six goblin and troll records are listed in $A49C.
NpcStates:
  DEFB $3E,$07
  DEFW ScriptC8BA
  DEFW GandalfBehaviours
  DEFB $05
NpcThorin:
  DEFB $3F,$02
  DEFW ScriptC8EC
  DEFW ThorinBehaviours
  DEFB $06
NpcElf:
  DEFB $40,$02
  DEFW ScriptC91D
  DEFW ElfBehaviours
  DEFB $01
NpcWarg:
  DEFB $43,$00
  DEFW ScriptC928
  DEFW WargBehaviours
  DEFB $00
NpcButler:
  DEFB $00,$02
  DEFW ScriptC950
  DEFW ButlerBehaviours
  DEFB $01
NpcElrond:
  DEFB $41,$02
  DEFW ScriptC99A
  DEFW ElrondBehaviours
  DEFB $05
NpcGollum:
  DEFB $44,$01
  DEFW ScriptC9F7
  DEFW GollumBehaviours
  DEFB $03
NpcBard:
  DEFB $00,$01
  DEFW ScriptC9DE
  DEFW BardBehaviours
  DEFB $03
NpcDragon:
  DEFB $00,$01
  DEFW ScriptC9B8
  DEFW DragonBehaviours
  DEFB $00
NpcTroll1:
  DEFB $47,$01
  DEFW ScriptCA3B
  DEFW TrollBehaviours
  DEFB $01
NpcTroll2:
  DEFB $48,$01
  DEFW ScriptCA3B
  DEFW TrollBehaviours
  DEFB $01
NpcGoblinA:
  DEFB $3D,$01
  DEFW ScriptC842
  DEFW GoblinABehaviours
  DEFB $00
NpcGoblinB:
  DEFB $45,$01
  DEFW ScriptC842
  DEFW GoblinABehaviours
  DEFB $00
NpcGoblinC:
  DEFB $4B,$01
  DEFW ScriptC871
  DEFW GoblinBBehaviours
  DEFB $00
NpcGoblinD:
  DEFB $49,$01
  DEFW ScriptC895
  DEFW GoblinCBehaviours
  DEFB $00
NpcGoblinE:
  DEFB $4A,$01
  DEFW ScriptC895
  DEFW GoblinCBehaviours
  DEFB $00
NpcGoblinF:
  DEFB $4C,$01
  DEFW ScriptC895
  DEFW GoblinCBehaviours
  DEFB $00
  DEFB $FF

; Unused: 189 zero bytes
;
; Not referenced; between the saved NPC states and the picture table.
LCB43:
  DEFS $BD,$00
