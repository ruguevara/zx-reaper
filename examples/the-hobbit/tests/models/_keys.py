"""Helpers for the keys and system tests: the command table from the snapshot."""
import os
from skoolkit.snapshot import Snapshot

COMMAND_TABLE = 0xAB53
RECORDS = 59
_here = os.path.dirname(os.path.abspath(__file__))
_mem = None


def command_table():
    """The 59 eight-byte records of the command table, as in the snapshot."""
    global _mem
    if _mem is None:
        _mem = Snapshot.get(os.path.join(_here, '..', '..', 're', 'orig.z80')).ram(-1)
    base = COMMAND_TABLE - 0x4000
    return [bytes(_mem[base + 8 * k: base + 8 * k + 8]) for k in range(RECORDS)]
