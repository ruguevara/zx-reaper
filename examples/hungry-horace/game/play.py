"""Hungry Horace, stage 4, on Pyxel. From the project root: python game/play.py

Needs game/assets.json (make game/assets.json). Keys as on the Spectrum (Q up,
Z down, I left, P right, T sound) or the arrows."""
import pyxel

from horace.pacer import Pacer
from zxpyxel import sound
from zxpyxel.display import Display
from zxpyxel.pyxel_host import RATE, run_display

pacer = Pacer(Display(), RATE, lambda edges, t, rate: sound.pcm(edges, 0, 0, t, rate)[0])
run_display(pacer.update, pacer.display, title='Hungry Horace',
            keymap={pyxel.KEY_UP: 'Q', pyxel.KEY_DOWN: 'Z', pyxel.KEY_LEFT: 'I', pyxel.KEY_RIGHT: 'P'})
