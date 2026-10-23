---
name: zx-port
description: Check annotations with executable models and port ZX Spectrum routines to C or Python routine by routine, each one tested against the original Z80 code on generated cases. Use when a routine's description needs proof, or when porting the game to another language or platform library.
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
6. Whole-game check: the port's frame output for `tests/inputs/*.txt` against
   `tests/expected/*.hash` when the platform library can produce the same
   screen bytes.
