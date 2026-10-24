; IM 2 interrupt handler: runs the frame routine on its own stack
;
; Entered by the 50 Hz frame interrupt (IM 2, I = $84: every byte of the vector
; table at Im2Table is $85, so every vector is $8585). It swaps HL with the
; return address on the stack, stores the return address in the operand of the
; JP at SmcInterruptReturn and the interrupted SP in the operand of the LD SP
; at SmcInterruptSP, switches SP to the interrupt stack (InterruptStack, which
; ends at $8585), pushes IX, HL, AF, BC, DE, IY and the alternate set, and
; calls the routine whose address is in InterruptRoutine through JumpToHL (JP
; (HL)). Afterwards it pops everything, enables interrupts and returns with LD
; SP and JP through the two patched operands. The interrupted code needs no
; stack room: the main loop runs the frame list with SP as a data pointer
; (RunFrameList) and is interrupted in the middle of it.
;
; The routine called is GameFrameRoutine while the game (or the intro room 0)
; runs, MenuFrame during the title and the controls menu, and the RET at
; NoFrameRoutine before the game starts (StartUp). One run of GameFrameRoutine
; takes about 5,500 to 7,300 T-states, plus a burst of up to 9,000 for a beeper
; sound effect, of the 69,888 of a frame (observed with the simulator, frames
; 200-260 of tests/inputs/play.txt: interrupt accepted at T 19-28 of the frame,
; EndFrameList reached at T 5,700-7,300).
;
; Hardware: the IM 2 frame interrupt. Interrupts stay disabled until the EI at
; 85B5, so the frame routine is never interrupted. By reading the code (not
; seen): an interrupt accepted between that EI and the JP at SmcInterruptReturn
; would store $85B9 as the return address and then hang on JP $85B9; it needs a
; run of the handler that ends exactly as the next frame starts.
;
; O:All All registers are restored; the interrupted code goes on unaware
InterruptHandler:
  EX (SP),HL              ; HL = interrupted PC; the old HL is now on the stack
  LD (SmcInterruptReturn+$0001),HL ; return address: operand of the JP at $85B9
  POP HL                  ; HL as it was
  LD (SmcInterruptSP+$0001),SP ; interrupted SP: operand of the LD SP at $85B6
  PUSH BC                 ; no effect: writes BC below the interrupted SP,
                          ; never read back (BC is pushed again at $8597)
  DI                      ; (the CPU disabled interrupts when it accepted this
                          ; one)
  LD SP,InterruptHandler  ; interrupt stack, InterruptStack-$8584
  PUSH IX
  PUSH HL
  PUSH AF
  PUSH BC
  PUSH DE
  EXX                     ; switch to the alternate set, saved next
  EX AF,AF'
  PUSH IY
  PUSH HL
  PUSH AF
  PUSH BC
  PUSH DE
  LD HL,(InterruptRoutine) ; frame routine address
  CALL JumpToHL           ; JP (HL): call the frame routine
  POP DE
  POP BC
  POP AF
  POP HL
  POP IY
  EX AF,AF'
  EXX
  POP DE
  POP BC
  POP AF
  POP HL
  POP IX
  EI                      ; the only EI of the frame; takes effect after the LD
                          ; SP
SmcInterruptSP:
  LD SP,SmcInterruptSP    ; SMC: the operand is the interrupted SP, stored by
                          ; the LD at $858A
SmcInterruptReturn:
  JP SmcInterruptReturn   ; SMC: the operand is the interrupted PC, stored by
                          ; the LD at $8586

  ORG $85BC+SHIFT
; Jump to HL
;
; A CALL to this address is an indirect call through HL. Used by the interrupt
; handler InterruptHandler (HL = the frame routine from InterruptRoutine) and
; by the draw queue runner BuildRedrawList (HL = the handler of a queued job).
;
; HL Address to jump to
JumpToHL:
  JP (HL)

; Unused RET
;
; Nothing refers to this RET (not executed with any input in re/maps).
UnusedRet:
  RET

; 128K: page in bank 0 with ROM 1
;
; Writes $10 to port $7FFD: RAM bank 0 at $C000, ROM 1, normal screen, which is
; the paging state of the game. The 128K hooks use it as the return address of
; a call into the music bank (CallInMusicBank); the start-up code (StartUp)
; calls it on every machine, where on a 48K Spectrum it does nothing visible.
;
; Hardware: writes the 128K paging port $7FFD (through PageInBank).
;
; O:A $10, the value written
PageInBank0:
  LD A,PAGING_BANK0
  JR PageInBank

