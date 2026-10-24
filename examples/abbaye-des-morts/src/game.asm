SCREEN_THIRD2 EQU $4800
LIVES_BAR_SCREEN EQU $50C0
HUD_CROSSES_SCREEN EQU $50E0
ATTRS EQU $5800
LIVES_BAR_ATTRS EQU $5AC0
HUD_CROSSES_ATTR EQU $5AE0
TILE_MAP EQU $5B00
OBJECT_LIST EQU $5DC0
SPAWN_TEMPLATE EQU $5DFC
SPAWN_POSITION EQU $5DFE
FLAG_MAP EQU $5E00
PAGING_PORT EQU $7FFD
OutlineMasks EQU $FF00

  ORG $6000

  INCLUDE "startup.asm"
  INCLUDE "font.asm"
  INCLUDE "graphics.asm"
  INCLUDE "roomscripts.asm"
  INCLUDE "cutscenelists.asm"
  INCLUDE "im2table.asm"
  INCLUDE "variables.asm"
  INCLUDE "interrupt.asm"
  INCLUDE "mainloop.asm"
  INCLUDE "sequences.asm"
  INCLUDE "objects.asm"
  INCLUDE "text.asm"
  INCLUDE "behaviours.asm"
  INCLUDE "redraw.asm"
  INCLUDE "sprites.asm"
  INCLUDE "hud.asm"
  INCLUDE "script.asm"
  INCLUDE "helpers.asm"
  INCLUDE "controls.asm"
  INCLUDE "gameframe.asm"
  INCLUDE "player.asm"
  INCLUDE "effects.asm"
  INCLUDE "unpack.asm"
  INCLUDE "entities.asm"
  INCLUDE "templates.asm"
  INCLUDE "buffers.asm"
  INCLUDE "tiles.asm"
  INCLUDE "spritesheet.asm"
