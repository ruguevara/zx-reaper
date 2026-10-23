; Look: say where the actor is and what is around
;
; Default handler of the verb look (CMD_LOOK, id 23; VerbHandlers). When the
; actor lies at a location (holder AT_LOCATION) it describes the location with
; its picture and lists (DescribeLocation). When the actor is inside a holder
; (a barrel, a boat) it prints "<subj_is> <relation word> <holder name>." (for
; example "You are in the barrel."): the preposition slot of MsgSubjIsIn is
; blanked with an empty word item ($80,$00) and the relation word of the holder
; (PrintHolderRelation: In the, On the...) is printed in its place. Then
; "<subj> see :" and a list of what the holder holds at its location
; (ListObjects).
;
; Hardware: none directly; the location description may show a picture and wait
; for a key (DescribeLocation).
VerbLook:
  CALL CommitOrAbort      ; only when really performing
  LD IX,(ActorRecord)     ; the actor
  LD A,(IX+$01)           ; its holder
  CP AT_LOCATION
  JR Z,VerbLook_AtLocation ; lies at a location: describe it
  LD HL,$0080             ; empty word item ($80,$00): no preposition
  LD (MsgSubjIsIn+$0001),HL ; blank the preposition slot of the message
  LD HL,MsgSubjIsIn       ; "<subj_is>"
  CALL PrintMessage       ; print it
  PUSH IX                 ; keep the actor record
  LD A,(IX+$01)
  CALL FindObject         ; IX = record of the holder
  CALL PrintHolderRelation ; "In the" / "On the"... by the holder's state
  LD E,(IX+$08)           ; name phrase of the holder (+8, +9) without the
                          ; print mode nibble
  LD A,(IX+$09)
  AND $0F
  LD D,A
  CALL PrintWord          ; print the holder's name
  LD A,CHAR_FULLSTOP
  CALL PrintChar          ; "."
  CALL PrintNewLine       ; new line
  LD HL,MsgSee2           ; "<subj> see :"
  CALL PrintMessage
  POP IX                  ; the actor again
  LD A,(IX+$01)           ; A = the holder
  LD B,(IX+$10)           ; B = where the holder is
  JP ListObjects          ; list what it holds there
VerbLook_AtLocation:
  LD A,(IX+$10)           ; the actor's location
  JP DescribeLocation     ; describe it (with picture)

; Require the first object to be held by the subject
;
; Checks with CheckObject1Held that the subject carries the first object. If it
; does, returns. If not, drops its own return address, so that the handler that
; called it ends at once, and prints "<subject> not carrying it." Used by the
; drop handler VerbDrop.
;
; Hardware: none.
;
; O:F Carry set when the object is held (otherwise the caller's caller gets
;     control)
RequireHeld:
  CALL CheckObject1Held   ; held by the subject?
  RET C
  POP HL                  ; no: discard the return address,
  LD HL,MsgNotCarrying    ; "{SUBJ_IS} not carrying it."
  JP PrintMessage         ; print it and return to the handler's caller

; Drop the first object
;
; Default handler of the verb drop (id 13; VerbHandlers). Refuses with "<subj>
; not carrying it." unless the subject holds the first object (RequireHeld).
; The thing dropped is the first object, except that an object tied to the rope
; (its holder is OBJ_ROPE) drops the rope instead, as in take (VerbTake). The
; dropped record's holder becomes the holder of the actor, so it lies at the
; location (AT_LOCATION) or stays in the barrel or boat the actor is in; its
; location slot already follows the actor (MoveContents). A consumable thing
; (flag bit 1: liquids) is destroyed: its location is set to 0 and "<thing>
; evaporates." is printed.
VerbDrop:
  CALL RequireHeld        ; held by the subject, else the caller's caller
                          ; returns
  CALL CommitOrAbort      ; only when really performing
  LD IX,(Noun1Record)     ; the first object
  LD A,(IX+$01)           ; its holder
  CP OBJ_ROPE
  JR NZ,VerbDrop_0        ; tied to the rope?
  LD IX,Obj12Rope         ; then the rope is what drops
VerbDrop_0:
  PUSH IX                 ; keep the record to drop
  LD IX,(ActorRecord)     ; the actor
  LD A,(IX+$01)           ; its holder
  POP IX                  ; the record to drop
  LD (IX+$01),A           ; now held by the actor's holder
  BIT FLAG_CONSUMABLE,(IX+$07)
  RET Z                   ; not consumable: done
  LD (IX+$10),$00         ; consumable: nowhere any more
  LD HL,MsgEvaporates     ; "<thing> evaporates."
  LD DE,$0008             ; IX+8 = the name phrase of the thing...
  ADD IX,DE
  PUSH IX                 ; ... as the message's argument
  CALL PrintMessage
  RET

; Command handler (via $C730)
L8CE0:
  LD A,(FirstObject)
  LD HL,SecondObject
  CALL CheckObject1Held_0
  LD HL,MsgNot
  JP NZ,PrintMessage
  JR VerbTake_0

; Check that the subject can lift and carry the first object
;
; Three tests on the first object (Noun1Record) for the actor (ActorRecord). 1.
; Its bulk (record +3, plus everything inside it, SumHeldBulk; capped at $FF)
; must not exceed the actor's own +3, the biggest load the actor can lift: else
; prints "<obj1> is too heavy to lift." 2. What is left of that capacity after
; the bulk of everything the subject already carries must not go negative: else
; prints "<subject> carrying too much." 3. The object must have a single place
; (CheckSinglePlace: doors, rivers and webs have several) and bit 1 of its
; record flags (+7) must be clear; otherwise the command is refused
; (RefuseCommand). The failing cases drop the return address, so the handler
; that called this routine ends at once. $8D25 is the entry for the last test
; only, used by PutObjectIn.
;
; Hardware: none.
;
; O:IX Record of the first object (when it returns)
CheckCanCarry:
  LD IX,(Noun1Record)     ; first object
  LD A,(FirstObject)
  CALL SumHeldBulk        ; bulk of what is inside it
  ADD A,(IX+$03)          ; plus its own bulk
  JR NC,CheckCanCarry_0
  LD A,$FF                ; cap at 255
CheckCanCarry_0:
  LD B,A
  LD IY,(ActorRecord)     ; the actor
  LD A,(IY+$03)           ; the actor's capacity
  SUB B
  LD HL,MsgTooHeavyLift   ; "{OBJ1} is too heavy to lift."
  JR C,CheckCanCarry_1
  PUSH AF
  LD A,(Subject)
  CALL SumHeldBulk        ; bulk of what the subject carries
  LD B,A
  POP AF
  SUB B
  JP P,CheckCanCarry_Single
  LD HL,MsgCarryingTooMuch ; "{SUBJ_IS} carrying too much."
CheckCanCarry_1:
  EX (SP),HL              ; discard the return address
  POP HL                  ; HL := message
  JP PrintMessage         ; print it, return to the handler's caller
; This entry point is used by the routine at PutObjectIn.
CheckCanCarry_Single:
  CALL CheckSinglePlace   ; single place?
  JR NZ,CheckCanCarry_2
  BIT 1,(IX+$07)
  RET Z                   ; fine
CheckCanCarry_2:
  POP HL
  JP RefuseCommand        ; refuse

