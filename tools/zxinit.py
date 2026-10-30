#!/usr/bin/env python3
"""Create a reverse-engineering project from an original tape.

  zxinit.py ORIGINAL.tap|tzx PROJECTDIR [--frames N] [--rzx FILE ...]

Steps (all mechanical, no judgement needed):
 1. copy zx-reaper's template/ and tools/ into PROJECTDIR, zxpyxel/ into port/,
    the tape into original/
 2. split the tape into a manifest + payloads (re/tape/)
 3. simulated LOAD -> re/orig.z80 (machine state at handover to the game)
 4. BASIC blocks -> src/*.bas (lossless text), loading screen -> data/
 5. load-time image (handover snapshot + every headed block patched in)
    -> re/image.z80, the reference the disassembly describes
 6. coverage: random input for N frames (+ RZX files) -> re/maps/*.map
 7. sna2ctl + sna2skool over the code region -> re/skool/ (one file per entry)
 8. src/build.asm (SAVEBIN per block), tape/tape.txt, re/layout.mk
After this `make` must report IDENTICAL: the project starts byte-exact and
every later step is a refactoring checked by `make`.
"""
import argparse
import os
import shutil
import subprocess
import sys

KIT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(KIT, 'tools'))
import zxbasic  # noqa: E402
import zxtape   # noqa: E402

FUZZ_KEYS = 'Q,A,O,P,M,N,Z,X,SPACE,ENTER,0,1,2,3,4,5,KF,KL,KR,KU,KD'


