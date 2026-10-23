; Turn a cursor key at the start of a line into a compass word
;
; Called by ReadLine for the first key of a new input line. If the key is a
; cursor key, the line becomes the one-letter direction command: cursor up
; types "N", down "S", right "E", left "W" (echoed in the input window), then a
; carriage return is stored after it. The caller echoes that return and ends
; the line, so one arrow key moves the player. Any other key is left alone.
;
; Hardware: echoes the letter through PrintChar (input window).
;
;   A Key code
;   HL Address in the input line buffer where the next character goes
;   B Free bytes left in the buffer ($80 for an empty line)
; O:A Carriage return when a cursor key was converted, else the key unchanged
; O:HL Address after the stored letter and return
; O:B Free bytes left, 2 fewer when converted
; O:F NZ
CursorKeyToWord:
  CP KEY_RIGHT
  JR Z,CursorKeyToWord_1
  CP KEY_LEFT
  JR Z,CursorKeyToWord_2
  CP KEY_DOWN
  JR Z,CursorKeyToWord_0
  CP KEY_UP
  RET NZ
  LD A,"N"                ; N for up
CursorKeyToWord_Store:
  LD (HL),A
  INC HL
  CALL PrintChar
  DEC B
  LD A,CHAR_CR
  LD (HL),A               ; end of line, not echoed here
  INC HL
  DEC B
  OR $01
  RET
CursorKeyToWord_0:
  LD A,"S"                ; S for down
  JR CursorKeyToWord_Store
CursorKeyToWord_1:
  LD A,"E"                ; E for right
  JR CursorKeyToWord_Store
CursorKeyToWord_2:
  LD A,"W"                ; W for left
  JR CursorKeyToWord_Store

; Repeat the previous command (the @ key)
;
; Reached from the line editor ReadLine when "@" is the first key of an empty
; line. The input line buffer still holds the previous line and the parsed word
; list at $709C is untouched, so the caller only has to parse that list again:
; this routine rubs out the "> " prompt with two back-spaces and returns Z with
; A = 0, which sends the caller (GameStart) straight to parsing.
;
; While a question of the game ("Which ...?") waits for its answer
; (AwaitingAnswer is not 0) the key is ignored and the editor goes on reading
; keys.
;
; Hardware: echoes through PrintChar (input window).
;
; O:A 0
; O:F Z set (no new line was typed)
L6E7A:
  LD A,(AwaitingAnswer)   ; AwaitingAnswer: an answer is awaited
  AND A
  JP NZ,ReadLine_Key      ; yes: ignore "@", read the next key
  LD A,CHAR_BACKSPACE
  CALL PrintChar          ; rub out the prompt ">"
  CALL PrintChar          ; and the space after it
  XOR A
  RET

; Erase the typed line from the input window
;
; Backs up over every character typed so far: prints a back-space for each and
; steps the buffer pointer back, until the line is empty (bit 7 of B set). Used
; for the cancel key of the line editor and before the idle "WAIT" is typed.
;
; Hardware: echoes through PrintChar (input window).
;
;   HL Address after the last typed character in the input line buffer
;   B Free bytes left in the buffer ($80 means empty)
; O:HL Start of the input line buffer
; O:B $80
EraseInputLine:
  BIT 7,B
  RET NZ
  LD A,CHAR_BACKSPACE
  CALL PrintChar
  INC B
  DEC HL
  JR EraseInputLine

; Turn the next typed word into a word token
;
; Skips spaces in the typed line and makes one token of what follows: the end
; of the line (carriage return) gives TOKEN_END, a full stop, comma or double
; quote its punctuation token (ScanPunctuation), anything else is looked up in
; the dictionary at $6000 (L6F47). A typed word matches the first dictionary
; entry that starts with the same letters when the typed word is not longer
; than the entry. A typed word that is longer than an entry of 4 or more
; letters matches it when it starts with all of its letters, unless a later
; entry matches as well; the longer one is then preferred. A synonym entry
; (last byte bit 6) is replaced by the word it points to, so "n" gives the
; token of "north". A word that matches nothing gives TOKEN_UNKNOWN.
;
; The token is a class in the high nibble (dictionary class of the word, see
; the notes) and the dictionary offset of the word in the other 12 bits: B =
; class + offset bits 8-11, C = offset bits 0-7. The caller (GameStart) stores
; B and C in the word list at $709C. InputLinePtr ($B6DA) is set to the start
; of the word, for the "I do not know the word" message. Entry points inside
; the loop use SourceTextPtr ($B717) for the dictionary entry being tried.
;
; Hardware: none.
;
;   HL Address in the typed line to read from
; O:A Class nibble of the token ($C0 end of line, $D0 unknown word, $90/$A0/$B0
;     punctuation)
; O:D The same
; O:B Class nibble and dictionary offset bits 8-11
; O:C Dictionary offset bits 0-7
; O:HL Address after the word or punctuation mark (also when the word is
;      unknown)
; O:E Preserved
ReadTypedWord:
  PUSH DE
