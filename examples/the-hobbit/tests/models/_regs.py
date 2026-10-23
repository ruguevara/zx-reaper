"""Run a port routine with the register interface (port/regs.py) on a zxdiff
case: the case's registers into `r`, the routine, the outputs out of `r`.
Flags as zxdiff's ZF, CF, SF, PF (F sets all four)."""
import inspect

from regs import r

FLAGS = {'ZF': 'zf', 'CF': 'cf', 'SF': 'sf', 'PF': 'pf'}
F_BITS = {'zf': 6, 'cf': 0, 'sf': 7, 'pf': 2}


def run(fn, regs, outputs):
    """Call `fn` (a plain routine) with `regs` loaded into r; return `outputs`."""
    assert not inspect.iscoroutinefunction(fn), 'async routines go to the whole-game check'
    r.reset()
    for k, val in regs.items():
        if k == 'F':
            for f, bit in F_BITS.items():
                setattr(r, f, bool(val >> bit & 1))
        elif k in FLAGS:
            setattr(r, FLAGS[k], bool(val))
        else:
            setattr(r, k.lower(), val)
    fn()
    return {k: int(getattr(r, FLAGS[k])) if k in FLAGS else getattr(r, k.lower()) for k in outputs}
