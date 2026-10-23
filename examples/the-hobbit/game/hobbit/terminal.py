"""The two text windows (stage 3: screen.py and devices.py; src/screen.asm,
src/devices.asm, docs/05-text-and-screen.md).

The story window: 42 characters a line in the game's own font (6 pixels
wide, so a character straddles two cells: the cursor is a cell column and a
pixel offset), printed on character row 17 and scrolled up, bitmap and
attributes, over rows 1-17, so a picture slides up and off the top. The
input window: 32 columns of the ROM font in capitals on row 23, scrolled up
over rows 19-23, bitmap only, with a cursor glyph after the last character.
Everything is drawn into s.screen; the cursors and counters are s.terminal,
the flags s.vars. The keyboard scanner is not here: keys arrive as ReadKey
answers (words.wait_key)."""
from zxpyxel import png
from zxpyxel.machine import ROM

from . import assets
from .state import Printed, ScrollPause

CR, BACKSPACE, SPACE = 0x0D, 0x08, 0x20
STORY_ROW = 17              # the story line; rows 1-17 scroll up into 0-16
STORY_COLUMNS = 42
GLYPH_WIDTH = 6
INPUT_ROW = 23              # the input line; rows 20-23 scroll up into 19-22
INPUT_TOP = 19
INPUT_COLUMNS = 32
RULE_ROW = 18               # the decorative rule between the windows
ROM_FONT = 0x3D00           # the ROM's character set: 96 characters from space


