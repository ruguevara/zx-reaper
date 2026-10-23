; Run the handler of a special typed word (all, except, it, load, save...)
;
; The dispatcher ParseNextWord sends the words of class 9 here. Looks the
; word's dictionary offset up in ActionWordTable (13 pairs) and jumps to the
; matching handler in ActionHandlerTable. A word that is not in the table goes
; on with the ordinary processing at StartPhraseRecord.
;
; Hardware: none.
;
; C Low byte of the word's dictionary offset (from ReadWord)
; B High byte of the word's dictionary offset
; DE Kept for the handler
DispatchSpecialWord:
  LD HL,ActionWordTable
  PUSH DE                 ; kept for the handler
  LD D,$0D                ; 13 pairs
DispatchSpecialWord_0:
  LD A,(HL)
  INC HL
  CP C
  JR NZ,DispatchSpecialWord_1
  LD A,(HL)
  CP B
  JR Z,DispatchSpecialWord_2
DispatchSpecialWord_1:
  INC HL
  DEC D
  JR NZ,DispatchSpecialWord_0
  JP StartPhraseRecord    ; not a special word (not executed with the inputs in
                          ; re/maps)
DispatchSpecialWord_2:
  LD DE,$0019             ; HL is at the pair's second byte; +$19 reaches
                          ; ActionHandlerTable+2n
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  POP DE
  JP (HL)                 ; run the handler; it ends with JP ParseNextWord or
                          ; its own exit

; Action word table (13 pairs) and handler addresses (13)
;
; $8251 looks up the pair (C, B) from $7873 in the 13 pairs at $8271 (two bytes
; each, the first pair is (0,0)) and jumps to the word at +$19 ($828B+2n).
ActionWordTable:
  DEFB $00,$00
  DEFB $4E,$00
  DEFB $45,$02
  DEFB $9E,$03
  DEFB $AD,$04
  DEFB $FB,$04
  DEFB $79,$04
  DEFB $EE,$03
  DEFB $80,$05
  DEFB $18,$05
  DEFB $1E,$03
  DEFB $8A,$05
  DEFB $D8,$04
ActionHandlerTable:
  DEFW StoreParsedOrders
  DEFW WordAll
  DEFW WordExcept
  DEFW L82E2
  DEFW ParseNextWord
  DEFW WordPrint
  DEFW L82AF
  DEFW LoadGame
  DEFW SaveGame
  DEFW WordQuit
  DEFW WordHelp
  DEFW L83EF
  DEFW WordPause

; Handler of the word "print": switch the ZX printer on
;
; Sets PrinterFlag to 1 when a printer answers on port $FB (bit 6 clear). An
; open bus reads $FF, so with no printer the flag stays as it was. Then goes on
; with the next word. The word "noprint" is L82AF.
;
; Hardware: reads the ZX printer port $FB.
WordPrint:
  IN A,(PORT_PRINTER)
  BIT 6,A                 ; the ROM tests this bit for "no printer" too
  JR NZ,ResumeDispatch
  LD A,$01                ; A=1 stored by the code at L82AF+1
  JR L82AF_0              ; into PrinterFlag

; Command handler: clear ($B6F2) (table $828B)
L82AF:
  XOR A
L82AF_0:
  LD (PrinterFlag),A

; Return from a word handler to the dispatcher
;
; Takes the class nibble of the last word read (WordFlags) back into D and
; continues at the dispatcher's next-word step ParseNextWord.
;
; Hardware: none.
;
; O:D WordFlags, the high nibble of the last word read
ResumeDispatch:
  LD A,(WordFlags)
  LD D,A
  JP ParseNextWord

; Handler of the word EXCEPT
;
; Allowed only after ALL (AllStage = ALL_STATE_ALL): AllStage becomes
; ALL_STATE_EXCEPT and the phrase record at IY gets the flag bit 7 (RECF_ALL)
; in its byte +1, then the parser goes on with the next word (ParseNextWord).
; After anything else the line is refused with "What ?" (RejectLine).
;
; Hardware: none.
;
; IY Phrase record being built
WordExcept:
  LD A,(AllStage)         ; AllStage
  CP ALL_STATE_ALL
  JP NZ,RejectLine        ; no ALL before: "What ?"
  LD A,ALL_STATE_EXCEPT
  LD (AllStage),A         ; AllStage
  LD A,(IY+$01)           ; record flags
  OR $01<<RECF_ALL        ; bit 7
  LD (IY+$01),A
  JP ParseNextWord        ; next word

