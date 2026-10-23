; Program entry: set up the stack and run a decryption loop that changes
; nothing
;
; Entered once, from the BASIC loader's jump to $8400. Disables interrupts (no
; instruction later in the program enables them), plants the return address
; RunCodeCheck by hand at $5BFE/$5BFF, points SP at it and then runs a loop
; over $8500-$FFFF. The loop reads each byte, computes A = L XOR byte XOR H,
; discards A and writes the byte back unchanged, so memory is the same
; afterwards (checked with the simulator: no byte of $8000-$FFFF differs when
; $869F is reached). Its only effect is a delay of about 22 frames; why it is
; there is Unknown (it looks like the shell of a decryptor with the key
; removed). The final RET pops the planted word and starts RunCodeCheck with
; SP=$5C00 and HL=$0000.
;
; Hardware: DI only.
StartProgram:
  DI
  LD HL,SCREEN_ATTRS_BUF-$0001 ; planted return address: high byte at $5BFF,
                               ; low byte at $5BFE
  LD (HL),RunCodeCheck>>8
  DEC HL
  LD (HL),RunCodeCheck&$FF
  LD SP,SCREEN_ATTRS_BUF-$0002
  SUB A
  LD L,A
  XOR $0A
  LD B,A
  INC B
  LD H,B                  ; B=$0B
  RRC H                   ; H=$85: HL=$8500
StartProgram_Loop:
  LD C,(HL)
  LD A,L                  ; A is computed but never used
  XOR C
  XOR H
  LD (HL),C               ; the byte is written back as it was read
  INC HL
  BIT 7,H                 ; loop until HL wraps from $FFFF to $0000
  JR NZ,StartProgram_Loop
  RET                     ; returns to RunCodeCheck
