"""IsPlacingCommand: Z set when CommandId is one of the five placing verbs (drop in, put in, put on, take out of, throw through)."""
import _regs
ROUTINE = 'IsPlacingCommand'
INPUTS = ['HL', 'BC', 'CommandId']
OUTPUTS = {'regs': ['A', 'HL', 'BC', 'ZF', 'CF', 'SF'], 'mem': []}
KINDS = ['typical', 'boundary']
PLACING = [0x0E, 0x11, 0x12, 0x14, 0x2C]


def cases(rnd):
    for i in range(40):
        regs = {'HL': rnd.randrange(0x10000), 'BC': rnd.randrange(0x10000)}
        yield 'typical', dict(regs, mem={'CommandId': rnd.choice(PLACING)})
        yield 'typical', dict(regs, mem={'CommandId': rnd.randrange(256)})
    for cid in PLACING + [0x00, 0x0D, 0x0F, 0x13, 0x2B, 0x2D, 0xFF]:   # first, last, neighbours
        yield 'boundary', {'HL': 0x1234, 'BC': 0x5678, 'mem': {'CommandId': cid}}


def port(regs):
    import handlers
    return _regs.run(handlers.IsPlacingCommand, regs, OUTPUTS['regs'])
