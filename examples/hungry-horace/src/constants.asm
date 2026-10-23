; Numeric constants (sizes, counts, colours, key masks, codes), used in
; the skool files through @isub. Add with: tools/zxq.py const NAME VALUE COMMENT
; Addresses (ROM, system variables, screen) are @equ lines in re/skool/head.skool.
SCREEN_SIZE              EQU $1800 ; bitmap bytes
ATTRS_SIZE               EQU $0300 ; attribute bytes
ULA_PORT                 EQU $FE ; keyboard in, border/beeper out
KB_CS_V                  EQU $FE ; high byte of port for half-row CAPS SHIFT,Z,X,C,V
KB_A_G                   EQU $FD ; high byte of port for half-row A,S,D,F,G
KB_Q_T                   EQU $FB ; high byte of port for half-row Q,W,E,R,T
KB_1_5                   EQU $F7 ; high byte of port for half-row 1,2,3,4,5
KB_0_6                   EQU $EF ; high byte of port for half-row 0,9,8,7,6
KB_P_Y                   EQU $DF ; high byte of port for half-row P,O,I,U,Y
KB_ENTER_H               EQU $BF ; high byte of port for half-row ENTER,L,K,J,H
KB_SPACE_B               EQU $7F ; high byte of port for half-row SPACE,SYMBOL SHIFT,M,N,B
KB_ALL_ROWS              EQU $00 ; port high byte that reads every half-row at once
KEY_BITS                 EQU $1F ; key bits of a half-row read (0 = pressed)
BLACK                    EQU 0 ; colour
BLUE                     EQU 1 ; colour
RED                      EQU 2 ; colour
MAGENTA                  EQU 3 ; colour
GREEN                    EQU 4 ; colour
CYAN                     EQU 5 ; colour
YELLOW                   EQU 6 ; colour
WHITE                    EQU 7 ; colour
BRIGHT                   EQU $40 ; attribute bit
FLASH                    EQU $80 ; attribute bit
PAPER                    EQU 8 ; multiplier: colour*PAPER + ink
CHAR_0                   EQU $30 ; ASCII digit 0
CHAR_SPACE               EQU $20 ; ASCII space, first glyph of the ROM font
CELL_BYTES               EQU 8 ; bytes (pixel rows) per character cell
SCREEN_COLS              EQU 32 ; character cells per screen row
THIRD_STEP               EQU 8 ; step of the screen address high byte from one screen third to the next
THIRD_BITS               EQU $18 ; bits of the screen address high byte that select the third
ROM_HIGH_MASK            EQU $1F ; mask for the high byte of an address to keep it inside the 8K ROM
ATTRS_HIGH               EQU $58 ; high byte of the attribute area address ($5800)
LEFT_HALF                EQU $F0 ; pixel byte with the left four pixels set
RIGHT_HALF               EQU $0F ; pixel byte with the right four pixels set
BOTH_HALVES              EQU $FF ; pixel byte with all eight pixels set
TILE_EMPTY               EQU 0 ; maze tile: empty floor
TILE_FLOWER              EQU 2 ; maze tile: flower
TILE_ARROW               EQU 3 ; maze tile: arrow (maze entrance/exit)
TILE_BLANK_WHITE         EQU 9 ; maze tile: blank bitmap drawn white on white
GUARD_RECORD_SIZE        EQU $2B ; bytes in one guard record
MAZE_DESC_SIZE           EQU 8 ; bytes in a maze descriptor
ULA_OUT_MASK             EQU $1F ; bits of an OUT to port $FE: border colour, MIC, speaker
SWEEP_STEPS              EQU 16 ; pitch steps in the rising tone
SWEEP_CYCLES             EQU 10 ; square-wave cycles per pitch step
GUARD_COUNT              EQU 4 ; number of guards
ATTR_GUARD               EQU $3B ; attribute of a guard (white paper, magenta ink)
ATTR_BELL                EQU $3A ; attribute of the bell bonus item (white paper, red ink)
ATTR_FLOWER              EQU $3C ; attribute of a flower (white paper, green ink)
ATTR_WALL                EQU $3D ; attribute of a maze wall (white paper, cyan ink)
ATTR_BLANK               EQU $3E ; attribute of an empty floor cell (white paper, yellow ink, blank bitmap)
ATTR_PAD                 EQU $3F ; attribute of the invisible vertical wrap pads (white ink on white paper)
ATTR_ARROW               EQU $38 ; attribute of the edge arrows, maze exits (white paper, black ink)
DIR_UP                   EQU 0 ; direction code: up
DIR_RIGHT                EQU 1 ; direction code: right
DIR_DOWN                 EQU 2 ; direction code: down
DIR_LEFT                 EQU 3 ; direction code: left
DIR_MASK                 EQU 3 ; direction codes use the low two bits
MOVE_FREE                EQU 0 ; probe result: nothing in the way
MOVE_WRAP                EQU 1 ; probe result: vertical wrap pad ahead
MOVE_EXIT                EQU 2 ; probe result: edge arrows ahead
MOVE_BLOCKED             EQU 3 ; probe result: wall ahead
PROBE_BLOCKED            EQU $FF ; probe accumulator value meaning a wall was seen
KEY_T_BIT                EQU $10 ; bit of the half-row Q-T read for the T key (0 = pressed): toggles the sound
SOUND_TOGGLE             EQU $18 ; XOR value that flips the sound mask between $1F (on) and $07 (off)
SAVED_CELL_SIZE          EQU 9 ; bytes per saved character cell: attribute + 8 pixel rows
SPRITE_CELLS             EQU 4 ; character cells in a 16x16 sprite (2x2)
FRUIT_MIN_DELAY          EQU $0320 ; least value of the fruit timer after a fruit appears
FRUIT_DELAY_MASK         EQU $03 ; mask of the random high byte added to the fruit timer (0-1023 extra)
BELL_PHASE_MASK          EQU $3F ; bell animation counter wraps every 64 steps
BELL_HALF_PHASE          EQU $20 ; bell animation counter value at the half way point
SPEED_DELAY_BASE         EQU $015E ; delay loop passes at guard interval 0
SPEED_DELAY_STEP         EQU $1E ; delay loop passes added per guard-interval step
CHIME_LOW_LEN            EQU $16 ; beeper cycles of the lower bell tone
CHIME_LOW_PITCH          EQU $0193 ; ROM BEEPER pitch value of the lower bell tone (about 1010 Hz)
CHIME_HIGH_LEN           EQU $1A ; beeper cycles of the higher bell tone
CHIME_HIGH_PITCH         EQU $0168 ; ROM BEEPER pitch value of the higher bell tone (about 1120 Hz)
SPRITE_BYTES             EQU 0x20 ; bytes in a 16x16 sprite graphic (4 cells x 8 rows); also the step from one direction's sprite to the next
GUARD_WALK_FRAME_BIT     EQU 0x20 ; bit of the guard animation counter that selects the walking frame set
GUARD_SCARED_FRAME_BIT   EQU 8 ; bit of the guard animation counter that selects the frame while the bell timer runs
HORACE_FRAME_BIT         EQU 0x10 ; bit of Horace's animation counter that selects the walking frame set
AI_BASE_SCORE            EQU 0x19 ; guard AI: starting score of every open direction
AI_STRAIGHT_BONUS        EQU 0x28 ; guard AI: score added for continuing in the current direction
AI_REVERSE_PENALTY       EQU 10 ; guard AI: score taken off for turning back (the byte added is 256 minus this)
AI_RANDOM_MASK           EQU 0x1F ; guard AI: mask of the random ROM byte added to a sideways direction (0-31)
AI_CHASE_BIAS            EQU 10 ; guard AI: constant added to the distance bonus for a direction that approaches Horace
RANDOM_ROM_HIGH_MASK     EQU 0x0F ; mask for the high byte of the FRAMES-based random pointer: keeps it in the first 4K of the ROM
CELL_COL_BITS            EQU 5 ; bits of a screen offset that hold the character column
WRAP_PAUSE               EQU 0x5A ; passes of the main loop Horace stays frozen after passing through a wrap pad
WRAP_TONE_CYCLES         EQU 8 ; square-wave cycles per pitch step of the wrap-around tone
DIR_COUNT                EQU 4 ; number of directions
DIR_OPPOSITE             EQU 2 ; added to a direction code (then masked with DIR_MASK) to get the opposite direction
DIR_NONE                 EQU 0xFF ; requested direction: no key pressed / nothing requested
KEY_Q                    EQU 0x01 ; bit of the Q-T half-row for Q (up)
KEY_4                    EQU 0x08 ; bit of the 1-5 half-row for 4 (up)
KEY_Z                    EQU 0x02 ; bit of the CAPS SHIFT-V half-row for Z (down)
KEY_3                    EQU 0x04 ; bit of the 1-5 half-row for 3 (down)
KEY_2                    EQU 0x02 ; bit of the 1-5 half-row for 2 (right)
KEY_1                    EQU 0x01 ; bit of the 1-5 half-row for 1 (left)
KEYBIT_P                 EQU 0 ; bit number of P in the P-Y half-row (right)
KEYBIT_I                 EQU 2 ; bit number of I in the P-Y half-row (left)
SCORE_FLOWER             EQU 10 ; points for a flower
SCORE_ITEM               EQU 50 ; points for a bell or fruit seen in the block Horace steps on (the bell adds more, see SCORE_BELL_PICKUP)
SCORE_BELL_PICKUP        EQU 60 ; points added when Horace takes the bell
SCORE_BELL_BONUS         EQU 150 ; second bonus added when Horace takes the bell
STATUS_PASSES_COL        EQU 7 ; column of the passes digit on the status line
STATUS_SCORE_COL         EQU 15 ; column of the first score digit on the status line
EXTRA_PASS_SCORE         EQU 10000 ; score interval at which Horace gets an extra pass
EAT_TONE_STEPS           EQU 16 ; pitch steps of the short sound made whenever the score changes
BELL_FRAME_BITS          EQU 0x38 ; bits of the bell counter that select its animation step (a step every 8 passes)
BELL_MIRROR_LIMIT        EQU 0x1F ; bell counter step values above this are in the second, mirrored half of the animation
SCREEN_ROWS              EQU 24 ; character rows on the screen
THIRD_SIZE               EQU 0x0800 ; bytes of screen bitmap in one third (8 character rows)
ATTR_HORACE              EQU 0x39 ; attribute of Horace (white paper, blue ink)
MAZE_NONE                EQU 0xFF ; maze number before the first maze: the next maze is number 0
MAZE_MASK                EQU 3 ; maze numbers 0-3 use the low two bits
START_PASSES             EQU 3 ; passes (lives) at the start of a game, before the free pass of the first score display
START_GUARD_INTERVAL     EQU 8 ; guard interval (game pace) at the start of a game
MIN_GUARD_INTERVAL       EQU 1 ; fastest guard interval; each cycle through the four mazes lowers the interval by one down to this
TITLE_PASSES             EQU 140 ; passes of the title screen colour-cycling loop before the demo starts (about 12 s)
FRUIT_FIRST_DELAY        EQU 2000 ; main loop passes to the first fruit drop of a maze (the fruit timer)
STATUS_BEST_COL          EQU 26 ; column of the first best-score digit on the status line
DEMO_BANNER_LEN          EQU 9 ; characters of the flashing DEMO MODE words at the start of the demo banner
CELL_ROW_STEP            EQU 0x20 ; step of a screen offset from one character row to the next inside a screen third (add THIRD_SIZE per third)
SCORE_GUARD              EQU 100 ; points for eating a guard while the bell timer runs
EATEN_TONE_STEPS         EQU 15 ; pitch steps of the falling buzz played when Horace eats a guard
EATEN_TONE_CYCLES        EQU 8 ; square-wave cycles per pitch step of the falling buzz
GUARD_WAIT               EQU 0x5A ; main loop passes an eaten guard waits at its start before it is drawn again
DEATH_FLASHES            EQU 45 ; colour steps of Horace's death animation
DEATH_NOISE_CYCLES       EQU 20 ; noise cycles (one random-length high and low half each) per colour step of the death animation
NOISE_MIN_DELAY          EQU 0x40 ; random delay counts of the death noise are ORed with this, so at least 64 loop passes
INK_MASK                 EQU 7 ; attribute bits holding the ink colour
PASSES_LABEL_CELLS       EQU 9 ; cells of the status line holding the word PASSES, its spaces and the digit (columns 0-8)
GAME_OVER_FLASHES        EQU 20 ; screen colour steps (each with a rising tone) of the game over sequence
TEXT_END                 EQU $FF ; terminator of the game texts
PROBE_ARROW_WEIGHT       EQU 4 ; ProbeCell adds 4 per arrow cell, 1 per pad cell
PROBE_MANY_BITS          EQU $0A ; bits 1 and 3 of pads+4*arrows: two or more pads / arrows
BLOCK_TOP_BITS           EQU $30 ; title block byte: bit 4 top-left, bit 5 top-right
BLOCK_TOP_LEFT           EQU $10 ; title block byte: top-left block
BLOCK_TOP_RIGHT          EQU $20 ; title block byte: top-right block
BLOCK_BOTTOM_BITS        EQU $03 ; title block byte: bit 0 bottom-left, bit 1 bottom-right
BLOCK_BOTTOM_RIGHT       EQU $02 ; title block byte: bottom-right block
BLOCK_PIXEL_ROWS         EQU 4 ; pixel rows in one block (4x4 pixels)
