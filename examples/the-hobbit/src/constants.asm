; Numeric constants (sizes, counts, colours, key masks, codes), used in
; the skool files through @isub. Add with: tools/zxq.py const NAME VALUE COMMENT
; Addresses (ROM, system variables, screen) are @equ lines in re/skool/head.skool.
; Location, object and character ids and directions: re/ids.md.
LOC_TUNNEL_LIKE_HALL     EQU $01 ; tunnel like hall
LOC_FOREST_ROAD_02       EQU $02 ; forest road
LOC_FOREST               EQU $03 ; forest
LOC_LONELANDS            EQU $04 ; lonelands
LOC_TROLLS_CLEARING      EQU $05 ; trolls clearing
LOC_TROLLS_PATH          EQU $06 ; trolls path
LOC_TROLLS_CAVE          EQU $07 ; trolls cave
LOC_RUNNING_RIVER_08     EQU $08 ; running river
LOC_RIVENDELL            EQU $09 ; rivendell
LOC_MISTY_MOUNTAIN       EQU $0A ; misty mountain
LOC_NARROW_PLACE         EQU $0B ; narrow place
LOC_DANGEROUS_NARROW_PAT EQU $0C ; dangerous narrow path
LOC_GOBLINS_DUNGEON      EQU $0D ; goblins dungeon
LOC_LARGE_DRY_CAVE       EQU $0E ; large dry cave
LOC_DARK_STUFFY_PASSA_0F EQU $0F ; dark stuffy passage
LOC_BIG_GOBLINS_CAVERN   EQU $10 ; big goblins cavern
LOC_DEEP_DARK_LAKE       EQU $11 ; deep dark lake
LOC_DARK_WINDING_PASSAGE EQU $12 ; dark winding passage
LOC_INSIDE_GOBLINS_GATE  EQU $13 ; inside goblins gate
LOC_OUTSIDE_GOBLINS_GATE EQU $14 ; outside goblins gate
LOC_TREELESS_OPENING     EQU $15 ; treeless opening
LOC_BEORNS_HOUSE         EQU $16 ; beorns house
LOC_FORESTRIVER_17       EQU $17 ; forestriver
LOC_FOREST_GATE          EQU $18 ; forest gate
LOC_BEWITCHED_GLOOMY_PLA EQU $19 ; bewitched gloomy place
LOC_SPIDER_THREADS_PLACE EQU $1A ; spider threads place
LOC_SMOTHERING_FOREST    EQU $1B ; smothering forest
LOC_LEVELLED_ELVISH_CLEA EQU $1C ; levelled elvish clearing
LOC_DEEP_BOG             EQU $1D ; deep bog
LOC_ELVENKINGS_GREAT_HAL EQU $1E ; elvenkings great halls
LOC_DARK_DUNGEON         EQU $1F ; dark dungeon
LOC_ELVENKINGS_CELLAR    EQU $20 ; elvenkings cellar
LOC_FORESTRIVER_21       EQU $21 ; forestriver
LOC_LONG_LAKE            EQU $22 ; long lake
LOC_LAKE_TOWN            EQU $23 ; lake town
LOC_RUNNING_RIVER_24     EQU $24 ; running river
LOC_DRAGONS_DESOLATION   EQU $25 ; dragons desolation
LOC_DALE_VALLEY          EQU $26 ; dale valley
LOC_FRONT_GATE           EQU $27 ; front gate
LOC_RAVENHILL            EQU $28 ; ravenhill
LOC_LOWER_HALLS          EQU $29 ; lower halls
LOC_SIDEDOOR             EQU $2A ; sidedoor
LOC_SMOOTH_STRAIGHT_PASS EQU $2B ; smooth straight passage
LOC_LONELY_MOUNTAIN      EQU $2C ; lonely mountain
LOC_WATERFALL            EQU $2D ; waterfall
LOC_FOREST_ROAD_2E       EQU $2E ; forest road
LOC_MOUNTAINS            EQU $30 ; mountains
LOC_GREAT_RIVER          EQU $31 ; great river
LOC_GREEN_FOREST         EQU $32 ; green forest
LOC_EM_PLACE             EQU $33 ; em place
LOC_DARK_STUFFY_PASSA_34 EQU $34 ; dark stuffy passage
LOC_DARK_STUFFY_PASSA_35 EQU $35 ; dark stuffy passage
LOC_DARK_STUFFY_PASSA_36 EQU $36 ; dark stuffy passage
LOC_DARK_STUFFY_PASSA_37 EQU $37 ; dark stuffy passage
LOC_DARK_STUFFY_PASSA_38 EQU $38 ; dark stuffy passage
LOC_DARK_STUFFY_PASSA_39 EQU $39 ; dark stuffy passage
LOC_DARK_STUFFY_PASSA_3A EQU $3A ; dark stuffy passage
LOC_DARK_STUFFY_PASSA_3B EQU $3B ; dark stuffy passage
LOC_DARK_STUFFY_PASSA_3C EQU $3C ; dark stuffy passage
LOC_DARK_STUFFY_PASSA_3D EQU $3D ; dark stuffy passage
LOC_DARK_STUFFY_PASSA_3E EQU $3E ; dark stuffy passage
LOC_DARK_STUFFY_PASSA_3F EQU $3F ; dark stuffy passage
LOC_DARK_STUFFY_PASSA_40 EQU $40 ; dark stuffy passage
LOC_DARK_STUFFY_PASSA_41 EQU $41 ; dark stuffy passage
LOC_WEST_BANK            EQU $42 ; west bank
LOC_EAST_BANK            EQU $43 ; east bank
LOC_NARROW_PATH_44       EQU $44 ; narrow path
LOC_NARROW_PATH_45       EQU $45 ; narrow path
LOC_NARROW_PATH_46       EQU $46 ; narrow path
LOC_NARROW_PATH_47       EQU $47 ; narrow path
LOC_NARROW_PATH_48       EQU $48 ; narrow path
LOC_NARROW_PATH_49       EQU $49 ; narrow path
LOC_NARROW_PATH_4A       EQU $4A ; narrow path
LOC_STEEP_PATH_4B        EQU $4B ; steep path
LOC_STEEP_PATH_4C        EQU $4C ; steep path
LOC_STEEP_PATH_4D        EQU $4D ; steep path
LOC_DEEP_MISTY_VALLEY_4E EQU $4E ; deep misty valley
LOC_DEEP_MISTY_VALLEY_4F EQU $4F ; deep misty valley
OBJ_HEAVY_ROCK_DOOR      EQU $01 ; heavy rock door
OBJ_SMALL_CURIOUS_KEY    EQU $02 ; small curious key
OBJ_CURIOUS_MAP          EQU $03 ; curious map
OBJ_LARGE_KEY            EQU $04 ; large key
OBJ_ROUND_GREEN_DOOR     EQU $05 ; round green door
OBJ_SMALL_INSIGNIFICANT  EQU $06 ; small insignificant crack
OBJ_SPIDER_WEB           EQU $07 ; spider web
OBJ_RED_DOOR             EQU $08 ; red door
OBJ_FAST_BLACK_RIVER     EQU $09 ; fast black river
OBJ_GOBLINS_BACK_DOOR    EQU $0A ; goblins back door
OBJ_MOUNTAINS_SIDE_DOOR  EQU $0B ; mountains side door
OBJ_LARGE_TRAP_DOOR      EQU $0C ; large trap door
OBJ_MAGIC_DOOR           EQU $0D ; magic door
OBJ_SHORT_STRONG_SWORD   EQU $0E ; short strong sword
OBJ_RED_KEY              EQU $0F ; red key
OBJ_VALUABLE_GOLDEN_RING EQU $10 ; valuable golden ring
OBJ_GOBLINS_DOOR         EQU $11 ; goblins door
OBJ_ROPE                 EQU $12 ; rope
OBJ_BARREL               EQU $13 ; barrel
OBJ_WINE                 EQU $14 ; wine
OBJ_WATER_15             EQU $15 ; water
OBJ_BLACK_WATER_16       EQU $16 ; black water
OBJ_WATER_17             EQU $17 ; water
OBJ_BLACK_WATER_18       EQU $18 ; black water
OBJ_BOW                  EQU $19 ; bow
OBJ_STRONG_ARROW         EQU $1A ; strong arrow
OBJ_WINDOW               EQU $1B ; window
OBJ_1C                   EQU $1C ; object $1C (name not decoded)
OBJ_SAND                 EQU $1D ; sand
OBJ_TRAP_DOOR            EQU $1E ; trap door
OBJ_GOBLINS_CACHE        EQU $1F ; goblins cache
OBJ_HEAVY_CURTAIN        EQU $20 ; heavy curtain
OBJ_LARGE_CUPBOARD       EQU $21 ; large cupboard
OBJ_FOOD                 EQU $22 ; food
OBJ_VALUABLE_TREASURE    EQU $23 ; valuable treasure
OBJ_24                   EQU $24 ; object $24 (name not decoded)
OBJ_WOODEN_CHEST         EQU $25 ; wooden chest
OBJ_LUNCH                EQU $26 ; lunch
OBJ_STRONG_PORTCULLIS    EQU $27 ; strong portcullis
OBJ_STONE                EQU $28 ; stone
OBJ_WOODEN_BOAT          EQU $29 ; wooden boat
OBJ_FAST_RIVER           EQU $2A ; fast river
OBJ_GOLDEN_KEY           EQU $2B ; golden key
PLAYER                   EQU $00 ; actor 0: Bilbo, the player
CHR_RED_GOLDEN_DRAGON    EQU $3C ; red golden dragon
CHR_NASTY_GOBLIN         EQU $3D ; nasty goblin
CHR_GANDALF              EQU $3E ; gandalf
CHR_THORIN               EQU $3F ; thorin
CHR_WOOD_ELF             EQU $40 ; wood elf
CHR_ELROND               EQU $41 ; elrond
CHR_BUTLER               EQU $42 ; butler
CHR_VICIOUS_WARG         EQU $43 ; vicious warg
CHR_GOLLUM               EQU $44 ; gollum
CHR_HIDEOUS_GOBLIN       EQU $45 ; hideous goblin
CHR_BARD                 EQU $46 ; bard
CHR_HIDEOUS_TROLL        EQU $47 ; hideous troll
CHR_VICIOUS_TROLL        EQU $48 ; vicious troll
CHR_HORRIBLE_GOBLIN      EQU $49 ; horrible goblin
CHR_MEAN_GOBLIN          EQU $4A ; mean goblin
DIR_NORTH                EQU $01 ; direction, also the command id for moving that way
DIR_SOUTH                EQU $02 ; direction, also the command id for moving that way
DIR_EAST                 EQU $03 ; direction, also the command id for moving that way
DIR_WEST                 EQU $04 ; direction, also the command id for moving that way
DIR_NORTHEAST            EQU $05 ; direction, also the command id for moving that way
DIR_NORTHWEST            EQU $06 ; direction, also the command id for moving that way
DIR_SOUTHEAST            EQU $07 ; direction, also the command id for moving that way
DIR_SOUTHWEST            EQU $08 ; direction, also the command id for moving that way
DIR_UP                   EQU $09 ; direction, also the command id for moving that way
DIR_DOWN                 EQU $0A ; direction, also the command id for moving that way
PORT_PRINTER             EQU 0xFB ; ZX printer port
PORT_ULA                 EQU 0xFE ; ULA port: keyboard half-rows, border
KEY_BITS                 EQU 0x1F ; keyboard port bits 0-4: key lines; all set = no key down
CHAR_CR                  EQU 0x0D ; carriage return: new line
CHAR_SPACE               EQU 0x20 ; space, the first printable character
STORY_SCROLL_ROWS        EQU 17 ; story window: character rows moved up by one scroll (rows 1-17 to 0-16)
STORY_COLUMNS            EQU 42 ; story window: characters per line
GLYPH_WIDTH              EQU 6 ; story window: pixels per character (42 x 6 = 252)
INPUT_COLUMNS            EQU 32 ; input window: characters per line
BORDER_GREEN             EQU 4 ; border colour green
BORDER_WHITE             EQU 7 ; border colour white
FONT_BASE_ADJUST         EQU 0x100 ; game font base is Font-$100 so that character code x indexes at 8*x
KEY_LEFT                 EQU 0x08 ; code of cursor left (5), also back-space
KEY_RIGHT                EQU 0x09 ; code of cursor right (8)
KEY_DOWN                 EQU 0x0A ; code of cursor down (6)
KEY_UP                   EQU 0x5B ; code of cursor up (7)
TOKEN_THEN               EQU 0xB0 ; word token of a full stop in the typed line: class 11 then
TOKEN_AND                EQU 0xA0 ; word token of a comma in the typed line: class 10 and
TOKEN_QUOTE              EQU 0x90 ; word token of a double quote in the typed line: class 9
WHITE                    EQU 0x07 ; colour white   
BLACK                    EQU 0x00 ; colour black   
PAPER                    EQU 0x08 ; multiplier of the paper colour in an attribute
SCREEN_BITMAP_SIZE       EQU 0x1800 ; bytes of screen bitmap
ATTRS_SIZE               EQU 0x0300 ; bytes of screen attributes
COMMAND_RECORD_SIZE      EQU 0x08 ; bytes in a command table record
ATTR_ROW                 EQU 0x20 ; bytes in one row of screen attributes (32 cells)
ORDER_SLOT_SIZE          EQU 25 ; bytes in an order slot: owner id + a 24-byte parsed command
ORDER_SLOTS              EQU 8 ; number of order slots at OrderSlots
PARSED_RECORD_SIZE       EQU 24 ; bytes in a parsed phrase record (the parser stack records)
PHRASE_WORDS_SIZE        EQU 6 ; bytes of a noun phrase: 3 dictionary words
REC_PHRASE_A             EQU 0x08 ; offset in a parsed phrase record of its first noun phrase (3 words)
REC_PHRASE_B             EQU 0x12 ; offset in a parsed phrase record of its second noun phrase (3 words)
FLAG_SLOT_PENDING        EQU 0xFF ; order slot owner value: slot is being filled
CHAR_BACKSPACE           EQU 0x08 ; back-space: moves the cursor one cell left and blanks it
KB_ROW_CAPS_V            EQU 0xFE ; keyboard half-row select: CAPS SHIFT Z X C V
KB_ROW_SPACE_B           EQU 0x7F ; keyboard half-row select: SPACE SYMBOL-SHIFT M N B
KEY_CAPS_SHIFT           EQU 0x01 ; keyboard port bit of CAPS SHIFT in its half-row
KEY_SYMBOL_SHIFT         EQU 0x02 ; keyboard port bit of SYMBOL SHIFT in its half-row
KEYS_PER_ROW             EQU 5 ; keys in one keyboard half-row
PRINTER_STOP_MOTOR       EQU 0x04 ; ZX printer port value that stops the motor
AT_LOCATION              EQU 0xFF ; holder id of an object that lies at its location instead of in a holder
RECORD_HEADER_SIZE       EQU 0x10 ; object/character record: bytes before the location list (+0 N .. +15)
ID_ENTRY_SIZE            EQU 3 ; bytes in an (id, word) table entry
NPC_RECORD_SIZE          EQU 7 ; bytes in an NPC record
LOCATION_COUNT           EQU 0x50 ; location ids are 0 to LOCATION_COUNT-1
ROLL_SPREAD              EQU 10 ; random spread added to a strength in a fight
END_MARK                 EQU 0xFF ; end byte of an (id, word) table
STATE_SIDE_BITS          EQU 0x70 ; object state byte (+4): bits 4-6, tested for a shared bit by the attack check
FLAG_CHARACTER           EQU 6 ; record flag (+7) bit: a character
FLAG_ACTIVE              EQU 5 ; record flag (+7) bit: active, open or alive
FLAG_DEAD                EQU 3 ; record flag (+7) bit: dead or disabled
PHRASE_BROKEN            EQU 0x00CD ; name phrase code: the word 'broken' (dictionary offset)
PHRASE_DEAD              EQU 0x0192 ; name phrase code: the word 'dead' (dictionary offset)
EXIT_SIZE                EQU 3 ; bytes in an exit record of a location (direction, obstacle, destination)
EXITS_BIAS               EQU 7 ; offset of the exit list in a location record minus one exit record (walkers step before reading)
REASON_CLOSED            EQU 5 ; reason id 5 of the object state words: closed (bit 7 set: open)
REASON_LOCKED            EQU 0x80 ; reason id 0 with bit 7: locked
REASON_OPEN              EQU 0x85 ; reason id 5 with bit 7: open
FLAG_PRESENT             EQU 7 ; record flag (+7) bit: present in the game (counted, can be seen)
FLAG_LOCKED              EQU 0 ; record flag (+7) bit: locked (door, chest)
WORD_SUFFIX_OBJ1         EQU 0x10 ; word print mode (high nibble of a word code): ending added when the first object (B6E8) is not 0
WORD_SUFFIX              EQU 0x40 ; word print mode: ending always added (verb words that take one)
WORD_PLAIN               EQU 0x50 ; word print mode: never an ending
WORD_CAPITAL             EQU 0x70 ; word print mode: first letter capital, ending when the subject is not the player
WORD_YOU                 EQU 0x07A8 ; dictionary offset of the word 'you' (name phrase code of the player; with bit 15 set)
WORD_ENDING_SIZE         EQU 4 ; bytes in a word ending record (WordEndings)
LETTER_BASE              EQU 0x60 ; dictionary letter n (1=a) prints as character LETTER_BASE+n
REC_WORD1                EQU 0 ; offset in a parsed phrase record of the first command word (verb, or the direction)
REC_WORD2                EQU 2 ; offset in a parsed phrase record of the second command word (e.g. go)
REC_BLOCK_A              EQU 4 ; offset in a parsed phrase record of the first phrase block (2 prepositions + noun phrase)
REC_BLOCK_B              EQU 0x0E ; offset in a parsed phrase record of the second phrase block
PHRASE_BLOCK_SIZE        EQU 10 ; bytes in a phrase block: 2 prepositions, noun, 2 adjectives (the dispatcher's ActionSlots)
RECF_EXCEPT              EQU 6 ; bit of byte +1 of a parsed phrase record: record only holds the nouns after except
RECF_ALL                 EQU 7 ; bit of byte +1 of a parsed phrase record: all was typed
ALL_STATE_ALL            EQU 1 ; AllStage after the word ALL
ALL_STATE_EXCEPT         EQU 2 ; AllStage after EXCEPT following ALL
ROW_BYTES                EQU 32 ; bytes in one pixel line of a screen character row
INPUT_SCROLL_ROWS        EQU 4 ; input window: character rows moved up by one scroll (rows 20-23 to 19-22)
ITEM_COMMON_WORD         EQU 0x60 ; message item byte: first of the 32 common words ($60-$7F), index into CommonWordTable
