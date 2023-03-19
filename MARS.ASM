;
; w.bruzda@uj.edu.pl
;
; *************************************************
; * MARS.EXE from 1993 by Tim J. Clarke REVISITED *
; *************************************************
;
; -----------------------------------------------------------------------------
; 2021-03-14 playing with MARS_WWP.EXE from the old resources (1995-05-09)
;   WWP is an executable files packer
;   by Piotr Warężak and Rafał Wierzbicki
;   https://www.wwpack32.venti.pl
; -----------------------------------------------------------------------------
; 2021-03-16 1st serious attempt to disassembling original MARS.EXE
;            it is also possible to disassemble MARS_WWP, although
;            this is really exhausting job
; -----------------------------------------------------------------------------
; 2021-03-19 disassembling MARS.EXE
; 2021-03-20 disassembling MARS.EXE
; 2021-03-21 disassembling MARS.EXE
; 2021-03-22 sky and terra are now correctly generated in 2-D
;            problems with the "ladder" before 0fe8h
;            sky is smoothly moving when the 5th call (@0a1fh) is off
; -----------------------------------------------------------------------------
; 2021-03-23 to avoid a big mess segments are realigned
;   to four 65535 blocks at 24d1, 34d1, 44d1, 54d1
;   and one extra for ss at 64d1 (eventually abandoned)
;   of course I do not care about RAM allocation
;                                     --> "640K ought to be enough for anybody"
; -----------------------------------------------------------------------------
; 2021-03-24 recovering "missing" data in the "ds" segment
;            contour of hills is being drawn
; 2021-03-24 almost done - hills are filled
;            althouhgh there are some artifacts in the vicinity of 0b3eh :/
; -----------------------------------------------------------------------------
; 2021-03-25 1st final fix:
;            _03a6 dd ?
;            _03a8 db ? ; for "adc bl, ..."
;            the issue was in "adc" of the lower part of "double-word" variable
;            now it is taken directly from the run-time memory
;            but there is still a little glitch when drawing highest hills...
; 2021-03-25 2nd final fix:
;            no glitches at all! DONE AGAIN AFTER 28 YEARS :)
;            (well, the original algorithm is not so perfect either, sometimes
;             one can see little anomalies...)
;            remember, when under DOSBOX, always use
;            $ DOSBOX . -machine vgaonly
; -----------------------------------------------------------------------------
; 2021-03-26 clean code
;            data compression
;            MARS.COM has 2126 bytes and still can be reduced far below 2.0kB!
; -----------------------------------------------------------------------------
; 2021-03-27 palette compression
;            MARS.COM has 1828 bytes and still can be reduced far below 1.5kB!
; 2021-03-27 plasma algorithm compression and other repetitions removed
;            MARS.COM has 1517 bytes and still can be reduced below 1.5kB!
; -----------------------------------------------------------------------------


; references:
;   https://hornet.org/cgi-bin/scene-search.cgi?search=Tim%20Clarke
;   https://www.youtube.com/watch?v=_zSjpIyMt0k
;   https://www.shadertoy.com/view/XdsGWH


; helpful links:
;   http://www.os2museum.com/wp/who-needs-the-address-wraparound-anyway/
;   https://en.wikipedia.org/wiki/X86_memory_segmentation
;   https://www.aldeid.com/wiki/X86-assembly/Instructions/or
;   https://www.calculator.net/hex-calculator.html?b2dnumber1=20&calctype=b2d&x=0&y=0#hex2decimal
;   https://www.csie.ntu.edu.tw/~acpang/course/asm_2004/slides/chapt_07_PartISolve.pdf
;   https://stanislavs.org/helppc/int_33-5.html
;   https://8086assembly.blogspot.com/2017/11/logical-instructions-and-or-xor-not.html
;
;   pictorial ASCII table:
;   http://maettig.com/media/dos/system-tools/basic-snippets-power-test-ascii-table.png
;
;


