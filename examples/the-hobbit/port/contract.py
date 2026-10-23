"""Check port modules against CONTRACT.md: every routine of the module's table
is defined, async exactly where the table says, and the module imports.

  python3 port/contract.py [MODULE ...]      (default: every module in the table)
"""
import importlib
import inspect
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)


def table():
    rows, mod = {}, None
    for line in open(os.path.join(HERE, 'CONTRACT.md')):
        m = re.match(r'^### (\w+)\.py', line)
        if m:
            mod = m.group(1)
        m = re.match(r'^\| \$[0-9A-F]{4} \| `(\w+)` \| (async)? \|', line)
        if m and mod:
            rows.setdefault(mod, []).append((m.group(1), m.group(2) == 'async'))
    return rows


def main():
    rows = table()
    bad = 0
    for mod in sys.argv[1:] or sorted(rows):
        try:
            m = importlib.import_module(mod)
        except Exception as e:                     # noqa: BLE001  (report and go on)
            print('%s: does not import: %s' % (mod, e))
            bad += 1
            continue
        for name, is_async in rows[mod]:
            fn = getattr(m, name, None)
            if not inspect.isfunction(fn) or fn.__module__ != mod:
                print('%s.%s: missing' % (mod, name))
                bad += 1
            elif inspect.iscoroutinefunction(fn) != is_async:
                print('%s.%s: should %sbe async' % (mod, name, '' if is_async else 'not '))
                bad += 1
    print('contract: %d problems' % bad)
    sys.exit(1 if bad else 0)


if __name__ == '__main__':
    main()
