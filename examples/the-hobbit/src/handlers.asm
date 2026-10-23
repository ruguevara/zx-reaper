; Test whether the command puts an object somewhere
;
; Compares the command id (CommandId) with the five verbs of the table at
; IdList: $0E drop in, $11 put in, $12 put on, $14 take out of, $2C throw
; through. These are the commands whose second object is a place for the first.
;
; O:F Z set when the command is one of them
IsPlacingCommand:
  PUSH HL
  PUSH BC
  LD B,$05
  LD HL,IdList
  LD A,(CommandId)
IsPlacingCommand_0:
  CP (HL)
  JR Z,IsPlacingCommand_1
  INC HL
  DJNZ IsPlacingCommand_0
IsPlacingCommand_1:
  POP BC
  POP HL
  RET

; Print a spoken line
;
; Prints "<subject> say "<HL message>"." from the messages MsgSay, then the
; message in HL, then MsgB00F. Sets the capital flag (CapitalNext) first so the
; speech starts with a capital letter.
;
; HL Message address of the words spoken
PrintSpeech:
  PUSH HL
  LD HL,MsgSay
  CALL PrintMessage
  POP HL
  LD A,$01
  LD (CapitalNext),A      ; capital flag
  CALL PrintMessage
  LD HL,MsgB00F
  JP PrintMessage

; Say why the first object cannot be opened, or that it can
;
; For command handler OpenObject (open). Looks at the first object
; (Noun1Record): if its flag bit 0 (locked) is set it returns the reason
; "locked" in A with NZ; else it returns "open" in A, NZ when the object is
; already open (flag bit 5) and Z when it is closed and can be opened. A is the
; state id for PrintStateIX.
;
; O:A State id: $80 locked, $85 open
; O:F NZ: refused (locked or already open); Z: may be opened
CheckOpenable:
  LD IX,(Noun1Record)
  BIT FLAG_LOCKED,(IX+$07)
  LD A,REASON_LOCKED
  RET NZ
CheckOpenable_0:
  BIT FLAG_ACTIVE,(IX+$07)
  LD A,REASON_OPEN
  RET

; Object name words, failure reason words and their lists
;
; $A20B: five record ids (checked by $A1D4). $A20E: table of dictionary word
; references, one per id (indexed from 1, read by $A0BA). $A224 and $A234: 8
; reason words each, chosen by $A172 (second table when bit 7 of A is set).
IdList:
  DEFB $0E,$11,$12
NameWordTable:
  DEFB $14,$2C
  DEFB $80,$04
  DEFB $07,$06
  DEFB $FE,$01
  DEFB $79,$07
  DEFB $85,$04
  DEFB $8E,$04
  DEFB $0C,$06
  DEFB $15,$06
  DEFB $25,$07
  DEFB $C4,$01
ReasonWords1:
  DEFB $18,$07
  DEFB $00,$00
  DEFB $28,$02
  DEFB $00,$00
  DEFB $9F,$04
  DEFB $39,$01
  DEFB $92,$01
  DEFB $00,$00
ReasonWords2:
  DEFB $F6,$03
  DEFB $00,$00
  DEFB $B9,$02
  DEFB $CD,$00
  DEFB $AA,$04
  DEFB $B4,$04
  DEFB $D4,$07
  DEFB $00,$00

; Handlers (via $A1D5): $A244, $A248, $A2B4, $A2CD, $A302, $A310, $A328, $A330
LA244:
  CALL CommitOrAbort
  RET
LA244_0:
  LD A,(FirstObject)
  CP $12
  JR Z,LA244_4
  LD A,(SecondObject)
  CP $12
  JP NZ,RefuseCommand
  LD IX,(Noun1Record)
  BIT 1,(IX+$07)
  JP NZ,RefuseCommand
  CALL CountHeldPresent
  CP $00
  LD HL,MsgAlreadyTied
  JP NZ,PrintMessage
  BIT 3,(IX+$07)
  JR NZ,LA244_1
  BIT 6,(IX+$07)
  JP NZ,RefuseCommand
LA244_1:
  CALL CommitOrAbort
  LD IY,(Noun2Record)
  CALL CheckObject1Held
  LD A,(SecondObject)
  LD (IX+$01),A
  JR C,LA244_2
  SUB A
  LD (ActionPerform),A
  CALL VerbTake
  LD A,(ActionAllowed)
  CP $00
  LD A,$01
  LD (ActionPerform),A
  LD (ActionAllowed),A
  JR Z,LA244_3
LA244_2:
  LD A,(Subject)
  LD (IY+$01),A
  RET
LA244_3:
  LD (IY+$01),$FF
  RET
LA244_4:
  LD HL,LA244_0
  JP L9F4A
LA244_5:
  LD IX,(Noun1Record)
  LD A,(IX+$01)
  CP $12
  LD HL,MsgNotTied
  JP NZ,PrintMessage
  CALL CommitOrAbort
  LD A,(Obj12RopeHolder)
  LD (IX+$01),A
  RET
LA244_6:
  CALL FindExitByObstacle
  LD A,(IX+$02)
  CP $00
  JR NZ,LA244_7
  CALL CommitOrAbort
  RET
LA244_7:
  LD A,(IX+$00)
  LD HL,(CommandId)
  PUSH HL
  LD (CommandId),A
  LD IX,(Noun1Record)
  SET 5,(IX+$07)
  PUSH IX
  LD A,$FF
  LD (FirstObject),A
  CALL MoveActor
  POP IX
  RES 5,(IX+$07)
  POP HL
  LD (CommandId),HL
  RET
LA244_8:
  LD A,(Subject)
  CP $3C
  JP NZ,RefuseCommand
  CALL CommitOrAbort
  JP L977C
