"""Hungry Horace on zxpyxel (stage 3). From the project root: python port/play.py

Needs labels.py, variables.py and image.bin (make port/labels.py
port/variables.py port/image.bin). Keys as on the Spectrum (Q up, Z down,
I left, P right, T sound) or the arrows."""
import os

import pyxel

from main import Start
from zxpyxel import zx
from zxpyxel.pyxel_host import run

zx.reset(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'image.bin'), 'rb').read())
run(Start, title='Hungry Horace',
    keymap={pyxel.KEY_UP: 'Q', pyxel.KEY_DOWN: 'Z', pyxel.KEY_LEFT: 'I', pyxel.KEY_RIGHT: 'P'})
