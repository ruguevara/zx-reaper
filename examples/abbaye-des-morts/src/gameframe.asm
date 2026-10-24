; Game frame: read the controls, update Jean, the objects and the room exits
;
; The per-frame game routine, run from the interrupt handler through the vector
; at $8504 (GameFrameRoutine plays the sound effects, then jumps here). Reads
; the keyboard (ScanKeyboard, ReadKeyControls, and the Kempston joystick
; through KempstonSwitch) into ControlsRead. If the room state (RoomState) has
; bit 7 clear (not playing) it stops there. Otherwise it works out the newly
; pressed bits (ControlsPressed), keeps the held bits (ControlsHeld) and, if R
; and Y are both held, sets the room state to 5 (Game Over). Then it restarts
; the frame call list at $BE5A, runs the player probes (ProbePlayer), every
; object slot (RunObjectSlots: items, enemies and other objects queue their
; sprites), the player state machine (UpdatePlayer), closes the call list
; (EndFrameList, unless the list is being drawn: QueueDrawCmd is a RET then),
; spawns the cutscene actors if $8552 is nonzero (SpawnQueuedObjects) and ends
; with the room-exit check CheckRoomExit.
;
; Hardware: reads the keyboard half-rows (port $FE) and, if on, the Kempston
; port $1F; nothing is drawn here, the sprites are queued for the drawing phase
; run by RunFrameList.
GameFrame:
  CALL ScanKeyboard       ; keyboard half-rows into KeyRows
  CALL ReadKeyControls    ; control bits (and the joystick)
  LD A,(RoomState)        ; room state: bit 7 set = playing
  RLA
  RET NC                  ; not playing: nothing more
  LD HL,ControlsRead      ; newly pressed = (previous XOR now) AND now
  LD A,(ControlsHeld)
  XOR (HL)
  AND (HL)
  LD (ControlsPressed),A
  LD A,(HL)
  LD (ControlsHeld),A     ; keep the bits now as the held bits
  AND CTRL_ABORT          ; R and Y together
  CP CTRL_ABORT
  JR NZ,GameFrame_List
  LD A,STATE_GAME_OVER    ; abort the game: Game Over screen
  LD (RoomState),A
GameFrame_List:
  LD HL,FrameList         ; frame call list starts at $BE5A
  LD (FrameListPtr),HL
  CALL ProbePlayer        ; player: tile flags around Jean, hit box
  CALL RunObjectSlots     ; run every object slot
  CALL UpdatePlayer       ; player state machine
  LD A,(QueueDrawCmd)     ; $AA1F is a RET while the list is being drawn
  OR A
  CALL Z,EndFrameList     ; otherwise close the list
  LD A,(SpawnQueueCount)  ; cutscene actors pending?
  OR A
  CALL NZ,SpawnQueuedObjects
  JP CheckRoomExit        ; room exits; returns to the interrupt handler

; End the frame call list
;
; Appends the address $BDEB to the list of drawing routines at ($BE58) and
; writes 0 (a NOP) over the RET at FrameListGate. $BDEB is the routine that
; ends the list (it restores SP); the NOP is the signal the main loop waits for
; (WaitFrameList) before it calls FrameListGate, which falls into RunFrameList
; and runs the list.
EndFrameList:
  LD HL,(FrameListPtr)
  LD DE,LeaveFrameList    ; the routine that ends the call list
  LD (HL),E
  INC HL
  LD (HL),D
  XOR A
  LD (FrameListGate),A    ; NOP: the list is ready
  RET

; Run the handler of every object slot
;
; The object slots are 11 records of 22 bytes at $C100, followed by an end mark
; at $C1F2 whose handler word is EndOfSlots. Each slot starts with a handler
; address (0 = free slot). The routine saves SP, then for each slot sets SP to
; the slot address and RETs, which pops the handler address and enters the
; handler with SP pointing into the slot: the handler POPs the slot's own
; fields and ends by jumping to RunObjectSlot with HL = the next slot. A free
; slot (handler 0) is skipped by adding 22 to SP. The end-mark handler
; EndOfSlots restores SP and returns to this routine's caller.
;
; Slot layout for the room items (made by MakeItemSlot from the room item
; records at RoomItems and the type records at ObjectTypeTable): +0 word:
; handler (RoomItemHandler), +2 byte: row (y/8), +3 byte: column (x/8), +4
; word: the item's action routine, +6 word: address of the item's flag byte, +8
; byte: frame countdown, +9 byte: countdown reload, +A byte: current frame, +B
; byte: number of frames, +C word: frame list (FramesHeart), +E byte: sprite
; width, +F byte: sprite height (2-pixel units); the rest is used by the
; enemies and other handlers.
;
; Hardware: none. The stack pointer is used as a data pointer; this is safe
; because the frame routine runs inside the interrupt handler with interrupts
; disabled.
RunObjectSlots:
  LD (EndOfSlots+$0001),SP ; operand of the LD SP at EndOfSlots
  LD HL,ObjectSlots       ; first slot
