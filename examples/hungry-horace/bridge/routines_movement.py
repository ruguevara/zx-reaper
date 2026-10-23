"""Stage 4 movement (game/horace/movement.py) for stage 3's port/movement.py."""
from horace import movement
from routines import none

ROUTINES = {'ReadControls': (lambda s, a: movement.read_controls(s, a), none),
            'PlanMoves': (lambda s, a: movement.plan_moves(s), none)}
