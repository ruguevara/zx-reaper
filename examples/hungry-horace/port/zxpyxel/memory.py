"""Memory as a port sees it, three ways that all wrap like the Z80:

    mem[a]      a byte; a store keeps the low 8 bits
    mem16[a]    the little-endian word at a, a+1 (a+1 wraps at $FFFF)
    v.Score     a named variable with the width the asm declares (DEFB, DEFW,
                a table), from port/variables.py (tools/zxport.py variables)
"""


class Memory(bytearray):
    def __setitem__(self, a, value):
        if type(a) is int:
            value &= 0xFF
        bytearray.__setitem__(self, a, value)


class Words:
    def __init__(self, mem):
        self.mem = mem

    def __getitem__(self, a):
        return self.mem[a] | self.mem[(a + 1) & 0xFFFF] << 8

    def __setitem__(self, a, value):
        self.mem[a] = value
        self.mem[(a + 1) & 0xFFFF] = value >> 8


class Byte:
    """A DEFB variable: `v.Passes`."""

    def __init__(self, addr):
        self.addr = addr

    def __get__(self, obj, cls):
        return obj.mem[self.addr]

    def __set__(self, obj, value):
        obj.mem[self.addr] = value


class Word(Byte):
    """A DEFW variable: `v.Score`."""

    def __get__(self, obj, cls):
        return obj.mem16[self.addr]

    def __set__(self, obj, value):
        obj.mem16[self.addr] = value


class Table:
    """A table of `n` bytes or words: `v.GuardTimers[i]`, `len(...)`. An index
    outside it is an error; code that walks past a table uses mem/mem16."""

    def __init__(self, addr, n, width=1):
        self.addr, self.n, self.width = addr, n, width

    def __get__(self, obj, cls):
        self.cells = obj.mem if self.width == 1 else obj.mem16
        return self

    def __len__(self):
        return self.n

    def __getitem__(self, i):
        return self.cells[self.address(i)]

    def __setitem__(self, i, value):
        self.cells[self.address(i)] = value

    def address(self, i):
        if not 0 <= i < self.n:
            raise IndexError('index %d outside a table of %d' % (i, self.n))
        return self.addr + i * self.width


class Variables:
    """Base of the generated variables class: its fields live in `mem`."""

    def __init__(self, mem):
        self.mem, self.mem16 = mem, Words(mem)
