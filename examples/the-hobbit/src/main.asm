; Start of the game, restart point and main loop
;
; The entry point of the game: the BASIC loader ends with PRINT USR 27648. This
; entry also holds the restart point and the main loop. How the whole game
; runs, top down:
;
; Start. The four state blocks that SAVE writes (the variables at $B6EB, the
; objects and characters at $C11B, the timers at $CA84, the locations at $BA8A)
; hold the story as loaded from tape. The game copies them to a backup: the big
; two to StateBackup ($F400), the small two to $5F00. The title screen (the
; loading picture) is still on the display.
;
; Restart (RestartGame, $6C27). QUIT, death and a tape error all jump here. The
; stack is reset, the backup is copied back over the state blocks (so the story
; begins again), the border goes black and the game waits at the title screen
; for any key. If N is held when the key goes down the pictures are turned off
; for the whole game. The Z80 refresh register read at that moment is the seed
; of the random numbers.
;
; Set up. The cursors and column counters of the story window and the input
; window get their start values, the order slots (what characters were told to
; do) are cleared, the printer is off, messages are on, the score is 0, the
; screen is cleared and a rule is drawn between the story and the input window.
; The first 17 lines of story text will scroll without the pause that otherwise
; follows each full screen.
;
; Opening. The first time round (ParserWordCount is still $FF from the saved
; state) the game sets up its hidden starting state (InitNewGame: which exit is
; blocked, the random event, who is about), echoes "> LOOK" in the input window
; and runs that command as if it had been typed, so the player starts with the
; description and the picture of Bag End.
;
; Main loop (MainLoop, $6D13), once per typed line. ReadLine reads a line of up
; to 128 characters from the keyboard into InputLine. ReadTypedWord turns its
; words into tokens in ParsedWords: a word of the dictionary, THEN (a full
; stop), AND (a comma), a double quote or the end of the line. A word that is
; not in the dictionary prints `I do not know the word "..."` and drops the
; line. What is typed between double quotes (SAY TO somebody "...") is an order
; for a character: the closing quote gets a THEN before it, and a line that
; ends inside quotes is refused. ParseLine then builds phrase records from the
; tokens, one sentence (up to a THEN) at a time, and RunSentences runs them: it
; matches each record to a command, finds the objects, checks the command and,
; if it is allowed, performs it and gives the others their turn. The loop goes
; round ParseLine and RunSentences while ParserFlag stays set, that is while
; the line has sentences left, and then reads the next line. A sentence that
; ParseLine cannot understand (it prints "What ?") drops the rest of the line.
; The key @ at the start of an empty line repeats the previous line: the editor
; returns Z and the loop goes straight to RunWordList with the old word list.
;
; A turn. After each sentence the game performed, RunSentences ticks the timers
; and runs every other character (one turn of the world) before the next
; sentence of the line is run. A sentence the game refused takes no turn.
;
; Hardware: DI (interrupts stay off for the whole game); OUT to port $FE for
; the border and BORDCR for the border colour the ROM would use; IN from port
; $FE for the title-screen key (all half-rows) and the N key (half-row $7F);
; the R register as the random seed; the screen bitmap and attributes (cleared
; with ClearScreen, the rule drawn from BorderTile). All other output goes
; through the print routines.
GameStart:
  DI                      ; interrupts stay off for the whole game
  LD DE,StateBackup       ; back up the objects and characters ...
  LD HL,Chr00Player
  LD BC,STATE_OBJECTS_SIZE
  LDIR
  LD HL,Loc00None         ; ... and the locations (DE goes on after the first
                          ; copy)
  LD BC,STATE_LOCATIONS_SIZE
  LDIR
  LD DE,STATE_COPY        ; back up the saved variables ...
  LD HL,SavedScriptBytes
  LD BC,STATE_VARS_SIZE
  LDIR
  LD HL,Timers            ; ... and the timers and character records
  LD BC,STATE_TIMERS_SIZE
  LDIR

