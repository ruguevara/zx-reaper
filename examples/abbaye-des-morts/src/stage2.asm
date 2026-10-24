; Loader, second stage: unpacked to $6000 by Stage1 (src/stage1.asm). It
; finds out the machine, reveals the picture at $7000 cell by cell, loads
; tape block 3 with a copy of the ROM loader that animates an hourglass, and
; unpacks the game over itself; the game starts at $6000.
;
; Tape block 3 (29796 bytes at $625E, over this stage's own code from
; RevealExit on) holds four MegaLZ streams one after another
; (scripts/block3.py): the loading screen in RCS order ($625E), the info
; screen in RCS order ($6C4B), the 128K music ($712E) and the game ($83F9).
;
; Hardware: ports $FE (border, speaker, tape EAR), $7FFD (128K paging),
; $FFFD/$BFFD (AY), IM 2 on 128K only; ROM LD-BYTES copied and patched.
  DEVICE ZXSPECTRUM48
  INCLUDE "megalz.asm"

; ROM and system variables
LD_BYTES     EQU $0556  ; ROM tape loader, copied to TapeLoader
LD_EDGE_2    EQU $05E3  ; where the copy stops
LD_EDGE_1    EQU $05E9  ; inside LD-EDGE-1: $C3 there means a ROM that jumps away
BORDCR       EQU $5C48
PRINTER_BUF  EQU $5B00  ; the game depacker runs here
ATTRS        EQU $5800
; 128K
BANK_PORT    EQU $7FFD
AY_SELECT    EQU $FF    ; high bytes of the AY ports $FFFD and $BFFD
AY_DATA      EQU $BF
; the loader built in high memory
TapeLoader   EQU $FE00  ; LD-BYTES, 141 bytes copied from the ROM
TL_BORDER    EQU TapeLoader+$05   ; operand of LD A,$0F (border colour)
TL_PUSH      EQU TapeLoader+$0B   ; PUSH HL of LD-BYTES (SA/LD-RET)
TL_EDGE_CALL EQU TapeLoader+$75   ; CALL LD-EDGE-2 in LD-8-BITS
TL_8BITS     EQU TapeLoader+$74   ; LD-8-BITS
TL_8BITS_JP  EQU TapeLoader+$80   ; JP NC,LD-8-BITS
FrameTable   EQU $FB00  ; page of the bytes left -> offset of the hourglass frame
FramesEven    EQU $FC00  ; HourglassFramesEven copied here: frames for an even count
FramesOdd EQU $FD00  ; HourglassFramesOdd: frames for an odd count
IM2_TABLE    EQU $BE00  ; 128K timing: 257 bytes of $BF, handler at $BFBF
TIMING_LOOP  EQU $C000  ; INC DE / JR $-1, put in each bank tested
; tape block 3
BLOCK3_LEN   EQU 29796
PackedGame   EQU $83F9  ; the fourth stream of block 3
PACKED_GAME_LEN EQU 21193
GAME         EQU $6000
; layout of stage 2's own data
Picture      EQU $7000  ; the picture, RCS order: pixels by cells, then attributes
PictureAttrs EQU $8800
HOURGLASS    EQU $50BD  ; screen address of the hourglass (3x3 cells)
HOURGLASS_ATTR EQU $5ABD
HOURGLASS_INK  EQU $46  ; bright yellow on black

  ORG $6000
Stage2:
  LD SP,Stage2
  DI
  CALL DetectMachine
  CALL RevealPicture
  CALL InstallLoader
  LD IX,Block3
  LD DE,BLOCK3_LEN
.retry:
  PUSH IX
  PUSH DE
  CALL BuildFrameTable
  PUSH DE
  CALL DrawHourglass
  POP DE
  LD A,$FF              ; flag byte $FF, LOAD
  SCF
  CALL TapeLoader
  POP DE
  POP IX
  JR NC,.retry          ; a tape error: load the block again. Safe only for an
                        ; error in the first 1764 bytes: block 3 overwrites
                        ; BuildFrameTable ($6942) on, and a retry after that
                        ; runs block-3 data (observed with a simulated error
                        ; after 3000 bytes; after 1000 the retry works)
  DI
  LD A,(MachineType)
  PUSH AF               ; for the game: A = machine type (1 = 48K)
  DEC A
  JR NZ,Start128
; 48K: black attributes, then the loading screen comes up from block 3
  LD BC,$0300           ; B = 3 pages, C = 0
  LD HL,ATTRS