; Entry point used by every slot handler to go on with the next slot. HL =
; address of the slot to run.
RunObjectSlot:
  LD SP,HL                ; SP into the slot
  LD A,(HL)               ; handler address (low)
  INC L
  OR (HL)                 ; zero = free slot
  RET NZ                  ; RET pops the handler address and enters it
  LD HL,SLOT_SIZE         ; free slot: skip it
  ADD HL,SP
  JP RunObjectSlot

; End of the object slots
;
; The handler word of the end mark at $C1F2. Loads SP with the value saved by
; RunObjectSlots (the operand of this instruction is written by it) and returns
; to the caller of RunObjectSlots.
EndOfSlots:
  LD SP,EndOfSlots        ; operand = SP saved by RunObjectSlots
  RET

; Handler of the room items: position, overlap test, then the item's action
;
; The handler word (+0) of the slots made from room item records; entered by
; the RET of RunObjectSlot with SP at slot + 2. Pops the row and column (+2,
; +3) into the position of the object sprite command at ItemCmd (y, x/4),
; builds the 16x16-pixel box of the item in 2-pixel units (column * 4, row * 4,
; 8 wide and high) and jumps to the overlap test OverlapTest with IX =
; ItemActionEntry. The test compares it with Jean's box at PlayerBoxXMax and
; jumps to IX with carry set when they overlap. ItemActionEntry is a RET: it
; pops the item's action routine (slot +4), which gets the carry flag and SP at
; slot + 6.
;
; Used by all item types of ObjectTypeTable except type 5 (ParchmentHandler).
RoomItemHandler:
  POP HL                  ; L = row, H = column
  LD (ItemCmdPos),HL      ; sprite command position (y, x/4)
  ADD HL,HL               ; x2
  ADD HL,HL               ; x4: D = column * 4, E = row * 4
  EX DE,HL
  LD HL,ITEM_BOX*$0100+ITEM_BOX ; box size 8 x 8 (2-pixel units)
  ADD HL,DE
  LD B,H                  ; BC = far corner
  LD C,L
  LD IX,ItemActionEntry   ; continue at the RET: the action routine
  JP OverlapTest

; Continuation of an item handler: RET into the item's action
;
; RoomItemHandler and ParchmentHandler load IX with this address before the
; overlap test OverlapTest, which ends with JP (IX). The RET pops the next word
; of the slot (+4), the item's action routine, and enters it with the carry
; flag from the test (set when Jean overlaps the item) and SP at slot + 6.
ItemActionEntry:
  RET

; Item action: the church door that shuts behind Jean (room 7)
;
; The room item of room 7 (Abandoned church) at row 15, column 2 with flag
; $8543; it has no sprite. While the door is open ($851A = 0), Jean touching
; the item (observed with Jean placed on that spot; in play Jean enters the
; room from the left) sets its flag to 1 (checkpoint 1: SelectCheckpoint uses
; the first nonzero checkpoint flag among the nine at $8543), $851A to $FF, and
; arms the one-shot script runner RunEventScript with the subscript at $76A0,
; which draws the door (tiles at column 0, rows 14-17); the room script of room
; 7 draws it again whenever the room is entered with $851A nonzero. Once the
; door is shut the item makes it flicker: a countdown in slot +8 of 32-63
; frames (random, from the R register) ends with sound effect 8 and the
; alternative door tiles of the subscript at $76A8 for 3 frames (slot +9 counts
; them), then the normal $76A0 again.
;
; Hardware: reads the R register as a random number; sound request byte
; SoundRequest.
;
; F Carry set when Jean's box overlaps the item's box
; SP Slot address + 6 on entry (the RET of ItemActionEntry popped the action
;    word at +4): the next stack word is the flag pointer (the action pops it);
;    see RunObjectSlots for the slot layout
ActionChurchDoor:
  JR NC,ActionChurchDoor_NoTouch
  LD A,(ChurchDoorShut)   ; $851A: door shut ($FF) or not (0)
  INC A
  JR Z,ActionChurchDoor_Flicker ; shut: flicker
  POP HL                  ; flag pointer
  LD (HL),$01             ; checkpoint 1 reached
  SBC A,A                 ; carry is set: A = $FF
  LD (ChurchDoorShut),A   ; door shut
  LD HL,DoorLeftShut      ; subscript: the shut door
  LD (SmcEventScript+$0001),HL ; operand of the LD HL at SmcEventScript (script
                               ; address)
  LD HL,RunEventScript    ; the one-shot runner RunEventScript ...
  LD (HL),$00             ; ... is re-armed: NOP
; Go on with the next slot; SP is at slot + 8 here (the flag pointer is popped,
; the counters are pushed back).
NextSlotSP8:
  LD HL,SLOT_SIZE-$0008
  ADD HL,SP
  JP RunObjectSlot
ActionChurchDoor_NoTouch:
  LD A,(ChurchDoorShut)   ; not touching: only if the door is shut
  INC A
  JR NZ,NextSlotSP6       ; open and not touching: skip the slot
