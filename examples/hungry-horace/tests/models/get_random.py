"""GetRandom returns the ROM byte at RandomPtr and advances the pointer inside the first 8K."""
ROUTINE = 'GetRandom'
INPUTS = ['RandomPtr (memory)']
OUTPUTS = {'regs': ['A'], 'mem': [('RandomPtr', 2)]}
KINDS = ['typical', 'wrap', 'outside-8k']


def cases(rnd):
    for _ in range(300):
        p = rnd.randrange(0x2000)
        yield 'typical', {'mem': {'RandomPtr': [p & 255, p >> 8]}}
    for p in (0x1FFF, 0x00FF, 0x1EFF):
        yield 'wrap', {'mem': {'RandomPtr': [p & 255, p >> 8]}}
    # a pointer outside the ROM's first 8K (not produced by the game) is masked back
    for _ in range(20):
        p = rnd.randrange(0x2000, 0x4000)
        yield 'outside-8k', {'mem': {'RandomPtr': [p & 255, p >> 8]}}


def model(regs, mem):
    ptr = sym('RandomPtr')
    p = mem.word(ptr)
    nxt = (p + 1) & 0xFFFF
    nxt = ((nxt >> 8) & const('ROM_HIGH_MASK')) << 8 | (nxt & 255)
    return {'A': mem[p], 'mem': {ptr: nxt & 255, ptr + 1: nxt >> 8}}


def port(regs):
    import library
    return {'A': library.GetRandom()}
