; Current maze descriptor (4 words)
;
; The descriptor of the maze being played, copied by LoadMazeDescriptor
; (LoadMazeDescriptor) from one of Maze1Desc, Maze2Desc, Maze3Desc, Maze4Desc
; when Start starts a maze (the loaded contents equal Maze2Desc and are
; replaced at the first maze). Positions are screen offsets (address minus
; $4000) of the top-left cell of a 2x2 block.
;
; Fields: +0 word: vertical wrap delta (this word has the label
; MazeDescriptor), added to a position that goes up through a wrap pad and
; subtracted when going down (PlanMoves for Horace, ChooseGuardMove for
; guards); a screen offset difference +2 word: position of the bell at the
; start of the maze (MazeBellStart); copied to the bell position BellPos when a
; maze starts and used again by UpdateBell when the bell is picked up +4 word:
; start position of guard 1 (MazeGuardStart), used by Start for the guard whose
; release timer is 0 when a maze starts or Horace has lost a life +6 word:
; start position of Horace (MazeHoraceStart), also the start of the guards
; whose timers are still running and the place eaten guards go back to
; (CheckGuardContact)
MazeDescriptor:
  DEFW $1060
MazeBellStart:
  DEFW $00FC
MazeGuardStart:
  DEFW $1010
MazeHoraceStart:
  DEFW $0841

; Maze 1 descriptor (4 words)
;
; Maze 1 descriptor: four words giving the maze's wrap delta and its starting
; positions (8 bytes, MAZE_DESC_SIZE). The maze is selected by the maze number
; 0 in MazeNumber (numbers run 0 to 3 and repeat, the game starts with maze 0),
; and the descriptor is copied by LoadMazeDescriptor to the current maze
; descriptor MazeDescriptor when Start starts the maze. It goes with the map
; Maze1Map (Maze1Map); the four descriptors are at Maze1Desc, Maze2Desc,
; Maze3Desc and Maze4Desc but their maps are not in the same order in memory.
;
; Fields: +0 word: vertical wrap delta, added to the position of Horace or a
; guard that goes up through a wrap pad (tile 9 of the map) and subtracted when
; going down: a screen-offset difference (PlanMoves, ChooseGuardMove); 0 when
; the maze has no wrap pads +2 word: position of the bell at the start of the
; maze (copied to BellPos; 0 there means no bell) +4 word: position of the
; first guard when its release timer is zero (guard 1 at the start of a maze)
; +6 word: position of Horace's start, at the left-hand arrows; a guard whose
; release timer is not zero waits here too Positions are screen offsets
; (address minus $4000) of the top-left cell of a 2x2-cell block: THIRD_SIZE
; per screen third of 8 character rows, CELL_ROW_STEP per row inside a third,
; plus the column.
Maze1Desc:
  DEFW -THIRD_SIZE        ; wrap delta: -8 character rows
  DEFW THIRD_SIZE*$0002+CELL_ROW_STEP*$0003+$000A ; bell: row 19, column 10
  DEFW THIRD_SIZE+CELL_ROW_STEP*$0004+$0015 ; guard 1 start: row 12, column 21
  DEFW THIRD_SIZE+CELL_ROW_STEP*$0005+$0001 ; Horace start: row 13, column 1