; ------------------------------------------------------------------------------
.model tiny
.code
.386
        org 100h
start: ; mov ax, 064d1h ; without stack relocation...
       ; mov ss, ax
       ; mov sp, 0400h

        mov es, cs:[_0345]
        xor di, di
        mov ax, 0b3eh   ; load data to [_0345]:0000
        mov cx, 00c8h   ; from 0b3e to 0fe8
_load1: stosw           ; see _fill below...
        add ax, 0006
        loop _load1
        xor ax, ax
        mov cl, 0029h
_load2: stosw
        inc ax
        loop _load2
        inc ax ; ax = 029h
        inc ax ; ax = 02ah
        mov cl, 000ah
_load3: stosw
        inc ax
        inc ax
        loop _load3
        mov al, 0040h
        mov cl, 000ah
_load4: stosw
        add al, 04
        loop _load4
;      cld
        xor ah, ah
        int 1ah
        and dh, 7fh
        mov cs:[_035d], dx
        mov ax, 0013h
        int 10h
        xor ax, ax
        int 33h
        cmp ax, 0ffffh
        setz byte ptr cs:[mouse]

;        lea si, cs:[palette] ; try -1 or +1 to get green or blue shades
        cli
;        mov dx, 03c8h        ; original palette
;        xor al, al
;        out dx, al
;        inc dx
;        mov cx, 0300h
;        rep outsb            ; [ds:si++] ---> [dx] (cx--)

        xor bx, bx            ; new shades of terra
        xor ax, ax
p1:     push ax
        mov cl, 0040h
p2:     mov dx, 03c8h
        out dx, al
        inc dx
        push ax
        mov al, bl
        out dx, al
        inc bl
        mov al, bh
        out dx, al
        out dx, al
        pop ax
        inc al
        loop p2
        pop ax
        add bx, 941eh         ; new shades of sky
        add al, 40h
        cmp al, 80h
        jne p1
        sti

        call _00f3 ; prepare cloudy sky
        call _0153 ; prepare terrain

        mov byte ptr cs:[key_pressed], 00
        mov word ptr cs:[_0351], 03e8h
        mov word ptr cs:[_0353], 03e8h
_00bc:  mov es, cs:[_0345]
        call _0408
        call _0459
        call _0a1f
        mov si, 07aah
        mov ax, 0a000h
        mov es, ax
        mov di, 0020h
        mov bl, 0c8h

        push ds
        mov ds, cs:[_0345]
_00d1:  mov cx, 0040h
        rep movsd
        add di, 40h
        dec bl
        jne short _00d1
        pop ds

        cmp byte ptr cs:[key_pressed], 00
        je short _00bc
        mov ax, 0003
        int 10h
        mov ah, 4ch
        int 21h
;-------------------------------------------------------------------------------
_00f3:  mov es, cs:[_034b]
        xor di, di
        mov ax, 0ffffh ; clear the sky
        mov cx, 8000h
        rep stosw
        mov ax, 00abh
        mul word ptr cs:[_035d]
        add ax, 2bcdh
        adc dx, +00
        div word ptr cs:[_034d]
        mov cs:[_035d], dx
        mov si, dx
        mov byte ptr es:[0000h], 0
        mov byte ptr es:[0080h], 0feh
        mov byte ptr es:[8000h], 0feh
        mov byte ptr es:[8080h], 0
        push +00
        push 0100h
        call _0219
        add sp, +04
        xor di, di
_0141:  mov al, es:[di]
        shr al, 03
        add al, 40h
        stosb     ; ax ---> [es:di++] (cx--)
        or di, di ; ZF | SF | result
                  ; 0  | 0  | di > 0
                  ; 1  | 0  | di = 0
                  ; 0  | 1  | di < 0
        jnz short _0141
        ret
