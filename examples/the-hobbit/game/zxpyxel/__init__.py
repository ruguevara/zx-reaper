"""zxpyxel: a stand-in for the 48K Spectrum for ported and new games, on Pyxel.
Design: docs/stage3.md in zx-reaper.

    from zxpyxel import zx, mem, mem16
"""
from .machine import T_FRAME, Goto, dispatch, djnz_t, zx

mem = zx.mem
mem16 = zx.mem16
