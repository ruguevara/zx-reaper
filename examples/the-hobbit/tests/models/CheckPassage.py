"""CheckPassage: may the subject pass obstacle A (0 none) and enter TakeId with weight TakeWeight? A = 0 / PASS_BLOCKED / PASS_TOO_SMALL / PASS_TOO_FULL, Z set when it can pass; IX = obstacle (or destination) record; TakeObject set."""
import _regs
import _verbs
from labels import Subject, TakeId, TakeObject, TakeWeight

ROUTINE = 'CheckPassage'
INPUTS = ['A', 'mem']
OUTPUTS = {'regs': ['A', 'B', 'C', 'IX', 'ZF', 'CF'], 'mem': [(TakeObject, 2)]}
KINDS = ['typical', 'obstacle', 'boundary']

LOCATIONS = [0x01, 0x04, 0x07, 0x0B, 0x16, 0x1B, 0x22, 0x2A, 0x41, 0x4F]
OBSTACLES = [oid for oid, rec in _verbs.objects() if _verbs.byte(rec) != 1 or oid in (0x01, 0x12)]


def case(a, loc, weight, subject, mem=None):
    m = {TakeId: loc, TakeWeight: weight, Subject: subject}
    m.update(mem or {})
    return {'A': a, 'B': 0, 'C': 0, 'mem': m}


def cases(rnd):
    for loc in LOCATIONS:
        for w in (0, 5, 40, 120, 255):
            yield 'typical', case(0, loc, w, 0)
    recs = dict(_verbs.objects())
    for oid in OBSTACLES:
        rec = recs[oid]
        for subject in (0, 0x11):
            for w in (0, rnd.randrange(1, 60), _verbs.byte(rec + 2), 255):
                yield 'obstacle', case(oid, rnd.choice(LOCATIONS), w, subject)
        # the flags that decide it: neither active nor dead (blocked), state bit 7 (blocks the player)
        yield 'boundary', case(oid, 0x01, 0, 0, {rec + 7: _verbs.byte(rec + 7) & ~0x28})
        yield 'boundary', case(oid, 0x01, 0, 0, {rec + 7: _verbs.byte(rec + 7) | 0x20, rec + 4: 0x80})
    yield 'boundary', case(0, 0x50, 0, 0)                        # location out of range: FindLocation gives A = 0


def port(regs):
    import verbs
    return _regs.run(verbs.CheckPassage, regs, OUTPUTS['regs'])
