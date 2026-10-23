"""Hungry Horace, stage 4, on Pyxel. From the project root: python game/play.py

Needs game/assets.json (make game/assets.json). Keys as on the Spectrum (Q up,
Z down, I left, P right, T sound) or the arrows."""
import pyxel

from horace import controls, sounds
from horace.flow import Game
from horace.render import render
from horace.state import Sound
from zxpyxel import sound as pcm
from zxpyxel.display import Display
from zxpyxel.pyxel_host import RATE, run_display

FRAME = 1 / 50
CLOCK = 3500000


class Pacer:
    """Runs the game's steps at the original's pace: a Show holds the state
    as it is then for its seconds; sounds play as they come."""

    def __init__(self):
        self.game, self.display = Game(), Display()
        self.step, self.hold = None, 0.0

    def update(self, keys):
        audio = b''
        self.hold -= FRAME
        while self.hold <= 0:
            if self.step is None:
                self.step = self.game.step(controls.actions(keys))
            try:
                event = next(self.step)
            except StopIteration:
                self.step = None
                continue
            if isinstance(event, Sound):
                edges, t = sounds.edges(event)
                audio += pcm.pcm(edges, 0, 0, t, RATE)[0]
            else:
                self.hold += event.seconds
                render(self.game.state, self.display)
        return audio


pacer = Pacer()
run_display(pacer.update, pacer.display, title='Hungry Horace',
            keymap={pyxel.KEY_UP: 'Q', pyxel.KEY_DOWN: 'Z', pyxel.KEY_LEFT: 'I', pyxel.KEY_RIGHT: 'P'})