;-------------------------------------------------------------------------------
_0153:  mov es, cs:[_0347]
        mov fs, cs:[_0349]
        xor di, di
        mov ax, 0ffffh
        mov cx, 8000h
        rep stosw
        mov ax, 00abh
        mul word ptr cs:[_035d]
        add ax, 2bcdh
        adc dx, +00
        div word ptr cs:[_034d]
        mov cs:[_035d], dx
        mov si, dx
        mov byte ptr es:[0000], 0080h
        push +00
        push 0100h
        call _0219
        add sp, +04
        xor si, si
_019a:  mov al, es:[si]
        xor ah, ah
        add al, es:[si+4]
        adc ah, 00
        add al, es:[si+0202h]
        adc ah, 00
        add al, es:[si+0feffh]
        adc ah, 00
        shr ax, 02
        mov es:[si], al
        inc si
        jnz _019a
        xor si, si
_01cc:  mov al, es:[si]
        xor ah, ah
        sub al, es:[si + 03]
        sbb ah, 00
        add ax, 0020h
        jns short _01df
        xor ax, ax
_01df:  cmp ax, 003fh
        jbe short _01e7
        mov ax, 003fh
_01e7:  mov fs:[si], al
        inc si
        jnz short _01cc
        xor si, si
_01ef:  mov al, es:[si]
        xor ah, ah
        add al, es:[si + 01]
        adc ah, 00
        add al, es:[si + 0100h]
        adc ah, 00
        add al, es:[si + 0101h]
        adc ah, 00
        shr ax, 02
        mov es:[si], al
        inc si
        jnz short _01ef
        ret
;-------------------------------------------------------------------------------
_0219:  mov bp, sp
        mov bx, ss:[bp + 04]
        mov cx, ss:[bp + 02]
        shr cx, 1
        mov dl, es:[bx]
        add bl, cl
        mov di, bx
        add bl, cl
	call _cr03
        add bh, cl
        mov di, bx
        add bh, cl
	call _cr03
        sub bl, cl
        mov di, bx
        sub bl, cl
	call _cr03
        sub bh, cl
        mov di, bx
        sub bh, cl
	call _cr03
        xor dh, dh
        add bl, cl
        add bl, cl
        add dl, es:[bx]
        adc dh, 00
        add bh, cl
        add bh, cl
        add dl, es:[bx]
        adc dh, 00
        sub bl, cl
        sub bl, cl
        add dl, es:[bx]
        adc dh, 00
        shr dx, 02
	call _cr05
        js short _03ca
        cmp ax, 00feh
        jbe short _03cc
        mov al, 0feh
        jmp short _03cc
_03ca:  xor al, al
_03cc:  add bl, cl
        sub bh, cl
        mov es:[bx], al
        cmp cl, 01
        jz short _0407
        xor ch, ch
        sub bl, cl
        sub bh, cl
        push bx
        push cx
        call _0219
        mov bp, sp
        mov cl, ss:[bp + 00]
        add ss:[bp + 02], cl
        call _0219
        mov bp, sp
        mov cl, ss:[bp + 00]
        add ss:[bp + 03], cl
        call _0219
        mov bp, sp
        mov cl, ss:[bp + 00]
        sub ss:[bp + 02], cl
        call _0219
        add sp, +04
_0407:  ret
_cr03:  cmp byte ptr es:[di], 0ffh
        jnz short _0276
        xor dh, dh
        add dl, es:[bx]
        adc dh, 00
        shr dx, 1
	call _cr05
        js short _0271
        cmp ax, 00feh
        jbe short _0273
        mov al, 0feh
        jmp short _0273
_0271:  xor al, al
_0273:  mov es:[di], al
_0276:  mov dl, es:[bx]
	ret
_cr05:  mov ch, dl
        mov ax, 00abh
        mul si
        add ax, 2bcdh
        adc dx, +00
        div word ptr cs:[_034d]
        mov si, dx
        sub dx, 67c2h
        mov al, cl
        xor ah, ah
        imul dx
        mov al, ah
        mov ah, dl
        sar ax, 05
        cbw
        add al, ch
        adc ah, 00
	ret
