; Test whether the command can be applied to the first object
;
; Sets ActionAllowed to 1 when the verb (CommandId) makes sense for the first
; object, otherwise to 0. It is 0 when the nouns clash (CheckNounsDistinct says
; Z: the object is the subject or the second object). Otherwise it is 1 when
; the verb has a default handler (VerbHandlers), or when it is a placing
; command (IsPlacingCommand, whose second object takes the first), or when the
; object's own verb table has an entry for the verb (FindVerbEntry).
; NextNoun1Match calls it for each candidate of an ambiguous noun and takes the
; first one for which the answer is 1.
;
; IX and HL are preserved.
;
;   CommandId The verb to try
;   FirstObject The candidate object
; O:ActionAllowed 1 when the verb applies, 0 when not
CheckVerbApplies:
  PUSH IX
  PUSH HL
  CALL CheckNounsDistinct ; nouns distinct?
  LD A,$00
  JR Z,CheckVerbApplies_0 ; no: 0
  LD A,(CommandId)
  LD IX,VerbHandlers      ; default handlers
  CALL FindIdRecord
  CP END_MARK             ; found one?
  LD A,$01
  JR NZ,CheckVerbApplies_0 ; yes: 1
  CALL IsPlacingCommand   ; a placing command?
  LD A,$01
  JR Z,CheckVerbApplies_0 ; yes: 1
  LD A,(FirstObject)      ; the object's own verb table
  CALL FindObject
  LD A,(CommandId)
  CALL FindVerbEntry
  LD A,$01
  JR C,CheckVerbApplies_0 ; has the verb: 1
  SUB A                   ; else 0
CheckVerbApplies_0:
  LD (ActionAllowed),A
  POP HL
  POP IX
  RET

; Carry out the command in the parser variables (test pass or real pass)
;
; Finds the code that does the current command and calls it. The command is
; CommandId with FirstObject and SecondObject for the actor Subject. The caller
; runs it twice: first with ActionPerform = 0 (the test pass: the handlers only
; check, print a refusal and clear ActionAllowed, or set it to 1 when the
; command may go on; RunCheck reads the result), then with ActionPerform = 1
; (the real pass: the handlers do the work and print the result). The typed
; command, RunSentences, and every command an NPC runs (RunActorCommand) go
; through here.
;
; Steps. A command that names the same thing twice is refused
; (CheckNounsDistinct, "I cannot do that."). If the actor is the player and it
; is dark (CheckDark), the command is refused with "I see nothing here." unless
; the command is one that does not need light ($B711 = 0, set by UnpackFlags)
; and the objects named are held by the actor (CheckObject1Held,
; CheckHeldBySubject). Then the handlers are found: with no first object, or a
; noun that names a place reached by an exit and not an object (Noun1Kind or
; Noun2Kind = 1; UnpackFlags), the default table VerbHandlers ($C730) is used.
; Otherwise each object is looked up (FindObject) and a thing that another
; character carries stops the command (CheckHeldByOther, it prints its own
; message). The verb table of an object (FindVerbEntry) is searched for
; CommandId: in the second object when the command puts the first somewhere
; (IsPlacingCommand: drop in, put in, put on, take out of, throw through), in
; the first object otherwise. If that object has no entry for the verb,
; VerbHandlers is searched (FindIdRecord); if that has none either, "I cannot
; do that." is printed. Every handler found is called through CallHandler: the
; entry for the verb and then each entry that follows it with verb id 0 (these
; are called for every verb).
;
; On the real pass for the player the dark is tested again after the handlers
; (an action may have put the light out): "It is dark." is printed. Then both
; objects are shown to NotifyCharacter so that a living character who was the
; target of the command switches to its script for that verb.
;
; Hardware: none itself; the handlers print.
;
; CommandId The verb id (1-59) FirstObject First object id or $FF SecondObject
; Second object id or $FF Subject Who acts (0 the player) ActionPerform 0 test
; pass, 1 real pass O:ActionAllowed After the test pass: 1 when the command is
; allowed, 0 when it is refused (RunCheck reads it) HL, IX and BC are
; preserved.
DispatchCommand:
  PUSH HL                 ; save the registers
  PUSH IX
  PUSH BC
  CALL CheckNounsDistinct ; CheckNounsDistinct: Z = the same thing twice
  JP Z,DispatchCommand_6  ; refuse: "I cannot do that."
  CALL CheckDark          ; CheckDark: carry = the subject cannot see
  JR NC,DispatchCommand_1 ; lit: go on
  LD A,(NeedsLight)       ; dark: does the command need light? (NeedsLight, set
                          ; by $7B78)
  AND A
  JR NZ,DispatchCommand_0
  CALL CheckObject1Held   ; is the first object held by the subject?
  JR NC,DispatchCommand_0 ; no: refuse
  LD A,(SecondObject)     ; and the second one?
  CALL CheckHeldBySubject
  JR C,DispatchCommand_1  ; both held: go on in the dark
DispatchCommand_0:
  LD HL,MsgISeeNothingHere ; "I see nothing here."
  CALL PrintMessage
  JR DispatchCommand_Done ; no handler is run
DispatchCommand_1:
  LD A,(Noun1Kind)        ; Noun1Kind
  CP $01                  ; the first noun is a place: default table
  JP Z,DispatchCommand_Default
  LD A,(FirstObject)
  CP NO_OBJECT            ; no first object: default table
  JP Z,DispatchCommand_Default
  CALL FindObject         ; IX = record of the first object
  LD (Noun1Record),IX     ; keep it for the end of the pass
  LD A,(FirstObject)
  CALL CheckHeldByOther   ; another character carries it? (message)
  JR NZ,DispatchCommand_Done ; yes: stop
  LD A,(SecondObject)
  CP NO_OBJECT            ; no second object: use the first one
  JR Z,DispatchCommand_2
  LD A,(Noun2Kind)        ; Noun2Kind
  CP $01
  JR Z,DispatchCommand_Default
  LD A,(SecondObject)     ; IX = record of the second object
  CALL FindObject
  LD (Noun2Record),IX     ; keep it for the end of the pass
  CALL CheckHeldByOther   ; another character carries it? (message)
  JR NZ,DispatchCommand_Done ; yes: stop
  CALL IsPlacingCommand   ; does the command put the first object into the
                          ; second?
  JR Z,DispatchCommand_3  ; yes: the second object has the handler
DispatchCommand_2:
  LD IX,(Noun1Record)     ; no: the first object has it
DispatchCommand_3:
  LD A,(CommandId)        ; the verb id
  CALL FindVerbEntry      ; FindVerbEntry in the object
  JR NC,DispatchCommand_Default ; none: default table
DispatchCommand_Call:
  LD L,(IX+$01)           ; HL = handler of the entry
  LD H,(IX+$02)
  CALL CallHandler        ; call it unless it is 0
  INC IX                  ; next entry
  INC IX
  INC IX
  SUB A                   ; an entry with verb id 0 follows:
  CP (IX+$00)
  JR Z,DispatchCommand_Call ; it is called too
