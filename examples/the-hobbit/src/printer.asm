; "WAIT" text and the message control code table
;
; "WAIT": typed by $7249 when no key is pressed for a long time. From $7295: 23
; words, handler of control code 0-22 in a message (read by $7326; codes below
; $14 are called, the rest jumped to).
WaitText:
  DEFM "WAIT"
ControlCodeTable:
  DEFW PrintStackedName
  DEFW PrintStackedWord
  DEFW MessageJump
  DEFW L738D
  DEFW PrintStackedWordArticle
  DEFW MessageJump_1
  DEFW PrintSubjectName
  DEFW PrintFirstObjectName
  DEFW L73BD
  DEFW PrintSecondObjectName
  DEFW MessageJump_1
  DEFW MessageCall
  DEFW L73F9
  DEFW PrintMessageChar
  DEFW HisYourFirstObject
  DEFW MessageJump_1
  DEFW PrintSubjectIs
  DEFW L7425
  DEFW MessageJump_1
  DEFW PrintNameIsFromStack
  DEFW EndNewLine
  DEFW EndFullStop
  DEFW PrintEndingWord_1

; Print a message character
;
; Prints character A with PrintChar. A carriage return also clears the output
; column byte ($B704), so the next word starts a fresh line. The printer calls
; it for every literal character ($20-$5F) of a message, and it is the handler
; of control code 13 (line break).
;
;   A Character
; O:F Z for a carriage return (nothing more to print), NZ otherwise
PrintMessageChar:
  CALL PrintChar
  CP CHAR_CR
  RET NZ
  XOR A
  LD (CapitalNext),A      ; CapitalNext: at line start
  RET

; Print "I cannot do that."
;
; Prints the message at $AFBF with PrintMessage: the reply when an action
; cannot be done.
;
; O:A, DE, HL As PrintMessage
PrintCannotDoThat:
  LD HL,MsgICannotDoThat  ; "I cannot do that."
  JR PrintMessage

; Print a message
;
; The message interpreter. PrintMessage ($72DD) prints the message at HL in the
; story window, or in the input window when RawOutputFlag ($B701) is not 0. The
; parser calls PrintParserMessage instead, which first clears ActionPerform
; ($B6FA) when the words are an order being parsed (InputFromOrder, $B71B, not
; 0), so that the message counts as a refusal.
;
; A message is a list of items, read from IX, up to an ending item (the formats
; are in the notes, "Messages"):
;
; - bit 7 set: a two-byte word item. D = first byte & $7F, E = second; the high
; nibble of D is the print mode. The modes WORD_END_PLAIN, WORD_END_STOP and
; WORD_END_NEWLINE print the word and end the message (PrintEndingWord); the
; other modes print the word with PrintWord and go on. - $20-$5F: a literal
; character (PrintMessageChar). - $60-$7F: a common word (PrintCommonWord). -
; $00-$1F: a control code. Its handler is ControlCodeTable[code]. Codes below
; CODE_FIRST_END are called: the handler returns Z when it has printed what it
; wanted, or NZ with a word token in DE, which is printed here. The codes from
; CODE_FIRST_END on end the message and are jumped to.
;
; When ActionPerform is 0 (a test pass of a command, see DispatchCommand)
; printing a message sets ActionAllowed ($B6FB) to 0, so a message printed by a
; check refuses the command. The message is printed in both cases.
;
; A, DE and IX of the caller are saved in SavedA, SavedDE and SavedIX
; ($70DC-$70E0) and restored by the ending (PrintEndingWord). Words that codes
; 0, 1, 4 and 19 ask for are on the stack, below the return address. HL is not
; kept.
;
; Hardware: none directly; the characters go to the screen through PrintChar.
;
; HL Address of the message
; A Saved and returned unchanged
; DE Saved and returned unchanged
; IX Saved and returned unchanged
PrintParserMessage:
  LD A,(InputFromOrder)   ; InputFromOrder
  AND A
  JR Z,PrintMessage
  XOR A                   ; an order is being parsed: the message is a refusal
  LD (ActionPerform),A    ; ActionPerform = 0
