"""Shared case builders for the events.asm models."""

SCREEN_BYTES = 6912     # bitmap + attributes


def pos(third, row, col):
    return (third << 11) + (row << 5) + col


def rand_pos(rnd):
    """A block's top-left cell that the game produces: the bottom row stays on the screen."""
    third = rnd.randrange(3)
    return pos(third, rnd.randrange(7 if third == 2 else 8), rnd.randrange(31))


def screen(rnd, sym):
    return {sym('SCREEN'): bytes(rnd.randrange(256) for _ in range(SCREEN_BYTES))}