;-------------------------------------------------------------------------------
_0408:  cmp byte ptr cs:[mouse], 00
        jz short _0423
        mov ax, 000bh
        int 33h
_0423:  add cs:[_0351], cx
        sub cs:[_0353], dx
        mov cx, cs:[_0351]
        mov dx, cs:[_0353]
        mov cs:[_0355], cx
        mov cs:[_0357], dx
        call _105c
        add ah, 19h
        jae short _0446
        mov ax, 0ffffh
_0446:  mov cs:[_0359], ax
        mov ah, 01
        int 16h
        jz short _0458
        mov byte ptr cs:[key_pressed], 01
        xor ah, ah
        int 16h
_0458:  ret
;-------------------------------------------------------------------------------
_105c:  mov fs, cs:[_0347]
        ror cx, 04
        ror dx, 04
        mov bl, cl
        mov bh, dl
        shr cx, 0ch
        shr dx, 0ch
        inc bl
        mov al, fs:[bx]
        xor ah, ah
        dec bl
        sub al, fs:[bx]
        sbb ah, 00
        push dx
        imul cx
        mov dl, fs:[bx]
        xor dh, dh
        shl dx, 04
        add ax, dx
        pop dx
        mov si, ax
        inc bh
        inc bl
        mov al, fs:[bx]
        xor ah, ah
        dec bl
        sub al, fs:[bx]
        sbb ah, 00
        push dx
        imul cx
        mov dl, fs:[bx]
        xor dh, dh
        shl dx, 04
        add ax, dx
        pop dx
        mov di, ax
        mov ax, di
        sub ax, si
        imul dx
        shl si, 04
        add ax, si
        ret
;-------------------------------------------------------------------------------
_0459:  mov di, 07aah
        mov ecx, 00000063h
        xor eax, eax
        mov ax, cs:[_0359]
        neg ax
        shr ax, 03
        add ax, 4000h
        shl eax, 0dh
        mov cs:[_0360], eax
        xor eax, eax
        mov ax, cs:[_0355]
        shl eax, 09
        mov cs:[_0364], eax
        xor eax, eax
        mov ax, cs:[_0357]
        shl eax, 09
        mov cs:[_0368], eax
        push ds
        mov ds, cs:[_034b]
_049d:  mov eax, cs:[_0360]
        xor edx, edx
        div ecx
        mov esi, cs:[_0364]
        mov ebp, cs:[_0368]
        sub esi, eax
        add ebp, eax
        shr eax, 07
        mov bx, si
        shr esi, 10h
        and si, 00ffh
        shr ebp, 08
        and bp, 0ff00h
        or si, bp
        mov ebp, eax
        shr ebp, 10h
        dec bp
        movsb
        push cx
        mov cx, 00ffh
_04df:  add bx, ax
        adc si, bp
        movsb
        loop _04df
        pop cx
        dec cl
        jnz _049d
        pop ds
        mov ax, 5050h ; this is horizon :)
        mov cx, 0080h
        rep stosw
        mov si, cs:[_0359]
        shr si, 1
        add si, +0ah
        mov bx, 0004
_09f5:  mov ax, si
        xor dx, dx
        div bx
        shr ax, 07
        cmp ax, 003fh
        jbe short _0a05
        mov al, 3fh
_0a05:  mov ah, al
        mov dl, al
        shl ax, 10h
        mov al, dl
        mov ah, al
        mov cx, 80h
        rep stosw
        inc bl
        cmp bl, 2ch
        jnz _09f5
        ret
;-------------------------------------------------------------------------------
_0a1f:  mov fs, cs:[_0347]
        mov gs, cs:[_0349]
        mov eax, 7d007d00h
        mov di, 03aah
        mov cx, 0080h
        rep stosd
        xor eax, eax
        mov di, 05aah
        mov cx, 0080h
        rep stosd
        mov word ptr cs:[_03a0], 0078h