; Handler of the word "all" (also "everything")
;
; Records that ALL was typed: AllStage becomes 1, unless "except" has been seen
; already (2). The state is cleared at the start of each phrase
; (ClearAllStage). Then goes on with the next word.
;
; Hardware: none.
WordAll:
  LD A,(AllStage)
  CP ALL_STATE_EXCEPT
  JP Z,ParseNextWord
  LD A,ALL_STATE_ALL
  LD (AllStage),A
  JP ParseNextWord

; Command handler: copy 6 bytes $B6E0 to $757F, then dispatch (table $828B)
L82E2:
  PUSH DE
  LD HL,PhraseBuffer
  LD DE,ActionSlots+$0004
  LD BC,$0006
  LDIR
  POP DE
  BIT 7,E
  CALL L82E2_0
  JP ParseNextWord
L82E2_0:
  JP Z,StorePhraseBlock_0
  JP StoreFirstPhraseBlock

; Start the second pass over a stored order
;
; Reached from StoreParsedOrders when the end of a phrase is met while
; InputFromOrder is 0 (seen with SAY TO THORIN "GIVE MAP TO ME", frame 14895 of
; verbs.txt). Keeps D, DE, BC, IY and ParserWordCount, moves IY back one phrase
; record ($18 bytes) and re-enters the dispatcher at ParseLineFrom with
; InputFromOrder = 1. StoreParsedOrders then stores the phrases parsed since in
; the order slots at $B738.
;
; Hardware: none.
;
; D Class nibble of the last word, kept in PicVar2 ($824F)
; IY Phrase record being built
BeginOrderPass:
  LD A,D
  LD (PicVar2),A          ; kept in PicVar2 ($824F)
  PUSH DE
  PUSH BC
  PUSH IY
  LD A,(ParserWordCount)
  LD (PicVar3),A          ; ParserWordCount kept in PicVar3 ($8250)
  LD DE,$FFE8             ; IY back one phrase record
  ADD IY,DE
  LD A,$01                ; A=1 becomes InputFromOrder at ParseLineFrom
  JP ParseLineFrom

; Handle the end of the typed words: store the orders of a SAY TO line
;
; The handler of the special word with dictionary offset 0, the end of the word
; list (first entry of ActionWordTable). It works together with BeginOrderPass
; to parse a SAY TO line twice (seen with SAY TO THORIN "GIVE MAP TO ME", frame
; 14895 of verbs.txt). With InputFromOrder ($B71B) 0 it only starts the second
; pass (BeginOrderPass). With InputFromOrder 1 the second pass has ended: it
; clears the flag and works out how many phrase records were parsed since the
; pass began (ParserWordCount minus PicVar3, the count kept by BeginOrderPass).
; Each of them, newest first, is copied into a free order slot of OrderSlots
; (the owner byte first, set to $FF = pending, then the 24 bytes of the
; record). A record whose bit 6 of +1 is set is not kept: its slot is freed
; again. It stops when no slot is free. The number of slots used goes to
; OrderSlotCount for ClaimOrderSlots, which gives them to the character
; addressed. Finally it clears AllStage, restores ParserWordCount and returns
; to the dispatcher at ParseNextWord with the word class that BeginOrderPass
; saved in PicVar2.
;
; Hardware: none.
;
;   InputFromOrder ($B71B) 0 first pass, 1 second pass
;   PicVar2 ($824F) Class nibble of the last word, from BeginOrderPass
;   PicVar3 ($8250) ParserWordCount when the second pass began, from
;           BeginOrderPass
;   stack IY, BC, DE as pushed by BeginOrderPass
; O:D Class nibble of the last word
; O:OrderSlotCount Number of slots filled
StoreParsedOrders:
  LD A,(InputFromOrder)   ; InputFromOrder
  AND A
  JR Z,BeginOrderPass     ; 0: start the second pass
  DEC A                   ; second pass over:
  LD (InputFromOrder),A   ; InputFromOrder = 0
  LD A,(PicVar3)          ; PicVar3: count when the pass began
  LD B,A
  LD A,(ParserWordCount)  ; ParserWordCount
  SUB B                   ; A = records parsed in the pass
  AND A
  LD C,$00                ; C counts the slots used
  JR Z,StoreParsedOrders_Done ; none: nothing to store
  POP IY                  ; IY = the saved IY
  PUSH IY
  LD DE,-PARSED_RECORD_SIZE ; one phrase record back
  ADD IY,DE
  LD B,A                  ; B = records to store
