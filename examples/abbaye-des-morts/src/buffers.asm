; Object list write pointer: where the next spawn request goes
;
; Address of the next free entry of the object list at $5DC0-$5DFF, which holds
; requests to create objects in the slots at ObjectSlots. An entry is 4 bytes:
; word template address (the templates start at ArrowLeftTemplate), byte y,
; byte x, the position the object starts from, in 2-pixel units; the template
; adds its own offsets. The enemies that throw things (ThrowDeathScythe,
; UpdateSatan, and the routines at $B620, $B687, $B7C6, $B818 and $B8C5) build
; the entry in the four bytes at $5DFC-$5DFF, copy it to this address, advance
; this pointer by 4 and add 1 to the count in SpawnQueueCount. Near the end of
; every frame GameFrame calls SpawnQueuedObjects when the count is not zero:
; that resets this pointer to $5DC0, creates the objects in free slots
; (FindFreeSlot) and counts the entries down. The cutscene actor lists
; (LoadCutsceneList) use the same list.
ObjectListPtr:
  DEFW OBJECT_LIST

; Frame call list write pointer
;
; Address of the next free byte of the frame call list at FrameList. GameFrame
; sets it to $BE5A at the start of every game frame, each draw command queued
; (QueueDrawCmd, AnimateItem, SelectFrameRight, QueueTwoCommands,
; UpdateBeastFire_Draw and others) copies its 10 bytes there and advances it by
; 10, and EndFrameList appends the closing entry LeaveFrameList. The value in
; the loaded image (0) is never used.
FrameListPtr:
  DEFW $0000

; Frame call list: the draw commands of one frame, closed by $BDEB
;
; Built by the game frame and run by RunFrameList. A command is 10 bytes: the
; address of a routine (QueueSprite for sprites that are masked in the redraw
; buffer, QueueBlockSprite for the object sprite), then the 8 bytes it pops:
; position (y, byte column), graphics address (column in the low byte,
; pixel-row page in the high byte), width in bytes, height in 2-pixel units, a
; byte that is popped as the flags and not used, and the attribute (the fields
; are described at SpriteCmd). The list has room for 16 commands and the
; closing word $BDEB ($A2 bytes); no check for a full list was seen, and the
; fill after it (LBEFC) would take the overflow.
;
; The interrupt handler writes into this area while SP points here and puts the
; bytes back.
FrameList:
  DEFS $A2

; Unused: $FF fill
;
; Never read and never written in the runs made (rooms 9, 12, 14, 15 and 17
; with random keys for 1500 frames, nothing was written into $BEFC-$BFFF). It
; follows the frame call list.
LBEFC:
  DEFS $0104,$FF

  ORG $C000
; Sprite draw queue: 16 jobs of 16 bytes
;
; Jobs for drawing sprites into the redraw buffers. QueueSprite and
; QueueBlockSprite, run from the frame call list, fill a template and
; AddQueueJob appends a copy at the end of the queue (the tail address is the
; operand of its first instruction). BuildRedrawList then walks the queue
; (RunDrawQueue): for each job whose first word is not zero it calls the
; routine at that address with DE = job + 1 and clears the word, so the queue
; is empty again afterwards and the first word is also the marker of a free
; job. Fields: +0 word routine ($9972 for a masked sprite, $98F7 for an object
; sprite), the other 14 bytes are the parameters of the routine (SpriteJob and
; BlockJob list them). A 17th job would run into the object slots at
; ObjectSlots.
DrawQueue:
  DEFS $0100,$FF

