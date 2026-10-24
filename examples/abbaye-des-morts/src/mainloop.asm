; Game start and main loop
;
; Starts a game and then runs it: the code never returns, the Game Over screen
; and the ending jump back to $85FC.
;
; Start. On a 48K machine ($8506 = 1) it draws the title screen script
; ScriptTitle; the first start enters at StartGame_NoTitle instead (StartUp
; jumps there), because the loader's picture is already the title. It installs
; MenuFrame, the frame routine of the menus, in InterruptRoutine, starts the
; title music (track 3; on a 128K Patch128KHooks turns the LD HL at
; StartGame_Music into CALL MusicEntryGame), clears the 60 bytes $8512-$854D
; (respawn position, flags of the items and checkpoints, lives, crosses), sets
; 9 lives, enables the redraw of the lives bar and the crosses counter
; (DrawLivesBar, DrawCrossesHud: a NOP written over their RET), and waits in
; the title menu for ENTER (TitleWaitKey). It then installs the game frame
; routine GameFrameRoutine, clears the exit direction and the room state, runs
; the intro, room 0, until a key is pressed (RunIntro), makes Jean stand (state
; 4), takes the respawn position and room from the checkpoint rules
; (SelectCheckpoint: with no checkpoint taken, room 5 at X $2400, Y $4400,
; observed) and enters the room. On a 128K machine the title script is not
; drawn at all (by reading the code: the DEC A / CALL Z test is for a 48K
; machine only).
;
; Main loop (MainLoop). The low 7 bits of the room state RoomState say what to
; do, bit 7 only tells the frame routine GameFrame to run the game logic:
;
; 1 enter the room RoomNumber: EnterRoom, then RedrawRoom draws it with a
; sweep, then the state becomes $80 (playing).
;
; 2 respawn: copy the respawn position (RespawnX, RespawnY) to Jean's X and Y
; (PlayerX, PlayerY), then as 1.
;
; 3 the ending: RunEnding, then start again at StartGame.
;
; 4 after a death: SelectCheckpoint chooses the checkpoint (room, position,
; state 0), then as 2.
;
; 5 Game Over: script ScriptGameOver, music track 7, wait for a key, start
; again at StartGame.
;
; anything else (0 with bit 7 set): one frame of play, see below.
;
; One frame of play. The game logic does not run here but in the interrupt,
; once per frame at 50 Hz (GameFrameRoutine and GameFrame; observed: 800
; interrupts and 800 game frames in frames 700-1500 of tests/inputs/play.txt).
; The loop below is the foreground, which only draws. It calls the four
; one-shot gates (RunEventScript event script, ParchmentGate parchment,
; DrawLivesBar lives bar, DrawCrossesHud crosses counter: each is a RET until
; something arms it) over and over until the interrupt has completed a frame
; list (FrameListGate is NOP, written by EndFrameList), then runs the list of
; queued sprite commands (RunFrameList), builds and draws the changed cells and
; sprites (BuildRedrawList, DrawRedrawList), steps the three tile animations
; (DrawWaterReflection water strip, AnimateBloodTiles blood tiles,
; ShowCrossRing ring of crosses; each a RET until a room script enables it) and
; tests the room state again. A quiet frame is drawn by about T 55,000 of the
; frame; a busy one takes the whole frame or more. When the drawing outlasts
; the next interrupt, that frame's game logic still runs but its sprites are
; not queued, so the screen is updated on fewer frames than the logic
; (observed, same run: 586 draws for 800 frames).
;
; Hardware: none directly. The pacing comes from the gate FrameListGate that
; the 50 Hz interrupt opens; the screen is written by the routines called from
; here.
StartGame:
  LD A,(MachineType)      ; machine type: 1 on a 48K Spectrum
  LD HL,ScriptTitle       ; title screen script
  DEC A                   ; Z on a 48K machine
  CALL Z,RunScript        ; RunScript: draw the title (48K only)
StartGame_NoTitle:
  LD HL,MenuFrame         ; first start enters here; menu frame routine for the
                          ; title
  LD (InterruptRoutine),HL ; InterruptRoutine
StartGame_Music:
  LD HL,MusicEntryGame    ; 128K: becomes CALL $85F3 (start the music), written
                          ; by Patch128KHooks; on a 48K it only loads HL
  LD A,MUSIC_TRACK_TITLE
  LD (MusicTrack),A       ; MusicTrack
  LD HL,RespawnX          ; first byte to clear: RespawnX
  LD BC,$3C00             ; B = 60 bytes ($8512-$854D), C = 0
