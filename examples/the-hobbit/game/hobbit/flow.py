"""The game from its start (stage 3: main.py): the restart, the main loop, the
line editor and the word list. `Game().run()` is one generator for the whole
game; it yields the events of state.py and a Step at the top of every pass of
the main loop. QUIT, death and the end of the game come back as the flow
target 'RestartGame', and the game starts again from the title key."""
import copy

from . import assets, engine, parser, terminal, text, words
from . import handlers, system, verbs  # noqa: F401  (they register the table handlers)
from .constants import (CHAR_AT, CHAR_BACKSPACE, CHAR_COMMA, CHAR_CR, CHAR_FULLSTOP, CHAR_PROMPT,
                        CHAR_QUOTE, CHAR_SPACE, CURSOR_GLYPH, INPUT_COLUMNS, INPUT_LINE_SIZE,
                        KEY_DELETE, OPENING_LINES, ORDER_SLOTS, PARSED_WORDS_SIZE, RULE_ROW_Y,
                        STORY_COLUMNS, TOKEN_AND, TOKEN_END, TOKEN_QUOTE, TOKEN_THEN, TOKEN_UNKNOWN,
                        TURN_NO_PAUSE_LINES)
from .state import Order, Phrase, ReadR, Step, TitleKey, WaitKey

# the variables of the saved block, which a restart restores with the records
SAVED_VARS = ('random_event', 'timers_fired', 'exit_restore_mode', 'printer_on', 'arrival_location',
              'actor_has_order', 'player_location', 'actor_location', 'score', 'reply_given',
              'action_perform', 'action_allowed', 'weapon_name', 'noun1_kind', 'noun2_kind', 'lisp',
              'raw_output', 'messages_visible', 'phrase_mode', 'capital_next', 'parser_flag',
              'parser_word_count', 'pictures_enabled')