; This entry point is used by the routines at GameStart, PrintCannotDoThat,
; RejectLine, WordHelp, PrintScore, LoadBlock, SaveGame, VerifyBlock, VerbLook,
; RequireHeld, VerbDrop, CheckCanCarry, VerbTake, VerbMove, VerbLookThrough,
; VerbFollow, TalkToCharacter, EndGame, VerbInventory, VerbAttack, PutObjectIn,
; GiveObject, ExamineObject, DispatchCommand, ShowLocation, PrintLocationText,
; CheckHeldByOther, PrintMessageDot, RunNpcScripts, AnnounceArrival,
; EmptyFirstObject, ListObjectsHere, ListObjects, PrintContentsHeader,
; PrintHolderRelation, ListExitObstacles, ListVisibleExits, PrintStateIX,
; PrintSpeech, PrintNoFit, RespawnKilledGoblin, ThorinDeathBreaksKey and
; CheckVictory.
PrintMessage:
  LD (SavedDE),DE         ; SavedDE
  LD (SavedIX),IX         ; SavedIX
  LD (SavedA),A           ; SavedA
  LD A,(ActionPerform)    ; ActionPerform
  AND A
  JR NZ,PrintMessageAt    ; 1: really doing it
  LD (ActionAllowed),A    ; test pass: ActionAllowed = 0 (A is 0)
; This entry point is used by the routine at MessageCall.
PrintMessageAt:
  PUSH HL
  POP IX                  ; IX = the message
PrintMessage_Item:
  LD A,(IX+$00)           ; next item
  BIT 7,A                 ; a word?
  JR Z,PrintParserMessage_0
  AND $7F
  LD D,A                  ; D = print mode and offset bits 8-11
  LD E,(IX+$01)           ; E = offset bits 0-7
  INC IX
  AND $F0                 ; the print mode
  CP WORD_END_STOP
  JR Z,PrintEndingWord    ; print the word and end the message
  CP WORD_END_PLAIN
  JR Z,PrintEndingWord
  CP WORD_END_NEWLINE
  JR Z,PrintEndingWord
; This entry point is used by the routine at PrintCommonWord.
PrintMessage_Word:
  CALL PrintWord          ; print the word (DE)
PrintMessage_Next:
  INC IX
  JR PrintMessage_Item
PrintParserMessage_0:
  CP CHAR_SPACE           ; below $20: a control code
  JR C,PrintParserMessage_1
  CP ITEM_COMMON_WORD     ; $60 and up: a common word
  JP NC,PrintCommonWord
  CALL PrintMessageChar   ; a literal character
  JR PrintMessage_Next
PrintParserMessage_1:
  PUSH DE
  LD E,A
  LD D,$00
  LD HL,ControlCodeTable  ; ControlCodeTable
  ADD HL,DE
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL                ; HL = the handler
  POP DE
  CP CODE_FIRST_END
  JR NC,PrintParserMessage_2 ; an ending: jump to it
  CALL PrintParserMessage_2 ; any other code: call the handler
  JR Z,PrintMessage_Next  ; it printed what it wanted: next item
  JR PrintMessage_Word    ; NZ: print the word token in DE
PrintParserMessage_2:
  JP (HL)

; Control code $14: end the message with a new line
;
; Sets D to $60 (print mode 6 of a word token: end the message with a new line)
; and goes to the ending in PrintEndingWord.
;
;          Reached with a jump, so the return goes to the caller of the message
;                  printer.
; Hardware: prints through PrintNewLine (story window).
EndNewLine:
  LD D,$60
  JR EndMessage

; Control code $15: end the message with a full stop and a new line
;
; Sets D to $30 (print mode 3 of a word token) and goes to the ending in
; PrintEndingWord: prints ".", a new line, restores the registers and returns
; to the caller of the message printer.
;
;          Reached with a jump.
; Hardware: prints through PrintChar and PrintNewLine (story window).
EndFullStop:
  LD D,$30
  JR EndMessage

