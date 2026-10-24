#!/usr/bin/env python3
r"""Lossless Sinclair BASIC (48K) <-> text.

  zxbasic.py list PROG.bin [PROGLEN] > prog.bas   PROGLEN = header p2 (rest = variables)
  zxbasic.py build prog.bas PROG.bin

Text format: `LINENO BODY`, keywords spelled out with spaces around them.
Escapes:
  \XX           raw byte (hex): colour codes, UDGs, bytes in REM code
  \\            backslash
  \#=N, \#HEX   the stored 5-byte number when it differs from what the digits
                say (hidden-number trick: `CLEAR 0\#=24999`); also DEF FN slots
  .raw HEX      a whole line record (number, length, body) not expressible as text
  .vars HEX     the variables area after the program
`list` tokenizes every line back and falls back to .raw, so build(list(x)) == x.
"""
import re
import sys

KW = ('RND INKEY$ PI FN POINT SCREEN$ ATTR AT TAB VAL$ CODE VAL LEN SIN COS TAN '
      'ASN ACS ATN LN EXP INT SQR SGN ABS PEEK IN USR STR$ CHR$ NOT BIN OR AND '
      '<= >= <> LINE THEN TO STEP DEF_FN CAT FORMAT MOVE ERASE OPEN_# CLOSE_# '
      'MERGE VERIFY BEEP CIRCLE INK PAPER FLASH BRIGHT INVERSE OVER OUT LPRINT '
      'LLIST STOP READ DATA RESTORE NEW BORDER CONTINUE DIM REM FOR GO_TO GO_SUB '
      'INPUT LOAD LIST LET PAUSE NEXT POKE PRINT PLOT RUN SAVE RANDOMIZE IF CLS '
      'DRAW CLEAR RETURN COPY').split(' ')
KW = {0xA5 + i: k.replace('_', ' ') for i, k in enumerate(KW)}
BY_TEXT = sorted(((k, c) for c, k in KW.items()), key=lambda x: -len(x[0]))
REM = 0xEA
SPECIAL = {0x5E: '↑', 0x60: '£', 0x7F: '©'}
UNSPECIAL = {v: k for k, v in SPECIAL.items()}
NUM_RE = re.compile(r'(\d+\.?\d*|\.\d+)(E[+-]?\d+)?')


def zx_number(text):
    """5-byte form the ROM stores for a numeric literal."""
    v = float(text)
    if v == int(v) and 0 <= v <= 65535:
        n = int(v)
        return bytes([0, 0, n & 255, n >> 8, 0])
    if v == 0:
        return bytes(5)
    e = 0
    m = v
    while m >= 1:
        m /= 2
        e += 1
    while m < 0.5:
        m *= 2
        e -= 1
    mant = int(m * 2 ** 32 + 0.5)
    if mant >= 2 ** 32:
        mant >>= 1
        e += 1
    return bytes([e + 128, (mant >> 24) & 0x7F, (mant >> 16) & 255, (mant >> 8) & 255, mant & 255])


def detok(body):
    """Text for a line body (without the final 0x0D)."""
    out = []
    added = False   # the last output char is a space we added after a keyword
    in_str = in_rem = False
    i = 0
    while i < len(body):
        b = body[i]
        if not (in_str or in_rem) and b >= 0xA5:
            kw = KW[b]
            if out and not added:
                out.append(' ')
            out.append(kw + ' ')
            added = True
            in_rem = b == REM
            i += 1
            continue
        added = False
        if b == 0x0E and not (in_str or in_rem) and i + 5 < len(body) + 0:
            # 5-byte number after digits: omit if it is the canonical one
            m = re.search(r'(?:^|(?<=[^A-Za-z0-9$]))' + NUM_RE.pattern + r'$', ''.join(out))
            stored = bytes(body[i + 1:i + 6])
            try:
                ok = m and zx_number(m.group(0)) == stored
            except (ValueError, OverflowError):
                ok = False
            if ok:
                out.append('')
            elif stored[:2] == b'\0\0' and stored[4] == 0:
                out.append('\\#=%d' % (stored[2] | stored[3] << 8))
            else:
                out.append('\\#' + stored.hex())
            i += 6
            continue
        if b == 0x22 and not in_rem:
            in_str = not in_str
        if b == 0x5C:
            out.append('\\\\')
        elif b in SPECIAL:
            out.append(SPECIAL[b])
        elif 0x20 <= b < 0x7F:
            out.append(chr(b))
        else:
            out.append('\\%02X' % b)
        i += 1
    text = ''.join(out)
    if text.endswith(' '):
        text = text[:-1] if added else text[:-1] + '\\20'
    return text


