"""Helpers for the text tests (printer, screen): a random screen, flag inputs."""
FLAGS = ['ZF', 'CF', 'SF', 'PF']
SCREEN_MEM = [(0x4000, 0x1B00)]


def random_screen(rnd):
    """The whole bitmap and attributes filled with random bytes."""
    return {0x4000: bytes(rnd.randrange(256) for _ in range(0x1B00))}


def cell(rnd, rows):
    """The screen address of a random cell in character rows `rows`."""
    row = rnd.choice(rows)
    return 0x4000 + (row >> 3) * 0x800 + (row & 7) * 32 + rnd.randrange(32)


def drive(coro):
    """Run a port coroutine to its end, passing every frame wait."""
    while True:
        try:
            coro.send(None)
        except StopIteration:
            return


def run_async(fn, regs, outputs):
    """_regs.run for an async routine (the cases keep clear of the keyboard)."""
    import _regs
    def sync():
        drive(fn())
    return _regs.run(sync, regs, outputs)


STORY_MEM = _text_mem = SCREEN_MEM + [('StoryColumn', 6), ('CapitalNext', 1), ('InputColumn', 4), ('StoryLastChar', 1),
                                      ('NoPauseLines', 1), ('WordBuffer', 20), ('SavedA', 5), ('ActionAllowed', 1)]


def story_state(rnd, column=42, last=0, capital=1, indent=0, pixel=None, cursor=None):
    """Memory for the story window: random screen, cursor, flags (output on, story window, no printer, no pause)."""
    cur = cursor if cursor is not None else 0x4000 + 0x1000 + 0x20 + rnd.randrange(30)
    return {**random_screen(rnd), 'StoryColumn': column, 'StoryCursor': [cur & 255, cur >> 8],
            'StoryCursorPixel': rnd.randrange(8) if pixel is None else pixel, 'ListIndent': indent,
            'StoryLastChar': last, 'CapitalNext': capital, 'RawOutputFlag': 0, 'ActionPerform': 1,
            'MessagesVisible': 1, 'PrinterFlag': 0, 'LispFlag': 0, 'NoPauseLines': 5, 'EchoingCommand': 0,
            'Subject': 0, 'FirstObject': 0, 'ActionAllowed': 7}