; End a message with a closing word (print modes 2, 3 and 6)
;
; Reached with the first two bytes of a word item in DE (D = print mode and
; offset bits 8-11). Prints the word with PrintWord, then ends the message as
; the mode says: WORD_END_PLAIN nothing more, WORD_END_STOP a full stop and a
; new line, WORD_END_NEWLINE a new line only. The control codes $14 and $15
; enter at EndMessage with D set to the mode and no word. Then restores A, DE
; and IX of the caller of the message printer (PrintMessage) and returns to it.
;
; Hardware: prints through PrintChar and PrintNewLine (story window or input
; window).
;
;   D Print mode (bit 6: new line only; bit 4: full stop and new line)
;   E Offset bits 0-7 of the word
; O:A Saved A of the message printer
; O:DE Saved DE of the message printer
; O:IX Saved IX of the message printer
PrintEndingWord:
  CALL PrintWord          ; print the word
; This entry point is used by the routines at EndNewLine and EndFullStop.
EndMessage:
  LD A,$2E                ; "."
  BIT 6,D                 ; mode 6: new line only
  JR NZ,PrintEndingWord_0
  BIT 4,D                 ; mode 3: full stop...
  CALL NZ,PrintChar
  BIT 4,D
PrintEndingWord_0:
  CALL NZ,PrintNewLine    ; ...and a new line (PrintNewLine)
PrintEndingWord_1:
  LD DE,(SavedDE)         ; SavedDE
  LD IX,(SavedIX)         ; SavedIX
  LD A,(SavedA)           ; SavedA
  RET

; Control code 0: print a name phrase passed on the stack
;
; The caller of the message printer pushed the address of a name phrase (as
; returned by ObjectNamePtr, 0 for none) below its return address. This takes
; it off the stack, closing the gap, clears the article flag ($B703) and, if it
; is not 0, prints the name with PrintPhraseAtHL.
;
; The printer calls this handler with IX at the code byte. Return Z when there
; is nothing to print; NZ with a word token in DE and the printer prints it.
;
; O:A 0 (nothing more to print)
; O:F Z
PrintStackedName:
  XOR A
  LD (PhraseMode),A       ; PhraseMode: no article
  POP DE
  POP HL
  EX (SP),HL
  PUSH DE
  LD A,H
  OR L
  CALL NZ,PrintPhraseAtHL
  XOR A
  RET

; Control code 1: print a word token passed on the stack
;
; Takes the word token the caller of the message printer pushed below its
; return address (closing the gap) and returns it in DE.
;
; The printer calls this handler with IX at the code byte. Return Z when there
; is nothing to print; NZ with a word token in DE and the printer prints it.
;
; O:DE Word token
; O:F NZ
PrintStackedWord:
  POP DE
  POP HL
  EX (SP),HL
  PUSH DE
  EX DE,HL
  OR $01
  RET

; Control code 2: jump inside the message data
;
; The byte after the code is a signed displacement. IX moves by it from the
; code byte; the printer's next step passes the displacement byte, so the
; message goes on at (address of the displacement byte) + displacement. Many
; messages end by jumping into the middle of another.
;
; The printer calls this handler with IX at the code byte. Return Z when there
; is nothing to print; NZ with a word token in DE and the printer prints it.
;
;   IX Address of the code byte
; O:IX Address one before where the message continues
; O:F Z
MessageJump:
  LD E,(IX+$01)
  LD D,$00                ; signed displacement
  BIT 7,E
  JR Z,MessageJump_0
  LD D,$FF
MessageJump_0:
  ADD IX,DE
MessageJump_1:
  XOR A                   ; nothing to print
  RET

; Control code 3 handler: DE=($B6FC), return NZ (jump table $7295, never run)
L738D:
  LD DE,(TargetNamePtr)
  OR $01
  RET

; Control code 4: print a word token from the stack with an article
;
; Takes the word token the caller pushed below its return address, sets the
; article flag ($B703) and prints it with PrintNounWord, which puts "the", "a"
; or "an" first.
;
; The printer calls this handler with IX at the code byte. Return Z when there
; is nothing to print; NZ with a word token in DE and the printer prints it.
;
; O:A 0
; O:F Z
PrintStackedWordArticle:
  POP DE
  POP HL
  EX (SP),HL
  PUSH DE
  EX DE,HL
  LD A,$01
  LD (PhraseMode),A       ; PhraseMode: with article
  CALL PrintNounWord
  XOR A
  RET

