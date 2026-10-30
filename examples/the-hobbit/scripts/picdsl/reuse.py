"""Reuse: runs of tokens replaced by a copy of an earlier run of the same
picture (a loop when the copy overlaps what it copies) or a call of a run of
an earlier picture. The tokens depend on the pen, so a shape drawn again
somewhere else is the same run. The parse is optimal for the bit costs it is
given (an estimate: the type codes change with the tokens around them).
"""
import gamma

NEVER = ('then', 'end')     # a copy never takes these


def parse(all_tokens, cost, copy_cost, call_cost, calls=True):
    """The token lists with copies and calls where they are cheaper.
    cost(t): bits of a token; copy_cost(back, count), call_cost(stream,
    start, count): bits of a copy and a call. A copy never starts right
    after a move (a move is always followed by a line)."""
    out = []
    for j, toks in enumerate(all_tokens):
        n = len(toks)
        index = {}
        for p, t in enumerate(toks):
            index.setdefault(t, []).append(p)
        best = [0] * (n + 1)
        how = [None] * (n + 1)
        for i in range(n - 1, -1, -1):
            best[i] = cost(toks[i]) + best[i + 1]
            how[i] = None
            if toks[i][0] in NEVER or (i and toks[i - 1][0] in ('move', 'amove')):
                continue
            for p in index[toks[i]]:
                if p >= i:
                    break
                length = 0
                while i + length < n and toks[p + length] == toks[i + length] \
                        and toks[i + length][0] not in NEVER:
                    length += 1
                for m in range(2, length + 1):
                    c = copy_cost(i - p, m) + best[i + m]
                    if c < best[i]:
                        best[i], how[i] = c, ('copy', i - p, m)
            if calls:
                for q in range(j):
                    src = out[q][1]
                    for p, t in enumerate(src):
                        if t != toks[i]:
                            continue
                        length = 0
                        while i + length < n and p + length < len(src) and src[p + length] == toks[i + length] \
                                and toks[i + length][0] not in NEVER:
                            length += 1
                        for m in range(2, length + 1):
                            c = call_cost(q, p, m) + best[i + m]
                            if c < best[i]:
                                best[i], how[i] = c, ('call', q, p, m)
        res, i = [], 0
        while i < n:
            if how[i]:
                res.append(how[i])
                i += how[i][-1]
            else:
                res.append(toks[i])
                i += 1
        out.append((res, toks))
    return [r for r, _ in out]


def gamma_costs(all_tokens, k=gamma.K, codes=None):
    """Cost functions for parse() from the gamma code: the type codes of
    `codes` (the average over the contexts, 5 bits for a type not seen)."""
    codes = codes or gamma.type_codes(all_tokens)

    def type_bits(kind):
        lens = [len(c[kind]) for c in codes.values() if kind in c]
        return sum(lens) / len(lens) if lens else 5

    tb = {t: type_bits(t) for t in gamma.TYPES}
    return (lambda t: tb[t[0]] + gamma.token_bits(t, k),
            lambda back, count: tb['copy'] + gamma.token_bits(('copy', back, count), k),
            lambda q, start, count: tb['call'] + gamma.token_bits(('call', q, start, count), k))
