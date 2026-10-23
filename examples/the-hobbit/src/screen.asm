; Test whether text output is enabled
;
; Output is enabled when ActionPerform and MessagesVisible have a bit in
; common; both are set for what the player does or sees, and zero when an
; action is only being tried or happens out of sight. PrintChar skips the
; character when this returns Z. Registers and A are kept.
;
; Hardware: none.
;
; O:F Z set when nothing is to be printed
OutputEnabled:
  PUSH HL
  LD L,A
  LD A,(ActionPerform)
  LD H,A
  LD A,(MessagesVisible)
  AND H
  LD A,L
  POP HL
  RET

; Print a new line
;
; Sends a carriage return (CHAR_CR) through PrintChar, which prints it in the
; story window or the input window as RawOutputFlag says. Keeps AF.
;
; Hardware: none directly (see PrintChar).
PrintNewLine:
  PUSH AF
  LD A,CHAR_CR
  CALL PrintChar
  POP AF
  RET

; Print a character in the current output window
;
; The one character output of the game. Does nothing when OutputEnabled says
; output is off. Otherwise sends the character to the input window
; (PrintToInput) when RawOutputFlag is set, or to the story window
; (OutputStoryChar). In the story window, while LispFlag is set, an S or s is
; followed by an H, so that the speaker lisps (the extra H goes through the
; same story window routine, with its capital and line end rules).
;
; Hardware: none itself; the windows draw on the screen.
;
;   A Character code ($0D new line, $08 back-space, $20-$7F printable)
; O:F Z set when output is off (nothing printed)
PrintChar:
  CALL OutputEnabled      ; output enabled?
  RET Z
  PUSH AF
  LD A,(RawOutputFlag)
  AND A
  JR NZ,PrintToInput      ; RawOutputFlag set: the input window
  POP AF
  CALL OutputStoryChar    ; story window
  PUSH AF
  LD A,(LispFlag)
  AND A
  JR NZ,PrintChar_0       ; LispFlag set
  POP AF
  RET
PrintChar_0:
  POP AF
  CP 'S'
  JR Z,PrintChar_1
  CP 's'
  RET NZ
PrintChar_1:
  PUSH AF
  LD A,'H'
  CALL OutputStoryChar    ; S -> SH
  POP AF
  RET

; Input window cursor state
;
; Column counter ($85B3), cursor screen address ($85B4), and the cursor's glyph
; ($85B6: '+', set at $6C85). Set at the start ($6C82) and by the print routine
; PrintInputWindowChar.
InputColumn:
  DEFB $00
InputCursor:
  DEFW $0000
InputCursorGlyph:
  DEFB $00

; Print a character in the input window
;
; Prints at the input window's cursor (InputCursor) in the bottom five
; character rows and moves the cursor, drawing the cursor glyph
; (InputCursorGlyph) at the new place; letters a-z are made capitals. A new
; line ($0D) blanks the cursor, scrolls the window up one line (ScrollInputUp)
; and puts the cursor at column 0 of the bottom row. Back-space ($08) blanks
; the cursor cell and moves the cursor one cell back, scrolling the window down
; (ScrollInputDown) when that goes back past the start of a line. When
; InputColumn (columns left in the line) reaches 0 the line wraps like a new
; line. $85B7 is the entry from PrintChar, which has AF on the stack; $85B8
; takes the character in A.
;
; Hardware: draws characters of the ROM font in the screen (through
; PrintInputChar).
;
; A Character code ($0D, $08, $20-$7F) ($85B8 only)
PrintToInput:
  POP AF
; This entry point is used by the routine at GameStart.
PrintInputWindowChar:
  PUSH HL
  PUSH AF
  LD HL,(InputCursor)     ; cursor cell
  CP CHAR_CR
  JR NZ,PrintToInput_0
  LD A,CHAR_SPACE
  CALL PrintInputChar     ; blank the cursor
  JR InputNewLine         ; new line
PrintToInput_0:
  CP CHAR_BACKSPACE
  JR Z,InputBackspace
  CP 'a'                  ; lower case letter?
  JR C,PrintToInput_1
  CP 'z'+$01
  JR NC,PrintToInput_1
  AND $5F                 ; to capital
