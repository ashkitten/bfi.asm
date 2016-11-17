section .data
	msg1 db "Enter code: "		; first prompt
	msg1_size equ $-msg1		; first prompt length

	msg2 db "Enter input: "		; second prompt
	msg2_size equ $-msg2		; second prompt length

	array_ptr dd 0
	code_ptr dd 0
	input_ptr dd 0

	skip_to_brackets dd 0

section .bss
	array resb 65536
	array_size equ $-array
	
	code resb 65536
	code_size equ $-code

	input resb 65536
	input_size equ $-input

section .text
	global _start

_start:
	mov	byte[array], 0		; initialize array to 0

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

	mov	byte[code+eax-1], 0	; strip last character (linefeed)

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

	mov	byte[input+eax-1], 0	; strip last character (linefeed)

interpret:
	mov	eax, dword[array_ptr]	; use eax to store array ptr for operations
	mov	ebx, dword[code_ptr]	; use ebx to store code ptr for operations
	mov	ecx, dword[input_ptr]

	cmp	dword[skip_to_brackets], 0
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
	inc	byte[skip_to_brackets]	; increase skip_to_brackets
	jmp	.7
	.7.1:
	push	ebx			; else push ebx
	.7:

	cmp	byte[code+ebx], "]"	; if buffer character is a "]"
	jne	.8
	cmp	byte[skip_to_brackets], 0
	je	.8.1
	dec	byte[skip_to_brackets]	; decrease skip_to_brackets
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

	cmp	byte[code+ebx], 0	; if code character is not 0
	jne	interpret		; go to next character

	; print linefeed
	push	0xA			; push linefeed character to stack
	mov	edx, 1			; length 1
	lea	ecx, [esp]		; load address of linefeed character on stack
	mov	ebx, 1			; stdout
	mov	eax, 4			; sys_write
	int	80h			; syscall
	add	esp, 4			; pop linefeed character off stack

exit:
	mov	eax, 1			; syscall_exit
	mov	ebx, 0 			; status 0
	int	80h			; syscall
