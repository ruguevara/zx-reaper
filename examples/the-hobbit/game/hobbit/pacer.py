"""Runs the game as a host does, 50 frames a second: answers its requests and
holds its pauses for the original's time.

- Keys: the original's scanner (ReadKey): each frame the ZX keys held are
  scanned by half-row with its masks, and a key that was up in the previous
  scan is a new key, coded through its key tables (the shifted one while CAPS
  or SYMBOL SHIFT is down). The idle time-out: the original allows 3000 scans
  of no key (each key gives 500 back, up to 3000), a scan about 26,600
  T-states; then ReadKey is answered None.
- ScrollPause: about 0.63 s ($8000 polls), cut short by a key, held while a
  key is down. WaitKey: until a key is down.
- Printed lines go to the transcript file, SAVE and LOAD to the save file.
- R and the random routine's mixed values come from a stand-in generator.
"""
import json
import os
import random

from . import assets
from .flow import Game
from .state import (Mixed, Printed, ReadKey, ReadR, ScrollPause, Show, Step, TapeLoad, TapeSave,
                    WaitKey)

FRAME_T = 69888
SCAN_T = 26600              # one scan of WaitKey: DelayShort's 1000 passes and the scanner
IDLE_SCANS, SCANS_PER_KEY = 3000, 500
PAUSE_FRAMES = 0x8000 * 67 // FRAME_T
ROWS = ['CS Z X C V', 'A S D F G', 'Q W E R T', '1 2 3 4 5',
        '0 9 8 7 6', 'P O I U Y', 'ENTER L K J H', 'SPACE SS M N B']


class Pacer:
    def __init__(self, display, save='hobbit.sav', transcript='hobbit.txt', seed=None):
        tables = assets.load_json('tables.json')
        self.masks, self.keys_plain, self.keys_shifted = (tables['key_masks'], tables['key_table'],
                                                          tables['shift_key_table'])
        self.display, self.save, self.transcript = display, save, transcript
        self.random = random.Random(seed)
        self.game = Game()
        self.gen = self.game.run()
        self.reply, self.waiting = None, None
        self.previous = [0x1F] * 8          # the last scan, as the original keeps it
        self.idle = IDLE_SCANS
        self.frame = 0

    def scan(self, held):
        """The original's ReadKey on the keys held: a new key's code, or 0."""
        found = None
        for i, row in enumerate(ROWS):
            bits = 0x1F
            for col, k in enumerate(row.split()):
                if k in held:
                    bits &= ~(1 << col)
            a = bits | self.masks[i]
            new = ~(~a & self.previous[i]) & 0xFF
            if ~new & 0xFF:
                found = (i, new)
            self.previous[i] = a
        if found is None:
            return 0
        i, new = found
        col = next(c for c in range(8) if not new >> c & 1)
        table = self.keys_shifted if 'CS' in held or 'SS' in held else self.keys_plain
        return table[5 * i + col]

    def update(self, held):
        """One host frame with the ZX keys `held`; returns b'' (the game is silent)."""
        self.frame += 1
        scans = FRAME_T // SCAN_T
        while True:
            if self.waiting is not None:
                if not self.wait(self.waiting, held, scans):
                    break
                self.waiting = None
            try:
                e = self.gen.send(self.reply)
            except StopIteration:
                return None
            self.reply = None
            if isinstance(e, (ReadKey, WaitKey, ScrollPause, Show)):
                self.waiting = e
                if isinstance(e, ScrollPause):
                    e.frames = PAUSE_FRAMES
                elif isinstance(e, Show):
                    e.frames = round(e.seconds * 50)
            elif isinstance(e, ReadR):
                self.reply = self.frame & 0x7F
            elif isinstance(e, Mixed):
                self.reply = self.random.randrange(256)
            elif isinstance(e, Printed):
                with open(self.transcript, 'a') as f:
                    f.write(e.text + '\n')
            elif isinstance(e, TapeSave):
                with open(self.save, 'w') as f:
                    json.dump(assets.dump_state(self.game.state), f)
            elif isinstance(e, TapeLoad):
                self.reply = assets.state(json.load(open(self.save))) if os.path.exists(self.save) else None
            elif isinstance(e, Step):
                pass
        self.display.data[:] = self.game.state.screen.data
        self.display.border = self.game.state.screen.border
        return b''

    def wait(self, e, held, scans):
        """True when the wait `e` is over this frame (its answer in self.reply)."""
        if isinstance(e, ReadKey):
            code = self.scan(held)
            if code:
                self.idle = min(self.idle + SCANS_PER_KEY, IDLE_SCANS)
                self.reply = code
                return True
            self.idle -= scans
            if self.idle <= 0:
                self.idle = IDLE_SCANS
                self.reply = None           # the idle time-out
                return True
            return False
        if isinstance(e, WaitKey):
            self.scan(held)
            return bool(held)
        if isinstance(e, ScrollPause):
            self.scan(held)
            if held:
                e.frames = 0                # a key cuts the pause short, and holds it while down
                return False
            e.frames -= 1
            return e.frames <= 0
        e.frames -= 1                       # Show
        return e.frames <= 0
