section .data
	msg1 db "Enter code: "		; first prompt
	msg1_size equ $-msg1		; first prompt length

	msg2 db "Enter input: "		; second prompt
	msg2_size equ $-msg2		; second prompt length

	array times 65536 db 0		; array of characters for program
	array_size equ $-array
	array_ptr dd 0

	code times 65536 db 0		; array of characters for program
	code_size equ $-array
	code_ptr dd 0

	input times 65536 db 0		; array of characters for program
	input_size equ $-array
	input_ptr dd 0

	bracket_skip dd 0

section .bss

section .text
	global _start

_start:
	mov	edx, msg1_size		; msg1 length
	mov	ecx, msg1		; address of msg1
	mov	ebx, 1			; stdout
	mov	eax, 4			; sys_write
	int	80h			; syscall

	mov	edx, code_size		; code length
	mov	ecx, code		; address of code
	mov	ebx, 0			; stdin
	mov	eax, 3			; sys_read
	int	80h			; syscall

	mov	edx, msg2_size		; msg2 length
	mov	ecx, msg2		; address of msg2
	mov	ebx, 1			; stdout
	mov	eax, 4			; sys_write
	int	80h			; syscall

	mov	edx, input_size		; input length
	mov	ecx, input		; address of input
	mov	ebx, 0			; stdin
	mov	eax, 3			; sys_read
	int	80h			; syscall

interpret:
	mov	eax, dword[array_ptr]	; use eax to store array ptr for operations
	mov	ebx, dword[code_ptr]	; use ebx to store code ptr for operations
	mov	ecx, dword[input_ptr]

	cmp	dword[bracket_skip], 0
	jne	.bracketskip

	cmp	byte[code+ebx], "+"	; if buffer character is a "+"
	jne	.1			; conditional jump
	inc	byte[array+eax]		; add 1
	.1:				; label for conditonal

	cmp	byte[code+ebx], "-"	; if buffer character is a "-"
	jne	.2			; conditional jump
	dec	byte[array+eax]		; subtract 1
	.2:				; label for conditional

	cmp	byte[code+ebx], "<"	; if buffer character is a "<"
	jne	.3
	dec	eax
	.3:

	cmp	byte[code+ebx], ">"	; if buffer character is a ">"
	jne	.4
	inc	eax
	.4:

	cmp	byte[code+ebx], "."	; if buffer character is a "."
	jne	.5
	mov	edx, 1			; length 1
	push	ecx
	lea	ecx, [array+eax]	; address of array+array_ptr
	push	ebx			; store register value to stack
	mov	ebx, 1			; stdout
	push	eax			; store register value to stack
	mov	eax, 4			; sys_write
	int	80h			; syscall
	pop	eax			; restore register values
	pop	ebx
	pop	ecx
	.5:

	cmp	byte[code+ebx], ","	; if buffer character is a ","
	jne	.6
	lea	esi, [input+ecx]	; prepare for movsb
	lea	edi, [array+eax]	; by loading esi and dsi with src and dest strings	
	movsb				; mov string byte
	inc	ecx			; next input byte
	.6:

	.bracketskip:

	cmp	byte[code+ebx], "["	; if buffer character is a "["
	jne	.7
	cmp	byte[array+eax], 0	; if current array cell is a 0
	jne	.7.1
	inc	byte[bracket_skip]	; increase bracket_skip
	jmp	.7
	.7.1:
	push	ebx			; else push ebx
	.7:

	cmp	byte[code+ebx], "]"	; if buffer character is a "]"
	jne	.8
	cmp	byte[bracket_skip], 0
	je	.8.1
	dec	byte[bracket_skip]	; decrease bracket_skip
	.8.1:
	cmp	byte[array+eax], 0	; if current array cell is not 0
	je	.8.2
	pop	ebx			; pop ebx
	dec	ebx
	jmp	.8
	.8.2:
	add	esp, 4
	.8:

	inc	ebx			; move to next code byte

	; put array ptr back
	mov	dword[array_ptr], eax
	mov	dword[code_ptr], ebx
	mov	dword[input_ptr], ecx

	cmp	byte[code+ebx], 10	; if buffer character is a linefeed
	jne	interpret		; go to next character

exit:
	mov	eax, 1			; syscall_exit
	mov	ebx, 0 			; status 0
	int	80h			; syscall
