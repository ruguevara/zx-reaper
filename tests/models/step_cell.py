"""StepCell moves a screen offset one cell in direction A; left never changes the third."""
ROUTINE = 'StepCell'
INPUTS = ['A', 'HL']
OUTPUTS = {'regs': ['HL']}
KINDS = ['typical', 'boundary', 'high-bits']


def cases(rnd):
    thirds = [0, const('THIRD_STEP'), 2 * const('THIRD_STEP')]
    for _ in range(400):
        yield 'typical', {'A': rnd.randrange(4), 'HL': rnd.choice(thirds) << 8 | rnd.randrange(256)}
    # first/last cell row of each third, first/last column
    for h in thirds:
        for low in (0x00, 0x1F, 0xE0, 0xFF):
            for a in range(4):
                yield 'boundary', {'A': a, 'HL': h << 8 | low}
    # only the two low bits of A are a direction
    for _ in range(64):
        yield 'high-bits', {'A': rnd.randrange(256), 'HL': rnd.choice(thirds) << 8 | rnd.randrange(256)}


def model(regs, mem):
    step, cols = const('THIRD_STEP'), const('SCREEN_COLS')
    h, low = regs['HL'] >> 8, regs['HL'] & 255
    d = regs['A'] & 3
    if d == 0:                      # up: borrow moves to the previous third
        low -= cols
        if low < 0:
            low, h = low + 256, h - step
    elif d == 1:                    # right: carry moves to the next third
        low += 1
        if low > 255:
            low, h = 0, h + step
    elif d == 2:                    # down
        low += cols
        if low > 255:
            low, h = low - 256, h + step
    else:                           # left: wraps inside the third (carry is always clear)
        low = (low - 1) & 255
    return {'HL': (h & 255) << 8 | low}
