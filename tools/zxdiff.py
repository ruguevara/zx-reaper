#!/usr/bin/env python3
"""Differential tests: run Z80 routines on generated cases and compare them
with Python models (annotation check) or ports (port check).

  zxdiff.py [MODEL.py ...] [options]      default: every tests/models/*.py
  zxdiff.py MODEL.py --dump cases.jsonl   golden input/output pairs from the Z80
                                          code, for testing a C or other port
Options:
  --snapshot FILE   machine state to run in (default re/orig.z80)
  --sym FILE        symbols from sjasmplus --sym (default build/game.sym; run make)
  --seed N          random seed (default 1)
  --status FILE     write a per-routine status table (default tests/models/STATUS.md
                    when no MODEL is given)

A model is a Python file:

    ROUTINE = 'StepCell'              # label (from the symbol file) or address
    INPUTS = ['A', 'HL']              # registers the cases set (documentation)
    OUTPUTS = {'regs': ['HL'],        # registers compared after the routine returns
               'mem': [('Score', 2)]} # memory ranges compared (label or address, length)
    KINDS = ['typical', 'boundary']   # case kinds that must be present

    def cases(rnd):                   # yield (kind, {'A': 1, 'HL': 0x0800,
        ...                           #               'mem': {addr: byte or bytes}})

    def model(regs, mem):             # regs: input registers; mem: read-only memory
        ...                           # return {'HL': value, 'mem': {addr: byte}}

Names `sym('Label')` and `const('NAME')` are available inside the model
(both read the symbol file). A pass covers only the generated cases, not
every input; say which kinds were tested when you cite a result.
"""
import argparse
import importlib.util
import json
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from skoolkit import CSimulator  # noqa: E402
from skoolkit.simulator import Simulator  # noqa: E402
from skoolkit.simutils import from_memory  # noqa: E402
from skoolkit.snapshot import Snapshot  # noqa: E402
from skoolkit import simutils  # noqa: E402
from zxrun import Tracer  # noqa: E402

PAIRS = {'AF': ('A', 'F'), 'BC': ('B', 'C'), 'DE': ('D', 'E'), 'HL': ('H', 'L'),
         'IX': ('IXh', 'IXl'), 'IY': ('IYh', 'IYl')}
SENTINEL = 0x0001
MAX_OPS = 5000000


def reg_get(regs, name):
    shadow = name.startswith('^')
    base = name[1:] if shadow else name
    if base in PAIRS:
        hi, lo = PAIRS[base]
        if shadow:
            hi, lo = 'x' + hi, 'x' + lo
        return regs[getattr(simutils, hi)] * 256 + regs[getattr(simutils, lo)]
    if base == 'SP':
        return regs[simutils.SP]
    idx = getattr(simutils, ('x' + base) if shadow else base)
    return regs[idx]


def load_symbols(path):
    syms = {}
    if os.path.exists(path):
        for line in open(path):
            name, sep, rest = line.partition(': EQU ')
            if sep:
                syms[name.strip()] = int(rest.strip(), 0)
    return syms


class ReadOnlyMemory:
    def __init__(self, data):
        self._data = data

    def __getitem__(self, i):
        return self._data[i]

    def word(self, addr):
        return self._data[addr] | self._data[(addr + 1) & 0xFFFF] << 8


def load_model(path, syms):
    spec = importlib.util.spec_from_file_location(os.path.splitext(os.path.basename(path))[0], path)
    mod = importlib.util.module_from_spec(spec)

    def sym(name):
        if name not in syms:
            raise KeyError('unknown symbol %s (run make to refresh the symbol file)' % name)
        return syms[name]
    mod.sym = mod.const = sym
    spec.loader.exec_module(mod)
    return mod


def resolve(value, syms):
    return syms[value] if isinstance(value, str) else value


def run_case(base, start, case, out_spec, syms):
    mem = list(base)
    for addr, val in case.get('mem', {}).items():
        addr = resolve(addr, syms)
        vals = list(val) if isinstance(val, (bytes, bytearray, list, tuple)) else [val]
        for k, v in enumerate(vals):
            mem[(addr + k) & 0xFFFF] = v & 0xFF
    regs = {k: v for k, v in case.items() if k != 'mem'}
    regs.setdefault('SP', 0xFF00)
    sim = from_memory(CSimulator or Simulator, mem, regs, {'iff': 0, 'im': 1},
                      {'fast_djnz': False, 'fast_ldir': False})
    sim.set_tracer(Tracer())
    sp = (sim.registers[simutils.SP] - 2) & 0xFFFF
    sim.memory[sp], sim.memory[sp + 1] = SENTINEL & 255, SENTINEL >> 8
    sim.registers[simutils.SP] = sp
    cond, ops = sim.trace(start, SENTINEL, MAX_OPS, 0, 0, None, None, [0] * 8, None, None)
    if sim.registers[simutils.PC] != SENTINEL:
        return None, mem
    out = {r: reg_get(sim.registers, r) for r in out_spec.get('regs', [])}
    out_mem = {}
    for start_addr, length in out_spec.get('mem', []):
        a = resolve(start_addr, syms)
        for k in range(length):
            out_mem[(a + k) & 0xFFFF] = sim.memory[(a + k) & 0xFFFF]
    out['mem'] = out_mem
    return out, mem