DispatchCommand_Done:
  LD A,(ActionPerform)    ; ActionPerform
  CP $01                  ; test pass: nothing more
  JR NZ,DispatchCommand_5
  LD A,(Subject)          ; Subject
  CP PLAYER               ; not the player: no dark test
  JR NZ,DispatchCommand_4
  CALL CheckDark          ; is the player in the dark now?
  CALL C,PrintMessage     ; "It is dark."
DispatchCommand_4:
  LD A,(CommandId)        ; B = the verb id
  LD B,A
  LD A,(FirstObject)      ; the first object
  LD IX,(Noun1Record)     ; and its record
  CALL NotifyCharacter    ; NotifyCharacter
  LD A,(SecondObject)     ; the second object
  LD IX,(Noun2Record)     ; and its record
  CALL NotifyCharacter    ; NotifyCharacter
DispatchCommand_5:
  POP BC                  ; restore the registers
  POP IX
  POP HL
  RET
DispatchCommand_Default:
  LD A,(CommandId)        ; the verb id
  LD IX,VerbHandlers      ; VerbHandlers
  CALL FindIdRecord       ; find the verb
  CP END_MARK             ; not in the table?
  JR NZ,DispatchCommand_Call ; found: call it
DispatchCommand_6:
  CALL PrintCannotDoThat  ; "I cannot do that."
  JR DispatchCommand_5

; Let a living character react to a command
;
; If the record at IX is a character (flag bit 6) that is not dead (flag bit 3)
; hands the command to SwitchNpcScript, which switches the character's script
; to its behaviour for that command. Other records are ignored.
;
; A Object id of the record B Command id (verb) IX Record of object A
NotifyCharacter:
  BIT FLAG_CHARACTER,(IX+$07)
  RET Z                   ; not a character
  BIT FLAG_DEAD,(IX+$07)
  RET NZ                  ; dead or disabled
  CALL SwitchNpcScript
  RET

; Test whether the subject is in the dark
;
; Carry set means the subject cannot see: HL is then MsgDark ("It is dark.").
; Only the player can be in the dark; any other subject (a non-zero Subject)
; always sees. The player sees when none of these holds: standing inside a
; closed holder (FindClosedHolder finds one), or in a location whose flags have
; the lit bit (LOC_LIT, bit 7) clear (caves and dungeons). In those cases it is
; still light when the light source, object $0E (OBJ_SHORT_STRONG_SWORD), is
; within the player's reach (ActorCanReach) and its flags have bits 4 and 2 set
; and bit 3 clear ($94 at the start). Observed in the simulator by moving the
; player to cave $0E and the sword there and varying its flags.
;
; Called by the picture drawing (StartPicture), the move handler (VerbMove),
; the command dispatcher (DispatchCommand), UpdatePlayerSight,
; PrintCommandSentence and VerbCapture.
;
; IX, IY, BC are preserved.
;
;   Subject 0 for the player
; O:F Carry set when it is dark
; O:HL MsgDark when it is dark
CheckDark:
  LD A,(Subject)
  AND A
  RET NZ                  ; not the player: sees (carry clear)
  PUSH IX
  PUSH BC
  LD IX,Chr00Player       ; the player
  CALL FindClosedHolder   ; closed holder
  INC A
  JR NZ,CheckDark_0       ; inside one: needs the light
  CALL GetActorLocationRec ; the location record
  BIT LOC_LIT,(IX+$00)    ; lit?
  JR NZ,CheckDark_2       ; yes: sees
CheckDark_0:
  PUSH IY
  LD A,OBJ_SHORT_STRONG_SWORD
  LD IY,Obj0EShortStrongSword ; the light source
  CALL ActorCanReach      ; within reach?
  POP IY
  JR Z,CheckDark_1        ; no: dark
  LD A,(Obj0ESwordFlags)  ; its flags
  XOR LIGHT_FLAGS_XOR
  AND LIGHT_FLAGS_MASK    ; bits 4 and 2 set, bit 3 clear?
  JR Z,CheckDark_3        ; yes: light
CheckDark_1:
  LD HL,MsgDark           ; "It is dark."
  SCF
CheckDark_2:
  POP BC
  POP IX
  RET
CheckDark_3:
  AND A                   ; carry clear
  JR CheckDark_2

; Describe a location with the "see" message
;
; Prints MsgSee ("<subject> see") followed by the location's description and
; picture through DescribeLocation_Intro. VerbLookThrough calls it while it has
; temporarily put the same id into the first location slot of the subject's
; record.
;
; A Location id
DescribeSeen:
  LD HL,MsgSee
  JR DescribeLocation_Intro

; Describe a location as "<subject> are in ..." with its picture
;
; Chooses the preposition of the location from its flags (bits 1-3, times 2,
; index into LocationPrepositions: outside, inside, in, on, at) and writes that
; phrase code over the second item of MsgSubjIsIn (self-modifying message data
; at $AFFD-$AFFE, high byte first), so the message reads "You are in", "You are
; on" and so on. Then it joins DescribeLocation_Intro with that message.
;
; The player sees this when entering a location for the first time and for LOOK
; (VerbMove, VerbLook); a visited location gets the shorter
; DescribeLocationShort.
;
; Hardware: draws the picture and may wait for a key (see ShowLocation).
;
; A Location id O:IX Record of the location (the entry at $964D keeps IX, IY
; and BC)
DescribeLocation:
  PUSH AF
  CALL FindLocation       ; the location record in IX
  LD A,(IX+$00)           ; flags
  AND LOC_PREP_MASK
  LD E,A
  LD D,$00
  LD HL,LocationPrepositions ; LocationPrepositions
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)               ; DE = the phrase code
  LD HL,MsgSubjIsIn+$0001
  LD (HL),D               ; patch the message
  INC HL
  LD (HL),E
  POP AF
  LD HL,MsgSubjIsIn       ; MsgSubjIsIn: "<subject> are in"
; Entry point: describe location A, starting with the message at HL (also
; DescribeSeen and VerbCapture).
DescribeLocation_Intro:
  PUSH IX
  PUSH IY
  PUSH BC
  CALL ShowLocation       ; print the intro, the description and the picture
  POP BC
  POP IY
  POP IX
  RET

; Show a location: its text, picture, obstacles, exits and objects
;
; The second half of DescribeLocation (which has put the "<subject> are in"
; intro message in HL). Prints the intro, then the location's description
; message or its name (PrintLocationText), draws the picture
; (DrawLocationPicture) and, when one was drawn, waits for a key
; (WaitKeyAfterPicture; the border goes white). Then a new line, the doors and
; other obstacles (ListExitObstacles), the visible exits (ListVisibleExits) and
; "You see :" with the objects lying here (ListObjectsHere).
;
; Hardware: the picture drawing and the key wait (see DrawLocationPicture,
; WaitKeyAfterPicture).
;
; A Location id
; HL Intro message
ShowLocation:
  LD B,A                  ; B = location
  CALL FindLocation       ; IX = its record
  CALL PrintMessage       ; "<subject> are in"
  LD L,(IX+$08)           ; HL = description message (+8) ...
  LD H,(IX+$09)
  LD A,H                  ; ... Z when it has none
  OR L
  CALL PrintLocationText  ; description or name
  LD A,B
  CALL DrawLocationPicture ; the picture
  LD A,(PictureFound)     ; PictureFound
  INC A                   ; $FF: no picture drawn
  CALL NZ,WaitKeyAfterPicture ; keep the picture until a key is pressed
  CALL PrintNewLine       ; new line
  LD A,B                  ; doors, rivers, webs on the exits
  CALL ListExitObstacles
