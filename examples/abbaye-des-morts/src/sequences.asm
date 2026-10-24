; Intro: room 0 until a key is pressed
;
; Called by the start of the game (StartGame) after ENTER in the title menu.
; Room 0 is the intro: the text "13th Century. The Cathars were being expelled
; ... The Cathar Jean Raymond runs to escape the crusaders..." with Jean and
; three crusaders walking across the screen (the four objects of kind 0 in the
; room object table, run by the game frame in the interrupt, GameFrameRoutine).
; Jean's own state is set to 0 (none), so the player is not in play, and the
; key code KeyCode is cleared. The routine enters room 0 (EnterRoom), draws it
; (RedrawRoom), sets the room state to $80, and runs the foreground half of the
; game frame in a loop: wait for a completed frame list (WaitFrameList), run it
; (FrameListGate), build and copy the changed cells (BuildRedrawList,
; DrawRedrawList) and read the key code (GetKeyCode; the menu frame routine
; that does it in the menus is no longer installed). It returns when a key is
; down (KeyCode is not 0), when the room state is 5 (R and Y were pressed
; together: the frame routine sets it, and the caller ignores it, as
; SelectCheckpoint clears the state), or when any of the control bits 0-4 of
; ControlsRead is set (right, left, crouch, jump, or the Kempston joystick).
;
; Hardware: none directly; the screen is written by the routines called.
RunIntro:
  XOR A                   ; PlayerState 0: no player in the intro
  LD (PlayerState),A
  LD (RoomNumber),A       ; room 0
  LD (KeyCode),A          ; KeyCode: no key yet
  CALL EnterRoom          ; build room 0
  CALL RedrawRoom         ; draw it
  LD A,STATE_RUNNING
  LD (RoomState),A
RunIntro_Loop:
  CALL WaitFrameList      ; wait for a completed frame list
  CALL FrameListGate      ; = RunFrameList, run the frame list
  CALL BuildRedrawList    ; redraw runs and sprite jobs
  CALL DrawRedrawList     ; cells to the screen
  CALL GetKeyCode         ; KeyCode of the key held
  LD A,(KeyCode)
  OR A
  RET NZ                  ; a key: the intro ends
  LD A,(RoomState)
  CP STATE_GAME_OVER
  RET Z                   ; R and Y: Game Over requested
  LD A,(ControlsRead)     ; ControlsRead
  AND CTRL_MOVES
  JR Z,RunIntro_Loop      ; no control pressed: go on
  RET

; Wait until the interrupt has completed a frame list
;
; Spins until the byte at FrameListGate is 0 (a NOP). The game frame in the
; interrupt stores 0 there when it has queued the sprite commands of a frame
; (EndFrameList); the CALL FrameListGate that follows runs the list. Used by
; the intro (RunIntro) and the cutscene loop (RunCutscene); the main loop has
; its own copy of the wait with the one-shot gates inside it (MainLoop_Play).
;
; Hardware: waits for the frame interrupt without HALT.
;
; O:A 0
WaitFrameList:
  LD A,(FrameListGate)
  OR A
  JR NZ,WaitFrameList
  RET

; Load a cutscene actor list
;
; Copies a list of actors to the object list at $5DC0: the first byte of the
; list, the number of records, goes to SpawnQueueCount (the objects waiting to
; be spawned), the records (template address, y, x; 4 bytes each) to $5DC0. The
; next game frame (GameFrame) spawns them with SpawnQueuedObjects. Used by the
; ending (RunEnding) with the lists CutsceneList1 and CutsceneList2.
;
; HL Address of the list (count, then the records)
; BC Size of the list in bytes: 1 + 4 * the count
LoadCutsceneList:
  LD DE,SpawnQueueCount
  LDI
  LD DE,OBJECT_LIST
  LDIR
  RET