; Take or carry an object (default handler of the verbs take and carry)
;
; Verb ids $13 (take) and $3B (carry) in VerbHandlers. The subject (Subject)
; takes the first object. Prints "<subject> already carrying <obj1>." when it
; already holds it (CheckObject1Held). Then CheckCanCarry checks weight and
; kind. The command is refused (RefuseCommand) when the first object is
; something the subject is itself in or on: the walk goes up the chain of
; holders of the subject looking for the first object. When the command is
; really performed (CommitOrAbort) the first object's holder (+1) becomes the
; subject. If its holder was the rope (OBJ_ROPE; apparently the object is tied
; to it), the rope's own holder ($C367) is set instead, so the rope comes with
; the subject.
;
; Hardware: none.
VerbTake:
  CALL CheckObject1Held   ; already held?
  LD HL,MsgAlreadyCarrying ; "{SUBJ_IS} already carrying {OBJ1}."
  JP C,PrintMessage
VerbTake_0:
  CALL CheckCanCarry      ; can the subject lift and carry it?
  LD A,(Subject)          ; the subject
VerbTake_Up:
  CALL FindObject         ; record of A
  LD A,(FirstObject)
  CP (IX+$01)             ; is the first object this one's holder?
  JP Z,RefuseCommand      ; yes: refuse
  LD A,(IX+$01)           ; go up to the holder
  CP AT_LOCATION
  JR NZ,VerbTake_Up
  LD IX,(Noun1Record)     ; the first object
  CALL CommitOrAbort      ; only when really performing
  LD A,(IX+$01)
  CP OBJ_ROPE             ; tied to the rope?
  LD A,(Subject)          ; the subject
  JR Z,VerbTake_1
  LD (IX+$01),A           ; the object is now held by the subject
  RET
VerbTake_1:
  LD (Obj12Rope+$0001),A  ; the rope is held by the subject (holder field of
                          ; the rope record $C366)
  RET

; Score for the first visit to a location (14 records)
;
; Records of 3 bytes: location id, score value (word, in tenths of a per cent);
; FF ends. When the player first arrives at a location (ActorArrives marks it
; with LOC_VISITED), the location is looked up with FindIdRecord and its value
; is added to the score ($B6F7).
FirstVisitScores:
  DEFB $04
  DEFW $0019
  DEFB $07
  DEFW $0032
  DEFB $0B
  DEFW $0019
  DEFB $16
  DEFW $0019
  DEFB $0D
  DEFW $004B
  DEFB $41
  DEFW $0032
  DEFB $1B
  DEFW $0019
  DEFB $1C
  DEFW $0019
  DEFB $1F
  DEFW $0032
  DEFB $22
  DEFW $0064
  DEFB $26
  DEFW $0019
  DEFB $2A
  DEFW $0019
  DEFB $2B
  DEFW $0032
  DEFB $29
  DEFW $00C8
  DEFB $FF

; Variables of the take routine ($8D9D)
TakeObject:
  DEFW $0000
TakeId:
  DEFB $00
TakeWeight:
  DEFB $00

; Move the actor in a direction
;
; Default handler (VerbHandlers) of the ten direction verbs (go north ... go
; down; CommandId holds DIR_NORTH to DIR_DOWN), also entered by run (VerbRun).
; The actor is the Subject: the player or an NPC acting from its script. It has
; three parts: $8D9D chooses the direction, MoveActor moves through the exit
; and ActorArrives is the arrival.
;
; Direction: in the dark (CheckDark) the player cannot choose; CommandId
; becomes a random direction 1-10. A way out of a holder is refused unless the
; holder is a character (then the actor is set free of it); an actor inside a
; barrel or a boat cannot walk. TakeWeight is what the actor weighs plus what
; it carries (SumHeldWeight). The exit comes from FindExitByDirection. Without
; an exit (or with destination 0) the command is refused (RefuseCommand:
; "<subj> cannot go north."); but in the dark the player blunders into a wall:
; the player's strength (record +5) is halved, "But fall and hit your head.",
; and when the halving leaves 0, "But fall and smash your skull." and the game
; ends (EndGame).
;
; Obstacle: CheckPassage tests the exit's obstacle and the destination's
; capacity. Blocked: refused. Too small or too full: "<the thing> is too small
; (full) for <subj> to enter." (the too small message takes its word from
; record bytes +2,+3 of the obstacle, its weight, which is a bug: it prints a
; wrong word; see the findings).
;
; Arrival (ActorArrives, also entered by MoveCarried for a player carried to a
; new place, with TakeId and B set): when really performing, the actor's
; location slot (record +$10) becomes B, what it carries comes along
; (MoveCarried) and an NPC is done (its movement is shown by AnnounceArrival).
; For the player the arrival handler of the destination runs (ArrivalHandlers),
; and unless it is dark the destination is described: the first time (location
; flag LOC_VISITED not yet set) the flag is set, the score is raised by the
; value found for the location id in FirstVisitScores (that table is keyed by
; location id, not by treasure) and the full description with picture follows
; (DescribeLocation); a visited location gets the short one
; (DescribeLocationShort).
;
; Hardware: none directly; the description may show a picture and wait for a
; key.
;
; B New location id ($8E12 only)
; IY Record of the actor ($8E12 only; MoveCarried enters with the IY of its own
;    caller)
VerbMove:
  CALL CheckDark          ; dark?
  JR NC,MoveActor         ; no: keep the direction
  LD A,DIR_DOWN-$01       ; in the dark: a random direction...
  CALL RandomUpTo         ; ... 0-9...
  INC A                   ; ... plus 1: 1-10
  LD (CommandId),A        ; CommandId := the random direction

; Move the actor through the exit in CommandId
;
; Entry point of the walk: move the actor in direction CommandId. WalkToExit
; joins here after it has made the direction of an exit the verb.
MoveActor:
  LD IY,(ActorRecord)     ; the actor's record
  LD A,(IY+$01)           ; its holder
  CP AT_LOCATION
  JR Z,MoveActor_0        ; lies at a location: can walk
  CALL FindObject         ; IX = record of the holder
  BIT FLAG_CHARACTER,(IX+$07)
  JR Z,MoveActor_NoWay    ; holder is not a character (barrel, boat): cannot
                          ; walk
  LD (IY+$01),AT_LOCATION ; set free of the character holding it
MoveActor_0:
  LD A,(Subject)          ; the subject
  CALL SumHeldWeight      ; weight of what it carries
  ADD A,(IY+$02)          ; plus its own weight
  LD (TakeWeight),A       ; TakeWeight
  LD A,(CommandId)        ; the direction
  CALL FindExitByDirection ; the exit of its location
  CP END_MARK
  JR NZ,MoveActor_1       ; found
; No way out: refuse; in the dark hit the head.
MoveActor_NoWay:
  CALL CheckDark          ; dark?
  JP NC,RefuseCommand     ; no: "<subj> cannot go <dir>."
  CALL CommitOrAbort      ; only when really performing
  LD IX,Chr00Player       ; the player
  AND A                   ; carry clear
  LD HL,MsgButFallHitHead ; "But fall and hit your head."
  RR (IX+$05)             ; halve the player's strength (+5)
  JP NZ,PrintMessage      ; still above 0: print it
  LD HL,MsgButFallSmashSkull ; "But fall and smash your skull."
  CALL PrintMessage       ; print it
  JP EndGame              ; the game ends: "... is dead."