ReadTypedWord_0:
  LD A,(HL)
  INC HL
  CP CHAR_SPACE
  JR Z,ReadTypedWord_0    ; skip spaces
  DEC HL
  LD (InputLinePtr),HL    ; InputLinePtr: start of this word
  CP CHAR_CR
  JR Z,ReadTypedWord_5    ; end of the line
  CALL ScanPunctuation    ; punctuation?
  JR Z,ReadTypedWord_Done ; yes: A = its token, BC = 0
  CALL L6F47              ; copy the letters, find the first entry for the
                          ; first letter
  JR NZ,ReadTypedWord_3   ; no entry: unknown word
  PUSH HL                 ; address after the typed word
ReadTypedWord_1:
  CALL CompareWords       ; compare the letters with the entry
  JR Z,ReadTypedWord_4    ; same as far as the shorter one goes
ReadTypedWord_2:
  CALL TestWordEntry      ; try the next entry
  JR Z,ReadTypedWord_1    ; (same first letter)
  POP HL                  ; none left: unknown word
ReadTypedWord_3:
  LD A,TOKEN_UNKNOWN
  JR ReadTypedWord_6
ReadTypedWord_4:
  LD A,(WordLength)       ; length of the typed word
  LD B,A
  LD A,(MatchLength)      ; length of the entry
  CP B
  JR NC,ReadTypedWord_Accept ; entry not shorter: accept it
  CP $04
  JR C,ReadTypedWord_2    ; shorter than 4 letters: no, try the next entry
  PUSH IX                 ; the typed word is longer: is there a better entry?
  CALL TestWordEntry_Compare ; decode the next entry
  JR NZ,ReadTypedWord_7   ; none: accept this one
  CALL CompareWords
  JR NZ,ReadTypedWord_7   ; the next one does not match: accept this one
  POP IX
  JR ReadTypedWord_2      ; it matches too: take it as the candidate
ReadTypedWord_5:
  LD A,TOKEN_END
ReadTypedWord_6:
  LD BC,$0000             ; no word
ReadTypedWord_Done:
  POP DE
  LD D,A                  ; D = class nibble
  ADD A,B
  LD B,A                  ; B = class + offset bits 8-11
  LD A,D
  RET
ReadTypedWord_7:
  POP IX
ReadTypedWord_Accept:
  LD IX,(SourceTextPtr)   ; SourceTextPtr: the entry that matched
  PUSH IX
  XOR A
ReadTypedWord_8:
  INC IX                  ; find the last byte of the entry
  INC A
  BIT 7,(IX-$01)
  JR Z,ReadTypedWord_8
  CP $02                  ; byte 2 never ends an entry
  JR Z,ReadTypedWord_8
  CP $03
  JR NZ,ReadTypedWord_9
  BIT 7,(IX-$02)          ; byte 3 does not end it after a verb flag in byte 2
  JR NZ,ReadTypedWord_8
ReadTypedWord_9:
  BIT 6,(IX-$01)          ; synonym?
  JR Z,ReadTypedWord_10
  LD L,(IX+$00)           ; offset of the word it stands for
  LD H,(IX+$01)
  LD DE,Vocabulary
  ADD HL,DE
  EX (SP),HL              ; use that entry instead
