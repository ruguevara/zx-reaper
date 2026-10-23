; NPC turn: the NPC is held by something
;
; Part of the NPC loop (RunNpcScripts), taken when the NPC's record has a
; holder (+1 is not AT_LOCATION). FirstObject becomes the holder and
; SecondObject none. When the holder is dead or disabled (FLAG_DEAD) or a
; character, the NPC acts as usual (jump to RunNpcScripts_Start). When the
; holder is shut (FLAG_ACTIVE clear) the NPC does nothing this turn
; (RunNpcScripts_Next, the next NPC). Otherwise it climbs out of the open
; holder: CommandId := CMD_CLIMB_OUT_OF is carried out for the NPC by
; RunActorCommand (a barrel, a boat), and the loop goes on with the next NPC.
;
; IX Record of the NPC (set by the loop)
NpcHeld:
  LD A,NO_OBJECT          ; SecondObject := none
  LD (SecondObject),A
  LD A,(IX+$01)           ; FirstObject := the holder
  LD (FirstObject),A
  CALL FindObject         ; IX = the holder's record
  BIT FLAG_DEAD,(IX+$07)  ; dead or disabled holder
  JP NZ,RunNpcScripts_Start ; the NPC acts normally
  BIT FLAG_CHARACTER,(IX+$07) ; a character holds it
  JP NZ,RunNpcScripts_Start ; the NPC acts normally
  BIT FLAG_ACTIVE,(IX+$07) ; open?
  JP Z,RunNpcScripts_Next ; no: skip this NPC
  LD A,CMD_CLIMB_OUT_OF
  LD (CommandId),A        ; CommandId := climb out of
  CALL RunActorCommand    ; the NPC does it
  JP RunNpcScripts_Next   ; next NPC

; Check that a command does not use the same object twice
;
; Rejects commands that act on themselves: the subject (the actor), the first
; object and the second object must differ where it matters. Returns NZ when
; the first object is not given (FirstObject is $FF). Otherwise, unless
; Noun1Kind is set, Z when the subject or the second object equals the first
; object; then, unless Noun2Kind is set, Z when the second object equals the
; subject. The callers (CheckVerbApplies and DispatchCommand) end the command
; when the answer is Z. Noun1Kind and Noun2Kind are set by UnpackFlags from
; bits 7 and 6 of $B71D; what they stand for is not decoded.
;
; O:F Z set when the command is rejected O:A Non-zero when FirstObject is $FF
CheckNounsDistinct:
  LD A,(FirstObject)
  INC A                   ; FF + 1 = 0: no first object
  JR NZ,CheckNounsDistinct_0
  INC A                   ; A := 1, NZ
  RET
CheckNounsDistinct_0:
  LD A,(Noun1Kind)        ; Noun1Kind
  AND A
  JR NZ,CheckNounsDistinct_1
  LD HL,FirstObject
  LD A,(Subject)
  CP (HL)                 ; Subject = first object
  RET Z
  LD A,(SecondObject)
  CP (HL)                 ; second object = first object
  RET Z
CheckNounsDistinct_1:
  LD A,(Noun2Kind)        ; Noun2Kind
  AND A
  RET NZ
  LD A,(SecondObject)
  LD HL,Subject
  CP (HL)                 ; second object = subject
  RET

; Call a handler address if it is not zero
;
; Calls the routine at HL (through JumpHL) when HL is not zero, and does
; nothing when it is. All registers except AF are preserved, so the handler can
; not hand values back in registers. Used for the handler words in records,
; timers and NPC scripts.
;
; HL Address of the handler, or 0 for none
CallHandler:
  PUSH IX
  PUSH IY
  PUSH DE
  PUSH BC
  PUSH HL
  LD A,L
  OR H
  CALL NZ,JumpHL          ; JP (HL) trampoline
  POP HL
  POP BC
  POP DE
  POP IY
  POP IX
  RET

; Jump to the address in HL
;
; Entered by CALL from CallHandler, so that the JP (HL) behaves as a call to
; HL.
;
; HL Address to run
JumpHL:
  JP (HL)

; Find a verb entry in an object's verb table
;
; Skips the fixed part of the object record in IX (RECORD_HEADER_SIZE bytes
; plus one per location, record +0 N) and searches the verb table that follows:
; (verb id, handler address) entries, ending with $FF. An entry with id 0
; chains to the next table; FindIdRecord does not follow it.
;
; A Verb id IX Record of the object O:IX Address of the matching entry, or of
; the $FF that ends the table O:A The id found, or END_MARK O:F Z set when not
; found
FindVerbEntry:
  PUSH DE
  LD D,A
  LD A,(IX+$00)
  ADD A,RECORD_HEADER_SIZE
  LD E,A                  ; E: offset of the verb table
  LD A,D
  LD D,$00
  ADD IX,DE
  CALL FindIdRecord
  POP DE
  RET

; Step to the next entry of the object table
;
; Moves IX on by one (id, record address) entry and loads that entry's record
; address into IY and its id into A. Start a walk with IX = the address before
; the table (ObjectTable - 3, $C060). Works in the alternate registers, so BC,
; DE and HL are kept.
;
; IX Current entry of ObjectTable (or its base minus 3) O:IX Next entry O:IY
; Record of the next object O:A Id of the next object O:F Z set at the $FF that
; ends the table
NextObject:
  EXX                     ; alternate registers
  LD DE,ID_ENTRY_SIZE
  ADD IX,DE
  LD D,(IX+$02)
  LD E,(IX+$01)
  PUSH DE
  POP IY                  ; IY := record
  LD A,(IX+$00)
  CP END_MARK
  EXX
  RET

; Step to the next object, keeping A
;
; Like NextObject but A and BC come back as they went in, so a loop can keep an
; id in A. Only IX, IY and Z are results.
;
; A Value to keep IX Current entry of ObjectTable (or its base minus 3) O:IX
; Next entry O:IY Record of the next object O:F Z set at the $FF that ends the
; table
NextObjectKeepA:
  PUSH BC
  LD B,A
  CALL NextObject
  LD A,B
  POP BC
  RET

; Find a location record
;
; Looks the location id up in the table of 80 record addresses (LocationTable
; at $B9E0, 2 bytes each). An id of $50 or more gives A = 0 and leaves IX as it
; was.
;
; A Location id O:IX Address of the location record O:A The id (unchanged), or
; 0 when the id is out of range Preserves DE and HL.
FindLocation:
  CP LOCATION_COUNT
  JR C,FindLocation_0
  XOR A                   ; out of range: A := 0
  RET
FindLocation_0:
  PUSH DE
  LD DE,LocationTable
  PUSH HL
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  PUSH DE
  POP IX
  POP HL
  POP DE
  RET