; 128K: call the routine DE in the music bank
;
; Pushes the address of PageInBank0 (page bank 0 back in) and then DE, and
; falls into PageInMusicBank, which pages the music bank in and RETs: the RET
; jumps to DE, and the RET at the end of that routine returns to PageInBank0,
; which restores bank 0 and returns to the caller of this routine. HL and the
; other registers reach the music routine unchanged, except BC.
;
; Hardware: writes the paging port $7FFD (through PageInBank).
;
;   DE Address of the routine in the music bank ($C000-$FFFF)
;   HL Argument passed on to that routine (module address, see
;      MusicEntryEnding)
; O:BC Changed
CallInMusicBank:
  LD BC,PageInBank0       ; return address of the music routine
  PUSH BC
  PUSH DE                 ; the RET at $85D4 jumps here
PageInMusicBank:
  LD A,(MachineType)      ; port value that selects the music bank
                          ; (MachineType)

; 128K: page in bank A
;
; Writes A to the 128K paging port and remembers it in PagingState. BC is saved
; and restored.
;
; Hardware: writes port $7FFD (nothing happens on a 48K Spectrum).
;
; A Value for port $7FFD (bits 0-2 RAM bank at $C000, bit 4 ROM)
PageInBank:
  PUSH BC
  LD BC,PAGING_PORT
  LD (PagingState),A      ; last value written, for PlayEffectOnAY
  OUT (C),A
  POP BC
  RET

; 128K: sound effect through the AY player (replaces PlaySoundStep)
;
; On a 128K machine where the loader found an AY chip, Patch128KHooks turns the
; first instruction of PlaySoundStep (LD HL,$85D5) into JP $85D5, so the frame
; routine GameFrameRoutine comes here instead of playing a beeper effect. The
; routine saves the current paging, pages in the music bank (PageInMusicBank),
; calls $CF7D in that bank, restores the paging and returns to the caller of
; PlaySoundStep. $CF7D is not disassembled (the music bank is not part of this
; image): it presumably reads the effect request SoundRequest, but whether it
; clears it and what the effect numbers mean on the AY is Unknown.
;
; Hardware: writes the paging port $7FFD (through PageInBank, PageInMusicBank);
; the AY itself is driven by the music bank code.
PlayEffectOnAY:
  LD A,(PagingState)      ; current paging (PagingState)
  PUSH AF
  CALL PageInMusicBank
  CALL $CF7D              ; AY sound effect routine in the music bank
  POP AF
  JR PageInBank           ; restore the paging and return

; Frame routine of the game: sound effect, then the game frame
;
; The routine the interrupt handler InterruptHandler calls each frame during
; the game and the intro room 0: StartGame puts its address in InterruptRoutine
; after the title menu. It plays one step of the beeper sound effect
; (PlaySoundStep) and jumps to the game frame GameFrame. The sound step comes
; first: when an effect is playing it keeps the CPU for about 7,000 T-states
; (observed), so the game logic of that frame starts later in the frame.
;
; Hardware: the beeper, through PlaySoundStep.
GameFrameRoutine:
  CALL PlaySoundStep
  JP GameFrame

; 128K: music player entry points
;
; Three entry points that load the registers for CallInMusicBank and call a
; routine of the music player in the music bank. The 128K code is not
; disassembled and was not run (the simulator is a 48K machine), so what each
; call does is a guess from the callers: Unknown. The names are the callers'
; names.
;
; MusicEntryEnding: DE = $FC4B, HL as the caller left it; called by RunEnding
; at the end of the ending (the stub at $88D5 that Patch128KHooks turns into
; CALL $85E8). Probably silences the music.
;
; MusicEntryInfo: HL = $CA8A, then as MusicEntryGame; called through the stub
; at WaitSpaceRelease when SPACE is held on the title (the info screen).
;
; MusicEntryGame: HL = $C09D, DE = $F9D7; called through the stub at
; StartGame_Music when a game starts and by WaitSpaceRelease when SPACE is
; released. Probably starts the module at HL (the music is a Vortex Tracker II
; module).
;
; Hardware: 128K paging port, through CallInMusicBank.
MusicEntryEnding:
  LD DE,$FC4B             ; music bank routine at $FC4B
  JP CallInMusicBank
MusicEntryInfo:
  LD HL,$CA8A             ; module address for the info screen (assumed)
  JR MusicCallF9D7        ; skip the next LD HL
MusicEntryGame:
  LD HL,$C09D             ; module address of the game music (assumed)
MusicCallF9D7:
  LD DE,$F9D7             ; music bank routine at $F9D7
  JP CallInMusicBank