PrintToInput_1:
  CALL PrintInputChar     ; draw it over the cursor, HL := next cell
  LD A,(InputColumn)      ; InputColumn
  DEC A
  JR NZ,PrintToInput_2    ; room left in the line
InputNewLine:
  LD L,CURSOR_ROW_START   ; start of the bottom row
  CALL ScrollInputUp      ; scroll the window up
  LD A,INPUT_COLUMNS
PrintToInput_2:
  LD (InputColumn),A      ; new InputColumn
  LD A,(InputCursorGlyph) ; the cursor glyph
  LD (InputCursor),HL     ; new cursor cell
  CALL PrintInputChar     ; draw the cursor
  POP AF
  POP HL
  RET
InputBackspace:
  LD A,$20
  CALL PrintInputChar     ; blank the cursor
  DEC L                   ; HL back to the cell before the cursor
  DEC L
  LD A,(InputColumn)
  INC A                   ; one more column left
  CP INPUT_COLUMNS_PLUS_1
  JR NZ,PrintToInput_2
  LD L,$FF                ; back past the start of the line: end of the row
                          ; above
  CALL ScrollInputDown    ; scroll the window down
  LD A,$01                ; one column left, at the end of that row
  JR PrintToInput_2

; Scroll the input window up one line
;
; The input window is character rows 19-23 (5 lines of 32 columns). Moves rows
; 20-23 up to 19-22 one pixel line at a time, then clears row 23 by printing 32
; spaces with PrintInputChar. All registers are kept.
;
; Hardware: copies the screen bitmap of rows 19-23; attributes are not touched.
ScrollInputUp:
  PUSH HL
  PUSH DE
  PUSH BC
  PUSH AF
  LD HL,SCREEN_ROW_20     ; source: row 20
  LD DE,SCREEN_ROW_19     ; destination: row 19
  LD A,INPUT_SCROLL_ROWS
  LD B,$00                ; B=0 for the 16-bit adds below
ScrollInputUp_0:
  PUSH HL
  PUSH DE
  LD C,$08                ; 8 pixel lines of one character row
ScrollInputUp_1:
  PUSH HL
  PUSH DE
  PUSH BC
  LD C,ROW_BYTES          ; one pixel line = 32 bytes
  LDIR
  POP BC
  POP DE
  POP HL
  INC H
  INC D
  DEC C
  JR NZ,ScrollInputUp_1
  POP DE
  POP HL
  LD C,ROW_BYTES          ; next character row
  ADD HL,BC
  EX DE,HL
  ADD HL,BC
  EX DE,HL
  DEC A
  JR NZ,ScrollInputUp_0
  LD B,INPUT_COLUMNS
  LD HL,SCREEN_ROW_23
  LD A,CHAR_SPACE         ; blank the bottom row
ScrollInputUp_Clear:
  CALL PrintInputChar
  DJNZ ScrollInputUp_Clear
  POP AF
  POP BC
  POP DE
  POP HL
  RET

; Scroll the input window down one line
;
; Copies character rows 22, 21, 20, 19 and 18 one row down (to 23-19), going
; upward from the bottom. Used when the cursor is moved back past the start of
; the top input line (InputBackspace). The fifth copy takes row 18, the divider
; row below the story window, into row 19; the first line is not cleared here.
; Not executed with the inputs in re/maps.
;
; Hardware: copies the screen bitmap of rows 18-23.
ScrollInputDown:
  PUSH HL
  PUSH DE
  PUSH BC
  PUSH AF
  LD HL,SCREEN_ROW_22     ; source: row 22
  LD DE,SCREEN_ROW_23     ; destination: row 23
  LD A,$05                ; 5 rows
ScrollInputDown_0:
  PUSH HL
  PUSH DE
  LD B,$08                ; 8 pixel lines
