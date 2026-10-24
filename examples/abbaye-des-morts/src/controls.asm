; Turn the keyboard row buffer into control bits
;
; Walks the 8 (row, mask) pairs of the key table ControlKeys: bit n of the
; result is set when the key of pair n is held, that is when its mask bit is 0
; in the half-row byte of KeyRows (read by ScanKeyboard). The bits are RIGHT,
; LEFT, CROUCH, JUMP, JUMP (again), then the fixed keys T (debug warp when the
; cheat is on), R and Y (R and Y together abort the game). The result is stored
; in ControlsRead.
;
; The byte at KempstonSwitch that ends this routine is a RET when no Kempston
; joystick is used and a NOP when it is: then the code runs on into
; ReadKempston, which adds the joystick bits to E.
;
; Hardware: none itself; the ports were read by ScanKeyboard. The routine
; executes an odd number of EXX, so it returns with the other register set
; selected (the alternate set is used for the loop counter and the result
; bits); the caller GameFrame does not rely on either set.
;
; O:E Control bits (bit n = key pair n held), for ReadKempston that follows
ReadKeyControls:
  LD BC,ControlKeys
  LD DE,KeyRows
  EXX
  LD B,CONTROL_KEYS       ; eight key pairs
ReadKeyControls_Pair:
  EXX                     ; next key pair (loop 8 times)
  LD A,(BC)               ; row index of the pair
  INC BC
  LD L,A
  LD H,$00
  ADD HL,DE
  LD A,(BC)               ; mask of the pair
  INC BC
  AND (HL)                ; 0 when the key is held (bit = 0)
  CP $01                  ; carry set when the key is held
  EXX
  RR E                    ; shift the carry into the result, first pair ends in
                          ; bit 0
  DJNZ ReadKeyControls_Pair
  LD A,E
  LD (ControlsRead),A
; RET when the Kempston joystick is off, NOP when it is on. Set at start-up by
; StartUp (a read of port $1F that never shows a joystick bit means a joystick
; is present) and toggled by ToggleKempston.
KempstonSwitch:
  RET                     ; NOP: fall into ReadKempston

; Add the Kempston joystick to the control bits
;
; Reached only by falling through from KempstonSwitch when it holds a NOP.
; Reads the Kempston port and keeps right, left, down and fire (bits 0, 1, 2
; and 4); joystick up (bit 3) is ignored. Fire lands in bit 4, the second JUMP
; bit, so it jumps like the JUMP key. The bits are ORed into the keyboard
; result and stored in ControlsRead.
;
; Hardware: reads the Kempston joystick port $1F.
;
; E Keyboard control bits from ReadKeyControls
ReadKempston:
  LD BC,PORT_KEMPSTON
  IN A,(C)
  AND KEMPSTON_MASK       ; right, left, down, fire
  OR E
  LD (ControlsRead),A
  RET

; Find the first key held in the row buffer
;
; Scans the 8 half-rows of KeyRows in order (port high bytes $FE, $FD, $FB,
; $F7, $EF, $DF, $BF, $7F) and in each row the five key bits from bit 4 down to
; bit 0, and stops at the first key that is held (bit = 0). The caller
; (MenuFrame) stores the result for the key redefinition (RedefineOneKey). Note
; that GetKeyCode, which gives the key's code, scans each row from bit 0 up, so
; with two keys held in one row the two routines can pick different keys
; (observed: P and I held give the name P and the key I, F127).
;
; O:B Row index of the key (0-7), 0 when no key is held
; O:C Bit mask of the key within its half-row ($10, 8, 4, 2 or 1), 0 when no
;     key is held
FindPressedKey:
  LD HL,KeyRows
  LD B,KEY_ROWS           ; row counter (counts down from 8)
FindPressedKey_Row:
  LD C,$10                ; start of a row: first mask $10
FindPressedKey_Bit:
  LD A,(HL)
  AND C
  CP $01                  ; carry set when the key is held
  JR C,FindPressedKey_0
  RRC C                   ; next mask; carry out after $01
  JR NC,FindPressedKey_Bit
  INC HL
  DJNZ FindPressedKey_Row
  LD C,B                  ; no key held: BC = 0
  RET
