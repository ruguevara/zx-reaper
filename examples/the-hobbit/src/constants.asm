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
