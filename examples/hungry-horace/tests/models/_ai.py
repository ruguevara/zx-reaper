"""Shared case builders for the movement tests."""


def pos(third, row, col):
    return (third << 11) + (row << 5) + col


def rand_pos(rnd):
    """A 2x2 sprite offset well inside a third (its neighbours are in the same third)."""
    return pos(rnd.randrange(3), rnd.randrange(1, 5), rnd.randrange(2, 28))


def w(x):
    return [x & 255, x >> 8 & 255]


def around(rnd, attrs, p, pool):
    """Attributes of the cells around the block at offset p, drawn from pool."""
    base = attrs + ((p >> 11 & 3) << 8) + (p & 255)
    return {base + dr * 32 + dc: rnd.choice(pool) for dr in range(-1, 4) for dc in range(-1, 3)}
