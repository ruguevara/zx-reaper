"""Ported from src/world.asm: the small routines among the world data ($C7A4-$C7FB).
Values pass in the registers `r` (port/regs.py); conventions: port/CONTRACT.md.
They are the arrival handlers of ArrivalHandlers, reached through
`calls.call_at` after a move to the location named in the table."""
from labels import *  # noqa: F403  (first: port functions shadow routine labels)
import calls  # noqa: F401
import printer
import verbs
from regs import r
from variables import v
from zxpyxel import Goto, mem, mem16, zx  # noqa: F401


def _bit(n, value):
    """BIT n,value: Z set when the bit is clear (carry untouched)."""
    r.zf = not value >> n & 1
    r.pf = r.zf
    r.sf = n == 7 and bool(value & 0x80)


def ArriveBeornsHouse():
    """Beorn's house ($16): unless the butler is dead (flag bit 3), wake him
    (NpcButler := $42) and set his flag bit 7. O: HL = Chr42ButlerFlags, A $42,
    Z from the BIT."""
    r.hl = Chr42ButlerFlags
    _bit(3, mem[r.hl])
    if not r.zf:
        return
    r.a = 0x42
    mem[NpcButler] = r.a
    mem[r.hl] |= 0x80


def ArriveSpiderPlace():
    """Mirkwood spider place ($1A): start timer 2 (Timer2Counter := Timer2Start)."""
    r.a = v.Timer2Start
    mem[Timer2Counter] = r.a


def ArriveBog():
    """Deep bog ($1D): start timer 4."""
    r.a = v.Timer4Start
    mem[Timer4Counter] = r.a


def ArriveCellar():
    """Elvenking's cellar ($20): timer 9 starts at 3; the dragon slot (NpcDragon
    := $3C) wakes unless the dragon is dead (flag bit 3), and the Bard's
    (NpcBard := $46) unless he is. O: HL = Chr46BardFlags."""
    r.a = 3
    mem[Timer9Counter] = r.a
    r.hl = Chr3CDragonFlags
    _bit(3, mem[r.hl])
    if r.zf:
        r.a = 0x3C
        mem[NpcDragon] = r.a
    r.hl = Chr46BardFlags
    _bit(3, mem[r.hl])
    if not r.zf:
        return
    r.a = 0x46
    mem[NpcBard] = r.a


def ArriveForest():
    """Forest road and forest ($02, $03): remember where the player came from
    (ArrivalLocation := TakeId) and start timer 8."""
    r.a = v.TakeId
    v.ArrivalLocation = r.a
    r.a = v.Timer8Start
    mem[Timer8Counter] = r.a


async def ArriveForestRiver():
    """Forest river ($21): unless the player is in the barrel ($13) he is swept
    away: the arrival (ActorArrives_0) is shown, then the game ends."""
    r.a = mem[Chr00PlayerHolder]
    r.cp(0x13)
    if r.zf:
        return
    await verbs.ActorArrives_0()
    r.hl = MsgSweptForcefully
    await printer.PrintMessage()
    return await verbs.EndGame()
