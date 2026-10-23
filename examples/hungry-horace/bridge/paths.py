"""Puts the stage 3 port (port/) and the stage 4 game (game/) on the import
path: the bridge is the only code that sees both."""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
for d in ('game', 'port'):
    p = os.path.join(ROOT, d)
    if p not in sys.path:
        sys.path.insert(0, p)