; Entry point of DescribeLocationShort: the lists without the picture.
ShowLocation_Lists:
  LD A,B                  ; B = location
  CALL ListVisibleExits   ; visible exits
  JP ListObjectsHere      ; "You see :" and the objects here

; Print a location's description text or its name
;
; Prints the description message of the location when it has one (its record's
; word +8, passed here as the flag NZ), otherwise falls into PrintLocationName.
;
; F NZ when the location has a description message
; HL The description message (record +8), when F is NZ
; IX Record of the location
PrintLocationText:
  JP NZ,PrintMessage      ; print the message
; Entry point (also used by DescribeLocationShort): print the location's name
; as words.
PrintLocationName:
  LD DE,LOC_NAME_OFFSET   ; name phrase codes at +2
  PUSH IY
  PUSH IX
  POP IY
  ADD IY,DE               ; IY: the name phrase codes of the location
  CALL PrintNamePhrase    ; print adjectives and noun
  POP IY
  RET

; Wait for a key after a picture
;
; Waits until any key is down (reading all 8 keyboard half-rows at once), then
; sets the border to white. ShowLocation calls it after drawing a location's
; picture, so the picture stays on the screen until a key is pressed. Does not
; wait for the key to be released.
;
; Hardware: keyboard port $FE (all half-rows); border colour via port $FE.
WaitKeyAfterPicture:
  XOR A
  IN A,(PORT_ULA)         ; A = 0 selects every half-row
  AND KEY_BITS
  CP KEY_BITS
  JR Z,WaitKeyAfterPicture ; no key: keep waiting
  LD A,BORDER_WHITE
  OUT (PORT_ULA),A        ; border white
  RET

; Show a visited location: its name and the lists, without the picture
;
; The short description of a location the player has seen before (the long one
; is DescribeLocation): prints the location's name as words
; (PrintLocationName), a new line, and continues in ShowLocation with the
; obstacles, the exits and the objects here.
;
; Hardware: none.
;
; A Location id
DescribeLocationShort:
  CALL FindLocation       ; IX = the record
  CALL PrintLocationName  ; name only (no description message, no picture)
  CALL PrintNewLine       ; new line
  JR ShowLocation_Lists   ; ShowLocation_Lists

; End of a turn: win test, NPC scripts, timers
;
; Called after every command the player's turn consists of (RunSentences, once
; the command has been carried out). First the treasure is tested
; (CheckVictory: when the valuable treasure is in the chest the game ends).
; Then every NPC runs its script (RunNpcScripts). Then the timers (Timers, 10
; records of 7 bytes, $FF in byte 0 ends the table) are stepped:
;
; +0 byte: the value the timer starts counting from (the code that starts a
; timer copies it into the counter, e.g. ArriveBog; only the end mark is tested
; here) +1 byte: counter, 0 = the timer is stopped +2 word: handler called when
; the counter reaches 0 (the timer fires) +4 byte: tick threshold, 0 = no tick
; +5 word: handler called on a turn that leaves the counter between 1 and the
; threshold (a tick)
;
; A running timer (counter not 0) is counted down. When it reaches 0 it fires,
; but only one timer fires in a turn (TimersFired): a second timer that would
; fire in the same turn has its counter set to 1 instead and fires on the next
; turn. A timer that has not fired and whose counter is at most the threshold
; calls its tick handler. Handlers are called with ActionPerform and
; ActionAllowed both 1, so they act and print. They can start timers, move
; characters, print messages (the player sees them when MessagesVisible is 1;
; it is set to 1 at the end of the turn).
;
; Hardware: none itself; the handlers print.
;
; All registers are preserved.
L96B3:
  PUSH HL
  PUSH IX
  PUSH IY
  PUSH BC
  PUSH DE
  CALL CheckVictory       ; the treasure in the chest ends the game
  CALL RunNpcScripts      ; run every NPC
  SUB A                   ; no timer has fired this turn
  LD (TimersFired),A
  INC A                   ; A = 1
  LD (ActionAllowed),A    ; ActionAllowed = 1
  LD (ActionPerform),A    ; ActionPerform = 1: real pass
  LD IY,Timers            ; the first timer
EndTurn_Timer:
  LD A,(IY+$00)           ; byte 0
  CP END_MARK             ; the end of the table?
  JR Z,L96B3_1
  LD A,(IY+$01)           ; the counter
  CP $00                  ; stopped: next timer
  JR Z,L96B3_0
  DEC A                   ; count down
  LD (IY+$01),A
  CP $00                  ; not 0 yet: tick test
  JR NZ,EndTurn_Tick
  LD A,(TimersFired)      ; has a timer fired this turn?
  CP $01                  ; (flags kept by the LD below)
  LD (IY+$01),A           ; counter := TimersFired: 0 if it fires, 1 if it is
                          ; put off one turn
  JR Z,EndTurn_Tick       ; another one fired: put off
  INC A                   ; TimersFired := 1
  LD (TimersFired),A
  LD L,(IY+$02)           ; the fire handler
  LD H,(IY+$03)
  CALL CallHandler        ; call it unless it is 0
  JR L96B3_0              ; next timer
EndTurn_Tick:
  LD A,(IY+$04)           ; the threshold
  CP $00
  JR Z,L96B3_0            ; 0: no tick handler
  CP (IY+$01)             ; compare with the counter
  JR C,L96B3_0            ; counter above the threshold: no tick
  LD L,(IY+$05)           ; the tick handler
  LD H,(IY+$06)
  CALL CallHandler        ; call it unless it is 0
L96B3_0:
  LD DE,TIMER_RECORD_SIZE ; next timer
  ADD IY,DE
  JP EndTurn_Timer
L96B3_1:
  LD A,$01                ; messages from now on show
  LD (MessagesVisible),A
  POP DE
  POP BC
  POP IY
  POP IX
  POP HL
  RET

; Report an object that another character is carrying
;
; Used by the command dispatcher (DispatchCommand) on each noun before a
; command runs. Does nothing unless the subject is the player and the object
; has a place (is not lying at a location). When the object is not held by the
; player (CheckHeldBySubject) but, at the top of its holder chain, by a
; character and the player's present flag (bit 7 of its flags at
; Chr00PlayerFlags) is set, it prints "<the character> is carrying <the
; object>." (MsgCarrying3) and the command is abandoned by the caller.
;
; IX, IY and BC are preserved.
;
; A Object id, or $FF for none O:F NZ when the message was printed, Z when not
CheckHeldByOther:
  CP $FF                  ; no object: Z
  RET Z
  PUSH IX
  PUSH IY
  PUSH BC
  LD B,A                  ; B = object
  LD A,(Subject)
  CP $00                  ; only the player is told
  JR Z,CheckHeldByOther_0
  XOR A                   ; Z
  JR CheckHeldByOther_1