FindPressedKey_0:
  LD A,$08                ; row index = 8 - counter
  SUB B
  LD B,A
  RET

; Cheat check: 4 (row, mask) pairs that spell RAGE ($A422)
;
; The four key pairs, in the order of the first four pairs of ControlKeys
; (RIGHT, LEFT, CROUCH, JUMP), that CheckCheatKeys compares with the redefined
; keys: (2, 4) = E, (1, $10) = G, (1, 1) = A, (2, 8) = R. Typed in the order of
; the redefinition prompts (JUMP, CROUCH, LEFT, RIGHT) the keys spell RAGE.
;
; Each pair is a keyboard half-row index (0-7, see KeyRows) and a key bit mask
; within it.
CheatKeyPairs:
  DEFB $02,$04            ; RIGHT = E
  DEFB $01,$10            ; LEFT = G
  DEFB $01,$01            ; CROUCH = A
  DEFB $02,$08            ; JUMP = R

; Control keys: 8 (half-row index, bit mask) pairs
;
; Pair n gives the key for control bit n (see ControlsRead); ReadKeyControls
; tests each pair against the row buffer at KeyRows. The values here are the
; defaults (QAOP); RedefineOneKey overwrites the first four pairs when the
; player redefines the keys and TitleMenu copies the JUMP pair into the fifth.
; Each pair is +0 byte: half-row index 0-7 (port high bytes $FE, $FD, $FB, $F7,
; $EF, $DF, $BF, $7F), +1 byte: bit mask of the key in that half-row (bit 0 is
; the key nearest the edge).
;
; The last three pairs are fixed: T, R and Y.
ControlKeys:
  DEFB $05,$01            ; bit 0 RIGHT: P
KeyLeft:
  DEFB $05,$02            ; bit 1 LEFT: O
KeyCrouch:
  DEFB $01,$01            ; bit 2 CROUCH: A
KeyJump:
  DEFB $02,$01            ; bit 3 JUMP: Q
KeyJumpCopy:
  DEFB $02,$01            ; bit 4 JUMP again: a copy of the pair above (the
                          ; Kempston fire bit is bit 4)
KeyWarp:
  DEFB $02,$10            ; bit 5 fixed: T, the debug room warp (only if the
                          ; cheat is on)
KeyAbortR:
  DEFB $02,$08            ; bit 6 fixed: R, with Y it ends the game
KeyAbortY:
  DEFB $05,$10            ; bit 7 fixed: Y

; Control bits read this frame
;
; Stored by ScanKeyboard (any key held, bits 0-4), then by ReadKeyControls and,
; with a joystick, ReadKempston. Bit 0 RIGHT, 1 LEFT, 2 CROUCH, 3 and 4 JUMP, 5
; T (debug warp), 6 R, 7 Y. Read directly by the intro loop RunIntro.
ControlsRead:
  DEFB $00

; Control bits held after this frame's update
;
; A copy of ControlsRead made by GameFrame once it has computed the newly
; pressed bits, so at the start of that routine it still holds the previous
; frame's bits and everywhere else (the player routines) the bits held now.
; Same bit layout as ControlsRead.
ControlsHeld:
  DEFB $00

; Control bits newly pressed this frame
;
; Bits that are set in ControlsRead and were not in the previous frame,
; computed by GameFrame. Used for the jump (bits 3 and 4, PlayerStanding) and
; the debug warp: T (bit 5) enters and leaves it (UpdatePlayer, DebugWarpRoom)
; and in the warp mode the direction bits 0-3 move one room (DebugWarpRoom).
; Same bit layout as ControlsRead.
ControlsPressed:
  DEFB $00

; Code of the key held now (0 = none)
;
; Set by GetKeyCode from the key code table KeyCodeTable. Updated every
; interrupt only while the menu frame routine MenuFrame is installed, and by
; the intro loop RunIntro; the menus wait on it.
KeyCode:
  DEFB $00