; Maze 2 descriptor (4 words)
;
; Maze 2 descriptor: four words giving the maze's wrap delta and its starting
; positions (8 bytes, MAZE_DESC_SIZE). The maze is selected by the maze number
; 1 in MazeNumber (numbers run 0 to 3 and repeat, the game starts with maze 0),
; and the descriptor is copied by LoadMazeDescriptor to the current maze
; descriptor MazeDescriptor when Start starts the maze. It goes with the map
; Maze2Map (Maze2Map); the four descriptors are at Maze1Desc, Maze2Desc,
; Maze3Desc and Maze4Desc but their maps are not in the same order in memory.
;
; Fields: +0 word: vertical wrap delta, added to the position of Horace or a
; guard that goes up through a wrap pad (tile 9 of the map) and subtracted when
; going down: a screen-offset difference (PlanMoves, ChooseGuardMove); 0 when
; the maze has no wrap pads +2 word: position of the bell at the start of the
; maze (copied to BellPos; 0 there means no bell) +4 word: position of the
; first guard when its release timer is zero (guard 1 at the start of a maze)
; +6 word: position of Horace's start, at the left-hand arrows; a guard whose
; release timer is not zero waits here too Positions are screen offsets
; (address minus $4000) of the top-left cell of a 2x2-cell block: THIRD_SIZE
; per screen third of 8 character rows, CELL_ROW_STEP per row inside a third,
; plus the column.
Maze2Desc:
  DEFW THIRD_SIZE*$0002+CELL_ROW_STEP*$0003 ; wrap delta: 19 character rows
  DEFW CELL_ROW_STEP*$0007+$001C ; bell: row 7, column 28
  DEFW THIRD_SIZE*$0002+$0010 ; guard 1 start: row 16, column 16
  DEFW THIRD_SIZE+CELL_ROW_STEP*$0002+$0001 ; Horace start: row 10, column 1

; Maze 3 descriptor (4 words)
;
; Maze 3 descriptor: four words giving the maze's wrap delta and its starting
; positions (8 bytes, MAZE_DESC_SIZE). The maze is selected by the maze number
; 2 in MazeNumber (numbers run 0 to 3 and repeat, the game starts with maze 0),
; and the descriptor is copied by LoadMazeDescriptor to the current maze
; descriptor MazeDescriptor when Start starts the maze. It goes with the map
; Maze3Map (Maze3Map); the four descriptors are at Maze1Desc, Maze2Desc,
; Maze3Desc and Maze4Desc but their maps are not in the same order in memory.
;
; Fields: +0 word: vertical wrap delta, added to the position of Horace or a
; guard that goes up through a wrap pad (tile 9 of the map) and subtracted when
; going down: a screen-offset difference (PlanMoves, ChooseGuardMove); 0 when
; the maze has no wrap pads +2 word: position of the bell at the start of the
; maze (copied to BellPos; 0 there means no bell) +4 word: position of the
; first guard when its release timer is zero (guard 1 at the start of a maze)
; +6 word: position of Horace's start, at the left-hand arrows; a guard whose
; release timer is not zero waits here too Positions are screen offsets
; (address minus $4000) of the top-left cell of a 2x2-cell block: THIRD_SIZE
; per screen third of 8 character rows, CELL_ROW_STEP per row inside a third,
; plus the column.
Maze3Desc:
  DEFW $0000              ; wrap delta: 0: this maze has no wrap pads
  DEFW CELL_ROW_STEP*$0005+$001D ; bell: row 5, column 29
  DEFW THIRD_SIZE+CELL_ROW_STEP+$000C ; guard 1 start: row 9, column 12
  DEFW THIRD_SIZE*$0002+CELL_ROW_STEP*$0005+$0001 ; Horace start: row 21,
                                                  ; column 1

; Maze 4 descriptor (4 words)
;
; Maze 4 descriptor: four words giving the maze's wrap delta and its starting
; positions (8 bytes, MAZE_DESC_SIZE). The maze is selected by the maze number
; 3 in MazeNumber (numbers run 0 to 3 and repeat, the game starts with maze 0),
; and the descriptor is copied by LoadMazeDescriptor to the current maze
; descriptor MazeDescriptor when Start starts the maze. It goes with the map
; Maze4Map (Maze4Map); the four descriptors are at Maze1Desc, Maze2Desc,
; Maze3Desc and Maze4Desc but their maps are not in the same order in memory.
;
; Fields: +0 word: vertical wrap delta, added to the position of Horace or a
; guard that goes up through a wrap pad (tile 9 of the map) and subtracted when
; going down: a screen-offset difference (PlanMoves, ChooseGuardMove); 0 when
; the maze has no wrap pads +2 word: position of the bell at the start of the
; maze (copied to BellPos; 0 there means no bell) +4 word: position of the
; first guard when its release timer is zero (guard 1 at the start of a maze)
; +6 word: position of Horace's start, at the left-hand arrows; a guard whose
; release timer is not zero waits here too Positions are screen offsets
; (address minus $4000) of the top-left cell of a 2x2-cell block: THIRD_SIZE
; per screen third of 8 character rows, CELL_ROW_STEP per row inside a third,
; plus the column.
Maze4Desc:
  DEFW THIRD_SIZE*$0002-CELL_ROW_STEP ; wrap delta: 15 character rows
  DEFW CELL_ROW_STEP*$0003+$001D ; bell: row 3, column 29
  DEFW THIRD_SIZE+CELL_ROW_STEP*$0003+$000F ; guard 1 start: row 11, column 15
  DEFW CELL_ROW_STEP*$0003+$0001 ; Horace start: row 3, column 1

