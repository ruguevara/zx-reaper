; Parse the typed word list into phrase records
;
; The sentence parser. The word list built by GameStart at $709C (WordListPtr
; points at it) is read word by word with ReadWord; the class of each word
; picks a handler from ActionTable ($75D2), which stores the word in the phrase
; being built: ActionSlots ($757B: two prepositions, noun, two adjectives) are
; copied into one of the two phrase blocks of the record at IY
; (StorePhraseBlock), command words go to the record's first words
; (StoreFirstWord). Records are 24 bytes and grow down the phrase stack from
; $B9C8; ALL, EXCEPT, AND and THEN start or extend records (ParseEnd,
; DispatchSpecialWord, ParseAnd). The result is read by RunSentences, which
; matches the records against the command table.
;
; Entered at ParseLine for a line typed by the player. BeginOrderPass enters at
; ParseLineFrom with A = 1 to parse the text of an order given with SAY TO.
; When a question of the game is waiting for its answer (AwaitingAnswer not 0)
; the answer is parsed as the continuation of the saved record: the parser goes
; on at CloseRecord as if AND had just been read.
;
; Registers in the handlers: E parser flags (bit 1: the record has no command
; word yet; bit 3: cleared by ParseAnd when it has saved a position; bits 6, 7:
; first and second phrase block still free), D class of the last word read, IY
; the record being built, ParserWordCount ($B706) the number of records.
;
;   A InputFromOrder: 0 for the typed line (ParseLineFrom only; ParseLine sets
;     it)
;   IY Phrase record to start with ($B9C8 for ParseLine)
; O:F Z when the line was parsed, NZ when it was refused (a message was
;     printed)
ParseLine:
  LD IY,PhraseRecord0     ; top of the phrase stack
  XOR A
; This entry point is used by the routine at BeginOrderPass.
ParseLineFrom:
  LD (InputFromOrder),A   ; InputFromOrder
  CALL ClearAllStage      ; ClearAllStage
  LD (ParserWordCount),A  ; ParserWordCount = 0
  LD E,$FF                ; all parser flags set
  LD A,(AwaitingAnswer)   ; AwaitingAnswer: an answer is awaited?
  AND A
  LD D,TOKEN_AND          ; the answer continues the saved record, like "and"
  JP NZ,CloseRecord
  LD D,TOKEN_END          ; no word before this one
; This entry point is used by the routines at ParseEnd and DispatchSpecialWord.
StartPhraseRecord:
  XOR A
  LD (ActionFlag),A       ; ActionFlag: no preposition in this phrase yet
  LD A,E
  OR $C7                  ; both phrase blocks free, command word needed...
  LD E,A
  LD A,(AllStage)         ; AllStage
  CP $02
  JR NZ,ParseLine_0
  RES 1,E                 ; after EXCEPT no command word is needed
ParseLine_0:
  CALL ClearRecord        ; ClearRecord
; This entry point is used by the routines at ParseDirection, ParseGoVerb,
; ParseIn, RejectLine, ResumeDispatch, WordExcept, WordAll, StoreParsedOrders
; and WordHelp.
ParseNextWord:
  LD HL,ActionSlots       ; ActionSlots
  LD B,$0A
  CALL ClearBytes         ; ClearBytes
  SET 4,E
; This entry point is used by the routine at ParseArticle.
DispatchWord:
  CALL ReadWord           ; ReadWord: A = class nibble
  PUSH DE
  RRCA                    ; class * 2
  RRCA
  RRCA
  LD E,A
  LD D,$00
  LD HL,ActionTable       ; ActionTable
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  POP DE
  JP (HL)                 ; to the handler of the class

; Action dispatch table: 13 handler addresses
;
; Indexed by A rotated right three times at $75C1 (value of $7873); jumped to
; by $75D1.
ActionTable:
  DEFW ParseAdverb
  DEFW ParseIn
  DEFW ParseDirection
  DEFW ParseVerb
  DEFW ParseGoVerb
  DEFW ParseNoun
  DEFW ParseAdjective
  DEFW ParsePreposition
  DEFW ParseArticle
  DEFW DispatchSpecialWord
  DEFW ParseAnd
  DEFW ParseThen
  DEFW ParseEnd

; Test for an order being parsed (Z set)
;
; InputFromOrder ($B71B) is 1 while the text after SAY TO is parsed as an order
; for a character (BeginOrderPass starts it, StoreParsedOrders ends it), 0 for
; the player's own line. Returns Z when it is 1.
;
; O:A InputFromOrder - 1
; O:F Z set while an order is parsed
TestOrderText:
  LD A,(InputFromOrder)
  DEC A
  RET

; Test for the player's own line being parsed (Z set)
;
; Z when InputFromOrder ($B71B) is 0: the words come from the line the player
; typed, so a syntax error is reported ("What ?"). NZ while the order after SAY
; TO is parsed, which ignores errors.
;
; O:A InputFromOrder
; O:F Z set for the typed line
TestTypedLine:
  LD A,(InputFromOrder)
  AND A
  RET

; Parse the end of the line or THEN: close the phrase records
;
; The handler of class 12 (the end of the typed line, $C0) in ActionTable;
; class 11 (THEN, a full stop) and AND enter at ParseThen. It ends the phrase
; the parser was building:
;
; 1. A phrase with no command word is refused with "What ?" (PrintWhat) for a
; typed line, except when it is the first and only one and empty (the line was
; blank or ended at once): the parser then returns NZ without a message.
; Nothing is checked while the text of an order (SAY TO) is parsed.
;
; 2. The record is closed (CloseRecord): after ALL its RECF_ALL flag is set,
; and ParserWordCount ($B706) counts it, except for an AND inside the nouns of
; EXCEPT, which goes on filling the same EXCEPT record. IY moves to the next
; newer record. After AND a new empty record is started at once
; (StartPhraseRecord).
;
; 3. After THEN and at the end of the line the records are completed. When
; AwaitingAnswer ($B71A) is not 0 the line is the player's answer to a question
; of the game ("Which key ?", "Give the map to what ?"): the words the answer's
; noun phrase (in the first record after the saved one, at $B9B0) lacks are
; taken from the phrase of the saved record at $B9C8 that the question was
; about (offset AwaitingAnswer; inferred, run only by the endgame input in
; re/maps). Then every record without a command word of its own inherits the
; one of the record before it (InheritRecord: "take the key and the lamp"),
; walking from the oldest record to the newest. Then, walking back from the
; newest, a second phrase block (a trailing "in the chest") is copied into
; older records that have the same command word and no second noun phrase of
; their own: "put the key and the lamp in the chest" becomes two commands with
; the chest. Records of the nouns after EXCEPT are skipped by both walks
; (FindNewerRecord, FindOlderRecord).
;
; 4. At the end of the line ParserFlag ($B705) is cleared. If it is not 0
; (THEN) the parse ends here for a typed line, which returns Z so that the
; caller executes the records and calls the parser again for the rest of the
; line (GameStart); for the text of an order the parser goes on with a new
; record.
;
; D Class of the word that ended the phrase: THEN, AND or the end of the line E
; Parser flags (see ParseLine) IY Phrase record being built O:F Z when the
; records are ready, NZ when the line was refused or is empty
ParseEnd:
  XOR A
  LD (ParserFlag),A       ; ParserFlag 0: the line is finished
; This entry point is used by the routines at ParseAnd and ParseGoVerb.
ParseThen:
  BIT 1,E                 ; no command word in this phrase?
  JR Z,CloseRecord
  LD A,(ParserWordCount)  ; ParserWordCount
  AND A
  JR NZ,CloseRecord       ; an older record can lend its command word
  LD A,(WordFlags)        ; WordFlags: class of the word before
  CP TOKEN_END
  JR NZ,ParseEnd_0
  CP D                    ; end of line right after the start of the line:
  JR Z,TestOrderText      ; an empty line (returns the result of TestOrderText)
ParseEnd_0:
  CALL TestTypedLine      ; TestTypedLine
  JP Z,PrintWhat          ; typed line without a command: "What ?"
; This entry point is used by the routine at ParseLine.
CloseRecord:
  LD A,(AllStage)         ; AllStage
  DEC A
  JR NZ,ParseEnd_1
  SET RECF_ALL,(IY+1)     ; ALL typed: flag the record
ParseEnd_1:
  LD HL,ParserWordCount   ; ParserWordCount
  DEC A
  LD A,D
  JR NZ,ParseEnd_2
  CP TOKEN_AND            ; after EXCEPT, AND adds to the same record
  JR Z,ParseEnd_3
ParseEnd_2:
  INC (HL)                ; one more record
ParseEnd_3:
  CALL StepNewer          ; StepNewer
  CP TOKEN_AND
  JP Z,StartPhraseRecord  ; AND: start the next record
  LD A,(AwaitingAnswer)   ; AwaitingAnswer
  AND A
  JR Z,InheritWords
  PUSH DE                 ; the line answers a question:
  LD E,A
  LD D,$00
  LD HL,PhraseRecord0     ; HL = the saved record's phrase the question was
                          ; about
  ADD HL,DE
  PUSH IY
  LD IY,PhraseRecord1     ; the answer's first record
  LD A,(IY+$08)           ; has it a noun?
  OR (IY+$09)
  LD DE,PhraseRecord1Slot1 ; DE = its phrase REC_PHRASE_A
  JR Z,ParseEnd_5         ; no: complete that phrase
  LD A,(IY+$08)
  CP (HL)                 ; the same noun as in the question?
  JR NZ,ParseEnd_4
  LD A,(IY+$09)
  INC HL
  CP (HL)
  DEC HL
  JR Z,ParseEnd_5         ; yes: complete that phrase
ParseEnd_4:
  LD A,(IY+$12)           ; else its second phrase, if it is empty
  OR (IY+$13)
  LD DE,PhraseRecord1Slot2 ; DE = REC_PHRASE_B of the answer
ParseEnd_5:
  POP IY
  JR NZ,ParseEnd_9        ; no phrase to complete
  EX DE,HL                ; HL = the answer's phrase, DE = the saved phrase
  LD B,$03                ; three words
ParseEnd_6:
  LD A,(HL)
  INC HL
  OR (HL)
  DEC HL
  JR NZ,ParseEnd_7        ; word present: keep it
  LD A,(DE)               ; missing: take it from the question's phrase
  LD (HL),A
ParseEnd_7:
  INC HL
  INC DE
  JR NZ,ParseEnd_8
  LD A,(DE)
  LD (HL),A
ParseEnd_8:
  INC HL
  INC DE
  DJNZ ParseEnd_6
ParseEnd_9:
  POP DE
InheritWords:
  PUSH IY
  LD IY,LocationTable     ; one record above the oldest
  LD A,(ParserWordCount)  ; ParserWordCount
  LD B,A
  PUSH BC
  CALL StepNewerCount     ; StepNewerCount: to the oldest record
ParseEnd_10:
  LD A,B                  ; oldest to newest:
  AND A
  JR Z,ParseEnd_11
  CALL StepNewerCount     ; StepNewerCount: IX = the older record
  LD A,(IY+$01)
  AND $7F
  OR (IY+$00)             ; a record with no command word (RECF_ALL aside)?
  CALL Z,InheritRecord    ; InheritRecord: take the older one's
  JR ParseEnd_10
ParseEnd_11:
  POP BC
  POP IY                  ; IY = the free record after the newest
  PUSH IY
  CALL StepOlderCount     ; StepOlderCount
ParseEnd_12:
  LD A,B                  ; newest to oldest:
  AND A
  JP Z,ParseEnd_13
  CALL StepOlderCount     ; StepOlderCount: IX = the newer, IY = the older
                          ; record
  LD A,(IY+$12)           ; the older one has a second noun phrase: leave it
  OR (IY+$13)
  JR NZ,ParseEnd_12
  LD A,(IY+$00)           ; same command word in both?
  CP (IX+$00)
  JR NZ,ParseEnd_12
  LD A,(IY+$01)
  CP (IX+$01)
  JR NZ,ParseEnd_12
  LD A,(IX+$0E)           ; the newer one has a second block (a preposition)?
  OR (IX+$0F)
  JR Z,ParseEnd_12
  EXX
  LD DE,REC_BLOCK_B
  CALL CopyBlockFromIX    ; CopyBlockFromIX: older record gets that block too
  JP ParseEnd_12
ParseEnd_13:
  POP IY
  LD A,(ParserFlag)       ; ParserFlag
  AND A
  RET Z                   ; end of the line: Z, the records are ready
  CALL TestTypedLine      ; TestTypedLine
  RET Z                   ; THEN in a typed line: stop here, the rest is parsed
                          ; later
  JP StartPhraseRecord    ; an order: go on with a new record

