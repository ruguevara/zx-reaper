"""Indirect calls: JP (HL), JP (IX), JP (IY) and the handler tables (verbs,
arrivals, timers, NPC script routines, message control codes, parser word
classes, special words) jump to an address; the port routine at that address
is the function named as the label there, in whichever module defines it."""
import importlib
import inspect

import labels

MODULES = ['main', 'keys', 'printer', 'parser', 'drawing', 'system', 'screen', 'devices',
           'verbs', 'engine', 'objects', 'handlers', 'world']
_at = None


def routine_at(addr):
    """The port function whose label is `addr`."""
    global _at
    if _at is None:
        _at = {}
        for m in MODULES:
            mod = importlib.import_module(m)
            for name, fn in vars(mod).items():
                if inspect.isfunction(fn) and fn.__module__ == m and isinstance(getattr(labels, name, None), int):
                    _at[getattr(labels, name)] = fn
    try:
        return _at[addr]
    except KeyError:
        raise KeyError('no port routine at $%04X' % addr) from None


async def call_at(addr):
    """Call the routine at `addr`, awaiting it if it is async."""
    res = routine_at(addr)()
    if inspect.iscoroutine(res):
        await res