; Restart the game: restore the saved state and begin a new game
;
; This entry point is used by the routines at WordQuit, LoadBlock and EndGame.
RestartGame:
  DI
  LD SP,STACK_TOP         ; the stack lives at $5EFF and below
  LD IX,PictureTable      ; PictureTable: zero the border and attribute bytes
                          ; of
  LD A,$05                ; picture 5 (already 0 on the tape; reason unknown,
                          ; see
  CALL FindIdRecord       ; the notes)
  LD L,(IX+$01)
  LD H,(IX+$02)
  LD (HL),$00
  INC HL
  LD (HL),$00
  LD HL,StateBackup       ; copy the backups over the state blocks
  LD DE,Chr00Player
  LD BC,STATE_OBJECTS_SIZE
  LDIR
  LD DE,Loc00None
  LD BC,STATE_LOCATIONS_SIZE
  LDIR
  LD HL,STATE_COPY
  LD DE,SavedScriptBytes
  LD BC,STATE_VARS_SIZE
  LDIR
  LD DE,Timers
  LD BC,STATE_TIMERS_SIZE
  LDIR
  XOR A
  OUT (PORT_ULA),A        ; black border
  LD A,WHITE*PAPER+BLACK
  LD (BORDCR),A           ; BORDCR: black ink on white paper
WaitTitleKey:
  XOR A                   ; A = 0 selects all eight half-rows
  IN A,(PORT_ULA)
  AND KEY_BITS
  CP KEY_BITS             ; all five lines high: no key
  JR Z,WaitTitleKey       ; wait for any key
  LD A,KB_ROW_SPACE_B     ; half-row SPACE SYMBOL-SHIFT M N B
  IN A,(PORT_ULA)
  AND KEY_N               ; 0 when N is held (the key is down), else $08
  LD (PicturesEnabled),A  ; PicturesEnabled
  LD HL,SCREEN_ROW_23     ; input window cursor: the bottom row ...
  LD (InputCursor),HL
  LD A,CURSOR_GLYPH
  LD (InputCursorGlyph),A ; InputCursorGlyph
  LD HL,STORY_LAST_ROW    ; story window cursor: its last row
  LD (StoryCursor),HL
  LD A,$01
  LD (StoryCursorPixel),A ; StoryCursorPixel
  LD A,INPUT_COLUMNS
  LD (InputColumn),A      ; InputColumn: a full line of columns left
  LD A,STORY_COLUMNS
  LD (StoryColumn),A      ; StoryColumn
  LD B,ORDER_SLOT_SIZE*ORDER_SLOTS
  LD HL,OrderSlots        ; OrderSlots
  CALL ClearBytes         ; ClearBytes: no character has an order
  LD A,R                  ; the refresh register depends on how long the title
  LD (RandomSeed),A       ; screen waited: RandomSeed
  XOR A
  LD (ListIndent),A       ; ListIndent
  LD (StoryLastChar),A    ; StoryLastChar
  LD (AwaitingAnswer),A   ; AwaitingAnswer: no question pending
  LD (LispFlag),A         ; LispFlag
  LD (PrinterFlag),A      ; PrinterFlag: printer off
  LD A,$01
  LD (MessagesVisible),A  ; MessagesVisible
  LD (ActionPerform),A    ; ActionPerform: do, not just test
  LD (CapitalNext),A      ; CapitalNext: the first letter is a capital
  LD HL,$0000
  LD (Score),HL           ; Score
  CALL ClearScreen        ; ClearScreen
  LD HL,BORDER_RULE       ; draw the rule between story and input window: 5
                          ; pixel
  LD DE,BorderTile        ; lines (BorderTile rows) of 16 two-byte tiles each
  LD C,$05
RestartGame_0:
  LD B,$10
  PUSH HL
RestartGame_1:
  LD A,(DE)
  LD (HL),A
  INC HL
  INC DE
  LD A,(DE)
  LD (HL),A
  INC HL
  DEC DE                  ; the same two bytes again for the next tile
  DJNZ RestartGame_1
  INC DE
  INC DE                  ; the next pixel line's two bytes
  POP HL
  INC H
  DEC C
  JR NZ,RestartGame_0
  LD A,OPENING_LINES
  LD (NoPauseLines),A     ; NoPauseLines: the opening text scrolls without
                          ; pauses
  LD A,(ParserWordCount)  ; ParserWordCount, $FF until the first line is parsed
  INC A
  JR NZ,MainLoop          ; not $FF: no automatic LOOK (not seen to happen)
AutoLook:
  CALL InitNewGame        ; InitNewGame
  LD HL,StartCommand      ; StartCommand: echo "> LOOK" in the input window
