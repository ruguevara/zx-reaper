"""Speaker changes → 16-bit mono PCM and WAV."""
import io
import wave

CLOCK = 3500000          # T-states per second
ON = (12000).to_bytes(2, 'little', signed=True)
OFF = b'\0\0'


def pcm(edges, level, t0, t1, rate):
    """PCM from clock t0 to t1. `edges` are (t, level) changes and `level` holds
    before them. Returns the PCM and the level at t1."""
    out = bytearray()

    def fill(t):
        out.extend((ON if level else OFF) * ((t - t0) * rate // CLOCK - len(out) // 2))

    for t, new in edges:
        fill(t)
        level = new
    fill(t1)
    return bytes(out), level


def wav(data, rate):
    f = io.BytesIO()
    with wave.open(f, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(data)
    return f.getvalue()