MoveActor_1:
  LD A,(IX+EXIT_DEST)     ; destination
  AND A
  JR Z,MoveActor_NoWay    ; none: no way
  LD (TakeId),A           ; TakeId := destination
  LD A,(IX+EXIT_OBSTACLE) ; the obstacle
  CALL CheckPassage       ; may the actor pass?
  DEC A                   ; PASS_BLOCKED: no way
  JR Z,MoveActor_NoWay
  DEC A                   ; PASS_TOO_SMALL
  JR Z,ActorArrives_2
  DEC A                   ; PASS_TOO_FULL
  JR Z,ActorArrives_3

; The actor arrives at the destination
;
; Entry point of the arrival: the actor is at its destination B (also
; MoveCarried). Moves the actor, announces the place to the player.
ActorArrives:
  CALL CommitOrAbort      ; only when really performing
  LD (IY+$10),B           ; the actor's location := destination
  LD A,(Subject)          ; the subject...
  CALL MoveCarried        ; ... takes what it carries along
  LD A,(Subject)          ; an NPC is done here
  CP PLAYER
  RET NZ
  LD IX,ArrivalHandlers   ; arrival handlers of the player
  LD A,(TakeId)           ; destination id
  CALL FindIdRecord
  JR Z,ActorArrives_0     ; none for it
  LD L,(IX+$01)           ; the handler's address...
  LD H,(IX+$02)
  CALL CallHandler        ; ... called if not 0
ActorArrives_0:
  CALL CheckDark          ; dark? (nothing is described)
  RET C                   ; yes: done
  LD A,(Subject)          ; the subject
  AND A
  LD A,(TakeId)           ; A = destination id
  JR NZ,ActorArrives_Describe ; never taken: here the subject is the player
  LD HL,(TakeObject)      ; the destination's location record
  BIT LOC_VISITED,(HL)
  JP NZ,DescribeLocationShort ; visited before: short description
  SET LOC_VISITED,(HL)    ; first visit: mark it
  PUSH AF
  LD IX,FirstVisitScores  ; score values of first visits
  CALL FindIdRecord       ; keyed by location id
  JR Z,ActorArrives_1
  PUSH DE                 ; DE = value; add it to the score
  LD E,(IX+$01)
  LD D,(IX+$02)
  LD HL,(Score)
  ADD HL,DE
  LD (Score),HL
  POP DE
ActorArrives_1:
  POP AF                  ; destination id
ActorArrives_Describe:
  JP DescribeLocation     ; describe the place, with picture
ActorArrives_2:
  LD HL,MsgTooSmallForEnter ; "<the_arg> is too small for <subj> to enter."
  JR ActorArrives_4       ; to the common end
ActorArrives_3:
  LD IX,(TakeObject)      ; the destination's record
  LD HL,MsgTooFullForEnter ; "<the_arg> is too full for <subj> to enter."
ActorArrives_4:
  PUSH HL                 ; message under the argument...
  LD L,(IX+$02)           ; ... the word at record +2, +3 (the destination's
                          ; name; for the obstacle its weight: bug)
  LD H,(IX+$03)
  EX (SP),HL              ; stack: that word; HL = message
  CALL PrintMessage       ; print
  RET

