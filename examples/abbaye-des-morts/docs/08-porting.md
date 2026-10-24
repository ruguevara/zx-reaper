# 8. Porting notes

What a port to C or Python on a Spectrum-like platform library (a 256 x 192
bitmap with 32 x 24 attribute cells, a beeper, a keyboard matrix, a 50 Hz
tick) has to replace, and what it can keep. The game splits cleanly into a
logic routine called once per frame from the interrupt and a foreground that
only draws, so the logic ports as a function per tick; the parts that need
care are the drawing, which runs at its own pace, the stack tricks and the
self-modifying code. Stages 3 and 4 of the harness (a Python port checked
against the original) have not been done for this game.

## Control flow

| Original | What it is | In a port |
| --- | --- | --- |
| [InterruptHandler](../src/interrupt.asm#L30) at $8585, IM 2 | calls the routine in [InterruptRoutine](../src/variables.asm#L34) once per frame with interrupts disabled | the tick |
| [GameFrameRoutine](../src/interrupt.asm#L178) | [PlaySoundStep](../src/mainloop.asm#L288) then [GameFrame](../src/gameframe.asm#L20): keys, Jean's probes, all object slots, Jean, the exits | `frame()`, 50 times a second |
| [MenuFrame](../src/controls.asm#L548) | the menus' tick: sound step, keyboard scan, key code | the tick while a menu is up |
| [StartGame](../src/mainloop.asm#L65) and [MainLoop](../src/mainloop.asm#L119) | the room state machine (1 enter, 2 respawn, 3 ending, 4 after a death, 5 Game Over) and the drawing of play | the main loop |
| [RunIntro](../src/sequences.asm#L21), [RunCutscene](../src/sequences.asm#L167) | the same drawing loop with other exit tests | loops over ticks |
| [ShowTextWindow](../src/hud.asm#L116), [WaitKeyPress](../src/helpers.asm#L9), [WaitKeyRelease](../src/helpers.asm#L27), [TitleMenu](../src/controls.asm#L297) | foreground waits with HALT; the tick keeps running with bit 7 of the room state clear (no logic) | waits that keep calling the tick |

The two halves talk through a few bytes: [FrameListGate](../src/templates.asm#L252) (a list of draw
commands is complete), [QueueDrawCmd](../src/player.asm#L445) (the list is being drawn: do not
queue), [RoomState](../src/variables.asm#L116) (bit 7: run the logic; low bits: what the main loop
does next). Logic never waits for drawing: a frame whose list is not drawn
in time is simply not shown ([The game loop](04-game-loop.md), F103). A port that draws after
every tick shows every logic frame (50 pictures a second against the
original's 21-38) without changing the game.

For a check against the original frame by frame, the logic state is what
should be compared: the variables at $8501-$855E, the object slots, Jean's
block at [PlayerState](../src/player.asm#L30), the tile map and the class bits of the flag map.
The redraw bits 6 and 7 of the flag map, the frame call list, the draw
queue and the redraw buffers depend on when the foreground got to run,
which depends on T-states.

## Hardware touch points

| Hardware | Routines | Replace with |
| --- | --- | --- |
| screen bitmap and attributes, through the cell buffers | [DrawRedrawList](../src/redraw.asm#L32) ([CopyAttrChain](../src/redraw.asm#L106), [CopyBitmapBack](../src/redraw.asm#L196), [CopyBitmapForward](../src/redraw.asm#L269)) | copy changed cells to the platform screen, or redraw everything each tick |
| screen, directly | [RedrawCell](../src/sprites.asm#L1231) ([RedrawRoom](../src/sprites.asm#L1147)), [DrawGlyph](../src/script.asm#L531) (XOR), [FillBitmapRect](../src/script.asm#L895) and [FillAttrRect](../src/script.asm#L925) (script opcodes $81 and $8F), [DrawTileCells](../src/hud.asm#L45) and [FillHudAttrs](../src/hud.asm#L69) (status bar), [DrawFrameCell](../src/hud.asm#L226) (parchment frame), [CopyMenuArea](../src/controls.asm#L592) (save and restore under the menus) | drawing calls of the platform |
| screen read back | [DrawWaterReflection](../src/effects.asm#L29): copies screen lines above the water into the water row, so whatever is on the screen there (sprites included) is reflected | a screen bitmap the port can read, or the same copy in its own buffer |
| port $FE out | [PlaySoundStep](../src/mainloop.asm#L288) (speaker bit 4, border bits 0), [StartUp](../src/startup.asm#L39) (black border) | a square-wave voice; the border is always black |
| port $FE in | [ScanKeyboard](../src/helpers.asm#L221) (eight half-rows with INI, then all rows at once), [WaitKeyPress](../src/helpers.asm#L9), [WaitKeyRelease](../src/helpers.asm#L27) (all rows) | a key-matrix read returning active-low bits |
| port $1F | [StartUp](../src/startup.asm#L39) (65536 reads: is there a Kempston?), [ReadKempston](../src/controls.asm#L61) (bits 0-2 and 4 used) | joystick state; the probe can become a setting |
| port $7FFD | [PageInBank](../src/interrupt.asm#L139) via [PageInBank0](../src/interrupt.asm#L105) (every machine at start-up), the 128K hooks | nothing on a 48K port; a module player for the 128K music |
| ports $FFFD, $BFFD (AY) | only the loader's [WriteAY](../src/stage2.asm#L157) and the music bank | an AY emulator or a module player |
| IM 2 and I | [StartUp](../src/startup.asm#L39), [Im2Table](../src/im2table.asm#L11), [InterruptHandler](../src/interrupt.asm#L30) | the platform's tick |
| HALT | [WaitKeyPress](../src/helpers.asm#L9), [WaitKeyRelease](../src/helpers.asm#L27), [WaitSpaceRelease](../src/controls.asm#L245), [TitleMenu](../src/controls.asm#L297), [RedefineOneKey](../src/controls.asm#L410) | wait for the next tick |
| R register | [ThrowDeathScythe](../src/entities.asm#L3234) (bit 0: the side Death throws to, F49), [ActionChurchDoor](../src/gameframe.asm#L173) (the 32-63 frame flicker interval, F28), [NoiseByte](../src/mainloop.asm#L422) (unused effect) | any random bit; for a frame-exact check, the values the original read (`tools/zxrun.py --take`) |
| ROM | the loader's copy of LD-BYTES; [NoiseByte](../src/mainloop.asm#L422) reads $0001 | nothing; the game itself does not call the ROM |

The keyboard is read as (half-row, mask) pairs ([ControlKeys](../src/controls.asm#L131)): RIGHT,
LEFT, CROUCH, JUMP twice, and the fixed T, R and Y (F27). The key names of
the controls screen come from [KeyCodeTable](../src/controls.asm#L200).

## Timing

Every speed of the game is counted in logic frames at 50 Hz: Jean walks 1
pixel a frame (F70), a jump lasts 36 frames (F71), the death 32 (F73), the
crusaders come every 40 frames (F118), Death throws every 50 (F49), the
archers shoot every 80 (F81). A port that calls `frame()` 50 times a second
has the original speed.

The logic stops, with the tick still running and the keys still read, while:

- a room is entered: the room script and the sprite unpacking take 7-15
  frames and the sweep 8-9 more; the sweep ended 14 to 27 frames after the
  room state was poked, depending on the room ([Screen drawing](05-drawing.md));
- a text window or a parchment waits for a key;
- the Game Over screen and the end of the ending wait for a key.

A port that builds and draws a room at once removes up to half a second per
room change; for the same rhythm it can wait the same number of ticks.

Sound: an effect is one burst per frame of 255 loop counts, about 2 ms, in
which the speaker flips every 27 x PERIOD + 29 T-states (3.5 MHz clock),
PERIOD changing by STEP after each burst ([Sound](05-sound.md), F105). A port plays,
per tick, 2 ms of square wave at 3,500,000 / (2 x (27 x PERIOD + 29)) Hz and
then silence; PERIOD 0 is one click.

## Data formats to use as they are

The formats are in [Data structures](02-data.md). A port can load the 40 KB
block $6000-&#36;FEFF from `re/image.z80` and read:

| Data | Address | Format |
| --- | --- | --- |
| room scripts | [RoomScriptTable](../src/roomscripts.asm#L8) $7236, bytecode to $83A7 | 26 words, then bytecode of 32 opcodes for [RunScript](../src/script.asm#L84) ([Rooms](05-rooms.md)); the port either runs the interpreter or stores the 25 resulting tile maps, flag maps and room effects |
| tiles | [TileFlags](../src/tiles.asm#L36) $CD00, [TileAttrs](../src/tiles.asm#L61) $CE00, [TileGfx](../src/tiles.asm#L90) $CF00 | 256 classes, attributes, 8-byte bitmaps |
| room objects, room items | [RoomObjects](../src/objects.asm#L259) $8B8F, [RoomItems](../src/objects.asm#L580) $8EDF | 11- and 8-byte records |
| item types and frames | [ObjectTypeTable](../src/objects.asm#L14) $8A8F, [FramesHeart](../src/objects.asm#L120) $8B07 | 8-byte type records, 4-byte frames |
| item sprites | [SpriteArch](../src/graphics.asm#L24) $66DC | 16 pixels wide, 2 bytes per pixel row |
| behaviour blocks, templates | [BehaviourJean](../src/behaviours.asm#L41) $93D3, [ArrowLeftTemplate](../src/templates.asm#L26) $BC92 | per kind ([Data structures](02-data.md)); they hold sprite sheet addresses |
| sprite sets | [PackedSet0](../src/graphics.asm#L308) $68CC, [UnpackRecords](../src/unpack.asm#L24) $AE9D | packed columns; unpack with shifted and mirrored copies ([Screen drawing](05-drawing.md)) |
| fixed sprites | [SpriteSheet](../src/spritesheet.asm#L25) $D700 columns $00-$62 | Jean, the small projectiles |
| font | [FontIndex](../src/font.asm#L11) $6130 | index of 96 words, masked 16-row glyphs |
| texts | [RoomNames](../src/text.asm#L18) $9048 | 53 strings, a length byte and the characters |
| parchment frame | [ParchmentFrameTiles](../src/graphics.asm#L651) $717F, [ParchmentLayout](../src/graphics.asm#L679) $71DF | 12 tiles, run-coded layout |
| checkpoints | [Checkpoints](../src/templates.asm#L364) $BE2A | 10 records: room, row, column |
| sound effects | [SoundEffects](../src/mainloop.asm#L510) $87F2 | 8-byte records for effects 2-9 |
| music per room, cutscene actors | [RoomMusicTable](../src/cutscenelists.asm#L63) $83E6, [CutsceneList1](../src/cutscenelists.asm#L14) $83A8 | bytes; count and 4-byte records |
| screens | `data/loading.scr`, `data/info.scr`, `data/picture.scr` | 6912-byte screen dumps |
| 128K music | `data/music128.bin` | unpacked by the loader to $CF6D in the bank; a table of 9 modules at $D892 (8 Vortex Tracker II, 1 ProTracker 3.5 compilation) |

Graphics addresses in the behaviour blocks, the templates and the monk's
frame tables point into the sprite sheet (&#36;D7xx-&#36;FExx, page = pixel row).
The simplest port keeps a 10 KB sheet with the same layout and fills it per
room as [UnpackSpriteSet](../src/unpack.asm#L86) does; a port with one image per sprite has to
translate these addresses.

## Behaviour that depends on memory layout

These come from where things are in memory; a port with separate arrays
loses them silently. None of them shows in normal play except F120.

- **F120** For one frame, when Jean stops crouching and starts to fall, his
  graphics are read from the code bytes of [QueueSprite](../src/sprites.asm#L38) at $983C.
  Reproducing it needs those bytes.
- **F51** The sliding scythe's draw path uses x for y (not reached in
  play).
- **F95** The chasing ghost reads the flag map as a flat array: at the edges
  it reads the end of the previous row or the start of the next.
- **F55** A 16-byte template copies two bytes of the next template into the
  slot.
- **F44** A 17th draw job would overwrite the first object slot (never
  reached).
- **F77** Room numbers wrap modulo 25 as bytes (debug warp only).
- The flag map byte holds the tile class (bits 0-2) and the redraw marks
  (bits 6, 7); the collision code masks the class bits (`AND 1`, `AND 2`,
  `AND 3`, `AND 7`), so the marks do not disturb it. A port can keep two
  arrays.

The `PUSH BC` that repairs what the interrupt writes into the graphics
([Tricks](06-tricks.md)) has no counterpart in a port without interrupts.

## Self-modifying code

| Original | In a port |
| --- | --- |
| one-byte gates (RET/NOP): [DrawLivesBar](../src/sprites.asm#L1321), [DrawCrossesHud](../src/hud.asm#L17), [ParchmentGate](../src/hud.asm#L88), [RunEventScript](../src/hud.asm#L279), [FrameListGate](../src/templates.asm#L252), [QueueDrawCmd](../src/player.asm#L445), [DrawWaterReflection](../src/effects.asm#L29), [AnimateBloodTiles](../src/effects.asm#L187), [ShowCrossRing](../src/effects.asm#L240) | booleans |
| [KempstonSwitch](../src/controls.asm#L46), [SmcWarpCheat](../src/player.asm#L568) (the RAGE cheat) | settings: joystick on, cheat on |
| operands that hold values: SP and return addresses, pointers, counters, the room sweep steps, the water parameters, the event script address, the cross colour step | variables |
| JR into unrolled chains (redraw copy, water copy, glyph shift) | loops with a count |
| [Patch128KHooks](../src/startup.asm#L122) | a 128K option: title and info screens from the bank, music, AY effects |
| handler words in the object slots, rewritten by the creatures | a state or function reference per object |
| the frame call list run by RET | a list of (routine, arguments) records |
| the object slots run by RET with SP in the slot | an array of objects with a handler field |

[CheckCheatKeys](../src/controls.asm#L516) toggles the cheat each time the keys are entered, and a
new game does not reset it (F123): the cheat is a property of the session,
not of the game.

## Entry points

| Address | Label | Entered from |
| --- | --- | --- |
| $5CF6 | [Stage1](../src/stage1.asm#L16) | BASIC: `PRINT USR (VARS+3)` |
| $6000 | [Stage2](../src/stage2.asm#L52) | Stage1, after unpacking it |
| $6000 | [StartUp](../src/startup.asm#L39) | the game's depacker, with the machine type on the stack (F132) |
| $8606 | [StartGame_NoTitle](../src/mainloop.asm#L70) | [StartUp](../src/startup.asm#L39), the first game (the loading screen is the title) |
| $85FC | [StartGame](../src/mainloop.asm#L65) | after Game Over and after the ending |
| $8585 | [InterruptHandler](../src/interrupt.asm#L30) | the IM 2 vector |
| $85E2, $A43D | [GameFrameRoutine](../src/interrupt.asm#L178), [MenuFrame](../src/controls.asm#L548) | through [InterruptRoutine](../src/variables.asm#L34) |
| $8659 | [MainLoop_EnterRoom](../src/mainloop.asm#L114) | room state 1; the coverage scripts enter rooms by poking $8509 and $850C |

Further dispatch goes through tables: script opcodes through
[ScriptOpTable](../src/hud.asm#L323), room object kinds through [EntityHandlers](../src/entities.asm#L29), item types
through [ObjectTypeTable](../src/objects.asm#L14) and the action word of each item record.

A useful order for a port is the order in which it can be checked: the room
scripts (compare the tile map and flag map at $5B00-$60BF after
[RunScript](../src/script.asm#L84) for all 26 scripts), the sprite unpacking (the sheet after
[UnpackSpriteSet](../src/unpack.asm#L86), F114), the font ([Screen drawing](05-drawing.md)), then [GameFrame](../src/gameframe.asm#L20)
with its slots against runs of `tests/inputs/*.txt`, then the drawing (the
model of [Screen drawing](05-drawing.md)), then sound.