class Game:
    def __init__(self, state=None):
        self.state = state or assets.state()
        self.tables = assets.load_json('tables.json')

    def run(self):
        """The whole game: the backup of the state, then restart after restart."""
        s = self.state
        self.backup = copy.deepcopy((s.things, s.locations, s.timers, s.npcs,
                                     {k: getattr(s.vars, k) for k in SAVED_VARS}))
        while True:
            target = yield from self.restart_game()
            assert target == 'RestartGame', target

    def restart_game(self):
        """Restore the state, wait for the title key (N held: no pictures), seed
        the random numbers from R, set up the windows and the opening LOOK, then
        the main loop. Returns only with a flow target. (stage 3: RestartGame)"""
        s = self.state
        s.picture5 = (0, 0)             # the dawn's picture 5 back to night (F77)
        things, locations, timers, npcs, saved = copy.deepcopy(self.backup)
        s.things, s.locations, s.timers, s.npcs = things, locations, timers, npcs
        for k, value in saved.items():
            setattr(s.vars, k, value)
        s.screen.border = 0
        yield WaitKey()                 # the title key
        s.vars.pictures_enabled = yield TitleKey()
        t = s.terminal
        t.input_cursor, t.input_glyph = 0, CURSOR_GLYPH
        t.story_cursor, t.story_pixel = 0, 1
        t.input_column, t.story_column = INPUT_COLUMNS, STORY_COLUMNS
        s.orders = [Order(0, Phrase([0] * 12)) for _ in range(ORDER_SLOTS)]   # no orders
        s.vars.random_seed = yield ReadR()
        t.list_indent = t.story_last_char = 0
        s.vars.awaiting_answer = s.vars.lisp = s.vars.printer_on = 0
        s.vars.messages_visible = s.vars.action_perform = s.vars.capital_next = 1
        s.vars.score = 0
        words.clear_screen(s)
        tile = self.tables['border_tile']           # the rule between the windows
        for line in range(5):
            for col in range(32):
                s.screen.set_byte(col, RULE_ROW_Y + line, tile[2 * line + (col & 1)])
        t.no_pause_lines = OPENING_LINES            # the opening text does not pause
        if s.vars.parser_word_count + 1 & 0xFF:     # not $FF: no automatic LOOK (never seen)
            return (yield from self.main_loop())
        yield from engine.init_new_game(s)          # AutoLook
        for ch in self.tables['start_command']:     # "> LOOK" in the input window
            terminal.print_input_window_char(s, ch)
        line = bytearray(self.tables['look_command']).ljust(INPUT_LINE_SIZE + 1, b'\0')
        target = yield from self.build_word_list(line)
        if target:
            return target
        return (yield from self.main_loop())

    def main_loop(self):
        """Read a line ("@" repeats the previous one), make its word list, parse
        and run its sentences; a Step at the top of every pass. (stage 3: MainLoop)"""
        s = self.state
        while True:
            yield Step()
            s.vars.parser_flag = 1
            s.terminal.no_pause_lines = TURN_NO_PAUSE_LINES
            repeat, line = yield from self.read_line()
            if repeat:
                target = yield from self.run_word_list()
            else:
                target = yield from self.build_word_list(line)
            if target:
                return target

    def build_word_list(self, line):
        """The typed line as tokens in s.parsed_words (high byte first), a
        double quote opening and closing an order (a THEN token ends it); an
        unknown word, or a line that ends inside quotes, is reported. Then the
        sentences are run. (stage 3: BuildWordList)"""
        s = self.state
        s.parsed_words = [0] * PARSED_WORDS_SIZE
        pos, i = 0, 0
        while True:
            token, pos, start = words.read_typed_word(s, line, pos)
            hi, lo, cls = token >> 8, token & 0xFF, token >> 8 & 0xF0
            if cls == TOKEN_UNKNOWN:
                return (yield from self.unknown_word(line, start))
            if cls == TOKEN_QUOTE and not token & 0x0FFF:
                if not s.vars.input_from_order:
                    s.vars.input_from_order = 1             # an opening quote
                else:
                    s.vars.input_from_order = 0             # a closing quote: end the order
                    if s.parsed_words[i - 2] & 0xF0 not in (TOKEN_THEN, TOKEN_AND):
                        self.store(i, TOKEN_THEN, 0)
                        i += 2
            self.store(i, hi, lo)
            i += 2
            if cls == TOKEN_END:
                break
        if s.vars.input_from_order:                         # the line ended inside quotes
            s.vars.input_from_order = 0
            yield from parser.print_what(s)
            return None
        return (yield from self.run_word_list())

    def store(self, i, hi, lo):
        """A token into the word list. More than 32 tokens run past its end in
        the original, over code (F71); here the list grows (a deviation)."""
        w = self.state.parsed_words
        while len(w) < i + 2:
            w.append(0)
        w[i], w[i + 1] = hi, lo

    def run_word_list(self):
        """Parse the next sentence of the word list and run it, until the list is
        used up (parser_flag 0) or a sentence is refused. (stage 3: RunWordList)"""
        s = self.state
        s.scratch['word_pos'] = 0                           # WordListPtr: the first token
        while True:
            ok = yield from parser.parse_line(s)
            if not ok:
                return None                                 # refused: drop the line
            target = yield from parser.run_sentences(s)
            if target:
                return target
            if not s.vars.parser_flag:
                return None

    def unknown_word(self, line, start):
        """`I do not know the word "..."` in the input window. (stage 3: UnknownWord)"""
        s = self.state
        s.vars.raw_output = 1
        yield from text.print_message(s, 'MsgIDoNotKnow', [])
        pos = start
        while True:
            ch = line[pos]
            if ch in (CHAR_CR, CHAR_QUOTE):
                break
            yield from terminal.put_char(s, ch)
            pos += 1
            if ch == CHAR_SPACE:
                break
        yield from terminal.put_char(s, CHAR_QUOTE)
        yield from terminal.new_line(s)
        return None

    def read_line(self):
        """A typed line, echoed after the prompt: letters, digits, space, CR,
        quote, full stop, comma; DELETE starts again, back-space rubs out; "@"
        on an empty line repeats the previous line. Returns (repeat, line).
        (stage 3: ReadLine)"""
        s = self.state
        s.vars.raw_output = s.vars.action_perform = 1
        yield from terminal.put_char(s, CHAR_PROMPT)
        yield from terminal.put_char(s, CHAR_SPACE)
        line, pos, first = bytearray(INPUT_LINE_SIZE + 1), 0, True
        while True:
            key, pos = yield from words.wait_key(s, line, pos)
            if pos == 0 and key == CHAR_AT:                 # "@" on an empty line
                if (yield from words.l6e7a(s)):
                    return True, line
                continue
            if first:                                       # the first key may be an arrow
                key, pos = yield from words.cursor_key_to_word(s, key, line, pos)
            first = False
            if key == KEY_DELETE:
                pos = yield from words.erase_input_line(s, pos)
                first = True
                continue
            if key == CHAR_BACKSPACE:
                if pos:
                    yield from terminal.put_char(s, CHAR_BACKSPACE)
                    pos -= 1
                continue
            if not (key >= CHAR_AT or key in (CHAR_QUOTE, CHAR_SPACE, CHAR_CR, CHAR_FULLSTOP,
                                               CHAR_COMMA)):
                continue                                    # anything else is ignored
            s.vars.capital_next = key
            if pos < INPUT_LINE_SIZE:                       # room left: echo and store
                yield from terminal.put_char(s, key)
                line[pos] = key
                pos += 1
            if key == CHAR_CR:
                return False, line
