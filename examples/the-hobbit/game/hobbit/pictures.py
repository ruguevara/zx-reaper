"""The location pictures (stage 3: drawing.py; src/drawing.asm, docs/05-pictures.md).

A picture is a header (the border and the attribute of the picture area) and
a list of commands: move the pen, draw a line, flood fill, paint paper colours
along runs of attribute cells. It is drawn into character rows 0-15 of the
screen (the picture area, 256x128 pixels, y counted from the bottom) with the
original's rules: a line is a run of major steps with one minor step every k,
the fill is the original's scan-line fill, every plotted pixel sets the ink of
its cell. The commands are game/assets/pictures/NN.txt (NN: the location id in
hex), their format explained at the top of each file."""
import functools
import glob
import os

from . import assets

PEN_START = (0x7F, 0x3F)        # PIC_START_X, PIC_START_Y: the middle of the area
TOP = 127                       # the highest pen y (the top pixel row of the area)
AREA_CELLS = 512                # attribute cells of the area (rows 0-15)
AREA_BYTES = 4096               # bitmap bytes of the area (the top two thirds)
TROLLS_CLEARING = 5             # its picture's header is s.picture5 (dawn rewrites it)
STEPS = {'r': (1, 0), 'l': (-1, 0), 'u': (0, 1), 'd': (0, -1)}
CELL_STEPS = {'u': -32, 'r': 1, 'd': 32, 'l': -1}      # paint runs, in the original's order 0-3


class Picture:
    def __init__(self, border, attr, commands):
        self.border, self.attr, self.commands = border, attr, commands


def _number(word, low, high, what):
    n = int(word, 0)
    if not low <= n <= high:
        raise ValueError('%s %d is not %d-%d' % (what, n, low, high))
    return n


def parse(text):
    """(border, attr, commands) of a picture file; 'then' stays a command."""
    header, commands = None, []
    for n, line in enumerate(text.splitlines(), 1):
        w = line.split('#')[0].split()
        if not w:
            continue
        try:
            if header is None:
                if w[0] != 'border' or w[2:3] != ['ink'] or w[4:5] != ['paper'] \
                        or not set(w[6:]) <= {'bright', 'flash'}:
                    raise ValueError('the first line must be "border B ink I paper P [bright] [flash]"')
                header = (_number(w[1], 0, 7, 'border'),
                          ('flash' in w[6:]) << 7 | ('bright' in w[6:]) << 6
                          | _number(w[5], 0, 7, 'paper') << 3 | _number(w[3], 0, 7, 'ink'))
            elif w[0] == 'move' and len(w) == 3:
                commands.append(('move', _number(w[1], 0, 255, 'x'), _number(w[2], 0, TOP, 'y')))
            elif w[0] == 'line' and len(w) == 4:
                d = w[1]
                if len(d) != 2 or not set(d) <= set(STEPS) or (d[0] in 'rl') == (d[1] in 'rl'):
                    raise ValueError('a line goes one of rl and one of ud (major first): %r' % d)
                commands.append(('line', d[0], d[1], _number(w[2], 1, 64, 'steps'),
                                 _number(w[3], 1, 64, 'every')))
            elif w[0] == 'fill' and len(w) == 4:
                commands.append(('fill', _number(w[1], 0, 7, 'ink'), _number(w[2], 0, 255, 'x'),
                                 _number(w[3], 0, TOP, 'y')))
            elif w[0] == 'paint' and len(w) >= 5:
                runs = []
                for run in w[4:]:
                    if run[0] not in CELL_STEPS:
                        raise ValueError('a run is u, r, d or l and a count: %r' % run)
                    runs.append((run[0], _number(run[1:], 1, 64, 'run')))
                commands.append(('paint', _number(w[1], 0, 7, 'paper'),
                                 _number(w[3], 0, 15, 'row') * 32 + _number(w[2], 0, 31, 'column'), runs))
            elif w[0] == 'then' and len(w) == 2:
                commands.append(('then', int(w[1], 16)))
            else:
                raise ValueError('unknown command')
        except ValueError as e:
            raise ValueError('line %d: %s: %s' % (n, line.strip(), e)) from None
    if header is None:
        raise ValueError('no header')
    return header[0], header[1], commands


@functools.lru_cache(None)
def pictures():
    """Location id -> Picture, from game/assets/pictures/*.txt; a 'then NN'
    goes on with picture NN's commands (the original runs on into the next
    picture's data: the goblins' dungeon and the trolls' clearing)."""
    raw = {}
    for f in sorted(glob.glob(assets.path(os.path.join('pictures', '*.txt')))):
        name = os.path.basename(f)
        try:
            raw[int(name[:-4], 16)] = parse(assets.load_text(os.path.join('pictures', name)))
        except ValueError as e:
            raise ValueError('pictures/%s %s' % (name, e)) from None
    if not raw:
        raise ValueError('game/assets/pictures/ has no pictures')

    def flat(loc, seen):
        out = []
        for c in raw[loc][2]:
            if c[0] != 'then':
                out.append(c)
            elif c[1] not in raw or c[1] in seen:
                raise ValueError('pictures/%02X.txt: then %02X: no such picture, or a loop' % (loc, c[1]))
            else:
                out += flat(c[1], seen | {c[1]})
        return out
    return {loc: Picture(b, a, flat(loc, {loc})) for loc, (b, a, _) in raw.items()}