ReadTypedWord_10:
  POP HL                  ; the dictionary entry
  LD A,(HL)               ; class bits 3-2: bits 5-6 of byte 1...
  RLCA
  AND $C0
  LD B,A
  INC HL
  LD A,(HL)               ; ...class bits 1-0: bits 5-6 of byte 2
  RRCA
  AND $30
  ADD A,B                 ; A = class nibble
  DEC HL
  LD DE,-Vocabulary       ; HL - $6000: the offset of the entry
  ADD HL,DE
  PUSH HL
  POP BC                  ; BC = offset
  POP HL                  ; address after the typed word
  JR ReadTypedWord_Done

; Turn punctuation in the typed line into a word token
;
; Looks at the character at HL in the typed line: a full stop gives the word
; token for "then" ($B0, class 11), a comma gives "and" ($A0, class 10), a
; double quote gives $90 (class 9). Called by ReadTypedWord before it tries a
; dictionary lookup.
;
;   A Character from the typed line
;   HL Address of that character
; O:F Z when the character was punctuation, NZ otherwise
; O:A Word token (when Z), else the character
; O:HL Address after the punctuation (when Z)
; O:BC 0 (when Z)
ScanPunctuation:
  LD B,TOKEN_THEN
  CP "."
  JR Z,ScanPunctuation_0
  LD B,TOKEN_AND
  CP ","
  JR Z,ScanPunctuation_0
  CP '"'
  RET NZ
  LD B,TOKEN_QUOTE
ScanPunctuation_0:
  INC HL
  LD A,B
  LD BC,$0000
  RET

; Look up the typed word in the dictionary
;
; Copies the letters of the word at HL (characters $40 and up, 5 bits each)
; into WordLetters and counts them in WordLength, then picks the first
; dictionary entry for its first letter from the index at Vocabulary. Falls
; into the loop that tests entries one at a time.
;
; The entry points after the first test one entry (IX) against the typed word:
; if its first letter differs, return NZ (the words of one letter are
; contiguous, so the caller stops). Otherwise the entry's letters are decoded
; into MatchLetters (count in MatchLength), skipping the suffix bits that are
; not letters, IX is moved past the entry (and past its two synonym bytes when
; bit 6 of its last byte is set, in which case A=0), and Z is returned. The
; caller (ReadTypedWord) then compares the two words with CompareWords.
;
;   HL Address of the first character of the typed word
; O:HL Address after the typed word
; O:IX Address of the first dictionary entry for its first letter
; O:F NZ when the first letter has no entry
L6F47:
  LD DE,WordLetters
  LD B,$00
L6F47_0:
  LD A,(HL)
  CP $40
  JR C,L6F47_1
  AND $1F
  LD (DE),A
  INC DE
  INC HL
  INC B
  JR L6F47_0
L6F47_1:
  LD A,B
  LD (WordLength),A
  PUSH HL
  LD HL,(WordLetters)     ; first letter in L
  LD H,$00                ; H=0, HL=first letter
  LD DE,Vocabulary
  ADD HL,HL               ; two bytes per index entry
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD IX,Vocabulary        ; IX=entry address
  ADD IX,DE
  POP HL
; This entry point is used by the routine at ReadTypedWord.
TestWordEntry:
  LD (SourceTextPtr),IX   ; remember the entry being tried for the caller
; This entry point is used by the routine at ReadTypedWord.
TestWordEntry_Compare:
  LD A,(IX+$00)
  AND $1F
  LD B,A
  LD A,(WordLetters)      ; first typed letter
  CP B
  RET NZ                  ; different first letter: no more candidates
  PUSH HL
  LD HL,MatchLetters
  LD BC,$0000
L6F47_2:
  LD A,(IX+$00)
  AND $1F
  JR Z,L6F47_3
  LD (HL),A
  INC HL
  INC B
L6F47_3:
  INC IX
  INC C
  BIT 7,(IX-$01)
  JR Z,L6F47_2
  LD A,C                  ; C counts bytes read
  CP $02                  ; byte 2 is never the last
  JR Z,L6F47_2
  CP $03
  JR NZ,L6F47_4
  BIT 7,(IX-$02)          ; byte 3 goes on when byte 2 had bit 7
  JR NZ,L6F47_2
L6F47_4:
  POP HL
  LD A,B
  LD (MatchLength),A      ; MatchLength
  BIT 6,(IX-$01)          ; bit 6 of the last byte: synonym
  RET Z
  INC IX
  INC IX
  XOR A
  RET

