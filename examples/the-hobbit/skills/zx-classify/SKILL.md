---
name: zx-classify
description: Separate code, data, text, graphics and variables in a ZX Spectrum disassembly and build the memory map. Use after coverage, before annotating, and whenever a skool entry looks like garbage code.
---

# zx-classify

Classification never changes bytes, so `make` stays green; it changes what
the agent and the reader see.

## Evidence, cheapest first

1. Execution map: `tools/zxq.py unexec re/maps/*.map` lists code never run.
   Garbage instructions (`LD D,E` runs, odd `JR` targets) after a `RET`/`JP`/`HALT`
   are data.
2. Text: `tools/zxq.py strings 4 START END`.
3. Graphics: `tools/zxq.py gfx ADDR LEN WIDTH /tmp/g.png` for linear sprites
   (try WIDTH 1, 2, 3, 4), `... 8 /tmp/g.png cells` for fonts and tiles; view the PNG.
   Shapes are obvious at a glance; noise means not graphics or wrong width.
4. Readers: `tools/zxq.py refs ADDR` — the code that reads a table tells its
   format (byte or word, stride, terminator).
5. Writers: `tools/zxrun.py re/orig.z80 --frames N --watch A-B --watch-from N-5`.
   Bytes written at run time are variables (`g` entries).

## Applying it

Write a control-file fragment covering whole existing entries, ending with
`i $END`, and run `tools/zxq.py reclassify frag.ctl`, then `make`. Example:

```
c $812E Game over
t $8144 Title text
T $8144,12,11:B1
w $8073 Direction handlers
W $8073,8
g $8159 Player X
b $815E Stack area
S $815E,64,64:$55
b $9000 Sprite: player, 2x16
B $9000,32,2
@ $9000 label=PlayerSprite
i $81A1
```

Text after an address in a control file becomes a comment, so keep notes
out of fragments. Above: `T $8144,12,11:B1` is 11 characters then one byte
(bit-7 terminated text); `W` makes words, which skool2asm turns into labels;
`S ...:$55` is `DEFS 64,$55`; `B $9000,32,2` writes 2 bytes per line.

Types: `c` code, `b` data, `t` text, `w` words, `g` variables, `s` fill, `u` unused,
`i` ignore. Use `w`/`W` for every table of addresses (jump tables, pointer lists).

## Memory map

Keep the table in `re/notes.md` (`Range | What | Status`) up to date. Mark
regions as `code`, `data:<format>`, `vars`, `stack`, `buffer`, `unused`.
Done when no entry is a data block disassembled as code and every region of
the image has a row.
