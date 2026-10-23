"""The routine at $80D0 (cellad in the fixture source) returns the attribute address ATTRS + 32*PY + PX."""
ROUTINE = 0x80D0
OUTPUTS = {'regs': ['HL']}
KINDS = ['typical', 'boundary']


def cases(rnd):
    for _ in range(200):
        yield 'typical', {'mem': {'PX': rnd.randrange(32), 'PY': rnd.randrange(24)}}
    for x in (0, 31):
        for y in (0, 23):
            yield 'boundary', {'mem': {'PX': x, 'PY': y}}


def model(regs, mem):
    return {'HL': 0x5800 + 32 * mem[sym('PY')] + mem[sym('PX')]}