def expected_from_model(mod, case, mem_before, out_spec, syms):
    regs_in = {k: v for k, v in case.items() if k != 'mem'}
    res = mod.model(dict(regs_in), ReadOnlyMemory(mem_before))
    exp = {r: res[r] & (0xFF if len(r.lstrip('^')) == 1 else 0xFFFF)
           for r in out_spec.get('regs', []) if r in res}
    writes = {resolve(a, syms): v & 0xFF for a, v in res.get('mem', {}).items()}
    exp_mem = {}
    for start_addr, length in out_spec.get('mem', []):
        a = resolve(start_addr, syms)
        for k in range(length):
            addr = (a + k) & 0xFFFF
            exp_mem[addr] = writes.get(addr, mem_before[addr])
    exp['mem'] = exp_mem
    return exp


def fmt(d):
    parts = ['%s=$%04X' % (k, v) if v > 255 or len(k.lstrip('^')) == 2 else '%s=$%02X' % (k, v)
             for k, v in d.items() if k != 'mem']
    if d.get('mem'):
        parts.append('mem ' + ' '.join('$%04X:%02X' % kv for kv in sorted(d['mem'].items())))
    return ' '.join(parts)


def test_model(path, base, syms, seed, dump=None):
    mod = load_model(path, syms)
    start = resolve(mod.ROUTINE, syms)
    out_spec = getattr(mod, 'OUTPUTS', {})
    rnd = random.Random(seed)
    counts, fails, examples = {}, {}, []
    dump_f = open(dump, 'w') if dump else None
    for kind, case in mod.cases(rnd):
        counts[kind] = counts.get(kind, 0) + 1
        got, mem_before = run_case(base, start, case, out_spec, syms)
        if dump_f:
            dump_f.write(json.dumps({'kind': kind, 'in': {k: v for k, v in case.items() if k != 'mem'},
                                     'in_mem': {str(resolve(a, syms)): v if isinstance(v, int) else list(v)
                                                for a, v in case.get('mem', {}).items()},
                                     'out': None if got is None else
                                     {k: v for k, v in got.items() if k != 'mem'},
                                     'out_mem': None if got is None else
                                     {str(a): v for a, v in got['mem'].items()}}) + '\n')
        if not hasattr(mod, 'model'):
            continue
        exp = expected_from_model(mod, case, mem_before, out_spec, syms)
        if got != exp:
            fails[kind] = fails.get(kind, 0) + 1
            if len(examples) < 5:
                examples.append((kind, case, got, exp))
    if dump_f:
        dump_f.close()
    missing = [k for k in getattr(mod, 'KINDS', []) if not counts.get(k)]
    total, bad = sum(counts.values()), sum(fails.values())
    name = mod.ROUTINE if isinstance(mod.ROUTINE, str) else '$%04X' % start
    print('%s (%s): %d cases, %d mismatches  [%s]' % (
        name, os.path.basename(path), total, bad,
        ', '.join('%s %d/%d' % (k, counts[k] - fails.get(k, 0), counts[k]) for k in counts)))
    for kind, case, got, exp in examples:
        print('  %-9s in:  %s' % (kind, fmt({k: v for k, v in case.items() if k != 'mem'})))
        print('            z80: %s' % ('did not return' if got is None else fmt(got)))
        print('            mod: %s' % fmt(exp))
    if missing:
        print('  missing case kinds: %s' % ', '.join(missing))
    ok = bad == 0 and not missing and total > 0
    return {'routine': name, 'model': os.path.basename(path), 'cases': total, 'mismatches': bad,
            'kinds': counts, 'missing': missing, 'ok': ok,
            'doc': (mod.__doc__ or '').strip().split('\n')[0]}


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0],
                                 formatter_class=argparse.RawDescriptionHelpFormatter,
                                 epilog='\n'.join(__doc__.split('\n')[2:]))
    ap.add_argument('models', nargs='*')
    ap.add_argument('--snapshot', default='re/orig.z80')
    ap.add_argument('--sym', default='build/game.sym')
    ap.add_argument('--seed', type=int, default=1)
    ap.add_argument('--dump')
    ap.add_argument('--status')
    a = ap.parse_args()
    models = a.models or sorted(os.path.join('tests/models', f) for f in os.listdir('tests/models')
                                if f.endswith('.py') and not f.startswith('_'))
    status = a.status or (None if a.models else 'tests/models/STATUS.md')
    snap = Snapshot.get(a.snapshot)
    base = [0] * 16384 + list(snap.ram(-1))[:49152]
    from skoolkit import ROM48, read_bin_file
    base[:16384] = list(read_bin_file(ROM48))
    syms = load_symbols(a.sym)
    results = [test_model(m, base, syms, a.seed, a.dump if len(models) == 1 else None) for m in models]
    if status:
        with open(status, 'w') as f:
            f.write('# Differential test status\n\nGenerated by `tools/zxdiff.py`; a pass covers '
                    'only the generated cases.\n\n| Routine | Model | Cases | Kinds | Result |\n'
                    '| --- | --- | ---: | --- | --- |\n')
            for r in results:
                f.write('| %s | [%s](%s) | %d | %s | %s |\n' % (
                    r['routine'], r['model'], r['model'], r['cases'],
                    ', '.join('%s %d' % kv for kv in r['kinds'].items()),
                    'pass' if r['ok'] else '**%d mismatches%s**' % (
                        r['mismatches'], ', missing ' + '/'.join(r['missing']) if r['missing'] else '')))
    sys.exit(0 if all(r['ok'] for r in results) else 1)


if __name__ == '__main__':
    import signal
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)
    main()
