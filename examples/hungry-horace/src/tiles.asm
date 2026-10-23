; Maze tile graphics (10 tiles of 8 bytes)
;
; The 8x8 pixel bitmaps of the maze tiles, one per tile code of the maze maps
; (Maze1Map, Maze2Map, Maze3Map, Maze4Map), in code order: 8 bytes per tile,
; one byte per pixel row from the top, bit 7 the leftmost pixel, so a tile's
; bitmap is at TileGraphics + 8 * code. Codes 0 and 9 are both blank; they
; differ only in the attribute DrawMaze gives them (yellow ink versus
; white-on-white). Read by DrawMaze (DrawMaze), which copies them into the
; screen bitmap; the attributes are set there from the tile code.
TileGraphics:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; tile 0: empty floor
  DEFB $00,$FF,$FF,$00,$00,$FF,$FF,$00 ; tile 1: horizontal wall
  DEFB $00,$00,$00,$20,$F8,$50,$F8,$20 ; tile 2: flower
  DEFB $00,$18,$0C,$06,$7F,$06,$0C,$18 ; tile 3: arrow pointing right
  DEFB $66,$66,$66,$66,$66,$66,$66,$66 ; tile 4: vertical wall
  DEFB $00,$7F,$7F,$60,$60,$67,$67,$66 ; tile 5: corner, top-left
  DEFB $00,$FE,$FE,$06,$06,$E6,$E6,$66 ; tile 6: corner, top-right
  DEFB $66,$67,$67,$60,$60,$7F,$7F,$00 ; tile 7: corner, bottom-left
  DEFB $66,$E6,$E6,$06,$06,$FE,$FE,$00 ; tile 8: corner, bottom-right
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; tile 9: wrap pad (blank)
