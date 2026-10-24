#!/usr/bin/env python3
"""Make the images of docs/ from the game's bytes and runs of the game.

  python3 scripts/docs-images.py        (from the project root, venv active,
                                          after make restore)

Screens come from the simulator (tools/zxrun.py), rooms by entering each one
directly (room number $8509, room state $850C = $81, as scripts/coverage.sh
does); sprites are cut out of the sprite sheet at $D700 of a snapshot taken in
the room that unpacks them, as the behaviour blocks of the room objects say.
"""
import os
import subprocess
import sys

sys.path.insert(0, 'tools')
import zxgfx  # noqa: E402
from skoolkit.snapshot import get_snapshot  # noqa: E402

IMG = 'docs/img'
TMP = 'build/docs'
RUN = [sys.executable, 'tools/zxrun.py']


def run(*args):
    subprocess.run(RUN + [str(a) for a in args], check=True, stdout=subprocess.DEVNULL)


def screen_rows(mem, x=0, y=0, w=32, h=24):
    """Colour pixel rows of a part of the screen (cells)."""
    rows = []
    for py in range(y * 8, (y + h) * 8):
        row = []
        for cx in range(x, x + w):
            a = 0x4000 + ((py & 0xC0) << 5) + ((py & 7) << 8) + ((py & 0x38) << 2) + cx
            attr = mem[0x5800 + (py // 8) * 32 + cx]
            ink, paper = zxgfx.colours(attr)
            b = mem[a]
            row += [ink if (b >> (7 - k)) & 1 else paper for k in range(8)]
        rows.append(row)
    return rows


def scaled(rows, n):
    if n == 1:
        return rows
    return [[p for p in r for _ in range(n)] for r in rows for _ in range(n)]


def word(mem, a):
    return mem[a] | mem[a + 1] << 8


def sheet_sprite(mem, addr, width, height, attr):
    """A sprite of the sprite sheet: a page per pixel row (INC D), WIDTH
    bytes from ADDR, HEIGHT rows."""
    ink, paper = zxgfx.colours(attr)
    rows = []
    for r in range(height):
        row = []
        for i in range(width):
            b = mem[(addr + r * 256 + i) & 0xFFFF]
            row += [ink if (b >> (7 - k)) & 1 else paper for k in range(8)]
        rows.append(row)
    return rows


def pad(rows, w, h):
    """Rows placed in a W x H black canvas (top left)."""
    out = [r + [(0, 0, 0)] * (w - len(r)) for r in rows]
    return out + [[(0, 0, 0)] * w for _ in range(h - len(out))]


def warp(room, frames, dump, *more):
    run(f'{TMP}/play400.z80', '--poke', '0x8509,%d' % room, '--poke', '0x850C,0x81',
        '--frames', frames, '--dump', dump, *more)


def main():
    os.makedirs(IMG, exist_ok=True)
    os.makedirs(TMP, exist_ok=True)

    # Loader picture, title (loading) screen and the info screen
    for name, scr in (('loader-picture', 'data/picture.scr'), ('title', 'data/loading.scr'),
                      ('info', 'data/info.scr')):
        subprocess.run(['sna2img.py', '-s', '2', scr, f'{IMG}/{name}.png'], check=True)

    # Screens in play
    run('re/orig.z80', '--input', 'tests/inputs/play.txt', '--frames', 400, '--dump', f'{TMP}/play400.z80',
        '--shot', f'250:{IMG}/intro.png')
    run('re/orig.z80', '--input', 'tests/inputs/play.txt', '--shot', f'700:{IMG}/play-forest.png',
        '--shot', f'1500:{IMG}/play-church.png', '--shot', f'2900:{IMG}/parchment.png')
    run('re/orig.z80', '--input', 'tests/inputs/menu.txt', '--shot', f'199:{IMG}/controls.png',
        '--shot', f'450:{IMG}/redefine.png')
    run(f'{TMP}/play400.z80', '--poke', '0x850C,0x85', '--frames', 200, '--shot', f'150:{IMG}/game-over.png')
    run(f'{TMP}/play400.z80', '--poke', '0x850C,0x83', '--frames', 3000,
        '--shots-every', f'100:{TMP}/ending')

    # Every room, entered directly, 20 frames after the sweep-in began; room 0
    # (the intro) when its text is up; in room 3 Jean lands on the parchment,
    # so SPACE closes it first
    with open(f'{TMP}/close.txt', 'w') as f:
        f.write('40 SPACE\n45 -\n')
    rooms = []
    for n in range(25):
        dump = f'{TMP}/room{n:02d}.z80'
        if n == 0:
            warp(n, 150, dump)
        elif n == 3:
            warp(n, 90, dump, '--input', f'{TMP}/close.txt')
        else:
            warp(n, 20, dump)
        mem = get_snapshot(dump)
        rows = screen_rows(mem)
        zxgfx.write_png(f'{IMG}/room-{n:02d}.png', scaled(rows, 2))
        rooms.append(rows)
    # the map: 5 x 5 rooms, room n at row n // 5, column n % 5
    zxgfx.write_png(f'{IMG}/map.png', zxgfx.compose(rooms, 5, 1))

    mem0 = get_snapshot('re/image.z80')

    # Tiles: 256 bitmaps at $CF00, each with its attribute from $CE00
    attrs = ','.join('%d' % mem0[0xCE00 + t] for t in range(256))
    subprocess.run([sys.executable, 'tools/zxgfx.py', 'sheet', '0xCF00', '256', '1', '1',
                    f'{IMG}/tiles.png', '--attrs', attrs, '--cols', '32', '--scale', '3'], check=True)

    # Item sprites: frame lists at $8B07 (4 bytes: sprite, attribute, 0, 0),
    # 16 x 16 pixels, 2 bytes per row (24 rows for the arch)
    items = []
    for i in range(34):
        a = 0x8B07 + 4 * i
        spr, attr = word(mem0, a), mem0[a + 2]
        if not spr:
            continue
        h = 24 if spr == 0x66DC else 16
        rows = zxgfx.graphic_pixels(mem0, spr, 2, 3 if h == 24 else 2, 'linear', attr)
        items.append(pad(rows, 16, 24))
    zxgfx.write_png(f'{IMG}/items.png', zxgfx.compose(items, 12, 3))

    # The monk: frame tables at $ACA7 (left), $ACAD (right), $ACB3 (dying),
    # $ACC9/$ACCD (crouching); the copy for x AND 3 = 0 is at offset 0 (2 bytes)
    monk = []
    for table, count, h in ((0xACA7, 3, 24), (0xACAD, 3, 24), (0xACB3, 7, 24),
                            (0xACC9, 2, 16), (0xACCD, 2, 16)):
        for f in range(count):
            monk.append(pad(sheet_sprite(mem0, word(mem0, table + 2 * f), 2, h, 0x46), 16, 24))
    zxgfx.write_png(f'{IMG}/monk.png', zxgfx.compose(monk, 17, 4))
    walk = [scaled(pad(sheet_sprite(mem0, word(mem0, 0xACAD + 2 * f), 2, 24, 0x46), 16, 24), 4)
            for f in (0, 1, 2, 1)]
    zxgfx.write_gif(f'{IMG}/monk-walk.gif', walk, 12)

    # The creatures: for each room object, its behaviour block (record +9)
    # gives attribute, shift table, height and two frame tables; the frames
    # are drawn from a snapshot of a room where the object lives
    seen = {}
    a = 0x8B8F
    while mem0[a] != 0x1A:
        room, block = mem0[a], word(mem0, a + 9)
        seen.setdefault(block, room)
        a += 11
    creatures, labels = [], []
    for block in sorted(seen):
        room = seen[block]
        dump = f'{TMP}/room{room:02d}.z80'
        if not os.path.exists(dump):
            warp(room, 20, dump)
        mem = get_snapshot(dump)
        b = block + 5
        attr, pairs, height = mem[b], word(mem, b + 1), mem[b + 3]
        width = mem[pairs + 1]
        frames = []
        for t in (word(mem, b + 4), word(mem, b + 6)):
            if 0x6000 <= t < 0xC000:
                for f in range(2):
                    g = word(mem, t + 2 * f)
                    if 0xD700 <= g < 0xFF00:
                        frames.append(sheet_sprite(mem, g + mem[pairs], width, 2 * height, attr))
        frames = [fr for fr in frames if any(p != (0, 0, 0) for r in fr for p in r)]
        if frames:
            w = max(len(r[0]) for r in frames)
            h = max(len(r) for r in frames)
            creatures.append([sum((row for row in rowset), []) for rowset in
                              zip(*[pad(fr, w, h) for fr in frames])])
            labels.append('$%04X r%d' % (block, room))
    # the small ones in one sheet, each large one (Death) on its own
    small = [(c, t) for c, t in zip(creatures, labels) if len(c) <= 24]
    w = max(len(c[0]) for c, t in small)
    zxgfx.write_png(f'{IMG}/creatures.png',
                    zxgfx.compose([pad(c, w, 24) for c, t in small], 4, 2, [t for c, t in small]))
    for c, t in zip(creatures, labels):
        if len(c) > 24:
            zxgfx.write_png(f'{IMG}/creature-%s.png' % t.split()[0][1:], scaled(c, 2))


if __name__ == '__main__':
    main()