def hidden_number(text, i, out):
    """Append 0x0E + 5 bytes for the \\#=N or \\#HEX escape at text[i]; return the new index."""
    h = re.match(r'\\#=(\d+)', text[i:])
    if h:
        out += b'\x0e' + zx_number(h.group(1))
        return i + h.end()
    out += b'\x0e' + bytes.fromhex(text[i + 2:i + 12])
    return i + 12


def tok(text):
    """Line body bytes (without the final 0x0D) for a text body."""
    out = bytearray()
    in_str = in_rem = False
    after_kw = False
    i = 0
    start = True
    while i < len(text):
        c = text[i]
        if not (in_str or in_rem):
            prev_ok = start or text[i - 1] == ' '
            kw = next((k for k, code in BY_TEXT if text.startswith(k, i) and prev_ok and
                       (i + len(k) == len(text) or text[i + len(k)] == ' ')), None)
            if kw:
                code = next(code for k, code in BY_TEXT if k == kw)
                if not start and not after_kw and out and out[-1] == 0x20:
                    out.pop()   # the space before a keyword is the one we added
                out.append(code)
                i += len(kw) + 1  # skip the space added after it
                after_kw = True
                start = False
                in_rem = code == REM
                continue
            m = NUM_RE.match(text, i)
            if m and (i == 0 or not re.match(r'[A-Za-z0-9$.]', text[i - 1])):
                out += m.group(0).encode()
                i = m.end()
                if text.startswith('\\#', i):
                    i = hidden_number(text, i, out)
                else:
                    out += b'\x0e' + zx_number(m.group(0))
                after_kw = start = False
                continue
        after_kw = start = False
        if c == '\\':
            if text[i + 1] == '#':
                i = hidden_number(text, i, out)
            elif text[i + 1] == '\\':
                out.append(0x5C)
                i += 2
            else:
                out.append(int(text[i + 1:i + 3], 16))
                i += 3
            continue
        b = UNSPECIAL.get(c, ord(c))
        if b == 0x22 and not in_rem:
            in_str = not in_str
        out.append(b)
        i += 1
    return bytes(out)


def list_program(data, prog_len=None):
    if prog_len is None:
        prog_len = len(data)
    lines = []
    i = 0
    while i + 4 <= prog_len:
        num = data[i] << 8 | data[i + 1]
        n = data[i + 2] | data[i + 3] << 8
        rec = data[i:i + 4 + n]
        body = rec[4:]
        text = None
        if len(body) == n and body.endswith(b'\r') and num < 65536:
            t = detok(body[:-1])
            try:
                same = tok(t) == body[:-1]
            except (ValueError, IndexError):
                same = False
            if same:
                text = '%d %s' % (num, t)
        lines.append(text or '.raw ' + rec.hex())
        i += 4 + n
    if i < len(data):
        lines.append('.vars ' + data[i:].hex())
    return '\n'.join(lines) + '\n'


def build_program(text):
    out = bytearray()
    for line in text.splitlines():
        if not line.strip():
            continue
        if line.startswith('.raw '):
            out += bytes.fromhex(line[5:])
        elif line.startswith('.vars '):
            out += bytes.fromhex(line[6:])
        else:
            num, _, body = line.partition(' ')
            b = tok(body) + b'\r'
            out += int(num).to_bytes(2, 'big') + len(b).to_bytes(2, 'little') + b
    return bytes(out)


def main():
    a = sys.argv[1:]
    if len(a) in (2, 3) and a[0] == 'list':
        data = open(a[1], 'rb').read()
        sys.stdout.write(list_program(data, int(a[2], 0) if len(a) == 3 else None))
    elif len(a) == 3 and a[0] == 'build':
        open(a[2], 'wb').write(build_program(open(a[1], encoding='utf-8').read()))
    else:
        sys.exit(__doc__)


if __name__ == '__main__':
    import signal
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)   # quiet exit under `| head`
    main()
