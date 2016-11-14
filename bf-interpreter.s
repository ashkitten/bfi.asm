section .data
	msg1 db "Enter text: "		; first prompt
	msg1_size equ $-msg1		; first prompt length
	endl db 10

section .bss
	buffer resb 1
	array resb 256
	array_len equ $-array
	array_ptr resb 1

section .text
	global _start

_start:
	; initialize array
	mov	eax, 0
	.1:
	mov	byte[array+eax], 48
	add	eax, 1
	cmp	eax, array_len
	jne	.1

	mov	byte[array_ptr], 0

	; sys_write
	mov	edx, msg1_size
	mov	ecx, msg1
	mov	ebx, 1			; stdout
	mov	eax, 4			; sys_write
	int	80h			; syscall

readwrite:
	; sys_read
	mov	edx, 1
	mov	ecx, buffer
	mov	ebx, 0			; stdin
	mov	eax, 3			; sys_read
	int	80h			; syscall

	; print what we got from sys_read
	; sys_write
	mov	edx, 1
	mov	ecx, buffer
	mov	ebx, 1			; stdout
	mov	eax, 4			; sys_write
	int	80h			; syscall

	mov	eax, [array_ptr]

	cmp	byte[buffer], 43	; if buffer character is a "+"
	jne	.1			; conditional jump
	inc	byte[array+eax]		; add 1
	.1:				; label for conditonal

	cmp	byte[buffer], 45	; if buffer character is a "-"
	jne	.2			; conditional jump
	dec	byte[array+eax]		; subtract 1
	.2:				; label for conditional

	cmp	byte[buffer], 60	; if buffer character is a "<"
	jne	.3
	dec	eax
	.3:

	cmp	byte[buffer], 62	; if buffer character is a ">"
	jne	.4
	inc	eax
	.4:

	; put array ptr back
	mov	[array_ptr], eax

	; this is so if we overflow the buffer then it'll read more
	; if the last byte we printed is a linefeed, we're done
	; if not, there must be more to read
	cmp	byte[ecx], 10
	jne	readwrite

	; write out the array
	; sys_write
	mov	edx, array_len
	mov	ecx, array
	mov	ebx, 1			; stdout
	mov	eax, 4			; sys_write
	int	80h			; syscall

	; endl
	; sys_write
	mov	edx, 1
	mov	ecx, endl
	mov	ebx, 1
	mov	eax, 4
	int	80h

exit:
	; syscall exit(0)
	mov	eax, 1			; syscall_exit
	mov	ebx, 0 			; status 0
	int	80h			; call
