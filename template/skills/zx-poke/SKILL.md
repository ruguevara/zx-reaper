---
name: zx-poke
description: Find POKEs for a ZX Spectrum game (infinite lives, energy, ammo, time, start level or room, invulnerability, protection bypass) and the cheats its developers left in (typed words, key combinations, debug code), check each in the simulator, and record them in re/pokes.md and re/pokes.pok. Use after coverage and annotation have named the main variables, or when asked for cheats or POKEs.
---

# zx-poke

A POKE is an address and a byte (`POKE 35899,0`, decimal) that changes the
game when written after it has loaded. The work: find the variable or the
code an effect depends on, propose the patch, run it. `tools/zxpoke.py` does
the runs; `tools/zxq.py` reads the code. Nothing is a POKE until `zxpoke.py
check` has run it with an input that reaches the event.

Output:
- `re/pokes.md`: one table row per POKE (what, POKE in decimal, address in
  hex and label, status observed/inferred, how found and checked: the
  commands and what they showed), then the developer cheats, then a
  comparison with published POKEs if one was made afterwards.
- `re/pokes.pok`: the POKEs in the World of Spectrum format (below);
  `make pokes` checks every original byte in it against `re/orig.z80`.
- Each developer cheat and each piece of debug code as a finding
  (`zxq.py finding add observed ...`), so `zx-document` puts it in
  `docs/06-tricks.md`.

Work blind first: do not look up published POKEs for the game until your
list is checked and written down; then compare (end of this skill).

## 1. Inputs for every event

List the events the POKEs are about: losing a life by each cause, energy or
ammo use, collecting, the clock, changing room or level, finishing a level,
game over. Each needs an input script (`tests/inputs/` or a scratch file)
that reaches it, and the frames where it happens, read from screenshots
(`zxrun.py --shots-every 25:/tmp/s`, view a few) or from `--text`. Random
play reaches deaths and room changes; collecting, later levels and endings
usually need a written route, a start-room POKE found earlier (`--poke` and
`check --with`), or an RZX. An event no input reaches gives at best an
`inferred` POKE.

Action games read keys once per pass of their main loop, which can be
several frames: hold each key of a typed word 8 frames and release it 8
(`TYPE` in a script holds 2 frames, enough for a ROM-driven text game, too
fast for many action games).

## 2. Find the variable

`zxpoke.py profile` when you know roughly when things happen but not the
values: every address that changes after `--from`, with its history,
filtered.
- lives: `--changes 1-9 --max 10 --step 1` (a few steps of 1 down);
- a timer or clock: `--step 1` with more changes, or digits shown as text
  (ASCII $30-$39 in the history);
- with deaths seen at frames F1,F2: `--near F1,F2`;
- `--referenced` keeps addresses the code names as operands (variables)
  and drops bytes inside buffers; `--range` narrows memory (leave out the
  screen buffers and the stack).

`zxpoke.py search` when you know the values on screen: `--at F=3 --at
G=2` keeps addresses holding 3 at F and 2 at G, in any of the encodings
games use (the value, value-1 for "lives in reserve", value+1, an ASCII
digit, BCD). Relative steps for values you cannot read: start with
`--at F=any`, then `changed`, `same`, `dec`, `inc`, `less`, `more` at later
frames; `--max 63` for a room number. Rooms: alternate frames inside a room
(`same`) and after a change (`changed`).

What survives is usually a few candidates: the variable, its copy in a
buffer (the current room's record, a working copy of the level), the digits
on screen. `zxpoke.py trace SNAP --input X ADDR...` prints each one's
changes; `zxq.py refs ADDR` shows the code that names it. Patch the master,
not the copy (a value copied from a table at each room entry is set in the
table, or in the code that copies it).

Counting up or down: items are often a count of the ones left, or 256-N
counting up to 0. A value may be kept only in the screen digits (the game
reads its own score from the screen): then the variable is the screen.

## 3. Find the code: `zxpoke.py writers`

`writers SNAP --input X ADDR --from F --frames G` runs the pure Python
simulator from F to G (keep the window short: it is slow) and prints each
instruction that writes ADDR, the instructions executed before it, and the
patches it proposes:
- a decrement (`DEC (HL)`, `DEC (IX+d)`) -> NOP: the infinite POKE;
- `LD (nn),A` -> `LD A,(nn)` (POKE addr,58): the store becomes a load;
- the `DEC A`, `SUB n` before the store -> NOP or operand 0;
- the `LD A,n` before a store at a new game: the starting value (lives,
  level, room, ammo; POKE address of n, N);
- a `JR cc`/`JP cc` before the write that jumps past it -> `JR` (24) or
  `JP` (195): the update is skipped (a clock).
When a writer is reached in several ways (a kill routine called from each
cause of death, a new-game routine reached from the title and from the code
check), it lists the paths, the last `--depth` jumps of each, and how to
block each path (`JR cc` -> offset 0, `JP cc` and `CALL cc` -> NOPs, `RET
cc` -> NOP). The input only shows the paths it took: `zxq.py refs` on the
routine's entry lists every jump to it, one per cause.

The proposals are mechanical. Read the routine (`zxq.py show`) and choose:
- one byte where possible: a compare's operand moved out of range (`CP $0C`
  -> `CP 16`: no fall is high enough), a `JR cc` made `JR`, a `RET` (201)
  as the first byte of a test routine;
