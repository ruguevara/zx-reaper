#!/usr/bin/env python3
"""Make the images of docs/ from the game's bytes and runs of the game.

  python3 scripts/docs-images.py        (from the project root, venv active,
                                          after make restore)

Screens come from the simulator (tools/zxrun.py), rooms by entering each one
directly (room number $8509, room state $850C = $81, as scripts/coverage.sh
does); sprites are cut out of the sprite sheet at $D700 of a snapshot taken in
the room that unpacks them, as the behaviour blocks of the room objects say.

The images of 05-drawing, 05-sound, 06-tricks and 07-graphics (names
drawing-*, sound-*, tricks-*, graphics-*) are made by article_images(): the
font and the 128K ending by running the game's own routines in the simulator,
the hourglass and the parchment tiles from their bytes, the rest from runs.
"""
import os
import re
import subprocess
import sys

sys.path.insert(0, 'tools')
import zxgfx  # noqa: E402
from skoolkit.simulator import Simulator  # noqa: E402
from skoolkit.snapshot import Snapshot, get_snapshot  # noqa: E402
from skoolkit.simutils import IFF, PC, SP, from_snapshot  # noqa: E402

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


def symbols():
    """Label -> address of the game (build/game.sym)."""
    syms = {}
    for line in open('build/game.sym'):
        name, sep, value = line.partition(': EQU ')
        if sep:
            syms[name] = int(value, 16)
    return syms


def lst_symbols(path):
    """Labels and EQUs of an sjasmplus listing (the loader, build/stage2.lst)."""
    syms = {}
    for line in open(path):
        m = re.match(r'\s*\d+\+*\s+([0-9A-F]{4})\s+(\w+):\s*$', line)
        if m:
            syms[m.group(2)] = int(m.group(1), 16)
        m = re.match(r'\s*\d+\+*\s+[0-9A-F]{4}\s+(\w+)\s+EQU\s+\$([0-9A-F]+)', line)
        if m:
            syms[m.group(1)] = int(m.group(2), 16)
    return syms


def call(mem, addr, **regs):
    """Run the routine at ADDR on MEM (a 64K list) until it returns, with the
    stack in the main stack area and the return address $0001 (never run)."""
    sp = 0x60FE
    mem[sp], mem[sp + 1] = 0x01, 0x00
    Simulator(mem, dict(regs, SP=sp)).run(addr, 0x0001)


def music_bank():
    """The 128K bank at $C000 as the loader's Start128 fills it: the screen
    depacker DepackScreen, the packed loading and info screens (the start of
    tape block 3, up to the packed music) and the unpacked music
    (data/music128.bin)."""
    ls = lst_symbols('build/stage2.lst')
    s2 = open('build/stage2.bin', 'rb').read()             # assembled at $6000
    b3 = open('build/blk03.bin', 'rb').read()              # loaded at Block3
    data = (s2[ls['DepackScreen'] - 0x6000:ls['Block3'] - 0x6000]
            + b3[:ls['PackedMusic'] - ls['Block3']])
    return data + open('data/music128.bin', 'rb').read()


