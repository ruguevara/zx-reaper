"""The game's data as files in game/assets/ (written from the original by
bridge/assets.py, edited by hand after that): JSON, text, PNG and the title
screen. The start state is loaded and checked here."""
import json
import os

from .state import (Command, Exit, GameState, Location, Npc, Order, Phrase, Terminal, Thing,
                    Timer, Vars)
from zxpyxel.display import Display

ROOT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'assets')


def path(name):
    return os.path.join(ROOT, name)


def load_json(name):
    with open(path(name)) as f:
        return json.load(f)


def load_text(name):
    with open(path(name)) as f:
        return f.read()


def screen(border):
    """The title screen: game/assets/title.scr, a Spectrum screen file (6912 bytes)."""
    data = open(path('title.scr'), 'rb').read()
    if len(data) != 6912:
        raise ValueError('title.scr: %d bytes, a screen has 6912' % len(data))
    d = Display()
    d.data[:] = data
    d.border = border
    return d


def _tuple(x):
    return tuple(x) if isinstance(x, list) else x


def state(d=None):
    """The state at the start, from state.json (and the title screen)."""
    d = d or load_json('state.json')
    v = dict(d['vars'])
    for k in ('noun1', 'noun2', 'command_flags'):
        v[k] = _tuple(v[k])
    return GameState(
        vars=Vars(**v),
        locations=[Location(id=x['id'], flags=x['flags'], capacity=x['capacity'], names=x['names'],
                            description=x['description'], exits=[Exit(*e) for e in x['exits']])
                   for x in d['locations']],
        things=[Thing(**{**x, 'verbs': [tuple(e) for e in x['verbs']]}) for x in d['things']],
        npcs=[Npc(**x) for x in d['npcs']],
        timers=[Timer(**x) for x in d['timers']],
        program=[Command(**x) for x in d['program']],
        orders=[Order(owner=x['owner'], phrase=Phrase(x['phrase'])) for x in d['orders']],
        order_count=d['order_count'],
        question=Phrase(d['question']) if d['question'] is not None else None,
        parsed_words=d['parsed_words'], picture5=tuple(d['picture5']),
        terminal=Terminal(**d['terminal']), screen=screen(d['border']))


def dump_state(s):
    """The state as JSON-ready values (the screen is the title, kept apart)."""
    from dataclasses import asdict
    d = asdict(s)
    del d['screen']
    d['border'] = s.screen.border
    for o in d['orders']:
        o['phrase'] = o['phrase']['words']
    if d['question'] is not None:
        d['question'] = d['question']['words']
    for x in d['locations']:
        x['exits'] = [[e['direction'], e['obstacle'], e['destination']] for e in x['exits']]
    return d