StartGame_Clear:
  LD (HL),C
  INC HL
  DJNZ StartGame_Clear
  LD HL,Crosses           ; Crosses: 0 (already cleared by the loop)
  LD (HL),C
  DEC HL
  LD (HL),MAX_LIVES       ; Lives
  LD HL,DrawCrossesHud    ; DrawCrossesHud: NOP instead of RET, so it draws
                          ; once
  LD (HL),C
  LD HL,DrawLivesBar      ; DrawLivesBar: NOP instead of RET
  LD (HL),C
  LD HL,PlayerAnimTimer   ; Jean's animation timer PlayerAnimTimer
  LD (HL),$08
  CALL TitleWaitKey       ; title menu: ENTER starts, C opens the controls menu
  LD HL,GameFrameRoutine  ; game frame routine
  LD (InterruptRoutine),HL
  XOR A                   ; exit direction 0 (right)
  LD (ExitDirection),A
  LD (RoomState),A        ; room state 0
  CALL RunIntro           ; intro: room 0 until a key is pressed
  LD A,PLAYER_STANDING
  LD (PlayerState),A      ; PlayerState
MainLoop_AfterDeath:
  CALL SelectCheckpoint   ; chooses room and respawn position, sets room state
                          ; 0
MainLoop_Respawn:
  LD HL,(RespawnX)        ; respawn position X (8.8) ...
  LD (PlayerX),HL         ; ... to Jean's X
  LD HL,(RespawnY)        ; respawn position Y ...
  LD (PlayerY),HL         ; ... to Jean's Y
MainLoop_EnterRoom:
  CALL EnterRoom          ; build the room
  CALL RedrawRoom         ; draw it, sweeping in from the side Jean left by
  LD A,STATE_RUNNING
  LD (RoomState),A        ; RoomState: playing
MainLoop:
  LD A,(RoomState)        ; RoomState
  AND $7F                 ; bit 7 is only the "run the game logic" flag
  DEC A                   ; state 1: enter the room
  JR Z,MainLoop_EnterRoom
  DEC A                   ; state 2: respawn
  JR Z,MainLoop_Respawn
  DEC A                   ; state 3: the ending
  JR Z,MainLoop_Ending
  DEC A                   ; state 4: restart after a death
  JR Z,MainLoop_AfterDeath
  DEC A                   ; state 5: Game Over
  JR Z,MainLoop_GameOver
MainLoop_Play:
  CALL RunEventScript     ; event script (once, when armed)
  CALL ParchmentGate      ; parchment (when one was picked up)
  CALL DrawLivesBar       ; lives bar
  CALL DrawCrossesHud     ; crosses counter
  LD A,(FrameListGate)    ; frame list gate: $C9 (RET) until the interrupt
                          ; completes a list, then NOP
  OR A
  JR NZ,MainLoop_Play     ; not ready: the gates again
  CALL FrameListGate      ; = RunFrameList, run the frame list of sprite
                          ; commands
  CALL BuildRedrawList    ; build the redraw runs, draw the sprite jobs into
                          ; the cells
  CALL DrawRedrawList     ; copy the cells to the screen
  CALL DrawWaterReflection ; water strip of rooms 16 and 19
  CALL AnimateBloodTiles  ; blood tiles of rooms 21-23
  CALL ShowCrossRing      ; ring of crosses of room 24
  JP MainLoop             ; next frame
MainLoop_Ending:
  CALL RunEnding          ; the ending, then restart the game
  JP StartGame
MainLoop_GameOver:
  LD HL,ScriptGameOver    ; Game Over screen script
  CALL RunScript
  LD A,MUSIC_TRACK_GAME_OVER ; MusicTrack 7
  LD (MusicTrack),A
  CALL WaitKeyPress       ; wait for a key press
  CALL WaitKeyRelease     ; wait for the key to be released
  JP StartGame

