; Cutscene finished flag
;
; Zero while a cutscene runs, nonzero when it is over. RunCutscene clears it,
; runs the cutscene frame loop and polls it each frame; an actor sets it to 1
; when its path script ends (UpdateCrusaderSignal) or when its countdown
; reaches zero (UpdatePyreMonk).
CutsceneDone:
  DEFB $00

; Key found by the menu key scan: bit mask and keyboard row
;
; Written every frame by the menu interrupt routine MenuFrame from the result
; of FindPressedKey (the first key pressed in the key row buffer KeyRows). Read
; by RedefineOneKey when the player redefines a key: the two bytes (row, mask)
; are stored as the new entry of the key table ControlKeys. The mask is $01-$10
; for a key and the row is the index (0-7) of the half-row; both are 0 while no
; key is down.
;
; +0 byte PressedKeyMask: bit mask of the key within its half-row +1 byte
; PressedKeyRow: index of the keyboard half-row
PressedKeyMask:
  DEFB $00
PressedKeyRow:
  DEFB $00

; Address of the routine the interrupt handler calls each frame
;
; Word. The interrupt handler InterruptHandler calls the routine at this
; address on its own stack every 50 Hz frame: the RET at $8719 before the game
; starts (StartUp), the menu key scanner MenuFrame during the title and menu
; (StartGame), and GameFrameRoutine (beeper effects, then the frame update
; GameFrame) while the game runs. The image holds $8504, a value that is never
; used.
InterruptRoutine:
  DEFB $04,$85

; Machine type left by the loader
;
; 1 on a 48K Spectrum. On a 128K it is the value for port $7FFD that pages in
; the bank holding the music, which PageInMusicBank writes to the port each
; time the music player is called. Stored by StartUp from the word the loader
; leaves on the stack; StartGame compares it with 1 to draw the title screen
; script ScriptTitle on a 48K machine.
MachineType:
  DEFB $00

; Last value written to the 128K paging port $7FFD
;
; Set by PageInBank whenever it pages a bank in; PlayEffectOnAY saves it and
; restores it after calling the music player, so the game's own bank (bank 0,
; ROM 1: $10) is restored. Unused on a 48K machine apart from the one write
; made by StartUp.
PagingState:
  DEFB $00

; Unused byte
;
; No code reads or writes $8508, nor $8520 and $8550 further on (see BellRung
; and SoundRequest): they are padding of the variable block. ($8503 is
; PressedKeyRow, $8505 the high byte of InterruptRoutine.)
UnusedByte:
  DEFB $00

; Current room number (0-24)
;
; The room the player is in; the rooms form a 5x5 grid: left and right are -1
; and +1, up and down are -5 and +5, and a number of 25 or more wraps modulo 25
; (CheckRoomExit, after the player crosses a screen edge). Room 25 is only used
; by the ending sequence (RunEnding, which also uses room 4) and room 0 is the
; intro text screen (RunIntro). Read as the index of the room script table
; RoomScriptTable by EnterRoom, of the music table RoomMusicTable, and as the
; key when SpawnRoomItems and SpawnRoomObjects search the room item table
; RoomItems and the object table RoomObjects. Written by CheckRoomExit (edge
; crossing), RunIntro/RunEnding (title, ending), the passage items
; ActionArchToBeast/ActionArchToRiver (room 10 or 19), the checkpoint restore
; SelectCheckpoint and the debug room warp of the cheat DebugWarpRoom.
RoomNumber:
  DEFB $00

; Terminator of the room-keyed tables
;
; Constant $1A (26, one more than the last room 25). The tables of room items
; (RoomItems) and room objects (RoomObjects) are sorted by room number and end
; with this value; SpawnRoomItems and SpawnRoomObjects load BC from RoomNumber
; (C = the room, B = this byte) and stop their scan when a record's first byte
; equals B. Never written.
RoomTableEnd:
  DEFB $1A

; Direction of the last room change (0 right, 1 left, 2 down, 3 up)
;
; Set by CheckRoomExit when the player crosses a screen edge: 0 = left the room
; through the right edge, 1 = left edge, 2 = bottom edge, 3 = top edge.
; RedrawRoom (called when a room is entered) indexes the four scroll set-ups at
; SweepSetups with it to choose from which side the new room is drawn in.
; Cleared by StartGame at the start of a game and by ShowParchment after a
; parchment has been read (so that the room is redrawn from the right).
ExitDirection:
  DEFB $00

