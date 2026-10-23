; Title screen caption
;
; The two caption lines of the title screen, printed one character at a time by
; Start with PrintChar from the screen address $50C0 (character row 22, column
; 0) in the ROM font: the 63 characters fill row 22 and run on into row 23. The
; first line reads " Copyright (c) 1982 Beam Software" and the second "PRESS
; ANY KEY TO START PLAY" (the copyright sign is character $7F of the ROM font).
;
; Format: plain ASCII characters, terminated by $FF (the print loop in Start
; stops at $FF).
TitleText:
  DEFM " Copyright "
  DEFB $7F
  DEFM " 1982 Beam Software   PRESS ANY KEY TO START PLAY  "
  DEFB $FF

; Demo mode banner
;
; The banner shown in the top character row (screen address $4000, 32
; characters) while the demonstration game is running: "DEMO MODE  PRESS ANY
; KEY TO PLAY". Printed by Start with PrintChar in place of the status line
; (StatusText); the first nine attribute cells ("DEMO MODE") are then set to
; flash.
;
; Format: plain ASCII characters, terminated by $FF.
DemoText:
  DEFM "DEMO MODE  PRESS ANY KEY TO PLAY"
  DEFB $FF

; Title screen countdown (word)
;
; Counts the passes of the title-screen loop in Start that remain before the
; demo starts. Start sets it to 140 ($008C) when the title screen is drawn and
; decrements it once per pass of the colour-cycling loop (each pass takes about
; 4 frames: the rising tone of PlayRisingTone is the delay). When it reaches 0
; the demo starts, with GameActive left at 0; a key pressed before that sets
; GameActive to 1 and starts a real game at once. Not used outside the title
; loop; the loaded value 0 is never read.
TitleCountdown:
  DEFW $0000

; Number of guards released (byte)
;
; Meant to be the count of guards that have left their start, used by
; PaceAndChime to shorten the delay of the main loop as more guards are out. It
; is cleared to 0 by ResetGuardTimers (at the start of a game and whenever
; Horace has lost a life) and incremented by TickGuardTimers. The increment is
; guarded by OR C, with C left over from the caller, so it only fires when C is
; 0: that happens after Horace has taken the bell (UpdateBell leaves BC = 0
; when the bell position BellPos is 0). Then the value counts 1, 2 ... 255, 0
; during the last 256 ticks of each waiting guard's timer and ends at 0 again.
; While the bell is lying in the maze (C = $3A) the byte stays 0 (verified in
; the simulator: no change in 6000 frames of demo, 256 increments after the
; bell was taken).
GuardsReleased:
  DEFB $00

; Game mode flag: 0 title or demo, 1 real game (byte)
;
; 0 while the title screen is shown and during the demo; 1 once the player has
; pressed a key at the title screen and a real game is played. Set to 0 by
; Start when the title screen is drawn, and to 1 at $60C4 when a key is pressed
; before the countdown TitleCountdown runs out. Start briefly sets it to 1 to
; print the title texts and the "DEMO MODE" banner and restores the old value.
;
; Readers: PrintChar (PrintChar, and through it PrintNumber and PrintDigit)
; draws only when bit 0 is set, so the status line and score are not printed in
; the demo; ReadControls reads the keyboard when it is non-zero and runs the
; autopilot when it is zero; HoraceDies (death) restarts the same maze in a
; real game (JP $61AA) but goes on to the next one in the demo, and updates the
; best score (BestScore) at game over only in a real game.
GameActive:
  DEFB $00