; Check whether the subject can pass an obstacle and enter the destination
;
; Part of moving (VerbMove, WalkToExit). Uses the variables of the take routine
; set by the mover: TakeId (the destination location id), TakeWeight (the
; weight the subject adds to the destination: its own +2 plus what it carries,
; SumHeldWeight). With an obstacle id (the exit's obstacle byte) it tests the
; obstacle's record: flag bits 5 (active) and 3 (dead or disabled) both clear
; stops the traveller (PASS_BLOCKED), so does bit 7 of the state byte (+4) when
; the subject is the player; then TakeWeight must be below the obstacle's +2 or
; the result is PASS_TOO_SMALL. Then, with or without an obstacle, the
; destination: TakeObject gets its record, and unless its capacity (+1) is $FF
; (unlimited), what is left of the capacity after the weights of the objects
; lying there (LocationSpareCapacity) must exceed TakeWeight, or the result is
; PASS_TOO_FULL.
;
; Hardware: none.
;
;   A Obstacle id, 0 for none
; O:A 0 can pass, PASS_BLOCKED, PASS_TOO_SMALL or PASS_TOO_FULL
; O:F Z set when it can pass
; O:IX Record of the obstacle (PASS_BLOCKED, PASS_TOO_SMALL) or of the
;      destination (PASS_TOO_FULL)
CheckPassage:
  AND A
  JR Z,CheckPassage_1     ; no obstacle
  CALL FindObject         ; obstacle record
  LD A,(IX+$07)
  AND $28                 ; active or dead/disabled bit
  JR Z,CheckPassage_5     ; neither: blocked
  LD A,(Subject)
  AND A
  JR NZ,CheckPassage_0    ; not the player
  BIT 7,(IX+$04)          ; the player is stopped by state bit 7
  JR NZ,CheckPassage_5
CheckPassage_0:
  LD A,(TakeWeight)       ; TakeWeight
  LD B,(IX+$02)           ; the obstacle's capacity
  SUB B
  JR NC,CheckPassage_4    ; weight not below it: too small
CheckPassage_1:
  LD A,(TakeId)           ; TakeId
  LD B,A
  CALL FindLocation       ; destination record
  LD (TakeObject),IX      ; TakeObject
  LD A,END_MARK
  CP (IX+$01)             ; unlimited capacity?
  JR Z,CheckPassage_2
  LD A,B
  CALL LocationSpareCapacity ; room left in the destination
  LD C,A
  LD A,(TakeWeight)
  SUB C
  JR NC,CheckPassage_3    ; weight not below the room: too full
CheckPassage_2:
  XOR A
  RET                     ; can pass
CheckPassage_3:
  LD A,PASS_TOO_FULL
  AND A
  RET
CheckPassage_4:
  LD A,PASS_TOO_SMALL
  AND A
  RET
CheckPassage_5:
  LD A,PASS_BLOCKED
  AND A
  RET

; Test whether an object is shut in by a closed holder
;
; Follows the chain of holders (record +1) upward from the object in A through
; holders whose flag bit 5 (active, open, alive) is set. Reaching an object
; that lies at a location (holder AT_LOCATION) means it is in the open. A
; holder with bit 5 clear stops the chain. VerbLookThrough calls it for the
; subject (an actor) and returns when the answer is NZ.
;
; A Object id O:F Z set when the chain ends at a location, NZ when a holder
; with bit 5 clear is met O:A AT_LOCATION when Z; the id of that holder OR 1
; when NZ Preserves IX.
CheckEnclosed:
  PUSH IX
  CALL FindObject         ; IX := record of A
CheckEnclosed_Next:
  LD A,(IX+$01)           ; holder id
  CP AT_LOCATION
  JR Z,CheckEnclosed_0
  CALL FindObject         ; IX := record of the holder
  BIT FLAG_ACTIVE,(IX+$07)
  JR NZ,CheckEnclosed_Next
  OR $01                  ; make A non-zero: NZ
CheckEnclosed_0:
  POP IX
  RET

; Look through the first object into the place beyond
;
; Handler of look through (id 24), reached from the verb tables of doors and
; windows (for example LA761). The first object must be open (CheckOpen; else
; "<it> is closed.") and the subject must not be shut in (CheckEnclosed:
; returns silently). The exit whose obstacle is the first object
; (FindExitByObstacle) gives the place beyond; no such exit or destination 0:
; refused. When really performing, the subject's location slot is set to that
; place for the time of the description "<subj> see ..." with its picture
; (DescribeSeen) and then put back. The test for a dark place beyond ("It is
; dark.") reads the wrong location: see the comment at $8F14.
;
; Hardware: none directly; the description may show a picture and wait for a
; key.
VerbLookThrough:
  LD A,(FirstObject)      ; the first object
  CALL FindObject         ; its record
  CALL CheckOpen          ; open?
  JP Z,PrintStateIX       ; no: "<it> is closed."
VerbLookThrough_0:
  LD A,(Subject)          ; the subject
  CALL CheckEnclosed      ; shut in by a closed holder?
  RET NZ                  ; yes: nothing
  CALL FindExitByObstacle ; the exit this object blocks
  CP END_MARK
  JP Z,RefuseCommand      ; none: refuse
  LD A,(IX+$02)           ; its destination
  CP $00
  JP Z,RefuseCommand      ; none: refuse
  CALL CommitOrAbort      ; only when really performing
  PUSH IX                 ; keep the exit
; BUG: A is the perform flag (1) here, left by CommitOrAbort, not the
; destination, so this finds location 1 (Bag End, always lit) and the dark test
; below never fails.
  CALL FindLocation       ; the place beyond: location record
  BIT LOC_LIT,(IX+$00)    ; lit?
  POP IX                  ; the exit again
  JR Z,VerbLookThrough_Dark ; not lit: "It is dark."
  LD IY,(ActorRecord)     ; the actor
  LD A,(IY+$10)           ; its own location...
  PUSH AF                 ; ... kept
  LD A,(IX+$02)           ; the destination
  LD (IY+$10),A           ; is now the actor's location
  CALL DescribeSeen       ; "<subj> see" and the place
  POP AF                  ; the real location back
  LD (IY+$10),A
  RET
VerbLookThrough_Dark:
  LD HL,MsgDark           ; "It is dark."
  JP PrintMessage

; Command handler (via $C730): call $9F25
L8F3B:
  CALL FindExitByObstacle

; Walk through a given exit (follow, enter, go into)
;
; Common end of the handlers L8FCD (verbs enter and go into: the first object
; is the place to go to) and VerbFollow (follow). They call
; FindExitByDestination, which searches the exits of the current location for
; the one that leads to a wanted location. This routine refuses the command
; (RefuseCommand) when no exit was found (A = $FF), when the exit has no
; destination, or when CheckPassage says the obstacle or the destination stops
; the subject. Otherwise, when the command is really performed (CommitOrAbort),
; it makes the exit's direction the verb (CommandId), clears FirstObject and
; continues in the move handler at MoveActor, which does the walk as if the
; player had typed the compass direction.
;
; CheckPassage reads TakeId and TakeWeight, which only VerbMove sets, after the
; walk starts, so here they still have the values from the last move.
;
; Hardware: none.
;
; A Result of FindExitByDestination: $FF when no exit was found
; IX Exit record found (direction, obstacle, destination)
WalkToExit:
  CP END_MARK
  JP Z,RefuseCommand      ; no such exit
  LD A,(IX+EXIT_DEST)     ; destination
  CP $00
  JP Z,RefuseCommand
  LD A,(IX+EXIT_OBSTACLE) ; obstacle
  PUSH IX
  CALL CheckPassage
  POP IX
  JP NZ,RefuseCommand     ; blocked
  CALL CommitOrAbort      ; only when really performing
  LD A,(IX+$00)           ; the exit's direction
  LD (CommandId),A        ; becomes the verb
  LD A,AT_LOCATION
  LD (FirstObject),A      ; no first object
  JP MoveActor            ; move

; Command handler (via $C730)
L8F69:
  LD IX,(Noun1Record)
  LD A,(SecondObject)
  CP $17
  JR Z,L8F69_1
  CP $18
  JR Z,L8F69_2
L8F69_0:
  LD IY,(Noun2Record)
  BIT 1,(IY+$07)
  JP Z,RefuseCommand
  BIT 2,(IX+$07)
  LD A,$82
  JP NZ,PrintStateIX
  LD HL,PutObjectIn
  JP L9F4A
L8F69_1:
  LD A,$15
  LD IY,Obj15Water
  JR L8F69_3
L8F69_2:
  LD A,$16
  LD IY,Obj16BlackWater
L8F69_3:
  LD (SecondObject),A
  LD (Noun2Record),IY
  LD (IY+$01),$FF
  JR L8F69_0

; Run: move in a random direction that has an exit
;
; Default handler of run (id 36; VerbHandlers). Rolls a start direction with
; RandomUpTo(DIR_DOWN) (0 is rolled again), then tries it and each next
; direction (after DIR_UP it wraps to DIR_NORTH, so DIR_DOWN is only tried when
; it is rolled) until FindExitByDirection finds an exit of the actor's
; location. That direction becomes CommandId and the walk continues in
; VerbMove. A location with no exit in the directions 1-9 (the steep paths
; $4B-$4D have only down) loops here for ever unless 10 was rolled.
VerbRun:
  LD A,DIR_DOWN           ; random 0-10
  CALL RandomUpTo
  CP $00                  ; 0 is not a direction
  JR Z,VerbRun
VerbRun_Try:
  LD B,A                  ; B = the direction tried
  CALL FindExitByDirection ; is there an exit that way?
  CP B                    ; the same: take it
  JR Z,VerbRun_0
  LD A,B                  ; next direction
  INC A
  CP DIR_DOWN
  JR C,VerbRun_Try        ; below 10: try it
  LD A,DIR_NORTH          ; wrap round to north
  JR VerbRun_Try
VerbRun_0:
  LD (CommandId),A        ; CommandId := the direction
  JP VerbMove             ; and move

; Command handler (via $C730): call $9F2D with ($B6E8), jump to $8F3E
L8FCD:
  LD A,(FirstObject)
  CALL FindExitByDestination
  JP WalkToExit

; Follow: walk to where the first object is
;
; Default handler of follow (id 39; VerbHandlers). Takes the location of the
; first object. When it is the actor's own location, or when the actor's
; location has no exit leading there (FindExitByDestination), prints "I cannot
; follow <obj1> from here." Otherwise it walks through that exit like go into
; (WalkToExit).
VerbFollow:
  LD IX,(ActorRecord)     ; the actor
  LD B,(IX+$10)           ; B = where it is
  LD IX,(Noun1Record)     ; the first object
  LD A,(IX+$10)           ; A = where it is
  CP B
  JR Z,VerbFollow_0       ; the same place: cannot follow
  CALL FindExitByDestination ; the exit of the actor's location that leads
                             ; there
  CP END_MARK
  JP NZ,WalkToExit        ; found: walk through it
VerbFollow_0:
  LD HL,MsgICannotFollowFromHere ; "I cannot follow <obj1> from here."
  JP PrintMessage

; Command handler (via $C730)
L8FF5:
  CALL CheckCanCarry
  LD HL,VerbAttack
  LD A,$0F
  LD IX,(Noun2Record)
  BIT 6,(IX+$07)
  JR NZ,L8FF5_0
  LD HL,StrikeObject
  LD A,$0B
L8FF5_0:
  LD (CommandId),A
  CALL L9F4A
  LD A,$2A
  LD (CommandId),A
  LD A,(ActionPerform)
  CP $01
  RET NZ
  LD IX,(Noun1Record)
  LD (IX+$01),$FF
  LD A,$0F
  LD (CommandId),A
  LD A,(FirstObject)
  JP NotifyCharacter
  LD (IX+$01),$FF

; Handler for "talk to": the character takes some of the orders
;
; The default handler (VerbHandlers) of command 53, "talk to". The parser has
; already stored the orders typed after the name in order slots
; (ClaimOrderSlots); this decides how many of them the addressed character
; (FirstObject) obeys and calls ClaimOrderSlots with that number.
;
; A character with no NPC record obeys none. After a character has spoken to
; the player (ReplyGiven is set by GollumAsksRiddle) the reply is accepted: one
; order. Otherwise the NPC record's byte +6 is its obedience: 0 obeys none, any
; other value n obeys a random number of orders from 0 to n; when that comes
; out as 0 the character says "<obj1> says "No"".
;
; Only a real performance counts (CommitOrAbort drops out when the command is
; only being tried).
;
; FirstObject The character spoken to
TalkToCharacter:
  CALL CommitOrAbort      ; abandon unless performing
  LD A,(FirstObject)      ; the character
  CALL FindNpcState       ; its NPC record in IY
  CP END_MARK             ; no record?
  LD A,$00                ; (keeps the flags) no orders
  JR Z,TalkToCharacter_0
  LD A,(ReplyGiven)       ; ReplyGiven: 1 order when it just spoke
  CP $00
  JR NZ,TalkToCharacter_0
  LD A,(IY+$06)           ; obedience
  CP $00
  JR Z,TalkToCharacter_0  ; none: no orders
  CALL RandomUpTo         ; random number of orders 0 to obedience
  CP $00
  JR Z,TalkToCharacter_1  ; 0: refuse
TalkToCharacter_0:
  CALL ClaimOrderSlots    ; ClaimOrderSlots: keep A orders
  RET
TalkToCharacter_1:
  LD HL,MsgSaysNo         ; "<obj1> says "No""
  CALL PrintMessage
  SUB A                   ; no orders
  JR TalkToCharacter_0

; Command handler (via $C730)
L9065:
  CALL CommitOrAbort
  LD IX,(Noun1Record)
  BIT 5,(IX+$07)
  JP Z,OpenObject_0
  JP CloseObject_Clear
L9065_0:
  LD A,$19
  CALL CheckHeldBySubject
  LD HL,MsgNotCarryingBow
  JP NC,PrintMessage
  CALL CheckAttackAllowed
  CALL CommitOrAbort
  LD A,$0F
  LD (CommandId),A
  LD A,(Subject)
  CP $46
  JR Z,L9065_1
  LD A,(FirstObject)
  CP $3C
  LD HL,MsgArrowMissesByWide
  JP Z,PrintMessage
  LD A,$08
  CALL RandomUpTo
  CP $03
  JP C,PrintMessage
L9065_1:
  LD IX,Obj1AStrongArrow
  LD A,(FirstObject)
  CP $1A
  JR Z,L9065_2
  LD (IX+$01),$FF
L9065_2:
  LD HL,MsgArrowHits
  CALL PrintMessage
  LD IX,(Noun1Record)
  CALL LA1AE_2
  JP NZ,StrikeObject
  LD A,(FirstObject)
  CALL KillCharacter
  LD A,$06
  JP PrintStateIX

; End of the game: dead, or the ending text printed
;
; Entered when the player dies (KillCharacter KillCharacter) and from several
; handlers that kill the player. Sets the actor to the player and prints "You
; are dead.", then the score (PrintScore; the mark of how much of the adventure
; was done), waits for a key and restarts the game at RestartGame. The victory
; (CheckVictory) joins at EndGame_Wait after its own text.
;
; Hardware: reads the keyboard port $FE (all half-rows) in a polling loop.
EndGame:
  SUB A                   ; A = 0
  LD (Subject),A          ; actor = the player
  LD HL,MsgDead           ; "<subject> is dead."
  CALL PrintMessage
  CALL PrintScore         ; "You have mastered ..% Of this adventure."
; Entry point of CheckVictory (the victory): wait for any key.
EndGame_Wait:
  XOR A                   ; A = 0 selects every half-row
  IN A,(PORT_ULA)
  AND KEY_BITS
  CP KEY_BITS
  JR Z,EndGame_Wait
  JP RestartGame          ; restart the game

; Inventory: list what the subject carries
;
; Default handler of inventory (id 26; VerbHandlers). Prints "<subj_is>
; carrying." and then the objects held by the subject, or "Nothing" when it
; holds none present (the contents of held containers are listed with them,
; ListObjects).
VerbInventory:
  CALL CommitOrAbort      ; only when really performing
  LD HL,MsgCarrying       ; "<subj_is> carrying."
  CALL PrintMessage       ; print it
  LD A,(Subject)          ; the subject
  CALL CountHeldPresent   ; how many present things does it hold?
  AND A
  LD HL,MsgNothing        ; "Nothing"
  JP Z,PrintMessage       ; none: print it
  LD A,(Subject)          ; the subject is the holder...
  LD IX,(ActorRecord)     ; the actor
  LD B,(IX+$10)           ; B = where it is
  JP ListObjects          ; list what the subject holds

; Open the first object and show what is inside
;
; Common part of the open handlers (called from the handlers of doors, chests
; and others, for example OpenCrack; the object's own handler may do more after
; it). The reason why the first object cannot be opened (CheckOpenable: locked,
; or already open) is said with PrintStateIX ("The door is locked.").
; Otherwise, when really performing, the object gets the open flag
; (FLAG_ACTIVE). An object with one location (a container, not a door) then
; shows its contents: when it holds something present, PrintContentsHeader
; prints the line that introduces them ("In the chest there is") and
; ListObjects lists them.
OpenObject:
  CALL CheckOpenable      ; can it be opened?
  JP NZ,PrintStateIX      ; no: say why
  CALL CommitOrAbort      ; only when really performing
OpenObject_0:
  SET FLAG_ACTIVE,(IX+$07) ; open
  LD A,(IX+$00)           ; number of places of the object
  DEC A                   ; more than one (a door): done
  RET NZ
  LD A,(FirstObject)      ; the object
  CALL CountHeldPresent   ; how many present things does it hold?
  AND A
  RET Z                   ; none: done
  LD A,(FirstObject)      ; the object
  CALL PrintContentsHeader ; say what it holds
  RET C                   ; nothing to list
  LD B,(IX+$10)           ; B = where the object is
  LD A,(FirstObject)      ; the object is the holder
  JP ListObjects          ; list its contents

; Close the first object
;
; Verb handler of command 12, "close", in the verb tables of doors, chests and
; the like (and the shared close of LA67E and LA761). When the object is not
; open it says "<object> is closed" (state id 5, see PrintStateIX); otherwise
; it clears the open flag (bit 5 of the flags).
;
; Nothing changes unless the command is really performed (CommitOrAbort).
;
; Noun1Record Record of the object to close
CloseObject:
  LD IX,(Noun1Record)
  CALL CheckOpen          ; open?
  JP Z,PrintStateIX       ; no: "<it> is closed"
  CALL CommitOrAbort      ; abandon unless performing
CloseObject_Clear:
  RES FLAG_ACTIVE,(IX+$07) ; no longer open
  RET

; Refuse an attack between actors that share a side bit
;
; The victim is the record in Noun1Record, the attacker the record in
; ActorRecord (both loaded here). If the subject is the player (Subject = 0)
; and the victim has state bit 4 set, that bit is cleared first. Then the state
; bytes (+4) of the victim and the attacker are ANDed over bits 4-6: if they
; share a bit the attack is refused: the routine drops its own return address
; (so its caller returns to its own caller) and clears ActionAllowed. With no
; shared bit it returns normally, Z set. Used by the attack handler VerbAttack
; and by the handler at L9065.
;
; O:F Z set when the attack may go on (otherwise it does not return)
CheckAttackAllowed:
  LD IX,(Noun1Record)
  LD A,(Subject)          ; Subject: 0 = the player
  AND A
  JR NZ,CheckAttackAllowed_0
  BIT 4,(IX+$04)          ; state bit 4 of the victim
  JR Z,CheckAttackAllowed_0 ; only the player clears it
  RES 4,(IX+$04)
CheckAttackAllowed_0:
  LD A,(IX+$04)
  AND STATE_SIDE_BITS
  LD IX,(ActorRecord)     ; IX := attacker
  AND (IX+$04)
  RET Z
  POP HL                  ; refused: return to the caller's caller
  XOR A
  LD (ActionAllowed),A    ; ActionAllowed := 0
  RET

; Attack the first object, with the second as the weapon
;
; Default handler of attack (id 15; VerbHandlers; the goblins chain
; RespawnKilledGoblin after it). Refused when the two share a side bit
; (CheckAttackAllowed). The weapon is the second object (bare hands, the word
; "fist", when none): it must have exactly one place, else "You cannot kill
; with <obj2>."; its name phrase goes to TargetNamePtr for the messages.
;
; Strengths (record +5 attack, +6 defence): attack = the actor's +5 plus the
; weapon's +5 (saturating at $FF), defence = the victim's +6; both are rolled
; with RollStrength (random spread up to ROLL_SPREAD, which wraps in some
; cases: finding F9). When the defence is not below the attack: "But the effort
; is wasted. <his> defense is too strong." Otherwise the excess d is the
; damage. More than KILL_MARGIN (16): "With one well placed blow <subj> cleave
; <his> skull.", the victim gets the dead flag and dies (KillCharacter; if it
; is the player the game ends) and "<victim> is dead." is printed
; (PrintStateIX). Else the wound message number d of WoundMessages is printed
; and the victim's +5 is reduced by X+1 (if it is above X) and its +6 by Y+1
; (if above Y), where X is 2d rotated right twice (d/2 for even d; for odd d
; bit 0 lands in bit 7, so X >= 128 and the reduction practically never
; happens) and Y is X rotated right once more (inferred from the code). Damage
; 16 indexes the table one word past its end, at $9246, which is code: a wild
; message address (finding).
;
; Hardware: none.
VerbAttack:
  CALL CheckAttackAllowed ; refuse a fight between friends
  LD A,(SecondObject)     ; the weapon
  LD HL,PHRASE_FIST       ; default name: fist
  CP NO_OBJECT
  JR Z,VerbAttack_0       ; no weapon
  LD IX,(Noun2Record)     ; the weapon's record
  LD L,(IX+$08)           ; its name phrase...
  LD H,(IX+$09)
