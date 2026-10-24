; Cutscene actor lists of the ending: a count, then 4-byte records
;
; Two lists loaded by LoadCutsceneList for the ending sequence RunEnding: the
; first byte of a list is the number of records (copied to SpawnQueueCount) and
; the records are copied to the object list at $5DC0, from where
; SpawnQueuedObjects spawns them as objects. A record is 4 bytes: the address
; of an actor template in $BD80-$BDC8 (word), then the y and x of the actor in
; 2-pixel units, added to the offsets in the template.
;
; The first list (1 record: template $BD80 at y=$34, x=$6C) is loaded for the
; first part of the ending, in room 25; the second list (8 records: templates
; $BD92, $BDA4 three times, $BDC8 twice and $BDB6 twice) for the second part,
; in room 4. Each cutscene runs until one of the actors sets CutsceneDone.
CutsceneList1:
  DEFB $01
  DEFB low ActorMonkTemplate,high ActorMonkTemplate,$34,$6C
CutsceneList2:
  DEFB $08
  DEFB low ActorPyreMonkTemplate,high ActorPyreMonkTemplate,$3A,$3E
  DEFB low ActorFlameTemplate,high ActorFlameTemplate,$44,$36
  DEFB low ActorFlameTemplate,high ActorFlameTemplate,$44,$3E
  DEFB low ActorFlameTemplate,high ActorFlameTemplate,$44,$46
  DEFB low ActorCrusaderLTemplate,high ActorCrusaderLTemplate,$44,$14
  DEFB low ActorCrusaderLTemplate,high ActorCrusaderLTemplate,$44,$24
  DEFB low ActorCrusaderRTemplate,high ActorCrusaderRTemplate,$44,$54
  DEFB low ActorCrusaderRTemplate,high ActorCrusaderRTemplate,$44,$60

; Debug room warp (cheat): move between rooms with the direction keys
;
; The player routine UpdatePlayer jumps here while the player state PlayerState
; is $FF. Only the RAGE cheat reaches that state: CheckCheatKeys turns the JR
; at SmcWarpCheat into JR Z, and then the T key during play runs EnterRoomWarp,
; which sets $FF (observed with tests/inputs/cheat.txt, F23; without the cheat
; the JR always skips EnterRoomWarp). The routine reads the keys pressed this
; frame (ControlsPressed): when bit 5 is set it returns to normal play through
; DebugLeaveWarp; otherwise the low four bits (right, left, down, up) call
; DebugMoveRoom, which moves RoomNumber one room that way and starts the room
; change, and the room number is then reduced modulo 25.
DebugWarpRoom:
  LD A,(ControlsPressed)  ; keys newly pressed this frame
  BIT 5,A                 ; bit 5: back to normal play
  JP NZ,DebugLeaveWarp
  AND $0F                 ; direction bits: right, left, down, up
  RET Z
  CALL DebugMoveRoom      ; move one room that way
  LD HL,RoomNumber        ; wrap the room number modulo 25
DebugWarpRoom_Wrap:
  LD A,(HL)
  SUB GRID_ROOMS
  RET C
  LD (HL),A
  JR DebugWarpRoom_Wrap

; Music track of each room (rooms 0-25)
;
; One byte for each room number: the track the 128K player is asked to play
; (MusicTrack) when the room is entered; EnterRoom indexes the table with
; RoomNumber. Tracks 1-9 exist; the 48K version never reads them.
;
; Track by room: 0:1, 1:2, 2:4, 3:4, 4:7, 5:5, 6:5, 7:4, 8:4, 9:7, 10:8, 11:8,
; 12:4, 13:4, 14:8, 15:8, 16:8, 17:4, 18:9, 19:8, 20:8, 21:6, 22:6, 23:6, 24:9,
; 25:7.
RoomMusicTable:
  DEFB $01,$02,$04,$04,$07,$05,$05,$04,$04,$07,$08,$08,$04
  DEFB $04,$08,$08,$08,$04,$09,$08,$08,$06,$06,$06,$09,$07
