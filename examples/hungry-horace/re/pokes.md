# POKEs and developer cheats

Found blind (skill `zx-poke`): only the project files and the simulator were
used; no published POKE list was looked up and none is compared here. All
POKEs apply to `re/orig.z80` (the code is loaded once at $5FB5 and never
moved or decrypted). `re/pokes.pok` holds the same list; `make pokes` checks
its original bytes.

Inputs used (all commands run from the project root with `tools/zxpoke.py`):
`tests/inputs/play.txt` (three games, deaths at frames 169, 376, 620, 805, ...),
`tests/inputs/bell.txt` (bell taken at 9981, a guard eaten at 9993, maze exit
at 9312), random play `--fuzz 11:6:P,Q,Z,I,P` / `14:...` / `5:...` for long
runs. Helper POKEs used with `check --with`: infinite passes (26429,0),
start maze (24778,N), the bell moved next to Horace's start (28633,162 +
28634,8), walk through guards (26284,201).

Every POKE below also survived a 20,000-frame random run (`check --fuzz
5:6:P,Q,Z,I,P --frames 20000`): screens still changing at the end, no crash.

| What | POKE | Address | Status | How found and checked |
| --- | --- | --- | --- | --- |
| Infinite passes (lives) | POKE 26429,0 | $673D `DEC A` in HoraceDies | observed | `profile --from 100 --frames 900 --changes 1-9 --max 10 --step 1 --referenced` -> Passes $7C78 4@100 3@169 2@376 1@620 0@805; `writers ... 0x7C78 --frames 400` -> HoraceDies+4, proposal DEC A -> NOP. `check --input play.txt --poke 26429,0 --addr 0x7C78`: original 18 changes ending 0 (3 game overs), patched stays 4 from frame 30. `check --fuzz 11:6:P,Q,Z,I,P --frames 20000 --addr 0x7C71`: HoraceAttr (cycles 45 times per death) changes 1775 times patched, so about 39 deaths, passes still 4, maze 3 reached; screenshot at 19990 normal |
| Start with N+1 passes | POKE 24788,N | $60D4 operand of `LD A,3` in StartGame | observed | writers proposal "LD A,$03: the value written". The first ShowScore adds a free pass (F13), so N gives N+1. Checked 0, 1, 5, 9, 255 on play.txt: 0 -> 1 pass, 1 -> 2, 9 -> 10 shown as ":" (F14), 255 -> wraps to 0 at the free pass, digit "0", then 255, 254... (256 lives, digit "/"). Use 1-8 |
| Invulnerable, bell still works | POKE 26291,57 | $66B3, target of `JP Z,HoraceDies` in CheckGuardContact -> $6739 (a `RET`) | observed | `zxq.py refs 0x673A`: HoraceDies is reached only from $66B2, so guard contact is the only cause of death. Jump target moved to the `RET` at $6739 (end of the guard loop, `peek 0x672F 12`). `check --input play.txt`: no pass lost (4 throughout). `check --input bell.txt --addr 0x6DAF --addr 0x6DBE`: bell taken (timer high byte 4 at 2169), guard eaten (timer cleared at 2204, GuardWait 89 counting down), so eating guards still works. 30,000-frame fuzz run: passes 4, maze 3 reached. Guards are drawn and pass through Horace |
| Walk through guards | POKE 26284,201 | $66AC `RET NZ` -> `RET` in CheckGuardContact | observed | contact test never runs: no death, but the bell no longer lets Horace eat guards. play.txt: passes stay 4; 20,000-frame fuzz run fine. When Horace and a guard overlap, the saved backgrounds leave small sprite scraps (screenshot) |
| Guards always edible | POKE 26290,218 | $66B2 `JP Z` -> `JP C` | observed | after `OR L` carry is always clear, so the jump to HoraceDies never happens and every contact eats the guard (+100, guards sent home, GuardWait 90). play.txt: passes stay 4, GuardWait $6DBE changes 838 times (0 in the original). 20,000-frame fuzz: score 8120, no crash |
| Start maze | POKE 24778,N | $60CA operand of `LD A,$FF` (MazeNumber) in StartGame | observed | `writers ... 0x7C63` -> StartGame+2. Mazes are played 0-3 (F6); NextMaze increments first. N=0 -> maze number 1 (2nd maze), 1 -> 3rd, 2 -> 4th (screenshot of the 4th maze), 255 -> 1st. N=3 or 254 also speed the game up one step (pace 7), because NextMaze sees "after the fourth maze". Also changes the demo |
| Starting pace | POKE 24783,N | $60CF operand of `LD A,8` (GuardInterval) | observed | writers on $7C62. Lower is faster: 1 -> Horace steps every ~1-2 frames, 45 pass changes in 4000 frames of play.txt (18 originally); 4 -> 29; 16 -> slow, 9. 0 -> one step every ~950 frames (unplayable, also makes the bell timer 0: the bell is useless). 1-3 have the PaceAndChime stall (F11) |
| No speed-up every fourth maze | POKE 24815,24 | $60EF `JR Z` -> `JR` in NextMaze | observed | read NextMaze (`zxq.py show 0x6000`). Real maze exit reached by `check --fuzz 14:6:P,Q,Z,I,P --frames 40000 --with 26429,0 --with 24778,2 --poke 24815,24 --addr 0x7C62`: original pace 8 -> 7 at the exit at frame 32206, patched stays 8. POKE 24820,0 (`DEC A` -> NOP) gives the same (checked with `--with 24778,3`) |
| Bell lasts until a guard is eaten | POKE 26198,0 | $6656 `DEC BC` in DrawGuard | observed | `writers ... 0x6DAE --from 9900 --frames 10100` -> DrawGuard+26. With the bell next to the start and contact off (`--with 28633,162 --with 28634,8 --with 26284,201`): original BellTimer high byte 3@32 2@152 1@273 0@393 (timer runs out), patched stays $0400. Scared guards drawn (screenshot at 2000). Eating a guard still clears the timer |
| Bell four times longer | POKE 26857,36 | $68E9 `SRA H` -> `SLA H` in TakeBell | observed | TakeBell sets BellTimer = pace*128; SLA H makes it pace*512. Same input as above without the freeze: timer high byte 15@32 ... original runs out at 393, patched about 4 times later |
| Guards do not chase | POKE 25793,121 | $64C1 `ADD A,C` -> `LD A,C` in ChooseGuardMove | observed | read the AI (F8): the chase bonus is added here; LD A,C drops it, guards wander at random. 20,000-frame fuzz with infinite passes: about 30 deaths instead of 39 (HoraceAttr 1364 vs 1775 changes). Behaviour change, not immunity |
| Guards frozen | POKE 25535,201 | $63BF `LD HL` -> `RET` at PlanMoves_Guards | observed | guards never plan a move. Same fuzz run: 2 deaths instead of 39 (Horace walking into a standing guard); first guard record $6DE3 changes 3 times (only at maze changes; 4025 originally). Released guards stand at Horace's start cell (screenshot) |
| Only the first guard | POKE 27001,0 | $6979 `DEC DE` in TickGuardTimers | observed | release timers never count down: $6DA9/$6DAB stay 8/16 (177 and 182 changes originally); deaths halve in the fuzz run (822 vs 1775 HoraceAttr changes) |
| No guards | POKE 27001,0 + POKE 27177,255 | as above + $6A29, high byte of the first guard's timer in ResetGuardTimers | observed | `zxq.py show 0x6A22`. 20,000-frame fuzz without infinite passes: passes stay 4, mazes 1-3 reached, no guard on the screen |
| Points per flower | POKE 26037,N | $65B5, `LD BC,10` in EatObject | observed | play.txt with N=250: score 250, 500, 750... (high byte 1@64 2@101) |
| Points per fruit / bell item | POKE 26049,N | $65C1, `LD BC,50` in EatObject | observed | play.txt with first fruit early and infinite passes (`--with 24998,0 --with 26429,0`), N=200: fruit eaten at 1449 and 2480 gives +200 each |
| Points per eaten guard | POKE 26297,N | $66B9, `LD BC,100` in CheckGuardContact | observed | bell.txt N=250: guard eaten at 9993, score low byte 192 instead of 42 (+150) |
| Extra pass every 1040 points | POKE 26073,4 | $65D9, high byte of `LD BC,10000` in ShowScore | observed | bell.txt with 100 per flower and infinite passes: passes 5@519 6@1039 7@2248 ... 10, none in the original. Above 9 the digit is wrong (F14). Lower values give more |
| Eaten guards wait longer | POKE 26409,N | $6729, `LD A,$5A` (GUARD_WAIT) | observed | bell.txt N=255: GuardWait 255@10006 instead of 90 |
| First fruit early | POKE 24998,0 | $61A6, high byte of `LD HL,2000` in InitMaze | observed | play.txt: FruitTimer $7C65 starts at 208, fruit drops at frame ~147 (cherry in the screenshot at 400); none within 900 frames originally |
| Slower game | POKE 27057,N | $69B1, high byte of `LD HL,$015E` in PaceAndChime | observed | demo.txt: N=4 Horace steps every ~7 frames instead of 5, N=16 every ~16. (First tried 27056, the low byte, which made the game a little faster) |
| Bell next to Horace's start (maze 1) | POKE 28633,162 + POKE 28634,8 | $6FD9, bell start in the first maze descriptor | observed | descriptor $6FD7: +2 bell $106A, +6 Horace $08A1 (`peek 0x6FD7`); bell at $08A2 is taken on the first pass (BellPos 0 at frame 31, score 210). Testing aid for the bell POKEs |

