# Questions

What this reverse engineering must answer; revisit before finishing. Edit through `tools/zxq.py question`.

| ID | Status | Question | Answer |
| --- | --- | --- | --- |
| Q1 | answered | How is the game loaded and where does control pass to it (loader stages, protection, decryption)? | docs/01-overview.md: two BASIC programs, loading screen, one code block at $5FB5, entry $6000; no protection; F1 |
| Q2 | answered | What is the memory map: code, data, variables, buffers, unused areas? | re/notes.md memory map, docs/01-overview.md, src/ modules |
| Q3 | answered | What are the controls (keys, joysticks, redefinition, pause, sound toggle)? | Q/4 up, Z/3 down, I/1 left, P/2 right, T toggles sound; no joystick; docs/05-horace.md |
| Q4 | answered | What happens on the title screen, menu and demo, and how does a game start? | docs/03-title-and-menu.md; F7 |
| Q5 | answered | What does one pass of the main loop do, in which order, and what sets the game speed (frames, delays, interrupts)? | docs/04-game-loop.md: 12 calls per pass, busy-wait delay sets the speed; F11 |
| Q6 | answered | How does the player move and what does it collide with? | docs/05-horace.md: attribute colours as collision map; F3 |
| Q7 | answered | How do enemies move and decide (AI rules, randomness, difficulty)? | docs/05-guards.md; F8, F9, F18, F19 |
| Q8 | answered | How is the score counted and shown; how are extra lives awarded? | docs/05-bell-fruit-score.md; F13, F14, F16, F17 |
| Q9 | answered | How is a life lost and what happens at game over (high score)? | docs/05-death.md; F12 |
| Q10 | partial | How do levels advance, what changes per level, and what happens after the last one? | cycle of 4 mazes, pace drops after every 4th (F6, F11); long games past maze 29 not run (F23) |
| Q11 | answered | What are the data formats (level maps, sprites, tiles, fonts, texts, tables)? | docs/02-data.md, docs/07-graphics.md |
| Q12 | answered | Where do random numbers come from? | ROM bytes via RandomPtr (F5); the guard AI reads ROM bytes at FRAMES (F8) |
| Q13 | answered | What sounds does the game make and how? | docs/05-sound.md |
| Q14 | answered | Which hardware does each routine touch (screen, attributes, border, ports, ROM, interrupts, timing)? | docs/08-porting.md (from the Hardware: sentences) |
| Q15 | partial | What happens at the edges of every counter: minimum, maximum, overflow (lives, level, speed, score digits, timers, indexes)? | lives 10 (F14), pace 1-3 (F11), score byte wrap (F9), start passes (F13); score past 99999 and long games not tested (F23) |
| Q16 | answered | Which code never ran in our inputs, and is it dead or only unreached? | 8% not executed with our inputs, read statically (F24); provably dead code F20, F21 |
| Q17 | partial | Which bugs does the original have, and is each one observed? | observed: F9-F14, F17-F20; unknown: F22 |
