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
1. `make labels` lists operands that are addresses without a label (skool2asm's
   warnings, then `zxq.py addrs`: operands no label lands on, such as the
   middle of an instruction or of a data line). For each, add `@label=` on the
   target instruction or data, or mark the target instruction as an entry
   point (`*$8D3C` instead of ` $8D3C`: code reclassified after the first
   disassembly lacks these marks), or write the operand as label + offset
   (`@isub=LD A,(RecWork3+1)`). Pointer tables must be `W` (words), not bytes,
   and a word that is a number (a dictionary offset, a word code) gets `@keep`
   so a label cannot replace it. Pointers stored as byte pairs inside records
   (a description pointer at +14 of a record) are found by the shift test,
   not by `make labels`.
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
   - an address stored as two bytes of a record (`DEFB ...,$4C,$B0` for a
     handler or template at $B04C): `@isub=DEFB ...,low Label,high Label`;
     look for the records whose descriptions say "address" or "pointer";
   - a negative address in an addition (`LD DE,$A000` to subtract $6000):
     `@isub=LD DE,-Vocabulary`;
   - the frames match until the first random number: a random routine that
     reads memory (code included) gives a moved build other numbers. Set
     `SHIFT_GIVE` in `re/layout.mk` to the address where A holds the value
     read from memory, before it is compared or scaled: the original's values
     are given to the moved build;
   - a script whose output carries addresses (a saved game on tape) differs
     by design: leave it out with `SHIFT_INPUTS` in `re/layout.mk`, with the
     reason.
   To find the culprit, dump both runs at the frame before the divergence
   (`--dump`) and compare the game memory, allowing for the words that moved
   by SHIFT: the bytes left name the variable or the code that differs.
   - the frames differ but the memory at the end of the frame does not: a
     sprite or table read from code bytes (a bug of the original that reads
     past a table); confirm it, record it as a finding, and leave that run
     out of the shift test with the reason.
   The input scripts reach only part of a game: run the shift test also on
   the coverage runs that warp to each level (a project script, like the
   one that makes the coverage maps).
3. Then `make shift-test SHIFT=0x101` (odd shift): failures now mean real
   alignment needs (`ALIGN 256` before page-aligned tables) — record them.
   When memory is full up to the top (a buffer that ends near $FFFF), use a
   small shift that fits (`SHIFT := 0x10` in `re/layout.mk`) and an odd one,
   or move only part of the code: `SHIFT_START`/`SHIFT_END` in
   `re/layout.mk` and an `@org` on the entries where the moved part starts
   and ends (fixed parts: page-aligned tables, an IM 2 handler at $XYXY,
   code entered at a fixed address, buffers up to $FFFF); unused fill at the
   end of the moved part takes the shift.
4. `make` must stay `IDENTICAL` after every `@isub`.

Done when shift tests pass for 0x100 and an odd value, or the remaining
fixed-address parts are listed in `re/notes.md`.
