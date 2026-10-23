#!/usr/bin/env python3
"""Check that the tools are installed and, inside a project, what is missing.

  zxdoctor.py            run from the zx-reaper root or a project root
Exit status 1 when something required is missing; every problem comes with
the command that fixes it.
"""
import glob
import os
import re
import shutil
import subprocess
import sys

problems = 0


def report(ok, what, fix='', required=True):
    global problems
    mark = 'ok  ' if ok else ('MISS' if required else 'opt ')
    print('%s %s%s' % (mark, what, '' if ok or not fix else '  ->  ' + fix))
    if not ok and required:
        problems += 1


def version(cmd, pattern):
    try:
        out = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
    except (OSError, subprocess.TimeoutExpired):
        return None
    m = re.search(pattern, out.stdout + out.stderr)
    return m.group(1) if m else '?'


def tools():
    report(sys.version_info >= (3, 9), 'Python %d.%d (3.9 or later)' % sys.version_info[:2],
           'install Python 3.9+')
    try:
        import skoolkit
        v = skoolkit.VERSION
        major = int(v.split('.')[0])
        report(major >= 9, 'SkoolKit %s (9.0 or later; tested with 10.1)' % v,
               'pip install -r <zx-reaper>/requirements.txt')
        report(skoolkit.CSimulator is not None, 'SkoolKit C simulator (fast runs)',
               'reinstall skoolkit from a wheel or with a C compiler', required=False)
    except ImportError:
        report(False, 'SkoolKit', 'pip install -r <zx-reaper>/requirements.txt')
    v = version(['sjasmplus', '--version'], r'v(\d+\.\d+\.\d+)')
    report(v is not None, 'sjasmplus %s' % (v or ''),
           'build from https://github.com/z00m128/sjasmplus (git submodule update --init; make)')
    report(shutil.which('make') is not None, 'make', 'install make')
    for tool in ('tap2sna.py', 'sna2skool.py', 'skool2asm.py', 'snapmod.py', 'rzxplay.py'):
        report(shutil.which(tool) is not None, tool, 'activate the venv with SkoolKit (zx-reaper README, Setup)')
    report(shutil.which('fuse') or shutil.which('fuse-sdl') or shutil.which('fuse-gtk'),
           'Fuse emulator (playing, RZX recording)', 'install Fuse: https://fuse-emulator.sourceforge.net', required=False)


def project():
    print('\nproject %s' % os.getcwd())
    tapes = glob.glob('original/*.tap') + glob.glob('original/*.tzx')
    report(bool(tapes), 'original tape in original/', 'copy the tape to original/game.tzx (or .tap)')
    report(os.path.exists('re/orig.z80') and os.path.exists('re/image.z80'),
           're/orig.z80, re/image.z80', 'make restore')
    report(os.path.isdir('re/tape'), 're/tape/ (tape blocks)', 'make restore')
    report(os.path.exists('build/game.sym'), 'build/game.sym (symbols for zxdiff)', 'make')
    for inp in glob.glob('tests/inputs/*.txt'):
        exp = 'tests/expected/%s.hash' % os.path.splitext(os.path.basename(inp))[0]
        report(os.path.exists(exp), 'expected hashes for %s' % inp, 'make expected')
    for reg in ('re/questions.md', 're/findings.md'):
        report(os.path.exists(reg), reg, 'copy it from zx-reaper template/re/', required=False)


def main():
    tools()
    if os.path.exists('Makefile') and os.path.exists('re/layout.mk'):
        project()
    print('\n%s' % ('ready' if not problems else '%d required item(s) missing' % problems))
    sys.exit(1 if problems else 0)


if __name__ == '__main__':
    main()