StoreParsedOrders_Record:
  LD IX,OrderSlots        ; first slot
  PUSH DE
  PUSH BC
  LD DE,ORDER_SLOT_SIZE   ; slot size
  LD B,ORDER_SLOTS
StoreParsedOrders_Find:
  LD A,(IX+$00)           ; look for a free slot
  AND A
  JR Z,StoreParsedOrders_0
  ADD IX,DE               ; next slot
  DJNZ StoreParsedOrders_Find
StoreParsedOrders_0:
  LD (IX+$00),FLAG_SLOT_PENDING ; take it: pending
  INC IX
  POP BC
  POP DE
  JR NZ,StoreParsedOrders_Done ; NZ: no free slot, stop
  BIT 6,(IY+$01)          ; record flag (+1 bit 6): not to keep
  JR Z,StoreParsedOrders_Copy
  LD (IX-$01),ORDER_SLOT_FREE ; free the slot again
  JR StoreParsedOrders_2
StoreParsedOrders_Copy:
  PUSH BC
  LD B,PARSED_RECORD_SIZE ; copy the 24 bytes of the record
StoreParsedOrders_1:
  LD A,(IY+$00)
  LD (IX+$00),A
  INC IY
  INC IX
  DJNZ StoreParsedOrders_1
  POP BC
  ADD IY,DE               ; IY back to the start of the record
StoreParsedOrders_2:
  ADD IY,DE               ; and one record further back
  INC C                   ; slots used
  DJNZ StoreParsedOrders_Record
StoreParsedOrders_Done:
  XOR A                   ; AllStage = 0
  LD (AllStage),A
  LD A,C
  LD (OrderSlotCount),A   ; OrderSlotCount
  POP IY                  ; IY from before
  LD A,(PicVar3)          ; PicVar3 back into ParserWordCount
  LD (ParserWordCount),A
  POP BC                  ; BC, DE from BeginOrderPass
  POP DE
  LD A,(PicVar2)          ; PicVar2: the class nibble
  LD D,A
  JP ParseNextWord        ; on with the next word

; Handler of the word QUIT
;
; Prints the score (PrintScore), waits for a key and restarts the game at
; RestartGame, which restores the starting state and the title wait.
;
; Hardware: reads the keyboard port $FE (all half-rows) in a polling loop.
WordQuit:
  CALL PrintScore         ; "You have mastered ..% Of this adventure."
WordQuit_Wait:
  XOR A                   ; A = 0 selects every half-row
  IN A,(PORT_ULA)
  AND KEY_BITS
  CP KEY_BITS             ; no key down
  JR Z,WordQuit_Wait
  JP RestartGame          ; restart the game

; Handler of the word HELP
;
; For the player (a hint is never given to an order for someone else; those
; skip to the next word) prints the hint for the player's location from
; HintTable ("A trolls door needs a trolls key." in the trolls path, for
; instance), or "You're doing fine." when the location has no hint. Prints in
; the input window (RawOutputFlag = 1). Then returns to the dispatcher
; (ResumeDispatch).
;
; Hardware: none.
WordHelp:
  LD A,(Subject)          ; actor
  AND A
  JP NZ,ParseNextWord     ; not the player: next word
  PUSH HL
  PUSH IX
  LD HL,MsgReDoingFine    ; "You're doing fine."
  LD A,(Chr00PlayerLocation) ; player location (first byte of its location
                             ; list)
  LD IX,HintTable
  CALL FindIdRecord       ; find the hint
  JR Z,WordHelp_Print     ; none: keep the default
  LD L,(IX+$01)
  LD H,(IX+$02)
WordHelp_Print:
  LD A,$01                ; RawOutputFlag: input window
  LD (RawOutputFlag),A
  CALL PrintMessage
  POP IX
  POP HL
  JP ResumeDispatch

