b $6073 Room tile map buffer ($5E00-$60BF, 32x22 tile numbers), rows 19-21; the start-up code at $6000 is overwritten
S $6073,77,77:$FF
b $60C0 Main stack (SP starts at $6100)
S $60C0,64,64:$FF
w $6100 Row address table: 24 words $5E00+32*n into the room tile map, built at start-up
W $6100,48,8
b $6130 Font index: 96 words for $20-$7F, bits 0-11 offset from the word's high byte to the glyph, bits 12-15 width-2
W $6130,192,8
b $61F0 Font glyphs, 16 rows: mask word (bit 15 = row 0, set = new row pattern), then 1 byte per new row (2 if width>8)
B $61F0,2
B $61F2,6
B $61F8,4
B $61FC,14
B $620A,14
B $6218,24,16
B $6230,24,16
B $6248,4
B $624C,12
B $6258,12
B $6264,8
B $626C,6
B $6272,6
B $6278,4
B $627C,4
B $6280,14
B $628E,6
B $6294,8
B $629C,13
B $62A9,13
B $62B6,22,16
B $62CC,11
B $62D7,10
B $62E1,9
B $62EA,8
B $62F2,10
B $62FC,6
B $6302,8
B $630A,10
B $6314,6
B $631A,10
B $6324,11
B $632F,2
B $6331,26,16
B $634B,18,16
B $635D,10
B $6367,18,16
B $6379,24,16
B $6391,20,16
B $63A5,22,16
B $63BB,24,16
B $63D3,16
B $63E3,8
B $63EB,24,16
B $6403,14
B $6411,22,16
B $6427,24,16
B $643F,16
B $644F,16
B $645F,20,16
B $6473,22,16
B $6489,13
B $6496,12
B $64A2,18,16
B $64B4,20,16
B $64C8,22,16
B $64DE,22,16
B $64F4,22,16
B $650A,24,16
B $6522,6
B $6528,14
B $6536,6
B $653C,6
B $6542,6
B $6548,6
B $654E,14
B $655C,10
B $6566,9
B $656F,18,16
B $6581,10
B $658B,8
B $6593,11
B $659E,22,16
B $65B4,12
B $65C0,12
B $65CC,22,16
B $65E2,8
B $65EA,18,16
B $65FC,18,16
B $660E,7
B $6615,16
B $6625,18,16
B $6637,8
B $663F,10
B $6649,10
B $6653,16
B $6663,18,16
B $6675,18,16
B $6687,18,16
B $6699,22,16
B $66AF,18,16
B $66C1,8
B $66C9,4
B $66CD,8
B $66D5,5
B $66DA,2
b $66DC Sprite graphics, 16 pixels wide, 2 bytes a row, read by $98F7 through the sprite table at $8B07
B $66DC,48,2
B $670C,32,2
B $672C,32,2
B $674C,32,2
B $676C,32,2
B $678C,32,2
B $67AC,32,2
B $67CC,32,2
B $67EC,32,2
B $680C,32,2
B $682C,32,2
B $684C,32,2
B $686C,32,2
B $688C,32,2
B $68AC,32,2
b $68CC Packed sprite set 0 (op $97): 4 columns of 3 chars; flag bytes, set bit = literal byte, clear = 0
B $68CC,2
B $68CE,72,16
b $6916 Packed sprite set 1 (op $97): 4 columns of 3 chars; flag bytes, set bit = literal byte, clear = 0
B $6916,2
B $6918,97,16
b $6979 Packed sprite set 2 (op $97): 12 columns of 4 chars; flag bytes, set bit = literal byte, clear = 0
B $6979,2
B $697B,300,16
b $6AA7 Packed sprite set 3 (op $97): 4 columns of 3 chars; flag bytes, set bit = literal byte, clear = 0
B $6AA7,2
B $6AA9,89,16
b $6B02 Packed sprite set 4 (op $97): 6 columns of 2 chars; flag bytes, set bit = literal byte, clear = 0
B $6B02,2
B $6B04,66,16
b $6B46 Packed sprite set 5 (op $97): 10 columns of 3 chars; flag bytes, set bit = literal byte, clear = 0
B $6B46,2
B $6B48,146,16
b $6BDA Packed sprite set 6 (op $97): 4 columns of 5 chars; flag bytes, set bit = literal byte, clear = 0
B $6BDA,2
B $6BDC,115,16
b $6C4F Packed sprite set 7 (op $97): 2 columns of 4 chars; flag bytes, set bit = literal byte, clear = 0
B $6C4F,2
B $6C51,42,16
b $6C7B Packed sprite set 8 (op $97): 4 columns of 2 chars; flag bytes, set bit = literal byte, clear = 0
B $6C7B,2
B $6C7D,57,16
b $6CB6 Packed sprite set 9 (op $97): 4 columns of 2 chars; flag bytes, set bit = literal byte, clear = 0
B $6CB6,2
B $6CB8,57,16
b $6CF1 Packed sprite set 10 (op $97): 2 columns of 3 chars; flag bytes, set bit = literal byte, clear = 0
B $6CF1,2
B $6CF3,42,16
b $6D1D Packed sprite set 11 (op $97): 4 columns of 3 chars; flag bytes, set bit = literal byte, clear = 0
B $6D1D,2
B $6D1F,97,16
b $6D80 Packed sprite set 12 (op $97): 4 columns of 2 chars; flag bytes, set bit = literal byte, clear = 0
B $6D80,2
B $6D82,68,16
b $6DC6 Packed sprite set 13 (op $97): 4 columns of 2 chars; flag bytes, set bit = literal byte, clear = 0
B $6DC6,2
B $6DC8,45,16
b $6DF5 Packed sprite set 14 (op $97): 30 columns of 3 chars; flag bytes, set bit = literal byte, clear = 0
B $6DF5,2
B $6DF7,587,16
b $7042 Packed sprite set 15 (op $97): 4 columns of 2 chars; flag bytes, set bit = literal byte, clear = 0
B $7042,2
B $7044,48,16
b $7074 Packed sprite set 16 (op $97): 4 columns of 4 chars; flag bytes, set bit = literal byte, clear = 0
B $7074,2
B $7076,65,16
b $70B7 Packed sprite set 17 (op $97): 4 columns of 3 chars; flag bytes, set bit = literal byte, clear = 0
B $70B7,2
B $70B9,85,16
b $710E Packed sprite set 18 (op $97): 4 columns of 3 chars; flag bytes, set bit = literal byte, clear = 0
B $710E,2
B $7110,89,16
b $7169 Packed sprite set 19 (op $97): 2 columns of 2 chars; flag bytes, set bit = literal byte, clear = 0
B $7169,2
B $716B,20,16
b $717F Parchment frame tiles: 12 8x8 bitmaps, read by $9CB7
B $717F,96,8
b $71DF Parchment frame layout for $9C96: screen position, then per column 24 cells (1,n = n blank cells; k>1 = tile k-2), 0 ends
W $71DF,2
B $71E1,24,16
B $71F9,4
B $71FD,4
B $7201,4
B $7205,4
B $7209,4
B $720D,4
B $7211,4
B $7215,4
B $7219,4
B $721D,24,16
B $7235,1
w $7236 Room script addresses (rooms 0-25), read by $86B9
W $7236,52,8
b $726A Room 0 script: intro text (messages 38-42)
B $726A,2
B $726C,6
B $7272,6
B $7278,6
B $727E,3
B $7281,2
B $7283,3
B $7286,2
B $7288,3
B $728B,2
B $728D,3
B $7290,2
B $7292,3
B $7295,2
B $7297,6
B $729D,2
B $729F,1
b $72A0 Room 1 script: A prayer of Hope
B $72A0,2
B $72A2,3
B $72A5,3
B $72A8,7
B $72AF,5
B $72B4,5
B $72B9,5
B $72BE,11
B $72C9,11
B $72D4,21,16
B $72E9,7
B $72F0,1
b $72F1 Room 2 script: Tower of the Bell
B $72F1,2
B $72F3,2
B $72F5,3
B $72F8,3
B $72FB,6
B $7301,3
B $7304,14
B $7312,6
B $7318,11
B $7323,3
B $7326,10
B $7330,13
B $733D,13
B $734A,13
B $7357,1
b $7358 Script: block pattern 2x2 (op $88)
B $7358,7
B $735F,1
b $7360 Script: block pattern 2x2 (op $88)
B $7360,7
B $7367,1
b $7368 Room 3 script: Wine supplies
B $7368,2
B $736A,3
B $736D,3
B $7370,3
B $7373,14
B $7381,6
B $7387,6
B $738D,9
B $7396,13
B $73A3,13
B $73B0,13
B $73BD,1
b $73BE Room 4 script
B $73BE,2
B $73C0,6
B $73C6,6
B $73CC,3
B $73CF,3
B $73D2,14
B $73E0,3
B $73E3,5
B $73E8,6
B $73EE,11
B $73F9,15
B $7408,11
B $7413,9
B $741C,7
B $7423,9
B $742C,20,16
B $7440,2
B $7442,1
b $7443 Script: block pattern 2x2 (op $88)
B $7443,7
B $744A,1
b $744B Script: block pattern 2x2 (op $88)
B $744B,7
B $7452,1
b $7453 Room 5 script: Escape !!!
B $7453,2
B $7455,2
B $7457,3
B $745A,3
B $745D,14
B $746B,3
B $746E,30,16
B $748C,19,16
B $749F,17,16
B $74B0,13
B $74BD,17,16
B $74CE,6
B $74D4,58,16
B $750E,4
B $7512,4
B $7516,2
B $7518,1
b $7519 Room 6 script: Death is close
B $7519,2
B $751B,2
B $751D,3
B $7520,3
B $7523,3
B $7526,5
B $752B,3
B $752E,5
B $7533,5
B $7538,14
B $7546,15
B $7555,9
B $755E,5
B $7563,11
B $756E,11
B $7579,11
B $7584,10
B $758E,13
B $759B,9
B $75A4,7
B $75AB,7
B $75B2,9
B $75BB,7
B $75C2,17,16
B $75D3,4
B $75D7,4
B $75DB,5
B $75E0,1
b $75E1 Room 7 script: Abandoned church
B $75E1,2
B $75E3,3
B $75E6,3
B $75E9,14
B $75F7,4
B $75FB,3
B $75FE,5
B $7603,5
B $7608,26,16
B $7622,3
B $7625,10
B $762F,9
B $7638,13
B $7645,17,16
B $7656,11
B $7661,27,16
B $767C,11
B $7687,7
B $768E,4
B $7692,4
B $7696,4
B $769A,5
B $769F,1
b $76A0 Script: tiles drawn when flag $851A is set (room 7), also run by $A615
B $76A0,7
B $76A7,1
b $76A8 Script: tiles run by $A615 (room 7 animation)
B $76A8,7
B $76AF,1
b $76B0 Script: block pattern 2x2 (op $88)
B $76B0,7
B $76B7,1
b $76B8 Room 8 script: The Altar
B $76B8,2
B $76BA,2
B $76BC,3
B $76BF,7
B $76C6,5
B $76CB,5
B $76D0,9
B $76D9,5
B $76DE,10
B $76E8,17,16
B $76F9,3
B $76FC,14
B $770A,7
B $7711,10
B $771B,7
B $7722,10
B $772C,7
B $7733,11
B $773E,4
B $7742,4
B $7746,10
B $7750,12
B $775C,7
B $7763,7
B $776A,7
B $7771,5
B $7776,7
B $777D,5
B $7782,1
b $7783 Script: rectangle drawn when flag $851B is set (room 8)
B $7783,6
B $7789,1
b $778A Script: tiles drawn by flag $851A/$851D/$851F (rooms 6, 8, 20)
B $778A,7
B $7791,1
b $7792 Room 9 script: Hangman tree
B $7792,2
B $7794,2
B $7796,2
B $7798,3
B $779B,13
B $77A8,5
B $77AD,9
B $77B6,10
B $77C0,3
B $77C3,10
B $77CD,5
B $77D2,5
B $77D7,11
B $77E2,11
B $77ED,6
B $77F3,6
B $77F9,6
B $77FF,9
B $7808,7
B $780F,7
B $7816,13
B $7823,7
B $782A,7
B $7831,7
B $7838,9
B $7841,4
B $7845,4
B $7849,4
B $784D,4
B $7851,25,16
B $786A,1
b $786B Room 10 script: Pestilent Beast
B $786B,2
B $786D,2
B $786F,2
B $7871,3
B $7874,3
B $7877,42,16
B $78A1,3
B $78A4,18,16
B $78B6,6
B $78BC,21,16
B $78D1,15
B $78E0,19,16
B $78F3,35,16
B $7916,13
B $7923,7
B $792A,4
B $792E,4
B $7932,7
B $7939,7
B $7940,7
B $7947,7
B $794E,6
B $7954,1
b $7955 Script: block pattern 2x2 (op $88)
B $7955,7
B $795C,1
b $795D Room 11 script: Cave of illusions
B $795D,2
B $795F,2
B $7961,3
B $7964,3
B $7967,5
B $796C,23,16
B $7983,25,16
B $799C,9
B $79A5,3
B $79A8,22,16
B $79BE,17,16
B $79CF,23,16
B $79E6,7
B $79ED,15
B $79FC,21,16
B $7A11,6
B $7A17,6
B $7A1D,6
B $7A23,7
B $7A2A,1
b $7A2B Script: block pattern 2x2 (op $88)
B $7A2B,7
B $7A32,1
b $7A33 Room 12 script: Plagued ruins
B $7A33,2
B $7A35,2
B $7A37,2
B $7A39,3
B $7A3C,3
B $7A3F,38,16
B $7A65,5
B $7A6A,5
B $7A6F,15
B $7A7E,9
B $7A87,13
B $7A94,29,16
B $7AB1,7
B $7AB8,4
B $7ABC,4
B $7AC0,7
B $7AC7,1
b $7AC8 Script: block pattern 2x2 (op $88)
B $7AC8,7
B $7ACF,1
b $7AD0 Room 13 script: Catacombs
B $7AD0,2
B $7AD2,2
B $7AD4,3
B $7AD7,3
B $7ADA,5
B $7ADF,31,16
B $7AFE,8
B $7B06,7
B $7B0D,7
B $7B14,19,16
B $7B27,25,16
B $7B40,13
B $7B4D,1
b $7B4E Room 14 script: Hidden garden
B $7B4E,2
B $7B50,2
B $7B52,3
B $7B55,3
B $7B58,38,16
B $7B7E,3
B $7B81,14
B $7B8F,5
B $7B94,5
B $7B99,21,16
B $7BAE,15
B $7BBD,23,16
B $7BD4,13
B $7BE1,4
B $7BE5,7
B $7BEC,1
b $7BED Room 15 script: Gloomy tunels
B $7BED,2
B $7BEF,2
B $7BF1,3
B $7BF4,3
B $7BF7,5
B $7BFC,31,16
B $7C1B,27,16
B $7C36,5
B $7C3B,7
B $7C42,21,16
B $7C57,19,16
B $7C6A,17,16
B $7C7B,4
B $7C7F,4
B $7C83,4
B $7C87,7
B $7C8E,1
b $7C8F Room 16 script: Lake of despair
B $7C8F,2
B $7C91,3
B $7C94,3
B $7C97,42,16
B $7CC1,11
B $7CCC,3
B $7CCF,14
B $7CDD,43,16
B $7D08,9
B $7D11,23,16
B $7D28,13
B $7D35,13
B $7D42,12
B $7D4E,4
B $7D52,4
B $7D56,6
B $7D5C,5
B $7D61,1
b $7D62 Room 17 script: The wheel of faith
B $7D62,2
B $7D64,2
B $7D66,3
B $7D69,3
B $7D6C,70,16
B $7DB2,11
B $7DBD,21,16
B $7DD2,19,16
B $7DE5,7
B $7DEC,7
B $7DF3,4
B $7DF7,1
b $7DF8 Room 18 script: Banquet of Death
B $7DF8,2
B $7DFA,2
B $7DFC,2
B $7DFE,3
B $7E01,6
B $7E07,7
B $7E0E,26,16
B $7E28,6
B $7E2E,43,16
B $7E59,15
B $7E68,21,16
B $7E7D,17,16
B $7E8E,29,16
B $7EAB,19,16
B $7EBE,19,16
B $7ED1,1
b $7ED2 Room 19 script: Underground river
B $7ED2,2
B $7ED4,3
B $7ED7,3
B $7EDA,78,16
B $7F28,5
B $7F2D,5
B $7F32,18,16
B $7F44,17,16
B $7F55,15
B $7F64,9
B $7F6D,4
B $7F71,4
B $7F75,5
B $7F7A,5
B $7F7F,7
B $7F86,1
b $7F87 Script: tiles drawn when flag $851C is 0 (room 19)
B $7F87,7
B $7F8E,1
b $7F8F Room 20 script: Unexpected gate
B $7F8F,2
B $7F91,2
B $7F93,2
B $7F95,3
B $7F98,11
B $7FA3,18,16
B $7FB5,3
B $7FB8,46,16
B $7FE6,6
B $7FEC,6
B $7FF2,6
B $7FF8,9
B $8001,17,16
B $8012,7
B $8019,13
B $8026,4
B $802A,13
B $8037,11
B $8042,5
B $8047,1
b $8048 Script: rectangle run by $A75A
B $8048,6
B $804E,1
b $804F Room 21 script: Evil church
B $804F,2
B $8051,2
B $8053,2
B $8055,3
B $8058,3
B $805B,18,16
B $806D,3
B $8070,10
B $807A,3
B $807D,5
B $8082,3
B $8085,5
B $808A,27,16
B $80A5,3
B $80A8,22,16
B $80BE,49,16
B $80EF,4
B $80F3,4
B $80F7,4
B $80FB,1
B $80FC,7
B $8103,1
b $8104 Script: block pattern 2x2 (op $88)
B $8104,7
B $810B,1
b $810C Script: block pattern 2x2 (op $88)
B $810C,7
B $8113,1
b $8114 Script: block pattern 2x2 (op $88)
B $8114,7
B $811B,1
b $811C Script: block pattern 2x2 (op $88)
B $811C,7
B $8123,1
b $8124 Script: block pattern 2x2 (op $88)
B $8124,7
B $812B,1
b $812C Room 22 script: Tortured souls
B $812C,2
B $812E,2
B $8130,2
B $8132,2
B $8134,2
B $8136,3
B $8139,3
B $813C,22,16
B $8152,6
B $8158,3
B $815B,5
B $8160,3
B $8163,10
B $816D,3
B $8170,22,16
B $8186,11
B $8191,18,16
B $81A3,6
B $81A9,15
B $81B8,9
B $81C1,1
B $81C2,1
b $81C3 Room 23 script: Ashes to ashes
B $81C3,2
B $81C5,2
B $81C7,2
B $81C9,2
B $81CB,3
B $81CE,3
B $81D1,5
B $81D6,15
B $81E5,3
B $81E8,10
B $81F2,3
B $81F5,14
B $8203,13
B $8210,15
B $821F,11
B $822A,15
B $8239,6
B $823F,31,16
B $825E,5
B $8263,1
B $8264,7
B $826B,1
b $826C Room 24 script: Satan !!!
B $826C,2
B $826E,2
B $8270,2
B $8272,3
B $8275,3
B $8278,5
B $827D,3
B $8280,5
B $8285,15
B $8294,11
B $829F,15
B $82AE,7
B $82B5,7
B $82BC,7
B $82C3,11
B $82CE,1
B $82CF,1
b $82D0 Room 25 script (the ending): room 24 again
B $82D0,3
B $82D3,1
b $82D4 Script: the twelve crosses (tile $80 at 12 positions; $82D7 is also read by $AE4B), run by $BB57
B $82D4,3
B $82D7,24,2
B $82EF,1
b $82F0 Script: room frame and title bar, prints the room name (message ($850D))
B $82F0,6
B $82F6,6
B $82FC,6
B $8302,3
B $8305,3
B $8308,2
B $830A,1
b $830B Script: block pattern 2x2 (op $88)
B $830B,7
B $8312,5
B $8317,18,16
B $8329,1
b $832A Script: parchment text (messages ($850E) and ($850F)), run by $9C52
B $832A,6
B $8330,6
B $8336,3
B $8339,3
B $833C,3
B $833F,3
B $8342,2
B $8344,1
b $8345 Script: ending text 1 (messages 43-45), run by $887B
B $8345,6
B $834B,6
B $8351,3
B $8354,2
B $8356,3
B $8359,2
B $835B,3
B $835E,2
B $8360,2
B $8362,1
b $8363 Script: ending text 2 (messages 46-48), run by $887B
B $8363,6
B $8369,6
B $836F,3
B $8372,2
B $8374,3
B $8377,2
B $8379,3
B $837C,2
B $837E,2
B $8380,1
b $8381 Script: final text (messages 49-52), run by $887B
B $8381,6
B $8387,6
B $838D,3
B $8390,2
B $8392,3
B $8395,2
B $8397,3
B $839A,2
B $839C,3
B $839F,2
B $83A1,6
B $83A7,1
b $83A8 Cutscene actor lists for $8870: count (to $8552), then 4-byte records (word $BDxx, x, y) copied to $5DC0 with one byte more
B $83A8,1
B $83A9,4
B $83AD,1
B $83AE,4
B $83B2,4
B $83B6,4
B $83BA,4
B $83BE,4
B $83C2,4
B $83C6,4
B $83CA,4
c $83CE Unused debug: move between rooms with the controls (jumped to from $AAAF when $A894=$FF)
b $83E6 Music track for each room (0-25), copied to $8551 by $86B9
B $83E6,26,13
b $8400 IM 2 vector table (I=$84): 257 bytes $85, all to $8585
S $8400,257,257:$85
g $8501 Cutscene finished flag (set by $B1CF/$B97D, polled by $88DE)
g $8502 Title screen: word written by $A43D, read by $A3B9
B $8502,2,2
g $8504 Address of the routine the interrupt calls
B $8504,2,2
g $8506 Machine type (1 = 48K)
g $8507 128K: last byte sent to port $7FFD
g $8508 Unused
g $8509 Room number (0-24; 25 = the ending)
g $850A End marker ($1A) of the room-keyed tables, read with $8509 as a word
g $850B Room flag read by $9B5A (cleared at game start)
g $850C Room state ($80 playing, 1 enter, 2 checkpoint, 3 game over, 4, 5 ending)
g $850D Room name message number (script op $87)
g $850E Parchment message numbers (written by $A836)
B $850E,2,2
g $8510 Counter for $AE20
g $8511 Cross animation delay for $AE4B
g $8512 Checkpoint position (two words, to $A8A1/$A8A3)
B $8512,4,2
g $8516 Two words for $A851/$A8A5
B $8516,4,2
g $851A Flag $851A (scripts, $A615)
g $851B Object flags ($FF = gone) read by $896B; $851B-$851F also test scripts
B $851B,6,6
g $8521 Flag read by $A668/$A734/$BB57
g $8522 Flag read by $B6E6
g $8523 Bytes for $A6D8
B $8523,2,2
g $8525 Object flags read by $896B
B $8525,28,14
g $8541 Twelve crosses: count drawn, done flag ($AE4B)
B $8541,2,2
g $8543 Nine bytes reset together by $A688
B $8543,9,9
g $854C Lives (HUD, $9BF3)
g $854D Crosses collected (HUD, $9C1B)
g $854E Sound effect playing
g $854F Sound effect requested
g $8550 Unused
g $8551 Music track (128K player)
g $8552 Cutscene actor count
b $8553 Cross colour cycle: 6 attributes for $AE4B
B $8553,6
g $8559 Variables for $B44B
B $8559,4
g $855D Word for $9719/$97B7
W $855D,2
b $855F Interrupt stack (SP=$8585 in the handler)
S $855F,38,38:$FF
c $8585 IM 2 interrupt handler: calls the routine at ($8504) on its own stack
c $85BC Jump to HL
c $85BD Unused RET
c $85BE 128K: page in bank 0
c $85C2 128K: call DE in the music bank
c $85CA 128K: page in bank A
c $85D5 128K: sound effect through the AY player (replaces $871A)
c $85E2 Frame routine: sound effect, then the game frame at $A596
c $85E8 128K: music player entry points
c $85FC Game start and main loop
c $86B9 Enter a room
c $871A Beeper sound effects
c $87D7 Random byte for the noise effect
g $87E8 Noise pointer into the ROM
W $87E8,2
g $87EA Current sound effect (8 bytes, from $87F2)
B $87EA,8
b $87F2 Sound effects 2-9 for $871A: 8 bytes each
B $87F2,64,8
c $8832 Title: room 0 until a key is pressed
c $8869 Wait for the frame flag at $BDDA
c $8870 Load a cutscene actor list
c $887B Ending sequence
c $88DE Run a cutscene until $8501 is set
c $88FE Cutscene: no free actor slot
c $8905 Spawn the cutscene actors from $5DC0
c $8957 Spawn the room's objects (table $8EDF)
c $896B Spawn one object unless its flag is $FF
c $897E Spawn an object
c $89D9 Spawn the room's enemies (table $8B8F)
c $89ED Spawn an enemy
c $8A6E Find a free actor slot at $C100
i $8A8F
