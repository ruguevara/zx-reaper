"""The Hobbit on zxpyxel (stage 3). From the project root: python port/play.py

Needs labels.py, variables.py and image.bin (make port/labels.py
port/variables.py port/image.bin). Type as on the Spectrum: letters, digits,
space, Enter; the punctuation keys type their Spectrum symbol (comma, full
stop, quote, @ for the last command again); Backspace rubs out, Delete starts
the line again; the arrows move north, south, east and west (the Spectrum's
5-8). Hold N while pressing a key at the title for no pictures."""
import os

import pyxel

from main import GameStart
from zxpyxel import zx
from zxpyxel.pyxel_host import run

zx.reset(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'image.bin'), 'rb').read())
run(GameStart, title='The Hobbit',
    keymap={pyxel.KEY_COMMA: 'SS N', pyxel.KEY_PERIOD: 'SS M', pyxel.KEY_QUOTE: 'SS P',
            pyxel.KEY_AT: 'SS 2', pyxel.KEY_BACKSPACE: 'CS 5', pyxel.KEY_DELETE: 'CS 0',
            pyxel.KEY_LEFT: '5', pyxel.KEY_DOWN: '6', pyxel.KEY_UP: '7', pyxel.KEY_RIGHT: '8'})