; Maze 2 map (24 x 32 tile codes)
;
; Maze 2 map, the second maze (maze number 1). Map of tile codes, 24 rows of 32
; columns, one byte per character cell, row by row (768 bytes = SCREEN_ROWS x
; SCREEN_COLS). DrawMaze (DrawMaze) draws the whole map from the top-left of
; the screen; row 0 is empty in every maze and is overwritten by the status
; line (StatusText) or the demo banner (DemoText). Tile codes (the graphics are
; the 8-byte entries of TileGraphics, index = code): 0 empty floor
; (TILE_EMPTY), drawn yellow-on-white; this is where Horace and the guards walk
; 1 horizontal wall (two parallel lines) 2 flower (TILE_FLOWER), green; worth
; 10 points 3 arrow pointing right (TILE_ARROW), black; the left-hand arrows
; are where Horace enters (he cannot move into them again), the right-hand ones
; are the exit to the next maze 4 vertical wall (two parallel lines) 5 wall
; corner, top-left; 6 top-right; 7 bottom-left; 8 bottom-right (all walls are
; cyan) 9 wrap pad (TILE_BLANK_WHITE): a blank cell drawn white on white, so
; invisible; going up or down into it moves the walker by the vertical wrap
; delta of the maze descriptor (MazeDescriptor) After drawing, the game never
; reads the map again: walls, flowers and arrows are recognised from the screen
; attributes ($3D, $3C, $38; ProbeMove).
;
; Occupies rows 1-23. Entrance arrows in column 0, rows 10-11, where Horace
; starts; exit arrows in column 30, rows 10-11. Wrap pads (tile 9) at the top
; and bottom of the central corridor: row 1 and row 23, columns 13-14. 55
; flowers. Its descriptor is Maze2Desc (Maze2Desc). Start selects the map by
; the maze number in MazeNumber and draws it with DrawMaze. The four maps are
; not stored in game order: this one is maze number 1.
Maze2Map:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$09,$09,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $05,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$04,$00,$00,$04,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$06,$00
  DEFB $04,$00,$02,$00,$00,$02,$00,$00,$02,$00,$00,$02,$04,$00,$00,$04,$00,$02,$00,$00,$02,$00,$00,$02,$00,$00,$02,$00,$00,$02,$04,$00
  DEFB $04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00
  DEFB $04,$00,$00,$05,$01,$01,$01,$01,$01,$01,$00,$00,$04,$00,$00,$04,$00,$00,$04,$00,$00,$04,$00,$00,$01,$01,$01,$01,$00,$00,$04,$00
  DEFB $04,$00,$02,$04,$00,$02,$00,$00,$02,$00,$00,$02,$00,$00,$02,$00,$00,$02,$04,$00,$02,$04,$00,$02,$00,$00,$02,$00,$00,$00,$04,$00
  DEFB $04,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00
  DEFB $04,$00,$00,$04,$00,$00,$05,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$00,$04,$00,$00,$07,$01,$01,$01,$01,$01,$01,$01,$01,$08,$00
  DEFB $03,$00,$00,$04,$00,$02,$04,$00,$02,$00,$00,$02,$00,$00,$02,$00,$00,$02,$04,$00,$02,$00,$00,$02,$00,$00,$02,$00,$00,$00,$03,$00
  DEFB $03,$00,$00,$04,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$00
  DEFB $04,$00,$00,$04,$00,$00,$04,$00,$00,$05,$01,$01,$01,$01,$01,$01,$00,$00,$04,$00,$00,$01,$01,$01,$06,$00,$00,$04,$00,$00,$04,$00
  DEFB $04,$00,$02,$04,$00,$02,$04,$00,$02,$04,$00,$02,$00,$00,$02,$00,$00,$02,$04,$00,$02,$00,$00,$02,$04,$00,$02,$04,$00,$02,$04,$00
  DEFB $04,$00,$00,$04,$00,$00,$04,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$00,$00,$00,$04,$00,$00,$04,$00,$00,$04,$00
  DEFB $04,$00,$00,$04,$00,$00,$04,$00,$00,$04,$00,$00,$05,$01,$01,$01,$00,$00,$04,$00,$00,$04,$00,$00,$04,$00,$00,$04,$00,$00,$04,$00
  DEFB $04,$00,$02,$04,$00,$02,$00,$00,$02,$04,$00,$02,$04,$00,$02,$00,$00,$02,$00,$00,$02,$04,$00,$02,$00,$00,$02,$04,$00,$02,$04,$00
  DEFB $04,$00,$00,$04,$00,$00,$00,$00,$00,$04,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$00,$00,$00,$04,$00,$00,$04,$00
  DEFB $04,$00,$00,$07,$01,$01,$01,$01,$01,$08,$00,$00,$04,$00,$00,$04,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$08,$00,$00,$04,$00
  DEFB $04,$00,$02,$00,$00,$02,$00,$00,$02,$00,$00,$02,$04,$00,$00,$04,$00,$02,$00,$00,$02,$00,$00,$02,$00,$00,$02,$00,$00,$02,$04,$00
  DEFB $04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00
  DEFB $07,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$04,$00,$00,$04,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$08,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$09,$09,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; Maze 1 map (24 x 32 tile codes)
