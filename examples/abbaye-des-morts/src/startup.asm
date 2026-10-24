; Start-up: set up the machine, tables and interrupts, then start the game
;
; Run once, entered from the unpacker with SP=$5FFE: the word on the stack was
; left by the loader's machine check (H = machine type: 1 on a 48K Spectrum, on
; a 128K the value for port $7FFD that pages in the fastest bank, which holds
; the music; L = 1 when an AY chip answers, 0 when not). The routine sits in
; the room buffers at $6000-$6072 and is overwritten as soon as the first room
; is entered, so it cannot be called again.
;
; It saves the machine type in MachineType, hooks the 128K music
; (Patch128KHooks) when H is not 1, pages in bank 0 and sets the border to
; black, selects interrupt mode 2 with the vector table at Im2Table (every
; vector points to the interrupt handler InterruptHandler) and installs the
; do-nothing routine NoFrameRoutine as the routine the handler calls
; (InterruptRoutine). It then builds the row address table FlagRowTable (24
; words, $5E00+32*n, one per row of the tile flag map), the outline mask table
; at $FF00 and probes for a Kempston joystick. It ends by jumping into the game
; start at $8606, skipping the title screen script ScriptTitle that StartGame
; draws on a 48K machine (the first time, the loader's picture serves as the
; title).
;
; Outline mask table: byte n of the page OutlineMasks ($FF00) is NOT(n OR n<<1
; OR n>>1): a pixel row with every pixel next to a set pixel cleared. The
; sprite drawers use it to give sprites a one-pixel black outline instead of
; storing masks.
;
; Kempston probe: port $1F is read 65536 times and the readings are ORed
; together. A machine without the interface returns the floating bus, which
; sets some of bits 0-4 at some point; the routine then stores RET ($C9) at
; $A28F, the last instruction of the key scan ReadKeyControls, so the joystick
; read that follows it at $A290 is never reached. When bits 0-4 stay clear (a
; Kempston interface with nothing pressed) a NOP is stored instead and the key
; scan runs on into the joystick read.
;
; Hardware: writes the border and the speaker through port $FE, sets IM 2 and
; the I register, writes port $7FFD through PageInBank0 (128K paging; harmless
; on a 48K machine), reads the Kempston port $1F.
StartUp:
  DI
  POP HL                  ; machine type pushed by the loader
  LD SP,MainStack+$40     ; main stack is $60C0-$60FF
  LD A,H
  LD (MachineType),A      ; 1 on a 48K Spectrum
  DEC A
  CALL NZ,Patch128KHooks  ; 128K: hook the music (not on a 48K)
  CALL PageInBank0        ; page in bank 0 (RAM 0, ROM 1)
  XOR A                   ; black border, speaker off
  OUT (ULA_PORT),A
  LD A,Im2Table/$100      ; vector table page ($84): every entry points to the
                          ; interrupt handler
  LD I,A
  IM 2
  LD HL,NoFrameRoutine    ; the interrupt calls a RET until the game sets its
                          ; own routine
  LD (InterruptRoutine),HL
  LD HL,FlagRowTable      ; row address table
  LD DE,FLAG_MAP          ; flag map row 0
  LD B,ROW_TABLE_ENTRIES  ; one word per row
StartUp_RowTable:
  LD (HL),E               ; word = address of the flag map row
  INC L
  LD (HL),D
  INC L
  PUSH HL
  LD HL,SCREEN_COLS       ; next row is 32 bytes further
  ADD HL,DE
  EX DE,HL
  POP HL
  DJNZ StartUp_RowTable
  LD HL,OutlineMasks      ; outline mask table, one page
StartUp_Outline:
  LD B,L                  ; B = n >> 1
  LD A,L                  ; A = n << 1
  SRL B
  SLA A
  OR L
  OR B                    ; A = n OR n<<1 OR n>>1
  CPL                     ; NOT: the outline mask
  LD (HL),A
  INC L
  JR NZ,StartUp_Outline
  LD BC,PORT_KEMPSTON     ; read port $1F 65536 times
  LD H,B
  LD L,B
  LD E,B
StartUp_Kempston:
  IN A,(C)                ; accumulate every bit seen on the port
  OR E
  LD E,A
  DEC HL
  LD A,H
  OR L
  JR NZ,StartUp_Kempston
  LD A,E                  ; bits 0-4 of the port ever set (floating bus): no
                          ; interface
  AND C
  JR Z,StartUp_0
  LD A,OP_RET             ; RET