Not POKEs here: the sound key T (CheckSoundKey) already toggles sound; the
loader's `POKE (PROG),255` and `POKE 23659,0` are the usual listing/BREAK
tricks, not protection that needs bypassing (no protection, Q1).

## Developer cheats and debug code

None found.

- `zxpoke.py keys`: 11 keyboard reads in 3 entries, all executed by the
  coverage maps: the title "any key" (all rows, $60BA), the demo abort (all
  rows, $6261), the controls Q/4, Z/3, I/1, P/2 ($62C6-$6313, one bit each)
  and T for sound ($6990). No read of other keys, no sequence matcher, no
  key combination.
- `zxq.py unexec re/maps/*.map`: everything not executed is game logic
  reached only by events (bell pickup, eating a guard, maze exit, demo abort
  from a key, the speed-up after maze 4, the T toggle) or the known dead
  bytes ($6A17-$6A1D, the CALL at $672F, F21). None of it reads keys, prints
  memory or sets a level.
- `zxq.py strings 4 0x5FB5 0x8000`: only the title, demo and status texts;
  no unreferenced message.
- No flag with a single writer that unlocks anything; GameActive $6B0B is
  only title/demo/game.

Developer-cheat findings were not added with `zxq.py finding add` (this run
was told not to edit `re/findings.md`); there is none to add.

## Comparison with published POKEs

Not made (blind run).