;
; Maze 1 map, the first maze of a game (maze number 0). Map of tile codes, 24
; rows of 32 columns, one byte per character cell, row by row (768 bytes =
; SCREEN_ROWS x SCREEN_COLS). DrawMaze (DrawMaze) draws the whole map from the
; top-left of the screen; row 0 is empty in every maze and is overwritten by
; the status line (StatusText) or the demo banner (DemoText). Tile codes (the
; graphics are the 8-byte entries of TileGraphics, index = code): 0 empty floor
; (TILE_EMPTY), drawn yellow-on-white; this is where Horace and the guards walk
; 1 horizontal wall (two parallel lines) 2 flower (TILE_FLOWER), green; worth
; 10 points 3 arrow pointing right (TILE_ARROW), black; the left-hand arrows
; are where Horace enters (he cannot move into them again), the right-hand ones
; are the exit to the next maze 4 vertical wall (two parallel lines) 5 wall
; corner, top-left; 6 top-right; 7 bottom-left; 8 bottom-right (all walls are
; cyan) 9 wrap pad (TILE_BLANK_WHITE): a blank cell drawn white on white, so
; invisible; going up or down into it moves the walker by the vertical wrap
; delta of the maze descriptor (MazeDescriptor) After drawing, the game never
; reads the map again: walls, flowers and arrows are recognised from the screen
; attributes ($3D, $3C, $38; ProbeMove).
;
; Occupies rows 3-21. Entrance arrows (tile 3) in column 0, rows 13-14, where
; Horace starts; exit arrows in column 30, rows 19-20. A single wrap pad pair
; (tile 9) at row 14, columns 16-17, in the middle of the maze. 44 flowers. Its
; descriptor is Maze1Desc (Maze1Desc). Start selects the map by the maze number
; in MazeNumber and draws it with DrawMaze. The four maps are not stored in
; game order: this one is maze number 0.
Maze1Map:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $05,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$06,$00
  DEFB $04,$00,$02,$00,$00,$02,$00,$00,$02,$04,$00,$02,$00,$00,$02,$00,$00,$02,$00,$00,$02,$04,$00,$02,$00,$00,$02,$00,$00,$02,$04,$00
  DEFB $04,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00
  DEFB $04,$00,$00,$05,$01,$01,$01,$00,$00,$04,$00,$00,$01,$01,$01,$01,$00,$00,$00,$00,$00,$04,$00,$00,$01,$01,$01,$06,$00,$00,$04,$00
  DEFB $04,$00,$02,$04,$00,$02,$00,$00,$02,$00,$00,$02,$00,$00,$02,$00,$00,$02,$00,$00,$02,$00,$00,$02,$00,$00,$02,$04,$00,$02,$04,$00
  DEFB $04,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$04,$00
  DEFB $04,$00,$00,$04,$00,$00,$05,$01,$01,$01,$01,$01,$01,$01,$01,$06,$00,$00,$05,$01,$01,$01,$01,$01,$06,$00,$00,$04,$00,$00,$04,$00
  DEFB $04,$00,$02,$04,$00,$02,$04,$00,$00,$00,$00,$00,$05,$01,$01,$01,$01,$01,$01,$01,$01,$06,$00,$00,$04,$00,$02,$00,$00,$02,$04,$00
  DEFB $04,$00,$00,$04,$00,$00,$04,$00,$00,$05,$01,$01,$08,$00,$00,$00,$00,$00,$00,$00,$00,$07,$01,$01,$04,$00,$00,$00,$00,$00,$04,$00
  DEFB $04,$00,$00,$04,$00,$00,$07,$01,$01,$08,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07,$01,$01,$01,$00,$00,$04,$00
  DEFB $03,$00,$00,$04,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$05,$01,$01,$06,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$04,$00
  DEFB $03,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$05,$01,$01,$08,$09,$09,$07,$01,$01,$06,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00
  DEFB $04,$00,$00,$04,$00,$00,$05,$01,$01,$01,$01,$01,$08,$00,$00,$00,$00,$00,$04,$00,$00,$07,$01,$01,$01,$01,$01,$01,$00,$00,$04,$00
  DEFB $04,$00,$02,$04,$00,$02,$04,$00,$02,$00,$00,$02,$00,$00,$02,$00,$00,$02,$04,$00,$02,$00,$00,$02,$00,$00,$02,$00,$00,$02,$04,$00
  DEFB $04,$00,$00,$04,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00
  DEFB $04,$00,$00,$04,$00,$00,$04,$00,$00,$05,$01,$01,$01,$01,$01,$01,$01,$01,$08,$00,$00,$04,$00,$00,$01,$01,$01,$01,$00,$00,$04,$00
  DEFB $04,$00,$02,$00,$00,$02,$00,$00,$02,$04,$00,$00,$00,$00,$02,$00,$00,$02,$00,$00,$02,$04,$00,$02,$00,$00,$02,$00,$00,$00,$03,$00
  DEFB $04,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$03,$00
  DEFB $07,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$08,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; Maze 3 map (24 x 32 tile codes)