ScrollInputDown_1:
  PUSH HL
  PUSH DE
  PUSH BC
  LD BC,ROW_BYTES         ; one pixel line
  LDIR
  POP BC
  POP DE
  POP HL
  INC H
  INC D
  DJNZ ScrollInputDown_1
  POP DE
  POP HL
  LD BC,-ROW_BYTES        ; both pointers one character row up
  ADD HL,BC
  EX DE,HL
  ADD HL,BC
  EX DE,HL
  DEC A
  JR NZ,ScrollInputDown_0
  POP AF
  POP BC
  POP DE
  POP HL
  RET

; Print a character in the input window
;
; Draws one 8x8 character from the ROM font (32 columns) into the screen cell
; at HL, one pixel line per screen row ($100 apart), and returns HL moved one
; cell to the right. The cell attribute is not changed. AF, BC and DE are kept.
;
; Hardware: writes 8 bytes of the screen bitmap; reads the ROM font.
;
;   A Character code $20-$7F
;   HL Screen address of the cell (top pixel line)
; O:HL Address of the next cell (L + 1)
PrintInputChar:
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  SUB CHAR_SPACE          ; the font starts at space
  LD L,A
  LD H,$00
  ADD HL,HL               ; x8 bytes per character
  ADD HL,HL
  ADD HL,HL
  LD DE,ROM_FONT          ; ROM font ($3D00 is the space)
  ADD HL,DE
  EX DE,HL
  POP HL
  PUSH HL
  LD B,$08                ; 8 pixel lines
PrintInputChar_0:
  LD A,(DE)
  LD (HL),A
  INC DE
  INC H
  DJNZ PrintInputChar_0
  POP HL
  POP DE
  POP BC
  POP AF
  INC L                   ; next column
  RET

; Story window cursor state
;
; Column counter ($869B), cursor cell address ($869C), pixel offset of the
; cursor within its cell ($869E; 6-pixel characters straddle cells), the indent
; printed at the start of an empty line ($869F, set by ListHolderContents) and
; the last character printed on the line ($86A0, 0 = empty line). Set at the
; start ($6C8D-$6CB0) and by OutputStoryChar.
StoryColumn:
  DEFB $00
StoryCursor:
  DEFW $0000
StoryCursorPixel:
  DEFB $00
ListIndent:
  DEFB $00
StoryLastChar:
  DEFB $00

; Print a character in the story window
;
; The story window packs 42 characters of 6 pixels into one 32-cell row, so the
; cursor is a cell address (StoryCursor) plus a pixel offset in C (kept in the
; byte at $869E). What it does with the character in A:
;
; At the start of an empty line (StoryLastChar is 0) it first prints ListIndent
; spaces, an indent set by ListHolderContents.
;
; New line ($0D): sets CapitalNext, clears StoryLastChar, copies the finished
; row to the ZX printer (PrintStoryLine), then pauses so the player can read:
; while NoPauseLines is not 0 (the opening text) it only counts it down and
; waits until no key is down; otherwise it polls the keyboard for SCROLL_DELAY
; loops and, if any key is down, waits until all keys are up (holding a key
; pauses the scroll). Then it scrolls the window up one line (ScrollStoryUp)
; and starts a new line with StoryColumn at 42.
;
; Back-space ($08): steps the cursor back, blanks the cell and steps back
; again.
;
; Other characters: capital letters become lower case; if CapitalNext is not 0
; the next letter is made a capital again and CapitalNext cleared; a full stop
; (.) sets CapitalNext (any non-zero value will do). The glyph is drawn by
; PrintStoryChar and remembered in StoryLastChar. When StoryColumn counts down
; to 0 the line ends like a new line.
;
; Hardware: reads the keyboard port $FE (the pause); draws on the screen
; through PrintStoryChar and ScrollStoryUp; may drive the printer.
;
;   A Character code ($0D, $08, $20-$7F)
; O:A Character code (AF, BC and HL are kept)
OutputStoryChar:
  PUSH HL
  PUSH BC
  PUSH AF
  LD HL,(StoryCursor)     ; cursor cell
  LD A,(StoryCursorPixel)
  LD C,A                  ; pixel offset in the cell
  LD A,(StoryLastChar)
  AND A
  JR NZ,OutputStoryChar_0 ; not at the start of a line
  LD A,(ListIndent)       ; indent
  AND A
  JR Z,OutputStoryChar_0
  LD B,A
