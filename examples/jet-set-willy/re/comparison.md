# Jet Set Willy: harness run and comparison with the SkoolKit reference

A full ZX-REAPER run on Jet Set Willy (Software Projects, 1984), compared with
Richard Dymond's disassembly (skoolkit.ca, jsw-disassembly-20260428). No other
Horace game has a published disassembly (Horace Goes Skiing has one routine
online from a stalled 2021 project), so Jet Set Willy was chosen as the next
game with a full reference.

The reference was downloaded after annotation was finished and opened only
for this comparison. Subagents were told not to search the web and not to use
remembered names or facts. Jet Set Willy is a famous game and its disassembly
is likely in model training data, so some prior knowledge cannot be ruled
out; the run avoided remembered names visibly (the title tune is unnamed, the
bedroom figure is "the figure", not "Maria").

## Result

- `make` builds a tape byte-identical to `JETSET.TAP` (WoS "original" TAP):
  21 asm modules (15,044 lines), the BASIC loader, constants, tape manifest.
- 203 entries, all with titles; 369 labels; 0 16-bit and 89 8-bit literals
  left in the ASM (most are `>>8`, `&$FF` and mask idioms).
- Relocation: `$8000-$9EFF` assembled at +$100 plays frame-identical on five
  input scripts (58,000 frames, room changes, deaths, game over). The rest
  ($A000-$FFFF) is reached by page arithmetic and memory is full, so it stays
  fixed; the limits are in `re/notes.md`.
- Coverage 97% of code instructions (scripts, fuzz, the "Perfect JSW" RZX,
  pokes for the ending).
- 17/17 questions answered; 121 findings: 95 observed, 23 inferred,
  1 unknown, 2 refuted.
- Article: `docs/`, 17 files, about 23,000 words, 84 images from the game's
  bytes, including all 61 rooms and a room map built from the exits.

## Time and tokens

| Stage | Who | Time |
| --- | --- | --- |
| choose game, toolchain (SkoolKit, sjasmplus from source) | lead | ~10 min |
| init, colour-code input, coverage 93%, classification | lead | ~15 min |
| wave 1: drawing, protection, rooms, entities/sprites, items | 5 subagents (Sonnet) | ~18 min |
| wave 2: Willy, entities, special rooms, main loop, title | 5 subagents (Sonnet) | ~29 min |
| splits, review, coverage 97%, questions, relocation | lead | ~15 min |
| magic numbers | 2 subagents (Sonnet) | ~5 min |
| export, README | lead | ~5 min |
| article with gallery and bug hunt | 1 subagent (Opus) | ~27 min |

Subagent tokens: 2.90 M in total (annotation 2.03 M over 10 runs, 160-310 k
each; magic numbers 0.27 M; article 0.39 M). Human: chose the game when the
premise (a published Horace disassembly) failed; nothing else.

## Comparison

Tool: `tools/zxcompare.py ours.skool jsw.skool --start 0x8000 --end 0x10000`.

**Bytes:** identical over $8000-$FFED: same version of the game.

**Classification by byte:**

| ours \ reference | code | text | data | vars | unused |
| --- | ---: | ---: | ---: | ---: | ---: |
| code | 4191 | 0 | 0 | 0 | 58 |
| text | 0 | 369 | 0 | 9 | 0 |
| data | 0 | 0 | 25052 | 316 | 1984 |
| vars | 0 | 0 | 1 | 27 | 0 |
| unused | 0 | 0 | 423 | 0 | 320 |

Code vs non-code: 99.8%. The differences are type letters for the same
meaning: both call $93BB and $96F4 unused routines (ours `c`, reference `u`),
both call $8141-$81FF and $9718-$97FF unused (ours `u`, reference `b`), the
zero sprite pages $A680-$AAFF and room pages 61-63 are data described as
unused in ours and `u` in the reference (which identifies 61-63 as TRS-DOS
code; ours says "Z80 code, not a room"). The room buffer is `b` in ours and
`g` in the reference.

**Entry boundaries:** all 40 reference routines are entries in ours, with the
same start address. Ours has 7 more: the title screen and scroller ($8813,
$88AE) and the cheat check ($8B70) split from bigger routines, two pieces of
Willy's movement ($8E9C, $8EB0), and the two unused routines.

**Meaning:** every one of the 40 routine names matches the reference in
meaning, for example:

| Address | Ours | Reference |
| --- | --- | --- |
| $8400 | `StartProgram`: set up the stack and run a decryption loop that changes nothing | The game has just loaded |
| $873C | `ReadCodeSlot` | Read the keyboard during code entry |
| $8B07 | `ResumeAfterPause`: rest of the frame loop | Main loop (2) |
| $91BE | `DrawEntities`: draw and test them against Willy | Draw the rope, arrows and guardians |
| $9534 | `UpdateBedroom`: Master Bedroom and Bathroom events | Deal with special rooms |
| $96A2 | `PlayTune` | Play the theme tune (Moonlight Sonata) |
| $96DE | `PlaySweepSound` | Play an intro message sound effect |

