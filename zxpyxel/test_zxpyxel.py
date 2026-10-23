"""Checks of the core: python -m zxpyxel.test_zxpyxel (or pytest)."""
from zxpyxel import T_FRAME, headless, keys, screen, sound, zx
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
