#!/usr/bin/env python3
"""Compare two skool disassemblies of the same game (ours vs a reference).

  zxcompare.py OURS.skool REF.skool [--pairs PAIRS.tsv] [--start A] [--end B]

Prints a markdown report:
  - byte check: both describe the same bytes
  - classification agreement per byte (code / text / data / variables / unused)
  - entry boundaries: code entry starts and entry points found by each side
  - documentation volume: labels, titles, descriptions, comments
  - magic numbers left in the ASM output of each (skool2asm -H)
--pairs writes one row per entry address (both sides' type, label, title,
first description sentence) for a semantic review by a person or an agent.
"""
import argparse
import re
import subprocess
import sys

from skoolkit.skoolparser import SkoolParser

KIND = {'c': 'code', 't': 'text', 'g': 'vars', 'b': 'data', 'w': 'data', 's': 'data',
        'u': 'unused', 'i': 'ignored'}


def parse(path):
    return SkoolParser(path, asm_mode=1, html=False, asm_labels=True, create_labels=False)


def entries(parser, lo, hi):
    out = []
    for e in parser.memory_map:
        if e.ctl == 'i' or not e.instructions or e.address is None:
            continue
        if lo <= e.address < hi:
            out.append(e)
    return out


def byte_kinds(ents, hi):
    kinds = {}
    for n, e in enumerate(ents):
        end = ents[n + 1].address if n + 1 < len(ents) else hi
        for a in range(e.address, end):
            kinds[a] = KIND.get(e.ctl, e.ctl)
    return kinds


def first_sentence(text):
    text = re.sub(r'#R\$?([0-9A-Fa-f]+)(@\w+)?', r'$\1', ' '.join(text) if isinstance(text, list) else text)
    text = re.sub(r'\s+', ' ', text).strip()
    m = re.match(r'(.+?[.!?])(\s|$)', text)
    return (m.group(1) if m else text)[:200]


def doc_stats(ents):
    labels = sum(1 for e in ents for i in e.instructions if i.asm_label)
    labelled = sum(1 for e in ents if e.instructions[0].asm_label)
    comments = sum(1 for e in ents for i in e.instructions if i.comment and i.comment.text.strip())
    code_instr = sum(1 for e in ents if e.ctl == 'c' for i in e.instructions)
    code_comments = sum(1 for e in ents if e.ctl == 'c' for i in e.instructions
                        if i.comment and i.comment.text.strip())
    desc_words = sum(len(' '.join(e.details).split()) for e in ents)
    regs = sum(1 for e in ents if e.registers)
    mid = sum(1 for e in ents for i in e.instructions if i.mid_block_comment)
    return {
        'entries': len(ents),
        'entries with a label': labelled,
        'labels in total': labels,
        'instruction comments': comments,
        'code instructions commented': '%d/%d (%.0f%%)' % (code_comments, code_instr,
                                                           100.0 * code_comments / max(code_instr, 1)),
        'description words': desc_words,
        'entries with register sections': regs,
        'mid-block comments': mid,
    }


NUM = re.compile(r'(?<![\w$])(\$[0-9A-Fa-f]+|[0-9]+)(?![\w])')


