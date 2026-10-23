"""OutputEnabled: Z when ActionPerform and MessagesVisible share no bit; A and HL kept."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import _regs
import screen

ROUTINE = 'OutputEnabled'
INPUTS = ['A', 'HL', 'ActionPerform', 'MessagesVisible']
OUTPUTS = {'regs': ['A', 'HL', 'ZF', 'CF'], 'mem': []}
KINDS = ['typical', 'boundary']


def cases(rnd):
    for ap, mv in [(0, 0), (1, 0), (0, 1), (1, 1), (0xFF, 0), (0x80, 0x01)]:
        yield 'boundary', {'A': rnd.randrange(256), 'HL': rnd.randrange(65536), 'F': rnd.randrange(256),
                           'mem': {'ActionPerform': ap, 'MessagesVisible': mv}}
    for _ in range(30):
        yield 'typical', {'A': rnd.randrange(256), 'HL': rnd.randrange(65536), 'F': rnd.randrange(256),
                          'mem': {'ActionPerform': rnd.randrange(2), 'MessagesVisible': rnd.randrange(2)}}


def port(regs):
    return _regs.run(screen.OutputEnabled, regs, OUTPUTS['regs'])
