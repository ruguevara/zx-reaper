# Questions

What this reverse engineering must answer; revisit before finishing. Edit through `tools/zxq.py question`.

| ID | Status | Question | Answer |
| --- | --- | --- | --- |
| Q1 | open | How is the game loaded and where does control pass to it (loader stages, protection, decryption)? |  |
| Q2 | open | What is the memory map: code, data, variables, buffers, unused areas? |  |
| Q3 | open | What are the controls (keys, joysticks, redefinition, pause, sound toggle)? |  |
| Q4 | open | What happens on the title screen, menu and demo, and how does a game start? |  |
| Q5 | open | What does one pass of the main loop do, in which order, and what sets the game speed (frames, delays, interrupts)? |  |
| Q6 | open | How does Bilbo move between locations, and how are locations connected (exits, doors, special crossings, darkness)? |  |
| Q7 | open | How do the other characters move and decide (ANIMACTION: rules, randomness, who follows, attacks, captures)? |  |
| Q8 | open | How is the score ("mastered N% of this adventure") counted and shown? |  |
| Q9 | open | How does Bilbo die (fights, strength, falls), and what happens after death? |  |
| Q10 | open | How does the game end (the treasure in the chest, death, QUIT), and what restarts it? |  |
| Q11 | open | What are the data formats (level maps, sprites, tiles, fonts, texts, tables)? |  |
| Q12 | open | Where do random numbers come from? |  |
| Q13 | open | What sounds does the game make and how? |  |
| Q14 | open | Which hardware does each routine touch (screen, attributes, border, ports, ROM, interrupts, timing)? |  |
| Q15 | open | What happens at the edges of every counter: minimum, maximum, overflow (lives, level, speed, score digits, timers, indexes)? |  |
| Q16 | open | Which code never ran in our inputs, and is it dead or only unreached? |  |
| Q17 | open | Which bugs does the original have, and is each one observed? |  |
| Q18 | open | How is a typed line parsed (INGLISH): vocabulary format, verbs, adverbs, prepositions, AND/ALL/EXCEPT, ambiguity queries, the 128-character limit? |  |
| Q19 | open | How are messages and descriptions stored and printed (compression, dictionary, control codes, the two windows, scrolling, the 42-column font)? |  |
| Q20 | open | How are objects modelled (location, container, weight, size, light, liquids, locks, breakable, open/closed) and what rules apply to them? |  |
| Q21 | open | How are location pictures stored and drawn (format, primitives, fill), and when are they shown? |  |
| Q22 | open | How does fighting work (strength, weapons, who wins, death of characters)? |  |
| Q23 | open | How does time pass (real-time WAIT after idle, turns, the order in which characters act)? |  |
| Q24 | open | How does SAY TO work (ANIMTALK): who agrees, and why? |  |
| Q25 | open | How do SAVE, LOAD, PRINT, NOPRINT, PAUSE and QUIT work, and which ROM routines and ports do they use? |  |
