"""Hungry Horace on zxpyxel (stage 3 spike). From port/: python play.py

Needs labels.py and image.bin (tools/zxport.py) and the zxpyxel package
(a copy here, or zx-reaper on PYTHONPATH)."""
import os

from main import Start
from zxpyxel import zx
from zxpyxel.pyxel_host import run

zx.reset(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'image.bin'), 'rb').read())
run(Start, title='Hungry Horace')
