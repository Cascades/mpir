
;  Copyright 1999, 2000, 2001, 2002 Free Software Foundation, Inc.
;
;  Copyright 2005, 2006 Pierrick Gaudry
;
;  Copyright 2008 Brian Gladman
;
;  This file is part of the MPIR Library.
;
;  The MPIR Library is free software; you can redistribute it and/or
;  modify it under the terms of the GNU Lesser General Public License as
;  published by the Free Software Foundation; either version 2.1 of the
;  License, or (at your option) any later version.
;
;  The MPIR Library is distributed in the hope that it will be useful,
;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;  Lesser General Public License for more details.
;
;  You should have received a copy of the GNU Lesser General Public
;  License along with the MPIR Library; see the file COPYING.LIB.  If
;  not, write to the Free Software Foundation, Inc., 51 Franklin Street,
;  Fifth Floor, Boston, MA 02110-1301, USA.

;  AMD64 mpn_mul_1 -- mpn by limb multiply.
;
;  Calling interface:
;  mp_limb_t mpn_mul_1 (
;     mp_ptr dst,                  rcx
;     mp_srcptr src,               rdx
;     mp_size_t size,               r8
;     mp_limb_t multiplier          r9
;  )
;
;  mp_limb_t mpn_mul_1c (
;     mp_ptr dst,                  rcx
;     mp_srcptr src,               rdx
;     mp_size_t size,               r8
;     mp_limb_t multiplier,         r9
;     mp_limb_t carry       [rsp+0x28]
;  )
;
; Multiply src[size] by mult and store the result in dst[size].  Return the
; carry limb from the top of the result.
;
; mpn_mul_1c() accepts an initial carry for the calculation, it's added into
; the low limb of the destination.
;
; Maximum possible UNROLL_COUNT with the current code is 64.
;
;  This is an SEH Leaf Function (no unwind support needed)

%if 1

%define dst         rcx
%define len          r8
%define mlt          r9
%define cry  [rsp+0x28]
%define src         r10     ; from rdx on input

%define UNROLL_LOG2     4
%define UNROLL_COUNT    (1 << UNROLL_LOG2)
%define UNROLL_MASK     (UNROLL_COUNT - 1)
%define UNROLL_BYTES    8 * UNROLL_COUNT

%if UNROLL_BYTES >= 256
%error unroll count is too large
%elif UNROLL_BYTES >= 128
%define off 128
%else
%define off 0
%endif

%define UNROLL_THRESHOLD   7

    bits    64
    section .text

    global  __gmpn_mul_1
    global  __gmpn_mul_1c

%ifdef DLL
    export  __gmpn_mul_1
    export  __gmpn_mul_1c
%endif

__gmpn_mul_1c:
    mov     r11,[rsp+0x28]
    jmp     start

__gmpn_mul_1:
    xor     r11,r11

start:
    movsxd  len,r8d
    mov     src,rdx
    cmp     len,UNROLL_THRESHOLD
    jae     .1
    lea     src,[src+len*8]
    lea     dst,[dst+len*8]
    neg     len
.0: mov     rax,[src+len*8]
    mul     mlt
    add     rax,r11
    mov     r11,dword 0
    adc     r11,rdx
    mov     [dst+len*8],rax
    inc     len
    jnz     .0
    mov     rax,r11
    ret

; The mov to load the next source limb is done well ahead of the mul, this
; is necessary for full speed.  It leads to one limb handled separately
; after the loop.
;
; When unrolling to 32 or more, an offset of +4 is used on the src pointer,
; to avoid having an 0x80 displacement in the code for the last limb in the
; unrolled loop.  This is for a fair comparison between 16 and 32 unrolling.

.1: lea     rax,[len-2]
    dec     len
    neg     len
    shr     rax,UNROLL_LOG2
    and     len,UNROLL_MASK
    mov     [rsp+0x08],rax      ; loop count in shadow space
    mov     rdx,len
    shl     rdx,4
    lea     rax,[rel .3]
    lea     rdx,[rdx+len*4]
    lea     rdx,[rdx+rax]
    mov     rax,[src]
    neg     len
    lea     src,[src+len*8+off]
    lea     dst,[dst+len*8+off]
    xor     len,len             ; len now zero
    jmp     rdx

.3:
%assign i 0
%rep  UNROLL_COUNT
%define disp   8 * i - off

    mul     mlt                 ; 20 bytes per block
    add     r11,rax
    mov     rax,[byte src+disp+8]
    mov     [byte dst+disp],r11
    mov     r11,len
    adc     r11,rdx

%assign i i + 1
%endrep

    dec     dword [rsp+0x08]
    lea     src,[src+UNROLL_BYTES]
    lea     dst,[dst+UNROLL_BYTES]
    jns     .3
    mul     mlt
    add     r11,rax
    mov     rax,len
    mov     [dst-off],r11
    adc     rax,rdx
    ret

%else

    bits    64
    section .text
    global  __gmpn_mul_1
    global  __gmpn_mul_1c

%ifdef DLL
    export  __gmpn_mul_1
    export  __gmpn_mul_1c
%endif
__gmpn_mul_1c:
    mov     r11, [rsp+0x28]
    jmp     start

    align   16
    nop
    nop
__gmpn_mul_1:
    xor     r11, r11
start:
    lea     r10, [rdx+8*r8]
    lea     rcx, [rcx+8*r8]
    neg     r8
.1: mov     rax, [r10+8*r8]
    mul     r9
    add     rax, r11
    mov     r11d, 0
    adc     r11, rdx
    mov     [rcx+8*r8], rax
    inc     r8
    jne     .1
    mov     rax, r11
    ret

%endif

    end