; Control code 6: print the name of the subject
;
; Prints the name of the actor in $B6EA ("you" for the player, "someone" when
; $FF) without an article. The second entry leaves the article flag as the
; caller set it (used by PrintCommandSentence).
;
; The printer calls this handler with IX at the code byte. Return Z when there
; is nothing to print; NZ with a word token in DE and the printer prints it.
;
; O:A 0
; O:F Z
PrintSubjectName:
  XOR A
  LD (PhraseMode),A       ; PhraseMode: no article
; This entry point is used by the routine at PrintCommandSentence.
PrintSubjectNameAsIs:
  LD A,(Subject)          ; Subject
  CALL PrintActorName
  XOR A
  RET

; Control code 7: print the name of the first object with an article
;
; Sets the article flag ($B703) and prints the name of the first object of the
; command ($B6E8). If $B6FE (first noun is a location) is set it is a location
; id and its name is found with LocationNamePtr, otherwise an object with
; ObjectNamePtr; the name is printed by PrintPhraseAtHL. The second entry
; leaves the article flag as the caller set it (used by PrintCommandSentence).
; Shares the lookup in PrintSecondObjectName.
;
; The printer calls this handler with IX at the code byte. Return Z when there
; is nothing to print; NZ with a word token in DE and the printer prints it.
;
; O:A 0
; O:F Z
PrintFirstObjectName:
  LD A,$01
  LD (PhraseMode),A       ; PhraseMode: with article
; This entry point is used by the routine at PrintCommandSentence.
PrintFirstObjectNameAsIs:
  LD A,(Noun1Kind)        ; Noun1Kind
  AND A
  LD A,(FirstObject)      ; FirstObject
  JR PrintSecondObjectName_0

; Control code 8 handler: print character A, return Z (jump table $7295, never
; run)
L73BD:
  CALL PrintChar
  XOR A
  RET

; Control code 9: print the name of the second object with an article
;
; Sets the article flag (PhraseMode, $B703) and prints the name of the second
; object of the command ($B6E9): a location id when Noun2Kind ($B6FF) is not 0
; (name from LocationNamePtr), otherwise an object (ObjectNamePtr), printed
; with PrintPhraseAtHL. The second entry leaves the article flag as the caller
; set it (used by PrintCommandSentence). The code 7 handler
; (PrintFirstObjectName) joins at PrintSecondObjectName_0 with its own noun. HL
; is kept.
;
; The printer calls this handler with IX at the code byte. Return Z when there
; is nothing to print; NZ with a word token in DE and the printer prints it.
;
;   A Id of the object or location to name (PrintNameOfObject only)
; O:A 0
; O:F Z
PrintSecondObjectName:
  LD A,$01
  LD (PhraseMode),A       ; PhraseMode: with article
; This entry point is used by the routine at PrintCommandSentence.
PrintSecondObjectNameAsIs:
  LD A,(Noun2Kind)        ; Noun2Kind
  AND A
  LD A,(SecondObject)     ; SecondObject
; This entry point is used by the routine at PrintFirstObjectName.
PrintSecondObjectName_0:
  JR Z,PrintNameOfObject  ; an object
  PUSH HL
  CALL LocationNamePtr    ; name phrase of the location
  JR PrintSecondObjectName_1
; This entry point is used by the routine at PrintActorName.
PrintNameOfObject:
  PUSH HL
  CALL ObjectNamePtr      ; name phrase of the object or character A
PrintSecondObjectName_1:
  CALL PrintPhraseAtHL    ; print it
  POP HL
  XOR A
  RET

; Control code 11: print another message, then go on
;
; The byte after the code is a signed displacement; the message at (address of
; that byte) + displacement is printed through PrintMessageAt until its ending
; code, then this message continues after the displacement byte.
;
; The printer calls this handler with IX at the code byte. Return Z when there
; is nothing to print; NZ with a word token in DE and the printer prints it.
;
;   IX Address of the code byte
; O:IX Address of the displacement byte
; O:F Z
MessageCall:
  INC IX
  PUSH IX                 ; IX = displacement byte
  POP HL
  PUSH HL
  LD E,(IX+$00)
  LD D,$00
  BIT 7,E
  JR Z,MessageCall_0
  LD D,$FF
