"""Delay spins BC passes (BC = 0 is 65536) and leaves BC = 0."""
ROUTINE = 'Delay'
INPUTS = ['BC']
OUTPUTS = {'regs': ['BC']}
KINDS = ['typical', 'boundary']


def cases(rnd):
    for _ in range(40):
        yield 'typical', {'BC': rnd.randrange(1, 400)}
    for bc in (1, 2, 0, 0xFFFF, 0x0100, 0x0101):
        yield 'boundary', {'BC': bc}


def model(regs, mem):
    return {'BC': 0}


def port(regs):
    import library
    from zxpyxel import zx
    t = zx.t
    library.Delay(regs['BC'])
    assert zx.t - t == 26 * (regs['BC'] or 0x10000)
    return {'BC': 0}