; Parse a direction or an adverb (word classes 2 and 0)
;
; The handler of class 2 (north, up, down, ne...) in ActionTable; class 0
; (adverbs such as "carefully", "please") enters at ParseAdverb.
;
; A direction that comes while the phrase still needs its command word
; (PF_NEED_COMMAND) is a command by itself, "north": it goes to the verb
; handler (ParseVerbAsCommand). Otherwise the word is the command's second
; word, which may be given once (PF_DIRECTION_OK): after a verb, or after an
; adverb ("go north", "take carefully"). After the nouns of EXCEPT the parser
; first returns to the main record (PreviousRecord). The word is stored as the
; record's second command word (+2, REC_WORD2) and parsing goes on with the
; next word. A second one, or one in a phrase that has already used it, is
; refused with "What ?" (RejectLine).
;
; BC The word (dictionary offset) D Class of this word (set to 0 for a
; direction) E Parser flags (see ParseLine) IY Phrase record being built
ParseDirection:
  BIT PF_NEED_COMMAND,E
  JR NZ,ParseVerbAsCommand ; no command word yet: "north" is the command
  LD D,$00
; Entry point for the words of class 0.
ParseAdverb:
  BIT PF_DIRECTION_OK,E
  JP Z,RejectLine         ; already used: RejectLine
  LD A,(AllStage)         ; AllStage
  CP ALL_STATE_EXCEPT
  JR NZ,ParseDirection_0
  CALL PreviousRecord     ; PreviousRecord: back to the main record
ParseDirection_0:
  RES PF_DIRECTION_OK,E   ; the second word is taken
  LD L,REC_WORD2
  CALL StoreRecordWord    ; StoreRecordWord: second command word
  JP ParseNextWord        ; ParseNextWord

; Parse AND: save the parser position, then treat it as a separator
;
; The handler of class 10 (and, the comma) in ActionTable. Clears flag bit 3 of
; E ("a position is saved"), skips any further AND words, puts the first word
; after them back (WordListPtr points at it again) and saves the parser state
; in SavedHL, SavedA1, SavedIY and SavedA2 ($7574-$7579): the address of that
; word, the flags E, the phrase record IY and ParserWordCount. Then goes on at
; ParseThen as for THEN. When a command word follows instead of another noun
; (inferred: "take the map and go east"), ParseGoVerb restores this state (it
; reloads WordListPtr, E, IY and the word count from the saved copies) and
; parses from the saved word again as a new command.
;
; D Class of the previous word
; E Parser flags (bit 3 is cleared)
; IY Phrase record being built
ParseAnd:
  RES 3,E                 ; a position is saved
  PUSH DE
ParseAnd_0:
  CALL ReadWord           ; ReadWord
  CP TOKEN_AND            ; skip "and and"
  JR Z,ParseAnd_0
  DEC HL                  ; back to the start of that token
  DEC HL
  LD (SavedHL),HL         ; SavedHL
  LD (WordListPtr),HL     ; WordListPtr: read it again later
  POP DE
  LD A,E
  LD (SavedA1),A          ; SavedA1: the flags
  LD (SavedIY),IY         ; SavedIY: the record
  LD A,(ParserWordCount)  ; ParserWordCount
  LD (SavedA2),A          ; SavedA2
  JP ParseThen

; Parse a verb (word classes 4 and 3)
;
; The handler of class 4 (go, run) in ActionTable; class 3 (the other verbs)
; enters at ParseVerb. The direction handler (ParseDirection) and "in"
; (ParseIn) also join at ParseVerbAsCommand when such a word has to be the
; command word.
;
; If an AND has saved the parser position (ParseAnd, PF_NO_SAVED_POS clear) and
; the line is the player's own, a verb after AND starts a new command: the
; saved position, flags and record are restored and the phrase is closed as if
; THEN had been read (ParseThen). The verb is read again by the next call of
; the parser, so "take the map and go east" is two commands.
;
; Otherwise the verb becomes the first command word of the record
; (StoreFirstWord). A second command word is refused with "What ?"
; (RejectLine). A verb that is go or run (PF_PLAIN_VERB clear) first looks
; ahead past any adverbs: when a direction follows, the direction becomes the
; command word (+0) and go or run the second word (+2), the form of the move
; commands in the command table. If none follows the verb is stored as it is.
;
; BC The word (dictionary offset) D Class of this word (ParseVerbAsCommand sets
; TOKEN_VERB) E Parser flags (see ParseLine) IY Phrase record being built
ParseGoVerb:
  RES 0,E                 ; PF_PLAIN_VERB clear: look ahead for a direction
; This entry point is used by the routines at ParseDirection and ParseIn.
ParseVerbAsCommand:
  LD D,TOKEN_VERB
ParseVerb:
  BIT PF_NO_SAVED_POS,E   ; no AND has saved a position?
  JR NZ,StoreVerb
  CALL TestTypedLine      ; TestTypedLine
  JR NZ,StoreVerb         ; an order: no restart
  LD HL,(SavedHL)         ; SavedHL
  LD (WordListPtr),HL     ; WordListPtr: back to the word after AND
  LD D,TOKEN_THEN
  LD A,(SavedA1)          ; SavedA1
  LD E,A
  LD A,(SavedA2)          ; SavedA2
  LD (ParserWordCount),A  ; ParserWordCount
  LD IY,(SavedIY)         ; SavedIY
  JP ParseThen            ; ParseThen: close the phrase before AND
StoreVerb:
  CALL ClearAllStage      ; ClearAllStage
  BIT PF_NEED_COMMAND,E
  JP Z,RejectLine         ; a command word already: RejectLine
  BIT PF_PLAIN_VERB,E
  JR Z,ParseGoDirection   ; go or run
StoreCommandWord:
  CALL StoreFirstWord     ; StoreFirstWord
  JP ParseNextWord        ; ParseNextWord
ParseGoDirection:
  PUSH DE                 ; look ahead:
  PUSH BC                 ; the verb
  LD HL,(WordListPtr)     ; WordListPtr
  PUSH HL
ParseGoVerb_0:
  CALL ReadWord           ; ReadWord
  CP $00
  JR Z,ParseGoVerb_0      ; skip adverbs (class 0)
  SET PF_PLAIN_VERB,E
  CP TOKEN_DIRECTION
  JR Z,ParseGoVerb_1
  POP HL                  ; not a direction: read it again later
  LD (WordListPtr),HL
  POP BC                  ; BC = the verb
  POP DE
  JR StoreCommandWord     ; the verb is the command word
ParseGoVerb_1:
  CALL StoreFirstWord     ; the direction (BC) is the command word
  POP HL
  POP BC                  ; BC = go or run
  POP HL
  LD L,REC_WORD2
  CALL StoreRecordWord    ; StoreRecordWord: go or run is the second word
  JP ParseNextWord        ; ParseNextWord

; Parse an article or auxiliary word (class 8)
;
; Handler for the words of class 8 (a, an, the, is, can ...) in the table
; ActionTable. The word is ignored: it clears bit 4 of the flags (the article
; that is allowed at the start of a phrase has been seen) and goes on with the
; next word.
;
; E Parser flags (bit 4 is cleared)
; IY Current phrase record
ParseArticle:
  RES 4,E                 ; an article has been seen
  JP DispatchWord         ; read the next word

; Parse "in" and the words of a noun phrase (word classes 1, 7, 6, 5)
;
; The handler of class 1 (in, into) in ActionTable. It either makes the word
; the command word or treats it as a preposition, then falls into the loop that
; reads one whole noun phrase, which the handlers of classes 7 (preposition), 6
; (adjective) and 5 (noun) also enter. A phrase is
;
; [preposition ...] [article] [adjective ...] [noun]
;
; with up to two prepositions (StorePreposition), one article (a second one is
; refused, RejectPhrase), any number of adjectives, two of which are kept
; (StoreAdjective), and one noun, kept in the noun slot of ActionSlots ($757F).
; The first word that is none of these is put back (WordListPtr is reset to
; InputLinePtr) and ends the phrase. The slots are then copied into a block of
; the record (StorePhraseBlock) and parsing goes on with the next word
; (ParseNextWord).
;
; "in" is a command by itself ("go in") when the phrase has no command word yet
; and the word before it was AND (via ParseVerbAsCommand); in any other place
; it is a preposition (D = TOKEN_PREPOSITION).
;
; After EXCEPT (AllStage 2) the phrase is stored differently. A preposition
; there means the phrase belongs to the main record, to which the parser
; returns first (PreviousRecord). Otherwise each noun goes into a record of its
; own, filled in block A (StoreFirstPhraseBlock) and flagged RECF_EXCEPT: the
; first one in the free record below the main record (ClearRecord), the
; following ones (after AND) in the records that ParseThen has started; these
; records are not counted in ParserWordCount. They name the objects that ALL
; leaves out (IsExcluded).
;
; BC The word (dictionary offset) D Class of this word (the other entries set
; TOKEN_PREPOSITION, TOKEN_ADJECTIVE or TOKEN_NOUN) E Parser flags (see
; ParseLine) IY Phrase record being built
ParseIn:
  BIT 1,E                 ; PF_NEED_COMMAND
  JR Z,ParseIn_0
  LD A,(WordFlags)        ; WordFlags: class of the word before
  CP TOKEN_AND
  JR Z,ParseVerbAsCommand ; ParseVerbAsCommand
ParseIn_0:
  LD D,TOKEN_PREPOSITION
; Entry point for the words of class 7.
ParsePreposition:
  CALL StorePreposition   ; StorePreposition
ParsePhraseWord:
  CALL ReadWord           ; ReadWord
  CP TOKEN_PREPOSITION
  JR Z,ParsePreposition   ; another preposition
  CP TOKEN_ARTICLE
  JR NZ,ParseIn_1
  BIT PF_ARTICLE_OK,E     ; an article is allowed once
  CALL Z,RejectPhrase     ; RejectPhrase
  RES PF_ARTICLE_OK,E
  JR ParsePhraseWord
ParseIn_1:
  CP TOKEN_ADJECTIVE
  JR Z,ParseAdjective
  CP TOKEN_NOUN
  JR Z,ParseNoun
  LD HL,(InputLinePtr)    ; any other word: not part of the phrase,
  LD (WordListPtr),HL     ; put it back
  JR EndNounPhrase
; Entry point for the words of class 6.
ParseAdjective:
  CALL StoreAdjective     ; StoreAdjective
  CALL ReadWord           ; ReadWord
  JR ParseIn_1
; Entry point for the words of class 5.
ParseNoun:
  LD HL,ActionSlots+$0004 ; the noun slot
  LD (HL),C
  INC HL
  LD (HL),B
EndNounPhrase:
  LD D,TOKEN_NOUN
  LD A,(AllStage)         ; AllStage
  CP ALL_STATE_EXCEPT
  JR NZ,ParseIn_3
  LD HL,(ActionSlots)     ; ActionSlots: first preposition
  LD A,H
  OR L
  JR NZ,ParseIn_2         ; a preposition: the main record
  BIT RECF_EXCEPT,(IY+PARSED_RECORD_SIZE+1) ; is the older record an EXCEPT
                                            ; record?
  JR NZ,StoreExceptNouns  ; yes: IY is already a free record for the next noun
  LD BC,-PARSED_RECORD_SIZE
  ADD IY,BC               ; else this is the first noun: the free record below
  CALL ClearRecord        ; ClearRecord
StoreExceptNouns:
  CALL StoreFirstPhraseBlock ; StoreFirstPhraseBlock
  LD (IY+$01),$01<<RECF_EXCEPT ; RECF_EXCEPT
  JP ParseNextWord        ; ParseNextWord
ParseIn_2:
  CALL PreviousRecord     ; PreviousRecord
ParseIn_3:
  CALL StorePhraseBlock   ; StorePhraseBlock
  JP Z,ParseNextWord      ; ParseNextWord
  RET

; Store a word in the first free slot of a pair
;
; Stores the word BC in the first of two consecutive word slots at HL that is
; still empty (0). Entered at StoreAdjective it fills the adjective slots of
; ActionSlots ($7581, $7583); StorePreposition enters at StoreWordInPair for
; the two preposition slots. Both full: the phrase is rejected through
; RejectPhrase.
;
; BC Word to store (dictionary offset)
; HL First slot of the pair (StoreWordInPair only; StoreAdjective uses
;    ActionSlots+6)
StoreAdjective:
  LD HL,ActionSlots+$0006 ; adjective slots
; This entry point is used by the routine at StorePreposition.
StoreWordInPair:
  LD A,(HL)               ; first slot empty?
  INC HL
  OR (HL)
  JR Z,StoreAdjective_0
  INC HL                  ; second slot
  LD A,(HL)
  INC HL
  OR (HL)
  JP NZ,RejectPhrase      ; both full: reject the phrase
