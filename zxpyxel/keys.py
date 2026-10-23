"""The keyboard matrix and the Kempston joystick, with the key names of tools/zxrun.py."""
ROWS = ['CS Z X C V', 'A S D F G', 'Q W E R T', '1 2 3 4 5',
        '0 9 8 7 6', 'P O I U Y', 'ENTER L K J H', 'SPACE SS M N B']
KEYS = {k: (r, b) for r, row in enumerate(ROWS) for b, k in enumerate(row.split())}
KEMPSTON = {'KR': 1, 'KL': 2, 'KD': 4, 'KU': 8, 'KF': 16}


def read(held, high):
    """IN from $xxFE: the half-rows whose bit in `high` is 0, combined; bits 0-4
    are 0 for a held key, bit 6 (EAR) reads 0 as in zxrun."""
    v = 0
    for k in held:
        if k in KEYS and not high >> KEYS[k][0] & 1:
            v |= 1 << KEYS[k][1]
    return (v | 0x40) ^ 0xFF


def kempston(held):
    return sum(KEMPSTON[k] for k in held if k in KEMPSTON)