RestartGame_2:
  LD A,(HL)
  CALL PrintInputWindowChar ; PrintInputWindowChar
  INC HL
  CP CHAR_CR
  JR NZ,RestartGame_2
  LD HL,LookCommand       ; LookCommand: "LOOK", CR becomes the typed line
  LD DE,InputLine         ; InputLine
  LD BC,$0005
  LDIR
  JR BuildWordList        ; and is parsed as if the player had typed it

; Main loop: read a line, turn it into words, run its sentences
MainLoop:
  LD A,$01
  LD (ParserFlag),A       ; ParserFlag: the line has sentences to run
  LD A,TURN_NO_PAUSE_LINES
  LD (NoPauseLines),A     ; NoPauseLines: nine lines of reply scroll without a
                          ; pause
  CALL ReadLine           ; ReadLine: NZ a new line, Z the previous one
                          ; repeated
  JR Z,RunWordList        ; "@": run the old word list again
BuildWordList:
  LD HL,ParsedWords       ; ParsedWords
  LD B,PARSED_WORDS_SIZE
  CALL ClearBytes         ; ClearBytes: empty the word list
  LD HL,InputLine         ; InputLine
  LD IY,ParsedWords       ; IY: where the next token goes
ReadWords:
  CALL ReadTypedWord      ; ReadTypedWord: B, C token, D its class
  CP TOKEN_UNKNOWN
  JR Z,UnknownWord        ; a word the game does not know
  CP TOKEN_QUOTE
  JR NZ,StoreToken        ; not a double quote: store the token
  LD A,B
  AND $0F
  OR C
  JR NZ,StoreToken
  LD A,(InputFromOrder)   ; InputFromOrder: 1 inside quotes
  AND A
  JR NZ,MainLoop_0
  INC A                   ; an opening quote: now inside quotes
  LD (InputFromOrder),A
  JR StoreToken
MainLoop_0:
  DEC A                   ; a closing quote ...
  LD (InputFromOrder),A
  LD A,(IY-$02)           ; ... after the order's last word: if that is not
                          ; already a
  AND $F0                 ; THEN or AND, end the order with a THEN token
  CP TOKEN_THEN
  JR Z,StoreToken
  CP TOKEN_AND
  JR Z,StoreToken
  LD A,TOKEN_THEN
  LD (IY+$00),A
  XOR A
  LD (IY+$01),A
  INC IY
  INC IY
StoreToken:
  LD (IY+$00),B
  LD (IY+$01),C
  INC IY
  INC IY
  LD A,D
  CP TOKEN_END
  JR NZ,ReadWords         ; until the end of the line
  LD A,(InputFromOrder)   ; the line ended inside quotes?
  AND A
  JR Z,RunWordList
  XOR A
  LD (InputFromOrder),A
  CALL PrintWhat          ; print "What ?"
  JR MainLoop             ; and read another line
RunWordList:
  LD HL,ParsedWords       ; ParsedWords
  LD (WordListPtr),HL     ; WordListPtr: start at the first token
ParseSentence:
  CALL ParseLine          ; ParseLine: the next sentence of the line into
                          ; records
  JP NZ,MainLoop          ; refused: drop the line
  CALL RunSentences       ; RunSentences: run the records
  LD A,(ParserFlag)       ; ParserFlag
  AND A
  JR NZ,ParseSentence     ; more of the line: parse the next sentence
  JP MainLoop             ; the line is used up: read the next

; Report an unknown word and read the next line
UnknownWord:
  LD HL,MsgIDoNotKnow     ; MsgIDoNotKnow
  LD A,$01
  LD (RawOutputFlag),A    ; RawOutputFlag: print in the input window
  CALL PrintMessage       ; `I do not know the word "`
  LD HL,(InputLinePtr)    ; InputLinePtr: the start of the unknown word
UnknownWord_0:
  LD A,(HL)
  CP CHAR_CR
  JR Z,UnknownWord_1
  CP CHAR_QUOTE
  JR Z,UnknownWord_1
  CALL PrintChar          ; PrintChar: echo the word up to the next space
  INC HL
  CP CHAR_SPACE
  JR NZ,UnknownWord_0
UnknownWord_1:
  LD A,CHAR_QUOTE         ; the closing quote
  CALL PrintChar
  CALL PrintNewLine       ; PrintNewLine
  JP MainLoop             ; read another line