; Find an object or character record
;
; Looks the id up in ObjectTable (id, record address) with FindIdRecord and
; puts the record address into IX. HL is preserved.
;
; A Object or character id O:IX Address of the record (garbage when the id is
; not in the table) O:A The id, or END_MARK when it is not in the table O:F Z
; set when not found
FindObject:
  LD IX,ObjectTable
  CALL FindIdRecord
  PUSH HL
  LD L,(IX+$01)
  LD H,(IX+$02)
  EX (SP),HL
  POP IX
  RET

; Flag set by $9BDD (starts FF)
MoveFlag:
  DEFB $FF

; Move what a carrier holds to a new location, bringing the player along
;
; Called when an actor or object has been put at a new location (B). Sets
; MoveFlag to 1 and gives the new location to everything the carrier holds, and
; what those hold (MoveContents). If that walk met the player (MoveFlag was
; cleared: the player is inside or carried by the carrier), the player arrives
; too: with the player as the actor (Subject 0, ActorRecord the player's
; record, TakeId = B) it runs the arrival part of the take routine
; (ActorArrives), then UpdatePlayerSight refreshes what the player can see, and
; the actor is restored. The arrival step is skipped when the player's first
; location ($C12B) is 0. MoveFlag is 0 when the routine ends with the player
; carried.
;
; A Id of the carrier (an actor or an object that holds things) B The new
; location
MoveCarried:
  LD HL,MoveFlag
  LD (HL),$01
  CALL MoveContents       ; relocate the contents
  LD A,(HL)
  AND A
  RET NZ                  ; the player was not among them
  PUSH HL
  LD A,(Chr00PlayerLocation) ; the player's first location
  AND A
  JR Z,MoveCarried_0
  LD A,(Subject)          ; keep the actor
  PUSH AF
  LD HL,(ActorRecord)     ; and its record
  PUSH HL
  LD HL,Chr00Player       ; the player
  LD (ActorRecord),HL
  XOR A
  LD (Subject),A          ; Subject := player
  LD A,B
  LD (TakeId),A           ; TakeId := the new location
  CALL ActorArrives       ; the player arrives
  CALL UpdatePlayerSight
  POP HL
  LD (ActorRecord),HL
  POP AF
  LD (Subject),A
MoveCarried_0:
  POP HL
  XOR A
  LD (HL),A               ; MoveFlag := 0
  RET

; Move an object's contents to a location
;
; Sets the first location slot (record +$10) to B for every object whose holder
; is A, then does the same for the contents of each of those objects (it calls
; itself). Used by MoveCarried when a carrier changes place. If the walk meets
; table id 0 (the player) it clears MoveFlag, which tells MoveCarried that the
; player moved with the load (inferred).
;
; A Holder id B New location
MoveContents:
  PUSH IY
  PUSH IX
  LD IX,ObjectTable-ID_ENTRY_SIZE
MoveContents_Next:
  CALL NextObjectKeepA
  JR Z,MoveContents_1
  CP (IY+$01)             ; holder = A?
  JR NZ,MoveContents_Next
  LD (IY+$10),B           ; location slot 0
  PUSH AF
  LD A,(IX+$00)
  AND A
  JR NZ,MoveContents_0    ; id 0 (the player)?
  LD (MoveFlag),A
MoveContents_0:
  CALL MoveContents       ; its contents too
  POP AF
  JR MoveContents_Next
MoveContents_1:
  POP IX
  POP IY
  RET

; Capacity left at a location
;
; Takes the capacity of the location (record +1) and subtracts the weight (+2)
; of every object or character record that has exactly one location and that
; location is the one given, stopping at 0 when the sum is too much. The caller
; (CheckPassage) has already dealt with the $FF capacity of an unlimited
; location. BC, IX and IY are kept.
;
; A Location id O:A Capacity left, 0 when the weights add up to more than the
; capacity
LocationSpareCapacity:
  PUSH IX
  PUSH IY
  PUSH BC
  LD B,A                  ; B = the location
  CALL FindLocation       ; IX = its record
  LD A,(IX+$01)
  LD C,A                  ; C = capacity
  LD IX,ObjectTable-ID_ENTRY_SIZE
LocationSpareCapacity_Next:
  CALL NextObject
  JR Z,LocationSpareCapacity_0 ; end of the table
  LD A,(IY+$00)
  CP $01
  JR NZ,LocationSpareCapacity_Next ; only records with one location
  LD A,B
  CP (IY+$10)
  JR NZ,LocationSpareCapacity_Next ; and that one is the location
  LD A,C
  SUB (IY+$02)            ; minus its weight
  JR C,LocationSpareCapacity_1 ; over capacity
  LD C,A
  JR LocationSpareCapacity_Next
LocationSpareCapacity_0:
  LD A,C
  POP BC
  POP IY
  POP IX
  RET
LocationSpareCapacity_1:
  LD C,$00
  JR LocationSpareCapacity_0

; Test whether an object is held by the subject
;
; Tests the chain of holders of an object: is it carried by the subject
; (Subject: 0 is the player), directly or inside something the subject carries.
; $9C78 takes the object from the first object slot (FirstObject); $9C7B takes
; the id in A. The id $FF (no object) counts as held. Objects lying at a
; location (holder $FF) are not held.
;
; Part of the walk is WalkHolderChain.
;
;   A Object id ($9C7B only; $9C78 loads it from $B6E8)
; O:F Carry set when the object is held by the subject, or A was $FF; carry
;     clear when not
; O:HL $B6EA, the address of the subject id
CheckObject1Held:
  LD A,(FirstObject)
CheckHeldBySubject:
  LD HL,Subject
CheckObject1Held_0:
  CP $FF                  ; no object: counts as held
  SCF
  RET Z
  PUSH IX                 ; IX is not preserved by WalkHolderChain
  CALL WalkHolderChain
  POP IX
  RET

; Walk up the holder chain of an object
;
; Looks up the record of the object in A, takes its holder and compares it with
; the id at (HL); if different, repeats with the holder as the object, so an
; object inside a bag inside the subject's hands is found. Stops with carry
; clear when a holder is $FF (the object lies at a location). The first CALL
; trashes IX (the POP IX throws away the saved AF; callers save IX).
;
;   A Object id whose holders are followed
;   HL Address of the id looked for (Subject, the subject)
; O:F Carry set when the id at (HL) is a holder in the chain; clear when the
;     chain ends at a location
WalkHolderChain:
  CALL FindObject
  PUSH AF
  LD A,(IX+$01)
  CP AT_LOCATION          ; holder $FF: lies at a location
  JR Z,WalkHolderChain_0
  POP IX                  ; drops the saved AF into IX (unused)
  CP (HL)
  JR NZ,WalkHolderChain
  SCF
  RET
WalkHolderChain_0:
  POP AF
  AND A
  RET