; Enter a room
;
; Builds the room whose number is in RoomNumber from nothing, in this order:
; the table of bit-reversed bytes at $C500 (BuildMirrorTable: the sprite
; unpacker mirrors sprites with it); RET ($C9) over the first instruction of
; five one-shot routines, which switches them off until the room script or an
; item arms them again (the tile animations DrawWaterReflection,
; AnimateBloodTiles, ShowCrossRing, the parchment gate ParchmentGate and the
; event script gate RunEventScript); the draw queue $C000-$C0FF is cleared; the
; 11 object slots at $C100 are freed and the end mark EndOfSlots is written
; after them; the room state is set to 0 (the frame routine reads the keys but
; runs no game logic while the room is built); the room script (the word of
; room N is at $7236 + 2 N) is run by RunScript, which fills the tile map and
; the tile flags, unpacks the sprites and marks every cell for redraw; the room
; items (SpawnRoomItems) and the room objects (SpawnRoomObjects) are spawned;
; the music track is taken from the table RoomMusicTable; and the frame list
; gate FrameListGate is closed, so that the main loop waits for a complete game
; frame before it draws.
;
; Nothing is drawn to the screen here apart from what the room script itself
; prints: the callers follow with RedrawRoom (the sweep in). Jean's position is
; not touched. The RET at the end is also the address StartUp installs in
; InterruptRoutine before the game starts (NoFrameRoutine).
;
; Hardware: none directly (the room script may write screen and attributes).
;
; O:IX Changed (by the spawners)
EnterRoom:
  LD HL,RedrawPixels      ; redraw pixel buffer page
  CALL BuildMirrorTable   ; = BuildMirrorTable; leaves B = 0
  LD A,OP_RET             ; RET over: DrawWaterReflection, AnimateBloodTiles,
                          ; ShowCrossRing (tile animations), ParchmentGate,
                          ; RunEventScript (gates)
  LD (DrawWaterReflection),A
  LD (AnimateBloodTiles),A
  LD (ShowCrossRing),A
  LD (ParchmentGate),A
  LD (RunEventScript),A
  LD HL,DrawQueue         ; clear the draw queue, $C000-$C0FF; B = 0 from
                          ; BuildMirrorTable
EnterRoom_0:
  LD (HL),B
  INC L
  JR NZ,EnterRoom_0
  LD HL,ObjectSlots       ; object slots
  LD DE,EndOfSlots        ; handler word of the end mark
  LD BC,OBJECT_SLOTS*$0100 ; B = 11 slots, C = 0
EnterRoom_1:
  LD (HL),C               ; free the slot: handler word = 0
  INC L
  LD (HL),C
  LD A,L
  ADD A,SLOT_SIZE-$01     ; next slot (22 bytes, L was incremented once)
  LD L,A
  DJNZ EnterRoom_1
  LD (HL),E               ; end mark: handler word EndOfSlots after the last
                          ; slot
  INC L
  LD (HL),D
  XOR A
  LD (RoomState),A        ; room state 0
  LD HL,(RoomNumber)      ; L = room (H is overwritten next)
  LD H,$00
  ADD HL,HL
  LD DE,RoomScriptTable   ; room script table, one word per room 0-25
  ADD HL,DE
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  CALL RunScript          ; build the room
  CALL SpawnRoomItems     ; room items: hearts, crosses, levers...
  CALL SpawnRoomObjects   ; room objects: enemies and scenery movers
  LD A,(RoomNumber)       ; room number
  LD HL,RoomMusicTable    ; music track of each room
  CALL AddAToHL
  LD A,(HL)
  LD (MusicTrack),A       ; MusicTrack
  LD A,OP_RET             ; close the frame list gate
  LD (FrameListGate),A
NoFrameRoutine:
  RET                     ; RET: also the do-nothing frame routine before the
                          ; game starts

