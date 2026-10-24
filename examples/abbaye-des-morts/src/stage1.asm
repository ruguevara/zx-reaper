; Loader, first stage: the variables area of the BASIC program (tape block 2
; after the 40 bytes of src/loader.bas). It is the string variable l$, and
; line 10 calls its contents: PRINT USR (VARS+3).
;
; Stage1 moves the packed second stage to the top of memory and unpacks it
; to $6000 (src/stage2.asm), then returns to it.
  DEVICE ZXSPECTRUM48
  INCLUDE "megalz.asm"

  ORG $5CF3             ; VARS: BASIC's 40 bytes start at PROG = $5CCB
LoaderString:
  DEFB $4C              ; a string variable, l$
  DEFW Stage1End-Stage1 ; its length (the last byte is the end of the variables)

; Called by USR with BC = its own address.
Stage1:
  DI
  LD H,B
  LD L,C
  LD SP,HL              ; the stack goes down from here, below the string
  LD HL,Stage1End-1-Stage1
  ADD HL,BC
  LD DE,$FFFF
  LD BC,Stage1End-PackedStage2
  LDDR                  ; packed stage 2 to the top of memory (to $FFFF)
  INC DE
  LD HL,STAGE2          ; unpack to $6000 and return there
  PUSH HL
  EX DE,HL
  MEGALZ_DEPACK

PackedStage2:
  INCBIN "build/stage2.mlz"
  DEFB $80              ; the end of the variables (the string ends with it)
Stage1End:

STAGE2 EQU $6000

  SAVEBIN "build/stage1.bin",LoaderString,Stage1End-LoaderString
