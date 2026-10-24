g $A894 Player variables
B $A894,1,1 State: 0 none, 1 dying, 2 jumping, 3 crouching, 4 standing/walking, 5 falling, $FF debug room warp
B $A895,1,1 Animation timer
B $A896,1,1 Animation frame
B $A897,1,1 Facing: 0 right, 1 left
W $A898,2,2 Vertical speed (8.8)
B $A89A,2,2 Unused
B $A89C,4,4 Tile flags at the head, right, feet, left
B $A8A0,1,1 Hit flag (bit 2 or $FF)
W $A8A1,2,2 X (8.8, high byte in 2-pixel units, 0-$7F)
W $A8A3,2,2 Y (8.8, high byte in 2-pixel units, 0-$57)
i $A8A5
c $AAC0 Unused: enter the debug room-warp mode (player state $FF)
i $AAC6
b $AC9F Player sprite frame tables
B $AC9F,8,2 Standing: (byte offset, width) for X mod 4
W $ACA7,6,6 Standing frames, facing left
W $ACAD,6,6 Standing frames, facing right
W $ACB3,14,14 Dying frames
B $ACC1,8,2 Crouching: (byte offset, width) for X mod 4
W $ACC9,4,4 Crouching frames, facing left
W $ACCD,4,4 Crouching frames, facing right
g $ACD1 Sprite draw commands
W $ACD1,6,6 Main sprite: routine, position (y, x/4 = byte column), graphics
B $ACD7,4,4 Width, height, unused, attribute
W $ACDB,6,6 Second sprite: routine, position, graphics
B $ACE1,4,4 Width, height, unused, attribute
W $ACE5,6,6 Object sprite (drawn by $97FD): routine, position, graphics
B $ACEB,4,4 Width, height, unused, attribute
i $ACEF
c $AD71 Unused debug: move to the next room in the direction bits in A
c $AD82 Unused debug: leave the room-warp mode (player state 4)
i $AD88
c $ADA1 Block copier: first 16 LDIs of the chain entered from $AD9F
i $ADC1
b $AE9D Graphics unpack commands (20 records of 6 bytes)
W $AE9D,4,4
B $AEA1,2,2
W $AEA3,4,4
B $AEA7,2,2
W $AEA9,4,4
B $AEAD,2,2
W $AEAF,4,4
B $AEB3,2,2
W $AEB5,4,4
B $AEB9,2,2
W $AEBB,4,4
B $AEBF,2,2
W $AEC1,4,4
B $AEC5,2,2
W $AEC7,4,4
B $AECB,2,2
W $AECD,4,4
B $AED1,2,2
W $AED3,4,4
B $AED7,2,2
W $AED9,4,4
B $AEDD,2,2
W $AEDF,4,4
B $AEE3,2,2
W $AEE5,4,4
B $AEE9,2,2
W $AEEB,4,4
B $AEEF,2,2
W $AEF1,4,4
B $AEF5,2,2
W $AEF7,4,4
B $AEFB,2,2
W $AEFD,4,4
B $AF01,2,2
W $AF03,4,4
B $AF07,2,2
W $AF09,4,4
B $AF0D,2,2
W $AF0F,4,4
B $AF13,2,2
i $AF15
w $B028 Entity handlers by type
W $B028,36,8
b $B04C Entity templates: initial stack frames for the handler at $B1D4
W $B04C,66,22
i $B08E
b $B0E8 Speed curves for path movers (6 signed 8.8 words each)
W $B0E8,12,12
W $B0F4,12,12
W $B100,12,12
i $B10C
w $B20C Path command handlers
W $B20C,12,12
b $B218 Path scripts: (target coordinate, command) pairs
B $B218,8,2
B $B220,12,2
B $B22C,10,2
i $B236
c $B74B Entity handler: falling projectile, removed off screen or on a solid tile
i $B77F
c $B924 Continuation of the routine at $B8C5 after the draw at $A851
i $B97D
c $BB07 Entity handler: second state of the one at $BAB1
i $BB57
c $BC69 Entity handler: two-part sprite with a lifetime (template at $BD6A)
b $BC92 Entity templates: initial stack frames
W $BC92,144,16
W $BD22,72,18
W $BD6A,22,22
W $BD80,90,18
i $BDDA
b $BE2A Checkpoints: (room, row, column)
B $BE2A,30,3
i $BE48