.black:
  LD (HL),C
  INC L
  JR NZ,.black
  INC H
  DJNZ .black
  LD HL,Block3
  CALL DepackScreen
; Both machines: move the packed game to the top of memory and unpack it
; to $6000 from the printer buffer; the depacker returns to the game.
StartGame:
  LD HL,Depack
  LD DE,PRINTER_BUF
  LD BC,DepackEnd-Depack
  LDIR
  LD HL,PackedGame
  LD BC,PACKED_GAME_LEN
  ADD HL,BC             ; one past the end: LDDR moves that byte to $0000
  LD DE,0               ; (the ROM) and the stream but its first byte to
  LDDR                  ; the top of memory
  LD A,(HL)
  LD (DE),A
  EX DE,HL
  LD DE,GAME
  PUSH DE
  JP PRINTER_BUF

; 128K: the screens and their depacker go to the fastest bank found, the
; music is unpacked after them, then the AY is looked for.
Start128:
  INC A
  CALL PageBank
  LD HL,DepackScreen
  LD DE,$C000
  LD BC,Block3-DepackScreen
  LDIR
  LD HL,Block3
  LD BC,PackedMusic-Block3
  LDIR
  CALL Depack           ; HL = PackedMusic, DE right after the screens
  LD DE,AY_SELECT*256+AY_DATA
  LD C,$FD
  LD L,0
  LD A,14
.silence:
  DEC A                 ; AY registers 13 to 0 := 0
  LD H,A
  CALL WriteAY
  JR NZ,.silence
  LD HL,$080F           ; register 8 := $0F, read back
  CALL WriteAY
  LD B,D
  IN A,(C)
  SUB L
  JR NZ,.noAY
  LD L,7                ; then := 7, read back
  CALL WriteAY
  LD B,D
  IN A,(C)
  SUB L
  JR NZ,.noAY
  LD A,1
  JR .ay
.noAY:
  XOR A
.ay:
  LD L,0
  CALL WriteAY
  POP BC                ; B = machine type (C = the flags pushed with it)
  LD C,A                ; C = 1 if an AY answered, 0 if not
  PUSH BC
  LD A,$10              ; bank 0, 48K ROM
  CALL PageBank
  JP StartGame

; Write L to AY register H (D, E: high bytes of the ports, C = $FD).
WriteAY:
  LD B,D
  OUT (C),H
  LD B,E
  OUT (C),L
  RET

; Detect a 128K machine: write $10 and $11 to $FFFF in banks 0 and 1. On a
; 48K machine the second write wins (type 1); on a 128K one MeasureBanks
; picks the bank to use.
DetectMachine:
  LD BC,BANK_PORT
  LD HL,$FFFF
  LD DE,$1110
  LD A,E
  CALL OutBank
  LD (HL),E
  LD A,D
  CALL OutBank
  LD (HL),D
  LD A,E
  CALL OutBank
  LD A,(HL)
  SUB E
  JR Z,MeasureBanks
SetMachine:
  LD (MachineType),A
  RET

; Page in the bank in A (with the ROM bit).
PageBank:
  LD BC,BANK_PORT
OutBank:
  OUT (C),A
  RET

; 128K: count how far INC DE gets in one frame in banks 1, 3, 4 and 6 and
; keep the fastest (uncontended) as the machine type; it is the port value.
; An IM 2 handler of POP HL / RET throws away the interrupted return
; address, so the interrupt returns from the CALL that waited for it.
MeasureBanks:
  LD (MeasureSP+1),SP
  LD HL,IM2_TABLE
  LD A,H
  LD I,A
  IM 2
  INC A
.table:
  LD (HL),A             ; $BF everywhere: vector $BFBF
  INC L
  JR NZ,.table
  INC H
  LD (HL),A
  LD L,A
  LD (HL),$E1           ; $BFBF: POP HL
  INC HL
  LD (HL),$C9           ;        RET
  LD A,$11
.bank:
  CALL OutBank
  LD HL,TIMING_LOOP
  LD (HL),$13           ; INC DE
  INC L
  LD (HL),$18           ; JR $-1
  INC L
  LD (HL),$FD
  LD DE,0
  CALL WaitInterrupt
  EI
  CALL TIMING_LOOP      ; returns at the next interrupt, DE = count
  PUSH AF
  PUSH DE
  INC A
  CP $12
  JR NZ,.not2
  INC A
.not2:
  CP $15
  JR NZ,.not5
  INC A