- the master switch over the symptom: skip a whole update rather than
  freeze one digit of it (infinite time froze only the units digit when the
  digit's `INC` was removed);
- disarm or remove: blocking a kill path leaves the enemy drawn and
  harmless; skipping its drawing removes it. Say which the POKE does.

## 4. Check: `zxpoke.py check`

`check SNAP --input X --poke A,V [--poke ...] --addr ADDR [--with A,V]
[--shot F:PNG]` runs the input with and without the POKEs (`--with`: in
both, such as a start room next to the hazard) and prints each `--addr`'s
history in both runs, the first frame the screens differ, and whether each
run still changes the screen at the end. A POKE is `observed` when:
- the input reaches the event in the unpatched run (the value changes, the
  death happens) and not in the patched one;
- the patched game still runs: screens still change at the end, a
  screenshot after the event looks right, and a long run (20,000 frames or
  more) does not crash or stall;
- a starting value is checked at the extremes too (0, 1, 9, 255): large
  values overflow displays and loops (one Willy drawn per life).
Anything else is `inferred`, with what is missing.

`zxpoke.py pok re/pokes.pok --apply re/orig.z80 /tmp/cheat.z80` writes a
patched snapshot to play in Fuse.

## 5. Developer cheats and debug code

Developers left cheat words, key combinations, level selects and test code.
Where to look:
- `zxpoke.py keys`: every keyboard read (IN with the keys of the half-rows
  it reads, the ROM's key routines, LAST_K and KSTATE), by entry, marked
  `NEVER RAN` when no coverage map has it. Suspects: reads outside the
  control, pause and menu routines; reads of several rows at once or of
  unusual keys; reads that never ran (code behind a condition no input
  met); keys read while loading or on the title screen.
- a progress counter: a variable compared with a constant whose only
  writers are an increment and a reset (`XOR A`), next to a keyboard read:
  a sequence matcher. The word is in a table it indexes: ASCII or key
  codes (`zxq.py strings`, `peek`), or masks of half-rows
  (`zxpoke.py keytab ADDR COUNT --rows $FB,$DF` prints the keys).
- every compare before the matcher is a condition: a room, a position, a
  screen, a score, a key held. Write them all down.
- a flag that unlocks something (teleport, level select, invulnerability)
  read by code with no writer other than the matcher; `zxq.py refs` on it.
- debug code: entries no input ran and nothing calls (`zxq.py refs`), that
  read keys, print memory, show timing on the border or set a level.
- strings no print routine references: messages of a cheat mode.
Check each by doing it: an input script that meets the conditions (a
start-room POKE helps) and types the word slowly; `trace` the counter and
screenshot the effect. Record the word, the conditions, the effect and the
equivalent POKE (the counter's final value), as a finding.

## The .pok format

```
NInfinite lives
Z  8 35899   0  53
NStart with N lives
Z  8 34785 256   7
Y
```
`N` starts a POKE with its name; each line after it is `M` (more follow)
or `Z` (the last): bank (8 for a 48K game), address, value (256: ask the
user), original value. `Y` ends the file. Addresses are as loaded: a POKE
into code a loader moves or decrypts applies after the loader, which is
`re/orig.z80`.

## Compare (after your list is done)

Published POKEs: the World of Spectrum and Spectrum Computing entries of
the game, the reference disassembly if one exists, magazine POKE pages.
Put them in a table next to yours in `re/pokes.md` (or
`re/comparison.md`): same, different patch with the same effect (run both
with `check`), found only by them (why not here: no input reached it, a
kind of POKE not looked for), found only here. Bug-fix POKEs (data
corrections) are not cheats; list them apart. What a published POKE shows
you missed becomes a rule in this skill.
