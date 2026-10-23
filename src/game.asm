ROM_BEEPER EQU $3B5
FRAMES EQU $5C78
SCREEN EQU $4000
ATTRS EQU $5800
ROM_CHARSET EQU $3D00

  ORG $5FB5+SHIFT

  INCLUDE "main.asm"
  INCLUDE "movement.asm"
  INCLUDE "sprites.asm"
  INCLUDE "events.asm"
  INCLUDE "guards.asm"
  INCLUDE "texts.asm"
  INCLUDE "library.asm"
  INCLUDE "state.asm"
  INCLUDE "title_gfx.asm"
  INCLUDE "mazes.asm"
  INCLUDE "tiles.asm"
  INCLUDE "variables.asm"
  INCLUDE "sprite_gfx.asm"