CheckHeldByOther_0:
  LD A,B
  CALL FindObject
  LD A,(IX+$01)           ; holder
  CP AT_LOCATION          ; lies at a location: nothing to say
  JR Z,CheckHeldByOther_1
  LD A,B
  PUSH IX
  POP IY                  ; IY = the object
  CALL CheckHeldBySubject ; held by the player?
  JR C,CheckHeldByOther_1 ; yes: nothing to say
  CALL FindObject         ; A = top of the holder chain: its record in IX
  BIT FLAG_CHARACTER,(IX+$07) ; a character?
  JR Z,CheckHeldByOther_1
  LD A,(Chr00PlayerFlags) ; player's flags
  BIT FLAG_PRESENT,A
  JR Z,CheckHeldByOther_1
  LD L,(IY+$08)           ; the object's name
  LD H,(IY+$09)
  PUSH HL
  LD L,(IX+$08)           ; the carrier's name
  LD H,(IX+$09)
  PUSH HL
  LD HL,MsgCarrying3      ; "<the carrier> is carrying <the object>."
  CALL PrintMessage
  OR $01                  ; NZ: said
CheckHeldByOther_1:
  POP BC
  POP IY
  POP IX
  RET

; Wound/score helper: A=($B6E8), continues at $977F (called from $A30D)
L977C:
  LD A,(FirstObject)

; Kill a character
;
; Called when a fight or a shot kills someone (VerbAttack, L9065, L929C and
; more). With A = 0 the player is dead: the game ends in EndGame ("<subject> is
; dead." and a restart). Otherwise the character A is marked dead (flag bit 3),
; what it carries is put down where it stands (EmptyHolder moves its contents
; to its own holder, and liquids evaporate), its NPC record is made dormant by
; clearing its id so that the NPC loop no longer runs it, its name becomes
; "dead ..." (MarkBrokenOrDead) and its pending orders are freed
; (FreeOrderSlots).
;
; BC, IX and IY are preserved.
;
; A Id of the character that dies, 0 for the player
KillCharacter:
  AND A
  JP Z,EndGame            ; the player: game over
  PUSH BC
  PUSH IY
  PUSH IX
  LD C,A                  ; C = the character
  CALL FindObject
  SET FLAG_DEAD,(IX+$07)  ; dead
  CALL EmptyHolder        ; put down what it carries
  LD A,C
  CALL FindNpcState       ; its NPC record
  CP END_MARK
  LD A,C
  JR Z,KillCharacter_0    ; none
  LD (IY+$00),$00         ; dormant: the NPC loop skips it
KillCharacter_0:
  CALL MarkBrokenOrDead   ; name becomes "dead ..."
  LD A,C
  CALL FreeOrderSlots     ; free its order slots
  POP IX
  POP IY
  POP BC
  RET

; Set up a new game: the blocked exit, the random event, the actor
;
; Called once from the start routine (GameStart). Clears Subject (the player
; acts), ExitRestoreMode and ReplyGiven, and makes the player the acting actor
; (ActorRecord = Chr00Player).
;
; Then it chooses which of the 5 BlockedExits records is active this game
; (RandomUpTo(BLOCKED_EXIT_MAX) + 1), remembers the record by patching the
; operand of the LD IY,nn at $A7CF (ExamineMap puts the exit back later), and
; zeroes that exit triple (direction, obstacle, destination) in the location
; record, so the exit does not exist until ExamineMap restores it. Last it
; picks one of the 4 RandomEvents records (RandomUpTo(RANDOM_EVENT_MAX)) into
; RandomEventPtr.
;
; The random numbers are why the game differs each time (the seed is the R
; register at the first key, GameStart).
InitNewGame:
  SUB A
  LD (Subject),A          ; the player acts
  LD (ExitRestoreMode),A  ; ExitRestoreMode
  LD (ReplyGiven),A       ; ReplyGiven
  LD HL,Chr00Player
  LD (ActorRecord),HL     ; ActorRecord = the player
  LD A,BLOCKED_EXIT_MAX
  CALL RandomUpTo         ; 0-4
  INC A
  LD B,A                  ; 1-5
  LD IY,BlockedExits-BLOCKED_EXIT_SIZE ; the table starts one record later
  LD DE,BLOCKED_EXIT_SIZE
InitNewGame_Step:
  ADD IY,DE
  DJNZ InitNewGame_Step   ; IY = record B
  LD (SmcBlockedExit+$0002),IY ; patches the LD IY,nn at $A7CF (ExamineMap)
  LD L,(IY+$01)           ; the exit triple in the location record
  LD H,(IY+$02)
  LD B,EXIT_SIZE
InitNewGame_0:
  LD (HL),$00             ; remove the exit
  INC HL
  DJNZ InitNewGame_0
  LD A,RANDOM_EVENT_MAX
  CALL RandomUpTo         ; 0-3
  LD E,A
  LD D,$00
  SLA E
  SLA E                   ; times 4 (the size of a random event record)
  LD HL,RandomEvents      ; RandomEvents
  ADD HL,DE
  LD (RandomEventPtr),HL  ; RandomEventPtr
  RET

; Print a message, then a full stop and a new line
;
; Used by the scripted events (WargHowls, ThorinTalks) for sentences whose
; messages have no ending of their own.
;
; HL Message to print
PrintMessageDot:
  CALL PrintMessage
  LD A,CHAR_FULLSTOP
  CALL PrintChar          ; the full stop
  JP PrintNewLine         ; new line

; Return from the caller unless the action is to be performed
;
; Reads ActionPerform (C) and ActionAllowed (B) and ANDs them. If the result is
; non-zero the routine returns normally. If it is zero it discards its own
; return address, so the handler that called it returns to its caller at once.
; Handlers use it to skip their effects in the test pass and after a refusal.
;
; Preserves BC.
AbortUnlessPerform:
  PUSH BC
  LD BC,(ActionPerform)   ; C = ActionPerform, B = ActionAllowed
  LD A,C
  AND B
  JR NZ,AbortUnlessPerform_0
  POP BC                  ; restore BC, then drop the return address
AbortUnlessPerform_0:
  POP BC                  ; restore BC (or the dropped word)
  RET

; Three bytes of the turn routines ($980E, $99C6)
NpcFailures:
  DEFB $00
SightState:
  DEFB $00
FirstObjectPlace:
  DEFB $00

; Run the script of every NPC for one turn (the script interpreter)
;
; Called by L96B3 after each player command. Goes through the NPC states
; (NpcStates, 17 records of 7 bytes, $FF ends) and lets each NPC with an id do
; commands from its script until one of them succeeds or it has failed six
; times.
;
; Per NPC. Subject is the NPC's id (a record with id 0 is a dormant slot that
; events fill in, and is skipped), its record goes to ActorRecord, its place to
; ActorLocation. MessagesVisible is cleared and set to 1 only when the player
; can see the NPC act: the NPC is within the player's reach (CanReachSwapped)
; and the player is not in the dark. In the dark, the first NPC within reach
; makes SightState go from 1 to 2 and "You hear a noise." is printed once for
; the turn (after that nothing of the NPCs is printed). NpcFailures counts the
; failures of the NPC. An NPC that is held by something (its record's holder is
; not AT_LOCATION) is passed to NpcHeld: the NPC acts as usual when the holder
; is dead or disabled or is a character; otherwise it does nothing, unless the
; holder is open or alive, when it tries to climb out (command $37) instead.
; ActorHasOrder is 1 when the NPC owns a stored order (given with SAY TO,
; FindOrderSlotKeep). At the end the Subject is the player again,
; MessagesVisible is 1 and ActorRecord points to the player's record.
;
; THE SCRIPT LANGUAGE. An NPC state record is: +0 id, +1 the highest entry
; number for random choices, +2 word, the current script (address of the next
; command), +4 word, the behaviour table, +6 not used by the interpreter. A
; script is a row of commands in $C82D-$CA83. The first byte of a command is
; the command byte: bits 0-3 are the op, bit 4 says that a word follows the
; command, bit 5 (SCRIPT_BIT_ERASE) erases the command byte after a success
; (RunScriptCommand), bit 6 (SCRIPT_BIT_NO_ORDER) says that a stored order must
; not replace the command, bit 7 is not used. The word of bit 4 is the
; ALTERNATIVE address, a script address: where the NPC goes when the command
; fails (it is the last two bytes of the command, and the command is 2 bytes
; longer). The ops:
;
; 0 and 2: verb, object 1, object 2 (4 bytes). The NPC does the command as if
; it were typed (a verb id from the command table, $FF as an object means none;
; ids of objects and characters are in the ids list). RunScriptCommand,
; RunActorCommand.
;
; 1 and 3: routine word, one unused byte (4 bytes). The routine is called in
; two passes like a verb handler and must set ActionAllowed to 1 in the first
; to agree. RunScriptCommand.
;
; 4: verb (2 bytes). The command without objects: a move (verbs 1-10 are the
; directions), or $24 (run) and $30 (capture, default handler VerbCapture). A
; verb of $FF does nothing: the NPC is done for the turn, or jumps to the
; alternative address when there is one. RunScriptVerb.
;
; 5-9, B and D: end of the script (1 byte; $07 is the one used). The NPC takes
; the script of entry 0 of its behaviour table (the default script,
; SelectScript) and is done for this turn.
;
; C: behaviour id (2 bytes). Takes the script of the entry with that id in the
; behaviour table (SwitchNpcScript) and goes on with it at once.
;
; E: script address (3 bytes). Jumps there and goes on with it at once.
;
; F: highest entry number (2 bytes). Takes the script of a random entry of the
; behaviour table, from 0 to the smaller of this number and the record's +1
; (ChooseRandomScript), and goes on at once.
;
; The behaviour table of an NPC is a row of (id, script word) entries ended by
; $FF. Entries 0 to the record's +1 have id 0 and are the scripts that op F and
; the end ops choose among (entry 0 is the default). The entries after them
; have as their id a command id: when a living NPC is the first or second
; object of a command that was just done, the entry for that verb (15 attack,
; 29 give, 48 capture) becomes its script (NotifyCharacter, SwitchNpcScript).
;
; A turn. The NPC takes the command at its current script address. Ops C, E and
; F cost no time. A command of op 0-4 is tried: when it succeeds the script
; address is already past it and the NPC is done for the turn. When it fails
; the failure counter NpcFailures goes up; the NPC then goes to the alternative
; address of the command if it has one, or to the next command; at 6 failures
; the NPC is done for the turn and goes on from there next turn. A command is a
; failure when the test pass of the command refuses it (RunActorCommand).
;
; Stored orders. If the NPC owns a stored order (ActorHasOrder = 1) and the
; command to be tried is an op 0-4 without bit 6, the order is taken first
; (RunStoredOrder, once per turn). If it parses and is allowed, the NPC does
; that order instead (RunActorCommand_Run) and is done for the turn: the script
; address does not move. Otherwise the script command is tried.
;
; Hardware: none itself; the commands print through the message printer.
RunNpcScripts:
  CALL UpdatePlayerSight  ; SightState, PlayerLocation
  LD IY,NpcStates         ; the first NPC state
