"""Stage 4 sprites.py <-> stage 3 routines."""
from horace import sprites

from routines import none

ROUTINES = {
    'EraseSprites': (lambda s, a: sprites.erase_sprites(s), none),
    'EatObject': (lambda s, a: sprites.eat_object(s), none),
    'ShowScore': (lambda s, a, value: sprites.show_score(s, value), lambda hl: (hl,)),
    'DrawGuards': (lambda s, a: sprites.draw_guards(s), none),
}