; Compare the typed word with the dictionary word
;
; Compares the letters of the typed word (WordLetters) with the letters of the
; dictionary entry just decoded (MatchLetters) over the length of the shorter
; of the two. Z means the shorter one is a prefix of the other.
;
; O:F Z when the letters match, NZ otherwise
; O:A Last letter compared
; O:B Remaining count (0 when Z)
CompareWords:
  LD A,(WordLength)
  LD B,A
  LD A,(MatchLength)
  CP B
  JR NC,CompareWords_0    ; B = shorter length
  LD B,A
CompareWords_0:
  LD HL,WordLetters       ; typed letters
  LD DE,MatchLetters
CompareWords_1:
  LD A,(DE)
  CP (HL)
  RET NZ
  INC DE
  INC HL
  DJNZ CompareWords_1
  RET

; Clear the screen to black ink on white paper
;
; Sets the border white, zeroes the whole bitmap and fills the attributes with
; black ink on white paper. The second fill runs one byte past the attributes
; and sets $5B00 as well.
;
; Hardware: writes the border (port $FE), the screen bitmap and the attributes.
;
; O:BC, DE, HL Preserved
ClearScreen:
  PUSH HL
  PUSH DE
  PUSH BC
  LD A,BORDER_WHITE
  OUT (PORT_ULA),A
  LD HL,SCREEN
  LD DE,SCREEN+$0001
  LD BC,SCREEN_BITMAP_SIZE
  LD (HL),$00
  LDIR
  LD BC,ATTRS_SIZE
  LD (HL),WHITE*PAPER+BLACK
  LDIR
  POP BC
  POP DE
  POP HL
  RET

; Default first command text "> LOOK", CR
;
; Printed by the start code at $6CFA; the five bytes from $6FF4 ("LOOK", CR)
; are copied to the input line.
StartCommand:
  DEFM "> "
LookCommand:
  DEFM "LOOK"
  DEFB $0D

; Input line buffer: 128 characters and a CR ($6FF9-$7079)
;
; The command being typed, blank-filled; edited by $6E97 and the line editor,
; parsed by $6E97 with $6F47.
InputLine:
  DEFS $80,$20
  DEFB $0D

; Word lookup workspace
;
; Letters (5 bits each) of the word being looked up, its length ($708A), the
; letters of the dictionary word found ($708B, up to 16) and their count
; ($709B). Set by $6F47.
WordLetters:
  DEFS $10
WordLength:
  DEFB $00
MatchLetters:
  DEFS $10
MatchLength:
  DEFB $01

; Parsed command: up to 32 pairs (tag, word number)
;
; Built by $6E97 from the input line; read back by $7873 through the pointer
; ($B6DC). Tag high nibble = word class, low nibble = count; zero tag byte =
; end.
ParsedWords:
  DEFS $40

; Message printer saved registers
;
; Set by $72DD on entry: A ($70DC), DE ($70DD), IX ($70E0); restored by control
; codes ($735B). Between them, $70DF is set while a command is echoed as a
; sentence.
SavedA:
  DEFB $00
SavedDE:
  DEFW $0000
EchoingCommand:
  DEFB $00                ; 1 while PrintCommandSentence builds the command's
                          ; sentence (F29)
SavedIX:
  DEFW $0000

; Zero a block of bytes
;
; Fills B bytes from HL with zero (B=0 means 256).
;
;   HL Start address
;   B Number of bytes
; O:HL Address after the block
; O:A 0
; O:B 0
ClearBytes:
  XOR A
ClearBytes_0:
  LD (HL),A
  INC HL
  DJNZ ClearBytes_0
  RET

; Address of a command table record
;
; HL = CommandTable + 8 * (A - 1): the 8-byte record of command id A in the
; command table (ids start at 1).
;
;   A Command id (1-59)
; O:HL Address of the record
; O:DE Destroyed
CommandRecordAddr:
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,CommandTable-COMMAND_RECORD_SIZE
  ADD HL,DE
  RET

