"""The state onto a zxpyxel.display: every cell, every pass (768 cells are
cheap), in the Spectrum's layout, so a screen compares byte for byte."""
from .constants import COLS, WHITE


def render(s, display):
    for i, c in enumerate(s.cells):
        display.cell(i % COLS, i // COLS, c.glyph, c.attr)
    display.border = WHITE