MessageCall_0:
  ADD HL,DE
  CALL PrintMessageAt     ; print the other message
  POP IX
  XOR A
  RET

; Control code 12 handler: word reference by ($B6EA), return DE (jump table
; $7295)
L73F9:
  LD A,(Subject)

; Choose "his" or "your" for an actor
;
; Gives the word token for "his" when the actor is not the player and "your"
; when it is. Control codes 12 (subject) and 14 (first object) get here, from
; L73F9 and HisYourFirstObject.
;
;   A Actor id (0 = the player)
; O:DE Word token: $0990 "his" or $0BEA "your"
; O:F NZ
HisOrYour:
  LD DE,$0990             ; "his"
  AND A
  RET NZ
  LD DE,$0BEA             ; "your"
  OR $01
  RET

; Control code 14: "his" or "your" for the first object
;
; Prints the word for the actor in $B6E8 (the first object of the command) with
; HisOrYour.
;
; The printer calls this handler with IX at the code byte. Return Z when there
; is nothing to print; NZ with a word token in DE and the printer prints it.
;
; O:DE Word token
; O:F NZ
HisYourFirstObject:
  LD A,(FirstObject)      ; FirstObject
  JR HisOrYour

; Control code 16: print the subject's name and "is" or "are"
;
; Prints the name of the actor in $B6EA ("you" for the player, "someone" when
; $FF; no article), then returns the word token for "are" when the actor is the
; player and "is" otherwise. The second entry takes the article flag in A and
; the actor in A' (used by PrintNameIs for codes 17 and 19).
;
; The printer calls this handler with IX at the code byte. Return Z when there
; is nothing to print; NZ with a word token in DE and the printer prints it.
;
;   A' Actor id (second entry only)
;   A Article flag $B703 (second entry only)
; O:DE Word token: $039B "is" or $0065 "are"
; O:F NZ
PrintSubjectIs:
  LD A,(Subject)          ; Subject
  EX AF,AF'
  XOR A
; This entry point is used by the routine at PrintNameIs.
PrintActorIs:
  LD (PhraseMode),A       ; PhraseMode
  EX AF,AF'
  PUSH AF
  CALL PrintActorName
  POP AF
  AND A
  LD DE,$039B             ; "is"
  RET NZ
  LD DE,$0065             ; "are"
  OR $01
  RET

; Control code 17 handler: select by ($B6E8), then as $7428 (jump table $7295,
; never run)
L7425:
  LD A,(FirstObject)

; Print a name with its article, then "is" or "are"
;
; Message control codes 17 (after L7425 loads the first object) and 19
; (PrintNameIsFromStack takes the id from the stack). Like PrintSubjectIs, but
; PhraseMode is set to 1, so the name is printed with its article
; (PrintNounWord calls PrintArticle). The id goes to A', the shared tail
; PrintActorIs prints the name and returns the word for "are" (the player) or
; "is" (anyone else).
;
; The printer calls this handler with IX at the code byte; NZ with a word code
; in DE means print that word.
;
;   A Id of the thing named (PLAYER prints "you", $FF "someone")
; O:DE Word code: "is" ($039B) or "are" ($0065)
; O:F NZ
PrintNameIs:
  EX AF,AF'               ; id of the thing to A'
  LD A,$01                ; PhraseMode 1: print with an article
  JR PrintActorIs         ; PrintActorIs stores PhraseMode, prints the name

; Print a name with its article and "is"/"are", the id from the stack
;
; Message control code 19. The caller of the message printer pushed AF (A = id
; of the thing) before it, below one more word that the printer keeps; this
; takes the AF off the stack, leaves the other word in place and continues in
; PrintNameIs.
;
;   stack Id of the thing in the A of a pushed AF, below the return address and
;         one saved word
; O:DE Word code: "is" or "are" (see PrintNameIs)
; O:F NZ
PrintNameIsFromStack:
  POP DE                  ; return address
  POP HL                  ; the word the printer keeps
  POP AF                  ; A = id
  PUSH HL                 ; put the kept word back
  PUSH DE                 ; and the return address
  JR PrintNameIs

