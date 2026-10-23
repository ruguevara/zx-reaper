---
name: zx-port
description: Check annotations with executable models and port ZX Spectrum routines to C or Python routine by routine, each one tested against the original Z80 code on generated cases; stage 3, the whole game in Python on zxpyxel checked by replaying Z80 runs. Use when a routine's description needs proof, or when porting the game to another language or platform library.
---

# zx-port

The original Z80 code is the oracle. `tools/zxdiff.py` runs a routine in the
simulator on many generated inputs and compares its registers and memory with
a Python function. That function is either a **model** (checks that the
annotation is right) or the **port** itself.

## A model or port file

`tests/models/<routine>.py` (format in `tools/zxdiff.py -h`):

```python
"""StepCell moves a screen offset one cell in direction A; left never changes the third."""
ROUTINE = 'StepCell'                 # label from build/game.sym
OUTPUTS = {'regs': ['HL'], 'mem': [('Score', 2)]}
KINDS = ['typical', 'boundary', 'high-bits']

def cases(rnd):                      # yield (kind, {'A': .., 'HL': .., 'mem': {..}})
    ...
def model(regs, mem):                # return {'HL': .., 'mem': {addr: byte}}
    ...
```

- The docstring states the claim being tested, in one sentence.
- Case kinds: always `typical` (random valid inputs) and `boundary` (edges:
  first/last row or column, screen-third boundaries, counter 0/1/max, values
  that wrap); add kinds for the routine's special inputs (blocked direction,
  empty list, overflow). Boundary cases find most mismatches.
- Inputs in memory (variables, tables, screen attributes) go into the case's
  `mem`; outputs to compare go into `OUTPUTS['mem']`.
- Use `sym('Label')` and `const('NAME')`, never raw addresses.
- Run `make` first (it writes `build/game.sym`), then `make diff` or
  `tools/zxdiff.py tests/models/<file>.py`.

## Annotation check

Write models for routines whose description makes a precise claim that is
easy to get wrong: address arithmetic, collision rules, AI scoring, score
printing, random numbers, timers. A pass turns the claim into an `observed`
finding (`tools/zxq.py finding set ID observed "zxdiff: N cases, kinds ..."`);
a mismatch is either an annotation error (fix the description) or a quirk of
the original (document it as such, keep the model faithful to the Z80).

## Porting

1. Order: leaf routines first (`tools/zxq.py next` style), then callers.
2. For each routine, write the port function with the same inputs and outputs
   as its register/memory interface, test it with `zxdiff.py`, then refactor
   the interface (registers to arguments, memory to struct fields) only after
   it passes.
3. For a C (or other non-Python) port, dump golden cases from the Z80 code and
   test the port against them in its own test runner:
   `tools/zxdiff.py tests/models/<file>.py --dump tests/golden/<routine>.jsonl`.
   Each line holds the case kind, input registers and memory, and the Z80's
   output registers and memory.
4. Hardware access (`Hardware:` sentences in the sources, `docs/08-porting.md`)
   goes through the platform library; model it in the case memory (screen,
   attributes) rather than calling real hardware.
5. `tests/models/STATUS.md` (written by `make diff`) is the progress table:
   routine, cases per kind, pass/fail. A pass covers only the generated cases:
   cite the kinds when you report it.
6. Whole-game check of a Python port: stage 3 below.

## Stage 3: the game in Python on zxpyxel

