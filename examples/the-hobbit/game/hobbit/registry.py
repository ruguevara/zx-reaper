"""Handlers by name: the original keeps routine addresses in its tables (verb
tables, timers, arrivals, NPC script routines); the stage 4 state keeps the
stage 3 routine's name, and each module registers the function that stands
for it: `@registry.handler('VerbTake')`."""
HANDLERS = {}


def handler(*names):
    def register(f):
        for n in names:
            HANDLERS[n] = f
        return f
    return register