; Random number from 0 to A
;
; Takes the absolute value of the signed random number of RandomSigned, so the
; result is between 0 and A (small values are likelier than large ones).
;
;   A Largest value wanted
;   DE Any value (RandomSigned adds it to the ROM address it reads)
; O:A Random number 0 to A
RandomUpTo:
  CALL RandomSigned
  BIT 7,A
  RET Z
  NEG
  RET

; Random number from -A to A
;
; The game's random number routine. It keeps a seed ($B70E) and a pointer into
; memory ($B712: its high byte at $B713 is stepped by one page per call, the
; low byte when that wraps), and mixes the seed with two bytes read from memory
; at the pointer and at the pointer plus DE plus 1. A repeated seed is
; discarded. The 8-bit result is halved until it is at most 2*A (or 255 when A
; is 128 or more), then A is subtracted, giving a signed value from -A to A
; (not evenly spread).
;
; The seed starts from the R register at the first key press (GameStart).
;
;   A Largest absolute value wanted
;   DE Any value; added to the memory pointer, so callers' leftovers add noise
; O:A Random number from -A to A (two's complement)
RandomSigned:
  PUSH IX
  PUSH BC
  LD C,A
  SLA A
  JR NC,RandomSigned_0
  LD A,$FF
RandomSigned_0:
  LD B,A
RandomSigned_Retry:
  LD IX,RandomRomPtr      ; step the pointer: page counter, then its low byte
  INC (IX+$01)
  JR NZ,RandomSigned_1
  INC (IX+$00)
RandomSigned_1:
  LD IX,(RandomRomPtr)
  LD A,(RandomSeed)       ; seed + byte at the pointer
  ADC A,(IX+$00)
  ADD IX,DE               ; second byte comes from pointer + DE + 1
  XOR (IX+$01)
  PUSH HL
  LD HL,RandomSeed
  CP (HL)
  POP HL
  JR Z,RandomSigned_Retry
  LD (RandomSeed),A
RandomSigned_Halve:
  CP B                    ; halve until not above 2*A
  JR C,RandomSigned_2
  JR Z,RandomSigned_2
  SRL A
  JP RandomSigned_Halve
RandomSigned_2:
  SUB C                   ; range -A..A
  POP BC
  POP IX
  RET

; Sum the weights of what a holder directly holds
;
; Adds up the weight (+2) of every record whose holder is the id in A, without
; looking inside them. Sets B to 1 and joins SumHeld. Used for the weight an
; actor already carries or a container already holds.
;
;   A Holder id (the player, an actor or a container)
; O:A Total weight, $FF when it overflows
SumHeldWeight:
  PUSH BC                 ; B=1: sum weights, do not recurse
  LD B,$01
  JR SumHeld

; Sum the sizes of everything inside a holder
;
; Adds up the size (+3, the bulk) of every record held by the id in A and,
; recursively, of everything held by those. Used to check that an object fits a
; container. B (0 for the size sum, 1 for the weight sum of SumHeldWeight) is
; passed to SumHeldRecords.
;
;   A Holder id
; O:A Total, $FF when it overflows
SumHeldBulk:
  PUSH BC                 ; B=0: sum sizes, recurse
  LD B,$00
SumHeld:
  PUSH IX
  PUSH IY
  LD C,$00                ; total
  CALL SumHeldRecords     ; IY is kept by SumHeldRecords
  LD A,C
  POP IY
  POP IX
  POP BC
  RET

; Add a field of all records held by a holder
;
; Walks the object table ObjectTable and, for each record whose holder (+1) is
; A, adds its size (+3) to C and calls itself for that record, or, when B is
; not 0, adds its weight (+2) and does not recurse. A signed overflow sets C to
; $FF and ends the walk. The walk starts at the second table entry: the player
; record is never held.
;
;   A Holder id
;   B 0: add the size (+3) and recurse; not 0: add the weight (+2) only
;   C Total so far
; O:C Total, $FF on overflow
SumHeldRecords:
  PUSH IX
  LD IX,ObjectTable
SumHeld_Next:
  CALL NextObjectKeepA
  JR Z,SumHeldRecords_2
  CP (IY+$01)
  JR NZ,SumHeld_Next
  PUSH AF
  SUB A                   ; Z when B = 0
  CP B
  LD A,C
  JR Z,SumHeldRecords_0
  ADD A,(IY+$02)
  JP PE,SumHeldRecords_3  ; overflow: C = $FF
  LD C,A
  JR SumHeldRecords_1
SumHeldRecords_0:
  ADD A,(IY+$03)
  JP PE,SumHeldRecords_3
  LD C,A
  LD A,(IX+$00)
  CALL SumHeldRecords     ; the held record may hold more
SumHeldRecords_1:
  POP AF
  JR SumHeld_Next
SumHeldRecords_2:
  POP IX
  RET
SumHeldRecords_3:
  POP AF
  LD C,$FF                ; overflow marker
  JR SumHeldRecords_2

; Find the record of the location of the current actor
;
; Takes the first location (+$10) of the actor record at (ActorRecord) and
; looks up the location record.
;
; O:IX Record of the actor's location (FindLocation: unchanged when the id is
;      not a location)
GetActorLocationRec:
  PUSH AF
  LD IX,(ActorRecord)
  LD A,(IX+$10)
  CALL FindLocation
  POP AF
  RET

; Continue only if the command is really being performed
;
; Called just before a command changes the world. When the perform flag
; (ActionPerform) is 1 it returns; otherwise the command is only being tried:
; it sets the "possible" flag (ActionAllowed) to the perform flag plus one and
; abandons the routine that called it (POP BC drops its return address, so the
; RET goes to that routine's caller).
;
; O:A Perform flag (when it returns)
CommitOrAbort:
  LD A,(ActionPerform)
  CP $01
  RET Z
  INC A
  LD (ActionAllowed),A
  POP BC                  ; drop the return address: leave the caller
  RET

; Empty the first object: consumables vanish, the rest passes up
;
; Entry for the object in FirstObject ($B6E8); EmptyHolder takes the holder in
; A. Used when a holder is destroyed or killed: its contents are either gone or
; handed to whatever held the holder.
;
; Every record held by the holder (+1 = A) is treated alone. If its consumable
; flag (bit 1 of +7) is clear its holder becomes the holder's own holder ($FF
; when the holder lies at a location). If it is set, it evaporates: its first
; location is cleared, its holder is set to $FF, its present flag (bit 7 of +7)
; is cleared, its name is printed and then "Evaporates.". HL is kept.
;
; Hardware: none.
EmptyFirstObject:
  LD A,(FirstObject)      ; FirstObject
; This entry point is used by the routine at KillCharacter.
EmptyHolder:
  PUSH IY
  PUSH IX
  PUSH HL
  CALL FindObject         ; IX = the holder's record
  LD B,(IX+$01)           ; B = what holds the holder
  LD IX,ObjectTable-ID_ENTRY_SIZE
