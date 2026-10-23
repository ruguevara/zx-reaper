"""MoveContents: set the first location of everything a holder holds, recursively; clears MoveFlag at id 0."""
import _objects as W
from labels import *  # noqa: F403
ROUTINE = 'MoveContents'
INPUTS = []
OUTPUTS = W.out(['A', 'IX', 'IY'], [('MoveFlag', 1), W.OBJECTS_REGION])
KINDS = ['typical', 'boundary']
def cases(rnd):
    for _ in range(150):
        holder = rnd.choice(W.IDS[:20])
        yield 'typical', W.case(rnd, A=holder, B=rnd.randrange(0x50), mem={MoveFlag: 1}, **W.noise(rnd, 'IX', 'IY'))
    for holder in (0, 0xFF, 0x77, W.IDS[-1]):
        yield 'boundary', W.case(rnd, A=holder, B=0x1D, mem={MoveFlag: 1}, **W.noise(rnd, 'IX', 'IY'))
    for k in range(10):                            # the player carried by a holder
        yield "boundary", W.case(rnd, False, A=W.IDS[k + 1], B=5, mem={MoveFlag: 1, W.REC[0] + 1: W.IDS[k + 1]}, **W.noise(rnd, 'IX', 'IY'))


def port(regs):
    return W.run('MoveContents', regs, OUTPUTS)
