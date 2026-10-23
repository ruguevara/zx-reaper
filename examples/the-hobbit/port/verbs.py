"""Ported from src/verbs.asm: look, take, drop, move, run, follow, inventory, open, attack, put, give, examine.
Values pass in the registers `r` (port/regs.py); conventions: port/CONTRACT.md."""
from labels import *  # noqa: F403  (first: port functions shadow routine labels)
import calls  # noqa: F401
from regs import r  # noqa: F401
from variables import v  # noqa: F401
from zxpyxel import Goto, mem, mem16, zx  # noqa: F401
