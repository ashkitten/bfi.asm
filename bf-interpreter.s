section .data
	msg1 db "Enter code: "		; first prompt
	msg1_size equ $-msg1		; first prompt length

	msg2 db "Enter input: "		; second prompt
	msg2_size equ $-msg2		; second prompt length

	endl db 10

	array_ptr dd 0
	code_ptr dd 0
	input_ptr dd 0

section .bss
	array resb 256			; array of characters for program
	array_size equ $-array		; length of array

	code resb 256
	code_size equ $-code

	input resb 256
	input_size equ $-input

section .text
	global _start

_start:
	; initialize array
	; loops through array till it gets to end
	mov	eax, 0
	.1:
	mov	byte[array+eax], 48	; initialize cell to 48 (ASCII 0)
	add	eax, 1			; add 1 to eax
	cmp	eax, array_size		; check if eax == array_size
	jne	.1			; jump back to .1 if not equal

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

	cmp	byte[code+ebx], 43	; if buffer character is a "+"
	jne	.1			; conditional jump
	inc	byte[array+eax]		; add 1
	.1:				; label for conditonal

	cmp	byte[code+ebx], 45	; if buffer character is a "-"
	jne	.2			; conditional jump
	dec	byte[array+eax]		; subtract 1
	.2:				; label for conditional

	cmp	byte[code+ebx], 60	; if buffer character is a "<"
	jne	.3
	dec	eax
	.3:

	cmp	byte[code+ebx], 62	; if buffer character is a ">"
	jne	.4
	inc	eax
	.4:

	cmp	byte[code+ebx], 46	; if buffer character is a "."
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

	cmp	byte[code+ebx], 44	; if buffer character is a ","
	jne	.6
	push	ebx			; store ebx value to stack
	mov	ebx, dword[input+ecx]	; use ebx as intermediate register
	mov	dword[array+eax], ebx
	pop	ebx
	inc	ecx
	.6:

	inc	ebx			; move to next code byte

	; put array ptr back
	mov	dword[array_ptr], eax
	mov	dword[code_ptr], ebx
	mov	dword[input_ptr], ecx

	cmp	byte[code+ebx], 10	; if buffer character is a linefeed
	jne	interpret		; go to next character

	; endl
	mov	edx, 1			; length 1
	mov	ecx, endl		; address of endl
	mov	ebx, 1			; stdout
	mov	eax, 4			; sys_write
	int	80h			; syscall

exit:
	; syscall exit(0)
	mov	eax, 1			; syscall_exit
	mov	ebx, 0 			; status 0
	int	80h			; syscall