EmptyHolder_Next:
  CALL NextObjectKeepA    ; next record, A kept
  JR Z,EmptyFirstObject_1
  CP (IY+$01)             ; held by the holder?
  JR NZ,EmptyHolder_Next
  BIT FLAG_CONSUMABLE,(IY+$07)
  JR Z,EmptyFirstObject_0
  PUSH AF
  LD (IY+$10),$00         ; location none
  LD (IY+$01),AT_LOCATION
  RES FLAG_PRESENT,(IY+$07) ; no longer present
  CALL PrintObjectName    ; its name
  LD HL,MsgEvaporates2
  CALL PrintMessage       ; "Evaporates."
  POP AF
  JR EmptyHolder_Next
EmptyFirstObject_0:
  LD (IY+$01),B           ; passes to the holder's holder
  JP EmptyHolder_Next
EmptyFirstObject_1:
  POP HL
  POP IX
  POP IY
  RET

; Count the present records held by a holder
;
; Counts the records whose holder (+1) is A and whose flag bit 7 (present) is
; set; objects inside are not counted.
;
;   A Holder id
; O:A Number of present records held
CountHeldPresent:
  PUSH IX
  PUSH IY
  PUSH BC
  LD B,$00
  LD IX,ObjectTableBase   ; the walk steps before it reads: first entry is
                          ; ObjectTable
CountHeldPresent_0:
  CALL NextObjectKeepA
  JR Z,CountHeldPresent_1
  CP (IY+$01)
  JR NZ,CountHeldPresent_0
  BIT FLAG_PRESENT,(IY+$07)
  JR Z,CountHeldPresent_0
  INC B
  JP CountHeldPresent_0
CountHeldPresent_1:
  LD A,B
  POP BC
  POP IY
  POP IX
  RET

; Find a record by id in a table of records that start with an id
;
; Steps through records of 3 bytes from IX until the first byte equals A or is
; $FF (the end mark). Used on ObjectTable (objects), the picture table, the
; verb tables and others. HL, DE and BC are kept (the alternate set is used).
;
;   A Id looked for
;   IX Start of the table
; O:IX Address of the matching record, or of the end mark
; O:F Z set when the id was not found (end mark reached)
FindIdRecord:
  EXX
  PUSH IX
  POP HL
  LD B,A
  LD E,ID_ENTRY_SIZE
  LD D,$00
FindIdRecord_0:
  LD A,(HL)
  CP B
  JR Z,FindIdRecord_1
  CP END_MARK
  JR Z,FindIdRecord_1
  ADD HL,DE
  JP FindIdRecord_0
FindIdRecord_1:
  PUSH HL
  POP IX
  CP END_MARK             ; Z: not found
  EXX
  RET

; Find the next object that a typed noun phrase can mean
;
; Walks the object table (NextObject) from the entry in IX and returns the id
; of the next record that qualifies, or $FF at the end of the table. A record
; qualifies when:
;
; 1. its kind fits AllMode ($B710): 0 things (objects and dead characters), 1
; living characters (flag bit 6 set, bit 3 clear), ALL_MODE_ANY anything;
;
; 2. its name phrase (+8, three word codes) matches the typed phrase (the match
; is MatchCommandRecord, which compares word by word);
;
; 3. unless AllActive ($B70F) is set, the actor can reach it (ActorCanReach).
;
; Start with IX = ObjectTable-3 ($C060); to get the next candidate call again
; with the IX returned. DE, HL and IY are kept.
;
; HL Typed noun phrase (three word tokens) IX Entry before the first to examine
; (ObjectTable-3 to start) O:A Id of the object found, $FF when there are no
; more O:IX Its entry in the object table
FindNextNamedObject:
  PUSH BC
  PUSH DE
  PUSH IY
  LD IY,(ActorRecord)     ; the actor's record
  LD D,(IY+$10)           ; D := the actor's location (not used again)
  LD A,(AllMode)          ; AllMode
  LD E,A
FindNextNamedObject_Next:
  CALL NextObject
  JR Z,FindNextNamedObject_2 ; end of the table
  LD A,ALL_MODE_ANY
  CP E
  JR Z,FindNextNamedObject_1 ; any kind
  LD A,(IY+$07)
  AND $48                 ; character and not dead?
  CP $40
  LD A,$00
  JR NZ,FindNextNamedObject_0
  INC A                   ; 1 = living character
FindNextNamedObject_0:
  CP E
  JR NZ,FindNextNamedObject_Next ; the wrong kind
FindNextNamedObject_1:
  LD BC,REC_PHRASE_A
  PUSH IY
  ADD IY,BC               ; its name phrase
  CALL MatchCommandRecord
  POP IY
  JR NZ,FindNextNamedObject_Next ; the phrase does not match
  LD A,(AllActive)        ; AllActive
  AND A
  JR NZ,FindNextNamedObject_2 ; no reach test then
  LD A,(IX+$00)
  CALL ActorCanReach
  JR Z,FindNextNamedObject_Next ; out of reach
FindNextNamedObject_2:
  LD A,(IX+$00)
  POP IY
  POP DE
  POP BC
  RET

; Test reach with the two records exchanged
;
; Exchanges IX and IY, runs CanReach, and exchanges them back, so the caller
; can hold the object in IX and the observer in IY. RunNpcScripts asks it
; whether the player (IY) can reach the NPC being run (IX);
; ThorinDeathBreaksKey asks it for the small curious key.
;
;   A Object id
;   IX Record of the object
;   IY Record of the observer
; O:F As CanReach: NZ when the object is within reach
CanReachSwapped:
  CALL SwapIXIY
  CALL CanReach           ; IX = observer, IY = object
SwapIXIY:
  PUSH IX                 ; falls through from above: swaps them back
  PUSH IY
  POP IX
  POP IY
  RET

; Test whether the current actor can reach an object
;
; Runs CanReach with IX set to the actor record at (ActorRecord); IX is kept.
;
;   A Object id
;   IY Record of the object
; O:F NZ when the object is within reach of the actor
ActorCanReach:
  PUSH IX
  LD IX,(ActorRecord)
  CALL CanReach
  POP IX
  RET

; Test whether an object is within an observer's reach
;
; The object (IY, id in A) must be present (flag bit 7). It is within reach
; when the observer (IX) is itself inside that object (the first holder in the
; observer's chain that is not open or alive, see FindClosedHolder, is the
; object), or when both have the same such closed holder: if that holder is a
; real one they are inside it together, and if it is $FF (both out in the open)
; the observer's first location must be one of the object's locations.
;
;   A Id of the object at IY
;   IX Record of the observer (an actor or the player)
;   IY Record of the object
; O:F NZ when the object is within reach, Z when not (or when it is not
;     present)
CanReach:
  BIT FLAG_PRESENT,(IY+$07)
  RET Z
  PUSH IY
  PUSH IX
  PUSH BC
  LD B,A                  ; B = object id
  LD C,(IX+$10)           ; C = location of the observer
  PUSH IY
  CALL FindClosedHolder   ; closed holder of the observer
  CP B                    ; the object itself? then reachable
  LD B,A
  POP IX
  JR Z,CanReach_1
  CALL FindClosedHolder   ; closed holder of the object
  CP B                    ; must be the observer's
  JR NZ,CanReach_0
  INC A                   ; $FF + 1 = 0: both in the open
  JR NZ,CanReach_1
  LD B,(IY+$00)           ; B = number of locations of the object
  LD A,C
