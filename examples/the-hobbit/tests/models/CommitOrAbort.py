"""CommitOrAbort, the path that returns: ActionPerform is 1. (Otherwise the Z80 drops the caller's return
address, which a test cannot follow; the port returns False there.)"""
import _objects as W
from labels import *  # noqa: F403
ROUTINE = 'CommitOrAbort'
INPUTS = []
OUTPUTS = W.out(['A', 'ZF', 'CF', 'SF', 'BC'], [('ActionAllowed', 1)])
KINDS = ['typical', 'boundary']


def cases(rnd):
    for _ in range(20):
        yield 'typical', W.case(rnd, False, A=rnd.randrange(256), F=rnd.randrange(256), mem={ActionPerform: 1, ActionAllowed: rnd.randrange(2)}, **W.noise(rnd, 'BC'))
    yield 'boundary', W.case(rnd, False, mem={ActionPerform: 1, ActionAllowed: 0xFF}, BC=0)


def port(regs):
    import objects
    out = W.run('CommitOrAbort', regs, OUTPUTS)
    assert objects.r.zf and objects.v.ActionPerform == 1
    return out