_0a48:  mov si, cs:[_03a0]
	mov ds, cs:[_0345]
        mov si, ds:[si + 0190h]
        shl si, 04
        mov ax, cs:[_0357]
        and ax, 000fh
        xor al, 0fh
        add si, ax
        mov ax, cs:[_0359]
        xor dx, dx
        div si
        add ax, 0064h
        mov cs:[_03a2], ax
        xor eax, eax
        mov ax, si
        shl eax, 06
        mov ds:[03a6h], eax
        cmp word ptr cs:[_03a0], +02
        jnz short _0a8c
        mov word ptr cs:[_03a2], 7d00h
        mov word ptr cs:[_03a4], 0000
        jmp short _0a96
_0a8c:  xor ax, ax
        mov dx, 0001
        div si
        mov cs:[_03a4], ax
_0a96:  xor ecx, ecx
        mov cx, cs:[_0355]
        shl ecx, 0ch
        mov eax, ds:[03a6h]
        shl eax, 07
        sub ecx, eax
        mov dx, cs:[_0357]
        shl dx, 04
        mov ebx, ecx
        shr ebx, 10h
        mov bh, dh
        mov ax, si
        shr ax, 04
        add bh, al
        shr cx, 1
        mov si, 01feh
        mov word ptr cs:[_0364], 07aah
_0ace:  shl cx, 1
        add cx, ds:[03a6h]
        adc bl, ds:[03a8h]
        shr cx, 1
        mov al, fs:[bx + 01]
        xor ah, ah
        sub al, fs:[bx]
        sbb ah, 00
        imul cx
        shrd ax, dx, 07
        add ah, fs:[bx]
        mul word ptr cs:[_03a4]
        mov di, cs:[_03a2]
        sub di, dx
        jns short _0afe
        mov di, 0ffffh
_0afe:  cmp di, 00c8h
        jl short _0b07
        mov di, 00c7h
_0b07:  mov bp, ds:[si + 03aah]
        mov ds:[si + 03aah], di
        sub bp, di
        jns short _101a
        shl di, 08
        add di, word ptr cs:[_0364]
        call _cr02
        mov dx, ax
        xchg ax, ds:[si + 05aah]
        push ax
        sub ax, dx
        cwd
        idiv bp
        pop dx
        shl bp, 1
comment #
_0b39:  jmp word ptr ds:[bp + 0190h]
_0b3e:  mov [di + 03900h], dh
#
        push bx
        push ax
        push dx
        xor dx, dx
        mov ax, word ptr ds:[bp + 0190h]
        sub ax, 0b3eh
        mov bx, 0006
        div bx
        shl ax, 8
        add ax, 3900h
        mov bx, ax
        pop dx
        pop ax
_fill:  mov ds:[di + bx], dh
        add dx, ax
        add bx, 0100h
        cmp bx, 0100h
        jne _fill
        pop bx
_0fe8:  mov ds:[di], dh
_cr01:  inc word ptr cs:[_0364]
        sub si,+02
        jns _0ace
        sub word ptr cs:[_03a0],+02
        mov si, cs:[_03a0]
        mov si, ds:[si + 0190h]
        test si, 0003
        jnz short _1010
        shr si, 02
_1010:  cmp word ptr cs:[_03a0], +00
        jnz _0a48
        ret
_101a:  call _cr02
        mov ds:[si + 05aah], ax
        jmp short _cr01
_cr02:  mov al, gs:[bx + 01]
        sub al, gs:[bx]
        imul ch
        shl ax, 1
        add ah, gs:[bx]
	ret
;===============================================================================

_0345 dw 024d1h ; offset of landscape
_0347 dw 034d1h ; offset of aux. array
_0349 dw 044d1h ; offset of terra
_034b dw 054d1h ; offset of sky
_034d dw 0cf85h
_0351 dw ?
_0353 dw ?
_0355 dw ?
_0357 dw ?
_0359 dw ?
_035d dw ?
_0360 dd ?
_0364 dd ?
_0368 dd ?
_03a0 dw ?
_03a2 dw ?
_03a4 dw ?

