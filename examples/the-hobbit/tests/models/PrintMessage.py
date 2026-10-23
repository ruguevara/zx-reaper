"""PrintMessage: print a real message of the game (those without name or stack codes) in the story window,
with the subject and first object set or not, in a test pass (ActionPerform 0) or for real."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import _text
import printer

ROUTINE = 'PrintMessage'
INPUTS = ['HL', 'A', 'DE', 'IX', 'story window state', 'ActionPerform', 'Subject', 'FirstObject']
OUTPUTS = {'regs': ['A', 'DE', 'IX', 'B'],
           'mem': _text.STORY_MEM + [('SavedDE', 3), ('SavedIX', 2), ('ActionAllowed', 1)]}
KINDS = ['typical', 'boundary']
STATE_CODES = {0, 1, 3, 4, 6, 7, 8, 9, 12, 16, 17, 19}   # names and stack words: need other modules


def message_ok(ram, addr, depth=0):
    """Does the message at addr use only the codes this module's tests can run?"""
    while depth < 6:
        b = ram[addr]
        if b & 0x80:
            if (b & 0x70) in (0x20, 0x30, 0x60):
                return True
            addr += 2
        elif b < 0x20:
            if b in STATE_CODES:
                return False
            if b >= 0x14:
                return True
            if b in (2, 11):
                d = ram[addr + 1]
                target = addr + 1 + (d - 256 if d > 127 else d)
                if b == 2:
                    addr = target
                    continue
                if not message_ok(ram, target, depth + 1):
                    return False
            addr += 2 if b in (2, 11) else 1
        else:
            addr += 1
    return False


def starts(ram):
    import labels
    return sorted({v for k, v in vars(labels).items() if k.startswith('Msg') and isinstance(v, int)}
                  | {0xADA9, 0xADC4, 0xAFB5, 0xB018, 0xB143})


def cases(rnd):
    from skoolkit.snapshot import Snapshot
    ram = list(Snapshot.get('re/orig.z80').ram())
    ram = [0] * 0x4000 + ram if len(ram) == 0xC000 else ram
    good = [a for a in starts(ram) if message_ok(ram, a)]
    for n, addr in enumerate(good):
        mem = _text.story_state(rnd, column=rnd.choice([42, 42, 20]), last=rnd.choice([0, 0x41]),
                                capital=rnd.randrange(2))
        mem.update({'Subject': rnd.choice([0, 5]), 'FirstObject': rnd.choice([0, 5]),
                    'ActionPerform': rnd.choice([1, 1, 0]), 'MessagesVisible': 1})
        yield ('boundary' if n < 6 else 'typical'), {'HL': addr, 'A': rnd.randrange(256), 'DE': rnd.randrange(65536),
                                                     'IX': rnd.randrange(65536), 'B': rnd.randrange(256), 'mem': mem}


def port(regs):
    return _text.run_async(printer.PrintMessage, regs, OUTPUTS['regs'])
