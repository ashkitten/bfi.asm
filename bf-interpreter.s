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
    xor     ebx, ebx                    ; xor ebx to 0 (stdin)
    mov     al, 3                       ; mov 3 to eax (sys_read)
    int     0x80                        ; syscall

    ; no need to strip linefeed because it's just code

    add     ecx, cisize                 ; add to get address of input
    xor     ebx, ebx                    ; xor ebx to 0 (stdin)
    mov     al, 3                       ; mov 3 to eax (sys_read)
    int     0x80                        ; syscall

    mov     byte[ecx + eax - 1], 0      ; strip last character (linefeed)

    ; initialize pointer registers
    mov     eax, esp
    lea     ebx, [esp + arraysize]
    ; no need to initialize ecx to the address of input,
    ; because it's already there

    ; starting bracket depth is 0
    xor     edx, edx

interpret:
    ; eax points to the position in the array
    ; ebx points to the position in the code
    ; ecx points to the position in the input
    ; edx tells us the bracket depth
    ; we abuse ebp to serve as a bracket skip indicator

    cmp     ebp, 0                      ; check if ebp is zero
    jne     .bracketskip                ; if it's not, skip to the bracketskip section

    ; case "+"
    cmp     byte[ebx], "+"              ; check if buffer character is a "+"
    jne     .next1                      ; if not, skip

    inc     byte[eax]                   ; add 1

    .next1:
    ; case "-"
    cmp     byte[ebx], "-"              ; check if buffer character is a "-"
    jne     .next2                      ; if not, skip

    dec     byte[eax]                   ; subtract 1

    .next2:
    ; case "<"
    cmp     byte[ebx], "<"              ; check if buffer character is a "<"
    jne     .next3                      ; if not, skip

    dec     eax                         ; decrement array pointer

    .next3:
    ; case ">"
    cmp     byte[ebx], ">"              ; check if buffer character is a ">"
    jne     .next4                      ; if not, skip

    inc     eax                         ; increment array pointer

    .next4:
    ; case "."
    cmp     byte[ebx], "."              ; check if buffer character is a "."
    jne     .next5                      ; if not, skip

    push    edx                         ; save bracket skip to stack
    xor     edx, edx                    ; xor edx to 0
    inc     edx                         ; increment edx to 1 (length)

    push    ecx                         ; save input pointer to stack
    lea     ecx, [eax]                  ; address of array pointer

    push    ebx                         ; save input pointer to stack
    mov     ebx, edx                    ; mov edx (1) to ebx

    push    eax                         ; save array pointer to stack
    mov     eax, 4                      ; mov 4 to eax (sys_write)
    int     0x80                        ; syscall

    ; restore register values
    pop     eax
    pop     ebx
    pop     ecx
    pop     edx

    .next5:
    ; case ","
    cmp     byte[ebx], ","              ; check if buffer character is a ","
    jne     .next6                      ; if not, skip

    lea     esi, [ecx]                  ; prepare for movsb
    lea     edi, [eax]                  ; by loading esi and dsi with src and dest strings
    movsb                               ; mov string byte
    inc     ecx                         ; next input byte

    .next6:
    ; case "["
    cmp     byte[ebx], "["              ; check if buffer character is a "["
    jne     .next7                      ; if not, skip

    cmp     byte[eax], 0                ; if current array cell is 0
    je      .bracketopen_skip           ; jump to .bracketopen_skip

    push    ebx                         ; else push ebx
    inc     edx                         ; increment bracket depth

    .next7:
    ; case "]"
    cmp     byte[ebx], "]"              ; check if buffer character is a "]"
    jne     post                        ; if not, skip to post
    pop     ebx                         ; pop ebx
    dec     ebx                         ; move back to previous character
    dec     edx                         ; decrement bracket depth

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
    xor     eax, eax                    ; xor eax to 0
    inc     eax                         ; increment eax to 1 (sys_exit)
    xor     ebx, ebx                    ; xor ebx to 0 (exit code 0)
    int     0x80                        ; syscall

filesize      equ     $ - $$
