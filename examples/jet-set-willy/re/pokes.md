# Jet Set Willy: POKEs and the developer's cheat

The game on which the `zx-poke` skill and `tools/zxpoke.py` were developed.
Each POKE below was found with the tool from the annotated sources and the
simulator, then checked (`zxpoke.py check`); afterwards the list was compared
with the POKEs page of the SkoolKit reference disassembly (skoolkit.ca,
"Pokes"). The comparison is at the end; what it taught became rules in the
skill. The POKEs are in `re/pokes.pok` (World of Spectrum format; 256 means
"ask for the value"); `make pokes` checks every original byte in it against
`re/orig.z80`.

Commands run from this directory with the harness's tool
(`../../tools/zxpoke.py`); `play.txt` is `tests/inputs/play.txt` (code entry,
then 40,000 frames of random play: two rooms, deaths, game over).

## POKEs

| What | POKE | Where | Status | How it was found and checked |
| --- | --- | --- | --- | --- |
| Infinite lives | 35899,0 | $8C3B `DEC (HL)` in RestartAfterDeath | observed | `profile --from 400 --changes 1-8 --max 10 --step 1` found LivesLeft ($85CC) among 12; `writers 0x85CC --from 4900` gave the one decrement; `check --frames 20000`: lives stay 7 through every death |
| Start with N lives | 34785,N (7) | $87E1, operand of `LD A,$07` in NewGame | observed | `writers 0x85CC --frames 300`; `check`: LivesLeft starts at N |
| Infinite time | 35408,24 | $8A50 `JR NZ` -> `JR` in FrameLoop | observed | `profile --step 1 --range 0x8000-0x10000` found the clock text (ClockText+4, ASCII digits); `writers 0x8583` proposed the JR; `check`: the clock stays 7:00am |
| Start in room N | 34795,N (33) | $87EB, operand of `LD A,$21` in NewGame | observed | `search` over room changes with `--referenced --max 63` left 16 candidates, CurrentRoom ($8420) the room number itself; `writers 0x8420 --frames 300`; `check --poke 34795,25 --shot`: Cold Store |
| Survive falls | 36579,0 36580,0 36581,0 | $8EE3 `JP NC,KillWilly` -> NOPs | observed | `writers 0x85D1 --depth 3`: KillWilly's paths, one per cause of death; `check`: no death from falls in play.txt |
| Survive guardians | 37425,0 37426,0 37427,0 | $9231 `JP NZ,KillWilly` in DrawEntities | observed | the other path of KillWilly in play.txt; `check` with the falls POKE: no deaths in 12,000 frames |
| Survive arrows | 37527,0 37528,0 37529,0 | $9297 `JP NZ,KillWilly` in DrawEntities | inferred | static only: `zxq.py refs 0x90B7` lists five jumps to KillWilly, no input reached this one |
| Survive nasties | 38451,0 38452,0 38453,0 | $9633 `JP Z,KillWilly-1` in MarkWillyCell | observed | `check --with 34795,35` (start in the Master Bedroom) and the bedroom POKE: the nasty death at frame 663 is gone |
| The bedroom figure (Maria) is harmless | 38246,0 38247,0 38248,0 | $9566 `JP NZ,KillWilly` in UpdateBedroom | observed | `check --with 34795,35`, walking left: 7 deaths in 1,000 frames without it, none from her with it (screenshot: Willy walks past) |
| WRITETYPER on from the start | 34275,10 | CheatProgress ($85E3) | observed | see below |
| Any colour code is accepted | 34483,195 | $86B3 `JP Z` -> `JP` in RunCodeCheck | observed | the path into NewGame from the code check (`writers 0x85D1 --frames 300 --depth 3`); `check` with a wrong code (1-1-1-1): the game starts |

## The developer's cheat: WRITETYPER

- `zxpoke.py keys` lists 26 keyboard reads in 9 entries. Besides the code
  entry, the title, the pause and Willy's controls, one entry reads keys in
  the middle of the frame loop (CheckTeleport, $8B70), and one of its reads
  ($8B8B, keys 1-5) never ran under the coverage maps: code behind a
  condition no input met.