VerbAttack_0:
  LD (TargetNamePtr),HL   ; ... for the messages
  LD IX,(ActorRecord)     ; the attacker
  LD B,(IX+$05)           ; B = its strength
  LD A,(SecondObject)     ; the weapon
  INC A
  JR Z,VerbAttack_Roll    ; none: bare hands
  LD IY,(Noun2Record)     ; the weapon's record
  LD A,(IY+$00)           ; its number of places
  DEC A                   ; more than one (a door): not a weapon
  LD HL,MsgCannotKillWith ; "You cannot kill with <obj2>."
  JP NZ,PrintMessage
  LD A,(IY+$05)           ; the weapon's strength
  ADD A,B                 ; plus the attacker's, saturating at $FF
  JR NC,VerbAttack_1
  LD A,$FF
VerbAttack_1:
  LD B,A
VerbAttack_Roll:
  LD A,B
  CALL RollStrength       ; roll the attack
  LD B,A                  ; B = attack
  CALL CommitOrAbort      ; only when really performing
  LD IX,(Noun1Record)     ; the victim
  LD A,(IX+$06)           ; its defence
  CALL RollStrength       ; roll it
  CP B                    ; defence against attack
  LD HL,MsgButEffortWasted ; "But the effort is wasted..."
  JP NC,PrintMessage      ; defence holds: no effect
  LD C,A                  ; C = defence
  ADD A,KILL_MARGIN       ; defence + 16 (saturating)...
  JR NC,VerbAttack_2
  LD A,$FF