ActionChurchDoor_Flicker:
  POP HL                  ; flag pointer
  POP BC                  ; C = countdown, B = frames left of the flash
  DEC C
  JR NZ,ActionChurchDoor_Count ; countdown not over
  LD B,$04                ; flash starts: 3 frames to go
  LD HL,DoorLeftRattle    ; subscript: the other door tiles
  LD (SmcEventScript+$0001),HL
  LD HL,RunEventScript    ; re-arm the runner
  LD (HL),C
  LD A,R                  ; random countdown 32-63 frames
  AND $1F
  ADD A,$20
  LD C,A
  LD A,SFX_DOOR
  LD (SoundRequest),A
ActionChurchDoor_Count:
  DJNZ ActionChurchDoor_Store ; one frame of the flash less
  LD HL,DoorLeftShut      ; flash over: the normal door tiles
  LD (SmcEventScript+$0001),HL
  LD HL,RunEventScript
  LD (HL),B
ActionChurchDoor_Store:
  PUSH BC                 ; write the counters back
  JR NextSlotSP8

; Item action: the final parchment that starts the ending (room 24)
;
; The room item of room 24 (Satan !!!) at row 14, column 28 with flag $8534. It
; exists only after the chalice has been taken ($8521, set by ActionChalice, is
; nonzero): before that the slot is skipped and nothing is drawn. When Jean
; touches it the flag becomes $FF, the room state becomes 3 (the ending
; sequence, RunEnding) and the slot is freed with sound effect 5; otherwise it
; draws frame 0.
;
; F Carry set when Jean's box overlaps the item's box
; SP Slot address + 6 on entry (the RET of ItemActionEntry popped the action
;    word at +4): the next stack word is the flag pointer (the action pops it);
;    see RunObjectSlots for the slot layout
ActionFinalScroll:
  EX AF,AF'               ; keep the carry
  LD A,(ChaliceTaken)     ; $8521: the chalice has been taken
  OR A
  JR NZ,ActionFinalScroll_0 ; taken: go on
; Entry point used by ActionChurchDoor (door open, Jean not touching): go on
; with the next slot; SP is at slot + 6 (nothing has been popped).
NextSlotSP6:
  LD HL,SLOT_SIZE-$0006
  ADD HL,SP
  JP RunObjectSlot
ActionFinalScroll_0:
  POP HL                  ; flag pointer
  EX AF,AF'               ; carry again
  JR NC,ActionFinalScroll_1
  LD (HL),ITEM_GONE
  LD A,STATE_ENDING
  LD (RoomState),A
  JP FreeSlotWithSound    ; sound, free the slot
ActionFinalScroll_1:
  XOR A                   ; frame 0
  JP DrawItemFrame

; Item action: checkpoint (a gravestone cross)
;
; Room items of rooms 8, 11, 12, 14, 15, 19, 21 and 23 with flags $8544-$854B;
; with $8543 of ActionChurchDoor they are the nine checkpoint flags (0 = not
; active, nonzero = the active one). When Jean touches a checkpoint whose flag
; is 0 all nine flags are cleared, this one is set to 2 and sound effect 9
; plays; SelectCheckpoint then restarts Jean after a death at the checkpoint of
; the first nonzero flag (positions at Checkpoints). The frame drawn is (flag
; AND 2) / 2: 0 = not active, 1 = active.
;
; F Carry set when Jean's box overlaps the item's box
; SP Slot address + 6 on entry (the RET of ItemActionEntry popped the action
;    word at +4): the next stack word is the flag pointer (the action pops it);
;    see RunObjectSlots for the slot layout
ActionCheckpoint:
  POP HL                  ; flag pointer
  JR NC,DrawFlagFrame     ; not touching: just draw
  LD A,(HL)               ; flag
  OR A
  JR NZ,DrawFlagFrame     ; already active: just draw
  LD DE,CheckpointFlag0   ; the nine checkpoint flags
  LD B,CHECKPOINT_FLAGS
ActionCheckpoint_0:
  LD (DE),A               ; A = 0: clear all nine
  INC DE
  DJNZ ActionCheckpoint_0
  LD (HL),$02             ; this one is the active checkpoint
  LD A,SFX_CHECKPOINT
  LD (SoundRequest),A
  JR DrawFlagFrame

; Item action: the wheel of faith, turned by each touch (room 17)
;
; The room item of room 17 (The wheel of faith) at row 2, column 15 with flag
; $851E. While Jean touches it and bit 7 of the flag (a latch) is clear, the
; flag is XORed with $86: bit 7 is set (latch) and bits 1-2 toggle between 0
; (at rest) and 6 (turned); sound effect 5 plays. When Jean is not touching it
; the latch is cleared. The frame drawn is bit 1 of the flag. The crosses of
; ActionCrossWheelTurned and ActionCrossWheelRest depend on the state bits
; (flag AND 7).
;
; F Carry set when Jean's box overlaps the item's box
; SP Slot address + 6 on entry (the RET of ItemActionEntry popped the action
;    word at +4): the next stack word is the flag pointer (the action pops it);
;    see RunObjectSlots for the slot layout
ActionWheel:
  POP HL                  ; flag pointer
  JR NC,ActionWheel_Release ; not touching: release the latch
  BIT 7,(HL)              ; latch set: Jean has not left the wheel yet
  JR NZ,DrawFlagFrame
  LD A,(HL)
  XOR $86                 ; toggle the state bits and set the latch
  LD (HL),A
  LD A,SFX_PICKUP
  LD (SoundRequest),A
  JR DrawFlagFrame