RunNpcScripts_0:
  XOR A
  LD (NpcFailures),A      ; no failures yet (NpcFailures)
  LD A,(IY+$00)           ; NPC id
  CP END_MARK             ; the end of the list?
  JP Z,RunNpcScripts_9    ; yes: finish
  CP $00                  ; 0: a dormant slot
  JP Z,RunNpcScripts_Next ; skip it
  LD (Subject),A          ; Subject = the NPC
  CALL GetSingleLocation  ; A = its location, IX = its record
  LD (ActorRecord),IX     ; ActorRecord
  LD (ActorLocation),A    ; ActorLocation (also $FF if it has several)
  SUB A                   ; MessagesVisible = 0
  LD (MessagesVisible),A
  LD A,(IY+$00)           ; the NPC id again
  PUSH IY                 ; keep the NPC state
  LD IY,Chr00Player       ; IY = the player's record
  CALL CanReachSwapped    ; can the player reach the NPC?
  POP IY
  JR Z,RunNpcScripts_1    ; no: nothing is seen
  LD A,(SightState)       ; SightState
  CP SIGHT_NOISE_HEARD    ; the noise was heard: nothing is seen
  JR Z,RunNpcScripts_1
  LD A,$01                ; the player sees what the NPC does
  LD (MessagesVisible),A  ; MessagesVisible = 1
  LD A,(SightState)       ; SightState
  CP SIGHT_DARK           ; lit: that is all
  JR NZ,RunNpcScripts_1
  INC A                   ; dark: SightState = 2 (SIGHT_NOISE_HEARD)
  LD (SightState),A
  LD HL,MsgHearNoise      ; "You hear a noise."
  CALL PrintMessage
  SUB A                   ; MessagesVisible = 0 again
  LD (MessagesVisible),A
RunNpcScripts_1:
  LD A,$FF
  CP (IX+$01)             ; is the NPC held by something?
  JP NZ,NpcHeld           ; yes: NpcHeld decides
; This entry point is used by the routine at NpcHeld.
RunNpcScripts_Start:
  LD IX,(ActorRecord)     ; IX = ActorRecord
  CALL FindOrderSlotKeep  ; does the NPC own a stored order? (Z = yes)
  LD A,$00
  JR NZ,RunNpcScripts_2
  INC A                   ; ActorHasOrder = 1
RunNpcScripts_2:
  LD (ActorHasOrder),A    ; ActorHasOrder
