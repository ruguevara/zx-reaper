"""Checks of the core: python -m zxpyxel.test_zxpyxel (or pytest)."""
from zxpyxel import T_FRAME, Goto, dispatch, headless, keys, mem, mem16, screen, sound, zx
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