; Print the name phrase at HL
;
; Points IY at the name phrase (three word codes: noun, then up to two
; adjectives) and has PrintNamePhrase print it, then restores IY. Used by the
; message control codes 0 and 9 for a phrase address kept in a record.
;
; HL Address of the name phrase (6 bytes, noun first)
PrintPhraseAtHL:
  PUSH IY
  PUSH HL
  POP IY
  CALL PrintNamePhrase    ; prints adjectives, then the noun
  POP IY
  RET

; Print the article of a name phrase
;
; DE is the noun code of a name phrase (D bits 4-7 are its style). A proper
; name (bit 15 set, "you" included) has no article: the routine only sets the
; capital flag (CapitalNext, $B704) so that the name starts with a capital, and
; does nothing at all for "you". For any other noun it prints "the", "a", "an"
; or "some", chosen by bits 12-13 of DE from ArticleTable; ArticleTableInput
; ("the" for the first three) is used while the input window is the output
; (B701) or while the command echo is built (PrintCommandSentence sets $70DF).
;
; The common path destroys E (it holds B701 when D is pushed), so callers
; reload or save DE (PrintNounWord does).
;
;   DE Noun code of the phrase (bit 15 proper name, bits 12-13 article)
; O:D Unchanged
; O:E Destroyed on the common path
PrintArticle:
  BIT 7,D                 ; proper name?
  JR Z,PrintArticle_1
  LD A,E                  ; low byte of "you"...
  LD HL,WORD_YOU          ; ...and the code of "you" (bit 15 stripped)
  CP L
  JR NZ,PrintArticle_0
  LD A,D
  AND $0F
  CP H
  RET Z                   ; "you": nothing at all
PrintArticle_0:
  LD A,$01                ; capital flag: the name starts with a capital
  LD (CapitalNext),A      ; CapitalNext is the capital flag (set after a new
                          ; line)
  RET
PrintArticle_1:
  LD HL,ArticleTable      ; article words: the, a, an, some
  LD A,(RawOutputFlag)    ; B701: output to the input window
  LD E,A
  LD A,(EchoingCommand)   ; $70DF: command echo being built
  OR E
  JR Z,PrintArticle_2
  LD HL,ArticleTableInput ; the, the, the, some
PrintArticle_2:
  LD A,D                  ; style bits 4-7 of D as a word index
  RRCA
  RRCA
  RRCA
  AND $1E
  PUSH DE
  LD E,A
  LD D,$00
  ADD HL,DE
  LD E,(HL)               ; article word code
  INC HL
  LD D,(HL)
PrintArticle_Word:
  CALL PrintWord          ; print it
  POP DE
  RET

; Print the noun of a name phrase with its article
;
; DE is the noun code of a name phrase (bits 12-15 style, bits 0-11 dictionary
; offset). When PhraseMode ($B703) is not 0 the article (or the capital flag of
; a proper name) comes first (PrintArticle); then the noun itself is printed
; with its style bits cleared, as a word of print mode 0 (PrintWord).
;
;   DE Noun code of the name phrase
; O:D Style bits cleared
PrintNounWord:
  PUSH DE
  LD A,(PhraseMode)       ; PhraseMode: with article?
  AND A
  CALL NZ,PrintArticle    ; PrintArticle
  POP DE
  LD A,D
  AND $0F                 ; keep the offset only
  LD D,A
  JP PrintWord            ; PrintWord

; Print the name of an actor
;
; A is an actor id as kept in Subject ($B6EA): $FF means nobody known and
; prints the word "someone"; any other id (0 is the player, who prints as
; "you") is a character or object whose name phrase is printed by
; PrintNameOfObject, with or without an article as PhraseMode ($B703) says.
; Used by the message control codes 6 and 16.
;
; A Actor id, NO_ACTOR for "someone"
PrintActorName:
  CP NO_ACTOR
  JP NZ,PrintNameOfObject ; PrintNameOfObject
  LD DE,WORD_SOMEONE      ; "someone"
  JP PrintWord            ; PrintWord

