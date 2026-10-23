"""Runs a game on Pyxel: window, palette, screen, keys, beeper sound."""
import ctypes
import os
import tempfile

import pyxel

from . import screen, sound
from .machine import zx

RATE = 22050


def host_keys():
    """Host key → ZX keys: letters and digits as themselves, Shift = CAPS SHIFT,
    Ctrl and Alt = SYMBOL SHIFT."""
    m = {getattr(pyxel, 'KEY_' + c): c for c in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'}
    m.update({pyxel.KEY_SPACE: 'SPACE', pyxel.KEY_RETURN: 'ENTER', pyxel.KEY_SHIFT: 'CS',
              pyxel.KEY_CTRL: 'SS', pyxel.KEY_ALT: 'SS'})
    return m


def run(main, title='ZX Spectrum', scale=3, border=32, palette='pulsar', keymap=None):
    """Run the coroutine function `main` at 50 frames a second. `keymap` adds host
    keys or gamepad buttons → space-separated ZX keys ('CS 5', 'KL')."""
    pyxel.init(256 + 2 * border, 192 + 2 * border, title=title, fps=50, display_scale=scale)
    for i, c in enumerate(screen.rgb(palette)):
        pyxel.colors[i] = c
    keys = {h: z.split() for h, z in {**host_keys(), **(keymap or {})}.items()}
    image = pyxel.images[0].data_ptr()
    wav = os.path.join(tempfile.gettempdir(), 'zxpyxel.wav')
    game = main()
    frame = 0

    def update():
        nonlocal frame
        zx.keys = {k for h, zk in keys.items() if pyxel.btn(h) for k in zk}
        try:
            game.send(None)
        except StopIteration:
            pyxel.quit()
        frame += 1
        pcm = zx.take_audio(RATE)
        if pcm:
            # ponytail: one WAV per chunk through Sound.pcm; a tone that spans
            # frames while the game runs gets a seam each frame (docs/port.md)
            with open(wav, 'wb') as f:
                f.write(sound.wav(pcm, RATE))
            pyxel.sounds[0].pcm(wav)
            pyxel.play(0, 0)

    def draw():
        ctypes.memmove(image, screen.render(zx.mem, frame >> 4 & 1), 256 * 192)
        pyxel.cls(zx.border)
        pyxel.blt(border, border, 0, 0, 0, 256, 192)

    pyxel.run(update, draw)