def magic_numbers(skool):
    """Count numeric literals in instruction operands of the ASM output."""
    r = subprocess.run(['skool2asm.py', '-q', '-w', '-H', skool], capture_output=True, text=True)
    lines = r.stdout.splitlines()
    small = big = 0
    examples = []
    for line in lines:
        code = line.split(';')[0].strip()
        if not code or code.endswith(':') or code.upper().startswith(('DEF', 'ORG', 'IF', 'ENDIF')) \
                or ' EQU ' in code.upper():
            continue
        parts = code.split(None, 1)
        if len(parts) < 2:
            continue
        op = parts[1]
        if parts[0].upper() in ('RST', 'IM', 'BIT', 'SET', 'RES'):
            op = op.split(',', 1)[1] if ',' in op and parts[0].upper() != 'RST' else ''
        for m in NUM.finditer(op):
            v = int(m.group(1)[1:], 16) if m.group(1).startswith('$') else int(m.group(1))
            if v in (0, 1):
                continue
            if v >= 0x100:
                big += 1
                if len(examples) < 6:
                    examples.append(code)
            else:
                small += 1
    w = subprocess.run(['skool2asm.py', '-q', '-H', skool], capture_output=True, text=True)
    nolabel = w.stderr.count('No label for address')
    return {'16-bit literals': big, '8-bit literals (not 0/1)': small,
            'skool2asm "No label" warnings': nolabel, 'examples': examples}


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('ours')
    ap.add_argument('ref')
    ap.add_argument('--pairs')
    ap.add_argument('--start', type=lambda s: int(s, 0), default=0)
    ap.add_argument('--end', type=lambda s: int(s, 0), default=0x10000)
    a = ap.parse_args()

    po, pr = parse(a.ours), parse(a.ref)
    lo = max(a.start, min(e.address for e in entries(po, 0, 0x10000)),
             min(e.address for e in entries(pr, 0, 0x10000)))
    hi = a.end
    eo, er = entries(po, lo, hi), entries(pr, lo, hi)
    hi = min(hi, max(e.instructions[-1].address for e in eo) + 1,
             max(e.instructions[-1].address for e in er) + 1)
    hi = max(hi, lo)
    print('# Disassembly comparison\n')
    print('Ours: `%s`, reference: `%s`, range $%04X-$%04X.\n' % (a.ours, a.ref, lo, hi - 1))

    so, sr = po.snapshot, pr.snapshot
    diff = [x for x in range(lo, hi) if so[x] != sr[x]]
    print('## Bytes\n')
    print('%s\n' % ('identical' if not diff else '%d bytes differ, first at $%04X' % (len(diff), diff[0])))

    ko, kr = byte_kinds(eo, hi), byte_kinds(er, hi)
    cats = ['code', 'text', 'data', 'vars', 'unused']
    print('## Classification (bytes)\n')
    print('| ours \\ reference | ' + ' | '.join(cats) + ' |')
    print('| --- |' + ' ---: |' * len(cats))
    agree = total = 0
    for c1 in cats:
        row = []
        for c2 in cats:
            n = sum(1 for x in range(lo, hi) if ko.get(x) == c1 and kr.get(x) == c2)
            row.append(str(n))
            total += n
            agree += n if c1 == c2 else 0
        print('| %s | %s |' % (c1, ' | '.join(row)))
    code_agree = sum(1 for x in range(lo, hi) if (ko.get(x) == 'code') == (kr.get(x) == 'code'))
    print('\nSame category: %.1f%% of bytes; code vs non-code agreement: %.1f%%.\n'
          % (100.0 * agree / max(total, 1), 100.0 * code_agree / max(hi - lo, 1)))

    def starts(ents, kind):
        return {e.address for e in ents if KIND.get(e.ctl) == kind}

    def points(ents):
        return {i.address for e in ents for i in e.instructions[1:] if i.asm_label}

    print('## Entry boundaries\n')
    print('| | ours | reference | both |')
    print('| --- | ---: | ---: | ---: |')
    for name, fo in (('code entries', lambda es: starts(es, 'code')),
                     ('data/text/vars entries', lambda es: {e.address for e in es if e.ctl != 'c'}),
                     ('labelled entry points inside entries', points)):
        x, y = fo(eo), fo(er)
        print('| %s | %d | %d | %d |' % (name, len(x), len(y), len(x & y)))
    only_r = sorted(starts(er, 'code') - starts(eo, 'code'))
    only_o = sorted(starts(eo, 'code') - starts(er, 'code'))
    print('\nCode entries only in the reference: %s' % (' '.join('$%04X' % x for x in only_r) or '-'))
    print('\nCode entries only in ours: %s\n' % (' '.join('$%04X' % x for x in only_o) or '-'))

    print('## Documentation volume\n')
    do, dr = doc_stats(eo), doc_stats(er)
    print('| | ours | reference |')
    print('| --- | ---: | ---: |')
    for k in do:
        print('| %s | %s | %s |' % (k, do[k], dr[k]))

    print('\n## Magic numbers in ASM output\n')
    mo, mr = magic_numbers(a.ours), magic_numbers(a.ref)
    print('| | ours | reference |')
    print('| --- | ---: | ---: |')
    for k in mo:
        if k != 'examples':
            print('| %s | %s | %s |' % (k, mo[k], mr[k]))
    print()

    if a.pairs:
        by_o = {e.address: e for e in eo}
        by_r = {e.address: e for e in er}
        with open(a.pairs, 'w') as f:
            f.write('addr\tours_type\tours_label\tours_title\tours_desc\tref_type\tref_label\tref_title\tref_desc\n')
            for addr in sorted(set(by_o) | set(by_r)):
                row = ['$%04X' % addr]
                for e in (by_o.get(addr), by_r.get(addr)):
                    if e is None:
                        row += ['', '', '', '']
                    else:
                        row += [e.ctl, e.instructions[0].asm_label or '', first_sentence(e.description),
                                first_sentence(e.details)]
                f.write('\t'.join(c.replace('\t', ' ') for c in row) + '\n')
        print('Wrote %s.' % a.pairs)


if __name__ == '__main__':
    import signal
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)
    try:
        main()
    except (OSError, ValueError) as e:
        sys.exit(str(e))
