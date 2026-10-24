#!/usr/bin/env python3
"""Tape block 3: the loading screen, the info screen, the 128K music and
the game, each packed with MegaLZ, one after another (loaded at $625E).

  block3.py LOADING.scr INFO.scr MUSIC128.bin GAME.bin OUT
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import megalz  # noqa: E402


def main():
    loading, info, music, game, out = sys.argv[1:6]
    data = b''
    for path, rcs in ((loading, True), (info, True), (music, False), (game, False)):
        raw = open(path, 'rb').read()
        data += megalz.pack(megalz.to_rcs(raw) if rcs else raw)
    open(out, 'wb').write(data)


if __name__ == '__main__':
    main()
