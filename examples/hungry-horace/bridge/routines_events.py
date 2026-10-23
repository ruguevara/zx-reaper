"""Stage 4 events.py <-> stage 3 routines."""
from horace import events

from routines import none

ROUTINES = {
    'CheckGuardContact': (lambda s, a: events.check_guard_contact(s), none),
    'HoraceDies': (lambda s, a: events.horace_dies(s), none),
    'GameOver': (lambda s, a: events.game_over(s), none),
    'DrawHorace': (lambda s, a: events.draw_horace(s), none),
    'UpdateBell': (lambda s, a: events.update_bell(s), none),
    'UpdateFruitDrops': (lambda s, a: events.update_fruit_drops(s), none),
    'TickGuardTimers': (lambda s, a: events.tick_guard_timers(s), none),
    'CheckSoundKey': (lambda s, a: events.check_sound_key(s, a), none),
    'PaceAndChime': (lambda s, a: events.pace_and_chime(s), none),
    'ResetGuardTimers': (lambda s, a: events.reset_guard_timers(s), none),
}