def draw_location_picture(s, loc):
    """Draw the picture of location `loc` if pictures are on and it has one:
    the header (the trolls' clearing's from s.picture5), black and abandoned
    when the player cannot see. Returns True when it has one (stage 3:
    DrawLocationPicture; PictureFound not $FF)."""
    p = pictures().get(loc) if s.vars.pictures_enabled else None
    if p is None:
        return False
    from . import engine                # wave B: CheckDark (carry: True when dark)
    border, attr = s.picture5 if loc == TROLLS_CLEARING else (p.border, p.attr)
    if engine.check_dark(s):
        draw(s.screen, (), 0, 0)        # StartPicture: both header bytes taken as 0, then abandoned
    else:
        draw(s.screen, p.commands, border, attr)
    return True


def draw(screen, commands, border, attr):
    """StartPicture and RunPictureCommands: the border, the area cleared and
    filled with the attribute, then the commands from the pen at PEN_START.
    The lines' ink is black: every fill ends by setting it (PicVar1) to 0.
    Quirk: PicVar1 is $38 in the loaded image (lines before the first fill of
    the session would make their cells white paper), but the first picture of
    every game is Bag End's (01), which fills before it draws a line, so it is
    0 whenever a line is drawn (bridge/routines_pictures.py shows the 14
    pictures that would differ)."""
    screen.border = border
    screen.data[:AREA_BYTES] = bytes(AREA_BYTES)
    screen.data[6144:6144 + AREA_CELLS] = bytes([attr]) * AREA_CELLS
    x, y = PEN_START
    for c in commands:
        if c[0] == 'move':
            x, y = c[1], c[2]
        elif c[0] == 'line':
            x, y = draw_line(screen, x, y, c[1], c[2], c[3], c[4], 0)
        elif c[0] == 'fill':
            flood_fill(screen, c[1], c[2], c[3])        # the pen stays where it was
        else:
            paint(screen, c[1], c[2], c[3])


def step(x, y, d):
    """The pen one pixel in direction d (r, l, u, d): (x, y, True), or the pen
    as it was and False at the edge of the area (stage 3: MovePenRight,
    MovePenLeft, MovePenUp, MovePenDown)."""
    dx, dy = STEPS[d]
    if 0 <= x + dx <= 255 and 0 <= y + dy <= TOP:
        return x + dx, y + dy, True
    return x, y, False


def lit(screen, x, y):
    """Is the pixel at the pen (x, y) set? (stage 3: TestPixel)"""
    return screen.pixel(x, TOP - y) == 1


def plot_pixel(screen, x, y, ink):
    """Set the pixel at (x, y) and give its cell the ink, keeping the paper
    and clearing BRIGHT and FLASH; an ink equal to the paper becomes 7 - ink
    (white lines on black). The ink byte is rotated as the original does, so
    an ink above 7 also works as there (stage 3: PlotPixel)."""
    row = TOP - y
    col, cell_row = x >> 3, row >> 3
    paper = screen.attr(col, cell_row) & 0x38
    i = (ink << 3 | ink >> 5) & 0xFF                    # RLCA x3
    if i == paper:
        i ^= 0x38
    screen.set_attr(col, cell_row, (i >> 3 | i << 5) & 0xFF | paper)
    screen.plot(x, row)


def draw_line(screen, x, y, major, minor, steps, every, ink):
    """Plot `steps` pixels from the pen, a step in the major direction after
    each and one in the minor direction after every `every` major steps; it
    stops at the edge. Returns the pen, one step past the last pixel (stage 3:
    DrawPictureLine)."""
    left = every
    while True:
        plot_pixel(screen, x, y, ink)
        x, y, moved = step(x, y, major)
        if not moved:
            break
        left -= 1
        if left == 0:
            x, y, moved = step(x, y, minor)
            if not moved:
                break
            left = every
        steps -= 1
        if steps == 0:
            break
    return x, y


def flood_fill(screen, ink, x, y):
    """The original's scan-line fill from the seed (x, y) with `ink`: left to
    the first lit pixel (which is plotted again, as the right boundary is),
    then the span to the right, pushing a seed above and below at the start of
    every clear run (stage 3: FloodFill; the seeds on the Z80 stack)."""
    seeds = []
    while True:
        while True:
            if lit(screen, x, y):
                plot_pixel(screen, x, y, ink)
                x, y, _ = step(x, y, 'r')
                break
            x, y, moved = step(x, y, 'l')
            if not moved:
                break
        above = below = False           # DrawVar1, DrawVar2
        while True:
            for d, was in (('u', above), ('d', below)):
                nx, ny, moved = step(x, y, d)
                clear = moved and not lit(screen, nx, ny)
                if clear and not was:
                    seeds.append((nx, ny))
                if d == 'u':
                    above = clear
                else:
                    below = clear
            plot_pixel(screen, x, y, ink)
            x, y, moved = step(x, y, 'r')
            if not moved:
                break
            if lit(screen, x, y):
                plot_pixel(screen, x, y, ink)
                break
        if not seeds:
            break
        x, y = seeds.pop()


def cell_step(cell, d):
    """An attribute cell of the area (row * 32 + column) one step in direction
    d; a step off the area stays (left and right wrap round to the row above
    or below). Stage 3: AttrUp, AttrRight, AttrDown, AttrLeft."""
    n = cell + CELL_STEPS[d]
    return n if 0 <= n < AREA_CELLS else cell


def paint(screen, paper, cell, runs):
    """Give the cells along the runs from `cell` the paper; an ink equal to it
    becomes 7 - ink; BRIGHT and FLASH are cleared (stage 3: the paint command
    of RunPictureCommands)."""
    for d, count in runs:
        for _ in range(count):
            col, row = cell & 31, cell >> 5
            ink = screen.attr(col, row) & 7
            if ink == paper:
                ink ^= 7
            screen.set_attr(col, row, paper << 3 | ink)
            cell = cell_step(cell, d)