CanReach_Location:
  CP (IY+$10)
  JR Z,CanReach_1
  INC IY
  DJNZ CanReach_Location
CanReach_0:
  XOR A
  JR CanReach_2
CanReach_1:
  OR $01
CanReach_2:
  POP BC
  POP IX
  POP IY
  RET

; Find the closed holder of an object
;
; Climbs the holder chain of the record in IX: takes its holder, and while that
; holder has flag bit 5 or 3 set (active/open/alive, or dead/disabled: not a
; shut container), continues with the holder's own holder. Stops at a holder
; with neither bit and returns its id, or returns $FF when the chain reaches a
; location. IX is kept.
;
;   IX Record of the object or actor
; O:A Id of the closed holder, $FF when none
FindClosedHolder:
  PUSH IX
FindClosedHolder_0:
  LD A,(IX+$01)
  CP AT_LOCATION
  JR Z,FindClosedHolder_1
  EX AF,AF'               ; keep the holder id
  LD A,(IX+$01)
  CALL FindObject
  LD A,(IX+$07)
  AND $28                 ; bits 5 and 3: active/open/alive, dead/disabled
  JR NZ,FindClosedHolder_0
  EX AF,AF'
FindClosedHolder_1:
  POP IX
  RET

; Point IX at the exits of the actor's location
;
; Takes the location record of the current actor (GetActorLocationRec) and sets
; IX to its exit list minus one exit record (+7), the starting position for
; walkers that step IX by 3 before reading (NextObject). The exit records are
; direction, obstacle object, destination.
;
; O:IX Location record + 7
SeekActorExits:
  PUSH DE
  CALL GetActorLocationRec
  LD DE,EXITS_BIAS
  ADD IX,DE
  POP DE
  RET

; Find the next exit whose destination a typed noun phrase names
;
; Walks the exits of the actor's location (IX from SeekActorExits) and, for
; each, looks up its destination location and matches the typed phrase
; (MatchCommandRecord) against that location's name phrase (record +2, three
; word codes). Returns the destination id of the first match, or $FF when the
; exits are used up. Used for "go to <place>"; ExplainNounFailure falls back to
; the object search when it finds none.
;
; HL Typed noun phrase (three word tokens) IX Exit record before the first to
; examine (SeekActorExits gives the start) O:A Destination location id, $FF
; when no more exits match O:IX The exit record found IY and DE are kept.
FindExitByName:
  PUSH IY
  PUSH DE
  LD DE,$0002             ; offset of the location's first name phrase
FindExitByName_Next:
  CALL NextObject         ; next exit (as 3-byte entries)
  JR Z,FindExitByName_0   ; end of the exits
  LD A,(IX+EXIT_DEST)     ; destination
  PUSH IX
  CALL FindLocation       ; IX = the destination's record
  PUSH IX
  POP IY
  POP IX                  ; back to the exit
  ADD IY,DE               ; IY = its name phrase
  CALL MatchCommandRecord
  JR NZ,FindExitByName_Next ; no match
  LD A,(IX+EXIT_DEST)
FindExitByName_0:
  POP DE
  POP IY
  RET

; Print the name of an object
;
; Prints the name phrases of the record in IY (its words at +8, +10, +12: see
; PrintNamePhrase).
;
; IY Record of the object
PrintObjectName:
  PUSH IY
  PUSH DE
  LD DE,$0008             ; DE = 8, the name phrase codes
  ADD IY,DE
  CALL PrintNamePhrase
  POP DE
  POP IY
  RET

; Print a name phrase
;
; Prints the name phrase at IY: three word codes, the noun at +0 and two
; adjectives at +2 and +4. When PhraseMode ($B703) is 0 the article of the noun
; (PrintArticle) and the two adjectives come first; then the noun is printed by
; PrintNounWord, which adds the article only when PhraseMode is not 0. So
; PhraseMode 0 gives "the wooden chest" and any other value gives "the chest".
; A word code of 0 prints nothing, and a noun code of 0 prints no noun. AF and
; DE are kept.
;
; Hardware: none directly (the words go to the screen through PrintWord).
;
; IY Name phrase (6 bytes: noun, adjective, adjective)
PrintNamePhrase:
  PUSH AF
  PUSH DE
  LD A,(PhraseMode)       ; PhraseMode
  CP $00
  JR NZ,PrintNamePhrase_0 ; noun only
  LD D,(IY+$01)
  LD E,(IY+$00)
  CALL PrintArticle       ; the article of the noun
  LD E,(IY+$02)
  LD D,(IY+$03)
  CALL PrintWord          ; first adjective
  LD E,(IY+$04)
  LD D,(IY+$05)
  CALL PrintWord          ; second adjective
PrintNamePhrase_0:
  LD E,(IY+$00)
  LD D,(IY+$01)
  LD A,D
  OR E
  CALL NZ,PrintNounWord   ; the noun
  POP DE
  POP AF
  RET

; Find the exit of the actor's location in a given direction
;
; Walks the exits of the actor's location (SeekActorExits) for one whose
; direction is A and whose destination is not 0. BC and IY are kept.
;
; A Direction (DIR_NORTH to DIR_DOWN) O:A The direction when the exit exists,
; $FF when it does not O:IX The exit record (direction, obstacle, destination)
; when found
FindExitByDirection:
  PUSH BC
  PUSH IY
  LD B,A                  ; B = direction wanted
  CALL SeekActorExits     ; IX = exits - 3
FindExitByDirection_Next:
  CALL NextObject
  JR Z,FindExitByDirection_0 ; no more exits: A = $FF
  LD A,(IX+EXIT_DEST)
  AND A
  JR Z,FindExitByDirection_Next ; destination 0: not an exit
  LD A,(IX+$00)
  CP B
  JP NZ,FindExitByDirection_Next
FindExitByDirection_0:
  POP IY
  POP BC
  RET

; Find the exit that has the first object as its obstacle
;
; Loads the first object (FirstObject) and joins the exit walk of
; FindExitByDestination with its field selector set to 1, the obstacle byte of
; the exit record. Used to find the exit a door, web or river blocks.
;
; O:A The obstacle id, $FF when the actor's location has no such exit
; O:IX The exit record (direction, obstacle, destination) found
FindExitByObstacle:
  LD A,(FirstObject)
