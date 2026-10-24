; MegaLZ depacker (the short version by fyrex and Mayhem), as a macro: the
; loader has two copies of it, in the BASIC string (Stage1) and in stage 2
; (Depack). Format: scripts/megalz.py.
;   HL = packed data, DE = destination. The output goes up from DE.
;   A' = bit buffer: bits are taken from its top, a 1 trails the last bit
;   (the first ADD A,A of $80 gives zero, so a byte is fetched).
;   B counts down which branch of the code tree a DJNZ chain lands on, C
;   gathers the bits read and stops the reading when its top bit leaves.
; Returns (RET C) when the end code is read; HL then points past it.
  MACRO MEGALZ_DEPACK
  LD A,$80
  EX AF,AF'
.literal:
  LDI                   ; a literal byte (the first byte is always one)
.token:
  LD BC,$02FF           ; read one bit: 1 = literal
.getbits:
  EX AF,AF'
.nextbit:
  ADD A,A
  JR NZ,.havebit
  LD A,(HL)             ; bit buffer empty: next byte, a 1 shifted in as the end mark
  INC HL
  RLA
.havebit:
  RL C
  JR NC,.nextbit        ; until the top bit of C leaves
  EX AF,AF'
  DJNZ .tree1
  LD A,2                ; after the two bits that follow a 0
  SRA C
  JR C,.long            ; x1: 2 bytes (01) or a gamma length (11)
  INC A
  INC C
  JR Z,.len3            ; 10: 3 bytes
  LD BC,$033F           ; 00: 1 byte from distance 1-8, three bits
  JR .getbits
.tree1:
  DJNZ .tree2
  SRL C
  JR C,.literal
  INC B
  JR .getbits           ; read two more bits
.addlength:
  ADD A,C               ; length = 2 + 2^(k+1) + the k+1 bits
.len3:
  LD BC,$04FF           ; offset kind: one bit
  JR .getbits
.long:
  INC C
  JR NZ,.offset8        ; 01: 2 bytes, an 8-bit offset
  EX AF,AF'
  INC B
.gamma:
  RR C                  ; count zero bits; the eighth one is the end code
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
  JR .getbits           ; k+1 bits, C holds the stop mark
.tree2:
  DJNZ .tree3
  LD A,1                ; 1 byte: offset $FFF8-$FFFF in C
  JR .copy
.tree3:
  DJNZ .tree4
  INC C
  JR NZ,.offset8        ; 0: an 8-bit offset
  LD BC,$051F           ; 1: four bits of the high byte, then the low byte
  JR .getbits
.tree4:
  DJNZ .addlength
  LD B,C
.offset8:
  LD C,(HL)
  INC HL
.copy:
  DEC B                 ; BC = offset (negative)
  PUSH HL
  LD L,C
  LD H,B
  ADD HL,DE
  LD C,A
  LD B,0
  LDIR
  POP HL
  JR .token
  ENDM
