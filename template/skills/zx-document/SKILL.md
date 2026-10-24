---
name: zx-document
description: Write the docs/ article that explains how a reverse-engineered ZX Spectrum game works, top-down, with a graphics gallery rendered to PNG and links into the sources. Use after annotation (titles and labels exist), before or after export.
---

# zx-document

Output: `docs/README.md` (index) plus one file per section, written for a
reader who knows programming but not this game: the level of a good Habr or
blog article. Every claim points to code with a relative link, so the docs
work on a private GitHub repository.

## Files

```
docs/README.md            title, screenshot, one-paragraph summary, table of contents
docs/01-overview.md       the game, the hardware it uses, memory map, how it loads
docs/02-data.md           data structures: variables, records, tables, formats (field tables)
docs/03-title-and-menu.md title screen, demo mode, start of a game
docs/04-game-loop.md      main loop, frame by frame; timing and speed
docs/05-<subsystem>.md    one file per subsystem (player, enemies/AI, collisions,
                          scoring, sound, screen drawing, levels...)
docs/06-tricks.md         non-obvious code: self-modifying code, ROM data reuse,
                          dead code, bugs, size/speed hacks
docs/07-graphics.md       gallery: every sprite set, tile set, font, title
                          graphic, loading screen and every level map as PNG
docs/08-porting.md        what a C/Python port must replace: hardware touch
                          points, timing, data formats, entry points
docs/img/                 PNGs (committed)
```

## Writing rules

- Top-down: start with what the player sees, then the loop, then subsystems,
  then details. Each file starts with a 2-3 sentence summary.
- Link names to sources: `[DrawSprite](../src/screen.asm#L120)` after export,
  or `[DrawSprite](../re/skool/6BD6.skool)` before. Get line numbers with
  `grep -n '^DrawSprite:' src/*.asm`; re-check them after every export.
- Use tables for record layouts (`Offset | Size | Meaning`), constants and
  memory maps; Mermaid `flowchart` for the main loop and state machines
  (GitHub renders it); short asm excerpts (5-15 lines) only where the trick is
  in the code itself.
- State what is verified and what is inferred. Mark guesses as such.
- Keep a claim inside its evidence. "Never", "always", "unused", "any
  order", "whatever you do" need a scan of every case (every message, for
  "this control code is unused") or a run of each case the mechanism allows
  (each way out of a trap, each word order). A summary of a finding keeps
  the finding's conditions.
- Numbers: hex with `$`, decimal in parentheses where it helps (`$0300` (768)).
  GitHub reads `$...$` as inline maths, so `$A000-$A3FF` shows `$A000-$` as
  a formula; `tools/zxq.py dollars docs/*.md` writes every such `$` as
  `&#36;` (renders as `$`; code spans are left alone).
- No filler, no marketing tone, no metaphors.

## Audit before writing

`make audit` lists open questions and `unknown`/`inferred` findings. Answer or
mark each question (`tools/zxq.py question set Q7 answered "F12, F15"`), try to
turn important `inferred` findings into `observed` ones (simulator, models),
and list what stays open in `docs/06-tricks.md` under "Open questions".
When a finding answers an unknown, change every place that still states it:
grep `re/notes.md`, `re/questions.md`, the README's "Not explained" and the
comments in `src/` for the address and the term. Code no input ran: `zxq.py
refs` on each stretch; with no reference it is dead code (a finding), with
one it is a path the coverage scripts have not taken yet. The
"verified"/"inferred" marks in the article come from `re/findings.md`; cite
finding IDs where a claim is not obvious.

## Bug hunt before writing `06-tricks.md`

Annotation finds bugs on the paths it reads; bugs at the edges need a
deliberate pass. For every counter and timer variable (lives, level, speed,
score digits, timers, list indexes):
- what happens at its minimum, maximum and on overflow (e.g. 10 lives, the
  last level, the fastest speed, a score past 99999);
- force it in the simulator: `tools/zxrun.py re/orig.z80 --poke ADDR,VALUE
  --input tests/inputs/play.txt --shot F:/tmp/x.png` and look at the result;
- check printing of multi-digit values, delay formulas for negative or
  wrapped results, and interactions of two actors (two enemies on top of each
  other, an enemy over an item).
Then the paths no script took:
- sequences, not single commands: type random lines from the game's own
  vocabulary and command patterns (`TYPE` in an input script, many seeds),
  including a refused line followed by the repeat key, junk after ALL or
  EXCEPT, and very long lines; a hang or a reset is a finding;
- every command pattern against the handler tables: a pattern with no
  handler is a sentence the game accepts and cannot carry out;
- every screen of the recorded runs read for odd text (a doubled word, a
  wrong name): `tools/zxrun.py ... --text` at each prompt;
- what a new game restores and what it leaves as it was (script steps,
  self-modified operands), and what SAVE writes against what the game
  changes.
Record each finding with the evidence (frame, screenshot, value) and mark it
verified or inferred.

## Graphics

All images come from the game's bytes, never redrawn by hand:

- Sprite and tile sheets: `tools/zxgfx.py sheet ADDR COUNT W H docs/img/x.png
  --attrs ...` (colours = the attributes the game uses; `--layout linear` for
  row-ordered sprites; `--labels` captions each graphic, e.g. with how often
  the game uses it).
- Sprites with animation frames or movement phases: a GIF per animation,
  `tools/zxgfx.py gif ADDR COUNT W H docs/img/x.gif --order 0,1,2,3 --delay CS`,
  in the order and at the speed the game shows them (the frame rule comes
  from the code). Many animated objects (all enemies): one GIF of a sheet,
  built with `compose` and `write_gif` from `tools/zxgfx.py` in a project
  script. Things that move across a level: sample the screen every few frames
  (`tools/zxrun.py ... --frames N --dump`) and write the frames as a GIF.
- Levels, title graphics and anything with its own drawing routine: call the
  game's routine in the simulator and save the screen:
  `tools/zxrun.py re/orig.z80 --cls ATTR --call DrawMaze --reg HL=... --reg DE=$4000
  --reg BC=$300 --png docs/img/level1.png [--crop X,Y,W,H]`
  (use the routine's address; registers as its description says).
- Screens in play: `tools/zxrun.py re/orig.z80 --input tests/inputs/X.txt
  --shot F:docs/img/x.png`.
- Loading screen: `sna2img.py data/screen*.scr docs/img/loading.png`.
- Put the commands in `docs/img/Makefile` (or `scripts/docs-images.sh`) so
  images can be regenerated after changes.

Check every image by looking at it before linking it.

## Done when

All sections exist, every subsystem routine of the main loop is mentioned
with a link, every graphic and level is in the gallery, and the links resolve
(`grep -o '](\.\./[^)#]*' docs/*.md | sed 's/.*](//' | sort -u | xargs ls`
from `docs/`), and `tools/zxq.py dollars --check docs/*.md` reports nothing.
