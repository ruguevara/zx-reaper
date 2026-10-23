"""CheckSoundKey toggles SoundMask on a press of T; here the keyboard reads no key."""
ROUTINE = 'CheckSoundKey'
INPUTS = ['SoundKeyState', 'SoundMask (memory)']
OUTPUTS = {'regs': [], 'mem': [('SoundMask', 1), ('SoundKeyState', 1)]}
KINDS = ['no-key']


def cases(rnd):
    for state in (0x10, 0, 0x08):       # T was up; T was down (released now); stale
        for mask in (0x1F, 0x07):
            yield 'no-key', {'mem': {sym('SoundKeyState'): state, sym('SoundMask'): mask}}


def port(regs):
    import events
    events.CheckSoundKey()
    return {}
