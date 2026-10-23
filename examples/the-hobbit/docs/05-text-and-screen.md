# 5b. Text: the message printer and the two windows

All text the game prints comes from a 177-message bytecode and the
562-word dictionary the parser also uses. One message serves every actor: the
printer fills in names, chooses "you are" or "Gandalf is" and adds verb
endings. The text goes to one of two windows: a 42-column story window with
the game's own narrow font, which scrolls over the picture, and a 32-column
input window at the bottom in the ROM font.

## The screen

| Character rows | Window | Font | Routines |
| --- | --- | --- | --- |
| 0-15 | picture area (shared with the story window) | | [05-pictures](05-pictures.md) |
| 0-17 | story window: 42 characters of 6 pixels per line, scrolls up, text appears on row 17 | [Font](../src/screen.asm#L660) at `$8822` | [OutputStoryChar](../src/screen.asm#L349), [PrintStoryChar](../src/screen.asm#L580), [ScrollStoryUp](../src/screen.asm#L495) |
| 18 | a decorative rule ([BorderTile](../src/main.asm#L299)) | | [RestartGame](../src/main.asm#L81) |
| 19-23 | input window: 32 columns, capitals only, cursor `+` | ROM `$3D00` | [PrintToInput](../src/screen.asm#L105), [PrintInputChar](../src/screen.asm#L270), [ScrollInputUp](../src/screen.asm#L164), [ScrollInputDown](../src/screen.asm#L220) |

The story window scrolls rows 1-17 up by one character row, bitmap **and**
attributes ([ScrollStoryUp](../src/screen.asm#L495), F22), so a picture drawn in rows 0-15 slides up
and off the top as the description is printed below it. The input window
holds the typed lines and the parser's replies ("WHAT ?", "YOU CANNOT ..."),
so the dialogue with the parser stays apart from the story.

Characters are 6 pixels wide in the story window, so a character usually
straddles two screen cells: the cursor is a cell address plus a pixel offset
(0-7), and [PrintStoryChar](../src/screen.asm#L580) shifts each of the 8 glyph rows into place. The
font has 96 glyphs of 8x8 pixels, drawn in the right 6 columns' width (sheet
in [07-graphics](07-graphics.md)).

### Where a character goes ([PrintChar](../src/screen.asm#L48))

Every character the game prints passes through [PrintChar](../src/screen.asm#L48):

1. [OutputEnabled](../src/screen.asm#L11): nothing is printed unless [ActionPerform](../src/world.asm#L33) and
   [MessagesVisible](../src/world.asm#L47) are both set. This one test hides the test pass of
   every command (ActionPerform 0) and what characters do out of the player's
   sight (MessagesVisible 0).
2. [RawOutputFlag](../src/world.asm#L45) chooses the window: the input window for the editor's
   echo and the parser's replies, the story window for the rest.
3. In the story window, with [LispFlag](../src/world.asm#L43) set, every `S` or `s` is followed by
   an `h`: after drinking the wine the player lisps for five turns
   ([05-time](05-time.md)).

### The story window ([OutputStoryChar](../src/screen.asm#L349))

- Capitals: letters are printed in lower case; [CapitalNext](../src/world.asm#L51) makes the next
  letter a capital. It is set after a full stop, at the start of a line, for
  a proper name and for print mode 7 (F28).
- Word wrap: [PrintWord](../src/printer.asm#L742) breaks the line before a word that would not fit
  in the 42 columns (a word longer than the rest of the line moves to the next
  one).
- At each line end the line is copied to the ZX printer when PRINT is on
  ([PrintStoryLine](../src/devices.asm#L15)) and the window scrolls. Before the scroll comes a pause
  of `SCROLL_DELAY` keyboard polls (about half a second) so that the text can
  be read; a key held down stops the scrolling until it is released. The first
  9 lines after each typed line, and 17 after a start, scroll without the pause
  ([NoPauseLines](../src/world.asm#L88), F35).
- [ListIndent](../src/screen.asm#L313) indents the lines of an object list: 4 spaces for the things
  here, 2 more for the contents of each (F33).

## The message bytecode ([PrintMessage](../src/printer.asm#L112))

A message is a list of items read until an ending item. Messages lie back to
back from `$AD7D` to `$B6D9` (verified, F2).

| Item | Bytes | Meaning |
| --- | --- | --- |
| `$20-$5F` | 1 | the character itself (printed in lower case unless a capital is due) |
| `$60-$7F` | 1 | common word *n*-`$60` of [CommonWordTable](../src/commands.asm#L103): a, and, are, at, be, blow, but, cannot, carrying, do, door, dragon, fall, from, here, i, in, is, it, not, of, on, see, some, the, there, this, to, too, what, with, you |
| `$80-$FF` | 2 | dictionary word: offset in bits 0-11, print mode in bits 12-14 |
| `$00-$13` | 1-2 | control code, a routine from [ControlCodeTable](../src/printer.asm#L8) |
| `$14` | 1 | end, new line |
| `$15` | 1 | end, full stop and new line |
| `$16` | 1 | end |

Print modes of a dictionary word ([PrintWord](../src/printer.asm#L742)):

| Mode | Effect |
| --- | --- |
| 0, 2, 3, 6, 7 | verb ending added when the subject is not the player: "Gandalf take**s**", "you take" |
| 1 | ending added when the first object is not the player |
| 4 | ending always ("place**d**") |
| 5 | no ending |
| 2, 3, 6 | the word ends the message: nothing more, a full stop and new line, a new line |
| 7 | the word starts with a capital |

The endings are the six of [WordEndings](../src/world.asm#L109) (`s`, `es`, `ies`, back-space +
`ies`, `d`, `ing`), chosen by the dictionary entry. Each word is preceded by a
space unless it starts a line.

Control codes:

| Code | Prints | Routine |
| --- | --- | --- |
| 0 | a name phrase passed on the stack by the caller | [PrintStackedName](../src/printer.asm#L243) |
| 1, 4 | a word token from the stack, without / with its article | [PrintStackedWord](../src/printer.asm#L266), [PrintStackedWordArticle](../src/printer.asm#L317) |
| 2 | jump: continue at this byte + a signed offset | [MessageJump](../src/printer.asm#L288) |
| 3 | the word at [TargetNamePtr](../src/world.asm#L37) (the weapon in a fight) | [L738D](../src/printer.asm#L301) |
| 6 | the subject's name ("you", "Thorin") | [PrintSubjectName](../src/printer.asm#L340) |
| 7, 9 | the first / second object with its article ("the curious map") | [PrintFirstObjectName](../src/printer.asm#L364), [PrintSecondObjectName](../src/printer.asm#L397) |
| 8 | back-space | [L73BD](../src/printer.asm#L376) |
| 11 | call: print the message at this byte + offset, then go on | [MessageCall](../src/printer.asm#L433) |
| 12, 14 | "his" or "your" for the subject / the first object | [L73F9](../src/printer.asm#L452), [HisYourFirstObject](../src/printer.asm#L482) |
| 13 | new line | [PrintMessageChar](../src/printer.asm#L42) |
| 16, 17, 19 | name and "is" or "are": subject, first object, a name from the stack | [PrintSubjectIs](../src/printer.asm#L500), [L7425](../src/printer.asm#L520), [PrintNameIsFromStack](../src/printer.asm#L554) |
| 5, 10, 15, 18 | nothing | |

Example: [MsgDead](../src/messages.asm#L349) is three bytes, `$10 $B1 $92`: code 16 (the subject and
"is"/"are") and the word `dead` in mode 3 (full stop, new line). It prints
"You are dead." or "Thorin is dead.". [MsgWithOneWellPlacedBlow](../src/messages.asm#L142) is 15
bytes for "With one well placed blow you cleave his skull." / "...Thorin
cleaves your skull.".

The jump and call codes let messages share tails: many messages end by
jumping into the middle of another. Altogether the 177 messages hold about
6800 characters of text in 2397 bytes, plus the dictionary, which the parser
needs anyway.

### Articles and names

[PrintArticle](../src/printer.asm#L593) chooses "the", "a", "an" or "some" for a noun from its
phrase code; proper names get none and a capital. In a command echoed as a
sentence ([PrintCommandSentence](../src/keys.asm#L570)) the article is always "the" or "some"
([ArticleTableInput](../src/commands.asm#L95), F29). Location and object names are printed from their
three phrase codes, adjectives first ([PrintNamePhrase](../src/objects.asm#L943)).

### Self-changing messages

[MsgSubjIsIn](../src/messages.asm#L357) ("You are in") is patched before each location description:
[DescribeLocation](../src/engine.asm#L282) writes the location's preposition (in, on, at, inside,
outside) into the message's second item, and [VerbLook](../src/verbs.asm#L15) blanks it to print
"You are in the barrel" with the holder's own relation word. The troll
clearing's description pointer is replaced at dawn ([06-tricks](06-tricks.md)).

## Hardware notes

- The story window writes the bitmap only; the attributes it scrolls are those
  of the picture and of [ClearScreen](../src/keys.asm#L381) (black on white).
- The input window uses the ROM font at `$3D00` and does not touch the
  attributes.
- No routine uses the ROM's print or the system variables of the ROM's
  screen output.