FindExitByObstacle_0:
  PUSH AF
  LD A,$01                ; 1 = field +1 (the obstacle), stored by
                          ; FindExitByField into the displacement at 9F42
  JR FindExitByField

; Find the exit of the actor's location that leads to a given place
;
; Walks the exits of the actor's location (SeekActorExits) for one whose
; destination (record byte +2) is A. At FindExitByField the walk can be told to
; compare another byte of the exit record: the displacement of the LD A,(IX+d)
; at SmcExitField is a self-modified byte, written from A (2 destination here,
; 1 the obstacle from FindExitByObstacle). It is not restored, so it stays as
; last set. BC and IY are kept.
;
; A Destination location id O:A The id when an exit has it, $FF when none has
; O:IX The exit record (direction, obstacle, destination) when found
FindExitByDestination:
  PUSH AF
  LD A,EXIT_DEST          ; compare byte +2
; This entry point is used by the routine at FindExitByObstacle.
FindExitByField:
  LD (SmcExitField+$0002),A ; sets the field the walk compares
  POP AF
  PUSH BC
  PUSH IY
  LD B,A                  ; B = the value looked for
  CALL SeekActorExits     ; IX = exits - 3
FindExitByDestination_Next:
  CALL NextObject
  JR Z,FindExitByDestination_0 ; no more exits: A = $FF
SmcExitField:
  LD A,(IX+$02)           ; the displacement byte is rewritten at
                          ; FindExitByField
  CP B
  JR NZ,FindExitByDestination_Next
FindExitByDestination_0:
  POP IY
  POP BC
  RET

; Swap the actor and target records ($B708/$B70A, $B6E8/$B6E9), run $9B6C, swap
; back
L9F4A:
  LD DE,(Noun1Record)
  LD IY,(Noun2Record)
  LD (Noun1Record),IY
  LD (Noun2Record),DE
  LD BC,(FirstObject)
  LD A,B
  LD (FirstObject),A
  LD A,C
  LD (SecondObject),A
  CALL CallHandler
  LD (FirstObject),BC
  LD (Noun1Record),DE
  LD (Noun2Record),IY
  RET

; Refuse the command
;
; End of a command that cannot be carried out. When the command is really
; performed (ActionPerform is 1) it jumps to PrintCommandSentence, which prints
; "<subject> cannot <the command>."; when it is only being tried it clears the
; "possible" flag (ActionAllowed) and returns.
RefuseCommand:
  LD A,(ActionPerform)
  DEC A
  JP Z,PrintCommandSentence
  SUB A
  LD (ActionAllowed),A
  RET

; Get the one location of a record
;
; For an object or actor that has exactly one location in its list (+0 is 1),
; returns that location (+$10). The NPC loop RunNpcScripts uses it to find
; where an NPC is.
;
;   A Object or actor id, $FF for none
; O:A Its location, or $FF when the id is $FF or it has several locations
; O:IX Record of the object (when A was not $FF)
GetSingleLocation:
  CP $FF
  RET Z
  CALL FindObject
  LD A,$01                ; exactly one location?
  CP (IX+$00)
  LD A,$FF
  RET NZ
  LD A,(IX+$10)
  RET

; Print "You see :" and the objects lying where the actor is
;
; Prints the message "<subject> see :" and lists the objects with the holder
; AT_LOCATION at the actor's location (the first location of the record at
; ActorRecord, $B70C: the player in a location description), or "Nothing"
; (ListObjects). Registers IY, AF and BC are kept.
;
; Hardware: none.
ListObjectsHere:
  PUSH IY
  PUSH AF
  PUSH BC
  LD HL,MsgSee2           ; "<subject> see :"
  CALL PrintMessage
  LD A,AT_LOCATION        ; holder: lying at the location
  LD IY,(ActorRecord)     ; the actor's record
  LD B,(IY+$10)           ; B = its location
  CALL ListObjects        ; list, or "Nothing"
  POP BC
  POP AF
  POP IY
  RET

; List what a holder holds at a location, or print "Nothing"
;
; Lists the objects held by the holder in A (or lying at the location when A is
; $FF) that are at location B and that the actor can reach, indented by
; LIST_INDENT spaces, through ListHolderContents. When none was listed prints
; "Nothing". Used for "You see :" in a location description (ListObjectsHere),
; for the inventory ("<subject> is carrying.", VerbInventory, for an actor in
; B6EA) and for the contents of a container (OpenObject).
;
; A Holder id, or AT_LOCATION for objects lying at the location B Location id
; O:HL Destroyed
ListObjects:
  PUSH IY
  PUSH DE
  PUSH BC
  LD C,$00                ; C counts what is listed
  LD D,LIST_INDENT        ; indent
  CALL ListHolderContents
  SUB A
  CP C
  LD HL,MsgNothing
  CALL Z,PrintMessage     ; nothing listed: "Nothing"
  POP BC
  POP DE
  POP IY
  RET

; List the objects of a holder, one per line, with their contents
;
; Sets the story window indent (ListIndent, $869F: the number of spaces
; OutputStoryChar prints at the start of each line) to D, then walks the object
; table for records whose holder (+1) is A. A record is listed when:
;
; 1. it is at location B: for a holder of $FF it has exactly one location and
; it is B; otherwise its first, or its second, location is B;
;
; 2. it is not the actor itself at the top level (D = LIST_INDENT);
;
; 3. the actor can reach it (ActorCanReach).
;
; A listed object counts in C, then prints its full name (PhraseMode 0) and a
; full stop, and, when it has something to show (PrintContentsHeader returned
; carry clear), the routine calls itself for it with the indent raised by
; LIST_INDENT_STEP. The actor itself gets only a new line. The old indent is
; put back at the end.
;
; Hardware: none directly (the text goes to the screen through PrintChar).
;
; A Holder id, or AT_LOCATION B Location id C Number listed so far (0 at the
; first call) D Indent, in spaces O:A Unchanged O:C Number listed, with the
; contents of the objects listed
ListHolderContents:
  PUSH HL
  LD L,A                  ; L = holder
  LD A,(ListIndent)
  LD H,A                  ; H = the old indent
  LD A,D
  LD (ListIndent),A       ; the new indent
  LD A,L
  EX (SP),HL              ; keep both on the stack
  PUSH IX
  LD IX,ObjectTable-ID_ENTRY_SIZE
ListHolderContents_Next:
  CALL NextObjectKeepA    ; next record, A kept
  JR Z,ListHolderContents_5
  CP (IY+$01)             ; held by the holder?
  JR NZ,ListHolderContents_Next
  PUSH AF
  INC A
  LD E,(IY+$00)           ; E = its number of locations
  JR NZ,ListHolderContents_0 ; a holder
  LD A,$01                ; lying at the location: it must have one location
  CP E
  JR NZ,ListHolderContents_3
