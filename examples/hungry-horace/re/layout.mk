# Written by zxinit.py
REGION_START := 0x5FB5
REGION_END := 0x8000
ENTRY_PC := 0x6000
ENTRY_IN_REGION := 1
IMAGE_PATCHES := --patch 24501,re/tape/09.bin
PORT_ENTRY := main.Start
PORT_CHECKPOINT := MainLoop
PORT_STATE := --state 0x4000-0x5B00 --state 0x5C78-0x5C7B --state $(REGION_START)-$(REGION_END)