; Pack the flag nibbles of a command record
;
; Takes the top nibbles of the four high bytes of the record's words (verb word
; +1, first preposition +3, second preposition +5, flags word +7) and packs
; them into two bytes: StateB71D = (nibble of +3 << 4) + nibble of +1,
; StateB71E = (nibble of +7 << 4) + nibble of +5. Later code tests the single
; bits (for example bit 7 of StateB71D: the first noun is a location; bit 6 of
; StateB71E). Meaning of the bits is only partly known.
;
;   IX Command table record
; O:A Value stored in StateB71D
; O:C Nibble of +1
PackCommandFlags:
  LD A,(IX+$05)
  RRCA
  RRCA
  RRCA
  RRCA
  AND $0F
  LD C,A
  LD A,(IX+$07)
  AND $F0
  ADD A,C
  LD (StateB71E),A
  LD A,(IX+$01)
  RRCA
  RRCA
  RRCA
  RRCA
  AND $0F
  LD C,A
  LD A,(IX+$03)
  AND $F0
  ADD A,C
  LD (StateB71D),A
  RET

; Start performing a command
;
; Sets the "perform" flag ($B6FA) and clears the "blocked" flag ($B6FB), then
; calls PrintCommandSentence unless the command comes from a stored order
; ($B71B set), to print the command as a sentence.
;
; O:A 0
StartPerform:
  XOR A
  LD (ActionAllowed),A
  INC A
  LD (ActionPerform),A
  LD A,(InputFromOrder)   ; InputFromOrder
  AND A
  CALL Z,PrintCommandSentence
  XOR A
  RET

; Print a command as a sentence
;
; Writes the chosen command (CommandId, FirstObject, SecondObject, Subject) as
; a sentence: "You take the short strong sword.", "Gandalf gives the curious
; map to you.", "You cannot take the wooden chest.". The parts, in order: the
; name of the subject; "cannot" when ActionAllowed is 0; the word at record +6
; of the command table record (the "go" of the ten moves); the verb word at +0
; (a move in the dark prints "somewhere" instead of the direction); the first
; noun's name phrase, preceded by the record's prepositions when the flags say
; so (CMDF_PREP1_BEFORE, CMDG_PREP2_BEFORE: "climb out of the pit", "take off
; the cloak"); the other prepositions and the second noun ("put the map in the
; chest"); a full stop and a new line. A command with CMDF_SILENT (look,
; inventory) prints nothing.
;
; A command that is allowed (ActionAllowed 1) is printed in the story window,
; on a new line when the player acts. A refused one goes to the input window
; (RawOutputFlag 1), after the prompt line. While it runs the byte $70DF is 1,
; which makes the article printer use the table "the, the, the, some"
; (PrintArticle). PhraseMode is cleared. RawOutputFlag is left as set here.
;
; Hardware: none directly; the characters go to the screen through PrintChar.
;
; O:A 0
; O:F Z set
; O:RawOutputFlag 0 when the command was allowed, 1 when it was refused
PrintCommandSentence:
  LD A,$01                ; $70DF = 1: a command sentence is being built
  LD (EchoingCommand),A
  XOR A
  LD (PhraseMode),A       ; PhraseMode 0
  PUSH IY
  PUSH BC
  LD A,(ActionAllowed)    ; ActionAllowed
  LD B,A                  ; B = allowed (1) or refused (0)
  AND A
  LD A,$01                ; refused: input window
  JR Z,PrintCommandSentence_0
  XOR A                   ; allowed: story window
PrintCommandSentence_0:
  LD (RawOutputFlag),A    ; RawOutputFlag
  PUSH IX
  PUSH HL
  PUSH DE
  LD A,(CommandId)        ; CommandId
  CALL CommandRecordAddr  ; CommandRecordAddr
  PUSH HL
  POP IX                  ; IX = the command table record
  XOR A
  CP B
  JR Z,PrintCommandSentence_1 ; refused: no new line
  LD A,(Subject)          ; Subject
  AND A
  CALL Z,PrintNewLine     ; the player acts: start on a new line
PrintCommandSentence_1:
  CALL PackCommandFlags   ; PackCommandFlags: A = C = StateB71D
  BIT CMDF_SILENT,A
  LD C,A
  JP NZ,PrintCommandSentence_6 ; silent command (look, inventory): print
                               ; nothing
  CALL PrintSubjectNameAsIs ; the subject's name
  LD DE,WORD_CANNOT
  XOR A
  CP B
  CALL Z,PrintWord        ; refused: "cannot"
  PUSH HL
  LD DE,$0006
  ADD HL,DE
  CALL PrintWordAtHL      ; the word at record +6 ("go"), usually empty
  CALL CheckDark          ; CheckDark
  POP HL                  ; HL = record
  JR NC,PrintCommandSentence_2
  LD A,(CommandId)        ; in the dark:
  CP CMD_FIRST_OTHER
  JR NC,PrintCommandSentence_2 ; not a move
  LD DE,WORD_SOMEWHERE
  INC HL
  INC HL                  ; skip the direction word
  CALL PrintWord          ; "go somewhere"
  JR PrintCommandSentence_3
