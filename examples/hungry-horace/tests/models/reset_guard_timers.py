"""ResetGuardTimers clears GuardsReleased and sets the four guard timers to 0, n, 2n, 4n (times 256)."""
ROUTINE = 'ResetGuardTimers'
INPUTS = ['GuardInterval (memory)']
OUTPUTS = {'regs': [], 'mem': [('GuardsReleased', 1), ('GuardTimers', 8)]}
KINDS = ['typical', 'overflow']


def cases(rnd):
    for n in range(1, 9):
        yield 'typical', {'mem': {sym('GuardInterval'): n, sym('GuardsReleased'): rnd.randrange(5)}}
    for n in (0, 0x40, 0x41, 0x7F, 0x80, 0xFF):     # 2n and 4n wrap in the high byte (SLA H)
        yield 'overflow', {'mem': {sym('GuardInterval'): n}}


def port(regs):
    import guards
    guards.ResetGuardTimers()
    return {}