def _font():
    """font.png: the story font, characters 32-127 on 16 x 6 cells; a glyph
    uses the left 6 pixels of its cell (the next character covers the rest)."""
    out = []
    for k, (glyph, ink, bright) in enumerate(png.cells(assets.path('font.png'), 16, 6)):
        if any(b & 3 for b in glyph):
            raise ValueError('font.png: cell %d,%d (character %d) uses the right two pixel columns'
                             % (k % 16, k // 16, 32 + k))
        out.append(glyph)
    return out


FONT = _font()
_TEXT = {bytes(b & 0xFC for b in g): chr(32 + k) for k, g in enumerate(FONT)}    # the printer's reading


def _index(ch):
    """The glyph index of character `ch` (both fonts hold characters 32-127; the
    original would draw other bytes for the rest, which it never prints)."""
    if not 32 <= ch < 128:
        raise ValueError('character %d has no glyph' % ch)
    return ch - 32


def put_char(s, ch):
    """Print character `ch` in the story window or, while s.vars.raw_output is
    set, in the input window; nothing while output is off (a command's test
    pass, an actor out of sight). In the story window a lisp (s.vars.lisp)
    adds an H after every S. (stage 3: PrintChar)"""
    v = s.vars
    if not v.action_perform & v.messages_visible:
        return
    if v.raw_output:
        print_input_window_char(s, ch)
        return
    yield from output_story_char(s, ch)
    if v.lisp and ch in (ord('S'), ord('s')):
        yield from output_story_char(s, ord('H'))


def new_line(s):
    """End the line (a carriage return through put_char). (stage 3: PrintNewLine)"""
    yield from put_char(s, CR)


def output_story_char(s, ch):
    """Print character `ch` at the story cursor: an empty line starts with the
    list indent; CR ends the line, a back-space steps back over a character,
    letters print in lower case unless a capital is due (s.vars.capital_next,
    counted up by each full stop); a full line ends as a CR does. A line end
    goes to the printer, pauses (ScrollPause) and scrolls. (stage 3: OutputStoryChar)"""
    t, v = s.terminal, s.vars
    col, pixel = t.story_cursor, t.story_pixel
    if t.story_last_char == 0 and t.list_indent:
        for _ in range(t.list_indent):
            col, pixel = print_story_char(s, SPACE, col, pixel)
            t.story_column = t.story_column - 1 & 0xFF
    end_line = False
    if ch == CR:
        v.capital_next = 1
        end_line = True
    elif ch == BACKSPACE:
        col, pixel = _step_back(col, pixel)
        col, pixel = print_story_char(s, SPACE, col, pixel)
        col, pixel = _step_back(col, pixel)
        columns = t.story_column + 1 & 0xFF
    else:
        if ord('A') <= ch <= ord('Z'):
            ch |= 0x20
        capital = v.capital_next
        if capital and ord('a') <= ch <= ord('z'):
            ch &= ~0x20                     # the first letter after a sentence end
            capital = v.capital_next = 0
        if ch == ord('.'):
            v.capital_next = capital + 1 & 0xFF     # (any value but 0 gives one capital)
        col, pixel = print_story_char(s, ch, col, pixel)
        t.story_last_char = ch
        columns = t.story_column - 1 & 0xFF
        end_line = columns == 0
    if end_line:
        t.story_last_char = 0
        yield from print_story_line(s)
        if t.no_pause_lines:                # the opening text and the lines after a command
            t.no_pause_lines -= 1
        else:
            yield ScrollPause()
        col, pixel = 0, 1
        scroll_story_up(s)
        columns = STORY_COLUMNS
    t.story_column = columns
    t.story_cursor, t.story_pixel = col, pixel


def _step_back(col, pixel):
    """The story cursor one character back (stage 3: StepCursorBack)."""
    pixel -= GLYPH_WIDTH
    if pixel < 0:
        return col - 1, pixel + 8
    return col, pixel


def print_story_char(s, ch, col, pixel):
    """Draw character `ch` of the story font at `pixel` (0-7) of cell column
    `col` on the story line: 8 pixels from there are replaced, spilling into
    the next cell. Returns the column and pixel of the next character.
    (stage 3: PrintStoryChar)"""
    d, glyph = s.screen, FONT[_index(ch)]
    keep = 0xFF >> pixel
    for k, g in enumerate(glyph):
        y = STORY_ROW * 8 + k
        d.set_byte(col, y, d.byte(col, y) & ~keep & 0xFF | g >> pixel)
        if pixel:                           # (a column of 32 would be the rule row's first cell)
            d.set_byte(col + 1, y, d.byte(col + 1, y) & keep | g << 8 - pixel & 0xFF)
    pixel += GLYPH_WIDTH
    if pixel >= 8:
        return col + 1, pixel - 8
    return col, pixel


def _copy_row(d, src, dst):
    """The bitmap of character row `src` into row `dst`."""
    for y in range(8):
        for col in range(32):
            d.set_byte(col, dst * 8 + y, d.byte(col, src * 8 + y))


def scroll_story_up(s):
    """Scroll the story window (rows 1-17, bitmap and attributes) up a row and
    blank the story line: 42 spaces from pixel 1, so its first and last pixel
    columns keep what they had. (stage 3: ScrollStoryUp)"""
    d = s.screen
    for row in range(STORY_ROW):
        _copy_row(d, row + 1, row)
        for col in range(32):
            d.set_attr(col, row, d.attr(col, row + 1))
    col, pixel = 0, 1
    for _ in range(STORY_COLUMNS):
        col, pixel = print_story_char(s, SPACE, col, pixel)


def print_story_line(s):
    """With PRINT on, the story line goes to the printer: the transcript gets
    its text (Printed); the original sends its pixels to the ZX printer.
    (stage 3: PrintStoryLine)"""
    if s.vars.printer_on:
        yield Printed(story_line_text(s))


def story_line_text(s):
    """The characters on the story line, read back from its pixels."""
    d, out = s.screen, []
    for i in range(STORY_COLUMNS):
        x = 1 + GLYPH_WIDTH * i
        g = bytes(sum(d.pixel(x + j, STORY_ROW * 8 + k) << 7 - j for j in range(6)) for k in range(8))
        out.append(_TEXT.get(g, '?'))
    return ''.join(out).rstrip()


def print_input_window_char(s, ch):
    """Print character `ch` at the input cursor: letters in capitals, CR
    scrolls the window up, a back-space goes back (into the line above, the
    window scrolled down, at the start of a line), a full line wraps; then
    the cursor glyph after it. (stage 3: PrintInputWindowChar)"""
    t = s.terminal
    col = t.input_cursor
    if ch == CR:
        print_input_char(s, SPACE, col)
        scroll_input_up(s)
        columns, col = INPUT_COLUMNS, 0
    elif ch == BACKSPACE:
        print_input_char(s, SPACE, col)
        col -= 1
        columns = t.input_column + 1 & 0xFF
        if columns == INPUT_COLUMNS + 1:    # back past the start of the line
            col = INPUT_COLUMNS - 1
            scroll_input_down(s)
            columns = 1
    else:
        if ord('a') <= ch <= ord('z'):
            ch &= 0x5F
        col = print_input_char(s, ch, col)
        columns = t.input_column - 1 & 0xFF
        if columns == 0:
            col = 0
            scroll_input_up(s)
            columns = INPUT_COLUMNS
    t.input_column = columns
    t.input_cursor = col
    print_input_char(s, t.input_glyph, col)


def print_input_char(s, ch, col):
    """Draw character `ch` of the ROM font at column `col` of the input line
    (the bitmap only); returns the next column. (stage 3: PrintInputChar)"""
    a = ROM_FONT + 8 * _index(ch)
    glyph = ROM[a:a + 8]
    for k in range(8):
        s.screen.set_byte(col, INPUT_ROW * 8 + k, glyph[k])
    return col + 1


def scroll_input_up(s):
    """Scroll the input window (rows 20-23 into 19-22, bitmap only) and blank
    the input line. (stage 3: ScrollInputUp)"""
    for row in range(INPUT_TOP, INPUT_ROW):
        _copy_row(s.screen, row + 1, row)
    for col in range(INPUT_COLUMNS):
        print_input_char(s, SPACE, col)


def scroll_input_down(s):
    """Scroll the input window down a row: rows 22 to 18 copied a row down, the
    last copy taking the rule (row 18) into row 19, which is not cleared:
    quirk kept. (stage 3: ScrollInputDown)"""
    for row in range(INPUT_ROW - 1, RULE_ROW - 1, -1):
        _copy_row(s.screen, row, row + 1)
