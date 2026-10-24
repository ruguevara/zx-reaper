# Hungry Horace: the blind POKE search compared with the published POKEs

`re/pokes.md` and `re/pokes.pok` were written blind by one subagent
following the `zx-poke` skill as it was after Jet Set Willy: the project
files and the simulator only, no web, no remembered POKEs. It took about
13 minutes (76 tool calls, 187,000 tokens) and found 23 POKEs, every one
checked by a run that reaches the event and by 20,000 frames of random
play. It found no developer cheat or test code, and said why: every
keyboard read is the title's any key, the demo abort, the four direction
pairs or T for sound, all of them executed, and no text goes unprinted.

The published POKEs were collected afterwards by the lead, who had not
shown them to the subagent:
- ZXDB (Spectrum Computing / World of Spectrum POKE database), the file
  `Hungry Horace (1982)(Sinclair Research).pok`: two POKEs;
- Crash 21 (October 1985), page 78, playing tips: one tip, no POKE;
- Home Computing Weekly 128 (September 1985), page 46, listed by ZXDB as
  tips: no Hungry Horace text in the scan's OCR.

## POKEs

| Published | Blind run | Same effect? |
| --- | --- | --- |
| Infinite lives: 26429,0 | Infinite passes: 26429,0 (`DEC A` -> NOP in HoraceDies) | the same POKE |
| Immunity: 26290,42 (`JP Z,HoraceDies` -> `LD HL,($673A)`) | three: 26290,218 (`JP Z` -> `JP C`: guards always edible), 26291,57 (the jump lands on a `RET`: harmless, the bell still works), 26284,201 (no contact test: walk through, guards cannot be eaten) | 26290,42 and 26290,218 behave alike: in 4,000 frames of `play.txt` neither loses a pass, HoraceDies is reached 0 times (12 in the original, `check --hits HoraceDies`), and guards are eaten on contact (GuardWait changes 824 and 838 times, 0 in the original). Same address, a different byte: ZXDB's turns the jump into a harmless load, the blind run's into a jump on a flag that is never set there |
| none | 20 more: starting passes, start maze, starting pace, no speed-up, bell duration (two), guards' chase, guards frozen, one guard, no guards, points for flowers, fruit and guards, extra-pass threshold, guard wait, early fruit, game speed, the bell moved next to the start | not published; all observed |

Both published POKEs were found; the published list has nothing the blind
run lacks.

## The magazine tip

Crash, October 1985 (from Michael Page of Hull): "When collecting a bell
move away once you have touched it. If you have done it right the bell will
still be there and you will get extra points. You can repeat this as often
as you like."

This is a bug the stage 2 run had already found and documented without the
tip: "The bell pays 50 points per pass" (`docs/06-tricks.md`). The bell is
taken only at five of Horace's offsets from it, while the bell's colour,
which scores 50 points, is seen at four more; touching it at one of those
scores and leaves it in place. The article verified the scoring with a
POKE and marked where it happens in play as inferred; the tip shows that
players reached it and repeated it on purpose. The blind POKE run did not
look for it: it is a way to play, not a byte to change.

## What the run taught the skill and the tool

From the subagent's report of problems, and from the published immunity
POKE:

- `profile` for lives must stay inside one game: `play.txt` plays three,
  the pass counter jumps from 0 to 3 at each new game, and `--step 1`
  dropped it. The skill now says so.
- Words: the bell timer and the score are 16 bits, read one byte at a time
  by `trace`, `check` and `writers`; the low byte of `LD HL,$015E` was
  patched first by mistake. Added `--word` and a note on byte order.
- `writers` proposed "never jump" for a jump that jumps to the write, and
  "block this path" where the code after the jump reaches the write as
  well; its "before" list ran across a call into another routine. The
  first is gone, the second is left out for short jumps inside the
  stretch that leads to the write and marked "check" otherwise, the third
  stops at the last return. It now proposes `DEC rr` -> NOP before a
  16-bit store, the better bell POKE the subagent found by reading.
- `check` now says whether the patched code ran at all, since a long run
  identical to the original proves nothing about code it never reached,
  and counts passes through an address (`--hits HoraceDies`: deaths).
- `pok --apply` applies chosen POKEs (`--select`) with a value for those
  that ask (`--ask`), and compares original bytes before applying, so two
  POKEs at one address no longer warn.
- `keys` names the keys each read tests (`BIT`, `AND`, `CP` after the IN).
- `zxq.py` and `zxpoke.py` take labels where they take addresses.
- One-byte ways to disarm a 3-byte jump (`LD HL,(nn)` = 42, a condition the
  flags never meet, a target moved onto a `RET`) are in the skill.
- Timing: a patch that shortens a path shifts the screen hashes by a few
  T-states; "first differ at frame N" is not an effect until a screenshot
  shows one.

The tool in this project's `tools/` is the version the blind run used.
