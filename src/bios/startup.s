section .text

bits 16

_start:
    mov ax, 0xe41
    int 0x10
    jmp $

section .data
