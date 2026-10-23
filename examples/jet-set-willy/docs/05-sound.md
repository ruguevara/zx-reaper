# 5.7 Sound

All sound is the beeper, driven by busy-wait loops that toggle bits 3 and 4
of port $FE ([BEEPER_BITS](../src/constants.asm#L10) = $18, speaker and MIC together). The other
bits written are the border colour, so every sound routine first loads the
room's border colour (or black) into A and toggles only the sound bits.
Nothing runs in the background: while a sound plays, the game stops.

| Sound | Routine | Form |
| --- | --- | --- |
| title tune | [PlayTune](../src/output.asm#L154) | 99 notes of ~0.29 s, each dropping an octave halfway |
| in-game tune | [PlayGameTune](../src/mainloop.asm#L352) | one 9 ms blip per pass, one note per 2 passes |
| scroll sweep | [PlaySweepSound](../src/output.asm#L230) | one pulse moving along a burst, per scroll step |
| jump click | [MoveWilly](../src/willy.asm#L78) | 32 toggles, pitch from the distance to the apex |
| fall click | [MoveWilly_Air](../src/willy.asm#L158) | 32 toggles, delay = state * 16 |
| item beep | [UpdateItems](../src/items.asm#L33) | 64 half-periods, delay $10 rising to $8E |
| arrow warning | [DrawEntities_ArrowBeep](../src/entities.asm#L330) | 128 toggles, delay falling from 128 loop passes: a rising chirp |
| death buzz | [PlayDeath](../src/mainloop.asm#L456) | 8 rounds, falling pitch, fewer toggles each round |
| game-over whistle | [ShowGameOver](../src/mainloop.asm#L506) | 49 x 64 toggles, delay $FF - counter |

## Tunes

A note byte is a half-period: the number of inner loop passes between two
toggles of the speaker (larger = lower). [PlayTune](../src/output.asm#L154) plays each note for
100 x 256 passes of its inner loop with a fixed length, so there are no
rests or durations in the data; halfway through (outer count 50) it doubles
the half-period, so the second half of every note is an octave lower (F44,
inferred from the code, not listened to). After each note it calls
[ReadStartInput](../src/output.asm#L196), which ends the tune on a start key. The title tune
lasts about 29 s (F73).

The first half of a note sounds at about 3.5 MHz / (2 * (40 * E + 6)) Hz
for a note byte E (computed in the source comments: $51 = 539 Hz, $3C = 727
Hz, $33 = 855 Hz). [TitleTune](../src/variables.asm#L557) is written as 33 groups of three notes (a
low note and two higher ones). The comments in
[`src/variables.asm`](../src/variables.asm) list the computed note names;
what tune it is cannot be told from the bytes (Unknown).

[GameTune](../src/variables.asm#L610) has 64 notes and no end marker. [PlayGameTune](../src/mainloop.asm#L352) picks note
(TuneStep AND $7E) / 2, so a note lasts two passes and the tune 128 passes,
and plays it for 3 x 256 inner passes: 768 port writes, about 9 ms. The
half-period used is note + 28 - 4 * [LivesLeft](../src/variables.asm#L190), so the tune is lower the
fewer lives are left (observed: $48, $50, $60 for one note at 7, 5 and 1
lives, F74). The tune is a series of short blips because the game can only
make sound between its other work; the tune costs about 31,000 T per pass,
12% of the pass (F93).

## Effects

**Jump and fall clicks.** Each pass of a jump plays 32 toggles with a delay
of (|step - 8| + 1) * 8 loop passes, highest at the apex; each pass of a
fall 32 toggles with a delay of state * 16, lower as the fall gets longer.

**Item beep.** 64 half-periods with C counting $80, $7E, ... 2 and a delay
of $90 - C: a short falling note.

**Arrow warning.** When an arrow's X reaches $2C or $F4, the pass plays 128
toggles; the first delay is 2 loop passes, then the delay is a falling
counter (128, 127 ... 2): half-periods falling from 1697 T to 72 T, a chirp rising from about
1 kHz, about 32 ms in all (observed in an I/O log, F85). It is heard 12 or
13 passes before the arrow appears.

**Scroll sweep.** [PlaySweepSound](../src/output.asm#L230) makes A passes; in each, one of E port
writes (where the counter equals N) has the sound bits set, so a single
pulse moves step by step through the burst. The other bits are the counter,
so the border flickers. The start value is (scroll offset AND $1F) + $32.

**Death buzz and game-over whistle.** See [Death](05-death.md).

No sound routine reads the keyboard except [PlayTune](../src/output.asm#L154) (through
[ReadStartInput](../src/output.asm#L196)).
