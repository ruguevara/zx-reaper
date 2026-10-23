---
name: zx-relocate
description: Make ZX Spectrum disassembly sources relocatable (every address operand symbolic) and prove it with the shift test. Use after annotation, before export.
---

# zx-relocate

Byte identity says nothing about whether the source can be changed. The shift
test does: `make shift-test` assembles the code at `+SHIFT`, clears the original
region, runs every input script and compares screen and sound frame by frame
with the original.

Loop:
1. `make labels` lists operands that are addresses without a label. For each,
   add `@label=` on the target instruction or data (or reclassify, see
   zx-classify). Pointer tables must be `W` (words), not bytes.
2. `make shift-test` (default `SHIFT=0x100`, keeps 256-byte alignment).
   On `DIVERGED at frame N`: view `diverged-N.png`, then find the culprit:
   - `JR ... Target out of range` at assembly: data disassembled as code;
   - absolute address hidden in data (`DEFB lo,hi`), in `LD HL,nn` used as
     a pointer, or in split bytes (`LD H,$90` + `LD L,A` table lookups): use
     `@isub=LD H,Table/256` style substitutions, or `@isub=LD HL,Table+5`;
   - self-modifying code writes into an operand: label the instruction
     (`@label=SmcSpeed`) and write the store as `@isub=LD (SmcSpeed+1),A`;
   - code copied to a fixed address at run time: keep it at that address with
     `DISP`/`ENT` or leave that range out of the shift (note in `re/notes.md`).
3. Then `make shift-test SHIFT=0x101` (odd shift): failures now mean real
   alignment needs (`ALIGN 256` before page-aligned tables) — record them.
4. `make` must stay `IDENTICAL` after every `@isub`.

Done when shift tests pass for 0x100 and an odd value, or the remaining
fixed-address parts are listed in `re/notes.md`.
