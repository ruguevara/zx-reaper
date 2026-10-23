# Questions

What this reverse engineering must answer; revisit before finishing. Edit through `tools/zxq.py question`.

| ID | Status | Question | Answer |
| --- | --- | --- | --- |
| Q1 | open | How is the game loaded and where does control pass to it (loader stages, protection, decryption)? |  |
| Q2 | open | What is the memory map: code, data, variables, buffers, unused areas? |  |
| Q3 | open | What are the controls (keys, joysticks, redefinition, pause, sound toggle)? |  |
| Q4 | open | What happens on the title screen, menu and demo, and how does a game start? |  |
| Q5 | open | What does one pass of the main loop do, in which order, and what sets the game speed (frames, delays, interrupts)? |  |
| Q6 | open | How does the player move and what does it collide with? |  |
| Q7 | open | How do enemies move and decide (AI rules, randomness, difficulty)? |  |
| Q8 | open | How is the score counted and shown; how are extra lives awarded? |  |
| Q9 | open | How is a life lost and what happens at game over (high score)? |  |
| Q10 | open | How do levels advance, what changes per level, and what happens after the last one? |  |
| Q11 | open | What are the data formats (level maps, sprites, tiles, fonts, texts, tables)? |  |
| Q12 | open | Where do random numbers come from? |  |
| Q13 | open | What sounds does the game make and how? |  |
| Q14 | open | Which hardware does each routine touch (screen, attributes, border, ports, ROM, interrupts, timing)? |  |
| Q15 | open | What happens at the edges of every counter: minimum, maximum, overflow (lives, level, speed, score digits, timers, indexes)? |  |
| Q16 | open | Which code never ran in our inputs, and is it dead or only unreached? |  |
| Q17 | open | Which bugs does the original have, and is each one observed? |  |
