#!/usr/bin/env python3
"""Print the map of locations and exits as a Mermaid flowchart, from the bytes.

Location records: pointers at $B9E0 (80 words), +2/+4/+6 name phrase codes
(noun, adjective, adjective), +10 exits (direction, obstacle, destination) to $FF.
Objects: (id, address) pairs at $C063 to $FF, name phrase codes at +8/+10/+12.
Blocked exits: 5 records of 6 bytes at $C80E (location, triple address, saved triple).
Usage: python3 scripts/locmap.py [re/image.z80]
"""
import sys
from collections import defaultdict

sys.path.insert(0, 'scripts')
from text import Text

DIRS = {1: 'n', 2: 's', 3: 'e', 4: 'w', 5: 'ne', 6: 'nw', 7: 'se', 8: 'sw', 9: 'u', 10: 'd'}
REGIONS = [  # grouped by the location names (an editorial grouping, not game data)
    ('Bag End to Rivendell', [0x01, 0x04, 0x05, 0x06, 0x07, 0x09]),
    ('Misty Mountains', [0x0A, 0x0B, 0x0C, 0x0E] + list(range(0x44, 0x50))),
    ('Goblin caves', [0x0D, 0x0F, 0x10, 0x11, 0x12, 0x13, 0x14] + list(range(0x34, 0x42))),
    ('Beorn and Mirkwood', [0x15, 0x16, 0x17, 0x18, 0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x2E,
                            0x02, 0x03, 0x08, 0x2D, 0x30, 0x31, 0x32, 0x42, 0x43]),
    ("Elvenking's halls", [0x1E, 0x1F, 0x20]),
    ('Long Lake', [0x21, 0x22, 0x23, 0x24]),
    ('Lonely Mountain', [0x25, 0x26, 0x27, 0x28, 0x29, 0x2A, 0x2B, 0x2C, 0x2F, 0x33]),
]


def main(src='re/image.z80'):
    t = Text(src)
    m = t.m
    w16 = lambda a: m[a] | m[a + 1] << 8

    def phrase(a, order):
        return ' '.join(t.word(w16(a + k) & 0xFFF) for k in order if w16(a + k) & 0xFFF)

    objs, a = {}, 0xC063
    while m[a] != 0xFF:
        objs[m[a]] = phrase(w16(a + 1), (10, 12, 8))
        a += 3
    blocked = {w16(0xC80E + 6 * i + 1) for i in range(5)}
    names, edges = {}, defaultdict(list)
    for loc in range(80):
        r = w16(0xB9E0 + 2 * loc)
        names[loc] = phrase(r, (4, 6, 2)) or 'no place'
        p = r + 10
        while loc and m[p] != 0xFF:
            d, ob, dest = m[p:p + 3]
            if d:
                edges[(loc, dest)].append((DIRS[d], objs[ob] if ob else '', p in blocked))
            p += 3
    node = lambda n: f'L{n:02X}'
    out = ['```mermaid', 'flowchart LR']
    for title, ids in REGIONS:
        out.append(f'  subgraph "{title}"')
        out += [f'    {node(i)}["{i:02X} {names[i]}"]' for i in ids]
        out.append('  end')
    out.append(f'  {node(0)}["00 empty record"]')
    done = set()
    for (a, b), ex in sorted(edges.items()):
        if (a, b) in done:
            continue
        back = edges.get((b, a)) if a != b else None
        if back:
            done.add((b, a))
        both = ex + (back or [])
        label = ','.join(d for d, _, _ in ex) + (' / ' + ','.join(d for d, _, _ in back) if back else '')
        obs = sorted({o for _, o, _ in both if o})
        label += (': ' + ', '.join(obs)) if obs else ''
        label += ' (blockable)' if any(bl for _, _, bl in both) else ''
        dashed = any(o or bl for _, o, bl in both)
        arrow = ('<-.->' if dashed else '<-->') if back else ('-.->' if dashed else '-->')
        out.append(f'  {node(a)} {arrow}|"{label}"| {node(b)}')
    out.append('```')
    print('\n'.join(out))


if __name__ == '__main__':
    main(*sys.argv[1:])
