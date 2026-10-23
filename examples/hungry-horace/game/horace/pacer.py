"""Runs the game's steps in real time for a host: a Show holds the state as
it is then for its seconds, sounds are synthesised as they come."""
from . import controls, sounds
from .flow import Game
from .render import render
from .state import Sound

FRAME = 1 / 50


class Pacer:
    def __init__(self, display, rate, pcm):
        """`pcm(edges, t, rate)`: speaker edges -> PCM bytes (zxpyxel.sound)."""
        self.game, self.display, self.rate, self.pcm = Game(), display, rate, pcm
        self.step, self.hold = None, 0.0

    def update(self, keys):
        """One host frame with the ZX keys held; returns the PCM to play."""
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
                audio += self.pcm(edges, t, self.rate)
            else:
                self.hold += event.seconds
                render(self.game.state, self.display)
        return audio