OutputStoryChar_Indent:
  LD A,CHAR_SPACE
  CALL PrintStoryChar
  LD A,(StoryColumn)
  DEC A
  LD (StoryColumn),A      ; one column used
  DJNZ OutputStoryChar_Indent
OutputStoryChar_0:
  POP AF
  PUSH AF
  CP CHAR_CR
  JR NZ,OutputStoryChar_4
  LD A,$01
  LD (CapitalNext),A      ; CapitalNext: the next letter is a capital
StoryLineEnd:
  XOR A
  LD (StoryLastChar),A    ; empty line
  CALL PrintStoryLine     ; copy the row to the printer
  PUSH BC
  LD A,(NoPauseLines)
  AND A
  JR NZ,OutputStoryChar_1 ; opening text: no delay
  LD BC,SCROLL_DELAY
OutputStoryChar_Delay:
  XOR A
  IN A,(PORT_ULA)
  AND KEY_BITS
  CP KEY_BITS
  JR NZ,OutputStoryChar_2 ; a key is down: wait for release
  DEC BC
  LD A,B
  OR C
  JR NZ,OutputStoryChar_Delay
  POP BC                  ; delay over, no key
  JR OutputStoryChar_3
OutputStoryChar_1:
  DEC A
  LD (NoPauseLines),A     ; one more line of the opening text shown
OutputStoryChar_2:
  POP BC
OutputStoryChar_Release:
  XOR A
  IN A,(PORT_ULA)
  AND KEY_BITS
  CP KEY_BITS
  JR NZ,OutputStoryChar_Release ; wait until all keys are up
OutputStoryChar_3:
  LD HL,STORY_LAST_ROW    ; start of the bottom story row
  LD C,$01
  CALL ScrollStoryUp      ; scroll up
  LD A,STORY_COLUMNS
  JR OutputStoryChar_9
OutputStoryChar_4:
  CP CHAR_BACKSPACE
  JR NZ,OutputStoryChar_5
  CALL StepCursorBack     ; back one character
  LD A,CHAR_SPACE
  CALL PrintStoryChar     ; blank it
  CALL StepCursorBack     ; and back again
  LD A,(StoryColumn)
  INC A                   ; one more column left
  JR OutputStoryChar_9
OutputStoryChar_5:
  CP 'A'
  JR C,OutputStoryChar_6
  CP 'Z'+$01
  JR NC,OutputStoryChar_6
  OR $20                  ; capitals to lower case
OutputStoryChar_6:
  PUSH HL
  LD HL,CapitalNext       ; CapitalNext
  INC (HL)                ; (sets Z when it is 0)
  DEC (HL)
  JR Z,OutputStoryChar_7
  CP 'a'
  JR C,OutputStoryChar_7
  CP 'z'+$01
  JR NC,OutputStoryChar_7
  RES 5,A                 ; letter after a sentence end: capital
  LD (HL),$00
OutputStoryChar_7:
  CP '.'
  JR NZ,OutputStoryChar_8
  INC (HL)                ; full stop: CapitalNext becomes non-zero
OutputStoryChar_8:
  POP HL
  CALL PrintStoryChar     ; draw
  LD (StoryLastChar),A    ; remember it: the line is not empty
  LD A,(StoryColumn)
  DEC A
  JP Z,StoryLineEnd       ; line full: end it
OutputStoryChar_9:
  LD (StoryColumn),A      ; new StoryColumn
  LD (StoryCursor),HL     ; new cursor cell
  LD A,C
  LD (StoryCursorPixel),A ; new pixel offset
  POP AF
  POP BC
  POP HL
  RET

; Move the story-window cursor back one character
;
; The story window packs 42 characters of 6 pixels into 32 cells, so a
; character starts at pixel offset C (0-7) inside a cell. Subtracts GLYPH_WIDTH
; from C; when that goes below 0, adds 8 and moves to the cell on the left.
;
; Hardware: none.
;
;   C Pixel offset of the character inside its cell, 0-7
;   HL Screen address of the cell
; O:C New pixel offset
; O:L Low byte of the cell address, one less when C wrapped
StepCursorBack:
  LD A,C
  SUB GLYPH_WIDTH
  LD C,A
  RET NC
  ADD A,$08               ; borrow: 8 pixels per cell
  LD C,A
  DEC L
  RET

