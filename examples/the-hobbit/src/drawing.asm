; Picture id found by $7F78 (FF when pictures are off)
PictureFound:
  DEFB $00

; Draw the picture of a location
;
; Looks the location up in PictureTable ($CC00) and draws its picture with
; RunPictureCommands. Does nothing but set PictureFound to $FF when pictures
; are off (the N key held at start-up left PicturesEnabled, $B707, at 0).
; Otherwise PictureFound is the location id, or $FF when the location has no
; picture (the table holds 22 pictures for about 60 locations). The caller
; ShowLocation then waits for a key when a picture was drawn.
;
; Hardware: the drawing writes the screen bitmap, the attributes and the
; border.
;
;   A Location id
;   PicturesEnabled ($B707) 0 = pictures off
; O:PictureFound Id of the picture drawn, $FF if none
;   All registers are preserved
DrawLocationPicture:
  PUSH AF
  LD A,(PicturesEnabled)  ; PicturesEnabled
  AND A
  JR NZ,DrawLocationPicture_0
  LD A,$FF                ; pictures off:
  LD (PictureFound),A     ; PictureFound = $FF
  POP AF
  RET
DrawLocationPicture_0:
  POP AF
  PUSH AF
  PUSH HL
  PUSH BC
  PUSH DE
  PUSH IX
  LD IX,PictureTable      ; picture table
  CALL FindIdRecord       ; find the id; Z = not found
  LD (PictureFound),A     ; id or $FF
  LD L,(IX+$01)           ; HL = address of the picture data
  LD H,(IX+$02)
  CALL NZ,RunPictureCommands ; draw it (flags still from the lookup)
  POP IX
  POP DE
  POP BC
  POP HL
  POP AF
  RET

; Run the picture commands of a location picture
;
; The picture interpreter of DrawLocationPicture. StartPicture first sets the
; border and fills the picture area (top 16 character rows) with the picture's
; attribute; then the commands at IY run until a $00 byte. The pen starts at
; PIC_START_X, PIC_START_Y (x to the right, y upward). Command byte A:
;
; $00 end. $08 (PIC_CMD_MOVE) x y: move the pen. Other values below $20 are
; skipped.
;
; $80-$FF line, 2 bytes: byte 1 = 1 rrrr L D V, byte 2 = rr nnnnnn. V = 1
; vertical-major, else horizontal-major; D = 1 the minor step goes down, else
; up; L = 1 left, else right; n+1 major steps, one minor step after every
; (rrrrrr + 1) major steps (DrawPictureLine).
;
; $40-$7F flood fill, 3 bytes: ink = A AND 7, x, y of the seed (FloodFill).
;
; $20-$27 paint attributes, 3 bytes and runs: paper = (A AND 7) * 8, then the
; attribute address (high byte first), then run bytes dd cccccc: direction dd
; (0 up, 1 right, 2 down, 3 left), cccccc+1 cells, until $FF. Each cell gets
; the new paper; its ink is inverted when it equalled the new paper.
;
; Hardware: writes the screen bitmap, the attributes and the border (through
; StartPicture and the drawing routines).
;
; HL Address of the picture data (border, attribute, commands)
; All registers are preserved.
RunPictureCommands:
  PUSH IY                 ; keep IY
  PUSH HL                 ; keep HL
  PUSH HL                 ; IY = HL, the data
  POP IY
  PUSH DE
  PUSH BC
  CALL StartPicture       ; border, attributes, clear; may end the picture (too
                          ; dark)
  LD D,PIC_START_X        ; pen x
  LD E,PIC_START_Y        ; pen y
  LD B,$01                ; B, C, L are set up by each line command
  LD C,$01
  LD L,$01
RunPictureCommands_Next:
  LD A,(IY+$00)           ; next command byte
  AND A                   ; $00: end
  JP Z,RunPictureCommands_End ; -> RunPictureCommands_End
  INC IY
  CP PIC_CMD_MOVE
  JR NZ,RunPictureCommands_0
  LD D,(IY+$00)           ; move: pen x
  INC IY
  LD E,(IY+$00)           ; pen y
  INC IY
  JR RunPictureCommands_Next
