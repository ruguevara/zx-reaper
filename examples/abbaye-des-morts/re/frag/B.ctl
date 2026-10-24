w $8A8F Object type table: 12 pointers to 8-byte type records (index = type, read by $897E)
W $8A8F,24,2
b $8AA7 Object type records: 12 x 8 bytes (+0 to IX+$08/$09, +1 to IX+$0B, +2 handler address, +4 frame-list pointer, +6/+7 to IX+$0E/$0F)
B $8AA7,2,2
W $8AA9,4,2
B $8AAD,2,2
B $8AAF,2,2
W $8AB1,4,2
B $8AB5,2,2
B $8AB7,2,2
W $8AB9,4,2
B $8ABD,2,2
B $8ABF,2,2
W $8AC1,4,2
B $8AC5,2,2
B $8AC7,2,2
W $8AC9,4,2
B $8ACD,2,2
B $8ACF,2,2
W $8AD1,4,2
B $8AD5,2,2
B $8AD7,2,2
W $8AD9,4,2
B $8ADD,2,2
B $8ADF,2,2
W $8AE1,4,2
B $8AE5,2,2
B $8AE7,2,2
W $8AE9,4,2
B $8AED,2,2
B $8AEF,2,2
W $8AF1,4,2
B $8AF5,2,2
B $8AF7,2,2
W $8AF9,4,2
B $8AFD,2,2
B $8AFF,2,2
W $8B01,4,2
B $8B05,2,2
b $8B07 Frame lists: 4-byte frames (sprite address, attribute, unused 0), read by $A7CB
W $8B07,2
B $8B09,2,2
W $8B0B,2
B $8B0D,2,2
W $8B0F,2
B $8B11,2,2
W $8B13,2
B $8B15,2,2
W $8B17,2
B $8B19,2,2
W $8B1B,2
B $8B1D,2,2
W $8B1F,2
B $8B21,2,2
W $8B23,2
B $8B25,2,2
W $8B27,2
B $8B29,2,2
W $8B2B,2
B $8B2D,2,2
W $8B2F,2
B $8B31,2,2
W $8B33,2
B $8B35,2,2
W $8B37,2
B $8B39,2,2
W $8B3B,2
B $8B3D,2,2
W $8B3F,2
B $8B41,2,2
W $8B43,2
B $8B45,2,2
W $8B47,2
B $8B49,2,2
W $8B4B,2
B $8B4D,2,2
W $8B4F,2
B $8B51,2,2
W $8B53,2
B $8B55,2,2
W $8B57,2
B $8B59,2,2
W $8B5B,2
B $8B5D,2,2
W $8B5F,2
B $8B61,2,2
W $8B63,2
B $8B65,2,2
W $8B67,2
B $8B69,2,2
W $8B6B,2
B $8B6D,2,2
W $8B6F,2
B $8B71,2,2
W $8B73,2
B $8B75,2,2
W $8B77,2
B $8B79,2,2
W $8B7B,2
B $8B7D,2,2
W $8B7F,2
B $8B81,2,2
W $8B83,2
B $8B85,2,2
W $8B87,2
B $8B89,2,2
W $8B8B,2
B $8B8D,2,2
b $8B8F Room objects: 11-byte records (room, kind, 7 parameters, pointer to behaviour data), ended by room $1A; read by $89D9/$89ED
B $8B8F,9,9
W $8B98,2
B $8B9A,9,9
W $8BA3,2
B $8BA5,9,9
W $8BAE,2
B $8BB0,9,9
W $8BB9,2
B $8BBB,9,9
W $8BC4,2
B $8BC6,9,9
W $8BCF,2
B $8BD1,9,9
W $8BDA,2
B $8BDC,9,9
W $8BE5,2
B $8BE7,9,9
W $8BF0,2
B $8BF2,9,9
W $8BFB,2
B $8BFD,9,9
W $8C06,2
B $8C08,9,9
W $8C11,2
B $8C13,9,9
W $8C1C,2
B $8C1E,9,9
W $8C27,2
B $8C29,9,9
W $8C32,2
B $8C34,9,9
W $8C3D,2
B $8C3F,9,9
W $8C48,2
B $8C4A,9,9
W $8C53,2
B $8C55,9,9
W $8C5E,2
B $8C60,9,9
W $8C69,2
B $8C6B,9,9
W $8C74,2
B $8C76,9,9
W $8C7F,2
B $8C81,9,9
W $8C8A,2
B $8C8C,9,9
W $8C95,2
B $8C97,9,9
W $8CA0,2
B $8CA2,9,9
W $8CAB,2
B $8CAD,9,9
W $8CB6,2
B $8CB8,9,9
W $8CC1,2
B $8CC3,9,9
W $8CCC,2
B $8CCE,9,9
W $8CD7,2
B $8CD9,9,9
W $8CE2,2
B $8CE4,9,9
W $8CED,2
B $8CEF,9,9
W $8CF8,2
B $8CFA,9,9
W $8D03,2
B $8D05,9,9
W $8D0E,2
B $8D10,9,9
W $8D19,2
B $8D1B,9,9
W $8D24,2
B $8D26,9,9
W $8D2F,2
B $8D31,9,9
W $8D3A,2
B $8D3C,9,9
W $8D45,2
B $8D47,9,9
W $8D50,2
B $8D52,9,9
W $8D5B,2
B $8D5D,9,9
W $8D66,2
B $8D68,9,9
W $8D71,2
B $8D73,9,9
W $8D7C,2
B $8D7E,9,9
W $8D87,2
B $8D89,9,9
W $8D92,2
B $8D94,9,9
W $8D9D,2
B $8D9F,9,9
W $8DA8,2
B $8DAA,9,9
W $8DB3,2
B $8DB5,9,9
W $8DBE,2
B $8DC0,9,9
W $8DC9,2
B $8DCB,9,9
W $8DD4,2
B $8DD6,9,9
W $8DDF,2
B $8DE1,9,9
W $8DEA,2
B $8DEC,9,9
W $8DF5,2
B $8DF7,9,9
W $8E00,2
B $8E02,9,9
W $8E0B,2
B $8E0D,9,9
W $8E16,2
B $8E18,9,9
W $8E21,2
B $8E23,9,9
W $8E2C,2
B $8E2E,9,9
W $8E37,2
B $8E39,9,9
W $8E42,2
B $8E44,9,9
W $8E4D,2
B $8E4F,9,9
W $8E58,2
B $8E5A,9,9
W $8E63,2
B $8E65,9,9
W $8E6E,2
B $8E70,9,9
W $8E79,2
B $8E7B,9,9
W $8E84,2
B $8E86,9,9
W $8E8F,2
B $8E91,9,9
W $8E9A,2
B $8E9C,9,9
W $8EA5,2
B $8EA7,9,9
W $8EB0,2
B $8EB2,9,9
W $8EBB,2
B $8EBD,9,9
W $8EC6,2
B $8EC8,9,9
W $8ED1,2
B $8ED3,9,9
W $8EDC,2
B $8EDE,1
b $8EDF Room items: 8-byte records (room, pointer to state flag, object type, 4 parameters), ended by room $1A; read by $8957/$896B/$897E
B $8EDF,1
W $8EE0,2
B $8EE2,5,5
B $8EE7,1
W $8EE8,2
B $8EEA,5,5
B $8EEF,1
W $8EF0,2
B $8EF2,5,5
B $8EF7,1
W $8EF8,2
B $8EFA,5,5
B $8EFF,1
W $8F00,2
B $8F02,5,5
B $8F07,1
W $8F08,2
B $8F0A,5,5
B $8F0F,1
W $8F10,2
B $8F12,5,5
B $8F17,1
W $8F18,2
B $8F1A,5,5
B $8F1F,1
W $8F20,2
B $8F22,5,5
B $8F27,1
W $8F28,2
B $8F2A,5,5
B $8F2F,1
W $8F30,2
B $8F32,5,5
B $8F37,1
W $8F38,2
B $8F3A,5,5
B $8F3F,1
W $8F40,2
B $8F42,5,5
B $8F47,1
W $8F48,2
B $8F4A,5,5
B $8F4F,1
W $8F50,2
B $8F52,5,5
B $8F57,1
W $8F58,2
B $8F5A,5,5
B $8F5F,1
W $8F60,2
B $8F62,5,5
B $8F67,1
W $8F68,2
B $8F6A,5,5
B $8F6F,1
W $8F70,2
B $8F72,5,5
B $8F77,1
W $8F78,2
B $8F7A,5,5
B $8F7F,1
W $8F80,2
B $8F82,5,5
B $8F87,1
W $8F88,2
B $8F8A,5,5
B $8F8F,1
W $8F90,2
B $8F92,5,5
B $8F97,1
W $8F98,2
B $8F9A,5,5
B $8F9F,1
W $8FA0,2
B $8FA2,5,5
B $8FA7,1
W $8FA8,2
B $8FAA,5,5
B $8FAF,1
W $8FB0,2
B $8FB2,5,5
B $8FB7,1
W $8FB8,2
B $8FBA,5,5
B $8FBF,1
W $8FC0,2
B $8FC2,5,5
B $8FC7,1
W $8FC8,2
B $8FCA,5,5
B $8FCF,1
W $8FD0,2
B $8FD2,5,5
B $8FD7,1
W $8FD8,2
B $8FDA,5,5
B $8FDF,1
W $8FE0,2
B $8FE2,5,5
B $8FE7,1
W $8FE8,2
B $8FEA,5,5
B $8FEF,1
W $8FF0,2
B $8FF2,5,5
B $8FF7,1
W $8FF8,2
B $8FFA,5,5
B $8FFF,1
W $9000,2
B $9002,5,5
B $9007,1
W $9008,2
B $900A,5,5
B $900F,1
W $9010,2
B $9012,5,5
B $9017,1
W $9018,2
B $901A,5,5
B $901F,1
W $9020,2
B $9022,5,5
B $9027,1
W $9028,2
B $902A,5,5
B $902F,1
W $9030,2
B $9032,5,5
B $9037,1
W $9038,2
B $903A,5,5
B $903F,1
W $9040,2
B $9042,5,5
B $9047,1
t $9048 Text table: length-prefixed strings found by number from here ($9F43); 0-24 room names
T $9048,3,n1:2
T $904B,17,n1:16
T $905C,18,n1:17
T $906E,14,n1:13
T $907C,3,n1:2
T $907F,11,n1:10
T $908A,15,n1:14
T $9099,17,n1:16
T $90AA,10,n1:9
T $90B4,13,n1:12
T $90C1,16,n1:15
T $90D1,18,n1:17
T $90E3,14,n1:13
T $90F1,10,n1:9
T $90FB,14,n1:13
T $9109,14,n1:13
T $9117,16,n1:15
T $9127,19,n1:18
T $913A,17,n1:16
T $914B,18,n1:17
T $915D,16,n1:15
T $916D,12,n1:11
T $9179,15,n1:14
T $9188,15,n1:14
T $9197,10,n1:9
t $91A1 Text: parchment messages (strings 25-36, two lines each)
T $91A1,15,n1:14
T $91B0,18,n1:17
T $91C2,16,n1:15
T $91D2,18,n1:17
T $91E4,14,n1:13
T $91F2,20,n1:19
T $9206,18,n1:17
T $9218,19,n1:18
T $922B,14,n1:13
T $9239,21,n1:20
T $924E,14,n1:13
T $925C,15,n1:14
t $926B Text: "G a m e  O v e r" (string 37)
T $926B,17,n1:16
t $927C Text: intro (strings 38-42)
T $927C,31,n1:30
T $929B,31,n1:30
T $92BA,28,n1:27
T $92D6,24,n1:23
T $92EE,32,n1:31
t $930E Text: Satan's words (strings 43-45)
T $930E,20,n1:19
T $9322,15,n1:14
T $9331,19,n1:18
t $9344 Text: "Heresy!!!" message (strings 46-48)
T $9344,21,n1:20
T $9359,24,n1:23
T $9371,19,n1:18
t $9384 Text: ending (strings 49-52)
T $9384,21,n1:20
T $9399,15,n1:14
T $93A8,24,n1:23
T $93C0,19,n1:18
b $93D3 Behaviour data for object kind 0 (rooms 0): 5-byte header, then kind-specific bytes and sprite/frame pointers
B $93D3,5,5
B $93D8,1,1
W $93D9,2,2
B $93DB,1,1
W $93DC,4,2
b $93E0 Behaviour data for object kind 0,1 (rooms 0,5,6,25): 5-byte header, then kind-specific bytes and sprite/frame pointers
B $93E0,5,5
B $93E5,1,1
W $93E6,2,2
B $93E8,1,1
W $93E9,12,2
b $93F5 Behaviour data for object kind 2 (rooms 13,22): 5-byte header, then kind-specific bytes and sprite/frame pointers
B $93F5,5,5
B $93FA,1,1
W $93FB,2,2
B $93FD,1,1
W $93FE,12,2
b $940A Behaviour data for object kind 2 (rooms 22,23): 5-byte header, then kind-specific bytes and sprite/frame pointers
B $940A,5,5
B $940F,1,1
W $9410,2,2
B $9412,1,1
W $9413,12,2
b $941F Behaviour data for object kind 2,3 (rooms 8): 5-byte header, then kind-specific bytes and sprite/frame pointers
B $941F,5,5
B $9424,1,1
W $9425,2,2
B $9427,1,1
W $9428,8,2
b $9430 Behaviour data for object kind 2,3 (rooms 2): 5-byte header, then kind-specific bytes and sprite/frame pointers
B $9430,5,5
B $9435,1,1
W $9436,2,2
B $9438,1,1
W $9439,12,2
b $9445 Behaviour data for object kind 4 (rooms 3,14,16,19): 5-byte header, then kind-specific bytes and sprite/frame pointers
B $9445,5,5
B $944A,1,1
W $944B,2,2
B $944D,1,1
W $944E,4,2
b $9452 Behaviour data for object kind 5 (rooms 3): 5-byte header, then kind-specific bytes and sprite/frame pointers
B $9452,5,5
B $9457,1,1
W $9458,2,2
B $945A,1,1
W $945B,8,2
B $9463,2,2
b $9465 Behaviour data for object kind 6 (rooms 9): 5-byte header, then kind-specific bytes and sprite/frame pointers
B $9465,5,5
B $946A,1,1
W $946B,2,2
B $946D,1,1
W $946E,8,2
b $9476 Behaviour data for object kind 2 (rooms 9,14): 5-byte header, then kind-specific bytes and sprite/frame pointers
B $9476,5,5
B $947B,1,1
W $947C,2,2
B $947E,1,1
W $947F,8,2
b $9487 Behaviour data for object kind 5 (rooms 12): 5-byte header, then kind-specific bytes and sprite/frame pointers
B $9487,5,5
B $948C,1,1
W $948D,2,2
B $948F,1,1
W $9490,12,2
b $949C Behaviour data for object kind 5 (rooms 12): 5-byte header, then kind-specific bytes and sprite/frame pointers
B $949C,5,5
B $94A1,1,1
W $94A2,2,2
B $94A4,1,1
W $94A5,12,2
b $94B1 Behaviour data for object kind 8 (rooms 11): 5-byte header, then kind-specific bytes and sprite/frame pointers
B $94B1,5,5
B $94B6,1,1
W $94B7,2,2
B $94B9,1,1
W $94BA,12,2
b $94C6 Behaviour data for object kind 2 (rooms 20,23): 5-byte header, then kind-specific bytes and sprite/frame pointers
B $94C6,5,5
B $94CB,1,1
W $94CC,2,2
B $94CE,1,1
W $94CF,12,2
B $94DB,8,8
b $94E3 Behaviour data for object kind 9 (rooms 15,19): 5-byte header, then kind-specific bytes and sprite/frame pointers
B $94E3,5,5
B $94E8,2,2
W $94EA,6,2
B $94F0,1,1
W $94F1,2,2
B $94F3,1,1
W $94F4,2,2
B $94F6,1,1
W $94F7,2,2
B $94F9,1,1
W $94FA,2,2
B $94FC,1,1
W $94FD,2,2
B $94FF,1,1
W $9500,6,2
b $9506 Behaviour data for object kind 2 (rooms 15,20): 5-byte header, then kind-specific bytes and sprite/frame pointers
B $9506,5,5
B $950B,1,1
W $950C,2,2
B $950E,1,1
W $950F,12,2
b $951B Behaviour data for object kind 10 (rooms 17,21): 5-byte header, then kind-specific bytes and sprite/frame pointers
B $951B,5,5
B $9520,3,3
W $9523,12,2
b $952F Behaviour data for object kind 11 (rooms 20,22): 5-byte header, then kind-specific bytes and sprite/frame pointers
B $952F,5,5
B $9534,3,3
W $9537,6,2
b $953D Behaviour data for object kind 12 (rooms 14): 5-byte header, then kind-specific bytes and sprite/frame pointers
B $953D,5,5
B $9542,3,3
W $9545,4,2
b $9549 Behaviour data for object kind 13 (rooms 16,19): 5-byte header, then kind-specific bytes and sprite/frame pointers
B $9549,5,5
B $954E,3,3
W $9551,4,2
b $9555 Behaviour data for object kind 2,3 (rooms 21,22): 5-byte header, then kind-specific bytes and sprite/frame pointers
B $9555,5,5
B $955A,1,1
W $955B,2,2
B $955D,1,1
W $955E,12,2
b $956A Behaviour data for object kind 4 (rooms 22,23): 5-byte header, then kind-specific bytes and sprite/frame pointers
B $956A,5,5
B $956F,1,1
W $9570,2,2
B $9572,1,1
W $9573,8,2
b $957B Behaviour data for object kind 14 (rooms 10): 5-byte header, then kind-specific bytes and sprite/frame pointers
B $957B,5,5
B $9580,3,3
W $9583,2,2
b $9585 Behaviour data for object kind 15 (rooms 10): 5-byte header, then kind-specific bytes and sprite/frame pointers
B $9585,5,5
B $958A,3,3
W $958D,8,2
B $9595,1,1
W $9596,2,2
B $9598,1,1
W $9599,4,2
B $959D,1,1
W $959E,2,2
B $95A0,1,1
W $95A1,4,2
B $95A5,1,1
W $95A6,2,2
B $95A8,1,1
W $95A9,4,2
B $95AD,1,1
W $95AE,2,2
B $95B0,1,1
W $95B1,2,2
B $95B3,1,1
W $95B4,2,2
B $95B6,1,1
W $95B7,2,2
b $95B9 Behaviour data for object kind 16 (rooms 18): 5-byte header, then kind-specific bytes and sprite/frame pointers
B $95B9,5,5
B $95BE,1,1
W $95BF,2,2
B $95C1,1,1
W $95C2,16,2
B $95D2,9,9
W $95DB,2,2
B $95DD,1,1
W $95DE,8,2
b $95E6 Behaviour data for object kind 17 (rooms 24): 5-byte header, then kind-specific bytes and sprite/frame pointers
B $95E6,5,5
B $95EB,3,3
W $95EE,8,2
B $95F6,1,1
W $95F7,8,2
i $95FF
c $9636 Unrolled LDI chain, 21 of 31: entered by the JR at $9634 (offset set from the width)
i $9660
c $9685 Unrolled LDD chain, 21 of 31: entered by the JR at $9683 (offset set from the width)
i $96AF
c $96C9 Unrolled LDI chain, 21 of 31: entered by the JR at $96C7 (offset set from the width)
i $96F3
g $982E Draw-queue job built by $97FD: handler address, then parameters written at run time (16 bytes copied by $98B1)
W $982E,2,2
W $9830,2,2
B $9832,1,1
W $9833,2,2
B $9835,1,1
i $9836
g $98D9 Draw-queue job built by $9836: handler address, then parameters written at run time (16 bytes copied by $98B1)
W $98D9,2,2
W $98DB,2,2
B $98DD,1,1
W $98DE,2,2
B $98E0,4,1
i $98E4
w $99E8 Jump table of the sprite drawers used by $99C9 (index A-1)
W $99E8,10,2
i $99F2
b $9BD3 Screen-scroll setups: 4 x 8 bytes (rows, columns, start address, 4 step bytes poked into $9B91/$9B95/$9B9D/$9BA1), indexed by $850B
B $9BD3,32,8
i $9BF3
w $9CF3 Attribute-buffer row addresses: 22 words, $5800 + 32*row, read by $95FF
W $9CF3,44,2
w $9D1F Script opcode jump table: handlers of the codes $80-$9F interpreted by $9D5F
W $9D1F,64,2
i $9D5F
g $9F26 Text cursor: y (pixel row), x (pixel column); set by script code $8E
B $9F26,2,1
i $9F28
g $9F93 Alignment of numbered strings (1 at x=0, 2 centred, other values right-aligned), set by script code $82
i $9F94
c $A097 Unused script handler: fill a C x B area of the $5E00 attribute buffer with a byte (arguments as code $8F)
i $A0B4
g $A116 Block descriptor set by script code $88: width, height, data address
B $A116,2,1
W $A118,2,2
i $A11A
c $A15A Script code $9A: one count byte, then as $A15C (never used by the scripts)
i $A15C
c $A22F Unused copy of $A21E: $5E00 buffer address of cell (L, H)
i $A240
b $A2B7 Cheat check: 4 (row, mask) pairs whose XOR with the first four redefined keys must be 0 ($A422)
B $A2B7,8,2
g $A2BF Redefinable keys: 8 (keyboard row index, bit mask) pairs into the row buffer at $A2D3
B $A2BF,16,2
g $A2CF Control bits read this frame ($A271, or $A290 for Kempston)
g $A2D0 Control bits of the previous frame ($A596)
g $A2D1 Controls newly pressed this frame ($A596)
g $A2D2 Code of the key pressed (0 = none), from $A304
g $A2D3 Keyboard row buffer: 8 half-rows read by $A240
B $A2D3,8,8
t $A2DB Key codes in keyboard-scan order (CAPS SHIFT..B), 40 codes then 0 for no key; read by $A304
T $A2DB,41,n1:29:n1:5:n1:3:n1
i $A304
c $A31E Wait for SPACE to be released (128K only: the RET here becomes CALL $85EE, patched by $605F)
B $A31F,2,2
i $A32D
w $A3A9 Redefine-key prompts: 4 x (prompt script address, key pair address)
W $A3A9,16,4
i $A3B9
t $A41A Short names of ENTER, SPACE, CAPS SHIFT, SYMBOL SHIFT, read by $A3F6
T $A41A,8,2
i $A422
t $A493 Script: controls screen background and "Enter to menu"
B $A493,6,6
B $A499,6,6
B $A49F,3,3
T $A4A2,13
B $A4AF,6,6
B $A4B5,1,1
t $A4B6 Script: "1. Kempston "
B $A4B6,6,6
B $A4BC,3,3
T $A4BF,12
B $A4CB,1,1
t $A4CC Script: "enabled"
T $A4CC,7
B $A4D3,1,1
t $A4D4 Script: "disabled"
T $A4D4,8
B $A4DC,1,1
t $A4DD Script: "2. Keyboard " followed by the key names at $A4F2
B $A4DD,6,6
B $A4E3,3,3
T $A4E6,12
g $A4F2 Key names shown on the controls screen (8 characters, rewritten by $A336/$A3F6), end of the script at $A4DD
T $A4F2,8
B $A4FA,1,1
t $A4FB Script: "Press key "
B $A4FB,6,6
B $A501,3,3
T $A504,10
B $A50E,1,1
t $A50F Script: "JUMP"
T $A50F,4
B $A513,1,1
t $A514 Script: "CROUCH"
T $A514,6
B $A51A,1,1
t $A51B Script: "LEFT"
T $A51B,4
B $A51F,1,1
t $A520 Script: "RIGHT"
T $A520,5
B $A525,1,1
t $A526 Script: title screen
B $A526,6,6
B $A52C,6,6
B $A532,3,3
T $A535,8
B $A53D,3,3
T $A540,9
B $A549,3,3
T $A54C,20
B $A560,3,3
T $A563,20
B $A577,6,6
B $A57D,1,1
t $A57E Script: game over screen
B $A57E,6,6
B $A584,6,6
B $A58A,3,3
B $A58D,2,2
B $A58F,6,6
B $A595,1,1
i $A596
