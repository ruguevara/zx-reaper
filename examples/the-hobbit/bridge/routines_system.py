"""Stage 3 system.py -> stage 4 hobbit/system.py, for bridge/oracle.py routine.

The special words are word-class handlers: each continues the parse to its
end, so each is run from the parser's registers at the call
(routines_parser.special) and compared by the parse's result."""
import paths  # noqa: F401
import system as port_system
from routines import ANY, none
from routines_parser import keep_regs, note, special
from hobbit import system as S

SPECIAL = {'StoreParsedOrders': S.store_parsed_orders, 'BeginOrderPass': S.begin_order_pass,
           'WordAll': S.word_all, 'WordExcept': S.word_except, 'L82E2': S.l82e2, 'WordPrint': S.word_print,
           'L82AF': S.l82af, 'WordQuit': S.word_quit, 'WordHelp': S.word_help, 'L83EF': S.l83ef,
           'WordPause': S.word_pause, 'SaveGame': S.save_game, 'LoadGame': S.load_game,
           'DispatchSpecialWord': S.dispatch_special_word, 'ResumeDispatch': S.resume_dispatch}

ROUTINES = {
    'PrintScore': (S.print_score, none, lambda regs: ANY),
    'DecimalDigit': (lambda s, v, d: S.decimal_digit(v, d), lambda regs: (regs.hl, regs.de),
                     lambda regs: (regs.a, regs.hl)),
}
ROUTINES.update({name: (special(name, f), keep_regs, lambda regs: regs.zf) for name, f in SPECIAL.items()})

note(port_system, SPECIAL)
