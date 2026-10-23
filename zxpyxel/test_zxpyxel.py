"""Checks of the core: python -m zxpyxel.test_zxpyxel (or pytest)."""
from zxpyxel import T_FRAME, Goto, dispatch, headless, keys, mem, mem16, screen, sound, zx
from zxpyxel.display import Display, attr
from zxpyxel.memory import Byte, Table, Variables, Word
from zxpyxel.machine import FRAMES


def test_keys():
    assert keys.read(set(), 0x00) == 0xBF                    # nothing held, EAR bit 0
    assert keys.read({'Q'}, 0xFB) == 0xBE                    # Q-T half-row, Q is bit 0
    assert keys.read({'Q'}, 0x00) == 0xBE                    # all half-rows at once
    assert keys.read({'Q'}, 0xFE) == 0xBF                    # another half-row
    assert keys.kempston({'KL', 'KF'}) == 18


def test_pcm():
    data, level = sound.pcm([(0, 1), (35000, 0)], 0, 0, 70000, 1000)   # 3500 T a sample
    assert data == sound.ON * 10 + sound.OFF * 10 and level == 0


def test_frames_and_interrupts():
    zx.reset()

    async def main():
        zx.ei()
        await zx.halt()
        zx.spend(2 * T_FRAME)
        await zx.sync()

    assert headless.run(main) == 3
    assert zx.mem[FRAMES] == 3                                # IM1 ran after each frame


def test_memory():
    zx.reset()

    class Data(Variables):
        Count = Byte(0x8000)
        Score = Word(0x8001)
        Timers = Table(0x8003, 2, 2)

    v = Data(mem)
    v.Count -= 1                        # wraps like the Z80
    v.Score = 0x12345
    v.Timers[1] = 0xBEEF
    assert v.Count == 0xFF and mem[0x8001:0x8003] == b'\x45\x23' and mem16[0x8005] == 0xBEEF
    mem16[0xFFFF] = 0x0102              # the high byte wraps to $0000 (the ROM)
    assert mem[0xFFFF] == 2 and mem[0] == 1
    mem[0] = 0xF3
    try:
        v.Timers[2]
        assert False, 'index outside the table'
    except IndexError:
        pass


def test_display():
    d = Display()
    d.cls(attr(0, 7))
    d.text(1, 9, 'A', attr(2, 7, bright=True))
    zx.reset()
    for line in range(8):                   # the same bytes as a Spectrum's screen
        zx.mem[0x4000 + 0x0800 + line * 256 + 0x20 + 1] = d.glyph(1, 9)[line]
    zx.mem[0x5800:0x5B00] = d.data[6144:]
    assert d.data[:6144] == zx.mem[0x4000:0x5800] and d.glyph(1, 9) == zx.mem[0x3E08:0x3E10]   # A is character 65
    assert screen.render(d.data, base=0) == screen.render(zx.mem) and d.attr(1, 9) == 0x7A


def test_png(tmp='/tmp/zxpyxel-test.png'):
    from zxpyxel import png
    cells = [(bytes([0x81, 0x42, 0x24, 0x18, 0, 0xFF, 1, 0x80]), 2, False), (bytes(8), 0, False),
             (bytes([0xF0] * 8), 4, True), (bytes([0x0F] * 8), 0, False)]
    png.write_cells(tmp, 2, 2, cells)
    assert png.cells(tmp, 2, 2) == cells                      # round trip, inks and BRIGHT
    for bad, why in (((3, 2), 'pixels expected'),):
        try:
            png.cells(tmp, *bad)
            assert False, why
        except ValueError as e:
            assert why in str(e)
    # a 1-bit indexed PNG, as editors save two-colour images: black ink on white
    import struct
    import zlib

    def chunk(k, b):
        return struct.pack('>I', len(b)) + k + b + struct.pack('>I', zlib.crc32(k + b))
    raw = b''.join(b'\0' + bytes([0xA5]) for _ in range(8))
    open(tmp, 'wb').write(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', 8, 8, 1, 3, 0, 0, 0))
                          + chunk(b'PLTE', bytes([205, 205, 205, 0, 0, 0])) + chunk(b'IDAT', zlib.compress(raw))
                          + chunk(b'IEND', b''))
    assert png.cells(tmp, 1, 1) == [(bytes([0xA5]) * 8, 0, False)]


def test_goto():
    trail = []

    async def a():
        trail.append('a')
        raise Goto(b)

    async def b():
        trail.append('b')
        return 'done'

    async def main():
        return await dispatch(a)

    assert headless.run(main) == 0 and trail == ['a', 'b']


def test_replay(path='/tmp/zxpyxel-test.rec'):
    """Repeated reads ('in PORT VAL COUNT') and R reads come back in order."""
    open(path, 'w').write('checkpoint 8000\nstate 9000-9001\nin 00FE BF 3\nr 15\n'
                          'in 7FFE BE\na 9CD2 07\ncp 100 9000:2a\nend 1\n')

    class labels:
        Loop = 0x8000

    async def main():
        for _ in range(3):
            assert zx.inp(0x00FE) == 0xBF
        zx.mem[0x9000] = zx.r() + 0x15
        assert zx.inp(0x7FFE) == 0xBE
        assert zx.take(0x9CD2, 0x55) == 0x07
        zx.checkpoint('Loop')
        zx.inp(0x00FE)                       # past the end of the record: the replay stops

    zx.reset()
    assert headless.replay(main, path, labels)[0] == 1


def test_tape():
    """A block saved through SA_BYTES verifies and loads back; a missing one waits."""
    from zxpyxel import rom
    zx.reset()
    zx.mem[0x8000:0x8003] = b'abc'

    async def main():
        await rom.SA_BYTES(0x8000, 3, 0xFF)
        assert await rom.LD_BYTES(0x8000, 3, 0xFF, False)       # verify
        zx.mem[0x8000:0x8003] = b'xyz'
        assert not await rom.LD_BYTES(0x8000, 3, 0xFF, False)
        assert await rom.LD_BYTES(0x8000, 3, 0xFF, True) and zx.mem[0x8000:0x8003] == b'abc'
        await rom.LD_BYTES(0x8000, 4, 0xFF, True)              # no such block: waits

    assert headless.run(main, frames=300) == 300


def test_render():
    zx.reset()
    zx.mem[0x4000], zx.mem[0x5800] = 0x80, 0xC7              # FLASH BRIGHT, white ink on black
    assert screen.render(zx.mem, 0)[:2] == bytes([15, 8])
    assert screen.render(zx.mem, 1)[:2] == bytes([8, 15])
    assert screen.render(zx.mem)[256 * 8] == 0               # row 8 is the next cell row


if __name__ == '__main__':
    for name, f in list(globals().items()):
        if name.startswith('test_'):
            f()
    print('zxpyxel ok')
