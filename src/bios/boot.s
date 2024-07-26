org 0x7c00

start:
    mov sp, 0x7000
    mov bp, 0x7000
    xor ax, ax
    mov ss, ax
    push ds
    xor ax, ax
    mov ds, ax
    mov [bootdisk], dx
    pop ds
    jmp 0:segment_set
segment_set:
    xor ax, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    push ds
    push si
    mov ds, ax
enable_a20:
    call test_a20
    test ax, ax
    jnz load_stage_2
    
    call bios_enable_a20
    call test_a20
    test ax, ax
    jnz load_stage_2
    
    call kbd_en_a20
    xor cx, cx
    .testlp:
        call test_a20
        test ax, ax
        jnz load_stage_2
        inc cx
        cmp cx, 512
        jl .testlp
    jmp $
    
    
test_a20:
    cli
    xor ax, ax
    push es
    push ds
    push si
    push di
    
    mov es, ax
    not ax
    mov ds, ax
    mov di, 0x500
    mov si, 0x510
    
    mov al, byte [es:di]
    push ax
    mov al, byte [ds:si]
    push ax
    
    mov byte [es:di], 0x00
    mov byte [ds:si], 0xff
    
    cmp byte [es:di], 0xff
    
    pop ax
    mov [ds:si], al
    pop ax
    mov [es:si], al
    
    mov ax, 0
    je .test_a20_exit
    mov ax, 1
    
    .test_a20_exit:
        pop si
        pop si
        pop ds
        pop es
        ret

bios_enable_a20:
    mov ax, 0x2403
    int 0x15
    jb .ret
    cmp ah, 0
    jnz .ret
    
    mov ax, 0x2401
    int 0x15
    .ret:
        ret

kbd_en_a20:
    
    cli
    
    call .wait
    mov al, 0xad
    out 0x64, al
    
    call .wait
    mov al, 0xd0
    out 0x64, al
    
    call .wait2
    in al, 0x60
    push eax
    
    call .wait
    mov al, 0xd1
    out 0x64, al
    
    call .wait
    pop eax
    or al, 2
    out 0x60, al
    
    call .wait
    mov al, 0xae
    out 0x64, al
    
    call .wait
    sti
    ret
    
    
    .wait:
        in al, 0x64
        test al, 2
        jnz .wait
        ret
    .wait2:
        in al, 0x64
        test al, 1
        jnz .wait2
        ret
check_mbr:
    push word 0
    pop ds
    mov dx, [bootdisk]
    mov ah, 0x2
    mov al, 1
    mov ch, 0
    mov cl, 1
    mov dh, 0
    xor bx, bx
    mov es, bx
    mov bx, 0x800
    int 0x13
    mov cx, 128
    mov si, 0x7c00
    mov di, 0x800
    .cmplp:
        mov ax, [si]
        cmp ax, [di]
        
        jne .set_vbr
        add di, 2
        add si, 2
        dec cx
        cmp cx, 0
        jne .cmplp
    .set_mbr:
        mov ax, 0
        ret
    .set_vbr:
        pop si
        pop ds
        xor si, si
        mov ds, si
        mov ax, [ds:si + 0x8]
        ret
    .ret:
        ret
DAP:
    .size:              db 0x10
    .unused:            db 0
    .sectors_to_read:   dw 0x10
    .offset:            dw 0x0000
    .segment:           dw 0x1000
    .start_low:         dd 0
    .start_high:        dd 0
    
load_stage_2:
    call check_mbr
    push ax
    xor eax, eax
    pop ax
    inc eax
    mov [DAP.start_low], eax
    mov ah, 0x42
    mov dx, [bootdisk]
    mov si, DAP
    xor al, al
    int 0x13
    jc .testerr
    
    ; push ds
    cli
    
    lgdt [gdt_desc]
    mov eax, cr0
    or al, 1
    mov cr0, eax
    jmp 0x10:.pmode
bits 32
    .pmode:
        mov bx, 0x18
        mov ds, bx
        mov es, bx
        mov ss, bx
        ; and al, 0xfe
        ; mov cr0, eax
        ; jmp 0x0:.unreal
    .unreal:
        ; pop ds
        ; sti
        ; mov bx, 0x0f01
        ; mov eax, 0xb8000
        ; mov [ds:eax], bx
    jmp 0x10:0x10000
    ;0x10000
    .testerr:
        mov ax, 0xe43
        int 0x10
    jmp $
BMRG_DATA_STRUCT:
    
gdt_desc:
    .size: dw GDT_END - GDT_DATA - 1
    .offset: dd GDT_DATA
GDT_DATA:
    NULL:
                    dq 0
    UNREAL_CODE:
        .lim:       dw 0xffff
        .base_l:    dw 0x0000
        .base_m:    db 0x00
        .access:    db 0b1001_1010
        .flags:     db 0b0000_0000
        .base_h:    db 0x00
    CODE32:
        .lim:       dw 0xffff
        .base_l:    dw 0x00
        .base_m:    db 0x00
        .access:    db 0b1001_1010
        .flags:     db 0b1100_1111
        .base_h:    db 0x00
    DATA32:
        .lim:       dw 0xffff
        .base_l:    dw 0x00
        .base_m:    db 0x00
        .access:    db 0b1001_0010
        .flags:     db 0b1100_1111
        .base_h:    db 0x00
GDT_END:
times 510-($-$$) db 0
db 0x55, 0xaa
times 1024-($-$$) db 0
bootdisk: dw 0