def article_images():
    """Images of 05-drawing, 05-sound, 06-tricks and 07-graphics."""
    syms = symbols()
    play = ('re/orig.z80', '--input', 'tests/inputs/play.txt')

    # The sprite sheet $D700-$FEFF in room 22 (four sprite sets unpacked):
    # four bands of 64 columns, 40 pixel rows (pages) each, white on black
    mem = get_snapshot(f'{TMP}/room22.z80')
    white, black, grey = (255, 255, 255), (0, 0, 0), (110, 110, 110)
    rows = []
    for c0 in range(0, 256, 64):
        if c0:
            rows.append([grey] * 512)
        for r in range(40):
            row = []
            for c in range(c0, c0 + 64):
                b = mem[0xD700 + 256 * r + c]
                row += [white if (b >> (7 - k)) & 1 else black for k in range(8)]
            rows.append(row)
    zxgfx.write_png(f'{IMG}/drawing-sheet.png', scaled(rows, 2))

    # The room sweep: room 8 entered with exit direction 0 (columns left to
    # right), one frame per image from frame 7 to 18 after the warp
    frames = []
    for f in range(7, 19):
        dump = f'{TMP}/sweep{f:02d}.z80'
        warp(8, f, dump, '--poke', '0x850B,0')
        frames.append(scaled(screen_rows(get_snapshot(dump), 0, 0, 32, 22), 2))
    frames += [frames[-1]] * 6
    zxgfx.write_gif(f'{IMG}/drawing-sweep.gif', frames, 10)

    # Sprites over the scenery: crusaders on the tree of room 6 (frame 700 of
    # play.txt), cells 0-9 of rows 13-20, four times enlarged
    run(*play, '--frames', 700, '--png', f'{IMG}/drawing-outline.png', '--crop', '0,13,10,8',
        '--scale', 4)

    # The font: the 96 characters $20-$7F drawn by the game's DrawGlyph, 12
    # to a line, white on black
    mem = list(get_snapshot('re/image.z80'))
    mem[0x4000:0x5800] = [0] * 0x1800
    mem[0x5800:0x5B00] = [0x07] * 0x300
    for n, code in enumerate(range(0x20, 0x80)):
        mem[syms['TextCursorY']] = 4 + 23 * (n // 12)
        mem[syms['TextCursorX']] = 8 + 20 * (n % 12)
        call(mem, syms['DrawGlyph'], A=code)
    zxgfx.write_png(f'{IMG}/graphics-font.png', scaled(screen_rows(mem, 0, 0, 32, 24), 2))

    # The parchment frame tiles (12 bitmaps at ParchmentFrameTiles), yellow
    # on black as ShowParchment draws them
    mem0 = get_snapshot('re/image.z80')
    tiles = [zxgfx.graphic_pixels(mem0, syms['ParchmentFrameTiles'] + 8 * n, 1, 1, 'cells', 0x06)
             for n in range(12)]
    zxgfx.write_png(f'{IMG}/graphics-parchment-tiles.png',
                    zxgfx.compose(tiles, 12, 4, [str(n) for n in range(12)]))

    # The loader's hourglass: the outline (3 x 3 cells, column by column) with
    # the middle column replaced by each of the 10 frames of the two sets
    ls = lst_symbols('build/stage2.lst')
    s2 = open('build/stage2.bin', 'rb').read()

    def at(label, n):
        return s2[ls[label] - 0x6000:ls[label] - 0x6000 + n]
    outline = at('HourglassOutline', 72)
    ink, paper = zxgfx.colours(0x46)

    def glass(middle):
        cols = (outline[0:24], middle, outline[48:72])
        return [sum(([ink if (c[y] >> (7 - k)) & 1 else paper for k in range(8)] for c in cols), [])
                for y in range(24)]
    sets = [[at(label, 240)[24 * k:24 * k + 24] for k in range(10)]
            for label in ('HourglassTop', 'HourglassBottom')]
    zxgfx.write_png(f'{IMG}/graphics-hourglass.png',
                    zxgfx.compose([glass(sets[s][k]) for s in (0, 1) for k in range(9, -1, -1)], 10, 3,
                                  ['%d' % k for s in (0, 1) for k in range(9, -1, -1)]))
    zxgfx.write_gif(f'{IMG}/graphics-hourglass.gif',
                    [scaled(glass(sets[s][k]), 4) for k in range(9, -1, -1) for _ in range(3) for s in (0, 1)],
                    8)

    # Creatures in play: rooms entered directly with enemy hits off
    # ($A87A := $18) and Jean taken out of play (state 0) where he would fall
    # or die; the frame numbers count from the warp
    for room, frame, name, more in ((10, 100, 'beast', ('--poke', '0xA894,0')),
                                    (10, 300, 'beast-flames', ('--poke', '0xA894,0')),
                                    (9, 60, 'hanged-men', ()),
                                    (14, 135, 'plants', ()),
                                    (17, 110, 'archers', ()),
                                    (18, 100, 'death', ('--poke', '0xA894,0')),
                                    (19, 80, 'fish', ('--poke', '0xA894,0')),
                                    (24, 180, 'satan', ()),
                                    (24, 160, 'ring', ('--poke', '0x854D,12'))):
        run(f'{TMP}/play400.z80', '--poke', '0x8509,%d' % room, '--poke', '0x850C,0x81',
            '--poke', '0xA87A,0x18', *more, '--frames', frame + 1,
            '--shot', f'{frame}:{IMG}/graphics-play-{name}.png')

    # The interrupt handler without its PUSH BC ($858E := NOP): play.txt at
    # frame 1500 (compare play-church.png)
    run(*play, '--poke', '0x858E,0', '--frames', 1501, '--shot', f'1500:{IMG}/tricks-no-push-bc.png')

    # The 128K ending: the music bank's routine MusicEntryEnding calls
    # ($FC4B) run in the 48K simulator with the bank's bytes at $C000 (paging
    # is not simulated), from the end of the ending; interrupts on, the frame
    # routine replaced by a RET; the screen after each picture it draws
    run(f'{TMP}/play400.z80', '--poke', '0x850C,0x83', '--frames', 3000, '--fuzz', '8:20:SPACE,ENTER',
        '--stop', syms['RunEnding_Music'], '--dump', f'{TMP}/ending-end.z80')
    sim = from_snapshot(Simulator, Snapshot.get(f'{TMP}/ending-end.z80'), {}, None, {})
    mem, r = sim.memory, sim.registers
    bank = music_bank()
    mem[0xC000:0xC000 + len(bank)] = list(bank)
    nofr = syms['NoFrameRoutine']
    mem[syms['InterruptRoutine']], mem[syms['InterruptRoutine'] + 1] = nofr & 255, nofr >> 8
    r[SP] -= 2
    mem[r[SP]], mem[r[SP] + 1] = 0x01, 0x00
    r[IFF] = 1
    r[PC] = word(mem, syms['MusicEntryEnding'] + 1)      # LD DE,$FC4B
    pictures = []
    for stop in [0xFC5C] + [0xFC6F] * 5:      # after each CALL of the drawing routine $FC78
        sim.run(r[PC], stop, True)
        pictures.append(screen_rows(mem))
        sim.run(r[PC])
    # 50 frames, then a picture every 20 frames, then 60 frames (GIF steps of 0.2 s)
    gif = [pictures[0]] * 5 + [p for p in pictures[1:] for _ in range(2)] + [pictures[-1]] * 6
    zxgfx.write_gif(f'{IMG}/sound-ending-128k.gif', gif, 20)


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

    # The monk: frame tables at $ACA7 (left), $ACAD (right), $ACB3 (dying,
    # drawn bright red), $ACC9/$ACCD (crouching); the copy for x AND 3 = 0 is
    # at offset 0 (2 bytes)
    monk = []
    for table, count, h, attr in ((0xACA7, 3, 24, 0x46), (0xACAD, 3, 24, 0x46), (0xACB3, 7, 24, 0x42),
                                  (0xACC9, 2, 16, 0x46), (0xACCD, 2, 16, 0x46)):
        for f in range(count):
            monk.append(pad(sheet_sprite(mem0, word(mem0, table + 2 * f), 2, h, attr), 16, 24))
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

    article_images()


if __name__ == '__main__':
    main()
