"""The Hobbit, stage 4 (clean logic, the Spectrum's look). From the project
root: python game/play.py (needs game/assets/: make game/assets/state.json).

Type as on the Spectrum: letters, digits, space, Enter; comma, full stop,
quote and @ type their Spectrum symbols; Backspace rubs out, Delete starts the
line again; the arrows move north, south, east and west (the Spectrum's 5-8).
Hold N while pressing a key at the title for no pictures. SAVE and LOAD use
hobbit.sav, PRINT copies the story to hobbit.txt."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import pyxel  # noqa: E402

from hobbit.pacer import Pacer  # noqa: E402
from zxpyxel.display import Display  # noqa: E402
from zxpyxel.pyxel_host import run_display  # noqa: E402

display = Display()
run_display(Pacer(display).update, display, title='The Hobbit',
            keymap={pyxel.KEY_COMMA: 'SS N', pyxel.KEY_PERIOD: 'SS M', pyxel.KEY_QUOTE: 'SS P',
                    pyxel.KEY_AT: 'SS 2', pyxel.KEY_BACKSPACE: 'CS 5', pyxel.KEY_DELETE: 'CS 0',
                    pyxel.KEY_LEFT: '5', pyxel.KEY_DOWN: '6', pyxel.KEY_UP: '7', pyxel.KEY_RIGHT: '8'})
