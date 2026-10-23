"""Ported from src/screen.asm: the story and input windows: characters, scrolling, the font.
Values pass in the registers `r` (port/regs.py); conventions: port/CONTRACT.md."""
from labels import *  # noqa: F403  (first: port functions shadow routine labels)
import calls  # noqa: F401
import devices
from regs import r
from variables import v
from zxpyxel import Goto, mem, mem16, zx  # noqa: F401


def _flags():
    return r.zf, r.cf, r.sf, r.pf


def _set_flags(f):
    r.zf, r.cf, r.sf, r.pf = f


def _copy(src, dst, n, loop_t=150):
    """LDIR of n bytes as a helper (no register is touched); `loop_t` is the
    T-states of the scroll loop around it."""
    for k in range(n):
        mem[dst + k & 0xFFFF] = mem[src + k & 0xFFFF]
    zx.spend(21 * n - 5 + loop_t)


def OutputEnabled():
    """Is text output on? Z when ActionPerform and MessagesVisible share no
    bit (nothing is to be printed). A and HL are kept."""
    r.set_zs(v.ActionPerform & v.MessagesVisible)
    r.cf = False


async def PrintNewLine():
    """Print a new line (CHAR_CR through PrintChar). AF is kept."""
    a, f = r.a, _flags()
    r.a = CHAR_CR
    await PrintChar()
    r.a = a
    _set_flags(f)


async def PrintChar():
    """The one character output of the game: A to the input window when
    RawOutputFlag is set, else to the story window; with LispFlag an S or s is
    followed by an H. Z on return when output is off (nothing printed); else
    NZ, except for the lisped S (Z, as the asm's CP leaves it)."""
    a = r.a
    OutputEnabled()
    if r.zf:
        return
    if v.RawOutputFlag:
        return PrintToInput()
    await OutputStoryChar()
    if not v.LispFlag:
        return
    r.cp(ord('S'))
    if r.zf:
        pass
    else:
        r.cp(ord('s'))
        if not r.zf:
            return
    await _lisp_h(a)


async def _lisp_h(a):
    # The lisp's extra H goes through the same story routine; A and the flags
    # of the preceding CP come back.
    f = _flags()
    r.a = ord('H')
    await OutputStoryChar()
    r.a = a
    _set_flags(f)


def PrintToInput():
    """Print the character in A in the input window (the entry from PrintChar,
    whose stacked AF is just A and the flags here)."""
    return PrintInputWindowChar()


def PrintInputWindowChar():
    """Print the character A at the input window's cursor: letters to capitals,
    CR scrolls the window up, back-space (8) goes back, a full line wraps;
    then the cursor glyph is drawn after it. A, HL and the flags are kept."""
    a = r.a
    hl = mem16[InputCursor]
    if a == CHAR_CR:
        hl = _put_input_char(CHAR_SPACE, hl)
        ScrollInputUp()
        columns = INPUT_COLUMNS
        hl = hl & 0xFF00 | CURSOR_ROW_START
    elif a == CHAR_BACKSPACE:
        hl = _put_input_char(CHAR_SPACE, hl)
        hl = hl & 0xFF00 | hl - 2 & 0xFF
        columns = v.InputColumn + 1 & 0xFF
        if columns == INPUT_COLUMNS_PLUS_1:             # back past the start of the line
            hl |= 0xFF
            ScrollInputDown()
            columns = 1
    else:
        if ord('a') <= a <= ord('z'):
            a &= 0x5F
        hl = _put_input_char(a, hl)
        columns = v.InputColumn - 1 & 0xFF
        if columns == 0:
            hl = hl & 0xFF00 | CURSOR_ROW_START
            ScrollInputUp()
            columns = INPUT_COLUMNS
    v.InputColumn = columns
    glyph = v.InputCursorGlyph
    mem16[InputCursor] = hl
    _put_input_char(glyph, hl)