ListHolderContents_0:
  LD A,(IY+$10)
  CP B
  JR Z,ListHolderContents_1 ; first location is B
  DEC E
  JR Z,ListHolderContents_3 ; only one location: no
  LD A,(IY+$11)
  CP B
  JR NZ,ListHolderContents_3 ; second location is not B
ListHolderContents_1:
  LD A,(Subject)          ; Subject
  CP (IX+$00)
  JR NZ,ListHolderContents_2
  LD A,LIST_INDENT
  CP D
  JR Z,ListHolderContents_3 ; the actor is not listed at the top level
ListHolderContents_2:
  LD A,(IX+$00)
  CALL ActorCanReach      ; can the actor reach it?
  JR Z,ListHolderContents_3
  INC C                   ; one more listed
  SUB A
  LD (CapitalNext),A      ; CapitalNext := 0
  LD (PhraseMode),A       ; PhraseMode := 0 (adjectives too)
  CALL PrintObjectName    ; print its name
  LD A,(Subject)
  CP (IX+$00)
  JR Z,ListHolderContents_4 ; the actor: just end the line
  LD A,CHAR_FULLSTOP
  CALL PrintChar          ; "."
  LD A,(IX+$00)
  CALL PrintContentsHeader ; header of its contents (or just a new line)
  JR C,ListHolderContents_3 ; nothing to list
  LD A,(IX+$00)
  PUSH DE
  INC D
  INC D                   ; indent two more
  CALL ListHolderContents ; list its contents
  POP DE
ListHolderContents_3:
  POP AF
  JP ListHolderContents_Next
ListHolderContents_4:
  CALL PrintNewLine       ; new line
  JR ListHolderContents_3
ListHolderContents_5:
  POP IX
  EX (SP),HL
  LD A,H
  LD (ListIndent),A       ; the old indent back
  LD A,L
  POP HL                  ; A = the holder again
  RET

; Print the line that introduces what an object holds
;
; For an object that can show its contents (flags +7 bit 5 or 3 set: open or
; alive, or dead) and holds at least one present record (CountHeldPresent)
; prints:
;
; - for a character "<name> is carrying" (the message in MsgCarrying2), then
; clears carry; - for any other holder the relation word of the holder
; (PrintHolderRelation, "In the", "On the"...), its noun and "there is" or
; "there are" (MsgThere, with the word "is" for one thing and "are" for more),
; then clears carry.
;
; Otherwise it ends the line with a new line (PrintNewLine) and sets carry. The
; caller (ListHolderContents, OpenObject) lists the contents when carry is
; clear. BC, DE and IX are kept.
;
; Hardware: none directly (the text goes to the screen through PrintMessage).
;
; A Id of the holder O:F Carry set when there is nothing to list
PrintContentsHeader:
  PUSH IX
  PUSH BC
  PUSH DE
  LD C,A                  ; C = holder id
  CALL FindObject         ; IX = its record
  LD A,(IX+$07)
  AND $28                 ; open, alive or dead?
  JR Z,PrintContentsHeader_4 ; no: nothing to show
  LD A,C
  CALL CountHeldPresent   ; A = how many it holds
  CP $00
  JR Z,PrintContentsHeader_4 ; none
  BIT FLAG_CHARACTER,(IX+$07)
  JR Z,PrintContentsHeader_0
  LD A,C                  ; a character: "<name> is carrying"
  PUSH AF
  LD HL,MsgCarrying2
  JR PrintContentsHeader_2
PrintContentsHeader_0:
  LD HL,WORD_IS           ; "is" for one thing
  DEC A
  JR Z,PrintContentsHeader_1
  LD HL,WORD_ARE          ; "are" for more
PrintContentsHeader_1:
  PUSH HL
  LD L,(IX+$08)           ; the holder's noun
  LD A,(IX+$09)
  AND $0F
  LD H,A
  PUSH HL
  CALL PrintHolderRelation ; "In the" / "On the"...
  LD HL,MsgThere
PrintContentsHeader_2:
  CALL PrintMessage       ; "<noun> there is/are" or "<name> is carrying"
  AND A                   ; carry clear
PrintContentsHeader_3:
  POP DE
  POP BC
  POP IX
  RET
PrintContentsHeader_4:
  CALL PrintNewLine       ; a new line
  SCF
  JR PrintContentsHeader_3

; Print the relation word of a holder
;
; Prints the 4-byte message at MsgInThe + 4 * (state & 15), where the state is
; the low nibble of the holder's state byte (+4): how the holder keeps what is
; in it. The table starts "In the", "On the", "Behind the", "Under the", "Tied
; to the". Used before the name of a container in "<In the> chest: ..." lines.
; The message is printed by a jump to PrintMessage.
;
; IX Record of the holder
PrintHolderRelation:
  LD HL,MsgInThe
  LD A,(IX+$04)           ; state byte (+4)
  RLCA                    ; rotate twice and mask: (state & 15) * 4
  RLCA
  AND $3C
  LD E,A
  LD D,$00
  ADD HL,DE
  JP PrintMessage         ; print and return

; Point IX at the exits of a location
;
; Looks up the location record (FindLocation) and sets IX to its exit list
; minus one exit record, and BC to the size of an exit record, ready for the
; exit walkers NextListedExit and ListExitObstacles, which add BC before
; reading.
;
;   A Location id
; O:IX Location record + 7
; O:BC 3
SeekExitsOfLocation:
  CALL FindLocation
  LD BC,EXITS_BIAS
  ADD IX,BC
  LD BC,EXIT_SIZE
  RET

; Get the dictionary word for an id
;
; Reads the word offset for id A (bit 7 ignored) from the table NameWordTable
; (words, index from 1): 1-10 are the directions north .. down, 11 and up the
; object state words (unlocked, empty, off, closed, dead, locked, full, broken,
; on, open, alive). $A0BD does the same for another table in HL (the state word
; tables ReasonWords1 and ReasonWords2).
;
;   A Id (bit 7 ignored)
;   HL Table of words ($A0BD only; $A0BA uses NameWordTable)
; O:DE Word offset in the dictionary (print with PrintWord); 0 for an id with
;      no word
GetIdWord:
  LD HL,NameWordTable
GetTableWord:
  LD E,A
  RES 7,E
  LD D,$00
  ADD HL,DE
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  RET

; List the doors and other obstacles on the exits of a location
;
; Prints one line "To the <direction> there is <thing>" for every exit whose
; obstacle (door, river, web, portcullis: the second byte of the exit) is an
; object present in the game; for up and down the line starts with "above" or
; "below" instead of "To the". Part of every location description
; (ShowLocation), before the list of the plain exits (ListVisibleExits).
;
; Hardware: none (the text goes through the message printer).
;
; A Location id
; Preserves BC, DE, IX and IY.
ListExitObstacles:
  PUSH BC
  PUSH DE
  PUSH IY
  PUSH IX
  CALL SeekExitsOfLocation ; IX = location record + 7, BC = 3
  ADD IX,BC               ; IX = first exit (direction, obstacle, destination)
  PUSH IX
  POP IY                  ; IY walks the exits
