"""CheckNounsDistinct: reject a command that uses the same object twice."""
import _objects as W
from labels import *  # noqa: F403
ROUTINE = 'CheckNounsDistinct'
INPUTS = []
OUTPUTS = W.out(['A', 'HL', 'ZF', 'CF', 'SF'], [])
KINDS = ['typical', 'boundary']
def cases(rnd):
    ids = W.IDS[:6] + [0xFF]
    for _ in range(200):
        yield 'typical', W.case(rnd, False, mem={FirstObject: rnd.choice(ids[:6]), SecondObject: rnd.choice(ids),
                                                 Subject: rnd.choice(ids[:6]), Noun1Kind: rnd.choice([0, 0, 0x80]),
                                                 Noun2Kind: rnd.choice([0, 0, 0x40])}, **W.noise(rnd, 'HL', 'A'))
    for first in (0xFF, 0, 1):
        for n1 in (0, 1):
            for n2 in (0, 1):
                for second, subject in ((first, 2), (3, first), (3, 4), (2, 2), (first, first)):
                    yield 'boundary', W.case(rnd, False, mem={FirstObject: first, SecondObject: second, Subject: subject,
                                                              Noun1Kind: n1, Noun2Kind: n2})


def port(regs):
    return W.run('CheckNounsDistinct', regs, OUTPUTS)
