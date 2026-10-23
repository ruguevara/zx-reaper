"""Ported from src/keys.asm: typed words to tokens, the command table helpers, WaitKey and the WAIT time-out.
Values pass in the registers `r` (port/regs.py); conventions: port/CONTRACT.md."""
from labels import *  # noqa: F403  (first: port functions shadow routine labels)
import calls  # noqa: F401
from regs import r  # noqa: F401
from variables import v  # noqa: F401
from zxpyxel import Goto, mem, mem16, zx  # noqa: F401