; Ending sequence
;
; Run by the main loop (StartGame) when the room state is 3 (touching the red
; scroll of room 24 sets it, ActionFinalScroll). In order:
;
; 1 Jean's state becomes 0 (none) and room 25 is entered (EnterRoom). The
; full-screen text window ShowTextWindow shows the script ScriptEnding1, "your
; doom will come / not by my hand / but by human hands", in black on bright
; red.
;
; 2 Music track 5 (128K), actor list CutsceneList1 (one actor, template
; ActorMonkTemplate) is loaded and the cutscene runs (RunCutscene): room 25,
; the pentagram room, with Jean on the right and the crusaders walking in
; (observed: it ends 365 frames after the window is closed by a key).
;
; 3 Room 4 is entered with the text window ScriptEnding2 ("Heresy!!! The Cathar
; is hidden on the throne of Satan, burn him", black on cyan). Jean's X and Y
; are set to $3E00 and $3A00 (the middle of the room), actor list CutsceneList2
; (8 actors) is loaded and the second cutscene runs (observed: 457 frames): a
; forest at night, Jean on a red pyre, the crusaders round it.
;
; 4 Music track 2, the script ScriptEnding3 ("Your body has burned in the
; flames, but your soul has found a place in Heaven."), the stub at
; RunEnding_Music (on a 128K it calls the music routine MusicEntryEnding), then
; wait for a key and its release.
;
; It returns to the main loop, which starts a new game at StartGame. The text
; windows save and restore the room state (ShowTextWindow), and the cutscene
; loop sets it to 0 when it ends.
;
; Hardware: none directly; the screen is written by the routines called, the
; keyboard is read through WaitKeyPress.
RunEnding:
  XOR A                   ; PlayerState 0
  LD (PlayerState),A
  LD A,ROOM_ENDING        ; room 25
  LD (RoomNumber),A
  CALL EnterRoom          ; build it
  LD HL,ScriptEnding1     ; ScriptEnding1
  LD BC,(BRIGHT+RED*PAPER)*$0100+BRIGHT+RED ; B: window interior bright red
                                            ; paper, black ink; C: frame tiles
  CALL ShowTextWindow     ; = ShowTextWindow, show the text window, wait for a
                          ; key
  LD A,MUSIC_TRACK_ENDING1 ; music track 5
  LD (MusicTrack),A
  LD HL,CutsceneList1     ; CutsceneList1
  LD BC,$0001+OBJECT_ENTRY_SIZE*$0001 ; 1 record
  CALL LoadCutsceneList   ; to the object list
  CALL RunCutscene        ; run the cutscene until an actor sets CutsceneDone
  LD A,ROOM_PYRE          ; room 4
  LD (RoomNumber),A
  CALL EnterRoom          ; build it
  LD HL,ScriptEnding2     ; ScriptEnding2
  LD BC,CYAN*PAPER*$0100+CYAN ; B: interior cyan paper, black ink; C: frame
                              ; tiles
  CALL ShowTextWindow
  LD HL,$3E00             ; Jean X = $3E (8.8)
  LD (PlayerX),HL
  LD HL,$3A00             ; Jean Y = $3A (8.8)
  LD (PlayerY),HL
  LD HL,CutsceneList2     ; CutsceneList2
  LD BC,$0001+OBJECT_ENTRY_SIZE*$0008 ; 8 records
  CALL LoadCutsceneList
  CALL RunCutscene        ; run the second cutscene
  LD A,MUSIC_TRACK_ENDING2 ; music track 2
  LD (MusicTrack),A
  LD HL,ScriptEnding3     ; ScriptEnding3
  CALL RunScript          ; = RunScript, run the final text script
RunEnding_Music:
  LD HL,MusicEntryEnding  ; 128K: becomes CALL $85E8 (Patch128KHooks,
                          ; MusicEntryEnding); on a 48K it only loads HL
  CALL WaitKeyPress       ; wait for a key
  JP WaitKeyRelease       ; ... and for its release; returns to the main loop

; Run a cutscene until an actor says it is over
;
; Clears the flag CutsceneDone, sets the room state to $80 (the frame routine
; runs the game logic, so the actors queued by LoadCutsceneList are spawned by
; SpawnQueuedObjects and move) and runs the foreground half of the game frame,
; as the intro does: wait for a completed frame list (WaitFrameList), run it
; (FrameListGate), build and copy the cells (BuildRedrawList, DrawRedrawList).
; It stops when an actor sets CutsceneDone (the end of its path script,
; UpdateCrusaderSignal, or its countdown, UpdatePyreMonk) and then sets the
; room state to 0. Jean is not in play (state 0) and the keys do nothing.
;
; Hardware: none directly.
RunCutscene:
  XOR A                   ; CutsceneDone = 0
  LD (CutsceneDone),A
  LD A,STATE_RUNNING
  LD (RoomState),A        ; RoomState
RunCutscene_Loop:
  CALL WaitFrameList      ; wait for a completed frame list
  CALL FrameListGate      ; = RunFrameList, run the frame list
  CALL BuildRedrawList
  CALL DrawRedrawList
  LD A,(CutsceneDone)     ; CutsceneDone
  OR A
  JR Z,RunCutscene_Loop
  XOR A                   ; room state 0
  LD (RoomState),A
  RET

; Spawn failure: no free object slot
;
; The exit of SpawnQueuedObjects when FindFreeSlot finds no free slot: drops
; the template address and position it had pushed, discards the rest of the
; queue (SpawnQueueCount = 0) and returns to the caller of SpawnQueuedObjects.
;
; O:A 0
SpawnQueued_NoSlot:
  POP AF                  ; drop the pushed position (BC)...
  POP AF                  ; ... and template (DE)
  XOR A                   ; SpawnQueueCount = 0: forget the other records
  LD (SpawnQueueCount),A
  RET

; Spawn the objects queued in the object list
;
; Called by the game frame (GameFrame) while SpawnQueueCount is not 0. The
; object list at $5DC0 holds that many 4-byte records: a template address
; (ScytheLeftTemplate and the like, 18 bytes: the layout is described at
; ObjectSlots) and the y and x of the new object. The routine sets the write
; pointer of the list ObjectListPtr back to $5DC0 and makes an object of each
; record: it finds a free slot (FindFreeSlot, which leaves its address in IX
; and DE'), copies the template bytes 0-5 to the slot's +0..+5 (handler, x
; speed, y speed), clears +6, puts the template byte 6 plus x in +7 (the high
; byte of the position X), clears +8, puts the template byte 7 plus y in +9
; (the high byte of Y) and copies the template bytes 8-17 to +$A..+$13 (hit
; box, sprite pointer, animation counters); then it decrements SpawnQueueCount.
; The same list is filled by the cutscene loader LoadCutsceneList and by the
; enemies that shoot (Death, Satan, the archers). When no slot is free the rest
; of the list is dropped (SpawnQueued_NoSlot).
;
; The routine keeps the record in the main register set and the slot address in
; the alternate one (EXX).
;
; Hardware: none.
SpawnQueuedObjects:
  LD HL,OBJECT_LIST       ; object list
  LD (ObjectListPtr),HL   ; ObjectListPtr: the list is consumed, appenders
                          ; start again at $5DC0
SpawnQueuedObjects_Next:
  LD E,(HL)               ; DE = template address
  INC HL
  LD D,(HL)
  INC HL
  LD C,(HL)               ; C = y
  INC HL
  LD B,(HL)               ; B = x
  INC HL
  PUSH BC                 ; save y, x
  PUSH DE                 ; save the template address
  EX DE,HL                ; HL = template, DE = list pointer
  CALL FindFreeSlot       ; free slot: IX and DE' = its address; carry set if
                          ; found
  JR NC,SpawnQueued_NoSlot ; none: give up
  EXX                     ; alternate set: DE' = slot
  POP HL                  ; HL = template
  LDI                     ; template bytes 0-5 to slot +0..+5
  LDI
  LDI
  LDI
  LDI
  LDI
  POP BC                  ; BC = y, x
  XOR A                   ; slot +6 = 0 (X fraction)
  LD (DE),A
  INC DE
  LD A,B                  ; x + template byte 6
  ADD A,(HL)
  INC HL
  LD (DE),A               ; slot +7: X high byte
  INC DE
  XOR A                   ; slot +8 = 0 (Y fraction)
  LD (DE),A
  INC DE
  LD A,C                  ; y + template byte 7
  ADD A,(HL)
  INC HL
  LD (DE),A               ; slot +9: Y high byte
  INC DE
  LDI                     ; template bytes 8-17 to slot +$A..+$13
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  EXX                     ; main set again
  LD HL,SpawnQueueCount   ; SpawnQueueCount
  DEC (HL)                ; one record done
  EX DE,HL                ; HL = list pointer again
  JR NZ,SpawnQueuedObjects_Next ; more records
  RET

; Spawn the room's items
;
; Walks the room item table RoomItems (8-byte records sorted by room, ended by
; room $1A) and calls SpawnItem for every record of the current room
; RoomNumber. The room and the end mark are loaded together: C = the room, B =
; $1A (RoomTableEnd). Called by EnterRoom after the room script, with every
; slot free.
;
; Hardware: none.
SpawnRoomItems:
  LD HL,RoomItems
  LD DE,ROOM_ITEM_SIZE
  LD BC,(RoomNumber)      ; C = room, B = $1A: the table ends with a record of
                          ; room $1A
SpawnRoomItems_Loop:
  LD A,(HL)               ; room of the record
  CP C
  CALL Z,SpawnItem        ; this room: spawn it (HL = record)
  ADD HL,DE               ; next record
  CP B                    ; A is still the room of the record just handled:
                          ; stop after the end mark
  JR NZ,SpawnRoomItems_Loop
  RET

; Spawn one item unless its flag is $FF
;
; The flag byte of an item (its address is the word at +1 of the record) is $FF
; once the item is taken or finished (ITEM_GONE: a heart, a cross, the church
; trigger...); such an item is not created again when the room is entered
; later. Otherwise MakeItemSlot makes its slot. All registers are preserved.
;
; HL Address of the room item record (RoomItems)
SpawnItem:
  PUSH AF
  PUSH HL
  PUSH DE
  PUSH BC
  INC HL                  ; BC = address of the flag byte
  LD C,(HL)
  INC HL
  LD B,(HL)
  LD A,(BC)               ; the flag
  CP ITEM_GONE
  CALL NZ,MakeItemSlot    ; not gone: make the slot, HL = record + 2
  POP BC
  POP DE
  POP HL
  POP AF
  RET

; Make the object slot of a room item
;
; Finds a free slot (FindFreeSlot) and fills it from the room item record
; (RoomItems) and the type record of its type (ObjectTypeRecords, found through
; the table ObjectTypeTable). Slot layout, as the handler RoomItemHandler and
; RunObjectSlots use it:
;
; +0 word: handler (type record +2); +2 byte: row (record +4); +3 byte: column
; (record +5); +4 word: action routine (record +6; for parchments the two text
; line numbers); +6 word: address of the item's flag byte (BC); +8 byte: frame
; countdown and +9 byte: its reload (type record +0); +$A byte: current frame,
; 0; +$B byte: number of frames (type +1); +$C word: frame list (type +4); +$E
; byte: sprite width and +$F byte: height (type +6, +7).
;
; The carry of FindFreeSlot is not tested: with no free slot the routine would
; write into the slot IX held before. It cannot happen with the shipped tables,
; which have at most 10 records in a room (room 15), for 11 slots, all free on
; room entry (checked from the tables).
;
;   HL Address of the record + 2 (the high byte of the flag pointer: SpawnItem
;      has read the pointer)
;   BC Address of the item's flag byte
; O:IX Address of the slot
MakeItemSlot:
  INC HL                  ; HL = record + 3: the type
  LD A,(HL)               ; type
  INC HL
  PUSH HL                 ; save the pointer to the record + 4
  ADD A,A                 ; two bytes per entry
  LD HL,ObjectTypeTable   ; ObjectTypeTable
  CALL AddAToHL           ; = AddAToHL, HL += A
  LD E,(HL)               ; DE = type record
  INC HL
  LD D,(HL)
  POP HL                  ; HL = record + 4
  CALL FindFreeSlot       ; IX = a free slot
  LD A,(HL)               ; row
  INC HL
  LD (IX+$02),A
  LD A,(HL)               ; column
  INC HL
  LD (IX+$03),A
  LD A,(HL)               ; action routine, low byte
  INC HL
  LD (IX+$04),A
  LD A,(HL)               ; ... high byte
  INC HL
  LD (IX+$05),A
  LD (IX+$06),C           ; flag address
  LD (IX+$07),B
  LD A,(DE)               ; frame countdown ...
  INC DE
  LD (IX+$08),A
  LD (IX+$09),A           ; ... and its reload
  XOR A                   ; frame 0
  LD (IX+$0A),A
  LD A,(DE)               ; number of frames
  INC DE
  LD (IX+$0B),A
  LD A,(DE)               ; handler (low byte)
  INC DE
  LD (IX+$00),A
  LD A,(DE)               ; handler (high byte)
  INC DE
  LD (IX+$01),A
  LD A,(DE)               ; frame list (low)
  INC DE
  LD (IX+$0C),A
  LD A,(DE)               ; frame list (high)
  INC DE
  LD (IX+$0D),A
  LD A,(DE)               ; width
  INC DE
  LD (IX+$0E),A
  LD A,(DE)               ; height
  LD (IX+$0F),A
  RET

; Spawn the room's objects
;
; Walks the room object table RoomObjects (11-byte records, ended by room $1A)
; and calls SpawnRoomObject for every record of the current room RoomNumber;
; the same room/end mark test as SpawnRoomItems. These are the enemies and
; moving scenery (kinds listed at RoomObjects). Called by EnterRoom after the
; items.
;
; Hardware: none.
SpawnRoomObjects:
  LD HL,RoomObjects
  LD DE,ROOM_OBJECT_SIZE
  LD BC,(RoomNumber)      ; C = room, B = $1A
SpawnRoomObjects_Loop:
  LD A,(HL)
  CP C
  CALL Z,SpawnRoomObject  ; this room: spawn it (HL = record)
  ADD HL,DE
  CP B
  JR NZ,SpawnRoomObjects_Loop ; until the end mark
  RET

; Spawn one room object from its record
;
; Finds a free slot (FindFreeSlot) and fills it from the 11-byte record of
; RoomObjects. Slot: +0 word handler, the entry of the record's kind (+1) in
; EntityHandlers; +2 word speed, the record byte +2 times 4; +4 and +5 the two
; limits of the patrol (record +7, +8); +6 and +8 the fractions of x and y, 0;
; +7 x (record +4); +9 y (record +5); +$A and +$B the timer and its reload
; (record +6); +$C word hit box offset and +$E word hit box far corner, the
; first four bytes of the behaviour block the record points to (+9); +$10 word
; the address after the fifth byte of that block (where the frame data starts);
; +$12 and +$13 the animation counter and its reload (record +3); +$14 frame
; number, 0; +$15 number of frames, the fifth byte of the block. The layout is
; described at ObjectSlots.
;
; As in MakeItemSlot, the carry of FindFreeSlot is not tested (no problem with
; the shipped tables). All registers but IX and IY are preserved.
;
;   HL Address of the room object record
; O:IX Address of the slot
SpawnRoomObject:
  PUSH AF
  PUSH HL
  PUSH DE
  PUSH BC
  CALL FindFreeSlot       ; IX = a free slot
  INC HL                  ; kind
  LD E,(HL)
  INC HL
  LD D,$00
  EX DE,HL                ; HL = kind, DE = record + 2
  ADD HL,HL               ; two bytes per handler
  PUSH DE                 ; keep the record pointer
  LD DE,EntityHandlers    ; EntityHandlers
  ADD HL,DE
  LD A,(HL)               ; handler address ...
  LD (IX+$00),A
  INC HL
  LD A,(HL)
  LD (IX+$01),A           ; ... to the slot
  POP DE                  ; DE = record + 2
  LD A,(DE)               ; speed byte ...
  INC DE
  LD L,A
  LD H,$00
  ADD HL,HL               ; ... times 4 ...
  ADD HL,HL
  LD (IX+$02),L           ; ... is the speed word (+2)
  LD (IX+$03),H
  LD A,(DE)               ; animation counter ...
  INC DE
  LD (IX+$12),A           ; ... and reload (+$12, +$13)
  LD (IX+$13),A
  XOR A                   ; x and y fractions and the frame number = 0
  LD (IX+$06),A
  LD (IX+$08),A
  LD (IX+$14),A
  LD A,(DE)               ; x
  INC DE
  LD (IX+$07),A
  LD A,(DE)               ; y
  INC DE
  LD (IX+$09),A
  LD A,(DE)               ; timer ...
  INC DE
  LD (IX+$0A),A
  LD (IX+$0B),A           ; ... and its reload
  LD A,(DE)               ; lower limit of the patrol (+4)
  INC DE
  LD (IX+$04),A
  LD A,(DE)               ; upper limit (+5)
  INC DE
  LD (IX+$05),A
  EX DE,HL                ; HL = record + 9: the pointer to the behaviour block
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL                ; HL = behaviour block
  LD A,(HL)               ; hit box offset (+$C, +$D) ...
  INC HL
  LD (IX+$0C),A
  LD A,(HL)
  INC HL
  LD (IX+$0D),A
  LD A,(HL)               ; ... hit box far corner (+$E, +$F)
  INC HL
  LD (IX+$0E),A
  LD A,(HL)
  INC HL
  LD (IX+$0F),A
  LD A,(HL)               ; number of frames (+$15)
  INC HL
  LD (IX+$15),A
  LD (IX+$10),L           ; pointer to the frame data (+$10, +$11)
  LD (IX+$11),H
  POP BC
  POP DE
  POP HL
  POP AF
  RET

; Find a free object slot
;
; Scans the 11 slots at $C100 (22 bytes each) for one whose handler word is 0.
; The routine pops its return address into IY and returns with JP (IY), and
; does its work in the alternate register set, so HL, DE and BC of the caller
; are preserved. Used by the three spawners MakeItemSlot, SpawnRoomObject and
; SpawnQueuedObjects (which takes the slot address from DE' after its own EXX).
;
; O:F Carry set when a free slot was found, clear when all are in use O:IX
; Address of the free slot (unchanged when none) O:DE' Address of the free slot
; (the alternate DE; SpawnQueuedObjects uses it) O:IY Changed (holds the return
; address)
FindFreeSlot:
  POP IY                  ; return address; the routine ends with JP (IY)
FindFreeSlot_IY:
  EXX                     ; alternate set
  LD HL,ObjectSlots       ; ObjectSlots
  LD BC,OBJECT_SLOTS*$0100+SLOT_SIZE-$0001 ; B = 11 slots, C = 21 (22 less the
                                           ; INC L)
FindFreeSlot_0:
  LD A,(HL)               ; handler word, low byte ...
  INC L
  OR (HL)                 ; ... OR high byte: 0 when free
  JR Z,FindFreeSlot_1
  LD A,L                  ; next slot
  ADD A,C
  LD L,A
  DJNZ FindFreeSlot_0
  EXX                     ; none: main set again, carry clear
  OR A
  JP (IY)
FindFreeSlot_1:
  DEC L                   ; found: HL = slot address
  EX DE,HL                ; DE = slot address
  LD IXL,E                ; IX = slot
  LD IXH,D
  EXX                     ; main set again
  SCF                     ; carry set
  JP (IY)