.not5:
  CP $17
  JR NZ,.bank
  LD A,$10
  CALL OutBank
  DI
  IM 1
  LD A,$3F
  LD I,A
  LD B,3
  POP DE
  POP AF
  LD C,A
.best:
  POP HL
  POP AF
  OR A
  SBC HL,DE
  JR C,.slower
  LD C,A
  ADD HL,DE
  EX DE,HL
.slower:
  DJNZ .best
MeasureSP:
  LD SP,MeasureSP       ; the operand is set at the start
  LD A,C
  JR SetMachine

; Wait for an interrupt (the IM 2 handler returns from this CALL).
WaitInterrupt:
  EI
  HALT

; 1 on a 48K machine; on 128K the port value of the bank in use ($11, $13,
; $14 or $16: the fastest of the banks measured).
MachineType:
  DEFB 0

; Unpack MegaLZ data from HL to DE. Copied to the printer buffer with the
; RET after it to unpack the game.
Depack:
  MEGALZ_DEPACK
  RET
DepackEnd:

; Unpack the MegaLZ stream at HL to the screen; the stream holds the screen
; in RCS order (scripts/megalz.py, rcs_address): DE counts on in that order
; and each byte, written or copied, goes through the address conversion.
DepackScreen:
  LD DE,$4000
  LD A,$80
  EX AF,AF'
.literal:
  LD A,(HL)
  INC HL
  LD B,1
  PUSH HL
  PUSH BC
.put:
  PUSH AF               ; write A at the screen address for DE
  LD C,E
  LD B,D
  LD A,D
  CP $58
  JR NC,.putattr
  XOR E
  AND $F8
  XOR E
  LD B,A
  XOR E
  XOR D
  RLCA
  RLCA
  LD C,A
.putattr:
  POP AF
  LD (BC),A
  INC DE
  POP BC
  DJNZ .next
  POP HL
.token:
  LD BC,$02FF
.getbits:
  EX AF,AF'
.nextbit:
  ADD A,A
  JR NZ,.havebit
  LD A,(HL)
  INC HL
  RLA
.havebit:
  RL C
  JR NC,.nextbit
  EX AF,AF'
  DJNZ .tree1
  LD A,2
  SRA C
  JR C,.long
  INC A
  INC C
  JR Z,.len3
  LD BC,$033F
  JR .getbits
.tree4:
  DJNZ .addlength
  LD B,C
.offset8:
  LD C,(HL)
  INC HL
.copy:
  DEC B
  PUSH HL
  LD L,C
  LD H,B
  ADD HL,DE             ; HL = logical source, B = length
  LD B,A
.next:
  PUSH BC               ; read the byte at the screen address for HL
  LD C,L
  LD B,H
  LD A,H
  CP $58
  JR NC,.getattr
  XOR L
  AND $F8
  XOR L
  LD B,A
  XOR L
  XOR H
  RLCA
  RLCA
  LD C,A
.getattr:
  LD A,(BC)
  INC HL
  JR .put
.tree1:
  DJNZ .tree2
  SRL C
  JR C,.literal
  INC B
  JR .getbits
.addlength:
  ADD A,C
.len3:
  LD BC,$04FF
  JR .getbits
.long:
  INC C
  JR NZ,.offset8
  EX AF,AF'
  INC B
.gamma:
  RR C
  RET C
  RL B
  ADD A,A
  JR NZ,.gammabit
  LD A,(HL)
  INC HL
  RLA
.gammabit:
  JR NC,.gamma
  EX AF,AF'
  ADD A,B
  LD B,6
  JR .getbits
.tree2:
  DJNZ .tree3
  LD A,1
  JR .copy
.tree3:
  DJNZ .tree4
  INC C
  JR NZ,.offset8
  LD BC,$051F
  JR .getbits

; Tape block 3 loads from here on, over the rest of this stage's code.
Block3:
; The end of RevealPicture: put the stack back, black border.
RevealExit:
  LD SP,RevealExit      ; the operand is set by RevealPicture
  XOR A
  OUT ($FE),A
  RET

; Reveal the picture at $7000 cell by cell in the order of RevealOrder,
; each cell with two clicks (the speaker bit from a ROM byte, the MIC bit
; from R).
RevealPicture:
  LD A,(BORDCR)
  RRA
  RRA
  RRA
  AND 7
  LD C,A                ; the border colour
  LD (RevealExit+1),SP
  LD SP,RevealOrder
