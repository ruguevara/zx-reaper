; Numeric constants (sizes, counts, colours, key masks, codes), used in
; the skool files through @isub. Add with: tools/zxq.py const NAME VALUE COMMENT
; Addresses (ROM, system variables, screen) are @equ lines in re/skool/head.skool.
SPRITE_HEIGHT            EQU 16 ; sprite height in pixel rows (sprites are 16x16, 2 bytes per row)
CELL_HEIGHT              EQU 8 ; pixel rows in a character cell
TILE_SIZE                EQU 9 ; bytes per room tile: attribute + 8 pixel rows
TILE_COUNT               EQU 6 ; tiles in a room definition
ULA_PORT                 EQU 0xFE ; ULA port: border, MIC, speaker out; keyboard in
KEMPSTON_PORT            EQU 0x1F ; Kempston joystick port
BEEPER_BITS              EQU 0x18 ; port FE bits 3 (MIC) and 4 (speaker) toggled together to make sound
KEMPSTON_FIRE_BIT        EQU 4 ; Kempston fire button bit
ENTITY_SIZE              EQU 8 ; bytes per entity buffer entry
ENTITY_END               EQU 0xFF ; end marker of the entity buffer
TUNE_END                 EQU 0xFF ; tune data terminator byte
SCREEN_COLS              EQU 32 ; character columns per screen row (also attribute cells per row)
PAPER                    EQU 8 ; attribute multiplier for the paper colour
BLUE                     EQU 1 ; Spectrum colour 1
RED                      EQU 2 ; Spectrum colour 2
MAGENTA                  EQU 3 ; Spectrum colour 3
GREEN                    EQU 4 ; Spectrum colour 4
ATTR_INK_CLEAR           EQU 0xF8 ; attribute mask that keeps paper, bright and flash and clears the ink
SCREEN_AND_ATTRS_SIZE    EQU 0x1B00 ; bytes of bitmap plus attributes
KEYROW_1_5               EQU 0xF7FE ; port to read keys 1-5 (bit 0 = key 1 ... bit 4 = key 5, 0 = pressed)
KEYROW_H_ENTER_HI        EQU 0xBF ; high byte of the port that reads H J K L ENTER (ENTER = bit 0)
KEYS_1_4_MASK            EQU 0x0F ; bits of the 1-5 half row that are keys 1-4
KEY_1_ONLY               EQU 0x0E ; 1-5 half row masked with 0F: only key 1 down
KEY_2_ONLY               EQU 0x0D ; 1-5 half row masked with 0F: only key 2 down
KEY_3_ONLY               EQU 0x0B ; 1-5 half row masked with 0F: only key 3 down
KEY_4_ONLY               EQU 0x07 ; 1-5 half row masked with 0F: only key 4 down
CODE_GRID_COLS           EQU 18 ; columns (A-R) of the colour-code grid
CODE_GRID_CELLS          EQU 180 ; cells of the colour-code grid (18 columns x 10 rows)
CODE_GRID_STEP           EQU 0x25 ; added to FRAMES before each colour-code attempt to pick the grid cell
CODE_SLOT_1_ATTR         EQU 0x5950 ; attribute address of the first colour slot of the code screen (2x2 cells)
CODE_SLOT_2_ATTR         EQU 0x5953 ; attribute address of the second colour slot
CODE_SLOT_3_ATTR         EQU 0x5956 ; attribute address of the third colour slot
CODE_SLOT_4_ATTR         EQU 0x5959 ; attribute address of the fourth colour slot
CODE_SLOT_SPACING        EQU 3 ; attribute columns between colour slots
CODE_SLOT_END            EQU 0x5C ; low byte of the attribute address after the last colour slot (0x595C)
CODE_SLOT_EMPTY          EQU 7 ; attribute of an empty colour slot (white ink, black paper, no pixels)
CODE_KEY_SIZE            EQU 32 ; bytes per code-screen key graphic (16x16 pixels)
ATTRS_SIZE               EQU 0x300 ; bytes of screen attributes
ITEM_PRESENT             EQU 0x40 ; item table bit 6: item still in the game (not collected)
INK_MASK                 EQU 7 ; attribute bits 0-2: ink colour
WHITE                    EQU 7 ; colour code white (ink 7 is Willy's ink; touching it collects an item)
ASCII_ZERO               EQU 0x30 ; ASCII code of the digit 0
ASCII_AFTER_NINE         EQU 0x3A ; ASCII code after the digit 9 (the digit overflows)
CELLS_PER_BYTE           EQU 4 ; room layout cells packed per byte (2 bits each)
ROOM_LAYOUT_SIZE         EQU 0x80 ; bytes of room layout
START_ROOM               EQU 0x21 ; room where a new game starts (the Bathroom)
START_LIVES              EQU 7 ; lives at the start of a game
WILLY_START_Y            EQU 0xD0 ; Willy start Y at a new game (pixel row index, standing on the Bathroom floor)
WILLY_START_ATTR         EQU 0x5DB4 ; start address of Willy's attribute cell in the attribute buffer at a new game
ITEM_PRESENT_BIT         EQU 6 ; bit number of the item-present flag in the item table
BRIGHT                   EQU 0x40 ; attribute bit 6
YELLOW                   EQU 6 ; Spectrum colour 6
KEMPSTON_UNUSED_MASK     EQU 0x20 ; bit 5 of the Kempston port: always 0 on a real interface, set by some floating-bus reads
KEYROW_START             EQU 0xAFFE ; port that reads half-rows 6-0 and H-ENTER together: bit 0 = key 0 or ENTER (0 = pressed)
TITLE_SCROLL_STEPS       EQU 0xE0 ; steps of the title message scroll (message length 256 - window 32)
ROOM_TABLE_PAGE          EQU 0xC0 ; high byte of the room table (room N is at ROOM_TABLE_PAGE*256 + 256*N)
ROOM_SLOTS               EQU 8 ; entity slots per room
BITMAP_SIZE              EQU 0x1800 ; bytes of the screen bitmap
THIRD_SIZE               EQU 0x800 ; bytes of bitmap in one third of the screen (8 character rows)
ROOM_SIZE                EQU 0x100 ; bytes per room in the room table and in the room buffer
BRIGHT_WHITE_ON_BLUE     EQU 0x4F ; attribute of the scrolling title message line
ROOM_BATHROOM            EQU 0x21 ; room number of The Bathroom
ROOM_MASTER_BEDROOM      EQU 0x23 ; room number of the Master Bedroom
STAGE_PLAYING            EQU 0 ; EndingStage 0: normal play, not every item collected
STAGE_ALL_ITEMS          EQU 1 ; EndingStage 1: every item collected
STAGE_RUN_TO_TOILET      EQU 2 ; EndingStage 2: Willy reached the bed end of the Master Bedroom; he now runs right by himself and cannot jump
STAGE_AT_TOILET          EQU 3 ; EndingStage 3: Willy is at the toilet in the Bathroom; he is no longer moved, drawn or checked
BED_END_COLUMN           EQU 6 ; Master Bedroom: Willy in a column below this (the bed end) starts the run to the toilet
TOILET_COLUMN            EQU 28 ; Bathroom: screen column of the toilet sprite (2 cells wide)
TOILET_ATTR_LOW          EQU 0xBC ; low byte of Willy's attribute address (DBC: row 13, column 28) when he is at the toilet
CYAN                     EQU 5 ; Spectrum colour 5
BEDROOM_FLOOR_Y          EQU 0xD0 ; Willy Y index on the lowest floor (pixel row 104); selects the guard figure's walking frames
BEDROOM_MID_Y            EQU 0xC0 ; Willy Y index below which the guard figure uses its last frame
Y_CELL_MASK              EQU 0x0F ; Y index bits within a character row (16 units per row): non-zero when Willy is between rows