; Object slots: 11 records of 22 bytes, one per enemy, item, projectile or
; actor
;
; Each slot is the stack frame of an entity: word 0 is the address of its
; handler, 0 when the slot is free, followed by the state the handler keeps
; (SLOT_SIZE = 22 bytes in all, 11 slots, the word $A5FC at $C1F2 ends the
; list). The slot walker RunObjectSlots sets SP to a slot and RETs into the
; handler, which pops its state words, pushes back those that change, and ends
; with a jump to RunObjectSlot with HL at the next slot; a slot with a zero
; first word is skipped. At the end mark EndOfSlots restores the SP of the
; walker. Free slots are found by FindFreeSlot, they are cleared by room entry
; (EnterRoom: the first word of every slot) and by FreeEntitySlotAtEntry when a
; handler removes its entity. Whoever finds the slot free writes into it with
; IX (MakeItemSlot for items, SpawnRoomObject for room enemies,
; SpawnQueuedObjects for objects from templates).
;
; The layout after word 0 belongs to the handler, but the handlers from
; UpdateDeathRight to UpdateSatanSmoke all end with the same kind of words,
; because they jump to the same shared routines that pop them: the hit test
; HitTest pops two words, the hit box offset (L = y offset, H = x offset, in
; 2-pixel units) and far corner (C = y, B = x), and adds each of them to the
; position it finds in DE (D = x, E = y); the animation step StepAnimation pops
; the animation counter and its reload (C, B) and the frame number and number
; of frames (E, D). Positions are words in 8.8: the high byte is in 2-pixel
; units (x 0-$7F, y 0-$57), the low byte a fraction. x/4 is the byte column and
; x AND 3 the shift phase. The layouts seen:
;
; Enemies from the room object table ($89ED: Death UpdateDeathLeft, Satan
; UpdateSatan): +2 word speed, +4 byte lower and +5 byte upper limit of the
; patrolling coordinate, +6 word x, +8 word y, +$A byte timer counter, +$B byte
; its reload, +$C word hit box offset, +$E word hit box far corner, +$10 word
; pointer into the sprite block, +$12 byte animation counter, +$13 its reload,
; +$14 byte frame number, +$15 byte number of frames.
;
; Objects from templates (Death's scythe UpdateScytheFalling, spawned by
; SpawnQueuedObjects from ScytheLeftTemplate): +2 word x speed, +4 word y
; speed, +6 word x, +8 word y, +$A word hit box offset, +$C word hit box far
; corner, +$E word pointer into the sprite block, +$10 animation counter and
; reload, +$12 frame number and number of frames, +$14 word not set by the
; spawner (stale). The projectiles of UpdateFireball have the first four words
; of this layout. Template bytes 6 and 7 are offsets added to the start
; position and become the high bytes of x and y; the 10 bytes from template
; byte 8 are copied to +$A to +$13 as they are.
;
; Room items (MakeItemSlot) use slots too, filled from the item record
; (RoomItems) and the type record (ObjectTypeRecords); their layout is given at
; RunObjectSlots.
ObjectSlots:
  DEFS $F4,$FF

; Unused: $FF fill
;
; Follows the object slots and their end mark at $C1F2. Never written in the
; runs made.
LC1F4:
  DEFS $0C,$FF

; Redraw run list: the cells to copy to the screen this frame, grouped by row
;
; Built by BuildRedrawList (through CollectRedrawRun) from the cells of the
; tile flag map that are marked for redraw, and read by DrawRedrawList, which
; writes the cells to the screen. The list is a sequence of row groups: byte
; row (0-21, the character row), byte n (number of runs in the row), then n
; runs of two bytes: byte column (0-31) of the first cell of the run and byte
; index of that cell in the redraw cell buffers (RedrawLengths, RedrawAttrs,
; RedrawPixels). The list ends with $FF where a row byte would be. A run is a
; stretch of marked cells that follow each other in a row; its length is in
; RedrawLengths at the index of its first cell. Observed after a frame of room
; 5: $11 $02 $00 $00 $12 $02 / $12 $02 $00 $05 $12 $07 / $13 $02 $00 $0A $12
; $0C / $FF: row 17 with two runs, cells 0-1 from column 0 and cells 2-4 from
; column $12 (lengths 2 and 3 in RedrawLengths), then the same for rows 18 and
; 19. The index is one byte, so a frame can queue at most 256 cells.
RedrawRuns:
  DEFS $0100,$FF

; Redraw cells: length of the run that starts at this cell
;
; One byte per queued cell, indexed like RedrawAttrs and RedrawPixels. Only the
; entry of the first cell of a run is meaningful: it holds the number of cells
; in the run (CopyRunCells writes it, DrawRedrawList reads it). Observed after
; a frame: runs of 1 to 7 cells.
RedrawLengths:
  DEFS $0100,$FF

; Redraw cells: attribute of each queued cell
;
; One byte per queued cell: the attribute from TileAttrs, indexed by the cell
; index of the run list (RedrawRuns); CopyRunCells fills it, the sprite drawers
; change it, DrawRedrawList writes it to the attribute file (high byte
; PAGE_REDRAW_ATTRS).
RedrawAttrs:
  DEFS $0100,$FF

; Redraw cells: the 8 pixel rows of each queued cell, one 256-byte page per row
;
; Page $C5 + r holds pixel row r (0-7) of the queued cells, indexed by the cell
; index of the run list (RedrawRuns): the bytes of the cell are 256 bytes
; apart. CopyRunCells copies the tile bitmaps (TileGfx) in, the sprite drawers
; draw into them, and DrawRedrawList writes them to the screen. The first page
; ($C500-$C5FF) is also the table of bit-reversed bytes built by
; BuildMirrorTable on room entry and used while the sprites of a room are
; unpacked; and RestoreMenuArea and its partner copy the middle third of the
; screen bitmap ($4800-$4FFF, 2048 bytes) to $C500 and back to save the screen
; under the menus.
RedrawPixels:
  DEFS $0800,$FF
