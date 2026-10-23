"""The 48K Spectrum as a ported game sees it: memory, a T-state clock, port
$FE, interrupts, and the frames that follow from the clock.

No CPU is emulated. The port charges time itself (`spend`, `tone`) and hands
the frames the clock has passed to the host (`await sync()`, `await halt()`).
"""
import os

from . import keys, sound

T_FRAME = 69888          # T-states per 48K frame (224 x 312)
FRAMES = 0x5C78          # system variable the IM1 handler counts
ROM = open(os.path.join(os.path.dirname(__file__), '48.rom'), 'rb').read()


def djnz_t(b):
    """T-states of a DJNZ loop of B passes (B = 0 makes 256)."""
    return 13 * (b or 256) - 5


class _Frame:
    def __await__(self):
        yield            # back to the host for one frame


_FRAME = _Frame()


class Spectrum:
    def __init__(self):
        self.mem = bytearray(0x10000)
        self.reset()

    def reset(self, ram=b''):
        """ROM at $0000, `ram` (up to 48K) from $4000, the rest zero."""
        self.mem[:0x4000] = ROM
        self.mem[0x4000:] = bytes(ram).ljust(0xC000, b'\0')
        self.t = 0                 # T-states since reset
        self.frame_end = T_FRAME   # clock at the next frame interrupt
        self.border = 7
        self.speaker = 0
        self.edges = []            # speaker changes (t, level) the host has not taken
        self.audio_level = 0
        self.keys = set()          # ZX keys held in this frame (keys.KEYS, keys.KEMPSTON)
        self.interrupts = False
        self.handler = self.count_frames
        self.on_checkpoint = None

    def peek16(self, a):
        return self.mem[a] | self.mem[(a + 1) & 0xFFFF] << 8

    def poke16(self, a, v):
        self.mem[a] = v & 0xFF
        self.mem[(a + 1) & 0xFFFF] = v >> 8 & 0xFF

    def out(self, port, v):
        if port & 1 == 0:          # ULA: border bits 0-2, speaker bit 4
            self.border = v & 7
            level = v >> 4 & 1
            if level != self.speaker:
                self.speaker = level
                self.edges.append((self.t, level))

    def inp(self, port):
        if port & 0xFF == 0x1F:
            return keys.kempston(self.keys)
        if port & 1 == 0:
            return keys.read(self.keys, port >> 8)
        return 0xFF

    def spend(self, t):
        self.t += t

    def tone(self, half, cycles, on, off):
        """A beeper loop: OUT on, wait `half` T-states, OUT off, wait, `cycles` times."""
        for _ in range(cycles):
            self.out(0xFE, on)
            self.t += half
            self.out(0xFE, off)
            self.t += half

    async def sync(self):
        """Hand the host every frame the clock has passed; the interrupt runs after each."""
        while self.t >= self.frame_end:
            await _FRAME
            self.frame_end += T_FRAME
            if self.interrupts:
                self.handler()

    async def halt(self):
        self.t = max(self.t, self.frame_end)
        await self.sync()

    def di(self):
        self.interrupts = False

    def ei(self):
        self.interrupts = True

    def im2(self, handler):
        self.handler = handler

    def count_frames(self):
        """What games see of the ROM's IM1 handler: FRAMES (3 bytes) + 1."""
        n = int.from_bytes(self.mem[FRAMES:FRAMES + 3], 'little') + 1
        self.mem[FRAMES:FRAMES + 3] = (n & 0xFFFFFF).to_bytes(3, 'little')

    def checkpoint(self, label):
        if self.on_checkpoint:
            self.on_checkpoint(label)

    def take_audio(self, rate):
        """16-bit PCM of the speaker from its first untaken change up to the clock; b'' if none."""
        if not self.edges:
            return b''
        pcm, self.audio_level = sound.pcm(self.edges, self.audio_level,
                                          self.edges[0][0], self.t, rate)
        self.edges.clear()
        return pcm


zx = Spectrum()
