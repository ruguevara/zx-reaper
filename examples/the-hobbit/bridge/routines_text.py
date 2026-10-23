"""Stage 3 printer.py (and PrintCommandSentence, StartPerform of keys.py,
PrintNamePhrase of objects.py) -> stage 4 hobbit/text.py, for bridge/oracle.py
routine.

The message arguments: stage 3 pops printer.msg_args while it prints, so the
list as it was when PrintMessage began is noted here (PrintMessage wrapped,
transparently) and given to the stage 4 routine. Two stand-ins until the other
slices have them: the decoded state carries Vars.subj_is_in (the word in the
message MsgSubjIsIn) when state.py has no such field yet, and
hobbit.engine.check_dark is stage 3's CheckDark on its memory when there is no
hobbit.engine with it yet."""
import functools
import importlib
import sys
import types

import paths  # noqa: F401
import labels as L
import printer as port_printer
from regs import r
from routines import ANY, none
from routines_terminal import keep_registers
from zxpyxel import mem
from hobbit import text as T
from hobbit.state import Vars

# ---- the message names and arguments ------------------------------------

@functools.lru_cache(None)
def message_names():
    import assets_text
    from assets import image
    m = image()
    return assets_text.message_names(m, assets_text.T.Text(bytes(m)))


def message(hl):
    return message_names()[hl]


_orig_print_message, _args = port_printer.PrintMessage, [[]]


@functools.wraps(_orig_print_message)
async def _print_message():
    args = list(port_printer.msg_args)
    await _orig_print_message()
    _args[0] = args                 # read by the oracle right after the call returns


port_printer.PrintMessage = _print_message


def pops(name):
    """The control codes of message `name` that pop an argument, in print order."""
    out = []
    for it in T.MESSAGES[name]:
        if it[0] == 'code' and it[1] in (0, 1, 4, 19):
            out.append(it[1])
        elif it[0] in ('call', 'goto'):
            out += pops(it[1])
    return out


def args(name):
    """The arguments stage 3 had pushed for message `name`, in stage 4 terms:
    a name phrase's address (code 0) becomes its three codes."""
    out = list(_args[0])
    for k, code in enumerate(pops(name)):
        i = len(out) - 1 - k
        if code == 0 and out[i]:
            out[i] = [word16(out[i] + 2 * j) for j in range(3)]
    return out


def word16(a):
    return mem[a] | mem[a + 1] << 8


# ---- stand-ins for what other slices will provide ------------------------

if 'subj_is_in' not in Vars.__dataclass_fields__:       # until the lead adds the field
    import decode as _decode_module
    _decode = _decode_module.decode

    def _decode_with_slot(m, border=0):
        s = _decode(m, border)
        s.vars.subj_is_in = (m[L.MsgSubjIsIn + 1] & 0x0F) << 8 | m[L.MsgSubjIsIn + 2]
        return s
    _decode_module.decode = _decode_with_slot
    for _m in list(sys.modules.values()):
        if getattr(_m, 'decode', None) is _decode:
            _m.decode = _decode_with_slot

try:
    _engine = importlib.import_module('hobbit.engine')
except ImportError:
    _engine = None
if not hasattr(_engine, 'check_dark') and sys.argv[1:2] == ['routine']:
    def _stage3_dark(s):
        """CheckDark of stage 3 on its memory (unchanged by the routines that ask)."""
        import engine as port_engine

        def run():
            port_engine.CheckDark()
            return r.cf
        return keep_registers(run)
    _engine = types.ModuleType('hobbit.engine')
    _engine.check_dark = _stage3_dark
    sys.modules['hobbit.engine'] = _engine
    import hobbit
    hobbit.engine = _engine


def echo():
    return bool(mem[L.EchoingCommand])


ROUTINES = {
    'PrintMessage': (T.print_message, lambda regs: (message(regs.hl), args(message(regs.hl))), lambda regs: ANY),
    'PrintParserMessage': (T.print_parser_message, lambda regs: (message(regs.hl), args(message(regs.hl))),
                           lambda regs: ANY),
    'PrintCannotDoThat': (T.print_cannot_do_that, none, lambda regs: ANY),
    'PrintMessageChar': (T.print_message_char, lambda regs: (regs.a,), lambda regs: ANY),
    'PrintWord': (T.print_word, lambda regs: (regs.de & 0xFFF, regs.d >> 4), lambda regs: ANY),
    'PrintArticle': (T.print_article, lambda regs: (regs.de, echo()), lambda regs: ANY),
    'PrintNounWord': (T.print_noun_word, lambda regs: (regs.de, echo()), lambda regs: ANY),
    'PrintNamePhrase': (T.print_name_phrase,
                        lambda regs: ([word16(regs.iy + 2 * k) for k in range(3)], echo()),
                        lambda regs: ANY),
    'PrintActorName': (T.print_actor_name, lambda regs: (regs.a, echo()), lambda regs: ANY),
    'PrintSubjectName': (T.print_subject_name, none, lambda regs: ANY),
    'PrintFirstObjectNameAsIs': (T.print_first_object_name, lambda regs: (echo(),), lambda regs: ANY),
    'PrintSecondObjectNameAsIs': (T.print_second_object_name, lambda regs: (echo(),), lambda regs: ANY),
    'PrintCommandSentence': (T.print_command_sentence, none, lambda regs: ANY),
    'StartPerform': (T.start_perform, none, lambda regs: ANY),
}