.cell:
  POP DE                ; DE = cell number 0-767
  LD A,(DE)             ; a ROM byte: its bit 4 drives the speaker
  AND $10
  OR C
  OUT ($FE),A
  LD A,D
  AND E
  INC A
  JR Z,RevealExit       ; $FFFF: done
  LD HL,PictureAttrs
  ADD HL,DE
  LD A,D
  ADD A,high ATTRS
  LD D,A
  LD A,(HL)
  LD (DE),A             ; the attribute
  LD A,D                ; DE = top pixel row of the cell
  ADD A,A
  ADD A,A
  ADD A,A
  AND $18
  ADD A,$40
  LD D,A
  LD A,H                ; HL = the cell's 8 bytes in RCS order: third,
  RLC L                 ; column, row of the cell
  RLC L
  RLC L
  SUB high PictureAttrs
  LD H,A
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD A,high Picture
  ADD A,H
  LD H,A
  DUP 7
  LD A,(HL)
  LD (DE),A
  INC L
  INC D
  EDUP
  LD A,(HL)
  LD (DE),A
  LD A,R                ; bit 3 (MIC) from R: a second click; the border stays C
  AND 8
  OR C
  OUT ($FE),A
  LD B,26
.delay:
  DJNZ .delay
  JR .cell

; Order of the cells revealed (768 cell numbers, row*32+column, from the
; middle outwards), ended by $FFFF.
RevealOrder:
  DEFW $0190,$016F,$0170,$018F,$014F,$016E,$0150,$018E,$0191,$01AF,$0171,$01B0
  DEFW $01AE,$0151,$014E,$01B1,$012F,$016D,$018D,$0130,$01CF,$0172,$0192,$01D0
  DEFW $01CE,$012E,$01D1,$0131,$01AD,$014D,$01B2,$0152,$0132,$01D2,$012D,$01CD
  DEFW $010F,$016C,$018C,$0110,$010E,$01EF,$0173,$0193,$01F0,$01F1,$0111,$01EE
  DEFW $0153,$01B3,$01ED,$014C,$0112,$010D,$01AC,$01CC,$0133,$012C,$01F2,$01D3
  DEFW $0113,$016B,$018B,$00F0,$010C,$01EC,$01F3,$00EF,$020F,$0174,$0194,$0210
  DEFW $0211,$00EE,$00F1,$014B,$020E,$0154,$01B4,$020D,$00ED,$0212,$00F2,$01AB
  DEFW $00EC,$020C,$00F3,$0134,$0213,$012B,$01EB,$0114,$010B,$016A,$018A,$00D0
  DEFW $01D4,$01F4,$00F4,$01CB,$022F,$00CF,$0175,$0195,$0230,$0231,$00CE,$0155
  DEFW $00EB,$020B,$022E,$00D1,$00CD,$01B5,$00D2,$022D,$014A,$01AA,$0214,$022C
  DEFW $0232,$00CC,$01CA,$012A,$00F5,$0169,$0189,$0233,$00D3,$022B,$00CB,$01D5
  DEFW $0135,$0234,$020A,$0215,$00EA,$024F,$00B0,$0176,$0196,$00AF,$0250,$024E
  DEFW $0251,$00AD,$0156,$00D4,$00D5,$01EA,$00B1,$0252,$0149,$01A9,$00B2,$01B6
  DEFW $024D,$024C,$00CA,$022A,$01F5,$00AC,$0253,$00B3,$01C9,$010A,$0235,$0115
  DEFW $024B,$0168,$0188,$00AE,$01D6,$0129,$00B4,$00AB,$0136,$0109,$00D6,$00C9
  DEFW $026F,$0090,$0177,$008F,$0197,$0270,$026E,$0091,$0271,$008D,$0116,$00AA
  DEFW $0255,$0229,$0236,$00B6,$0254,$0148,$0272,$01A8,$0157,$026C,$0093,$024A
  DEFW $01F6,$01E9,$00E9,$0209,$008E,$01B7,$026D,$0092,$0137,$008C,$026B,$008B
  DEFW $00B5,$00A9,$0249,$0216,$0167,$0187,$0273,$01D7,$0128,$008A,$026A,$01C8
  DEFW $0108,$01E8,$0256,$00B7,$028F,$0070,$0178,$006F,$0198,$0290,$028E,$0071
  DEFW $006D,$0094,$0274,$01F7,$0117,$0276,$0248,$00A8,$0095,$0291,$01B8,$0147
  DEFW $0292,$01A7,$0158,$0089,$0257,$0097,$00F6,$00D7,$0275,$006E,$028D,$006C
  DEFW $0073,$028C,$0127,$01C7,$0138,$028B,$0269,$0228,$00C8,$028A,$0186,$0293
  DEFW $01D8,$0074,$006B,$0294,$01E7,$0098,$0208,$0237,$02AF,$0166,$004F,$0199
  DEFW $02B0,$0179,$02AE,$0051,$01B9,$0072,$006A,$0107,$0069,$0289,$0096,$01F8
  DEFW $0118,$00E7,$00F7,$0088,$0268,$00E8,$0277,$00A7,$0050,$02B1,$0146,$02B2
  DEFW $004C,$01A6,$0159,$0295,$0075,$0296,$0267,$0247,$0076,$02AD,$02B3,$0139
  DEFW $0053,$01D9,$02AB,$0126,$01C6,$0054,$02AA,$00F8,$0297,$0068,$0278,$0078
  DEFW $0087,$00B8,$02A9,$0185,$004E,$02AC,$004B,$004A,$0218,$0207,$0288,$02CF
  DEFW $0165,$002F,$019A,$02D1,$017A,$0031,$01BA,$01A5,$0052,$02B4,$0055,$01F9
  DEFW $01E6,$0206,$0079,$0227,$0030,$02CE,$02D2,$0145,$002C,$013A,$02B5,$0106
  DEFW $0049,$02A8,$00E6,$0219,$00F9,$0067,$0217,$0287,$0099,$0086,$0258,$02D3
  DEFW $002B,$01DA,$02CB,$01C5,$0034,$0056,$0048,$0057,$02B7,$0047,$0077,$0286
  DEFW $0299,$00D8,$0266,$002E,$02CD,$0033,$0125,$02CA,$02B6,$02B8,$0059,$00C7
  DEFW $02C9,$02EF,$0164,$019B,$02F1,$017B,$0184,$01BB,$0011,$015A,$01A4,$02CC
  DEFW $02D4,$0035,$002A,$02D5,$0029,$02A7,$005A,$007A,$0066,$02C8,$0010,$000F
  DEFW $02EE,$02F2,$0144,$0032,$000C,$013B,$011A,$01FA,$0105,$0028,$0205,$00E5
  DEFW $0226,$0246,$002D,$02F3,$0124,$000B,$01C4,$02EA,$0119,$02D6,$0037,$021A
  DEFW $00FA,$00C5,$00D9,$0046,$00C6,$02A6,$0065,$0259,$000E,$02ED,$02EC,$02F4
  DEFW $0014,$01DB,$0015,$011B,$02E9,$02C7,$0027,$02D8,$0026,$02A5,$02BA,$0285
  DEFW $02E8,$0163,$019C,$017C,$0183,$01BC,$015B,$0012,$01A3,$02EB,$000A,$0036
  DEFW $0009,$0038,$00DA,$0225,$02D9,$0058,$003A,$0279,$02D7,$02D0,$004D,$0143
  DEFW $013C,$0104,$02F5,$0016,$01FB,$01E5,$0204,$023A,$02C6,$0298,$003B,$005B
  DEFW $0238,$0045,$00A6,$01C3,$0013,$00E4,$0007,$02E7,$00C4,$023B,$00DB,$0224
  DEFW $00B9,$0245,$0044,$000D,$0123,$01DC,$0103,$01E3,$011C,$01E4,$0008,$02F7
  DEFW $0017,$02F9,$0239,$0025,$02C4,$0265,$027A,$0162,$019D,$0182,$01BD,$01A2
  DEFW $021B,$0018,$0006,$0005,$02C5,$02DB,$02A4,$02F8,$017D,$015C,$013D,$01FC
  DEFW $02E6,$0039,$00A5,$001C,$00BA,$003C,$02F0,$0142,$01C2,$021C,$0223,$0019
  DEFW $02FA,$02E5,$0085,$029A,$0122,$01FD,$01E2,$00E3,$00C3,$023C,$00DC,$00A3
  DEFW $02B9,$0024,$0244,$0023,$0264,$0161,$019E,$01A1,$01BE,$0102,$011D,$02F6
  DEFW $00BB,$02E3,$02C3,$029B,$017E,$0181,$015D,$01DD,$00FB,$0004,$00A4,$02FC
  DEFW $001D,$005C,$0284,$0121,$013E,$021D,$0222,$025C,$00BC,$0243,$02E4,$0141
  DEFW $01C1,$011E,$01E1,$00C2,$00A2,$025D,$00BD,$0242,$001A,$009B,$0022,$0043
  DEFW $0160,$019F,$01A0,$01BF,$01DE,$01FE,$0101,$0003,$0263,$0002,$0283,$0084
  DEFW $02BB,$017F,$0180,$015E,$00FE,$0203,$00FC,$025A,$02DA,$02FD,$02E2,$0064
  DEFW $02BC,$0120,$011F,$023D,$025B,$0083,$003D,$02A3,$0140,$01C0,$021E,$00E2
  DEFW $0221,$001B,$009C,$01DF,$01FF,$0100,$01E0,$00FF,$0202,$00C1,$0241,$00A1
  DEFW $025E,$00BE,$0082,$009A,$001E,$0001,$02C2,$0081,$009D,$0282,$02DC,$015F
  DEFW $00E0,$023E,$00FD,$02A2,$0063,$02BD,$021F,$0200,$0201,$023F,$00DD,$0240
  DEFW $009E,$007C,$027B,$013F,$00E1,$027E,$0260,$02FB,$02DD,$00C0,$0080,$027F
  DEFW $009F,$0262,$007D,$02E1,$0281,$02A1,$00DE,$00A0,$027C,$0062,$0042,$007B
  DEFW $02DE,$025F,$0061,$0060,$029C,$02C1,$027D,$007E,$007F,$02A0,$02C0,$02FE
  DEFW $0220,$00DF,$005E,$0261,$0021,$02FF,$0040,$005F,$029D,$00BF,$0280,$02E0
  DEFW $0041,$029E,$005D,$0020,$0000,$029F,$02BE,$003E,$003F,$02DF,$02BF,$001F
  DEFW $FFFF