StoreAdjective_0:
  LD (HL),B               ; store BC
  DEC HL
  LD (HL),C
  RET

; Store a preposition in the phrase slots
;
; Counts the prepositions of the phrase in ActionFlag ($757A, cleared when a
; phrase record is started by StartPhraseRecord): the third is refused
; (RejectPhrase, RejectPhrase). Otherwise the word is stored in the first free
; of the two preposition slots at the start of ActionSlots ($757B, $757D) by
; StoreWordInPair.
;
; Preposition-like words are class 7 (on, with, to...) and class 1 (in, into),
; which ParseIn reads.
;
;   BC Word (class nibble and dictionary offset)
; O:HL After the stored word (StoreWordInPair)
StorePreposition:
  LD HL,ActionFlag        ; ActionFlag
  INC (HL)                ; one more preposition
  LD A,(HL)
  CP MAX_PREPOSITIONS
  JP NC,RejectPhrase      ; a third one: reject the phrase
  LD HL,ActionSlots       ; ActionSlots: the two preposition slots
  JR StoreWordInPair      ; StoreWordInPair

; Copy the collected phrase slots into the record
;
; Copies the ten bytes of ActionSlots (two prepositions, noun, two adjectives)
; into one of the two phrase blocks of the record at IY. Flag bit 6 of E
; selects the first block (+4) and is cleared; otherwise bit 7 selects the
; second block (+$0E) and is cleared; with neither set there is no room for
; another phrase and the line is rejected (RejectPhrase). The slots are not
; cleared here (ParseNextWord does that).
;
; StoreFirstPhraseBlock is the entry for the first block alone, used for the
; nouns after EXCEPT.
;
;   E Parser flags: bit 6 first block free, bit 7 second block free
;   IY Phrase record to fill
; O:E Flags with the used bit cleared
; O:A 0
; O:F Z set
StorePhraseBlock:
  BIT 6,E                 ; first block free?
  JR NZ,StoreFirstPhraseBlock
  BIT 7,E                 ; second block free?
  JR NZ,StorePhraseBlock_0
  CALL RejectPhrase       ; neither: reject the phrase
  XOR A
  RET
StorePhraseBlock_0:
  RES 7,E                 ; second block used
  PUSH DE
  LD DE,REC_BLOCK_B       ; offset of the second block
StorePhraseBlock_Copy:
  PUSH BC
  PUSH IY
  POP HL
  ADD HL,DE               ; HL = IY + offset
  EX DE,HL
  LD HL,ActionSlots       ; ActionSlots
  LD BC,PHRASE_BLOCK_SIZE
  LDIR
  POP BC
  POP DE
  XOR A
  RET
; This entry point is used by the routine at ParseIn.
StoreFirstPhraseBlock:
  RES 6,E                 ; first block used
  PUSH DE
  LD DE,REC_BLOCK_A       ; offset of the first block
  JR StorePhraseBlock_Copy

; Go back to the previous phrase record
;
; Makes the nearest older record without the EXCEPT flag (FindOlderRecord) the
; current one and falls into ClearAllStage, which clears the ALL/EXCEPT stage.
; Used when the nouns after EXCEPT have been stored in their own record and
; parsing returns to the main command, or for a second command after SAY TO.
;
;   IY Current phrase record
; O:IY The previous phrase record
; O:IX The same record
; O:A 0
PreviousRecord:
  CALL FindOlderRecord    ; IX = older record
  PUSH IX
  POP IY                  ; IY = IX

; Clear the ALL/EXCEPT stage
;
; Sets AllStage to 0. That byte is 0 for a normal command, 1 after ALL
; (WordAll) and 2 after EXCEPT (WordExcept); it is cleared at the start of
; every parse (ParseLine) and when the parser leaves the EXCEPT nouns.
;
; O:A 0
ClearAllStage:
  XOR A
  LD (AllStage),A         ; AllStage
  RET

; Clear a phrase record and the head of the next one
;
; Zeroes the 24 bytes of the record at IY and the first word of the record
; below it (the next one to be started), so a record in use always ends with an
; empty one. Records are PARSED_RECORD_SIZE bytes, kept on the phrase stack
; that grows down from $B9C8.
;
;   IY Phrase record to clear
; O:B 0
ClearRecord:
  PUSH IY
  POP HL
  LD B,PARSED_RECORD_SIZE
  CALL ClearBytes         ; zero fill
  LD (IY-PARSED_RECORD_SIZE),B ; empty first word of the next record
  LD (IY-PARSED_RECORD_SIZE+$01),B
  RET

; Read the next word of the parsed line
;
; Takes the next token of the list the line editor built at $709C (pairs: class
; in the high nibble of the first byte, dictionary offset in the other 12 bits)
; from WordListPtr. The class of the word is returned in A and D; BC is the
; word (its offset). The previous token's address is saved in InputLinePtr (so
; the word can be put back, as ParseIn does) and the D passed in, the class of
; the word before, in WordFlags.
;
;   D Class of the previous word (stored in WordFlags)
; O:A Class of this word, as a high nibble (0, $10 ... $C0 for the end)
; O:D The same
; O:B Bits 8-11 of the word offset
; O:C Bits 0-7 of the word offset
; O:HL Address after the token
ReadWord:
  LD HL,(WordListPtr)
  LD (InputLinePtr),HL    ; InputLinePtr: this token, for putting it back
  LD A,D
  LD (WordFlags),A        ; WordFlags: previous class
  LD A,(HL)
  AND $0F
  LD B,A
  LD A,(HL)
  AND $F0
  LD D,A
  INC HL
  LD C,(HL)               ; C = low byte of the offset
  INC HL
  LD (WordListPtr),HL
  RET

; Step IY to the next older phrase record, counting down B
;
; Counts one record off B, moves IY to the nearest older record that is not an
; EXCEPT record (FindOlderRecord) and leaves the old IY in IX (the swap is
; SwapRecordPtrs). The mirror of StepNewerCount, which goes to newer records.
; Used by ParseEnd to walk the records from the newest to the oldest.
;
;   B Records left to visit
;   IY Current record
; O:B Decreased by one
; O:IY The next older record
; O:IX The old IY
StepOlderCount:
  DEC B
  CALL FindOlderRecord    ; FindOlderRecord: IX = the older record
  JR SwapRecordPtrs       ; swap IX and IY

; Step IY to the next newer phrase record
;
; Moves IY to the next record below it on the phrase stack that is not an
; EXCEPT record (FindNewerRecord) and leaves the old IY in IX (the swap is
; SwapRecordPtrs). StepNewerCount also counts the record down in B (the number
; of records still to visit); StepNewer does not. Records are created
; downwards, so "newer" is a lower address.
;
;   B Records left to visit (StepNewerCount only)
;   IY Current record
; O:B Decreased by one (StepNewerCount only)
; O:IY The next newer record
; O:IX The old IY
StepNewerCount:
  DEC B
; This entry point is used by the routine at ParseEnd.
StepNewer:
  CALL FindNewerRecord
; This entry point is used by the routine at StepOlderCount.
SwapRecordPtrs:
  PUSH IX
  PUSH IY
  POP IX
  POP IY
  RET

; Find the next newer phrase record
;
; IX = the nearest record below IY on the phrase stack whose RECF_EXCEPT flag
; (bit 6 of byte +1) is clear; falls into the search of FindOlderRecord with
; the step -PARSED_RECORD_SIZE.
;
;   IY Current record
; O:IX The next newer record
FindNewerRecord:
  PUSH DE
  LD DE,-PARSED_RECORD_SIZE ; step down: newer
  JR FindRecordStep       ; search

; Find the previous (older) phrase record
;
; IX = the nearest record above IY on the phrase stack whose RECF_EXCEPT flag
; (bit 6 of byte +1) is clear. The search loop is shared with FindNewerRecord,
; which enters at FindRecordStep with the downward step in DE.
;
;   IY Current record
; O:IX The next older record
FindOlderRecord:
  PUSH DE
  LD DE,PARSED_RECORD_SIZE ; step up: older
; This entry point is used by the routine at FindNewerRecord.
FindRecordStep:
  PUSH IY
  POP IX
FindOlderRecord_0:
  ADD IX,DE               ; next record in the direction of DE
  BIT RECF_EXCEPT,(IX+1)  ; skip the EXCEPT records
  JR NZ,FindOlderRecord_0
  POP DE
  RET