;
; Maze 3 map, the third maze (maze number 2). Map of tile codes, 24 rows of 32
; columns, one byte per character cell, row by row (768 bytes = SCREEN_ROWS x
; SCREEN_COLS). DrawMaze (DrawMaze) draws the whole map from the top-left of
; the screen; row 0 is empty in every maze and is overwritten by the status
; line (StatusText) or the demo banner (DemoText). Tile codes (the graphics are
; the 8-byte entries of TileGraphics, index = code): 0 empty floor
; (TILE_EMPTY), drawn yellow-on-white; this is where Horace and the guards walk
; 1 horizontal wall (two parallel lines) 2 flower (TILE_FLOWER), green; worth
; 10 points 3 arrow pointing right (TILE_ARROW), black; the left-hand arrows
; are where Horace enters (he cannot move into them again), the right-hand ones
; are the exit to the next maze 4 vertical wall (two parallel lines) 5 wall
; corner, top-left; 6 top-right; 7 bottom-left; 8 bottom-right (all walls are
; cyan) 9 wrap pad (TILE_BLANK_WHITE): a blank cell drawn white on white, so
; invisible; going up or down into it moves the walker by the vertical wrap
; delta of the maze descriptor (MazeDescriptor) After drawing, the game never
; reads the map again: walls, flowers and arrows are recognised from the screen
; attributes ($3D, $3C, $38; ProbeMove).
;
; Occupies rows 1-23. Entrance arrows in column 0, rows 21-22, where Horace
; starts; exit arrows in column 31, rows 2-3. It has no wrap pads (its wrap
; delta is 0). 44 flowers. Its descriptor is Maze3Desc (Maze3Desc). Start
; selects the map by the maze number in MazeNumber and draws it with DrawMaze.
; The four maps are not stored in game order: this one is maze number 2.
Maze3Map:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$05,$01,$01,$01,$01,$01,$01,$01,$01,$01
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$05,$01,$01,$01,$01,$01,$01,$08,$00,$00,$00,$00,$00,$00,$00,$00,$03
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$05,$01,$01,$01,$01,$01,$01,$08,$00,$02,$00,$00,$02,$00,$00,$00,$02,$00,$00,$00,$00,$00,$00,$03
  DEFB $05,$01,$01,$01,$01,$01,$01,$01,$08,$00,$00,$02,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$05,$01,$01,$01,$01,$01,$06
  DEFB $04,$00,$02,$00,$00,$02,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$05,$01,$01,$01,$08,$00,$00,$04,$00,$00,$04
  DEFB $04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$05,$01,$01,$01,$01,$01,$01,$06,$00,$02,$07,$01,$01,$01,$01,$01,$06,$04,$00,$00,$04
  DEFB $04,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$04,$00,$00,$00,$00,$00,$00,$04,$00,$00,$00,$00,$00,$02,$00,$00,$07,$08,$00,$00,$04
  DEFB $04,$00,$02,$00,$00,$02,$00,$00,$02,$00,$00,$07,$01,$01,$01,$01,$01,$01,$04,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$00,$04
  DEFB $04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$02,$00,$00,$00,$07,$01,$01,$01,$01,$01,$06,$00,$00,$00,$00,$00,$00,$04
  DEFB $07,$01,$01,$01,$01,$01,$01,$01,$06,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$02,$00,$00,$00,$07,$01,$01,$01,$01,$01,$01,$04
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$07,$01,$01,$01,$01,$01,$01,$06,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$02,$00,$00,$02,$04
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07,$01,$01,$01,$01,$01,$06,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$01,$01,$01,$01,$01,$01,$01,$00,$00,$04
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$05,$01,$01,$01,$01,$01,$01,$08,$00,$00,$02,$00,$00,$02,$00,$00,$02,$04
  DEFB $00,$00,$00,$00,$00,$00,$00,$05,$01,$01,$01,$01,$01,$01,$08,$00,$00,$02,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04
  DEFB $05,$01,$01,$01,$01,$01,$01,$08,$00,$00,$00,$02,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$05,$01,$01,$01,$01,$01,$01,$04
  DEFB $04,$00,$02,$00,$00,$02,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$05,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$04
  DEFB $04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$05,$01,$01,$01,$01,$01,$01,$08,$00,$00,$00,$02,$00,$00,$02,$00,$00,$02,$00,$00,$02,$04
  DEFB $04,$00,$00,$05,$01,$01,$01,$01,$01,$01,$04,$00,$00,$00,$02,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04
  DEFB $04,$00,$00,$07,$01,$01,$01,$01,$01,$01,$08,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$00,$04
  DEFB $03,$00,$00,$00,$00,$02,$00,$00,$02,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$02,$00,$00,$02,$00,$00,$02,$04
  DEFB $03,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$05,$01,$01,$01,$06,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04
  DEFB $07,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$08,$00,$00,$00,$07,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$08