LA244_9:
  CALL CommitOrAbort
  LD HL,MsgAsSoonAsTouchRiver
LA244_10:
  CALL PrintMessage
  LD A,(Subject)
  PUSH AF
  AND A
  LD HL,MsgTimePasses2
  CALL Z,PrintMessage
  POP AF
  JP KillCharacter
LA244_11:
  CALL CommitOrAbort
  LD HL,MsgFallAsleep
  JR LA244_10
LA244_12:
  LD B,$02
  JR LA244_15
LA244_13:
  LD B,$0F
  JR LA244_15
LA244_14:
  LD B,$04
LA244_15:
  LD A,(SecondObject)
  CP B
  JR NZ,LA244_16
  LD A,(CommandId)
  CP $25
  JP Z,L9404_5
  JP L9404_7
LA244_16:
  CP $02
  JR Z,PrintNoFit
  CP $04
  JR Z,PrintNoFit
  CP $0F
  JP NZ,PrintCannotDoThat

; Print that the key does not fit
;
; Message "<object 2> does not fit this lock." Reached by the key and lock
; handlers (LA244) when the second object is not the right key.
PrintNoFit:
  LD HL,MsgDoesNotFitThisLock
  JP PrintMessage

; Command handler (via $C730): call $97FF, jump to $9117
LA35E:
  CALL AbortUnlessPerform
  LD IX,(Noun1Record)
  JP OpenObject_0

; Open handler of the small insignificant crack
;
; The handler of the crack (OBJ_SMALL_INSIGNIFICANT) for the verb open ($10),
; from its verb table. The crack can only be opened by a character who is in
; the dark stuffy passage $0F (the first location in the acting character's
; record); from anywhere else the command is refused (RefuseCommand: "cannot
; open"). In the passage the normal open handler runs (OpenObject, which tests
; locked and open).
;
; Observed: a nasty goblin in $0F opens it (verbs.txt). The actor is read from
; ActorRecord, the noun from Noun1Record by OpenObject.
;
; Hardware: none.
OpenCrack:
  LD IX,(ActorRecord)     ; actor record
  LD A,(IX+$10)           ; actor's location
  CP LOC_DARK_STUFFY_PASSA_0F
  JP NZ,RefuseCommand     ; not in the passage: refuse
  JP OpenObject           ; the normal open

; Command handler (via $C730) with entry points $A390 and $A3BC
LA377:
  LD IX,(Noun1Record)
  BIT 3,(IX+$07)
  RET Z
  SET 5,(IX+$07)
  LD A,(Timer1Start)
  LD (Timer1Counter),A
  LD HL,MsgSomeSpidersStart
  JP PrintMessage
LA377_0:
  CALL CommitOrAbort
  LD IY,(ActorRecord)
  LD IX,Obj10ValuableGoldenRing
  RES 7,(IY+$07)
  SRL (IY+$05)
  SRL (IY+$05)
  RES 7,(IX+$07)
  LD A,(Subject)
  LD (IX+$01),A
  LD A,$08
  CALL RandomUpTo
  ADD A,$02
  LD (Timer6Counter),A
  RET
LA377_1:
  LD IX,(ActorRecord)
  LD IY,Obj10ValuableGoldenRing
  BIT 7,(IY+$07)
  LD HL,MsgNotWearing
  JP NZ,PrintMessage
  CALL CommitOrAbort
  SET 7,(IY+$07)
  SET 7,(IX+$07)
  SLA (IX+$05)
  SLA (IX+$05)
  SUB A
  LD (Timer6Counter),A
  RET

; Capture: send the first object to a prison
;
; Default handler of capture (id 48; VerbHandlers). Refused when the two share
; a side bit in their state bytes (+4, STATE_SIDE_BITS), when the first object
; is not a character, or when the capturer's location (ActorLocation, set by
; the NPC loop) is the prison already. The prison is LOC_DARK_DUNGEON for the
; wood elf and the butler (the elvenking's), else LOC_GOBLINS_DUNGEON. When
; really performing the captive's holder becomes AT_LOCATION and its location
; the prison, and what it carries goes with it (MoveCarried). When the captive
; is the player, he is made the subject and, unless it is dark, "You are in"
; and the prison are described (DescribeLocation_Intro).
;
; Hardware: none directly; the description may show a picture and wait for a
; key.
VerbCapture:
  LD IX,(Noun1Record)     ; the first object, the captive
  LD A,(IX+$04)           ; its side bits...
  AND STATE_SIDE_BITS
  PUSH IX                 ; keep the captive
  LD IX,(ActorRecord)     ; the actor
  AND (IX+$04)            ; shared with the captive?
  POP IX
  JP NZ,RefuseCommand     ; yes: refuse
  BIT FLAG_CHARACTER,(IX+$07) ; not a character: refuse
  JP Z,RefuseCommand
  LD A,(Subject)          ; the subject
  LD B,LOC_DARK_DUNGEON
  CP CHR_WOOD_ELF
  JR Z,VerbCapture_0
  CP CHR_BUTLER
  JR Z,VerbCapture_0
  LD B,LOC_GOBLINS_DUNGEON
VerbCapture_0:
  LD A,(ActorLocation)    ; where the NPC last run is
  CP B
  JP Z,RefuseCommand      ; already in the prison: refuse
  CALL CommitOrAbort      ; only when really performing
  LD IX,(Noun1Record)     ; the captive
  LD (IX+$10),B           ; its location := the prison
  LD (IX+$01),AT_LOCATION ; lies at a location
  LD A,(FirstObject)      ; the captive's id...
  CALL MoveCarried        ; ... takes what it carries along
  LD A,(FirstObject)      ; the captive
  CP PLAYER
  RET NZ                  ; not the player: done
  LD (Subject),A          ; the player is the subject (A = 0)
  LD HL,Chr00Player       ; and the actor
  LD (ActorRecord),HL
  CALL CheckDark          ; dark? (nothing is described)
  RET C
  LD A,B                  ; A = the prison
  LD HL,MsgSubjIsIn       ; "<subj_is> in"
  JP DescribeLocation_Intro ; describe the prison

; Bring a killed goblin back at its home
;
; Chained after the attack handler VerbAttack in the verb table of each of the
; six goblins (verb 0 = run after the previous entry). When the attacked
; character (Noun1Record) has just been killed (its dead flag, bit 3, is set)
; the goblin is revived: the flag is cleared, and the record found in
; RecordTable by its id supplies the goblin's home. The id is stored back into
; the goblin's NPC state (so RunNpcScripts runs it again; KillCharacter had
; cleared it), and its location (+$10) and its second name phrase (+$0A, +$0B:
; it was replaced by the word "dead", MarkBrokenOrDead) are restored. Prints
; "<goblin> falls down a hole and vanishes." and, when the player's location
; equals B, "Another goblin enters." So the goblins cannot be killed for good.
;
; Hardware: none (the text goes through the message printer).
;
; B Compared with the player's location; nothing here sets it (a leftover of
; the command dispatcher: $0E when the mean goblin was killed with the
; player at $36), so the "Another goblin enters." line is unreliable
RespawnKilledGoblin:
  LD IX,(Noun1Record)     ; IX = the attacked character
  BIT FLAG_DEAD,(IX+$07)  ; killed?
  RET Z                   ; no: nothing to do
  RES FLAG_DEAD,(IX+$07)  ; alive again
  LD DE,RESPAWN_RECORD_SIZE
  LD IY,RecordTable       ; IY = RecordTable
  LD A,(FirstObject)      ; A = the goblin's id
