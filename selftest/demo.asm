; Self-test fixture: a tiny "game" that plays the role of an unknown original.
; Collect stars with Q/A/O/P or a Kempston joystick. Never shipped as source
; to the pipeline: only demo.tap built from it is used.

ATTR    equ 22528
LAST_K  equ 23560

        org 32768
start:  di
        ld sp,stack
        xor a
        out (254),a
        call cls
        ld hl,title
        ld de,16384+32*0+8
        call print
        ei
mainlp: halt
        ld a,(tick)
        inc a
        ld (tick),a
        call input
        call move
        call check
        ld a,(timer)
        dec a
        ld (timer),a
        jr nz,mainlp
        jp gameover

; Read keys into A as bits 0-3 = right,left,down,up
input:  ld c,0
        ld a,0xfb       ; Q row
        in a,(254)
        rra
        jr c,1f
        set 3,c
1:      ld a,0xfd       ; A row
        in a,(254)
        rra
        jr c,2f
        set 2,c
2:      ld a,0xdf       ; P/O row
        in a,(254)
        rra
        jr c,3f
        set 0,c
3:      rra
        jr c,4f
        set 1,c
4:      in a,(31)
        and 15
        or c
        ld (keys),a
        ret

move:   ld a,(keys)
        or a
        ret z
        ld b,4
        ld hl,dirtab
mv1:    rra
        jr c,mv2
        inc hl
        inc hl
        djnz mv1
        ret
mv2:    ld e,(hl)
        inc hl
        ld d,(hl)
        ex de,hl
        jp (hl)

dirtab: dw right,left,down,up

right:  ld a,(px)
        cp 31
        ret z
        inc a
        ld (px),a
        ret
left:   ld a,(px)
        or a
        ret z
        dec a
        ld (px),a
        ret
down:   ld a,(py)
        cp 23
        ret z
        inc a
        ld (py),a
        ret
up:     ld a,(py)
        cp 1
        ret z
        dec a
        ld (py),a
        ret

; Paint player cell; collect star if present
check:  call cellad
        ld a,(hl)
        cp 0x16         ; star colour
        jr nz,ch1
        call beep
smc:    ld a,0          ; self-modified score counter
        inc a
        ld (smc+1),a
ch1:    ld (hl),0x38+0x40+2
        ld a,(tick)
        and 31
        ret nz
        ld a,(tick)
        rlca
        rlca
        and 0x1f
        ld l,a
        ld h,0
        ld de,ATTR+32*12
        add hl,de
        ld (hl),0x16
        ret

; HL = attribute address of player
cellad: ld a,(py)
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        ld a,(px)
        ld e,a
        ld d,0
        add hl,de
        ld de,ATTR
        add hl,de
        ret

beep:   push hl
        ld b,40
bp1:    ld a,16
        out (254),a
        ld c,b
bp2:    dec c
        jr nz,bp2
        xor a
        out (254),a
        djnz bp1
        pop hl
        ret

cls:    ld hl,16384
        ld de,16385
        ld bc,6144
        ld (hl),0
        ldir
        ld bc,767
        ld (hl),0x38
        ldir
        ret

; Print bit-7-terminated string at HL to screen address DE using ROM font
print:  ld a,(hl)
        push hl
        push de
        and 0x7f
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        ld bc,0x3c00
        add hl,bc
        ld b,8
pr1:    ld a,(hl)
        ld (de),a
        inc hl
        inc d
        djnz pr1
        pop de
        pop hl
        inc de
        bit 7,(hl)
        inc hl
        jr z,print
        ret

gameover:
        di
        ld hl,overmsg
        ld de,16384+32*0+11
        call print
        ld a,(smc+1)
        cp 200          ; only a perfect run reaches this
        jr nz,go1
        ld a,4
        out (254),a
go1:    halt

title:  db "STAR GRABBE",'R'+128
overmsg: db "GAME OVE",'R'+128
px:     db 16
py:     db 12
tick:   db 0
keys:   db 0
timer:  db 250
        ds 64,0x55
stack:
        db "end"