ActionWheel_Release:
  RES 7,(HL)              ; clear the latch
; Entry point used by ActionCheckpoint: draw frame (flag AND 2) / 2 of the
; item; HL = flag pointer.
DrawFlagFrame:
  LD A,(HL)               ; bit 1: 0 or 1
  AND $02
  RRCA
  JP DrawItemFrame        ; draw the frame, next slot

; Item action: the arch of room 19 (Underground river), leading to Pestilent
; Beast
;
; The blue arch of room 19 at row 15, column 21 with flag $8524. When Jean
; touches it (and its latch, bit 7 of the flag, is clear) the latch of the
; other arch ($8523) is set, RespawnX/RespawnY are set to the position of the
; room 10 arch (X $5C, Y $44), and EnterRoomAtArch enters room 10. The latch of
; the arch Jean arrives at stays set until he has walked away from it
; (ArchRelease), so he is not sent back at once.
;
; F Carry set when Jean's box overlaps the item's box
; SP Slot address + 6 on entry (the RET of ItemActionEntry popped the action
;    word at +4): the next stack word is the flag pointer (the action pops it);
;    see RunObjectSlots for the slot layout
ActionArchToBeast:
  POP HL                  ; flag pointer
  JR NC,ArchRelease       ; not touching: release the latch
  BIT 7,(HL)              ; latched: Jean has just arrived here
  JR NZ,ArchIdle
  LD HL,DoorwayRoom10     ; latch of the arch in room 10
  SET 7,(HL)              ; it is where Jean arrives
  LD HL,$5C00             ; arrival position: X = $5C (column 23) ...
  LD (RespawnX),HL
  LD HL,$4400             ; ... Y = $44 (row 17), 2-pixel units
  LD (RespawnY),HL
  LD A,ROOM_BEAST
  JR EnterRoomAtArch

; Item action: the arch of room 10 (Pestilent Beast), leading to Underground
; river
;
; The blue arch of room 10 at row 17, column 23 with flag $8523; the mirror of
; ActionArchToBeast: sets the latch of the other arch ($8524), the arrival
; position to X $54, Y $3C (the arch in room 19) and enters room 19 through
; EnterRoomAtArch.
;
; F Carry set when Jean's box overlaps the item's box
; SP Slot address + 6 on entry (the RET of ItemActionEntry popped the action
;    word at +4): the next stack word is the flag pointer (the action pops it);
;    see RunObjectSlots for the slot layout
ActionArchToRiver:
  POP HL                  ; flag pointer
  JR NC,ArchRelease       ; not touching: release the latch
  BIT 7,(HL)              ; latched: Jean has just arrived here
  JR NZ,ArchIdle
  LD HL,DoorwayRoom19     ; latch of the arch in room 19
  SET 7,(HL)
  LD HL,$5400             ; arrival position: X = $54 (column 21) ...
  LD (RespawnX),HL
  LD HL,$3C00             ; ... Y = $3C (row 15), 2-pixel units
  LD (RespawnY),HL
  LD A,ROOM_RIVER

; Enter a room at an arch
;
; Entry point used by ActionArchToBeast. A = new room. The room state becomes
; 2, which makes the main loop (StartGame) put Jean at the position in
; RespawnX/RespawnY and enter the room, as after a death at a checkpoint.
;
; A New room
EnterRoomAtArch:
  LD (RoomNumber),A       ; new room number
  LD A,STATE_RESPAWN
  LD (RoomState),A
  ADD A,A                 ; player state 4: standing
  LD (PlayerState),A
  LD A,SFX_PORTAL
  LD (SoundRequest),A
  JP AnimateItem          ; draw the arch, next slot
; Entry point used by ActionArchToBeast: Jean is not touching the arch, clear
; its latch.
ArchRelease:
  RES 7,(HL)
; Entry point used by ActionArchToBeast: draw the arch and go on.
ArchIdle:
  JP AnimateItem

; Item action: heart (an extra life)
;
; Room items of type 0 (hearts). When Jean touches one its flag becomes $FF (it
; is not created again), the status-bar hearts redraw DrawLivesBar is armed (it
; is a RET until a 0 is written to it) and the lives at $854C go up by one, to
; a maximum of 9, then the item is freed with sound effect 5
; (FreeSlotWithSound). Without a touch the heart is animated and drawn by
; AnimateItem.
;
; F Carry set when Jean's box overlaps the item's box
; SP Slot address + 6 on entry (the RET of ItemActionEntry popped the action
;    word at +4): the next stack word is the flag pointer (the action pops it);
;    see RunObjectSlots for the slot layout
ActionHeart:
  POP HL                  ; flag pointer
  JP NC,AnimateItem       ; not touching: animate and draw
  LD (HL),ITEM_GONE
  LD HL,DrawLivesBar      ; hearts redraw: NOP
  LD (HL),$00
  LD HL,Lives             ; lives
  LD A,(HL)
  CP MAX_LIVES            ; carry set below the maximum
  ADC A,$00               ; +1 when below the maximum
  LD (HL),A