; Beeper sound effects: one frame of the current effect
;
; Called once per frame by the frame routine GameFrameRoutine, before the game
; logic. On a 128K machine with an AY chip Patch128KHooks turns the first
; instruction into JP PlayEffectOnAY and this code is not used. A game routine
; requests an effect by storing its number in SoundRequest (0 = none; SFX_
; constants); this routine takes the request, clears it, and plays one step of
; the effect in SoundPlaying every frame until the effect ends. A new request
; replaces the effect that is playing at once (observed, F104). An effect can
; chain another one when it ends (field +7 of its record).
;
; Effect 1 is built in: a noise burst of 10 frames (NOISE_FRAMES), each 48
; speaker samples (NOISE_SAMPLES) of bit 4 of NoiseByte, about 180 T-states
; apart. No code of the image requests effect 1 (by reading the stores to
; SoundRequest).
;
; Effects 2-9 are tones. Their 8-byte records (SoundEffects) are copied to
; SoundPeriod when the effect starts, and the first step is played at once. One
; step is a burst of exactly 255 loop counts (BURST_COUNTS, about 6,900
; T-states, the CPU is held in the interrupt): the speaker bit is flipped every
; PERIOD counts, a flip every 27 * PERIOD + 29 T-states (observed: PERIOD 40
; gives 1,109), so the burst holds 255 / PERIOD half-waves and PERIOD 0 gives a
; single click. After each burst PERIOD changes by STEP (8-bit wrap-around, so
; a large step makes the pitch jump about) and the frame counter FRAMES drops.
; When it reaches 0 the segment is over: the segment counter SEGMENTS drops,
; and when that reaches 0 the effect ends (and starts the chained effect, if
; the record has one). Otherwise the next segment starts: MODE 0 sets PERIOD
; back to BASE, 1 lowers BASE by 2 first (higher pitch each time), 2 raises it
; by 2 (lower pitch), anything else keeps PERIOD and reverses STEP (the pitch
; sweeps back); FRAMES is reloaded from RELOAD. The fields are described at
; SoundPeriod.
;
; Hardware: writes the speaker through port $FE (bit 4; the border bits are 0,
; so the border goes black during a burst). The timing loops run with
; interrupts disabled, inside the interrupt handler, so a step takes the CPU
; for 7,000-9,000 T-states of the frame (observed). Nothing is heard between
; the bursts: a tone is a 50 Hz train of 2 ms bursts.
;
; The first instruction (LD HL,$85D5) is the patch point of Patch128KHooks; on
; a 48K machine it only loads HL.
PlaySoundStep:
  LD HL,PlayEffectOnAY    ; 128K with AY: becomes JP $85D5 (Patch128KHooks)
  LD A,(SoundRequest)     ; SoundRequest
  AND A
  JR Z,PlaySoundStep_Continue ; none: go on with the effect playing
  LD (SoundPlaying),A     ; SoundPlaying = the new effect (replaces one that is
                          ; playing)
  DEC A                   ; effect 1?
  JR Z,PlaySoundStep_NoiseStart ; yes: the built-in noise
  LD HL,SoundEffects      ; effect table (effects 2-9)
  DEC A                   ; effect number - 2 ...
  ADD A,A                 ; ... times 8, the record size
  ADD A,A
  ADD A,A
  LD E,A
  XOR A                   ; request taken
  LD (SoundRequest),A
  LD D,A
  ADD HL,DE               ; record of the effect
  LD BC,SFX_SIZE
  LD DE,SoundPeriod       ; current effect, SoundPeriod
  LDIR                    ; copy the record
  JR PlaySoundStep_Tone   ; play its first step now
PlaySoundStep_Continue:
  LD A,(SoundPlaying)     ; SoundPlaying
  AND A
  RET Z                   ; no effect: nothing to play
  DEC A
  JR NZ,PlaySoundStep_Tone ; not effect 1: a tone step
  JR PlaySoundStep_Noise  ; effect 1: a noise step
PlaySoundStep_NoiseStart:
  LD A,NOISE_FRAMES       ; noise: 10 frames, counted in SEGMENTS SoundSegments
  LD (SoundSegments),A
  XOR A
  LD (SoundRequest),A     ; request taken
PlaySoundStep_Noise:
  LD B,NOISE_SAMPLES      ; 48 samples per frame
PlaySoundStep_0:
  CALL NoiseByte          ; = NoiseByte: a "random" byte
  AND SPEAKER_BIT         ; speaker bit; the border bits are 0
  OUT (ULA_PORT),A
  LD C,$02                ; delay between samples
PlaySoundStep_1:
  DEC C
  JR NZ,PlaySoundStep_1
  DJNZ PlaySoundStep_0
  LD HL,SoundSegments     ; frames left
  DEC (HL)
  RET NZ                  ; effect goes on next frame
  XOR A                   ; end: SoundPlaying = 0
  LD (SoundPlaying),A
  RET
PlaySoundStep_Tone:
  LD A,(SoundPeriod)      ; PERIOD of this burst
  LD H,A                  ; H keeps it for the whole burst
  LD A,SPEAKER_BIT        ; speaker bit set
  LD D,BURST_COUNTS       ; D counts the burst: 255 counts