; Print a common word of a message
;
; Message item $60-$7F: the word at index item-$60 of CommonWordTable (a, and,
; are, ... you). Builds its word code in DE with print mode WORD_PLAIN (no
; ending) and jumps into the message loop at PrintMessage_Word, which prints it
; with PrintWord and goes on to the next item.
;
;   A Message item byte ($60-$7F)
;   IX Address of the item in the message (kept for the loop)
; O:DE Word code to print
PrintCommonWord:
  SUB ITEM_COMMON_WORD    ; index 0-31
  LD E,A
  LD D,$00
  LD HL,CommonWordTable
  ADD HL,DE               ; 2 bytes per entry
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD A,(HL)
  ADD A,WORD_PLAIN        ; high byte + print mode 5: no ending
  LD D,A
  JP PrintMessage_Word    ; print DE, next item

; Word text buffer (20 bytes)
;
; The letters of the word being printed by $74C1 (dictionary letters + $60,
; then up to 4 more); printed through $858B afterwards.
WordBuffer:
  DEFB $F1,$78,$36,$04,$CD,$30,$79,$36
  DEFB $36,$23,$73,$23,$70,$18,$1C,$FE
  DEFB $0B,$20,$1B,$CB

; Print a word of the dictionary
;
; PrintWordAtHL reads a two-byte word code at HL (offset low byte, then high
; byte with the print mode cleared) and advances HL. PrintWord takes the code
; in DE: bits 0-11 are the offset of the word in the dictionary at $6000
; (offset 0 prints nothing), bits 12-15 the print mode.
;
; The letters (5 bits each, +$60 to make lower-case characters) are copied to
; WordBuffer. A verb whose byte 2 has bit 7 set may then get an ending from
; WordEndings (4 bytes each, index = bits 5-7 of byte 3), depending on the
; mode: WORD_SUFFIX_OBJ1 when FirstObject ($B6E8) is not 0, WORD_SUFFIX always,
; WORD_PLAIN never, every other mode (0, 2, 3, 6, 7) when Subject ($B6EA) is
; not 0 (so a verb gets its "s" for anyone but the player).
;
; The word is then printed through PrintChar, one character at a time, to the
; story window, or to the input window when B701 is not 0. A space goes before
; it, except at the start of a line of the story window. When the word is
; longer than the columns left (the column counter at $869B or $85B3) a new
; line is started first, keeping the capital flag (CapitalNext, $B704). Mode
; WORD_CAPITAL sets that flag before the word, so its first letter is a
; capital.
;
; Hardware: none directly; the characters go to the screen through PrintChar.
;
;   DE Word code (PrintWord)
;   HL Address of a word code (PrintWordAtHL)
; O:HL Address after the code (PrintWordAtHL); otherwise unchanged
; O:DE Unchanged (PrintWord)
PrintWordAtHL:
  LD E,(HL)               ; offset, low byte
  INC HL
  LD A,(HL)               ; high byte...
  INC HL
  AND $0F                 ; ...without the print mode
  LD D,A
; This entry point is used by the routines at PrintCommandSentence,
; PrintParserMessage, PrintEndingWord, PrintArticle, PrintNounWord,
; PrintActorName, VerbLook, PrintNamePhrase, ListExitObstacles,
; ListVisibleExits and RespawnKilledGoblin.
PrintWord:
  LD A,D
  AND $0F                 ; offset 0: nothing to print
  OR E
  RET Z
  PUSH HL
  PUSH BC
  PUSH DE
  LD C,D                  ; C keeps the print mode
  LD A,D
  AND $0F
  LD D,A
  LD HL,Vocabulary        ; HL = the word in the dictionary
  ADD HL,DE
  LD DE,WordBuffer        ; DE = WordBuffer
  PUSH HL                 ; keep the start of the word
  LD B,$00                ; B counts the letters