; Free the object slot with sound 5
;
; Entry point used by the other actions (taking a cross, the chalice, the final
; parchment): play sound effect 5, then free the slot; SP is at slot + 8.
;
; SP Slot address + 8
FreeSlotWithSound:
  LD A,SFX_PICKUP
  LD (SoundRequest),A

; Free the object slot
;
; Entry point used by ActionChalice and ActionParchment: free the object slot
; (zero its handler word) and go on with the next one; SP is at slot + 8.
;
; SP Slot address + 8
FreeSlot:
  LD HL,$FFFA             ; SP back to slot + 2
  ADD HL,SP
  LD SP,HL
  LD HL,$0000
  PUSH HL                 ; handler = 0: the slot is free
  LD HL,SLOT_SIZE
  ADD HL,SP
  JP RunObjectSlot

; Item action: the chalice that appears after twelve crosses (room 24)
;
; The room item of room 24 (Satan !!!) at row 2, column 16 with flag $8521. It
; is drawn (frame 0) only while twelve crosses have been collected ($854D >=
; 12); with fewer its slot is freed on its first frame without a touch. A
; touch in that first frame takes it whatever the cross count (observed with 0
; crosses and Jean placed on its spot at the room entry, F30; not possible in
; play, Jean reaches it from the ring of crosses, F125): the flag becomes $FF
; and the item is freed with sound effect 5. The flag is tested by UpdateSatan
; (Satan disappears in a cloud of smoke), ActionFinalScroll (the final
; parchment appears) and ShowCrossRing (the ring of crosses stops).
;
; F Carry set when Jean's box overlaps the item's box
; SP Slot address + 6 on entry (the RET of ItemActionEntry popped the action
;    word at +4): the next stack word is the flag pointer (the action pops it);
;    see RunObjectSlots for the slot layout
ActionChalice:
  POP HL                  ; flag pointer
  LD A,(HL)               ; flag
  JR NC,ActionChalice_0   ; not touching: show it if twelve crosses
  SBC A,A                 ; touching: A = $FF
  LD (HL),A
  JR FreeSlotWithSound    ; taken: sound, free the slot
ActionChalice_0:
  LD A,(Crosses)          ; crosses collected
  CP CROSSES_NEEDED
  JP C,FreeSlot           ; fewer than twelve: free the slot without a sound
                          ; (not drawn this frame)
  XOR A                   ; frame 0
  JP DrawItemFrame

; Item action: bell or lever that can be touched once
;
; Room items of room 2 (the bell of Tower of the Bell, flag $851B), room 9 (a
; lever, $851C) and room 10 (a lever, $851D). The first touch sets the flag to
; 1 and plays sound effect 3; the frame drawn is the flag (0 = rest, 1 = rung
; or pulled). The room scripts test the flags ($95/$9C opcodes at $7774, $7780,
; $7F78).
;
; F Carry set when Jean's box overlaps the item's box
; SP Slot address + 6 on entry (the RET of ItemActionEntry popped the action
;    word at +4): the next stack word is the flag pointer (the action pops it);
;    see RunObjectSlots for the slot layout
ActionBellOrLever:
  POP HL                  ; flag pointer
  LD A,(HL)               ; flag
  JR NC,DrawFlagValueFrame ; not touching: draw
  OR A                    ; already touched: draw
  JR NZ,DrawFlagValueFrame ; already touched: draw
  LD (HL),$01             ; touched
  LD A,SFX_TRIGGER
  LD (SoundRequest),A
  LD A,(HL)
; Entry point used by ActionGateLever: draw frame A of the item; HL is not
; needed.
DrawFlagValueFrame:
  JP DrawItemFrame

; Item action: lever that opens the gate of room 20
;
; The room item of room 20 (Unexpected gate) at row 6, column 24 with flag
; $851F. The first touch sets the flag to 1, plays sound effect 5 and arms the
; one-shot script runner RunEventScript with the subscript at $8048, which
; removes the gate tiles at the right edge of the room (column 31, rows 14-17);
; the room script tests the flag so the gate stays open. The frame drawn is the
; flag.
;
; F Carry set when Jean's box overlaps the item's box
; SP Slot address + 6 on entry (the RET of ItemActionEntry popped the action
;    word at +4): the next stack word is the flag pointer (the action pops it);
;    see RunObjectSlots for the slot layout
ActionGateLever:
  POP HL                  ; flag pointer
  LD A,(HL)               ; flag
  JR NC,DrawFlagValueFrame ; not touching: draw
  OR A                    ; already pulled: draw
  JR NZ,DrawFlagValueFrame ; already pulled: draw
  LD (HL),$01
  LD A,SFX_PICKUP
  LD (SoundRequest),A
  LD A,(HL)
  LD HL,EraseDoorRight    ; subscript: open the gate
  LD (SmcEventScript+$0001),HL ; operand of the LD HL at SmcEventScript (script
                               ; address)
  LD HL,RunEventScript    ; re-arm the one-shot runner RunEventScript
  LD (HL),$00
  JP DrawItemFrame