; The edge routines of the tape loader with the hourglass (copied to $FE8D
; by InstallLoader): LD-EDGE-2 and LD-EDGE-1 of the ROM, where LD-EDGE-1
; first draws a quarter of the current hourglass frame (8 bytes) instead of
; the ROM's delay loop.
EdgeRoutines:
  DISP $FE8D
LdEdge2:
  CALL LdEdge1
  RET NC
LdEdge1:
  LD A,E                ; frame offset for the high byte of the bytes left;
  RRA                   ; bit 0 of the low byte picks the set of frames
  LD A,D
  EXX
  LD DE,FrameTable
  LD E,A
  LD A,(DE)
  LD L,A
  LD A,high FramesEven
  ADC A,0
  LD H,A
  LD (EdgeSP+1),SP
  LD SP,HL
EdgeQuarter:
  LD A,0                ; the quarter drawn last (0-3)
  INC A
  AND 3
  LD (EdgeQuarter+1),A
  LD E,A
  XOR A
  LD D,A
  LD HL,QuarterOffset
  ADD HL,DE
  LD L,(HL)
  LD H,D
  ADD HL,SP
  LD SP,HL
  SLA E
  LD HL,QuarterScreen
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  DUP 3
  POP BC
  LD (HL),C
  INC H
  LD (HL),B
  INC H
  EDUP
  POP BC
  LD (HL),C
  INC H
  LD (HL),B