RespawnKilledGoblin_Find:
  CP (IY+$00)             ; find the record of that id (it is always there)
  JR Z,RespawnKilledGoblin_0
  ADD IY,DE
  JR RespawnKilledGoblin_Find
RespawnKilledGoblin_0:
  PUSH IY
  POP HL
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD (DE),A               ; the NPC state's id slot := the goblin's id
  INC HL
  LD A,(HL)
  LD (IX+$10),A           ; home location
  INC HL
  LD A,(HL)
  LD (IX+$0A),A           ; second name phrase restored (replaces "dead")
  INC HL
  LD A,(HL)
  LD (IX+$0B),A
  LD HL,MsgFallsDownHoleVanishes ; "<obj1> falls down a hole and vanishes."
  CALL PrintMessage
  LD A,(Chr00PlayerLocation) ; player's location
  CP B
  RET NZ                  ; not equal to B: done
  LD DE,WORD_ANOTHER
  CALL PrintWord          ; "another"
  LD DE,WORD_GOBLIN
  CALL PrintWord          ; "goblin"
  LD HL,MsgEnters2        ; "Enters."
  JP PrintMessage

; Table of 6-byte records for the handler at $A448 (6 records)
;
; Record: id (compared with ($B6E8)), address of a game state byte, then three
; bytes stored to IX+$10, IX+$0A, IX+$0B.
RecordTable:
  DEFB $3D
  DEFW NpcGoblinA
  DEFB $0F,$6A,$04
  DEFB $45
  DEFW NpcGoblinB
  DEFB $3A,$37,$03
  DEFB $49
  DEFW NpcGoblinD
  DEFB $12,$61,$03
  DEFB $4A
  DEFW NpcGoblinE
  DEFB $38,$34,$04
  DEFB $4B
  DEFW NpcGoblinC
  DEFB $40,$41,$07
  DEFB $4C
  DEFW NpcGoblinF
  DEFB $10,$B6,$01

; Handler: test (IX+$10)=$10, call $910E and $97FF
LA4C0:
  LD IX,(ActorRecord)
  LD A,(IX+$10)
  CP $10
  JP NZ,RefuseCommand
  CALL OpenObject
  CALL AbortUnlessPerform
  LD A,(Timer3Start)
  LD (Timer3Counter),A
  RET
LA4C0_0:
  LD HL,Obj11DoorFlags
  RES 5,(HL)
  RET

; NPC answer to being given something
;
; Script handler (op 3 in GoblinABehaviours) of behaviour $1D, the behaviour
; switched on by the event "give" (command id $1D) for Gandalf, Thorin, the
; wood elf, the butler and Elrond. The character speaks: usually "Thank you",
; sometimes (a random number from 0 to 10 of 8 or more) "What do you expect me
; to do with this ?". Always passes the test pass of the script engine
; (CommitOrAbort).
;
; Hardware: none (the text goes through the message printer).
NpcAnswersGift:
  CALL CommitOrAbort      ; test pass: allowed, nothing else
  LD A,$0A
  CALL RandomUpTo         ; random 0 to 10
  LD HL,MsgWhatDoExpectMeDo ; "What do you expect me to do with this ?"
  CP $08                  ; 8 or more
  JP NC,PrintSpeech
  LD HL,MsgThank          ; "Thank you"
  JP PrintSpeech

; Command handler (via $C8C9 table)
LA4F5:
  CALL CommitOrAbort
  LD HL,MsgWhatSThis
  JP PrintSpeech

