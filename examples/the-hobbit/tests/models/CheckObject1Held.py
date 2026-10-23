"""CheckObject1Held: is the object in the holder chain of the subject (carry set when held)."""
import _objects as W
from labels import *  # noqa: F403
ROUTINE = 'CheckObject1Held'
INPUTS = []
OUTPUTS = W.out(['CF', 'HL', 'IX', 'A'], [])
KINDS = ['typical', 'boundary']
def cases(rnd):
    ids = W.IDS[1:] + [0xFF]
    for _ in range(200):
        a = rnd.choice(ids if "CheckObject1Held" != "WalkHolderChain" else W.IDS[1:])
        yield 'typical', W.case(rnd, A=a, **W.noise(rnd, 'IX'), mem={Subject: rnd.choice(W.IDS[:8]), FirstObject: a})
    for a in (0xFF, W.IDS[1], W.IDS[-1]):
        for subject in (0, W.IDS[1], 0xFF):
            yield 'boundary', W.case(rnd, A=a, **W.noise(rnd, 'IX'), mem={Subject: subject, FirstObject: a})


def port(regs):
    return W.run('CheckObject1Held', regs, OUTPUTS)
