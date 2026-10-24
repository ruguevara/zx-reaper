---
name: zx-annotate
description: Name and describe ZX Spectrum skool entries (routines, data, variables), replace magic numbers with named constants and label self-modifying code, one file at a time. Use for the bulk annotation loop, including as a subagent given a list of entry files.
---

# zx-annotate

Input: a list of entry files (`re/skool/XXXX.skool`), usually from
`tools/zxq.py next N`. Edit only those files. Other agents edit other files
at the same time, so never edit `head.skool`, never run `make` (it shares
`build/`); verify with `tools/zxq.py check` instead. Never delete, move,
restore or regenerate `re/skool/` or any file you were not given (no
`rm -rf`, no `zxq.py split`/`reclassify`): edit your files in place.

## Per entry

1. `tools/zxq.py show $XXXX` — the entry plus callers and callees with their
   current names and titles. Use those names; do not re-read callees that
   already have titles. `re/notes.md` has the memory map.
2. If the purpose is not clear from the code, ask the simulator instead of
   guessing: `tools/zxrun.py re/orig.z80 --input tests/inputs/demo.txt --stop $XXXX`
   (when is it reached), `--shot F:/tmp/x.png` (what is on screen), `--watch A-B`
   (who writes), `tools/zxq.py gfx` / `peek` (what a table holds).
3. Edit the file (format below). Keep every instruction's address and bytes.
4. `tools/zxq.py check` must print `IDENTICAL`.

## Format

```
; Draw a sprite
;
; Copies a 16x16 sprite (32 bytes, cells TL TR BL BR) to the screen.
; .
; Hardware: writes the screen bitmap.
;
; HL Sprite graphic address
; DE Screen address of the top-left cell
; O:HL Address after the sprite
@label=DrawSprite
c$9100 LD B,$10        ; 16 pixel rows
@isub=LD A,KB_Q_T
 $9102 LD A,$FB        ; read Q-T
```

- Entry header layout is fixed: title, `;`, description, `;`, register lines.
  A bare `;` line ends the description, so separate description paragraphs
  with `; .` (otherwise skool2asm reads the next paragraph as registers and
  fails). An `@isub` applies to the instruction on the next line only; put it
  directly above that instruction.
- Title: one line, what it is. Description: what it does in game terms, then
  a `Hardware:` sentence when it touches the screen, attributes, ports, ROM,
  interrupts or timing loops (this is what a port to C/Python must replace).
  Register lines: inputs `A Meaning`, outputs `O:HL Meaning`. They describe
  what the routine's own instructions see, because a port's signature is
  built from them: inputs are the registers and flags read before they are
  written; outputs are what some caller uses after the call (check every
  CALL). Flags count: `F Carry clear on entry`, `O:F Z set when nothing
  found`. Write `E`, not `E'`, when the routine reads E, and say in the
  description when the caller does EXX around the call. A value a caller
  takes from a register this routine leaves behind gets an `O:` line too
  (`O:C $3A while the bell is in the maze (TickGuardTimers relies on it)`).
- Labels: routines `VerbNoun` (`DrawSprite`), data/variables `NounPhrase`
  (`GuardX`), unique, at most 24 characters. `@label=` goes on the line before
  the instruction. Label loop heads and alternative entry points that other code
  jumps to (`DrawSprite_Loop`), not every branch.
- Data entries: the title names the format; in the description list the
  fields (`+0 word: screen address`, `+2 byte: direction 0-3`...). Put
  `@label=` on fields other code reads directly (struct fields). Name a
  field from what the game says when its test fails: the message printed
  after the comparison ("too heavy to lift" makes it the weight, "too full"
  the size). A name taken from how the field is summed or where it sits
  can be the wrong way round, and no check catches a name.
- A title that says what sets a routine off (a word, a key, an event)
  needs a run that reaches it and one that does not: compare the two code
  maps. A guess from a table's layout named the quote mark's handler "the
  end of the typed words".
- Every target of a handler table (verb handlers, object and character
  handlers, timers, script routines) is an entry of its own with a title,
  even when the handlers sit back to back: an entry titled "Command
  handlers" holding twenty is twenty routines nobody described.
- Comments: only where the intent is not obvious; refer to entries as `#R$XXXX`.
- `Unknown` is allowed; a wrong name costs more than a missing one.

## Magic numbers

- **Addresses outside the code** (ROM routines, system variables, screen
  positions): `@equ=NAME=$XXXX` lines at the top of your own entry file
  (the lead moves them to `head.skool`). skool2asm then replaces every 16-bit
  operand with that value, so run `tools/zxq.py equs --uses` and put `@keep`
  on the line before any instruction where the value is a count, not that address.
  Existing names: `tools/zxq.py equs`.
- **Numbers** (sizes, counts, colours, key masks, tile codes, directions,
  offsets): `tools/zxq.py const NAME VALUE COMMENT` (prints a note if the
  value already has a name; reuse it if the meaning is the same), then
  `@isub=` with the instruction rewritten using the name. Expressions are fine:
  `@isub=LD (HL),CYAN*PAPER+BLACK`, `@isub=LD BC,ATTRS_SIZE-1`,
  `@isub=LD DE,ATTRS+1`. Existing names: `tools/zxq.py const`.
- **Addresses inside the code**: nothing to do; operands become labels when
  the target has a `@label`. For an address in the middle of a data entry
  write `@isub=LD HL,MazeRecord1+7`.
- **Self-modifying code**: label the modified instruction
  (`@label=SmcGuardSpeed`), say in a comment what modifies it, and write the
  stores as `@isub=LD (SmcGuardSpeed+1),A`.
- Leave a number alone when it is just a number (`ADD A,2` that moves two
  pixels can stay, or become `STEP` if it recurs).

## Findings and open questions

- A claim that other work depends on (a variable's meaning, a data format, a
  rule of the game, a bug) goes into the register with its status:
  `tools/zxq.py finding add inferred "GuardWait counts down 90 passes after a guard is eaten" "code: $663D decrements, $66A4 sets 90" "$6DBE"`.
  `observed` needs a run: simulator watch or screenshot (`zxrun.py`), a byte
  check, or a passing model (`zx-port` skill). Reading the code is `inferred`.
  Something you could not settle is `unknown`; a claim shown wrong is set to
  `refuted`, never deleted. The command is safe for parallel agents.
- Claims from coverage are bounded: write "not executed with the inputs in
  re/maps", not "dead code", unless the code itself makes it unreachable (an
  unconditional jump over it, a condition that cannot hold); say which.
- For a precise claim that is easy to get wrong (address arithmetic, scoring
  rules, AI weights), a model in `tests/models/` checks it on generated cases
  (`zx-port` skill).

## Report back

For each entry: label and title. Proposed splits: address, title, reason
(the lead applies them with `tools/zxq.py cut ADDR TITLE`). Then the finding IDs you added or changed,
facts about other entries (with evidence), and open questions.