; Gandalf cheers the player on
;
; Script handler (op 3, in Gandalf's script ScriptC8D4). Says one of "You are
; doing a great job", "Hurry up" or "Hello", chosen by a random number from 0
; to 2. Always passes the test pass of the script engine (CommitOrAbort).
;
; Hardware: none (the text goes through the message printer).
GandalfCheers:
  CALL CommitOrAbort
  LD A,$02
  CALL RandomUpTo         ; random 0 to 2
  LD HL,MsgDoingGreatJob  ; "You are doing a great job"
  CP $00
  JP Z,PrintSpeech
  LD HL,MsgHurryUp        ; "Hurry up"
  CP $01
  JP Z,PrintSpeech
  LD HL,MsgHello          ; "Hello"
  JP PrintSpeech

; Command handler (via $C8FC table)
LA51C:
  CALL CommitOrAbort
  LD HL,MsgThisWasThrainsKey
  JP PrintSpeech

; Elrond greets the player
;
; Script handler (op 3, in Elrond's script ScriptC99A). When Elrond is where
; the player is (ActorLocation = PlayerLocation) he says "Hello". Otherwise it
; returns before the test pass accepts, so the script takes its alternative
; step (ScriptC9A4).
;
; Hardware: none (the text goes through the message printer).
ElrondGreets:
  LD A,(ActorLocation)    ; location of the NPC being run
  LD HL,PlayerLocation
  CP (HL)
  RET NZ                  ; not with the player: refuse
  CALL CommitOrAbort
  LD HL,MsgHello          ; "Hello"
  JP PrintSpeech

; Command handlers ($A536, $A541, $A55F)
LA536:
  LD A,(Subject)
  CP $40
  JP NZ,RefuseCommand
  JP OpenObject
LA536_0:
  LD IY,(ActorRecord)
  LD A,(FirstObject)
  CP (IY+$01)
  JP NZ,RefuseCommand
  CALL FindObject
  CALL CheckOpen
  JP Z,PrintStateIX
  CALL CommitOrAbort
  LD (IY+$01),$FF
  RET
LA536_1:
  LD IY,(ActorRecord)
  LD A,(FirstObject)
  CP (IY+$01)
  JP Z,RefuseCommand
  LD IY,(Noun1Record)
  CALL ActorCanReach
  JP Z,RefuseCommand
  LD A,(FirstObject)
LA536_2:
  CALL FindObject
  LD A,(IX+$01)
  CP $FF
  JR Z,LA536_3
  LD A,(Subject)
  CP (IX+$01)
  LD A,(IX+$01)
  JR NZ,LA536_2
  LD IX,(Noun1Record)
  LD (IX+$01),$FF
LA536_3:
  LD IY,(ActorRecord)
  LD A,(Subject)
  CALL SumHeldWeight
  ADD A,(IY+$02)
  JR C,LA536_4
  LD A,$FF
LA536_4:
  LD B,A
  LD IX,(Noun1Record)
  CALL CheckOpen
  JP Z,PrintStateIX
  LD A,(IX+$02)
  CP $FF
  JR Z,LA536_5
  SUB B
  LD HL,MsgTooBig
  JP NC,PrintMessage
LA536_5:
  CALL CommitOrAbort
  LD A,(FirstObject)
  LD (IY+$01),A
  RET

; Test whether the object is open
;
; Reports the state of the object at IX: A is the state id 5 ("closed") and Z
; is set when the open flag (bit 5) is clear. Callers jump to PrintStateIX to
; say "<it> is closed" on Z.
;
;   IX Record of the object
; O:A 5, state id of "closed" (bit 7 clear)
; O:F Z set when the object is closed
CheckOpen:
  BIT FLAG_ACTIVE,(IX+$07)
  LD A,REASON_CLOSED
  RET

; The warg runs around the player and howls
;
; Script handler (op 3, in the warg's script ScriptC92F). Always passes the
; test pass of the script engine (CommitOrAbort); when the player is in the
; warg's location it prints "The vicious warg run around you and howls."
; (PrintMessageDot adds the full stop and a new line).
;
; Hardware: none (the text goes through the message printer).
WargHowls:
  CALL CommitOrAbort
  LD HL,Chr43WargLocation ; the warg's location
  LD A,(Chr00PlayerLocation) ; player's location
  CP (HL)
  RET NZ                  ; elsewhere: silent
  LD HL,MsgViciousWargRunAround ; "The vicious warg run around you and howls"
  JP PrintMessageDot

; Handlers: $A5E2 (via $C302), $A5FB
LA5E2:
  LD A,(FirstObject)
  CP $13
  RET NZ
  CALL AbortUnlessPerform
  LD IX,Obj13Barrel
  LD A,(IX+$10)
  CP $21
  RET NZ
  LD A,$02
  LD (Timer0Counter),A
  RET
LA5E2_0:
  SUB A
  LD (TimersFired),A
  LD A,(Chr00PlayerHolder)
  CP $13
  LD HL,MsgThrownOntoBankLong
  CALL Z,PrintMessage
  LD A,$22
  LD (Obj13BarrelLocation),A
  LD B,A
  LD A,$13
  CALL MoveCarried
  LD IX,Obj13Barrel
  LD (IX+$10),$20
  RES 5,(IX+$07)
  SET 2,(IX+$07)
  SUB A
  LD (MessagesVisible),A
  LD A,$13
  CALL EmptyHolder
  LD A,$01
  LD (MessagesVisible),A
  LD IY,Obj14Wine
  LD (IY+$10),$20
  LD (IY+$01),$13
  RET

; Thorin asks where the thief is
;
; Script handler (op 3, in Thorin's script ScriptC8FF). When Thorin is where
; the player is and the player is invisible (the present/visible flag, bit 7 of
; the player's flags, is cleared while the ring is worn, LA377) he says
; "Where's the thief ?". Otherwise it returns before the test pass accepts, so
; the script takes its alternative step (ScriptC90C, ThorinTalks).
;
; Hardware: none (the text goes through the message printer).
ThorinMissesThief:
  LD A,(ActorLocation)    ; location of the NPC being run
  LD HL,PlayerLocation
  CP (HL)
  RET NZ                  ; not with the player: refuse
  LD A,(Chr00PlayerFlags) ; the player's flags
  BIT FLAG_PRESENT,A
  RET NZ                  ; visible: refuse
  CALL CommitOrAbort
  LD HL,MsgWhereSThief    ; "Where's the thief ?"
  JP PrintSpeech

; Thorin's remarks
;
; Script handler (op 3, in Thorin's script ScriptC90C). Always passes the test
; pass of the script engine (CommitOrAbort). Then, by a random number A from 0
; to 8 (small values likelier): 0 "Thorin sits down and starts singing about
; gold", 1-2 Thorin says "Hurry up", 3-4 "Thorin wait" (these two as plain text
; with a full stop, PrintMessageDot), 5 or more nothing.
;
; The branch for "Get us out of this one, thief !" ($B0D5) cannot be reached:
; it tests Z after a CP 3 that has already sent every A of 3 or more away
; (finding).
;
; Hardware: none (the text goes through the message printer).
ThorinTalks:
  CALL CommitOrAbort
  LD A,$08                ; random 0 to 8
  CALL RandomUpTo
  CP $05                  ; 5 or more: silent
  RET NC
  CP $03                  ; 3 or 4:
  LD HL,MsgThorinWait     ; "Thorin wait"
  JP NC,PrintMessageDot
  LD HL,MsgGetUsOutThisOne ; "Get us out of this one, thief !" (never reached)
  JP Z,PrintSpeech        ; Z cannot hold here: A is below 3 and not 3
  LD HL,MsgThorinSitsDownStarts ; "Thorin sits down and starts singing about
                                ; gold"
  CP $00
  JP Z,PrintMessageDot
  LD HL,MsgHurryUp        ; 1 or 2: "Hurry up"
  JP PrintSpeech

; Handlers (via $C2F0, $C2F3)
LA67E:
  LD IX,(ActorRecord)
  LD A,(IX+$10)
  CP $20
  LD HL,MsgCannotReach
  JP NZ,PrintMessage
  LD A,(CommandId)
  CP $0C
  JP Z,CloseObject
  JP OpenObject
LA67E_0:
  LD A,(Chr00PlayerLocation)
  CP $27
  JR Z,LA67E_1
  CP $2C
  JR Z,LA67E_1
  CP $29
  RET NZ
LA67E_1:
  CALL CommitOrAbort
  LD A,(Chr00PlayerLocation)
  LD HL,Chr3CDragonLocation
  CP (HL)
  RET Z
  LD (HL),A
  LD A,$01
  LD (MessagesVisible),A
  LD HL,Chr3CDragonName
  PUSH HL
  LD HL,MsgEnters
LA67E_2:
  CALL PrintMessage
  RET
LA67E_3:
  LD A,(Chr00PlayerLocation)
  LD HL,ActorLocation
  CP (HL)
  RET NZ
  CALL CommitOrAbort
  LD A,(Chr00PlayerFlags)
  AND $80
  LD HL,MsgDragonSaysIMayNot
  JR Z,LA67E_4
  LD HL,MsgDragonSaysWellThief
LA67E_4:
  JR LA67E_2
LA67E_5:
  LD A,(Obj23TreasureLocation)
  CP $29
  RET Z
  LD A,(Chr00PlayerLocation)
  CALL FindLocation
  BIT 7,(IX+$00)
  RET Z
  CALL CommitOrAbort
  LD A,$01
  LD (MessagesVisible),A
  LD HL,MsgDistanceSeeShape
  LD A,$64
  CALL RandomUpTo
  CP $50
  JR C,LA67E_2
  LD HL,MsgDragonDescends
  CALL PrintMessage
  JP EndGame
  CALL FindExitByObstacle
  CP $FF
  RET Z
  SUB A
  LD (IX+$00),$00
  LD (IX+$01),$00
  LD (IX+$02),$00
  RET
LA67E_6:
  CALL CommitOrAbort
  LD IX,(ActorRecord)
  BIT 7,(IX+$07)
  LD HL,MsgSeeNothingSpecialHere
  JP NZ,PrintMessage
  LD A,(Timer5Start)
  LD (Timer5Counter),A
  LD HL,MsgMagicDoorWarnsElves
  JP PrintMessage

; Killing Thorin breaks the small curious key
;
; Chained after the attack handler VerbAttack in Thorin's verb table. When
; Thorin has just been killed (his dead flag, bit 3, is set) and the command is
; really performed, the small curious key is marked dead/disabled (flag bit 3)
; and renamed "broken key" (MarkBrokenOrDead). If the key is within the
; player's reach (CanReachSwapped) it prints "The small curious key shatters."
;
; Hardware: none (the text goes through the message printer).
ThorinDeathBreaksKey:
  LD HL,Chr3FThorinFlags  ; Thorin's flags
  BIT FLAG_DEAD,(HL)
  RET Z                   ; not killed: nothing to do
  CALL AbortUnlessPerform ; only when performed for real
  LD IX,Obj02SmallCuriousKey ; the small curious key
  SET FLAG_DEAD,(IX+$07)
  LD A,OBJ_SMALL_CURIOUS_KEY
  CALL MarkBrokenOrDead   ; broken
  LD A,OBJ_SMALL_CURIOUS_KEY
  LD IY,Chr00Player
  CALL CanReachSwapped    ; reach test: IX = key, IY = player
  RET Z                   ; out of reach: silent
  LD HL,MsgSmallCuriousKey ; "The small curious key shatters."
  JP PrintMessage

; Handlers (via $C518, $C51B)
LA761:
  LD A,(Subject)
  CP $00
  JR NZ,LA761_0
  LD A,(Chr00PlayerHolder)
  LD HL,MsgCannotReach
  CP $FF
  JP Z,PrintMessage
  JP RefuseCommand
LA761_0:
  LD A,(CommandId)
  CP $0C
  JP Z,CloseObject
  CP $10
  JP Z,OpenObject
  RET
LA761_1:
  LD A,(Subject)
  CP $00
  JP NZ,LA761_2
  LD A,(Chr00PlayerHolder)
  CP $FF
  LD HL,MsgCannotReach
  JP Z,PrintMessage
LA761_2:
  LD A,(CommandId)
  CP $1E
  JP Z,L8F3B
  CP $0B
  JP Z,StrikeObject
  CP $18
  JP Z,VerbLookThrough
  RET
LA761_3:
  LD A,(Chr00PlayerLocation)
  CP $1D
  JR NZ,LA761_4
  SUB A
  LD (Timer4Counter),A
LA761_4:
  LD HL,MsgSlowlySinkingIntoBog
  CALL PrintMessage
  LD A,(Timer4Counter)
  CP $00
  RET NZ
  JP EndGame

; Examine the curious map
;
; Handler of the curious map (OBJ_CURIOUS_MAP) for the verb examine ($1C). When
; the examiner (the subject, $B6EA) is not Elrond it is the ordinary examine
; (ExamineObject: "There seem to be some symbols on it but <subject> cannot
; read them."). When Elrond reads it, he reveals the exit that InitNewGame
; erased at the start of the game: the erased exit triple is put back in its
; location record and he says "Go <direction> from <place> to get to <place>"
; (observed: "SAY TO ELROND READ MAP" in the endgame run).
;
; The blocked-exit record (BlockedExits: location, exit triple address, saved
; triple) is the operand of the instruction at $A7CF, which 97CF patched. The
; restore happens while ExitRestoreMode is 0 (it is never set to anything
; else).
;
; Hardware: none (the text goes through the message printer).
ExamineMap:
  LD A,(Subject)          ; the subject
  CP CHR_ELROND
  JP NZ,ExamineObject     ; not Elrond: plain examine
  CALL CommitOrAbort      ; only when performed for real
SmcBlockedExit:
  LD IY,$0000             ; record of the blocked exit (patched by 97CF)
  LD L,(IY+$01)           ; HL = address of the exit triple in the location
                          ; record
  LD H,(IY+$02)
  LD A,(ExitRestoreMode)  ; ExitRestoreMode
  CP $00
  JR NZ,ExamineMap_0      ; not 0: do not restore
  LD B,$03                ; copy the saved triple (direction, obstacle,
                          ; destination) back
ExamineMap_Restore:
  LD A,(IY+$03)
  LD (HL),A
  INC HL
  INC IY
  DJNZ ExamineMap_Restore
  LD IY,(SmcBlockedExit+$0002) ; IY = the record again
ExamineMap_0:
  LD A,(IY+$05)           ; destination
  CALL FindLocation       ; IX = destination location record
  INC IX                  ; IX = its name phrase (+2)
  INC IX
  PUSH IX
  LD A,(IY+$00)           ; location of the exit
  CALL FindLocation
  INC IX
  INC IX
  PUSH IX                 ; its name phrase
  LD A,(IY+$03)           ; direction id
  CALL GetIdWord          ; DE = direction word
  PUSH DE
  LD HL,MsgGoFromGet      ; "Go <word> from <thing> to get to <thing>"
  JP PrintSpeech

; Handlers (via $C378): $A814, $A876, $A89E, $A8AB
LA814:
  LD A,(SecondObject)
  CALL FindExitByObstacle_0
  CP $FF
  JP Z,RefuseCommand
  CALL CommitOrAbort
  LD HL,MsgSailsAcross
  CALL PrintMessage
  LD A,(Obj29BoatLocation)
  CP (IX+$02)
  JR NZ,LA814_1
  CALL LA814_3
  JR C,LA814_0
  LD HL,MsgFallsJustShortOther
  CALL LA814_3
  JR C,LA814_2
  LD HL,MsgLandsBoatButSlidesOut
  JR LA814_2
LA814_0:
  LD A,$12
  LD (Obj29BoatHolder),A
  LD HL,MsgLandsBoat
  JR LA814_2
LA814_1:
  LD HL,MsgFallsJustShortOther
  CALL LA814_3
  JR C,LA814_2
  LD A,(IX+$02)
  LD IX,(Noun1Record)
  LD (IX+$10),A
  LD (IX+$01),$FF
  LD A,(FirstObject)
  CALL MoveCarried
  LD HL,MsgLandsOnOtherSide
LA814_2:
  JP PrintMessage
LA814_3:
  LD A,$64
  CALL RandomUpTo
  CP $32
  RET
LA814_4:
  CALL CommitOrAbort
  LD A,(Obj29BoatHolder)
  CP $12
  RET NZ
  LD HL,MsgBoatGlidesAcrossRiver
LA814_5:
  CALL PrintMessage
  LD A,(Obj29BoatLocation)
  CP $42
  LD A,$42
  JR NZ,LA814_6
  LD A,$43
LA814_6:
  LD (Obj29BoatLocation),A
  LD B,A
  LD A,$FF
  LD (Obj29BoatHolder),A
  LD A,$29
  JP MoveCarried
LA814_7:
  CALL AbortUnlessPerform
  LD A,(Subject)
  AND A
  RET NZ
  LD HL,MsgWithLurchBoatGlides
  JR LA814_5
LA814_8:
  LD A,(ActorHasOrder)
  CP $01
  RET NZ
  SUB A
  LD (ActorHasOrder),A
  INC A
  CALL RunStoredOrder
  RET Z
  SUB A
  LD (ActionAllowed),A
  LD A,(SavedCommandId)
  LD (BardCommandVerb),A
  LD BC,(FirstObject)
  LD (BardCommandArgs),BC
  LD A,$42
  LD (BardCommandOp),A
  RET

; Gollum asks his riddle
;
; Script handler (op 3, in Gollum's script ScriptC9F7). When Gollum is where
; the player is and the player is visible (not wearing the ring: flag bit 7 of
; the player is set) the test pass accepts and Gollum says the riddle chosen at
; the start of the game (RandomEventPtr: the message word at +2 of the record
; in RandomEvents; the riddle of the dark or the riddle of the animal with four
; feet). It sets ReplyGiven to 1, so that the answer is looked for by LA8F6.
; Otherwise it returns before the test pass accepts and the script takes its
; alternative step (ScriptCA10).
;
; Hardware: none (the text goes through the message printer).
GollumAsksRiddle:
  LD A,(Chr44GollumLocation) ; Gollum's location
  LD HL,PlayerLocation    ; player's location
  CP (HL)
  RET NZ                  ; not together: refuse
  LD HL,Chr00PlayerFlags
  BIT FLAG_PRESENT,(HL)   ; player invisible: refuse
  RET Z
  CALL CommitOrAbort
  LD HL,(RandomEventPtr)  ; the chosen random event
  INC HL                  ; skip the phrase code
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  PUSH DE
  POP HL
  CALL PrintSpeech        ; say the riddle
  LD A,$01
  LD (ReplyGiven),A       ; ReplyGiven := 1: waiting for the answer
  RET

; Handler (via $C9FE)
LA8F6:
  CALL CommitOrAbort
  SUB A
  LD (ReplyGiven),A
  CALL RunStoredOrder
  JR Z,LA8F6_1
  LD BC,$0018
  LD DE,(RandomEventPtr)
  LD A,(DE)
LA8F6_0:
  CPIR
  JR NZ,LA8F6_1
  INC DE
  LD A,(DE)
  DEC DE
  CP (HL)
  JR NZ,LA8F6_0
  RET
LA8F6_1:
  CALL CommitOrAbort
  LD A,$01
  LD (MessagesVisible),A
  LD HL,MsgSomeoneStranglesFrom
  CALL PrintMessage
  JP EndGame

; Gollum mutters about his pockets
;
; Script handler (op 3, in Gollum's script ScriptCA14). When Gollum is where
; the player is, he says one of two things. A random number from 0 to 8 that is
; not negative (the carry left by RandomUpTo is clear), or Gollum holding the
; golden ring, gives "What has it got in its pockets ?"; otherwise (the ring is
; not with him) "My birthday present - how did we lose it. My precious". When
; he is elsewhere it returns before the test pass accepts, and the script takes
; its alternative step (ScriptC9F7).
;
; Hardware: none (the text goes through the message printer).
GollumTalks:
  LD A,(Chr44GollumLocation) ; Gollum's location
  LD HL,PlayerLocation
  CP (HL)
  RET NZ                  ; not together: refuse
  CALL CommitOrAbort
  LD HL,MsgWhatHasGotPockets ; "What has it got in its pockets ?"
  LD A,$08                ; random 0 to 8
  CALL RandomUpTo
  JP NC,PrintSpeech       ; carry clear: say it
  LD IX,Obj10ValuableGoldenRing ; the golden ring
  LD A,CHR_GOLLUM
  CP (IX+$01)             ; held by Gollum?
  JP Z,PrintSpeech        ; yes: the same words
  LD HL,MsgMyBirthdayPresentHow ; "My birthday present - how did we lose it. My
                                ; precious"
  JP PrintSpeech

; Handlers (via $CA42-$CA54): $A94E, $A971
LA94E:
  LD A,(ActorLocation)
  LD HL,PlayerLocation
  CP (HL)
  RET NZ
  CALL CommitOrAbort
  LD A,$1B
  LD (CommandId),A
  LD A,$00
  LD (FirstObject),A
  LD A,$FF
  LD (SecondObject),A
  CALL RefuseCommand
  CALL L929C_0
  JP EndGame
LA94E_0:
  CALL CommitOrAbort
  LD A,$47
  CALL KillCharacter
  LD A,$48
  CALL KillCharacter
  LD HL,Chr47TrollFlags
  RES 7,(HL)
  LD HL,Chr48TrollFlags
  RES 7,(HL)
  LD HL,MsgClearingWithTwoStone
  LD (Loc00None_0),HL
  LD HL,Loc05TrollsClearing
  RES 6,(HL)
  LD A,$47
  CALL EmptyHolder
  LD A,$48
  CALL EmptyHolder
  LD HL,MsgDayDawns
  LD A,$01
  LD (MessagesVisible),A
  CALL PrintMessage
  LD IX,PictureTable
  LD A,$05
  CALL FindIdRecord
  LD L,(IX+$01)
  LD H,(IX+$02)
  LD (HL),$05
  INC HL
  LD (HL),$28
  RET

; The trolls talk about cooking the player
;
; Script handler (op 3, in the script ScriptCA3B of both trolls). When the
; player is at the trolls clearing (LOC_TROLLS_CLEARING) the speaking troll
; says "Blimey, look at this!! Can yer cook'em?" (the hideous troll) or "Yer
; can try, but he wouldn't make above a mouthfull" (the vicious troll).
; Elsewhere it returns before the test pass accepts, and the script repeats.
;
; Hardware: none (the text goes through the message printer).
TrollsTalk:
  LD A,(PlayerLocation)   ; player's location
  CP LOC_TROLLS_CLEARING
  RET NZ                  ; not at the clearing: refuse
  CALL CommitOrAbort
  LD A,(Subject)          ; the troll speaking
  LD HL,MsgBlimeyLookAtThisCan ; "Blimey, look at this!! Can yer cook'em?"
  CP CHR_HIDEOUS_TROLL
  JR Z,TrollsTalk_0
  LD HL,MsgYerCanTryButHe ; "Yer can try, but he wouldn't make above a
                          ; mouthfull"
TrollsTalk_0:
  JP PrintSpeech

; Victory check, once per turn
;
; Called at the start of every turn (L96B3). Does nothing unless the valuable
; treasure (OBJ_VALUABLE_TREASURE) is held by the wooden chest
; (OBJ_WOODEN_CHEST). Then prints the ending ("a cheering crowd of dwarves,
; hobbits and elves appears. Led by gandalf they carry you off into the sunset,
; proclaiming you hero of heroes and master adventurer !!!") and goes to the
; end of the game at EndGame_Wait: the score, a key and the restart.
;
; Hardware: none.
CheckVictory:
  LD A,(Obj23TreasureHolder) ; holder of the treasure
  CP OBJ_WOODEN_CHEST
  RET NZ                  ; not in the chest yet
  LD HL,MsgCheeringCrowdDwarves ; the ending text
  CALL PrintMessage
  JP EndGame_Wait         ; wait for a key and restart (EndGame_Wait)

; Handlers (via $C9A1): $A9E5 and following to the end of the code region
LA9E5:
  LD A,(ActorLocation)
  LD HL,PlayerLocation
  CP (HL)
  RET NZ
  LD IX,Obj26Lunch
  LD A,(IX+$10)
  CP $00
  JR Z,LA9E5_0
  LD A,$41
  CP (IX+$01)
  RET NZ
LA9E5_0:
  CALL CommitOrAbort
  LD A,(ActorLocation)
  LD (IX+$10),A
  LD (IX+$01),$41
  LD BC,$0026
  LD (FirstObject),BC
  LD A,$1D
  LD (CommandId),A
  LD (Noun1Record),IX
  LD HL,Chr00Player
  LD (Noun2Record),HL
  CALL RefuseCommand
  JP GiveObject
LA9E5_1:
  LD IY,(Noun1Record)
  LD A,(IY+$10)
  LD B,A
  CALL FindExitByDestination
  CP $FF
  LD HL,MsgCannotJumpOntoFrom
  JP Z,PrintMessage
  LD A,(IX+$00)
  CP $0A
  JP NZ,MsgCannotJumpOntoFrom
  CALL CommitOrAbort
  LD A,(FirstObject)
  LD IX,(ActorRecord)
  LD (IX+$01),A
  CALL MoveCarried
  LD A,(Subject)
  CP $00
  RET NZ
  LD A,B
  JP DescribeLocation
LA9E5_2:
  LD IX,Obj07SpiderWeb
  RES 3,(IX+$07)
  RES 5,(IX+$07)
  SLA (IX+$05)
  LD DE,$0623
  LD (Obj07WebOff0A),DE
  RET
LA9E5_3:
  LD HL,Obj0BDoorFlags
  BIT 5,(HL)
  RET NZ
  LD A,(Timer9Start)
  LD (Timer9Counter),A
  LD HL,Obj0BDoorFlags
  RES 7,(HL)
  LD A,(Chr00PlayerLocation)
  CP $2A
  RET NZ
LA9E5_4:
  LD HL,MsgHoleVanishes
  JP PrintMessage
LA9E5_5:
  LD HL,Obj0BDoorFlags
  SET 7,(HL)
  LD A,(Chr00PlayerLocation)
  CP $2A
  RET NZ
  LD HL,MsgThereLoudCrackHole
  JP PrintMessage
LA9E5_6:
  CALL AbortUnlessPerform
  LD A,$06
  LD (Timer9Counter),A
  LD HL,Obj0BDoorFlags
  SET 0,(HL)
  RES 7,(HL)
  JR LA9E5_4
LA9E5_7:
  LD HL,Obj0DDoorFlags
  SET 5,(HL)
  LD HL,MsgMagicDoorOpens
  CALL LA9E5_8
  LD HL,MsgElfSweepsPast
  CALL LA9E5_8
  JP LA9E5_10
LA9E5_8:
  LD A,(Chr00PlayerLocation)
  CP $1E
  JP Z,PrintMessage
  CP $1C
  JP Z,PrintMessage
  RET
LA9E5_9:
  LD HL,Obj0DDoorFlags
  RES 5,(HL)
  LD HL,MsgMagicDoorCloses
  JP LA9E5_8
LA9E5_10:
  LD IX,Obj10ValuableGoldenRing
  LD A,(IX+$01)
  CP $FF
  RET Z
  CALL FindObject
  LD (ActorRecord),IX
  BIT 7,(IX+$07)
  JP Z,LA377_1
  RET
LA9E5_11:
  LD A,(Subject)
  CP $00
  RET NZ
  LD A,$01
  LD (LispFlag),A
  LD A,(Timer7Start)
  LD (Timer7Counter),A
  RET
LA9E5_12:
  SUB A
  LD (LispFlag),A
  RET
LA9E5_13:
  LD A,(Chr00PlayerLocation)
  CP $1A
  RET NZ
  LD HL,MsgSpiderWebSlowly
  CALL PrintMessage
  JP EndGame
LA9E5_14:
  LD HL,MsgSeeSomePaleBulbous
  CALL PrintMessage
  LD A,(Chr00PlayerLocation)
  LD C,A
  LD HL,ArrivalLocation
  CP (HL)
  RET Z
  LD B,(HL)
  LD A,$02
  CP B
  JR NZ,LA9E5_15
  LD A,$03
LA9E5_15:
  CP C
  RET Z
  JR LA9E5_18
LA9E5_16:
  LD A,(Chr00PlayerLocation)
  CP $02
  JR Z,LA9E5_17
  CP $03
  RET NZ
LA9E5_17:
  LD HL,MsgSeeSomePaleBulbous
  CALL PrintMessage
LA9E5_18:
  LD HL,MsgSomeDropsFromAbove
  CALL PrintMessage
  JP EndGame