; HELP hints by location (11 records)
;
; Records of 3 bytes: location id, hint message address; $FF ends. HELP
; (WordHelp) looks up the player's location ($C12B) with FindIdRecord and
; prints the hint, or "You're doing fine." when there is none.
HintTable:
  DEFB $06
  DEFW LB47A
  DEFB $09
  DEFW LB48A
  DEFB $0D
  DEFW LB49A
  DEFB $42
  DEFW LB4BE
  DEFB $1F
  DEFW LB4CA
  DEFB $20
  DEFW LB4DA
  DEFB $2A
  DEFW LB4FA
  DEFB $2E
  DEFW LB504
  DEFB $29
  DEFW LB518
  DEFB $1A
  DEFW LB52F
  DEFB $05
  DEFW LB53E
  DEFB $FF

; Command handler (via $828B): call $83F5, then $82B3
L83EF:
  CALL PrintScore
  JP ResumeDispatch

; Print the score as a percentage of the adventure
;
; Prints "You have mastered " (message $B454), the Score ($B6F7) as hundreds
; digit (left out when 0), tens digit, a full stop and the units digit, and
; then "% Of this adventure." (message $B462), so the score is kept in tenths
; of a percent (finding F24). Digits come from DecimalDigit and go out one by
; one through PrintChar. Used by the SCORE word (L83EF), by QUIT (WordQuit) and
; by the death and ending code (EndGame). Clears RawOutputFlag first and
; CapitalNext after the number.
;
; Hardware: none (text output goes through the message printer).
;
; Score ($B6F7) Word, tenths of a percent
; HL, DE are preserved
PrintScore:
  PUSH HL
  PUSH DE
  XOR A
  LD (RawOutputFlag),A    ; RawOutputFlag = 0
  LD HL,MsgHaveMastered   ; "You have mastered "
  CALL PrintMessage
  LD HL,(Score)           ; Score
  LD DE,$0064             ; hundreds
  CALL DecimalDigit       ; A = digit, Z if 0
  CALL NZ,PrintChar       ; print it unless it is 0
  LD DE,$000A             ; tens
  CALL DecimalDigit
  CALL PrintChar          ; print it
  LD A,'.'                ; full stop
  CALL PrintChar
  LD A,L                  ; units: the remainder
  ADD A,'0'
  CALL PrintChar
  XOR A                   ; CapitalNext = 0
  LD (CapitalNext),A
  LD HL,MsgThisAdventure  ; "% Of this adventure."
  CALL PrintMessage
  POP DE
  POP HL
  RET

; Next decimal digit by repeated subtraction
;
; Divides HL by DE with a loop of subtractions and returns the quotient as an
; ASCII digit (the quotient must be below 10). The caller prints the digit with
; PrintChar, skipping it when it is "0" for the leading hundreds place of the
; score.
;
; Hardware: none.
;
;   HL Number
;   DE Divisor (100, then 10)
; O:A ASCII digit "0"-"9"
; O:HL Remainder
; O:F Z set when the digit is "0"
DecimalDigit:
  LD A,'0'-$01
DecimalDigit_0:
  INC A
  AND A
  SBC HL,DE
  JR NC,DecimalDigit_0
  ADD HL,DE
  CP '0'
  RET

; PAUSE: wait for a key with a green border
;
; The handler of the word PAUSE (via ActionHandlerTable). Sets the border
; green, waits for a key to be pressed (WaitForKey) and then for it to be
; released, sets the border white again and goes on with the dispatcher
; (ResumeDispatch).
;
; Hardware: writes the border (port $FE) and reads the keyboard port.
WordPause:
  LD A,BORDER_GREEN       ; green border
  OUT (PORT_ULA),A
  CALL WaitForKey         ; wait for a key press
WordPause_0:
  XOR A                   ; wait until all keys are up
  IN A,(PORT_ULA)
  AND KEY_BITS
  CP KEY_BITS
  JR NZ,WordPause_0
  LD A,BORDER_WHITE       ; white border again
  OUT (PORT_ULA),A
  JP ResumeDispatch       ; back to the dispatcher