; Scroll the story window up one line
;
; The story window is character rows 0-17 of the screen (a picture is drawn
; over rows 0-15 and scrolls away with the text). Moves rows 1-17 up to 0-16,
; bitmap and attributes, then clears row 17 by printing 42 spaces with
; PrintStoryChar from pixel offset 1. All registers are kept.
;
; Hardware: copies the screen bitmap of rows 1-17 and the attributes
; $5820-$5A3F, and writes row 17 (STORY_LAST_ROW).
ScrollStoryUp:
  PUSH AF
  PUSH BC
  PUSH HL
  PUSH DE
  LD HL,SCREEN+ROW_BYTES  ; source: row 1
  LD DE,SCREEN            ; destination: row 0
  LD A,STORY_SCROLL_ROWS
  LD B,$00
ScrollStoryUp_0:
  PUSH HL
  PUSH DE
  LD C,$08                ; 8 pixel lines of one character row
ScrollStoryUp_1:
  PUSH HL
  PUSH DE
  PUSH BC
  LD C,ROW_BYTES
  LDIR
  POP BC
  POP DE
  POP HL
  INC H
  INC D
  DEC C
  JR NZ,ScrollStoryUp_1
  POP DE
  POP HL
  LD C,ROW_BYTES          ; next character row
  ADD HL,BC
  EX DE,HL
  ADD HL,BC
  EX DE,HL
  PUSH AF                 ; a step into the next third must add 7 to the high
                          ; byte
  LD A,D
  AND $07
  JR Z,ScrollStoryUp_2
  LD A,D
  ADD A,$07
  LD D,A
ScrollStoryUp_2:
  LD A,H
  AND $07
  JR Z,ScrollStoryUp_3
  LD A,H
  ADD A,$07
  LD H,A
ScrollStoryUp_3:
  POP AF
  DEC A
  JR NZ,ScrollStoryUp_0
  LD HL,ATTRS+ROW_BYTES   ; attributes of rows 1-17 up one row
  LD DE,ATTRS
  LD BC,STORY_SCROLL_ROWS*ROW_BYTES
  LDIR
  LD B,STORY_COLUMNS      ; clear the new bottom row
  LD HL,STORY_LAST_ROW
  LD C,$01                ; pixel offset 1
  LD A,CHAR_SPACE
ScrollStoryUp_4:
  CALL PrintStoryChar
  DJNZ ScrollStoryUp_4
  POP DE
  POP HL
  POP BC
  POP AF
  RET

; Print a character in the story window
;
; Draws one character of the game font (Font, 6 pixels wide, 8 lines) at pixel
; offset C inside the cell at HL. The 8-bit window from bit 7-C down is cleared
; and filled with the glyph; the part of it that falls over the right edge goes
; into the next cell. Then the position moves on by GLYPH_WIDTH pixels (42
; characters of 6 pixels fill a 252-pixel line). AF, DE and B are kept.
;
; Hardware: writes up to 16 bytes of the screen bitmap (8 lines in the cell and
; the next one); attributes are not changed.
;
;   A Character code $20-$7F
;   HL Screen address of the cell (top pixel line)
;   C Pixel offset of the glyph inside the cell, 0-7
; O:HL Address of the cell for the next character
; O:C Pixel offset for the next character
PrintStoryChar:
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,Font-FONT_BASE_ADJUST ; glyph = Font + (code-$20)*8
  ADD HL,DE
  EX DE,HL
  POP HL
  PUSH HL
  LD B,$08                ; 8 pixel lines
PrintStoryChar_0:
  LD A,(DE)
  PUSH BC
  DEC C                   ; C = 0: no shift
  INC C
  LD B,$FF                ; B = mask of the bits to replace
  JR Z,PrintStoryChar_2
PrintStoryChar_1:
  SRL A                   ; shift glyph and mask right by C
  SRL B
  DEC C
  JR NZ,PrintStoryChar_1
