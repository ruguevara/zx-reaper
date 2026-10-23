"""Re-point [Label](../src/F.asm#LN) links in docs/*.md at the label's current line; report links whose text is not a label."""
import re, glob, os
root = '.'          # run from the project root
labels = {}
for f in glob.glob(root + '/src/*.asm'):
    for i, l in enumerate(open(f), 1):
        m = re.match(r'([A-Za-z_]\w*):', l)
        if m: labels[m.group(1)] = (os.path.basename(f), i)
for p in sorted(glob.glob(root + '/docs/*.md')):
    s = open(p).read(); n = 0
    def fix(m):
        global n
        text, f, ln = m.group(1), m.group(2), int(m.group(3))
        if text in labels:
            nf, nl = labels[text]
            if (nf, nl) != (f, ln): n += 1
            return '[%s](../src/%s#L%d)' % (text, nf, nl)
        print('not a label:', os.path.basename(p), m.group(0))
        return m.group(0)
    s2 = re.sub(r'\[([^\[\]\n]+)\]\(\.\./src/([\w.]+\.asm)#L(\d+)\)', fix, s)
    if s2 != s: open(p, 'w').write(s2)
    if n: print(os.path.basename(p), 'fixed', n)