PlaySoundStep_2:
  LD E,H                  ; E counts half a period
  OUT (ULA_PORT),A        ; flip the speaker
  XOR SPEAKER_BIT         ; next level
PlaySoundStep_3:
  DEC D                   ; count the burst down
  JR Z,PlaySoundStep_BurstEnd ; burst over
  DEC E
  JR NZ,PlaySoundStep_3
  JR PlaySoundStep_2
PlaySoundStep_BurstEnd:
  LD A,(SoundStep)        ; burst over: PERIOD += STEP
  ADD A,H
  LD (SoundPeriod),A      ; (8-bit wrap-around)
  LD HL,SoundFrames       ; FRAMES
  DEC (HL)                ; one frame of the segment done
  RET NZ                  ; segment goes on next frame
  LD HL,SoundSegments     ; SEGMENTS
  DEC (HL)                ; one segment done
  JR NZ,PlaySoundStep_NextSeg ; more segments: set up the next
  XOR A                   ; effect over: SoundPlaying = 0
  LD (SoundPlaying),A
  LD A,(SoundNext)        ; chained effect (+7)
  AND A                   ; none
  RET Z
  LD (SoundRequest),A     ; chain: SoundRequest = next effect, played from the
                          ; next frame
  RET
PlaySoundStep_NextSeg:
  LD A,(SoundBase)        ; BASE
  LD C,A
  LD A,(SoundMode)        ; MODE
  AND A
  JR Z,PlaySoundStep_6    ; 0: PERIOD back to BASE
  DEC A
  JR Z,PlaySoundStep_5    ; 1: BASE - 2
  DEC A
  JR Z,PlaySoundStep_4    ; 2: BASE + 2
  LD A,(SoundStep)        ; 3 or more: keep PERIOD, reverse STEP
  NEG
  LD (SoundStep),A
  JR PlaySoundStep_7
PlaySoundStep_4:
  INC C                   ; mode 2: BASE + 2 ...
  INC C
  LD A,C
  LD (SoundBase),A
  JR PlaySoundStep_6
PlaySoundStep_5:
  DEC C                   ; mode 1: BASE - 2 ...
  DEC C
  LD A,C
  LD (SoundBase),A
  JR PlaySoundStep_6
PlaySoundStep_6:
  LD A,C                  ; PERIOD = BASE
  LD (SoundPeriod),A
PlaySoundStep_7:
  LD A,(SoundReload)      ; FRAMES = RELOAD
  LD (SoundFrames),A
  RET

; Random byte for the noise effect
;
; Meant to return the Refresh register XORed with a byte of the ROM, read
; through a pointer that walks the first 1,024 bytes of the ROM ($87E8). The
; pointer is stored with LD ($87E8),A instead of LD ($87E8),HL: A is the high
; byte masked to 0-3, written over the LOW byte, so the pointer stays $1000, HL
; becomes $0001 after the INC and the AND, and the byte read is always the ROM
; byte at $0001 ($01 in the standard 48K ROM). The result is R XOR $01. R
; counts instructions, so the 'noise' of effect 1 is a regular pattern
; (observed: the bit 4 of the 48 samples of a frame repeat '001' with a phase
; change). An original bug; no request ever starts effect 1 anyway.
;
; Hardware: reads the Refresh register (LD A,R) and ROM memory.
;
; O:A R XOR (ROM byte at $0001)
NoiseByte:
  PUSH HL
  LD HL,(NoisePointer)    ; noise pointer, $1000 and never changed
  INC HL                  ; $1001
  LD A,H                  ; H = $10
  AND $03                 ; window of 1,024 bytes, intended to keep the pointer
                          ; in $0000-$03FF
  LD H,A                  ; H = 0: HL = $0001
  LD (NoisePointer),A     ; BUG: stores A (0-3) over the low byte of the
                          ; pointer instead of HL
  LD A,R                  ; refresh register
  XOR (HL)                ; XOR the ROM byte at $0001
  POP HL
  RET

; Noise pointer into the ROM
;
; Word. Read and 'advanced' by NoiseByte, which was meant to walk the ROM
; addresses $0000-$03FF to make noise; the store is wrong (see there), so the
; word stays $1000 in every run.
NoisePointer:
  DEFW $1000

