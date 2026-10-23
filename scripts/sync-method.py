#!/usr/bin/env python3
"""Copy the method notes from the Obsidian vault into docs/.

  scripts/sync-method.py VAULT_NOTES_DIR

VAULT_NOTES_DIR is the vault folder with the notes ("Хобби/Реверс ZX Spectrum").
The vault is the master: edit the notes there and run this script. Wiki-links
between the copied notes become relative links; links to other vault notes
become plain text. The YAML front matter is dropped.
"""
import os
import re
import sys

NOTES = {
    'Метод реверса игр ZX Spectrum с агентом': 'method.md',
    'Hungry Horace — прогон метода и сравнение с SkoolKit': 'hungry-horace-run.md',
}
DOCS = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'docs')
HEADER = ('<!-- Copy of the vault note "{name}". Edit it in the vault, then run '
          'scripts/sync-method.py. -->\n\n')


def wiki_link(m):
    target, _, alias = m.group(1).partition('|')
    target = target.split('#')[0]
    text = alias or target
    return '[%s](%s)' % (text, NOTES[target]) if target in NOTES else text


def convert(text):
    if text.startswith('---\n'):
        text = text[text.index('\n---\n', 4) + 5:].lstrip('\n')
    return re.sub(r'\[\[([^\]]+)\]\]', wiki_link, text)


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    os.makedirs(DOCS, exist_ok=True)
    for name, out in NOTES.items():
        text = open(os.path.join(sys.argv[1], name + '.md'), encoding='utf-8').read()
        with open(os.path.join(DOCS, out), 'w', encoding='utf-8') as f:
            f.write(HEADER.format(name=name) + convert(text))
        print('docs/%s <- %s.md' % (out, name))


if __name__ == '__main__':
    main()
