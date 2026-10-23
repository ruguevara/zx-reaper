"""The world slice's assets (called by bridge/assets.py):

  pictures/NN.txt   the picture of location NN (hex) as commands, one per line
                    (format at the top of each file), loaded by hobbit/pictures.py
  pictures/NN.png   a preview drawn from the text by hobbit/pictures.py (not loaded)
  world.json        the small word tables of src/objects.asm: the direction words
                    (NameWordTable), the state words (ReasonWords1, ReasonWords2),
                    and the relation messages ("In the", "On the"... at MsgInThe + 4k)
"""
import json
import os

import paths  # noqa: F401
import labels as L
from decode import names, word
from assets import OUT, writing
from hobbit import pictures
from zxpyxel import png, screen
from zxpyxel.display import Display

DOC = """\
# The picture of location {loc:02X}{note}, drawn by game/hobbit/pictures.py.
# The picture area is the top 16 character rows, 256x128 pixels: x 0-255 from
# the left, y 0-127 from the bottom; the pen starts at 127 63. One command per
# line, # starts a comment:
#   border B ink I paper P [bright] [flash]
#                            the header (first): the border and the attribute the
#                            whole area starts with
#   move X Y                 the pen to (X, Y)
#   line MN STEPS EVERY      STEPS pixels from the pen, the pen moving one pixel in
#                            direction M after each and one in direction N after
#                            every EVERY of them (r right, l left, u up, d down;
#                            1-64); a line stops at the edge; the pen stays one
#                            step past its end
#   fill INK X Y             flood fill with ink 0-7 from (X, Y), bounded by any set
#                            pixel; the pen stays where it was
#   paint PAPER COL ROW RUNS paper 0-7 for the attribute cells along the runs from
#                            cell (COL 0-31, ROW 0-15): u3 is three cells up, then
#                            r right, d down, l left (1-64 each)
#   then NN                  go on with the commands of picture NN
# Every pixel plotted gives its cell the ink (black for lines, the fill's ink in a
# fill) and keeps the paper; an ink equal to the paper becomes 7 - ink.
"""
NOTES = {
    0x05: ' (the trolls\' clearing; the game takes this header from the state,'
          '\n# picture5: dawn makes it border 5 ink 0 paper 5)',
}


def table(mem):
    """[(location id, address)] of PictureTable, in its (address) order."""
    out, a = [], L.PictureTable
    while mem[a] != 0xFF:
        out.append((mem[a], word(mem, a + 1)))
        a += 3
    return out


def header(b, a):
    if b > 7:
        raise ValueError('border byte $%02X' % b)
    return 'border %d ink %d paper %d%s%s' % (b, a & 7, a >> 3 & 7, ' bright' if a & 0x40 else '',
                                              ' flash' if a & 0x80 else '')


def text(mem, loc, a, starts):
    """The commands of the picture at `a` as text; `starts` maps the address of
    another picture's commands to its id (the data runs on into it: 'then')."""
    out = [DOC.format(loc=loc, note=NOTES.get(loc, '')).rstrip('\n'), header(mem[a], mem[a + 1])]
    p = a + 2
    while True:
        if p in starts and p != a + 2:
            out.append('then %02X' % starts[p])
            break
        c = mem[p]
        p += 1
        if c == 0:
            break
        if c == 0x08:
            out.append('move %d %d' % (mem[p], mem[p + 1]))
            p += 2
        elif c & 0x80:
            b2 = mem[p]
            p += 1
            h, v = 'l' if c & 4 else 'r', 'd' if c & 2 else 'u'
            out.append('line %s %d %d' % (v + h if c & 1 else h + v, (b2 & 0x3F) + 1,
                                          ((c >> 1 & 0x3C) | b2 >> 6) + 1))
        elif c & 0x40 and not c & 0x38:
            out.append('fill %d %d %d' % (c & 7, mem[p], mem[p + 1]))
            p += 2
        elif c & 0x20 and not c & 0x18:
            cell = (mem[p] << 8 | mem[p + 1]) - 0x5800            # high byte first
            if not 0 <= cell < pictures.AREA_CELLS:
                raise ValueError('picture %02X: paint at $%04X' % (loc, cell + 0x5800))
            p += 2
            runs = []
            while mem[p] != 0xFF:
                runs.append('%s%d' % ('urdl'[mem[p] & 3], (mem[p] >> 2) + 1))
                p += 1
            p += 1
            out.append('paint %d %d %d %s' % (c & 7, cell & 31, cell >> 5, ' '.join(runs)))
        else:
            raise ValueError('picture %02X: command $%02X at $%04X' % (loc, c, p - 1))
    return '\n'.join(out) + '\n'


def preview(loc, path):
    """pictures/NN.png: the picture area drawn by hobbit/pictures.py from the text."""
    p = pictures.pictures()[loc]
    d = Display()
    pictures.draw(d, p.commands, p.border, p.attr)
    pix, rgb = screen.render(d.data, base=0), screen.rgb()
    rows = [[(rgb[i] >> 16, rgb[i] >> 8 & 0xFF, rgb[i] & 0xFF) for i in pix[256 * y:256 * y + 256]]
            for y in range(128)]
    png.write(path, 256, 128, rows)


def words(mem, a, n):
    return [word(mem, a + 2 * k) for k in range(n)]


def write(mem, force):
    pics = table(mem)
    starts = {a + 2: loc for loc, a in pics}
    for loc, a in pics:
        name = 'pictures/%02X.txt' % loc
        if writing(name, force):
            with open(os.path.join(OUT, name), 'w') as f:
                f.write(text(mem, loc, a, starts))
    pictures.pictures.cache_clear()
    for loc, a in pics:
        name = 'pictures/%02X.png' % loc
        if writing(name, force):
            preview(loc, os.path.join(OUT, name))
    if writing('world.json', force):
        n = names()
        with open(os.path.join(OUT, 'world.json'), 'w') as f:
            json.dump({
                'direction_words': words(mem, L.NameWordTable, (L.ReasonWords1 - L.NameWordTable) // 2),
                'state_words': [words(mem, L.ReasonWords1, 8), words(mem, L.ReasonWords2, 8)],
                'relations': [n.get(a, 'L%04X' % a) for a in range(L.MsgInThe, L.MsgThere - 2, 4)],
            }, f, indent=1)