ListExitObstacles_Next:
  SUB A                   ; obstacle 0: nothing to say
  CP (IY+$01)
  JR Z,ListExitObstacles_2
  LD A,(IY+$01)
  CALL FindObject         ; IX = the obstacle record
  BIT FLAG_PRESENT,(IX+$07) ; not present in the game: skip
  JR Z,ListExitObstacles_2
  LD DE,$0008
  ADD IX,DE               ; IX = its first name phrase (+8), the <thing> of the
                          ; message
  PUSH IX
  LD A,(IY+$00)
  CALL GetIdWord          ; DE = direction word
  CP DIR_UP               ; the eight compass directions are below 9
  JR C,ListExitObstacles_0
  LD DE,WORD_ABOVE
  JR Z,ListExitObstacles_1 ; up
  LD DE,WORD_BELOW
  JR ListExitObstacles_1
ListExitObstacles_0:
  LD HL,MsgToThe          ; "To the"
  CALL PrintMessage
ListExitObstacles_1:
  CALL PrintWord          ; the direction word, or above / below
  LD HL,MsgThere2         ; "There is <thing>"
  CALL PrintMessage
ListExitObstacles_2:
  ADD IY,BC               ; next exit
  LD A,END_MARK
  CP (IY+$00)
  JP NZ,ListExitObstacles_Next
  POP IX
  POP IY
  POP DE
  POP BC
  RET

; Step to the next listable exit
;
; Adds BC to IX and skips exit records that are not shown: an exit with an
; obstacle (door, web, river) or an erased one (direction 0, a blocked exit
; whose record was zeroed). Stops at the end mark.
;
;   BC Size of an exit record (3)
;   IX Previous exit record
; O:IX The next listable exit
; O:F Z set when the end mark was reached, NZ with an exit
NextListedExit:
  ADD IX,BC
  LD A,END_MARK
  CP (IX+$00)
  RET Z
  XOR A                   ; obstacle must be 0
  CP (IX+$01)
  JR NZ,NextListedExit
  CP (IX+$00)             ; direction must not be 0
  JR Z,NextListedExit
  RET

; List the visible exits of a location
;
; Prints "Visible exits are:" and the direction word of every exit that has no
; obstacle and is not erased (NextListedExit), then a new line. Prints nothing
; when there is no such exit. Part of every location description
; (ShowLocation), after the obstacles (ListExitObstacles); also the second
; entry of that description at $967F.
;
; Hardware: none (the text goes through the message printer).
;
; A Location id
; Preserves BC, DE, IX and IY.
ListVisibleExits:
  PUSH IX
  PUSH IY
  PUSH DE
  PUSH BC
  CALL SeekExitsOfLocation ; IX = location record + 7, BC = 3
  CALL NextListedExit     ; IX = first listable exit
  JR Z,ListVisibleExits_0 ; none: print nothing
  LD HL,MsgVisibleExits   ; "Visible exits are:"
  CALL PrintMessage
ListVisibleExits_Next:
  LD A,(IX+$00)           ; direction id of the exit
  CALL GetIdWord          ; DE = direction word
  CALL PrintWord          ; print the word
  CALL NextListedExit     ; next listable exit
  JR NZ,ListVisibleExits_Next
  CALL PrintNewLine       ; end the line
ListVisibleExits_0:
  POP BC
  POP DE
  POP IY
  POP IX
  RET

; Print "<object> is <state>" for the object in IY
;
; Loads the first name phrase (+8) of the record in IY and joins PrintStateHL,
; which prints a message such as "The door is closed." with the state word
; chosen by the id in A (see PrintStateIX).
;
; A State id (bit 7 selects the second word table)
; IY Record of the object
PrintStateIY:
  LD L,(IY+$08)
  LD H,(IY+$09)
  JR PrintStateHL

; Print "<object> is <state>" for the object in IX
;
; Loads the first name phrase (+8) of the record in IX and falls into $A172.
;
; $A172 picks the state word for the id in A from ReasonWords1 (bit 7 clear:
; unlocked, empty, off, closed, dead) or from ReasonWords2 (bit 7 set: locked,
; full, broken, on, open, alive), indexed by the id without bit 7, and prints
; "<the phrase> is <word>." with MsgTheArgIsWord. The commands use it to say
; why they failed ("The door is locked.") or what they did ("The goblin is
; dead.").
;
; Hardware: none (the text goes through the message printer).
;
; A State id (bit 7 selects the second word table)
; IX Record of the object (not used at $A172)
; HL Name phrase of the object ($A172 only)
; Preserves DE.
PrintStateIX:
  LD L,(IX+$08)
  LD H,(IX+$09)
; This entry point is used by the routine at PrintStateIY.
PrintStateHL:
  PUSH DE
  PUSH HL
  LD HL,ReasonWords1      ; table of the ids without bit 7
  BIT 7,A
  JR Z,PrintStateIX_0
  LD HL,ReasonWords2      ; bit 7 set: the other table
PrintStateIX_0:
  CALL GetTableWord       ; DE = state word
  POP HL
  PUSH DE
  PUSH HL
  LD HL,MsgTheArgIsWord   ; <the_arg> is <word>.
  CALL PrintMessage
  POP DE                  ; restore DE
  RET

; Mark an object or actor as broken or dead
;
; Replaces the second name phrase (+10) of the record with the word "broken"
; (an object) or "dead" (a character, flag bit 6), and clears the third (+12),
; so its name prints as "broken sword", "dead goblin". Used after a fight
; (StrikeObject, KillCharacter, ThorinDeathBreaksKey).
;
; A Object or actor id
MarkBrokenOrDead:
  PUSH IX
  CALL FindObject
  LD (IX+$0C),$00         ; clear the third name phrase
  LD (IX+$0D),$00
  LD DE,PHRASE_BROKEN
  BIT FLAG_CHARACTER,(IX+$07)
  JR Z,MarkBrokenOrDead_0
  LD DE,PHRASE_DEAD
MarkBrokenOrDead_0:
  LD (IX+$0A),E
  LD (IX+$0B),D
  POP IX
  RET

; Find the record in table $C060 whose id matches IY+1 (unreferenced), then
; $A1C8 test
LA1AE:
  PUSH IY
  PUSH IX
  LD IX,ObjectTableBase
LA1AE_0:
  CALL NextObjectKeepA
  JR Z,LA1AE_1
  CP (IY+$01)
  JR NZ,LA1AE_0
LA1AE_1:
  LD A,(IX+$00)
  POP IX
  POP IY
  RET
LA1AE_2:
  LD A,(IX+$07)
  AND $48
  CP $40
  RET
