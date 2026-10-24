"""Stage 3 engine.py -> stage 4 hobbit/engine.py, for bridge/oracle.py routine.

An NPC record in IY becomes its slot (an index into s.npcs), a script command
in IX its index in s.program, a message in HL or DE its name, a record in IX
('thing'|'location', id) as decode.which gives it. The stage 3 interpreter's
steps ('next', 'script', 'command') are compared as they are returned."""
import paths  # noqa: F401
import labels as L
from decode import program, which
from routines import none, nothing
from hobbit import engine as E
from routines_text import message
from zxpyxel import mem


def slot(regs):
    return (regs.iy - L.NpcStates) // 7


def command(regs):
    """The program index of the script command at IX."""
    return program(mem)[2][regs.ix]


def a(regs):
    return (regs.a,)


ROUTINES = {
    # the dark, commands
    'CheckDark': (E.check_dark, none, lambda regs: regs.cf),
    'UpdatePlayerSight': (E.update_player_sight, none, nothing),
    'AbortUnlessPerform': (E.abort_unless_perform, none, lambda regs: regs.a != 0),
    'CheckVerbApplies': (E.check_verb_applies, none, lambda regs: regs.a),
    'DispatchCommand': (E.dispatch_command, none, nothing),
    'CheckHeldByOther': (E.check_held_by_other, a, lambda regs: not regs.zf),
    'NotifyCharacter': (E._notify, lambda regs: (which(regs.ix), regs.a, regs.b), nothing),
    # locations
    'DescribeLocation': (E.describe_location, a, nothing),
    'DescribeSeen': (E.describe_seen, a, nothing),
    'DescribeLocation_Intro': (E.describe_location_intro, lambda regs: (regs.a, message(regs.hl)), nothing),
    'ShowLocation': (E.describe_location_intro, lambda regs: (regs.a, message(regs.hl)), nothing),
    'ShowLocation_Lists': (E.show_location_lists, lambda regs: (regs.b,), nothing),
    'PrintLocationName': (E.print_location_name, lambda regs: (which(regs.ix)[1],), nothing),
    'DescribeLocationShort': (E.describe_location_short, a, nothing),
    'PrintMessageDot': (E.print_message_dot, lambda regs: (message(regs.hl),), nothing),
    # the turn, the scripts
    'EndTurn_Timer': (E.end_turn, none, nothing),
    'RunNpcScripts': (E.run_npc_scripts, none, nothing),
    'RunNpcScripts_Start': (E.run_npc_scripts_start, lambda regs: (slot(regs),), nothing),
    'RunNpcScripts_Next': (E.run_npc_scripts_next, lambda regs: (slot(regs),), nothing),
    # RunScriptCommand, RunScriptVerb and ScriptCommandFailed return the interpreter's
    # next step: the oracle's wrapper of an async routine drops the return value (and
    # stage 3 then goes wrong), so they are checked through RunNpcScripts
    'ChooseRandomScript': (E.choose_random_script, lambda regs: (slot(regs), command(regs)), nothing),
    'SelectScript': (E.select_script, lambda regs: (slot(regs), regs.e), nothing),
    'FindNpcState': (E.find_npc, a, lambda regs: None if regs.a == 0xFF else slot(regs)),
    'SwitchNpcScript': (E.switch_npc_script, lambda regs: (regs.a, regs.b), nothing),
    'RunActorCommand': (E.run_actor_command, none, lambda regs: not regs.zf),
    'RunActorCommand_Run': (E.run_actor_command_run, none, lambda regs: True),
    'AnnounceArrival': (E.announce_arrival, lambda regs: (regs.a, mem[regs.hl], message(regs.de)), nothing),
    # death, a new game
    'KillCharacter': (E.kill_character, a, nothing),
    'L977C': (E.kill_first_object, none, nothing),
    'InitNewGame': (E.init_new_game, none, nothing),
}
