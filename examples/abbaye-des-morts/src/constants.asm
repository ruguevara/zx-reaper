; Numeric constants (sizes, counts, colours, key masks, codes), used in
; the skool files through @isub. Add with: tools/zxq.py const NAME VALUE COMMENT
; Addresses (ROM, system variables, screen) are @equ lines in re/skool/head.skool.
BLACK                    EQU 0 ; colour: black
BLUE                     EQU 1 ; colour: blue
RED                      EQU 2 ; colour: red
WHITE                    EQU 7 ; colour: white
PAPER                    EQU 8 ; attribute multiplier of the paper colour (ink colour is the low 3 bits)
BRIGHT                   EQU 0x40 ; attribute bit 6: bright
OP_RET                   EQU 0xC9 ; opcode of RET, written over the NOP at the start of a routine to switch it off: the one-shot gates (HUD, parchment, event script), the tile animations at room entry, the frame-list gate, QueueDrawCmd while the list runs, the Kempston read
SCREEN_COLS              EQU 0x20 ; character cells per screen row; also the row stride of the tile map, the flag map and the attribute file
ROOM_HEIGHT_2PX          EQU 0x58 ; height of the room area in 2-pixel units (22 cell rows of 4)
SUBROW_MASK              EQU 3 ; mask for the position of a sprite inside a cell row, in 2-pixel units (0-3)
SUBROWS_PER_CELL         EQU 4 ; 2-pixel units in a cell row (8 pixel rows)
CELL_SIZE                EQU 8 ; pixel rows (and bitmap bytes) of a character cell
PAGE_REDRAW_ATTRS        EQU 0xC4 ; high byte of the redraw cell buffer holding each cell's attribute
PAGE_REDRAW_PIXELS       EQU 0xC5 ; high byte of the first pixel-row page of the redraw cell buffer (page + n holds pixel row n of each cell)
FLAGS_PAGE_OFFSET        EQU 3 ; pages between the tile map ($5B00) and the tile flag map ($5E00)
TILE_HEART               EQU 0x7B ; tile number of the heart in the status bar
STATUS_CELLS             EQU 12 ; cells of a status bar row (hearts, crosses)
MAX_LIVES                EQU 9 ; lives at the start of a game, also the most the player can have (hearts in the status bar)
ULA_PORT                 EQU 0xFE ; keyboard in, border/beeper out
KB_CS_V                  EQU 0xFE ; high byte of port for half-row CAPS SHIFT,Z,X,C,V
KEY_BITS                 EQU 0x1F ; key bits of a half-row read (0 = pressed)
THIRD_STEP               EQU 8 ; step of the screen address high byte from one screen third to the next
ATTRS_HIGH               EQU 0x58 ; high byte of the attribute area address ($5800)
SCREEN_HIGH              EQU 0x40 ; high byte of the screen bitmap address ($4000)
MAP_ROWS                 EQU 22 ; rows of the tile map and the tile flag map (the room area)
FLAG_REDRAW              EQU 0x80 ; tile flag bit 7: the cell is marked for redraw
FLAG_HARMFUL             EQU 4 ; tile flag bit 2 (class 4): the cell kills the monk (ProbePlayer sets PlayerHit to 4) and removes Death's scythes; tiles $05, $3B, $3C, $4E-$74 (tile flag $84) and the water strips of rooms 16 and 19 (OpSetupWater)
TILEMAP_HIGH             EQU 0x5B ; high byte of the tile map address ($5B00)
FLAGMAP_HIGH             EQU 0x5E ; high byte of the tile flag map address ($5E00)
LDI_CHAIN_LEN            EQU 32 ; LDI instructions in the block copier chain at $ADA1-$ADE0
GLYPH_WIDTH_BIAS         EQU 2 ; added to the width field of a font index word to get the glyph advance
CHAR_SPACE               EQU 0x20 ; ASCII space, first glyph of the font
YELLOW                   EQU 6 ; colour: yellow
TILE_CROSS               EQU 0x7C ; tile number of the cross in the status bar
GLYPH_ROWS               EQU 16 ; pixel rows of a font glyph
WIDE_GLYPH               EQU 9 ; glyphs this wide (pixels) or wider have two bitmap bytes per new row
PARCHMENT_COLS           EQU 24 ; cells per row of the parchment frame
KEYCODE_CAPS_SHIFT       EQU 0x01 ; key code of CAPS SHIFT in the key code table (GetKeyCode)
KEYCODE_SYMBOL_SHIFT     EQU 0x02 ; key code of SYMBOL SHIFT
KEYCODE_ENTER            EQU 0x0D ; key code of ENTER
KEYCODE_1                EQU 0x31 ; key code of the 1 key (ASCII)
KEYCODE_2                EQU 0x32 ; key code of the 2 key (ASCII)
KEYCODE_C                EQU 0x43 ; key code of the C key (ASCII)
CTRL_ABORT               EQU 0xC0 ; control bits 6 and 7 together (the fixed keys R and Y): abort the game
KEMPSTON_MASK            EQU 0x17 ; Kempston bits used: right, left, down, fire (up, bit 3, is ignored)
PORT_KEMPSTON            EQU 0x1F ; Kempston joystick input port
CHEAT_BYTES              EQU 8 ; bytes of the cheat key table (4 row,mask pairs)
CHEAT_OPCODE_FLIP        EQU 0x30 ; XOR that turns the JR opcode ($18) into JR Z ($28) and back
OP_EX_DE_HL              EQU 0xEB ; opcode of EX DE,HL, patched over a NOP to reverse a block copy
KEY_ROWS                 EQU 8 ; keyboard half-rows read into the row buffer
CONTROL_KEYS             EQU 8 ; (row, mask) key pairs in the control key table
KEY_NAMES_LEN            EQU 8 ; characters of the key-name buffer on the controls screen
ATTRS_SIZE               EQU 0x300 ; bytes of the attribute file (24 rows of 32)
THIRD_SIZE               EQU 0x800 ; bytes of one screen third in the bitmap (8 character rows)
SLOT_SIZE                EQU 0x16 ; bytes of an object slot at $C100
ITEM_BOX                 EQU 8 ; width and height of an item's collision box, in 2-pixel units (16x16 pixels)
ITEM_GONE                EQU 0xFF ; item flag value: taken or finished, the item is not created again
CROSSES_NEEDED           EQU 12 ; crosses to collect before the chalice appears
CHECKPOINT_FLAGS         EQU 9 ; checkpoint flag bytes at $8543 (0 inactive, nonzero the active checkpoint)
WHEEL_STATE_MASK         EQU 7 ; bits of the wheel of faith flag ($851E) that tell its state (0 at rest, 6 turned)
WHEEL_TURNED             EQU 6 ; value of the state bits of the wheel of faith ($851E) when it is turned
STATE_RESPAWN            EQU 2 ; room state: put Jean at RespawnX/RespawnY ($8512/$8514) and enter the room (the arches of rooms 10 and 19 set it; state 4 goes on here after SelectCheckpoint)
STATE_ENDING             EQU 3 ; room state: ending sequence ($887B)
STATE_GAME_OVER          EQU 5 ; room state: Game Over screen ($A57E)
SFX_TRIGGER              EQU 3 ; sound effect: bell or lever touched once ($A748)
SFX_PORTAL               EQU 4 ; sound effect: passage between rooms 10 and 19
SFX_PICKUP               EQU 5 ; sound effect: an item taken (heart, cross, chalice, the final scroll), the wheel turned, the gate lever of room 20 pulled, a parchment read, a cross added to the ring of room 24, a key accepted in the menu
SFX_DOOR                 EQU 8 ; sound effect: the church door rattles
SFX_CHECKPOINT           EQU 9 ; sound effect: checkpoint touched
ROOM_BEAST               EQU 10 ; room number of Pestilent Beast (the dragon room)
ROOM_RIVER               EQU 19 ; room number of Underground river
ROW_TABLE_ENTRIES        EQU 24 ; words in the flag map row address table at $6100 (22 room rows and 2 spare)
ATTACK_PERIOD            EQU 0x32 ; frames between two throws of Death or two volleys of Satan (the timer reloads with it)
SFX_ENEMY_SHOT           EQU 7 ; sound effect: an enemy shoots or throws (Death, Satan, archers, plants, the fish splash, the Beast's fire)
OBJECT_ENTRY_SIZE        EQU 4 ; bytes of an entry of the object list at $5DC0: template address, y, x
TILE_CLASS_MASK          EQU 7 ; mask of the tile class in a tile flag (bits 0-2)
MUSIC_TRACK_GAME_OVER    EQU 7 ; music track 7: the Game Over screen ($86AB), also started when Satan turns into smoke ($BB57)
PLAYER_DYING             EQU 1 ; player state: dying
PLAYER_STANDING          EQU 4 ; player state: standing or walking
OP_CALL                  EQU 0xCD ; opcode of CALL, stored over the first byte of a 3-byte instruction to turn it into a call
OP_JP                    EQU 0xC3 ; opcode of JP
GRID_ROOMS               EQU 25 ; rooms of the 5x5 map: a room number wraps modulo this (room 25 is the ending room outside the grid)
PLAYER_JUMPING           EQU 2 ; player state: jumping (rising)
PLAYER_CROUCHING         EQU 3 ; player state: crouching
PLAYER_FALLING           EQU 5 ; player state: falling
PLAYER_WARP              EQU 0xFF ; player state: debug room warp (cheat only)
CTRL_RIGHT               EQU 1 ; control bit 0: right
CTRL_LEFT                EQU 2 ; control bit 1: left
CTRL_CROUCH              EQU 4 ; control bit 2: crouch
CTRL_JUMP                EQU 0x18 ; control bits 3 and 4: jump (the keyboard sets both, Kempston fire only bit 4)
TILE_BLOCKS              EQU 2 ; tile flag bit 1: the cell blocks the monk walking sideways or jumping up into it, and a fall stops on it (classes 2 and 3)
TILE_STANDABLE           EQU 1 ; tile flag bit 0: the monk can stand on the cell (classes 1 and 3); class 1 only from above: a jump that leaves the feet inside its row falls back through it
WALK_SPEED               EQU 0x80 ; horizontal speed of the monk, 8.8 per frame: half a unit of 2 pixels, one pixel
CROUCH_SPEED             EQU 0x20 ; horizontal speed of the crouching monk, 8.8 per frame: a quarter of a pixel
JUMP_SPEED               EQU 0x01FE ; vertical speed at the start of a jump, 8.8 units of 2 pixels per frame, upwards
GRAVITY                  EQU 0x1E ; change of the monk's vertical speed per frame, 8.8: the jump slows and the fall speeds up by this
FALL_SPEED_CAP_HI        EQU 2 ; high byte of the fall speed from which it stops growing (the speed ends at $021C)
DYING_RISE               EQU 0x80 ; how far the dying monk rises per frame, 8.8 (one pixel)
WALK_ANIM_PERIOD         EQU 8 ; frames the walking monk keeps one animation frame
DYING_ANIM_PERIOD        EQU 4 ; frames each frame of the dying animation lasts
DYING_LAST_FRAME         EQU 7 ; first frame of the dying animation that is not drawn (frames 0-6 are; frame 7 lasts 4 frames, frame 8 ends the death)
MONK_HEIGHT              EQU 12 ; height of the standing monk sprite in 2-pixel units (24 pixels)
CROUCH_HEIGHT            EQU 8 ; height of the crouching monk sprite in 2-pixel units (16 pixels)
SFX_JUMP                 EQU 2 ; sound effect: the monk jumps
SFX_DEATH                EQU 6 ; sound effect: the monk dies
STATE_DEATH              EQU 0x84 ; room state 4 with STATE_RUNNING: restart at the active checkpoint after a death (SelectCheckpoint, then as 2); UpdateDying_End makes it $85 (Game Over) when no life is left
STATE_ENTER_ROOM         EQU 1 ; room state: enter the room whose number is in $8509
EXIT_RIGHT               EQU 0 ; exit direction: through the right edge (not used: LeaveRight stores it with XOR A)
EXIT_LEFT                EQU 1 ; exit direction: through the left edge
EXIT_DOWN                EQU 2 ; exit direction: through the bottom edge
EXIT_UP                  EQU 3 ; exit direction: through the top edge
ROOM_WIDTH_2PX           EQU 0x80 ; width of the room in 2-pixel units (32 cells of 4)
TILE_ROPE                EQU 0xB7 ; tile number of the dotted vertical rope of the hanged men (one pixel column at the left edge of the cell, red ink)
TILE_BLANK               EQU 0x80 ; tile number of the empty tile (all zero bitmap)
DROP_PERIOD              EQU 0x46 ; frames from one fall of a water drop to the next (also the countdown reload of its slot)
DROP_SWELL               EQU 0x1E ; countdown value at which a hanging water drop switches to its second frame, 30 frames before it falls
ARCHER_AIM_TIME          EQU 0x1E ; shooter countdown value at which an archer or the stone head switches to its aiming frame (30 frames before the shot)
PLANT_SPIT_TIME          EQU 0x32 ; countdown value at which a plant of room 14 opens and spits its two seeds
BEAST_HEAD_DIP           EQU 0x28 ; the head of the Pestilent Beast is lowered by 2 units while its counter is at or below this
PROJECTILE_Y_MAX         EQU 0x60 ; a projectile whose y (2-pixel units) reaches this is below the room and is removed (the room is 22 rows of 4 units, ROOM_HEIGHT_2PX)
SEED_GRAVITY             EQU 0x14 ; added to the vertical speed of a plant's seed every frame (8.8)
FISH_GRAVITY             EQU 0x16 ; added to the vertical speed of a jumping fish every frame (8.8)
FISH_JUMP_SPEED          EQU 0xFDAE ; vertical speed a fish starts its jump with (8.8, -2.32 units per frame, upwards)
FISH_JUMP_Y              EQU 0x4C7C ; y of a fish at the start of its jump (8.8, high byte in 2-pixel units)
FISH_JUMP_TIME           EQU 0x36 ; countdown value at which a fish waiting under the water jumps
WATER_Y                  EQU 0x50 ; y (2-pixel units) of the water surface of rooms 16 and 19, where splashes appear
TILE_BLOOD_A             EQU 0x3B ; tile number of the bubbling blood, first phase (swapped with TILE_BLOOD_B by AnimateBloodTiles)
TILE_BLOOD_B             EQU 0x3C ; tile number of the bubbling blood, second phase
TILE_RING_CROSS          EQU 0x4C ; tile number of the red crosses of the ring of twelve crosses in Satan's room
CROSS_FLASH_PERIOD       EQU 5 ; passes of the main loop (drawn frames, not interrupts: 8-9 frames in room 24, F117) between two steps of the ring of crosses (CrossFlashTimer reload)
CROSS_COLOURS            EQU 6 ; attributes in the colour cycle of the ring of crosses (CrossColours)
BLOOD_ANIM_PERIOD        EQU 2 ; passes of the main loop (drawn frames, not interrupts, F116) between two swaps of the blood tiles (BloodAnimTimer reload)
COLUMN_MASK              EQU 0x1F ; mask of a cell column number (0-31)
PAGING_BANK0             EQU 0x10 ; value for port $7FFD: RAM bank 0 at $C000, ROM 1 (48K BASIC), normal screen: the paging state of the game
SPEAKER_BIT              EQU 0x10 ; bit 4 of port $FE: the speaker (EAR output); the beeper effects toggle it
STATE_RUNNING            EQU 0x80 ; room state bit 7: the frame routines run the game logic (with the low 7 bits 0 the main loop plays)
MUSIC_TRACK_TITLE        EQU 3 ; music track 3: the title and the controls menu
MUSIC_TRACK_ENDING1      EQU 5 ; music track 5: first part of the ending (room 25)
MUSIC_TRACK_ENDING2      EQU 2 ; music track 2: second part of the ending (the pyre, room 4)
ROOM_ENDING              EQU 25 ; room number of the first scene of the ending (outside the 5x5 grid)
ROOM_PYRE                EQU 4 ; room number of the second scene of the ending: the burning of Jean at the stake
OBJECT_SLOTS             EQU 11 ; object slots at $C100
ROOM_ITEM_SIZE           EQU 8 ; bytes of a room item record (table at $8EDF)
ROOM_OBJECT_SIZE         EQU 11 ; bytes of a room object record (table at $8B8F)
SFX_SIZE                 EQU 8 ; bytes of a sound effect record
NOISE_SAMPLES            EQU 0x30 ; speaker samples per frame of the noise effect
NOISE_FRAMES             EQU 10 ; frames the noise effect lasts
BURST_COUNTS             EQU 0xFF ; loop counts in the tone burst of one frame of a sound effect
CYAN                     EQU 5 ; colour: cyan
PAGE_REDRAW_LENGTHS      EQU 0xC3 ; high byte of the redraw cell buffer holding the run length of each run's first cell
JOB_SIZE                 EQU 0x10 ; bytes of a draw queue job at $C000 (16 jobs)
FLAG_SPRITE              EQU 0x40 ; tile flag bit 6: a sprite covers the cell this frame (becomes the redraw bit 7 for the next frame, to erase it)
THIRD_MASK               EQU 0x18 ; mask of the screen third bits in the high byte of a screen address
PIXEL_ROW_PAIRS          EQU 4 ; pairs of pixel rows (a cell has 8) copied by the redraw loop
CTRL_MOVES               EQU 0x1F ; control bits 0-4: right, left, crouch and jump; any of them ends the intro
CRUSADER_PERIOD          EQU 40 ; frames between two crusaders made by the spawner of rooms 5, 6 and 25
CRUSADER_JUMP_FRAMES     EQU 6 ; frames of a crusader's jump along a speed curve (also the number of values of a curve)
CRUSADER_STEP_SPEED      EQU 0x00A0 ; x speed of a crusader during a step up (8.8: 0.625 units a frame)
CRUSADER_HOP_SPEED       EQU 0x0150 ; x speed of a crusader during a hop (8.8: 1.3 units a frame)