def ScrollInputUp():
    """Scroll the input window (character rows 19-23) up one line, bitmap
    only, and blank the bottom row. All registers are kept."""
    src, dst = SCREEN_ROW_20, SCREEN_ROW_19
    for _ in range(INPUT_SCROLL_ROWS):
        for line in range(8):
            _copy(src + (line << 8), dst + (line << 8), ROW_BYTES)
        src += ROW_BYTES
        dst += ROW_BYTES
    hl = SCREEN_ROW_23
    for _ in range(INPUT_COLUMNS):
        hl = _put_input_char(CHAR_SPACE, hl)


def ScrollInputDown():
    """Scroll the input window down one line: rows 22 to 18 copied one row
    down (the fifth copy takes the divider row 18 into row 19; row 19 is not
    cleared). All registers are kept."""
    src, dst = SCREEN_ROW_22, SCREEN_ROW_23
    for _ in range(5):
        for line in range(8):
            _copy(src + (line << 8), dst + (line << 8), ROW_BYTES)
        src -= ROW_BYTES
        dst -= ROW_BYTES


def _put_input_char(code, hl):
    """Draw `code` in the ROM font at screen cell hl; the next cell (L + 1)."""
    font = ROM_FONT + ((code - CHAR_SPACE & 0xFF) << 3)
    for k in range(8):
        mem[hl + (k << 8) & 0xFFFF] = mem[font + k]
    zx.spend(470)
    return hl & 0xFF00 | hl + 1 & 0xFF


def PrintInputChar():
    """Draw character A in the ROM font at the cell HL; HL = the next cell
    (L + 1). AF, BC, DE are kept, except the flags of INC L."""
    r.hl = _put_input_char(r.a, r.hl)
    r.set_zs(r.l)
    r.pf = r.l == 0x80                                  # INC L overflow


async def OutputStoryChar():
    """Print character A in the story window at the cursor (StoryCursor +
    StoryCursorPixel): the indent at the start of an empty line; CR ends the
    line (printer, scroll pause that a held key extends, scroll); back-space
    steps back; capitals become lower case unless CapitalNext asks for one
    after a full stop; a full line ends like a CR. A, BC, HL and the flags
    are kept."""
    saved = r.a, r.bc, r.hl, _flags()
    ch = r.a
    hl, c = mem16[StoryCursor], v.StoryCursorPixel
    if v.StoryLastChar == 0 and v.ListIndent:
        for _ in range(v.ListIndent):
            hl, c = _put_story_char(CHAR_SPACE, hl, c)
            v.StoryColumn = v.StoryColumn - 1 & 0xFF
    end_line = False
    if ch == CHAR_CR:
        v.CapitalNext = 1
        end_line = True
    elif ch == CHAR_BACKSPACE:
        hl, c = _step_back(hl, c)
        hl, c = _put_story_char(CHAR_SPACE, hl, c)
        hl, c = _step_back(hl, c)
        columns = v.StoryColumn + 1 & 0xFF
    else:
        if ord('A') <= ch <= ord('Z'):
            ch |= 0x20
        capital = v.CapitalNext
        if capital and ord('a') <= ch <= ord('z'):
            ch &= ~0x20                                 # a letter after a sentence end
            capital = v.CapitalNext = 0
        if ch == ord('.'):
            v.CapitalNext = capital + 1 & 0xFF
        hl, c = _put_story_char(ch, hl, c)
        v.StoryLastChar = ch
        columns = v.StoryColumn - 1 & 0xFF
        end_line = columns == 0
    if end_line:                                        # StoryLineEnd
        v.StoryLastChar = 0
        await devices.PrintStoryLine()
        await _scroll_pause()
        hl, c = STORY_LAST_ROW, 1
        ScrollStoryUp()
        columns = STORY_COLUMNS
    v.StoryColumn = columns
    mem16[StoryCursor] = hl
    v.StoryCursorPixel = c
    r.a, r.bc, r.hl, f = saved
    _set_flags(f)