RunPictureCommands_0:
  BIT 7,A                 ; bit 7: line
  JR Z,RunPictureCommands_1
  LD B,A                  ; B = byte 1
  AND $07                 ; C = 0 0 0 0 0 L D V
  LD C,A
  LD A,B
  RRCA                    ; B = rrrr << 2
  AND $3C
  LD B,A
  LD A,(IY+$00)           ; byte 2
  AND $3F                 ; L = n + 1 major steps
  LD L,A
  INC L
  LD A,(IY+$00)
  INC IY
  RLCA                    ; the top two bits of byte 2 ...
  RLCA
  AND $03
  OR B                    ; ... are the low bits of r
  LD B,A
  INC B                   ; B = r + 1 major steps per minor step
  CALL DrawPictureLine    ; draw the line, pen moves
  JR RunPictureCommands_Next
RunPictureCommands_1:
  BIT 6,A                 ; bit 6: fill
  JR Z,RunPictureCommands_Paint
  AND $07                 ; A = ink colour
  PUSH DE                 ; keep the pen
  LD D,(IY+$00)           ; seed x
  INC IY
  LD E,(IY+$00)           ; seed y
  INC IY
  CALL FloodFill          ; fill
  POP DE
  JP RunPictureCommands_Next
RunPictureCommands_Paint:
  BIT 5,A                 ; bit 5: paint (otherwise skip the byte)
  JP Z,RunPictureCommands_Next
  AND $07                 ; A = paper colour * 8 (PIC_PAPER_MASK)
  RLCA
  RLCA
  RLCA
  PUSH HL                 ; keep L, D/E, B/C
  PUSH DE
  PUSH BC
  LD C,A                  ; C = new paper
  LD H,(IY+$00)           ; H = attribute address, high byte
  INC IY
  LD L,(IY+$00)           ; L = low byte
  INC IY
RunPictureCommands_Run:
  LD A,(IY+$00)           ; run byte
  INC IY
  CP PIC_ATTR_END
  JR Z,RunPictureCommands_3 ; end of the runs
  LD B,A
  AND $03                 ; E = direction 0 up, 1 right, 2 down, 3 left
  LD E,A
  LD A,B
  RRCA
  RRCA
  AND $3F                 ; A = cells - 1 ...
  INC A                   ; ... B = cells in the run
  LD B,A
RunPictureCommands_Cell:
  LD A,(HL)               ; attribute of the cell
  AND $07                 ; its ink
  RLCA
  RLCA
  RLCA
  CP C                    ; equal to the new paper?
  JR NZ,RunPictureCommands_2
  XOR PIC_PAPER_MASK      ; invert the ink so it stays visible
RunPictureCommands_2:
  RRCA                    ; ink back to bits 0-2
  RRCA
  RRCA
  OR C                    ; with the new paper
  LD (HL),A
  LD A,E
  AND A
  CALL Z,AttrUp           ; step up
  DEC A
  CALL Z,AttrRight        ; step right
  DEC A
  CALL Z,AttrDown         ; step down
  DEC A
  CALL Z,AttrLeft         ; step left
  DJNZ RunPictureCommands_Cell
  JR RunPictureCommands_Run
RunPictureCommands_3:
  POP BC                  ; restore
  POP DE
  POP HL
  JP RunPictureCommands_Next
; Exit of the drawer (also taken from StartPicture when it is too dark to see).
RunPictureCommands_End:
  POP BC
  POP DE
  POP HL
  POP IY
  RET

; Two bytes of the picture drawing routine ($8071)
DrawVar1:
  DEFB $00
DrawVar2:
  DEFB $00

; Flood fill a region of the picture
;
; The fill command of the picture drawer (RunPictureCommands): fills the clear
; pixels around the seed pen position until lit pixels (lines drawn earlier)
; bound the region. Scan-line fill: each seed on the stack gives a span (go
; left to the first lit pixel, then right to the next); every pixel of the span
; is plotted (PlotPixel, in the ink colour, which also recolours the attribute
; cell) and the rows above and below are tested, one new seed being pushed for
; each run of clear pixels. The lit pixel that stops a span is plotted as well.
; Seeds are pen positions (D = x, E = y) kept on the machine stack above a
; sentinel with y $80; the fill ends when the sentinel comes back. DrawVar1 and
; DrawVar2 are the "a seed was already pushed for this run" flags of the row
; above and the row below.
;
; At the end PicVar1, the ink colour used by PlotPixel for the lines too, is
; set to 0, so lines drawn after a fill are black (the lines of a picture whose
; paper is black are white, see PlotPixel).
;
; Hardware: writes the screen bitmap and attributes (and reads the bitmap).
;
; A Ink colour 0-7 (kept in PicVar1)
; D Seed pen x
; E Seed pen y
; All registers other than AF are preserved
FloodFill:
  LD (PicVar1),A          ; fill ink colour
  PUSH DE
  PUSH HL
  LD HL,FILL_SENTINEL     ; sentinel seed (y = $80)
  PUSH HL
