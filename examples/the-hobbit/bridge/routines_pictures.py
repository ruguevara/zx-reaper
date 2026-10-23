"""Stage 3 drawing.py -> stage 4 hobbit/pictures.py, for bridge/oracle.py routine.

  python3 bridge/routines_pictures.py      draws every picture through stage 3
      (port/drawing.py, CheckDark stubbed as lit) and through pictures.py from
      game/assets/pictures/, on the same screen, and compares the screens and
      borders (PicVar1, the lines' ink, 0 as in play); then lists the pictures
      that would differ with PicVar1 $38, its value in the loaded image
"""
import sys

import paths  # noqa: F401
import labels as L
from routines import nothing
from hobbit import pictures as P
from zxpyxel import mem


def _pen(regs):
    return regs.d, regs.e


def _line(regs):
    h, v = 'l' if regs.c & 4 else 'r', 'd' if regs.c & 2 else 'u'
    major, minor = (v, h) if regs.c & 1 else (h, v)
    return regs.d, regs.e, major, minor, regs.l, regs.b, mem[L.PicVar1]


def _move(d, axis):
    return (lambda s, v: P.step(v, 0, d)[0::2] if axis == 'x' else P.step(0, v, d)[1:],
            lambda regs: (regs.d if axis == 'x' else regs.e,),
            lambda regs: (regs.d if axis == 'x' else regs.e, not regs.zf))


def _attr(d):
    return (lambda s, cell: P.cell_step(cell, d), lambda regs: (regs.hl - 0x5800,),
            lambda regs: regs.hl - 0x5800)


ROUTINES = {
    'DrawLocationPicture': (P.draw_location_picture, lambda regs: (regs.a,),
                            lambda regs: mem[L.PictureFound] != 0xFF),
    'FloodFill': (lambda s, ink, x, y: P.flood_fill(s.screen, ink, x, y),
                  lambda regs: (regs.a, regs.d, regs.e), nothing),
    'DrawPictureLine': (lambda s, *a: P.draw_line(s.screen, *a), _line, _pen),
    'PlotPixel': (lambda s, x, y, ink: P.plot_pixel(s.screen, x, y, ink),
                  lambda regs: (regs.d, regs.e, mem[L.PicVar1]), nothing),
    'TestPixel': (lambda s, x, y: P.lit(s.screen, x, y), _pen, lambda regs: not regs.zf),
    'MovePenUp': _move('u', 'y'), 'MovePenDown': _move('d', 'y'),
    'MovePenRight': _move('r', 'x'), 'MovePenLeft': _move('l', 'x'),
    'AttrUp': _attr('u'), 'AttrDown': _attr('d'), 'AttrLeft': _attr('l'), 'AttrRight': _attr('r'),
}


def compare_all(ink=0):
    """Every picture of the table, stage 3 (PicVar1 = ink before it) against
    pictures.py; returns (the pictures drawn, the differences)."""
    import os
    import paths as p
    import drawing
    import engine
    from regs import r
    from zxpyxel import zx
    from zxpyxel.display import Display
    zx.reset(open(os.path.join(p.ROOT, 'port/image.bin'), 'rb').read())
    check_dark, engine.CheckDark = engine.CheckDark, lambda: setattr(r, 'cf', False)
    bad, n = [], 0
    try:
        a = L.PictureTable
        while mem[a] != 0xFF:
            loc, a = mem[a], a + 3
            start = bytes((i * 37 + loc) & 0xFF for i in range(6144)) + bytes([0x38 + i % 3 for i in range(768)])
            mem[0x4000:0x5B00] = start
            mem[L.PicVar1], mem[L.PicturesEnabled] = ink, 1
            r.a = loc
            drawing.DrawLocationPicture()
            d = Display()
            d.data[:] = start
            pic = P.pictures()[loc]
            P.draw(d, pic.commands, pic.border, pic.attr)
            n += 1
            if bytes(d.data) != bytes(mem[0x4000:0x5B00]) or d.border != zx.border:
                bad.append('picture %02X with PicVar1 $%02X: %d bytes differ, border %d (stage 3 %d)'
                           % (loc, ink, sum(x != y for x, y in zip(d.data, mem[0x4000:0x5B00])),
                              d.border, zx.border))
    finally:
        engine.CheckDark = check_dark
    return n, bad


if __name__ == '__main__':
    n, bad = compare_all()
    print('\n'.join(bad) or '%d pictures drawn the same by stage 3 and pictures.py' % n)
    print('with PicVar1 $38 (never when a line is drawn: Bag End fills first): %s differ'
          % ', '.join(b.split()[1] for b in compare_all(0x38)[1]))
    sys.exit(bool(bad))