; Load a saved game from tape
;
; Handler of the word LOAD. Reads the four saved-state blocks with LoadBlock in
; the order SavedScriptBytes, Chr00Player, Timers, Loc00None, then puts the
; three Bard script bytes back at $C9E2 (CopyScriptBytes) and returns to the
; dispatcher. The blocks are read straight over the live game state, so a tape
; error (handled in LoadBlock) restarts the program.
;
; Hardware: the ROM tape loader (LD-BYTES, through LoadBlock); it re-enables
; interrupts, so the routine executes DI after the last block.
LoadGame:
  PUSH IX
  PUSH DE
  LD A,TAPE_FLAG_DATA     ; flag byte of the block
  SCF                     ; carry set: load (not verify)
  LD IX,SavedScriptBytes  ; saved variables
  LD DE,STATE_VARS_SIZE
  CALL LoadBlock
  LD A,TAPE_FLAG_DATA
  SCF
  LD IX,Chr00Player       ; object and character records
  LD DE,STATE_OBJECTS_SIZE
  CALL LoadBlock
  LD A,TAPE_FLAG_DATA
  SCF
  LD IX,Timers            ; timers and NPC records
  LD DE,STATE_TIMERS_SIZE
  CALL LoadBlock
  LD A,TAPE_FLAG_DATA
  SCF
  LD IX,Loc00None         ; location records
  LD DE,STATE_LOCATIONS_SIZE
  CALL LoadBlock
  DI                      ; the ROM returned with interrupts on
  LD HL,SavedScriptBytes  ; copy the script bytes back from SavedScriptBytes
  LD DE,BardCommandOp     ; to the script area
  CALL CopyScriptBytes
  POP DE
  POP IX
  JP ResumeDispatch

; Load one block from tape, restart the game on an error
;
; Calls the ROM's LD-BYTES. If it reports success (carry set) the routine
; returns. If the block is bad or the load is stopped, it prints "Tape error -
; hit any key to restart program." in the input window, waits for a key and
; jumps to RestartGame, which restores the starting state and begins a new
; game: the blocks already read have overwritten the running game.
;
; Hardware: the ROM tape loader LD-BYTES; the keyboard port $FE.
;
;   A Flag byte of the block
;   F Carry set to load
;   IX Address to load to
;   DE Length of the block
; O:F Carry set when loaded (otherwise the routine does not return)
LoadBlock:
  CALL LD_BYTES
  RET C                   ; loaded
  LD A,$01
  LD (RawOutputFlag),A    ; print in the input window
  LD HL,MsgTapeErrorHitAnyKey ; "Tape error -     hit any key to restart
                              ; program."
  CALL PrintMessage
LoadBlock_WaitKey:
  XOR A                   ; select all keyboard half-rows
  IN A,(PORT_ULA)
LoadBlock_0:
  AND KEY_BITS
  CP KEY_BITS
  JR Z,LoadBlock_WaitKey  ; no key down yet
  JP RestartGame          ; restart

; Copy the three script bytes
;
; Copies 3 bytes from HL to DE: the command bytes at $C9E2 (not part of the
; saved state) to SavedScriptBytes before SAVE, and back after LOAD.
;
; Hardware: none.
;
; HL Source
; DE Destination
CopyScriptBytes:
  LD BC,$0003
  LDIR
  RET

; Wait for a key press
;
; Waits until no key is down, then until any key is down. Reads all eight
; keyboard half-rows at once (A = 0 selects them all).
;
; Hardware: reads the keyboard port $FE.
WaitForKey:
  XOR A
  IN A,(PORT_ULA)
  AND KEY_BITS
  CP KEY_BITS
  JR NZ,WaitForKey        ; a key is down: wait for release
WaitForKey_0:
  XOR A
  IN A,(PORT_ULA)
  AND KEY_BITS
  CP KEY_BITS
  JR Z,WaitForKey_0       ; no key down: wait for a press
  RET