PrintCommandSentence_2:
  CALL PrintWordAtHL      ; the verb word (+0)
PrintCommandSentence_3:
  BIT CMDF_NOUN1,C        ; has a first noun?
  JR Z,PrintCommandSentence_4
  BIT CMDF_PREP1_BEFORE,C
  CALL NZ,PrintWordAtHL   ; preposition before the noun ("off", "out")
  LD A,(StateB71E)        ; StateB71E
  BIT CMDG_PREP2_BEFORE,A
  CALL NZ,PrintWordAtHL   ; second preposition before the noun ("of")
  CALL PrintFirstObjectNameAsIs ; the first noun, with its article
PrintCommandSentence_4:
  LD A,(SecondObject)     ; SecondObject
  CP NO_OBJECT
  JR Z,PrintCommandSentence_5 ; no second noun
  BIT CMDF_NOUN2,C
  JR Z,PrintCommandSentence_5
  BIT CMDF_PREP1_BEFORE,C
  CALL Z,PrintWordAtHL    ; preposition between the nouns ("to", "in")
  LD A,(StateB71E)
  BIT CMDG_PREP2_BEFORE,A
  CALL Z,PrintWordAtHL
  CALL PrintSecondObjectNameAsIs ; the second noun, with its article
PrintCommandSentence_5:
  LD A,CHAR_FULLSTOP      ; "."
  CALL PrintChar          ; PrintChar
  CALL PrintNewLine       ; PrintNewLine
PrintCommandSentence_6:
  XOR A
  LD (EchoingCommand),A   ; the sentence is done
  POP DE
  POP HL
  POP IX
  POP BC
  POP IY
  RET

; Address of a location's name phrase
;
; Looks up the location record of location A (FindLocation) and returns the
; address of its first phrase code (record +2). For an id of $50 or more the
; lookup leaves IX alone and the result is not meaningful.
;
;   A Location id
; O:HL Address of the phrase codes of the location
; O:IX Preserved
LocationNamePtr:
  PUSH IX
  CALL FindLocation
  PUSH IX
  POP HL
  INC HL
  INC HL
  POP IX
  RET

; Address of an object's name phrases
;
; Looks up the record of object or character A (FindObject) and returns the
; address of its name phrase codes (record +8).
;
;   A Object or character id
; O:HL Address of the name phrase codes
; O:DE, IX Preserved
ObjectNamePtr:
  PUSH DE
  PUSH IX
  CALL FindObject
  PUSH IX
  POP HL
  LD DE,$0008             ; record +8: first name phrase
  ADD HL,DE
  POP IX
  POP DE
  RET

; Match a command table record against the typed phrase
;
; HL points at the three word tokens of the parsed phrase (verb and two others,
; 0 meaning absent) and IY at one record of the command table. The verb word
; must match the record's verb. If it does, PhraseMatched is set to 1 (the
; phrase matched in part). The next two words must then match the record's two
; prepositions in order (A=0), or the other way round (A=1). Each comparison is
; made by MatchWord.
;
;   HL Parsed phrase (three word tokens)
;   IY Command table record
; O:F Z when the record matches
; O:A 0 when the words matched in order, 1 when swapped (valid with Z)
; O:DE, HL, IY Preserved
MatchCommandRecord:
  PUSH DE
  PUSH HL
  PUSH IY
  CALL MatchWord
  JR NZ,MatchCommandRecord_0
  LD A,$01
  LD (PhraseMatched),A    ; PhraseMatched: the verb matched
  CALL MatchWord
  JR NZ,MatchCommandRecord_Swap
  CALL MatchWord
  LD A,$00
  JR Z,MatchCommandRecord_0