; Item action: cross that can be taken while the wheel is turned
;
; Room items of types 1 and 2 with this action are crosses;
; ActionCrossWheelRest is the other set. Which set can be taken depends on the
; wheel of faith at WheelState in room 17 (ActionWheel): with the wheel at rest
; the ActionCrossWheelRest crosses are the real ones (bright, cycling colours)
; and the ActionCrossWheelTurned crosses are drawn thin (frames 6-11); with the
; wheel turned it is the other way round. If Jean touches the cross while the
; wheel state bits (flag AND 7) are nonzero it is taken (TakeCross), otherwise
; it is drawn by DrawCrossWheelTurned.
;
; F Carry set when Jean's box overlaps the item's box
ActionCrossWheelTurned:
  JR NC,DrawCrossWheelTurned
  LD A,(WheelState)
  AND WHEEL_STATE_MASK    ; wheel state bits of WheelState
  JR Z,DrawCrossWheelTurned ; wheel at rest: not takeable
  JR TakeCross            ; take the cross

; Item action: cross that can be taken while the wheel is at rest
;
; The other set of crosses (see ActionCrossWheelTurned). If Jean touches the
; cross while the wheel state bits at WheelState are 0 it is taken (TakeCross);
; otherwise it is animated and drawn by the code at DrawCrossWheelRest, using
; frame offset 0 (bright cross) when the wheel is at rest and 6 (thin cross)
; when it is turned.
;
; F Carry set when Jean's box overlaps the item's box
ActionCrossWheelRest:
  JR NC,DrawCrossWheelRest
  LD A,(WheelState)
  AND WHEEL_STATE_MASK
  JR NZ,DrawCrossWheelRest ; wheel turned: not takeable

; Take a cross
;
; Entry point used by ActionCrossWheelTurned: Jean takes the cross. The flag
; becomes $FF (never created again), the status-bar crosses redraw
; DrawCrossesHud is armed (a RET until a 0 is written to it), the number of
; crosses at $854D goes up by one, then the slot is freed with sound effect 5.
TakeCross:
  POP HL                  ; flag pointer
  LD (HL),ITEM_GONE
  LD HL,DrawCrossesHud    ; crosses redraw: NOP
  LD (HL),$00
  LD HL,Crosses           ; crosses collected + 1
  INC (HL)
  JR FreeSlotWithSound    ; sound, free the slot

; Draw a cross of the wheel-at-rest set
;
; Not takeable (no touch, or the wheel is turned): step the frame animation
; (countdown in +8, reload in +9, frame in +A of the frame count in +B) as
; AnimateItem does, and draw frame E + (wheel state bits), that is the bright
; cross when the wheel is at rest and the thin one (frames 6-11) when it is
; turned.
DrawCrossWheelRest:
  POP HL                  ; flag pointer
  POP BC                  ; C = countdown, B = reload
  POP DE                  ; E = frame, D = number of frames
  LD A,E
  DEC C
  JR NZ,DrawCrossWheelRest_0 ; countdown not over
  LD C,B                  ; reload the countdown, next frame, wrap at D
  INC A
  LD E,A
  CP D
  JR C,DrawCrossWheelRest_0
  SUB D
  LD E,A
DrawCrossWheelRest_0:
  LD L,A                  ; frame without the wheel at restset
  LD A,(WheelState)
  AND WHEEL_STATE_MASK    ; + 0 (wheel at rest) or + 6 (turned)
  ADD A,L
  JR AnimateItem_Store    ; store the counters, draw frame A
                          ; (AnimateItem_Store)

; Draw the cross of the wheel-turned set
;
; Used by ActionCrossWheelTurned when the cross is not taken: steps the frame
; animation like DrawCrossWheelRest and draws frame E + ((wheel state bits) XOR
; 6), that is the thin cross (frames 6-11) when the wheel is at rest and the
; bright one when it is turned.
;
; F Carry set when Jean overlaps the item (not used here)
; SP Slot address + 6 on entry (flag pointer next)
DrawCrossWheelTurned:
  POP HL                  ; flag pointer
  POP BC                  ; C = countdown, B = reload
  POP DE                  ; E = frame, D = number of frames
  LD A,E
  DEC C
  JR NZ,DrawCrossWheelTurned_0 ; countdown not over
  LD C,B                  ; reload the countdown, next frame, wrap at D
  INC A
  LD E,A
  CP D
  JR C,DrawCrossWheelTurned_0
  SUB D
  LD E,A
DrawCrossWheelTurned_0:
  LD L,A                  ; frame without the wheel at restset
  LD A,(WheelState)
  AND WHEEL_STATE_MASK
  XOR WHEEL_TURNED        ; 0 (wheel turned) or 6 (wheel at rest)
  ADD A,L
  JR AnimateItem_Store    ; store the counters, draw frame A
                          ; (AnimateItem_Store)