; Let a phrase record inherit from the one before it
;
; Used for the second and later parts of a list ("take map and key", "look in
; chest and map"). The record at IY copies the first command word of the older
; record at IX (and its flags except ALL), so "key" becomes "take key".
;
; When the older record's first phrase block has a word at +4 (a preposition)
; and bit 7 of E (second block free) is set, the record's own noun phrase moves
; to the second block and the older first block is copied over it: "look in
; chest and map" becomes look in chest, with map as the second noun.
; CopyBlockFromIX is the common tail, which copies a 10-byte block from IX to
; IY (DE = offset, 4 or $0E) and then the second command word when the record
; has none; ParseEnd enters it with DE = REC_BLOCK_B to pass a second block
; back to an older record. BC, DE and HL are preserved (EXX).
;
; IX Older phrase record
; IY Phrase record to complete
; E Parser flags (bit 7: second phrase block free)
InheritRecord:
  EXX                     ; keep BC, DE, HL
  LD A,(IX+$01)           ; flags of the older word, without ALL...
  AND $7F
  OR (IY+$01)             ; ...added to our own flags
  LD (IY+$01),A
  LD A,(IX+$00)           ; first command word
  LD (IY+$00),A
  EXX
  LD A,(IY+PARSED_RECORD_SIZE+REC_BLOCK_A) ; older record: first block has a
                                           ; preposition?
  OR (IY+PARSED_RECORD_SIZE+REC_BLOCK_A+$01)
  RET Z
  BIT 7,E                 ; second block free?
  RET Z
  EXX
  PUSH IY
  POP HL
  LD DE,REC_PHRASE_B      ; move our noun phrase (REC_PHRASE_A) ...
  ADD HL,DE
  PUSH HL
  LD DE,-PHRASE_BLOCK_SIZE
  ADD HL,DE
  POP DE
  LD BC,PHRASE_WORDS_SIZE ; ... to the second block
  LDIR
  LD DE,REC_BLOCK_A       ; then copy the older first block
; This entry point is used by the routine at ParseEnd.
CopyBlockFromIX:
  CALL L78FB_0            ; 10 bytes IX+DE to IY+DE
  LD A,(IY+$02)           ; no second command word yet?
  OR (IY+$03)
  LD DE,REC_WORD2         ; copy it as well
  CALL Z,L78FB_1
  EXX
  RET

; Copy 6 bytes of record field IX+DE to IY+DE (entry for C=6; $78FF copies 10,
; $7903 copies 2)
L78FB:
  LD C,$06
  JR L78FB_2
L78FB_0:
  LD C,$0A
  JR L78FB_2
L78FB_1:
  LD C,$02
L78FB_2:
  PUSH IY
  POP HL
  ADD HL,DE
  PUSH HL
  PUSH IX
  POP HL
  ADD HL,DE
  POP DE
  LD B,$00
  LDIR
  RET

; Store a word as the first word of the record
;
; Clears bit 1 of E (no command word is needed any more) and stores BC at +0 of
; the record at IY. StoreRecordWord stores BC at +L: +0 for the first command
; word (a verb, or the direction in "go north"), +2 for the second (the word
; "go" when a direction follows).
;
; BC Word
; E Parser flags (bit 1 is cleared, StoreFirstWord only)
; IY Phrase record
; L Offset in the record, 0 or 2 (StoreRecordWord only)
StoreFirstWord:
  RES 1,E
  LD L,REC_WORD1
; This entry point is used by the routines at ParseDirection and ParseGoVerb.
StoreRecordWord:
  PUSH DE                 ; keep DE
  PUSH IY
  POP DE
  LD H,$00                ; HL = L
  ADD HL,DE               ; HL = IY + L
  LD (HL),C               ; word, low byte first
  INC HL
  LD (HL),B
  POP DE
  RET

; Reject the phrase
;
; Called (or jumped to) when the words do not fit the grammar. While an order
; after SAY TO is being parsed (TestTypedLine gives NZ) the error is ignored
; and the routine just returns. For the player's own line it discards one
; return address and falls into RejectLine, which prints "What ?" and returns
; NZ to the caller's caller, so parsing stops.
;
; O:F NZ (order text: returns to the caller)
RejectPhrase:
  CALL TestTypedLine
  RET NZ                  ; an order: ignore the error
  POP HL                  ; drop the caller: end the parse

; Refuse the line with "What ?"
;
; For a typed line (TestTypedLine gives Z) prints "What ?" in the input window
; and returns NZ to the caller of the parser, so the line is not executed. For
; an order being parsed (SAY TO) the error is ignored and the parser goes on
; with the next word at ParseNextWord. RejectPhrase enters here after dropping
; a return address. PrintWhat is the second entry, which prints the message
; only (used when the parser ends with a sentence that is not finished).
;
; Hardware: none directly (the message goes through PrintMessage).
;
;   E Parser flags (kept for ParseNextWord)
; O:F NZ when the line was refused (PrintWhat)
RejectLine:
  CALL TestTypedLine      ; TestTypedLine
  JP NZ,ParseNextWord     ; an order: ignore the error, ParseNextWord
; This entry point is used by the routines at GameStart and ParseEnd.
PrintWhat:
  LD HL,MsgWhat           ; "What ?"
  LD A,$01
  LD (RawOutputFlag),A    ; RawOutputFlag: the input window
  CALL PrintMessage       ; PrintMessage
  OR $01                  ; NZ
  RET

; Workspace of the record routines ($79B6-$7E7C)
;
; Bytes and words kept between the routines at $7A14, $7AF5, $7B9E, $7C23,
; $7DBC: $794E, $7950, $795E hold IX; $7958, $795A, $795C hold HL/DE.
RecWork:
  DEFB $00
RecWork1:
  DEFB $00
RecWork2:
  DEFB $00
RecWork3:
  DEFB $00,$00
RecBuf1:
  DEFB $00,$00,$00,$00,$00,$00
RecBuf2:
  DEFB $00,$00,$00,$00,$00,$00
RecPtr1:
  DEFW $0000
RecPtr2:
  DEFW $0000
RecWork4:
  DEFB $00
RecWork5:
  DEFB $00
RecWork6:
  DEFB $00,$00
RecWork7:
  DEFB $00
RecWork8:
  DEFB $00
RecWord1:
  DEFW $0000
RecWord2:
  DEFW $0000
RecWord3:
  DEFW $0000
RecPtr3:
  DEFW $0000

; Run the parsed sentences, one turn each
;
; Takes the phrase records ParseLine has left on the phrase stack (the first at
; $B9C8, the others below it at 24-byte steps, ParserWordCount of them) and
; runs them in order. For each record: MatchSentence matches it to a command
; and finds its objects; if that fails (a message was printed) the rest of the
; line is given up (ParserFlag is cleared). The command is then checked once
; with ActionPerform 0 (RunCheck). A command the check refuses has printed its
; reason and takes no turn: it goes on at PerformRefusal. A command that passes
; is printed as a sentence (PrintCommandSentence), carried out
; (DispatchCommand, ActionPerform 1) and followed by the turn of the world,
; EndOfTurn: the timers tick (L96B3) and every other character acts. With ALL
; typed (VerbAllFlag not 0) the same record is matched again for the next
; object (MatchSentence keeps the scan position) until none is left. Then the
; next record is taken; a record that only holds the nouns after EXCEPT is
; stepped over.
;
; When a question of the game is waiting for its answer (AwaitingAnswer, set by
; SaveParsedRecord), the first record is the saved question and is not run
; again: the routine goes straight to the next record. The flag is cleared.
;
; Hardware: none directly (the commands print and draw through the output
; routines).
;
; O:F Z (the caller tests ParserFlag to know whether the line has more
;     sentences)
RunSentences:
  XOR A
  LD (VerbAllFlag),A      ; VerbAllFlag: not ALL
  LD IY,PhraseRecord0     ; the first record
  LD HL,AwaitingAnswer    ; AwaitingAnswer
  CP (HL)
  LD (HL),A               ; clear it
  JP NZ,NextRecord        ; there was one: skip the saved question record
RunSentences_Record:
  CALL MatchSentence      ; MatchSentence
  JR NZ,RunSentences_0
  XOR A                   ; not understood: give up the rest of the line
  LD (ParserFlag),A       ; ParserFlag
  RET
RunSentences_0:
  CALL RunCheck           ; RunCheck: Z when the command is refused
  JP Z,PerformRefusal     ; refused: print the reason, no turn
  LD A,$01
  LD (ActionPerform),A    ; ActionPerform: carry it out
  CALL PrintCommandSentence ; print the command as a sentence
  CALL DispatchCommand    ; carry out the command
; This entry point is used by the routine at MatchCommand.
EndOfTurn:
  CALL L96B3              ; the world's turn: timers, then the other characters
; This entry point is used by the routine at ExplainNounFailure.
RunSentences_More:
  LD A,(VerbAllFlag)      ; VerbAllFlag
  AND A
  JR NZ,RunSentences_Record ; ALL: the same record again for the next object
; This entry point is used by the routine at ExplainNounFailure.
NextRecord:
  LD A,(ParserWordCount)  ; ParserWordCount
  DEC A
  LD (ParserWordCount),A
  RET Z                   ; no record left
  LD BC,-PARSED_RECORD_SIZE
RunSentences_1:
  ADD IY,BC               ; the next record, further down the stack
  BIT RECF_EXCEPT,(IY+1)
  JR NZ,RunSentences_1    ; skip the records that only hold EXCEPT nouns
  JR RunSentences_Record

; Clear the record workspace
;
; Sets B701 to 0 (output to the story window) and zeroes the first 17 bytes of
; the record workspace, RecWork to RecBuf2 inclusive. First step of matching a
; command (MatchSentence, TestActorCommand).
;
; O:A 0
ResetRecWork:
  XOR A
  LD (RawOutputFlag),A    ; B701: story window
  LD HL,RecWork
  LD B,RecPtr1-RecWork
  CALL ClearBytes
  RET

; Match a phrase record to a command and find its objects
;
; Takes the parsed sentence at IY and prepares everything the check and the
; verb handlers need: FirstObject and SecondObject start as NO_OBJECT; the
; record workspace is cleared (ResetRecWork); MatchCommand finds the command
; table record that fits the verb and prepositions (Z here: nothing fits and a
; message has been printed). The record's number (1-59) becomes CommandId and
; its address goes to RecPtr3. The flags of the command are unpacked
; (UnpackFlags) and the scan for the first noun is set up (StartNounScan1).
; ActionPerform is set to 0 (test pass).
;
; A command with no nouns (bits 2-3 of StateB71D clear) is ready. For the
; others ResolveNouns finds the objects the noun phrases mean and puts them in
; FirstObject and SecondObject; if it cannot, ExplainNounFailure prints why (I
; see nothing to ..., or asks what is meant) and the sentence ends there. When
; ALL was typed (RecWork4 holds the ALL flag; it is copied to VerbAllFlag) the
; objects come one by one, once per call: an object that EXCEPT names is passed
; over (IsExcluded) and the scan carries on at the next one.
;
; Hardware: none.
;
;   IY Parsed phrase record
; O:F NZ when the sentence is matched and its objects are found, Z when it
;   is not (the message is already printed)
; O:IX Command table record
MatchSentence:
  LD A,$FF
  LD (SecondObject),A     ; SecondObject: none
  LD (FirstObject),A      ; FirstObject: none
  CALL ResetRecWork       ; ResetRecWork
  CALL MatchCommand       ; MatchCommand
  RET Z                   ; no command fits
  LD A,$01                ; A: the record's index in CommandTable, from 1
  PUSH IX
  POP HL
  LD DE,CommandTable      ; CommandTable
  SBC HL,DE
  JR Z,MatchSentence_1
  LD DE,COMMAND_RECORD_SIZE
MatchSentence_0:
  INC A
  SBC HL,DE
  JR NZ,MatchSentence_0
MatchSentence_1:
  LD (CommandId),A        ; CommandId
  LD (SavedCommandId),A   ; SavedCommandId
  LD (RecPtr3),IX         ; RecPtr3
  CALL UnpackFlags        ; UnpackFlags
  CALL StartNounScan1     ; StartNounScan1
  XOR A
  LD (ActionPerform),A    ; ActionPerform: test pass
  LD A,(StateB71D)        ; StateB71D: command flags
  AND $0C                 ; does the command take nouns?
  JR Z,MatchSentence_2    ; no
  LD A,(RecWork4)         ; RecWork4: the ALL flag of the first word
  LD (VerbAllFlag),A      ; VerbAllFlag
  RLCA
  AND $01
  LD (RecWork5),A         ; RecWork5: 1 when ALL
MatchSentence_Object:
  CALL ResolveNouns       ; ResolveNouns
  JP NZ,ExplainNounFailure ; no (or no single) object: say so
  LD A,(VerbAllFlag)      ; VerbAllFlag
  AND A
  JR Z,MatchSentence_2    ; not ALL: done
  CALL IsExcluded         ; IsExcluded: EXCEPT names this object?
  JR NZ,MatchSentence_Object ; yes: take the next object
MatchSentence_2:
  OR $01
  RET                     ; NZ

; Find the objects the noun phrases of a sentence mean
;
; The noun matcher of a command. NextNoun1 returns the next candidate that fits
; the first noun phrase and that the verb lets through (NZ, the object in
; FirstObject; Z when the candidates are used up). When the command takes a
; second noun (NeedSecondNoun) a candidate is kept only if NextNoun2 finds a
; second-noun candidate that the whole command allows with it (StartNounScan2
; starts that scan); otherwise the candidate is kept when the check RunCheck
; passes with it alone. Kept first candidates are counted in RecWork3 ($7940),
; the last one in RecWork7 ($7956). When the candidates are used up, exactly
; one must have been kept: it becomes FirstObject. The second noun is then
; settled the same way: kept candidates counted in $7941, the last one in
; RecWork8 ($7957), and exactly one goes to SecondObject.
;
; With ALL typed (RecWork5 is 1) the first kept candidate is returned at once.
; The scan position (RecPtr1) is not cleared by ResetRecWork, so the next call
; goes on with the next object. No candidate, or more than one, gives NZ, and
; the caller (MatchSentence) hands over to ExplainNounFailure, which tells the
; player ("I see nothing to ...", or asks what is meant).
;
; Hardware: none.
;
;   RecBuf1 Words of the first noun phrase (RecBuf2 for the second)
; O:F Z when the objects are found (FirstObject, SecondObject), NZ when they
;     are not
ResolveNouns:
  CALL NextNoun1          ; next candidate for the first noun: NZ found
  JR NZ,ResolveNouns_0
  LD A,(RecWork3)         ; none left: how many were accepted?
  CP $01
  RET NZ                  ; not exactly one: failure
  LD A,(RecWork7)         ; the one accepted object
  LD (FirstObject),A      ; FirstObject
  CALL StartNounScan2     ; StartNounScan2
  CALL NeedSecondNoun     ; NeedSecondNoun
  JR NZ,ResolveNouns_Second ; yes: pick the second
  RET                     ; no: done (Z)
ResolveNouns_0:
  LD HL,RecWork2          ; RecWork2: candidates seen for the first noun
  INC (HL)
  CALL NeedSecondNoun     ; NeedSecondNoun
  JR Z,ResolveNouns_1     ; no: test the command with this candidate
  CALL StartNounScan2     ; StartNounScan2
  CALL NextNoun2          ; a candidate for the second noun?
ResolveNouns_Accept:
  JR Z,ResolveNouns       ; none (or the command was refused): the next first
                          ; candidate
  LD A,(RecWork5)         ; RecWork5: ALL?
  DEC A
  RET Z                   ; ALL: this one, now (Z)
  LD A,(FirstObject)      ; count this candidate
  LD (RecWork7),A
  LD HL,RecWork3
  INC (HL)
  JR ResolveNouns
ResolveNouns_1:
  CALL RunCheck           ; RunCheck: Z when refused
  JR ResolveNouns_Accept
ResolveNouns_Second:
  CALL NextNoun2          ; next candidate for the second noun: NZ found
  JR NZ,ResolveNouns_2
  LD A,(RecWork3+$0001)   ; none left: how many?
  CP $01
  RET NZ                  ; not exactly one: failure
  LD A,(RecWork8)
  LD (SecondObject),A     ; SecondObject
  RET                     ; Z: done
ResolveNouns_2:
  LD A,(SecondObject)     ; count this candidate
  LD (RecWork8),A
  LD HL,RecWork3+$0001
  INC (HL)
  JR ResolveNouns_Second

; Test whether EXCEPT removes the current object
;
; Used while ALL is processed (MatchSentence). Walks the EXCEPT records, those
; with RECF_EXCEPT set, that follow the record at IY (lower addresses). For
; each, FindNextNamedObject lists the objects its noun phrase (REC_PHRASE_A)
; can mean; if one of them is FirstObject ($B6E8) the object is excluded. IY is
; kept; IX is not.
;
;   IY Current (main) phrase record
; O:F NZ when FirstObject is named after EXCEPT, Z when it is not
; O:IX Destroyed (the table walked by FindNextNamedObject)
IsExcluded:
  PUSH IY
  PUSH DE
  PUSH HL
IsExcluded_Record:
  LD DE,-PARSED_RECORD_SIZE ; next newer record
  ADD IY,DE
  BIT RECF_EXCEPT,(IY+1)  ; an EXCEPT record?
  JR Z,IsExcluded_0       ; no: not excluded
  LD IX,ObjectTable-$0003 ; ObjectTable-3, walked by FindNextNamedObject
IsExcluded_Object:
  PUSH IY
  POP HL
  LD DE,REC_PHRASE_A      ; its noun phrase
  ADD HL,DE
  CALL FindNextNamedObject ; A = id of the next object that phrase can mean
  CP END_MARK             ; no more: next record
  JR Z,IsExcluded_Record
  LD HL,FirstObject       ; FirstObject
  CP (HL)
  JR NZ,IsExcluded_Object
  OR $01                  ; NZ: excluded
IsExcluded_0:
  POP HL
  POP DE
  POP IY
  RET

; Start the candidate scan for the first noun
;
; Sets RecPtr1 ($794E), the position from which NextNoun1 goes through the
; candidates for the first noun phrase. The class of the noun is bits 2-3 of
; the command flags StateB71E ($B71E) (PickScanStart turns it into the start of
; the object table). When Noun1Kind ($B6FE) is not 0 the noun is a place, and
; the scan starts at the exits of the actor's location instead
; (SeekActorExits). Does nothing while VerbAllFlag is not 0 (ALL was typed: the
; nouns are then taken one by one by other code); StartNounScan1_Always skips
; that test (used by TestActorCommand).
;
; O:IX The start position, also stored in RecPtr1
StartNounScan1:
  LD A,(VerbAllFlag)      ; VerbAllFlag: ALL typed
  AND A
  RET NZ
; This entry point is used by the routine at TestActorCommand.
StartNounScan1_Always:
  LD A,(StateB71E)        ; StateB71E
  RRCA
  RRCA                    ; noun 1 class, bits 2-3
  CALL PickScanStart      ; PickScanStart
  LD A,(Noun1Kind)        ; Noun1Kind
  AND A
  CALL NZ,SeekActorExits  ; a place: SeekActorExits
  LD (RecPtr1),IX         ; RecPtr1
  RET

; Start the candidate scan for the second noun
;
; The same as StartNounScan1_Always for the second noun phrase: the class is
; bits 0-1 of StateB71E ($B71E), Noun2Kind ($B6FF) tells a place from an
; object, and the start position goes to RecPtr2 ($7950) for NextNoun2.
;
; O:IX The start position, also stored in RecPtr2
StartNounScan2:
  LD A,(StateB71E)        ; StateB71E: noun 2 class, bits 0-1
  CALL PickScanStart      ; PickScanStart
  LD A,(Noun2Kind)        ; Noun2Kind
  AND A
  CALL NZ,SeekActorExits  ; a place: SeekActorExits
  LD (RecPtr2),IX         ; RecPtr2
  RET

; Choose where an object scan starts
;
; Sets IX to the entry of the object table (ObjectTable) in front of the first
; one a scan is to look at, because NextObject steps IX on by 3 before it
; reads. A noun class of 0 starts at object 1 (the player's own entry is
; skipped); any other class starts at the player (id 0).
;
;   A Noun class; only bits 0-1 are used (from the command flags $B71E)
; O:IX Scan start: ObjectTable for class 0, ObjectTable-3 otherwise
PickScanStart:
  LD IX,ObjectTable
  AND $03
  RET Z
  LD IX,ObjectTable-$0003
  RET

; Decide whether the second noun phrase must be matched next
;
; Z (no) when bit 2 of the command flags StateB71D ($B71D) is clear. NZ (yes)
; when the typed sentence has a second noun phrase (bit 0 of RecWork1, $793E).
; Otherwise bit 1 of $B71D decides: set gives Z, clear gives NZ. Used by the
; noun matching loop ResolveNouns and by ExplainNounFailure. The meaning of the
; bits is inferred from these tests only (see finding on the command flags).
;
; O:F Z when the second noun phrase is not to be matched
; O:A Destroyed
NeedSecondNoun:
  LD A,(StateB71D)
  BIT 2,A
  RET Z
  LD HL,RecWork1
  BIT 0,(HL)
  RET NZ
  BIT 1,A
  JR NZ,NeedSecondNoun_0
  OR $01
  RET
NeedSecondNoun_0:
  XOR A
  RET

; Run the command check and fetch its result
;
; Calls DispatchCommand, the check of the command (with ActionPerform, $B6FA,
; at 0 the verb handlers only check and ActionAllowed is set; see
; CommitOrAbort), then reads ActionAllowed ($B6FB). CommitOrAbort sets it to 1
; when a check passes and PrintMessage sets it to 0 when a message is printed
; in a check, so 0 here means the command is refused (finding F10: the name is
; inverted).
;
; O:A ActionAllowed ($B6FB)
; O:F Z when it is 0
RunCheck:
  CALL DispatchCommand
  LD A,(ActionAllowed)
  AND A
  RET

; Test whether a character can do a command
;
; Used by the NPC script interpreter (RunActorCommand) for a command it wants a
; character to carry out: CommandId, FirstObject and SecondObject are already
; set (Noun1Kind and Noun2Kind say whether a noun is an object or a place; the
; acting character is Subject). The routine does what the sentence matcher does
; for a typed sentence, but without a typed sentence: it fetches the command's
; table record (CommandRecordAddr), packs and unpacks its flags
; (PackCommandFlags, UnpackFlags) and puts the name phrases of the two objects
; into RecBuf1 and RecBuf2 (CopyNamePhrase) so that the noun matcher recognises
; exactly them. ActionPerform is 0 for the test.
;
; A command without nouns is checked at once (DispatchCommand; the result is
; ActionAllowed). A command with nouns goes through ResolveNouns with RecWork5
; = 1, which confirms that the objects fit the command. ActionPerform is left 1
; on return, so the caller can carry the command out. All registers and the
; scan position RecPtr1 ($794E) are kept.
;
; Hardware: none (the check may print a message when it refuses).
;
;   CommandId The command (1-59)
;   FirstObject First object or NO_OBJECT
;   SecondObject Second object or NO_OBJECT
;   Noun1Kind 0 an object, else a place (Noun2Kind for the second)
; O:F NZ when the command can be done, Z when it is refused
TestActorCommand:
  PUSH HL
  PUSH IY
  PUSH IX
  PUSH DE
  PUSH BC
  LD HL,(RecPtr1)         ; RecPtr1
  PUSH HL
  LD A,(CommandId)        ; CommandId
  CALL CommandRecordAddr  ; CommandRecordAddr
  PUSH HL
  POP IX                  ; IX: the command's record
  CALL ResetRecWork       ; ResetRecWork
  CALL PackCommandFlags   ; PackCommandFlags
  CALL UnpackFlags        ; UnpackFlags
  LD A,(FirstObject)      ; FirstObject
  LD B,A
  LD A,(Noun1Kind)        ; Noun1Kind
  LD DE,RecBuf1           ; RecBuf1
  CALL CopyNamePhrase     ; CopyNamePhrase
  LD A,(SecondObject)     ; SecondObject
  LD B,A
  LD A,(Noun2Kind)        ; Noun2Kind
  LD DE,RecBuf2           ; RecBuf2
  CALL CopyNamePhrase
  CALL StartNounScan1_Always ; start the scan for the first noun (ignores
                             ; VerbAllFlag)
  XOR A
  LD (ActionPerform),A    ; ActionPerform: test pass
  LD A,(StateB71D)        ; StateB71D: command flags
  AND $0C                 ; does the command take nouns?
  JR NZ,TestActorCommand_0
  CALL DispatchCommand    ; no: check it directly
  LD A,(ActionAllowed)    ; ActionAllowed
  AND A
  JR TestActorCommand_2
TestActorCommand_0:
  LD A,$01
  LD (RecWork5),A         ; RecWork5: take the first match
  CALL ResolveNouns       ; ResolveNouns
  JR Z,TestActorCommand_1
  XOR A                   ; no match: Z
  JR TestActorCommand_2
TestActorCommand_1:
  OR $01                  ; matched: NZ
TestActorCommand_2:
  LD A,$01
  LD (ActionPerform),A    ; ActionPerform: the caller carries it out
  POP HL
  LD (RecPtr1),HL         ; RecPtr1 as it was
  POP BC
  POP DE
  POP IX
  POP IY
  POP HL
  RET

; Copy the name phrase of an object or place into a record buffer
;
; Copies the six bytes of the name phrase (noun and two adjectives) of object
; B, or of place B when the kind in A is not 0, to DE. B = $FF means no noun
; and nothing is copied. Called by TestActorCommand for RecBuf1 ($7942) and
; RecBuf2 ($7948) so that a command given to a character carries its noun
; phrases.
;
;   A Noun kind (Noun1Kind or Noun2Kind): 0 object, else location
;   B Object or location id, $FF for none
;   DE Where to copy to
; O:BC 0 (when copied)
; O:DE After the copy (when copied)
; O:HL After the name phrase (when copied)
CopyNamePhrase:
  INC B
  RET Z                   ; $FF: none
  DEC B
  AND A
  LD A,B
  JR Z,CopyNamePhrase_0
  CALL LocationNamePtr    ; LocationNamePtr
  JR CopyNamePhrase_1
CopyNamePhrase_0:
  CALL ObjectNamePtr      ; ObjectNamePtr
CopyNamePhrase_1:
  LD BC,PHRASE_WORDS_SIZE
  LDIR
  RET

; Unpack the command flags into the matcher's variables
;
; StateB71D and StateB71E ($B71D, $B71E) were built by PackCommandFlags from
; the four flag nibbles of the command record. Copies single bits into separate
; variables:
;
; $B711 = $B71E & $40 (read by DispatchCommand: with no light the command is
; refused with "I see nothing here.") $B70F = $B71D & 1 (AllActive;
; FindNextNamedObject then accepts a name match without the further test
; ActorCanReach) Noun1Kind ($B6FE) = 1 if bit 7 of $B71D, else 0 Noun2Kind
; ($B6FF) = 1 if bit 6 of $B71D, else 0
;
; A noun kind of 1 makes NextNoun1 and NextNoun2 look the noun up among the
; places reachable by an exit (FindExitByName) instead of among objects
; (FindNextNamedObject).
;
; O:A Noun2Kind
; O:B StateB71D
UnpackFlags:
  LD A,(StateB71E)
  AND $40                 ; bit 6 of the second flag byte
  LD (NeedsLight),A       ; B711: needs light
  LD A,(StateB71D)
  LD B,A
  AND $01
  LD (AllActive),A        ; B70F: bit 0 of the first flag byte
  LD A,B
  AND $80
  JR Z,UnpackFlags_0      ; Noun1Kind: bit 7 -> 1
  LD A,$01
UnpackFlags_0:
  LD (Noun1Kind),A
  LD A,B
  AND $40
  JR Z,UnpackFlags_1      ; Noun2Kind: bit 6 -> 1
  LD A,$01
UnpackFlags_1:
  LD (Noun2Kind),A
  RET

; Find the command table record that matches a parsed phrase
;
; Takes the phrase record at IY (first command word, then up to two preposition
; words in its two phrase blocks) and looks for a record of the command table
; that has the same verb and prepositions (MatchCommandRecord, which also
; accepts the two prepositions swapped).
;
; First the ALL flag (bit 7 of the first word) is kept in RecWork4 ($7952), the
; verb goes to RecWord1 ($7958), and the (up to) two prepositions of the record
; are collected from both blocks in the order first block, second block
; (CollectWord) into RecWord2 and RecWord3 ($795A-$795D). Then the command
; table is walked in 8-byte steps up to its zero word.
;
; If a record matches, SplitNounPhrases splits the noun phrases of the phrase
; for it and the routine returns NZ with IX at the record.
;
; If none matches and the verb matched alone (PhraseMatched, $B6DF, set by
; MatchCommandRecord) the verb is used with the wrong prepositions and
; ReportUnknownVerb reports that. Otherwise the word is a verb that has no
; entry in the command table, and the game prints message $ADA3 ("You {WORD}."
; and "Time passes...", the word being the verb) with ActionPerform set. For a
; line typed by the player the routine then drops both return addresses and
; goes on at EndOfTurn, the end of the turn, so "sing" makes time pass. For the
; text of an order (SAY TO) it returns Z.
;
; Hardware: none.
;
;   IY Parsed phrase record
; O:F NZ when a command record matched, Z when none did
; O:IX Matching command table record
MatchCommand:
  PUSH IY
  LD L,(IY+$00)           ; first command word
  LD H,(IY+$01)
  LD A,H
  AND $80                 ; the ALL flag (RECF_ALL)
  LD (RecWork4),A         ; RecWork4
  RES 7,H
  LD (RecWord1),HL        ; RecWord1: the verb word
  LD HL,RecWord2          ; RecWord2
  PUSH HL
  LD B,$04
  CALL ClearBytes         ; ClearBytes: RecWord2 and RecWord3 empty
  POP HL
  LD B,$02                ; room for two words
  LD E,REC_BLOCK_A        ; first preposition of the first block
  CALL CollectWord        ; CollectWord
  LD E,REC_BLOCK_B        ; first preposition of the second block
  CALL CollectWord
  LD E,REC_BLOCK_A+$02    ; second preposition of the first block
  CALL CollectWord
  LD E,REC_BLOCK_B+$02    ; second preposition of the second block
  CALL CollectWord
  XOR A
  LD (PhraseMatched),A    ; PhraseMatched = 0
  LD HL,RecWord1          ; RecWord1: verb and two prepositions
  LD DE,COMMAND_RECORD_SIZE
  LD IX,CommandTable      ; CommandTable
MatchCommand_Next:
  PUSH IX
  POP IY
  CALL MatchCommandRecord ; MatchCommandRecord
  JR Z,MatchCommand_Found ; found
  ADD IX,DE
  LD A,(IX+$01)
  OR (IX+$00)
  JR NZ,MatchCommand_Next ; until the zero word that ends the table
  POP IY
  LD A,(PhraseMatched)    ; PhraseMatched
  AND A
  JP NZ,ReportUnknownVerb ; the verb is known but not with these words
  LD HL,(RecWord1)        ; the verb word, for {WORD}
  PUSH HL
  LD HL,MsgTimePasses     ; "You {WORD}." "Time passes..."
  XOR A
  LD (RawOutputFlag),A    ; RawOutputFlag: the story window
  LD (VerbAllFlag),A      ; VerbAllFlag = 0
  LD A,$01
  LD (ActionPerform),A    ; ActionPerform = 1
  CALL PrintParserMessage ; PrintParserMessage
  LD A,(InputFromOrder)   ; InputFromOrder
  DEC A
  RET Z                   ; an order: Z, no match
  POP HL                  ; the typed line: end the turn here. Drop the return
  POP HL                  ; addresses of MatchSentence and of its caller
  JP EndOfTurn
MatchCommand_Found:
  POP IY
  CALL SplitNounPhrases   ; SplitNounPhrases (A = 1 if the prepositions were
                          ; swapped)
  OR $01                  ; NZ
  RET

; Split a matched phrase into its two noun phrases
;
; Called by MatchCommand when a command record has matched the parsed phrase.
; First, if A is not 0, swaps the two words collected in $795A and $795C. Then
; PackCommandFlags builds the flags $B71D/$B71E from the command record in IX.
;
; The parsed record (24 bytes, IY) holds two noun phrases of three words, at
; +$08 and +$12. Bit 5 of $B71D decides which is noun phrase 1: clear gives
; +$12 for phrase 1 and +$08 for phrase 2, set the other way round. That bit is
; flipped when the first collected word ($795A) equals the word at +$0E or +$10
; of the record; with no collected word, bit 5 of $B71E is taken and flipped.
; The two offsets go to RecWork6/7 ($7954/$7955). Phrase 1 is copied to RecBuf1
; ($7942) with bit 0 of RecWork ($793D) set if it has any word; it is copied on
; to PhraseBuffer ($B6E0). Phrase 2 goes to RecBuf2 ($7948), flag in RecWork1
; ($793E).
;
; The part from $7C91 is a routine of its own (copy one phrase): A offset in
; the record, IY the record, DE the destination, HL the flag byte.
;
;   A Not 0: the command matched with its two words in the other order
;     (MatchCommandRecord)
;   IX Command record that matched
;   IY Parsed phrase record
; O:A Offset of noun phrase 2 in the record
SplitNounPhrases:
  AND A                   ; A not 0: swap the two collected words
  JR Z,SplitNounPhrases_Flags
  LD HL,(RecWord2)
  LD DE,(RecWord3)
  LD (RecWord2),DE
  LD (RecWord3),HL
SplitNounPhrases_Flags:
  CALL PackCommandFlags   ; build $B71D/$B71E from IX
  LD HL,RecWord2
  LD A,(HL)
  INC HL
  OR (HL)
  JR NZ,SplitNounPhrases_0 ; no word collected: use $B71E
  LD A,(StateB71E)
  JR SplitNounPhrases_3
SplitNounPhrases_0:
  DEC HL
  LD A,(HL)
  CP (IY+$0E)
  JR NZ,SplitNounPhrases_1
  INC HL
  LD A,(HL)
  CP (IY+$0F)
  JR Z,SplitNounPhrases_2
  DEC HL
SplitNounPhrases_1:
  LD A,(HL)
  CP (IY+$10)
  JR NZ,SplitNounPhrases_2
  INC HL
  LD A,(HL)
  CP (IY+$11)
SplitNounPhrases_2:
  LD A,(StateB71D)
  JR NZ,SplitNounPhrases_4
SplitNounPhrases_3:
  XOR $20                 ; flip bit 5
SplitNounPhrases_4:
  BIT 5,A
  LD BC,REC_PHRASE_B*$0100+REC_PHRASE_A ; bit 5 clear: phrase 1 at +$12, 2 at
                                        ; +$08
  JR Z,SplitNounPhrases_5
  LD BC,REC_PHRASE_A*$0100+REC_PHRASE_B
SplitNounPhrases_5:
  LD HL,RecWork6
  LD (HL),B               ; RecWork6: offset of phrase 1
  INC HL
  LD (HL),C               ; RecWork7: offset of phrase 2
  LD A,B
  LD DE,RecBuf1
  LD HL,RecWork
  CALL CopyPhrase         ; phrase 1 to RecBuf1
  LD A,C
  LD HL,RecBuf1
  LD DE,PhraseBuffer      ; and to PhraseBuffer
  LD BC,PHRASE_WORDS_SIZE
  LDIR
  LD DE,RecBuf2           ; phrase 2 to RecBuf2
  LD HL,RecWork1

; Copy a noun phrase out of the parsed record
CopyPhrase:
  PUSH BC                 ; copy a phrase: A = offset in the record
  LD C,A
  LD B,$00
  PUSH HL
  PUSH IY
  POP HL
  ADD HL,BC
  LD BC,PHRASE_WORDS_SIZE
  LDIR
  XOR A
  LD B,PHRASE_WORDS_SIZE
CopyPhrase_0:
  DEC HL                  ; OR the six bytes copied
  OR (HL)
  DJNZ CopyPhrase_0
  POP HL
  POP BC
  RET Z                   ; no words: leave the flag clear
  SET 0,(HL)              ; phrase has words
  RET

; Collect one word of the parsed record
;
; Copies the word at offset E of the parsed record to the word list at HL. If
; the word is not zero, a slot is used up: B is decremented and HL moves on to
; the next slot. A zero word is stored but not counted. Does nothing when B is
; 0. MatchCommand calls it four times to collect up to two words of the phrase
; into $795A-$795D.
;
;   B Free slots in the list
;   E Offset of the word in the parsed record
;   HL Where to store the word
;   IY Parsed phrase record
; O:B B-1 if a word was stored
; O:HL Next slot if a word was stored
; O:F Z when the word was zero or B was 0
CollectWord:
  XOR A
  CP B
  RET Z
  LD D,$00
  PUSH IY
  ADD IY,DE
  LD A,(IY+$00)
  LD (HL),A
  INC HL
  LD A,(IY+$01)
  LD (HL),A
  DEC HL
  OR (IY+$00)
  POP IY
  RET Z
  DEC B
  INC HL
  INC HL
  RET

; Jump to the routine in IY
;
; A trampoline: the noun lookup NextNoun1Match and NextNoun2Match set IY to
; FindNextNamedObject (look among objects) or FindExitByName (look among exits)
; and call this. The registers pass through to that routine, which returns to
; the caller of this one.
;
; IY Address of the routine to run
; HL Noun phrase words (RecBuf1 or RecBuf2) for that routine
CallIY:
  JP (IY)

; Next candidate for the first noun phrase
;
; One step of the search for what the first typed noun phrase (RecBuf1) means.
; The search position is the cursor RecPtr1 ($794E), which StartNounScan1 sets
; before the first call; every call goes on from where the last one stopped.
;
; If Noun1Kind is NOUN_PLACE the candidates are the destinations of the exits
; of the actor's location whose names fit the phrase (FindExitByName).
; Otherwise they are the objects whose names fit (FindNextNamedObject) and that
; are of the kind the command takes: AllMode ($B710) is set from bits 2-3 of
; StateB71E (0 things, 1 living characters, 2 anything). A candidate is
; accepted when the check of the command lets it through (NextNoun1Match); the
; accepted one is left in FirstObject.
;
; O:A Id of the accepted object or place, $FF when there are no more O:F Z when
; there are no more O:FirstObject The accepted candidate O:HL Destroyed (IY is
; preserved)
NextNoun1:
  PUSH IY
  LD IX,(RecPtr1)         ; RecPtr1: the cursor
  LD A,(Noun1Kind)        ; Noun1Kind
  DEC A
  JR Z,NextNoun1Place     ; a place
  LD IY,FindNextNamedObject ; FindNextNamedObject
  LD A,(StateB71E)        ; StateB71E
  RRCA
  RRCA
  AND $03                 ; noun 1 kind: bits 2-3
  LD (AllMode),A          ; AllMode
  CALL NextNoun1Match     ; NextNoun1Match
  CP $FF
NextNoun1_0:
  LD (RecPtr1),IX         ; RecPtr1
  POP IY
  RET
NextNoun1Place:
  LD IY,FindExitByName    ; FindExitByName
  CALL NextNoun1Match     ; NextNoun1Match
  CP $FF
  JR NextNoun1_0

; Find the next object that fits noun phrase 1 and passes the check
;
; Used by NextNoun1 to step through the candidates for the first noun phrase of
; a command. Each pass asks the lookup routine in IY (through CallIY, with HL =
; RecBuf1, the phrase's words) for the next object, keeps it in FirstObject
; ($B6E8), sets bit 1 of RecWork ($793D: a candidate was found for phrase 1)
; and asks CheckVerbApplies whether that object lets the command through (it
; leaves the answer in ActionAllowed). A refused candidate is dropped and the
; next one is fetched, so the loop ends on the first accepted object or when
; the lookup is exhausted.
;
;   IY Lookup routine: FindNextNamedObject (objects around) or FindExitByName
;      (exits), set by NextNoun1
;   IX Cursor of the lookup, kept by it between calls
; O:A $FF when no candidate is left, otherwise 1 (ActionAllowed)
; O:F Z when no candidate is left
; O:FirstObject The accepted object
NextNoun1Match:
  LD HL,RecBuf1
  CALL CallIY             ; next candidate for phrase 1
  CP $FF                  ; $FF: none left
  RET Z
  LD (FirstObject),A      ; FirstObject
  LD HL,RecWork
  SET 1,(HL)              ; RecWork bit 1: phrase 1 has a candidate
  CALL CheckVerbApplies   ; does the verb allow it? (ActionAllowed)
  LD A,(ActionAllowed)
  AND A
  JR Z,NextNoun1Match     ; refused: try the next one
  RET

; Next candidate for the second noun phrase
;
; The same step as NextNoun1 for the second typed noun phrase (RecBuf2), with
; the cursor RecPtr2 ($7950) that StartNounScan2 sets. A place (Noun2Kind
; NOUN_PLACE) is looked up among the exits (FindExitByName), anything else
; among the objects (FindNextNamedObject) of the kind in bits 0-1 of StateB71E
; (AllMode). A candidate is accepted when the whole command, both objects, is
; allowed (NextNoun2Match); it is left in SecondObject.
;
; AllActive ($B70F) is 0 during the search, so a second object must always be
; within the actor's reach (ActorCanReach); afterwards it is set again to bit 0
; of StateB71D, its value for the first noun.
;
; O:A Id of the accepted object or place, $FF when there are no more O:F Z when
; there are no more O:SecondObject The accepted candidate O:HL Destroyed (IY is
; preserved)
NextNoun2:
  XOR A
  LD (AllActive),A        ; AllActive 0
  PUSH IY
  LD IX,(RecPtr2)         ; RecPtr2: the cursor
  LD A,(Noun2Kind)        ; Noun2Kind
  DEC A
  JR Z,NextNoun2Place     ; a place
  LD IY,FindNextNamedObject ; FindNextNamedObject
  LD A,(StateB71E)        ; StateB71E
  AND $03                 ; noun 2 kind: bits 0-1
  LD (AllMode),A          ; AllMode
  CALL NextNoun2Match     ; NextNoun2Match
  CP $FF
NextNoun2_0:
  LD (RecPtr2),IX         ; RecPtr2
  POP IY
  PUSH AF
  LD A,(StateB71D)        ; StateB71D
  AND $01
  LD (AllActive),A        ; AllActive: bit 0 again
  POP AF
  RET
NextNoun2Place:
  LD IY,FindExitByName    ; FindExitByName
  CALL NextNoun2Match     ; NextNoun2Match
  CP $FF
  JR NextNoun2_0

; Find the next object that fits noun phrase 2 and passes the check
;
; Like NextNoun1Match for the second noun phrase of a command: asks the lookup
; routine in IY (through CallIY, HL = RecBuf2) for the next candidate, keeps it
; in SecondObject ($B6E9), sets bit 1 of RecWork1 ($793E) and runs the whole
; command check with RunCheck, which needs both objects. The loop repeats while
; the check refuses (Z) and ends on the first accepted object or when the
; lookup is exhausted. Used by NextNoun2.
;
;   IY Lookup routine: FindNextNamedObject (objects around) or FindExitByName
;      (exits), set by NextNoun2
;   IX Cursor of the lookup, kept by it between calls
; O:A $FF when no candidate is left, otherwise ActionAllowed (not 0)
; O:F Z when no candidate is left
; O:SecondObject The accepted object
NextNoun2Match:
  LD HL,RecBuf2
  CALL CallIY             ; next candidate for phrase 2
  CP $FF                  ; $FF: none left
  RET Z
  LD (SecondObject),A     ; SecondObject
  LD HL,RecWork1
  SET 1,(HL)              ; RecWork1 bit 1: phrase 2 has a candidate
  CALL RunCheck           ; full check of the command
  JR Z,NextNoun2Match     ; refused: try the next one
  RET

; Switch to performing and printing mode
;
; Sets ActionPerform ($B6FA) and RawOutputFlag ($B701) to 1. The first makes
; the handlers carry the command out and PrintMessage leave ActionAllowed
; alone; the second is the flag that makes the message printer take its second
; article table (see notes). Done before printing a question or an error
; message.
;
; O:A 1
SetPerformMode:
  LD A,$01
  LD (ActionPerform),A
  LD (RawOutputFlag),A
  RET

; Save the parsed record for the player's reply
;
; Stores A in AwaitingAnswer ($B71A) and copies the 24-byte parsed record at IY
; to $B9C8, the top record of the phrase stack. RunSentences tests
; AwaitingAnswer first and when it is not 0 goes on with the reply; the callers
; pass the offset of the noun phrase (RecWork6/7) the question is about ("Which
; ...?", "... what?").
;
; A Offset of the noun phrase being asked about, from RecWork6/7
; IY Parsed phrase record to keep
SaveParsedRecord:
  LD (AwaitingAnswer),A
  PUSH IY
  POP HL
  LD DE,PhraseRecord0     ; top of the phrase stack
  LD BC,PARSED_RECORD_SIZE
  LDIR
  RET

; Ask "Which ...?" about noun phrase 1
;
; Several objects matched the first noun phrase and ALL was not typed. Takes
; the first word of the phrase (RecBuf1) and the offset RecWork6, saves the
; record with SaveParsedRecord, then prints message $ADCC ("Which {WORD} ?")
; with the word pushed for its {WORD} code. The second entry takes A and HL
; from its caller (HL is pushed as the word; ExplainNoun2Failure passes the
; address $7948 there, not the word; see the open question). Continues in
; PrintReplyFail.
;
; O:A 0 (from PrintReplyFail)
; O:F Z
AskWhichNoun1:
  LD A,(RecWork6)         ; offset of phrase 1
  LD HL,(RecBuf1)         ; its first word
; This entry point is used by the routine at ExplainNoun2Failure.
AskWhich:
  PUSH HL                 ; the word for the message
  CALL SaveParsedRecord   ; save the record
  LD HL,MsgWhich          ; "Which {WORD} ?"

; Print a parser reply and return failure
;
; The common end of the parser's questions and complaints: switches to
; performing and printing mode with SetPerformMode, prints the message at HL
; (with the words the caller has pushed on the stack for its {WORD} codes) and
; returns 0 with Z set, which the callers pass on as "the command was not
; carried out".
;
;   HL Message to print: "Which {WORD} ?", "I do not see {THING} here", "I see
;      nothing to ...", "... what ?"
; O:A 0
; O:F Z
PrintReplyFail:
  CALL SetPerformMode     ; ActionPerform = 1, RawOutputFlag = 1
  CALL PrintParserMessage ; print the message at HL
  XOR A
  RET

; Explain why the second noun phrase gave no single object
;
; Reached from ExplainNounFailure when the first noun phrase is settled (one
; object) and the second is not. RecWork1 ($793E) says what the matcher saw of
; the second phrase: bit 0 the player typed words for it, bit 1 some object or
; place fitted them; $7941 (RecWork3+1) counts the candidates the command
; accepted. The cases:
;
; 1. No words typed, a second noun is needed: ReportNoSecondNoun asks "... what
; ?" or says there is nothing to use.
;
; 2. Words typed, nothing fitted them: FindNounElsewhere looks for a place or
; any object of that name, and else says "I do not see ... here".
;
; 3. Fitting candidates, none accepted: PerformRefusal runs the command in
; perform mode so that its own refusal is printed.
;
; 4. Several accepted (the player must choose): the record is saved and "Which
; ... ?" is asked (AskWhich). This case is odd: the code loads A twice and puts
; the address RecBuf2 ($7948) on the stack where AskWhichNoun1 puts the first
; word of the phrase, so the question prints a stray word ("Which ting ?") and
; AwaitingAnswer gets the low byte of that word instead of the offset of the
; phrase. Not executed with the inputs in re/maps; seen by calling this routine
; with RecWork1 = 3 and $7941 = 2.
;
; Like ExplainNounFailure it ends by returning to the caller of MatchSentence
; or jumping to the end of the turn code at RunSentences_More.
ExplainNoun2Failure:
  LD HL,RecWork1          ; RecWork1
  BIT 0,(HL)              ; words typed for phrase 2?
  JP Z,ReportNoSecondNoun ; ReportNoSecondNoun
  BIT 1,(HL)              ; a candidate fitted?
  LD HL,RecBuf2           ; RecBuf2
  LD DE,SecondObject      ; SecondObject
  LD BC,Noun2Kind         ; Noun2Kind
  JR Z,FindNounElsewhere  ; FindNounElsewhere
  LD A,(RecWork3+$0001)   ; candidates accepted
  AND A
  JP Z,PerformRefusal     ; none: PerformRefusal
  LD A,(RecWork6+$0001)   ; (this load is overwritten)
  LD A,(RecBuf2)
  JR AskWhich             ; AskWhich (HL = $7948 is pushed as the word)

; Explain why the noun phrases did not give one object each
;
; Entered by a jump from MatchSentence when the search for the objects of a
; command (ResolveNouns) did not end with exactly one accepted object for each
; noun phrase. It prints a question or a complaint, or lets the command print
; its own refusal, and so takes the place of MatchSentence's return: the Z
; result with A 0 goes back to the caller of MatchSentence (RunSentences),
; which then has nothing to execute; the paths through PerformRefusal go on at
; RunSentences_More, the end of that record. The decisions, in order:
;
; 1. The words come from an order (InputFromOrder 1, SAY TO): return Z at once,
; silently.
;
; 2. ALL was typed (VerbAllFlag): the objects of ALL are used up. Silently go
; to the next record (NextRecord).
;
; 3. Exactly one accepted object for the first noun phrase (RecWork3 $7940 is
; 1): the second phrase is the trouble (ExplainNoun2Failure).
;
; 4. No words typed for the first phrase: ReportNoNoun1.
;
; 5. Words typed and no object or place fits them: FindNounElsewhere.
;
; 6. Candidates found (RecWork2 $793F counts those that passed the check of the
; command for one object): none passed, so PerformRefusal prints the refusal;
; one passed and a second noun is still needed, ExplainNoun2Failure; one passed
; and the full check refused it, PerformRefusal; several passed, so ask "Which
; {word} ?" (AskWhichNoun1).
;
; Bits 0 and 1 of RecWork ($793D) say that the first phrase had words and that
; some object fitted them.
ExplainNounFailure:
  LD A,(InputFromOrder)   ; InputFromOrder
  DEC A
  RET Z                   ; an order: nothing is said
  LD A,(VerbAllFlag)      ; VerbAllFlag
  AND A
  JR Z,ExplainNounFailure_0
  POP HL                  ; ALL: drop the return address
  JP NextRecord           ; next record
ExplainNounFailure_0:
  LD A,(RecWork3)         ; RecWork3: accepted objects for phrase 1
  CP $01
  JR Z,ExplainNoun2Failure ; ExplainNoun2Failure
  LD HL,RecWork           ; RecWork
  BIT 0,(HL)              ; words typed for phrase 1?
  JP Z,ReportNoNoun1      ; ReportNoNoun1
  BIT 1,(HL)              ; an object fitted?
  LD HL,RecBuf1           ; RecBuf1
  LD DE,FirstObject       ; FirstObject
  LD BC,Noun1Kind         ; Noun1Kind
  JR Z,FindNounElsewhere  ; FindNounElsewhere
  LD A,(RecWork2)         ; RecWork2: candidates that passed the check
  AND A
  JR Z,PerformRefusal     ; none: PerformRefusal
  DEC A
  JR NZ,AskWhichNoun1     ; several: AskWhichNoun1
  CALL NeedSecondNoun     ; NeedSecondNoun
  JR NZ,ExplainNoun2Failure ; ExplainNoun2Failure

; Run the verb handler again to print its refusal
;
; This entry point is used by the routines at RunSentences and
; ExplainNoun2Failure.
PerformRefusal:
  CALL SetPerformMode     ; SetPerformMode
  CALL DispatchCommand    ; run the command again: its handler prints the
                          ; refusal
  JP RunSentences_More    ; end of the record

; Find a named object out of reach and say where it is
;
; Try a rejected noun phrase as a place or as any object.
;
; The words fitted no object of the kind the command takes. A noun phrase can
; still be a place of the exits of the actor's location ("take lonelands") or
; an object of another kind, such as a person for a verb that wants a thing
; ("eat Gandalf"). The routine looks for the words first among the exits, then
; among all the objects (AllMode ANY, within reach unless AllActive is set). If
; one is found it becomes the noun and the command is refused with "You cannot
; {verb} {noun}." (StartPerform with ActionAllowed 0, so the sentence
; PrintCommandSentence goes to the input window). If none is found the message
; "I do not see {THING} here" is printed, the address of the typed words being
; the {THING}.
;
; Entered from ExplainNoun2Failure as well.
;
; HL The typed noun phrase (RecBuf1 or RecBuf2) DE Variable to receive the
; found noun (FirstObject or SecondObject) BC Variable of the noun's kind
; (Noun1Kind or Noun2Kind), set here O:A 0 O:F Z
FindNounElsewhere:
  PUSH HL
  CALL SeekActorExits     ; SeekActorExits
  LD A,NOUN_PLACE
  LD (BC),A               ; the noun is a place
  CALL FindExitByName     ; FindExitByName
  CP END_MARK
  JR NZ,FindNounElsewhere_0 ; found
  POP HL
  LD A,ALL_MODE_ANY
  LD (AllMode),A          ; AllMode: any kind of object
  LD IX,ObjectTable-$0003
  XOR A
  LD (BC),A               ; the noun is an object
  PUSH HL                 ; kept for the message
  CALL FindNextNamedObject ; FindNextNamedObject
  CP END_MARK
  JR Z,FindNounElsewhere_1 ; nothing of that name
FindNounElsewhere_0:
  POP HL
  LD (DE),A               ; the noun
  JP StartPerform         ; StartPerform: "You cannot ..."
FindNounElsewhere_1:
  CALL SetPerformMode     ; SetPerformMode
  LD HL,MsgIDoNotSeeHere  ; "I do not see {THING} here"
  CALL PrintParserMessage
  XOR A
  RET

; Report that the first noun phrase names nothing here
;
; Explain a first noun phrase with no words.
;
; The player typed a verb with no noun ("take", "give"). The words the command
; record shows before and after the noun are pushed with the verb
; (PushWordsBefore) for the message. When no object was accepted ($7940 is 0)
; it prints "I see nothing to {verb} ..." ($ADE1). Otherwise the parsed record
; is saved (offset $7954, the first noun phrase) so that the next line answers,
; and "{verb} ... what ?" ($ADC4) is printed: "EXAMINE WHAT ?". Both end in
; PrintReplyFail.
;
; O:A 0 O:F Z
ReportNoNoun1:
  CALL PushWordsBefore    ; PushWordsBefore
  LD HL,(RecWord1)        ; RecWord1: the verb
  PUSH HL
  LD HL,MsgISeeNothing    ; "I see nothing to {WORD} {WORD} {WORD}"
  LD A,(RecWork3)         ; RecWork3
  AND A
  JP Z,PrintReplyFail     ; PrintReplyFail
  LD A,(RecWork6)         ; RecWork6: offset of phrase 1
  CALL SaveParsedRecord   ; SaveParsedRecord
  LD HL,MsgWhat3          ; "{WORD} {WORD} {WORD} what ?"
  JP PrintReplyFail

; Report or ask about a missing second noun phrase
;
; Reached from ExplainNoun2Failure when the command has no second noun phrase
; (bit 0 of RecWork1, $793E, clear). Pushes the words for the message: the
; command record's words that follow the noun (PushWordsAfter), a 0, the name
; of FirstObject (ObjectNamePtr), the words that precede the noun
; (PushWordsBefore) and the verb (RecWord1). Then, when RecWork3+1 ($7941) is 0
; (no object could serve), prints message $ADE7, "I see nothing to {verb}
; {word} {word} {THING} {word} {word} {word}" (seen: LOCK DOOR gives "I see
; nothing to lock the round green door with"). Otherwise saves the parsed
; record with SaveParsedRecord (offset RecWork7, $7955) so the player's next
; line answers it, and prints $ADC0, "{verb} {words} {THING} {words} what ?".
; Both end through PrintReplyFail.
;
; O:A 0
; O:F Z
ReportNoSecondNoun:
  CALL PushWordsAfter     ; words that follow the noun
  LD HL,$0000             ; a blank word
  PUSH HL
  LD A,(FirstObject)      ; FirstObject
  CALL ObjectNamePtr      ; HL = its name phrases
  PUSH HL
  CALL PushWordsBefore    ; words that precede the noun
  LD HL,(RecWord1)        ; RecWord1: the verb
  PUSH HL
  LD HL,MsgISeeNothing2   ; "I see nothing to ..."
  LD A,(RecWork3+$0001)   ; RecWork3+1
  AND A
  JP Z,PrintReplyFail     ; nothing could serve: just say so
  LD A,(RecWork6+$0001)   ; offset of phrase 2
  CALL SaveParsedRecord   ; keep the record for the reply
  LD HL,MsgWhat2          ; "... what ?"
  JP PrintReplyFail

; Push the command's words that follow the noun
;
; Same as PushWordsBefore but with the opposite test: a word of the command
; record is pushed when its "before the noun" flag is clear. Sets the two JR
; opcodes of PushWordsBefore to JR Z ($28) and continues there.
;
; O:stack Two words for the message printer's {WORD} codes, see PushWordsBefore
PushWordsAfter:
  LD A,$28                ; $28 = JR Z
  JR PushWords_SetTests

; Push the command's words that precede the noun
;
; The command record at (RecPtr3, $795E) may hold two extra words (+2 and +4,
; the prepositions, e.g. the "up" of "pick up"). A word is pushed when its flag
; says it comes before the noun: bit 5 of the high byte of the word at +2, bit
; 7 of (IX+7) for the word at +4; otherwise 0 is pushed. The test is
; self-modified: the entry at $7E7C stores JR NZ ($20) into the two JR opcodes
; SmcKeepWord4 and SmcKeepWord2, PushWordsAfter stores JR Z ($28) so that the
; other words are pushed.
;
; It does not return in the usual way: it swaps the words in under its own
; return address and jumps to it, so the caller finds the word of +2 on top of
; the stack, then the word of +4. The callers push one more word (the verb,
; RecWord1) and print a message such as $ADE1 ("I see nothing to {WORD} {WORD}
; {WORD}"), whose {WORD} codes take the three words from the stack.
;
; O:stack The word at +2 (or 0), then the word at +4 (or 0), under the return
;   address's place
PushWordsBefore:
  LD A,$20                ; $20 = JR NZ
; This entry point is used by the routine at PushWordsAfter.
PushWords_SetTests:
  LD (SmcKeepWord4),A     ; modify the JR at SmcKeepWord4
  LD (SmcKeepWord2),A     ; and the JR at SmcKeepWord2
  LD IX,(RecPtr3)         ; command record
  LD L,(IX+$04)           ; word at +4
  LD H,(IX+$05)
  BIT 7,(IX+$07)          ; flag of the word at +4
SmcKeepWord4:
  JR NZ,PushWords_Word4Done
  LD HL,$0000             ; flag says skip: no word
PushWords_Word4Done:
  EX (SP),HL              ; word under the return address
  PUSH HL
  LD L,(IX+$02)           ; word at +2
  LD H,(IX+$03)
  BIT 5,H                 ; flag of the word at +2
SmcKeepWord2:
  JR NZ,PushWords_Word2Done
  LD HL,$0000             ; flag says skip: no word
PushWords_Word2Done:
  EX (SP),HL              ; word 2 on top; HL = return address
  JP (HL)                 ; return

; Report a verb that matched only in part
;
; Reached from MatchCommand when a command record matched the start of the
; phrase but not the whole (PhraseMatched, $B6DF, is set). Pushes the three
; words of the phrase (RecWord1 the verb, RecWord2, RecWord3) and prints
; message $ADB0: "I do not know the verb "{WORD} {WORD} {WORD}"" through
; PrintReplyFail.
;
; O:A 0 (from PrintReplyFail)
ReportUnknownVerb:
  LD HL,(RecWord3)
  PUSH HL
  LD HL,(RecWord2)
  PUSH HL
  LD HL,(RecWord1)
  PUSH HL
  LD HL,MsgIDoNotKnowVerb ; the message
  JP PrintReplyFail

; Give pending order slots to an actor and free the rest
;
; When the player gives orders to a character, the parser stores each parsed
; command in a free order slot (OrderSlots, $B738) and marks the slot $FF,
; counting them in OrderSlotCount ($B737; filled by StoreParsedOrders). This
; keeps the first A of the pending slots (at most OrderSlotCount) by setting
; their owner to FirstObject ($B6E8, the character addressed), and frees the
; others by setting their owner to 0.
;
; A Number of orders the actor accepts
; BC, DE, IX are preserved
ClaimOrderSlots:
  PUSH BC
  PUSH IX
  PUSH DE
  LD B,A                  ; B = A
  LD A,(OrderSlotCount)   ; C = OrderSlotCount
  LD C,A
  CP B
  JR NC,ClaimOrderSlots_0 ; B = min(A, count)
  LD B,A
ClaimOrderSlots_0:
  LD A,C
  SUB B                   ; C = slots to free
  LD C,A
  LD IX,OrderSlots-ORDER_SLOT_SIZE ; the slot before slot 0
  LD DE,ORDER_SLOT_SIZE
  XOR A
  CP B
  JR Z,ClaimOrderSlots_1
ClaimOrderSlots_Next:
  ADD IX,DE               ; next slot ...
  LD A,(IX+$00)
  CP FLAG_SLOT_PENDING
  JR NZ,ClaimOrderSlots_Next ; ... that is pending
  LD A,(FirstObject)
  LD (IX+$00),A           ; it belongs to the addressed actor
  DJNZ ClaimOrderSlots_Next
ClaimOrderSlots_1:
  LD B,C                  ; the remaining pending slots
  XOR A
  CP B
  JR Z,ClaimOrderSlots_2
ClaimOrderSlots_Free:
  ADD IX,DE
  LD A,(IX+$00)
  CP FLAG_SLOT_PENDING
  JR NZ,ClaimOrderSlots_Free
  LD (IX+$00),$00         ; become free
  DJNZ ClaimOrderSlots_Free
ClaimOrderSlots_2:
  POP DE
  POP IX
  POP BC
  RET

; Find the order slot of the acting character
;
; Looks through the 8 order slots for one whose owner is Subject ($B6EA, the
; actor now acting).
;
; O:F Z if found
; O:HL Address of the slot (its owner byte) if found, otherwise past the table
;   OrderSlots+8*25
; O:A Subject
; O:B, DE Destroyed
FindOrderSlot:
  LD HL,OrderSlots
  LD DE,ORDER_SLOT_SIZE
  LD A,(Subject)
  LD B,ORDER_SLOTS
FindOrderSlot_0:
  CP (HL)
  RET Z
  ADD HL,DE
  DJNZ FindOrderSlot_0
  RET

; Find the acting character's order slot, keeping registers
;
; FindOrderSlot with HL, DE and BC preserved: only the flag comes back.
;
; O:F Z if Subject ($B6EA) owns an order slot
FindOrderSlotKeep:
  PUSH HL
  PUSH DE
  PUSH BC
  CALL FindOrderSlot
  POP BC
  POP DE
  POP HL
  RET

; Take the acting character's stored order and test it
;
; Called by the NPC runner (RunNpcScripts, LA814, LA8F6) when a character who
; was given an order by SAY TO is about to act. Finds the order slot owned by
; Subject (FindOrderSlot) and frees it at once (owner 0); the 24 bytes after
; the owner are the parsed command. With A = 0 it stops there. Otherwise it
; parses that record as if the player had typed it (InputFromOrder = 1,
; MatchSentence, keeping VerbAllFlag) and, when the parse succeeds, runs the
; check of the command (RunCheck). A parse failure or a refused check frees all
; of the character's remaining slots (FreeOrderSlots). The command ends up in
; the parser's variables (CommandId, FirstObject, SecondObject) for the caller
; to carry out.
;
; All registers are preserved except A and F, and HL in the A = 0 case. The
; three callers pass A = 1; the A = 0 path is not executed with the inputs in
; re/maps. If Subject owns no slot HL is past the table and the zero is written
; at the first byte after it (PhraseStack).
;
;   A 0: only fetch the slot; not 0: parse and check the order
;   Subject ($B6EA) The character whose order is wanted
; O:A 0 when there is no usable order (all slots of the character freed), else
;     not 0
; O:F Z when there is no usable order
; O:HL (A = 0 only) Address of the stored command record
RunStoredOrder:
  PUSH IX
  PUSH IY
  PUSH BC
  PUSH DE
  PUSH HL
  LD C,A                  ; C = mode
  CALL FindOrderSlot      ; HL = slot of Subject
  LD (HL),ORDER_SLOT_FREE ; slot is taken: owner 0
  INC HL                  ; HL = the stored record
  XOR A
  CP C
  JR NZ,RunStoredOrder_Parse
  OR $01                  ; A = 1, NZ
  EX (SP),HL              ; the record address replaces the saved HL
RunStoredOrder_Return:
  POP HL
  POP DE
  POP BC
  POP IY
  POP IX
  RET
RunStoredOrder_Parse:
  PUSH HL
  POP IY                  ; IY = the stored command
  LD A,$01
  LD (InputFromOrder),A   ; InputFromOrder = 1
  LD A,(VerbAllFlag)      ; VerbAllFlag is kept across the parse
  PUSH AF
  CALL MatchSentence      ; parse the record; Z = failed
  EX AF,AF'
  XOR A
  LD (InputFromOrder),A   ; InputFromOrder = 0
  POP AF
  LD (VerbAllFlag),A
  EX AF,AF'
  JR Z,RunStoredOrder_Drop
  CALL RunCheck           ; run the check of the command
  JR NZ,RunStoredOrder_Return ; allowed: return NZ
RunStoredOrder_Drop:
  LD A,(Subject)          ; parse failed or refused:
  CALL FreeOrderSlots     ; free the actor's slots
  XOR A                   ; A = 0, Z
  JR RunStoredOrder_Return

; Free the order slots of an actor
;
; Sets the owner of every order slot owned by A to 0 (free). HL, DE, BC are
; preserved.
;
; A Actor id
FreeOrderSlots:
  PUSH HL
  PUSH DE
  PUSH BC
  LD HL,OrderSlots
  LD DE,ORDER_SLOT_SIZE
  LD B,ORDER_SLOTS
FreeOrderSlots_0:
  CP (HL)
  JR NZ,FreeOrderSlots_1
  LD (HL),$00
FreeOrderSlots_1:
  ADD HL,DE
  DJNZ FreeOrderSlots_0
  POP BC
  POP DE
  POP HL
  RET
