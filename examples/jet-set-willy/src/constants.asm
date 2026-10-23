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
ENTITY_TYPE_MASK         EQU 0x07 ; entity byte 0 bits 0-2: entity type, which selects the drawing code
ENTITY_MOVE_MASK         EQU 0x03 ; bits of the entity type the movement routine tells apart (type 4 reads as 0 there and is not moved)
ENTITY_HORIZONTAL        EQU 1 ; entity type 1: guardian that walks left and right along a row
ENTITY_VERTICAL          EQU 2 ; entity type 2: guardian that moves up and down a column
ENTITY_ROPE              EQU 3 ; entity type 3: swinging rope
ENTITY_ARROW             EQU 4 ; entity type 4: arrow that flies across the room
ENTITY_DIR_BIT           EQU 7 ; entity byte 0 bit 7: direction (arrow, horizontal guardian: 1 = right; rope: swing direction)
ENTITY_PHASE_STEP        EQU 0x20 ; one animation phase in entity byte 0 (the phase is in bits 5-6 or 5-7)
ENTITY_FRAME_MASK        EQU 0xE0 ; entity bytes 0-2: bits 5-7 pick the sprite frame (frame number times 32 is the sprite offset)
ENTITY_GO_RIGHT          EQU 0x81 ; entity byte 0 of a horizontal guardian that has just turned right: type 1, direction right, phase 0
ENTITY_GO_LEFT           EQU 0x61 ; entity byte 0 of a horizontal guardian that has just turned left: type 1, direction left, phase 3
COLUMN_MASK              EQU 0x1F ; bits 0-4: screen column 0-31
ROPE_FREE                EQU 0 ; state of the rope variable at #R$85D6: Willy holds no rope
ROPE_LET_GO              EQU 0xF0 ; rope variable value after Willy leaves a rope: counts up by 1 per rope pass until it wraps to 0, so he cannot grab a rope for 16 passes
ROPE_MIN_SEGMENT         EQU 0x0C ; lowest segment Willy can climb to when the up exit of the room is the room itself
ARROW_BEEP_LEFT          EQU 0x2C ; arrow X at which a left-moving arrow sounds its beep (13 passes before it reaches column 31)
ARROW_BEEP_RIGHT         EQU 0xF4 ; arrow X at which a right-moving arrow sounds its beep (12 passes before it reaches column 0)
ARROW_BEEP_COUNT         EQU 0x80 ; number of speaker toggles in the arrow beep (delays 2, then 128 down to 2)
PIXEL_LEFT               EQU 0x80 ; bit mask of the leftmost pixel of a byte
PAPER_MASK               EQU 0x38 ; attribute bits 3-5: paper colour
DRAW_COLLIDE             EQU 1 ; DrawSprite mode (value of C): draw with collision test, stop at the first overlapping pixel
ENTITY_ATTR_MASK         EQU 0x0F ; entity byte +1 bits 0-3: ink (bits 0-2) and bright (bit 3) of the sprite
KEYROW_CS_V              EQU 0xFEFE ; port that reads CAPS SHIFT Z X C V (bit 0 = CAPS SHIFT, 0 = pressed)
KEYROW_SPACE_B           EQU 0x7FFE ; port that reads SPACE SYMBOL-SHIFT M N B (bit 0 = SPACE, 0 = pressed)
KEYROW_A_G_HI            EQU 0xFD ; high byte of the port that reads A S D F G (the pause keys)
KEYROW_NOT_A_G_HI        EQU 0x02 ; high byte of a port that reads every half row except A-G (a zero bit selects a row: bit 1 is the A-G row)
KEYROW_Q_T               EQU 0xFBFE ; port that reads Q W E R T (bit 0 = Q ... bit 4 = T, 0 = pressed)
KEYROW_P_Y               EQU 0xDFFE ; port that reads P O I U Y (bit 0 = P ... bit 4 = Y, 0 = pressed)
KEYROW_0_9               EQU 0xEFFE ; port that reads 0 9 8 7 6 (bit 0 = 0 ... bit 4 = 6, 0 = pressed)
KEYROW_H_ENTER           EQU 0xBFFE ; port that reads H J K L ENTER (bit 0 = ENTER, bit 4 = H, 0 = pressed)
KEYS_MASK                EQU 0x1F ; the five key bits of a half row read
NO_KEYS                  EQU 0x1F ; half row read (masked with KEYS_MASK) with no key pressed
KEY_9_BIT                EQU 1 ; bit of the 0-9 half row that is key 9
KEY_6_BIT                EQU 4 ; bit of the 0-9 half row that is key 6
KEY_6_ROOM_BIT           EQU 0x20 ; teleport cheat: key 6 adds 32 to the room number (keys 1-5 add 1, 2, 4, 8, 16)
ROOM_ATTRS_SIZE          EQU 0x200 ; bytes of attributes of the room area (screen rows 0-15)
ROOM_BITMAP_SIZE         EQU 0x1000 ; bytes of bitmap of the room area (the top two thirds of the screen)
WILLY_Y_ABOVE_TOP        EQU 0xE1 ; Willy Y index from which he has gone above the top of the room (Y is unsigned and wraps below 0)
WILLY_KILLED             EQU 0xFF ; value of the Willy air/death state byte (85D1) that means Willy has been killed
ASCII_ONE                EQU 0x31 ; ASCII code of the digit 1
ASCII_THREE              EQU 0x33 ; ASCII code of the digit 3
ASCII_SIX                EQU 0x36 ; ASCII code of the digit 6
ASCII_SPACE              EQU 0x20 ; ASCII code of the space
ASCII_P                  EQU 0x70 ; ASCII code of the letter p
CLOCK_HOURS_TENS         EQU 0 ; offset in the clock text: tens digit of the hour (blank or 1)
CLOCK_HOURS_UNITS        EQU 1 ; offset in the clock text: units digit of the hour
CLOCK_MINUTES_TENS       EQU 3 ; offset in the clock text: tens digit of the minutes
CLOCK_MINUTES_UNITS      EQU 4 ; offset in the clock text: units digit of the minutes
CLOCK_AM_PM              EQU 5 ; offset in the clock text: letter a or p
CLOCK_LENGTH             EQU 6 ; characters of the clock text
ITEM_DIGITS              EQU 3 ; digits of the items collected count
CHEAT_ACTIVE             EQU 10 ; value of the cheat progress byte when the whole key sequence has been typed
TUNE_LENGTH_MASK         EQU 0x7E ; mask that turns the tune step counter into twice the note index (64 notes, 2 passes each)
LIVES_FULL_PITCH         EQU 0x1C ; 4 * START_LIVES: the tune note gets 0x1C - 4 * lives added, so it is unchanged with a full set of lives
LIFE_FRAME_MASK          EQU 0x60 ; mask of the animation frame offset (0, 0x20, 0x40, 0x60) of the Willy sprites shown as lives
WILLY_SPRITE_PAGE        EQU SpriteWillyRight0>>8 ; high byte of the Willy sprite page (right-facing frames at 0x9D00, left-facing at 0x9D80)
TUNE_BEEP_LOOPS          EQU 3 ; outer loops of 256 beeper writes per note blip in the game
FLASH_START_ATTR         EQU 0x47 ; first colour of the death flash: bright, white ink, black paper
FLASH_END_ATTR           EQU 0x3F ; value after the last colour of the death flash (ink 0, bright) is passed
GAME_OVER_STEPS          EQU 0xC4 ; game over: the foot position counter stops here (steps of 4, 49 steps)
GAME_OVER_BARREL_INK     EQU 2 ; game over: ink (red) of the barrel cells
THIRD_ATTRS_SIZE         EQU 0x100 ; bytes of attributes of one third of the screen (8 character rows)
ROOM_FIRST_LANDING       EQU 0x1C ; room number of First Landing, where the cheat sequence is typed
CHEAT_Y                  EQU 0xD0 ; Willy Y index required to type the cheat sequence (standing on the lowest floor)
Y_ROW_MASK               EQU 0xF0 ; Willy Y index bits that select the character row (16 Y units per row, 2 per pixel row)
Y_ROW_STEP               EQU 0x10 ; Y index units in one character row (8 pixel rows)
Y_FALL_STEP              EQU 8 ; Y index units Willy falls per pass (4 pixel rows)
Y_BETWEEN_MASK           EQU 0x0E ; Y index bits that are non-zero while Willy is between two character rows (jump or fall in progress)
JUMP_APEX_STEP           EQU 8 ; jump step at which the arc is highest: the Y change of a pass is (step AND $FE) - 8 index units
JUMP_LAND_FIRST          EQU 0x0D ; jump step after which Willy may land on ground two rows above his take-off row
JUMP_LAND_SECOND         EQU 0x10 ; jump step after which Willy may land on ground one row above his take-off row
JUMP_END_STEP            EQU 0x12 ; jump step (18 passes) at which the jump ends in a fall
AIR_ON_GROUND            EQU 0 ; Willy air state: standing or walking on ground (or holding a rope)
AIR_JUMPING              EQU 1 ; Willy air state: in the arc of a jump (the step is in WillyJumpStep)
AIR_FALL_START           EQU 2 ; Willy air state: first state of a fall; the state counts up once per pass of the fall
AIR_FALL_AFTER_JUMP      EQU 6 ; Willy air state at the end of a jump: a fall that counts as already four passes old
AIR_FATAL_FALL           EQU 0x0C ; Willy air state from which a landing kills him (a fall of 5 character rows or more from standing)
AIR_FALL_WRAP            EQU 0x10 ; fall state that wraps back to AIR_FATAL_FALL, so a long fall cycles through 12-15
STEP_SOUND_TOGGLES       EQU 0x20 ; speaker toggles of the click played in every pass of a jump or fall
WALK_LAST_FRAME          EQU 3 ; last frame of Willy's 4-frame walk cycle: he moves one cell when the cycle wraps
KEYBITS_LEFT             EQU 0x2A ; bits of the key-bit byte that mean left (keys Q E T U O 5 6, joystick left, conveyor left): bits 1, 3, 5
KEYBITS_RIGHT            EQU 0x15 ; bits of the key-bit byte that mean right (keys W R Y I P 7 8, joystick right, conveyor right): bits 0, 2, 4
STATE_ROW_LEFT           EQU 4 ; offset of the left row in the move state table (index = old state + 4 * left + 8 * right)
STATE_ROW_RIGHT_BIT      EQU 3 ; bit of the move state table index set when a right key is down (adds 8)
MOVE_FACING_LEFT         EQU 1 ; bit mask of WillyMoveState: 1 = facing left (and walking left when the walk bit is set)
MOVE_WALK_BIT            EQU 1 ; bit number in WillyMoveState: 1 = Willy walks this pass
MOVE_WALK_MASK           EQU 2 ; bit mask of WillyMoveState: Willy walks this pass
ENDING_AUTORUN_BIT       EQU 1 ; bit of EndingStage set in stages 2 and 3: the right key is forced on and the jump key is ignored
KEYROWS_5_6_HI           EQU 0xE7 ; high byte of the port that reads half rows 1-5 and 6-0 together (a zero bit selects the row)
KEYROWS_BOTTOM           EQU 0x7EFE ; port that reads half rows CAPS SHIFT-V and B-SPACE together: the jump keys
KEMPSTON_LR_MASK         EQU 3 ; Kempston bits 0 (right) and 1 (left)
KEY_0_BIT                EQU 0 ; bit of the 0-9 half row that is key 0
Y_WRAPPED_MIN            EQU 0xF0 ; smallest Y index after a rise that means Willy has gone above the top of the room (Y wrapped below 0)
CODE_PAPER_MASK          EQU 3*PAPER ; paper bits of a code slot colour after subtracting blue: 0-3 in bits 4-3
FLASH                    EQU 0x80 ; attribute bit 7: flash
WILLY_STATE_SIZE         EQU 7 ; bytes of Willy's state (Y, move state, air state, frame, attribute address, jump step) saved at room entry and restored after a death
COLOUR_CYCLE_STEP        EQU 3 ; colour added to ink and paper in each step of the screen colour cycle
SCROLL_PITCH_MASK        EQU 0x1F ; title scroll: the position in the message modulo 32 gives the pitch of the sound
SCROLL_PITCH_BASE        EQU 0x32 ; title scroll: smallest pitch value of the sound
DEBOUNCE_LOOPS           EQU 24 ; outer loops of 256 DJNZ passes of the colour-code key debounce (about 23 ms)
GAME_OVER_COLUMN         EQU 15 ; game over: screen column of Willy, the barrel and the falling foot
GAME_OVER_STEP           EQU 4 ; game over: counter step of the foot per pass (2 pixel rows)
GAME_OVER_TOGGLES        EQU 64 ; game over: speaker toggles of the whistle in each step
GAME_OVER_WORD_LEN       EQU 4 ; game over: letters of each of the words Game and Over
GAME_OVER_FLASH_LOOPS    EQU 6 ; game over: outer loops of 256 DJNZ passes per colour step of the letters
KEYBITS_NONE             EQU 0xFF ; key-bit byte with no direction key pressed (0 = pressed)
KEYBITS_PAD_P            EQU 0x20 ; bit 5 of the key-bit byte: not a key in the P O I U Y row, forced to 1 (the left keys use it later)
KEYROW_0_9_HI            EQU (KEYROW_0_9>>8) ; high byte of the port that reads 0 9 8 7 6
KEY_8_BIT                EQU 2 ; bit of the 0-9 half row that is key 8 (key 7 is bit 3 and reaches bit 2 after a rotate)
HI_BYTE                  EQU 256 ; multiplier that puts a value in the high byte of a register pair (B*HI_BYTE+C)
ENT_TYPE                 EQU 0 ; entity byte 0: type, animation phase and direction
ENT_ATTR                 EQU 1 ; entity byte 1 (guardian): ink and bright of the sprite, frame mask
ENT_SWING                EQU 1 ; entity byte 1 (rope): swing position, bit 7 = side, bits 0-6 = distance
ENT_COLUMN               EQU 2 ; entity byte 2 (guardian, rope): screen column, bits 5-7 frame offset (rope: column of the top)
ENT_ARROW_Y              EQU 2 ; entity byte 2 (arrow): Y index of the centre row
ENT_Y                    EQU 3 ; entity byte 3 (guardian): Y index
ENT_ROPE_COLUMN          EQU 3 ; entity byte 3 (rope): scratch, column of the current rope point
ENT_STEP                 EQU 4 ; entity byte 4 (vertical guardian): signed Y step per pass
ENT_ARROW_X              EQU 4 ; entity byte 4 (arrow): X column
ENT_ROPE_LENGTH          EQU 4 ; entity byte 4 (rope): length in segments
ENT_PAGE                 EQU 5 ; entity byte 5 (guardian): high byte of the sprite page
ENT_ARROW_MASK           EQU 5 ; entity byte 5 (arrow): scratch, collision mask
ENT_ROPE_MASK            EQU 5 ; entity byte 5 (rope): scratch, pixel mask of the current rope point
ENT_LIMIT_LOW            EQU 6 ; entity byte 6: left end of the beat (horizontal guardian) or top limit (vertical guardian)
ENT_ARROW_FINS           EQU 6 ; entity byte 6 (arrow): pixel pattern of the fins
ENT_LIMIT_HIGH           EQU 7 ; entity byte 7: right end of the beat (horizontal guardian), bottom limit (vertical guardian) or swing limit (rope)
ROPE_SEGMENT             EQU 9 ; rope: segment counter, byte 1 of the entry after the rope (ENT_SIZE+1)
ROPE_HELD                EQU 11 ; rope: byte 3 of the entry after the rope; bit 0 = this rope holds Willy
ROPE_SIDE_LEFT           EQU 0x80 ; rope swing position bit 7: leaning left (also the value of distance 0 on the left side)
ROPE_DIST_MASK           EQU 0x7F ; rope swing position bits 0-6: distance from hanging straight
ROPE_STEP                EQU 2 ; swing distance change per half step; the rope takes two half steps near the middle
ROPE_FAST_DOWN           EQU 0x14 ; swing distance after the first step below which a moving-to-middle rope takes a second step
ROPE_FAST_UP             EQU 0x12 ; swing distance after the first step below which a moving-from-middle rope takes a second step
ENTITY_LAST_PHASE        EQU 3 ; last animation phase of a guardian (phases 0-3)
ENTITY_V_FLIP            EQU 8 ; entity byte 0 bit 3 (vertical guardian): flips every pass
ENTITY_V_ANIM_MASK       EQU 0x18 ; entity byte 0 bits 3-4 (vertical guardian): the phase goes up when either is set after the flip
Y_LOWER_HALF             EQU 0x80 ; Y index bit 7: set in the lower half of the room (character rows 8-15)
Y_SNAP_MASK              EQU 0xF8 ; mask that rounds a Y index down to a multiple of 8 (4 pixel rows)
Y_LOW_FLOOR              EQU 0xD0 ; Y index of the lowest floor (pixel row 104, character row 13)
ANIM_FRAME_MASK          EQU 3 ; bits 0-1 of an animation frame (Willy's 4 frames per direction)
THIRD_PAGES              EQU (THIRD_SIZE>>8) ; high-byte step between the thirds of the bitmap (and between the halves of the room buffers)
ITEM_BEEP_START          EQU 0x80 ; pick-up beep: first value of the counter C (steps down by 2 to 2)
ITEM_BEEP_DELAY          EQU 0x90 ; pick-up beep: delay B = ITEM_BEEP_DELAY - C, so the pitch falls
ITEM_COLOURS             EQU 4 ; colours an item cycles through (magenta, green, cyan, yellow)
FIGURE_ROW               EQU 11 ; Master Bedroom: character row of the top of the figure sprite
FIGURE_COLUMN            EQU 14 ; Master Bedroom: character column of the figure sprite
ROOM_NIGHTMARE           EQU 0x1D ; room number of The Nightmare Room, where Willy is drawn with the flapper sprites
WILLY_FACING_HALF        EQU 0x80 ; offset of the right-facing half (frames 4-7) in a Willy sprite page
RAMP_OFFSET_MASK         EQU 0x0C ; bits of the ramp Y offset of the Willy sprite (0, 4, 8 or 12 index units)
TUNE_PASSES              EQU 100 ; passes of 256 inner iterations that one tune note lasts
TOILET_ROW               EQU 13 ; Bathroom: character row of the top of the toilet sprite (2 cells high)