; Border strip tile: 5 pixel rows of 2 bytes
;
; Drawn 16 times across five pixel rows at $5140 by the start code ($6CD3): the
; line under the title.
BorderTile:
  DEFB $C3,$C3
  DEFB $2C,$34
  DEFB $10,$08
  DEFB $2C,$34
  DEFB $C3,$C3

; Read a typed line from the keyboard
;
; The line editor. Prints the prompt "> " in the input window, then reads keys
; (WaitKey, which types WAIT by itself when the player is idle) and builds the
; line in InputLine ($6FF9, up to 128 characters, closed by a CR that is stored
; in the buffer).
;
; Keys: a cursor key as the first key of a line becomes a one-letter compass
; command (CursorKeyToWord: up N, down S, right E, left W) and ends the line.
; DELETE (CAPS SHIFT+0) erases the whole line (EraseInputLine). Back-space (the
; left cursor key) removes the last character. Characters are accepted when
; they are letters or later ($40 and up), a space, a double quote, a full stop,
; a comma or the CR; digits and other punctuation are ignored. "@" as the first
; key of an empty line repeats the previous line (L6E7A). Each accepted
; character is echoed in the input window; its code is also stored in
; CapitalNext, which is then not 0, so the next story text starts with a
; capital (the code itself does not matter). When the buffer is full further
; characters are ignored until CR.
;
; Hardware: polls the keyboard (through WaitKey) and echoes in the input window
; (the output goes there because RawOutputFlag is set).
;
; O:A CR after a typed line, 0 after "@"
; O:F NZ when a line was typed (InputLine holds it), Z when "@" asked for the
;     previous line
ReadLine:
  LD HL,IDLE_SCANS_MAX
  LD (IdleCounter),HL     ; IdleCounter: start counting the idle time
  LD A,$01
  LD (RawOutputFlag),A    ; RawOutputFlag: echo in the input window
  LD (ActionPerform),A    ; ActionPerform
  LD A,CHAR_PROMPT
  CALL PrintChar          ; PrintChar
  LD A,CHAR_SPACE
  CALL PrintChar
  LD HL,InputLine         ; InputLine
  LD B,INPUT_LINE_SIZE    ; B: free bytes in the buffer, bit 7 set while empty
ReadLine_Start:
  LD C,$00                ; C: 0 until the first key of the line is in
; This entry point is used by the routine at L6E7A.
ReadLine_Key:
  CALL WaitKey            ; WaitKey
  BIT 7,B
  JR Z,ReadLine_0
  CP CHAR_AT              ; "@" on an empty line ...
  JP Z,L6E7A              ; ... repeats the previous line
ReadLine_0:
  BIT 0,C
  CALL Z,CursorKeyToWord  ; first key of the line: CursorKeyToWord
  LD C,$01
  CP KEY_DELETE
  JR NZ,ReadLine_1
  CALL EraseInputLine     ; EraseInputLine
  JR ReadLine_Start       ; and start the line again
ReadLine_1:
  CP CHAR_BACKSPACE
  JR NZ,ReadLine_2
  BIT 7,B
  JR NZ,ReadLine_Key      ; empty line: nothing to remove
  LD A,CHAR_BACKSPACE
  CALL PrintChar          ; rub out the last character on the screen
  INC B
  DEC HL
  JR ReadLine_Key
ReadLine_2:
  CP CHAR_AT
  JR NC,ReadLine_Accept   ; letters and later: accept
  CP CHAR_QUOTE
  JR Z,ReadLine_Accept
  CP CHAR_SPACE
  JR Z,ReadLine_Accept
  CP CHAR_CR
  JR Z,ReadLine_Accept
  CP CHAR_FULLSTOP
  JR Z,ReadLine_Accept
  CP CHAR_COMMA
  JR NZ,ReadLine_Key      ; anything else: ignore the key
ReadLine_Accept:
  LD (CapitalNext),A      ; CapitalNext: not 0, the next story text starts with
                          ; a capital
  DEC B
  INC B
  JR Z,ReadLine_3         ; buffer full: do not store
  CALL PrintChar          ; echo
  LD (HL),A
  INC HL
  DEC B
ReadLine_3:
  CP CHAR_CR
  JP NZ,ReadLine_Key      ; until CR
  OR $01                  ; NZ: a line was typed
  RET