PrintWord_Letter:
  LD A,(HL)
  AND $1F                 ; letter 1-26; 0 ends the word
  JR Z,PrintWordAtHL_0
  INC B
  ADD A,LETTER_BASE       ; to lower-case ASCII
  LD (DE),A
  INC DE
  BIT 7,(HL)              ; last byte of the word?
  INC HL
  JR Z,PrintWord_Letter
  LD A,B                  ; byte 2 (and byte 3 after a verb flag) has bit 7
                          ; without ending
  CP $02
  JR Z,PrintWord_Letter
  CP $03
  JR NZ,PrintWordAtHL_0
  DEC HL
  DEC HL
  LD A,(HL)
  INC HL
  INC HL
  BIT 7,A
  JR NZ,PrintWord_Letter
PrintWordAtHL_0:
  POP HL                  ; HL = start of the word again
  LD A,C                  ; print mode
  AND $F0
  CP WORD_PLAIN           ; never an ending
  JR Z,PrintWord_Place
  CP WORD_SUFFIX          ; always
  JR Z,PrintWord_Ending
  CP WORD_SUFFIX_OBJ1     ; if the first object is set...
  LD A,(FirstObject)      ; FirstObject
  JR Z,PrintWordAtHL_1
  LD A,(Subject)          ; ...otherwise (other modes) if Subject is set
PrintWordAtHL_1:
  AND A                   ; 0: no ending
  JR Z,PrintWord_Place
PrintWord_Ending:
  INC HL                  ; byte 2
  BIT 7,(HL)              ; bit 7: the word takes an ending
  JR Z,PrintWord_Place
  INC HL                  ; byte 3
  LD A,(HL)
  AND $E0                 ; bits 5-7 times 4 = offset in WordEndings
  RRCA
  RRCA
  RRCA
  LD L,A
  LD H,$00
  LD BC,WordEndings
  ADD HL,BC
  LD B,WORD_ENDING_SIZE
PrintWordAtHL_2:
  LD A,(HL)               ; copy the ending up to its 0 byte
  AND A
  JR Z,PrintWord_Place
  INC HL
  LD (DE),A
  INC DE
  DJNZ PrintWordAtHL_2
PrintWord_Place:
  LD HL,WordBuffer        ; HL = WordBuffer, DE = end of the text
  EX DE,HL
  AND A
  SBC HL,DE
  LD B,L                  ; B = length with the ending
  LD A,(RawOutputFlag)    ; B701: input window?
  AND A
  PUSH AF
  JR NZ,PrintWordAtHL_3
  LD A,(StoryLastChar)    ; story window: is the line empty?
  AND A
PrintWordAtHL_3:
  LD A,CHAR_SPACE         ; a space before the word...
  CALL NZ,PrintChar       ; ...except at the start of a story line
  POP AF
  LD A,(InputColumn)      ; columns left in the line (input or story window)
  JR NZ,PrintWordAtHL_4
  LD A,(StoryColumn)
PrintWordAtHL_4:
  LD HL,CapitalNext       ; capital flag
  CP B                    ; does the word fit?
  JR NC,PrintWordAtHL_5
  LD A,(HL)               ; no: keep the capital flag over the new line
  CALL PrintNewLine       ; new line
  LD (HL),A
PrintWordAtHL_5:
  POP DE                  ; the word code
  LD A,D
  AND $F0
  CP WORD_CAPITAL         ; mode 7: first letter capital
  LD A,$01
  JR NZ,PrintWord_Print
  LD (HL),A
PrintWord_Print:
  LD HL,WordBuffer        ; print the letters
PrintWordAtHL_6:
  LD A,(HL)
  CALL PrintChar
  INC HL
  DJNZ PrintWordAtHL_6
  POP BC
  POP HL
  RET

; Workspace of the action dispatcher ($770B, $772F, $7585)
;
; $7574 saved HL, $7576 saved A, $7577 saved IY, $7579 saved A; $757A flag;
; $757B ten bytes cleared at $75B4 (read by $7795, $781C, $7809).
SavedHL:
  DEFW $0000
SavedA1:
  DEFB $00
SavedIY:
  DEFW $0000
SavedA2:
  DEFB $00
ActionFlag:
  DEFB $00
ActionSlots:
  DEFS $0A
