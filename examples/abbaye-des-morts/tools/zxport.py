#!/usr/bin/env python3
"""Inputs of a stage 3 port on zxpyxel (docs/stage3.md in zx-reaper).

  zxport.py labels [SYMFILE] > port/labels.py   labels and constants as Python names
                                                 (default build/game.sym; run make first)
  zxport.py variables ASM... > port/variables.py the data labels of the asm as typed fields
                                                 of `v` (DEFB: byte, DEFW: word, more than
                                                 one: a table); sizes from build/game.sym
  zxport.py image SNAPSHOT OUT.bin              the 48K RAM of a snapshot ($4000-$FFFF)
  zxport.py check ENTRY RECORD...               the whole-game check (make port-test): the
                                                 port routine ENTRY (module.Routine in
                                                 port/) replays each zxrun.py --record from
                                                 port/image.bin and must match at every
                                                 checkpoint; prints the clock drift and
                                                 the routines no record ran
"""
import os
import re
import sys

DATA = re.compile(r'\s+(DEFB|DEFW|DEFS|DEFM|DB|DW|DS|DM)\b', re.I)


def labels(path):
    print('"""Labels and constants from %s (tools/zxport.py labels)."""' % path)
    for line in open(path):
        name, sep, value = line.partition(': EQU ')
        if sep and name.strip().isidentifier():
            print('%s = 0x%04X' % (name.strip(), int(value, 0)))


def symbols(path='build/game.sym'):
    syms = {}
    for line in open(path):
        name, sep, value = line.partition(': EQU ')
        if sep:
            syms[name.strip()] = int(value, 0)
    return syms


def variables(sources):
    """Each label whose first statement is a data directive, with its width
    (2 when every directive under it is DEFW) and its size up to the next
    label of the sources."""
    syms, kinds, label = symbols(), {}, None
    for path in sources:
        for line in open(path):
            code = line.split(';')[0]
            m = re.match(r'([A-Za-z_]\w*):', code)
            if m:
                label = m.group(1)
                kinds[label] = []
            elif code.strip() and label is not None:
                d = DATA.match(code)
                if not kinds[label] and not d:
                    label = None            # code
                elif d:
                    kinds[label].append(d.group(1).upper().replace('DEF', 'D'))
    addrs = sorted(syms[k] for k in kinds if k in syms)
    print('"""The data of the game as typed fields of `v`, widths from the asm\n'
          '(tools/zxport.py variables). mem/mem16 for computed addresses."""')
    print('from zxpyxel import mem\nfrom zxpyxel.memory import Byte, Table, Variables, Word\n\n')
    print('class Data(Variables):')
    for name in sorted((k for k in kinds if kinds[k] and k in syms), key=syms.get):
        a = syms[name]
        nxt = next((b for b in addrs if b > a), None)
        if nxt is None:
            continue                        # the last label: size unknown
        width = 2 if set(kinds[name]) == {'DW'} else 1
        n = (nxt - a) // width
        field = (('Word(0x%04X)' if width == 2 else 'Byte(0x%04X)') % a if n == 1
                 else 'Table(0x%04X, %d%s)' % (a, n, ', 2' if width == 2 else ''))
        print('    %s = %s' % (name, field))
    print('\n\nv = Data(mem)')


def image(snapshot, out):
    from skoolkit.snapshot import Snapshot
    snap = Snapshot.get(snapshot)
    if snap is None or len(snap.ram(-1)) != 0xC000:
        sys.exit('%s: not a 48K snapshot' % snapshot)
    with open(out, 'wb') as f:
        f.write(bytes(snap.ram(-1)))


def check(entry, records):
    sys.path.insert(0, 'port')
    import labels
    from zxpyxel import T_FRAME, headless, zx
    module, routine = entry.rsplit('.', 1)
    main = getattr(__import__(module), routine)
    ram = open('port/image.bin', 'rb').read()
    ran = set()
    for path in records:
        zx.reset(ram)
        sys.setprofile(lambda frame, event, arg: event == 'call' and ran.add(frame.f_code))
        try:
            passes, z80_t, port_t = headless.replay(main, path, labels)
        except headless.Mismatch as e:
            sys.exit('%s: MISMATCH %s' % (path, e))
        finally:
            sys.setprofile(None)
        if not passes:
            sys.exit('%s: the Z80 never reached the checkpoint' % path)
        print('%s: %d checkpoints match; at the last, Z80 frame %d, port frame %d (%+.1f%%)' % (
            path, passes, z80_t // T_FRAME, port_t // T_FRAME, 100 * (port_t / z80_t - 1)))
    never = sorted(name for code, name in routines().items() if code not in ran)
    if never:
        print('never ran in any record (add an input that reaches them): ' + ', '.join(never))


def routines():
    """The port's routines: functions named as labels (capitalised) in port/*.py."""
    port, out = os.path.abspath('port'), {}
    for m in list(sys.modules.values()):
        path = getattr(m, '__file__', None)
        if not path or os.path.dirname(os.path.abspath(path)) != port:
            continue
        for name, f in vars(m).items():
            if name[:1].isupper() and getattr(f, '__module__', None) == m.__name__ \
                    and hasattr(f, '__code__'):
                out[f.__code__] = '%s.%s' % (m.__name__, name)
    return out


if __name__ == '__main__':
    a = sys.argv[1:]
    if a[:1] == ['labels'] and len(a) <= 2:
        labels(a[1] if len(a) == 2 else 'build/game.sym')
    elif a[:1] == ['variables'] and len(a) >= 2:
        variables(a[1:])
    elif a[:1] == ['image'] and len(a) == 3:
        image(a[1], a[2])
    elif a[:1] == ['check'] and len(a) >= 3:
        check(a[1], a[2:])
    else:
        sys.exit(__doc__)