MatchCommandRecord_Swap:
  POP IY                  ; try the two words swapped
  POP HL
  PUSH HL
  PUSH IY
  LD DE,$0004             ; parsed word 2 against record word 3
  ADD IY,DE
  INC HL
  INC HL
  CALL MatchWord
  JR NZ,MatchCommandRecord_0
  LD DE,$FFFC             ; then parsed word 3 against record word 2
  ADD IY,DE
  CALL MatchWord
  LD A,$01
MatchCommandRecord_0:
  POP IY
  POP HL
  POP DE
  RET

; Compare a parsed word with a command record word
;
; HL points at a 16-bit word token of the parsed phrase, IY at a 16-bit word of
; a command table record. They match when the low 12 bits (the dictionary
; offset) are equal; the class and flag nibbles are ignored. A parsed token of
; 0 (no word given) matches anything. Both pointers move on by one word.
;
;   HL Parsed word token
;   IY Record word
; O:F Z when they match
; O:HL Address of the next parsed word
; O:IY Address of the next record word
MatchWord:
  PUSH HL
  LD A,(HL)
  INC HL
  OR (HL)
  JR Z,MatchWord_0        ; no word given: Z
  LD A,(IY+$01)
  XOR (HL)
  AND $0F                 ; offset bits 8-11
  JR NZ,MatchWord_0
  DEC HL
  LD A,(HL)
  CP (IY+$00)             ; offset low byte
MatchWord_0:
  POP HL
  INC HL
  INC HL
  INC IY
  INC IY
  RET

; Wait for a key of the line editor, typing WAIT when the player is idle
;
; Scans the keyboard with ReadKey until a key is newly pressed and returns its
; code. The scans are counted in the idle counter at $B714 (set to
; IDLE_SCANS_MAX by ReadLine at the start of every line). When it runs to 0
; with no key the routine rubs out whatever was typed (EraseInputLine), types
; the word WAIT into the line buffer and the input window and returns a
; carriage return as if the player had pressed ENTER, so a player who does
; nothing sees time pass. That takes roughly 15-20 s (the scan loop is not tied
; to a frame).
;
; Each key pressed gives IDLE_SCANS_PER_KEY scans back to the counter, to at
; most IDLE_SCANS_MAX, so typing keeps the player from timing out.
;
; Hardware: polls the keyboard (via ReadKey); the wait is a counted loop.
;
;   HL Address after the last typed character in the input line buffer
;   B Free bytes left in the buffer
; O:A Key code ($0D after the time-out)
; O:HL The same address, after WAIT on a time-out
; O:B Free bytes left, $7C on a time-out
WaitKey:
  PUSH HL
  LD HL,(IdleCounter)     ; idle counter ($B714)
WaitKey_Scan:
  CALL ReadKey            ; ReadKey
  AND A
  JR NZ,WaitKey_1         ; a key
  DEC HL
  LD A,H
  OR L
  JR NZ,WaitKey_Scan
  POP HL                  ; time-out: the line buffer pointer
  PUSH HL
  CALL EraseInputLine     ; erase the typed line
  LD DE,WaitText          ; WaitText
  LD B,$04
WaitKey_0:
  LD A,(DE)
  LD (HL),A               ; type "WAIT" into the buffer...
  INC HL
  INC DE
  CALL PrintChar          ; ...and the input window
  DJNZ WaitKey_0
  EX (SP),HL              ; the pointer after WAIT is returned in HL
  LD B,INPUT_LINE_SIZE-$04
  LD A,CHAR_CR            ; ENTER
  LD HL,-IDLE_SCANS_PER_KEY ; so that the refill below gives the full count
WaitKey_1:
  PUSH AF
  XOR A
  LD DE,IDLE_SCANS_PER_KEY
  ADC HL,DE               ; counter + 500
  LD DE,IDLE_SCANS_MAX
  JR C,WaitKey_2          ; wrapped (the time-out case): full count
  CALL CompareHLDE        ; compare with the maximum
  JR C,WaitKey_3          ; below it: keep
WaitKey_2:
  EX DE,HL                ; else the maximum
WaitKey_3:
  LD (IdleCounter),HL
  POP AF
  POP HL
  RET

; Compare HL with DE
;
; HL Value DE Value to compare with O:F Z when equal, carry when HL is less
; than DE O:A Destroyed
CompareHLDE:
  LD A,H
  SUB D
  RET NZ
  LD A,L
  SUB E
  RET