; Room state: what the main loop does next
;
; The main loop StartGame takes the low 7 bits: 1 = enter the room RoomNumber
; (EnterRoom); 2 = put the player at the respawn position ($8512/$8514), then
; enter the room (set by the passage items
; ActionArchToBeast/ActionArchToRiver); 3 = ending sequence RunEnding (set by
; the red scroll in Satan's room, ActionFinalScroll); 4 = restore the last
; checkpoint (SelectCheckpoint), then as 2 (set to $84 by the end of the dying
; animation UpdateDying_End when lives are left); 5 = Game Over screen
; (UpdateDying_End makes it $85 when no life is left; both abort keys,
; GameFrame); 0 or anything above 5: run the frame routines. Bit 7 keeps the
; frame routines (player, entities, drawing) running: the loop sets the state
; to $80 after a room has been entered. ShowParchment and the cutscene loop
; clear and restore it so that the frame update stops while a parchment is
; shown. The room-entry code EnterRoom clears it.
RoomState:
  DEFB $00

; String number of the room name
;
; Number of the text string (RoomNames, 0-52) that the status bar panel
; ScriptRoomPanel prints as the name of the room. Set by script op $87 at the
; start of each room script (OpSetRoomName); rooms 0 and 4 have no op $87, so
; they keep the previous name.
RoomNameString:
  DEFB $00

; Parchment text: string numbers of the two lines
;
; Set when a parchment is picked up (ActionParchment copies the two bytes after
; the item's coordinates), printed by the parchment script ScriptParchment
; through two PRINTVAR ops (script op $84). The image holds 25 and 26, the
; first parchment ("Twelve crosses / against the devil").
;
; +0 byte ParchmentLine1: string number of the first line +1 byte
; ParchmentLine2: string number of the second line
ParchmentLine1:
  DEFB $19
ParchmentLine2:
  DEFB $1A

; Timer of the bubbling blood tiles
;
; Counts down from 2 once per frame in AnimateBloodTiles; when it reaches zero
; it is reloaded with 2 and the cells of the bottom tile row (row 21 of the
; tile map) that hold tile $3B or $3C are swapped ($3B to $3C and back) and
; marked for redraw: the blood at the foot of the room bubbles every other
; frame. AnimateBloodTiles is a NOP only in the rooms whose script contains op
; $9E (rooms 21, 22 and 23); everywhere else it starts with a RET.
BloodAnimTimer:
  DEFB $02

; Timer of the colour cycle of the twelve crosses
;
; Counts down from 5 in ShowCrossRing (active once all 12 crosses are
; collected, in rooms 24 and 25); at zero it is reloaded with 5, the cycle
; position (the operand of the LD A,0 at SmcCrossColour) advances through 0-5
; and the attribute of the cross tile $4C (CE4C) is set from CrossColours.
CrossFlashTimer:
  DEFB $05

; Respawn position of the player (X and Y, 8.8 fixed point)
;
; The place where the player appears when a room is entered in state 2 or 4
; (RoomState): StartGame copies the two words to the player's X and Y (PlayerX,
; PlayerY). The high bytes are in 2-pixel units (X 0-$7F, Y 0-$57), the low
; bytes are 0. SelectCheckpoint sets the high bytes from the active checkpoint
; record (Checkpoints: column*4, row*4); the passage items ActionArchToBeast
; and ActionArchToRiver set both words to the exit of the doorway they lead to,
; where state 2 puts the player in the other room. A death goes through state 4
; and SelectCheckpoint, which overwrites them with the checkpoint (observed: a
; death after an arch restarted in room 5, the last checkpoint record). The
; block $8512-$854D is zeroed by StartGame at the start of a game.
;
; +0 word RespawnX (low byte, then RespawnXHi) +2 word RespawnY (low byte, then
; RespawnYHi)
RespawnX:
  DEFB $00
RespawnXHi:
  DEFB $00
RespawnY:
  DEFB $00
RespawnYHi:
  DEFB $00

; Hit box of the player (2-pixel units)
;
; The rectangle in which the player can be hit, rebuilt every frame by
; ProbePlayer from the player's position and state (smaller while crouching:
; X+1..X+8 and Y+7..Y+13; otherwise X+2..X+6 and Y+2..Y+12, with X, Y the high
; bytes of PlayerX/PlayerY). HitTest/OverlapTest compare the box of each entity
; with it as words: the first word is (min X, max X), the second (min Y, max Y)
; with the maximum in the low byte; an entity hits when its X range reaches min
; X and starts below max X, and likewise for Y.
;
; +0 byte PlayerBoxXMax: right edge +1 byte PlayerBoxXMin: left edge +2 byte
; PlayerBoxYMax: bottom edge +3 byte PlayerBoxYMin: top edge
PlayerBoxXMax:
  DEFB $00