; This entry point is used by the routine at RunScriptVerb.
RunNpcScripts_Script:
  LD L,(IY+$02)           ; HL = the current script
  LD H,(IY+$03)
; This entry point is used by the routine at RunScriptVerb.
RunNpcScripts_Command:
  LD A,(NpcFailures)      ; NpcFailures: failures so far
  CP SCRIPT_MAX_FAILURES  ; six: the NPC is done for this turn
  JR Z,RunNpcScripts_Next
  LD A,(HL)               ; the command byte
  LD DE,$0004             ; DE = length of op 0-3 commands
  PUSH HL
  POP IX                  ; IX = the command
  AND SCRIPT_OP_MASK      ; the op
  CP SCRIPT_OPS_COMMANDS  ; 5 and over: control ops
  JR NC,RunNpcScripts_4
  LD A,(ActorHasOrder)    ; ActorHasOrder
  CP $01                  ; no stored order: the script command
  JR NZ,RunNpcScripts_3
  BIT SCRIPT_BIT_NO_ORDER,(HL) ; this command is not to be interrupted
  JR NZ,RunNpcScripts_3
  SUB A                   ; the order is looked at once per turn
  LD (ActorHasOrder),A
  INC A                   ; A = 1: parse and test the order
  CALL RunStoredOrder     ; RunStoredOrder
  JR Z,RunNpcScripts_3    ; no usable order: the script command
  LD A,$01
  LD (ActionPerform),A    ; ActionPerform = 1
  LD (ActionAllowed),A    ; ActionAllowed = 1
  LD HL,RunNpcScripts_Next ; after the order: the next NPC
  PUSH HL                 ; (return address of the jump)
  PUSH IX                 ; (IX is popped by RunActorCommand)
  JP RunActorCommand_Run  ; do the order at once, the test is done
RunNpcScripts_3:
  LD A,(HL)
  AND $0F
  CP SCRIPT_OP_VERB       ; op 4: a verb alone
  JP Z,RunScriptVerb
  JR C,RunScriptCommand   ; op 0-3: RunScriptCommand
  JR RunNpcScripts_Next
RunNpcScripts_4:
  CP SCRIPT_OP_JUMP       ; E: jump
  JR NZ,RunNpcScripts_5
  LD E,(IX+$01)           ; the script address of the command
  LD (IY+$02),E           ; is the current script
  LD E,(IX+$02)
  LD (IY+$03),E
  JR RunNpcScripts_Script ; go on there
RunNpcScripts_5:
  CP SCRIPT_OP_SWITCH     ; C: switch behaviour
  JR NZ,RunNpcScripts_6
  LD B,(IX+$01)           ; B = the behaviour id
  LD A,(IY+$00)           ; A = the NPC id
  CALL SwitchNpcScript    ; SwitchNpcScript
  JR RunNpcScripts_Script ; go on with the new script
RunNpcScripts_6:
  CP SCRIPT_OP_RANDOM     ; F: random script
  JR NZ,RunNpcScripts_7
  CALL ChooseRandomScript ; ChooseRandomScript
  JR RunNpcScripts_Script ; go on with it
RunNpcScripts_7:
  CP $00                  ; never 0 here (the op is 5 or more): always jumps
  JR NZ,RunNpcScripts_8
  ADD HL,DE
  JR RunNpcScripts_Command
RunNpcScripts_8:
  SUB A                   ; 5-9, B, D: end of the script
  LD E,A                  ; entry 0 of the behaviour table
  CALL SelectScript       ; SelectScript: the default script
; This entry point is used by the routines at RunScriptCommand, RunScriptVerb
; and NpcHeld.
RunNpcScripts_Next:
  LD DE,NPC_RECORD_SIZE   ; the next NPC
  ADD IY,DE
  JP RunNpcScripts_0
RunNpcScripts_9:
  SUB A                   ; Subject = the player
  LD (Subject),A
  INC A
  LD (MessagesVisible),A  ; MessagesVisible = 1
  LD HL,Chr00Player       ; ActorRecord = the player's record
  LD (ActorRecord),HL
  RET

; Step the NPC script pointer past the command just read
;
; Adds the command length to the script address and, when the command byte has
; bit 4 set (it carries an extra word, the alternative target), two more bytes.
; The result becomes the NPC's current script (IY+2, IY+3). Used by the script
; interpreter's handlers for commands that run an order (RunScriptCommand) and
; for verb-only commands (RunScriptVerb).
;
; HL Address of the command (the current script) DE Length of the command
; without the extra word: 4 (verb, noun1, noun2) or 2 (verb) IX Address of the
; command (the same as HL) IY NPC record O:HL Address of the next command
AdvanceScript:
  ADD HL,DE
  BIT 4,(IX+$00)          ; extra word follows?
  JR Z,AdvanceScript_Store
  INC HL
  INC HL
AdvanceScript_Store:
  LD (IY+$02),L           ; IY+2: current script
  LD (IY+$03),H
  RET

; Run an NPC script command of op 0-3 (a command with objects, or a routine)
;
; Called by the script interpreter (RunNpcScripts) for the ops below
; SCRIPT_OP_VERB. Bit 0 of the command byte tells the two forms apart (the
; language is described at RunNpcScripts). The script pointer (IY+2, IY+3) is
; first moved past the command (AdvanceScript, length 4).
;
; Bit 0 clear (ops 0 and 2): CommandId, FirstObject and SecondObject are taken
; from bytes +1 to +3 and the command is tried through RunActorCommand (test
; pass, then done). A refusal is a failure (ScriptCommandFailed).
;
; Bit 0 set (ops 1 and 3): bytes +1 and +2 are the address of a routine, +3 is
; not used. The routine is called like a verb handler in two passes: with
; ActionPerform and ActionAllowed 0 (the test: the routine must set
; ActionAllowed to 1 to agree) and, if it agreed, again with ActionPerform = 1
; (it does its work). A routine that leaves ActionAllowed other than 1 in the
; test is a failure (ScriptCommandFailed).
;
; After a success the NPC is done for this turn. If bit 5 of the command byte
; is set (SCRIPT_BIT_ERASE) the command byte is first set to 0 in the script
; itself (a one-shot command). The other bytes stay, so a script that reaches
; the command again finds op 0 with the old bytes +1 to +3 as verb and objects;
; the only command with this bit in the data is Thorin's routine at $C8FB and
; it has not been seen to be reached again with the inputs in re/maps.
;
; IX Address of the command (as HL) IY The NPC record
RunScriptCommand:
  CALL AdvanceScript      ; move the script pointer on
  BIT SCRIPT_BIT_ROUTINE,(IX+$00) ; a routine?
  JR NZ,RunScriptCommand_0 ; yes
  LD A,(IX+$01)           ; the verb
  LD (CommandId),A        ; CommandId
  LD A,(IX+$02)           ; the first object
  LD (FirstObject),A      ; FirstObject
  LD A,(IX+$03)           ; the second object
  LD (SecondObject),A     ; SecondObject
  CALL RunActorCommand    ; try it: Z = refused
  JR Z,ScriptCommandFailed ; failed
  JR RunScriptCommand_1   ; done