FloodFill_Span:
  CALL TestPixel          ; go left along the row ...
  JR NZ,FloodFill_0       ; ... while the pixel is clear
  CALL MovePenLeft        ; MovePenLeft: Z at the left edge
  JR NZ,FloodFill_Span
  JR FloodFill_1          ; edge reached: the span starts here
FloodFill_0:
  CALL PlotPixel          ; lit pixel: colour it
  CALL MovePenRight       ; and step back right: start of the span
FloodFill_1:
  LD HL,$0000             ; no seed pushed above
  LD (DrawVar1),HL
FloodFill_Column:
  CALL MovePenUp          ; up: is the pixel above clear?
  LD A,$00
  JR Z,FloodFill_3        ; top edge: nothing above
  CALL TestPixel
  LD A,$00
  JR NZ,FloodFill_2       ; lit above: no seed
  LD A,(DrawVar1)         ; clear above:
  AND A
  JR NZ,FloodFill_2       ; a seed is already there
  PUSH DE                 ; new seed for the row above
  LD A,$01
FloodFill_2:
  PUSH AF
  CALL MovePenDown        ; back to the row
  POP AF
FloodFill_3:
  LD (DrawVar1),A         ; DrawVar1 = flag for the row above
  CALL MovePenDown        ; down: the pixel below
  LD A,$00
  JR Z,FloodFill_5        ; bottom edge: nothing below
  CALL TestPixel
  LD A,$00
  JR NZ,FloodFill_4
  LD A,(DrawVar2)         ; DrawVar2
  AND A
  JR NZ,FloodFill_4
  PUSH DE                 ; new seed for the row below
  LD A,$01
FloodFill_4:
  PUSH AF
  CALL MovePenUp          ; back to the row
  POP AF
FloodFill_5:
  LD (DrawVar2),A         ; DrawVar2 = flag for the row below
  CALL PlotPixel          ; colour this pixel
  CALL MovePenRight       ; right: Z at the right edge
  JR Z,FloodFill_NextSeed
  CALL TestPixel          ; clear: continue the span
  JR Z,FloodFill_Column
  CALL PlotPixel          ; lit: it bounds the span, colour it too
FloodFill_NextSeed:
  POP DE                  ; next seed
  LD A,E
  CP FILL_SENTINEL        ; sentinel: the fill is over
  JR NZ,FloodFill_Span
  LD A,$00                ; PicVar1 = 0
  LD (PicVar1),A
  POP HL
  POP DE
  RET

; Test a picture pixel
;
; Reads the pixel at the pen position and tells whether it is lit.
;
; Hardware: reads the screen bitmap.
;
; D Pen x, 0-255 E Pen y, 0-127 (0 is the bottom row of the picture area) O:F Z
; if the pixel is clear, NZ if it is lit O:A Pixel mask ANDed with the screen
; byte HL is preserved
TestPixel:
  PUSH HL
  CALL PenToScreen
  AND (HL)
  POP HL
  RET

; Step an attribute address up one row
;
; Used by the picture paint command: subtracts 32 from the attribute address
; and keeps the old address if that would leave the picture's 16 attribute rows
; ($5800-$59FF).
;
; Hardware: none (address arithmetic on the attribute area).
;
; HL Attribute address O:HL New attribute address AF and DE are preserved
AttrUp:
  PUSH AF
  PUSH DE
  LD DE,ATTR_ROW
  AND A
  SBC HL,DE
  LD A,H
  CP $57                  ; above $5800?
  JR NZ,AttrUp_0
  ADD HL,DE
AttrUp_0:
  POP DE
  POP AF
  RET