VerbAttack_2:
  CP B
  JR C,VerbAttack_Kill    ; ... below the attack: a killing blow
  LD A,B                  ; damage d = attack - defence, 1-16
  SUB C
  RLCA                    ; 2d: word index
  LD E,A
  LD D,$00
  LD IY,WoundMessages
  ADD IY,DE               ; wound message d
  LD L,(IY+$00)
  LD H,(IY+$01)           ; HL = its address
  RRCA                    ; 2d rotated right twice: X
  RRCA
  LD B,A
  CPL                     ; victim's +5 reduced by X+1 if above X
  ADD A,(IX+$05)
  JR NC,VerbAttack_3
  LD (IX+$05),A
VerbAttack_3:
  LD A,B                  ; X rotated once more: Y
  RRCA
  CPL                     ; victim's +6 reduced by Y+1 if above Y
  ADD A,(IX+$06)
  JR NC,VerbAttack_4
  LD (IX+$06),A
VerbAttack_4:
  JP PrintMessage         ; print the wound
VerbAttack_Kill:
  LD HL,MsgWithOneWellPlacedBlow ; "With one well placed blow <subj> cleave
                                 ; <his> skull."
  CALL PrintMessage
  SET FLAG_DEAD,(IX+$07)  ; dead
  LD A,(FirstObject)      ; the victim
  CALL KillCharacter      ; dies
  LD A,REASON_DEAD        ; "<victim> is dead."
  JP PrintStateIX

; Roll a strength with a random spread
;
; Adds a random signed spread (RandomSigned with range ROLL_SPREAD) to the
; strength in A, for the fight in VerbAttack. Observed over 64 rolls: the
; result is the strength plus 0 to 10 (mostly), saturated at $FF; a negative
; spread that does not underflow gives 0, and one that does underflow wraps
; (strength 0 gave 252 and 255). Looks like a bug in the original (inferred).
;
; A Strength O:A Strength with the spread added
RollStrength:
  PUSH BC
  LD B,A
  LD A,ROLL_SPREAD
  CALL RandomSigned
  LD C,A                  ; C: spread (signed)
  ADD A,B
  JR NC,RollStrength_0    ; no carry: result in A
  XOR A                   ; carry: A := 0 ...
  BIT 7,C
  JR NZ,RollStrength_0
  DEC A                   ; ... or $FF when the spread was positive
RollStrength_0:
  POP BC
  RET