; Keyboard half-row buffer: 8 bytes
;
; Filled by ScanKeyboard with eight INI reads of port $FE, one per half-row, in
; the order of the port high bytes $FE, $FD, $FB, $F7, $EF, $DF, $BF, $7F: row
; 0 CAPS SHIFT Z X C V, row 1 A S D F G, row 2 Q W E R T, row 3 1 2 3 4 5, row
; 4 0 9 8 7 6, row 5 P O I U Y, row 6 ENTER L K J H, row 7 SPACE SYMBOL SHIFT M
; N B. Bits 0-4 are the keys, bit 0 the one nearest the edge; a bit is 0 while
; its key is held.
KeyRows:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

; Key code table in scan order
;
; The code of each key in the order GetKeyCode scans the row buffer (row 0 bit
; 0 first): CAPS SHIFT = $01, then the letters and digits as ASCII, ENTER =
; $0D, SPACE = $20, SYMBOL SHIFT = $02; 40 codes, then a 0 that is returned
; when no key is held.
KeyCodeTable:
  DEFM $01,"ZXCVASDFGQWERT1234509876POIUY",$0D,"LKJH ",$02,"MNB",$00

; Find the code of the key held now
;
; Scans the 8 half-rows of KeyRows, bit 0 to bit 4 in each, and takes the code
; of the first key held (bit = 0) from KeyCodeTable; with no key held it
; reaches the 0 after the table. The code is stored in KeyCode.
;
; Hardware: none (the ports were read by ScanKeyboard).
GetKeyCode:
  LD DE,KeyCodeTable
  LD HL,KeyRows
  LD C,KEY_ROWS           ; rows left
GetKeyCode_Row:
  LD A,(HL)
  INC HL
  LD B,$05                ; five keys per row
GetKeyCode_Key:
  RRA                     ; bit 0 into carry
  JR NC,GetKeyCode_Found  ; carry clear: this key is held
  INC DE                  ; next code
  DJNZ GetKeyCode_Key
  DEC C
  JR NZ,GetKeyCode_Row
GetKeyCode_Found:
  LD A,(DE)
  LD (KeyCode),A
  RET

