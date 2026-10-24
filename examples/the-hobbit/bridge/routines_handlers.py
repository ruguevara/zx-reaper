"""Stage 3 handlers.py and world.py -> stage 4 hobbit/handlers.py, for
bridge/oracle.py routine.

The table handlers take the state only; three take what the asm passes in a
register: RespawnKilledGoblin and LA814 the dispatcher's B, SpiderEyesFromHL
the message at HL (its own address when a timer runs it: the message
'SpiderEyesFromHL'). PrintSpeech's message arguments are the stage 3 stack as
it was when PrintSpeech began (noted here by a transparent wrapper)."""
import functools

import paths  # noqa: F401
import labels as L
import handlers as port_handlers
import world as port_world  # noqa: F401  (the arrivals: the oracle looks in the port modules loaded)
import printer as port_printer
import routines_text as RT
from routines import none, nothing
from routines_world import rec
from hobbit import handlers as H, registry

# ---- PrintSpeech's arguments ---------------------------------------------

_orig_speech, _speech_stack = port_handlers.PrintSpeech, [[]]


@functools.wraps(_orig_speech)
async def _print_speech():
    _speech_stack[0] = list(port_printer.msg_args)
    return await _orig_speech()


port_handlers.PrintSpeech = _print_speech


def message(hl):
    """The message at HL; SpiderEyesFromHL's own address prints its code."""
    return 'SpiderEyesFromHL' if hl == L.SpiderEyesFromHL else RT.message(hl)


def speech(regs):
    name = message(regs.hl)
    out = list(_speech_stack[0])
    for k, code in enumerate(RT.pops(name)):
        i = len(out) - 1 - k
        if code == 0 and out[i]:
            out[i] = [RT.word16(out[i] + 2 * j) for j in range(3)]
    return name, out


# ---- the routines ------------------------------------------------------------

def b(regs):
    return (regs.b,)


def msg(regs):
    return (message(regs.hl),)


SPECIAL = {
    'RespawnKilledGoblin': (H.respawn_killed_goblin, b, nothing),
    'LA814': (H.la814, b, nothing),
    'SpiderEyesFromHL': (H.spider_eyes, msg, nothing),
    'LA244_10': (H.la244_10, msg, nothing),
    'LA244_15': (H.lock_with_key, b, nothing),
    'LA814_3': (H.below_half, none, lambda regs: regs.cf),
    'LA814_5': (H.la814_5, msg, nothing),
    'LA9E5_8': (H.la9e5_8, msg, nothing),
    'PrintSpeech': (H.print_speech, speech, nothing),
    'IsPlacingCommand': (H.is_placing_command, none, lambda regs: regs.zf),
    'CheckOpen': (H.check_open, lambda regs: (rec(regs.ix),), lambda regs: not regs.zf),
    'CheckOpenable': (H.check_openable, none, lambda regs: (not regs.zf, regs.a)),
    'CheckOpenable_0': (H.check_openable_thing, lambda regs: (rec(regs.ix),),
                        lambda regs: (not regs.zf, regs.a)),
    'CheckVictory': (H.check_victory, none, nothing),
}

ROUTINES = {name: (f, none, nothing) for name, f in registry.HANDLERS.items()
            if f.__module__ == H.__name__}
ROUTINES.update(SPECIAL)