RunScriptCommand_0:
  LD L,(IX+$01)           ; the routine
  LD H,(IX+$02)
  SUB A                   ; the test pass:
  LD (ActionPerform),A    ; ActionPerform = 0
  LD (ActionAllowed),A    ; ActionAllowed = 0
  CALL CallHandler        ; call it unless it is 0
  LD A,(ActionAllowed)    ; it agreed?
  CP $01
  JR NZ,ScriptCommandFailed ; no: failed
  LD (ActionPerform),A    ; ActionPerform = 1
  CALL CallHandler        ; do it
RunScriptCommand_1:
  BIT SCRIPT_BIT_ERASE,(IX+$00) ; erase after use?
  JP Z,RunNpcScripts_Next ; no: next NPC
  LD (IX+$00),$00
  JR RunNpcScripts_Next   ; next NPC

; Run an NPC script command of type 4 (a verb alone)
;
; Called by the script interpreter (RunNpcScripts, dispatching on the low
; nibble of the command byte) for op 4: command byte, verb id, and, when bit 4
; of the command byte is set, a word giving the alternative script address. The
; script pointer (IY+2, IY+3) is first moved past the command (AdvanceScript,
; length 2).
;
; A verb of $FF is no action: with the alternative bit it jumps to the
; alternative address, otherwise the NPC is done for this turn. Any other verb
; becomes the command (CommandId, with no first or second object) and is tried
; through RunActorCommand. When that works the NPC is done for this turn. When
; it fails, NpcFailures counts the failure and the NPC continues at the
; alternative address if the command has one (RunNpcScripts_Command), otherwise
; with its next command (RunNpcScripts_Script).
;
; IX Address of the command (as HL) IY The NPC record
RunScriptVerb:
  LD DE,$0002             ; length of the command
  CALL AdvanceScript      ; step the script pointer past it
  LD A,(IX+$01)           ; the verb
  CP NO_OBJECT            ; none?
  JR Z,RunScriptVerb_0
  LD (CommandId),A        ; CommandId
  LD A,NO_OBJECT
  LD (FirstObject),A      ; no first object
  LD (SecondObject),A     ; no second object
  CALL RunActorCommand    ; try it
  JR Z,ScriptCommandFailed ; failed
  JP RunNpcScripts_Next   ; done: next NPC
RunScriptVerb_0:
  BIT 4,(IX+$00)          ; an alternative address?
  JP Z,RunNpcScripts_Next ; no: next NPC
  LD L,(IX+$02)           ; jump there
  LD H,(IX+$03)
  LD (IY+$02),L
  LD (IY+$03),H
  JP RunNpcScripts_Next
; Entry point: the command failed (also used by RunScriptCommand for orders).
ScriptCommandFailed:
  LD HL,NpcFailures       ; NpcFailures counts the failures
  INC (HL)
  BIT 4,(IX+$00)
  JP Z,RunNpcScripts_Script ; no alternative: carry on with the script
  ADD IX,DE               ; the alternative address follows the command
  LD H,(IX+$01)
  LD L,(IX+$00)
  LD (IY+$02),L           ; the script continues there
  LD (IY+$03),H
  JP RunNpcScripts_Command

; Make a character carry out the command in the parser variables
;
; Used for every command an NPC runs: from its script (RunScriptCommand,
; RunScriptVerb), and for the NPC that climbs out of the thing that holds it
; (NpcHeld). The command is CommandId, FirstObject and SecondObject, the actor
; is Subject. First the test pass (TestActorCommand, which runs DispatchCommand
; with ActionPerform = 0); when the command is refused nothing happens and Z
; comes back. Otherwise the command is announced to the player and then really
; done (DispatchCommand with ActionPerform = 1).
;
; The announcement is the command written as a sentence (PrintCommandSentence:
; "Gandalf opens the door."), and it is printed only when MessagesVisible is 1
; (the actor is with the player and the player can see; set by RunNpcScripts).
; When the actor is not with the player but the first object is one with
; several places (a door, a river) and the player stands at one of them, the
; sentence is printed with nobody (NO_ACTOR) as the subject, so that it reads
; "Someone opens the door.". Going through something (CMD_GO_THROUGH) is
; announced only when the actor is in the player's location. After the command
; the actor "enters" and the first object "appears" when they have come to the
; player's location (AnnounceArrival).
;
; The second entry point runs the command at once without the test pass, for an
; order that RunStoredOrder has already tested; the caller has pushed the
; registers it wants back (RunNpcScripts pushes RunNpcScripts_Next and IX).
;
; Subject Who acts (not the player) CommandId The verb id FirstObject First
; object id or $FF Noun1Kind 1: the first noun is a place, the command is just
; run O:F Z the command was refused in the test pass, NZ it was done IX is
; preserved.
RunActorCommand:
  PUSH IX                 ; IX is restored at the end
  CALL TestActorCommand   ; test pass
  JP Z,RunActorCommand_Exit ; refused: Z
; This entry point is used by the routine at RunNpcScripts.
RunActorCommand_Run:
  LD A,(Noun1Kind)        ; Noun1Kind
  CP $01                  ; a place: run it quietly
  JR Z,RunActorCommand_Do
  LD A,(CommandId)        ; CommandId
  CP CMD_GO_THROUGH       ; going through something?
  JR NZ,RunActorCommand_0
  LD A,(ActorLocation)    ; ActorLocation
  LD HL,Chr00PlayerLocation ; the player's location byte
  CP (HL)                 ; is the actor with the player?
  JR NZ,RunActorCommand_Do ; no: run it quietly
RunActorCommand_0:
  LD A,(FirstObject)      ; FirstObject
  CP NO_OBJECT            ; none: announce as usual
  JR Z,RunActorCommand_Say
  CALL GetSingleLocation  ; A = its location, $FF if it has several; IX = its
                          ; record
  LD (FirstObjectPlace),A ; remember it for "appears" (FirstObjectPlace)
  CP NO_OBJECT            ; in one place only: announce as usual
  JR NZ,RunActorCommand_Say
  LD BC,(PlayerLocation)  ; C = PlayerLocation, B = ActorLocation
  LD A,C                  ; the player's location
  CP B
  JR Z,RunActorCommand_Say ; the actor is with the player: announce as usual
  LD B,(IX+$00)           ; B = number of places of the object
RunActorCommand_Places:
  CP (IX+$10)             ; is one of them the player's?
  JR Z,RunActorCommand_1  ; yes
  INC IX
  DJNZ RunActorCommand_Places
  JR RunActorCommand_Say  ; no: announce as usual
RunActorCommand_1:
  LD A,(Subject)          ; keep Subject
  LD B,A
  LD A,NO_ACTOR           ; nobody: "Someone"
  LD (Subject),A
  LD A,$01                ; the player sees it
  LD (MessagesVisible),A  ; MessagesVisible = 1
  PUSH IY
  CALL PrintCommandSentence ; print the command as a sentence
  POP IY
  SUB A
  LD (MessagesVisible),A  ; MessagesVisible = 0
  LD A,B
  LD (Subject),A          ; Subject back
  JR RunActorCommand_Do   ; run the command
