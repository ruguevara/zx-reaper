"""Shared by the verbs tests: the object and character records of the snapshot image."""
import os

IMAGE = open(os.path.join(os.path.dirname(__file__), '..', '..', 'port', 'image.bin'), 'rb').read()
OBJECT_TABLE = 0xC063


def byte(addr):
    return IMAGE[addr - 0x4000]


def objects():
    """(id, record address) of every entry of the object table, up to the $FF end mark."""
    out, a = [], OBJECT_TABLE
    while byte(a) != 0xFF:
        out.append((byte(a), byte(a + 1) | byte(a + 2) << 8))
        a += 3
    return out