The port runs the same game in Python: same memory layout, same screens,
same behaviour under the same input, one function per routine. It runs on
`port/zxpyxel/` (a stand-in for the 48K machine, design in zx-reaper's
`docs/port.md`). Setup, once: `make port/labels.py port/variables.py
port/image.bin` (again after a change to `src/`); set
`PORT_ENTRY` (`main.Start`) and `PORT_CHECKPOINT` (the main loop's label) in
`re/layout.mk`, and `PORT_STATE` if the game keeps state outside the screen
and its code region (a system variable it reads, such as FRAMES:
`PORT_STATE := --state 0x4000-0x5B00 --state 0x5C78-0x5C7B --state ...`).
`python port/play.py` plays it; `make port-test` is the check.

### Code

- `port/<module>.py` per `src/<module>.asm`; `from labels import *` first,
  then imports from the other port modules, `from variables import v` and
  `from zxpyxel import mem, mem16, zx`.
- One function per routine, named as the label. Registers become arguments
  and return values (in the order of the `R`/`O` lines of the header), a
  flag the caller branches on becomes a returned bool. Return only the
  outputs some caller uses (check the callers), and say what is returned in
  the docstring.
- Flags: a carry chain (`RLA`, `ADC`, `SBC` in a row) is one integer of 9
  or 17 bits, with a comment naming the instructions. A flag that leaks from
  one call into the next becomes an explicit argument, and the comment says
  so. `CP n` + `JR C` is unsigned `a < n`; `JP M` is signed
  (`x - 256 if x > 127`).
- Width: mask a register where the asm can overflow it, at the assignment,
  not at the use (`c = c + bonus & 0xFF`). Traps: `DEC` of 0 is $FF,
  `DJNZ` with B = 0 runs 256 times, `ADD HL` drops the carry out of 16 bits.
- Memory, three ways onto the same 64K, all wrapping like the Z80:
  `v.Name` for a data label with the width the asm declares (`v.Passes -= 1`
  a DEFB, `v.Score = 0` a DEFW, `v.GuardTimers[i]` a table; generated
  `port/variables.py`); `mem[a]` (byte) and `mem16[a]` (word) for a computed
  address: the screen, a pointer, a walk past a table's end; `mem[Label + 1]`
  for a self-modified operand. Data stays in memory: never copy a table into
  Python. Register arithmetic is plain ints: mask it (`& 0xFF`) where the
  register would wrap.
- Write exactly the bytes the asm writes, including scratch variables and
  values that look dead: the check compares all of the code region. Stage 3
  does not tidy up: mark each write that is there only for the check (a dead
  store, a no-effect write, a scratch table) with a `# check:` comment, so
  stage 4 can find it and delete it.
- Fall-through into the next label: call it as the last statement. A jump
  that drops return addresses (`POP HL` + `JP Label`): `raise Goto(Label)`
  (from zxpyxel); the entry routine runs `await dispatch(...)`, which goes on
  at the target. Keep the asm's quirks (a wrong mask, an off-by-one): they
  are the behaviour; a comment names them. A second entry point inside a
  routine (`EraseGuard_Always`) is its own function, which the outer one
  calls after its own checks. A routine that never returns says so in its
  docstring and ends in a Goto or in a call to a routine that raises one.
  Stack quirks (a leak, a dropped word) have no Python equivalent: a comment
  names the finding, nothing more.
- An inline loop the asm repeats in several places becomes one lower-case
  helper (`print_text`), not a routine.
- Hardware only through `zx`: `zx.inp(port)` with the full 16-bit port
  address the asm uses (`A << 8 | $FE` for `IN A,($FE)`), `zx.out(port, v)`,
  `zx.tone(...)` for a beeper loop, `zxpyxel.rom` for ROM calls, `zx.di()`,
  `zx.ei()`.
- Time: no CPU is emulated, so the port charges it. Delay and sound loops
  exactly (`zx.spend(passes * 26)`, `djnz_t(b)`, `zx.tone`); other routines
  with `zx.spend(T)`, T from the `T-states` that `zxdiff.py` prints for the
  routine (a typical value; charge per call, per loop pass where the cost
  depends on a count). `make port-test` prints the drift of the port's clock
  against the Z80's; keep it within a few per cent.
- A routine that waits or plays a sound longer than a frame is `async def`,
  ends with (or contains, per wait) `await zx.sync()`, and its callers
  `await` it. The main loop awaits `zx.sync()` once per pass; HALT is
  `await zx.halt()`.
- Charging: the T-states zxdiff prints include the callees (not the final
  RET). A routine charges its own part: its T minus what its callees charge;
  each CALL and RET it makes is 27 more. `zxdiff.py --tstates` prints the
  mean per case kind, the Z80 next to what the port charged: with case kinds
  that follow the branches, the difference per kind is what each branch
  still has to charge. An async routine: measure the Z80 side with a
  cases-only file in `tests/models/` (no `model`, no `port`: zxdiff prints
  the T-states); one that never returns: charge its loops exactly and let
  the drift of `make port-test` judge the rest. Do not hand-count
  straight-line code.

### Checks

1. Per routine, while porting: add `port(regs)` to the routine's file in
   `tests/models/` (or write one: same `ROUTINE`, `OUTPUTS`, `KINDS`,
   `cases` as a model). zxdiff loads the case into `zx.mem`, calls `port`,
   and compares registers and memory with the Z80:

   ```python
   import library
   def port(regs):
       return {'HL': library.StepCell(regs['A'], regs['HL'])}
   ```

   A routine that only writes memory returns `{}`; its memory is compared
   through `OUTPUTS['mem']`. A word in a case's `mem` is `[lo, hi]`.

   Read the inputs from the routine's instructions, not only its header (a
   header's `E'`/`HL'` can describe the state after the caller's EXX), and
   put every register and flag the instructions read into the case, even
   one the port does not take (A = "0", `F` with carry clear). Keep cases
   inside the inputs the game passes. A mismatch shows only the registers
   and bytes that differ. Helpers shared by several test files go into
   `tests/models/_name.py` and take their names from `labels` (port/ is on
   the path).
   Async routines and routines whose cost is the whole game state are left
   to the whole-game check.
