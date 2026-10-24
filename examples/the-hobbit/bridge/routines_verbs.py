"""Stage 3 verbs.py -> stage 4 hobbit/verbs.py, for bridge/oracle.py routine.

The handlers take no registers (their inputs are the variables) and return
None or a flow target. Not registered: RequireHeld, CheckCanCarry and
CheckCanCarry_Single are coroutines that return a value, which the oracle's
wrapper of a coroutine drops (stage 3 would then go wrong): they are checked
through their callers. Tails that are a line of their caller (ActorArrives_2,
_3, _4, StrikeObject_4, CheckSinglePlace) are checked through it."""
import paths  # noqa: F401
import labels as L
from decode import which
from routines import nothing
from routines_world import a, rec, ret_a
from hobbit import verbs as V
from hobbit.state import Exit
from zxpyxel import mem

TIMER_SIZE, TIMER_COUNT = 7, 10


def arriving(iy):
    """The asm's IY at ActorArrives: a thing's id, or ('timer', k) for timer k's
    record (F85)."""
    if L.Timers <= iy < L.Timers + TIMER_SIZE * TIMER_COUNT and (iy - L.Timers) % TIMER_SIZE == 0:
        return ('timer', (iy - L.Timers) // TIMER_SIZE)
    kind, id = which(iy)
    if kind != 'thing':
        raise ValueError('ActorArrives with IY at location %d' % id)
    return id


def exit_at(regs):
    """WalkToExit's exit: IX, or None when A is $FF."""
    return (None if regs.a == 0xFF else Exit(mem[regs.ix], mem[regs.ix + 1], mem[regs.ix + 2]),)


def handler(f):
    return (f, lambda regs: (), nothing)


ROUTINES = {name: handler(V.__dict__[f]) for name, f in {
    'VerbLook': 'verb_look', 'VerbDrop': 'verb_drop', 'L8CE0': 'take_out_of', 'VerbTake': 'verb_take',
    'VerbTake_0': 'verb_take_0', 'VerbMove': 'verb_move', 'MoveActor': 'move_actor',
    'MoveActor_NoWay': 'move_actor_no_way', 'ActorArrives_0': 'actor_arrives_describe',
    'VerbLookThrough': 'verb_look_through', 'VerbLookThrough_0': 'verb_look_through_0',
    'L8F3B': 'go_through', 'L8F69': 'put_into', 'VerbRun': 'verb_run', 'L8FCD': 'enter',
    'VerbFollow': 'verb_follow', 'L8FF5': 'throw_at', 'TalkToCharacter': 'talk_to_character',
    'L9065': 'open_or_close', 'OpenObject': 'open_object', 'CloseObject': 'close_object',
    'VerbAttack': 'verb_attack', 'L9065_0': 'shoot', 'StrikeObject': 'strike_object',
    'PutObjectIn': 'put_object_in', 'GiveObject': 'give_object', 'ExamineObject': 'examine_object',
    'L929C': 'eat', 'L929C_0': 'eat_lying', 'L9404': 'empty', 'L9404_1': 'send_down_river',
    'L9404_5': 'lock', 'L9404_7': 'unlock', 'L9404_8': 'put_through',
    'VerbInventory': 'verb_inventory', 'EndGame': 'end_game', 'EndGame_Wait': 'end_game_wait',
}.items()}

ROUTINES.update({
    'ActorArrives': (V.actor_arrives, lambda regs: (arriving(regs.iy), regs.b), nothing),
    'CheckPassage': (V.check_passage, a, ret_a),
    'CheckEnclosed': (V.check_enclosed, a, lambda regs: not regs.zf),
    'WalkToExit': (V.walk_to_exit, exit_at, nothing),
    'CheckAttackAllowed': (V.check_attack_allowed, lambda regs: (), lambda regs: regs.zf),
    'RollStrength': (V.roll_strength, a, ret_a),
    'L929C_1': (V.eat_meal, a, nothing),
    'OpenObject_0': (V.open_thing, lambda regs: (rec(regs.ix),), nothing),
    'CloseObject_Clear': (V.close_thing, lambda regs: (rec(regs.ix),), nothing),
    'L9404_6': (V.lock_with_key, lambda regs: (regs.a == 0xC6,), nothing),
    'SmcSetOrRes': (V.set_locked, lambda regs: (rec(regs.ix), mem[L.SmcSetOrRes + 3] == 0xC6),
                    nothing),
})
