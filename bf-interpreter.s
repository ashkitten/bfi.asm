%define arraysize 30000
%define cisize 0x80000

BITS 32

            org     0x00010000

            db      0x7F, "ELF"         ; e_ident
            dd      1                                   ; p_type
            dd      0                                   ; p_offset
            dd      $$                                  ; p_vaddr
            dw      2                   ; e_type        ; p_paddr
            dw      3                   ; e_machine
            dd      _start              ; e_version     ; p_filesz
            dd      _start              ; e_entry       ; p_memsz
            dd      4                   ; e_phoff       ; p_flags
    times 8 db      0
            dw      0x34                ; e_ehsize
            dw      0x20                ; e_phentsize
            dw      1                   ; e_phnum
                                        ; e_shentsize
                                        ; e_shnum
                                        ; e_shstrndx

_start:
    mov     edx, cisize                 ; length of code and input
    sub     esp, cisize * 2 + arraysize ; allocate code/input buffer to stack

    mov     ecx, esp                    ; start at esp
    add     ecx, arraysize              ; add to get address of code
    xor     ebx, ebx                    ; xor ebx to 0 (stdin)
    mov     al, 3                       ; mov 3 to eax (sys_read)
    int     0x80                        ; syscall

    ; no need to strip linefeed because it's just code

    add     ecx, cisize                 ; add to get address of input
    xor     ebx, ebx                    ; xor ebx to 0 (stdin)
    mov     al, 3                       ; mov 3 to eax (sys_read)
    int     0x80                        ; syscall

    mov     byte[ecx + eax - 1], 0 ; strip last character (linefeed)

    ; initialize pointer registers
    mov     eax, esp
    mov     ebx, esp
    add     ebx, arraysize
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

    cmp     ebp, 0
    jne     .bracketskip

    .default:
    ; case "+"
    cmp     byte[ebx], "+"              ; if buffer character is a "+"
    je      plus
    ; case "-"
    cmp     byte[ebx], "-"              ; if buffer character is a "-"
    je      minus
    ; case "<"
    cmp     byte[ebx], "<"              ; if buffer character is a "<"
    je      arrayprev
    ; case ">"
    cmp     byte[ebx], ">"              ; if buffer character is a ">"
    je      arraynext
    ; case "."
    cmp     byte[ebx], "."              ; if buffer character is a "."
    je      print
    ; case ","
    cmp     byte[ebx], ","              ; if buffer character is a ","
    je      getchar
    ; case "["
    cmp     byte[ebx], "["              ; if buffer character is a "["
    je      bracketopen
    ; case "]"
    cmp     byte[ebx], "]"              ; if buffer character is a "]"
    je      bracketclose

    ; no need to jump to post here because if it didn't match
    ; the previous bracket cases, it won't match the next ones

    .bracketskip:

    ; case "["
    cmp     byte[ebx], "["              ; if buffer character is a "["
    je      bracketopen_skip
    ; case "]"
    cmp     byte[ebx], "]"              ; if buffer character is a "]"
    je      bracketclose_skip

    jmp     post

plus:
    inc     byte[eax]                   ; add 1

    jmp     post

minus:
    dec     byte[eax]                   ; subtract 1

    jmp     post

arrayprev:
    dec     eax                         ; decrement array pointer

    jmp     post

arraynext:
    inc     eax                         ; increment array pointer

    jmp    post

print:
    push    edx                         ; save bracket skip to stack
    xor     edx, edx                    ; xor edx to 0
    inc     edx                         ; increment edx to 1 (length)

    push    ecx                         ; save input pointer to stack
    lea     ecx, [eax]                  ; address of array pointer

    push    ebx                         ; save input pointer to stack
    xor     ebx, ebx                    ; xor ebx to 0
    inc     ebx                         ; increment ebx to 1 (stdout)

    push    eax                         ; save array pointer to stack
    mov     eax, 4                      ; mov 4 to eax (sys_write)
    int     0x80                        ; syscall

    ; restore register values
    pop     eax
    pop     ebx
    pop     ecx
    pop     edx

    jmp     post

getchar:
    lea     esi, [ecx]                  ; prepare for movsb
    lea     edi, [eax]                  ; by loading esi and dsi with src and dest strings
    movsb                               ; mov string byte
    inc     ecx                         ; next input byte

    jmp     post

bracketopen:
    cmp     byte[eax], 0                ; if current array cell is 0
    je      bracketopen_skip

    push    ebx                         ; else push ebx
    inc     edx                         ; increment bracket depth

    jmp     post

bracketclose:
    pop     ebx                         ; pop ebx
    dec     ebx                         ; move back to previous character
    dec     edx                         ; decrement bracket depth

    jmp     post

bracketopen_skip:
    inc     ebp                         ; increment bracket skip

    jmp     post

bracketclose_skip:
    dec     ebp                         ; decrement bracket skip

    ; no need to jmp to post because we're already there

post:
    inc     ebx                        ; move to next code byte
    cmp     byte[ebx], 0
    jne     interpret

exit:
    xor     eax, eax                    ; xor eax to 0
    inc     eax                         ; increment eax to 1 (sys_exit)
    xor     ebx, ebx                    ; xor ebx to 0 (exit code 0)
    int     0x80                        ; syscall

filesize      equ     $ - $$
