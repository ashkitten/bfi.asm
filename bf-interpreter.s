%define arraysize 30000
%define cisize 0x80000

BITS 32

    org     0x00010000

    db      0x7F, "ELF"                 ; e_ident
    dd      1                                           ; p_type
    dd      0                                           ; p_offset
    dd      $$                                          ; p_vaddr
    dw      2                           ; e_type        ; p_paddr
    dw      3                           ; e_machine
    dd      _start                      ; e_version     ; p_filesz
    dd      _start                      ; e_entry       ; p_memsz
    dd      4                           ; e_phoff       ; p_flags

; empty space is a waste! let's put a subroutine in the elf header! :D
_start:
    sub     esp, cisize * 2 + arraysize ; allocate code/input buffer to stack
    jmp     _main

    dw      0x34                        ; e_ehsize
    dw      0x20                        ; e_phentsize
    dw      1                           ; e_phnum
                                        ; e_shentsize
                                        ; e_shnum
                                        ; e_shstrndx

_main:
    mov     edx, cisize                 ; length of code and input

    lea     ecx, [esp + arraysize]      ; start at esp
    mov     al, 3                       ; mov 3 to al (sys_read)
    int     0x80                        ; syscall

    ; no need to strip linefeed because it's just code

    add     ecx, cisize                 ; add to get address of input
    xor     ebx, ebx                    ; xor ebx to 0 (stdin)
    mov     al, 3                       ; mov 3 to al (sys_read)
    int     0x80                        ; syscall

    mov     byte[ecx + eax - 1], 0      ; strip last character (linefeed)

    ; initialize pointer registers
    mov     edi, esp
    mov     esi, ecx
    lea     ebx, [esp + arraysize]
    ; starting bracket depth is 0
    xor     ecx, ecx
    ; edx is always 1 (length of sys_write call)
    xor     edx, edx
    inc     edx

interpret:
    ; edi points to the position in the array
    ; ebx points to the position in the code
    ; esi points to the position in the input
    ; ecx tells us the bracket depth
    ; ebp tells us the bracket skip depth

    cmp     ebp, 0                      ; check if bracket skip depth is zero
    jne     .bracketskip                ; if it's not, skip to .bracketskip section

    ; case "+"
    cmp     byte[ebx], "+"              ; check if buffer character is a "+"
    jne     .next1                      ; if not, skip

    inc     byte[edi]                   ; add 1

    .next1:
    ; case "-"
    cmp     byte[ebx], "-"              ; check if buffer character is a "-"
    jne     .next2                      ; if not, skip

    dec     byte[edi]                   ; subtract 1

    .next2:
    ; case "<"
    cmp     byte[ebx], "<"              ; check if buffer character is a "<"
    jne     .next3                      ; if not, skip

    dec     edi                         ; decrement array pointer

    .next3:
    ; case ">"
    cmp     byte[ebx], ">"              ; check if buffer character is a ">"
    jne     .next4                      ; if not, skip

    inc     edi                         ; increment array pointer

    .next4:
    ; case "."
    cmp     byte[ebx], "."              ; check if buffer character is a "."
    jne     .next5                      ; if not, skip

    ; edx is already 1 (length)

    lea     ecx, [edi]                  ; address of array pointer

    push    ebx                         ; save input pointer to stack
    mov     ebx, edx                    ; mov edx (1) to ebx

    mov     al, 4                       ; mov 4 to al (sys_write)
    int     0x80                        ; syscall

    ; restore register values
    pop     ebx

    .next5:
    ; case ","
    cmp     byte[ebx], ","              ; check if buffer character is a ","
    jne     .next6                      ; if not, skip

    movsb                               ; mov string byte from esi to edi
    dec     edi                         ; prev array byte (movsb increments both)

    .next6:
    ; case "["
    cmp     byte[ebx], "["              ; check if buffer character is a "["
    jne     .next7                      ; if not, skip

    cmp     byte[edi], 0                ; if current array cell is 0
    je      .bracketopen_skip           ; jump to .bracketopen_skip

    push    ebx                         ; else push ebx
    inc     ecx                         ; increment bracket depth

    .next7:
    ; case "]"
    cmp     byte[ebx], "]"              ; check if buffer character is a "]"
    jne     post                        ; if not, skip to post
    pop     ebx                         ; pop ebx
    dec     ebx                         ; move back to previous character
    dec     ecx                         ; decrement bracket depth

    jmp     post                        ; jump to post so we don't hit bracketskip stuff

    .bracketskip:

    ; case "["
    cmp     byte[ebx], "["              ; check if buffer character is a "["
    jne     .next8                      ; if not, skip
    .bracketopen_skip:
    inc     ebp                         ; increment bracket skip

    .next8:
    ; case "]"
    cmp     byte[ebx], "]"              ; check if buffer character is a "]"
    jne     post                        ; if not, skip
    dec     ebp                         ; decrement bracket skip

post:
    inc     ebx                         ; move to next code byte
    cmp     byte[ebx], 0                ; check if this is the last byte
    jne     interpret                   ; if not, go to interpret

exit:
    mov     al, 1                       ; mov 1 to al (sys_exit)
    xor     ebx, ebx                    ; xor ebx to 0 (exit code 0)
    int     0x80                        ; syscall

filesize      equ     $ - $$
