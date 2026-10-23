"""The rules' numbers the flow uses, named as in src/constants.asm (no addresses)."""
CHAR_CR, CHAR_SPACE, CHAR_BACKSPACE = 0x0D, 0x20, 0x08
CHAR_QUOTE, CHAR_COMMA, CHAR_FULLSTOP, CHAR_PROMPT, CHAR_AT = 0x22, 0x2C, 0x2E, 0x3E, 0x40
KEY_DELETE = 0x18                   # CAPS SHIFT+0
TOKEN_QUOTE, TOKEN_AND, TOKEN_THEN, TOKEN_END, TOKEN_UNKNOWN = 0x90, 0xA0, 0xB0, 0xC0, 0xD0
INPUT_LINE_SIZE = 0x80              # characters of a typed line (then its CR)
PARSED_WORDS_SIZE = 64              # bytes of the word list: 32 tokens, high byte first
STORY_COLUMNS, INPUT_COLUMNS = 42, 32
CURSOR_GLYPH = 0x2B                 # '+'
OPENING_LINES, TURN_NO_PAUSE_LINES = 17, 9
ORDER_SLOTS = 8
WHITE, BLACK, PAPER = 7, 0, 8
RULE_ROW_Y = 145                    # the rule between the windows: pixel rows 145-149