PlayerBoxXMin:
  DEFB $00
PlayerBoxYMax:
  DEFB $00
PlayerBoxYMin:
  DEFB $00

; Church door flag: the way back to room 6 is shut
;
; Zero at the start of a game, $FF once the player has walked into the
; Abandoned church (room 7) through its left door: the trigger item of that
; room (ActionChurchDoor, item type 7, which also makes checkpoint 0 active)
; sets it, closes the door with the script DoorLeftShut and plays the door
; sound. While it is nonzero, the script of room 6 draws the door (DoorRight)
; at its right edge and the script of room 7 draws the door (DoorLeftShut) at
; its left edge, so the player cannot go back (op $9C, OpRunIfNonZero).
ChurchDoorShut:
  DEFB $00

; State flags of the bell, three levers and the wheel of faith ($851B-$8520)
;
; One byte for each of the interactive items (type 4, 9 and 10 of the item
; types, see RoomItems). They are read by the item routines, which choose the
; sprite frame from them, and by the room scripts (ops $95 and $9C test a byte
; through its address, OpRunIfZero and OpRunIfNonZero), which open or close
; doors and remove blocks.
;
; +0 BellRung ($851B): 0, or 1 once the bell of the Tower of the Bell (room 2)
; has been touched (ActionBellOrLever, sound 3). The script of room 8 (The
; Altar) erases a 2x2 block of wall at row 20, column 26 when it is set. +1
; LeverRoom9 ($851C): 0 or 1, the lever of room 9 (Hangman tree). While it is 0
; the script of room 19 (Underground river) draws a door at its left edge
; (DoorLeftLow). +2 LeverRoom10 ($851D): 0 or 1, the lever of room 10
; (Pestilent Beast). While it is 0 the script of room 8 draws a door at its
; right edge (DoorRight). +3 WheelState ($851E): the wheel of faith in room 17:
; 0 at rest, $06 once turned; each touch toggles bits 1-2 (XOR $86) and bit 7
; is set while the player still touches it (ActionWheel). It decides which
; crosses can be picked up: the crosses of type 1 only while it is 0, those of
; type 2 only while it is not (ActionCrossWheelRest, ActionCrossWheelTurned),
; and which of the two cross shapes is drawn. +4 LeverRoom20 ($851F): 0 or 1,
; the lever of room 20 (Unexpected gate). While it is 0 the script of room 20
; draws a door at its right edge (DoorRight). +5 $8520: unused
BellRung:
  DEFB $00
LeverRoom9:
  DEFB $00
LeverRoom10:
  DEFB $00
WheelState:
  DEFB $00
LeverRoom20:
  DEFB $00
  DEFB $00

; Chalice flag: the chalice of Satan's room has been taken
;
; 0, or $FF once the player has touched the chalice in room 24 (item type 11,
; ActionChalice; the chalice is drawn only once 12 crosses are collected, see
; Crosses; with fewer the item frees its slot on its first frame, so only a
; touch on the room's first frame takes it, F30, which cannot happen in play:
; the chalice is reached from the ring of crosses, F125). The enemy code of
; Satan UpdateSatan tests it: while it is 0 Satan moves and attacks, once it is
; set he turns into a cloud of smoke (once, see SatanSmoked). The crosses
; routine ShowCrossRing stops adding crosses and the red scroll (item type 6,
; ActionFinalScroll) appears: touching it starts the ending. Never cleared
; except by a new game.
ChaliceTaken:
  DEFB $00

; Satan has been turned into smoke
;
; 0, or $FF once UpdateSatan has seen the chalice taken (ChaliceTaken) and has
; replaced Satan by the smoke object: it then switches the music to track 7
; (MusicTrack), runs the script ScriptEraseCrosses to erase the twelve crosses
; and clears CrossRingDone. Other entity routines (for instance UpdateFireball)
; test it and remove themselves while it is set, so that Satan's fire
; disappears.
SatanSmoked:
  DEFB $00

