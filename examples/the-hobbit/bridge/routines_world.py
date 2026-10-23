"""Stage 3 objects.py -> stage 4 hobbit/world.py, for bridge/oracle.py routine.

Records in IX/IY become ids (decode.which), a name phrase at HL/IY its three
codes, a walk position in IX a cursor (an index; -1 before the first), an
exit in IX the Exit (None for $FF)."""
import paths  # noqa: F401
import labels as L
from decode import name, record_starts, which, word
from routines import ANY, nothing
from hobbit import world as W
from hobbit.state import Exit
from zxpyxel import mem


def rec(ptr):
    """The id of the record at ptr (a thing or a location), None if it is none."""
    try:
        return which(ptr)[1]
    except KeyError:
        return None


def phrase(ptr):
    return [word(mem, ptr + 2 * k) for k in range(3)]


def _start(ptr, kind):
    """The start of the record of that kind that contains ptr."""
    return max(a for a, (k, _) in record_starts().items() if k == kind and a <= ptr)


def exit_cursor(ix):
    return (ix - _start(ix, 'location') - 10) // 3


def exit_out(regs):
    return None if regs.a == 0xFF else Exit(mem[regs.ix], mem[regs.ix + 1], mem[regs.ix + 2])


def verb_index(regs):
    if regs.zf:
        return None
    a = _start(regs.ix, 'thing')
    return (regs.ix - a - 16 - mem[a]) // 3


def a(regs):
    return (regs.a,)


def ret_a(regs):
    return regs.a


def found(regs):
    return not regs.zf


def anything(regs):
    return ANY


ROUTINES = {
    # lookups
    'FindObject': (lambda s, i: getattr(W.thing(s, i), 'id', None), a,
                   lambda regs: None if regs.a == 0xFF else rec(regs.ix)),
    'FindLocation': (lambda s, i: getattr(W.location(s, i), 'id', None), a, lambda regs: rec(regs.ix)),
    'FindVerbEntry': (W.verb_entry, lambda regs: (rec(regs.ix), regs.a), verb_index),
    'LA1AE_2': (W.living, lambda regs: (rec(regs.ix),), lambda regs: regs.zf),
    'FindNextNamedObject': (W.next_named_thing,
                            lambda regs: (phrase(regs.hl), (regs.ix - L.ObjectTable) // 3),
                            lambda regs: (regs.a, (regs.ix - L.ObjectTable) // 3)),
    # holders, weights, room
    'CheckObject1Held': (W.first_object_held, lambda regs: (), lambda regs: regs.cf),
    'CheckHeldBySubject': (W.held_by_subject, a, lambda regs: regs.cf),
    'CheckObject1Held_0': (W.held_by, lambda regs: (regs.a, mem[regs.hl]), lambda regs: regs.cf),
    'WalkHolderChain': (W.held_by, lambda regs: (regs.a, mem[regs.hl]), lambda regs: regs.cf),
    'FindClosedHolder': (W.closed_holder, lambda regs: (rec(regs.ix),), ret_a),
    'CanReach': (W.can_reach, lambda regs: (rec(regs.ix), rec(regs.iy)), found),
    'ActorCanReach': (W.actor_can_reach, lambda regs: (rec(regs.iy),), found),
    'CanReachSwapped': (W.can_reach, lambda regs: (rec(regs.iy), rec(regs.ix)), found),
    'SumHeldWeight': (W.held_weight, a, ret_a),
    'SumHeldBulk': (W.held_bulk, a, ret_a),
    'SumHeldRecords': (W.sum_held, lambda regs: (regs.a, regs.b != 0, regs.c), lambda regs: regs.c),
    'LocationSpareCapacity': (W.spare_capacity, a, ret_a),
    'CountHeldPresent': (W.count_held_present, a, ret_a),
    'GetSingleLocation': (W.single_location, a, ret_a),
    'GetActorLocationRec': (W.actor_location, lambda regs: (), lambda regs: rec(regs.ix)),
    # exits
    'FindExitByDirection': (W.exit_by_direction, a, exit_out),
    'FindExitByObstacle': (lambda s: W.exit_by_obstacle(s, s.vars.first_object), lambda regs: (), exit_out),
    'FindExitByObstacle_0': (W.exit_by_obstacle, a, exit_out),
    'FindExitByDestination': (W.exit_by_destination, a, exit_out),
    'FindExitByName': (W.next_named_exit, lambda regs: (phrase(regs.hl), exit_cursor(regs.ix)),
                       lambda regs: (regs.a, exit_cursor(regs.ix))),
    # changes
    'MoveContents': (W.move_contents, lambda regs: (regs.a, regs.b), nothing),
    'MoveCarried': (W.move_carried, lambda regs: (regs.a, regs.b, rec(regs.iy)), nothing),
    'MarkBrokenOrDead': (W.mark_broken_or_dead, a, nothing),
    'EmptyHolder': (W.empty_holder, a, nothing),
    'EmptyFirstObject': (lambda s: W.empty_holder(s, s.vars.first_object), lambda regs: (), nothing),
    'CommitOrAbort': (W.commit_or_abort, lambda regs: (), anything),
    'RandomSigned': (W.random_signed, a, ret_a),
    'RandomUpTo': (W.random_up_to, a, ret_a),
    # handlers and commands
    'CheckNounsDistinct': (W.same_object_twice, lambda regs: (), lambda regs: regs.zf),
    'CallHandler': (W.call_handler, lambda regs: (name(regs.hl),), anything),
    'L9F4A': (W.call_swapped, lambda regs: (name(regs.hl),), anything),
    'NpcHeld': (W.npc_held, lambda regs: ((regs.iy - L.NpcStates) // 7,), anything),
    'RefuseCommand': (W.refuse_command, lambda regs: (), anything),
    # printing
    'GetIdWord': (lambda s, i: W.id_word(i), a, lambda regs: regs.de),
    'PrintObjectName': (W.print_object_name, lambda regs: (rec(regs.iy),), nothing),
    'PrintHolderRelation': (W.print_holder_relation, lambda regs: (rec(regs.ix),), nothing),
    'PrintStateIX': (W.print_state, lambda regs: (rec(regs.ix), regs.a), nothing),
    'PrintStateIY': (W.print_state, lambda regs: (rec(regs.iy), regs.a), nothing),
    'PrintContentsHeader': (W.print_contents_header, a, lambda regs: not regs.cf),
    'ListHolderContents': (W.list_holder_contents, lambda regs: (regs.a, regs.b, regs.d, regs.c),
                           lambda regs: regs.c),
    'ListObjects': (W.list_objects, lambda regs: (regs.a, regs.b), nothing),
    'ListObjectsHere': (W.list_objects_here, lambda regs: (), nothing),
    'ListExitObstacles': (W.list_exit_obstacles, a, nothing),
    'ListVisibleExits': (W.list_visible_exits, a, nothing),
}