EdgeSP:
  LD SP,EdgeSP          ; the operand is set above
  EXX
.sample:                ; the ROM's LD-SAMPLE
  INC B
  RET Z
  LD A,$7F
  IN A,($FE)
  RRA
  NOP                   ; the ROM has RET NC (BREAK) here
  XOR C
  AND $20
  JR Z,.sample
  LD A,C
  CPL
  LD C,A
  AND 0                 ; the ROM has AND 7: the border stays black
  OR 8
  OUT ($FE),A
  SCF
  RET
; Byte offset in a frame and screen address of each quarter: the middle
; column of the hourglass, rows 0, 1, 2, 1.
QuarterOffset:
  DEFB 0,8,16,8
QuarterScreen:
  DEFW HOURGLASS+1,HOURGLASS+$21,HOURGLASS+$41,HOURGLASS+$21
  ENT
EdgeRoutinesEnd:

; Fill FrameTable for DE bytes to load: the frame offset (0, 24, ... 216)
; goes up by one frame every 1/10 of the pages.
BuildFrameTable:
  LD BC,10
  LD A,E
  CP 1
  CCF
  LD A,D
  ADC A,0               ; pages, rounded up
.divide:
  INC B
  SUB C
  JR NC,.divide
  LD C,B                ; pages per frame
  XOR A
  LD HL,FrameTable
.fill:
  LD (HL),A
  INC L
  JR Z,.done
  DJNZ .fill
  LD B,C
  ADD A,24
  JR NC,.fill
.done:
  RET