StartUp_0:
  LD (KempstonSwitch),A   ; 0 (NOP) when a Kempston interface answers, RET when
                          ; not
  JP StartGame_NoTitle    ; start the game, skipping the title script of a 48K

; Hook the game to the 128K music player (128K machines only)
;
; Called by StartUp when the machine is not a 48K. It turns three
; one-instruction stubs of the 48K code into CALLs (store $CD, the opcode of
; CALL, over the first byte): StartGame_Music (start of the game: the call
; enters the music bank through MusicEntryGame), $88D5 in RunEnding (end of the
; ending sequence, through MusicEntryEnding) and $A31E in the key-release wait
; (through MusicEntryInfo). Each stub is a 3-byte instruction whose operand
; already is the address of the 128K entry routine, and each of those pages in
; the music bank and calls the player there with CallInMusicBank.
;
; When L is nonzero (the loader found an AY chip) it also turns the first
; instruction of the beeper sound routine PlaySoundStep into JP PlayEffectOnAY
; ($C3 stored), which sends sound effects to the AY player instead of the
; beeper.
;
; L 1 if the loader found an AY chip, 0 if not (the beeper effects stay)
Patch128KHooks:
  LD A,OP_CALL            ; opcode of CALL
  LD (StartGame_Music),A  ; the instruction at $860C (LD HL,$85F3) becomes CALL
                          ; $85F3
  LD (RunEnding_Music),A  ; $88D5 (LD HL,$85E8) becomes CALL $85E8
  LD (WaitSpaceRelease),A ; $A31E (a RET followed by the operand bytes of CALL
                          ; $85EE) becomes CALL $85EE
  LD A,L
  OR A
  RET Z
  LD A,OP_JP              ; opcode of JP
  LD (PlaySoundStep),A    ; $871A (LD HL,$85D5) becomes JP $85D5
  RET

; Tile flag map, end of row 19 and rows 20-21 (image fill)
;
; The tile flag map is the 22 x 32 byte buffer at $5E00-$60BF: one byte per
; character cell of the room, 3 pages above the tile map at $5B00. This entry
; is its last 77 bytes; the rest of the map lies below the image, and the
; start-up code StartUp occupies rows 16-19 until the first room is entered.
; The $FF here is only the fill of the packed image: a room script rebuilds the
; whole map, because every tile opcode of the script interpreter RunScript
; writes the tile into the tile map and its flags (the byte at TileFlags+tile)
; into this map through PlaceTile.
;
; Cell byte: bits 0-2 the class of the tile (see TileFlags), bit 7 the "redraw
; this cell" mark, bit 6 the "a sprite was drawn here, erase it next frame"
; mark (see QueueSprite).
L6073:
  DEFS $4D,$FF

; Main stack (64 bytes, SP starts at $6100)
;
; The stack of the main program: the start-up code and the main loop StartGame
; run with SP=$6100 and the stack grows down to $60C0. The interrupt handler
; uses its own stack at InterruptStack. The image holds $FF here.
MainStack:
  DEFS $40,$FF

; Flag map row address table: 24 words, $5E00+32*n
;
; Built by StartUp (the image holds $FFFF). Word n is the address of row n of
; the tile flag map at $5E00 (32 bytes per row, so the words are $5E00, $5E20,
; $5E40, ...). The entity update routines find the flag-map cell under a sprite
; by loading H=$61, L=2*row (row = y/4 of the 2-pixel y coordinate) and reading
; the row address from here, then adding the column x/4: see UpdateChaser. Only
; the first 22 words (the room area) are used; the last two are spare.
;
; +0 word: address of row 0 ... +46 word: address of row 23
FlagRowTable:
  DEFW $FFFF,$FFFF,$FFFF,$FFFF
  DEFW $FFFF,$FFFF,$FFFF,$FFFF
  DEFW $FFFF,$FFFF,$FFFF,$FFFF
  DEFW $FFFF,$FFFF,$FFFF,$FFFF
  DEFW $FFFF,$FFFF,$FFFF,$FFFF
  DEFW $FFFF,$FFFF,$FFFF,$FFFF
