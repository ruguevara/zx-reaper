import sys
from collections import Counter
from skoolkit.snapshot import Snapshot
ram = Snapshot.get(sys.argv[1] if len(sys.argv)>1 else 're/image.z80').ram(-1)
def b(a): return ram[a-0x4000]
first = b(0xA3FF)
print('first item index', hex(first), 'count', 256-first)
cnt = Counter(); rows=[]
for i in range(first, 256):
    t = b(0xA400+i); p = b(0xA500+i)
    room = t & 0x3F; flag6=(t>>6)&1; half=t>>7
    col = p & 0x1F; row = ((p>>5)&7) + 8*half
    name = bytes(b(0xC000+256*room+0x80+k) for k in range(32)).decode('latin1').strip()
    cnt[room]+=1
    rows.append((i,room,name,col,row,flag6,half,t,p))
for r in rows: print('%02X room %02X %-32s x(col)=%2d y(row)=%2d bit6=%d half=%d  [%02X %02X]'%r)
print('per room:')
for room in sorted(cnt):
    name = bytes(b(0xC000+256*room+0x80+k) for k in range(32)).decode('latin1').strip()
    print('%02X %-32s %d'%(room,name,cnt[room]))
print('rooms with items',len(cnt),'total',sum(cnt.values()))
print('bit6 set at load:', sum(1 for r in rows if r[5]))
# duplicates
pos=Counter((r[1],r[3],r[4]) for r in rows)
print('duplicate positions', [k for k,v in pos.items() if v>1])