; Wound messages: 16 message addresses
;
; Indexed by the damage ($91D2-$91DC), printed with $72DD.
WoundMessages:
  DEFW MsgSeemTiredStaggerBut
  DEFW MsgSwingFeeblyAtButMiss
  DEFW MsgBrandishButOnGuard
  DEFW MsgSlashAtButBlow
  DEFW MsgSweepsPastCloseEar
  DEFW MsgSwingBroadsideAtBody
  DEFW MsgThrustBackLoseFooting
  DEFW MsgHitWithGlancingBlow
  DEFW MsgFastStrokeSweepsOff
  DEFW MsgFastBlowKnocksWindOut
  DEFW MsgHitHardOnShoulder
  DEFW MsgGiveNastySlashLeg
  DEFW MsgSliceHandBloodDrips
  DEFW MsgNastySliceMissesHeart
  DEFW MsgGiveViciousCutRibs
  DEFW MsgViolentAttackAlmost

; Test whether the first object has a single place
;
; Looks at the record of Noun1Record: its field +0 (N, the number of locations
; it lists) minus 1. Things with several places (doors, rivers, webs) have N >
; 1; ordinary portable objects and characters have N = 1. The attack handler
; VerbAttack uses the same test on the second object ("you cannot kill with
; X").
;
; O:F Z set when N is 1 O:IX Record of the first object
CheckSinglePlace:
  LD IX,(Noun1Record)
  LD A,(IX+$00)
  DEC A                   ; Z when N = 1
  RET

; Put the first object into (or onto) the second
;
; Verb handler of the commands "drop in" (14) and "put in" (17) in the verb
; tables of containers (the second object); L8F69 also reaches it through L9F4A
; with the nouns swapped. It refuses, in this order:
;
; CheckCanCarry_Single refuses first (the object has several places, like a
; door, or is a liquid); then "I cannot do that." when the first object is
; already in the second; "<container> is closed" (PrintStateIY) unless the
; container is open (this check is skipped for command 18, "put on"); and the
; message "<obj2> is too full." when the first object's weight (+2) is more
; than the container's capacity (+2) or does not leave room beside what it
; already holds (SumHeldWeight; an exact fit is refused too).
;
; Otherwise (CommitOrAbort: only when performed) the first object's holder (+1)
; becomes the second object and its location (+$10) becomes the container's.
;
; Noun1Record Record of the first object
; Noun2Record Record of the second object (the container)
; FirstObject Id of the first object
; SecondObject Id of the second object
; CommandId The command (14, 17 or 18)
PutObjectIn:
  CALL CheckCanCarry_Single ; refuse a fixed object or a liquid
  LD A,(SecondObject)
  CP (IX+$01)             ; already in it?
  JP Z,PrintCannotDoThat  ; "I cannot do that."
  LD IY,(Noun2Record)     ; the container
  LD A,(CommandId)
  CP CMD_PUT_ON           ; put on: no need for it to be open
  JR Z,PutObjectIn_0
  BIT FLAG_ACTIVE,(IY+$07) ; open?
  JR Z,PutObjectIn_2
PutObjectIn_0:
  LD A,(IY+$02)           ; container's capacity
  SUB (IX+$02)            ; minus the weight of the object
  JR C,PutObjectIn_1      ; too heavy for it
  PUSH AF
  LD A,(SecondObject)
  CALL SumHeldWeight      ; weight it already holds
  LD B,A
  POP AF
  SUB B                   ; room left; carry or zero: too full
PutObjectIn_1:
  LD HL,MsgTooFull        ; "<obj2> is too full."
  JP C,PrintMessage
  JP Z,PrintMessage
  CALL CommitOrAbort      ; abandon unless performing
  LD A,(IY+$10)           ; the object goes to the container's location
  LD (IX+$10),A
  LD A,(SecondObject)     ; and its holder is the container
  LD (IX+$01),A
  RET
PutObjectIn_2:
  LD A,REASON_CLOSED      ; state "closed"
  JP PrintStateIY         ; "<container> is closed"

; Command handler (via $C730)
L929C:
  CALL CommitOrAbort
  LD IX,(Noun1Record)
  LD A,(IX+$01)
  CP $FF
  JR Z,L929C_0
  CALL FindObject
  RES 2,(IX+$07)
  LD A,$01
  JR L929C_1
L929C_0:
  CALL CommitOrAbort
  LD A,$0A
L929C_1:
  LD IX,(ActorRecord)
  ADD A,(IX+$05)
  CP $80
  JR NC,L929C_3
  LD (IX+$05),A
  LD IX,(Noun1Record)
  LD (IX+$01),$FF
  LD B,(IX+$00)
L929C_2:
  LD (IX+$10),$00
  INC IX
  DJNZ L929C_2
  RET
L929C_3:
  LD HL,MsgFoulGluttonyHasKilled
  CALL PrintMessage
  LD A,(Subject)
  JP KillCharacter
  LD A,$83
  JP PrintStateIY

; Strike an object, perhaps with a weapon
;
; Verb handler of command 11, "strike" ("strike X with Y"), in the verb tables
; of breakable things (also reached from the throw and shoot handlers when the
; target is not a character, and from LA761). The first object is hit by the
; subject, with the second object as the weapon when one is given.
;
; Refused (RefuseCommand) when the object is a liquid or has defence 0 (+6);
; when it is already broken (flag bit 3) it says "<object> is broken". A weapon
; is refused when its attack strength (+5) is 0 or its own verb table has no
; "strike" entry.
;
; Once performed: strength = random spread (STRIKE_SPREAD) + weapon attack (+5,
; 0 without a weapon) + the subject's attack (+5), saturated at $FF. When it is
; at least the object's defence (+6) the object breaks: the broken flag is set,
; its name becomes "broken ..." (MarkBrokenOrDead), its attack is halved and,
; when its state byte (+4) is below 2, its contents spill (EmptyFirstObject);
; the message is "<object> is broken" (REASON_BROKEN). Then the weapon is tried
; the same way with its defence (+6) against the object's, and when it comes
; out as at least the object's defence the weapon breaks too and its "is
; broken" message is printed. The spread is added as an unsigned byte, so a
; negative spread saturates to $FF as in RollStrength (inferred: not tried in
; play).
;
; Noun1Record Record of the object struck
; Noun2Record Record of the weapon (when SecondObject is not $FF)
; FirstObject Id of the object struck
; SecondObject Id of the weapon, or $FF
StrikeObject:
  LD IX,(Noun1Record)
  BIT FLAG_CONSUMABLE,(IX+$07) ; a liquid cannot be struck
  JP NZ,RefuseCommand
  BIT FLAG_DEAD,(IX+$07)  ; already broken
  JP NZ,StrikeObject_4
  SUB A
  CP (IX+$06)             ; defence 0: unbreakable
  JP Z,RefuseCommand
  LD B,A                  ; B = weapon attack, 0 without a weapon
  LD A,(SecondObject)
  INC A                   ; no weapon?
  JR Z,StrikeObject_0
  LD IY,(Noun2Record)     ; the weapon
  LD A,(IY+$05)
  AND A
  JP Z,RefuseCommand      ; attack 0: not a weapon
  PUSH IX
  LD IX,(Noun2Record)
  LD A,CMD_STRIKE
  CALL FindVerbEntry      ; does the weapon have a "strike" entry?
  POP IX
  INC A
  JP Z,RefuseCommand      ; no
  LD B,(IY+$05)           ; weapon attack
StrikeObject_0:
  CALL CommitOrAbort      ; abandon unless performing
  LD A,STRIKE_SPREAD
  CALL RandomSigned       ; random spread
  ADD A,B                 ; plus the weapon's attack
  LD IY,(ActorRecord)     ; the subject
  ADD A,(IY+$05)          ; plus the subject's attack
  JR NC,StrikeObject_1
  LD A,$FF                ; saturate
StrikeObject_1:
  SUB (IX+$06)            ; minus the object's defence
  JR C,StrikeObject_2     ; not enough: the object holds
  SET FLAG_DEAD,(IX+$07)  ; the object breaks
  LD A,(FirstObject)
  CALL MarkBrokenOrDead   ; its name becomes "broken ..."
  SRA (IX+$05)            ; half the attack
  LD A,(IX+$04)           ; state byte
  CP $02
  CALL C,EmptyFirstObject ; spill its contents
  LD A,REASON_BROKEN
  CALL PrintStateIX       ; "<object> is broken"
StrikeObject_2:
  LD A,(SecondObject)
  CP NO_OBJECT
  RET Z                   ; no weapon: done
  LD IY,(Noun2Record)     ; the weapon
  BIT FLAG_DEAD,(IY+$07)
  RET NZ                  ; already broken
  LD B,(IY+$06)           ; weapon defence
  LD A,STRIKE_SPREAD
  CALL RandomSigned
  ADD A,B
  JR NC,StrikeObject_3
  LD A,$FF
StrikeObject_3:
  SUB (IX+$06)            ; minus the object's defence
  RET C                   ; below it: the weapon holds
  SET FLAG_DEAD,(IY+$07)  ; the weapon breaks
  LD A,(SecondObject)
  CALL MarkBrokenOrDead   ; its name becomes "broken ..."
  LD A,(IY+$05)
  SRA A                   ; half the attack
  LD (IY+$05),A
  CALL EmptyFirstObject   ; spill its contents
  PUSH IY
  POP IX                  ; the message names the weapon
StrikeObject_4:
  LD A,REASON_BROKEN
  JP PrintStateIX         ; "<IX> is broken"

; Give the first object to the second
;
; Default handler (VerbHandlers) of command 29, "give X to Y". The subject must
; hold the object (CheckObject1Held: "<subject> is not carrying it." otherwise)
; and the recipient must have room: the bulk it already holds (SumHeldBulk)
; plus the object's bulk (+3) may not exceed its capacity (+3), or it says
; "<subject> is carrying too much.". When performed, the object's holder (+1)
; becomes the recipient and its location (+$10) the recipient's, and
; MoveCarried finishes the move (the object's contents go with it).
;
; Noun1Record Record of the object given
; Noun2Record Record of the recipient
; FirstObject Id of the object given
; SecondObject Id of the recipient
GiveObject:
  LD IY,(Noun2Record)     ; the recipient
  CALL CheckObject1Held   ; held by the subject?
  LD HL,MsgNotCarrying    ; "<subject> is not carrying it."
  JP NC,PrintMessage
  LD A,(SecondObject)
  CALL SumHeldBulk        ; bulk the recipient already holds
  LD IX,(Noun1Record)
  ADD A,(IX+$03)          ; plus the bulk of the object
  PUSH AF
  POP BC                  ; B = total
  LD A,(IY+$03)           ; the recipient's capacity
  SUB B
  LD HL,MsgCarryingTooMuch ; "<subject> is carrying too much."
  JP C,PrintMessage
  CALL CommitOrAbort      ; abandon unless performing
  LD A,(SecondObject)     ; the recipient becomes the holder
  LD (IX+$01),A
  LD A,(IY+$10)           ; and the object is where it is
  LD (IX+$10),A
  LD B,A                  ; B = that location
  LD A,(FirstObject)      ; A = the object
  JP MoveCarried

; Examine the first object
;
; Default handler (VerbHandlers) of command 28, "examine"; ExamineMap uses it
; for every subject but Elrond. When the object's record has a description
; message (+14, +15) that is printed; otherwise it prints "<subject> see <the
; object name>." (MsgSee, then the name, a full stop and a new line).
;
; Nothing is printed unless the command is really performed (CommitOrAbort).
;
; FirstObject Id of the object examined
ExamineObject:
  CALL CommitOrAbort      ; abandon unless performing
  LD A,(FirstObject)
  CALL FindObject         ; its record in IX
  LD L,(IX+$0E)           ; description message
  LD H,(IX+$0F)
  LD A,H
  OR L
  JP NZ,PrintMessage      ; print it
  LD HL,MsgSee            ; "<subject> see"
  CALL PrintMessage
  PUSH IX
  POP IY
  CALL PrintObjectName    ; the name
  LD A,CHAR_FULLSTOP
  CALL PrintChar
  CALL PrintNewLine       ; new line
  RET

; Command handler (via $C730), with entry points $946D, $948D, $94A4
L9404:
  LD IX,(Noun1Record)
  CALL CheckOpen
  JP Z,PrintStateIX
  LD A,(FirstObject)
  CALL CountHeldPresent
  CP $00
  JR Z,L9404_0
  CALL CommitOrAbort
  CALL EmptyFirstObject
  RES 2,(IX+$07)
  RET
L9404_0:
  LD A,$02
  JP PrintStateIX
L9404_1:
  CALL CheckCanCarry_Single
  CALL CommitOrAbort
  LD A,(ActorLocation)
  LD IX,(Noun2Record)
  LD B,(IX+$00)
L9404_2:
  CP (IX+$10)
  JR Z,L9404_3
  INC IX
  DJNZ L9404_2
  JP PrintCannotDoThat
L9404_3:
  LD A,(IX+$11)
  DEC B
  JR NZ,L9404_4
  XOR A
L9404_4:
  PUSH AF
  LD HL,MsgGetsSweptAway
  CALL PrintMessage
  POP AF
  LD IX,(Noun1Record)
  LD (IX+$10),A
  LD (IX+$01),$FF
  LD B,A
  LD A,(FirstObject)
  CALL MoveCarried
  LD A,(Chr00PlayerLocation)
  AND A
  JP Z,EndGame
  RET
L9404_5:
  CALL CheckOpenable
  JP NZ,PrintStateIX
  LD A,$C6
L9404_6:
  LD (SmcSetOrRes+$0003),A
  LD IY,(Noun2Record)
  BIT 3,(IY+$07)
  LD A,$83
  JP NZ,PrintStateIY
  CALL CommitOrAbort
SmcSetOrRes:
  SET 0,(IX+$07)          ; SET 0 or RES 0: L9404_6 writes the operation byte
                          ; ($C6 or $86)
  RET
L9404_7:
  LD IX,(Noun1Record)
  BIT 0,(IX+$07)
  LD A,$00
  JP Z,PrintStateIX
  CALL CheckOpenable_0
  JP NZ,PrintStateIX
  LD A,$86
  JR L9404_6
L9404_8:
  CALL RequireHeld
  LD A,(SecondObject)
  CALL FindExitByObstacle_0
  CP $FF
  JP Z,RefuseCommand
  LD IY,(Noun2Record)
  BIT 5,(IY+$07)
  LD A,$05
  JP Z,PrintStateIY
  CALL CommitOrAbort
  LD B,(IX+$02)
  LD IX,(Noun1Record)
  LD (IX+$01),$FF
  LD (IX+$10),B
  LD A,(FirstObject)
  JP MoveCarried
