---
name: zx-annotate
description: Name and describe ZX Spectrum skool entries (routines, data, variables) one file at a time. Use for the bulk annotation loop, including as a subagent given a list of entry files.
---

# zx-annotate

Input: a list of entry files (`re/skool/XXXX.skool`), usually from
`tools/zxq.py next N`. Edit only those files.

For each entry:

1. `tools/zxq.py show $XXXX` — the entry plus its callers and callees with their
   current names and titles. Use those names; do not re-read callees that
   already have titles.
2. If the purpose is not clear from the code, ask the simulator, do not guess:
   - when is it called: `tools/zxrun.py re/orig.z80 --input tests/inputs/play-1.txt --stop $XXXX`
     then `--shot` around that frame;
   - what it writes: `--watch` on its target addresses;
   - what a table holds: `zxq.py gfx` / `peek`.
3. Edit the file:
   - replace the default title (`; Routine at ...`) with one line;
   - description paragraph after `;` line: what it does, in game terms;
   - inputs/outputs as register lines:
     ```
     ; Draw a sprite
     ;
     ; Copies a 2x16 sprite to the screen with XOR.
     ;
     ; HL Sprite address
     ; DE Screen address
     @label=DrawSprite
     c$9100 LD B,$10
     ```
   - `@label=` lines for the entry and for important inner targets (loop heads,
     alternative entry points);
   - instruction comments only for non-obvious intent (`; screen line down`,
     `; self-modified: speed`). Comment text goes after `;` on the instruction line.
   - in comments, refer to other entries as `#R$XXXX` (becomes a link/label).
4. Never change instruction text or addresses. Never touch other files.

After the batch: `make` must say `IDENTICAL` (a typo in a directive breaks
it). Report: each entry's label and title, and any facts for `re/notes.md`
(variable meanings, data formats) and open questions.

Quality bar: a reader who knows Z80 understands the entry from its title and
description without reading the code. Use `Unknown purpose` plus what you do
know rather than an invented name.
