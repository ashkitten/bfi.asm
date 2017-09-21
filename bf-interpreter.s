section .bss
    array   resb 30000                  ; "standard" array size
    code    resb 0x80000
    input   resb 0x80000
    size    equ  0x80000

section .text
    global  _start

_start:
    mov     edx, size                   ; length of code and input

    ; the reason we use regular 32-bit registers here is because if we use
    ; 8-bit registers it will screw with the return value of the syscall
    ; and not reset the rest of eax to 0 like we need

    mov     ecx, code                   ; address of code
    xor     ebx, ebx                    ; xor ebx to 0 (stdin)
    mov     eax, 3                      ; mov 3 to eax (sys_read)
    int     0x80                        ; syscall

    ; no need to strip linefeed because it's just code

    mov     ecx, input                  ; address of input
    xor     ebx, ebx                    ; xor ebx to 0 (stdin)
    mov     eax, 3                      ; mov 3 to eax (sys_read)
    int     0x80                        ; syscall

    mov     byte[input + eax - 1], 0    ; strip last character (linefeed)

    ; initialize pointer registers
    mov     eax, array
    mov     ebx, code
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
    dec     eax                         ; decrease array pointer

    jmp     post

arraynext:
    inc     eax                         ; increase array pointer

    jmp    post

print:
    push    edx                         ; save bracket skip to stack
    xor     edx, edx                    ; xor edx to 0
    inc     edx                         ; increment edx to 1 (length)

    push    ecx                         ; save input pointer to stack
    lea     ecx, [eax]                  ; address of array pointer

    push    ebx                         ; save input pointer to stack
    xor     ebx, ebx                    ; xor ebx to 0
    inc     ebx                         ; increase ebx to 1 (stdout)

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
    inc     edx                         ; increase bracket depth

    jmp     post

bracketclose:
    pop     ebx                         ; pop ebx
    dec     ebx                         ; move back to previous character
    dec     edx                         ; decrease bracket depth

    jmp     post

bracketopen_skip:
    inc     ebp                         ; increase bracket skip

    jmp     post

bracketclose_skip:
    dec     ebp                         ; decrease bracket skip

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