def run(cmd, cwd, log=None):
    print('$ ' + ' '.join(cmd))
    r = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)
    if log:
        with open(os.path.join(cwd, log), 'a') as f:
            f.write('$ %s\n%s%s' % (' '.join(cmd), r.stdout, r.stderr))
    if r.returncode:
        sys.exit('command failed:\n%s%s' % (r.stdout, r.stderr))
    return r.stdout


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[1].strip(),
                                 formatter_class=argparse.RawDescriptionHelpFormatter,
                                 epilog=__doc__.split('\n', 3)[3])
    ap.add_argument('tape')
    ap.add_argument('project')
    ap.add_argument('--frames', type=int, default=6000, help='frames of random input for coverage')
    ap.add_argument('--rzx', action='append', default=[], help='RZX recording for coverage')
    ap.add_argument('--force', action='store_true', help='reuse an existing project directory')
    a = ap.parse_args()

    if os.path.exists(a.project) and os.listdir(a.project) and not a.force:
        sys.exit('%s exists and is not empty (use --force)' % a.project)
    tape = os.path.abspath(a.tape)
    rzx = [os.path.abspath(r) for r in a.rzx]
    p = a.project
    shutil.copytree(os.path.join(KIT, 'template'), p, dirs_exist_ok=True)
    shutil.copytree(os.path.join(KIT, 'tools'), os.path.join(p, 'tools'), dirs_exist_ok=True,
                    ignore=shutil.ignore_patterns('__pycache__', 'zxinit.py'))
    shutil.copytree(os.path.join(KIT, 'zxpyxel'), os.path.join(p, 'port', 'zxpyxel'),
                    dirs_exist_ok=True, ignore=shutil.ignore_patterns('__pycache__', 'test_*'))
    for d in ('original', 're/tape', 're/maps', 're/rzx', 'src', 'data', 'tape',
              'tests/inputs', 'tests/expected', 'scripts', '.claude', '.agents'):
        os.makedirs(os.path.join(p, d), exist_ok=True)
    for agent in ('.claude', '.agents'):   # Claude Code, Codex
        skills = os.path.join(p, agent, 'skills')
        if not os.path.lexists(skills):
            os.symlink('../skills', skills)
    os.chdir(p)
    p = '.'
    ext = os.path.splitext(tape)[1].lower()
    orig = 'original/game' + ext
    shutil.copy(tape, orig)
    for r in rzx:
        shutil.copy(r, 're/rzx')

    # 2. tape -> manifest + payloads
    zxtape.split(orig, 're/tape')
    manifest = open(os.path.join(p, 're/tape/tape.txt')).read().splitlines()
    for line in manifest:
        print('   ' + line)

    # 3. simulated LOAD to the handover point
    run(['tap2sna.py', orig, 're/orig.z80'], p, 're/tap2sna.log')

    # 4./5. classify blocks, write sources and the load-time image
    out_manifest = []
    savebins = []
    patches = []
    todo = []
    header = None
    n_block = -1
    for line in manifest:
        tokens = line.split()
        kind = next((t for t in tokens if t in ('header', 'data', 'raw')), None)
        if kind is None or line.startswith('format') or line.startswith('tzx '):
            out_manifest.append(line)
            continue
        n_block += 1
        if kind == 'header':
            header = zxtape.parse_kv(tokens)[0]
            header['type'] = tokens[tokens.index('header') + 1]
            out_manifest.append(line)
            continue
        path = tokens[tokens.index(kind) + (2 if kind == 'data' else 1)]
        payload = open(os.path.join(p, path), 'rb').read()
        nn = os.path.splitext(os.path.basename(path))[0]
        new = None
        if header and kind == 'data' and len(payload) == header['len']:
            if header['type'] == 'program':
                bas = 'src/loader%s.bas' % ('' if nn == '01' else nn)
                text = zxbasic.list_program(payload, header['p2'])
                open(os.path.join(p, bas), 'w').write(text)
                new = 'build/%s.bin' % os.path.splitext(os.path.basename(bas))[0]
            elif header['type'] == 'code' and len(payload) == 6912:
                # a screen: LOAD "" SCREEN$ ignores the header address
                shutil.copy(os.path.join(p, path), os.path.join(p, 'data/screen%s.scr' % nn))
                new = 'data/screen%s.scr' % nn
            elif header['type'] == 'code':
                start = header['p1']
                savebins.append((start, len(payload), 'build/blk%s.bin' % nn))
                patches.append((start, path))
                new = 'build/blk%s.bin' % nn
        if new is None:
            dst = 'data/blk%s.bin' % nn
            shutil.copy(os.path.join(p, path), os.path.join(p, dst))
            new = dst
            todo.append('block %s (%s, %d bytes) is kept as raw data in %s: find where it loads'
                        ' and what it is' % (nn, line.split(path)[0].strip(), len(payload), dst))
        out_manifest.append(line.replace(path, new))
        header = None
    open(os.path.join(p, 'tape/tape.txt'), 'w').write('\n'.join(out_manifest) + '\n')

    if not savebins:
        sys.exit('no headed CODE blocks found: custom loader. Follow the zx-init skill (non-standard tapes) by hand.')
    lo = min(s for s, n, f in savebins)
    hi = max(s + n for s, n, f in savebins)
    cmd = ['snapmod.py']
    for start, path in patches:
        cmd += ['--patch', '%d,%s' % (start, path)]
    run(cmd + ['re/orig.z80', 're/image.z80'], p)

    # 6. coverage
    run([sys.executable, 'tools/zxrun.py', 're/orig.z80', '--frames', str(a.frames),
         '--fuzz', '1:5:' + FUZZ_KEYS, '--map', 're/maps/fuzz.map',
         '--shot', '%d:re/fuzz-end.png' % (a.frames - 1)], p)
    for r in rzx:
        run(['rzxplay.py', '--no-screen', '--quiet', '--map', 're/maps/rzx.map',
             os.path.join('re/rzx', os.path.basename(r))], p)
    maps = [os.path.join('re/maps', m) for m in sorted(os.listdir(os.path.join(p, 're/maps')))]
    merged = set()
    for m in maps:
        merged |= {line.strip() for line in open(os.path.join(p, m)) if line.strip()}
    with open(os.path.join(p, 're/maps/all.map.tmp'), 'w') as f:
        f.write('\n'.join(sorted(merged)) + '\n')

    # 7. disassembly
    pc = int(run(['snapinfo.py', 're/orig.z80'], p).split('PC')[1].split()[0])
    ctl = run(['sna2ctl.py', '-h', '-m', 're/maps/all.map.tmp', '-s', str(lo),
               '-e', '%d' % hi, 're/image.z80'], p)
    os.remove(os.path.join(p, 're/maps/all.map.tmp'))
    open(os.path.join(p, 're/game.ctl'), 'w').write(ctl)
    skool = run(['sna2skool.py', '-H', '-c', 're/game.ctl', 're/image.z80'], p)
    open(os.path.join(p, 'build.skool.tmp'), 'w').write(skool)
    run([sys.executable, 'tools/zxq.py', 'split', 'build.skool.tmp', 're/skool'], p)
    os.remove(os.path.join(p, 'build.skool.tmp'))

    # 8. build glue
    with open(os.path.join(p, 'src/build.asm'), 'w') as f:
        f.write('; Assembles the game and saves each tape block. Generated by zxinit.py;\n'
                '; edit freely (add blocks, INCBINs, extra SAVEBINs).\n'
                '  DEVICE ZXSPECTRUM48\n'
                '  IFNDEF SHIFT\nSHIFT = 0\n  ENDIF\n'
                '  INCLUDE "constants.asm"\n'
                '  INCLUDE "game.asm"\n'
                '  IF SHIFT == 0\n')
        for s, n, path in savebins:
            f.write('  SAVEBIN "%s",$%04X,%d\n' % (path, s, n))
        f.write('  ELSE\n  SAVEBIN "build/shifted.bin",$%04X+SHIFT,%d\n  ENDIF\n' % (lo, hi - lo))
    with open(os.path.join(p, 'src/constants.asm'), 'w') as f:
        f.write('; Numeric constants (sizes, counts, colours, key masks, codes), used in\n'
                '; the skool files through @isub. Add with: tools/zxq.py const NAME VALUE COMMENT\n'
                '; Addresses (ROM, system variables, screen) are @equ lines in re/skool/head.skool.\n')
    with open(os.path.join(p, 're/layout.mk'), 'w') as f:
        f.write('# Written by zxinit.py\nREGION_START := 0x%04X\nREGION_END := 0x%04X\n'
                'ENTRY_PC := 0x%04X\nENTRY_IN_REGION := %d\n' % (lo, hi, pc, lo <= pc < hi))
        f.write('IMAGE_PATCHES := %s\n' % ' '.join('--patch %d,%s' % (st, path) for st, path in patches))
    notes = os.path.join(p, 're/notes.md')
    with open(notes, 'a') as f:
        f.write('\n## Init (zxinit.py)\n\n- original: `%s`\n- code region: $%04X-$%04X\n'
                '- handover PC: $%04X\n' % (orig, lo, hi - 1, pc))
        for t in todo:
            f.write('- TODO: %s\n' % t)
    for t in todo:
        print('TODO: ' + t)
    r = subprocess.run(['make', '-s'], cwd=p, capture_output=True, text=True)
    print(r.stdout + r.stderr)
    if r.returncode:
        sys.exit('initial build is not identical: see above')
    subprocess.run([sys.executable, 'tools/zxq.py', 'status'] + maps, cwd=p)


if __name__ == '__main__':
    main()