PrintStoryChar_2:
  LD C,A
  LD A,B
  CPL
  AND (HL)
  OR C
  LD (HL),A
  POP BC
  DEC C
  INC C
  JR Z,PrintStoryChar_4   ; C = 0: nothing spills into the next cell
  PUSH BC
  LD A,$08                ; spill: shift the glyph left by 8-C
  SUB C
  LD C,A
  LD A,(DE)
  LD B,$FF
PrintStoryChar_3:
  SLA A
  SLA B
  DEC C
  JR NZ,PrintStoryChar_3
  LD C,A
  LD A,B
  CPL
  INC HL                  ; next cell
  AND (HL)
  OR C
  LD (HL),A
  DEC HL
  POP BC
PrintStoryChar_4:
  INC DE
  INC H                   ; next pixel line
  DJNZ PrintStoryChar_0
  POP HL
  POP DE
  POP BC
  LD A,C
  ADD A,GLYPH_WIDTH
  CP $08                  ; over the cell edge?
  JR C,PrintStoryChar_5
  SUB $08
  INC L                   ; next cell
PrintStoryChar_5:
  LD C,A
  POP AF
  RET

; The game's font: 96 characters ($20-$7F), 8 bytes each
;
; Used for the story window (42 columns); the input window uses the ROM font.
Font:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$10,$10,$10,$10,$00,$10,$00
  DEFB $00,$28,$28,$00,$00,$00,$00,$00
  DEFB $00,$28,$7C,$28,$7C,$28,$00,$00
  DEFB $00,$10,$7C,$50,$7C,$14,$7C,$10
  DEFB $00,$64,$48,$10,$24,$4C,$00,$00
  DEFB $20,$50,$20,$54,$48,$74,$00,$00
  DEFB $00,$08,$10,$00,$00,$00,$00,$00
  DEFB $00,$08,$10,$10,$10,$10,$08,$00
  DEFB $00,$10,$08,$08,$08,$08,$10,$00
  DEFB $00,$28,$10,$7C,$10,$28,$00,$00
  DEFB $00,$10,$10,$7C,$10,$10,$00,$00
  DEFB $00,$00,$00,$00,$00,$10,$10,$20
  DEFB $00,$00,$00,$7C,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$30,$30,$00
  DEFB $00,$04,$08,$10,$20,$40,$00,$00
  DEFB $00,$38,$4C,$54,$54,$64,$38,$00
  DEFB $00,$30,$50,$10,$10,$10,$7C,$00
  DEFB $00,$38,$44,$04,$38,$40,$7C,$00
  DEFB $00,$38,$44,$18,$04,$44,$38,$00
  DEFB $00,$18,$28,$48,$7C,$08,$08,$00
  DEFB $00,$7C,$40,$78,$04,$44,$38,$00
  DEFB $00,$38,$40,$78,$44,$44,$38,$00
  DEFB $00,$7C,$04,$08,$10,$20,$20,$00
  DEFB $00,$38,$44,$38,$44,$44,$38,$00
  DEFB $00,$38,$44,$44,$3C,$04,$38,$00
  DEFB $00,$00,$10,$00,$00,$10,$00,$00
  DEFB $00,$00,$10,$00,$00,$10,$10,$20
  DEFB $00,$00,$08,$10,$20,$10,$08,$00
  DEFB $00,$00,$00,$3C,$00,$3C,$00,$00
  DEFB $00,$00,$20,$10,$08,$10,$20,$00
  DEFB $00,$38,$44,$08,$10,$00,$10,$00
  DEFB $00,$38,$54,$54,$58,$40,$38,$00
  DEFB $00,$38,$44,$44,$7C,$44,$44,$00
  DEFB $00,$78,$44,$78,$44,$44,$78,$00
  DEFB $00,$38,$44,$40,$40,$44,$38,$00
  DEFB $00,$70,$48,$44,$44,$48,$70,$00
  DEFB $00,$7C,$40,$78,$40,$40,$7C,$00
  DEFB $00,$7C,$40,$78,$40,$40,$40,$00
  DEFB $00,$38,$44,$40,$5C,$44,$38,$00
  DEFB $00,$44,$44,$7C,$44,$44,$44,$00
  DEFB $00,$7C,$10,$10,$10,$10,$7C,$00
  DEFB $00,$04,$04,$04,$44,$44,$38,$00
  DEFB $00,$48,$50,$60,$50,$48,$44,$00
  DEFB $00,$40,$40,$40,$40,$40,$7C,$00
  DEFB $00,$44,$6C,$54,$44,$44,$44,$00
  DEFB $00,$44,$64,$54,$54,$4C,$44,$00
  DEFB $00,$38,$44,$44,$44,$44,$38,$00
  DEFB $00,$78,$44,$44,$78,$40,$40,$00
  DEFB $00,$38,$44,$44,$54,$48,$34,$00
  DEFB $00,$78,$44,$44,$78,$48,$44,$00
  DEFB $00,$38,$40,$38,$04,$44,$38,$00
  DEFB $00,$7C,$10,$10,$10,$10,$10,$00
  DEFB $00,$44,$44,$44,$44,$44,$38,$00
  DEFB $00,$44,$44,$44,$44,$28,$10,$00
  DEFB $00,$44,$44,$44,$54,$6C,$44,$00
  DEFB $00,$44,$28,$10,$10,$28,$44,$00
  DEFB $00,$44,$44,$28,$10,$10,$10,$00
  DEFB $00,$7C,$04,$18,$20,$40,$7C,$00
  DEFB $00,$38,$20,$20,$20,$20,$38,$00
  DEFB $00,$40,$20,$10,$08,$04,$00,$00
  DEFB $00,$38,$08,$08,$08,$08,$38,$00
  DEFB $00,$10,$38,$54,$10,$10,$10,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$7C
  DEFB $00,$18,$24,$70,$20,$20,$7C,$00
  DEFB $00,$00,$38,$04,$3C,$44,$3C,$00
  DEFB $00,$40,$40,$78,$44,$44,$78,$00
  DEFB $00,$00,$38,$40,$40,$40,$38,$00
  DEFB $00,$04,$04,$3C,$44,$44,$3C,$00
  DEFB $00,$00,$38,$44,$78,$40,$3C,$00
  DEFB $00,$18,$20,$30,$20,$20,$20,$00
  DEFB $00,$00,$3C,$44,$44,$3C,$04,$38
  DEFB $00,$40,$40,$78,$44,$44,$44,$00
  DEFB $00,$10,$00,$30,$10,$10,$38,$00
  DEFB $00,$08,$00,$08,$08,$08,$48,$30
  DEFB $00,$20,$28,$30,$30,$28,$24,$00
  DEFB $00,$20,$20,$20,$20,$20,$18,$00
  DEFB $00,$00,$68,$54,$54,$54,$54,$00
  DEFB $00,$00,$78,$44,$44,$44,$44,$00
  DEFB $00,$00,$38,$44,$44,$44,$38,$00
  DEFB $00,$00,$78,$44,$44,$78,$40,$40
  DEFB $00,$00,$38,$48,$48,$38,$08,$0C
  DEFB $00,$00,$38,$20,$20,$20,$20,$00
  DEFB $00,$00,$38,$40,$38,$04,$78,$00
  DEFB $00,$20,$70,$20,$20,$20,$18,$00
  DEFB $00,$00,$44,$44,$44,$44,$38,$00
  DEFB $00,$00,$44,$44,$28,$28,$10,$00
  DEFB $00,$00,$44,$54,$54,$54,$28,$00
  DEFB $00,$00,$44,$28,$10,$28,$44,$00
  DEFB $00,$00,$44,$44,$44,$3C,$04,$38
  DEFB $00,$00,$7C,$08,$10,$20,$7C,$00
  DEFB $00,$1C,$10,$60,$10,$10,$1C,$00
  DEFB $00,$10,$10,$10,$10,$10,$10,$00
  DEFB $00,$70,$10,$0C,$10,$10,$70,$00
  DEFB $00,$28,$50,$00,$00,$00,$00,$00
  DEFB $00,$10,$08,$7C,$00,$7C,$08,$10
