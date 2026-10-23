---
name: zx-coverage
description: Grow the code execution map of a ZX Spectrum game (input scripts, random play, RZX recordings) so code/data separation is reliable. Use after init and whenever `zxq.py unexec` shows large unexplained regions.
---

# zx-coverage

Coverage tells code from data without reading it. Aim for every reachable
routine executed at least once; 100% instruction coverage is not needed.

1. Status: `make status` (code coverage line) and `tools/zxq.py unexec re/maps/*.map | head -40`.
2. Write input scripts in `tests/inputs/NAME.txt` (format: `tools/zxrun.py -h`).
   Find controls from screenshots: run with `--shots-every 50:/tmp/s`, view a few
   PNGs, not all. Typical scripts: `menu` (each menu option), `play-1` (start,
   move, fire, die), `die-all` (lose every life, game over, high score entry),
   `pause`, `redefine-keys`.
   End each with `N END`. Check a script does what you think by viewing
   `--shot` frames at its key moments.
3. `make coverage` adds maps from all scripts and RZX files.
4. Random play reaches odd paths cheaply:
   `tools/zxrun.py re/orig.z80 --frames 20000 --fuzz 2:3:O,P,Q,A,M,SPACE --map re/maps/fuzz2.map`
   (use the game's real keys; try several seeds).
5. Later levels and endings need real play. Ask the human for an RZX
   (Fuse: Recording → Record, play 10 minutes) or take one from the RZX Archive;
   put it in `re/rzx/` and run `make coverage`.
6. Make the important scripts regression tests: `make expected` records their
   frame hashes from the original; `make test` replays them on the build.

Stop when two new scripts in a row add under 1% coverage; note what is
still unexecuted and why in `re/notes.md`.