**Bugs of the original game** (reference `bugs.ref`, 19 entries):

| Reference bug | Found? |
| --- | --- |
| The Attic bug | yes, observed (F92), and further: which definitions it breaks and that rooms 14-16 then kill Willy on entry, damage surviving a new game (F121, article) |
| Corrupted conveyors (rooms 24, 29, 49, 51) | yes, observed, with the CPIR cause (F30, F40) |
| Corrupted nasties (room 36) | yes, same finding |
| Don't mind your head | yes, observed (F116) |
| Invalid grid location ('D>') | yes, observed: FRAMES $8E gives index $FF (F6) |
| 12:30am in the afternoon | yes: noon shown as "a", game ends at "13:00p" (F75, F96) |
| The invisible item | partly: room 28 has an item with a blank graphic; unreachable not checked |
| From top to bottom | partly: rope limits and rooms whose up exit is themselves (F89); the jump through the top not found |
| Very corrupted conveyor | partly: room 29's conveyor is drawn wrong; the misplaced tile bytes not found |
| Stuck in the wall | no (follows from F116, not found) |
| The sticky bed | no (the bed is described as a conveyor, the stuck P key not found) |
| The self-collecting item | no (the rule "ink 7 collects" is F19, the white background of room 31 not found) |
| The inaccessible items, the uncollectable item | no (reachability was not simulated) |
| Guardian halos | no |
| Long distance nasties | no |
| The missed note | no |
| The pause bug (Interface 1 hangs) | no |
| The blank conveyor | no |

Found beyond the reference's bug list (checked in the simulator): a deadly
fall carried through a bottom exit repeats after every restart until game
over (F120; the reference has it as the fact "Dangerous connections");
white-ink guardians and arrows collect items (F19, F119; reference fact
"Items and whiteness"); the rope's segment-0 quirk (F91); vertical guardians
overshoot their limit by 4-8 Y units (computed).

**Facts** (reference `facts.ref`, 66 entries): about 25 are in our findings or
annotations, among them game over at 1am (F96), the music of life (F74),
BREAK quits (F99), WRITETYPER and the teleport (F72, F106), the white-seeking
arrow (F86), the unused room 47 (F35), the unused grid location (F6), unused
items (4 of 5 rooms), the unused guardian page $B100 (F59), codes from code
(F9: "plausible Z80 code of some other program"), the unused AIR text (F12),
the figure raising its arm by Willy's height (F63), rope climbing direction
(F88), the encroaching rope and ropes before arrows (F55, F87, F90), double
descent (F120 and the $94D2 rule), guardians need a clear path (F83), the
unused and untouchable entity definitions, one item behind another (F18),
items and whiteness, to pause or not to pause (F98), cheats never cycle
colours, the room with most items. Not found: statistics over guardians and
colours, the one-way saw and the monk, high jump on ramps, ramps through
walls, slippery slopes and floor ramps (tiles sharing attributes), unanimated
conveyors and guardians, "as you were" (Willy's frame and facing not reset),
the flickering clock, and the cultural references (tune names, room-name
puns), which the blind rules excluded.

**Documentation style:**

| | ours | reference |
| --- | ---: | ---: |
| words in entry descriptions | 28,607 | 6,963 |
| code instructions with a comment | 38% | 63% |
| mid-block comments | 555 | 839 |
| labels | 369 | 396 |
| 16-bit / 8-bit literals in the ASM | 0 / 89 | 264 / 569 |

As with Hungry Horace, ours puts the explanation into entry headers and
findings and names numbers; the reference comments more instructions.

## Harness changes made during the run

- `zxq.py reclassify` kept losing the `@org` of the first entry it replaced,
  so the image assembled at 0; it now keeps it.
- `zxq.py cut ADDR TITLE`: split an annotated entry in place (reclassify
  regenerates entries and drops their annotation). Annotators propose splits;
  the lead applies them (template AGENTS.md and zx-annotate skill updated).
- Shift test with a fixed tail: `SHIFT_END` and `SHIFT_LOAD` in
  `re/layout.mk`; `zxq.py asm` leaves ORGs at or above `SHIFT_END` unshifted;
  `zxq.py export` keeps such an ORG with its entry. Defaults are unchanged.
- Template `.gitignore`: `re/rzx/*.rzx` (an RZX embeds a game snapshot).

Lessons for the method: games that fill memory to $FFFF and find tables by
page arithmetic can only be relocated in part; reachability of items and
rooms needs a deliberate pass (jump physics in the simulator), which neither
annotation nor the bug hunt did, and it is where most of the missed bugs are.
