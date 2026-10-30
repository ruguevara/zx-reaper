"""Streams in the original format (docs/05-pictures.md): header, commands,
$00; a picture that goes on into the next one ends with $08, whose two
operands are the next picture's header (the move they make is never used)."""


def line(c):
    _, major, minor, n, k = c
    vertical = major in 'ud'
    h, v = (minor, major) if vertical else (major, minor)
    r = k - 1
    return bytes([0x80 | (r >> 2) << 3 | (h == 'l') << 2 | (v == 'd') << 1 | vertical, (r & 3) << 6 | (n - 1)])


def encode(stream):
    out = bytearray([stream.border, stream.attr])
    for c in stream.commands:
        if c[0] == 'move':
            out += bytes([0x08, c[1], c[2]])
        elif c[0] == 'line':
            out += line(c)
        elif c[0] == 'fill':
            out += bytes([0x40 | c[1], c[2], c[3]])
        elif c[0] == 'paint':
            a = 0x5800 + c[2]
            out += bytes([0x20 | c[1], a >> 8, a & 0xFF] + [(n - 1) << 2 | 'urdl'.index(d) for d, n in c[3]] + [0xFF])
        elif c[0] == 'then':
            if out[-3] == 0x08 and stream.commands[-2][0] == 'move':
                del out[-2:]            # the move to the next header is this $08
            else:
                out.append(0x08)
            return bytes(out)
    out.append(0x00)
    return bytes(out)
