ROM_FONT EQU $3D00
SCREEN EQU $4000
STORY_LAST_ROW EQU $5020
SCREEN_ROW_19 EQU $5060
SCREEN_ROW_20 EQU $5080
SCREEN_ROW_22 EQU $50C0
SCREEN_ROW_23 EQU $50E0
ATTRS EQU $5800
SA_BYTES EQU $4C2
LD_BYTES EQU $556
BORDER_RULE EQU $5140
BORDCR EQU $5C48
STACK_TOP EQU $5EFF
STATE_COPY EQU $5F00

  ORG $6000+SHIFT

  INCLUDE "dictionary.asm"
  INCLUDE "main.asm"
  INCLUDE "input.asm"
  INCLUDE "printer.asm"
  INCLUDE "parser.asm"
  INCLUDE "drawing.asm"
  INCLUDE "system.asm"
  INCLUDE "screen.asm"
  INCLUDE "devices.asm"
  INCLUDE "verbs.asm"
  INCLUDE "engine.asm"
  INCLUDE "objects.asm"
  INCLUDE "handlers.asm"
  INCLUDE "commands.asm"
  INCLUDE "messages.asm"
  INCLUDE "world.asm"
  INCLUDE "pictures.asm"