; Item: step the frame animation, then queue the item's sprite
;
; The common tail of the item actions whose sprite is animated and depends on
; nothing else (ActionArchToRiver, ActionHeart). The wheel crosses
; (ActionCrossWheelRest, DrawCrossWheelTurned) do the same with a frame offset
; of their own and enter at AnimateItem_Store. Entered with SP at slot + 8: the
; caller has popped the flag pointer. Pops the animation words of the slot (+8:
; C = countdown, B = reload value; +$A: E = frame, D = number of frames); the
; countdown goes down by one and at zero it reloads from B, the frame goes up
; by one and wraps to 0 at D. AnimateItem_Store then stores the words back and
; DrawItemFrame queues the sprite of frame A.
;
; Hardware: none; the sprite is only queued (ItemCmd), the screen is written
; later.
;
; SP Slot address + 8 (the flag pointer is already popped)
AnimateItem:
  POP BC                  ; C = countdown, B = reload
  POP DE                  ; E = frame, D = number of frames
  LD A,E                  ; A = frame
  DEC C
  JR NZ,AnimateItem_Store ; countdown not over
  LD C,B                  ; reload; next frame, wrapping at D
  INC A
  LD E,A
  CP D
  JR C,AnimateItem_Store
  SUB D
  LD E,A
; Entry point of AnimateItem, ActionCrossWheelRest and DrawCrossWheelTurned: A
; = frame to draw, DE and BC = the animation words to put back into the slot
AnimateItem_Store:
  PUSH DE                 ; store the animation words back
  PUSH BC

; Queue an item's animation frame
;
; Entry point of the item actions that draw a frame they have already chosen
; (ActionFinalScroll, ActionWheel, ActionChalice, ActionBellOrLever,
; ActionGateLever, ActionParchment) and of AnimateItem_Store. A = frame number,
; SP at slot + 8. Skips the animation words (+8..+$B), pops the frame list
; pointer (+$C) and the size of the sprite (+$E: C = width in bytes, B = height
; in 2-pixel units), takes frame A of the list (4 bytes: sprite address,
; attribute, 0; FramesHeart) and puts address, size and attribute into the
; object draw command ItemCmd (its position was set by the slot handler,
; RoomItemHandler or ParchmentHandler). Unless the frame list is being run
; (QueueDrawCmd is a RET) the 10 bytes of the command are appended to the list
; at (FrameListPtr). Last it goes on with the next slot (the slot ends at SP +
; 6).
;
; A Frame number
; SP Slot address + 8
DrawItemFrame:
  POP HL                  ; skip the animation words
  POP HL
  POP DE                  ; DE = frame list
  LD H,$00                ; HL = 4 x A
  LD L,A
  ADD HL,HL
  ADD HL,HL
  ADD HL,DE               ; frame entry
  LD E,(HL)               ; DE = sprite address (D = pixel row page, E =
                          ; column)
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)               ; attribute
  INC HL
  POP BC                  ; C = width, B = height
  LD (ItemCmdGfx),DE
  LD (ItemCmdSize),BC
  LD (ItemCmdAttr),A
  LD HL,ItemCmd           ; the draw command
  LD A,(QueueDrawCmd)     ; $C9 (RET) while the frame list is being run
  OR A
  JR NZ,DrawItemFrame_Next
  LD DE,(FrameListPtr)    ; append the 10 bytes to the frame list
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LD (FrameListPtr),DE
DrawItemFrame_Next:
  LD HL,SLOT_SIZE-$10     ; SP is at slot + $10
  ADD HL,SP
  JP RunObjectSlot        ; next slot

; Handler of the parchment items
;
; The handler word (+0) of the slots made from room items of type 5, the
; parchments (ObjectTypeRecords, room item records of RoomItems). Like
; RoomItemHandler it pops the row and column (+2, +3) into the position of the
; object draw command ItemCmd, builds the 16x16-pixel box of the item in
; 2-pixel units and jumps to the overlap test OverlapTest, but with IX =
; ActionParchment instead of the RET at ItemActionEntry: the word at +4 of a
; parchment slot does not hold an action routine but the two message numbers,
; so the action is fixed.
;
; SP Slot address + 2 (the handler word was popped by the RET that entered the
;    routine)
ParchmentHandler:
  POP HL                  ; L = row, H = column
  LD (ItemCmdPos),HL      ; position of the draw command
  ADD HL,HL
  ADD HL,HL
  EX DE,HL
  LD HL,ITEM_BOX*$0100+ITEM_BOX ; box size 8 x 8 (2-pixel units)
  ADD HL,DE
  LD B,H
  LD C,L
  LD IX,ActionParchment   ; continue at the parchment action
  JP OverlapTest          ; overlap test

; Item action: parchment
;
; The action of the room items of type 5 (ParchmentHandler), entered by the
; overlap test with the carry flag set when Jean touches the parchment.
; Touched: the two message numbers at slot +4 (the string numbers of the first
; and second line of the text, RoomNames) go to ParchmentLine1, the item's flag
; becomes $FF (it is not created again), the parchment gate ParchmentGate is
; armed (a RET until a 0 is written to it; with the 0 the main loop shows the
; parchment), sound effect 5 is requested and the slot is freed (FreeSlot). Not
; touched: the flag pointer is dropped and frame 0 of the item is drawn
; (DrawItemFrame).
;
; F Carry set when Jean's box overlaps the item's box
; SP Slot address + 4 on entry: the next stack word is the pair of message
;    numbers (the action pops it)
ActionParchment:
  POP HL                  ; message numbers: line 1, line 2
  JR NC,ActionParchment_0 ; not touched
  LD (ParchmentLine1),HL
  POP HL                  ; flag pointer
  LD (HL),ITEM_GONE       ; never created again
  LD HL,ParchmentGate     ; the gate: NOP now, the main loop shows the
                          ; parchment
  LD (HL),$00
  LD A,SFX_PICKUP
  LD (SoundRequest),A
  JP FreeSlot             ; free the slot
