; Room names: strings 0-24 of the text table, one per room
;
; The text table (RoomNames to 93D2, 53 strings) is a sequence of strings, each
; a length byte followed by that many characters (ASCII, drawn with the
; proportional font at FontIndex). FindString finds string number N by stepping
; over N strings from here. The string numbers: 0-24 the names of rooms 0-24
; (this entry), 25-36 the parchment texts (ParchmentTexts), 37 "Game Over"
; (GameOverText), 38-42 the intro (IntroText), 43-45 Satan's words (SatanText),
; 46-48 the "Heresy" message (HeresyText) and 49-52 the ending text
; (EndingText).
;
; String N is the name of room N: the room script (op $87, RoomNameString) puts
; it in the name panel at the bottom right of the screen. Rooms 0 and 4 have no
; name panel; their strings ":)" and ":$" are never shown (Unknown: they look
; like placeholders). Room 0 is the title and intro screen, room 4 the setting
; of the second part of the ending. The game's spelling is kept: room 15 is
; "Gloomy tunels".
RoomNames:
  DEFM $02,":)"           ; room 0
  DEFM $10,"A prayer of Hope" ; room 1
  DEFM $11,"Tower of the Bell" ; room 2
  DEFM $0D,"Wine supplies" ; room 3
  DEFM $02,":$"           ; room 4
  DEFM $0A,"Escape !!!"   ; room 5
  DEFM $0E,"Death is close" ; room 6
  DEFM $10,"Abandoned church" ; room 7
  DEFM $09,"The Altar"    ; room 8
  DEFM $0C,"Hangman tree" ; room 9
  DEFM $0F,"Pestilent Beast" ; room 10
  DEFM $11,"Cave of illusions" ; room 11
  DEFM $0D,"Plagued ruins" ; room 12
  DEFM $09,"Catacombs"    ; room 13
  DEFM $0D,"Hidden garden" ; room 14
  DEFM $0D,"Gloomy tunels" ; room 15
  DEFM $0F,"Lake of despair" ; room 16
  DEFM $12,"The wheel of faith" ; room 17
  DEFM $10,"Banquet of Death" ; room 18
  DEFM $11,"Underground river" ; room 19
  DEFM $0F,"Unexpected gate" ; room 20
  DEFM $0B,"Evil church"  ; room 21
  DEFM $0E,"Tortured souls" ; room 22
  DEFM $0E,"Ashes to ashes" ; room 23
  DEFM $09,"Satan !!!"    ; room 24

; Parchment texts: strings 25-36, two lines for each of the six parchments
;
; A parchment (room item type 5, RoomItems) names its two lines by string
; number; the text is shown by ShowParchment in the parchment frame when Jean
; touches the item (the item action ActionParchment copies the numbers to
; ParchmentLine1). The pairs: 25-26 room 3 (Wine supplies), 27-28 room 8 (The
; Altar), 29-30 room 12 (Plagued ruins), 31-32 room 14 (Hidden garden), 33-34
; room 16 (Lake of despair), 35-36 room 21 (Evil church). The first parchment
; says to collect twelve crosses; the others are hints about the abbey.
ParchmentTexts:
  DEFM $0E,"Twelve crosses" ; string 25
  DEFM $11,"against the devil" ; string 26
  DEFM $0F,"Twelve brothers" ; string 27
  DEFM $11,"hid and died here" ; string 28
  DEFM $0D,"Four brothers" ; string 29
  DEFM $13,"changed their faith" ; string 30
  DEFM $11,"An invisible path" ; string 31
  DEFM $12,"over a wood bridge" ; string 32
  DEFM $0D,"Jump to death" ; string 33
  DEFM $14,"and prove your faith" ; string 34
  DEFM $0D,"Glide through" ; string 35
  DEFM $0E,"the beast cage" ; string 36

; Game Over text: string 37
;
; Printed by the Game Over screen script (ScriptGameOver), with spaces between
; the letters (and two between the words).
GameOverText:
  DEFM $10,"G a m e  O v e r" ; string 37

; Intro text: strings 38-42, shown on the intro screen of room 0
;
; The Cathar story, printed by the script of room 0 (RoomScript00): strings
; 38-40 (the Cathars expelled from the Languedoc by the Catholic Church) at the
; top of the screen and 41-42 (Jean Raymond runs to escape the crusaders) at
; the bottom. The game's text spells it "Lanquedoc".
IntroText:
  DEFM $1E,"13th Century. The Cathars were" ; string 38
  DEFM $1E,"being expelled by the Catholic" ; string 39
  DEFM $1B,"Church out of the Lanquedoc" ; string 40
  DEFM $17,"The Cathar Jean Raymond" ; string 41
  DEFM $1F,"runs to escape the crusaders..." ; string 42

; Satan's words: strings 43-45
;
; The first screen of the ending sequence (RunEnding): white text on black,
; printed centred by the script ScriptEnding1: "your doom will come / not by my
; hand / but by human hands".
SatanText:
  DEFM $13,"your doom will come" ; string 43
  DEFM $0E,"not by my hand" ; string 44
  DEFM $12,"but by human hands" ; string 45

; The "Heresy" message: strings 46-48
;
; The second screen of the ending sequence, printed centred by the script
; ScriptEnding2 before the second part of the ending (room 25): "Heresy!!! The
; Cathar is hidden on the throne of Satan, burn him".
HeresyText:
  DEFM $14,"Heresy!!! The Cathar" ; string 46
  DEFM $17,"is hidden on the throne" ; string 47
  DEFM $12,"of Satan, burn him" ; string 48

; Ending text: strings 49-52
;
; The last screen of the game, printed by the script ScriptEnding3: Jean's body
; has burned in the flames, but his soul has found a place in Heaven.
EndingText:
  DEFM $14,"Your body has burned" ; string 49
  DEFM $0E,"in the flames," ; string 50
  DEFM $17,"but your soul has found" ; string 51
  DEFM $12,"a place in Heaven." ; string 52