2. Whole game, the stage's gate: `make port-test`. It records each
   `tests/inputs/*.txt` on the Z80 (`build/record/*.rec`: every value an IN
   of the game reads, and the state at every pass through PORT_CHECKPOINT)
   and runs the port from `PORT_ENTRY` with those values replayed; the port
   calls `zx.checkpoint('MainLoop')` at the top of its main loop. Input is
   matched by read order, so the port's frames need not match the Z80's.
   The first difference stops it: a read on another port or at another time
   (control flow differs before that point), or the bytes that differ at a
   checkpoint, named by label or screen cell, with the Z80 frame. Look at
   that frame (`tools/zxrun.py re/orig.z80 --input ... --shot F:z80.png`),
   find the routine that writes the bytes (`--watch`), fix, repeat. A
   difference in a variable an interrupt handler writes (FRAMES) means the
   Z80 took an interrupt the port's clock did not: the record holds the
   ROM's interrupts, so check that `PORT_STATE` covers the variable and that
   the port changes it only in `zx.handler`.

   A pass proves only what the inputs reach. `make port-test` lists the port
   routines no record ran; add an input that reaches them: search seeds with
   `tools/zxrun.py re/orig.z80 --fuzz SEED:HOLD:KEYS --frames N --map
   /tmp/f.map` for the routine's address, save the one that reaches it with
   `--save-input tests/inputs/NAME.txt`, then `make expected`.
3. By eye: `python port/play.py` next to the original in an emulator; speed
   and sound are judged there. `make port-html` builds the web page.

### Orchestration

The lead writes the control flow (the entry routine and the main loop, in
`port/main.py`) and a contract before any subagent starts: for each module,
the routines other modules call with their signatures, which are `async`,
the Goto targets and where they live, the cross-module calls. Leaf modules
(drawing, printing, probes, records) go first, so their signatures are
fixed; the rest then go in parallel, one subagent per module, against the
contract. Each subagent gets this skill, the contract, the files it may
edit, and the rule to run zxdiff on explicit files only (`make diff`
rewrites STATUS.md). The lead integrates and runs `make port-test`.