; Step an attribute address down one row
;
; Adds 32 to the attribute address and keeps the old one if that would pass the
; picture's 16 attribute rows ($5A00). The JR NZ at $810F jumps to $8113, the
; second byte of the SBC HL,DE: it is $52, LD D,D, a no-op.
;
; Hardware: none (address arithmetic on the attribute area).
;
; HL Attribute address O:HL New attribute address AF and DE are preserved
AttrDown:
  PUSH AF
  PUSH DE
  LD DE,ATTR_ROW
  ADD HL,DE
  LD A,H
  CP $5A                  ; past $59FF?
  JR NZ,AttrDown_Sbc+$0001 ; no: jumps into SBC HL,DE (LD D,D)
  AND A
AttrDown_Sbc:
  SBC HL,DE
  POP DE
  POP AF
  RET

; Step an attribute address left one cell
;
; Subtracts 1; keeps the old address if that would pass $5800. It does not stop
; at the start of a row: from column 0 it goes to the end of the row above.
;
; Hardware: none (address arithmetic on the attribute area).
;
; HL Attribute address O:HL New attribute address AF is preserved
AttrLeft:
  PUSH AF
  DEC HL
  LD A,H
  CP $57
  JR NZ,AttrLeft_0
  INC HL
AttrLeft_0:
  POP AF
  RET

; Step an attribute address right one cell
;
; Adds 1; keeps the old address if that would reach $5A00. It does not stop at
; the end of a row: from column 31 it goes to the start of the next row.
;
; Hardware: none (address arithmetic on the attribute area).
;
; HL Attribute address O:HL New attribute address AF is preserved
AttrRight:
  PUSH AF
  INC HL
  LD A,H
  CP $5A
  JR NZ,AttrRight_0
  DEC HL
AttrRight_0:
  POP AF
  RET

; Move the picture pen up one pixel
;
; Adds 1 to the pen y. At the top edge (y would become 128) the pen stays and Z
; is returned. H is used as scratch and the other registers are kept. The four
; pen moves (MovePenUp, MovePenDown, MovePenRight, MovePenLeft) are used by the
; line and fill routines.
;
;   E Pen y
; O:E New pen y
; O:F Z if the pen was at the edge and did not move
; O:H Destroyed
MovePenUp:
  INC E
  BIT 7,E
  JR Z,MovePen_Moved
  DEC E
  LD H,A
  XOR A
  LD A,H
  RET
; This entry point is used by the routine at MovePenDown.
MovePen_Moved:
  LD H,A                  ; moved: clear Z (A is kept)
  OR $01
  LD A,H
  RET

; Move the picture pen down one pixel
;
; Subtracts 1 from the pen y. At the bottom edge (y 0) the pen stays and Z is
; returned. Uses the exit at MovePen_Moved when it moved.
;
;   E Pen y
; O:E New pen y
; O:F Z if the pen was at the edge and did not move
; O:H Destroyed on the moved path
MovePenDown:
  DEC E
  BIT 7,E
  JR Z,MovePen_Moved
  INC E
  RET

; Move the picture pen right one pixel
;
; Adds 1 to the pen x. At the right edge (x 255) the pen stays and Z is
; returned. H is used as scratch on that path; A is kept.
;
;   D Pen x
; O:D New pen x
; O:F Z if the pen was at the edge and did not move
MovePenRight:
  INC D
  RET NZ
  DEC D
  LD H,A
  XOR A
  LD A,H
  RET

; Move the picture pen left one pixel
;
; Subtracts 1 from the pen x. At the left edge (x 0) the pen stays and Z is
; returned. H is used as scratch; A is kept.
;
;   D Pen x
; O:D New pen x
; O:F Z if the pen was at the edge and did not move
; O:H Destroyed
MovePenLeft:
  DEC D
  LD H,A
  LD A,D
  CP $FF
  LD A,H
  RET NZ
  INC D
  RET

