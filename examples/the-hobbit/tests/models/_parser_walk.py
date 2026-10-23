"""Cases for the phrase-record walks: records on the phrase stack with EXCEPT flags, a start record IY
and a search that always finds a record without the EXCEPT flag."""
import _parser

SPAN = (_parser.PHRASE_STACK_TOP - 24 * 4, 24 * 10)       # the records the walks may read


def walk_cases(rnd, direction, extra=None):
    """direction +1: older (higher addresses), -1: newer. Yields (kind, case)."""
    top = _parser.PHRASE_STACK_TOP
    for n in range(40):
        k = rnd.randrange(-1, 4)                           # the start record, as an index down from the top
        iy = top - 24 * k
        mem = {}
        for j in range(-4, 6):                             # records j down from the top
            flags = rnd.choice([0, _parser.EXCEPT, _parser.EXCEPT, _parser.ALL])
            mem[top - 24 * j + 1] = flags
        # the first record in the direction of the walk after N skips is a plain one
        skips = rnd.randrange(0, 3)
        for s in range(1, skips + 1):
            mem[iy + direction * 24 * s + 1] = _parser.EXCEPT
        mem[iy + direction * 24 * (skips + 1) + 1] = rnd.choice([0, _parser.ALL])
        c = {'IY': iy, 'DE': rnd.randrange(65536), 'IX': rnd.randrange(65536), 'B': rnd.randrange(1, 9), 'mem': mem}
        if extra:
            c.update(extra)
        yield 'typical' if skips else 'boundary', c