; Copy LD-BYTES from the ROM to $FE00 and patch it: black border, no
; return address pushed, and (when the ROM's LD-EDGE-1 is the standard one)
; the edge routines with the hourglass.
InstallLoader:
  LD HL,LD_BYTES
  LD DE,TapeLoader
  LD BC,LD_EDGE_2-LD_BYTES
  LDIR
  LD BC,EdgeRoutinesEnd-EdgeRoutines
  LD A,(LD_EDGE_1)
  CP $C3
  JR Z,.patch
  XOR A
  LD (DrawHourglass),A  ; RET -> NOP: draw the hourglass
  LD (TL_EDGE_CALL),DE
  LD HL,EdgeRoutines
  LDIR
.patch:
  LD HL,TL_BORDER
  LD (HL),0
  LD HL,TL_PUSH
  LD (HL),C             ; NOP (C = 0 after the copy). Unknown: with the
                        ; other ROM C = $70, LD (HL),B
  LD HL,TL_8BITS
  LD (TL_8BITS_JP),HL
  RET

; Draw the hourglass at HOURGLASS: frames to FramesEven and FramesOdd,
; the attributes, the outline. The RET is made a NOP by InstallLoader.
DrawHourglass:
  RET
  LD HL,HourglassFramesEven
  LD DE,FramesEven
  LD BC,240
  LDIR
  LD DE,FramesOdd
  LD BC,240
  LDIR
  LD HL,HOURGLASS_ATTR
  LD DE,30
  LD BC,3*256+HOURGLASS_INK
.attr:
  LD (HL),C
  INC HL
  LD (HL),C
  INC HL
  LD (HL),C
  ADD HL,DE
  DJNZ .attr
  LD DE,HOURGLASS
  LD HL,HourglassOutline
  CALL .column
  LD DE,HOURGLASS+1
  CALL .column
  LD DE,HOURGLASS+2
.column:                ; three cells down from DE
  LD BC,$0703
.cell:
  PUSH BC
.row:
  LD A,(HL)
  LD (DE),A
  INC HL
  INC D
  DJNZ .row
  LD A,(HL)
  LD (DE),A
  INC HL
  LD A,E
  ADD A,32
  LD E,A
  LD A,D
  SUB 7
  LD D,A
  POP BC
  DEC C
  JR NZ,.cell
  RET

; The hourglass, three columns of three cells.
HourglassOutline:
  DEFB $0E,$0D,$05,$05,$0D,$05,$0D,$04
  DEFB $0C,$06,$04,$04,$04,$06,$0C,$06
  DEFB $04,$0D,$05,$0D,$05,$05,$0D,$0E
  DEFB $FF,$80,$7F,$7F,$7F,$7F,$7F,$BE
  DEFB $5D,$2A,$2A,$1C,$14,$22,$22,$41
  DEFB $80,$00,$00,$00,$00,$00,$80,$FF
  DEFB $B8,$D8,$50,$50,$58,$50,$58,$B0
  DEFB $18,$30,$10,$10,$10,$30,$18,$30
  DEFB $90,$58,$50,$58,$50,$50,$D8,$B8

; Ten frames of the middle column (3 cells, 24 bytes each), two sets
; chosen by bit 0 of the bytes left: HourglassFramesEven for an even count,
; HourglassFramesOdd for an odd one. The sets are not the top and bottom of
; the hourglass: they differ only in the falling grains, so the stream
; flickers as bytes come in. Frame 0 has all the sand below (the end of the
; load), frame 9 all of it above; FrameTable picks the frame from the high
; byte of the bytes left (observed by running LdEdge1 with DE = $7464 down
; to $0010: the sand runs from the top into the bottom).
HourglassFramesEven:
  DEFB $FF,$80,$00,$00,$00,$00,$00,$80
  DEFB $55,$2A,$2A,$14,$1C,$22,$2A,$5D
  DEFB $BE,$7F,$7F,$7F,$7F,$7F,$80,$FF
  DEFB $FF,$80,$00,$00,$00,$00,$00,$80
  DEFB $5D,$2A,$2A,$14,$1C,$22,$2A,$49
  DEFB $BE,$7F,$7F,$7F,$7F,$7F,$80,$FF
  DEFB $FF,$80,$00,$00,$00,$00,$00,$B6
  DEFB $5D,$2A,$2A,$14,$1C,$22,$2A,$49
  DEFB $9C,$3E,$7F,$7F,$7F,$7F,$80,$FF
  DEFB $FF,$80,$00,$00,$00,$00,$41,$BE
  DEFB $5D,$2A,$2A,$14,$1C,$22,$2A,$49
  DEFB $9C,$1C,$3E,$7F,$7F,$7F,$80,$FF
  DEFB $FF,$80,$00,$00,$00,$41,$63,$BE
  DEFB $5D,$2A,$2A,$14,$1C,$22,$2A,$41
  DEFB $88,$1C,$3E,$7F,$7F,$7F,$80,$FF
  DEFB $FF,$80,$00,$00,$00,$63,$7F,$BE
  DEFB $5D,$2A,$2A,$14,$1C,$22,$2A,$41
  DEFB $88,$08,$1C,$3E,$7F,$7F,$80,$FF
  DEFB $FF,$80,$00,$00,$41,$77,$7F,$BE
  DEFB $5D,$2A,$2A,$14,$1C,$22,$2A,$41
  DEFB $88,$00,$08,$1C,$3E,$7F,$80,$FF
  DEFB $FF,$80,$00,$41,$77,$7F,$7F,$BE
  DEFB $5D,$2A,$2A,$14,$1C,$22,$2A,$41
  DEFB $88,$00,$08,$08,$1C,$3E,$80,$FF
  DEFB $FF,$80,$41,$77,$7F,$7F,$7F,$BE
  DEFB $5D,$2A,$2A,$14,$1C,$22,$2A,$41
  DEFB $88,$00,$08,$00,$08,$1C,$80,$FF
  DEFB $FF,$80,$7F,$7F,$7F,$7F,$7F,$BE
  DEFB $5D,$2A,$2A,$14,$1C,$22,$2A,$41
  DEFB $88,$00,$08,$00,$08,$00,$80,$FF
HourglassFramesOdd:
  DEFB $FF,$80,$00,$00,$00,$00,$00,$80
  DEFB $55,$2A,$2A,$1C,$14,$2A,$2A,$5D
  DEFB $BE,$7F,$7F,$7F,$7F,$7F,$80,$FF
  DEFB $FF,$80,$00,$00,$00,$00,$00,$80
  DEFB $5D,$2A,$2A,$1C,$14,$2A,$22,$49
  DEFB $BE,$7F,$7F,$7F,$7F,$7F,$80,$FF
  DEFB $FF,$80,$00,$00,$00,$00,$00,$B6
  DEFB $5D,$2A,$2A,$1C,$14,$2A,$22,$49
  DEFB $9C,$3E,$7F,$7F,$7F,$7F,$80,$FF
  DEFB $FF,$80,$00,$00,$00,$00,$41,$BE
  DEFB $5D,$2A,$2A,$1C,$14,$2A,$22,$49
  DEFB $9C,$1C,$3E,$7F,$7F,$7F,$80,$FF
  DEFB $FF,$80,$00,$00,$00,$41,$63,$BE
  DEFB $5D,$2A,$2A,$1C,$14,$2A,$22,$49
  DEFB $88,$1C,$3E,$7F,$7F,$7F,$80,$FF
  DEFB $FF,$80,$00,$00,$00,$63,$7F,$BE
  DEFB $5D,$2A,$2A,$1C,$14,$2A,$22,$49
  DEFB $80,$08,$1C,$3E,$7F,$7F,$80,$FF
  DEFB $FF,$80,$00,$00,$41,$77,$7F,$BE
  DEFB $5D,$2A,$2A,$1C,$14,$2A,$22,$49
  DEFB $80,$08,$08,$1C,$3E,$7F,$80,$FF
  DEFB $FF,$80,$00,$41,$77,$7F,$7F,$BE
  DEFB $5D,$2A,$2A,$1C,$14,$2A,$22,$49
  DEFB $80,$08,$00,$08,$1C,$3E,$80,$FF
  DEFB $FF,$80,$41,$77,$7F,$7F,$7F,$BE
  DEFB $5D,$2A,$2A,$1C,$14,$2A,$22,$49
  DEFB $80,$08,$00,$08,$08,$1C,$80,$FF
  DEFB $FF,$80,$7F,$7F,$7F,$7F,$7F,$BE
  DEFB $5D,$2A,$2A,$1C,$14,$2A,$22,$49
  DEFB $80,$08,$00,$08,$00,$08,$80,$FF

; Unused up to the picture.
  DS Picture-$,0

  ORG Picture
  INCBIN "build/picture.rcs"   ; data/picture.scr in RCS order

PackedMusic EQU $712E   ; the third stream of block 3

  SAVEBIN "build/stage2.bin",Stage2,$-Stage2
