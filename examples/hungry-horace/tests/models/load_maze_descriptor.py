"""LoadMazeDescriptor copies the 8-byte descriptor at HL to MazeDescriptor."""
ROUTINE = 'LoadMazeDescriptor'
INPUTS = ['HL']
OUTPUTS = {'regs': [], 'mem': [('MazeDescriptor', const('MAZE_DESC_SIZE'))]}
KINDS = ['game-descriptors', 'random']


def cases(rnd):
    for i in range(4):
        yield 'game-descriptors', {'HL': sym('MazeDescriptor') + (i + 1) * const('MAZE_DESC_SIZE')}
    for _ in range(10):
        src = 0xE000 + rnd.randrange(100)
        yield 'random', {'HL': src, 'mem': {src: bytes(rnd.randrange(256) for _ in range(8))}}


def port(regs):
    import guards
    guards.LoadMazeDescriptor(regs['HL'])
    return {}