; Maze 4 map (24 x 32 tile codes)
;
; Maze 4 map, the fourth maze (maze number 3). Map of tile codes, 24 rows of 32
; columns, one byte per character cell, row by row (768 bytes = SCREEN_ROWS x
; SCREEN_COLS). DrawMaze (DrawMaze) draws the whole map from the top-left of
; the screen; row 0 is empty in every maze and is overwritten by the status
; line (StatusText) or the demo banner (DemoText). Tile codes (the graphics are
; the 8-byte entries of TileGraphics, index = code): 0 empty floor
; (TILE_EMPTY), drawn yellow-on-white; this is where Horace and the guards walk
; 1 horizontal wall (two parallel lines) 2 flower (TILE_FLOWER), green; worth
; 10 points 3 arrow pointing right (TILE_ARROW), black; the left-hand arrows
; are where Horace enters (he cannot move into them again), the right-hand ones
; are the exit to the next maze 4 vertical wall (two parallel lines) 5 wall
; corner, top-left; 6 top-right; 7 bottom-left; 8 bottom-right (all walls are
; cyan) 9 wrap pad (TILE_BLANK_WHITE): a blank cell drawn white on white, so
; invisible; going up or down into it moves the walker by the vertical wrap
; delta of the maze descriptor (MazeDescriptor) After drawing, the game never
; reads the map again: walls, flowers and arrows are recognised from the screen
; attributes ($3D, $3C, $38; ProbeMove).
;
; Occupies rows 2-22. Entrance arrows in column 0, rows 3-4, where Horace
; starts; exit arrows in column 31, rows 20-21. Eight wrap pads (tile 9): rows
; 3 and 21, columns 4-5 and 26-27. 24 flowers. Its descriptor is Maze4Desc
; (Maze4Desc). Start selects the map by the maze number in MazeNumber and draws
; it with DrawMaze. The four maps are not stored in game order: this one is
; maze number 3.
Maze4Map:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$06
  DEFB $03,$00,$00,$04,$09,$09,$04,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$04,$09,$09,$04,$00,$00,$04
  DEFB $03,$00,$00,$04,$00,$00,$04,$00,$00,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$00,$00,$04,$00,$00,$04,$00,$00,$04
  DEFB $04,$00,$00,$04,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$04,$00,$00,$04
  DEFB $04,$00,$00,$04,$00,$00,$04,$00,$00,$02,$00,$00,$00,$00,$02,$00,$00,$02,$00,$00,$00,$00,$00,$02,$00,$04,$00,$00,$04,$00,$00,$04
  DEFB $04,$00,$00,$04,$00,$00,$04,$00,$00,$00,$00,$05,$06,$00,$00,$00,$00,$00,$00,$05,$06,$00,$00,$00,$00,$04,$00,$00,$04,$00,$00,$04
  DEFB $04,$00,$00,$04,$00,$00,$04,$00,$00,$00,$00,$07,$08,$00,$00,$00,$00,$00,$00,$07,$08,$00,$00,$00,$00,$04,$00,$00,$04,$00,$00,$04
  DEFB $04,$00,$00,$04,$00,$00,$04,$00,$02,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$00,$02,$04,$00,$00,$00,$00,$00,$04
  DEFB $04,$00,$00,$04,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$00,$00,$00,$04
  DEFB $04,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07,$01,$01,$06,$00,$00,$04
  DEFB $04,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$04
  DEFB $04,$00,$00,$07,$01,$01,$06,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$04
  DEFB $04,$00,$00,$00,$00,$00,$04,$00,$00,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$00,$00,$04,$00,$00,$04,$00,$00,$04
  DEFB $04,$00,$00,$00,$00,$00,$04,$00,$02,$00,$00,$05,$06,$00,$00,$00,$00,$00,$00,$05,$06,$00,$00,$00,$02,$04,$00,$00,$04,$00,$00,$04
  DEFB $07,$01,$01,$06,$00,$00,$04,$00,$00,$00,$00,$07,$08,$00,$00,$00,$00,$00,$00,$07,$08,$00,$00,$00,$00,$04,$00,$00,$04,$00,$00,$04
  DEFB $00,$00,$00,$04,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$04,$00,$00,$04
  DEFB $00,$00,$00,$04,$00,$00,$04,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00,$04,$00,$00,$04,$00,$00,$04
  DEFB $00,$00,$00,$04,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$04,$00,$00,$04
  DEFB $00,$00,$00,$04,$00,$00,$04,$00,$00,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$00,$00,$04,$00,$00,$04,$00,$00,$03
  DEFB $00,$00,$00,$04,$09,$09,$04,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$04,$09,$09,$04,$00,$00,$03
  DEFB $00,$00,$00,$07,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
