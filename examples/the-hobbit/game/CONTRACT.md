# Stage 4 contract: The Hobbit as clean game logic

Stage 3 (`port/`) is the game in Python with the original's memory layout,
identical to the Z80 at every pass of the main loop. Stage 4 (`game/hobbit/`)
is the same game as plain Python over plain state, checked against stage 3.
The procedure: `skills/zx-clean/SKILL.md`; the reasons: zx-reaper's
`docs/stage4.md`. This file is binding for every slice.

## Decisions (with the author)

- Pictures: vector text files (the game's own commands), drawn with the
  original's line and flood-fill rules; PNG previews generated from them for
  viewing, not loaded.
- Screen: the exact Spectrum screen, part of the state (`GameState.screen`, a
  `zxpyxel.display.Display`), compared byte for byte at every check.
- Input: as the original (the line editor, arrows, `@`, DELETE, back-space,
  the idle WAIT).
- Sound: none (the original is silent).
- SAVE/LOAD: the state to a file (events `TapeSave`, `TapeLoad`); PRINT: the
  story lines to a transcript file (event `Printed`).

## Rules

- `game/` never imports `port/`, `bridge/` or anything with an address.
  No registers, no T-states, no memory: the state (`game/hobbit/state.py`,
  the lead's; read it first) and the game's data (assets) only.
- Faithful first: every behaviour of stage 3 stays, bugs and quirks included
  (findings in `re/findings.md`, comments in `port/` and `src/`), each with a
  comment naming it. Scratch memory of the original (work buffers, saved
  registers) becomes Python locals.
- One stage 4 function per stage 3 routine that the oracle can check
  (snake_case of its name; docstring first line in game terms, then
  `(stage 3: Name)`), plus helpers as needed. Small stage 3 helpers that are
  only record walks may vanish into Python (`s.things`, comprehensions).
- Arguments are meaningful values: `s` the state first, then ids, words,
  message names, flags. Results are returned (a tuple when several).

## Names, not addresses

| Original | Stage 4 |
| --- | --- |
| a location or thing record | its id (`s.locations[i]`; things by id through `world.thing(s, id)`) |
| a message (and a message tail other code enters) | the stage 3 label at its address (`'MsgDayDawns'`, `'LB575'`): `bridge/decode.names()` |
| a handler (verb tables, timers, arrivals, script routines) | the stage 3 function name (`'VerbTake'`, `'LA244_14'`): its stage 4 function is `registry.HANDLERS[name]` (each module registers its handlers: `@registry.handler('VerbTake')`) |
| a word | its dictionary offset (an int; a phrase code adds flags in bits 12-15) |
| an NPC script position | an index into `s.program` |
| a behaviour table | its name (the stage 3 label) |
| the blocked exit, the random event | their index in their tables |

## Events

A routine that needs input or holds the game is a generator: it yields events
(classes in `state.py`) and its callers `yield from` it (`x = yield from f(s)`).
Requests are answered by the driver through `send`:

| Event | Answer | Where |
| --- | --- | --- |
| `ReadKey()` | the next key code | the line editor (stage 3 WaitKey's results) |
| `ReadR()` | the R register | the (re)start (the random seed) |
| `Mixed()` | the random routine's mixed value | RandomSigned at RandomSigned_Mixed (stage 3 `zx.take`) |
| `TapeLoad()` | a saved state or None (no tape: wait forever) | LOAD |
| `WaitKey()`, `ScrollPause()`, `Show(s)`, `Printed(text)`, `TapeSave()`, `Step()` | None | waits, pauses, the printer, SAVE, the top of the main loop |

Every stage 3 IN that waits (a picture, PAUSE, the end of a game, the scroll
pause) becomes a `WaitKey` or `ScrollPause`; key reads through the line editor
become `ReadKey`. A stage 3 `raise Goto(Target)` is a return value: the
routine returns `'Target'` (`'RestartGame'`), and the flow goes on there.

## Interfaces between slices

Wave A writes these first; wave B calls them (read wave A's code for the
rest). Signatures are fixed here:

- `terminal.put_char(s, ch)` — generator: print character code `ch` in the
  story window or, with `s.vars.raw_output`, the input window, as PrintChar
  does (lisp, line ends, the printer copy, scrolling and its pause).
  `terminal.new_line(s)` — generator: PrintNewLine.
- `text.print_message(s, name, args=None)` — generator: print the message
  `name` as PrintMessage does (`s.vars.action_perform`, `raw_output`, the
  saved flags). `args` is the message argument stack (a list): where the asm
  pushes values before printing, the caller appends them in the same order;
  control codes 0, 1, 4 and 19 pop from its end.
- `text.print_word(s, word, mode)` — generator: one dictionary word in a
  print mode (PrintWord).
- `world.thing(s, id)` — the Thing with that id; `world.location(s, id)`.
- `world.random_up_to(s, n)` and `world.random_signed(s, n)` — generators
  (they yield `Mixed`): RandomUpTo and RandomSigned with their quirks.
- `world.commit_or_abort(s)` — returns False when the asm pops its caller's
  return address (the caller returns at once); True otherwise. The same for
  `engine.abort_unless_perform(s)`.

## Assets

`game/assets/` (never committed: game data) is written once by
`bridge/assets.py` (`make game/assets/state.json`) from the original's image
and kept after that (edits survive; `--force` rewrites). Each slice adds the
extraction of its own data to `bridge/assets_<slice>.py` (called by
`bridge/assets.py`) and its loading to its module, through
`game/hobbit/assets.py` (json, text and PNG helpers, checks as they load):

| File | Slice | What |
| --- | --- | --- |
| `state.json` | lead | the state at the start (decoded from `port/image.bin`), the NPC program included |
| `tables.json` | lead | verb handlers, arrival handlers, behaviour tables, random events, blocked exits, hints, first-visit scores, the other small tables |
| `title.png` | lead | the title screen (the loading screen) |
| `dictionary.json`, `commands.json`, `messages.json` | text | the words, the command table, the messages in a form a person can edit |
| `font.png` | text | the story window's font (96 glyphs, 6 pixels used of 8) |
| `pictures/NN.txt`, `pictures/NN.png` | world | the 22 pictures as commands (loaded) and previews (not loaded) |

## Checks

- Per routine, while porting: `bridge/routines_<module>.py` maps the stage 3
  routine name to `(clean, convert_in, convert_out)`; `convert_in(regs)`
  turns the stage 3 registers before the call (a `routines.Regs`: `regs.a`,
  `regs.hl`, `regs.zf`...) into the clean arguments, `convert_out(regs)` the
  registers after it into the clean result (`routines.ANY`: not compared).
  Run `python3 bridge/oracle.py routine Name [--max=N] build/record/*.rec`
  (one routine per command while iterating; `--max=200` keeps it fast). The
  check runs clean on the decoded state before every call, answers its
  requests with the inputs stage 3 took in the call, and compares the decoded
  state after (the screen included) and the result.
- The game (the lead, after integration): `python3 bridge/oracle.py game
  build/record/*.rec`, pass by pass.