; Title: SPACE held, show the info screen until it is released (128K only)
;
; Called from TitleMenu when SPACE is pressed on the title screen. On the 48K
; the first byte is a RET, so SPACE does nothing. On the 128K the start-up code
; Patch128KHooks turns the RET into CALL $85EE (the two bytes after it are that
; address), BankShowInfo: the music bank unpacks the info screen ($CA8A); the
; routine then waits for the key to be released and calls BankShowTitle, which
; unpacks the title again ($C09D). The bank routine was run on its own in the
; simulator and gives exactly data/info.scr and data/loading.scr.
;
; Hardware: 128K only: calls into the music bank.
;
; O:A 0 (the key code is lost, so the caller's tests for C fail)
WaitSpaceRelease:
  RET                     ; 48K: return; 128K: CALL $85EE (patched by
                          ; Patch128KHooks)
  DEFB $EE,$85            ; operand of the patched CALL ($85EE)
WaitSpaceRelease_Loop:
  HALT                    ; wait for a frame
  LD A,(KeyCode)          ; key code
  OR A
  JR NZ,WaitSpaceRelease_Loop
  CALL BankShowTitle     ; 128K: music bank routine at $C09D
  XOR A
  RET

; Switch the Kempston joystick on or off
;
; Called from TitleMenu when 1 is pressed on the controls screen. Flips the
; byte at KempstonSwitch between RET ($C9, joystick off) and NOP ($00, joystick
; on), then goes on to redraw the Kempston line at ShowKempstonLine.
ToggleKempston:
  LD HL,KempstonSwitch
  LD A,(HL)
  XOR OP_RET              ; RET <-> NOP
  LD (HL),A
  JR ShowKempstonLine

; Title screen key loop and controls menu
;
; Entered from the start of the game StartGame at $A339 with the title screen
; on the screen (the script ScriptTitle when a game restarts after Game Over or
; the ending; the first time, start-up jumps to $8606 past that drawing and the
; loading picture, which shows the same three prompts, stays); the interrupt
; runs MenuFrame, which keeps KeyCode up to date. It waits for no key to be
; held, then for a key: ENTER returns to the caller (the game starts), SPACE
; calls WaitSpaceRelease (128K only: the info screen while SPACE is held; the
; loading picture says "hold Space for info" but on the 48K nothing happens), C
; opens the controls screen, anything else is ignored.
;
; The controls screen: SaveMenuArea saves the middle of the screen and the
; attributes, then the scripts ScriptControlsScreen, ScriptKeyboardLine and
; (through DrawKempstonLine) ScriptKempstonLine draw it: line 1 is the Kempston
; joystick (on or off), line 2 the keyboard with the names of the keys, ENTER
; goes back to the title (the entry at $A336 restores the screen with
; RestoreMenuArea and waits again). 1 toggles the joystick (ToggleKempston). 2
; redefines the keys: it blanks the key-name buffer KeyNames, asks for JUMP,
; CROUCH, LEFT and RIGHT in turn with RedefineOneKey (prompts at PromptJump),
; copies the JUMP pair into the fifth pair, runs the cheat check CheckCheatKeys
; and draws the controls screen again.
;
; Hardware: waits with HALT for the frame interrupt; draws through the script
; interpreter RunScript; keys come from the interrupt routine MenuFrame.
; Observed: C, then 1 on the controls screen writes RET at KempstonSwitch
; (from ToggleKempston) and shows "Kempston disabled"; ENTER brings the title
; picture back.
TitleMenu:
  CALL RestoreMenuArea    ; restore the title screen (coming back from the
                          ; controls screen)

; Title: wait for ENTER, SPACE or C
;
; Entry point used by StartGame when the title has just been drawn. Wait for
; all keys to be released.
TitleWaitKey:
  EI                      ; interrupts on: the key code is updated by the frame
                          ; routine
  HALT
  LD A,(KeyCode)
  OR A
  JR NZ,TitleWaitKey
; Wait for a key: ENTER starts, SPACE (128K music), C controls.
TitleWaitKey_Loop:
  HALT
  LD A,(KeyCode)
  CP KEYCODE_ENTER
  RET Z
  CP CHAR_SPACE
  CALL Z,WaitSpaceRelease
  CP KEYCODE_C            ; C: controls
  JR NZ,TitleWaitKey_Loop
  CALL SaveMenuArea       ; save the middle of the screen and the attributes

; Controls screen: draw it and run its menu
;
; Draw the controls screen: background, then the keyboard line.
ShowControlsMenu:
  LD HL,ScriptControlsScreen
  CALL RunScript
  LD HL,ScriptKeyboardLine
  CALL RunScript
; Entry point used by ToggleKempston. Draw the Kempston line, then wait for no
; key and for a menu key.
ShowKempstonLine:
  CALL DrawKempstonLine
ShowControlsMenu_0:
  HALT                    ; wait until no key is held
  LD A,(KeyCode)
  OR A
  JR NZ,ShowControlsMenu_0
ControlsMenuLoop:
  HALT                    ; wait for a key
  LD A,(KeyCode)
  CP KEYCODE_ENTER        ; ENTER: back to the title
  JR Z,TitleMenu
  CP KEYCODE_1            ; 1: Kempston on/off
  JR Z,ToggleKempston
  CP KEYCODE_2            ; 2: redefine the keys
  JR NZ,ControlsMenuLoop

; Redefine the four keys
;
; Redefine the keys: blank the 8-character key-name buffer, then ask for JUMP,
; CROUCH, LEFT and RIGHT in turn.
RedefineKeys:
  LD DE,KeyNames
  LD H,D
  LD L,E
  LD BC,KEY_NAMES_LEN*$0100+CHAR_SPACE ; B = 8 characters, C = space
RedefineKeys_Blank:
  LD (HL),C
  INC HL
  DJNZ RedefineKeys_Blank
  LD HL,PromptJump
  CALL RedefineOneKey
  LD HL,PromptCrouch
  CALL RedefineOneKey
  LD HL,PromptLeft
  CALL RedefineOneKey
  LD HL,PromptRight
  CALL RedefineOneKey
  LD HL,(KeyJump)         ; the fifth pair (JUMP again) is a copy of the JUMP
                          ; pair
  LD (KeyJumpCopy),HL
  CALL CheckCheatKeys     ; cheat check: do the keys spell RAGE?
  JR ShowControlsMenu

; Redefine-key prompts: 4 x (prompt script, key pair)
;
; One 4-byte record per key asked for by TitleMenu, in the order JUMP, CROUCH,
; LEFT, RIGHT: +0 word: address of the script that prints the name of the key
; (TextJump...), +2 word: address of the key's (row, mask) pair in ControlKeys
; where RedefineOneKey stores the pressed key.
PromptJump:
  DEFW TextJump,KeyJump   ; JUMP: text "JUMP", pair KeyJump
PromptCrouch:
  DEFW TextCrouch,KeyCrouch ; CROUCH: text "CROUCH", pair KeyCrouch
PromptLeft:
  DEFW TextLeft,KeyLeft   ; LEFT: text "LEFT", pair KeyLeft
PromptRight:
  DEFW TextRight,ControlKeys ; RIGHT: text "RIGHT", pair ControlKeys

; Ask for one key and store it
;
; Prints "Press key " (ScriptPressKey) and the name of the control from the
; prompt record, waits for all keys to be released and for a key to be pressed,
; appends the key's name to the buffer KeyNames (AddKeyName), plays sound
; effect 5 and stores the key's (row, mask) into the pair named by the record.
; The row and mask come from PressedKeyMask, which the frame routine MenuFrame
; filled with FindPressedKey's answer, while the name comes from the key code
; of GetKeyCode; with two keys held at once these can differ (F127). Finally
; the keyboard line is redrawn with the new names (ScriptKeyboardLine).
;
; Hardware: waits for frame interrupts with HALT; beeper effect through the
; request byte SoundRequest; text through RunScript.
;
;   HL Address of the prompt record in PromptJump
;   DE Cursor in the key-name buffer KeyNames
; O:DE Cursor after the name that was added
RedefineOneKey:
  PUSH DE
  PUSH HL
  LD HL,ScriptPressKey
  CALL RunScript          ; "Press key " (script, ends at the cursor)
  POP HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  PUSH HL
  EX DE,HL
  CALL RunScript          ; print the name of the control after it
RedefineOneKey_Release:
  HALT                    ; wait until no key is held
  LD A,(KeyCode)
  OR A
  JR NZ,RedefineOneKey_Release
RedefineOneKey_Press:
  HALT                    ; wait for a key
  LD A,(KeyCode)
  OR A
  JR Z,RedefineOneKey_Press
  POP HL
  POP DE
  CALL AddKeyName         ; add its name to the buffer
  LD A,SFX_PICKUP         ; sound request: key accepted
  LD (SoundRequest),A
  PUSH DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD HL,(PressedKeyMask)  ; L = mask, H = row of the key found by
                          ; FindPressedKey
  EX DE,HL                ; DE = row, mask; HL = address of the pair
  LD (HL),D
  INC HL
  LD (HL),E
  LD HL,ScriptKeyboardLine ; redraw "2. Keyboard " and the names
  CALL RunScript
  POP DE
  RET

; Append the name of a key to the key-name buffer
;
; ENTER, SPACE, CAPS SHIFT and SYMBOL SHIFT are written as the two letters from
; ShortKeyNames (en, sp, cs, ss); any other key code is written as the
; character itself.
;
;   A Key code (from KeyCode)
;   DE Cursor in the buffer KeyNames
; O:DE Cursor after the name
AddKeyName:
  PUSH HL
  LD HL,ShortKeyNames
  CP KEYCODE_ENTER
  JR Z,AddKeyName_Short
  INC HL
  INC HL
  CP CHAR_SPACE
  JR Z,AddKeyName_Short
  INC HL
  INC HL
  CP KEYCODE_CAPS_SHIFT
  JR Z,AddKeyName_Short
  INC HL
  INC HL
  CP KEYCODE_SYMBOL_SHIFT
  JR Z,AddKeyName_Short
  LD (DE),A               ; a letter or digit: one character
  INC DE
  POP HL
  RET
AddKeyName_Short:
  LDI                     ; copy the two-letter name
  LDI
  POP HL
  RET

; Short names of the keys ENTER, SPACE, CAPS SHIFT, SYMBOL SHIFT
;
; Four two-letter names in the order ENTER, SPACE, CAPS SHIFT, SYMBOL SHIFT;
; AddKeyName copies one into the key-name buffer KeyNames.
ShortKeyNames:
  DEFM "en"               ; ENTER
  DEFM "sp"               ; SPACE
  DEFM "cs"               ; CAPS SHIFT
  DEFM "ss"               ; SYMBOL SHIFT

; Cheat check: toggle the debug room warp if the keys spell RAGE
;
; Called by TitleMenu after the player has redefined the keys. XORs each of
; the eight bytes of the first four key pairs of ControlKeys with the matching
; byte of CheatKeyPairs (E, G, A, R) into one running value, and if the final
; value is 0 flips the opcode at SmcWarpCheat between JR ($18) and JR Z ($28)
; (XOR $30). With JR Z in place the T key during play puts the player in the
; debug room-warp mode (UpdatePlayer, DebugWarpRoom); with the JR it does
; nothing. Because the XOR runs over the whole table at once and only the last
; result is tested, any four keys whose bytes have the same XOR as E, G, A and
; R toggle the cheat, not only those four (Z, X, C and 5 do too). Redefining to
; the same keys again turns it off.
;
; Hardware: none.
CheckCheatKeys:
  LD HL,ControlKeys
  LD DE,CheatKeyPairs
  LD BC,CHEAT_BYTES*$0100 ; 8 bytes, running XOR in C
CheckCheatKeys_Loop:
  LD A,(DE)
  XOR (HL)
  XOR C                   ; accumulate
  LD C,A
  INC HL
  INC DE
  DJNZ CheckCheatKeys_Loop
  RET NZ                  ; not the cheat keys
  LD A,(SmcWarpCheat)     ; the opcode of the JR at SmcWarpCheat
  XOR CHEAT_OPCODE_FLIP   ; $18 <-> $28
  LD (SmcWarpCheat),A
  RET

; Frame routine of the title and controls menus
;
; Called by the interrupt handler through the vector InterruptRoutine ($8504).
; The start of the game StartGame installs it at StartGame_NoTitle, after
; drawing the title script (on a restart) and before the title menu, and
; replaces it with GameFrameRoutine when ENTER starts the game. Each frame it
; runs the sound effects
; (PlaySoundStep), reads the keyboard into KeyRows (ScanKeyboard), finds the
; first key held (FindPressedKey) and stores its half-row index and mask in
; $8502/$8503 (the mask in $8502, the row in $8503; read by RedefineOneKey),
; then finishes with GetKeyCode which sets the key code KeyCode.
;
; Hardware: beeper (through PlaySoundStep) and keyboard ports (through
; ScanKeyboard).
MenuFrame:
  CALL PlaySoundStep
  CALL ScanKeyboard
  CALL FindPressedKey
  LD (PressedKeyMask),BC  ; $8502 = mask of the key found, $8503 = its half-row
                          ; index
  JP GetKeyCode           ; tail call: the key code goes to KeyCode

; Save the middle of the screen and the attributes
;
; Called by TitleMenu before the controls screen is drawn. Sets A = 0 (NOPs)
; and jumps into the copier at CopyMenuArea: the bitmap of the middle screen
; third ($4800-$4FFF) goes to $C500 and the whole attribute file ($5800-$5AFF)
; to $5B00. Both are scratch areas of the game (the redraw buffer at $C500 and
; the tile map at $5B00) that are not in use while the title and the menus are
; shown.
;
; Hardware: reads the screen bitmap and attributes.
SaveMenuArea:
  XOR A
  JR CopyMenuArea         ; copy screen to buffers (the copier gets NOPs)

; Restore the middle of the screen and the attributes
;
; Called by TitleMenu when the controls screen is left. Fills the attribute
; file with 0 (black), then loads A with the opcode of EX DE,HL and runs the
; copier CopyMenuArea, which patches that opcode over both NOPs so that the two
; block copies run the other way: from $C500 back to $4800 and from $5B00 back
; to $5800. The attribute fill is overwritten by the second copy.
;
; Hardware: writes the screen bitmap and attributes.
RestoreMenuArea:
  LD HL,ATTRS
  LD DE,ATTRS+$0001
  LD (HL),L               ; L = 0: black
  LD BC,ATTRS_SIZE-$0001
  LDIR
  LD A,OP_EX_DE_HL        ; makes both copies run buffer -> screen

; Copy the menu area (save or restore)
;
; Entry point used by SaveMenuArea. The two copies below are patched by A: 0
; (NOP) copies screen to buffers (save), $EB (EX DE,HL) copies buffers to
; screen (restore).
CopyMenuArea:
  LD (SmcCopyAttrs),A     ; patch the NOP at the end (attributes)
  LD (SmcCopyBitmap),A    ; patch the NOP below (bitmap)
  LD HL,SCREEN_THIRD2     ; middle third of the bitmap
  LD DE,RedrawPixels
  LD BC,THIRD_SIZE
; Self-modified: NOP or EX DE,HL, written by CopyMenuArea.
SmcCopyBitmap:
  NOP                     ; NOP: screen to buffer; EX DE,HL: buffer to screen
  LDIR
  LD HL,ATTRS
  LD DE,TILE_MAP          ; attribute save area (the tile map buffer, unused
                          ; before the game)
  LD BC,ATTRS_SIZE
; Self-modified: NOP or EX DE,HL, written by CopyMenuArea.
SmcCopyAttrs:
  NOP
  LDIR
  RET

; Draw the Kempston line of the controls screen
;
; Prints "1. Kempston " with the script ScriptKempstonLine, then "enabled"
; (ScriptEnabled) when the byte KempstonSwitch is a NOP (joystick on) or
; "disabled" (ScriptDisabled) when it is a RET. Ends with a tail call into the
; script interpreter.
;
; Hardware: draws text and background on the screen through RunScript.
DrawKempstonLine:
  LD HL,ScriptKempstonLine
  CALL RunScript
  LD HL,ScriptEnabled
  LD DE,ScriptDisabled
  LD A,(KempstonSwitch)   ; NOP (0) = joystick on
  OR A
  JR Z,DrawKempstonLine_Tail ; joystick on: keep "enabled"
  EX DE,HL                ; joystick off: "disabled"
DrawKempstonLine_Tail:
  JP RunScript

; Script: controls screen background and "Enter to menu"
;
; Interpreted by RunScript: $8F y,x,width,height,attribute fills a block of
; attributes; $81 y,x,width,height,value fills a block of the bitmap (y in
; pixel rows, x and width in bytes); $8E y,x sets the text cursor (pixel rows
; and columns) and the characters that follow are printed; $80 ends. Here: all
; attributes to 0 (black), a clear block of the bitmap 64 rows high from row
; $40 (the middle third), the text, and the middle third of the attributes set
; to 7 (white on black).
ScriptControlsScreen:
  DEFB $8F,$00,$00,$20,$18,$00 ; attributes: whole screen black
  DEFB $81,$40,$00,$20,$40,$00 ; bitmap: clear rows $40-$7F
  DEFB $8E,$70,$4B        ; text at y = $70, x = $4B
  DEFM "Enter to menu"
  DEFB $8F,$08,$00,$20,$08,$07 ; attributes: rows 8-15 white on black
  DEFB $80                ; end

; Script: "1. Kempston "
;
; Clears the bitmap row of the line (y = $40, 16 pixel rows) and prints the
; text at y = $40; DrawKempstonLine appends "enabled" or "disabled".
ScriptKempstonLine:
  DEFB $81,$40,$00,$20,$10,$00
  DEFB $8E,$40,$00        ; text cursor at y = $40, x = 0
  DEFM "1. Kempston "
  DEFB $80

; Script: "enabled"
;
; Printed after "1. Kempston " when the joystick is on (DrawKempstonLine).
ScriptEnabled:
  DEFM "enabled"
  DEFB $80

; Script: "disabled"
;
; Printed after "1. Kempston " when the joystick is off (DrawKempstonLine).
ScriptDisabled:
  DEFM "disabled"
  DEFB $80

; Script: "2. Keyboard " followed by the key names at $A4F2
;
; Clears the bitmap row of the line (y = $50, 16 pixel rows), prints "2.
; Keyboard " at y = $50 and has no $80 of its own: the script goes on into the
; key-name buffer KeyNames, whose last byte is the $80.
ScriptKeyboardLine:
  DEFB $81,$50,$00,$20,$10,$00
  DEFB $8E,$50,$00        ; text cursor at y = $50, x = 0
  DEFM "2. Keyboard "

; Key names shown on the controls screen
;
; Eight characters of the names of the keys JUMP, CROUCH, LEFT, RIGHT in that
; order (QAOP at start-up; ENTER, SPACE, CAPS SHIFT and SYMBOL SHIFT take two
; letters), blank-filled; rewritten by TitleMenu (blanked) and AddKeyName
; (appended). Followed by the $80 that ends the script ScriptKeyboardLine.
KeyNames:
  DEFM "QAOP    "
  DEFB $80                ; end of script ScriptKeyboardLine

; Script: "Press key "
;
; Clears the line at y = $70 and prints "Press key " at y = $70, x = $42;
; RedefineOneKey follows it with the name of the control (JUMP, CROUCH, LEFT,
; RIGHT).
ScriptPressKey:
  DEFB $81,$70,$00,$20,$10,$00
  DEFB $8E,$70,$42        ; text cursor at y = $70, x = $42
  DEFM "Press key "
  DEFB $80

; Script: "JUMP"
;
; Name of the control in the redefinition prompt, printed after ScriptPressKey.
TextJump:
  DEFM "JUMP"
  DEFB $80

; Script: "CROUCH"
;
; Name of the control in the redefinition prompt, printed after ScriptPressKey.
TextCrouch:
  DEFM "CROUCH"
  DEFB $80

; Script: "LEFT"
;
; Name of the control in the redefinition prompt, printed after ScriptPressKey.
TextLeft:
  DEFM "LEFT"
  DEFB $80

; Script: "RIGHT"
;
; Name of the control in the redefinition prompt, printed after ScriptPressKey.
TextRight:
  DEFM "RIGHT"
  DEFB $80

; Script: title screen
;
; Drawn by StartGame (on the 48K, where $8506 = 1) when a game restarts after
; Game Over or the ending; the first start jumps over that drawing and the
; loader's picture serves as the title. The whole screen black, the bitmap
; cleared, the title in two lines ("l'Abbaye" at y = 0, x = $60 and "des morts"
; at y = $10, x = $5C), the two prompt lines at y = $A0 and y = $B0, then all
; attributes set to 7 (white on black). Script codes as in
; ScriptControlsScreen.
ScriptTitle:
  DEFB $8F,$00,$00,$20,$18,$00 ; attributes: whole screen black
  DEFB $81,$00,$00,$20,$C0,$00 ; bitmap: clear all 192 rows
  DEFB $8E,$00,$60        ; text at y = 0, x = $60
  DEFM "l'Abbaye"
  DEFB $8E,$10,$5C        ; text at y = $10, x = $5C
  DEFM "des morts"
  DEFB $8E,$A0,$00        ; text at y = $A0
  DEFM "press C for controls"
  DEFB $8E,$B0,$00        ; text at y = $B0
  DEFM "press enter to start"
  DEFB $8F,$00,$00,$20,$18,$07 ; attributes: whole screen white on black
  DEFB $80                ; end

; Script: Game Over screen
;
; Drawn by StartGame in room state 5: the screen black and cleared, the
; alignment mode set to 2 with the text row at y = $58 (script code $82), the
; text string 37 ("Game Over", script code $85) and the attributes set to 7
; (white on black).
ScriptGameOver:
  DEFB $8F,$00,$00,$20,$18,$00 ; attributes: whole screen black
  DEFB $81,$00,$00,$20,$C0,$00 ; bitmap: clear all 192 rows
  DEFB $82,$02,$58        ; alignment mode 2, text row y = $58
  DEFB $85,$25            ; string 37: Game Over
  DEFB $8F,$00,$00,$20,$18,$07 ; attributes: whole screen white on black
  DEFB $80                ; end