key_pressed db ?
mouse dw ?

comment #
palette db 00h, 00h, 00h ; 1st part
        db 01h, 00h, 00h
        db 02h, 00h, 00h
        db 03h, 00h, 00h
        db 03h, 00h, 00h ; 03 _01_ 00 in the original data
        db 04h, 00h, 00h
        db 05h, 00h, 00h
        db 06h, 00h, 00h
        db 07h, 00h, 00h
        db 08h, 00h, 00h ; 10
        db 09h, 00h, 00h
        db 0ah, 00h, 00h
        db 0bh, 00h, 00h
        db 0ch, 00h, 00h
        db 0dh, 00h, 00h
        db 0eh, 00h, 00h
        db 0fh, 00h, 00h
        db 10h, 00h, 00h
        db 11h, 00h, 00h
        db 12h, 00h, 00h ; 20
        db 13h, 00h, 00h
        db 14h, 00h, 00h
        db 15h, 00h, 00h
        db 16h, 00h, 00h
        db 17h, 00h, 00h
        db 18h, 00h, 00h
        db 19h, 00h, 00h
        db 1ah, 00h, 00h
        db 1bh, 00h, 00h
        db 1ch, 00h, 00h ; 30
        db 1dh, 01h, 00h
        db 1eh, 02h, 00h
        db 1fh, 03h, 00h
        db 20h, 04h, 00h
        db 21h, 05h, 00h
        db 22h, 06h, 00h
        db 23h, 07h, 01h
        db 24h, 08h, 02h
        db 25h, 09h, 03h
        db 26h, 0ah, 04h ; 40
        db 27h, 0bh, 05h
        db 28h, 0ch, 06h
        db 29h, 0dh, 07h
        db 2ah, 0eh, 08h
        db 2bh, 0fh, 09h
        db 2ch, 10h, 0ah
        db 2dh, 11h, 0bh
        db 2eh, 12h, 0ch
        db 2fh, 13h, 0dh
        db 30h, 14h, 0eh ; 50
        db 31h, 15h, 0fh
        db 32h, 16h, 10h
        db 33h, 17h, 11h
        db 34h, 18h, 12h
        db 35h, 19h, 13h
        db 36h, 1ah, 14h
        db 37h, 1bh, 15h
        db 38h, 1ch, 16h
        db 39h, 1dh, 17h
        db 3ah, 1eh, 18h ; 60
        db 3bh, 1fh, 19h
        db 3ch, 20h, 1ah
        db 3dh, 21h, 1bh
        db 3eh, 22h, 1ch
        db 32h, 0ah, 0ah ; 2nd part
        db 32h, 0bh, 0bh
        db 32h, 0ch, 0ch
        db 32h, 0dh, 0dh
        db 32h, 0eh, 0eh
        db 32h, 0fh, 0fh ; 70
        db 32h, 10h, 10h
        db 32h, 11h, 11h
        db 32h, 12h, 12h
        db 32h, 13h, 13h
        db 32h, 14h, 14h
        db 32h, 15h, 15h
        db 32h, 16h, 16h
        db 32h, 17h, 17h
        db 32h, 18h, 18h
        db 32h, 19h, 19h ; 80
        db 32h, 1ah, 1ah
        db 32h, 1bh, 1bh
        db 32h, 1ch, 1ch
        db 32h, 1dh, 1dh
        db 32h, 1eh, 1eh
        db 32h, 1fh, 1fh
        db 32h, 20h, 20h
        db 32h, 21h, 21h
        db 32h, 22h, 22h
        db 32h, 23h, 23h ; 90
        db 32h, 24h, 24h
        db 32h, 25h, 25h
        db 32h, 26h, 26h
        db 32h, 27h, 27h
        db 32h, 28h, 28h
        db 32h, 29h, 29h
#
end start
