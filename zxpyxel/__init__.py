"""zxpyxel: a stand-in for the 48K Spectrum for ported and new games, on Pyxel.
Design: docs/port.md in zx-reaper.

    from zxpyxel import zx, mem
"""
from .machine import T_FRAME, djnz_t, zx

mem = zx.mem
