"""Shared by the engine NPC tests: the NpcStates records and script commands of the snapshot image."""
import os

from labels import NpcStates, NPC_RECORD_SIZE

IMAGE = open(os.path.join(os.path.dirname(__file__), '..', '..', 'port', 'image.bin'), 'rb').read()


def byte(addr):
    return IMAGE[addr - 0x4000]


def records():
    """Addresses of the NpcStates records up to the $FF end mark (included)."""
    out, a = [], NpcStates
    while True:
        out.append(a)
        if byte(a) == 0xFF:
            return out
        a += NPC_RECORD_SIZE