RunActorCommand_Say:
  PUSH IY
  CALL PrintCommandSentence ; print the command as a sentence (if visible)
  POP IY
RunActorCommand_Do:
  CALL DispatchCommand    ; the real pass
  LD A,(Subject)          ; the actor
  LD HL,ActorLocation     ; where it was
  LD DE,MsgEnters         ; "<name> enters."
  CALL AnnounceArrival
  LD A,(Noun1Kind)        ; Noun1Kind
  CP $01
  JR Z,RunActorCommand_2
  LD A,(FirstObject)      ; the first object
  LD HL,FirstObjectPlace  ; where it was (FirstObjectPlace)
  LD DE,MsgAppears        ; "<name> appears."
  CALL AnnounceArrival
RunActorCommand_2:
  OR $01                  ; NZ: done
RunActorCommand_Exit:
  POP IX
  RET

; Choose a random script from the NPC's behaviour table
;
; For script op $F ("random entry 0..arg"): takes the smaller of the argument
; (command byte +1) and the NPC's highest random index (IY+1), draws a random
; number up to it with RandomUpTo (absolute value) and falls into the
; selection. The second entry point takes the entry number directly.
;
; IX Address of the script command (its +1 is the highest entry to draw) IY NPC
; record (+1 highest index, +4 behaviour table)
ChooseRandomScript:
  LD A,(IX+$01)
  CP (IY+$01)             ; smaller of the two limits
  JR C,ChooseRandomScript_0
  LD A,(IY+$01)
ChooseRandomScript_0:
  CALL RandomUpTo         ; random 0..A
  LD E,A
; This entry point is used by the routine at RunNpcScripts.
SelectScript:
  LD A,(IY+$01)
  CP E
  JR NC,ChooseRandomScript_1 ; E = min(E, highest index)
  LD E,A
ChooseRandomScript_1:
  LD L,(IY+$04)           ; HL: behaviour table
  LD H,(IY+$05)
  LD D,$00
  ADD HL,DE
  ADD HL,DE
  ADD HL,DE
  INC HL                  ; entry = 3 bytes (id, script word); skip the id
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD (IY+$02),E           ; IY+2: current script
  LD (IY+$03),D
  RET

; Find an NPC record by id
;
; Searches the 17 NPC records (NpcStates, 7 bytes each) for the id in A. The
; search stops at the id or at the $FF that ends the table.
;
; A Character id O:A The id found, or END_MARK when the character has no record
; O:HL Address of the record (or of the end mark) O:IY Address of the record
; (or of the end mark)
FindNpcState:
  PUSH DE
  PUSH BC
  LD B,A
  LD HL,NpcStates
  LD DE,NPC_RECORD_SIZE
FindNpcState_Loop:
  LD A,(HL)
  CP B
  JR Z,FindNpcState_0
  CP END_MARK
  JR Z,FindNpcState_0
  ADD HL,DE
  JP FindNpcState_Loop
FindNpcState_0:
  POP BC
  POP DE
  PUSH HL
  POP IY
  RET

; Switch an NPC to the script for an event
;
; Looks up the NPC's record (FindNpcState), then the entry for the behaviour id
; in B in the NPC's behaviour table (+4: id, script address; see NpcStates) and
; makes that script the NPC's current script (+2). Nothing changes when the NPC
; has no record or its table has no entry for the id. Used by script op $C
; (switch behaviour) in RunNpcScripts and by NotifyCharacter when a character
; is told of an event.
;
; A Character id B Behaviour id (0 default, $0F idle, others for events)
SwitchNpcScript:
  PUSH IY
  PUSH IX
  CALL FindNpcState       ; IY = NPC record
  CP END_MARK
  JR Z,SwitchNpcScript_0  ; no such NPC
  LD L,(IY+$04)
  LD H,(IY+$05)
  PUSH HL
  POP IX                  ; IX = behaviour table
  LD A,B
  CALL FindIdRecord       ; find the entry for the id
  CP END_MARK
  JR Z,SwitchNpcScript_0  ; not in the table
  LD L,(IX+$01)
  LD H,(IX+$02)
  LD (IY+$02),L           ; current script := the entry's script
  LD (IY+$03),H
SwitchNpcScript_0:
  POP IX
  POP IY
  RET

; Announce that a character or object has arrived where the player is
;
; Called after a command or an NPC turn with the actor, or the first object, in
; A, the address of the byte that holds its location from before the action in
; HL and the message in DE. Prints the message ("<name> enters." for the actor,
; "<name> appears." for the object) only when it is now at the player's
; location and was not there before. It prints nothing when A is $FF or 0 (the
; player), when SightState is 2 (the dark noise was already given), when the
; location has not changed, when the player is somewhere else, or when MoveFlag
; is 0 (the last MoveCarried move carried the player along).
;
; The name is passed to the message as the name phrase of the record (+8) on
; the stack.
;
; A Id of the actor or object ($FF none, 0 player) HL Address of a byte holding
; its location before the action DE Message to print
AnnounceArrival:
  CP END_MARK
  RET Z
  AND A
  RET Z                   ; the player never arrives
  LD B,A
  LD A,(SightState)       ; SightState: 2 = "You hear a noise." already given
  CP $02
  RET Z
  LD A,B
  CALL GetSingleLocation  ; A = its location now
  LD C,A
  CP (HL)
  RET Z                   ; not moved
  LD A,(PlayerLocation)
  CP C
  RET NZ                  ; not where the player is
  LD A,(MoveFlag)
  AND A
  RET Z                   ; MoveFlag 0: the player moved with it
  LD A,$01
  LD (MessagesVisible),A  ; messages visible
  PUSH DE
  POP HL                  ; HL = the message
  LD A,B
  CALL FindObject         ; IX = its record
  PUSH DE
  LD DE,$0008
  ADD IX,DE
  POP DE
  PUSH IX                 ; the name phrase, for the message
  CALL PrintMessage       ; "<name> enters." / "<name> appears."
  RET

; Update where the player is and whether the player can see
;
; Stores the player's location in PlayerLocation and sets SightState
; (SightState) to 0 when the player can see (CheckDark returns carry clear) or
; to 1 when it is too dark. RunNpcScripts uses SightState for the "You hear a
; noise." rule: it goes to 2 once that message has been printed in a turn.
; Called at the start of every turn and after the player has been carried to a
; new place (MoveCarried).
;
; Uses the actor in Subject ($B6EA) through CheckDark, which returns at once
;      for
; any actor but the player.
UpdatePlayerSight:
  LD A,PLAYER
  CALL GetSingleLocation  ; the player's location
  LD (PlayerLocation),A   ; PlayerLocation
  CALL CheckDark          ; carry set: too dark to see
  LD A,$00
  JR NC,UpdatePlayerSight_0
  INC A                   ; 1 when dark
UpdatePlayerSight_0:
  LD (SightState),A       ; SightState
  RET