; Current sound effect: the 8-byte record being played
;
; PlaySoundStep copies the record of the requested effect from SoundEffects
; here when the effect starts and updates the first four fields while it plays.
; The record format is the one of the table:
;
; +0 byte: PERIOD, the loop count between two flips of the speaker in the burst
; of a frame (0 means one click only). The smaller it is, the higher the pitch.
;
; +1 byte: STEP, added to PERIOD after every frame with 8-bit wrap-around ($FA
; is -6); a negative step raises the pitch
;
; +2 byte: FRAMES, the frames (bursts) left in the current segment; the table
; value is the length of the first segment
;
; +3 byte: SEGMENTS, the number of segments of the effect, counted down as they
; end (the noise effect uses it as its frame counter)
;
; +4 byte: MODE, what happens to PERIOD at the start of the next segment: 0
; PERIOD = BASE, 1 BASE -= 2 and PERIOD = BASE, 2 BASE += 2 and PERIOD = BASE,
; 3 or more PERIOD goes on and STEP changes sign
;
; +5 byte: BASE, the PERIOD a new segment starts from (changed by modes 1 and
; 2)
;
; +6 byte: RELOAD, the length in frames of the second and later segments (0
; means 256)
;
; +7 byte: NEXT, the effect to start when this one has ended, 0 for none
SoundPeriod:
  DEFB $00
SoundStep:
  DEFB $00
SoundFrames:
  DEFB $00
SoundSegments:
  DEFB $00
SoundMode:
  DEFB $00
SoundBase:
  DEFB $00
SoundReload:
  DEFB $00
SoundNext:
  DEFB $00

; Sound effects 2-9: 8-byte records, effect n at $87F2 + 8 * (n - 2)
;
; The tone effects of PlaySoundStep. PlaySoundStep copies the record of the
; requested effect to SoundPeriod, where the fields are described: +0 PERIOD,
; +1 STEP, +2 FRAMES (first segment, frames), +3 SEGMENTS, +4 MODE, +5 BASE, +6
; RELOAD (later segments, frames), +7 NEXT (chained effect). Effect 1 (noise)
; is built into the routine and has no record.
;
; Who plays what (SFX_ constants; observed by watching SoundRequest in runs,
; except the checkpoint and the portal, which are inferred from the callers): 2
; jump, 3 bell or lever touched, 4 passage between rooms 10 and 19, 5 item
; taken or lever pulled, 6 Jean dies, 7 Death throws a scythe or Satan fires, 8
; the church door, 9 a checkpoint.
;
; Effects 2 and 8 are the same record, 5 and 9 too. Lengths and sweeps, from
; the fields: every effect is one segment except effect 6; the lengths are 2,
; 30, 10, 8, 56 (40 + 8 + 8), 1, 2 and 8 frames. Effect 5 (observed with the
; simulator, one burst per frame): PERIOD 40, 34, 28, 22, 16, 10, 4, 254, a
; rising chirp that ends in one low blip.
SoundEffects:
  DEFB $00,$02,$02,$01,$00,$00,$00,$00 ; 2 SFX_JUMP: 2 frames, PERIOD 0 (one
                                       ; click) then 2 (about 21 kHz)
  DEFB $A0,$50,$1E,$01,$00,$00,$00,$00 ; 3 SFX_TRIGGER: 30 frames, PERIOD $A0 +
                                       ; $50 per frame (wraps: a warble)
  DEFB $E6,$E6,$0A,$01,$02,$00,$00,$00 ; 4 SFX_PORTAL: 10 frames, PERIOD $E6 -
                                       ; $1A per frame
  DEFB $28,$FA,$08,$01,$00,$00,$00,$00 ; 5 SFX_PICKUP: 8 frames, PERIOD 40 - 6
                                       ; per frame (rising)
  DEFB $04,$F2,$28,$03,$02,$50,$08,$00 ; 6 SFX_DEATH: 3 segments, 40 frames
                                       ; from PERIOD 4 (STEP -14), then 8
                                       ; frames from BASE+2 = $52 and 8 from
                                       ; $54
  DEFB $14,$00,$01,$01,$00,$00,$00,$00 ; 7 SFX_ENEMY_SHOT: one frame, PERIOD 20
  DEFB $00,$02,$02,$01,$00,$00,$00,$00 ; 8 SFX_DOOR: as effect 2
  DEFB $28,$FA,$08,$01,$00,$00,$00,$00 ; 9 SFX_CHECKPOINT: as effect 5
