"""Runs a game without a window, for tests: as fast as it goes, keys from a function."""
from .machine import ROM, zx


def run(main, frames=None, keys=None):
    """Drive the coroutine function `main` for `frames` frames (None: until it
    returns); `keys(frame)` gives the ZX keys held. Returns the frames run."""
    game, n = main(), 0
    while frames is None or n < frames:
        zx.keys = keys(n) if keys else set()
        try:
            game.send(None)
        except StopIteration:
            break
        if zx.mem[:0x4000] != ROM:
            raise AssertionError('frame %d: the port wrote to the ROM' % n)
        zx.edges.clear()
        n += 1
    return n
