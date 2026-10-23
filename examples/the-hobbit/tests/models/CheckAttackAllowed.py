"""CheckAttackAllowed, the allowed case: no shared side bit (state +4 bits 4-6) between victim and attacker; Z set, IX = the attacker. (A refused attack drops the return address; the harness cannot follow that, so it is left to the whole-game check.)"""
import _regs
import _verbs
from labels import ActorRecord, Noun1Record, Subject

ROUTINE = 'CheckAttackAllowed'
INPUTS = ['mem']
OUTPUTS = {'regs': ['A', 'IX', 'ZF'], 'mem': [(Noun1Record, 2), ('ActionAllowed', 1), (0xC11B, 0x500)]}   # all records: the victim's state bit 4
KINDS = ['typical', 'boundary']


def side(rec, victim_of_player=False):
    st = _verbs.byte(rec + 4)
    return st & 0x70


def cases(rnd):
    objs = _verbs.objects()
    for subject in (0, 0x11):
        for oid, vrec in objs:
            for aid, arec in objs:
                v = side(vrec)
                if subject == 0:
                    v &= ~0x10                         # the player clears bit 4 of the victim first
                if v & side(arec):
                    continue
                m = {Noun1Record: [vrec & 0xFF, vrec >> 8], ActorRecord: [arec & 0xFF, arec >> 8], Subject: subject}
                if subject == 0 and aid == 0 and oid != 0:
                    yield 'typical', {'mem': m}
                elif rnd.random() < 0.01:
                    yield 'boundary', {'mem': m}
    # the victim carries state bit 4 and the player is the subject: the bit is cleared, then no shared bit
    for oid, vrec in objs:
        if _verbs.byte(vrec + 4) & 0x10 and not _verbs.byte(vrec + 4) & 0x60:
            m = {Noun1Record: [vrec & 0xFF, vrec >> 8], ActorRecord: [0x1B, 0xC1], Subject: 0}
            yield 'boundary', {'mem': m}


def port(regs):
    import verbs
    return _regs.run(verbs.CheckAttackAllowed, regs, OUTPUTS['regs'])