; Draw a straight picture line segment
;
; The line command of the picture drawer (RunPictureCommands). Plots L pixels
; from the pen position, moving the pen after each plot: a step along the major
; axis every time and a step along the other axis every B major steps (a
; shallow or steep line made of runs; B = 1 gives a diagonal). Drawing stops
; early when a pen move reports the edge of the picture area (MovePenRight and
; the other pen moves return Z there). The pen ends one step past the last
; pixel. Bit 0 of C picks the major axis: clear is horizontal (this part), set
; is vertical (DrawPictureLine_Vertical, the same code with the axes swapped).
;
; Hardware: writes the screen bitmap and attributes through PlotPixel.
;
;   B Major steps per minor step (1-64)
;   C Direction bits: bit 0 vertical-major; bit 1 the minor/vertical step is
;     MovePenDown (pen y down), clear MovePenUp (up); bit 2 the horizontal step
;     is MovePenLeft (left), clear MovePenRight (right)
;   D Pen x
;   E Pen y
;   L Number of major steps (1-64)
; O:D, E Pen after the last step
;   BC, HL are preserved
DrawPictureLine:
  BIT 0,C                 ; bit 0: vertical-major
  JR NZ,DrawPictureLine_Vertical
  PUSH HL                 ; keep L and B
  PUSH BC
DrawPictureLine_Step:
  CALL PlotPixel          ; colour the pixel
  BIT 2,C                 ; bit 2: left or right
  JR Z,DrawPictureLine_0
  CALL MovePenLeft
  JR Z,DrawPictureLine_5
  JR DrawPictureLine_1
DrawPictureLine_0:
  CALL MovePenRight
  JR Z,DrawPictureLine_5
DrawPictureLine_1:
  DEC B                   ; every B steps:
  JR NZ,DrawPictureLine_4
  BIT 1,C                 ; bit 1: down or up
  JR Z,DrawPictureLine_2
  CALL MovePenDown
  JR Z,DrawPictureLine_5
  JR DrawPictureLine_3
DrawPictureLine_2:
  CALL MovePenUp
  JR Z,DrawPictureLine_5
DrawPictureLine_3:
  POP BC                  ; restart the count of B
  PUSH BC
DrawPictureLine_4:
  DEC L                   ; next major step
  JR NZ,DrawPictureLine_Step
DrawPictureLine_5:
  POP BC
  POP HL
  RET
DrawPictureLine_Vertical:
  PUSH HL                 ; the same with x and y swapped
  PUSH BC
DrawPictureLine_6:
  CALL PlotPixel
  BIT 1,C
  JR Z,DrawPictureLine_7
  CALL MovePenDown
  JR Z,DrawPictureLine_12
  JR DrawPictureLine_8
DrawPictureLine_7:
  CALL MovePenUp
  JR Z,DrawPictureLine_12
DrawPictureLine_8:
  DEC B
  JR NZ,DrawPictureLine_11
  BIT 2,C
  JR Z,DrawPictureLine_9
  CALL MovePenLeft
  JR Z,DrawPictureLine_12
  JR DrawPictureLine_10
DrawPictureLine_9:
  CALL MovePenRight
  JR Z,DrawPictureLine_12
DrawPictureLine_10:
  POP BC
  PUSH BC
DrawPictureLine_11:
  DEC L
  JR NZ,DrawPictureLine_6
DrawPictureLine_12:
  POP BC
  POP HL
  RET

; Plot a picture pixel and colour its cell
;
; Sets the pixel at the pen position and sets the ink of its attribute cell to
; the picture's current ink colour (PicVar1, $824E). The cell keeps its paper;
; BRIGHT and FLASH are cleared. If the ink would equal the paper, it is
; inverted (7 minus the colour) so that the pixel can be seen. Used by the
; line, fill and paint routines.
;
; Hardware: writes the screen bitmap and the attribute area.
;
; D Pen x, 0-255 E Pen y, 0-127 PicVar1 Ink colour 0-7 HL is preserved
PlotPixel:
  PUSH HL
  CALL PenToScreen        ; HL = bitmap byte, A = mask
  PUSH AF
  PUSH HL
  LD A,H
  AND $18                 ; third of the screen ...
  RRCA
  RRCA
  RRCA
  ADD A,$58               ; ... to the attribute page ($58-$5A)
  LD H,A
  LD A,(HL)
  AND $07*PAPER           ; keep the paper only
  LD (HL),A
  LD A,(PicVar1)
  RLCA
  RLCA
  RLCA                    ; ink colour in the paper position
  CP (HL)
  JR NZ,PlotPixel_0       ; ink equals paper?
  XOR $07*PAPER           ; then invert it