async def _scroll_pause():
    """The pause after a story line: while NoPauseLines is not 0 (the opening
    text) it only counts down; otherwise SCROLL_DELAY polls of the keyboard,
    a key ending them early. A key down is then waited for to go up."""
    key_down = True
    if v.NoPauseLines:
        v.NoPauseLines -= 1
    else:
        key_down = False
        for left in range(SCROLL_DELAY, 0, -1):         # XOR A, IN, AND, CP, JR; DEC BC, LD, OR, JR
            if zx.inp(PORT_ULA) & KEY_BITS != KEY_BITS:
                zx.spend(4 + 11 + 7 + 7 + 12)
                await zx.sync()
                key_down = True
                break
            zx.spend(62 if left > 1 else 57)
            await zx.sync()
    if key_down:
        while True:                                     # wait until all keys are up
            pressed = zx.inp(PORT_ULA) & KEY_BITS != KEY_BITS
            zx.spend(41 if pressed else 36)
            await zx.sync()
            if not pressed:
                break


def _step_back(hl, c):
    """Cursor back one glyph: C -= GLYPH_WIDTH, borrowing from the cell on the left."""
    c -= GLYPH_WIDTH
    if c < 0:
        c += 8
        hl = hl & 0xFF00 | hl - 1 & 0xFF
    return hl, c


def StepCursorBack():
    """Move the story cursor back one glyph: C = C - GLYPH_WIDTH, +8 and L - 1
    on a borrow. A = C; carry as the asm's SUB/ADD leaves it."""
    c = r.c - GLYPH_WIDTH
    r.cf = c < 0
    if r.cf:
        c += 8
        r.l = r.l - 1 & 0xFF
    r.a = r.c = c
    r.zf = c == 0
    r.sf = r.pf = False
    if r.cf:
        r.pf = r.l == 0x7F                              # the DEC L (before it: L - 1 = r.l)
        r.set_zs(r.l)


def ScrollStoryUp():
    """Scroll the story window (character rows 1-17) up one line, bitmap and
    attributes, and blank row 17 (42 spaces from pixel offset 1). All
    registers are kept."""
    src, dst = SCREEN + ROW_BYTES, SCREEN
    for _ in range(STORY_SCROLL_ROWS):
        for line in range(8):
            _copy(src + (line << 8), dst + (line << 8), ROW_BYTES)
        src += ROW_BYTES
        dst += ROW_BYTES
        if dst >> 8 & 7:                                # into the next third: +7 on the high byte
            dst += 0x700
        if src >> 8 & 7:
            src += 0x700
    _copy(ATTRS + ROW_BYTES, ATTRS, STORY_SCROLL_ROWS * ROW_BYTES, 0)
    hl, c = STORY_LAST_ROW, 1
    for _ in range(STORY_COLUMNS):
        hl, c = _put_story_char(CHAR_SPACE, hl, c)


def _put_story_char(code, hl, c):
    """Draw `code` of the game font (6x8) at pixel offset c of the cell hl,
    spilling into the next cell; returns the cell and offset of the next glyph."""
    glyph = Font - FONT_BASE_ADJUST + (code << 3) & 0xFFFF
    zx.spend(3864 if c else 1234)                       # the shift loops run only for c > 0
    for k in range(8):
        g = mem[glyph + k & 0xFFFF]
        addr = hl & 0xFF | (hl >> 8) + k << 8 & 0xFF00
        keep = 0xFF >> c
        mem[addr] = mem[addr] & ~keep & 0xFF | g >> c
        if c:                                           # the part over the right edge
            nxt = addr + 1 & 0xFFFF
            keep = 0xFF << 8 - c & 0xFF
            mem[nxt] = mem[nxt] & ~keep & 0xFF | g << 8 - c & 0xFF
    c += GLYPH_WIDTH
    if c >= 8:
        c -= 8
        hl = hl & 0xFF00 | hl + 1 & 0xFF
    return hl, c


def PrintStoryChar():
    """Draw character A of the game font at pixel offset C in the cell HL (the
    8-bit window cleared and filled; the overflow into the next cell). HL and C
    leave for the next glyph. A, DE, B and the flags are kept."""
    r.hl, r.c = _put_story_char(r.a, r.hl, r.c)
