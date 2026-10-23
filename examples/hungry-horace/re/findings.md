# Findings

Every claim about the game with its status and evidence. `observed`: seen in the simulator, a byte check or a test; `inferred`: read from code, not run; `unknown`: open; `refuted`: shown wrong (keep it). Only observed evidence can make a claim observed. Edit through `tools/zxq.py finding`.

| ID | Status | Claim | Evidence | Refs |
| --- | --- | --- | --- | --- |
| F1 | observed | The sources rebuild the original TZX byte for byte | make: IDENTICAL | tape/tape.txt |
| F2 | observed | The code is relocatable: built at +$7, +$101 and +$1234 it plays frame-identically | make shift-test with tests/inputs demo (3000 frames) and play (4000) | src/game.asm |
| F3 | observed | StepCell moves one cell; a left move wraps inside the screen third and never changes it | zxdiff tests/models/step_cell.py: 512 cases (typical, boundary, high-bits) | StepCell |
| F4 | observed | SetAttrPointer puts the attribute address of HL in HL' and keeps HL | zxdiff tests/models/set_attr_pointer.py: 312 cases | SetAttrPointer |
| F5 | observed | GetRandom returns ROM bytes; RandomPtr wraps inside the first 8K | zxdiff tests/models/get_random.py: 323 cases incl. wrap and outside-8K | GetRandom, RandomPtr |
| F6 | observed | Mazes are played in the order $72F7, $6FF7, $75F7, $78F7 (map 1 is not first in memory) | screenshot of the first maze matches the map at $72F7 | Start, Maze1Map |
| F7 | observed | The demo starts about 606 frames after the title appears | zxrun run with no input | TitleLoop |
| F8 | inferred | Guard AI: per open direction 25, +40 straight on, -10 reversing, +random 0-31 sideways; chase bonus 10+distance towards Horace, negated while the bell timer runs; highest score wins, ties to the higher direction code | code: ChooseGuardMove; worked example in docs/05-guards.md | ChooseGuardMove |
| F9 | observed | A fleeing guard can turn towards Horace: the negated bonus wraps below 0 as an unsigned byte | simulator: scores up 65, right 54, down 253, left 8 | ChooseGuardMove |
| F10 | observed | OR C at $697F (meant OR E): GuardsReleased counts only after the bell has been taken, 256 ticks per waiting guard | 12000-frame demo run: no change before the bell, 256 increments after | TickGuardTimers |
| F11 | observed | At paces 1-3 the PaceAndChime delay underflows and the game stalls about 25 frames on every fourth pass | pokes: pace 1, bell gone, guard 3 timer $0140 | PaceAndChime |
| F12 | observed | Each demo abort leaves SP 2 bytes higher; the 70th abort crashes | simulator: 70 consecutive aborts, code at $601A overwritten from the 63rd | ReadControls, GameOver |
| F13 | observed | A game starts with 4 passes although Passes is set to 3 (ExtraPassMark starts at 0) | screenshot: PASSES 4 | ShowScore, StartGame |
| F14 | observed | Ten passes are printed as ":" (digit + 1 past 9) | zxrun --call ShowScore with Passes=9 and a score past 10000: status line "PASSES :" | ShowScore |
| F15 | refuted | ShowScore ignores HL, so LD HL,(Score) before the call is dead | zxrun --call ShowScore with HL=$1234 prints 04660 | ShowScore, main.asm |
| F16 | observed | ShowScore prints the number in HL; every caller loads Score first | same test as the refuted claim | ShowScore |
| F17 | observed | A bell overlapping Horace at offsets +32, +31, -31 or -33 is not taken but scores 50 on every pass | poke: bell one row above Horace, score +$32 per pass | UpdateBell, EatObject |
| F18 | observed | An eaten guard sends every released guard back to Horace start cell | forced in the simulator: poked contact with BellTimer running | CheckGuardContact |
| F19 | observed | CheckGuardContact walks the timers 1 byte per guard instead of 2, so a waiting guard can be sent home too | simulator: guard 2 reset while still waiting | CheckGuardContact_Reset |
| F20 | observed | $7C64 is dead state: written and read only by the AI, the read result is overwritten | simulator watch: counts 8..1 and reloads; no effect | UnusedAiCounter |
| F21 | inferred | $6A17-$6A1D and the CALL at $672F can never run (unconditional jumps around them); the bell turn-round at $68EF is overwritten by the next LoadGuardRecord | code; turn-round watched: GuardDir 3, 1, back to 3 | $6A17, $672F, $68EF |
| F22 | unknown | A guard following another one picks up the items the first one hides (reference: "Who ate my lunch?") | not tested; found only by comparison with the SkoolKit reference | SaveBackground |
| F23 | unknown | Long games: what happens after maze 29, when the pace stays at 1 | partly covered by the stall finding; no long run made | NextMaze |
| F24 | inferred | Code not executed with our inputs (8% of instructions, mostly the maze-cleared and bell-pickup paths) was annotated from reading | coverage maps in re/maps: demo, play, fuzz 2-5 (bounded by those inputs) | re/maps |