PlotPixel_0:
  RRCA
  RRCA
  RRCA
  OR (HL)                 ; ink | paper
  LD (HL),A
  POP HL
  POP AF
  OR (HL)                 ; set the pixel
  LD (HL),A
  POP HL
  RET

; Convert a picture pen position to a screen byte address and bit mask
;
; The picture area is 256x128 pixels with y growing upward, so the pixel row
; from the top is $7F-y. Builds the Spectrum screen address of the byte holding
; the pixel (third, character row and pixel line from the row; column from x/8)
; and the mask of the pixel in that byte (bit 7 for x mod 8 = 0). Used by the
; line, plot and fill routines of the picture drawer.
;
; Hardware: none (computes an address in the screen bitmap only).
;
;   D Pen x, 0-255
;   E Pen y, 0-127 (0 is the bottom row of the picture area)
; O:HL Screen address of the byte
; O:A Bit mask of the pixel in that byte
PenToScreen:
  LD A,$7F
  SUB E                   ; pixel row from the top
  LD L,A
  AND $07
  OR $40                  ; $40 + pixel line within the character row
  LD H,A
  LD A,L
  AND $C0
  RRCA                    ; row bits 6-7 (the third) to bits 3-4 of H
  RRCA
  RRCA
  OR H
  LD H,A
  LD A,L
  AND $38                 ; row bits 3-5 (character row in the third) to bits
                          ; 5-7 of L
  RLCA
  RLCA
  LD L,A
  LD A,D
  RRCA                    ; x/8 is the column
  RRCA
  RRCA
  AND $1F
  OR L
  LD L,A
  LD A,D
  AND $07
  PUSH BC
  LD B,A
  INC B
  LD A,$01                ; mask: $80 rotated right (x mod 8)+1 times
PenToScreen_0:
  RRC A
  DJNZ PenToScreen_0
  POP BC
  RET

; Start a picture: border, attribute fill and clear
;
; The first step of RunPictureCommands. Asks CheckDark whether the player can
; see (carry set: too dark; the same rule as for a room description). The
; picture data begin with two bytes: the border colour and the attribute that
; fills the picture area. If it is too dark both are taken as 0, so the picture
; area is cleared to black with a black border, and the picture is abandoned
; (the return address is dropped and the drawer leaves at
; RunPictureCommands_End). Otherwise sets the border, clears the bitmap of the
; picture area ($4000-$4FFF, the top 16 rows) and fills its attributes
; ($5800-$59FF).
;
; Hardware: writes the border (port $FE), the screen bitmap and the attributes.
; The carry from CheckDark is parked in AF' while the registers are used.
;
;   IY Picture data: border, attribute, then the drawing commands
; O:IY Advanced past the two header bytes
StartPicture:
  CALL CheckDark          ; carry = too dark to see
  EX AF,AF'               ; carry kept in AF'
  LD A,(IY+$00)           ; border colour
  INC IY
  EX AF,AF'
  JR NC,StartPicture_0
  EX AF,AF'
  XOR A
  EX AF,AF'
StartPicture_0:
  EX AF,AF'
  OUT (PORT_ULA),A        ; set the border
  PUSH HL
  PUSH DE
  PUSH BC
  LD HL,SCREEN            ; clear the picture bitmap
  LD DE,SCREEN+$0001
  LD BC,PICTURE_BITMAP_SIZE-$0001
  LD (HL),$00
  LDIR
  LD HL,ATTRS             ; fill the picture attributes
  LD DE,ATTRS+$0001
  LD BC,PICTURE_ATTRS_SIZE-$0001
  LD A,(IY+$00)           ; attribute byte
  INC IY
  EX AF,AF'
  JR NC,StartPicture_1
  EX AF,AF'
  XOR A
  EX AF,AF'
StartPicture_1:
  EX AF,AF'
  LD (HL),A
  LDIR
  POP BC
  POP DE
  POP HL
  EX AF,AF'
  RET NC                  ; light: back to the drawer
  POP HL                  ; dark: drop the return address
  JP RunPictureCommands_End ; and leave the drawer

; Three bytes of the picture routines ($8071, $82FD, $8315)
PicVar1:
  DEFB $38
PicVar2:
  DEFB $00
PicVar3:
  DEFB $00
