"""GetTableWord: the word for an id (bit 7 ignored) from a word table at HL."""
import _objects as W
from labels import *  # noqa: F403
ROUTINE = 'GetTableWord'
INPUTS = []
OUTPUTS = W.out(['A', 'DE', 'HL'], [])
KINDS = ['typical', 'boundary']
def cases(rnd):
    for table in (ReasonWords1, ReasonWords2, NameWordTable):
        for _ in range(40):
            yield 'typical', W.case(rnd, False, A=rnd.randrange(0, 8), HL=table, **W.noise(rnd, 'DE'))
    for a in (0, 0x7F, 0x80, 0xFF):
        yield 'boundary', W.case(rnd, False, A=a, HL=ReasonWords1, **W.noise(rnd, 'DE'))


def port(regs):
    return W.run('GetTableWord', regs, OUTPUTS)