; Doorway locks: arrived through the passage between rooms 10 and 19
;
; Flags of the two arched doorways (items of type 8) that join room 10
; (Pestilent Beast) and room 19 (Underground river). Touching the doorway of
; room 10 (ActionArchToRiver) sends the player to room 19 and sets bit 7 of the
; other doorway's flag, and the doorway of room 19 (ActionArchToBeast) does the
; reverse; a doorway whose bit 7 is set ignores the player until he has walked
; off it (the routine clears the bit when there is no contact), so the arrival
; does not send him straight back.
;
; +0 DoorwayRoom10 ($8523): flag of the doorway in room 10 +1 DoorwayRoom19
; ($8524): flag of the doorway in room 19
DoorwayRoom10:
  DEFB $00
DoorwayRoom19:
  DEFB $00

; Collected flags of the hearts, parchments, the red scroll and the crosses
; ($8525-$8540)
;
; One byte for each pick-up item of the room item table RoomItems (the pointer
; in the item's record is the address of its flag). 0 means the item is still
; there, $FF (ITEM_GONE) that it has been taken: the item spawner
; SpawnRoomItems (via SpawnItem) does not create an item whose flag is $FF, so
; a taken item stays gone. The flags are zeroed by StartGame at the start of a
; game; the flag of an item taken in a room survives leaving and re-entering
; the room. Each flag is named after its item and the room it is in; the
; comment gives the item's row and column in the room.
;
; +$00-$08: hearts (item type 0, ActionHeart): one more life, up to 9 (the
;           status bar shows them, Lives).
; +$09-$0E: parchments (type 5, ActionParchment): taking one shows the
;           parchment text (ParchmentLine1).
;     +$0F: the red scroll of Satan's room (type 6, ActionFinalScroll), only
;           present after the chalice.
; +$10-$1B: the twelve crosses (types 1 and 2,
;           ActionCrossWheelRest/ActionCrossWheelTurned, counted in Crosses).
;           The eight crosses of type 1
;          CrossRoomN can be taken while the wheel of faith WheelState is at
;                     rest, the four of type 2 (WheelCrossRoomN) only
;          after it has been turned.
HeartRoom2:
  DEFB $00                ; room 2, row 7, column 12, item type 0
HeartRoom10:
  DEFB $00                ; room 10, row 18, column 10, item type 0
HeartRoom11:
  DEFB $00                ; room 11, row 4, column 2, item type 0
HeartRoom12:
  DEFB $00                ; room 12, row 6, column 16, item type 0
HeartRoom15:
  DEFB $00                ; room 15, row 14, column 3, item type 0
HeartRoom17:
  DEFB $00                ; room 17, row 18, column 3, item type 0
HeartRoom18:
  DEFB $00                ; room 18, row 11, column 15, item type 0
HeartRoom19:
  DEFB $00                ; room 19, row 8, column 25, item type 0
HeartRoom23:
  DEFB $00                ; room 23, row 7, column 23, item type 0
ParchmentRoom3:
  DEFB $00                ; room 3, row 16, column 18, item type 5
ParchmentRoom8:
  DEFB $00                ; room 8, row 18, column 27, item type 5
ParchmentRoom12:
  DEFB $00                ; room 12, row 18, column 10, item type 5
ParchmentRoom14:
  DEFB $00                ; room 14, row 10, column 19, item type 5
ParchmentRoom16:
  DEFB $00                ; room 16, row 5, column 22, item type 5
ParchmentRoom21:
  DEFB $00                ; room 21, row 6, column 3, item type 5
RedScrollTaken:
  DEFB $00                ; room 24, row 14, column 28, item type 6
CrossRoom3:
  DEFB $00                ; room 3, row 18, column 28, item type 1
WheelCrossRoom9:
  DEFB $00                ; room 9, row 4, column 6, item type 2
CrossRoom10:
  DEFB $00                ; room 10, row 4, column 26, item type 1
CrossRoom13:
  DEFB $00                ; room 13, row 18, column 18, item type 1
CrossRoom14:
  DEFB $00                ; room 14, row 4, column 9, item type 1
WheelCrossRoom15:
  DEFB $00                ; room 15, row 8, column 28, item type 2
CrossRoom16:
  DEFB $00                ; room 16, row 6, column 2, item type 1
CrossRoom17:
  DEFB $00                ; room 17, row 18, column 28, item type 1
WheelCrossRoom17:
  DEFB $00                ; room 17, row 10, column 3, item type 2
CrossRoom18:
  DEFB $00                ; room 18, row 5, column 3, item type 1
CrossRoom19:
  DEFB $00                ; room 19, row 2, column 3, item type 1
WheelCrossRoom22:
  DEFB $00                ; room 22, row 18, column 27, item type 2

; The ring of twelve crosses: how many are shown, and a completion flag
;
; State of the crosses routine ShowCrossRing, which runs in rooms 24 and 25
; (script op $9F) once all 12 crosses are collected (Crosses). Every 5 frames
; it increments the count (while the chalice is not taken, ChaliceTaken) and
; re-stamps that many crosses (tile $4C) at the positions listed from
; CrossRingPositions, so that the ring of twelve crosses appears one cross at a
; time with sound 5. The values survive leaving the room, so on a later visit
; the whole ring is drawn at once. Zeroed at the start of a game.
;
; +0 CrossRingCount: crosses of the ring drawn so far, 0-12 +1 CrossRingDone:
; set to 12 when the twelfth cross appears and cleared by UpdateSatan when
; Satan is turned into smoke; no code reads it
CrossRingCount:
  DEFB $00
CrossRingDone:
  DEFB $00

; Checkpoint flags: which checkpoint is the active respawn point
;
; Nine bytes, one for each checkpoint that can be reached (checkpoint 0 is the
; trigger in the Abandoned church, room 7; checkpoints 1-8 are the ringed
; crosses of type 3 in rooms 8, 11, 12, 14, 15, 19, 21 and 23). At most one is
; nonzero: touching a checkpoint (ActionCheckpoint) first clears all nine, then
; sets its own byte to 2 (and plays sound 9); the church trigger
; (ActionChurchDoor) sets byte 0 to 1. The sprite frame of a checkpoint is bit
; 1 of its byte (ringed cross lit up once active). SelectCheckpoint scans the
; bytes for the first nonzero one: its index selects the respawn record in the
; table Checkpoints (room, row, column); if all nine are zero the tenth record
; is used, the start of the game in room 5. Zeroed at the start of a game.
CheckpointFlag0:
  DEFB $00                ; room 7 (church trigger)
CheckpointFlag1:
  DEFB $00                ; room 8
CheckpointFlag2:
  DEFB $00                ; room 11
CheckpointFlag3:
  DEFB $00                ; room 12
CheckpointFlag4:
  DEFB $00                ; room 14
CheckpointFlag5:
  DEFB $00                ; room 15
CheckpointFlag6:
  DEFB $00                ; room 19
CheckpointFlag7:
  DEFB $00                ; room 21
CheckpointFlag8:
  DEFB $00                ; room 23

; Lives left
;
; Number of lives, 9 at the start of a game (the image holds 9). Decremented by
; the death routine KillPlayer; raised by one, up to 9 (MAX_LIVES), by a heart
; (ActionHeart). The status bar draws that many hearts (DrawLivesBar). When it
; is 0 at the end of the death animation the room state becomes 5, Game Over
; (RoomState). The dying monk still touches items, so a heart taken during the
; death animation gives the life back, the last one too (observed, F121).
Lives:
  DEFB $09

; Crosses collected (0-12)
;
; Incremented by ActionCrossWheelRest and ActionCrossWheelTurned when a cross
; is picked up. The status bar draws that many crosses (DrawCrossesHud). With
; 12 (CROSSES_NEEDED) the chalice appears in room 24 (ActionChalice) and the
; ring of crosses is shown (ShowCrossRing). Zeroed at the start of a game.
Crosses:
  DEFB $00

; Beeper effect being played (0 = none)
;
; Number of the sound effect that PlaySoundStep is playing (set from
; SoundRequest when it starts one, cleared when the effect ends). A new request
; in SoundRequest replaces the effect being played at once (observed, F104).
SoundPlaying:
  DEFB $00

; Sound effect requested
;
; Written by the game code to start a sound effect, cleared by PlaySoundStep
; (the routine called each frame through the interrupt) when it picks the
; request up. 1 is a noise built in the routine (never requested, F106), 2-9
; are the 8-byte descriptions at SoundEffects (effect n at $87F2+8*(n-2)).
; Known requests: 2 jump (UpdatePlayerActive), 3 bell or lever touched
; (ActionBellOrLever), 4 passage between rooms 10 and 19 (ActionArchToRiver), 5
; item taken, wheel turned, chalice, key accepted in the controls menu
; (ActionHeart, ActionWheel, RedefineOneKey), 6 the player dies (KillPlayer), 7
; an enemy shoots or throws (SFX_ENEMY_SHOT: ThrowDeathScythe, UpdateSatan,
; UpdateShooter_Tail, UpdatePlant_Spit, UpdateFishWaiting_Jump,
; UpdateBeastFire_Draw), 8 the church door (ActionChurchDoor), 9 checkpoint
; touched (ActionCheckpoint). On a 128K machine the AY player handles the
; request instead (PlayEffectOnAY).
SoundRequest:
  DEFB $00

; Unused byte
;
; No code reads or writes $8550.
UnusedByte2:
  DEFB $00

; Music track number
;
; The track the 128K music player should play: set to 3 by StartGame at the
; start of a game (the title), to the track of the room from RoomMusicTable
; each time a room is entered (EnterRoom), to 7 when Satan is turned into smoke
; (UpdateSatan), to 5 and 2 during the two parts of the ending (RunEnding) and
; to 7 on the Game Over screen. The player lives in the 128K bank (see
; CallInMusicBank) and reads this byte there; on a 48K machine nothing reads
; it.
MusicTrack:
  DEFB $00

; Objects waiting to be spawned
;
; Count of the 4-byte records (template address, y, x) queued in the object
; list that starts at $5DC0 (pointer ObjectListPtr) and have not yet been
; turned into live objects. LoadCutsceneList sets it from the actor lists of
; the cutscenes and the enemies and entities that shoot or split add one with
; the record they append (UpdateShooter_Tail, UpdateSatan, ...); the frame
; update GameFrame calls SpawnQueuedObjects while it is nonzero, and that
; routine spawns the records into free object slots at $C100 and decrements it
; (it is cleared at once when no slot is free).
SpawnQueueCount:
  DEFB $00

; Colour cycle of the ring of crosses: 6 attribute bytes
;
; Attributes (bright yellow, red, magenta, blue, cyan, green) that
; ShowCrossRing copies one by one to the attribute of the cross tile $4C
; (CE4C), advancing every 5 frames (CrossFlashTimer), so that the twelve
; crosses flash through the rainbow.
CrossColours:
  DEFB $46,$42,$43,$41,$45,$44

; Tile flags around the entity being updated by UpdateChaser
;
; Four scratch bytes written each time UpdateChaser samples the tile flag map
; around an entity (a 16x24 pixel sprite, 2 x 3 cells) from its position: each
; is the OR of the flags of two neighbouring cells. UpdateChaser then turns
; them into a mask of free directions. The player has its own copy in
; PlayerTileHead.
;
; +0 ProbeRight: the two cells to the right of the sprite (rows 1 and 2) +1
; ProbeLeft: the two cells to the left (rows 1 and 2) +2 ProbeBelow: the two
; cells under the feet +3 ProbeHead: the two cells of the top row of the sprite
ProbeRight:
  DEFB $00
ProbeLeft:
  DEFB $00
ProbeBelow:
  DEFB $00
ProbeHead:
  DEFB $00

; Write pointer of the redraw run list
;
; Word. BuildRedrawList sets it to $C200, the start of the redraw run list, at
; the beginning of the redraw pass of each frame; CollectRedrawRun advances it
; as it appends the records of the runs of marked cells of a row and keeps a
; $FF after the last record. DrawRedrawList later walks the list and draws the
; cells.
RedrawListPtr:
  DEFW $0000

; Interrupt stack: 38 bytes below $8585
;
; The interrupt handler InterruptHandler switches SP to $8585 and pushes all
; the registers here (IX, HL, AF, BC, DE and the alternate set: 20 bytes), so
; the routine it calls runs on this stack and the game stacks are untouched.
; The stack ends at $8585, where the handler's code begins. The image holds
; $FF.
InterruptStack:
  DEFS $26,$FF