ActionParchment_0:
  POP HL                  ; drop the flag pointer
  XOR A                   ; frame 0
  JP DrawItemFrame        ; draw it

; Hit test of an entity against the player, then continue where the caller says
;
; Used by the enemy handlers (Death, Satan, the crusaders and the other
; entities), which JP here with their slot on the stack: SP points at the
; slot's two hit box words (+$C offset, +$E far corner; both words have y in
; the low byte and x in the high byte, in 2-pixel units, see ObjectSlots). The
; minimum corner of the entity's box is its position plus the offset, the
; maximum corner its position plus the far corner word (measured from the
; position, not from the offset corner: it is a size only while the offset is
; 0). The two corners go to DE and BC and the code falls into the overlap test
; OverlapTest with IX = HitTestDone. HL is stored as the operand of the JP at
; SmcHitContinue, so that HitTestDone goes on at the caller's address with SP
; just after the two words.
;
; Hardware: none.
;
; DE Position of the entity: D = x, E = y (2-pixel units)
; HL Address to continue at after the test
; SP Slot address + $C (the hit box offset word)
HitTest:
  LD (SmcHitContinue+$0001),HL ; continuation address
  POP HL                  ; hit box offset (y, x)
  ADD HL,DE               ; minimum corner = position + offset
  EX DE,HL                ; DE = minimum corner
  POP BC                  ; hit box far corner (y, x)
  ADD HL,BC               ; maximum corner = position + far corner
  LD B,H                  ; BC = maximum corner
  LD C,L
  LD IX,HitTestDone       ; continue at HitTestDone after the test

; Test two boxes for overlap
;
; Entry point of RoomItemHandler, ParchmentHandler and UpdatePlant (which load
; IX themselves): the overlap test. Compares the box (D, E)..(B, C) with the
; player box PlayerBoxXMax (min x, max x, min y, max y of Jean) and jumps to IX
; with carry set when they overlap, clear when not.
;
; D Left of the box (min x)
; E Top of the box (min y)
; B Right of the box (max x)
; C Bottom of the box (max y)
; IX Where to go on (carry set: overlap)
OverlapTest:
  LD HL,(PlayerBoxXMax)   ; H = player min x, L = player max x
  LD A,B                  ; entity max x below the player min x: no
  CP H
  JR C,OverlapTest_0      ; no
  LD A,D                  ; entity min x not below the player max x: no
  CP L
  JR NC,OverlapTest_0     ; no
  LD HL,(PlayerBoxYMax)   ; H = player min y, L = player max y
  LD A,C                  ; entity max y below the player min y: no
  CP H
  JR C,OverlapTest_0      ; no
  LD A,E                  ; entity min y not below the player max y: no
  CP L
  JR NC,OverlapTest_0     ; no
  JP (IX)                 ; overlap: carry is set by the last CP
OverlapTest_0:
  OR A                    ; no overlap: carry clear
  JP (IX)

; Hit test continuation: flag a hit on the player
;
; Reached by the JP (IX) at the end of the overlap test OverlapTest, entered
; through HitTest. With the carry flag set (the entity's box overlaps the
; player's) it stores $FF in the player's hit flag PlayerHit, which makes the
; player routine (UpdatePlayerActive) kill the monk in this frame. Then it
; jumps to the continuation address that HitTest stored in the operand of the
; JP at SmcHitContinue.
;
; F Carry set when the entity overlaps the player
HitTestDone:
  JR NC,SmcHitContinue    ; no overlap
  SBC A,A                 ; A = $FF
  LD (PlayerHit),A
; Self-modified: the operand is the address HitTest was called with.
SmcHitContinue:
  JP SmcHitContinue       ; continue (operand written by HitTest)

; Step the frame animation of an entity, then continue at IX
;
; Used by the entities with an animation (SetDeathSprite, SetSatanSprite and
; others) after their hit test. Pops the animation words of the slot: C =
; countdown and B = reload value, E = frame number and D = number of frames.
; The countdown goes down by one; at zero it reloads from B, the frame number
; goes up by one and wraps to 0 at D. Both words are pushed back (SP is as
; before) and the routine jumps to IX, which the caller has loaded with its
; continuation.
;
; Hardware: none.
;
;   IX Address to continue at
;   SP Slot address of the animation words
; O:E Frame number after the step
StepAnimation:
  POP BC                  ; C = countdown, B = reload
  POP DE                  ; E = frame, D = number of frames
  DEC C
  JR NZ,StepAnimation_0   ; countdown not over
  LD C,B                  ; reload
  INC E                   ; next frame
  LD A,E
  CP D                    ; wrap at D
  JR C,StepAnimation_0
  SUB D
  LD E,A
StepAnimation_0:
  PUSH DE                 ; put the words back
  PUSH BC
  JP (IX)                 ; continue at IX
