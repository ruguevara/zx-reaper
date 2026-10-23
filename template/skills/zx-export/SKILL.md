---
name: zx-export
description: Freeze an annotated ZX Spectrum skool disassembly into asm modules (src/ becomes the master) and finish the project. Use when annotation and relocation are done.
---

# zx-export

1. Write `re/modules.txt`, one line per module: `START name` in address order
   (`$8000 main`, `$9A00 sprites`, `$C000 music`, ...). Group by memory map,
   not by file size.
2. `make export` writes `src/game.asm` + one file per module and runs `make`;
   it must say `IDENTICAL`. From now on edit `src/*.asm`; `re/skool` is history.
3. Final checks: `make test`, `make shift-test`.
4. Large binary data that a human would edit with a tool (screens, fonts,
   music) may move to `data/*.bin` + `INCBIN`; `make` must stay `IDENTICAL`.
5. Write `README.md`: what the game is, how to build (`make`), required tools
   (sjasmplus, Python 3, SkoolKit), memory map, module list, known
   unexplained parts, how to change common things (lives, speed, graphics).
6. Commit with `git tag identical`.
