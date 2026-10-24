; Numeric constants (sizes, counts, colours, key masks, codes), used in
; the skool files through @isub. Add with: tools/zxq.py const NAME VALUE COMMENT
; Addresses (ROM, system variables, screen) are @equ lines in re/skool/head.skool.
BLACK                    EQU 0 ; colour: black
BLUE                     EQU 1 ; colour: blue
RED                      EQU 2 ; colour: red
WHITE                    EQU 7 ; colour: white
PAPER                    EQU 8 ; attribute multiplier of the paper colour (ink colour is the low 3 bits)
BRIGHT                   EQU 0x40 ; attribute bit 6: bright
OP_RET                   EQU 0xC9 ; opcode of RET, stored over a NOP to switch a one-shot routine off
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
FLAG_HARMFUL             EQU 4 ; tile flag value of a cell that hurts the monk (observed: the lake of room 16)
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
OP_FIRST                 EQU 0x80 ; script codes from here are commands, below it characters
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
LEVER_STATE_MASK         EQU 7 ; lever flag bits that tell the lever state (0 off, 6 on)
LEVER_ON                 EQU 6 ; value of the lever state bits of the lever at $851E when it is on
STATE_RESPAWN            EQU 2 ; room state: respawn at the checkpoint position ($8512/$8514)
STATE_ENDING             EQU 3 ; room state: ending sequence ($887B)
STATE_GAME_OVER          EQU 5 ; room state: Game Over screen ($A57E)
SFX_TRIGGER              EQU 3 ; sound effect: bell or lever touched once ($A748)
SFX_PORTAL               EQU 4 ; sound effect: passage between rooms 10 and 19
SFX_PICKUP               EQU 5 ; sound effect: item taken, lever pulled, key accepted in the menu
SFX_DOOR                 EQU 8 ; sound effect: the church door rattles
SFX_CHECKPOINT           EQU 9 ; sound effect: checkpoint touched
ROOM_BEAST               EQU 10 ; room number of Pestilent Beast (the dragon room)
ROOM_RIVER               EQU 19 ; room number of Underground river
ROW_TABLE_ENTRIES        EQU 24 ; words in the flag map row address table at $6100 (22 room rows and 2 spare)
ATTACK_PERIOD            EQU 0x32 ; frames between two throws of Death or two volleys of Satan (the timer reloads with it)
SFX_ENEMY_SHOT           EQU 7 ; sound effect: Death throws a scythe, Satan fires
OBJECT_ENTRY_SIZE        EQU 4 ; bytes of an entry of the object list at $5DC0: template address, y, x
TILE_CLASS_MASK          EQU 7 ; mask of the tile class in a tile flag (bits 0-2)
MUSIC_TRACK_7            EQU 7 ; music track 7 (also set by the Game Over code at $86AB)
PLAYER_DYING             EQU 1 ; player state: dying
PLAYER_STANDING          EQU 4 ; player state: standing or walking
OP_CALL                  EQU 0xCD ; opcode of CALL, stored over the first byte of a 3-byte instruction to turn it into a call
OP_JP                    EQU 0xC3 ; opcode of JP
GRID_ROOMS               EQU 25 ; rooms of the 5x5 map: a room number wraps modulo this (room 25 is the ending room outside the grid)