; Save the game to tape and verify it
;
; Handler of the word SAVE. Copies the three Bard script bytes from $C9E2 to
; SavedScriptBytes (CopyScriptBytes), prints "Start tape then press any key."
; in the input window, waits for a key and writes the four state blocks with
; the ROM's SA-BYTES in the same order and with the same lengths that LoadGame
; loads: SavedScriptBytes, Chr00Player, Timers, Loc00None. Then prints "Rewind
; and prepare tape for verification -- then hit any key.", waits for a key and
; checks the four blocks against memory with VerifyBlock (LD-BYTES with carry
; clear), which reports a mismatch itself and ends the command through
; SaveGame_End. The blocks have no header, only the flag byte $FF.
;
; Hardware: the ROM tape routines SA-BYTES and LD-BYTES (they re-enable
; interrupts, so the routine executes DI at the end); the keyboard port $FE.
SaveGame:
  PUSH IX
  PUSH DE
  LD DE,SavedScriptBytes  ; copy the script bytes from the script area
  LD HL,BardCommandOp     ; to SavedScriptBytes
  CALL CopyScriptBytes
  LD A,$01
  LD (RawOutputFlag),A    ; print in the input window
  LD HL,MsgStartTapeThenPressAny ; "Start tape then press any key."
  CALL PrintMessage
  CALL WaitForKey         ; wait for a key
  LD A,TAPE_FLAG_DATA     ; flag byte of the block
  LD IX,SavedScriptBytes  ; saved variables
  LD DE,STATE_VARS_SIZE
  CALL SA_BYTES
  LD A,TAPE_FLAG_DATA
  LD IX,Chr00Player       ; object and character records
  LD DE,STATE_OBJECTS_SIZE
  CALL SA_BYTES
  LD A,TAPE_FLAG_DATA
  LD IX,Timers            ; timers and NPC records
  LD DE,STATE_TIMERS_SIZE
  CALL SA_BYTES
  LD A,TAPE_FLAG_DATA
  LD IX,Loc00None         ; location records
  LD DE,STATE_LOCATIONS_SIZE
  CALL SA_BYTES
  LD HL,MsgRewindPrepareTapeFor ; "Rewind and prepare tape for verification --
                                ; then hit any key."
  CALL PrintMessage
  CALL WaitForKey         ; wait for a key
  LD A,TAPE_FLAG_DATA
  AND A                   ; carry clear: verify
  LD IX,SavedScriptBytes
  LD DE,STATE_VARS_SIZE
  CALL VerifyBlock
  LD A,TAPE_FLAG_DATA
  AND A
  LD IX,Chr00Player
  LD DE,STATE_OBJECTS_SIZE
  CALL VerifyBlock
  LD A,TAPE_FLAG_DATA
  AND A
  LD IX,Timers
  LD DE,STATE_TIMERS_SIZE
  CALL VerifyBlock
  LD A,TAPE_FLAG_DATA
  AND A
  LD IX,Loc00None
  LD DE,STATE_LOCATIONS_SIZE
  CALL VerifyBlock
; This entry point is used by the routine at VerifyBlock.
SaveGame_End:
  DI                      ; the ROM returned with interrupts on
  POP DE
  POP IX
  JP ResumeDispatch

; Verify one tape block of SAVE
;
; Compares a block on tape with memory through the ROM's LD-BYTES (carry clear
; on entry means verify). Called by SaveGame for each of the four state blocks,
; with the block address in IX, its length in DE and the flag byte in A. When
; the block is right returns to SaveGame. When it differs prints "Tape error -
; hit any key to continue.", waits for a key and ends the SAVE command at
; SaveGame_End: the POP DE drops the return address into SaveGame, so the
; command ends here.
;
; Hardware: the ROM tape routine (LD-BYTES; it returns with interrupts on); the
; keyboard port $FE.
;
; A Flag byte of the block
; F Carry clear: verify
; IX Address of the block
; DE Length of the block
VerifyBlock:
  CALL LD_BYTES           ; ROM LD-BYTES, verify
  RET C                   ; carry set: the block matched
  LD A,$01                ; RawOutputFlag: input window
  LD (RawOutputFlag),A
  LD HL,MsgTapeErrorHitAnyKey2 ; "Tape error - hit any key to continue."
  CALL PrintMessage
VerifyBlock_Wait:
  XOR A                   ; A = 0 selects every half-row
  IN A,(PORT_ULA)
  AND KEY_BITS
  CP KEY_BITS
  JR Z,VerifyBlock_Wait
  POP DE                  ; drop the return address
  JP SaveGame_End         ; SaveGame_End: end the command
