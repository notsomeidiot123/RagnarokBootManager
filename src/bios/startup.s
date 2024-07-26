section .text

bits 32
extern bmain
_start:
    
    call bmain
    jmp $

section .data

test: dw 0x55aa