- The entry compares a progress byte (CheatProgress, $85E3) with 10 and
  steps through a table of two key masks per step (rows Q-T and P-Y).
  `zxpoke.py keytab 0x85E5 11 --rows 0xFB,0xDF` reads the table as
  `.WRITETYPER`.
- The comparisons before the table say where it works: only in First
  Landing (room $1C) with Willy standing at Y = $D0.
- Check: start in First Landing (`--poke 34795,28`; the start Y is already
  $D0) and type the word with each key held 8 frames and released 8 frames
  (the `TYPE` line of an input script holds keys for 2 frames, faster than
  one pass of the frame loop: the counter went to 1 and back to 0).
  `zxpoke.py trace ... 0x85E3` shows the counter going 1 to 10, one step per
  letter.
- With the cheat on, key 9 held with keys 1-5 and 6 teleports to the room
  whose number the keys give as bits (the read at $8B8B).
- The same entry file holds leftover test code: ShowAttrMap ($96F4, never
  run, no caller) shows the room's attribute map and reads key X.

## Comparison with the SkoolKit "Pokes" page

| SkoolKit | This run | Note |
| --- | --- | --- |
| Infinite lives 35899,0 | 35899,0 | same |
| More lives 34785,N | 34785,N | same; SkoolKit adds 35211,201 (do not draw the lives) for large N, since DrawLives draws one Willy per life: not found here |
| Infinite time 35408,24 | 35408,24 | same, after the rule "a conditional jump before the write that skips it becomes unconditional" was added to `writers`; the first proposal was 3 NOPs on `INC (IX+4)`, which freezes one digit only |
| Start in room N 34795,N | 34795,N | same; SkoolKit also gives the start position (34790, 34800, 34801): the writers of Willy's Y and attribute address at a new game, not looked for |
| Harmless heights 36578,16 | 36579-36581,0 | a different patch with the same effect in `check`: SkoolKit raises the operand of the `CP $0C` before the jump (one byte), this run removed the jump (three) |
| Gentle guardians 37392,0 | 37425-37427,0 | different place: SkoolKit changes the collision test's mode before the sprite is drawn, this run removed the jump after it |
| Agreeable arrows 37505,24 | 37527-37529,0 | different place, same idea; this run's is not run-checked |
| Nice nasties 38447,201 | 38451-38453,0 | SkoolKit returns at the start of the test (`RET`, one byte); both checked |
| Deal with Maria 38207,24 | 38246-38248,0 | SkoolKit removes her (`JR NZ` -> `JR`: "no figure"), this run makes her harmless; both checked. SkoolKit's "Maria leaves after N items" (41983,256-N) needs the item table, not looked for: no input collected an item |
| Cheat mode 34275,10 | 34275,10 | same |
| No code sheet 34483,195 | 34483,195 | same; SkoolKit also bypasses the code screen (33797,135 and 33800,202), not looked for |
| Official Software Projects POKEs (60231,0, 42183,11, 59901,82, 56876,4) | none | bug fixes in room and item data, not cheats; found by reading the room data (the comparison of the earlier run lists the bugs) |

What the comparison changed in the skill:

- Prefer one byte: look at the few instructions before a jump for a
  compare operand that can be moved out of range (`CP $0C` -> `CP 16`), a
  `JR cc` that can become `JR`, or the routine's first byte (`RET`, 201).
  `writers` proposes the jump and the operand patches; the operand ones
  are read by hand.
- Remove versus disarm: blocking the kill path leaves the hazard drawn; the
  published POKE for Maria skips drawing her. Both are POKEs; say which one
  a POKE is.
- An input for every event: random play never collected an item, so the
  item POKEs were not found. List the events (lose a life by each cause,
  collect, change room, run the clock, finish a level) and write a script
  for each before searching, or start next to the event with a start-room
  POKE.
- Large values break displays: a POKE of a starting count needs a run with
  a large value and a screenshot (SkoolKit's 35211,201).
