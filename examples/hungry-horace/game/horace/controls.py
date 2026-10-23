"""The keys held -> Actions. The keys are the original's: Q or 4 up, Z or 3
down, P or 2 right, I or 1 left (the first pair held wins, in that order),
T toggles the sound, any key starts a game or ends the demo."""
from .constants import DIR_DOWN, DIR_LEFT, DIR_NONE, DIR_RIGHT, DIR_UP
from .state import Actions

DIRECTIONS = [(DIR_UP, 'Q4'), (DIR_DOWN, 'Z3'), (DIR_RIGHT, 'P2'), (DIR_LEFT, 'I1')]


def actions(keys):
    """`keys`: the ZX key names held (zxpyxel.keys: 'Q', '4', 'SPACE', 'CS', ...)."""
    direction = next((d for d, pair in DIRECTIONS if keys & set(pair)), DIR_NONE)
    return Actions(any_key=bool(keys), direction=direction, t='T' in keys)
